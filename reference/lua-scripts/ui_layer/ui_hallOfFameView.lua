--名人堂Rank
--litao
--2014-4-8
---------------------------------------------
require("CommonBuyItemDialog.lua")

module("ui_hallOfFameView", package.seeall)
baseClass(layer_base_t, ui_hallOfFameView)

function init(self, node, currentScore)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	--Load res
	self.contentSize_ = GetMainMenu():GetSubContentNode():getContentSize()
	local ccbiAttrTable = {name="activity/PlayerStrengthRank.ccbi", size=self.contentSize_}
	layer_base_t.init(self, true, ccbiAttrTable)

	self.preNode = node
	--当前排名
	self.m_currentRank = 0
	--数据
	self.m_min_data = 0
	self.m_max_data = 0
	--排行榜玩家信息
	self.m_playerDatas = {}
	--tableView cell container
	self.cellNodes = {}
	--cur type
	self.m_cur_type = 0
	--
	self.m_touchPoint = nil

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
		--个人信息
		self.label_myrank = tolua.cast(self.proxy_:getNode("label_myrank"), "CCLabelBMFont")
		self.label_mydata = tolua.cast(self.proxy_:getNode("label_mydata"), "CCLabelBMFont")
		self.label_mydata_type_desc = tolua.cast(self.proxy_:getNode("label_mydata_type_desc"), "CCLabelTTF")
		
		self.label_norank_desc = tolua.cast(self.proxy_:getNode("norank_desc"), "CCLabelTTF")
		self.label_merit_lv = tolua.cast(self.proxy_:getNode("merit_lv"), "CCLabelTTF")
		self.label_merit_desc = tolua.cast(self.proxy_:getNode("label_merit_desc"), "CCLabelTTF") 
		self.label_merit = tolua.cast(self.proxy_:getNode("label_merit"), "CCLabelBMFont") 
		--攻击、防御、忍阶
		self.btn_rank_attack = tolua.cast(self.proxy_:getNode("btn_rank_attack"), "CCControlButton")
		self.btn_rank_def = tolua.cast(self.proxy_:getNode("btn_rank_def"), "CCControlButton")
		self.btn_rank_ninjaLV = tolua.cast(self.proxy_:getNode("btn_rank_ninjaLV"), "CCControlButton")
		--初始选择
		self.btn_rank_attack:setEnabled(false)
		self.m_cur_type = 1
		--back按钮
		self.btnBack = tolua.cast(self.proxy_:getNode("btn_back"), "CCControlButton")
		--提升实力按钮
		self.btn_raise = tolua.cast(self.proxy_:getNode("btn_raise"), "CCControlButton")

		--排行榜container
		self.node_content = tolua.cast(self.proxy_:getNode("node_content"), "CCNode")
		--cellNode
		self.node_cell = tolua.cast(self.proxy_:getNode("node_cell"), "CCNode")

		--请求攻击rank信息(1/2/3)
		self:startRequestRankInfo(1)
	end
end

