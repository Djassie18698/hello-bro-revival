
module("ui_gameSettingLayer", package.seeall)
baseClass(layer_base_t, ui_gameSettingLayer)

OPEN_USER_CENTER_FOR_APPSTORE = false

OPEN_SHOW_VERSION = false

function init(self) 
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	local winSize = CCDirector:sharedDirector():getWinSize()

	local ccbiAttrTable = {name="GameSettingViewForLua.ccbi", size=winSize}
	layer_base_t.init(self, true, ccbiAttrTable)

	self:init_ui()
	self:init_binding_event()
    self:updateShow()
end

function updateShow(self)

    self.text_title:setString(localizable.ui_gameSettings_title)
    self.text_sound_settings:setString(localizable.ui_gameSettings_soundSettings)
    self.text_sound:setString(localizable.ui_gameSettings_sound)
    self.text_sound_effect:setString(localizable.ui_gameSettings_soundEffect)
    self.text_contact_service:setString(localizable.ui_gameSettings_contactService)
    self.text_uid_tip:setString(localizable.ui_gameSettings_uidTip)
    
    self.text_username:setString(localizable.ui_gameSettings_userNameNotSet)
    self.text_invite_code:setString(localizable.ui_gameSettings_inviteCode)
    self.text_uid:setString(self.playerData_.m_uid)

    self.text_version:setString(GetGameVersion())
    self.text_usercenter:setString(localizable.ui_gameSettings_userCenter)
    self.text_username:setString(self.playerData_.m_name)

    self.btn_user_center:setVisible(false)

    self.btn_change_user:setVisible(OPEN_USER_CENTER_FOR_APPSTORE)
    self.text_usercenter:setVisible(OPEN_USER_CENTER_FOR_APPSTORE)
    self.text_username:setVisible(OPEN_USER_CENTER_FOR_APPSTORE)
    self.btn_user_center_background:setVisible(OPEN_USER_CENTER_FOR_APPSTORE)

    local showInvi = not global.isReviewing()
    self.btn_get_award:setVisible(showInvi)
    self.text_invite_code:setVisible(showInvi)
    self.edit_invite_code:setVisible(showInvi)    
    self.btn_invite_code_background:setVisible(OPEN_USER_CENTER_FOR_APPSTORE)

    self.text_version:setVisible(OPEN_SHOW_VERSION)

    self.sprite_sound:setVisible(CCUserDefault:sharedUserDefault():getBoolForKey("switch_sound"))
    self.sprite_sound_effect:setVisible(CCUserDefault:sharedUserDefault():getBoolForKey("switch_soundeffect"))

end

