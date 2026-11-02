----------------------------------------------------------------------
--  Copyright (c) 2014-2016, XCKOO. All Rights Reserved.
--  Author :lyk
--  Time   :2015-10-20
--  Remark :中忍考试
----------------------------------------------------------------------
module("ui_ninjaTestMain", package.seeall)
baseClass(layer_base_t, ui_ninjaTestMain)

require("ui_layer/ui_ninjaTestIntegralAwardListLayer")
require("util/tools")
require("util/localizable")
require("ui_layer/ui_ninjaTestSelect")
require "CommonDialogView"
require("ui_layer/ui_ninjaTestDesc")
require("NewDialogView")


function init(self, parent)
    self.playerMgr_ = CPlayerDataMgr:instance()
    self.playerData_ = self.playerMgr_:GetPlayerInfoData()

    self.contentSize_ = GetMainMenu():GetSubContentNode():getContentSize()
    local ccbiAttrTable = { name = "sub_ui/NinjaTestMain.ccbi", size = self.contentSize_ }
    layer_base_t.init(self, true, ccbiAttrTable)

    -- pre page
    self.back_page = E_DEFAULTMENU

    self.parent = parent
    self.is_attack = 0

    self.all_dead = false
    -- 是否全部阵亡  true是
   
    self:init_ui()
    self:init_binding_event()
end

function init_ui(self)
    if self.proxy_ ~= nil then
        initHeader(self.proxy_)
        self.label_shouguan_name = tolua.cast(self.proxy_:getNode("label_shouguan_name"), "CCLabelTTF")
        self.lable_number = tolua.cast(self.proxy_:getNode("label_number"), "CCLabelTTF")
        -- 挑战次数
        self.label_fight_number = tolua.cast(self.proxy_:getNode("label_fight_number"), "CCLabelTTF")
        self.label_chapter_name = tolua.cast(self.proxy_:getNode("label_chapter_name"), "CCLabelTTF")
        self.label_score = tolua.cast(self.proxy_:getNode("label_score"), "CCLabelTTF")
        self.sprite_bg = tolua.cast(self.proxy_:getNode("sprite_bg"), "CCSprite")
        self.button_back = tolua.cast(self.proxy_:getNode("btn_back"), "CCControlButton")
        self.button_award = tolua.cast(self.proxy_:getNode("button_award"), "CCControlButton")
        self.button_fight = tolua.cast(self.proxy_:getNode("button_fight"), "CCControlButton")
        self.button_my_hero = tolua.cast(self.proxy_:getNode("button_my_hero"), "CCControlButton")

        self.button_desc = tolua.cast(self.proxy_:getNode("button_desc"), "CCControlButton")
        for i = 1, 5 do
            -- 防守方
            self["sprite_icon_shouguan_0" .. tostring(i)] = tolua.cast(self.proxy_:getNode("sprite_icon_shouguan_0" .. tostring(i)), "CCSprite")
            self["sprite_wuxing_shouguan_0" .. tostring(i)] = tolua.cast(self.proxy_:getNode("sprite_wuxing_shouguan_0" .. tostring(i)), "CCSprite")
            self["sprite_gong_shouguan_0" .. tostring(i)] = tolua.cast(self.proxy_:getNode("sprite_gong_shouguan_0" .. tostring(i)), "CCSprite")
            self["sprite_dead_0" .. tostring(i)] = tolua.cast(self.proxy_:getNode("sprite_dead_0" .. tostring(i)), "CCSprite")
            self["label_attack_shouguan_0" .. tostring(i)] = tolua.cast(self.proxy_:getNode("label_attack_shouguan_0" .. tostring(i)), "CCLabelBMFont")
            ---------------------------------------
            -- 我方
            self["sprite_icon_my_0" .. tostring(i)] = tolua.cast(self.proxy_:getNode("sprite_icon_my_0" .. tostring(i)), "CCSprite")
            self["sprite_wuxing_my_0" .. tostring(i)] = tolua.cast(self.proxy_:getNode("sprite_wuxing_my_0" .. tostring(i)), "CCSprite")
            self["sprite_dead_my_0" .. tostring(i)] = tolua.cast(self.proxy_:getNode("sprite_dead_my_0" .. tostring(i)), "CCSprite")
            self["sprite_gong_my_0" .. tostring(i)] = tolua.cast(self.proxy_:getNode("sprite_gong_my_0" .. tostring(i)), "CCSprite")
            self["label_attack_my_0" .. tostring(i)] = tolua.cast(self.proxy_:getNode("label_attack_my_0" .. tostring(i)), "CCLabelBMFont")
        end

        for i = 1, 2 do
            self["node_box_0" .. tostring(i)] = tolua.cast(self.proxy_:getNode("node_box_0" .. tostring(i)), "CCNode")
        end

        for i = 1, 4 do
            self["button_box_0" .. tostring(i)] = tolua.cast(self.proxy_:getNode("button_box_0" .. tostring(i)), "CCControlButton")
            self["sprite_gold_0" .. tostring(i)] = tolua.cast(self.proxy_:getNode("sprite_gold_0" .. tostring(i)), "CCSprite")

            self["label_need_gold_0" .. tostring(i)] = tolua.cast(self.proxy_:getNode("label_need_gold_0" .. tostring(i)), "CCLabelBMFont")
        end
        self.node_enemy = tolua.cast(self.proxy_:getNode("node_enemy"), "CCNode")

        self.box_close_frame = { }
        for i = 1, 5, 2 do
            local frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("ninja_text_box_0" .. tostring(i))
            if frame then
                table.insert(self.box_close_frame, frame)
            end
        end

        self.box_open_frame = { }
        for i = 2, 6, 2 do
            local frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("ninja_text_box_0" .. tostring(i))
            if frame then
                table.insert(self.box_open_frame, frame)
            end
        end


        self:requestBaseLayerInfo()
    end
