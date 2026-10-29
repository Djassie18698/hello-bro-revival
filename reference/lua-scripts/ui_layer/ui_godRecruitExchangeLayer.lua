----------------------------------------------------------------------
--  Copyright (c) 2014-2016, XCKOO. All Rights Reserved.
--  Author :Tango
--  Time   :2015/7/2 16:37:32
--  Remark :老虎机奖励兑换
----------------------------------------------------------------------
require("ui_layer/ui_godRecruitExchangeCell")

module("ui_godRecruitExchangeLayer", package.seeall)
baseClass(layer_base_t, ui_godRecruitExchangeLayer)

function init(self, parent, data)
	self.contentSize_ = GetMainMenu():GetModelLayer():getContentSize()

	local ccbiAttrTable = { name = "activity/GodRecruitExchangeView.ccbi", size = self.contentSize_ }
	layer_base_t.init(self, true, ccbiAttrTable)

	-- 用户info
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	self.parent = parent
	-- tableView cell container
	self.cellNodes = { }
	self.tableData = self:splitNinjas(data)
	self.m_touchPoint = nil

	-- init
	self:init_ui()
	self:init_binding_event()

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

		getLabelTTFFromCCB(self.proxy_, 'label_title'):setString(localizable.ui_godRecruit_exchangeTitle)
		getLabelTTFFromCCB(self.proxy_, 'label_unuse1'):setString(localizable.ui_godRecruit_curScore)

		self.labelScore:setString(self.parent.score)

		self:createTableView()
	end
end

function splitNinjas( self, ninjas )
	local ret = {}
	local item3 = {}
	local count = 0
	for i = 1, #ninjas do
		table.insert(item3,ninjas[i])
		if #ninjas - count*3 >= 3 then --剩下的 >= 3个
			if 3 == #item3 then
				table.insert(ret, item3)
				item3 = {}
				count = count+1
			end
		end
	end

	-- 剩下不足3个的
	if #item3 > 0 then
		table.insert(ret, item3)
	end
	
	return ret
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

	local _id_icon = tonumber(self.tableData[line][i].drop_id)
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
			local nodeLayer = createObj(ui_godRecruitExchangeCell, self._cell_size, self.tableData[a1 + 1], self)
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

			for i = 1, 3 do
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
	if cellData[i].drop_id == nil or cellData[i].drop_id == '0' then
		return nil
	end

	local _id = tonumber(cellData[i].drop_id)
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

function onExchangeSuc(self, curScore)
	self.labelScore:setString(curScore)
	self.parent:setScore(curScore)
end

function onNodeCleanup(self)
	if self.proxy_ then
		self.proxy_:release()
	end
	layer_base_t.onNodeCleanup(self)
end
