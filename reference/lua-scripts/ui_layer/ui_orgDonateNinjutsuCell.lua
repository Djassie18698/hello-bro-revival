----------------------------------------------------------------------
--  Copyright (c) 2014-2016, XCKOO. All Rights Reserved.
--  Author :Tango
--  Time   :2014/12/3 10:13:36
--  Remark :捐献忍术
----------------------------------------------------------------------
module("ui_orgDonateNinjutsuCell", package.seeall)
baseClass(layer_base_t, ui_orgDonateNinjutsuCell)

function init(self, cellSize, data, parent)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	local ccbiAttrTable = { name = "sub_ui/OrgDonateNinjutsuCell.ccbi", size = cellSize }
	layer_base_t.init(self, true, ccbiAttrTable)

	-- data
	self.data = data

	self.parent = parent

	-- init
	self:init_ui()
	self:init_binding_event()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		-- label
		self.label_name = tolua.cast(self.proxy_:getNode("label_name"), "CCLabelTTF")
		self.label_attack = tolua.cast(self.proxy_:getNode("label_attack"), "CCLabelBMFont")
		self.label_defense = tolua.cast(self.proxy_:getNode("label_defense"), "CCLabelBMFont")

		self.label_level = tolua.cast(self.proxy_:getNode("label_level"), "CCLabelBMFont")

		for i = 1, 5 do
			self["spr_star_" .. i] = tolua.cast(self.proxy_:getNode("sprite_star" .. i), "CCSprite")
		end

		-- btn
		self.btnSelect = tolua.cast(self.proxy_:getNode("ctrl_select"), "CCControlButton")
		self.sprSelected = tolua.cast(self.proxy_:getNode("ctrl_selected"), "CCSprite")

		self.sprCardFrame = tolua.cast(self.proxy_:getNode("sprite_ninjaicon"), "CCSprite")
		self.sprCardIcon = tolua.cast(self.proxy_:getNode("spr_card_icon"), "CCSprite")

		-- init info
		self:init_ui_ext()
	end
end

function init_ui_ext(self)
	self.label_name:setString(self.data.name)
	self.label_attack:setString(self.data.attacklow .. "-" .. self.data.attackhigh)
	self.label_defense:setString(self.data.defenselow .. "-" .. self.data.defensehigh)

	self.sprSelected:setVisible(self.data.selected)

	local quality = tonumber(self.data.star_level)
	for i = 1, quality do
		local pSprite = CCSprite:createWithSpriteFrameName("com_normal_star")
		self["spr_star_" .. tostring(i)]:addChild(pSprite);
		pSprite:setPosition(0, 0)
		pSprite:setAnchorPoint(ccp(0, 0))
	end
	for i = quality + 1, 5 do
		self["spr_star_" .. tostring(i)]:removeAllChildrenWithCleanup(true)
	end

	local cardid = tonumber(self.data.cardid)
	local ninjainfo = DataMgr.GetDataByID("Struct_Ninjutsuinfo", cardid)
	if ninjainfo then
		local frame = rl_get_frameicon(E_FRAMETYPE_SMALL, ninjainfo.m_quality)
		local icon = CGameObjElement:GetNinjutsuIcon(E_FRAMETYPE_SMALL, ninjainfo.m_icon)
		self.sprCardFrame:setDisplayFrame(frame)
		self.sprCardIcon:setDisplayFrame(icon)
	end
	self.label_level:setString(self.data.cardlevel)

end

function init_binding_event(self)
	if self.proxy_ ~= nil then
		self.btnSelect:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.proxy_:handleButtonEvent(self.btnSelect, function(button, event)
			self.data.selected = not self.data.selected
			self.sprSelected:setVisible(self.data.selected)
			if self.parent then
				self.parent:onSelectChanged()
			end
		end , CCControlEventTouchDown)
	end
end

function onNodeCleanup(self)
	if self.proxy_ then
		self.proxy_:release()
		self.proxy_ = nil
	end
	layer_base_t.onNodeCleanup(self)
end