----------------------------------------------------------------------
--  Copyright (c) 2014-2016, XCKOO. All Rights Reserved.
--  Author :zhangwy
--  Time   :2015-12-07 
--  Remark :突破
----------------------------------------------------------------------


module("ui_tupoLayer", package.seeall)
baseClass(layer_base_t, ui_tupoLayer)

Instance = nil
SelectedCard = 0

function init(self)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	self.contentSize_ = GetMainMenu():GetSubContentNode():getContentSize()
	local ccbiAttrTable = { name = "sub_ui/Tupo.ccbi", size = self.contentSize_ }
	layer_base_t.init(self, true, ccbiAttrTable)

	ui_tupoLayer.Instance = self
	ui_tupoLayer.SelectedCard = 0

	self.cost_piece_num = 0
	self.cost_sliver_num = 0
	self.has_piece_num = 0
	self.current_tupo_level = 0
	self.max_tupo_level = 0
	self.cost_chip_id = 0

	self.base_add_attact=0
	self.base_add_defense=0
	self.base_add_chakra=0

	self.tupo_begin = {}
	self.tupo_end = {}
	for i=1,5 do
		self.tupo_begin[i] = '0'
	end

	for i=1,5 do
		self.tupo_end[i] = '0'
	end

	-- init
	self:init_ui()
	self:init_binding_event()

	self:clearShowTupoInfo()
end

function clearShowTupoInfo( self )
	-- body
	---[[
    -- test
    self.select_card:setVisible(true)
    self.label_tupo_cost:setString("0")
    self.label_tupo_cost_piece:setString("0/0")

    self.card_name_1:setString("")
    self.card_name_2:setString("")
    self.spr_add_01:setVisible(false)
    self.spr_add_02:setVisible(false)

    self.tupo_begin_level:setString("0")
    self.tupo_begin_level:setVisible(false)
    self.tupo_end_level:setString("0")
    self.tupo_end_level:setVisible(false)

    for i=1,5 do
    	self["card_attr_start_0"..tostring(i)]:setString(tostring(0))

    	self["card_attr_end_0"..tostring(i)]:setString(tostring(0))
    end
    --]]
end

--同步卡的突破等级
function SyncTupoLevel( self, guid, level )
	-- 与C++代码同步 碎片数量 突破等级
	local pNinjaInfo = tolua.cast(CPlayerDataMgr:instance():GetObjectByID(guid), "CPlayerNinja")
	if pNinjaInfo ~= nil then
		pNinjaInfo:SetTupoLevel(level)

		pNinjaInfo:setTupoAttrAdd(self.base_add_attact, self.base_add_defense, self.base_add_chakra)
	end
end

function refreshData(self)
    -- 突破请求后的信息刷新

    if ui_tupoLayer.SelectedCard ~= 0 then
    	--攻击等属性加成
    	for i=1,5 do
    		self["card_attr_start_0"..tostring(i)]:setString(self.tupo_begin[i])

    		self["card_attr_end_0"..tostring(i)]:setString(self.tupo_end[i])
    	end
    	
    	self.spr_piece_icon:removeAllChildrenWithCleanup(true)

    	--突破等级
    	if self.current_tupo_level ~= 0 then
    		self.tupo_begin_level:setString(tostring(self.current_tupo_level))
    		self.tupo_begin_level:setVisible(true)
    		self.spr_add_01:setVisible(true)

    	else
    		self.spr_add_01:setVisible(false)
    		self.tupo_begin_level:setVisible(false)
    	end

    	if (self.current_tupo_level+1)>self.max_tupo_level then
    		self.tupo_end_level:setVisible(false)
    		self.spr_add_02:setVisible(false)

    		self.label_tupo_cost:setString("0")
    		self.label_tupo_cost_piece:setString("0/0")

    		self.card_name_2:setVisible(false)
    	else
    		self.tupo_end_level:setString(tostring(self.current_tupo_level+1))
    		self.tupo_end_level:setVisible(true)
    		self.spr_add_02:setVisible(true)

    		--消耗碎片数量和银两数量
    		self.label_tupo_cost:setString(tostring(self.cost_sliver_num))
    		self.label_tupo_cost_piece:setString(tostring(self.has_piece_num)..'/'..tostring(self.cost_piece_num))
    		
    		local ninja = CPlayerDataMgr:instance():GetObjectByID(ui_tupoLayer.SelectedCard)
			local pNinjaFrame = CGameObjElement:GetItemFrame(0,ninja:GetQuality())

			local ninjaData = DataMgr.GetDataByID("Struct_Ninjainfo", tonumber(ninja:GetDataID()))
			local pNinjaIcon=CCSprite:createWithSpriteFrame(ninja:GetCardIcon(0))

			--碎片图标
			self.spr_piece_icon:setDisplayFrame(pNinjaFrame)
			---[[
			local size_icon = self.spr_piece_icon:getContentSize()
			pNinjaIcon:setPosition(size_icon.width/2,size_icon.height/2)
			pNinjaIcon:setAnchorPoint(ccp(0.5,0.5))
			pNinjaIcon:setScale(0.9)
			self.spr_piece_icon:addChild(pNinjaIcon)
			--]]
			self.card_name_2:setVisible(true)
			self.card_name_2:setString(ninjaData.m_ninjaname)

    	end
    	  	    
    	self.select_card:setVisible(false)
    end
  
