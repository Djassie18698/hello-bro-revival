--descriptioin:刮刮乐活动（重写）
--company: xckoo
--author: chenchun
--date: 2013-12-17
---------------------------------------------
module("ui_scratchCardLayer", package.seeall)
baseClass(layer_base_t, ui_scratchCardLayer)

pressTag = nil
function init(self)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	self.contentNode_ = GetActivityView():GetNodeContent()
	self.contentSize_ = self.contentNode_:getContentSize()

	local ccbiAttrTable = {name="activity/ScratchCard.ccbi", size=self.contentSize_}
	layer_base_t.init(self, true, ccbiAttrTable)

	--self:createTestData()
	self.isGot = false
	self.freeNum = 0
	self.cangotcash = 0
	self.costGold = 20
	self.scratchData = {}
	self.isCostGold = false
	self.btns = {}
	self.tipsDlgView = nil
	self.disapper = nil
	self.numClick = 0
	self.usercash = self.playerData_.m_gold

	self.isTips = false
	ui_scratchCardLayer.pressTag = nil
	self:init_ui()
end

--完成以后，如果获得奖励，将播放动画
function loadFinishAnimation(self)
	local win = CCDirector:sharedDirector():getWinSize()
    local finishLayer = createObj(ui_scratchGoldAnimation, self.cangotcash)
	finishLayer.node_:setAnchorPoint(ccp(0.5, 0.5))
	finishLayer.node_:setPosition(win.width / 2, win.height / 2)
	finishLayer.node_:ignoreAnchorPointForPosition(false)
	finishLayer.node_:setTouchEnabled(true)
	local function stopAnimation()
		if self.disappear ~= nil then
		 	CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.disappear)
         	self.disappear = nil
         	ui_scratchCardLayer.pressTag = nil
         	finishLayer.node_:removeFromParentAndCleanup(true)
		end
	end
	finishLayer.node_:registerScriptTouchHandler(stopAnimation,false,kCCMenuHandlerPriority-1,true)
	finishLayer.node_:setTouchMode(0)

	local function animationFinished()
		if self.disappear ~= nil then
		 	CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.disappear)
         	self.disappear = nil
         	ui_scratchCardLayer.pressTag = nil
         	finishLayer.node_:removeFromParentAndCleanup(true)
		end
	end
	self.disappear = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(animationFinished, 4, false)
	GetMainMenu():GetModelLayer():addChild(finishLayer.node_)
end

function initCard(self)
	local function onBtnDown(btn)
		ui_scratchCardLayer.pressTag = btn:getTag()
        --[[
        if self.btns[ui_scratchCardLayer.pressTag] == 1 then
            ui_scratchCardLayer.pressTag = btn:getTag()
        end
        ]]
        --cclog("1111---tag:%d, %d, %s ",ui_scratchCardLayer.pressTag,btn:getTag(),tostring(self.btns[ui_scratchCardLayer.pressTag]))
	end
	local function onBtnClick(btn)
		local tag = btn:getTag()
		if self.numClick == 9 then
			for m = 1, 9 do
				local item = tolua.cast(self.proxy_:getNode("ctrl_big_bk_" .. tostring(m)), "CCControlButton")
				local pFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("activity_02_28")
				item:setBackgroundSpriteFrameForState(pFrame, 1)
				item:setBackgroundSpriteFrameForState(pFrame, 2)
				local lblFont = tolua.cast(self.proxy_:getNode("label_gift_gold_" .. tostring(m)), "CCLabelBMFont")
				lblFont:setVisible(false)
				tolua.cast(self.proxy_:getNode("sprite_gold_" .. tostring(m)), "CCSprite"):setVisible(false)
				local sprite_bk = tolua.cast(self.proxy_:getNode("sprite_gift_bk_" .. tostring(m)), "CCSprite")
				sprite_bk:removeAllChildrenWithCleanup(true)
				sprite_bk:setVisible(false)
				self.btns[m] = false
			end
			self.isGot = false
			ui_scratchCardLayer.pressTag = nil
			self.numClick = 0
			return
		end
		if self.playerData_.m_level < 10 then
			GetMainMenu():ShowTextTip(localizable.ui_not_enough_level, -1)
			return
		end
        if ui_scratchCardLayer.pressTag == tag then
			if self.freeNum > 0 or self.isGot then
				if not self.isGot then
					self:getCardInfo(btn)
				end
				if self.isGot then
					self:updateCardInfo(btn)
				end
			else
				local function callBack()
					self.isCostGold = true
					self.tipsDlgView = nil
					self:getCardInfo(btn)
					self.isTips = false
				end
				local function touchCallBack()
					self.tipsDlgView = nil
					self.isTips = false
				end
				if not self.isCostGold then
					if not self.isTips then
						if self.tipsDlgView == nil then
							self.tipsDlgView = createObj(ui_scratchTipLayer, callBack, touchCallBack);
						end
						GetMainMenu():GetModelLayer():addChild(self.tipsDlgView.node_)
						self.isTips = true
					end
				else
					self:getCardInfo(btn)
				end
			end
			ui_scratchCardLayer.pressTag = nil
		end
	end
	-- 初始化按钮
	tolua.cast(self.proxy_:getNode("label_free_num"), "CCLabelBMFont"):setString(tostring(self.freeNum))
	for i = 1, 9 do
		local item = tolua.cast(self.proxy_:getNode("ctrl_big_bk_" .. tostring(i)), "CCControlButton")
		item:setTag(i)

		self.proxy_:handleButtonEvent(item, function(button, event)
			onBtnClick(button)
			return nil
		end, CCControlEventTouchUpInside)

		self.proxy_:handleButtonEvent(item, function(button, event)
			onBtnDown(button)
			return nil
		end, CCControlEventTouchDown)
	end
