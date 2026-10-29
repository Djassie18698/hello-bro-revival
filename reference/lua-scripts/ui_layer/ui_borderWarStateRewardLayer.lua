--边界碑游荡奖励
--litao
--2014-2-17
---------------------------------------------
module("ui_borderWarStateRewardLayer", package.seeall)
baseClass(layer_base_t, ui_borderWarStateRewardLayer)

require("ui_layer/ui_borderWarStateRewardCell1.lua")

function init(self, node, data)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	local winSize = CCDirector:sharedDirector():getWinSize()

	--Load res
	local ccbiAttrTable = {name="activity/BorderWarStateRewardView.ccbi", size=CCSizeMake(768, winSize.height)}
	layer_base_t.init(self, true, ccbiAttrTable)

	self.preNode = node
	--当前积分
	self.m_curData = data
	--状态信息数据
	self.m_rewardDatas = {}
	--奖励信息列表
	self.m_rewardItemList = {}
	--领取获取物品列表
	self.m_getAwardlist = {}
	--是否清理外面的状态
	self.isClear = false

	self.tableData = {}

	self:init_ui()
	self:init_binding_event()
end


function init_ui(self)
	if self.proxy_ ~= nil then
		--领奖Btn
		self.btnGetAward = tolua.cast(self.proxy_:getNode("stateReward_getRewardBtn"), "CCControlButton")
		--关闭按钮
		self.btnDialogClose = tolua.cast(self.proxy_:getNode("closeButton"), "CCControlButton")
		--次数
		for i=1,4 do
			self["label_"..(i)] = tolua.cast(self.proxy_:getNode("label_"..tostring(i)), "CCLabelTTF")
		end
		--滑动frame
		self.node_cell = tolua.cast(self.proxy_:getNode("cellNode"), "CCNode")
		self.node_content = tolua.cast(self.proxy_:getNode("contentNode"), "CCNode")

		self.node_cell1 = tolua.cast(self.proxy_:getNode("node_cell1"), "CCNode")
		self.node_content1 = tolua.cast(self.proxy_:getNode("node_content1"), "CCNode")	

		---[[
		--获取信息
		local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 1, "rl_r_frontiers_war_award_info")
		urlpath = AddData(urlpath, "Country", self.playerData_.m_countrytype)
		--cclog("rl_r_frontiers_war_award_info----%s", urlpath)
		GetMainMenu():ShowLoadingDlg()
		CCHttpRequest:open(urlpath, kHttpPost,"query=param1&other=params"):sendWithHandler(
			function(res, hnd)
				GetMainMenu():CloseLoadding()
				local resData = res:getResponseData()
				local code = res:getResponseCode()
				local xfile = xml.parse(resData)
				local item = xfile:find("RENLONG")
				local retcode = item.code
				--cclog("rl_r_frontiers_war_award_info----%s", resData)
				if retcode == "0" then
					--奖励记录
					local count_info = item:find("award_count")
					if count_info then
						local total_provoke = count_info:find("total_defiance")[1]
						local cur_provoke = count_info:find("current_defiance")[1]
						self["label_1"]:setString(tostring(cur_provoke.."/"..total_provoke..localizable.ui_border_times_unit))

						local total_wander = count_info:find("total_wander")[1]
						local cur_wander = count_info:find("current_wander")[1]
						self["label_2"]:setString(tostring(cur_wander.."/"..total_wander..localizable.ui_border_times_unit))

						local total_c_provoke = count_info:find("total_clear_defiance")[1]
						local cur_c_provoke = count_info:find("current_clear_defiance")[1]
						self["label_3"]:setString(tostring(cur_c_provoke.."/"..total_c_provoke..localizable.ui_border_times_unit))

						local total_c_wander = count_info:find("total_clear_wander")[1]
						local cur_c_wander = count_info:find("current_clear_wander")[1]
						self["label_4"]:setString(tostring(cur_c_wander.."/"..total_c_wander..localizable.ui_border_times_unit))
					end
					--奖励信息
					local awardList = item:find("award_list")					
					if awardList then						
						for i = 1, #awardList do
							local tempitem = {}
							tempitem.countryId = awardList[i].Country
							tempitem.exp = tonumber(awardList[i].Exp)					
							tempitem.merit = tonumber(awardList[i].Merit)

							local state_label = nil 
							local round = tonumber(awardList[i].Round)
							if tonumber(awardList[i].Status) == 1 then
								state_label = string.format(localizable.ui_border_tips21, tostring(round))
							elseif tonumber(awardList[i].Status) == 2 then
								state_label = string.format(localizable.ui_border_tips22, tostring(round))
							elseif tonumber(awardList[i].Status) == 3 then
								state_label = string.format(localizable.ui_border_tips23, tostring(round))
							else
								state_label = string.format(localizable.ui_border_tips24, tostring(round))
							end
							
							tempitem.label = state_label
							table.insert(self.m_rewardDatas, tempitem)
						end
					end
					--加载信息
					if #self.m_rewardDatas > 0 then
						self:createRankTableView()
					end

					self.tableData = item:find("attack_award_list")
					if self.tableData then
						self:createTableView()
					end
				end
			end)
		--]]		
	end
