--descriptioin:极限训练
--company: xckoo
--author: litao
--date: 2014-07-17
---------------------------------------------
module("ui_limitTrainSoulLayer", package.seeall)
baseClass(layer_base_t, ui_limitTrainSoulLayer)

function init(self)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	self.contentSize_ = GetMainMenu():GetSubContentNode():getContentSize()
	local ccbiAttrTable = {name="sub_ui/LimitTrainSoulView.ccbi", size=self.contentSize_}
	layer_base_t.init(self, true, ccbiAttrTable)

	--pre
	self.preNode = node

    --data
    self.m_readme_datas = {}
    self.m_ninjaList = {}
    self.m_inherit_ninjaList = {}
    --
    self.isGetting = false
    self.isTraining = false

    --init
	self:init_ui()
	self:init_binding_event()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		--node
		self.node_anim_container = tolua.cast(self.proxy_:getNode("node_anim_container"), "CCNode")
		self.node_pre_train = tolua.cast(self.proxy_:getNode("node_pre_train"), "CCNode")
		self.node_after_train = tolua.cast(self.proxy_:getNode("node_after_train"), "CCNode")

		--btn
		self.btn_back = tolua.cast(self.proxy_:getNode("btn_back"), "CCControlButton")
		self.btn_get = tolua.cast(self.proxy_:getNode("btn_get"), "CCControlButton")
		self.btn_special_muti = tolua.cast(self.proxy_:getNode("btn_gold_muti"), "CCControlButton")
		self.btn_normal_muti = tolua.cast(self.proxy_:getNode("btn_silver_muti"), "CCControlButton")

		self.btn_train_normal = tolua.cast(self.proxy_:getNode("btn_train_normal"), "CCControlButton")
		self.btn_train_special = tolua.cast(self.proxy_:getNode("btn_train_special"), "CCControlButton")

		--label
		self.label_gold = tolua.cast(self.proxy_:getNode("label_gold"), "CCLabelBMFont")
		self.label_silver = tolua.cast(self.proxy_:getNode("label_silver"), "CCLabelBMFont")

		self.label_cur_soul = tolua.cast(self.proxy_:getNode("label_cur_soul"), "CCLabelTTF") -- 现有魂
		self.label_train_soul = tolua.cast(self.proxy_:getNode("label_train_soul"), "CCLabelTTF") -- 翻倍界面 x 倍数的
		
		self.label_train_soul_all = tolua.cast(self.proxy_:getNode("label_train_soul_all"), "CCLabelTTF")-- 翻倍后总数[翻倍界面]

		self.label_multiple = tolua.cast(self.proxy_:getNode("label_multiple"), "CCLabelTTF")

		-- 训练花费
		self.label_normal_cost_silver = tolua.cast(self.proxy_:getNode("label_silver_normal"), "CCLabelBMFont") 
		self.label_special_cost_gold = tolua.cast(self.proxy_:getNode("label_gold_special"), "CCLabelBMFont")

		-- 翻倍花费
		self.label_normalMultiCost = tolua.cast(self.proxy_:getNode("label_cost_silver"), "CCLabelTTF")
		self.label_specialMultiCost = tolua.cast(self.proxy_:getNode("label_cost_gold"), "CCLabelTTF")

		-- 训练次数
		self.label_normal_times = tolua.cast(self.proxy_:getNode("label_cost_desc_normal"),"CCLabelTTF")
		self.label_special_times = tolua.cast(self.proxy_:getNode("label_cost_desc_special"),"CCLabelTTF")
		self.label_vip_add = tolua.cast(self.proxy_:getNode("label_vip_add"), "CCLabelTTF")

		-- 免费高级翻倍次数
		self.labelFreeMutiTimes = tolua.cast(self.proxy_:getNode("label_free_muti_times"), "CCLabelTTF")

		-- 训练所得  
		self.label_can_get_soul_normal = tolua.cast(self.proxy_:getNode("label_can_get_soul_normal"), "CCLabelTTF")
		self.label_can_get_soul_special = tolua.cast(self.proxy_:getNode("label_can_get_soul_special"), "CCLabelTTF")

		-- sprite
		self.sprVipLv = tolua.cast(self.proxy_:getNode("spr_vip_lv"),"CCSprite")
		self.sprGoldIcon = tolua.cast(self.proxy_:getNode("spr_gold_icon"),"CCSprite") -- 翻倍界面高级翻倍的金币图标

		--init
		--self:initLayerInfo()
		--base request
		self:requestBaseLayerInfo()
	end
