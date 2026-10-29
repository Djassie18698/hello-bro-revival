----------------------------------------------------------------------
--  Copyright (c) 2014-2016, XCKOO. All Rights Reserved.
--  Author :Tango
--  Time   :2014/11/12 17:32:26
--  Remark :组织排行
----------------------------------------------------------------------
module("ui_orgRankingsCell", package.seeall)
baseClass(layer_base_t, ui_orgRankingsCell)

function init(self, cellSize, data)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	local ccbiAttrTable = {name="sub_ui/OrgRankingsCell.ccbi", size=cellSize}
	layer_base_t.init(self, true, ccbiAttrTable)

    --data
    self.data = data

    --init
	self:init_ui()
	self:init_binding_event()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		--label
		self.labelRank = tolua.cast(self.proxy_:getNode("label_rank"), "CCLabelTTF")
		self.label_org_name = tolua.cast(self.proxy_:getNode("label_org_name"), "CCLabelTTF")
		self.label_org_level = tolua.cast(self.proxy_:getNode("label_org_level"), "CCLabelTTF")
		self.label_org_leader = tolua.cast(self.proxy_:getNode("label_org_leader"), "CCLabelTTF")
		self.label_org_num = tolua.cast(self.proxy_:getNode("label_org_num"), "CCLabelTTF")
		--btn
		self.btn_detail = tolua.cast(self.proxy_:getNode("btn_detail"), "CCControlButton")

		--init info
		self:init_ui_ext()
	end
end

function init_ui_ext(self)
	--label
	self.labelRank:setString(self.data.rank)
	self.label_org_name:setString(self.data.groupname)
	self.label_org_level:setString(self.data.level)
	self.label_org_leader:setString(self.data.leadername)
	self.label_org_num:setString(self.data.curcount)
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