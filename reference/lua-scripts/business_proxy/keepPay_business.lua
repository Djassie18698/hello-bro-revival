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

require("ui_layer/ui_keepPayLayer")
require("ui_layer/ui_keepPayCell")

function initKeepPayLayer()
	local view = createObj(ui_keepPayLayer)
	local currentlayer = GetActivityView():GetNodeContent()
	currentlayer:addChild(view.node_)
end

xpcall(initKeepPayLayer, __G__TRACKBACK__)