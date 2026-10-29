require "LuaSubView.lua"
require "RLRequest"
require "LuaXml.lua"
require "util/localizable"

CommonDialogView=class(
		"CommonDialogView",
    function()
        return CCLayer:create()
    end
)

function CommonDialogView:create()
	local view = CommonDialogView.new();
	return view;
end

CommonDialogView.title = ""
CommonDialogView.description = ""
CommonDialogView.m_btnList = {}

local cancelHandler = nil
local confirmHandler = nil

function CommonDialogView:loadCCBI(iPriority, ccbName)

	local function CCLayerTouch(event, x, y)
		if event == "began" then
			return true
		end
	end
	local view = LuaSubView:create();
	local priority = iPriority or (kCCMenuHandlerPriority-2)
	view:setTouchEnabled(true)
	view:registerScriptTouchHandler(CCLayerTouch, false, priority, true)

	local win = CCDirector:sharedDirector():getWinSize();
	if ccbName == nil then
		view:LoadCCBI("dlg_ui/CommonDialogView.ccbi",CCSize(768,win.height));
	else
		view:LoadCCBI("dlg_ui/" ..ccbName .. ".ccbi",CCSize(768,win.height));
	end
	self:addChild(view)
	view:setPosition(CCPoint(win.width / 2, win.height / 2));
	CommonDialogView.m_dlgview = view;
end

function CommonDialogView:SetLabelText(label, txt, bmfont)
    local labelText = tolua.cast(label, "CCLabelTTF")

	if bmfont == true then
		label:setLineBreakWithoutSpace(true)
		label:setString(txt)
	else
		label:setString(txt)
	end
end

function CommonDialogView:initUI(iPriority)
	if self.title ~= "" then
		self:SetLabelText(CommonDialogView.m_dlgview:getNode("labelTitle"), self.title, false)
	end

	if self.description ~= "" then
		self:SetLabelText(CommonDialogView.m_dlgview:getNode("labelDescription"), self.description, false)
	end

	CommonDialogView:BindControl(iPriority);
	self:setTouchEnabled(true)
	self:registerScriptTouchHandler(CommonDialogView_onTouch,false,kCCMenuHandlerPriority-1,true)
	self:setTouchMode(0)
end

function CommonDialogView:updateLeftBtnText(text)
	local leftBtn = tolua.cast(CommonDialogView.m_dlgview:getNode("leftButton"), "CCControlButton")
	leftBtn:setTitleForState(text, CCControlStateNormal)
	leftBtn:setTitleForState(text, CCControlStateHighlighted)
	leftBtn:setTitleForState(text, CCControlStateDisabled)
end

function CommonDialogView_onTouch(event, x, y)
    if event == "began" then
        for i = 1, #CommonDialogView.m_btnList do
            local rect = tolua.cast(CommonDialogView.m_btnList[i], "CCControlButton"):boundingBox()
            rect.origin = CommonDialogView.m_btnList[i]:getParent():convertToWorldSpace(rect.origin)
        	if(rect:containsPoint(CCPoint(x,y)))then
    			tolua.cast(CommonDialogView.m_btnList[i], "CCControlButton"):setHighlighted(true);
    		end
        end

        return true
    end
    if event == "moved" then
    	for i = 1, #CommonDialogView.m_btnList do
    	    local rect = tolua.cast(CommonDialogView.m_btnList[i], "CCControlButton"):boundingBox()
    	    rect.origin = CommonDialogView.m_btnList[i]:getParent():convertToWorldSpace(rect.origin)
        	if(rect:containsPoint(CCPoint(x,y)))then
    			tolua.cast(CommonDialogView.m_btnList[i], "CCControlButton"):setHighlighted(true);
    		else
    			tolua.cast(CommonDialogView.m_btnList[i], "CCControlButton"):setHighlighted(false);
    		end
        end
    end
    if event == "ended" then
    	for i = 1, #CommonDialogView.m_btnList do
    	    local rect = tolua.cast(CommonDialogView.m_btnList[i], "CCControlButton"):boundingBox()
    	    rect.origin = CommonDialogView.m_btnList[i]:getParent():convertToWorldSpace(rect.origin)
        	if(rect:containsPoint(CCPoint(x,y)))then
    			tolua.cast(CommonDialogView.m_btnList[i], "CCControlButton"):setHighlighted(false);
    			CommonDialogView.m_btnList[i]:sendActionsForControlEvents(CCControlEventTouchUpInside);
    		else
    			tolua.cast(CommonDialogView.m_btnList[i], "CCControlButton"):setHighlighted(false);
    		end
        end
    end
end

function CommonDialogView:AddBtnToList(index, btn)
	self.m_btnList[index] = btn
end

function CommonDialogView:BindControl(iPriority)
	CommonDialogView:AddBtnToList(1, tolua.cast(CommonDialogView.m_dlgview:getNode("closeButton"), "CCControlButton"))
	CommonDialogView:AddBtnToList(2, tolua.cast(CommonDialogView.m_dlgview:getNode("leftButton"), "CCControlButton"))
	CommonDialogView:AddBtnToList(3, tolua.cast(CommonDialogView.m_dlgview:getNode("rightButton"), "CCControlButton"))

	local priority = iPriority or (kCCMenuHandlerPriority - 3)

	self.m_btnList[1]:setTouchPriority(priority)
	self.m_btnList[1]:setTouchEnabled(true)
		-- 初始化按钮
	CommonDialogView.m_dlgview:handleButtonEvent(self.m_btnList[1], function(button, event)
		self:Cancel();
		return nil
	end, CCControlEventTouchUpInside)

	self.m_btnList[2]:setTouchPriority(priority)
	self.m_btnList[1]:setTouchEnabled(true)
	CommonDialogView.m_dlgview:handleButtonEvent(self.m_btnList[2], function(button, event)
		self:Confirm();
		return nil
	end, CCControlEventTouchUpInside)

	self.m_btnList[3]:setTouchPriority(priority)
	self.m_btnList[3]:setTouchEnabled(true)
	CommonDialogView.m_dlgview:handleButtonEvent(self.m_btnList[3], function(button, event)
		self:Cancel();
		return nil
	end, CCControlEventTouchUpInside)
end

function CommonDialogView:Cancel()
	CSoundMgr:instance():PlayEffect(SOUND_BUTTON)

    if cancelHandler ~= nil then
		cancelHandler()
		cancelHandler = nil
	end
    CommonDialogView.m_selfview:removeFromParentAndCleanup(true);
end

function CommonDialogView:Confirm()
	CSoundMgr:instance():PlayEffect(SOUND_BUTTON)

    if confirmHandler ~= nil then
		confirmHandler()
		confirmHandler = nil
	end
	CommonDialogView.m_selfview:removeFromParentAndCleanup(true);
end

function CommonDialogView:SetCancelHandler(handler)
	cancelHandler = handler
end

function CommonDialogView:SetConfirmHandler(handler)
	confirmHandler = handler
end

function CommonDialogView:SetTitle(txt)
	self.title = txt
end

function CommonDialogView:SetDescription(txt)
	self.description = txt
end

--[[
function CreateCommonDialogView()
	local dlg = CommonDialogView.create()
	CommonDialogView.m_selfview = dlg;
	dlg:SetTitle("测试标题")
	dlg:SetDescription("测试内容")
	dlg:loadCCBI();
	dlg:SetConfirmHandler(m_selfview.freshTableData)
	dlg:initUI()
	GetMainMenu():GetModelLayer():AddDialog(dlg, 3);
end]]


