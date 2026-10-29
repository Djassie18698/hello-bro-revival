--descriptioin:跨服战活动开始之前的界面
--company: xckoo
--author: chenchun
--date: 2014-2-19
---------------------------------------------
module("ui_multiBattleBefore", package.seeall)
baseClass(layer_base_t, ui_multiBattleBefore)

function init(self, parentSize, leftTime, playerInfo, othersPlayer)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	self.contentSize_ = parentSize
	self.leftTime = leftTime
	self.deltatime = 0
	self.playerInfo = playerInfo
	self.battleInfoData = othersPlayer

	local ccbiAttrTable = {name="multiserverbattle/multiBattleBefore.ccbi", size=self.contentSize_}
	layer_base_t.init(self, true, ccbiAttrTable)

	--self.battleInfoData = {[1] = 1, [2] = 2, [3] = 3, [4] = 4, [5] = 5, [6] = 6, [7] = 7}
	self.curpage = 0
	self.AllPage = 10 --总共拉多少页数据
	self:init_ui()
	self:init_binding_event()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		self.label_title1 = tolua.cast(self.proxy_:getNode("label_title1"), "CCLabelTTF")
		self.label_time1 = tolua.cast(self.proxy_:getNode("label_time1"), "CCLabelTTF")
		self.label_endtimebefore = tolua.cast(self.proxy_:getNode("label_endtimebefore"), "CCLabelTTF")
		self.btn_more_data =  tolua.cast(self.proxy_:getNode("btn_more_data"), "CCControlButton")

		self.label_before_desc = tolua.cast(self.proxy_:getNode("label_before_desc"), "CCLabelTTF")
		self.label_last_rank = tolua.cast(self.proxy_:getNode("label_last_rank"), "CCLabelBMFont")
		self.label_no_enter = tolua.cast(self.proxy_:getNode("label_no_enter"), "CCLabelTTF")

		self.node_cardcontent = tolua.cast(self.proxy_:getNode("node_cardcontent"), "CCNode")
		self.node_tablecontent = tolua.cast(self.proxy_:getNode("node_tablecontent"), "CCNode")

		self.layer_mask = tolua.cast(self.proxy_:getNode("layer_mask"), "CCLayer")

		self.label_before_desc:setString(string.format(localizable.ui_person_count, MULTI_BATTLE_BATTLE_PERSON_COUNT))
		if self.playerInfo.isin == "1" then
			self.label_last_rank:setString(self.playerInfo.rank)
		else
			self.label_last_rank:setVisible(false)
			self.label_no_enter:setVisible(true)
		end

		self.label_endtimebefore:setString(localizable.ui_multi_not_start)

		self:initTableView()

		local function updateLeftTimeLabel(fDeltaTime)
			self.deltatime = self.deltatime + fDeltaTime
			if self.deltatime >= 1 then
				local intPart, floatPart = math.modf(self.deltatime)
				self.leftTime = self.leftTime - intPart
				if self.leftTime > 0 then
					local timeStr = tools.convertTimeElectronicWatchChinese(self.leftTime, 3)
					self.label_endtimebefore:setString(timeStr)
					self.deltatime = floatPart
				else
					self.label_endtimebefore:setString(localizable.ui_multi_ended)
					self.label_endtimebefore:unscheduleUpdate()
				end
			end
		end

		if self.leftTime > 0 then
			self.label_endtimebefore:scheduleUpdateWithPriorityLua(updateLeftTimeLabel, 0)
			self.label_endtimebefore:setString(tools.convertTimeElectronicWatchChinese(self.leftTime, 3))
		else
			self.label_endtimebefore:setString(localizable.ui_multi_ended)
		end

		--local x, y = self.label_title1:getPosition()
		--cclog("1111---%s", tostring(x))
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


