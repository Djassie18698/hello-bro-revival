--descriptioin:活动弹出页面
--company: xckoo
--author: chenchun
--date: 2013-12-23
---------------------------------------------
module("ui_activityPopupLayer", package.seeall)
baseClass(layer_base_t, ui_activityPopupLayer)

getPopupActivityData = {}

function init(self)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	self.contentSize_ = CCDirector:sharedDirector():getWinSize()
	local ccbiAttrTable = {name="activity/ActivityPopup.ccbi", size=self.contentSize_}
	layer_base_t.init(self, true, ccbiAttrTable)

	--self.node_:setAnchorPoint(ccp(0.5, 0.5))

	self:createActivityData()

	--self:createTestData()
	ui_activityPopupTableCell.ispopup = false
	self.cellNodes = {}
	self.proxyNodes = {}
	self:init_ui()
	self:init_binding_event()
end

function init_ui(self)
	if self.proxy_ ~= nil then

		self.node_activity_tablecontent = tolua.cast(self.proxy_:getNode("node_activity_tablecontent"), "CCNode")
		self.node_activity_cellnode = tolua.cast(self.proxy_:getNode("node_activity_cellnode"), "CCNode")
		self.ctrl_next_page = tolua.cast(self.proxy_:getNode("ctrl_next_page"), "CCControlButton")
		self.layer_container = tolua.cast(self.proxy_:getNode("layer_container"), "CCLayer")

		--local tempNum = #ui_activityPopupLayer.getPopupActivityData

		if #ui_activityPopupLayer.getPopupActivityData > 12 then
			self.ctrl_next_page:setVisible(true)
		else
			self.ctrl_next_page:setVisible(false)
		end
		--self:createActivityTableView(self.reCreateData)

		self:createActivityTableView(self.reCreateData)

		--[[
		local urlpath = GetUrlNormalHeader(self.playerData_.m_uid,  protocol.CMD_R_COMM, protocol.URL_R_COMM)
		GetMainMenu():ShowLoadingDlg()	--获取信息的时候，不允许操作
		CCHttpRequest:open(urlpath, kHttpPost,"query=param1&other=params"):sendWithHandler(
			function(res, hnd)
				GetMainMenu():CloseLoadding() --获取信息完成时，解除禁止操作
				local resData = res:getResponseData()
				local code = res:getResponseCode()
				local xfile = xml.parse(resData)
				local item = xfile:find("RENLONG")
				local retcode = item.code
				if retcode == "0" then

				end
			end)
		]]
	end
end


function init_binding_event(self)

	if self.proxy_ ~= nil then
		local function removePopupLayer(event, x, y)

			ui_activityPopupLayer.instanceNode = nil
	        self.node_:removeFromParentAndCleanup(true)
			if event == "began" then
				return true;
			end
		end
		self.node_:setTouchMode(kCCTouchesOneByOne)
		self.node_:setTouchEnabled(true)
		self.node_:registerScriptTouchHandler(removePopupLayer, false, kCCMenuHandlerPriority-1, true)

		local function containerTouch(event, x, y)
			if event == "began" then
				--local touchPoint = self.layer_container:convertToNodeSpace(ccp(x, y))
				if self.layer_container:boundingBox():containsPoint(ccp(x, y)) then
        			return true
				else
					return false
        		end
    		end
		end
		self.layer_container:setTouchEnabled(true)
		self.layer_container:registerScriptTouchHandler(containerTouch, false, kCCMenuHandlerPriority-50, true)
	end
end



