--descriptioin:彩票
--company: xckoo
--litao
--2014.5.15
---------------------------------------------
module("ui_lotteryTicketLayer", package.seeall)
baseClass(layer_base_t, ui_lotteryTicketLayer)

function init(self, node, data)
	self.contentNode_ = GetActivityView():GetNodeContent()
	self.contentSize_ = self.contentNode_:getContentSize()

	local ccbiAttrTable = {name="activity/LotteryTicketView.ccbi", size=self.contentSize_}
	layer_base_t.init(self, true, ccbiAttrTable)

	--用户info
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	--data
	self.m_awardDatas = {}
	--tableView cell container
	self.cellNodes = {}
	--init info
	self.m_basicInfo = {}
	--touch
	self.m_touchPoint = nil
	self.m_touchBegan = nil
	self.m_touchEnd = nil
	self.m_touch_time = 0
	self.m_touch_index = 0
	--time
	self.deltatime = 0
	--4个格子的号码
	self.m_lucky_nums = {}
	--已下注号码
	self.m_cur_lucky_nums = {[1] = 1, [2] = 1, [3] = 1, [4] = 1}

	--create data
	self:createData()

	--init
	self:init_ui()		
	self:init_binding_event()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		--label
		self.label_ticket_times = tolua.cast(self.proxy_:getNode("label_ticket_times"), "CCLabelBMFont")
		self.label_open_time = tolua.cast(self.proxy_:getNode("label_open_time"), "CCLabelTTF")
		self.label_award_info = tolua.cast(self.proxy_:getNode("label_award_info"), "CCLabelTTF")
		for i=1,4 do
			self["label_pre_award_num_"..i] = tolua.cast(self.proxy_:getNode("label_pre_award_num_"..i), "CCLabelTTF")
		end
		self.label_get_time = tolua.cast(self.proxy_:getNode("label_get_time"), "CCLabelBMFont")
		self.label_get_time_month = tolua.cast(self.proxy_:getNode("label_get_time_month"), "CCLabelBMFont")
		self.label_cost_cash = tolua.cast(self.proxy_:getNode("label_cost_cash"), "CCLabelTTF")
		self.label_rand = tolua.cast(self.proxy_:getNode("label_rand"), "CCLabelTTF")
		--btn
		self.btn_pre_lucky_list = tolua.cast(self.proxy_:getNode("btn_pre_lucky_list"), "CCControlButton")
		self.btn_readme = tolua.cast(self.proxy_:getNode("btn_readme"), "CCControlButton")
		self.btn_get_award = tolua.cast(self.proxy_:getNode("btn_get_award"), "CCControlButton")
		self.btn_rand_lucky_num = tolua.cast(self.proxy_:getNode("btn_rand_lucky_num"), "CCControlButton")
		self.btn_my_num_list = tolua.cast(self.proxy_:getNode("btn_my_num_list"), "CCControlButton")
		self.btn_buy_lucky_num = tolua.cast(self.proxy_:getNode("btn_buy_lucky_num"), "CCControlButton")
		for i=1,3 do
			self["btn_award_icon_"..i] = tolua.cast(self.proxy_:getNode("btn_award_icon_"..i), "CCControlButton")
		end
		--spr
		for i=1,3 do
			self["spr_award_icon_"..i] = tolua.cast(self.proxy_:getNode("spr_award_icon_"..i), "CCSprite")
		end	
		--node
		for i=1,4 do
			self["node_lucky_num_content_"..i] = tolua.cast(self.proxy_:getNode("node_lucky_num_content_"..i), "CCNode")
		end
		self.node_lucky_num_cell = tolua.cast(self.proxy_:getNode("node_lucky_num_cell"), "CCNode")
		--init_ext
		self:request_init_info()
	end
end

function request_init_info(self)
	--更新当前界面的信息.主要方便判断是否结束
	local function updateLotteryTime(fDeltaTime)		
		self.deltatime = self.deltatime + fDeltaTime
		--20秒定时刷新
		if self.deltatime >= 20 then
			local intPart, floatPart = math.modf(self.deltatime)
			self.deltatime = floatPart
			--
			local _t_m = os.date("%m", os.time())
			local _t_d = os.date("%d", os.time())
			local _t_H = os.date("%H", os.time())
			local _t_M = os.date("%M", os.time())

			if _t_m == os.date("%m", self.m_basicInfo.bet_end_ts) and _t_d == os.date("%d", self.m_basicInfo.bet_end_ts) and _t_H == os.date("%H", self.m_basicInfo.bet_end_ts) and _t_m == os.date("%M", self.m_basicInfo.bet_end_ts) then
				self.label_award_info:setString(localizable.ui_lottry_tips1)
			elseif _t_m == os.date("%m", self.m_basicInfo.lottery_ts) and _t_d == os.date("%d", self.m_basicInfo.lottery_ts) and _t_H == os.date("%H", self.m_basicInfo.lottery_ts) and _t_m == os.date("%M", self.m_basicInfo.lottery_ts) then
				self.node_:unscheduleUpdate()
				self:request_init_info()
			else
				cclog("open time!")
			end	
		end
	end
	--request init info
	---[[
	--获取基本信息
	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 1, "rl_r_lottery")
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
				--奖励信息。奖励列表
				self.m_awardDatas = {}
				local _award_list = item:find("award_list")
				for i=1,#_award_list do
					table.insert(self.m_awardDatas, _award_list[i])
				end
				--获取基本信息
				local _init_info = item:find("lottery")
				--当前期数
				self.m_basicInfo.phase = tonumber(_init_info:find("phase")[1])
				--当期开奖时间
				self.m_basicInfo.lottery_ts = tonumber(_init_info:find("lottery_ts")[1])
				--上期中奖号码，0表示第一期
				self.m_basicInfo.last_no = tonumber(_init_info:find("last_no")[1])
				--投注需要的元宝数
				self.m_basicInfo.cost_cash = tonumber(_init_info:find("cost_cash")[1])
				--玩家中奖等级，0表示未中奖
				self.m_basicInfo.player_prize = tonumber(_init_info:find("player_prize")[1])
				--下注截止时间
				self.m_basicInfo.bet_end_ts = tonumber(_init_info:find("bet_end_ts")[1])
				--基本信息初始化
				if self.m_basicInfo then
					--启用定时更新
					self.node_:unscheduleUpdate()
					self.node_:scheduleUpdateWithPriorityLua(updateLotteryTime, 0)
					--ext_init
					self:init_ext_ui()	
				end
			else
				GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
			end
		end)
