--跨服大富翁Rank
--litao
--2014-08-25
---------------------------------------------
module("ui_crossMonopolyRandkLayer", package.seeall)
baseClass(layer_base_t, ui_crossMonopolyRandkLayer)

function init(self, node, currentScore)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	local winSize = CCDirector:sharedDirector():getWinSize()

	--Load res
	local ccbiAttrTable = {name="activity/MonopolyRankViewForCross.ccbi", size=CCSizeMake(768, winSize.height)}
	layer_base_t.init(self, true, ccbiAttrTable)

	self.preNode = node
	--当前排名
	self.m_currentRank = 0
	--历史积分
	--self.m_hisScore = 0
	--当前积分
	self.m_currentScore = 0
	--排行榜玩家信息
	self.m_playerDatas = {}
	--礼包信息列表
	self.m_packageItemList = {}
	--领取获取物品列表
	self.m_getAwardlist = {}
	--点击的按钮索引
	self.btnIndex = -1

	--创建测试数据信息
	--self:createTestData()

	--init && bindEvent
	self:init_ui()
	self:init_binding_event()
end


function init_ui(self)
	if self.proxy_ ~= nil then
		--初始化奖励列表
		for i = 1, 4 do
			self["btn_rank_award"..tostring(i)] =  tolua.cast(self.proxy_:getNode("btn_rank_award" .. tostring(i)), "CCControlButton")
			--排名奖励
			self["sprite_rank_icon"..tostring(i)] =  tolua.cast(self.proxy_:getNode("sprite_rank_icon" .. tostring(i)), "CCSprite")
			self["sprite_score_icon"..tostring(i)] =  tolua.cast(self.proxy_:getNode("sprite_score_icon" .. tostring(i)), "CCControlButton")
			--成就奖励
			self["label_rank_reward"..tostring(i)] =  tolua.cast(self.proxy_:getNode("label_rank_reward" .. tostring(i)), "CCLabelTTF")
			self["label_score_reward"..tostring(i)] =  tolua.cast(self.proxy_:getNode("label_score_reward" .. tostring(i)), "CCLabelTTF")
			--奖励数量_litao_2014.7.14
			self["label_num_"..tostring(i)] =  tolua.cast(self.proxy_:getNode("label_num_" .. tostring(i)), "CCLabelBMFont")
			self["label_score_num_"..tostring(i)] =  tolua.cast(self.proxy_:getNode("label_score_num_" .. tostring(i)), "CCLabelBMFont")
		end
		--领奖Btn
		self.btnGetAward = tolua.cast(self.proxy_:getNode("btnGetAward"), "CCControlButton")
		--当前名次 步数
		self.label_rank =  tolua.cast(self.proxy_:getNode("label_rank"), "CCLabelBMFont")
		self.label_score =  tolua.cast(self.proxy_:getNode("label_score"), "CCLabelBMFont")
		--排行榜container
		self.node_tablecontent = tolua.cast(self.proxy_:getNode("node_tablecontent"), "CCNode")
		--关闭按钮
		self.btnDialogClose = tolua.cast(self.proxy_:getNode("btnDialogClose"), "CCControlButton")
		--cellNode
		self.node_cardcontent = tolua.cast(self.proxy_:getNode("node_cardcontent"), "CCNode")
		--领奖下限限制_litao_2014.5.30
		self.m_limitDesc = tolua.cast(self.proxy_:getNode("label_limit_desc"), "CCLabelTTF")

		---[[
		--获取排名信息
		local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 1, "rl_r_monopoly_rank")
		urlpath = AddData(urlpath, "page", 1)
		cclog("monorank111----%s", urlpath)
		GetMainMenu():ShowLoadingDlg()
		CCHttpRequest:open(urlpath, kHttpPost,"query=param1&other=params"):sendWithHandler(
			function(res, hnd)
				GetMainMenu():CloseLoadding()
				local resData = res:getResponseData()
				cclog("monorank_rank_data----%s", resData)
				local code = res:getResponseCode()
				local xfile = xml.parse(resData)
				local item = xfile:find("RENLONG")
				local retcode = item.code
				if retcode == "0" then
					--玩家信息
					self.m_playerRankInfo = item:find("player")
					self.m_currentRank = tonumber(self.m_playerRankInfo:find("rank")[1])
					self.m_currentScore = tonumber(self.m_playerRankInfo:find("step_num")[1])
					--下限限制_litao_2014.5.29
					self.m_limit_score = tonumber(item:find("limitscore")[1])
					--排名列表
					local itemList = (xfile:find("rank_list"))
					if itemList then
						for i = 1, #itemList do
							local tempitem = {}
							tempitem.rank = tonumber(itemList[i].rank)
							tempitem.nick = itemList[i].nick
							tempitem.country = itemList[i].country
							tempitem.score = tonumber(itemList[i].step_num)
							--服务器id_8.21_litao
							tempitem.server_id = tonumber(itemList[i].zone)
							table.insert(self.m_playerDatas, tempitem)
						end

						--排名从低到高sort
						table.sort(self.m_playerDatas, function(a, b)
							return a.rank < b.rank
						end)
					end
					--奖励信息
					local itemRankRewardList = xfile:find("rank_reward_list")
					if itemRankRewardList then
						for i = 1, #itemRankRewardList do
							local tempitem = {}
							tempitem.id = tonumber(itemRankRewardList[i].id)
							tempitem.name = itemRankRewardList[i].name
							tempitem.icon = itemRankRewardList[i].icon
							tempitem.quality = itemRankRewardList[i].star
							table.insert(self.m_packageItemList, tempitem)
						end
					end

					local itemStepRewardList = xfile:find("step_reward_list")
					if itemStepRewardList then
						for i = 1, #itemStepRewardList do
							local tempitem = {}
							tempitem.id = tonumber(itemStepRewardList[i].id)
							tempitem.name = itemStepRewardList[i].name
							tempitem.icon = itemStepRewardList[i].icon
							tempitem.quality = itemStepRewardList[i].star
							table.insert(self.m_packageItemList, tempitem)
						end
					end

					--创建排名列表cell
					self:createRankTableView()
					self:updateUI()
				else
					--GetMainMenu():ShowTextTip(tostring(text.text_config[tonumber(retcode)].description), -1)
				end
			end)
		--]]
	end
