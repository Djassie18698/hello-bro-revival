--descriptioin:连续充值(正版上线活动)
--company: xckoo
--litao
--2014.8.12
---------------------------------------------
require("config/firstpurchase_config")
require("ui_layer/ui_purchaseLayer")
require("ui_layer/ui_purchaseTableCell")

module("ui_keepPayLayer", package.seeall)
baseClass(layer_base_t, ui_keepPayLayer)

function init(self, node)
	self.contentNode_ = GetActivityView():GetNodeContent()
	self.contentSize_ = self.contentNode_:getContentSize()

	local ccbiAttrTable = {name="activity/KeepPayView.ccbi", size=self.contentSize_}
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
	self.ext_award_datas = {}
	--tableView cell container
	self.cellNodes = {}
	--touch
	self.m_touchPoint = nil

	self:init_ui()
	self:init_binding_event()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		--label
		self.label_pay_days = tolua.cast(self.proxy_:getNode("label_pay_days"), "CCLabelBMFont")
		self.label_act_time = tolua.cast(self.proxy_:getNode("label_act_time"), "CCLabelTTF")
		for i=1,4 do
			self["label_item_name"..tostring(i)] = tolua.cast(self.proxy_:getNode("label_item_name"..tostring(i)), "CCLabelTTF") 
		end
		--node
		self.node_content = tolua.cast(self.proxy_:getNode("node_content"), "CCNode")
		self.node_cell = tolua.cast(self.proxy_:getNode("node_cell"), "CCNode")
		--btn
		self.btn_get = tolua.cast(self.proxy_:getNode("btn_get"), "CCControlButton")
		self.btn_pay = tolua.cast(self.proxy_:getNode("btn_pay"), "CCControlButton")
		for i=1,4 do
			self["btn_item_"..tostring(i)] = tolua.cast(self.proxy_:getNode("btn_item_"..tostring(i)), "CCControlButton") 
		end
		--spr
		self.spr_hasgot = tolua.cast(self.proxy_:getNode("sprite_hasgot"), "CCSprite")
		for i=1,4 do
			self["spr_item"..tostring(i)] = tolua.cast(self.proxy_:getNode("sprite_item"..tostring(i)), "CCSprite") 
		end

		--init
		self:pre_base_info()
	end
end

function pre_base_info(self)
	local function updateLeftTimeLabel(fDeltaTime)
		self.deltatime = self.deltatime + fDeltaTime
		if self.deltatime >= 1 then
			local intPart, floatPart = math.modf(self.deltatime)
			self.restTime = self.restTime - intPart
			if self.restTime > 0 then
				local timeStr = tools.convertTimeElectronicWatchHaveDay(self.restTime, 3)
				self.label_act_time:setString(timeStr)
				self.deltatime = floatPart
			else
				self.m_state = 1
				self.label_act_time:setString(localizable.ui_monopoly_end)
				self.label_act_time:unscheduleUpdate()
			end
		end
	end
	--请求基本信息
	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 9003, "rl_r_activity")
	--cclog("rl_r_activity & cmd = 9003---%s", urlpath)
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
				--basic
				local _basic = item:find("preview")
				if _basic then
					self.keepPayDays = tonumber(_basic.days)
					self.restTime = tonumber(_basic.resttime)

					if self.restTime > 0 then
						self.label_act_time:scheduleUpdateWithPriorityLua(updateLeftTimeLabel, 0)
						self.label_act_time:setString(tools.convertTimeElectronicWatchHaveDay(self.restTime, 3))
					else
						self.m_state = 1
						self.label_act_time:setString(localizable.ui_monopoly_end)
					end
				end

				--award list
				local _award = item:find("awardlist")
				if _award then
					for i=1,#_award do
						local _award_item = {}
						_award_item.index = tonumber(_award[i].id)
						_award_item.has_got = tonumber(_award[i].state)
						_award_item.award_datas = _award[i]:find("award")
						table.insert(self.award_datas, _award_item)
					end
				end

				--ext award list
				local _ext_award = item:find("ext_award")
				
				if _ext_award then
					self.specialState = tonumber(_ext_award.state)
				end
				for i=1,#_ext_award do
					local _award_item = {}
					_award_item.id = tonumber(_ext_award[i].drop)
					_award_item.icon = tostring(_ext_award[i].icon)
					_award_item.name = tostring(_ext_award[i].name)
					table.insert(self.ext_award_datas, _award_item)
				end
													
				--update
				self:init_ui_ext()
			else
				GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
			end
		end)
