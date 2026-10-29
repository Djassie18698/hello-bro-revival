--descriptioin:女神献花界面
--company: xckoo
--author: chenchun
--date: 2013-1-16

---------------------------------------------
module("ui_nvshenLayer", package.seeall)
baseClass(layer_base_t, ui_nvshenLayer)

pixelUnit = 5	--单位,当移动距离超过5以后，才进行放大缩小处理
label_money_node_instance = nil

function init(self)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	--如果期数不同，更新期数
	if activityPeriod.goddessFlower.display == -1 then
		newsCount = newsCount - 1
		writeActivityData(self.playerData_.m_uid, activity_config.activityTipConfig.goddessFlower, activityPeriod.goddessFlower.period)
	elseif activityPeriod.goddessFlower.display == -2 then
		newsCount = newsCount - 1
	end

	self.contentNode_ = GetActivityView():GetNodeContent()
	self.contentSize_ = self.contentNode_:getContentSize()

	--cclog("1111---%d, %d", self.contentSize_.width, self.contentSize_.height)
	local ccbiAttrTable = {name="activity/NvShen.ccbi", size=self.contentSize_}
	layer_base_t.init(self, true, ccbiAttrTable)

	self.m_bIsEndAnimatedScroll_ = true
	self.touchHandler_ = {}
	self.sprite_config_data = {}
	self.gift_config_data = {}
	self.leftTime = 0
	self.acc_money = 0
	self.deltatime = 0

	--self:create_test_data()
	--self.cellNodes = {}   --首充信息列表的单元格信息，元素为ui_purchaseTableCell 类型
	self:init_ui()
	self:init_binding_event()
end


function init_ui(self)
	if self.proxy_ ~= nil then
		self.node_sprite_content = tolua.cast(self.proxy_:getNode("node_sprite_content"), "CCNode")
		self.sprite_nodes = {}
		self.sprite_points = {}
		self.sprite_scales = {[1] = 0.31, [2] = 0.65, [3] = 1, [4] = 0.65, [5] = 0.31}
		self.sprite_opactiy = {[1] = 105, [2] = 180, [3] = 255, [4] = 180, [5] = 105}
		for i = 1, 5 do
			self["sprite_avtor_" .. tostring(i)] =  tolua.cast(self.proxy_:getNode("sprite_avtor_" .. tostring(i)), "CCSprite")
			self.node_sprite_content:reorderChild(self["sprite_avtor_" .. tostring(i)] , 1)
			table.insert(self.sprite_nodes, self["sprite_avtor_" .. tostring(i)])
			local x, y = self["sprite_avtor_" .. tostring(i)]:getPosition()
			local tmpPoint = {x = x, y = y}
			table.insert(self.sprite_points, tmpPoint)
		end
		self.label_rest_time = tolua.cast(self.proxy_:getNode("label_rest_time"), "CCLabelTTF")
		self.btn_give_flower = tolua.cast(self.proxy_:getNode("btn_give_flower1"), "CCControlButton")
		self.label_good_feel = tolua.cast(self.proxy_:getNode("label_good_feel"), "CCLabelTTF")
		self.label_acc_money = tolua.cast(self.proxy_:getNode("label_acc_money"), "CCLabelBMFont")
		self.btn_give_money = tolua.cast(self.proxy_:getNode("btn_give_money"), "CCControlButton")
		self.btn_activity_desc = tolua.cast(self.proxy_:getNode("btn_activity_desc"), "CCControlButton")
		self.btn_update_money = tolua.cast(self.proxy_:getNode("btn_update_money"), "CCControlButton")
		self.label_give_flowers = tolua.cast(self.proxy_:getNode("label_give_flowers"), "CCLabelTTF")

		local node_size = self.node_sprite_content:getContentSize()
		self.midX = node_size.width * 0.5
		self.left_right_width = node_size.width * 2
		self.sprite_distance = node_size.width * 0.4
		self.scalePara = 0.4 / self.sprite_distance --每移动单个像素的缩放比例
		self.scaleOpacity = 75 / self.sprite_distance
		self.scaleParameter = self.scalePara * 5			--每移动5个像素的缩放比例
		self.allMoveDistance = 0
		self.circleNumber = -1
		self.move_speed = self.sprite_distance / 0.5

		self:getActivityInitData()
	end
