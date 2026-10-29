--descriptioin:神秘商店
--company: xckoo
--author: chenchun
--date: 2014-03-12
---------------------------------------------
module("ui_secretShopLayer", package.seeall)
baseClass(layer_base_t, ui_secretShopLayer)


function init(self, secretShopEntry, parent)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	self.contentSize_ = GetMainMenu():GetSubContentNode():getContentSize()
	local ccbiAttrTable = {name="secretshop/secretShopLayer.ccbi", size=self.contentSize_}
	layer_base_t.init(self, true, ccbiAttrTable)

	self.secretShopEntry = secretShopEntry or {}
    self.parent = parent
	self.cards = {}
	self.userInfo = {}
	self.leftTime = 0
	self.deltaTime= 0
	self.shopNodes = {}
	self:init_ui()
	self:init_binding_event()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		self.ctrl_btn_update = tolua.cast(self.proxy_:getNode("ctrl_btn_update"), "CCControlButton")
		self.ctrl_btn_train = tolua.cast(self.proxy_:getNode("ctrl_btn_train"), "CCControlButton")
		self.label_left_time = tolua.cast(self.proxy_:getNode("label_left_time"), "CCLabelBMFont")

		self.label_cur_soul = tolua.cast(self.proxy_:getNode("label_cur_soul"), "CCLabelBMFont")
		self.label_need_gold = tolua.cast(self.proxy_:getNode("label_need_gold"), "CCLabelTTF")
		self.label_update_token = tolua.cast(self.proxy_:getNode("label_update_token"), "CCLabelTTF")
		self.ctrl_btn_back = tolua.cast(self.proxy_:getNode("ctrl_btn_back"), "CCControlButton")

		self.label_today_times = tolua.cast(self.proxy_:getNode("label_today_times"), "CCLabelTTF")
		self.label_vip_times = tolua.cast(self.proxy_:getNode("label_vip_times"), "CCLabelTTF")
		self.label_vip_unit = tolua.cast(self.proxy_:getNode("label_vip_unit"), "CCLabelTTF")
		self.sprite_vip_level = tolua.cast(self.proxy_:getNode("sprite_vip_level"), "CCSprite")

		for i = 1, 6 do
			self["node_card" .. tostring(i)] = tolua.cast(self.proxy_:getNode("node_card" .. tostring(i)), "CCNode")
		end
		self.cellNodeSize = self.node_card1:getContentSize()	

		local viplevel = self.playerData_.m_viplevel
		local vipframes={[0] = "vip_015",[1]="vip_003",[2]="vip_004",[3]="vip_005",[4]="vip_006",
			[5]="vip_007",[6]="vip_008",[7]="vip_009",[8]="vip_010",[9]="vip_011",[10]="vip_012",[11]="vip_013",[12]="vip_014",[13]="vip_s_13",[14] = "vip_s_14",[15] = "vip_s_15",[16]="vip_s_16",[17]="vip_s_17",[18]="vip_s_18"}
		

		local normal_vipData = DataMgr.GetDataByID("Struct_Vipinfo", tonumber(viplevel + 1))
		if viplevel < 18 then
			if self.sprite_vip_level ~= nil then
				local pFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(vipframes[viplevel+1])
				self.sprite_vip_level:setDisplayFrame(pFrame)
			end
			local next_vipData = DataMgr.GetDataByID("Struct_Vipinfo", tonumber(viplevel + 2))
			local vipAddUpdateTimes = next_vipData.m_vip_fun2_num - normal_vipData.m_vip_fun2_num
			self.label_vip_times:setString("+" .. tostring(vipAddUpdateTimes))
		else
			if self.sprite_vip_level ~= nil then
				local pFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(vipframes[viplevel])
				self.sprite_vip_level:setDisplayFrame(pFrame)
			end
			self.label_vip_unit:setVisible(false)
			self.label_vip_times:setString(localizable.ui_train_update_times_limit_tips)
		end

		self:getCardsInfo(true)
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

		local function update_card_info()
			--local function update_sure()
			self:getCardsInfo(false)
			--end
		end
		
		local function goto_train()
			--self.node_:removeFromParentAndCleanup(true)
			GetMainMenu():ChangeToActivitySubMenu("ShowTrainSoulView", "gTrainSoulEntry={prePage=\"secretshop\"}")
		end

		local function go_back()
            if self.secretShopEntry == "petlist" then
                self.node_:removeFromParentAndCleanup(true)
                if self.parent ~= nil then
                    self.parent:update_ui()
                end
			elseif self.secretShopEntry.prePage == "soul" then
				GetMainMenu():ChangeToActivitySubMenu("ShowTrainSoulView", "gTrainSoulEntry={prePage=\"secretshop\"}")
			elseif self.secretShopEntry.prePage == "backpack" then
				GetMainMenu():ChangeToSub(E_BACKPACKVIEW)
			else
				GetMainMenu():ChangeToSub(E_DEFAULTMENU)
			end
		end

		self.ctrl_btn_update:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.proxy_:handleControlEvent(self.ctrl_btn_update, update_card_info, CCControlEventTouchUpInside)
		self.ctrl_btn_train:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.proxy_:handleControlEvent(self.ctrl_btn_train, goto_train, CCControlEventTouchUpInside)
		self.ctrl_btn_back:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.proxy_:handleControlEvent(self.ctrl_btn_back, go_back, CCControlEventTouchUpInside)

	end
