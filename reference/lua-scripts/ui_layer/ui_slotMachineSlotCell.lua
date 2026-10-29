----------------------------------------------------------------------
--  Copyright (c) 2014-2016, XCKOO. All Rights Reserved.
--  Author :Tango
--  Time   :2015/6/29 21:02:16
--  Remark :摇摇乐滚动槽
----------------------------------------------------------------------

module("ui_slotMachineSlotCell", package.seeall)
baseClass(layer_base_t, ui_slotMachineSlotCell)

function init(self, cellSize, data)
	local ccbiAttrTable = {name="activity/SlotMachineSlotCell.ccbi", size=cellSize}
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()
	layer_base_t.init(self, true, ccbiAttrTable)

	self.cellData = data
	self:init_ui()
	--self:init_binding_event()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		self.sprSlot = tolua.cast(self.proxy_:getNode('spr_slot'), "CCSprite")

		self:showInfo()
	end
end

function showInfo(self)
		local pathName = "icon/"..self.cellData.icon..".plist"
		CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile(pathName)
		local frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(self.cellData.icon)
		if frame ~= nil then
			self.sprSlot:setDisplayFrame(frame)
			--sprSlot:setScale(66/106)
		end
end

function init_binding_event(self)
	--奖励详情
	local function onBtnClickAwardIcon(btn)
		local btnIndex = btn:getTag()
		
		if btnIndex > 0 and btnIndex <= 4 then
			local _id = tonumber(self.cellData[btnIndex].id)
			if nil ~= _id then
				CGameObjElement:ShowDropByID(_id)
			end
		end
	end

	for i = 1, 4 do
		self["btn_item_"..i]:setTouchPriority(1)
		self["btn_item_"..i]:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self["btn_item_"..i], function(button, event)
			onBtnClickAwardIcon(button)
			return nil
		end, CCControlEventTouchUpInside)
	end
end

function onNodeCleanup(self)
	---[[
	if self.proxy_ then
    	self.proxy_:release()
    	self.proxy_ = nil
    end
    --]]
    layer_base_t.onNodeCleanup(self)
end