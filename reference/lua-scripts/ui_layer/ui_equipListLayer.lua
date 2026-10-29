----------------------------------------------------------------------
--  Copyright (c) 2014-2016, XCKOO. All Rights Reserved.
--  Author :Tango
--  Time   :2015/3/5 17:17:20
--  Remark :装备列表
----------------------------------------------------------------------
module("ui_equipListLayer", package.seeall)
baseClass(layer_base_t, ui_equipListLayer)

require("ui_layer/ui_equipListItem")


selectedList = { } -- 选入列表

--
EquipType = { e_obj_weapon, e_obj_armors }

function init(self, parent, exclude,mode)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	self.contentSize_ = GetMainMenu():GetSubContentNode():getContentSize()
	local ccbiAttrTable = { name = "sub_ui/EquipList.ccbi", size = self.contentSize_ }
	layer_base_t.init(self, true, ccbiAttrTable)

	self.parent = parent
	self.tab = 0
	self.btntab = { }
	self.itemlist = { }
	self.exclude = exclude
    self.mode = mode

	self:init_ui()
	self:init_binding_event()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		self.btn_back = tolua.cast(self.proxy_:getNode("btn_back"), "CCControlButton")
		self.node_table_content = tolua.cast(self.proxy_:getNode("node_table_content"), "CCNode")
		self.node_card_cell = tolua.cast(self.proxy_:getNode("node_card_cell"), "CCNode")

		-- tabs
		self.btntab[1] = tolua.cast(self.proxy_:getNode("ctrl_weapon"), "CCControlButton")
		self.btntab[2] = tolua.cast(self.proxy_:getNode("ctrl_armors"), "CCControlButton")

		self:setCurTab(1)
	end
end

function setCurTab(self, tab)
	self.tab = tab
	for i = 1, 2 do
		self.btntab[i]:setEnabled(i ~= tab)
	end

	self:refreshList()
end

function refreshList(self)
	self.itemlist = { }

	local objlist = CPlayerDataMgr:instance():GetObjectList(EquipType[self.tab])
	local count = objlist:size() -1
	for i = 0, count do
		local quality = objlist[i]:GetQuality()
		local grade = objlist[i]:GetReincarnationLevel()
        if self.mode == 1 then
		    if  quality == 5  and objlist[i]:GetLevel() == 50 and grade < 3 and self.exclude ~= objlist[i]:GetGUID() then
			    table.insert(self.itemlist, objlist[i])
		    end
        else
            if objlist[i]:IsUsingInAnyTeam() == false and quality == 5  and objlist[i]:GetLevel() == 50 and grade < 3 and self.exclude ~= objlist[i]:GetGUID() then
			    table.insert(self.itemlist, objlist[i])
		    end
        end
	end

	self:initTableView()
end

function init_binding_event(self)
	if self.proxy_ ~= nil then
		local function CCLayerTouch(event, x, y)
			local rect = self.node_:boundingBox()
			rect.origin = ccp(0, 0)
			local p = self.node_:convertToNodeSpace(ccp(x, y))
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

		local function btn_back()
			--ui_trainSoulLayer.Instance:update_btn_addorchange()
			self.node_:removeFromParentAndCleanup(true)
		end

		self.btn_back:setTouchPriority(-5)
		self.proxy_:handleControlEvent(self.btn_back, btn_back, CCControlEventTouchUpInside)

		for i = 1, 2 do
			self.btntab[i]:setTouchPriority(-5)
			self.proxy_:handleControlEvent(self.btntab[i], function()
				self:setCurTab(i)
			end , CCControlEventTouchUpInside)
		end

	end
end

function initTableView(self)
	self.tableData = self.itemlist
	local tipsData = { tipsdesc = localizable.ui_train_ninjalist_tips, istips = true }
	table.insert(self.tableData, tipsData)

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
	else
		self.tableview:reloadData()
	end
end


function initHandle(self)
	self.tableViewHandler = LuaEventHandler:create( function(fn, table, a1, a2, x, y)
		local r
		if fn == "cellSize" then
			r = self.cellsize
		elseif fn == "cellAtIndex" then
			local nodeLayer = createObj(ui_equipListItem, self.tableData[a1 + 1], self.cellsize, a1 + 1,self)
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

		elseif fn == "cellTouchBegan" then
			-- A cell is touching, a1 is cell, a2 is CCTouch
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


function onSelected(self, index)
	self.parent:onSelected(self.itemlist[index])
	self.node_:removeFromParentAndCleanup(true)
end

function updateCellAtIndex(self, index)
	self.tableview:updateCellAtIndex(index)
end

function update_ui(self)
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