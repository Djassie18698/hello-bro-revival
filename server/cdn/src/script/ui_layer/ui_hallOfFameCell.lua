--hall of fame rankCell
--litao
--2014.4.8
---------------------------------------------
module("ui_hallOfFameCell", package.seeall)
baseClass(layer_base_t, ui_hallOfFameCell)

function init(self, cellSize, data)
	local ccbiAttrTable = {name="activity/PlayerStrengthCell.ccbi", size=cellSize}
	layer_base_t.init(self, true, ccbiAttrTable)

	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	--frames
	self.m_rank_frames = {'tower_rank_gold_number_1','tower_rank_gold_number_2','tower_rank_gold_number_3'}
	self.m_bg_frames = {'rank_first','rank_second','rank_third','rank_normal'}

	self.cellData = data

	self:init_ui()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		---[[
		self.spr_rank_icon =  tolua.cast(self.proxy_:getNode("spr_rank_icon"), "CCSprite")
		self.label_rank = tolua.cast(self.proxy_:getNode("label_rank"), "CCLabelBMFont")

		self.label_name = tolua.cast(self.proxy_:getNode("label_name"), "CCLabelTTF")
		self.label_data_type = tolua.cast(self.proxy_:getNode("data_type"), "CCLabelTTF")

		self.spr_merit = tolua.cast(self.proxy_:getNode("sprite_merit"), "CCSprite")
		self.label_merit_lv = tolua.cast(self.proxy_:getNode("merit_lv"), "CCLabelTTF")

		self.spr_lv =tolua.cast(self.proxy_:getNode("sprite_lv"), "CCSprite")
		self.label_lv = tolua.cast(self.proxy_:getNode("label_lv"), "CCLabelBMFont")

		self.label_mydata = tolua.cast(self.proxy_:getNode("label_mydata"), "CCLabelBMFont")

		self.btn_fight = tolua.cast(self.proxy_:getNode("btn_fight"), "CCControlButton")

		self.rank_cell_bg = tolua.cast(self.proxy_:getNode("rank_cell_bg"), "CCSprite")
		--init info
		self:init_ext_ui()
	end
end

function init_ext_ui(self)
	--init
	CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile("ccbResources/player_rank.plist")
	if self.cellData then
		--btn
		local sub_uid = string.reverse(string.sub(string.reverse(self.cellData.id), 6))
		if tostring(sub_uid) == tostring(self.playerData_.m_uid) then
			self.btn_fight:setVisible(false)
			self.btn_fight:setEnabled(false)
		end
		--info
		if self.cellData.rank > 3 then
			self.spr_rank_icon:setVisible(false)
			self.label_rank:setVisible(true)
			self.label_rank:setString(tostring(self.cellData.rank))

			local bg_frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(self.m_bg_frames[4])
			self.rank_cell_bg:setDisplayFrame(bg_frame)
		else
			local frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(self.m_rank_frames[self.cellData.rank])
			self.spr_rank_icon:setDisplayFrame(frame)

			local bg_frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(self.m_bg_frames[self.cellData.rank])
			self.rank_cell_bg:setDisplayFrame(bg_frame)
		end

		self.label_name:setString(tostring(self.cellData.nick))
		if self.cellData.glow == "1" then self:purple_name() end
		if self.cellData.infoType == 3 then
			self.spr_merit:setVisible(true)
			self.label_merit_lv:setVisible(true)

			local levelmedal = DataMgr.GetDataByID("Struct_Playemedal", tonumber(self.cellData.min_score))
			local frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(levelmedal.m_merit_icon)
			self.spr_merit:setDisplayFrame(frame)

			self.spr_lv:setVisible(false)
			self.label_lv:setVisible(false)
			self.label_data_type:setString(localizable.ui_hall_battle_honour)

			self.label_merit_lv:setString(tostring(levelmedal.m_medalname))--self.cellData.min_score.."阶"))
			self.label_mydata:setString(tostring(self.cellData.max_score))
		elseif self.cellData.infoType == 2 then
			self.label_data_type:setString(localizable.ui_hall_defense)
			self.label_lv:setString(tostring(self.cellData.level))
			self.label_mydata:setString(tostring(self.cellData.min_score.."-"..self.cellData.max_score))
		else
			self.label_data_type:setString(localizable.ui_hall_attack)
			self.label_lv:setString(tostring(self.cellData.level))
			self.label_mydata:setString(tostring(self.cellData.min_score.."-"..self.cellData.max_score))
		end
	end
end

-- Purple name (Ninja Online Reborn server, 28.0.42): the server sends glow="1" for a few chosen accounts.
-- A light purple glow that pulses (two rings of 8 copies of the name, 5 and 3 px around), a thin dark purple outline
-- (8 copies 1.5 px around) and the name itself shifting between two purples. The copies sit next to the label, the label goes on top.
function purple_name(self)
	local label = self.label_name
	local parent = label and label:getParent()
	if parent == nil then return end
	local text, font, size = label:getString(), label:getFontName(), label:getFontSize()
	local x, y, z = label:getPositionX(), label:getPositionY(), label:getZOrder()
	local around = {{1, 0}, {-1, 0}, {0, 1}, {0, -1}, {0.7, 0.7}, {-0.7, 0.7}, {0.7, -0.7}, {-0.7, -0.7}}
	local function copy(dx, dy, r, g, b, opacity)
		local c = CCLabelTTF:create(text, font, size)
		c:setAnchorPoint(label:getAnchorPoint())
		c:setPosition(ccp(x + dx, y + dy))
		c:setColor(ccc3(r, g, b))
		c:setOpacity(opacity)
		parent:addChild(c, z)
		return c
	end
	for _, ring in ipairs({{5, 215, 140, 255, 40, 170}, {3, 245, 210, 255, 70, 230}}) do
		for _, d in ipairs(around) do
			local halo = copy(d[1] * ring[1], d[2] * ring[1], ring[2], ring[3], ring[4], ring[6])
			halo:runAction(CCRepeatForever:create(CCSequence:createWithTwoActions(CCFadeTo:create(0.8, ring[5]), CCFadeTo:create(0.8, ring[6]))))
		end
	end
	for _, d in ipairs(around) do
		copy(d[1] * 1.5, d[2] * 1.5, 50, 0, 90, 255)
	end
	parent:reorderChild(label, z + 1)
	label:setColor(ccc3(215, 140, 255))
	label:runAction(CCRepeatForever:create(CCSequence:createWithTwoActions(CCTintTo:create(0.8, 165, 60, 255), CCTintTo:create(0.8, 215, 140, 255))))
end

function onNodeCleanup(self)
    layer_base_t.onNodeCleanup(self)
end