--lottery ticket desc_Cell
--litao
--2014.5.23
---------------------------------------------
module("ui_lotteryShowDetailCell", package.seeall)
baseClass(layer_base_t, ui_lotteryShowDetailCell)

function init(self, cellSize, data)
	local ccbiAttrTable = {name="activity/LotteryDetailDescCell.ccbi", size=cellSize}
	layer_base_t.init(self, true, ccbiAttrTable)

	self.cellData = data
	--init	
	self:init_ui()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		--label
		self.label_title = tolua.cast(self.proxy_:getNode("label_title"), "CCLabelTTF")
		self.label_desc = tolua.cast(self.proxy_:getNode("label_desc"), "CCLabelTTF")
		self.spr_title = tolua.cast(self.proxy_:getNode("spr_title"), "CCSprite")

		--
		self:init_ui_ext()
	end
end

function init_ui_ext(self)
	self.label_title:setString(tostring(self.cellData.title))
	self.label_desc:setString(tostring(self.cellData.desc))

	if self.cellData.isTitle then
		self.spr_title:setVisible(true)
		self.label_title:setColor(ccc3(255, 255, 255))
	else
		self.spr_title:setVisible(false)	
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