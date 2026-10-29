--套装Cell
--litao
--2014.2.15
---------------------------------------------
module("ui_suitCell", package.seeall)
baseClass(layer_base_t, ui_suitCell)

function init(self, cellSize, data)
	self.cellData = data

	local ccbiAttrTable = {name="sub_ui/SuitEffectCell.ccbi", size=cellSize}
	layer_base_t.init(self, true, ccbiAttrTable)

	--init	
	self.cellSuitInfo = {}
	self.cellSuitInfo = self.cellData.data
	self:init_ui()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		--label
		self["suitEffect_cell_title"] = tolua.cast(self.proxy_:getNode("suitEffect_cell_title"), "CCLabelTTF")
		self["suitEffect_cell_attack"] = tolua.cast(self.proxy_:getNode("suitEffect_cell_attack"), "CCLabelTTF")
		self["suitEffect_cell_def"] = tolua.cast(self.proxy_:getNode("suitEffect_cell_def"), "CCLabelTTF")
		self["suitEffect_cell_chakra"] = tolua.cast(self.proxy_:getNode("suitEffect_cell_chakra"), "CCLabelTTF")
		self["suitEffect_cell_attack_per"] = tolua.cast(self.proxy_:getNode("suitEffect_cell_attack_per"), "CCLabelTTF")
		self["suitEffect_cell_def_per"] = tolua.cast(self.proxy_:getNode("suitEffect_cell_def_per"), "CCLabelTTF")
		self["suitEffect_cell_chakra_per"] = tolua.cast(self.proxy_:getNode("suitEffect_cell_chakra_per"), "CCLabelTTF")		

		--label pre desc
		self["suitEffect_cell_attack_desc"] = tolua.cast(self.proxy_:getNode("suitEffect_cell_attack_desc"), "CCLabelTTF")
		self["suitEffect_cell_def_desc"] = tolua.cast(self.proxy_:getNode("suitEffect_cell_def_desc"), "CCLabelTTF")
		self["suitEffect_cell_chakra_desc"] = tolua.cast(self.proxy_:getNode("suitEffect_cell_chakra_desc"), "CCLabelTTF")
		self["suitEffect_cell_attack_per_desc"] = tolua.cast(self.proxy_:getNode("suitEffect_cell_attack_per_desc"), "CCLabelTTF")
		self["suitEffect_cell_def_per_desc"] = tolua.cast(self.proxy_:getNode("suitEffect_cell_def_per_desc"), "CCLabelTTF")
		self["suitEffect_cell_chakra_per_desc"] = tolua.cast(self.proxy_:getNode("suitEffect_cell_chakra_per_desc"), "CCLabelTTF")

		--show info
		--if self.cellData.id_suit > 0 then			
			--self:getSuitInfo()
			self:init_ui_ext()
			if self.cellData.isActivate == true then
				--self:setLabelColor(self.cellData.c3_color)
				self:setLabelColor(ccc3(255,0,0))
			end
		--end
	end
end

function init_ui_ext(self)
	self["suitEffect_cell_title"]:setString(self.cellSuitInfo.title)
	self["suitEffect_cell_attack"]:setString(self.cellSuitInfo.attack_num)
	self["suitEffect_cell_def"]:setString(self.cellSuitInfo.def_num)
	self["suitEffect_cell_chakra"]:setString(self.cellSuitInfo.chakra_num)
	self["suitEffect_cell_attack_per"]:setString(self.cellSuitInfo.attack_per)
	self["suitEffect_cell_def_per"]:setString(self.cellSuitInfo.def_per)
	self["suitEffect_cell_chakra_per"]:setString(self.cellSuitInfo.chakra_per)
end

function setLabelColor(self, color)
	self["suitEffect_cell_title"]:setColor(color)
	--self:setLabelWithStroke(color)
	self["suitEffect_cell_attack"]:setColor(color)
	self["suitEffect_cell_def"]:setColor(color)
	self["suitEffect_cell_chakra"]:setColor(color)
	self["suitEffect_cell_attack_per"]:setColor(color)
	self["suitEffect_cell_def_per"]:setColor(color)
	self["suitEffect_cell_chakra_per"]:setColor(color)

	self["suitEffect_cell_attack_desc"]:setColor(color)
	self["suitEffect_cell_def_desc"]:setColor(color)
	self["suitEffect_cell_chakra_desc"]:setColor(color)
	self["suitEffect_cell_attack_per_desc"]:setColor(color)
	self["suitEffect_cell_def_per_desc"]:setColor(color)
	self["suitEffect_cell_chakra_per_desc"]:setColor(color)
end

function setLabelWithStroke(self, color)
	self["suitEffect_cell_title"]:setVisible(false)
	local st = CCLabelTTFWithStroke:create(self["suitEffect_cell_title"]:getString(), "Arial-BoldMT", self["suitEffect_cell_title"]:getFontSize(), color, ccc3(0,0,0), CCSize(0,0), 2)
	st:setColor(color)
	st:setAnchorPoint(self["suitEffect_cell_title"]:getAnchorPoint())
	st:setPosition(self["suitEffect_cell_title"]:getPosition())
	self.node_:addChild(st, 100)
end

--获取套装数据
function getSuitInfo(self)
	---[[
	--颜色套info
	local colorSuitData = DataMgr.GetDataByID("Struct_Suit_Info", tonumber(self.cellData.id_suit))
	--3-5 绿蓝紫
	self.cellSuitInfo.title = tostring(colorSuitData.m_suit_desc)
	self.cellSuitInfo.attack_num = tonumber(colorSuitData.m_suit_attack_num)
	self.cellSuitInfo.attack_per = tostring(math.ceil(tonumber(colorSuitData.m_suit_attack_percent * 100)).."%")
	self.cellSuitInfo.def_num = tonumber(colorSuitData.m_suit_defense_num)
	self.cellSuitInfo.def_per = tostring(math.ceil(tonumber(colorSuitData.m_suit_defense_percent * 100)).."%")
	self.cellSuitInfo.chakra_num = tonumber(colorSuitData.m_suit_chacra_num)
	self.cellSuitInfo.chakra_per = tostring(math.ceil(tonumber(colorSuitData.m_suit_chacra_percent * 100)).."%")
	--]]
end

function onNodeCleanup(self)
	if self.proxy_ then
    	self.proxy_:release()
    end
    layer_base_t.onNodeCleanup(self)
end