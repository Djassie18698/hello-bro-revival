--description: 累计充值
--company：xckoo
--author：chenchun
---------------------------------------------
module("ui_accumulateMoneyTableCell", package.seeall)
baseClass(layer_base_t, ui_accumulateMoneyTableCell)

function init(self, cellSize, data)
	local ccbiAttrTable = {name="activity/AccumulateItem.ccbi", size=cellSize}
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()
	layer_base_t.init(self, true, ccbiAttrTable)
	self.gift_data = data
	self:init_ui()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		local pFrameNoGiftBK = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("small_no_obj_frame")
		local pFrameHasGiftBk = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("small_box_skill_05")
		for i = 1, 4 do
			self["sprite_item" .. tostring(i)] = tolua.cast(self.proxy_:getNode("sprite_item" .. tostring(i)), "CCSprite")
			self["label_item_name" .. tostring(i)] = tolua.cast(self.proxy_:getNode("label_item_name" .. tostring(i)), "CCLabelTTF")
			self["sprite_item" .. tostring(i)]:setDisplayFrame(pFrameNoGiftBK)
			self["label_item_name" .. tostring(i)]:setVisible(false)

			self["ctrl_gift_" .. tostring(i)] = tolua.cast(self.proxy_:getNode("ctrl_gift_" .. tostring(i)), "CCControlButton")
			self["ctrl_gift_" .. tostring(i)]:setTag(i)
			--转生标志_litao_2014.8.2
			self["spr_frame_corner1_"..tostring(i)] = tolua.cast(self.proxy_:getNode("spr_frame_corner1_" .. tostring(i)), "CCSprite")
			self["spr_frame_corner2_"..tostring(i)] = tolua.cast(self.proxy_:getNode("spr_frame_corner2_" .. tostring(i)), "CCSprite")
		end
		self.btn_scale_sprite = tolua.cast(self.proxy_:getNode("btn_scale_sprite"), "CCScale9Sprite")
		self.label_item_title = tolua.cast(self.proxy_:getNode("label_item_title"), "CCLabelTTF")
		self.label_item_title:setString(self.gift_data.title)
		self.label_get_title = tolua.cast(self.proxy_:getNode("label_get_title"), "CCLabelTTF")
		self.node_btn_container = tolua.cast(self.proxy_:getNode("node_btn_container"), "CCNode")
		self.sprite_hasgot = tolua.cast(self.proxy_:getNode("sprite_hasgot"),  "CCSprite")
		--self.ctrl_get_gift = tolua.cast(self.proxy_:getNode("ctrl_get_gift"), "CCControlButton")
		if self.gift_data.status == 1 or self.gift_data.status == 3 then
			--self.ctrl_get_gift:setTitleForState(localizable.ui_status_1, CCControlStateNormal)
			--self.ctrl_get_gift:setTitleForState(localizable.ui_status_1, CCControlStateHighlighted)
			--self.ctrl_get_gift:setTitleForState(localizable.ui_status_1, CCControlStateDisabled)
			self.label_get_title:setString(localizable.ui_status_1)
		else
			--self.ctrl_get_gift:setTitleForState(localizable.ui_status_2, CCControlStateNormal)
			--self.ctrl_get_gift:setTitleForState(localizable.ui_status_2, CCControlStateHighlighted)
			--self.ctrl_get_gift:setTitleForState(localizable.ui_status_2, CCControlStateDisabled)
			self.label_get_title:setString(localizable.ui_status_2)
			self.node_btn_container:setVisible(false)
			self.sprite_hasgot:setVisible(true)
		end

		local index = 1
		for k, v in pairs(self.gift_data.gift) do
			--边框按照品质来litao_2014.7.9
			local _t_card = {}
			local _maintype = 0
			local _subtype = 0
			local _id = -1
			_maintype, _subtype, _id = setObjTypeInfo(v.drop)
			_t_card.pIcon, _t_card.pFrame = rl_get_iconsprite(_maintype, _subtype, E_FRAMETYPE_SMALL, _id)
			--frame
			if nil ~= _t_card.pFrame then
				self["sprite_item"..tostring(index)]:setDisplayFrame(_t_card.pFrame)
			end
			--self["sprite_item" .. tostring(index)]:setDisplayFrame(pFrameHasGiftBk)
			CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile("props/" .. v.icon .. ".plist")
			local sprite_icon = CCSprite:createWithSpriteFrameName(v.icon)
			local contentSize = self["sprite_item" .. tostring(index)]:getContentSize()
			sprite_icon:setPosition(contentSize.width / 2, contentSize.height / 2)
			sprite_icon:setAnchorPoint(ccp(0.5, 0.5))
			self["sprite_item" .. tostring(index)]:addChild(sprite_icon)
			self["label_item_name" .. tostring(index)]:setString(v.name)
			self["label_item_name" .. tostring(index)]:setVisible(true)
			--增加转生等级_litao_2014.8.2
			if tonumber(v.newlife) > 0 then
				self["spr_frame_corner1_"..tostring(index)]:setVisible(true)
				self["spr_frame_corner2_"..tostring(index)]:setVisible(true)
				local topinlayframe = CGameObjElement:GetTopInlayFrame(E_FRAMETYPE_SMALL, v.newlife)
				if topinlayframe ~= nil then
					self["spr_frame_corner1_"..tostring(index)]:setDisplayFrame(topinlayframe)
				end

				local downinlayframe = CGameObjElement:GetDownInlayFrame(E_FRAMETYPE_SMALL, v.newlife)
				if downinlayframe ~= nil then
					self["spr_frame_corner2_"..tostring(index)]:setDisplayFrame(downinlayframe)
				end
			else
				self["spr_frame_corner1_"..tostring(index)]:setVisible(false)
				self["spr_frame_corner2_"..tostring(index)]:setVisible(false)		
			end
			index = index + 1
		end

		--隐藏没有物品的节点框转生标志_litao_2014.8.2
		for i=1,4 do
			if i > #self.gift_data.gift then
				self["spr_frame_corner1_"..tostring(i)]:setVisible(false)
				self["spr_frame_corner2_"..tostring(i)]:setVisible(false)
			end
		end

		local function btn_get_gift(btn, event)
			local id = self.gift_data.id
			local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 9100, protocol.URL_W_ACTIVITY)
			urlpath = AddData(urlpath, "ActType", 6)
			urlpath = AddData(urlpath, "SubID", id)
			--cclog("1111----%s", urlpath)
			GetMainMenu():ShowLoadingDlg()	-- 获取信息的时候，不允许操作
			CCHttpRequest:open(urlpath, kHttpPost,"query=param1&other=params"):sendWithHandler(
				function(res, hnd)
					GetMainMenu():CloseLoadding(); --获取信息完成时，解除禁止操作
					local resData = res:getResponseData()
					local code = res:getResponseCode()
					local xfile = xml.parse(resData)
					local item = xfile:find("RENLONG")
					if item == nil then
						return nil
					end
					local retcode = item.code
					if retcode == "0" then
						local awardXML = xfile:find("award")
						ShowAward(awardXML)
						self.label_get_title:setString(localizable.ui_status_2)
						self.node_btn_container:setVisible(false)
						self.sprite_hasgot:setVisible(true)
						if newsCount > 0 then
							newsCount = newsCount - 1
						end
						--updated by gongsun 2014.4.14 将开关上的新消息标志刷新
						if ui_activityPopupLayer.getPopupActivityData then
							for k, v in pairs(ui_activityPopupLayer.getPopupActivityData) do
								if v.icon == "activity12" and tonumber(v.newscount) > 0 then
									v.newscount = tonumber(v.newscount) - 1
									CPlayerDataMgr:instance():SetActivityNews("activity12", v.newscount)
									break
								end
							end
						end
						-------------------------------------------------------
						CPlayerDataMgr:instance():SetActivityNewsNum(newsCount)
						GetActTopBarView():Refresh()

						--GetMainMenu():ShowTextTip("领取成功",-1)
					elseif retcode == "314000" then
						GetMainMenu():ShowTextTip(localizable.ui_accu_has_got_gift, -1)
					elseif retcode == "314004" then
						GetMainMenu():ShowTextTip(localizable.ui_accu_has_not_reach,-1)
					elseif retcode == "314002" then
						GetMainMenu():ShowTextTip(localizable.ui_accu_activity_out_of_date,-1)
					elseif retcode == "314003" then
						GetMainMenu():ShowTextTip(localizable.ui_accu_has_not_start,-1)
					end
				end)
		end

		local function btn_show_gift(btn)
			local index = btn:getTag()
			if index <= #self.gift_data.gift then
				--cclog("1111----%s", tostring(self.gift_data.gift[index].drop))
				CGameObjElement:ShowDropByID(tonumber(self.gift_data.gift[index].drop))
			end
		end

		for k = 1, 4 do
			self["ctrl_gift_" .. tostring(k)]:setTouchPriority(1)
			self.proxy_:handleControlEvent(self["ctrl_gift_" .. tostring(k)], btn_show_gift, CCControlEventTouchUpInside)
		end
		
	end
