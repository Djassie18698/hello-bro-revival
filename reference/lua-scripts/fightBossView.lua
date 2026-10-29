
require "LuaSubView.lua"
require "RLRequest"
require "LuaXml.lua"
require "CommonDialogView"
require "bossRewardCellView"
require "fightBossHeroDialog"
require "util/tools"
require "util/text"
require "PlayOnceAnimLayer.lua"
require "fightBossClearCdDialog.lua"
require "fightBossDetailView.lua"
require "fightBossEnhanceDialogView.lua"
require "util/localizable"

local m_touchPoint


fightBossView=class(
	"fightBossView",
    function()
        return LuaSubView:create() 
    end
)

local m_selfview={};
function fightBossView:create()
	local view = fightBossView.new();
	fightBossView.m_selfview = view;
	return view;
end

function fightBossView:updateUI()
	self:initRewardTable()

	local bigninjaicon = CGameObjElement:GetNinjaIcon(E_FRAMETYPE_LARGE, self.m_bossicon)
	local bigninjasprite = CCSprite:createWithSpriteFrame(bigninjaicon)
	if bigninjasprite ~= nil then
		self:getNode("node_icon"):removeAllChildrenWithCleanup(true)
		self:getNode("node_icon"):addChild(bigninjasprite)
		local size = self:getNode("node_icon"):getContentSize()
		bigninjasprite:setAnchorPoint(ccp(0.5,0.5))
		bigninjasprite:setPosition(ccp(size.width/2,size.height/2))
	end
	
	local frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(self.m_bossname_icon)
	if frame ~= nil then
		tolua.cast(self:getNode("sprite_boss_name"),"CCSprite"):setDisplayFrame(frame)
	end
	
	if self.m_attacktype == 1 then
		frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("com_text_gong_02")
	else
		frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("com_text_fang_02")
	end
	if frame ~= nil then
		tolua.cast(self:getNode("sprite_attack_type"),"CCSprite"):setDisplayFrame(frame)
	end
	
	local currentLifeStr = self:getLifeStr(self.m_current_life)
	local totalLifeStr = self:getLifeStr(self.m_total_life)
	tolua.cast(self:getNode("label_boss_life"), "CCLabelTTF"):setString(currentLifeStr.."/"..totalLifeStr)
	tolua.cast(self:getNode("sprite_blood"), "CCScale9Sprite"):setScaleX(self.m_current_life/self.m_total_life)
	
	--[[local damageStr = "伤害x"..self:GetDiceStr(self.m_damage_times)
	tolua.cast(self:getNode("label_damage_times"), "CCLabelTTF"):setString(damageStr)
	
	tolua.cast(self:getNode("label_last_shot_reputation"), "CCLabelTTF"):setString(self.m_lastshot_reputation)
	tolua.cast(self:getNode("label_in_reputation"), "CCLabelTTF"):setString(self.m_in_reputation)
	tolua.cast(self:getNode("label_in_lose"), "CCLabelTTF"):setString(self.m_in_failed)
	tolua.cast(self:getNode("label_current_reputation"), "CCLabelTTF"):setString(self.m_my_reputation)
	tolua.cast(self:getNode("label_current_damage"), "CCLabelTTF"):setString(self.m_this_total_hurt)]]
	
	local timeStr = self:gettimelabel(self.m_resttime)
	self.m_timelabel:setString(timeStr)
	timeStr = self:getTitle(self.m_resttime)
	self.m_titleLabel:setString(timeStr)
	
	if self.m_periodId ~= fightBossPeriodId then
		fightBossPeriodId = self.m_periodId
		fightBossMsgImportantId = 0
		fightBossMsgNormalId = 0
	end
	
	tolua.cast(self:getNode("label_fight_up"), "CCLabelBMFont"):setString("+"..self.m_up_total.."%")
	tolua.cast(self:getNode("label_current_damage"), "CCLabelTTF"):setString(self.m_this_total_hurt)
	tolua.cast(self:getNode("label_current_rank"), "CCLabelTTF"):setString(self.m_my_rank)
	tolua.cast(self:getNode("label_my_current_rep"), "CCLabelBMFont"):setString(self.m_my_reputation)
	tolua.cast(self:getNode("label_pk_limit"), "CCLabelTTF"):setString(self.m_fight_left_times.."/"..self.m_fight_attack_total)
	tolua.cast(self:getNode("label_boss_level"), "CCLabelTTF"):setString(self.m_boss_level)
	
	if self.m_current_life <= 0 then
		self.m_timelabel:setVisible(false)
	else
		self.m_timelabel:setVisible(true)
	end
end

function fightBossView:getLifeStr(life)
	if life < 100000 then
		return tostring(life)
	else
		life = tools.getIntPart(life / 10000)
		return tostring(life).."W"
	end
end

