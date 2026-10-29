
module("ui_ninjaTestIntegralAwardListCell", package.seeall)
baseClass(layer_base_t, ui_ninjaTestIntegralAwardListCell)

function init(self, data, cellSize, parent)
	local ccbiAttrTable = { name = "sub_ui/NinjaTestIntegralAwardListCellView.ccbi", size = cellSize }
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()
	layer_base_t.init(self, true, ccbiAttrTable)

    self.data = data
    --[[
    cclog("dump data")
    for k, v in pairs(self.data) do
        cclog("[" .. k .. "] = " .. v)
    end
    ]]    
	self.parent = parent
    self.id = 0
    self.num = 0
    self.name = ""
	self:init_ui()
    self:init_binding_event()
end

function init_ui(self)
	if self.proxy_ ~= nil then
        local proxy = self.proxy_

        self.text_item_num = getLabelBMFontFromCCB(proxy, "text_item_num")
        self.text_item_name = getLabelTTFFromCCB(proxy, "text_item_name")
        self.text_item_desc = getLabelTTFFromCCB(proxy, "text_item_desc")
        self.btn_exchange = getButtonFromCCB(proxy, "btn_exchange")
        self.text_exchange_desc = getLabelTTFFromCCB(proxy, "text_exchange_desc")
        self.text_integral_num = getLabelBMFontFromCCB(proxy, "text_integral_num")
        self.text_gold_num = getLabelBMFontFromCCB(proxy, "text_gold_num")
        self.text_silver_num = getLabelBMFontFromCCB(proxy, "text_silver_num")
        self.sprite_gold = getSpriteFromCCB(proxy, "sprite_gold")
        self.sprite_silver = getSpriteFromCCB(proxy, "sprite_silver")
        self.sprite_item_icon = getSpriteFromCCB(proxy, "sprite_item_icon")
        self.sprite_item_frame = getSpriteFromCCB(proxy, "sprite_item_frame")
        self.btn_item = getButtonFromCCB(proxy, "btn_item")
        self.sprite_piece_tip = getSpriteFromCCB(proxy, "sprite_piece_tip")

        self:refreshData()
	end
end

