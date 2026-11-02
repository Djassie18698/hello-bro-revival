--descriptioin:边界碑
--company: xckoo
--author: litao
--date: 2014-2-13
---------------------------------------------
module("ui_borderWarLayer", package.seeall)
baseClass(layer_base_t, ui_borderWarLayer)

function init(self)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	self.contentSize_ = GetMainMenu():GetSubContentNode():getContentSize()
	local ccbiAttrTable = {name="activity/BorderWarView.ccbi", size=self.contentSize_}
	layer_base_t.init(self, true, ccbiAttrTable)

	--时间增量
	self.deltatime = 0
	--定时更新时间增量、定时
	self.deal_time = 0
	--控制多停留一秒
	self.stay_time = 0
	--玩家当前状态(0.和平 1.挑衅 2.游荡)
	self.state = 0
	--边境之战是否开启(0关闭 1开启)
	self.bOpen = 1
	--玩家当前点击的攻击状态
	self.m_curAttackType = 0
	--玩家击退敌数
	self.beat_enemyCount = 0
	--挑衅、游荡每轮时间
	self.provokeEndTime = 0
	self.wanderEndTime = 0
	--
	self.clear_lmt = 0
	self.clear_left = 0
	self.next_clear = 0
	--hp
	self.totalHp = 0
	--玩家挑衅国家id
	self.provokeCountryId = -1
	--国家icon tableView
	self.m_tableview = nil
	--当前界面显示的国家Id
	self.m_curCountryId = self.playerData_.m_countrytype

	--是否有滑动事件
	--self.isUpdate = -1

	--请求控制
	self.allRequestCount = -1

	self.m_touchBegan = nil
	self.m_touchMove = nil
	self.m_touchEnd = nil

	--又当一次花费
	self.m_gold_one_provoke = 0
	self.m_silver_one_wander = 0

	--5个国家的信息
	self.m_countryDatas = {}

	self:init_ui()
	self:init_binding_event()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		--返回、详情
		self.btn_back = tolua.cast(self.proxy_:getNode("borderWar_backBtn"), "CCControlButton")
		self.btn_detail = tolua.cast(self.proxy_:getNode("borderWar_detailBtn"), "CCControlButton")
		--挑衅、游荡
		self.btn_provoke = tolua.cast(self.proxy_:getNode("borderWar_provokeBtn"), "CCControlButton")		
		self.btn_wander = tolua.cast(self.proxy_:getNode("borderWar_wanderBtn"), "CCControlButton")
		self.btn_provoke:setVisible(false)
		self.btn_wander:setVisible(false)
		--边界奖励、边界丰碑
		self.btn_reward = tolua.cast(self.proxy_:getNode("borderWar_rewardBtn"), "CCControlButton")
		self.btn_rank = tolua.cast(self.proxy_:getNode("borderWar_rankBtn"), "CCControlButton")
		--血量详情
		self.btn_bloodDetail = tolua.cast(self.proxy_:getNode("borderWar_blood_detailBtn"), "CCControlButton")
		--清理游荡、挑衅
		self.btn_clearEnemy = tolua.cast(self.proxy_:getNode("borderWar_clearEnemy"), "CCControlButton")
		self.btn_clearProvoke = tolua.cast(self.proxy_:getNode("borderWar_clearProvoke"), "CCControlButton")

		--金钱标签
		self.label_gold = tolua.cast(self.proxy_:getNode("label_gold"), "CCLabelBMFont")
		self.label_silver = tolua.cast(self.proxy_:getNode("label_silver"), "CCLabelBMFont")
		--击败人数
		self.label_wanderKilledCount = tolua.cast(self.proxy_:getNode("borderWar_wanderCountLabel"), "CCLabelBMFont")
		self.label_provokeKilledCount = tolua.cast(self.proxy_:getNode("borderWar_provokeCountLabel"), "CCLabelBMFont")
		--状态desc
		self.label_playerStateDescLabel = tolua.cast(self.proxy_:getNode("borderWar_playerStateDescLabel"), "CCLabelTTF")
		--边境desc
		self.label_borderEnemyDesc = tolua.cast(self.proxy_:getNode("borderWar_borderEnemyDesc"), "CCLabelTTF")
		self.label_provokeCurCountryDesc = tolua.cast(self.proxy_:getNode("borderWar_provokeCurCountryDesc"), "CCLabelTTF")
		--血量
		self.label_bloodLabel = tolua.cast(self.proxy_:getNode("borderWar_bloodLabel"), "CCLabelTTF")
		self.spr_meBlood = tolua.cast(self.proxy_:getNode("borderWar_meBlood"), "CCScale9Sprite")
		self.spr_otherBlood = tolua.cast(self.proxy_:getNode("borderWar_otherBlood"), "CCScale9Sprite")
		self.spr_meFrame = tolua.cast(self.proxy_:getNode("borderWar_bloodFrame_me"), "CCSprite")
		self.spr_otherFrame = tolua.cast(self.proxy_:getNode("borderWar_bloodFrame_other"), "CCSprite")		
		self.spr_otherFrame:setVisible(false)
		self.spr_otherBlood:setVisible(false)
		--滑动
		self.spr_preA = tolua.cast(self.proxy_:getNode("borderWar_preA"), "CCControlButton")
		self.spr_preA_gray = tolua.cast(self.proxy_:getNode("borderWar_preA_gray"), "CCSprite")
		self.spr_nextA = tolua.cast(self.proxy_:getNode("borderWar_nextA"), "CCControlButton")
		self.spr_nextA_gray = tolua.cast(self.proxy_:getNode("borderWar_nextA_gray"), "CCSprite")
		self.spr_preA_gray:setVisible(false)
		self.spr_nextA_gray:setVisible(false)	
		--位置node
		self.preCountryNode = tolua.cast(self.proxy_:getNode("borderWar_preCell"), "CCNode")
		self.curCountryNode = tolua.cast(self.proxy_:getNode("borderWar_nowCell"), "CCNode")
		self.nextCountryNode = tolua.cast(self.proxy_:getNode("borderWar_nextCell"), "CCNode")
		self.curContentSize = self.curCountryNode:getContentSize()
		--敌情
		for i=1,4 do
			self["spr_wanderCountryIcon"..tostring(i)] = tolua.cast(self.proxy_:getNode("borderWar_enemyCountryIcon"..tostring(i)), "CCNode")
			self["label_wanderCountLabel"..tostring(i)] = tolua.cast(self.proxy_:getNode("borderWar_enemyCountLabel"..tostring(i)), "CCLabelBMFont")
			
			self["spr_provokeCountryIcon"..tostring(i)] = tolua.cast(self.proxy_:getNode("borderWar_provokeIcon"..tostring(i)), "CCNode")
			self["label_provokeCountLabel"..tostring(i)] = tolua.cast(self.proxy_:getNode("borderWar_provokeLabel"..tostring(i)), "CCLabelBMFont")
		end		
		--国家信息
		self:createTestData()
		--请求基本信息
		self:startRequestCountryInfo(self.playerData_.m_countrytype)
		self:startRequestPlayerInfo()	
		--显示所有country
		self:showAllCountry(self.m_curCountryId, 2)
		--启用定时更新
		--更新当前界面的信息
		local function updateAllProvokeTime(fDeltaTime)
			--请求控制
			if self.allRequestCount == -2 then				
				self.deal_time = self.deal_time + fDeltaTime
			else
				self.deal_time = 0
			end
			--12秒定时刷新
			if self.deal_time >= 12 then
				--if self.isUpdate ~= 1 then
					self:startRequestCountryInfo(self.m_curCountryId)
					self:startRequestPlayerInfo()
					local intPart, floatPart = math.modf(self.deal_time)
					self.deal_time = floatPart
				--end
			end
		end
		self.node_:scheduleUpdateWithPriorityLua(updateAllProvokeTime, 0)		
	end
