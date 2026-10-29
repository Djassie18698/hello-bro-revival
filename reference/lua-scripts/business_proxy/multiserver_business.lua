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
require("config/activity_config")
require("config/firstpurchase_config")
require("ui_layer/multi_battle/ui_multiBattleBefore")
require("ui_layer/multi_battle/ui_multiBattleBuyTicket")
require("ui_layer/multi_battle/ui_multiBattleDesc")
require("ui_layer/multi_battle/ui_multiBattleItemBefore")
require("ui_layer/multi_battle/ui_multiBattleRank")
require("ui_layer/multi_battle/ui_multiBattleScoreDlg")
require("ui_layer/multi_battle/ui_multiBattling")
require("ui_layer/multi_battle/ui_multiBattlingItem")
require("ui_layer/multi_battle/ui_multiRankGiftItem")
require("ui_layer/multi_battle/ui_multiRankItem")
require("ui_layer/multi_battle/ui_multiServerHonour")
require("ui_layer/multi_battle/ui_multiTeamCompareItemView")
require("ui_layer/multi_battle/ui_multiTeamCompareView")
require("ui_layer/multi_battle/ui_multiServerLayer")





function initMultiServerBattle()
	local view = createObj(ui_multiServerLayer)
    local currentlayer = tolua.cast(GetMainMenu():GetCurrentSubMenu(), "CCLayer")
    --if view.battleStatus ~= 0 then
    view.node_:setTag(1002)		--必须设置tag 为1002，因为c++ 层有通过这个去判断，执行删除逻辑        --(已经废除了)
	currentlayer:addChild(view.node_)
    --end
end

--xpcall(initMultiServerBattle, __G__TRACKBACK__)