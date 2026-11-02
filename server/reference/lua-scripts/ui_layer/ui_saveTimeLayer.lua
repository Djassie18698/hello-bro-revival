--descriptioin:拉面换经验
--company: xckoo
--litao
--2014.6.20
---------------------------------------------
require("CommonBuyItemDialog.lua")

module("ui_saveTimeLayer", package.seeall)
baseClass(layer_base_t, ui_saveTimeLayer)

function init(self, node, cur_index)
	self.contentSize_ = GetMainMenu():GetModelLayer():getContentSize()

	local ccbiAttrTable = {name="activity/SaveTimeView.ccbi", size=self.contentSize_}
	layer_base_t.init(self, true, ccbiAttrTable)

	--vip
	self.m_vipframes={'vip_015','vip_003','vip_004','vip_005','vip_006','vip_007','vip_008','vip_009','vip_010','vip_011','vip_012','vip_013','vip_014','vip_s_13','vip_s_14','vip_s_15','vip_s_16','vip_s_17','vip_s_18'}

	--用户info
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	--pre info
	self.preNode = node

	--tableView cell container
	self.cellNodes = {}
	self.awardcellNodes = {}
	--data
	self.m_taskDatas = {}
	--
	self.m_awardDatas = {}
	--touch
	self.m_touchPoint = nil
	--
	self.cur_award_box = 1

	--create data
	--self:createData()

	--init
	self:init_ui()		
	self:init_binding_event()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		--label
		self.label_cur_chapter = tolua.cast(self.proxy_:getNode("label_cur_chapter"), "CCLabelTTF")
		self.label_exp = tolua.cast(self.proxy_:getNode("label_exp"), "CCLabelBMFont")
		self.label_silver = tolua.cast(self.proxy_:getNode("label_silver"), "CCLabelBMFont")
		self.label_cost = tolua.cast(self.proxy_:getNode("label_cost"), "CCLabelTTF")
		self.label_tip = tolua.cast(self.proxy_:getNode("label_tip"), "CCLabelTTF")
		self.label_ramen_num = tolua.cast(self.proxy_:getNode("label_ramen_num"), "CCLabelBMFont")
		self.label_exchange_num = tolua.cast(self.proxy_:getNode("label_exchange_num"), "CCLabelBMFont")
		self.label_add_desc = tolua.cast(self.proxy_:getNode("label_add_desc"), "CCLabelTTF")
		self.label_max_vip = tolua.cast(self.proxy_:getNode("label_max_vip"), "CCLabelTTF")
		--btn
		self.btn_close_dlg = tolua.cast(self.proxy_:getNode("closeButton"), "CCControlButton")
		self.btn_buy = tolua.cast(self.proxy_:getNode("btn_buy"), "CCControlButton") 
		self.btn_exchange = tolua.cast(self.proxy_:getNode("btn_exchange"), "CCControlButton") 
		--spr
		self.spr_next_vip = tolua.cast(self.proxy_:getNode("spr_next_vip"), "CCSprite")
		--node
		self.node_anim = tolua.cast(self.proxy_:getNode("node_anim"), "CCNode")

		--get info
		self:getBaseInfoData()
	end
end

