--descriptioin:跨服大转盘
--company: xckoo
--author: litao
--date: 2014-08-25
---------------------------------------------
require "util/common"

module("ui_crossRouletteLayer", package.seeall)
baseClass(layer_base_t, ui_crossRouletteLayer)

function init(self)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	--如果期数不同，更新期数
	if activityPeriod.roulette.display == -1 then
		writeActivityData(self.playerData_.m_uid, activity_config.activityTipConfig.roulette, activityPeriod.roulette.period)
	end

	self.contentSize_ = GetMainMenu():GetSubContentNode():getContentSize()

	local ccbiAttrTable = {name="activity/RouletteViewForCross.ccbi", size=self.contentSize_}
	layer_base_t.init(self, true, ccbiAttrTable)

	--self:createTestData()
	self.m_resttime = 0
	self.m_score_once = 10
	self.m_super_award = 0
	self.m_freetimes = 0
	self.m_currentScore = 0
	self.m_gold_one_shoot = 100
	self.m_itemlist = {}
	self.m_one_shoot = true
	self.deltatime = 0
	self.m_awardlist = {}
	self.m_rewardIdx = 1
	self.m_state = 0
	self:init_ui()
	self:init_binding_event()
end


function init_ui(self)
	if self.proxy_ ~= nil then
		self.label_gold = tolua.cast(self.proxy_:getNode("label_gold"), "CCLabelBMFont")
		self.label_silver = tolua.cast(self.proxy_:getNode("label_silver"), "CCLabelBMFont")
		self.label_score = tolua.cast(self.proxy_:getNode("label_score"), "CCLabelTTF")
		self.aaa = tolua.cast(self.proxy_:getNode("aaa"), "CCLabelTTF")
		self.label_free = tolua.cast(self.proxy_:getNode("label_free"), "CCLabelTTF")
		self.label_gold_once = tolua.cast(self.proxy_:getNode("label_gold_once"), "CCLabelTTF")
		self.label_gold_desc = tolua.cast(self.proxy_:getNode("label_gold_desc"), "CCLabelTTF")
		self.label_aaa_desc = tolua.cast(self.proxy_:getNode("label_aaa_desc"), "CCLabelTTF")
		self.label_end_desc = tolua.cast(self.proxy_:getNode("label_end_desc"), "CCLabelTTF")
		self.label_super_award = tolua.cast(self.proxy_:getNode("label_super_award"), "CCLabelBMFont")
		self.btn_roll_once = tolua.cast(self.proxy_:getNode("btn_roll_once"), "CCControlButton")
		self.btn_rank = tolua.cast(self.proxy_:getNode("btn_rank"), "CCControlButton")
		self.btn_roll_tentimes = tolua.cast(self.proxy_:getNode("btn_roll_tentimes"), "CCControlButton")
		self.label_left_roll = tolua.cast(self.proxy_:getNode("label_left_roll"), "CCLabelTTF")
		self.btn_back = tolua.cast(self.proxy_:getNode("btn_back"), "CCControlButton")

		self.label_gold:setString(tostring(self.playerData_.m_gold))
		self.label_silver:setString(tostring(self.playerData_.m_silver))
		self.label_score:setString(tostring(self.m_score_once))
		self.label_left_roll:setString("10")
		
		for i=1,12 do
			self["btn_card" .. tostring(i)] = tolua.cast(self.proxy_:getNode("btn_card" .. tostring(i)), "CCControlButton")
			self["label_num_"..tostring(i)] = tolua.cast(self.proxy_:getNode("label_num_"..tostring(i)), "CCLabelBMFont")
		end

		if activityPeriod.roulette.display == 1 then
			self.btn_rank:removeChildByTag(100,true);
			local bk = CCSprite:createWithSpriteFrameName("com_tip_icon");
			self.btn_rank:addChild(bk);
			local rect = self.btn_rank:boundingBox();
			bk:setPosition(ccp(rect.size.width*0.95,rect.size.height*0.85));
			bk:setTag(100)
		end

		local function updateLeftTimeLabel(fDeltaTime)
			self.deltatime = self.deltatime + fDeltaTime
			if self.deltatime >= 1 then
				local intPart, floatPart = math.modf(self.deltatime)
				self.m_resttime = self.m_resttime - intPart
				if self.m_resttime > 0 then
					local timeStr = tools.convertTimeElectronicWatchChinese(self.m_resttime, 3)
					self.aaa:setString(timeStr)
					self.deltatime = floatPart
				else
					self.aaa:setVisible(false)
					self.label_aaa_desc:setVisible(false)
					self.label_end_desc:setVisible(true)
					self.aaa:unscheduleUpdate()
				end
			end
		end

		local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, protocol.ROULETTE_R_LOADINFO, protocol.URL_R_ROULETTE)
		--urlpath = "http://203.195.181.162:8080/rl_w_guaguale?Cmd=1701&Uid=80021&Session=962954F5D722633016FF458E22920C29&Clinettime=2013/10/22%2021:56:17%20Tuesday&Platform=win32&Version=1.0.0&Pt=3&Area=2"
		--AddData(urlpath, "m_type", 3)

		GetMainMenu():ShowLoadingDlg()
		CCHttpRequest:open(urlpath, kHttpPost, "query=param1&other=params"):sendWithHandler(
			function(res, hnd)
				GetMainMenu():CloseLoadding();
				local resData = res:getResponseData()
				local code = res:getResponseCode()
				local xfile = xml.parse(resData)
				local item = xfile:find("RENLONG")
				local retcode = item.code
				if retcode == "0" then
					local itemInfo = item:find("info")
					self.m_resttime = tonumber(itemInfo:find("lasttime")[1])
					self.m_score_once = tonumber(itemInfo:find("per_jifeng")[1])
					self.m_super_award = tonumber(itemInfo:find("bigcash")[1])
					self.m_freetimes = tonumber(itemInfo:find("freetimes")[1])
					self.m_currentScore = tonumber(itemInfo:find("jifeng")[1])

					local itemWheelconf = item:find("wheelconf")

					if itemWheelconf then
						self.m_totalItemCount = #itemWheelconf
						for i = 1, #itemWheelconf do
							local item = {}
							item.id = itemWheelconf[i].id
							item.icon = itemWheelconf[i].icon
							item.dropid = itemWheelconf[i].dropid
							table.insert(self.m_itemlist, item)
						end
					end

					if self.m_resttime > 0 then
						self.aaa:scheduleUpdateWithPriorityLua(updateLeftTimeLabel, 0)
						self.aaa:setString(tools.convertTimeElectronicWatchChinese(self.m_resttime, 3))
					else
						--self.aaa:setString("已经结束")
						self.aaa:setVisible(false)
						self.label_aaa_desc:setVisible(false)
						self.label_end_desc:setVisible(true)
					end

					for i = 1, self.m_totalItemCount do
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
						--litao_2014.7.10_大转盘item数量
						local _drop_info = {}
						_drop_info.mainType, _drop_info.subType, _drop_info.toId, _drop_info.num = setObjTypeInfo(self.m_itemlist[i].dropid)
						if _drop_info.num > 1 then
							self["label_num_"..tostring(i)]:setVisible(true)
							self["label_num_"..tostring(i)]:setString(_drop_info.num)
						else
							self["label_num_"..tostring(i)]:setVisible(false)
						end

					end
					--self:startRequestRoulette(protocol.ROULETTE_W_ONCE, 0)
					self:init_ui_ext()
				else
					--GetMainMenu()->ShowErrorTip(atoi(rlele->Attribute("code")));
				end
			end)

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
		self.aaa:setVisible(true)
		self.label_aaa_desc:setVisible(true)
		self.label_end_desc:setVisible(false)
	else
		self.aaa:setVisible(false)
		self.label_aaa_desc:setVisible(false)
		self.label_end_desc:setVisible(true)
	end

	self.label_super_award:setString(tostring(self.m_super_award))
	self.label_score:setString(tostring(self.m_score_once))
	self.label_gold_once:setString(tostring(self.m_gold_one_shoot))
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

