--玩家等级排行榜
--chenchun
---------------------------------------------
module("ui_BorderAwardLayer", package.seeall)
baseClass(layer_base_t, ui_BorderAwardLayer)

function init(self)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	local winSize = CCDirector:sharedDirector():getWinSize()
	local ccbiAttrTable = {name="dlg_ui/GetWardRewardDialog.ccbi", size=CCSizeMake(768, winSize.height)}
	layer_base_t.init(self, true, ccbiAttrTable)
	self.awardList = {}
	self:init_ui()
	self:init_binding_event()
end

function init_ui(self)
		--屏蔽掉后层触摸事件
	
		if self.proxy_ ~= nil then
		self.rank_tableContent = tolua.cast(self.proxy_:getNode("node_tableContent"), "CCNode")
		self.rank_cellnode = tolua.cast(self.proxy_:getNode("node_cellnode"), "CCNode")
		

		self.label_left_time:setString("")
		self.label_level:setString(tostring(self.playerData_.m_level))
		self.label_rank:setString("")

		local function updateLeftTimeLabel(fDeltaTime)
			self.deltatime = self.deltatime + fDeltaTime
			if self.deltatime >= 1 then
				local intPart, floatPart = math.modf(self.deltatime)
				self.leftTime = self.leftTime - intPart
				if self.leftTime > 0 then
					local timeStr = tools.convertTimeElectronicWatchHaveDay(self.leftTime, 3)
					self.label_left_time:setString(timeStr)
					self.deltatime = floatPart
				else
					self.label_left_time:setString(localizable.ui_border_end)
					self.label_left_time:unscheduleUpdate()
				end
			end
		end

		local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, protocol.CMD_R_COMM, protocol.URL_R_COMM)
		GetMainMenu():ShowLoadingDlg();	-- 获取信息的时候，不允许操作
		CCHttpRequest:open(urlpath, kHttpPost,"query=param1&other=params"):sendWithHandler(
			function(res, hnd)
				GetMainMenu():CloseLoadding(); --获取信息完成时，解除禁止操作

				local resData = res:getResponseData()
				local code = res:getResponseCode()
				local xfile = xml.parse(resData)
				local item = xfile:find("RENLONG")
				if item == nil then
					return nil
				end
				local retcode = item.code
				if retcode == "0" then
					self.levelType = item:find("preview").type       --用于判断现在是领取还是正在做活动，1-代表正在活动，2-代表领取，3-代表活动过期
					if self.levelType == "2" then
						local pFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("textures4_06")
						self.sprite_activity_status:setDisplayFrame(pFrame)
					end
					if self.levelType == "1" or self.levelType == "2" then
						self.leftTime = tonumber(item:find("preview").resttime)
						local levelrankItems = item:find("levelrank")
						if levelrankItems then
							self.myrank = levelrankItems.my
							for i = 1, #levelrankItems do
								self.rankData[i] = {rank=levelrankItems[i][1][1], playerid=levelrankItems[i][2][1], name=levelrankItems[i][3][1],
								country=levelrankItems[i][4][1], level=levelrankItems[i][5][1]}
							end
						end
						if self.myrank == "0" then
							self.label_rank:setString(localizable.ui_border_temp_not)
						elseif tonumber(self.myrank) > 200 then
							self.label_rank:setString("200" .. localizable.ui_border_num_after)
						else
							self.label_rank:setString(self.myrank)
						end
						local awardItems = item:find("awardlist")
						if awardItems then
							self.awardList = {}
							for i = 1, #awardItems do
								if awardItems[i][2][1] == "1" then
									if self.awardList[awardItems[i][3][1]] ~= nil then
										if tonumber(self.awardList[awardItems[i][3][1]].beginrank) > tonumber(awardItems[i][1][1]) then
											self.awardList[awardItems[i][3][1]].beginrank = awardItems[i][1][1]
										elseif tonumber(self.awardList[awardItems[i][3][1]].endrank) < tonumber(awardItems[i][1][1]) then
											self.awardList[awardItems[i][3][1]].endrank = awardItems[i][1][1]
										end
									else
										self.awardList[awardItems[i][3][1]] = {beginrank=awardItems[i][1][1], endrank = awardItems[i][1][1], giftname=awardItems[i][4][1], icon=awardItems[i][3][1]}
									end
									--cclog("1111---%s, %s, %s, %s",awardItems[i][1][1], awardItems[i][2][1], awardItems[i][3][1], awardItems[i][4][1])
								end
							end
							local i = 1
							local j = 1
							for k, v in pairs(self.awardList) do
								for k, v in pairs(self.awardList) do
									if tonumber(self.awardList[k].beginrank) == j then
										self.awardListIndex[i] = self.awardList[k]
										j = tonumber(self.awardList[k].endrank) + 1
										break
									end
								end
								i = i + 1
							end
						end

						if self.leftTime > 0 then
							self.label_left_time:scheduleUpdateWithPriorityLua(updateLeftTimeLabel, 0)
							self.label_left_time:setString(tools.convertTimeElectronicWatchHaveDay(self.leftTime, 3))
						else
							self.label_left_time:setString(localizable.ui_border_has_ended)
						end
						self:createRankTableView()
					end

					--GetMainMenu():ShowTextTip("领取成功",-1)
				else

					--GetMainMenu():ShowErrorTip(retcode,-1)
				end

			end)
	end
