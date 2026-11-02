------------------------------------------------------------------------
--  Copyright (c) 2011-2015, XCKOO. All Rights Reserved.
--  Author :Tango
--  FName  :ui_diligenceGiftCell.lua
--  Time   :2014/11/03 11:12:00
--  Remark :勤奋礼包
------------------------------------------------------------------------
	

module("ui_diligenceGiftCell", package.seeall)
baseClass(layer_base_t, ui_diligenceGiftCell)

function init(self, cellSize, data)
	local ccbiAttrTable = {name="activity/DiligenceGiftCell.ccbi", size=cellSize}
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()
	layer_base_t.init(self, true, ccbiAttrTable)

	self.cellData = data
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
			self["node_icon_"..tostring(i)] = tolua.cast(self.proxy_:getNode("node_icon_" .. tostring(i)), "CCNode")	
			self["label_item_num_"..tostring(i)] = tolua.cast(self.proxy_:getNode("label_item_num_"..tostring(i)), "CCLabelBMFont")
		end

		self.labelCompleted = tolua.cast(self.proxy_:getNode("label_completed"), "CCLabelBMFont")
		self.labelRest = tolua.cast(self.proxy_:getNode("label_rest"), "CCLabelBMFont")

		self.btnBuy = tolua.cast(self.proxy_:getNode("btn_get"), "CCControlButton")

		--show info
		self:showInfo()
	end
end

function clearData( self )
	for i=1,4 do
		self["label_item_name"..tostring(i)]:setVisible(false)
		self["btn_item_"..tostring(i)]:setVisible(false)
		self["node_icon_"..tostring(i)]:setVisible(false)
		self["label_item_num_"..tostring(i)]:setVisible(false)
	end
end

function showInfo(self)
	self:clearData()

	self.label_item_title:setString(self.cellData.desc)

	self.labelCompleted:setString(self.cellData.done)

	self.labelRest:setString(self.cellData.current_recv .. "/" .. self.cellData.total_recv)

	for i=1,#self.cellData do
		local _icon = self["spr_item"..tostring(i)]:getChildByTag(99)
		if _icon then
			_icon:removeFromParentAndCleanup(true)
		end
		local item = self.cellData[i]
		--icon/frame
		local _maintype = 0
		local _subtype = 0
		local _id = -1
		local _num = -1
		local _drop_type = 0
		local _obj_info = {}
		_maintype, _subtype, _id, _num, _drop_type = setObjTypeInfo(tonumber(item.id))
		_obj_info.pIcon, _obj_info.pFrame, _obj_info.quality, _obj_info.objname = rl_get_iconsprite(_maintype, _subtype, E_FRAMETYPE_SMALL, _id)
		if nil ~= _obj_info.pFrame then
			self["spr_item"..tostring(i)]:setDisplayFrame(_obj_info.pFrame)
		end
		--合集icon用发过来的,防止集合出现问题
		if _drop_type == 1 then	
			local pathName = "props/"..item.icon..".plist"
			CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile(pathName)
			local frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(item.icon)
			if frame ~= nil then
				_obj_info.pIcon = CCSprite:createWithSpriteFrame(frame)
			end
			self["label_item_name"..tostring(i)]:setString(tostring(item.name))
		else
			self["label_item_name"..tostring(i)]:setString(tostring(_obj_info.objname))
		end
		self["label_item_name"..tostring(i)]:setVisible(true)

		if nil ~= _obj_info.pIcon then
			self["node_icon_"..tostring(i)]:addChild(_obj_info.pIcon)
			self["node_icon_"..tostring(i)]:setVisible(true)

			local size = self["node_icon_"..tostring(i)]:getContentSize()
			_obj_info.pIcon:setPosition(ccp(size.width * 0.5, size.height * 0.5))
			_obj_info.pIcon:setAnchorPoint(ccp(0.5, 0.5))
			_obj_info.pIcon:setTag(99)
			if _drop_type ~= 1 then
				_obj_info.pIcon:setScale(0.9)
			end
		end

		

		if _num > 1 then
			self["label_item_num_"..tostring(i)]:setVisible(true)
			self["label_item_num_"..tostring(i)]:setString(tostring(_num))
		else
			self["label_item_num_"..tostring(i)]:setVisible(false)
		end

		self["btn_item_"..tostring(i)]:setVisible(true)
	end	
	--]]
end

function init_binding_event(self)
	--奖励详情
	local function onBtnClickAwardIcon(btn)
		local btnIndex = btn:getTag()
		
		if btnIndex > 0 and btnIndex <= 4 then
			local _id = tonumber(self.cellData[btnIndex].id)
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