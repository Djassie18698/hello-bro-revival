--descriptioin:女神献花描述界面
--company: xckoo
--author: chenchun
--date: 2014-4-09

---------------------------------------------
module("ui_nvshenDescLayer", package.seeall)
baseClass(layer_base_t, ui_nvshenDescLayer)


--title_color_config = {{title="雏田的回馈",color=ccc3(255,0,255)},{title="小南的回馈",color=ccc3(0,140,255)},{title="照美名的回馈",color=ccc3(255,0,255)},{title="春野樱的回馈",color=ccc3(0,140,255)},{title="纲手的回馈",color=ccc3(255,0,255)}}
title_color_config = {{title=localizable.ui_nvshen_chutian_gift,color=ccc3(255,0,255)},{title=localizable.ui_nvshen_xiaonan_gift,color=ccc3(255,0,255)},{title=localizable.ui_nvshen_zhaomeimi_gift,color=ccc3(255,0,255)},{title=localizable.ui_nvshen_chunyeyin_gift,color=ccc3(255,0,255)},{title=localizable.ui_nvshen_gangshou_gift,color=ccc3(255,0,255)}}
function init(self, data)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	self.contentSize_ = CCDirector:sharedDirector():getWinSize()
	--cclog("1111---%d, %d", self.contentSize_.width, self.contentSize_.height)
	local ccbiAttrTable = {name="activity/NvShenDesc.ccbi", size=self.contentSize_}
	layer_base_t.init(self, true, ccbiAttrTable)

	self.data = data

	self:init_ui()
	self:init_binding_event()
end


function init_ui(self)
	if self.proxy_ ~= nil then
		self.labelDescription = tolua.cast(self.proxy_:getNode("labelDescription"), "CCLabelTTF")
		self.labelTitle = tolua.cast(self.proxy_:getNode("labelTitle"), "CCLabelTTF")
		self.leftButton = tolua.cast(self.proxy_:getNode("leftButton"), "CCControlButton")
		self.rightButton = tolua.cast(self.proxy_:getNode("rightButton"), "CCControlButton")
		self.node_content = tolua.cast(self.proxy_:getNode("node_content"), "CCNode")
		self.node_cell = tolua.cast(self.proxy_:getNode("node_cell"), "CCNode")
		self.closeButton = tolua.cast(self.proxy_:getNode("closeButton"), "CCControlButton")
		
		self.labelTitle:setString(localizable.ui_nvshen_title)
		self.labelDescription:setString(localizable.ui_nvshen_description1)
		self:initTableView()	
	end
end

function init_binding_event(self)
	if self.proxy_ ~= nil then

		local function CCLayerTouch(event, x, y)
			if event == "began" then
				return true
			end
		end
		self.node_:setTouchEnabled(true)
		self.node_:registerScriptTouchHandler(CCLayerTouch, false, -3, true)

		local function closeWin()
			self.node_:removeFromParentAndCleanup(true)
		end
		self.leftButton:setTouchPriority(-3)
		self.rightButton:setTouchPriority(-3)
		self.closeButton:setTouchPriority(-3)
		self.proxy_:handleControlEvent(self.leftButton, closeWin, CCControlEventTouchUpInside)	
		self.proxy_:handleControlEvent(self.rightButton, closeWin, CCControlEventTouchUpInside)	
		self.proxy_:handleControlEvent(self.closeButton, closeWin, CCControlEventTouchUpInside)	
	end
end


function initTableView(self)
	-- body
	if self.tableview == nil then
		self.cellsize = self.node_cell:getContentSize()
		self.tableContentSize = self.node_content:getContentSize()
		self:initHandle()
		self.tableview = LuaTableView:createWithHandler(self.tableViewHandler, CCSizeMake(self.tableContentSize.width, self.tableContentSize.height))

		self.tableview:setDirection(kCCScrollViewDirectionVertical)
		self.tableview:setVerticalFillOrder(kCCTableViewFillBottomUp)
		self.tableview:setTouchPriority(-6)
		self.node_content:addChild(self.tableview)
		
		--self.tableview:reloadData()
		--self.tableview:setDragEnabled(true)
	end
end


function initHandle(self)
	self.tableViewHandler = LuaEventHandler:create(function(fn, table, a1, a2, x, y)
		local r
		if fn == "cellSize" then
			r = self.cellsize
		elseif fn == "cellAtIndex" then
    		local nodeLayer = createObj(ui_nvshenDescItem, self.cellsize, self.data[a1 + 1], ui_nvshenDescLayer.title_color_config[a1+1])
			if not a2 then
				a2 = CCTableViewCell:create()
				a2:addChild(nodeLayer.node_)
			else
				a2:removeAllChildrenWithCleanup(true)
        		a2:addChild(nodeLayer.node_)
			end
			r = a2
		elseif fn == "numberOfCells" then
			r = #self.data
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

function create_test_data(self)
	self.test_data = {
		[1] = {id = 1, icon = "nvshen_meinv1", desc = "献花1朵", ccbi="nvshenxianhua_chutian"},
		[2] = {id = 2, icon = "nvshen_meinv2", desc = "献花10朵", ccbi="nvshenxianhua_xiaonan"},
		[3] = {id = 3, icon = "nvshen_meinv3", desc = "献花30朵", ccbi="nvshenxianhua_shuiying"},
		[4] = {id = 4, icon = "nvshen_meinv4", desc = "献花50朵", ccbi="nvshenxianhua_chunyeying"},
		[5] = {id = 5, icon = "nvshen_meinv5", desc = "献花100朵", ccbi="nvshenxianhua_gangshou"}
	}
end