end

function requestBaseLayerInfo(self)
	--获取基本信息
	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 3, "rl_w_eight_gate")
	urlpath = AddData(urlpath, "version", 2)
	--cclog("rl_w_eight_gate & cmd = 3---%s", urlpath)
	GetMainMenu():ShowLoadingDlg()
	CCHttpRequest:open(urlpath, kHttpPost, "query=param1&other=params"):sendWithHandler(
		function(res, hnd)
			GetMainMenu():CloseLoadding()
			local resData = res:getResponseData()
			local code = res:getResponseCode()
			local xfile = xml.parse(resData)
			local item = xfile:find("RENLONG")
			if item == nil then
				return nil
			end
			--cclog("%s", resData)
			local retcode = item.code
			if retcode == "0" then
				local _basic = item:find("basic")
				if _basic then
					-- 自己当前的魂
					self.cur_soul = tonumber(_basic:find("soul")[1])

					-- 一次训练能得到的魂（不计翻倍）
					self.trainSoul = {normal = tonumber(_basic:find("soul_train")[1]), special = tonumber(_basic:find("soul_train_ad")[1])} 
					
					-- 训练花费
					self.trainPrice = {normal = tonumber(_basic:find("cost_coin")[1]), special = tonumber(_basic:find("cost_cash")[1])}

					--次数
					self.timesNormal = {cur = tonumber(_basic:find("left_count")[1]), total = tonumber(_basic:find("allow_count")[1]) }
					self.timesSpecial = {cur = tonumber(_basic:find("left_count_ad")[1]), total = tonumber(_basic:find("allow_count_ad")[1])}

					-- 下等级vip 增加的次数
					self.vipadd = tonumber(_basic:find("vip_count_add")[1])

					--翻倍需要花费的元宝
					self.multiPrice = {normal = tonumber(_basic:find("multiple_cash")[1]), special = tonumber(_basic:find("multiple_cash_ad")[1])}

					-- 未收集的魂和倍数
					self.soul_muti = tonumber(_basic:find("multiple_time")[1])
					local uncollect = tonumber(_basic:find("uncollect_soul")[1])
					self.soul_train = uncollect/self.soul_muti

					-- 今日剩余免费高级翻倍次数
					self.freeMutiTimes = {cur = tonumber(_basic:find("free_left_count")[1]), total = tonumber(_basic:find("free_total_count")[1])}
				end

				self:init_ext_ui()
			else
				GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
			end
		end)
end

function updateVipLv( self )
	local vipFrames = {"vip_015","vip_003","vip_004","vip_005","vip_006",
		"vip_007","vip_008","vip_009","vip_010","vip_011","vip_012","vip_013",
		"vip_014","vip_s_13","vip_s_14","vip_s_15","vip_s_16","vip_s_17","vip_s_18"}

	local viplv = self.playerMgr_:GetPlayerInfoData().m_viplevel
	local frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(vipFrames[viplv+1])
	self.sprVipLv:setDisplayFrame(frame)

	addtxt = string.format(localizable.ui_limitTrainSoul_vipadd,self.vipadd)
	self.label_vip_add:setString(addtxt)

end

function updateFreeMutiTimes( self )
	if self.freeMutiTimes.cur > 0 then -- 有免费翻倍次数
		self.labelFreeMutiTimes:setVisible(true)
		self.label_specialMultiCost:setVisible(false)
		self.sprGoldIcon:setVisible(false)
		local txt = string.format(localizable.ui_limitTrainSoul_freeMutiTimes,self.freeMutiTimes.cur,self.freeMutiTimes.total)
		self.labelFreeMutiTimes:setString(txt)
	else
		self.labelFreeMutiTimes:setVisible(false)
		self.label_specialMultiCost:setVisible(true)
		self.sprGoldIcon:setVisible(true)
	end
