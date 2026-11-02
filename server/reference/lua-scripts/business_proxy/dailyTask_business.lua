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

require("config/firstpurchase_config")
require("ui_layer/ui_purchaseLayer")
require("ui_layer/ui_purchaseTableCell")

require("ui_layer/ui_dailyTaskCell")
require("ui_layer/ui_dailyTaskAwardCell")
require("ui_layer/ui_dailyTaskLayer")
require("ui_layer/ui_dailyRewardLayer")

function initDailyTask()
	local view = createObj(ui_dailyTaskLayer)
	local currentlayer = GetMainMenu():GetModelLayer()
	currentlayer:addChild(view.node_)
end

xpcall(initDailyTask, __G__TRACKBACK__)