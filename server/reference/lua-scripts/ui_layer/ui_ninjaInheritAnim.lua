--xckoo
--litao
--2014-6-21
---------------------------------------------
module("ui_ninjaInheritAnim", package.seeall)
baseClass(layer_base_t, ui_ninjaInheritAnim)

function init(self, parentSize)
	local ccbiAttrTable = {name="animations/inherit.ccbi", size=parentSize}
	layer_base_t.init(self, true, ccbiAttrTable)
end

function onNodeCleanup(self)
	--cclog("1111---001:")
	if self.proxy_ then
    	self.proxy_:release()
    end
    layer_base_t.onNodeCleanup(self)
end