------------------------------------------------------------------------
--  Copyright (c) 2011-2015, XCKOO. All Rights Reserved.
--  Author :Milo
--  FName  :ui_petTrainingLayer.lua
--  Time   :2015年8月21日 19:05:50
--  Remark :宠物训练
------------------------------------------------------------------------
module("ui_petTrainingLayer", package.seeall)
baseClass(layer_base_t, ui_petTrainingLayer)

MAX_STAR_NUM = 10
TRAIN_MODE_NORMAL = 1
TRAIN_MODE_SPECIAL = 2
STAR_LEVEL_UP_SUCCESS = 1
HAS_CRIT = 1
HAS_NOT_CRIT = 0

function init(self, preLayer, pet)

    self.contentSize = GetMainMenu():GetSubContentNode():getContentSize()
    local ccbiAttrTable = { name = "sub_ui/PetTrainingView.ccbi", size = self.contentSize }
    layer_base_t.init(self, true, ccbiAttrTable)

    self.preLayer = preLayer

    self.sprite_stars_on = { }

    self.pet = pet.info
    self.pet_id_value = pet.id

    self.train_cost_value = 0

    self.playerMgr = CPlayerDataMgr:instance()
    self.playerData = self.playerMgr:GetPlayerInfoData()

    self:init_ui()
    self:init_binding_event()

    initHeader(self.proxy_)

    self:requestLayerInfo()
end

function refreshData(self)

    self.text_pet_name:setString(self.pet:GetName())

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

    for i = 1, MAX_STAR_NUM do
        self.sprite_stars_on[i]:setVisible(i <= self.pet_star_value)
    end

    self.text_training_exp:setString(tostring(self.train_exp_value) .. "/" .. tostring(self.train_exp_max_value))
    self.loadingBar_exp:setPercentage(math.floor(self.train_exp_value * 100 / self.train_exp_max_value))

    --cclog("normal train cost = " .. self.normal_train_cost_value)
    --cclog("special train cost = " .. self.special_train_cost_value)
    self.text_normal_train_cost:setString(self.normal_train_cost_value)
    self.text_special_train_cost:setString(self.special_train_cost_value)

    self.text_normal_train_desc:setString(string.format(localizable.ui_petTraining_normal_desc, self.normal_train_exp_value))
    self.text_special_train_desc:setString(string.format(localizable.ui_petTraining_special_desc, self.special_train_exp_value))

    self.text_top_gold:setString(self.playerData.m_gold)
    self.text_top_silver:setString(self.playerData.m_silver)

    if self.isCrit ~= nil then
        self:showCritAnim(self.train_add_exp_value)
    end

    self.text_prop_buff_desc1:setString(localizable.ui_label_property_buff_text)
    self.text_prop_buff_desc2:setString(localizable.ui_label_property_buff_text)
    self.text_train_consume_desc1:setString(localizable.ui_label_consume_text)
    self.text_train_consume_desc2:setString(localizable.ui_label_consume_text)
    self.text_train_title:setString(localizable.ui_label_train_text)
    self.text_train_title:setString(localizable.ui_label_train_text)
end

function showCritAnim(self, num)
    self.view = LuaSubView:create()
        if self.view == nil then
        return nil
    end

    if self.isCrit == HAS_CRIT then
        self.view:LoadCCBI("animations/petCritAnim.ccbi", self.contentSize)
    elseif self.isCrit == HAS_NOT_CRIT then
        self.view:LoadCCBI("animations/petTrainAnim.ccbi", self.contentSize)
    end

    self.isCrit = nil

    self.view:setAnchorPoint(ccp(0.5, 0.5))
    self.view:setPosition(ccp(0, 0))
    self.node_anim_root:addChild(self.view)

    self.text_num = tolua.cast(self.view:getNode("text_num"), "CCLabelBMFont")
    --self.sprit_crit = tolua.cast(self.view:getNode("sprite_crit"), "CCSprite")

    self.text_num:setString("+" .. tostring(num))

    local function animFinished ()
        if self.schedule then
            CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.schedule)
            self.schedule = nil
            self.train_add_exp_value = 0
            self.view:removeFromParentAndCleanup(true)
            GetMainMenu():CloseLoadding()
        end
    end

    self.schedule = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(animFinished, 1, false)
    GetMainMenu():ShowUnvisibleLoadingDlg()
