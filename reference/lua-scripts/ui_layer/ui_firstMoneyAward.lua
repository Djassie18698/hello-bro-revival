--首冲礼包界面
--chenchun
---------------------------------------------
module("ui_firstMoneyAward", package.seeall)
baseClass(layer_base_t, ui_firstMoneyAward)

function init(self)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	self.contentNode_ = GetActivityView():GetNodeContent()
	self.contentSize_ = self.contentNode_:getContentSize()
	local ccbiAttrTable = {name="activity/FirstMoneyAward.ccbi", size=self.contentSize_}
	layer_base_t.init(self, true, ccbiAttrTable)

	self:init_ui()
	self:init_binding_event()
end


function init_ui(self)
	if self.proxy_ ~= nil then
		self.label_first_gift_info =  tolua.cast(self.proxy_:getNode("label_first_gift_info"), "CCLabelTTF")
		self.label_second_gift_info = tolua.cast(self.proxy_:getNode("label_second_gift_info"), "CCLabelTTF")
		self.btn_give_money = tolua.cast(self.proxy_:getNode("btn_give_money"), "CCControlButton")
		self.label_rest_time = tolua.cast(self.proxy_:getNode("label_rest_time"), "CCLabelTTF")
		self.ctrl_info = tolua.cast(self.proxy_:getNode("ctrl_info"), "CCControlButton")
		self.btn_get_gift = tolua.cast(self.proxy_:getNode("btn_get_gift"), "CCControlButton")
		self.node_gift_container_1 = tolua.cast(self.proxy_:getNode("node_gift_container_1"), "CCNode")
		self.node_gift_container_2 = tolua.cast(self.proxy_:getNode("node_gift_container_2"), "CCNode")
		self.sprite_triple = tolua.cast(self.proxy_:getNode("sprite_triple"), "CCSprite")

		self.sprite_triple:setVisible(false)
		self.label_first_gift_info:setString(localizable.ui_firstmoneyaward_tip1)
		self.label_second_gift_info:setString(localizable.ui_firstmoneyaward_tip2)
		for i = 1, 4 do
			local btn_name = "ctrl_gift_" .. tostring(i)
			local sprite_bk_name = "sprite_gift_bk_" .. tostring(i)
			local label_name = "label_award_" .. tostring(i)
			self[label_name] =  tolua.cast(self.proxy_:getNode(label_name), "CCLabelTTF")
			self[btn_name] = tolua.cast(self.proxy_:getNode(btn_name), "CCControlButton")
			self[sprite_bk_name] = tolua.cast(self.proxy_:getNode(sprite_bk_name), "CCSprite")
			self[btn_name]:setTag(i)
			--self[btn_name]:setVisible(true)
		end

		

		--由于图标分散在不同的文件夹，所以需要分开处理
		--第一个礼品
		self.label_award_1:setString(localizable.ui_firstpurchase_label_award1)
		--local pFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("activity_03_04")
		local sprite_icon = CCSprite:createWithSpriteFrameName("activity_03_04")
		local contentSize = self.sprite_gift_bk_1:getContentSize()
		sprite_icon:setPosition(contentSize.width / 2, contentSize.height / 2)
		sprite_icon:setAnchorPoint(ccp(0.5, 0.5))
		self.sprite_gift_bk_1:addChild(sprite_icon)

		--第二个礼品
		local itemInfo = ItemDataInfo:new()
		CGameObjElement:GetItemInfoByDropid(firstpurchase_config.data[1].first_recharge_id1, itemInfo)
		local pIcon, iconFrame = rl_get_iconsprite(itemInfo.mainType, itemInfo.subType, E_FRAMETYPE_MIDDLE, itemInfo.itemId)
		self.sprite_gift_bk_2:setDisplayFrame(iconFrame)
		local pathName = "icon/icon_"..firstpurchase_config.data[1].first_recharge_icon1 ..".plist"
		CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile(pathName)
		self.label_award_2:setString(firstpurchase_config.data[1].first_recharge_name1)
		sprite_icon = CCSprite:createWithSpriteFrameName("icon_" .. firstpurchase_config.data[1].first_recharge_icon1)
		sprite_icon:setPosition(contentSize.width / 2, contentSize.height / 2)
		sprite_icon:setAnchorPoint(ccp(0.5, 0.5))
		self.sprite_gift_bk_2:addChild(sprite_icon)

		--第三个礼品
		CGameObjElement:GetItemInfoByDropid(firstpurchase_config.data[1].first_recharge_id2, itemInfo)
		pIcon, iconFrame = rl_get_iconsprite(itemInfo.mainType, itemInfo.subType, E_FRAMETYPE_MIDDLE, itemInfo.itemId)
		self.sprite_gift_bk_3:setDisplayFrame(iconFrame)
		pathName = "equip/small_"..firstpurchase_config.data[1].first_recharge_icon2 ..".plist"
		CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile(pathName)
		self.label_award_3:setString(firstpurchase_config.data[1].first_recharge_name2)
		sprite_icon = CCSprite:createWithSpriteFrameName("small_" .. firstpurchase_config.data[1].first_recharge_icon2)
		sprite_icon:setPosition(contentSize.width / 2, contentSize.height / 2)
		sprite_icon:setAnchorPoint(ccp(0.5, 0.5))
		self.sprite_gift_bk_3:addChild(sprite_icon)

		--第四个礼品
		CGameObjElement:GetItemInfoByDropid(firstpurchase_config.data[1].first_recharge_id3, itemInfo)
		pIcon, iconFrame = rl_get_iconsprite(itemInfo.mainType, itemInfo.subType, E_FRAMETYPE_MIDDLE, itemInfo.itemId)
		self.sprite_gift_bk_4:setDisplayFrame(iconFrame)
		pathName = "skill/small_"..firstpurchase_config.data[1].first_recharge_icon3 ..".plist"
		CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile(pathName)
		self.label_award_4:setString(firstpurchase_config.data[1].first_recharge_name3)
		sprite_icon = CCSprite:createWithSpriteFrameName("small_" .. firstpurchase_config.data[1].first_recharge_icon3)
		sprite_icon:setPosition(contentSize.width / 2, contentSize.height / 2)
		sprite_icon:setAnchorPoint(ccp(0.5, 0.5))
		self.sprite_gift_bk_4:addChild(sprite_icon)


		local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, protocol.CMD_PAYPACK, protocol.URL_R_PAYPACK)
		--urlpath = AddData(urlpath, "ActType", actType)
		--urlpath = AddData(urlpath, "ActID", actId)
		--urlpath = "http://203.195.181.162:8080/rl_r_paypack?Cmd=1&Uid=80021&Session=962954F5D722633016FF458E22920C29&Clinettime=2013/10/22%2021:56:17%20Tuesday&Platform=win32&Version=1.0.0&Pt=3&ServerID=2&GroupID=1"
		local p = 1
		GetMainMenu():ShowLoadingDlg();	-- 获取信息的时候，不允许操作
		CCHttpRequest:openWithUserData(urlpath, kHttpPost, p, "query=param1&other=params"):sendWithHandler(
			function(res, hnd)
				GetMainMenu():CloseLoadding(); --获取信息完成时，解除禁止操作
				local resData = res:getResponseData()
				--cclog("1111----" .. resData)
				local code = res:getResponseCode()
				local xfile = xml.parse(resData)
				local item = xfile:find("RENLONG")
				local retcode = item.code
				if retcode == "0" then
					self.canget = (xfile:find("canget"))[1]
					local servertime = (xfile:find("servertime"))
					local endtime = (xfile:find("endtime"))
					if endtime ~= nil and servertime ~= nil then
						if tonumber(endtime[1]) < tonumber(servertime[1]) then
							self.node_gift_container_1:removeFromParentAndCleanup(true)
							local parentNodeSize = self.node_gift_container_2:getParent():getContentSize()
							local x, y = self.node_gift_container_2:getPosition()
							self.node_gift_container_2:setPosition(parentNodeSize.width * 0.5, y)
							self.node_gift_container_2:setAnchorPoint(ccp(0.5, 0.5))
							self.label_rest_time:setString(localizable.ui_multi_ended)
						else
							local restSeconds = tools.convertTimeSecondsToStrForPurchase(tonumber(endtime[1]) - tonumber(servertime[1]))
							self.label_rest_time:setString(localizable.ui_first_money_left .. restSeconds)
						end
					else
						self.node_gift_container_1:removeFromParentAndCleanup(true)
						local parentNodeSize = self.node_gift_container_2:getParent():getContentSize()
						local x, y = self.node_gift_container_2:getPosition()
						self.node_gift_container_2:setPosition(parentNodeSize.width * 0.5, y)
						self.node_gift_container_2:setAnchorPoint(ccp(0.5, 0.5))
						self.label_rest_time:setString(localizable.ui_multi_ended)
					end
					--GetMainMenu():ShowTextTip("领取成功",-1)
				else
					--GetMainMenu():ShowErrorTip(retcode,-1)
				end
			end)
	end
