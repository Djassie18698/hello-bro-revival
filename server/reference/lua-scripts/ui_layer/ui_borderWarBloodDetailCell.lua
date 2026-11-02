--边界血量详情Cell
--litao
--2014.3.4
---------------------------------------------
module("ui_borderWarBloodDetailCell", package.seeall)
baseClass(layer_base_t, ui_borderWarBloodDetailCell)

function init(self, cellSize, data)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()
	local ccbiAttrTable = {name="activity/BorderWarBloodDetailCell.ccbi", size=cellSize}
	layer_base_t.init(self, true, ccbiAttrTable)

	self.cellData = data
	self:init_ui()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		---[[
		self.label_name = tolua.cast(self.proxy_:getNode("bloodDetailCell_name"), "CCLabelTTF")
		self.label_index = tolua.cast(self.proxy_:getNode("bloodDetailCell_index"), "CCLabelTTF")
		self.node_countryIcon = tolua.cast(self.proxy_:getNode("bloodDetailCell_countryIcon"), "CCNode")
		self.label_time = tolua.cast(self.proxy_:getNode("bloodDetailCell_time"), "CCLabelTTF")
		self.label_desc = tolua.cast(self.proxy_:getNode("bloodDetailCell_desc"), "CCLabelTTF")
		
		self.label_index:setString(tostring(self.cellData.index))
		self.label_time:setString(tostring(self.cellData.time))
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
				pIcon:setPosition(ccp(size.width * 0.5, size.height * 0.5))
				pIcon:setAnchorPoint(ccp(0.5, 0.5))
			end
		end

		self.label_name:setString(self.cellData.nick)
		self.label_desc:setString(self.cellData.desc)

		local timeSize = self.label_time:getContentSize()			
		local nodeSize = self.node_countryIcon:getContentSize()
		local nameSize = self.label_name:getContentSize()

		local ptx,pty = self.label_time:getPosition()
		self.node_countryIcon:setPosition(ccp(ptx + timeSize.width + 25, pty))

		ptx,pty = self.node_countryIcon:getPosition()
		self.label_name:setPosition(ccp(ptx + nodeSize.width * 0.5 + 5, pty))

		ptx,pty = self.label_name:getPosition()
		self.label_desc:setPosition(ccp(ptx + nameSize.width + 5, pty))
		--]]
	end
end

function onNodeCleanup(self)
    layer_base_t.onNodeCleanup(self)
end