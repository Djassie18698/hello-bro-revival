--descriptioin:首冲礼包界面
--company: xckoo
--author: chenchun
--date: 2013-12

---------------------------------------------
module("ui_purchaseLayer", package.seeall)
baseClass(layer_base_t, ui_purchaseLayer)

--IOS商品id
BuyYuanBao={}
BuyYuanBao[normal_apple_goods_prefix.."3"] = 45     --0.99
BuyYuanBao[normal_apple_goods_prefix.."4"] = 240    --4.99
BuyYuanBao[normal_apple_goods_prefix.."5"] = 490    --9.99
BuyYuanBao[normal_apple_goods_prefix.."6"] = 1050   --19.99
BuyYuanBao[normal_apple_goods_prefix.."7"] = 2700   --49.99
BuyYuanBao[normal_apple_goods_prefix.."8"] = 5500   --99.99

--index = 0
function init(self, otherData)   --otherData,用于关闭购买窗口后，更新相关界面信息
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	local winSize = CCDirector:sharedDirector():getWinSize()

	local ccbiAttrTable = {name="store/PurchaseListViewForLua.ccbi", size=winSize}
	layer_base_t.init(self, true, ccbiAttrTable)

	--frame data
	self.m_next_vipframes={'vip_015','vip_003','vip_004','vip_005','vip_006','vip_007','vip_008','vip_009','vip_010','vip_011','vip_012','vip_013','vip_014','vip_s_13','vip_s_14','vip_s_15','vip_s_16','vip_s_17','vip_s_18'}
	self.m_cur_vipframes={'vip_0','vip_1','vip_2','vip_3','vip_4','vip_5','vip_6','vip_7','vip_8','vip_9','vip_10','vip_11','vip_12','vip_13','vip_14','vip_15','vip_16','vip_17','vip_18'}
	--
	self.m_currexp = 0
	self.m_needexp = 0
	self.otherObj = otherData
	self.cellNodes = {}   --首充信息列表的单元格信息，元素为ui_purchaseTableCell 类型
	self:init_ui()
	self:init_binding_event()
end


