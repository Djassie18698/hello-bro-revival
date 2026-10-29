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

require("ui_layer/ui_saveTimeLayer")
require("ui_layer/ui_saveTimeAnim")

function initSaveTime()
	local view = createObj(ui_saveTimeLayer)
	local currentlayer = GetMainMenu():GetModelLayer()
	currentlayer:addChild(view.node_)
end

xpcall(initSaveTime, __G__TRACKBACK__)