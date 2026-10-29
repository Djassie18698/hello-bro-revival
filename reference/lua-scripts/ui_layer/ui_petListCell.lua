--
-- Author: Tango
-- Date: 2015-08-24 21:08:25
--

module("ui_petListCell", package.seeall)
baseClass(layer_base_t, ui_petListCell)

require('ui_layer/ui_petTrainingLayer')
require("ui_layer/ui_petAdvanceLayer")
require("ui_layer/ui_petUpgradeLayer")
require("ui_layer/secret_shop/ui_secretShopLayer")

local StarNum = 10

function init(self, cellSize, data, parent)
	local ccbiAttrTable = { name = "sub_ui/PetListCell.ccbi", size = cellSize }
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()
	layer_base_t.init(self, true, ccbiAttrTable)

	self.parent = parent
	self.pet = data
	self:init_ui()

end

function init_ui(self)
	if self.proxy_ ~= nil then
        local layer_info = tolua.cast(self.proxy_:getNode("layer_info"), "CCLayer")
        local layer_tips = tolua.cast(self.proxy_:getNode("layer_tips"), "CCLayer")
        if self.pet.id > 0 and self.pet.typeid > 0 then
            layer_info:setVisible(true)
            layer_tips:setVisible(false)
            self.label_inuse = tolua.cast(self.proxy_:getNode("label_inuse"), "CCLabelTTF")
            self.label_inuse:setString(localizable.ui_label_inuse_text)

		    self.btnUpgrade = tolua.cast(self.proxy_:getNode("btn_upgrade"), "CCControlButton")
		    self.btnTrain = tolua.cast(self.proxy_:getNode("btn_train"), "CCControlButton")
		    self.btnAdvance = tolua.cast(self.proxy_:getNode("btn_advance"), "CCControlButton")

		    self.sprStar = {}
		    for i=1,StarNum do
			    table.insert(self.sprStar, self:getCtrl('sprite_star' .. i,'CCSprite'))
		    end
		    -- show info
		    self:showInfo()
        else
            layer_info:setVisible(false)
            layer_tips:setVisible(true)
            self.btn_gototore = tolua.cast(self.proxy_:getNode("btn_gotostore"), "CCControlButton")
            tolua.cast(self.proxy_:getNode("label_tiptext"), "CCLabelTTF"):setString(localizable.ui_pet_text_4)

            self:init_btn_binding_event(self.btn_gototore, 
            function(button, event)
                local layer = createObj(ui_secretShopLayer, "petlist", self.pet.listLayer)
		        AddViewToActivitySubMenu(layer.node_)
            end,
            localizable.ui_label_gotomystore_text
        )
        end
	end
end

--
function showInfo(self)
	local info = self.pet.info

    if self.pet.inuse == 1 then
        self.label_inuse:setVisible(true)
    else
        self.label_inuse:setVisible(false)
    end
	
	--技能
	self:getCtrl('lb_skillName', 'CCLabelTTF'):setString(info:GetSkillName())
	self:getCtrl('lb_skillDesc', 'CCLabelTTF'):setString(info:GetSkillDesc(self.pet.lv))
	self:getCtrl('spr_skil_icon','CCSprite'):setDisplayFrame(info:GetSkillIcon(E_FRAMETYPE_SMALL))
	
	--宠物图标
	self:getCtrl('lb_name', 'CCLabelTTF'):setString(info:GetName())

	local sprIconBorder = self:getCtrl('spr_icon_border','CCSprite')
	sprIconBorder:setDisplayFrame(info:GetPetFrame(E_FRAMETYPE_MIDDLE))

    local sprIcon = self:getCtrl('node_icon','CCNode')
    local icon = CCSprite:createWithSpriteFrame(info:GetPetIcon(E_FRAMETYPE_MIDDLE))
    sprIcon:removeAllChildrenWithCleanup(true)
    local size = sprIcon:getContentSize()
    icon:setPosition(size.width * 0.5, size.height * 0.5)
    icon:setScale(0.5)
    sprIcon:addChild(icon)

	self:getCtrl('lb_level','CCLabelBMFont'):setString(self.pet.lv)
	
	--属性
	self:getCtrl('lb_atk','CCLabelBMFont'):setString(self.pet.atk)
	self:getCtrl('lb_atk_add','CCLabelBMFont'):setString('+' .. self.pet.atkAdd)

	self:getCtrl('lb_def','CCLabelBMFont'):setString(self.pet.def)
	self:getCtrl('lb_def_add','CCLabelBMFont'):setString('+' .. self.pet.defAdd)

	self:getCtrl('lb_chakra','CCLabelBMFont'):setString(self.pet.chakra)
	self:getCtrl('lb_chakra_add','CCLabelBMFont'):setString('+' .. self.pet.chakraAdd)

	local frameBlue = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName('com_normal_star_blue')
	local frameYellow = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName('com_normal_star')
	local frames = {[0] = frameBlue,[1] = frameYellow}

	for i = 1, 10 do
		self.sprStar[i]:setVisible(i <= self.pet.star)
	end

	self:getCtrl('sprite_star1','CCSprite'):setDisplayFrame(frame)

	self:init_binding_event()
end

function init_binding_event(self)
    --升级
     self:init_btn_binding_event(self.btnUpgrade, 
            function(button, event)
                local layer = createObj(ui_petUpgradeLayer, self.parent, self.pet)
		        AddViewToActivitySubMenu(layer.node_)
            end,
            localizable.ui_label_upgrade_text
        )
    --进阶
     self:init_btn_binding_event(self.btnAdvance, 
            function(button, event)
                local layer = createObj(ui_petAdvanceLayer,self.parent, self.pet)
		        AddViewToActivitySubMenu(layer.node_)
            end,
            localizable.ui_label_advance_text
        )
    --训练
     self:init_btn_binding_event(self.btnTrain, 
            function(button, event)
                local layer = createObj(ui_petTrainingLayer,self.parent, self.pet)
		        AddViewToActivitySubMenu(layer.node_)
            end,
            localizable.ui_label_train_text
        )
end

function getCtrl(self, ctrlname, type )
	return tolua.cast(self.proxy_:getNode(ctrlname), type)
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
