--descriptioin:活动充值翻倍
--company: xckoo
--author: litao
--date: 2014-10-30
---------------------------------------------
require("config/firstpurchase_config")
require("ui_layer/ui_purchaseLayer")
require("ui_layer/ui_purchaseTableCell")

module("ui_randPayLayer", package.seeall)
baseClass(layer_base_t, ui_randPayLayer)

function init(self)
	self.contentNode_ = GetActivityView():GetNodeContent()
	self.contentSize_ = self.contentNode_:getContentSize()

	local ccbiAttrTable = {name="activity/RandPayView.ccbi", size=self.contentSize_}
	layer_base_t.init(self, true, ccbiAttrTable)

	--用户info
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	--活动剩余时间
	self.m_resttime = 0
	--倍数数据列表
	self.m_datas = {}
	--活动状态(0关闭、1开启)
	self.m_state = 0
	--时间增量
	self.deltatime = 0
	--转盘一次消耗元宝数
	self.m_gold_one_rand = 0
	--roll一次是否结束标志
	self.bRandOver = true
	--
	self.m_awardType = 0

	self:init_ui()
	self:init_binding_event()
end


function init_ui(self)
	--初始化界面信息
	if self.proxy_ ~= nil then
		self.spr_rand = tolua.cast(self.proxy_:getNode("spr_rand"), "CCSprite")
		self.spr_start = tolua.cast(self.proxy_:getNode("spr_start"), "CCSprite")
		self.spr_free = tolua.cast(self.proxy_:getNode("spr_free"), "CCSprite")
		self.btn_pay = tolua.cast(self.proxy_:getNode("btn_pay"), "CCControlButton")
		self.label_cur_muti = tolua.cast(self.proxy_:getNode("label_cur_muti"), "CCLabelBMFont")
		self.label_resttime = tolua.cast(self.proxy_:getNode("label_resttime"), "CCLabelTTF")
		self.label_desc = tolua.cast(self.proxy_:getNode("label_desc"), "CCLabelTTF")
		self.label_cost = tolua.cast(self.proxy_:getNode("label_cost"), "CCLabelTTF")
		for i=1,6 do
			self["label_"..i] = tolua.cast(self.proxy_:getNode("label_"..tostring(i)), "CCLabelBMFont")
			self["spr_light_"..i] = tolua.cast(self.proxy_:getNode("spr_light_"..tostring(i)), "CCSprite")
		end

		--测试数据
		--self:createTestData()
		self:requestBaseInfo()

		self.label_desc:setString(localizable.ui_randPay_tips2)
		self.label_desc:setColor(ccc3(0,255,0))

		--点击选择呼吸动画
		--[[
		local move = CCScaleBy:create(0.3, 1.1)
		local array = CCArray:create()
		array:addObject(move)
		array:addObject(move:reverse())
		array:addObject(move)
		array:addObject(move:reverse())
		array:addObject(CCDelayTime:create(1.5))
		local forever = CCRepeatForever:create(CCSequence:create(array))
		self.label_desc:runAction(forever)
		--]]
	end
end