end

function updateUI_ext(self)
    if self.specialState == 0 then
		self.btn_pay:setTouchEnabled(true)
		self.btn_pay:setVisible(true)
		self.btn_get:setTouchEnabled(false)
		self.btn_get:setVisible(false)
		self.spr_hasgot:setVisible(false)
	elseif self.specialState == 1 then
		self.btn_pay:setTouchEnabled(false)
		self.btn_pay:setVisible(false)
		self.btn_get:setTouchEnabled(true)
		self.btn_get:setVisible(true)
		self.spr_hasgot:setVisible(false)
	elseif self.specialState == 2 then
		self.btn_pay:setTouchEnabled(false)
		self.btn_pay:setVisible(false)
		self.btn_get:setTouchEnabled(false)
		self.btn_get:setVisible(false)
		self.spr_hasgot:setVisible(true)
	end
end

function ext_award_init(self)
    self:updateUI_ext()
	---[[
	for i=1,4 do
        self["btn_item_"..tostring(i)]:setOpacity(0)
		local _icon = self["spr_item"..tostring(i)]:getChildByTag(99)
		if _icon then
			_icon:removeFromParentAndCleanup(true)
		end

		if i <= #self.ext_award_datas then
			--icon/frame
			local _maintype = 0
			local _subtype = 0
			local _id = -1
			local _num = -1
			local _drop_type = 0
			local _obj_info = {}
			_maintype, _subtype, _id, _num, _drop_type = setObjTypeInfo(tonumber(self.ext_award_datas[i].id))
			_obj_info.pIcon, _obj_info.pFrame, _obj_info.quality, _obj_info.objname = rl_get_iconsprite(_maintype, _subtype, E_FRAMETYPE_SMALL, _id)
			if nil ~= _obj_info.pFrame then
				self["spr_item"..tostring(i)]:setDisplayFrame(_obj_info.pFrame)
			end
			--合集icon用发过来的,防止集合出现问题
			if _drop_type == 1 then	
				local pathName = "props/"..self.ext_award_datas[i].icon..".plist"
				CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile(pathName)
				local frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(self.ext_award_datas[i].icon)
				if frame ~= nil then
					_obj_info.pIcon = CCSprite:createWithSpriteFrame(frame)
				end
			end
			if nil ~= _obj_info.pIcon then
				self["spr_item"..tostring(i)]:addChild(_obj_info.pIcon)
				local size = self["spr_item"..tostring(i)]:getContentSize()
				_obj_info.pIcon:setPosition(ccp(size.width * 0.5, size.height * 0.5))
				_obj_info.pIcon:setAnchorPoint(ccp(0.5, 0.5))
				_obj_info.pIcon:setTag(99)
				if _drop_type ~= 1 then
					_obj_info.pIcon:setScale(1.0)
				end
			end

			self["label_item_name"..tostring(i)]:setVisible(true)
			self["label_item_name"..tostring(i)]:setString(tostring(self.ext_award_datas[i].name))
		else
			local pFrameNoGiftBK = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("small_no_obj_frame")
			self["spr_item"..tostring(i)]:setDisplayFrame(pFrameNoGiftBK)
			self["label_item_name"..tostring(i)]:setVisible(false)
		end		
	end	
	--]]
end

function init_ui_ext(self)
	self.label_pay_days:setString(tostring(self.keepPayDays))

	self:ext_award_init()

	---[[
	self:creatTabelView()
	--]]