end

function init_binding_event(self)

	local function onTouched(_eventType, ...)
        --cclog("_eventType = %s", _eventType)
        local result = self.touchHandler_[_eventType](self, ...)
        if self.touchBegan ~= nil and _eventType == "began" then
            assert(result ~= nil, "touchBegan must return a result!")

            local ret

            if result == true then
                ret = 1
            else
                ret = 0
            end
            return ret
        end
    end

    if self.touchBegan ~= nil then
        --单点触控
        self.node_:setTouchEnabled(true)
        self.node_:registerScriptTouchHandler(onTouched, false, 2, true)

        self.touchHandler_["began"] = self.touchBegan
        self.touchHandler_["moved"] = self.touchMoved
        self.touchHandler_["ended"] = self.touchEnded
        self.touchHandler_["cancelled"] = self.touchCancelled
 	end

	--self.node_:setTouchEnabled(true)
	--self.node_:registerScriptTouchHandler(CCLayerTouch, false, -1, true)

	local function give_flower(btn, event)
		local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 9, protocol.URL_W_COMM)
		urlpath = AddData(urlpath, "GirlID", self.sprite_config_data[3].id) --这个参数没意义在这里没意义，但是要传
		GetMainMenu():ShowLoadingDlg()
		CCHttpRequest:open(urlpath, kHttpPost, "query=param1&other=params"):sendWithHandler(
			function(res, hnd)
				GetMainMenu():CloseLoadding()
				local resData = res:getResponseData()
				local code = res:getResponseCode()
				local xfile = xml.parse(resData)
				local item = xfile:find("RENLONG")
				local retcode = item.code
				if retcode == "0" then
					local previewData = xfile:find("preview")
					if previewData then
						local curstat = previewData.currsat
						--cclog("1111---%s", tostring(curstat))
						local myflowers = previewData.currflower
						if curstat ~= "0" then
							self.label_acc_money:setString(myflowers)
							self.sprite_config_data[3].like = curstat
							self.label_good_feel:setString(tostring(self.sprite_config_data[3].like) .. "/" .. tostring(self.sprite_config_data[3].alllikenum))
							self:flowerAnimation("nvshenxianhua_1", 1.3)
						else
							self.label_acc_money:setString(myflowers)
							self.sprite_config_data[3].like = curstat
							self.label_good_feel:setString(tostring(self.sprite_config_data[3].like) .. "/" .. tostring(self.sprite_config_data[3].alllikenum))
							self:flowerAnimation(self.sprite_config_data[3].ccbi, 3)
							self.awardXml = xfile:find("award")
						end
					end
				else
					GetMainMenu():ShowTextTip(text.text_config[tonumber(retcode)].description, -1)
					if retcode == "320002" then
						local puchaseLayer = createObj(ui_purchaseLayer)
						GetMainMenu():GetModelLayer():AddDialog(puchaseLayer.node_, 3)
					end
				end
			end)
	end

	local function give_money(btn, event)
		local puchaseLayer = createObj(ui_purchaseLayer)
		GetMainMenu():GetModelLayer():AddDialog(puchaseLayer.node_, 3)
	end

	local function btn_activity_desc(btn, event)
		CSoundMgr:instance():PlayEffect(SOUND_BUTTON)
		-- local index = btn:getTag()
		-- local dlg = CommonDialogView.create()
		-- CommonDialogView.m_selfview = dlg
		-- dlg:SetTitle(localizable.ui_nvshen_title)
		-- dlg:SetDescription(localizable.ui_nvshen_description)
		-- dlg:loadCCBI(kCCMenuHandlerPriority-4, "CommonDialogViewBig")
		-- dlg:initUI(kCCMenuHandlerPriority-5)
		-- --dlg:SetConfirmHandler(getRankGift)
		-- --dlg:updateLeftBtnText(localizable.ui_rouletteLayer_get_gift)
		-- GetMainMenu():GetModelLayer():AddDialog(dlg, 3)
		
		local nodelayer = createObj(ui_nvshenDescLayer, self.gift_config_data)
		GetMainMenu():GetModelLayer():AddDialog(nodelayer.node_, 3)

	end

	local function btn_update_money(btn, event)
		self:refresh()
	end

	if self.proxy_ ~= nil then
		self.proxy_:handleControlEvent(self.btn_give_flower, give_flower, CCControlEventTouchUpInside)
		self.proxy_:handleControlEvent(self.btn_give_money, give_money, CCControlEventTouchUpInside)
		self.proxy_:handleControlEvent(self.btn_activity_desc, btn_activity_desc, CCControlEventTouchUpInside)
		self.proxy_:handleControlEvent(self.btn_update_money, btn_update_money, CCControlEventTouchUpInside)
	end
