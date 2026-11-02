--descriptioin:女神献花动画（重写）
--company: xckoo
--author: chenchun
--date: 2013-1-20
---------------------------------------------
module("ui_nvshenAnimationLayer", package.seeall)
baseClass(layer_base_t, ui_nvshenAnimationLayer)

function init(self, animationName)
	self.contentSize_ = CCDirector:sharedDirector():getWinSize()
	local ccbiAttrTable = {name="animations/" .. animationName .. ".ccbi", size=CCSize(self.contentSize_.width, self.contentSize_.height)}
	layer_base_t.init(self, true, ccbiAttrTable)
	--self.goldData = goldData
	local bglayer = CCLayerColor:create(ccc4(0, 0, 0, 175), self.contentSize_.width, self.contentSize_.height)
	local node = self.node_
	node:setAnchorPoint(ccp(0.5, 0.5))
	node:setPosition(self.contentSize_.width / 2, self.contentSize_.height / 2)
	node:ignoreAnchorPointForPosition(false)
	bglayer:addChild(node)
	self.node_ = bglayer
	self:init_ui()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		--tolua.cast(self.proxy_:getNode("label_gold_num" ), "CCLabelTTF"):setString(tostring(self.goldData))
	end
end

function onNodeCleanup(self)
	--cclog("1111---001:ui_scratchGoldAnimation")
	if self.proxy_ then
    	self.proxy_:release()
    end
    layer_base_t.onNodeCleanup(self)
end