function getBaseInfoData(self)
	---[[
	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 1, "rl_r_savetime")
	--cclog("rl_r_savetime----%s", urlpath)

	GetMainMenu():ShowLoadingDlg()
	CCHttpRequest:open(urlpath, kHttpPost, "query=param1&other=params"):sendWithHandler(
		function(res, hnd)
			GetMainMenu():CloseLoadding();
			local resData = res:getResponseData()
			local code = res:getResponseCode()
			local xfile = xml.parse(resData)
			local item = xfile:find("RENLONG")
			if item == nil then
				return nil
			end
			local retcode = item.code
			--cclog("resData = %s", resData)
			if retcode == "0" then
				--基本信息
				local _base = item:find("basic")
				if _base then
					self.m_chapter = tonumber(_base:find("chapter")[1])
					self.m_round = tonumber(_base:find("round")[1])
					--拥有拉面数
					self.m_prop_num = tonumber(_base:find("prop_num")[1])
					--总转换次数
					self.m_total_trans = tonumber(_base:find("total_trans")[1])
					--已转换次数
					self.m_used_trans = tonumber(_base:find("used_trans")[1])
					self.left_trans_times = self.m_total_trans - self.m_used_trans
					--cost
					self.m_cost_cash = tonumber(_base:find("cost_cash")[1])
					self.m_vip_add = tonumber(_base:find("vip_add")[1])
					self.m_exp = tonumber(_base:find("exp")[1])
					self.m_coin = tonumber(_base:find("coin")[1])
					self.m_vip_limit = tonumber(_base:find("vip_limit")[1])
					self.m_level_limit = tonumber(_base:find("level_limit")[1])
				end

				self:init_ext_ui()
			else
				GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
			end
		end)	
end

function init_ext_ui(self)		
	self.label_cur_chapter:setString(string.format(localizable.ui_saveTime_chapter_desc, tostring(self.m_chapter), tostring(self.m_round)))
	self.label_exp:setString(self.m_exp)
	self.label_silver:setString(self.m_coin)
	self.label_ramen_num:setString(self.m_prop_num)
	self.label_exchange_num:setString(self.left_trans_times)
	self.label_cost:setString(self.m_cost_cash..localizable.ui_common_gold)
	self.label_tip:setString(string.format(localizable.ui_saveTime_tip, tostring(self.m_vip_limit), tostring(self.m_level_limit)))
	self.label_add_desc:setString(string.format(localizable.ui_saveTime_add_desc, tostring(self.m_vip_add)))
	--next vip
	local next_viplevel = self.playerMgr_:GetVipLevel() + 2
	if next_viplevel > #self.m_vipframes then
		next_viplevel = #self.m_vipframes
		self.label_max_vip:setVisible(true)
		self.label_add_desc:setVisible(false)
	else
		self.label_max_vip:setVisible(false)
		self.label_add_desc:setVisible(true)
	end
	local frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(self.m_vipframes[next_viplevel])
	if frame ~= nil then
		self.spr_next_vip:setDisplayFrame(frame)
	end
end

function getIntPart(self, x)
    if x <= 0 then
       return 0
    end

    if math.abs(math.ceil(x) - x) < 0.005 then
       x = math.ceil(x)
    else
       x = math.ceil(x) - 1
    end
    return x
end

function showExchangeInfoAnim(self)
	--播放动画
	---[[
	local pre_animLayer = self.node_anim:getChildByTag(100)
	if pre_animLayer then
		pre_animLayer:removeFromParentAndCleanup(true)
	end

	local data = {}
	data.exchange_ratio = self.m_exchange_ratio
	data.exchange_exp = self.m_exchange_exp
	data.exchange_coin = self.m_exchange_coin

	local _iconSize = self.node_anim:getContentSize()
	self.m_animLayer = createObj(ui_saveTimeAnim, _iconSize, data)

	self.node_anim:addChild(self.m_animLayer.node_)

	self.m_animLayer.node_:setPosition(ccp(_iconSize.width * 0.5, _iconSize.height * 0.8))
	self.m_animLayer.node_:setAnchorPoint(ccp(0.5, 0.5))
	self.m_animLayer.node_:setTag(100)
	--]]
end

function updateInfo(self)
	--拉面数量
	self.m_prop_num = self.m_prop_num - 1
	self.label_ramen_num:setString(self.m_prop_num)
	CTradeMgr:instance():SetConsumItemCountByID(BIG_ENERGY_ITEM_ID, self.m_prop_num)
	--剩余转换次数
	self.left_trans_times = self.left_trans_times - 1
	self.label_exchange_num:setString(self.left_trans_times)
	CTradeMgr:instance():SetRemenLimitRest(self.m_left_remain_times)
end

function init_binding_event(self)
	if self.proxy_ ~= nil then
		--屏蔽掉后层触摸事件
		local function CCLayerTouch(event, x, y)
			if event == "began" then
				 return true
			end
		end

		local function onBtnBuy(btn, event)
			--购买拉面
			ShowCommonBuyItemDialog(kConsumableTypeItem, SMALL_ENERGY_ITEM_ID, BIG_ENERGY_ITEM_ID, 0)
			self.node_:removeFromParentAndCleanup(true)
		end

		local function onBtnExchange(btn, event)
			--等级不够
			local cur_vip_lv = self.playerMgr_:GetVipLevel()
			if self.playerData_.m_level < self.m_level_limit or cur_vip_lv < self.m_vip_limit then
				GetMainMenu():ShowTextTip(string.format(localizable.ui_saveTime_tip, self.m_vip_limit, self.m_level_limit), -1)
				return nil
			end
			--转换拉面
			self.m_cur_ramen_count = CTradeMgr:instance():GetConsumItemCountByID(BIG_ENERGY_ITEM_ID)
			--拉面不足
			if self.m_cur_ramen_count <= 0 then
				GetMainMenu():ShowTextTip(localizable.ui_saveTime_ramen_not_enough, -1)
				--购买拉面
				ShowCommonBuyItemDialog(kConsumableTypeItem, SMALL_ENERGY_ITEM_ID, BIG_ENERGY_ITEM_ID, 0)
				self.node_:removeFromParentAndCleanup(true)
				return nil
			end

			---[[
			local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 2, "rl_r_savetime")
			--cclog("rl_r_savetime--cmd = 2--%s", urlpath)

			GetMainMenu():ShowLoadingDlg()
			CCHttpRequest:open(urlpath, kHttpPost, "query=param1&other=params"):sendWithHandler(
				function(res, hnd)
					GetMainMenu():CloseLoadding();
					local resData = res:getResponseData()
					local code = res:getResponseCode()
					local xfile = xml.parse(resData)
					local item = xfile:find("RENLONG")
					if item == nil then
						return nil
					end
					local retcode = item.code
					--cclog("resData = %s", resData)
					if retcode == "0" then
						--基本信息
						local _base = item:find("basic")
						if nil ~= _base then
							self.m_exchange_ratio = tonumber(_base:find("ratio")[1])
							self.m_exchange_exp = tonumber(_base:find("exp")[1])
							self.m_exchange_coin = tonumber(_base:find("coin")[1])
							self.m_left_remain_times = tonumber(_base:find("remain")[1])
							--add exp & silver
							local playerMgr = CPlayerDataMgr:instance()
							playerMgr:AddSilver(self.m_exchange_coin)
							playerMgr:AddExp(self.m_exchange_exp)
							GetMainMenu():GetCurrentSubMenu():InitNormalHeader()
							--更新拉面数量
							self:updateInfo()
							--动画
							self:showExchangeInfoAnim()
						end			
					else
						GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
					end
				end)		
		end

		local function onBtnClose(btn, event)
			self.node_:removeFromParentAndCleanup(true)
		end

		self.node_:setTouchEnabled(true)
		self.node_:registerScriptTouchHandler(CCLayerTouch, false, kCCMenuHandlerPriority-1, true)
		--购买拉面
		self.btn_buy:setTouchPriority(kCCMenuHandlerPriority-1)
		self.btn_buy:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btn_buy, function(button, event)
			onBtnBuy(button)
			return nil
		end, CCControlEventTouchDown)
		--转换
		self.btn_exchange:setTouchPriority(kCCMenuHandlerPriority-1)
		self.btn_exchange:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btn_exchange, function(button, event)
			onBtnExchange(button)
			return nil
		end, CCControlEventTouchDown)

		self.btn_close_dlg:setTouchPriority(kCCMenuHandlerPriority-1)
		self.btn_close_dlg:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btn_close_dlg, function(button, event)
			onBtnClose(button)
			return nil
		end, CCControlEventTouchDown)
	end
end

function onNodeCleanup(self)
	if self.proxy_ then
    	self.proxy_:release()
    end

    layer_base_t.onNodeCleanup(self)
end

--创建测试数据
function createData(self)
	---[[
	--]]
end