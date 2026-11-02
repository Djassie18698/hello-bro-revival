--descriptioin:ninja传承
--company: xckoo
--author: litao
--date: 2014-06-21
---------------------------------------------
module("ui_ninjaInheritLayer", package.seeall)
baseClass(layer_base_t, ui_ninjaInheritLayer)

function init(self, card_bag_id)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	self.contentSize_ = GetMainMenu():GetSubContentNode():getContentSize()
	local ccbiAttrTable = {name="sub_ui/NinjaInheritView.ccbi", size=self.contentSize_}
	layer_base_t.init(self, true, ccbiAttrTable)

	--select card
    self.objItem_src = nil
    self.objItem_dest = nil
    self.m_cur_bag_id = -1
	--pre
	if nil ~= card_bag_id then
		self.back_page = E_BACKPACKVIEW
		self.m_cur_bag_id = tonumber(card_bag_id)
	else
		self.back_page = E_STOREITEMSVIEW
	end

	--所选卡用途
	self.selectForInherit = false
	--guid
	self.m_newSrcCard_guid = -1
	self.m_newDestCard_guid = -1

    --data
    self.preNode = node
    self.m_readme_datas = {}
    self.m_ninjaList = {}
    self.m_inherit_ninjaList = {}

    --init
	self:init_ui()
	self:init_binding_event()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		--node
		self.node_content = tolua.cast(self.proxy_:getNode("node_content"), "CCNode")
		self.node_cell = tolua.cast(self.proxy_:getNode("node_cell"), "CCNode")
		self.node_anim_container = tolua.cast(self.proxy_:getNode("node_anim_container"), "CCNode")

		self.node_card_shadow_back_src = tolua.cast(self.proxy_:getNode("node_shadow_back_src"), "CCNode")
		self.node_card_icon_src = tolua.cast(self.proxy_:getNode("layer_icon_src"), "CCNode")
		self.node_card_shadow_front_src = tolua.cast(self.proxy_:getNode("node_shadow_front_src"), "CCNode")
		self.node_card_inlay_frame_src = tolua.cast(self.proxy_:getNode("node_inlay_frame_src"), "CCNode")

		self.node_card_shadow_back_dest = tolua.cast(self.proxy_:getNode("node_shadow_back_dest"), "CCNode")
		self.node_card_icon_dest = tolua.cast(self.proxy_:getNode("layer_icon_dest"), "CCNode")
		self.node_card_shadow_front_dest = tolua.cast(self.proxy_:getNode("node_shadow_front_dest"), "CCNode")
		self.node_card_inlay_frame_dest = tolua.cast(self.proxy_:getNode("node_inlay_frame_dest"), "CCNode")
		
		--label
		self.label_card_level = tolua.cast(self.proxy_:getNode("label_card_level"), "CCLabelTTF")
		self.label_card_cuilian = tolua.cast(self.proxy_:getNode("label_card_cuilian"), "CCLabelTTF")
		self.label_card_newlife = tolua.cast(self.proxy_:getNode("label_card_newlife"), "CCLabelTTF")
		self.label_card_add_att = tolua.cast(self.proxy_:getNode("label_card_add_att"), "CCLabelTTF")
		self.label_card_add_def = tolua.cast(self.proxy_:getNode("label_card_add_def"), "CCLabelTTF")
		self.label_cost = tolua.cast(self.proxy_:getNode("label_cost"), "CCLabelTTF")

		self.label_card_ninja_lv_src = tolua.cast(self.proxy_:getNode("label_ninja_level_src"), "CCLabelBMFont")
		self.label_card_ninja_lv_dest = tolua.cast(self.proxy_:getNode("label_ninja_level_dest"), "CCLabelBMFont")
		--btn
		self.btn_back = tolua.cast(self.proxy_:getNode("btn_back"), "CCControlButton")
		self.btn_inherit = tolua.cast(self.proxy_:getNode("btn_inherit"), "CCControlButton")

		self.btn_select_card_src = tolua.cast(self.proxy_:getNode("btn_select_card_src"), "CCControlButton")
		self.btn_select_card_dest = tolua.cast(self.proxy_:getNode("btn_select_card_dest"), "CCControlButton")
		--spr
		self.sprite_ninjacamp_src = tolua.cast(self.proxy_:getNode("sprite_ninjacamp_src"), "CCSprite")
		self.spr_ninja_icon_src = tolua.cast(self.proxy_:getNode("sprite_ninja_icon_src"), "CCSprite")
		self.spr_frame_corner1_src = tolua.cast(self.proxy_:getNode("sprite_frame_corner1_src"), "CCSprite")
		self.spr_frame_corner2_src = tolua.cast(self.proxy_:getNode("sprite_frame_corner2_src"), "CCSprite")
		self.spr_dragon_icon_src = tolua.cast(self.proxy_:getNode("sprite_dragon_icon_src"), "CCSprite")
		for i=1,5 do
			self["spr_star_"..i.."_src"] = tolua.cast(self.proxy_:getNode("sprite_star0"..i.."_src"), "CCSprite")
		end

		self.sprite_ninjacamp_dest = tolua.cast(self.proxy_:getNode("sprite_ninjacamp_dest"), "CCSprite")
		self.spr_ninja_icon_dest = tolua.cast(self.proxy_:getNode("sprite_ninja_icon_dest"), "CCSprite")
		self.spr_frame_corner1_dest = tolua.cast(self.proxy_:getNode("sprite_frame_corner1_dest"), "CCSprite")
		self.spr_frame_corner2_dest = tolua.cast(self.proxy_:getNode("sprite_frame_corner2_dest"), "CCSprite")
		self.spr_dragon_icon_dest = tolua.cast(self.proxy_:getNode("sprite_dragon_icon_dest"), "CCSprite")
		for i=1,5 do
			self["spr_star_"..i.."_dest"] = tolua.cast(self.proxy_:getNode("sprite_star0"..i.."_dest"), "CCSprite")
		end

		self.spr_add_dest = tolua.cast(self.proxy_:getNode("spr_add_dest"), "CCSprite")
		self.spr_add_src = tolua.cast(self.proxy_:getNode("spr_add_src"), "CCSprite")

		--init
		self:initLayerInfo()
		self:initTopBar()
		self:init_ext_topBar()
		--init info
		self:getNinjaListForInherit()
	end