end

function updateTupoNinja( self , guid )
	-- body
	if guid~=0 then

		ui_tupoLayer.SelectedCard = guid
		-- 选择的神卡icon展示
		self.spr_tupo_icon_01:removeAllChildrenWithCleanup(true)
		self.spr_tupo_icon_02:removeAllChildrenWithCleanup(true)

		local ninja = CPlayerDataMgr:instance():GetObjectByID(guid)
		local pNinjaFrame = ninja:GetCardFrame(1)
		local pNinjaIcon01=CCSprite:createWithSpriteFrame(ninja:GetCardIcon(1))
		local pNinjaIcon02=CCSprite:createWithSpriteFrame(ninja:GetCardIcon(1))	

		self.spr_tupo_frame_01:setDisplayFrame(pNinjaFrame)
		self.spr_tupo_icon_01:setDisplayFrame(pNinjaFrame)
		self.spr_tupo_frame_02:setDisplayFrame(pNinjaFrame)
		self.spr_tupo_icon_02:setDisplayFrame(pNinjaFrame)

		local size_icon = self.spr_tupo_icon_01:getContentSize()
		pNinjaIcon01:setScale(0.5)
		pNinjaIcon02:setScale(0.5)
		pNinjaIcon01:setPosition(size_icon.width/2,size_icon.height/2)
		pNinjaIcon01:setAnchorPoint(ccp(0.5,0.5))
		pNinjaIcon02:setPosition(size_icon.width/2,size_icon.height/2)
		pNinjaIcon02:setAnchorPoint(ccp(0.5,0.5))
		self.spr_tupo_icon_01:addChild(pNinjaIcon01)
		self.spr_tupo_icon_02:addChild(pNinjaIcon02)
		
		--卡牌名称
		local ninjaData = DataMgr.GetDataByID("Struct_Ninjainfo", tonumber(ninja:GetDataID()))
		self.card_name_1:setString(ninjaData.m_ninjaname)

		-- 请求突破信息
		self:requestTupoInfo(ui_tupoLayer.SelectedCard, 1)
	end
end

