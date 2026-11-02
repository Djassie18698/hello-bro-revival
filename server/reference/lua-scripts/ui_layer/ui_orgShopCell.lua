----------------------------------------------------------------------
--  Copyright (c) 2014-2016, XCKOO. All Rights Reserved.
--  Author :Tango
--  Time   :2014/11/24 19:54:12
--  Remark :组织商城
----------------------------------------------------------------------
module("ui_orgShopCell", package.seeall)
baseClass(layer_base_t, ui_orgShopCell)

function init(self, cellSize, data)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	local ccbiAttrTable = { name = "sub_ui/OrgShopCell.ccbi", size = cellSize }
	layer_base_t.init(self, true, ccbiAttrTable)

	-- data
	self.cellData = data
	self.nodeGrid = { }
	self.sprClose = { }
	self.btnBuy = { }
	self.sprItem = {}
	self.nodeIcon = {}
	self.labelContrib = {}
	self.labelNeedGold = {}
	self.sprGoldIcon = {}
	self.labelNum = {}

	-- init
	self:init_ui()
	self:init_binding_event()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		-- label
		self.labelName = tolua.cast(self.proxy_:getNode("label_name"), "CCLabelTTF")
		self.labelLevel = tolua.cast(self.proxy_:getNode("label_level"), "CCLabelTTF")
		self.labelTitle = tolua.cast(self.proxy_:getNode("label_title"), "CCLabelTTF")
		self.labelContribution = tolua.cast(self.proxy_:getNode("label_contribution"), "CCLabelTTF")
		self.labelLastLogin = tolua.cast(self.proxy_:getNode("label_lastLogin"), "CCLabelTTF")

		for i = 1, 3 do
			local si = tostring(i)
			self.nodeGrid[i] = tolua.cast(self.proxy_:getNode("node_grid" .. si), "CCNode")
			self.sprClose[i] = tolua.cast(self.proxy_:getNode("spr_close" .. si), "CCSprite")
			self.sprItem[i] = tolua.cast(self.proxy_:getNode("spr_item_" .. si), "CCSprite")
			self.nodeIcon[i] = tolua.cast(self.proxy_:getNode("node_icon_" .. si), "CCSprite")
			self.labelNum[i] = tolua.cast(self.proxy_:getNode("label_num_" .. si), "CCLabelBMFont")
			self.labelContrib[i] = tolua.cast(self.proxy_:getNode("label_need_contrib" .. si), "CCLabelTTF")
			self.labelNeedGold[i] = tolua.cast(self.proxy_:getNode("label_need_gold" .. si), "CCLabelTTF")
			self.sprGoldIcon[i] = tolua.cast(self.proxy_:getNode("spr_goldIcon" .. si), "CCSprite")
			self.btnBuy[i] = tolua.cast(self.proxy_:getNode("btn_buy" .. si), "CCControlButton")
			self["label_level" .. si] = tolua.cast(self.proxy_:getNode("label_open_level_" .. si),"CCLabelTTF")
			self["spr_cover" .. si] = tolua.cast(self.proxy_:getNode("spr_cover" .. si),"CCLayerColor")
            self["sprite_type" .. si] = tolua.cast(self.proxy_:getNode("sprite_type_" .. si), "CCSprite")

		end

		-- init info
		self:init_ui_ext()
	end
end

function clear(self)
	for i = 1, 3 do
		self.nodeGrid[i]:setVisible(false)
		self.sprClose[i]:setVisible(true)
	end
end

function init_ui_ext(self)
	self:clear()
	for i = 1, #self.cellData do
		local si = tostring(i)
		self.nodeGrid[i]:setVisible(true)
		self.sprClose[i]:setVisible(false)

		local nodeItem =self.nodeIcon[i]
		
		local _icon = nodeItem:getChildByTag(99)
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
		_maintype, _subtype, _id, _num, _drop_type = setObjTypeInfo(tonumber(item.store_drop))
		_obj_info.pIcon, _obj_info.pFrame, _obj_info.quality, _obj_info.objname = rl_get_iconsprite(_maintype, _subtype, E_FRAMETYPE_SMALL, _id)
		if nil ~= _obj_info.pFrame then
			self.sprItem[i]:setDisplayFrame(_obj_info.pFrame)
		end
		--合集icon用发过来的,防止集合出现问题
		if _drop_type == 1 then
			local pathName = "props/"..item.store_icon..".plist"
			CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile(pathName)
			local frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(item.store_icon)
			if frame ~= nil then
				_obj_info.pIcon = CCSprite:createWithSpriteFrame(frame)
			end
		end
		if nil ~= _obj_info.pIcon then
			nodeItem:setVisible(true)
			nodeItem:addChild(_obj_info.pIcon)
			local size = nodeItem:getContentSize()
			_obj_info.pIcon:setPosition(ccp(size.width * 0.5, size.height * 0.5))
			_obj_info.pIcon:setAnchorPoint(ccp(0.5, 0.5))
			_obj_info.pIcon:setTag(99)
			if _drop_type ~= 1 then
				_obj_info.pIcon:setScale(0.9)
			end
		end
		
		self.labelContrib[i]:setString(item.cost_score)
		if item.cost_cash == '0' then
			self.sprGoldIcon[i]:setVisible(false)
			self.labelNeedGold[i]:setVisible(false)
		else
			self.sprGoldIcon[i]:setVisible(true)
			self.labelNeedGold[i]:setVisible(true)
			self.labelNeedGold[i]:setString(item.cost_cash)
		end

		if _num == nil then
			_num = 1
		end
		
		if _num > 1 then
			self.labelNum[i]:setString(_num)
			self.labelNum[i]:setVisible(true)
		else
			self.labelNum[i]:setVisible(false)
		end

		if item.onoff == '1' then -- 是否开启
			setBtnEnabled(self.btnBuy[i],true)
			self["label_level" .. si]:setVisible(false)
			self["spr_cover" .. si]:setVisible(false)
		else
			setBtnEnabled(self.btnBuy[i],false)
			self["label_level" .. si]:setVisible(true)
			self["label_level" .. si]:setString(item.min_store_level .. localizable.ui_orgShop_openLevel)
			self["spr_cover" .. si]:setVisible(true)
		end

		if item.buyflag == '1' then --已购买
			setBtnTitle(self.btnBuy[i], localizable.ui_orgShop_btn_1)
			setBtnEnabled(self.btnBuy[i],false)
		else
			setBtnTitle(self.btnBuy[i], localizable.ui_orgShop_btn_0)
			if item.onoff == '1' then
				setBtnEnabled(self.btnBuy[i],true)
			end
		end

        if _maintype == 5 then--碎片
            self["sprite_type" .. si]:setVisible(true)
        else
            self["sprite_type" .. si]:setVisible(false)
        end
	end
end

function init_binding_event(self)

end

function onNodeCleanup(self)
	if self.proxy_ then
		self.proxy_:release()
		self.proxy_ = nil
	end
	layer_base_t.onNodeCleanup(self)
end