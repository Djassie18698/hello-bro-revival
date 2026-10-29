--description:跨服转盘排行榜
--company: xckoo
--author: litao
--date: 2014-08-25

---------------------------------------------
module("ui_crossRouletteRankLayer", package.seeall)
baseClass(layer_base_t, ui_crossRouletteRankLayer)

function init(self, node, currentScore)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	local winSize = CCDirector:sharedDirector():getWinSize()

	local ccbiAttrTable = {name="dlg_ui/RouletteRankDialogViewForCross.ccbi", size=CCSizeMake(768, winSize.height)}
	layer_base_t.init(self, true, ccbiAttrTable)

	self.preNode = node
	self.m_currentRank = 0
	self.m_hisScore = 0
	self.m_currentScore = currentScore or 0
	self.m_playerDatas = {}
	self.m_packageItemList = {}
	self:init_ui()
	self:init_binding_event()
end


function init_ui(self)
	if self.proxy_ ~= nil then

		for i = 1, 4 do
			self["btnRankAward" .. tostring(i)] =  tolua.cast(self.proxy_:getNode("btnRankAward" .. tostring(i)), "CCControlButton")
			self["btnScoreAward" .. tostring(i)] =  tolua.cast(self.proxy_:getNode("btnScoreAward" .. tostring(i)), "CCControlButton")
			self["sprite_rank_icon" .. tostring(i)] =  tolua.cast(self.proxy_:getNode("sprite_rank_icon" .. tostring(i)), "CCSprite")
			self["sprite_score_icon" .. tostring(i)] =  tolua.cast(self.proxy_:getNode("sprite_score_icon" .. tostring(i)), "CCSprite")
			self["label_rank_reward" .. tostring(i)] =  tolua.cast(self.proxy_:getNode("label_rank_reward" .. tostring(i)), "CCLabelTTF")
			self["label_score_reward" .. tostring(i)] =  tolua.cast(self.proxy_:getNode("label_score_reward" .. tostring(i)), "CCLabelTTF")

			self["btnRankAward" .. tostring(i)]:setTag(i)
			self["btnScoreAward" .. tostring(i)]:setTag(i)
			--奖励数量_litao_2014.7.14
			self["label_num_"..tostring(i)] =  tolua.cast(self.proxy_:getNode("label_num_" .. tostring(i)), "CCLabelBMFont")
			self["label_score_num_"..tostring(i)] =  tolua.cast(self.proxy_:getNode("label_score_num_" .. tostring(i)), "CCLabelBMFont")
		end

		self.label_rank =  tolua.cast(self.proxy_:getNode("label_rank"), "CCLabelBMFont")
		self.label_score =  tolua.cast(self.proxy_:getNode("label_score"), "CCLabelBMFont")
		self.node_tablecontent = tolua.cast(self.proxy_:getNode("node_tablecontent"), "CCNode")
		self.node_cardcontent = tolua.cast(self.proxy_:getNode("node_cardcontent"), "CCNode")
		self.btnDialogClose = tolua.cast(self.proxy_:getNode("btnDialogClose"), "CCControlButton")
		self.btnRankGetGift = tolua.cast(self.proxy_:getNode("btnRankGetGift"), "CCControlButton")
		--领奖下限限制_litao_2014.5.30
		self.m_limitDesc = tolua.cast(self.proxy_:getNode("label_limit_desc"), "CCLabelTTF")
		--self.m_limitDesc:setVisible(false)

		local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 0, protocol.URL_R_WHEELRANK)
		urlpath = AddData(urlpath, "page", 1)
		urlpath = AddData(urlpath, "wid", 1)
		GetMainMenu():ShowLoadingDlg()
		CCHttpRequest:open(urlpath, kHttpPost,"query=param1&other=params"):sendWithHandler(
			function(res, hnd)
				GetMainMenu():CloseLoadding()
				local resData = res:getResponseData()
				local code = res:getResponseCode()
				local xfile = xml.parse(resData)
				local item = xfile:find("RENLONG")
				local retcode = item.code
				if retcode == "0" then
					self.m_currentRank = tonumber((item:find("myrank"))[1])
					self.m_hisScore = tonumber((item:find("myscore"))[1])
					--下限限制_litao_2014.5.29
					self.m_limit_score = tonumber(item:find("limitscore")[1])
					--rank
					local itemList = (xfile:find("rank"))
					if itemList then
						for i = 1, #itemList do
							local item = {}
							item.rank = tonumber((itemList[i]:find("rank"))[1])
							item.nick = (itemList[i]:find("nick"))[1]
							item.score = tonumber((itemList[i]:find("score"))[1])
							--服务器id_8.21_litao
							item.server_id = tonumber(itemList[i]:find("zone")[1])
							table.insert(self.m_playerDatas, item)
						end

						table.sort(self.m_playerDatas, function(a, b)
							return a.rank < b.rank
						end)
					end

					local itemList1 = (xfile:find("wheelpackage"))
					if itemList1 then
						for i = 1, #itemList1 do
							local item = {}
							item.id = tonumber(itemList1[i].id)
							item.name = itemList1[i].name
							item.icon = itemList1[i].icon
							item.type = tonumber(itemList1[i].type)
							item.desc = itemList1[i].desc
							item.quality = itemList1[i].quality
							item.dropid = tonumber(itemList1[i].dropid)
							table.insert(self.m_packageItemList, item)
						end
					end
					self:createRankTableView()
					self:updateUI()
				else
					GetMainMenu():ShowTextTip(tostring(text.text_config[tonumber(retcode)].description), -1)
				end
			end)

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

		--立即充值回调函数
		local function close_window(btn, event)
			self.preNode.m_currentScore = self.m_currentScore
			self.node_:removeFromParentAndCleanup(true)
		end

		local function onBtnRankAward(btn)
			CSoundMgr:instance():PlayEffect(SOUND_BUTTON)
			local index = btn:getTag()
			local dlg = CommonDialogView.create()
			CommonDialogView.m_selfview = dlg
			dlg:SetTitle(localizable.ui_rouletteLayer_get_gift)
			dlg:SetDescription(self.m_packageItemList[index].desc)
			dlg:loadCCBI(kCCMenuHandlerPriority-4)
			dlg:initUI(kCCMenuHandlerPriority-5)
			--dlg:SetConfirmHandler(getRankGift)
			--dlg:updateLeftBtnText(localizable.ui_rouletteLayer_get_gift)
			GetMainMenu():GetModelLayer():AddDialog(dlg, 3)
		end

		local function onBtnScoreAward(btn)
			CSoundMgr:instance():PlayEffect(SOUND_BUTTON)
			local index = btn:getTag()

			local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 2, protocol.URL_R_WHEELGIFT)
			urlpath = AddData(urlpath, "GiftId", btn:getTag() + 4)

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
						local jifen = xfile:find("jifeng")
						if jifen then
							self.m_currentScore = tonumber(jifen[1])
						end
						local awardXML = xfile:find("award")
						ShowAward(awardXML)
					else
						GetMainMenu():ShowTextTip(tostring(text.text_config[tonumber(retcode)].description), -1)
					end
					self.label_score:setString(tostring(self.m_currentScore) .. "/" ..tostring(self.m_hisScore))
				end)
		end

		local function getRankGift()
			if self.m_currentRank > 0 and self.m_currentRank <= 100 then
				local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 1, protocol.URL_R_WHEELGIFT)
				GetMainMenu():ShowLoadingDlg()
				urlpath = AddData(urlpath, "GiftId", 1) --这个参数没意义在这里没意义，但是要传
				CCHttpRequest:open(urlpath, kHttpPost, "query=param1&other=params"):sendWithHandler(
					function(res, hnd)
						GetMainMenu():CloseLoadding()
						local resData = res:getResponseData()
						local code = res:getResponseCode()
						local xfile = xml.parse(resData)
						local item = xfile:find("RENLONG")
						local retcode = item.code
						--cclog("1111---%s", resData)
						if retcode == "0" then
							local awardXML = xfile:find("award")
							ShowAward(awardXML)
							--下限限制码_litao_2014.5.29
							local _limitCode = tonumber(xfile:find("limitcode")[1])
							if _limitCode > 0 then
								GetMainMenu():ShowErrorTip(_limitCode, -1)
							end	
						else
							--GetMainMenu():ShowTextTip(tostring("排行礼包请在活动结束后自行领取,积分达到"..self.m_limit_score.."及以上,才能领取第一名奖励!"), -1)
							GetMainMenu():ShowTextTip(tostring(text.text_config[tonumber(retcode)].description), -1)
						end
					end)
			else
				GetMainMenu():ShowTextTip(localizable.ui_roulette_not_qualification, -1)
			end
		end

		for i = 1, 4 do
			self["btnRankAward" .. tostring(i)]:setTouchPriority(kCCMenuHandlerPriority - 3)
			self["btnRankAward" .. tostring(i)]:setTouchEnabled(true)

			self["btnScoreAward" .. tostring(i)]:setTouchPriority(kCCMenuHandlerPriority - 3)
			self["btnScoreAward" .. tostring(i)]:setTouchEnabled(true)

			self.proxy_:handleButtonEvent(self["btnRankAward" .. tostring(i)], function(button, event)
				onBtnRankAward(button)
				return nil
			end, CCControlEventTouchUpInside)

			self.proxy_:handleButtonEvent(self["btnScoreAward" .. tostring(i)], function(button, event)
				onBtnScoreAward(button)
				return nil
			end, CCControlEventTouchUpInside)
		end

		self.btnDialogClose:setTouchPriority(kCCMenuHandlerPriority - 3)
		self.proxy_:handleControlEvent(self.btnDialogClose, close_window, CCControlEventTouchUpInside)

		self.btnRankGetGift:setTouchPriority(kCCMenuHandlerPriority - 3)
		self.proxy_:handleControlEvent(self.btnRankGetGift, getRankGift, CCControlEventTouchUpInside)
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
		self.rankTableView:setTouchPriority(kCCMenuHandlerPriority - 3)
		self.node_tablecontent:addChild(self.rankTableView)
	end
