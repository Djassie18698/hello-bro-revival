require "LuaSubView.lua"
require "RLRequest"
require "LuaXml.lua"
require ("util/common_const")
require "util/localizable"

BuyRemenDlg=class(
		"BuyRemenDlg",
    function()
        return CCLayer:create() 
    end
)
BuyRemenDlg.m_selfview={};
BuyRemenDlg.m_data={};
BuyRemenDlg.m_cardbagid = 0;
BuyRemenDlg.smallItemcount=0;
BuyRemenDlg.bigItemcount=0;
BuyRemenDlg.smallItemName=localizable.buyRemenDlg_smallRemenName;
BuyRemenDlg.bigItemName=localizable.buyRemenDlg_bigRemenName;

BuyRemenDlg.smallItemIcon="props_016";
BuyRemenDlg.bigItemIcon="props_017";

BuyRemenDlg.selectedItemCount=0;
BuyRemenDlg.selectedItemID=0;
BuyRemenDlg.m_dlgview = {};
BuyRemenDlg.m_touchPriority = kCCMenuHandlerPriority-1;
BuyRemenDlg.text_buy = localizable.commonBuy_buy_desc;
BuyRemenDlg.text_use = localizable.commonBuy_use_desc;
BuyRemenDlg.m_buybtn={};
BuyRemenDlg.m_smallitemdata={};
BuyRemenDlg.m_bigitemdata={};
BuyRemenDlg.m_selectitemdata={};
BuyRemenDlg.m_selectitemdatabig=0;
function BuyRemenDlg:create()
	local view = BuyRemenDlg.new();
	BuyRemenDlg.m_selfview = view;
	BuyRemenDlg.m_smallitemdata=nil;
	BuyRemenDlg.m_bigitemdata=nil;
	BuyRemenDlg.m_selectitemdata=nil;
	BuyRemenDlg.smallItemcount=0;
    BuyRemenDlg.bigItemcount=0;
	return view;
end

function BuyRemenDlg:loadCCBI()
	local view = LuaSubView:create();	
	local win = CCDirector:sharedDirector():getWinSize();
	view:LoadCCBI("dlg_ui/buyremenDialogView.ccbi",CCSize(768,win.height));
	self:addChild(view)
	view:setPosition(CCPoint(win.width / 2, win.height / 2));
	BuyRemenDlg.m_dlgview = view;
	
	self:initUI();
end

function onTouch(event, x, y)
    if event == "began" then        
        return true
    end
end
function BuyRemenDlg:initCount(label,count)
	local smalltext = count.."";
	if count > 99 then
		smalltext = "99+";
	end
	tolua.cast(BuyRemenDlg.m_dlgview:getNode(label), "CCLabelBMFont"):setString(smalltext);
end
function BuyRemenDlg:initSelectedUI(itemdata,count,islight1)

	BuyRemenDlg.m_selectitemdata = itemdata;
	BuyRemenDlg.selectedItemCount = count;
	local iconname=BuyRemenDlg.m_selectitemdata["m_icon"];
	local pathName = "props/"..iconname..".plist";
	CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile(pathName);
	
	local sprite_icon = CCSprite:createWithSpriteFrameName(iconname);
	--sprite_icon:setScale(1.1);
	--BuyRemenDlg.m_dlgview:getNode("node_icon3"):removeAllChildren();
	BuyRemenDlg.m_dlgview:getNode("node_icon3"):addChild(sprite_icon);	
	local rect = BuyRemenDlg.m_dlgview:getNode("node_icon3"):boundingBox();
	sprite_icon:setPosition(ccp(rect.size.width/2,rect.size.height/2));
	sprite_icon:setAnchorPoint(ccp(0.5,0.5));
	tolua.cast(BuyRemenDlg.m_dlgview:getNode("label_hascount3"), "CCLabelBMFont"):setString(count.."");
	tolua.cast(BuyRemenDlg.m_dlgview:getNode("lable_itemname"), "CCLabelTTF"):setString(itemdata["m_namestr"]);
	
	if count > 0 then
		BuyRemenDlg.m_buybtn:setTitleForState(BuyRemenDlg.text_use,CCControlStateNormal);
		BuyRemenDlg.m_buybtn:setTitleForState(BuyRemenDlg.text_use,CCControlStateHighlighted);
		BuyRemenDlg.m_buybtn:setTitleForState(BuyRemenDlg.text_use,CCControlStateSelected);
		BuyRemenDlg.m_dlgview:getNode("sprite_pricebk"):setVisible(false);
	else
		BuyRemenDlg.m_buybtn:setTitleForState(BuyRemenDlg.text_buy,CCControlStateNormal);
		BuyRemenDlg.m_buybtn:setTitleForState(BuyRemenDlg.text_buy,CCControlStateHighlighted);
		BuyRemenDlg.m_buybtn:setTitleForState(BuyRemenDlg.text_buy,CCControlStateSelected);
		BuyRemenDlg.m_dlgview:getNode("sprite_pricebk"):setVisible(true);
		tolua.cast(BuyRemenDlg.m_dlgview:getNode("label_itemprice"), "CCLabelBMFont"):setString(itemdata.m_needgold.."");
	end
	if islight1==1 then
		BuyRemenDlg.m_dlgview:getNode("sprite_higilight1"):setVisible(true);
		BuyRemenDlg.m_dlgview:getNode("sprite_higilight2"):setVisible(false);
	else
		BuyRemenDlg.m_dlgview:getNode("sprite_higilight1"):setVisible(false);
		BuyRemenDlg.m_dlgview:getNode("sprite_higilight2"):setVisible(true);
	end
	BuyRemenDlg.m_selectitemdatabig = islight1;