end

function initLayerInfo(self)
	--初始化页面固定信息
	self.spr_ninja_icon_dest:setVisible(false)
	--点击选择呼吸动画dest
	local move = CCScaleBy:create(0.2, 1.2)
	local array = CCArray:create()
	array:addObject(move)
	array:addObject(move:reverse())
	array:addObject(move)
	array:addObject(move:reverse())
	array:addObject(CCDelayTime:create(1.5))
	local forever = CCRepeatForever:create(CCSequence:create(array))
	self.spr_add_dest:runAction(forever)
	--点击选择呼吸动画src
	local move1 = CCScaleBy:create(0.2, 1.2)
	local array1 = CCArray:create()
	array1:addObject(move1)
	array1:addObject(move1:reverse())
	array1:addObject(move1)
	array1:addObject(move1:reverse())
	array1:addObject(CCDelayTime:create(1.5))
	local forever1 = CCRepeatForever:create(CCSequence:create(array1))
	self.spr_add_src:runAction(forever1)
	--readme info
	self.m_readme_datas = {}
	local tempData = {}
	tempData.desc = tostring(localizable.ui_inherit_readme_info1)
	table.insert(self.m_readme_datas, tempData)

	tempData = {}
	tempData.desc = tostring(localizable.ui_inherit_readme_info2)
	table.insert(self.m_readme_datas, tempData)

	tempData = {}
	tempData.desc = tostring(localizable.ui_inherit_readme_info3)
	table.insert(self.m_readme_datas, tempData)

	tempData = {}
	tempData.desc = tostring(localizable.ui_inherit_readme_info4)
	table.insert(self.m_readme_datas, tempData)
	--创建说明table
	self:createTableView()
end

