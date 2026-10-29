--descriptioin:跨服战活动开始之前的界面
--company: xckoo
--author: chenchun
--date: 2014-2-19
---------------------------------------------
module("ui_multiBattling", package.seeall)
baseClass(layer_base_t, ui_multiBattling)

function init(self, parentSize, leftTime, playerInfo, othersPlayer)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	self.contentSize_ = parentSize
	self.playerInfo = playerInfo
	self.battleInfoData = othersPlayer

	local ccbiAttrTable = {name="multiserverbattle/multiBattling.ccbi", size=self.contentSize_}
	layer_base_t.init(self, true, ccbiAttrTable)
	self.leftTime = leftTime
	self.extra_timeleft = 0
	if playerInfo.extra ~= 0 then
		self.extra_timeleft = playerInfo.extra_timeleft
	end
	--self.battleStatus = 1      --1,代表查看阵容，2、代表激励，3、代表挑战
	self.deltatime = 0
	self.deltaBattleTime = 0
	--self.battleInfoData = {[1] = 1, [2] = 2, [3] = 3, [4] = 4, [5] = 5, [6] = 6, [7] = 7}
	self:init_ui()
	self:init_binding_event()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		self.node_user_title = tolua.cast(self.proxy_:getNode("node_user_title"), "CCLabelTTF")
		self.node_myinfo = tolua.cast(self.proxy_:getNode("node_myinfo"), "CCNode")
		self.label_title = tolua.cast(self.proxy_:getNode("label_title"), "CCLabelTTF")
		self.label_rest_time = tolua.cast(self.proxy_:getNode("label_rest_time"), "CCLabelBMFont")
		self.label_time1 = tolua.cast(self.proxy_:getNode("label_time1"), "CCLabelTTF")
		self.label_score_rank = tolua.cast(self.proxy_:getNode("label_score_rank"), "CCLabelBMFont")
		self.ctrl_get_score = tolua.cast(self.proxy_:getNode("ctrl_get_score"), "CCControlButton")
		self.btn_Inspire = tolua.cast(self.proxy_:getNode("btn_Inspire"), "CCControlButton")

		self.label_mypos = tolua.cast(self.proxy_:getNode("label_mypos"),"CCLabelBMFont")
		self.label_myrank = tolua.cast(self.proxy_:getNode("label_myrank"), "CCLabelBMFont")
		self.label_my_score = tolua.cast(self.proxy_:getNode("label_my_score"), "CCLabelBMFont")
		self.label_addvalue = tolua.cast(self.proxy_:getNode("label_addvalue"),"CCLabelBMFont")
		self.label_my_time_score = tolua.cast(self.proxy_:getNode("label_my_time_score"), "CCLabelTTF")
		self.label_add_rest_time =  tolua.cast(self.proxy_:getNode("label_add_rest_time"),"CCLabelBMFont")
		self.btn_more_fights = tolua.cast(self.proxy_:getNode("btn_more_fights"), "CCControlButton")

		self.node_addcontent = tolua.cast(self.proxy_:getNode("node_addcontent"),"CCNode")
		self.node_cardcontent = tolua.cast(self.proxy_:getNode("node_cardcontent"), "CCNode")
		self.node_tablecontent = tolua.cast(self.proxy_:getNode("node_tablecontent"), "CCNode")

		self:init_itemInfoForUser()
		self:initTableView()

		local function updateLeftTimeLabel1(fDeltaTime)
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

		if self.leftTime > 0 then
			self.label_rest_time:scheduleUpdateWithPriorityLua(updateLeftTimeLabel1, 0)
			self.label_rest_time:setString(tools.convertTimeElectronicWatch(self.leftTime, 3))
		else
			self.label_rest_time:setString("0")
			ShowMultiBattleView()
		end
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

--根据列表的玩家是否是自己，进行一些特殊的初始化，比如底图颜色，是否激励
function init_itemInfoForUser(self)
	if self.playerInfo.isin == "1" then
			self.label_my_time_score:setString("(+" .. tostring(self.playerInfo.addscore) ..localizable.ui_multi_acc_score .. tostring(self.playerInfo.timeval) .. localizable.ui_multi_time_sec .. ")")
			self.label_mypos:setString(tostring(self.playerInfo.posid))
			self.label_myrank:setString(tostring(self.playerInfo.rank))
			self.label_my_score:setString(tostring(self.playerInfo.score))
			if self.playerInfo.extra ~= 0 then
				self.label_addvalue:setString(tostring(self.playerInfo.extra) .. "%")
				self:update_ui_for_frame()
				self.node_addcontent:setVisible(true)
			else
				self.node_addcontent:setVisible(true)
				self.label_add_rest_time:setString("0")
				self.label_addvalue:setString(tostring(self.playerInfo.extra))
			end
		else
			self.node_myinfo:setVisible(false)
			self.btn_Inspire:setEnabled(false)
			self.btn_Inspire:setVisible(false)
			local contentSize = self.node_user_title:getContentSize()
			self.ctrl_get_score:setPosition(contentSize.width * 0.5, contentSize.height * 0.4)
		end