end

function init_ui_ext(self)
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	--显示银两信息
	self.label_gold:setString(tostring(self.playerData_.m_gold))
	self.label_silver:setString(tostring(self.playerData_.m_silver))

	--显示国家信息
	if self.m_curCountryId ~= self.playerData_.m_countrytype then
		self.btn_provoke:setVisible(true)
		self.btn_wander:setVisible(true)
		self.btn_reward:setVisible(false)
		self.btn_rank:setVisible(false)
		self.spr_meBlood:setVisible(false)
		self.spr_otherBlood:setVisible(true)
		self.spr_meFrame:setVisible(false)
		self.spr_otherFrame:setVisible(true)
	else
		self.btn_provoke:setVisible(false)
		self.btn_wander:setVisible(false)
		self.btn_reward:setVisible(true)
		self.btn_rank:setVisible(true)	
		self.spr_meBlood:setVisible(true)
		self.spr_otherBlood:setVisible(false)
		self.spr_meFrame:setVisible(true)		
		self.spr_otherFrame:setVisible(false)	
	end
end

--显示所有country
function showAllCountry(self, curCountryId, moveType)
	--0-4风雷水火土
	if curCountryId < 0 then
		curCountryId = 0
	elseif curCountryId > 4 then
		curCountryId = 4
	end

	local preIndex = curCountryId - 1
	local nextIndex = curCountryId + 1

	--超出索引范围不显示
	if preIndex < 0 then
		preIndex = -1
	end
	if nextIndex > 4 then
		nextIndex = -1
	end

	--cclog("preIcon = %s__curIcon = %s__nextIcon = %s",preIndex,curCountryId,nextIndex)
	
	local nodeHeight = self.curContentSize.height * 0.5
	--判断位移的方向
	if self.m_curCountryId < curCountryId then
		self:moveToPos(nextIndex + 1, self.curContentSize.width * 1.5, nodeHeight,2)
	else
		self:moveToPos(preIndex + 1, -self.curContentSize.width * 0.5, nodeHeight,2)
	end

	for i=1,#self.m_countryDatas do		
		if i == preIndex + 1 then
			self:moveToPos(i,-self.curContentSize.width * 0.5,nodeHeight,moveType)
		elseif i == curCountryId + 1 then
			self:moveToPos(i,self.curContentSize.width * 0.5,nodeHeight,moveType)
		elseif i == nextIndex + 1 then
			self:moveToPos(i,self.curContentSize.width * 1.5,nodeHeight,moveType)
		else
			self.m_countryDatas[i].node:setVisible(false)
		end
	end

	--没有改变则不切换
	if curCountryId ~= self.m_curCountryId then
		--更新curId
		self.m_curCountryId = curCountryId		
		--重新请求
		self:startRequestCountryInfo(self.m_curCountryId)	
		self:startRequestPlayerInfo()	
	end	
	--update_ui
	self:init_ui_ext()

	if self.m_curCountryId == 0 then 
		self.spr_preA:setVisible(false)
		self.spr_preA_gray:setVisible(true)
	elseif self.m_curCountryId == 4 then 
		self.spr_nextA:setVisible(false)
		self.spr_nextA_gray:setVisible(true)
	else
		self.spr_preA:setVisible(true)
		self.spr_nextA:setVisible(true)

		self.spr_preA_gray:setVisible(false)
		self.spr_nextA_gray:setVisible(false)	
	end
