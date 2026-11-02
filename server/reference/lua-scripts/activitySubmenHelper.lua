require "moraView.lua"

require "ui_layer/ui_rouletteLayer"
require "ui_layer/ui_rouletteBingo"
require "ui_layer/ui_rouletteRankLayer"
require "ui_layer/ui_rouletteRankTableCell"

require "ui_layer/ui_monopolyLayer"
require "ui_layer/ui_monopolyRankLayer"
require "ui_layer/ui_monopolyRankCell"
require "ui_layer/ui_monopolyDiceAnim"
require "ui_layer/ui_monopolyLightAnim"

require("ui_layer/ui_borderWarLayer")
require("ui_layer/ui_borderWarCell")

require("ui_layer/ui_borderWarRankLayer")
require("ui_layer/ui_borderWarRankCell")

require("ui_layer/ui_borderWarProvokeInfoLayer")
require("ui_layer/ui_borderWarProvokeInfoCell")

require ("ui_layer/ui_borderWarWanderInfoLayer")
require ("ui_layer/ui_borderWarWanderInfoCell")

require("ui_layer/ui_borderWarRewardLayer")
require("ui_layer/ui_borderWarStateRewardLayer")
require("ui_layer/ui_borderWarStateRewardCell")

require("ui_layer/ui_borderWarShowTip")
require("ui_layer/ui_borderWarShowAttackTip")
require("ui_layer/ui_borderWarFireAnim")
require("ui_layer/ui_borderWarShowDetail")
require("ui_layer/ui_borderWarAttackLayer")
require("ui_layer/ui_borderWarCommonRewardDlg")
require("ui_layer/ui_borderWarChangeAttackDlg")
require("ui_layer/ui_borderWarBloodDetailLayer")
require("ui_layer/ui_borderWarBloodDetailCell")

require("ui_layer/secret_shop/ui_secretShopLayer")
require("ui_layer/secret_shop/ui_secretShopNode")
require("ui_layer/secret_shop/ui_trainSoulLayer")
require("ui_layer/secret_shop/ui_trainNinjaListLayer")
require("ui_layer/secret_shop/ui_trainNinjaItem")
require("ui_layer/secret_shop/ui_trainNinjaCard")
require("ui_layer/secret_shop/ui_trainSoulAnimation")
require("ui_layer/secret_shop/ui_trainResultLayer")
require("ui_layer/secret_shop/ui_trainSoulDescription")

require("ui_layer/ui_colorSuitView")
require("ui_layer/ui_levelSuitView")
require("ui_layer/ui_suitCell")

require("ui_layer/ui_hallOfFameView")
require("ui_layer/ui_hallOfFameCell")

require("ui_layer/limit_superninja/ui_limitSuperNinjaLayer")
require("ui_layer/limit_superninja/ui_currSuperNinjaTableCell")
require("ui_layer/limit_superninja/ui_rewardInfoTableCell")
require("ui_layer/limit_superninja/ui_integralRankTableCell")
require("ui_layer/ui_growthfundLayer")

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

require("ui_layer/ui_attributeDanLayer")
require("ui_layer/ui_attributeDanNinjaListLayer")
require("ui_layer/ui_attributeDanNinjaItem")
require("ui_layer/ui_changeAttrAnim")

require("ui_layer/ui_godCardSyntheticLayer")
require("ui_layer/ui_godCardSyntheticNinjaListLayer")
require("ui_layer/ui_godCardSyntheticNinjaItem")
require("ui_layer/ui_godCardSyntheticReadMeLayer")
require("ui_layer/ui_godCardReadmeCell")
require("ui_layer/ui_godCardSyntheticAnim")

require("ui_layer/ui_ninjaTreasureLayer")

require("ui_layer/ui_ninjaInheritLayer")
require("ui_layer/ui_ninjaInheritNinjaListLayer")
require("ui_layer/ui_ninjaInheritNinjaItem")
require("ui_layer/ui_ninjaInheritReadmeCell")
require("ui_layer/ui_ninjaInheritAnim")

