
require "LuaSubView.lua"
require "RLRequest"
require "LuaXml.lua"
require "boxOpenActivityDetailDialog.lua"
require "boxOpenInfoData.lua"
require "CommonDialogView"
require "util/localizable"

boxOpenActivityView=class(
	"boxOpenActivityView",
    function()
        return LuaSubView:create() 
    end
)

--vip
boxOpenActivityView.m_vipframes={'vip_015','vip_003','vip_004','vip_005','vip_006','vip_007','vip_008','vip_009','vip_010','vip_011','vip_012','vip_013','vip_014','vip_s_13','vip_s_14','vip_s_15','vip_s_16','vip_s_17','vip_s_18'}

local m_selfview={};
function boxOpenActivityView:create()
	local view = boxOpenActivityView.new();
	view:SetClearPlist(false);
	boxOpenActivityView.m_selfview = view;
	return view;
end

function boxOpenActivityView:initUI()
	self:LoadCCBI("activity/ActivityBox.ccbi",self.m_contentsize);
	self:loadInfoData()
	self:BindControl()

	self.isBuy = 0
end

function boxOpenActivityView:updateUI()
	self.isBuy = 0
	for i = 1, 3 do
		--local doubleAward = self.m_info[i]:find("double")[1]
		--local keyNumber = self.m_info[i]:find("count")[1]
		local doubleAward = self.m_info[i].double 
		local keyNumber = self.m_info[i].count
		local doubleSpriteName = "sprite_times"..tostring(i)
		local keyCountName = "label_key_num"..tostring(i)
		
		if doubleAward ~= 0 then
			self:getNode(doubleSpriteName):setVisible(true)
		else
			self:getNode(doubleSpriteName):setVisible(false)
		end
		
		tolua.cast(self:getNode(keyCountName), "CCLabelBMFont"):setString(keyNumber)
		
	end

	--显示金箱子次数限制
	local _left_times = tonumber(self.m_info[1].total_times - self.m_info[1].opened_times)
	if _left_times < 0 then
		_left_times = 0
	end

	local _goldbox_times = tostring(_left_times.."/"..self.m_info[1].total_times)
	tolua.cast(self:getNode("label_left_times"), "CCLabelBMFont"):setString(tostring(_goldbox_times))--_left_times))
	--next vip icon
	local playerMgr = CPlayerDataMgr:instance()
	local viplevel = playerMgr:GetVipLevel()
	local next_vip = viplevel + 2
	if next_vip > #self.m_vipframes then
		next_vip = #self.m_vipframes
	end
	local next_frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(boxOpenActivityView.m_vipframes[next_vip])
	tolua.cast(self:getNode("sprite_next_viplevel"), "CCSprite"):setDisplayFrame(next_frame)
	--add label
	local cur_vipData = DataMgr.GetDataByID("Struct_Vipinfo", tonumber(viplevel + 1))
	local cur_box_num = tostring(cur_vipData.m_vip_fun4_num)
	local next_vip_lv = viplevel + 1
	if next_vip_lv > #self.m_vipframes - 1 then
		tolua.cast(self:getNode("label_next_level_add"), "CCLabelTTF"):setString(localizable.commonBuy_max_vipLv_desc)
	else
		local next_vipData = DataMgr.GetDataByID("Struct_Vipinfo", tonumber(next_vip_lv + 1))
		local next_box_num = tostring(next_vipData.m_vip_fun4_num)
		local label_add = tostring("+"..tonumber(next_box_num-cur_box_num)..localizable.commonBuy_vipLv_add_desc)
		tolua.cast(self:getNode("label_next_level_add"), "CCLabelTTF"):setString(label_add)
	end

end

function boxOpenActivityView:BindControl()
	self.m_chestBtn = {}
	self.m_openChestBtn = {}

	for i = 1, 3 do
		local btnChestName = "btn_chest"..tostring(i)
		local btnOpenName = "btn_open_box"..tostring(i)
		
		self.m_chestBtn[i] = tolua.cast(self:getNode(btnChestName), "CCControlButton")
		boxOpenActivityView.m_selfview:handleButtonEvent(self.m_chestBtn[i], function(button, event)
			self:clickChest(button);
			return nil
		end, CCControlEventTouchUpInside)
		
		self.m_openChestBtn[i] = tolua.cast(self:getNode(btnOpenName), "CCControlButton")
		boxOpenActivityView.m_selfview:handleButtonEvent(self.m_openChestBtn[i], function(button, event)
			self:clickOpen(button);
			return nil
		end, CCControlEventTouchUpInside)
	end
	
	self.m_detail = tolua.cast(self:getNode("btn_detail"), "CCControlButton")
	boxOpenActivityView.m_selfview:handleButtonEvent(self.m_detail, function(button, event)
		self:clickDetail(button)
		return nil
	end, CCControlEventTouchUpInside)
	
