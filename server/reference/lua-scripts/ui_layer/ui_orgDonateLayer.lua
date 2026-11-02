----------------------------------------------------------------------
--  Copyright (c) 2014-2016, XCKOO. All Rights Reserved.
--  Author :Tango
--  Time   :2014/11/22 16:21:53
--  Remark :供奉主页
----------------------------------------------------------------------
module("ui_orgDonateLayer", package.seeall)
baseClass(layer_base_t, ui_orgDonateLayer)


function init(self)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	self.contentSize_ = GetMainMenu():GetSubContentNode():getContentSize()
	local ccbiAttrTable = {name="sub_ui/OrgDonateView.ccbi", size=self.contentSize_}
	layer_base_t.init(self, true, ccbiAttrTable)

	--pre page
	self.back_page = E_DEFAULTMENU

	self.btnDonate = {nil,nil,nil,nil}
	self.data = {}
    --init
	self:init_ui()
	self:init_binding_event()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		--node
		self.node_content = tolua.cast(self.proxy_:getNode("node_content"), "CCNode")
		self.node_cell = tolua.cast(self.proxy_:getNode("node_cell"), "CCNode")
		--btn
		self.btn_back = tolua.cast(self.proxy_:getNode("btn_back"), "CCControlButton")
		self.btnManage = tolua.cast(self.proxy_:getNode("btn_manage"), "CCControlButton")
		self.btnSetting = tolua.cast(self.proxy_:getNode("btn_setting"), "CCControlButton")
		self.btnUpgrade = tolua.cast(self.proxy_:getNode("btn_upgrade"), "CCControlButton")

		for i=1,4 do
			self.btnDonate[i] = tolua.cast(self.proxy_:getNode("btn_excute_"..tostring(i)), "CCControlButton")
			self.btnDonate[i]:setTag(i)
		end
		
		-- label
		self.label_donate_cash = tolua.cast(self.proxy_:getNode("label_donate_cash"),"CCLabelTTF")
		self.label_addBuild_1 = tolua.cast(self.proxy_:getNode("label_addBuild_1"),"CCLabelTTF")
		self.label_addContribution_1 = tolua.cast(self.proxy_:getNode("label_addContribution_1"),"CCLabelTTF")

		self.label_addBuild_2_4 = tolua.cast(self.proxy_:getNode("label_addBuild_2_4"),"CCLabelTTF") 
		self.label_addContribution_2_4 = tolua.cast(self.proxy_:getNode("label_addContribution_2_4"),"CCLabelTTF") 
		self.label_addBuild_2_5 = tolua.cast(self.proxy_:getNode("label_addBuild_2_5"),"CCLabelTTF") 
		self.label_addContribution_2_5 = tolua.cast(self.proxy_:getNode("label_addContribution_2_5"),"CCLabelTTF")

		self.label_addBuild_3_4 = tolua.cast(self.proxy_:getNode("label_addBuild_3_4"),"CCLabelTTF") 
		self.label_addContribution_3_4 = tolua.cast(self.proxy_:getNode("label_addContribution_3_4"),"CCLabelTTF") 
		self.label_addBuild_3_5 = tolua.cast(self.proxy_:getNode("label_addBuild_3_5"),"CCLabelTTF") 
		self.label_addContribution_3_5 = tolua.cast(self.proxy_:getNode("label_addContribution_3_5"),"CCLabelTTF") 

		self.label_addBuild_4_4 = tolua.cast(self.proxy_:getNode("label_addBuild_4_4"),"CCLabelTTF") 
		self.label_addContribution_4_4 = tolua.cast(self.proxy_:getNode("label_addContribution_4_4"),"CCLabelTTF") 
		self.label_addBuild_4_5 = tolua.cast(self.proxy_:getNode("label_addBuild_4_5"),"CCLabelTTF") 
		self.label_addContribution_4_5 = tolua.cast(self.proxy_:getNode("label_addContribution_4_5"),"CCLabelTTF") 
		
		self.labelMyScore = tolua.cast(self.proxy_:getNode("label_myscore"),"CCLabelTTF") 

		self:initTopBar()
		self:init_ext_topBar()

		--base request
		self:requestBaseLayerInfo()
	end
end

