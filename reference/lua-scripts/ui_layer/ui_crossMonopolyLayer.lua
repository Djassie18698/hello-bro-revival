--descriptioin:跨服大富翁
--company: xckoo
--author: litao
--date: 2014-08-25
---------------------------------------------
module("ui_crossMonopolyLayer", package.seeall)
baseClass(layer_base_t, ui_crossMonopolyLayer)

function init(self)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	--如果期数不同，更新期数
	if activityPeriod.monopoly.display == -1 then
		writeActivityData(self.playerData_.m_uid, activity_config.activityTipConfig.monopoly, activityPeriod.monopoly.period)
	end

	self.contentSize_ = GetMainMenu():GetSubContentNode():getContentSize()

	local ccbiAttrTable = {name="activity/MonopolyViewForCross.ccbi", size=self.contentSize_}
	layer_base_t.init(self, true, ccbiAttrTable)

	--活动剩余时间
	self.m_resttime = 0
	--剩余免费次数
	self.m_freetimes = 0
	--20个格子物品列表
	self.m_itemlist = {}
	--掷骰子获取物品列表
	self.m_awardlist = {}
	--奖励物品索引(1-20也可以作为骰子的路径)
	self.m_rewardIdx = -1
	--活动状态(0开启、1结束)
	self.m_state = 0
	--时间增量
	self.deltatime = 0
	--购买一次消耗元宝数
	self.m_gold_one_dice = 0
	--roll一次是否结束标志
	self.bRollOver = true
	--当前步数
	self.m_currentItemIndex = 1
	--目标步数
	self.m_targetNumber = 0
	--从服务器获取的随机投掷点数
	self.rollStep = 0
	--ten times
	self.bTenTimes = false

	self.m_currentScore = 0	
	self.m_one_shoot = true

	self:init_ui()
	self:init_binding_event()
end


