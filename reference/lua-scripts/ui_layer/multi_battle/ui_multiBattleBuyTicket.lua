--descriptioin:跨服战活动购买门票的界面
--company: xckoo
--author: chenchun
--date: 2014-2-19
---------------------------------------------
module("ui_multiBattleBuyTicket", package.seeall)
baseClass(layer_base_t, ui_multiBattleBuyTicket)

function init(self, parentSize, leftTime, playerInfo, othersPlayer)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	self.contentSize_ = parentSize
	local ccbiAttrTable = {name="multiserverbattle/multiBattleBuyTicket.ccbi", size=self.contentSize_}
	layer_base_t.init(self, true, ccbiAttrTable)

	self.playerInfo = playerInfo
	self.battleInfoData = othersPlayer

	self.leftTime = leftTime or 0
	self.deltaBattleTime = 0
	--self.battleInfoData = {[1] = 1, [2] = 2, [3] = 3, [4] = 4, [5] = 5, [6] = 6, [7] = 7}
	self.curpage = 0
	self.AllPage = 10 --总共拉多少页数据
	self:init_ui()
	self:init_binding_event()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		self.label_title = tolua.cast(self.proxy_:getNode("label_title"), "CCLabelTTF")
		self.label_starttime = tolua.cast(self.proxy_:getNode("label_starttime"), "CCLabelTTF")
		self.label_endtime = tolua.cast(self.proxy_:getNode("label_endtime"), "CCLabelTTF")
		self.label_isEnter = tolua.cast(self.proxy_:getNode("label_isEnter"), "CCLabelTTF")
		self.label_rest_time = tolua.cast(self.proxy_:getNode("label_rest_time"), "CCLabelBMFont")

		self.ctrl_buy_ticket = tolua.cast(self.proxy_:getNode("ctrl_buy_ticket"), "CCControlButton")
		self.btn_more_data =  tolua.cast(self.proxy_:getNode("btn_more_data"), "CCControlButton")

		self.node_cardcontent = tolua.cast(self.proxy_:getNode("node_cardcontent"), "CCNode")
		self.node_tablecontent = tolua.cast(self.proxy_:getNode("node_tablecontent"), "CCNode")


		if self.playerInfo.isin == "1" then
			self.label_isEnter:setString(localizable.ui_multi_entered)
			--self.ctrl_buy_ticket:setEnabled(false)
		else
			self.label_isEnter:setString(localizable.ui_multi_not_enter)
		end

		local function updateLeftTimeLabel(fDeltaTime)
			self.deltaBattleTime = self.deltaBattleTime + fDeltaTime
			if self.deltaBattleTime >= 1 then
				local intPart, floatPart = math.modf(self.deltaBattleTime)
				self.leftTime = self.leftTime - intPart
				if self.leftTime > 0 then
					local timeStr = tools.convertTimeElectronicWatch(self.leftTime, 3)
					self.label_rest_time:setString(timeStr)
					self.deltaBattleTime = floatPart
				else
					self.label_rest_time:setString("0")
					self.label_rest_time:unscheduleUpdate()
					ShowMultiBattleView()
				end
			end
		end

		self:initTableView()

		if self.leftTime > 0 then
			self.label_rest_time:scheduleUpdateWithPriorityLua(updateLeftTimeLabel, 0)
			self.label_rest_time:setString(tools.convertTimeElectronicWatch(self.leftTime, 3))
		else
			self.label_rest_time:setString("0")
			ShowMultiBattleView()
		end	
	end
end


