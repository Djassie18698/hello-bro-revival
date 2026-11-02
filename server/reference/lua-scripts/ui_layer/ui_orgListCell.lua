--descriptioin:工会申请页面
--company: xckoo
--author: litao
--date: 2014-10-24
---------------------------------------------
module("ui_orgListCell", package.seeall)
baseClass(layer_base_t, ui_orgListCell)

function init(self, cellSize, data)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	local ccbiAttrTable = {name="sub_ui/OrgListCell.ccbi", size=cellSize}
	layer_base_t.init(self, true, ccbiAttrTable)

    --data
    self.m_orgData = data

    --init
	self:init_ui()
	self:init_binding_event()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		--label
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
	self.label_org_name:setString(self.m_orgData.groupname)
	self.label_org_level:setString(self.m_orgData.level)
	self.label_org_leader:setString(self.m_orgData.leader)
	local tempstr = self.m_orgData.curcount .. "/" .. self.m_orgData.totalcount
	self.label_org_num:setString(tempstr)
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