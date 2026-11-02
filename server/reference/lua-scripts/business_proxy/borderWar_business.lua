require("RLRequest")
require("util/protocol")
require("util/tools")
require("util/common")
require("global/cfg")
require("util/localizable")
require("ui_common/node_base_t")
require("ui_common/layer_base_t")
--require("RLRequest")
require("LuaXml")
require("CommonDialogView")

require("ui_layer/ui_borderWarLayer")
require("ui_layer/ui_borderWarCell")

require("ui_layer/ui_borderWarRankLayer")
require("ui_layer/ui_borderWarRankCell")

require("ui_layer/ui_borderWarProvokeInfoLayer")
require("ui_layer/ui_borderWarProvokeInfoCell")

require ("ui_layer/ui_borderWarWanderInfoLayer")
require ("ui_layer/ui_borderWarWanderInfoCell")

require("ui_layer/ui_borderWarRewardLayer")
require("ui_layer/ui_borderWarStateRewardLayer")
require("ui_layer/ui_borderWarStateRewardCell")

require("ui_layer/ui_borderWarShowTip")
require("ui_layer/ui_borderWarShowAttackTip")
require("ui_layer/ui_borderWarFireAnim")
require("ui_layer/ui_borderWarShowDetail")
require("ui_layer/ui_borderWarAttackLayer")
require("ui_layer/ui_borderWarCommonRewardDlg")
require("ui_layer/ui_borderWarChangeAttackDlg")
require("ui_layer/ui_borderWarBloodDetailLayer")
require("ui_layer/ui_borderWarBloodDetailCell")

function initBorderWarLayer()
	local borderWarLayer = createObj(ui_borderWarLayer)
	borderWarLayer.node_:setTag(1002)
	local currentlayer = tolua.cast(GetMainMenu():GetCurrentSubMenu(), "CCLayer")
	currentlayer:addChild(borderWarLayer.node_)
end