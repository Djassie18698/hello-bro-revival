--descriptioin:ÊôÐÔµ¤
--company: xckoo
--author: litao
--date: 2014-05-13
---------------------------------------------
module("ui_attributeDanLayer", package.seeall)
baseClass(layer_base_t, ui_attributeDanLayer)

function init(self, card_bag_id)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	self.contentSize_ = GetMainMenu():GetSubContentNode():getContentSize()
	local ccbiAttrTable = {name="sub_ui/AttributeDanView.ccbi", size=self.contentSize_}
	layer_base_t.init(self, true, ccbiAttrTable)

	--select card
    self.objItem = nil
    self.m_cur_bag_id = -1
	--pre
	if nil ~= card_bag_id then
		self.back_page = E_BACKPACKVIEW
		self.m_cur_bag_id = tonumber(card_bag_id)
	else
		self.back_page = E_STOREITEMSVIEW
	end

    --data
    self.preNode = node
    self.m_datas = {}
    self.m_ninjaList = {}

    --
    self.change_attr = 0

    --init
	self:init_ui()
	self:init_binding_event()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		--node
		self.node_content = tolua.cast(self.proxy_:getNode("node_content"), "CCNode")
		self.node_card_shadow_back = tolua.cast(self.proxy_:getNode("node_shadow_back"), "CCNode")
		self.node_card_icon = tolua.cast(self.proxy_:getNode("layer_icon"), "CCNode")
		self.node_card_shadow_front = tolua.cast(self.proxy_:getNode("node_shadow_front"), "CCNode")
		self.node_card_inlay_frame = tolua.cast(self.proxy_:getNode("node_inlay_frame"), "CCNode")
		self.node_anim_container = tolua.cast(self.proxy_:getNode("node_anim_container"), "CCNode")
		--label
		self.label_attrDan_count = tolua.cast(self.proxy_:getNode("label_attrDan_count"), "CCLabelTTF")
		self.label_cur_attr = tolua.cast(self.proxy_:getNode("label_cur_attr"), "CCLabelTTF")
		self.label_dan_cost = tolua.cast(self.proxy_:getNode("label_dan_cost"), "CCLabelBMFont")
		self.label_silver_cost = tolua.cast(self.proxy_:getNode("label_silver_cost"), "CCLabelBMFont")
		self.label_card_ninja_lv = tolua.cast(self.proxy_:getNode("label_ninja_level"), "CCLabelBMFont")
		self.label_click_desc = tolua.cast(self.proxy_:getNode("label_click_desc"), "CCLabelTTF")
		--btn
		self.btn_back = tolua.cast(self.proxy_:getNode("btn_back"), "CCControlButton")
		self.btn_select_card = tolua.cast(self.proxy_:getNode("btn_select_card"), "CCControlButton")
		self.btn_changeAttr = tolua.cast(self.proxy_:getNode("btn_change"), "CCControlButton")
		--spr
		self.sprite_ninjacamp = tolua.cast(self.proxy_:getNode("sprite_ninjacamp"), "CCSprite")
		self.spr_attrDan_icon = tolua.cast(self.proxy_:getNode("spr_attrDan_icon"), "CCSprite")
		self.spr_ninja_icon = tolua.cast(self.proxy_:getNode("sprite_ninja_icon"), "CCSprite")
		self.spr_frame_corner1 = tolua.cast(self.proxy_:getNode("sprite_frame_corner1"), "CCSprite")
		self.spr_frame_corner2 = tolua.cast(self.proxy_:getNode("sprite_frame_corner2"), "CCSprite")
		self.spr_dragon_icon = tolua.cast(self.proxy_:getNode("sprite_dragon_icon"), "CCSprite")
		for i=1,5 do
			self["spr_star_"..i] = tolua.cast(self.proxy_:getNode("sprite_star0"..i), "CCSprite")
		end

		--init
		self:initTopBar()
		self:init_ext_topBar()
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
	--
	if nil == self.objItem then
		self.spr_ninja_icon:setVisible(false)
		self.label_cur_attr:setString(localizable.ui_attribute_no)
		self.label_silver_cost:setString(tostring(0))
		self.label_dan_cost:setString(tostring(0))
	end
	--点击选择呼吸动画
	local move = CCScaleBy:create(0.2, 1.1)
	local array = CCArray:create()
	array:addObject(move)
	array:addObject(move:reverse())
	array:addObject(move)
	array:addObject(move:reverse())
	array:addObject(CCDelayTime:create(1.5))
	local forever = CCRepeatForever:create(CCSequence:create(array))
	self.label_click_desc:runAction(forever)
	--
	local _attrDanCount = CTradeMgr:instance():GetConsumItemCountByID(33)
	self.label_attrDan_count:setString(tostring(_attrDanCount))
	--
	CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile("props/props_200.plist")
	local pFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("props_200")
	if pFrame ~= nil then
		local pIcon = CCSprite:createWithSpriteFrame(pFrame);
		local size = self.spr_attrDan_icon:getContentSize()
		if pIcon ~= nil then
			self.spr_attrDan_icon:addChild(pIcon)
			pIcon:setPosition(ccp(size.width/2, size.height/2))
			pIcon:setAnchorPoint(ccp(0.5, 0.5))
		end
	end
