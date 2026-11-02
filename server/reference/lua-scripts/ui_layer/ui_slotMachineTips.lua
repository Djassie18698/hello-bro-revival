----------------------------------------------------------------------
--  Copyright (c) 2014-2016, XCKOO. All Rights Reserved.
--  Author :Tango
--  Time   :2015-7-6 10:52:34
--  Remark :摇摇乐说明
----------------------------------------------------------------------
module("ui_slotMachineTips", package.seeall)
baseClass(layer_base_t, ui_slotMachineTips)

function init(self, data)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()
	local winSize = CCDirector:sharedDirector():getWinSize()
	--Load res
	local ccbiAttrTable = {name="activity/SlotMachineTips.ccbi", size=CCSizeMake(768, winSize.height)}
	layer_base_t.init(self, true, ccbiAttrTable)

	self.m_datas = data
	--
	self.cellNodes = {}

	self:init_ui()
	self:init_binding_event()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		self.btnDialogClose = tolua.cast(self.proxy_:getNode("closeButton"), "CCControlButton")
		self.btnClose = tolua.cast(self.proxy_:getNode("btn_close"), "CCControlButton")
		--
		self.node_content = tolua.cast(self.proxy_:getNode("node_content"), "CCNode")
		self.node_cell = tolua.cast(self.proxy_:getNode("node_cell"), "CCNode")

	end
end

function init_binding_event(self)
	if self.proxy_ ~= nil then
		local function CCLayerTouch(event,x,y)
			local rect = self.node_:boundingBox()
			rect.origin = ccp(0,0)
			local p = self.node_:convertToNodeSpace(ccp(x,y))
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

		--绑定按钮事件
		self.btnClose:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.proxy_:handleButtonEvent(self.btnClose, close_window, CCControlEventTouchUpInside)

		self.btnDialogClose:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.proxy_:handleControlEvent(self.btnDialogClose, close_window, CCControlEventTouchUpInside)
	end
end

function onNodeCleanup(self)
    layer_base_t.onNodeCleanup(self)
end