----------------------------------------------------------------------
--  Copyright (c) 2014-2016, XCKOO. All Rights Reserved.
--  Author :Tango
--  Time   :2015/1/10 16:56:07
--  Remark :边界碑奖励
----------------------------------------------------------------------

module("ui_borderWarStateRewardCell1", package.seeall)
baseClass(layer_base_t, ui_borderWarStateRewardCell1)

function init(self, cellSize, data)
	local ccbiAttrTable = {name="activity/BorderWarStateRewardCell1.ccbi", size=cellSize}
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()
	layer_base_t.init(self, true, ccbiAttrTable)

	self.cellData = data
	self:init_ui()
	self:init_binding_event()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		for i=1,4 do
			self["btn_item_"..tostring(i)] = tolua.cast(self.proxy_:getNode("btn_item_"..tostring(i)), "CCControlButton")
			self["spr_item"..tostring(i)] = tolua.cast(self.proxy_:getNode("sprite_item"..tostring(i)), "CCSprite")
			self["node_icon_"..tostring(i)] = tolua.cast(self.proxy_:getNode("node_icon_" .. tostring(i)), "CCNode")	
			--self["label_item_num_"..tostring(i)] = tolua.cast(self.proxy_:getNode("label_item_num_"..tostring(i)), "CCLabelBMFont")
			self["label_name_"..tostring(i)] = tolua.cast(self.proxy_:getNode("label_name_"..tostring(i)), "CCLabelTTF")
		end

		self.nodeMine = tolua.cast(self.proxy_:getNode("node_mine"),"CCNode")
		self.nodeOthers = tolua.cast(self.proxy_:getNode("node_others"),"CCNode")

		self.labelPlayerName = tolua.cast(self.proxy_:getNode("label_playerName"),"CCLabelTTF")
		self.nodeStateIcon0 = tolua.cast(self.proxy_:getNode("node_stateIcon_0"),"CCNode")
		self.nodeStateIcon1 = tolua.cast(self.proxy_:getNode("node_stateIcon_1"),"CCNode")

		--show info
		self:showInfo()
	end
end

function clearData( self )
	for i=1,4 do
		self["btn_item_"..tostring(i)]:setVisible(false)
		self["node_icon_"..tostring(i)]:setVisible(false)
		--self["label_item_num_"..tostring(i)]:setVisible(false)
		self["label_name_"..tostring(i)]:setVisible(false)
	end
end

function showInfo(self)
	self:clearData()
	local nodeStateIcon = nil
	if self.cellData.type == "0" then -- 破国奖
		self.nodeMine:setVisible(true);
		self.nodeOthers:setVisible(false);
		nodeStateIcon = self.nodeStateIcon0
	else -- 参与奖
		self.nodeMine:setVisible(false);
		self.nodeOthers:setVisible(true);
		self.labelPlayerName:setString(self.cellData.destoryuser)
		nodeStateIcon = self.nodeStateIcon1
	end

	-- 国家图标
	local ctryId = tonumber(self.cellData.countryid)
	local pFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(countryIcon(ctryId))
	if pFrame ~= nil then
		local pIcon = CCSprite:createWithSpriteFrame(pFrame)
		local size = nodeStateIcon:getContentSize()
		if pIcon ~= nil then
			nodeStateIcon:addChild(pIcon)
			pIcon:setPosition(ccp(size.width/2, size.height/2))
			pIcon:setAnchorPoint(ccp(0.5, 0.5))
		end
	end

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
		_maintype, _subtype, _id, _num, _drop_type = setObjTypeInfo(tonumber(item.dropid))
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
			--self["label_item_name"..tostring(i)]:setString(tostring(item.name))
		else
			--self["label_item_name"..tostring(i)]:setString(tostring(_obj_info.objname))
		end

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

		if _obj_info.objname then
			self["label_name_"..i]:setString(_obj_info.objname)
			self["label_name_"..i]:setVisible(true)
		end
		
		

--		if _num > 1 then
--			self["label_item_num_"..tostring(i)]:setVisible(true)
--			self["label_item_num_"..tostring(i)]:setString(tostring(_num))
--		else
--			self["label_item_num_"..tostring(i)]:setVisible(false)
--		end

		self["btn_item_"..tostring(i)]:setVisible(true)
	end	
	--]]
end

function init_binding_event(self)
	--奖励详情
	local function onBtnClickAwardIcon(btn)
		local btnIndex = btn:getTag()
		
		if btnIndex > 0 and btnIndex <= 4 then
			local _id = tonumber(self.cellData[btnIndex].dropid)
			if nil ~= _id then
				CGameObjElement:ShowDropByID(_id)
			end
		end
	end

	for i = 1, 4 do
		self["btn_item_"..i]:setTouchPriority(kCCMenuHandlerPriority-1)
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