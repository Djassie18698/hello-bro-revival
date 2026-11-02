--
-- Author: tango
-- Date: 2015-12-29 16:53:17
--

module("ui_godRecruitReturnLayer", package.seeall)
baseClass(layer_base_t, ui_godRecruitReturnLayer)

function init(self, gold )
	self.contentSize_ = GetMainMenu():GetModelLayer():getContentSize()

	local ccbiAttrTable = {name="activity/GodRecruitReturn.ccbi", size=self.contentSize_}
	layer_base_t.init(self, true, ccbiAttrTable)

	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	self.addGold = gold

	--init
	self:init_ui()		
	self:init_binding_event()
end

function init_ui(self)
	if self.proxy_ ~= nil then

		self.btnOK = getButtonFromCCB(self.proxy_, 'btnOK')

		getLabelTTFFromCCB(self.proxy_, 'label_title'):setString(localizable.ui_godRecruit_winTitle)
		self.labelName = getLabelTTFFromCCB(self.proxy_, 'lb_name')
		self.labelName:setString(self.addGold .. localizable.ui_text_gold)

	end
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

		self.btnOK:setTouchPriority(kCCMenuHandlerPriority-1)
		self.proxy_:handleButtonEvent(self.btnOK, function(button, event)
			self:close()
		end, CCControlEventTouchDown)
	end
end

function close(self )
	self.node_:removeFromParentAndCleanup(true)
end

function onNodeCleanup(self)
	if self.proxy_ then
    	self.proxy_:release()
    end

    layer_base_t.onNodeCleanup(self)
end
