--八门遁甲Cell
--litao
--2014.7.18
---------------------------------------------
module("ui_limitTrainCell", package.seeall)
baseClass(layer_base_t, ui_limitTrainCell)

function init(self, cellSize, data)
	local ccbiAttrTable = {name="sub_ui/LimitTrainCell.ccbi", size=cellSize}
	layer_base_t.init(self, true, ccbiAttrTable)

	self.cellData = data
	--init
	self:init_ui()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		--lebel
		self.label_add_desc = tolua.cast(self.proxy_:getNode("label_add_desc"), "CCLabelTTF")

		--init info
		self:init_ui_ext()
	end
end

function init_ui_ext(self)
	local label_add_type = nil
	if tonumber(self.cellData.type) == 1 then
		label_add_type = localizable.ui_limitTrain_att.."+"..tostring(self.cellData.add_num)
	elseif tonumber(self.cellData.type) == 2 then
		label_add_type = localizable.ui_limitTrain_def.."+"..tostring(self.cellData.add_num)
	elseif tonumber(self.cellData.type) == 3 then
		label_add_type = localizable.ui_limitTrain_chakra.."+"..tostring(self.cellData.add_num)
	elseif tonumber(self.cellData.type) == 4 then
		label_add_type = localizable.ui_limitTrain_ninjasu.."+"..tostring(self.cellData.add_num/10).."%"
	elseif tonumber(self.cellData.type) == 5 then
		label_add_type = localizable.ui_limitTrain_att.."+"..tostring(self.cellData.add_num/10).."%"
	elseif tonumber(self.cellData.type) == 6 then
		label_add_type = localizable.ui_limitTrain_def.."+"..tostring(self.cellData.add_num/10).."%"
	elseif tonumber(self.cellData.type) == 7 then
		label_add_type = localizable.ui_limitTrain_chakra.."+"..tostring(self.cellData.add_num/10).."%"
	end
	self.label_add_desc:setString(label_add_type)
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