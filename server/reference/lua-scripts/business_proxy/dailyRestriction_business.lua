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

require("ui_layer/ui_dailyRestrictionLayer")
require("ui_layer/ui_dailyRestrictionCell")

function initDailyRestrictionLayer()
	local view = createObj(ui_dailyRestrictionLayer)
	local currentlayer = GetActivityView():GetNodeContent()
	currentlayer:addChild(view.node_)
end

xpcall(initDailyRestrictionLayer, __G__TRACKBACK__)