function fightBossView:initRewardTable()
	local contentNode = self:getNode("node_rewardcontent")
	local contentsize = contentNode:getContentSize()
	
	if self.m_reward_tableview == nil then
		self.m_reward_cellsize = self:getNode("node_award_cell"):getContentSize()
		self:initRewardHandle();
		self.m_reward_tableview = LuaTableView:createWithHandler(self.m_reward_handler, CCSizeMake(contentsize.width,contentsize.height))
		self.m_reward_tableview:setDirection(kCCScrollViewDirectionHorizontal)
		self.m_reward_tableview:setVerticalFillOrder(kCCTableViewFillTopDown)
		contentNode:addChild(self.m_reward_tableview)
	end
	self.m_reward_tableview:reloadData()
end

function fightBossView:initUI()	
	self.m_rank_tableview = nil
	self.m_reward_tableview = nil
	self.cellNodes = {}
	
	self:LoadCCBI("activity/FightBoss.ccbi",self.m_contentsize);	
	self:LoadInfoData();
	
	self:BindControl()
	
	local function updateLeftTimeLabel(fDeltaTime)
		self.deltatime = self.deltatime + fDeltaTime
		if self.deltatime >= 1 then
			if self.m_resttime <= 0 then
				if self.m_active == 0 then
					self.m_active = 1
				end
				timeStr = self:getTitle(self.m_resttime)
				self.m_titleLabel:setString(timeStr)
				self:LoadInfoData()
			else
				self.m_resttime = self.m_resttime - 1
				local timeStr = self:gettimelabel(self.m_resttime)
				self.m_timelabel:setString(timeStr)
			end
			timeStr = self:getTitle(self.m_resttime)
			self.m_titleLabel:setString(timeStr)
			
			if self.m_fight_resttime > 0 then
				self.m_fight_resttime = self.m_fight_resttime - 1
				--复活cd时间_litao_2014.8.1
				local timeStr = tools.convertTimeElectronicWatch(self.m_fight_resttime, 3)
				self.label_cd_time:setString(timeStr)
				
				if self.m_fight_resttime == 0 then
					self.m_fight_left_times = self.m_fight_attack_total
					tolua.cast(self:getNode("label_pk_limit"), "CCLabelTTF"):setString(self.m_fight_left_times.."/"..self.m_fight_attack_total)
				end
			end
			
			local intPart, floatPart = math.modf(self.deltatime)
			self.deltatime = floatPart
		end
	end
	
	local function updateBossInfo(fDeltaTime)
		self.boss_deltatime = self.boss_deltatime + fDeltaTime
		if self.boss_deltatime >= 5 then
			if self:isFightOK() == 1 then
				if self.m_current_life > 0 then
					self:LoadBossInfo()
				end
			end			
			
			local intPart, floatPart = math.modf(self.boss_deltatime)
			self.boss_deltatime = floatPart
		end
	end
	
	local function updateShowList(fDeltaTime)
		self.show_deltatime = self.show_deltatime + fDeltaTime
		if self.show_deltatime >= self.m_showInter then
			if self:isFightOK() == 1 then
				self:ShowFightAttackList()
			end			
			
			self.show_deltatime = 0
		end
	end
	
	self.deltatime = 0
	self.deltaCdtime = 0
	self.boss_deltatime = 0
	self.show_deltatime = 0
	self.m_resttime = 0
	self.m_fight_resttime = 0

	--新增任务复活cd时间_litao_2014.8.1
	self.label_cd_time = tolua.cast(self:getNode("label_cd_time"), "CCLabelTTF")
	local timeStr = tools.convertTimeElectronicWatch(self.m_fight_resttime, 3)
	self.label_cd_time:setString(timeStr)

	self.m_timelabel = tolua.cast(self:getNode("label_resttime"), "CCLabelTTF")
	self.m_titleLabel = tolua.cast(self:getNode("label_boss_title"), "CCLabelTTF")
	self.m_timelabel:scheduleUpdateWithPriorityLua(updateLeftTimeLabel, 0)
	
	self.m_herobtn = tolua.cast(self:getNode("btn_hero"), "CCControlButton")
	local move = CCScaleBy:create(1, 0.8)
	local array = CCArray:create()
	array:addObject(move)
	array:addObject(move:reverse())
	local forever = CCRepeatForever:create(CCSequence:create(array))
	self.m_herobtn:runAction(forever)
	
	self.m_herobtn:scheduleUpdateWithPriorityLua(updateBossInfo, 0)
	
	self.m_showIndex = 0
	self.m_showList = {}
	self.m_showInter = 1
	math.randomseed(os.time())
	self:scheduleUpdateWithPriorityLua(updateShowList, 0)
end

function fightBossView:gettimelabel(_sec)
	local time = tools.convertTimeToTable(_sec)
	
	if self.m_active == 0 or _sec <= 0 then
		return localizable.fightBoss_not_open
	end

	local timestr
	if time.d > 0 then
		timestr = string.format(localizable.localizable.localizable.localizable.mora_time_arg_4, time.d, time.h, time.m, time.s)
    elseif time.h > 0 then
        timestr = string.format(localizable.localizable.localizable.mora_time_arg_3, time.h, time.m, time.s)
    elseif time.m > 0 then
        timestr = string.format(localizable.localizable.mora_time_arg_2, time.m, time.s)
    else
        timestr = string.format(localizable.mora_time_arg_1, time.s)
    end
	
	return timestr
end