end


function update_ui_for_frame(self)
	self.label_add_rest_time:unscheduleUpdate()
	self.label_add_rest_time:setString("0")
	local function updateLeftTimeLabel(fDeltaTime)
		self.deltatime = self.deltatime + fDeltaTime
		if self.deltatime >= 1 then
			local intPart, floatPart = math.modf(self.deltatime)
			--local tmpTable = {}
			self.extra_timeleft = self.extra_timeleft - intPart
			for i = 1, #self.playerInfo.inspireList do
				if self.playerInfo.inspireList[i] > 0 then
					local val = self.playerInfo.inspireList[i] - intPart
					if val > 0 then
						self.playerInfo.inspireList[i] = val
						--table.insert(tmpTable, val)
					else
						local tmpVal = self.playerInfo.extra - MULTI_BATTLE_INSPIRE_VALUE
						if tmpVal <= 0 then
							self.playerInfo.extra = 0
						else
							self.playerInfo.extra = tmpVal
						end
						self.label_addvalue:setString(tostring(self.playerInfo.extra) .. "%")
					end
				end
			end
			--self.playerInfo.inspireList = tmpTable

			if self.extra_timeleft > 0 then
				local timeStr = tools.convertTimeElectronicWatch(self.extra_timeleft, 3)
				self.label_add_rest_time:setString(timeStr)
				self.deltatime = floatPart
			else
				self.label_add_rest_time:setString("0")
				self.label_addvalue:setString("0")
				self.label_add_rest_time:unscheduleUpdate()
			end
		end
	end

	if self.extra_timeleft > 0 then
		self.label_add_rest_time:scheduleUpdateWithPriorityLua(updateLeftTimeLabel, 0)
		self.label_add_rest_time:setString(tools.convertTimeElectronicWatch(self.extra_timeleft, 3))
	else
		self.label_add_rest_time:setString("0")
	end
end

function init_binding_event(self)

	if self.proxy_ ~= nil then
		local function open_score_rank(btn, event)
			--cclog("1111---open_score_rank")
			local rankDlg = createObj(ui_multiBattleScoreDlg)
			GetMainMenu():GetModelLayer():AddDialog(rankDlg.node_, 3)
		end

		local function btn_Inspire(btn, event)
			--cclog("1111---no inspire")

			local function inspireAttribute()
				local urlpath = GetMultiBattleHeader(self.playerData_.m_uid, 2, protocol.URL_W_CWAR)   --不需要传CMD
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
							self.playerInfo.extra = tonumber(item:find("extra")[1])
							self.extra_timeleft = tonumber(item:find("extra_left")[1])

							local extralefts = item:find("extra_time_lefts")
							local inspires = {}
							for i = 1, #extralefts do
								table.insert(inspires, tonumber(extralefts:find("timeleft")[1]))
							end
							self.label_addvalue:setString(tostring(self.playerInfo.extra) .. "%")
							self.playerInfo.inspireList = inspires
							self.playerInfo.extra_my_times = #self.playerInfo.inspireList
							self:update_ui_for_frame()
						else
							GetMainMenu():ShowErrorTip(tonumber(retcode), -1)
						end
					end)
			end
			local dlg = CommonDialogView.create()
			CommonDialogView.m_selfview = dlg
			dlg:SetTitle(localizable.ui_inspire_title)
			--local str = string.format(localizable.ui_inspire_description, 500, MULTI_BATTLE_INSPIRE_VALUE, self.playerInfo.extra_my_times, self.playerInfo.extra_times_lmt)

			local str = string.format(localizable.ui_inspire_description, MULTI_BATTLE_INSPIRE_COST, MULTI_BATTLE_INSPIRE_VALUE, MULTI_INSPIRE_TIME, self.playerInfo.extra_my_times, self.playerInfo.extra_times_lmt)
			dlg:SetDescription(str)
			dlg:loadCCBI(kCCMenuHandlerPriority-4, "CommonDialogView")
			dlg:initUI(kCCMenuHandlerPriority-5)
			dlg:SetConfirmHandler(inspireAttribute)
			GetMainMenu():GetModelLayer():AddDialog(dlg, 3)
		end

		local function update_pos_info()
			self:update_data()
		end
		self.ctrl_get_score:setTouchPriority(-2)
		self.btn_Inspire:setTouchPriority(-2)
		self.btn_more_fights:setTouchPriority(-2)

		self.proxy_:handleControlEvent(self.ctrl_get_score, open_score_rank, CCControlEventTouchUpInside)
		self.proxy_:handleControlEvent(self.btn_Inspire, btn_Inspire, CCControlEventTouchUpInside)
		self.proxy_:handleControlEvent(self.btn_more_fights, update_pos_info, CCControlEventTouchUpInside)
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
			r = self.cellsize;
		elseif fn == "cellAtIndex" then
    		local nodeLayer = createObj(ui_multiBattlingItem, self.cellsize, self.playerInfo, self.battleInfoData[a1 + 1], self)
			if not a2 then
				a2 = CCTableViewCell:create()
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