function init_binding_event(self)
    local function CCLayerTouch(event,x,y)
        local rect = self.node_:boundingBox()
    	rect.origin = ccp(0,0)
    	local p = self.node_:convertToNodeSpace(ccp(x,y))
    	if event == "began" then
    		if rect:containsPoint(p) == true then
    			return true
    		else
    			return false
    		end
    	end
    end
    self.node_:setTouchEnabled(true)
    self.node_:registerScriptTouchHandler(CCLayerTouch, false, kCCMenuHandlerPriority - 1, true)

    self:init_btn_binding_event(self.btn_close, 
        function(button, event)
            self.node_:removeFromParentAndCleanup(true)
        end,
        "" )   

    self:init_btn_binding_event(self.btn_sound,
        function (button, event)
            cclog("sound on / off")
            if (self.sprite_sound:isVisible()) then
                self.sprite_sound:setVisible(false)
                CCUserDefault:sharedUserDefault():setBoolForKey("switch_sound", false)
                CSoundMgr:instance():SetBackSoundEnable(false)
                CSoundMgr:instance():StopBackgroundSound()
            else
                self.sprite_sound:setVisible(true)
                CCUserDefault:sharedUserDefault():setBoolForKey("switch_sound", true)
                CSoundMgr:instance():SetBackSoundEnable(true)
                CSoundMgr:instance():PlayBackgroundSound(SOUND_BEIJINGMAIN, true)
            end
        end,
        "" )

    self:init_btn_binding_event(self.btn_sound_effect,
        function (button, event)
            cclog("sound effect on / off")
            if (self.sprite_sound_effect:isVisible()) then
                self.sprite_sound_effect:setVisible(false)
                CCUserDefault:sharedUserDefault():setBoolForKey("switch_soundeffect", false)
                CSoundMgr:instance():SetSoundEffectEnable(false)
                CSoundMgr:instance():StopAllEffect()
            else
                self.sprite_sound_effect:setVisible(true)
                CCUserDefault:sharedUserDefault():setBoolForKey("switch_soundeffect", true)
                CSoundMgr:instance():SetSoundEffectEnable(true)
                CSoundMgr:instance():PlayEffect(SOUND_BUTTON)
            end
        end,
        "")

    self:init_btn_binding_event(self.btn_change_user,
        function (button, event)
            cclog("change user")
            CSoundMgr:instance():PlayEffect(SOUND_BUTTON);
            --GetMainMenu():LogOut()
        end,
        localizable.ui_gameSettings_changeUser)

    self:init_btn_binding_event(self.btn_get_award,
        function (button, event)
            cclog("get award")
            CSoundMgr:instance():PlayEffect(SOUND_BUTTON)
            self.inviteCode = self.edit_invite_code:getText()
            if self.inviteCode == "" or self.inviteCode == nil then
                GetMainMenu():ShowTextTip(localizable.ui_gameSettings_inviteCodeInput, -1)
            else
                self:getAward()
            end
        end,
        localizable.ui_gameSettings_getAward)
end

function getAward(self)
    local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 1, "rl_w_invitecode")
    urlpath = AddData(urlpath, "Code", self.inviteCode)
    --local date=os.date("%Y-%m-%d %H:%M:%S")
    --cclog("date = " .. date)
    cclog("url = %s", tostring(urlpath))

    function getAwardCallback(data)
        cclog("getAwardCallback data = %s", tostring(data))

        local award = data:find("award")
        ShowAward(award)

    end

    sendRequest(urlpath, getAwardCallback, cost)
end

function init_ui(self)
	if self.proxy_ ~= nil then
        local proxy = self.proxy_

        self.btn_change_user = getButtonFromCCB(proxy, "btn_change_user")
        self.btn_close = getButtonFromCCB(proxy, "btn_close")
        self.btn_get_award = getButtonFromCCB(proxy, "btn_get_award")
        self.btn_sound = getButtonFromCCB(proxy, "btn_sound")
        self.btn_sound_effect = getButtonFromCCB(proxy, "btn_sound_effect")
        self.btn_user_center = getButtonFromCCB(proxy, "btn_user_center")

        self.btn_invite_code_background = getButtonFromCCB(proxy, "btn_invite_code_background")
        self.btn_user_center_background = getButtonFromCCB(proxy, "btn_user_center_background")

        -- static text
        self.text_title = getLabelTTFFromCCB(proxy, "text_game_title")
        self.text_sound_settings = getLabelTTFFromCCB(proxy, "text_sound_settings")
        self.text_sound = getLabelTTFFromCCB(proxy, "text_sound")
        self.text_sound_effect = getLabelTTFFromCCB(proxy, "text_sound_effect")
        self.text_contact_service = getLabelTTFFromCCB(proxy, "text_contact_service")
        self.text_uid_tip = getLabelTTFFromCCB(proxy, "text_uid_tip")
        self.text_usercenter = getLabelTTFFromCCB(proxy, "text_usercenter")
        self.text_invite_code = getLabelTTFFromCCB(proxy, "text_invite_code")
        --
        self.text_version = getLabelTTFFromCCB(proxy, "text_version")
        self.text_uid = getLabelTTFFromCCB(proxy, "text_uid")
        self.text_username = getLabelTTFFromCCB(proxy, "text_username")
        --
        self.sprite_sound = getSpriteFromCCB(proxy, "sprite_sound")
        self.sprite_sound_effect = getSpriteFromCCB(proxy, "sprite_sound_effect")
        self.sprite_input = getScale9SpriteFromCCB(proxy, "sprite_input")
        --
        self:initEditBox()

	end
