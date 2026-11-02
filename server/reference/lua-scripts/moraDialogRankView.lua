require "LuaSubView.lua"
require "RLRequest"
require "LuaXml.lua"
require "moraRankCellView.lua"
require "moraGetPackDialog.lua"
require "util/localizable"

moraDialogRankView=class(
		"moraDialogRankView",
    function()
        return CCLayer:create() 
    end
)

moraDialogRankView.m_touchPriority = kCCMenuHandlerPriority-1;

function moraDialogRankView_onTouch(event, x, y)
     if event == "began" then   
        return true
    end
end

function moraDialogRankView:create()
	local view = moraDialogRankView.new();
	return view;
end

function moraDialogRankView:loadCCBI()
	local view = LuaSubView:create();	
	local win = CCDirector:sharedDirector():getWinSize();
	view:LoadCCBI("dlg_ui/MoraRankDialogView.ccbi",CCSize(768,win.height));
	self:addChild(view)
	view:setPosition(CCPoint(win.width / 2, win.height / 2));
	self.m_dlgview = view;
	
	self:initUI();
end

function moraDialogRankView:initTable()	
	self:initHandle();
	self.m_contentview = self.m_dlgview:getNode("node_tablecontent");
	local contentsize = self.m_contentview:getContentSize();
	self.m_cellsize = self.m_dlgview:getNode("node_cellcontent"):getContentSize();
	local tableview = LuaTableView:createWithHandler(self.m_handler, CCSizeMake(contentsize.width,contentsize.height))
	tableview:setDirection(kCCScrollViewDirectionVertical);
	tableview:setVerticalFillOrder(kCCTableViewFillTopDown);
	tableview:reloadData()
	self.m_contentview:addChild(tableview);
	tableview:setTouchPriority(moraDialogRankView.m_touchPriority);
end

function moraDialogRankView:initUI()	
	self.m_superaward = nil
	for i = 1, #self.m_awardlistdata do
		local awardtype = self.m_awardlistdata[i]:find("gamble_type")[1]
		if awardtype == "2" then
			self.m_superaward = self.m_awardlistdata[i]
		else
			local chest_cost = "label_chest_cost"..i
			tolua.cast(self.m_dlgview:getNode(chest_cost), "CCLabelBMFont"):setString(self.m_awardlistdata[i]:find("gamble_need")[1])
		end
	end
	
	tolua.cast(self.m_dlgview:getNode("label_current_rank"), "CCLabelBMFont"):setString(self.m_currank)
	local fortunestring = tostring(self.m_curfortune).."/"..tostring(self.m_hisfortune)
	tolua.cast(self.m_dlgview:getNode("label_current_fortune"), "CCLabelBMFont"):setString(fortunestring)
	
	if self.m_currank ~= 1 then
		--tolua.cast(self.m_dlgview:getNode("btn_get_award"), "CCControlButton"):setEnabled(false)
	else
		--tolua.cast(self.m_dlgview:getNode("btn_get_award"), "CCControlButton"):setEnabled(true)
	end
	
	self:BindControl()
	self:initTable()
end

