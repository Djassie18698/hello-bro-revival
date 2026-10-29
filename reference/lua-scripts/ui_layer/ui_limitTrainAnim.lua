--xckoo
--litao
--2014-7-17
---------------------------------------------
module("ui_limitTrainAnim", package.seeall)
baseClass(layer_base_t, ui_limitTrainAnim)

function init(self, parentSize, index)
	local ccbiAttrTable = {}
	if index == 1 then
		ccbiAttrTable = {name="animations/limitTrainAnim_bamen_01.ccbi", size=parentSize}
	elseif index == 2 then
		ccbiAttrTable = {name="animations/limitTrainAnim_bamen_02.ccbi", size=parentSize}
	elseif index == 3 then
		ccbiAttrTable = {name="animations/limitTrainAnim_bamen_03.ccbi", size=parentSize}
	elseif index == 4 then
		ccbiAttrTable = {name="animations/att_muzhuang.ccbi", size=parentSize}
	end
	layer_base_t.init(self, true, ccbiAttrTable)
end

function onNodeCleanup(self)
	--cclog("1111---001:")
	if self.proxy_ then
    	self.proxy_:release()
    end
    layer_base_t.onNodeCleanup(self)
end