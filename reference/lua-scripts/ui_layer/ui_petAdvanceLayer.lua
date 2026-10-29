------------------------------------------------------------------------
--  Copyright (c) 2011-2015, XCKOO. All Rights Reserved.
--  Author :Milo
--  FName  :ui_petAdvanceLayer.lua
--  Time   :2015年8月27日 14:28:02
--  Remark :宠物进阶
------------------------------------------------------------------------
module("ui_petAdvanceLayer", package.seeall)
baseClass(layer_base_t, ui_petAdvanceLayer)

MAX_STAR_NUM = 10
ADVANCE_SUCCESS = 1
ADVANCE_FAILURE = 0

function init(self, preLayer, pet)

    self.contentSize = GetMainMenu():GetSubContentNode():getContentSize()
    local ccbiAttrTable = { name = "sub_ui/PetAdvanceView.ccbi", size = self.contentSize }
    layer_base_t.init(self, true, ccbiAttrTable)

    self.sprite_stars_on = { }

    self.preLayer = preLayer

    self.advanceSucc = nil

    self.pet_id_value = pet.id
    self.pet_typeid_value = pet.typeid

    self.player_id_value = CPlayerDataMgr:instance():GetPlayerInfoData().m_uid

    self:init_ui()
    self:init_binding_event()

    initHeader(self.proxy_)

    self:requestLayerInfo()
end

function refreshData(self)

    self.pet = CPlayerPet:new(
        self.pet_typeid_value, 
        self.pet_level_value, 
        self.pet_rank_value, 
        self.pet_star_value)

    self.canAdvance = (self.pet_rank_value ~= self.pet_rank_max_value)

    self.text_pet_name:setString(self.pet:GetName())
    self.text_pet_level:setString(self.pet:getLevel())
    self.sprite_pet_icon:setDisplayFrame(self.pet:GetPetIcon(E_FRAMETYPE_MIDDLE))
    self.sprite_pet_icon:setScale(0.5)
    self.sprite_pet_frame:setDisplayFrame(self.pet:GetPetFrame(E_FRAMETYPE_MIDDLE))

    self.text_cur_atk:setString(self.cur_atk_value)
    self.text_cur_def:setString(self.cur_def_value)
    self.text_cur_chakra:setString(self.cur_chakra_value)
    self.text_cur_atk_add:setString("+" .. self.cur_atk_add_value)
    self.text_cur_def_add:setString("+" .. self.cur_def_add_value)
    self.text_cur_chakra_add:setString("+" .. self.cur_chakra_add_value)

    self.text_next_atk:setString(self.next_atk_value)
    self.text_next_def:setString(self.next_def_value)
    self.text_next_chakra:setString(self.next_chakra_value)
    self.text_next_atk_add:setString("+" .. self.next_atk_add_value)
    self.text_next_def_add:setString("+" .. self.next_def_add_value)
    self.text_next_chakra_add:setString("+" .. self.next_chakra_add_value)

    self.text_advance_chance:setString(string.format(localizable.ui_petAdvance_chance_text, tonumber(self.advance_chance_value)) .. "%")

    for i = 1, MAX_STAR_NUM do
        self.sprite_stars_on[i]:setVisible(i <= self.pet_star_value)
    end

    local itemInfo = tolua.cast(CTradeMgr:instance():GetConsumByIDForLua(self.item_id_value), "ConsumeInfo")
    if itemInfo == nil then
        self.playerHasItemNum = 0
    else
        self.playerHasItemNum = itemInfo.m_bagnum
    end

    self.text_item_num:setString(self.playerHasItemNum .. "/" .. self.item_num_value)

    if self.item_num_value > self.playerHasItemNum then
        self.text_item_num:setColor(Color3.Red)
    else
        self.text_item_num:setColor(Color3.Green)
    end

    self.text_item_name:setString(self.pet:GetComsumeNameById(self.item_id_value))
    self.sprite_item_icon:setDisplayFrame(self.pet:GetComsumeIconById(self.item_id_value, E_FRAMETYPE_SMALL))

    if self.advanceSucc ~= nil then
        self:showAdvanceAnim()
    end

    self.text_prop_buff_desc:setString(localizable.ui_label_property_buff_text)
    self.text_consume_desc:setString(localizable.ui_label_consume_text)
    self.text_advance_title:setString(localizable.ui_label_advance_text)