end

function moveToPos(self, index, toPos_x, toPos_y, moveType)
	if index < 1 or index > #self.m_countryDatas then
		return nil
	end

	local moveNode = self.m_countryDatas[index].node
	--移动效果
	if moveType == 1 then
		local move = CCMoveTo:create(0.5, ccp(toPos_x,toPos_y))
		local easeTo = CCEaseSineOut:create(move)
		local array = CCArray:create()
		array:addObject(move)
		array:addObject(CCDelayTime:create(0.5))
		local sequen = CCSequence:create(array)
		moveNode:runAction(sequen)
	else
		moveNode:setPosition(ccp(toPos_x,toPos_y))
	end		 

	moveNode:setVisible(true)
end

function retCountryText(self, countryId, retType)
	--1.文字  2.iconName
	local curCountryNameLabel = ""
	if retType == 1 then
		if countryId == 0 then
				curCountryNameLabel = localizable.ui_border_country_wind
		elseif countryId == 1 then
			curCountryNameLabel = localizable.ui_border_country_thunder
		elseif countryId == 2 then
			curCountryNameLabel = localizable.ui_border_country_water
		elseif countryId == 3 then
			curCountryNameLabel = localizable.ui_border_country_fire
		elseif countryId == 4 then
			curCountryNameLabel = localizable.ui_border_country_earth
		end

		if countryId == self.playerData_.m_countrytype then
			curCountryNameLabel = localizable.ui_border_my_country
		end
	elseif retType == 2 then
		if countryId == 0 then
			curCountryNameLabel = tostring("com_icon_country_Wind")
		elseif countryId == 1 then
			curCountryNameLabel = tostring("com_icon_country_Mine")
		elseif countryId == 2 then
			curCountryNameLabel = tostring("com_icon_country_Water")
		elseif countryId == 3 then
			curCountryNameLabel = tostring("com_icon_country_Fire")
		elseif countryId == 4 then
			curCountryNameLabel = tostring("com_icon_country_Earth")
		end
	end

	return curCountryNameLabel
end

function ShowLoadingDlgView(self)
	if self.allRequestCount < 0 then
		GetMainMenu():ShowLoadingDlg()
		self.allRequestCount = 0
		--cclog("self.allRequestCount = %s is loading.", self.allRequestCount)
	end
end

function CloseLoadingDlgView(self)	
	GetMainMenu():CloseLoadding()
	self.allRequestCount = -2
	--cclog("self.allRequestCount = %s is closed.", self.allRequestCount)
end

