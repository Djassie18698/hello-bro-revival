require "LuaSubView.lua"
require "RLRequest"
require "LuaXml.lua"
require "util/localizable"

SwitchCountryDialogView=class(
		"SwitchCountryDialogView",
    function()
        return CCLayer:create() 
    end
)

function SwitchCountryDialogView:create()
	local view = SwitchCountryDialogView.new();
	return view;
end

SwitchCountryDialogView.m_selectedCountry = -1
SwitchCountryDialogView.m_selectedCountryCost = -1
SwitchCountryDialogView.m_bagid = -1
SwitchCountryDialogView.m_countryList = {}
SwitchCountryDialogView.m_btnList = {}
SwitchCountryDialogView.m_nodeList = {}
SwitchCountryDialogView.m_item = nil

local SWITCH_COUNTRY_CARD_INDEX = 18

function SwitchCountryDialogView:LoadCost()
		local playerMgr = CPlayerDataMgr:instance()
		local playerData = playerMgr:GetPlayerInfoData()
		local uid = playerData.m_uid
		local urlpath = GetUrlNormalHeader(uid,0,"rl_r_migrate_price")
		local targetCountry = self.m_countryList[self.m_selectedCountry]
		urlpath = AddData(urlpath, "ToCountry", targetCountry)
		GetMainMenu():ShowLoadingDlg();
		CCHttpRequest:open(urlpath, kHttpGet, "query=param1&other=params"):sendWithHandler(
		function(res, hnd)
			GetMainMenu():CloseLoadding();		
			local resData = res:getResponseData()
		    local code = res:getResponseCode()
		    local xfile = xml.parse(resData)
		    local item = xfile:find("RENLONG")
			if item == nil then
				return nil
			end
		    local retcode = item.code
			if retcode == "0" then			
			    local price = item:find("price")[1]
				SwitchCountryDialogView.m_selectedCountryCost = price
				tolua.cast(SwitchCountryDialogView.m_dlgview:getNode("label_cost"), "CCLabelBMFont"):setString(tostring(price))
			else
				GetMainMenu():ShowErrorTip(retcode,-1);
				tolua.cast(SwitchCountryDialogView.m_dlgview:getNode("label_cost"), "CCLabelBMFont"):setString("99999");
			end
			
		end)
		return nil
end

function SwitchCountryDialogView:loadCCBI()
	local view = LuaSubView:create();	
	local win = CCDirector:sharedDirector():getWinSize();
	view:LoadCCBI("dlg_ui/SwitchCountryDialogView.ccbi",CCSize(768,win.height));
	self:addChild(view)
	--view:ignoreAnchorPointForPosition(false)
	view:setPosition(CCPoint(win.width / 2, win.height / 2));
	SwitchCountryDialogView.m_dlgview = view;
	
	self:initUI();
end

function SwitchCountryDialogView:initUI()	
	CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile("ccbResources/normal_dlg_bk.plist")
			
	local index = 1
	for i = 1, 5 do
		if CPlayerDataMgr:instance():GetCountryType() ~= (i-1) then
			local spriteName = "store_candidate_"..CProfileData:GetCountryLayoutName(i-1)
			local frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(spriteName)
			if frame ~= nil then
				local nodeName = "sprite_country"..index
				local node = tolua.cast(SwitchCountryDialogView.m_dlgview:getNode(nodeName), "CCSprite")
				node:removeAllChildrenWithCleanup(true)
				node:setDisplayFrame(frame)
				
				SwitchCountryDialogView.m_countryList[index] = i-1
				SwitchCountryDialogView.m_nodeList[index] = node
			end
			index = index + 1
		end
	end
	
	SwitchCountryDialogView:BindControl();
	self:setTouchEnabled(true)
	self:registerScriptTouchHandler(onTouch,false,kCCMenuHandlerPriority-1,true)
	self:setTouchMode(0) 
end

