allActivityData = {}
allActivityNum = 0
newsCount = 0
defaultNews = 0
actNewsCount = 0
--reincarnationDisplay = 0

payhisNewsCount = 0
boxOpenNewsCount = 0
worldBossNewsCount = 0
--collectExchgNewsCount = 0
goddessFlowersNewsCount = 0
timePurchaseNewsCount = 0
limitGroupNewsCount = 0

fightBossMsgImportantId = 0
fightBossMsgNormalId = 0
fightBossPeriodId = 0

goddessFlowerStatus = 0
timePurchaseStatus = 0
limitGroupStatus = 0

waraward = false

g_evaluate_app_activity_status = 0       --用來控制

cclog = function(...)
    --print(string.format(...))
    CCLuaLog(string.format(...))
end

require "util/localizable"
require "util/common"
require "util/protocol"
require "global/cfg"
require "global"

require "RLRequest"
require "LuaXml"
require "loginActivityData"
require "upgradeActivityData"
require "monthCardData"
require "payhistorydropData"
require "keeplogin_info"

require "util/tools"
require "util/text"
require "ui_common/node_base_t"
require "ui_common/layer_base_t"
require "config/activity_config"
require "CommonDialogView"

require "ui_layer/ui_activityPopupTableCell"
require "ui_layer/ui_activityPopupLayer"
require "ui_layer/ui_mainActivityBtn"

require "ui_layer/ui_rouletteLayer"
require "ui_layer/ui_rouletteBingo"
require "ui_layer/ui_rouletteRankLayer"
require "ui_layer/ui_rouletteRankTableCell"

require "ui_layer/ui_monopolyLayer"
require "ui_layer/ui_monopolyRankLayer"
require "ui_layer/ui_monopolyRankCell"
require "ui_layer/ui_monopolyDiceAnim"
require "ui_layer/ui_monopolyLightAnim"

require "ui_layer/ui_borderWarLayer"
require "ui_layer/ui_borderWarCell"
require "ui_layer/ui_borderWarRankLayer"
require "ui_layer/ui_borderWarRankCell"
require "ui_layer/ui_borderWarProvokeInfoLayer"
require "ui_layer/ui_borderWarProvokeInfoCell"
require "ui_layer/ui_borderWarWanderInfoLayer"
require "ui_layer/ui_borderWarWanderInfoCell"
require "ui_layer/ui_borderWarRewardLayer"
require "ui_layer/ui_borderWarStateRewardLayer"
require "ui_layer/ui_borderWarStateRewardCell"
require "ui_layer/ui_borderWarShowTip"
require "ui_layer/ui_borderWarShowAttackTip"
require "ui_layer/ui_borderWarFireAnim"
require "ui_layer/ui_borderWarShowDetail"
require "ui_layer/ui_borderWarAttackLayer"
require "ui_layer/ui_borderWarCommonRewardDlg"
require "ui_layer/ui_borderWarChangeAttackDlg"
require "ui_layer/ui_borderWarBloodDetailLayer"
require "ui_layer/ui_borderWarBloodDetailCell"

require "ui_layer/ui_colorSuitView"
require "ui_layer/ui_levelSuitView"
require "ui_layer/ui_suitCell"
require "ui_layer/ui_vipRightInfoView"
require "ui_layer/ui_vipRightInfoCell"
require "ui_layer/ui_giftDetailView"
require "ui_layer/ui_giftDetailCell"
require "ui_layer/ui_growthfundLayer"

require "ui_layer/ui_sevenDayView"
require "ui_layer/ui_sevenDayCell"
require "ui_layer/ui_sevenDaySprCell"

require "ui_layer/ui_commonPrePay"
require "ui_layer/ui_prePayAnim"
--用于配置活动相关图标以及lua脚本名称的配置表。
--type：用户配置类型，如果为0，表示没有这个字段服务器返回没有设置，或者没有用处
--name：脚本名字
--icon：活动图标名字

mainMenuActivityConfigData = mainMenuActivityConfigData or {}

--用于标示主界面是否已经加载活动图标（大转盘等），因为服务器返回数据是异步的
isloadMainMenuActivity = false

local activityDataConfig = {}
-- 以下是所有活动数据 --------------------------------------------------
-- 各天登录数据数组
-- [0, 1 ..] 表示第一天登录礼包不能领取，第二天可以领取
-- 0表示可以领取，1表示不能领取，2表示已领取
loginData = {}

-- 升级数据数组
-- [0, 1 ..] 表示第一天登录礼包不能领取，第二天可以领取
-- 0表示可以领取，1表示不能领取，2表示已领取
upgradeData = {}

-- 月卡数据
-- [0, 1 ..] 第一项可以购买，第二项已购买
-- 0表示可以领取，1表示可以购买，2表示不可以购买不可以领取
monthData = {}

-- 累计充值礼包数据
-- 0表示可以领取，250010表示已经领取，250011表示没有资格领取
payhisData = {}
-- ----------------------------------------------------------------------
-- 以下是所有活动数据 --------------------------------------------------
-- 各天登录数据数组
-- [0, 1 ..] 表示第一天登录礼包不能领取，第二天可以领取
-- 0表示可以领取，1表示未完成连续登陆不能领取，2表示已领取 或者 过期后不能领取的
keeploginData = {}

