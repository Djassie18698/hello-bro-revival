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

require("ui_layer/ui_commonPrePay")
require("ui_layer/ui_prePayAnim")

function initCommonPrePayLayer()
	local view = createObj(ui_commonPrePay)
	local currentlayer = GetMainMenu():GetModelLayer()
	currentlayer:addChild(view.node_, 3)
end

xpcall(initCommonPrePayLayer, __G__TRACKBACK__)