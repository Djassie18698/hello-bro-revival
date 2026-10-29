
module("ui_festivalCellView", package.seeall)
baseClass(layer_base_t, ui_festivalCellView)

INDEX_SINGLE_ITEM = 1
INDEX_SINGLE_RESULT = 2
INDEX_MULTIPLE_LEFT = 3
INDEX_MULTIPLE_RIGHT = 4
INDEX_MULTIPLE_RESULT = 5

function init(self, data, item_data, cellSize, parent)
	local ccbiAttrTable = { name = "activity/FestivalCell.ccbi", size = cellSize }
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()
	layer_base_t.init(self, true, ccbiAttrTable)

    self.data = data
    self.itemInfo = {}  
    self.item_data = item_data
	self.parent = parent
	self:init_ui()
    self:init_binding_event()
end

function init_ui(self)
	if self.proxy_ ~= nil then
        local proxy = self.proxy_

        self.btn_exchange = getButtonFromCCB(proxy, "btn_exchange")
        self.text_exchange_desc = getLabelTTFFromCCB(proxy, "text_exchange_desc")

        self.node_single_exchange = getNodeFromCCB(proxy, "node_single_exchange")
        self.node_multiple_exchange = getNodeFromCCB(proxy, "node_multiple_exchange")

        self.single_item = createButtonItem(self, INDEX_SINGLE_ITEM)
        self.single_result = createButtonItem(self, INDEX_SINGLE_RESULT)
        self.multiple_left = createButtonItem(self, INDEX_MULTIPLE_LEFT)
        self.multiple_right = createButtonItem(self, INDEX_MULTIPLE_RIGHT)
        self.multiple_result = createButtonItem(self, INDEX_MULTIPLE_RESULT)

        self:refreshData()
	end
end


function createButtonItem(layer, btn_index)
    local btn_item = {}

    local proxy = layer.proxy_

    btn_item.btn = getButtonFromCCB(proxy, "btn_item_" .. btn_index)
    btn_item.frame = getSpriteFromCCB(proxy, "sprite_frame_" .. btn_index)
    btn_item.icon = getSpriteFromCCB(proxy, "sprite_icon_" .. btn_index)
    btn_item.text_num = getLabelBMFontFromCCB(proxy, "text_num_" .. btn_index)
    btn_item.piece_flag = getSpriteFromCCB(proxy, "sprite_piece_" .. btn_index)
    btn_item.btn.index = btn_index

    return btn_item
end

function setAttrForButtonItem(btn_item, icon, frame, num, isPiece)
    if btn_item then
        btn_item.frame:setDisplayFrame(frame)
        btn_item.icon:setDisplayFrame(icon)

        local iconsize = btn_item.icon:getContentSize()
		local scalex = 83 / iconsize.width
		local scaley = 83 / iconsize.height
		if scalex > scaley then
			btn_item.icon:setScale(scaley)
		else
			btn_item.icon:setScale(scalex)
		end

        btn_item.piece_flag:setVisible(isPiece or false)
        if tonumber(num) == 1 then
            --btn_item.text_num:setVisible(false)
        end
        btn_item.text_num:setString(num)
    end
end

function refreshData(self)

    self.node_single_exchange:setVisible(self.data.isSingleExchange)
    self.node_multiple_exchange:setVisible(not self.data.isSingleExchange)
    
    if self.data.isSingleExchange then

        local data = nil
        if self.data.itemA.id ~= 0 then
            data = self.data.itemA     
        else
            data = self.data.itemB
        end

        self:setButtonItemAttr(self.single_item, data, INDEX_SINGLE_ITEM)
        self:setButtonResultItemAttr(self.single_result, self.data.itemC, INDEX_SINGLE_RESULT)

        resultIdx = INDEX_SINGLE_RESULT

    else

        self:setButtonItemAttr(self.multiple_left, self.data.itemA, INDEX_MULTIPLE_LEFT)
        self:setButtonItemAttr(self.multiple_right, self.data.itemB, INDEX_MULTIPLE_RIGHT)
        self:setButtonResultItemAttr(self.multiple_result, self.data.itemC, INDEX_MULTIPLE_RESULT)
        resultIdx = INDEX_MULTIPLE_RESULT

    end

    self:updateUI(self.data.remain_times) 
end

function setButtonResultItemAttr(self, btnItem, data, idx)

    local id = data.id

    local num = data.num
    local item_info = ItemDataInfo:new()
    CGameObjElement:GetItemInfoByDropid(id, item_info)
    local frame = rl_get_frameicon(E_FRAMETYPE_SMALL, item_info.quality)
    local icon = rl_get_iconsprite(data.mainType, item_info.subType, E_FRAMETYPE_SMALL, data.itemId, true)
    local isPiece = false
 	if tonumber(item_info.mainType) == 5 then
		isPiece = true
	elseif tonumber(item_info.mainType) == 1 and tonumber(item_info.subtype) == 5 then
		isPiece = true
	end
    setAttrForButtonItem(btnItem, icon, frame, num, isPiece)
    self.itemInfo[idx] = {
        num = num,
        mainType = data.mainType,
        subType = item_info.subType,
        id = data.itemId,
        name = item_info.name,
        desc = item_info.name
    }

end

