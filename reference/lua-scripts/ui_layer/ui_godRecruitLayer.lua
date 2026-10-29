----------------------------------------------------------------------
--  Copyright (c) 2014-2016, XCKOO. All Rights Reserved.
--  Author :Tango
--  Time   :2015-12-21 17:25:00
--  Remark :神卡招募
----------------------------------------------------------------------
module("ui_godRecruitLayer", package.seeall)
baseClass(layer_base_t, ui_godRecruitLayer)

require('ui_layer/ui_godRecruitAwardCell')
require('ui_layer/ui_godRecruitSlotCell')
require("ui_layer/ui_scratchGoldAnimation")
require('ui_layer/ui_godRecruitExchangeLayer')

local lampNum = 37

function init(self)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	self.contentSize_ = GetActivityView():GetNodeContent():getContentSize()

	local ccbiAttrTable = { name = "activity/GodRecruitView.ccbi", size = self.contentSize_ }
	layer_base_t.init(self, true, ccbiAttrTable)

	self.slotSize = 186

	-- 活动状态(0开启、1结束)
	self.m_state = 0
	-- 时间增量
	self.deltatime = 0
	self.remain = 0
	-- my
	self.score = 0
	self.price = {old = 0, now = 0}

	self.laseWinId = 0

	self.isRolling = false
	self.result = { }

	self.ninjas = { }
	self.slotNinja = { }

	self.ninjasForExchange = {}

	self.cellNodes = { }

	self._slotTable = nil
	self._slotTableHandler = nil

	self:init_ui()
	self:init_binding_event()
end


function init_ui(self)
	-- 初始化界面信息
	if self.proxy_ ~= nil then
		self.labelTime = getLabelTTFFromCCB(self.proxy_, 'label_time')
		self.labelOldPrice = tolua.cast(self.proxy_:getNode("label_oldPrice"), "CCLabelTTF")
		self.labelNowPrice = tolua.cast(self.proxy_:getNode("label_nowPrice"), "CCLabelBMFont")
		self.labelScore = tolua.cast(self.proxy_:getNode("label_score"), "CCLabelTTF")
		-- btn
		self.btn_back = tolua.cast(self.proxy_:getNode("btn_back"), "CCControlButton")
		self.btnTips = tolua.cast(self.proxy_:getNode("btn_detail"), "CCControlButton")
		self.btnPreview = tolua.cast(self.proxy_:getNode("btn_preview"), "CCControlButton")
		self.btnExchange = tolua.cast(self.proxy_:getNode("btn_exchange"), "CCControlButton")
		self.btnRecruit = tolua.cast(self.proxy_:getNode("btn_recruit"), "CCControlButton")


		self.node_animWIn = tolua.cast(self.proxy_:getNode("node_animWIn"), "CCNode")

		self.tableSlot = tolua.cast(self.proxy_:getNode('node_table_slot'), "CCNode")
		self.tableCell = tolua.cast(self.proxy_:getNode("node_cell_slot"), "CCNode")

		self.lamps = { }
		for i = 1, lampNum do
			table.insert(self.lamps, getSpriteFromCCB(self.proxy_, 'spr_lamp' .. i))
		end

		self:requestBaseInfo()

		self.maskLayer = CCLayer:create()
		self.node_:addChild(self.maskLayer)
	end
end

function requestBaseInfo(self)
	local function updateLeftTimeLabel(fDeltaTime)
		self.deltatime = self.deltatime + fDeltaTime
		if self.deltatime >= 1 then
			local intPart, floatPart = math.modf(self.deltatime)
			self.remain = self.remain - intPart
			if self.remain > 0 then
				local timeStr = tools.convertTimeElectronicWatch(self.remain, 3)
				self.labelTime:setString(localizable.ui_timeleft ..  timeStr)
				self.deltatime = floatPart
			else
				self.m_state = 1
				self.labelTime:unscheduleUpdate()
				self.labelTime:setString(localizable.ui_timeleft .. localizable.ui_border_end)
			end
		end
	end

	local function baseinfoCallback( renlong )
		local basic = renlong:find('basic')
		self.remain = tonumber(basic:find('left_time')[1]) 
		self.score = tonumber(basic:find('score')[1]) 
		self.laseWinId = tonumber(basic:find('super_id')[1]) 
		self.price = {old = tonumber(basic:find('oldCash')[1]), now = tonumber(basic:find('newCash')[1])}

		self.ninjas = renlong:find('card_info_list')
		self:getNinjasForExchange(self.ninjas)

		-- 实时更新活动时间
		if self.remain > 0 then
			self.labelTime:scheduleUpdateWithPriorityLua(updateLeftTimeLabel, 0)
			self.labelTime:setString(localizable.ui_timeleft .. tools.convertTimeElectronicWatch(self.remain, 3))
		else
			self.labelTime:setString(localizable.ui_timeleft .. localizable.ui_border_end)
		end

		self:initExtra()
	end

	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 17, "rl_x_small_activity")
	sendRequest(urlpath, baseinfoCallback)
