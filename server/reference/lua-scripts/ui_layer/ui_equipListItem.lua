----------------------------------------------------------------------
--  Copyright (c) 2014-2016, XCKOO. All Rights Reserved.
--  Author :Tango
--  Time   :2015/3/5 17:17:32
--  Remark :装备列表
----------------------------------------------------------------------

module("ui_equipListItem", package.seeall)
baseClass(layer_base_t, ui_equipListItem)

function init(self, data, cellSize, indexval,listener)
	local ccbiAttrTable = {name="sub_ui/EquipItem.ccbi", size=cellSize}
	--local ccbiAttrTable = {name="secretshop/trainNinjaCard.ccbi"}
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()
	layer_base_t.init(self, true, ccbiAttrTable)

	self.listener = listener

	self.objItem = data
	self.indexval = indexval
	self:init_ui()
	self:init_binding_event()
end

function init_ui(self)
	if self.proxy_ ~= nil then

		self.label_name = tolua.cast(self.proxy_:getNode("label_name"), "CCLabelTTF")
		self.label_attack = tolua.cast(self.proxy_:getNode("label_attack"), "CCLabelBMFont")

		self.label_level = tolua.cast(self.proxy_:getNode("label_level"), "CCLabelBMFont")
		self.labelGrade = tolua.cast(self.proxy_:getNode("label_grade"), "CCLabelBMFont")

		for i = 1, 5 do
			self["spr_star_" .. i] = tolua.cast(self.proxy_:getNode("sprite_star" .. i), "CCSprite")
		end

		-- btn
		self.btnSelect = tolua.cast(self.proxy_:getNode("btn_select"),"CCControlButton")
		self.ctrl_goto_store = tolua.cast(self.proxy_:getNode("ctrl_goto_store"), "CCControlButton")
		self.ctrl_goto_mainround = tolua.cast(self.proxy_:getNode("ctrl_goto_mainround"), "CCControlButton")

		self.sprCardFrame = tolua.cast(self.proxy_:getNode("sprite_ninjaicon"), "CCSprite")
		self.sprCardIcon = tolua.cast(self.proxy_:getNode("spr_card_icon"), "CCSprite")

		self.sprEquipType = tolua.cast(self.proxy_:getNode("spr_equip_type"), "CCSprite")

		self.layer_info = tolua.cast(self.proxy_:getNode("layer_info"),"CCLayer")		
		self.layer_tips = tolua.cast(self.proxy_:getNode("layer_tips"),"CCLayer")	
	
        self.label_is_use = tolua.cast(self.proxy_:getNode("label_is_use"),"CCLabelTTF")	

		if self.objItem.istips then
			self.layer_tips:setVisible(true)
			self.layer_info:setVisible(false)
		else
			self.layer_info:setVisible(true)
			self.layer_tips:setVisible(false)
			self:initEquipInfo()
		end

		--self.proxy_:handleControlEvent(self.btn_card_info, btn_vs_player, CCControlEventTouchUpInside)
	end
end

function init_binding_event(self)
	if self.proxy_ ~= nil then		
		if self.objItem.istips then
			local function goto_store()
				GetMainMenu():ChangeToSub(E_STOREITEMSVIEW)
			end

			local function goto_mainround()
				GetMainMenu():ChangeToSub(E_GAMEROUND)
			end

			self.ctrl_goto_store:setTouchPriority(-5)
			self.proxy_:handleControlEvent(self.ctrl_goto_store, goto_store, CCControlEventTouchUpInside)
			self.ctrl_goto_mainround:setTouchPriority(-5)
			self.proxy_:handleControlEvent(self.ctrl_goto_mainround, goto_mainround, CCControlEventTouchUpInside)
		else
			self.btnSelect:setTouchPriority(-5)
			self.proxy_:handleControlEvent(self.btnSelect, function ()
				self.listener:onSelected(self.indexval)
			end, CCControlEventTouchUpInside)
		end
	end
end

function initEquipInfo( self )
	self.label_name:setString(self.objItem:GetName())
	self.label_level:setString(self.objItem:GetLevel())

	local quality = tonumber(self.objItem:GetQuality())
	for i = 1, quality do
		local pSprite = CCSprite:createWithSpriteFrameName("com_normal_star")
		self["spr_star_" .. tostring(i)]:addChild(pSprite);
		pSprite:setPosition(0, 0)
		pSprite:setAnchorPoint(ccp(0, 0))
	end
	for i = quality + 1, 5 do
		self["spr_star_" .. tostring(i)]:removeAllChildrenWithCleanup(true)
	end

	local ninjainfo = DataMgr.GetDataByID("Struct_Equipmentinfo", tonumber(self.objItem:GetDataID()))
	if ninjainfo then
		local frame = rl_get_frameicon(E_FRAMETYPE_SMALL, ninjainfo.m_quality)
		local icon = CGameObjElement:GetEquipIcon(E_FRAMETYPE_SMALL, ninjainfo.m_equipicon)
		self.sprCardFrame:setDisplayFrame(frame)
		self.sprCardIcon:setDisplayFrame(icon)

		local typeIcon = nil
		if ninjainfo.m_equiptype == 0 then -- 武器
			typeIcon = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("com_fight_icon")
			self.label_attack:setString(self.objItem:GetAttackMin() .. "-" .. self.objItem:GetAttackMax())
		elseif ninjainfo.m_equiptype == 1 then -- 防具
			typeIcon = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("com_defense_icon")
			self.label_attack:setString(self.objItem:GetDefenseMin() .. "-" .. self.objItem:GetDefenseMax())
		elseif ninjainfo.m_equiptype == 2 then -- 饰品
			typeIcon = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("com_text_chakra")
			self.label_attack:setString(self.objItem:GetChakraMin() .. "-" .. self.objItem:GetChakraMax())
		end
		self.sprEquipType:setDisplayFrame(typeIcon)

		local grade = self.objItem:GetReincarnationLevel()
		if grade > 0 then
			self.labelGrade:setString(grade)
			self.labelGrade:setVisible(true)
		else
			self.labelGrade:setVisible(false)
		end

        if self.objItem:IsUsingInAnyTeam() then
            self.label_is_use:setVisible(true)           
        end

	end
end

function onNodeCleanup(self)
    --cclog("onNodeCleanup")
	if self.proxy_ ~= nil then
		self.proxy_:release()
		self.proxy_ = nil
	end
   layer_base_t.onNodeCleanup(self)
end
