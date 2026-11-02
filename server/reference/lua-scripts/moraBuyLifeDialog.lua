require "LuaSubView.lua"
require "RLRequest"
require "LuaXml.lua"
require "util/localizable"

moreBuyLifeDialog=class(
		"moreBuyLifeDialog",
    function()
        return CCLayer:create() 
    end
)

function moreBuyLifeDialog_onTouch(event, x, y)
     if event == "began" then   
        return true
    end
end

moreBuyLifeDialog.m_touchPriority = kCCMenuHandlerPriority-1;

function moreBuyLifeDialog:create()
	local view = moreBuyLifeDialog.new();
	return view;
end

function moreBuyLifeDialog:loadCCBI()
	local view = LuaSubView:create();	
	local win = CCDirector:sharedDirector():getWinSize();
	view:LoadCCBI("dlg_ui/MoraBuyLifeView.ccbi",CCSize(768,win.height));
	self:addChild(view)
	view:setPosition(CCPoint(win.width / 2, win.height / 2));
	self.m_dlgview = view;
end

function moreBuyLifeDialog:initUI()	
	self:loadCCBI()
	self:BindControl();
	
	tolua.cast(self.m_dlgview:getNode("label_onelife_cost"),"CCLabelBMFont"):setString(self.m_oneLifeCost)
	tolua.cast(self.m_dlgview:getNode("label_fulllife_cost"),"CCLabelBMFont"):setString(self.m_fullLifeCost)
	tolua.cast(self.m_dlgview:getNode("label_mygold"),"CCLabelBMFont"):setString(CPlayerDataMgr:instance():GetPlayerInfoData().m_gold)
end

function moreBuyLifeDialog:BindControl()
	self:setTouchEnabled(true)
	self:registerScriptTouchHandler(moreBuyLifeDialog_onTouch,false,kCCMenuHandlerPriority-1,true)
	self:setTouchMode(0) 
	
	self.m_btn_fullbuy = tolua.cast(self.m_dlgview:getNode("btn_fullbuy"), "CCControlButton")
	self.m_btn_partbuy = tolua.cast(self.m_dlgview:getNode("btn_partbuy"), "CCControlButton")
	self.m_btn_close = tolua.cast(self.m_dlgview:getNode("closeButton"), "CCControlButton")
	
	-- 初始化按钮
	self.m_btn_fullbuy:setTouchPriority(moreBuyLifeDialog.m_touchPriority);
	self.m_dlgview:handleButtonEvent(self.m_btn_fullbuy, function(button, event)
		self:FullBuy();
		return nil
	end, CCControlEventTouchUpInside)
	
	self.m_btn_partbuy:setTouchPriority(moreBuyLifeDialog.m_touchPriority);
	self.m_dlgview:handleButtonEvent(self.m_btn_partbuy, function(button, event)
		self:PartBuy();
		return nil
	end, CCControlEventTouchUpInside)
	
	self.m_btn_close:setTouchPriority(moreBuyLifeDialog.m_touchPriority);
	self.m_dlgview:handleButtonEvent(self.m_btn_close, function(button, event)
		self:CloseView();
		return nil
	end, CCControlEventTouchUpInside)
end

function moreBuyLifeDialog:CloseView()    
	CSoundMgr:instance():PlayEffect(SOUND_BUTTON)
    moreBuyLifeDialog.m_selfview:removeFromParentAndCleanup(true);
end

function moreBuyLifeDialog:FullBuy()
	CSoundMgr:instance():PlayEffect(SOUND_BUTTON)
	self.m_moraview:buyFullLife()
	moreBuyLifeDialog.m_selfview:removeFromParentAndCleanup(true);
end

function moreBuyLifeDialog:PartBuy()
	CSoundMgr:instance():PlayEffect(SOUND_BUTTON)
	self.m_moraview:buyOneLife()
	moreBuyLifeDialog.m_selfview:removeFromParentAndCleanup(true);
end

function moreBuyLifeDialog:setData(oneLifeCost, fullLifeCost)
	self.m_oneLifeCost = oneLifeCost
	self.m_fullLifeCost = fullLifeCost
end

function moreBuyLifeDialog:setMoraView(view)
	self.m_moraview = view
end


