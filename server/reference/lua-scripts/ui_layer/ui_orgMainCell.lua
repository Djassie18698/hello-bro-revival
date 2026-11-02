----------------------------------------------------------------------
--  Copyright (c) 2014-2016, XCKOO. All Rights Reserved.
--  Author :Tango
--  Time   :2014/11/11 11:28:30
--  Remark :组织主页面
----------------------------------------------------------------------
module("ui_orgMainCell", package.seeall)
baseClass(layer_base_t, ui_orgMainCell)

function init(self, cellSize, data)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	local ccbiAttrTable = {name="sub_ui/OrgMainCell.ccbi", size=cellSize}
	layer_base_t.init(self, true, ccbiAttrTable)

    --data
    self.cellData = data

    --init
	self:init_ui()
	self:init_binding_event()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		--label
		self.labelName = tolua.cast(self.proxy_:getNode("label_name"), "CCLabelTTF")
		self.labelLevel = tolua.cast(self.proxy_:getNode("label_level"), "CCLabelTTF")
		self.labelTitle = tolua.cast(self.proxy_:getNode("label_title"), "CCLabelTTF")
		self.labelContribution = tolua.cast(self.proxy_:getNode("label_contribution"), "CCLabelTTF")
		self.labelLastLogin = tolua.cast(self.proxy_:getNode("label_lastLogin"), "CCLabelTTF")

		--init info
		self:init_ui_ext()
	end
end

function init_ui_ext(self)
	--label
	self.labelName:setString(self.cellData.name)
	self.labelLevel:setString(self.cellData.level)
	local title = localizable.OrgTitleName[tonumber(self.cellData.postion) + 1]
	self.labelTitle:setString(title)
	self.labelContribution:setString(self.cellData.score)
	local timestr = os.date("%m-%d",self.cellData.last_login)
	self.labelLastLogin:setString(timestr)
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