function moraDialogRankView:initHandle()
	self.m_handler = LuaEventHandler:create(function(fn, table, a1, a2, x, y)
		local r
		if fn == "cellSize" then
			-- Return cell size
			-- a1 is cell index (-1 means default size, in cocos2d-x version below 2.1.3, it's always -1)
			r = self.m_cellsize;
		elseif fn == "cellAtIndex" then
			-- Return CCTableViewCell, a1 is cell index (zero based), a2 is dequeued cell (maybe nil)
			-- Do something to create cell and change the content
			if not a2 then
				a2 = CCTableViewCell:create()
				local cell = moraRankCellView:create();
				cell:setIndex(a1);
				cell:setCellData(self.m_ranklistdata[a1+1]);
				cell:setCellSize(self.m_cellsize);
				cell:loadCCBI();
				cell:initUI();
				a2:addChild(cell);
				cell:setTag(100);
			else			
				local n = a2:getChildByTag(100);
				local cell = n;
				cell:setIndex(a1);
				cell:setCellData(self.m_ranklistdata[a1+1]);
				cell:initUI();
			end
			
			r = a2
		elseif fn == "numberOfCells" then
			r = #self.m_ranklistdata;
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

function moraDialogRankView:setRankListData(data)
	self.m_ranklistdata = data;
	return nil
end

function moraDialogRankView:setAwardListData(data)
	self.m_awardlistdata = data;
	return nil
end

function moraDialogRankView:setRankData(currank, curforutune, hisfortune)
	self.m_currank = currank
	self.m_curfortune = curforutune
	self.m_hisfortune = hisfortune
	return nil
end

function moraDialogRankView:setMoraView(view)
	self.m_moraView = view
end

function moraDialogRankView:BindControl()
	moraDialogRankView.m_selfview:setTouchEnabled(true)
	moraDialogRankView.m_selfview:registerScriptTouchHandler(moraDialogRankView_onTouch,false,kCCMenuHandlerPriority-1,true)
	moraDialogRankView.m_selfview:setTouchMode(0) 
	
	self.m_btn_getaward = tolua.cast(self.m_dlgview:getNode("btn_get_award"), "CCControlButton")
	self.m_btn_close = tolua.cast(self.m_dlgview:getNode("btnDialogClose"), "CCControlButton")
	self.m_btn_chest1 = tolua.cast(self.m_dlgview:getNode("btn_chest1"), "CCControlButton")
	self.m_btn_chest2 = tolua.cast(self.m_dlgview:getNode("btn_chest2"), "CCControlButton")
	self.m_btn_chest3 = tolua.cast(self.m_dlgview:getNode("btn_chest3"), "CCControlButton")
	self.m_btn_chest4 = tolua.cast(self.m_dlgview:getNode("btn_chest4"), "CCControlButton")
	self.m_btn_superchest = tolua.cast(self.m_dlgview:getNode("btn_superchest"), "CCControlButton")
	
	-- 初始化按钮
	self.m_btn_getaward:setTouchPriority(moraDialogRankView.m_touchPriority);
	self.m_dlgview:handleButtonEvent(self.m_btn_getaward, function(button, event)
		self:GetAward();
		return nil
	end, CCControlEventTouchUpInside)
	
	self.m_btn_close:setTouchPriority(moraDialogRankView.m_touchPriority);
	self.m_dlgview:handleButtonEvent(self.m_btn_close, function(button, event)
		self:CloseView();
		return nil
	end, CCControlEventTouchUpInside)
	
	self.m_btn_chest1:setTouchPriority(moraDialogRankView.m_touchPriority);
	self.m_dlgview:handleButtonEvent(self.m_btn_chest1, function(button, event)
		self:ClickChest1();
		return nil
	end, CCControlEventTouchUpInside)
	
	self.m_btn_chest2:setTouchPriority(moraDialogRankView.m_touchPriority);
	self.m_dlgview:handleButtonEvent(self.m_btn_chest2, function(button, event)
		self:ClickChest2();
		return nil
	end, CCControlEventTouchUpInside)
	
	self.m_btn_chest3:setTouchPriority(moraDialogRankView.m_touchPriority);
	self.m_dlgview:handleButtonEvent(self.m_btn_chest3, function(button, event)
		self:ClickChest3();
		return nil
	end, CCControlEventTouchUpInside)
	
	self.m_btn_chest4:setTouchPriority(moraDialogRankView.m_touchPriority);
	self.m_dlgview:handleButtonEvent(self.m_btn_chest4, function(button, event)
		self:ClickChest4();
		return nil
	end, CCControlEventTouchUpInside)
	
	self.m_btn_superchest:setTouchPriority(moraDialogRankView.m_touchPriority);
	self.m_dlgview:handleButtonEvent(self.m_btn_superchest, function(button, event)
		self:ClickSuperChest();
		return nil
	end, CCControlEventTouchUpInside)
end

function moraDialogRankView:CloseView()    
	CSoundMgr:instance():PlayEffect(SOUND_BUTTON)
    moraDialogRankView.m_selfview:removeFromParentAndCleanup(true);
end

function moraDialogRankView:GetAward()
	CSoundMgr:instance():PlayEffect(SOUND_BUTTON)
	
	local playerMgr = CPlayerDataMgr:instance()
	local playerData = playerMgr:GetPlayerInfoData()
	local uid = playerData.m_uid
	local urlpath = GetUrlNormalHeader(uid,6,"rl_w_comm")

	GetMainMenu():ShowLoadingDlg();
	CCHttpRequest:openWithUserData(urlpath, kHttpPost, p, "query=param1&other=params"):sendWithHandler(
	function(res, hnd)
		GetMainMenu():CloseLoadding();
		local p = res:getHttpRequest():getUserData()
		local resData = res:getResponseData();			
		local code = res:getResponseCode()
		local xfile = xml.parse(resData)
		local item = xfile:find("RENLONG")
		if item == nil then
			return nil
		end
		local retcode = item.code
		if retcode == "0" then			
			local awardXML = xfile:find("award")
			ShowAward(awardXML)
		else
			GetMainMenu():ShowErrorTip(retcode,-1);
		end
	end)
end

function moraDialogRankView:ClickChest1()
	CSoundMgr:instance():PlayEffect(SOUND_BUTTON)
	self:doShowBoxDesc(1)
end

function moraDialogRankView:ClickChest2()
	CSoundMgr:instance():PlayEffect(SOUND_BUTTON)
	self:doShowBoxDesc(2)
end

function moraDialogRankView:ClickChest3()
	CSoundMgr:instance():PlayEffect(SOUND_BUTTON)
	self:doShowBoxDesc(3)
end

function moraDialogRankView:ClickChest4()
	CSoundMgr:instance():PlayEffect(SOUND_BUTTON)
	self:doShowBoxDesc(4)
end

function moraDialogRankView:ClickSuperChest()
	CSoundMgr:instance():PlayEffect(SOUND_BUTTON)
	if self.m_superaward ~= nil then
		local dlg = CommonDialogView.create()
		CommonDialogView.m_selfview = dlg;
		dlg:SetTitle(localizable.mora_dlg_rank_title)
		dlg:SetDescription(self.m_superaward:find("gamble_drop_show")[1])
		dlg:loadCCBI();
		dlg:initUI()
		GetMainMenu():AddDialog(dlg, 3);
	end
end

function moraDialogRankView:doShowBoxDesc(index)
	local dlg = moraGetPackDialog.create()
	moraGetPackDialog.m_selfview = dlg;
	dlg:setMoraView(self)
	dlg:setDescription(self.m_awardlistdata[index]:find("gamble_drop_show")[1])
	dlg:setExchangeId(tonumber(self.m_awardlistdata[index]:find("gamble_id")[1]))
	dlg:initUI()
	GetMainMenu():AddDialog(dlg, 3);
end

function moraDialogRankView:exchangePack(id)
	local playerMgr = CPlayerDataMgr:instance()
	local playerData = playerMgr:GetPlayerInfoData()
	local uid = playerData.m_uid
	local urlpath = GetUrlNormalHeader(uid,5,"rl_w_comm")
	urlpath = AddData(urlpath, "GambleExchangeID", id)
	self.m_packcost = tonumber(self.m_awardlistdata[id]:find("gamble_need")[1])
	
	GetMainMenu():ShowLoadingDlg();
	CCHttpRequest:openWithUserData(urlpath, kHttpPost, p, "query=param1&other=params"):sendWithHandler(
	function(res, hnd)
		GetMainMenu():CloseLoadding();
		local p = res:getHttpRequest():getUserData()
		local resData = res:getResponseData();			
		local code = res:getResponseCode()
		local xfile = xml.parse(resData)
		local item = xfile:find("RENLONG")
		if item == nil then
			return nil
		end
		local retcode = item.code
		if retcode == "0" then			
			
			local awardXML = xfile:find("award")
			ShowAward(awardXML)
			self.m_curfortune = self.m_curfortune - self.m_packcost
			
			tolua.cast(self.m_dlgview:getNode("label_current_rank"), "CCLabelBMFont"):setString(self.m_currank)
			local fortunestring = tostring(self.m_curfortune).."/"..tostring(self.m_hisfortune)
			tolua.cast(self.m_dlgview:getNode("label_current_fortune"), "CCLabelBMFont"):setString(fortunestring)
	
			self.m_moraView:updateFortune(self.m_curfortune)
		else
			GetMainMenu():ShowErrorTip(retcode,-1);
		end
	end)
end