function init_ui(self)
	if self.proxy_ ~= nil then

		--self.container = tolua.cast(self.proxy_:getNode("node_container"), "CCNode")

		--文字部分
		self.select_card = tolua.cast(self.proxy_:getNode("label_select_card"), "CCLabelTTF")
		self.label_tupo_cost = tolua.cast(self.proxy_:getNode("label_cost_sliver"), "CCLabelTTF")
		self.label_tupo_cost_piece = tolua.cast(self.proxy_:getNode("label_tupo_cost_piece"), "CCLabelTTF")

		self.card_name_1 = tolua.cast(self.proxy_:getNode("label_card_name_01"), "CCLabelTTF")
		self.card_name_2 = tolua.cast(self.proxy_:getNode("label_card_name_02"), "CCLabelTTF")

		self.tupo_begin_level = tolua.cast(self.proxy_:getNode("label_tupo_start_level"), "CCLabelBMFont")
		self.tupo_end_level = tolua.cast(self.proxy_:getNode("label_tupo_end_level"), "CCLabelBMFont")
		self.spr_add_01 = tolua.cast(self.proxy_:getNode("spr_add_01"), "CCLabelBMFont")
		self.spr_add_02 = tolua.cast(self.proxy_:getNode("spr_add_02"), "CCLabelBMFont")

		for i=1,5 do
			self["card_attr_start_0"..tostring(i)] = tolua.cast(self.proxy_:getNode("card_attr_start_0" .. tostring(i)), "CCLabelTTF")
		end
		for i=1,5 do
			self["card_attr_end_0"..tostring(i)] = tolua.cast(self.proxy_:getNode("card_attr_end_0" .. tostring(i)), "CCLabelTTF")
		end

		--sprite
		self.spr_tupo_frame_01 = tolua.cast(self.proxy_:getNode("spr_tupo_frame_01"), "CCSprite")
		self.spr_tupo_icon_01 = tolua.cast(self.proxy_:getNode("spr_tupo_icon_01"), "CCSprite")
		self.spr_tupo_frame_02 = tolua.cast(self.proxy_:getNode("spr_tupo_frame_02"), "CCSprite")
		self.spr_tupo_icon_02 = tolua.cast(self.proxy_:getNode("spr_tupo_icon_02"), "CCSprite")

		self.spr_piece_icon = tolua.cast(self.proxy_:getNode("spr_tupo_icon"), "CCSprite")

		--按钮
		self.button_back = tolua.cast(self.proxy_:getNode("btn_back"), "CCControlButton")
		self.button_detail = tolua.cast(self.proxy_:getNode("btn_detail"), "CCControlButton")		
		self.button_start_tupo = tolua.cast(self.proxy_:getNode("btn_tupo"), "CCControlButton")
		self.button_select = tolua.cast(self.proxy_:getNode("btn_select"), "CCControlButton")
	
		--
		self.node_tupo = tolua.cast(self.proxy_:getNode("node_tupo_ani"), "CCNode")
	end
end

--解析一个忍者的突破信息
function ParseNinjaTupoInfo( self, item )
	-- 消耗
	if item:find("max_break_level") ~= nil then
		self.max_tupo_level = tonumber(item:find("max_break_level")[1])
	end

	self.cost_piece_num = tonumber(item:find("need_chip_num")[1])
	self.cost_sliver_num = tonumber(item:find("cost_coin")[1])
	self.has_piece_num = tonumber(item:find("chip_num")[1])
	self.current_tupo_level = tonumber(item:find("break_level")[1])	
	local piece_id = tonumber(item:find("chip_id")[1])
	self.cost_chip_id = piece_id

	--突破前属性
	local tupo_attr_begin = item:find("attr_before")
	self.tupo_begin[1] = tostring(tupo_attr_begin:find("add_attack")[1])
	self.tupo_begin[2] = tostring(tupo_attr_begin:find("add_defense")[1])
	self.tupo_begin[3] = tostring(tupo_attr_begin:find("add_chakela")[1])
	self.tupo_begin[4] = tostring(tupo_attr_begin:find("add_skill")[1])..'%'
	self.tupo_begin[5] = tostring(tupo_attr_begin:find("add_kezhi")[1])..'%'
	--突破后属性
	local tupo_attr_end = item:find("attr_after")
	self.tupo_end[1] = tostring(tupo_attr_end:find("add_attack")[1])
	self.tupo_end[2] = tostring(tupo_attr_end:find("add_defense")[1])
	self.tupo_end[3] = tostring(tupo_attr_end:find("add_chakela")[1])
	self.tupo_end[4] = tostring(tupo_attr_end:find("add_skill")[1])..'%'
	self.tupo_end[5] = tostring(tupo_attr_end:find("add_kezhi")[1])..'%'

	--突破增加的基础攻击力
	if item:find("add_attack") ~= nil then
		self.base_add_attact = tonumber(item:find("add_attack")[1])
	end
	if item:find("add_defense") ~= nil then
		self.base_add_defense = tonumber(item:find("add_defense")[1])
	end
	if item:find("add_chakela") ~= nil then
		self.base_add_chakra = tonumber(item:find("add_chakela")[1])
	end
end

function requestTupoInfo(self, bagId, cmd)
	--cclog("20151209 tupo request")
	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, cmd, "rl_x_breakthrough")
	urlpath = AddData(urlpath, "BagIndex", bagId)
	cclog("rl_r_group_comm & cmd = 9---%s", urlpath)
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
			--cclog("20151209 tupo_01 = %s", resData)
			local retcode = item.code
			if retcode == "0" then
				-- 获取神卡的突破信息
				self:ParseNinjaTupoInfo(item)
				self:refreshData()
				if cmd==2 then
					self:playAnimation(true)

					self:SyncTupoLevel(bagId, self.current_tupo_level)
					self.playerMgr_:updatePieceNum(self.cost_chip_id, 6, self.has_piece_num)

					GetMainMenu():SetNinjalistNeedtoReLoad(true)
				end

			else
				GetMainMenu():ShowErrorTip(tonumber(retcode),-1)

                if tonumber(recode) == 329019 then
                   ShowCommonBuyItemDialog(kConsumableTypeItem, SMALL_COIN_ITEM_ID, BIG_COIN_ITEM_ID, 0)
                end
			end
		end)
