----------------------------------------------------------------------
--  Copyright (c) 2014-2016, XCKOO. All Rights Reserved.
--  Author :Tango
--  Time   :2014/11/11 21:32:00
--  Remark :组织成员管理
----------------------------------------------------------------------
module("ui_orgMemManageLayer", package.seeall)
baseClass(layer_base_t, ui_orgMemManageLayer)

function init(self, node)
	self.contentSize_ = GetMainMenu():GetModelLayer():getContentSize()
	local ccbiAttrTable = {name="sub_ui/OrgMemManageView.ccbi", size=self.contentSize_}
	layer_base_t.init(self, true, ccbiAttrTable)

	--用户info
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	--pre info
	self.preNode = node

	self.m_touchPoint = nil
	
	--init
	self:init_ui()		
	self:init_binding_event()

	self:init_ext_ui()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		self.node_content = tolua.cast(self.proxy_:getNode("node_content"), "CCNode")
		self.node_cell = tolua.cast(self.proxy_:getNode("node_cell"), "CCNode")
		--btn
		self.btnClose = tolua.cast(self.proxy_:getNode("btn_close"), "CCControlButton")

		self.btnExpel = tolua.cast(self.proxy_:getNode("btn_kickout"), "CCControlButton")
		self.btnCheck = tolua.cast(self.proxy_:getNode("btn_accept"), "CCControlButton")
		self.btnDutyManage = tolua.cast(self.proxy_:getNode("btn_dutyManage"), "CCControlButton")

		--get info
		--self:requestBaseInfo()
	end
end


function requestBaseInfo(self)
	
end

function init_ext_ui(self)	

end

function close( self )
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

		self.btnExpel:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.proxy_:handleButtonEvent(self.btnExpel, function(button, event)
			self:close()
			require("ui_layer/ui_orgMemExpelLayer")
			showModelLayer(ui_orgMemExpelLayer,self.preNode)

		end , CCControlEventTouchDown)

		self.btnCheck:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.proxy_:handleButtonEvent(self.btnCheck, function(button, event)
			self:close()
			require("ui_layer/ui_orgMemCheckLayer")
			showModelLayer(ui_orgMemCheckLayer,self.preNode)
		end , CCControlEventTouchDown)

		self.btnDutyManage:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.proxy_:handleButtonEvent(self.btnDutyManage, function(button, event)
			self:close()
			require("ui_layer/ui_orgMemOfficeLayer")
			showModelLayer(ui_orgMemOfficeLayer,self.preNode)
		end , CCControlEventTouchDown)

	end
end

function onNodeCleanup(self)
	if self.proxy_ then
    	self.proxy_:release()
    end

    layer_base_t.onNodeCleanup(self)
end
