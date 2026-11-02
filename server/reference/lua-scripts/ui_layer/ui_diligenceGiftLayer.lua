------------------------------------------------------------------------
--  Copyright (c) 2011-2015, XCKOO. All Rights Reserved.
--  Author :Tango
--  FName  :ui_diligenceGiftLayer.lua
--  Time   :2014/11/03 11:12:37
--  Remark :勤奋礼包
------------------------------------------------------------------------
module("ui_diligenceGiftLayer", package.seeall)
baseClass(layer_base_t, ui_diligenceGiftLayer)

function init(self, node)
	self.contentNode_ = GetActivityView():GetNodeContent()
	self.contentSize_ = self.contentNode_:getContentSize()

	local ccbiAttrTable = {name="activity/DiligenceGiftView.ccbi", size=self.contentSize_}
	layer_base_t.init(self, true, ccbiAttrTable)

	--用户info
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	--pre node
	self.preNode = node

	--datas
	self.award_datas = {}
	--tableView cell container
	self.cellNodes = {}
	--touch
	self.m_touchPoint = nil
	self.m_touchBegan = nil
	self.m_touchEnd = nil

	--活动剩余时间
	self.m_left_time = 0
	--时间增量
	self.deltatime = 0

	self:init_ui()
	self:init_binding_event()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		--label
		self.label_act_time = tolua.cast(self.proxy_:getNode("label_time"), "CCLabelTTF")
		--node
		self.node_content = tolua.cast(self.proxy_:getNode("node_gift_table_content"), "CCNode")
		self.node_cell = tolua.cast(self.proxy_:getNode("node_gift_cell_node"), "CCNode")

		--init
		self:pre_base_info()
	end
end

function pre_base_info(self)
	--活动时间刷新
	local function updateActTimeLabel(fDeltaTime)
		self.deltatime = self.deltatime + fDeltaTime
		if self.deltatime >= 1 then
			if 0 == self.m_act_state then
				self.label_update_time:unscheduleUpdate()
				self.label_act_time:setString(localizable.ui_monopoly_end)
			end
			local intPart, floatPart = math.modf(self.deltatime)
			self.m_left_time = self.m_left_time - intPart
			if self.m_left_time > 0 then
				local timeStr = tools.convertTimeElectronicWatch(self.m_left_time, 3)
				self.label_act_time:setString(timeStr)
				self.deltatime = floatPart
			else
				self.label_act_time:setString(localizable.ui_monopoly_end)
				self.label_act_time:unscheduleUpdate()
			end
		end
	end

	--请求基本信息
	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 1, "rl_r_multiple_task")
	--cclog("rl_r_multiple_task & cmd = 1---%s", urlpath)
	GetMainMenu():ShowLoadingDlg()
	CCHttpRequest:open(urlpath, kHttpPost, "query=param1&other=params"):sendWithHandler(
		function(res, hnd)
			GetMainMenu():CloseLoadding()
			local resData = res:getResponseData()
			local code = res:getResponseCode()
			local xfile = xml.parse(resData)
			local item = xfile:find("RENLONG")
			if item == nil then
				return nil
			end
			--cclog("%s", resData)
			local retcode = item.code
			if retcode == "0" then
				--basic
				local tasks = item:find("tasks")
				if tasks then
					for i=1,#tasks do
						table.insert(self.award_datas,tasks[i])
					end
				end

				--活动剩余时间
				self.m_left_time = tonumber(item:find("remain")[1])

				--实时更新活动时间
				if self.m_left_time > 0 then
					self.m_act_state = 1
					self.label_act_time:scheduleUpdateWithPriorityLua(updateActTimeLabel, 0)
					self.label_act_time:setString(tools.convertTimeElectronicWatch(self.m_left_time, 3))
				else
					self.m_act_state = 0
					self.label_act_time:setString(localizable.ui_monopoly_end)
				end
				
				--update
				self:init_ui_ext()
			else
				GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
			end
		end)
end

function init_ui_ext(self)
	self:creatTabelView()
end

function creatTabelView(self)
	-- body
	if self._tableView == nil then
		local cellContentSize = self.node_cell:getContentSize()
		self.cell_size = CCSizeMake(cellContentSize.width,cellContentSize.height)

		self.content_size = self.node_content:getContentSize()
		self:initPicTableHandle()
		self._tableView = LuaTableView:createWithHandler(self._tableViewHandler, CCSizeMake(self.content_size.width, self.content_size.height))
		self._tableView:setDirection(kCCScrollViewDirectionVertical)
		self._tableView:setVerticalFillOrder(kCCTableViewFillTopDown)
		self._tableView:setTouchPriority(kCCMenuHandlerPriority - 1)
		
		self.node_content:addChild(self._tableView)
	else
		self._tableView:reloadData()
	end
