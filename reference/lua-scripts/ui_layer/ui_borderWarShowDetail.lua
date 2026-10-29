--边界碑_tip
--litao
--2014.2.15
---------------------------------------------
module("ui_borderWarShowDetail", package.seeall)
baseClass(layer_base_t, ui_borderWarShowDetail)

function init(self, data)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()
	local winSize = CCDirector:sharedDirector():getWinSize()
	--Load res
	local ccbiAttrTable = {name="activity/BorderWarDetailView.ccbi", size=CCSizeMake(768, winSize.height)}
	layer_base_t.init(self, true, ccbiAttrTable)

	self.m_noticeDatas = data

	self:init_ui()
	self:init_binding_event()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		self.btnDialogClose = tolua.cast(self.proxy_:getNode("closeButton"), "CCControlButton")
		self.btnClose = tolua.cast(self.proxy_:getNode("btn_close"), "CCControlButton")

		self.scroll_layer = tolua.cast(self.proxy_:getNode("scroll_layer"), "CCLayer")

		self.label_desc_1 = tolua.cast(self.proxy_:getNode("label_desc_1"), "CCLabelTTF")
		self.label_desc_2 = tolua.cast(self.proxy_:getNode("label_desc_2"), "CCLabelTTF")
		self.label_desc_3 = tolua.cast(self.proxy_:getNode("label_desc_3"), "CCLabelTTF")
		self.label_desc_4 = tolua.cast(self.proxy_:getNode("label_desc_4"), "CCLabelTTF")

		self.detail_node_1 = tolua.cast(self.proxy_:getNode("detail_node_1"), "CCNode")
		self.detail_node_2 = tolua.cast(self.proxy_:getNode("detail_node_2"), "CCNode")
		self.detail_node_3 = tolua.cast(self.proxy_:getNode("detail_node_3"), "CCNode")
		self.detail_node_4 = tolua.cast(self.proxy_:getNode("detail_node_4"), "CCNode")

		self.label_desc_1:setString(tostring(self.m_noticeDatas.desc_1))
		self.label_desc_2:setString(tostring(self.m_noticeDatas.desc_2))
		self.label_desc_3:setString(tostring(self.m_noticeDatas.desc_3))
		self.label_desc_4:setString(tostring(self.m_noticeDatas.desc_4))

		--信息排版
		local descSize_1 = self.label_desc_1:getContentSize()
		local descSize_2 = self.label_desc_2:getContentSize()
		local descSize_3 = self.label_desc_3:getContentSize()
		local descSize_4 = self.label_desc_4:getContentSize()
		local nodeSize_1 = self.detail_node_1:getContentSize()
		local nodeSize_2 = self.detail_node_2:getContentSize()
		local nodeSize_3 = self.detail_node_3:getContentSize()
		local nodeSize_4 = self.detail_node_4:getContentSize()

		--desc_1
		local ptx, pty = self.detail_node_1:getPosition()
		self.label_desc_1:setPosition(ccp(ptx, pty - nodeSize_1.height -2))
		--node_2
		ptx, pty = self.label_desc_1:getPosition()	
		self.detail_node_2:setPosition(ccp(ptx, pty - descSize_1.height - 2))
		--desc_2
		ptx, pty = self.detail_node_2:getPosition()
		self.label_desc_2:setPosition(ccp(ptx, pty - nodeSize_2.height - 2))
		--node_3
		ptx, pty = self.label_desc_2:getPosition()
		self.detail_node_3:setPosition(ccp(ptx, pty - descSize_2.height - 2))
		--desc_3
		ptx, pty = self.detail_node_3:getPosition()
		self.label_desc_3:setPosition(ccp(ptx, pty - nodeSize_3.height - 2))
		--node_4
		ptx, pty = self.label_desc_3:getPosition()
		self.detail_node_4:setPosition(ccp(ptx, pty - descSize_3.height - 2))
		--desc_4
		ptx, pty = self.detail_node_4:getPosition()
		self.label_desc_4:setPosition(ccp(ptx, pty - nodeSize_4.height - 2))

		--滚动条
		local layer = tolua.cast(self.proxy_:getNode("layer_scollview"), "CCScrollView")				
		self.scroll_layer:removeFromParentAndCleanup(false)
		--滚动区域
		local s_layerSize = self.scroll_layer:getContentSize()
		--设置可视区域
		--layer:setViewSize(CCSizeMake(s_layerSize.width, layer:getContentSize().height))		
		--设置scrollview区域的大小
		--layer:setContentSize(CCSizeMake(s_layerSize.width, s_layerSize.height))
		--添加节点
		layer:setContainer(self.scroll_layer)
		layer:setContentOffset(ccp(0,0))
		--触摸优先级
		layer:setTouchPriority(kCCMenuHandlerPriority - 1)
	end
end

function init_binding_event(self)
	if self.proxy_ ~= nil then
		local function CCLayerTouch(event,x,y)
			local rect = self.node_:boundingBox()
			rect.origin = ccp(0,0)
			local p = self.node_:convertToNodeSpace(ccp(x,y))
			if event == "began" then
				if rect:containsPoint(p) == true then
					return true
				else
					return true
				end
			end
		end
		self.node_:setTouchEnabled(true)
		self.node_:registerScriptTouchHandler(CCLayerTouch, false, kCCMenuHandlerPriority - 1, true)

		local function close_window(btn, event)
			self.node_:removeFromParentAndCleanup(true)
		end

		--绑定按钮事件
		self.btnClose:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.proxy_:handleButtonEvent(self.btnClose, close_window, CCControlEventTouchUpInside)

		self.btnDialogClose:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.proxy_:handleControlEvent(self.btnDialogClose, close_window, CCControlEventTouchUpInside)
	end
end

function onNodeCleanup(self)
    layer_base_t.onNodeCleanup(self)
end