end

function requestBaseLayerInfo(self)
    -- rl_x_exam
    local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 1, "rl_x_exam")
    -- urlpath = AddData(urlpath, "GroupId", global.myOrgId)
    --cclog("%s", urlpath)
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
        -- cclog("rl_r_group_comm ret = %s", resData)
        local retcode = item.code
        if retcode == "0" then
            self:init_xml(item)
        else
            GetMainMenu():ShowErrorTip(tonumber(retcode), -1)
        end
    end )
end

-- 下一关返回信息和第一次请求返回信息一样 所以使用相同的处理
function init_xml(self, item)
    -- 当前打第几关
    self.curr_grade = tonumber(item:find("curr_grade")[1])
    -- 守关者名字
    self.guard_name = item:find("guard_name")[1]
    -- 玩家当前积分（兑换奖励）
    self.score = tonumber(item:find("score")[1])
    -- 购买战斗次数需要消耗的元宝
    self.buy_cost = tonumber(item:find("buy_cost")[1])
    -- 当前关卡是否是攻击关卡  1攻击
    self.is_attack = tonumber(item:find("is_attack")[1])
    -- 当前关卡可以打的总次数
    self.total_count = tonumber(item:find("total_count")[1])
    -- 当前关卡可以打的剩余次数
    self.left_count = tonumber(item:find("left_count")[1])
    -- 是否通过 1通过
    self.is_win = tonumber(item:find("is_win")[1])
    -- 宝箱是否开启
    self.fetch_flag1 = tonumber(item:find("fetch_flag1")[1])
    self.fetch_flag2 = tonumber(item:find("fetch_flag2")[1])
    self.fetch_flag3 = tonumber(item:find("fetch_flag3")[1])

    if self.is_attack ==0 then 
        self.my_attack = 1
    else 
        self.my_attack = 0
    end

    -- 守关英雄列表
    self.opp_list = { }
    local opp_list = item:find("opp_list")
    if opp_list then
        for i = 1, #opp_list do
            local ninja_member = opp_list[i]:find("ninja_member")
            if ninja_member then
                local ninja_member_item = { }
                ninja_member_item.ninja_id = tonumber(ninja_member:find("ninja_id")[1])
                -- id
                ninja_member_item.val = tonumber(ninja_member:find("val")[1])
                -- 攻击 或者防御值
                ninja_member_item.cardattr = tonumber(ninja_member:find("cardattr")[1])
                -- 属性（风火雷电）
                ninja_member_item.dead_flag = tonumber(ninja_member:find("dead_flag")[1])
                -- 0活着  1 阵亡
                table.insert(self.opp_list, ninja_member_item)
            end
        end
    end

    -- 阵亡列表
    self.dead_list = { }
    local dead_list_item = item:find("dead_list")
    if dead_list_item then
        for i = 1, #dead_list_item do
            local bag_index = dead_list_item[i]:find("bag_index")[1]
            if bag_index then
                table.insert(self.dead_list, bag_index)
            end
        end
    end
    -- 我方阵容
    self.my_list = { }
    local my_list_item = item:find("my_list")
    if my_list_item then
        for i = 1, #my_list_item do
            local bag_index = my_list_item[i]:find("bag_index")[1]
            if bag_index then
                table.insert(self.my_list, bag_index)
            end
        end
    end
    -- 测试
    -- self.dead_list = self.my_list
    -- 奖励兑换
    self.exchage_list = { }
    local exchage_list_item = item:find("exchage_list")
   -- cclog("exchage_list_item = %s", exchage_list_item)
    if exchage_list_item then
        for i = 1, #exchage_list_item do
            local item = exchage_list_item[i]:find("item")
            if item then
                local item_item = { }
                item_item.reward_id =(item:find("reward_id")[1])
                -- id
                item_item.reward_name =(item:find("reward_name")[1])
                -- 奖励名称
                item_item.icon =(item:find("icon")[1])
                -- 奖励图标
                item_item.score =(item:find("score")[1])
                -- 兑换改奖励需要的积
                item_item.cash =(item:find("cash")[1])
                -- 兑换改奖励需要的元宝
                item_item.coin =(item:find("coin")[1])
                -- 兑换改奖励需要的金币
                item_item.drop_id =(item:find("drop_id")[1])
                -- 奖励掉落id
                item_item.quality = (item:find("quality")[1])
                -- 物品品质
                item_item.show = (item:find("show")[1])
                -- 物品说明
                table.insert(self.exchage_list, item_item)
            end
        end
    end

    self.reward_box = { }
    local reward_box_item = item:find("reward_box")
    if reward_box_item then
        for i = 1, #reward_box_item do
            local item = reward_box_item[i]:find("box_info")
            if item then
                local item_item = { }
                item_item.index = tonumber(item:find("index")[1])
                item_item.cost = tonumber(item:find("cost")[1])
                table.insert(self.reward_box, item_item)
            end
        end
    end

    self:init_ext_ui()