function init_ui(self)
	--初始化界面信息
	if self.proxy_ ~= nil then
		self.label_gold = tolua.cast(self.proxy_:getNode("label_gold"), "CCLabelBMFont")
		self.label_silver = tolua.cast(self.proxy_:getNode("label_silver"), "CCLabelBMFont")
		self.label_lefttime_desc = tolua.cast(self.proxy_:getNode("label_lefttime_desc"), "CCLabelTTF")
		self.label_lefttime = tolua.cast(self.proxy_:getNode("label_lefttime"), "CCLabelBMFont")
		self.label_end_desc = tolua.cast(self.proxy_:getNode("label_end_desc"), "CCLabelTTF")
		self.btn_rank = tolua.cast(self.proxy_:getNode("btn_rank"), "CCControlButton")
		self.btn_dice = tolua.cast(self.proxy_:getNode("btn_dice"), "CCControlButton")
		self.btn_back = tolua.cast(self.proxy_:getNode("btn_back"), "CCControlButton")
		self.btn_dice_icon = tolua.cast(self.proxy_:getNode("btn_dice_icon"), "CCSprite")
		self.btn_light_icon = tolua.cast(self.proxy_:getNode("btn_light_icon"), "CCSprite")
		--btn
		self.btn_roll_ten_times = tolua.cast(self.proxy_:getNode("btn_roll_tentimes"), "CCControlButton")

		self.btn_dice_icon:setVisible(false)
		self.btn_light_icon:setVisible(false)

		self.label_gold:setString(tostring(self.playerData_.m_gold))
		self.label_silver:setString(tostring(self.playerData_.m_silver))

		if activityPeriod.monopoly.display == 1 then
			self.btn_rank:removeChildByTag(100,true);
			local bk = CCSprite:createWithSpriteFrameName("com_tip_icon");
			self.btn_rank:addChild(bk);
			local rect = self.btn_rank:boundingBox();
			bk:setPosition(ccp(rect.size.width*0.95,rect.size.height*0.85));
			bk:setTag(100)
		end

		for i=1,20 do
			self["btn_icon" .. tostring(i)] = tolua.cast(self.proxy_:getNode("btn_icon" .. tostring(i)), "CCControlButton")	
			self["label_num_".. tostring(i)] = tolua.cast(self.proxy_:getNode("label_num_".. tostring(i)), "CCLabelBMFont")			
		end

		--骰子呼吸
		local move = CCScaleBy:create(0.2, 1.1)
		local array = CCArray:create()
		array:addObject(move)
		array:addObject(move:reverse())
		array:addObject(move)
		array:addObject(move:reverse())
		array:addObject(CCDelayTime:create(1.5))
		local forever = CCRepeatForever:create(CCSequence:create(array))
		self.btn_dice:runAction(forever)

		local function updateLeftTimeLabel(fDeltaTime)
			self.deltatime = self.deltatime + fDeltaTime
			if self.deltatime >= 1 then
				local intPart, floatPart = math.modf(self.deltatime)
				self.m_resttime = self.m_resttime - intPart
				if self.m_resttime > 0 then
					local timeStr = tools.convertTimeElectronicWatch(self.m_resttime, 3)
					self.label_lefttime:setString(timeStr)
					self.deltatime = floatPart
				else
					self.m_state = 1
					self:init_ui_ext()
					self.label_lefttime:unscheduleUpdate()
				end
			end
		end

		--测试数据
		--self:createTestData()

		---[[
		local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 1, "rl_r_monopoly_info")
		--urlpath = "http://203.195.181.162:8080/rl_w_guaguale?Cmd=1701&Uid=80021&Session=962954F5D722633016FF458E22920C29&Clinettime=2013/10/22%2021:56:17%20Tuesday&Platform=win32&Version=1.0.0&Pt=3&Area=2"
		--AddData(urlpath, "m_type", 3)
		--cclog("mono222----%s", urlpath)

		GetMainMenu():ShowLoadingDlg()
		CCHttpRequest:open(urlpath, kHttpPost, "query=param1&other=params"):sendWithHandler(
			function(res, hnd)
				GetMainMenu():CloseLoadding();
				local resData = res:getResponseData()
				local code = res:getResponseCode()
				local xfile = xml.parse(resData)
				local item = xfile:find("RENLONG")
				if item == nil then
					--cclog("CGI : rl_r_monopoly_info is down!")
					return nil
				end
				local retcode = item.code
				if retcode == "0" then					
					local itemInfo = item:find("basic_info")
					--剩余时间
					self.m_resttime = tonumber(itemInfo:find("remaining_time")[1])
					--获取roll点元宝消耗
					self.m_gold_one_dice = tonumber(item:find("cost_cash")[1])
					if self.m_gold_one_dice < 0 then
						self.m_gold_one_dice = 0
					end

					--获取20个格子的图片信息
					local itemCellList = item:find("cell_list")
					if itemCellList then
						self.m_totalItemCount = 20 --#itemCellList
						for i = 1, #itemCellList do
							local item = {}
							item.id = itemCellList[i].id
							item.icon = itemCellList[i].icon
							table.insert(self.m_itemlist, item)
						end
					end

					--标记上次的位置
					self.m_currentItemIndex = tonumber(itemInfo:find("cell_index")[1])
					if self.m_currentItemIndex < 1 then 
						self.m_currentItemIndex = 1
					end

					--报文出错时直接关活动
					if #self.m_itemlist < 20 then
						--cclog("icon count : m_itemlist = %d", #self.m_itemlist)
						self.m_state = 1
						self.m_resttime = -1
						self.label_lefttime:setString(localizable.ui_monopoly_end)
						return nil
					end

					--实时更新活动时间
					if self.m_resttime > 0 then
						self.m_state = 0
						self.label_lefttime:scheduleUpdateWithPriorityLua(updateLeftTimeLabel, 0)
						self.label_lefttime:setString(tools.convertTimeElectronicWatch(self.m_resttime, 3))
					else
						self.m_state = 1
						self.label_lefttime:setString(localizable.ui_monopoly_end)
					end

					--先固定写20个
					for i = 1, 20 do
						self["sprite_icon_" .. tostring(i)] = tolua.cast(self.proxy_:getNode("sprite_icon_" .. tostring(i)), "CCSprite")
						self["sprite_hl_" .. tostring(i)] = tolua.cast(self.proxy_:getNode("sprite_hl_" .. tostring(i)), "CCSprite")
						CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile("props/" .. self.m_itemlist[i].icon .. ".plist")
						local pFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(self.m_itemlist[i].icon)
						if pFrame ~= nil then
							local pIcon = CCSprite:createWithSpriteFrame(pFrame);
							local size = self["sprite_icon_" .. tostring(i)]:getContentSize()
							if pIcon ~= nil then
								self["sprite_icon_" .. tostring(i)]:addChild(pIcon)
								pIcon:setPosition(ccp(size.width/2, size.height/2))
								pIcon:setAnchorPoint(ccp(0.5, 0.5))
							end
						end
						--显示item数量_litao_2014.7.8
						local _drop_info = {}
						_drop_info.mainType, _drop_info.subType, _drop_info.toId, _drop_info.num = setObjTypeInfo(self.m_itemlist[i].id)
						if _drop_info.num > 1 then
							self["label_num_"..tostring(i)]:setVisible(true)
							self["label_num_"..tostring(i)]:setString(_drop_info.num)
						else
							self["label_num_"..tostring(i)]:setVisible(false)
						end
					end

					--显示活动时间信息
					self:init_ui_ext()
				else
					self.label_lefttime:setString(localizable.ui_monopoly_end)
					GetMainMenu():ShowTextTip(localizable.ui_monopoly_not_start,-1)
				end
			end)
		--]]
	end