end

function createRankTableView(self)
	-- body
	if self.tableView == nil then
		local cellContentSize = self.node_cell:getContentSize()
		self.cellsize = CCSize(cellContentSize.width,cellContentSize.height)
		self.contentSize = self.node_content:getContentSize()
		self:initHandle()
		self.tableView = LuaTableView:createWithHandler(self.rankTableViewHandler, CCSizeMake(self.contentSize.width, self.contentSize.height))
		self.tableView:setDirection(kCCScrollViewDirectionVertical)
		self.tableView:setVerticalFillOrder(kCCTableViewFillTopDown)
		self.tableView:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.node_content:addChild(self.tableView)
	else
		self.tableView:reloadData()
	end
end

function initHandle(self)
	self.rankTableViewHandler = LuaEventHandler:create(function(fn, table, a1, a2, x, y)
		local r
		if fn == "cellSize" then
			r = self.cellsize
		elseif fn == "cellAtIndex" then
    		local nodeLayer = createObj(ui_borderWarStateRewardCell, self.cellsize, self.m_rewardDatas[a1 + 1])
    		if not a2 then
				a2 = CCTableViewCell:create()
				a2:addChild(nodeLayer.node_)
			else
				a2:removeAllChildrenWithCleanup(true)
        		a2:addChild(nodeLayer.node_)
			end
			r = a2
		elseif fn == "numberOfCells" then
			r = #self.m_rewardDatas
		    -- Cell events:
		elseif fn == "cellTouched" then			-- A cell was touched, a1 is cell that be touched. This is not necessary.
			---[[
			--local cellIndex = a1:getIdx() + 1
			--]]
		elseif fn == "cellTouchBegan" then		-- A cell is touching, a1 is cell, a2 is CCTouch
			r = true
		elseif fn == "cellTouchEnded" then		-- A cell was touched, a1 is cell, a2 is CCTouch
			local 
			r = true
		elseif fn == "cellHighlight" then		-- A cell is highlighting, coco2d-x 2.1.3 or above
		elseif fn == "cellUnhighlight" then		-- A cell had been unhighlighted, coco2d-x 2.1.3 or above
		elseif fn == "cellWillRecycle" then		-- A cell will be recycled, coco2d-x 2.1.3 or above
		end
		return r
	end)
end

function createTableView(self)
	-- body
	if self.tableView1 == nil then
		local cellContentSize = self.node_cell1:getContentSize()
		self.cellsize1 = CCSize(cellContentSize.width,cellContentSize.height)
		self.contentSize = self.node_content1:getContentSize()
		self:initTableHandle()
		self.tableView1 = LuaTableView:createWithHandler(self.rankTableViewHandler1, CCSizeMake(self.contentSize.width, self.contentSize.height))
		self.tableView1:setDirection(kCCScrollViewDirectionVertical)
		self.tableView1:setVerticalFillOrder(kCCTableViewFillTopDown)
		self.tableView1:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.node_content1:addChild(self.tableView1)
	else
		self.tableView1:reloadData()
	end
end