function startRequestRankInfo(self, infoType)
	if infoType < 1 or infoType > 3 then
		infoType = 1
	end

	---[[
	--获取排名信息
	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, infoType, "rl_r_ninja_rank")
	cclog("rl_r_ninja_rank----%s", urlpath)
	GetMainMenu():ShowLoadingDlg()
	CCHttpRequest:open(urlpath, kHttpPost,"query=param1&other=params"):sendWithHandler(
		function(res, hnd)
			GetMainMenu():CloseLoadding()
			local resData = res:getResponseData()
			local code = res:getResponseCode()
			local xfile = xml.parse(resData)
			local item = xfile:find("RENLONG")
			if nil == item then
				GetMainMenu():ShowTextTip(localizable.ui_hall_net_error, -1)
				return nil
			end
			local retcode = item.code
			if retcode == "0" then
				cclog("rl_r_ninja_rank.....%s", resData)
				--player信息
				local userInfo = xfile:find("player")
				if userInfo then
					self.m_currentRank = tonumber(userInfo:find("rank")[1])
					self.m_min_data = tonumber(userInfo:find("min_score")[1])
					self.m_max_data = tonumber(userInfo:find("max_score")[1])
				end
				--排名列表
				local itemList = xfile:find("rank_list")
				if itemList then
					self.m_playerDatas = {}
					for i = 1, #itemList do
						local tempitem = {}
						tempitem.infoType = tonumber(infoType)
						tempitem.rank = tonumber(itemList[i].rank)
						tempitem.id = itemList[i].uid
						tempitem.nick = itemList[i].nick
						tempitem.countryId = itemList[i].country
						tempitem.level = tonumber(itemList[i].level)
						tempitem.min_score = tonumber(itemList[i].min_score)
						tempitem.max_score = tonumber(itemList[i].max_score)
						table.insert(self.m_playerDatas, tempitem)
					end

					--init
					if self.m_playerDatas then
						--创建排名列表cell				
						self:createRankTableView()
						--init info
						self:init_ext_ui()	
					end
				end								
			else
				GetMainMenu():ShowTextTip(localizable.ui_hall_net_error, -1)
			end
		end)
	--]]
end

function init_ext_ui(self)
	--init
	if self.m_currentRank <= 0 then
		self.label_myrank:setVisible(false)
		self.label_norank_desc:setVisible(true)
	else
		self.label_myrank:setVisible(true)
		self.label_norank_desc:setVisible(false)
		self.label_myrank:setString(tostring(self.m_currentRank))
	end
	
	if self.m_cur_type == 1 then
		self.label_mydata_type_desc:setString(localizable.ui_hall_my_attack)
		self.label_mydata:setString(tostring(self.m_min_data.."-"..self.m_max_data))

		self.label_mydata:setVisible(true)
		self.label_merit:setVisible(false)
		self.label_merit_desc:setVisible(false)
		self.label_merit_lv:setVisible(false)
	elseif self.m_cur_type == 2 then
		self.label_mydata_type_desc:setString(localizable.ui_hall_my_defense)
		self.label_mydata:setString(tostring(self.m_min_data.."-"..self.m_max_data))

		self.label_mydata:setVisible(true)
		self.label_merit:setVisible(false)
		self.label_merit_desc:setVisible(false)
		self.label_merit_lv:setVisible(false)
	elseif self.m_cur_type == 3 then
		self.label_mydata_type_desc:setString(localizable.ui_hall_ninja_level)
		self.label_mydata:setVisible(false)
		self.label_merit:setVisible(true)
		self.label_merit_desc:setVisible(true)
		self.label_merit_lv:setVisible(true)

		self.label_merit_lv:setString(localizable.ui_hall_level)
		self.label_merit:setString(tostring(self.m_max_data))
	end
end

function onBtnAttackRank(self)	
	self.btn_rank_attack:setEnabled(false)
	self.btn_rank_def:setEnabled(true)
	self.btn_rank_ninjaLV:setEnabled(true)
	--请求
	self:startRequestRankInfo(1)
	self.m_cur_type = 1	
end

function onBtnDefRank(self)	
	self.btn_rank_attack:setEnabled(true)
	self.btn_rank_def:setEnabled(false)
	self.btn_rank_ninjaLV:setEnabled(true)
	--请求
	self:startRequestRankInfo(2)
	self.m_cur_type = 2
end

