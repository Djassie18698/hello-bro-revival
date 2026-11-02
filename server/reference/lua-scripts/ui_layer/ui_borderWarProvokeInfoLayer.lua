--边界碑挑衅
--litao
--2014-2-17
---------------------------------------------
require("CommonBuyItemDialog.lua")

module("ui_borderWarProvokeInfoLayer", package.seeall)
baseClass(layer_base_t, ui_borderWarProvokeInfoLayer)

function init(self, node, data, state)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	local winSize = CCDirector:sharedDirector():getWinSize()

	--Load res
	local ccbiAttrTable = {name="activity/BorderWarProvokeInfoView.ccbi", size=CCSizeMake(768, winSize.height)}
	layer_base_t.init(self, true, ccbiAttrTable)

	--vip
	self.m_vipframes={'vip_015','vip_003','vip_004','vip_005','vip_006','vip_007','vip_008','vip_009','vip_010','vip_011','vip_012','vip_013','vip_014','vip_s_13','vip_s_14','vip_s_15','vip_s_16','vip_s_17','vip_s_18'}

	self.preNode = node
	--当前国家Id
	self.curData = data
	--排行榜玩家信息
	self.m_playerDatas = {}

	self.state = state -- 我的状态
	--tableView cell container
	self.cellNodes = {}

	self.m_touchPoint = nil

	--清理成功的奖励
	self.exp = 0
	self.merit = 0

	--时间增量
	self.deltatime = 0

	--创建测试数据信息
	--self:createTestData()

	--init && bindEvent
	---[[
	self:init_ui()
	self:init_binding_event()
	--]]
end

function init_ui(self)
	if self.proxy_ ~= nil then
		--update Btn
		self.btnUpdate = tolua.cast(self.proxy_:getNode("borderInfo_updateBtn"), "CCControlButton")
		--关闭按钮
		self.btnDialogClose = tolua.cast(self.proxy_:getNode("borderInfo_closeBtn"), "CCControlButton")
		--container
		self.node_content = tolua.cast(self.proxy_:getNode("borderInfo_contentNode"), "CCNode")
		--cellNode
		self.node_cell = tolua.cast(self.proxy_:getNode("borderInfo_cellNode"), "CCNode")

		self.label_title = tolua.cast(self.proxy_:getNode("provokeInfo_titleLabel"), "CCLabelTTF")

		local curCountryNameLabel
		if self.curData.curCountryId ~= self.playerData_.m_countrytype then		
			if self.curData.curCountryId == 0 then
				curCountryNameLabel = localizable.ui_border_country_wind
			elseif self.curData.curCountryId == 1 then
				curCountryNameLabel = localizable.ui_border_country_thunder
			elseif self.curData.curCountryId == 2 then
				curCountryNameLabel = localizable.ui_border_country_water
			elseif self.curData.curCountryId == 3 then
				curCountryNameLabel = localizable.ui_border_country_fire
			elseif self.curData.curCountryId == 4 then
				curCountryNameLabel = localizable.ui_border_country_earth
			end
		else
			curCountryNameLabel = localizable.ui_border_my_country
		end

		self.label_title:setString(tostring(curCountryNameLabel..localizable.ui_border_provoke_info1))

		--剩余次数
		self.label_clear_left = tolua.cast(self.proxy_:getNode("label_clear_left"), "CCLabelBMFont")
		self.label_next_add = tolua.cast(self.proxy_:getNode("label_next_level_add"), "CCLabelBMFont")
		self.spr_next_vip_level = tolua.cast(self.proxy_:getNode("sprite_next_viplevel"), "CCSprite")

		self.label_clear_left:setString(tostring(self.curData.clear_left.."/"..self.curData.clear_lmt))
		--next vip
		local next_viplevel = self.playerMgr_:GetVipLevel() + 2
		if next_viplevel > #self.m_vipframes then
			next_viplevel = #self.m_vipframes
			tolua.cast(self.proxy_:getNode("label_max_vip"), "CCLabelTTF"):setVisible(true)
			self.label_next_add:setVisible(false)
			tolua.cast(self.proxy_:getNode("label_add_desc"), "CCLabelTTF"):setVisible(false)
		else
			local _add_times = tonumber(self.curData.next_clear - self.curData.clear_lmt)
			if _add_times < 0 then
				_add_times = 0
			end
			self.label_next_add:setString(tostring("+".._add_times))
		end
		local frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(self.m_vipframes[next_viplevel])
		if frame ~= nil then
			self.spr_next_vip_level:setDisplayFrame(frame)
		end

		self:startRequest()
	end
end

