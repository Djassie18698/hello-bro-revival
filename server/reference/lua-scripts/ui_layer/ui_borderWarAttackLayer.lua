--边界碑挑衅、游荡
--litao
--2014-2-17
---------------------------------------------
module("ui_borderWarAttackLayer", package.seeall)
baseClass(layer_base_t, ui_borderWarAttackLayer)

function init(self, node, data)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	local winSize = CCDirector:sharedDirector():getWinSize()

	--Load res
	local ccbiAttrTable = {name="activity/BorderWarAttackView.ccbi", size=CCSizeMake(768, winSize.height)}
	layer_base_t.init(self, true, ccbiAttrTable)

	self.preNode = node
	--当前数据
	self.m_attackData = data
	--奖励
	self.exp = 0
	self.merit = 0

	self:init_ui()
	self:init_binding_event()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		--ok
		self.btnOk = tolua.cast(self.proxy_:getNode("attack_ok"), "CCControlButton")
		--关闭按钮
		self.btnDialogClose = tolua.cast(self.proxy_:getNode("closeButton"), "CCControlButton")
		self.btnClose = tolua.cast(self.proxy_:getNode("attack_close"), "CCControlButton")
		--label
		self.label_gold = tolua.cast(self.proxy_:getNode("attack_goldLabel"), "CCLabelTTF")
		self.label_type_1 = tolua.cast(self.proxy_:getNode("attack_typeLabel_1"), "CCLabelTTF")
		self.label_type_2 = tolua.cast(self.proxy_:getNode("attack_typeLabel_2"), "CCLabelTTF")
		self.label_time = tolua.cast(self.proxy_:getNode("attack_timeLabel"), "CCLabelTTF")
		self.label_exp = tolua.cast(self.proxy_:getNode("attack_expLabel"), "CCLabelTTF")
		self.label_merit = tolua.cast(self.proxy_:getNode("attack_scoreLabel"), "CCLabelTTF")
		self.label_blood = tolua.cast(self.proxy_:getNode("attack_bloodLabel"), "CCLabelTTF")
		self.label_round = tolua.cast(self.proxy_:getNode("attack_roundLabel"), "CCLabelTTF")	

		--initUI
		self:init_ui_info()	
	end
end

function init_ui_info(self)
	if self.m_attackData == nil then
		self:removeFromParentAndCleanup(true)
		return nil
	end

	local timeOnceText = tools.convertTimeElectronicWatchChinese(tonumber(self.m_attackData.endTime), 3)
	self.label_time:setString(timeOnceText)
	self.label_exp:setString(self.m_attackData.exp)
	self.label_merit:setString(self.m_attackData.merit)
	--
	self.label_blood:setString(self.m_attackData.blood)
	self.label_round:setString(self.m_attackData.round)
	
	if self.m_attackData.attackType == 1 then
		self.label_gold:setString(self.m_attackData.gold..localizable.ui_border_gold)
		self.label_type_1:setString(localizable.ui_border_provoke)
		self.label_type_2:setString(localizable.ui_border_provoke)
	else
		self.label_gold:setString(self.m_attackData.gold..localizable.ui_border_silver)
		self.label_type_1:setString(localizable.ui_border_wander)
		self.label_type_2:setString(localizable.ui_border_wander)		
	end
end

function update_gold(self, attackType)
	--扣除元宝并更新
	if attackType == 1 then 
		self.playerMgr_:AddGold(-self.m_attackData.gold)
		
	else
		self.playerMgr_:AddSilver(-self.m_attackData.gold)
	end
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()
end

