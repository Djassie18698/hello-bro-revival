require "LuaSubView.lua"
require "RLRequest"
require "LuaXml.lua"
require "util/localizable"

moraKillConfirmDlg=class(
		"moraKillConfirmDlg",
    function()
        return CCLayer:create() 
    end
)

moraKillConfirmDlg.m_touchPriority = kCCMenuHandlerPriority-1;

function moraKillConfirmDlg_onTouch(event, x, y)
     if event == "began" then   
        return true
    end
end

function moraKillConfirmDlg:create()
	local view = moraKillConfirmDlg.new();
	moraKillConfirmDlg.m_selfview = view;
	return view;
end

function moraKillConfirmDlg:loadCCBI()
	local view = LuaSubView:create();	
	local win = CCDirector:sharedDirector():getWinSize();
	view:LoadCCBI("dlg_ui/MoraConfirmDlg.ccbi",CCSize(768,win.height));
	self:addChild(view)
	view:setPosition(CCPoint(win.width / 2, win.height / 2));
	self.m_dlgview = view;
end

function moraKillConfirmDlg:initUI()	
	self:loadCCBI()
	self:BindControl();
end
function moraKillConfirmDlg_onTouch(event, x, y)
     if event == "began" then   
        return true
    end
end
function moraKillConfirmDlg:BindControl()
	self:setTouchEnabled(true)
	self:registerScriptTouchHandler(moraKillConfirmDlg_onTouch,false,moraKillConfirmDlg.m_touchPriority,true)
	self:setTouchMode(0) 
	
	self.m_btn_confirm = tolua.cast(self.m_dlgview:getNode("btn_confirm"), "CCControlButton")
	self.m_btn_cancel = tolua.cast(self.m_dlgview:getNode("btn_close"), "CCControlButton")
	
	-- 初始化按钮
	self.m_btn_confirm:setTouchPriority(moraKillConfirmDlg.m_touchPriority);
	self.m_dlgview:handleButtonEvent(self.m_btn_confirm, function(button, event)
		self:onConfirm();
		return nil
	end, CCControlEventTouchUpInside)
	
	self.m_btn_cancel:setTouchPriority(moraKillConfirmDlg.m_touchPriority);
	self.m_dlgview:handleButtonEvent(self.m_btn_cancel, function(button, event)
		self:CloseView();
		return nil
	end, CCControlEventTouchUpInside)	
end

function moraKillConfirmDlg:CloseView()    	
	moraKillConfirmDlg.m_selfview:removeFromParentAndCleanup(true);
end
function moraKillConfirmDlg:setConfirmCallback(callback)
	self.m_callback = callback;
end
function moraKillConfirmDlg:onConfirm()
	self.m_callback();
	moraKillConfirmDlg.m_selfview:removeFromParentAndCleanup(true);
end
function moraKillConfirmDlg:setKillPrice(price)
	self.m_price = price;	
	tolua.cast(self.m_dlgview:getNode("label_killprice"),"CCLabelBMFont"):setString(""..price);
end