function updateFreeTimes(self)
	if self.m_freetimes > 0 then
		self.label_free:setVisible(true)
		self.label_gold_once:setVisible(false)
		self.label_gold_desc:setVisible(false)
	else
		self.label_free:setVisible(false)
		self.label_gold_once:setVisible(true)
		self.label_gold_desc:setVisible(true)
	end
end

function init_binding_event(self)
	if self.proxy_ ~= nil then
		local function onBtnRollOnce(btn)
			--litao_限制刷小号_等级限制_2014.6.24
			local _playerData_ = CPlayerDataMgr:instance():GetPlayerInfoData()
			--get info from table_bin
			local config_info_level = DataMgr.GetDataByID("Struct_Functionconfig", 15)
			--判断等级
			if nil ~= config_info_level then 
			    if _playerData_.m_level < tonumber(config_info_level.m_needlevel) then
					GetMainMenu():ShowTextTip(tostring(config_info_level.m_tipinfo), -1)
					return nil
				end
			end
			if self.m_state ~= 0 then
				return
			end
			local cost
			if self.m_freetimes > 0 then
				cost = 0
			else
				cost = self.m_gold_one_shoot
			end

			local function startRollOnce()
				if self.m_state ~= 0 then
					return
				end
				self.m_one_shoot = true
				self.m_leftRollTimes = 1
				self:startRequestRoulette(protocol.ROULETTE_W_ONCE, 0)
			end

			local dlg = CommonDialogView.create()
			CommonDialogView.m_selfview = dlg
			dlg:SetTitle(localizable.ui_rouletteLayer_title)
			local showContent = string.format(text.text_config[267].description, cost)
			dlg:SetDescription(showContent)
			dlg:loadCCBI()
			dlg:initUI()
			dlg:SetConfirmHandler(startRollOnce)
			GetMainMenu():GetModelLayer():AddDialog(dlg, 3)

		end

		local function onBtnRank(btn)
			local rankLayer = createObj(ui_crossRouletteRankLayer, self, self.m_currentScore)
			local size1 = GetMainMenu():GetModelLayer():getContentSize()
			rankLayer.node_:setAnchorPoint(ccp(0.5, 0.5))

			rankLayer.node_:setPosition(size1.width / 2, size1.height / 2)
			GetMainMenu():GetModelLayer():addChild(rankLayer.node_)
		end

		local function onBtnRollTentimes(btn)
			--litao_限制刷小号_等级限制_2014.6.24
			local _playerData_ = CPlayerDataMgr:instance():GetPlayerInfoData()
			--get info from table_bin
			local config_info_level = DataMgr.GetDataByID("Struct_Functionconfig", 15)
			--判断等级
			if nil ~= config_info_level then 
			    if _playerData_.m_level < tonumber(config_info_level.m_needlevel) then
					GetMainMenu():ShowTextTip(tostring(config_info_level.m_tipinfo), -1)
					return nil
				end
			end
			if self.m_state ~= 0 then
				return
			end
			local cost
			if self.m_freetimes > 0 then
				cost = (10-1) * self.m_gold_one_shoot
			else
				cost = 10 * self.m_gold_one_shoot
			end
			local function startRollTen()
				if self.m_state ~= 0 then
					return
				end
				self.m_one_shoot = false
				self.m_leftRollTimes = 10
				self:startRequestRoulette(protocol.ROULETTE_W_TENTIMES, 1)
			end

			local dlg = CommonDialogView.create()
			CommonDialogView.m_selfview = dlg
			dlg:SetTitle(localizable.ui_rouletteLayer_title)
			local showContent = string.format(text.text_config[267].description, cost)
			dlg:SetDescription(showContent)
			dlg:loadCCBI()
			dlg:initUI()
			dlg:SetConfirmHandler(startRollTen)
			GetMainMenu():GetModelLayer():AddDialog(dlg, 3)
		end

		local function onBtnBack(btn)
			GetMainMenu():ChangeToSub(E_DEFAULTMENU)
		end
		
		local function onBtnClickIcon(btn)
			local btnIndex = btn:getTag()

			if btnIndex > 0 and btnIndex <= 12 then
				local dropid = tonumber(self.m_itemlist[btnIndex].dropid)
				if nil ~= dropid then
					CGameObjElement:ShowDropByID(dropid)
				end
			end
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
		end]]

		--self.node_:setTouchEnabled(true)
		--self.node_:registerScriptTouchHandler(CCLayerTouch, false, kCCMenuHandlerPriority-1, true)

		--self.btn_roll_once:setTouchPriority(kCCMenuHandlerPriority - 2)
		--self.btn_roll_once:setTouchEnabled(true)

		self.proxy_:handleButtonEvent(self.btn_roll_once, function(button, event)
			onBtnRollOnce(button)
			return nil
		end, CCControlEventTouchUpInside)

		--self.btn_rank:setTouchPriority(kCCMenuHandlerPriority - 2)
		--self.btn_rank:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btn_rank, function(button, event)
			onBtnRank(button)
			return nil
		end, CCControlEventTouchDown)

		--self.btn_roll_tentimes:setTouchPriority(kCCMenuHandlerPriority - 2)
		--self.btn_roll_tentimes:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btn_roll_tentimes, function(button, event)
			onBtnRollTentimes(button)
			return nil
		end, CCControlEventTouchDown)

		--self.btn_back:setTouchPriority(kCCMenuHandlerPriority - 2)
		--self.btn_back:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btn_back, function(button, event)
			onBtnBack(button)
			return nil
		end, CCControlEventTouchDown)
		
		-- 点击格子事件
		for i = 1, 12 do
			self.proxy_:handleButtonEvent(self["btn_card" .. tostring(i)], function(button, event)
				onBtnClickIcon(button)
				return nil
			end, CCControlEventTouchUpInside)
		end

	end
