--[[
Description:限时神将活动
Company:XCKOO
Author:gongsun
Creation Date:2014/4/4
]]
require("config/firstpurchase_config")
require("ui_layer/ui_purchaseLayer")
require("ui_layer/ui_purchaseTableCell")

module("ui_limitSuperNinjaLayer", package.seeall)
baseClass(layer_base_t, ui_limitSuperNinjaLayer)

function init(self)
	--获取用户信息
	self.playerMgr_     = CPlayerDataMgr:instance()
	self.playerData_    = self.playerMgr_:GetPlayerInfoData()

	--如果期数不同，更新期数
	if activityPeriod.limitSuper.display == -1 then
		writeActivityData(self.playerData_.m_uid, activity_config.activityTipConfig.limitSuper, activityPeriod.limitSuper.period)
	end

	self.contentSize_   = GetMainMenu():GetSubContentNode():getContentSize()
	local ccbiAttrTable = {name = "activity/LimitSuperNinja.ccbi", size = self.contentSize_}
	layer_base_t.init(self, true, ccbiAttrTable)--加载ccbi

	self.deltatime           = 0	--记录自上次更新界面以后，流逝的时间
	self.leftTime            = 0  --活动倒计时
	--self.currActivityTime    = {}  --本期活动时间
	self.protect             = 0--抽卡保护
	self.leftFreeTime        = 0 --剩余免费抽取时间
	self.needGold            = 0 --所需元宝
	self.myrankData			 = {} --我的排名数据
	self.currSuperNinjaData  = {} --本期超忍数据
	self.integralRankData    = {}  --积分排名数据
	self.rewardInfoData      = {}  --奖励说明数据
	self.status				 = 0   --领取奖励状态[0活动中/1活动已结束 未领取/2活动已结束 已领取]
	self.actstatus			 = 1   --活动状态[1活动中/2活动已结束 未领取/3活动已结束 已领取]
	self.currentIndex 		 = 1
	self.superNinjaCellNodes = {}  --TableCells
	self.rankCellNodes       = {}  --TableCells
	self.infoCellNodes       = {}  --TableCells
	--self:createTestData()  --创建测试数据
	self:init_ui()  --初始化UI
end

