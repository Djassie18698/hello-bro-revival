--description: 用于记录前后端通讯的协议定义

module( "protocol", package.seeall )

URL_RANDNAME				=	"rl_r_randname"
URL_LOGIN					=	"rl_w_login2"
URL_LOADVERSION				=	"rl_r_version"
URL_REGISTRATION			=	"rl_w_reg2"
URL_REGISTRATIONIINIT		=	"rl_w_init"
URL_CARDLIST				=	"rl_r_bagage"
URL_MAINPAGE				=	"rl_r_mainpage"
URL_UPGRADE					=	"rl_w_strengthen"
URL_NINJALIST				=	"rl_r_ninjalist"
URL_RUN_ROUND				=	"rl_r_adventure"
URL_W_ROUND					=	"rl_w_adventure"
URL_W_NINJALIST				=	"rl_w_ninjalist"
URL_SHOPLIST				=	"rl_r_shoplist"
URL_SHOPBUY					=	"rl_w_shopbuy"
URL_USECONSUME				=	"rl_w_propuse"
URL_R_RECRUIT               =	"rl_r_recruit"
URL_NINJARECRUIT			=	"rl_w_recruit"
URL_R_MARKCHIP				=	"rl_r_markchip"
URL_W_MARKCHIP				=	"rl_w_markchip"
URL_R_PKLIST				=	"rl_r_pk"
URL_W_PVP					=	"rl_w_pvp"
URL_R_MSG					=	"rl_r_msg"
URL_W_MSG					=	"rl_w_msg"
URL_R_DUP					=	"rl_r_dup"
URL_W_DUP					=	"rl_w_dup"
URL_R_FRIEND				=	"rl_r_friend"
URL_W_FRIEND				=	"rl_w_friend"
URL_W_SEARCH_FRIEND			=	"rl_r_nickinfo"
URL_R_COUNTRYINFO			=	"rl_r_country"
URL_W_COUNTRYINFO			=	"rl_w_country"
URL_R_WARINFO				=	"rl_r_war"
URL_R_WARINFO_RESULT		=	"rl_r_warresult"
URL_W_WAR_RESULT			=	"rl_w_warresult"
URL_R_WARRANK				=	"rl_r_countryrank"
URL_R_WARMSG				=	"rl_r_warmsg"
URL_W_WARFIGHT				=	"rl_w_war"
URL_R_ARENA					=	"rl_r_sport"
URL_R_ARENA_RANK			=	"rl_r_sportrank"
URL_W_ARENA_PACK			=	"rl_w_sportpack"
URL_W_ARENA					=	"rl_w_sport"
URL_W_ACTIVITY				=	"rl_w_activity"
URL_R_MYBANK				=	"rl_r_tear"
URL_W_MYBANK				=	"rl_w_tear"
URL_R_COUNTRYBANK			=	"rl_r_tearcountry"
URL_W_COUNTRYBANK			=	"rl_w_tearcountry"
URL_W_COUNTRYGUARD			=	"rl_w_tearguard"
URL_R_PAYPACK				=	"rl_r_paypack"
URL_W_PAYPACK				=	"rl_w_paypack"
URL_W_RAMEN					=	"rl_w_ramen"
URL_W_KY_PAYORDER           =	"rl_w_ky_payorder"
URL_R_KY_CHECKORDER         =	"rl_r_ky_checkorder"
URL_W_STRENGTH				=	"rl_w_star"
URL_R_MONEYTREE				=	"rl_r_mtree"
URL_W_MONEYTREE				=	"rl_w_mtree"
URL_R_SYSTEMNOTICE			=	"rl_r_bulletin"
URL_R_VERSION				=	"rl_r_version"
URL_R_PUCHASE_LIST          =	"rl_r_readconf"
URL_W_ROULETTE				=	"rl_w_wheel"
URL_R_ROULETTE				=	"rl_r_wheel"
URL_R_WHEELRANK				=	"rl_r_fwheel_rank"
URL_R_WHEELGIFT				=	"rl_w_wheel_gift"
URL_W_INIVTECODE			=	"rl_w_invitecode"
URL_W_NEWLIFE				=	"rl_w_newlife"
URL_R_COMM					= 	"rl_r_comm"
URL_W_COMM					= 	"rl_w_comm"
URL_W_APPLE_BUY				=	"rl_w_apple_buy"
URL_W_LOG					=	"rl_w_log"
URL_R_NOTICE				=	"rl_r_notice"
URL_R_PAY_CUMULA			=	"rl_r_pay_cumula"
URI_R_LIMIT_GROUP           =   "rl_r_comm"
URI_R_LIMIT_BUY             =   "rl_w_comm"
URI_R_CWARLIST				= 	"rl_r_cross_war"
URI_W_CWARLIST				=	"rl_w_cross_war"
URL_W_CWAR					=   "rl_w_cwar"
URL_W_CWAR_WAR 				=	"rl_w_cwar_war"
URL_R_CROSSWAR_RANK			=	"rl_r_crosswar_rank"
URL_X_MYSTERY_SHOP			=   "rl_x_mystery_shop"
URL_GROWTH_FUND_R			=   "rl_x_small_activity"

--挑战
ARENA_FIGHT					= 	8200
ARENA_GET_PACKAGE			= 	8300
ARENA_CANCEL_CD				= 	8301

--切磋
PVP_CMD_BEGIN 				=   2700
PVP_CMD_TAKE  				=   2700 --夺宝命令字
PVP_CMD_FIGHT 				=   2701 --切磋命令字
PVP_CMD_END   				=   2701

CMD_R_COMM					= 	2
CMD_W_COMM02				=	2 --最强战力领取奖励
CMD_W_COMM03				=	3 --最强等级领取奖励
CMD_PAYPACK					=	1
CMD_GET_PURCHASE_LIST 		= 	1


CMD_KY_CHECKORDER           =	2401	--支付请求订单
CMD_KY_SEARCHORDER          =	2401	--查询订单
CMD_KY_PAYORDER				= 	2400

--获取充值列表以及领取充值奖励的参数设置
E_GET_AWARD = 0
E_GET_PURCHASE_LIST = 1

--客户端log 处理
LOG_CMD						= 	2500	--刮刮乐错误处理
LOG_CMD_FOR_SYSTEM_ERROR	= 	2501	--系统错误处理

ROULETTE_R_DISPALY			= 	1400
ROULETTE_R_LOADINFO			= 	1401
ROULETTE_R_RANK				= 	1400

ROULETTE_W_ONCE				= 	1400
ROULETTE_W_TENTIMES			= 	1401
ROULETTE_W_SCORE_GIFTPACK	= 	2

CMD_CROSS_WAR_01 			= 	1 		--打斗
CMD_CROSS_WAR_02 			= 	2       --阵容对比

