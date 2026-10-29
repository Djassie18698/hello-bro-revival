--[[
Description:全服限时限量团购活动
Company:XCKOO
Author:gongsun
Creation Date:2014/1/9
]]

module("ui_limitedGroupBuyingLayer", package.seeall)
baseClass(layer_base_t, ui_limitedGroupBuyingLayer)

function init(self)
	--获取用户信息
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	--如果期数不同，更新期数
	if activityPeriod.limitGroup.display == -1 then
		newsCount = newsCount - 1
		writeActivityData(self.playerData_.m_uid, activity_config.activityTipConfig.limitGroup, activityPeriod.limitGroup.period)
	elseif activityPeriod.limitGroup.display == -2 then
		newsCount = newsCount - 1
	end

	self.contentNode_ = GetActivityView():GetNodeContent()
	self.contentSize_ = self.contentNode_:getContentSize()
	local ccbiAttrTable = {name = "activity/LimitedGroupBuying.ccbi", size = self.contentSize_}
	layer_base_t.init(self, true, ccbiAttrTable)--加载ccbi

	self.deltatime = 0	--记录自上次更新界面以后，流逝的时间
	self.leftTime = 0  --剩余时间
	self.giftData = {}  --活动数据
	self.gotIds = {} 
	self.money = 0
	self.cellNodes = {}  --TableCells
	--self:createTestData()  --创建测试数据
	self:init_ui()  --初始化UI
end

function init_ui( self )
	if self.proxy_ ~= nil then
		self.label_rest_time = tolua.cast(self.proxy_:getNode("label_rest_time"), "CCLabelBMFont")  --剩余时间
		self.btn_give_money = tolua.cast(self.proxy_:getNode("btn_give_money"), "CCControlButton")  --立即充值
		self.node_gift_table_content = tolua.cast(self.proxy_:getNode("node_gift_table_content"), "CCNode")  --TableNode
		self.node_gift_cell_node = tolua.cast(self.proxy_:getNode("node_gift_cell_node"), "CCNode")  --CellsNode


        -- 刷新数据
		local function freshTableData()
			if self.giftTableView ~= nil then
				for i=1,#self.giftData do
					self.giftData[i].status = 2
				end
				local offset = self.giftTableView:getContentOffset()
				self.giftTableView:reloadData()
				self.giftTableView:setContentOffset(offset.x, offset.y)
			end
			return nil
		end

		--时间倒计时
		local function updateLeftTimeLabel(fDeltaTime)
			self.deltatime = self.deltatime + fDeltaTime
			if self.deltatime >= 1 then
				local intPart, floatPart = math.modf(self.deltatime)
				self.leftTime = self.leftTime - intPart
				local timeStr = tools.convertTimeElectronicWatch(self.leftTime, 3)
				self.label_rest_time:setString(timeStr)
				self.deltatime = floatPart
				if self.leftTime <= 0 then
					freshTableData()
				end
			end
		end

		--立即充值回调
		local function give_money_now_callback(btn, event)
			local puchaseLayer = createObj(ui_purchaseLayer)
			GetMainMenu():GetModelLayer():AddDialog(puchaseLayer.node_, 3)
		end

		--立即充值按钮事件
		self.proxy_:handleControlEvent(self.btn_give_money, give_money_now_callback, CCControlEventTouchUpInside)

		local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 4, protocol.URI_R_LIMIT_GROUP)
		cclog("url-----%s", urlpath)
		GetMainMenu():ShowLoadingDlg();	-- 获取信息的时候，不允许操作
		CCHttpRequest:open(urlpath, kHttpPost,"query=param1&other=params"):sendWithHandler(
			function(res, hnd)
				GetMainMenu():CloseLoadding() --获取信息完成时，解除禁止操作

				local resData = res:getResponseData()
				cclog("data---%s",resData)
				local code = res:getResponseCode()
				local xfile = xml.parse(resData)
				local item = xfile:find("RENLONG")
				local retcode = item.code

				if retcode == "0" then
					local preview = item:find("preview")
					local itemlist = item:find("itemlist")

					if preview then
					    self.leftTime = tonumber(preview.resttime)
					end
					--代码优化litao_2014.6.21
					if itemlist then
						for i = 1, #itemlist do
							local giftCellTable = {}
							local _awardList = itemlist[i]:find("awardlist")
							for j = 1, #_awardList do
								--增加转生等级_litao_2014.8.2
								--cclog("%d-%d----%s---%s", i, j, tostring(itemlist[i][5][j][1][1]),tostring(itemlist[i][5][j][2][1]))
								giftCellTable[j] = {name=tostring(_awardList[j]:find("name")[1]), icon=tostring(_awardList[j]:find("icon")[1]), dropid=tonumber(_awardList[j]:find("dropid")[1]), newlife=tonumber(_awardList[j]:find("newlife")[1]) }
							end
							local mstatus = 1
							if self.leftTime == 0 or tonumber(itemlist[i]:find("restnum")[1]) == 0 then
								mstatus = 2
							end
							--litao_2014.6.3_增加限量礼包原价节点
							self.giftData[i] = {id=tonumber(itemlist[i]:find("id")[1]), cost=tonumber(itemlist[i]:find("cost")[1]), restnum=tonumber(itemlist[i]:find("restnum")[1]), gift=giftCellTable, status=mstatus, origincost=tonumber(itemlist[i]:find("origincost")[1])}
						end
					end
					self:createGiftTableView()  --创建TableView
					self.label_rest_time:scheduleUpdateWithPriorityLua(updateLeftTimeLabel, 0)  --启动定时器更新剩余时间
					self.label_rest_time:setString(tools.convertTimeElectronicWatch(self.leftTime, 3))  --显示剩余时间 分钟:秒的格式
				else
				end
			end)
	end
