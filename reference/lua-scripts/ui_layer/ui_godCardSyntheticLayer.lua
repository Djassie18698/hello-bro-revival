--descriptioin:神卡合成
--company: xckoo
--author: litao
--date: 2014.6.9
---------------------------------------------
module("ui_godCardSyntheticLayer", package.seeall)
baseClass(layer_base_t, ui_godCardSyntheticLayer)

function init(self, card_bag_id)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	self.contentSize_ = GetMainMenu():GetSubContentNode():getContentSize()
	local ccbiAttrTable = {name="sub_ui/GodCardSyntheticView.ccbi", size=self.contentSize_}
	layer_base_t.init(self, true, ccbiAttrTable)

	--select card
    self.objItem_att = nil
    self.objItem_def = nil
    self.m_cur_bag_id = -1
	--pre
	self.back_page = E_DEFAULTMENU

    --data
    self.preNode = node
    self.m_datas = {}
    self.m_ninjaList = {}
    --att list
    self.m_att_ninjaList = {}
    --def list
    self.m_def_ninjaList = {}
    --新神卡掉落id
    self.m_newCard_drop_id = nil

    --所选卡牌的类型1.att 2.def 3.god
    self.sel_card_type = 0
    --丹总数
    self.cost_prop = 0
    self.prop_count = 0

    --init
	self:init_ui()
	self:init_binding_event()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		--node
		self.node_card_shadow_back_god = tolua.cast(self.proxy_:getNode("node_shadow_back_god"), "CCNode")

		self.node_card_icon_god = tolua.cast(self.proxy_:getNode("layer_icon_god"), "CCNode")

		self.node_card_shadow_front_god = tolua.cast(self.proxy_:getNode("node_shadow_front_god"), "CCNode")

		self.node_card_inlay_frame_god = tolua.cast(self.proxy_:getNode("node_inlay_frame_god"), "CCNode")
		self.node_card_inlay_frame_att = tolua.cast(self.proxy_:getNode("node_inlay_frame_att"), "CCNode")
		self.node_card_inlay_frame_def = tolua.cast(self.proxy_:getNode("node_inlay_frame_def"), "CCNode")

		self.node_anim_container = tolua.cast(self.proxy_:getNode("node_anim_container"), "CCNode")
		--label
		self.label_dan_cost = tolua.cast(self.proxy_:getNode("label_dan_cost"), "CCLabelBMFont")
		self.label_dan_count = tolua.cast(self.proxy_:getNode("label_dan_count"), "CCLabelBMFont")

		self.label_card_ninja_lv_att = tolua.cast(self.proxy_:getNode("label_lv_att"), "CCLabelBMFont")
		self.label_card_ninja_lv_def = tolua.cast(self.proxy_:getNode("label_lv_def"), "CCLabelBMFont")
		self.label_card_ninja_lv_god = tolua.cast(self.proxy_:getNode("label_ninja_level_god"), "CCLabelBMFont")
		--btn
		self.btn_back = tolua.cast(self.proxy_:getNode("btn_back"), "CCControlButton")
		self.btn_readme = tolua.cast(self.proxy_:getNode("btn_readMe"), "CCControlButton")
		self.btn_select_card_att = tolua.cast(self.proxy_:getNode("btn_select_card_att"), "CCControlButton")
		self.btn_select_card_def = tolua.cast(self.proxy_:getNode("btn_select_card_def"), "CCControlButton")

		self.btn_synthetic = tolua.cast(self.proxy_:getNode("btn_ok"), "CCControlButton")
		self.btn_god = tolua.cast(self.proxy_:getNode("btn_god"), "CCControlButton")

		self.btn_click_dan = tolua.cast(self.proxy_:getNode("btn_click_dan"), "CCControlButton")
		--spr
		self.spr_dan_icon = tolua.cast(self.proxy_:getNode("spr_dan_icon"), "CCSprite")

		self.spr_ninja_icon_att = tolua.cast(self.proxy_:getNode("spr_ninja_icon_att"), "CCSprite")
		self.spr_ninja_icon_def = tolua.cast(self.proxy_:getNode("spr_ninja_icon_def"), "CCSprite")
		self.spr_ninja_icon_god = tolua.cast(self.proxy_:getNode("sprite_ninja_icon_god"), "CCSprite")

		self.spr_frame_corner1_god = tolua.cast(self.proxy_:getNode("sprite_frame_corner1_god"), "CCSprite")
		self.spr_frame_corner2_god = tolua.cast(self.proxy_:getNode("sprite_frame_corner2_god"), "CCSprite")

		self.spr_frame_corner1_att = tolua.cast(self.proxy_:getNode("sprite_frame_corner1_att"), "CCSprite")
		self.spr_frame_corner2_att = tolua.cast(self.proxy_:getNode("sprite_frame_corner2_att"), "CCSprite")

		self.spr_frame_corner1_def = tolua.cast(self.proxy_:getNode("sprite_frame_corner1_def"), "CCSprite")
		self.spr_frame_corner2_def = tolua.cast(self.proxy_:getNode("sprite_frame_corner2_def"), "CCSprite")

		self.spr_dragon_icon_god = tolua.cast(self.proxy_:getNode("sprite_dragon_icon_god"), "CCSprite")
		for i=1,5 do
			self["spr_star_"..i.."_god"] = tolua.cast(self.proxy_:getNode("sprite_star0"..i.."_god"), "CCSprite")
		end
		self.spr_add_big_att = tolua.cast(self.proxy_:getNode("spr_add_big_att"), "CCSprite")
		self.spr_add_big_def = tolua.cast(self.proxy_:getNode("spr_add_big_def"), "CCSprite")
		self.spr_lv_att = tolua.cast(self.proxy_:getNode("spr_lv_att"), "CCSprite")
		self.spr_lv_def = tolua.cast(self.proxy_:getNode("spr_lv_def"), "CCSprite")
		--init
		self:initTopBar()
		self:init_ext_topBar()
		--pre base info request
		self:preBaseInfoRequest()
		--init info
		self:init_ext_ui()
		self:getNinjaListForChange()
	end