end

function refresh(self)
	--self.playerData_ = self.playerMgr_:GetPlayerInfoData()
	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid,  5, protocol.URL_R_COMM)
	GetMainMenu():ShowLoadingDlg()
	CCHttpRequest:open(urlpath, kHttpPost, "query=param1&other=params"):sendWithHandler(
		function(res, hnd)
			GetMainMenu():CloseLoadding()
			local resData = res:getResponseData()
			local code = res:getResponseCode()
			local xfile = xml.parse(resData)
			local item = xfile:find("RENLONG")
			local retcode = item.code

			if retcode == "0" then
				local previewData = xfile:find("preview")
				if previewData then
					local open = previewData.open
					local myflowers = previewData.myflower
					local leftTime = tonumber(previewData.resttime)
					self.label_acc_money:setString(myflowers)
				end

			end
		end)
end

function touchBegan(self, _touchX, _touchY)
	if self.m_bIsEndAnimatedScroll_ then
		--[[]]
		local tmpPoint = self.contentNode_:convertToNodeSpace(ccp(_touchX, _touchY))
		if self.contentNode_:boundingBox():containsPoint(tmpPoint) then
			self.isTouchMoved_ = false
			self.moveDirection_ = true	--right direction
			self.beganX_ = _touchX
			self._preTouchX = _touchX
			self._preTouchY = _touchY
		end


		--self.circleNumber = 0
		--[[
		if _touchX < self.maxRightX_ then
			self.beganX_ = _touchX
		else
			self.beganX_ = nil
		end
		]]
		return true
	else
		return false
	end
end

function touchMoved(self, _touchX, _touchY)
	if self.beganX_ ~= nil and self.m_bIsEndAnimatedScroll_ then
		self.isTouchMoved_ = true
		local moveDistance = 0
		--cclog("1111---%s", tostring(_preTouchX))
		if self._preTouchX > _touchX then --向左
			self.moveDirection_ = false
			moveDistance = self.beganX_ - _touchX

			local disX = _touchX - self._preTouchX
			self.allMoveDistance = self.allMoveDistance + disX
			self:moveSprite(false, moveDistance, disX)
			--self:reorderChild()
			local num = tools.getIntPart((moveDistance / self.sprite_distance))

			if num ~= self.circleNumber then
				self.circleNumber = num
				local x, y = self.sprite_nodes[1]:getPosition()
				local tmpValue = table.remove(self.sprite_nodes, 1)
				tmpValue:setPosition(x + self.left_right_width, y)
				local tmpScale = math.abs(self.midX - x - self.left_right_width) * self.scalePara
				local tmpOpacity = math.abs(self.midX - x - self.left_right_width) * self.scaleOpacity
				tmpValue:setScale(1 - tmpScale)
				tmpValue:updateDisplayedOpacity(255 - tmpOpacity)
				table.insert(self.sprite_nodes, tmpValue)
				self:resetConfigData(false)
			end
		elseif self._preTouchX < _touchX then --向右
			self.moveDirection_ = true
			moveDistance = _touchX - self.beganX_
			local disX = _touchX - self._preTouchX
			self.allMoveDistance = self.allMoveDistance + disX
			self:moveSprite(true, moveDistance, disX)

			--self:reorderChild()
			local num = tools.getIntPart((moveDistance / self.sprite_distance))

			if num ~= self.circleNumber then
				self.circleNumber = num
				local x, y = self.sprite_nodes[5]:getPosition()
				local tmpValue = table.remove(self.sprite_nodes)
				tmpValue:setPosition(x - self.left_right_width, y)
				local tmpScale = math.abs(self.midX - x + self.left_right_width) * self.scalePara
				tmpValue:setScale(1 - tmpScale)
				local tmpOpacity = math.abs(self.midX - x + self.left_right_width) * self.scaleOpacity
				tmpValue:updateDisplayedOpacity(255 - tmpOpacity)
				table.insert(self.sprite_nodes, 1, tmpValue)
				--重新移动配置数据
				self:resetConfigData(true)
			end
		end
		self._preTouchX = _touchX
		self._preTouchY = _touchY
	end
