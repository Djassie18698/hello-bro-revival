--
-- Author: tango
-- Date: 2015-12-25 11:13:45
--

module("ui_godRecruitWinLayer", package.seeall)
baseClass(layer_base_t, ui_godRecruitWinLayer)

function init(self, node, ninja)
	self.contentSize_ = GetMainMenu():GetModelLayer():getContentSize()

	local ccbiAttrTable = {name="activity/GodRecruitWin.ccbi", size=self.contentSize_}
	layer_base_t.init(self, true, ccbiAttrTable)

	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	self.ninja = ninja
	--pre info`
	self.parent = node

	--init
	self:init_ui()		
	self:init_binding_event()

	self:init_ext_ui()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		self.nodeContainer = getNodeFromCCB(self.proxy_, 'node_container')

		self.btnReturn = getButtonFromCCB(self.proxy_, 'btn_return')
		self.btnKeep = getButtonFromCCB(self.proxy_, 'btn_keep')

		self.sprNinja = getSpriteFromCCB(self.proxy_, 'spr_ninja')
		self.lbGold = getLabelBMFontFromCCB(self.proxy_, 'label_gold')

		getLabelTTFFromCCB(self.proxy_, 'label_unuse1'):setString(localizable.ui_godRecruitWin_unuse1)
		getLabelTTFFromCCB(self.proxy_, 'text_title'):setString(localizable.ui_godRecruit_winTitle)

	end
end


function init_ext_ui(self)	
	self.ninja_id = self.ninja.card_id
	local ninjaIcon, ninjaFrame, quality = rl_get_iconsprite("1", "1", E_FRAMETYPE_MIDDLE, self.ninja_id)
	if ninjaIcon ~= nil then

		ninjaFrame = rl_get_ninjaFrame(E_FRAMETYPE_MIDDLE, quality)
		if ninjaFrame ~= nil then
			self.sprNinja:setDisplayFrame(ninjaFrame)
		end

		local size = self.sprNinja:getContentSize()
		ninjaIcon:setPosition(size.width/2, size.height/2)
		ninjaIcon:setScale(0.5)
		self.sprNinja:removeAllChildrenWithCleanup(true)
		self.sprNinja:addChild(ninjaIcon)
	end

	self.lbGold:setString(self.ninja.card_drop_gold)
end

function onClickedIcon( self, line, i )
	CGameObjElement:ShowDropByID(_id_icon)
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

		self.btnReturn:setTouchPriority(kCCMenuHandlerPriority-1)
		self.proxy_:handleButtonEvent(self.btnReturn, function(button, event)
			self:requestReturn()
		end, CCControlEventTouchDown)

		self.btnKeep:setTouchPriority(kCCMenuHandlerPriority-1)
		self.proxy_:handleButtonEvent(self.btnKeep, function(button, event)
			self:requestKeep()
		end, CCControlEventTouchDown)

	end
end

function close(self )
	self.node_:removeFromParentAndCleanup(true)
end

function requestReturn( self, id)
	local function returnCallback( renlong)
		local add = tonumber(renlong:find('add_cash')[1])
		local gold = tonumber(renlong:find('left_cash')[1])
		local curScore = tonumber(renlong:find('left_score')[1])

		CPlayerDataMgr:instance():SetGold(gold)
		
		self:scaleOut(add)
		self.parent:setScore(curScore)
	end

	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 20, "rl_x_small_activity")
	sendRequest(urlpath, returnCallback, 1)
end

function scaleOut( self, add )
	local scale = CCScaleTo:create(0.5, 1.0, 0.01)

	local function callback(  )
		self:close()
		require('ui_layer/ui_godRecruitReturnLayer')
		showModelLayer(ui_godRecruitReturnLayer, add)
	end 

	local callfunc = CCCallFunc:create(callback)
	local sequence = CCSequence:createWithTwoActions(scale, callfunc)
	self.nodeContainer:runAction(sequence)
end

function requestKeep( self,id )
	local function keepCallback( renlong)
		local awardXML = renlong:find("award")
		--只加入背包/显示掉落动画	
		ShowAward(awardXML)
		self:close()
	end

	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 19, "rl_x_small_activity")
	sendRequest(urlpath, keepCallback, 1)
end

function onNodeCleanup(self)
	if self.proxy_ then
    	self.proxy_:release()
    end

    layer_base_t.onNodeCleanup(self)
end
