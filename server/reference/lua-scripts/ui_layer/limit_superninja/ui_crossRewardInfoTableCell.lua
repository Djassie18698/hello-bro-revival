--Description:跨服限时神将活动奖励说明TableCell
--Company:XCKOO
--Author:litao
--Creation Date:2014-08-25
--------------------------------------------------
module("ui_crossRewardInfoTableCell", package.seeall)
baseClass(layer_base_t, ui_crossRewardInfoTableCell)

function init(self, cellSize, data)
	local ccbiAttrTable = {name = "activity/LimitRewardInfoCellForCross.ccbi", size = cellSize}
	layer_base_t.init(self, true, ccbiAttrTable)  --加载ccbi
	self.reward_data = data  --获取cell数据
	self:init_ui()  --初始化UI
end

function init_ui(self)
	if self.proxy_ ~= nil then
		self.label_rank    = tolua.cast(self.proxy_:getNode("label_rank"), "CCLabelTTF")
		self.label_reward  = tolua.cast(self.proxy_:getNode("label_reward"), "CCLabelTTF")
		self.sprite_bottom = tolua.cast(self.proxy_:getNode("sprite_bottom"), "CCNode")
		
		if self.reward_data.id % 2 ~= 0 then
			self.sprite_bottom:setVisible(false)
		end
		self.label_rank:setString(self.reward_data.rankrange)
		self.label_reward:setString(self.reward_data.rewardName)
	end
end