userData = {}
activityPeriod = {roulette={},monopoly={},mora={},limitSuper={},limitGroup={},goddessFlower={},timePurchase={}}
--rouletteDisplay = 0
--monopolyDisplay = 0
--moraDisplay = 0
--limitSuperDisplay = 0

local loginDays = 1
local keepLoginNewsCount = 0
local loginNewsCount = 0
local upgradeNewsCount = 0
local monthcardNewsCount = 0

keepLoginDays = 1
showStageGiftBtn = true
stageGiftId = 31

-- 各种活动的初始化 -----------------------------------------------------
-- 初始化登录活动数据
function initLoginActivityData()
	local num = #allActivityData
	for i = 1, num do
		if allActivityData[i].type == "1" then
			activityData = allActivityData[i]
			break
		end
	end

	if activityData ~= nil then
		num = #activityData
		for i = 1, num do
			if activityData[i].actid == "1" then
				itemData = activityData[i]
				break
			end
		end
	end

	loginDays = (activityData.loginallnum+0)
	CPlayerDataMgr:instance():SetTotalLoginDay(loginDays)

	for i = 1, #loginPackData do
		if itemData ~= nil  then
			local num = #itemData

			if num > 0 then
				local dataFound = 0
				for j = 1, num do
					if itemData[j].subid == tostring(i) then
						loginData[i] = 0
						newsCount = newsCount + 1
						loginNewsCount = loginNewsCount + 1
						dataFound = 1
						break
					end
				end

				if dataFound == 0 then
					if loginDays >= loginPackData[i].login_day then
						loginData[i] = 2
					else
						loginData[i] = 1
					end
				end
			else
				if loginDays >= loginPackData[i].login_day then
						loginData[i] = 2
				else
						loginData[i] = 1
				end
			end
		else
			if loginDays >= loginPackData[i].login_day then
					loginData[i] = 2
			else
				loginData[i] = 1
			end
		end
	end
	return nil
end

