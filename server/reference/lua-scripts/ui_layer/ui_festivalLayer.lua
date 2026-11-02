
module("ui_festivalLayer", package.seeall)
baseClass(layer_base_t, ui_festivalLayer)

require("global")
require("ui_layer/ui_festivalCellView")
require("ui_layer/ui_commonBuyItemDialog")

function init(self)
	self.contentNode_ = GetActivityView():GetNodeContent()
	self.contentSize = self.contentNode_:getContentSize()
    local ccbiAttrTable = { name = "activity/FestivalView.ccbi", size = self.contentSize }
    layer_base_t.init(self, true, ccbiAttrTable)

    self.playerMgr = CPlayerDataMgr:instance()
    self.playerData = self.playerMgr:GetPlayerInfoData()

    self.cellNodes = {}

    global.is_click_outSide = true

    self:init_ui()
    self:init_binding_event()
end

function init_ui(self)
    if self.proxy_ ~= nil then
        
        local proxy = self.proxy_
        self.node_content = getNodeFromCCB(proxy, "node_table_content")
		self.node_cell = getNodeFromCCB(proxy, "node_cell")

        self.text_title = getLabelTTFFromCCB(proxy, "text_title")
        self.text_item_first_num = getLabelBMFontFromCCB(proxy, "text_item1_num")
        self.text_item_second_num = getLabelBMFontFromCCB(proxy, "text_item2_num")
        self.text_item_first_desc = getLabelTTFFromCCB(proxy, "text_item1_desc")
        self.text_item_second_desc = getLabelTTFFromCCB(proxy, "text_item2_desc")
        
        self.sprite_item_first = getSpriteFromCCB(proxy, "sprite_item1")
        self.sprite_item_second = getSpriteFromCCB(proxy, "sprite_item2")

        self.btn_buy = getButtonFromCCB(proxy, "btn_buy")

        self.layer_touch_up = getLayerFromCCB(proxy, "layer_touch_up")
        self.layer_touch_down = getLayerFromCCB(proxy, "layer_touch_down")

        self.text_begin_time = getLabelTTFFromCCB(proxy, "text_begin_time")
        self.text_begin_time_desc = getLabelTTFFromCCB(proxy, "text_begin_time_desc")
        self.text_end_time = getLabelTTFFromCCB(proxy, "text_end_time")
        self.text_end_time_desc = getLabelTTFFromCCB(proxy, "text_end_time_desc")

        self:refreshData()
    end
end

function init_binding_event(self)
    if self.proxy_ ~= nil then

        local function CCLayerTouchUp(event, x, y)
            local rect = self.layer_touch_up:boundingBox()
            rect.origin = ccp(0, 0)
            local p = self.layer_touch_up:convertToNodeSpace(ccp(x, y))
            if event == "began" then
                if rect:containsPoint(p) == true then
                    global.is_click_outSide = false
                else
                    global.is_click_outSide = true
                end
                return global.is_click_outSide
            end
        end
        self.layer_touch_up:setTouchEnabled(true)
        self.layer_touch_up:registerScriptTouchHandler(CCLayerTouchUp, false, kCCMenuHandlerPriority - 3, false)

        local function CCLayerTouchDown(event, x, y)
            local rect = self.layer_touch_down:boundingBox()
            rect.origin = ccp(0, 0)
            local p = self.layer_touch_down:convertToNodeSpace(ccp(x, y))
            if event == "began" then
                if rect:containsPoint(p) == true then
                    if global.is_click_outSide ~= true then
                        return true
                    end
                    global.is_click_outSide = true
                else
                    return false
                end
            end
        end
        self.layer_touch_down:setTouchEnabled(true)
        self.layer_touch_down:registerScriptTouchHandler(CCLayerTouchDown, false, kCCMenuHandlerPriority - 2, false)


        self:init_btn_binding_event(self.btn_buy,
            function (button, event)
                --if global.is_click_outSide == true then
                    local data = {}
                    data.itemA = self.itemA
                    data.itemB = self.itemB
                    local time = self.buy_begin_time.month .. "." .. self.buy_begin_time.day
                    time = time .. "-"
                    time = time .. self.buy_end_time.month .. "." .. self.buy_end_time.day
                    local buyLayer = createObj(ui_commonBuyItemDialog, data, time, self)
				    GetMainMenu():GetModelLayer():AddDialog(buyLayer.node_, 3)
                --end
            end,
            localizable.ui_festival_buyDesc
        )
    end
end

function initPicTableHandle(self)
	self._tableViewHandler = LuaEventHandler:create(function(fn, table, a1, a2, x, y)
		local r
		if fn == "cellSize" then
			r = self.cell_size;
		elseif fn == "cellAtIndex" then

            local item_data = {}
            item_data.itemA = self.itemA
            item_data.itemB = self.itemB
    		local nodeLayer = createObj(ui_festivalCellView, self.exchange_list[a1 + 1], item_data, self.cell_size, self)
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
			r = #self.exchange_list
		    -- Cell events:
		elseif fn == "cellTouched" then			-- A cell was touched, a1 is cell that be touched. This is not necessary.
			local cell_index = a1:getIdx() + 1
			local _layer = self.cellNodes[cell_index]

			--if _layer.btnBuy:boundingBox():containsPoint(self.m_touchPoint) then
			--	self:GetAward(cell_index)
			--end

			self.m_touchPoint = nil
		elseif fn == "cellTouchBegan" then		-- A cell is touching, a1 is cell, a2 is CCTouch
			self.m_touchPoint = a2:getLocation()
			self.m_touchPoint = a1:convertToNodeSpace(self.m_touchPoint)

			local cell_index = a1:getIdx() + 1

		elseif fn == "cellTouchEnded" then		-- A cell was touched, a1 is cell, a2 is CCTouch
			r = true
            cclog("touch ended")
		elseif fn == "cellHighlight" then		-- A cell is highlighting, coco2d-x 2.1.3 or above
		elseif fn == "cellUnhighlight" then		-- A cell had been unhighlighted, coco2d-x 2.1.3 or above
		elseif fn == "cellWillRecycle" then		-- A cell will be recycled, coco2d-x 2.1.3 or above
		end
		return r
	end)
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

