--descriptioin:秘宝
--company: xckoo
--author: litao
--date: 2013-06-11
---------------------------------------------
require("ui_layer/ui_rewardDlgLayer")
require("ui_layer/ui_rewardDlgCell")
require("ui_layer/ui_rewardDlgCell_cell")
require("ui_layer/ui_ninjaTrasureTopViewLayer.lua")

module("ui_ninjaTreasureLayer", package.seeall)
baseClass(layer_base_t, ui_ninjaTreasureLayer)

function init(self)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	self.contentSize_ = GetMainMenu():GetSubContentNode():getContentSize()

	local ccbiAttrTable = {name="activity/NinjaTreasureView.ccbi", size=self.contentSize_}
	layer_base_t.init(self, true, ccbiAttrTable)

	--活动剩余时间
	self.m_left_time = 0
	--剩余刷新时间
	self.m_refresh_time = 0
	--9个格子物品列表
	self.m_itemlist = {}
	--奖励信息
	self.m_awardXml = {}
	--奖励物品索引(1-9也可以作为路径)
	self.m_rewardIdx = -1
	--时间增量
	self.deltatime = 0
	--秘宝刷新时间增量
	self.re_deltatime = 0
	--刷新一次消耗元宝数
	self.m_gold_one_refresh = 0
	--探索一次消耗元宝数
	self.m_gold_one_search = 0
	--全部购买消耗元宝数
	self.m_gold_buy_all = 0
	--探索一次是否结束标志
	self.bSearchOver = true
	--随机物品框
	self.m_randNumSeq = {}
	--随机闪烁个数
	self.m_lightNum = 15
	--当前闪烁个数
	self.m_curNum = 0
	--格子总数
	self.m_totalItemCount = 9
	--活动状态(0结束/1开启)
	self.m_act_state = 0

	self:init_ui()
	self:init_binding_event()
end

function init_ui(self)
	--初始化界面信息
	if self.proxy_ ~= nil then
		--label
		self.label_gold = tolua.cast(self.proxy_:getNode("label_gold"), "CCLabelBMFont")
		self.label_silver = tolua.cast(self.proxy_:getNode("label_silver"), "CCLabelBMFont")
		self.label_gold_refresh = tolua.cast(self.proxy_:getNode("label_gold_update"), "CCLabelBMFont")
		self.label_gold_find = tolua.cast(self.proxy_:getNode("label_gold_find"), "CCLabelBMFont")
		self.label_update_time = tolua.cast(self.proxy_:getNode("label_update_time"), "CCLabelBMFont")
		self.label_act_time = tolua.cast(self.proxy_:getNode("label_act_time"), "CCLabelTTF")
		--btn
		self.btn_get_all = tolua.cast(self.proxy_:getNode("btn_get_all"), "CCControlButton")
		self.btn_refresh = tolua.cast(self.proxy_:getNode("btn_update_treasure"), "CCControlButton")
		self.btn_back = tolua.cast(self.proxy_:getNode("btn_back"), "CCControlButton")
		self.btn_start_find = tolua.cast(self.proxy_:getNode("btn_start_find"), "CCControlButton")
		self.btnPreviewTop = tolua.cast(self.proxy_:getNode("btn_preview_top"),"CCControlButton")
		--9*9
		for i=1,9 do
			self["btn_icon" .. tostring(i)] = tolua.cast(self.proxy_:getNode("btn_icon" .. tostring(i)), "CCControlButton")	
			self["sprite_hl_"..tostring(i)] = tolua.cast(self.proxy_:getNode("sprite_hl_" .. tostring(i)), "CCSprite")	
			self["spr_icon_"..tostring(i)] = tolua.cast(self.proxy_:getNode("spr_icon_" .. tostring(i)), "CCSprite")
			self["node_icon_"..tostring(i)] = tolua.cast(self.proxy_:getNode("node_icon_" .. tostring(i)), "CCNode")
			self["spr_got_item_"..tostring(i)] = tolua.cast(self.proxy_:getNode("spr_got_item_"..tostring(i)), "CCSprite")
			self["spr_got_item_"..tostring(i)]:setVisible(false)		
			self["label_item_num_"..tostring(i)] = tolua.cast(self.proxy_:getNode("label_item_num_"..tostring(i)), "CCLabelBMFont")
		end

		--player info
		self.label_gold:setString(self.playerData_.m_gold)
		self.label_silver:setString(self.playerData_.m_silver)
		--request base info
		self:startRequestBaseInfo(false)	
	end
