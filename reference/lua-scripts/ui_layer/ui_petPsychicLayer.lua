----------------------------------------------------------------------
--  Copyright (c) 2014-2016, XCKOO. All Rights Reserved.
--  Author :Tango
--  Time   :2015-8-20 19:20:00
--  Remark :通灵阵
----------------------------------------------------------------------
module("ui_petPsychicLayer", package.seeall)
baseClass(layer_base_t, ui_petPsychicLayer)

require('ui_layer/ui_petListItemLayer')

-- 开放等级
local openLv = { 1, 80, 100, 120, 140, 160, 180, 200 }
local animSprTag = 99

function init(self, contentSize, parent)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	local ccbiAttrTable = { name = "sub_ui/PetPsychicArray.ccbi", size = contentSize }
	layer_base_t.init(self, true, ccbiAttrTable)

	self.parent = parent
	self.tab = 0

	self.pets = { }
	-- 依次8个Id

	self.mainPet = 0

	self:init_ui()
	self:init_binding_event()

	self:requestBaseLayerInfo()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		self.btnTips = tolua.cast(self.proxy_:getNode("btn_tips"), "CCControlButton")

		self.btnPet = { }
		self.nodePet = { }
		for i = 1, 8 do
			self.btnPet[i] = self:getCtrl('btn_pet' .. i, 'CCControlButton')
			self.nodePet[i] = self:getCtrl('node_pet' .. i, 'CCNode')
		end

		self.btnPetMain = self:getCtrl('btn_pet_main', 'CCControlButton')
		self.nodePetMain = self:getCtrl('node_petMain', 'CCNode')
	end
end


function requestBaseLayerInfo(self)
	-- 获取基本信息
	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 2, "rl_x_pet")
	urlpath = AddData(urlpath, "GroupId", global.myOrgId)
	-- cclog("rl_x_pet & cmd = 2---%s", urlpath)
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
		-- cclog("rl_x_pet ret = %s", resData)
		local retcode = item.code
		if retcode == "0" then
			local basic = item:find('basic')

			local atk = basic:find('attack')[1]
			local def = basic:find('defense')[1]
			local chakra = basic:find('chakala')[1]

			self:getCtrl('label_attack', 'CCLabelBMFont'):setString(atk)
			self:getCtrl('label_defense', 'CCLabelBMFont'):setString(def)
			self:getCtrl('label_chakra', 'CCLabelBMFont'):setString(chakra)

			local _id = tonumber(item:find('master'):find('id')[1]) or 0
			local _typeid = tonumber(item:find('master'):find('pet_id')[1]) or 0
			self.mainPet ={id = _id,typeid = _typeid}
			self.pets = { }
			local petsXml = item:find('pets')
			for i = 1, #petsXml do
				local pet = {id = tonumber(petsXml[i].id), typeid = tonumber(petsXml[i].pet_id)}
				table.insert(self.pets, pet)
			end
			-- ext init ui
			self:init_ext_ui()
		else
			GetMainMenu():ShowErrorTip(tonumber(retcode), -1)
		end
	end )
end

function init_ext_ui(self)
	-- 是否开放
	local playerLv = self.playerData_.m_level
	for i = 1, 8 do
		local isOpen = playerLv >= openLv[i]
		self:getCtrl('lb_open' .. i, 'CCLabelTTF'):setVisible(not isOpen)
		self:getCtrl('lb_open' .. i, 'CCLabelTTF'):setString(localizable.ui_pet_text_5)
		self:getCtrl('label_open_lv' .. i, 'CCLabelTTF'):setVisible(not isOpen)
		self:getCtrl('label_open_lv' .. i, 'CCLabelTTF'):setString(openLv[i] .. localizable.ui_pet_text_2)
		self:getCtrl('spr_closed' .. i, 'CCSprite'):setVisible(not isOpen)
		self:getCtrl('spr_add' .. i, 'CCSprite'):setVisible(isOpen)

		if self.pets[i].typeid > 0 then
			self:getCtrl('spr_add' .. i, 'CCSprite'):setVisible(false)
			self:getCtrl('spr_icon' .. i, 'CCSprite'):setVisible(true)

			local info = CPlayerPet:new(self.pets[i].typeid, 0, 0, 0)
			local icon = CCSprite:createWithSpriteFrame(info:GetPetIcon(E_FRAMETYPE_SMALL))
			local circleIconNode = GetMainMenu():getCircleClipNode(40, icon)
			local sprIcon = self:getCtrl('spr_icon' .. i, 'CCSprite')
			sprIcon:addChild(circleIconNode)
			local size = sprIcon:getContentSize()
			circleIconNode:setPosition(size.width/2, size.height/2)
			sprIcon:setScale(1.2)
		else
			self:getCtrl('spr_icon' .. i, 'CCSprite'):setVisible(false)
		end
	end

    self:getCtrl('label_txt1', 'CCLabelTTF'):setString(localizable.ui_pet_text_6)

	if self.mainPet.typeid > 0 then
		self:getCtrl('spr_add_main', 'CCSprite'):setVisible(false)
		self:getCtrl('spr_icon_main', 'CCSprite'):setVisible(true)
		local info = CPlayerPet:new(self.mainPet.typeid, 0, 0, 0)
		local icon = CCSprite:createWithSpriteFrame(info:GetPetIcon(E_FRAMETYPE_SMALL))
		local circleIconNode = GetMainMenu():getCircleClipNode(40, icon)
		local sprIconMain = self:getCtrl('spr_icon_main', 'CCSprite')
		sprIconMain:addChild(circleIconNode)
		local size = sprIconMain:getContentSize()
		circleIconNode:setPosition(size.width/2, size.height/2)
		sprIconMain:setScale(1.5)

		self:playAnim()
	else
		self:getCtrl('spr_add_main', 'CCSprite'):setVisible(true) 
		self:getCtrl('spr_icon_main', 'CCSprite'):setVisible(false)
		self:removeAnim()
	end