end

function initTopBar(self)
	if self.proxy_ ~= nil then
		self.sprite_playermedal = tolua.cast(self.proxy_:getNode("sprite_playermedal"), "CCSprite")
		self.label_level = tolua.cast(self.proxy_:getNode("label_level"), "CCLabelBMFont")
		self.label_curexp = tolua.cast(self.proxy_:getNode("label_curexp"), "CCLabelBMFont")
		self.label_name = tolua.cast(self.proxy_:getNode("label_name"), "CCLabelTTF")
		self.sprite_vipinfo = tolua.cast(self.proxy_:getNode("sprite_vipinfo"), "CCSprite")
		self.label_bodyval = tolua.cast(self.proxy_:getNode("label_bodyval"), "CCLabelBMFont")
		self.label_attackval = tolua.cast(self.proxy_:getNode("label_attackval"), "CCLabelBMFont")
		self.label_goldval = tolua.cast(self.proxy_:getNode("label_goldval"), "CCLabelBMFont")
		self.label_silverval = tolua.cast(self.proxy_:getNode("label_silverval"), "CCLabelBMFont")
		self.ctrl_btnplayermsg = tolua.cast(self.proxy_:getNode("ctrl_btnplayermsg"), "CCControlButton")
		self.sprite_levelstate = tolua.cast(self.proxy_:getNode("sprite_levelstate"), "CCSprite")
		self.sprite_bodyratio = tolua.cast(self.proxy_:getNode("sprite_bodyratio"), "CCSprite")
		self.sprite_attackratio = tolua.cast(self.proxy_:getNode("sprite_attackratio"), "CCSprite")
	end
end