end


--播放动画
function playAnimation(self, istraining)
	if istraining == true then
		local rotatenode = createObj(ui_tupoAnimation, "Tupo_ef", self.node_tupo:getContentSize(), istraining)
		self.node_tupo:removeAllChildrenWithCleanup(true)
		self.node_tupo:setVisible(true)
		local function animationFinished()
			if self.disappear ~= nil then
			 	CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.disappear)
			 	self.disappear = nil
			 	self.node_tupo:removeAllChildrenWithCleanup(true)

				self:playAnimation(false)
			end
		end
		self.disappear = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(animationFinished, 2, false)
		self.node_tupo:addChild(rotatenode.bglayer)
		self.node_tupo:addChild(rotatenode.node_)
	elseif istraining == false then
		self.node_tupo:removeAllChildrenWithCleanup(true)
	end
end

function init_binding_event(self)
	if self.proxy_ ~= nil then
		local function CCLayerTouch(event, x, y)
            local rect = self.node_:boundingBox()
            rect.origin = ccp(0, 0)
            local p = self.node_:convertToNodeSpace(ccp(x, y))
            if event == "began" then
                if rect:containsPoint(p) == true then
                    return true
                else
                    return false
                end
            end
        end

		self.node_:setTouchEnabled(true)
		self.node_:registerScriptTouchHandler(CCLayerTouch, false, kCCMenuHandlerPriority - 1, true)
	
		local function onBtnBack(btn)
            -- back
            self.node_:removeFromParentAndCleanup(true)
            --cclog("20151208---btn back")
        end

        local function onBtnDetail(btn)
            -- detail
            --cclog("20151208---btn Detail")
            local tupoLayer = createObj(ui_tupoDesc)
            local size1 = GetMainMenu():GetModelLayer():getContentSize()
            tupoLayer.node_:setAnchorPoint(ccp(0.5, 0.5))
            tupoLayer.node_:setPosition(size1.width / 2, size1.height / 2)
            GetMainMenu():GetModelLayer():addChild(tupoLayer.node_)
        end

        local function onBtnStartTupo(btn)
            -- 开始突破
            --self:playAnimation(true)
            if ui_tupoLayer.SelectedCard ~= 0 then
            	-- 请求突破信息
				self:requestTupoInfo(ui_tupoLayer.SelectedCard, 2)
            else
            	--
            end
            
        end

        local function onBtnSelect(btn)
            -- 开始选卡
            local cellsize = self.node_:getContentSize()
			local tupolistLayer = createObj(ui_tupoNinjaListLayer)
			self.node_:addChild(tupolistLayer.node_)
        end

        self.button_back:setTouchEnabled(true)
        self.button_back:setTouchPriority(kCCMenuHandlerPriority - 1)
        self.proxy_:handleButtonEvent(self.button_back, function(button, event)
            onBtnBack()
            return nil
        end , CCControlEventTouchDown)

        self.button_detail:setTouchEnabled(true)
        self.button_detail:setTouchPriority(kCCMenuHandlerPriority - 1)
        self.proxy_:handleButtonEvent(self.button_detail, function(button, event)
            onBtnDetail()
            return nil
        end , CCControlEventTouchDown)

        self.button_start_tupo:setTouchEnabled(true)
        self.button_start_tupo:setTouchPriority(kCCMenuHandlerPriority - 1)
        self.proxy_:handleButtonEvent(self.button_start_tupo, function(button, event)
            onBtnStartTupo()
            return nil
        end , CCControlEventTouchDown)

        self.button_select:setTouchEnabled(true)
        self.button_select:setTouchPriority(kCCMenuHandlerPriority - 1)
        self.proxy_:handleButtonEvent(self.button_select, function(button, event)
            onBtnSelect()
            return nil
        end , CCControlEventTouchDown)
	end
end

function onNodeCleanup(self)
	if self.proxy_ then
		self.proxy_:release()
	end

	layer_base_t.onNodeCleanup(self)
end