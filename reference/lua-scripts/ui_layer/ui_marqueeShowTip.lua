--跑马灯_tip
--litao
--2014.6.5
---------------------------------------------
module("ui_marqueeShowTip", package.seeall)
baseClass(layer_base_t, ui_marqueeShowTip)

function init(self, data)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()
	local winSize = CCDirector:sharedDirector():getWinSize()

	--Load res
	local ccbiAttrTable = {name="MarqueeTipView.ccbi", size=CCSizeMake(768, winSize.height)}
	layer_base_t.init(self, true, ccbiAttrTable)

	--时间增量
	self.round = 0
	self.deal_time = 0
	self.m_noticeDatas = data
	self.m_informRect = nil
	self:init_ui()
end	

function init_ui(self)
	self.label_type = tolua.cast(self.proxy_:getNode("label_type"), "CCLabelTTF")
	self.label_player = tolua.cast(self.proxy_:getNode("label_player"), "CCLabelTTF")
	self.label_name = tolua.cast(self.proxy_:getNode("label_name"), "CCLabelTTF")
	self.label_tip_desc = tolua.cast(self.proxy_:getNode("label_tip_desc"), "CCLabelTTF")
	self.node_info = tolua.cast(self.proxy_:getNode("node_inform"), "CCNode")
	self.node_label = tolua.cast(self.proxy_:getNode("node_label"), "CCNode")

	--消息索引+1
	self.round = self.round + 1
	--显示区域
	self.size = self.node_info:getContentSize()
	--处理公告
	self:initNoticeInfoText(self.m_noticeDatas[self.round + 1])
	--文字长度
	--self.m_informRect = self.label_tip_desc:getTextureRect()
	--记录label的位置
	self.label_x, self.label_y = self.node_label:getPosition()	
	--文字X轴的左边界
	self.m_informScrollX = self.size.width + self.label_x
	
	--定时拉取公告信息、弹出公告
	local function updateNoticeInfo(fDeltaTime)
		self.deal_time = self.deal_time + fDeltaTime

		local intPart, floatPart = math.modf(self.deal_time)

		self.m_informScrollX = self.m_informScrollX - 1
		--确保信息区域不为空
		if nil == self.m_informRect then
			self.node_label:setVisible(false)
			self.node_:unscheduleUpdate()
			self.node_:removeFromParentAndCleanup(true)
			return
		elseif nil == self.m_informRect.width then
			self.node_label:setVisible(false)
			self.node_:unscheduleUpdate()
			self.node_:removeFromParentAndCleanup(true)
			return
		end
		--判断是否为下一条信息
		if self.m_informScrollX < -self.m_informRect.width + self.label_x then
			--显示下一条消息
			cclog("next index = %s", tostring(self.round + 1))
			if self.round + 1 <= #self.m_noticeDatas then
				self.m_informScrollX = self.size.width + self.label_x			
				self:initNoticeInfoText(self.m_noticeDatas[self.round + 1])
				self.node_label:setPosition(self.m_informScrollX, self.label_y)
				self.round = self.round + 1
			else
				self.node_label:setVisible(false)
				self.node_:unscheduleUpdate()
				self.node_:removeFromParentAndCleanup(true)
				return
			end			
		end

		--文字长度不超过文字显示区域
		if self.m_informRect.width < self.size.width then
			--文字从右边出来
			local expose = self.size.width + self.label_x - self.m_informScrollX
			if expose < self.m_informRect.width then
				--文字部分未全部显示出来
				--self.node_label:setTextureRect(CCRectMake(0, 0, expose, self.size.height))
			else
				--文字部分已经从右边全部显示出来
				--self.node_label:setTextureRect(CCRectMake(0, 0, self.m_informRect.width, self.size.height))
			end

			--文字开始从左边消失
			if self.m_informScrollX < self.label_x then
				local offset = math.abs(self.label_x - self.m_informScrollX)
				--self.node_label:setTextureRect(CCRectMake(offset, 0, self.m_informRect.width - offset, self.size.height))
			else
				--文字移动
				--self.node_label:setPosition(self.m_informScrollX, self.label_y)	
			end
		else--文字长度超过文字显示区域		
			--文字从右边出来
			local expose = self.size.width + self.label_x - self.m_informScrollX
			if expose < self.size.width then
				--文字部分未全部显示出来
				--self.node_label:setTextureRect(CCRectMake(0, 0, expose, self.size.height))
			end

			--文字开始从左边消失
			if self.m_informScrollX < self.label_x then
				local offset = math.abs(self.label_x - self.m_informScrollX)
				--剩下的长度依旧大于显示区域的情况
				if self.m_informRect.width - offset > self.size.width then
					--self.node_label:setTextureRect(CCRectMake(offset, 0, self.size.width, self.size.height))
				else
					--self.node_label:setTextureRect(CCRectMake(offset, 0, self.m_informRect.width - offset, self.size.height))
				end
			else
				--文字移动
				--self.node_label:setPosition(self.m_informScrollX, self.label_y)
			end
		end
		self.node_label:setPosition(self.m_informScrollX, self.label_y)
	end
	--开启定时器
	self.node_:unscheduleUpdate()
	self.node_:scheduleUpdateWithPriorityLua(updateNoticeInfo, 0)