end

function init_ui_ext(self)
	--player info
	self.label_gold:setString(self.playerData_.m_gold)
	self.label_silver:setString(self.playerData_.m_silver)
	--cost info
 	self.label_gold_find:setString(self.m_gold_one_search)
	self.label_gold_refresh:setString(self.m_gold_one_refresh)

    --固定9个item info
	for i = 1, #self.m_itemlist do
		--清除以前的
		if self["node_icon_"..tostring(i)]:getChildByTag(99) then
			self["node_icon_"..tostring(i)]:removeChildByTag(99, true)
		end
		local pProgram = CCShaderCache:sharedShaderCache():programForKey("ShaderPositionTextureColor")
		self["spr_icon_"..tostring(i)]:setShaderProgram(pProgram)
		--icon/frame
		local _maintype = 0
		local _subtype = 0
		local _id = -1
		local _obj_info = {}
		_maintype, _subtype, _id = setObjTypeInfo(self.m_itemlist[i].id)
		_obj_info.pIcon, _obj_info.pFrame, _obj_info.quality, _obj_info.objname = rl_get_iconsprite(_maintype, _subtype, E_FRAMETYPE_SMALL, _id)
		if nil ~= _obj_info.pFrame then
			self["spr_icon_"..tostring(i)]:setDisplayFrame(_obj_info.pFrame)
		end
		if nil ~= _obj_info.pIcon then
			self["node_icon_"..tostring(i)]:addChild(_obj_info.pIcon)
			local size = self["node_icon_"..tostring(i)]:getContentSize()
			_obj_info.pIcon:setPosition(ccp(size.width * 0.5, size.height * 0.5))
			_obj_info.pIcon:setAnchorPoint(ccp(0.5, 0.5))
			_obj_info.pIcon:setTag(99)
			_obj_info.pIcon:setScale(0.8)
		end
		--bGot
		if 1 == tonumber(self.m_itemlist[i].bGot) then
			self["spr_got_item_"..tostring(i)]:setVisible(true)
			--灰化中奖格子
			local _icon = self["node_icon_"..tostring(i)]:getChildByTag(99)
			if _icon then
				local pProgram = CCShaderCache:sharedShaderCache():programForKey("greysprite")
				_icon:setShaderProgram(pProgram)
			end
			local pProgram_1 = CCShaderCache:sharedShaderCache():programForKey("greysprite")
			self["node_icon_"..tostring(i)]:setShaderProgram(pProgram_1)
		else
			self["spr_got_item_"..tostring(i)]:setVisible(false)
		end
		--num
		self["label_item_num_"..tostring(i)]:setString(self.m_itemlist[i].num)
	end
	self:unhighlightAllItem()
 end 

