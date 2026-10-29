--descriptioin:连续充值(正版上线活动)
--company: xckoo
--litao
--2014.8.12
---------------------------------------------
module("ui_keepPayCell", package.seeall)
baseClass(layer_base_t, ui_keepPayCell)

function init(self, cellSize, data, keepPayDays)
	local ccbiAttrTable = {name="activity/KeepPayCell.ccbi", size=cellSize}
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()
	layer_base_t.init(self, true, ccbiAttrTable)

	self.cellData = data
	self.keepPayDays = keepPayDays
	self:init_ui()
	self:init_binding_event()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		--label
		self.label_item_title = tolua.cast(self.proxy_:getNode("label_item_title"), "CCLabelTTF")

		for i=1,4 do
			self["label_item_name"..tostring(i)] = tolua.cast(self.proxy_:getNode("label_item_name"..tostring(i)), "CCLabelTTF")
			self["btn_item_"..tostring(i)] = tolua.cast(self.proxy_:getNode("btn_item_"..tostring(i)), "CCControlButton")
			self["spr_item"..tostring(i)] = tolua.cast(self.proxy_:getNode("sprite_item"..tostring(i)), "CCSprite")
		end

		self.spr_get = tolua.cast(self.proxy_:getNode("sprite_btn_get"), "CCScale9Sprite")
		self.spr_pay = tolua.cast(self.proxy_:getNode("sprite_btn_pay"), "CCScale9Sprite")
		self.label_get = tolua.cast(self.proxy_:getNode("label_get"), "CCLabelTTF")
		self.label_pay = tolua.cast(self.proxy_:getNode("label_pay"), "CCLabelTTF")
		self.spr_got = tolua.cast(self.proxy_:getNode("sprite_hasgot"), "CCSprite")

		--show info
		self:showInfo()
	end
end

function setState(self)
	if self.cellData.has_got == 0 then
		self.spr_pay:setVisible(true)
		self.label_pay:setVisible(true)
		self.spr_get:setVisible(false)
		self.label_get:setVisible(false)
		self.spr_got:setVisible(false)
	elseif self.cellData.has_got == 1 then
		self.spr_pay:setVisible(false)
		self.label_pay:setVisible(false)
		self.spr_get:setVisible(true)
		self.label_get:setVisible(true)
		self.spr_got:setVisible(false)
	elseif self.cellData.has_got == 2 then
		self.spr_pay:setVisible(false)
		self.spr_get:setVisible(false)
		self.label_pay:setVisible(false)
		self.label_get:setVisible(false)
		self.spr_got:setVisible(true)
	end

	local program = CCShaderCache:sharedShaderCache():programForKey("ShaderPositionTextureColor")
	if program ~= nil then
		self.spr_get:setShaderProgram(program)
	end
end

function showInfo(self)
	self.label_item_title:setString(string.format(localizable.ui_keepPay_cell_title, tostring(self.cellData.index)))
	--状态
	if self.cellData.index <= self.keepPayDays then
		self:setState()
	elseif self.cellData.index == self.keepPayDays + 1 then
		self:setState()
	elseif self.cellData.index == 7 and self.keepPayDays == self.cellData.index then
		self:setState()
	else
		self.spr_pay:setVisible(false)
		self.label_pay:setVisible(false)
		self.spr_get:setVisible(true)
		self.label_get:setVisible(true)
		self.spr_got:setVisible(false)

		local program = CCShaderCache:sharedShaderCache():programForKey("greysprite")
		if program ~= nil then
			self.spr_get:setShaderProgram(program)
		end	
	end

	---[[
	for i=1,4 do
        self["btn_item_"..tostring(i)]:setOpacity(0)
		local _icon = self["spr_item"..tostring(i)]:getChildByTag(99)
		if _icon then
			_icon:removeFromParentAndCleanup(true)
		end

		if i <= #self.cellData.award_datas then
			--icon/frame
			local _maintype = 0
			local _subtype = 0
			local _id = -1
			local _num = -1
			local _drop_type = 0
			local _obj_info = {}
			_maintype, _subtype, _id, _num, _drop_type = setObjTypeInfo(tonumber(self.cellData.award_datas[i].drop))
			_obj_info.pIcon, _obj_info.pFrame, _obj_info.quality, _obj_info.objname = rl_get_iconsprite(_maintype, _subtype, E_FRAMETYPE_SMALL, _id)
			if nil ~= _obj_info.pFrame then
				self["spr_item"..tostring(i)]:setDisplayFrame(_obj_info.pFrame)
			end
			--合集icon用发过来的,防止集合出现问题
			if _drop_type == 1 then	
				local pathName = "props/"..self.cellData.award_datas[i].icon..".plist"
				CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile(pathName)
				local frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(self.cellData.award_datas[i].icon)
				if frame ~= nil then
					_obj_info.pIcon = CCSprite:createWithSpriteFrame(frame)
				end
			end
			if nil ~= _obj_info.pIcon then
				self["spr_item"..tostring(i)]:addChild(_obj_info.pIcon)
				local size = self["spr_item"..tostring(i)]:getContentSize()
				_obj_info.pIcon:setPosition(ccp(size.width * 0.5, size.height * 0.5))
				_obj_info.pIcon:setAnchorPoint(ccp(0.5, 0.5))
				_obj_info.pIcon:setTag(99)
				if _drop_type ~= 1 then
					_obj_info.pIcon:setScale(1.0)
				end
			end

			self["label_item_name"..tostring(i)]:setVisible(true)
			self["label_item_name"..tostring(i)]:setString(tostring(self.cellData.award_datas[i].name))
		else
			local pFrameNoGiftBK = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("small_no_obj_frame")
			self["spr_item"..tostring(i)]:setDisplayFrame(pFrameNoGiftBK)
			self["label_item_name"..tostring(i)]:setVisible(false)
		end		
	end	
	--]]
end

function init_binding_event(self)
	--奖励详情
	local function onBtnClickAwardIcon(btn)
		local btnIndex = btn:getTag()

		if btnIndex > #self.cellData.award_datas then
			return nil
		end
		
		if btnIndex > 0 and btnIndex <= #self.cellData.award_datas then
			local _id = tonumber(self.cellData.award_datas[btnIndex].drop)
			if nil ~= _id then
				CGameObjElement:ShowDropByID(_id)
			end
		end
	end

	for i = 1, 4 do
		self["btn_item_"..i]:setTouchPriority(1)
		self["btn_item_"..i]:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self["btn_item_"..i], function(button, event)
			onBtnClickAwardIcon(button)
			return nil
		end, CCControlEventTouchUpInside)
	end
end

function onNodeCleanup(self)
	---[[
	if self.proxy_ then
    	self.proxy_:release()
    	self.proxy_ = nil
    end
    --]]
    layer_base_t.onNodeCleanup(self)
end