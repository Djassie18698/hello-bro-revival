require "RLRequest"
require ("util/localizable")
require ("util/protocol")
require ("global/cfg")

local actType = "4"
local actId = "4"
local activityData
local itemData
local m_touchPoint
local tableview
local requestBuyTimes = 0
local btn1
local btn2
local btn3

monthMapMoney  = {}
monthMapMoney[1] = 4.99
monthMapMoney[2] = 9.99

local function clickGetPack(index)
	--if monthData[index+1] == 0 then
	--end
	return nil
end

local function appleBuyCallBack(jsonStr, orderStrId, shopGoodIdStr)
        local playerMgr = CPlayerDataMgr:instance()
		local playerData = playerMgr:GetPlayerInfoData()
		local uid = playerData.m_uid
        local urlpath = GetUrlNormalHeader(uid, protocol.CMD_PAYPACK, protocol.URL_W_APPLE_BUY)
		local postValue = string.format("{\"receipt-data\":\"%s\",\"password\":\"%s\"}", jsonStr, "your_secret_here")
		urlpath = AddData(urlpath, "rc", postValue)
		--cclog("1111----%s", urlpath)
		GetMainMenu():ShowLoadingDlg()
		CCHttpRequest:open(urlpath, kHttpPost,"query=param1&other=params"):sendWithHandler(
		function(res, hnd)
			GetMainMenu():CloseLoadding()
			local resData = res:getResponseData()
			--cclog("1111----%s\n", resData)
			local code = res:getResponseCode()
			local xfile = xml.parse(resData)
			local item = xfile:find("RENLONG")
			if item == nil then
				return nil
			end
			local retcode = item.code
			if retcode == "0" then
                local appleOrderId = item:find("orderid")[1]
				local urlpath1 = GetUrlNormalHeader(uid, protocol.CMD_KY_CHECKORDER, protocol.URL_R_KY_CHECKORDER)
				urlpath1 = AddData(urlpath1, "DealNo", appleOrderId)
				GetMainMenu():ShowLoadingDlg()
				CCHttpRequest:open(urlpath1, kHttpPost,"query=param1&other=params"):sendWithHandler(
				function(res, hnd)
					GetMainMenu():CloseLoadding()
					local resData = res:getResponseData()
					--cclog("1111----001--%s\n", resData)
					local code = res:getResponseCode()
					local xfile = xml.parse(resData)
					local item = xfile:find("RENLONG")
					local retcode = item.code
					if retcode == "0" then
						GetMainMenu():ShowTextTip(localizable.ui_buy_success_tips, -1)
						CallBackFinishTrans();
					else
						GetMainMenu():ShowTextTip(localizable.ui_buy_failed_tips, -1)
					end
				end)
			elseif retcode == "250013" or retcode == "250014" then
				GetMainMenu():ShowTextTip(localizable.ui_buy_order_tips, -1)
				CallBackFinishTrans();
			else
				requestBuyTimes = requestBuyTimes + 1
				if requestBuyTimes < 2 then
                    --cclog("1111---second:%s", tostring(requestBuyTimes))
					appleBuyCallBack(jsonStr, orderStrId, shopGoodIdStr)
                else
                    --cclog("1111---second2:%s", tostring(requestBuyTimes))
                    GetMainMenu():ShowTextTip(localizable.ui_buy_failed_tips, -1)
				end
			end
		end)
	end