function createTableView(self)
	if self._tableView == nil then
		local cellContentSize = self.node_cell:getContentSize()
		self._cell_size = CCSizeMake(cellContentSize.width,cellContentSize.height)

		self._content_size = self.node_content:getContentSize()
		self:initTableHandle()
		self._tableView = LuaTableView:createWithHandler(self._tableViewHandler, CCSizeMake(self._content_size.width, self._content_size.height))
		self._tableView:setDirection(kCCScrollViewDirectionVertical)
		self._tableView:setVerticalFillOrder(kCCTableViewFillTopDown)
		self._tableView:setTouchPriority(kCCMenuHandlerPriority - 1)

		self.node_content:addChild(self._tableView)
	else
		self._tableView:reloadData()
	end
end

function initTableHandle(self)
	self._tableViewHandler = LuaEventHandler:create(function(fn, table, a1, a2, x, y)
		local r
		if fn == "cellSize" then
			r = self._cell_size;
		elseif fn == "cellAtIndex" then
    		local nodeLayer = createObj(ui_ninjaInheritReadmeCell, self._cell_size, self.m_readme_datas[a1 + 1])
			--tableView cell container
			--self.cellNodes[a1+1] = nodeLayer
			if not a2 then
				a2 = CCTableViewCell:create()
				a2:addChild(nodeLayer.node_)
			else
				a2:removeAllChildrenWithCleanup(true)
        		a2:addChild(nodeLayer.node_)
			end
			r = a2
		elseif fn == "numberOfCells" then
			r = #self.m_readme_datas;
		    -- Cell events:
		elseif fn == "cellTouched" then			-- A cell was touched, a1 is cell that be touched. This is not necessary.
			---[[
			local cell_index = a1:getIdx() + 1
			--]]
		elseif fn == "cellTouchBegan" then		-- A cell is touching, a1 is cell, a2 is CCTouch
			r = true
		elseif fn == "cellTouchEnded" then		-- A cell was touched, a1 is cell, a2 is CCTouch
			r = true
		elseif fn == "cellHighlight" then		-- A cell is highlighting, coco2d-x 2.1.3 or above
		elseif fn == "cellUnhighlight" then		-- A cell had been unhighlighted, coco2d-x 2.1.3 or above
		elseif fn == "cellWillRecycle" then		-- A cell will be recycled, coco2d-x 2.1.3 or above
		end
		return r
	end)
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