function startRequest(self)
	--更新所有敌人时间
	local function updateAllProvokeTime(fDeltaTime)
		self.deltatime = self.deltatime + fDeltaTime
		if self.deltatime >= 1 then
			local intPart, floatPart = math.modf(self.deltatime)

			if #self.m_playerDatas < 1 then
				self.node_:unscheduleUpdate()
			else
				for i=1,#self.m_playerDatas do
					if self.m_playerDatas[i].time < self.curData.endTime then
						self.m_playerDatas[i].time = self.m_playerDatas[i].time + intPart					
					end
					self.deltatime = floatPart
				end
			end
		end
	end
	---[[
	--获取排名信息
	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 1, "rl_r_frontiers_war_enemy_info")
	urlpath = AddData(urlpath, "Country", self.curData.curCountryId)
	--cclog("BorderEnemyInfo---CGI----%s", urlpath)
	self.preNode:ShowLoadingDlgView()
	CCHttpRequest:open(urlpath, kHttpPost,"query=param1&other=params"):sendWithHandler(
		function(res, hnd)
			self.preNode:CloseLoadingDlgView()
			local resData = res:getResponseData()
			local code = res:getResponseCode()
			local xfile = xml.parse(resData)
			local item = xfile:find("RENLONG")
			local retcode = item.code
			--cclog("BorderEnemyInfo----%s", resData)
			if retcode == "0" then
				--排名列表
				local itemList = (xfile:find("enemy_list"))
				if itemList then
					self.m_playerDatas = {}
					for i = 1, #itemList do
						local tempitem = {}
						tempitem.endTime = self.curData.endTime
						tempitem.userId = tostring(itemList[i].id)
						tempitem.nick = itemList[i].nick
						tempitem.countryId = tonumber(itemList[i].country)
						tempitem.level = itemList[i].level
						tempitem.time = tonumber(itemList[i].remaining_time)
						table.insert(self.m_playerDatas, tempitem)
					end

					--排名按时间从高到低sort
					--[[
					table.sort(self.m_playerDatas, function(a, b)
						return a.time > b.time
					end)
					--]]
				end

				self.node_:scheduleUpdateWithPriorityLua(updateAllProvokeTime, 0)
				--创建列表cell
				self:createRankTableView()
			else
				--调整为错误码
				GetMainMenu():ShowErrorTip(tostring(retcode), -1)
			end
		end)
end

function init_binding_event(self)
	if self.proxy_ ~= nil then
		local function CCLayerTouch(event,x,y)
			local rect = self.preNode.node_:boundingBox()
			rect.origin = ccp(0,0)
			local p = self.preNode.node_:convertToNodeSpace(ccp(x,y))
			if event == "began" then
				if rect:containsPoint(p) == true then
					return true
				else
					return false
				end
			end
		end
		self.node_:setTouchEnabled(true)
		self.node_:registerScriptTouchHandler(CCLayerTouch, false, kCCMenuHandlerPriority - 1, true)

		local function close_window(btn, event)
			self:updateMainInfo()
			self.node_:removeFromParentAndCleanup(true)
		end

		local function onBtnUpdate(btn, event)
			CSoundMgr:instance():PlayEffect(SOUND_BUTTON)
			self:startRequest()
		end

		--绑定按钮事件
		self.btnUpdate:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.proxy_:handleButtonEvent(self.btnUpdate, onBtnUpdate, CCControlEventTouchUpInside)

		self.btnDialogClose:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.proxy_:handleControlEvent(self.btnDialogClose, close_window, CCControlEventTouchUpInside)
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
    		local nodeLayer = createObj(ui_borderWarProvokeInfoCell, self.cellsize, self.m_playerDatas[a1 + 1])
    		nodeLayer.node_:setTag(100)
    		--tableView cell container
			self.cellNodes[a1+1] = nodeLayer
			if not a2 then
				a2 = CCTableViewCell:create()
				a2:addChild(nodeLayer.node_)
			else
				a2:removeAllChildrenWithCleanup(true)
        		a2:addChild(nodeLayer.node_)
			end
			r = a2
		elseif fn == "numberOfCells" then
			r = #self.m_playerDatas
		    -- Cell events:
		elseif fn == "cellTouched" then			-- A cell was touched, a1 is cell that be touched. This is not necessary.
			---[[
			local cellIndex = a1:getIdx() + 1
			if self.cellNodes[cellIndex].clearBtn:boundingBox():containsPoint(self.m_touchPoint) then
				if self.cellNodes[cellIndex].cellData.nick == self.playerData_.m_name and self.cellNodes[cellIndex].cellData.countryId == self.playerData_.m_countrytype then
					return nil
				end
				self:onBtnClear(cellIndex)
			end
			--]]
		elseif fn == "cellTouchBegan" then		-- A cell is touching, a1 is cell, a2 is CCTouch
			self.m_touchPoint = a2:getLocation()
			self.m_touchPoint = a1:convertToNodeSpace(self.m_touchPoint)
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

function requestClear( self, countryid, userid, force)
	--显示清理战斗
	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 1, "rl_r_frontiers_war_clear")
	urlpath = AddData(urlpath, "Country", userid)
	urlpath = AddData(urlpath, "ToUid", tostring(userid))
	urlpath = AddData(urlpath, "ForceClear", force)
	--cclog("BorderEnemyInfo---clearCGI----%s", urlpath)
	self.preNode:ShowLoadingDlgView()
	CCHttpRequest:open(urlpath, kHttpPost,"query=param1&other=params"):sendWithHandler(
		function(res, hnd)
			self.preNode:CloseLoadingDlgView()
			local resData = res:getResponseData()
			local code = res:getResponseCode()
			local xfile = xml.parse(resData)
			local item = xfile:find("RENLONG")
			local retcode = item.code
			--cclog("BorderEnemyInfo--clearCGI--%s", resData)
			if retcode == "0" then
				local preView = item:find("preview")
				local result = tonumber(preView.result)	
				--刷新主界面
				self:updateMainInfo()	
				--显示战斗过程动画
				GetMainMenu():ShowArenaView(resData)	

				--根据结果处理
				if result == 1 then 						
					--奖励信息
					local awardInfo = item:find("userinfo")
					if awardInfo ~= nil then
						self.exp = tonumber(awardInfo:find("Exp")[1])
						self.merit = tonumber(awardInfo:find("Merit")[1])				
						--显示胜利奖励功勋框
						--超过4次无奖励
						local titleText = localizable.ui_border_battle_win
						local showContent
						if self.exp ~= 0 or self.merit ~= 0 then													
							--标准框
							showContent = localizable.ui_border_battle_gift
						else
						    --标准框
							showContent = localizable.ui_border_battle_gift1										
						end
						--显示奖励窗口
						local awardData = {}
						awardData.title = titleText
						awardData.descText = showContent
						awardData.exp = self.exp
						awardData.merit = self.merit
						self.preNode:showClearReward(awardData)
						--关闭当前窗口
						self.node_:removeFromParentAndCleanup(true)	
					else
						--关闭当前窗口
						self.node_:removeFromParentAndCleanup(true)	
					end	
				else
					--reOpen
					local function reloadCurLayer()
						self.preNode:reOpenClearProvoke()
					end
					--延迟1s弹出奖励框
					local ccArray = CCArray:create()
				    ccArray:addObject(CCDelayTime:create(1))
				    ccArray:addObject(CCCallFuncN:create(reloadCurLayer))
					local sequen = CCSequence:create(ccArray)   
					self.node_:runAction(sequen)
					--
					--关闭当前窗口
					self.node_:removeFromParentAndCleanup(true)	
					--刷新列表
					--self:startRequest()					
				end										
			elseif retcode == "329007" then
				--决斗值不足
				GetMainMenu():ShowErrorTip(tonumber(retcode), -1)
				--关闭当前窗口
				self.node_:removeFromParentAndCleanup(true)	
				--购买兵粮丸提示框
				ShowCommonBuyItemDialog(kConsumableTypeItem, SMALL_PK_ENERGY_ITEM_ID, BIG_PK_ENERGY_ITEM_ID, 0)
			else
				--其他错误码
				GetMainMenu():ShowErrorTip(tonumber(retcode), -1)
			end
		end)		
end

function onBtnClear(self,index)
	CSoundMgr:instance():PlayEffect(SOUND_BUTTON)

	--清理次数限制
	if self.curData.clear_left <= 0 then
		GetMainMenu():ShowTextTip(localizable.ui_border_tips12, -1)
		return nil
	end

	local function doClear ()
		self:requestClear(self.curData.curCountryId,self.m_playerDatas[index].userId, 1)
	end
	if self.state == 1 or self.state == 2 then -- 游荡或挑衅状态
		local dlg = CommonDialogView.create()
		CommonDialogView.m_selfview = dlg
		dlg:SetTitle(localizable.ui_rouletteLayer_title)
		dlg:SetDescription(localizable.ui_border_tips27)
		dlg:loadCCBI()
		dlg:initUI()
		dlg:SetConfirmHandler(doClear)
		GetMainMenu():GetModelLayer():AddDialog(dlg, 3)
	else
		self:requestClear(self.curData.curCountryId,self.m_playerDatas[index].userId,0)
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
	return nil
end