end

function getAttrLabelById(self, _index)
	_index = tonumber(_index)
	--1-5 水火风土雷
	local _label_attr
	if 1 == _index then
		_label_attr = localizable.ui_attribute_water		 
	elseif 2 == _index then
		_label_attr = localizable.ui_attribute_fire		 
	elseif 3 == _index then
		_label_attr = localizable.ui_attribute_wind	 
	elseif 4 == _index then
		_label_attr = localizable.ui_attribute_earth
	elseif 5 == _index then
		_label_attr = localizable.ui_attribute_thunder
	end

	return _label_attr
end

function updatePreChangeAttr(self)
	--cur car attr
	local county_icon_index = self.objItem:GetCardCamp()
	local _label_attr = self:getAttrLabelById(county_icon_index)
	self.label_cur_attr:setString(tostring(_label_attr))
	--
	self.label_silver_cost:setString(tostring(self.silver_cost))
	self.label_dan_cost:setString(tostring(self.attrDan_cost))
end

function playAnim(self)
	--准备播放动画
	---[[
	local pre_animLayer = self.node_anim_container:getChildByTag(100)
	if pre_animLayer then
		pre_animLayer:removeFromParentAndCleanup(true)
	end

	local diceIconSize = self.node_anim_container:getContentSize()
	self.m_animLayer = createObj(ui_changeAttrAnim, diceIconSize)

	self.node_anim_container:addChild(self.m_animLayer.node_)

	self.m_animLayer.node_:setPosition(ccp(-diceIconSize.width * 0.4, -diceIconSize.height * 0.05))
	self.m_animLayer.node_:setAnchorPoint(ccp(0.5, 0.5))
	self.m_animLayer.node_:setTag(100)

	--]]
end

function updateUI(self)
	if self.change_attr < 1 or self.change_attr > 5 then
		GetMainMenu():ShowTextTip(localizable.ui_attribute_exchange_attr_error, -1)
		return nil
	end
	--gold & silver
	self.label_goldval:setString(tostring(self.playerData_.m_gold))
	self.label_silverval:setString(tostring(self.playerData_.m_silver))
	self.label_level:setString(tostring(self.playerData_.m_level))
	--ninja attr label
	local _label_attr = self:getAttrLabelById(self.change_attr)
	self.label_cur_attr:setString(tostring(_label_attr))
	--设置国家标志
	local frame1 = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(tools.getAttributeIcon(self.change_attr))
	if frame1 ~= nil then
		self.sprite_ninjacamp:setDisplayFrame(frame1)
	end

	--
	local _attrDanCount = CTradeMgr:instance():GetConsumItemCountByID(33)
	self.label_attrDan_count:setString(tostring(_attrDanCount))
end

function pre_change_request(self)
	--选好卡后请求数据
	if nil == self.objItem then
		cclog("pre_change_request_self.objItem is nil")
		return nil
	end

	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 5, "rl_w_newlife")
	urlpath = AddData(urlpath, "ReadyCard", tostring(self.objItem:GetGUID()))
	cclog("rl_w_newlife & cmd = 5---%s", urlpath)
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
				--属性转换基本信息
				local prop_transfer = xfile:find("prop_transfer")
				if nil ~= prop_transfer then
					self.silver_cost = tonumber(prop_transfer:find("coin")[1])
    				self.attrDan_cost = tonumber(prop_transfer:find("cost_prop")[1])
				end
													
				--update ui
				self:updatePreChangeAttr()
			else
				GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
			end
		end)
end

