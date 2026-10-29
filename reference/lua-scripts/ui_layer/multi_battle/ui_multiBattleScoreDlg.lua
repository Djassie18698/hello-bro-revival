--descriptioin:跨服战活动开始之前的界面
--company: xckoo
--author: chenchun
--date: 2014-2-19
---------------------------------------------
module("ui_multiBattleScoreDlg", package.seeall)
baseClass(layer_base_t, ui_multiBattleScoreDlg)

function init(self)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	self.contentSize_ = CCDirector:sharedDirector():getWinSize()
	local ccbiAttrTable = {name="multiserverbattle/multiBattleScoreDlg.ccbi", size=self.contentSize_}
	layer_base_t.init(self, true, ccbiAttrTable)

	--self.rankData = {[1] = 1, [2] = 2, [3] = 3, [4] = 4, [5] = 5, [6] = 6, [7] = 7}
	self.myscore = 0
	self.myrank = 0
	--self:createTestData()
	self:init_ui()
	self:init_binding_event()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		self.label_myrank = tolua.cast(self.proxy_:getNode("label_myrank"), "CCLabelTTF")
		self.label_myscore = tolua.cast(self.proxy_:getNode("label_myscore"), "CCLabelTTF")
		self.ctrl_close = tolua.cast(self.proxy_:getNode("ctrl_close"), "CCControlButton")

		self.node_cardcontent = tolua.cast(self.proxy_:getNode("node_cardcontent"), "CCNode")
		self.node_tablecontent = tolua.cast(self.proxy_:getNode("node_tablecontent"), "CCNode")

		self:initData()
		self.label_myrank:setString(self.myrank)
		self.label_myscore:setString(self.myscore)
		self:initTableView()

		--[[
		local urlpath = GetUrlNormalHeader(self.playerData_.m_uid,  protocol.CMD_R_COMM, protocol.URL_R_COMM)
		GetMainMenu():ShowLoadingDlg()	--获取信息的时候，不允许操作
		CCHttpRequest:open(urlpath, kHttpPost,"query=param1&other=params"):sendWithHandler(
			function(res, hnd)
				GetMainMenu():CloseLoadding() --获取信息完成时，解除禁止操作
				local resData = res:getResponseData()
				local code = res:getResponseCode()
				local xfile = xml.parse(resData)
				local item = xfile:find("RENLONG")
				local retcode = item.code
				if retcode == "0" then

				end
			end)
		]]
	end
end

function initData(self)
	local urlpath = GetMultiBattleHeader(self.playerData_.m_uid, 1, protocol.URL_R_CROSSWAR_RANK)   --拉取当前实时排名数据
	--urlpath = AddData(urlpath, "ToUid", self.rank_data.playerid)
	cclog("11111----%s", urlpath)
	GetMainMenu():ShowLoadingDlg();	-- 获取信息的时候，不允许操作
	CCHttpRequest:open(urlpath, kHttpPost,"query=param1&other=params"):sendWithHandler(
		function(res, hnd)
			GetMainMenu():CloseLoadding(); --获取信息完成时，解除禁止操作
			local resData = res:getResponseData()
			cclog("11111----%s", resData)
			local code = res:getResponseCode()
			local xfile = xml.parse(resData)
			local item = xfile:find("RENLONG")
			local retcode = item.code
			if retcode == "0" then
				local ranklist = item:find("rank_list")
				self.rankData = {}
				for i = 1, #ranklist do
					local data = {}
					data.uid = ranklist[i].col0
					data.rank = ranklist[i].col1
					data.zone = ranklist[i].col2
					data.name = ranklist[i].col3
					data.score = ranklist[i].col4
					table.insert(self.rankData, data)
				end

				local playerItem = item:find("player")
				if playerItem ~= nil then
					self.myscore = item:find("score")[1]
					self.myrank = item:find("rank")[1]
				end

				self.label_myrank:setString(self.myrank)
				self.label_myscore:setString(self.myscore)
				self.tableview:reloadData()
			else
				GetMainMenu():ShowErrorTip(tonumber(retcode), -1)
			end
		end)
end

function init_binding_event(self)
	if self.proxy_ ~= nil then
		local function close_window(btn, event)
			self.node_:removeFromParentAndCleanup(true)
		end

		local function CCLayerTouch(event, x, y)
			local rect = self.node_:boundingBox()
			rect.origin = ccp(0,0)
			local p = self.node_:convertToNodeSpace(ccp(x,y))
			if event == "began" then
				return true
			end
		end

		self.node_:setTouchEnabled(true)
		self.node_:registerScriptTouchHandler(CCLayerTouch, false, -8, true)

		self.ctrl_close:setTouchPriority(-10)
		self.proxy_:handleControlEvent(self.ctrl_close, close_window, CCControlEventTouchUpInside)
	end
end


--private function
function initTableView(self)
	-- body
	if self.tableview == nil then
		self.cellsize = self.node_cardcontent:getContentSize()
		self.tableContentSize = self.node_tablecontent:getContentSize()
		self:initHandle()
		self.tableview = LuaTableView:createWithHandler(self.tableViewHandler, CCSizeMake(self.tableContentSize.width, self.tableContentSize.height))

		self.tableview:setDirection(kCCScrollViewDirectionVertical)
		self.tableview:setVerticalFillOrder(kCCTableViewFillTopDown)
		self.tableview:setTouchPriority(-10)
		self.node_tablecontent:addChild(self.tableview)
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
			r = self.cellsize;
		elseif fn == "cellAtIndex" then
    		local nodeLayer = createObj(ui_multiRankItem, self.cellsize, self.rankData[a1 + 1], false)
			if not a2 then
				a2 = CCTableViewCell:create()
				a2:addChild(nodeLayer.node_)
			else
				a2:removeAllChildrenWithCleanup(true)
        		a2:addChild(nodeLayer.node_)
			end
			r = a2
		elseif fn == "numberOfCells" then
			r = #self.rankData
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

function onNodeCleanup(self)
	--cclog("1111---001")
	if self.proxy_ then
    	self.proxy_:release()
    end
    layer_base_t.onNodeCleanup(self)
end

function createTestData(self)
	self.rankData = {}
	for i = 1, 25 do
		local data = {}
		data.id = tostring(i)
		data.rank = tostring(i)
		data.zone = tostring(i) .. "区"
		data.name = tostring(i) .. "消失的影子"
		data.score = tostring(i * 100)
		table.insert(self.rankData, data)
	end
end