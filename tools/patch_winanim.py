# Default item-name labels in several layouts read the Chinese "大拉面" (Big Ramen). The game leaves that default when it does not fill the
# name (seen on the victory reward draw, fillDropData row 147 ramen, and ramen rewards), so the default is English now (hot update 28.0.30).
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ccbi

FILES = ['core_combat/RS_WinAnim.ccbi', 'activity/AwardCenterCellCell.ccbi', 'activity/GodRecruitReturn.ccbi', 'activity/SaveTimeView.ccbi',
         'dlg_ui/BuyItemDialogCellView.ccbi', 'sub_ui/CommonRewardCell_cell.ccbi', 'sub_ui/DailyRewardView.ccbi', 'sub_ui/SweepRewardDlgCell_cell.ccbi']
for f in FILES:
    src, dst = 're/obb/' + f, 'server/cdn/src/' + f
    data = open(src, 'rb').read()
    try:
        data = ccbi.replace_string(data, '大拉面', 'Big Ramen')
    except AssertionError as e:
        print('skip', f, e); continue
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    open(dst, 'wb').write(data)
    print('wrote', dst)
