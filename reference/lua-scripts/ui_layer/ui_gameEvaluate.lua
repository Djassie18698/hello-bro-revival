--评分界面
--chenchun
---------------------------------------------
module("ui_gameEvaluate", package.seeall)
baseClass(layer_base_t, ui_gameEvaluate)

--m_isEvaluate = 0
function init(self)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	self.contentNode_ = GetActivityView():GetNodeContent()
	self.contentSize_ = self.contentNode_:getContentSize()
	local ccbiAttrTable = {name="activity/GameEvaluate.ccbi", size=self.contentSize_}
	layer_base_t.init(self, true, ccbiAttrTable)

	self.getStatus = 1
	self.is_evaluate = 0  --是否評價
	self.giftlist = {}
	self:init_ui()
	self:init_binding_event()
end


function init_ui(self)
	if self.proxy_ ~= nil then
		self.label_first_gift_info =  tolua.cast(self.proxy_:getNode("label_first_gift_info"), "CCLabelTTF")
		self.btn_give_evaluate = tolua.cast(self.proxy_:getNode("btn_give_evaluate"), "CCControlButton")
		self.btn_get_gift = tolua.cast(self.proxy_:getNode("btn_get_gift"), "CCControlButton")
		self.node_gift_container_2 = tolua.cast(self.proxy_:getNode("node_gift_container_2"), "CCNode")

		self.label_first_gift_info:setString(localizable.ui_evaluate_tips2)
		
		for i = 2, 4 do
			local btn_name = "ctrl_gift_" .. tostring(i)
			local sprite_bk_name = "sprite_gift_bk_" .. tostring(i)
			local label_name = "label_award_" .. tostring(i)
			self[label_name] =  tolua.cast(self.proxy_:getNode(label_name), "CCLabelTTF")
			self[btn_name] = tolua.cast(self.proxy_:getNode(btn_name), "CCControlButton")
			self[sprite_bk_name] = tolua.cast(self.proxy_:getNode(sprite_bk_name), "CCSprite")
			self[btn_name]:setTag(i)
			--self[btn_name]:setVisible(true)
		end

		local contentSize = self.sprite_gift_bk_2:getContentSize()
		
		local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 5, protocol.URL_GROWTH_FUND_R)
		--urlpath = AddData(urlpath, "ActType", actType)
		--urlpath = AddData(urlpath, "ActID", actId)
		--urlpath = "http://192.168.0.236/gift.xml"
		local p = 1
		GetMainMenu():ShowLoadingDlg();	-- 获取信息的时候，不允许操作
		CCHttpRequest:openWithUserData(urlpath, kHttpPost, p, "query=param1&other=params"):sendWithHandler(
			function(res, hnd)
				GetMainMenu():CloseLoadding(); --获取信息完成时，解除禁止操作
				local resData = res:getResponseData()
				cclog("1111----ui_gameEvaluate:%s", resData)
				local code = res:getResponseCode()
				local xfile = xml.parse(resData)
				local item = xfile:find("RENLONG")
				local retcode = item.code
				if retcode == "0" then
					local preview = xfile:find("preview")
					self.getStatus = tonumber(preview.status)
					self.appurl = preview.url
					self.giftlist = xfile:find("giftlist")

					local function gift_card_info_callback(btn, event)
						local tagIndex = btn:getTag()
						--cclog("1111----%d", tagIndex)		
						local dlg = CommonDialogView.create()
						CommonDialogView.m_selfview = dlg;
						dlg:SetTitle(localizable.ui_firstmoneyaward_yuanbao_title)
						dlg:SetDescription(self.giftlist[tagIndex-1].desc)
						dlg:loadCCBI();
						dlg:initUI()
						GetMainMenu():GetModelLayer():AddDialog(dlg, 3);

					end

					for i = 1, #self.giftlist do
						local j = i + 1
						local itemInfo = ItemDataInfo:new()
						CGameObjElement:GetItemInfoByDropid(tonumber(self.giftlist[i].id), itemInfo)
						local pIcon, iconFrame = rl_get_iconsprite(itemInfo.mainType, itemInfo.subType, E_FRAMETYPE_MIDDLE, itemInfo.itemId)
						self["sprite_gift_bk_" .. tostring(j)]:setDisplayFrame(iconFrame)
						local pathName = "props/"..self.giftlist[i].icon ..".plist"
						CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile(pathName)
						self["label_award_" .. tostring(j)]:setString(self.giftlist[i].desc)
						local sprite_icon = CCSprite:createWithSpriteFrameName(self.giftlist[i].icon)
						sprite_icon:setPosition(contentSize.width / 2, contentSize.height / 2)
						sprite_icon:setAnchorPoint(ccp(0.5, 0.5))
						self["sprite_gift_bk_" .. tostring(j)]:addChild(sprite_icon)

						self.proxy_:handleControlEvent(self["ctrl_gift_" .. tostring(j)], gift_card_info_callback, CCControlEventTouchUpInside)
					end
				else
					GetMainMenu():ShowErrorTip(retcode,-1)
				end
			end)

			
	end
end

function init_binding_event(self)
	--评价回调函数
	local function give_evaluate_callback(btn, event)
		--openHyperlink(self.appurl)
		--cclog("1111----url:%s", self.appurl)
		self.is_evaluate = 1
		--ui_gameEvaluate.m_isEvaluate = 1
		openHyperlink(self.appurl)

	end

	local function get_gift_now_callback(btn, event)

		if self.getStatus == 0 and self.is_evaluate == 1 then 
			local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 6, protocol.URL_GROWTH_FUND_R)
			GetMainMenu():ShowLoadingDlg();	-- 获取信息的时候，不允许操作
			CCHttpRequest:open(urlpath, kHttpPost, "query=param1&other=params"):sendWithHandler(
			function(res, hnd)
				GetMainMenu():CloseLoadding(); --获取信息完成时，解除禁止操作
				local resData = res:getResponseData()
				--cclog("1111----01%s", resData)
				local code = res:getResponseCode()
				local xfile = xml.parse(resData)
				local item = xfile:find("RENLONG")
				local retcode = item.code
				if retcode == "0" then
					local awardXML = xfile:find("award")
					ShowAward(awardXML);
					self.getStatus = 1
						--GetMainMenu():ShowTextTip("领取成功",-1)
				else
					GetMainMenu():ShowErrorTip(retcode,-1)
				end
			end)
		else
			if self.getStatus == 1 then
				GetMainMenu():ShowTextTip(localizable.ui_evaluate_application_tips1,-1)
			else
				GetMainMenu():ShowTextTip(localizable.ui_evaluate_tips3, -1)
			end
		end
	end


	if self.proxy_ ~= nil then
		self.proxy_:handleControlEvent(self.btn_give_evaluate, give_evaluate_callback, CCControlEventTouchUpInside)
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