function setButtonItemAttr(self, btnItem, data, idx)

    local id = data.id
    local num = data.num
    local quality = data.quality
    local item_info = DataMgr.GetDataByID("Struct_Consumeinfo", tonumber(id))
    local frame = rl_get_frameicon(E_FRAMETYPE_SMALL, quality)
    local icon = CGameObjElement:GetConsumeIcon(E_FRAMETYPE_SMALL, item_info.m_icon)
    setAttrForButtonItem(btnItem, icon, frame, num)
    self.itemInfo[idx] = {
        num = num,
        id = id,
        mainType = 0,
        subType = 0,
        name = item_info.m_namestr,
        desc = item_info.m_consumedesc
    }   

end

function init_binding_event(self)
   
   self:init_btn_binding_event(self.btn_exchange, 
        function(button, event)
            if global.is_click_outSide == true then
                global.is_click_outSide = false
                return
            end
            self:exchangeAward()
        end,
        localizable.ui_festival_exchangeDesc
    )

    function showItemInfo(button, event)

        if global.is_click_outSide == true then
            global.is_click_outSide = false
            return
        end

        local data = self.itemInfo[button.index]

        if data.mainType == 5 then
            local descStr = data.name .. localizable.ui_secret_shop_suipian .. tostring(data.num)
            local info = DataMgr.GetDataByID("Struct_Piece_Info", tonumber(data.id))
            if info.m_piece_type == 1 then
                CGameObjElement:ShowCommonItemDetail(1, 1, tonumber(info.m_piece_targetthingID), descStr)
            elseif info.m_piece_type == 2 then
                CGameObjElement:ShowCommonItemDetail(1, 2, tonumber(info.m_piece_targetthingID), descStr)
            elseif info.m_piece_type == 3 then
                CGameObjElement:ShowCommonItemDetail(1, 3, tonumber(info.m_piece_targetthingID), descStr)
            elseif info.m_piece_type == 5 then--宠物碎片，显示宠物详情
                CGameObjElement:ShowCommonItemDetail(7, 5, tonumber(info.m_piece_targetthingID), descStr)
            end    
        elseif data.mainType == 1 and data.subType == 5 then
            local descStr = data.name .. localizable.ui_secret_shop_suipian .. tostring(data.num)
            CGameObjElement:ShowCommonItemDetail(tonumber(data.mainType), tonumber(data.subType), tonumber(data.id), descStr)
        else
            local descStr = data.desc
            CGameObjElement:ShowCommonItemDetail(tonumber(data.mainType), tonumber(data.subType), tonumber(data.id), descStr)
        end
    end

    self:init_btn_binding_event(self.single_item.btn, showItemInfo, "")
    self:init_btn_binding_event(self.single_result.btn, showItemInfo, "")
    self:init_btn_binding_event(self.multiple_left.btn, showItemInfo, "")
    self:init_btn_binding_event(self.multiple_right.btn, showItemInfo, "")
    self:init_btn_binding_event(self.multiple_result.btn, showItemInfo, "")

end

function exchangeAward(self)

    ---[[
    local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 11, "rl_x_small_activity")
    urlpath = AddData(urlpath,"ExId", self.data.exchange_id)
    --cclog("urlpath = " .. urlpath)
    function exchangeAwardCallback(data)

        --cclog("callback data = %s", data)

        local award = data:find("award")
        ShowAward(award)

        local item_id
        local item_num

        if self.data.isSingleExchange then

            item_id = self.itemInfo[INDEX_SINGLE_ITEM].id
            self:updateItemData(item_id, self.itemInfo[INDEX_SINGLE_ITEM].num)
        else
            item_id = self.itemInfo[INDEX_MULTIPLE_LEFT].id
            self:updateItemData(item_id, self.itemInfo[INDEX_MULTIPLE_LEFT].num)

            item_id = self.itemInfo[INDEX_MULTIPLE_RIGHT].id
            self:updateItemData(item_id, self.itemInfo[INDEX_MULTIPLE_RIGHT].num)
        end

        self.data.remain_times = self.data.remain_times - 1
        self:updateUI()
        self.parent:updateUI(self.item_data)
    end

    sendRequest(urlpath, exchangeAwardCallback)
    --]]

end

function updateUI(self)
    self.text_exchange_desc:setString(localizable.ui_festival_exchangeTotalDesc .. self.data.remain_times .. "/" .. self.data.total_times)
end

function updateItemData(self, item_id, consume_num)
    if item_id == self.item_data.itemA.id then
        self.item_data.itemA.num = self.item_data.itemA.num - consume_num
    elseif item_id == self.item_data.itemB.id then
        self.item_data.itemB.num = self.item_data.itemB.num - consume_num
    end 
end

---------------------common------------------------

function onNodeCleanup(self)
	--- [[
	if self.proxy_ then
		self.proxy_:release()
		self.proxy_ = nil
	end
	-- ]]
	layer_base_t.onNodeCleanup(self)
end

function getNumber(data, name)
    return tonumber(data:find(name)[1])
end

function init_btn_binding_event(self, btn_node, callback, btn_title_text)
    btn_node:setTouchEnabled(true)
    btn_node:setTouchPriority(kCCMenuHandlerPriority - 0)
    self.proxy_:handleButtonEvent(btn_node, callback , CCControlEventTouchUpInside)
    if btn_title_text ~= nil then
        --btn_node:setTitleForState(btn_title_text, CCControlStateNormal)
        --btn_node:setTitleForState(btn_title_text, CCControlStateHighlighted)
        --btn_node:setTitleForState(btn_title_text, CCControlStateDisabled)    
    end
end