function showSelectSrcCard(self)
	--显示背包选择传承的卡
	if nil ~= self.objItem_src then
		--显示卡牌
		self.spr_ninja_icon_src:setVisible(true)
		--
		local lv = self.objItem_src:GetLevel()
		self.label_card_ninja_lv_src:setString(tostring(self.objItem_src:GetLevel()))

		self.node_card_icon_src:removeAllChildrenWithCleanup(true)
		--设置卡牌的图标
		if self.node_card_icon_src:getChildByTag(99) then
			self.node_card_icon_src:removeChildByTag(99, true)
		end
		local ninjainfo = DataMgr.GetDataByID("Struct_Ninjainfo", tonumber(self.objItem_src:GetDataID()))
		local pFrameSprite = CGameObjElement:GetNinjaFrame(E_FRAMETYPE_MIDDLE, ninjainfo.m_quality)
		local pIconFrame = CGameObjElement:GetNinjaIcon(E_FRAMETYPE_MIDDLE, ninjainfo.m_ninjaicon)
		local sprite1 = CCSprite:createWithSpriteFrame(pIconFrame)
		local _size = self.spr_ninja_icon_src:getContentSize()
		sprite1:setPosition(ccp(_size.width * 0.5, _size.height * 0.5))
		sprite1:setAnchorPoint(ccp(0.5, 0.5))
		sprite1:setScale(0.5)
		sprite1:setTag(99)
		self.spr_ninja_icon_src:setDisplayFrame(pFrameSprite)
		self.node_card_icon_src:addChild(sprite1)

		--卡牌背景动画
		local strengthlevel = self.objItem_src:GetStrengthLevel()
		if strengthlevel > 0 then
			CGameObjElement:SetFrameShadowBack(self.node_card_shadow_back_src:getContentSize(),self.node_card_shadow_back_src, strengthlevel, ninjainfo.m_level)
			CGameObjElement:SetFrameShadowFront(self.node_card_shadow_front_src:getContentSize(),self.node_card_shadow_front_src, strengthlevel, ninjainfo.m_level)
		else
			self.node_card_shadow_back_src:removeAllChildrenWithCleanup(true)
			self.node_card_shadow_front_src:removeAllChildrenWithCleanup(true)
		end
		--设置是否转生
		local newlife =  self.objItem_src:GetReincarnationLevel()	
		self.node_card_inlay_frame_src:setVisible(true)
		local topinlayframe = CGameObjElement:GetTopInlayFrame(E_FRAMETYPE_MIDDLE, newlife)
		if topinlayframe ~= nil then
			self.spr_frame_corner1_src:setDisplayFrame(topinlayframe)
			self.spr_frame_corner1_src:setVisible(true)
		else
			self.spr_frame_corner1_src:setVisible(false)
		end

		local downinlayframe = CGameObjElement:GetDownInlayFrame(E_FRAMETYPE_MIDDLE, newlife)
		if downinlayframe ~= nil then
			self.spr_frame_corner2_src:setDisplayFrame(downinlayframe)
			self.spr_frame_corner2_src:setVisible(true)
		else
			self.spr_frame_corner2_src:setVisible(false)
		end

		local dragon_icon_frame = CGameObjElement:GetFrameDragon(E_FRAMETYPE_MIDDLE, newlife)
		if dragon_icon_frame ~= nil then
			self.spr_dragon_icon_src:setDisplayFrame(dragon_icon_frame)
			self.spr_dragon_icon_src:setVisible(true)
		else
			self.spr_dragon_icon_src:setVisible(false)
		end

		--设置国家标志
		local county_icon_index = self.objItem_src:GetCardCamp()
		local frame1 = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(tools.getAttributeIcon(county_icon_index))
		if frame1 ~= nil then
			self.sprite_ninjacamp_src:setDisplayFrame(frame1)
		end

		--设置卡片星级
		local quality = self.objItem_src:GetQuality()
		if quality > 5 then
			quality = 5
		end

		for i=1, 5 do
			if i > quality then
				self["spr_star_" .. tostring(i).."_src"]:setVisible(false)
			else
				self["spr_star_" .. tostring(i).."_src"]:setVisible(true)
			end
		end
	end
end

function init_ext_ui(self)
	--显示基本信息
	if nil ~= self.objItem_src then
		self.spr_ninja_icon_src:setVisible(true)
		--base info/--扣除元宝+培养数值
		local _cost_gold = tonumber(self.cost_cash + self.card_add_att + self.card_add_def)
		self.label_cost:setString(tostring(_cost_gold))
		self.label_card_level:setString(tostring(self.card_level))
		self.label_card_cuilian:setString(tostring(self.card_star))
		self.label_card_newlife:setString(tostring(self.card_newlife))
		self.label_card_add_att:setString(tostring(self.card_add_att))
		self.label_card_add_def:setString(tostring(self.card_add_def))
	else
		self.spr_ninja_icon_src:setVisible(false)
		self.label_cost:setString(tostring(0))
		self.label_card_level:setString(tostring(0))
		self.label_card_cuilian:setString(tostring(0))
		self.label_card_newlife:setString(tostring(0))
		self.label_card_add_att:setString(tostring(0))
		self.label_card_add_def:setString(tostring(0))
	end
end