end


function startRequestRoulette(self, cmd, type)
		local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, cmd, protocol.URL_W_ROULETTE)
		--urlpath = "http://203.195.181.162:8080/rl_w_guaguale?Cmd=1701&Uid=80021&Session=962954F5D722633016FF458E22920C29&Clinettime=2013/10/22%2021:56:17%20Tuesday&Platform=win32&Version=1.0.0&Pt=3&Area=2"
		AddData(urlpath, "m_type", type)
		GetMainMenu():ShowLoadingDlg()
		CCHttpRequest:open(urlpath, kHttpPost, "query=param1&other=params"):sendWithHandler(
			function(res, hnd)
				GetMainMenu():CloseLoadding();
				local resData = res:getResponseData()
				local code = res:getResponseCode()
				local xfile = xml.parse(resData)
				local item = xfile:find("RENLONG")
				local retcode = item.code
				if retcode == "0" then
					local itemInfo = item:find("info")
					self.m_super_award = tonumber(itemInfo:find("bigcash")[1])
					self.m_currentScore = tonumber(itemInfo:find("jifeng")[1])

					local itemList = item:find("award_list")

					if itemList then
						self.m_awardlist = {}
						self.m_rewardIdx = 1
						for i = 1, #itemList do
							local awardXml = itemList[i]:find("award")
							local rewarddata = FightReward:new()
							InitAwardData(rewarddata, awardXml)
							local tmpItem = {}
							tmpItem.resultdata = rewarddata
							tmpItem.rewardId = tonumber(itemList[i].item_id)
							table.insert(self.m_awardlist, tmpItem)
						end
					end

					if #self.m_awardlist > 0 then
						if #self.m_awardlist == 1 then
							if self.m_one_shoot == false then
								self.label_left_roll:setString(tostring(#self.m_awardlist))
							end
							self:doRoll(self.m_awardlist[1].rewardId);
						else
							local resultView = tolua.cast(CRouletteTurnResultDialogView:create(), "CRouletteTurnResultDialogView")
							resultView:ClearAwardList()
							for i = 1, #self.m_awardlist do
								local turnId = tonumber(self.m_awardlist[i].rewardId)
								local itemInfo = ItemDataInfo:new()
								self.playerMgr_:AddDataFromReward(self.m_awardlist[i].resultdata)
								CGameObjElement:GetInfoFromDropId(self.m_awardlist[i].resultdata, itemInfo)
								itemInfo.dropid = self.m_awardlist[i].resultdata.m_dropid
								if itemInfo.mainType ~= 1 then
									itemInfo.quality = 5
									itemInfo.icon = self.m_itemlist[turnId].icon
								end
								
								resultView:PushAward(itemInfo)
							end
							resultView:startRun()
							GetMainMenu():AddDialog(resultView)
						end
					end
					if self.m_freetimes > 0 then
						self.playerMgr_:AddGold(-(#self.m_awardlist-1) * self.m_gold_one_shoot)
						self.m_freetimes = 0
					else
						self.playerMgr_:AddGold(-(#self.m_awardlist) * self.m_gold_one_shoot)
					end
					self:init_ui_ext()
				else
					--GetMainMenu()->ShowErrorTip(atoi(rlele->Attribute("code")));
					GetMainMenu():ShowTextTip(tostring(text.text_config[tonumber(retcode)].description), -1)
				end
			end)
end


function doRoll(self, targetNumber)
	self.m_state = 1
	self.m_currentItemIndex = 1
	self.m_leftRound = 2
	self.m_targetNumber = targetNumber
	self:doRollAction()
end

function doRollAction(self)
	if self.m_leftRound > 0 then
		if self.m_currentItemIndex > self.m_totalItemCount then
			self.m_leftRound = self.m_leftRound - 1
			self.m_currentItemIndex = 1
			self:nextItem()
		else
			self:highlightTargetItem(self.m_currentItemIndex);
			self.m_currentItemIndex = self.m_currentItemIndex + 1
			if self.m_currentItemIndex > self.m_totalItemCount then
				self.m_leftRound = self.m_leftRound - 1
				self.m_currentItemIndex = 1
			end
			self:nextItem()
		end
	else
		if self.m_currentItemIndex > self.m_targetNumber then
			self:highlightTargetItem(self.m_targetNumber)
			self:doRollEnd()
		else
			self:highlightTargetItem(self.m_currentItemIndex);
			self.m_currentItemIndex = self.m_currentItemIndex + 1
			self:nextItem()
		end
	end
end

function doRollEnd(self)
	local size = self["sprite_hl_" .. tostring(self.m_targetNumber)]:getContentSize()

	self.m_hlLayer = createObj(ui_rouletteBingo, size)
	self.m_hlLayer.node_:setAnchorPoint(ccp(0.5, 0.5))
	self.m_hlLayer.node_:setPosition(size.width / 2, size.height / 2)

	self["sprite_hl_" .. tostring(self.m_targetNumber)]:addChild(self.m_hlLayer.node_)

	local function showBox()
		self:unhighlightAllItem()
		if self.m_hlLayer then
			self.m_hlLayer.node_:removeFromParentAndCleanup(true)
		end
		if self.m_leftRollTimes <= 0 then
			if self.m_one_shoot == false then
				self.label_left_roll:setString(tostring(10))
			end
			self.m_state = 0
			return
		end
		if self.m_rewardIdx > #self.m_awardlist then
			self.m_state = 0
			return
		end

		if self.m_rewardIdx >= 1 and self.m_rewardIdx <= #self.m_awardlist then
			self.playerMgr_:AddDataFromReward(self.m_awardlist[self.m_rewardIdx].resultdata)
			self.playerData_ = self.playerMgr_:GetPlayerInfoData()
			self.label_gold:setString(tostring(self.playerData_.m_gold))
			self.label_silver:setString(tostring(self.playerData_.m_silver))
		end

		local function showBoxEnd()
			self.m_leftRollTimes = self.m_leftRollTimes - 1
			self.m_rewardIdx = self.m_rewardIdx + 1

			if self.m_leftRollTimes > 0 and self.m_rewardIdx <= #self.m_awardlist then
				self:doRoll(self.m_awardlist[self.m_rewardIdx].rewardId)

				if self.m_one_shoot == false then
					self.label_left_roll:setString(tostring(self.m_leftRollTimes))
				end
			else
				if self.m_one_shoot == false then
					self.label_left_roll:setString(10)
				end
				self.m_state = 0;
			end
		end
		GetMainMenu():ShowCommonBoxForCallBack(self.m_awardlist[self.m_rewardIdx].resultdata, showBoxEnd)

	end
	local ccArray = CCArray:create()
    ccArray:addObject(CCDelayTime:create(2))
    ccArray:addObject(CCCallFuncN:create(showBox))
    local sequen = CCSequence:create(ccArray)
	self.node_:runAction(sequen)

end

function nextItem(self)
	local i
	if self.m_leftRound > 0 then
		i = 0.08
	else
		i = 0.4
	end

	local function doRollAction1()
		if self.m_leftRound > 0 then
			if self.m_currentItemIndex > self.m_totalItemCount then
				self.m_leftRound = self.m_leftRound - 1
				self.m_currentItemIndex = 1
				self:nextItem()
			else
				self:highlightTargetItem(self.m_currentItemIndex);
				self.m_currentItemIndex = self.m_currentItemIndex + 1
				if self.m_currentItemIndex > self.m_totalItemCount then
					self.m_leftRound = self.m_leftRound - 1
					self.m_currentItemIndex = 1
				end
				self:nextItem()
			end
		else
			if self.m_currentItemIndex > self.m_targetNumber then
				self:highlightTargetItem(self.m_targetNumber)
				self:doRollEnd()
			else
				self:highlightTargetItem(self.m_currentItemIndex);
				self.m_currentItemIndex = self.m_currentItemIndex + 1
				self:nextItem()
			end
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