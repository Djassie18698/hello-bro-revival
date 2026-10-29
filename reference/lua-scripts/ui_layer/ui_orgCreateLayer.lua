--descriptioin:工会申请页面
--company: xckoo
--author: litao
--date: 2014-10-24
---------------------------------------------
module("ui_orgCreateLayer", package.seeall)
baseClass(layer_base_t, ui_orgCreateLayer)

function init(self,preLayer)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	self.contentSize_ = GetMainMenu():GetSubContentNode():getContentSize()
	local ccbiAttrTable = {name="sub_ui/OrgCreateView.ccbi", size=self.contentSize_}
	layer_base_t.init(self, true, ccbiAttrTable)

	--pre page
	self.back_page = E_DEFAULTMENU

    --data
    self.preLayer = preLayer
    self.m_add_desc_data = {}

    self.cost = 0 --花费元宝

    --editbox
    self.m_name_edit = nil
    self.m_desc_edit = nil

    --init
	self:init_ui()
	self:init_binding_event()
end
function requestBaseLayerInfo(self)
	--获取基本信息
	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 7, "rl_r_group_comm")
	--cclog("rl_r_group_comm & cmd = 7---%s", urlpath)
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
				self.cost =tonumber(item:find("cash")[1])
								
				self:init_ext_ui()
			else
				GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
			end
		end)
end

function init_ui(self)
	if self.proxy_ ~= nil then
		--label
		self.labelCost = tolua.cast(self.proxy_:getNode("label_apply_org_cost"), "CCLabelTTF")
		self.label_org_desc = tolua.cast(self.proxy_:getNode("label_org_desc"), "CCLabelTTF")
		--editbox
		self.spr_input_org_name = tolua.cast(self.proxy_:getNode("spr_input_org_name"), "CCScale9Sprite")
		self.spr_input_org_desc = tolua.cast(self.proxy_:getNode("spr_input_org_desc"), "CCScale9Sprite")
		--btn
		self.btn_close = tolua.cast(self.proxy_:getNode("btn_close"), "CCControlButton")
		self.btn_ok = tolua.cast(self.proxy_:getNode("btn_ok"), "CCControlButton")
		--node
		self.node_content = tolua.cast(self.proxy_:getNode("node_content"), "CCNode")

		self:initEditBox()

		--base request
		self:requestBaseLayerInfo()
	end
end

