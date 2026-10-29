--边界碑奖励通用框
--litao
--2014-2-17
---------------------------------------------
module("ui_borderWarCommonRewardDlg", package.seeall)
baseClass(layer_base_t, ui_borderWarCommonRewardDlg)

function init(self, node, data)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	local winSize = CCDirector:sharedDirector():getWinSize()

	--Load res
	local ccbiAttrTable = {name="activity/BorderWarAttackView.ccbi", size=CCSizeMake(768, winSize.height)}
	layer_base_t.init(self, true, ccbiAttrTable)

	self.preNode = node
	--数据
	self.m_awardData = data

	self:init_ui()
	self:init_binding_event()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		--ok
		self.btnOk = tolua.cast(self.proxy_:getNode("attack_ok"), "CCControlButton")		
		--关闭按钮
		self.btnDialogClose = tolua.cast(self.proxy_:getNode("closeButton"), "CCControlButton")
		self.btnClose = tolua.cast(self.proxy_:getNode("attack_close"), "CCControlButton")
		--关闭按钮居中
		local layer_size = self.node_:getContentSize()
		local ptx, pty = self.btnClose:getPosition()
		self.btnClose:setPosition(ccp(layer_size.width * 0.5, pty))
		--node
		self.node_1 = tolua.cast(self.proxy_:getNode("attack_node_1"), "CCNode")
		self.node_2 = tolua.cast(self.proxy_:getNode("attack_node_2"), "CCNode")
		self.node_3 = tolua.cast(self.proxy_:getNode("attack_node_3"), "CCNode")
		--label
		self.label_desc = tolua.cast(self.proxy_:getNode("label_desc"), "CCLabelTTF")
		self.label_exp = tolua.cast(self.proxy_:getNode("attack_expLabel"), "CCLabelTTF")
		self.label_merit = tolua.cast(self.proxy_:getNode("attack_scoreLabel"), "CCLabelTTF")
		self.label_title = tolua.cast(self.proxy_:getNode("titleLabel"), "CCLabelTTF")

		--initUI
		self:init_ui_info()	
	end
end

function init_ui_info(self)
	self.node_1:setVisible(false)
	self.node_2:setVisible(false)
	self.node_3:setVisible(false)
	self.btnOk:setVisible(false)
	self.btnOk:setEnabled(false)

	self.label_desc:setVisible(true)
	self.label_desc:setString(tostring(self.m_awardData.descText))
	self.label_exp:setString(tostring(self.m_awardData.exp))
	self.label_merit:setString(tostring(self.m_awardData.merit))
	self.label_title:setString(tostring(self.m_awardData.title))
end

function init_binding_event(self)
	if self.proxy_ ~= nil then
		local function CCLayerTouch(event,x,y)
			local rect = self.preNode.node_:boundingBox()
			rect.origin = ccp(0,0)
			local p = self.preNode.node_:convertToNodeSpace(ccp(x,y))
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

		local function close_window(btn, event)
			self.node_:removeFromParentAndCleanup(true)
		end

		--绑定按钮事件
		self.btnDialogClose:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.proxy_:handleControlEvent(self.btnDialogClose, close_window, CCControlEventTouchUpInside)

		self.btnClose:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.proxy_:handleControlEvent(self.btnClose, close_window, CCControlEventTouchUpInside)
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