end

function touchEnded(self, _touchX, _touchY)
	if self.isTouchMoved_ then
		self.isTouchMoved_ = false
		self:startAnimatedScroll()
		self.allMoveDistance = 0
		self.circleNumber = -1
		self.beganX_ = nil
		self.label_give_flowers:setString(self.sprite_config_data[3].desc)
		--self.btn_give_flower:setTitleForState(self.sprite_config_data[3].desc, CCControlStateNormal)
		--self.btn_give_flower:setTitleForState(self.sprite_config_data[3].desc, CCControlStateHighlighted)
		--self.btn_give_flower:setTitleForState(self.sprite_config_data[3].desc, CCControlStateDisabled)
		self.label_good_feel:setString(tostring(self.sprite_config_data[3].like) .. "/" .. tostring(self.sprite_config_data[3].alllikenum))
	end
end

function touchCancelled(self)
	for i = 1, 5 do
		self.sprite_nodes[i]:setPosition(self.sprite_points[i].x, self.sprite_points[i].y)
		self.sprite_nodes[i]:setScale(self.sprite_scales[i])
	end
	self:reorderChild()
	self.label_give_flowers:setString(self.sprite_config_data[3].desc)
	--self.btn_give_flower:setTitleForState(self.sprite_config_data[3].desc, CCControlStateNormal)
	--self.btn_give_flower:setTitleForState(self.sprite_config_data[3].desc, CCControlStateHighlighted)
	--self.btn_give_flower:setTitleForState(self.sprite_config_data[3].desc, CCControlStateDisabled)
	self.label_good_feel:setString(tostring(self.sprite_config_data[3].like) .. "/" .. tostring(self.sprite_config_data[3].alllikenum))
end

function reorderChild(self)
	local disMid = 2000
	local index = 1
	for i = 1, 5 do
		local x = self.sprite_nodes[i]:getPosition()
		local tmpDis = math.abs(x - self.midX)
		if tmpDis < disMid then
			disMid = tmpDis
			index = i
		end
	end
	for i = 1, 5 do
		if i == index then
			self.node_sprite_content:reorderChild(self.sprite_nodes[i], 5)
		else
			self.node_sprite_content:reorderChild(self.sprite_nodes[i], 1)
			self.sprite_nodes[i]:updateDisplayedOpacity(self.sprite_opactiy[i])
		end
	end
end

function resetConfigData(self, direction)
	if not direction then
		local tmpValue = table.remove(self.sprite_config_data, 1)
		table.insert(self.sprite_config_data, tmpValue)
	else
		local tmpValue = table.remove(self.sprite_config_data)
		table.insert(self.sprite_config_data, 1, tmpValue)
	end
	for i = 1, 5 do
		--cclog("1111---sprite:%s", self.sprite_config_data[i].icon)
		local pFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(self.sprite_config_data[i].icon)
		self.sprite_nodes[i]:setDisplayFrame(pFrame)
	end
end

function moveSprite(self, direction, moveDistance, disX)
	--if not direction then  --局部往左做移动
		for i = 1, 5 do
			if moveDistance > 0 then --整体是往左移动
				local preX, preY = self.sprite_nodes[i]:getPosition()
				local x = preX + disX
				--local tmpX = self.sprite_points[i].x - moveDistance
				local scaleCur = math.abs(self.midX - x) * self.scalePara
				local tmpOpacity = math.abs(self.midX - x) * self.scaleOpacity
				self.sprite_nodes[i]:updateDisplayedOpacity(255 - tmpOpacity)
				self.sprite_nodes[i]:setPosition(x, preY)
				self.sprite_nodes[i]:setScale(1 - scaleCur)
			else                     --整体往右移动
				local preX, preY = self.sprite_nodes[i]:getPosition()
				local x = preX + disX
				--local tmpX = self.sprite_points[i].x + moveDistance
				local scaleCur = math.abs(self.midX - x) * self.scalePara
				local tmpOpacity = math.abs(self.midX - x) * self.scaleOpacity
				self.sprite_nodes[i]:updateDisplayedOpacity(255 - tmpOpacity)
				self.sprite_nodes[i]:setPosition(x, preY)
				self.sprite_nodes[i]:setScale(1 - scaleCur)
			end
		end

