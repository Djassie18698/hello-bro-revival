--VIP_Gift_Cell
--litao
--2014.4.10
---------------------------------------------
module("ui_giftDetailCell", package.seeall)
baseClass(layer_base_t, ui_giftDetailCell)

function init(self, cellSize, data)
	local ccbiAttrTable = {name="store/GiftDetailCell.ccbi", size=cellSize}
	layer_base_t.init(self, true, ccbiAttrTable)

	self.cellData = data
	--init	
	self.gift_data = {} 
	self:init_ui()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		--label
		self["label_gift_name"] = tolua.cast(self.proxy_:getNode("label_gift_name"), "CCLabelTTF")
		self["label_gift_num"] = tolua.cast(self.proxy_:getNode("label_gift_num"), "CCLabelTTF")
		self["label_gift_desc"] = tolua.cast(self.proxy_:getNode("label_gift_desc"), "CCLabelTTF")
		self["sprite_gift_icon"] = tolua.cast(self.proxy_:getNode("sprite_gift_icon"), "CCSprite")
		self.spr_gift_icon = tolua.cast(self.proxy_:getNode("sprite_gift_icon"), "CCSprite")

		--suit icon
		self.m_suitframes={'icon_title_yellow','icon_title_green','icon_title_blue','icon_title_purple','icon_title_orange'}
		--show info
		self:setObjInfo()
	end
end

--获取物品数据
function setObjInfo(self)
	---[[
	local data = DataMgr.GetDataByID("Struct_Dropinfo", tonumber(self.cellData._id))
	if data then
		self.gift_data.obj_desc =  tostring(data.m_dropdesc)
		self.gift_data.obj_num = tonumber(data.m_drop_num)
		if self.gift_data.obj_num == nil then
			self.gift_data.obj_num = 2
		end

		if tonumber(data.m_ninja_id) > 0 then				--忍者卡
			local ninja_data = DataMgr.GetDataByID("Struct_Ninjainfo", data.m_ninja_id)
			self.gift_data.obj_name = tostring(ninja_data.m_ninjaname)
			self.gift_data.pIcon,self.gift_data.pFrame = rl_get_iconsprite(1, 1, E_FRAMETYPE_SMALL, data.m_ninja_id)
		elseif tonumber(data.m_equip_id) > 0 then			--装备卡
			local ninja_data = DataMgr.GetDataByID("Struct_Equipmentinfo", data.m_equip_id)
			self.gift_data.obj_name = tostring(ninja_data.m_equipname)
			self.gift_data.pIcon,self.gift_data.pFrame = rl_get_iconsprite(1, 2, E_FRAMETYPE_SMALL, data.m_equip_id)
			--suit icon
			if ninja_data.m_equip_skill > 0 then
				self:setSuitIcon(ninja_data.m_quality)
			end
		elseif tonumber(data.m_skill_id) > 0 then			--忍术卡
			local ninja_data = DataMgr.GetDataByID("Struct_Ninjutsuinfo", data.m_skill_id)
			self.gift_data.obj_name = tostring(ninja_data.m_ninjutsuName)
			self.gift_data.pIcon,self.gift_data.pFrame = rl_get_iconsprite(1, 4, E_FRAMETYPE_SMALL, data.m_skill_id)
			--suit icon
			if ninja_data.m_skill_suit > 0 then
				self:setSuitIcon(ninja_data.m_quality)
			end
		elseif tonumber(data.m_mark_id) > 0 then			--印记/印记碎片
			local ninja_data = DataMgr.GetDataByID("Struct_Markinfo", data.m_mark_id)
			self.gift_data.obj_name = tostring(ninja_data.m_markname)
			self.gift_data.pIcon,self.gift_data.pFrame = rl_get_iconsprite(1, 3, E_FRAMETYPE_SMALL, data.m_mark_id)
			--suit icon
			if ninja_data.m_mark_suit > 0 then
				self:setSuitIcon(ninja_data.m_quality)
			end
		elseif tonumber(data.m_prop_id) > 0 then			--物品卡
			local ninja_data = DataMgr.GetDataByID("Struct_Consumeinfo", data.m_prop_id)
			self.gift_data.obj_name = tostring(ninja_data.m_namestr)
			self.gift_data.pIcon = rl_get_iconsprite(2, 0, E_FRAMETYPE_SMALL, data.m_prop_id)
		elseif tonumber(data.m_suipians_id) > 0 then		--装备碎片
			local ninja_data = DataMgr.GetDataByID("Struct_Piece_Info", data.m_suipians_id)
			self.gift_data.obj_name = tostring(ninja_data.m_piece_name)
			self.gift_data.pIcon = rl_get_iconsprite(5, 0, E_FRAMETYPE_SMALL, data.m_suipians_id)
		elseif tonumber(data.m_yinzi_num) > 0 then
			self.gift_data.obj_name = localizable.ui_border_silver
			self.gift_data.pIcon = rl_get_iconsprite(3, 0, E_FRAMETYPE_SMALL, 0)
		elseif tonumber(data.m_yuanbao_num) > 0 then
			self.gift_data.obj_name = localizable.ui_border_gold
			self.gift_data.pIcon = rl_get_iconsprite(4, 0, E_FRAMETYPE_SMALL, 0)
		elseif tonumber(data.m_renhuns_num) > 0 then
			self.gift_data.obj_name = localizable.ui_soul_name
			self.gift_data.pIcon = rl_get_iconsprite(6, 0, E_FRAMETYPE_SMALL, 0)
		end	

		self["label_gift_name"]:setString(self.gift_data.obj_name)
		self["label_gift_desc"]:setString(self.gift_data.obj_desc)
		self["label_gift_num"]:setString(tostring(self.gift_data.obj_num))

		--frame
		if self.gift_data.pFrame ~= nil then
			self["spr_gift_icon"]:setDisplayFrame(self.gift_data.pFrame)
		end

		--icon
		if self.gift_data.pIcon ~= nil then
			local _icon = self.gift_data.pIcon
			local size = self["sprite_gift_icon"]:getContentSize()
			self["sprite_gift_icon"]:addChild(_icon)
			_icon:setPosition(ccp(size.width/2, size.height/2))
			_icon:setAnchorPoint(ccp(0.5, 0.5))
		else
			cclog("frame is nil")
		end
	end
	--]]
end

function setSuitIcon(self, _quality)
	--suit icon
	CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile("ccbResources/equip_suit.plist")
	local pIcon = CCSprite:createWithSpriteFrameName(self.m_suitframes[_quality - 1])
	if pIcon ~= nil then
		local _iconSize = pIcon:getContentSize()
		local _nodeSize = self["sprite_gift_icon"]:getContentSize()
		pIcon:setPosition(ccp(_iconSize.width * 0.5, _nodeSize.height - _iconSize.height * 0.5))
		pIcon:setAnchorPoint(ccp(0.5,0.5))
		self["sprite_gift_icon"]:addChild(pIcon, 1)
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