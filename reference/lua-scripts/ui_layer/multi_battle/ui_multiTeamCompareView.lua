--descriptioin:阵容对比界面
--company: xckoo
--author: chenchun
--date: 2014-02-21

---------------------------------------------
module("ui_multiTeamCompareView", package.seeall)
baseClass(layer_base_t, ui_multiTeamCompareView)

--index = 0
function init(self, otherPlayerId, zone)   --otherData,用于关闭购买窗口后，更新相关界面信息
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	local winSize = CCDirector:sharedDirector():getWinSize()

	local ccbiAttrTable = {name="dlg_ui/TeamCompareView.ccbi", size=winSize}
	layer_base_t.init(self, true, ccbiAttrTable)

	self.otherPlayerId= otherPlayerId
	self.otherPlayerZone = zone
	self.myTeamInfo = {}
	self.otherTeamInfo = {}
	self.myNinjalist = {}
	self.otherNinjalist = {}

	self:createTestData()
	self:init_ui()
	self:init_binding_event()
end


function init_ui(self)
	if self.proxy_ ~= nil then
		self.label_attackname = tolua.cast(self.proxy_:getNode("label_attackname"), "CCLabelTTF")
		self.label_attacklevel = tolua.cast(self.proxy_:getNode("label_attacklevel"), "CCLabelTTF")
		self.label_attackattack = tolua.cast(self.proxy_:getNode("label_attackattack"), "CCLabelTTF")
		self.label_attacknum = tolua.cast(self.proxy_:getNode("label_attacknum"), "CCLabelTTF")
		self.label_defensename = tolua.cast(self.proxy_:getNode("label_defensename"), "CCLabelTTF")
		self.label_defenselevel = tolua.cast(self.proxy_:getNode("label_defenselevel"), "CCLabelTTF")
		self.label_defensedefense = tolua.cast(self.proxy_:getNode("label_defensedefense"), "CCLabelTTF")
		self.label_defensenum = tolua.cast(self.proxy_:getNode("label_defensenum"), "CCLabelTTF")
		self.ctrl_changeteam = tolua.cast(self.proxy_:getNode("ctrl_changeteam"), "CCControlButton")
		self.sprite_changeteam = tolua.cast(self.proxy_:getNode("sprite_changeteam"), "CCSprite")
		self.ctrl_back = tolua.cast(self.proxy_:getNode("ctrl_back"), "CCControlButton")
		self.sprite_close = tolua.cast(self.proxy_:getNode("sprite_close"), "CCSprite")
		self.node_close = tolua.cast(self.proxy_:getNode("node_close"), "CCNode")
		self.ctrl_close1 = tolua.cast(self.proxy_:getNode("ctrl_close1"), "CCControlButton")
		self.ctrl_close = tolua.cast(self.proxy_:getNode("ctrl_close"), "CCControlButton")
		self.node_content = tolua.cast(self.proxy_:getNode("node_content"), "CCNode")
		self.node_cardview = tolua.cast(self.proxy_:getNode("node_cardview"), "CCNode")

		self.ctrl_changeteam:setEnabled(false)
		self.ctrl_changeteam:setVisible(false)
		self.sprite_changeteam:setVisible(false)
		self.ctrl_back:setEnabled(false)
		self.ctrl_back:setVisible(false)
		self.sprite_close:setVisible(false)
		self.node_close:setVisible(true)

		--self:init_config_data()
		self:init_control()
		self:initTableView()
	end
end

function init_binding_event(self)
	local function CCLayerTouch(event)
		if event == "began" then
			return true
		end
	end
	self.node_:setTouchEnabled(true)
	self.node_:registerScriptTouchHandler(CCLayerTouch, false, -1, true)

	local function close_window(btn, event)
		self.node_:removeFromParentAndCleanup(true)
	end

	if self.proxy_ ~= nil then
		self.ctrl_close1:setTouchPriority(-2)
		self.ctrl_close:setTouchPriority(-2)
		self.proxy_:handleControlEvent(self.ctrl_close, close_window, CCControlEventTouchUpInside)
		self.proxy_:handleControlEvent(self.ctrl_close1, close_window, CCControlEventTouchUpInside)
	end
end

