----------------------------------------------------------------------
--  Copyright (c) 2014-2016, XCKOO. All Rights Reserved.
--  Author :Tango
--  Time   :2015/5/14 16:08:07
--  Remark :累计元宝消耗
----------------------------------------------------------------------

module("ui_consumptionCell", package.seeall)
baseClass(layer_base_t, ui_consumptionCell)


function init(self, cellSize, data)
	local ccbiAttrTable = { name = "activity/ConsumptionGiftCell.ccbi", size = cellSize }
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()
	layer_base_t.init(self, true, ccbiAttrTable)

	self.cellData = data
	self:init_ui()
	self:init_binding_event()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		-- label
		self.label_item_title = tolua.cast(self.proxy_:getNode("label_item_title"), "CCLabelTTF")

		for i = 1, 4 do
			self["label_item_name" .. tostring(i)] = tolua.cast(self.proxy_:getNode("label_item_name" .. tostring(i)), "CCLabelTTF")
			self["btn_item_" .. tostring(i)] = tolua.cast(self.proxy_:getNode("btn_item_" .. tostring(i)), "CCControlButton")
			self["spr_item" .. tostring(i)] = tolua.cast(self.proxy_:getNode("sprite_item" .. tostring(i)), "CCSprite")
		end

		self.spr_get = tolua.cast(self.proxy_:getNode("btn_get"), "CCScale9Sprite")
		self.label_get = tolua.cast(self.proxy_:getNode("label_get"), "CCLabelTTF")
		self.spr_got = tolua.cast(self.proxy_:getNode("sprite_hasgot"), "CCSprite")

		-- show info
		self:showInfo()
	end
end

--
function showInfo(self)
	self.label_item_title:setString(self.cellData.cash .. " cumulative golds already")

	--1 可领取
	--2 没有奖励
	--3 已领取
	if 3 == tonumber(self.cellData.status) then
		self.spr_got:setVisible(true)
		self.label_get:setVisible(false)
		self.spr_get:setVisible(false)
	else
		self.spr_got:setVisible(false)
		self.label_get:setVisible(true)
		self.spr_get:setVisible(true)
	end

	--- [[
	for i = 1, 4 do
		local _icon = self["spr_item" .. tostring(i)]:getChildByTag(99)
		if _icon then
			_icon:removeFromParentAndCleanup(true)
		end

		if self.cellData['drop' .. i] ~= '0' then
			-- icon/frame
			local _maintype = 0
			local _subtype = 0
			local _id = -1
			local _num = -1
			local _drop_type = 0
			local _obj_info = { }
			_maintype, _subtype, _id, _num, _drop_type = setObjTypeInfo(tonumber(self.cellData['drop' .. i]))
			_obj_info.pIcon, _obj_info.pFrame, _obj_info.quality, _obj_info.objname = rl_get_iconsprite(_maintype, _subtype, E_FRAMETYPE_SMALL, _id)
			if nil ~= _obj_info.pFrame then
				self["spr_item" .. tostring(i)]:setDisplayFrame(_obj_info.pFrame)
			end
			-- 合集icon用发过来的,防止集合出现问题
			if _drop_type == 1 then
				local pathName = "props/" .. self.cellData['icon' .. i] .. ".plist"
				CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile(pathName)
				local frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(self.cellData['icon' .. i])
				if frame ~= nil then
					_obj_info.pIcon = CCSprite:createWithSpriteFrame(frame)
				end
			end
			if nil ~= _obj_info.pIcon then
				self["spr_item" .. tostring(i)]:addChild(_obj_info.pIcon)
				local size = self["spr_item" .. tostring(i)]:getContentSize()
				_obj_info.pIcon:setPosition(ccp(size.width * 0.5, size.height * 0.5))
				_obj_info.pIcon:setAnchorPoint(ccp(0.5, 0.5))
				_obj_info.pIcon:setTag(99)
				if _drop_type ~= 1 then
					_obj_info.pIcon:setScale(0.9)
				end
			end

			self["label_item_name" .. tostring(i)]:setVisible(true)
			self["label_item_name" .. tostring(i)]:setString(tostring(self.cellData['name' .. i]))
		else
			local pFrameNoGiftBK = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("small_no_obj_frame")
			self["spr_item" .. tostring(i)]:setDisplayFrame(pFrameNoGiftBK)
			self["label_item_name" .. tostring(i)]:setVisible(false)
		end
	end
	-- ]]
end

function init_binding_event(self)
	-- 奖励详情
	local function onBtnClickAwardIcon(btn)
		local btnIndex = btn:getTag()

		if self.cellData['drop' .. btnIndex] == nil or self.cellData['drop' .. btnIndex] == '0' then
			return nil
		end

		local _id = tonumber(self.cellData['drop' .. btnIndex])
		if nil ~= _id then
			CGameObjElement:ShowDropByID(_id)
		end
	end

	for i = 1, 4 do
		self["btn_item_" .. i]:setTouchPriority(1)
		self["btn_item_" .. i]:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self["btn_item_" .. i], function(button, event)
			onBtnClickAwardIcon(button)
			return nil
		end , CCControlEventTouchUpInside)
	end
end

function onNodeCleanup(self)
	--- [[
	if self.proxy_ then
		self.proxy_:release()
		self.proxy_ = nil
	end
	-- ]]
	layer_base_t.onNodeCleanup(self)
end