function preBaseInfoRequest(self)
	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 20, "rl_r_comm")
	urlpath = AddData(urlpath, "AttackCardBagIndex", tostring(-1))
	cclog("pre rl_r_comm & cmd = 8 & url = %s", urlpath)
	GetMainMenu():ShowLoadingDlg()
	CCHttpRequest:open(urlpath, kHttpPost, "query=param1&other=params"):sendWithHandler(
		function(res, hnd)
			GetMainMenu():CloseLoadding()
			local resData = res:getResponseData()
			local code = res:getResponseCode()
			local xfile = xml.parse(resData)
			local item = xfile:find("RENLONG")
			if item == nil then
				return nil
			end
			cclog("%s", resData)
			local retcode = item.code
			if retcode == "0" then
				---[[	
				--进化丹总数
				local _basic = xfile:find("basic")
				if nil ~= _basic then
    				self.prop_count = tonumber(_basic:find("prop_num")[1])
    				self.label_dan_count:setString(tostring(self.prop_count))
				end

			else
				GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
			end
		end)
end

--人物信息
function init_ext_topBar(self)
	if self.proxy_ ~= nil then
		local meritIcon = self.playerMgr_:GetMeritIcon()
		if meritIcon ~= nil then
			local pFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(meritIcon)
			if pFrame ~= nil then
				self.sprite_playermedal:setDisplayFrame(pFrame)
			end
		end
		--exp
		self.label_name:setString(self.playerData_.m_name)
		local nextExp = self.playerMgr_:GetNextLevelExp()
		local expStr = tostring(self.playerData_.m_exp) .. "/" .. tostring(nextExp)
		self.label_curexp:setString(expStr)
		self.sprite_levelstate:setScaleX(self.playerData_.m_exp / nextExp)

		--vipinfo
		local viplevel = self.playerData_.m_viplevel
		local vipframes={[0] = "vip_015",[1]="vip_003",[2]="vip_004",[3]="vip_005",[4]="vip_006",
			[5]="vip_007",[6]="vip_008",[7]="vip_009",[8]="vip_010",[9]="vip_011",[10]="vip_012",[11]="vip_013",[12]="vip_014",[13]="vip_s_13",[14] = "vip_s_14",[15] = "vip_s_15",[16]="vip_s_16",[17]="vip_s_17",[18]="vip_s_18"}
		if self.sprite_vipinfo ~= nil then
			local pFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(vipframes[viplevel])
			self.sprite_vipinfo:setDisplayFrame(pFrame)
		end

		--bodyval
		local maxbodyval = self.playerMgr_:GetMaxBodyValue()
		local bodyValStr = tostring(self.playerData_.m_bodyvalue) .. "/" .. tostring(maxbodyval)
		self.label_bodyval:setString(bodyValStr)
		local scaleVal = self.playerData_.m_bodyvalue / maxbodyval
		if scaleVal > 1 then
			scaleVal = 1
		end
		self.sprite_bodyratio:setScaleX(scaleVal)

		--attack
		local maxattack = self.playerMgr_:GetMaxAttackCount()
		local attackValStr = tostring(self.playerData_.m_fightcount) .. "/" .. tostring(maxattack)
		self.label_attackval:setString(attackValStr)
		self.sprite_attackratio:setScaleX(self.playerData_.m_fightcount / maxattack)

		--gold & silver
		self.label_goldval:setString(tostring(self.playerData_.m_gold))
		self.label_silverval:setString(tostring(self.playerData_.m_silver))
		self.label_level:setString(tostring(self.playerData_.m_level))
	end
end

function init_ext_ui(self)
	--未选择卡牌
	if nil == self.objItem_att and nil == self.objItem_def then
		self.spr_ninja_icon_god:setVisible(false)
		self.spr_lv_att:setVisible(false)
		self.spr_lv_def:setVisible(false)
		self.label_card_ninja_lv_att:setVisible(false)
		self.label_card_ninja_lv_def:setVisible(false)
	end
	--隐藏转生图标
	self.node_card_inlay_frame_att:setVisible(false)
	self.node_card_inlay_frame_def:setVisible(false)
	--攻卡点击选择呼吸动画
	local move = CCScaleBy:create(0.2, 1.1)
	local array = CCArray:create()
	array:addObject(move)
	array:addObject(move:reverse())
	array:addObject(move)
	array:addObject(move:reverse())
	array:addObject(CCDelayTime:create(1.5))
	local forever = CCRepeatForever:create(CCSequence:create(array))
	self.spr_add_big_att:runAction(forever)
	--防卡点击选择呼吸动画
	local move1 = CCScaleBy:create(0.2, 1.1)
	local array1 = CCArray:create()
	array1:addObject(move1)
	array1:addObject(move1:reverse())
	array1:addObject(move1)
	array1:addObject(move1:reverse())
	array1:addObject(CCDelayTime:create(1.5))
	local forever1 = CCRepeatForever:create(CCSequence:create(array1))
	self.spr_add_big_def:runAction(forever1)
	--丹数量x/xx
	self.label_dan_count:setString(tostring(self.prop_count))
	self.label_dan_cost:setString(tostring("0"))
	--丹图片
	CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile("props/props_229.plist")
	local pFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("props_229")
	if pFrame ~= nil then
		local pIcon = CCSprite:createWithSpriteFrame(pFrame);
		local size = self.spr_dan_icon:getContentSize()
		if pIcon ~= nil then
			self.spr_dan_icon:addChild(pIcon)
			pIcon:setPosition(ccp(size.width/2, size.height/2))
			pIcon:setAnchorPoint(ccp(0.5, 0.5))
		end
	end
end

function playAnim(self)
	--准备播放动画
	---[[
	local pre_animLayer = self.node_anim_container:getChildByTag(100)
	if pre_animLayer then
		pre_animLayer:removeFromParentAndCleanup(true)
	end

	local _iconSize = self.node_anim_container:getContentSize()
	self.m_animLayer = createObj(ui_godCardSyntheticAnim, _iconSize)

	self.node_anim_container:addChild(self.m_animLayer.node_)

	self.m_animLayer.node_:setPosition(ccp(-_iconSize.width * 0.4, -_iconSize.height * 0.8))
	self.m_animLayer.node_:setAnchorPoint(ccp(0.5, 0.5))
	self.m_animLayer.node_:setTag(100)
	--]]
end

function updateUI(self, _newGodCard)
	--gold & silver
	self.label_goldval:setString(tostring(self.playerData_.m_gold))
	self.label_silverval:setString(tostring(self.playerData_.m_silver))
	self.label_level:setString(tostring(self.playerData_.m_level))
	--丹
	local _dan_count = self.prop_count - self.cost_prop
	self.label_dan_count:setString(tostring(_dan_count))
	self.label_dan_cost:setString(tostring("0"))
	--灰化神卡消失
	if self.node_card_icon_god:getChildByTag(100) then
		self.node_card_icon_god:removeChildByTag(100, true)
	end
	--添加新神卡
	local _t_card = {}
	_t_card.pIcon, _t_card.pFrame, _t_card.quality = rl_get_iconsprite(1, _newGodCard.subtype, E_FRAMETYPE_MIDDLE, _newGodCard.id)

	local _size = self.node_card_icon_god:getContentSize()
	_t_card.pIcon:setPosition(ccp(_size.width * 0.5, _size.height * 0.5))
	_t_card.pIcon:setAnchorPoint(ccp(0.5, 0.5))
	_t_card.pIcon:setScale(0.5)
	--add child
	self.node_card_icon_god:addChild(_t_card.pIcon, 1, 100)
	--frame
	local pFrameSprite = CGameObjElement:GetNinjaFrame(E_FRAMETYPE_MIDDLE, _t_card.quality)
	if nil ~= pFrameSprite then
		self.spr_ninja_icon_god:setDisplayFrame(pFrameSprite)
	else
		pFrameSprite = CGameObjElement:GetNinjaFrame(E_FRAMETYPE_MIDDLE, 6)
		self.spr_ninja_icon_god:setDisplayFrame(pFrameSprite)
	end
	--bg
	--CGameObjElement:SetFrameShadowBack(self.node_card_shadow_back_god:getContentSize(),self.node_card_shadow_back_god, _newGodCard.m_strengthLevel, ninjainfo.m_level)
	--CGameObjElement:SetFrameShadowFront(self.node_card_shadow_front_god:getContentSize(),self.node_card_shadow_front_god, _newGodCard.m_strengthLevel, ninjainfo.m_level)
	--设置是否转生
	local newlife =  _newGodCard.m_reincarnationLevel
	self.node_card_inlay_frame_god:setVisible(true)
	local topinlayframe = CGameObjElement:GetTopInlayFrame(E_FRAMETYPE_MIDDLE, newlife)
	if topinlayframe ~= nil then
		self.spr_frame_corner1_god:setDisplayFrame(topinlayframe)
		self.spr_frame_corner1_god:setVisible(true)
	else
		self.spr_frame_corner1_god:setVisible(false)
	end

	local downinlayframe = CGameObjElement:GetDownInlayFrame(E_FRAMETYPE_MIDDLE, newlife)
	if downinlayframe ~= nil then
		self.spr_frame_corner2_god:setDisplayFrame(downinlayframe)
		self.spr_frame_corner2_god:setVisible(true)
	else
		self.spr_frame_corner2_god:setVisible(false)
	end

	local dragon_icon_frame = CGameObjElement:GetFrameDragon(E_FRAMETYPE_MIDDLE, newlife)
	if dragon_icon_frame ~= nil then
		self.spr_dragon_icon_god:setDisplayFrame(dragon_icon_frame)
		self.spr_dragon_icon_god:setVisible(true)
	else
		self.spr_dragon_icon_god:setVisible(false)
	end
	--移除攻防卡
	self.node_card_inlay_frame_att:setVisible(false)
	self.node_card_inlay_frame_def:setVisible(false)

	self.spr_lv_att:setVisible(false)
	self.label_card_ninja_lv_att:setVisible(false)
	self.spr_lv_def:setVisible(false)
	self.label_card_ninja_lv_def:setVisible(false)
	if self.spr_ninja_icon_att:getChildByTag(100) then
		self.spr_ninja_icon_att:removeChildByTag(100, true)
	end
	if self.spr_ninja_icon_def:getChildByTag(100) then
		self.spr_ninja_icon_def:removeChildByTag(100, true)
	end
	--移除背包的攻防卡
	CPlayerDataMgr:instance():RemoveObjByID(self.objItem_att:GetGUID())
	CPlayerDataMgr:instance():RemoveObjByID(self.objItem_def:GetGUID())
	--
	self.objItem_att = nil
	self.objItem_def = nil
	--重新拉取列表
	self:getNinjaListForChange()
end

function updatePreSynthetic(self)
	self.label_dan_count:setString(tostring(self.prop_count))
	self.label_dan_cost:setString(tostring(self.cost_prop))
end

function updateGodCardLevel(self)
	-- body
	local nLevel = 1
	if self.objItem_att ~= nil then
		nLevel = self.objItem_att:GetLevel()
	end

	if self.objItem_def ~= nil then
		if nLevel < self.objItem_def:GetLevel() then
			nLevel = self.objItem_def:GetLevel()
		end 
	end

	self.label_card_ninja_lv_god:setString(tostring(nLevel))
end

function pre_change_request(self)
	--选好卡后请求数据
	if nil == self.objItem_att or nil == self.objItem_def then
		GetMainMenu():ShowTextTip(localizable.ui_godCard_error1,-1)
		return nil
	end

	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 8, "rl_r_comm")
	urlpath = AddData(urlpath, "AttackCardBagIndex", tostring(self.objItem_att:GetGUID()))
	cclog("rl_r_comm & cmd = 8 & url = %s", urlpath)
	GetMainMenu():ShowLoadingDlg()
	CCHttpRequest:open(urlpath, kHttpPost, "query=param1&other=params"):sendWithHandler(
		function(res, hnd)
			GetMainMenu():CloseLoadding()
			local resData = res:getResponseData()
			local code = res:getResponseCode()
			local xfile = xml.parse(resData)
			local item = xfile:find("RENLONG")
			if item == nil then
				return nil
			end
			cclog("%s", resData)
			local retcode = item.code
			if retcode == "0" then
				---[[	
				--合成神卡的消耗
				local _basic = xfile:find("basic")
				if nil ~= _basic then
    				self.cost_prop = tonumber(_basic:find("cost_prop")[1])
    				self.prop_count = tonumber(_basic:find("prop_num")[1])
				end
													
				--update ui
				self:updatePreSynthetic()
			else
				GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
			end
		end)
end

function init_binding_event(self)
	if self.proxy_ ~= nil then
		--返回
		local function onBtnBack(btn, event)
			GetMainMenu():ChangeToSub(self.back_page)
		end
		--readme
		local function onBtnReadMe(btn, event)
			local _descData = {}

			local tempData = {}
			tempData.desc = localizable.ui_godCard_info1
			table.insert(_descData, tempData)

			tempData = {}
			tempData.desc = localizable.ui_godCard_info2
			table.insert(_descData, tempData)

			tempData = {}
			tempData.desc = localizable.ui_godCard_info3
			table.insert(_descData, tempData)

			tempData = {}
			tempData.desc = localizable.ui_godCard_info4
			table.insert(_descData, tempData)

			tempData = {}
			tempData.desc = localizable.ui_godCard_info5
			table.insert(_descData, tempData)

			tempData = {}
			tempData.desc = localizable.ui_godCard_info6
			table.insert(_descData, tempData)

			tempData = {}
			tempData.desc = localizable.ui_godCard_info7
			table.insert(_descData, tempData)

			local detailLayer = createObj(ui_godCardSyntheticReadMeLayer, _descData)
			local size1 = GetMainMenu():GetModelLayer():getContentSize()
			detailLayer.node_:setAnchorPoint(ccp(0.5, 0.5))
			detailLayer.node_:setPosition(ccp(size1.width / 2, size1.height * 0.5))
			GetMainMenu():GetModelLayer():addChild(detailLayer.node_)
		end
		--选择攻卡
		local function onBtnSelectCard_att(btn, event)
			local ninjalistLayer = createObj(ui_godCardSyntheticNinjaListLayer, self, self.m_att_ninjaList, 1)
			self.node_:addChild(ninjalistLayer.node_)
		end
		--选择防卡
		local function onBtnSelectCard_def(btn, event)
			local ninjalistLayer = createObj(ui_godCardSyntheticNinjaListLayer, self, self.m_def_ninjaList, 2)
			self.node_:addChild(ninjalistLayer.node_)
		end
		--合成响应函数
		local function onBtnSynthetic(btn, event)
			if nil == self.objItem_att or nil == self.objItem_def then
				GetMainMenu():ShowTextTip(localizable.ui_godCard_error1,-1)
				return nil
			end

			--进化丹不足
			if self.cost_prop > self.prop_count then
				GetMainMenu():ShowTextTip(localizable.ui_godCard_dan_not_enough, -1)
				return nil
			end

			--忍者需要相同
			local _data_ninja_att = DataMgr.GetDataByID("Struct_Ninjainfo", tonumber(self.objItem_att:GetDataID()))
			local _data_ninja_def = DataMgr.GetDataByID("Struct_Ninjainfo", tonumber(self.objItem_def:GetDataID()))
			if _data_ninja_att and _data_ninja_def then
				local att_icon = _data_ninja_att.m_ninjaicon
				local def_icon = _data_ninja_def.m_ninjaicon
				if att_icon ~= def_icon then
					GetMainMenu():ShowTextTip(localizable.ui_godCard_error1,-1)
					return nil
				end
			end

			local function startSyntheticRequest()
				--合成
				---[[
				local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 28, "rl_w_comm")
				local _cur_card_bag_id_att = self.objItem_att:GetGUID()
				local _cur_card_bag_id_def = self.objItem_def:GetGUID()
				urlpath = AddData(urlpath, "AttackCardBagIndex", tostring(_cur_card_bag_id_att))
				urlpath = AddData(urlpath, "DefenseCardBagIndex", tostring(_cur_card_bag_id_def))
				--cclog("rl_w_comm & cmd = 12 & url = %s", urlpath)
				GetMainMenu():ShowLoadingDlg()
				CCHttpRequest:open(urlpath, kHttpPost, "query=param1&other=params"):sendWithHandler(
					function(res, hnd)
						GetMainMenu():CloseLoadding()
						local resData = res:getResponseData()
						local code = res:getResponseCode()
						local xfile = xml.parse(resData)
						local item = xfile:find("RENLONG")
						if item == nil then
							return nil
						end
		
						local retcode = item.code
						if retcode == "0" then
							local prop_num = tonumber(item:find("prop_num")[1])
							if prop_num > 0 then
								GetMainMenu():ShowTextTip(string.format(localizable.ui_godCard_dan_back, tostring(prop_num)), -1)
							else
								GetMainMenu():ShowTextTip(localizable.ui_godCard_synthetic_succeed, -1)
							end
							local awardXML = item:find("award")
							local _newCard = InitAwardIconData(awardXML)
							if _newCard.m_cardlist then
								--update ui
								self:updateUI(_newCard.m_cardlist[1])
								self.m_newCard_drop_id = nil
								self.m_newCard_drop_id = tonumber(_newCard.m_dropid)

								--获取神卡的guid
								self.m_godCard_guid = tonumber(_newCard.m_cardlist[1].guid)
								
							end
							--只加入背包不显示掉落动画		
							AddSoulAwardData(awardXML)
							--play anim
							self:playAnim()
						else
							GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
						end
					end)
	            --]]
			end
            --标准框
			local dlg = CommonDialogView.create()
			CommonDialogView.m_selfview = dlg
			dlg:SetTitle(localizable.ui_godCard_confirm_title)
			local showContent = string.format(localizable.ui_godCard_confirm, tostring(self.objItem_att:GetName()))
			dlg:SetDescription(showContent)
			dlg:loadCCBI()
			dlg:initUI()
			dlg:SetConfirmHandler(startSyntheticRequest)
			GetMainMenu():GetModelLayer():AddDialog(dlg, 1)	
		end

		local function onBtnPlayerMsg(btn, event)
			GetMainMenu():OnShowUserInfo()
		end

		local function onBtnGodCard(btn, event)
			--点击显示神卡详情
			if nil ~= self.m_godCard_guid then
				local info = CPlayerDataMgr:instance():GetObjectByID(tonumber(self.m_godCard_guid))
				local pNinja = tolua.cast(info, "CPlayerNinja")
				if nil ~= pNinja then
					GetMainMenu():ShowNinjaDetail(pNinja)
				end
			end 
			--[[
			if nil ~= self.m_newCard_drop_id then
				CGameObjElement:ShowDropByID(self.m_newCard_drop_id)
			end
			--]]			
		end

		local function onBtnClickDan(btn, event)
			CGameObjElement:ShowDropByID(tonumber(1527))
		end

		self.btn_back:setTouchPriority(kCCMenuHandlerPriority-1)
		self.btn_back:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btn_back, function(button, event)
			onBtnBack(button)
			return nil
		end, CCControlEventTouchDown)

		self.btn_readme:setTouchPriority(kCCMenuHandlerPriority-1)
		self.btn_readme:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btn_readme, function(button, event)
			onBtnReadMe(button)
			return nil
		end, CCControlEventTouchDown)

		self.btn_select_card_att:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.btn_select_card_att:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btn_select_card_att, function(button, event)
			onBtnSelectCard_att(button)
			return nil
		end, CCControlEventTouchDown)

		self.btn_select_card_def:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.btn_select_card_def:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btn_select_card_def, function(button, event)
			onBtnSelectCard_def(button)
			return nil
		end, CCControlEventTouchDown)

		self.btn_click_dan:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.btn_click_dan:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btn_click_dan, function(button, event)
			onBtnClickDan(button)
			return nil
		end, CCControlEventTouchDown)

		self.btn_synthetic:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.btn_synthetic:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btn_synthetic, function(button, event)
			onBtnSynthetic(button)
			return nil
		end, CCControlEventTouchDown)

		self.ctrl_btnplayermsg:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.ctrl_btnplayermsg:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.ctrl_btnplayermsg, function(button, event)
			onBtnPlayerMsg(button)
			return nil
		end, CCControlEventTouchDown)

		self.btn_god:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.btn_god:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btn_god, function(button, event)
			onBtnGodCard(button)
			return nil
		end, CCControlEventTouchDown)
	end