function getRandCellList(self)
	local item_left_count = 0
	for i=1,#self.m_itemlist do
		if 0 == self.m_itemlist[i].bGot then
			item_left_count = item_left_count + 1	
		end
	end

	if item_left_count == 1 and item_left_count > 0 then
		--清空随机序列
		self.m_randNumSeq = {}
		table.insert(self.m_randNumSeq, self.m_rewardIdx)
	elseif item_left_count <= 0 then
		GetMainMenu():ShowTextTip(localizable.ui_ninjaTreasure_error, -1)
		--重置标志
		self.bSearchOver = true
		return nil
	else
		--清空随机序列
		self.m_randNumSeq = {}
		--防止时间短种子一样..取反取高六位
		math.randomseed(tostring(os.time()):reverse():sub(1, 6))
		--while循环
		while #self.m_randNumSeq < self.m_lightNum - 1 do
			local r_num = math.random(9)
			if #self.m_randNumSeq > 0 then
				--判断是否被获取
				if 0 == self.m_itemlist[r_num].bGot then
					if r_num ~= self.m_randNumSeq[#self.m_randNumSeq] then
						table.insert(self.m_randNumSeq, r_num)
					end
				end
			else
				table.insert(self.m_randNumSeq, r_num)
			end	
		end
		table.insert(self.m_randNumSeq, self.m_rewardIdx)
	end

	self:doRoll()
end

function startRequestBaseInfo(self)
	--活动时间刷新
	local function updateActTimeLabel(fDeltaTime)
		self.deltatime = self.deltatime + fDeltaTime
		if self.deltatime >= 1 then
			if 0 == self.m_act_state then
				self.label_update_time:unscheduleUpdate()
				self.label_act_time:setString(localizable.ui_monopoly_end)
			end
			local intPart, floatPart = math.modf(self.deltatime)
			self.m_left_time = self.m_left_time - intPart
			if self.m_left_time > 0 then
				local timeStr = tools.convertTimeElectronicWatchHaveDay(self.m_left_time, 3)
				self.label_act_time:setString(timeStr)
				self.deltatime = floatPart
			else
				self.label_act_time:setString(localizable.ui_monopoly_end)
				self.label_act_time:unscheduleUpdate()
			end
		end
	end
	--秘宝刷新时间
	local function updateRefreshTimeLabel(fDeltaTime)
		self.re_deltatime = self.re_deltatime + fDeltaTime
		if 0 == self.m_act_state then
			self.label_update_time:unscheduleUpdate()
		end
		if self.re_deltatime >= 1 then
			local intPart, floatPart = math.modf(self.re_deltatime)
			self.m_refresh_time = self.m_refresh_time - intPart
			if self.m_refresh_time >= 0 then
				local timeStr = tools.convertTimeElectronicWatch(self.m_refresh_time, 3)
				self.label_update_time:setString(timeStr)
				self.re_deltatime = floatPart
			else
				self.label_update_time:unscheduleUpdate()
				self:startRequestRefreshInfo(false)
			end
		end
	end
	---[[
	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 1, "rl_r_sudoku")
	cclog("rl_r_sudoku----%s", urlpath)
	GetMainMenu():ShowLoadingDlg()
	CCHttpRequest:open(urlpath, kHttpPost, "query=param1&other=params"):sendWithHandler(
		function(res, hnd)
			GetMainMenu():CloseLoadding();
			local resData = res:getResponseData()
			local code = res:getResponseCode()
			local xfile = xml.parse(resData)
			local item = xfile:find("RENLONG")
			if item == nil then
				--cclog("CGI : rl_r_sudoku cmd = 1 is down!")
				return nil
			end
			local retcode = item.code
			if retcode == "0" then	
				cclog("rl_r_sudoku...1..%s", resData)
				--info			
				local itemInfo = item:find("basic")
				--活动剩余时间
				self.m_left_time = tonumber(itemInfo:find("remain_time")[1])
				--刷新一次元宝消耗
				self.m_gold_one_refresh = tonumber(item:find("refresh_cash")[1])
				--探索一次元宝消耗
				self.m_gold_one_search = tonumber(item:find("lottery_cash")[1])
				--探宝全部
				self.m_gold_buy_all = tonumber(item:find("total_cash")[1])
				--刷新时间
				self.m_refresh_time = tonumber(itemInfo:find("refresh_time")[1])

				--获取9个格子的图片信息
				local itemCellList = item:find("cell_info")
				self.m_itemlist = {}
				if itemCellList then
					self.m_totalItemCount = 9 --#itemCellList
					for i = 1, #itemCellList do
						local item = {}
						item.index = tonumber(itemCellList[i].index)
						item.id = tonumber(itemCellList[i].drop_id)
						item.bGot = tonumber(itemCellList[i].got_award)
						item.num = tonumber(itemCellList[i].drop_num)
						table.insert(self.m_itemlist, item)
					end
				end

				--实时更新活动时间
				if self.m_left_time > 0 then
					self.m_act_state = 1
					self.label_act_time:scheduleUpdateWithPriorityLua(updateActTimeLabel, 0)
					self.label_act_time:setString(tools.convertTimeElectronicWatchHaveDay(self.m_left_time, 3))
				else
					self.m_act_state = 0
					self.label_act_time:setString(localizable.ui_monopoly_end)
				end
				--实时更新刷新时间
				if self.m_refresh_time >= 0 then
					self.label_update_time:scheduleUpdateWithPriorityLua(updateRefreshTimeLabel, 0)
					self.label_update_time:setString(tools.convertTimeElectronicWatch(self.m_refresh_time, 3))
				end
				--显示信息
				self:init_ui_ext()
			else
				self.label_act_time:setString(localizable.ui_monopoly_end)
				GetMainMenu():ShowTextTip(localizable.ui_monopoly_not_start,-1)
			end
		end)
	--]]