function requestBaseInfo(self)
	local function updateLeftTimeLabel(fDeltaTime)
		self.deltatime = self.deltatime + fDeltaTime
		if self.deltatime >= 1 then
			local intPart, floatPart = math.modf(self.deltatime)
			self.m_resttime = self.m_resttime - intPart
			if self.m_resttime > 0 then
				local timeStr = tools.convertTimeElectronicWatch(self.m_resttime, 3)
				self.label_resttime:setString(timeStr)
				self.deltatime = floatPart
			else
				self.m_state = 0--(0关闭、1开启)
				self:init_ui_ext()
				self.label_resttime:unscheduleUpdate()
			end
		end
	end
	---[[
	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 1, "rl_r_multiple_pay")
	--urlpath = "http://203.195.181.162:8080/rl_w_guaguale?Cmd=1701&Uid=80021&Session=962954F5D722633016FF458E22920C29&Clinettime=2013/10/22%2021:56:17%20Tuesday&Platform=win32&Version=1.0.0&Pt=3&Area=2"
	--cclog("rl_r_multiple_pay222----%s", urlpath)

	GetMainMenu():ShowLoadingDlg()
	CCHttpRequest:open(urlpath, kHttpPost, "query=param1&other=params"):sendWithHandler(
		function(res, hnd)
			GetMainMenu():CloseLoadding();
			local resData = res:getResponseData()
			local code = res:getResponseCode()
			local xfile = xml.parse(resData)
			local item = xfile:find("RENLONG")
			if item == nil then
				--cclog("CGI : rl_r_multiple_pay is down!")
				return nil
			end
			local retcode = item.code
			if retcode == "0" then					
				local info = item:find("info")
				--剩余时间
				self.m_resttime = tonumber(info:find("remain")[1])
				--获取roll点元宝消耗
				self.m_gold_one_rand = tonumber(info:find("cost")[1])
				if self.m_gold_one_rand > 0 then
					self.spr_free:setVisible(false)
					self.label_cost:setVisible(true)
					self.label_cost:setString(string.format(localizable.ui_randPay_tips4, self.m_gold_one_rand))
				else
					self.spr_free:setVisible(true)
					self.label_cost:setVisible(false)
				end
				--已有倍数
				self.multiple = tonumber(info:find("multiple")[1])

				--获取翻倍信息
				local itemList = item:find("mutiples")
				if itemList then
					self.m_datas = {}
					for i = 1, #itemList do
						local item = {}
						item.id = itemList[i].id
						item.multiple = itemList[i].multiple
						table.insert(self.m_datas, item)
					end
				end
				--找到对应的type
				for i = 1,#self.m_datas do
					self["label_"..i]:setString(self.m_datas[i].multiple * 0.1)
					if self.multiple == tonumber(self.m_datas[i].multiple) then
						self.m_awardType = tonumber(self.m_datas[i].id)

						self["spr_light_"..i]:setVisible(true)
						self.spr_rand:setRotation((self.m_awardType-1)*60)
					else
						self["spr_light_"..i]:setVisible(false)
					end
				end

				--实时更新活动时间(0关闭、1开启)
				if self.m_resttime > 0 then
					self.m_state = 1
					self.label_resttime:scheduleUpdateWithPriorityLua(updateLeftTimeLabel, 0)
					self.label_resttime:setString(tools.convertTimeElectronicWatch(self.m_resttime, 3))
				else
					self.m_state = 0
					self.label_resttime:setString(localizable.ui_monopoly_end)
				end

				--显示活动时间信息
				self:init_ui_ext()
			else
				self.label_resttime:setString(localizable.ui_monopoly_end)
				--找到对应的type
				for i = 1,6 do
					self["label_"..i]:setString(0)
					self["spr_light_"..i]:setVisible(false)
				end
				self.label_cur_muti:setString(0)
				GetMainMenu():ShowTextTip(localizable.ui_monopoly_not_start,-1)
			end
		end)
	--]]
end

function init_ui_ext(self)
	if tonumber(self.multiple) == 1 then
		self.label_cur_muti:setString(1)
	else
		self.label_cur_muti:setString(self.multiple * 0.1)
	end
end

function refreshData(self)
	self:requestBaseInfo()
end

function playRandAnim(self)
	if self.m_awardType <= 0 then
		self.bRandOver = true
		return nil
	else
		for i = 1,#self.m_datas do
			self["spr_light_"..i]:setVisible(false)
		end	
	end
	--play anim
	self.spr_rand:setRotation(0)
	local move1 = CCRotateBy:create(0.3,360*1)
	local move2 = CCRotateBy:create(0.4,360*1)
	local move3 = CCRotateBy:create(0.5,360*1)
	
	local array = CCArray:create()
	array:addObject(move1)
	array:addObject(move2)
	array:addObject(move3)

	local t_move
	if self.m_awardType > 3 then 
		local move4 = CCRotateBy:create(0.6,360*1)--CCRotateBy:create((self.m_awardType-1)*0.15,(self.m_awardType-1)*60)
		array:addObject(move4)

		for i = 2, self.m_awardType do
			if self.m_awardType - i  > 2 then
				t_move = CCRotateBy:create(0.15, 60)
			else
				t_move = CCRotateBy:create((2 + i - self.m_awardType)*0.2 + 0.15, 60)
			end
			array:addObject(t_move)
		end
	else
		for i = 2, self.m_awardType + 6 do
			if self.m_awardType + 6 - i  > 2 then
				t_move = CCRotateBy:create(0.15, 60)
			else
				t_move = CCRotateBy:create((2 + i - self.m_awardType - 6)*0.2 + 0.15, 60)
			end
			array:addObject(t_move)
		end
	end
	local function updateIsOver()
		--
		for i = 1,#self.m_datas do
			if self.m_awardType == tonumber(self.m_datas[i].id) then
				self["spr_light_"..i]:setVisible(true)
				self.label_cur_muti:setString(self.multiple * 0.1)
			else
				self["spr_light_"..i]:setVisible(false)
			end
		end	
		self.bRandOver = true
		self.m_awardType = 0
	end
	local callfunc = CCCallFuncN:create(updateIsOver)
	array:addObject(callfunc)
	local forever = CCSequence:create(array)
	self.spr_rand:runAction(forever)	