function initEditBox( self )
	--inti edit box
	local function editnameboxEventHandler(eventType,sender)
        local strFmt 
        if eventType == "began" then
            -- triggered when an edit box gains focus after keyboard is shown
            strFmt = string.format("editBox began !")
            cclog("editboxEventHandler began = %s", strFmt)
        elseif eventType == "ended" then
            -- triggered when an edit box loses focus after keyboard is hidden.
            strFmt = string.format("editBox DidEnd !")
            cclog("editboxEventHandler ended = %s", strFmt)
        elseif eventType == "changed" then
            -- triggered when the edit box text was changed.
            strFmt = string.format("editBox changed !")
            cclog("editboxEventHandler changed = %s", strFmt)
        elseif eventType == "return" then
            -- triggered when the return button was pressed or the outside area of keyboard was touched. 
            strFmt = string.format("editBox return !")  
            cclog("editboxEventHandler return = %s", strFmt)
        end
    end
    
    --name
    local ptx, pty = self.spr_input_org_name:getPosition()
	local size = self.spr_input_org_name:getContentSize()

	self.spr_input_org_name:removeFromParentAndCleanup(true)

    self.m_name_edit = CCEditBox:create(size, tolua.cast(self.proxy_:getNode("spr_input_org_name"), "CCScale9Sprite"))
    self.m_name_edit:registerScriptEditBoxHandler(editnameboxEventHandler)
    self.node_content:addChild(self.m_name_edit, 1)

    self.m_name_edit:setPlaceHolder("name")
	self.m_name_edit:setPosition(ccp(ptx + size.width/2, pty))
	self.m_name_edit:setAnchorPoint(ccp(0.5,0.5))
	self.m_name_edit:setMaxLength(20)
	self.m_name_edit:setInputMode(kEditBoxInputModeSingleLine) --任何文本_不包括换行
	self.m_name_edit:setReturnType(kKeyboardReturnTypeDone)
	self.m_name_edit:setFontColor(ccc3(0,0,0))--ccBLACK)

	self.m_name_edit:setTouchPriority(kCCMenuHandlerPriority-1)
	self.m_name_edit:setTouchEnabled(true)
	
	--desc
	local function editdescboxEventHandler(eventType)
        local strFmt 
        if eventType == "began" then
            -- triggered when an edit box gains focus after keyboard is shown
            strFmt = string.format("editBox began !")
            --self.m_desc_edit:setText(tostring(self.label_org_desc:getString()))
            cclog("editboxEventHandler began = %s", strFmt)
        elseif eventType == "ended" then
            -- triggered when an edit box loses focus after keyboard is hidden.
            strFmt = string.format("editBox DidEnd !")
            cclog("editboxEventHandler ended = %s", strFmt)
        elseif eventType == "changed" then
            -- triggered when the edit box text was changed.
            strFmt = string.format("editBox changed !")
            self.label_org_desc:setString(self.m_desc_edit:getText())
            cclog("editboxEventHandler changed = %s", strFmt)
        elseif eventType == "return" then
            -- triggered when the return button was pressed or the outside area of keyboard was touched.  
            strFmt = string.format("editBox return !") 
            self.label_org_desc:setString(self.m_desc_edit:getText())
            self.m_desc_edit:setText("")
            cclog("editboxEventHandler return = %s", strFmt)
        end
    end
	local ptx_1, pty_1 = self.spr_input_org_desc:getPosition()
	local size_1 = self.spr_input_org_desc:getContentSize()

	self.spr_input_org_desc:removeFromParentAndCleanup(true)

	self.m_desc_edit = CCEditBox:create(size_1, tolua.cast(self.proxy_:getNode("spr_input_org_desc"), "CCScale9Sprite"))
    self.m_desc_edit:registerScriptEditBoxHandler(editdescboxEventHandler)
    self.node_content:addChild(self.m_desc_edit, 1)

    --self.m_desc_edit:setPlaceHolder("desc")
	self.m_desc_edit:setPosition(ccp(ptx_1 + size_1.width/2, pty_1 - size_1.height/2))
	self.m_desc_edit:setAnchorPoint(ccp(0.5, 0.5))
	self.m_desc_edit:setMaxLength(100)
	self.m_desc_edit:setInputMode(kEditBoxInputModeSingleLine) --任何文本_不包括换行
	self.m_desc_edit:setReturnType(kKeyboardReturnTypeDone)
	self.m_desc_edit:setFontColor(ccc3(255,255,255))--ccBLACK)
	self.m_desc_edit:setFontSize(0)  
    --self.m_desc_edit:setOpacity(0) 

	self.m_desc_edit:setTouchPriority(kCCMenuHandlerPriority-1)
	self.m_desc_edit:setTouchEnabled(true)

	--org desc
	self.label_org_desc:removeFromParentAndCleanup(true)
	self.label_org_desc = tolua.cast(self.proxy_:getNode("label_org_desc"), "CCLabelTTF")
    self.node_content:addChild(self.label_org_desc, 2)
    self.label_org_desc:setString(tostring("Click to input the introduction."))
	self.label_org_desc:setDimensions(CCSizeMake(size_1.width - 50, 0))
end
function init_ext_ui(self)
	self.labelCost:setString(self.cost)
end

function closeDlg(self)
	self.m_name_edit:unregisterScriptEditBoxHandler()
	self.m_desc_edit:unregisterScriptEditBoxHandler()	
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

		local function onBtnOK(btn, event)
			-- check
			if self.playerData_.m_gold < self.cost then
				--提示购买元宝
				GetMainMenu():ShowTextTip(localizable.ui_monopoly_gold_not_enough,-1)
				--通用付费引导
				local prePayLayer = createObj(ui_commonPrePay)
				GetMainMenu():GetModelLayer():AddDialog(prePayLayer.node_, 3)
				return nil
			end

			local name = self.m_name_edit:getText()
			local desc = self.label_org_desc:getString()
			self:requestCreate(name,desc)
		end

		self.node_:setTouchEnabled(true)
		self.node_:registerScriptTouchHandler(CCLayerTouch, false, kCCMenuHandlerPriority-1, true)

		self.btn_close:setTouchPriority(kCCMenuHandlerPriority-1)
		self.btn_close:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btn_close, function(button, event)
			self:closeDlg()
			return nil
		end, CCControlEventTouchDown)

		self.btn_ok:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.btn_ok:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btn_ok, function(button, event)
			onBtnOK(button)
			return nil
		end, CCControlEventTouchDown)
	end
end

function requestCreate(self, name, desc )
	--获取基本信息
	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 3, "rl_r_group_comm")
	urlpath = AddData(urlpath, "GroupName", name)
	urlpath = AddData(urlpath, "Desc", desc)
	--cclog("rl_r_group_comm & cmd = 3---%s", urlpath)
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
				require("util/common")
				global.myOrgId = item:find("groupid")[1]
				self:closeDlg()
				if self.preLayer then
					self.playerMgr_:AddGold(-self.cost)
					self.preLayer:onCreateSuc()
				end
				ShowOrgMapLayer()
			else
				GetMainMenu():ShowErrorTip(tonumber(item.code),-1)
			end
		end)
end
function onNodeCleanup(self)
	if self.proxy_ then
    	self.proxy_:release()
    end

    layer_base_t.onNodeCleanup(self)
end