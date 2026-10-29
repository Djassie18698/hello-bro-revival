--中忍考试规则
--liyongkang
--2015-10-26
---------------------------------------------
module("ui_ninjaTestDesc", package.seeall)
baseClass(layer_base_t, ui_ninjaTestDesc)

require("util/localizable")

function init(self)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	local winSize = CCDirector:sharedDirector():getWinSize()
	--Load res
	local ccbiAttrTable = {name="dlg_ui/NinjaTestDesc.ccbi", size=CCSizeMake(768, winSize.height)}
	
    layer_base_t.init(self, true, ccbiAttrTable)

	
    self:init_ui()
    self:init_binding_event()
end


function init_ui(self)
    if self.proxy_ ~= nil then
          self.button_close = tolua.cast(self.proxy_:getNode("closeButton"), "CCControlButton")
          self.button_left = tolua.cast(self.proxy_:getNode("leftButton"), "CCControlButton")
          self.label_content_01 =  tolua.cast(self.proxy_:getNode("label_content_01"), "CCLabelTTF")
          self.label_content_02 =  tolua.cast(self.proxy_:getNode("label_content_02"), "CCLabelTTF")
          self.label_content_03 =  tolua.cast(self.proxy_:getNode("label_content_03"), "CCLabelTTF")
          self.label_content_04 =  tolua.cast(self.proxy_:getNode("label_content_04"), "CCLabelTTF")

          self.label_content_01:setString(localizable.ui_ninjaTestDesc_text1)
          self.label_content_02:setString(localizable.ui_ninjaTestDesc_text2)
          self.label_content_03:setString(localizable.ui_ninjaTestDesc_text3)
          self.label_content_04:setString(localizable.ui_ninjaTestDesc_text4)


    end
end

function init_binding_event(self)
    if self.proxy_ ~= nil then
          --屏蔽下层的触摸
        local function CCLayerTouch(event)
			if event == "began" then
				return true
			end
		end
		self.node_:setTouchEnabled(true)
		self.node_:registerScriptTouchHandler(CCLayerTouch, false, kCCMenuHandlerPriority-1, true)

        local function onBtnClose(btn)
             cclog("onBtnClose")
             self.node_:removeFromParentAndCleanup(true)
        end    

        self.button_close:setTouchPriority(kCCMenuHandlerPriority - 1)
        self.proxy_:handleButtonEvent(self.button_close, function(button, event)
		    onBtnClose(button)
		    return nil
	    end, CCControlEventTouchUpInside)

         self.button_left:setTouchPriority(kCCMenuHandlerPriority - 1)
         self.proxy_:handleButtonEvent(self.button_left, function(button, event)
		    onBtnClose(button)
		    return nil
	    end, CCControlEventTouchUpInside)
    end
end

function onNodeCleanup(self)
    --cclog("onNodeCleanup")
    if self.proxy_ then
    	self.proxy_:release()
    end
    layer_base_t.onNodeCleanup(self)
end

