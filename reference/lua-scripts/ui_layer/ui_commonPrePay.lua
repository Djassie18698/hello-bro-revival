--付费引导通用框
--litao
--2014-5-6
---------------------------------------------
require("config/firstpurchase_config")
require("ui_layer/ui_purchaseLayer")
require("ui_layer/ui_purchaseTableCell")

module("ui_commonPrePay", package.seeall)
baseClass(layer_base_t, ui_commonPrePay)

function init(self, node)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	--load res
	self.contentSize_ = GetMainMenu():GetModelLayer():getContentSize()
	local ccbiAttrTable = {name="dlg_ui/CommonPrePay.ccbi", size=self.contentSize_}
	layer_base_t.init(self, true, ccbiAttrTable)

	self.preNode = node

	self:init_ui()
	self:init_binding_event()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		--ok
		self.btnOk = tolua.cast(self.proxy_:getNode("leftButton"), "CCControlButton")		
		--关闭按钮
		--self.btnDialogClose = tolua.cast(self.proxy_:getNode("closeButton"), "CCControlButton")
		self.btnClose = tolua.cast(self.proxy_:getNode("rightButton"), "CCControlButton")
		--node
		self.node_anim = tolua.cast(self.proxy_:getNode("node_anim"), "CCNode")

		--initUI
		self:init_ui_info()	
	end
end

function init_ui_info(self)
	---[[
	local _size = self.node_anim:getContentSize()
	self.m_animLayer = createObj(ui_prePayAnim, _size)

	self.node_anim:addChild(self.m_animLayer.node_)

	self.m_animLayer.node_:setPosition(ccp(_size.width / 2, _size.height / 2))
	self.m_animLayer.node_:setAnchorPoint(ccp(0.5, 0.5))
	--]]
end

function init_binding_event(self)
	if self.proxy_ ~= nil then
		local function CCLayerTouch(event,x,y)
			if event == "began" then
				return true
			end
		end
		self.node_:setTouchEnabled(true)
		self.node_:registerScriptTouchHandler(CCLayerTouch, false, kCCMenuHandlerPriority - 1, true)

		local function close_window(btn, event)
			self.node_:removeFromParentAndCleanup(true)
		end

		local function onBtnOk(btn, event)
			--跳转充值页面
			local puchaseLayer = createObj(ui_purchaseLayer)
			GetMainMenu():GetModelLayer():AddDialog(puchaseLayer.node_, 3)
			--关闭自身按钮
			self.node_:removeFromParentAndCleanup(true)
		end

		--绑定按钮事件
		--self.btnDialogClose:setTouchPriority(kCCMenuHandlerPriority - 1)
		--self.proxy_:handleControlEvent(self.btnDialogClose, close_window, CCControlEventTouchUpInside)

		self.btnClose:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.proxy_:handleControlEvent(self.btnClose, close_window, CCControlEventTouchUpInside)

		self.btnOk:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.proxy_:handleControlEvent(self.btnOk, onBtnOk, CCControlEventTouchUpInside)
	end
end

function onNodeCleanup(self)
    --cclog("onNodeCleanup")
    if self.proxy_ then
    	self.proxy_:release()
    end
    layer_base_t.onNodeCleanup(self)
end

function createTestData(self)
	--testData
	return nil
end