end

--整理一条公告信息
function initNoticeInfoText(self, curTipData)
	--处理错误信息
	if curTipData == nil then
		self.node_:unscheduleUpdate()
		self.node_:removeFromParentAndCleanup(true)	
		return nil
	end

	if false == curTipData.isBorderWar then
		--跑马灯信息整理
		self:initMarqueeInfoText(curTipData)
	end
end

function initMarqueeInfoText(self, curTipData)
	--litao_2014.6.3_跑马灯信息整理
	if 1 == curTipData.type then	--万里挑一1
		self.label_type:setString(localizable.ui_borderShow_type_1)
		self.label_player:setString(localizable.ui_borderShow_type_desc_player)
		self.label_name:setString(curTipData.arg1)
		self.label_tip_desc:setString(string.format(localizable.ui_borderShow_type_1_desc, curTipData.arg2))
	elseif 2 == curTipData.type then--淬炼1
		self.label_type:setString(localizable.ui_borderShow_type_2)
		self.label_player:setString(localizable.ui_borderShow_type_desc_player)
		self.label_name:setString(curTipData.arg1)
		self.label_tip_desc:setString(string.format(localizable.ui_borderShow_type_2_desc, tostring(curTipData.arg2)))
	elseif 3 == curTipData.type then--转生2
		self.label_type:setString(localizable.ui_borderShow_type_3)
		self.label_player:setString(localizable.ui_borderShow_type_3_desc_player)
		self.label_name:setString(curTipData.arg1)
		self.label_tip_desc:setString(string.format(localizable.ui_borderShow_type_3_desc, curTipData.arg2, tostring(curTipData.arg3)))
	elseif 4 == curTipData.type then--夺宝0
		self.label_type:setString(localizable.ui_borderShow_type_4)
		self.label_player:setString(localizable.ui_borderShow_type_4_desc_player)
		self.label_name:setString(curTipData.arg1)
		self.label_tip_desc:setString(localizable.ui_borderShow_type_4_desc)
	elseif 5 == curTipData.type then--活动抽卡1
		self.label_type:setString(localizable.ui_borderShow_type_5)
		self.label_player:setString(localizable.ui_borderShow_type_desc_player)
		self.label_name:setString(curTipData.arg1)
		self.label_tip_desc:setString(string.format(localizable.ui_borderShow_type_5_desc, curTipData.arg2))
	elseif 6 == curTipData.type then--活动第一名1
		self.label_type:setString(localizable.ui_borderShow_type_5)
		self.label_player:setString(localizable.ui_borderShow_type_desc_player)
		self.label_name:setString(curTipData.arg1)
		self.label_tip_desc:setString(string.format(localizable.ui_borderShow_type_6_desc, curTipData.arg2))
	elseif 7 == curTipData.type then--百宝箱1000元宝0
		self.label_type:setString(localizable.ui_borderShow_type_5)
		self.label_player:setString(localizable.ui_borderShow_type_desc_player)
		self.label_name:setString(curTipData.arg1)
		self.label_tip_desc:setString(localizable.ui_borderShow_type_7_desc)
	elseif 8 == curTipData.type then--BOSS补刀0
		self.label_type:setString(localizable.ui_borderShow_type_6)
		self.label_player:setString(localizable.ui_borderShow_type_desc_player)
		self.label_name:setString(curTipData.arg1)
		self.label_tip_desc:setString(localizable.ui_borderShow_type_8_desc)
	elseif 9 == curTipData.type then--BOSS最强dps0
		self.label_type:setString(localizable.ui_borderShow_type_6)
		self.label_player:setString(localizable.ui_borderShow_type_desc_player)
		self.label_name:setString(curTipData.arg1)
		self.label_tip_desc:setString(localizable.ui_borderShow_type_9_desc)
	end

	--整理内容	
	local typeSize = self.label_type:getContentSize()
	local playerSize = self.label_player:getContentSize()
	local nameSize = self.label_name:getContentSize()
	local descSize = self.label_tip_desc:getContentSize()

	local ptx,pty = self.label_type:getPosition()
	self.label_player:setPosition(ccp(ptx + typeSize.width + 3, pty))
	ptx,pty = self.label_player:getPosition()	
	self.label_name:setPosition(ccp(ptx + playerSize.width + 3,pty))
	ptx,pty = self.label_name:getPosition()
	self.label_tip_desc:setPosition(ccp(ptx + nameSize.width + 3,pty))
	--文字长度
	self.m_informRect = CCSizeMake(typeSize.width + playerSize.width + nameSize.width + descSize.width + 9, self.size.height)
end

function moveTextNode(self)
	--公告移动
	local move = CCMoveBy:create(1.5, ccp(-100, 0))
	local array = CCArray:create()
	array:addObject(move)
	array:addObject(CCDelayTime:create(1.5))
	local forever = CCRepeatForever:create(CCSequence:create(array))
	self.label_tip_desc:runAction(forever)
end

function onNodeCleanup(self)
    layer_base_t.onNodeCleanup(self)
end