end


function updateTime(self)
	self.label_left_time:unscheduleUpdate()
	self.deltaTime = 0
	local function updateLeftTimeLabel(fDeltaTime)
		self.deltaTime = self.deltaTime + fDeltaTime
		if self.deltaTime >= 1 then
			local intPart, floatPart = math.modf(self.deltaTime)
			self.leftTime = self.leftTime - intPart
			if self.leftTime > 0 then
				local timeStr = tools.convertTimeElectronicWatch(self.leftTime, 3)
				self.label_left_time:setString(timeStr)
				self.deltaTime = floatPart
			else
				self.label_left_time:setString("0")
				self.label_left_time:unscheduleUpdate()
				self.deltaTime = 0
				self.leftTime = 0
				self:getCardsInfo(true)
			end
		end
	end

	if self.leftTime > 0 then
		self.label_left_time:scheduleUpdateWithPriorityLua(updateLeftTimeLabel, 0)
		self.label_left_time:setString(tools.convertTimeElectronicWatch(self.leftTime, 3))
	else
		self.label_left_time:setString("0")
		self.deltaTime = 0
		self.leftTime = 0
		self:getCardsInfo(true)
	end
end


function refreshData(self, item, isfirst)
	self.cards = {}
	local userItem = item:find("user")
	local cardList = item:find("cardlist")
	if userItem ~= nil then
		self.userInfo["cursoul"] = userItem:find("cursoul")[1]
		self.userInfo["updatenum"] = userItem:find("updatenum")[1]
		self.userInfo["gold"] = userItem:find("gold")[1]
		self.userInfo["refreshcost"] = userItem:find("refreshcost")[1]
		self.userInfo["totalrefresh"] = userItem:find("totalrefresh")[1]
		self.userInfo["dayrefreshleft"] = userItem:find("dayrefreshleft")[1]
		self.leftTime = tonumber(userItem:find("lefttime")[1])
	end

	self.label_cur_soul:setString(self.userInfo["cursoul"])
	self.label_update_token:setString(self.userInfo["updatenum"])
	self.label_need_gold:setString(self.userInfo["refreshcost"])

	if cardList ~= nil then
		for i = 1, #cardList do
			local tmpTable = {}
			local card = cardList[i]:find("card")
			tmpTable["id"] = card:find("id")[1]
			tmpTable["type"] = card:find("type")[1]
			tmpTable["subtype"] = card:find("subtype")[1]
			tmpTable["name"] = card:find("name")[1]
			tmpTable["icon"] = card:find("icon")[1]
			tmpTable["num"] = card:find("num")[1]
			tmpTable["cost"] = card:find("cost")[1]
			tmpTable["costtype"] = card:find("costtype")[1]
			tmpTable["status"] = card:find("status")[1]
			tmpTable["itemid"] = card:find("itemid")[1]
			tmpTable["attacktype"] = card:find("attacktype")[1]
			table.insert(self.cards, tmpTable)
		end
	end

	if isfirst and #self.shopNodes  <= 0 then
		for i = 1, #self.cards do
			local shopnode = createObj(ui_secretShopNode, self.cellNodeSize, self.cards[i], self)
			self["node_card" .. tostring(i)]:addChild(shopnode.node_)
			table.insert(self.shopNodes, shopnode)
		end	
	else
		for i = 1, #self.cards do
			self.shopNodes[i]:update_data(self.cards[i])
		end
	end
	--local costTimes = tonumber(self.userInfo["totalrefresh"]) - tonumber(self.userInfo["dayrefreshleft"])
	self.label_today_times:setString(self.userInfo["dayrefreshleft"] .. "/" .. self.userInfo["totalrefresh"])