end

--所有刷新请求
function startRequestRefreshInfo(self, isCostRefresh)
	if nil == isCostRefresh then
		isCostRefresh = false
	end
	--活动时间刷新
	local function updateActTimeLabel(fDeltaTime)
		self.deltatime = self.deltatime + fDeltaTime
		if self.deltatime >= 1 then
			if 0 == self.m_act_state then
				self.label_update_time:unscheduleUpdate()
				self.label_act_time:setString(localizable.ui_monopoly_end)
			end
			local intPart, floatPart = math.modf(self.deltatime)
			self.m_left_time = self.m_left_time - intPart
			if self.m_left_time > 0 then
				local timeStr = tools.convertTimeElectronicWatchHaveDay(self.m_left_time, 3)
				self.label_act_time:setString(timeStr)
				self.deltatime = floatPart
			else
				self.label_act_time:setString(localizable.ui_monopoly_end)
				self.label_act_time:unscheduleUpdate()
			end
		end
	end
	--秘宝刷新时间
	local function updateRefreshTimeLabel(fDeltaTime)
		self.re_deltatime = self.re_deltatime + fDeltaTime
		if self.re_deltatime >= 1 then
			if 0 == self.m_act_state then
				self.label_update_time:unscheduleUpdate()
			end
			local intPart, floatPart = math.modf(self.re_deltatime)
			self.m_refresh_time = self.m_refresh_time - intPart
			if self.m_refresh_time >= 0 then
				local timeStr = tools.convertTimeElectronicWatch(self.m_refresh_time, 3)
				self.label_update_time:setString(timeStr)
				self.re_deltatime = floatPart
			else
				self.label_update_time:unscheduleUpdate()
				self:startRequestRefreshInfo(false)
			end
		end
	end
	---[[

	local urlpath
	if isCostRefresh then
		urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 1, "rl_w_sudoku")
		cclog("rl_w_sudoku----%s", urlpath)
	else
		urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 1, "rl_r_sudoku")
		cclog("rl_r_sudoku----%s", urlpath)	
	end
	--[[
	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 1, "rl_w_sudoku")
	cclog("rl_w_sudoku----%s", urlpath)
	]]
	GetMainMenu():ShowLoadingDlg()
	CCHttpRequest:open(urlpath, kHttpPost, "query=param1&other=params"):sendWithHandler(
		function(res, hnd)
			GetMainMenu():CloseLoadding();
			local resData = res:getResponseData()
			local code = res:getResponseCode()
			local xfile = xml.parse(resData)
			local item = xfile:find("RENLONG")
			if item == nil then
				cclog("CGI : rl_w_sudoku cmd = 1 is down!")
				return nil
			end
			local retcode = item.code
			if retcode == "0" then
				if isCostRefresh then
					GetMainMenu():ShowTextTip(localizable.ui_ninjaTreasure_refresh_tip, -1)
					--扣除元宝
					self.playerMgr_:AddGold(-self.m_gold_one_refresh)
					self.playerData_ = self.playerMgr_:GetPlayerInfoData()
					--player info
					self.label_gold:setString(self.playerData_.m_gold)
					self.label_silver:setString(self.playerData_.m_silver)	
				end	
				--info			
				local itemInfo = item:find("basic")
				--活动剩余时间
				self.m_left_time = tonumber(itemInfo:find("remain_time")[1])
				--刷新一次元宝消耗
				self.m_gold_one_refresh = tonumber(item:find("refresh_cash")[1])
				--探索一次元宝消耗
				self.m_gold_one_search = tonumber(item:find("lottery_cash")[1])
				--探宝全部
				self.m_gold_buy_all = tonumber(item:find("total_cash")[1])
				--刷新时间
				self.m_refresh_time = tonumber(itemInfo:find("refresh_time")[1])

				--获取9个格子的图片信息
				local itemCellList = item:find("cell_info")
				self.m_itemlist = {}
				if itemCellList then
					self.m_totalItemCount = 9 --#itemCellList
					for i = 1, #itemCellList do
						local item = {}
						item.index = tonumber(itemCellList[i].index)
						item.id = tonumber(itemCellList[i].drop_id)
						item.bGot = tonumber(itemCellList[i].got_award)
						item.num = tonumber(itemCellList[i].drop_num)
						table.insert(self.m_itemlist, item)
					end
				end

				--实时更新活动时间
				if self.m_left_time > 0 then
					self.m_act_state = 1
					self.label_act_time:unscheduleUpdate()
					self.label_act_time:scheduleUpdateWithPriorityLua(updateActTimeLabel, 0)
					self.label_act_time:setString(tools.convertTimeElectronicWatchHaveDay(self.m_left_time, 3))
				else
					self.m_act_state = 0
					self.label_act_time:setString(localizable.ui_monopoly_end)
				end
				--实时更新刷新时间
				if self.m_refresh_time >= 0 then
					self.label_update_time:unscheduleUpdate()
					self.label_update_time:scheduleUpdateWithPriorityLua(updateRefreshTimeLabel, 0)
					self.label_update_time:setString(tools.convertTimeElectronicWatch(self.m_refresh_time, 3))
				end
				--显示信息
				self:init_ui_ext()
			else
				self.label_act_time:setString(localizable.ui_monopoly_end)
				GetMainMenu():ShowTextTip(localizable.ui_monopoly_not_start,-1)
			end
		end)
	--]]
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