end

function init_ext_ui(self)
	--随机下注呼吸
	local move = CCScaleBy:create(0.2, 1.1)
	local array = CCArray:create()
	array:addObject(move)
	array:addObject(move:reverse())
	array:addObject(move)
	array:addObject(move:reverse())
	array:addObject(CCDelayTime:create(1.5))
	local forever = CCRepeatForever:create(CCSequence:create(array))
	self.label_rand:runAction(forever)
	self.label_rand:setColor(ccc3(255, 255, 255))
	--[[
	local move1 = CCScaleBy:create(0.2, 1.1)
	local array1 = CCArray:create()
	array1:addObject(move1)
	array1:addObject(move1:reverse())
	array1:addObject(move1)
	array1:addObject(move1:reverse())
	array1:addObject(CCDelayTime:create(1.5))
	local forever1 = CCRepeatForever:create(CCSequence:create(array1))	
	self.btn_rand_lucky_num:runAction(forever1)
	--]]
	--cost cash
	self.label_cost_cash:setString(tostring(self.m_basicInfo.cost_cash..localizable.ui_lottry_bet_gold))
	--期数
	self.label_ticket_times:setString(self.m_basicInfo.phase)
	--获奖情况
	if self.m_basicInfo.player_prize > 0 then
		self.label_award_info:setString(string.format(localizable.ui_lottry_tips2, tostring(self.m_basicInfo.player_prize)))
	else
		self.label_award_info:setString(localizable.ui_lottry_tips3)
	end
	--上期中奖号码 math.floor(9.9)	 9
	local _num_1 = math.floor(self.m_basicInfo.last_no/1000)
	local _num_2 = math.floor((self.m_basicInfo.last_no - _num_1 * 1000)/100)
	local _num_3 = math.floor((self.m_basicInfo.last_no - _num_1 * 1000 - _num_2 * 100)/10)
	local _num_4 = math.floor(self.m_basicInfo.last_no  - _num_1 * 1000 - _num_2 * 100 - _num_3 * 10)
	--
	self["label_pre_award_num_1"]:setString(tostring(_num_1))
	self["label_pre_award_num_2"]:setString(tostring(_num_2))
	self["label_pre_award_num_3"]:setString(tostring(_num_3))
	self["label_pre_award_num_4"]:setString(tostring(_num_4))
	--领奖截止时间：%Y年份.%m月份数.%d一个月中的第几天.%x日期(09/16/98).%X时间(23:48:10)。%H。24小时制中的小时数
	local end_time_month = os.date("%m", self.m_basicInfo.bet_end_ts).."/"..os.date("%d", self.m_basicInfo.bet_end_ts)
	local end_time = os.date("%H", self.m_basicInfo.bet_end_ts)..":"..os.date("%M", self.m_basicInfo.bet_end_ts)
	self.label_get_time_month:setString(end_time_month)
	self.label_get_time:setString(end_time)
	--开奖时间
	local open_time = os.date("%m", self.m_basicInfo.lottery_ts)..localizable.ui_lottry_month..os.date("%d", self.m_basicInfo.lottery_ts)..localizable.ui_lottry_day..os.date("%H", self.m_basicInfo.lottery_ts)..localizable.ui_lottry_dian..os.date("%M", self.m_basicInfo.lottery_ts)..localizable.ui_lottry_min
	self.label_open_time:setString(open_time)

	--奖励
	self:set_award_info()
	--数字列表 X 4
	self:createLucky_1_TableView()	
	self:createLucky_2_TableView()	
	self:createLucky_3_TableView()	
	self:createLucky_4_TableView()	
end

