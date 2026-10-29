----------------------------------------------------------------------
--  Copyright (c) 2014-2016, XCKOO. All Rights Reserved.
--  Author :Tango
--  Time   :2015/1/13 15:19:23
--  Remark :排行榜奖励查看
----------------------------------------------------------------------

module("ui_borderWarRankAwardPreviewLayer", package.seeall)
baseClass(layer_base_t, ui_borderWarRankAwardPreviewLayer)

function init(self, node, data)
	self.contentSize_ = GetMainMenu():GetModelLayer():getContentSize()
	local ccbiAttrTable = {name="activity/BorderWarRankAwardPreview.ccbi", size=self.contentSize_}
	layer_base_t.init(self, true, ccbiAttrTable)

	--用户info
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	--pre info
	self.preNode = node

	self.m_touchPoint = nil
	self.data = data
	
	--init
	self:init_ui()		
	self:init_binding_event()

	self:init_ext_ui()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		--btn
		self.btnClose = tolua.cast(self.proxy_:getNode("btn_close"), "CCControlButton")
		self.btnOk = tolua.cast(self.proxy_:getNode("btn_ok"), "CCControlButton")

		self.labelAward = tolua.cast(self.proxy_:getNode("label_award"),"CCLabelTTF")

		self:init_ext_ui()
	end
end

function init_ext_ui(self)
	local str = string.gsub(self.data, "|", function ( p ) return "\r\n" end)
	self.labelAward:setString(str)
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
		end, CCControlEventTouchDown)

		self.btnOk:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.proxy_:handleButtonEvent(self.btnOk, function(button, event)
			self:close()
		end , CCControlEventTouchDown)
	end
end

function onNodeCleanup(self)
	if self.proxy_ then
    	self.proxy_:release()
    end

    layer_base_t.onNodeCleanup(self)
end
