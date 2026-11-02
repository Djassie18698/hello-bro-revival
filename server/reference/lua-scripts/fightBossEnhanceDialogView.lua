require "LuaSubView.lua"
require "RLRequest"
require "LuaXml.lua"
require "fightBossRankCellView.lua"
require "util/localizable"

fightBossEnhanceDialogView=class(
		"fightBossEnhanceDialogView",
    function()
        return CCLayer:create() 
    end
)

fightBossEnhanceDialogView.m_touchPriority = kCCMenuHandlerPriority-1;

function fightBossEnhanceDialogView_onTouch(event, x, y)
     if event == "began" then   
        return true
    end
end

function fightBossEnhanceDialogView:create()
	local view = fightBossEnhanceDialogView.new();
	return view;
end

function fightBossEnhanceDialogView:loadCCBI()
	local view = LuaSubView:create();	
	local win = CCDirector:sharedDirector():getWinSize();
	view:LoadCCBI("activity/FightBossEnhanceDialogView.ccbi",CCSize(768,win.height));
	self:addChild(view)
	view:setPosition(CCPoint(win.width / 2, win.height / 2));
	self.m_dlgview = view;
end

function fightBossEnhanceDialogView:initUI()		
	self:loadCCBI()
	self:BindControl()
	
	tolua.cast(self.m_dlgview:getNode("label_silver_up_cost"), "CCLabelBMFont"):setString(self.m_silver_cost)
	tolua.cast(self.m_dlgview:getNode("label_gold_up_cost"), "CCLabelBMFont"):setString(self.m_gold_cost)
	tolua.cast(self.m_dlgview:getNode("label_silver_up_value"), "CCLabelTTF"):setString(self.m_silver_up_value.."%")
	tolua.cast(self.m_dlgview:getNode("label_gold_up_value"), "CCLabelTTF"):setString(self.m_gold_up_value.."%")
	tolua.cast(self.m_dlgview:getNode("label_total_up"), "CCLabelBMFont"):setString(self.m_total_up.."%")
end

function fightBossEnhanceDialogView:setData(silverCost, goldCost, silverUp, silverMax, goldUp, goldMax, totalUp, bossView)
	self.m_silver_cost = silverCost
	self.m_gold_cost = goldCost
	self.m_silver_up_value = silverUp
	self.m_silver_up_max = silverMax
	self.m_gold_up_value = goldUp
	self.m_gold_up_max = goldMax
	self.m_total_up = totalUp
	self.m_boss_view = bossView
	self.m_up_type = 1
	return nil
end

function fightBossEnhanceDialogView:BindControl()
	fightBossEnhanceDialogView.m_selfview:setTouchEnabled(true)
	fightBossEnhanceDialogView.m_selfview:registerScriptTouchHandler(fightBossEnhanceDialogView_onTouch,false,kCCMenuHandlerPriority-1,true)
	fightBossEnhanceDialogView.m_selfview:setTouchMode(0) 
	
	self.m_btn_silver_up = tolua.cast(self.m_dlgview:getNode("btn_silver_up"), "CCControlButton")
	self.m_btn_gold_up = tolua.cast(self.m_dlgview:getNode("btn_gold_up"), "CCControlButton")
	self.m_btn_right = tolua.cast(self.m_dlgview:getNode("rightButton"), "CCControlButton")
	self.m_btn_close = tolua.cast(self.m_dlgview:getNode("closeButton"), "CCControlButton")
	
	-- 初始化按钮
	self.m_btn_silver_up:setTouchPriority(fightBossEnhanceDialogView.m_touchPriority);
	self.m_dlgview:handleButtonEvent(self.m_btn_silver_up, function(button, event)
		self:ClickSilverupTab();
		return nil
	end, CCControlEventTouchUpInside)
	
	self.m_btn_gold_up:setTouchPriority(fightBossEnhanceDialogView.m_touchPriority);
	self.m_dlgview:handleButtonEvent(self.m_btn_gold_up, function(button, event)
		self:ClickGoldupTab();
		return nil
	end, CCControlEventTouchUpInside)
	
	self.m_btn_close:setTouchPriority(fightBossEnhanceDialogView.m_touchPriority);
	self.m_dlgview:handleButtonEvent(self.m_btn_close, function(button, event)
		self:CloseView();
		return nil
	end, CCControlEventTouchUpInside)
	
	self.m_btn_right:setTouchPriority(fightBossEnhanceDialogView.m_touchPriority);
	self.m_dlgview:handleButtonEvent(self.m_btn_right, function(button, event)
		self:CloseView();
		return nil
	end, CCControlEventTouchUpInside)
