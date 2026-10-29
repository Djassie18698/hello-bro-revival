----------------------------------------------------------------------
--  Copyright (c) 2014-2016, XCKOO. All Rights Reserved.
--  Author :Tango
--  Time   :2014/11/25 11:51:25
--  Remark :捐献忍者
----------------------------------------------------------------------
module("ui_orgDonateNinjaCell", package.seeall)
baseClass(layer_base_t, ui_orgDonateNinjaCell)

function init(self, cellSize, data, parent)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	local ccbiAttrTable = {name="sub_ui/OrgDonateNinjaCell.ccbi", size=cellSize}
	layer_base_t.init(self, true, ccbiAttrTable)

    --data
    self.data = data
	self.parent = parent

    --init
	self:init_ui()
	self:init_binding_event()
end

function init_ui(self)
	if self.proxy_ ~= nil then

		--btn
		self.btnSelect = tolua.cast(self.proxy_:getNode("ctrl_select"), "CCControlButton")
		self.sprSelected = tolua.cast(self.proxy_:getNode("ctrl_selected"), "CCSprite")
		
		self.nodeIcon = tolua.cast(self.proxy_:getNode("node_icon"), "CCNode")

		self.label_card_level = tolua.cast(self.proxy_:getNode("label_level"),"CCLabelBMFont")		
		self.node_icon = tolua.cast(self.proxy_:getNode("node_icon"), "CCNode")
		self.sprite_ninjaicon = tolua.cast(self.proxy_:getNode("sprite_ninjaicon"), "CCSprite")
		self.node_shadow_back = tolua.cast(self.proxy_:getNode("node_shadow_back"), "CCNode")
		self.node_shadow_front = tolua.cast(self.proxy_:getNode("node_shadow_front"), "CCNode")
		self.node_inlay_frame = tolua.cast(self.proxy_:getNode("node_inlay_frame"), "CCNode")
		self.sprite_frame_corner1 = tolua.cast(self.proxy_:getNode("sprite_frame_corner1"), "CCSprite")
		self.sprite_frame_corner2 = tolua.cast(self.proxy_:getNode("sprite_frame_corner2"), "CCSprite")

		self.label_name = tolua.cast(self.proxy_:getNode("label_name"), "CCLabelTTF")

		self.sprite_ninjacamp = tolua.cast(self.proxy_:getNode("sprite_ninjacamp"), "CCSprite")
		self.label_attack = tolua.cast(self.proxy_:getNode("label_attack"), "CCLabelBMFont")
		self.label_defense = tolua.cast(self.proxy_:getNode("label_defense"), "CCLabelBMFont")
		self.label_chakra = tolua.cast(self.proxy_:getNode("label_chakra"), "CCLabelBMFont")

		for i = 1, 5 do
			self["sprite_star" .. tostring(i)] = tolua.cast(self.proxy_:getNode("sprite_star" .. tostring(i)), "CCSprite")
		end
		

		--init info
		self:init_ui_ext()
	end
end

