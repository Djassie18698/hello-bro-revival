----------------------------------------------------------------------
--  Copyright (c) 2014-2016, XCKOO. All Rights Reserved.
--  Author :Tango
--  Time   :2015/3/5 11:42:51
--  Remark :武器进阶
----------------------------------------------------------------------
module("ui_advanceEquipLayer", package.seeall)
baseClass(layer_base_t, ui_advanceEquipLayer)

require("ui_layer/ui_equipListLayer")

function init(self, entry)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	self.contentSize_ = GetMainMenu():GetSubContentNode():getContentSize()
	local ccbiAttrTable = { name = "sub_ui/AdvanceEquipView.ccbi", size = self.contentSize_ }
	layer_base_t.init(self, true, ccbiAttrTable)

	self.selectMode = 1
	-- 1:左装备 2:右装备
	self.selectedEquip = { nil, nil }
	-- 保存选入的两个装备信息

	self.entry = entry

	self.maxGrade = 0
	self.cost = 0

	self.retObj = nil

	self:init_ui()
	self:init_binding_event()

	self:init_normalTopBar()
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

function requestBaseInfo(self)
	-- 获取基本信息
	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 8, "rl_w_newlife")
	-- cclog("rl_w_newlife & cmd = 8---%s", urlpath)
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
		-- cclog("rl_w_group_admin ret = %s", resData)
		local retcode = item.code
		if retcode == "0" then
			local info = item:find("info")
			if info then
				self.maxGrade = tonumber(info:find("max_lv")[1])
				self.cost = tonumber(info:find("coin")[1])
				self.labelCost:setString(self.cost)
			end
		else
			GetMainMenu():ShowErrorTip(tonumber(retcode), -1)
		end
	end )
end


function selectByBagid(self, bagid )
	local info = CPlayerDataMgr:instance():GetObjectByID(tonumber(bagid))
	self.selectMode = 1
	self:onSelected(info)
end

function init_ui(self)
	if self.proxy_ ~= nil then
		self:initTopBar()
		
		self.sprite_playermedal = tolua.cast(self.proxy_:getNode("sprite_playermedal"), "CCSprite")
		self.label_level = tolua.cast(self.proxy_:getNode("label_level"), "CCLabelBMFont")
		self.label_curexp = tolua.cast(self.proxy_:getNode("label_curexp"), "CCLabelBMFont")
		self.labelCost = tolua.cast(self.proxy_:getNode("label_cost"),"CCLabelBMFont")
		self.labelGrow = tolua.cast(self.proxy_:getNode("label_grow"),"CCLabelTTF")

		self.ctrl_btn_back = tolua.cast(self.proxy_:getNode("btn_back"), "CCControlButton")

		self.node_circle = tolua.cast(self.proxy_:getNode("node_circle"), "CCNode")
		self.node_rotate = tolua.cast(self.proxy_:getNode("node_rotate"), "CCNode")

		for i = 1, 3 do
			self["sprite_ninjaicon" .. i] = tolua.cast(self.proxy_:getNode("sprite_ninjaicon" .. i), "CCSprite")
			self["layer_icon" .. i] = tolua.cast(self.proxy_:getNode("layer_icon" .. i), "CCLayer")
			self["label_ninja_level" .. i] = tolua.cast(self.proxy_:getNode("label_ninja_level" .. i), "CCLabelBMFont")
			self["label_grade" .. i] = tolua.cast(self.proxy_:getNode("label_grade" .. i), "CCLabelBMFont")
		end

		-- btn
		for i = 1, 2 do
			self["btn_equip" .. i] = tolua.cast(self.proxy_:getNode("btn_equip" .. i), "CCControlButton")
		end

		self.btnResult = tolua.cast(self.proxy_:getNode("btn_equip3"), "CCControlButton")

		self.btnStart = tolua.cast(self.proxy_:getNode("btn_start"), "CCControlButton")

		self:requestBaseInfo()

		self:initExtr()
		if self.entry ~= nil then
			self:selectByBagid(self.entry.bagid)
		end

	end
end


function initExtr(self)
	for i = 1, 3 do
		self:fillCardInfo(i, nil)
	end
	self.selectMode = 1
	-- 1:左装备 2:右装备
	self.selectedEquip = { nil, nil }
	self.retObj = nil
	self:updateTips(0)