end

function setNinjaCardInfo(self, _type)
	if nil ~= self.objItem_att or nil ~= self.objItem_def then
		--获取卡牌基本信息
		local _objItem = nil
		if 1 == _type then
			_objItem = self.objItem_att
		elseif 2 == _type then
			_objItem = self.objItem_def
		else
			return nil
		end
		--等级
		local lv = _objItem:GetLevel()	
		--设置卡牌的图标
		local ninjainfo = DataMgr.GetDataByID("Struct_Ninjainfo", tonumber(_objItem:GetDataID()))
		local pFrameSprite = CGameObjElement:GetNinjaFrame(E_FRAMETYPE_SMALL, ninjainfo.m_quality)
		local pIconFrame = CGameObjElement:GetNinjaIcon(E_FRAMETYPE_SMALL, ninjainfo.m_ninjaicon)
		local sprite1 = CCSprite:createWithSpriteFrame(pIconFrame)
		--淬炼等级
		local strengthlevel = _objItem:GetStrengthLevel()
		--转生等级
		local newlife =  _objItem:GetReincarnationLevel()
		--显示卡牌信息
		if 1 == _type then
			self.spr_lv_att:setVisible(true)
			self.label_card_ninja_lv_att:setVisible(true)
			--转生图标
			if newlife > 0 then
				self.node_card_inlay_frame_att:setVisible(true)
				local topinlayframe = CGameObjElement:GetTopInlayFrame(E_FRAMETYPE_SMALL, newlife)
				if topinlayframe ~= nil then
					self.spr_frame_corner1_att:setDisplayFrame(topinlayframe)
					self.spr_frame_corner1_att:setVisible(true)
				else
					self.spr_frame_corner1_att:setVisible(false)
				end

				local downinlayframe = CGameObjElement:GetDownInlayFrame(E_FRAMETYPE_SMALL, newlife)
				if downinlayframe ~= nil then
					self.spr_frame_corner2_att:setDisplayFrame(downinlayframe)
					self.spr_frame_corner2_att:setVisible(true)
				else
					self.spr_frame_corner2_att:setVisible(false)
				end
			end
			--lv
			self.label_card_ninja_lv_att:setString(tostring(_objItem:GetLevel()))
			if self.spr_ninja_icon_att:getChildByTag(100) then
				self.spr_ninja_icon_att:removeChildByTag(100, true)
			end
			--card icon
			local _size = self.spr_ninja_icon_att:getContentSize()
			sprite1:setPosition(ccp(_size.width * 0.5, _size.height * 0.5))
			sprite1:setAnchorPoint(ccp(0.5, 0.5))
			self.spr_ninja_icon_att:setDisplayFrame(pFrameSprite)	
			self.spr_ninja_icon_att:addChild(sprite1, 0, 100)
		elseif 2 == _type then
			self.spr_lv_def:setVisible(true)
			self.label_card_ninja_lv_def:setVisible(true)
			--转生图标
			if newlife > 0 then
				self.node_card_inlay_frame_def:setVisible(true)
				local topinlayframe = CGameObjElement:GetTopInlayFrame(E_FRAMETYPE_SMALL, newlife)
				if topinlayframe ~= nil then
					self.spr_frame_corner1_def:setDisplayFrame(topinlayframe)
					self.spr_frame_corner1_def:setVisible(true)
				else
					self.spr_frame_corner1_def:setVisible(false)
				end

				local downinlayframe = CGameObjElement:GetDownInlayFrame(E_FRAMETYPE_SMALL, newlife)
				if downinlayframe ~= nil then
					self.spr_frame_corner2_def:setDisplayFrame(downinlayframe)
					self.spr_frame_corner2_def:setVisible(true)
				else
					self.spr_frame_corner2_def:setVisible(false)
				end
			end
			--lv
			self.label_card_ninja_lv_def:setString(tostring(_objItem:GetLevel()))
			if self.spr_ninja_icon_def:getChildByTag(100) then
				self.spr_ninja_icon_def:removeChildByTag(100, true)
			end
			--card icon
			local _size = self.spr_ninja_icon_def:getContentSize()
			sprite1:setPosition(ccp(_size.width * 0.5, _size.height * 0.5))
			sprite1:setAnchorPoint(ccp(0.5, 0.5))
			self.spr_ninja_icon_def:setDisplayFrame(pFrameSprite)
			self.spr_ninja_icon_def:addChild(sprite1, 0, 100)
		end
	end