function onNodeCleanup(self)
    --cclog("onNodeCleanup")
    if self.proxy_ then
    	self.proxy_:release()
    end
    layer_base_t.onNodeCleanup(self)
end

function init_config_data(self)

	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, protocol.CMD_CROSS_WAR_02, protocol.URI_W_CWARLIST)
	urlpath = AddData(urlpath, "ToUid", self.otherPlayerId)
	urlpath = AddData(urlpath, "ToZone", self.otherPlayerZone)

	GetMainMenu():ShowLoadingDlg();	-- 获取信息的时候，不允许操作
	CCHttpRequest:open(urlpath, kHttpPost,"query=param1&other=params"):sendWithHandler(
		function(res, hnd)
			GetMainMenu():CloseLoadding(); --获取信息完成时，解除禁止操作
			local resData = res:getResponseData()
			local code = res:getResponseCode()
			local xfile = xml.parse(resData)
			local item = xfile:find("RENLONG")
			local retcode = item.code
			if retcode == "0" then
				local fightItem = item:find("fight")
				local killer = fightItem:find("killer")
				local guarder = fightItem:find("guard")

				self:init_myteam(killer)
				self:init_otherteam(guarder)

				--设置玩家信息相关的空间
				self:init_control()

				--设置玩家卡片相关的信息
				self:initTableView()

				--GetMainMenu():ShowArenaView(resData)
			else
				GetMainMenu():ShowTextTip("阵容对比数据存在错误", -1)
			end
		end)
end

function init_myteam(self, killer)
	self.myTeamInfo.name = killer:find("name")[1]
	self.myTeamInfo.level = killer:find("level")[1]
	self.myTeamInfo.all_high = killer:find("all_high")[1]
	self.myTeamInfo.all_low = killer:find("all_low")[1]

	local ninjalist = killer:find("ninjalist")

	for i = 1, #ninjalist do
		local ninjalistItem = {}
		ninjalistItem.id = ninjalist[i]:find("id")[1]
		ninjalistItem.bagid = ninjalist[i]:find("bagid")[1]
		ninjalistItem.low = ninjalist[i]:find("low")[1]
		ninjalistItem.high = ninjalist[i]:find("high")[1]
		ninjalistItem.chackla_low = ninjalist[i]:find("chackla_low")[1]
		ninjalistItem.chackla_high = ninjalist[i]:find("chackla_high")[1]
		table.insert(self.myNinjalist, ninjalistItem)
	end
	self.myTeamInfo.cardCount = #self.myNinjalist
end

function init_otherteam(self, guarder)
	self.otherTeamInfo.name = guarder:find("name")[1]
	self.otherTeamInfo.level = guarder:find("level")[1]
	self.otherTeamInfo.all_high = guarder:find("all_high")[1]
	self.otherTeamInfo.all_low = guarder:find("all_low")[1]

	local ninjalist = guarder:find("ninjalist")
	for i = 1, #ninjalist do
		local ninjalistItem = {}
		ninjalistItem.id = ninjalist[i]:find("id")[1]
		ninjalistItem.bagid = ninjalist[i]:find("bagid")[1]
		ninjalistItem.low = ninjalist[i]:find("low")[1]
		ninjalistItem.high = ninjalist[i]:find("high")[1]
		ninjalistItem.chackla_low = ninjalist[i]:find("chackla_low")[1]
		ninjalistItem.chackla_high = ninjalist[i]:find("chackla_high")[1]
		table.insert(self.otherNinjalist, ninjalistItem)
	end
	self.otherTeamInfo.cardCount = #self.otherNinjalist
end

function init_control(self)
	self.label_attackname:setString(self.myTeamInfo.name)
	self.label_attacklevel:setString(self.myTeamInfo.level)
	self.label_attackattack:setString(tostring(self.myTeamInfo.all_low) .. "-" .. tostring(self.myTeamInfo.all_high))
	self.label_attacknum:setString(tostring(self.myTeamInfo.cardCount))

	self.label_defensename:setString(self.otherTeamInfo.name)
	self.label_defenselevel:setString(self.otherTeamInfo.level)
	self.label_defensedefense:setString(tostring(self.otherTeamInfo.all_low) .. "-" .. tostring(self.otherTeamInfo.all_high))
	self.label_defensenum:setString(tostring(self.otherTeamInfo.cardCount))