end

function fightBossEnhanceDialogView:CloseView()    
	fightBossEnhanceDialogView.m_selfview:removeFromParentAndCleanup(true);
end

function fightBossEnhanceDialogView:ClickSilverupTab()
	self.m_up_type = 1
	self:doAttackUp(self.m_up_type)
end

function fightBossEnhanceDialogView:ClickGoldupTab()
	self.m_up_type = 2
	self:doAttackUp(self.m_up_type)
end

function fightBossEnhanceDialogView:doAttackUp(attacktype)
	local playerMgr = CPlayerDataMgr:instance()
	local playerData = playerMgr:GetPlayerInfoData()
	local uid = playerData.m_uid
	local urlpath = GetUrlNormalHeader(uid,9,"rl_w_xiao")
	urlpath = AddData(urlpath, "AddAttackType", attacktype)
	GetMainMenu():ShowUnvisibleLoadingDlg();
	CCHttpRequest:openWithUserData(urlpath, kHttpPost, p, "query=param1&other=params"):sendWithHandler(
	function(res, hnd)
		local p = res:getHttpRequest():getUserData()
		local resData = res:getResponseData();			
		local code = res:getResponseCode()
		local xfile = xml.parse(resData)
		local item = xfile:find("RENLONG")
		if item == nil then
			GetMainMenu():CloseLoadding();
			return nil
		end
		local retcode = item.code
		if retcode == "0" then			
			local preview = item:find("preview")
			if preview ~= nil then
				local addDetal = tonumber(preview.addval)
				local uptotal = tonumber(preview.addall)
				
				self.m_total_up = uptotal
				tolua.cast(self.m_dlgview:getNode("label_total_up"), "CCLabelBMFont"):setString(self.m_total_up.."%")
				
				if self.m_boss_view ~= nil then
					self.m_boss_view:setTotalUp(uptotal)
				end
				
				local goodluck = false
				if self.m_up_type == 1 then
					if addDetal == self.m_silver_up_max then
						goodluck = true
					end
				else
					if addDetal == self.m_gold_up_max then
						goodluck = true
					end
				end
				
				self:PlayEnhanceAnimView(addDetal, goodluck)
			end
			GetMainMenu():CloseLoadding();				
		else
			--GetMainMenu():ShowTextTip(text.text_config[tonumber(retcode)].description,-1);
			GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
			GetMainMenu():CloseLoadding();
		end
	end)
end

function fightBossEnhanceDialogView:PlayEnhanceAnimView(upvalue, goodluck)
	local animView = PlayOnceAnimLayer:create()
	if animView == nil then
		return nil
	end
	animView:initUI("activity/FightBossEnhanceShowView.ccbi",CCSize(768,1024), 1)
	local win = CCDirector:sharedDirector():getWinSize();
	tolua.cast(animView:getNode("label_defense_value"), "CCLabelBMFont"):setString("+"..upvalue.."%")
	tolua.cast(animView:getNode("label_attack_value"), "CCLabelBMFont"):setString("+"..upvalue.."%")
	if goodluck == true then
		tolua.cast(animView:getNode("node_goodluck"), "CCNode"):setVisible(true)
	else
		tolua.cast(animView:getNode("node_goodluck"), "CCNode"):setVisible(false)
	end
	tolua.cast(self.m_dlgview:getNode("node_animlayer"), "CCNode"):addChild(animView, 10)
end