function update_data(self)
	local urlpath = GetMultiBattleHeader(self.playerData_.m_uid, 0, protocol.URI_R_CWARLIST)   --不需要传CMD
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

				local userItem = item:find("user")
				self:playerInfoForSelf(userItem)

				--解析其他玩家信息
				local otherItem = item:find("positionlist")
				self:playerInfoForOther(otherItem)

				self.label_mypos:setString(tostring(self.playerInfo.posid))
				self.label_myrank:setString(tostring(self.playerInfo.rank))
				self.label_my_score:setString(tostring(self.playerInfo.score))
				self.tableview:reloadData()
			else
				GetMainMenu():ShowErrorTip(tonumber(retcode), -1)
			end
		end)
end

function playerInfoForSelf(self, userItem)
	self.playerInfo = {}
	self.playerInfo.uid = userItem:find("uid")[1]
	self.playerInfo.isin = userItem:find("isin")[1]
	self.playerInfo.posid = userItem:find("posid")[1]
	self.playerInfo.pf = userItem:find("pf")[1]
	self.playerInfo.zone = userItem:find("zone")[1]
	self.playerInfo.rank = userItem:find("rank")[1]
	self.playerInfo.score = userItem:find("score")[1]
	self.playerInfo.extra = tonumber(userItem:find("extra")[1])
	self.playerInfo.extra_timeleft = tonumber(userItem:find("extra_timeleft")[1])
	self.playerInfo.keep_left = userItem:find("keep_left")[1]
	self.playerInfo.timeval = userItem:find("timeval")[1]
	self.playerInfo.addscore = userItem:find("addscore")[1]
	self.playerInfo.viplevel = userItem:find("viplevel")[1]
	self.playerInfo.playerlevel = userItem:find("playerlevel")[1]

	self.playerInfo.extra_times_lmt = tonumber(userItem:find("extra_times_lmt")[1])
	self.playerInfo.inspireList = {}
	local inspireList = userItem:find("extra_time_lefts")
	for i = 1, #inspireList do
		table.insert(self.playerInfo.inspireList, tonumber(inspireList:find("timeleft")[1]))
	end
	self.playerInfo.extra_my_times = #inspireList

	self.playerInfo.cardInfo = {}
	local cardInfo = userItem:find("card")
	self.playerInfo.cardInfo.id = cardInfo:find("id")[1]
	self.playerInfo.cardInfo.life = cardInfo:find("life")[1]
	self.playerInfo.cardInfo.strength = cardInfo:find("strength")[1]
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


function init_selfUserInfo(self)
	if self.playerInfo.isin == "1" then
			self.label_my_time_score:setString("+" .. tostring(self.playerInfo.addscore) ..localizable.ui_multi_acc_score .. tostring(self.playerInfo.timeval) .. localizable.ui_multi_time_sec)
			self.label_mypos:setString(tostring(self.playerInfo.posid))
			self.label_myrank:setString(tostring(self.playerInfo.rank))
			self.label_my_score:setString(tostring(self.playerInfo.score))
			if self.playerInfo.extra ~= 0 then
				self.label_addvalue:setString(tostring(self.playerInfo.extra) .. "%")
				self.node_addcontent:setVisible(true)
			else
				self.node_addcontent:setVisible(true)
				self.label_add_rest_time:setString("0")
				self.label_addvalue:setString(tostring(self.playerInfo.extra))
			end
		else
			self.node_myinfo:setVisible(false)
			self.btn_Inspire:setEnabled(false)
			self.btn_Inspire:setVisible(false)
		end
end


--挑战以后更新界面结果
function update_all_ui(self)
	self:init_itemInfoForUser()
	self.tableview:reloadData()
end

function onNodeCleanup(self)
	if self.proxy_ then
    	self.proxy_:release()
    end
    layer_base_t.onNodeCleanup(self)
end

function createTestData(self)
	self.battleInfoData = {}
end