end

function initEditBox(self)
	-- inti edit box
	local function editboxEventHandle (eventType)
		local strFmt
		if eventType == "began" then
			-- triggered when an edit box gains focus after keyboard is shown
			--strFmt = string.format("editBox began !")
			--cclog("editboxEventHandler began = %s", strFmt)
		elseif eventType == "ended" then
			-- triggered when an edit box loses focus after keyboard is hidden.
			--strFmt = string.format("editBox DidEnd !")
			--cclog("editboxEventHandler ended = %s", strFmt)

			self:onInputDone()
		elseif eventType == "changed" then
			-- triggered when the edit box text was changed.
			--strFmt = string.format("editBox changed !")
			--cclog("editboxEventHandler changed = %s", strFmt)
		elseif eventType == "return" then
			-- triggered when the return button was pressed or the outside area of keyboard was touched.
			--strFmt = string.format("editBox return !")
			--cclog("editboxEventHandler return = %s", strFmt)
		end
	end
    	
	local ptx, pty = self.sprite_input:getPosition()
	local size = self.sprite_input:getContentSize()
	local parentNode = self.sprite_input:getParent()

	self.sprite_input:removeFromParentAndCleanup(true)
    self.edit_invite_code = CCEditBox:create(size, self.sprite_input)
    self.edit_invite_code:registerScriptEditBoxHandler(editboxEventHandle)
    parentNode:addChild(self.edit_invite_code, 1)

    self.edit_invite_code:setPosition(ccp(ptx + size.width / 2, pty + size.height / 2))
    self.edit_invite_code:setAnchorPoint(ccp(0.5, 0.5))
    self.edit_invite_code:setMaxLength(20)
    self.edit_invite_code:setInputMode(kEditBoxInputModeSingleLine)
    self.edit_invite_code:setReturnType(kKeyboardReturnTypeDone)
    self.edit_invite_code:setFontColor(ccc3(0, 0, 0))
    self.edit_invite_code:setTouchPriority(kCCMenuHandlerPriority - 1)
    self.edit_invite_code:setTouchEnabled(true)
    self.edit_invite_code:setPlaceHolder(localizable.ui_gameSettings_inviteCodeInput)
end

function onInputDone(self)
    self.inviteCode = self.edit_invite_code:getText()
    cclog("onInputDone get invite code = %s", self.inviteCode)
--[[
	local inviteCode = tonumber(self.edit_invite_code:getText())
	if lv == nil or lv < 0 then
		GetMainMenu():ShowTextTip(localizable.ui_orgDonate_input, -1)
		return nil
	end

	if lv > self.maxRound then
		GetMainMenu():ShowTextTip(string.format(localizable.ui_towerSweepLvTooBig, self.maxRound), -1)
		self.editLv:setText(self.maxRound)
		return nil
	end

	self.goalRound = lv
	self.totalTime = self.costTime *(self.goalRound - self.curRound + 1)

	self.labelTime:setString(tools.convertTimeElectronicWatchChinese(self.totalTime, 3))
--]]
end


---------------------common------------------------

function onNodeCleanup(self)
    if self.proxy_ then
        self.proxy_:release()
    end
    layer_base_t.onNodeCleanup(self)
end

function getNumber(data, name)
    return tonumber(data:find(name)[1])
end

function init_btn_binding_event(self, btn_node, callback, btn_title_text)
    btn_node:setTouchEnabled(true)
    btn_node:setTouchPriority(kCCMenuHandlerPriority - 1)
    self.proxy_:handleButtonEvent(btn_node, callback , CCControlEventTouchUpInside)
    if btn_title_text ~= nil then
        btn_node:setTitleForState(btn_title_text, CCControlStateNormal)
        btn_node:setTitleForState(btn_title_text, CCControlStateHighlighted)
        btn_node:setTitleForState(btn_title_text, CCControlStateDisabled)    
    end
end