-- 初始化连续登录数据
function initKeepLoginActivityData()
	--按照数据格式找到desc为conlogin的节点
	---[[
	local nAllCount = #allActivityData
	for i=1, nAllCount do
		if allActivityData[i]["desc"] == "conlogin" then
			allKeepLoginData = allActivityData[i]
			break
		end
	end
	--]]

	--空数据处理
	if allKeepLoginData == nil then
		return nil
	end

	--整理数据 0可领取 1不可领取 2已领取
	local day = 1
	day = tonumber(allKeepLoginData.condays)
	local got = 1
	got = tonumber(allKeepLoginData.got)

	for k, v in pairs(keeplogin_data) do
		if day >= #keeplogin_data then
			keeploginData[v.keeplogin_days] = 1
			if got == 0 then
				keeploginData[#keeplogin_data] = 0
				newsCount = newsCount + 1
				keepLoginNewsCount = keepLoginNewsCount + 1
			else
				keeploginData[#keeplogin_data] = 2
			end
		elseif	day == v.keeplogin_days then
			if got == 0 then
				keeploginData[v.keeplogin_days] = 0
				newsCount = newsCount + 1
				keepLoginNewsCount = keepLoginNewsCount + 1
			else
				keeploginData[v.keeplogin_days] = 2
			end
		else
			keeploginData[v.keeplogin_days] = 1
		end
	end

	return nil
end

--设置最强战力和最强排名的活动
function initRankPowerActivity()
	local confData = allActivityData:find("conf")
	if confData then
		local openType = confData:find("opentype")
		if openType then
			if openType[1] == "1" then
				local count1 = #activityDataConfig
				activityDataConfig[count1 + 1] =  {type=0, name="business_proxy/firstMoneyAward", icon="activity9"}
			end
			if openType[1] == "1" or openType[1] == "2" then
				local count2 = #activityDataConfig
				activityDataConfig[count2 + 1] =  {type=0, name="business_proxy/levelRank_business", icon="activity10"}
				activityDataConfig[count2 + 2] =  {type=0, name="business_proxy/fightRank_business", icon="activity11"}
			end
		end
	end
end

function initMoraActivity()
	local confData = allActivityData:find("conf")
	if confData then
		local openType = confData:find("gambletype")
		if openType then
			if openType[1] == "1" then
				CPlayerDataMgr:instance():SetMoraOpen(1)
			elseif openType[1] == "2" then
				CPlayerDataMgr:instance():SetMoraOpen(2)
			else
				CPlayerDataMgr:instance():SetMoraOpen(0)
			end
		end
	end
end

function initFightBossActivity()
	local confData = allActivityData:find("conf")
	if confData then
		local openType = confData:find("xiaoopen")
		if openType then
			if openType[1] == "1" then
				local count1 = #activityDataConfig
				activityDataConfig[count1 + 1] =  {type=0, name="fightBossView", icon="activity13"}
			end
		end
	end
end

-- 初始化升级活动数据
function initUpgradeActivityData()
	playerLevel = CPlayerDataMgr:instance():GetPlayerInfoData().m_level

	local num = #allActivityData
	for i = 1, num do
		if allActivityData[i].type == "2" then
			activityData = allActivityData[i]
			break
		end
	end

	if activityData ~= nil then
		num = #activityData
		for i = 1, num do
			if activityData[i].actid == "2" then
				itemData = activityData[i]
				break
			end
		end
	end

	for i = 1, #upgradePackData do
		if itemData ~= nil  then
			local num = #itemData

			local dataFound = 0
			if num > 0 then
				for j = 1, num do
					if itemData[j].subid == tostring(i) then
						upgradeData[i] = 0
						newsCount = newsCount + 1
						upgradeNewsCount = upgradeNewsCount + 1
						dataFound = 1
						break
					end
				end

				if dataFound == 0 then
					if playerLevel >= upgradePackData[i].act_player_level then
						upgradeData[i] = 2
					else
						upgradeData[i] = 1
					end
				end
			else
				if playerLevel >= upgradePackData[i].act_player_level then
					upgradeData[i] = 2
				else
					upgradeData[i] = 1
				end
			end
		else
			if playerLevel >= upgradePackData[i].act_player_level then
				upgradeData[i] = 2
			else
				upgradeData[i] = 1
			end
		end
	end
	return nil
end

-- 初始化财神数据
function initLotteryData()
	local num = #allActivityData
	for i = 1, num do
		if allActivityData[i].type == "3" then
			activityData = allActivityData[i]
			break
		end
	end

	if activityData ~= nil then
		num = #activityData
		for i = 1, num do
			if activityData[i].actid == "3" then
				itemData = activityData[i]
				break
			end
		end
	end

	local progress
	if itemData.pos == nil then
		progress = -1
	else
		progress = itemData.pos
	end
	CPlayerDataMgr:instance():SetLotteryProgress(progress)
end

-- 初始化月卡活动数据
function initMonthCardData()
	local num = #allActivityData
	for i = 1, num do
		if allActivityData[i].type == "4" then
			activityData = allActivityData[i]
			break
		end
	end

	if activityData ~= nil then
		num = #activityData
		for i = 1, num do
			if activityData[i].actid == "4" then
				itemData = activityData[i]
				break
			end
		end
	end

	for i = 1, #monthCardData do
		if itemData ~= nil  then
			local num = #itemData

			local dataFound = 0
			if num > 0 then
				for j = 1, num do
					if itemData[j][0] == "canget" then
						if itemData[j].subid == tostring(i) then
							monthData[i] = 0
							newsCount = newsCount + 1
							monthcardNewsCount = monthcardNewsCount + 1
							dataFound = 1
							break
						end
					end
				end

				if dataFound == 0 then
					local ingXML = itemData:find("ing")
					if ingXML then
						for k = 1, #ingXML do
							if ingXML[k].subid == tostring(i) then
								monthData[i] = 2
								dataFound = 2
								break
							end
						end
					end
				end

				if dataFound == 0 then
					monthData[i] = 1
				end
			else
				monthData[i] = 1
			end
		else
			monthData[i] = 1
		end
	end
	return nil
end

function initAccumulateMoneyActivity()
	local count = #activityDataConfig
	local num = #allActivityData
	for i = 1, num do
		if allActivityData[i].type == "6" then
			activityData = allActivityData[i]
			break
		end
	end
	if activityData ~= nil then
		num = #activityData
		for i = 1, num do
			--if activityData[i].on == "1" then
			if activityData[i].on then
				activityDataConfig[count + 1] =  {type=0, name="business_proxy/accumulateMoney_business", icon="activity12"}
			end
		end
	end
end

function clearActivityBtns(  )
	-- 清空所有按鈕
	if GetMainMenu() == nil then 
		return
	end

	local currentNode = tolua.cast(GetMainMenu():GetSubContentNode(), "CCNode")
	local currentlayer = tolua.cast(currentNode:getChildByTag(1001), "CCLayer")
	for i = 1, 100 do
		local btn = currentlayer:getChildByTag(i)
		if btn ~= nil then
			currentlayer:removeChildByTag(i, true)
		end
	end
end
function recreateActivityBtns(  )
	showStageGiftBtn = false
	
	-- 重新加载活动数据
	initAllActivityData()
	initMainMenuActivityBtn("callback")
end

function initStageGift(  )
	popupActivityData = allActivityData:find("items")
	if popupActivityData == nil then
		return nil
	end
	--cclog("---------------------------------")
	--cclog("%s",popupActivityData)
	--cclog("---------------------------------")
	showStageGiftBtn = false
	for i=1, #popupActivityData do
		--状态、id、活动开关中的位置、类型
		local actId = tonumber(popupActivityData[i]:find("id")[1])

		if actId == stageGiftId then
			local act_on_off = tonumber(popupActivityData[i]:find("onoff")[1])
			local timeleft = 0
			if act_on_off == 1 then
				timeleft = tonumber(popupActivityData[i]:find("timeleft")[1])
				if timeleft > 0 then
					showStageGiftBtn = true
				else
					showStageGiftBtn = false
				end
			elseif act_on_off == 0 then
				showStageGiftBtn = false
			end
		
			if showStageGiftBtn then
				table.insert(mainMenuActivityConfigData, {script="createStageGiftLayer()", btnImg = "ccbResources/activity_icon_11.png", display = 0,bShowTime = true, 
					time = timeleft,callback = recreateActivityBtns})
			end
			break
		end
	end
end


--获取消息数目
function getNewsCount(_index)
	--添加newCount
	local newCount = 0
	if activity_config.activityConfig[_index].icon == "activity1" then--登录奖励
		newCount = loginNewsCount
	elseif activity_config.activityConfig[_index].icon == "activity2" then--升级奖励
		newCount = upgradeNewsCount
	elseif activity_config.activityConfig[_index].icon == "activity3" then--超值月卡
		newCount = monthcardNewsCount
	elseif activity_config.activityConfig[_index].icon == "activity5" then--累计充值
		newCount = payhisNewsCount
	--[[
	elseif activity_config.activityConfig[_index].icon == "activity6" then--收集兑换
		newCount = collectExchgNewsCount
	--]]
	elseif activity_config.activityConfig[_index].icon == "activity7" then--签到奖励
		newCount = keepLoginNewsCount
	elseif activity_config.activityConfig[_index].icon == "activity12" then--定时礼包
		newCount = timePurchaseNewsCount
	elseif activity_config.activityConfig[_index].icon == "activity13" then--世界boss
		newCount = worldBossNewsCount
	elseif activity_config.activityConfig[_index].icon == "activity14" then--限量礼包
		newCount = limitGroupNewsCount
	elseif activity_config.activityConfig[_index].icon == "activity15" then--百宝箱
		newCount = boxOpenNewsCount
	elseif activity_config.activityConfig[_index].icon == "activity16" then--女神献花
		newCount = goddessFlowersNewsCount
	else
		newCount = 0
	end

	if newCount <= 0 then
		newCount = 0
	end

	return newCount
end

--获取小红点状态
function getDisplay(_index)
	local _isDisplay = -1
	if _index == 17 then       ---大富翁
		_isDisplay = activityPeriod.monopoly.display
	elseif _index == 18 then   ---限时神将
		_isDisplay = activityPeriod.limitSuper.display
	elseif _index == 20 then   ---大转盘
		_isDisplay = activityPeriod.roulette.display
	elseif _index == 21 then   ---猜拳
		_isDisplay = activityPeriod.mora.display
	end

	return _isDisplay
end

---获取活动控制数据 By_litao_2014.1.2----
function initPopupActivityData()
	--用于存储排列好的活动开关数据
	sortedPopupActivityData = {}

	--按照数据格式找到conf节点
	getAllActivityData = allActivityData:find("conf")	
	if getAllActivityData == nil then
		return nil
	end

	--获取特殊活动开关状态(开服相关——最强战力)
	local openTypeNum = 0
	--开服相关
	local openType = getAllActivityData:find("opentype")
	if openType then
		openTypeNum = tonumber(openType[1])
	end

	--items节点
	popupActivityData = getAllActivityData:find("items")
	if popupActivityData == nil then
		return nil
	end

	if nil ~= getAllActivityData:find("pingfen") then
		g_evaluate_app_activity_status = tonumber(getAllActivityData:find("pingfen")[1])
	end
	---[[
	--整理活动控制数据
	for i=1, #popupActivityData do
		--状态、id、活动开关中的位置、类型
		local actId = popupActivityData[i]:find("id")
		local actPos = popupActivityData[i]:find("pos")
		local actStatus = popupActivityData[i]:find("status")
		local act_on_off = popupActivityData[i]:find("onoff")
		local _act_type = popupActivityData[i]:find("type")

		local indexId = tonumber(actId[1])
		local indexStatus = tonumber(actStatus[1])
		local indexPos = tonumber(actPos[1])
		local index_on_off = tonumber(act_on_off[1])

		--跨服活动标志
		local local_is_cross = popupActivityData[i]:find("is_cross")
		local index_is_cross = 0
		if nil ~= local_is_cross then
			index_is_cross = tonumber(local_is_cross[1])
		end
		
		--整理对应活动的配置
		for j=1,#activity_config.activityConfig do
			--評分機制
			--cclog("1111----%d",g_evaluate_app_activity_status)
			if indexId == 23 and g_evaluate_app_activity_status == 1 then
				break
			end

			-- 阶段礼包前面已经处理过
			if indexId == stageGiftId then
				break
			end

			--支持配置不连续
			if nil ~= activity_config.activityConfig[j] then
				--查找对应活动配置
				if indexId == tonumber(activity_config.activityConfig[j].id) then
					--主界面活动/活动开关列表 分开处理			
					if nil == _act_type then
						break
					end

					local _type = tonumber(_act_type[1])
					if _type == 1 then            --1主界面活动 2控制台活动
						local _t_mainMenuAct = {}
						_t_mainMenuAct.script = activity_config.activityConfig[j].name
						_t_mainMenuAct.btnImg = activity_config.activityConfig[j].icon
						_t_mainMenuAct.display = getDisplay(indexId)
						--添加id
						_t_mainMenuAct.id = indexId

						--猜拳3态特殊处理
						if index_on_off == 1 and indexId == 21 then
							CPlayerDataMgr:instance():SetMoraOpen(1)
						elseif index_on_off == 2 and indexId == 21 then
							CPlayerDataMgr:instance():SetMoraOpen(2)
						elseif index_on_off == 3 and indexId == 21 then
							CPlayerDataMgr:instance():SetMoraOpen(3)
						end

						--限时特惠单独处理_litao_2014.8.14
						if indexId == 27 then
							_t_mainMenuAct.btnImg = "ccbResources/activity_icon_10.png"
						end

						--跨服活动特殊处理_litao_2014.8.21
						if index_is_cross == 1 then
							if indexId == 17 then
								_t_mainMenuAct.script = tostring("GetMainMenu():ChangeToActivitySubMenu(\"ShowCrossMonopolyView\")")
								_t_mainMenuAct.btnImg = tostring("ccbResources/activity_icon_5_1.png")
							elseif indexId == 18 then
								_t_mainMenuAct.script = tostring("GetMainMenu():ChangeToActivitySubMenu(\"ShowCrossSuperNinjaView\")")
								_t_mainMenuAct.btnImg = tostring("ccbResources/activity_icon_7_1.png")
							elseif indexId == 20 then
								_t_mainMenuAct.script = tostring("GetMainMenu():ChangeToActivitySubMenu(\"ShowCrossRouletteView\")")
								_t_mainMenuAct.btnImg = tostring("ccbResources/activity_icon_3_1.png")
							end
						end 

						if indexId == 21 and index_on_off == 3 then
							_t_mainMenuAct = nil
						else
							table.insert(mainMenuActivityConfigData, _t_mainMenuAct)
						end
					elseif _type == 2 then        --1主界面活动 2控制台活动
						local tempActivityData = {}
						tempActivityData.id = indexId
						tempActivityData.name = activity_config.activityConfig[indexId].name
						tempActivityData.icon = activity_config.activityConfig[indexId].icon
						tempActivityData.status = indexStatus
						tempActivityData.newscount = getNewsCount(indexId)
						tempActivityData.pos = indexPos

						--特殊处理(开服相关/BOSS)
						if openTypeNum == 3 then
							if indexId == 8 or indexId == 9 or indexId == 10 then
								tempActivityData = nil
							end
						elseif openTypeNum == 2 and indexId == 8 then
							tempActivityData = nil
						elseif indexId == 8 then
							tempActivityData = nil
						end

                        --monthCard unvisiable_litao_2014.7.16   --针对苹果做特殊处理
                        --[[
                        if indexId == 3 and is_applestore then
                            tempActivityData = nil
                        end
						]]

						--审核期间关闭网页支付和勤奋礼包
						if global.isReviewing() then
							if indexId == 28 or indexId == 23 then
								tempActivityData = nil
							end
						end
						

						if tempActivityData ~= nil then
							table.insert(sortedPopupActivityData, tempActivityData)
						end
					end
					break
				end
			end
		end
	end
	--]]

	--判断数据是否为空
	if sortedPopupActivityData == nil then
		return nil
	end
	--按照pos排列
	---[[
	for i=1, #sortedPopupActivityData - 1 do
		for j=i + 1, #sortedPopupActivityData do
			if sortedPopupActivityData[i].pos == nil then
				break
			elseif sortedPopupActivityData[j].pos == nil then
				break
			end

			if sortedPopupActivityData[i].pos > sortedPopupActivityData[j].pos then
				sortedPopupActivityData[i], sortedPopupActivityData[j] = sortedPopupActivityData[j], sortedPopupActivityData[i]
			end
		end
	end
	--]]
	--新增彩票
	--[[
	local _t_lottery = {}
	_t_lottery.id = 22
	_t_lottery.name = tostring("business_proxy/lotteryTicket_business")
	_t_lottery.icon = tostring("activity21")
	_t_lottery.status = 1
	_t_lottery.newscount = 0
	_t_lottery.pos = #sortedPopupActivityData+1

	if _t_lottery ~= nil then
		table.insert(sortedPopupActivityData, _t_lottery)
	end
	--]]
end
function createStageGiftLayer( )
		require("ui_layer/ui_stageGiftLayer")
		require("ui_layer/ui_stageGiftCell")
	
		local view = createObj(ui_stageGiftLayer)
		local currentlayer = GetMainMenu():GetModelLayer()
		currentlayer:addChild(view.node_)
	end
-- 初始化所有活动数据
function initAllActivityData()
	newsCount = actNewsCount
	loginDays = 1
	keepLoginNewsCount = 0
	loginNewsCount = 0
	upgradeNewsCount = 0
	monthcardNewsCount = 0
	
	activityDataConfig = {}
	mainMenuActivityConfigData = {}

	--苹果审核期间不开忍界榜
	if not global.isReviewing() then
		table.insert(mainMenuActivityConfigData, {script="GetMainMenu():ChangeToActivitySubMenu(\"ShowHallOfFame\")", btnImg = "ccbResources/activity_icon_6.png", display = 0})
	end

	-- 因为阶段礼包的图标要固定放在上面，所以先处理
	initStageGift()
	--秘宝
	--[[
	table.insert(mainMenuActivityConfigData, {script="GetMainMenu():ChangeToActivitySubMenu(\"ShowNinjaTreasureView\")", btnImg = "ccbResources/activity_icon_9.png", display = 0})
	--]]
	---------------------------
	initLoginActivityData()
	initKeepLoginActivityData()
	initUpgradeActivityData()
	initLotteryData()
	initMonthCardData()

	initRankPowerActivity()
	initMoraActivity()
	initFightBossActivity()
	initAccumulateMoneyActivity()

	--updated by gongsun 2014.4.14
	extraInit()
	---获取活动控制数据 By_litao_2014.1.2----
	initPopupActivityData()
	---------------------------------

	-- 添加活动列表
	ClearActivityName()

	local notDisplayActivityType = {}

	--if loginDays <= 30 then
	if #keeploginData <= 0 then
		table.insert(notDisplayActivityType, 5)
	end

	---将活动里面的排列按照开关的顺序来 By_litao_2014.1.6----
	defaultNews = 0
	for k, v in pairs(sortedPopupActivityData) do
		PushActivityName(v.name, v.icon)
		--if v.icon == "activity1" or v.icon == "activity2" then
			defaultNews = defaultNews + v.newscount
		--end
		--设置各个活动消息数目
		CPlayerDataMgr:instance():SetActivityNews(v.icon, tonumber(v.newscount))
	end
	CPlayerDataMgr:instance():SetActivityNewsNum(defaultNews)

    ---特惠单独处理_litao_2014.8.14
	for k, v in pairs(mainMenuActivityConfigData) do
		if tonumber(v.id) == 27 then
			PushActivityName("business_proxy/limitDiscount_business", "activity25")
			cclog("push limitDiscount")
			break
		end
	end

	--7天活动_litao	
	local _login_days_count = CPlayerDataMgr:instance():GetTotalLoginDay()
	local _playerData_ = CPlayerDataMgr:instance():GetPlayerInfoData()
	--get info from table_bin
	local config_info_level = DataMgr.GetDataByID("Struct_Functionconfig", 12)
	local config_info_days = DataMgr.GetDataByID("Struct_Functionconfig", 13)
	--
	if nil ~= config_info_days and nil ~= config_info_level then 
	    if _login_days_count <= tonumber(config_info_days.m_needlevel) and _playerData_.m_level >= tonumber(config_info_level.m_needlevel) then
			PushActivityName("business_proxy/sevenDay_business", "activity17")
		end
	else
		PushActivityName("business_proxy/sevenDay_business", "activity17")
	end

	return nil
end

function extraInit()
	if loginData[7] == 2 then
		CPlayerDataMgr:instance():SetNaturoOpened(false)
	else
		CPlayerDataMgr:instance():SetNaturoOpened(true)
	end
	
	--close level 30 nan
	if upgradeData[3] == 2 then
		CPlayerDataMgr:instance():SetNanOpened(false)
	else
		CPlayerDataMgr:instance():SetNanOpened(false)
	end

	readPayhisState()
	return nil
end

-- 读取累计充值数据
function readPayhisState()
	local uid = CPlayerDataMgr:instance():GetPlayerInfoData().m_uid
	local urlpath = GetUrlNormalHeader(uid,2,"rl_r_paypack")
	CCHttpRequest:open(urlpath, kHttpPost, "query=param1&other=params"):sendWithHandler(
	function(res, hnd)
		local resData = res:getResponseData()
		local code = res:getResponseCode()
		local xfile = xml.parse(resData)
		local item = xfile:find("RENLONG")
		if item == nil then
			return nil
		end
		local retcode = item.code
		if retcode == "0" then
			local hisdata = xfile:find("payheaplist")
			initPayHisData(hisdata)
		end
	end)
	return nil
end

-- 初始化累计充值数据
function initPayHisData(hisData)
	for i = 1, #hisData do
		if hisData[i][0] == "payheap" then
			local index = hisData[i][1][1] + 0
			local state = hisData[i][2][1] + 0
			if state == 0 then
				--newsCount = newsCount + 1
				--payhisNewsCount = payhisNewsCount + 1
			end
			payhisData[index] = state
		end
	end
	--CPlayerDataMgr:instance():SetActivityNewsNum(newsCount)
	return nil
end
-- --------------------------------------------------------------------


-- 从后台读取活动数据并初始化数据
function readActivityState()
	local playerMgr = CPlayerDataMgr:instance()
	local playerData = playerMgr:GetPlayerInfoData()
	local uid = playerData.m_uid
	local urlpath = GetUrlNormalHeader(uid,9000,"rl_r_activity")
	cclog("221122---%s", urlpath)
	CCHttpRequest:open(urlpath, kHttpPost, "query=param1&other=params"):sendWithHandler(
	--CCHttpRequest:open("https://google.com/search?q=LuaProxy&safe=strict", kHttpPost, "query=param1&other=params"):sendWithHandler(
	function(res, hnd)
		local resData = res:getResponseData()
		cclog("222266---%s", resData)
		local code = res:getResponseCode()
		local xfile = xml.parse(resData)
		local item = xfile:find("RENLONG")
		if item == nil then
			return nil
		end
		local retcode = item.code
		if retcode == "0" then
			allActivityData = item
			allActivityNum = #item
			initAllActivityData()

			--将整理好的popup活动数据赋给相应页面 By_litao_2014.1.2
			ui_activityPopupLayer.getPopupActivityData = sortedPopupActivityData

			--extraInit()
			--CPlayerDataMgr:instance():SetActivityNewsNum(defaultNews)
			initMainMenuActivityBtn("http")--刷新大活动小红点
		end
		if GetLoadScene() then
			GetLoadScene():LoadRoundInfo();
		end
	end)
	return nil
end

--comesrc 是指这个函数是由哪里调用，这个函数是每次进入主界面时调用，并且在readActivityState 中有调用
function initMainMenuActivityBtn(comesrc)
	clearActivityBtns()
	if comesrc == "http" and isloadMainMenuActivity == true then
		--return nil
		--刷新小红点
		if GetMainMenu():GetCurrentSubMenuType() == E_DEFAULTMENU then
			RefreshActivityTips(waraward)

			local currentNode = tolua.cast(GetMainMenu():GetSubContentNode(), "CCNode")
			local currentlayer = tolua.cast(currentNode:getChildByTag(1001), "CCLayer")

			local contentSize = currentlayer:getContentSize()
			local y = contentSize.height - 550
			for i = 1, #mainMenuActivityConfigData do
				currentlayer:removeChildByTag(i, true)
				local view = createObj(ui_mainActivityBtn, i)
				
				view.node_:setPosition(95.5, y - (i - 1) * 91)
				--[[
				if i < 2 then
					view.node_:setPosition(470, y)
				else
					view.node_:setPosition(95.5, y - (i - 2) * 91)
				end
				--]]
				view.node_:setAnchorPoint(ccp(0.5, 0.5))
				currentlayer:addChild(view.node_, 0, i)
			end
		end
	else
		if comesrc == "http" and isloadMainMenuActivity == false then
			return nil
		end
		local currentNode = tolua.cast(GetMainMenu():GetSubContentNode(), "CCNode")
		local currentlayer = tolua.cast(currentNode:getChildByTag(1001), "CCLayer")
		
		local contentSize = currentlayer:getContentSize()
		local y = contentSize.height - 550
		for i = 1, #mainMenuActivityConfigData do
			local view = createObj(ui_mainActivityBtn, i)
			
			view.node_:setPosition(95.5, y - (i - 1) * 91)
			--[[
			if i < 2 then
				view.node_:setPosition(470, y)
			else
				view.node_:setPosition(95.5, y - (i - 2) * 91)
			end
			--]]
			view.node_:setAnchorPoint(ccp(0.5, 0.5))
			currentlayer:addChild(view.node_, 0, i)
			isloadMainMenuActivity = true
		end
	end
end

function initActivityNews()
	userData = {}
	activityPeriod = {roulette={},monopoly={},mora={},limitSuper={},limitGroup={},goddessFlower={},timePurchase={}}

	actNewsCount = 0
	worldBossNewsCount = 0
	boxOpenNewsCount = 0
	--collectExchgNewsCount = 0
	payhisNewsCount = 0
	goddessFlowersNewsCount = 0
	timePurchaseNewsCount = 0
	limitGroupNewsCount = 0

	waraward = false
	return nil
end

---[[
--获取是否显示小红点状态
function readActivityNewsData()
	goddessFlowerStatus = 0
	timePurchaseStatus = 0
	limitGroupStatus = 0

	initActivityNews()
	local playerMgr = CPlayerDataMgr:instance()
	local playerData = playerMgr:GetPlayerInfoData()
	local uid = playerData.m_uid
	local urlpath = GetUrlNormalHeader(uid,1,"rl_r_trackpoint")
	urlpath = AddData(urlpath, "ActID", tonumber(activity_config.activityTipConfig.all))--999所有
	--cclog("2222---%s", urlpath)
	CCHttpRequest:open(urlpath, kHttpPost, "query=param1&other=params"):sendWithHandler(
	function(res, hnd)
		local resData = res:getResponseData()
		local code = res:getResponseCode()
		local xfile = xml.parse(resData)
		local item = xfile:find("RENLONG")
		if item == nil then
			return nil
		end
		local retcode = item.code
		if retcode == "0" then
			userData = readActivityData(uid)
			local activity = item:find("activity")
			if activity ~= nil then
				for i=1,#activity do
					if activity[i].actid == activity_config.activityTipConfig.worldBoss then--世界boss
						if activity[i].display == "1" then--显示   0不显示
							actNewsCount = actNewsCount + activity[i].count
							worldBossNewsCount = tonumber(activity[i].count)
						end
					elseif activity[i].actid == activity_config.activityTipConfig.boxOpen  then--百宝箱
						if activity[i].display == "1" then--显示   0不显示
							actNewsCount = actNewsCount + activity[i].count
							boxOpenNewsCount = tonumber(activity[i].count)
						end
					--[[暂时不做
					elseif activity[i].actid == activity_config.activityTipConfig.collectExg then--收集兑换
						if activity[i].display == "1" then--显示   0不显示
							actNewsCount = actNewsCount + activity[i].count
							collectExchgNewsCount = tonumber(activity[i].count)
						end]]
					elseif activity[i].actid == activity_config.activityTipConfig.payHistory then--累计充值
						if activity[i].display == "1" then--显示   0不显示
							actNewsCount = actNewsCount + activity[i].count
							payhisNewsCount = tonumber(activity[i].count)
						end
					--这三个活动每次登陆游戏都显示
					elseif activity[i].actid == activity_config.activityTipConfig.goddessFlower then--女神鲜花
						activityPeriod.goddessFlower.period = activity[i].period
						if userData == nil then
							activityPeriod.goddessFlower.display = -1
							actNewsCount = actNewsCount + 1
							goddessFlowersNewsCount = 1
						else
							if showActivityNotify(userData, activity[i].actid, activity[i].period) == 0 then
								activityPeriod.goddessFlower.display = tonumber(activity[i].display)
								if activity[i].display == "1" then--显示   0不显示
									actNewsCount = actNewsCount + activity[i].count
									goddessFlowersNewsCount = tonumber(activity[i].count)
								else--如果期数相同，但是无奖励可领取，重新登陆的时候同样要亮起
									goddessFlowerStatus = 1
								end
							else
								activityPeriod.goddessFlower.display = -1
								actNewsCount = actNewsCount + 1
								goddessFlowersNewsCount = 1
							end
						end
					elseif activity[i].actid == activity_config.activityTipConfig.timePurchase then--定时礼包
						activityPeriod.timePurchase.period = activity[i].period
						if userData == nil then
							activityPeriod.timePurchase.display = -1
							actNewsCount = actNewsCount + 1
							timePurchaseNewsCount = 1
						else
							if showActivityNotify(userData, activity[i].actid, activity[i].period) == 0 then
								activityPeriod.timePurchase.display = tonumber(activity[i].display)
								if activity[i].display == "1" then--显示   0不显示
									actNewsCount = actNewsCount + activity[i].count
									timePurchaseNewsCount = tonumber(activity[i].count)
								else--如果期数相同，但是无奖励可领取，重新登陆的时候同样要亮起
									timePurchaseStatus = 1
								end
							else
								activityPeriod.timePurchase.display = -1
								actNewsCount = actNewsCount + 1
								timePurchaseNewsCount = 1
							end
						end
					elseif activity[i].actid == activity_config.activityTipConfig.limitGroup then--限量礼包
						activityPeriod.limitGroup.period = activity[i].period
						if userData == nil then
							activityPeriod.limitGroup.display = -1
							actNewsCount = actNewsCount + 1
							limitGroupNewsCount = 1
						else
							if showActivityNotify(userData, activity[i].actid, activity[i].period) == 0 then
								activityPeriod.limitGroup.display = tonumber(activity[i].display)
								if activity[i].display == "1" then--显示   0不显示
									actNewsCount = actNewsCount + activity[i].count
									limitGroupNewsCount = tonumber(activity[i].count)
								else--如果期数相同，但是无奖励可领取，重新登陆的时候同样要亮起
									limitGroupStatus = 1
								end
							else
								activityPeriod.limitGroup.display = -1
								actNewsCount = actNewsCount + 1
								limitGroupNewsCount = 1
							end
						end
					----------------------------------------------
					--大活动
					elseif activity[i].actid == activity_config.activityTipConfig.roulette then--大转盘
						activityPeriod.roulette.period = activity[i].period
						if userData == nil then
							activityPeriod.roulette.display = -1
						else
							if showActivityNotify(userData, activity[i].actid, activity[i].period) == 0 then
								activityPeriod.roulette.display = tonumber(activity[i].display)
							else
								activityPeriod.roulette.display = -1
							end
						end
					elseif activity[i].actid == activity_config.activityTipConfig.monopoly then--大富翁
						activityPeriod.monopoly.period = activity[i].period
						if userData == nil then
							activityPeriod.monopoly.display = -1
						else
							if showActivityNotify(userData, activity[i].actid, activity[i].period) == 0 then
								activityPeriod.monopoly.display = tonumber(activity[i].display)
							else
								activityPeriod.monopoly.display = -1
							end
						end
					elseif activity[i].actid == activity_config.activityTipConfig.mora then--猜拳
						activityPeriod.mora.period = activity[i].period
						if userData == nil then
							activityPeriod.mora.display = -1
						else
							if showActivityNotify(userData, activity[i].actid, activity[i].period) == 0 then
								activityPeriod.mora.display = tonumber(activity[i].display)
							else
								activityPeriod.mora.display = -1
							end
						end
					elseif activity[i].actid == activity_config.activityTipConfig.limitSuper then--限时神将
						activityPeriod.limitSuper.period = activity[i].period
						if userData == nil then
							activityPeriod.limitSuper.display = -1
						else
							if showActivityNotify(userData, activity[i].actid, activity[i].period) == 0 then
								activityPeriod.limitSuper.display = tonumber(activity[i].display)
							else
								activityPeriod.limitSuper.display = -1
							end
						end
					----------------------------------------------
					--[[非活动   暂时不用
					elseif activity[i].actid == activity_config.activityTipConfig.reincarnation then--转生
						reincarnationDisplay = tonumber(activity[i].display)]]
					elseif activity[i].actid == activity_config.activityTipConfig.waraward then
						if tonumber(activity[i].display) == 1 then
							waraward = true
						end
					end
				end
				readActivityState()
			end
		end
	end)
	return nil
end--]]

readActivityNewsData()
--readActivityState()