function showNoticeTip(self, attackType)
	local m_noticeDatas = {}
	m_noticeDatas.countryId = self.playerData_.m_countrytype
	m_noticeDatas.nameText = self.playerData_.m_name
	m_noticeDatas.toNameText = tostring("||")
	m_noticeDatas.toCountryId = self.m_attackData.toCountryId
	m_noticeDatas.attackType =  attackType
	--show attack tip	
	local tipLayer = createObj(ui_borderWarShowAttackTip, m_noticeDatas)
	local size1 = GetMainMenu():GetModelLayer():getContentSize()
	tipLayer.node_:setAnchorPoint(ccp(0.5, 0.5))

	tipLayer.node_:setPosition(ccp(size1.width / 2, size1.height * 0.72))
	GetMainMenu():GetModelLayer():addChild(tipLayer.node_)
end 

function startRequestAttack(self)
	--攻击类型错误
	if self.m_attackData.attackType < 1 or self.m_attackData.attackType > 2 then
		--边境碑暂时不能被攻击/攻击边界碑失败
		GetMainMenu():ShowErrorTip(tonumber(329016),-1)
		self:removeFromParentAndCleanup(true)
		return nil
	end

	--请求
	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, self.m_attackData.attackType, "rl_r_frontiers_war_attack")
	urlpath = AddData(urlpath, "ToCountry", self.m_attackData.toCountryId)
	urlpath = AddData(urlpath, "Country", self.playerData_.m_countrytype)

	--cclog("startRequestAtttack----%s", urlpath)
	GetMainMenu():ShowLoadingDlg()
	CCHttpRequest:open(urlpath, kHttpPost, "query=param1&other=params"):sendWithHandler(
		function(res, hnd)
			GetMainMenu():CloseLoadding()
			local resData = res:getResponseData()
			local code = res:getResponseCode()
			local xfile = xml.parse(resData)
			local item = xfile:find("RENLONG")
			if item == nil then
				--cclog("CGI : rl_r_frontiers_war_attack is down!")
				return nil
			end
			--cclog("rl_r_frontiers_war_attack...ret...!%s", resData)
			local retcode = item.code
			if retcode == "0" then										
				--正常攻击
				self:update_gold(self.m_attackData.attackType)
				self:showNoticeTip(self.m_attackData.attackType)

				self:updateMainInfo()

				self.node_:removeFromParentAndCleanup(true)
			elseif retcode == "329018" then
				--元宝不足
				GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
				--通用付费引导
				local prePayLayer = createObj(ui_commonPrePay)
				GetMainMenu():GetModelLayer():AddDialog(prePayLayer.node_, 3)
				self.node_:removeFromParentAndCleanup(true)
			elseif retcode == "329017" then
				--该国边界碑已被摧毁
				GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
				self.node_:removeFromParentAndCleanup(true)
			elseif retcode == "329020" then
				---[[
				--有奖励
				--切换攻击目标
				local basicInfo = item:find("basic")					
				local infoCountry = tonumber(basicInfo:find("country")[1])
				local infoState = tonumber(basicInfo:find("status")[1])
				local isAward = tonumber(basicInfo:find("has_award")[1])
				local infoTime = tonumber(basicInfo:find("min_time")[1])

				local timeText = tools.convertSecToStr(infoTime, true)
				local showContent = nil
				local descText_1 = nil
				local stateText = nil

				if infoState == 1 then
					stateText = tostring(localizable.ui_border_provoke)
				else
					stateText = tostring(localizable.ui_border_wander)
				end
				local countryText = self.preNode:retCountryText(infoCountry, 1)
				local curCountryText = self.preNode:retCountryText(self.m_attackData.toCountryId, 1)
				
				if isAward == 1 then
					local awardInfo = item:find("award")
					self.exp = tonumber(awardInfo:find("exp")[1])
					self.merit = tonumber(awardInfo:find("merit")[1])						
					--showContent = tostring("你已在"..countryText.."边境"..stateText..timeText..".\n可获得如下奖励:")						
					--descText_1 = tostring("确定要[保留]奖励并"..stateText.."["..curCountryText.."]吗?")
					showContent = string.format(localizable.ui_border_tips1, countryText, stateText..timeText)						
					descText_1 = string.format(localizable.ui_border_tips2, stateText, curCountryText)
				else
					--showContent = tostring("你已在"..countryText.."边境"..stateText..timeText..".\n时间不足无法获得奖励:")						
					--descText_1 = tostring("确定要"..stateText..curCountryText.."吗?")
					showContent = string.format(localizable.ui_border_tips3, countryText, stateText..timeText)						
					descText_1 = string.format(localizable.ui_border_tips4, stateText, curCountryText)
				end

				--显示转换确认窗口窗口
				--信息
				local tempData = {}
				tempData.title = localizable.ui_border_title
				tempData.descText = showContent
				tempData.descText_1 = descText_1
				tempData.exp = self.exp
				tempData.merit = self.merit
				tempData.attackType = self.m_attackData.attackType
				tempData.toCountryId = self.m_attackData.toCountryId
				tempData.gold = self.m_attackData.gold
				--界面
				local layer = createObj(ui_borderWarChangeAttackDlg, self.preNode, tempData)
				local size1 = GetMainMenu():GetModelLayer():getContentSize()
				layer.node_:setAnchorPoint(ccp(0.5, 0.5))
				layer.node_:setPosition(ccp(size1.width * 0.5, size1.height * 0.5))
				GetMainMenu():GetModelLayer():addChild(layer.node_)	
				--关掉当前窗口
				self.node_:removeFromParentAndCleanup(true)
				--]]
			elseif retcode == "329012" or recode == "329013" then
				--已经在攻击此国家
				GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
				self.node_:removeFromParentAndCleanup(true)
			else
				--
				GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
			end
		end)