end

function boxOpenActivityView:clickDetail(button)
	local dlg = boxOpenActivityDetailDialog:create()
	boxOpenActivityDetailDialog.m_selfview = dlg
	dlg:setInfoData(self.m_goldChestList,self.m_silverChestList,self.m_copperChestList)
	dlg:setTab(1)
	dlg:initUI()
	GetMainMenu():AddDialog(dlg, 3)
end

function boxOpenActivityView:clickChest(button)
	CSoundMgr:instance():PlayEffect(SOUND_BUTTON)
	
	local index = 1
	if button == self.m_chestBtn[1] then
		index = 1
	end
	if button == self.m_chestBtn[2] then
		index = 2
	end
	if button == self.m_chestBtn[3] then
		index = 3
	end
	
	local dlg = boxOpenActivityDetailDialog:create()
	boxOpenActivityDetailDialog.m_selfview = dlg
	dlg:setInfoData(self.m_goldChestList,self.m_silverChestList,self.m_copperChestList)
	dlg:setTab(index)
	dlg:initUI()
	GetMainMenu():AddDialog(dlg, 3)
	
	return nil
end

function boxOpenActivityView:clickOpen(button)
	CSoundMgr:instance():PlayEffect(SOUND_BUTTON)
	--litao_限制刷小号_等级限制_2014.6.24
	local _playerData_ = CPlayerDataMgr:instance():GetPlayerInfoData()
	--get info from table_bin
	local config_info_level = DataMgr.GetDataByID("Struct_Functionconfig", 16)
	--判断等级
	if nil ~= config_info_level then 
	    if _playerData_.m_level < tonumber(config_info_level.m_needlevel) then
			GetMainMenu():ShowTextTip(tostring(config_info_level.m_tipinfo), -1)
			return nil
		end
	end
	
	local index
	if button == self.m_openChestBtn[1] then
		index = 1
		--次数限制
		if self.m_info[index].opened_times >= self.m_info[index].total_times then
			GetMainMenu():ShowTextTip(localizable.boxOpen_open_times_not_enough, -1)
			return nil
		end
	end
	if button == self.m_openChestBtn[2] then
		index = 2
	end
	if button == self.m_openChestBtn[3] then
		index = 3
	end
	
	self.m_selectedChest = index
	
	if self.m_info[index].count <= 0 then
		self:confirmToBuy(self.m_info[index].cost,self.m_info[index].propId,index)
		return nil
	end
	
	self:openChest(self.m_info[index].propId,index)
	
	--[[
	local playerMgr = CPlayerDataMgr:instance()
	local playerData = playerMgr:GetPlayerInfoData()
	local uid = playerData.m_uid
	local urlpath = GetUrlNormalHeader(uid,1,"rl_w_xiao")
	urlpath = AddData(urlpath, "chestId", index)
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
			local award = item:find("award")
			ShowAward(award, "")
			GetMainMenu():CloseLoadding();				
		else
			GetMainMenu():ShowTextTip(text.text_config[tonumber(retcode)].description,-1);
			GetMainMenu():CloseLoadding();
		end
		
	end)]]
	
	return nil
end

function boxOpenActivityView:confirmToBuy(goldCost, propId, index)
	local dlg = CommonDialogView.create()
	CommonDialogView.m_selfview = dlg;
	dlg:SetTitle(localizable.ui_rouletteLayer_title)
	local desc = string.format(localizable.boxOpen_cost_confirm_desc, tostring(goldCost))
	dlg:SetDescription(desc)
	dlg:loadCCBI();
	dlg:SetConfirmHandler(
		function()
			self.isBuy = 1
			self:openChest(propId, index)
		end)
	dlg:initUI()
	GetMainMenu():GetModelLayer():AddDialog(dlg, 3);
end