end

function getActivityInitData(self)
	local function updateLeftTimeLabel(fDeltaTime)
		self.deltatime = self.deltatime + fDeltaTime
		if self.deltatime >= 1 then
			local intPart, floatPart = math.modf(self.deltatime)
			self.leftTime = self.leftTime - intPart
			if self.leftTime > 0 then
				local timeStr = tools.convertTimeElectronicWatchChinese(self.leftTime, 3)
				self.label_rest_time:setString(timeStr)
				self.deltatime = floatPart
			else
				self.label_rest_time:setString(localizable.ui_multi_ended)
				self.label_rest_time:unscheduleUpdate()
			end
		end
	end

	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 5, protocol.URL_R_COMM)
		GetMainMenu():ShowLoadingDlg()
		CCHttpRequest:open(urlpath, kHttpPost, "query=param1&other=params"):sendWithHandler(
			function(res, hnd)
				GetMainMenu():CloseLoadding()
				local resData = res:getResponseData()
				cclog("1111----resData:%s", resData)
				local code = res:getResponseCode()
				local xfile = xml.parse(resData)
				local item = xfile:find("RENLONG")
				local retcode = item.code
				if retcode == "0" then
					local previewData = xfile:find("preview")
					if previewData then
						local open = previewData.open
						local myflowers = previewData.myflower
						local leftTime = tonumber(previewData.resttime)
						self.label_acc_money:setString(myflowers)
						if open == "0" then
							self.leftTime = 0
							if leftTime > 0 then
								self.label_rest_time:setString(localizable.ui_nvshen_not_start)
							else
								self.label_rest_time:setString(localizable.ui_multi_ended)
							end
						else
							if leftTime > 0 then
								self.leftTime = leftTime
								self.label_rest_time:scheduleUpdateWithPriorityLua(updateLeftTimeLabel, 0)
								self.label_rest_time:setString(tools.convertTimeElectronicWatchChinese(self.leftTime, 3))
							else
								self.label_rest_time:setString(localizable.ui_multi_ended)
							end
						end
					end

					local itemList = xfile:find("itemlist")
					if itemList then
						self.sprite_config_data = {}
						self.gift_config_data = {}
						for i = 1, #itemList do
							local id = tonumber(itemList[i]:find("ninja_id")[1])
							local name = itemList[i]:find("ninja_name")[1]
							local icon = itemList[i]:find("ninja_icon")[1]
							local flowers = itemList[i]:find("ninja_flowers")[1]
							local alllikenum = tonumber(itemList[i]:find("ninja_alllikenum")[1])
							local like = tonumber(itemList[i]:find("own_like")[1])
							local index = tonumber(itemList[i]:find("ninja_index")[1])
							local desc_tmp = string.format(localizable.ui_nvshen_give_flower_tips1, tostring(flowers))
							self.sprite_config_data[index] = {id=id, icon=icon, desc=desc_tmp, alllikenum=alllikenum, like=like, ccbi="nvshenxianhua_" .. name}
							
							local awardItemlist = itemList[i]:find("awardlist")
							if awardItemlist then
								local tmpTable = {}
								local tmpTable = {}
								for j = 1, #awardItemlist do
									local giftid = awardItemlist[j].dropid
									local iconfolder = awardItemlist[j].folder
									local iconname = awardItemlist[j].name
									local num = awardItemlist[j].num
									local descinfo = awardItemlist[j].des
									local colorinfo = awardItemlist[j].color
									--增加忍者转生等级_litao_2014.8.2
									local newlife = tonumber(awardItemlist[j].newlife)
									table.insert(tmpTable, {id=giftid, folder=iconfolder, icon=iconname, count=num, desc=descinfo, color=colorinfo, newlife = newlife})
								end
								table.insert(self.gift_config_data, tmpTable)
							end

						end
						self.label_good_feel:setString(tostring(self.sprite_config_data[3].like) .. "/" .. tostring(self.sprite_config_data[3].alllikenum))
						--self.btn_give_flower:setTitleForState(tostring(self.sprite_config_data[3].desc), CCControlStateDisabled)
						self.label_give_flowers:setString(self.sprite_config_data[3].desc)
						--self.btn_give_flower:setTitleForState(self.sprite_config_data[3].desc, CCControlStateNormal)
						--self.btn_give_flower:setTitleForState(self.sprite_config_data[3].desc, CCControlStateHighlighted)
						--self.btn_give_flower:setTitleForState(self.sprite_config_data[3].desc, CCControlStateDisabled)
					end

				else
					GetMainMenu():ShowTextTip(text.text_config[tonumber(retcode)].description, -1)
				end
			end)
