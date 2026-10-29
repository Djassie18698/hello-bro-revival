--description: 当资源不足时，购买提示窗口（公共的）
--company：xckoo
--author：chenchun
--date：2013-12-24
---------------------------------------------
module("ui_dialogBuyItemLayer", package.seeall)
baseClass(layer_base_t, ui_dialogBuyItemLayer)

function init(self, _itemtype)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	local winSize = CCDirector:sharedDirector():getWinSize()

	local ccbiAttrTable = {name="dlg_ui/BuyItemDlg.ccbi", size=CCSizeMake(768, winSize.height)}
	layer_base_t.init(self, true, ccbiAttrTable)

	self.deltatime = 0
	self.m_consumableItemType = _itemtype or tradeMgr_config.kConsumableEnergy
	self.m_consumableType = tradeMgr_config.kConsumableTypeItem
	self.m_itemIndex = 0
	self.m_info = ConsumeInfo:new()
	self.m_giftinfo = Struct_Giftinfo:new()
	self:setType()
	self.activity_data = data
	self:init_ui()
end

function getConsumableItemTypeAndIndex(self)
	if tradeMgr_config.kConsumableCoin == self.m_consumableItemType then
		self.m_itemIndex = tradeMgr_config.SMALL_COIN_ITEM_INDEX
		self.m_consumableType = tradeMgr_config.kConsumableTypeItem
	elseif tradeMgr_config.kConsumableEnergy == self.m_consumableItemType then
		self.m_itemIndex = tradeMgr_config.SMALL_ENERGY_ITEM_INDEX
		self.m_consumableType = kConsumableTypeItem
	elseif tradeMgr_config.kConsumablePkEnergy == self.m_consumableItemType then
		self.m_itemIndex = tradeMgr_config.SMALL_PK_ENERGY_ITEM_INDEX
		self.m_consumableType = kConsumableTypeItem
	elseif tradeMgr_config.kGiftpackNinja == self.m_consumableItemType then
		self.m_itemIndex = tradeMgr_config.SMALL_NINJA_GIFTPACK_ITEM_INDEX
		self.m_consumableType = tradeMgr_config.kCosnuambleTypeGiftpack
	elseif tradeMgr_config.kGiftpackWeapon == self.m_consumableItemType then
		self.m_itemIndex = tradeMgr_config.SMALL_WEAPON_GIFTPACK_ITEM_INDEX
		self.m_consumableType = tradeMgr_config.kCosnuambleTypeGiftpack
	elseif tradeMgr_config.kGiftpackArmor == self.m_consumableItemType then
		self.m_itemIndex = tradeMgr_config.SMALL_ARMOR_GIFTPACK_ITEM_INDEX
		self.m_consumableType = tradeMgr_config.kCosnuambleTypeGiftpack
	elseif tradeMgr_config.kGiftpackDecoration == self.m_consumableItemType then
		self.m_itemIndex = tradeMgr_config.SMALL_DECORATION_GIFTPACK_ITEM_INDEX
		self.m_consumableType = tradeMgr_config.kCosnuambleTypeGiftpack
	elseif tradeMgr_config.kGiftpackSkill == self.m_consumableItemType then
		self.m_itemIndex = tradeMgr_config.SMALL_SKILL_GIFTPACK_ITEM_INDEX
		self.m_consumableType = tradeMgr_config.kCosnuambleTypeGiftpack
	elseif tradeMgr_config.kGiftpackSmallStone == self.m_consumableItemType then
		self.m_itemIndex = tradeMgr_config.SMALL_STONE_GIFTPACK_ITEM_INDEX
		self.m_consumableType = tradeMgr_config.kCosnuambleTypeGiftpack
	elseif tradeMgr_config.kGiftpackBigStone == self.m_consumableItemType then
		self.m_itemIndex = tradeMgr_config.BIG_STONE_GIFTPACK_ITEM_INDEX
		self.m_consumableType = tradeMgr_config.kCosnuambleTypeGiftpack
	end
end

function setType(self)
	self:getConsumableItemTypeAndIndex()
	if self.m_consumableType == tradeMgr_config.kConsumableTypeItem then
		CTradeMgr:instance():GetConsum(self.m_itemIndex-1, self.m_info)
	elseif (m_consumableType == kCosnuambleTypeGiftpack)
		CTradeMgr:instance():GetGift(self.m_itemIndex-1, self.m_giftinfo)
	end

	if self.m_consumableType == tradeMgr_config.kConsumableTypeItem then
		if self.m_info.m_bagnum == 0 then
			local info = CTradeMgr:instance():GetConsum(self.m_itemIndex, info)
			if info.m_bagnum > 0 then
				self.m_itemIndex = self.m_itemIndex + 1
				self.m_info = info
			elseif self.m_consumableItemType == tradeMgr_config.kConsumableCoin then
				--有足够元宝的情况下，缺银票直接提示买大的银票包
				self.playerMgr_ = CPlayerDataMgr:instance()
				self.playerData_ = self.playerMgr_:GetPlayerInfoData()
				if self.playerData_.m_gold >= info.m_needgold or self.playerData_.m_silver >= info.m_needsilver then
					self.m_itemIndex = self.m_itemIndex + 1
					self.m_info = info
				end
			end
		end
	end