function init_ui(self)
	if self.proxy_ ~= nil then
		for i = 1, 4 do
			self["label_award"..tostring(i)] =  tolua.cast(self.proxy_:getNode("label_award"..tostring(i)), "CCLabelTTF")
			self["sprite_award"..tostring(i)] =  tolua.cast(self.proxy_:getNode("sprite_award"..tostring(i)), "CCSprite")
		end

		for i = 2, 4 do
			self["ctrl_gift_"..tostring(i)] = tolua.cast(self.proxy_:getNode("ctrl_gift_"..tostring(i)), "CCControlButton")
		end
		
		self.btnGetAward2 = tolua.cast(self.proxy_:getNode("btn_getAward2"), "CCControlButton")

		for i = 1, 3 do
			self['spr_award' .. i] = tolua.cast(self.proxy_:getNode('spr_award' .. i), 'CCSprite')
			self['btn_award' .. i] = tolua.cast(self.proxy_:getNode('btn_award' .. i), "CCControlButton")
		end

		--由于图标分散在不同的文件夹，所以需要分开处理
		--第一个礼品
		self.label_award1:setString(localizable.ui_firstpurchase_label_award1)
		CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile("ccbResources/activity_02.plist")
		local sprite_icon = CCSprite:createWithSpriteFrameName("activity_03_04")
		local contentSize = self.sprite_award1:getContentSize()
		sprite_icon:setPosition(contentSize.width / 2, contentSize.height / 2)
		sprite_icon:setAnchorPoint(ccp(0.5, 0.5))
		self.sprite_award1:addChild(sprite_icon)

		--第二个礼品
		local pathName = "icon/icon_"..firstpurchase_config.data[1].first_recharge_icon1 ..".plist"
		CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile(pathName)
		self.label_award2:setString(firstpurchase_config.data[1].first_recharge_name1)
		sprite_icon = CCSprite:createWithSpriteFrameName("icon_" .. firstpurchase_config.data[1].first_recharge_icon1)
		sprite_icon:setPosition(contentSize.width / 2, contentSize.height / 2)
		sprite_icon:setAnchorPoint(ccp(0.5, 0.5))
		sprite_icon:setScale(0.9)
		self.sprite_award2:addChild(sprite_icon)

		--第三个礼品
		pathName = "equip/small_"..firstpurchase_config.data[1].first_recharge_icon2 ..".plist"
		CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile(pathName)
		self.label_award3:setString(firstpurchase_config.data[1].first_recharge_name2)
		sprite_icon = CCSprite:createWithSpriteFrameName("small_" .. firstpurchase_config.data[1].first_recharge_icon2)
		sprite_icon:setPosition(contentSize.width / 2, contentSize.height / 2)
		sprite_icon:setAnchorPoint(ccp(0.5, 0.5))
		self.sprite_award3:addChild(sprite_icon)

		--第四个礼品
		pathName = "skill/small_"..firstpurchase_config.data[1].first_recharge_icon3 ..".plist"
		CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile(pathName)
		self.label_award4:setString(firstpurchase_config.data[1].first_recharge_name3)
		sprite_icon = CCSprite:createWithSpriteFrameName("small_" .. firstpurchase_config.data[1].first_recharge_icon3)
		sprite_icon:setPosition(contentSize.width / 2, contentSize.height / 2)
		sprite_icon:setAnchorPoint(ccp(0.5, 0.5))
		self.sprite_award4:addChild(sprite_icon)

		self.ctrl_close = tolua.cast(self.proxy_:getNode("ctrl_close"), "CCControlButton")
		self.ctrl_getaward = tolua.cast(self.proxy_:getNode("ctrl_getaward"), "CCControlButton")
		self.node_gift_container_1 = tolua.cast(self.proxy_:getNode("node_gift_container_1"), "CCNode")
		self.node_gift_container_2 = tolua.cast(self.proxy_:getNode("node_gift_container_2"), "CCNode")
		self.node_touchsize = tolua.cast(self.proxy_:getNode("node_touchsize"), "CCNode")
		self.node_content = tolua.cast(self.proxy_:getNode("node_content"), "CCNode")
		self.node_cellsize = tolua.cast(self.proxy_:getNode("node_cellsize"), "CCNode")

		--init cur vip info
		self.spr_vip = tolua.cast(self.proxy_:getNode("sprite_viplevel"), "CCSprite")
		self.label_next_vip_desc = tolua.cast(self.proxy_:getNode("label_next_vipdesc"), "CCLabelTTF")
		self.spr_next_vip = tolua.cast(self.proxy_:getNode("sprite_next_viplevel"), "CCSprite")
		self.btn_vip_right = tolua.cast(self.proxy_:getNode("vip_right_btn"), "CCControlButton")
		self.label_cur_vip_exp = tolua.cast(self.proxy_:getNode("label_vipratio"), "CCLabelBMFont")
		self.cc9_spr_cur_vip_exp =  tolua.cast(self.proxy_:getNode("sprite_viplevelbar"), "CCScale9Sprite")
		--首冲3倍标识
		self.node_triple = tolua.cast(self.proxy_:getNode("node_triple"), "CCNode")
		
		self.labelProgress = tolua.cast(self.proxy_:getNode("label_progress"), "CCLabelBMFont")
		self.sprProgress = tolua.cast(self.proxy_:getNode("spr_progress"), "CCScale9Sprite")
		
		--代码整理_litao
		self:requestBaseInfo()
	end
end

