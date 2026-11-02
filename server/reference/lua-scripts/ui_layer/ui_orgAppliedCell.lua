----------------------------------------------------------------------
--  Copyright (c) 2014-2016, XCKOO. All Rights Reserved.
--  Author :Tango
--  Time   :2014/11/10 10:22:25
--  Remark :已申请组织列表
----------------------------------------------------------------------
module("ui_orgAppliedCell", package.seeall)
baseClass(layer_base_t, ui_orgAppliedCell)

function init(self, cellSize, data)
	local ccbiAttrTable = {name="sub_ui/OrgHasApplyCell.ccbi", size=cellSize}
	layer_base_t.init(self, true, ccbiAttrTable)
	
	self.cellData = data
	--init
	self:init_ui()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		self.labelName = tolua.cast(self.proxy_:getNode("label_org_name"),"CCLabelTTF")
		self.labelLv = tolua.cast(self.proxy_:getNode("label_org_level"),"CCLabelTTF")
		self.labelLeader = tolua.cast(self.proxy_:getNode("label_org_header"),"CCLabelTTF")
		self.labelPopulation = tolua.cast(self.proxy_:getNode("label_org_num"),"CCLabelTTF")
		self.labelState = tolua.cast(self.proxy_:getNode("label_apply_state"),"CCLabelTTF")
		
		--init info
		self:init_ui_ext()
	end
end

function clear( self )

end
--
function init_ui_ext(self)
	self:clear()
	
	self.labelName:setString(self.cellData.groupname)
	self.labelLv:setString(self.cellData.level)
	self.labelLeader:setString(self.cellData.leadername)

	local tempstr = self.cellData.curcount .. "/" .. self.cellData.totalcount
	self.labelPopulation:setString(tempstr)

	--0：申请中；1：已拒绝
	if self.cellData.status == "0" then
		self.labelState:setColor(ccc3(0,255,0))
		self.labelState:setString(localizable.ui_orgApplied_check)
	elseif self.cellData.status == "1" then
		self.labelState:setColor(ccc3(255,0,0))
		self.labelState:setString(localizable.ui_orgApplied_refuse)
	end
end

function init_binding_event(self)
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