function startRequestInfo(self)
	--检查元宝
	if self.playerData_.m_gold < self.m_gold_one_search then
		--重置标志
		self.bSearchOver = true
		--提示购买元宝
		GetMainMenu():ShowTextTip(localizable.ui_lottry_gold_not_enough,-1)
		--通用付费引导
		local prePayLayer = createObj(ui_commonPrePay)
		GetMainMenu():GetModelLayer():AddDialog(prePayLayer.node_, 3)
		return nil
	end
	---[[
	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 2, "rl_w_sudoku")
	--cclog("rl_r_sudoku---cmd=2--%s", urlpath)

	GetMainMenu():ShowLoadingDlg()
	CCHttpRequest:open(urlpath, kHttpPost, "query=param1&other=params"):sendWithHandler(
		function(res, hnd)
			GetMainMenu():CloseLoadding();
			local resData = res:getResponseData()
			local code = res:getResponseCode()
			local xfile = xml.parse(resData)
			local item = xfile:find("RENLONG")
			if item == nil then
				--cclog("CGI : rl_r_sudoku cmd = 2 is down!")
				return nil
			end
			local retcode = item.code
			if retcode == "0" then		
				--扣除元宝
				self.playerMgr_:AddGold(-self.m_gold_one_search)
				self.playerData_ = self.playerMgr_:GetPlayerInfoData()	
				--player info
				self.label_gold:setString(self.playerData_.m_gold)
				self.label_silver:setString(self.playerData_.m_silver)
				--info		
				local itemInfo = item:find("basic")
				--探索的格子位置
				self.m_rewardIdx = tonumber(itemInfo:find("cell_index")[1]) + 1
				--探索一次元宝消耗
				self.m_gold_one_search = tonumber(item:find("lottery_cash")[1])
				--探宝全部
				self.m_gold_buy_all = tonumber(item:find("total_cash")[1])
				--cost info
			 	self.label_gold_find:setString(self.m_gold_one_search)
				--奖励信息
				self.m_awardXml = {}
				self.m_awardXml = item:find("award")
				--随机序列
				self:getRandCellList()
			else
				GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
				--重置标志
				self.bSearchOver = true
			end
		end)
	--]]