end

-- 头部信息的初始化
function init_normalTopBar(self)
	local meritIcon = self.playerMgr_:GetMeritIcon()
	if meritIcon ~= nil then
		local pFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(meritIcon)
		if pFrame ~= nil then
			self.sprite_playermedal:setDisplayFrame(pFrame)
		end
	end
	-- exp
	self.label_name:setString(self.playerData_.m_name)
	local nextExp = self.playerMgr_:GetNextLevelExp()
	local expStr = tostring(self.playerData_.m_exp) .. "/" .. tostring(nextExp)
	self.label_curexp:setString(expStr)
	self.sprite_levelstate:setScaleX(self.playerData_.m_exp / nextExp)

	-- vipinfo
	local viplevel = self.playerData_.m_viplevel
	local vipframes = {
		[0] = "vip_015",
		[1] = "vip_003",
		[2] = "vip_004",
		[3] = "vip_005",
		[4] = "vip_006",
		[5] = "vip_007",
		[6] = "vip_008",
		[7] = "vip_009",
		[8] = "vip_010",
		[9] = "vip_011",
		[10] = "vip_012",
		[11] = "vip_013",
		[12] = "vip_014",
		[13] = "vip_s_13",
		[14] = "vip_s_14",
		[15] = "vip_s_15",
		[16] = "vip_s_16",
		[17] = "vip_s_17",
		[18] = "vip_s_18"
	}
	if self.sprite_vipinfo ~= nil then
		local pFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(vipframes[viplevel])
		self.sprite_vipinfo:setDisplayFrame(pFrame)
	end

	-- bodyval
	local maxbodyval = self.playerMgr_:GetMaxBodyValue()
	local bodyValStr = tostring(self.playerData_.m_bodyvalue) .. "/" .. tostring(maxbodyval)
	self.label_bodyval:setString(bodyValStr)
	local scaleVal = self.playerData_.m_bodyvalue / maxbodyval
	if scaleVal > 1 then
		scaleVal = 1
	end
	self.sprite_bodyratio:setScaleX(scaleVal)

	-- attack
	local maxattack = self.playerMgr_:GetMaxAttackCount()
	local attackValStr = tostring(self.playerData_.m_fightcount) .. "/" .. tostring(maxattack)
	self.label_attackval:setString(attackValStr)
	self.sprite_attackratio:setScaleX(self.playerData_.m_fightcount / maxattack)

	-- gold & silver
	self.label_goldval:setString(tostring(self.playerData_.m_gold))
	self.label_silverval:setString(tostring(self.playerData_.m_silver))
	self.label_level:setString(tostring(self.playerData_.m_level))
end


function requestAdvance(self, equipid1, equipid2, nextgrade)
	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 7, "rl_w_newlife")
	urlpath = AddData(urlpath, "Type", 2)
	urlpath = AddData(urlpath, "ReadyCard", equipid1)
	urlpath = AddData(urlpath, "EatCard", equipid2)
	urlpath = AddData(urlpath, "NewLifeCount", nextgrade)

	GetMainMenu():ShowLoadingDlg()
	-- 获取信息的时候，不允许操作
	CCHttpRequest:open(urlpath, kHttpPost, "query=param1&other=params"):sendWithHandler(
	function(res, hnd)
		GetMainMenu():CloseLoadding()
		-- 获取信息完成时，解除禁止操作
		local resData = res:getResponseData()
		-- cclog("1111----resData:%s", resData)
		local code = res:getResponseCode()
		local xfile = xml.parse(resData)
		local item = xfile:find("RENLONG")
		local retcode = item.code
		if retcode == "0" then
			self:showAnim()
		else
			GetMainMenu():ShowErrorTip(tonumber(retcode), -1)
		end
	end )
end

function updateTips( self,grade )
	local cfg = DataMgr.GetDataByID("Struct_Equipnewlifeprop", grade)
	local grow = 0
	if cfg then
		grow = math.floor(cfg.m_newlife_times_grow * 100)
	end

	local str = tostring(grow) .. '%'
	self.labelGrow:setString(str)
