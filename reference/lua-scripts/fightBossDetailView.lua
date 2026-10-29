require "LuaSubView.lua"
require "RLRequest"
require "LuaXml.lua"
require "fightBossRankCellView.lua"
require "util/localizable"

fightBossDetailView=class(
		"fightBossDetailView",
    function()
        return CCLayer:create() 
    end
)

fightBossDetailView.m_touchPriority = kCCMenuHandlerPriority-1;

function fightBossDetailView_onTouch(event, x, y)
     if event == "began" then   
        return true
    end
end

function fightBossDetailView:create()
	local view = fightBossDetailView.new();
	return view;
end

function fightBossDetailView:loadCCBI()
	local view = LuaSubView:create();	
	local win = CCDirector:sharedDirector():getWinSize();
	view:LoadCCBI("activity/FightBossDetailView.ccbi",CCSize(768,win.height));
	self:addChild(view)
	view:setPosition(CCPoint(win.width / 2, win.height / 2));
	self.m_dlgview = view;
end

function fightBossDetailView:initTable()	
	self:initHandle();
	self.m_contentview = self.m_dlgview:getNode("node_rep_table");
	local contentsize = self.m_contentview:getContentSize();
	self.m_cellsize = self.m_dlgview:getNode("node_rank_cell"):getContentSize();
	
	local tableview = LuaTableView:createWithHandler(self.m_handler, CCSizeMake(contentsize.width,contentsize.height))
	self.m_tableview = tableview
	tableview:setDirection(kCCScrollViewDirectionVertical);
	tableview:setVerticalFillOrder(kCCTableViewFillTopDown);
	tableview:reloadData()
	self.m_contentview:addChild(tableview);
	tableview:setTouchPriority(fightBossDetailView.m_touchPriority);
end

function fightBossDetailView:initUI()		
	self:loadCCBI()
	
	tolua.cast(self.m_dlgview:getNode("btn_desc"), "CCControlButton"):setEnabled(false)
	tolua.cast(self.m_dlgview:getNode("btn_rep"), "CCControlButton"):setEnabled(true)
	tolua.cast(self.m_dlgview:getNode("node_detail_container"), "CCNode"):setVisible(true)
	tolua.cast(self.m_dlgview:getNode("node_rep_container"), "CCNode"):setVisible(false)
	--玩法说明修改_litao_2014.8.2
	local str = "1. "..string.format(localizable.fightBoss_new_detail_desc_1, self.m_damageL1)
	--local str = "1. "..tostring(self.m_damageL1)..localizable.fightBoss_hurt_desc_2..tostring(self.m_repL1)..localizable.fightBoss_prestige_desc
	tolua.cast(self.m_dlgview:getNode("labelDescription1"),"CCLabelTTF"):setString(str)
	
	local str = "2. "..string.format(localizable.fightBoss_new_detail_desc_2, self.m_damageL2)
	--local str = "2. "..tostring(self.m_damageL2)..localizable.fightBoss_hurt_desc_2..tostring(self.m_repL2)..localizable.fightBoss_prestige_desc
	tolua.cast(self.m_dlgview:getNode("labelDescription2"),"CCLabelTTF"):setString(str)
	
	--local str = "3. "..tostring(self.m_damageL3)..localizable.fightBoss_hurt_desc_2..tostring(self.m_repL3)..localizable.fightBoss_prestige_desc
	--tolua.cast(self.m_dlgview:getNode("labelDescription3"),"CCLabelTTF"):setString(str)
	tolua.cast(self.m_dlgview:getNode("labelDescription3"),"CCLabelTTF"):setVisible(false)
	
	self:BindControl()
	
	tolua.cast(self.m_dlgview:getNode("label_last_shot_reputation"), "CCLabelTTF"):setString(self.m_lastshotReward)
	tolua.cast(self.m_dlgview:getNode("label_in_reputation"), "CCLabelTTF"):setString(self.m_inReward)
	tolua.cast(self.m_dlgview:getNode("label_boss_level"), "CCLabelTTF"):setString(self.m_bosslevel)
	
	self:initTable()
	
	self:ClickDescTab()
end

