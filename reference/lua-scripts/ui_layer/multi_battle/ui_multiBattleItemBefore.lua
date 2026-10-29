--description: 跨服战还未开始时的表格cell
--company：xckoo
--author：chenchun
---------------------------------------------

module("ui_multiBattleItemBefore", package.seeall)
baseClass(layer_base_t, ui_multiBattleItemBefore)

function init(self, cellSize, data)
	local ccbiAttrTable = {name="multiserverbattle/multiBattleItemBefore.ccbi", size=cellSize}
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()
	layer_base_t.init(self, true, ccbiAttrTable)
	self.dataInfo = data
	--self.isBuyTicket = ui_multiServerLayer.gBattleStatus
	self:init_ui()
	self:init_binding_event()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		self.label_name = tolua.cast(self.proxy_:getNode("label_name"), "CCLabelTTF")
		self.label_zone = tolua.cast(self.proxy_:getNode("label_zone"), "CCLabelTTF")
		self.label_rank_or_pos = tolua.cast(self.proxy_:getNode("label_rank_or_pos"), "CCLabelTTF")
		self.label_score_title = tolua.cast(self.proxy_:getNode("label_score_title"), "CCLabelTTF")

		self.label_player_level = tolua.cast(self.proxy_:getNode("label_player_level"),"CCLabelBMFont")
		self.sprite_vip = tolua.cast(self.proxy_:getNode("sprite_vip"), "CCSprite")
		self.sprite_last_rank = tolua.cast(self.proxy_:getNode("sprite_last_rank"), "CCSprite")
		self.label_last_rank = tolua.cast(self.proxy_:getNode("label_last_rank"), "CCLabelBMFont")
		self.label_last_score = tolua.cast(self.proxy_:getNode("label_last_score"), "CCLabelBMFont")
		self.btn_card_info = tolua.cast(self.proxy_:getNode("btn_card_info"), "CCControlButton")
		self.node_icon = tolua.cast(self.proxy_:getNode("node_icon"), "CCNode")
		self.sprite_ninjaicon2 = tolua.cast(self.proxy_:getNode("sprite_ninjaicon2"), "CCSprite")
		self.node_shadow_back = tolua.cast(self.proxy_:getNode("node_shadow_back"), "CCNode")
		self.node_shadow_front = tolua.cast(self.proxy_:getNode("node_shadow_front"), "CCNode")
		self.node_inlay_frame = tolua.cast(self.proxy_:getNode("node_inlay_frame"), "CCNode")
		self.sprite_frame_corner1 = tolua.cast(self.proxy_:getNode("sprite_frame_corner1"), "CCSprite")
		self.sprite_frame_corner2 = tolua.cast(self.proxy_:getNode("sprite_frame_corner2"), "CCSprite")

		self.label_no_rank = tolua.cast(self.proxy_:getNode("label_no_rank"), "CCLabelTTF")
		self.label_no_score = tolua.cast(self.proxy_:getNode("label_no_score"), "CCLabelTTF")
		--[[
		local x, y = self.label_name:getPosition()
		local x1, y1 = self.label_name:getAnchorPoint()
		local pNode = self.label_name:getParent()
		self.label_name:removeFromParentAndCleanup(true)
		self.label_name = CCLabelTTFWithStroke:create("12345", "汉仪粗圆简.ttf", 40, ccc3(255, 0, 0), ccc3(0, 0, 0), CCSizeMake(0, -1), 0.8)
		self.label_name:setAnchorPoint(ccp(x, y))
		self.label_name:setPosition(x, y)
		pNode:addChild(self.label_name)
		]]

		local rank_or_pos  --根据具体情况，该变量保存不同的值：排名或者位置
		if ui_multiServerLayer.gBattleStatus == 1 then
			self.label_rank_or_pos:setString(localizable.ui_multi_position)
			self.label_score_title:setString(localizable.ui_multi_last_score)
			rank_or_pos = self.dataInfo.posid
		else
			rank_or_pos = self.dataInfo.rank
			self.label_rank_or_pos:setString(localizable.ui_multi_last_rank)
			--rank_or_pos = self.dataInfo.posid
		end

		self.label_zone:setString(string.format(localizable.ui_multi_region, self.dataInfo.zone))
		self.label_name:setString(self.dataInfo.name)


		if self.dataInfo.score == "0" then
			--self.label_last_score:setVisible(false)
			--self.label_no_score:setVisible(true)
			self.label_last_score:setString(self.dataInfo.score)
		else
			self.label_last_score:setString(self.dataInfo.score)
		end
		self.label_player_level:setString(self.dataInfo.playerlevel)

		local viplevel = tonumber(self.dataInfo.viplevel)
		local vipframes={[0] = "vip_015",[1]="vip_003",[2]="vip_004",[3]="vip_005",[4]="vip_006",
			[5]="vip_007",[6]="vip_008",[7]="vip_009",[8]="vip_010",[9]="vip_011",[10]="vip_012",[11]="vip_013",[12]="vip_014",[13]="vip_s_13",[14] = "vip_s_14",[15] = "vip_s_15",[16]="vip_s_16",[17]="vip_s_17",[18]="vip_s_18"}
		if self.sprite_vip ~= nil then
			local pFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(vipframes[viplevel])
			self.sprite_vip:setDisplayFrame(pFrame)
		end

		--设置上期排名
		if rank_or_pos == "1" then
			local pFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("Inter_service_011")
			self.sprite_last_rank:setDisplayFrame(pFrame)
			self.label_last_rank:setVisible(false)
		elseif rank_or_pos == "2" then
			local pFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("Inter_service_012")
			self.sprite_last_rank:setDisplayFrame(pFrame)
			self.label_last_rank:setVisible(false)
		elseif rank_or_pos == "3" then
			local pFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("Inter_service_013")
			self.sprite_last_rank:setDisplayFrame(pFrame)
			self.label_last_rank:setVisible(false)
		else
			self.sprite_last_rank:setVisible(false)
			self.label_last_rank:setVisible(true)
		end

		if ui_multiServerLayer.gBattleStatus == 1 then
			self.label_last_rank:setString(rank_or_pos)
		else
			self.label_last_rank:setString(rank_or_pos)
			--self.label_last_rank:setVisible(false)
			--self.sprite_last_rank:setVisible(false)
			--self.label_no_rank:setVisible(true)
		end

		--设置卡牌的图标
		local ninjainfo = DataMgr.GetDataByID("Struct_Ninjainfo", tonumber(self.dataInfo.cardInfo.id))
		local pFrameSprite = CGameObjElement:GetNinjaFrame(E_FRAMETYPE_SMALL, ninjainfo.m_quality)
		local pIconFrame = CGameObjElement:GetNinjaIcon(E_FRAMETYPE_SMALL, ninjainfo.m_ninjaicon)
		local sprite1 = CCSprite:createWithSpriteFrame(pIconFrame)
		sprite1:setPosition(ccp(0,0))
		sprite1:setAnchorPoint(ccp(0,0))
		self.sprite_ninjaicon2:setDisplayFrame(pFrameSprite)
		self.node_icon:addChild(sprite1)

		--卡牌背景动画
		CGameObjElement:SetFrameShadowBack(self.node_shadow_back:getContentSize(),self.node_shadow_back, tonumber(self.dataInfo.cardInfo.strength), ninjainfo.m_level)
		CGameObjElement:SetFrameShadowFront(self.node_shadow_front:getContentSize(),self.node_shadow_front, tonumber(self.dataInfo.cardInfo.strength), ninjainfo.m_level)

		--设置是否转生
		self.node_inlay_frame:setVisible(true)
		local topinlayframe = CGameObjElement:GetTopInlayFrame(E_FRAMETYPE_SMALL, tonumber(self.dataInfo.cardInfo.life))
		if topinlayframe ~= nil then
			self.sprite_frame_corner1:setDisplayFrame(topinlayframe)
			self.sprite_frame_corner1:setVisible(true)
		else
			self.sprite_frame_corner1:setVisible(false)
		end

		local downinlayframe = CGameObjElement:GetDownInlayFrame(E_FRAMETYPE_SMALL, tonumber(self.dataInfo.cardInfo.life))
		if downinlayframe ~= nil then
			self.sprite_frame_corner2:setDisplayFrame(downinlayframe)
			self.sprite_frame_corner2:setVisible(true)
		else
			self.sprite_frame_corner2:setVisible(false)
		end

	end
end

function init_binding_event(self)
	if self.proxy_ ~= nil then

		local function get_card_info(btn)
			--cclog("1111---get_card_info")
			GetMainMenu():ShowTextTip(localizable.ui_multi_not_open_team_info, -1)
			--local compareView = createObj(ui_multiTeamCompareView, self.dataInfo.id, tonumber(self.dataInfo.zone))
			--GetMainMenu():GetModelLayer():AddDialog(compareView.node_, 3)
		end

		self.btn_card_info:setTouchPriority(-2)
		self.proxy_:handleControlEvent(self.btn_card_info, get_card_info, CCControlEventTouchUpInside)
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