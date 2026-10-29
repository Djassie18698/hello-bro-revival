require "LuaSubView.lua"
require "RLRequest"
require "LuaXml.lua"
require "heroRankCellView.lua"
require "bossRewardRuleDialogView"
require "util/text"
require "util/localizable"

fightBossHeroDialog=class(
		"fightBossHeroDialog",
    function()
        return CCLayer:create() 
    end
)

fightBossHeroDialog.m_touchPriority = kCCMenuHandlerPriority-1;

function fightBossHeroDialog_onTouch(event, x, y)
     if event == "began" then   
        return true
    end
end

function fightBossHeroDialog:create()
	local view = fightBossHeroDialog.new();
	return view;
end

function fightBossHeroDialog:loadCCBI()
	local view = LuaSubView:create();	
	local win = CCDirector:sharedDirector():getWinSize();
	view:LoadCCBI("dlg_ui/FightBossRankView.ccbi",CCSize(768,win.height));
	self:addChild(view)
	view:setPosition(CCPoint(win.width / 2, win.height / 2));
	self.m_dlgview = view;
end

function fightBossHeroDialog:initTable()	
	if self.m_tableview ~= nil then
		self.m_tableview:removeFromParentAndCleanup(true)
		self.m_tableview = nil
	end
	
	self:initHandle();
	self.m_contentview = self.m_dlgview:getNode("node_tablecontent");
	local contentsize = self.m_contentview:getContentSize();
	self.m_cellsize = self.m_dlgview:getNode("node_cellcontent"):getContentSize();
	
	local tableview = LuaTableView:createWithHandler(self.m_handler, CCSizeMake(contentsize.width,contentsize.height))
	self.m_tableview = tableview
	tableview:setDirection(kCCScrollViewDirectionVertical);
	tableview:setVerticalFillOrder(kCCTableViewFillTopDown);
	tableview:reloadData()
	self.m_contentview:addChild(tableview);
	tableview:setTouchPriority(fightBossHeroDialog.m_touchPriority);
end

function fightBossHeroDialog:initUI()		
	self:loadCCBI()
	
	self.m_show_this_report = 1
	tolua.cast(self.m_dlgview:getNode("btn_this_report"), "CCControlButton"):setEnabled(false)
	tolua.cast(self.m_dlgview:getNode("btn_his_report"), "CCControlButton"):setEnabled(true)
	tolua.cast(self.m_dlgview:getNode("label_name_damage"), "CCLabelTTF"):setVisible(true)
	tolua.cast(self.m_dlgview:getNode("label_name_reputation"), "CCLabelTTF"):setVisible(false)
	
	self:BindControl()
	self:LoadInfoData()
end

function fightBossHeroDialog:updateUI()
	if self.m_playername ~= nil then
		tolua.cast(self.m_dlgview:getNode("label_lastshot_player"), "CCLabelTTF"):setString(self.m_playername)
	else
		tolua.cast(self.m_dlgview:getNode("label_lastshot_player"), "CCLabelTTF"):setString("")
	end
	tolua.cast(self.m_dlgview:getNode("label_my_damage"), "CCLabelBMFont"):setString(self.m_my_damage)
	tolua.cast(self.m_dlgview:getNode("label_my_rank"), "CCLabelBMFont"):setString(self.m_my_rank)
	tolua.cast(self.m_dlgview:getNode("label_my_reputation"), "CCLabelBMFont"):setString(self.m_my_reputation)
	tolua.cast(self.m_dlgview:getNode("label_this_reputation"), "CCLabelBMFont"):setString(self.m_this_reputation)
	
	self:initTable()
end

function fightBossHeroDialog:LoadInfoData()
	local playerMgr = CPlayerDataMgr:instance()
	local playerData = playerMgr:GetPlayerInfoData()
	local uid = playerData.m_uid
	local urlpath = GetUrlNormalHeader(uid,6,"rl_w_xiao")
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
			self:parseInfoData(item)
			self:updateUI()
			GetMainMenu():CloseLoadding();				
		else
			GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
			GetMainMenu():CloseLoadding();
		end
		
	end)
end