end

function init_ui_ext(self)
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()
	self.label_gold:setString(tostring(self.playerData_.m_gold))
	self.label_silver:setString(tostring(self.playerData_.m_silver))

	for i = 1, self.m_totalItemCount do
		self:unhighlightItem(i)
	end

	self:updateFreeTimes()

	if self.m_resttime > 0 then
		self.label_lefttime_desc:setVisible(false)
		self.label_lefttime:setVisible(true)
		self.label_end_desc:setVisible(false)
	else
		self.label_lefttime_desc:setVisible(false)
		self.label_lefttime:setVisible(false)
		self.label_end_desc:setVisible(true)
	end

	--高亮当前位置
	self:highlightTargetItem(self.m_currentItemIndex)
end

function highlightItem(self, index)
	if index < 1 and index > self.m_totalItemCount then
		return
	end
	self["sprite_hl_" .. tostring(index)]:setVisible(true)
end

function unhighlightItem(self, index)
	if index < 1 and index > self.m_totalItemCount then
		return
	end
	self["sprite_hl_" .. tostring(index)]:setVisible(false)
end

--更新免费投掷次数
function updateFreeTimes(self)
	--[[
	if self.m_freetimes > 0 then
		self.label_free:setVisible(true)
		self.label_gold_once:setVisible(false)
		self.label_gold_desc:setVisible(false)
	else
		self.label_free:setVisible(false)
		self.label_gold_once:setVisible(true)
		self.label_gold_desc:setVisible(true)
	end
	--]]
end