function onTouch(event, x, y)
    if event == "began" then      
        for i = 1, #SwitchCountryDialogView.m_btnList do
            local rect = tolua.cast(SwitchCountryDialogView.m_btnList[i], "CCControlButton"):boundingBox()
            rect.origin = SwitchCountryDialogView.m_btnList[i]:getParent():convertToWorldSpace(rect.origin)
        	if(rect:containsPoint(CCPoint(x,y)))then
    			tolua.cast(SwitchCountryDialogView.m_btnList[i], "CCControlButton"):setHighlighted(true);	
    		end
        end
        
        return true
    end
    if event == "moved" then    	
    	for i = 1, #SwitchCountryDialogView.m_btnList do
    	    local rect = tolua.cast(SwitchCountryDialogView.m_btnList[i], "CCControlButton"):boundingBox()
    	    rect.origin = SwitchCountryDialogView.m_btnList[i]:getParent():convertToWorldSpace(rect.origin)
        	if(rect:containsPoint(CCPoint(x,y)))then
    			tolua.cast(SwitchCountryDialogView.m_btnList[i], "CCControlButton"):setHighlighted(true);	
    		else
    			tolua.cast(SwitchCountryDialogView.m_btnList[i], "CCControlButton"):setHighlighted(false);
    		end
        end
    end
    if event == "ended" then    	
    	for i = 1, #SwitchCountryDialogView.m_btnList do
    	    local rect = tolua.cast(SwitchCountryDialogView.m_btnList[i], "CCControlButton"):boundingBox()
    	    rect.origin = SwitchCountryDialogView.m_btnList[i]:getParent():convertToWorldSpace(rect.origin)
        	if(rect:containsPoint(CCPoint(x,y)))then
    			tolua.cast(SwitchCountryDialogView.m_btnList[i], "CCControlButton"):setHighlighted(false);	
    			SwitchCountryDialogView.m_btnList[i]:sendActionsForControlEvents(CCControlEventTouchUpInside);	
    		else
    			tolua.cast(SwitchCountryDialogView.m_btnList[i], "CCControlButton"):setHighlighted(false);
    		end
        end
        
        SwitchCountryDialogView:SetCountrySelected(x,y)
    end
end

function SwitchCountryDialogView:AddBtnToList(index, btn)
	self.m_btnList[index] = btn
end

function SwitchCountryDialogView:SetCountrySelected(x,y)
    local selected = false
	for i = 1, #self.m_nodeList do
	    SwitchCountryDialogView.m_nodeList[i]:removeAllChildrenWithCleanup(true)
	    local rect = SwitchCountryDialogView.m_nodeList[i]:boundingBox()
        rect.origin = SwitchCountryDialogView.m_nodeList[i]:getParent():convertToWorldSpace(rect.origin)
		if(rect:containsPoint(CCPoint(x,y)))then
    		local hl = CCSprite:createWithSpriteFrameName("store_candidate_000")
    		if hl ~= nil then
    			SwitchCountryDialogView.m_nodeList[i]:addChild(hl)
    			
    			local size = SwitchCountryDialogView.m_nodeList[i]:getContentSize();
    			hl:setPosition(CCPoint(size.width / 2, size.height / 2))
    		end
    		
    		selected = true
    		SwitchCountryDialogView.m_selectedCountry = i
    	end
	end
	
	if selected == true then
	    SwitchCountryDialogView:LoadCost()
	end
	
end