function onBtnNinjaLvRank(self)	
	self.btn_rank_attack:setEnabled(true)
	self.btn_rank_def:setEnabled(true)
	self.btn_rank_ninjaLV:setEnabled(false)
	--请求
	self:startRequestRankInfo(3)
	self.m_cur_type = 3
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
				end
			end
		end
		self.node_:setTouchEnabled(true)
		self.node_:registerScriptTouchHandler(CCLayerTouch, false, kCCMenuHandlerPriority-1, true)

		
		local function onBtnRaise(btn)
			CSoundMgr:instance():PlayEffect(SOUND_BUTTON)
			---[[跳转到商城
			GetMainMenu():ChangeToSub(E_STOREITEMSVIEW)
			--]]			
		end
		
		local function onBtnBack(btn, event)
			CSoundMgr:instance():PlayEffect(SOUND_BUTTON)
			GetMainMenu():ChangeToSub(E_DEFAULTMENU)
		end

		--attack
		self.btn_rank_attack:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.proxy_:handleButtonEvent(self.btn_rank_attack, function(button, event)
			self:onBtnAttackRank();
			return nil
		end, CCControlEventTouchUpInside)
		--def
		self.btn_rank_def:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.proxy_:handleButtonEvent(self.btn_rank_def, function(button, event)
			self:onBtnDefRank();
			return nil
		end, CCControlEventTouchUpInside)
		--ninjaLv
		self.btn_rank_ninjaLV:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.proxy_:handleButtonEvent(self.btn_rank_ninjaLV, function(button, event)
			self:onBtnNinjaLvRank();
			return nil
		end, CCControlEventTouchUpInside)
		--rase
		self.btn_raise:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.proxy_:handleButtonEvent(self.btn_raise, onBtnRaise, CCControlEventTouchUpInside)
		--back
		self.btnBack:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.proxy_:handleControlEvent(self.btnBack, onBtnBack, CCControlEventTouchUpInside)
	end
end

function createRankTableView(self)
	if self.rankTableView == nil then
		local cellContentSize = self.node_cell:getContentSize()
		self.rank_cellsize = CCSizeMake(cellContentSize.width,cellContentSize.height)

		self.rank_tableContentSize = self.node_content:getContentSize()
		self:initRankTableHandle()
		self.rankTableView = LuaTableView:createWithHandler(self.rankTableViewHandler, CCSizeMake(self.rank_tableContentSize.width, self.rank_tableContentSize.height))
		self.rankTableView:setDirection(kCCScrollViewDirectionVertical)
		self.rankTableView:setVerticalFillOrder(kCCTableViewFillTopDown)
		self.rankTableView:setTouchPriority(kCCMenuHandlerPriority - 1)

		self.node_content:addChild(self.rankTableView)
	else
		self.rankTableView:reloadData()
	end
end

function initRankTableHandle(self)
	self.rankTableViewHandler = LuaEventHandler:create(function(fn, table, a1, a2, x, y)
		local r
		if fn == "cellSize" then
			r = self.rank_cellsize;
		elseif fn == "cellAtIndex" then
    		local nodeLayer = createObj(ui_hallOfFameCell, self.rank_cellsize, self.m_playerDatas[a1 + 1])
			--tableView cell container
			self.cellNodes[a1+1] = nodeLayer
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
			---[[
			local cell_index = a1:getIdx() + 1
			local cellData = self.m_playerDatas[cell_index]
			if self.cellNodes[cell_index].btn_fight:boundingBox():containsPoint(self.m_touchPoint) then
				local sub_uid = string.reverse(string.sub(string.reverse(cellData.id), 6))
				if tostring(sub_uid) ~= tostring(self.playerData_.m_uid) then
					self:OnBtnFight(cell_index)
					self.m_touchPoint = nil
				end	    
				--]]
			end
			self.cellNodes[cell_index].btn_fight:setScale(1.0);
			--]]
		elseif fn == "cellTouchBegan" then		-- A cell is touching, a1 is cell, a2 is CCTouch
			local cell_index = a1:getIdx() + 1
			self.m_touchPoint = a2:getLocation()
			self.m_touchPoint = a1:convertToNodeSpace(self.m_touchPoint)
			if self.cellNodes[cell_index].btn_fight:boundingBox():containsPoint(self.m_touchPoint) then
				self.cellNodes[cell_index].btn_fight:setScale(1.1);
			end
			r = true
		elseif fn == "cellTouchEnded" then		-- A cell was touched, a1 is cell, a2 is CCTouch
			local cell_index = a1:getIdx() + 1
			self.cellNodes[cell_index].btn_fight:setScale(1.0);
			r = true
		elseif fn == "cellHighlight" then		-- A cell is highlighting, coco2d-x 2.1.3 or above
		elseif fn == "cellUnhighlight" then		-- A cell had been unhighlighted, coco2d-x 2.1.3 or above
			local cell_index = a1:getIdx() + 1
			self.cellNodes[cell_index].btn_fight:setScale(1.0);
		elseif fn == "cellWillRecycle" then		-- A cell will be recycled, coco2d-x 2.1.3 or above
		end
		return r
	end)