end

function getCardsInfo(self, isfirst)
	local urlpath = ""
	if isfirst then
		urlpath = GetUrlNormalHeader(self.playerData_.m_uid,  1, protocol.URL_X_MYSTERY_SHOP)
	 	--urlpath = "http://192.168.0.236/secretshop.xml"
	else
		urlpath = GetUrlNormalHeader(self.playerData_.m_uid,  2, protocol.URL_X_MYSTERY_SHOP)
		--urlpath = "http://192.168.0.236/secretshop2.xml"
	end
	GetMainMenu():ShowLoadingDlg()	--获取信息的时候，不允许操作
	CCHttpRequest:open(urlpath, kHttpPost,"query=param1&other=params"):sendWithHandler(
		function(res, hnd)
			GetMainMenu():CloseLoadding() --获取信息完成时，解除禁止操作
			local resData = res:getResponseData()
			local code = res:getResponseCode()
			local xfile = xml.parse(resData)
			local item = xfile:find("RENLONG")
			local retcode = item.code
			if retcode == "0" then
				self:refreshData(item, isfirst)
				self:updateTime()
			else
				if retcode == "325006" then
					--GetMainMenu():ShowTextTip("每天只能刷新" .. tostring(self.userInfo["totalrefresh"]) .. "次，请明天再来吧！", -1)
					GetMainMenu():ShowTextTip(string.format(localizable.ui_sceret_shop_update_tips, tostring(self.userInfo["totalrefresh"])), -1)
				else
					GetMainMenu():ShowErrorTip(tonumber(retcode), -1)
				end
			end
		end)	
end

function update_label_soul(self, costtype, cost)
	if costtype == "1" then
		self.userInfo["cursoul"] = tostring(tonumber(self.userInfo["cursoul"]) - cost)
		self.label_cur_soul:setString(self.userInfo["cursoul"])
	else
		self.userInfo["gold"] = tostring(tonumber(self.userInfo["gold"]) - cost)
	end
end

function onNodeCleanup(self)
	--cclog("1111---001")
	if self.proxy_ then
    	self.proxy_:release()
    end
    local plistNameList = {"ccbResources/train_soul.plist","ccbResources/train_soul_animation.plist"}
    for k, v in ipairs(plistNameList) do
		CCSpriteFrameCache:sharedSpriteFrameCache():removeSpriteFramesFromFile(v)
		local imagePath = string.format( "%s.pvr.ccz", string.sub(v, 1, string.len(v) - 6) )
		CCTextureCache:sharedTextureCache():removeTextureForKey( imagePath )
		imagePath = string.format( "%s.pvr", string.sub(v, 1, string.len(v) - 6) )
		CCTextureCache:sharedTextureCache():removeTextureForKey( imagePath )
		imagePath = string.format( "%s.png", string.sub(v, 1, string.len(v) - 6) )
		CCTextureCache:sharedTextureCache():removeTextureForKey( imagePath )
	end
	self.shopNodes = nil
	self.cards = nil
	self.userInfo = nil
	self.leftTime = nil
	self.deltaTime= nil
	self.label_left_time:unscheduleUpdate()
    layer_base_t.onNodeCleanup(self)
end