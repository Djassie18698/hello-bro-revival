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

require("ui_layer/ui_dailyPayLayer")
require("ui_layer/ui_dailyPayCell")

function initDailyPayLayer()
	local view = createObj(ui_dailyPayLayer)
	local currentlayer = GetActivityView():GetNodeContent()
	currentlayer:addChild(view.node_)
end

xpcall(initDailyPayLayer, __G__TRACKBACK__)