require "LuaSubView.lua"
require "RLRequest"
require "LuaXml.lua"
require "util/localizable"

bossRewardRuleDialogView=class(
		"bossRewardRuleDialogView",
    function()
        return CCLayer:create() 
    end
)

function bossRewardRuleDialogView_onTouch(event, x, y)
     if event == "began" then   
        return true
    end
end

bossRewardRuleDialogView.m_touchPriority = kCCMenuHandlerPriority-1;

function bossRewardRuleDialogView:create()
	local view = bossRewardRuleDialogView.new();
	return view;
end

function bossRewardRuleDialogView:loadCCBI()
	local view = LuaSubView:create();	
	local win = CCDirector:sharedDirector():getWinSize();
	view:LoadCCBI("dlg_ui/BossExchangeDialogView.ccbi",CCSize(768,win.height));
	self:addChild(view)
	view:setPosition(CCPoint(win.width / 2, win.height / 2));
	self.m_dlgview = view;
end

function bossRewardRuleDialogView:initUI()	
	self:loadCCBI()
	self:BindControl();
	
	tolua.cast(self.m_dlgview:getNode("label_damage"),"CCLabelTTF"):setString(self.m_totalDamage)

	--玩法说明修改_litao_2014.8.2
	local str = "1. "..string.format(localizable.fightBoss_new_detail_desc_1, self.m_damageL1)
	--local str = "1. "..tostring(self.m_damageL1)..localizable.fightBoss_hurt_desc_2..tostring(self.m_repL1)..localizable.fightBoss_prestige_desc
	tolua.cast(self.m_dlgview:getNode("labelDescription1"),"CCLabelTTF"):setString(str)
	
	local str = "2. "..string.format(localizable.fightBoss_new_detail_desc_2, self.m_damageL2)
	--local str = "2. "..tostring(self.m_damageL2)..localizable.fightBoss_hurt_desc_2..tostring(self.m_repL2)..localizable.fightBoss_prestige_desc
	tolua.cast(self.m_dlgview:getNode("labelDescription2"),"CCLabelTTF"):setString(str)
	
	--local str = "3. "..tostring(self.m_damageL3)..localizable.fightBoss_hurt_desc_2..tostring(self.m_repL3)..localizable.fightBoss_prestige_desc
	--tolua.cast(self.m_dlgview:getNode("labelDescription3"),"CCLabelTTF"):setString(str)
	tolua.cast(self.m_dlgview:getNode("labelDescription3"),"CCLabelTTF"):setVisible(false)
end

function bossRewardRuleDialogView:BindControl()
	self:setTouchEnabled(true)
	self:registerScriptTouchHandler(bossRewardRuleDialogView_onTouch,false,kCCMenuHandlerPriority-1,true)
	self:setTouchMode(0) 
	
	self.m_leftbtn = tolua.cast(self.m_dlgview:getNode("leftButton"), "CCControlButton")
	self.m_rightbtn = tolua.cast(self.m_dlgview:getNode("rightButton"), "CCControlButton")
	self.m_closebtn = tolua.cast(self.m_dlgview:getNode("closeButton"), "CCControlButton")
	
	-- 初始化按钮
	self.m_leftbtn:setTouchPriority(bossRewardRuleDialogView.m_touchPriority);
	self.m_dlgview:handleButtonEvent(self.m_leftbtn, function(button, event)
		self:getReward();
		return nil
	end, CCControlEventTouchUpInside)
	
	self.m_rightbtn:setTouchPriority(bossRewardRuleDialogView.m_touchPriority);
	self.m_dlgview:handleButtonEvent(self.m_rightbtn, function(button, event)
		self:CloseView();
		return nil
	end, CCControlEventTouchUpInside)
	
	self.m_closebtn:setTouchPriority(bossRewardRuleDialogView.m_touchPriority);
	self.m_dlgview:handleButtonEvent(self.m_closebtn, function(button, event)
		self:CloseView();
		return nil
	end, CCControlEventTouchUpInside)
end

function bossRewardRuleDialogView:getReward()
	--[[if self.m_heroDlgView ~= nil then
		self.m_heroDlgView:getLevelReward()
	end]]
	CSoundMgr:instance():PlayEffect(SOUND_BUTTON)
    bossRewardRuleDialogView.m_selfview:removeFromParentAndCleanup(true);
end

function bossRewardRuleDialogView:setData(totalDamage,damageL1,repL1,damageL2,repL2,damageL3,repL3,dlgView)
	self.m_totalDamage = totalDamage
	self.m_damageL1 = damageL1
	self.m_repL1 = repL1
	self.m_damageL2 = damageL2
	self.m_repL2 = repL2
	self.m_damageL3 = damageL3
	self.m_repL3 = repL3
	self.m_heroDlgView = dlgView
end

function bossRewardRuleDialogView:CloseView()    
	CSoundMgr:instance():PlayEffect(SOUND_BUTTON)
    bossRewardRuleDialogView.m_selfview:removeFromParentAndCleanup(true);
end