function init_binding_event(self)
	if self.proxy_ ~= nil then
		--dice
		local function onBtnRollOnce(btn)
			--litao_限制刷小号_等级限制_2014.6.24
			local _playerData_ = CPlayerDataMgr:instance():GetPlayerInfoData()
			--get info from table_bin
			local config_info_level = DataMgr.GetDataByID("Struct_Functionconfig", 14)
			--判断等级
			if nil ~= config_info_level then 
			    if _playerData_.m_level < tonumber(config_info_level.m_needlevel) then
					GetMainMenu():ShowTextTip(tostring(config_info_level.m_tipinfo), -1)
					return nil
				end
			end
			--判断活动状态
			if self.m_state == 1 then
				GetMainMenu():ShowTextTip(localizable.ui_monopoly_not_start,-1)
				return nil
			end

			local function startRequestDice()
				--扣除元宝并更新
				if self.playerData_.m_gold < self.m_gold_one_dice then
					--提示购买元宝
					GetMainMenu():ShowTextTip(localizable.ui_monopoly_gold_not_enough,-1)
					--通用付费引导
					local prePayLayer = createObj(ui_commonPrePay)
					GetMainMenu():GetModelLayer():AddDialog(prePayLayer.node_, 3)
					return nil
				end
				--判断是否Roll完
				if not self.bRollOver then
					return nil
				else
					self.bRollOver = false
				end
				--准备播放dice动画
				---[[
				local diceIconSize = self.btn_dice_icon:getContentSize()
				self.m_diceAnimLayer = createObj(ui_monopolyDiceAnim, diceIconSize)

				self.btn_dice_icon:addChild(self.m_diceAnimLayer.node_)

				self.m_diceAnimLayer.node_:setPosition(ccp(diceIconSize.width / 2, diceIconSize.height / 2))
				self.m_diceAnimLayer.node_:setAnchorPoint(ccp(0.5, 0.5))

				self.btn_dice_icon:setVisible(true)
				--]]

				local function playDiceAnim()
					if self.m_diceAnimLayer then
						self.m_diceAnimLayer.node_:removeFromParentAndCleanup(true)
					end

					--从服务器获取骰子点数、奖励列表
					---[[
					local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 1, "rl_w_monopoly_roll")
					--cclog("mono_dice222----%s", urlpath)
					GetMainMenu():ShowLoadingDlg()
					CCHttpRequest:open(urlpath, kHttpPost, "query=param1&other=params"):sendWithHandler(
						function(res, hnd)
							GetMainMenu():CloseLoadding();
							local resData = res:getResponseData()
							local code = res:getResponseCode()
							local xfile = xml.parse(resData)
							local item = xfile:find("RENLONG")
							if item ==  nil then
								--cclog("CGI : rl_w_monopoly_roll is down!")
								return nil
							end
							local retcode = item.code
							if retcode == "0" then
								--扣除元宝
								self.playerMgr_:AddGold(-self.m_gold_one_dice)
								self.playerData_ = self.playerMgr_:GetPlayerInfoData()
								self.label_gold:setString(tostring(self.playerData_.m_gold))
								self.label_silver:setString(tostring(self.playerData_.m_silver))
								--获取roll的点数
								self.rollStep = tonumber(item:find("dice")[1])
								--cclog("rollStep = %d", self.rollStep)
								if self.rollStep <= 0 or self.rollStep > 3 then 
									self.rollStep = 1
								end	
								--设置目标cell位置
								self.m_targetNumber = self.m_currentItemIndex + self.rollStep				

								--奖励列表
								local itemList = item:find("reward_list")

								if itemList then
									self.m_awardlist = {}
									for i = 1, 1 do
										local awardXml = itemList[i]:find("award")
										if awardXml then
											self.m_awardXml = {}
											self.m_awardXml = awardXml

											local rewarddata = FightReward:new()
											InitAwardData(rewarddata, awardXml)
											local tmpItem = {}
											tmpItem.resultdata = rewarddata
											table.insert(self.m_awardlist, tmpItem)	
										end							
									end
								end
									
								--显示投掷的点数
								if self.pIcon then
									self.pIcon:removeFromParentAndCleanup(true)
								end										
								CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile("ccbResources/dice_1.plist")
								local nowStep = self.rollStep + 6
								local pFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("dice_0"..nowStep)
								if pFrame ~= nil then
									self.pIcon = CCSprite:createWithSpriteFrame(pFrame);
									local size = self.btn_dice_icon:getContentSize()
									if self.pIcon ~= nil then
										self.btn_dice_icon:addChild(self.pIcon)
										self.pIcon:setPosition(ccp(size.width/2, size.height/2))
										self.pIcon:setAnchorPoint(ccp(0.5, 0.5))	
										self.pIcon:setVisible(true)	
									end								
								end	

								--playLightAnim
								self:playLightAnim()								
							else
								--背包已满、高亮当前格子
								self.m_targetNumber = self.m_currentItemIndex
								self:highlightTargetItem(self.m_targetNumber)
								--重新显示骰子	
								self.btn_dice:setVisible(true)	
								--Roll完一次以后，更新标志
								self.bRollOver = true						
								GetMainMenu():ShowErrorTip(tonumber(retcode), -1)
							end
						end)
					--]]	
				end

				local ccArray = CCArray:create()
			    --ccArray:addObject(CCDelayTime:create(0.56))
			    ccArray:addObject(CCCallFuncN:create(playDiceAnim))
				local sequen = CCSequence:create(ccArray)  

			    --播放动画
				self.btn_dice:setVisible(false)		    
				self.node_:runAction(sequen)
			end

			--标准框
			local dlg = CommonDialogView.create()
			CommonDialogView.m_selfview = dlg
			dlg:SetTitle(localizable.ui_monopoly_title)
			local showContent = string.format(localizable.ui_monopoly_tips1, tostring(self.m_gold_one_dice))
			dlg:SetDescription(showContent)
			dlg:loadCCBI()
			dlg:initUI()
			dlg:SetConfirmHandler(startRequestDice)
			GetMainMenu():GetModelLayer():AddDialog(dlg, 3)				
		end

		local function onBtnRollTenTimes(btn)
			--litao_限制刷小号_等级限制_2014.6.24
			local _playerData_ = CPlayerDataMgr:instance():GetPlayerInfoData()
			--get info from table_bin
			local config_info_level = DataMgr.GetDataByID("Struct_Functionconfig", 14)
			--判断等级
			if nil ~= config_info_level then 
			    if _playerData_.m_level < tonumber(config_info_level.m_needlevel) then
					GetMainMenu():ShowTextTip(tostring(config_info_level.m_tipinfo), -1)
					return nil
				end
			end
			--
			if self.bTenTimes == true then
				GetMainMenu():ShowTextTip(localizable.ui_monopoly_tips2,-1)
				return nil
			end
			--判断活动状态
			if self.m_state == 1 then
				GetMainMenu():ShowTextTip(localizable.ui_monopoly_not_start,-1)
				return nil
			end

			local function startRequestDiceTenTimes()
				--扣除元宝并更新
				if self.playerData_.m_gold < tonumber(self.m_gold_one_dice * 10) then
					--提示购买元宝
					GetMainMenu():ShowTextTip(localizable.ui_monopoly_gold_not_enough,-1)
					--通用付费引导
					local prePayLayer = createObj(ui_commonPrePay)
					GetMainMenu():GetModelLayer():AddDialog(prePayLayer.node_, 3)
					return nil
				end

				--判断是否Roll完
				if not self.bRollOver then
					return nil
				else
					self.bRollOver = false
				end

				--准备播放dice动画
				---[[
				local diceIconSize = self.btn_dice_icon:getContentSize()
				self.m_diceAnimLayer = createObj(ui_monopolyDiceAnim, diceIconSize)

				self.btn_dice_icon:addChild(self.m_diceAnimLayer.node_)

				self.m_diceAnimLayer.node_:setPosition(ccp(diceIconSize.width / 2, diceIconSize.height / 2))
				self.m_diceAnimLayer.node_:setAnchorPoint(ccp(0.5, 0.5))

				self.btn_dice_icon:setVisible(true)
				--]]

				local function playTenDiceAnim()
					if self.m_diceAnimLayer then
						self.m_diceAnimLayer.node_:removeFromParentAndCleanup(true)
					end

					--从服务器获取骰子点数、奖励列表
					---[[
					local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 2, "rl_w_monopoly_roll")
					--cclog("mono_dice222----%s", urlpath)
					GetMainMenu():ShowLoadingDlg()
					CCHttpRequest:open(urlpath, kHttpPost, "query=param1&other=params"):sendWithHandler(
						function(res, hnd)
							GetMainMenu():CloseLoadding();
							local resData = res:getResponseData()
							local code = res:getResponseCode()
							local xfile = xml.parse(resData)
							local item = xfile:find("RENLONG")
							if item ==  nil then
								--cclog("CGI : rl_w_monopoly_roll is down!")
								return nil
							end
							local retcode = item.code
							if retcode == "0" then
								--扣除元宝
								self.playerMgr_:AddGold(-tonumber(self.m_gold_one_dice * 10))
								self.playerData_ = self.playerMgr_:GetPlayerInfoData()
								self.label_gold:setString(tostring(self.playerData_.m_gold))
								self.label_silver:setString(tostring(self.playerData_.m_silver))
								--tentimes is success
								self.bTenTimes = true
								--获取roll的点数
								self.rollStep = tonumber(item:find("dice")[1])
								--cclog("rollStep = %d", self.rollStep)
	
								--设置目标cell位置
								--self.m_targetNumber = self.m_currentItemIndex + self.rollStep				

								--奖励列表
								local itemList = item:find("reward_list")

								if itemList then
									self.m_awardlist = {}
									for i = 1, #itemList do
										local awardXml = itemList[i]:find("award")
										if awardXml then
											local rewarddata = FightReward:new()
											InitAwardData(rewarddata, awardXml)
											local tmpItem = {}
											tmpItem.dropid = tonumber(awardXml.dropid)
											tmpItem.resultdata = rewarddata
											tmpItem.rewardId = tonumber(itemList[i]:find("cell_index")[1])
											if i == #itemList then
												--self.m_targetNumber = tonumber(item:find("cell_index")[1])
												self.m_targetNumber = tonumber(itemList[i]:find("cell_index")[1])	
												--cclog("2222-----cell_index = %d", self.m_targetNumber)	
											end
											table.insert(self.m_awardlist, tmpItem)	
										end							
									end
								end
									
								--显示投掷的点数
								if #self.m_awardlist > 1 then
									local resultView = tolua.cast(CRouletteTurnResultDialogView:create(), "CRouletteTurnResultDialogView")
									resultView:ClearAwardList()
									for i = 1, #self.m_awardlist do
										local turnId = tonumber(self.m_awardlist[i].rewardId)
										local itemInfo = ItemDataInfo:new()
										self.playerMgr_:AddDataFromReward(self.m_awardlist[i].resultdata)
										CGameObjElement:GetInfoFromDropId(self.m_awardlist[i].resultdata, itemInfo)
										itemInfo.dropid = tonumber(self.m_awardlist[i].dropid)
										if itemInfo.mainType ~= 1 then
											itemInfo.quality = 5
											itemInfo.icon = self.m_itemlist[turnId].icon
										end
										
										resultView:PushAward(itemInfo)
									end
									resultView:startRun()
									GetMainMenu():AddDialog(resultView)
								end

								--playLightAnim
								self:playLightAnim()								
							else
								--背包已满、高亮当前格子
								self.m_targetNumber = self.m_currentItemIndex
								self:highlightTargetItem(self.m_targetNumber)
								--重新显示骰子	
								self.btn_dice:setVisible(true)	
								--Roll完一次以后，更新标志
								self.bRollOver = true	
								self.bTenTimes = false						
								GetMainMenu():ShowErrorTip(tonumber(retcode), -1)
							end
						end)
					--]]	
				end

				local ccArray = CCArray:create()
			    ccArray:addObject(CCDelayTime:create(0.56))
			    ccArray:addObject(CCCallFuncN:create(playTenDiceAnim))
				local sequen = CCSequence:create(ccArray)  

			    --播放动画
				--self.btn_dice:setVisible(false)		    
				self.node_:runAction(sequen)
			end

			--标准框
			local dlg = CommonDialogView.create()
			CommonDialogView.m_selfview = dlg
			dlg:SetTitle(localizable.ui_monopoly_title)
			local showContent = string.format(localizable.ui_monopoly_tips1, tostring(self.m_gold_one_dice * 10))
			dlg:SetDescription(showContent)
			dlg:loadCCBI()
			dlg:initUI()
			dlg:SetConfirmHandler(startRequestDiceTenTimes)
			GetMainMenu():GetModelLayer():AddDialog(dlg, 3)				
		end

		local function onBtnRank(btn)
			local rankLayer = createObj(ui_crossMonopolyRandkLayer, self, self.m_currentScore)
			local size1 = GetMainMenu():GetModelLayer():getContentSize()
			rankLayer.node_:setAnchorPoint(ccp(0.5, 0.5))

			rankLayer.node_:setPosition(size1.width / 2, size1.height / 2)
			GetMainMenu():GetModelLayer():addChild(rankLayer.node_)
		end

		local function onBtnBack(btn)
			GetMainMenu():ChangeToSub(E_DEFAULTMENU)
		end

		--[[
		local function CCLayerTouch(event, x, y)
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
		end	
		self.node_:setTouchEnabled(true)
		self.node_:registerScriptTouchHandler(CCLayerTouch)
		--]]

		local function onBtnClickIcon(btn)
			CSoundMgr:instance():PlayEffect(SOUND_BUTTON)
			local btnIndex = btn:getTag()

			if btnIndex > 0 and btnIndex <= 20 then
				local _id_icon = tonumber(self.m_itemlist[btnIndex].id)
				if nil ~= _id_icon then
					CGameObjElement:ShowDropByID(_id_icon)
				end
			end
		end

		--判断是否点击格子
		for i = 1, 20 do
			self.proxy_:handleButtonEvent(self["btn_icon" .. tostring(i)], function(button, event)
				onBtnClickIcon(button)
				return nil
			end, CCControlEventTouchUpInside)
		end

		--self.btn_dice:setTouchPriority(kCCMenuHandlerPriority - 2)
		--self.btn_dice:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btn_dice, function(button, event)
			onBtnRollOnce(button)
			return nil
		end, CCControlEventTouchUpInside)

		--roll tentimes_2014.4.21_litao
		self.proxy_:handleButtonEvent(self.btn_roll_ten_times, function(button, event)
			onBtnRollTenTimes(button)
			return nil
		end, CCControlEventTouchUpInside)

		--self.btn_rank:setTouchPriority(kCCMenuHandlerPriority - 2)
		--self.btn_rank:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btn_rank, function(button, event)
			onBtnRank(button)
			return nil
		end, CCControlEventTouchDown)

		--self.btn_back:setTouchPriority(kCCMenuHandlerPriority - 2)
		--self.btn_back:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btn_back, function(button, event)
			onBtnBack(button)
			return nil
		end, CCControlEventTouchDown)

	end
