--
-- Author: Tango
-- Date: 2015-08-26 19:43:46
--

module("ui_tipsDialog", package.seeall)
baseClass(layer_base_t, ui_tipsDialog)

function init(self, text)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()
	local winSize = CCDirector:sharedDirector():getWinSize()
	-- Load res
	local ccbiAttrTable = { name = "sub_ui/PetPsychicArrayTips.ccbi", size = CCSizeMake(768, winSize.height) }
	layer_base_t.init(self, true, ccbiAttrTable)

	self.text = text
	--
	self.cellNodes = { }

	self:init_ui()
	self:init_binding_event()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		self.btnDialogClose = tolua.cast(self.proxy_:getNode("closeButton"), "CCControlButton")
		self.btnClose = tolua.cast(self.proxy_:getNode("btn_close"), "CCControlButton")
        
		self.labelTitle = tolua.cast(self.proxy_:getNode('borderInfo_title'), 'CCLabelTTF')
		self.labelTips = tolua.cast(self.proxy_:getNode('label_tips'), 'CCLabelTTF')

		self.labelTitle:setString(localizable.ui_label_info_title_text)
		self.labelTips:setString(self.text)
	end
end

function init_binding_event(self)
	if self.proxy_ ~= nil then
		local function CCLayerTouch(event, x, y)
			local rect = self.node_:boundingBox()
			rect.origin = ccp(0, 0)
			local p = self.node_:convertToNodeSpace(ccp(x, y))
			if event == "began" then
				if rect:containsPoint(p) == true then
					return true
				else
					return true
				end
			end
		end
		self.node_:setTouchEnabled(true)
		self.node_:registerScriptTouchHandler(CCLayerTouch, false, kCCMenuHandlerPriority - 1, true)

		local function close_window(btn, event)
			self.node_:removeFromParentAndCleanup(true)
		end

        self:init_btn_binding_event(self.btnClose, close_window, localizable.ui_label_info_ok_text)
        self:init_btn_binding_event(self.btnDialogClose, close_window, nil)
	end
end

function onNodeCleanup(self)
	layer_base_t.onNodeCleanup(self)
end

function init_btn_binding_event(self, btn_node, callback, btn_title_text)
    btn_node:setTouchEnabled(true)
    btn_node:setTouchPriority(kCCMenuHandlerPriority - 1)
    self.proxy_:handleButtonEvent(btn_node, callback , CCControlEventTouchUpInside)
    if btn_title_text ~= nil then
        --btn_node:setTitleForState(btn_title_text, CCControlStateNormal)
        --btn_node:setTitleForState(btn_title_text, CCControlStateHighlighted)
        --btn_node:setTitleForState(btn_title_text, CCControlStateDisabled)    
    end
end