end
function init_ext_ui(self)
	--显示基本信息
	self.label_gold:setString(tostring(self.playerData_.m_gold))
	self.label_silver:setString(tostring(self.playerData_.m_silver))
	
	self.label_cur_soul:setString(tostring(self.cur_soul))

	self.label_train_soul:setString(self.soul_train)
	local ptx,pty = self.label_train_soul:getPosition()
	local descSize = self.label_train_soul:getContentSize()
	self.label_multiple:setString("x"..tostring(self.soul_muti))
	if ptx ~= nil and pty ~= nil and descSize ~= nil then
		--self.label_multiple:setPosition(ccp(ptx + descSize + 2, pty))
	end

	self.label_normalMultiCost:setString(tostring(self.multiPrice.normal))
	self.label_specialMultiCost:setString(tostring(self.multiPrice.special))
	
	self:updateFreeMutiTimes()


	self.label_can_get_soul_normal:setString(tostring(self.trainSoul.normal))
	self.label_can_get_soul_special:setString(tostring(self.trainSoul.special))

	title = tostring(localizable.ui_limitTrainSoul_free_times)
	self.label_normal_times:setString(title .. self.timesNormal.cur .."/".. self.timesNormal.total)
	self.label_special_times:setString(title .. self.timesSpecial.cur .."/".. self.timesSpecial.total)

	self.label_normal_cost_silver:setString(tostring(self.trainPrice.normal))
	self.label_special_cost_gold:setString(tostring(self.trainPrice.special))

	if self.soul_train > 0 then
		self.node_pre_train:setVisible(false)
		self.node_after_train:setVisible(true)
		if self.soul_muti > 0 then
			self.label_multiple:setVisible(true)
		else
			self.label_multiple:setVisible(false)
		end
		self:updateMuti()
	else
		self.node_pre_train:setVisible(true)
		self.node_after_train:setVisible(false)
	end

	--更新总魂数
	self.label_train_soul_all:setString(tostring(self.soul_muti * self.soul_train))	
	--
	--self.label_normal_times:setColor(ccc3(255,0,0))
	self:updateVipLv()
end

function playGetAnim(self)
	--播放light动画
	---[[	
	local pre_animLayer = self.label_train_soul_all:getChildByTag(100)
	if pre_animLayer then
		pre_animLayer:removeFromParentAndCleanup(true)
	end

	local animNodeSize = self.label_train_soul_all:getContentSize()
	self.m_animLayer = createObj(ui_limitTrainAnim, animNodeSize, 3)

	self.label_train_soul_all:addChild(self.m_animLayer.node_)

	self.m_animLayer.node_:setPosition(ccp(animNodeSize.width * 0.5, animNodeSize.height * 0.5))
	self.m_animLayer.node_:setAnchorPoint(ccp(0.5, 0.5))
	self.m_animLayer.node_:setTag(100)
	--]]

	local function toDoUpdate()
		self:updateSoul()
		self.isGetting = false
	end

	local ccArray = CCArray:create()
    ccArray:addObject(CCDelayTime:create(2.0))
    ccArray:addObject(CCCallFuncN:create(toDoUpdate))
	local sequen = CCSequence:create(ccArray)  

    --播放动画
	self.label_train_soul_all:runAction(sequen)
end

function playTrainAnim(self)
	--播放动画
	---[[	
	local pre_animLayer = self.node_anim_container:getChildByTag(100)
	if pre_animLayer then
		pre_animLayer:removeFromParentAndCleanup(true)
	end

	local animNodeSize = self.node_anim_container:getContentSize()
	self.m_animLayer = createObj(ui_limitTrainAnim, animNodeSize, 4)
	self.node_anim_container:addChild(self.m_animLayer.node_)

	self.m_animLayer.node_:setPosition(ccp(-animNodeSize.width * 0.38, -animNodeSize.height * 0.8))
	self.m_animLayer.node_:setAnchorPoint(ccp(0.5, 0.5))
	self.m_animLayer.node_:setTag(100)
	--]]

	local function toUpdateUI()
		self:updateUI()
	end

	local ccArray = CCArray:create()
    ccArray:addObject(CCDelayTime:create(2.0))
    ccArray:addObject(CCCallFuncN:create(toUpdateUI))
	local sequen = CCSequence:create(ccArray)  

    --播放动画
	self.node_anim_container:runAction(sequen)
end