end

function initPicTableHandle(self)
	self._tableViewHandler = LuaEventHandler:create(function(fn, table, a1, a2, x, y)
		local r
		if fn == "cellSize" then
			r = self.cell_size;
		elseif fn == "cellAtIndex" then
    		local nodeLayer = createObj(ui_diligenceGiftCell, self.cell_size, self.award_datas[a1 + 1])
			--tableView cell container
			self.cellNodes[a1+1] = nodeLayer
			if not a2 then
				a2 = CCTableViewCell:create()
				a2:addChild(nodeLayer.node_)
			else
				a2:removeAllChildrenWithCleanup(true)
        		a2:addChild(nodeLayer.node_)
			end

			nodeLayer.node_:setTag(100)

			r = a2
		elseif fn == "numberOfCells" then
			r = #self.award_datas;
		    -- Cell events:
		elseif fn == "cellTouched" then			-- A cell was touched, a1 is cell that be touched. This is not necessary.
			local cell_index = a1:getIdx() + 1
			local _layer = self.cellNodes[cell_index]

			if _layer.btnBuy:boundingBox():containsPoint(self.m_touchPoint) then
				self:GetAward(cell_index)
			end

			self.m_touchPoint = nil
		elseif fn == "cellTouchBegan" then		-- A cell is touching, a1 is cell, a2 is CCTouch
			self.m_touchPoint = a2:getLocation()
			self.m_touchPoint = a1:convertToNodeSpace(self.m_touchPoint)

			local cell_index = a1:getIdx() + 1

			r = true
		elseif fn == "cellTouchEnded" then		-- A cell was touched, a1 is cell, a2 is CCTouch
			r = true
		elseif fn == "cellHighlight" then		-- A cell is highlighting, coco2d-x 2.1.3 or above
		elseif fn == "cellUnhighlight" then		-- A cell had been unhighlighted, coco2d-x 2.1.3 or above
		elseif fn == "cellWillRecycle" then		-- A cell will be recycled, coco2d-x 2.1.3 or above
		end
		return r
	end)
end

function GetAward(self, index)

	if self.award_datas[index] == nil then
		return nil
	end

	--检查条件
	if "0" == self.award_datas[index].current_recv then
		GetMainMenu():ShowTextTip(localizable.ui_diligenceGift_noneLeft,-1)
		return nil
	end

	if "0" == self.award_datas[index].can_recv then
		GetMainMenu():ShowTextTip(localizable.ui_diligenceGift_checkError,-1)
		return nil
	end


	local giftid = tonumber(self.award_datas[index].id)
	--请求信息
	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 2, "rl_r_multiple_task")
	urlpath = AddData(urlpath, "AwardID", giftid)
	--cclog("rl_w_dailycost & cmd = 2---%s", urlpath)
	GetMainMenu():ShowLoadingDlg()
	CCHttpRequest:open(urlpath, kHttpPost, "query=param1&other=params"):sendWithHandler(
		function(res, hnd)
			GetMainMenu():CloseLoadding()
			local resData = res:getResponseData()
			local code = res:getResponseCode()
			local xfile = xml.parse(resData)
			local item = xfile:find("RENLONG")
			if item == nil then
				return nil
			end
			--cclog("%s", resData)
			local retcode = item.code
			if retcode == "0" then	
				local awardXML = item:find("award")
				--只加入背包/显示掉落动画	
				ShowAward(awardXML)	
				--GetMainMenu():ShowTextTip(localizable.ui_daily_get_gift_success, -1)
				--标志
				local remain = tonumber(self.award_datas[index].current_recv) - 1
				self.award_datas[index].current_recv = tostring(remain)	
				--update
				self:updateUI()
			else
				GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
			end
		end)
end

function updateUI(self)
	self._tableView:reloadData()
end

function init_binding_event(self)
	if self.proxy_ ~= nil then
		--[[
		local function CCLayerTouch(event, x, y)
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
		self.node_:registerScriptTouchHandler(CCLayerTouch, false, kCCMenuHandlerPriority-1, true)
		--]]
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