end

function updateMainInfo(self)
	self.preNode:startRequestCountryInfo(self.preNode.m_curCountryId)
	self.preNode:startRequestPlayerInfo()

	self.preNode.label_gold:setString(tostring(self.playerData_.m_gold))
	self.preNode.label_silver:setString(tostring(self.playerData_.m_silver))
end

function init_binding_event(self)
	if self.proxy_ ~= nil then
		local function CCLayerTouch(event,x,y)
			local rect = self.node_:boundingBox()
			rect.origin = ccp(0,0)
			local p = self.node_:convertToNodeSpace(ccp(x,y))
			if event == "began" then
				if rect:containsPoint(p) == true then
					return true
				else
					return true
				end
			end
		end
		self.node_:setTouchEnabled(true)
		self.node_:registerScriptTouchHandler(CCLayerTouch, false, kCCMenuHandlerPriority - 1, true)

		local function close_window(btn, event)
			self.node_:removeFromParentAndCleanup(true)
		end

		local function onBtnOK(btn)
			CSoundMgr:instance():PlayEffect(SOUND_BUTTON)
				--扣除元宝并更新
			if self.m_attackData.attackType == 1 then 
				if self.playerData_.m_gold < self.m_attackData.gold then
					--提示购买元宝
					GetMainMenu():ShowErrorTip(tonumber(329018),-1)
					--通用付费引导
					local prePayLayer = createObj(ui_commonPrePay)
					GetMainMenu():GetModelLayer():AddDialog(prePayLayer.node_, 3)
					self.node_:removeFromParentAndCleanup(true)
					return nil
				end
			else
				if self.playerData_.m_silver < self.m_attackData.gold then
					--提示购买银票
					GetMainMenu():ShowErrorTip(tonumber(329019),-1)
					self.node_:removeFromParentAndCleanup(true)
					return nil
				end
			end
			self:startRequestAttack()			
		end

		--绑定按钮事件
		self.btnOk:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.proxy_:handleButtonEvent(self.btnOk, onBtnOK, CCControlEventTouchUpInside)

		self.btnDialogClose:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.proxy_:handleControlEvent(self.btnDialogClose, close_window, CCControlEventTouchUpInside)

		self.btnClose:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.proxy_:handleControlEvent(self.btnClose, close_window, CCControlEventTouchUpInside)
	end
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