end

function creatTabelView(self)
	-- body
	if self._tableView == nil then
		local cellContentSize = self.node_cell:getContentSize()
		self.cell_size = CCSizeMake(cellContentSize.width,cellContentSize.height)

		self.content_size = self.node_content:getContentSize()
		self:initTableHandle()
		self._tableView = LuaTableView:createWithHandler(self._tableViewHandler, CCSizeMake(self.content_size.width, self.content_size.height))
		self._tableView:setDirection(kCCScrollViewDirectionVertical)
		self._tableView:setVerticalFillOrder(kCCTableViewFillTopDown)
		self._tableView:setTouchPriority(kCCMenuHandlerPriority - 1)

		self.node_content:addChild(self._tableView)

		if self.keepPayDays > 1 and self.keepPayDays < 7 then
			local targetOffsetY = (-6 + self.keepPayDays) * self.cell_size.height
			self._tableView:setContentOffset(0, targetOffsetY)
        elseif self.keepPayDays >= 7 then
            local targetOffsetY = (-6 + 7) * self.cell_size.height
			self._tableView:setContentOffset(0, targetOffsetY)
		end
		
	else
		self._tableView:reloadData()
	end
end

function initTableHandle(self)
	self._tableViewHandler = LuaEventHandler:create(function(fn, table, a1, a2, x, y)
		local r
		if fn == "cellSize" then
			r = self.cell_size;
		elseif fn == "cellAtIndex" then
    		local nodeLayer = createObj(ui_keepPayCell, self.cell_size, self.award_datas[a1 + 1], self.keepPayDays)
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
            ---[[
			local cell_index = a1:getIdx() + 1
			local _layer = self.cellNodes[cell_index]

			if _layer.spr_get:boundingBox():containsPoint(self.m_touchPoint) and self.award_datas[cell_index].has_got == 1 then
					self:GetAward(cell_index)
			elseif _layer.spr_pay:boundingBox():containsPoint(self.m_touchPoint) and self.award_datas[cell_index].has_got == 0 then
				local targetDays = 0
				if self.keepPayDays == 7 then
					targetDays = 7
				else
					targetDays = self.keepPayDays + 1
				end
				if cell_index == targetDays then
					--前往充值
					--[[
					local puchaseLayer = createObj(ui_purchaseLayer)
					GetMainMenu():GetModelLayer():AddDialog(puchaseLayer.node_, 3)
					--]]
					GetMainMenu():ChangeToSub(E_STOREITEMSVIEW)
				end
			end

			_layer.spr_get:setScale(1.0)
			_layer.spr_pay:setScale(1.0)
			self.m_touchPoint = nil
			--]]
		elseif fn == "cellTouchBegan" then		-- A cell is touching, a1 is cell, a2 is CCTouch
			self.m_touchPoint = a2:getLocation()
			self.m_touchPoint = a1:convertToNodeSpace(self.m_touchPoint)

			local cell_index = a1:getIdx() + 1

			local _layer = self.cellNodes[cell_index]

			if _layer.spr_get:boundingBox():containsPoint(self.m_touchPoint) then
				_layer.spr_get:setScale(1.1)
			elseif _layer.spr_pay:boundingBox():containsPoint(self.m_touchPoint) then
				_layer.spr_pay:setScale(1.1)
			end

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
	--请求信息
	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 9100, "rl_w_activity")
	urlpath = AddData(urlpath, "ActType", 9)
	urlpath = AddData(urlpath, "ActID", 1)
	cclog("rl_w_activity & cmd = 9100---%s", urlpath)
	GetMainMenu():ShowLoadingDlg()
	CCHttpRequest:open(urlpath, kHttpPost, "query=param1&other=params"):sendWithHandler(
		function(res, hnd)
			GetMainMenu():CloseLoadding()
			local resData = res:getResponseData()
			cclog("%s", resData)
			local code = res:getResponseCode()
			local xfile = xml.parse(resData)
			local item = xfile:find("RENLONG")
			if item == nil then
				return nil
			end
			local retcode = item.code
			if retcode == "0" then	
				local awardXML = item:find("award")
				--显示掉落动画	
				ShowAward(awardXML)	
				GetMainMenu():ShowTextTip(localizable.ui_daily_get_gift_success, -1)
				--标志
				self.award_datas[index].has_got = 2						
				--update
				self:updateUI()
			else
				GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
			end
		end)
