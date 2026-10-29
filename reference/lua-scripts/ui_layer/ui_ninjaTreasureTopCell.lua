--[[----------------------------------------------------
  Author :tango
  FName  :ui_ninjaTreasureTopCell.lua
  Time   :2014/10/14 11:25:33
  Remark :新手阶段性礼包
-------------------------------------------------------]]


module("ui_ninjaTreasureTopCell", package.seeall)
baseClass(layer_base_t, ui_ninjaTreasureTopCell)

function init(self, cellSize, data)
	local ccbiAttrTable = {name="activity/NinjaTreasureTopCell.ccbi", size=cellSize}
	layer_base_t.init(self, true, ccbiAttrTable)

	self.m_itemlist = data

	self:init_ui()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		for i=1,4 do
			self["btn_icon" .. tostring(i)] = tolua.cast(self.proxy_:getNode("btn_icon" .. tostring(i)), "CCControlButton")	
			self["spr_icon_"..tostring(i)] = tolua.cast(self.proxy_:getNode("spr_icon_" .. tostring(i)), "CCSprite")
			self["node_icon_"..tostring(i)] = tolua.cast(self.proxy_:getNode("node_icon_" .. tostring(i)), "CCNode")	
			self["label_item_num_"..tostring(i)] = tolua.cast(self.proxy_:getNode("label_item_num_"..tostring(i)), "CCLabelBMFont")
		end

		self:init_ext_ui()
	end
end

function clearData(self )
	for i=1,4 do
		self["btn_icon" .. tostring(i)]:setVisible(false)
		--self["spr_icon_"..tostring(i)]:setVisible(false)
		self["node_icon_"..tostring(i)]:setVisible(false)
		self["label_item_num_"..tostring(i)]:setVisible(false)
	end
end

function init_ext_ui(self)
	self:clearData()
	--init
	CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile("ccbResources/player_rank.plist")
	if self.m_itemlist then
		for i=1,#self.m_itemlist do
			item = self.m_itemlist[i]

			-- item icon
			local _maintype = 0
			local _subtype = 0
			local _id = -1
			local _obj_info = {}
			_maintype, _subtype, _id, _num = setObjTypeInfo(self.m_itemlist[i].id)
			_obj_info.pIcon, _obj_info.pFrame, _obj_info.quality, _obj_info.objname = 	rl_get_iconsprite(_maintype, _subtype, E_FRAMETYPE_SMALL, _id)
			if nil ~= _obj_info.pFrame then
				self["spr_icon_"..tostring(i)]:setDisplayFrame(_obj_info.pFrame)
			end
			if nil ~= _obj_info.pIcon then
				self["node_icon_"..tostring(i)]:addChild(_obj_info.pIcon)
				self["node_icon_"..tostring(i)]:setVisible(true)
				local size = self["node_icon_"..tostring(i)]:getContentSize()
				_obj_info.pIcon:setPosition(ccp(size.width * 0.5, size.height * 0.5))
				_obj_info.pIcon:setAnchorPoint(ccp(0.5, 0.5))
				_obj_info.pIcon:setTag(99)
				_obj_info.pIcon:setScale(0.8)
			end

			if _num > 1 then
				self["label_item_num_"..tostring(i)]:setVisible(true)
				self["label_item_num_"..tostring(i)]:setString(tostring(_num))
			else
				self["label_item_num_"..tostring(i)]:setVisible(false)
			end

			self["btn_icon" .. tostring(i)]:setVisible(true)

		end
	end
end

function onNodeCleanup(self)
    layer_base_t.onNodeCleanup(self)
end