end

function initRankTableHandle(self)
	self.rankTableViewHandler = LuaEventHandler:create(function(fn, table, a1, a2, x, y)
		local r
		if fn == "cellSize" then
			r = self.rank_cellsize;
		elseif fn == "cellAtIndex" then
    		local nodeLayer = createObj(ui_crossRouletteRankTableCell, self.rank_cellsize, self.m_playerDatas[a1 + 1])
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
		local frame = CGameObjElement:GetItemFrame(E_FRAMETYPE_SMALL, self.m_packageItemList[i].quality)
		if (frame ~= nil) then
			self["sprite_rank_icon" .. tostring(i)]:setDisplayFrame(frame)
		end
			
		CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile("props/" .. self.m_packageItemList[i].icon .. ".plist")
		local sprite_icon = CCSprite:createWithSpriteFrameName(self.m_packageItemList[i].icon)
		local contentSize = self["sprite_rank_icon" .. tostring(i)]:getContentSize()
		sprite_icon:setPosition(contentSize.width / 2, contentSize.height / 2)
		sprite_icon:setAnchorPoint(ccp(0.5, 0.5))
		self["sprite_rank_icon" .. tostring(i)]:addChild(sprite_icon)
		self["label_rank_reward" .. tostring(i)]:setString(self.m_packageItemList[i].name)

		--奖励数量_litao_2014.7.14
		local _drop_info = {}
		_drop_info.mainType, _drop_info.subType, _drop_info.toId, _drop_info.num = setObjTypeInfo(self.m_packageItemList[i].dropid)
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
		self["sprite_score_icon" .. tostring(i)]:addChild(sprite_icon)
		self["label_score_reward" .. tostring(i)]:setString(self.m_packageItemList[j].name)
		
		frame = CGameObjElement:GetItemFrame(E_FRAMETYPE_SMALL, self.m_packageItemList[j].quality);
		if (frame ~= nil) then
			self["sprite_score_icon" .. tostring(i)]:setDisplayFrame(frame)
		end

		--奖励数量_litao_2014.7.14
		local _score_drop_info = {}
		_score_drop_info.mainType, _score_drop_info.subType, _score_drop_info.toId, _score_drop_info.num = setObjTypeInfo(self.m_packageItemList[j].dropid)
		if _score_drop_info.num > 1 then
			self["label_score_num_"..tostring(i)]:setVisible(true)
			self["label_score_num_"..tostring(i)]:setString(_score_drop_info.num)
		else
			self["label_score_num_"..tostring(i)]:setVisible(false)
		end
	end

	self.label_rank:setString(tostring(self.m_currentRank))
	self.label_score:setString(tostring(self.m_currentScore) .. "/" ..tostring(self.m_hisScore))
	--领奖下限限制_litao_2014.5.30
	self.m_limitDesc:setString(tostring(localizable.ui_limitSuperNinja_info_1..self.m_limit_score..localizable.ui_limitSuperNinja_info_2))
end

function onNodeCleanup(self)
    --cclog("onNodeCleanup")
    if self.proxy_ then
    	self.proxy_:release()
    end
    layer_base_t.onNodeCleanup(self)
end