function requestBaseInfo(self)
	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, protocol.CMD_PAYPACK, protocol.URL_R_PAYPACK)
	local p = 1
	CCHttpRequest:openWithUserData(urlpath, kHttpPost, p, "query=param1&other=params"):sendWithHandler(
		function(res, hnd)
			local resData = res:getResponseData()
			local code = res:getResponseCode()
			local xfile = xml.parse(resData)
			local item = xfile:find("RENLONG")
			local retcode = item.code
			if retcode == "0" then
				cclog("1111---URL_R_PAYPACK--%s", resData)
				--vip info
				self.max_vip_lv = tonumber(item:find("maxlv")[1])
				self.m_currexp = tonumber(item:find("exp")[1])
				self.m_needexp = tonumber(item:find("lvexp")[1])
				--首充礼包是否获取
				self.canget = tonumber(xfile:find("canget")[1])
				--首充标识litao_2014.6.24
				if nil ~= xfile:find("first_pay") then
					self.bFirstPay = tonumber(xfile:find("first_pay")[1])
				end
				if 0 == self.bFirstPay then
					self.node_triple:setVisible(true)
				else
					self.node_triple:setVisible(false)
				end
				--活动翻倍_litao
				if nil ~= xfile:find("multiple") then
					self.multiple = tonumber(xfile:find("multiple")[1])
				end
				--活动时间litao_现调整为永久,可忽略
				local servertime = (xfile:find("servertime"))
				local endtime = (xfile:find("endtime"))

				--ext init
				self:init_ext_info()
				--[[
				if endtime ~= nil and servertime ~= nil then
					if tonumber(endtime[1]) < tonumber(servertime[1]) then
						self.node_gift_container_1:removeFromParentAndCleanup(true)
						local parentNodeSize = self.node_gift_container_2:getParent():getContentSize()
						local x, y = self.node_gift_container_2:getPosition()
						self.node_gift_container_2:setPosition(parentNodeSize.width * 0.5, y)
						self.node_gift_container_2:setAnchorPoint(ccp(0.5, 0.5))
					end
				else
					self.node_gift_container_1:removeFromParentAndCleanup(true)
					local parentNodeSize = self.node_gift_container_2:getParent():getContentSize()
					local x, y = self.node_gift_container_2:getPosition()
					self.node_gift_container_2:setPosition(parentNodeSize.width * 0.5, y)
					self.node_gift_container_2:setAnchorPoint(ccp(0.5, 0.5))
				end
				--]]
			else

			end
		end)

	urlpath = GetUrlNormalHeader(self.playerData_.m_uid, protocol.CMD_GET_PURCHASE_LIST, protocol.URL_R_PUCHASE_LIST)
	GetMainMenu():ShowLoadingDlg()	-- 获取信息的时候，不允许操作
	CCHttpRequest:openWithUserData(urlpath, kHttpPost, p, "query=param1&other=params"):sendWithHandler(
		function(res, hnd)
			GetMainMenu():CloseLoadding() --获取信息完成时，解除禁止操作
			local resData = res:getResponseData()
			cclog("1111--URL_R_PUCHASE_LIST----resdata:%s", resData)
			local code = res:getResponseCode()
			local xfile = xml.parse(resData)
			local item = xfile:find("RENLONG")
			local retcode = item.code
			if retcode == "0" then
				self.rechargeTable ={}
				local indexForMM = 1
				local platform_ptid = CNetUser:instance():GetPlatformID()
				--litao_2014.7.23_节点解析方式修改					
				local _payact = item:find("payact")
				if _payact then
					self.mul = tonumber(_payact:find("mul")[1])
					self.bOpen=tonumber(_payact:find("bOpen")[1])
				end
				
				--安卓和appstore用的节点不一样
				local nodeName = 'rechargelist'
				if is_applestore == true then
					nodeName = "rechargeioslist"
				end

				local _rechargelist = item:find(nodeName)
				if _rechargelist then
					--判断pt是不是移动MM,虽然早已下架,但保留代码
					if mm_platform_ptid == platform_ptid then
						local tmpRmb = tonumber(_rechargelist[1]:find("recharge_rmb")[1]) / 100
						if tmpRmb <= 30 then
							for i=1,#_rechargelist do
								local _data = {}
								_data.id = tonumber(_rechargelist[i]:find("recharge_id")[1])
								_data.rmb = tonumber(_rechargelist[i]:find("recharge_rmb")[1])
								_data.yuanbao = tonumber(_rechargelist[i]:find("recharge_yuanbao")[1])
								_data.yuanbao_give = tonumber(_rechargelist[i]:find("recharge_yuanbao_give")[1])
								table.insert(self.rechargeTable, _data)
							end
						end
					else
						for i=1,#_rechargelist do
							local _data = {}
							_data.id = tonumber(_rechargelist[i]:find("recharge_id")[1])
							_data.rmb = tonumber(_rechargelist[i]:find("recharge_rmb")[1])
							_data.yuanbao = tonumber(_rechargelist[i]:find("recharge_yuanbao")[1])
							_data.yuanbao_give = tonumber(_rechargelist[i]:find("recharge_yuanbao_give")[1])
							table.insert(self.rechargeTable, _data)
						end
					end
				end
				--[[
				for k, v in pairs(item[1]) do
					local index = tonumber(k)
					if index ~= nil and index ~= 0 then
						if mm_platform_ptid == platform_ptid then
							local tmpRmb = tonumber(item[1][index][2][1]) / 100
							if tmpRmb <= 30 then
								self.rechargeTable[indexForMM] = {id=tonumber(item[1][index][1][1]), rmb=tonumber(item[1][index][2][1]), yuanbao=tonumber(item[1][index][3][1]), yuanbao_give=tonumber(item[1][index][4][1])}
								indexForMM = indexForMM + 1
							end
						else
							self.rechargeTable[index] = {id=tonumber(item[1][index][1][1]), rmb=tonumber(item[1][index][2][1]), yuanbao=tonumber(item[1][index][3][1]), yuanbao_give=tonumber(item[1][index][4][1])}
						end
					end
				end
				--]]
				self:initTableView()
			else
				--GetMainMenu():ShowErrorTip(retcode,-1)
			end
		end)
		
		self:requestAward()
