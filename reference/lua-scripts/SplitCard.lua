require "LuaSubView.lua"
require "RLRequest"
require "LuaXml.lua"
require "util/localizable"

SplitCardView=class(
		"SplitCardView",
    function()
        return CCLayer:create() 
    end
)
SplitCardView.m_selfview={};
SplitCardView.m_tiptext=localizable.splitCard_tiptext;
SplitCardView.m_data={};
SplitCardView.m_cardbagid = 0;
SplitCardView.m_backpackview ="";
SplitCardView.m_dlgview = {};
SplitCardView.m_touchPriority = kCCMenuHandlerPriority-1;

function SplitCardView:create()
	local view = SplitCardView.new();
	SplitCardView.m_selfview = view;
	return view;
end

function SplitCardView:loadCCBI()
	local view = LuaSubView:create();	
	local win = CCDirector:sharedDirector():getWinSize();
	view:LoadCCBI("dlg_ui/CommonDialogView.ccbi",CCSize(768,win.height));
	self:addChild(view)
	view:setPosition(CCPoint(win.width / 2, win.height / 2));
	SplitCardView.m_dlgview = view;
	
	self:initUI();
end

function onTouch(event, x, y)
    if event == "began" then        
        return true
    end
end

function SplitCardView:initUI()	
	tolua.cast(SplitCardView.m_dlgview:getNode("labelTitle"), "CCLabelTTF"):setString(SplitCardView.m_tiptext);
	local card = CPlayerDataMgr:instance():GetObjectByID(self.m_cardbagid);
	local name = card:GetName();
	local text=string.format(localizable.splitCard_info1, name)
	tolua.cast(SplitCardView.m_dlgview:getNode("labelDescription"), "CCLabelTTF"):setString(text);
	
	SplitCardView:BindControl();
	self:setTouchEnabled(true)
	self:registerScriptTouchHandler(onTouch,false,SplitCardView.m_touchPriority,true)
	self:setTouchMode(0) 
	
end

function SplitCardView:BindControl()

	local btn1 = tolua.cast(SplitCardView.m_dlgview:getNode("leftButton"), "CCControlButton")
	local btn2 = tolua.cast(SplitCardView.m_dlgview:getNode("rightButton"), "CCControlButton")
	local btn3 = tolua.cast(SplitCardView.m_dlgview:getNode("closeButton"), "CCControlButton")	
	btn1:setTouchPriority(SplitCardView.m_touchPriority);
	btn2:setTouchPriority(SplitCardView.m_touchPriority);
	btn3:setTouchPriority(SplitCardView.m_touchPriority);
	--self:setBtn(tolua.cast(SplitCardView.m_dlgview:getNode("leftButton"), "CCControlButton"));
		-- 初始化按钮
	SplitCardView.m_dlgview:handleButtonEvent(btn1, function(button, event)
		self:DoSplit();
		return nil
	end, CCControlEventTouchUpInside)
	SplitCardView.m_dlgview:handleButtonEvent(btn2, function(button, event)
		self:CloseView();
		return nil
	end, CCControlEventTouchUpInside)
	SplitCardView.m_dlgview:handleButtonEvent(btn3, function(button, event)
		SplitCardView:CloseView();
		return nil
	end, CCControlEventTouchUpInside)
end

function SplitCardView:CloseView()    
    SplitCardView.m_selfview:removeFromParentAndCleanup(true);
end
	
local split_text=localizable.splitCard_split_success;	
function SplitCardView:DoSplit()
		local playerMgr = CPlayerDataMgr:instance()
		local playerData = playerMgr:GetPlayerInfoData()
		local uid = playerData.m_uid
		local urlpath = GetUrlNormalHeader(uid,1400,"rl_w_split_card")
		urlpath = AddData(urlpath,"i",SplitCardView.m_cardbagid)
		GetMainMenu():ShowLoadingDlg();
		CCHttpRequest:openWithUserData(urlpath, kHttpPost, p, "query=param1&other=params"):sendWithHandler(
		function(res, hnd)
			GetMainMenu():CloseLoadding();
			local p = res:getHttpRequest():getUserData()
			local resData = res:getResponseData()
			local code = res:getResponseCode()
			local xfile = xml.parse(resData)
			local item = xfile:find("RENLONG")
			local retcode = item.code
				if item == nil then
			    return;
			end
			if retcode == "0" then	
				local awardXML = xfile:find("award")	
				GetMainMenu():ShowTextTip(split_text,-1);	
				ShowAward(awardXML);	
				CPlayerDataMgr:instance():RemoveObjByID(SplitCardView.m_cardbagid);
				getMyBackpackView():ReFreshData();
				GetMainMenu():GetCurrentSubMenu():InitNormalHeader();
			else
				GetMainMenu():ShowErrorTip(retcode,-1);
				--GetMainMenu():ShowTextTip(item.message,-1);
			end				
            SplitCardView.m_selfview:removeFromParentAndCleanup(true);
		end)
end

function ShowSplitDlg(bagid)
	local view = SplitCardView.create();
	
	view.m_cardbagid = bagid;
	view:loadCCBI();
	SplitCardView.m_cardbagid = bagid;
	
	SplitCardView.m_selfview = view;
	
	GetMainMenu():GetModelLayer():addChild(view);
end


