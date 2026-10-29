--descriptioin:卡的界面
--company: xckoo
--author: chenchun
--date: 2014-03-1４
---------------------------------------------
module("ui_trainNinjaCard", package.seeall)
baseClass(layer_base_t, ui_trainNinjaCard)

function init(self, cellSize,index)
	local ccbiAttrTable = {name="secretshop/trainNinjaCard.ccbi", size=cellSize}
	--local ccbiAttrTable = {name="secretshop/trainNinjaCard.ccbi"}
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()
	layer_base_t.init(self, true, ccbiAttrTable)

	self.guid = 0
	self.index = index
	self:init_ui()
	self:init_binding_event()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		self.label_card_level = tolua.cast(self.proxy_:getNode("label_card_level"),"CCLabelBMFont")
		self.labelSoul = tolua.cast(self.proxy_:getNode("label_soul"),"CCLabelBMFont")
		
		self.node_icon = tolua.cast(self.proxy_:getNode("node_icon"), "CCNode")
		self.sprite_ninjaicon2 = tolua.cast(self.proxy_:getNode("sprite_ninjaicon2"), "CCSprite")
		self.node_shadow_back = tolua.cast(self.proxy_:getNode("node_shadow_back"), "CCNode")
		self.node_shadow_front = tolua.cast(self.proxy_:getNode("node_shadow_front"), "CCNode")
		self.node_inlay_frame = tolua.cast(self.proxy_:getNode("node_inlay_frame"), "CCNode")
		self.sprite_frame_corner1 = tolua.cast(self.proxy_:getNode("sprite_frame_corner1"), "CCSprite")
		self.sprite_frame_corner2 = tolua.cast(self.proxy_:getNode("sprite_frame_corner2"), "CCSprite")

		if self.index > 0 and self.index <= #ui_trainSoulLayer.TrainNinjaList then
			local ninja = ui_trainSoulLayer.TrainNinjaList[self.index]
			self.label_card_level:setString(ninja:GetLevel())
			self.guid = ninja:GetGUID()
			self.labelSoul:setString(0)
			self:init_control_data()
		end
		--self.proxy_:handleControlEvent(self.btn_card_info, btn_vs_player, CCControlEventTouchUpInside)
	end
end

function init_binding_event(self)
	if self.proxy_ ~= nil then

	end
end


function init_control_data(self)
	--设置卡牌的图标
	local ninjainfo = DataMgr.GetDataByID("Struct_Ninjainfo", tonumber(ui_trainSoulLayer.TrainNinjaList[self.index]:GetDataID()))
	local pFrameSprite = CGameObjElement:GetNinjaFrame(E_FRAMETYPE_SMALL, ninjainfo.m_quality)
	local pIconFrame = CGameObjElement:GetNinjaIcon(E_FRAMETYPE_SMALL, ninjainfo.m_ninjaicon)
	local sprite1 = CCSprite:createWithSpriteFrame(pIconFrame)
	sprite1:setPosition(ccp(0,0))
	sprite1:setAnchorPoint(ccp(0,0))
	self.sprite_ninjaicon2:setDisplayFrame(pFrameSprite)
	self.node_icon:addChild(sprite1)

	--卡牌背景动画
	local strengthlevel = ui_trainSoulLayer.TrainNinjaList[self.index]:GetStrengthLevel()
	
	CGameObjElement:SetFrameShadowBack(self.node_shadow_back:getContentSize(),self.node_shadow_back, strengthlevel, ninjainfo.m_level)
	CGameObjElement:SetFrameShadowFront(self.node_shadow_front:getContentSize(),self.node_shadow_front, strengthlevel, ninjainfo.m_level)

	--设置是否转生
	local newlife =  ui_trainSoulLayer.TrainNinjaList[self.index]:GetReincarnationLevel()
	
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

end

function setSoul(self, soullist)
	for i,v in ipairs(soullist) do
		if v.bagid == self.guid then
			self.labelSoul:setString(v.soul)
			return
		end
	end
end

function onNodeCleanup(self)
    --cclog("onNodeCleanup")
    if self.proxy_ then
       self.proxy_:release()
    end
    layer_base_t.onNodeCleanup(self)
end
