--玩家累计充值活动
--chenchun
---------------------------------------------
module("ui_accumulateMoneyLayer", package.seeall)
baseClass(layer_base_t, ui_accumulateMoneyLayer)

function init(self)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	--如果期数不同，更新期数
	if activityPeriod.timePurchase.display == -1 then
		newsCount = newsCount - 1
		writeActivityData(self.playerData_.m_uid, activity_config.activityTipConfig.timePurchase, activityPeriod.timePurchase.period)
	elseif activityPeriod.timePurchase.display == -2 then
		newsCount = newsCount - 1
	end

	self.contentNode_ = GetActivityView():GetNodeContent()
	self.contentSize_ = self.contentNode_:getContentSize()
	local ccbiAttrTable = {name="activity/AccumulateMoney.ccbi", size=self.contentSize_}
	layer_base_t.init(self, true, ccbiAttrTable)


	self.deltatime = 0	--记录自上次更新界面以后，流逝的时间
	self.leftTime = 0
	self.giftData = {}
	self.gotIds = {}
	self.money = 0
	self.cellNodes = {}
	--self:createTestData()
	self:init_ui()
	self:init_binding_event()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		self.node_gift_table_content = tolua.cast(self.proxy_:getNode("node_gift_table_content"), "CCNode")
		self.label_rest_time = tolua.cast(self.proxy_:getNode("label_rest_time"), "CCLabelBMFont")
		self.label_acc_money = tolua.cast(self.proxy_:getNode("label_acc_money"), "CCLabelBMFont")
		self.btn_give_money = tolua.cast(self.proxy_:getNode("btn_give_money"), "CCControlButton")
		self.node_gift_cell_node = tolua.cast(self.proxy_:getNode("node_gift_cell_node"), "CCNode")
		self.layer_helper = tolua.cast(self.proxy_:getNode("layer_helper"), "CCLayer")

		local function updateLeftTimeLabel(fDeltaTime)
			self.deltatime = self.deltatime + fDeltaTime
			if self.deltatime >= 1 then
				local intPart, floatPart = math.modf(self.deltatime)
				self.leftTime = self.leftTime - intPart
				local timeStr = tools.convertTimeElectronicWatch(self.leftTime, 3)
				self.label_rest_time:setString(timeStr)
				self.deltatime = floatPart
			end
		end

		
		--self.label_rest_time:scheduleUpdateWithPriorityLua(updateLeftTimeLabel, 0)
		--self.label_rest_time:setString(tools.convertTimeElectronicWatch(self.leftTime, 3))
		--self:createGiftTableView()

		local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 0, protocol.URL_R_PAY_CUMULA)
		GetMainMenu():ShowLoadingDlg();	-- 获取信息的时候，不允许操作
		CCHttpRequest:open(urlpath, kHttpPost,"query=param1&other=params"):sendWithHandler(
			function(res, hnd)
				GetMainMenu():CloseLoadding() --获取信息完成时，解除禁止操作

				local resData = res:getResponseData()
				--cclog("1111---%s",resData)
				local code = res:getResponseCode()
				local xfile = xml.parse(resData)
				local item = xfile:find("RENLONG")
				if item == nil then
					return nil
				end
				local retcode = item.code
				if retcode == "0" then
					local Items = item:find("cf")
					local userItems = item:find("user")

					if userItems then
						if userItems:find("giftIdsGot") then
							local ids = userItems:find("giftIdsGot")[1]
							if ids ~= nil then
								idsTable = tools.split(ids, "|")
								for k, v in pairs(idsTable) do
									self.gotIds[tonumber(v)] = 1
								end
							end
						end
						if userItems:find("sum") then
							self.money = tonumber(userItems:find("sum")[1]) or 0
							self.label_acc_money:setString(tostring(self.money))
						end
						if userItems:find("timeLeft") then
							self.leftTime = tonumber(userItems:find("timeLeft")[1]) or 0
						end
					end

					if Items then
						for i = 1, #Items do
							local giftCellTable = {}
							local index = 1
							for j = 1, 4 do
								if Items[i]:find("drop" .. tostring(j))[1] ~= "0" then
									--增加转生等级_litao_2014.8.2
									giftCellTable[index] = {name=Items[i]:find("name" .. tostring(j))[1], icon=Items[i]:find("icon" .. tostring(j))[1], drop=Items[i]:find("drop" .. tostring(j))[1], newlife = tonumber(Items[i]:find("newlife"..tostring(j))[1])}
									index = index + 1
								end
							end
							if self.gotIds[tonumber(Items[i][1][1])] == 1 then
								self.giftData[i] = {id=tonumber(Items[i][1][1]), title=tostring(Items[i][2][1]) .. localizable.ui_accu_big_gift, gift=giftCellTable, status=2}
							elseif self.money >= tonumber(Items[i][2][1]) then
								self.giftData[i] = {id=tonumber(Items[i][1][1]), title=tostring(Items[i][2][1]) .. localizable.ui_accu_big_gift, gift=giftCellTable, status=1}
							else
								self.giftData[i] = {id=tonumber(Items[i][1][1]), title=tostring(Items[i][2][1]) .. localizable.ui_accu_big_gift, gift=giftCellTable, status=3}
							end
						end
					end

					self.label_rest_time:scheduleUpdateWithPriorityLua(updateLeftTimeLabel, 0)
					self.label_rest_time:setString(tools.convertTimeElectronicWatch(self.leftTime, 3))
					self:createGiftTableView()
				else
				end
			end)

	end
