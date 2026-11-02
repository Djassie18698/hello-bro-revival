require "util/localizable"
require "LuaSubView.lua"
require "RLRequest"
require "LuaXml.lua"
require "CommonDialogView.lua"
require "moraBuyLifeDialog.lua"
require "moraDialogRankView.lua"
require "moraDetailDialogView.lua"
require "util/tools"
require "moraKillConfirmDlg.lua"
local m_moraTouchPoint


moraView=class(
	"moraView",
    function()
        return LuaSubView:create()
    end
)

local m_selfview={};
function moraView:create()
	local view = moraView.new();
	m_selfview = view;
	return view;
end

moraView.mora_inanim=false;

function moraView:initUI()
	self.m_fixstart = 0;
	self.m_rewardcount = 0;
	--获取用户信息
	self.playerMgr_     = CPlayerDataMgr:instance()
	self.playerData_    = self.playerMgr_:GetPlayerInfoData()
	self.mora_betSelected = false;
	--如果期数不同，更新期数
	if activityPeriod.mora.display == -1 then
		writeActivityData(self.playerData_.m_uid, activity_config.activityTipConfig.mora, activityPeriod.mora.period)
	end

	self:LoadCCBI("activity/MoraView.ccbi",self.m_contentsize);
	self:LoadInfoData();
	--self:updateUI()
	self:BindControl()

	local function updateLeftTimeLabel(fDeltaTime)
		self.deltatime = self.deltatime + fDeltaTime
		if self.deltatime >= 1 then
			if self.mora_resttime <= 0 then
				self.mora_timelabel:setString(localizable.mora_not_open)
			else
				self.mora_resttime = self.mora_resttime - 1
				local timeStr = self:gettimelabel(self.mora_resttime)
				self.mora_timelabel:setString(timeStr)
			end
			local intPart, floatPart = math.modf(self.deltatime)
			self.deltatime = floatPart
		end
	end

	self.deltatime = 0;
	self.mora_resttime = 0
	self.mora_timelabel = tolua.cast(self:getNode("label_countdown"), "CCLabelTTF")
	self.mora_timelabel:scheduleUpdateWithPriorityLua(updateLeftTimeLabel, 0)
end

function moraView:gettimelabel(_sec)
	local time = tools.convertTimeToTable(_sec)

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

	if CPlayerDataMgr:instance():GetMoraOpen() == 1 then
		return string.format(localizable.localizable.mora_desc_end, timestr)
	else
		return string.format(localizable.mora_desc_getaward_end, timestr)
	end
end
--[[
moraView.m_touchPriority = kCCMenuHandlerPriority-1;
function moraonTouch(event, x, y)
    local rect = m_selfview:boundingBox();
	rect.origin = ccp(0,0);
	local p = m_selfview:convertToNodeSpace(ccp(x,y));
    if event == "began" then
       if rect:containsPoint(p) == true then
			return true;
	   else
			return false;
	   end
    end

end
]]
function moraView:BindControl()
	self.mora_btn_choice1 = tolua.cast(self:getNode("btn_choice1"), "CCControlButton")
	self.mora_btn_choice2 = tolua.cast(self:getNode("btn_choice2"), "CCControlButton")
	self.mora_btn_choice3 = tolua.cast(self:getNode("btn_choice3"), "CCControlButton")
	self.mora_btn_bet = tolua.cast(self:getNode("btn_ok_frame"), "CCControlButton")
	self.mora_btn_buy_life = tolua.cast(self:getNode("btn_buy_life"), "CCControlButton")
	self.mora_btn_chest = tolua.cast(self:getNode("btn_chest"), "CCControlButton")
	self.mora_btn_detail = tolua.cast(self:getNode("btn_detail"), "CCControlButton")
	self.mora_btn_kill = tolua.cast(self:getNode("btn_killfix"), "CCControlButton")
