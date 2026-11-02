----------------------------------------------------------------------
--  Copyright (c) 2014-2016, XCKOO. All Rights Reserved.
--  Author :Tango
--  Time   :2015/7/2 16:37:32
--  Remark :老虎机奖励兑换
----------------------------------------------------------------------
require("ui_layer/ui_slotMExchangeCell")

module("ui_slotMExchangeLayer", package.seeall)
baseClass(layer_base_t, ui_slotMExchangeLayer)

function init(self, node, data)
	self.contentSize_ = GetMainMenu():GetModelLayer():getContentSize()

	local ccbiAttrTable = { name = "activity/SlotMExchangeView.ccbi", size = self.contentSize_ }
	layer_base_t.init(self, true, ccbiAttrTable)

	-- 用户info
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	-- pre info`
	self.preNode = node
	-- tableView cell container
	self.cellNodes = { }

	self.tableData = { }
	self.m_touchPoint = nil
	-- 时间增量
	self.deltatime = 0

	self.state = 1
	-- 状态 1：未充值 2：已经充值未领取 3：已领取
	self.price = 0
	-- init
	self:init_ui()
	self:init_binding_event()

	self:init_ext_ui()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		-- label
		self.labelTime = tolua.cast(self.proxy_:getNode("label_time"), "CCLabelTTF")
		self.labelScore = tolua.cast(self.proxy_:getNode("label_score"), "CCLabelBMFont")
		-- node
		self.node_content = tolua.cast(self.proxy_:getNode("node_content"), "CCNode")
		self.node_cell = tolua.cast(self.proxy_:getNode("node_cell"), "CCNode")

		-- btn
		self.btn_close_dlg = tolua.cast(self.proxy_:getNode("closeButton"), "CCControlButton")

		-- get info
		self:requestBaseInfo()
	end
end

function requestBaseInfo(self)
	local function updateLeftTimeLabel(fDeltaTime)
		self.deltatime = self.deltatime + fDeltaTime
		if self.deltatime >= 1 then
			local intPart, floatPart = math.modf(self.deltatime)
			self.m_resttime = self.m_resttime - intPart
			if self.m_resttime > 0 then
				local timeStr = tools.convertTimeElectronicWatch(self.m_resttime, 3)
				self.labelTime:setString(timeStr)
				self.deltatime = floatPart
			else
				self.m_state = 1
				self.labelTime:unscheduleUpdate()
				self.labelTime:setString(localizable.ui_slotExchange_text5)
			end
		end
	end

	--- [[
	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 18, "rl_r_comm")
	cclog("rl_r_comm----%s", urlpath)

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
		local retcode = item.code
		-- cclog("resData = %s", resData)
		if retcode == "0" then
			local basic = item:find('basic')
			self.m_resttime = tonumber(basic:find("remain")[1])
			self.labelScore:setString(basic:find('score')[1])

			-- 实时更新活动时间
			if self.m_resttime > 0 then
				self.labelTime:scheduleUpdateWithPriorityLua(updateLeftTimeLabel, 0)
				self.labelTime:setString(tools.convertTimeElectronicWatch(self.m_resttime, 3))
			else
				self.labelTime:setString(localizable.ui_slotExchange_text5)
			end

			self.tableData = item:find('package')
			self:init_ext_ui()
			printTable(self.tableData)
		else
			GetMainMenu():ShowErrorTip(tonumber(retcode), -1)
		end
	end )
end

function init_ext_ui(self)
	-- self.labelTime:setString(tostring(self.cur_score.."/"..self.total_score))
	-- 列表
	self:createTableView()
	--
end


function createTableView(self)
	if self._tableView == nil then
		local cellContentSize = self.node_cell:getContentSize()
		self._cell_size = CCSizeMake(cellContentSize.width, cellContentSize.height)

		self._content_size = self.node_content:getContentSize()
		self:initTableHandle()
		self._tableView = LuaTableView:createWithHandler(self._tableViewHandler, CCSizeMake(self._content_size.width, self._content_size.height))
		self._tableView:setDirection(kCCScrollViewDirectionVertical)
		self._tableView:setVerticalFillOrder(kCCTableViewFillTopDown)
		self._tableView:setTouchPriority(kCCMenuHandlerPriority - 1)

		self.node_content:addChild(self._tableView)
	else
		self._tableView:reloadData()
	end
end

function onClickedIcon(self, line, i)
	CSoundMgr:instance():PlayEffect(SOUND_BUTTON)
	if line < 0 or line > #self.tableData then
		GetMainMenu():ShowTextTip(localizable.ui_hall_net_error, -1)
		return nil
	end
	if i < 0 or i > #self.tableData[line] then
		return nil
	end

	local _id_icon = tonumber(self.tableData[line][i].dropid)
	if nil ~= _id_icon then
		CGameObjElement:ShowDropByID(_id_icon)
	end

end

function initTableHandle(self)
	self._tableViewHandler = LuaEventHandler:create( function(fn, table, a1, a2, x, y)
		local r
		if fn == "cellSize" then
			r = self._cell_size;
		elseif fn == "cellAtIndex" then
			local nodeLayer = createObj(ui_slotMExchangeCell, self._cell_size, self.tableData[a1 + 1], self)
			-- tableView cell container
			self.cellNodes[a1 + 1] = nodeLayer
			if not a2 then
				a2 = CCTableViewCell:create()
				a2:addChild(nodeLayer.node_)
			else
				a2:removeAllChildrenWithCleanup(true)
				a2:addChild(nodeLayer.node_)
			end
			r = a2
		elseif fn == "numberOfCells" then
			r = #self.tableData
			-- Cell events:
		elseif fn == "cellTouched" then
			-- A cell was touched, a1 is cell that be touched. This is not necessary.
			local cell_index = a1:getIdx() + 1
			local _layer = self.cellNodes[cell_index]

			for i = 1, 4 do
				local btn = _layer["sprite_item" .. i]
				local bbox = btn:boundingBox()
				local x, y = btn:getPosition()

				bbox.origin.x, bbox.origin.y = x - btn:getContentSize().width / 2, y - btn:getContentSize().height / 2

				if bbox:containsPoint(self.m_touchPoint) then
					self:onClickedIcon(cell_index, i)
					break;
				end
			end

			self.m_touchPoint = nil
		elseif fn == "cellTouchBegan" then
			-- A cell is touching, a1 is cell, a2 is CCTouch
			self.m_touchPoint = a2:getLocation()
			self.m_touchPoint = a1:convertToNodeSpace(self.m_touchPoint)

			r = true
		elseif fn == "cellTouchEnded" then
			-- A cell was touched, a1 is cell, a2 is CCTouch
			r = true
		elseif fn == "cellHighlight" then
			-- A cell is highlighting, coco2d-x 2.1.3 or above
		elseif fn == "cellUnhighlight" then
			-- A cell had been unhighlighted, coco2d-x 2.1.3 or above
		elseif fn == "cellWillRecycle" then
			-- A cell will be recycled, coco2d-x 2.1.3 or above
		end
		return r
	end )
end

function onClickedIcon(self, cellIndex, i)
	local cellData = self.tableData[cellIndex]
	if cellData['drop' .. i] == nil or cellData['drop' .. i] == '0' then
		return nil
	end

	local _id = tonumber(cellData['drop' .. i])
	if nil ~= _id then
		CGameObjElement:ShowDropByID(_id)
	end
end

function init_binding_event(self)
	if self.proxy_ ~= nil then
		-- 屏蔽掉后层触摸事件
		local function CCLayerTouch(event, x, y)
			if event == "began" then
				return true
			end
		end

		local function onBtnClose(btn, event)
			self.node_:removeFromParentAndCleanup(true)
		end

		self.btn_close_dlg:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.btn_close_dlg:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btn_close_dlg, function(button, event)
			onBtnClose(button)
			return nil
		end , CCControlEventTouchDown)

		self.node_:setTouchEnabled(true)
		self.node_:registerScriptTouchHandler(CCLayerTouch, false, kCCMenuHandlerPriority - 1, true)
	end
end

function onExchangeSuc(self)
	self:requestBaseInfo()
end

function onNodeCleanup(self)
	if self.proxy_ then
		self.proxy_:release()
	end
	layer_base_t.onNodeCleanup(self)
end