end

function init_binding_event(self)
	if self.proxy_ ~= nil then
		local function CCLayerTouch(event, x, y)
			local rect = self.node_:boundingBox()
			rect.origin = ccp(0, 0)
			local p = self.node_:convertToNodeSpace(ccp(x, y))
			if event == "began" then
				if rect:containsPoint(p) == true then
					return true
				else
					return false
				end
			end
		end

		self.node_:setTouchEnabled(true)
		self.node_:registerScriptTouchHandler(CCLayerTouch, false, kCCMenuHandlerPriority - 1, true)

		self.btnTips:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.proxy_:handleControlEvent(self.btnTips, function()
			showTipsDialog(localizable.ui_pet_text_3)
		end , CCControlEventTouchUpInside)

		for i = 1, 8 do
			self.btnPet[i]:setTouchPriority(kCCMenuHandlerPriority - 1)
			self.proxy_:handleControlEvent(self.btnPet[i], function()
				self:onClickedIcon(i)
				self.nodePet[i]:runAction(CCScaleTo:create(0.1, 1.0))
			end , CCControlEventTouchUpInside)

			self.proxy_:handleControlEvent(self.btnPet[i], function()
				self.nodePet[i]:runAction(CCScaleTo:create(0.1, 1.1))
			end , CCControlEventTouchDown)

			self.proxy_:handleControlEvent(self.btnPet[i], function()
				self.nodePet[i]:runAction(CCScaleTo:create(0.1, 1.0))
			end , CCControlEventTouchDragOutside)
		end


		self.btnPetMain:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.proxy_:handleButtonEvent(self.btnPetMain, function(button, event)
			self.nodePetMain:runAction(CCScaleTo:create(0.1, 1.0))
			self:openSelectList(0)
		end , CCControlEventTouchUpInside)

		self.proxy_:handleControlEvent(self.btnPetMain, function(button, event)
			self.nodePetMain:runAction(CCScaleTo:create(0.1, 1.1))
		end , CCControlEventTouchDown)

		self.proxy_:handleButtonEvent(self.btnPetMain, function(button, event)
			self.nodePetMain:runAction(CCScaleTo:create(0.1, 1.0))
		end , CCControlEventTouchDragOutside)

	end
end

function onClickedIcon(self, index)
	if self.playerData_.m_level < openLv[index] then
		GetMainMenu():ShowTextTip(localizable.ui_pet_text_1, -1)
		return
	end
	self:openSelectList(index)
end

function playAnim(self)
	self:removeAnim()
	local cache = CCSpriteFrameCache:sharedSpriteFrameCache()  
    cache:addSpriteFramesWithFile('ccbResources/psychicAni.plist')

    local namePre = '0_0000'

    local array = CCArray:create()
    for i=0,9 do 
        local name = namePre .. i 
        local frame = cache:spriteFrameByName(name)
		if frame ~= nil then
			array:addObject(frame)  
		end
	end  

	local animation = CCAnimation:createWithSpriteFrames(array,0.08)  
    local animate = CCAnimate:create(animation)

    local animSprite = CCSprite:create()
    animSprite:setTag(animSprTag)
	self.nodePetMain:addChild(animSprite)

	animSprite:setPosition(ccp(self.nodePetMain:getContentSize().width/2,self.nodePetMain:getContentSize().height/2))
	animSprite:runAction(CCRepeatForever:create(animate))
end

function removeAnim( self )
	--local spr = self.nodePetMain:getChildByTag(animSprTag)
	self.nodePetMain:removeChildByTag(animSprTag, true)
end

function openSelectList(self, index)
    local petoldid = 0
    if index == 0 then
        petoldid = self.mainPet.id
    else
        petoldid = self.pets[index].id
    end
    if index == 0 then
        
    end
	local layer = createObj(ui_petListItemLayer, self, index, petoldid)
	AddViewToActivitySubMenu(layer.node_)
end

function getCtrl(self, ctrlname, type)
	return tolua.cast(self.proxy_:getNode(ctrlname), type)
end

function update_ui(self)
	self:requestBaseLayerInfo()
end

function onNodeCleanup(self)
	if self.proxy_ then
		self.proxy_:release()
	end

	layer_base_t.onNodeCleanup(self)
end