----------------------------------------------------------------------
--  Copyright (c) 2014-2016, XCKOO. All Rights Reserved.
--  Author :Tango
--  Time   :2015/3/11 15:38:41
--  Remark :装备进阶成功对比界面
----------------------------------------------------------------------
module("ui_AdvanceEquipSucLayer", package.seeall)
baseClass(layer_base_t, ui_AdvanceEquipSucLayer)

function init(self, node, newObj)
	self.contentSize_ = GetMainMenu():GetModelLayer():getContentSize()
	local ccbiAttrTable = {name="sub_ui/AdvanceEquipSuc.ccbi", size=self.contentSize_}
	layer_base_t.init(self, true, ccbiAttrTable)

	--用户info
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	--pre info
	self.preNode = node

	self.m_touchPoint = nil
	
	self.newObj = newObj
	--init
	self:init_ui()		
	self:init_binding_event()
	self:initInfo()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		self.node_content = tolua.cast(self.proxy_:getNode("node_content"), "CCNode")
		self.node_cell = tolua.cast(self.proxy_:getNode("node_cell"), "CCNode")
		--btn
		self.btnClose = tolua.cast(self.proxy_:getNode("btnDialogClose"), "CCControlButton")
		self.btnOK = tolua.cast(self.proxy_:getNode("btnOK"), "CCControlButton")

		--label
		self.labelAttack_before = tolua.cast(self.proxy_:getNode("label_before_attack"),"CCLabelBMFont")
		self.labelAttack_after = tolua.cast(self.proxy_:getNode("label_after_attack"),"CCLabelBMFont")

		self.labelName_before = tolua.cast(self.proxy_:getNode("label_name_before"),"CCLabelTTF")
		self.labelName_after = tolua.cast(self.proxy_:getNode("label_name_after"),"CCLabelTTF")

		self.labelGrade_before = tolua.cast(self.proxy_:getNode("label_grade1"),"CCLabelBMFont")
		self.labelGrade_after = tolua.cast(self.proxy_:getNode("label_grade2"),"CCLabelBMFont")

		--sprite
		self.sprEquipIcon_before = tolua.cast(self.proxy_:getNode("sprite_ninjaicon_before"),"CCSprite")
		self.sprEquipIcon_after = tolua.cast(self.proxy_:getNode("sprite_ninjaicon_after"),"CCSprite")

		self.sprIcon_before = tolua.cast(self.proxy_:getNode("spr_icon_before"),"CCSprite")
		self.sprIcon_after = tolua.cast(self.proxy_:getNode("spr_icon_after"),"CCSprite")

		self.typeIcon_before = tolua.cast(self.proxy_:getNode("spr_before_type"),"CCSprite")
		self.typeIcon_after = tolua.cast(self.proxy_:getNode("spr_after_type"),"CCSprite")
	end
end

function initInfo(self)	
	if self.newObj == nil then
		return
	end

	-- icon
	local frame = CGameObjElement:GetNinjaFrame(E_FRAMETYPE_MIDDLE, self.newObj:GetQuality())
	self.sprEquipIcon_after:setDisplayFrame(frame)
	local icon = self.newObj:GetCardIcon(E_FRAMETYPE_LARGE)
	self.sprIcon_after:setDisplayFrame(icon)
	
	self.sprEquipIcon_before:setDisplayFrame(frame)
	self.sprIcon_before:setDisplayFrame(icon)

	--name 
	self.labelName_before:setString(self.newObj:GetName())
	self.labelName_after:setString(self.newObj:GetName())

	--type
	local info = DataMgr.GetDataByID("Struct_Equipmentinfo", tonumber(self.newObj:GetDataID()))
	if info == nil then
		return
	end

	local typeIcon = nil
	if info.m_equiptype == 0 then -- 武器
		typeIcon = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("com_fight_icon")
		self.labelAttack_after:setString(self.newObj:GetAttackMin() .. "-" .. self.newObj:GetAttackMax())
	elseif info.m_equiptype == 1 then -- 防具
		typeIcon = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("com_defense_icon")
		self.labelAttack_after:setString(self.newObj:GetDefenseMin() .. "-" .. self.newObj:GetDefenseMax())
	end

	self.typeIcon_before:setDisplayFrame(typeIcon)
	self.typeIcon_after:setDisplayFrame(typeIcon)

	--grade
	local grade = self.newObj:GetReincarnationLevel()
	self.labelGrade_after:setString('+' .. grade)
	if grade > 1 then
		self.labelGrade_before:setString('+'.. (grade-1))
		self.labelGrade_before:setVisible(true)
	else
		self.labelGrade_before:setVisible(false)
	end

	-- 计算进阶前1级的属性
	self.newObj:SetReincarnationLevel(grade - 1)
	self.newObj:InitFromID(self.newObj:GetDataID())
	self.newObj:SetLevel(1)

	if info.m_equiptype == 0 then
		self.labelAttack_before:setString(self.newObj:GetAttackMin() .. "-" .. self.newObj:GetAttackMax())
	elseif info.m_equiptype == 1 then
		self.labelAttack_before:setString(self.newObj:GetDefenseMin() .. "-" .. self.newObj:GetDefenseMax())
	end
	--恢复阶数 
	self.newObj:SetReincarnationLevel(grade)
	self.newObj:InitFromID(self.newObj:GetDataID())

end


function close( self )
	self.node_:removeFromParentAndCleanup(true)
end

function init_binding_event(self)
	if self.proxy_ ~= nil then
		--屏蔽掉后层触摸事件
		local function CCLayerTouch(event, x, y)
			if event == "began" then
				 return true
			end
		end

		self.node_:setTouchEnabled(true)
		self.node_:registerScriptTouchHandler(CCLayerTouch, false, kCCMenuHandlerPriority-1, true)

		self.btnClose:setTouchPriority(kCCMenuHandlerPriority-1)
		self.proxy_:handleButtonEvent(self.btnClose, function(button, event)
			self:close()
		end, CCControlEventTouchDown)

		self.btnOK:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.proxy_:handleButtonEvent(self.btnOK, function(button, event)
			self:close()
		end , CCControlEventTouchDown)

	end
end

function onNodeCleanup(self)
	if self.proxy_ then
    	self.proxy_:release()
    end

    layer_base_t.onNodeCleanup(self)
end