end
function onSuc( self )
	-- 删掉消耗的副卡
	CPlayerDataMgr:instance():RemoveObjByID(self.selectedEquip[2]:GetGUID())
	local main = self.selectedEquip[1]
	local newGrade = main:GetReincarnationLevel() + 1
	if newGrade > self.maxGrade then
		newGrade = self.maxGrade
	end
	main:SetReincarnationLevel(newGrade)
	main:InitFromID(main:GetDataID())
	main:SetLevel(1)
	self.retObj = main
	self.selectedEquip = {nil,nil}

	self:fillCardInfo(1,nil)
	self:fillCardInfo(2,nil)

	self.playerMgr_:AddSilver(-self.cost)
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()
	self.label_silverval:setString(tostring(self.playerData_.m_silver))
end

function init_binding_event(self)
	if self.proxy_ ~= nil then
		local function goto_pre_page()
			if self.entry.prePage == "backpack" then
				GetMainMenu():ChangeToSub(E_BACKPACKVIEW);
			else
				GetMainMenu():ChangeToSub(E_DEFAULTMENU);
			end
		end

		self.ctrl_btn_back:setTouchPriority(-2)
		self.proxy_:handleControlEvent(self.ctrl_btn_back, goto_pre_page, CCControlEventTouchUpInside)

		for i = 1, 2 do
			self["btn_equip" .. i]:setTouchPriority(-2)
			self.proxy_:handleControlEvent(self["btn_equip" .. i], function()
				self:openEquipList(i)
			end , CCControlEventTouchUpInside)
		end

		local function onClickedStart()
			if self.playerData_.m_silver < self.cost then
				GetMainMenu():ShowTextTip(localizable.ui_attribute_silver_not_enough, -1)
				--购买银票
				ShowCommonBuyItemDialog(kConsumableTypeItem, SMALL_COIN_ITEM_ID, BIG_COIN_ITEM_ID, 0)
				return
			end

			if self:check(true) == true then
				local id1, id2 = self.selectedEquip[1]:GetGUID(), self.selectedEquip[2]:GetGUID()
				local nextGrade = self.selectedEquip[1]:GetReincarnationLevel() + 1
				self:requestAdvance(id1, id2, nextGrade)
			end
		end

		self.btnStart:setTouchPriority(-2)
		self.proxy_:handleControlEvent(self.btnStart, onClickedStart, CCControlEventTouchUpInside)

		self.btnResult:setTouchPriority(-2)
		self.proxy_:handleControlEvent(self.btnResult, function()
			--CGameObjElement:ShowCommonItemDetail(1,  self.retObj:GetObjType(), self.retObj:GetDataID(), "")
			if self.retObj ~= nil then
				self:openSucLayer()
			end
		end , CCControlEventTouchUpInside)

	end
end

function showAnim( self )
	self.anim = LuaSubView:create()
	if self.anim == nil then
		return
	end

	self.anim:LoadCCBI("animations/ReincarnationSucceedEffect.ccbi",CCSize(768,825));
	self.anim:setTag(100)
	self.anim:setAnchorPoint(ccp(0.5, 0.5))
	self.anim:setPosition(ccp(0,0))
	self.node_:addChild(self.anim)

	local function animFinished(  )
		GetMainMenu():CloseLoadding()
		if self.schedule then
			CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.schedule)
			self.schedule = nil
			self.anim:removeFromParentAndCleanup(true)

			self:onSuc()
			self:openSucLayer()
		end
		
	end
	self.schedule = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(animFinished,2.6,false)
	GetMainMenu():ShowUnvisibleLoadingDlg()
end

function openSucLayer( self )
	require("ui_layer/ui_AdvanceEquipSucLayer")
	showModelLayer(ui_AdvanceEquipSucLayer,nil,self.retObj)
end