end

function init_binding_event(self)
    if self.proxy_ ~= nil then

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

        -- 训练
        self:init_btn_binding_event(self.btn_normal_train,
            function(button, event)
                self:train(TRAIN_MODE_NORMAL, tonumber(self.normal_train_cost_value))
            end,
            localizable.ui_label_train_text
        )

        -- 特训
        self:init_btn_binding_event(self.btn_special_train,
            function(button, event)
                self:train(TRAIN_MODE_SPECIAL, tonumber(self.special_train_cost_value))
            end,
            localizable.ui_label_special_text
        )
    end
end

function train(self, trainMode, cost)
    if self.canTrain == false then
        GetMainMenu():ShowTextTip(localizable.ui_petTraining_maxStar_tip, -1)
        return
    end

    if self.playerData.m_gold < cost then
        --GetMainMenu():ShowTextTip(localizable.ui_monopoly_gold_not_enough, -1)
        local prePayLayer = createObj(ui_commonPrePay)
        GetMainMenu():GetModelLayer():AddDialog(prePayLayer.node_, 3)
        return 
    end

    --cclog("train cost = " .. cost)

    self:execTraining(trainMode, cost)
end

function execTraining(self, mode, cost)       

    local urlpath = GetUrlNormalHeader(self.playerData.m_uid, 5, "rl_x_pet")
    --urlpath = AddData(urlpath, "PetID", self.pet:getId())
    urlpath = AddData(urlpath, "PetID", self.pet_id_value)
    urlpath = AddData(urlpath, "Type", mode)
    local date=os.date("%Y-%m-%d %H:%M:%S")
    --cclog("date = " .. date)
    --cclog("url = " .. urlpath)

    function execTrainingCallback(data)
        --cclog("train callback\n%s", data)
        local basic = data:find("basic")
        local bUp = getNumber(basic, "upgrade")
        
        self.isCrit = getNumber(basic, "crit")

        local train_last_exp_value = self.train_exp_value
        self.train_exp_value = getNumber(basic, "train")
        self.train_add_exp_value = self.train_exp_value - train_last_exp_value

        local curCost = getNumber(basic, "current_cost")
        --cclog("curCost = " .. curCost)
        self.playerMgr:AddGold(-curCost)
        
        local next_train_cost = getNumber(basic, "next_spec_cost")
        if mode == TRAIN_MODE_NORMAL then
            self.normal_train_cost_value = next_train_cost
        end

        if bUp == STAR_LEVEL_UP_SUCCESS then
            self.train_add_exp_value = self.train_add_exp_value + self.train_exp_max_value
            self:requestLayerInfo()
        else
            self:refreshData()
        end
    end

    sendRequest(urlpath, execTrainingCallback, cost)
end

function requestLayerInfo(self)

    local urlpath = GetUrlNormalHeader(self.playerData.m_uid, 4, "rl_x_pet")
    --urlpath = AddData(urlpath, "PetID", self.pet:getId())
    --local date=os.date("%Y-%m-%d %H:%M:%S")
    urlpath = AddData(urlpath, "PetID", self.pet_id_value)

    function requestLayerInfoCallback(data)
        --cclog("request callback\n%s", data)
        local basic = data:find("basic")
        local num = data:find("num")
        local curProp = num:find("current")
        local nextProp = num:find("next")

        self.pet_star_value = getNumber(basic, "star")
        self.pet_star_max_value = getNumber(basic, "max_star")
        self.train_exp_value = getNumber(basic, "current_train")
        self.train_exp_max_value = getNumber(basic, "total_train")
        self.normal_train_cost_value = getNumber(basic, "tain_normal_cost")
        self.special_train_cost_value = getNumber(basic, "tain_spec_cost")
        self.normal_train_exp_value = getNumber(basic, "tain_normal_gen")
        self.special_train_exp_value = getNumber(basic, "tain_spec_gen")

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

        self.canTrain = (self.pet_star_value ~= self.pet_star_max_value)

        if self.canTrain == false then
            self.train_exp_value = self.train_exp_max_value
        end

        self:refreshData()
    end

    sendRequest(urlpath, requestLayerInfoCallback)
