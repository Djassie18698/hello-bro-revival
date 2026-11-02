--my lucky num layer
--litao
--2014-5-19
---------------------------------------------
module("ui_lotteryMyLuckyNumListLayer", package.seeall)
baseClass(layer_base_t, ui_lotteryMyLuckyNumListLayer)

function init(self, node, currentScore)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	self.contentSize_ = GetMainMenu():GetModelLayer():getContentSize()
	--Load res
	local ccbiAttrTable = {name="activity/LotteryMyLuckyNumListView.ccbi", size=self.contentSize_}
	layer_base_t.init(self, true, ccbiAttrTable)

	self.preNode = node
	--data
	self.m_luckyNumsData = {}
	--创建测试数据信息
	--self:createTestData()

	--init && bindEvent
	---[[
	self:init_ui()
	self:init_binding_event()
	--]]
end

function init_ui(self)
	if self.proxy_ ~= nil then
		--关闭按钮
		self.btn_close = tolua.cast(self.proxy_:getNode("btn_close"), "CCControlButton")

		--container
		self.node_content_cur = tolua.cast(self.proxy_:getNode("node_content_cur"), "CCNode")
		self.node_content_pre = tolua.cast(self.proxy_:getNode("node_content_pre"), "CCNode")
		--cellNode
		self.node_cell = tolua.cast(self.proxy_:getNode("node_cell"), "CCNode")

		--
		self:startRequestMyLuckyNumInfo()
		--self:createCurTableView()
		--self:createPreTableView()
	end
end

function startRequestMyLuckyNumInfo(self)
	---[[
	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 2, "rl_r_lottery")
	--cclog("rl_r_lottery----%s", urlpath)
	GetMainMenu():ShowLoadingDlg()
	CCHttpRequest:open(urlpath, kHttpPost,"query=param1&other=params"):sendWithHandler(
		function(res, hnd)
			GetMainMenu():CloseLoadding()
			local resData = res:getResponseData()
			local code = res:getResponseCode()
			local xfile = xml.parse(resData)
			local item = xfile:find("RENLONG")
			local retcode = item.code
			if retcode == "0" then
				cclog("rl_r_lottery.....%s", resData)
				self.m_luckyNumsData = {}
				--本期号码
				local cur_list = item:find("current_no")
				local cur_data = {}
				for i=1,#cur_list do
					local t_num = {}
					t_num.index = i
					t_num.num = cur_list[i][1]
					table.insert(cur_data, t_num)
				end
				self.m_luckyNumsData.cur_list = cur_data
				--上期号码
				local pre_list = item:find("last_no")
				local pre_data = {}
				for i=1,#pre_list do
					local t_num = {}
					t_num.index = i
					t_num.num = pre_list[i][1]
					table.insert(pre_data, t_num)
				end
				self.m_luckyNumsData.pre_list = pre_data
				--创建排名列表cell				
				self:createCurTableView()
				self:createPreTableView()					
			else
				GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
			end
		end)
	--]]
end

function init_binding_event(self)
	if self.proxy_ ~= nil then
		local function CCLayerTouch(event,x,y)
			local rect = self.node_:boundingBox()
			rect.origin = ccp(0,0)
			local p = self.node_:convertToNodeSpace(ccp(x,y))
			if event == "began" then
				if rect:containsPoint(p) == true then
					return true
				end
			end
		end
		self.node_:setTouchEnabled(true)
		self.node_:registerScriptTouchHandler(CCLayerTouch, false, kCCMenuHandlerPriority - 1, true)
		
		local function close_window(btn, event)
			self.node_:removeFromParentAndCleanup(true)
		end
	
		--关闭
		self.btn_close:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.proxy_:handleControlEvent(self.btn_close, close_window, CCControlEventTouchUpInside)
	end
end

function createCurTableView(self)
	if self.curTableView == nil then
		local cellContentSize = self.node_cell:getContentSize()
		self.node_cellsize = CCSizeMake(cellContentSize.width,cellContentSize.height)

		self.rank_tableContentSize = self.node_content_cur:getContentSize()
		self:initCurTableHandle()
		self.curTableView = LuaTableView:createWithHandler(self.curTableViewHandler, CCSizeMake(self.rank_tableContentSize.width, self.rank_tableContentSize.height))
		self.curTableView:setDirection(kCCScrollViewDirectionVertical)
		self.curTableView:setVerticalFillOrder(kCCTableViewFillTopDown)
		self.curTableView:setTouchPriority(kCCMenuHandlerPriority - 1)

		self.node_content_cur:addChild(self.curTableView)
	else
		self.curTableView:reloadData()
	end
end

function initCurTableHandle(self)
	self.curTableViewHandler = LuaEventHandler:create(function(fn, table, a1, a2, x, y)
		local r
		if fn == "cellSize" then
			r = self.node_cellsize;
		elseif fn == "cellAtIndex" then
    		local nodeLayer = createObj(ui_lotteryMyLuckyNumListCell, self.node_cellsize, self.m_luckyNumsData.cur_list[a1 + 1])
			if not a2 then
				a2 = CCTableViewCell:create()
				a2:addChild(nodeLayer.node_)
			else
				a2:removeAllChildrenWithCleanup(true)
        		a2:addChild(nodeLayer.node_)
			end
			r = a2
		elseif fn == "numberOfCells" then
			r = #self.m_luckyNumsData.cur_list;
		    -- Cell events:
		elseif fn == "cellTouched" then			-- A cell was touched, a1 is cell that be touched. This is not necessary.
			--local cellIndex = a1:getIdx() + 1
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

function createPreTableView(self)
	if self.preTableView == nil then
		local cellContentSize = self.node_cell:getContentSize()
		self.node_cellsize = CCSizeMake(cellContentSize.width,cellContentSize.height)

		self.pre_tableContentSize = self.node_content_pre:getContentSize()
		self:initPreTableHandle()
		self.preTableView = LuaTableView:createWithHandler(self.preTableViewHandler, CCSizeMake(self.pre_tableContentSize.width, self.pre_tableContentSize.height))
		self.preTableView:setDirection(kCCScrollViewDirectionVertical)
		self.preTableView:setVerticalFillOrder(kCCTableViewFillTopDown)
		self.preTableView:setTouchPriority(kCCMenuHandlerPriority - 1)

		self.node_content_pre:addChild(self.preTableView)
	else
		self.preTableView:reloadData()
	end
end

function initPreTableHandle(self)
	self.preTableViewHandler = LuaEventHandler:create(function(fn, table, a1, a2, x, y)
		local r
		if fn == "cellSize" then
			r = self.node_cellsize;
		elseif fn == "cellAtIndex" then
    		local nodeLayer = createObj(ui_lotteryMyLuckyNumListCell, self.node_cellsize, self.m_luckyNumsData.pre_list[a1 + 1])
			if not a2 then
				a2 = CCTableViewCell:create()
				a2:addChild(nodeLayer.node_)
			else
				a2:removeAllChildrenWithCleanup(true)
        		a2:addChild(nodeLayer.node_)
			end
			r = a2
		elseif fn == "numberOfCells" then
			r = #self.m_luckyNumsData.pre_list;
		    -- Cell events:
		elseif fn == "cellTouched" then			-- A cell was touched, a1 is cell that be touched. This is not necessary.
			--local cellIndex = a1:getIdx() + 1
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

function onNodeCleanup(self)
    --cclog("onNodeCleanup")
    if self.proxy_ then
    	self.proxy_:release()
    end
    layer_base_t.onNodeCleanup(self)
end

function createTestData(self)
end