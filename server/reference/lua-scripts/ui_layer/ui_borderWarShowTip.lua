--边界碑_tip
--litao
--2014.2.15
---------------------------------------------
module("ui_borderWarShowTip", package.seeall)
baseClass(layer_base_t, ui_borderWarShowTip)

function init(self, data)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()
	local winSize = CCDirector:sharedDirector():getWinSize()
	--Load res
	local ccbiAttrTable = {name="activity/BorderWarMainLayerTip.ccbi", size=CCSizeMake(768, winSize.height)}
	layer_base_t.init(self, true, ccbiAttrTable)

	--时间增量
	self.round = 0
	self.deal_time = 0
	self.show_time = 0
	self.m_noticeDatas = data
	self:init_ui()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		self.countryText = tolua.cast(self.proxy_:getNode("borderWarTip_country"), "CCLabelTTF")
		self.nameText = tolua.cast(self.proxy_:getNode("borderWarTip_name"), "CCLabelTTF")	
		self.label_desc = tolua.cast(self.proxy_:getNode("borderWarTip_desc"), "CCLabelTTF")	
		self.tipNode = tolua.cast(self.proxy_:getNode("borderWarTip_node"), "CCNode")
		self.label_palyer_name_desc = tolua.cast(self.proxy_:getNode("label_player"), "CCLabelTTF")
		--记录最前label的位置
		self.countryLabel_x, self.countryLabel_y = self.countryText:getPosition()		
		--整理消息
		self:initNoticeInfoText(self.m_noticeDatas[self.round + 1])
		--记录播放状态
		--self.m_noticeDatas[self.round + 1].isShowed = true
		--消息索引+1
		self.round = self.round + 1
		
		--定时拉取边界碑公告信息、弹出公告
		local function updateNoticeInfo(fDeltaTime)
			self.deal_time = self.deal_time + fDeltaTime

			local intPart, floatPart = math.modf(self.deal_time)
			--弹出边界挑衅公告
			if intPart == (19 * self.round) then	
				--超出则关闭									
				if self.round > 3 or self.round > #self.m_noticeDatas then
					self.node_:unscheduleUpdate()
					self.m_noticeDatas = {}
					self.node_:removeFromParentAndCleanup(true)	
					return nil	
				end
				--判断播放状态
				--[[
				if self.m_noticeDatas[self.round + 1].isShowed == false then
					self.m_noticeDatas[self.round + 1].isShowed = true
				else
					--索引+1	
					self.round = self.round + 1
					return nil
				end
				--]]
				--显示整理一条消息
				self:initNoticeInfoText(self.m_noticeDatas[self.round + 1])				
				--显示
				self.tipNode:setVisible(true)
				--索引+1	
				self.round = self.round + 1
			elseif intPart == (19 * self.round - 15) then
				--隐藏
				self.tipNode:setVisible(false)	
			end
		end
		--开启定时器
		self.node_:scheduleUpdateWithPriorityLua(updateNoticeInfo, 0)
	end
end

--整理一条公告信息
function initNoticeInfoText(self, curTipData)
	--处理错误信息
	if curTipData == nil then
		self.node_:unscheduleUpdate()
		self.node_:removeFromParentAndCleanup(true)	
		return nil
	end
	--边境信息整理
	if true == curTipData.isBorderWar then
		--国家text
		local curCountryId = tonumber(curTipData.countryId)
		local curCountryText = tostring(self:retCountryNameText(curCountryId))

		self.countryText:setString(curCountryText)
		self.countryText:setPosition(ccp(self.countryLabel_x, self.countryLabel_y))
		self.nameText:setString(curTipData.nameText)

		--toCountryId
		local toCountryId = tonumber(curTipData.toCountryId)
		local toCountryText = self:retCountryNameText(toCountryId)
		--toName
		local toNameText = tostring(curTipData.toNameText)
		--消息类型
		local curStatus = tonumber(curTipData.status)
		if curStatus == 1 then
			if toCountryId == self.playerData_.m_countrytype then
				self.label_desc:setString(string.format(localizable.ui_border_tips16, toCountryText))
			else
				self.label_desc:setString(string.format(localizable.ui_border_tips17, toCountryText))
			end
		elseif curStatus == 2 then
			if toCountryId == self.playerData_.m_countrytype then
				self.label_desc:setString(string.format(localizable.ui_border_tips18, toCountryText))
			else
				self.label_desc:setString(string.format(localizable.ui_border_tips19, toCountryText))
			end
		else
			self.label_desc:setString(string.format(localizable.ui_border_tips20, toCountryText, toNameText))
		end
	else
		--跑马灯信息整理
		--self:initMarqueeInfoText(curTipData)
	end

	--整理内容、整体居中
	---[[	
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

function initMarqueeInfoText(self, curTipData)
	--litao_2014.6.3_跑马灯信息整理
	if 1 == curTipData.type then	--万里挑一
		self.countryText:setString(localizable.ui_borderShow_type_1)
		self.nameText:setString(curTipData.arg1)
		self.label_desc:setString(string.format(localizable.ui_borderShow_type_1_desc, curTipData.arg2))
	elseif 2 == curTipData.type then--淬炼
		self.countryText:setString(localizable.ui_borderShow_type_2)
		self.nameText:setString(curTipData.arg1)
		self.label_desc:setString(string.format(localizable.ui_borderShow_type_2_desc, curTipData.arg2))
	elseif 3 == curTipData.type then--转生
		self.countryText:setString(localizable.ui_borderShow_type_3)
		self.label_palyer_name_desc:setString(localizable.ui_borderShow_type_3_desc_1)
		self.nameText:setString(curTipData.arg1)
		self.label_desc:setString(string.format(localizable.ui_borderShow_type_3_desc_2, curTipData.arg2))
	elseif 4 == curTipData.type then--夺宝
		self.countryText:setString(localizable.ui_borderShow_type_4)
		self.label_palyer_name_desc:setString(localizable.ui_borderShow_type_4_desc_1)
		self.nameText:setString(curTipData.arg1)
		self.label_desc:setString(string.format(localizable.ui_borderShow_type_4_desc_2, curTipData.arg2, curTipData.arg3))
	elseif 5 == curTipData.type then--活动抽卡
		self.countryText:setString(localizable.ui_borderShow_type_5)
		self.nameText:setString(curTipData.arg1)
		self.label_desc:setString(string.format(localizable.ui_borderShow_type_5_desc, curTipData.arg2))
	elseif 6 == curTipData.type then--活动第一名
		self.countryText:setString(localizable.ui_borderShow_type_5)
		self.label_palyer_name_desc:setString(localizable.ui_borderShow_type_6_desc_1)
		self.nameText:setString(curTipData.arg1)
		self.label_desc:setString(string.format(localizable.ui_borderShow_type_6_desc_2, curTipData.arg2))
	elseif 7 == curTipData.type then--百宝箱1000元宝
		self.countryText:setString(localizable.ui_borderShow_type_5)
		self.nameText:setString(curTipData.arg1)
		self.label_desc:setString(localizable.ui_borderShow_type_7_desc)
	elseif 8 == curTipData.type then--BOSS补刀
		self.countryText:setString(localizable.ui_borderShow_type_6)
		self.nameText:setString(curTipData.arg1)
		self.label_desc:setString(localizable.ui_borderShow_type_8_desc)
	elseif 9 == curTipData.type then--BOSS最强dps
		self.countryText:setString(localizable.ui_borderShow_type_6)
		self.nameText:setString(curTipData.arg1)
		self.label_desc:setString(localizable.ui_borderShow_type_9_desc)
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