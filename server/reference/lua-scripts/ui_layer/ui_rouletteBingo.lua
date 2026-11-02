--descriptioin:大转盘中奖奖品的动画
--company: xckoo
--author: chenchun
--date: 2013-1-8
---------------------------------------------
module("ui_rouletteBingo", package.seeall)
baseClass(layer_base_t, ui_rouletteBingo)

function init(self, parentSize)
	local ccbiAttrTable = {name="animations/RouletteBingo.ccbi", size=parentSize}
	layer_base_t.init(self, true, ccbiAttrTable)
end


function onNodeCleanup(self)
	--cclog("1111---001:ui_scratchGoldAnimation")
	if self.proxy_ then
    	self.proxy_:release()
    end
    layer_base_t.onNodeCleanup(self)
end