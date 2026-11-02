require("RLRequest")
require("util/protocol")
require("util/tools")
require("util/common")
require("global/cfg")
require("util/localizable")
require("ui_common/node_base_t")
require("ui_common/layer_base_t")
require("LuaXml")
require("CommonDialogView")
require("ui_layer/ui_fightRankLayer")
require("ui_layer/ui_levelRankTableCell")
require("ui_layer/ui_levelRankGiftTableCell")



function initFightRank()
	local activityView = GetActivityView()
	local contentNode = activityView:GetNodeContent()
	local ui_fightRank = createObj(ui_fightRankLayer)
	contentNode:addChild(ui_fightRank.node_)
end

xpcall(initFightRank, __G__TRACKBACK__)