end


function init_ext_ui(self)
    for i = 1, 5 do
        -- 守方信息
        local ninjainfo = DataMgr.GetDataByID("Struct_Ninjainfo", tonumber(self.opp_list[i].ninja_id))
        local pFrameSprite = CGameObjElement:GetNinjaFrame(E_FRAMETYPE_SMALL, ninjainfo.m_quality)
        if pFrameSprite then
            self["sprite_icon_shouguan_0" .. tostring(i)]:setDisplayFrame(pFrameSprite)
        end

        if self.is_attack == 0 then
            local frame1 = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("com_small_defense_icon")
            if frame1 ~= nil then
                self["sprite_gong_shouguan_0" .. tostring(i)]:setDisplayFrame(frame1)
            end
        else
            local frame1 = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("com_small_attack_icon")
            if frame1 ~= nil then
                self["sprite_gong_shouguan_0" .. tostring(i)]:setDisplayFrame(frame1)
            end
        end

        local pIconFrame = CGameObjElement:GetNinjaIcon(E_FRAMETYPE_SMALL, ninjainfo.m_ninjaicon)
        local sprite1 = CCSprite:createWithSpriteFrame(pIconFrame)
        local _size = self["sprite_icon_shouguan_0" .. tostring(i)]:getContentSize()
        sprite1:setPosition(ccp(_size.width * 0.5, _size.height * 0.5))
        sprite1:setAnchorPoint(ccp(0.5, 0.5))
        self["sprite_icon_shouguan_0" .. tostring(i)]:addChild(sprite1)

        local county_icon_index = self.opp_list[i].cardattr
        local frame1 = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(tools.getAttributeIcon(county_icon_index))
        if frame1 ~= nil then
            self["sprite_wuxing_shouguan_0" .. tostring(i)]:setDisplayFrame(frame1)
        end
        self["label_attack_shouguan_0" .. tostring(i)]:setString(self.opp_list[i].val)

        if self.opp_list[i].dead_flag == 1 then
            self["sprite_dead_0" .. tostring(i)]:setVisible(true)
        else
            self["sprite_dead_0" .. tostring(i)]:setVisible(false)
        end
    end

    --[[
    if self.curr_grade >= 15 and self.is_win == 1 then
        self.button_fight:setVisible(false)
    end
    ]]
    self:init_my_info()
    self:init_box_info()
    self:init_box_award_info()
    self:init_fight_info()
    self:init_bg_info()

    self.lable_number:setString(string.format(localizable.ui_ninjaTest_number, self.curr_grade))
    self.label_shouguan_name:setString(self.guard_name)
    self.label_fight_number:setString(self.left_count .. "/" .. self.total_count)
    self.label_score:setString(self.score)
end


function init_bg_info(self)
    local number = tonumber(self.curr_grade)
    if number > 0 and number <= 5 then
        self.label_chapter_name:setString(localizable.ui_ninjaTestMain_text9)
        local frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("ninja_test_bg_03")
        if frame then
            self.sprite_bg:setDisplayFrame(frame)
        end
    elseif number > 5 and number <= 10 then
        self.label_chapter_name:setString(localizable.ui_ninjaTestMain_text10)
        local frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("ninja_test_bg_01")
        if frame then
            self.sprite_bg:setDisplayFrame(frame)
        end
    elseif number > 10 and number <= 15 then
        self.label_chapter_name:setString(localizable.ui_ninjaTestMain_text11)
        local frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("ninja_test_bg_02")
        if frame then
            self.sprite_bg:setDisplayFrame(frame)
        end
    end