function init_binding_event(self)

	if self.proxy_ ~= nil then

		local function exchange_gift()
		local urlpath = GetMultiBattleHeader(self.playerData_.m_uid, 3, protocol.URL_W_CWAR)   --兑换奖励
		urlpath = AddData(urlpath, "ExchId", ExchId)
		--cclog("1111----%s", urlpath)

		GetMainMenu():ShowLoadingDlg();	-- 获取信息的时候，不允许操作
		CCHttpRequest:open(urlpath, kHttpPost,"query=param1&other=params"):sendWithHandler(
			function(res, hnd)
				GetMainMenu():CloseLoadding(); --获取信息完成时，解除禁止操作
				local resData = res:getResponseData()
				--cclog("1111----%s", resData)
				local code = res:getResponseCode()
				local xfile = xml.parse(resData)
				local item = xfile:find("RENLONG")
				local retcode = item.code
				if retcode == "0" then
					self.leftScore = tonumber(item:find("myscore_left")[1])
					self.label_acc_score:setString(tostring(self.leftScore))
					local goldval = self.playerData_.m_gold - MULTI_BATTLE_BUY_TICKET
					self.playerMgr_:SetGold(goldval)
					ui_multiServerLayer.GoldLabelNode:setString(tostring(gold))
					local awardXML = item:find("award")
					ShowAward(awardXML)
				else
					GetMainMenu():ShowErrorTip(tonumber(retcode), -1)
				end
			end)
	end

		local function buy_ticket( ... )
			if self.playerInfo.isin == "1" then
				GetMainMenu():ShowTextTip(localizable.ui_multi_has_qualification, -1)
			else
				local function buy_sure()
					local urlpath = GetMultiBattleHeader(self.playerData_.m_uid, 1, protocol.URL_W_CWAR)   --不需要传CMD
					--urlpath = AddData(urlpath, "ToUid", self.rank_data.playerid)
					--cclog("1111-----%s", urlpath)
					GetMainMenu():ShowLoadingDlg();	-- 获取信息的时候，不允许操作
					CCHttpRequest:open(urlpath, kHttpPost,"query=param1&other=params"):sendWithHandler(
						function(res, hnd)
							GetMainMenu():CloseLoadding(); --获取信息完成时，解除禁止操作
							local resData = res:getResponseData()
							--cclog("1111-----%s", resData)
							local code = res:getResponseCode()
							local xfile = xml.parse(resData)
							local item = xfile:find("RENLONG")
							local retcode = item.code
							if retcode == "0" then
								self.label_isEnter:setString(localizable.ui_multi_entered)
								self.playerInfo.isin = "1"
								--self.ctrl_buy_ticket:setEnabled(false)
							else
								GetMainMenu():ShowErrorTip(tonumber(retcode), -1)
							end
						end)
				end
				local dlg = CommonDialogView.create()
				CommonDialogView.m_selfview = dlg
				dlg:SetTitle(localizable.ui_multi_buy_ticket)
				--local str = string.format(localizable.ui_inspire_description, 500, MULTI_BATTLE_INSPIRE_VALUE, self.playerInfo.extra_my_times, self.playerInfo.extra_times_lmt)
				dlg:SetDescription(string.format(localizable.ui_multi_buy_ticket_tips, MULTI_BATTLE_BUY_TICKET))
				dlg:loadCCBI(kCCMenuHandlerPriority-4, "CommonDialogView")
				dlg:initUI(kCCMenuHandlerPriority-5)
				dlg:SetConfirmHandler(buy_sure)
				GetMainMenu():GetModelLayer():AddDialog(dlg, 3)
			end
		end

		local function get_more_data( ... )

			local urlpath = GetMultiBattleHeader(self.playerData_.m_uid, 1, protocol.URI_R_CWARLIST)   --不需要传CMD
			local page = (self.curpage + 1) % self.AllPage + 1
			urlpath = AddData(urlpath, "Page", page)
			--cclog("1111-----%s", urlpath)
			GetMainMenu():ShowLoadingDlg();	-- 获取信息的时候，不允许操作
			CCHttpRequest:open(urlpath, kHttpPost,"query=param1&other=params"):sendWithHandler(
				function(res, hnd)
					GetMainMenu():CloseLoadding(); --获取信息完成时，解除禁止操作
					local resData = res:getResponseData()
					--cclog("1111-----%s", resData)
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
		self.ctrl_buy_ticket:setTouchPriority(-3)
		self.proxy_:handleControlEvent(self.ctrl_buy_ticket, buy_ticket, CCControlEventTouchUpInside)
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
    		local nodeLayer = createObj(ui_multiBattleItemBefore, self.cellsize, self.battleInfoData[a1 + 1], 1)
			if not a2 then
				a2 = CCTableViewCell:create()
				a2:addChild(nodeLayer.node_)
			else
				a2:removeAllChildrenWithCleanup(true)
        		a2:addChild(nodeLayer.node_)
			end
			r = a2
		elseif fn == "numberOfCells" then
			r = #self.battleInfoData
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

function createTestData(self)
	self.battleInfoData = {}
end