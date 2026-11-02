require "LuaSubView.lua"
require "RLRequest"
require "LuaXml.lua"
require "util/localizable"

ReNewLevel=class(
		"ReNewLevel",
    function()
        return CCLayer:create() 
    end
)
ReNewLevel.m_selfview={};
ReNewLevel.m_tiptext=localizable.reNewLevel_tiptext;
ReNewLevel.m_levelid = 0;
ReNewLevel.m_backpackview ="";
ReNewLevel.m_dlgview = {};
ReNewLevel.m_touchPriority = kCCMenuHandlerPriority-1;

function ReNewLevel:create()
	local view = ReNewLevel.new();
	ReNewLevel.m_selfview = view;
	return view;
end

function ReNewLevel:loadCCBI()
	local view = LuaSubView:create();	
	local win = CCDirector:sharedDirector():getWinSize();
	view:LoadCCBI("dlg_ui/CommonDialogView.ccbi",CCSize(768,win.height));
	self:addChild(view)
	view:setPosition(CCPoint(win.width / 2, win.height / 2));
	ReNewLevel.m_dlgview = view;
	
	self:initUI();
end

function onTouch(event, x, y)
    if event == "began" then        
        return true
    end
end

function ReNewLevel:initUI()	
	tolua.cast(ReNewLevel.m_dlgview:getNode("labelTitle"), "CCLabelTTF"):setString(ReNewLevel.m_tiptext);
	local text=string.format(localizable.reNewLevel_info1, tostring(ReNewLevel.m_levelname));
	tolua.cast(ReNewLevel.m_dlgview:getNode("labelDescription"), "CCLabelTTF"):setString(text);
	
	ReNewLevel:BindControl();
	self:setTouchEnabled(true)
	self:registerScriptTouchHandler(onTouch,false,ReNewLevel.m_touchPriority,true)
	self:setTouchMode(0) 
	
end

function ReNewLevel:BindControl()

	self.m_btn1 = tolua.cast(ReNewLevel.m_dlgview:getNode("leftButton"), "CCControlButton")
	self.m_btn2 = tolua.cast(ReNewLevel.m_dlgview:getNode("rightButton"), "CCControlButton")
	self.m_btn3 = tolua.cast(ReNewLevel.m_dlgview:getNode("closeButton"), "CCControlButton")	
	self.m_btn1:setTouchPriority(ReNewLevel.m_touchPriority);
	self.m_btn2:setTouchPriority(ReNewLevel.m_touchPriority);
	self.m_btn3:setTouchPriority(ReNewLevel.m_touchPriority);
	--self:setBtn(tolua.cast(ReNewLevel.m_dlgview:getNode("leftButton"), "CCControlButton"));
		-- 初始化按钮
	ReNewLevel.m_dlgview:handleButtonEvent(self.m_btn1, function(button, event)
		self:DoSplit();
		return nil
	end, CCControlEventTouchUpInside)
	ReNewLevel.m_dlgview:handleButtonEvent(self.m_btn2, function(button, event)
		self:CloseView();
		return nil
	end, CCControlEventTouchUpInside)
	ReNewLevel.m_dlgview:handleButtonEvent(self.m_btn3, function(button, event)
		ReNewLevel:CloseView();
		return nil
	end, CCControlEventTouchUpInside)
end

function ReNewLevel:CloseView()    
    ReNewLevel.m_selfview:removeFromParentAndCleanup(true);
end
	
local split_text=localizable.reNewLevel_reNew_success;	
function ReNewLevel:DoSplit()
		local playerMgr = CPlayerDataMgr:instance()
		local playerData = playerMgr:GetPlayerInfoData()
		local uid = playerData.m_uid
		local urlpath = GetUrlNormalHeader(uid,2609,"rl_w_adventure")
		urlpath = AddData(urlpath,"CurChapter",ReNewLevel.m_levelid)
		urlpath = AddData(urlpath,"Type",15)
		urlpath = AddData(urlpath,"CurTime",1)
		urlpath = AddData(urlpath,"CurSubTime",1)
		GetMainMenu():ShowLoadingDlg();
		print(urlpath);
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
				GetMainMenu():ShowTextTip(split_text,-1);
				ReNewLevel.m_levellistview:ReFreshRoundInfo();
			else
				GetMainMenu():ShowErrorTip(retcode,-1);
				--GetMainMenu():ShowTextTip(item.message,-1);
			end				
            ReNewLevel.m_selfview:removeFromParentAndCleanup(true);
		end)
end

function ShowReNewDlg(levelid,strlevelname,levellistview)
	local view = ReNewLevel.create();	
	ReNewLevel.m_levelid = levelid;
	ReNewLevel.m_levelname = strlevelname;
	ReNewLevel.m_levellistview = levellistview;
	view:loadCCBI();
	ReNewLevel.m_selfview = view;
	
	GetMainMenu():GetModelLayer():addChild(view);
end


