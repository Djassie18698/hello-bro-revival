--description: 阵容对比
--company：xckoo
--author：chenchun
---------------------------------------------

module("ui_multiTeamCompareItemView", package.seeall)
baseClass(layer_base_t, ui_multiTeamCompareItemView)

function init(self, cellSize, mydata, otherdata)
	local ccbiAttrTable = {name="dlg_ui/TeamCompareItemViewForMultiBattle.ccbi", size=cellSize}
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()
	layer_base_t.init(self, true, ccbiAttrTable)
	self.mydata = mydata
	self.enemydata = otherdata

	self:init_ui()
	self:init_binding_event()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		self.node_myteam = tolua.cast(self.proxy_:getNode("node_myteam"), "CCNode")
		self.node_enemy = tolua.cast(self.proxy_:getNode("node_enemy"), "CCNode")
		self.sprite_my = tolua.cast(self.proxy_:getNode("sprite_my"), "CCSprite")
		self.sprite_enemy = tolua.cast(self.proxy_:getNode("sprite_enemy"), "CCSprite")
		self.sprite_mycamp = tolua.cast(self.proxy_:getNode("sprite_mycamp"), "CCSprite")
		self.sprite_enemycamp = tolua.cast(self.proxy_:getNode("sprite_enemycamp"), "CCSprite")
		self.node_inlay_frame_my = tolua.cast(self.proxy_:getNode("node_inlay_frame_my"), "CCNode")
		self.node_inlay_frame_enemy = tolua.cast(self.proxy_:getNode("node_inlay_frame_enemy"), "CCNode")
		self.sprite_frame_corner1_my = tolua.cast(self.proxy_:getNode("sprite_frame_corner1_my"), "CCNode")
		self.sprite_frame_corner2_my = tolua.cast(self.proxy_:getNode("sprite_frame_corner2_my"), "CCNode")
		self.sprite_frame_corner1_enemy = tolua.cast(self.proxy_:getNode("sprite_frame_corner1_enemy"), "CCNode")
		self.sprite_frame_corner2_enemy = tolua.cast(self.proxy_:getNode("sprite_frame_corner2_enemy"), "CCNode")
		self.node_my_shadow_back = tolua.cast(self.proxy_:getNode("node_my_shadow_back"), "CCNode")
		self.node_my_shadow_front = tolua.cast(self.proxy_:getNode("node_my_shadow_front"), "CCNode")
		self.node_enemy_shadow_back = tolua.cast(self.proxy_:getNode("node_enemy_shadow_back"), "CCNode")
		self.node_enemy_shadow_front = tolua.cast(self.proxy_:getNode("node_enemy_shadow_front"), "CCNode")
		self.node_myicon = tolua.cast(self.proxy_:getNode("node_myicon"), "CCNode")
		self.node_enemyicon = tolua.cast(self.proxy_:getNode("node_enemyicon"), "CCNode")

		self.label_mylevel = tolua.cast(self.proxy_:getNode("label_mylevel"), "CCLabelBMFont")
		self.label_enemylevel = tolua.cast(self.proxy_:getNode("label_enemylevel"), "CCLabelBMFont")

		self.label_myname = tolua.cast(self.proxy_:getNode("label_myname"), "CCLabelTTF")
		self.label_enemyname = tolua.cast(self.proxy_:getNode("label_enemyname"), "CCLabelTTF")
		self.label_myattack = tolua.cast(self.proxy_:getNode("label_myattack"),"CCLabelTTF")
		self.label_enemyattack = tolua.cast(self.proxy_:getNode("label_enemyattack"),"CCLabelTTF")
		self.label_mydefense = tolua.cast(self.proxy_:getNode("label_mydefense"),"CCLabelTTF")
		self.label_enemydefense = tolua.cast(self.proxy_:getNode("label_enemydefense"),"CCLabelTTF")
		self.label_mychakra = tolua.cast(self.proxy_:getNode("label_mychakra"),"CCLabelTTF")
		self.label_enemychakra = tolua.cast(self.proxy_:getNode("label_enemychakra"),"CCLabelTTF")

		self:init_mydata()

		self:init_enemydata()



	end
end

function init_binding_event(self)
	if self.proxy_ ~= nil then

	end
end

