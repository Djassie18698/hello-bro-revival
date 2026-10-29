require "LuaSubView.lua"
require "RLRequest"
require "LuaXml.lua"
require "util/localizable"

fightBossClearCdDialog=class(
		"fightBossClearCdDialog",
    function()
        return CCLayer:create() 
    end
)

fightBossClearCdDialog.m_touchPriority = kCCMenuHandlerPriority-1;

function fightBossClearCdDialog_onTouch(event, x, y)
     if event == "began" then   
        return true
    end
end

function fightBossClearCdDialog:create()
	local view = fightBossClearCdDialog.new();
	return view;
end

function fightBossClearCdDialog:loadCCBI()
	local view = LuaSubView:create();	
	local win = CCDirector:sharedDirector():getWinSize();
	view:LoadCCBI("activity/FightBossClearCd.ccbi",CCSize(768,win.height));
	self:addChild(view)
	view:setPosition(CCPoint(win.width / 2, win.height / 2));
	self.m_dlgview = view;
end

function fightBossClearCdDialog:initUI()		
	self:loadCCBI()
	self:BindControl()
	
	local function updateLeftTimeLabel(fDeltaTime)
		self.deltatime = self.deltatime + fDeltaTime
		if self.deltatime >= 1 then
			if self.m_resttime > 0 then
				self.m_resttime = self.m_resttime - 1
			end
			self:settimelabel(self.m_resttime)

			local intPart, floatPart = math.modf(self.deltatime)
			self.deltatime = floatPart
		end
	end
	
	self.deltatime = 0
	self.m_timelabel = tolua.cast(self.m_dlgview:getNode("label_time"), "CCLabelTTF")
	self.m_timelabel:scheduleUpdateWithPriorityLua(updateLeftTimeLabel, 0)
	
	self:settimelabel(self.m_resttime)
	local coststr = string.format(localizable.fightBoss_cost_clearCD_tip_desc, tostring(self.m_cost))
	tolua.cast(self.m_dlgview:getNode("label_desc"), "CCLabelTTF"):setString(coststr)
end

function fightBossClearCdDialog:settimelabel(_sec)
	local time = tools.convertTimeToTable(_sec)
	
	if _sec <= 0 then
		tolua.cast(self.m_dlgview:getNode("label_free_container"), "CCNode"):setVisible(true)
		tolua.cast(self.m_dlgview:getNode("label_cost_container"), "CCNode"):setVisible(false)
		return
	end

	local timestr
	timestr = string.format(localizable.mora_time_arg_2, time.m, time.s)
	tolua.cast(self.m_dlgview:getNode("label_free_container"), "CCNode"):setVisible(false)
	tolua.cast(self.m_dlgview:getNode("label_cost_container"), "CCNode"):setVisible(true)
	tolua.cast(self.m_dlgview:getNode("label_time"), "CCLabelTTF"):setString(timestr)
	return timestr
end

function fightBossClearCdDialog:setData(resttime, cost, bossView)
	self.m_resttime = resttime
	self.m_bossView = bossView
	self.m_cost = cost
	return nil
end

function fightBossClearCdDialog:BindControl()
	fightBossClearCdDialog.m_selfview:setTouchEnabled(true)
	fightBossClearCdDialog.m_selfview:registerScriptTouchHandler(fightBossClearCdDialog_onTouch,false,kCCMenuHandlerPriority-1,true)
	fightBossClearCdDialog.m_selfview:setTouchMode(0) 
	
	self.m_confirmBtn = tolua.cast(self.m_dlgview:getNode("leftButton"), "CCControlButton")
	self.m_cancelBtn = tolua.cast(self.m_dlgview:getNode("rightButton"), "CCControlButton")
	self.m_closeBtn = tolua.cast(self.m_dlgview:getNode("closeButton"), "CCControlButton")

	-- 初始化按钮
	self.m_confirmBtn:setTouchPriority(fightBossClearCdDialog.m_touchPriority);
	self.m_dlgview:handleButtonEvent(self.m_confirmBtn, function(button, event)
		self:ClickPayClearCd();
		return nil
	end, CCControlEventTouchUpInside)
	
	self.m_cancelBtn:setTouchPriority(fightBossClearCdDialog.m_touchPriority);
	self.m_dlgview:handleButtonEvent(self.m_cancelBtn, function(button, event)
		self:CloseView();
		return nil
	end, CCControlEventTouchUpInside)
	
	self.m_closeBtn:setTouchPriority(fightBossClearCdDialog.m_touchPriority);
	self.m_dlgview:handleButtonEvent(self.m_closeBtn, function(button, event)
		self:CloseView();
		return nil
	end, CCControlEventTouchUpInside)
end

function fightBossClearCdDialog:CloseView()    
	fightBossClearCdDialog.m_selfview:removeFromParentAndCleanup(true);
end

function fightBossClearCdDialog:ClickPayClearCd()	
	if self.m_resttime <= 0 then
		self.m_bossView:setFightResttime(0)
		self:CloseView()
		return
	end
	
	local playerMgr = CPlayerDataMgr:instance()
	local playerData = playerMgr:GetPlayerInfoData()
	
	if playerData.m_gold < self.m_cost then
		GetMainMenu():ShowTextTip(localizable.fightBoss_god_not_enough_desc,-1)
		--通用付费引导
		local prePayLayer = createObj(ui_commonPrePay)
		GetMainMenu():GetModelLayer():AddDialog(prePayLayer.node_, 3)
		return
	end
	
	local uid = playerData.m_uid
	local urlpath = GetUrlNormalHeader(uid,10,"rl_w_xiao")
	GetMainMenu():ShowLoadingDlg();
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
				local cost = tonumber(preview.cost)
				local gold = CPlayerDataMgr:instance():GetPlayerInfoData().m_gold - cost
				if gold < 0 then
					gold = 0
				end
				CPlayerDataMgr:instance():SetGold(gold)
				
				if self.m_bossView ~= nil then
					self.m_bossView:setFightResttime(0)
				end
				
				self:CloseView()
			end
			GetMainMenu():CloseLoadding();				
		else
			GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
			GetMainMenu():CloseLoadding();
		end
		
	end)
end