end

function init_binding_event(self)
	if self.proxy_ ~= nil then
		local function CCLayerTouch(event)
			if event == "began" then
				return true
			end
		end
		self.node_:setTouchEnabled(true)
		self.node_:registerScriptTouchHandler(CCLayerTouch, false, kCCMenuHandlerPriority-1, true)

		local function close_window(btn, event)
			self.preNode.m_currentScore = self.m_currentScore
			self.node_:removeFromParentAndCleanup(true)
		end

		local function onBtnGetAward(btn)
			CSoundMgr:instance():PlayEffect(SOUND_BUTTON)

			---[[得到排名奖励
			local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 1, "rl_w_monopoly_receive")
			
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
						---[[
						--下限限制码_litao_2014.5.29
						local _limitCode = tonumber(xfile:find("limitcode")[1])		
						--排名奖励				
						local rank_reward_xfile = xfile:find("reward_list")
						if rank_reward_xfile then							
							local rankAwardXML = rank_reward_xfile:find("award")							
							if rankAwardXML then
								local m_rankAwardXml = {}
								local m_rankAwardXml = rankAwardXML

								local rankrewarddata = FightReward:new()
								InitAwardData(rankrewarddata, rankAwardXML)
								local tmpRankItem = {}
								tmpRankItem.resultdata = rankrewarddata
								self.m_getAwardlist = {}
								table.insert(self.m_getAwardlist, tmpRankItem)	
								--显示奖励物品
								ShowAward(rankAwardXML)
							end
						else
							GetMainMenu():ShowTextTip(localizable.ui_monopoly_tips3,-1)
						end	
								
						--将奖励添加到玩家信息			
						if self.m_getAwardlist then
							if _limitCode < 0 then
								GetMainMenu():ShowTextTip(localizable.ui_monopoly_tips4,-1)
							else
								GetMainMenu():ShowErrorTip(_limitCode, -1)
							end			
							--self.playerMgr_:AddDataFromReward(self.m_getAwardlist[1].resultdata)		
						else	
							GetMainMenu():ShowTextTip(localizable.ui_monopoly_tips5,-1)						
						end
						self.playerData_ = self.playerMgr_:GetPlayerInfoData()
						--]]
					---[[
					else
						--cclog("monorank_rankreward----%s", xfile)
						if retcode == "1" then
							GetMainMenu():ShowTextTip(localizable.ui_monopoly_tips6,-1)
						elseif retcode == "2" then
							GetMainMenu():ShowTextTip(localizable.ui_monopoly_tips7,-1)
						elseif retcode == "3" then
							GetMainMenu():ShowTextTip(localizable.ui_monopoly_tips8,-1)
						else
							GetMainMenu():ShowTextTip(localizable.ui_monopoly_tips9,-1)
						end
					end
				end)
		end

		local function onBtnScoreAward(btn)
			CSoundMgr:instance():PlayEffect(SOUND_BUTTON)
			self.btnIndex = btn:getTag()

			if self.btnIndex < 0 or self.btnIndex > 4 then
				self.btnIndex = -1
				return nil
			end

			--领奖请求
			local function startGetStepReward()
				local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 2, "rl_w_monopoly_receive")
				urlpath = AddData(urlpath, "AwardID", self.btnIndex+4)
				--cclog("startGetStepReward:url----%s", urlpath)
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
							--GetMainMenu():ShowTextTip(tostring("报文0"..resData),-1)
							--成就奖励
							local step_reward_xfile = xfile:find("reward_list")
							if step_reward_xfile then
								local stepAwardXML = step_reward_xfile:find("award")
								if stepAwardXML then
									local m_stepAwardXml = {}
									local m_stepAwardXml = stepAwardXML

									local steprewarddata = FightReward:new()
									InitAwardData(steprewarddata, stepAwardXML)
									local tmpStepItem = {}
									tmpStepItem.resultdata = steprewarddata
									self.m_getAwardlist = {}
									table.insert(self.m_getAwardlist, tmpStepItem)	
									--显示奖励物品
									ShowAward(stepAwardXML)
								else
									GetMainMenu():ShowTextTip(localizable.ui_monopoly_tips10,-1)
								end

								--将奖励添加到玩家信息
								if self.m_getAwardlist then
									GetMainMenu():ShowTextTip(localizable.ui_monopoly_tips4,-1)
									--self.playerMgr_:AddDataFromReward(self.m_getAwardlist[1].resultdata)	
								else		
									GetMainMenu():ShowTextTip(localizable.ui_monopoly_tips11,-1)						
								end

								self.playerData_ = self.playerMgr_:GetPlayerInfoData()
							else
								GetMainMenu():ShowTextTip(localizable.ui_monopoly_tips11,-1)
							end
						else
							--GetMainMenu():ShowTextTip(tostring("报文123"),-1)
							---[[
							if retcode == "1" then
								GetMainMenu():ShowTextTip(localizable.ui_monopoly_tips12,-1)
							elseif retcode == "2" then
								GetMainMenu():ShowTextTip(localizable.ui_monopoly_tips13,-1)
							else
								GetMainMenu():ShowTextTip(localizable.ui_monopoly_tips9,-1)
							end
							--]]
						end
					end)
				--重置按钮位置
				self.btnIndex = -1
			end

			--掉落描述
			local _t_id = tonumber(self.m_packageItemList[self.btnIndex+4].id)
			local _obj_desc = tostring("")
			if nil ~= _t_id then
				local _drop_info = DataMgr.GetDataByID("Struct_Dropinfo", _t_id)				
				if nil ~= _drop_info then
					_obj_desc = _drop_info.m_dropdesc
				end 
			end

			--模态框
			local dlg = CommonDialogView.create()
			CommonDialogView.m_selfview = dlg
			dlg:SetTitle(localizable.ui_monopoly_tips14)
			--tostring("您确定领取["..self.m_packageItemList[self.btnIndex+4].name.."]的奖励[".._obj_desc.."]吗?")
			local showContent = string.format(localizable.ui_monopoly_tips15, self.m_packageItemList[self.btnIndex+4].name, _obj_desc)
			dlg:SetDescription(showContent)
			dlg:loadCCBI(kCCMenuHandlerPriority-1)
			dlg:initUI(kCCMenuHandlerPriority-1)
			dlg:SetConfirmHandler(startGetStepReward)
			GetMainMenu():GetModelLayer():AddDialog(dlg, 3)				
		end

		local function onBtnClickRankIcon(btn)
			--
			CSoundMgr:instance():PlayEffect(SOUND_BUTTON)
			local btnIndex = btn:getTag()

			if btnIndex > 0 and btnIndex <= 4 then
				local _id_icon = tonumber(self.m_packageItemList[btnIndex].id)
				if nil ~= _id_icon then
					CGameObjElement:ShowDropByID(_id_icon)
				end
			end
		end

		for i = 1, 4 do
			self["sprite_score_icon" .. tostring(i)]:setTouchPriority(kCCMenuHandlerPriority - 1)
			self["sprite_score_icon" .. tostring(i)]:setTouchEnabled(true)

			self.proxy_:handleButtonEvent(self["sprite_score_icon" .. tostring(i)], function(button, event)
				onBtnScoreAward(button)
				return nil
			end, CCControlEventTouchUpInside)

			self["btn_rank_award" .. tostring(i)]:setTouchPriority(kCCMenuHandlerPriority - 1)
			self["btn_rank_award" .. tostring(i)]:setTouchEnabled(true)

			self.proxy_:handleButtonEvent(self["btn_rank_award" .. tostring(i)], function(button, event)
				onBtnClickRankIcon(button)
				return nil
			end, CCControlEventTouchUpInside)
		end

		--绑定按钮事件
		self.btnGetAward:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.proxy_:handleButtonEvent(self.btnGetAward, onBtnGetAward, CCControlEventTouchUpInside)

		self.btnDialogClose:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.proxy_:handleControlEvent(self.btnDialogClose, close_window, CCControlEventTouchUpInside)
	end
