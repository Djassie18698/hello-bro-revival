--奖励cell_Cell
--litao
--2014.5.8
---------------------------------------------
module("ui_rewardDlgCell_cell", package.seeall)
baseClass(layer_base_t, ui_rewardDlgCell_cell)

function init(self, cellSize, data)
	local ccbiAttrTable = {name="sub_ui/SweepRewardDlgCell_cell.ccbi", size=cellSize}
	layer_base_t.init(self, true, ccbiAttrTable)

	self.cellData = data
	--init	

	self:init_ui()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		--spr
		self.spr_item = tolua.cast(self.proxy_:getNode("spr_item"), "CCSprite")
		--label
		self.label_item = tolua.cast(self.proxy_:getNode("label_item"), "CCLabelTTF")
		--node
		self.node_item = tolua.cast(self.proxy_:getNode("node_item"), "CCNode")

		--init info
		self:init_ui_ext()
	end
end

--
function init_ui_ext(self)
	--init icon && frame
	local _t_card = {}
	--if 2 == self.cellData.maintype then
	--	_t_prop.pIcon, _t_prop.pFrame, _t_prop.objname = rl_get_iconsprite(self.cellData.maintype, self.cellData.subtype, E_FRAMETYPE_SMALL, self.cellData.id)
	--else
		_t_card.pIcon, _t_card.pFrame, _t_card.quality, _t_card.objname = rl_get_iconsprite(self.cellData.maintype, self.cellData.subtype, E_FRAMETYPE_SMALL, self.cellData.id)
	--end
	if nil ~= _t_card.pFrame then
		self.spr_item:setDisplayFrame(_t_card.pFrame)
	end

	if nil ~= _t_card.pIcon then
		---[[
		self.spr_item:addChild(_t_card.pIcon)
		--cclog("%s _icon = %s", _t_card.objname, _t_card.pIcon)

		local size = self.spr_item:getContentSize()
		_t_card.pIcon:setPosition(ccp(size.width * 0.5, size.height * 0.5))
		_t_card.pIcon:setAnchorPoint(ccp(0.5, 0.5))
		--]]
	end

	local _size = self.node_:getContentSize()
	self.label_item:setDimensions(CCSize(_size.width,0))
	self.label_item:setString(tostring(_t_card.objname.."*"..self.cellData.num))
end

function init_binding_event(self)
	--
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