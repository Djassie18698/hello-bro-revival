--description: 跨服战还未开始时的表格cell
--company：xckoo
--author：chenchun
---------------------------------------------

module("ui_multiBattlingItem", package.seeall)
baseClass(layer_base_t, ui_multiBattlingItem)

function init(self, cellSize, myinfo, otherinfo, parentObj)
	local ccbiAttrTable = {name="multiserverbattle/multiBattlingItem.ccbi", size=cellSize}
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()
	layer_base_t.init(self, true, ccbiAttrTable)

	self.playerInfo = myinfo
	self.otherInfo = otherinfo
	self.parentObj = parentObj

	self:init_ui()
	self:init_binding_event()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		self.sprite_itemback = tolua.cast(self.proxy_:getNode("sprite_itemback"), "CCSprite")
		self.label_name = tolua.cast(self.proxy_:getNode("label_name"), "CCLabelTTF")
		self.label_zone = tolua.cast(self.proxy_:getNode("label_zone"), "CCLabelTTF")
		self.sprite_vip = tolua.cast(self.proxy_:getNode("sprite_vip"), "CCSprite")

		self.sprite_rank = tolua.cast(self.proxy_:getNode("sprite_rank"), "CCSprite")
		self.label_player_level = tolua.cast(self.proxy_:getNode("label_player_level"),"CCLabelBMFont")
		self.label_rank = tolua.cast(self.proxy_:getNode("label_rank"), "CCLabelBMFont")
		self.label_score = tolua.cast(self.proxy_:getNode("label_score"), "CCLabelBMFont")
		self.label_time_score = tolua.cast(self.proxy_:getNode("label_time_score"), "CCLabelTTF")

		self.node_icon = tolua.cast(self.proxy_:getNode("node_icon"), "CCNode")
		self.sprite_ninjaicon2 = tolua.cast(self.proxy_:getNode("sprite_ninjaicon2"), "CCSprite")
		self.node_shadow_back = tolua.cast(self.proxy_:getNode("node_shadow_back"), "CCNode")
		self.node_shadow_front = tolua.cast(self.proxy_:getNode("node_shadow_front"), "CCNode")
		self.node_inlay_frame = tolua.cast(self.proxy_:getNode("node_inlay_frame"), "CCNode")
		self.sprite_frame_corner1 = tolua.cast(self.proxy_:getNode("sprite_frame_corner1"), "CCSprite")
		self.sprite_frame_corner2 = tolua.cast(self.proxy_:getNode("sprite_frame_corner2"), "CCSprite")

		self.btn_add_vs_info = tolua.cast(self.proxy_:getNode("btn_add_vs_info"), "CCControlButton")


		self.label_zone:setString(string.format(localizable.ui_multi_region, self.otherInfo.zone))
		self.label_name:setString(self.otherInfo.name)
		self.label_rank:setString(self.otherInfo.posid)
		self.label_score:setString(self.otherInfo.score)
		self.label_time_score:setString("(+" .. tostring(self.otherInfo.addscore) ..localizable.ui_multi_acc_score .. tostring(self.otherInfo.timeval) .. localizable.ui_multi_time_sec .. ")")
		self.label_player_level:setString(self.otherInfo.playerlevel)
		self:init_control_data()
		--self.proxy_:handleControlEvent(self.btn_card_info, btn_vs_player, CCControlEventTouchUpInside)
	end
end

function init_binding_event(self)
	if self.proxy_ ~= nil then

		local function btn_vs()
			if self.playerInfo.isin == "1" then
				local urlpath = GetMultiBattleHeader(self.playerData_.m_uid, 1, protocol.URL_W_CWAR_WAR)
				urlpath = AddData(urlpath, "Pos", self.otherInfo.posid)
				cclog("1111----urlpath:%s", urlpath)
				GetMainMenu():ShowLoadingDlg();	-- 获取信息的时候，不允许操作
				CCHttpRequest:open(urlpath, kHttpPost,"query=param1&other=params"):sendWithHandler(
					function(res, hnd)
						GetMainMenu():CloseLoadding(); --获取信息完成时，解除禁止操作
						local resData = res:getResponseData()
						cclog("1111----resData:%s", resData)
						local code = res:getResponseCode()
						local xfile = xml.parse(resData)
						local item = xfile:find("RENLONG")
						if item == nil then
							return nil
						end
						local retcode = item.code
						if retcode == "0" then
							GetMainMenu():ShowArenaView(resData)

							--local result = item:find("cwar").result
							local newListItem = item:find("newlist")

                            --玩家信息
							local userItem = newListItem:find("user")
							if #userItem > 0 then
								self.parentObj:playerInfoForSelf(userItem)
							end
							--解析其他玩家信息
							local otherItem = newListItem:find("positionlist")
							self.parentObj:playerInfoForOther(otherItem)

							self.parentObj:update_all_ui()
							--GetMainMenu():ShowTextTip("领取成功",-1)
						else
							GetMainMenu():ShowErrorTip(tonumber(retcode), -1)
						end
					end)
			else
				GetMainMenu():ShowTextTip(localizable.ui_multi_not_qualification_enter, -1)
			end
		end

		self.btn_add_vs_info:setTouchPriority(-2)
		self.proxy_:handleControlEvent(self.btn_add_vs_info, btn_vs, CCControlEventTouchUpInside)
	end
