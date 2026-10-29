----------------------------------------------------------------------
--  Copyright (c) 2014-2016, XCKOO. All Rights Reserved.
--  Author :Tango
--  Time   :2014/11/20 19:57:47
--  Remark :组织设置
----------------------------------------------------------------------

module("ui_orgSettingLayer", package.seeall)
baseClass(layer_base_t, ui_orgSettingLayer)

function init(self)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	self.contentSize_ = GetMainMenu():GetSubContentNode():getContentSize()
	local ccbiAttrTable = {name="sub_ui/OrgSettingView.ccbi", size=self.contentSize_}
	layer_base_t.init(self, true, ccbiAttrTable)

	--pre page
	self.back_page = E_DEFAULTMENU

    --data
    self.preNode = node
    self.m_add_desc_data = {}

    self.cost = 0 --花费元宝

    --editbox
    self.editLv = nil
    self.editDesc = nil

    self.lv = 0
    self.fighting = 0
    self.desc = ''

    --init
	self:init_ui()
	self:init_binding_event()
end

function requestBaseLayerInfo(self)
	--获取基本信息
	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 6, "rl_w_group_admin")
	urlpath = AddData(urlpath, "GroupId", global.myOrgId)
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
			local retcode = item.code
			if retcode == "0" then
				local info = item:find("group_info")
				self.lv = info:find("minlevel")[1]
				self.fighting = info:find("minfightscore")[1]
				self.desc = info:find("desc")[1]
								
				self:init_ext_ui()
			else
				GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
			end
		end)
end

function init_ui(self)
	if self.proxy_ ~= nil then
		--label
		self.label_apply_org_cost = tolua.cast(self.proxy_:getNode("label_apply_org_cost"), "CCLabelTTF")
		self.label_org_desc = tolua.cast(self.proxy_:getNode("label_org_desc"), "CCLabelTTF")
		--editbox
		self.spr_input_lv = tolua.cast(self.proxy_:getNode("spr_input_lv"), "CCScale9Sprite")
		self.spr_input_fighting = tolua.cast(self.proxy_:getNode("spr_input_fighting"), "CCScale9Sprite")
		self.spr_input_org_desc = tolua.cast(self.proxy_:getNode("spr_input_org_desc"), "CCScale9Sprite")
		--btn
		self.btn_close = tolua.cast(self.proxy_:getNode("btn_close"), "CCControlButton")
		self.btn_ok = tolua.cast(self.proxy_:getNode("btn_ok"), "CCControlButton")

		self.nodeCondition = tolua.cast(self.proxy_:getNode("node_condition"), "CCNode")
		self.nodeDesc = tolua.cast(self.proxy_:getNode("node_desc"), "CCNode")

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
    
    --lv
    local ptx, pty = self.spr_input_lv:getPosition()
	local size = self.spr_input_lv:getContentSize()

	self.spr_input_lv:removeFromParentAndCleanup(true)

    self.editLv = CCEditBox:create(size, tolua.cast(self.proxy_:getNode("spr_input_lv"), "CCScale9Sprite"))
    self.editLv:registerScriptEditBoxHandler(editnameboxEventHandler)
	self.nodeCondition:addChild(self.editLv, 1)

	self.editLv:setPosition(ccp(ptx + size.width/2, pty))
	self.editLv:setAnchorPoint(ccp(0.5,0.5))
	self.editLv:setMaxLength(20)
	self.editLv:setInputMode(kEditBoxInputModeSingleLine ) --任何文本_不包括换行
	self.editLv:setReturnType(kKeyboardReturnTypeDone)
	self.editLv:setFontColor(ccc3(0,0,0))--ccBLACK)

	self.editLv:setTouchPriority(kCCMenuHandlerPriority-1)
	self.editLv:setTouchEnabled(true)

	-- fighting

	local function editFightEventHandler(eventType,sender)
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

	local ptx, pty = self.spr_input_fighting:getPosition()
	local size = self.spr_input_fighting:getContentSize()

	self.spr_input_fighting:removeFromParentAndCleanup(true)

    self.editFighting = CCEditBox:create(size, tolua.cast(self.proxy_:getNode("spr_input_fighting"), "CCScale9Sprite"))
    self.editFighting:registerScriptEditBoxHandler(editFightEventHandler)
	self.nodeCondition:addChild(self.editFighting, 1)

	self.editFighting:setPosition(ccp(ptx + size.width/2, pty))
	self.editFighting:setAnchorPoint(ccp(0.5,0.5))
	self.editFighting:setMaxLength(20)
	self.editFighting:setInputMode(kEditBoxInputModeSingleLine ) --任何文本_不包括换行
	self.editFighting:setReturnType(kKeyboardReturnTypeDone)
	self.editFighting:setFontColor(ccc3(0,0,0))--ccBLACK)

	self.editFighting:setTouchPriority(kCCMenuHandlerPriority-1)
	self.editFighting:setTouchEnabled(true)
	
	--desc
	local function editdescboxEventHandler(eventType)
        local strFmt 
        if eventType == "began" then
            -- triggered when an edit box gains focus after keyboard is shown
            strFmt = string.format("editBox began !")
            --self.editDesc:setText(tostring(self.label_org_desc:getString()))
            cclog("editboxEventHandler began = %s", strFmt)
        elseif eventType == "ended" then
            -- triggered when an edit box loses focus after keyboard is hidden.
            strFmt = string.format("editBox DidEnd !")
            cclog("editboxEventHandler ended = %s", strFmt)
        elseif eventType == "changed" then
            -- triggered when the edit box text was changed.
            strFmt = string.format("editBox changed !")
            self.label_org_desc:setString(self.editDesc:getText())
            cclog("editboxEventHandler changed = %s", strFmt)
        elseif eventType == "return" then
            -- triggered when the return button was pressed or the outside area of keyboard was touched.  
            strFmt = string.format("editBox return !") 
            self.label_org_desc:setString(self.editDesc:getText())
            self.editDesc:setText("")
            cclog("editboxEventHandler return = %s", strFmt)
        end
    end
	local ptx_1, pty_1 = self.spr_input_org_desc:getPosition()
	local size_1 = self.spr_input_org_desc:getContentSize()

	self.spr_input_org_desc:removeFromParentAndCleanup(true)

	self.editDesc = CCEditBox:create(size_1, tolua.cast(self.proxy_:getNode("spr_input_org_desc"), "CCScale9Sprite"))
    self.editDesc:registerScriptEditBoxHandler(editdescboxEventHandler)
	self.nodeDesc:addChild(self.editDesc, 1)

    --self.editDesc:setPlaceHolder("desc")
	self.editDesc:setPosition(ccp(ptx_1, pty_1))
	self.editDesc:setAnchorPoint(ccp(0.5, 1.0))
	self.editDesc:setMaxLength(100)
	self.editDesc:setInputMode(kEditBoxInputModeSingleLine) --任何文本_不包括换行
	self.editDesc:setReturnType(kKeyboardReturnTypeDone)
	self.editDesc:setFontColor(ccc3(255,255,255))--ccBLACK)
	self.editDesc:setFontSize(0)  
    --self.editDesc:setOpacity(0) 

	self.editDesc:setTouchPriority(kCCMenuHandlerPriority-1)
	self.editDesc:setTouchEnabled(true)

	--org desc
	self.label_org_desc:removeFromParentAndCleanup(true)
	self.label_org_desc = tolua.cast(self.proxy_:getNode("label_org_desc"), "CCLabelTTF")
	self.nodeDesc:addChild(self.label_org_desc, 2)
    self.label_org_desc:setString(tostring("请输入组织描述"))
	self.label_org_desc:setDimensions(CCSizeMake(size_1.width - 50, 0))
