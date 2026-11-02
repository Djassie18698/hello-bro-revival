--[[
Description:限时神将活动积分排名TableCell
Company:XCKOO
Author:gongsun
Creation Date:2014/4/4
]]
module("ui_integralRankTableCell", package.seeall)
baseClass(layer_base_t, ui_integralRankTableCell)

function init(self, cellSize, data)
	local ccbiAttrTable = {name = "activity/LimitIntegralRankCell.ccbi", size = cellSize}
	layer_base_t.init(self, true, ccbiAttrTable)  --加载ccbi
	self.rank_data = data  --获取cell数据
	self:init_ui()  --初始化UI
end

function init_ui(self)
	if self.proxy_ ~= nil then
		self.label_rank    = tolua.cast(self.proxy_:getNode("label_rank"), "CCLabelTTF")
		self.label_name    = tolua.cast(self.proxy_:getNode("label_name"), "CCLabelTTF")
		self.label_score   = tolua.cast(self.proxy_:getNode("label_score"), "CCLabelTTF")
		self.sprite_bottom = tolua.cast(self.proxy_:getNode("sprite_bottom"), "CCNode")

		if self.rank_data.rank % 2 ~= 0 then
			self.sprite_bottom:setVisible(false)
		end
		self.label_rank:setString(self.rank_data.rank)
		self.label_name:setString(self.rank_data.nickname)
		self.label_score:setString(self.rank_data.score)
	end
end