end

function init_ui(self)
    if self.proxy_ ~= nil then
        
        local proxy = self.proxy_

        self.btn_back = getButtonFromCCB(proxy, "btn_back")
        self.btn_normal_train = getButtonFromCCB(proxy, "btn_normal_train")
        self.btn_special_train = getButtonFromCCB(proxy, "btn_special_train")

        self.text_cur_atk = getLabelBMFontFromCCB(proxy,"text_current_atk")
        self.text_cur_def = getLabelBMFontFromCCB(proxy,"text_current_def")
        self.text_cur_chakra = getLabelBMFontFromCCB(proxy,"text_current_chakra")
        self.text_cur_atk_add = getLabelBMFontFromCCB(proxy,"text_current_atk_add")
        self.text_cur_def_add = getLabelBMFontFromCCB(proxy,"text_current_def_add")
        self.text_cur_chakra_add = getLabelBMFontFromCCB(proxy,"text_current_chakra_add")

        self.text_next_atk = getLabelBMFontFromCCB(proxy,"text_next_atk")
        self.text_next_def = getLabelBMFontFromCCB(proxy,"text_next_def")
        self.text_next_chakra = getLabelBMFontFromCCB(proxy,"text_next_chakra")
        self.text_next_atk_add = getLabelBMFontFromCCB(proxy,"text_next_atk_add")
        self.text_next_def_add = getLabelBMFontFromCCB(proxy,"text_next_def_add")
        self.text_next_chakra_add = getLabelBMFontFromCCB(proxy,"text_next_chakra_add")
        
        self.text_pet_name = getLabelTTFFromCCB(proxy, "text_pet_name")
        self.text_normal_train_cost = getLabelBMFontFromCCB(proxy,"text_normal_train_cost")
        self.text_special_train_cost = getLabelBMFontFromCCB(proxy,"text_special_train_cost")

        self.text_normal_train_desc = getLabelTTFFromCCB(proxy, "text_normal_train_desc")
        self.text_special_train_desc = getLabelTTFFromCCB(proxy, "text_special_train_desc")

        for i = 1, MAX_STAR_NUM do
            self.sprite_stars_on[i] = getSpriteFromCCB(proxy, "star_on_" .. tostring(i))
        end

        self.text_training_exp = getLabelBMFontFromCCB(proxy,"text_training_exp")
        self.node_expBar = getNodeFromCCB(proxy, "node_expBar")

        self.loadingBar_exp = CCProgressTimer:create(CCSprite:createWithSpriteFrame(CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("progress")))
        self.loadingBar_exp:setType(kCCProgressTimerTypeBar)
        self.loadingBar_exp:setMidpoint(ccp(0, 0.5))
        self.loadingBar_exp:setBarChangeRate(ccp(1, 0))
        self.loadingBar_exp:setPercentage(50)
        self.node_expBar:addChild(self.loadingBar_exp)

        self.text_top_gold = getLabelBMFontFromCCB(proxy,"label_goldval")
        self.text_top_silver = getLabelBMFontFromCCB(proxy,"label_silverval")

        self.node_anim_root = getNodeFromCCB(proxy, "node_anim_root")

        self.text_prop_buff_desc1 = getLabelTTFFromCCB(proxy, "text_prop_buff_desc1")
        self.text_prop_buff_desc2 = getLabelTTFFromCCB(proxy, "text_prop_buff_desc2")
        self.text_train_consume_desc1 = getLabelTTFFromCCB(proxy, "text_train_consume_desc1")
        self.text_train_consume_desc2 = getLabelTTFFromCCB(proxy, "text_train_consume_desc2")
        self.text_train_title = getLabelTTFFromCCB(proxy, "text_train_title")
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