function init_ui( self )
	if self.proxy_ ~= nil then
		self.btn_back			   = tolua.cast(self.proxy_:getNode("btn_back"), "CCControlButton")  --返回
		self.label_gold            = tolua.cast(self.proxy_:getNode("label_gold"), "CCLabelBMFont")  --我的元宝
		self.node_leftTime         = tolua.cast(self.proxy_:getNode("node_leftTime"), "CCNode")  --倒计时
		self.label_activity_over   = tolua.cast(self.proxy_:getNode("label_activity_over"), "CCLabelTTF")  --活动已结束
		self.label_leftTime        = tolua.cast(self.proxy_:getNode("label_leftTime"), "CCLabelBMFont")  --活动倒计时
		self.btn_activity_info     = tolua.cast(self.proxy_:getNode("btn_activity_info"), "CCControlButton")  --活动说明
		self.btn_purchase          = tolua.cast(self.proxy_:getNode("btn_purchase"), "CCControlButton")  --充值
		self.btn_pre			   = tolua.cast(self.proxy_:getNode("btn_pre"), "CCControlButton") --上一个
		self.btn_next		       = tolua.cast(self.proxy_:getNode("btn_next"), "CCControlButton") --下一个
		self.label_ninja_name      = tolua.cast(self.proxy_:getNode("label_ninja_name"), "CCLabelTTF")  --活动结束时间
		self.btn_getForFree        = tolua.cast(self.proxy_:getNode("btn_getForFree"), "CCControlButton")  --免费抽取
		self.btn_getByGold         = tolua.cast(self.proxy_:getNode("btn_getByGold"), "CCControlButton")  --元宝抽取
		self.label_leftFreeTime    = tolua.cast(self.proxy_:getNode("label_leftFreeTime"), "CCLabelBMFont")  --剩余免费抽取时间
		self.label_needGold		   = tolua.cast(self.proxy_:getNode("label_needGold"), "CCLabelBMFont")  --所需元宝
		--self.label_begindate	   = tolua.cast(self.proxy_:getNode("label_begindate"), "CCLabelTTF")  --活动开始时间
		--self.label_enddate	       = tolua.cast(self.proxy_:getNode("label_enddate"), "CCLabelTTF")  --活动结束时间
		self.label_protect		   = tolua.cast(self.proxy_:getNode("label_protect"), "CCLabelBMFont")  --抽卡保护次数
		self.label_myIntegral      = tolua.cast(self.proxy_:getNode("label_myIntegral"), "CCLabelBMFont")  --我的积分
		self.label_myRank	       = tolua.cast(self.proxy_:getNode("label_myRank"), "CCLabelBMFont")  --我的排名
		self.btn_getReward         = tolua.cast(self.proxy_:getNode("btn_getReward"), "CCControlButton")  --领取奖励
		self.node_superninja_table = tolua.cast(self.proxy_:getNode("node_superninja_table"), "CCNode")  --TableNode
		self.node_superninja_cell  = tolua.cast(self.proxy_:getNode("node_superninja_cell"), "CCNode")  --CellsNode
		self.node_rank_table       = tolua.cast(self.proxy_:getNode("node_rank_table"), "CCNode")  --TableNode
		self.node_rank_cell        = tolua.cast(self.proxy_:getNode("node_rank_cell"), "CCNode")  --CellsNode
		self.node_info_table       = tolua.cast(self.proxy_:getNode("node_info_table"), "CCNode")  --TableNode
		self.node_info_cell        = tolua.cast(self.proxy_:getNode("node_info_cell"), "CCNode")  --CellsNode

		--隐藏限制_litao_2014.8.20
        self.m_limitDesc           = tolua.cast(self.proxy_:getNode("label_limit_desc"), "CCLabelTTF")
        self.width_limitDesc = self.m_limitDesc:getContentSize().width

        -- 刷新数据
		local function freshTableData()
			local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 7, protocol.URL_R_COMM)
		    --cclog("url-------------------------------%s", urlpath)
			GetMainMenu():ShowLoadingDlg();	-- 获取信息的时候，不允许操作
			CCHttpRequest:open(urlpath, kHttpPost,"query=param1&other=params"):sendWithHandler(
				function(res, hnd)
					GetMainMenu():CloseLoadding() --获取信息完成时，解除禁止操作

					local resData = res:getResponseData()
					--cclog("data----------------%s",resData)
					local code = res:getResponseCode()
					local xfile = xml.parse(resData)
					local item = xfile:find("RENLONG")
					local retcode = item.code

					if retcode == "0" then
						local preview = item:find("preview")
						local ranklist = item:find("ranklist")

						if preview then
						    self.leftFreeTime = tonumber(preview.nextfreetime)
						    self.protect = tonumber(preview.protect) - 1
						    self.status = tonumber(preview.status)
						    self.actstatus = tonumber(preview.actstatus)
						    self.myrankData = {rank=preview.rank, score=preview.score}
						end
						if ranklist then
							self.integralRankData = {}
							for i = 1, #ranklist do
								self.integralRankData[i] = {rank=ranklist[i].rank, nickname=ranklist[i].nick, score=ranklist[i].score}
							end
						end
						--刷新数据
						self.label_protect:setString(tostring(self.protect))
						self.label_gold:setString(self.playerData_.m_gold)
						self.label_myRank:setString(self.myrankData.rank)
						self.label_myIntegral:setString(self.myrankData.score)
						if self.rankTableView ~= nil then
							--local offset = self.rankTableView:getContentOffset()
							self.rankTableView:reloadData()
							--self.rankTableView:setContentOffset(offset.x, offset.y)
						end
					end
				end)
		end

		--时间倒计时
		local function updateLeftTimeLabel(fDeltaTime)
			self.deltatime = self.deltatime + fDeltaTime
			if self.deltatime >= 1 then
				local intPart, floatPart = math.modf(self.deltatime)
				self.leftTime = self.leftTime - intPart
				self.leftFreeTime = self.leftFreeTime - intPart
				local leftTimeStr = tools.convertTimeElectronicWatch(self.leftTime, 3)
				local leftFreeTimeStr = tools.convertTimeElectronicWatch(self.leftFreeTime, 3)
				self.label_leftTime:setString(leftTimeStr)
				self.label_leftFreeTime:setString(leftFreeTimeStr)
				self.deltatime = floatPart
				if self.leftTime <= 0 then
					self.label_leftTime:unscheduleUpdate()--时间到，活动结束，停止倒计时
					self.node_leftTime:setVisible(false)
					self.label_activity_over:setVisible(true)
					if self.actstatus == 1 then
						freshTableData()
					end
				end
			end
		end

		--返回回调
		local function back_callback(btn, event)
			GetMainMenu():ChangeToSub(E_DEFAULTMENU)
		end
		--pre回调
		local function pre_callback(btn, event)
			local offset = self.superNinjaTableView:getContentOffset()
			if offset.x ~= -(self.currentIndex-1)*self.superninja_tableContentSize.width then
				return
			end
			self.superNinjaTableView:unscheduleAllSelectors()
			if self.currentIndex > 1 then
				self.currentIndex = self.currentIndex - 1
				local offset = self.superNinjaTableView:getContentOffset()
				local targetCardOffsetX = -(self.currentIndex-1)*self.superninja_tableContentSize.width
				local adjustAnimDelay = (math.abs(targetCardOffsetX-offset.x) * 1.0) / 5000
				self.superNinjaTableView:setContentOffsetInDuration(ccp(targetCardOffsetX, 0), adjustAnimDelay)
				self.label_ninja_name:setString(self.currSuperNinjaData[self.currentIndex].name)
			end
		end
		--next回调
		local function next_callback(btn, event)
			local offset = self.superNinjaTableView:getContentOffset()
			if offset.x ~= -(self.currentIndex-1)*self.superninja_tableContentSize.width then
				return
			end
			self.superNinjaTableView:unscheduleAllSelectors()
			if self.currentIndex < #self.currSuperNinjaData then
				self.currentIndex = self.currentIndex + 1
				local targetCardOffsetX = -(self.currentIndex-1)*self.superninja_tableContentSize.width
				local adjustAnimDelay = (math.abs(targetCardOffsetX-offset.x) * 1.0) / 5000
				self.superNinjaTableView:setContentOffsetInDuration(ccp(targetCardOffsetX, 0), adjustAnimDelay)
				self.label_ninja_name:setString(self.currSuperNinjaData[self.currentIndex].name)
			end
		end
		--活动说明回调
		local function activityInfo_callback(btn, event)	
			local dlg = CommonDialogView.create()
			CommonDialogView.m_selfview = dlg;
			dlg:SetTitle(localizable.ui_firstmoneyaward_dlg_title)
			dlg:SetDescription(localizable.ui_activity_description)
			dlg:loadCCBI();
			dlg:initUI()
			GetMainMenu():GetModelLayer():AddDialog(dlg, 3);
		end
		--充值回调
		local function purchase_callback(btn, event)
			local puchaseLayer = createObj(ui_purchaseLayer)
			GetMainMenu():GetModelLayer():AddDialog(puchaseLayer.node_, 3)
		end
		--免费抽取回调
		local function getForFree_callback(btn, event)
			--litao_限制刷小号_等级限制_2014.6.24
			local _playerData_ = CPlayerDataMgr:instance():GetPlayerInfoData()
			--get info from table_bin
			local config_info_level = DataMgr.GetDataByID("Struct_Functionconfig", 17)
			--判断等级
			if nil ~= config_info_level then 
			    if _playerData_.m_level < tonumber(config_info_level.m_needlevel) then
					GetMainMenu():ShowTextTip(tostring(config_info_level.m_tipinfo), -1)
					return nil
				end
			end
			if self.actstatus == 1 then
				if self.leftFreeTime <= 0 then
					--[[
					local dlg = CCommonPrayDialogView:create()
					dlg:SetPrayFree(true)
					dlg:SetPrayoneCost(self.needGold)
					dlg:SetPrayCmd(1902)
					dlg:SetPrayOneDoneCallbackForScript(freshTableData)
					dlg:SetPrayTenDoneCallbackForScript(freshTableData)
					dlg:initView()
					GetMainMenu():AddDialog(dlg)
					]]
					local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 1902, protocol.URL_NINJARECRUIT)
					urlpath = AddData(urlpath, "Type", 1)
					urlpath = AddData(urlpath, "Free", 1)
					--cclog("url-----%s", urlpath)
					GetMainMenu():ShowLoadingDlg();	-- 获取信息的时候，不允许操作
					CCHttpRequest:open(urlpath, kHttpPost,"query=param1&other=params"):sendWithHandler(
						function(res, hnd)
							GetMainMenu():CloseLoadding() --获取信息完成时，解除禁止操作

							local resData = res:getResponseData()
							--cclog("data---%s",resData)
							local code = res:getResponseCode()
							local xfile = xml.parse(resData)
							local item = xfile:find("RENLONG")
							local retcode = item.code

							if retcode == "0" then
								local awardXML = xfile:find("award")
								ShowAward(awardXML)
								
								freshTableData()
							else
								GetMainMenu():ShowErrorTip(retcode,-1)
							end
						end)
				else
					GetMainMenu():ShowErrorTip(80003,-1)
				end
			else
				GetMainMenu():ShowErrorTip(312000,-1)
			end
		end
		--元宝抽取回调
		local function getByGold_callback(btn, event)
			--litao_限制刷小号_等级限制_2014.6.24
			local _playerData_ = CPlayerDataMgr:instance():GetPlayerInfoData()
			--get info from table_bin
			local config_info_level = DataMgr.GetDataByID("Struct_Functionconfig", 17)
			--判断等级
			if nil ~= config_info_level then 
			    if _playerData_.m_level < tonumber(config_info_level.m_needlevel) then
					GetMainMenu():ShowTextTip(tostring(config_info_level.m_tipinfo), -1)
					return nil
				end
			end
			if self.actstatus == 1 then
				--[[
				if self.needGold <= self.playerData_.m_gold then
					local dlg = CCommonPrayDialogView:create()
					dlg:SetPrayFree(false)
					dlg:SetPrayoneCost(self.needGold)
					dlg:SetPrayCmd(1900)
					dlg:SetPrayOneDoneCallbackForScript(freshTableData)
					dlg:SetPrayTenDoneCallbackForScript(freshTableData)
					dlg:initView()
					GetMainMenu():AddDialog(dlg)
				else
					local dlg = CommonDialogView.create()
					CommonDialogView.m_selfview = dlg;
					dlg:SetTitle("温馨提示")
					dlg:SetDescription("您的元宝不足，请充值")
					dlg:SetConfirmHandler(
					function()
						local puchaseLayer = createObj(ui_purchaseLayer)
						GetMainMenu():GetModelLayer():AddDialog(puchaseLayer.node_, 3)
					end)
					dlg:loadCCBI();
					dlg:initUI()
					GetMainMenu():GetModelLayer():AddDialog(dlg, 3);
				end]]
				local dlg = CCommonPrayDialogView:create()
				dlg:SetIsCostPray(1)
				dlg:SetPrayFree(false)
				dlg:SetPrayoneCost(self.needGold)
				dlg:SetPrayCmd(1900)
				dlg:SetPrayOneDoneCallbackForScript(freshTableData)
				dlg:SetPrayTenDoneCallbackForScript(freshTableData)
				dlg:initView()
				GetMainMenu():AddDialog(dlg)
			else
				GetMainMenu():ShowErrorTip(312000,-1)
			end
		end
		--领取奖励回调
		local function getReward_callback(btn, event)
			if self.actstatus == 1 then--活动中
				GetMainMenu():ShowErrorTip(315005,-1)
				--GetMainMenu():ShowTextTip(tostring("活动未结束!累计积分不足"..self.limit_score..",活动结束后第一名排行奖励无法领取!"), -1)
			elseif self.actstatus == 2 then--活动结束
				if self.status == 1 then--可领取奖励
					local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 11, protocol.URL_W_COMM)
					--cclog("url-----%s", urlpath)
					GetMainMenu():ShowLoadingDlg();	-- 获取信息的时候，不允许操作
					CCHttpRequest:open(urlpath, kHttpPost,"query=param1&other=params"):sendWithHandler(
						function(res, hnd)
							GetMainMenu():CloseLoadding() --获取信息完成时，解除禁止操作

							local resData = res:getResponseData()
							--cclog("data---%s",resData)
							local code = res:getResponseCode()
							local xfile = xml.parse(resData)
							local item = xfile:find("RENLONG")
							local retcode = item.code

							if retcode == "0" then
								local preview = xfile:find("preview")
								if preview then
									self.status = tonumber(preview.status)
								end
								local awardXML = xfile:find("award")
								ShowAward(awardXML)
								--下限限制码_litao_2014.5.29
								--[[
								local _limitCode = tonumber(xfile:find("limitcode")[1])
								if _limitCode < 0 then
									GetMainMenu():ShowErrorTip(100,-1)
								else
									GetMainMenu():ShowErrorTip(_limitCode, -1)
								end
								--]]
							else
								GetMainMenu():ShowErrorTip(retcode,-1)
							end
						end)
				else--已领取奖励
					GetMainMenu():ShowErrorTip(315006,-1)
				end
			else
				GetMainMenu():ShowErrorTip(312000,-1)
			end
		end

		local function onTouchBegan(x, y)
			self.touchBegan = CCPointMake(x,y)
			local offset = self.superNinjaTableView:getContentOffset()
			if offset.x ~= -(self.currentIndex-1)*self.superninja_tableContentSize.width then
				offset.x = -(self.currentIndex-1)*self.superninja_tableContentSize.width
				self.superNinjaTableView:setContentOffset(offset.x, 0)
			end
			return true
		end 

		local function onTouchMoved(x, y)

		end

		local function onTouchEnded(x, y)
			self.touchEnd = CCPointMake(x,y)

			if self.touchEnd.x ~= self.touchBegan.x then
				self.superNinjaTableView:unscheduleAllSelectors()
				local offset = self.superNinjaTableView:getContentOffset()
				
				if self.touchEnd.x - self.touchBegan.x < -30 then--向左滑动
					if self.currentIndex < #self.currSuperNinjaData then
						self.currentIndex = self.currentIndex + 1
					end
				elseif self.touchEnd.x - self.touchBegan.x > 30 then--向右滑动
					if self.currentIndex > 1 then
						self.currentIndex = self.currentIndex - 1
					end
				end
				local targetCardOffsetX = -(self.currentIndex-1)*self.superninja_tableContentSize.width
				local adjustAnimDelay = (math.abs(targetCardOffsetX-offset.x) * 1.0) / 5000
				self.superNinjaTableView:setContentOffsetInDuration(ccp(targetCardOffsetX, 0), adjustAnimDelay)
				self.label_ninja_name:setString(self.currSuperNinjaData[self.currentIndex].name)
			end
		end

		local function listener(eventType, x, y)
			local rectNinjaTable = self.node_superninja_table:boundingBox()
			rectNinjaTable.origin = ccp(0,0)
			local cur_p = self.node_superninja_table:convertToNodeSpace(ccp(x,y))
		    if eventType == "began" then
		    	if rectNinjaTable:containsPoint(cur_p) == true then
		        	return onTouchBegan(x, y)
		    	end
		    elseif eventType == "moved" then
		        return onTouchMoved(x, y)
		    else
		    	return onTouchEnded(x, y)
		    end
		end

		--返回按钮事件
		self.proxy_:handleControlEvent(self.btn_back, back_callback, CCControlEventTouchUpInside)
		--pre按钮事件
		self.proxy_:handleControlEvent(self.btn_pre, pre_callback, CCControlEventTouchUpInside)
		--next按钮事件
		self.proxy_:handleControlEvent(self.btn_next, next_callback, CCControlEventTouchUpInside)
		--活动说明按钮事件
		self.proxy_:handleControlEvent(self.btn_activity_info, activityInfo_callback, CCControlEventTouchUpInside)
		--充值按钮事件
		self.proxy_:handleControlEvent(self.btn_purchase, purchase_callback, CCControlEventTouchUpInside)
		--免费抽取按钮事件
		self.proxy_:handleControlEvent(self.btn_getForFree, getForFree_callback, CCControlEventTouchUpInside)
		--元宝抽取按钮事件
		self.proxy_:handleControlEvent(self.btn_getByGold, getByGold_callback, CCControlEventTouchUpInside)
		--领取奖励按钮事件
		self.proxy_:handleControlEvent(self.btn_getReward, getReward_callback, CCControlEventTouchUpInside)

		--刷新活动数据
		local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 6, protocol.URL_R_COMM)
		--cclog("url-------------------------------%s", urlpath)
		GetMainMenu():ShowLoadingDlg();	-- 获取信息的时候，不允许操作
		CCHttpRequest:open(urlpath, kHttpPost,"query=param1&other=params"):sendWithHandler(
			function(res, hnd)
				GetMainMenu():CloseLoadding() --获取信息完成时，解除禁止操作

				local resData = res:getResponseData()
				--cclog("data----------------%s",resData)
				local code = res:getResponseCode()
				local xfile = xml.parse(resData)
				local item = xfile:find("RENLONG")
				local retcode = item.code

				if retcode == "0" then
					local preview = item:find("preview")
					local ninjalist = item:find("ninjalist")
					local ranklist = item:find("ranklist")
					local myrank = item:find("myrank")
					local rewardlist = item:find("rewardlist")

					if preview then
					    self.leftTime = tonumber(preview.resttime)
					    self.leftFreeTime = tonumber(preview.nexttime)
					    --self.currActivityTime = {begindate=tonumber(preview.begindate), enddate=tonumber(preview.enddate)}
					    self.protect = tonumber(preview.protect) - 1
					    self.needGold = tonumber(preview.gold)
					    self.status = tonumber(preview.status)
					    self.actstatus = tonumber(preview.actstatus)
					    --最低分数限制_litao_2014.5.29
					    self.limit_score = tonumber(preview.limitscore)
					    self.m_limitDesc:setString(tostring(localizable.ui_limitSuperNinja_info_1..self.limit_score..localizable.ui_limitSuperNinja_info_2))
						--self.m_limitDesc:setDimensions(CCSize(self.width_limitDesc,0))
					end
					if ninjalist then
						for i=1,#ninjalist do
							self.currSuperNinjaData[i] = {name=ninjalist[i].name, ninjaid=tonumber(ninjalist[i].ninjiaid), attr=tonumber(ninjalist[i].attr), dropid=tonumber(ninjalist[i].dropid)}
						end
					end
					if ranklist then
						for i = 1, #ranklist do
							self.integralRankData[i] = {rank=ranklist[i].rank, nickname=ranklist[i].nick, score=ranklist[i].score}
						end
					end
					if myrank then
						self.myrankData = {rank=myrank.rank, score=myrank.score}
					end
					if rewardlist then
						for i = 1, #rewardlist do
							self.rewardInfoData[i] = {id=i, rankrange=rewardlist[i].rankrange, rewardName=rewardlist[i].dropinfo}
						end
					end
					--初始化数据
					self.label_gold:setString(self.playerData_.m_gold)
					self.label_myRank:setString(self.myrankData.rank)
					self.label_myIntegral:setString(self.myrankData.score)
					self.label_needGold:setString(self.needGold)
					self.label_ninja_name:setString(self.currSuperNinjaData[1].name)
					--self.label_begindate:setString(os.date("%Y年%m月%d日%H点", self.currActivityTime.begindate))
					--self.label_enddate:setString(os.date("%Y年%m月%d日%H点", self.currActivityTime.enddate))
					self.label_protect:setString(tostring(self.protect))

					self:createCurrSuperNinjaTableView()  --创建本期超忍TableView
					self:createIntegralRankTableView()  --创建积分排行TableView
					self:createRewardInfoTableView()  --创建奖励说明TableView
					if self.actstatus == 1 then--活动正在进行中，启动倒计时
						self.label_leftTime:scheduleUpdateWithPriorityLua(updateLeftTimeLabel, 0)  --启动定时器更新剩余时间
						self.node_leftTime:setVisible(true)
						self.label_activity_over:setVisible(false)
					else
						self.node_leftTime:setVisible(false)
						self.label_activity_over:setVisible(true)
					end
					self.label_leftTime:setString(tools.convertTimeElectronicWatch(self.leftTime, 3))  --显示剩余活动时间 分钟:秒的格式
					self.label_leftFreeTime:setString(tools.convertTimeElectronicWatch(self.leftFreeTime, 3))  --显示剩余免费抽取时间 分钟:秒的格式
				end
			end)
		self.node_:setTouchEnabled(true)
		self.node_:registerScriptTouchHandler(listener, false, 2, false)
	end
