--xckoo
--litao
--2014-2-22
---------------------------------------------
module("ui_borderWarFireAnim", package.seeall)
baseClass(layer_base_t, ui_borderWarFireAnim)

function init(self, parentSize, data)
	local ccbiAttrTable = {name="animations/bianjing_001.ccbi", size=parentSize}
	layer_base_t.init(self, true, ccbiAttrTable)

	self.cellData = data

	self:init_ui()
end

function init_ui(self)
	self.curIconSpr = tolua.cast(self.proxy_:getNode("anim_iconNode"), "CCNode")
	self.bg_iconNode = tolua.cast(self.proxy_:getNode("bg_iconNode"), "CCNode")

	--国家图标
	local pathName = "ccbResources/borderWar.plist"
	CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile(pathName)

	local curIconName = "curCountryIcon_"..tostring(self.cellData.countryId)
	local curIcon = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(curIconName)
	if curIcon ~= nil then
		local pIcon = CCSprite:createWithSpriteFrame(curIcon)
		local size = self.curIconSpr:getContentSize()
		if pIcon ~= nil then
			--cclog(tostring("curCountryIcon_"..self.cellData.countryId))				
			self.curIconSpr:addChild(pIcon)
			pIcon:setPosition(ccp(size.width/2, size.height/2))
			pIcon:setAnchorPoint(ccp(0.5, 0.5))
		end
	end
	
	--底座图标
	local playerMgr_ = CPlayerDataMgr:instance()
	local playerData_ = playerMgr_:GetPlayerInfoData()

	local bg_iconName
	if self.cellData.countryId == playerData_.m_countrytype then
		bg_iconName = "borderWarIcon_7"
	else
		bg_iconName = "borderWarIcon_5"
	end
	local bgIcon = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(bg_iconName)
	if bgIcon ~= nil then
		local bgIcon = CCSprite:createWithSpriteFrame(bgIcon)
		local size = self.bg_iconNode:getContentSize()
		if bgIcon ~= nil then
			--cclog(tostring("curCountryIcon_5"..self.cellData.countryId))				
			self.bg_iconNode:addChild(bgIcon)
			bgIcon:setPosition(ccp(size.width/2, size.height/2))
			bgIcon:setAnchorPoint(ccp(0.5, 0.5))
		end
	end
end

function onNodeCleanup(self)
	if self.proxy_ then
    	self.proxy_:release()
    end
    layer_base_t.onNodeCleanup(self)
end