end
function BuyRemenDlg:initUI()	
	local playerMgr = CPlayerDataMgr:instance()
    local playerData = playerMgr:GetPlayerInfoData()
	local maxbodyval = playerMgr:GetMaxBodyValue();
	local currbodyval = playerData.m_bodyvalue;
	local textbodyval = currbodyval.."/"..maxbodyval;
	tolua.cast(BuyRemenDlg.m_dlgview:getNode("lable_currbodyval"), "CCLabelBMFont"):setString(textbodyval);
	BuyRemenDlg.m_dlgview:getNode("labelDescription"):setVisible(true);
	BuyRemenDlg.m_dlgview:getNode("lable_lasttimes"):setVisible(true);
	local resttext = CTradeMgr:instance():GetRemenLimitRest().."";--.."/"..CTradeMgr:instance():GetRemenLimitTotal();
	tolua.cast(BuyRemenDlg.m_dlgview:getNode("lable_lasttimes"), "CCLabelBMFont"):setString(resttext);
	BuyRemenDlg.smallItemcount = CTradeMgr:instance():GetConsumItemCountByID(common_const.ITEM_SMALL_REMEN_ID);
	BuyRemenDlg.bigItemcount = CTradeMgr:instance():GetConsumItemCountByID(common_const.ITEM_BIG_REMEN_ID);
	self:initCount("label_hascount1",BuyRemenDlg.smallItemcount);
	self:initCount("label_hascount2",BuyRemenDlg.bigItemcount);
	
	BuyRemenDlg.m_smallitemdata = DataMgr.GetDataByID("Struct_Consumeinfo",common_const.ITEM_SMALL_REMEN_ID);
	BuyRemenDlg.m_bigitemdata = DataMgr.GetDataByID("Struct_Consumeinfo",common_const.ITEM_BIG_REMEN_ID);
	
    tolua.cast(BuyRemenDlg.m_dlgview:getNode("label_minieffect"), "CCLabelBMFont"):setString("+"..BuyRemenDlg.m_smallitemdata.m_para1);
	tolua.cast(BuyRemenDlg.m_dlgview:getNode("label_bigeffect"), "CCLabelBMFont"):setString("+"..BuyRemenDlg.m_bigitemdata.m_para1);
	
	local iconname =BuyRemenDlg.m_smallitemdata["m_icon"];
	local pathName = "props/"..iconname..".plist";
	CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile(pathName);
	local sprite_icon = CCSprite:createWithSpriteFrameName(iconname);
	BuyRemenDlg.m_dlgview:getNode("node_icon1"):addChild(sprite_icon);
	local rect = BuyRemenDlg.m_dlgview:getNode("node_icon1"):boundingBox();
	sprite_icon:setPosition(ccp(rect.size.width/2,rect.size.height/2));
	sprite_icon:setAnchorPoint(ccp(0.5,0.5));
	
	local iconname1 =BuyRemenDlg.m_bigitemdata["m_icon"];
	local pathName1 = "props/"..iconname1..".plist";
	CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile(pathName1);
	local sprite_icon1 = CCSprite:createWithSpriteFrameName(iconname1);
	BuyRemenDlg.m_dlgview:getNode("node_icon2"):addChild(sprite_icon1);
	local rect1 = BuyRemenDlg.m_dlgview:getNode("node_icon2"):boundingBox();
	sprite_icon1:setPosition(ccp(rect1.size.width/2,rect1.size.height/2));
	sprite_icon1:setAnchorPoint(ccp(0.5,0.5));
	
	BuyRemenDlg:BindControl();
	self:setTouchEnabled(true)
	self:registerScriptTouchHandler(onTouch,false,BuyRemenDlg.m_touchPriority,true)
	self:setTouchMode(0) 
	if BuyRemenDlg.smallItemcount > 0 then
		self:initSelectedUI(BuyRemenDlg.m_smallitemdata,BuyRemenDlg.smallItemcount,1);
	else
		self:initSelectedUI(BuyRemenDlg.m_bigitemdata,BuyRemenDlg.bigItemcount,0);
		
	end