end

function startAnimatedScroll(self)
	self.m_bIsEndAnimatedScroll_ = false
	local animationNumer = 0
	local function actionFinished()
		animationNumer = animationNumer + 1
		if animationNumer == 5 then
			self:reorderChild()
			self.m_bIsEndAnimatedScroll_ = true
		end
	end
	local sprite_posX = self.sprite_nodes[3]:getPosition()
	local time1 = math.abs(self.sprite_points[3].x - sprite_posX) / self.move_speed
	for i = 1, 5 do
		local endPos = ccp(self.sprite_points[i].x, self.sprite_points[i].y)
    	local ccMoveto = CCMoveTo:create(time1, endPos)
    	local scaleTo = CCScaleTo:create(time1, self.sprite_scales[i])
    	local ccFadeTo = CCFadeTo:create(time1, self.sprite_opactiy[i])
		local ccArraySpawn = CCArray:create()
    	ccArraySpawn:addObject(ccMoveto)
    	ccArraySpawn:addObject(scaleTo)
    	ccArraySpawn:addObject(ccFadeTo)
    	local ccSpawn = CCSpawn:create(ccArraySpawn)

    	local moveFinishCall = CCCallFuncN:create(actionFinished)

    	local moveSeq = CCSequence:createWithTwoActions(ccSpawn, moveFinishCall)
    	self.sprite_nodes[i]:runAction(moveSeq)
	end

end

function onNodeCleanup(self)
    --cclog("onNodeCleanup")
    if self.proxy_ then
    	self.proxy_:release()
    end
    layer_base_t.onNodeCleanup(self)
end

--private function
function flowerAnimation(self, animationName, time)
	local win = CCDirector:sharedDirector():getWinSize()
	local finishLayer = createObj(ui_nvshenAnimationLayer, animationName)
	finishLayer.node_:setAnchorPoint(ccp(0.5, 0.5))
	finishLayer.node_:setPosition(win.width / 2, win.height / 2)
	finishLayer.node_:ignoreAnchorPointForPosition(false)
	finishLayer.node_:setTouchEnabled(true)
		local function stopAnimation()
			if self.disappear ~= nil then
				CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.disappear)
				self.disappear = nil
				finishLayer.node_:removeFromParentAndCleanup(true)
				if self.awardXml then
					ShowAward(self.awardXml)
					self.awardXml = nil
				end
			end
		end
		finishLayer.node_:registerScriptTouchHandler(stopAnimation, false, kCCMenuHandlerPriority-1, true)
		finishLayer.node_:setTouchMode(0)

		local function animationFinished()
			if self.disappear ~= nil then
				CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.disappear)
				self.disappear = nil
				finishLayer.node_:removeFromParentAndCleanup(true)
				if self.awardXml then
					ShowAward(self.awardXml)
					self.awardXml = nil
				end
			end
		end
		self.disappear = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(animationFinished, time, false)
		GetMainMenu():GetModelLayer():addChild(finishLayer.node_)
end

function create_test_data(self)
	self.test_data = {
		[1] = {id = 1, icon = "nvshen_meinv1", desc = "献花1朵", ccbi="nvshenxianhua_chutian"},
		[2] = {id = 2, icon = "nvshen_meinv2", desc = "献花10朵", ccbi="nvshenxianhua_xiaonan"},
		[3] = {id = 3, icon = "nvshen_meinv3", desc = "献花30朵", ccbi="nvshenxianhua_shuiying"},
		[4] = {id = 4, icon = "nvshen_meinv4", desc = "献花50朵", ccbi="nvshenxianhua_chunyeying"},
		[5] = {id = 5, icon = "nvshen_meinv5", desc = "献花100朵", ccbi="nvshenxianhua_gangshou"}
	}
end