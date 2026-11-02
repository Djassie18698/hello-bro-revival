--descriptioin:跨服功勋
--company: xckoo
--author: chenchun
--date: 2014-2-19
---------------------------------------------
module("ui_multiBattleRank", package.seeall)
baseClass(layer_base_t, ui_multiBattleRank)

function init(self, parentSize, leftTime, playerInfo, othersPlayer)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	self.contentSize_ = parentSize
	local ccbiAttrTable = {name="multiserverbattle/multiBattleRank.ccbi", size=self.contentSize_}
	layer_base_t.init(self, true, ccbiAttrTable)

	self:createTestData()
	--self.rankData = {[1] = 1, [2] = 2, [3] = 3, [4] = 4, [5] = 5, [6] = 6, [7] = 7}
	--self.giftInfoData = {[1] = 1, [2] = 2, [3] = 3, [4] = 4, [5] = 5, [6] = 6, [7] = 7}
	self.isGiftIcon = false    --表的cell 是否可以领取奖励，只有上期排行会显示
	self.myinfo = {}
	self.giftInfoData = {}
	self.rankData = {}
	self.topGiftInfoData = {}
	self.leftScore = 0
	self.curTag = 0
	self:init_ui()
	self:init_binding_event()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		self.ctrl_last_rank = tolua.cast(self.proxy_:getNode("ctrl_last_rank"), "CCControlButton")
		self.ctrl_server_rank = tolua.cast(self.proxy_:getNode("ctrl_server_rank"), "CCControlButton")
		self.ctrl_country_rank = tolua.cast(self.proxy_:getNode("ctrl_country_rank"), "CCControlButton")
		self.ctrl_history_rank = tolua.cast(self.proxy_:getNode("ctrl_history_rank"), "CCControlButton")

		self.label_acc_score = tolua.cast(self.proxy_:getNode("label_acc_score"), "CCLabelBMFont")
		self.node_cardcontent1 = tolua.cast(self.proxy_:getNode("node_cardcontent1"), "CCNode")
		self.node_tablecontent = tolua.cast(self.proxy_:getNode("node_tablecontent"), "CCNode")
		self.gift_tablecontent = tolua.cast(self.proxy_:getNode("gift_tablecontent"), "CCNode")
		self.gift_cellnode = tolua.cast(self.proxy_:getNode("gift_cellnode"), "CCNode")
		self.label_nickname = tolua.cast(self.proxy_:getNode("label_nickname"), "CCLabelTTF")

		self.ctrl_last_rank:setTag(1)
		self.ctrl_server_rank:setTag(2)
		self.ctrl_country_rank:setTag(3)
		self.ctrl_history_rank:setTag(4)

		self.ctrl_last_rank:setEnabled(false)
		self.btns = {[1] = self.ctrl_last_rank, [2] = self.ctrl_server_rank, [3] = self.ctrl_country_rank, [4] = self.ctrl_history_rank}

		self.label_acc_score:setString(tostring(self.leftScore))
		self:reGetRankData(1)
		self:initRankTableView()
		self:initGiftTableView()
	end
end


function init_binding_event(self)
	if self.proxy_ ~= nil then
		local function get_rankData(btn)
			local tag = btn:getTag()
			if tag ~= self.curTag then
				self.btns[self.curTag]:setEnabled(true)
				btn:setEnabled(false)

				self:reGetRankData(tag)
				self.tableview:reloadData()
			end
		end
		self.ctrl_last_rank:setTouchPriority(-2)
		self.ctrl_server_rank:setTouchPriority(-2)
		self.ctrl_country_rank:setTouchPriority(-2)
		self.ctrl_history_rank:setTouchPriority(-2)

		self.proxy_:handleControlEvent(self.ctrl_last_rank, get_rankData, CCControlEventTouchUpInside)
		self.proxy_:handleControlEvent(self.ctrl_server_rank, get_rankData, CCControlEventTouchUpInside)
		self.proxy_:handleControlEvent(self.ctrl_country_rank, get_rankData, CCControlEventTouchUpInside)
		self.proxy_:handleControlEvent(self.ctrl_history_rank, get_rankData, CCControlEventTouchUpInside)
	end
end