function initTopBar(self)
	if self.proxy_ ~= nil then
		self.sprite_playermedal = tolua.cast(self.proxy_:getNode("sprite_playermedal"), "CCSprite")
		self.label_level = tolua.cast(self.proxy_:getNode("label_level"), "CCLabelBMFont")
		self.label_curexp = tolua.cast(self.proxy_:getNode("label_curexp"), "CCLabelBMFont")
		self.label_name = tolua.cast(self.proxy_:getNode("label_name"), "CCLabelTTF")
		self.sprite_vipinfo = tolua.cast(self.proxy_:getNode("sprite_vipinfo"), "CCSprite")
		self.label_bodyval = tolua.cast(self.proxy_:getNode("label_bodyval"), "CCLabelBMFont")
		self.label_attackval = tolua.cast(self.proxy_:getNode("label_attackval"), "CCLabelBMFont")
		self.label_goldval = tolua.cast(self.proxy_:getNode("label_goldval"), "CCLabelBMFont")
		self.label_silverval = tolua.cast(self.proxy_:getNode("label_silverval"), "CCLabelBMFont")
		self.ctrl_btnplayermsg = tolua.cast(self.proxy_:getNode("ctrl_btnplayermsg"), "CCControlButton")
		self.sprite_levelstate = tolua.cast(self.proxy_:getNode("sprite_levelstate"), "CCSprite")
		self.sprite_bodyratio = tolua.cast(self.proxy_:getNode("sprite_bodyratio"), "CCSprite")
		self.sprite_attackratio = tolua.cast(self.proxy_:getNode("sprite_attackratio"), "CCSprite")
	end
end

--人物信息
function init_ext_topBar(self)
	if self.proxy_ ~= nil then
		local meritIcon = self.playerMgr_:GetMeritIcon()
		if meritIcon ~= nil then
			local pFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(meritIcon)
			if pFrame ~= nil then
				self.sprite_playermedal:setDisplayFrame(pFrame)
			end
		end
		--exp
		self.label_name:setString(self.playerData_.m_name)
		local nextExp = self.playerMgr_:GetNextLevelExp()
		local expStr = tostring(self.playerData_.m_exp) .. "/" .. tostring(nextExp)
		self.label_curexp:setString(expStr)
		self.sprite_levelstate:setScaleX(self.playerData_.m_exp / nextExp)

		--vipinfo
		local viplevel = self.playerData_.m_viplevel
		local vipframes={[0] = "vip_015",[1]="vip_003",[2]="vip_004",[3]="vip_005",[4]="vip_006",
			[5]="vip_007",[6]="vip_008",[7]="vip_009",[8]="vip_010",[9]="vip_011",[10]="vip_012",[11]="vip_013",[12]="vip_014",[13]="vip_s_13",[14] = "vip_s_14",[15] = "vip_s_15",[16]="vip_s_16",[17]="vip_s_17",[18]="vip_s_18"}
		if self.sprite_vipinfo ~= nil then
			local pFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(vipframes[viplevel])
			self.sprite_vipinfo:setDisplayFrame(pFrame)
		end

		--bodyval
		local maxbodyval = self.playerMgr_:GetMaxBodyValue()
		local bodyValStr = tostring(self.playerData_.m_bodyvalue) .. "/" .. tostring(maxbodyval)
		self.label_bodyval:setString(bodyValStr)
		local scaleVal = self.playerData_.m_bodyvalue / maxbodyval
		if scaleVal > 1 then
			scaleVal = 1
		end
		self.sprite_bodyratio:setScaleX(scaleVal)

		--attack
		local maxattack = self.playerMgr_:GetMaxAttackCount()
		local attackValStr = tostring(self.playerData_.m_fightcount) .. "/" .. tostring(maxattack)
		self.label_attackval:setString(attackValStr)
		self.sprite_attackratio:setScaleX(self.playerData_.m_fightcount / maxattack)

		--gold & silver
		self.label_goldval:setString(tostring(self.playerData_.m_gold))
		self.label_silverval:setString(tostring(self.playerData_.m_silver))
		self.label_level:setString(tostring(self.playerData_.m_level))
	end
end

function requestBaseLayerInfo(self)
	--获取基本信息
	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 1, "rl_r_group_contri")
	urlpath = AddData(urlpath, "GroupId", global.myOrgId)
	--cclog("rl_r_group_contri & cmd = 1---%s", urlpath)
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
			--cclog("rl_r_group_contri ret = %s", resData)
			local retcode = item.code
			if retcode == "0" then
				self.labelMyScore:setString(localizable.ui_orgMyScore .. item:find("score")[1])

				local item1 = item:find("item1")
				self.data[1] = item1

				local item2 = item:find("item2")
				self.data[2] = item2

				local item3 = item:find("item3")
				self.data[3] = item3

				local item4 = item:find("item4")
				self.data[4] = item4

				--ext init ui
				self:init_ext_ui()
			else
				GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
			end
		end)
