----------------------------------------------------------------------
--  Copyright (c) 2014-2016, XCKOO. All Rights Reserved.
--  Author :Tango
--  Time   :2015-8-20 17:13:05
--  Remark :宠物主界面
----------------------------------------------------------------------
module("ui_petMainLayer", package.seeall)
baseClass(layer_base_t, ui_petMainLayer)

require("ui_layer/ui_petPsychicLayer")
require("ui_layer/ui_petListLayer")

function init(self, parent)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	self.contentSize_ = GetMainMenu():GetSubContentNode():getContentSize()
	local ccbiAttrTable = { name = "sub_ui/PetMainView.ccbi", size = self.contentSize_ }
	layer_base_t.init(self, true, ccbiAttrTable)

	self.parent = parent

	self:init_ui()
	self:init_binding_event()
end

function refreshData(self)
    getLabelBMFontFromCCB(self.proxy_,"label_goldval"):setString(self.playerData_.m_gold)
    getLabelBMFontFromCCB(self.proxy_,"label_silverval"):setString(self.playerData_.m_silver)
end

function init_ui(self)
	if self.proxy_ ~= nil then
		self.nodeSubLayer = tolua.cast(self.proxy_:getNode("node_sublayer"), "CCNode")
		-- tabs
        self.btn_back = tolua.cast(self.proxy_:getNode("btn_back"), "CCControlButton")
		self.btnPsychic = tolua.cast(self.proxy_:getNode("btn_psychic_array"), "CCControlButton")
		self.btnPet = tolua.cast(self.proxy_:getNode("btn_pet"), "CCControlButton")

		self:openPsychic()

		initHeader(self.proxy_)
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
					return false
				end
			end
		end

		self.node_:setTouchEnabled(true)
		self.node_:registerScriptTouchHandler(CCLayerTouch, false, kCCMenuHandlerPriority - 1, true)

        --通灵阵
        self:init_btn_binding_event(self.btnPsychic, 
            function(button, event)
                self:openPsychic()
            end,
            localizable.ui_label_psychic_text
        )
        --通灵兽
        self:init_btn_binding_event(self.btnPet, 
            function(button, event)
                self:openPet()
            end,
            localizable.ui_label_petlist_text
        )
        --返回
        self:init_btn_binding_event(self.btn_back, 
            function(button, event)
                self.parent:refreshData()
                self.node_:removeFromParentAndCleanup(true)
            end,
            localizable.ui_label_back_text
        )

	end
end

function openPsychic(self)
	self.nodeSubLayer:removeAllChildrenWithCleanup(true)
	local view = createObj(ui_petPsychicLayer,self.nodeSubLayer:getContentSize(), self)
	self.nodeSubLayer:addChild(view.node_)
	self.btnPsychic:setEnabled(false)
	self.btnPet:setEnabled(true)
end

function openPet( self )
	self.nodeSubLayer:removeAllChildrenWithCleanup(true)
	local view = createObj(ui_petListLayer,self.nodeSubLayer:getContentSize(), self)
	self.nodeSubLayer:addChild(view.node_)

	self.btnPet:setEnabled(false)
	self.btnPsychic:setEnabled(true)
end

function onNodeCleanup(self)
	-- cclog("1111---001")
	if self.proxy_ then
		self.proxy_:release()
	end
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