require("ui_layer/ui_limitTrainLayer")
require("ui_layer/ui_limitTrainSoulLayer")
require("ui_layer/ui_limitTrainAnim")
require("ui_layer/ui_limitTrainCell")

--跨服大富翁、跨服大转盘、跨服超忍_litao_2014.8.20
require("ui_layer/ui_crossRouletteLayer")
require("ui_layer/ui_crossRouletteRankLayer")
require("ui_layer/ui_crossRouletteRankTableCell")

require("ui_layer/ui_crossMonopolyLayer")
require("ui_layer/ui_crossMonopolyRankLayer")
require("ui_layer/ui_crossMonopolyRankCell")

require("ui_layer/limit_superninja/ui_crossLimitSuperNinjaLayer")
require("ui_layer/limit_superninja/ui_crossCurrSuperNinjaTableCell")
require("ui_layer/limit_superninja/ui_crossRewardInfoTableCell")
require("ui_layer/limit_superninja/ui_crossIntegralRankTableCell")

--org组织_litao_2014.10.24
require("ui_layer/ui_orgListLayer")
require("ui_layer/ui_orgListCell")
require("ui_layer/ui_orgDetailLayer")
require("ui_layer/ui_orgAppliedLayer")
require("ui_layer/ui_orgAppliedCell")
require("ui_layer/ui_orgCreateLayer")
require("ui_layer/ui_orgMainLayer")
require("ui_layer/ui_orgMainCell")
require("ui_layer/ui_orgMapLayer")
require("ui_layer/ui_orgRankingsLayer")
require("ui_layer/ui_orgRankingsCell")
require("ui_layer/ui_orgHallLayer")
require("ui_layer/ui_orgHallCell")
require("ui_layer/ui_orgDonateLayer")
require("ui_layer/ui_orgShopLayer")
require("ui_layer/ui_orgShopCell")
require("global")

require('ui_layer/ui_slotMachineLayer')
require('ui_layer/ui_advanceEquipLayer')

require("ui_layer/ui_myBaseLayer")
--require("ui_layer/ui_petTrainingLayer")

require("ui_layer/ui_tupoLayer")
require("ui_layer/ui_tupoNinjaListLayer")
require("ui_layer/ui_tupoNinjaItem")
require("ui_layer/ui_tupoAnimation")
require("ui_layer/ui_tupoDesc")


function AddViewToActivitySubMenu(view)
	local submenuContainer = tolua.cast(GetMainMenu():GetActivitySubMenuView(), "CCLayer")
	if submenuContainer ~= nil then
		submenuContainer:addChild(view)
	end
end

function ShowMoraView()
	local view = moraView:create()
	--view:setTag(1002)	----必须设置tag 为1002，因为c++ 层有通过这个去判断，执行删除逻辑
	view.m_contentsize = GetMainMenu():GetSubContentNode():getContentSize()
	view.bet_ok = false
	moraView.m_selfview = view;
	view:initUI()
	--local currentlayer = tolua.cast(GetMainMenu():GetCurrentSubMenu(), "CCLayer")
	--currentlayer:removeAllChildrenWithCleanup(true)
	AddViewToActivitySubMenu(view)
end


function ShowRouletteView()
	local view = createObj(ui_rouletteLayer)
	AddViewToActivitySubMenu(view.node_)
end

function ShowMonopolyView()
	local view = createObj(ui_monopolyLayer)
	AddViewToActivitySubMenu(view.node_)
end

function ShowBorderWarView()
	local view = createObj(ui_borderWarLayer)
	AddViewToActivitySubMenu(view.node_)
end

