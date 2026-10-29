require "util/localizable"

CommonBuyItemCellView=class(
		"CommonBuyItemCellView",
    function()
        return LuaSubView:create() 
    end
)

function CommonBuyItemCellView:create()
	local view = CommonBuyItemCellView.new();
	return view;
end

function CommonBuyItemCellView:loadCCBI()
	self:LoadCCBI("dlg_ui/BuyItemDialogCellView.ccbi",self.m_cellsize);
	
	self:initData()
end

function CommonBuyItemCellView:initData()
	if self.m_itemType == kConsumableTypeItem then
		self.m_itemInfo = tolua.cast(CTradeMgr:instance():GetConsumByIDForLua(self.m_itemId), "ConsumeInfo")
	else
		self.m_itemInfo = tolua.cast(CTradeMgr:instance():GetGiftByIDForLua(self.m_itemId), "Struct_Giftinfo")
	end
end

function CommonBuyItemCellView:initUI()
	if self.m_itemInfo == nil then
		return nil
	end

	-- 设置道具图标
	local itemName
	if self.m_itemType == kConsumableTypeItem then
		itemName = self.m_itemInfo.m_icon
	else
		itemName = self.m_itemInfo.m_icon
	end
	
	tolua.cast(self:getNode("sprite_item_frame"), "CCSprite"):removeAllChildrenWithCleanup(true)
	local frame = CGameObjElement:GetConsumeIcon(E_FRAMETYPE_SMALL,itemName)
	if frame ~= nil then
		local icon = CCSprite:createWithSpriteFrame(frame)
		local size = tolua.cast(self:getNode("sprite_item_frame"), "CCSprite"):getContentSize()
		tolua.cast(self:getNode("sprite_item_frame"), "CCSprite"):addChild(icon)
		icon:setPosition(size.width/2, size.height/2)
		local point = CCPoint:new()
		point.x = 0.5;
		point.y = 0.5;
		icon:setAnchorPoint(point);
	end
	
	-- 设置数量
	local count
	if self.m_itemType == kConsumableTypeItem then
		count = self.m_itemInfo.m_bagnum
	else
		count = 0
	end
	tolua.cast(self:getNode("label_item_count"), "CCLabelBMFont"):setString(count)
	
	-- 设置名字
	if self.m_itemType == kConsumableTypeItem then
		tolua.cast(self:getNode("label_item_name"), "CCLabelTTF"):setString(tostring(self.m_itemInfo.m_namestr))
	else
		tolua.cast(self:getNode("label_item_name"), "CCLabelTTF"):setString(tostring(self.m_itemInfo.m_giftname))
	end
	
	-- 设置描述
	if self.m_itemType == kConsumableTypeItem then
		tolua.cast(self:getNode("label_item_desc"), "CCLabelTTF"):setString(tostring(self.m_itemInfo.m_consumedesc))
	else
		tolua.cast(self:getNode("label_item_desc"), "CCLabelTTF"):setString(tostring(self.m_itemInfo.m_giftdesc))
	end
	
	-- 设置价格
	local goldprice
	local silverprice
	
	if self.m_itemType == kConsumableTypeItem then
		goldprice = self.m_itemInfo.m_needgold
		silverprice = self.m_itemInfo.m_needsilver
	else
		goldprice = self.m_itemInfo.m_price_gold
		silverprice = self.m_itemInfo.m_price_silver
	end 
	
	if goldprice > 0 then
		tolua.cast(self:getNode("label_item_price"), "CCLabelBMFont"):setString(tostring(goldprice))
		tolua.cast(self:getNode("sprite_silver_icon"), "CCSprite"):setVisible(false)
		tolua.cast(self:getNode("sprite_gold_icon"), "CCSprite"):setVisible(true)
	else
		tolua.cast(self:getNode("label_item_price"), "CCLabelBMFont"):setString(tostring(silverprice))
		tolua.cast(self:getNode("sprite_silver_icon"), "CCSprite"):setVisible(true)
		tolua.cast(self:getNode("sprite_gold_icon"), "CCSprite"):setVisible(false)
	end
	
	-- 是否选择单元
	if self.m_selected == true then
		tolua.cast(self:getNode("sprite_gou_frame"), "CCSprite"):setVisible(true)
		tolua.cast(self:getNode("sprite_gou"), "CCSprite"):setVisible(true)
		tolua.cast(self:getNode("sprite_bottom_dark"), "CCSprite"):setVisible(false)
		tolua.cast(self:getNode("sprite_bottom_light"), "CCSprite"):setVisible(true)
	else
		tolua.cast(self:getNode("sprite_gou_frame"), "CCSprite"):setVisible(false)
		tolua.cast(self:getNode("sprite_gou"), "CCSprite"):setVisible(false)
		tolua.cast(self:getNode("sprite_bottom_dark"), "CCSprite"):setVisible(true)
		tolua.cast(self:getNode("sprite_bottom_light"), "CCSprite"):setVisible(false)
	end
	
	return nil
end

function CommonBuyItemCellView:setIndex(idx)
	self.m_index = idx;
end

function CommonBuyItemCellView:getIndex()
	return self.m_index;
end

function CommonBuyItemCellView:setCellSize(size)
	self.m_cellsize = size;
end

function CommonBuyItemCellView:setItemIdData(itemid)
	self.m_itemId = itemid;
end

function CommonBuyItemCellView:getCellData()
	return self.m_itemId;
end

function CommonBuyItemCellView:setItemType(itemType)
	self.m_itemType = itemType
end

function CommonBuyItemCellView:getItemType()
	return self.m_itemType
end

function CommonBuyItemCellView:setSelected(selected)
	self.m_selected = selected
end
