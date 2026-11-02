--边界碑Rank
--litao
--2014-2-17
---------------------------------------------
module("ui_borderWarRankLayer", package.seeall)
baseClass(layer_base_t, ui_borderWarRankLayer)

require("ui_layer/ui_borderWarRankCell2")

local RankType = {defYest = 1, defHistory = 2,attYest = 3,attHistory = 4}

function init(self, node, currentScore)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	local winSize = CCDirector:sharedDirector():getWinSize()

	--Load res
	local ccbiAttrTable = {name="activity/BorderWarRankView.ccbi", size=CCSizeMake(768, winSize.height)}
	layer_base_t.init(self, true, ccbiAttrTable)

	self.preNode = node
	--当前排名
	self.m_currentRank = 0
	--排行榜玩家信息
	self.m_playerDatas = {}
	--礼包信息列表
	self.m_packageItemList = {}
	--领取获取物品列表
	self.m_getAwardlist = {}
	--点击的按钮索引
	self.btnIndex = -1

	self.rankType = RankType.attYest

	self.myScore = 0
	self.minScore = 0


	--创建测试数据信息
	--self:createTestData()

	--init && bindEvent
	---[[
	self:init_ui()
	self:init_binding_event()
	--]]
end


function init_ui(self)
	if self.proxy_ ~= nil then
		--领奖Btn
		self.btnGetAward = tolua.cast(self.proxy_:getNode("rank_getReward"), "CCControlButton")
		self.getLabel = tolua.cast(self.proxy_:getNode("rank_getLabel"), "CCLabelTTF")
		self.haveGetLabel = tolua.cast(self.proxy_:getNode("rank_haveGetLabel"), "CCLabelTTF")
		self.getLabel:setVisible(true)
		self.haveGetLabel:setVisible(false)
		--昨日、历史
		self.btnYestodayHero = tolua.cast(self.proxy_:getNode("rank_yestodayHeroBtn"), "CCControlButton")
		self.btnHisHero = tolua.cast(self.proxy_:getNode("rank_hisHeroBtn"), "CCControlButton")

		self.btnAttackHero = tolua.cast(self.proxy_:getNode("btnAttackHero"), "CCControlButton")
		self.btnDefHero = tolua.cast(self.proxy_:getNode("btnDefHero"), "CCControlButton")
		--颜色
		self.btnYestodayHero:setEnabled(false)
		--[[
		local cur_program = CCShaderCache:sharedShaderCache():programForKey("greysprite")
		if cur_program ~= nil then
			tolua.cast(self.hisSpr, "CCNode"):setShaderProgram(cur_program)
		end
		--]]
		--关闭按钮
		self.btnDialogClose = tolua.cast(self.proxy_:getNode("closeButton"), "CCControlButton")
		--箱子按钮
		self.btnBox = tolua.cast(self.proxy_:getNode("rewardBox"), "CCControlButton")

		--排行榜container
		self.node_contentNode = tolua.cast(self.proxy_:getNode("rank_contentNode"), "CCNode")
		--cellNode
		self.node_cell = tolua.cast(self.proxy_:getNode("rank_cellNode"), "CCNode")

		self.nodeTitle1 = tolua.cast(self.proxy_:getNode("node_title1"), "CCNode")
		self.nodeTitle2 = tolua.cast(self.proxy_:getNode("node_title2"), "CCNode")

		self.labelBoxTips2 = tolua.cast(self.proxy_:getNode("label_boxTips2"),"CCLabelTTF")

		--请求yestoday信息
		self:onBtnAttackHero()
	end
end

function init_ext_ui(self)
	if self.rankType == RankType.defYest or self.rankType == RankType.attYest then
		self.nodeTitle1:setVisible(false)
		self.nodeTitle2:setVisible(true)
	else
		self.nodeTitle1:setVisible(true)
		self.nodeTitle2:setVisible(false)
	end

	if self.myScore < self.minScore then
		setBtnEnabled(self.btnBox,false)
	else
		setBtnEnabled(self.btnBox,true)
	end

	self.labelBoxTips2:setString(string.format(localizable.ui_border_boxTips2,self.minScore))
end