function updateUI(self)
	--更新UI
	if self.soul_train > 0 then
		self.node_pre_train:setVisible(false)
		self.node_after_train:setVisible(true)
		if self.soul_muti > 0 then
			self.label_multiple:setVisible(true)
		else
			self.label_multiple:setVisible(false)
		end
		self:updateMuti()

	else
		self.node_pre_train:setVisible(true)
		self.node_after_train:setVisible(false)
	end

	self.label_train_soul:setString(self.soul_train)


	title = tostring(localizable.ui_limitTrainSoul_free_times)
	self.label_normal_times:setString(title .. self.timesNormal.cur .."/".. self.timesNormal.total)
	self.label_special_times:setString(title .. self.timesSpecial.cur .."/".. self.timesSpecial.total)

	self.label_normal_cost_silver:setString(tostring(self.trainPrice.normal))
	self.label_special_cost_gold:setString(tostring(self.trainPrice.special))

	self.label_gold:setString(tostring(self.playerData_.m_gold))
	self.label_silver:setString(tostring(self.playerData_.m_silver))

	--训练后更新总魂数
	self.label_train_soul_all:setString(tostring(self.soul_muti * self.soul_train))	
	--
	self.isTraining = false
end

function updateSoul(self)
 	--收取魂
 	self.label_cur_soul:setString(tostring(self.cur_soul))
 	self.label_can_get_soul_normal:setString(tostring(self.trainSoul.normal))
 	self.label_can_get_soul_special:setString(tostring(self.trainSoul.special))
 	self.node_pre_train:setVisible(true)
	self.node_after_train:setVisible(false)
end 

function updateMuti(self)
 	--倍数
 	self.label_multiple:setString("x"..tostring(self.soul_muti))
 	if self.soul_muti > 0 then
		self.label_multiple:setVisible(true)
	else
		self.label_multiple:setVisible(false)
	end

	self.label_normalMultiCost:setString(tostring(self.multiPrice.normal))
	self.label_specialMultiCost:setString(tostring(self.multiPrice.special))

	self.label_gold:setString(tostring(self.playerData_.m_gold))
	self.label_silver:setString(tostring(self.playerData_.m_silver))

	--更新总魂数
	self.label_train_soul_all:setString(tostring(self.soul_muti * self.soul_train))	

	self:updateFreeMutiTimes()
end 