function ShowSecretShopView(secretShopEntry)
	if secretShopEntry ~= nil then
		loadstring(secretShopEntry)() --这句代码会生成gSecretShopEntry 全局变量
		local view = createObj(ui_secretShopLayer, gSecretShopEntry) 
		AddViewToActivitySubMenu(view.node_)
	else
		local view = createObj(ui_secretShopLayer)
		AddViewToActivitySubMenu(view.node_)
	end
end


function  ShowTrainSoulView(trainSoulEntry)	
	if trainSoulEntry ~= nil then
		loadstring(trainSoulEntry)() --这句代码会生成gTrainSoulEntry 全局变量
		local view = createObj(ui_trainSoulLayer, gTrainSoulEntry) 
		AddViewToActivitySubMenu(view.node_)
	else
		local view = createObj(ui_trainSoulLayer)
		AddViewToActivitySubMenu(view.node_)
	end
end

function ShowColorSuitView()
	local view = createObj(ui_colorSuitView)
	--AddViewToActivitySubMenu(view.node_)
	local currentlayer = GetMainMenu():GetModelLayer()
	currentlayer:addChild(view.node_)
end

function ShowLevelSuitView()
	local view = createObj(ui_levelSuitView)
	--AddViewToActivitySubMenu(view.node_)
	local currentlayer = GetMainMenu():GetModelLayer()
	currentlayer:addChild(view.node_)
end

function ShowMultiBattleView()
	local view = createObj(ui_multiServerLayer)
	AddViewToActivitySubMenu(view.node_)
end

function ShowHallOfFame()
	local view = createObj(ui_hallOfFameView)
	AddViewToActivitySubMenu(view.node_)
end

function ShowSuperNinjaView()
 	local view = createObj(ui_limitSuperNinjaLayer)
	AddViewToActivitySubMenu(view.node_)
end

function ShowGrowthFundView()
	local view = createObj(ui_growthfundLayer);
	AddViewToActivitySubMenu(view.node_);
end

function ShowAttributeDanView(card_bag_id)
	if nil ~= card_bag_id then
		local view = createObj(ui_attributeDanLayer, card_bag_id)
		AddViewToActivitySubMenu(view.node_)
	else
		local view = createObj(ui_attributeDanLayer)
		AddViewToActivitySubMenu(view.node_)
	end
end

function ShowGodCardSyntheticView()	
	local view = createObj(ui_godCardSyntheticLayer)
	AddViewToActivitySubMenu(view.node_)	
end

function ShowNinjaTreasureView()
	local view = createObj(ui_ninjaTreasureLayer)
	AddViewToActivitySubMenu(view.node_)
end

function ShowNinjaInheritView(card_bag_id)
	if nil ~= card_bag_id then
		local view = createObj(ui_ninjaInheritLayer, card_bag_id)
		AddViewToActivitySubMenu(view.node_)
	else
		local view = createObj(ui_ninjaInheritLayer)
		AddViewToActivitySubMenu(view.node_)
	end
end

function ShowLimitTrainView()
	local view = createObj(ui_limitTrainLayer)
	AddViewToActivitySubMenu(view.node_)
end

function ShowLimitTrainSoulView()
	local view = createObj(ui_limitTrainSoulLayer)
	AddViewToActivitySubMenu(view.node_)
end

--跨服大富翁、跨服大转盘、跨服超忍_litao_2014.8.20
function ShowCrossRouletteView()
	local view = createObj(ui_crossRouletteLayer)
	AddViewToActivitySubMenu(view.node_)
end

function ShowCrossMonopolyView()
	local view = createObj(ui_crossMonopolyLayer)
	AddViewToActivitySubMenu(view.node_)
end

function ShowCrossSuperNinjaView()
 	local view = createObj(ui_crossLimitSuperNinjaLayer)
	AddViewToActivitySubMenu(view.node_)
end

function PreShowOrgView( )
	
