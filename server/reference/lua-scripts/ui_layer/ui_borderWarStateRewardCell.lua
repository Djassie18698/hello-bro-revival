--边界奖励Cell
--litao
--2014.3.4
---------------------------------------------
module("ui_borderWarStateRewardCell", package.seeall)
baseClass(layer_base_t, ui_borderWarStateRewardCell)

function init(self, cellSize, data)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()
	local ccbiAttrTable = {name="activity/BorderWarStateRewardCell.ccbi", size=cellSize}
	layer_base_t.init(self, true, ccbiAttrTable)

	self.cellData = data
	self:init_ui()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		---[[
		self["stateReward_nodeIcon"] = tolua.cast(self.proxy_:getNode("stateReward_nodeIcon"), "CCNode")
		self["stateReward_expLabel"] = tolua.cast(self.proxy_:getNode("stateReward_expLabel"), "CCLabelTTF")
		self["stateReward_scoreLabel"] = tolua.cast(self.proxy_:getNode("stateReward_scoreLabel"), "CCLabelTTF")		
		self["stateReward_label"] = tolua.cast(self.proxy_:getNode("stateReward_label"), "CCLabelTTF")
		---[[
		--init info				
		self["stateReward_label"]:setString(self.cellData.label)			
		self["stateReward_expLabel"]:setString(tostring(self.cellData.exp))
		self["stateReward_scoreLabel"]:setString(tostring(self.cellData.merit))

		CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile("com_res/Resident.plist")
		---[[
		--0-4 风雷水火土
		local countryIconId = tonumber(self.cellData.countryId)
		local countryIconName
		if countryIconId == 0 then
			countryIconName = tostring("com_icon_country_Wind")
		elseif countryIconId == 1 then
			countryIconName = tostring("com_icon_country_Mine")
		elseif countryIconId == 2 then
			countryIconName = tostring("com_icon_country_Water")
		elseif countryIconId == 3 then
			countryIconName = tostring("com_icon_country_Fire")
		elseif countryIconId == 4 then
			countryIconName = tostring("com_icon_country_Earth")
		end

		local pFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(countryIconName)
		if pFrame ~= nil then
			local pIcon = CCSprite:createWithSpriteFrame(pFrame)
			local size = self["stateReward_nodeIcon"]:getContentSize()
			if pIcon ~= nil then
				self["stateReward_nodeIcon"]:addChild(pIcon)
				pIcon:setPosition(ccp(size.width/2, size.height/2))
				pIcon:setAnchorPoint(ccp(0.5, 0.5))
			end
		end
	end
end

function onNodeCleanup(self)
    layer_base_t.onNodeCleanup(self)
end