end

function createSlotTable(self)
	if self._slotTable == nil then
		local cellContentSize = self.tableCell:getContentSize()
		local cellSize = CCSizeMake(cellContentSize.width, cellContentSize.height)
		local contentSize = self.tableSlot:getContentSize()

		self:initSlotTableHandle(cellSize)

		self._slotTable = LuaTableView:createWithHandler(self._slotTableHandler, contentSize)
		self._slotTable:setDirection(kCCScrollViewDirectionHorizontal)
		self._slotTable:setVerticalFillOrder(kCCTableViewFillTopDown)
		self._slotTable:setTouchEnabled(false)

		self.tableSlot:addChild(self._slotTable)
	else
		self._slotTable:reloadData()
	end
end

function initSlotTableHandle(self, cellSize)
	self._slotTableHandler = LuaEventHandler:create( function(fn, table, a1, a2, x, y)
		local r
		if fn == "cellSize" then
			r = cellSize;
		elseif fn == "cellAtIndex" then
			local nodeLayer = createObj(ui_godRecruitSlotCell, cellSize, self.slotNinja[a1 + 1])
			if not a2 then
				a2 = CCTableViewCell:create()
				a2:addChild(nodeLayer.node_)
			else
				a2:removeAllChildrenWithCleanup(true)
				a2:addChild(nodeLayer.node_)
			end
			r = a2
		elseif fn == "numberOfCells" then
			r = #self.slotNinja
			-- Cell events:
		elseif fn == "cellTouched" then
		elseif fn == "cellTouchBegan" then
			r = true
		elseif fn == "cellTouchEnded" then
			-- A cell was touched, a1 is cell, a2 is CCTouch
			r = true
		elseif fn == "cellHighlight" then
			-- A cell is highlighting, coco2d-x 2.1.3 or above
		elseif fn == "cellUnhighlight" then
			-- A cell had been unhighlighted, coco2d-x 2.1.3 or above
		elseif fn == "cellWillRecycle" then
			-- A cell will be recycled, coco2d-x 2.1.3 or above
		end
		return r
	end )
end

function initExtra(self)
	getLabelTTFFromCCB(self.proxy_, 'label_unuse2'):setString(localizable.ui_godRecruit_nowPrice)

	self.labelScore:setString(localizable.ui_godRecruit_score ..  self.score)
	self.labelOldPrice:setString(localizable.ui_godRecruit_oldPrice .. self.price.old)
	self.labelNowPrice:setString(self.price.now)

	-- 初始化
	self.slotNinja = table.deepcopy(self.ninjas)
	self:createSlotTable()
	self._slotTable:setContentOffset(0, 0)
end
 
function updateUI(self)
	self:setScore( self.score)
end

function setScore( self, score )
	self.score = score
	self.labelScore:setString(localizable.ui_godRecruit_score ..score)
end

function requestSpin(self)
	local function spinCallback( renlong)
		self.result = tonumber(renlong:find('id')[1])
		local cost = tonumber(renlong:find('castCash')[1])
		self.playerMgr_:AddGold(-cost)

		self:scrollToResult(self.result)
	end

	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 18, "rl_x_small_activity")
	sendRequest(urlpath, spinCallback, 1)
end