function init_binding_event(self)

	if self.proxy_ ~= nil then
		--[[
		self.layer_mask:setVisible(true)

		local function CCLayerTouch(event, x, y)
			local rect = self.layer_mask:boundingBox()
			rect.origin = ccp(0,0)
			local p = self.layer_mask:convertToNodeSpace(ccp(x,y))
			if event == "began" then
				if rect:containsPoint(p) == true then
					return true
				else
					return false
				end
			end
		end

		self.layer_mask:setTouchEnabled(true)
		self.layer_mask:registerScriptTouchHandler(CCLayerTouch, false, -3, true)
		]]

		local function get_more_data( ... )
			local urlpath = GetMultiBattleHeader(self.playerData_.m_uid, 0, protocol.URI_R_CWARLIST)   --不需要传CMD
			local page = (self.curpage + 1) % self.AllPage + 1
			urlpath = AddData(urlpath, "Page", page)
			cclog("1111-----%s", urlpath)
			GetMainMenu():ShowLoadingDlg();	-- 获取信息的时候，不允许操作
			CCHttpRequest:open(urlpath, kHttpPost,"query=param1&other=params"):sendWithHandler(
				function(res, hnd)
					GetMainMenu():CloseLoadding(); --获取信息完成时，解除禁止操作
					local resData = res:getResponseData()
					cclog("1111-----%s", resData)
					local code = res:getResponseCode()
					local xfile = xml.parse(resData)
					local item = xfile:find("RENLONG")
					local retcode = item.code
					if retcode == "0" then
						self.curpage = self.curpage + 1
						local otherItem = item:find("positionlist")
						self:playerInfoForOther(otherItem)
						self.tableview:reloadData()
					else
						GetMainMenu():ShowErrorTip(tonumber(retcode), -1)
					end
				end)

		end
		self.btn_more_data:setTouchPriority(-2)
		self.proxy_:handleControlEvent(self.btn_more_data, get_more_data, CCControlEventTouchUpInside)
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
		self.tableview:setTouchPriority(-2)
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
			-- Return cell size
			-- a1 is cell index (-1 means default size, in cocos2d-x version below 2.1.3, it's always -1)
			r = self.cellsize;
		elseif fn == "cellAtIndex" then
			-- Return CCTableViewCell, a1 is cell index (zero based), a2 is dequeued cell (maybe nil)
			-- Do something to create cell and change the content
			--[[
			if not self.cellNodes[a1 + 1] or self.cellNodes[a1 + 1].node_ == nil then
        		self.cellNodes[a1 + 1] = createObj(ui_purchaseTableCell, self.cellsize, self.rechargeTable[a1 + 1])
    		end
    		]]
    		local nodeLayer = createObj(ui_multiBattleItemBefore, self.cellsize, self.battleInfoData[a1 + 1])
			if not a2 then
				--local nodeLayer = createObj(ui_purchaseTableCell, self.cellsize, self.rechargeTable[a1 + 1])
				a2 = CCTableViewCell:create()
				--nodeLayer.node_:setTag(100)
				a2:addChild(nodeLayer.node_)
			else
				a2:removeAllChildrenWithCleanup(true)
        		a2:addChild(nodeLayer.node_)
			end
			r = a2
		elseif fn == "numberOfCells" then
			r = #self.battleInfoData;
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

function playerInfoForOther(self, otherInfo)
	self.battleInfoData = {}
	for i = 1, #otherInfo do
		local tmpPlayerInfo = {}
		tmpPlayerInfo.uid = otherInfo[i]:find("uid")[1]
		tmpPlayerInfo.posid = otherInfo[i]:find("posid")[1]
		tmpPlayerInfo.pf = otherInfo[i]:find("pf")[1]
		tmpPlayerInfo.zone = otherInfo[i]:find("zone")[1]
		tmpPlayerInfo.rank = otherInfo[i]:find("rank")[1]
		tmpPlayerInfo.score = otherInfo[i]:find("score")[1]
		tmpPlayerInfo.keep_left = otherInfo[i]:find("keep_left")[1]
		tmpPlayerInfo.timeval = otherInfo[i]:find("timeval")[1]
		tmpPlayerInfo.addscore = otherInfo[i]:find("addscore")[1]
		tmpPlayerInfo.viplevel = otherInfo[i]:find("viplevel")[1]
		tmpPlayerInfo.name = otherInfo[i]:find("name")[1]
		tmpPlayerInfo.playerlevel = otherInfo[i]:find("playerlevel")[1]

		local cardInfo = otherInfo[i]:find("card")
		tmpPlayerInfo.cardInfo = {}
		tmpPlayerInfo.cardInfo.id = cardInfo:find("id")[1]
		tmpPlayerInfo.cardInfo.life = cardInfo:find("life")[1]
		tmpPlayerInfo.cardInfo.strength = cardInfo:find("strength")[1]

		table.insert(self.battleInfoData, tmpPlayerInfo)
	end
end

function onNodeCleanup(self)
	--cclog("1111---001")
	if self.proxy_ then
    	self.proxy_:release()
    end
    layer_base_t.onNodeCleanup(self)
end

function createTestData(self)
	self.battleInfoData = {}
end