function refreshData(self)
    
    ---[[
    --cclog("drop_id = " .. self.data.drop_id)
    local info = DataMgr.GetDataByID("Struct_Dropinfo", tonumber(self.data.drop_id))
    if info == nil then
        return
    end

    local drop_type = info.m_drop_type
    --cclog("drop_type = " .. drop_type)

    
    local renhun_num = info.m_renhuns_num
    local yuanbao_num = info.m_yuanbao_num
    local yinzi_num = info.m_yinzi_num


    local INVALID_VALUE = 0
    
    local itemInfo = ItemDataInfo:new()
    CGameObjElement:GetItemInfoByDropid(self.data.drop_id, itemInfo)
    local icon
    local frame
    local quality
    local name
    local desc

    --cclog("mainType = " .. itemInfo.mainType)
    --cclog("subType = " .. itemInfo.subType)

    -- 记录物品id
    -- 忍者
    local ninja_id = INVALID_VALUE
    local equip_id = INVALID_VALUE
    local skill_id = INVALID_VALUE
    local mark_id = INVALID_VALUE
    local prop_id = INVALID_VALUE
    local suipians_id = INVALID_VALUE
    local pet_id = INVALID_VALUE

    if info.m_ninja_id ~= INVALID_VALUE then
        ninja_id = info.m_ninja_id
        self.id = ninja_id
        --cclog("ninja_id = " .. ninja_id)
    -- 装备
    elseif info.m_equip_id ~= INVALID_VALUE then
        equip_id = info.m_equip_id
        self.id = equip_id
        --cclog("equip_id = " .. equip_id)
    -- 忍术
    elseif info.m_skill_id ~= INVALID_VALUE then 
        skill_id = info.m_skill_id
        self.id = skill_id
        --cclog("skill_id = " .. skill_id)
    -- 印记
    elseif info.m_mark_id ~= INVALID_VALUE then
        mark_id = info.m_mark_id
        self.id = mark_id
        --cclog("mark_id = " .. mark_id)
    -- 道具
    elseif info.m_prop_id ~= INVALID_VALUE then
       prop_id = info.m_prop_id
       self.id = prop_id
       --cclog("prop_id = " .. prop_id)
    -- 碎片
    elseif info.m_suipians_id ~= INVALID_ID then
        suipians_id = info.m_suipians_id
        self.id = suipians_id
        --cclog("suipians_id = " .. suipians_id)
    -- 通灵兽
    elseif info.m_pet_id ~= INVALID_VALUE then
        pet_id = info.m_pet_id
        self.id = pet_id
        --cclog("pet_id = " .. pet_id)
    end
    
    -- 记录掉落的物品数量
    self.num = info.m_drop_num

    -- 礼包
    if drop_type == 1 then

        icon = CGameObjElement:GetConsumeIcon(E_FRAMETYPE_SMALL, self.data.icon)
        frame = rl_get_frameicon(E_FRAMETYPE_SMALL, self.data.quality)
        name = self.data.reward_name
        desc = self.data.show

    -- 固定掉落
    elseif itemInfo.mainType ~= 0 and itemInfo.subType ~= 0 then
        -- 忍者卡
        if ninja_id ~= INVALID_VALUE then
            local ninjainfo = DataMgr.GetDataByID("Struct_Ninjainfo", tonumber(ninja_id))
            desc = ninjainfo.m_ninjadesc
            icon, frame, quility, name = rl_get_iconsprite(itemInfo.mainType, itemInfo.subType, E_FRAMETYPE_SMALL, ninja_id, true)
            self.sprite_item_icon:setScale(0.85)

        -- 装备
        elseif equip_id ~= INVALID_VALUE then
            local equipinfo = DataMgr.GetDataByID("Struct_Equipmentinfo", tonumber(equip_id))
            desc = equipinfo.m_equipdesc
            icon, frame, quility, name = rl_get_iconsprite(itemInfo.mainType, itemInfo.subType, E_FRAMETYPE_SMALL, equip_id, true)

        -- 忍术
        elseif skill_id ~= INVALID_VALUE then
            local skillinfo = DataMgr.GetDataByID("Struct_Ninjutsuinfo", tonumber(skill_id))
            desc = skillinfo.m_descinfo
            icon, frame, quility, name = rl_get_iconsprite(itemInfo.mainType, itemInfo.subType, E_FRAMETYPE_SMALL, skill_id, true)

        -- 通灵兽
        elseif pet_id ~= INVALID_VALUE then
            local petinfo = DataMgr.GetDataByID("Struct_Petinfo", tonumber(pet_id))
            desc = petinfo.m_pet_skilldes
            icon, frame, quality, name = rl_get_iconsprite(7, itemInfo.subType, E_FRAMETYPE_SMALL, pet_id, true)
            self.sprite_item_icon:setScale(0.85)
            self.isPet = true

        -- 印记
        elseif mark_id ~= INVALID_VALUE then
            local markinfo = DataMgr.GetDataByID("Struct_Markinfo", tonumber(mark_id))
            desc = markinfo.m_markdesc
            icon, frame, quility, name = rl_get_iconsprite(itemInfo.mainType, itemInfo.subType, E_FRAMETYPE_SMALL, mark_id, true)

        -- 道具
        elseif prop_id ~= INVALID_VALUE then
            local propinfo = DataMgr.GetDataByID("Struct_Consumeinfo", prop_id)
            desc = propinfo.m_consumedesc
            icon, frame, quility, name = rl_get_iconsprite(itemInfo.mainType, itemInfo.subType, E_FRAMETYPE_SMALL, prop_id, true)

        -- 碎片
        elseif suipians_id ~= INVALID_VALUE then
            local pieceinfo = DataMgr.GetDataByID("Struct_Piece_Info", tonumber(suipians_id))
            desc = self.data.show
            icon, frame, quility, name = rl_get_iconsprite(itemInfo.mainType, itemInfo.subType, E_FRAMETYPE_SMALL, suipians_id, true)
            self.isPiece = true
            self.sprite_item_icon:setScale(0.85)

        -- 忍魂
        elseif renhun_num ~= INVALID_VALUE then
            --cclog("renhun_num = " .. renhun_num)
            desc = localizable.ui_ninjaTest_desc_soul
            icon, frame, quility, name = rl_get_iconsprite(itemInfo.mainType, itemInfo.subType, E_FRAMETYPE_SMALL, itemInfo.itemId, true)

        -- 元宝
        elseif yuanbao_num ~= INVALID_VALUE then
            --cclog("yuanbao_num = " .. yuanbao_num)
            desc = localizable.ui_ninjaTest_desc_gold
            icon, frame, quility, name = rl_get_iconsprite(itemInfo.mainType, itemInfo.subType, E_FRAMETYPE_SMALL, itemInfo.itemId, true)

        -- 银子
        elseif yinzi_num ~= INVALID_VALUE then
            --cclog("yinzi_num = " .. yinzi_num)
            desc = localizable.ui_ninjaTest_desc_silver
            icon, frame, quility, name = rl_get_iconsprite(itemInfo.mainType, itemInfo.subType, E_FRAMETYPE_SMALL, itemInfo.itemId, true)
        end

    else
        GetMainMenu():ShowTextTip(text.text_config[10009].description,-1)
    end

    if icon == nil then
        --cclog("无法获得icon")
        return
    end
    self.sprite_item_icon:setDisplayFrame(icon)

    if frame == nil then
        --cclog("无法获得frame")
        return
    end
    self.sprite_item_frame:setDisplayFrame(frame)

    if name == nil then
        --cclog("无法获得name")
        return
    end
    self.text_item_name:setString(name)
    self.name = name

    self.text_item_desc:setString(desc)  
    self.desc = desc

    if self.num == 1 then
        self.text_item_num:setVisible(false)
    else
        self.text_item_num:setString(self.num)
    end



    self.text_integral_num:setString(self.data.score)

    if tonumber(self.data.cash) == 0 then
        self.text_gold_num:setVisible(false)
        self.sprite_gold:setVisible(false)
    else
        self.text_gold_num:setString(self.data.cash)
    end

    if tonumber(self.data.coin) == 0 then
        self.text_silver_num:setVisible(false)
        self.sprite_silver:setVisible(false)
    else
        self.text_silver_num:setString(self.data.coin)
    end

    self.text_exchange_desc:setString(localizable.ui_ninjaTest_exchange_desc)

    if self.isPiece == true then
        self.sprite_piece_tip:setVisible(true)
    else
        self.sprite_piece_tip:setVisible(false)
    end
    --]]