end

function OnBtnFight(self, index)
	CSoundMgr:instance():PlayEffect(SOUND_BUTTON)
	if index < 0 or index > #self.m_playerDatas then
		GetMainMenu():ShowTextTip(localizable.ui_hall_net_error, -1)
		return nil
	end

	local cellData = self.m_playerDatas[index]
	local sub_uid = string.reverse(string.sub(string.reverse(cellData.id), 6))

	--显示pvp战斗
	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 2701, "rl_w_pvp")
	urlpath = AddData(urlpath, "ToUid", tostring(sub_uid))
	cclog("rl_w_pvp---clearCGI----%s", urlpath)
	GetMainMenu():ShowLoadingDlg()
	CCHttpRequest:open(urlpath, kHttpPost,"query=param1&other=params"):sendWithHandler(
		function(res, hnd)
			GetMainMenu():CloseLoadding()
			local resData = res:getResponseData()
			local code = res:getResponseCode()
			local xfile = xml.parse(resData)
			local item = xfile:find("RENLONG")
			if item == nil then
				return nil
			end
			local retcode = item.code
			cclog("rl_w_pvp--pvpCGI--%s", resData)
			if retcode == "0" then
				--显示战斗过程动画
				--GetMainMenu():ShowArenaView(resData)
				local fightinfo = item:find("fight")
				local resultData = CFightResultData:instance()
				resultData:Clear()
				InitFightXML(fightinfo, resultData)
				resultData:SetFightType(FT_FIGHT)
				
				local awardXML
				local hasAward = false
				for i = 1, #item do
					if item[i][0] == "award" then
						hasAward = true
						awardXML = item[i]
					end
				end
				if hasAward == true then
					InitAwardData(resultData:GetRewardData(),awardXML)
					CPlayerDataMgr:instance():AddDataFromReward(resultData:GetRewardData())
				end
				
				local fightview = CRoundFightView:new()
				fightview:init()
				GetMainMenu():addChild(fightview,5)
				fightview:Start()
				fightview:release()									
			elseif retcode == "240002" then
				local function ret_1(self)
					-- body
				end

				local function ret_2(self)
					-- body
				end
				GetMainMenu():ShowTextTip(localizable.ui_hall_attack_value_not_enougt, -1)
				--购买兵粮丸提示框
				ShowCommonBuyItemDialog(kConsumableTypeItem, SMALL_PK_ENERGY_ITEM_ID, BIG_PK_ENERGY_ITEM_ID, 0)
				--[[
				local tradeMgr_ = CTradeMgr:instance()
				tradeMgr_:ShowBuyDialogForLua(kConsumablePkEnergy, ret_1, ret_2)
				--]]
			elseif retcode == "100002" then
				GetMainMenu():ShowTextTip(localizable.ui_hall_tips1, -1)
			elseif retcode == "240000" then
				GetMainMenu():ShowTextTip(localizable.ui_hall_tips2, -1)
			else
				GetMainMenu():ShowTextTip(localizable.ui_hall_net_error, -1)
			end
		end)
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