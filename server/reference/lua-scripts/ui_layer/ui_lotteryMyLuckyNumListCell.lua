--my num Cell
--litao
--2014.5.19
---------------------------------------------
module("ui_lotteryMyLuckyNumListCell", package.seeall)
baseClass(layer_base_t, ui_lotteryMyLuckyNumListCell)

function init(self, cellSize, data)
	local ccbiAttrTable = {name="activity/LotteryMyLuckyNumListCell.ccbi", size=cellSize}
	layer_base_t.init(self, true, ccbiAttrTable)

	self.cellData = data
	self:init_ui()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		---[[
		self.label_index =  tolua.cast(self.proxy_:getNode("label_index"), "CCLabelTTF")
		self.label_lucky_nums = tolua.cast(self.proxy_:getNode("label_lucky_nums"), "CCLabelTTF")
		
		self.label_index:setString(tostring(self.cellData.index))

		if tonumber(self.cellData.num) < 1000 and tonumber(self.cellData.num) > 99 then
			self.label_lucky_nums:setString("0"..tostring(self.cellData.num))
		elseif tonumber(self.cellData.num) < 100 and tonumber(self.cellData.num) > 9 then
			self.label_lucky_nums:setString("00"..tostring(self.cellData.num))
		elseif tonumber(self.cellData.num) < 10 and tonumber(self.cellData.num) >= 0 then
			self.label_lucky_nums:setString("000"..tostring(self.cellData.num))
		else
			self.label_lucky_nums:setString(tostring(self.cellData.num))
		end
		--]]
		--cclog("cellData = %s", self.cellData)
	end
end

function onNodeCleanup(self)
    layer_base_t.onNodeCleanup(self)
end