end

function init_box_info(self)
    if tonumber(self.is_win) == 0 then
        self["node_box_01"]:setVisible(false)
        self["node_box_02"]:setVisible(false)
        self.node_enemy:setVisible(true)
    elseif tonumber(self.is_win) == 1 and tonumber(self.curr_grade) % 5 == 0 then
        self["node_box_01"]:setVisible(true)
        self["node_box_02"]:setVisible(false)
        self.node_enemy:setVisible(false)
    else
        self["node_box_01"]:setVisible(false)
        self["node_box_02"]:setVisible(true)
        self.node_enemy:setVisible(false)
    end

end

function init_box_award_info(self)
    if tonumber(self.is_win) == 1 and tonumber(self.curr_grade) % 5 == 0 then
        for i = 1, 3 do
            if self["fetch_flag" .. tostring(i)] == 0 then
                self["button_box_0" .. tostring(i)]:setBackgroundSpriteFrameForState(self.box_close_frame[i], CCControlStateNormal)
                self["button_box_0" .. tostring(i)]:setBackgroundSpriteFrameForState(self.box_close_frame[i], CCControlStateHighlighted)
                self["button_box_0" .. tostring(i)]:setBackgroundSpriteFrameForState(self.box_close_frame[i], CCControlStateDisabled)
            else
                self["button_box_0" .. tostring(i)]:setBackgroundSpriteFrameForState(self.box_open_frame[i], CCControlStateNormal)
                self["button_box_0" .. tostring(i)]:setBackgroundSpriteFrameForState(self.box_open_frame[i], CCControlStateHighlighted)
                self["button_box_0" .. tostring(i)]:setBackgroundSpriteFrameForState(self.box_open_frame[i], CCControlStateDisabled)
            end
            if self.reward_box[i].cost ~= 0 then
                self["label_need_gold_0" .. tostring(i)]:setString(self.reward_box[i].cost)
            else
                self["label_need_gold_0" .. tostring(i)]:setVisible(false)
                self["sprite_gold_0" .. tostring(i)]:setVisible(false)
            end

        end
    elseif tonumber(self.is_win) == 1 and tonumber(self.curr_grade) % 5 ~= 0 then

        if self["fetch_flag1"] == 0 then
            self["button_box_04"]:setBackgroundSpriteFrameForState(self.box_close_frame[1], CCControlStateNormal)
            self["button_box_04"]:setBackgroundSpriteFrameForState(self.box_close_frame[1], CCControlStateHighlighted)
            self["button_box_04"]:setBackgroundSpriteFrameForState(self.box_close_frame[1], CCControlStateDisabled)
        else

            self["button_box_04"]:setBackgroundSpriteFrameForState(self.box_open_frame[1], CCControlStateNormal)
            self["button_box_04"]:setBackgroundSpriteFrameForState(self.box_open_frame[1], CCControlStateHighlighted)
            self["button_box_04"]:setBackgroundSpriteFrameForState(self.box_open_frame[1], CCControlStateDisabled)
        end

        if self.reward_box[1].cost ~= 0 then
            self["label_need_gold_0" .. tostring(4)]:setString(self.reward_box[1].cost)
        else
            self["label_need_gold_0" .. tostring(4)]:setVisible(false)
            self["sprite_gold_0" .. tostring(4)]:setVisible(false)
        end
    end
end