end


function init_control_data(self)
	--设置上期排名
	if self.otherInfo.posid == "1" then
		local pFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("Inter_service_011")
		self.sprite_rank:setDisplayFrame(pFrame)
		self.label_rank:setVisible(false)
	elseif self.otherInfo.posid == "2" then
		local pFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("Inter_service_012")
		self.sprite_rank:setDisplayFrame(pFrame)
		self.label_rank:setVisible(false)
	elseif self.otherInfo.posid == "3" then
		local pFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("Inter_service_013")
		self.sprite_rank:setDisplayFrame(pFrame)
		self.label_rank:setVisible(false)
	else
		self.sprite_rank:setVisible(false)
		self.label_rank:setVisible(true)
	end

	local viplevel = tonumber(self.otherInfo.viplevel)
	local vipframes={[0] = "vip_015",[1]="vip_003",[2]="vip_004",[3]="vip_005",[4]="vip_006",
		[5]="vip_007",[6]="vip_008",[7]="vip_009",[8]="vip_010",[9]="vip_011",[10]="vip_012",[11]="vip_013",[12]="vip_014",[13]="vip_s_13",[14] = "vip_s_14",[15] = "vip_s_15",[16]="vip_s_16",[17]="vip_s_17",[18]="vip_s_18"}
	if self.sprite_vip ~= nil then
		local pFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(vipframes[viplevel])
		self.sprite_vip:setDisplayFrame(pFrame)
	end

	--设置卡牌的图标
	local ninjainfo = DataMgr.GetDataByID("Struct_Ninjainfo", tonumber(self.otherInfo.cardInfo.id))
	local pFrameSprite = CGameObjElement:GetNinjaFrame(E_FRAMETYPE_SMALL, ninjainfo.m_quality)
	local pIconFrame = CGameObjElement:GetNinjaIcon(E_FRAMETYPE_SMALL, ninjainfo.m_ninjaicon)
	local sprite1 = CCSprite:createWithSpriteFrame(pIconFrame)
	sprite1:setPosition(ccp(0,0))
	sprite1:setAnchorPoint(ccp(0,0))
	self.sprite_ninjaicon2:setDisplayFrame(pFrameSprite)
	self.node_icon:addChild(sprite1)

	--卡牌背景动画
	CGameObjElement:SetFrameShadowBack(self.node_shadow_back:getContentSize(),self.node_shadow_back, tonumber(self.otherInfo.cardInfo.strength), ninjainfo.m_level)
	CGameObjElement:SetFrameShadowFront(self.node_shadow_front:getContentSize(),self.node_shadow_front, tonumber(self.otherInfo.cardInfo.strength), ninjainfo.m_level)

	--设置是否转生
	self.node_inlay_frame:setVisible(true)
	local topinlayframe = CGameObjElement:GetTopInlayFrame(E_FRAMETYPE_SMALL, tonumber(self.otherInfo.cardInfo.life))
	if topinlayframe ~= nil then
		self.sprite_frame_corner1:setDisplayFrame(topinlayframe)
		self.sprite_frame_corner1:setVisible(true)
	else
		self.sprite_frame_corner1:setVisible(false)
	end

	local downinlayframe = CGameObjElement:GetDownInlayFrame(E_FRAMETYPE_SMALL, tonumber(self.otherInfo.cardInfo.life))
	if downinlayframe ~= nil then
		self.sprite_frame_corner2:setDisplayFrame(downinlayframe)
		self.sprite_frame_corner2:setVisible(true)
	else
		self.sprite_frame_corner2:setVisible(false)
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