function getBaseInheritInfo(self)
	if nil == self.objItem_src then
		GetMainMenu():ShowTextTip(localizable.ui_inherit_choose_card_desc, -1)
		return nil
	end
	--获取基本信息
	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 9, "rl_r_comm")
	urlpath = AddData(urlpath, "SrcCardIndex", tostring(self.objItem_src:GetGUID()))
	cclog("rl_r_comm & cmd = 9---%s", urlpath)
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
			--cclog("%s", resData)
			local retcode = item.code
			if retcode == "0" then
				local _basic = item:find("basic")
				if _basic then
					self.cost_cash = tonumber(_basic:find("cost_cash")[1])
					self.card_level = tonumber(_basic:find("level")[1])
					self.card_star = tonumber(_basic:find("star")[1])
					self.card_newlife = tonumber(_basic:find("newlife")[1])
					self.card_add_att = tonumber(_basic:find("add_attack")[1])
					self.card_add_def = tonumber(_basic:find("add_defense")[1])
				end
													
				--ext init ui
				self:init_ext_ui()
			else
				GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
			end
		end)
end

function updateUI(self, _newGodCard)
	--重新初始化基础信息
	local objlist = CPlayerDataMgr:instance():GetObjectList(e_obj_ninja)
	local count = objlist:size() - 1
	--所有卡
	self.m_ninjaList = {}
	for i = 0, count do
		if objlist[i]:IsUsingInAnyTeam() == false then
			local _bag_id = objlist[i]:GetGUID()
			if tonumber(_bag_id) == self.m_newSrcCard_guid then
				self.objItem_src = objlist[i]
				self.m_newSrcCard_guid = -1
			elseif tonumber(_bag_id) == self.m_newDestCard_guid then
				self.objItem_dest = objlist[i]
				self.m_newDestCard_guid = -1
			end
			table.insert(self.m_ninjaList, objlist[i])
		end	
	end
	--筛选符合条件的卡
	if self.m_ninjaList then
		self.m_inherit_ninjaList = {}
		for i=1,#self.m_ninjaList do
			local _quality = self.m_ninjaList[i]:GetQuality()
			if tonumber(_quality) == tonumber(self.objItem_src:GetQuality()) then
				table.insert(self.m_inherit_ninjaList, self.m_ninjaList[i])
			end
		end
	end
	--显示基本信息
	self:showSelectSrcCard()
	self:setNinjaCardInfo()
end

function playAnim(self)
	--准备播放动画
	---[[
	local pre_animLayer = self.node_:getChildByTag(100)
	if pre_animLayer then
		pre_animLayer:removeFromParentAndCleanup(true)
	end

	local diceIconSize = self.node_:getContentSize()
	self.m_animLayer = createObj(ui_ninjaInheritAnim, diceIconSize)

	self.node_:addChild(self.m_animLayer.node_)

	self.m_animLayer.node_:setPosition(ccp(diceIconSize.width * 0.5, diceIconSize.height * 0.4))
	self.m_animLayer.node_:setAnchorPoint(ccp(0.5, 0.5))
	self.m_animLayer.node_:setTag(100)
	--]]
end

