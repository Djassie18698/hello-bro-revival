----------------------------------------------------------------------
--  Copyright (c) 2014-2016, XCKOO. All Rights Reserved.
--  Author :Tango
--  Time   :2015-11-12 16:18:32
--  Remark :热点宝藏
----------------------------------------------------------------------

module("ui_hotTreasure", package.seeall)
baseClass(layer_base_t, ui_hotTreasure)

require('ui_layer/ui_hotTreasurePreview')
require('ui_layer/ui_showAwards')

function init(self, node)
	self.contentNode_ = GetActivityView():GetNodeContent()
	self.contentSize_ = self.contentNode_:getContentSize()

	local ccbiAttrTable = { name = "activity/hotTreasure.ccbi", size = self.contentSize_ }
	layer_base_t.init(self, true, ccbiAttrTable)

	-- 用户info
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	-- pre node
	self.preNode = node
	-- 1开启，0结束
	self.state = 1
	self.deltatime = 0
	-- {一次, 十次}
	self.cost = { 0, 0 }
	self.free = 0

	self.main = { }
	self.minor = { }
	self.allItems = { }

	self:init_ui()
	self:init_binding_event()
end

function init_ui(self)
	if self.proxy_ ~= nil then

		self.labelTime = getLabelTTFFromCCB(self.proxy_, 'lb_time')
		self.labelCostOne = getLabelBMFontFromCCB(self.proxy_, 'lb_cost_one')
		self.labelCostTen = getLabelBMFontFromCCB(self.proxy_, 'lb_cost_ten')

		self.sprItemMain = getSpriteFromCCB(self.proxy_, 'spr_hot_main')
		self.btnItemMain = getButtonFromCCB(self.proxy_, 'btn_main')

		self.sprTypeMain = getSpriteFromCCB(self.proxy_, 'sprite_type_main')

		self.sprItemMinor = { }
		self.btnItemMinor = { }
		self.sprTypeMinor = { }
		for i = 1, 3 do
			self.sprItemMinor[i] = getSpriteFromCCB(self.proxy_, 'spr_minor' .. i)
			self.btnItemMinor[i] = getButtonFromCCB(self.proxy_, 'btn_minor' .. i)
			self.sprTypeMinor[i] = getSpriteFromCCB(self.proxy_, 'sprite_type_' .. i)
		end

		self.btnOnce = getButtonFromCCB(self.proxy_, 'btn_once')
		setBtnTitle(self.btnOnce, localizable.ui_hotTreasure_btn1)
		self.btnTen = getButtonFromCCB(self.proxy_, 'btn_ten')
		setBtnTitle(self.btnOnce, localizable.ui_hotTreasure_btn2)

		self.btnPreview = getButtonFromCCB(self.proxy_, 'btn_preview')

		self.nodePriceOne = getNodeFromCCB(self.proxy_, 'node_priceOne')
		self.labelFree = getLabelTTFFromCCB(self.proxy_, 'label_free')
		self.labelFree:setString(localizable.ui_hotTreasure_text2)
		getLabelTTFFromCCB(self.proxy_, 'label_unuse1'):setString(localizable.ui_hotTreasure_text1)
		getLabelTTFFromCCB(self.proxy_, 'lb_main_hot'):setString(localizable.ui_hotTreasure_main)
		getLabelTTFFromCCB(self.proxy_, 'lb_minor_hot'):setString(localizable.ui_hotTreasure_minor)



		-- init
		self:requestBaseInfo()
	end
end