--local funtion
function createActivityTableView(self, data)
	-- body
	if self.activityTableView == nil then
		self.cellsize = self.node_activity_cellnode:getContentSize()
		self.tableContentSize = self.node_activity_tablecontent:getContentSize()
		self:initActivityTableHandle()
		self.activityTableView = LuaTableView:createWithHandler(self.activityTableViewHandler, CCSizeMake(self.tableContentSize.width, self.tableContentSize.height))
		self.activityTableView:setDirection(kCCScrollViewDirectionVertical)
		self.activityTableView:setVerticalFillOrder(kCCTableViewFillTopDown)
		self.activityTableView:setTouchPriority(kCCMenuHandlerPriority-51)
		self.node_activity_tablecontent:addChild(self.activityTableView)
		self.activityTableView:reloadData()

		--local offset = self.activityTableView:getContentOffset()
		--self.activityTableView:reloadData()
		--self.activityTableView:setContentOffset(offset.x, offset.y)
		
		local defaultMenu = tolua.cast(GetMainMenu():GetCurrentSubMenu(), "CDefaultMainMenu")
		if defaultMenu ~= nil then
			local node = self.proxyNodes[1]:getNode("sprite_activity_3")
			defaultMenu:onStepNextForLua(self.activityTableView, node)
		end
	end
end

function initActivityTableHandle(self)
	self.activityTableViewHandler = LuaEventHandler:create(function(fn, table, a1, a2, x, y)
		local r
		if fn == "cellSize" then
			r = self.cellsize;
		elseif fn == "cellAtIndex" then
    		--local nodeLayer = createObj(ui_activityPopupTableCell, self.cellsize, self.reCreateData[a1 + 1])
    		local nodeLayer = createObj(ui_activityPopupTableCell, self.cellsize, self.reCreateData[a1 + 1])
    		self.cellNodes[a1 + 1] = nodeLayer
			self.proxyNodes[a1 + 1] = nodeLayer.proxy_
			if not a2 then
				a2 = CCTableViewCell:create()
				nodeLayer.node_:setTag(100)
				a2:addChild(nodeLayer.node_)
			else
				a2:removeAllChildrenWithCleanup(true)
				nodeLayer.node_:setTag(100)
        		a2:addChild(nodeLayer.node_)
			end
			r = a2
		elseif fn == "numberOfCells" then
			r = #self.reCreateData;
		    -- Cell events:
		elseif fn == "cellTouched" then			-- A cell was touched, a1 is cell that be touched. This is not necessary.
			local cellIndex = a1:getIdx() + 1
			if self.cellNodes[cellIndex].node_content_1 ~= nil and self.cellNodes[cellIndex].node_content_1:boundingBox():containsPoint(self.m_touchPoint) then
				self.cellNodes[cellIndex]:btn_change_to_sub(1)
				self.node_:removeFromParentAndCleanup(true)
			elseif self.cellNodes[cellIndex].node_content_2 ~= nil and self.cellNodes[cellIndex].node_content_2:boundingBox():containsPoint(self.m_touchPoint) then
				self.cellNodes[cellIndex]:btn_change_to_sub(2)
				self.node_:removeFromParentAndCleanup(true)
			elseif self.cellNodes[cellIndex].node_content_3 ~= nil and self.cellNodes[cellIndex].node_content_3:boundingBox():containsPoint(self.m_touchPoint) then
				self.cellNodes[cellIndex]:btn_change_to_sub(3)
				self.node_:removeFromParentAndCleanup(true)
			elseif self.cellNodes[cellIndex].node_content_4 ~= nil and self.cellNodes[cellIndex].node_content_4:boundingBox():containsPoint(self.m_touchPoint) then
				self.cellNodes[cellIndex]:btn_change_to_sub(4)
				self.node_:removeFromParentAndCleanup(true)
			end
		elseif fn == "cellTouchBegan" then		-- A cell is touching, a1 is cell, a2 is CCTouch
			self.m_touchPoint = a2:getLocation()
			local cellIndex = a1:getIdx() + 1
			local cell = a1:getChildByTag(100);
			self.m_touchPoint = cell:convertToNodeSpace(self.m_touchPoint)
			if self.cellNodes[cellIndex].node_content_1 ~= nil and self.cellNodes[cellIndex].node_content_1:boundingBox():containsPoint(self.m_touchPoint) then
				self.cellNodes[cellIndex]["sprite_activity_bg_1"]:setVisible(true)
			elseif self.cellNodes[cellIndex].node_content_2 ~= nil and self.cellNodes[cellIndex].node_content_2:boundingBox():containsPoint(self.m_touchPoint) then
				self.cellNodes[cellIndex]["sprite_activity_bg_2"]:setVisible(true)
			elseif self.cellNodes[cellIndex].node_content_3 ~= nil and self.cellNodes[cellIndex].node_content_3:boundingBox():containsPoint(self.m_touchPoint) then
				self.cellNodes[cellIndex]["sprite_activity_bg_3"]:setVisible(true)
			elseif self.cellNodes[cellIndex].node_content_4 ~= nil and self.cellNodes[cellIndex].node_content_4:boundingBox():containsPoint(self.m_touchPoint) then
				self.cellNodes[cellIndex]["sprite_activity_bg_4"]:setVisible(true)
			end
			r = true
		elseif fn == "cellTouchEnded" then		-- A cell was touched, a1 is cell, a2 is CCTouch
			r = true
		elseif fn == "cellHighlight" then		-- A cell is highlighting, coco2d-x 2.1.3 or above
		elseif fn == "cellUnhighlight" then		-- A cell had been unhighlighted, coco2d-x 2.1.3 or above
			local cell = a1:getChildByTag(100)
			local cellIndex = a1:getIdx() + 1
			if self.cellNodes[cellIndex]["sprite_activity_bg_1"] then
				self.cellNodes[cellIndex]["sprite_activity_bg_1"]:setVisible(false)
			end
			if self.cellNodes[cellIndex]["sprite_activity_bg_2"] then
				self.cellNodes[cellIndex]["sprite_activity_bg_2"]:setVisible(false)
			end
			if self.cellNodes[cellIndex]["sprite_activity_bg_3"] then
				self.cellNodes[cellIndex]["sprite_activity_bg_3"]:setVisible(false)
			end
			if self.cellNodes[cellIndex]["sprite_activity_bg_4"] then
				self.cellNodes[cellIndex]["sprite_activity_bg_4"]:setVisible(false)
			end
			r = true;
		elseif fn == "cellWillRecycle" then		-- A cell will be recycled, coco2d-x 2.1.3 or above
		end
		return r
	end)
