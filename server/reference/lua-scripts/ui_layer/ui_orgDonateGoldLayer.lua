----------------------------------------------------------------------
--  Copyright (c) 2014-2016, XCKOO. All Rights Reserved.
--  Author :Tango
--  Time   :2014/11/27 15:27:49
--  Remark :捐献元宝
----------------------------------------------------------------------
module("ui_orgDonateGoldLayer", package.seeall)
baseClass(layer_base_t, ui_orgDonateGoldLayer)

function init(self, data, preLayer)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	self.contentSize_ = GetMainMenu():GetSubContentNode():getContentSize()
	local ccbiAttrTable = {name="sub_ui/OrgDonateGoldView.ccbi", size=self.contentSize_}
	layer_base_t.init(self, true, ccbiAttrTable)

	--pre page
	self.back_page = E_DEFAULTMENU

    --data
    self.preLayer = preLayer

    self.data = data
	self.cash = 0 --花费元宝

    --editbox
    self.editGold = nil

    --init
	self:init_ui()
	self:init_binding_event()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		--label
		self.labelAddBuild = tolua.cast(self.proxy_:getNode("label_addBuild"), "CCLabelTTF")
		self.labelAddContrib = tolua.cast(self.proxy_:getNode("label_addContrib"), "CCLabelTTF")

		--editbox
		self.spr_input_org_name = tolua.cast(self.proxy_:getNode("spr_input_org_name"), "CCScale9Sprite")
		--btn
		self.btn_close = tolua.cast(self.proxy_:getNode("btn_close"), "CCControlButton")
		self.btn_ok = tolua.cast(self.proxy_:getNode("btn_ok"), "CCControlButton")
		--node
		self.node_content = tolua.cast(self.proxy_:getNode("node_content"), "CCNode")

		self:initEditBox()

		self:init_ext_ui()
	end
end

function initEditBox( self )
	--inti edit box
	local function editGoldEventHandler(eventType,sender)
        local strFmt 
        if eventType == "began" then
            -- triggered when an edit box gains focus after keyboard is shown
            strFmt = string.format("editBox began !")
            cclog("editboxEventHandler began = %s", strFmt)
        elseif eventType == "ended" then
            -- triggered when an edit box loses focus after keyboard is hidden.
            strFmt = string.format("editBox DidEnd !")
            cclog("editboxEventHandler ended = %s", strFmt)
			local num = tonumber(self.editGold:getText())
			if num and num >= 0 then
				self.cash = num
			else
				self.cash = 0
			end
			self:updateUI()
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

    self.editGold = CCEditBox:create(size, tolua.cast(self.proxy_:getNode("spr_input_org_name"), "CCScale9Sprite"))
    self.editGold:registerScriptEditBoxHandler(editGoldEventHandler)
    self.node_content:addChild(self.editGold, 1)

    self.editGold:setPlaceHolder("")
	self.editGold:setPosition(ccp(ptx + size.width/2, pty))
	self.editGold:setAnchorPoint(ccp(0.5,0.5))
	self.editGold:setMaxLength(20)
	self.editGold:setInputMode(kEditBoxInputModeSingleLine)
	self.editGold:setReturnType(kKeyboardReturnTypeDone)
	self.editGold:setFontColor(ccc3(0,0,0))--ccBLACK)

	self.editGold:setTouchPriority(kCCMenuHandlerPriority-1)
	self.editGold:setTouchEnabled(true)
	
end
function init_ext_ui(self)
	local unit = tonumber(self.data.contri_cash)
	self.uScore = tonumber(self.data.user_score)/unit
	self.oScore = tonumber(self.data.group_score)/unit
	
	self.cash = 0
	self:updateUI()
end

function updateUI(self)
	local addUScore = math.floor(self.cash * self.uScore)
	local addOScore = math.floor(self.cash * self.oScore)

	self.labelAddBuild:setString(tostring(addOScore))
	self.labelAddContrib:setString(tostring(addUScore))
end

function closeDlg(self)
	self.editGold:unregisterScriptEditBoxHandler()
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
			if self.cash <= 0 then
				GetMainMenu():ShowTextTip(localizable.ui_orgDonate_input, -1)
				return nil
			end
			if self.playerData_.m_gold < self.cash then
				--提示购买元宝
				GetMainMenu():ShowTextTip(localizable.ui_monopoly_gold_not_enough,-1)
				--通用付费引导
				local prePayLayer = createObj(ui_commonPrePay)
				GetMainMenu():GetModelLayer():AddDialog(prePayLayer.node_, 3)
				return nil
			end

			self:requestDonate()
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

function requestDonate(self)
	--获取基本信息
	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 2, "rl_r_group_contri")
	urlpath = AddData(urlpath, "GroupId", global.myOrgId)
	urlpath = AddData(urlpath, "Cash", self.cash)
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
			if item.code == "0" then
				self:closeDlg()
				self.playerMgr_:AddGold(-self.cash)
				if self.preLayer then
					self.preLayer:onDonateGoldSuc()
				end
				GetMainMenu():ShowTextTip(localizable.ui_orgDonate_suc, -1)
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