function init_my_info(self)
    self.my_list_info = { }
    self.my_list_info = self:getNinjaList()
    for i = 1, #self.my_list_info do
        -- 我方信息
        if self.my_attack == 0 then
            local frame1 = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("com_small_defense_icon")
            if frame1 ~= nil then
                self["sprite_gong_my_0" .. tostring(i)]:setDisplayFrame(frame1)
            end
        else
            local frame1 = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("com_small_attack_icon")
            if frame1 ~= nil then
                self["sprite_gong_my_0" .. tostring(i)]:setDisplayFrame(frame1)
            end
        end

        self["sprite_icon_my_0" .. tostring(i)]:setDisplayFrame(self.my_list_info[i].qualityFrame)
        self["sprite_icon_my_0" .. tostring(i)]:removeAllChildrenWithCleanup(true)

        local sprite1 = CCSprite:createWithSpriteFrame(self.my_list_info[i].iconFrame)
        local _size = self["sprite_icon_my_0" .. tostring(i)]:getContentSize()
        sprite1:setPosition(ccp(_size.width * 0.5, _size.height * 0.5))
        sprite1:setAnchorPoint(ccp(0.5, 0.5))
        self["sprite_icon_my_0" .. tostring(i)]:addChild(sprite1)
        self["sprite_wuxing_my_0" .. tostring(i)]:setDisplayFrame(self.my_list_info[i].cardCamp)
        self["label_attack_my_0" .. tostring(i)]:setString(self.my_list_info[i].attack)
        if self.my_list_info[i].dead == true then
            self["sprite_dead_my_0" .. tostring(i)]:setVisible(true)
        else
            self["sprite_dead_my_0" .. tostring(i)]:setVisible(false)
        end

        self["sprite_wuxing_my_0" .. tostring(i)]:setVisible(true)
        self["sprite_gong_my_0" .. tostring(i)]:setVisible(true)
        self["label_attack_my_0" .. tostring(i)]:setVisible(true)

    end

    if #self.my_list < 5 then
        for i = #self.my_list + 1, 5 do
            local spriteFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("small_icon_frame_clickadd")
            if spriteFrame then
                self["sprite_icon_my_0" .. tostring(i)]:setDisplayFrame(spriteFrame)
            end
            self["sprite_icon_my_0" .. tostring(i)]:removeAllChildrenWithCleanup(true)
            self["sprite_wuxing_my_0" .. tostring(i)]:setVisible(false)
            self["sprite_gong_my_0" .. tostring(i)]:setVisible(false)
            self["label_attack_my_0" .. tostring(i)]:setVisible(false)
            self["sprite_dead_my_0" .. tostring(i)]:setVisible(false)
        end
    end 

end


function getNinjaList(self)
    local ninjaList = { }
    -- local objlist = CPlayerDataMgr:instance():GetObjectList(e_obj_ninja)
    -- local count = objlist:size() -1
    for i = 1, #self.my_list do
        local ninja = CPlayerDataMgr:instance():GetObjectByID(self.my_list[i])
        local isdead = self:findDead(self.my_list[i])
        if ninja:GetQuality() >=4 then
            local attack_current_plus = 0
            local defense_current_plus = 0
            -- local chakra_current_plus = 0
            local attackmin = ninja:GetAttackMin()
            local attackmax = ninja:GetAttackMax()
            local defensemin = ninja:GetDefenseMin()
            local defensemax = ninja:GetDefenseMax()
            -- local chakramin = self.data[i].ninjainfo:GetChakraMin()
            -- local chakramax = self.data[i].ninjainfo:GetChakraMax()

            local strengthlevel = ninja:GetStrengthLevel()
            if strengthlevel ~= 0 then
                local strengthconfig = DataMgr.GetDataByID("Struct_Ninjastrengthconfig", strengthlevel)
                local ratio = strengthconfig.m_addprop / 2
                attack_current_plus =(attackmin + attackmax) * ratio
                defense_current_plus =(defensemin + defensemax) * ratio
                -- chakra_current_plus =(chakramin + chakramax) * ratio
            end

            -- 底框
            local ninja_id = ninja:GetDataID()
            local ninjainfo = DataMgr.GetDataByID("Struct_Ninjainfo", ninja_id)
            local localQualityFrame = CGameObjElement:GetNinjaFrame(E_FRAMETYPE_SMALL, ninjainfo.m_quality)

            -- icon
            local pIconFrame = CGameObjElement:GetNinjaIcon(E_FRAMETYPE_SMALL, ninjainfo.m_ninjaicon)
            -- cardcamp
            local county_icon_index = ninja:GetCardCamp()
            local localCardCamp = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(tools.getAttributeIcon(county_icon_index))

            local attack_or_defense = 0
            if self.my_attack == 1 then
                attack_or_defense =((attackmin + attack_current_plus) +(attackmax + attack_current_plus)) / 2
            else
                attack_or_defense =((defensemin + defense_current_plus) +(defensemax + defense_current_plus)) / 2
            end

            table.insert(ninjaList, { ninjainfo = ninja, qualityFrame = localQualityFrame, iconFrame = pIconFrame, cardCamp = localCardCamp, attack = math.modf(attack_or_defense), dead = isdead })
            -- 阵亡 true
        end
    end


    -- table.sort(ninjaList,)
    return ninjaList
end

-- 卡牌死亡 返回true
function findDead(self, bag_index)
    local dead = false
    for i = 1, #self.dead_list do
        if tonumber(self.dead_list[i]) == tonumber(bag_index) then
            dead = true
            break
        end
    end
    return dead
end


function updateUI(self)
    -- initHeader(self.proxy_)
  --  cclog("updateUI")
    self:init_my_info()
end

