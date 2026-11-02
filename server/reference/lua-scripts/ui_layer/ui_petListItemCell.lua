--2015/08/24
--gongsun
--宠物列表
module("ui_petListItemCell", package.seeall)
baseClass(layer_base_t, ui_petListItemCell)

require("ui_layer/secret_shop/ui_secretShopLayer")

function init(self, cellSize, data)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	local ccbiAttrTable = {name="sub_ui/PetListItemCell.ccbi", size=cellSize}
	layer_base_t.init(self, true, ccbiAttrTable)

    --data
    self.m_data = data

    --init
	self:init_ui()
end

function init_ui(self)
	if self.proxy_ ~= nil then
        local layer_info = tolua.cast(self.proxy_:getNode("layer_info"), "CCLayer")
        local layer_tips = tolua.cast(self.proxy_:getNode("layer_tips"), "CCLayer")
        if self.m_data.id > 0 and self.m_data.petid > 0 then
            layer_info:setVisible(true)
            layer_tips:setVisible(false)
		    --label
		    self.label_name = tolua.cast(self.proxy_:getNode("label_name"), "CCLabelTTF")
		    self.label_level = tolua.cast(self.proxy_:getNode("label_level"), "CCLabelBMFont")
            self.label_attack = tolua.cast(self.proxy_:getNode("label_attack"), "CCLabelBMFont")
            self.label_defense = tolua.cast(self.proxy_:getNode("label_defense"), "CCLabelBMFont")
            self.label_chakala = tolua.cast(self.proxy_:getNode("label_chakala"), "CCLabelBMFont")
            self.label_inuse = tolua.cast(self.proxy_:getNode("label_inuse"), "CCLabelTTF")
            self.label_inuse:setString(localizable.ui_label_inuse_text)
            --node
            self.nodeframe = tolua.cast(self.proxy_:getNode("sprite_ninjaicon"), "CCSprite")
            self.node_icon = tolua.cast(self.proxy_:getNode("node_icon"), "CCNode")
		    --btn
		    self.btn_select = tolua.cast(self.proxy_:getNode("btn_select"), "CCControlButton")

		    --init info
		    self:init_ui_ext()
        else
            layer_info:setVisible(false)
            layer_tips:setVisible(true)
            self.btn_gototore = tolua.cast(self.proxy_:getNode("btn_gotostore"), "CCControlButton")
            tolua.cast(self.proxy_:getNode("label_tiptext"), "CCLabelTTF"):setString(localizable.ui_pet_text_4)

            self:init_btn_binding_event(self.btn_gototore, 
            function(button, event)
                local layer = createObj(ui_secretShopLayer, "petlist", self.m_data.listLayer)
		        AddViewToActivitySubMenu(layer.node_)
            end,
            localizable.ui_label_gotomystore_text
        )
        end
	end
end

function init_ui_ext(self)
	self.label_name:setString(self.m_data.pet:GetName())
    self.label_level:setString(self.m_data.level)
    self.label_attack:setString(self.m_data.attack)
    self.label_defense:setString(self.m_data.defense)
    self.label_chakala:setString(self.m_data.chakala)
    if self.m_data.inuse == 1 then
        self.label_inuse:setVisible(true)
    else
        self.label_inuse:setVisible(false)
    end
    --icon
    local iconFrame = self.m_data.pet:GetPetIcon(E_FRAMETYPE_SMALL)
    if iconFrame then
        local icon = CCSprite:createWithSpriteFrame(iconFrame)
        self.node_icon:removeAllChildrenWithCleanup(true)
        local size = self.node_icon:getContentSize()
        icon:setPosition(size.width * 0.5, size.height * 0.5)
        self.node_icon:addChild(icon)
    end

    local spriteFrame = self.m_data.pet:GetPetFrame(E_FRAMETYPE_SMALL)
    if spriteFrame then
        self.nodeframe:setDisplayFrame(spriteFrame)
    end
    --stars
    for i = 1, 10 do
        self.proxy_:getNode("sprite_star"..i):setVisible(i <= self.m_data.star)
    end
    
	self:init_binding_event()
end

function init_binding_event(self)
	if self.proxy_ ~= nil then
		-- 选择
        self:init_btn_binding_event(self.btn_select, 
            function(button, event)
                local cmd = 10
                if self.m_data.listLayer.pos > 0 and self.m_data.listLayer.petoldid == 0 then
                    cmd = 10
                elseif self.m_data.listLayer.pos == 0 and self.m_data.listLayer.petoldid == 0 then
                    cmd = 11
                elseif self.m_data.listLayer.pos > 0 and self.m_data.listLayer.petoldid > 0 then
                    cmd = 12
                elseif self.m_data.listLayer.pos == 0 and self.m_data.listLayer.petoldid > 0 then
                    cmd = 13
                end
                --获取基本信息
	            local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, cmd, "rl_x_pet")
                if cmd == 12 or cmd == 13 then
                    urlpath = AddData(urlpath, "PetID", self.m_data.listLayer.petoldid)
                    urlpath = AddData(urlpath, "DstPetID", self.m_data.id)
                else
                    urlpath = AddData(urlpath, "PetID", self.m_data.id)
                end
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
			            --cclog("rl_x_pet ret = %s", resData)
			            local retcode = item.code
			            if retcode == "0" then
                            --替换成功，返回通灵阵刷新
                            if self.m_data.listLayer.parent ~= nil then
                                self.m_data.listLayer.parent:update_ui()
                            end
                            self.m_data.listLayer.node_:removeFromParentAndCleanup(true)
			            else
				            GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
			            end
		            end)
            end,
            localizable.ui_label_select_text
        )
    end
end

function onNodeCleanup(self)
	if self.proxy_ then
    	self.proxy_:release()
    	self.proxy_ = nil
    end
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