function scrollToResult(self, result)
	self.slotNinja = { }

	-- 填充几遍用来模拟转动
	for m = 1, 2  do
		for i = 1, #self.ninjas do
			table.insert(self.slotNinja, self.ninjas[i])
		end
	end

	-- 依次添加至停转处
	for i = 1, result do
		table.insert(self.slotNinja, self.ninjas[i])
	end

	-- 加上最后一个，抽中的放中间
	local n = result + 1
	if n > #self.ninjas then
		n = 1
	end
	table.insert(self.slotNinja, self.ninjas[n])

	-- 翻到底部
	self._slotTable:reloadData()
	self._slotTable:setContentOffset(0,0)


	local function onSlotStop()
		SimpleAudioEngine:sharedEngine():playEffect('sound/slot_bet.mp3')
	end

	local offset = - self.slotSize *(#self.slotNinja - 3)
	local dura = 4
	self._slotTable:setContentOffsetInDuration(ccp(offset, 0), dura)

	performWithDelay(self.node_, onSlotStop, dura)

	self.isRolling = true

	local onRollingEnd = function()
		self:updateUI()

		self:showWinLayer(result)
		--self:playAnimRolling(true)

		self.isRolling = false
	end

	performWithDelay(self.node_, onRollingEnd, dura+0.5)

	self:playAnimRolling()
end


function init_binding_event(self)
	if self.proxy_ ~= nil then
		local function CCLayerTouch(event, x, y)
			if event == "began" then
				if self.isRolling == true then
					return true
				end
			end
		end

		self.maskLayer:setTouchEnabled(true)
		self.maskLayer:registerScriptTouchHandler(CCLayerTouch, false, kCCMenuHandlerPriority-1, true)


		local function onbtnSpin(btn)

			if self.remain <= 0 then
				GetMainMenu():ShowTextTip(localizable.ui_monopoly_end, -1)
				return nil
			end

			if self.isRolling then return nil end

			if self.playerData_.m_gold < self.price.now then
				-- 提示购买元宝
				GetMainMenu():ShowTextTip(localizable.ui_monopoly_gold_not_enough, -1)
				-- 通用付费引导
				local prePayLayer = createObj(ui_commonPrePay)
				GetMainMenu():GetModelLayer():AddDialog(prePayLayer.node_, 3)
				return nil
			end

			local dlg = CommonDialogView.create()
			CommonDialogView.m_selfview = dlg
			dlg:SetTitle(localizable.ui_godRecruit_SpinConfirmTitle)
			dlg:SetDescription(string.format(localizable.ui_godRecruit_SpinConfirmText, self.price.now) )
			dlg:loadCCBI()
			dlg:initUI()
			dlg:SetConfirmHandler(function()
				self:requestSpin()
			end)
			GetMainMenu():GetModelLayer():AddDialog(dlg, 3)

			
		end

		local function onBtnPreview(btn)
			if self.isRolling then return end
			require("ui_layer/ui_godRecruitPreviewLayer")
			showModelLayer(ui_godRecruitPreviewLayer, self, self.ninjas)
		end

		self.proxy_:handleButtonEvent(self.btnRecruit, function(button, event)
			--self:testWin()
			onbtnSpin(button)
			return nil
		end , CCControlEventTouchUpInside)

		self.proxy_:handleButtonEvent(self.btn_back, function(button, event)
			if self.isRolling then return end

			GetMainMenu():ChangeToSub(E_DEFAULTMENU)
			return nil
		end , CCControlEventTouchDown)

		self.proxy_:handleButtonEvent(self.btnPreview, function(button, event)
			onBtnPreview(button)
			return nil
		end , CCControlEventTouchUpInside)

		self.proxy_:handleButtonEvent(self.btnTips, function(button, event)
			showTipsDialog(localizable.ui_godRecruit_tips)
		end , CCControlEventTouchUpInside)

		self.proxy_:handleButtonEvent(self.btnExchange, function(button, event)
			if self.isRolling == false then
				require("ui_layer/ui_godRecruitExchangeLayer")
				showModelLayer(ui_godRecruitExchangeLayer, self, self.ninjasForExchange)
			end
		end , CCControlEventTouchUpInside)

	end
end



function onNodeCleanup(self)
	if self.proxy_ then
		self.proxy_:release()
	end
	layer_base_t.onNodeCleanup(self)

	SimpleAudioEngine:sharedEngine():stopAllEffects()
	SimpleAudioEngine:sharedEngine():playBackgroundMusic('soung/beijingmain.mp3');

end

function showWinLayer(self, result)
	require('ui_layer/ui_godRecruitWinLayer')
	showModelLayer(ui_godRecruitWinLayer,self, self.ninjas[result])
end

function playAnimRolling(self, isWin)
	for i, lamp in ipairs(self.lamps) do
		local blink = CCBlink:create(4, 15)
		--lamp:runAction(blink)
		local delay = CCDelayTime:create(0.03*i)
		local seq = CCSequence:createWithTwoActions(delay, blink)
		lamp:runAction(seq)
	end

end

function getNinjasForExchange( self, ninjas )
	self.ninjasForExchange = {}
	for i=1,#ninjas do
		local need = tonumber(ninjas[i].card_exchange_point)
		if need > 0 then
			table.insert(self.ninjasForExchange, ninjas[i])
		end
	end
end

function testWin(self)
	self:showWinLayer(2)
	self:playAnimRolling(true)

	self.isRolling = false
end