end

---[[
function playLightAnim(self)
	--播放light动画
	---[[	
	local lightIconSize = self.btn_light_icon:getContentSize()					
	self.m_diceLightLayer = createObj(ui_monopolyLightAnim, lightIconSize)

	self.btn_light_icon:addChild(self.m_diceLightLayer.node_)

	self.m_diceLightLayer.node_:setPosition(ccp(lightIconSize.width / 2, lightIconSize.height / 2))
	self.m_diceLightLayer.node_:setAnchorPoint(ccp(0.5, 0.5))

	self.btn_light_icon:setVisible(true)
	--]]

	local function playStepAction()
		if self.m_diceLightLayer then
			self.m_diceLightLayer.node_:removeFromParentAndCleanup(true)
		end

		--放大缩小动画
		--
		--光标移动
		if not self.bTenTimes then
			self:doRoll(self.m_targetNumber)
		else
			--当前步数大于总步数时，调整目
			--cclog("lightact_cur = %d, tar = %d", self.m_currentItemIndex, self.m_targetNumber)
			if self.m_targetNumber >= self.m_totalItemCount then				
				self.m_targetNumber = self.m_targetNumber % self.m_totalItemCount
				--恰好整除的情况
				if 0 == self.m_targetNumber then
					self.m_targetNumber = 20
				end
			end
			self.m_currentItemIndex = self.m_targetNumber
			self:doRollEnd()
		end
	end

	local ccArray = CCArray:create()
	if not self.bTenTimes then 
    	ccArray:addObject(CCDelayTime:create(1.5))
    end
    ccArray:addObject(CCCallFuncN:create(playStepAction))
	local sequen = CCSequence:create(ccArray)  

    --播放动画
	self.btn_dice:setVisible(false)		    
	self.node_:runAction(sequen)	
end
--]]

