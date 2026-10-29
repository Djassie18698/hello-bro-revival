-- 中忍考试忍者选择cell
-- liyongkang
-- 2015-10-22
---------------------------------------------
module("ui_ninjaTestSelectCell", package.seeall)
-- require("ui_layer/ui_monthSignAnim")

baseClass(layer_base_t, ui_ninjaTestSelectCell)

function init(self, cellSize, data, is_attack)
    local ccbiAttrTable = { name = "dlg_ui/NinjaTestSelectCell.ccbi", size = cellSize }
    layer_base_t.init(self, true, ccbiAttrTable)

    self.data = data
    self.is_attack = is_attack
    self:init_ui()
end



function init_ui(self)
    if self.proxy_ ~= nil then

        for i = 1, #self.data do
            self["sprite_icon_shouguan_0" .. tostring(i)] = tolua.cast(self.proxy_:getNode("sprite_icon_shouguan_0" .. tostring(i)), "CCSprite")
            self["sprite_wuxing_shouguan_0" .. tostring(i)] = tolua.cast(self.proxy_:getNode("sprite_wuxing_shouguan_0" .. tostring(i)), "CCSprite")
            self["sprite_gong_shouguan_0" .. tostring(i)] = tolua.cast(self.proxy_:getNode("sprite_gong_shouguan_0" .. tostring(i)), "CCSprite")
            self["label_attack_shouguan_0" .. tostring(i)] = tolua.cast(self.proxy_:getNode("label_attack_shouguan_0" .. tostring(i)), "CCLabelBMFont")
            self["node_hero_0" .. tostring(i)] = tolua.cast(self.proxy_:getNode("node_hero_0" .. tostring(i)), "CCNode")
            self["sprite_ninja_status_0" .. tostring(i)] = tolua.cast(self.proxy_:getNode("sprite_ninja_status_0" .. tostring(i)), "CCSprite")
        end

        if #self.data < 5 then
            for i = #self.data + 1, 5 do
                self["node_hero_0" .. tostring(i)] = tolua.cast(self.proxy_:getNode("node_hero_0" .. tostring(i)), "CCNode")
                self["node_hero_0" .. tostring(i)]:setVisible(false)
            end
        end
        self:init_ext_ui()
    end
end


function init_ext_ui(self)
    for i = 1, #self.data do
        -- 功防
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

        local ninja_id = self.data[i].ninjainfo:GetDataID()
        local ninjainfo = DataMgr.GetDataByID("Struct_Ninjainfo", ninja_id)
        local pFrameSprite = CGameObjElement:GetNinjaFrame(E_FRAMETYPE_SMALL, ninjainfo.m_quality)
        if pFrameSprite then
            self["sprite_icon_shouguan_0" .. tostring(i)]:setDisplayFrame(pFrameSprite)
        end

        local pIconFrame = CGameObjElement:GetNinjaIcon(E_FRAMETYPE_SMALL, ninjainfo.m_ninjaicon)
        local sprite1 = CCSprite:createWithSpriteFrame(pIconFrame)
        local _size = self["sprite_icon_shouguan_0" .. tostring(i)]:getContentSize()
        sprite1:setPosition(ccp(_size.width * 0.5, _size.height * 0.5))
        sprite1:setAnchorPoint(ccp(0.5, 0.5))
        self["sprite_icon_shouguan_0" .. tostring(i)]:addChild(sprite1)

        local county_icon_index = self.data[i].ninjainfo:GetCardCamp()
        local frame1 = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(tools.getAttributeIcon(county_icon_index))
        if frame1 ~= nil then
            self["sprite_wuxing_shouguan_0" .. tostring(i)]:setDisplayFrame(frame1)
        end

        self["label_attack_shouguan_0" .. tostring(i)]:setString(self.data[i].attack)
        if self.data[i].status == 0 then
            -- 被选中
            local frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("com_bt_gou")
            if frame ~= nil then
                self["sprite_ninja_status_0" .. tostring(i)]:setDisplayFrame(frame)
            end
        elseif self.data[i].status == 2 then
            local frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("ninja_test_die")
            if frame ~= nil then
                self["sprite_ninja_status_0" .. tostring(i)]:setDisplayFrame(frame)
            end
        else
            self["sprite_ninja_status_0" .. tostring(i)]:setVisible(false)
        end

    end
end


function init_status(self,i)
      self["sprite_ninja_status_0" .. tostring(i)]:setVisible(true)
      if self.data[i].status == 0 then
            -- 被选中
            local frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("com_bt_gou")
            if frame ~= nil then
                self["sprite_ninja_status_0" .. tostring(i)]:setDisplayFrame(frame)
            end
        elseif self.data[i].status == 2 then
            local frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("ninja_test_die")
            if frame ~= nil then
                self["sprite_ninja_status_0" .. tostring(i)]:setDisplayFrame(frame)
            end
        else
            self["sprite_ninja_status_0" .. tostring(i)]:setVisible(false)
        end

end


function findInList(self, index)
    local found = false
    local reti = 1
    for i = 1, #ui_ninjaTestSelect.ninjaTestMySelectList do
        if ui_ninjaTestSelect.ninjaTestMySelectList[i] == index then
            found = true
            reti = i
        end
    end

    return found, reti
end


function btnSelect(self, curr)
    cclog("1")
    local selected = ui_ninjaTestSelect.ninjaTestMySelectList
    local bFound, i = self:findInList(self.data[curr].ninjainfo:GetGUID())
    if bFound == true then
        table.remove(selected, i)
        self["sprite_ninja_status_0" .. tostring(i)]:setVisible(false)
        -- self.sprite_gou:setVisible(false)
    else
        -- 如果没有就加进去
        if #selected >= 5 then
            -- 卡位已满
            GetMainMenu():ShowTextTip(localizable.ui_trainsoul_maxsize, -1)
            return
        end
        table.insert(selected, self.data[curr].ninjainfo:GetGUID())
        self["sprite_ninja_status_0" .. tostring(i)]:setVisible(true)
        local frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("com_bt_gou")
        if frame ~= nil then
            self["sprite_ninja_status_0" .. tostring(i)]:setDisplayFrame(frame)
        end
        self.data[curr].status = 0
    end
    -- ui_trainNinjaListLayer.Instance:update_ui()
end




function onNodeCleanup(self)
    layer_base_t.onNodeCleanup(self)
end