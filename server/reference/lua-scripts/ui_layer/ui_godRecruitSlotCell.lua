----------------------------------------------------------------------
--  Copyright (c) 2014-2016, XCKOO. All Rights Reserved.
--  Author :Tango
--  Time   :2015-12-23 17:48:36
--  Remark :神卡招募
----------------------------------------------------------------------

module("ui_godRecruitSlotCell", package.seeall)
baseClass(layer_base_t, ui_godRecruitSlotCell)

function init(self, cellSize, data)
	local ccbiAttrTable = {name="activity/GodRecruitSlotCell.ccbi", size=cellSize}
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()
	layer_base_t.init(self, true, ccbiAttrTable)

	self.data = data
	self:init_ui()
	--self:init_binding_event()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		self.sprNinja = tolua.cast(self.proxy_:getNode('spr_ninja'), "CCSprite")

		self:showInfo()
	end
end

function showInfo(self)
	self.ninja_id = self.data.card_id
	local ninjaIcon, ninjaFrame, quality = rl_get_iconsprite("1", "1", E_FRAMETYPE_MIDDLE, self.ninja_id)
	if ninjaIcon ~= nil then

		ninjaFrame = rl_get_ninjaFrame(E_FRAMETYPE_MIDDLE, quality)
		if ninjaFrame ~= nil then
			self.sprNinja:setDisplayFrame(ninjaFrame)
		end

		local size = self.sprNinja:getContentSize()
		ninjaIcon:setPosition(size.width/2, size.height/2)
		ninjaIcon:setScale(0.6)
		self.sprNinja:removeAllChildrenWithCleanup(true)
		self.sprNinja:addChild(ninjaIcon)

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