--descriptioin:刮刮乐获奖动画（重写）
--company: xckoo
--author: chenchun
--date: 2013-12-17
---------------------------------------------
module("ui_scratchGoldAnimation", package.seeall)
baseClass(layer_base_t, ui_scratchGoldAnimation)

function init(self, goldData)
	self.contentSize_ = CCDirector:sharedDirector():getWinSize()
	local ccbiAttrTable = {name="animations/guaguale.ccbi", size=CCSize(768,self.contentSize_.height)}
	layer_base_t.init(self, true, ccbiAttrTable)
	self.goldData = goldData
	self:init_ui()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		tolua.cast(self.proxy_:getNode("label_gold_num" ), "CCLabelTTF"):setString(tostring(self.goldData))
	end
end

function onNodeCleanup(self)
	--cclog("1111---001:ui_scratchGoldAnimation")
	if self.proxy_ then
    	self.proxy_:release()
    end
    layer_base_t.onNodeCleanup(self)
end