function reGetRankData(self, tag)
	local urlpath = GetMultiBattleHeader(self.playerData_.m_uid, tag, protocol.URL_R_CROSSWAR_RANK)   --拉取当前实时排名数据
			--urlpath = AddData(urlpath, "ToUid", self.rank_data.playerid)
	cclog("1111----%s", urlpath)
	self.curTag = tag
	if tag == 2 then
		self.label_nickname:setString(localizable.ui_multi_platform)
	else
		self.label_nickname:setString(localizable.ui_multi_name)
	end

	if tag == 1 then
		self.isGiftIcon = true
	else
		self.isGiftIcon = false
	end
	GetMainMenu():ShowLoadingDlg();	-- 获取信息的时候，不允许操作
	CCHttpRequest:open(urlpath, kHttpPost,"query=param1&other=params"):sendWithHandler(
		function(res, hnd)
			GetMainMenu():CloseLoadding(); --获取信息完成时，解除禁止操作
			local resData = res:getResponseData()
			cclog("1111----%s", resData)
			local code = res:getResponseCode()
			local xfile = xml.parse(resData)
			local item = xfile:find("RENLONG")
			local retcode = item.code
			if retcode == "0" then
				local ranklist = item:find("rank_list")
				self.rankData = {}
				if ranklist ~= nil then
					for i = 1, #ranklist do
						local data = {}
						if tag == 1 then
							data.uid = ranklist[i].col0
						end
						data.rank = ranklist[i].col1
						data.zone = ranklist[i].col2
						if tag == 2 then
							data.name = GetPlatformStr()
						else
							data.name = ranklist[i].col3
						end
						data.score = ranklist[i].col4
						table.insert(self.rankData, data)
					end
				end
				if tag == 1 then
					local playerItem = item:find("player")
					if playerItem ~= nil then
						self.myinfo = {}
						self.myinfo.myscore = item:find("score")[1]
						self.myinfo.myrank = item:find("rank")[1]
						self.myinfo.myzone = item:find("zone")[1]
						self.myinfo.myuid = item:find("uid")[1]

						self.leftScore = tonumber(item:find("score_left")[1])
					end
				end
				local giftList = item:find("score_package")
				if giftList ~= nil and #giftList > 0 then
					self.giftInfoData = {}
					for i = 1, #giftList do
						local giftInfo = {}
						giftInfo.id = giftList[i]:find("id")[1]
						giftInfo.icon = giftList[i]:find("icon")[1]
						giftInfo.cost = giftList[i]:find("cost")[1]
						giftInfo.desc = giftList[i]:find("desc")[1]
						table.insert(self.giftInfoData, giftInfo)
					end
				end

				local top_ten_giftList = item:find("topten_award")
				if top_ten_giftList ~= nil and #top_ten_giftList > 0 then
					self.topGiftInfoData = {}
					for i = 1, #top_ten_giftList do
						local topGiftInfo = {}
						topGiftInfo.id = top_ten_giftList[i]:find("id")[1]
						topGiftInfo.rank = top_ten_giftList[i]:find("rank")[1]
						topGiftInfo.desc = top_ten_giftList[i]:find("desc")[1]
						self.topGiftInfoData[tonumber(topGiftInfo.rank)] = topGiftInfo
					end
				end
				self.label_acc_score:setString(tostring(self.leftScore))
				self.tableview:reloadData()
				self.gifttableview:reloadData()
				if #self.rankData == 0 then
					GetMainMenu():ShowTextTip(localizable.ui_multi_not_rank_data, -1)
				end
			else
				self.rankData = {}
				self.tableview:reloadData()
				--GetMainMenu():ShowErrorTip(tonumber(retcode), -1)
				GetMainMenu():ShowTextTip(text.text_config[tonumber(retcode)].description, -1)
			end
		end)
end


--private function
function initRankTableView(self)
	-- body
	if self.tableview == nil then
		self.cellsize = self.node_cardcontent1:getContentSize()
		self.tableContentSize = self.node_tablecontent:getContentSize()
		self:initRankHandle()
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

function initGiftTableView(self)
	-- body
	if self.gifttableview == nil then
		self.giftcellsize = self.gift_cellnode:getContentSize()
		self.giftTableContentSize = self.gift_tablecontent:getContentSize()
		self:initGiftHandle()
		self.gifttableview = LuaTableView:createWithHandler(self.tableGiftViewHandler, CCSizeMake(self.giftTableContentSize.width, self.giftTableContentSize.height))

		self.gifttableview:setDirection(kCCScrollViewDirectionHorizontal)
		self.gifttableview:setVerticalFillOrder(kCCTableViewFillTopDown)
		self.gifttableview:setTouchPriority(-2)
		self.gift_tablecontent:addChild(self.gifttableview)
		--local offset = self.tableview:getContentOffset()
		--self.tableview:reloadData()
		--self.tableview:setContentOffset(offset.x, offset.y)
		--self.tableview:setDragEnabled(true)
	end
end

function initRankHandle(self)
	self.tableViewHandler = LuaEventHandler:create(function(fn, table, a1, a2, x, y)
		local r
		if fn == "cellSize" then
			r = self.cellsize;
		elseif fn == "cellAtIndex" then
    		local nodeLayer = createObj(ui_multiRankItem, self.cellsize, self.rankData[a1 + 1], self.isGiftIcon, self.myinfo, self.topGiftInfoData)
			if not a2 then
				a2 = CCTableViewCell:create()
				a2:addChild(nodeLayer.node_)
			else
				a2:removeAllChildrenWithCleanup(true)
        		a2:addChild(nodeLayer.node_)
			end
			r = a2
		elseif fn == "numberOfCells" then
			r = #self.rankData;
		-- Cell events:
		elseif fn == "cellTouched" then			-- A cell was touched, a1 is cell that be touched. This is not necessary.

		elseif fn == "cellTouchBegan" then		-- A cell is touching, a1 is cell, a2 is CCTouch
			r = true
		elseif fn == "cellTouchEnded" then		-- A cell was touched, a1 is cell, a2 is CCTouch
			--cclog("1111---000000000")
		elseif fn == "cellHighlight" then		-- A cell is highlighting, coco2d-x 2.1.3 or above
		elseif fn == "cellUnhighlight" then		-- A cell had been unhighlighted, coco2d-x 2.1.3 or above
		elseif fn == "cellWillRecycle" then		-- A cell will be recycled, coco2d-x 2.1.3 or above
		end
		return r
	end)