function createLucky_1_TableView(self)
	if self._lucky_1_tableView == nil then
		local cellContentSize = self.node_lucky_num_cell:getContentSize()
		self._lucky_cell_size = CCSizeMake(cellContentSize.width,cellContentSize.height)

		self._lucky_1_content_size = self["node_lucky_num_content_1"]:getContentSize()
		self:initLucky_1_TableHandle()
		self._lucky_1_tableView = LuaTableView:createWithHandler(self._lucky_1_tableViewHandler, CCSizeMake(self._lucky_1_content_size.width, self._lucky_1_content_size.height))
		self._lucky_1_tableView:setDirection(kCCScrollViewDirectionVertical)
		self._lucky_1_tableView:setVerticalFillOrder(kCCTableViewFillTopDown)
		self._lucky_1_tableView:setTouchPriority(kCCMenuHandlerPriority - 1)

		self["node_lucky_num_content_1"]:addChild(self._lucky_1_tableView)
		--
		local targetOffsetY = (-9 + 1.25) * self._lucky_cell_size.height
		self._lucky_1_tableView:setContentOffset(0, targetOffsetY)
	else
		self._lucky_1_tableView:reloadData()
	end
end

function initLucky_1_TableHandle(self)
	self._lucky_1_tableViewHandler = LuaEventHandler:create(function(fn, table, a1, a2, x, y)
		local r
		if fn == "cellSize" then
			r = self._lucky_cell_size;
		elseif fn == "cellAtIndex" then
    		local nodeLayer = createObj(ui_lotteryLuckyNumCell, self._lucky_cell_size, self.m_lucky_nums[1][a1 + 1])
			--tableView cell container
			--self.cellNodes[a1+1] = nodeLayer
			if not a2 then
				a2 = CCTableViewCell:create()
				a2:addChild(nodeLayer.node_)
			else
				a2:removeAllChildrenWithCleanup(true)
        		a2:addChild(nodeLayer.node_)
			end
			r = a2
		elseif fn == "numberOfCells" then
			r = #self.m_lucky_nums[1];
		    -- Cell events:
		elseif fn == "cellTouched" then			-- A cell was touched, a1 is cell that be touched. This is not necessary.
			---[[
			local cell_index = a1:getIdx() + 1
			--]]
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

function createLucky_2_TableView(self)
	if self._lucky_2_tableView == nil then
		local cellContentSize = self.node_lucky_num_cell:getContentSize()
		self._lucky_cell_size = CCSizeMake(cellContentSize.width,cellContentSize.height)

		self._lucky_2_content_size = self["node_lucky_num_content_2"]:getContentSize()
		self:initLucky_2_TableHandle()
		self._lucky_2_tableView = LuaTableView:createWithHandler(self._lucky_2_tableViewHandler, CCSizeMake(self._lucky_2_content_size.width, self._lucky_2_content_size.height))
		self._lucky_2_tableView:setDirection(kCCScrollViewDirectionVertical)
		self._lucky_2_tableView:setVerticalFillOrder(kCCTableViewFillTopDown)
		self._lucky_2_tableView:setTouchPriority(kCCMenuHandlerPriority - 1)

		self["node_lucky_num_content_2"]:addChild(self._lucky_2_tableView)
		local targetOffsetY = (-9 + 1.25) * self._lucky_cell_size.height
		self._lucky_2_tableView:setContentOffset(0, targetOffsetY)
	else
		self._lucky_2_tableView:reloadData()
	end
end

function initLucky_2_TableHandle(self)
	self._lucky_2_tableViewHandler = LuaEventHandler:create(function(fn, table, a1, a2, x, y)
		local r
		if fn == "cellSize" then
			r = self._lucky_cell_size;
		elseif fn == "cellAtIndex" then
    		local nodeLayer = createObj(ui_lotteryLuckyNumCell, self._lucky_cell_size, self.m_lucky_nums[2][a1 + 1])
			--tableView cell container
			--self.cellNodes[a1+1] = nodeLayer
			if not a2 then
				a2 = CCTableViewCell:create()
				a2:addChild(nodeLayer.node_)
			else
				a2:removeAllChildrenWithCleanup(true)
        		a2:addChild(nodeLayer.node_)
			end
			r = a2
		elseif fn == "numberOfCells" then
			r = #self.m_lucky_nums[2];
		    -- Cell events:
		elseif fn == "cellTouched" then			-- A cell was touched, a1 is cell that be touched. This is not necessary.
			---[[
			local cell_index = a1:getIdx() + 1
			--]]
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

function createLucky_3_TableView(self)
	if self._lucky_3_tableView == nil then
		local cellContentSize = self.node_lucky_num_cell:getContentSize()
		self._lucky_cell_size = CCSizeMake(cellContentSize.width,cellContentSize.height)

		self._lucky_3_content_size = self["node_lucky_num_content_3"]:getContentSize()
		self:initLucky_3_TableHandle()
		self._lucky_3_tableView = LuaTableView:createWithHandler(self._lucky_3_tableViewHandler, CCSizeMake(self._lucky_3_content_size.width, self._lucky_3_content_size.height))
		self._lucky_3_tableView:setDirection(kCCScrollViewDirectionVertical)
		self._lucky_3_tableView:setVerticalFillOrder(kCCTableViewFillTopDown)
		self._lucky_3_tableView:setTouchPriority(kCCMenuHandlerPriority - 1)

		self["node_lucky_num_content_3"]:addChild(self._lucky_3_tableView)
		local targetOffsetY = (-9 + 1.25) * self._lucky_cell_size.height
		self._lucky_3_tableView:setContentOffset(0, targetOffsetY)
	else
		self._lucky_3_tableView:reloadData()
	end
end

function initLucky_3_TableHandle(self)
	self._lucky_3_tableViewHandler = LuaEventHandler:create(function(fn, table, a1, a2, x, y)
		local r
		if fn == "cellSize" then
			r = self._lucky_cell_size;
		elseif fn == "cellAtIndex" then
    		local nodeLayer = createObj(ui_lotteryLuckyNumCell, self._lucky_cell_size, self.m_lucky_nums[3][a1 + 1])
			--tableView cell container
			--self.cellNodes[a1+1] = nodeLayer
			if not a2 then
				a2 = CCTableViewCell:create()
				a2:addChild(nodeLayer.node_)
			else
				a2:removeAllChildrenWithCleanup(true)
        		a2:addChild(nodeLayer.node_)
			end
			r = a2
		elseif fn == "numberOfCells" then
			r = #self.m_lucky_nums[3];
		    -- Cell events:
		elseif fn == "cellTouched" then			-- A cell was touched, a1 is cell that be touched. This is not necessary.
			---[[
			local cell_index = a1:getIdx() + 1
			--]]
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

function createLucky_4_TableView(self)
	if self._lucky_4_tableView == nil then
		local cellContentSize = self.node_lucky_num_cell:getContentSize()
		self._lucky_cell_size = CCSizeMake(cellContentSize.width,cellContentSize.height)

		self._lucky_4_content_size = self["node_lucky_num_content_4"]:getContentSize()
		self:initLucky_4_TableHandle()
		self._lucky_4_tableView = LuaTableView:createWithHandler(self._lucky_4_tableViewHandler, CCSizeMake(self._lucky_4_content_size.width, self._lucky_4_content_size.height))
		self._lucky_4_tableView:setDirection(kCCScrollViewDirectionVertical)
		self._lucky_4_tableView:setVerticalFillOrder(kCCTableViewFillTopDown)
		self._lucky_4_tableView:setTouchPriority(kCCMenuHandlerPriority - 1)

		self["node_lucky_num_content_4"]:addChild(self._lucky_4_tableView)
		local targetOffsetY = (-9 + 1.25) * self._lucky_cell_size.height
		self._lucky_4_tableView:setContentOffset(0, targetOffsetY)
	else
		self._lucky_4_tableView:reloadData()
	end
end

function initLucky_4_TableHandle(self)
	self._lucky_4_tableViewHandler = LuaEventHandler:create(function(fn, table, a1, a2, x, y)
		local r
		if fn == "cellSize" then
			r = self._lucky_cell_size;
		elseif fn == "cellAtIndex" then
    		local nodeLayer = createObj(ui_lotteryLuckyNumCell, self._lucky_cell_size, self.m_lucky_nums[4][a1 + 1])
			--tableView cell container
			--self.cellNodes[a1+1] = nodeLayer
			if not a2 then
				a2 = CCTableViewCell:create()
				a2:addChild(nodeLayer.node_)
			else
				a2:removeAllChildrenWithCleanup(true)
        		a2:addChild(nodeLayer.node_)
			end
			r = a2
		elseif fn == "numberOfCells" then
			r = #self.m_lucky_nums[4];
		    -- Cell events:
		elseif fn == "cellTouched" then			-- A cell was touched, a1 is cell that be touched. This is not necessary.
			---[[
			local cell_index = a1:getIdx() + 1
			--]]
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

function set_award_info(self)
	--assert
	--init icon
	--[[
	for i=1,3 do --#self.m_awardDatas
		local _icon = self["spr_award_icon_"..tostring(i)]:getChildByTag(100)
		if _icon then
			_icon:removeFromParentAndCleanup(true)
		end

		if i <= #self.m_awardDatas then
			local _t_card = {}
			local _maintype = 0
			local _subtype = 0
			local _id = -1
			local _num = 1
			_maintype, _subtype, _id, _num = setObjTypeInfo(self.m_awardDatas[i][1])
			_t_card.pIcon, _t_card.pFrame, _t_card.quality, _t_card.objname = rl_get_iconsprite(_maintype, _subtype, E_FRAMETYPE_SMALL, _id)
			--frame
			if nil ~= _t_card.pFrame then
				self["spr_award_icon_"..tostring(i)]:setDisplayFrame(_t_card.pFrame)
			end
			--icon
			if nil ~= _t_card.pIcon then
				local size = self["spr_award_icon_"..tostring(i)]:getContentSize()
				self["spr_award_icon_"..tostring(i)]:addChild(_t_card.pIcon)
				_t_card.pIcon:setPosition(ccp(size.width/2, size.height/2))
				_t_card.pIcon:setAnchorPoint(ccp(0.5, 0.5))
				_t_card.pIcon:setTag(100)
			end
		end
	end
	--]]
	--130/038/015
	CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile("props/props_130.plist")
	local frame1 = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("props_130")
	if frame1 ~= nil then
		local pIcon = CCSprite:createWithSpriteFrame(frame1)
		--icon
		if nil ~= pIcon then
			local size = self["spr_award_icon_1"]:getContentSize()
			self["spr_award_icon_1"]:addChild(pIcon)
			pIcon:setPosition(ccp(size.width/2, size.height/2))
			pIcon:setAnchorPoint(ccp(0.5, 0.5))
			pIcon:setTag(100)
		end
	end

	CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile("props/props_015.plist")
	local frame2 = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("props_015")
	if frame2 ~= nil then
		local pIcon = CCSprite:createWithSpriteFrame(frame2)
		--icon
		if nil ~= pIcon then
			local size = self["spr_award_icon_2"]:getContentSize()
			self["spr_award_icon_2"]:addChild(pIcon)
			pIcon:setPosition(ccp(size.width/2, size.height/2))
			pIcon:setAnchorPoint(ccp(0.5, 0.5))
			pIcon:setTag(100)
		end
	end

	CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile("props/props_038.plist")
	local frame3 = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("props_038")
	if frame3 ~= nil then
		local pIcon = CCSprite:createWithSpriteFrame(frame3)
		--icon
		if nil ~= pIcon then
			local size = self["spr_award_icon_3"]:getContentSize()
			self["spr_award_icon_3"]:addChild(pIcon)
			pIcon:setPosition(ccp(size.width/2, size.height/2))
			pIcon:setAnchorPoint(ccp(0.5, 0.5))
			pIcon:setTag(100)
		end
	end
end

function getIntPart(self, x)
    if x <= 0 then
       return 0
    end

    if math.abs(math.ceil(x) - x) < 0.005 then
       x = math.ceil(x)
    else
       x = math.ceil(x) - 1
    end
    return x
end

function init_binding_event(self)
	if self.proxy_ ~= nil then
		--重写相应的触摸函数
		local function onTouchBegan(x, y)
		    self.m_touchBegan = CCPointMake(x,y)
		    self.m_touch_time = os.clock()
			return true
		end

		local function onTouchMoved(x, y)
			if self.m_touchBegan ~= nil then
				self.m_touch_time = os.clock()
			end
		end

		local function onTouchEnded(x, y)
			self.m_touchEnd = ccp(x,y)
			if self.m_touchBegan == nil then
				return nil
			end
			--滑动逻辑			
			if self.m_touchEnd.y ~= self.m_touchBegan.y then
				--获取系统时间。取随机数
				local e_time = os.clock()
				local last_time = e_time - self.m_touch_time
				--防止时间短种子一样..取反取高六位
				math.randomseed(tostring(os.time()):reverse():sub(1, 6))
				local r_num = math.random(4)
				--相应表的操作
				local offset = nil
				if 1 == self.m_touch_index then
					self._lucky_1_tableView:unscheduleAllSelectors()
					offset = self._lucky_1_tableView:getContentOffset()

					self._lucky_1_tableView:reloadData()
					self._lucky_1_tableView:setContentOffset(offset.x, offset.y)
				elseif 2 == self.m_touch_index then
					self._lucky_2_tableView:unscheduleAllSelectors()
					offset = self._lucky_2_tableView:getContentOffset()

					self._lucky_2_tableView:reloadData()
					self._lucky_2_tableView:setContentOffset(offset.x, offset.y)
				elseif 3 == self.m_touch_index then
					self._lucky_3_tableView:unscheduleAllSelectors()
					offset = self._lucky_3_tableView:getContentOffset()

					self._lucky_3_tableView:reloadData()
					self._lucky_3_tableView:setContentOffset(offset.x, offset.y)
				elseif 4 == self.m_touch_index then
					self._lucky_4_tableView:unscheduleAllSelectors()
					offset = self._lucky_4_tableView:getContentOffset()

					self._lucky_4_tableView:reloadData()
					self._lucky_4_tableView:setContentOffset(offset.x, offset.y)
				end
				--当前cell位置
				local cur_1_lucky_num = offset.y / self._lucky_cell_size.height		
				local cur_int, cur_f = math.modf(cur_1_lucky_num)
				--下拉
				cclog("last_time = %s. cur_int = %s", last_time, cur_int)
				if self.m_touchEnd.y - self.m_touchBegan.y < 0 then
					if last_time <= 0.2 then
						cur_int = cur_int - r_num
					else
						cur_int = cur_int - 1
					end				
				else--上翻
					if last_time <= 0.2 then
						cur_int = cur_int + r_num
					end
				end
				--滑动边界
				if cur_int < -9 then
					cur_int = -9
				elseif cur_int > 0 then
					cur_int = 0
				end
				cclog("after pro cur_int = %s", cur_int)
				--记录滑动数字
				self.m_cur_lucky_nums[self.m_touch_index] = cur_int + 9
				--更改offset
				local targetOffsetY = (cur_int + 0.25) * self._lucky_cell_size.height
				--local adjustAnimDelay = 0.5
				if 1 == self.m_touch_index then
					self._lucky_1_tableView:setContentOffsetInDuration(ccp(0, targetOffsetY), 0.25)
				elseif 2 == self.m_touch_index then
					self._lucky_2_tableView:setContentOffsetInDuration(ccp(0, targetOffsetY), 0.25)
				elseif 3 == self.m_touch_index then
					self._lucky_3_tableView:setContentOffsetInDuration(ccp(0, targetOffsetY), 0.25)
				elseif 4 == self.m_touch_index then
					self._lucky_4_tableView:setContentOffsetInDuration(ccp(0, targetOffsetY), 0.25)
				end
			end

			--refresh data
			--self:updateInfo()
			self.m_touchBegan = nil
			self.m_touchEnd = nil
			self.m_touch_time = 0
		end

		local function onBtnPreLuckyList(btn, event)
			--上期中奖名单	
			local view = createObj(ui_lotteryPreWinerListLayer, self, nil)
			GetMainMenu():GetModelLayer():addChild(view.node_)
		end

		local function onBtnMyLuckyNumList(btn, event)
			--投注号码
			local view = createObj(ui_lotteryMyLuckyNumListLayer, self, nil)
			GetMainMenu():GetModelLayer():addChild(view.node_)
		end

		local function onBtnBuyLuckyNum(btn, event)
			--下注号码
			local _my_num_string = tostring(self.m_cur_lucky_nums[1])
			for i = 2, #self.m_cur_lucky_nums do
				_my_num_string = _my_num_string..tostring(self.m_cur_lucky_nums[i])
			end
			cclog("cur_lucky_num = %s", _my_num_string)
			--50元宝下注/检查元宝
			if self.playerData_.m_gold < self.m_basicInfo.cost_cash then
				--提示购买元宝
				GetMainMenu():ShowTextTip(localizable.ui_lottry_gold_not_enough,-1)
				--通用付费引导
				local prePayLayer = createObj(ui_commonPrePay)
				GetMainMenu():GetModelLayer():AddDialog(prePayLayer.node_, 3)
				return nil
			end

			--投注
			---[[
			local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 1, "rl_w_lottery")
			urlpath = AddData(urlpath, "No", tostring(_my_num_string))
			cclog("rl_w_lottery----%s", urlpath)
			GetMainMenu():ShowLoadingDlg()
			CCHttpRequest:open(urlpath, kHttpPost, "query=param1&other=params"):sendWithHandler(
				function(res, hnd)
					GetMainMenu():CloseLoadding();
					local resData = res:getResponseData()
					local code = res:getResponseCode()
					local xfile = xml.parse(resData)
					local item = xfile:find("RENLONG")
					if item ==  nil then
						--cclog("CGI : rl_w_lottery is down!")
						return nil
					end
					local retcode = item.code
					if retcode == "0" then
						--扣除元宝
						self.playerMgr_:AddGold(-self.m_basicInfo.cost_cash)
						self.playerData_ = self.playerMgr_:GetPlayerInfoData()
						--tip
						GetMainMenu():ShowTextTip(localizable.ui_lottry_tips4,-1)								
					else
						GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
					end
				end)
		    --]]
		end

		local function onBtnRandLuckyNum(btn, event)
			--50元宝下注/检查元宝
			if self.playerData_.m_gold < self.m_basicInfo.cost_cash then
				--提示购买元宝
				GetMainMenu():ShowTextTip(localizable.ui_lottry_gold_not_enough,-1)
				--通用付费引导
				local prePayLayer = createObj(ui_commonPrePay)
				GetMainMenu():GetModelLayer():AddDialog(prePayLayer.node_, 3)
				return nil
			end
			--随机4个号码
			--防止时间短种子一样..取反取高六位
			math.randomseed(tostring(os.time()):reverse():sub(1, 6))
			for i=1,4 do
				self.m_cur_lucky_nums[i] = math.random(10) - 1
				--相应表的操作
				local offset = nil
				if 1 == i then
					self._lucky_1_tableView:unscheduleAllSelectors()
					offset = self._lucky_1_tableView:getContentOffset()

					self._lucky_1_tableView:reloadData()
					self._lucky_1_tableView:setContentOffset(offset.x, offset.y)
				elseif 2 == i then
					self._lucky_2_tableView:unscheduleAllSelectors()
					offset = self._lucky_2_tableView:getContentOffset()

					self._lucky_2_tableView:reloadData()
					self._lucky_2_tableView:setContentOffset(offset.x, offset.y)
				elseif 3 == i then
					self._lucky_3_tableView:unscheduleAllSelectors()
					offset = self._lucky_3_tableView:getContentOffset()

					self._lucky_3_tableView:reloadData()
					self._lucky_3_tableView:setContentOffset(offset.x, offset.y)
				elseif 4 == i then
					self._lucky_4_tableView:unscheduleAllSelectors()
					offset = self._lucky_4_tableView:getContentOffset()

					self._lucky_4_tableView:reloadData()
					self._lucky_4_tableView:setContentOffset(offset.x, offset.y)
				end
				--更改offset
				local targetOffsetY = (self.m_cur_lucky_nums[i] - 9 + 0.25) * self._lucky_cell_size.height
				--local adjustAnimDelay = 0.5
				if 1 == i then
					self._lucky_1_tableView:setContentOffsetInDuration(ccp(0, targetOffsetY), 0.5)
				elseif 2 == i then
					self._lucky_2_tableView:setContentOffsetInDuration(ccp(0, targetOffsetY), 0.5)
				elseif 3 == i then
					self._lucky_3_tableView:setContentOffsetInDuration(ccp(0, targetOffsetY), 0.5)
				elseif 4 == i then
					self._lucky_4_tableView:setContentOffsetInDuration(ccp(0, targetOffsetY), 0.5)
				end
			end
			
			local _my_num_string = tostring(self.m_cur_lucky_nums[1])
			for i = 2, #self.m_cur_lucky_nums do
				_my_num_string = _my_num_string..tostring(self.m_cur_lucky_nums[i])
			end
			--开始下注
			local function startBuyRandLuckyNum()
				--投注
				---[[
				local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 1, "rl_w_lottery")
				urlpath = AddData(urlpath, "No", tostring(_my_num_string))
				cclog("rl_w_lottery----%s", urlpath)
				GetMainMenu():ShowLoadingDlg()
				CCHttpRequest:open(urlpath, kHttpPost, "query=param1&other=params"):sendWithHandler(
					function(res, hnd)
						GetMainMenu():CloseLoadding();
						local resData = res:getResponseData()
						local code = res:getResponseCode()
						local xfile = xml.parse(resData)
						local item = xfile:find("RENLONG")
						if item ==  nil then
							--cclog("CGI : rl_w_lottery is down!")
							return nil
						end
						local retcode = item.code
						if retcode == "0" then
							--扣除元宝
							self.playerMgr_:AddGold(-self.m_basicInfo.cost_cash)
							self.playerData_ = self.playerMgr_:GetPlayerInfoData()
							--tip
							GetMainMenu():ShowTextTip(localizable.ui_lottry_tips4,-1)								
						else
							GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
						end
					end)
			    --]]	
			end
			--标准框
			local dlg = CommonDialogView.create()
			CommonDialogView.m_selfview = dlg
			dlg:SetTitle(localizable.ui_lottry_tips5)
			local showContent = string.format(localizable.ui_lottry_tips6, tostring(self.m_basicInfo.cost_cash), tostring(_my_num_string))
			dlg:SetDescription(showContent)
			dlg:loadCCBI()
			dlg:initUI()
			dlg:SetConfirmHandler(startBuyRandLuckyNum)
			GetMainMenu():GetModelLayer():AddDialog(dlg, 1)	
		end

		local function onBtnGetAward(btn, event)
			--领奖
			---[[
			local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 2, "rl_w_lottery")
			cclog("rl_w_lottery----%s", urlpath)

			GetMainMenu():ShowLoadingDlg()
			CCHttpRequest:open(urlpath, kHttpPost, "query=param1&other=params"):sendWithHandler(
				function(res, hnd)
					GetMainMenu():CloseLoadding();
					local resData = res:getResponseData()
					local code = res:getResponseCode()
					local xfile = xml.parse(resData)
					local item = xfile:find("RENLONG")
					if item == nil then
						return nil
					end
					local retcode = item.code
					cclog("resData = %s", resData)
					if retcode == "0" then
						--
						cclog("get award = %s", resData)
						--领奖
						local awardXML = xfile:find("award")
						ShowAward(awardXML)
						GetMainMenu():ShowTextTip(localizable.ui_daily_get_gift_success,-1)
					else
						GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
					end
				end)
			--]]
		end

		--屏蔽掉后层触摸事件
		local function CCLayerTouch(event, x, y)
			local rect = self.node_:boundingBox()
			rect.origin = ccp(0,0)
			local p = self.node_:convertToNodeSpace(ccp(x,y))	
			--截获界面内后层的信息
			if rect:containsPoint(p) ==  true then
				--触摸区域
				local _cur_Node_1 = self["node_lucky_num_content_1"]:boundingBox()		
				local cur_p_1 = self["node_lucky_num_content_1"]:convertToNodeSpace(ccp(x,y))
				_cur_Node_1.origin = ccp(0,0)

				local _cur_Node_2 = self["node_lucky_num_content_2"]:boundingBox()
				local cur_p_2 = self["node_lucky_num_content_2"]:convertToNodeSpace(ccp(x,y))
				_cur_Node_2.origin = ccp(0,0)

				local _cur_Node_3 = self["node_lucky_num_content_3"]:boundingBox()		
				local cur_p_3 = self["node_lucky_num_content_3"]:convertToNodeSpace(ccp(x,y))
				_cur_Node_3.origin = ccp(0,0)

				local _cur_Node_4 = self["node_lucky_num_content_4"]:boundingBox()		
				local cur_p_4 = self["node_lucky_num_content_4"]:convertToNodeSpace(ccp(x,y))
				_cur_Node_4.origin = ccp(0,0)
				--判断触摸的位置
				if event == "began" then
					--判断滑动区域															
					if _cur_Node_1:containsPoint(cur_p_1) == true then	
						self.m_touch_index = 1				
						onTouchBegan(x,y)
					elseif _cur_Node_2:containsPoint(cur_p_2) == true then	
						self.m_touch_index = 2				
						onTouchBegan(x,y)
					elseif _cur_Node_3:containsPoint(cur_p_3) == true then	
						self.m_touch_index = 3				
						onTouchBegan(x,y)
					elseif _cur_Node_4:containsPoint(cur_p_4) == true then	
						self.m_touch_index = 4			
						onTouchBegan(x,y)
					end
					
				 	return true
				elseif event == "moved" then
					return nil--onTouchMoved(x,y)
				else		
					return onTouchEnded(x,y)
				end
			else
				if nil ~= self.m_touchBegan then
					self.m_touchBegan = nil
				end	
				return false
			end		
		end

		self.node_:setTouchEnabled(true)
		self.node_:registerScriptTouchHandler(CCLayerTouch, false, kCCMenuHandlerPriority-1, true)

		--奖励详情
		local function onBtnClickAwardIcon(btn, event)
			CSoundMgr:instance():PlayEffect(SOUND_BUTTON)
			local btnIndex = btn:getTag()
			---[[
			if btnIndex > #self.m_awardDatas then
				return nil
			end

			if btnIndex > 0 and btnIndex <= 3 then
				local _id_icon = tonumber(self.m_awardDatas[btnIndex][1])
				if nil ~= _id_icon then
					CGameObjElement:ShowDropByID(_id_icon)
				end
			end
			--]]
		end

	    --说明
		local function onBtnReadme(btn, event)
			---[[		
			local _descData = {}
			local tempData = {}
			tempData.title = localizable.ui_lottry_tips7
			tempData.isTitle = true
			tempData.desc = localizable.ui_lottry_tips8
			table.insert(_descData, tempData)

			tempData = {}
			tempData.title = localizable.ui_lottry_tips9
			tempData.desc = localizable.ui_lottry_tips10
			tempData.isTitle = false
			table.insert(_descData, tempData)

			tempData = {}
			tempData.title = localizable.ui_lottry_tips11
			tempData.desc = localizable.ui_lottry_tips12
			tempData.isTitle = false
			table.insert(_descData, tempData)

			tempData = {}
			tempData.title = localizable.ui_lottry_tips13
			tempData.desc = localizable.ui_lottry_tips14
			tempData.isTitle = false
			table.insert(_descData, tempData)

			tempData = {}
			tempData.title = localizable.ui_lottry_tips15
			tempData.desc = localizable.ui_lottry_tips16
			tempData.isTitle = false
			table.insert(_descData, tempData)

			tempData = {}
			tempData.title = localizable.ui_lottry_tips17
			tempData.desc = localizable.ui_lottry_tips18
			tempData.isTitle = false
			table.insert(_descData, tempData)

			tempData = {}
			tempData.title = localizable.ui_lottry_tips19
			tempData.desc = localizable.ui_lottry_tips20
			tempData.isTitle = true
			table.insert(_descData, tempData)

			tempData = {}
			tempData.title = localizable.ui_lottry_tips21
			tempData.desc = localizable.ui_lottry_tips22
			tempData.isTitle = false
			table.insert(_descData, tempData)

			tempData = {}
			tempData.title = localizable.ui_lottry_tips23
			tempData.desc = localizable.ui_lottry_tips24
			tempData.isTitle = false
			table.insert(_descData, tempData)

			tempData = {}
			tempData.title = localizable.ui_lottry_tips25
			tempData.desc = localizable.ui_lottry_tips26
			tempData.isTitle = false
			table.insert(_descData, tempData)

			tempData = {}
			tempData.title =localizable.ui_lottry_tips27
			tempData.desc = localizable.ui_lottry_tips28
			tempData.isTitle = false
			table.insert(_descData, tempData)

			tempData = {}
			tempData.title = localizable.ui_lottry_tips29
			tempData.desc = localizable.ui_lottry_tips30
			tempData.isTitle = false
			table.insert(_descData, tempData)

			tempData = {}
			tempData.title = localizable.ui_lottry_tips31
			tempData.desc = localizable.ui_lottry_tips32
			tempData.isTitle = false
			table.insert(_descData, tempData)

			local detailLayer = createObj(ui_lotteryShowDetail, _descData)
			local size1 = GetMainMenu():GetModelLayer():getContentSize()
			detailLayer.node_:setAnchorPoint(ccp(0.5, 0.5))
			detailLayer.node_:setPosition(ccp(size1.width / 2, size1.height * 0.5))
			GetMainMenu():GetModelLayer():addChild(detailLayer.node_)
			--]]
		end

		--奖励详情
		for i=1,3 do
			self["btn_award_icon_"..i]:setTouchPriority(kCCMenuHandlerPriority - 1)
			self["btn_award_icon_"..i]:setTouchEnabled(true)
			self.proxy_:handleButtonEvent(self["btn_award_icon_"..i], function(button, event)
				onBtnClickAwardIcon(button)
				return nil
			end, CCControlEventTouchDown)
		end
		--上期中奖名单
		self.btn_pre_lucky_list:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.btn_pre_lucky_list:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btn_pre_lucky_list, function(button, event)
			onBtnPreLuckyList(button)
			return nil
		end, CCControlEventTouchDown)
		--查看已下注名单
		self.btn_my_num_list:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.btn_my_num_list:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btn_my_num_list, function(button, event)
			onBtnMyLuckyNumList(button)
			return nil
		end, CCControlEventTouchDown)
		--50元宝下注
		self.btn_buy_lucky_num:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.btn_buy_lucky_num:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btn_buy_lucky_num, function(button, event)
			onBtnBuyLuckyNum(button)
			return nil
		end, CCControlEventTouchDown)
		--随机下注
		self.btn_rand_lucky_num:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.btn_rand_lucky_num:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btn_rand_lucky_num, function(button, event)
			onBtnRandLuckyNum(button)
			return nil
		end, CCControlEventTouchDown)
		--领奖
		self.btn_get_award:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.btn_get_award:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btn_get_award, function(button, event)
			onBtnGetAward(button)
			return nil
		end, CCControlEventTouchDown)
		--详情
		self.btn_readme:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.btn_readme:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btn_readme, function(button, event)
			onBtnReadme(button)
			return nil
		end, CCControlEventTouchDown)
	end
end

function onNodeCleanup(self)
	if self.proxy_ then
    	self.proxy_:release()
    end

    layer_base_t.onNodeCleanup(self)
end

--创建测试数据
function createData(self)
	---[[
	for i=1,4 do
		local _t_data = {}
		for i=1,10 do
			local _t_num = {}
			_t_num.num = tonumber(i - 1)
			table.insert(_t_data, _t_num)
		end
		table.insert(self.m_lucky_nums, _t_data)
	end
	--]]
end