function boxOpenActivityView:openChest(propId, index)
	local playerMgr = CPlayerDataMgr:instance()
	local playerData = playerMgr:GetPlayerInfoData()
	local uid = playerData.m_uid
	local urlpath = GetUrlNormalHeader(uid,1803,"rl_w_propuse")
	urlpath = AddData(urlpath, "Goodsid", propId)
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
			--金箱子次数限制
			if index == 1 then
				self.m_info[index].opened_times = self.m_info[index].opened_times + 1
			end
			--
			if self.isBuy == 0 then
				if newsCount > 0 then
					newsCount = newsCount - 1
				end
				--将开关上的新消息标志刷新By_litao_2014.1.13
				if ui_activityPopupLayer.getPopupActivityData then
					for k, v in pairs(ui_activityPopupLayer.getPopupActivityData) do
						if v.icon == "activity15" and tonumber(v.newscount) > 0 then
							v.newscount = tonumber(v.newscount) - 1
							CPlayerDataMgr:instance():SetActivityNews("activity15", v.newscount)
							break
						end
					end
				end
				--------------------------------------------
				CPlayerDataMgr:instance():SetActivityNewsNum(newsCount)
				GetActTopBarView():Refresh()
			end
			self.isBuy = 0

			self:parseChestOpenData(item)
			self:updateUI()
		else
			--GetMainMenu():ShowTextTip(text.text_config[tonumber(retcode)].description,-1);
			GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
			--通用付费引导
			if 10006 == tonumber(retcode) then
				--通用付费引导
				local prePayLayer = createObj(ui_commonPrePay)
				GetMainMenu():GetModelLayer():AddDialog(prePayLayer.node_, 3)
			end
		end
		
	end)
end

function boxOpenActivityView:setViewSize(size)
	self.m_contentsize = size;
end

function boxOpenActivityView:loadInfoData()
	local playerMgr = CPlayerDataMgr:instance()
	local playerData = playerMgr:GetPlayerInfoData()
	local uid = playerData.m_uid
	local urlpath = GetUrlNormalHeader(uid,1804,"rl_w_propuse")
	cclog("rl_w_propuse = %s", urlpath)
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
			self:parseInfoData(item)
			self:updateUI()
		else
			--GetMainMenu():ShowTextTip(text.text_config[tonumber(retcode)].description,-1);
			GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
		end
		
	end)
end

function boxOpenActivityView:parseInfoData(data)
	self.m_info = {}
	local propuse_info = data:find("propuse")
	for i = 1, #propuse_info do
		local temp = {}
		temp.double = tonumber(propuse_info[i].bdouble)
		temp.count = tonumber(propuse_info[i].amount)
		temp.propId = tonumber(propuse_info[i].propid)
		temp.cost = tonumber(propuse_info[i].cashcost)

		--次数限制
		temp.total_times = tonumber(propuse_info[i].total)
		temp.opened_times = tonumber(propuse_info[i].opentimes)
		
		self.m_info[i] = temp
	end
	--[[
	self.m_info[1] = {double=1, count=2000}
	self.m_info[2] = {double=0, count=0}
	self.m_info[3] = {double=1, count=800}]]

	self.m_goldChestList = {}
	self.m_silverChestList = {}
	self.m_copperChestList = {}
	
	for i = 1, #boxOpenInfoData do
		local chestId = boxOpenInfoData[i].awardChest
		if chestId == 1 then
			self.m_goldChestList[#self.m_goldChestList+1] = boxOpenInfoData[i]
		elseif chestId == 2 then
			self.m_silverChestList[#self.m_silverChestList+1] = boxOpenInfoData[i]
		elseif chestId == 3 then
			self.m_copperChestList[#self.m_copperChestList+1] = boxOpenInfoData[i]
		end
	end
end

function boxOpenActivityView:parseChestOpenData(data)
	local propuseInfo = data:find("propuse")
	if propuseInfo ~= nil then
		local leftCount = tonumber(propuseInfo.left)
		self.m_info[self.m_selectedChest].count = leftCount
		self.m_info[1].double = tonumber(propuseInfo.golddouble)
		self.m_info[2].double = tonumber(propuseInfo.silverdouble)
		self.m_info[3].double = tonumber(propuseInfo.copperdouble)
		
		local gold = CPlayerDataMgr:instance():GetPlayerInfoData().m_gold-tonumber(propuseInfo.cashcost)
		CPlayerDataMgr:instance():SetGold(gold)
		
		if self.m_info[self.m_selectedChest].double ~= 0 then
			self:playDoubleAnimView()
		else
			local award = propuseInfo:find("award")
			if award ~= nil then
				ShowAward(award)
			end
		end
	end
end

function boxOpenActivityView:playDoubleAnimView()
	local dlg = CommonDialogView.create()
	CommonDialogView.m_selfview = dlg;
	dlg:SetTitle(localizable.ui_rouletteLayer_title)
	dlg:SetDescription(localizable.boxOpen_double_award_desc)
	dlg:loadCCBI();
	dlg:initUI()
	GetMainMenu():GetModelLayer():AddDialog(dlg, 3);
end

function ShowBoxOpenActivity()
	local view = boxOpenActivityView:create();
	local activityView = GetActivityView()
	local contentNode = activityView:GetNodeContent()
	view:setViewSize(contentNode:getContentSize())
	view:initUI()
	contentNode:addChild(view)
	view:setTag(123);
end

ShowBoxOpenActivity()