end
function ShowOrgView()
	local orgState = 0
	--获取角色是否有组织
	local playerinfo = CPlayerDataMgr:instance():GetPlayerInfoData()
	local urlpath = GetUrlNormalHeader(playerinfo.m_uid, 8, "rl_r_group_comm")
	cclog("rl_r_group_comm & cmd = 8---%s", urlpath)
	GetMainMenu():ShowLoadingDlg()
	CCHttpRequest:open(urlpath, kHttpPost, "query=param1&other=params"):sendWithHandler(
		function(res, hnd)
			GetMainMenu():CloseLoadding()
			local resData = res:getResponseData()
			local code = res:getResponseCode()
			local xfile = xml.parse(resData)
			local item = xfile:find("RENLONG")
			if item == nil then
				return nil
			end
			cclog("rl_r_group_comm ret = %s", resData)
			local retcode = item.code
			if retcode == "0" then
				local minLevel = tonumber(item:find("min_user_level")[1])
				if playerinfo.m_level < minLevel then
					GetMainMenu():ShowTextTip(tostring(minLevel) .. localizable.ui_orgMinLevel, -1)
					return nil
				end

				orgState = tonumber(item:find("member_status")[1])

				--0:未申请组织；1:申请审核中；2:已加入组织
				if orgState == 2 then --已有组织
					global.myOrgId = item:find("groupid")[1]
					GetMainMenu():ChangeToActivitySubMenu("ShowOrgMapLayer")
				else -- 未加入组织或正在审核中
					GetMainMenu():ChangeToActivitySubMenu("ShowOrgListLayer")
				end
			else
				GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
			end
		end)
end

function ShowOrgMapLayer()
	local view = createObj(ui_orgMapLayer)
	AddViewToActivitySubMenu(view.node_)
end

function ShowOrgListLayer()
	local view = createObj(ui_orgListLayer)
	AddViewToActivitySubMenu(view.node_)
end

function ShowOrgMainView()
	local view = createObj(ui_orgMainLayer)
	AddViewToActivitySubMenu(view.node_)
end

function ShowOrgRankings()
	local view = createObj(ui_orgRankingsLayer)
	AddViewToActivitySubMenu(view.node_)
end

function ShowOrgHall()
	local view = createObj(ui_orgHallLayer)
	AddViewToActivitySubMenu(view.node_)
end

function ShowOrgDonate()
	local view = createObj(ui_orgDonateLayer)
	AddViewToActivitySubMenu(view.node_)
end

function ShowOrgShop()
	local view = createObj(ui_orgShopLayer)
	AddViewToActivitySubMenu(view.node_)
end

--[[
function ShowSweepAward(node, awardData )
	require("ui_layer/ui_sweepAwardLayer")
	showModelLayer(ui_sweepAwardLayer,node,awardData)
end

function ShowSummon()
	local view = createObj(ui_summonLayer)
	AddViewToActivitySubMenu(view.node_)
end
]]--

function ShowAwardCenter(  )
	require("ui_layer/ui_awardCenterLayer")
	local puchaseLayer = createObj(ui_awardCenterLayer)
	GetMainMenu():GetModelLayer():AddDialog(puchaseLayer.node_, 3);
end

function  ShowAdvanceEquipView(entryStr)	
	if entryStr ~= nil then
		loadstring(entryStr)() --这句代码会生成gTrainSoulEntry 全局变量
		local view = createObj(ui_advanceEquipLayer, gAdvanceEquipEntry) 
		AddViewToActivitySubMenu(view.node_)
	else
		local view = createObj(ui_advanceEquipLayer)
		AddViewToActivitySubMenu(view.node_)	
	end
end

function ShowSlotMachine()
	local view = createObj(ui_slotMachineLayer)
	AddViewToActivitySubMenu(view.node_)
end

function showBase( )

	GetMainMenu():ChangeToActivitySubMenu('doShowBase')
end

function doShowBase(  )
	cclog('~!~!~!~!~!~!~!~!~!~!')
	local view = createObj(ui_myBaseLayer)
	AddViewToActivitySubMenu(view.node_)
end