end

--清除Node
function onNodeCleanup(self)
	if self.proxy_ then
    	self.proxy_:release()
    end
    layer_base_t.onNodeCleanup(self)
end

--创建本期超忍TableView
function createCurrSuperNinjaTableView(self, data)
	if self.superNinjaTableView == nil then
		self.superninja_tableContentSize = self.node_superninja_table:getContentSize()  --根据TableNode的ContentSize设置TableView的size
		self.superninja_cellsize = self.node_superninja_cell:getContentSize()  --根据CellsNode的ContentSize设置tableview的cellsize
		self:initSuperNinjaTableHandle()  --实现tableview的各虚函数
		self.superNinjaTableView = LuaTableView:createWithHandler(self.superNinjaTableViewHandler, CCSizeMake(self.superninja_tableContentSize.width, self.superninja_tableContentSize.height))  --创建一个tableview
		self.superNinjaTableView:setDirection(kCCScrollViewDirectionHorizontal)  --设置方向为横向
		self.superNinjaTableView:setVerticalFillOrder(kCCTableViewFillTopDown)  --设置填充顺序为从上到下
		self.superNinjaTableView:setTouchPriority(1)  --设置触摸优先级为-10
		self.node_superninja_table:addChild(self.superNinjaTableView)  --把创建的tableview添加到TableNode中
	end