function init_mydata(self)
	if self.mydata ~= nil then

		--设置卡牌的图标
		local ninjainfo = DataMgr.GetDataByID("Struct_Ninjainfo", tonumber(self.mydata.id))
		local pFrameSprite = CGameObjElement:GetNinjaFrame(E_FRAMETYPE_SMALL, ninjainfo.m_quality)
		local pIconFrame = CGameObjElement:GetNinjaIcon(E_FRAMETYPE_SMALL, ninjainfo.m_ninjaicon)
		local sprite1 = CCSprite:createWithSpriteFrame(pIconFrame)
		sprite1:setPosition(ccp(0,0))
		sprite1:setAnchorPoint(ccp(0,0))
		self.sprite_my:setDisplayFrame(pFrameSprite)
		self.node_myicon:addChild(sprite1)

		self.sprite_mycamp:setVisible(false)
		self.label_mylevel:setString(ninjainfo.m_level)
		self.label_myname:setString(ninjainfo.m_ninjaname)

		local strAttack = string.format("%.1f千-%.1f千", tonumber(self.mydata.low) / 1000, tonumber(self.mydata.high) / 1000)
		self.label_myattack:setString(strAttack)
		self.label_mydefense:setString("0")
		local strChackla = string.format("%.1f千-%.1f千", tonumber(self.mydata.chackla_low) / 1000, tonumber(self.mydata.chackla_high) / 1000)
		self.label_mychakra:setString(strChackla)
		--卡牌背景动画
		--CGameObjElement:SetFrameShadowBack(self.node_my_shadow_back:getContentSize(),self.node_my_shadow_back, tonumber(self.mydata.strength), ninjainfo.m_level)
		--CGameObjElement:SetFrameShadowFront(self.node_my_shadow_front:getContentSize(),self.node_my_shadow_front, tonumber(self.mydata.strength), ninjainfo.m_level)

		--设置是否转生
		self.node_inlay_frame_my:setVisible(false)
		--[[
		local topinlayframe = CGameObjElement:GetTopInlayFrame(E_FRAMETYPE_SMALL, tonumber(self.mydata.life))
		if topinlayframe ~= nil then
			self.sprite_frame_corner1_my:setDisplayFrame(topinlayframe)
			self.sprite_frame_corner1_my:setVisible(true)
		else
			self.sprite_frame_corner1_my:setVisible(false)
		end

		local downinlayframe = CGameObjElement:GetDownInlayFrame(E_FRAMETYPE_SMALL, tonumber(self.mydata.life))
		if downinlayframe ~= nil then
			self.sprite_frame_corner2_my:setDisplayFrame(downinlayframe)
			self.sprite_frame_corner2_my:setVisible(true)
		else
			self.sprite_frame_corner2_my:setVisible(false)
		end
		]]
	else
		self.node_myteam:setVisible(false)
	end
end

function init_enemydata(self)
	if self.enemydata ~= nil then

		--设置卡牌的图标
		local ninjainfo = DataMgr.GetDataByID("Struct_Ninjainfo", tonumber(self.enemydata.id))
		local pFrameSprite = CGameObjElement:GetNinjaFrame(E_FRAMETYPE_SMALL, ninjainfo.m_quality)
		local pIconFrame = CGameObjElement:GetNinjaIcon(E_FRAMETYPE_SMALL, ninjainfo.m_ninjaicon)
		local sprite1 = CCSprite:createWithSpriteFrame(pIconFrame)
		sprite1:setPosition(ccp(0,0))
		sprite1:setAnchorPoint(ccp(0,0))
		self.sprite_enemy:setDisplayFrame(pFrameSprite)
		self.node_enemyicon:addChild(sprite1)

		self.sprite_enemycamp:setVisible(false)
		self.label_enemylevel:setString(ninjainfo.m_level)
		self.label_enemyname:setString(ninjainfo.m_ninjaname)

		local strDefense = string.format("%.1f千-%.1f千", tonumber(self.enemydata.low) / 1000, tonumber(self.enemydata.high) / 1000)
		self.label_enemyattack:setString("0")
		self.label_enemydefense:setString(strDefense)
		local strChackla = string.format("%.1f千-%.1f千", tonumber(self.enemydata.chackla_low) / 1000, tonumber(self.enemydata.chackla_high) / 1000)
		self.label_enemychakra:setString(strChackla)
		--卡牌背景动画
		--CGameObjElement:SetFrameShadowBack(self.node_enemy_shadow_back:getContentSize(),self.node_enemy_shadow_back, tonumber(self.enemydata.strength), ninjainfo.m_level)
		--CGameObjElement:SetFrameShadowFront(self.node_enemy_shadow_front:getContentSize(),self.node_enemy_shadow_front, tonumber(self.enemydata.strength), ninjainfo.m_level)

		--设置是否转生
		self.node_inlay_frame_enemy:setVisible(false)
		--[[
		local topinlayframe = CGameObjElement:GetTopInlayFrame(E_FRAMETYPE_SMALL, tonumber(self.enemydata.life))
		if topinlayframe ~= nil then
			self.sprite_frame_corner1_enemy:setDisplayFrame(topinlayframe)
			self.sprite_frame_corner1_enemy:setVisible(true)
		else
			self.sprite_frame_corner1_enemy:setVisible(false)
		end

		local downinlayframe = CGameObjElement:GetDownInlayFrame(E_FRAMETYPE_SMALL, tonumber(self.enemydata.life))
		if downinlayframe ~= nil then
			self.sprite_frame_corner2_enemy:setDisplayFrame(downinlayframe)
			self.sprite_frame_corner2_enemy:setVisible(true)
		else
			self.sprite_frame_corner2_enemy:setVisible(false)
		end
		]]
	else
		self.node_enemy:setVisible(false)
	end
end
function onNodeCleanup(self)
    --cclog("onNodeCleanup")
    --[[
    if self.node_:retainCount() == 1 then
        self.proxy_:release()
    end
    ]]
    layer_base_t.onNodeCleanup(self)
end