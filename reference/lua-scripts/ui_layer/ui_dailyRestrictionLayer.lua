--dailyPay
--litao
--2014-7-29
---------------------------------------------
require("config/firstpurchase_config")
require("ui_layer/ui_purchaseLayer")
require("ui_layer/ui_purchaseTableCell")

module("ui_dailyRestrictionLayer", package.seeall)
baseClass(layer_base_t, ui_dailyRestrictionLayer)

function init(self, node)
	self.contentNode_ = GetActivityView():GetNodeContent()
	self.contentSize_ = self.contentNode_:getContentSize()

	local ccbiAttrTable = {name="activity/DailyRestrictionView.ccbi", size=self.contentSize_}
	layer_base_t.init(self, true, ccbiAttrTable)

	--用户info
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	--pre node
	self.preNode = node
	--时间增量
	self.deltatime = 0
	--活动状态
	self.m_state = 0
	--datas
	self.award_datas = {}
	--tableView cell container
	self.cellNodes = {}
	--touch
	self.m_touchPoint = nil
	self.m_touchBegan = nil
	self.m_touchEnd = nil

	self:init_ui()
	self:init_binding_event()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		--label
		self.label_left_time = tolua.cast(self.proxy_:getNode("label_time_remain"), "CCLabelTTF")

		--node
		self.node_content = tolua.cast(self.proxy_:getNode("node_gift_table_content"), "CCNode")
		self.node_cell = tolua.cast(self.proxy_:getNode("node_gift_cell_node"), "CCNode")

		--init
		self:pre_base_info()
	end
end

function pre_base_info(self)
	local function updateLeftTimeLabel(fDeltaTime)
		self.deltatime = self.deltatime + fDeltaTime
		if self.deltatime >= 1 then
			local intPart, floatPart = math.modf(self.deltatime)
			self.m_resttime = self.m_resttime - intPart
			if self.m_resttime > 0 then
				local timeStr = tools.convertTimeElectronicWatchHaveDay(self.m_resttime, 3)
				self.label_left_time:setString(timeStr..localizable.ui_dailyRestriction_timeleft)
				self.deltatime = floatPart
			else
				self.m_state = 1
				self.label_left_time:unscheduleUpdate()
			end
		end
	end
	--请求基本信息
	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 1, "rl_r_dailylimit")
	cclog("rl_w_dailycost & cmd = 1---%s", urlpath)
	GetMainMenu():ShowLoadingDlg()
	CCHttpRequest:open(urlpath, kHttpPost, "query=param1&other=params"):sendWithHandler(
		function(res, hnd)
			GetMainMenu():CloseLoadding()
			local resData = res:getResponseData()
			local code = res:getResponseCode()
			local xfile = xml.parse(resData)
			local item = xfile:find("RENLONG")
			if item == nil then
				return nil
			end
			cclog("%s", resData)
			local retcode = item.code
			if retcode == "0" then
				--先保存以前的倍数
				local pre_muti = self.soul_muti
				--basic
				local _basic = item:find("packages")
				if _basic then
					--剩余时间
					self.m_resttime = tonumber(_basic:find("remain_time")[1])
					--实时更新活动时间
					if self.m_resttime > 0 then
						self.m_state = 0
						self.label_left_time:scheduleUpdateWithPriorityLua(updateLeftTimeLabel, 0)
						self.label_left_time:setString(tools.convertTimeElectronicWatchHaveDay(self.m_resttime, 3)..localizable.ui_dailyRestriction_timeleft)
					else
						self.m_state = 1
						self.label_left_time:setString(localizable.ui_monopoly_end)
					end
				end

				--award list
				local _award = item:find("award")
				if _award then
					for i=1,#_award do
						table.insert(self.award_datas, _award[i])
					end
				end
													
				--update
				self:init_ui_ext()
			else
				GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
			end
		end)
end

function init_ui_ext(self)
	self:creatTabelView()
end

function creatTabelView(self)
	-- body
	if self._tableView == nil then
		local cellContentSize = self.node_cell:getContentSize()
		self.cell_size = CCSizeMake(cellContentSize.width,cellContentSize.height)

		self.content_size = self.node_content:getContentSize()
		self:initPicTableHandle()
		self._tableView = LuaTableView:createWithHandler(self._tableViewHandler, CCSizeMake(self.content_size.width, self.content_size.height))
		self._tableView:setDirection(kCCScrollViewDirectionVertical)
		self._tableView:setVerticalFillOrder(kCCTableViewFillTopDown)
		self._tableView:setTouchPriority(kCCMenuHandlerPriority - 1)
		
		self.node_content:addChild(self._tableView)
	else
		self._tableView:reloadData()
	end
