require "LuaSubView.lua"
require "RLRequest"
require "LuaXml.lua"
require "util/localizable"

moraGetPackDialog=class(
		"moraGetPackDialog",
    function()
        return CCLayer:create() 
    end
)

moraGetPackDialog.m_touchPriority = kCCMenuHandlerPriority-1;

function moraGetPackDialog_onTouch(event, x, y)
     if event == "began" then   
        return true
    end
end

function moraGetPackDialog:create()
	local view = moraGetPackDialog.new();
	return view;
end

function moraGetPackDialog:loadCCBI()
	local view = LuaSubView:create();	
	local win = CCDirector:sharedDirector():getWinSize();
	view:LoadCCBI("dlg_ui/MoraPackDialog.ccbi",CCSize(768,win.height));
	self:addChild(view)
	view:setPosition(CCPoint(win.width / 2, win.height / 2));
	self.m_dlgview = view;
end

function moraGetPackDialog:initUI()	
	self:loadCCBI()
	self:BindControl();
	
	tolua.cast(self.m_dlgview:getNode("label_content"),"CCLabelTTF"):setString(self.m_moradesc)
end

function moraGetPackDialog:BindControl()
	self:setTouchEnabled(true)
	self:registerScriptTouchHandler(moraGetPackDialog_onTouch,false,kCCMenuHandlerPriority-1,true)
	self:setTouchMode(0) 
	
	self.m_btn_get = tolua.cast(self.m_dlgview:getNode("btnGet"), "CCControlButton")
	self.m_btn_cancel = tolua.cast(self.m_dlgview:getNode("btnClose"), "CCControlButton")
	self.m_btn_close = tolua.cast(self.m_dlgview:getNode("btnDialogClose"), "CCControlButton")
	
	-- 初始化按钮
	self.m_btn_get:setTouchPriority(moraGetPackDialog.m_touchPriority);
	self.m_dlgview:handleButtonEvent(self.m_btn_get, function(button, event)
		self:GetPack();
		return nil
	end, CCControlEventTouchUpInside)
	
	self.m_btn_cancel:setTouchPriority(moraGetPackDialog.m_touchPriority);
	self.m_dlgview:handleButtonEvent(self.m_btn_cancel, function(button, event)
		self:CloseView();
		return nil
	end, CCControlEventTouchUpInside)
	
	self.m_btn_close:setTouchPriority(moraGetPackDialog.m_touchPriority);
	self.m_dlgview:handleButtonEvent(self.m_btn_close, function(button, event)
		self:CloseView();
		return nil
	end, CCControlEventTouchUpInside)
end

function moraGetPackDialog:CloseView()    
	CSoundMgr:instance():PlayEffect(SOUND_BUTTON)
    moraGetPackDialog.m_selfview:removeFromParentAndCleanup(true);
end

function moraGetPackDialog:GetPack()
	CSoundMgr:instance():PlayEffect(SOUND_BUTTON)
	self.m_moraview:exchangePack(self.m_moraExchangeId)
	moraGetPackDialog.m_selfview:removeFromParentAndCleanup(true);
end

function moraGetPackDialog:setMoraView(view)
	self.m_moraview = view
end

function moraGetPackDialog:setDescription(desc)
	self.m_moradesc = desc
	return nil
end

function moraGetPackDialog:setExchangeId(index)
	self.m_moraExchangeId = index
end


