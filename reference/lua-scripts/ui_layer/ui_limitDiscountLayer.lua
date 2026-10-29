--descriptioin:限时特惠
--company: xckoo
--author: litao
--date: 2013-08-14
---------------------------------------------
module("ui_limitDiscountLayer", package.seeall)
baseClass(layer_base_t, ui_limitDiscountLayer)

function init(self, node)
	self.contentNode_ = GetActivityView():GetNodeContent()
	self.contentSize_ = self.contentNode_:getContentSize()

	local ccbiAttrTable = {name="activity/LimitDiscountView.ccbi", size=self.contentSize_}
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

	self:init_ui()
	self:init_binding_event()
end

function init_ui(self)
	--初始化界面信息
	if self.proxy_ ~= nil then
		--label
		self.label_pay_low = tolua.cast(self.proxy_:getNode("label_pay_low"), "CCLabelBMFont")
		self.label_gift_price = tolua.cast(self.proxy_:getNode("label_gift_price"), "CCLabelBMFont")
		self.label_time = tolua.cast(self.proxy_:getNode("label_time"), "CCLabelTTF")
		for i=1,4 do
			self["label_item_name"..tostring(i)] = tolua.cast(self.proxy_:getNode("label_item_name"..tostring(i)), "CCLabelTTF") 
		end
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
		--request base info
		self:startRequestBaseInfo(false)	
	end
end

function startRequestBaseInfo(self)
	local function updateLeftTimeLabel(fDeltaTime)
		self.deltatime = self.deltatime + fDeltaTime
		if self.deltatime >= 1 then
			local intPart, floatPart = math.modf(self.deltatime)
			self.restTime = self.restTime - intPart
			if self.restTime > 0 then
				local timeStr = tools.convertTimeElectronicWatch(self.restTime, 3)
				self.label_time:setString(timeStr)
				self.deltatime = floatPart
			else
				self.m_state = 1
				self.label_time:setString(localizable.ui_monopoly_end)
				self.label_time:unscheduleUpdate()
			end
		end
	end
	--请求基本信息
	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 9004, "rl_r_activity")
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
					self.pay_low = tonumber(_basic.mincash)
					self.restTime = tonumber(_basic.resttime)
					self.gift_price = tonumber(_basic.maxval)

					if self.restTime > 0 then
						self.label_time:scheduleUpdateWithPriorityLua(updateLeftTimeLabel, 0)
						self.label_time:setString(tools.convertTimeElectronicWatch(self.restTime, 3))
					else
						self.m_state = 1
						self.label_time:setString(localizable.ui_monopoly_end)
					end
				end

				--award list
				local _award = item:find("award")
				if _award then
					self.get_state = tonumber(_award.state)
					for i=1,#_award do
						local _award_item = {}
						_award_item.id = tonumber(_award[i].drop)
						_award_item.icon = tostring(_award[i].icon)
						_award_item.name = _award[i].name
						table.insert(self.award_datas, _award_item)
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
	if self.get_state == 0 then
		self.btn_pay:setTouchEnabled(true)
		self.btn_pay:setVisible(true)
		self.btn_get:setTouchEnabled(false)
		self.btn_get:setVisible(false)
		self.spr_hasgot:setVisible(false)
	elseif self.get_state == 1 then
		self.btn_pay:setTouchEnabled(false)
		self.btn_pay:setVisible(false)
		self.btn_get:setTouchEnabled(true)
		self.btn_get:setVisible(true)
		self.spr_hasgot:setVisible(false)
	elseif self.get_state == 2 then
		self.btn_pay:setTouchEnabled(false)
		self.btn_pay:setVisible(false)
		self.btn_get:setTouchEnabled(false)
		self.btn_get:setVisible(false)
		self.spr_hasgot:setVisible(true)
	end

	self.label_pay_low:setString(self.pay_low)
	self.label_gift_price:setString(self.gift_price)

	---[[
	for i=1,4 do
        self["btn_item_"..tostring(i)]:setOpacity(0)
		local _icon = self["spr_item"..tostring(i)]:getChildByTag(99)
		if _icon then
			_icon:removeFromParentAndCleanup(true)
		end

		if i <= #self.award_datas then
			--icon/frame
			local _maintype = 0
			local _subtype = 0
			local _id = -1
			local _num = -1
			local _drop_type = 0
			local _obj_info = {}
			_maintype, _subtype, _id, _num, _drop_type = setObjTypeInfo(tonumber(self.award_datas[i].id))
			_obj_info.pIcon, _obj_info.pFrame, _obj_info.quality, _obj_info.objname = rl_get_iconsprite(_maintype, _subtype, E_FRAMETYPE_SMALL, _id)
			if nil ~= _obj_info.pFrame then
				self["spr_item"..tostring(i)]:setDisplayFrame(_obj_info.pFrame)
			end
			--合集icon用发过来的,防止集合出现问题
			if _drop_type == 1 then	
				local pathName = "props/"..self.award_datas[i].icon..".plist"
				CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile(pathName)
				local frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(self.award_datas[i].icon)
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
			self["label_item_name"..tostring(i)]:setString(tostring(self.award_datas[i].name))
		else
			local pFrameNoGiftBK = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("small_no_obj_frame")
			self["spr_item"..tostring(i)]:setDisplayFrame(pFrameNoGiftBK)
			self["label_item_name"..tostring(i)]:setVisible(false)
		end		
	end	
	--]]
end

function updateUI(self)
	if self.get_state == 0 then
		self.btn_pay:setTouchEnabled(true)
		self.btn_pay:setVisible(true)
		self.btn_get:setTouchEnabled(false)
		self.btn_get:setVisible(false)
		self.spr_hasgot:setVisible(false)
	elseif self.get_state == 1 then
		self.btn_pay:setTouchEnabled(false)
		self.btn_pay:setVisible(false)
		self.btn_get:setTouchEnabled(true)
		self.btn_get:setVisible(true)
		self.spr_hasgot:setVisible(false)
	elseif self.get_state == 2 then
		self.btn_pay:setTouchEnabled(false)
		self.btn_pay:setVisible(false)
		self.btn_get:setTouchEnabled(false)
		self.btn_get:setVisible(false)
		self.spr_hasgot:setVisible(true)
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
			urlpath = AddData(urlpath, "ActType", 10)
			cclog("rl_w_activity & cmd = 9100 & actType = 10---%s", urlpath)
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
						self.get_state = 2						
						--update
						self:updateUI()
					else
						GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
					end
				end)			
		end

		local function onBtnPay(btn, event)
			--前往充值
			--[[
			local puchaseLayer = createObj(ui_purchaseLayer)
			GetMainMenu():GetModelLayer():AddDialog(puchaseLayer.node_, 3)
			--]]
			GetMainMenu():ChangeToSub(E_STOREITEMSVIEW)
		end

		--奖励详情
		local function onBtnClickAwardIcon(btn)
			local btnIndex = btn:getTag()

			if btnIndex > #self.award_datas then
				return nil
			end

			if btnIndex > 0 and btnIndex <= 4 then
				local _id_icon = tonumber(self.award_datas[btnIndex].id)
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

function onNodeCleanup(self)
	if self.proxy_ then
    	self.proxy_:release()
    end
    layer_base_t.onNodeCleanup(self)
end

--testData
function createTestData(self)
	--
end