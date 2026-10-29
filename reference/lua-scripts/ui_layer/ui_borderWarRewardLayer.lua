--边界碑游荡奖励
--litao
--2014-2-17
---------------------------------------------
module("ui_borderWarRewardLayer", package.seeall)
baseClass(layer_base_t, ui_borderWarRewardLayer)

function init(self, node, currentScore)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	local winSize = CCDirector:sharedDirector():getWinSize()

	--Load res
	local ccbiAttrTable = {name="activity/BorderWarRewardView.ccbi", size=CCSizeMake(768, winSize.height)}
	layer_base_t.init(self, true, ccbiAttrTable)

	self.preNode = node
	--当前积分
	self.m_currentScore = 0
	--状态信息数据
	self.m_rewardDatas = {}
	--奖励信息列表
	self.m_rewardItemList = {}
	--领取获取物品列表
	self.m_getAwardlist = {}

	self:init_ui()
	self:init_binding_event()
end


function init_ui(self)
	if self.proxy_ ~= nil then
		--领奖Btn
		self.btnGetAward = tolua.cast(self.proxy_:getNode("reward_getRewardBtn"), "CCControlButton")
		--关闭按钮
		self.btnDialogClose = tolua.cast(self.proxy_:getNode("closeButton"), "CCControlButton")
		--
		self.label_time = tolua.cast(self.proxy_:getNode("reward_time"), "CCLabelTTF")
		self.node_desc_2 = tolua.cast(self.proxy_:getNode("reward_node_2"), "CCNode")
		self.nodeCountryIcon = tolua.cast(self.proxy_:getNode("reward_iconNode"), "CCNode")
		self.label_name = tolua.cast(self.proxy_:getNode("reward_name"), "CCLabelTTF")
		self.label_attackType = tolua.cast(self.proxy_:getNode("reward_attackType"), "CCLabelTTF")
		self.label_exp = tolua.cast(self.proxy_:getNode("reward_expLabel"), "CCLabelTTF")
		self.label_score = tolua.cast(self.proxy_:getNode("reward_scoreLabel"), "CCLabelTTF")
		self.node_desc_2:setVisible(false)
		--是否领取
		self.label_getLabel = tolua.cast(self.proxy_:getNode("reward_getLabel"), "CCLabelTTF")
		self.label_haveGetLabel = tolua.cast(self.proxy_:getNode("reward_haveGetLabel"), "CCLabelTTF")
		self.label_getLabel:setVisible(true)
		self.label_haveGetLabel:setVisible(false)
		
		---[[
		--获取信息
		local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 2, "rl_r_frontiers_war_award_info")
		urlpath = AddData(urlpath, "Country", self.playerData_.m_countrytype)
		--cclog("rl_r_frontiers_war_award_info----%s", urlpath)
		GetMainMenu():ShowLoadingDlg()
		CCHttpRequest:open(urlpath, kHttpPost,"query=param1&other=params"):sendWithHandler(
			function(res, hnd)
				GetMainMenu():CloseLoadding()
				local resData = res:getResponseData()
				local code = res:getResponseCode()
				local xfile = xml.parse(resData)
				local item = xfile:find("RENLONG")
				local retcode = item.code
				--cclog("rl_r_frontiers_war_award_info----%s", resData)
				if retcode == "0" then
					local awardItem = item:find("award")
					if awardItem then
						local time = tonumber(awardItem.alive_time)
						self.label_time:setString(tostring(time))
						self.label_exp:setString(tostring(awardItem.exp))
						self.label_score:setString(tostring(awardItem.power))

						if time >= 8 then
							self.node_desc_2:setVisible(false)
						else
							self.node_desc_2:setVisible(true)
							local d_type = tonumber(awardItem.destory_type)
							if d_type == 1 then
								self.label_attackType:setString(localizable.ui_border_provoke)
							else
								self.label_attackType:setString(localizable.ui_border_wander)
							end 
							self.label_name:setString(tostring(awardItem.enemy_nick))

							--0-4 风雷水火土
							CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile("com_res/Resident.plist")
							local countryIconId = tonumber(awardItem.enemy_country)
							local countryIconName
							if countryIconId == 0 then
								countryIconName = tostring("com_icon_country_Wind")
							elseif countryIconId == 1 then
								countryIconName = tostring("com_icon_country_Mine")
							elseif countryIconId == 2 then
								countryIconName = tostring("com_icon_country_Water")
							elseif countryIconId == 3 then
								countryIconName = tostring("com_icon_country_Fire")
							elseif countryIconId == 4 then
								countryIconName = tostring("com_icon_country_Earth")
							end

							local pFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(countryIconName)
							if pFrame ~= nil then
								local pIcon = CCSprite:createWithSpriteFrame(pFrame)
								local size = self.nodeCountryIcon:getContentSize()
								if pIcon ~= nil then
									self.nodeCountryIcon:addChild(pIcon)
									pIcon:setPosition(ccp(size.width/2, size.height/2))
									pIcon:setAnchorPoint(ccp(0.5, 0.5))
								end
							end
						end
					end
				elseif retcode == "4" then
					self.label_getLabel:setVisible(false)
					self.label_haveGetLabel:setVisible(true)
				else
					GetMainMenu():ShowErrorTip(tostring(retcode), -1)
				end
			end)
		--]]		
	end
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
					return false
				end
			end
			return true
		end
		self.node_:setTouchEnabled(true)
		self.node_:registerScriptTouchHandler(CCLayerTouch, false, kCCMenuHandlerPriority - 1, true)

		local function onBtnGetAward(btn)
			CSoundMgr:instance():PlayEffect(SOUND_BUTTON)
			---[[得到边境奖励
			local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 2, "rl_r_frontiers_war_recv_award")
			
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
						--cclog("rl_r_frontiers_war_recv_award--ret--%s", resData)
						local award = item:find("award")
						if award then
							local exp = tonumber(award:find("exp")[1])
							local merit = tonumber(award:find("merit")[1])
							self.playerMgr_:AddExp(exp)
							self.playerMgr_:AddMerit(merit)

							self.playerData_ = self.playerMgr_:GetPlayerInfoData()
							GetMainMenu():ShowTextTip(localizable.ui_border_get_gift_success,-1)

							--领取成功则关掉当前界面
							self:updateMainInfo()
							self.node_:removeFromParentAndCleanup(true)
						end						
					elseif retcode == "329009" then
						GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
					else
						--GetMainMenu():ShowTextTip("奖励领取失败!",-1)
						GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
					end
				end)
		end

		--绑定按钮事件
		local function close_window(btn, event)
			self:updateMainInfo()
			self.node_:removeFromParentAndCleanup(true)
		end

		self.btnGetAward:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.proxy_:handleButtonEvent(self.btnGetAward, onBtnGetAward, CCControlEventTouchUpInside)

		self.btnDialogClose:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.proxy_:handleControlEvent(self.btnDialogClose, close_window, CCControlEventTouchUpInside)
	end
end

function updateMainInfo(self)
	self.preNode:startRequestCountryInfo(self.preNode.m_curCountryId)
	self.preNode:startRequestPlayerInfo()

	self.preNode.label_gold:setString(tostring(self.playerData_.m_gold))
	self.preNode.label_silver:setString(tostring(self.playerData_.m_silver))
end

function onNodeCleanup(self)
    --cclog("onNodeCleanup")
    if self.proxy_ then
    	self.proxy_:release()
    end
    layer_base_t.onNodeCleanup(self)
end

function createTestData(self)
	return nil
end