--[[
	self.mora_btn_choice1:setTouchPriority(moraView.m_touchPriority);
	self.mora_btn_choice2:setTouchPriority(moraView.m_touchPriority);
	self.mora_btn_choice3:setTouchPriority(moraView.m_touchPriority);
	self.mora_btn_bet:setTouchPriority(moraView.m_touchPriority);
	self.mora_btn_buy_life:setTouchPriority(moraView.m_touchPriority);
	self.mora_btn_chest:setTouchPriority(moraView.m_touchPriority);
	self.mora_btn_detail:setTouchPriority(moraView.m_touchPriority);]]

	--[[self:setTouchEnabled(true)
	self:registerScriptTouchHandler(moraonTouch,false,moraView.m_touchPriority,true)
	self:setTouchMode(0)
	self:setContentSize(self.m_contentsize);]]
	moraView.m_selfview:handleButtonEvent(self.mora_btn_choice1, function(button, event)
		self:clickChoice1();
		return nil
	end, CCControlEventTouchUpInside)
	moraView.m_selfview:handleButtonEvent(self.mora_btn_choice2, function(button, event)
		self:clickChoice2();
		return nil
	end, CCControlEventTouchUpInside)
	moraView.m_selfview:handleButtonEvent(self.mora_btn_choice3, function(button, event)
		self:clickChoice3();
		return nil
	end, CCControlEventTouchUpInside)
	moraView.m_selfview:handleButtonEvent(self.mora_btn_bet, function(button, event)
		self:clickBet();
		return nil
	end, CCControlEventTouchUpInside)
	moraView.m_selfview:handleButtonEvent(self.mora_btn_buy_life, function(button, event)
		self:clickBuyLife();
		return nil
	end, CCControlEventTouchUpInside)
	moraView.m_selfview:handleButtonEvent(self.mora_btn_chest, function(button, event)
		self:clickChest();
		return nil
	end, CCControlEventTouchUpInside)
	moraView.m_selfview:handleButtonEvent(self.mora_btn_detail, function(button, event)
		self:clickDetail();
		return nil
	end, CCControlEventTouchUpInside)
	moraView.m_selfview:handleButtonEvent(self.mora_btn_kill, function(button, event)
		self:clickKill();
		return nil
	end, CCControlEventTouchUpInside)
	self.award1 = tolua.cast(self:getNode("btn_reward1"), "CCControlButton")
	self.award1:setTag(1);
	self.award2_1 = tolua.cast(self:getNode("btn_reward2_1"), "CCControlButton")
	self.award2_1:setTag(2)
	self.award2_2 = tolua.cast(self:getNode("btn_reward2_2"), "CCControlButton")
	self.award2_2:setTag(3)
	moraView.m_selfview:handleButtonEvent(self.award1, function(button, event)
		self:ViewAward(1,1);
		return nil
	end, CCControlEventTouchUpInside)

	moraView.m_selfview:handleButtonEvent(self.award2_1, function(button, event)
		self:ViewAward(2,1);
		return nil
	end, CCControlEventTouchUpInside)	

	moraView.m_selfview:handleButtonEvent(self.award2_2, function(button, event)
		self:ViewAward(3,2);
		return nil
	end, CCControlEventTouchUpInside)	
end