end

function init_ui(self)
	if self.proxy_ ~= nil then
		tolua.cast(self.proxy_:getNode("label_free_num"), "CCLabelBMFont"):setString(tostring(0))
		tolua.cast(self.proxy_:getNode("label_gold_num"), "CCLabelBMFont"):setString(tostring(self.usercash))

		local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 1700, "rl_w_guaguale")
		--urlpath = "http://203.195.181.162:8080/rl_w_guaguale?Cmd=1701&Uid=80021&Session=962954F5D722633016FF458E22920C29&Clinettime=2013/10/22%2021:56:17%20Tuesday&Platform=win32&Version=1.0.0&Pt=3&Area=2"
		GetMainMenu():ShowLoadingDlg();
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
				if retcode == "0" then
					self.freeNum = tonumber(item.free)
					self:initCard()
				end
			end)
	end
end

--更新翻开卡片以后，更新卡片信息
function updateCardInfo(self, btn)
	local tag = btn:getTag()
    ui_scratchCardLayer.pressTag = nil
	if not self.btns[tag] then
		local item = tolua.cast(self.proxy_:getNode("ctrl_big_bk_" .. tostring(tag)), "CCControlButton")
		local pFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("activity_25")
		if pFrame == nil then
			local pathName = "ccbResources/activity.plist"
			CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile(pathName)
			pFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("activity_25")
		end
		item:setBackgroundSpriteFrameForState(pFrame, 1)
		item:setBackgroundSpriteFrameForState(pFrame, 2)
		local lblFont = tolua.cast(self.proxy_:getNode("label_gift_gold_" .. tostring(tag)), "CCLabelBMFont")
		lblFont:setString(self.scratchData[tag].cash)
		lblFont:setVisible(true)
		 tolua.cast(self.proxy_:getNode("sprite_gold_" .. tostring(tag)), "CCSprite"):setVisible(true)
		local sprite_bk = tolua.cast(self.proxy_:getNode("sprite_gift_bk_" .. tostring(tag)), "CCSprite")
		local pathName = "icon/"..self.scratchData[tag].icon..".plist"
		CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile(pathName)
		local sprite_icon = CCSprite:createWithSpriteFrameName(self.scratchData[tag].icon)
		local contentSize = sprite_bk:getContentSize()
		sprite_icon:setAnchorPoint(ccp(0.5, 0.5))
		sprite_icon:setPosition(contentSize.width / 2, contentSize.height / 2)
		sprite_bk:addChild(sprite_icon)
		sprite_bk:setVisible(true)
		self.btns[tag] = 1
		self.numClick = self.numClick + 1

	end

	-- 如果次数达到9次，且获得的元宝数大于0，则更新相关label 状态
	if self.numClick == 9 and self.cangotcash > 0 then
		self:loadFinishAnimation()
		tolua.cast(self.proxy_:getNode("label_gold_num"), "CCLabelBMFont"):setString(tostring(self.usercash))
	elseif self.numClick == 9 then
		GetMainMenu():ShowTextTip(localizable.ui_scratch_go_on_tips, -1)
		tolua.cast(self.proxy_:getNode("label_gold_num"), "CCLabelBMFont"):setString(tostring(self.usercash))
	end
