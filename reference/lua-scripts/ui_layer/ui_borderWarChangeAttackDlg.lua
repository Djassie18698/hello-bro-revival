--边界碑切换攻击目标确认框
--litao
--2014-2-17
---------------------------------------------
module("ui_borderWarChangeAttackDlg", package.seeall)
baseClass(layer_base_t, ui_borderWarChangeAttackDlg)

function init(self, node, data)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	local winSize = CCDirector:sharedDirector():getWinSize()

	--Load res
	local ccbiAttrTable = {name="activity/BorderWarAttackView.ccbi", size=CCSizeMake(768, winSize.height)}
	layer_base_t.init(self, true, ccbiAttrTable)

	self.preNode = node
	--数据
	self.m_attackData = data

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
		--node
		self.node_1 = tolua.cast(self.proxy_:getNode("attack_node_1"), "CCNode")
		self.node_2 = tolua.cast(self.proxy_:getNode("attack_node_2"), "CCNode")
		self.node_3 = tolua.cast(self.proxy_:getNode("attack_node_3"), "CCNode")
		--label
		self.label_desc = tolua.cast(self.proxy_:getNode("label_desc"), "CCLabelTTF")
		self.label_exp = tolua.cast(self.proxy_:getNode("attack_expLabel"), "CCLabelTTF")
		self.label_merit = tolua.cast(self.proxy_:getNode("attack_scoreLabel"), "CCLabelTTF")
		self.label_title = tolua.cast(self.proxy_:getNode("titleLabel"), "CCLabelTTF")
		self.label_desc2 = tolua.cast(self.proxy_:getNode("label_desc2"), "CCLabelTTF")

		--initUI
		self:init_ui_info()	
	end
end

function init_ui_info(self)
	self.node_1:setVisible(false)
	self.node_2:setVisible(false)
	self.node_3:setVisible(false)

	self.label_desc:setVisible(true)
	self.label_desc:setString(tostring(self.m_attackData.descText))
	self.label_exp:setString(tostring(self.m_attackData.exp))
	self.label_merit:setString(tostring(self.m_attackData.merit))
	self.label_title:setString(tostring(self.m_attackData.title))
	self.label_desc2:setString(tostring(self.m_attackData.descText_1))
	self.label_desc2:setVisible(true)
end

function setChangeAttackCountry(self)
	--请求
	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, self.m_attackData.attackType, "rl_r_frontiers_war_attack")
	urlpath = AddData(urlpath, "ToCountry", tonumber(self.m_attackData.toCountryId))
	urlpath = AddData(urlpath, "Country", self.playerData_.m_countrytype)
	urlpath = AddData(urlpath, "Switch", 1)
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
			--cclog("rl_r_frontiers_war_attack...报文!%s", resData)
			local retcode = item.code
			if retcode == "0" then	
				--正常攻击
				self:update_gold(self.m_attackData.attackType)
				self:showNoticeTip(self.m_attackData.attackType)
				--[[
				--领奖
				self.playerMgr_:AddExp(self.m_attackData.exp)
				self.playerMgr_:AddMerit(self.m_attackData.merit)	
				--]]
				--更新主界面信息
				self:updateMainInfo()
			else
				--该国边界碑暂时无法攻击
				GetMainMenu():ShowErrorTip(tonumber(retcode),-1)									
			end
		end)
end

function update_gold(self, attackType)
	--扣除元宝并更新
	if tonumber(attackType) == 1 then 
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

		local function onBtnOK(btn, event)
			self:setChangeAttackCountry()
			self.node_:removeFromParentAndCleanup(true)
		end

		local function close_window(btn, event)
			self.node_:removeFromParentAndCleanup(true)
		end

		--绑定按钮事件
		self.btnOk:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.proxy_:handleControlEvent(self.btnOk, onBtnOK, CCControlEventTouchUpInside)

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