end

function createRankTableView(self)
	-- body
	if self.rankTableView == nil then
		self.rank_cellsize = self.node_cardcontent:getContentSize()
		self.rank_tableContentSize = self.node_tablecontent:getContentSize()
		self:initRankTableHandle()
		self.rankTableView = LuaTableView:createWithHandler(self.rankTableViewHandler, CCSizeMake(self.rank_tableContentSize.width, self.rank_tableContentSize.height))
		self.rankTableView:setDirection(kCCScrollViewDirectionVertical)
		self.rankTableView:setVerticalFillOrder(kCCTableViewFillTopDown)
		self.rankTableView:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.node_tablecontent:addChild(self.rankTableView)
	end
end

function initRankTableHandle(self)
	self.rankTableViewHandler = LuaEventHandler:create(function(fn, table, a1, a2, x, y)
		local r
		if fn == "cellSize" then
			r = self.rank_cellsize;
		elseif fn == "cellAtIndex" then
    		local nodeLayer = createObj(ui_crossMonopolyRankCell, self.rank_cellsize, self.m_playerDatas[a1 + 1])
			if not a2 then
				a2 = CCTableViewCell:create()
				a2:addChild(nodeLayer.node_)
			else
				a2:removeAllChildrenWithCleanup(true)
        		a2:addChild(nodeLayer.node_)
			end
			r = a2
		elseif fn == "numberOfCells" then
			r = #self.m_playerDatas;
		    -- Cell events:
		elseif fn == "cellTouched" then			-- A cell was touched, a1 is cell that be touched. This is not necessary.
			--local cellIndex = a1:getIdx() + 1
		elseif fn == "cellTouchBegan" then		-- A cell is touching, a1 is cell, a2 is CCTouch
			r = true
		elseif fn == "cellTouchEnded" then		-- A cell was touched, a1 is cell, a2 is CCTouch
			r = true
		elseif fn == "cellHighlight" then		-- A cell is highlighting, coco2d-x 2.1.3 or above
		elseif fn == "cellUnhighlight" then		-- A cell had been unhighlighted, coco2d-x 2.1.3 or above
		elseif fn == "cellWillRecycle" then		-- A cell will be recycled, coco2d-x 2.1.3 or above
		end
		return r
	end)