end

--实现本期超忍TableView的各虚函数
function initSuperNinjaTableHandle(self)
	self.superNinjaTableViewHandler = LuaEventHandler:create(function(fn, table, a1, a2, x, y)
		local r
		if fn == "cellSize" then  --获取tableview的cellsize
			r = self.superninja_cellsize
		elseif fn == "cellAtIndex" then
			-- 请求cell对象，a1是索引（从0开始），a2是缓存的cell对象（可能为空）
    		local nodeLayer = createObj(ui_currSuperNinjaTableCell, self.superninja_cellsize, self.currSuperNinjaData[a1 + 1])
    		self.superNinjaCellNodes[a1 + 1] = nodeLayer
			if not a2 then
				a2 = CCTableViewCell:create()
				nodeLayer.node_:setTag(100)
				a2:addChild(nodeLayer.node_)
			else
				a2:removeAllChildrenWithCleanup(true)
				nodeLayer.node_:setAnchorPoint(ccp(0.5,0.5))
				nodeLayer.node_:setPosition(self.superninja_cellsize.width / 2, self.superninja_cellsize.height / 2)
				nodeLayer.node_:ignoreAnchorPointForPosition(false)
				nodeLayer.node_:setTag(100)
        		a2:addChild(nodeLayer.node_)
			end
			r = a2
		elseif fn == "numberOfCells" then  --cell的总个数
			r = #self.currSuperNinjaData;
		    -- Cell events:
		elseif fn == "cellTouched" then			-- A cell was touched, a1 is cell that be touched. This is not necessary.
			local cellIndex = a1:getIdx() + 1
			if self.superNinjaCellNodes[cellIndex].node_ninja:boundingBox():containsPoint(self.m_touchPoint) then
				CGameObjElement:ShowDropByID(self.currSuperNinjaData[cellIndex].dropid)
			end
			r = true
		elseif fn == "cellTouchBegan" then		-- A cell is touching, a1 is cell, a2 is CCTouch
			self.m_touchPoint = a2:getLocation()
			local cell = a1:getChildByTag(100);
			cell = tolua.cast(cell,"CCNode")
			self.m_touchPoint = cell:convertToNodeSpace(self.m_touchPoint)

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

--创建积分排名TableView
function createIntegralRankTableView(self, data)
	if self.rankTableView == nil then
		self.rank_tableContentSize = self.node_rank_table:getContentSize()  --根据TableNode的ContentSize设置TableView的size
		self.rank_cellsize = self.node_rank_cell:getContentSize()  --根据CellsNode的ContentSize设置tableview的cellsize
		self:initRankTableHandle()  --实现tableview的各虚函数
		self.rankTableView = LuaTableView:createWithHandler(self.rankTableViewHandler, CCSizeMake(self.rank_tableContentSize.width, self.rank_tableContentSize.height))  --创建一个tableview
		self.rankTableView:setDirection(kCCScrollViewDirectionVertical)  --设置方向为竖向
		self.rankTableView:setVerticalFillOrder(kCCTableViewFillTopDown)  --设置填充顺序为从上到下
		self.rankTableView:setTouchPriority(-10)  --设置触摸优先级为-10
		self.node_rank_table:addChild(self.rankTableView)  --把创建的tableview添加到TableNode中
	end
end

--实现积分排名TableView的各虚函数
function initRankTableHandle(self)
	self.rankTableViewHandler = LuaEventHandler:create(function(fn, table, a1, a2, x, y)
		local r
		if fn == "cellSize" then  --获取tableview的cellsize
			r = self.rank_cellsize
		elseif fn == "cellAtIndex" then
			-- 请求cell对象，a1是索引（从0开始），a2是缓存的cell对象（可能为空）
    		local nodeLayer = createObj(ui_integralRankTableCell, self.rank_cellsize, self.integralRankData[a1 + 1])
    		self.rankCellNodes[a1 + 1] = nodeLayer
			if not a2 then
				a2 = CCTableViewCell:create()
				nodeLayer.node_:setTag(101)
				a2:addChild(nodeLayer.node_)
			else
				a2:removeAllChildrenWithCleanup(true)
				nodeLayer.node_:setAnchorPoint(ccp(0.5,0.5))
				nodeLayer.node_:setPosition(self.rank_cellsize.width / 2, self.rank_cellsize.height / 2)
				nodeLayer.node_:ignoreAnchorPointForPosition(false)
				nodeLayer.node_:setTag(101)
        		a2:addChild(nodeLayer.node_)
			end
			r = a2
		elseif fn == "numberOfCells" then  --cell的总个数
			r = #self.integralRankData;
		    -- Cell events:
		elseif fn == "cellTouched" then			-- A cell was touched, a1 is cell that be touched. This is not necessary.
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

--创建奖励说明TableView
function createRewardInfoTableView(self, data)
	if self.infoTableView == nil then
		self.info_tableContentSize = self.node_info_table:getContentSize()  --根据TableNode的ContentSize设置TableView的size
		self.info_cellsize = self.node_info_cell:getContentSize()  --根据CellsNode的ContentSize设置tableview的cellsize
		self:initInfoTableHandle()  --实现tableview的各虚函数
		self.infoTableView = LuaTableView:createWithHandler(self.infoTableViewHandler, CCSizeMake(self.info_tableContentSize.width, self.info_tableContentSize.height))  --创建一个tableview
		self.infoTableView:setDirection(kCCScrollViewDirectionVertical)  --设置方向为竖向
		self.infoTableView:setVerticalFillOrder(kCCTableViewFillTopDown)  --设置填充顺序为从上到下
		self.infoTableView:setTouchPriority(-10)  --设置触摸优先级为-10
		self.node_info_table:addChild(self.infoTableView)  --把创建的tableview添加到TableNode中
	end
end

--实现奖励说明TableView的各虚函数
function initInfoTableHandle(self) 
	self.infoTableViewHandler = LuaEventHandler:create(function(fn, table, a1, a2, x, y)
		local r
		if fn == "cellSize" then  --获取tableview的cellsize
			r = self.info_cellsize
		elseif fn == "cellAtIndex" then
			-- 请求cell对象，a1是索引（从0开始），a2是缓存的cell对象（可能为空）
    		local nodeLayer = createObj(ui_rewardInfoTableCell, self.info_cellsize, self.rewardInfoData[a1 + 1])
    		self.infoCellNodes[a1 + 1] = nodeLayer
			if not a2 then
				a2 = CCTableViewCell:create()
				nodeLayer.node_:setTag(101)
				a2:addChild(nodeLayer.node_)
			else
				a2:removeAllChildrenWithCleanup(true)
				nodeLayer.node_:setAnchorPoint(ccp(0.5,0.5))
				nodeLayer.node_:setPosition(self.info_cellsize.width / 2, self.info_cellsize.height / 2)
				nodeLayer.node_:ignoreAnchorPointForPosition(false)
				nodeLayer.node_:setTag(101)
        		a2:addChild(nodeLayer.node_)
			end
			r = a2
		elseif fn == "numberOfCells" then  --cell的总个数
			r = #self.rewardInfoData;
		    -- Cell events:
		elseif fn == "cellTouched" then			-- A cell was touched, a1 is cell that be touched. This is not necessary.
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

--创建测试数据
function createTestData(self)
	--self.leftTime = 183811
	--self.leftFreeTime = 144888
	--self.status = 1

	for i=1,5 do
		self.currSuperNinjaData[i] = {rankid=i, name="宇智波波波波", ninjiaid=i, attri=2}
	end

	--[[for i=1,10 do
		self.integralRankData[i] = {rank=i, nickname="风雷之水火土", score=(10000-i)}	
	end]]

	for i=1,5 do
		self.rewardInfoData[i] = {id=i, rankrange="100-500", rewardName="六道仙人"..i}
	end
end