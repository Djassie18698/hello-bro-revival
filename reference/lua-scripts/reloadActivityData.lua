require "RLRequest"
require "LuaXml"
require "util/localizable"

-- 从后台读取活动数据并初始化数据
function refreshActivityState()
	local playerMgr = CPlayerDataMgr:instance()
	local playerData = playerMgr:GetPlayerInfoData()
	local uid = playerData.m_uid
	local urlpath = GetUrlNormalHeader(uid,9000,"rl_r_activity")
	cclog(urlpath)
	CCHttpRequest:open(urlpath, kHttpPost, "query=param1&other=params"):sendWithHandler(
	--CCHttpRequest:open("https://google.com/search?q=LuaProxy&safe=strict", kHttpPost, "query=param1&other=params"):sendWithHandler(
	function(res, hnd)
		local resData = res:getResponseData()
		local code = res:getResponseCode()
		local xfile = xml.parse(resData)
		local item = xfile:find("RENLONG")
		local retcode = item.code
		if retcode == "0" then
			allActivityData = item
			allActivityNum = #item
			initAllActivityData()

			--将整理好的popup活动数据赋给相应页面 By_litao_2014.1.2
			ui_activityPopupLayer.getPopupActivityData = sortedPopupActivityData
			--updated by gongsun 2014.4.14
			--extraInit()
			--CPlayerDataMgr:instance():SetActivityNewsNum(defaultNews)
			initMainMenuActivityBtn("http")--刷新大活动小红点
		end
	end)
	return nil
end

---[[
--获取是否显示小红点状态
function readActivityNewsData()
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
		--cclog("2222---%s", resData)
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
								else
									if goddessFlowerStatus == 1 then
										activityPeriod.goddessFlower.display = -2
										actNewsCount = actNewsCount + 1
										goddessFlowersNewsCount = 1
										goddessFlowerStatus = 0
									end
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
								else
									if timePurchaseStatus == 1 then
										activityPeriod.timePurchase.display = -2
										actNewsCount = actNewsCount + 1
										timePurchaseNewsCount = 1
										timePurchaseStatus = 0
									end
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
								else
									if limitGroupStatus == 1 then
										activityPeriod.limitGroup.display = -2
										actNewsCount = actNewsCount + 1
										limitGroupNewsCount = 1
										limitGroupStatus = 0
									end
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
					--[[非活动 暂时不用
					elseif activity[i].actid == activity_config.activityTipConfig.reincarnation then--转生
						reincarnationDisplay = tonumber(activity[i].display)]]
					elseif activity[i].actid == activity_config.activityTipConfig.waraward then
						if tonumber(activity[i].display) == 1 then
							waraward = true
						end
					end
				end
				refreshActivityState()
			end
		end
	end)
	return nil
end--]]

readActivityNewsData()
--refreshActivityState()