end


function init_binding_event(self)
	if self.proxy_ ~= nil then

		local function CCLayerTouch(event, x, y)
			local rect = self.layer_helper:boundingBox()
			rect.origin = ccp(0,0)
			local p = self.layer_helper:convertToNodeSpace(ccp(x,y))
			if event == "began" then
				if rect:containsPoint(p) == true then
					return true
				else
					return false
				end
			end
		end

		self.layer_helper:setTouchEnabled(true)
		self.layer_helper:registerScriptTouchHandler(CCLayerTouch, false, -2, true)

		local function give_money_now_callback(btn, event)
			local puchaseLayer = createObj(ui_purchaseLayer)
			GetMainMenu():GetModelLayer():AddDialog(puchaseLayer.node_, 3)
		end

		self.btn_give_money:setTouchPriority(-3)
		self.proxy_:handleControlEvent(self.btn_give_money, give_money_now_callback, CCControlEventTouchUpInside)
	end
end

function onNodeCleanup(self)
	--cclog("1111---002")
	if self.proxy_ then
    	self.proxy_:release()
    end
    layer_base_t.onNodeCleanup(self)
end

--local funtion
function createGiftTableView(self, data)
	-- body
	if self.giftTableView == nil then
		self.gift_cellsize = self.node_gift_cell_node:getContentSize()
		self.gift_tableContentSize = self.node_gift_table_content:getContentSize()
		self:initGiftTableHandle()
		self.giftTableView = LuaTableView:createWithHandler(self.giftTableViewHandler, CCSizeMake(self.gift_tableContentSize.width, self.gift_tableContentSize.height))
		self.giftTableView:setDirection(kCCScrollViewDirectionVertical)
		self.giftTableView:setVerticalFillOrder(kCCTableViewFillTopDown)
		self.giftTableView:setTouchPriority(-10)
		self.node_gift_table_content:addChild(self.giftTableView)

		--local offset = self.rankTableView:getContentOffset()
		--self.rankTableView:reloadData()
		--self.rankTableView:setContentOffset(offset.x, offset.y)
	end
end

function initGiftTableHandle(self)
	self.giftTableViewHandler = LuaEventHandler:create(function(fn, table, a1, a2, x, y)
		local r
		if fn == "cellSize" then
			r = self.gift_cellsize
		elseif fn == "cellAtIndex" then
    		local nodeLayer = createObj(ui_accumulateMoneyTableCell, self.gift_cellsize, self.giftData[a1 + 1])
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
		elseif fn == "numberOfCells" then
			r = #self.giftData;
		    -- Cell events:
		elseif fn == "cellTouched" then			-- A cell was touched, a1 is cell that be touched. This is not necessary.
			local cellIndex = a1:getIdx() + 1
			if self.cellNodes[cellIndex].node_btn_container:boundingBox():containsPoint(self.m_touchPoint) then
				self.cellNodes[cellIndex]:btn_get_gift_1()
			end
		elseif fn == "cellTouchBegan" then		-- A cell is touching, a1 is cell, a2 is CCTouch
			self.m_touchPoint = a2:getLocation()

			local cell = a1:getChildByTag(100);
			self.m_touchPoint = cell:convertToNodeSpace(self.m_touchPoint)

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

--创建测试数据
function createTestData(self)
	self.giftData = {}
	for i = 1, 3 do
		--status---1 ->> 已经领取
		self.giftData[i] = {id=i, title="50元大礼包", gift={{name="火影鸣人", icon="props_014"},{name="火影鸣人", icon="props_014"},{name="火影鸣人", icon="props_014"},{name="火影鸣人", icon="props_014"}}, status=1}
	end
	for i = 4, 5 do
		--status---2 --> 可以领取
		self.giftData[i] = {id=i, title="100元大礼包", gift={{name="火影鸣人", icon="props_014"},{name="火影鸣人", icon="props_014"},{name="火影鸣人", icon="props_014"}}, status=2}
	end

	--status--3 不可以领取
	self.leftTime = 96400
end