end

--创建活动数据
---[[
function createActivityData(self)
	self.reCreateData = {}
	local index = 0
	for i = 1, #ui_activityPopupLayer.getPopupActivityData do
		local inpart, decimal = tools.getIntAndDecimal(i / 4)
		if decimal == 0 then
			index = inpart
		else
			index = inpart + 1
		end
		self.reCreateData[index] = self.reCreateData[index] or {}
		table.insert(self.reCreateData[index], ui_activityPopupLayer.getPopupActivityData[i])
	end

	--tools.printTable4Level(ui_activityPopupLayer.getPopupActivityData, "1111")
	--tools.printTable4Level(self.reCreateData, "2222")

end
--]]

--创建测试数据
---[[
function createTestData(self)
	for i = 1, 3 do
		self.allActivityData[i] = {id=i, name="loginPackActivity", icon="activity1", status=1, newscount=2}
	end
	for k = 4, 6 do
		self.allActivityData[k] = {id=k, name="loginPackActivity", icon="activity3", status=2, newscount=3}
	end
	for j = 7, 12 do
		self.allActivityData[j] = {id=j, name="business_proxy/accumulateMoney_business", icon="activity10", status=3, newscount=2}
	end
	self.reCreateData = {}
	local index = 0
	for i = 1, #self.allActivityData do
		local inpart, decimal = tools.getIntAndDecimal(i / 4)
		if decimal == 0 then
			index = inpart
		else
			index = inpart + 1
		end
		self.reCreateData[index] = self.reCreateData[index] or {}
		table.insert(self.reCreateData[index], self.allActivityData[i])
	end
end
--]]

function onNodeCleanup(self)
	--cclog("1111---001")
	if self.proxy_ then
    	self.proxy_:release()
    	self.proxy_ = nil
    end
    layer_base_t.onNodeCleanup(self)
end