end

function BuyRemenDlg:BindControl()

	local btn1 = tolua.cast(BuyRemenDlg.m_dlgview:getNode("leftButton"), "CCControlButton")
	local btn2 = tolua.cast(BuyRemenDlg.m_dlgview:getNode("rightButton"), "CCControlButton")
	local btn3 = tolua.cast(BuyRemenDlg.m_dlgview:getNode("closeButton"), "CCControlButton")
	local btn4 = tolua.cast(BuyRemenDlg.m_dlgview:getNode("rightBuyOruse"), "CCControlButton")	
	btn1:setTouchPriority(BuyRemenDlg.m_touchPriority);
	btn2:setTouchPriority(BuyRemenDlg.m_touchPriority);
	btn3:setTouchPriority(BuyRemenDlg.m_touchPriority);
	btn4:setTouchPriority(BuyRemenDlg.m_touchPriority);
	BuyRemenDlg.m_buybtn = btn4;
	--self:setBtn(tolua.cast(BuyRemenDlg.m_dlgview:getNode("leftButton"), "CCControlButton"));
		-- 初始化按钮
	BuyRemenDlg.m_dlgview:handleButtonEvent(btn1, function(button, event)
		self:SelectSmall();
		return nil
	end, CCControlEventTouchUpInside)
	BuyRemenDlg.m_dlgview:handleButtonEvent(btn2, function(button, event)
		self:SelectBig();
		return nil
	end, CCControlEventTouchUpInside)
	BuyRemenDlg.m_dlgview:handleButtonEvent(btn3, function(button, event)
		BuyRemenDlg:CloseView();
		return nil
	end, CCControlEventTouchUpInside)
	
	BuyRemenDlg.m_dlgview:handleButtonEvent(btn4, function(button, event)
		BuyRemenDlg:DoUseView();
		return nil
	end, CCControlEventTouchUpInside)
end
function BuyRemenDlg:SelectSmall()
	self:initSelectedUI(BuyRemenDlg.m_smallitemdata,BuyRemenDlg.smallItemcount,1);
end
function BuyRemenDlg:SelectBig()
	self:initSelectedUI(BuyRemenDlg.m_bigitemdata,BuyRemenDlg.bigItemcount,0);
end
function BuyRemenDlg:CloseView()    
    BuyRemenDlg.m_selfview:removeFromParentAndCleanup(true);
end

function BuyRemenDlg:DobuyIt()    
     if BuyRemenDlg.selectedItemCount == 0 then --using
		local playerMgr = CPlayerDataMgr:instance()
		local playerData = playerMgr:GetPlayerInfoData()
		local uid = playerData.m_uid
		local urlpath = GetUrlNormalHeader(uid,1700,"rl_w_shopbuy")
		urlpath = AddData(urlpath,"Goodsid",BuyRemenDlg.m_selectitemdata.m_id)
		urlpath = AddData(urlpath,"Count",1)
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
				local awardXML = xfile:find("shopbuy")					
				local costyb = awardXML["costyb"];
				local costyz = awardXML["costyz"];
				playerMgr:AddGold(-costyb);
				playerMgr:AddSilver(-costyz);
				BuyRemenDlg.selectedItemCount = 1
				CTradeMgr:instance():SetConsumItemCountByID(BuyRemenDlg.m_selectitemdata.m_id,BuyRemenDlg.selectedItemCount);
				self:DoUseIt();
			else
				GetMainMenu():ShowErrorTip(retcode,-1);
				--GetMainMenu():ShowTextTip(item.message,-1);
			end				
            --BuyRemenDlg.m_selfview:removeFromParentAndCleanup(true);
		end)
		--//buy using
	end