end

function init_ext_info(self)
	--cur vip spr
	local viplevel = self.playerMgr_:GetVipLevel()
	local frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(self.m_cur_vipframes[viplevel+1])
	self.spr_vip:setDisplayFrame(frame)
	--exp
	if self.m_currexp < 0 or self.m_needexp <= 0 then
		self.cc9_spr_cur_vip_exp:setScaleX(0)
		self.label_cur_vip_exp:setString("0/0")
	else
		local expratio = self.m_currexp / self.m_needexp
		self.cc9_spr_cur_vip_exp:setScaleX(expratio)
		--
		local textexp = self.m_currexp..'/'..self.m_needexp
		self.label_cur_vip_exp:setString(textexp)
	end

	--next exp gold
	local need_gold = tonumber(self.m_needexp - self.m_currexp)
	--next vip
	local next_vip = viplevel + 2
	if next_vip > #self.m_next_vipframes then
		next_vip = #self.m_next_vipframes
		need_gold = 0
	end
	local next_frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(self.m_next_vipframes[next_vip])
	if next_frame ~= nil then
		self.spr_next_vip:setDisplayFrame(next_frame)
	end
	--need_gold
	local needgold_str = string.format(localizable.ui_purchase_buy_again, tostring(need_gold/10))
	self.label_next_vip_desc:setString(needgold_str)
end

