--边界信息Cell
--litao
--2014.2.17
---------------------------------------------
module("ui_borderWarWanderInfoCell", package.seeall)
baseClass(layer_base_t, ui_borderWarWanderInfoCell)

function init(self, cellSize, data)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()
	local ccbiAttrTable = {name="activity/BorderWarWanderInfoCell.ccbi", size=cellSize}
	layer_base_t.init(self, true, ccbiAttrTable)

	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	--时间增量
	self.deltatime = 0
	--游荡时间
	self.time = 0

	self.cellData = data
	self:init_ui()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		---[[
		self.label_name = tolua.cast(self.proxy_:getNode("borderInfoCell_name"), "CCLabelTTF")
		self.label_level = tolua.cast(self.proxy_:getNode("borderInfoCell_level"), "CCLabelTTF")
		self.node_countryIcon = tolua.cast(self.proxy_:getNode("borderInfoCell_countryIcon"), "CCNode")
		self.label_time = tolua.cast(self.proxy_:getNode("borderInfoCell_time"), "CCLabelTTF")

		self.clearBtn = tolua.cast(self.proxy_:getNode("borderInfoCell_clearBtn"), "CCControlButton")

		self.label_name:setString(self.cellData.nick)
		self.label_level:setString(self.cellData.level)

		--if tostring(self.cellData.nick) == self.playerData_.m_name and self.cellData.countryId == self.playerData_.m_countrytype then
		local sub_uid = string.reverse(string.sub(string.reverse(self.cellData.userId), 6))
		--cclog("userId = %s, uid = %s, sub_uid = %s", self.cellData.userId, self.playerData_.m_uid, sub_uid)
		if tostring(sub_uid) == tostring(self.playerData_.m_uid) then	
			self.clearBtn:setVisible(false)
			self.clearBtn:setEnabled(false)
		end

		---[[
		--0-4 风雷水火土
		local countryIconName
		CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile("com_res/Resident.plist")

		if self.cellData.countryId == 0 then
			countryIconName = tostring("com_icon_country_Wind")
		elseif self.cellData.countryId == 1 then
			countryIconName = tostring("com_icon_country_Mine")
		elseif self.cellData.countryId == 2 then
			countryIconName = tostring("com_icon_country_Water")
		elseif self.cellData.countryId == 3 then
			countryIconName = tostring("com_icon_country_Fire")
		elseif self.cellData.countryId == 4 then
			countryIconName = tostring("com_icon_country_Earth")
		end

		local pFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(countryIconName)
		if pFrame ~= nil then
			local pIcon = CCSprite:createWithSpriteFrame(pFrame);
			local size = self.node_countryIcon:getContentSize()
			if pIcon ~= nil then
				self.node_countryIcon:addChild(pIcon)
				--cclog(tostring("node_countryIcon"..self.cellData.countryId))
				pIcon:setPosition(ccp(size.width/2, size.height/2))
				pIcon:setAnchorPoint(ccp(0.5, 0.5))
			end
		end

		self.time = self.cellData.time
		local function updateTimeLabel(fDeltaTime)
			self.deltatime = self.deltatime + fDeltaTime
			if self.deltatime >= 1 then
				local intPart, floatPart = math.modf(self.deltatime)
				if self.time < self.cellData.endTime then
					self.time = self.time + intPart
				else
					self.time = 0
				end
				if self.time >= 0 then
					local timeStr = tools.convertSecToStr(self.time, true)
					self.label_time:setString(timeStr)
					self.deltatime = floatPart
				else
					self.label_lefttime:unscheduleUpdate()
				end
			end
		end

		self.label_time:scheduleUpdateWithPriorityLua(updateTimeLabel, 0)
		self.label_time:setString(tools.convertSecToStr(self.time, true))
	end
end

function onNodeCleanup(self)
    layer_base_t.onNodeCleanup(self)
end