function init_binding_event(self)
	if self.proxy_ ~= nil then
		local function onBtnBack(btn, event)
			GetMainMenu():ChangeToSub(self.back_page)
		end

		local function onBtnSelectSrcCard(btn, event)
			--选传承卡
			local cellsize = self.node_:getContentSize()
			local ninjalistLayer = createObj(ui_ninjaInheritNinjaListLayer, self, self.m_ninjaList)
			self.node_:addChild(ninjalistLayer.node_)
			--标志
			self.selectForInherit = true
		end

		local function onBtnSelectDestCard(btn, event)
			--选继承卡
			local cellsize = self.node_:getContentSize()
			local ninjalistLayer = createObj(ui_ninjaInheritNinjaListLayer, self, self.m_inherit_ninjaList)
			self.node_:addChild(ninjalistLayer.node_)
			--标志
			self.selectForInherit = false
		end

		local function onBtnInherit(btn, event)
			if nil == self.objItem_src or nil == self.objItem_dest then
				GetMainMenu():ShowTextTip(localizable.ui_inherit_choose_card_desc, -1)
				return nil
			end

			--保证传承卡和继承卡品阶一致
			if tonumber(self.objItem_src:GetQuality()) ~= tonumber(self.objItem_dest:GetQuality()) then
				GetMainMenu():ShowTextTip(localizable.ui_inherit_quality_confirm, -1)
				return nil
			end

			--元宝不足
			local _cost_gold = tonumber(self.cost_cash + self.card_add_att + self.card_add_def)
			if self.playerData_.m_gold < _cost_gold then
				--提示购买元宝
				GetMainMenu():ShowErrorTip(tonumber(329018),-1)
				--通用付费引导
				local prePayLayer = createObj(ui_commonPrePay)
				GetMainMenu():GetModelLayer():AddDialog(prePayLayer.node_, 3)
				return nil
			end

			local function startInheritRequest()
				--传承
				---[[
				local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 13, "rl_w_comm")
				local _cur_card_bag_id_src = self.objItem_src:GetGUID()
				local _cur_card_bag_id_dest = self.objItem_dest:GetGUID()
				urlpath = AddData(urlpath, "SrcCardIndex", tostring(_cur_card_bag_id_src))
				urlpath = AddData(urlpath, "DstCardIndex", tostring(_cur_card_bag_id_dest))
				--cclog("rl_w_comm & cmd = 13---%s", urlpath)
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
						cclog("startInheritRequest = %s", resData)
						local retcode = item.code
						if retcode == "0" then
							---[[
							--移除背包的所选卡
							CPlayerDataMgr:instance():RemoveObjByID(self.objItem_src:GetGUID())
							CPlayerDataMgr:instance():RemoveObjByID(self.objItem_dest:GetGUID())
							self.objItem_src = nil
							self.objItem_dest = nil
							--扣除元宝
							local _cost_gold_succ = tonumber(self.cost_cash + self.card_add_att + self.card_add_def)
							self.playerMgr_:AddGold(-_cost_gold)
							self.playerData_ = self.playerMgr_:GetPlayerInfoData()
							self.label_goldval:setString(tostring(self.playerData_.m_gold))
							--基础信息	
							local _basic = item:find("basic")
							if _basic then
								self.cost_cash = tonumber(_basic:find("cost_cash")[1])
								self.card_level = tonumber(_basic:find("level")[1])
								self.card_star = tonumber(_basic:find("star")[1])
								self.card_newlife = tonumber(_basic:find("newlife")[1])
								self.card_add_att = tonumber(_basic:find("add_attack")[1])
								self.card_add_def = tonumber(_basic:find("add_defense")[1])

								self:init_ext_ui()
							end
							--传承卡
							local src_card = xfile:find("src_card")
							if nil ~= src_card then
								local awardXML = src_card:find("award")
								local _newCard = InitAwardIconData(awardXML)
								if _newCard.m_cardlist then
									self.m_newSrcCard_guid = tonumber(_newCard.m_cardlist[1].guid)
								end
								--只加入背包不显示掉落动画		
								AddSoulAwardData(awardXML)
							end
							--继承卡
							local dest_card = xfile:find("dst_card")
							if nil ~= dest_card then
								local awardXML = dest_card:find("award")
								local _newCard = InitAwardIconData(awardXML)
								if _newCard.m_cardlist then
									self.m_newDestCard_guid = tonumber(_newCard.m_cardlist[1].guid)
								end
								--只加入背包不显示掉落动画		
								AddSoulAwardData(awardXML)
							end	
							--play anim
							self:playAnim()
							--update ui
							self:updateUI()
						else
							GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
						end
					end)
	            --]]
			end
            --标准框
			local dlg = CommonDialogView.create()
			CommonDialogView.m_selfview = dlg
			dlg:SetTitle(localizable.ui_inherit_title)
			dlg:SetDescription(localizable.ui_inherit_confirm_tip)
			dlg:loadCCBI()
			dlg:initUI()
			dlg:SetConfirmHandler(startInheritRequest)
			GetMainMenu():GetModelLayer():AddDialog(dlg, 1)	
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

		self.btn_select_card_src:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.btn_select_card_src:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btn_select_card_src, function(button, event)
			onBtnSelectSrcCard(button)
			return nil
		end, CCControlEventTouchDown)

		self.btn_select_card_dest:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.btn_select_card_dest:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btn_select_card_dest, function(button, event)
			onBtnSelectDestCard(button)
			return nil
		end, CCControlEventTouchDown)

		self.btn_inherit:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.btn_inherit:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btn_inherit, function(button, event)
			onBtnInherit(button)
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
	if nil ~= self.objItem_dest then
		--显示卡牌
		self.spr_ninja_icon_dest:setVisible(true)
		--
		local lv = self.objItem_dest:GetLevel()
		self.label_card_ninja_lv_dest:setString(tostring(self.objItem_dest:GetLevel()))

		self.node_card_icon_dest:removeAllChildrenWithCleanup(true)
		--设置卡牌的图标
		if self.node_card_icon_dest:getChildByTag(99) then
			self.node_card_icon_dest:removeChildByTag(99, true)
		end
		local ninjainfo = DataMgr.GetDataByID("Struct_Ninjainfo", tonumber(self.objItem_dest:GetDataID()))
		local pFrameSprite = CGameObjElement:GetNinjaFrame(E_FRAMETYPE_MIDDLE, ninjainfo.m_quality)
		local pIconFrame = CGameObjElement:GetNinjaIcon(E_FRAMETYPE_MIDDLE, ninjainfo.m_ninjaicon)
		local sprite1 = CCSprite:createWithSpriteFrame(pIconFrame)
		local _size = self.spr_ninja_icon_dest:getContentSize()
		sprite1:setPosition(ccp(_size.width * 0.5, _size.height * 0.5))
		sprite1:setAnchorPoint(ccp(0.5, 0.5))
		sprite1:setScale(0.5)
		sprite1:setTag(99)
		self.spr_ninja_icon_dest:setDisplayFrame(pFrameSprite)
		self.node_card_icon_dest:addChild(sprite1)

		--卡牌背景动画
		local strengthlevel = self.objItem_dest:GetStrengthLevel()
		if strengthlevel > 0 then
			CGameObjElement:SetFrameShadowBack(self.node_card_shadow_back_dest:getContentSize(),self.node_card_shadow_back_dest, strengthlevel, ninjainfo.m_level)
			CGameObjElement:SetFrameShadowFront(self.node_card_shadow_front_dest:getContentSize(),self.node_card_shadow_front_dest, strengthlevel, ninjainfo.m_level)
		else
			self.node_card_shadow_back_dest:removeAllChildrenWithCleanup(true)
			self.node_card_shadow_front_dest:removeAllChildrenWithCleanup(true)
		end		

		--设置是否转生
		local newlife =  self.objItem_dest:GetReincarnationLevel()	
		self.node_card_inlay_frame_dest:setVisible(true)
		local topinlayframe = CGameObjElement:GetTopInlayFrame(E_FRAMETYPE_MIDDLE, newlife)
		if topinlayframe ~= nil then
			self.spr_frame_corner1_dest:setDisplayFrame(topinlayframe)
			self.spr_frame_corner1_dest:setVisible(true)
		else
			self.spr_frame_corner1_dest:setVisible(false)
		end

		local downinlayframe = CGameObjElement:GetDownInlayFrame(E_FRAMETYPE_MIDDLE, newlife)
		if downinlayframe ~= nil then
			self.spr_frame_corner2_dest:setDisplayFrame(downinlayframe)
			self.spr_frame_corner2_dest:setVisible(true)
		else
			self.spr_frame_corner2_dest:setVisible(false)
		end

		local dragon_icon_frame = CGameObjElement:GetFrameDragon(E_FRAMETYPE_MIDDLE, newlife)
		if dragon_icon_frame ~= nil then
			self.spr_dragon_icon_dest:setDisplayFrame(dragon_icon_frame)
			self.spr_dragon_icon_dest:setVisible(true)
		else
			self.spr_dragon_icon_dest:setVisible(false)
		end

		--设置国家标志
		local county_icon_index = self.objItem_dest:GetCardCamp()
		local frame1 = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(tools.getAttributeIcon(county_icon_index))
		if frame1 ~= nil then
			self.sprite_ninjacamp_dest:setDisplayFrame(frame1)
		end

		--设置卡片星级
		local quality = self.objItem_dest:GetQuality()
		if quality > 5 then
			quality = 5
		end

		for i=1, 5 do
			if i > quality then
				self["spr_star_" .. tostring(i).."_dest"]:setVisible(false)
			else
				self["spr_star_" .. tostring(i).."_dest"]:setVisible(true)
			end
		end
	end
