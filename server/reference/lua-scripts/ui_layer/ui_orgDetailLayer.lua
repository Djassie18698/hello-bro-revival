--descriptioin:工会申请页面
--company: xckoo
--author: litao
--date: 2014-10-24
--modified: tango 2014-11-8 
---------------------------------------------
module("ui_orgDetailLayer", package.seeall)
baseClass(layer_base_t, ui_orgDetailLayer)

function init(self, orgid)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	self.contentSize_ = GetMainMenu():GetSubContentNode():getContentSize()
	local ccbiAttrTable = {name="sub_ui/OrgDetailView.ccbi", size=self.contentSize_}
	layer_base_t.init(self, true, ccbiAttrTable)

	--pre page
	self.back_page = E_DEFAULTMENU
	self.myState = 0 -- 0:未申请；1：申请中；2：已加入

    --data
    self.preNode = node
    --is open
    self.isOpening = false
    self.orgid = orgid

    --init
	self:init_ui()
	self:init_binding_event()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		--label
		self.labelName = tolua.cast(self.proxy_:getNode("label_name"), "CCLabelTTF")
		self.labelLevel = tolua.cast(self.proxy_:getNode("label_level"), "CCLabelTTF")
		self.labelPopulation = tolua.cast(self.proxy_:getNode("label_population"), "CCLabelTTF")
		self.labelLeader = tolua.cast(self.proxy_:getNode("label_leader"), "CCLabelTTF")

		self.labelBuild = tolua.cast(self.proxy_:getNode("label_build"), "CCLabelTTF")
		self.labelRank = tolua.cast(self.proxy_:getNode("label_rank"), "CCLabelTTF")
	
		self.labelDesc = tolua.cast(self.proxy_:getNode("label_org_desc"), "CCLabelTTF")
		self.labelMinLevel = tolua.cast(self.proxy_:getNode("label_minLevel"), "CCLabelTTF")
		self.labelMinFighting = tolua.cast(self.proxy_:getNode("label_minFighting"), "CCLabelTTF")

		--btn
		self.btnClose = tolua.cast(self.proxy_:getNode("btn_close"), "CCControlButton")
		self.btnApply = tolua.cast(self.proxy_:getNode("btn_apply"), "CCControlButton")

		--base request
		self:requestBaseLayerInfo()
	end
end

function requestBaseLayerInfo(self)
	--获取基本信息
	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 2, "rl_r_group_comm")
	urlpath = AddData(urlpath, "GroupId", self.orgid)
	--cclog("rl_r_group_comm & cmd = 2---%s", urlpath)
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
			--cclog("rl_r_group_comm ret = %s", resData)
			local retcode = item.code
			if retcode == "0" then
				local info = item:find("group_info")

				self.labelName:setString(info:find("name")[1])
				self.labelLevel:setString(info:find("level")[1])
				self.labelPopulation:setString(info:find("curcount")[1])

				self.labelLeader:setString(info:find("leader")[1])
				self.labelBuild:setString(info:find("score")[1])
				self.labelRank:setString(info:find("rank")[1])

				self.labelDesc:setString(info:find("desc")[1])

				self.labelMinLevel:setString(info:find("minlevel")[1])
				self.labelMinFighting:setString(info:find("minfightscore")[1])
				self.myState = tonumber(info:find("join_status")[1])

				--ext init ui
				self:init_ext_ui()
			else
				GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
			end
		end)
end

function init_ext_ui(self)
	self:updateBtn()
end

function updateBtn(self)
	self.btnApply:setVisible(true)
	if self.myState == 0 then
		setBtnEnabled(self.btnApply,true)
		setBtnTitle(self.btnApply,localizable.ui_orgDetail_apply)
	elseif self.myState == 1 then
		setBtnEnabled(self.btnApply,false)
		setBtnTitle(self.btnApply,localizable.ui_orgDetail_applied)
	elseif self.myState == 2 then
		self.btnApply:setVisible(false)
	end
end

function requestJoin(self )
	--获取基本信息
	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 6, "rl_r_group_comm")
	urlpath = AddData(urlpath, "GroupId", self.orgid)
	--cclog("rl_r_group_comm & cmd = 6---%s", urlpath)
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
			--cclog("rl_r_group_comm ret = %s", resData)
			if item.code == "0" then
				--self:closeDlg()
				GetMainMenu():ShowTextTip(localizable.ui_orgApply_suc, -1)
				self.myState = 1
				self:updateBtn()
			else
				GetMainMenu():ShowErrorTip(tonumber(item.code),-1)
			end
		end)
end

function init_binding_event(self)
	if self.proxy_ ~= nil then
		local function CCLayerTouch(event, x, y)
			if event == "began" then
				 return true
			end
		end
		self.node_:setTouchEnabled(true)
		self.node_:registerScriptTouchHandler(CCLayerTouch, false, kCCMenuHandlerPriority-1, true)

		local function onBtnClose(btn, event)
			self.node_:removeFromParentAndCleanup(true)
		end

		local function onBtnApply(btn, event)
			-- check...
			if self.myState == 1 then
				return nil
			end
			self:requestJoin()
		end

		self.btnClose:setTouchPriority(kCCMenuHandlerPriority-1)
		self.btnClose:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btnClose, function(button, event)
			onBtnClose(button)
			return nil
		end, CCControlEventTouchDown)

		self.btnApply:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.btnApply:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btnApply, function(button, event)
			onBtnApply(button)
			return nil
		end, CCControlEventTouchDown)
	end
end

function onNodeCleanup(self)
	if self.proxy_ then
    	self.proxy_:release()
    end

    layer_base_t.onNodeCleanup(self)
end