function updateUI(self, data)
    
    self.text_item_first_num:setString(data.itemA.num)
    self.text_item_second_num:setString(data.itemB.num)

end

function refreshData(self)
    
    self.text_item_first_desc:setString(localizable.ui_festival_firstItemGetFrom)
    self.text_item_second_desc:setString(localizable.ui_festival_secondItemGetFrom)
    self.text_begin_time_desc:setString(localizable.ui_festival_beginTimeDesc)
    self.text_end_time_desc:setString(localizable.ui_festival_endTimeDesc)

    ---[[
    local urlpath = GetUrlNormalHeader(self.playerData.m_uid, 9, "rl_x_small_activity")
    --cclog("urlpath = %s", urlpath)
    function refreshDataCallback(data)

        --cclog("callback data = %s", data)

        local activity = data:find("activity")
        self.activity_id = getNumber(activity, "act_id")
        self.activity_name = getString(activity, "act_name")
        self.text_title:setString(self.activity_name)
        local propA = activity:find("propA")
        local propB = activity:find("propB")
        self.itemA = {
            id = getNumber(propA, "prop_id"),
            icon = getString(propA, "prop_icon"),
            num = getNumber(propA, "prop_num"),
            quality = getNumber(propA, "prop_quality"),
        }

        self.itemB = {
            id = getNumber(propB, "prop_id"),
            icon = getString(propB, "prop_icon"),
            num = getNumber(propB, "prop_num"),
            quality = getNumber(propB, "prop_quality"),
        } 

        self.text_item_first_num:setString(tostring(self.itemA.num))
        self.text_item_second_num:setString(tostring(self.itemB.num))

        self.sprite_item_first:setDisplayFrame(CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(self.itemA.icon))
        self.sprite_item_second:setDisplayFrame(CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(self.itemB.icon))

        local time = os.date("*t", getString(propA, "begin_drop"))
        self.drop_begin_time = {
            month = time.month,
            day = time.day
        }
        time = os.date("*t", getString(propA, "end_drop"))
        self.drop_end_time = {
            month = time.month,
            day = time.day
        }
        time = os.date("*t", getString(propA, "begin_change"))
        self.exchange_begin_time = {
            month = time.month,
            day = time.day
        }
        time = os.date("*t", getString(propA, "end_change"))
        self.exchange_end_time = {
            month = time.month,
            day = time.day
        }
        time = os.date("*t", getString(propA, "begin_buy"))
        self.buy_begin_time = {
            month = time.month,
            day = time.day
        }
        time = os.date("*t", getString(propA, "end_buy"))
        self.buy_end_time = {
            month = time.month,
            day = time.day
        }
        time = os.date("*t", getString(propA, "del_time"))
        self.delete_time = {
            month = time.month,
            day = time.day
        }

        local drop_begin_time = self.drop_begin_time.month .. "." .. self.drop_begin_time.day
        local drop_end_time = self.drop_end_time.month .. "." .. self.drop_end_time.day
        local activity_end_time = self.exchange_end_time.month .. "." .. self.exchange_end_time.day

        self.text_begin_time:setString(drop_begin_time .. "-" .. drop_end_time)
        self.text_end_time:setString(activity_end_time)

        local exchangeList = data:find("exchange_list")
        self.exchange_list = {}
        function upadateItemQuality(item)
            if item.id == self.itemA.id then
                item.quality = self.itemA.quality
            elseif item.id == self.itemB.id then
                item.quality = self.itemB.quality
            else
                item.quality = 1
            end
        end
        for i = 1, #exchangeList do
            local exchange = exchangeList[i]:find("exchange")
            local need = exchange:find("need")
            local changed = exchange:find("changed")

            local temp = {
                remain_times = exchange.remain_times,
                total_times = exchange.total_times,
                exchange_id = exchange.exchange_id,
                itemA = {
                    id = getNumber(need, "a_id"),
                    num = getNumber(need, "a_num"),
                },
                itemB = {
                    id = getNumber(need, "b_id"),
                    num = getNumber(need, "b_num"),
                },
                itemC = {
                    id = getNumber(changed, "a_id"),
                    num = getNumber(changed, "a_num"),
                    itemId = getNumber(changed, "a_goods"),
                    mainType = getNumber(changed, "a_type"),
                },
                itemD = {
                    id = getNumber(changed, "b_id"),
                    num = getNumber(changed, "b_num"),
                    itemId = getNumber(changed, "b_goods"),
                    mainType = getNumber(changed, "b_type"),
                },
                isSingleExchange = false
            }
            upadateItemQuality(temp.itemA)
            upadateItemQuality(temp.itemB)

            temp.isSingleExchange = not (temp.itemA.id ~= 0 and temp.itemB.id ~= 0)
            self.exchange_list[#self.exchange_list + 1] = temp
        end

        self:creatTabelView()
    end

    sendRequest(urlpath, refreshDataCallback)
    --]]
end

---------------------common------------------------

function onNodeCleanup(self)
    if self.proxy_ then
        self.proxy_:release()
    end
    layer_base_t.onNodeCleanup(self)
end

function getNumber(data, name)
    return tonumber(data:find(name)[1])
end

function getString(data, name)
    return tostring(data:find(name)[1])
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