function fightBossDetailView:initHandle()
	self.m_handler = LuaEventHandler:create(function(fn, table, a1, a2, x, y)
		local r
		if fn == "cellSize" then
			-- Return cell size
			-- a1 is cell index (-1 means default size, in cocos2d-x version below 2.1.3, it's always -1)
			r = self.m_cellsize;
		elseif fn == "cellAtIndex" then
			-- Return CCTableViewCell, a1 is cell index (zero based), a2 is dequeued cell (maybe nil)
			-- Do something to create cell and change the content
			local cell = bossRankCellView:create();
			cell:setIndex(a1);
			cell:setCellData(self.m_rankdata[a1+1]);
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
			r = #self.m_rankdata;
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

function fightBossDetailView:setData(lastshotReward, inReward, rankData, bosslevel)
	self.m_lastshotReward = lastshotReward
	self.m_inReward = inReward
	self.m_rankdata = rankData
	self.m_bosslevel = bosslevel
	return nil
end

function fightBossDetailView:setExtraData(damageL1,repL1,damageL2,repL2,damageL3,repL3)
	self.m_damageL1 = damageL1
	self.m_repL1 = repL1
	self.m_damageL2 = damageL2
	self.m_repL2 = repL2
	self.m_damageL3 = damageL3
	self.m_repL3 = repL3
end

function fightBossDetailView:BindControl()
	fightBossDetailView.m_selfview:setTouchEnabled(true)
	fightBossDetailView.m_selfview:registerScriptTouchHandler(fightBossDetailView_onTouch,false,kCCMenuHandlerPriority-1,true)
	fightBossDetailView.m_selfview:setTouchMode(0) 
	
	self.m_btn_desc = tolua.cast(self.m_dlgview:getNode("btn_desc"), "CCControlButton")
	self.m_btn_rep = tolua.cast(self.m_dlgview:getNode("btn_rep"), "CCControlButton")
	self.m_btn_excharge = tolua.cast(self.m_dlgview:getNode("btn_excharge"), "CCControlButton")
	self.m_btn_close = tolua.cast(self.m_dlgview:getNode("closeButton"), "CCControlButton")
	self.m_btn_right = tolua.cast(self.m_dlgview:getNode("rightButton"), "CCControlButton")
	
	-- 初始化按钮
	self.m_btn_desc:setTouchPriority(fightBossDetailView.m_touchPriority);
	self.m_dlgview:handleButtonEvent(self.m_btn_desc, function(button, event)
		self:ClickDescTab();
		return nil
	end, CCControlEventTouchUpInside)
	
	self.m_btn_rep:setTouchPriority(fightBossDetailView.m_touchPriority);
	self.m_dlgview:handleButtonEvent(self.m_btn_rep, function(button, event)
		self:ClickRepTab();
		return nil
	end, CCControlEventTouchUpInside)
	
	self.m_btn_excharge:setTouchPriority(fightBossDetailView.m_touchPriority);
	self.m_dlgview:handleButtonEvent(self.m_btn_excharge, function(button, event)
		self:ClickExchargeTab();
		return nil
	end, CCControlEventTouchUpInside)
	
	self.m_btn_close:setTouchPriority(fightBossDetailView.m_touchPriority);
	self.m_dlgview:handleButtonEvent(self.m_btn_close, function(button, event)
		self:CloseView();
		return nil
	end, CCControlEventTouchUpInside)
	
	self.m_btn_right:setTouchPriority(fightBossDetailView.m_touchPriority);
	self.m_dlgview:handleButtonEvent(self.m_btn_right, function(button, event)
		self:CloseView();
		return nil
	end, CCControlEventTouchUpInside)
end

function fightBossDetailView:CloseView()    
	fightBossDetailView.m_selfview:removeFromParentAndCleanup(true);
end

function fightBossDetailView:ClickDescTab()
	tolua.cast(self.m_dlgview:getNode("btn_desc"), "CCControlButton"):setEnabled(false)
	tolua.cast(self.m_dlgview:getNode("btn_rep"), "CCControlButton"):setEnabled(true)
	tolua.cast(self.m_dlgview:getNode("btn_excharge"), "CCControlButton"):setEnabled(true)
	
	tolua.cast(self.m_dlgview:getNode("node_detail_container"), "CCNode"):setVisible(true)
	tolua.cast(self.m_dlgview:getNode("node_rep_container"), "CCNode"):setVisible(false)
	tolua.cast(self.m_dlgview:getNode("node_excharge_container"), "CCNode"):setVisible(false)
end

function fightBossDetailView:ClickRepTab()
	tolua.cast(self.m_dlgview:getNode("btn_desc"), "CCControlButton"):setEnabled(true)
	tolua.cast(self.m_dlgview:getNode("btn_rep"), "CCControlButton"):setEnabled(false)
	tolua.cast(self.m_dlgview:getNode("btn_excharge"), "CCControlButton"):setEnabled(true)
	
	tolua.cast(self.m_dlgview:getNode("node_detail_container"), "CCNode"):setVisible(false)
	tolua.cast(self.m_dlgview:getNode("node_rep_container"), "CCNode"):setVisible(true)
	tolua.cast(self.m_dlgview:getNode("node_excharge_container"), "CCNode"):setVisible(false)
end

function fightBossDetailView:ClickExchargeTab()
	tolua.cast(self.m_dlgview:getNode("btn_desc"), "CCControlButton"):setEnabled(true)
	tolua.cast(self.m_dlgview:getNode("btn_rep"), "CCControlButton"):setEnabled(true)
	tolua.cast(self.m_dlgview:getNode("btn_excharge"), "CCControlButton"):setEnabled(false)
	
	tolua.cast(self.m_dlgview:getNode("node_detail_container"), "CCNode"):setVisible(false)
	tolua.cast(self.m_dlgview:getNode("node_rep_container"), "CCNode"):setVisible(false)
	tolua.cast(self.m_dlgview:getNode("node_excharge_container"), "CCNode"):setVisible(true)
end