function init_ui_ext(self)
	local obj = self.data.ninjainfo
	self.sprSelected:setVisible(self.data.selected)

	self.label_card_level:setString(tostring(obj:GetLevel()))

	--设置卡牌的图标
	local ninjainfo = DataMgr.GetDataByID("Struct_Ninjainfo", tonumber(obj:GetDataID()))
	local pFrameSprite = CGameObjElement:GetNinjaFrame(E_FRAMETYPE_SMALL, ninjainfo.m_quality)
	local pIconFrame = CGameObjElement:GetNinjaIcon(E_FRAMETYPE_SMALL, ninjainfo.m_ninjaicon)
	local sprite1 = CCSprite:createWithSpriteFrame(pIconFrame)
	sprite1:setPosition(ccp(0,0))
	sprite1:setAnchorPoint(ccp(0,0))
	self.sprite_ninjaicon:setDisplayFrame(pFrameSprite)
	self.node_icon:addChild(sprite1)

	--卡牌背景动画
	local strengthlevel = obj:GetStrengthLevel()
	CGameObjElement:SetFrameShadowBack(self.node_shadow_back:getContentSize(),self.node_shadow_back, strengthlevel, ninjainfo.m_level)
	CGameObjElement:SetFrameShadowFront(self.node_shadow_front:getContentSize(),self.node_shadow_front, strengthlevel, ninjainfo.m_level)

	--设置是否转生
	local newlife =  obj:GetReincarnationLevel()	
	self.node_inlay_frame:setVisible(true)
	local topinlayframe = CGameObjElement:GetTopInlayFrame(E_FRAMETYPE_SMALL, newlife)
	if topinlayframe ~= nil then
		self.sprite_frame_corner1:setDisplayFrame(topinlayframe)
		self.sprite_frame_corner1:setVisible(true)
	else
		self.sprite_frame_corner1:setVisible(false)
	end

	local downinlayframe = CGameObjElement:GetDownInlayFrame(E_FRAMETYPE_SMALL, newlife)
	if downinlayframe ~= nil then
		self.sprite_frame_corner2:setDisplayFrame(downinlayframe)
		self.sprite_frame_corner2:setVisible(true)
	else
		self.sprite_frame_corner2:setVisible(false)
	end

	--设置名字
	self.label_name:setString(obj:GetName())

	--设置国家标志
	local county_icon_index = obj:GetCardCamp()
	local frame1 = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(tools.getAttributeIcon(county_icon_index))
	if frame1 ~= nil then
		self.sprite_ninjacamp:setDisplayFrame(frame1)
	end

	--设置攻防，查克拉属性
	local attack_current_plus = 0
	local defense_current_plus = 0
	local chakra_current_plus = 0
	local attackmin = obj:GetAttackMin()
	local attackmax = obj:GetAttackMax()
	local defensemin = obj:GetDefenseMin()
	local defensemax = obj:GetDefenseMax()
	local chakramin = obj:GetChakraMin()
	local chakramax = obj:GetChakraMax()
	
	if strengthlevel ~= 0 then
		local strengthconfig = DataMgr.GetDataByID("Struct_Ninjastrengthconfig", strengthlevel)
		local ratio = strengthconfig.m_addprop / 2
		attack_current_plus = (attackmin + attackmax) * ratio
		defense_current_plus = (defensemin + defensemax) * ratio
		chakra_current_plus = (chakramin + chakramax) * ratio
	end

	self.label_attack:setString(string.format("%d-%d", attackmin + attack_current_plus, attackmax + attack_current_plus))
	self.label_defense:setString(string.format("%d-%d", defensemin + defense_current_plus, defensemax + defense_current_plus))
	self.label_chakra:setString(string.format("%d-%d", chakramin + chakra_current_plus, chakramax + chakra_current_plus))

	--设置卡片星级
	local quality = obj:GetQuality()
	if quality > 5 then
		quality = 5
	end
	for i=1, quality do
		local pSprite = CCSprite:createWithSpriteFrameName("com_normal_star")
		self["sprite_star" .. tostring(i)]:addChild(pSprite);
		pSprite:setPosition(0, 0)
		pSprite:setAnchorPoint(ccp(0, 0))
	end
	for i=quality + 1, 5 do
		self["sprite_star" .. tostring(i)]:removeAllChildrenWithCleanup(true)
	end
end

function init_binding_event(self)
	if self.proxy_ ~= nil then
		self.btnSelect:setTouchPriority(kCCMenuHandlerPriority-1)
		self.proxy_:handleButtonEvent(self.btnSelect, function(button, event)
			self.data.selected = not self.data.selected
			self.sprSelected:setVisible(self.data.selected)
			if self.parent then
				self.parent:onSelectChanged()
			end
		end, CCControlEventTouchDown)
	end
end

function onNodeCleanup(self)
	if self.proxy_ then
    	self.proxy_:release()
    	self.proxy_ = nil
    end
    layer_base_t.onNodeCleanup(self)
end