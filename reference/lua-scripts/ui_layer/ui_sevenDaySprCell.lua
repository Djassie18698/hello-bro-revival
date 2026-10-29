--7_days_spr_Cell
--litao
--2014.4.11
---------------------------------------------
module("ui_sevenDaySprCell", package.seeall)
baseClass(layer_base_t, ui_sevenDaySprCell)

function init(self, cellSize, data)
	local ccbiAttrTable = {name="activity/SevenDayPlanSprCell.ccbi", size=cellSize}
	layer_base_t.init(self, true, ccbiAttrTable)

	self.login_days = CPlayerDataMgr:instance():GetTotalLoginDay()
	self.cellData = data
	--
	self.m_pic_day_frames = {}
	--init	
	self._data = {} 
	self:init_ui()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		--spr
		self.spr_pic_day = tolua.cast(self.proxy_:getNode("spr_pic_day"), "CCSprite")
		self.spr_label_day = tolua.cast(self.proxy_:getNode("spr_label_day"), "CCSprite")
		self.spr_can_get = tolua.cast(self.proxy_:getNode("spr_can_get"), "CCSprite")
		self.cell_spr_got = tolua.cast(self.proxy_:getNode("cell_spr_got"), "CCSprite")
		self.spr_gray_frame = tolua.cast(self.proxy_:getNode("spr_gray_frame"), "CCScale9Sprite")
		self.spr_cur_frame = tolua.cast(self.proxy_:getNode("spr_cur_frame"), "CCScale9Sprite")
		self.spr_spr_locked = tolua.cast(self.proxy_:getNode("spr_spr_locked"), "CCSprite")
		
		if self.cellData._reward == 0 then
			if self:retCurDayPlanIsFinished() == true then
				self.spr_can_get:setVisible(true)
			else
				self.spr_can_get:setVisible(false)
			end
		elseif self.cellData._reward == 1 then
			self.spr_can_get:setVisible(false)
			if self.cell_spr_got ~= nil then
				self.cell_spr_got:setVisible(true)
			end
		end

		--show info
		self:showInfo()

		--奖励已经过期_litao_2014.7.15
		if self.login_days > self.cellData._index + 1 then
			self.spr_can_get:setVisible(false)
			self.spr_gray_frame:setVisible(true)
		end	
	end
end

function retCurDayPlanIsFinished(self)
	--
	for i=1,#self.cellData._planData do
		local _data = self.cellData._planData[i]
		if tonumber(_data:find("st")[1]) == 0 then
			return false
		end
	end

	return true
end

--
function showInfo(self)
	---[[
	self.login_days = CPlayerDataMgr:instance():GetTotalLoginDay()
	if self.login_days >= self.cellData._index then
		self.spr_gray_frame:setVisible(false)
		self.spr_spr_locked:setVisible(false)
	end
	--]]

	--[[
	if self.cellData._focus then
		self.spr_gray_frame:setVisible(false)
	else
		self.spr_gray_frame:setVisible(true)
	end
	--]]

	self.spr_cur_frame:setVisible(self.cellData._focus)

	---[[
	local frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(tostring("seven_day_pic_"..self.cellData._index))
	if frame ~= nil then
		self.spr_pic_day:setDisplayFrame(frame)
	end

	local day_frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(tostring("seven_day_"..self.cellData._index))
	if day_frame ~= nil then
		self.spr_label_day:setDisplayFrame(day_frame)
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