--大富翁RankCell
--litao
--2014.1.18
---------------------------------------------
module("ui_monopolyRankCell", package.seeall)
baseClass(layer_base_t, ui_monopolyRankCell)

function init(self, cellSize, data)
	local ccbiAttrTable = {name="activity/MonopolyRankCellView.ccbi", size=cellSize}
	layer_base_t.init(self, true, ccbiAttrTable)

	self.cellData = data
	self:init_ui()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		self.label_rank =  tolua.cast(self.proxy_:getNode("label_rank"), "CCLabelTTF")
		self.label_name = tolua.cast(self.proxy_:getNode("label_name"), "CCLabelTTF")
		self.label_country = tolua.cast(self.proxy_:getNode("label_country"), "CCLabelTTF")
		self.label_score = tolua.cast(self.proxy_:getNode("label_score"), "CCLabelTTF")

		self.label_rank:setString(tostring(self.cellData.rank))
		self.label_name:setString(self.cellData.nick)
		self.label_country:setString(tostring(self.cellData.country))
		self.label_score:setString(self.cellData.score)
	end
end


function onNodeCleanup(self)
    layer_base_t.onNodeCleanup(self)
end