--7_days_Cell
--litao
--2014.4.11
---------------------------------------------
module("ui_sevenDayCell", package.seeall)
baseClass(layer_base_t, ui_sevenDayCell)

-- English texts for the 7-day goals (the game's own table only has Thai). Revival server hot update.
SEVEN_DAY_EN = {
	[1] = "Reach player level 70",
	[2] = "Get the highest ninja in your team to level 50",
	[3] = "Become VIP 1",
	[4] = "Have a ninja with strengthen level 5",
	[5] = "Clear every stage of Shinobi Exams",
	[6] = "Reach the ninja rank Middle Genin",
	[7] = "Earn 15 stars in total in Battles",
	[8] = "Reach arena rank 800 or better",
	[9] = "Reach a team attack of 8,000",
	[10] = "Reach a team defense of 10,000",
	[11] = "Own a purple card reincarnated once",
	[12] = "Hand in 20 national treasures in total",
	[13] = "Become VIP 2",
	[14] = "Become VIP 3",
	[15] = "Clear every stage of Land of Waves",
	[16] = "Reach a team attack of 10,000",
	[17] = "Reach a team attack of 15,000",
	[18] = "Earn 21 stars in total in Battles",
	[19] = "Have ninjas at level 50",
	[20] = "Have ninjas reincarnated once",
	[21] = "Have ninjas reincarnated twice",
	[22] = "Have a ninja reincarnated three times",
	[23] = "Earn 28 stars in total in Battles",
}

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
	local qid = tonumber(self.cellData:find("id")[1])
	self["label_plan_desc"]:setString(SEVEN_DAY_EN[qid] or tostring(quest_info.m_spec))--..quest_num))

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