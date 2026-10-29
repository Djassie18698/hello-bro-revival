--descriptioin:突破忍者列表界面
--company: xckoo
--author: zhangwy
--date: 20151208
---------------------------------------------
module("ui_tupoNinjaListLayer", package.seeall)
baseClass(layer_base_t, ui_tupoNinjaListLayer)

Instance = nil
tuposelectedList = {}
selectedCardId = 0
tupocardList = {}

function init(self)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	self.contentSize_ = GetMainMenu():GetSubContentNode():getContentSize()
	local ccbiAttrTable = {name="secretshop/trainNinjaList.ccbi", size=self.contentSize_}
	layer_base_t.init(self, true, ccbiAttrTable)
	
	self:getTupoNinjaList(e_obj_ninja)

	self:init_ui()
	self:init_binding_event()

	ui_tupoNinjaListLayer.Instance = self
	ui_tupoNinjaListLayer.selectedCardId = ui_tupoLayer.SelectedCard
end

function init_ui(self)
	if self.proxy_ ~= nil then
		self.btn_back = tolua.cast(self.proxy_:getNode("btn_back"), "CCControlButton")
		self.node_table_content = tolua.cast(self.proxy_:getNode("node_table_content"), "CCNode")
		self.label_select_num = tolua.cast(self.proxy_:getNode("label_select_num"), "CCLabelBMFont")
		self.ctrl_btn_select = tolua.cast(self.proxy_:getNode("ctrl_btn_select"), "CCControlButton")
		self.node_card_cell = tolua.cast(self.proxy_:getNode("node_card_cell"), "CCNode")

		self.node_select_info = tolua.cast(self.proxy_:getNode("node_select_info"), "CCNode")
		--self:update_ui()
		self.label_select_num:setVisible(false)

		self.ctrl_btn_select:setVisible(false)
		--self.ctrl_btn_select:setEnable(false)
		self.node_select_info:setVisible(false)

		self:initTableView()	
	end
end


function init_binding_event(self)
	if self.proxy_ ~= nil then
		local function btn_back()
			ui_tupoLayer.Instance:updateTupoNinja(ui_tupoNinjaListLayer.selectedCardId)
			self.node_:removeFromParentAndCleanup(true)
		end

		self.btn_back:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.proxy_:handleControlEvent(self.btn_back, btn_back, CCControlEventTouchUpInside)
		self.ctrl_btn_select:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.proxy_:handleControlEvent(self.ctrl_btn_select, btn_back, CCControlEventTouchUpInside)

		local function CCLayerTouch(event, x, y)
			local rect = self.node_:boundingBox()
			--cclog("20151208 --- touch")
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
		self.tableview:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.node_table_content:addChild(self.tableview)
	end
end

function getTupoNinjaList( self, cardtype )
	-- body
	ui_tupoNinjaListLayer.tupocardList = { }
	local objlist = CPlayerDataMgr:instance():GetObjectList(cardtype)
	local count = objlist:size() -1
	for i = 0, count do
		local quality = objlist[i]:GetQuality()
		--objlist[i]:IsUsingInAnyTeam() == false and
		if quality == 6 then
			table.insert(ui_tupoNinjaListLayer.tupocardList, objlist[i])
		end
	end
end

function initHandle(self)
	self.newNinjaList = ui_tupoNinjaListLayer.tupocardList
	local tipsData = {tipsdesc=localizable.ui_train_ninjalist_tips, istips=true}
	table.insert(self.newNinjaList, tipsData)
	self.tableViewHandler = LuaEventHandler:create(function(fn, table, a1, a2, x, y)
		local r
		if fn == "cellSize" then
			r = self.cellsize
		elseif fn == "cellAtIndex" then
    		local nodeLayer = createObj(ui_tupoNinjaItem, self.newNinjaList[a1 + 1], self.cellsize, a1 + 1)
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
	--self.label_select_num:setString(tostring(#selectedList))
	self.label_select_num:setVisible(false)
	
	ui_tupoLayer.Instance:updateTupoNinja(ui_tupoNinjaListLayer.selectedCardId)
	self.node_:removeFromParentAndCleanup(true)
end

function onNodeCleanup(self)
	--cclog("1111---001")
	if self.proxy_ then
    	self.proxy_:release()
    end
    if self.newNinjaList ~= nil then
    	table.remove(self.newNinjaList)
    end
    ui_tupoNinjaListLayer.Instance = nil
    ui_tupoNinjaListLayer.selectedCardId = 0
    layer_base_t.onNodeCleanup(self)
end