---[[
function doRoll(self, targetNumber)
	--高亮与否
	self:doRollAction()
end
--]]

function doRollAction(self)
	--新修改,到底目标位置
	if self.m_currentItemIndex >= self.m_targetNumber and math.abs(self.m_currentItemIndex - self.m_targetNumber) < 15 then
		self:highlightTargetItem(self.m_targetNumber)
		self:doRollEnd()
	elseif self.m_currentItemIndex < self.m_targetNumber then--正常情况,没转圈
		self:highlightTargetItem(self.m_currentItemIndex)
		self.m_currentItemIndex = self.m_currentItemIndex + 1
		self:nextItem()
	elseif self.m_currentItemIndex > self.m_targetNumber and math.abs(self.m_currentItemIndex - self.m_targetNumber) >= 15 then
		--需要转圈
		self.m_currentItemIndex = self.m_currentItemIndex + 1
		--当前格子超过总数
		if self.m_currentItemIndex > self.m_totalItemCount then
			self.m_currentItemIndex = 1
		end
		self:highlightTargetItem(self.m_currentItemIndex)
		--[[
		if self.m_currentItemIndex > self.m_totalItemCount then
			self.m_currentItemIndex = 1
			--当前步数大于总步数时，循环调整，目标步数也跟着调整
			if self.m_targetNumber > self.m_totalItemCount then
				self.m_targetNumber = self.m_targetNumber % self.m_totalItemCount
				--恰好整除的情况
				if 0 == self.m_targetNumber then
					self.m_targetNumber = 20
				end
				self.m_currentItemIndex = self.m_targetNumber			
				--self.m_targetNumber = self.m_targetNumber - self.m_totalItemCount
			end
		end
		--]]
		self:nextItem()
	end
