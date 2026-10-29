--descriptioin:神卡合成表格cell
--company: xckoo
--author: litao
--date: 2014.6.9
---------------------------------------------------
module("ui_godCardSyntheticNinjaItem", package.seeall)
baseClass(layer_base_t, ui_godCardSyntheticNinjaItem)

function init(self, data, cellSize, indexval)
	local ccbiAttrTable = {name="sub_ui/GodCardSyntheticNinjaItem.ccbi", size=cellSize}
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()
	layer_base_t.init(self, true, ccbiAttrTable)

	self.objItem = data
	self.indexval = indexval
	self:init_ui()
	self:init_binding_event()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		self.layer_info = tolua.cast(self.proxy_:getNode("layer_info"),"CCLayer")		
		self.layer_tips = tolua.cast(self.proxy_:getNode("layer_tips"),"CCLayer")
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
		--self.label_chakra = tolua.cast(self.proxy_:getNode("label_chakra"), "CCLabelBMFont")
		--self.sprite_gou = tolua.cast(self.proxy_:getNode("sprite_gou"), "CCSprite")
		--self.ctrl_btn_gou = tolua.cast(self.proxy_:getNode("ctrl_btn_gou"), "CCControlButton")
		self.ctrl_goto_store = tolua.cast(self.proxy_:getNode("ctrl_goto_store"), "CCControlButton")
		self.ctrl_goto_mainround = tolua.cast(self.proxy_:getNode("ctrl_goto_mainround"), "CCControlButton")

		--
		self.spr_btn_select = tolua.cast(self.proxy_:getNode("sprite_btn_select"), "CCSprite")
		for i = 1, 5 do
			self["sprite_star" .. tostring(i)] = tolua.cast(self.proxy_:getNode("sprite_star" .. tostring(i)), "CCSprite")
		end
	
		if self.objItem.istips then
			self.layer_tips:setVisible(true)
			self.layer_info:setVisible(false)
		else
			self.layer_info:setVisible(true)
			self.layer_tips:setVisible(false)
			self:init_control_data()
		end
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
			local function btn_select()
				if ui_trainNinjaListLayer.PreSelectedIndex == self.indexval then
					--self.sprite_gou:setVisible(false)
					ui_trainSoulLayer.CurIndex = 0
					ui_trainNinjaListLayer.PreSelectedIndex = 0
					ui_trainNinjaListLayer.LastSelectedIndex = 0
				else
					if ui_trainNinjaListLayer.PreSelectedIndex == 0 then
						--self.sprite_gou:setVisible(true)
						ui_trainSoulLayer.CurIndex = self.indexval
						ui_trainNinjaListLayer.PreSelectedIndex = self.indexval
						ui_trainNinjaListLayer.LastSelectedIndex = self.indexval
					else
						ui_trainSoulLayer.CurIndex = self.indexval				
						ui_trainNinjaListLayer.Instance:updateCellAtIndex(ui_trainNinjaListLayer.PreSelectedIndex - 1)
						ui_trainNinjaListLayer.PreSelectedIndex = self.indexval
						ui_trainNinjaListLayer.LastSelectedIndex = self.indexval
						--self.sprite_gou:setVisible(true)
					end
				end
				ui_trainNinjaListLayer.Instance:update_ui()
			end

			--self.ctrl_btn_gou:setTouchPriority(-5)
			--self.proxy_:handleControlEvent(self.ctrl_btn_gou, btn_select, CCControlEventTouchUpInside)
		end
	end
end


function init_control_data(self)
	local lv = self.objItem:GetLevel()
	self.label_card_level:setString(tostring(self.objItem:GetLevel()))

	--设置卡牌的图标
	local ninjainfo = DataMgr.GetDataByID("Struct_Ninjainfo", tonumber(self.objItem:GetDataID()))
	local pFrameSprite = CGameObjElement:GetNinjaFrame(E_FRAMETYPE_SMALL, ninjainfo.m_quality)
	local pIconFrame = CGameObjElement:GetNinjaIcon(E_FRAMETYPE_SMALL, ninjainfo.m_ninjaicon)
	local sprite1 = CCSprite:createWithSpriteFrame(pIconFrame)
	sprite1:setPosition(ccp(0,0))
	sprite1:setAnchorPoint(ccp(0,0))
	self.sprite_ninjaicon:setDisplayFrame(pFrameSprite)
	self.node_icon:addChild(sprite1)

	--卡牌背景动画
	local strengthlevel = self.objItem:GetStrengthLevel()
	CGameObjElement:SetFrameShadowBack(self.node_shadow_back:getContentSize(),self.node_shadow_back, strengthlevel, ninjainfo.m_level)
	CGameObjElement:SetFrameShadowFront(self.node_shadow_front:getContentSize(),self.node_shadow_front, strengthlevel, ninjainfo.m_level)

	--设置是否转生
	local newlife =  self.objItem:GetReincarnationLevel()	
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
	self.label_name:setString(self.objItem:GetName())

	--设置国家标志
	local county_icon_index = self.objItem:GetCardCamp()
	local frame1 = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(tools.getAttributeIcon(county_icon_index))
	if frame1 ~= nil then
		self.sprite_ninjacamp:setDisplayFrame(frame1)
	end

	--设置攻防，查克拉属性
	local attack_current_plus = 0
	local defense_current_plus = 0
	local chakra_current_plus = 0
	local attackmin = self.objItem:GetAttackMin()
	local attackmax = self.objItem:GetAttackMax()
	local defensemin = self.objItem:GetDefenseMin()
	local defensemax = self.objItem:GetDefenseMax()
	local chakramin = self.objItem:GetChakraMin()
	local chakramax = self.objItem:GetChakraMax()
	
	if strengthlevel ~= 0 then
		local strengthconfig = DataMgr.GetDataByID("Struct_Ninjastrengthconfig", strengthlevel)
		local ratio = strengthconfig.m_addprop / 2
		attack_current_plus = (attackmin + attackmax) * ratio
		defense_current_plus = (defensemin + defensemax) * ratio
		chakra_current_plus = (chakramin + chakramax) * ratio
	end

	self.label_attack:setString(string.format("%d-%d", attackmin + attack_current_plus, attackmax + attack_current_plus))
	self.label_defense:setString(string.format("%d-%d", defensemin + defense_current_plus, defensemax + defense_current_plus))
	--self.label_chakra:setString(string.format("%d-%d", chakramin + chakra_current_plus, chakramax + chakra_current_plus))

	--设置卡片星级
	local quality = self.objItem:GetQuality()
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

function onNodeCleanup(self)
    --cclog("onNodeCleanup")
	if self.proxy_ ~= nil then
		self.proxy_:release()
		self.proxy_ = nil
	end
   layer_base_t.onNodeCleanup(self)
end
