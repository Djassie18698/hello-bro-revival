--rankCell
--litao
--2014.5.19
---------------------------------------------
module("ui_lotteryPreWinerListCell", package.seeall)
baseClass(layer_base_t, ui_lotteryPreWinerListCell)

function init(self, cellSize, data)
	local ccbiAttrTable = {name="activity/LotteryWinerCell.ccbi", size=cellSize}
	layer_base_t.init(self, true, ccbiAttrTable)

	self.cellData = data
	self:init_ui()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		---[[
		self.label_pt =  tolua.cast(self.proxy_:getNode("label_pt"), "CCLabelTTF")
		self.label_server = tolua.cast(self.proxy_:getNode("label_server"), "CCLabelTTF")
		self.label_name = tolua.cast(self.proxy_:getNode("label_name"), "CCLabelTTF")

		self.label_pt:setString(tostring(self.cellData.pt))
		self.label_server:setString(tostring(self.cellData.server))
		self.label_name:setString(tostring(self.cellData.name))
		--]]
		--cclog("cellData = %s", self.cellData)
	end
end

function onNodeCleanup(self)
    layer_base_t.onNodeCleanup(self)
end