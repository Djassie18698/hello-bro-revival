--7_days_Cell
--litao
--2014.4.11
---------------------------------------------
module("ui_sevenDayCell", package.seeall)
baseClass(layer_base_t, ui_sevenDayCell)

function init(self, cellSize, data)
	local ccbiAttrTable = {name="activity/SevenDayPlanCell.ccbi", size=cellSize}
	layer_base_t.init(self, true, ccbiAttrTable)

	self.cellData = data
	--init	
	self._data = {} 
	self:init_ui()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		--spr
		self["spr_not_done"] = tolua.cast(self.proxy_:getNode("spr_not_done"), "CCSprite")
		self["spr_done"] = tolua.cast(self.proxy_:getNode("spr_done"), "CCSprite")
		--label
		self["label_plan_desc"] = tolua.cast(self.proxy_:getNode("label_plan_desc"), "CCLabelTTF")
		--btn
		self.btn_goto = tolua.cast(self.proxy_:getNode("btn_goto_plan"), "CCControlButton")

		--show info
		self:showInfo()
	end
end

--
function showInfo(self)
	---[[
	local quest_info = DataMgr.GetDataByID("Struct_Sevendays_Quest", tonumber(self.cellData:find("id")[1]))
	local quest_num = quest_info.m_sevendays_quest_num
	self["label_plan_desc"]:setString(tostring(quest_info.m_spec))--..quest_num))

	--
	if tonumber(self.cellData:find("st")[1]) == 1 then
		self["spr_done"]:setVisible(true)
		self["label_plan_desc"]:setColor(ccc3(255,0,0))
		
		self.btn_goto:setEnabled(false)
		self.btn_goto:setVisible(false)
	end
	--]]
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