function setMyList(self, list)
    self.my_list = tools.copyTab(list)
    -- = list
end


function init_binding_event(self)
    if self.proxy_ ~= nil then

        local function CCLayerTouch(event, x, y)
            local rect = self.node_:boundingBox()
            rect.origin = ccp(0, 0)
            local p = self.node_:convertToNodeSpace(ccp(x, y))
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

        local function onBtnBack(btn)
            self.parent:refreshData()
            self.node_:removeFromParentAndCleanup(true)
        end

        local function onBtnAward(btn)
           -- cclog("onBtnAward")
            -- self.exchage_list  奖励列表
            local view = createObj(ui_ninjaTestIntegralAwardListLayer, self.score, self.exchage_list, self)
            AddViewToActivitySubMenu(view.node_)
        end

        local function onBtnFight(btn)
          --  cclog("onBtnFight")
            if self.is_win == 1 then

                if self.fetch_flag1 == 0 and self.fetch_flag2 == 0 and self.fetch_flag3 == 0 then
                    -- 宝箱没有领取 弹出提示
                    self:showCommonDialog()
                else
                    -- 直接进入下一关
                    self:gotoNextChapter()
                end
            else
                self.all_dead = self:findAllDead()
                if self.all_dead then
                    -- 全部死亡 或者没有卡牌
                    GetMainMenu():ShowTextTip(localizable.ui_ninjaTestMain_text5, -1)
                else
                    -- 有卡牌死亡
                    local hasDead = false
                    for i = 1, #self.my_list do
                        local dead = self:findDead(self.my_list[i])
                        if dead then
                            hasDead = true
                        end
                    end

                    if #self.my_list ~= 5 then
                        self:showCommonDialogByMyList()
                    elseif hasDead then
                        self:showCommonDialogHasDead()
                    elseif tonumber(self.left_count) < 1 then
                        self:showCommonDialogBuyConst()
                    else
                        self:fight()
                    end

                end
            end
        end

        local function onBtnDesc(btn)
            local monthLayer = createObj(ui_ninjaTestDesc)
            local size1 = GetMainMenu():GetModelLayer():getContentSize()
            monthLayer.node_:setAnchorPoint(ccp(0.5, 0.5))
            monthLayer.node_:setPosition(size1.width / 2, size1.height / 2)
            GetMainMenu():GetModelLayer():addChild(monthLayer.node_)

        end

        local function onBtnBox(btn)

            local index = btn:getTag()
            if index == 4 then
                index = 1
            end
            if tonumber(self["fetch_flag" .. tostring(index)]) ~= 1 then
                if self.reward_box[index].cost ~= 0 then
                    self:showCommonDialogOpenBox(index)
                else
                    self:submit_box_info(index)
                end
            else
                cclog('asdasdasd ' .. localizable.ui_ninjaTestMain_text1)
                GetMainMenu():ShowTextTip(localizable.ui_ninjaTestMain_text1, -1)
            end

        end


        local function onBtnMyHero(btn)
            local testSelectLayer = createObj(ui_ninjaTestSelect, self, self.my_list_info, self.my_list, self.dead_list, self.my_attack)
            local size1 = GetMainMenu():GetModelLayer():getContentSize()
            testSelectLayer.node_:setAnchorPoint(ccp(0.5, 0.5))
            testSelectLayer.node_:setPosition(size1.width / 2, size1.height / 2)
            GetMainMenu():GetModelLayer():addChild(testSelectLayer.node_)
        end

        self.button_back:setTouchEnabled(true)
        self.button_back:setTouchPriority(kCCMenuHandlerPriority - 1)
        self.proxy_:handleButtonEvent(self.button_back, function(button, event)
            onBtnBack()
            return nil
        end , CCControlEventTouchDown)

        self.button_award:setTouchEnabled(true)
        self.button_award:setTouchPriority(kCCMenuHandlerPriority - 1)
        self.proxy_:handleButtonEvent(self.button_award, function(button, event)
            onBtnAward()
            return nil
        end , CCControlEventTouchDown)

        self.button_fight:setTouchEnabled(true)
        self.button_fight:setTouchPriority(kCCMenuHandlerPriority - 1)
        self.proxy_:handleButtonEvent(self.button_fight, function(button, event)
            onBtnFight()
            return nil
        end , CCControlEventTouchDown)

        self.button_my_hero:setTouchEnabled(true)
        self.button_my_hero:setTouchPriority(kCCMenuHandlerPriority - 1)
        self.proxy_:handleButtonEvent(self.button_my_hero, function(button, event)
            onBtnMyHero()
            return nil
        end , CCControlEventTouchDown)

        self.button_desc:setTouchEnabled(true)
        self.button_desc:setTouchPriority(kCCMenuHandlerPriority - 1)
        self.proxy_:handleButtonEvent(self.button_desc, function(button, event)
            onBtnDesc()
            return nil
        end , CCControlEventTouchDown)

        for i = 1, 4 do
            self["button_box_0" .. tostring(i)]:setTouchEnabled(true)
            self["button_box_0" .. tostring(i)]:setTouchPriority(kCCMenuHandlerPriority - 1)
            self.proxy_:handleButtonEvent(self["button_box_0" .. tostring(i)], function(button, event)
                onBtnBox(button)
                return nil
            end , CCControlEventTouchDown)
        end

    end
