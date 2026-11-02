----------------------------------------------------------------------
--  Copyright (c) 2014-2016, XCKOO. All Rights Reserved.
--  Author :Tango
--  Time   :2014/11/17 15:20:39
--  Remark :成员审批
----------------------------------------------------------------------
module("ui_orgMemCheckCell", package.seeall)
baseClass(layer_base_t, ui_orgMemCheckCell)

function init(self, cellSize, data)
	local ccbiAttrTable = {name="sub_ui/OrgMemCheckCell.ccbi", size=cellSize}
	layer_base_t.init(self, true, ccbiAttrTable)
	
	self.cellData = data
	self.selected = false
	
	--init
	self:init_ui()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		self.labelName = tolua.cast(self.proxy_:getNode("label_name"),"CCLabelTTF")
		self.labelLv = tolua.cast(self.proxy_:getNode("label_level"),"CCLabelTTF")
		self.labelFighting = tolua.cast(self.proxy_:getNode("label_fighting"),"CCLabelTTF")
		self.btnSelect = tolua.cast(self.proxy_:getNode("ctrl_select"),"CCControlButton")
		self.sprSelected = tolua.cast(self.proxy_:getNode("ctrl_selected"),"CCSprite")

		self.sprSelected:setVisible(false)
		--init info
		self:init_ui_ext()
		self:init_binding_event()
	end
end

function clear( self )

end
--
function init_ui_ext(self)
	self:clear()
	
	self.labelName:setString(self.cellData.name)
	self.labelLv:setString(self.cellData.level)
	self.labelFighting:setString(self.cellData.power)
end

function init_binding_event(self)
	if self.proxy_ ~= nil then
		self.btnSelect:setTouchPriority(kCCMenuHandlerPriority-1)
		self.proxy_:handleButtonEvent(self.btnSelect, function(button, event)
			self.selected = not self.selected
			self.sprSelected:setVisible(self.selected)
		end, CCControlEventTouchDown)
	end
end

function onNodeCleanup(self)
	---[[
	if self.proxy_ then
		self.proxy_:release()
		self.proxy_ = nil
	end
	--]]
	layer_base_t.onNodeCleanup(self)
end