end

--获取背包中可用于传承的全部卡片
function getNinjaListForInherit(self)
	local objlist = CPlayerDataMgr:instance():GetObjectList(e_obj_ninja)
	local count = objlist:size() - 1
	--所有卡
	self.m_ninjaList = {}
	for i = 0, count do	
		if objlist[i]:IsUsingInAnyTeam() == false then
			local _bag_id = objlist[i]:GetGUID()
			if tonumber(_bag_id) == self.m_cur_bag_id and self.m_cur_bag_id > 0 then
				self.objItem_src = objlist[i]
				self.m_cur_bag_id = -1
			end
			table.insert(self.m_ninjaList, objlist[i])
		end
	end
	--筛选符合条件的卡
	if self.m_ninjaList then
		self.m_inherit_ninjaList = {}
		for i=1,#self.m_ninjaList do
			local _quality = self.m_ninjaList[i]:GetQuality()
			local _bag_id = tonumber(self.m_ninjaList[i]:GetGUID())
			if tonumber(_quality) == tonumber(self.objItem_src:GetQuality()) and _bag_id ~= tonumber(self.objItem_src:GetGUID()) then
				table.insert(self.m_inherit_ninjaList, self.m_ninjaList[i])
			end
		end
	end
	--显示和请求基本信息
	self:showSelectSrcCard()
	self:getBaseInheritInfo()