function startRequestCountryInfo(self, countryId)
	---请求主界面基本信息
	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid,1,"rl_r_frontiers_war_info")
	urlpath = AddData(urlpath, "Country", countryId)

	local curCountryNameLabel = self:retCountryText(countryId, 1)

	self.label_borderEnemyDesc:setString(tostring(curCountryNameLabel..localizable.ui_border_wander_info))
	self.label_provokeCurCountryDesc:setString(tostring(curCountryNameLabel..localizable.ui_border_provoke_info)) 

	--self.isUpdate = 1

	cclog("borderWar111----%s", urlpath)
	self:ShowLoadingDlgView()
	CCHttpRequest:open(urlpath, kHttpPost, "query=param1&other=params"):sendWithHandler(
		function(res, hnd)
			if self.allRequestCount > 0 then
				self:CloseLoadingDlgView() 
			else
				self.allRequestCount = self.allRequestCount + 1
			end		
			local resData = res:getResponseData()
			local code = res:getResponseCode()
			local xfile = xml.parse(resData)
			local item = xfile:find("RENLONG")
			if item == nil then
				--cclog("CGI : rl_r_frontiers_war_info is down!")
				return nil
			end
			--cclog("rl_r_frontiers_war_info...报文!%s", resData)
			local retcode = item.code
			if retcode == "0" then	
				--显示边界碑血量信息			
				local monument_info = item:find("monument_info")
				if monument_info then
					--血量
					local remain_hp = monument_info:find("remaining_hp")
					local total_hp = monument_info:find("total_hp")	
					self.remainHp = tonumber(remain_hp[1])			
					self.totalHp = tonumber(total_hp[1])
					if self.remainHp < 0 then
						self.remainHp = 0
					end
					if self.totalHp < 0 then
						self.totalHp = 0
					end

					self.label_bloodLabel:setString(tostring(self.remainHp).."/"..tostring(self.totalHp))

					local hp_scale = tonumber(self.remainHp/(self.totalHp * 1.0))
					if self.m_curCountryId ~= self.playerData_.m_countrytype then
						self.spr_otherBlood:setScaleX(hp_scale)
					else
						self.spr_meBlood:setScaleX(hp_scale)
					end

					--挑衅、游荡花费
					self.m_gold_one_provoke = tonumber(monument_info:find("defiance_cash")[1])
					self.m_silver_one_wander = tonumber(monument_info:find("wander_coin")[1])
					--每次挑衅、游荡扣除血量
					self.provoke_blood = tonumber(monument_info:find("cost_defiance_hp")[1])
					self.wander_blood = tonumber(monument_info:find("cost_wander_hp")[1])
				end

				--显示边境游荡信息
				local wander_enemy = item:find("wander_enemy")
				CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile("com_res/Resident.plist")
				if wander_enemy then
					for i=1,4 do
						---[[
						--0-4 风雷水火土
						local countryIconId = tonumber(wander_enemy[i].id)
						local countryIconName = self:retCountryText(countryIconId, 2)

						local pFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(countryIconName)
						if pFrame ~= nil then
							local pIcon = CCSprite:createWithSpriteFrame(pFrame)
							local size = self["spr_wanderCountryIcon"..tostring(i)]:getContentSize()
							if pIcon ~= nil then
								self["spr_wanderCountryIcon"..tostring(i)]:addChild(pIcon)
								pIcon:setPosition(ccp(size.width/2, size.height/2))
								pIcon:setAnchorPoint(ccp(0.5, 0.5))
							end
						end

						self["label_wanderCountLabel"..tostring(i)]:setString(tostring(wander_enemy[i].num))
					end
				end

				--显示边境挑衅信息
				local provoke_enemy = item:find("defiance_enemy")
				CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile("com_res/Resident.plist")
				if provoke_enemy then
					for i=1,4 do
						---[[
						--0-4 风雷水火土
						local countryIconId = tonumber(provoke_enemy[i].id)
						local countryIconName = self:retCountryText(countryIconId, 2)

						local pFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(countryIconName)
						if pFrame ~= nil then
							local pIcon = CCSprite:createWithSpriteFrame(pFrame)
							local size = self["spr_provokeCountryIcon"..tostring(i)]:getContentSize()
							if pIcon ~= nil then
								self["spr_provokeCountryIcon"..tostring(i)]:addChild(pIcon)
								pIcon:setPosition(ccp(size.width/2, size.height/2))
								pIcon:setAnchorPoint(ccp(0.5, 0.5))
							end
						end

						self["label_provokeCountLabel"..tostring(i)]:setString(tostring(provoke_enemy[i].num))
					end
				end

				--self.isUpdate = -1
			else
				if retcode == "329005" then       ---边境战还未开始
					self.bOpen = 0
					self:setCloseCountryInfo()
					GetMainMenu():ShowErrorTip(tonumber(retcode),-1) 
				elseif retcode == "329006" then    ---边境战已经结束
					self.bOpen = 0
					self:setCloseCountryInfo()
					GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
				end
			end
		end)
end

function startRequestPlayerInfo(self)
	--刷新挑衅事件
	local function updateProvokeTimeLabel(fDeltaTime)
		self.deltatime = self.deltatime + fDeltaTime
		if self.deltatime >= 1 then
			local intPart, floatPart = math.modf(self.deltatime)
			self.provokeTime = self.provokeTime + intPart
			if self.provokeTime > 0 then
				local timeStr
				if self.state == 1 then					
					if self.provokeTime > self.provokeEndTime * 3 then
						self.provokeTime = self.provokeEndTime * 3	
						timeStr = tools.convertSecToStr(self.provokeTime, true)	
						timeStr = tostring(timeStr..localizable.ui_border_reach_uplimit)											
					else
						timeStr = tools.convertSecToStr(self.provokeTime, true)	
					end									
				elseif self.state == 2 then
				 	if self.provokeTime > self.wanderEndTime * 3 then
						self.provokeTime = self.wanderEndTime * 3
						timeStr = tools.convertSecToStr(self.provokeTime, true)
						timeStr = tostring(timeStr..localizable.ui_border_reach_uplimit)
					else
						timeStr = tools.convertSecToStr(self.provokeTime, true)	
					end
				end
				
				local countryName = self:retCountryText(self.provokeCountryId, 1)

				local descLabel
				if self.state == 1 then
					descLabel = countryName..localizable.ui_border_provoke..tostring(timeStr)
				elseif self.state ==2 then
					descLabel = countryName..localizable.ui_border_wander..tostring(timeStr)
				else
					self.label_playerStateDescLabel:unscheduleUpdate()
					descLabel = localizable.ui_border_tips6
				end
				self.label_playerStateDescLabel:setString(descLabel)
				self.deltatime = floatPart
			else
				--self:init_ui_ext()
				self.label_playerStateDescLabel:unscheduleUpdate()
			end
		end
	end

	--self.isUpdate = 1
	--请求人物基本信息
	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid,1,"rl_r_frontiers_war_user_info")
	urlpath = AddData(urlpath, "Country", self.playerData_.m_countrytype)
	urlpath = AddData(urlpath, "KillCountry", self.m_curCountryId)
	--cclog("rl_r_frontiers_war_user_info----%s", urlpath)
	self:ShowLoadingDlgView()
	CCHttpRequest:open(urlpath, kHttpPost, "query=param1&other=params"):sendWithHandler(
		function(res, hnd)	
			--close loading
			if self.allRequestCount > 0 then
				self:CloseLoadingDlgView() 
			else
				self.allRequestCount = self.allRequestCount + 1
			end	
			local resData = res:getResponseData()
			local code = res:getResponseCode()
			local xfile = xml.parse(resData)
			local item = xfile:find("RENLONG")
			if item == nil then
				--cclog("CGI : rl_r_frontiers_war_user_info is down!")
				return nil
			end
			--cclog("rl_r_frontiers_war_user_info...报文!%s", resData)
			local retcode = item.code
			if retcode == "0" then
				--如果未开启
				if self.bOpen == 0 then
					self.label_provokeKilledCount:setString(tostring(0))
					self.label_wanderKilledCount:setString(tostring(0))
					self.label_playerStateDescLabel:setString(localizable.ui_border_not_start)
					return nil
				end	
				--显示打败敌人数量				
				local user_info = item:find("user_info")
				if user_info then
					self.provokeEndTime = tonumber(user_info:find("defiance_end_time")[1])
					self.wanderEndTime = tonumber(user_info:find("wander_end_time")[1])
					self.provoke_exp = tonumber(user_info:find("defiance_exp")[1])
					self.provoke_merit = tonumber(user_info:find("defiance_exploit")[1])
					self.wander_exp = tonumber(user_info:find("wander_ex")[1])
					self.wander_merit = tonumber(user_info:find("wander_exploit")[1])
					--清理次数限制
					self.clear_lmt = tonumber(user_info:find("cleartimes_lmt")[1])
					self.clear_left = tonumber(user_info:find("cleartimes_left")[1])
					self.next_clear = tonumber(user_info:find("nextlv_cleartimes_lmt")[1])
				end

				--杀敌数
				local kill_info = item:find("kill_enemy")
				if kill_info then
					self.label_provokeKilledCount:setString(tostring(kill_info:find("kill_defiance")[1]))
					self.label_wanderKilledCount:setString(tostring(kill_info:find("kill_wander")[1]))
				end

				--显示攻击状态
				local user_status = item:find("user_status")
				if user_status then
					self.state = tonumber(user_status:find("status")[1])
					self.provokeCountryId = tonumber(user_status:find("to_country")[1])
					self.provokeTime = tonumber(user_status:find("remaining_time")[1])

					--不能攻击自己国家,屏蔽服务器发来的错误信息
					if self.provokeCountryId == self.playerData_.m_countrytype then
						self.state = 0
					end

					--实时更新挑衅时间
					if self.state == 1 then 
						if self.provokeTime >= 0 then						
							local timeStr = tools.convertSecToStr(self.provokeTime, true)
							local countryName = self:retCountryText(self.provokeCountryId, 1)
							local descLabel = countryName..localizable.ui_border_provoke..tostring(timeStr)

							self.label_playerStateDescLabel:scheduleUpdateWithPriorityLua(updateProvokeTimeLabel, 0)
							self.label_playerStateDescLabel:setString(tostring(descLabel))
						end
					elseif self.state == 2 then
						if self.provokeTime >= 0 then						
							local timeStr = tools.convertSecToStr(self.provokeTime, true)
							local countryName = self:retCountryText(self.provokeCountryId, 1)
							local descLabel = countryName..localizable.ui_border_wander..tostring(timeStr)

							self.label_playerStateDescLabel:scheduleUpdateWithPriorityLua(updateProvokeTimeLabel, 0)
							self.label_playerStateDescLabel:setString(tostring(descLabel))
						end
					else
						self.label_playerStateDescLabel:setString(localizable.ui_border_tips6)
					end
				end

				if self.state == 0 then
					--显示被清理状态
					local clear_info = item:find("clear_info")
					if clear_info then
						local last_attack_country = tonumber(clear_info:find("last_attack_country")[1])
						if last_attack_country >= 0 and last_attack_country < 5 then
							local last_attack_country_text = self:retCountryText(last_attack_country, 1)
							local last_enemy_country = tonumber(clear_info:find("last_clear_enemy_country")[1])
							local last_toCountry_text = self:retCountryText(last_enemy_country, 1)
							local last_beCleared_name = tostring(clear_info:find("last_clear_enemy_uid")[1])

							--self.label_playerStateDescLabel:setString(tostring("在"..last_attack_country_text.."被"..last_toCountry_text..last_beCleared_name.."击败!"))
							self.label_playerStateDescLabel:setString(string.format(localizable.ui_border_tips7, last_attack_country_text, last_toCountry_text..last_beCleared_name))
						end
					end
				end

				--self.isUpdate = -1
			else
				--无法获取信息
				self:setCloseUserInfo()
			end
		end)
	
end

function setCloseCountryInfo(self)
	self.label_bloodLabel:setString(tostring("0/0"))

	local nCount = 0
	for i=1, 5 do
		if i ~= tonumber(self.playerData_.m_countrytype + 1) then
			nCount = nCount + 1
			--0-4 风雷水火土
			local countryIconId = tonumber(nCount)
			local countryIconName = self:retCountryText(countryIconId, 2)

			local pFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(countryIconName)
			if pFrame ~= nil then
				local pIcon = CCSprite:createWithSpriteFrame(pFrame)
				local pIcon_1 = CCSprite:createWithSpriteFrame(pFrame)
				local size = self["spr_wanderCountryIcon"..tostring(nCount)]:getContentSize()
				local size_1 = self["spr_provokeCountryIcon"..tostring(nCount)]:getContentSize()
				if pIcon ~= nil or pIcon_1 ~= nil then
					self["spr_wanderCountryIcon"..tostring(nCount)]:addChild(pIcon)					
					pIcon:setPosition(ccp(size.width/2, size.height/2))
					pIcon:setAnchorPoint(ccp(0.5, 0.5))

					self["spr_provokeCountryIcon"..tostring(nCount)]:addChild(pIcon_1)
					pIcon_1:setPosition(ccp(size_1.width/2, size_1.height/2))
					pIcon_1:setAnchorPoint(ccp(0.5, 0.5))
				end
			end

			self["label_wanderCountLabel"..tostring(nCount)]:setString(tostring(0))
			self["label_provokeCountLabel"..tostring(nCount)]:setString(tostring(0))
		end
	end						
end

function setCloseUserInfo(self)
	self.label_provokeKilledCount:setString(tostring(0))
	self.label_wanderKilledCount:setString(tostring(0))
	self.label_playerStateDescLabel:setString(localizable.ui_border_cannot_enter_tip)
end

function update_gold(self, attackType)
	--扣除元宝并更新
	if attackType == 1 then 
		if self.playerData_.m_gold > self.m_gold_one_provoke then
			self.playerMgr_:AddGold(-self.m_gold_one_provoke)
			self.playerData_ = self.playerMgr_:GetPlayerInfoData()
			self.label_gold:setString(tostring(self.playerData_.m_gold))
			self.label_silver:setString(tostring(self.playerData_.m_silver))
		end
	else
		if self.playerData_.m_silver > self.m_silver_one_wander then
			self.playerMgr_:AddSilver(-self.m_silver_one_wander)
			self.playerData_ = self.playerMgr_:GetPlayerInfoData()
			self.label_gold:setString(tostring(self.playerData_.m_gold))
			self.label_silver:setString(tostring(self.playerData_.m_silver))
		end
	end
end

function init_binding_event(self)
	if self.proxy_ ~= nil then
		local function onBtnWander(btn)
			if self.bOpen == 0 then
				--边界碑未开启
				GetMainMenu():ShowErrorTip(tonumber(329005), -1)
				return nil
			end
			self.m_curAttackType = 2
			--self:startRequestAttack(2)
			local curData = {}
			curData.attackType = 2
			curData.gold = self.m_silver_one_wander
			curData.endTime = self.wanderEndTime
			curData.exp = self.wander_exp
			curData.merit = self.wander_merit
			curData.blood = self.wander_blood
			curData.round = 2
			curData.toCountryId = self.m_curCountryId

			local attackLayer = createObj(ui_borderWarAttackLayer, self, curData)
			local size1 = self.node_:getContentSize()
			attackLayer.node_:setAnchorPoint(ccp(0.5, 0.5))

			attackLayer.node_:setPosition(ccp(size1.width / 2, size1.height / 2))
			self.node_:addChild(attackLayer.node_)
		end

		local function onBtnProvoke(btn)
			if self.bOpen == 0 then
				--边界碑未开启
				GetMainMenu():ShowErrorTip(tonumber(329005), -1)
				return nil
			end
			self.m_curAttackType = 1
			--self:startRequestAttack(1)
			local curData = {}
			curData.attackType = 1
			curData.gold = self.m_gold_one_provoke
			curData.endTime = self.provokeEndTime
			curData.exp = self.provoke_exp
			curData.merit = self.provoke_merit
			curData.blood = self.provoke_blood
			curData.round = 2
			curData.toCountryId = self.m_curCountryId

			local attackLayer = createObj(ui_borderWarAttackLayer, self, curData)
			local size1 = self.node_:getContentSize()
			attackLayer.node_:setAnchorPoint(ccp(0.5, 0.5))

			attackLayer.node_:setPosition(ccp(size1.width / 2, size1.height / 2))
			self.node_:addChild(attackLayer.node_)
		end

		local function onBtnReward(btn)
			---[[
			local rewardLayer = createObj(ui_borderWarRewardLayer, self, self.m_currentScore)
			local size1 = self.node_:getContentSize()
			rewardLayer.node_:setAnchorPoint(ccp(0.5, 0.5))

			rewardLayer.node_:setPosition(ccp(size1.width / 2, size1.height / 2))
			self.node_:addChild(rewardLayer.node_)
			--]]
		end

		local function onBtnRank(btn)
			---[[
			local rankLayer = createObj(ui_borderWarRankLayer, self, self.m_currentScore)
			local size1 = self.node_:getContentSize()
			rankLayer.node_:setAnchorPoint(ccp(0.5, 0.5))

			rankLayer.node_:setPosition(ccp(size1.width / 2, size1.height / 2))
			self.node_:addChild(rankLayer.node_)
			--]]
		end

		local function onBtnClearWanderEnemy(btn)
			---[[
			local data = {}
			data.curCountryId = self.m_curCountryId
			data.endTime = self.wanderEndTime
			data.clear_lmt = tonumber(self.clear_lmt)
			data.clear_left = tonumber(self.clear_left)
			data.next_clear = tonumber(self.next_clear)
			local clearEnemyLayer = createObj(ui_borderWarWanderInfoLayer, self, data, self.state)
			local size1 = self.node_:getContentSize()
			clearEnemyLayer.node_:setAnchorPoint(ccp(0.5, 0.5))

			clearEnemyLayer.node_:setPosition(ccp(size1.width / 2, size1.height / 2))
			self.node_:addChild(clearEnemyLayer.node_)
			--]]
		end

		local function onBtnClearProvoke(btn)
			---[[
			local data = {}
			data.curCountryId = self.m_curCountryId
			data.endTime = self.provokeEndTime
			data.clear_lmt = tonumber(self.clear_lmt)
			data.clear_left = tonumber(self.clear_left)
			data.next_clear = tonumber(self.next_clear)
			local clearProvokeLayer = createObj(ui_borderWarProvokeInfoLayer, self, data, self.state)
			local size1 = self.node_:getContentSize()
			clearProvokeLayer.node_:setAnchorPoint(ccp(0.5, 0.5))

			clearProvokeLayer.node_:setPosition(ccp(size1.width / 2, size1.height / 2))
			self.node_:addChild(clearProvokeLayer.node_)
			--]]
		end

		local function onBtnStateReward(btn)
			---[[
			local curData = {}
			if self.m_curAttackType == 1 then
				curData.onceTime = self.provokeEndTime
			else
				curData.onceTime = self.wanderEndTime
			end

			local stateRewardLayer = createObj(ui_borderWarStateRewardLayer, self, curData)
			local size1 = self.node_:getContentSize()
			stateRewardLayer.node_:setAnchorPoint(ccp(0.5, 0.5))

			stateRewardLayer.node_:setPosition(ccp(size1.width / 2, size1.height / 2))
			self.node_:addChild(stateRewardLayer.node_)
			--]]
		end

		local function onBtnPreA(btn)
			self:showAllCountry(self.m_curCountryId - 1,1)
		end

		local function onBtnNextA(btn)
			self:showAllCountry(self.m_curCountryId + 1,1)
		end

		local function onBtnDetail(btn)
			---[[
			local tempData = {}
			--tempData.desc_1 = tostring("每个国家都有自己的边界碑,拥有血量"..self.totalHp..",每天8点到24点,可被敌国玩家攻击.\n")
			tempData.desc_1 = string.format(localizable.ui_border_tips8, tostring(self.totalHp))
			--tempData.desc_2 = tostring("边界碑开启后,玩家可在其他国家边界挑衅和游荡,挑衅花费"..self.m_gold_one_provoke.."元宝,游荡花费"..self.m_silver_one_wander.."银两.\n挑衅、游荡成功均会减少对方边界碑血量,并获得适量经验和武勋奖励.")
			tempData.desc_2 = string.format(localizable.ui_border_tips9, tostring(self.m_gold_one_provoke), tostring(self.m_silver_one_wander))
			--tools.convertSecToStr(self.provokeEndTime, true).."会获得大量的经验以及武勋,并且扣除敌国边界碑血量"..tostring(self.provoke_blood).."点，每天最多领取2次奖励.\n")
			tempData.desc_3 = localizable.ui_border_tips10
			tempData.desc_4 = localizable.ui_border_tips11

			local detailLayer = createObj(ui_borderWarShowDetail, tempData)
			local size1 = GetMainMenu():GetModelLayer():getContentSize()
			detailLayer.node_:setAnchorPoint(ccp(0.5, 0.5))
			detailLayer.node_:setPosition(ccp(size1.width / 2, size1.height * 0.5))
			GetMainMenu():GetModelLayer():addChild(detailLayer.node_)
			--]]
		end

		function onBtnBloodDetail(btn)
			---[[
			local data = {}
			data.curCountryId = self.m_curCountryId
			data.provokeEndTime = self.provokeEndTime
			data.wanderEndTime = self.wanderEndTime
			data.provoke_blood = self.provoke_blood
			data.wander_blood = self.wander_blood
			local blood_detail_layer = createObj(ui_borderWarBloodDetailLayer, self, data)
			local size1 = GetMainMenu():GetModelLayer():getContentSize()
			blood_detail_layer.node_:setAnchorPoint(ccp(0.5, 0.5))

			blood_detail_layer.node_:setPosition(ccp(size1.width * 0.5, size1.height * 0.5))
			GetMainMenu():GetModelLayer():addChild(blood_detail_layer.node_)
			--]]
		end

		local function onBtnBack(btn)
			GetMainMenu():ChangeToSub(E_DEFAULTMENU)
			--self.node_:removeFromParentAndCleanup(true)
		end

		--重写相应的触摸函数
		local function onTouchBegan(x, y)
		    self.m_touchBegan = CCPointMake(x,y)
		    self.m_touchMove = CCPointMake(x,y)
		end

		local function onTouchMoved(x, y)
			--横向位移
			local sub_x = x - self.m_touchMove.x
			self.m_touchMove = ccp(x,y)

			local preIndex = self.m_curCountryId - 1
			local nextIndex = self.m_curCountryId + 1

			--超出索引范围不显示
			if preIndex < 0 then
				preIndex = -1
			end
			if nextIndex > 4 then
				nextIndex = -1
			end

			local nodeHeight = self.curContentSize.height * 0.5

			for i=1,#self.m_countryDatas do		
				if i == preIndex + 1 or i == self.m_curCountryId + 1 or i == nextIndex + 1 then		
					--执行动作	
					local tempPos_x, tempPos_y = self.m_countryDatas[i].node:getPosition()	
					self.m_countryDatas[i].node:setPosition(ccp(tempPos_x + sub_x, tempPos_y))	
				end
			end
		end

		local function onTouchEnded(x, y)
			if self.m_touchBegan == nil then
				return nil
			end
			self.m_touchEnd = ccp(x,y)

			if self.m_touchEnd.x > self.m_touchBegan.x + 20 then
				self:showAllCountry(self.m_curCountryId - 1,1)
			elseif self.m_touchEnd.x + 20 < self.m_touchBegan.x then
				self:showAllCountry(self.m_curCountryId + 1,1)
			else
				self:showAllCountry(self.m_curCountryId,1)
			end

			self.m_touchBegan = nil
			self.m_touchEnd = nil
		end

		--屏蔽掉后层触摸事件
		local function CCLayerTouch(event, x, y)
			local rect = self.node_:boundingBox()
			rect.origin = ccp(0,0)
			local p = self.node_:convertToNodeSpace(ccp(x,y))			
			--截获界面内后层的信息
			if rect:containsPoint(p) ==  true then
				--设定滑动区域
				local rectCurCountryNode = self.curCountryNode:boundingBox()
				rectCurCountryNode.origin = ccp(0,0)
				local cur_p = self.curCountryNode:convertToNodeSpace(ccp(x,y))
				if event == "began" then
					--判断滑动区域					
					if rectCurCountryNode:containsPoint(cur_p) == true then				
						onTouchBegan(x,y)
					end
				 	return true
				elseif event == "moved" then
					if rectCurCountryNode:containsPoint(cur_p) == true then				
						return onTouchMoved(x,y)
					end
				else
					--if rectCurCountryNode:containsPoint(cur_p) == true then				
						return onTouchEnded(x,y)
					--end
				end
			else
				return false
			end		
		end

		self.node_:setTouchEnabled(true)
		self.node_:registerScriptTouchHandler(CCLayerTouch, false, kCCMenuHandlerPriority - 1, true)

		--游荡
		self.btn_wander:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.btn_wander:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btn_wander, function(button, event)
			onBtnWander(button)
			return nil
		end, CCControlEventTouchDown)

		--挑衅
		self.btn_provoke:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.btn_provoke:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btn_provoke, function(button, event)
			onBtnProvoke(button)
			return nil
		end, CCControlEventTouchDown)

		--边界丰碑
		self.btn_rank:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.btn_rank:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btn_rank, function(button, event)
			onBtnRank(button)
			return nil
		end, CCControlEventTouchDown)

		--边界奖励
		self.btn_reward:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.btn_reward:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btn_reward, function(button, event)
			onBtnStateReward(button)
			return nil
		end, CCControlEventTouchDown)

		--清理敌人
		self.btn_clearEnemy:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.btn_clearEnemy:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btn_clearEnemy, function(button, event)
			onBtnClearWanderEnemy(button)
			return nil
		end, CCControlEventTouchDown)

		--清理挑衅
		self.btn_clearProvoke:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.btn_clearProvoke:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btn_clearProvoke, function(button, event)
			onBtnClearProvoke(button)
			return nil
		end, CCControlEventTouchDown)


		--主界面箭头pre
		self.spr_preA:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.spr_preA:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.spr_preA, function(button, event)
			onBtnPreA(button)
			return nil
		end, CCControlEventTouchDown)

		--主界面箭头next
		self.spr_nextA:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.spr_nextA:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.spr_nextA, function(button, event)
			onBtnNextA(button)
			return nil
		end, CCControlEventTouchDown)

		--详情
		self.btn_detail:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.btn_detail:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btn_detail, function(button, event)
			onBtnDetail(button)
			return nil
		end, CCControlEventTouchDown)

		--血量详情
		self.btn_bloodDetail:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.btn_bloodDetail:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btn_bloodDetail, function(button, event)
			onBtnBloodDetail(button)
			return nil
		end, CCControlEventTouchDown)

		--返回按钮
		self.btn_back:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.btn_back:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btn_back, function(button, event)
			onBtnBack(button)
			return nil
		end, CCControlEventTouchDown)
	end
