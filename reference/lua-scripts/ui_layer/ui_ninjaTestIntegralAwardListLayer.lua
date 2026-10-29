
module("ui_ninjaTestIntegralAwardListLayer", package.seeall)
baseClass(layer_base_t, ui_ninjaTestIntegralAwardListLayer)

require("ui_layer/ui_ninjaTestIntegralAwardListCell")

function init(self, score, datas, preLayer)

	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

    self.contentSize_ = GetMainMenu():GetSubContentNode():getContentSize()
	local ccbiAttrTable = { name = "sub_ui/NinjaTestIntegralAwardListView.ccbi", size = self.contentSize_ }
	layer_base_t.init(self, true, ccbiAttrTable)

    initHeader(self.proxy_)

    self.integral_num = score

    --测试
    --score 积分, cash - gold 元宝, coin - silver 银子
    --[[
    datas = {}
    datas[1] = {reward_id = 1, drop_id = "1261", score = 100, gold = 20, silver = 0}
    datas[2] = {reward_id = 2, drop_id = "1285", score = 200, gold = 20, silver = 0}
    datas[3] = {reward_id = 3, drop_id = "1306", score = 200, gold = 20, silver = 0}
    datas[4] = {reward_id = 4, drop_id = "1385", score = 200, gold = 20, silver = 0}
    datas[5] = {reward_id = 5, drop_id = "1463", score = 200, gold = 20, silver = 0}
    datas[6] = {reward_id = 6, drop_id = "1781", score = 200, gold = 20, silver = 0}
    datas[7] = {reward_id = 7, drop_id = "1784", score = 200, gold = 20, silver = 0}
    datas[8] = {reward_id = 8, drop_id = "96", score = 200, gold = 20, silver = 0}
    ]]

    self.datas = datas

	self.preLayer = preLayer
	self.cellNodes = {}

	self:init_ui()
	self:init_binding_event()
end

function init_ui(self)
	if self.proxy_ ~= nil then
        local proxy = self.proxy_
        self.node_content = getNodeFromCCB(proxy, "node_content")
		self.node_cell = getNodeFromCCB(proxy, "node_cell_content")
        self.btn_back = getButtonFromCCB(proxy, "btn_back")
        self.text_award_title = getLabelTTFFromCCB(proxy, "text_award_title")
        self.text_integral_num = getLabelBMFontFromCCB(proxy, "text_integral_num")
		self:refreshData(self.integral_num)
	end
end

function refreshData(self, integral)

    self:createTableView()
    if integral == nil then
        integral = 0
    end
    self.integral_num = integral
    self.text_integral_num:setString(self.integral_num)
    self.text_award_title:setString(localizable.ui_ninjaTest_award_title)
    initHeader(self.proxy_)
end

function init_binding_event(self)

    local function CCLayerTouch(event,x,y)
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
    self.node_:registerScriptTouchHandler(CCLayerTouch, false, kCCMenuHandlerPriority - 1, true)

    self:init_btn_binding_event(self.btn_back, 
        function(button, event)
            -- 刷新前一界面
            self.preLayer:updata_score(self.integral_num)
            self.node_:removeFromParentAndCleanup(true)
        end,
        localizable.ui_label_back_text
    )
end

function createTableView(self)
	-- body
	if self._tableView == nil then
		local cellContentSize = self.node_cell:getContentSize()
		self.cell_size = CCSizeMake(cellContentSize.width, cellContentSize.height)

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
	self._tableViewHandler = LuaEventHandler:create( function(fn, table, a1, a2, x, y)
		local r
		if fn == "cellSize" then
			r = self.cell_size;
		elseif fn == "cellAtIndex" then
			local nodeLayer = createObj(ui_ninjaTestIntegralAwardListCell, self.datas[a1 + 1], self.cell_size, self)
			-- tableView cell container
			self.cellNodes[a1 + 1] = nodeLayer
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
			--r = #self.pets;
            r = #self.datas
			-- Cell events:
		elseif fn == "cellTouched" then
			-- A cell was touched, a1 is cell that be touched. This is not necessary.
			--- [[
			local cell_index = a1:getIdx() + 1
			local _layer = self.cellNodes[cell_index]

--			if _layer.btnGet:boundingBox():containsPoint(self.m_touchPoint) then
--				self:onClickedGet(cell_index)
--			end

			self.m_touchPoint = nil
			-- ]]
		elseif fn == "cellTouchBegan" then
			-- A cell is touching, a1 is cell, a2 is CCTouch
			self.m_touchPoint = a2:getLocation()
			self.m_touchPoint = a1:convertToNodeSpace(self.m_touchPoint)

			local cell_index = a1:getIdx() + 1

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

function onNodeCleanup(self)
	-- cclog("1111---001")
	if self.proxy_ then
		self.proxy_:release()
	end
	if self.tableData ~= nil then
		table.remove(self.tableData)
	end
	layer_base_t.onNodeCleanup(self)
end

function getNumber(data, name)
    return tonumber(data:find(name)[1])
end

function init_btn_binding_event(self, btn_node, callback, btn_title_text)
    btn_node:setTouchEnabled(true)
    btn_node:setTouchPriority(kCCMenuHandlerPriority - 1)
    self.proxy_:handleButtonEvent(btn_node, callback , CCControlEventTouchUpInside)
    if btn_title_text ~= nil then
        --btn_node:setTitleForState(btn_title_text, CCControlStateNormal)
        --btn_node:setTitleForState(btn_title_text, CCControlStateHighlighted)
        --btn_node:setTitleForState(btn_title_text, CCControlStateDisabled)    
    end
end