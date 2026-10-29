MeunBtnsData = {
	{icon="def_btn_ninjabook",actionscript="GetMainMenu():ChangeToSub(E_GAMEBOOKLISTVIEW);"},
	{icon="def_msg_btn",actionscript="GetMainMenu():ChangeToSub(E_INFORMATIONVIEW);"},
	--{icon="def_btn_chat",actionscript="ShowChatView();"},
	{icon="def_godCard",actionscript="GetMainMenu():ChangeToActivitySubMenu(\"ShowGodCardSyntheticView\");"},
	{icon="def_btn_limitTrain",actionscript="GetMainMenu():ChangeToActivitySubMenu(\"ShowLimitTrainView\");"},
	--{icon="defPayRanking", actionscript="showPayRanking()"},
	{icon="def_btn_trainsoul",actionscript="GetMainMenu():ChangeToActivitySubMenu(\"ShowTrainSoulView\");"},
	{icon="cuilian",actionscript="GetMainMenu():ChangeToSub(E_STRENGTHVIEW);"},
	{icon="def_btn_potential",actionscript="GetMainMenu():ChangeToSub(E_POTENTIALVIEW);"},
	{icon="def_btn_rein",actionscript="GetMainMenu():ChangeToSub(E_REINCARNATIONVIEW);"},
	{icon="def_btn_setting",actionscript="require('ui_layer/ui_gameSettingLayer'); local gameSettingView = createObj(ui_gameSettingLayer);GetMainMenu():GetModelLayer():AddDialog(gameSettingView.node_, 3);"},
	{icon="def_btn_friends",actionscript="GetMainMenu():ChangeToSub(E_FRIENDLISTVIEW);"},
	--{icon="def_btn_reward",actionscript="GetMainMenu():doPromoter();"}
}		

if global.isReviewing() then
	table.remove(MeunBtnsData,1)
end