end

function init_binding_event(self)
    if self.proxy_ ~= nil then

        -- layer的触摸吞噬
        local function CCLayerTouch(event,x,y)
            local rect = self.node_:boundingBox()
			rect.origin = ccp(0,0)
			local p = self.node_:convertToNodeSpace(ccp(x,y))
			if event == "began" then
				if rect:containsPoint(p) == true then
					return true
				else
					return false
				end
			end
        end
		self.node_:setTouchEnabled(true)
		self.node_:registerScriptTouchHandler(CCLayerTouch, false, kCCMenuHandlerPriority - 1, true)

        -- 返回
        self:init_btn_binding_event(self.btn_back, 
            function(button, event)
                self.preLayer:update_ui()
                self.node_:removeFromParentAndCleanup(true)
            end,
            localizable.ui_label_back_text
        )

        -- 进阶
        self:init_btn_binding_event(self.btn_advance,
            function(button, event)
                self:advance()
            end ,
            localizable.ui_label_advance_text
        )
    end
end

function advance(self)
    --无法进阶的情况
    if self.canAdvance == false then
        -- cclog("无法进阶")
        GetMainMenu():ShowTextTip(localizable.ui_petAdvance_maxRank_tip, -1)
        return nil
    end

    local urlpath = GetUrlNormalHeader(self.player_id_value, 9, "rl_x_pet")
    urlpath = AddData(urlpath, "PetID", self.pet_id_value)

    function advanceCallbakc(data)
 
        self.playerHasItemNum = self.playerHasItemNum - self.item_num_value
        CTradeMgr:instance():SetConsumItemCountByID(self.item_id_value, self.playerHasItemNum)

        self.advanceSucc = getNumber(data:find("basic")[1], "upgrade")
        if self.advanceSucc == ADVANCE_SUCCESS then
            self:requestLayerInfo()
        else
            self:refreshData()
        end
    end

    sendRequest(urlpath, advanceCallbakc)
end

function requestLayerInfo(self)

    local urlpath = GetUrlNormalHeader(self.player_id_value, 8, "rl_x_pet")
    urlpath = AddData(urlpath, "PetID", self.pet_id_value)

    function requestLayerInfoCallback(data)
        local basic = data:find("basic")
        local curProp = data:find("num"):find("current")
        local nextProp = data:find("num"):find("next")

        self.pet_level_value = getNumber(basic, "level")
        self.pet_star_value = getNumber(basic, "star")
        self.pet_rank_value = getNumber(basic, "rank")
        self.pet_rank_max_value = getNumber(basic, "max_rank")
        
        self.item_id_value = getNumber(basic, "prop_id")
        self.item_num_value = getNumber(basic, "prop_num")

        self.advance_chance_value = getNumber(basic, "chance")

        self.cur_atk_value = getNumber(curProp, "attack")
        self.cur_def_value = getNumber(curProp, "defense")
        self.cur_chakra_value = getNumber(curProp, "chakala")
        self.cur_atk_add_value = getNumber(curProp, "attack_buff")
        self.cur_def_add_value = getNumber(curProp, "defense_buff")
        self.cur_chakra_add_value = getNumber(curProp, "chakala_buff")

        self.next_atk_value = getNumber(nextProp, "attack")
        self.next_def_value = getNumber(nextProp, "defense")
        self.next_chakra_value = getNumber(nextProp, "chakala")
        self.next_atk_add_value = getNumber(nextProp, "attack_buff")
        self.next_def_add_value = getNumber(nextProp, "defense_buff")
        self.next_chakra_add_value = getNumber(nextProp, "chakala_buff")

        self:refreshData()
    end

    sendRequest(urlpath, requestLayerInfoCallback)