function init_binding_event(self)
	if self.proxy_ ~= nil then
		local function onBtnBack(btn, event)
			GetMainMenu():ChangeToSub(self.back_page)
		end

		local function onBtnSelectCard(btn, event)
			--
			local cellsize = self.node_:getContentSize()
			local ninjalistLayer = createObj(ui_attributeDanNinjaListLayer, self, self.m_ninjaList)
			self.node_:addChild(ninjalistLayer.node_)
		end

		local function onBtnChangeAttr(btn, event)
			if nil == self.objItem then
				return nil
			end

			--
			local _attrDanCount = CTradeMgr:instance():GetConsumItemCountByID(33)
			if self.playerData_.m_silver < self.silver_cost then
				GetMainMenu():ShowTextTip(localizable.ui_attribute_silver_not_enough, -1)
				--购买银票
				ShowCommonBuyItemDialog(kConsumableTypeItem, SMALL_COIN_ITEM_ID, BIG_COIN_ITEM_ID, 0)
				return nil
			elseif _attrDanCount < self.attrDan_cost then
				GetMainMenu():ShowTextTip(localizable.ui_attribute_wuxingdan_not_enough, -1)
				return nil
			end
			--转换属性
			---[[
			local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 6, "rl_w_newlife")
			local _cur_card_bag_id = self.objItem:GetGUID()
			urlpath = AddData(urlpath, "ReadyCard", tostring(_cur_card_bag_id))
			cclog("rl_w_newlife & cmd = 7---%s", urlpath)
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
					--cclog("--2016-0112-- %s", resData)
					local retcode = item.code
					if retcode == "0" then
						---[[	
						local prop_transfer = xfile:find("prop_transfer")
						if nil ~= prop_transfer then
							self.change_attr = tonumber(prop_transfer:find("target_prop")[1])
							self:setChangedAttr()
						end

						local tupo_add_attact = xfile:find("attack_tupo")[1]
						if nil ~= tupo_add_attact then
							local tupo_attact = tonumber(xfile:find("attack_tupo")[1])
							local tupo_defense = tonumber(xfile:find("defence_tupo")[1])
							local tupo_chakera = tonumber(xfile:find("cha_tupo")[1])

							--cclog("--2016-0112-- att:%d def:%d cha:%d", tupo_attact, tupo_defense, tupo_chakera)
							tolua.cast(self.objItem, "CPlayerNinja"):setTupoAttrAdd(tupo_attact, tupo_defense, tupo_chakera)
						end
															
						--重新拉数据
						self.playerMgr_:AddSilver(-self.silver_cost)
						self.playerData_ = self.playerMgr_:GetPlayerInfoData()
						--
						local _attrDanCount = CTradeMgr:instance():GetConsumItemCountByID(33)	
						CTradeMgr:instance():SetConsumItemCountByID(33, tonumber(_attrDanCount - self.attrDan_cost))	
						--play anim
						self:playAnim()
						--update ui
						self:updateUI()
						--设置进入忍者列表时需要重新刷新
						GetMainMenu():SetNinjalistNeedtoReLoad(true)
					else
						GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
					end
				end)
            --]]
		end

		local function onBtnPlayerMsg(btn, event)
			GetMainMenu():OnShowUserInfo()
		end

		self.btn_back:setTouchPriority(kCCMenuHandlerPriority-1)
		self.btn_back:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btn_back, function(button, event)
			onBtnBack(button)
			return nil
		end, CCControlEventTouchDown)

		self.btn_select_card:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.btn_select_card:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btn_select_card, function(button, event)
			onBtnSelectCard(button)
			return nil
		end, CCControlEventTouchDown)

		self.btn_changeAttr:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.btn_changeAttr:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btn_changeAttr, function(button, event)
			onBtnChangeAttr(button)
			return nil
		end, CCControlEventTouchDown)

		self.ctrl_btnplayermsg:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.ctrl_btnplayermsg:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.ctrl_btnplayermsg, function(button, event)
			onBtnPlayerMsg(button)
			return nil
		end, CCControlEventTouchDown)
	end
end

