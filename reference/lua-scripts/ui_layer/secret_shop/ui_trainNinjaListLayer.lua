--descriptioin:煉化忍者列表界面
--company: xckoo
--author: chenchun
--date: 2014-03-12
---------------------------------------------
module("ui_trainNinjaListLayer", package.seeall)
baseClass(layer_base_t, ui_trainNinjaListLayer)

PreSelectedIndex = 0   --前一个选择的索引
Instance = nil

selectedList = {} --选入列表

function init(self)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	self.contentSize_ = GetMainMenu():GetSubContentNode():getContentSize()
	local ccbiAttrTable = {name="secretshop/trainNinjaList.ccbi", size=self.contentSize_}
	layer_base_t.init(self, true, ccbiAttrTable)

	ui_trainNinjaListLayer.PreSelectedIndex = ui_trainSoulLayer.CurIndex or 0
	
	self:init_ui()
	self:init_binding_event()

	ui_trainNinjaListLayer.Instance = self
end

function init_ui(self)
	if self.proxy_ ~= nil then
		self.btn_back = tolua.cast(self.proxy_:getNode("btn_back"), "CCControlButton")
		self.node_table_content = tolua.cast(self.proxy_:getNode("node_table_content"), "CCNode")
		self.label_select_num = tolua.cast(self.proxy_:getNode("label_select_num"), "CCLabelBMFont")
		self.ctrl_btn_select = tolua.cast(self.proxy_:getNode("ctrl_btn_select"), "CCControlButton")
		self.node_card_cell = tolua.cast(self.proxy_:getNode("node_card_cell"), "CCNode")

		self:update_ui()
		self:initTableView()	
	end
end


function init_binding_event(self)
	if self.proxy_ ~= nil then
		local function btn_back()
			ui_trainSoulLayer.Instance:update_btn_addorchange()
			self.node_:removeFromParentAndCleanup(true)
		end

		self.btn_back:setTouchPriority(-5)
		self.proxy_:handleControlEvent(self.btn_back, btn_back, CCControlEventTouchUpInside)
		self.ctrl_btn_select:setTouchPriority(-6)
		self.proxy_:handleControlEvent(self.ctrl_btn_select, btn_back, CCControlEventTouchUpInside)

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
		self.node_:registerScriptTouchHandler(CCLayerTouch, false, -4, true)
	end
end

function initTableView(self)
	-- body
	if self.tableview == nil then
		self.cellsize = self.node_card_cell:getContentSize()
		self.tableContentSize = self.node_table_content:getContentSize()
		self:initHandle()
		self.tableview = LuaTableView:createWithHandler(self.tableViewHandler, CCSizeMake(self.tableContentSize.width, self.tableContentSize.height))

		self.tableview:setDirection(kCCScrollViewDirectionVertical)
		self.tableview:setVerticalFillOrder(kCCTableViewFillTopDown)
		self.tableview:setTouchPriority(-6)
		self.node_table_content:addChild(self.tableview)
		
		--[[
		local offset = self.tableview:getContentOffset()
		if ui_trainNinjaListLayer.LastSelectedIndex >= 1 and ui_trainNinjaListLayer.LastSelectedIndex <= #ui_trainSoulLayer.TrainNinjaList then
			local yHeight = self.cellsize.height * (ui_trainNinjaListLayer.LastSelectedIndex - 1)
			self.tableview:setContentOffset(offset.x, offset.y + yHeight)
		else
			ui_trainNinjaListLayer.LastSelectedIndex = 0
			self.tableview:setContentOffset(offset.x, offset.y)
		end
		]]

		--self.tableview:reloadData()
		--self.tableview:setDragEnabled(true)
	end
end


function initHandle(self)
	self.newNinjaList = ui_trainSoulLayer.TrainNinjaList
	local tipsData = {tipsdesc=localizable.ui_train_ninjalist_tips, istips=true}
	table.insert(self.newNinjaList, tipsData)
	self.tableViewHandler = LuaEventHandler:create(function(fn, table, a1, a2, x, y)
		local r
		if fn == "cellSize" then
			r = self.cellsize
		elseif fn == "cellAtIndex" then
    		local nodeLayer = createObj(ui_trainNinjaItem, self.newNinjaList[a1 + 1], self.cellsize, a1 + 1)
			if not a2 then
				a2 = CCTableViewCell:create()
				a2:addChild(nodeLayer.node_)
			else
				a2:removeAllChildrenWithCleanup(true)
        		a2:addChild(nodeLayer.node_)
			end
			r = a2
		elseif fn == "numberOfCells" then
			r = #self.newNinjaList
		-- Cell events:
		elseif fn == "cellTouched" then			-- A cell was touched, a1 is cell that be touched. This is not necessary.

		elseif fn == "cellTouchBegan" then		-- A cell is touching, a1 is cell, a2 is CCTouch
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

function updateCellAtIndex(self, index)
	self.tableview:updateCellAtIndex(index)
end

function update_ui(self)
	self.label_select_num:setString(tostring(#selectedList))
end

function onNodeCleanup(self)
	--cclog("1111---001")
	if self.proxy_ then
    	self.proxy_:release()
    end
    if self.newNinjaList ~= nil then
    	table.remove(self.newNinjaList)
    end
    ui_trainNinjaListLayer.Instance = nil
    ui_trainNinjaListLayer.PreSelectedIndex = 0
    layer_base_t.onNodeCleanup(self)
end