end

function init_fight_info(self)

    if self.is_win == 1 then
        self.button_fight:setTitleForState(localizable.ui_ninjaTestMain_text3, CCControlStateNormal);
        self.button_fight:setTitleForState(localizable.ui_ninjaTestMain_text3, CCControlStateHighlighted);
        self.button_fight:setTitleForState(localizable.ui_ninjaTestMain_text3, CCControlStateSelected);
    else
        self.button_fight:setTitleForState(localizable.ui_ninjaTestMain_text2, CCControlStateNormal);
        self.button_fight:setTitleForState(localizable.ui_ninjaTestMain_text2, CCControlStateHighlighted);
        self.button_fight:setTitleForState(localizable.ui_ninjaTestMain_text2, CCControlStateSelected);
    end

end

-- 点箱子提示
function showCommonDialogOpenBox(self, index)
    local dlg = CommonDialogView.create()
    CommonDialogView.m_selfview = dlg;
    dlg:SetTitle(localizable.ui_rouletteLayer_title)
    local desc = string.format(localizable.ui_ninjaTestMain_text12, self.reward_box[index].cost)
    dlg:SetDescription(desc)
    dlg:loadCCBI();
    dlg:SetConfirmHandler(
    function()
        self:submit_box_info(index)       
       
    end
    )
    dlg:initUI()
    GetMainMenu():GetModelLayer():AddDialog(dlg, 3);
end

--下一关
function showCommonDialog(self)
    local dialogView = createObj(NewDialogView)
    local size1 = GetMainMenu():GetModelLayer():getContentSize()
    -- local desc = string.format(localizable.ui_ninjaTestMain_text8, tonumber(self.buy_cost))
    dialogView:setContentText(localizable.ui_ninjaTestMain_text4)
    dialogView:setConfirmHandler(
    function()
        self:gotoNextChapter()
    end )
    dialogView.node_:setAnchorPoint(ccp(0.5, 0.5))
    dialogView.node_:setPosition(size1.width / 2, size1.height / 2)
    GetMainMenu():GetModelLayer():addChild(dialogView.node_)
end

-- 卡牌不足
function showCommonDialogByMyList(self)

    local dialogView = createObj(NewDialogView)
    local size1 = GetMainMenu():GetModelLayer():getContentSize()
    -- local desc = string.format(localizable.ui_ninjaTestMain_text8, tonumber(self.buy_cost))
    dialogView:setContentText(localizable.ui_ninjaTestMain_text6)
    dialogView:setConfirmHandler(
    function()
        if tonumber(self.left_count) > 0 then
            self:fight()
        else
            self:showCommonDialogBuyConst()
        end
    end )
    dialogView.node_:setAnchorPoint(ccp(0.5, 0.5))
    dialogView.node_:setPosition(size1.width / 2, size1.height / 2)
    GetMainMenu():GetModelLayer():addChild(dialogView.node_)
end

-- 队伍里有卡牌阵亡
function showCommonDialogHasDead(self)

    local dialogView = createObj(NewDialogView)
    local size1 = GetMainMenu():GetModelLayer():getContentSize()
    -- local desc = string.format(localizable.ui_ninjaTestMain_text8, tonumber(self.buy_cost))
    dialogView:setContentText(localizable.ui_ninjaTestMain_text7)
    dialogView:setConfirmHandler(
    function()
        if tonumber(self.left_count) > 0 then
            self:fight()
        else

            self:showCommonDialogBuyConst()

        end
    end )
    dialogView.node_:setAnchorPoint(ccp(0.5, 0.5))
    dialogView.node_:setPosition(size1.width / 2, size1.height / 2)
    GetMainMenu():GetModelLayer():addChild(dialogView.node_)

end