function init_binding_event(self)
	if self.proxy_ ~= nil then
		local function onBtnBack(btn, event)
			--返回八门遁甲
			GetMainMenu():ChangeToActivitySubMenu("ShowLimitTrainView")
			--self.node_:removeFromParentAndCleanup(true)
		end

		local function onBtnGetSoul(btn, event)
			--
			if self.isGetting == true then
				GetMainMenu():ShowTextTip(localizable.ui_limitTrainSoul_isDoing, -1)
				return nil
			end
			--收取训练所得的魂
			local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 6, "rl_w_eight_gate")
			urlpath = AddData(urlpath, "version", 2)
			--cclog("rl_w_eight_gate & cmd = 6---%s", urlpath)
			GetMainMenu():ShowLoadingDlg()
			CCHttpRequest:open(urlpath, kHttpPost, "query=param1&other=params"):sendWithHandler(
				function(res, hnd)
					GetMainMenu():CloseLoadding()
					local resData = res:getResponseData()
					local code = res:getResponseCode()
					local xfile = xml.parse(resData)
					local item = xfile:find("RENLONG")
					if item == nil then
						return nil
					end
					--cclog("%s", resData)
					local retcode = item.code
					if retcode == "0" then
						local _basic = item:find("basic")
						if _basic then
							--得到训练产生的魂
							self.cur_soul = tonumber(_basic:find("total_soul")[1])

							--每次收取以后 倍数清0
							self.soul_muti = 1
							self.soul_train = 0
						end
								
						self.isGetting = true							
						--update
						self:playGetAnim()
						--self:updateSoul()
					else
						self.isGetting = false
						GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
					end
				end)
		end

		-- 检查等级是否符合
		local function checkLevel( )
			local _playerData_ = CPlayerDataMgr:instance():GetPlayerInfoData()
			--get info from table_bin
			local config_info_level = DataMgr.GetDataByID("Struct_Functionconfig", 21)
			--判断等级
			if nil ~= config_info_level then 
			    if _playerData_.m_level < tonumber(config_info_level.m_needlevel) then
					GetMainMenu():ShowTextTip(tostring(config_info_level.m_tipinfo), -1)
					return false
				end
			end
			return true
		end

		local function onBtnTrainNormal( btn,event )
			if self.timesNormal.cur < 1 then
				GetMainMenu():ShowTextTip(localizable.ui_limitTrainSoul_notimes, -1)
				return nil
			end

			if checkLevel() == false then
				return nil
			end

			if self.isTraining == true then
				GetMainMenu():ShowTextTip(localizable.ui_limitTrainSoul_isDoing, -1)
				return nil
			end

			if self.playerData_.m_silver < self.trainPrice.normal then
				GetMainMenu():ShowTextTip(localizable.ui_attribute_silver_not_enough, -1)
				--购买银票
				ShowCommonBuyItemDialog(kConsumableTypeItem, SMALL_COIN_ITEM_ID, BIG_COIN_ITEM_ID, 0)
				return nil
			end

			--训练
			local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 4, "rl_w_eight_gate")
			urlpath = AddData(urlpath, "traintype", 1)
			urlpath = AddData(urlpath, "version", 2)
			--cclog("rl_w_eight_gate & cmd = 4---%s", urlpath)
			GetMainMenu():ShowLoadingDlg()
			CCHttpRequest:open(urlpath, kHttpPost, "query=param1&other=params"):sendWithHandler(
				function(res, hnd)
					GetMainMenu():CloseLoadding()
					local resData = res:getResponseData()
					local code = res:getResponseCode()
					local xfile = xml.parse(resData)
					local item = xfile:find("RENLONG")
					if item == nil then
						return nil
					end
					--cclog("%s", resData)
					local retcode = item.code
					if retcode == "0" then
						local _basic = item:find("basic")
						if _basic then
							--训练产生的魂
							self.soul_train = tonumber(_basic:find("soul_train")[1])

							self.timesNormal.cur = tonumber(_basic:find("left_count")[1])
							self.timesSpecial.cur = tonumber(_basic:find("left_count_ad")[1])

							self.multiPrice.normal = tonumber(_basic:find("need_cash")[1])
							self.multiPrice.special = tonumber(_basic:find("need_cash_ad")[1])
							self.freeMutiTimes = {cur = tonumber(_basic:find("free_left_count")[1]), total = tonumber(_basic:find("free_total_count")[1])}
						end

						--扣除元宝
						self.playerMgr_:AddSilver(-self.trainPrice.normal)
						self.playerData_ = self.playerMgr_:GetPlayerInfoData()
						self.label_gold:setString(tostring(self.playerData_.m_gold))
						self.label_silver:setString(tostring(self.playerData_.m_silver))
															
						--update_每次训练后倍数清0
						self.soul_muti = 1
						self.isTraining = true
						self:playTrainAnim()
					else
						self.isTraining = false
						GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
					end
				end)
		end

		local function onBtnTrainSpecial(btn, event)
			if self.timesSpecial.cur < 1 then
				GetMainMenu():ShowTextTip(localizable.ui_limitTrainSoul_notimes, -1)
				return nil
			end

			if checkLevel() == false then
				return nil
			end

			if self.isTraining == true then
				GetMainMenu():ShowTextTip(localizable.ui_limitTrainSoul_isDoing, -1)
				return nil
			end

			if self.playerData_.m_gold < self.trainPrice.special then
				--提示购买元宝
				GetMainMenu():ShowTextTip(localizable.ui_monopoly_gold_not_enough,-1)
				--通用付费引导
				local prePayLayer = createObj(ui_commonPrePay)
				GetMainMenu():GetModelLayer():AddDialog(prePayLayer.node_, 3)
				return nil
			end

			--训练
			local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 4, "rl_w_eight_gate")
			urlpath = AddData(urlpath, "traintype", 2)
			urlpath = AddData(urlpath, "version", 2)
			--cclog("rl_w_eight_gate & cmd = 4---%s", urlpath)
			GetMainMenu():ShowLoadingDlg()
			CCHttpRequest:open(urlpath, kHttpPost, "query=param1&other=params"):sendWithHandler(
				function(res, hnd)
					GetMainMenu():CloseLoadding()
					local resData = res:getResponseData()
					local code = res:getResponseCode()
					local xfile = xml.parse(resData)
					local item = xfile:find("RENLONG")
					if item == nil then
						return nil
					end
					--cclog("%s", resData)
					local retcode = item.code
					if retcode == "0" then
						local _basic = item:find("basic")
						if _basic then
							--训练产生的魂
							self.soul_train = tonumber(_basic:find("soul_train")[1])

							self.timesNormal.cur = tonumber(_basic:find("left_count")[1])
							self.timesSpecial.cur = tonumber(_basic:find("left_count_ad")[1])

							self.multiPrice.normal = tonumber(_basic:find("need_cash")[1])
							self.multiPrice.special = tonumber(_basic:find("need_cash_ad")[1])
							self.freeMutiTimes = {cur = tonumber(_basic:find("free_left_count")[1]), total = tonumber(_basic:find("free_total_count")[1])}
						end

						--扣除元宝
						self.playerMgr_:AddGold(-self.trainPrice.special)
						self.playerData_ = self.playerMgr_:GetPlayerInfoData()
						self.label_gold:setString(tostring(self.playerData_.m_gold))
						self.label_silver:setString(tostring(self.playerData_.m_silver))
															
						--update_每次训练后倍数清0
						self.soul_muti = 1
						self.isTraining = true
						self:playTrainAnim()
					else
						self.isTraining = false
						GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
					end
				end)
		end

		local function onBtnSpecialMuti(btn, event)
			--litao_等级限制_2014.7.22
			local _playerData_ = CPlayerDataMgr:instance():GetPlayerInfoData()
			--get info from table_bin
			local config_info_level = DataMgr.GetDataByID("Struct_Functionconfig", 21)
			--判断等级
			if nil ~= config_info_level then 
			    if _playerData_.m_level < tonumber(config_info_level.m_needlevel) then
					GetMainMenu():ShowTextTip(tostring(config_info_level.m_tipinfo), -1)
					return nil
				end
			end
			--
			if self.isGetting == true then
				GetMainMenu():ShowTextTip(localizable.ui_limitTrainSoul_isDoing, -1)
				return nil
			end
			--金币不足
			if self.playerData_.m_gold < self.multiPrice.special then
				--提示购买元宝
				GetMainMenu():ShowTextTip(localizable.ui_monopoly_gold_not_enough,-1)
				--通用付费引导
				local prePayLayer = createObj(ui_commonPrePay)
				GetMainMenu():GetModelLayer():AddDialog(prePayLayer.node_, 3)
				return nil
			end
			--金币翻倍
			local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 5, "rl_w_eight_gate")
			urlpath = AddData(urlpath, "multitype", 2)
			urlpath = AddData(urlpath, "version", 2)
			--cclog("rl_w_eight_gate & cmd = 5---%s", urlpath)
			GetMainMenu():ShowLoadingDlg()
			CCHttpRequest:open(urlpath, kHttpPost, "query=param1&other=params"):sendWithHandler(
				function(res, hnd)
					GetMainMenu():CloseLoadding()
					local resData = res:getResponseData()
					local code = res:getResponseCode()
					local xfile = xml.parse(resData)
					local item = xfile:find("RENLONG")
					if item == nil then
						return nil
					end
					--cclog("%s", resData)
					local retcode = item.code
					if retcode == "0" then
						local _basic = item:find("basic")
						if _basic then
							self.soul_muti = tonumber(_basic:find("multiple_times")[1])
							-- 剩余元宝
							local cash = tonumber(_basic:find("left_cash")[1])
							self.playerMgr_:SetGold(cash)

							self.multiPrice.normal = tonumber(_basic:find("need_cash")[1])
							self.multiPrice.special = tonumber(_basic:find("need_cash_ad")[1])

							self.freeMutiTimes = {cur = tonumber(_basic:find("free_left_count")[1]), total = tonumber(_basic:find("free_total_count")[1])}
						end
						
						self.playerData_ = self.playerMgr_:GetPlayerInfoData()
						self.label_gold:setString(tostring(self.playerData_.m_gold))
						self.label_silver:setString(tostring(self.playerData_.m_silver))
						--tip
						GetMainMenu():ShowTextTip(localizable.ui_limitTrainSoul_muti_ok, -1)
															
						--update
						self:updateMuti()
					else
						GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
					end
				end)							
		end

		local function onBtnNormalMuti(btn, event)
			--litao_等级限制_2014.7.22
			local _playerData_ = CPlayerDataMgr:instance():GetPlayerInfoData()
			--get info from table_bin
			local config_info_level = DataMgr.GetDataByID("Struct_Functionconfig", 21)
			--判断等级
			if nil ~= config_info_level then 
			    if _playerData_.m_level < tonumber(config_info_level.m_needlevel) then
					GetMainMenu():ShowTextTip(tostring(config_info_level.m_tipinfo), -1)
					return nil
				end
			end
			--
			if self.isGetting == true then
				GetMainMenu():ShowTextTip(localizable.ui_limitTrainSoul_isDoing, -1)
				return nil
			end

			--金币不足
			if self.playerData_.m_gold < self.multiPrice.normal then
				--提示购买元宝
				GetMainMenu():ShowTextTip(localizable.ui_monopoly_gold_not_enough,-1)
				--通用付费引导
				local prePayLayer = createObj(ui_commonPrePay)
				GetMainMenu():GetModelLayer():AddDialog(prePayLayer.node_, 3)
				return nil
			end

			--翻倍
			local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 5, "rl_w_eight_gate")
			urlpath = AddData(urlpath, "multitype", 1)
			urlpath = AddData(urlpath, "version", 2)
			--cclog("rl_w_eight_gate & cmd = 5--%s", urlpath)
			GetMainMenu():ShowLoadingDlg()
			CCHttpRequest:open(urlpath, kHttpPost, "query=param1&other=params"):sendWithHandler(
				function(res, hnd)
					GetMainMenu():CloseLoadding()
					local resData = res:getResponseData()
					local code = res:getResponseCode()
					local xfile = xml.parse(resData)
					local item = xfile:find("RENLONG")
					if item == nil then
						return nil
					end
					--cclog("%s", resData)
					local retcode = item.code
					if retcode == "0" then
						--先保存以前的倍数
						local pre_muti = self.soul_muti
						--basic
						local _basic = item:find("basic")
						if _basic then
							self.soul_muti = tonumber(_basic:find("multiple_times")[1])
							-- 剩余元宝
							local cash = tonumber(_basic:find("left_cash")[1])
							self.playerMgr_:SetGold(cash)

							self.multiPrice.normal = tonumber(_basic:find("need_cash")[1])
							self.multiPrice.special = tonumber(_basic:find("need_cash_ad")[1])

							self.cur_soul = tonumber(_basic:find("total_soul")[1])
							self.freeMutiTimes = {cur = tonumber(_basic:find("free_left_count")[1]), total = tonumber(_basic:find("free_total_count")[1])}
						end

						self.playerData_ = self.playerMgr_:GetPlayerInfoData()
						self.label_gold:setString(tostring(self.playerData_.m_gold))
						self.label_silver:setString(tostring(self.playerData_.m_silver))

						--tip
						if pre_muti == self.soul_muti or self.soul_muti == 1 then
							GetMainMenu():ShowTextTip(localizable.ui_limitTrainSoul_muti_failed, -1)
							self:playGetAnim() -- 已自动收取魂
						else
							GetMainMenu():ShowTextTip(localizable.ui_limitTrainSoul_muti_ok, -1)
						end
															
						--update
						self:updateMuti()
					else
						GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
					end
				end)
		end

		self.btn_back:setTouchPriority(kCCMenuHandlerPriority-1)
		self.btn_back:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btn_back, function(button, event)
			onBtnBack(button)
			return nil
		end, CCControlEventTouchDown)

		self.btn_get:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.btn_get:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btn_get, function(button, event)
			onBtnGetSoul(button)
			return nil
		end, CCControlEventTouchDown)

		self.btn_train_normal:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.btn_train_normal:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btn_train_normal, function(button, event)
			onBtnTrainNormal(button)
			return nil
		end, CCControlEventTouchDown)

		self.btn_train_special:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.btn_train_special:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btn_train_special, function(button, event)
			onBtnTrainSpecial(button)
			return nil
		end, CCControlEventTouchDown)


		self.btn_special_muti:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.btn_special_muti:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btn_special_muti, function(button, event)
			onBtnSpecialMuti(button)
			return nil
		end, CCControlEventTouchDown)

		self.btn_normal_muti:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.btn_normal_muti:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btn_normal_muti, function(button, event)
			onBtnNormalMuti(button)
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