end


function init_binding_event(self)

	local function CCLayerTouch(event, x, y)
			local rect = self.node_:boundingBox()
			rect.origin = ccp(0,0)
			local p = self.node_:convertToNodeSpace(ccp(x,y))
			--截获界面内后层的信息
			if rect:containsPoint(p) == true then
				if event == "began" then	
				 	return true
				end
			end	
		end

	self.node_:setTouchEnabled(true)
	self.node_:registerScriptTouchHandler(CCLayerTouch, false, kCCMenuHandlerPriority-2, true)
		
	self.btn_close = tolua.cast(self.proxy_:getNode("btnDialogClose"), "CCControlButton")
	self.btn_close:setTouchPriority(kCCMenuHandlerPriority - 2)
	self.btn_close:setTouchEnabled(true)
	
	self.btn_get_award = tolua.cast(self.proxy_:getNode("btn_get_award"), "CCControlButton")
	self.btn_get_award:setTouchPriority(kCCMenuHandlerPriority - 2)
	self.btn_get_award:setTouchEnabled(true)
	
	local function closethis()
		self.node_:removeFromParentAndCleanup(true)
	end
	local function getaward()
		
	end
	if self.proxy_ ~= nil then
		self.proxy_:handleControlEvent(self.btn_close, closethis, CCControlEventTouchUpInside)
		self.proxy_:handleControlEvent(self.btn_get_award, getaward, CCControlEventTouchUpInside)
	end
end

function onNodeCleanup(self)
	--cclog("1111---002")
	if self.proxy_ then
    	self.proxy_:release()
    end
    layer_base_t.onNodeCleanup(self)
end

--local funtion
function createRankTableView(self, data)
	-- body
	if self.rankTableView == nil then
		self.rank_cellsize = self.rank_cellnode:getContentSize()
		self.rank_tableContentSize = self.rank_tableContent:getContentSize()
		self:initRankTableHandle()
		self.rankTableView = LuaTableView:createWithHandler(self.rankTableViewHandler, CCSizeMake(self.rank_tableContentSize.width, self.rank_tableContentSize.height))
		self.rankTableView:setDirection(kCCScrollViewDirectionVertical)
		self.rankTableView:setVerticalFillOrder(kCCTableViewFillTopDown)
		self.rankTableView:setTouchPriority(kCCMenuHandlerPriority - 2)
		self.rank_tableContent:addChild(self.rankTableView)

		--local offset = self.rankTableView:getContentOffset()
		--self.rankTableView:reloadData()
		--self.rankTableView:setContentOffset(offset.x, offset.y)
	end
end

