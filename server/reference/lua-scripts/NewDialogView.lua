-- 新的对话框
-- liyongkang
-- 2015-10-27
---------------------------------------------
module("NewDialogView", package.seeall)
baseClass(layer_base_t, NewDialogView)

function init(self)
    self.playerMgr_ = CPlayerDataMgr:instance()
    self.playerData_ = self.playerMgr_:GetPlayerInfoData()

    local winSize = CCDirector:sharedDirector():getWinSize()
    -- Load res
    local ccbiAttrTable = { name = "dlg_ui/NewDialogView.ccbi", size = CCSizeMake(768, winSize.height) }

    layer_base_t.init(self, true, ccbiAttrTable)

    self.confirmHandler = nil
    self.cancelHandler = nil

    self:init_ui()
    self:init_binding_event()
end


function init_ui(self)
    if self.proxy_ ~= nil then
        self.button_close = tolua.cast(self.proxy_:getNode("button_close"), "CCControlButton")
        self.button_left = tolua.cast(self.proxy_:getNode("button_left"), "CCControlButton")
        self.button_right = tolua.cast(self.proxy_:getNode("button_right"), "CCControlButton")

        self.label_content = tolua.cast(self.proxy_:getNode("lable_content"), "CCLabelTTF")
        self.label_title = tolua.cast(self.proxy_:getNode("labelTitle"), "CCLabelTTF")
    end
end

function setRightButtonLabel(self, text)
    self.button_right:setTitleForState(text, CCControlStateNormal);
    self.button_right:setTitleForState(text, CCControlStateHighlighted);
    self.button_right:setTitleForState(text, CCControlStateSelected);
end

function setLeftButtonLabel(self, text)
    self.button_left:setTitleForState(text, CCControlStateNormal);
    self.button_left:setTitleForState(text, CCControlStateHighlighted);
    self.button_left:setTitleForState(text, CCControlStateSelected);
end

function setContentText(self, text)
    self.label_content:setString(text)
end

function setTitleText(self, text)
    self.label_title:setString(text)
end

function init_binding_event(self)
    if self.proxy_ ~= nil then
        -- 屏蔽下层的触摸
        local function CCLayerTouch(event)
            if event == "began" then
                return true
            end
        end
        self.node_:setTouchEnabled(true)
        self.node_:registerScriptTouchHandler(CCLayerTouch, false, kCCMenuHandlerPriority - 1, true)

        local function onBtnClose(btn)
            cclog("onBtnClose")
            self.node_:removeFromParentAndCleanup(true)
        end

        local function onBtnLeft(btn)
            cclog("onBtnLeft")
           if self.confirmHandler ~= nil then
                self.confirmHandler()
                self.confirmHandler = nil
            end
            self.node_:removeFromParentAndCleanup(true)
        end;

        local function onBtnRight(btn)
            

             if self.cancelHandler ~= nil then
                self.cancelHandler()
                self.cancelHandler = nil
            end
            self.node_:removeFromParentAndCleanup(true)
        end

        self.button_close:setTouchPriority(kCCMenuHandlerPriority - 1)
        self.proxy_:handleButtonEvent(self.button_close, function(button, event)
            onBtnClose(button)
            return nil
        end , CCControlEventTouchUpInside)

        self.button_left:setTouchPriority(kCCMenuHandlerPriority - 1)
        self.proxy_:handleButtonEvent(self.button_left, function(button, event)
            onBtnLeft(button)
            return nil
        end , CCControlEventTouchUpInside)

        self.button_right:setTouchPriority(kCCMenuHandlerPriority - 1)
        self.proxy_:handleButtonEvent(self.button_right, function(button, event)
            onBtnRight(button_right)
            return nil
        end , CCControlEventTouchUpInside)
    end
end

function setConfirmHandler(self, handler)
    self.confirmHandler = handler
end

function setCancelHandler(self, handler)
    self.cancelHandler = handler
end


function onNodeCleanup(self)
    -- cclog("onNodeCleanup")
    if self.proxy_ then
        self.proxy_:release()
    end
    layer_base_t.onNodeCleanup(self)
end



--[[
 local monthLayer = createObj(NewDialogView)
            local size1 = GetMainMenu():GetModelLayer():getContentSize()
            monthLayer:setConfirmHandler(
                function ()
                    cclog("SetConfirmHandler111")
                    local monthLayer = createObj(NewDialogView)
                    local size1 = GetMainMenu():GetModelLayer():getContentSize()
                    monthLayer:setConfirmHandler(
                        function ()
                            cclog("SetConfirmHandler2222")
                     end)
                    monthLayer.node_:setAnchorPoint(ccp(0.5, 0.5))
                    monthLayer.node_:setPosition(size1.width / 2, size1.height / 2)
                    GetMainMenu():GetModelLayer():addChild(monthLayer.node_)
             end)
            monthLayer:setRightButtonLabel("右按钮")
            monthLayer:setLeftButtonLabel("左按钮")
            monthLayer:setTitleText("标题")
            monthLayer:setContentText("左按钮左按钮左按钮左按钮左按钮左按钮左按钮左按钮左按钮左按钮左按钮左按钮左按钮左按钮左按钮左按钮左按钮左按钮左按钮左按钮左按钮左按钮左按钮左按钮左按钮左按钮左按钮左按钮左按钮左按钮左按钮")
            monthLayer.node_:setAnchorPoint(ccp(0.5, 0.5))
            monthLayer.node_:setPosition(size1.width / 2, size1.height / 2)
            GetMainMenu():GetModelLayer():addChild(monthLayer.node_)

           


]]