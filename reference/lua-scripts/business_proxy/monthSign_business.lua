require("RLRequest")
require("util/protocol")
require("util/tools")
require("util/common")
require("util/localizable")
require("global/cfg")
require("ui_common/node_base_t")
require("ui_common/layer_base_t")
require("LuaXml")
require("config/activity_config")
require("config/firstpurchase_config")

require("ui_layer/ui_monthSign")

function initMonthSign()
	local activityView = GetActivityView()
	local contentNode = activityView:GetNodeContent()
	local monthSignLayer = createObj(ui_monthSign)
	contentNode:addChild(monthSignLayer.node_)
end

xpcall(initMonthSign, __G__TRACKBACK__)