end

function getDestCardInfo(self)
	if nil == self.objItem_dest then
		GetMainMenu():ShowTextTip(localizable.ui_inherit_choose_card_desc, -1)
		return nil
	end

	--获取基本信息
	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 9, "rl_r_comm")
	urlpath = AddData(urlpath, "SrcCardIndex", tostring(self.objItem_src:GetGUID()))
	urlpath = AddData(urlpath, "DstCardIndex", tostring(self.objItem_dest:GetGUID()))
	cclog("rl_r_comm & cmd = 9---%s", urlpath)
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
			--cclog("%s", resData)
			local retcode = item.code
			if retcode == "0" then
				local _basic = item:find("basic")
				if _basic then
					self.cost_cash = tonumber(_basic:find("cost_cash")[1])
					self.card_level = tonumber(_basic:find("level")[1])
					self.card_star = tonumber(_basic:find("star")[1])
					self.card_newlife = tonumber(_basic:find("newlife")[1])
					self.card_add_att = tonumber(_basic:find("add_attack")[1])
					self.card_add_def = tonumber(_basic:find("add_defense")[1])
				end
													
				--ext init ui
				self:init_ext_ui()
			else
				GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
			end
		end)
end

function setSelectedNinjaForInherit(self, _index)
	--cclog("_selected_card_data in main layer = %s", tostring(_index))
	--根据选择类型操作
	if false == self.selectForInherit then
		self.objItem_dest = self.m_inherit_ninjaList[_index]
		self:setNinjaCardInfo()
		self:getDestCardInfo()
	else
		self.objItem_src = self.m_ninjaList[_index]
		--筛选符合条件的卡
		if self.m_ninjaList then
			self.m_inherit_ninjaList = {}
			for i=1,#self.m_ninjaList do
				local _quality = self.m_ninjaList[i]:GetQuality()
				if tonumber(_quality) == tonumber(self.objItem_src:GetQuality()) then
					table.insert(self.m_inherit_ninjaList, self.m_ninjaList[i])
				end
			end
		end
		--请求数据
		self:showSelectSrcCard()	
		self:getBaseInheritInfo()
	end
end

function onNodeCleanup(self)
	if self.proxy_ then
    	self.proxy_:release()
    end

    layer_base_t.onNodeCleanup(self)
end