end

function getNinjaListForChange(self)
	self.m_att_ninjaList = {}
	self.m_def_ninjaList = {}
	local objlist = CPlayerDataMgr:instance():GetObjectList(e_obj_ninja)
	local count = objlist:size() - 1
	for i = 0, count do
		local _bag_id = objlist[i]:GetGUID()

		local quality = objlist[i]:GetQuality()
		if objlist[i]:IsUsingInAnyTeam() == false and quality == 5 then
			local _ninja_id = objlist[i]:GetDataID()
			local _data_ninja = DataMgr.GetDataByID("Struct_Ninjainfo", _ninja_id)
			if _data_ninja then
				local maxAtt = _data_ninja.m_attackmax
				local maxDef = _data_ninja.m_defensemax
				if maxAtt >= maxDef then
					table.insert(self.m_att_ninjaList, objlist[i])
				else
					table.insert(self.m_def_ninjaList, objlist[i])
				end
			end
		end		
	end
end

function setSelectedNinjaForChange(self, _index, _type)
	--按照类型区分
	if 1 == _type then
		self.objItem_att = self.m_att_ninjaList[_index]
	elseif 2 == _type then
		self.objItem_def = self.m_def_ninjaList[_index]
	end
	self:setNinjaCardInfo(tonumber(_type))
	--不是同一个忍者的卡
	if nil ~= self.objItem_att and nil ~= self.objItem_def then
		local _data_ninja_att = DataMgr.GetDataByID("Struct_Ninjainfo", tonumber(self.objItem_att:GetDataID()))
		local _data_ninja_def = DataMgr.GetDataByID("Struct_Ninjainfo", tonumber(self.objItem_def:GetDataID()))
		if _data_ninja_att and _data_ninja_def then
			local att_icon = _data_ninja_att.m_ninjaicon
			local def_icon = _data_ninja_def.m_ninjaicon
			if att_icon ~= def_icon then
				GetMainMenu():ShowTextTip(localizable.ui_godCard_error1,-1)
				--以前有选中则消失
				if self.spr_ninja_icon_god:getChildByTag(100) then
					self.spr_ninja_icon_god:removeChildByTag(100, true)
				end
				self.spr_ninja_icon_god:setVisible(false)
			else
				self:SetGodCardBaseInfo(att_icon)
				--请求数据
	            self:pre_change_request()
			end
		end
	end
