require "LuaSubView.lua"
require "RLRequest"
require "LuaXml.lua"
require "boxOpenRewardCellView.lua"
require "util/text"

boxOpenActivityDetailDialog=class(
		"boxOpenActivityDetailDialog",
    function()
        return CCLayer:create() 
    end
)

boxOpenActivityDetailDialog.m_touchPriority = kCCMenuHandlerPriority-1;

function boxOpenActivityDetailDialog_onTouch(event, x, y)
     if event == "began" then   
        return true
    end
end

function boxOpenActivityDetailDialog:create()
	local view = boxOpenActivityDetailDialog.new();
	return view;
end

function boxOpenActivityDetailDialog:loadCCBI()
	local view = LuaSubView:create();	
	local win = CCDirector:sharedDirector():getWinSize();
	view:LoadCCBI("activity/ActivityBoxDetailView.ccbi",CCSize(768,win.height));
	self:addChild(view)
	view:setPosition(CCPoint(win.width / 2, win.height / 2));
	self.m_dlgview = view;
end

function boxOpenActivityDetailDialog:initTable()	
	if self.m_tableview ~= nil then
		self.m_tableview:removeFromParentAndCleanup(true)
		self.m_tableview = nil
	end
	
	self:initHandle();
	self.m_contentview = self.m_dlgview:getNode("node_tablecontent");
	local contentsize = self.m_contentview:getContentSize();
	self.m_cellsize = self.m_dlgview:getNode("node_cellcontent"):getContentSize();
	
	local tableview = LuaTableView:createWithHandler(self.m_handler, CCSizeMake(contentsize.width,contentsize.height))
	self.m_tableview = tableview
	tableview:setDirection(kCCScrollViewDirectionVertical);
	tableview:setVerticalFillOrder(kCCTableViewFillTopDown);
	tableview:reloadData()
	self.m_contentview:addChild(tableview);
	tableview:setTouchPriority(boxOpenActivityDetailDialog.m_touchPriority);
end

function boxOpenActivityDetailDialog:initUI()		
	self:loadCCBI()
	
	self:setTabClicked(self.m_tab)
	
	self:BindControl()
	self:updateUI()
end

function boxOpenActivityDetailDialog:setTabClicked(chest)
	if chest == 1 then
		tolua.cast(self.m_dlgview:getNode("btn_gold_box"), "CCControlButton"):setEnabled(false)
		tolua.cast(self.m_dlgview:getNode("btn_silver_box"), "CCControlButton"):setEnabled(true)
		tolua.cast(self.m_dlgview:getNode("btn_copper_box"), "CCControlButton"):setEnabled(true)
		self.m_tab = 1
	elseif chest == 2 then
		tolua.cast(self.m_dlgview:getNode("btn_gold_box"), "CCControlButton"):setEnabled(true)
		tolua.cast(self.m_dlgview:getNode("btn_silver_box"), "CCControlButton"):setEnabled(false)
		tolua.cast(self.m_dlgview:getNode("btn_copper_box"), "CCControlButton"):setEnabled(true)
		self.m_tab = 2
	elseif chest == 3 then
		tolua.cast(self.m_dlgview:getNode("btn_gold_box"), "CCControlButton"):setEnabled(true)
		tolua.cast(self.m_dlgview:getNode("btn_silver_box"), "CCControlButton"):setEnabled(true)
		tolua.cast(self.m_dlgview:getNode("btn_copper_box"), "CCControlButton"):setEnabled(false)
		self.m_tab = 3
	end
end

function boxOpenActivityDetailDialog:updateUI()
	self:initTable()
end

