# Victory screen silver (hot update 28.0.26): in core_combat/NewFightResult_WinView.ccbi the round layer has two silver labels at the
# same spot: label_round_getsilver (hidden), which CNewResultWinView::InitUI fills with the reward silver, and label_round_getsilver_pre
# (shown), which no code ever writes, so Spar and training wins always showed silver 0. Show the real one and move the empty one away.
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ccbi

SRC = 're/obb/core_combat/NewFightResult_WinView.ccbi'
DST = 'cdn/src/core_combat/NewFightResult_WinView.ccbi'
data = ccbi.patch(open(SRC, 'rb').read(), {
    'label_round_getsilver': {'visible': True},
    'label_round_getsilver_pre': {'position': (-5000.0, 22.0, 0)},
})
os.makedirs(os.path.dirname(DST), exist_ok=True)
open(DST, 'wb').write(data)
print('wrote', DST)
