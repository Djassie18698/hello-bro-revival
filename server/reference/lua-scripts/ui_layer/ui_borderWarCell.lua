--边界碑Cell
--litao
--2014.2.15
---------------------------------------------
module("ui_borderWarCell", package.seeall)
baseClass(layer_base_t, ui_borderWarCell)

function init(self, cellSize, data)
	local ccbiAttrTable = {name="activity/BorderWarCell.ccbi", size=cellSize}
	layer_base_t.init(self, true, ccbiAttrTable)

	self.cellData = data
	self:init_ui()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		self.curAnimNode = tolua.cast(self.proxy_:getNode("borderWarCell_animNode"), "CCNode")

		--动画
		self:playAnim()		
	end
end

function playAnim(self)
	--1
	local nodeSize = self.curAnimNode:getContentSize()
	self.m_animLayer = createObj(ui_borderWarFireAnim, nodeSize, self.cellData)
	self.curAnimNode:addChild(self.m_animLayer.node_)

	self.m_animLayer.node_:setPosition(ccp(nodeSize.width / 2, nodeSize.height / 2))
	self.m_animLayer.node_:setAnchorPoint(ccp(0.5, 0.5))
end

function onNodeCleanup(self)
    layer_base_t.onNodeCleanup(self)
end