end

function init_binding_event(self)

     self:init_btn_binding_event(self.btn_item, 
            function(button, event)
            
            local itemInfo = ItemDataInfo:new()
            CGameObjElement:GetItemInfoByDropid(self.data.drop_id, itemInfo)
            --cclog("mainType = " .. itemInfo.mainType)
            local mainType = tostring(itemInfo.mainType)
            local subType = tostring(itemInfo.subType)
            if self.isPet == true then
                mainType = 7
            end
           -- cclog("mainType = " .. mainType)
           -- cclog("subType = " .. subType)

			if mainType == "5" then
				local descStr = self.name .. localizable.ui_secret_shop_suipian .. tostring(self.num)
                --cclog("click desc = " .. descStr)
				--CGameObjElement:ShowCommonItemDetail(tonumber(self.data.type), tonumber(self.data.subtype), tonumber(self.data.icon), descStr)
				local info = DataMgr.GetDataByID("Struct_Piece_Info", tonumber(self.id))
				if info.m_piece_type == 1 then
		            CGameObjElement:ShowCommonItemDetail(1, 1, tonumber(info.m_piece_targetthingID), descStr)
		        elseif info.m_piece_type == 2 then
		            CGameObjElement:ShowCommonItemDetail(1, 2, tonumber(info.m_piece_targetthingID), descStr)
		        elseif info.m_piece_type == 3 then
		            CGameObjElement:ShowCommonItemDetail(1, 3, tonumber(info.m_piece_targetthingID), descStr)
                elseif info.m_piece_type == 5 then--宠物碎片，显示宠物详情
                    CGameObjElement:ShowCommonItemDetail(7, 5, tonumber(info.m_piece_targetthingID), descStr)
		        end    
			elseif mainType == "1" and subType == "5" then
				local descStr = self.name .. localizable.ui_secret_shop_suipian .. tostring(self.num)
				CGameObjElement:ShowCommonItemDetail(tonumber(mainType), tonumber(subType), tonumber(self.id), descStr)
                --cclog("descStr = " .. descStr)
            else
				local descStr = self.desc
				CGameObjElement:ShowCommonItemDetail(tonumber(mainType), tonumber(subType), tonumber(self.id), descStr)
                --cclog("descStr = " .. descStr)
			end
            end,
            ""
        )
     self:init_btn_binding_event(self.btn_exchange, 
            function(button, event)
                self:exchangeAward()
            end,
            localizable.ui_ninjaTest_exchange
        )
end

function exchangeAward(self)
    -- 请求基本信息  
  	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 3, "rl_x_exam")
    urlpath = AddData(urlpath,"reward_id", self.data.reward_id)
    --cclog("rl_x_ninja_challenge & cmd = 1---%s", urlpath)
    GetMainMenu():ShowLoadingDlg()
    CCHttpRequest:open(urlpath, kHttpPost, "query=param1&other=params"):sendWithHandler(
    function(res, hnd)
        GetMainMenu():CloseLoadding()
        local resData = res:getResponseData()
        local code = res:getResponseCode()
        local xfile = xml.parse(resData)

        local item = xfile:find("RENLONG")
        if item == nil then
            return nil
        end
      --  cclog("%s", resData)
        local retcode = item.code
        if retcode == "0" then
            local integral = tonumber(item:find("score")[1])
            --getNumber(item, "score")
            local award = xfile:find("award")
            ShowAward(award)         
            self.playerMgr_:AddGold(-self.data.cash)
            self.playerMgr_:AddSilver(-self.data.coin)
            self.parent:refreshData(integral)
        else
            GetMainMenu():ShowErrorTip(tonumber(retcode), -1)
            --GetMainMenu():ShowTextTip(text.text_config[tonumber(retcode)].description, -1)

        end
    end )

end

function onNodeCleanup(self)
	--- [[
	if self.proxy_ then
		self.proxy_:release()
		self.proxy_ = nil
	end
	-- ]]
	layer_base_t.onNodeCleanup(self)
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

function getNumber(data, name)
    return tonumber(data:find(name)[1])
end
