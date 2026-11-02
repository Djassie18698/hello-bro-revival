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

require("ui_layer/ui_consumptionLayer")
require("ui_layer/ui_consumptionCell")

function initConsumptionLayer()
	local view = createObj(ui_consumptionLayer)
	local currentlayer = GetActivityView():GetNodeContent()
	currentlayer:addChild(view.node_)
end

xpcall(initConsumptionLayer, __G__TRACKBACK__)