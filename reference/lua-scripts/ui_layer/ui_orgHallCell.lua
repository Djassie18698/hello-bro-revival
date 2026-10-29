----------------------------------------------------------------------
--  Copyright (c) 2014-2016, XCKOO. All Rights Reserved.
--  Author :Tango
--  Time   :2014/11/13 14:27:17
--  Remark :组织大厅
----------------------------------------------------------------------
module("ui_orgHallCell", package.seeall)
baseClass(layer_base_t, ui_orgHallCell)

function init(self, cellSize, data)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	local ccbiAttrTable = { name = "sub_ui/OrgHallCell.ccbi", size = cellSize }
	layer_base_t.init(self, true, ccbiAttrTable)

	-- data
	self.cellData = data

	-- init
	self:init_ui()
	self:init_binding_event()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		-- label
		self.labelTime = tolua.cast(self.proxy_:getNode("label_time"), "CCLabelTTF")
		self.labelName = tolua.cast(self.proxy_:getNode("label_name"), "CCLabelTTF")
		self.labelDesc = tolua.cast(self.proxy_:getNode("label_desc"), "CCLabelTTF")

		-- init info
		self:init_ui_ext()
	end
end

function init_ui_ext(self)
	-- label
	local timestr = os.date("%m-%d  %X", self.cellData.checkin_time)
	self.labelTime:setString(timestr)
	self.labelName:setString(self.cellData.checkin_name)
	self.labelDesc:setString(localizable.ui_orgHall_tasktype .. self.cellData.taskname)
end

function init_binding_event(self)
	--
end

function onNodeCleanup(self)
	if self.proxy_ then
		self.proxy_:release()
		self.proxy_ = nil
	end
	layer_base_t.onNodeCleanup(self)
end