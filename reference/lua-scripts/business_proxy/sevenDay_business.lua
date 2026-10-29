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

require("ui_layer/ui_sevenDayCell")
require("ui_layer/ui_sevenDaySprCell")
require("ui_layer/ui_sevenDayView")

function initSevenDay()
	local activityView = GetActivityView()
	local contentNode = activityView:GetNodeContent()
	local _sevenDayLayer = createObj(ui_sevenDayView)
	contentNode:addChild(_sevenDayLayer.node_)
end

xpcall(initSevenDay, __G__TRACKBACK__)