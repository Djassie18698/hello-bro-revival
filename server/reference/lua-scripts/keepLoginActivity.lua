require "RLRequest"
require "util/localizable"

local actType = "5"
local actId = "5"
local activityData
local itemData
local m_touchPoint
local tableview

local btn1


local function onBtnClick(btn)

	local notGot = true
	for k, v in pairs(keeploginData) do
		if v == 0 then			
			local playerMgr = CPlayerDataMgr:instance()
			local playerData = playerMgr:GetPlayerInfoData()
			local uid = playerData.m_uid
			local urlpath = GetUrlNormalHeader(uid,9100,"rl_w_activity")
			urlpath = AddData(urlpath, "ActType", actType)
			urlpath = AddData(urlpath, "ActID", actId)
			--urlpath = AddData(urlpath, "SubID", index)
			local p = 1
			GetMainMenu():ShowLoadingDlg();	-- 获取信息的时候，不允许操作
			--urlpath = "http://203.195.181.162:8080/rl_w_guaguale?Cmd=1700&Uid=80021&Session=962954F5D722633016FF458E22920C29&Clinettime=2013/10/22 21:56:17 Tuesday&Platform=win32&Version=1.0.0&Pt=3&Area=2"
			CCHttpRequest:openWithUserData(urlpath, kHttpPost, p, "query=param1&other=params"):sendWithHandler(
			function(res, hnd)
				--local p = res:getHttpRequest():getUserData()
				--local index = tolua.cast(p, "CCPoint").x
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
					--local monthXML = xfile:find("month")
					--local recash = monthXML:find("recash")[1]
					--CPlayerDataMgr:instance():AddGold(recash)
					--local pathName = "ccbResources/activity.plist"
					--CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile(pathName)
					local card = tableview:getChildByTag(101)
					local a = card:getTag()
					local strNum = tostring(k)
					local pFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("activity_22")
					local bkSprite = tolua.cast(card:GetNode("sprite_big_bk_" .. strNum), "CCScale9Sprite")
					bkSprite:setSpriteFrame(pFrame)
					bkSprite:setPreferredSize(CCSizeMake(147, 220))
					tolua.cast(card:GetNode("label_num_" .. strNum), "CCLabelTTF"):setColor(ccc3(83,40,0))
					tolua.cast(card:GetNode("label_day_" ..strNum), "CCLabelTTF"):setColor(ccc3(83,40,0))
					local sprite_bk = tolua.cast(card:GetNode("sprite_gift_bk_" .. strNum), "CCNode")
					local pProgram = CCShaderCache:sharedShaderCache():programForKey("greysprite")
					local giftSprite = sprite_bk:getChildByTag(100)
					local tag = giftSprite:getTag()
					giftSprite:setShaderProgram(pProgram)
					keeploginData[k] = 2
					GetMainMenu():ShowTextTip(localizable.monthCard_get_success,-1)
				else
					GetMainMenu():ShowErrorTip(retcode,-1)
				end
			end)
			notGot = false
		end

	end

	if notGot then
		GetMainMenu():ShowTextTip(localizable.keepLogin_gotaward_today_desc,-1)
	end
	return nil
end


local function initKeepLogin(card)
	for k, v in pairs(keeplogin_data) do
		local spriteGiftName = "sprite_gift_bk_"..tostring(v.keeplogin_days)
		local spriteBigBkName ="sprite_big_bk_" .. tostring(v.keeplogin_days)
		local labelNum = "label_num_" .. tostring(v.keeplogin_days)
		local labelDay = "label_day_" .. tostring(v.keeplogin_days)

		local pathName = "props/"..v.keeplogin_icon..".plist"
		CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile(pathName)
		local sprite_icon = CCSprite:createWithSpriteFrameName(v.keeplogin_icon)
		--local sprite_icon = CCSprite:createWithSpriteFrameName("activity_props_.01")
		local sprite_bk = tolua.cast(card:GetNode(spriteGiftName), "CCNode")
		local contentSize = sprite_bk:getContentSize()
		sprite_icon:setPosition(contentSize.width / 2, contentSize.height / 2)
		sprite_icon:setAnchorPoint(ccp(0.5, 0.5))
		sprite_icon:setTag(100)
		sprite_bk:addChild(sprite_icon)
		local label1 = tolua.cast(card:GetNode(labelNum), "CCLabelTTF")
		label1:setString("x  "..tostring(v.keeplogin_number))
		
		local bkSprite = tolua.cast(card:GetNode(spriteBigBkName),"CCScale9Sprite")
		--local preferredSize = bkSprite:getPreferredSize()
		local preferredSize = CCSizeMake(147, 220)
		local pFrame
		local pProgram = CCShaderCache:sharedShaderCache():programForKey("greysprite");
		if keeploginData[v.keeplogin_days] == 0 then
			pFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("activity_26")
			bkSprite:setSpriteFrame(pFrame)
			bkSprite:setPreferredSize(preferredSize)
			label1:setColor(ccc3(255,255,255))
			tolua.cast(card:GetNode(labelDay), "CCLabelTTF"):setColor(ccc3(255,255,255))
		elseif keeploginData[v.keeplogin_days] == 1 then
			pFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("activity_25")
			bkSprite:setSpriteFrame(pFrame)
			bkSprite:setPreferredSize(preferredSize)
			--sprite_icon:setShaderProgram(pProgram);
		else
			sprite_icon:setShaderProgram(pProgram);
			--pFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("activity_22")
			--tolua.cast(card:GetNode(spriteGiftName), "CCScale9Sprite"):setSpriteFrame(pFrame)
		end
	end
	tolua.cast(card:GetNode("label_login_days"), "CCLabelBMFont"):setString(tostring(keepLoginDays))
	btn1 = tolua.cast(card:GetNode("btn_get_login_gift"), "CCControlButton")
	return nil
end

local function createView()
	local proxy = CCBProxy:create()
	proxy:retain()
	local contentNode = GetActivityView():GetNodeContent()
	local contentSize = contentNode:getContentSize()
	local n = proxy:readCCBFromFileBySize("activity/KeepLogin.ccbi", contentSize)
    local layer = tolua.cast(n, "CCLayer")
	local card = CActivityCommonCardView:create()
	card:setTag(101)
	card:SetProxy(proxy)
	card:AssignCCBMemberVariable(proxy:getMemberVariables())
	initKeepLogin(card)
	layer:addChild(card)
	layer:setTag(100)
	
	-- 初始化按钮
	proxy:handleButtonEvent(btn1, function(button, event)
		onBtnClick(button)
		return nil
	end, CCControlEventTouchUpInside)
	
	return layer
end


tableview = createView()

local activityView = GetActivityView()
local contentNode = activityView:GetNodeContent()
contentNode:addChild(tableview)