end

function init_ext_ui(self)
	self.label_donate_cash:setString(self.data[1].contri_cash)
	self.label_addBuild_1:setString(self.data[1].group_score)
	self.label_addContribution_1:setString(self.data[1].user_score)

	self.label_addBuild_2_4:setString(self.data[2].group_score4)
	self.label_addContribution_2_4:setString(self.data[2].user_score4)
	self.label_addBuild_2_5:setString(self.data[2].group_score5)
	self.label_addContribution_2_5:setString(self.data[2].user_score5)

	self.label_addBuild_3_4:setString(self.data[3].group_score4)
	self.label_addContribution_3_4:setString(self.data[3].user_score4)
	self.label_addBuild_3_5:setString(self.data[3].group_score5)
	self.label_addContribution_3_5:setString(self.data[3].user_score5)

	self.label_addBuild_4_4:setString(self.data[4].group_score4)
	self.label_addContribution_4_4:setString(self.data[4].user_score4)
	self.label_addBuild_4_5:setString(self.data[4].group_score5)
	self.label_addContribution_4_5:setString(self.data[4].user_score5)
end



function requestExcute( self, taskid )
	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 2, "rl_r_group_contri")
	urlpath = AddData(urlpath, "TaskID", taskid)
	--cclog("rl_r_group_contri & cmd = 2---%s", urlpath)
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
			--cclog("rl_r_group_contri ret = %s", resData)
			local retcode = item.code
			if retcode == "0" then -- 刷新近期签到列表
				self.tableData = item:find("checkin_log")
				self._tableView:reloadData()
			else
				GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
			end
		end)
end

function init_binding_event(self)
	if self.proxy_ ~= nil then
		local function onBtnBack(btn, event)
			--GetMainMenu():ChangeToSub(self.back_page)
			self.node_:removeFromParentAndCleanup(true)
			ShowOrgMapLayer()
		end

		local function onBtnDonate( tag )
			if tag == 1 then
				require("ui_layer/ui_orgDonateGoldLayer")
				showModelLayer(ui_orgDonateGoldLayer, self.data[1],self)
			elseif tag == 2 then
				require("ui_layer/ui_orgDonateNinjaLayer")
				local view = createObj(ui_orgDonateNinjaLayer,self.data[2],self)
				AddViewToActivitySubMenu(view.node_)
			elseif tag == 3 then
				require("ui_layer/ui_orgDonateEquipLayer")
				local view = createObj(ui_orgDonateEquipLayer,self.data[3],self)
				AddViewToActivitySubMenu(view.node_)
			elseif tag == 4 then
				require("ui_layer/ui_orgDonateNinjutsuLayer")
				local view = createObj(ui_orgDonateNinjutsuLayer,self.data[4],self)
				AddViewToActivitySubMenu(view.node_)
			end
		end


		self.btn_back:setTouchPriority(kCCMenuHandlerPriority-1)
		self.btn_back:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btn_back, function(button, event)
			onBtnBack(button)
			return nil
		end, CCControlEventTouchDown)

		for i=1,4 do
			self.btnDonate[i]:setTouchPriority(kCCMenuHandlerPriority - 1)
			self.proxy_:handleButtonEvent(self.btnDonate[i], function(button, event)
				onBtnDonate(button:getTag())
				return nil
			end, CCControlEventTouchDown)
		end

		self.ctrl_btnplayermsg:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.ctrl_btnplayermsg:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.ctrl_btnplayermsg, function(button, event)
			GetMainMenu():OnShowUserInfo()
			return nil
		end, CCControlEventTouchDown)

	end
end

function onDonateGoldSuc(self)
	self.label_goldval:setString(self.playerMgr_:GetPlayerInfoData().m_gold)
	self:requestBaseLayerInfo()
end

function onDonateSuc( self )
	self:requestBaseLayerInfo()
end

function onNodeCleanup(self)
	if self.proxy_ then
    	self.proxy_:release()
    end

    layer_base_t.onNodeCleanup(self)
end