local function onBtnClick(btn)
	CSoundMgr:instance():PlayEffect(SOUND_BUTTON)

	local index
	local cost
	local cardName
	if btn == btn1 then
		index = 1
		cost = 4.99
		cardName = localizable.monthCard_card_name_25
	end
	if btn == btn2 then
		index = 2
		cost = 9.99
		cardName = localizable.monthCard_card_name_50
	end

	--[[
	if GetPlatForm() ~= "android" then
		if btn == btn3 then
			index = 3
			cost = 100
			cardName = localizable.monthCard_card_name_100
		end
	end
	]]

	if index == 2 and CNetUser:instance():GetPlatformID() ==  mm_platform_ptid then
		GetMainMenu():ShowTextTip(localizable.monthCard_failed_to_buy,-1)
		return nil
	end

	if monthData[index] == 0 then
		local playerMgr = CPlayerDataMgr:instance()
		local playerData = playerMgr:GetPlayerInfoData()
		local uid = playerData.m_uid
		local urlpath = GetUrlNormalHeader(uid,9100,"rl_w_activity")
		urlpath = AddData(urlpath, "ActType", actType)
		urlpath = AddData(urlpath, "ActID", actId)
		urlpath = AddData(urlpath, "SubID", index)
		local p = CCPoint:new()
		p.x = index
		GetMainMenu():ShowLoadingDlg();
		CCHttpRequest:openWithUserData(urlpath, kHttpPost, p, "query=param1&other=params"):sendWithHandler(
		function(res, hnd)
			GetMainMenu():CloseLoadding();
			local p = res:getHttpRequest():getUserData()
			local index = tolua.cast(p, "CCPoint").x
			local resData = res:getResponseData()
			local code = res:getResponseCode()
			local xfile = xml.parse(resData)
			local item = xfile:find("RENLONG")
			if item == nil then
				return nil
			end
			local retcode = item.code
			if retcode == "0" then
				--local monthXML = xfile:find("month")
				--local recash = monthXML:find("recash")[1]
				--CPlayerDataMgr:instance():AddGold(recash)
				if newsCount > 0 then
					newsCount = newsCount - 1
				end
				--updated by gongsun 2014.4.14 将开关上的新消息标志刷新
				if ui_activityPopupLayer.getPopupActivityData then
					for k, v in pairs(ui_activityPopupLayer.getPopupActivityData) do
						if v.icon == "activity3" and tonumber(v.newscount) > 0 then
							v.newscount = tonumber(v.newscount) - 1
							CPlayerDataMgr:instance():SetActivityNews("activity3", v.newscount)
							break
						end
					end
				end
				-------------------------------------------------------
				CPlayerDataMgr:instance():SetActivityNewsNum(newsCount)
				GetActTopBarView():Refresh()
				
				GetMainMenu():ShowTextTip(localizable.monthCard_get_success,-1)
			else
				GetMainMenu():ShowErrorTip(retcode,-1)
			end
		end)
	end

	local function refreshMonthUI()
	
	end
	if monthData[index] == 1 then
		local payid = CNetUser:instance():GetPayID()
		if not is_applestore then
			PayHelperForLua:monthCardPay(tostring(cost), payid, cardName, tostring(index), "1", refreshMonthUI)
		else
			InAppPurchase(month_apple_goods_prefix .. tostring(index), appleBuyCallBack)
		end
	end

	if monthData[index] == 2 then
		GetMainMenu():ShowTextTip(localizable.monthCard_not_enough_time,-1)
	end
	return nil
end