end

function init_binding_event(self)
	--立即充值回调函数
	local function give_money_now_callback(btn, event)
		--[[
		if not is_applestore then
			GetMainMenu():ChangeToSub(E_STOREITEMSVIEW)
		end
		]]
		local puchaseLayer = createObj(ui_purchaseLayer)
		GetMainMenu():GetModelLayer():AddDialog(puchaseLayer.node_, 3)
	end

	local function activity_info_callback(btn, event)
		local dlg = CommonDialogView.create()
		CommonDialogView.m_selfview = dlg;
		dlg:SetTitle(localizable.ui_firstmoneyaward_dlg_title)
		local showContent = localizable.ui_firstmoneyaward_dlg_tips
		dlg:SetDescription(showContent)
		dlg:loadCCBI()
		dlg:initUI()
		GetMainMenu():GetModelLayer():AddDialog(dlg, 3);
	end

	local function get_gift_now_callback(btn, event)
		local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, protocol.CMD_PAYPACK, protocol.URL_W_PAYPACK)
		GetMainMenu():ShowLoadingDlg();	-- 获取信息的时候，不允许操作
		CCHttpRequest:open(urlpath, kHttpPost, "query=param1&other=params"):sendWithHandler(
		function(res, hnd)
			GetMainMenu():CloseLoadding(); --获取信息完成时，解除禁止操作
			local resData = res:getResponseData()
			local code = res:getResponseCode()
			local xfile = xml.parse(resData)
			local item = xfile:find("RENLONG")
			local retcode = item.code
			if retcode == "0" then
				local awardXML = xfile:find("award")
				ShowAward(awardXML);
					--GetMainMenu():ShowTextTip("领取成功",-1)
			elseif retcode == "250010" then
				GetMainMenu():ShowTextTip(localizable.ui_firstmoneyaward_have_got,-1)
			elseif retcode == "250011" then
				GetMainMenu():ShowTextTip(localizable.ui_firstmoneyaward_cannot_got,-1)
			end
		end)
	end


	if self.proxy_ ~= nil then
		--礼品卡牌的详细信息
		local function gift_card_info_callback(btn, event)
			local tagIndex = btn:getTag()
			if tagIndex == 1 then
				local dlg = CommonDialogView.create()
				CommonDialogView.m_selfview = dlg;
				dlg:SetTitle(localizable.ui_firstmoneyaward_yuanbao_title)
				dlg:SetDescription(localizable.ui_firstpurchase_label_award1)
				dlg:loadCCBI();
				dlg:initUI()
				GetMainMenu():GetModelLayer():AddDialog(dlg, 3);
			else
				CGameObjElement:ShowDropByID(firstpurchase_config.data[1]["first_recharge_id" .. tostring(tagIndex-1)])
			end	
		end
	
		for i = 1, 4 do
			self.proxy_:handleControlEvent(self["ctrl_gift_" .. tostring(i)], gift_card_info_callback, CCControlEventTouchUpInside)
		end
		self.proxy_:handleControlEvent(self.btn_give_money, give_money_now_callback, CCControlEventTouchUpInside)
		self.proxy_:handleControlEvent(self.ctrl_info, activity_info_callback, CCControlEventTouchUpInside)
		self.proxy_:handleControlEvent(self.btn_get_gift, get_gift_now_callback, CCControlEventTouchUpInside)
	end
end

function onNodeCleanup(self)
    --cclog("onNodeCleanup1111")
    if self.proxy_ then
    	self.proxy_:release()
    end
    layer_base_t.onNodeCleanup(self)
end