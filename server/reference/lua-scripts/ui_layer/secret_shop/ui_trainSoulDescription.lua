--descriptioin:煉化結果界面
--company: xckoo
--author: chenchun
--date: 2014-3-17
---------------------------------------------
module("ui_trainSoulDescription", package.seeall)
baseClass(layer_base_t, ui_trainSoulDescription)

function init(self, data)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	self.contentSize_ = CCDirector:sharedDirector():getWinSize()
	local ccbiAttrTable = {name="secretshop/trainSoulDescription.ccbi", size=self.contentSize_}
	layer_base_t.init(self, true, ccbiAttrTable)

	self.data = data
	self:init_ui()
	self:init_binding_event()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		self.labelDescription = tolua.cast(self.proxy_:getNode("labelDescription"), "CCLabelTTF")
		self.closeButton =  tolua.cast(self.proxy_:getNode("closeButton"), "CCControlButton")
		self.btn_ok =  tolua.cast(self.proxy_:getNode("btn_ok"), "CCControlButton")

		self.labelDescription:setString(localizable.ui_train_soul_description)
	end
end

function init_binding_event(self)
	if self.proxy_ ~= nil then
		local function closeDlg()
			self.node_:removeFromParentAndCleanup(true)
		end
		self.closeButton:setTouchPriority(-10)
		self.btn_ok:setTouchPriority(-10)

		self.proxy_:handleControlEvent(self.closeButton, closeDlg, CCControlEventTouchUpInside)
		self.proxy_:handleControlEvent(self.btn_ok, closeDlg, CCControlEventTouchUpInside)

		local function CCLayerTouch(event, x, y)
			if event == "began" then			
				return true
			end
		end

		self.node_:setTouchEnabled(true)
		self.node_:registerScriptTouchHandler(CCLayerTouch, false, -6, true)
	end
end

function onNodeCleanup(self)
	if self.proxy_ then
    	self.proxy_:release()
    end
    layer_base_t.onNodeCleanup(self)
end