-- 次数不足 提示购买
function showCommonDialogBuyConst(self)

    local dialogView = createObj(NewDialogView)
    local size1 = GetMainMenu():GetModelLayer():getContentSize()
    local desc = string.format(localizable.ui_ninjaTestMain_text8, tonumber(self.buy_cost))
    dialogView:setContentText(desc)
    dialogView:setConfirmHandler(
    function()
        self:gotoBuyConst()
        self.playerMgr_:AddGold(-self.buy_cost)
        self.playerData_ = self.playerMgr_:GetPlayerInfoData()
        initHeader(self.proxy_)
    end )
    dialogView.node_:setAnchorPoint(ccp(0.5, 0.5))
    dialogView.node_:setPosition(size1.width / 2, size1.height / 2)
    GetMainMenu():GetModelLayer():addChild(dialogView.node_)


end

function gotoBuyConst(self)
    local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 4, "rl_x_exam")

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
     --   cclog("%s", resData)
        local retcode = item.code
        if retcode == "0" then
            -- self:init_xml(item)
            self.left_count = item:find("left_count")[1]
            if tonumber(self.left_count) > 0 then
                self:fight()
            end
        else
              GetMainMenu():ShowErrorTip(tonumber(retcode), -1)
           -- GetMainMenu():ShowTextTip(text.text_config[tonumber(retcode)].description, -1)
        end
    end )
end


function gotoNextChapter(self)
    -- 请求基本信息
    local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 7, "rl_x_exam")
    urlpath = AddData(urlpath, "box_index", index)
    -- cclog("rl_x_ninja_challenge & cmd = 1---%s", urlpath)
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
        --cclog("%s", resData)
        local retcode = item.code
        if retcode == "0" then
            self:init_xml(item)
        else
            GetMainMenu():ShowErrorTip(tonumber(retcode), -1)
            --GetMainMenu():ShowTextTip(text.text_config[tonumber(retcode)].description, -1)
        end
    end )

end


function findAllDead(self)
    local allDead = false
    local deadNumber = 0

    if #self.my_list == 0 then
        -- 没有卡牌 认为全部死亡
        allDead = true
        return allDead
    end

    for i = 1, #self.my_list do
        local isDead = self:findDead(tonumber(self.my_list[i]))
        if isDead then
            deadNumber = deadNumber + 1
        end
    end

    if deadNumber == #self.my_list then
        allDead = true
    end

    return allDead
end


function fight(self)
    -- 请求基本信息
    local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 5, "rl_x_exam")
    -- urlpath = AddData(urlpath, "ChallengeID", self.sellectedItem.id)
    -- cclog("rl_x_ninja_challenge & cmd = 1---%s", urlpath)
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
       -- cclog("%s", resData)
        local retcode = item.code
        if retcode == "0" then
            -- 显示战斗过程动画
            -- GetMainMenu():ShowArenaView(resData)
            local fightinfo = item:find("fight")
            local resultData = CFightResultData:instance()
            resultData:Clear()
            InitFightXML(fightinfo, resultData)
            resultData:SetFightType(7)

            local awardXML
            local hasAward = false
            for i = 1, #item do
                if item[i][0] == "award" then
                    hasAward = true
                    awardXML = item[i]
                end
            end
            if hasAward == true then
                InitAwardData(resultData:GetRewardData(), awardXML)
                CPlayerDataMgr:instance():AddDataFromReward(resultData:GetRewardData())
            end

            local fightview = CRoundFightView:new()
            fightview:init()
            GetMainMenu():addChild(fightview, 5)
            fightview:Start()
            fightview:release()          
            self:requestBaseLayerInfo()                  
        else
            GetMainMenu():ShowErrorTip(tonumber(retcode), -1)
            --GetMainMenu():ShowTextTip(text.text_config[tonumber(retcode)].description, -1)
        end
    end )

end

function submit_box_info(self, index)
    -- 请求基本信息
    local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 6, "rl_x_exam")
    urlpath = AddData(urlpath, "box_index", index)
   -- cclog("%s", urlpath)
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
     --   cclog("%s", resData)
        local retcode = item.code
        if retcode == "0" then
            local awardXml = xfile:find("award")
            if awardXml then
                self.m_awardXml = { }
                self.m_awardXml = awardXml
                ShowAward(self.m_awardXml)
            end
            self["fetch_flag" .. tostring(index)] = 1
            self:init_box_award_info()

            self.playerMgr_:AddGold(-self.reward_box[index].cost)
            self.playerData_ = self.playerMgr_:GetPlayerInfoData()
            initHeader(self.proxy_)
        else
             GetMainMenu():ShowErrorTip(tonumber(retcode), -1)
            --GetMainMenu():ShowTextTip(text.text_config[tonumber(retcode)].description, -1)

        end
    end )

end

function updata_score(self,score)
     self.label_score:setString(score)
     self.score = score
     initHeader(self.proxy_)
end


function onNodeCleanup(self)
    if self.proxy_ then
        self.proxy_:release()
    end

    layer_base_t.onNodeCleanup(self)
end