end

function updateUI(self)
	for i = 1, 4 do
		CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile("props/" .. self.m_packageItemList[i].icon .. ".plist")
		local sprite_icon = CCSprite:createWithSpriteFrameName(self.m_packageItemList[i].icon)
		local contentSize = self["sprite_rank_icon" .. tostring(i)]:getContentSize()
		sprite_icon:setPosition(contentSize.width / 2, contentSize.height / 2)
		sprite_icon:setAnchorPoint(ccp(0.5, 0.5))
		self["sprite_rank_icon" .. tostring(i)]:addChild(sprite_icon, 2)
		self["label_rank_reward" .. tostring(i)]:setString(self.m_packageItemList[i].name)

	    --quality frame
		local pRankFrame = rl_get_frameicon(E_FRAMETYPE_SMALL,self.m_packageItemList[i].quality)
		if pRankFrame ~= nil then
			local spr_frame = CCSprite:createWithSpriteFrame(pRankFrame)
			spr_frame:setPosition(contentSize.width / 2, contentSize.height / 2)
			spr_frame:setAnchorPoint(ccp(0.5, 0.5))
			self["sprite_rank_icon" .. tostring(i)]:addChild(spr_frame, 1)
		end

		--奖励数量_litao_2014.7.14
		local _drop_info = {}
		_drop_info.mainType, _drop_info.subType, _drop_info.toId, _drop_info.num = setObjTypeInfo(self.m_packageItemList[i].id)
		if _drop_info.num > 1 then
			self["label_num_"..tostring(i)]:setVisible(true)
			self["label_num_"..tostring(i)]:setString(_drop_info.num)
		else
			self["label_num_"..tostring(i)]:setVisible(false)
		end


		local j = i + 4
		CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile("props/" .. self.m_packageItemList[j].icon .. ".plist")
		sprite_icon = CCSprite:createWithSpriteFrameName(self.m_packageItemList[j].icon)
		contentSize = self["sprite_rank_icon" .. tostring(i)]:getContentSize()
		sprite_icon:setPosition(contentSize.width / 2, contentSize.height / 2)
		sprite_icon:setAnchorPoint(ccp(0.5, 0.5))
		self["sprite_score_icon" .. tostring(i)]:addChild(sprite_icon, 2)
		self["label_score_reward" .. tostring(i)]:setString(self.m_packageItemList[j].name)

		--quality frame
		local pScoreFrame = rl_get_frameicon(E_FRAMETYPE_SMALL,self.m_packageItemList[j].quality)
		if pScoreFrame ~= nil then
			local spr_frame = CCSprite:createWithSpriteFrame(pScoreFrame)
			spr_frame:setPosition(contentSize.width / 2, contentSize.height / 2)
			spr_frame:setAnchorPoint(ccp(0.5, 0.5))
			self["sprite_score_icon" .. tostring(i)]:addChild(spr_frame, 1)
		end

		--奖励数量_litao_2014.7.14
		local _score_drop_info = {}
		_score_drop_info.mainType, _score_drop_info.subType, _score_drop_info.toId, _score_drop_info.num = setObjTypeInfo(self.m_packageItemList[j].id)
		if _score_drop_info.num > 1 then
			self["label_score_num_"..tostring(i)]:setVisible(true)
			self["label_score_num_"..tostring(i)]:setString(_score_drop_info.num)
		else
			self["label_score_num_"..tostring(i)]:setVisible(false)
		end
		--暂时隐藏
		self["label_num_"..tostring(i)]:setVisible(false)
	end

	--显示排名、积分信息
	self.label_rank:setString(tostring(self.m_currentRank))
	self.label_score:setString(tostring(self.m_currentScore))
	--领奖下限限制_litao_2014.5.30
	self.m_limitDesc:setString(tostring(localizable.ui_monopoly_info_1..self.m_limit_score..localizable.ui_limitSuperNinja_info_2))
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
	for i=1,8 do
		local itemNode = {}
		itemNode.name = "一乐拉面(小)*2"
		itemNode.icon = "props_016"
		itemNode.id = 481
		itemNode.type = tonumber("1")
		itemNode.desc = "desc"
		table.insert(self.m_packageItemList, itemNode)
	end

	for i = 1, 20 do
		local item = {}
		item.rank = i
		item.nick = tostring("testName"..i)
		item.score = tonumber("99")
		item.country = tostring("火"..i)
		table.insert(self.m_playerDatas, item)
	end

	table.sort(self.m_playerDatas, function(a, b)
		return a.rank < b.rank
	end)
end