function fightBossHeroDialog:parseInfoData(data)
	local currrank = data:find("currrank")
	self.m_this_report_data = currrank
	self.m_my_rank = tonumber(currrank.my)
	
	local hisrank = data:find("hisrank")
	self.m_his_report_data = hisrank
	
	local previewinfo = data:find("preview")
	if previewinfo ~= nil then
		self.m_this_reputation = tonumber(previewinfo:find("commawardval")[1]) + tonumber(previewinfo:find("rankawardval")[1]) + tonumber(previewinfo:find("hurtawardval")[1])
		self.m_playername = previewinfo:find("lastattackman")[1]
		self.m_hasgot_award = tonumber(previewinfo:find("commaward")[1])
	end
	
	if self.m_hasgot_award == 1 then
		self.m_this_reputation = 0
	end
end

function fightBossHeroDialog:clickRule()
	CSoundMgr:instance():PlayEffect(SOUND_BUTTON)
	
	local dlg = bossRewardRuleDialogView:create()
	bossRewardRuleDialogView.m_selfview = dlg
	dlg:setData(self.m_totalDamage,self.m_damageL1,self.m_repL1,self.m_damageL2,self.m_repL2,self.m_damageL3,self.m_repL3,self)
	dlg:initUI()
	GetMainMenu():AddDialog(dlg, 3);
	
	return nil
end

function fightBossHeroDialog:setExtraData(totalDamage,damageL1,repL1,damageL2,repL2,damageL3,repL3,bossView)
	self.m_totalDamage = totalDamage
	self.m_damageL1 = damageL1
	self.m_repL1 = repL1
	self.m_damageL2 = damageL2
	self.m_repL2 = repL2
	self.m_damageL3 = damageL3
	self.m_repL3 = repL3
	self.m_bossView = bossView
end