function startRequestRankInfo(self)
	---[[
	--获取排名信息
	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, self.rankType, "rl_r_frontiers_war_rank")
	urlpath = AddData(urlpath, "Country", self.playerData_.m_countrytype)
	--cclog("rl_r_frontiers_war_rank----%s", urlpath)
	GetMainMenu():ShowLoadingDlg()
	CCHttpRequest:open(urlpath, kHttpPost,"query=param1&other=params"):sendWithHandler(
		function(res, hnd)
			GetMainMenu():CloseLoadding()
			local resData = res:getResponseData()
			local code = res:getResponseCode()
			local xfile = xml.parse(resData)
			local item = xfile:find("RENLONG")
			local retcode = item.code
			cclog("rl_r_frontiers_war_rank.....%s", resData)
			if retcode == "0" then
				--宝箱信息
				
				if self.rankType == RankType.defYest or self.rankType == RankType.attYest then
					self.myScore = tonumber((xfile:find("score"))[1])
					self.boxInfo = tostring((xfile:find("rank_award_desc"))[1])
				end
				self.minScore = tonumber((xfile:find("min_award_score"))[1])
				--排名列表
				local itemList = xfile:find("rank_list")
				if itemList then
					self.m_playerDatas = {}
					for i = 1, #itemList do
						local tempitem = {}
						tempitem.rank = itemList[i].rank
						tempitem.nick = itemList[i].nick
						tempitem.countryId = itemList[i].country
						tempitem.level = itemList[i].level
						tempitem.score = itemList[i].score
						tempitem.award = itemList[i].award
						table.insert(self.m_playerDatas, tempitem)
					end

					--排名从低到高sort
					--[[
					table.sort(self.m_playerDatas, function(a, b)
						return a.rank < b.rank
					end)
					--]]
				end
				--self:createTestData()
				self:init_ext_ui()
				--创建排名列表cell				
				self:createRankTableView()					
			else
				GetMainMenu():ShowTextTip(tostring(item.msg), -1)
			end
		end)
	--]]
end


function onBtnAttackHero( self )
	self.btnAttackHero:setEnabled(false)
	self.btnDefHero:setEnabled(true)
	self.btnYestodayHero:setEnabled(false)
	self.btnHisHero:setEnabled(true)

	self.rankType = RankType.attYest
	self:startRequestRankInfo()
end

function onBtnDefHero( self )
	self.btnAttackHero:setEnabled(true)
	self.btnDefHero:setEnabled(false)
	self.btnYestodayHero:setEnabled(false)
	self.btnHisHero:setEnabled(true)

	self.rankType = RankType.defYest
	self:startRequestRankInfo()
end

function onBtnYestoday(self)	
	self.btnYestodayHero:setEnabled(false)
	self.btnHisHero:setEnabled(true)

	if self.rankType == RankType.defHistory then
		self.rankType = RankType.defYest
	elseif self.rankType == RankType.attHistory then
		self.rankType = RankType.attYest
	end
	
	self:startRequestRankInfo()
end