end
function init_ext_ui(self)
	if self.editLv ~= nil then
		self.editLv:setText(self.lv)
	end
	if self.editFighting ~= nil then
		self.editFighting:setText(self.fighting)
	end
	self.label_org_desc:setString(self.desc)

end

function closeDlg(self)
	self.editLv:unregisterScriptEditBoxHandler()
	self.editFighting:unregisterScriptEditBoxHandler()
	self.editDesc:unregisterScriptEditBoxHandler()	
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
			local lv = tonumber(self.editLv:getText())
			if lv == nil or lv < 0 then
				GetMainMenu():ShowTextTip(localizable.ui_orgDonate_input, -1)
				return nil
			end

			local fighting = tonumber(self.editFighting:getText())
			if fighting == nil or fighting < 0 then
				GetMainMenu():ShowTextTip(localizable.ui_orgDonate_input, -1)
				return nil
			end

			local desc = self.label_org_desc:getString()

			self:requestSetting(lv, fighting, desc)
		end

		self.node_:setTouchEnabled(true)
		self.node_:registerScriptTouchHandler(CCLayerTouch, false, kCCMenuHandlerPriority-1, true)

		self.btn_close:setTouchPriority(kCCMenuHandlerPriority-1)
		self.proxy_:handleButtonEvent(self.btn_close, function(button, event)
			self:closeDlg()
			return nil
		end, CCControlEventTouchDown)

		self.btn_ok:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.proxy_:handleButtonEvent(self.btn_ok, function(button, event)
			onBtnOK(button)
			return nil
		end, CCControlEventTouchDown)
	end
end

function requestSetting(self, lv, fighting, desc )
	--获取基本信息
	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 7, "rl_w_group_admin")
	urlpath = AddData(urlpath, "GroupId", global.myOrgId)
	urlpath = AddData(urlpath, "MinLevel", lv)
	urlpath = AddData(urlpath, "MinFightScore", fighting)
	urlpath = AddData(urlpath, "Desc", desc)
	
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
			if item.code == "0" then
				self:closeDlg()
				--ShowOrgMapLayer()
				GetMainMenu():ShowTextTip(localizable.ui_orgSetting_suc, -1)
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