function init_binding_event(self)
	local function CCLayerTouch(event)
		if event == "began" then
			return true
		end
	end
	self.node_:setTouchEnabled(true)
	self.node_:registerScriptTouchHandler(CCLayerTouch, false, kCCMenuHandlerPriority-1, true)

	--立即充值回调函数
	local function close_window(btn, event)
		self.node_:removeFromParentAndCleanup(true)
		if self.otherObj ~= nil and self.otherObj.refreshData~= nil then
			self.otherObj:refreshData()
		end
	end

	local function get_gift_now_callback(btn, event)
		local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, protocol.CMD_PAYPACK, protocol.URL_W_PAYPACK)
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
					local awardXML = xfile:find("award")
					ShowAward(awardXML);
				elseif retcode == "250010" then
					GetMainMenu():ShowTextTip(localizable.ui_firstmoneyaward_have_got, -1)
				elseif retcode == "250011" then
					GetMainMenu():ShowTextTip(localizable.ui_firstmoneyaward_cannot_got, -1)
				end
			end)
	end

	--vip right
	local function OnBtnVipRight(btn)
		CSoundMgr:instance():PlayEffect(SOUND_BUTTON)
		--vip right
		local data = {}
		data.cur_exp = tonumber(self.m_currexp)
		data.need_exp = tonumber(self.m_needexp)
		data.need_show = tonumber(self.max_vip_lv)
		local vip_right_layer = createObj(ui_vipRightInfoView, self, data)
		local _size = GetMainMenu():GetModelLayer():getContentSize()
		vip_right_layer.node_:setAnchorPoint(ccp(0.5, 0.5))
		vip_right_layer.node_:setPosition(ccp(_size.width * 0.5, _size.height * 0.5))
		GetMainMenu():GetModelLayer():addChild(vip_right_layer.node_, 9)
	end

	--点击首冲格子详情
	local function onBtnClickIcon(btn)
		--CSoundMgr:instance():PlayEffect(SOUND_BUTTON)
		--
		local btnIndex = btn:getTag()

		local _id_icon = nil
		if btnIndex == 2 then
			_id_icon = tonumber(firstpurchase_config.data[1].first_recharge_id1)
		elseif btnIndex == 3 then
			_id_icon = tonumber(firstpurchase_config.data[1].first_recharge_id2)
		elseif btnIndex == 4 then
			_id_icon = tonumber(firstpurchase_config.data[1].first_recharge_id3)
		end
		if nil ~= _id_icon then
			CGameObjElement:ShowDropByID(_id_icon)
		end
		
	end

	if self.proxy_ ~= nil then
		self.ctrl_close:setTouchPriority(kCCMenuHandlerPriority-1)
		self.ctrl_getaward:setTouchPriority(kCCMenuHandlerPriority-1)
		self.proxy_:handleControlEvent(self.ctrl_close, close_window, CCControlEventTouchUpInside)
		self.proxy_:handleControlEvent(self.ctrl_getaward, get_gift_now_callback, CCControlEventTouchUpInside)
		
		--vip特权信息
		self.btn_vip_right:setTouchPriority(kCCMenuHandlerPriority-1)
		self.btn_vip_right:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btn_vip_right, function(button, event)
			OnBtnVipRight(button)
			return nil
		end, CCControlEventTouchDown)

		--判断是否点击首冲格子
		for i = 2, 4 do
			self["ctrl_gift_"..tostring(i)]:setTouchPriority(kCCMenuHandlerPriority-1)
			self["ctrl_gift_"..tostring(i)]:setTouchEnabled(true)
			self.proxy_:handleButtonEvent(self["ctrl_gift_"..tostring(i)], function(button, event)
				onBtnClickIcon(button)
				return nil
			end, CCControlEventTouchDown)
		end
	end
	
	-- 判断是否点击首冲格子
	for i = 2, 4 do
		self["ctrl_gift_" .. tostring(i)]:setTouchPriority(kCCMenuHandlerPriority - 1)
		self["ctrl_gift_" .. tostring(i)]:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self["ctrl_gift_" .. tostring(i)], function(button, event)
			onBtnClickIcon(button)
			return nil
		end , CCControlEventTouchDown)
	end

	self.btnGetAward2:setTouchPriority(kCCMenuHandlerPriority - 1)
	self.proxy_:handleButtonEvent(self.btnGetAward2, function(btn, event)
		self:onClickedGetAward2()
	end , CCControlEventTouchDown)

	for i=1, 3 do
		self["btn_award" .. i]:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.proxy_:handleButtonEvent(self["btn_award" .. i], function(btn, event)
		local dropid = tonumber(self.awards['drop'..i])
		if dropid then
			CGameObjElement:ShowDropByID(dropid)
		end
		end , CCControlEventTouchDown)
	end

end

function onNodeCleanup(self)
    --cclog("onNodeCleanup")
    if self.proxy_ then
    	self.proxy_:release()
    end
    layer_base_t.onNodeCleanup(self)
end


--private function
function initTableView(self)
	-- body
	if self.tableview == nil then
		self.cellsize = self.node_cellsize:getContentSize()
		self.tableContentSize = self.node_content:getContentSize()
		self:initHandle()
		self.tableview = LuaTableView:createWithHandler(self.tableViewHandler, CCSizeMake(self.tableContentSize.width, self.tableContentSize.height))

		self.tableview:setDirection(kCCScrollViewDirectionVertical)
		self.tableview:setVerticalFillOrder(kCCTableViewFillTopDown)
		self.tableview:setTouchPriority(kCCMenuHandlerPriority-1)
		self.node_content:addChild(self.tableview)
		--local offset = self.tableview:getContentOffset()
		--self.tableview:reloadData()
		--self.tableview:setContentOffset(offset.x, offset.y)
		--self.tableview:setDragEnabled(true)
	end
end

