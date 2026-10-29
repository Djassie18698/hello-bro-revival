--gongsun
--2015-08-26
--宠物升级

module("ui_petUpgradeLayer", package.seeall)
baseClass(layer_base_t, ui_petUpgradeLayer)

function init(self, parent, petUpgrade)
    self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

    self.contentSize_ = GetMainMenu():GetSubContentNode():getContentSize()
	local ccbiAttrTable = {name="sub_ui/PetUpgradeView.ccbi", size=self.contentSize_}
	layer_base_t.init(self, true, ccbiAttrTable)

    --data
    self.parent = parent
    self.petUpgrade = petUpgrade
    
	initHeader(self.proxy_)
    self:init_ui()
	self:init_binding_event()
    self:requestBaseLayerInfo(0)
end

function requestBaseLayerInfo(self, firstShow)
	--获取基本信息
	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 6, "rl_x_pet")
    urlpath = AddData(urlpath, "PetID", self.petUpgrade.id)
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
			local retcode = item.code
			if retcode == "0" then
                local pet = item:find("basic")
                if pet then
                    self.level = tonumber(pet:find("level")[1])
                    local equ = tonumber(pet:find("rank")[1])
                    self.star = tonumber(pet:find("star")[1])
                    self.pet = CPlayerPet:new(self.petUpgrade.typeid, self.level, equ, self.star)
                    self.maxLevel = tonumber(pet:find("max_level")[1])
                    self.prop_id = tonumber(pet:find("prop_id")[1])
                    self.prop_num = tonumber(pet:find("prop_num")[1])
                end
                local num = item:find("num")
                if num then
                    local current = num:find("current")
                    if current then
                        self.attack = tonumber(current:find("attack")[1])
                        self.defense = tonumber(current:find("defense")[1])
                        self.chakala = tonumber(current:find("chakala")[1])
                        self.attack_buff = tonumber(current:find("attack_buff")[1])
                        self.defense_buff = tonumber(current:find("defense_buff")[1])
                        self.chakala_buff = tonumber(current:find("chakala_buff")[1])
                    end
                    local _next = num:find("next")
                    if _next then
                        self.attackNext = tonumber(_next:find("attack")[1])
                        self.defenseNext = tonumber(_next:find("defense")[1])
                        self.chakalaNext = tonumber(_next:find("chakala")[1])
                        self.attack_buffNext = tonumber(_next:find("attack_buff")[1])
                        self.defense_buffNext = tonumber(_next:find("defense_buff")[1])
                        self.chakala_buffNext = tonumber(_next:find("chakala_buff")[1])
                    end
                end
                
                --init
                if firstShow == 0 then
                    self:showInfo()
                end
	            self:update_ui()
			else
				GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
			end
		end)
end