function requestBaseInfo(self)
	local function updateCountdown(dt)
		self.deltatime = self.deltatime + dt
		if self.deltatime < 1 then return end

		local intPart, floatPart = math.modf(self.deltatime)
		self.restTime = self.restTime - intPart
		if self.restTime > 0 then
			local timeStr = tools.convertTimeElectronicWatchHaveDay(self.restTime, 3)
			self.labelTime:setString(localizable.ui_timeleft .. timeStr)
			self.deltatime = floatPart
			self.state = 1
		else
			self.state = 0
			self.labelTime:setString(localizable.ui_monopoly_end)
			self.labelTime:unscheduleUpdate()
		end
	end

	local function getItemFromXml(src)
		local _item = {
			dropid = tonumber(src:find('drop_id')[1]),
			desc = src:find('desc')[1],
			type = tonumber(src:find('main_type')[1]),
			subtype = tonumber(src:find('sub_type')[1]),
			icon = tonumber(src:find('prop_id')[1])
		}
		return _item
	end

	-- 请求基本信息
	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 12, "rl_x_small_activity")
	local function callback(renlong)
		self.restTime = tonumber(renlong:find("remain_time")[1])
		if self.restTime > 0 then
			self.state = 1
			self.labelTime:scheduleUpdateWithPriorityLua(updateCountdown, 0)
		else
			self.state = 0
		end

		self.cost = { tonumber(renlong:find("one_cost")[1]), tonumber(renlong:find("ten_cost")[1]) }

		local mainItem = renlong:find('main')[1]
		self.main = getItemFromXml(mainItem)

		local minorItems = renlong:find('second')
		self.minor = { }
		for i = 1, #minorItems do
			minor = minorItems[i]
			table.insert(self.minor, getItemFromXml(minor))
		end

		local all = renlong:find('all')
		self.allItems = { }
		for i = 1, #all do
			table.insert(self.allItems, getItemFromXml(all[i]))
		end

		self.free = tonumber(renlong:find('left_free_count')[1])

		self:init_ui_ext()
	end
	sendRequest(urlpath, callback, 1)
end

function init_ui_ext(self)
	local function showItemInfo(sprCtrl, item)
		local nodeIcon = sprCtrl:getChildByTag(101)

		local _icon = nodeIcon:getChildByTag(99)
		if _icon then
			_icon:removeFromParentAndCleanup(true)
		end
		local sprite_icon, sprite_frame, quality = rl_get_iconsprite(item.type, item.subtype, E_FRAMETYPE_SMALL, item.icon)
		if sprite_icon ~= nil then
			if self.sprite_frame ~= nil then
				sprCtrl:setDisplayFrame(sprite_frame)
			else
				sprCtrl:setDisplayFrame(CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("small_box_skill_01"))
			end
			local iconsize = nodeIcon:getContentSize()
			sprite_icon:setPosition(iconsize.width / 2, 44)
			sprite_icon:setAnchorPoint(ccp(0.5, 0.5))
			nodeIcon:addChild(sprite_icon)
			sprite_icon:setScale(0.86)
			sprite_icon:setTag(99)
		end

		local sprType = sprCtrl:getChildByTag(100)
		if sprType then
			if item.type == 5 then
				sprType:setVisible(true)
			elseif item.type == 1 and item.subtype == 5 then
				sprType:setVisible(true)
			else
				sprType:setVisible(false)
			end
		end

	end

	showItemInfo(self.sprItemMain, self.main)
	for i = 1, 3 do
		showItemInfo(self.sprItemMinor[i], self.minor[i])
	end

	if self.free > 0 then
		-- 本次免费
		self.nodePriceOne:setVisible(false)
		self.labelFree:setVisible(true)
	else
		self.nodePriceOne:setVisible(true)
		self.labelFree:setVisible(false)
		self.labelCostOne:setString(self.cost[1])
	end

	self.labelCostTen:setString(self.cost[2])

end

function updateUI(self)
	-- self._tableView:reloadData()
	self:requestBaseInfo()
end


function init_binding_event(self)
	if self.proxy_ ~= nil then
		-- self.btnItemMain:setTouchPriority(kCCMenuHandlerPriority-1)
		self.proxy_:handleButtonEvent(self.btnItemMain, function(button, event)
			self:showDetail(self.main)
		end , CCControlEventTouchUpInside)

		local function onClickedMinor(i)
			self:showDetail(self.minor[i])
		end

		for i = 1, 3 do
			self.proxy_:handleButtonEvent(self.btnItemMinor[i], function(button, event)
				onClickedMinor(i)
			end , CCControlEventTouchUpInside)
		end

		self.proxy_:handleButtonEvent(self.btnOnce, function(button, event)
			self:hunt()
		end , CCControlEventTouchUpInside)

		self.proxy_:handleButtonEvent(self.btnTen, function(button, event)
			self:huntTen()
		end , CCControlEventTouchUpInside)

		self.proxy_:handleButtonEvent(self.btnPreview, function(button, event)
			showModelLayer(ui_hotTreasurePreview, self, self.allItems)
		end , CCControlEventTouchUpInside)

	end