end

function init_binding_event(self)
	if self.proxy_ ~= nil then
		--刷新秘宝
		local function onBtnRefreshTreasure(btn)
			if 0 == self.m_act_state then
				GetMainMenu():ShowTextTip(localizable.ui_monopoly_end, -1)
				return  nil
			end
			--探寻未结束不能刷新
			if not self.bSearchOver then
				GetMainMenu():ShowTextTip(localizable.ui_ninjaTreasure_refresh_error, -1)
				return nil
			end
			--检查元宝
			if self.playerData_.m_gold < self.m_gold_one_refresh then
				--提示购买元宝
				GetMainMenu():ShowTextTip(localizable.ui_lottry_gold_not_enough,-1)
				--通用付费引导
				local prePayLayer = createObj(ui_commonPrePay)
				GetMainMenu():GetModelLayer():AddDialog(prePayLayer.node_, 3)
				return nil
			else
				self:startRequestRefreshInfo(true)	
			end				
		end
		--全部获取
		local function onBtnGetAll(btn)
			--litao_限制刷小号_等级限制_2014.6.24
			local _playerData_ = CPlayerDataMgr:instance():GetPlayerInfoData()
			--get info from table_bin
			local config_info_level = DataMgr.GetDataByID("Struct_Functionconfig", 18)
			--判断等级
			if nil ~= config_info_level then 
			    if _playerData_.m_level < tonumber(config_info_level.m_needlevel) then
					GetMainMenu():ShowTextTip(tostring(config_info_level.m_tipinfo), -1)
					return nil
				end
			end
			if 0 == self.m_act_state then
				GetMainMenu():ShowTextTip(localizable.ui_monopoly_end, -1)
				return  nil
			end
			--检查元宝
			if self.playerData_.m_gold < self.m_gold_buy_all then
				--提示购买元宝
				GetMainMenu():ShowTextTip(localizable.ui_lottry_gold_not_enough,-1)
				--通用付费引导
				local prePayLayer = createObj(ui_commonPrePay)
				GetMainMenu():GetModelLayer():AddDialog(prePayLayer.node_, 3)
				return nil
			end
			local function startRequestBuyAll()
				---[[
				local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 3, "rl_w_sudoku")
				cclog("rl_r_sudoku---cmd = 3--%s", urlpath)

				GetMainMenu():ShowLoadingDlg()
				CCHttpRequest:open(urlpath, kHttpPost, "query=param1&other=params"):sendWithHandler(
					function(res, hnd)
						GetMainMenu():CloseLoadding();
						local resData = res:getResponseData()
						local code = res:getResponseCode()
						local xfile = xml.parse(resData)
						local item = xfile:find("RENLONG")
						if item == nil then
							cclog("CGI : rl_r_sudoku cmd = 3 is down!")
							return nil
						end
						local retcode = item.code
						if retcode == "0" then
							--扣除元宝
							self.playerMgr_:AddGold(-self.m_gold_buy_all)
							self.playerData_ = self.playerMgr_:GetPlayerInfoData()
							--player info
							self.label_gold:setString(self.playerData_.m_gold)
							self.label_silver:setString(self.playerData_.m_silver)
							--奖励信息										
							self.m_awardXml = {}
							self.m_awardXml = item:find("award")
							--只加入背包不显示掉落动画		
							AddSoulAwardData(self.m_awardXml)
							--获取award中信息
							local _awardDatas = {}	
							local t_awardIconDatas = {}
							t_awardIconDatas = InitAwardIconData(self.m_awardXml)
							t_awardIconDatas.name = localizable.ui_ninjaTreasure_got_all_title
							table.insert(_awardDatas, t_awardIconDatas)

							if nil ~= _awardDatas then
								local view = createObj(ui_rewardDlgLayer, self, _awardDatas)
								local currentlayer = GetMainMenu():GetSubContentNode()
								local size1 = self.node_:getContentSize()
								view.node_:setAnchorPoint(ccp(0.5, 0.5))
								view.node_:setPosition(ccp(size1.width / 2, size1.height / 2))
								currentlayer:addChild(view.node_, 3)
							end
							--全部获取成功提示
							GetMainMenu():ShowTextTip(localizable.ui_ninjaTreasure_got_all_succeed, -1)
							--重新刷新秘宝
							self:startRequestRefreshInfo(false)
						else
							GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
						end
					end)
				--]]
			end

			--标准框
			local dlg = CommonDialogView.create()
			CommonDialogView.m_selfview = dlg
			dlg:SetTitle(localizable.ui_ninjaTreasure_got_all_title)
			local showContent = string.format(localizable.ui_ninjaTreasure_got_all_tip, tostring(self.m_gold_buy_all))
			dlg:SetDescription(showContent)
			dlg:loadCCBI()
			dlg:initUI()
			dlg:SetConfirmHandler(startRequestBuyAll)
			GetMainMenu():GetModelLayer():AddDialog(dlg, 3)				
		end

		local function onBtnStartFind(btn)
			--litao_限制刷小号_等级限制_2014.6.24
			local _playerData_ = CPlayerDataMgr:instance():GetPlayerInfoData()
			--get info from table_bin
			local config_info_level = DataMgr.GetDataByID("Struct_Functionconfig", 18)
			--判断等级
			if nil ~= config_info_level then 
			    if _playerData_.m_level < tonumber(config_info_level.m_needlevel) then
					GetMainMenu():ShowTextTip(tostring(config_info_level.m_tipinfo), -1)
					return nil
				end
			end
			if 0 == self.m_act_state then
				GetMainMenu():ShowTextTip(localizable.ui_monopoly_end, -1)
				return  nil
			end
			if not self.bSearchOver then
				return nil
			end
			--开始探宝标志
			self.bSearchOver = false
			--开始探宝
			self:startRequestInfo()
		end

		local function onBtnPreviewTop( btn )
			local topLayer = createObj(ui_ninjaTrasureTopViewLayer,self)
			local size = GetMainMenu():GetModelLayer():getContentSize()
			topLayer.node_:setAnchorPoint(ccp(0.5,0.5))
			topLayer.node_:setPosition(size.width/2,size.height/2)
			GetMainMenu():GetModelLayer():addChild(topLayer.node_)
		end

		local function onBtnBack(btn)
			GetMainMenu():ChangeToSub(E_DEFAULTMENU)
		end

		local function onBtnClickIcon(btn)
			CSoundMgr:instance():PlayEffect(SOUND_BUTTON)
			local btnIndex = btn:getTag()

			if btnIndex > 0 and btnIndex <= 9 then
				local _id_icon = tonumber(self.m_itemlist[btnIndex].id)
				if nil ~= _id_icon then
					CGameObjElement:ShowDropByID(_id_icon)
				end
			end
		end

		--判断是否点击格子
		for i = 1, 9 do
			self.proxy_:handleButtonEvent(self["btn_icon" .. tostring(i)], function(button, event)
				onBtnClickIcon(button)
				return nil
			end, CCControlEventTouchUpInside)
		end

		--全部获得
		self.proxy_:handleButtonEvent(self.btn_get_all, function(button, event)
			onBtnGetAll(button)
			return nil
		end, CCControlEventTouchUpInside)

		--刷新秘宝
		self.proxy_:handleButtonEvent(self.btn_refresh, function(button, event)
			onBtnRefreshTreasure(button)
			return nil
		end, CCControlEventTouchUpInside)

		--开始探宝
		self.proxy_:handleButtonEvent(self.btn_start_find, function(button, event)
			onBtnStartFind(button)
			return nil
		end, CCControlEventTouchDown)

		self.proxy_:handleButtonEvent(self.btnPreviewTop, function(button, event)
			onBtnPreviewTop(button)
			return nil
		end, CCControlEventTouchDown)		

		--返回
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
				self.m_currentItemIndex = self.m_targetNumber
			end
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
	self.m_curNum = 1
	self:highlightTargetItem(self.m_randNumSeq[self.m_curNum])
	self.m_curNum = self.m_curNum + 1	
	self:nextItem()
