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

function onNodeCleanup(self)
    layer_base_t.onNodeCleanup(self)
end