end

function showClearReward(self, data)	
	local layer = createObj(ui_borderWarCommonRewardDlg, self, data)

	local size1 = self.node_:getContentSize()
	layer.node_:setAnchorPoint(ccp(0.5, 0.5))

	layer.node_:setPosition(ccp(size1.width * 0.5, size1.height * 0.5))
	self.node_:addChild(layer.node_)
end

function reOpenClearWander(self)
    ---[[
	local data = {}
	data.curCountryId = self.m_curCountryId
	data.endTime = self.wanderEndTime
	data.clear_lmt = tonumber(self.clear_lmt)
	data.clear_left = tonumber(self.clear_left)
	data.next_clear = tonumber(self.next_clear)
	local clearEnemyLayer = createObj(ui_borderWarWanderInfoLayer, self, data, self.state)
	local size1 = self.node_:getContentSize()
	clearEnemyLayer.node_:setAnchorPoint(ccp(0.5, 0.5))

	clearEnemyLayer.node_:setPosition(ccp(size1.width / 2, size1.height / 2))
	self.node_:addChild(clearEnemyLayer.node_)
	--]]
end

function reOpenClearProvoke(self)
	---[[
	local data = {}
	data.curCountryId = self.m_curCountryId
	data.endTime = self.provokeEndTime
	data.clear_lmt = tonumber(self.clear_lmt)
	data.clear_left = tonumber(self.clear_left)
	data.next_clear = tonumber(self.next_clear)
	local clearProvokeLayer = createObj(ui_borderWarProvokeInfoLayer, self, data,self.state)
	local size1 = self.node_:getContentSize()
	clearProvokeLayer.node_:setAnchorPoint(ccp(0.5, 0.5))

	clearProvokeLayer.node_:setPosition(ccp(size1.width / 2, size1.height / 2))
	self.node_:addChild(clearProvokeLayer.node_)
	--]]