function SwitchCountryDialogView:BindControl()
	SwitchCountryDialogView:AddBtnToList(1, tolua.cast(SwitchCountryDialogView.m_dlgview:getNode("startButton"), "CCControlButton"))
	SwitchCountryDialogView:AddBtnToList(2, tolua.cast(SwitchCountryDialogView.m_dlgview:getNode("closeButton"), "CCControlButton"))
	SwitchCountryDialogView:AddBtnToList(3, tolua.cast(SwitchCountryDialogView.m_dlgview:getNode("cancelButton"), "CCControlButton"))

		-- 初始化按钮
	SwitchCountryDialogView.m_dlgview:handleButtonEvent(self.m_btnList[1], function(button, event)
		self:Confirm();
		return nil
	end, CCControlEventTouchUpInside)
	SwitchCountryDialogView.m_dlgview:handleButtonEvent(self.m_btnList[2], function(button, event)
		self:CloseView();
		return nil
	end, CCControlEventTouchUpInside)
	SwitchCountryDialogView.m_dlgview:handleButtonEvent(self.m_btnList[3], function(button, event)
		self:CloseView();
		return nil
	end, CCControlEventTouchUpInside)
end

function SwitchCountryDialogView:CloseView() 
	CSoundMgr:instance():PlayEffect(SOUND_BUTTON)
	
    SwitchCountryDialogView.m_selfview:removeFromParentAndCleanup(true);
end

function SwitchCountryDialogView:Confirm() 
	CSoundMgr:instance():PlayEffect(SOUND_BUTTON)
	
    if self.m_selectedCountry == -1 then
            GetMainMenu():ShowTextTip(localizable.switchCountry_select_country_first, -1)
            return nil
    end
	
	local count = CTradeMgr:instance():GetConsumItemCountByID(SWITCH_COUNTRY_CARD_INDEX)
	if count < 1 then
		GetMainMenu():ShowTextTip(localizable.switchCountry_card_notEnough, -1)
        return nil
	end
    
    SwitchCountryDialogView:Start()
end

function SwitchCountryDialogView:Start()
		local playerMgr = CPlayerDataMgr:instance()
		local playerData = playerMgr:GetPlayerInfoData()
		local uid = playerData.m_uid
		local urlpath = GetUrlNormalHeader(uid,1802,"rl_w_propuse")
		local targetCountry = self.m_countryList[self.m_selectedCountry]
		urlpath = AddData(urlpath, "ToCountry", targetCountry)
		urlpath = AddData(urlpath, "Goodsid", self.m_bagid)
		GetMainMenu():ShowLoadingDlg();
		local p = CCPoint:new()
		p.x = targetCountry
		CCHttpRequest:openWithUserData(urlpath, kHttpPost, p, "query=param1&other=params"):sendWithHandler(
		function(res, hnd)
			GetMainMenu():CloseLoadding();		
			local p = res:getHttpRequest():getUserData()
			local targetCountry = tolua.cast(p, "CCPoint").x
			local resData = res:getResponseData()
		    local code = res:getResponseCode()
		    local xfile = xml.parse(resData)
		    local item = xfile:find("RENLONG")
			if item == nil then
				return nil
			end
		    local retcode = item.code
			if retcode == "0" then			
			    CPlayerDataMgr:instance():GetPlayerInfoData().m_countrytype = targetCountry
			    GetMainMenu():ShowTextTip("转国成功", -1)
				local count = CTradeMgr:instance():GetConsumItemCountByID(SWITCH_COUNTRY_CARD_INDEX)
				CTradeMgr:instance():SetConsumItemCountByID(SWITCH_COUNTRY_CARD_INDEX, count-1)
				if self.m_item ~= nil then
					self.m_item:initConsum()
				end
				
				local gold = playerData.m_gold;
				playerMgr:SetGold(gold-self.m_selectedCountryCost);
				
				GetMainMenu():GetCurrentSubMenu():InitNormalHeader();
			else
				GetMainMenu():ShowErrorTip(retcode,-1)
			end
			SwitchCountryDialogView:CloseView()
		end)
		return nil
end


function ShowSwitchCountryDialog(bagid,item)
	local view = SwitchCountryDialogView.create();
	SwitchCountryDialogView.m_bagid = bagid
	SwitchCountryDialogView.m_item = item
	
	view:loadCCBI();
	SwitchCountryDialogView.m_selfview = view;
	
	GetMainMenu():GetModelLayer():AddDialog(view, 3);
end


