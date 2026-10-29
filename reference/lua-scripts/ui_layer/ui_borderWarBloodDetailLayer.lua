--边界碑血量详情
--litao
--2014-3-4
---------------------------------------------
module("ui_borderWarBloodDetailLayer", package.seeall)
baseClass(layer_base_t, ui_borderWarBloodDetailLayer)

function init(self, node, data)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	local winSize = CCDirector:sharedDirector():getWinSize()

	--Load res
	local ccbiAttrTable = {name="activity/BorderWarBloodDetailView.ccbi", size=CCSizeMake(768, winSize.height)}
	layer_base_t.init(self, true, ccbiAttrTable)

	self.preNode = node
	--当前国家data
	self.curData = data
	--伤害信息
	self.m_cellDatas = {}

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
		self.btnDialogClose = tolua.cast(self.proxy_:getNode("closeBtn"), "CCControlButton")
		--container
		self.node_content = tolua.cast(self.proxy_:getNode("bloodDetail_contentNode"), "CCNode")
		--cellNode
		self.node_cell = tolua.cast(self.proxy_:getNode("bloodDetail_cellNode"), "CCNode")
		--tip
		self.tip = tolua.cast(self.proxy_:getNode("tip"), "CCLabelTTF")
		self.tip:setVisible(false)
		--title
		self.label_title = tolua.cast(self.proxy_:getNode("bloodDetail_titleLabel"), "CCLabelTTF")
		local curCountryNameLabel = self.preNode:retCountryText(self.curData.curCountryId, 1)
		self.label_title:setString(tostring(curCountryNameLabel..localizable.ui_border_blood_info))
		--请求信息
		self:startRequest()
	end
end

function startRequest(self)
	---[[
	--获取信息
	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 3, "rl_r_frontiers_war_info")
	urlpath = AddData(urlpath, "Country", self.curData.curCountryId)
	--cclog("BorderEnemyInfo---CGI----%s", urlpath)
	GetMainMenu():ShowLoadingDlg()
	CCHttpRequest:open(urlpath, kHttpPost,"query=param1&other=params"):sendWithHandler(
		function(res, hnd)
			GetMainMenu():CloseLoadding()
			local resData = res:getResponseData()
			local code = res:getResponseCode()
			local xfile = xml.parse(resData)
			local item = xfile:find("RENLONG")
			local retcode = item.code
			--cclog("BorderBloodInfo----%s", resData)
			if retcode == "0" then
				--信息列表
				local itemList = (xfile:find("hurt_record"))
				if itemList then
					self.m_cellDatas = {}
					for i = 1, #itemList do
						local tempitem = {}
						tempitem.index = tostring("["..i.."]")
						tempitem.time = tools.convertTimeElectronicWatch(tonumber(itemList[i].attack_starttime), 3) 	
						tempitem.nick = itemList[i].enemy_nick
						tempitem.countryId = tonumber(itemList[i].enemy_country)

						local stay_time = tools.convertSecToStr(tonumber(itemList[i].attack_lasttime), true)
						local attackType = nil
						if tonumber(itemList[i].attack_type) == 1 then
							attackType = tostring(localizable.ui_border_provoke)
						else
							attackType = tostring(localizable.ui_border_wander)
						end 
						local hurt = tonumber(itemList[i].attack_hurt)

						--tempitem.desc = tostring("在边境"..attackType..stay_time..",造成"..hurt.."点伤害!")
						tempitem.desc = string.format(localizable.ui_border_tips5, attackType..stay_time, tostring(hurt))
						table.insert(self.m_cellDatas, tempitem)
					end
				end

				--创建列表cell
				if #self.m_cellDatas < 1 then					
					self.tip:setVisible(true)
				else
					self:createRankTableView()					
				end
			else
				--边界碑玩法不在开放时段/未开启
				GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
			end
		end)
    --]]
end

function init_binding_event(self)
	if self.proxy_ ~= nil then
		local function CCLayerTouch(event,x,y)
			local rect = self.preNode.node_:boundingBox()
			rect.origin = ccp(0,0)
			local p = self.preNode.node_:convertToNodeSpace(ccp(x,y))
			if event == "began" then
				if rect:containsPoint(p) == true then
					return true
				else
					return true
				end
			end
		end
		self.node_:setTouchEnabled(true)
		self.node_:registerScriptTouchHandler(CCLayerTouch, false, kCCMenuHandlerPriority - 1, true)

		local function close_window(btn, event)
			self.node_:removeFromParentAndCleanup(true)
		end

		--绑定按钮事件
		self.btnDialogClose:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.proxy_:handleControlEvent(self.btnDialogClose, close_window, CCControlEventTouchUpInside)
	end
end

function createRankTableView(self)
	-- body
	if self.tableView == nil then
		local cellContentSize = self.node_cell:getContentSize()
		self.cellsize = CCSize(cellContentSize.width,cellContentSize.height)
		self.contentSize = self.node_content:getContentSize()
		self:initHandle()
		self.tableView = LuaTableView:createWithHandler(self.rankTableViewHandler, CCSizeMake(self.contentSize.width, self.contentSize.height))
		self.tableView:setDirection(kCCScrollViewDirectionVertical)
		self.tableView:setVerticalFillOrder(kCCTableViewFillTopDown)
		self.tableView:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.node_content:addChild(self.tableView)
	else
		self.tableView:reloadData()
	end
end

function initHandle(self)
	self.rankTableViewHandler = LuaEventHandler:create(function(fn, table, a1, a2, x, y)
		local r
		if fn == "cellSize" then
			r = self.cellsize
		elseif fn == "cellAtIndex" then
    		local nodeLayer = createObj(ui_borderWarBloodDetailCell, self.cellsize, self.m_cellDatas[a1 + 1])
    		if not a2 then
				a2 = CCTableViewCell:create()
				a2:addChild(nodeLayer.node_)
			else
				a2:removeAllChildrenWithCleanup(true)
        		a2:addChild(nodeLayer.node_)
			end
			r = a2
		elseif fn == "numberOfCells" then
			r = #self.m_cellDatas
		    -- Cell events:
		elseif fn == "cellTouched" then			-- A cell was touched, a1 is cell that be touched. This is not necessary.
			---[[
			--local cellIndex = a1:getIdx() + 1
			--]]
		elseif fn == "cellTouchBegan" then		-- A cell is touching, a1 is cell, a2 is CCTouch
			r = true
		elseif fn == "cellTouchEnded" then		-- A cell was touched, a1 is cell, a2 is CCTouch
			local 
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
	return nil
end