function fightBossView:calcInterval()
	if #self.m_showList > 0 then
		local inter = 5.0 / #self.m_showList
		if inter < 0.2 then
			return 0.2
		end
		return inter
	else
		return 1
	end
end

function fightBossView:getTitle(_sec)
	if self.m_active == 0 or _sec <= 0 then
		return localizable.fightBoss_status_1
	elseif self.m_current_life <= 0 then
		return localizable.fightBoss_status_2
	else
		return localizable.fightBoss_status_3
	end
end

function fightBossView:initRewardHandle()
	self.m_reward_handler = LuaEventHandler:create(function(fn, table, a1, a2, x, y)
		local r
		if fn == "cellSize" then
			-- Return cell size
			-- a1 is cell index (-1 means default size, in cocos2d-x version below 2.1.3, it's always -1)
			r = self.m_reward_cellsize;
		elseif fn == "cellAtIndex" then
			-- Return CCTableViewCell, a1 is cell index (zero based), a2 is dequeued cell (maybe nil)
			-- Do something to create cell and change the content
			local cell = bossRewardCellView:create();
			cell:setIndex(a1);
			cell:setCellData(self.m_rewarddata[a1+1]);
			cell:setCellSize(self.m_reward_cellsize);
			cell:loadCCBI();
			cell:initUI();
			self.cellNodes[a1+1] = cell
			if not a2 then
				a2 = CCTableViewCell:create()
			else			
				a2:removeAllChildrenWithCleanup(true)
			end
			a2:addChild(cell);
			cell:setTag(100);
			r = a2
		elseif fn == "numberOfCells" then
			r = #self.m_rewarddata;
		-- Cell events:
		elseif fn == "cellTouched" then			-- A cell was touched, a1 is cell that be touched. This is not necessary.	
			local cell = self.cellNodes[a1:getIdx() + 1]
			if cell:getNode("sprite_box_icon"):boundingBox():containsPoint(m_touchPoint) then
				CSoundMgr:instance():PlayEffect(SOUND_BUTTON)
			    fightBossView:clickGetReward(cell:getIndex())
			end		
		elseif fn == "cellTouchBegan" then		-- A cell is touching, a1 is cell, a2 is CCTouch
			m_touchPoint = a2:getLocation()
			local cell = self.cellNodes[a1:getIdx() + 1]
			m_touchPoint = cell:convertToNodeSpace(m_touchPoint)	
			r = true
		elseif fn == "cellTouchEnded" then		-- A cell was touched, a1 is cell, a2 is CCTouch
			r = true
		elseif fn == "cellHighlight" then		-- A cell is highlighting, coco2d-x 2.1.3 or above
		elseif fn == "cellUnhighlight" then		-- A cell had been unhighlighted, coco2d-x 2.1.3 or above
			r = true;
		elseif fn == "cellWillRecycle" then		-- A cell will be recycled, coco2d-x 2.1.3 or above
		end
		return r
	end)
end

function fightBossView:clickGetReward(index)
	CSoundMgr:instance():PlayEffect(SOUND_BUTTON)
	
	local dlg = CommonDialogView.create()
	CommonDialogView.m_selfview = dlg;
	dlg:SetTitle(localizable.fightBoss_award_title_desc)
	dlg:SetDescription(fightBossView.m_selfview.m_rewarddata[index+1]:find("name")[1])
	fightBossView.m_selfview.m_exchangeId = fightBossView.m_selfview.m_rewarddata[index+1]:find("id")[1]
	fightBossView.m_selfview.m_exchangeCost = fightBossView.m_selfview.m_rewarddata[index+1]:find("cost")[1]
	dlg:loadCCBI();
	dlg:SetConfirmHandler(
		function()
			local playerMgr = CPlayerDataMgr:instance()
			local playerData = playerMgr:GetPlayerInfoData()
			local uid = playerData.m_uid
			local urlpath = GetUrlNormalHeader(uid,7,"rl_w_xiao")
			urlpath = AddData(urlpath, "Exchangeid", fightBossView.m_selfview.m_exchangeId)
			GetMainMenu():ShowLoadingDlg();
			CCHttpRequest:openWithUserData(urlpath, kHttpPost, p, "query=param1&other=params"):sendWithHandler(
			function(res, hnd)
				local p = res:getHttpRequest():getUserData()
				local resData = res:getResponseData();			
				local code = res:getResponseCode()
				local xfile = xml.parse(resData)
				local item = xfile:find("RENLONG")
				if item == nil then
					GetMainMenu():CloseLoadding();
					return nil
				end
				local retcode = item.code
				if retcode == "0" then			
					GetMainMenu():CloseLoadding();		
					ShowAward(item:find("award"))	
					fightBossView.m_selfview.m_my_reputation = fightBossView.m_selfview.m_my_reputation-fightBossView.m_selfview.m_exchangeCost
					tolua.cast(fightBossView.m_selfview:getNode("label_my_current_rep"), "CCLabelBMFont"):setString(fightBossView.m_selfview.m_my_reputation)
				else
					GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
					GetMainMenu():CloseLoadding();
				end
			end)
		end)
	dlg:initUI()
	GetMainMenu():GetModelLayer():AddDialog(dlg, 3);

	return nil
end

function fightBossView:initRankHandle()
	self.m_rank_handler = LuaEventHandler:create(function(fn, table, a1, a2, x, y)
		local r
		if fn == "cellSize" then
			-- Return cell size
			-- a1 is cell index (-1 means default size, in cocos2d-x version below 2.1.3, it's always -1)
			r = self.m_rank_cellsize;
		elseif fn == "cellAtIndex" then
			-- Return CCTableViewCell, a1 is cell index (zero based), a2 is dequeued cell (maybe nil)
			-- Do something to create cell and change the content
			local cell = bossRankCellView:create();
			cell:setIndex(a1);
			cell:setCellData(self.m_rankdata[a1+1]);
			cell:setCellSize(self.m_rank_cellsize);
			cell:loadCCBI();
			cell:initUI();
			if not a2 then
				a2 = CCTableViewCell:create()
			else
				a2:removeAllChildrenWithCleanup(true)
			end
			
			a2:addChild(cell);
			cell:setTag(100);
			r = a2
		elseif fn == "numberOfCells" then
			r = #self.m_rankdata;
		-- Cell events:
		elseif fn == "cellTouched" then			-- A cell was touched, a1 is cell that be touched. This is not necessary.	
		elseif fn == "cellTouchBegan" then		-- A cell is touching, a1 is cell, a2 is CCTouch
			r = true
		elseif fn == "cellTouchEnded" then		-- A cell was touched, a1 is cell, a2 is CCTouch
			r = true
		elseif fn == "cellHighlight" then		-- A cell is highlighting, coco2d-x 2.1.3 or above
		elseif fn == "cellUnhighlight" then		-- A cell had been unhighlighted, coco2d-x 2.1.3 or above
			r = true;
		elseif fn == "cellWillRecycle" then		-- A cell will be recycled, coco2d-x 2.1.3 or above
		end
		return r
	end)
end

function fightBossView:BindControl()
	self.m_btn_fight = tolua.cast(self:getNode("btn_fight"), "CCControlButton")
	self.m_btn_up = tolua.cast(self:getNode("btn_up"), "CCControlButton")
	self.m_btn_hero = tolua.cast(self:getNode("btn_hero"), "CCControlButton")
	self.m_btn_detail = tolua.cast(self:getNode("btn_detail"), "CCControlButton")
	
	fightBossView.m_selfview:handleButtonEvent(self.m_btn_fight, function(button, event)
		self:clickFight();
		return nil
	end, CCControlEventTouchUpInside)
	fightBossView.m_selfview:handleButtonEvent(self.m_btn_up, function(button, event)
		self:clickUp();
		return nil
	end, CCControlEventTouchUpInside)
	fightBossView.m_selfview:handleButtonEvent(self.m_btn_hero, function(button, event)
		self:clickHero();
		return nil
	end, CCControlEventTouchUpInside)
	fightBossView.m_selfview:handleButtonEvent(self.m_btn_detail, function(button, event)
		self:clickDetail();
		return nil
	end, CCControlEventTouchUpInside)
end

function fightBossView:isFightOK()
	if self.m_active == 1 and self.m_resttime > 0 then
		return 1
	else
		return 0
	end
end

function fightBossView:ShowFightAttackList()
	self.m_showIndex = self.m_showIndex + 1
	if self.m_showIndex > #self.m_showList then
		return
	end
	
	if self.m_showIndex > #self.m_showList then
		return
	end
	
	local rect = tolua.cast(self:getNode("node_rand_pos_sequare"), "CCNode"):boundingBox()
	local randPosX = math.random(rect.origin.x, rect.origin.x+rect.size.width)
	local randPosY = math.random(rect.origin.y, rect.origin.y+rect.size.height)
	
	local digitView = PlayOnceAnimLayer:create()
	if digitView == nil then
		return nil
	end
	digitView:initUI("activity/ShowFightBossValue.ccbi",CCSize(280,280), 1)
	digitView:setPosition(ccp(randPosX-140,randPosY-80))
	tolua.cast(digitView:getNode("label_playername"), "CCLabelTTF"):setString(self.m_showList[self.m_showIndex].nick)
	tolua.cast(digitView:getNode("label_value"), "CCLabelBMFont"):setString(self.m_showList[self.m_showIndex].val)
	self:getNode("node_rand_pos_sequare"):getParent():addChild(digitView, 10)
	
end

function fightBossView:clickFight()
	CSoundMgr:instance():PlayEffect(SOUND_BUTTON)
	
	if self:isFightOK() == 0 then
		GetMainMenu():ShowTextTip(localizable.fightBoss_status_4,-1);
		return nil
	end
	
	if self.m_current_life <= 0 then
		GetMainMenu():ShowTextTip(localizable.fightBoss_status_2,-1);
		return nil
	end
	
	if self.m_fight_left_times <= 0 then
		local dlg = fightBossClearCdDialog:create()
		fightBossClearCdDialog.m_selfview = dlg
		dlg:setData(self.m_fight_resttime, self.m_clearcd_cost, self)
		dlg:initUI()
		GetMainMenu():AddDialog(dlg, 3)
		return nil
	end

	local playerMgr = CPlayerDataMgr:instance()
	local playerData = playerMgr:GetPlayerInfoData()
	local uid = playerData.m_uid
	local urlpath = GetUrlNormalHeader(uid,2,"rl_w_xiao_war")
	
	GetMainMenu():ShowLoadingDlg();
	CCHttpRequest:openWithUserData(urlpath, kHttpPost, p, "query=param1&other=params"):sendWithHandler(
	function(res, hnd)
		local p = res:getHttpRequest():getUserData()
		local resData = res:getResponseData();			
		local code = res:getResponseCode()
		local xfile = xml.parse(resData)
		local item = xfile:find("RENLONG")
		if item == nil then
			GetMainMenu():CloseLoadding();
			return nil
		end
		local retcode = item.code
		if retcode == "0" then			
			GetMainMenu():CloseLoadding();
			
			local fightinfo = item:find("fight")
			local resultData = CFightResultData:instance()
			resultData:Clear()
			InitFightXML(fightinfo, resultData)
			resultData:SetFightType(FT_BOSS)
			--resultData:SetFightbossDamageTimes(self.m_damage_times/100)
			
			local awardXML
			local hasAward = false
			for i = 1, #item do
				if item[i][0] == "award" then
					hasAward = true
					awardXML = item[i]
				end
			end
			if hasAward == true then
				InitAwardData(resultData:GetRewardData(),awardXML)
				CPlayerDataMgr:instance():AddDataFromReward(resultData:GetRewardData())
			end
			
			local fightview = CRoundFightView:new()
			fightview:init()
			GetMainMenu():addChild(fightview,5)
			fightview:Start()
			fightview:release()
			
			local bossinfo = item:find("xiao")
			self.m_current_life = tonumber(bossinfo:find("restlife")[1])
			self.m_my_reputation = self.m_my_reputation + tonumber(bossinfo:find("award")[1])
			--增加每次挑战BOSS获得声望浮动提示
			GetMainMenu():ShowTextTip(string.format(localizable.fightBoss_fight_reputation, tostring(bossinfo:find("award")[1])), -1)
			
			local currentLifeStr = self:getLifeStr(self.m_current_life)
			local totalLifeStr = self:getLifeStr(self.m_total_life)
			tolua.cast(self:getNode("label_boss_life"), "CCLabelTTF"):setString(currentLifeStr.."/"..totalLifeStr)
			tolua.cast(self:getNode("sprite_blood"), "CCScale9Sprite"):setScaleX(self.m_current_life/self.m_total_life)
			
			self.m_this_total_hurt = tonumber(bossinfo:find("outputalltime")[1])
			tolua.cast(self:getNode("label_current_damage"), "CCLabelTTF"):setString(self.m_this_total_hurt)
			
			if self.m_fight_left_times > 0 then
				self.m_fight_left_times = self.m_fight_left_times - 1
				tolua.cast(self:getNode("label_pk_limit"), "CCLabelTTF"):setString(self.m_fight_left_times.."/"..self.m_fight_attack_total)
			end
			if self.m_fight_left_times <= 0 then
				self.m_fight_resttime = self.m_fight_cd_total
			end

			--litao_2014.8.1
			local timeStr = tools.convertTimeElectronicWatch(self.m_fight_resttime, 3)
			self.label_cd_time:setString(timeStr)
			
			if self.m_current_life <= 0 then
				self:LoadInfoData()
			end
		else
			GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
			GetMainMenu():CloseLoadding();
		end
	end)
end

function fightBossView:clickDice()
	CSoundMgr:instance():PlayEffect(SOUND_BUTTON)
	
	if self:isFightOK() == 0 then
		GetMainMenu():ShowTextTip(localizable.fightBoss_status_4,-1);
		return nil
	end
	
	local dlg = CommonDialogView.create()
	CommonDialogView.m_selfview = dlg;
	dlg:SetTitle(localizable.ui_rouletteLayer_title)
	dlg:SetDescription(string.format(localizable.fightBoss_cost_tip_desc, tostring(self.m_dice_cost)))
	dlg:loadCCBI();
	dlg:SetConfirmHandler(
		function()
			local playerMgr = CPlayerDataMgr:instance()
			local playerData = playerMgr:GetPlayerInfoData()
			local uid = playerData.m_uid
			local urlpath = GetUrlNormalHeader(uid,3,"rl_w_xiao")
			GetMainMenu():ShowLoadingDlg();
			CCHttpRequest:openWithUserData(urlpath, kHttpPost, p, "query=param1&other=params"):sendWithHandler(
			function(res, hnd)
				local p = res:getHttpRequest():getUserData()
				local resData = res:getResponseData();			
				local code = res:getResponseCode()
				local xfile = xml.parse(resData)
				local item = xfile:find("RENLONG")
				if item == nil then
					GetMainMenu():CloseLoadding();
					return nil
				end
				local retcode = item.code
				if retcode == "0" then			
					GetMainMenu():CloseLoadding();		
					self.m_damage_times = tonumber(item:find("result").combo)
					local gold = CPlayerDataMgr:instance():GetPlayerInfoData().m_gold-self.m_dice_cost
					CPlayerDataMgr:instance():SetGold(gold)
					self:ShowDice()					
				else
					GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
					GetMainMenu():CloseLoadding();
				end
			end)
		end)
	dlg:initUI()
	GetMainMenu():GetModelLayer():AddDialog(dlg, 3);

	return nil
	
	
end

function fightBossView:ShowDice()
	self.m_diceView = LuaSubView:create()
	if self.m_diceView == nil then
		return nil
	end
	self.m_diceView:LoadCCBI("animations/DiceAnim.ccbi",CCSize(90,85));
	self.m_diceView:setTag(100)
	self.m_diceView:setAnchorPoint(ccp(0.5, 0.5))
	self.m_diceView:setPosition(self:getNode("btn_dice"):getPosition())
	
	self:getNode("btn_dice"):setVisible(false)
	
	--[[local diceFrame = self:GetDiceImg(self.m_damage_times)
	
	if diceFrame ~= nil then
		tolua.cast(self.m_diceView:getNode("sprite_dice_number"),"CCSprite"):setDisplayFrame(diceFrame)
	end]]
	
	tolua.cast(self.m_diceView:getNode("label_dice_number"), "CCLabelBMFont"):setString(self:GetDiceStr(self.m_damage_times))
	
	local function animationFinished()
		GetMainMenu():CloseLoadding()
		if self.disappear ~= nil then
		 	CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.disappear)
         	self.disappear = nil
         	self.m_diceView:removeFromParentAndCleanup(true) 
			
			local damageStr = localizable.fightBoss_hurt_desc..self:GetDiceStr(self.m_damage_times)
			tolua.cast(self:getNode("label_damage_times"), "CCLabelTTF"):setString(damageStr)
			self:getNode("btn_dice"):setVisible(true)
		end
	end
	self.disappear = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(animationFinished, 1, false)
	self:getNode("btn_dice"):getParent():addChild(self.m_diceView, 100)
	GetMainMenu():ShowUnvisibleLoadingDlg()
end

function fightBossView:clickHero()
	local dlg = fightBossHeroDialog:create()
	fightBossHeroDialog.m_selfview = dlg
	dlg:setRankData(self.m_lastshot_player,self.m_this_total_hurt,self.m_this_score,self.m_my_reputation, self)
	dlg:setExtraData(self.m_this_total_hurt,self.m_damageL1,self.m_repL1,self.m_damageL2,self.m_repL2,self.m_damageL3,self.m_repL3,self)
	dlg:initUI()
	GetMainMenu():AddDialog(dlg, 3);
	
	return nil
end

function fightBossView:clickUp()
	if self:isFightOK() == 0 then
		GetMainMenu():ShowTextTip(localizable.fightBoss_status_4,-1);
		return nil
	end
	
	if self.m_current_life <= 0 then
		GetMainMenu():ShowTextTip(localizable.fightBoss_status_2,-1);
		return nil
	end
	
	local dlg = fightBossEnhanceDialogView:create()
	fightBossEnhanceDialogView.m_selfview = dlg
	dlg:setData(self.m_silver_up_cost, self.m_gold_up_cost, self.m_silver_up_value, self.m_silver_up_max, self.m_gold_up_value, self.m_gold_up_max, self.m_up_total, self)
	dlg:initUI()
	GetMainMenu():AddDialog(dlg, 3);
	
	return nil
end

function fightBossView:clickDetail()
	local dlg = fightBossDetailView:create()
	fightBossDetailView.m_selfview = dlg
	dlg:setData(self.m_lastshot_reputation, self.m_in_reputation, self.m_rankdata, self.m_boss_level)
	dlg:setExtraData(self.m_damageL1,self.m_repL1,self.m_damageL2,self.m_repL2,self.m_damageL3, self.m_repL3)
	dlg:initUI()
	GetMainMenu():AddDialog(dlg, 3)
	
	return nil
end

function fightBossView:LoadInfoData()
	local playerMgr = CPlayerDataMgr:instance()
	local playerData = playerMgr:GetPlayerInfoData()
	local uid = playerData.m_uid
	local urlpath = GetUrlNormalHeader(uid,1,"rl_w_xiao")
	GetMainMenu():ShowLoadingDlg();
	CCHttpRequest:openWithUserData(urlpath, kHttpPost, p, "query=param1&other=params"):sendWithHandler(
	function(res, hnd)
		local p = res:getHttpRequest():getUserData()
		local resData = res:getResponseData();		
		local code = res:getResponseCode()
		local xfile = xml.parse(resData)
		local item = xfile:find("RENLONG")
		if item == nil then
			GetMainMenu():CloseLoadding();
			return nil
		end
		cclog("%s", resData)
		local retcode = item.code
		if retcode == "0" then			
			self:parseInfoData(item)
			self:updateUI()
			GetMainMenu():CloseLoadding();				
		else
			GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
			GetMainMenu():CloseLoadding();
		end
		
	end)
end

function fightBossView:LoadBossInfo()
	local playerMgr = CPlayerDataMgr:instance()
	local playerData = playerMgr:GetPlayerInfoData()
	local uid = playerData.m_uid
	local urlpath = GetUrlNormalHeader(uid,8,"rl_w_xiao")
	GetMainMenu():ShowUnvisibleLoadingDlg();
	CCHttpRequest:openWithUserData(urlpath, kHttpPost, p, "query=param1&other=params"):sendWithHandler(
	function(res, hnd)
		local p = res:getHttpRequest():getUserData()
		local resData = res:getResponseData();			
		local code = res:getResponseCode()
		local xfile = xml.parse(resData)
		local item = xfile:find("RENLONG")
		if item == nil then
			GetMainMenu():CloseLoadding();
			return nil
		end
		local retcode = item.code
		if retcode == "0" then			
			self.m_current_life = tonumber(item:find("restlife")[1])
			local currentLifeStr = self:getLifeStr(self.m_current_life)
			local totalLifeStr = self:getLifeStr(self.m_total_life)
			tolua.cast(self:getNode("label_boss_life"), "CCLabelTTF"):setString(currentLifeStr.."/"..totalLifeStr)
			tolua.cast(self:getNode("sprite_blood"), "CCScale9Sprite"):setScaleX(self.m_current_life/self.m_total_life)
			
			self.m_this_total_hurt = tonumber(item:find("totlehurt")[1])
			self.m_my_rank = tonumber(item:find("myrank")[1])
			
			tolua.cast(self:getNode("label_current_damage"), "CCLabelTTF"):setString(self.m_this_total_hurt)
			tolua.cast(self:getNode("label_current_rank"), "CCLabelTTF"):setString(self.m_my_rank)
			
			GetMainMenu():CloseLoadding();
			self:LoadFightMsg()
		else
			GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
			GetMainMenu():CloseLoadding();
		end
		
	end)
end

function fightBossView:LoadFightMsg()
	local playerMgr = CPlayerDataMgr:instance()
	local playerData = playerMgr:GetPlayerInfoData()
	local uid = playerData.m_uid
	local urlpath = GetUrlNormalHeader(uid,11,"rl_w_xiao")
	urlpath = AddData(urlpath, "MsgImportID", fightBossMsgImportantId)
	urlpath = AddData(urlpath, "MsgNormalID", fightBossMsgNormalId)
	GetMainMenu():ShowUnvisibleLoadingDlg();
	CCHttpRequest:openWithUserData(urlpath, kHttpPost, p, "query=param1&other=params"):sendWithHandler(
	function(res, hnd)
		local p = res:getHttpRequest():getUserData()
		local resData = res:getResponseData();			
		local code = res:getResponseCode()
		local xfile = xml.parse(resData)
		local item = xfile:find("RENLONG")
		if item == nil then
			GetMainMenu():CloseLoadding();
			return nil
		end
		local retcode = item.code
		if retcode == "0" then			
			self:parseFightData(item)
			self:updateUI()
			GetMainMenu():CloseLoadding();				
		else
			GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
			GetMainMenu():CloseLoadding();
		end
		
	end)
end

function fightBossView:parseInfoData(data)
	local preview = data:find("preview")
	if preview ~= nil then
		self.m_resttime = tonumber(preview:find("resttime")[1])
		self.m_active = tonumber(preview:find("inact")[1])
		self.m_lastshot_player = preview:find("lastattackman")[1]
		self.m_lastshot_reputation = tonumber(preview:find("lastaward")[1])
		self.m_in_reputation = tonumber(preview:find("commwinaward")[1])
		self.m_dice_cost = tonumber(preview:find("cost")[1])
		self.m_in_failed = tonumber(preview:find("commfailaward")[1])
		self.m_boss_level = tonumber(preview:find("level")[1])
		self.m_clearcd_cost = tonumber(preview:find("cdcost")[1])
		self.m_fight_cd_total = tonumber(preview:find("cdalltime")[1])
		self.m_fight_attack_total = tonumber(preview:find("cdallnum")[1])
		self.m_gold_up_cost = tonumber(preview:find("cashaddcost")[1])
		self.m_gold_up_value = tonumber(preview:find("cashaddonemin")[1])
		self.m_gold_up_max = tonumber(preview:find("cashaddonemax")[1])
		self.m_silver_up_cost = tonumber(preview:find("coinaddcost")[1])
		self.m_silver_up_value = tonumber(preview:find("coinaddonemin")[1])
		self.m_silver_up_max = tonumber(preview:find("coinaddonemax")[1])
		self.m_periodId = tonumber(preview:find("index")[1])
	end
	
	local userinfo = data:find("user")
	if userinfo ~= nil then
		self.m_damage_times = tonumber(userinfo:find("combo")[1])
		self.m_this_total_hurt = tonumber(userinfo:find("totlehurt")[1])
		self.m_my_reputation = tonumber(userinfo:find("score")[1])
		self.m_this_score = tonumber(userinfo:find("commawardval")[1]) + tonumber(userinfo:find("rankawardval")[1])
		self.m_up_total = tonumber(userinfo:find("coinadd")[1]) + tonumber(userinfo:find("cashadd")[1])
		self.m_fight_resttime = tonumber(userinfo:find("cdresttime")[1])
		self.m_fight_left_times = tonumber(userinfo:find("cdrestnum")[1])
		self.m_my_rank = tonumber(userinfo:find("rank")[1])
	end
	
	local npcinfo = data:find("npc")
	if npcinfo ~= nil then
		self.m_current_life = tonumber(npcinfo:find("restlife")[1])
		self.m_total_life = tonumber(npcinfo:find("totleblood")[1])
		self.m_bossicon = npcinfo:find("icon")[1]
		self.m_bossname_icon = npcinfo:find("nameicon")[1]
		self.m_attacktype = tonumber(npcinfo:find("type")[1])
	end
	
	self.m_rewarddata = data:find("exchange")
	self.m_rankdata = data:find("rankhonner")
	
	local damageinfo = data:find("damage")
	self.m_damageL1 = damageinfo[1]:find("attack")[1]
	self.m_repL1 = damageinfo[1]:find("score")[1]
	self.m_damageL2 = damageinfo[2]:find("attack")[1]
	self.m_repL2 = damageinfo[2]:find("score")[1]
	self.m_damageL3 = 0--damageinfo[3]:find("attack")[1]
	self.m_repL3 = 0--damageinfo[3]:find("score")[1]
	
	--self.m_bossicon = "npc11_5"
	--self.m_bossname_icon = "boss_wt_11"
	--self.m_attribute = 1
	--self.m_attacktype = 0
	--self.m_current_life = 34000000
	--self.m_total_life = 65000000
	
	--self.m_lastshot_reputation = 100
	--self.m_in_reputation = 20
	--self.m_dice_cost = 10
	--self.m_my_reputation = 4000
	
	--[[self.m_rewarddata = {}
	self.m_rewarddata[1] = {icon="props_115", reputation=2000}
	self.m_rewarddata[2] = {icon="props_085", reputation=1000}
	self.m_rewarddata[3] = {icon="props_100", reputation=800}]]
	--[[self.m_rankdata = {}
	self.m_rankdata[1] = {rank=1, reputation=2000}
	self.m_rankdata[2] = {rank=2, reputation=1000}
	self.m_rankdata[3] = {rank=3, reputation=800}]]
end

function fightBossView:parseFightData(data)
	self.m_showIndex = 0
	self.m_showList = {}

	local itemList = data:find("import_msg")
	if itemList ~= nil then
		for i = 1, #itemList do
			table.insert(self.m_showList, itemList[i])
			local itemId = tonumber(itemList[i].id)
			if itemId > fightBossMsgImportantId then
				fightBossMsgImportantId = itemId
			end
		end
	end
	
	itemList = data:find("normal_msg")
	if itemList ~= nil then
		for i = 1, #itemList do
			table.insert(self.m_showList, itemList[i])
			local itemId = tonumber(itemList[i].id)
			if itemId > fightBossMsgNormalId then
				fightBossMsgNormalId = itemId
			end
		end
	end
	
	self.m_showInter = self:calcInterval()
	
	
	
	
	--[[self.m_showList[1] = {nick="春爷", val="250"}
	self.m_showList[2] = {nick="林老师", val="2500"}
	self.m_showList[3] = {nick="小朱", val="250000"}
	self.m_showList[4] = {nick="土豪", val="2500000"}
	self.m_showList[5] = {nick="小胖", val="25000000"}
	self.m_showList[6] = {nick="熊猫", val="350"}
	self.m_showList[7] = {nick="辉辉", val="3500"}
	self.m_showList[8] = {nick="左左", val="35000"}
	self.m_showList[9] = {nick="宋哥", val="350000"}
	self.m_showList[10] = {nick="日总", val="3500000"}
	self.m_showList[11] = {nick="半仙", val="450"}
	self.m_showList[12] = {nick="小雨", val="4500"}]]
end

function fightBossView:setViewSize(size)
	self.m_contentsize = size;
end

function fightBossView:getCurrentReputation()
	return self.m_my_reputation
end

function fightBossView:setFightResttime(resttime)
	self.m_fight_resttime = resttime
	if self.m_fight_resttime == 0 then
		self.m_fight_left_times = self.m_fight_attack_total
		tolua.cast(self:getNode("label_pk_limit"), "CCLabelTTF"):setString(self.m_fight_left_times.."/"..self.m_fight_attack_total)
		--litao_2014.8.1
		local timeStr = tools.convertTimeElectronicWatch(self.m_fight_resttime, 3)
		self.label_cd_time:setString(timeStr)
	end
end

function fightBossView:setTotalUp(total)
	self.m_up_total = total
	tolua.cast(self:getNode("label_fight_up"), "CCLabelBMFont"):setString("+"..self.m_up_total.."%")
end

function fightBossView:setCurrentReputation(r)
	self.m_my_reputation = r
	tolua.cast(self:getNode("label_my_current_rep"), "CCLabelBMFont"):setString(self.m_my_reputation)
end

function ShowFightBossView()
	local view = fightBossView:create();
	local activityView = GetActivityView()
	local contentNode = activityView:GetNodeContent()
	view:setViewSize(contentNode:getContentSize())
	view:initUI()
	contentNode:addChild(view)
	view:setTag(123)
end

ShowFightBossView()