end

function doRollEnd(self)
	if self.m_currentItemIndex < 1 then
		self.m_currentItemIndex = 1
	end
	local size = self["sprite_hl_" .. tostring(self.m_currentItemIndex)]:getContentSize()

	self.m_hlLayer = createObj(ui_rouletteBingo, size)
	self.m_hlLayer.node_:setAnchorPoint(ccp(0.5, 0.5))
	self.m_hlLayer.node_:setPosition(size.width / 2, size.height / 2)

	self["sprite_hl_" .. tostring(self.m_currentItemIndex)]:addChild(self.m_hlLayer.node_)

	local function showBox()
		self:unhighlightAllItem()
		if self.m_hlLayer then
			self.m_hlLayer.node_:removeFromParentAndCleanup(true)
		end

		--隐藏投掷的点数
		if nil ~= self.pIcon then
			self.pIcon:setVisible(false)
		end
		self.btn_dice_icon:setVisible(false)
		self.btn_light_icon:setVisible(false)
		--展示、获取奖品(普通转的时候)
		--cclog("mono1111---%s", self.m_awardXml)
		if not self.bTenTimes then
			ShowAward(self.m_awardXml)
		else
			self.bTenTimes = false
		end

		--将奖励加入信息表
		--self.playerMgr_:AddDataFromReward(self.m_awardlist[1].resultdata)
		self.playerMgr_ = CPlayerDataMgr:instance()
		self.playerData_ = self.playerMgr_:GetPlayerInfoData()

		self.label_gold:setString(tostring(self.playerData_.m_gold))
		self.label_silver:setString(tostring(self.playerData_.m_silver))

		--Roll完一次以后，高亮当前格子
		self:highlightTargetItem(self.m_targetNumber)

		--重新显示骰子	
		self.btn_dice:setVisible(true)	
		--Roll完一次以后，更新标志
		self.bRollOver = true
		--cclog("end_cur = %d, tar = %d", self.m_currentItemIndex, self.m_targetNumber)
	end
	local ccArray = CCArray:create()
	if not self.bTenTimes then
    	ccArray:addObject(CCDelayTime:create(2))
    end
    ccArray:addObject(CCCallFuncN:create(showBox))
    local sequen = CCSequence:create(ccArray)
	self.node_:runAction(sequen)
