--descriptioin:月签动画
--company: xckoo
--author: liyongk
--date: 2015-10-14
---------------------------------------------
module("ui_monthSignAnim", package.seeall)
baseClass(layer_base_t, ui_monthSignAnim)

function init(self)
	self.contentSize_ = CCDirector:sharedDirector():getWinSize()
	local ccbiAttrTable = {name="animations/month_sign_click.ccbi", size=CCSize(150,150)}
	layer_base_t.init(self, true, ccbiAttrTable)

end

function init_ui(self)
	if self.proxy_ ~= nil then
		--tolua.cast(self.proxy_:getNode("label_gold_num" ), "CCLabelTTF"):setString(tostring(self.goldData))
	end
end

function onNodeCleanup(self)
	--cclog("1111---001:ui_scratchGoldAnimation")
	if self.proxy_ then
    	--self.proxy_:release()
    end
   -- layer_base_t.onNodeCleanup(self)
end