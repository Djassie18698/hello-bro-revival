--闯关扫荡_Cell
--litao
--2014.5.6
---------------------------------------------
module("ui_towerSweepCell", package.seeall)
baseClass(layer_base_t, ui_towerSweepCell)

function init(self, cellSize, data)
	local ccbiAttrTable = {name="sub_ui/TowerSweepCell.ccbi", size=cellSize}
	layer_base_t.init(self, true, ccbiAttrTable)

	self.cellData = data
	--init	
	self._data = {} 
	self:init_ui()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		--spr/node/lebel
		for i=1,4 do
			self["spr_level_"..i] = tolua.cast(self.proxy_:getNode("spr_level_"..i), "CCSprite")
			self["spr_select_"..i] = tolua.cast(self.proxy_:getNode("spr_select_"..i), "CCSprite")
			self["spr_select_frame_"..i] = tolua.cast(self.proxy_:getNode("spr_select_frame_"..i), "CCSprite")
			self["label_level_name_"..i] = tolua.cast(self.proxy_:getNode("label_level_name_"..i), "CCLabelBMFont")
			self["node_content_"..i] = tolua.cast(self.proxy_:getNode("node_content_"..i), "CCNode")
			self["spr_pass_"..i] = tolua.cast(self.proxy_:getNode("spr_pass_"..i), "CCSprite")
		end

		--init info
		self:init_ui_ext()
	end
end

--
function init_ui_ext(self)
	CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile("ccbResources/tower_ui.plist")
	--init icon
	for i=1, 4 do
		if i > #self.cellData then
			self["node_content_"..i]:setVisible(false)
		else
			self["label_level_name_"..i]:setString(self.cellData[i].name)
			self["spr_select_"..i]:setVisible(self.cellData[i].bSelected)

			--level icon
			local id_towerfloor = tonumber((self.cellData[i].id - 1) * 7 + 7)
			local floorinfo = DataMgr.GetDataByID("Struct_Towerfloor", id_towerfloor)
			if floorinfo then
				local boosicon = rl_get_iconsprite(1, 1, E_FRAMETYPE_SMALL, floorinfo.m_npc1)
				if nil ~= boosicon then
					self["spr_level_"..i]:addChild(boosicon)
					local size = self["spr_level_"..i]:getContentSize()
					boosicon:setPosition(ccp(size.width * 0.5, size.height * 0.5))
					boosicon:setAnchorPoint(ccp(0.5, 0.5))
					boosicon:setTag(100)

					if 0 == self.cellData[i].select_status then
						local pProgram = CCShaderCache:sharedShaderCache():programForKey("greysprite")
						boosicon:setShaderProgram(pProgram)
						self["spr_pass_"..i]:setVisible(false)
					elseif 1 == self.cellData[i].select_status then
						self["spr_pass_"..i]:setVisible(true)
					else
						self["spr_pass_"..i]:setVisible(false)
					end
				end
			end
		end
	end
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