function check(self,final)
	local equip1,equip2 = self.selectedEquip[1], self.selectedEquip[2]
	if equip1 == nil or equip2 == nil then
		if final then
			GetMainMenu():ShowTextTip(localizable.ui_advanceEquip_noequip, -1)
		end
		return false
	end
	-- 装备类型
	if equip1:GetDataID() ~= equip2:GetDataID() then
		GetMainMenu():ShowTextTip(localizable.ui_advanceEquip_diff, -1)
		return false
	end

	if equip1:GetReincarnationLevel() ~= equip2:GetReincarnationLevel() then
		GetMainMenu():ShowTextTip(localizable.ui_advanceEquip_diffGrade, -1)
		return false
	end

	-- 相同对象检查
	if equip1:GetGUID() == equip2:GetGUID() then
		GetMainMenu():ShowTextTip(localizable.ui_advanceEquip_sameone, -1)
		return false
	end

	return true
end
function openEquipList(self, mode)
	self.selectMode = mode

	-- 找出已选入的ID，不再显示在列表中
	local exclude = 0
	if mode == 1 then
		if self.selectedEquip[2] ~= nil then
			exclude = self.selectedEquip[2]:GetGUID()
		end
	elseif mode == 2 then
		if self.selectedEquip[1] ~= nil then
			exclude = self.selectedEquip[1]:GetGUID()
		end
	end

	local layer = createObj(ui_equipListLayer, self, exclude)
	self.node_:addChild(layer.node_)
end


function fillCardInfo(self, i, info, isPreview)
	if info then
		self["sprite_ninjaicon" .. i]:setVisible(true)
		local frame = CGameObjElement:GetNinjaFrame(E_FRAMETYPE_MIDDLE, info:GetQuality())
		if frame then
			self["sprite_ninjaicon" .. i]:setDisplayFrame(frame)
		end

		local sprite = CCSprite:createWithSpriteFrame(info:GetCardIcon(E_FRAMETYPE_LARGE))
		self["layer_icon" .. i]:removeAllChildrenWithCleanup(true)
		self["layer_icon" .. i]:addChild(sprite)
		sprite:setPosition(ccp(0, 0));
		sprite:setAnchorPoint(ccp(0, 0));
		sprite:setScale(0.7);

		local grade = info:GetReincarnationLevel()
		local level = info:GetLevel()
		if isPreview then
			grade = grade + 1
			level = 1
		end

		if grade > 0 then
			self["label_grade" .. i]:setString('+'..grade)
			self["label_grade" .. i]:setVisible(true)
		else
			self["label_grade" .. i]:setVisible(false)
		end
		
		self["label_ninja_level" .. i]:setString(level)
	else
		self["sprite_ninjaicon" .. i]:setVisible(false)
	end
end

-- PS:玩家可以选入列表中的任意装备，待点击“进阶”按钮时再做匹配检查
function onSelected(self, info)
	self.selectedEquip[self.selectMode] = info
	self:fillCardInfo(self.selectMode, info)

	if self:check(false) then
		self:fillCardInfo(3,info,true)
		self:updateTips(info:GetReincarnationLevel()+1)
	else
		self:fillCardInfo(3,nil)
		self:updateTips(0)
		self.retObj = nil
	end
end

function addTrainResultDlg(self)
	local resultLayer = createObj(ui_trainResultLayer, self.awardSpriteAndCount)
	GetMainMenu():GetModelLayer():AddDialog(resultLayer.node_, 3)
	resultLayer.node_container:setScale(0)
	local scaleTo = CCScaleTo:create(0.1, 1)
	resultLayer.node_container:runAction(scaleTo)
end

function onNodeCleanup(self)
	if self.proxy_ then
		self.proxy_:release()
	end
	self.entry = nil
	self:initExtr()

	local plistNameList = { "ccbResources/train_soul.plist", "ccbResources/train_soul_animation.plist" }
	for k, v in ipairs(plistNameList) do
		CCSpriteFrameCache:sharedSpriteFrameCache():removeSpriteFramesFromFile(v)
		local imagePath = string.format("%s.pvr.ccz", string.sub(v, 1, string.len(v) -6))
		CCTextureCache:sharedTextureCache():removeTextureForKey(imagePath)
		imagePath = string.format("%s.pvr", string.sub(v, 1, string.len(v) -6))
		CCTextureCache:sharedTextureCache():removeTextureForKey(imagePath)
		imagePath = string.format("%s.png", string.sub(v, 1, string.len(v) -6))
		CCTextureCache:sharedTextureCache():removeTextureForKey(imagePath)
	end

	layer_base_t.onNodeCleanup(self)
end