end

function init_binding_event(self)
	if self.proxy_ ~= nil then
		--dice
		local function onBtnRand(btn)
			--判断活动状态(0关闭、1开启)
			if self.m_state == 0 then
				GetMainMenu():ShowTextTip(localizable.ui_monopoly_not_start,-1)
				return nil
			end

			--判断是否Roll完
			if not self.bRandOver then
				GetMainMenu():ShowTextTip(localizable.ui_randPay_tips3,-1)
				return nil
			end

			local function startRequestRand()
				--扣除元宝并更新
				if self.playerData_.m_gold < self.m_gold_one_rand then
					--提示购买元宝
					GetMainMenu():ShowTextTip(localizable.ui_monopoly_gold_not_enough,-1)
					--通用付费引导
					local prePayLayer = createObj(ui_commonPrePay)
					GetMainMenu():GetModelLayer():AddDialog(prePayLayer.node_, 3)
					return nil
				end

				---[[
				local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 2, "rl_r_multiple_pay")
				--cclog("rl_r_multiple_pay---222----%s", urlpath)
				GetMainMenu():ShowLoadingDlg()
				CCHttpRequest:open(urlpath, kHttpPost, "query=param1&other=params"):sendWithHandler(
					function(res, hnd)
						GetMainMenu():CloseLoadding();
						local resData = res:getResponseData()
						local code = res:getResponseCode()
						local xfile = xml.parse(resData)
						local item = xfile:find("RENLONG")
						if item ==  nil then
							--cclog("CGI : rl_r_multiple_pay is down!")
							return nil
						end
						local retcode = item.code
						if retcode == "0" then
							cclog("rl_r_multiple_pay & cmd = 2-----%s", resData)
							--扣除元宝
							self.playerMgr_:AddGold(-self.m_gold_one_rand)
							self.playerData_ = self.playerMgr_:GetPlayerInfoData()
							--获取roll的倍数
							local info = item:find("info")
							if info then
								self.m_gold_one_rand = tonumber(info:find("cost")[1])
								if self.m_gold_one_rand > 0 then
									self.spr_free:setVisible(false)
									self.label_cost:setVisible(true)
									self.label_cost:setString(string.format(localizable.ui_randPay_tips4, self.m_gold_one_rand))
								else
									self.spr_free:setVisible(true)
									self.label_cost:setVisible(false)
								end
								self.multiple = tonumber(info:find("multiple")[1])
								for i = 1,#self.m_datas do
									if self.multiple == tonumber(self.m_datas[i].multiple) then
										self.m_awardType = tonumber(self.m_datas[i].id)
									end
								end				
							end
								
							--playRandAnim
							self.bRandOver = false
							self:playRandAnim()								
						else
							--Roll完一次以后，更新标志
							self.bRandOver = true						
							GetMainMenu():ShowErrorTip(tonumber(retcode), -1)
						end
					end)
				--]]
			end

			--标准框
			local dlg = CommonDialogView.create()
			CommonDialogView.m_selfview = dlg
			dlg:SetTitle(localizable.ui_monopoly_title)
			local showContent = string.format(localizable.ui_randPay_tips1, tostring(self.m_gold_one_rand))
			dlg:SetDescription(showContent)
			dlg:loadCCBI()
			dlg:initUI()
			dlg:SetConfirmHandler(startRequestRand)
			GetMainMenu():GetModelLayer():AddDialog(dlg, 3)				
		end

		local function onBtnPay(btn)
			--前往充值
			---[[
			local puchaseLayer = createObj(ui_purchaseLayer, self)
			GetMainMenu():GetModelLayer():AddDialog(puchaseLayer.node_, 3)
			--]]
		end

		--屏蔽掉后层触摸事件
		local function CCLayerTouch(event, x, y)
			local rect = self.node_:boundingBox()
			rect.origin = ccp(0,0)
			local p = self.node_:convertToNodeSpace(ccp(x,y))			
			--截获界面内后层的信息
			if rect:containsPoint(p) == true then
				if event == "began" then
					--判断区域	
					local spr_rect = self.spr_start:boundingBox()			
					if spr_rect:containsPoint(p) == true then				
						onBtnRand()
					end
				 	return true
				end
			else
				return false
			end		
		end

		self.node_:setTouchEnabled(true)
		self.node_:registerScriptTouchHandler(CCLayerTouch, false, kCCMenuHandlerPriority - 1, true)

		self.btn_pay:setTouchPriority(kCCMenuHandlerPriority - 1)
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
	---
end