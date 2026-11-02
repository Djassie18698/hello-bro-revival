require "util/localizable"
require "ui_common/node_base_t"
require "ui_common/layer_base_t"
require "CommonDialogView"


function showDialogBoxForActiveTeam()
	local dlg = CommonDialogView.create()
	CommonDialogView.m_selfview = dlg
	dlg:SetTitle(localizable.ui_active_team_title)
	dlg:SetDescription(localizable.ui_active_team_desc)
	dlg:loadCCBI(kCCMenuHandlerPriority-2, "CommonDialogViewBig")
	dlg:initUI()

	GetMainMenu():GetModelLayer():AddDialog(dlg, 3)
end