function moraView:updateUI()
	for i = 1, 20 do
		local lifename = "sprite_my_life"..tostring(i)
		if i <= self.mora_mylifecount then
			self:getNode(lifename):setVisible(true)
		else
			self:getNode(lifename):setVisible(false)
		end
	end

	tolua.cast(self:getNode("label_luck_value"), "CCLabelBMFont"):setString(self.mora_myluckcount)

	if self.mora_betSelected == true then
		self:getNode("sprite_gamble"):setVisible(true)
	else
		self:getNode("sprite_gamble"):setVisible(false)
	end

	for i = 1, 4 do
		local icon = "sprite_npc_icon"..tostring(i)
		local beaticon = "sprite_npc_beat"..tostring(i)

		local iconsprite = self:getNode(icon)
		local beatsprite = self:getNode(beaticon)

		local ninjaicon = CGameObjElement:GetNinjaIcon(E_FRAMETYPE_SMALL, self.mora_npclistdata[i]:find("icon")[1])
		local ninjasprite = CCSprite:createWithSpriteFrame(ninjaicon)

		if iconsprite ~= nil and ninjasprite ~= nil then
			iconsprite:removeAllChildrenWithCleanup(true)
			iconsprite:addChild(ninjasprite)
			local size = iconsprite:getContentSize()
			ninjasprite:setAnchorPoint(ccp(0.5,0.5))
			ninjasprite:setPosition(ccp(size.width/2,size.height/2))
		end

		if i < self.mora_enemyNo then
			if beatsprite ~= nil then
				beatsprite:setVisible(true)
			end
		else
			if beatsprite ~= nil then
				beatsprite:setVisible(false)
			end
		end
		if i > self.mora_enemyNo then
			if ninjasprite ~= nil then
				local program = CCShaderCache:sharedShaderCache():programForKey("greysprite")
				if program ~= nil then
					ninjasprite:setShaderProgram(program)
				end
			end
		else
			if ninjasprite ~= nil then
				local program = CCShaderCache:sharedShaderCache():programForKey("ShaderPositionTextureColor")
				if program ~= nil then
					ninjasprite:setShaderProgram(program)
				end
			end
		end

		if i == self.mora_enemyNo and iconsprite ~= nil then
			local frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("mo_bk_01")
			if frame ~= nil then
				tolua.cast(iconsprite, "CCSprite"):setDisplayFrame(frame)
			end
		else
			local frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("small_box04")
			if frame ~= nil then
				tolua.cast(iconsprite, "CCSprite"):setDisplayFrame(frame)
			end
		end

		local labelFortune = "label_fortune_get"..tostring(i)
		tolua.cast(self:getNode(labelFortune),"CCLabelTTF"):setString(self.mora_npclistdata[i]:find("addexp")[1])
	end

	local bigninjaicon = CGameObjElement:GetNinjaIcon(E_FRAMETYPE_LARGE, self.mora_npclistdata[self.mora_enemyNo]:find("icon")[1])
	local bigninjasprite = CCSprite:createWithSpriteFrame(bigninjaicon)
	if bigninjasprite ~= nil then
		self:getNode("node_icon"):removeAllChildrenWithCleanup(true)
		self:getNode("node_icon"):addChild(bigninjasprite)
		local size = self:getNode("node_icon"):getContentSize()
		bigninjasprite:setAnchorPoint(ccp(0.5,0.5))
		bigninjasprite:setPosition(ccp(size.width/2,size.height/2))
	end

	tolua.cast(self:getNode("label_npc_words"), "CCLabelTTF"):setString(self.mora_npclistdata[self.mora_enemyNo]:find("gamble_show_text")[1])

	for i = 1, 20 do
		local lifename = "sprite_npc_life"..tostring(i)
		if i <= self.mora_npclifecount then
			self:getNode(lifename):setVisible(true)
		else
			self:getNode(lifename):setVisible(false)
		end
	end

	local timeStr = self:gettimelabel(self.mora_resttime)
	self.mora_timelabel:setString(timeStr)

	self.m_currtkillaward = self.mora_npclistdata[self.mora_enemyNo]:find("award");
	local items = self.m_currtkillaward;
	local length = #self.m_currtkillaward;
	self.m_rewardcount = length;
	if length == 1 then
		moraView.m_selfview:getNode("sprite_reward1"):setVisible(true);
		moraView.m_selfview:getNode("sprite_reward2"):setVisible(false);
		self:initAwardIcon(items[1],"sprite_icon1","label_num1");
	

	elseif length == 2 then

		moraView.m_selfview:getNode("sprite_reward1"):setVisible(false);
		moraView.m_selfview:getNode("sprite_reward2"):setVisible(true);	
		self:initAwardIcon(items[1],"sprite_icon2_1","label_num2_1");
		self:initAwardIcon(items[2],"sprite_icon2_2","label_num2_2");
		
	else
		moraView.m_selfview:getNode("sprite_reward1"):setVisible(false);
		moraView.m_selfview:getNode("sprite_reward2"):setVisible(false);
	end
end

