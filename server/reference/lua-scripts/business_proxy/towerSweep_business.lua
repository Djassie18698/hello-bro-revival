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

require("ui_layer/ui_towerSweepLayer")
require("ui_layer/ui_towerSweepCell")
require("ui_layer/ui_rewardDlgLayer")
require("ui_layer/ui_rewardDlgCell")
require("ui_layer/ui_rewardDlgCell_cell")

function initTowerSweep()
	local view = createObj(ui_towerSweepLayer)
	local currentlayer = GetMainMenu():GetModelLayer()
	currentlayer:addChild(view.node_)
end

xpcall(initTowerSweep, __G__TRACKBACK__)