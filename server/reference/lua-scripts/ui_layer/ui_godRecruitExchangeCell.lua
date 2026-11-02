----------------------------------------------------------------------
--  Copyright (c) 2014-2016, XCKOO. All Rights Reserved.
--  Author :Tango
--  Time   :2015/7/2 20:51:38
--  Remark :老虎机兑换
----------------------------------------------------------------------
module("ui_godRecruitExchangeCell", package.seeall)
baseClass(layer_base_t, ui_godRecruitExchangeCell)

function init(self, cellSize, data,parent)
	local ccbiAttrTable = { name = "activity/GodRecruitExchangeCell.ccbi", size = cellSize }
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()
	layer_base_t.init(self, true, ccbiAttrTable)

	self.cellData = data
	self:init_ui()
	self:init_binding_event()
	self.parent = parent
end

function init_ui(self)
	if self.proxy_ ~= nil then
		-- label
		self.label_item_title = tolua.cast(self.proxy_:getNode("label_item_title"), "CCLabelTTF")

		for i = 1, 4 do
			self["btn_item_" .. i] = tolua.cast(self.proxy_:getNode("btn_item_" .. i), "CCControlButton")
			self["sprite_item" .. i] = tolua.cast(self.proxy_:getNode("sprite_item" .. i), "CCSprite")
			self['btn_get' .. i] = getButtonFromCCB(self.proxy_, 'btn_get' .. i)
			self['lb_score' .. i] = getLabelTTFFromCCB(self.proxy_, 'label_score'..i)
			self['label_cost'..i] = getLabelTTFFromCCB(self.proxy_, 'label_cost'..i)
		end

		self.btnGet = tolua.cast(self.proxy_:getNode("btn_get"), "CCControlButton")
		self.labelGet = tolua.cast(self.proxy_:getNode("label_get"), "CCLabelTTF")
		self.sprHasGot = tolua.cast(self.proxy_:getNode("sprite_hasgot"), "CCSprite")

		-- show info
		self:showInfo()
	end
end

--
function showInfo(self)
	--- [[
	for i = 1, #self.cellData do
		local data = self.cellData[i]
		local _icon = self["sprite_item" .. tostring(i)]:getChildByTag(99)
		if _icon then
			_icon:removeFromParentAndCleanup(true)
		end

		if data.drop_id ~= '0' then
			-- icon/frame
			local _maintype = 0
			local _subtype = 0
			local _id = -1
			local _num = -1
			local _drop_type = 0
			local _obj_info = { }
			_maintype, _subtype, _id, _num, _drop_type = setObjTypeInfo(tonumber(data.drop_id))
			_obj_info.pIcon, _obj_info.pFrame, _obj_info.quality, _obj_info.objname = rl_get_iconsprite(_maintype, _subtype, E_FRAMETYPE_SMALL, _id)
			if nil ~= _obj_info.pFrame then
				self["sprite_item" .. tostring(i)]:setDisplayFrame(_obj_info.pFrame)
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
				self["sprite_item" .. tostring(i)]:addChild(_obj_info.pIcon)
				local size = self["sprite_item" .. tostring(i)]:getContentSize()
				_obj_info.pIcon:setPosition(ccp(size.width * 0.5, size.height * 0.5))
				_obj_info.pIcon:setAnchorPoint(ccp(0.5, 0.5))
				_obj_info.pIcon:setTag(99)
				if _drop_type ~= 1 then
					_obj_info.pIcon:setScale(0.9)
				end
			end

			self['label_cost'..i]:setString(data.card_exchange_point)

		else
			local pFrameNoGiftBK = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("small_no_obj_frame")
			self["sprite_item" .. tostring(i)]:setDisplayFrame(pFrameNoGiftBK)
		end
	end
	-- ]]
end

function init_binding_event(self)
	for i=1,3 do
		local btn = self['btn_get' .. i]
		btn:setTouchPriority(kCCMenuHandlerPriority-2)
		self.proxy_:handleButtonEvent(btn, function (button, event)
			if 1 then
				self:requestExchange(i)
			end
		end, CCControlEventTouchDown)
	end
end

function requestExchange(self, i)
	local id = tonumber(self.cellData[i].id)

	local function spinCallback( renlong)
		local awardXML = renlong:find("award")
		ShowAward(awardXML)
		local curScore = renlong:find('leftScore')[1] or 0

		if self.parent then
			self.parent:onExchangeSuc(curScore)
		end
	end

	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 21, "rl_x_small_activity")
	urlpath = AddData(urlpath, "ChangeId", id)
	sendRequest(urlpath, spinCallback, 1)
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