function setNinjaCardInfo(self)
	if nil ~= self.objItem then
		--显示卡牌
		self.spr_ninja_icon:setVisible(true)
		--
		local lv = self.objItem:GetLevel()
		self.label_card_ninja_lv:setString(tostring(self.objItem:GetLevel()))

		self.node_card_icon:removeAllChildrenWithCleanup(true)
		--设置卡牌的图标
		local ninjainfo = DataMgr.GetDataByID("Struct_Ninjainfo", tonumber(self.objItem:GetDataID()))
		local pFrameSprite = CGameObjElement:GetNinjaFrame(E_FRAMETYPE_MIDDLE, ninjainfo.m_quality)
		local pIconFrame = CGameObjElement:GetNinjaIcon(E_FRAMETYPE_MIDDLE, ninjainfo.m_ninjaicon)
		local sprite1 = CCSprite:createWithSpriteFrame(pIconFrame)
		local _size = self.spr_ninja_icon:getContentSize()
		sprite1:setPosition(ccp(_size.width * 0.5, _size.height * 0.5))
		sprite1:setAnchorPoint(ccp(0.5, 0.5))
		sprite1:setScale(0.5);
		self.spr_ninja_icon:setDisplayFrame(pFrameSprite)
		self.node_card_icon:addChild(sprite1)

		--卡牌背景动画
		local strengthlevel = self.objItem:GetStrengthLevel()
		--CGameObjElement:SetFrameShadowBack(self.node_card_shadow_back:getContentSize(),self.node_card_shadow_back, strengthlevel, ninjainfo.m_level)
		--CGameObjElement:SetFrameShadowFront(self.node_card_shadow_front:getContentSize(),self.node_card_shadow_front, strengthlevel, ninjainfo.m_level)

		--设置是否转生
		local newlife =  self.objItem:GetReincarnationLevel()	
		self.node_card_inlay_frame:setVisible(true)
		local topinlayframe = CGameObjElement:GetTopInlayFrame(E_FRAMETYPE_SMALL, newlife)
		if topinlayframe ~= nil then
			self.spr_frame_corner1:setDisplayFrame(topinlayframe)
			self.spr_frame_corner1:setVisible(true)
		else
			self.spr_frame_corner1:setVisible(false)
		end

		local downinlayframe = CGameObjElement:GetDownInlayFrame(E_FRAMETYPE_SMALL, newlife)
		if downinlayframe ~= nil then
			self.spr_frame_corner2:setDisplayFrame(downinlayframe)
			self.spr_frame_corner2:setVisible(true)
		else
			self.spr_frame_corner2:setVisible(false)
		end

		local dragon_icon_frame = CGameObjElement:GetFrameDragon(E_FRAMETYPE_MIDDLE, newlife)
		if dragon_icon_frame ~= nil then
			self.spr_dragon_icon:setDisplayFrame(dragon_icon_frame)
			self.spr_dragon_icon:setVisible(true)
		else
			self.spr_dragon_icon:setVisible(false)
		end

		--设置国家标志
		local county_icon_index = self.objItem:GetCardCamp()
		local frame1 = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(tools.getAttributeIcon(county_icon_index))
		if frame1 ~= nil then
			self.sprite_ninjacamp:setDisplayFrame(frame1)
		end

		--设置卡片星级
		local quality = self.objItem:GetQuality()
		if quality > 5 then
			quality = 5
		end

		for i=1, 5 do
			if i > quality then
				self["spr_star_" .. tostring(i)]:setVisible(false)
			else
				self["spr_star_" .. tostring(i)]:setVisible(true)
			end
		end
	end
end

function setChangedAttr(self)
	--设置转换后的属性
	if nil ~= self.objItem then
		self.objItem:SetCardCamp(self.change_attr)
	end
end

function getNinjaListForChange(self)
	local objlist = CPlayerDataMgr:instance():GetObjectList(e_obj_ninja)
	local count = objlist:size() - 1
	for i = 0, count do
		local _bag_id = objlist[i]:GetGUID()
		if tonumber(_bag_id) == self.m_cur_bag_id and self.m_cur_bag_id > 0 then
			self.objItem = objlist[i]
			self.m_cur_bag_id = -1
			self:setNinjaCardInfo()
			self:pre_change_request()
		end
		table.insert(self.m_ninjaList, objlist[i])
	end
end

function setSelectedNinjaForChange(self, _index)
	--
	cclog("_selected_card_data in main layer = %s", tostring(_index))
	self.objItem = self.m_ninjaList[_index]
	self:setNinjaCardInfo()
	--请求数据
	self:pre_change_request()
end

function onNodeCleanup(self)
	if self.proxy_ then
    	self.proxy_:release()
    end

    layer_base_t.onNodeCleanup(self)
end