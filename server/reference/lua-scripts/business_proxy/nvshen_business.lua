require("RLRequest")
require("util/protocol")
require("util/tools")
require("util/common")
require("util/localizable")
require("global/cfg")
require("ui_common/node_base_t")
require("ui_common/layer_base_t")
require("LuaXml")
require("CommonDialogView")
require("config/activity_config")
require("config/firstpurchase_config")
require("ui_layer/ui_purchaseTableCell")
require("ui_layer/ui_purchaseLayer")
require("ui_layer/ui_nvshenAnimationLayer")
require("ui_layer/ui_nvshenLayer")
require("ui_layer/ui_nvshenDescLayer")
require("ui_layer/ui_nvshenDescItem")



function initNvShen()
	local activityView = GetActivityView()
	local contentNode = activityView:GetNodeContent()
	local nvshenLayer = createObj(ui_nvshenLayer)
	contentNode:addChild(nvshenLayer.node_)
end

xpcall(initNvShen, __G__TRACKBACK__)