end

function nextItem(self)
	--i表示前进时间
	local i = 0.4

	local function doRollAction1()
		if self.m_currentItemIndex >= self.m_targetNumber then
			self:highlightTargetItem(self.m_targetNumber)
			self:doRollEnd()
		else
			self:highlightTargetItem(self.m_currentItemIndex);
			self.m_currentItemIndex = self.m_currentItemIndex + 1

			if self.m_currentItemIndex > self.m_totalItemCount then
				self.m_currentItemIndex = 1
				--当前步数大于总步数时，循环调整，目标步数也跟着调整
				if self.m_targetNumber > self.m_totalItemCount then
					self.m_targetNumber = self.m_targetNumber - self.m_totalItemCount
				end
			end
			self:nextItem()
		end
	end

	local ccArray = CCArray:create()
    ccArray:addObject(CCDelayTime:create(i))
    ccArray:addObject(CCCallFuncN:create(doRollAction1))
    local sequen = CCSequence:create(ccArray)
	self.node_:runAction(sequen)

end

function highlightTargetItem(self, target)
	for i = 1, self.m_totalItemCount do
		if target ~= i then
			self:unhighlightItem(i)
		else
			self:highlightItem(i)
		end
	end
end

function unhighlightAllItem(self)
	for i = 1, self.m_totalItemCount do
		self:unhighlightItem(i)
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
	for i=1,20 do
		local itemNode = {}
		itemNode.name = "一乐拉面(小)*2"
		itemNode.icon = "props_016"
		itemNode.id = 481
		self.m_itemlist[i] = itemNode
	end

	for i = 1, 20 do
		self["sprite_icon_" .. tostring(i)] = tolua.cast(self.proxy_:getNode("sprite_icon_" .. tostring(i)), "CCSprite")
		self["sprite_hl_" .. tostring(i)] = tolua.cast(self.proxy_:getNode("sprite_hl_" .. tostring(i)), "CCSprite")
		CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile("props/" .. self.m_itemlist[i].icon .. ".plist")
		local pFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(self.m_itemlist[i].icon)
		if pFrame ~= nil then
			local pIcon = CCSprite:createWithSpriteFrame(pFrame);
			local size = self["sprite_icon_" .. tostring(i)]:getContentSize()
			if pIcon ~= nil then
				self["sprite_icon_" .. tostring(i)]:addChild(pIcon)
				pIcon:setPosition(ccp(size.width/2, size.height/2))
				pIcon:setAnchorPoint(ccp(0.5, 0.5))
			end
		end
	end

	self.m_totalItemCount = 20

	self:init_ui_ext()
end