function initRankTableHandle(self)
	self.rankTableViewHandler = LuaEventHandler:create(function(fn, table, a1, a2, x, y)
		local r
		if fn == "cellSize" then
			r = self.rank_cellsize;
		elseif fn == "cellAtIndex" then
    		local nodeLayer = createObj(ui_levelRankTableCell, self.rank_cellsize, self.rankData[a1 + 1])
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
			--local cellIndex = a1:getIdx() + 1
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

function createRankGiftTableView(self, data)
	-- body
	if self.rankGiftTableView == nil then
		self.rank_gift_cellsize = self.gift_cellnode:getContentSize()
		self.rank_gift_tableContentSize = self.gift_tableContent:getContentSize()
		self:initRankGiftTableHandle()
		self.rankGiftTableView = LuaTableView:createWithHandler(self.rankGiftTableViewHandler, CCSizeMake(self.rank_gift_tableContentSize.width, self.rank_gift_tableContentSize.height))
		self.rankGiftTableView:setDirection(kCCScrollViewDirectionHorizontal)
		self.rankGiftTableView:setVerticalFillOrder(kCCTableViewFillTopDown)
		self.rankGiftTableView:setTouchPriority(-10)
		self.gift_tableContent:addChild(self.rankGiftTableView)

		--local offset = self.rankGiftTableView:getContentOffset()
		--self.rankGiftTableView:reloadData()
		--self.rankGiftTableView:setContentOffset(offset.x, offset.y)
	end
end

function initRankGiftTableHandle(self)
	self.rankGiftTableViewHandler = LuaEventHandler:create(function(fn, table, a1, a2, x, y)
		local r
		if fn == "cellSize" then
			r = self.rank_gift_cellsize;
		elseif fn == "cellAtIndex" then
    		local nodeLayer = createObj(ui_levelRankGiftTableCell, self.rank_gift_cellsize, self.awardListIndex[a1 + 1])
			if not a2 then
				a2 = CCTableViewCell:create()
				a2:addChild(nodeLayer.node_)
			else
				a2:removeAllChildrenWithCleanup(true)
        		a2:addChild(nodeLayer.node_)
			end
			r = a2
		elseif fn == "numberOfCells" then
			r = #self.awardListIndex;
		-- Cell events:
		elseif fn == "cellTouched" then			-- A cell was touched, a1 is cell that be touched. This is not necessary.
			local cellIndex = a1:getIdx() + 1
			if self.levelType == "1" then
			    local dlg = CommonDialogView.create()
				CommonDialogView.m_selfview = dlg
				dlg:SetTitle(localizable.ui_rank_gift_title)
				local showContent = self.awardListIndex[cellIndex].giftname
				dlg:SetDescription(showContent)
				dlg:loadCCBI()
				dlg:initUI()
				GetMainMenu():GetModelLayer():AddDialog(dlg, 3)
			elseif self.levelType == "2" then
				local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, protocol.CMD_W_COMM03, protocol.URL_W_COMM)
				GetMainMenu():ShowLoadingDlg();	-- 获取信息的时候，不允许操作
				CCHttpRequest:open(urlpath, kHttpPost, "query=param1&other=params"):sendWithHandler(
				function(res, hnd)
					GetMainMenu():CloseLoadding(); --获取信息完成时，解除禁止操作
					local resData = res:getResponseData()
					local code = res:getResponseCode()
					local xfile = xml.parse(resData)
					local item = xfile:find("RENLONG")
					if item == nil then
						return nil
					end
					local retcode = item.code
					if retcode == "0" then
						local awardXML = xfile:find("award")
						ShowAward(awardXML);
						--GetMainMenu():ShowTextTip("领取成功",-1)
					else
						GetMainMenu():ShowTextTip(localizable.ui_border_has_got_tips, -1)
					end
				end)
			end
			--PayHelperForLua:goldPay(tostring(self.rechargeTable[cellIndex].rmb), payid, displayinfo .. "元宝", tostring(self.rechargeTable[cellIndex].id), "0")
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


--创建测试数据
function createTestData(self)
	self.rankData = {}
	self.giftData = {}
	for i = 1, 10 do
		self.rankData[i] = {rank=i, country="火之国", name="火影忍龙之陈春",level=i}
	end
	for j = 1, 7 do
		self.giftData[j] = {id = j, icon="npc11_2", desc="第一名奖励"}
	end
	self.leftTime = 96400
end