end

function btn_get_gift_1(self)
	local id = self.gift_data.id
	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 9100, protocol.URL_W_ACTIVITY)
	urlpath = AddData(urlpath, "ActType", 6)
			urlpath = AddData(urlpath, "SubID", id)
			--cclog("1111----%s", urlpath)
			GetMainMenu():ShowLoadingDlg()	-- 获取信息的时候，不允许操作
			CCHttpRequest:open(urlpath, kHttpPost,"query=param1&other=params"):sendWithHandler(
				function(res, hnd)
					GetMainMenu():CloseLoadding(); --获取信息完成时，解除禁止操作
					local resData = res:getResponseData()
					local code = res:getResponseCode()
					local xfile = xml.parse(resData)
					local item = xfile:find("RENLONG")
					if item == nil then
						return nil
					end
					local retcode = item.code
					if retcode == "0" then
						local awardXML = xfile:find("award")
						ShowAward(awardXML)
						self.label_get_title:setString(localizable.ui_status_2)
						self.node_btn_container:setVisible(false)
						self.sprite_hasgot:setVisible(true)
						--GetMainMenu():ShowTextTip("领取成功",-1)
					elseif retcode == "314000" then
						GetMainMenu():ShowTextTip(localizable.ui_accu_has_got_gift, -1)
					elseif retcode == "314004" then
						GetMainMenu():ShowTextTip(localizable.ui_accu_has_not_reach,-1)
					elseif retcode == "314002" then
						GetMainMenu():ShowTextTip(localizable.ui_accu_activity_out_of_date,-1)
					elseif retcode == "314003" then
						GetMainMenu():ShowTextTip(localizable.ui_accu_has_not_start,-1)
					end
				end)
end