function moraView:startGamble(npcid, choiceid,iskill)
	CSoundMgr:instance():PlayEffect(SOUND_BUTTON)

	local playerMgr = CPlayerDataMgr:instance()
	local playerData = playerMgr:GetPlayerInfoData()
	local uid = playerData.m_uid
	local urlpath = GetUrlNormalHeader(uid,4,"rl_w_comm")
	if self.mora_betSelected == true then
		urlpath = AddData(urlpath, "GambleType", 2)
	else
		urlpath = AddData(urlpath, "GambleType", 1)
	end
	if iskill == nil then
		urlpath = AddData(urlpath, "GambleMustWin", 0)
	else	
		urlpath = AddData(urlpath, "GambleMustWin", iskill)
	end
	urlpath = AddData(urlpath, "GambleNPCID", npcid)
	self.mora_selected_choice = choiceid

	GetMainMenu():ShowLoadingDlg();
	CCHttpRequest:openWithUserData(urlpath, kHttpPost, p, "query=param1&other=params"):sendWithHandler(
	function(res, hnd)
		local p = res:getHttpRequest():getUserData()
		local resData = res:getResponseData();
		local code = res:getResponseCode()
		local xfile = xml.parse(resData)
		local item = xfile:find("RENLONG")
		local retcode = item.code
		if retcode == "0" then
			GetMainMenu():CloseLoadding();
			self:parseGambleData(item)
		else
			GetMainMenu():ShowErrorTip(retcode,-1);
			GetMainMenu():CloseLoadding();
		end
	end)
end

function moraView:playAnimation(choice1, choice2, result)
	self.mora_animView = LuaSubView:create()
	if self.mora_animView == nil then
		return nil
	end
	local win = CCDirector:sharedDirector():getWinSize()
	if result == 0 then		
		if self.m_fixstart == 1 then
			self.mora_animView:LoadCCBI("animations/chaiquan_kill.ccbi",CCSize(768,win.height));
		else
		    self.mora_animView:LoadCCBI("animations/chaiquan.ccbi",CCSize(768,win.height));
		end
	else
		self.mora_animView:LoadCCBI("animations/chaiquan_fail.ccbi",CCSize(768,win.height));		
	end
	self.mora_animView:setTag(100)
	self.mora_animView:setAnchorPoint(ccp(0.5, 0.5))
	self.mora_animView:setPosition(win.width / 2, win.height / 2)
	self.mora_animView:ignoreAnchorPointForPosition(false)

	local npc_choice = self:getChoiceSprite(choice1)
	local my_choice = self:getChoiceSprite(choice2)
	local play_result = self:getResultSprite(result)
	if self.m_fixstart == 0 then
		if npc_choice ~= nil and my_choice ~= nil and play_result ~= nil then
			tolua.cast(self.mora_animView:getNode("sprite_npc_big"),"CCSprite"):setDisplayFrame(npc_choice)
			tolua.cast(self.mora_animView:getNode("sprite_my_big"),"CCSprite"):setDisplayFrame(my_choice)
			tolua.cast(self.mora_animView:getNode("sprite_win_result"),"CCSprite"):setDisplayFrame(play_result)
		else
			return nil
		end
	end
	local function animationFinished()
		GetMainMenu():CloseLoadding()
		if self.disappear ~= nil then
		 	CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.disappear)
         	self.disappear = nil
         	self.mora_animView:removeFromParentAndCleanup(true)
			self.mora_inanim = false
			self:updateUI()
			self.m_fixstart = 0;
			if self.mora_award ~= nil then
				ShowAward(self.mora_award)
				self.mora_award = nil
			end
		end
	end
	self.disappear = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(animationFinished, 2.2, false)
	self:addChild(self.mora_animView, 100)
	self.mora_inanim = true
	GetMainMenu():ShowUnvisibleLoadingDlg()
end

function moraView:getChoiceSprite(choice)
	local sprite = nil
	local frame = nil
	if choice == 1 then
		frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("mo_scissors_big")
	elseif choice == 2 then
		frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("mo_stone_big")
	elseif choice == 3 then
		frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("mo_cloth_big")
	end
	return frame
end

function moraView:getResultSprite(res)
	local sprite = nil
	local frame = nil
	if res == 1 then
		frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("mo_tie")
	elseif res == 2 then
		frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("mo_failure")
	elseif res == 0 then
		frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("mo_victory")
	end
	return frame
