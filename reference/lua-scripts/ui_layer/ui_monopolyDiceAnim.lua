--xckoo
--litao
--2014-1-21
---------------------------------------------
module("ui_monopolyDiceAnim", package.seeall)
baseClass(layer_base_t, ui_monopolyDiceAnim)

function init(self, parentSize)
	local ccbiAttrTable = {name="animations/dafuweng.ccbi", size=parentSize}
	layer_base_t.init(self, true, ccbiAttrTable)
end


function onNodeCleanup(self)
	--cclog("1111---001:ui_monopolyDiceAnim")
	if self.proxy_ then
    	self.proxy_:release()
    end
    layer_base_t.onNodeCleanup(self)
end