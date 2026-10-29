module("ui_commonBuyItemDialogCell", package.seeall)
baseClass(layer_base_t, ui_commonBuyItemDialogCell)

require("ui_layer/ui_purchaseLayer")

INDEX_LEFT = 1
INDEX_RIGHT = 2

function init(self, data, preData, cellSize, parent)
	local ccbiAttrTable = { name = "dlg_ui/CommonBuyCellForLua.ccbi", size = cellSize }
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()
	layer_base_t.init(self, true, ccbiAttrTable)

    self.preData = preData
    self.data = data 
    self.itemInfo = {}
	self.parent = parent
	self:init_ui()
    self:init_binding_event()
end

function init_ui(self)
    if self.proxy_ ~= nil then

        local proxy = self.proxy_

        self.item_left = createButtonItem(self, "left", INDEX_LEFT)
        self.item_right = createButtonItem(self, "right", INDEX_RIGHT)
        self.text_buy_desc = getLabelTTFFromCCB(proxy, "text_buy_desc")
        self.btn_buy = getButtonFromCCB(proxy, "btn_buy")

        self:refreshData()
    end
end

function refreshData(self)

    local icon
    local quality = 1
    local frame
    local num
    self.cost_info = {}
    if tonumber(self.data.silver) ~= 0 then
        icon = CGameObjElement:GetConsumeIcon(E_FRAMETYPE_SMALL, "props_036")
        num = self.data.silver
        self.cost_info.is_cost_gold = false
        self.cost_info.num = num
    elseif tonumber(self.data.gold) ~= 0 then
        icon = CGameObjElement:GetConsumeIcon(E_FRAMETYPE_SMALL, "props_037")
        num = self.data.gold
        self.cost_info.is_cost_gold = true
        self.cost_info.num = num
    else
        icon = CGameObjElement:GetConsumeIcon(E_FRAMETYPE_SMALL, "props_122")
        num = 0
        self.cost_info.is_cost_gold = false
        self.cost_info.num = 0
    end
    frame = rl_get_frameicon(E_FRAMETYPE_SMALL, 1)
    setAttrForButtonItem(self.item_left, icon, frame, num)
    self.itemInfo[INDEX_LEFT] = {
        desc = ""
    }

    self.text_buy_desc:setString(localizable.ui_festival_buyTimesDesc .. self.data.buyRemainTimes .. "/" .. self.data.buyTotalTimes)

    local item_info = DataMgr.GetDataByID("Struct_Consumeinfo", tonumber(self.data.id))
    if tonumber(self.data.id) == self.preData.itemA.id then
        quality = self.preData.itemA.quality
    elseif tonumber(self.data.id) == self.preData.itemB.id then
        quality = self.preData.itemB.quality
    else
        quality = 1
    end
    --cclog("icon = " .. item_info.m_icon)
    icon = CGameObjElement:GetConsumeIcon(E_FRAMETYPE_SMALL, item_info.m_icon)
    frame = rl_get_frameicon(E_FRAMETYPE_SMALL, quality)
    num = 1
    setAttrForButtonItem(self.item_right, icon, frame, num)
    self.itemInfo[INDEX_RIGHT] = {
        desc = item_info.m_consumedesc
    }
end

function createButtonItem(layer, name, btn_index)
    local btn_item = {}

    local proxy = layer.proxy_

    btn_item.btn = getButtonFromCCB(proxy, "btn_item_" .. name)
    btn_item.frame = getSpriteFromCCB(proxy, "sprite_frame_" .. name)
    btn_item.icon = getSpriteFromCCB(proxy, "sprite_icon_" .. name)
    btn_item.text_num = getLabelBMFontFromCCB(proxy, "text_num_" .. name)
    btn_item.piece_flag = getSpriteFromCCB(proxy, "sprite_piece_" .. name)
    btn_item.btn.index = btn_index

    return btn_item
end

function setAttrForButtonItem(btn_item, icon, frame, num, isPiece)
    if btn_item then
        btn_item.frame:setDisplayFrame(frame)
        btn_item.icon:setDisplayFrame(icon)
        btn_item.piece_flag:setVisible(isPiece or false)
        if tonumber(num) == 1 then
            --btn_item.text_num:setVisible(false)
        end
        btn_item.text_num:setString(num)
    end
end

function init_binding_event(self)

    self:init_btn_binding_event(self.btn_buy, 
        function (button, event)
            self:buy()
        end,
        localizable.ui_festival_buyDesc
    )

    function showItemInfo(button, event)

        local data = self.itemInfo[button.index]
        if data.desc ~= "" then
            CGameObjElement:ShowCommonItemDetail(0, 0, 0, data.desc)
        end
    end

    self:init_btn_binding_event(self.item_left.btn, showItemInfo, "")
    self:init_btn_binding_event(self.item_right.btn, showItemInfo, "")
end

function buy(self)

    --cclog("%s", "¹ºÂò")

    if self.cost_info.is_cost_gold == true and self.playerData_.m_gold < self.cost_info.num then

        GetMainMenu():ShowTextTip(localizable.ui_monopoly_gold_not_enough, -1)
        local prePayLayer = createObj(ui_commonPrePay)
        GetMainMenu():GetModelLayer():AddDialog(prePayLayer.node_, 3)        

    elseif self.cost_info.is_cost_gold == false and self.playerData_.m_silver < self.cost_info.num then

        GetMainMenu():ShowTextTip(localizable.ui_attribute_silver_not_enough, -1)
        ShowCommonBuyItemDialog(kConsumableTypeItem, SMALL_COIN_ITEM_ID, BIG_COIN_ITEM_ID, 0)

    else
        local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 1700, "rl_w_shopbuy")
        urlpath = AddData(urlpath, "Goodsid", self.data.id)
        urlpath = AddData(urlpath, "Counts", 1)
        --cclog("rl_w_shopbuy = %s", urlpath)
        function refreshDataCallback(data)

            --cclog("callback data = %s", data)

            if self.preData.itemA.id == self.data.id then
                self.preData.itemA.num = self.preData.itemA.num + 1
            elseif self.preData.itemB.id == self.data.id then
                self.preData.itemB.num = self.preData.itemB.num + 1
            end

            self.data.buyRemainTimes = self.data.buyRemainTimes - 1
            self.text_buy_desc:setString(localizable.ui_festival_buyTimesDesc .. self.data.buyRemainTimes .. "/" .. self.data.buyTotalTimes)

            GetMainMenu():ShowTextTip(localizable.ui_buy_success_tips, -1)

            self.parent:updateUI(self.preData)
        end

        sendRequest(urlpath, refreshDataCallback)
    end
    --]]
end



---------------------common------------------------

function onNodeCleanup(self)
    if self.proxy_ then
        self.proxy_:release()
        self.proxy_ = nil
    end
    layer_base_t.onNodeCleanup(self)
end

function getNumber(data, name)
    return tonumber(data:find(name)[1])
end

function init_btn_binding_event(self, btn_node, callback, btn_title_text)
    btn_node:setTouchEnabled(true)
    btn_node:setTouchPriority(kCCMenuHandlerPriority - 1)
    self.proxy_:handleButtonEvent(btn_node, callback , CCControlEventTouchUpInside)
    if btn_title_text ~= nil then
        --btn_node:setTitleForState(btn_title_text, CCControlStateNormal)
        --btn_node:setTitleForState(btn_title_text, CCControlStateHighlighted)
        --btn_node:setTitleForState(btn_title_text, CCControlStateDisabled)    
    end
end