end

function moraView:onCallBack()
	self.m_fixstart = 1;
	self:startGamble(self.mora_current_npcid, 1,1)
end

function moraView:clickChoice1()
	CSoundMgr:instance():PlayEffect(SOUND_BUTTON)

	if self.mora_inanim == true then
		return nil
	end

	self:startGamble(self.mora_current_npcid, 1)
	return nil
end

function moraView:clickChoice2()
	CSoundMgr:instance():PlayEffect(SOUND_BUTTON)

	if self.mora_inanim == true then
		return nil
	end

	self:startGamble(self.mora_current_npcid, 2)
	return nil
end

function moraView:clickChoice3()
	CSoundMgr:instance():PlayEffect(SOUND_BUTTON)

	if self.mora_inanim == true then
		return nil
	end

	self:startGamble(self.mora_current_npcid, 3)
end

function moraView:clickBet()
	CSoundMgr:instance():PlayEffect(SOUND_BUTTON)

	if self.mora_inanim == true then
		return nil
	end

	if self.mora_betSelected == true then
		self.mora_betSelected = false
		self:getNode("sprite_gamble"):setVisible(false)
		GetMainMenu():ShowTextTip(localizable.mora_normal_text_tip,-1);
	else
		self.mora_betSelected = true
		self:getNode("sprite_gamble"):setVisible(true)
		GetMainMenu():ShowTextTip(localizable.mora_gamele_text_tip,-1);
	end
	return nil
end

function moraView:clickBuyLife()
	CSoundMgr:instance():PlayEffect(SOUND_BUTTON)

	if self.mora_inanim == true then
		return nil
	end

	local dlg = moreBuyLifeDialog:create()
	moreBuyLifeDialog.m_selfview = dlg
	dlg:setData(self.mora_oneLifeCost, self.mora_fullLifeCost)
	dlg:setMoraView(self)
	dlg:initUI()
	GetMainMenu():AddDialog(dlg, 3);

	return nil
end
--必杀
function moraView:clickKill()
	local dlg = moraKillConfirmDlg:create();
	dlg:initUI();
	dlg:setConfirmCallback(function()
		self:onCallBack();
	 end);	
	local count = 5;
	if self.mora_npclifecount > self.mora_mylifecount then
		count = self.mora_mylifecount;
	else
		count = self.mora_npclifecount;
	end
	if count > 5 then
		count = 5;
	end
	if self.mora_betSelected == false then
		count = 1;
	end
	local price = tonumber(self.mora_npclistdata[self.mora_enemyNo]:find("gamble_mustwin")[1])*count;
	dlg:setKillPrice(price);
	GetMainMenu():AddDialog(dlg, 3);
end
function moraView:clickChest()
	--CSoundMgr:instance():PlayEffect(SOUND_BUTTON)

	if self.mora_inanim == true then
		return nil
	end

	local playerMgr = CPlayerDataMgr:instance()
	local playerData = playerMgr:GetPlayerInfoData()
	local uid = playerData.m_uid
	local urlpath = GetUrlNormalHeader(uid,3,"rl_r_comm")
	GetMainMenu():ShowLoadingDlg();
	CCHttpRequest:openWithUserData(urlpath, kHttpPost, p, "query=param1&other=params"):sendWithHandler(
	function(res, hnd)
		local p = res:getHttpRequest():getUserData()
		local resData = res:getResponseData();
		local code = res:getResponseCode()
		local xfile = xml.parse(resData)
		local item = xfile:find("RENLONG")
		local retcode = item.code
		if retcode == "0" then
			GetMainMenu():CloseLoadding();
			self:parseMoraData(item)

			local dlg = moraDialogRankView:create()
			moraDialogRankView.m_selfview = dlg
			dlg:setRankListData(self.mora_rankdata)
			dlg:setAwardListData(self.mora_awardlistdata)
			dlg:setMoraView(self)
			dlg:setRankData(self.mora_myrank, self.mora_myluckcount, self.mora_hisluckcount)
			dlg:loadCCBI()
			GetMainMenu():AddDialog(dlg, 3);
		else
			GetMainMenu():ShowErrorTip(retcode,-1);
			GetMainMenu():CloseLoadding();
		end
	end)

	return nil