function onBtnHis(self)	
	self.btnYestodayHero:setEnabled(true)
	self.btnHisHero:setEnabled(false)

	if self.rankType == RankType.defYest then
		self.rankType = RankType.defHistory
	elseif self.rankType == RankType.attYest then
		self.rankType = RankType.attHistory
	end
	
	self:startRequestRankInfo()
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
		end
		self.node_:setTouchEnabled(true)
		self.node_:registerScriptTouchHandler(CCLayerTouch, false, kCCMenuHandlerPriority - 1, true)

		
		local function onBtnGetAward(btn)
			CSoundMgr:instance():PlayEffect(SOUND_BUTTON)
			---[[得到排名奖励
			local cmd = 3 -- 3是护国奖励，4是破国奖励
			if self.rankType == RankType.attYest or self.rankType == RankType.attHistory then
				cmd = 4
			end

			local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, cmd, "rl_r_frontiers_war_recv_award")
			urlpath = AddData(urlpath, "Country", self.playerData_.m_countrytype)
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
						cclog("rank_list----%s", resData)		
						--排名奖励										
						local rankAwardXML = xfile:find("award")							
						if rankAwardXML then
							--[[
							local m_rankAwardXml = {}
							local m_rankAwardXml = rankAwardXML

							local rankrewarddata = FightReward:new()
							InitAwardData(rankrewarddata, rankAwardXML)
							local tmpRankItem = {}
							tmpRankItem.resultdata = rankrewarddata
							self.m_getAwardlist = {}
							table.insert(self.m_getAwardlist, tmpRankItem)
							--]]	
							--显示奖励物品
							ShowAward(rankAwardXML)

							--将奖励添加到玩家信息			
							self.playerData_ = self.playerMgr_:GetPlayerInfoData()	
							GetMainMenu():ShowTextTip(localizable.ui_border_get_gift_success,-1)						
						end																								
					else
						GetMainMenu():ShowErrorTip(tostring(retcode), -1)
						--[[
						if item.msg ~= nil then
							GetMainMenu():ShowTextTip(tostring(item.msg), -1)
						else
							GetMainMenu():ShowTextTip(tostring("已经领过奖励或没有任何奖励!"),-1)
						end	
						--]]
					end
				end)	
				--]]			
		end
		
		local function close_window(btn, event)
			self:updateMainInfo()
			self.node_:removeFromParentAndCleanup(true)
		end

		local function onBtnBox(btn, event)
			if self.myScore < self.minScore then
				GetMainMenu():ShowTextTip(localizable.ui_border_boxErr,-1)
				return nil
			end
			require("ui_layer/ui_borderWarRankAwardPreviewLayer.lua")
			showModelLayer(ui_borderWarRankAwardPreviewLayer, self, self.boxInfo)
		end

		-- 破国
		self.btnAttackHero:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.proxy_:handleButtonEvent(self.btnAttackHero, function(button, event)
			self:onBtnAttackHero()
			return nil
		end, CCControlEventTouchUpInside)

		-- 护国
		self.btnDefHero:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.proxy_:handleButtonEvent(self.btnDefHero, function(button, event)
			self:onBtnDefHero()
			return nil
		end, CCControlEventTouchUpInside)

		--昨日
		self.btnYestodayHero:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.proxy_:handleButtonEvent(self.btnYestodayHero, function(button, event)
			self:onBtnYestoday();
			return nil
		end, CCControlEventTouchUpInside)
		--历史
		self.btnHisHero:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.proxy_:handleButtonEvent(self.btnHisHero, function(button, event)
			self:onBtnHis();
			return nil
		end, CCControlEventTouchUpInside)
		--箱子
		self.btnBox:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.proxy_:handleButtonEvent(self.btnBox, onBtnBox, CCControlEventTouchUpInside)
		--领奖
		self.btnGetAward:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.proxy_:handleButtonEvent(self.btnGetAward, onBtnGetAward, CCControlEventTouchUpInside)
		--关闭
		self.btnDialogClose:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.proxy_:handleControlEvent(self.btnDialogClose, close_window, CCControlEventTouchUpInside)
	end
end

function createRankTableView(self)
	if self.rankTableView ~= nil then
		self.rankTableView:removeFromParentAndCleanup(true)
		self.rankTableView = nil
	end
	if self.rankTableView == nil then
		local cellContentSize = self.node_cell:getContentSize()
		self.rank_cellsize = CCSizeMake(cellContentSize.width,cellContentSize.height)

		self.rank_tableContentSize = self.node_contentNode:getContentSize()

		if self.rankType == RankType.defYest or self.rankType == RankType.attYest then
			self:initRankTableHandle(ui_borderWarRankCell2)
		else	
			self:initRankTableHandle(ui_borderWarRankCell)
		end

		self.rankTableView = LuaTableView:createWithHandler(self.rankTableViewHandler, CCSizeMake(self.rank_tableContentSize.width, self.rank_tableContentSize.height))
		self.rankTableView:setDirection(kCCScrollViewDirectionVertical)
		self.rankTableView:setVerticalFillOrder(kCCTableViewFillTopDown)
		self.rankTableView:setTouchPriority(kCCMenuHandlerPriority - 1)

		self.node_contentNode:addChild(self.rankTableView)
	else
		self.rankTableView:reloadData()
	end
end


function initRankTableHandle(self, cellModule)
	self.rankTableViewHandler = nil
	self.rankTableViewHandler = LuaEventHandler:create(function(fn, table, a1, a2, x, y)
		local r
		if fn == "cellSize" then
			r = self.rank_cellsize;
		elseif fn == "cellAtIndex" then
    		local nodeLayer = createObj(cellModule, self.rank_cellsize, self.m_playerDatas[a1 + 1])
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
	self.m_playerDatas = {}
	local tempitem = {}
	tempitem.rank = 1
	tempitem.nick = "玩家名字"
	tempitem.countryId = 1
	tempitem.level = 220
	tempitem.score = 123133
	table.insert(self.m_playerDatas, tempitem)

end