--lotteryPreWinerList Rank
--litao
--2014-5-19
---------------------------------------------
module("ui_lotteryPreWinerListLayer", package.seeall)
baseClass(layer_base_t, ui_lotteryPreWinerListLayer)

function init(self, node, currentScore)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	self.contentSize_ = GetMainMenu():GetModelLayer():getContentSize()
	--Load res
	local ccbiAttrTable = {name="activity/LotteryWinerList.ccbi", size=self.contentSize_}
	layer_base_t.init(self, true, ccbiAttrTable)

	self.preNode = node
	--排行榜玩家信息
	self.m_playerDatas = {}

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

		--排行榜container
		self.node_content = tolua.cast(self.proxy_:getNode("node_content"), "CCNode")
		--cellNode
		self.node_cell = tolua.cast(self.proxy_:getNode("node_cell"), "CCNode")

		--请求信息
		self:startRequestWinerList()
	end
end

function startRequestWinerList(self)
	---[[
	--获取信息
	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 3, "rl_r_lottery")
	urlpath = AddData(urlpath, "Prize", 1)
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
				local _winerList = item:find("lottery")
				if _winerList then
					for i=1,#_winerList do
						local t_winerInfo = {} 
						t_winerInfo.pt = tostring(_winerList[i].pt)
						t_winerInfo.server = tostring(_winerList[i].zone)
						t_winerInfo.name = tostring(_winerList[i].nick)
						table.insert(self.m_playerDatas, t_winerInfo)
					end	
					--创建排名列表cell	
					if self.m_playerDatas then			
						self:createRankTableView()
					end	
				end									
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

function createRankTableView(self)
	if self.rankTableView == nil then
		local cellContentSize = self.node_cell:getContentSize()
		self.rank_cellsize = CCSizeMake(cellContentSize.width,cellContentSize.height)

		self.rank_tableContentSize = self.node_content:getContentSize()
		self:initRankTableHandle()
		self.rankTableView = LuaTableView:createWithHandler(self.rankTableViewHandler, CCSizeMake(self.rank_tableContentSize.width, self.rank_tableContentSize.height))
		self.rankTableView:setDirection(kCCScrollViewDirectionVertical)
		self.rankTableView:setVerticalFillOrder(kCCTableViewFillTopDown)
		self.rankTableView:setTouchPriority(kCCMenuHandlerPriority - 1)

		self.node_content:addChild(self.rankTableView)
	else
		self.rankTableView:reloadData()
	end
end

function initRankTableHandle(self)
	self.rankTableViewHandler = LuaEventHandler:create(function(fn, table, a1, a2, x, y)
		local r
		if fn == "cellSize" then
			r = self.rank_cellsize;
		elseif fn == "cellAtIndex" then
    		local nodeLayer = createObj(ui_lotteryPreWinerListCell, self.rank_cellsize, self.m_playerDatas[a1 + 1])
			if not a2 then
				a2 = CCTableViewCell:create()
				a2:addChild(nodeLayer.node_)
			else
				a2:removeAllChildrenWithCleanup(true)
        		a2:addChild(nodeLayer.node_)
			end
			r = a2
		elseif fn == "numberOfCells" then
			r = #self.m_playerDatas;
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