end

function showAdvanceAnim(self)
    self.view = LuaSubView:create()
        if self.view == nil then
        return nil
    end

    if self.advanceSucc == ADVANCE_SUCCESS then
        self.view:LoadCCBI("animations/petAdvanceAnim_succ.ccbi", self.contentSize)
    elseif self.advanceSucc == ADVANCE_FAILURE then
        self.view:LoadCCBI("animations/petAdvanceAnim_fail.ccbi", self.contentSize)
    end

    self.view:setAnchorPoint(ccp(0.5, 0.5))
    self.view:setPosition(ccp(0, 0))
    self.node_anim_root:addChild(self.view)

    local function animFinished ()
        if self.schedule then
            CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.schedule)
            self.schedule = nil
            self.view:removeFromParentAndCleanup(true)
            GetMainMenu():CloseLoadding()
        end
    end

    self.schedule = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(animFinished, 0.8, false)
    GetMainMenu():ShowUnvisibleLoadingDlg()
end

function init_ui(self)
    if self.proxy_ ~= nil then
        local proxy = self.proxy_
        self.btn_back = getButtonFromCCB(proxy, "btn_back")
        self.btn_advance = getButtonFromCCB(proxy, "btn_advance")

        self.text_cur_atk = getLabelBMFontFromCCB(proxy, "text_current_atk")
        self.text_cur_def = getLabelBMFontFromCCB(proxy, "text_current_def")
        self.text_cur_chakra = getLabelBMFontFromCCB(proxy, "text_current_chakra")
        self.text_cur_atk_add = getLabelBMFontFromCCB(proxy, "text_current_atk_add")
        self.text_cur_def_add = getLabelBMFontFromCCB(proxy, "text_current_def_add")
        self.text_cur_chakra_add = getLabelBMFontFromCCB(proxy, "text_current_chakra_add")

        self.text_next_atk = getLabelBMFontFromCCB(proxy,"text_next_atk")
        self.text_next_def = getLabelBMFontFromCCB(proxy,"text_next_def")
        self.text_next_chakra = getLabelBMFontFromCCB(proxy,"text_next_chakra")
        self.text_next_atk_add = getLabelBMFontFromCCB(proxy,"text_next_atk_add")
        self.text_next_def_add = getLabelBMFontFromCCB(proxy,"text_next_def_add")
        self.text_next_chakra_add = getLabelBMFontFromCCB(proxy,"text_next_chakra_add")
        
        self.text_pet_level = getLabelBMFontFromCCB(proxy,"text_pet_level")
        self.sprite_pet_icon = getSpriteFromCCB(proxy, "sprite_pet_icon")
        self.sprite_pet_frame = getSpriteFromCCB(proxy, "sprite_pet_frame")
        self.text_pet_name = getLabelTTFFromCCB(proxy, "text_pet_name")

        self.text_item_num = getLabelBMFontFromCCB(proxy,"text_item_num")
        self.sprite_item_icon = getSpriteFromCCB(proxy, "sprite_item_icon")
        self.text_item_name = getLabelTTFFromCCB(proxy, "text_item_name")

        self.text_advance_chance = getLabelTTFFromCCB(proxy, "text_advance_chance")

        for i = 1, MAX_STAR_NUM do
            self.sprite_stars_on[i] = getSpriteFromCCB(proxy, "star_on_" .. i)
        end

        self.node_anim_root = getNodeFromCCB(proxy, "node_anim_root")

        self.text_advance_title = getLabelTTFFromCCB(proxy, "text_advance_title")
        self.text_prop_buff_desc = getLabelTTFFromCCB(proxy, "text_prop_buff_desc")
        self.text_consume_desc = getLabelTTFFromCCB(proxy, "text_consume_desc")
    end
end

---------------------common------------------------

function onNodeCleanup(self)
    if self.proxy_ then
        self.proxy_:release()
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