function init_ui(self)
	if self.proxy_ ~= nil then
		--btn
		self.btn_upgrade = self:getCtrl("btn_upgrade", "CCControlButton")
        self.btn_back = self:getCtrl("btn_back", "CCControlButton")
        --label&icon
        self.label_skilldesc_pre = self:getCtrl("label_skilldesc_pre", "CCLabelTTF")
        self.label_skilldesc_next = self:getCtrl("label_skilldesc_next", "CCLabelTTF")
        self.label_level_pre = self:getCtrl("label_level_pre", "CCLabelBMFont")
        self.label_level1_pre = self:getCtrl("label_level1_pre", "CCLabelBMFont")
        self.label_level_next = self:getCtrl("label_level_next", "CCLabelBMFont")
        self.label_level1_next = self:getCtrl("label_level1_next", "CCLabelBMFont")
        self.label_attack_pre = self:getCtrl("label_attack_pre", "CCLabelBMFont")
        self.label_attack_next = self:getCtrl("label_attack_next", "CCLabelBMFont")
        self.label_attackAdd_pre = self:getCtrl("label_attackAdd_pre", "CCLabelBMFont")
        self.label_attackAdd_next = self:getCtrl("label_attackAdd_next", "CCLabelBMFont")
        self.label_defense_pre = self:getCtrl("label_defense_pre", "CCLabelBMFont")
        self.label_defense_next = self:getCtrl("label_defense_next", "CCLabelBMFont")
        self.label_defenseAdd_pre = self:getCtrl("label_defenseAdd_pre", "CCLabelBMFont")
        self.label_defenseAdd_next = self:getCtrl("label_defenseAdd_next", "CCLabelBMFont")
        self.label_chakala_pre = self:getCtrl("label_chakala_pre", "CCLabelBMFont")
        self.label_chakala_next = self:getCtrl("label_chakala_next", "CCLabelBMFont")
        self.label_chakalaAdd_pre = self:getCtrl("label_chakalaAdd_pre", "CCLabelBMFont")
        self.label_chakalaAdd_next = self:getCtrl("label_chakalaAdd_next", "CCLabelBMFont")
        self.label_consumeName = self:getCtrl("label_consumeName", "CCLabelTTF")
        self.label_consumeNum = self:getCtrl("label_consumeNum", "CCLabelBMFont")
        self.nodeConsume = self:getCtrl("node_consume", "CCNode")
        --
        self:getCtrl("label_title", "CCLabelTTF"):setString(localizable.ui_label_upgrade_text)
        self:getCtrl("txt1_pre", "CCLabelTTF"):setString(localizable.ui_label_property_buff_text)
        self:getCtrl("txt1_next", "CCLabelTTF"):setString(localizable.ui_label_property_buff_text)
        self:getCtrl("txt_consume", "CCLabelTTF"):setString(localizable.ui_label_consume_text)        
	end
end

function update_ui(self)
    if self.level >= self.maxLevel then
        self.nextLevel = self.level
    else
        self.nextLevel = self.level + 1
    end
    --diff
    self.label_skilldesc_pre:setString(self.pet:GetSkillDesc(self.level))
    self.label_skilldesc_next:setString(self.pet:GetSkillDesc(self.nextLevel))
    self.label_level_pre:setString(self.level)
    self.label_level1_pre:setString(self.level)
    self.label_level_next:setString(self.nextLevel)
    self.label_level1_next:setString(self.nextLevel)
    self.label_attack_pre:setString(self.attack)
    self.label_attack_next:setString(self.attackNext)
    self.label_attackAdd_pre:setString("+"..self.attack_buff)
    self.label_attackAdd_next:setString("+"..self.attack_buffNext)
    self.label_defense_pre:setString(self.defense)
    self.label_defense_next:setString(self.defenseNext)
    self.label_defenseAdd_pre:setString("+"..self.defense_buff)
    self.label_defenseAdd_next:setString("+"..self.defense_buffNext)
    self.label_chakala_pre:setString(self.chakala)
    self.label_chakala_next:setString(self.chakalaNext)
    self.label_chakalaAdd_pre:setString("+"..self.chakala_buff)
    self.label_chakalaAdd_next:setString("+"..self.chakala_buffNext)
    --consume
    self.label_consumeName:setString(self.pet:GetComsumeNameById(self.prop_id))
    local itemInfo = tolua.cast(CTradeMgr:instance():GetConsumByIDForLua(self.prop_id), "ConsumeInfo")
    if itemInfo == nil then
        self.playerHasItemNum = 0
    else
        self.playerHasItemNum = itemInfo.m_bagnum
    end
    self.label_consumeNum:setString(self.playerHasItemNum .. "/" .. self.prop_num)
    if self.prop_num > self.playerHasItemNum then
        self.label_consumeNum:setColor(Color3.Red)
    end
    local consumeFrame = self.pet:GetComsumeIconById(self.prop_id, E_FRAMETYPE_SMALL)
    if consumeFrame then
        self.nodeConsume:removeAllChildrenWithCleanup(true)
        local consumeIcon = CCSprite:createWithSpriteFrame(consumeFrame)
        local consumeSize = self.nodeConsume:getContentSize()
        consumeIcon:setPosition(consumeSize.width * 0.5, consumeSize.height * 0.5)
        self.nodeConsume:addChild(consumeIcon)
    end
end

