--rankCell
--litao
--2014.2.17
---------------------------------------------
module("ui_borderWarRankCell", package.seeall)
baseClass(layer_base_t, ui_borderWarRankCell)

function init(self, cellSize, data)
	local ccbiAttrTable = {name="activity/BorderWarRankCell.ccbi", size=cellSize}
	layer_base_t.init(self, true, ccbiAttrTable)

	self.cellData = data
	self:init_ui()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		---[[
		self.label_rank =  tolua.cast(self.proxy_:getNode("rankCell_rank"), "CCLabelTTF")
		self.label_name = tolua.cast(self.proxy_:getNode("rankCell_name"), "CCLabelTTF")
		self.node_countryIcon = tolua.cast(self.proxy_:getNode("rankCell_countryIcon"), "CCNode")
		self.label_level = tolua.cast(self.proxy_:getNode("rankCell_level"), "CCLabelTTF")
		self.label_score = tolua.cast(self.proxy_:getNode("rankCell_score"), "CCLabelTTF")

		self.label_rank:setString(tostring(self.cellData.rank))
		self.label_name:setString(tostring(self.cellData.nick))
		self.label_level:setString(tostring(self.cellData.level))
		self.label_score:setString(tostring(self.cellData.score))

		---[[
		--0-4 风雷水火土		
		CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile("com_res/Resident.plist")

		local countryIconName
		local curCountryId = tonumber(self.cellData.countryId)
		if curCountryId == 0 then
			countryIconName = tostring("com_icon_country_Wind")
		elseif curCountryId == 1 then
			countryIconName = tostring("com_icon_country_Mine")
		elseif curCountryId == 2 then
			countryIconName = tostring("com_icon_country_Water")
		elseif curCountryId == 3 then
			countryIconName = tostring("com_icon_country_Fire")
		elseif curCountryId == 4 then
			countryIconName = tostring("com_icon_country_Earth")
		end

		if countryIconName == nil then
			return nil
		end

		local pFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(countryIconName)
		if pFrame ~= nil then
			local pIcon = CCSprite:createWithSpriteFrame(pFrame);
			local size = self.node_countryIcon:getContentSize()
			if pIcon ~= nil then
				self.node_countryIcon:addChild(pIcon)
				pIcon:setPosition(ccp(size.width/2, size.height/2))
				pIcon:setAnchorPoint(ccp(0.5, 0.5))
			end
		end
		--]]
		--cclog("cellData = %s", self.cellData)
	end
end

function onNodeCleanup(self)
    layer_base_t.onNodeCleanup(self)
end