end

local detaliText = localizable.mora_detail_text_info

function moraView:clickDetail()
	CSoundMgr:instance():PlayEffect(SOUND_BUTTON)

	if self.mora_inanim == true then
		return nil
	end

	local dlg = moraDetailDialogView:create()
	moraDetailDialogView.m_selfview = dlg
	dlg:initUI()
	GetMainMenu():AddDialog(dlg, 3);
	return nil
end

function moraView:LoadInfoData()
	local playerMgr = CPlayerDataMgr:instance()
	local playerData = playerMgr:GetPlayerInfoData()
	local uid = playerData.m_uid
	local urlpath = GetUrlNormalHeader(uid,3,"rl_r_comm")
	GetMainMenu():ShowLoadingDlg();
	CCHttpRequest:openWithUserData(urlpath, kHttpPost, p, "query=param1&other=params"):sendWithHandler(
	function(res, hnd)
		local p = res:getHttpRequest():getUserData()
		local resData = res:getResponseData();
		local code = res:getResponseCode()
		local xfile = xml.parse(resData)
		local item = xfile:find("RENLONG")
		local retcode = item.code
		if retcode == "0" then
			self:parseMoraData(item)
			self:updateUI()
		else
			GetMainMenu():ShowErrorTip(retcode,-1);
		end

		GetMainMenu():CloseLoadding();
	end)
end

function moraView:parseMoraData(data)
	local mydata = data:find("my")
	if mydata ~= nil then
		self.mora_mylifecount = tonumber(mydata:find("mylife")[1])
		self.mora_myluckcount = tonumber(mydata:find("currluckypoint")[1])
		self.mora_hisluckcount = tonumber(mydata:find("historylickypoint")[1])
		self.mora_enemyNo = tonumber(mydata:find("npcpos")[1])
		self.mora_npclifecount = tonumber(mydata:find("npclife")[1])
		self.mora_resttime = tonumber(mydata:find("resttime")[1])
		self.mora_oneLifeCost = tonumber(mydata:find("addone")[1])
		self.mora_fullLifeCost = tonumber(mydata:find("addall")[1])
		self.mora_myrank = tonumber(mydata:find("myrank")[1])
		self.mora_costval = tonumber(mydata:find("myrank")[1])
	end

	self.mora_rankdata = data:find("rank")
	local infodata = data:find("info")
	if infodata ~= nil then
		self.mora_npclistdata = data:find("npclist")
		self.mora_awardlistdata = data:find("awardlist")

		self.mora_current_npcid = tonumber(self.mora_npclistdata[self.mora_enemyNo]:find("id")[1])
	end	
end
function moraView:initAwardIcon(itemdata,spritename,labelname)
	local folder = itemdata["folder"];
	local namestr = itemdata["name"];
	local count = tonumber(itemdata["num"]);
	CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile(folder.."/"..namestr..".plist");
	local frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(namestr)
	local ninjasprite = CCSprite:createWithSpriteFrame(frame)
	local iconframe = tolua.cast(moraView.m_selfview:getNode(spritename), "CCSprite");
	local size = iconframe:getContentSize();
	ninjasprite:setPosition(ccp(size.width/2,size.height/2));
	ninjasprite:setAnchorPoint(ccp(0.5,0.5));
	iconframe:removeAllChildrenWithCleanup(true);
	iconframe:addChild(ninjasprite);
	if count > 1 then
		tolua.cast(moraView.m_selfview:getNode(labelname), "CCLabelTTF"):setString("X"..count);
		tolua.cast(moraView.m_selfview:getNode(labelname), "CCLabelTTF"):setVisible(true);
	else
		tolua.cast(moraView.m_selfview:getNode(labelname), "CCLabelTTF"):setVisible(false);
	end
end
function moraView:ViewAward(tag,index)
	if self.m_rewardcount == 1 then
		if index == 1 and tag == 1 then	
			CGameObjElement:ShowDropByID(tonumber(self.m_currtkillaward[index]["dropid"]));
		end
	elseif self.m_rewardcount == 2 then
		if tag ~= 1 then
			CGameObjElement:ShowDropByID(tonumber(self.m_currtkillaward[index]["dropid"]));
		end
	end