end

--获取相关9张卡片的信息
function getCardInfo(self, btn)
		local urlpath = GetUrlNormalHeader(self.playerData_.m_uid,1701,"rl_w_guaguale")
		if self.usercash >= self.costGold or self.freeNum > 0 then
			GetMainMenu():ShowLoadingDlg()	-- 获取信息的时候，不允许操作
			--urlpath = "http://203.195.181.162:8080/rl_w_guaguale?Cmd=1701&Uid=80021&Session=962954F5D722633016FF458E22920C29&Clinettime=2013/10/22%2021:56:17%20Tuesday&Platform=win32&Version=1.0.0&Pt=3&Area=2"
			CCHttpRequest:open(urlpath, kHttpPost, "query=param1&other=params"):sendWithHandler(
				function(res, hnd)
					GetMainMenu():CloseLoadding(); --获取信息完成时，解除禁止操作
					local resData = res:getResponseData()
					local code = res:getResponseCode()
					local xfile = xml.parse(resData)
					local item = xfile:find("RENLONG")
					if item == nil then
						return nil
					end
					local retcode = item.code
					if retcode == "0" then
						local tmpUserCash = self.usercash - self.costGold
						if self.freeNum > 0 then
							self.freeNum = self.freeNum - 1
							tolua.cast(self.proxy_:getNode("label_free_num"), "CCLabelBMFont"):setString(tostring(self.freeNum))
							tmpUserCash = self.usercash
						end

						self.usercash = tonumber(item.usercash)
						self.cangotcash = tonumber(item[1].cash)
						self.playerMgr_:SetGold(self.usercash)
						self.scratchData = {}
						local tempRec = {}
						local tempCash = 0
		                for i =1, 9 do
		                	self.scratchData[i] = {id=item[2][i][1][1], cash=item[2][i][2][1], icon=item[2][i][3][1]}
		                	--self.scratchData[i] = {id=item[2][i][1][1], cash=item[2][i][2][1], icon="activity_props_01"}
		                	if tempRec[item[2][i][2][1]] then
		                		tempRec[item[2][i][2][1]] = tempRec[item[2][i][2][1]] + 1
		                	else
		                		tempRec[item[2][i][2][1]] = 1
		                	end
		                end
		                for k, v in pairs(tempRec) do
		                	if v >= 3 then
		                		tempCash = tempCash + tonumber(k)
		                	end
		                end
		                if tempCash ~= self.cangotcash then
		                	GetMainMenu():ShowLoadingDlg()	-- 获取信息的时候，不允许操作
		                	local tmpUrlPath = GetUrlNormalHeader(self.playerData_.m_uid, protocol.LOG_CMD, protocol.URL_W_LOG)
		                	local transData = "tempCash:" .. tostring(tempCash) .. "|cangotcash:" .. tostring(self.cangotcash) .. "|" .. resData
		                	transData = tools.urlencode(transData)
							tmpUrlPath = AddData(tmpUrlPath, "Content", transData)
							CCHttpRequest:open(tmpUrlPath, kHttpPost, "query=param1&other=params"):sendWithHandler(
								function(res, hnd)
									GetMainMenu():CloseLoadding() --获取信息完成时，解除禁止操作
									--[[
									local resData = res:getResponseData()
									cclog("1111---error:%d,%d,%s\n", tempCash, self.cangotcash, resData)
									local code = res:getResponseCode()
									local xfile = xml.parse(resData)
									local item = xfile:find("RENLONG")
									local retcode = item.code

									if retcode == "0" then

									end
									]]
								end)
		                end
		                tolua.cast(self.proxy_:getNode("label_free_num"), "CCLabelBMFont"):setString(tostring(self.freeNum))
						tolua.cast(self.proxy_:getNode("label_gold_num"), "CCLabelBMFont"):setString(tostring(tmpUserCash))
						self:updateCardInfo(btn)
		 				self.isGot = true
		 			else
		 				GetMainMenu():ShowTextTip(localizable.ui_scratch_not_enough_gold, -1)
					end
				end)
		else
			GetMainMenu():ShowTextTip(localizable.ui_scratch_not_enough_gold, -1)
		end
end

function onNodeCleanup(self)
	if self.proxy_ then
    	self.proxy_:release()
    end
    ui_scratchCardLayer.isFinishBtnFun = true
    layer_base_t.onNodeCleanup(self)
end