end

function doRollEnd(self)
	local size = self["sprite_hl_" .. tostring(self.m_rewardIdx)]:getContentSize()

	self.m_hlLayer = createObj(ui_rouletteBingo, size)
	self.m_hlLayer.node_:setAnchorPoint(ccp(0.5, 0.5))
	self.m_hlLayer.node_:setPosition(size.width / 2, size.height / 2)

	self["sprite_hl_" .. tostring(self.m_rewardIdx)]:addChild(self.m_hlLayer.node_)

	local function showBox()
		self:unhighlightAllItem()
		if self.m_hlLayer then
			self.m_hlLayer.node_:removeFromParentAndCleanup(true)
		end

		--展示、获取奖品
		ShowAward(self.m_awardXml)
		--灰化中奖格子
		self.m_itemlist[self.m_rewardIdx].bGot = true
		local _icon = self["node_icon_"..tostring(self.m_rewardIdx)]:getChildByTag(99)
		if _icon then
			local pProgram = CCShaderCache:sharedShaderCache():programForKey("greysprite")
			_icon:setShaderProgram(pProgram)
		end
		local pProgram_1 = CCShaderCache:sharedShaderCache():programForKey("greysprite")
		self["spr_icon_"..tostring(self.m_rewardIdx)]:setShaderProgram(pProgram_1)

		--更新元宝
		self.playerMgr_ = CPlayerDataMgr:instance()
		self.playerData_ = self.playerMgr_:GetPlayerInfoData()

		self.label_gold:setString(tostring(self.playerData_.m_gold))
		self.label_silver:setString(tostring(self.playerData_.m_silver))
		--Roll完一次以后，更新标志
		self.bSearchOver = true
		--更新格子标志
		self["spr_got_item_"..tostring(self.m_rewardIdx)]:setVisible(true)
		--如果最后格子则重新刷新
		if 1 == #self.m_randNumSeq then
			self:startRequestRefreshInfo(false)
		end 
	end
	local ccArray = CCArray:create()
	ccArray:addObject(CCDelayTime:create(2))
    ccArray:addObject(CCCallFuncN:create(showBox))
    local sequen = CCSequence:create(ccArray)
	self.node_:runAction(sequen)
