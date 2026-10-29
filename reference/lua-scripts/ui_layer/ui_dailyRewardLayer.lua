--descriptioin:daily_reward
--company: xckoo
--litao
--2014.5.12
---------------------------------------------
module("ui_dailyRewardLayer", package.seeall)
baseClass(layer_base_t, ui_dailyRewardLayer)

function init(self, node, data)
	self.contentSize_ = GetMainMenu():GetModelLayer():getContentSize()

	local ccbiAttrTable = {name="sub_ui/DailyRewardView.ccbi", size=self.contentSize_}
	layer_base_t.init(self, true, ccbiAttrTable)

	--用户info
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	--pre info
	self.preNode = node
	--data
	self.cellData = data
	--touch
	self.m_touchPoint = nil

	--create data
	--self:createData()

	--init
	self:init_ui()		
	self:init_binding_event()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		--spr
		self.spr_got = tolua.cast(self.proxy_:getNode("spr_got"), "CCSprite")
		for i=1,4 do
			self["spr_gift_icon_"..i] = tolua.cast(self.proxy_:getNode("sprite_gift_icon_"..i), "CCSprite")
			self["spr_piece_"..i] = tolua.cast(self.proxy_:getNode("spr_piece_"..i), "CCSprite")
		end
		--btn		
		for i=1,4 do
			self["btn_award_"..i] = tolua.cast(self.proxy_:getNode("btn_award_"..i), "CCControlButton")
		end
		self.btn_close = tolua.cast(self.proxy_:getNode("closeButton"), "CCControlButton")
		self.btn_getAward = tolua.cast(self.proxy_:getNode("btn_getAward"), "CCControlButton")
		--label
		for i=1,4 do
			self["label_item_"..i] = tolua.cast(self.proxy_:getNode("label_item_"..i), "CCLabelTTF")
		end
		self.label_title = tolua.cast(self.proxy_:getNode("label_title"), "CCLabelTTF")

		--
		self:init_ext_ui()
	end
end

function init_ext_ui(self)
    --title
    self.label_title:setString(tostring(self.cellData.needscore)..localizable.ui_daily_score_gift)
    --btn set
    if 2 == self.cellData.status then
    	self.btn_getAward:setVisible(false)
    	self.btn_getAward:setEnabled(false)
    	self.spr_got:setVisible(true)
    else
    	self.spr_got:setVisible(false)
    end
	--奖励
	self:set_award_info()
end

function set_award_info(self)
	--init icon
	for i=1,4 do --#self.cellData
		local _icon = self["spr_gift_icon_"..tostring(i)]:getChildByTag(100)
		if _icon then
			_icon:removeFromParentAndCleanup(true)
		end

		if i <= #self.cellData.prop_list then
			local _t_card = {}
			local _maintype = 0
			local _subtype = 0
			local _id = -1
			local _num = 1
			_maintype, _subtype, _id, _num = setObjTypeInfo(self.cellData.prop_list[i][1])
			if tonumber(_maintype) == 5 then
				self["spr_piece_"..i]:setVisible(true)
			else
				self["spr_piece_"..i]:setVisible(false)
			end
			_t_card.pIcon, _t_card.pFrame, _t_card.quality, _t_card.objname = rl_get_iconsprite(_maintype, _subtype, E_FRAMETYPE_SMALL, _id)
			--frame
			if nil ~= _t_card.pFrame then
				self["spr_gift_icon_"..tostring(i)]:setDisplayFrame(_t_card.pFrame)
			end
			--icon
			if nil ~= _t_card.pIcon then
				local size = self["spr_gift_icon_"..tostring(i)]:getContentSize()
				self["spr_gift_icon_"..tostring(i)]:addChild(_t_card.pIcon)
				_t_card.pIcon:setPosition(ccp(size.width/2, size.height/2))
				_t_card.pIcon:setAnchorPoint(ccp(0.5, 0.5))
				_t_card.pIcon:setTag(100)
			end
			--label
			self["label_item_"..i]:setVisible(true)
			self["label_item_"..i]:setString(tostring(_t_card.objname.."*".._num))
		else
			self["label_item_"..i]:setVisible(false)
			self["spr_piece_"..i]:setVisible(false)
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
		local function onBtnClose(btn, event)
			self.node_:removeFromParentAndCleanup(true)
		end

		local function onBtnGetAward(btn, event)
			--rl_r_daily_task
			local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 2, "rl_r_dailytask")
			urlpath = AddData(urlpath, "AwardID", self.cellData.id)
			--cclog("rl_r_daily_task----%s", urlpath)

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
					--cclog("resData = %s", resData)
					if retcode == "0" then
						--
						local awardXML = item:find("award")
						--只加入背包不显示掉落动画		
						AddSoulAwardData(awardXML)
						GetMainMenu():ShowTextTip(localizable.ui_daily_get_gift_success, -1)
						--活动主页面拉取数据
						self.preNode:getTaskData()
						self.node_:removeFromParentAndCleanup(true)
					else
						GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
					end
				end)
			end

		--屏蔽掉后层触摸事件
		local function CCLayerTouch(event, x, y)
			if event == "began" then
				 return true
			else
				return false
			end		
		end

		self.node_:setTouchEnabled(true)
		self.node_:registerScriptTouchHandler(CCLayerTouch, false, kCCMenuHandlerPriority-1, true)

		--奖励详情
		local function onBtnClickAwardIcon(btn)
			CSoundMgr:instance():PlayEffect(SOUND_BUTTON)
			local btnIndex = btn:getTag()

			if btnIndex > #self.cellData.prop_list then
				return nil
			end

			if btnIndex > 0 and btnIndex <= 4 then
				local _id_icon = tonumber(self.cellData.prop_list[btnIndex][1])
				if nil ~= _id_icon then
					CGameObjElement:ShowDropByID(_id_icon)
				end
			end
		end

		for i=1,4 do
			self["btn_award_"..i]:setTouchPriority(kCCMenuHandlerPriority - 1)
			self["btn_award_"..i]:setTouchEnabled(true)
			self.proxy_:handleButtonEvent(self["btn_award_"..i], function(button, event)
				onBtnClickAwardIcon(button)
				return nil
			end, CCControlEventTouchDown)
		end

		self.btn_getAward:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.btn_getAward:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btn_getAward, function(button, event)
			onBtnGetAward(button)
			return nil
		end, CCControlEventTouchDown)

		self.btn_close:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.btn_close:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btn_close, function(button, event)
			onBtnClose(button)
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
	for i=1,5 do
		local tempdata = {}
		tempdata.plan_desc = tostring("plan:等级达到"..i.."级")
		tempdata.isDone = true
		table.insert(self.m_planDatas, tempdata)
	end

	for i=1,7 do
		local spr_t_data = {}
		spr_t_data._index = i
		table.insert(self.m_spr_planDatas, spr_t_data)
	end
	--]]
end