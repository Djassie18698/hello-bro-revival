----------------------------------------------------------------------
--  Copyright (c) 2014-2016, XCKOO. All Rights Reserved.
--  Author :Tango
--  Time   :2015/6/27 16:54:10
--  Remark :摇摇乐主界面
----------------------------------------------------------------------
module("ui_slotMachineLayer", package.seeall)
baseClass(layer_base_t, ui_slotMachineLayer)

require('ui_layer/ui_slotMachineAwardCell')
require('ui_layer/ui_slotMachineSlotCell')
require("ui_layer/ui_scratchGoldAnimation")

--深拷贝表，支持环形表
function table.deepcopy(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for index, value in pairs(object) do
            new_table[_copy(index)] = _copy(value)
        end
        return setmetatable(new_table, getmetatable(object))
    end
    return _copy(object)
end


function init(self)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	self.contentSize_ = GetMainMenu():GetSubContentNode():getContentSize()

	local ccbiAttrTable = { name = "activity/SlotMachineView.ccbi", size = self.contentSize_ }
	layer_base_t.init(self, true, ccbiAttrTable)

	self.slotSize = 130

	-- 活动状态(0开启、1结束)
	self.m_state = 0
	-- 时间增量
	self.deltatime = 0
	self.remain = 0
	-- my
	self.score = 0
	self.rate = 1
	self.betCost = 0
	self.cost = 0
	self.lastWin = 0

	self.isRolling = false
	self.result = { }

	self.awardXml = nil

	self.ninjas = { }
	self.slotNinja = { { }, { }, { } }
	-- 三个槽位里的图

	self.cellNodes = { }

	self._slotTable = { nil, nil, nil }
	self._slotTableHandler = { nil, nil, nil }

	self.lastRequestTime = 0

	self:init_ui()
	self:init_binding_event()
end


function init_ui(self)
	-- 初始化界面信息
	if self.proxy_ ~= nil then
		self.label_gold = tolua.cast(self.proxy_:getNode("label_gold"), "CCLabelBMFont")
		self.balelBetRate = tolua.cast(self.proxy_:getNode("label_bet_rate"), "CCLabelBMFont")
		self.labelTotalBet = tolua.cast(self.proxy_:getNode("label_total_bet"), "CCLabelBMFont")
		self.labelGoldWin = tolua.cast(self.proxy_:getNode("label_gold_win"), "CCLabelBMFont")
		self.labelScore = tolua.cast(self.proxy_:getNode("label_score"), "CCLabelBMFont")
		-- btn
		self.btn_back = tolua.cast(self.proxy_:getNode("btn_back"), "CCControlButton")
		self.btnTips = tolua.cast(self.proxy_:getNode("btn_detail"), "CCControlButton")
		self.btnBet = tolua.cast(self.proxy_:getNode("btn_bet"), "CCControlButton")
		self.btnExchange = tolua.cast(self.proxy_:getNode("btn_exchange"), "CCControlButton")
		self.btnSpin = tolua.cast(self.proxy_:getNode("btn_spin"), "CCControlButton")
		-- node
		self.nodeAwardContainer = tolua.cast(self.proxy_:getNode("node_awards_container"), "CCNode")
		self.nodeAwardCell = tolua.cast(self.proxy_:getNode("node_award_cell"), "CCNode")
		self.node_animWIn = tolua.cast(self.proxy_:getNode("node_animWIn"), "CCNode")

		--spr
		self.sprLight1 = tolua.cast(self.proxy_:getNode('spr_light1'),'CCSprite')
		self.sprLight2 = tolua.cast(self.proxy_:getNode('spr_light2'),'CCSprite')

		for i = 1, 3 do
			self['table_slot' .. i] = tolua.cast(self.proxy_:getNode('node_table_slot' .. i), "CCNode")
			self["cell_slot" .. i] = tolua.cast(self.proxy_:getNode("node_cell_slot" .. i), "CCNode")
		end

		self.label_gold:setString(tostring(self.playerData_.m_gold))

		self:requestBaseInfo()
	end
end

function requestBaseInfo(self)
	--- [[
	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 15, "rl_r_comm")
	GetMainMenu():ShowLoadingDlg()
	CCHttpRequest:open(urlpath, kHttpPost, "query=param1&other=params"):sendWithHandler(
	function(res, hnd)
		GetMainMenu():CloseLoadding();
		local resData = res:getResponseData()
		local code = res:getResponseCode()
		local xfile = xml.parse(resData)
		local item = xfile:find("RENLONG")
		if item == nil then
			-- cclog("CGI : rl_r_comm is down!")
			return nil
		end
		local retcode = item.code
		if retcode == "0" then
			local basic = item:find("basic")
			self.score = tonumber(basic:find('score')[1])
			self.betCost = tonumber(basic:find('bet_cost')[1])
			self.cost = tonumber(basic:find('cost')[1])
			self.rate = tonumber(basic:find('times')[1])
			self.remain = tonumber(basic:find('remain')[1])

			self.ninjas = item:find("ninjas")

			self:initExtra()
		else
			GetMainMenu():ShowTextTip(localizable.ui_monopoly_not_start, -1)
		end
	end )
end

function createAwardsTable(self)
	if self.ninjasTable == nil then
		local cellContentSize = self.nodeAwardCell:getContentSize()
		local cellSize = CCSizeMake(cellContentSize.width, cellContentSize.height)
		local contentSize = self.nodeAwardContainer:getContentSize()

		self:initAwardsTableHandle(cellSize)

		self.ninjasTable = LuaTableView:createWithHandler(self._awardTableHandler, contentSize)
		self.ninjasTable:setDirection(kCCScrollViewDirectionVertical)
		self.ninjasTable:setVerticalFillOrder(kCCTableViewFillTopDown)
		self.ninjasTable:setTouchPriority(kCCMenuHandlerPriority - 1)

		self.nodeAwardContainer:addChild(self.ninjasTable)
	else
		self.ninjasTable:reloadData()
	end
end

function initAwardsTableHandle(self, cellSize)
	self._awardTableHandler = LuaEventHandler:create( function(fn, table, a1, a2, x, y)
		local r
		if fn == "cellSize" then
			r = cellSize;
		elseif fn == "cellAtIndex" then
			local nodeLayer = createObj(ui_slotMachineAwardCell, cellSize, self.ninjas[a1 + 1])
			-- tableView cell container
			self.cellNodes[a1 + 1] = nodeLayer
			if not a2 then
				a2 = CCTableViewCell:create()
				a2:addChild(nodeLayer.node_)
			else
				a2:removeAllChildrenWithCleanup(true)
				a2:addChild(nodeLayer.node_)
			end
			r = a2
		elseif fn == "numberOfCells" then
			r = #self.ninjas
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

function createSlotTable(self)
	for i = 1, 3 do
		if self._slotTable[i] == nil then
			local cellContentSize = self["cell_slot" .. i]:getContentSize()
			local cellSize = CCSizeMake(cellContentSize.width, cellContentSize.height)
			local contentSize = self['table_slot' .. i]:getContentSize()

			self:initSlotTableHandle(i, cellSize)

			self._slotTable[i] = LuaTableView:createWithHandler(self._slotTableHandler[i], contentSize)
			self._slotTable[i]:setDirection(kCCScrollViewDirectionVertical)
			self._slotTable[i]:setVerticalFillOrder(kCCTableViewFillBottomUp)
			-- self._slotTable[i]:setTouchPriority(kCCMenuHandlerPriority - 1)
			self._slotTable[i]:setTouchEnabled(false)

			self['table_slot' .. i]:addChild(self._slotTable[i])
		else
			self._slotTable[i]:reloadData()
		end
	end
end

function initSlotTableHandle(self, i, cellSize)
	self._slotTableHandler[i] = LuaEventHandler:create( function(fn, table, a1, a2, x, y)
		local tableData = self.slotNinja[i]
		local r
		if fn == "cellSize" then
			r = cellSize;
		elseif fn == "cellAtIndex" then
			local nodeLayer = createObj(ui_slotMachineSlotCell, cellSize, tableData[a1 + 1])
			if not a2 then
				a2 = CCTableViewCell:create()
				a2:addChild(nodeLayer.node_)
			else
				a2:removeAllChildrenWithCleanup(true)
				a2:addChild(nodeLayer.node_)
			end
			r = a2
		elseif fn == "numberOfCells" then
			r = #tableData
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

function fillSlots(self)
	for j = 1, 3 do
		for i = 1, #self.ninjas do
			table.insert(self.slotNinja[1], self.ninjas[i])
		end
	end
	self._slotTable[1]:reloadData()
end

function initExtra(self)
	self.labelScore:setString(self.score)
	self.labelGoldWin:setString('0')
	self.balelBetRate:setString(self.rate)
	self.labelTotalBet:setString(self.betCost + self.cost)

	self:createAwardsTable()
	-- 初始化
	self.slotNinja = { table.deepcopy(self.ninjas), table.deepcopy(self.ninjas), table.deepcopy(self.ninjas) }

	self:createSlotTable()

	for i = 1, 3 do
		self._slotTable[i]:setContentOffset(0, 25 - self.slotSize)
	end

	SimpleAudioEngine:sharedEngine():playBackgroundMusic('sound/slot_bg.mp3')
	--SimpleAudioEngine:sharedEngine():playEffect('sound/slot_bg.mp3', false);

end
 
function updateUI(self)
	self.labelScore:setString(self.score)
	self.labelGoldWin:setString(self.lastWin)
	self.balelBetRate:setString(self.rate)
	self.labelTotalBet:setString(self.betCost + self.cost)

end


function requestBet(self)
	SimpleAudioEngine:sharedEngine():playEffect('sound/slot_bet.mp3')

	self.lastRequestTime = os.time()

	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 24, "rl_w_comm")
	GetMainMenu():ShowLoadingDlg()
	CCHttpRequest:open(urlpath, kHttpPost, "query=param1&other=params"):sendWithHandler(
	function(res, hnd)
		GetMainMenu():CloseLoadding();
		local resData = res:getResponseData()
		local code = res:getResponseCode()
		local xfile = xml.parse(resData)
		local item = xfile:find("RENLONG")
		if item == nil then
			-- cclog("CGI : rl_r_comm is down!")
			return nil
		end
		local retcode = item.code
		if retcode == "0" then
			self.rate = tonumber(item:find('times')[1])
			self.betCost = tonumber(item:find('bet_cost')[1])

			self:updateUI()
		elseif retcode == '600004' then
			GetMainMenu():ShowTextTip(localizable.ui_slotExchange_text6, -1)
		else
			GetMainMenu():ShowErrorTip(tonumber(retcode), -1)
		end
	end )
end


function requestSpin(self)
	SimpleAudioEngine:sharedEngine():stopBackgroundMusic()
	SimpleAudioEngine:sharedEngine():stopAllEffects();
	SimpleAudioEngine:sharedEngine():playEffect('sound/slot_spin.mp3')

	self.awardXML = nil
	self.lastRequestTime = os.time()

	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 23, "rl_w_comm")
	GetMainMenu():ShowLoadingDlg()
	CCHttpRequest:open(urlpath, kHttpPost, "query=param1&other=params"):sendWithHandler(
	function(res, hnd)
		GetMainMenu():CloseLoadding();
		local resData = res:getResponseData()
		local code = res:getResponseCode()
		local xfile = xml.parse(resData)
		local item = xfile:find("RENLONG")
		if item == nil then
			return nil
		end

		local retcode = item.code
		if retcode == "0" then
			self.playerMgr_:AddGold(- (self.betCost + self.cost))
			self.label_gold:setString(tostring(self.playerData_.m_gold))

			local basic = item:find('basic')
			self.score = tonumber(basic:find('score')[1])
			self.lastWin = tonumber(basic:find('cash')[1])
			self.rate = tonumber(basic:find('times')[1])
			self.betCost = tonumber(basic:find('bet_cost')[1])

			local slot = item:find('slot')
			self.result = { tonumber(slot:find('pos1')[1]), tonumber(slot:find('pos2')[1]), tonumber(slot:find('pos3')[1]) }
			self.awardXML = item:find('award')
 
			self:scrollToResult(self.result)

		elseif retcode == '600004' then
			GetMainMenu():ShowTextTip(localizable.ui_slotExchange_text6, -1)
		else
			GetMainMenu():ShowErrorTip(tonumber(retcode), -1)
		end
	end )
end

-- 控制请求的频率
function checkFrequency(self)
	local ret = true
	local now = os.time()
	if now - self.lastRequestTime < 2 then
		ret = false
	end

	return ret
end

function scrollToResult(self, result)
	for j = 1, 3 do
		self.slotNinja[j] = { }

		-- 填充几遍用来模拟转动
		for m = 1, 4+j do
			for i = 1, #self.ninjas do
				table.insert(self.slotNinja[j], self.ninjas[i])
			end
		end

		-- 依次添加至停转处
		for i = 1, result[j] do
			table.insert(self.slotNinja[j], self.ninjas[i])
		end

		-- 加上最后一个，其实只显示一个边
		local n = result[j] + 1
		if n > #self.ninjas then
			n = 1
		end
		table.insert(self.slotNinja[j], self.ninjas[n])

		-- 翻到底部
		self._slotTable[j]:reloadData()
		self._slotTable[j]:setContentOffset(0, 25 - self.slotSize)
	end

	local function onSlotStop()
		SimpleAudioEngine:sharedEngine():playEffect('sound/slot_bet.mp3')
	end

	for i = 1, 3 do
		local offset = - self.slotSize *(#self.slotNinja[i] -2) + 25
		local dura = 2 + i * 1
		self._slotTable[i]:setContentOffsetInDuration(ccp(0, offset), dura)

		performWithDelay(self.node_, onSlotStop, dura)
	end

	self.isRolling = true

	local onRollingEnd = function( )
		self:updateUI()

		self.sprLight1:removeAllChildrenWithCleanup(true)
		self.sprLight2:removeAllChildrenWithCleanup(true)
		if self.lastWin > 0 then
			self:playAnimWin()
			self:playAnimRolling(true)
			
			SimpleAudioEngine:sharedEngine():stopAllEffects();
			SimpleAudioEngine:sharedEngine():playEffect('sound/slot_win.mp3')
		else
			self.isRolling = false
		end
	end

	performWithDelay(self.node_, onRollingEnd, 5)

	self:playAnimRolling()
end


function init_binding_event(self) 
	if self.proxy_ ~= nil then
		local function onbtnSpin(btn)
			if self.remain <= 0 then
				GetMainMenu():ShowTextTip(localizable.ui_slotExchange_text6, -1)
				return nil
			end

			if self.isRolling then return nil end

			if self.playerData_.m_gold < self.betCost + self.cost then
				-- 提示购买元宝
				GetMainMenu():ShowTextTip(localizable.ui_monopoly_gold_not_enough, -1)
				-- 通用付费引导
				local prePayLayer = createObj(ui_commonPrePay)
				GetMainMenu():GetModelLayer():AddDialog(prePayLayer.node_, 3)
				return nil
			end

			self:requestSpin()
			-- if not self:checkFrequency() then
			-- 	return
			-- end
			-- self.lastRequestTime = os.time()
		end

		local function onBtnBet(btn)
			if self.remain <= 0 then
				GetMainMenu():ShowTextTip(localizable.ui_slotExchange_text6, -1)
				return nil
			end

			if self.isRolling then return end
			self:requestBet()
		end

		self.proxy_:handleButtonEvent(self.btnSpin, function(button, event)
			onbtnSpin(button)
			return nil
		end , CCControlEventTouchUpInside)

		self.proxy_:handleButtonEvent(self.btn_back, function(button, event)
			if self.isRolling then return end

			GetMainMenu():ChangeToSub(E_DEFAULTMENU)
			return nil
		end , CCControlEventTouchDown)

		self.proxy_:handleButtonEvent(self.btnBet, function(button, event)
			onBtnBet(button)
			return nil
		end , CCControlEventTouchUpInside)

		self.proxy_:handleButtonEvent(self.btnTips, function(button, event)
			require("ui_layer/ui_slotMachineTips")
			showModelLayer(ui_slotMachineTips)
			return nil
		end , CCControlEventTouchUpInside)

		self.proxy_:handleButtonEvent(self.btnExchange, function(button, event)
			if self.isRolling == false then
				require("ui_layer/ui_slotMExchangeLayer")
				showModelLayer(ui_slotMExchangeLayer,self.node_)
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

function playAnimWin( self )
	local cache = CCSpriteFrameCache:sharedSpriteFrameCache()  
    cache:addSpriteFramesWithFile('ccbResources/anim_win.plist')

    local array = CCArray:create()  
    for i=0,8 do 
        local name = "zj2_0000" .. i 
        local frame = cache:spriteFrameByName(name)
		if frame ~= nil then
			array:addObject(frame)  
		end
	end  
	local animation = CCAnimation:createWithSpriteFrames(array,0.13)  
    local animate = CCAnimate:create(animation)

	local animSprite = CCSprite:create()
	self.node_animWIn:addChild(animSprite)


	local function callback()
		animSprite:removeFromParentAndCleanup(true)
		self:showWinGold(self.lastWin)

		self.playerMgr_:AddGold(self.lastWin)
		self.label_gold:setString(tostring(self.playerData_.m_gold))
		self.isRolling = false
	end

	local action = CCSequence:createWithTwoActions(animate,CCCallFunc:create(function() callback() end))
	animSprite:runAction(action)

	--
	local scale = CCScaleBy:create(0.2,5)
	local array = CCArray:create()
	array:addObject(scale)
	array:addObject(scale:reverse())
	self.labelGoldWin:runAction(CCSequence:create(array))
end

--完成以后，如果获得奖励，将播放动画
function showWinGold(self, gold)
	local win = CCDirector:sharedDirector():getWinSize()
    local finishLayer = createObj(ui_scratchGoldAnimation, gold)
	finishLayer.node_:setAnchorPoint(ccp(0.5, 0.5))
	finishLayer.node_:setPosition(win.width / 2, win.height / 2)
	finishLayer.node_:ignoreAnchorPointForPosition(false)
	finishLayer.node_:setTouchEnabled(true)
	local function stopAnimation()
		if self.disappear ~= nil then
		 	CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.disappear)
         	self.disappear = nil
         	--ui_scratchCardLayer.pressTag = nil
         	finishLayer.node_:removeFromParentAndCleanup(true)
		end
	end
	finishLayer.node_:registerScriptTouchHandler(stopAnimation,false,kCCMenuHandlerPriority-1,true)
	finishLayer.node_:setTouchMode(0)

	local function animationFinished()
		if self.disappear ~= nil then
		 	CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.disappear)
         	self.disappear = nil
         	--ui_scratchCardLayer.pressTag = nil
         	finishLayer.node_:removeFromParentAndCleanup(true)
		end
	end
	self.disappear = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(animationFinished, 4, false)
	GetMainMenu():GetModelLayer():addChild(finishLayer.node_)
end

function playAnimRolling( self, isWin)
	local cache = CCSpriteFrameCache:sharedSpriteFrameCache()  
    cache:addSpriteFramesWithFile('ccbResources/anim_rolling.plist')

    local namePre = 'rolling_0000'
    if isWin then
    	namePre = 'rolling_win_0000'
    end

    local array = CCArray:create()
    for i=0,6 do 
        local name = namePre .. i 
        local frame = cache:spriteFrameByName(name)
		if frame ~= nil then
			array:addObject(frame)  
		end
	end  

	local animation = CCAnimation:createWithSpriteFrames(array,0.13)  
    local animate = CCAnimate:create(animation)

    local animSprite = CCSprite:create()
	self.sprLight1:addChild(animSprite)
	animSprite:setAnchorPoint(ccp(0,0))
	animSprite:setPosition(ccp(10,195))
	animSprite:runAction(CCRepeatForever:create(animate))


	local animation2 = CCAnimation:createWithSpriteFrames(array,0.13)  
    local animate2 = CCAnimate:create(animation2)

	local animSprite2 = CCSprite:create()
	self.sprLight2:addChild(animSprite2)
	animSprite2:setFlipX(true)
	animSprite2:setAnchorPoint(ccp(0,0))
	animSprite2:setPosition(ccp(278,195))
	animSprite2:runAction(CCRepeatForever:create(animate2))

end