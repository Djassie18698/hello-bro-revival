----------------------------------------------------------------------
--  Copyright (c) 2014-2016, XCKOO. All Rights Reserved.
--  Author :Tango
--  Time   :2015/1/19 17:40:21
--  Remark :领奖中心子页面
----------------------------------------------------------------------
module("ui_awardCenterCell", package.seeall)
baseClass(layer_base_t, ui_awardCenterCell)

require("ui_layer/ui_awardCenterCellCell")

function init(self, cellSize, data, parent)
	local ccbiAttrTable = {name="activity/AwardCenterCell.ccbi", size=cellSize}
	layer_base_t.init(self, true, ccbiAttrTable)

	--用户info
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()
	--
	self.data = data
	--
	self.tableData = {}

	--tableView cell container
	self.cellNodes = {}

	self.parent = parent
	--touch
	self.m_touchPoint = nil

	--create data
	--self:createData()

	--init
	self:init_ui()		
	self:init_binding_event()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		--label
		self.label_title = tolua.cast(self.proxy_:getNode("label_item_title"), "CCLabelTTF")
		self.labelAwardTime = tolua.cast(self.proxy_:getNode("label_award_time"),"CCLabelTTF")
		self.labelDesc = tolua.cast(self.proxy_:getNode("label_desc"),"CCLabelTTF")

		--node
		self.node_content = tolua.cast(self.proxy_:getNode("node_content"), "CCNode")
		self.node_cell = tolua.cast(self.proxy_:getNode("node_cell"), "CCNode")

		--btn
		self.btnGet = tolua.cast(self.proxy_:getNode("btn_get"),"CCControlButton")

		--get info
		self:init_ext_ui()
	end
end

function init_ext_ui(self)	
	if nil == self.data then
		return nil
	end
	self.id = tonumber(self.data:find("id")[1])
	local awardTime = tonumber(self.data:find("ts")[1])
	local timestr = os.date(localizable.ui_awardCenter_date, awardTime)
	self.labelAwardTime:setString(timestr)

	self.label_title:setString(self.data:find("title")[1])
	self.labelDesc:setString(self.data:find("content")[1])

	local awards = self.data:find("awards")
	if #awards > 0 then
		self.tableData = awards
		self:createTableView()
	end

	getLabelTTFFromCCB(self.proxy_, 'label_unuse1'):setString(localizable.ui_awardCenter_text2)

end

function createTableView(self)
	if self._tableView == nil then
		local cellContentSize = self.node_cell:getContentSize()
		self._cell_size = CCSizeMake(cellContentSize.width,cellContentSize.height)

		self._content_size = self.node_content:getContentSize()
		self:initTableHandle()
		self._tableView = LuaTableView:createWithHandler(self._tableViewHandler, CCSizeMake(self._content_size.width, self._content_size.height))
		self._tableView:setDirection(kCCScrollViewDirectionHorizontal)
		self._tableView:setVerticalFillOrder(kCCTableViewFillTopDown)
		self._tableView:setTouchPriority(kCCMenuHandlerPriority - 1)

		self.node_content:addChild(self._tableView)
	else
		self._tableView:reloadData()
	end
end

function initTableHandle(self)
	self._tableViewHandler = LuaEventHandler:create(function(fn, table, a1, a2, x, y)
		local r
		if fn == "cellSize" then
			r = self._cell_size;
		elseif fn == "cellAtIndex" then
    		local nodeLayer = createObj(ui_awardCenterCellCell, self._cell_size, self.tableData[a1 + 1])
			--tableView cell container
			self.cellNodes[a1+1] = nodeLayer
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
		elseif fn == "cellTouched" then			-- A cell was touched, a1 is cell that be touched. This is not necessary.
			---[[
			local cell_index = a1:getIdx() + 1		
			--]]
		elseif fn == "cellTouchBegan" then		-- A cell is touching, a1 is cell, a2 is CCTouch
			self.m_touchPoint = a2:getLocation()
			self.m_touchPoint = a1:convertToNodeSpace(self.m_touchPoint)

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



function init_binding_event(self)
	if self.proxy_ ~= nil then
		self.btnGet:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.proxy_:handleButtonEvent(self.btnGet, function(button, event)
			if self.parent then
				self.parent:requestGetAward(self.id)
			end
			return nil
		end, CCControlEventTouchUpInside)
	end
end

function onNodeCleanup(self)
	---[[
	if self.proxy_ then
    	self.proxy_:release()
    	self.proxy_ = nil
    end
	--]]
    layer_base_t.onNodeCleanup(self)
end

--创建测试数据
function createData(self)
	---[[
	--]]
end