end

--清除Node
function onNodeCleanup(self)
	if self.proxy_ then
    	self.proxy_:release()
    end
    layer_base_t.onNodeCleanup(self)
end

--创建TableView
function createGiftTableView(self, data)
	if self.giftTableView == nil then
		self.gift_tableContentSize = self.node_gift_table_content:getContentSize()  --根据TableNode的ContentSize设置TableView的size
		self.gift_cellsize = self.node_gift_cell_node:getContentSize()  --根据CellsNode的ContentSize设置tableview的cellsize
		self:initGiftTableHandle()  --实现tableview的各虚函数
		self.giftTableView = LuaTableView:createWithHandler(self.giftTableViewHandler, CCSizeMake(self.gift_tableContentSize.width, self.gift_tableContentSize.height))  --创建一个tableview
		self.giftTableView:setDirection(kCCScrollViewDirectionVertical)  --设置方向为竖向
		self.giftTableView:setVerticalFillOrder(kCCTableViewFillTopDown)  --设置填充顺序为从上到下
		self.giftTableView:setTouchPriority(-10)  --设置触摸优先级为-10
		self.node_gift_table_content:addChild(self.giftTableView)  --把创建的tableview添加到TableNode中
	end
end

--实现TableView的各虚函数
function initGiftTableHandle(self)
	self.giftTableViewHandler = LuaEventHandler:create(function(fn, table, a1, a2, x, y)
		local r
		if fn == "cellSize" then  --获取tableview的cellsize
			r = self.gift_cellsize
		elseif fn == "cellAtIndex" then
			-- 请求cell对象，a1是格索引（从0开始），a2是缓存的cell对象（可能为空）  
            -- 在此建立“格”对象并填充其要显示的内容。
    		local nodeLayer = createObj(ui_limitedGroupBuyTableCell, self.gift_cellsize, self.giftData[a1 + 1])
    		self.cellNodes[a1 + 1] = nodeLayer
			if not a2 then
				a2 = CCTableViewCell:create()
				nodeLayer.node_:setTag(100)
				a2:addChild(nodeLayer.node_)
			else
				a2:removeAllChildrenWithCleanup(true)
				nodeLayer.node_:setAnchorPoint(ccp(0.5,0.5))
				nodeLayer.node_:setPosition(self.gift_cellsize.width / 2 + 3, self.gift_cellsize.height / 2)
				nodeLayer.node_:ignoreAnchorPointForPosition(false)
				nodeLayer.node_:setTag(100)
        		a2:addChild(nodeLayer.node_)
			end
			r = a2
		elseif fn == "numberOfCells" then  --cell的总个数
			r = #self.giftData;
		    -- Cell events:
		elseif fn == "cellTouched" then			-- A cell was touched, a1 is cell that be touched. This is not necessary.
			local cellIndex = a1:getIdx() + 1
			if self.cellNodes[cellIndex].btn_scale_sprite:boundingBox():containsPoint(self.m_touchPoint) then
				self.cellNodes[cellIndex]:btn_buy()
			end
			self.cellNodes[cellIndex]:itemClick(self.m_touchPoint)
			--litao_2014.6.24
			self.m_touchPoint = nil
		elseif fn == "cellTouchBegan" then		-- A cell is touching, a1 is cell, a2 is CCTouch
			self.m_touchPoint = a2:getLocation()
			local cell = a1:getChildByTag(100);
			self.m_touchPoint = cell:convertToNodeSpace(self.m_touchPoint)
			
			local cellIndex = a1:getIdx() + 1
			if self.cellNodes[cellIndex].btn_scale_sprite:boundingBox():containsPoint(self.m_touchPoint) then
				self.cellNodes[cellIndex].btn_scale_sprite:setVisible(false)
				self.cellNodes[cellIndex].btn_scale_sprite2:setVisible(true)
			end
			r = true
		elseif fn == "cellTouchEnded" then		-- A cell was touched, a1 is cell, a2 is CCTouch
			r = true
		elseif fn == "cellHighlight" then		-- A cell is highlighting, coco2d-x 2.1.3 or above
		elseif fn == "cellUnhighlight" then		-- A cell had been unhighlighted, coco2d-x 2.1.3 or above
			local cellIndex = a1:getIdx() + 1
			self.cellNodes[cellIndex].btn_scale_sprite:setVisible(true)
			self.cellNodes[cellIndex].btn_scale_sprite2:setVisible(false)
		elseif fn == "cellWillRecycle" then		-- A cell will be recycled, coco2d-x 2.1.3 or above
		end
		return r
	end)
end


--创建测试数据
function createTestData(self)
	self.giftData = {}
	for i = 1, 4 do
		--status---1 ->> 不可以购买
		self.giftData[i] = {id=i, num=(3000 - i * 500), price=(500 - 50 * i), gift={{name="一乐拉面(大)*3", icon="props_017"},{name="一乐拉面(大)*3", icon="props_017"},{name="一乐拉面(大)*3", icon="props_017"},{name="一乐拉面(大)*3", icon="props_017"}}, status=1}
	end
	for i = 5, 7 do
		--status---2 --> 可以购买
		self.giftData[i] = {id=i, num=(1000 + i * 50), price=(500 - 50 * i), gift={{name="一乐拉面(大)*3", icon="props_017"},{name="一乐拉面(大)*3", icon="props_017"},{name="一乐拉面(大)*3", icon="props_017"},{name="一乐拉面(大)*3", icon="props_017"}}, status=2}
	end

	--status--3 不可以购买
	self.leftTime = 1838
end