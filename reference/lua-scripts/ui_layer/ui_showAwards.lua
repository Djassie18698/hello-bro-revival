----------------------------------------------------------------------
--  Copyright (c) 2014-2016, XCKOO. All Rights Reserved.
--  Author :Tango
--  Time   :2015-11-18 14:22:02
--  Remark :十连抽奖励
----------------------------------------------------------------------


module("ui_showAwards", package.seeall)
baseClass(layer_base_t, ui_showAwards)

function init(self, node, data)
    self.playerMgr_ = CPlayerDataMgr:instance()
    self.playerData_ = self.playerMgr_:GetPlayerInfoData()

    -- Load res
    self.contentSize_ = GetMainMenu():GetSubContentNode():getContentSize()
    local ccbiAttrTable = { name = "dlg_ui/ShowAwards.ccbi", size = self.contentSize_ }
    layer_base_t.init(self, true, ccbiAttrTable)

    self.preNode = node

    self.itemlist = data

    -- tableView cell container
    self.cellNodes = { }
    --

    -- init && bindEvent
    --- [[
    self:init_ui(data)
    self:init_binding_event()
    -- ]]
end


function init_ui(self, data)
    if self.proxy_ ~= nil then
        self.btnClose = getButtonFromCCB(self.proxy_, 'closeButton')
        self.btnOK = getButtonFromCCB(self.proxy_, 'btnOK')

        for i = 1, 10 do
            self['sprFrame' .. i] = getSpriteFromCCB(self.proxy_, 'sprite_cardframe' .. i)
            self['nodeItemIcon' .. i] = getNodeFromCCB(self.proxy_, 'sprite_itemicon' .. i)
            self['lbNum' .. i] = getLabelBMFontFromCCB(self.proxy_, 'label_count' .. i)
            self['lbName' .. i] = getLabelTTFFromCCB(self.proxy_, 'label_cardname' .. i)
            self['sprType' .. i] = getSpriteFromCCB(self.proxy_, 'sprite_type_' .. i)
            self['btnCard' .. i] = getButtonFromCCB(self.proxy_, 'btn_card' .. i)
        end

        local labelTitle = getLabelTTFFromCCB(self.proxy_, 'labelTitle')
        labelTitle:setString(localizable.ui_showAwards_title)

        self:fillItemsInfo()
    end
end

function fillItemsInfo(self)
    for i = 1, 10 do
        if i > #self.itemlist then
            return
        end

        local nodeIcon = self['nodeItemIcon' .. i]
        local sprFrm = self['sprFrame' .. i]
        _maintype, _subtype, _id, _num, _drop_type = setObjTypeInfo(tonumber(self.itemlist[i]))
        local sprite_icon, sprite_frame, quality, name = rl_get_iconsprite(_maintype, _subtype, E_FRAMETYPE_SMALL, _id)
        if sprite_icon ~= nil then
            if sprite_frame ~= nil then
                sprFrm:setDisplayFrame(sprite_frame)
            else
                sprFrm:setDisplayFrame(CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("small_box_skill_01"))
            end
            local iconsize = nodeIcon:getContentSize()
            sprite_icon:setPosition(iconsize.width / 2, iconsize.height / 2)
            sprite_icon:setAnchorPoint(ccp(0.5, 0.5))
            nodeIcon:removeAllChildrenWithCleanup(true)
            sprite_icon:setScale(0.9)
            nodeIcon:addChild(sprite_icon)
        end

        -- 数量
        if _num > 1 then
            self['lbNum' .. i]:setString(tostring(_num))
            self['lbNum' .. i]:setVisible(true)
        else
            self['lbNum' .. i]:setVisible(false)
        end

        self['lbName' .. i]:setString(name)

        -- 类型
        sprType = self["sprType" .. i]
        if _maintype == 5 then
            sprType:setVisible(true)
        elseif _maintype == 1 and _subtype == 5 then
            sprType:setVisible(true)
        else
            sprType:setVisible(false)
        end
    end
end

function init_binding_event(self)
    if self.proxy_ ~= nil then
        -- 屏蔽掉后层触摸事件
        local function CCLayerTouch(event, x, y)
            if event == "began" then
                return true
            end
        end

        self.node_:setTouchEnabled(true)
        self.node_:registerScriptTouchHandler(CCLayerTouch, false, kCCMenuHandlerPriority - 1, true)

        local function onBtnClose(btn, event)
            CSoundMgr:instance():PlayEffect(SOUND_BUTTON)
            self.node_:removeFromParentAndCleanup(true)
        end

        -- back
        self.btnClose:setTouchPriority(kCCMenuHandlerPriority - 1)
        self.proxy_:handleControlEvent(self.btnClose, onBtnClose, CCControlEventTouchUpInside)

        self.btnOK:setTouchPriority(kCCMenuHandlerPriority - 1)
        self.proxy_:handleControlEvent(self.btnOK, onBtnClose, CCControlEventTouchUpInside)

        for i = 1, 10 do
            local btn = self['btnCard' .. i]
            btn:setTouchPriority(kCCMenuHandlerPriority - 1)
            self.proxy_:handleControlEvent(btn, function(button, event)
                self:onClickedIcon(i)
            end , CCControlEventTouchUpInside)
        end
    end
end


function onClickedIcon(self, i)
    CSoundMgr:instance():PlayEffect(SOUND_BUTTON)

    if i < 0 or i > #self.itemlist then
        return nil
    end

    local function showDetail(dropid)
    	_maintype, _subtype, _id, _num, _drop_type = setObjTypeInfo(tonumber(dropid))
        local sprite_icon, sprite_frame, quality, name = rl_get_iconsprite(_maintype, _subtype, E_FRAMETYPE_SMALL, _id)

        if _maintype == 5 then
            local descStr = name .. localizable.ui_secret_shop_suipian .. tostring(_num)
            -- CGameObjElement:ShowCommonItemDetail(tonumber(_maintype), tonumber(_subtype), tonumber(self.data.icon), descStr)
            local info = DataMgr.GetDataByID("Struct_Piece_Info", tonumber(_id))
            if info.m_piece_type == 1 then
                CGameObjElement:ShowCommonItemDetail(1, 1, tonumber(info.m_piece_targetthingID), descStr)
            elseif info.m_piece_type == 2 then
                CGameObjElement:ShowCommonItemDetail(1, 2, tonumber(info.m_piece_targetthingID), descStr)
            elseif info.m_piece_type == 3 then
                CGameObjElement:ShowCommonItemDetail(1, 3, tonumber(info.m_piece_targetthingID), descStr)
            elseif info.m_piece_type == 5 then
                -- 宠物碎片，显示宠物详情
                CGameObjElement:ShowCommonItemDetail(7, 5, tonumber(info.m_piece_targetthingID), descStr)
            end
        elseif _maintype == 1 and _subtype == 5 then
            local descStr = name .. localizable.ui_secret_shop_suipian .. tostring(_num)
            CGameObjElement:ShowCommonItemDetail(tonumber(_maintype), tonumber(_subtype), tonumber(_id), descStr)
        else
            local descStr = name .. " x " .. tostring(_num)
            CGameObjElement:ShowCommonItemDetail(tonumber(_maintype), tonumber(_subtype), tonumber(_id), descStr)
        end
    end

	showDetail(self.itemlist[i])

end

function onNodeCleanup(self)
    -- cclog("onNodeCleanup")
    if self.proxy_ then
        self.proxy_:release()
    end
    layer_base_t.onNodeCleanup(self)
end

function createTestData(self)
    return nil
end