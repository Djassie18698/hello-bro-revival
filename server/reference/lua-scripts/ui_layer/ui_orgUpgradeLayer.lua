----------------------------------------------------------------------
--  Copyright (c) 2014-2016, XCKOO. All Rights Reserved.
--  Author :Tango
--  Time   :2014/11/21 21:00:04
--  Remark :建筑升级
----------------------------------------------------------------------
module("ui_orgUpgradeLayer", package.seeall)
baseClass(layer_base_t, ui_orgUpgradeLayer)

function init(self, node)
	self.contentSize_ = GetMainMenu():GetModelLayer():getContentSize()
	local ccbiAttrTable = {name="sub_ui/OrgUpgradeView.ccbi", size=self.contentSize_}
	layer_base_t.init(self, true, ccbiAttrTable)

	--用户info
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	--pre info
	self.preNode = node

	self.build = 0
	self.constructs = {}
	
	--init
	self:init_ui()		
	self:init_binding_event()

	

end

function init_ui(self)
	if self.proxy_ ~= nil then
		self.node_content = tolua.cast(self.proxy_:getNode("node_content"), "CCNode")
		self.node_cell = tolua.cast(self.proxy_:getNode("node_cell"), "CCNode")
		--btn
		self.btnClose = tolua.cast(self.proxy_:getNode("btn_close"), "CCControlButton")

		self.btnUpgrade = {}
		self.labelCondition = {}
		self.labelExpend = {}
		self.labelAdd = {}
		self.labelLv = {}
		--label
		self.labelCurBuild = tolua.cast(self.proxy_:getNode("label_curBuild"), "CCLabelTTF")
		for i=1,4 do
			local si = tostring(i)
			self.labelCondition[i] = tolua.cast(self.proxy_:getNode("label_condition_"..si), "CCLabelTTF")
			self.labelExpend[i] = tolua.cast(self.proxy_:getNode("label_expend_"..si), "CCLabelTTF")
			self.labelAdd[i] = tolua.cast(self.proxy_:getNode("label_add_"..si), "CCLabelTTF")

			self.btnUpgrade[i] = tolua.cast(self.proxy_:getNode("btn_upgrade_"..si), "CCControlButton")
			self.btnUpgrade[i]:setTag(i)

			self.labelLv[i] = tolua.cast(self.proxy_:getNode("label_lv_"..si), "CCLabelTTF")
		end

		self:requestBaseInfo()
	end
end


function requestBaseInfo(self)
	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 8, "rl_w_group_admin")
	urlpath = AddData(urlpath, "GroupId", global.myOrgId)
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
			local retcode = item.code
			--cclog("resData = %s", resData)
			if retcode == "0" then
				local info = item:find("group_info")
				self.build = info:find("score")[1]
				self.constructs = item:find("construct_list")
				self:init_ext_ui()
			else
				GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
			end
		end)	
end

function init_ext_ui(self)	
	self.labelCurBuild:setString(self.build)
	for i,construct in ipairs(self.constructs) do
		if construct.max_level_flag == "1" then -- 已达到顶级
			self.labelCondition[i]:setString(localizable.ui_orgUpgrade_condition_0)
			self.labelExpend[i]:setString(localizable.ui_orgUpgrade_condition_0)
			self.labelAdd[i]:setString(localizable.ui_orgUpgrade_top)
		else
			self.labelExpend[i]:setString(construct.consume_score .. localizable.ui_orgUpgrade_expend)
			self.labelAdd[i]:setString(construct.effect_desc)
			local needConstruct = tonumber(construct.require_construct_id)
			local strCondition = localizable.ui_orgUpgrade_condition_0
			if needConstruct > 0 and needConstruct <= #localizable.OrgBuilding then
				strCondition = localizable.OrgBuilding[needConstruct] .. construct.require_construct_level .. localizable.ui_orgUpgrade_condition_1
			end
			self.labelCondition[i]:setString(strCondition)
		end
		self.labelLv[i]:setString(localizable.ui_orgBuildLv .. construct.level)
	end
end

function close( self )
	self.preNode:refresh()
	self.node_:removeFromParentAndCleanup(true)
end

function init_binding_event(self)
	if self.proxy_ ~= nil then
		--屏蔽掉后层触摸事件
		local function CCLayerTouch(event, x, y)
			if event == "began" then
				 return true
			end
		end

		self.node_:setTouchEnabled(true)
		self.node_:registerScriptTouchHandler(CCLayerTouch, false, kCCMenuHandlerPriority-1, true)

		self.btnClose:setTouchPriority(kCCMenuHandlerPriority-1)
		self.proxy_:handleButtonEvent(self.btnClose, function(button, event)
			self:close()
			return nil
		end, CCControlEventTouchDown)


		for i,btn in ipairs(self.btnUpgrade) do
			btn:setTouchPriority(kCCMenuHandlerPriority - 1)
			self.proxy_:handleButtonEvent(btn, function(button, event)
				self:onBtnUpgrade(button:getTag())
			end, CCControlEventTouchDown)
		end

	end
end

function onBtnUpgrade( self, i )
	-- body
	if i <=0 or i > #self.constructs then
		return nil
	end

	local ConstructID = self.constructs[i].construct_id
	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 9, "rl_w_group_admin")
	urlpath = AddData(urlpath, "GroupId", global.myOrgId)
	urlpath = AddData(urlpath, "ConstructID", ConstructID)
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
			local retcode = item.code
			--cclog("resData = %s", resData)
			if retcode == "0" then
				local info = item:find("group_info")
				self.build = info:find("score")[1]
				self.constructs = item:find("construct_list")
				self:init_ext_ui()
				GetMainMenu():ShowTextTip(localizable.ui_orgUpgrade_suc, -1)
			else
				GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
			end
		end)	
end

function onNodeCleanup(self)
	if self.proxy_ then
    	self.proxy_:release()
    end

    layer_base_t.onNodeCleanup(self)
end
