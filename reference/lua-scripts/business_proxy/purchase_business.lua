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

function initPurchase()
	local puchaseLayer = createObj(ui_purchaseLayer)
	GetMainMenu():GetModelLayer():AddDialog(puchaseLayer.node_, 3);
end

xpcall(initPurchase, __G__TRACKBACK__)