local function initCard(card)
	--[[
	local cardnum = 3
	if GetPlatForm() == "android" then
		cardnum = 2
	end
	]]
	local cardnum = 2
	for i = 1, cardnum do
		local spriteName = "btn_item"..tostring(i).."_buy"
		local labelGet = "label_get"..tostring(i)
		local labelBuy = "label_buy"..tostring(i)
		if monthData[i] == 0 then
			--[[local program = CCShaderCache:sharedShaderCache():programForKey("ShaderPositionTextureColor")
			if program ~= nil then
				tolua.cast(card:GetNode(spriteName), "CCNode"):setShaderProgram(program)
			end]]
			tolua.cast(card:GetNode(spriteName), "CCControlButton"):setEnabled(true)
			tolua.cast(card:GetNode(labelGet), "CCNode"):setVisible(true)
			tolua.cast(card:GetNode(labelBuy), "CCNode"):setVisible(false)
		end

		if monthData[i] == 1 then
			--[[local program = CCShaderCache:sharedShaderCache():programForKey("ShaderPositionTextureColor")
			if program ~= nil then
				tolua.cast(card:GetNode(spriteName), "CCNode"):setShaderProgram(program)
			end]]
			tolua.cast(card:GetNode(spriteName), "CCControlButton"):setEnabled(true)
			tolua.cast(card:GetNode(labelGet), "CCNode"):setVisible(false)
			tolua.cast(card:GetNode(labelBuy), "CCNode"):setVisible(true)
		end

		if monthData[i] == 2 then
			--[[local program = CCShaderCache:sharedShaderCache():programForKey("greysprite")
			if program ~= nil then
				tolua.cast(card:GetNode(spriteName), "CCNode"):setShaderProgram(program)
			end]]
			tolua.cast(card:GetNode(spriteName), "CCControlButton"):setEnabled(false)
			tolua.cast(card:GetNode(labelGet), "CCNode"):setVisible(true)
			tolua.cast(card:GetNode(labelBuy), "CCNode"):setVisible(false)
		end
	end

	btn1 = tolua.cast(card:GetNode("btn_item1_buy"), "CCControlButton")
	btn2 = tolua.cast(card:GetNode("btn_item2_buy"), "CCControlButton")

	if is_applestore then
		local monthtitle1 = string.format(localizable.ui_text_title_month_card, tostring(monthMapMoney[1]) .. "USD")
		local monthdesc1 = string.format(localizable.ui_text_desc_month_card, monthCardData[1].month_dayback, monthCardData[1].month_day, monthCardData[1].month_dayback*monthCardData[1].month_day)
		tolua.cast(card:GetNode("label_MonthCard0"), "CCLabelTTF"):setString(monthtitle1)
		tolua.cast(card:GetNode("label_MonthCard1"), "CCLabelTTF"):setString(monthdesc1)

		local monthtitle2 = string.format(localizable.ui_text_title_month_card, tostring(monthMapMoney[2]) .. "USD")
		local monthdesc2 = string.format(localizable.ui_text_desc_month_card, monthCardData[2].month_dayback, monthCardData[2].month_day, monthCardData[2].month_dayback*monthCardData[2].month_day)
		tolua.cast(card:GetNode("label_MonthCard2"), "CCLabelTTF"):setString(monthtitle2)
		tolua.cast(card:GetNode("label_MonthCard3"), "CCLabelTTF"):setString(monthdesc2)

		--启动月卡页面的时候，判断是否存在没有完成的订单
		InAppInitInstance(appleBuyCallBack)	
	end
	
	--[[
	if GetPlatForm() ~= "android" then
		btn3 = tolua.cast(card:GetNode("btn_item3_buy"), "CCControlButton")
	end
	]]

	--启动月卡页面的时候，判断是否存在没有完成的订单
	--InAppInitInstance(appleBuyCallBack)
	
	return nil
end

local function createView()
	local proxy = CCBProxy:create()
	proxy:retain()
	local contentNode = GetActivityView():GetNodeContent()
	local contentSize = contentNode:getContentSize()
	--泰国平台月卡：ios 和 android 一致 
	local n = proxy:readCCBFromFileBySize("activity/MonthCard.ccbi", contentSize)
	--[[
	if GetPlatForm() == "android" then
		n = proxy:readCCBFromFileBySize("activity/MonthCard.ccbi", contentSize)
	else
		n = proxy:readCCBFromFileBySize("activity/MonthCard3.ccbi", contentSize)
	end
	]]

    local layer = tolua.cast(n, "CCLayer")
	local card = CActivityCommonCardView:create()
	card:setTag(100)
	card:SetProxy(proxy)
	card:AssignCCBMemberVariable(proxy:getMemberVariables())
	initCard(card)
	layer:addChild(card)
	layer:setTag(100)

	-- 初始化按钮
	proxy:handleButtonEvent(btn1, function(button, event)
		onBtnClick(button)
		return nil
	end, CCControlEventTouchUpInside)
	proxy:handleButtonEvent(btn2, function(button, event)
		onBtnClick(button)
		return nil
	end, CCControlEventTouchUpInside)
	--[[
	if GetPlatForm() ~= "android" then
		proxy:handleButtonEvent(btn3, function(button, event)
			onBtnClick(button)
			return nil
		end, CCControlEventTouchUpInside)
	end
	]]
	return layer
end


tableview = createView()

local activityView = GetActivityView()
local contentNode = activityView:GetNodeContent()
contentNode:addChild(tableview)
