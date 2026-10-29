--descriptioin:主界面活动按钮
--company: xckoo
--author: chenchun
--date: 2013-1-9

--注意：所有加进去的活动界面，必须先设置tag 为 1002。。

---------------------------------------------
module("ui_mainActivityBtn",  package.seeall)
baseClass(layer_base_t, ui_mainActivityBtn)

function init(self, btnTag)
	local ccbiAttrTable = {name="activity/MainActivityBtn.ccbi", size=CCSize(81, 81)}
	layer_base_t.init(self, true, ccbiAttrTable)
	self.btnTag = btnTag
	self.time = 0
	self.deltatime = 0
	self:init_ui()
end

function init_ui(self)
	local data = mainMenuActivityConfigData[self.btnTag]
	local function btnActivity(btn)
		loadstring(mainMenuActivityConfigData[btn:getTag()].script)()
	end

	local function updateTime( delta )
		self.deltatime = self.deltatime + delta
		if self.deltatime >= 1 then
			local intPart, floatPart = math.modf(self.deltatime)
			self.time = self.time - intPart
			if self.time > 0 then
				local timeStr = tools.convertTimeElectronicWatch(self.time, 3)
				self.labelTime:setString(timeStr)
				self.deltatime = floatPart
			else -- 计时结束
				self.labelTime:unscheduleUpdate()
				if data.callback then
					data.callback()
				end
			end
		end
	end
	if self.proxy_ ~= nil then
		self.btnActivity = tolua.cast(self.proxy_:getNode("btnActivity"), "CCControlButton")
		local sprite_icon = CCSprite:create(mainMenuActivityConfigData[self.btnTag].btnImg)
		local spriteFrame = sprite_icon:displayFrame()

		self.sprite_notify = tolua.cast(self.proxy_:getNode("sprite_notify"), "CCSprite")
		if mainMenuActivityConfigData[self.btnTag].display ~= 0 then
			self.sprite_notify:setVisible(true)
		else
			self.sprite_notify:setVisible(false)
		end

		self.btnActivity:setBackgroundSpriteFrameForState(spriteFrame, CCControlStateNormal)
		self.btnActivity:setBackgroundSpriteFrameForState(spriteFrame, CCControlStateHighlighted)
		self.btnActivity:setBackgroundSpriteFrameForState(spriteFrame, CCControlStateDisabled)

		self.btnActivity:setTag(self.btnTag)
		self.proxy_:handleControlEvent(self.btnActivity, btnActivity, CCControlEventTouchUpInside)

		self.labelTime = tolua.cast(self.proxy_:getNode("label_time"),"CCLabelTTF")
		
		if data.bShowTime and data.time ~= nil then
			self.time = data.time
			if self.time > 0 then
				self.labelTime:scheduleUpdateWithPriorityLua(updateTime,0)
				self.labelTime:setVisible(true)
				local timeStr = tools.convertTimeElectronicWatch(self.time, 3)
				self.labelTime:setString(timeStr)
			else
				self.labelTime:unscheduleUpdate()
			end
		else
			self.labelTime:setVisible(false)
		end
	end
end

function refreshTips()
	if mainMenuActivityConfigData[self.btnTag].display ~= 0 then
		self.sprite_notify:setVisible(true)
	else
		self.sprite_notify:setVisible(false)
	end
end

function onNodeCleanup(self)
	if self.proxy_ then
    	self.proxy_:release()
    end
    layer_base_t.onNodeCleanup(self)
end