function initTableHandle(self)
	self.rankTableViewHandler1 = LuaEventHandler:create(function(fn, table, a1, a2, x, y)
		local r
		if fn == "cellSize" then
			r = self.cellsize1
		elseif fn == "cellAtIndex" then
    		local nodeLayer = createObj(ui_borderWarStateRewardCell1, self.cellsize1, self.tableData[a1 + 1])
    		if not a2 then
				a2 = CCTableViewCell:create()
				a2:addChild(nodeLayer.node_)
			else
				a2:removeAllChildrenWithCleanup(true)
        		a2:addChild(nodeLayer.node_)
			end
			r = a2
		elseif fn == "numberOfCells" then
			r = #self.tableData
		    -- Cell events:
		elseif fn == "cellTouched" then			-- A cell was touched, a1 is cell that be touched. This is not necessary.
			---[[
			--local cellIndex = a1:getIdx() + 1
			--]]
		elseif fn == "cellTouchBegan" then		-- A cell is touching, a1 is cell, a2 is CCTouch
			r = true
		elseif fn == "cellTouchEnded" then		-- A cell was touched, a1 is cell, a2 is CCTouch
			local 
			r = true
		elseif fn == "cellHighlight" then		-- A cell is highlighting, coco2d-x 2.1.3 or above
		elseif fn == "cellUnhighlight" then		-- A cell had been unhighlighted, coco2d-x 2.1.3 or above
		elseif fn == "cellWillRecycle" then		-- A cell will be recycled, coco2d-x 2.1.3 or above
		end
		return r
	end)
end




function init_binding_event(self)
	if self.proxy_ ~= nil then
		local function CCLayerTouch(event,x,y)
			local rect = self.node_:boundingBox()
			rect.origin = ccp(0,0)
			local p = self.node_:convertToNodeSpace(ccp(x,y))
			if event == "began" then
				if rect:containsPoint(p) == true then
					return true
				else
					return true
				end
			end
		end
		self.node_:setTouchEnabled(true)
		self.node_:registerScriptTouchHandler(CCLayerTouch, false, kCCMenuHandlerPriority - 1, true)

		local function close_window(btn, event)
			self.node_:removeFromParentAndCleanup(true)
		end

		local function onBtnGetAward(btn)
			CSoundMgr:instance():PlayEffect(SOUND_BUTTON)
			if #self.m_rewardDatas < 1 and #self.tableData < 1 then
				GetMainMenu():ShowTextTip(localizable.ui_border_tips25,-1)
				return nil
			end
			---[[得到游荡/挑衅奖励
			local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 1, "rl_r_frontiers_war_recv_award")
			if self.isClear then
				urlpath = AddData(urlpath, "IsClear", 1)
			else
				urlpath = AddData(urlpath, "IsClear", 0)
			end
			GetMainMenu():ShowLoadingDlg()
			CCHttpRequest:open(urlpath, kHttpPost, "query=param1&other=params"):sendWithHandler(
				function(res, hnd)
					GetMainMenu():CloseLoadding()
					local resData = res:getResponseData()
					local code = res:getResponseCode()
					local xfile = xml.parse(resData)
					local item = xfile:find("RENLONG")
					local retcode = item.code
					if retcode == "0" then
						--cclog("rl_w_monopoly_receive----%s", resData)
						local speciallAward = item:find("attack_award")
						if speciallAward then
							local exp = tonumber(speciallAward:find("exp")[1])
							local merit = tonumber(speciallAward:find("merit")[1])
							if exp == 0 and merit == 0 then
								GetMainMenu():ShowTextTip(localizable.ui_border_tips26,-1)
								return nil
							end
							self.playerMgr_:AddExp(exp)
							self.playerMgr_:AddMerit(merit)

							self.playerData_ = self.playerMgr_:GetPlayerInfoData()
							GetMainMenu():ShowTextTip(localizable.ui_border_get_gift_success,-1)
						end

						local awardXML = item:find("award")
						ShowAward(awardXML)

						self:updateMainInfo()
						self.node_:removeFromParentAndCleanup(true)
					else
						GetMainMenu():ShowErrorTip(tonumber(retcode), -1)
					end
				end)
		end

		--绑定按钮事件
		self.btnGetAward:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.proxy_:handleButtonEvent(self.btnGetAward, onBtnGetAward, CCControlEventTouchUpInside)

		self.btnDialogClose:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.proxy_:handleControlEvent(self.btnDialogClose, close_window, CCControlEventTouchUpInside)
	end
end

function updateMainInfo(self)
	self.preNode:startRequestCountryInfo(self.preNode.m_curCountryId)
	self.preNode:startRequestPlayerInfo()

	self.preNode.label_gold:setString(tostring(self.playerData_.m_gold))
	self.preNode.label_silver:setString(tostring(self.playerData_.m_silver))
end

function onNodeCleanup(self)
    --cclog("onNodeCleanup")
    if self.proxy_ then
    	self.proxy_:release()
    end
    layer_base_t.onNodeCleanup(self)
end

function createTestData(self)
	--testData
	return nil
end