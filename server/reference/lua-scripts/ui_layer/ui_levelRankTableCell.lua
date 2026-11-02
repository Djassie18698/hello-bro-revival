--description: 玩家排名页面的排名表格的单元格
--company：xckoo
--author：chenchun
---------------------------------------------

module("ui_levelRankTableCell", package.seeall)
baseClass(layer_base_t, ui_levelRankTableCell)

function init(self, cellSize, data)
	local ccbiAttrTable = {name="activity/LevelRankItem.ccbi", size=cellSize}
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()
	layer_base_t.init(self, true, ccbiAttrTable)
	self.rank_data = data
	self:init_ui()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		self.label_level = tolua.cast(self.proxy_:getNode("label_level"), "CCLabelTTF")
		self.label_rank = tolua.cast(self.proxy_:getNode("label_rank"),"CCLabelTTF")
		self.label_country_name = tolua.cast(self.proxy_:getNode("label_country_name"), "CCLabelTTF")
		self.label_player_name = tolua.cast(self.proxy_:getNode("label_player_name"), "CCLabelTTF")
		self.btn_vs = tolua.cast(self.proxy_:getNode("btn_vs"), "CCControlButton")
		self.btn_vs:setTag(tonumber(self.rank_data.playerid))


		local function btn_vs_player(btn, event)
			--增加战斗力不够战斗时，直接弹出购买界面
			local function confirm()
			end

			local function cancel()
			end

			if self.playerMgr_:GetPlayerInfoData().m_fightcount <= 0 then
				CTradeMgr:instance():ShowBuyDialogForLua(kConsumablePkEnergy, confirm, cancel)
				return
			end
			local id = btn:getTag()
			if self.playerData_.m_uid ~= self.rank_data.playerid then
				local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, protocol.PVP_CMD_FIGHT, protocol.URL_W_PVP)
				urlpath = AddData(urlpath, "ToUid", self.rank_data.playerid)
				GetMainMenu():ShowLoadingDlg();	-- 获取信息的时候，不允许操作
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
							GetMainMenu():ShowArenaView(resData)
							--GetMainMenu():ShowTextTip("领取成功",-1)
						else
							GetMainMenu():ShowErrorTip(tonumber(retcode), -1)
						end
					end)
			else
				GetMainMenu():ShowTextTip(localizable.ui_fight_with_self_error, -1)
			end
		end
		self.label_rank:setString(self.rank_data.rank)
		self.label_level:setString(self.rank_data.level)
		self.label_country_name:setString(country_config[tonumber(self.rank_data.country)])
		self.label_player_name:setString(self.rank_data.name)

		self.proxy_:handleControlEvent(self.btn_vs, btn_vs_player, CCControlEventTouchUpInside)
	end
end

