require "LuaSubView.lua"
require "RLRequest"
require "LuaXml.lua"
require "util/localizable"

moraDetailDialogView=class(
		"moraDetailDialogView",
    function()
        return CCLayer:create() 
    end
)

function moraDetailDialogView_onTouch(event, x, y)
     if event == "began" then   
        return true
    end
end

moraDetailDialogView.m_touchPriority = kCCMenuHandlerPriority-1;

function moraDetailDialogView:create()
	local view = moraDetailDialogView.new();
	return view;
end

function moraDetailDialogView:loadCCBI()
	local view = LuaSubView:create();	
	local win = CCDirector:sharedDirector():getWinSize();
	view:LoadCCBI("dlg_ui/MoraDetailDialogView.ccbi",CCSize(768,win.height));
	self:addChild(view)
	view:setPosition(CCPoint(win.width / 2, win.height / 2));
	self.m_dlgview = view;
end

function moraDetailDialogView:initUI()	
	self:loadCCBI()
	self:BindControl();
end

function moraDetailDialogView:BindControl()
	self:setTouchEnabled(true)
	self:registerScriptTouchHandler(moraDetailDialogView_onTouch,false,kCCMenuHandlerPriority-1,true)
	self:setTouchMode(0) 
	
	self.m_leftbtn = tolua.cast(self.m_dlgview:getNode("leftButton"), "CCControlButton")
	self.m_rightbtn = tolua.cast(self.m_dlgview:getNode("rightButton"), "CCControlButton")
	self.m_closebtn = tolua.cast(self.m_dlgview:getNode("closeButton"), "CCControlButton")
	
	-- 初始化按钮
	self.m_leftbtn:setTouchPriority(moreBuyLifeDialog.m_touchPriority);
	self.m_dlgview:handleButtonEvent(self.m_leftbtn, function(button, event)
		self:CloseView();
		return nil
	end, CCControlEventTouchUpInside)
	
	self.m_rightbtn:setTouchPriority(moreBuyLifeDialog.m_touchPriority);
	self.m_dlgview:handleButtonEvent(self.m_rightbtn, function(button, event)
		self:CloseView();
		return nil
	end, CCControlEventTouchUpInside)
	
	self.m_closebtn:setTouchPriority(moreBuyLifeDialog.m_touchPriority);
	self.m_dlgview:handleButtonEvent(self.m_closebtn, function(button, event)
		self:CloseView();
		return nil
	end, CCControlEventTouchUpInside)
end

function moraDetailDialogView:CloseView()    
	CSoundMgr:instance():PlayEffect(SOUND_BUTTON)
    moraDetailDialogView.m_selfview:removeFromParentAndCleanup(true);
end