function initHandle(self)

	local function refreshChargeUI()
		self.bFirstPay = 1
		self.node_triple:setVisible(false)
		self.tableview:reloadData()
		--刷新活动充值倍率状态
		self:requestBaseInfo()
	end

    self.requestBuyTimes = 0
	local function appleBuyCallBack(jsonStr, orderStrId, shopGoodIdStr)
        local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, protocol.CMD_PAYPACK, protocol.URL_W_APPLE_BUY)
		--cclog("1111---path:%s", urlpath)
		local postValue = string.format("{\"receipt-data\":\"%s\",\"password\":\"%s\"}", jsonStr, "your_secret_here")
		--local postValue = string.format("{\"receipt-data\":\"%s\",\"password\":\"%s\"}", localizable.APPLE_REC, "your_secret_here")
		urlpath = AddData(urlpath, "rc", postValue)
		GetMainMenu():ShowLoadingDlg()
		CCHttpRequest:open(urlpath, kHttpPost,"query=param1&other=params"):sendWithHandler(
		function(res, hnd)
			GetMainMenu():CloseLoadding()
			local resData = res:getResponseData()
            --cclog("1111----0002---%s\n", resData)
			local code = res:getResponseCode()
			local xfile = xml.parse(resData)
			local item = xfile:find("RENLONG")
			local retcode = item.code
			if retcode == "0" then
                local appleOrderId = item:find("orderid")[1]
                --cclog("1111----0003---%s\n", appleOrderId)
				local urlpath1 = GetUrlNormalHeader(self.playerData_.m_uid, protocol.CMD_KY_CHECKORDER, protocol.URL_R_KY_CHECKORDER)
				urlpath1 = AddData(urlpath1, "DealNo", appleOrderId)
				GetMainMenu():ShowLoadingDlg()
				CCHttpRequest:open(urlpath1, kHttpPost,"query=param1&other=params"):sendWithHandler(
				function(res, hnd)
					GetMainMenu():CloseLoadding()
					local resData = res:getResponseData()
					--cclog("1111----001--%s\n", resData)
					local code = res:getResponseCode()
					local xfile = xml.parse(resData)
					local item = xfile:find("RENLONG")
					local retcode = item.code
					if retcode == "0" then
						GetMainMenu():ShowTextTip(localizable.ui_buy_success_tips, -1)
                        self.playerMgr_:AddGold(ui_purchaseLayer.BuyYuanBao[shopGoodIdStr])
                        GetMainMenu():GetCurrentSubMenu():InitNormalHeader();
                        CallBackFinishTrans();
                        refreshChargeUI()
					else
						GetMainMenu():ShowTextTip(localizable.ui_buy_failed_tips, -1)
					end
				end)
			elseif retcode == "250013" or retcode == "250014" then
				GetMainMenu():ShowTextTip(localizable.ui_buy_order_tips, -1)
				CallBackFinishTrans();
			else
				self.requestBuyTimes = self.requestBuyTimes + 1
				if self.requestBuyTimes < 2 then
                    --cclog("1111---second:%s", tostring(self.requestBuyTimes))
					appleBuyCallBack(jsonStr, orderStrId, shopGoodIdStr)
				else
                    --cclog("1111---second2:%s", tostring(self.requestBuyTimes))
                    GetMainMenu():ShowTextTip(localizable.ui_buy_failed_tips, -1)
                end
			end
		end)
	end

	local function refreshChargeUI()
		self.bFirstPay = 1
		self.node_triple:setVisible(false)
		self.tableview:reloadData()
		--刷新活动充值倍率状态
		self:requestBaseInfo()
	end

	self.tableViewHandler = LuaEventHandler:create(function(fn, table, a1, a2, x, y)
		local r
		if fn == "cellSize" then
			-- Return cell size
			-- a1 is cell index (-1 means default size, in cocos2d-x version below 2.1.3, it's always -1)
			r = self.cellsize;
		elseif fn == "cellAtIndex" then
			-- Return CCTableViewCell, a1 is cell index (zero based), a2 is dequeued cell (maybe nil)
			-- Do something to create cell and change the content
    		local nodeLayer = createObj(ui_purchaseTableCell, self.cellsize, self.rechargeTable[a1 + 1],self.bOpen,self.mul,self.bFirstPay,self.multiple)
			if not a2 then
				a2 = CCTableViewCell:create()
				a2:addChild(nodeLayer.node_)
			else			
				a2:removeAllChildrenWithCleanup(true)
        		a2:addChild(nodeLayer.node_)
			end
			r = a2
		elseif fn == "numberOfCells" then
			r = #self.rechargeTable;
		-- Cell events:
		elseif fn == "cellTouched" then			-- A cell was touched, a1 is cell that be touched. This is not necessary.
			local cellIndex = a1:getIdx() + 1
		    local payid = CNetUser:instance():GetPayID()
		    --首冲3倍特殊处理:0未/1已经
		    local displayinfo = nil
		    if 0 == self.bFirstPay then
		    	displayinfo = tostring(self.rechargeTable[cellIndex].yuanbao * self.mul)
				--ShowTapjoy();
			else
				displayinfo = tostring(self.rechargeTable[cellIndex].yuanbao + self.rechargeTable[cellIndex].yuanbao_give)
			end
			--GetMainMenu():ShowTextTip(tostring(self.rechargeTable[cellIndex].rmb) .. displayinfo .. "元宝  " .. tostring(self.rechargeTable[cellIndex].id) , -1)
			if not is_applestore then
				--appleBuyCallBack()
				PayHelperForLua:goldPay(tostring(tonumber(self.rechargeTable[cellIndex].rmb) / 100), payid, displayinfo .. localizable.ui_border_gold, tostring(self.rechargeTable[cellIndex].id), "0", refreshChargeUI)
			else
                InAppPurchase(normal_apple_goods_prefix .. tostring(self.rechargeTable[cellIndex].id), appleBuyCallBack)
			end
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
	
	if is_applestore then
        --判断是否存在没有完成的订单
    	InAppInitInstance(appleBuyCallBack)
	end
end

function initAward2(self)
	for i = 1, 3 do
		local iconPath = "props/" .. self.awards['icon' .. i] .. '.plist'
		CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile(iconPath)
		local sprite_icon = CCSprite:createWithSpriteFrameName(self.awards['icon' .. i])
		local contentSize = self['spr_award' .. i]:getContentSize()
		sprite_icon:setPosition(contentSize.width / 2, contentSize.height / 2)
		sprite_icon:setAnchorPoint(ccp(0.5, 0.5))
		self['spr_award' .. i]:addChild(sprite_icon)
	end

	--进度
	if self.current < 0 or self.totalAmount <= 0 then
		self.sprProgress:setScaleX(0)
		self.labelProgress:setString("0/0")
	else
		local expratio = self.current / self.totalAmount
		self.sprProgress:setScaleX(expratio)
		--
		local textexp = self.current .. '/' .. self.totalAmount
		self.labelProgress:setString(textexp)
	end

	if self.awardStatus == 0 then
		setBtnTitle(self.btnGetAward2,'Claim')
	elseif self.awardStatus == 1 then
		setBtnTitle(self.btnGetAward2,'Received')
	elseif self.awardStatus == 2 then
		setBtnTitle(self.btnGetAward2,'Claim')
	end
end

function requestAward(self)
	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 16, "rl_r_comm")
	cclog("rl_r_comm & cmd = 16---%s", urlpath)
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
		cclog("rl_r_comm ret = %s", resData)
		local retcode = item.code
		if retcode == "0" then
			local basic = item:find('basic')
			self.awardStatus = tonumber(basic:find("status")[1])
			self.totalAmount = tonumber(basic:find('amount')[1])/100
			self.current = tonumber(basic:find('current')[1])/100

			self.awards = item:find(awards):find('item')

			self:initAward2()
		else
			GetMainMenu():ShowErrorTip(tonumber(retcode), -1)
		end
	end )
end

function onClickedGetAward2(self)
	if self.awardStatus == 0 then
		GetMainMenu():ShowTextTip(localizable.ui_firstPay_tip1, -1)
		return
	elseif self.awardStatus == 1 then
		GetMainMenu():ShowTextTip(localizable.ui_firstPay_tip2, -1)
		return
	end
	
	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 26, 'rl_w_comm')
	GetMainMenu():ShowLoadingDlg()
	CCHttpRequest:open(urlpath, kHttpPost, "query=param1&other=params"):sendWithHandler(
	function(res, hnd)
		GetMainMenu():CloseLoadding()
		local resData = res:getResponseData()
		local code = res:getResponseCode()
		local xfile = xml.parse(resData)
		local item = xfile:find("RENLONG")
		local retcode = tonumber(item.code)
		if retcode == 0 then
			local awardXML = xfile:find("award")
			ShowAward(awardXML)
			self.awardStatus = 1
			setBtnTitle(self.btnGetAward2,'Received')
		elseif retcode == 610001 then
			GetMainMenu():ShowTextTip(localizable.ui_firstPay_tip1, -1)
		elseif retcode == 610002 then
			GetMainMenu():ShowTextTip(localizable.ui_firstPay_tip2, -1)
		end
	end )
end