function showInfo(self)
    self:getCtrl("label_name_pre", "CCLabelTTF"):setString(self.pet:GetName())
    self:getCtrl("label_name_next", "CCLabelTTF"):setString(self.pet:GetName())
    self:getCtrl("label_skillname_pre", "CCLabelTTF"):setString(self.pet:GetSkillName())
    self:getCtrl("label_skillname_next", "CCLabelTTF"):setString(self.pet:GetSkillName())
    local petFrame = self.pet:GetPetFrame(E_FRAMETYPE_MIDDLE)
    if petFrame then
        self:getCtrl("sprite_frame_pre", "CCSprite"):setDisplayFrame(petFrame)
        self:getCtrl("sprite_frame_next", "CCSprite"):setDisplayFrame(petFrame)
    end
    local petIcon = self.pet:GetPetIcon(E_FRAMETYPE_MIDDLE)
    if petIcon then
        local iconPre = CCSprite:createWithSpriteFrame(petIcon)
        local nodeIconPre = self:getCtrl("node_icon_pre", "CCNode")
        nodeIconPre:removeAllChildrenWithCleanup(true)
        local size = nodeIconPre:getContentSize()
        iconPre:setScale(0.5)
        iconPre:setPosition(size.width * 0.5, size.height * 0.5)
        nodeIconPre:addChild(iconPre)
        local iconNext = CCSprite:createWithSpriteFrame(petIcon)
        local nodeIconNext = self:getCtrl("node_icon_next", "CCNode")
        nodeIconNext:removeAllChildrenWithCleanup(true)
        iconNext:setScale(0.5)
        iconNext:setPosition(size.width * 0.5, size.height * 0.5)
        nodeIconNext:addChild(iconNext)
    end
    local skillIcon = self.pet:GetSkillIcon(E_FRAMETYPE_SMALL)
    if skillIcon then
        local skillIconPre = CCSprite:createWithSpriteFrame(skillIcon)
        local nodeSkillPre = self:getCtrl("node_skillicon_pre", "CCNode")
        nodeSkillPre:removeAllChildrenWithCleanup(true)
        local size = nodeSkillPre:getContentSize()
        skillIconPre:setPosition(size.width * 0.5, size.height * 0.5)
        nodeSkillPre:addChild(skillIconPre)
        local skillIconNext = CCSprite:createWithSpriteFrame(skillIcon)
        local nodeSkillNext = self:getCtrl("node_skillicon_next", "CCNode")
        nodeSkillNext:removeAllChildrenWithCleanup(true)
        skillIconNext:setPosition(size.width * 0.5, size.height * 0.5)
        nodeSkillNext:addChild(skillIconNext)
    end
    --
    for i = 1, 10 do
        self:getCtrl("sprite_star"..i.."_pre" , "CCSprite"):setVisible(i <= self.star)
        self:getCtrl("sprite_star"..i.."_next" , "CCSprite"):setVisible(i <= self.star)
    end
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
                if self.parent ~= nil then
                    self.parent:update_ui()
                end
                self.node_:removeFromParentAndCleanup(true)
            end,
            localizable.ui_label_back_text
        )
		-- 升级
        self:init_btn_binding_event(self.btn_upgrade, 
            function(button, event)
                if self.level >= self.maxLevel then
                    GetMainMenu():ShowTextTip(localizable.ui_petAdvance_maxLevel_tip, -1)
                else
                    self:requestUpdate()
                end
            end,
            localizable.ui_label_upgrade_text
        )
    end
end

function requestUpdate(self)
    --获取基本信息
	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 7, "rl_x_pet")
    urlpath = AddData(urlpath, "PetID", self.petUpgrade.id)
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
			local retcode = item.code
			if retcode == "0" then
                local pet = item:find("basic")
                if pet then
                    local upgrade = tonumber(pet:find("upgrade")[1])
                    if upgrade == 1 then
                        --减去消耗
                        CTradeMgr:instance():SetConsumItemCountByID(self.prop_id, self.playerHasItemNum - self.prop_num)
                        self:requestBaseLayerInfo(1)
                    else
                        GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
                    end
                end
			else
				GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
			end
		end)
end

function getCtrl(self, ctrlname, type )
	return tolua.cast(self.proxy_:getNode(ctrlname), type)
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