function fightBossHeroDialog:initHandle()
	self.m_handler = LuaEventHandler:create(function(fn, table, a1, a2, x, y)
		local r
		if fn == "cellSize" then
			-- Return cell size
			-- a1 is cell index (-1 means default size, in cocos2d-x version below 2.1.3, it's always -1)
			r = self.m_cellsize;
		elseif fn == "cellAtIndex" then
			-- Return CCTableViewCell, a1 is cell index (zero based), a2 is dequeued cell (maybe nil)
			-- Do something to create cell and change the content
			local cell = heroRankCellView:create();
			cell:setIndex(a1);
			if self.m_show_this_report == 1 then
				cell:setCellData(self.m_this_report_data[a1+1])
			else
				cell:setCellData(self.m_his_report_data[a1+1])
			end
			cell:setCellSize(self.m_cellsize);
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
			if self.m_show_this_report == 1 then
				r = #self.m_this_report_data
			else
				r = #self.m_his_report_data
			end
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

function fightBossHeroDialog:setRankData(playername, totalhurt, thisScore, currentScore, bossView)
	self.m_playername = playername
	self.m_my_damage = totalhurt
	self.m_this_reputation = thisScore
	self.m_my_reputation = currentScore
	self.m_bossView = bossView
	return nil
end

function fightBossHeroDialog:setMoraView(view)
	self.m_moraView = view
end

function fightBossHeroDialog:BindControl()
	fightBossHeroDialog.m_selfview:setTouchEnabled(true)
	fightBossHeroDialog.m_selfview:registerScriptTouchHandler(fightBossHeroDialog_onTouch,false,kCCMenuHandlerPriority-1,true)
	fightBossHeroDialog.m_selfview:setTouchMode(0) 
	
	self.m_btn_this_report = tolua.cast(self.m_dlgview:getNode("btn_this_report"), "CCControlButton")
	self.m_btn_his_report = tolua.cast(self.m_dlgview:getNode("btn_his_report"), "CCControlButton")
	self.m_btn_close = tolua.cast(self.m_dlgview:getNode("btnDialogClose"), "CCControlButton")
	self.m_btn_get = tolua.cast(self.m_dlgview:getNode("btn_get_reputation"), "CCControlButton")
	self.m_btn_rule = tolua.cast(self.m_dlgview:getNode("btn_reward_rule"), "CCControlButton")
	
	-- 初始化按钮
	self.m_btn_this_report:setTouchPriority(fightBossHeroDialog.m_touchPriority);
	self.m_dlgview:handleButtonEvent(self.m_btn_this_report, function(button, event)
		self:ClickThisReport();
		return nil
	end, CCControlEventTouchUpInside)
	
	self.m_btn_his_report:setTouchPriority(fightBossHeroDialog.m_touchPriority);
	self.m_dlgview:handleButtonEvent(self.m_btn_his_report, function(button, event)
		self:ClickHisReport();
		return nil
	end, CCControlEventTouchUpInside)
	
	self.m_btn_close:setTouchPriority(fightBossHeroDialog.m_touchPriority);
	self.m_dlgview:handleButtonEvent(self.m_btn_close, function(button, event)
		self:CloseView();
		return nil
	end, CCControlEventTouchUpInside)
	
	self.m_btn_get:setTouchPriority(fightBossHeroDialog.m_touchPriority);
	self.m_dlgview:handleButtonEvent(self.m_btn_get, function(button, event)
		self:GetReputation();
		return nil
	end, CCControlEventTouchUpInside)
	
	self.m_btn_rule:setTouchPriority(fightBossHeroDialog.m_touchPriority);
	self.m_dlgview:handleButtonEvent(self.m_btn_rule, function(button, event)
		self:clickRule();
		return nil
	end, CCControlEventTouchUpInside)
end

function fightBossHeroDialog:CloseView()    
	CSoundMgr:instance():PlayEffect(SOUND_BUTTON)
	
    fightBossHeroDialog.m_selfview:removeFromParentAndCleanup(true);
end

function fightBossHeroDialog:ClickThisReport()
	CSoundMgr:instance():PlayEffect(SOUND_BUTTON)
	
	if self.m_show_this_report == 1 then
		return nil
	end

	self.m_show_this_report = 1
	tolua.cast(self.m_dlgview:getNode("btn_this_report"), "CCControlButton"):setEnabled(false)
	tolua.cast(self.m_dlgview:getNode("btn_his_report"), "CCControlButton"):setEnabled(true)
	tolua.cast(self.m_dlgview:getNode("label_name_damage"), "CCLabelTTF"):setVisible(true)
	tolua.cast(self.m_dlgview:getNode("label_name_reputation"), "CCLabelTTF"):setVisible(false)
	self:initTable()
end

function fightBossHeroDialog:ClickHisReport()
	CSoundMgr:instance():PlayEffect(SOUND_BUTTON)
	
	if self.m_show_this_report == 0 then
		return nil
	end

	self.m_show_this_report = 0
	tolua.cast(self.m_dlgview:getNode("btn_this_report"), "CCControlButton"):setEnabled(true)
	tolua.cast(self.m_dlgview:getNode("btn_his_report"), "CCControlButton"):setEnabled(false)
	tolua.cast(self.m_dlgview:getNode("label_name_damage"), "CCLabelTTF"):setVisible(false)
	tolua.cast(self.m_dlgview:getNode("label_name_reputation"), "CCLabelTTF"):setVisible(true)
	self:initTable()
end

function fightBossHeroDialog:GetReputation()
	CSoundMgr:instance():PlayEffect(SOUND_BUTTON)
	
	local playerMgr = CPlayerDataMgr:instance()
	local playerData = playerMgr:GetPlayerInfoData()
	local uid = playerData.m_uid
	local urlpath = GetUrlNormalHeader(uid,4,"rl_w_xiao")
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
			local awardinfo = item:find("award")
			local commaward = tonumber(awardinfo:find("commawardval")[1])
			local rankaward = tonumber(awardinfo:find("rankawardval")[1])
			local hurtaward = tonumber(awardinfo:find("hurtawardval")[1])
			local reputation = commaward + rankaward + hurtaward
			self.m_this_reputation = 0
			self.m_my_reputation = self.m_my_reputation + reputation
			
			tolua.cast(self.m_dlgview:getNode("label_my_reputation"), "CCLabelBMFont"):setString(self.m_my_reputation)
			tolua.cast(self.m_dlgview:getNode("label_this_reputation"), "CCLabelBMFont"):setString(self.m_this_reputation)
			
			if self.m_bossView ~= nil then
				self.m_bossView:setCurrentReputation(self.m_my_reputation)
			end
			
			GetMainMenu():ShowTextTip(localizable.monthCard_get_success,-1);
			GetMainMenu():CloseLoadding();				
		else
			GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
			GetMainMenu():CloseLoadding();
		end
		
	end)
end