end


function hunt(self)
	if self.state == 0 then
		GetMainMenu():ShowTextTip(localizable.ui_monopoly_end, -1)
		return
	end
	if self.free == 0 then
		local cost = self.cost[1]
		if self.playerData_.m_gold < cost then
			GetMainMenu():ShowTextTip(localizable.ui_monopoly_gold_not_enough, -1)
			local prePayLayer = createObj(ui_commonPrePay)
			GetMainMenu():GetModelLayer():AddDialog(prePayLayer.node_, 3)
			return
		end
	end

	-- 请求基本信息
	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 13, "rl_x_small_activity")
	local function callback(renlong)
		local cash = tonumber(renlong:find('cash')[1])
		self.playerMgr_:SetGold(cash)

		local freecount = renlong:find('left_free_count')
		if freecount then
			self.free = tonumber(freecount[1])
		else
			self.free = 0
		end

		if self.free > 0 then
			-- 本次免费
			self.nodePriceOne:setVisible(false)
			self.labelFree:setVisible(true)
		else
			self.nodePriceOne:setVisible(true)
			self.labelFree:setVisible(false)
			self.labelCostOne:setString(self.cost[1])
		end

		local awardXML = renlong:find("award")
		ShowAward(awardXML)
	end
	sendRequest(urlpath, callback, 1)
end

function huntTen(self)
	if self.state == 0 then
		GetMainMenu():ShowTextTip(localizable.ui_monopoly_end, -1)
		return
	end

	local cost = self.cost[2]
	if self.playerData_.m_gold < cost then
		GetMainMenu():ShowTextTip(localizable.ui_monopoly_gold_not_enough, -1)
		local prePayLayer = createObj(ui_commonPrePay)
		GetMainMenu():GetModelLayer():AddDialog(prePayLayer.node_, 3)
		return
	end

	-- 请求基本信息
	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 14, "rl_x_small_activity")
	local function callback(renlong)
		local cash = tonumber(renlong:find('cash')[1])
		self.playerMgr_:SetGold(cash)
		local awards = { }
		local awardlist = renlong:find('award_list')
		for i = 1, #awardlist do
			local award = awardlist[i]
			if award then
				AddSoulAwardData(award)
				-- 加入背包
				table.insert(awards, award.dropid)
				-- 记下dropid
			end
		end

		showModelLayer(ui_showAwards, self, awards)

	end
	sendRequest(urlpath, callback, 1)
end

function showDetail(self, item)
	if item.type == 5 then
		local descStr = item.desc
		-- CGameObjElement:ShowCommonItemDetail(tonumber(item.type), tonumber(item.subtype), tonumber(item.icon), descStr)
		local info = DataMgr.GetDataByID("Struct_Piece_Info", tonumber(item.icon))
		if info.m_piece_type == 1 then
			CGameObjElement:ShowCommonItemDetail(1, 1, tonumber(info.m_piece_targetthingID), descStr)
		elseif info.m_piece_type == 2 then
			CGameObjElement:ShowCommonItemDetail(1, 2, tonumber(info.m_piece_targetthingID), descStr)
		elseif info.m_piece_type == 3 then
			CGameObjElement:ShowCommonItemDetail(1, 3, tonumber(info.m_piece_targetthingID), descStr)
		elseif info.m_piece_type == 5 then
			-- 宠物碎片，显示宠物详情
			CGameObjElement:ShowCommonItemDetail(7, 5, tonumber(info.m_piece_targetthingID), descStr)
		end
	elseif item.type == 1 and item.subtype == 5 then
		local descStr = item.desc
		CGameObjElement:ShowCommonItemDetail(tonumber(item.type), tonumber(item.subtype), tonumber(item.icon), descStr)
	else
		local descStr = item.desc
		CGameObjElement:ShowCommonItemDetail(tonumber(item.type), tonumber(item.subtype), tonumber(item.icon), descStr)
	end
end
function onNodeCleanup(self)
	-- cclog("onNodeCleanup")
	if self.proxy_ then
		self.proxy_:release()
	end
	layer_base_t.onNodeCleanup(self)
end

function createTestData(self)
	-- testData
	return nil
end