end

function nextItem(self)
	--i表示前进时间
	local i = 0.15
	if self.m_curNum > #self.m_randNumSeq - 4 then
		i = i + 0.15 * (4 + self.m_curNum - #self.m_randNumSeq)
		cclog("%s", i)
	end

	local function doRollAction1()
		if self.m_curNum >= #self.m_randNumSeq then
			self:highlightTargetItem(self.m_randNumSeq[#self.m_randNumSeq])
			self:doRollEnd()
		else
			self:highlightTargetItem(self.m_randNumSeq[self.m_curNum])
			self.m_curNum = self.m_curNum + 1
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
	for i=1,9 do
		local itemNode = {}
		itemNode.name = "一乐拉面(小)*2"
		itemNode.icon = "props_016"
		itemNode.id = 481
		itemNode.bGot = false
		self.m_itemlist[i] = itemNode
	end

	for i = 1, 9 do
		self["spr_icon_" .. tostring(i)] = tolua.cast(self.proxy_:getNode("spr_icon_" .. tostring(i)), "CCSprite")
		self["sprite_hl_" .. tostring(i)] = tolua.cast(self.proxy_:getNode("sprite_hl_" .. tostring(i)), "CCSprite")
		CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile("props/" .. self.m_itemlist[i].icon .. ".plist")
		local pFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(self.m_itemlist[i].icon)
		if pFrame ~= nil then
			local pIcon = CCSprite:createWithSpriteFrame(pFrame);
			local size = self["spr_icon_" .. tostring(i)]:getContentSize()
			if pIcon ~= nil then
				pIcon:setTag(99)
				self["node_icon_" .. tostring(i)]:addChild(pIcon)
				pIcon:setPosition(ccp(size.width/2, size.height/2))
				pIcon:setAnchorPoint(ccp(0.5, 0.5))
			end
		end
	end

	self:init_ui_ext()
end