end

function initPicTableHandle(self)
	self._tableViewHandler = LuaEventHandler:create(function(fn, table, a1, a2, x, y)
		local r
		if fn == "cellSize" then
			r = self.cell_size;
		elseif fn == "cellAtIndex" then
    		local nodeLayer = createObj(ui_dailyRestrictionCell, self.cell_size, self.award_datas[a1 + 1])
			--tableView cell container
			self.cellNodes[a1+1] = nodeLayer
			if not a2 then
				a2 = CCTableViewCell:create()
				a2:addChild(nodeLayer.node_)
			else
				a2:removeAllChildrenWithCleanup(true)
        		a2:addChild(nodeLayer.node_)
			end

			nodeLayer.node_:setTag(100)

			r = a2
		elseif fn == "numberOfCells" then
			r = #self.award_datas;
		    -- Cell events:
		elseif fn == "cellTouched" then			-- A cell was touched, a1 is cell that be touched. This is not necessary.
			local cell_index = a1:getIdx() + 1
			local _layer = self.cellNodes[cell_index]

			if _layer.btnBuy:boundingBox():containsPoint(self.m_touchPoint) then
				self:GetAward(cell_index)
			end

			self.m_touchPoint = nil
		elseif fn == "cellTouchBegan" then		-- A cell is touching, a1 is cell, a2 is CCTouch
			self.m_touchPoint = a2:getLocation()
			self.m_touchPoint = a1:convertToNodeSpace(self.m_touchPoint)

			local cell_index = a1:getIdx() + 1

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

function GetAward(self, index)
	--活动已经结束
	if self.m_state == 1 then
		GetMainMenu():ShowTextTip(localizable.ui_monopoly_end, -1)
		return nil
	end

	if self.award_datas[index] == nil then
		return nil
	end

	--检查次数
	local remain = tonumber(self.award_datas[index].remain)
	if remain < 1 then
		GetMainMenu():ShowTextTip(localizable.ui_dailyRestriction_timesout,-1)
		return nil
	end

	--检查元宝
	local price = tonumber(self.award_datas[index].price)
	if price > self.playerData_.m_gold then
		--提示购买元宝
		GetMainMenu():ShowTextTip(localizable.ui_monopoly_gold_not_enough,-1)
		--通用付费引导
		local prePayLayer = createObj(ui_commonPrePay)
		GetMainMenu():GetModelLayer():AddDialog(prePayLayer.node_, 3)
		return nil
	end

	--请求信息
	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 2, "rl_r_dailylimit")
	urlpath = AddData(urlpath, "PackageID", index)
	--cclog("rl_w_dailycost & cmd = 2---%s", urlpath)
	GetMainMenu():ShowLoadingDlg()
	CCHttpRequest:open(urlpath, kHttpPost, "query=param1&other=params"):sendWithHandler(
		function(res, hnd)
			GetMainMenu():CloseLoadding()
			local resData = res:getResponseData()
			local code = res:getResponseCode()
			local xfile = xml.parse(resData)
			local item = xfile:find("RENLONG")
			if item == nil then
				return nil
			end
			--cclog("%s", resData)
			local retcode = item.code
			if retcode == "0" then	
				local awardXML = item:find("award")
				--只加入背包/显示掉落动画	
				ShowAward(awardXML)	
				--GetMainMenu():ShowTextTip(localizable.ui_daily_get_gift_success, -1)
				--标志
				local remain = tonumber(self.award_datas[index].remain) - 1
				self.award_datas[index].remain = tostring(remain)	
				--update
				self:updateUI()
			else
				GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
			end
		end)
end

function updateUI(self)
	self._tableView:reloadData()
end

function init_binding_event(self)
	if self.proxy_ ~= nil then
		--[[
		local function CCLayerTouch(event, x, y)
			local rect = self.node_:boundingBox()
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
		self.node_:registerScriptTouchHandler(CCLayerTouch, false, kCCMenuHandlerPriority-1, true)
		--]]
	end
end

function onNodeCleanup(self)
    --cclog("onNodeCleanup")
    if self.proxy_ then
    	self.proxy_:release()
    end
    layer_base_t.onNodeCleanup(self)
end

function createTestData(self)
	--testData
	return nil
end