end

--private function
function initTableView(self)
	-- body
	if self.tableview == nil then
		self.cellsize = self.node_cardview:getContentSize()
		self.tableContentSize = self.node_content:getContentSize()
		self:initHandle()
		self.tableview = LuaTableView:createWithHandler(self.tableViewHandler, CCSizeMake(self.tableContentSize.width, self.tableContentSize.height))

		self.tableview:setDirection(kCCScrollViewDirectionVertical)
		self.tableview:setVerticalFillOrder(kCCTableViewFillTopDown)
		self.tableview:setTouchPriority(-2)
		self.node_content:addChild(self.tableview)
		--local offset = self.tableview:getContentOffset()
		--self.tableview:reloadData()
		--self.tableview:setContentOffset(offset.x, offset.y)
		--self.tableview:setDragEnabled(true)
	end
end

function initHandle(self)
	self.tableViewHandler = LuaEventHandler:create(function(fn, table, a1, a2, x, y)
		local r
		if fn == "cellSize" then
			-- Return cell size
			-- a1 is cell index (-1 means default size, in cocos2d-x version below 2.1.3, it's always -1)
			r = self.cellsize;
		elseif fn == "cellAtIndex" then
    		local nodeLayer = createObj(ui_multiTeamCompareItemView, self.cellsize, self.myNinjalist[a1 + 1], self.otherNinjalist[a1+1])
			if not a2 then
				--local nodeLayer = createObj(ui_purchaseTableCell, self.cellsize, self.rechargeTable[a1 + 1])
				a2 = CCTableViewCell:create()
				a2:addChild(nodeLayer.node_)
			else
				a2:removeAllChildrenWithCleanup(true)
        		a2:addChild(nodeLayer.node_)
			end
			r = a2
		elseif fn == "numberOfCells" then
			if #self.myNinjalist > #self.otherNinjalist then
				r = #self.myNinjalist
			else
				r = #self.otherNinjalist
			end
		-- Cell events:
		elseif fn == "cellTouched" then			-- A cell was touched, a1 is cell that be touched. This is not necessary.

		elseif fn == "cellTouchBegan" then		-- A cell is touching, a1 is cell, a2 is CCTouch
			r = true
		elseif fn == "cellTouchEnded" then		-- A cell was touched, a1 is cell, a2 is CCTouch
			r = true
		elseif fn == "cellHighlight" then		-- A cell is highlighting, coco2d-x 2.1.3 or above
		elseif fn == "cellUnhighlight" then		-- A cell had been unhighlighted, coco2d-x 2.1.3 or above
		elseif fn == "cellWillRecycle" then		-- A cell will be recycled, coco2d-x 2.1.3 or above
		end
		return r
	end)
end

function createTestData(self)
	self.myTeamInfo.name = "chenchun"
	self.myTeamInfo.level = "117"
	self.myTeamInfo.all_high = "900000"
	self.myTeamInfo.all_low = "10000"

	for i = 1, 10 do
		local ninjalistItem = {}
		ninjalistItem.id = "5"
		ninjalistItem.bagid = "1"
		ninjalistItem.low = "2000"
		ninjalistItem.high = "5000"
		ninjalistItem.chackla_low = "200"
		ninjalistItem.chackla_high = "1000"
		table.insert(self.myNinjalist, ninjalistItem)
	end
	self.myTeamInfo.cardCount = #self.myNinjalist

	self.otherTeamInfo.name = "chenchun"
	self.otherTeamInfo.level = "117"
	self.otherTeamInfo.all_high = "900000"
	self.otherTeamInfo.all_low = "10000"

	for i = 1, 7 do
		local ninjalistItem = {}
		ninjalistItem.id = "5"
		ninjalistItem.bagid = "1"
		ninjalistItem.low = "2000"
		ninjalistItem.high = "5000"
		ninjalistItem.chackla_low = "200"
		ninjalistItem.chackla_high = "500"
		table.insert(self.otherNinjalist, ninjalistItem)
	end
	self.otherTeamInfo.cardCount = #self.otherNinjalist
end