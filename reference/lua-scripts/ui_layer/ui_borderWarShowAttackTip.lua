--边界碑_tip
--litao
--2014.2.24
---------------------------------------------
module("ui_borderWarShowAttackTip", package.seeall)
baseClass(layer_base_t, ui_borderWarShowAttackTip)

function init(self, data)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()
	local winSize = CCDirector:sharedDirector():getWinSize()
	--Load res
	local ccbiAttrTable = {name="activity/BorderWarMainLayerTip.ccbi", size=CCSizeMake(768, winSize.height)}
	layer_base_t.init(self, true, ccbiAttrTable)

	--时间增量
	self.deal_time = 0
	self.m_noticeDatas = data
	self:init_ui()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		self.countryText = tolua.cast(self.proxy_:getNode("borderWarTip_country"), "CCLabelTTF")
		self.nameText = tolua.cast(self.proxy_:getNode("borderWarTip_name"), "CCLabelTTF")	
		self.label_desc = tolua.cast(self.proxy_:getNode("borderWarTip_desc"), "CCLabelTTF")	
		self.tipNode = tolua.cast(self.proxy_:getNode("borderWarTip_node"), "CCNode")

		self.countryText:setString(tostring(self:retCountryNameText(self.m_noticeDatas.countryId)))
		self.nameText:setString(tostring(self.m_noticeDatas.nameText))

		local attackCountryText = tostring(self:retCountryNameText(self.m_noticeDatas.toCountryId))

		if self.m_noticeDatas.attackType == 1 then
			self.label_desc:setString(string.format(localizable.ui_border_tips13, attackCountryText))
		elseif self.m_noticeDatas.attackType == 2 then
			self.label_desc:setString(string.format(localizable.ui_border_tips14, attackCountryText))
		elseif self.m_noticeDatas.attackType == 3 then
			--self.label_desc:setString("在边境清理了"..tostring(self:retCountryNameText(self.m_noticeDatas.toCountryId)).."的["..self.m_noticeDatas.toNameTest.."]")
			self.label_desc:setString(string.format(localizable.ui_border_tips15, tostring(self:retCountryNameText(self.m_noticeDatas.toCountryId)), self.m_noticeDatas.toNameTest))
		end

		--定时拉取边界碑公告信息、弹出公告
		local function showNoticeInfo(fDeltaTime)
			self.deal_time = self.deal_time + fDeltaTime
			local intPart, floatPart = math.modf(self.deal_time)
			--弹出边界挑衅公告
			if intPart > 2 then
				self.node_:unscheduleUpdate()
				self.node_:removeFromParentAndCleanup(true)			
			end
		end
		self.node_:scheduleUpdateWithPriorityLua(showNoticeInfo, 0)

		--整理公告、整体居中
		local countrySize = self.countryText:getContentSize()
		local playerSize = tolua.cast(self.proxy_:getNode("label_player"), "CCLabelTTF"):getContentSize()
		local nameSize = self.nameText:getContentSize()
		local descSize = self.label_desc:getContentSize()

		local nodeSize = self.tipNode:getContentSize()	
		local offset = nodeSize.width - countrySize.width - playerSize.width - nameSize.width - descSize.width
		
		local ptx,pty = self.countryText:getPosition()
		self.countryText:setPosition(ccp(ptx + offset * 0.5, pty))
		ptx,pty = self.countryText:getPosition()
		tolua.cast(self.proxy_:getNode("label_player"), "CCLabelTTF"):setPosition(ccp(ptx + countrySize.width + 5,pty))
		ptx,pty = tolua.cast(self.proxy_:getNode("label_player"), "CCLabelTTF"):getPosition()	
		self.nameText:setPosition(ccp(ptx + playerSize.width + 5,pty))
		ptx,pty = self.nameText:getPosition()
		self.label_desc:setPosition(ccp(ptx + nameSize.width + 5,pty))
	end
end

function retCountryNameText(self, curId)
	local countryId = curId

	local curCountryNameLabel	
	if countryId == 0 then
		curCountryNameLabel = "[" .. localizable.ui_border_country_wind .. "]"
	elseif countryId == 1 then
		curCountryNameLabel = "[" .. localizable.ui_border_country_thunder .. "]"
	elseif countryId == 2 then
		curCountryNameLabel = "[" .. localizable.ui_border_country_water .. "]"
	elseif countryId == 3 then
		curCountryNameLabel = "[" .. localizable.ui_border_country_fire .. "]"
	elseif countryId == 4 then
		curCountryNameLabel = "[" .. localizable.ui_border_country_earth .. "]"
	end

	if countryId == self.playerData_.m_countrytype then
			curCountryNameLabel = "[" .. localizable.ui_border_my_country .. "]"
		end

	return curCountryNameLabel
end

function moveTextNode(self)
	--公告移动
	local move = CCMoveBy:create(1.5, ccp(-100, 0))
	local array = CCArray:create()
	array:addObject(move)
	array:addObject(CCDelayTime:create(1.5))
	local forever = CCRepeatForever:create(CCSequence:create(array))
	self.tipNode:runAction(forever)
end

function onNodeCleanup(self)
    layer_base_t.onNodeCleanup(self)
end