end
function BuyRemenDlg:DoUseView()  
	if BuyRemenDlg.selectedItemCount > 0 then 
		self:DoUseIt();
	else
		self:DobuyIt();
	end
end
 function BuyRemenDlg:DoUseIt()  
	--BuyRemenDlg.m_selectitemdata = itemdata;
	--BuyRemenDlg.selectedItemCount = count;
    if BuyRemenDlg.selectedItemCount > 0 then --using
		local playerMgr = CPlayerDataMgr:instance()
		local playerData = playerMgr:GetPlayerInfoData()
		local uid = playerData.m_uid
		local urlpath = GetUrlNormalHeader(uid,1800,"rl_w_propuse")
		urlpath = AddData(urlpath,"Goodsid",BuyRemenDlg.m_selectitemdata.m_id)
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
				local awardXML = xfile:find("propuse")					
				local awardvalu = awardXML["ap"];
				CTradeMgr:instance():SetConsumItemCountByID(BuyRemenDlg.m_selectitemdata.m_id,BuyRemenDlg.selectedItemCount-1);
				playerMgr:SetBodyValue(awardvalu);				
				GetMainMenu():GetCurrentSubMenu():InitNormalHeader();
				local restcount = CTradeMgr:instance():GetRemenLimitRest();
				CTradeMgr:instance():SetRemenLimitRest(tonumber(awardXML["rest"]));
				CTradeMgr:instance():SetRemenLimitTotal(tonumber(awardXML["max"]));
				if tonumber(awardvalu) >= playerMgr:GetMaxBodyValue() then
					BuyRemenDlg.m_selfview:removeFromParentAndCleanup(true);
				else
				
					BuyRemenDlg.m_selfview:removeFromParentAndCleanup(true);
					ShowBuyRemenDlg();
					--[[local co = BuyRemenDlg.selectedItemCount-1;
					if co >0 then
						self:initSelectedUI(BuyRemenDlg.m_selectitemdata,BuyRemenDlg.selectedItemCount-1,BuyRemenDlg.m_selectitemdatabig);
					else
						BuyRemenDlg.m_selfview:removeFromParentAndCleanup(true);
						ShowBuyRemenDlg();
					end]]
				end
			else
				GetMainMenu():ShowErrorTip(retcode,-1);
				--GetMainMenu():ShowTextTip(item.message,-1);
				BuyRemenDlg.m_selfview:removeFromParentAndCleanup(true);
			end	
			
			
            --BuyRemenDlg.m_selfview:removeFromParentAndCleanup(true);
		end)
		--//buy using
	end
end
--[[
local split_text="拆卡成功";	
function BuyRemenDlg:DoSplit()
		local playerMgr = CPlayerDataMgr:instance()
		local playerData = playerMgr:GetPlayerInfoData()
		local uid = playerData.m_uid
		local urlpath = GetUrlNormalHeader(uid,1400,"rl_w_split_card")
		urlpath = AddData(urlpath,"i",BuyRemenDlg.m_cardbagid)
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
				CPlayerDataMgr:instance():RemoveObjByID(BuyRemenDlg.m_cardbagid);
				getMyBackpackView():ReFreshData();
				GetMainMenu():GetCurrentSubMenu():InitNormalHeader();
			else
				GetMainMenu():ShowErrorTip(retcode,-1);
				--GetMainMenu():ShowTextTip(item.message,-1);
			end				
            BuyRemenDlg.m_selfview:removeFromParentAndCleanup(true);
		end)
end
]]
function ShowBuyRemenDlg()
	local view = BuyRemenDlg.create();	
	view:loadCCBI();	
	BuyRemenDlg.m_selfview = view;	
	GetMainMenu():GetModelLayer():addChild(view);
end


