--description: 玩家排名页面的礼品表的单元格
--company：xckoo
--author：chenchun
---------------------------------------------

module("ui_levelRankGiftTableCell", package.seeall)
baseClass(layer_base_t, ui_levelRankGiftTableCell)

function init(self, cellSize, data)
	local ccbiAttrTable = {name="activity/LevelRankGiftItem.ccbi", size=cellSize}
	layer_base_t.init(self, true, ccbiAttrTable)

	self.gift_data = data
	self:init_ui()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		self.sprite_award_bk =  tolua.cast(self.proxy_:getNode("sprite_award_bk"), "CCSprite")
		self.label_award = tolua.cast(self.proxy_:getNode("label_award"), "CCLabelTTF")
		local contentSize = self.sprite_award_bk:getContentSize()
		local pathName = "props/"..self.gift_data.icon ..".plist"
		local itemInfo = ItemDataInfo:new()
		CGameObjElement:GetItemInfoByDropid(tonumber(self.gift_data.dropid), itemInfo)
		local pIcon, iconFrame = rl_get_iconsprite(itemInfo.mainType, itemInfo.subType, E_FRAMETYPE_SMALL, itemInfo.itemId)
		self.sprite_award_bk:setDisplayFrame(iconFrame)
		--local pathName = "props/".."props_082.plist"
		CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile(pathName)
		local sprite_icon = CCSprite:createWithSpriteFrameName(self.gift_data.icon)
		--local sprite_icon = CCSprite:createWithSpriteFrameName("props_082")
		sprite_icon:setPosition(contentSize.width / 2, contentSize.height / 2)
		sprite_icon:setAnchorPoint(ccp(0.5, 0.5))
		self.sprite_award_bk:addChild(sprite_icon)
		if self.gift_data.beginrank == self.gift_data.endrank then
			self.label_award:setString(string.format(localizable.ui_rank_label, tostring(self.gift_data.beginrank)))
		else
			self.label_award:setString(string.format(localizable.ui_rank_label, tostring(self.gift_data.beginrank) .. "-" ..tostring(self.gift_data.endrank)))
		end
	end
end

function onNodeCleanup(self)
    --cclog("onNodeCleanup")
    --[[
    if self.node_:retainCount() == 1 then
        self.proxy_:release()
    end
    ]]
    layer_base_t.onNodeCleanup(self)
end