end

function updateUI(self)
	self._tableView:reloadData()

	if self.keepPayDays > 1 and self.keepPayDays < 7 then
        local targetOffsetY = (-6 + self.keepPayDays) * self.cell_size.height
        self._tableView:setContentOffset(0, targetOffsetY)
    elseif self.keepPayDays >= 7 then
        local targetOffsetY = (-6 + 7) * self.cell_size.height
        self._tableView:setContentOffset(0, targetOffsetY)
    end
end

function init_binding_event(self)
	if self.proxy_ ~= nil then
		local function onBtnGet(btn, event)
			--活动已经结束
			if self.m_state == 1 then
				GetMainMenu():ShowTextTip(localizable.ui_monopoly_end, -1)
				return nil
			end
			--请求信息
			local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 9100, "rl_w_activity")
			urlpath = AddData(urlpath, "ActType", 9)
			urlpath = AddData(urlpath, "ActID", 2)
			cclog("rl_w_activity & cmd = 9100 & actType = 9---%s", urlpath)
			GetMainMenu():ShowLoadingDlg()
			CCHttpRequest:open(urlpath, kHttpPost, "query=param1&other=params"):sendWithHandler(
				function(res, hnd)
					GetMainMenu():CloseLoadding()
					local resData = res:getResponseData()
					cclog("%s", resData)
					local code = res:getResponseCode()
					local xfile = xml.parse(resData)
					local item = xfile:find("RENLONG")
					if item == nil then
						return nil
					end
					local retcode = item.code
					if retcode == "0" then	
						local awardXML = item:find("award")
						--显示掉落动画	
						ShowAward(awardXML)	
						GetMainMenu():ShowTextTip(localizable.ui_daily_get_gift_success, -1)
						--标志
						self.specialState = 2						
						--update
						self:updateUI_ext()
					else
						GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
					end
				end)			
		end

		local function onBtnPay(btn, event)
			--前往充值
			---[[
			local puchaseLayer = createObj(ui_purchaseLayer, self)
			GetMainMenu():GetModelLayer():AddDialog(puchaseLayer.node_, 3)
			--]]
			--GetMainMenu():ChangeToSub(E_STOREITEMSVIEW)
		end

		--奖励详情
		local function onBtnClickAwardIcon(btn)
			local btnIndex = btn:getTag()

			if btnIndex > #self.ext_award_datas then
				return nil
			end

			if btnIndex > 0 and btnIndex <= 4 then
				local _id_icon = tonumber(self.ext_award_datas[btnIndex].id)
				if nil ~= _id_icon then
					CGameObjElement:ShowDropByID(_id_icon)
				end
			end
		end

		for i=1,4 do
			self["btn_item_"..i]:setTouchPriority(kCCMenuHandlerPriority - 1)
			self["btn_item_"..i]:setTouchEnabled(true)
			self.proxy_:handleButtonEvent(self["btn_item_"..i], function(button, event)
				onBtnClickAwardIcon(button)
				return nil
			end, CCControlEventTouchDown)
		end

		self.btn_get:setTouchPriority(kCCMenuHandlerPriority-1)
		self.btn_get:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btn_get, function(button, event)
			onBtnGet(button)
			return nil
		end, CCControlEventTouchDown)

		self.btn_pay:setTouchPriority(kCCMenuHandlerPriority-1)
		self.btn_pay:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btn_pay, function(button, event)
			onBtnPay(button)
			return nil
		end, CCControlEventTouchDown)
	end
end

function refreshData(self)
	self:pre_base_info()
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