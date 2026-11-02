--神卡合成 desc_Cell
--litao
--2014.6.9
---------------------------------------------
module("ui_godCardReadmeCell", package.seeall)
baseClass(layer_base_t, ui_godCardReadmeCell)

function init(self, cellSize, data)
	local ccbiAttrTable = {name="sub_ui/GodCardSyntheticDescCell.ccbi", size=cellSize}
	layer_base_t.init(self, true, ccbiAttrTable)

	self.cellData = data
	--init	
	self:init_ui()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		--label
		self.label_desc = tolua.cast(self.proxy_:getNode("label_text"), "CCLabelTTF")

		--
		self:init_ui_ext()
	end
end

function init_ui_ext(self)
	self.label_desc:setString(tostring(self.cellData.desc))
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