end

function onNodeCleanup(self)
	if self.proxy_ then
    	self.proxy_:release()
    end
    --[[
	local plistNameList = {"ccbResources/borderWar.plist"}
    for k, v in ipairs(plistNameList) do
		CCSpriteFrameCache:sharedSpriteFrameCache():removeSpriteFramesFromFile(v)
		local imagePath = string.format( "%s.pvr.ccz", string.sub(v, 1, string.len(v) - 6) )
		CCTextureCache:sharedTextureCache():removeTextureForKey( imagePath )
		imagePath = string.format( "%s.pvr", string.sub(v, 1, string.len(v) - 6) )
		CCTextureCache:sharedTextureCache():removeTextureForKey( imagePath )
		imagePath = string.format( "%s.png", string.sub(v, 1, string.len(v) - 6) )
		CCTextureCache:sharedTextureCache():removeTextureForKey( imagePath )
	end
	--]]

    layer_base_t.onNodeCleanup(self)
end

--创建测试数据
function createTestData(self)
	--0-4 风雷水火土
	local cellContentSize = self.curCountryNode:getContentSize()
	self.m_cellsize = CCSize(cellContentSize.width,cellContentSize.height)

	for i=1,5 do		
		local indexData = {}
		indexData.countryId = i-1

		local nodeLayer = createObj(ui_borderWarCell, self.m_cellsize, indexData)
		self.curCountryNode:addChild(nodeLayer.node_)
		nodeLayer.node_:setAnchorPoint(ccp(0.5,0.5))
		indexData.node = nodeLayer.node_
		self.m_countryDatas[i] = indexData	
	end	
end