end
function moraView:parseGambleData(data)
	local mydata = data:find("preview")

	if mydata ~= nil then
		self.mora_mylifecount = tonumber(mydata:find("mylife")[1])
		self.mora_enemyNo = tonumber(mydata:find("npcpos")[1])
		self.mora_npclifecount = tonumber(mydata:find("npclife")[1])
		self.mora_myluckcount = tonumber(mydata:find("currluckypoint")[1])
		self.mora_hisluckcount = tonumber(mydata:find("historylickypoint")[1])
		self.mora_gamble_res = tonumber(mydata:find("res")[1])
		self.mora_fullLifeCost = tonumber(mydata:find("addall")[1])
		self.mora_mustwincost = tonumber(mydata:find("totlecash")[1])
		--计算必胜后的元宝数量
		local gold = CPlayerDataMgr:instance():GetPlayerInfoData().m_gold-self.mora_mustwincost
		CPlayerDataMgr:instance():SetGold(gold)


		if self.mora_npclistdata ~= nil then
			self.mora_current_npcid = tonumber(self.mora_npclistdata[self.mora_enemyNo]:find("id")[1])
		end

		local npc_choice
		if self.mora_gamble_res == 1 then
			npc_choice = self.mora_selected_choice
		elseif self.mora_gamble_res == 0 then
			if self.mora_selected_choice == 1 then
				npc_choice = 3
			elseif self.mora_selected_choice == 2 then
				npc_choice = 1
			elseif self.mora_selected_choice == 3 then
				npc_choice = 2
			end
		elseif self.mora_gamble_res == 2 then
			if self.mora_selected_choice == 1 then
				npc_choice = 2
			elseif self.mora_selected_choice == 2 then
				npc_choice = 3
			elseif self.mora_selected_choice == 3 then
				npc_choice = 1
			end
		end
		self:playAnimation(npc_choice, self.mora_selected_choice, self.mora_gamble_res)
	end

	self.mora_award = data:find("award")
	return nil
end

function moraView:buyOneLife()
	self:doBuyLife(1)
end

function moraView:buyFullLife()
	self:doBuyLife(2)
end

function moraView:updateFortune(fortune)
	self.mora_myluckcount = fortune
	tolua.cast(self:getNode("label_luck_value"), "CCLabelBMFont"):setString(self.mora_myluckcount)
end

function moraView:doBuyLife(buytype)
	local playerMgr = CPlayerDataMgr:instance()
	local playerData = playerMgr:GetPlayerInfoData()
	local uid = playerData.m_uid
	local urlpath = GetUrlNormalHeader(uid,7,"rl_w_comm")
	urlpath = AddData(urlpath, "GambleCashType", buytype)

	GetMainMenu():ShowLoadingDlg();
	CCHttpRequest:openWithUserData(urlpath, kHttpPost, p, "query=param1&other=params"):sendWithHandler(
	function(res, hnd)
		local p = res:getHttpRequest():getUserData()
		local resData = res:getResponseData();
		local code = res:getResponseCode()
		local xfile = xml.parse(resData)
		local item = xfile:find("RENLONG")
		local retcode = item.code
		if retcode == "0" then
			if buytype == 1 then
				local gold = CPlayerDataMgr:instance():GetPlayerInfoData().m_gold-self.mora_oneLifeCost
				CPlayerDataMgr:instance():SetGold(gold)

				if self.mora_mylifecount < 20 then
					self.mora_mylifecount = self.mora_mylifecount + 1
				end
			elseif buytype == 2 then
				local gold = CPlayerDataMgr:instance():GetPlayerInfoData().m_gold-self.mora_fullLifeCost
				CPlayerDataMgr:instance():SetGold(gold)

				self.mora_mylifecount = 20
			end
			self:updateUI()
			GetMainMenu():CloseLoadding();
		else
			GetMainMenu():ShowErrorTip(retcode,-1);
			GetMainMenu():CloseLoadding();
		end
	end)
end