end

function SetGodCardBaseInfo(self, att_icon)
	self.spr_ninja_icon_god:setVisible(true)
	self.node_card_inlay_frame_god:setVisible(false)
	self.spr_dragon_icon_god:setVisible(false)
	--新的神卡永远1级
	self:updateGodCardLevel()
	--cclog("--20160312-- set god card level !")
	--remove
	if self.spr_ninja_icon_god:getChildByTag(100) then
		self.spr_ninja_icon_god:removeChildByTag(100, true)
	end
	--icon & frame
	local pFrameSprite = CGameObjElement:GetNinjaFrame(E_FRAMETYPE_MIDDLE, tonumber(self.objItem_att:GetQuality() + 1))
	local pIconFrame = CGameObjElement:GetNinjaIcon(E_FRAMETYPE_MIDDLE, att_icon)
	local sprite1 = CCSprite:createWithSpriteFrame(pIconFrame)
	local _size = self.spr_ninja_icon_god:getContentSize()
	sprite1:setPosition(ccp(_size.width * 0.5, _size.height * 0.5))
	sprite1:setAnchorPoint(ccp(0.5, 0.5))
	sprite1:setScale(0.5)
	self.spr_ninja_icon_god:setDisplayFrame(pFrameSprite)
	--合成前灰化
	local pProgram = CCShaderCache:sharedShaderCache():programForKey("greysprite")
	sprite1:setShaderProgram(pProgram)
	--add child
	self.node_card_icon_god:addChild(sprite1, 1, 100)
end

function onNodeCleanup(self)
	if self.proxy_ then
    	self.proxy_:release()
    end

    layer_base_t.onNodeCleanup(self)
end