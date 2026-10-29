--description: 跨服战礼品表的单元格
--company：xckoo
--author：chenchun
---------------------------------------------

module("ui_multiRankGiftItem", package.seeall)
baseClass(layer_base_t, ui_multiRankGiftItem)

function init(self, cellSize, data)
	local ccbiAttrTable = {name="multiserverbattle/multiRankGiftItem.ccbi", size=cellSize}
	layer_base_t.init(self, true, ccbiAttrTable)

	self.gift_data = data
	self:init_ui()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		self.sprite_award_bk =  tolua.cast(self.proxy_:getNode("sprite_award_bk"), "CCSprite")
		self.label_gift_score = tolua.cast(self.proxy_:getNode("label_gift_score"), "CCLabelBMFont")
		local contentSize = self.sprite_award_bk:getContentSize()

		CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile("props/" .. self.gift_data.icon .. ".plist")
    	local pFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(self.gift_data.icon)
    	local pSprite = CCSprite:createWithSpriteFrame(pFrame)
    	self.sprite_award_bk:addChild(pSprite)
    	pSprite:setPosition(contentSize.width * 0.5, contentSize.height * 0.5)
    	pSprite:setAnchorPoint(ccp(0.5, 0.5))
    	self.label_gift_score:setString(self.gift_data.cost)
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