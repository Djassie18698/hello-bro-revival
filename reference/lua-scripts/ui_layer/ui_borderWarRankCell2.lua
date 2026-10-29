----------------------------------------------------------------------
--  Copyright (c) 2014-2016, XCKOO. All Rights Reserved.
--  Author :Tango
--  Time   :2015/1/13 15:42:49
--  Remark :边界碑排行奖励
----------------------------------------------------------------------
module("ui_borderWarRankCell2", package.seeall)
baseClass(layer_base_t, ui_borderWarRankCell2)

function init(self, cellSize, data)
	local ccbiAttrTable = { name = "activity/BorderWarRankCell2.ccbi", size = cellSize }
	layer_base_t.init(self, true, ccbiAttrTable)

	cclog("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")
	self.cellData = data
	self:init_ui()
	self:init_binding_event()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		--- [[
		self.label_rank = tolua.cast(self.proxy_:getNode("rankCell_rank"), "CCLabelTTF")
		self.label_name = tolua.cast(self.proxy_:getNode("rankCell_name"), "CCLabelTTF")
		self.label_score = tolua.cast(self.proxy_:getNode("rankCell_score"), "CCLabelTTF")
		self.sprBox = tolua.cast(self.proxy_:getNode("spr_box"), "CCSprite")
		self.btnBox = tolua.cast(self.proxy_:getNode("btn_box"), "CCControlButton")

		self.label_rank:setString(tostring(self.cellData.rank))
		self.label_name:setString(tostring(self.cellData.nick))
		self.label_score:setString(tostring(self.cellData.score))

		local boxIndex = self.cellData.rank
		if tonumber(self.cellData.rank) > 4 then
			boxIndex = "4"
		end

		local pFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("borderAwardBox" .. boxIndex)
		if pFrame ~= nil then
			self.sprBox:setDisplayFrame(pFrame)
		end

	end
end

function init_binding_event(self)
	local function onClickedBox()
		require("ui_layer/ui_borderWarRankAwardPreviewLayer.lua")
		showModelLayer(ui_borderWarRankAwardPreviewLayer, self, self.cellData.award)
	end

	self.btnBox:setTouchPriority(kCCMenuHandlerPriority-1)
	self.btnBox:setTouchEnabled(true)
	self.proxy_:handleButtonEvent(self.btnBox, function(button, event)
		onClickedBox()
	end, CCControlEventTouchUpInside)
end

function onNodeCleanup(self)
	layer_base_t.onNodeCleanup(self)
end