function boxOpenActivityDetailDialog:initHandle()
	self.m_handler = LuaEventHandler:create(function(fn, table, a1, a2, x, y)
		local r
		if fn == "cellSize" then
			-- Return cell size
			-- a1 is cell index (-1 means default size, in cocos2d-x version below 2.1.3, it's always -1)
			r = self.m_cellsize;
		elseif fn == "cellAtIndex" then
			-- Return CCTableViewCell, a1 is cell index (zero based), a2 is dequeued cell (maybe nil)
			-- Do something to create cell and change the content
			local cell = boxOpenRewardCellView:create();
			cell:setIndex(a1);
			self:setCellData(cell,a1+1)
			cell:setCellSize(self.m_cellsize);
			cell:loadCCBI();
			cell:initUI();
			if not a2 then
				a2 = CCTableViewCell:create()
			else			
				a2:removeAllChildrenWithCleanup(true)
			end
			
			a2:addChild(cell);
			cell:setTag(100);
			r = a2
		elseif fn == "numberOfCells" then
			r = self:getCellNumber()
		-- Cell events:
		elseif fn == "cellTouched" then			-- A cell was touched, a1 is cell that be touched. This is not necessary.	
		elseif fn == "cellTouchBegan" then		-- A cell is touching, a1 is cell, a2 is CCTouch
			r = true
		elseif fn == "cellTouchEnded" then		-- A cell was touched, a1 is cell, a2 is CCTouch
			r = true
		elseif fn == "cellHighlight" then		-- A cell is highlighting, coco2d-x 2.1.3 or above
		elseif fn == "cellUnhighlight" then		-- A cell had been unhighlighted, coco2d-x 2.1.3 or above
			r = true;
		elseif fn == "cellWillRecycle" then		-- A cell will be recycled, coco2d-x 2.1.3 or above
		end
		return r
	end)
end

function boxOpenActivityDetailDialog:setInfoData(goldList, silverList, copperList)
	self.m_goldChestList = goldList
	self.m_silverChestList = silverList
	self.m_copperChestList = copperList
	return nil
end

function boxOpenActivityDetailDialog:setTab(tab)
	self.m_tab = tab
end

function boxOpenActivityDetailDialog:setCellData(cell,index)
	if self.m_tab == 1 then
		cell:setCellData(self.m_goldChestList[index])
	elseif self.m_tab == 2 then
		cell:setCellData(self.m_silverChestList[index])
	elseif self.m_tab == 3 then
		cell:setCellData(self.m_copperChestList[index])
	else
		cell:setCellData(self.m_goldChestList[index])
	end
				
	return nil
end

function boxOpenActivityDetailDialog:getCellNumber()
	if self.m_tab == 1 then
		return #self.m_goldChestList
	elseif self.m_tab == 2 then
		return #self.m_silverChestList
	elseif self.m_tab == 3 then
		return #self.m_copperChestList
	else
		return #self.m_goldChestList
	end
end

function boxOpenActivityDetailDialog:BindControl()
	boxOpenActivityDetailDialog.m_selfview:setTouchEnabled(true)
	boxOpenActivityDetailDialog.m_selfview:registerScriptTouchHandler(boxOpenActivityDetailDialog_onTouch,false,kCCMenuHandlerPriority-1,true)
	boxOpenActivityDetailDialog.m_selfview:setTouchMode(0) 
	
	self.m_btn_gold = tolua.cast(self.m_dlgview:getNode("btn_gold_box"), "CCControlButton")
	self.m_btn_silver = tolua.cast(self.m_dlgview:getNode("btn_silver_box"), "CCControlButton")
	self.m_btn_copper = tolua.cast(self.m_dlgview:getNode("btn_copper_box"), "CCControlButton")
	self.m_btn_close = tolua.cast(self.m_dlgview:getNode("btnDialogClose"), "CCControlButton")
	
	-- 初始化按钮
	self.m_btn_gold:setTouchPriority(boxOpenActivityDetailDialog.m_touchPriority);
	self.m_dlgview:handleButtonEvent(self.m_btn_gold, function(button, event)
		self:clickGoldChest();
		return nil
	end, CCControlEventTouchUpInside)
	
	self.m_btn_silver:setTouchPriority(boxOpenActivityDetailDialog.m_touchPriority);
	self.m_dlgview:handleButtonEvent(self.m_btn_silver, function(button, event)
		self:clickSilverChest();
		return nil
	end, CCControlEventTouchUpInside)
	
	self.m_btn_copper:setTouchPriority(boxOpenActivityDetailDialog.m_touchPriority);
	self.m_dlgview:handleButtonEvent(self.m_btn_copper, function(button, event)
		self:clickCopperChest();
		return nil
	end, CCControlEventTouchUpInside)
	
	self.m_btn_close:setTouchPriority(boxOpenActivityDetailDialog.m_touchPriority);
	self.m_dlgview:handleButtonEvent(self.m_btn_close, function(button, event)
		self:CloseView();
		return nil
	end, CCControlEventTouchUpInside)
end

function boxOpenActivityDetailDialog:CloseView()    
    boxOpenActivityDetailDialog.m_selfview:removeFromParentAndCleanup(true);
end

function boxOpenActivityDetailDialog:clickGoldChest()
	if self.m_tab == 1 then
		return nil
	end

	self:setTabClicked(1)
	self:initTable()
end

function boxOpenActivityDetailDialog:clickSilverChest()
	if self.m_tab == 2 then
		return nil
	end

	self:setTabClicked(2)
	self:initTable()
end

function boxOpenActivityDetailDialog:clickCopperChest()
	if self.m_tab == 3 then
		return nil
	end

	self:setTabClicked(3)
	self:initTable()
end