end


function init_ui(self)
	if self.proxy_ ~= nil then
		self.btnDialogClose =  tolua.cast(self.proxy_:getNode("btnDialogClose"), "CCControlButton")
		self.btnBuy =  tolua.cast(self.proxy_:getNode("btnBuy"), "CCControlButton")
		self.btnClose =  tolua.cast(self.proxy_:getNode("btnClose"), "CCControlButton")
		self.sprite_store_goldicon = tolua.cast(self.proxy_:getNode("sprite_store_goldicon"), "CCSprite")
		self.sprite_my_goldicon = tolua.cast(self.proxy_:getNode("sprite_my_goldicon"), "CCSprite")
		self.label_my_gold =  tolua.cast(self.proxy_:getNode("label_my_gold", "CCLabelTTF")
		self.label_item_price =  tolua.cast(self.proxy_:getNode("label_item_price"), "CCLabelTTF")
		self.label_item_count = tolua.cast(self.proxy_:getNode("label_item_count"), "CCLabelTTF")
		self.label_title = tolua.cast(self.proxy_:getNode("label_item_count"), "CCLabelTTF")
		self.label_item_name = tolua.cast(self.proxy_:getNode("label_item_name"), "CCLabelTTF")
		self.label_item_desc = tolua.cast(self.proxy_:getNode("label_item_desc"), "CCLabelTTF")
		self.label_desc = tolua.cast(self.proxy_:getNode("label_desc"), "CCLabelTTF")
		self.label_use = tolua.cast(self.proxy_:getNode("label_use"), "CCLabelTTF")
		self.label_buy = tolua.cast(self.proxy_:getNode("label_buy"), "CCLabelTTF")
		self.sprite_item_icon = tolua.cast(self.proxy_:getNode("sprite_item_icon"), "CCSprite")
		self.label_current_energy = tolua.cast(self.proxy_:getNode("label_current_energy"), "CCLabelTTF")
		self.label_next_energy_recover = tolua.cast(self.proxy_:getNode("label_next_energy_recover"), "CCLabelTTF")
		self.label_all_energy_recover = tolua.cast(self.proxy_:getNode("label_all_energy_recover"), "CCLabelTTF")
		self.label_current_pk = tolua.cast(self.proxy_:getNode("label_current_pk"), "CCLabelTTF")
		self.label_next_pk_recover = tolua.cast(self.proxy_:getNode("label_next_pk_recover"), "CCLabelTTF")
		self.label_all_pk_recover = tolua.cast(self.proxy_:getNode("label_all_pk_recover"), "CCLabelTTF")
		self.node_energy_desc_container = tolua.cast(self.proxy_:getNode("node_energy_desc_container"), "CCNode")
		self.node_pk_desc_container = tolua.cast(self.proxy_:getNode("node_pk_desc_container"), "CCNode")

		local function updateLeftTimeLabel(fDeltaTime)
			self.deltatime = self.deltatime + fDeltaTime
			if self.deltatime >= 1 then
				local intPart, floatPart = math.modf(self.deltatime)
				self.deltatime = floatPart
				if tradeMgr_config.kConsumableEnergy == self.m_consumableItemType then --如果是体力购买框
					local text1 = string.format("%d/%d",self.playerMgr_:GetPlayerInfoData().m_bodyvalue,self.playerMgr_:GetMaxBodyValue())
					self.label_current_energy:setString(text1)
					self.label_next_energy_recover:setString(tostring(self.playerMgr_:GetEnergyRestTimeText())
					self.label_all_energy_recover:setString(tostring(self.playerMgr_:GetTimeText(self.playerMgr_:GetTotalEnergyRestTime())))
				elseif tradeMgr_config.kConsumablePkEnergy == self.m_consumableItemType then --如果是斗力购买框
					local text2 = string.format("%d/%d",self.playerMgr_:GetPlayerInfoData().m_fightcount,self.playerMgr_:GetMaxAttackCount())
					self.label_current_pk:setString(text2)
					self.label_next_pk_recover:setString(tostring(self.playerMgr_:GetPkRestTimeText()))
					self.label_all_pk_recover:setString(self.playerMgr_:GetTimeText(self.playerMgr_:GetTotalPkRestTime()))
				else

				end
			end
		end

		local frame = nil
		local itemName = nil
		if self.m_consumableType == tradeMgr_config.kConsumableTypeItem then
			if self.m_info.m_needgold > 0 then
				frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("com_gold_icon")
				if frame then
					self.sprite_store_goldicon:setDisplayFrame(frame)
					self.sprite_my_goldicon:setDisplayFrame(frame)
				end
				self.label_my_gold:setString(tostring(self.playerData_.m_gold))
				self.label_item_price:setString(tostring(self.m_info.m_needgold))
			else
				frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("com_silver_icon")
				if frame then
					self.sprite_store_goldicon:setDisplayFrame(frame)
					self.sprite_my_goldicon:setDisplayFrame(frame)
				end
				self.label_my_gold:setString(tostring(self.playerData_.m_silver))
				self.label_item_price:setString(tostring(self.m_info.m_needsilver))
			end

			self.label_item_count:setString(tostring(self.m_info.m_bagnum))
			self.label_title:setString(tostring(self.m_info.m_namestr))
			self.label_item_name:setString(tostring(self.m_info.m_namestr))
			self.label_item_desc:setString(tostring(self.m_info.m_consumedesc))

			local buf = string.format(text.text_config[121].description, getItemRealName(self.m_consumableItemType),self.m_info.m_namestr)
			self.label_desc:setString(buf)

			-- 设置道具图标
			itemName = CTradeMgr():instance():getConsumInfoIcon(self.m_info.m_id)

			if self.m_info.m_bagnum > 0 then
				self.label_use:setVisible(true)
				self.label_buy:setVisible(false)
			else
				self.label_use:setVisible(false)
				self.label_buy:setVisible(true)
			end
		else
			if self.m_giftinfo.m_price_gold > 0 then
				frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("com_gold_icon");
				if frame then
					self.sprite_store_goldicon:setDisplayFrame(frame)
					self.sprite_my_goldicon:setDisplayFrame(frame)
				end
				self.label_my_gold:setString(tostring(self.playerData_.m_gold))
				self.label_item_price:setString(tostring(self.m_giftinfo.m_price_gold))
			else
				frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("com_silver_icon")
				if frame then
					self.sprite_store_goldicon:setDisplayFrame(frame)
					self.sprite_my_goldicon:setDisplayFrame(frame)
				end
				self.label_my_gold:setString(tostring(self.playerData_.m_silver))
				self.label_item_price:setString(tostring(self.m_giftinfo.m_price_silver))
			end

			self.label_item_count:setString(tostring(0))
			self.label_title:setString(tostring(self.m_giftinfo.m_giftname))
			self.label_item_name:setString(tostring(self.m_giftinfo.m_giftname))
			self.label_item_desc:setString(tostring(self.m_giftinfo.m_giftdesc))

			local buf = string.format(text.text_config[121].description, getItemRealName(self.m_consumableItemType),self.m_info.m_namestr)
			self.label_desc:setString(buf)

			self.label_use:setVisible(false)
			self.label_buy:setVisible(true)

			itemName = CTradeMgr():instance():getGiftInfoIcon(self.m_info.m_id)
		end

		local pframe = CGameObjElement:GetConsumeIcon(E_FRAMETYPE_SMALL, itemName)
		if pframe ~= nil then
			local pIcon = CCSprite:createWithSpriteFrame(pframe)
			local size = self.sprite_item_icon:getContentSize()
			if pIcon ~= nil then
				self.sprite_item_icon:addChild(pIcon)
				pIcon:setPosition(size.width/2, size.height/2)
				pIcon:setAnchorPoint(ccp(0.5, 0.5))
			end
		end

		self.node_energy_desc_container:setVisible(false)
		self.node_pk_desc_container:setVisible(false)
		self.label_desc:setVisible(false)

		if tradeMgr_config.kConsumableEnergy == self.m_consumableItemType then --如果是体力购买框
			self.node_energy_desc_container:setVisible(true)
		elseif tradeMgr_config.kConsumablePkEnergy == self.m_consumableItemType then --如果是斗力购买框
			self.node_pk_desc_container:setVisible(true)
		else
			self.label_desc:setVisible(true)
		end

		self.node_:scheduleUpdateWithPriorityLua(updateLeftTimeLabel, 0)
	end
end

function init_binding_event(self)
	if self.proxy_ ~= nil then

		local function onBuy(btn, event)
			if self.m_consumableType == tradeMgr_config.kConsumableTypeItem then
				if self.m_info.m_bagnum > 0 then
					self:useConsume(self.m_info.m_id, tradeMgr_config.TRADE_USE_CONSUME)
				else
					local pTradeMgr = CTradeMgr:instance()
					local pDataMgr = CPlayerDataMgr:instance()
					if self.playerMgr_:GetPlayerInfoData().m_gold >= self.m_info.m_needgold or self.playerMgr_:GetPlayerInfoData().m_silver >= self.m_info.m_needsilver then
						self:purchase(self.m_info.m_id, tradeMgr_config.TRADE_BUY_CONSUME)
					else
						if self.m_info.m_needgold > 0 then
							GetMainMenu()->ShowTextTip(text.text_config[10006].description, -1)
						elseif self.m_info.m_needsilver > 0 then
							GetMainMenu()->ShowTextTip(text.text_config[10008].description, -1)
						end
						self:remove()
					end
				end
			else
				local pTradeMgr = CTradeMgr:instance()
				if (self.m_giftinfo.m_price_gold > 0 and
					self.playerMgr_:GetPlayerInfoData().m_gold >= self.m_giftinfo.m_price_gold) or
					(self.m_giftinfo.m_price_silver > 0 and
					self.playerMgr_:GetPlayerInfoData().m_silver >= self.m_giftinfo.m_price_silver) then

					pTradeMgr:purchase(self.m_giftinfo.m_id,  tradeMgr_config.TRADE_BUY_GIFT)

				else
					if self.m_giftinfo.m_price_gold > 0 then
						GetMainMenu()->ShowTextTip(text.text_config[10006].description, -1)
					elseif self.m_giftinfo.m_price_silver > 0 then
						GetMainMenu()->ShowTextTip(text.text_config[10008].description, -1)
					end
					self:remove()
				end
		end

		local function onClose(btn, event)
			self.node_:unscheduleUpdate()
			self.node:removeFromParentAndCleanup(true)
		end

		self.proxy_:handleControlEvent(self.btnDialogClose, onClose, CCControlEventTouchUpInside)
		self.proxy_:handleControlEvent(self.btnBuy, onBuy, CCControlEventTouchUpInside)
		self.proxy_:handleControlEvent(self.btnClose, onClose, CCControlEventTouchUpInside)
	end
end


function useConsume(self, goodsId, tradeType)
	local m_cmd = CTradeMgr:instance():GetCMD(tradeType)
	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, m_cmd, protocol.URL_USECONSUME)
	AddData(urlpath, "Goodsid", goodsId)
	GetMainMenu():ShowLoadingDlg()	-- 获取信息的时候，不允许操作
	CCHttpRequest:open(urlpath, kHttpPost, "query=param1&other=params"):sendWithHandler(
		function(res, hnd)
			GetMainMenu():CloseLoadding(); --获取信息完成时，解除禁止操作
			local resData = res:getResponseData()
			local code = res:getResponseCode()
			local xfile = xml.parse(resData)
			local item = xfile:find("RENLONG")
			local retcode = item.code
			if retcode == "0" then
				local item = xfile:find("shopbuy")
				if item then
					self.playerMgr_:AddGold(tonumber(item.costyb))
					self.playerMgr_:AddSilver(tonumber(item.costyz))
					self.m_info.m_bagnum = self.m_info.m_bagnum + 1

					CTradeMgr:instance():SetConsum(self.m_itemIndex-1, self.m_info)
					self:useConsume(self.m_info.m_id, tradeMgr_config.TRADE_USE_CONSUME)
				else
					GetMainMenu():ShowTextTip(text.text_config[120].description, -1)
					self:remove()
				end
			else
				GetMainMenu():ShowTextTip(text.text_config[tonumber(retcode)].description, -1)
				self:remove()
			end
		end)
end

function remove(self)
	self.node_:unscheduleUpdate()
	self.node:removeFromParentAndCleanup(true)
end

function onNodeCleanup(self)
    --cclog("onNodeCleanup")
    --[[
    if self.node_:retainCount() == 1 then
        self.proxy_:release()
    end
    ]]
    if self.proxy_ then
    	self.proxy_:release()
    end
    self.node_:unscheduleUpdate()
    layer_base_t.onNodeCleanup(self)
end

function getItemRealName(_itemtype)
	if _itemtype == tradeMgr_config.kConsumableEnergy then
		return text.text_config[122]
	elseif _itemtype == tradeMgr_config.kConsumablePkEnergy then
		return text.text_config[123]
	elseif _itemtype == tradeMgr_config.kConsumableCoin then
		return text.text_config[124]
	else
		return text.text_config[271]
	end
end