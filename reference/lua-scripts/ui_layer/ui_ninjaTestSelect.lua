-- 中忍考试选择界面
-- liyongkang
-- 2015-10-22
---------------------------------------------
module("ui_ninjaTestSelect", package.seeall)
baseClass(layer_base_t, ui_ninjaTestSelect)

require("ui_layer/ui_ninjaTestSelectCell")

require("util/localizable")
require("util/tools")


ninjaTestMySelectList = { }

function init(self, parent, my_list_info, my_list,dead_list,is_attack)
    self.playerMgr_ = CPlayerDataMgr:instance()
    self.playerData_ = self.playerMgr_:GetPlayerInfoData()

    local winSize = CCDirector:sharedDirector():getWinSize()
    -- Load res
    local ccbiAttrTable = { name = "dlg_ui/NinjaTestSelect.ccbi", size = CCSizeMake(768, winSize.height) }

    layer_base_t.init(self, true, ccbiAttrTable)

    self.cellNodes = { }
    self.parent = parent

    self.my_list_info = { }
    self.my_list_info = tools.copyTab(my_list_info)

    self.my_list = {}
    self.my_list = tools.copyTab(my_list)   
    if self.my_list ~= nil then
        ui_ninjaTestSelect.ninjaTestMySelectList = tools.copyTab(self.my_list)        
    end
    self.my_bagList = { }

    self.dead_list = {}
    self.dead_list = dead_list

    self.curr_insert = 0
    self.is_attack = is_attack
    self:init_ui()
    self:loadData()
    self:init_binding_event()
end


function init_ui(self)
    if self.proxy_ ~= nil then
        self.button_close = tolua.cast(self.proxy_:getNode("closeButton"), "CCControlButton")
        self.button_myhero = tolua.cast(self.proxy_:getNode("button_myhero"), "CCControlButton")
        self.button_ok = tolua.cast(self.proxy_:getNode("button_ok"), "CCControlButton")

        self.node_tablecontent = tolua.cast(self.proxy_:getNode("node_content"), "CCNode")
        self.node_cardcontent = tolua.cast(self.proxy_:getNode("node_cell"), "CCNode")

        for i = 1, 5 do
            self["sprite_icon_my_0" .. tostring(i)] = tolua.cast(self.proxy_:getNode("sprite_icon_my_0" .. tostring(i)), "CCSprite")
            -- 我方
            self["sprite_wuxing_my_0" .. tostring(i)] = tolua.cast(self.proxy_:getNode("sprite_wuxing_my_0" .. tostring(i)), "CCSprite")
            -- 五行
            self["sprite_gong_my_0" .. tostring(i)] = tolua.cast(self.proxy_:getNode("sprite_gong_my_0" .. tostring(i)), "CCSprite")
            -- 功防
            if self.is_attack == 0 then
                local frame1 = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("com_small_defense_icon")
                -- 防
                if frame1 ~= nil then
                    self["sprite_gong_my_0" .. tostring(i)]:setDisplayFrame(frame1)
                end
            else
                local frame1 = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("com_small_attack_icon")
                -- 功
                if frame1 ~= nil then
                    self["sprite_gong_my_0" .. tostring(i)]:setDisplayFrame(frame1)
                end
            end
            self["label_attack_my_0" .. tostring(i)] = tolua.cast(self.proxy_:getNode("label_attack_my_0" .. tostring(i)), "CCLabelBMFont")
            -- 攻击力
            self["sprite_dead_my_0" .. tostring(i)] = tolua.cast(self.proxy_:getNode("sprite_dead_my_0" .. tostring(i)), "CCSprite")

        end

        --移除死亡忍者
        for i = #self.my_list_info, 1, -1 do       
            if self.my_list_info[i].dead == true then                
                table.remove(self.my_list,i)
                table.remove(self.my_list_info,i)
                table.remove(ui_ninjaTestSelect.ninjaTestMySelectList,i)
            end
        end
        

        for i = 1, #self.my_list do
            -- 我方信息
            if self.is_attack == 0 then
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
            
            local ninja = CPlayerDataMgr:instance():GetObjectByID(self.my_list[i]) 
                    
            local ninjainfo = DataMgr.GetDataByID("Struct_Ninjainfo", tonumber(ninja:GetDataID()))
            local pFrameSprite = CGameObjElement:GetNinjaFrame(E_FRAMETYPE_SMALL, ninjainfo.m_quality)
            self["sprite_icon_my_0" .. tostring(i)]:setDisplayFrame(pFrameSprite)
            self["sprite_icon_my_0" .. tostring(i)]:removeAllChildrenWithCleanup(true)


            local pIconFrame = CGameObjElement:GetNinjaIcon(E_FRAMETYPE_SMALL, ninjainfo.m_ninjaicon)
            local sprite1 = CCSprite:createWithSpriteFrame(pIconFrame)
            local _size = self["sprite_icon_my_0" .. tostring(i)]:getContentSize()
            sprite1:setPosition(ccp(_size.width * 0.5, _size.height * 0.5))
            sprite1:setAnchorPoint(ccp(0.5, 0.5))
            self["sprite_icon_my_0" .. tostring(i)]:addChild(sprite1)

            local county_icon_index = ninja:GetCardCamp()
            local localCardCamp = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(tools.getAttributeIcon(county_icon_index))
            self["sprite_wuxing_my_0" .. tostring(i)]:setDisplayFrame(localCardCamp)

            self["label_attack_my_0" .. tostring(i)]:setString(self.my_list_info[i].attack)
         
            if self.my_list_info[i].dead == true then
                self["sprite_dead_my_0" .. tostring(i)]:setVisible(true)
            else
                self["sprite_dead_my_0" .. tostring(i)]:setVisible(false)
            end

        end

        if #self.my_list < 5 then
            for i = #self.my_list + 1, 5 do
                --
                local spriteFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("small_icon_frame_clickadd")
                if spriteFrame then
                    self["sprite_icon_my_0" .. tostring(i)]:setDisplayFrame(spriteFrame)
                end
                self["sprite_wuxing_my_0" .. tostring(i)]:setVisible(false)
                self["sprite_gong_my_0" .. tostring(i)]:setVisible(false)         
                self["label_attack_my_0" .. tostring(i)]:setVisible(false)              
                self["sprite_dead_my_0" .. tostring(i)]:setVisible(false)
              
            end
        end

    end