end

function initGiftHandle(self)
	self.tableGiftViewHandler = LuaEventHandler:create(function(fn, table, a1, a2, x, y)
		local r
		if fn == "cellSize" then
			r = self.giftcellsize;
		elseif fn == "cellAtIndex" then
    		local nodeLayer = createObj(ui_multiRankGiftItem, self.giftcellsize, self.giftInfoData[a1 + 1])
			if not a2 then
				a2 = CCTableViewCell:create()
				a2:addChild(nodeLayer.node_)
			else
				a2:removeAllChildrenWithCleanup(true)
        		a2:addChild(nodeLayer.node_)
			end
			r = a2
		elseif fn == "numberOfCells" then
			r = #self.giftInfoData;
		elseif fn == "cellTouched" then			-- A cell was touched, a1 is cell that be touched. This is not necessary.
			local cellIndex = a1:getIdx() + 1
			local excid = self.giftInfoData[cellIndex].id

			local function openDialogGetGift()
				if self.leftScore >= tonumber(self.giftInfoData[cellIndex].cost) then
					self:exchangeGift(excid, self.giftInfoData[cellIndex])
				else
					GetMainMenu():ShowTextTip(localizable.ui_multi_not_enough_get_gift_tips, "-1")
				end
			end

			local dlg = CommonDialogView.create()
			CommonDialogView.m_selfview = dlg
			dlg:SetTitle(localizable.ui_rank_gift_title)
			dlg:SetDescription(self.giftInfoData[cellIndex].desc)
			dlg:loadCCBI()
			dlg:initUI()
			dlg:SetConfirmHandler(openDialogGetGift)
			dlg:updateLeftBtnText(localizable.ui_common_exchage_text)
			GetMainMenu():GetModelLayer():AddDialog(dlg, 3)
			
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

function exchangeGift(self, ExchId, giftData_)
	
	local function exchange_gift()
		local urlpath = GetMultiBattleHeader(self.playerData_.m_uid, 3, protocol.URL_W_CWAR)   --兑换奖励
		urlpath = AddData(urlpath, "ExchId", ExchId)
		cclog("1111----%s", urlpath)

		GetMainMenu():ShowLoadingDlg();	-- 获取信息的时候，不允许操作
		CCHttpRequest:open(urlpath, kHttpPost,"query=param1&other=params"):sendWithHandler(
			function(res, hnd)
				GetMainMenu():CloseLoadding(); --获取信息完成时，解除禁止操作
				local resData = res:getResponseData()
				cclog("1111----%s", resData)
				local code = res:getResponseCode()
				local xfile = xml.parse(resData)
				local item = xfile:find("RENLONG")
				local retcode = item.code
				if retcode == "0" then
					self.leftScore = tonumber(item:find("myscore_left")[1])
					self.label_acc_score:setString(tostring(self.leftScore))
					local awardXML = item:find("award")
					ShowAward(awardXML)
				else
					GetMainMenu():ShowErrorTip(tonumber(retcode), -1)
				end
			end)
	end

	exchange_gift()
	--[[
	local dlg = CommonDialogView.create()
	CommonDialogView.m_selfview = dlg
	dlg:SetTitle(localizable.ui_multi_exchange_gift)
	--local str = string.format(localizable.ui_inspire_description, 500, MULTI_BATTLE_INSPIRE_VALUE, self.playerInfo.extra_my_times, self.playerInfo.extra_times_lmt)
	dlg:SetDescription(giftData_.desc)
	dlg:loadCCBI(kCCMenuHandlerPriority-4, "CommonDialogView")
	dlg:initUI(kCCMenuHandlerPriority-5)
	dlg:SetConfirmHandler(exchange_gift)
	GetMainMenu():GetModelLayer():AddDialog(dlg, 3)
	]]
end

function createTestData(self)
	self.rankData = {}
	for i = 1, 12 do
		local data = {}
		data.id = tostring(i)
		data.rank = tostring(i)
		data.zone = tostring(i)
		data.name = tostring(i) .. "消失的影子"
		data.score = tostring(i * 100)
		table.insert(self.rankData, data)
	end
	self.giftInfoData = {}

	for i = 1, 5 do
		local giftData = {}
		giftData.id = i
		giftData.icon = "props_144"
		giftData.score = "5000"
		table.insert(self.giftInfoData, giftData)
	end
end