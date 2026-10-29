--description: 跨服战排名表格的单元格
--company：xckoo
--author：chenchun
---------------------------------------------

module("ui_multiRankItem", package.seeall)
baseClass(layer_base_t, ui_multiRankItem)

function init(self, cellSize, data, isGiftIcon, myinfo, topteninfo)
	local ccbiAttrTable = {name="multiserverbattle/multiRankItem.ccbi", size=cellSize}
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()
	layer_base_t.init(self, true, ccbiAttrTable)

	self.isGiftIcon = isGiftIcon
	self.data = data
	self.myinfo = {}
	self.topTen = {}
	if myinfo ~= nil then
		self.myinfo = myinfo
	end
	if topteninfo ~= nil then
		self.topTen = topteninfo
	end
	self:init_ui()
	self:init_binding_event()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		self.label_rank = tolua.cast(self.proxy_:getNode("label_rank"),"CCLabelTTF")
		self.label_zone_name = tolua.cast(self.proxy_:getNode("label_zone_name"), "CCLabelTTF")
		self.label_player_name = tolua.cast(self.proxy_:getNode("label_player_name"), "CCLabelTTF")
		self.label_item_score = tolua.cast(self.proxy_:getNode("label_item_score"), "CCLabelTTF")
		self.btn_gift = tolua.cast(self.proxy_:getNode("btn_gift"), "CCControlButton")

		self.btn_gift:setVisible(false)
		self.label_rank:setString(self.data.rank)
		self.label_zone_name:setString(self.data.zone .. localizable.ui_multi_region1)
		self.label_player_name:setString(self.data.name)
		self.label_item_score:setString(self.data.score)
	end
end

function init_binding_event(self)
	if self.proxy_ ~= nil then
		if self.isGiftIcon and tonumber(self.data.rank) <= #self.topTen and self.data.uid ~= nil then
			self.btn_gift:setTag(tonumber(self.data.uid))
			if self.data.uid ~= nil then
				self.btn_gift:setVisible(true)
				local function open_dialog(btn)

					local function get_gift()
						if ui_multiServerLayer.gBattleStatus == 3 then
							if self.data.uid == self.myinfo.myuid and self.data.zone == self.myinfo.myzone then
								local urlpath = GetMultiBattleHeader(self.playerData_.m_uid, 4, protocol.URL_W_CWAR)   --领取top10 奖励
								cclog("1111----%s", urlpath)
								GetMainMenu():ShowLoadingDlg();	-- 获取信息的时候，不允许操作
								CCHttpRequest:open(urlpath, kHttpPost,"query=param1&other=params"):sendWithHandler(
									function(res, hnd)
										GetMainMenu():CloseLoadding(); --获取信息完成时，解除禁止操作
										local resData = res:getResponseData()
										cclog("1111----%s", resData)
										local code = res:getResponseCode()
										local xfile = xml.parse(resData)
										local item = xfile:find("RENLONG")
										local retcode = item.code
										if retcode == "0" then
											local awardXML = item:find("award")
											ShowAward(awardXML)
										else
											GetMainMenu():ShowErrorTip(tonumber(retcode), -1)
										end
									end)
							else
								GetMainMenu():ShowTextTip(localizable.ui_multi_get_rank_gift_error_tips, -1)
							end
						elseif ui_multiServerLayer.gBattleStatus == 2 then
							GetMainMenu():ShowTextTip(localizable.ui_multi_batting_tips, -1)
						elseif ui_multiServerLayer.gBattleStatus == 1 then
							GetMainMenu():ShowTextTip(localizable.ui_multi_batte_before_tips, -1)
						end
					end

					local dlg = CommonDialogView.create()
					CommonDialogView.m_selfview = dlg
					dlg:SetTitle(localizable.ui_multi_get_gift_title)
					--local str = string.format(localizable.ui_inspire_description, 500, MULTI_BATTLE_INSPIRE_VALUE, self.playerInfo.extra_my_times, self.playerInfo.extra_times_lmt)
					dlg:SetDescription(self.topTen[tonumber(self.data.rank)].desc)
					dlg:loadCCBI(kCCMenuHandlerPriority-4, "CommonDialogViewGift")
					dlg:initUI(kCCMenuHandlerPriority-5)
					dlg:SetConfirmHandler(get_gift)
					GetMainMenu():GetModelLayer():AddDialog(dlg, 3)
				end

				self.btn_gift:setTouchPriority(-2)
				self.proxy_:handleControlEvent(self.btn_gift, open_dialog, CCControlEventTouchUpInside)
			end
		end
	end
end

function onNodeCleanup(self)
    --cclog("onNodeCleanup")
    --[[
    if self.node_:retainCount() == 1 then
        self.proxy_:release()
    end
    ]]
    layer_base_t.onNodeCleanup(self)
end