end




function loadData(self)
    self.m_playerDatas = { }
    self.array = { }

    self.m_playerDatas = self:getNinjaList()

    local number = 5
    local rowCount = math.modf(#self.m_playerDatas / number)
    if #self.m_playerDatas % number > 0 then
        rowCount = rowCount + 1
    end

    for i = 1, rowCount do
        self.array[i] = { }
        for j = 1, number do
            self.array[i][j] = self.m_playerDatas[number *(i - 1) + j]
        end
    end

    self:createRankTableView()
end

function getNinjaList(self)
    local ninjaList = { }
    local objlist = CPlayerDataMgr:instance():GetObjectList(e_obj_ninja)
    local count = objlist:size() -1
    for i = 0, count do
        local ninja = objlist[i]
        local st = 0
        st = self:findStatus(ninja:GetGUID())
        cclog("guid_________%d",ninja:GetGUID())
        if ninja:GetQuality() >= 4 then

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

            local attack_or_defense = 0
            if self.is_attack == 1 then
                attack_or_defense =((attackmin + attack_current_plus) +(attackmax + attack_current_plus)) / 2
            else
                attack_or_defense =((defensemin + defense_current_plus) +(defensemax + defense_current_plus)) / 2
            end
           
            table.insert(ninjaList, { ninjainfo = ninja, status = st, attack = math.modf(attack_or_defense), })
            -- status  0选中 1不做操作  2 死亡
        end
    end



    
    local SortFunc = function (a, b)
        if a.status == b.status then
            return a.attack > b.attack
        else
            return a.status < b.status
        end
    end

    table.sort(ninjaList, SortFunc)

    return ninjaList
end

function findStatus(self,bag_index)
    local status = 1

     for i = 1 ,#self.my_list do
        if tonumber(self.my_list[i]) == tonumber(bag_index) then
            status = 0
            break
        end
    end

    for i = 1 ,#self.dead_list do
        if tonumber(self.dead_list[i]) == tonumber(bag_index) then
            status = 2
            break
        end
    end
    
    return status
end




function init_binding_event(self)
    if self.proxy_ ~= nil then
        -- 屏蔽下层的触摸
        local function CCLayerTouch(event)
            if event == "began" then
                return true
            end
        end
        self.node_:setTouchEnabled(true)
        self.node_:registerScriptTouchHandler(CCLayerTouch, false, kCCMenuHandlerPriority - 1, true)

        local function onBtnClose(btn)
            cclog("onBtnClose")
            self.node_:removeFromParentAndCleanup(true)
        end

        local function onBtnMyHero(btn)
            cclog("onBtnMyHero")
            -- self.node_:removeFromParentAndCleanup(true)
            if #ui_ninjaTestSelect.ninjaTestMySelectList > 0 then
                local gu_id = ui_ninjaTestSelect.ninjaTestMySelectList[#ui_ninjaTestSelect.ninjaTestMySelectList]
                self:update_data(gu_id)
                self:setHide(#ui_ninjaTestSelect.ninjaTestMySelectList)
                table.remove(ui_ninjaTestSelect.ninjaTestMySelectList, #ui_ninjaTestSelect.ninjaTestMySelectList)
            end
        end

        local function onBtnOk(btn)
            self:submit_data()
        end

        self.button_close:setTouchPriority(kCCMenuHandlerPriority - 1)
        self.proxy_:handleButtonEvent(self.button_close, function(button, event)
            onBtnClose(button)
            return nil
        end , CCControlEventTouchUpInside)

        self.button_myhero:setTouchPriority(kCCMenuHandlerPriority - 1)
        self.proxy_:handleButtonEvent(self.button_myhero, function(button, event)
            onBtnMyHero(button)
            return nil
        end , CCControlEventTouchUpInside)

        self.button_ok:setTouchPriority(kCCMenuHandlerPriority - 1)
        self.proxy_:handleButtonEvent(self.button_ok, function(button, event)
            onBtnOk(button)
            return nil
        end , CCControlEventTouchUpInside)


        -- self.button_myhero
    end
end

function createRankTableView(self)
    -- body
    if self.rankTableView == nil then
        self.rank_cellsize = self.node_cardcontent:getContentSize()
        self.rank_tableContentSize = self.node_tablecontent:getContentSize()
        self:initRankTableHandle()
        self.rankTableView = LuaTableView:createWithHandler(self.rankTableViewHandler, CCSizeMake(self.rank_tableContentSize.width, self.rank_tableContentSize.height))
        self.rankTableView:setDirection(kCCScrollViewDirectionVertical)
        self.rankTableView:setVerticalFillOrder(kCCTableViewFillTopDown)
        self.rankTableView:setTouchPriority(kCCMenuHandlerPriority - 1)
        self.node_tablecontent:addChild(self.rankTableView)
    else
        self.rankTableView:reloadData()
    end
end

function initRankTableHandle(self)
    self.rankTableViewHandler = LuaEventHandler:create( function(fn, table, a1, a2, x, y)
        local r
        if fn == "cellSize" then
            r = self.rank_cellsize;
        elseif fn == "cellAtIndex" then
            local nodeLayer = createObj(ui_ninjaTestSelectCell, self.rank_cellsize, self.array[a1 + 1],self.is_attack)
            -- self.m_playerDatas[a1 + 1])
            self.cellNodes[a1 + 1] = nodeLayer
            if not a2 then
                a2 = CCTableViewCell:create()
                a2:addChild(nodeLayer.node_)
            else
                a2:removeAllChildrenWithCleanup(true)
                a2:addChild(nodeLayer.node_)
            end
            nodeLayer.node_:setTag(100);
            r = a2
        elseif fn == "numberOfCells" then
            r = #self.array
        elseif fn == "cellTouched" then
            -- A cell was touched, a1 is cell that be touched. This is not necessary.
            local cell_index = a1:getIdx() + 1
            local _layer = self.cellNodes[cell_index]

            -- 无法使用按钮 通过图片位置判断点击位置
            local index = 0
            for i = 1, 5 do
                if _layer["node_hero_0" .. tostring(i)]:boundingBox():containsPoint(self.m_touchPoint) then
                    if tonumber(self.array[cell_index][i].status) == 2 then
                        -- 阵亡
                        GetMainMenu():ShowTextTip(localizable.ui_ninjaTestSelect_text1, -1)
                    elseif tonumber(self.array[cell_index][i].status) == 0 then
                        -- 已上阵
                        GetMainMenu():ShowTextTip(localizable.ui_ninjaTestSelect_text2, -1)
                    else
                        -- local index = self.array[cell_index][i].ninjainfo:GetGUID()
                        -- table.insert( self.my_list,{bag_index = index})
                        -- _layer:btnSelect(i)
                        self:resetData(cell_index, i)
                    end

                end
            end
            self.m_touchPoint = nil;

        elseif fn == "cellTouchBegan" then
            -- A cell is touching, a1 is cell, a2 is CCTouch
            self.m_touchPoint = a2:getLocation()
            local cell = self.cellNodes[a1:getIdx() + 1]
            self.m_touchPoint = cell.node_:convertToNodeSpace(self.m_touchPoint)
            r = true
        elseif fn == "cellTouchEnded" then
            -- A cell was touched, a1 is cell, a2 is CCTouch
            r = true
        elseif fn == "cellHighlight" then
            -- A cell is highlighting, coco2d-x 2.1.3 or above
        elseif fn == "cellUnhighlight" then
            -- A cell had been unhighlighted, coco2d-x 2.1.3 or above
        elseif fn == "cellWillRecycle" then
            -- A cell will be recycled, coco2d-x 2.1.3 or above	
        end
        return r
    end )
end

function update_data(self, guid)
     
    local arrayi = #self.array
    for i = 1, arrayi do
        local arrayj = #self.array[i]
        for j = 1, arrayj do
            local forguid = self.array[i][j].ninjainfo:GetGUID()
            if forguid == tonumber(guid) then
                if tonumber(self.array[i][j].status) ~= 2 then
                    self.array[i][j].status = 1
                    local layer = self.cellNodes[i]
                    layer:init_status(j)
                end
            end

        end
    end
end

function resetData(self, cell_index, i)
    local selected = ui_ninjaTestSelect.ninjaTestMySelectList
    if #selected >= 5 then
        -- 卡位已满
        GetMainMenu():ShowTextTip(localizable.ui_ninjaTestSelect_text3, -1)
        return
    end

    self.array[cell_index][i].status = 0
    table.insert(selected, self.array[cell_index][i].ninjainfo:GetGUID())
    self.curr_insert = #selected

    -- self.my_list = selected
    -- self.rankTableView:reloadData()
    local layer = self.cellNodes[cell_index]
    layer:init_status(i)
    self:init_ui_ext(self.array[cell_index][i].ninjainfo, self.array[cell_index][i].attack)

end

function setHide(self, index)
    local i = index
    local spriteFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("small_icon_frame_clickadd")
    if spriteFrame then
        self["sprite_icon_my_0" .. tostring(i)]:setDisplayFrame(spriteFrame)
    end
    self["sprite_wuxing_my_0" .. tostring(i)]:setVisible(false)
    self["sprite_gong_my_0" .. tostring(i)]:setVisible(false)
    self["label_attack_my_0" .. tostring(i)]:setVisible(false)
    self["sprite_dead_my_0" .. tostring(i)]:setVisible(false)
    self["sprite_icon_my_0" .. tostring(i)]:removeAllChildrenWithCleanup(true)
end


function init_ui_ext(self, ninjainfo_self, attack)
    local i = self.curr_insert

    self["sprite_wuxing_my_0" .. tostring(i)]:setVisible(true)
    self["sprite_gong_my_0" .. tostring(i)]:setVisible(true)
    self["label_attack_my_0" .. tostring(i)]:setVisible(true)

    local ninja_id = ninjainfo_self:GetDataID()

    local ninjainfo = DataMgr.GetDataByID("Struct_Ninjainfo", ninja_id)

    local pFrameSprite = CGameObjElement:GetNinjaFrame(E_FRAMETYPE_SMALL, ninjainfo.m_quality)
    if pFrameSprite then
        self["sprite_icon_my_0" .. tostring(i)]:setDisplayFrame(pFrameSprite)
    end

    local pIconFrame = CGameObjElement:GetNinjaIcon(E_FRAMETYPE_SMALL, ninjainfo.m_ninjaicon)
    local sprite1 = CCSprite:createWithSpriteFrame(pIconFrame)
    local _size = self["sprite_icon_my_0" .. tostring(i)]:getContentSize()
    sprite1:setPosition(ccp(_size.width * 0.5, _size.height * 0.5))
    sprite1:setAnchorPoint(ccp(0.5, 0.5))
    self["sprite_icon_my_0" .. tostring(i)]:addChild(sprite1)

    local county_icon_index = ninjainfo_self:GetCardCamp()
    local frame1 = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(tools.getAttributeIcon(county_icon_index))
    if frame1 ~= nil then
        self["sprite_wuxing_my_0" .. tostring(i)]:setDisplayFrame(frame1)
    end

    self["label_attack_my_0" .. tostring(i)]:setString(attack)

end


function submit_data(self)

   
    local index_list = ""
    -- index_list = table.concat(ui_ninjaTestSelect.ninjaTestMySelectList);

    for i = 1, #ui_ninjaTestSelect.ninjaTestMySelectList do
        index_list = index_list .. tostring(ui_ninjaTestSelect.ninjaTestMySelectList[i])
        if i ~= #ui_ninjaTestSelect.ninjaTestMySelectList then
            index_list = index_list .. "_"
        end
    end
  
    local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 2, "rl_x_exam")
    urlpath = AddData(urlpath, "card_index_list", index_list)   

    cclog("%s", urlpath)
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
            self.parent:setMyList(ui_ninjaTestSelect.ninjaTestMySelectList)
            self.parent:updateUI()
            self.node_:removeFromParentAndCleanup(true)
        else
            --GetMainMenu():ShowErrorTip(tonumber(retcode), -1)
            GetMainMenu():ShowTextTip(text.text_config[tonumber(retcode)].description, -1)
        end
    end )


end


function onNodeCleanup(self)
    -- cclog("onNodeCleanup")
    if self.proxy_ then
        self.proxy_:release()
    end
    ui_ninjaTestSelect.ninjaTestMySelectList = { }
    layer_base_t.onNodeCleanup(self)
end

