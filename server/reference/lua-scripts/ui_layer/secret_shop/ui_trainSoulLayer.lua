-- descriptioin:煉化界面
-- company: xckoo
-- author: chenchun
-- date: 2014-03-12
---------------------------------------------
module("ui_trainSoulLayer", package.seeall)
baseClass(layer_base_t, ui_trainSoulLayer)

TrainQualityToSoul = nil  -- 炼化品质到忍魂数量的映射表
TrainNinjaList = { }
Instance = nil

function init(self, trainSoulEntry)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	self.contentSize_ = GetMainMenu():GetSubContentNode():getContentSize()
	local ccbiAttrTable = { name = "secretshop/trainSoulLayer.ccbi", size = self.contentSize_ }
	layer_base_t.init(self, true, ccbiAttrTable)

	self.btnCard = { }
	self.nodeCard = { }
	self.nodeSquare = { }
	self.cardlist = {}
	self.soullist = {}

	ui_trainSoulLayer.TrainNinjaList = { }
	self.tempList = { }
	self.trainSoulEntry = trainSoulEntry or { }

	ui_trainNinjaListLayer.selectedList = {}  -- 每次进入的时候清空上次已选择的列表

	self:init_data(self.trainSoulEntry.bagId)
	self:init_ui()

	self:init_binding_event()
	ui_trainSoulLayer.Instance = self

	initHeader(self.proxy_)
	self.ctrl_btnplayermsg:setTouchPriority(-2)  --设置touch优先级,initHeader内设置的优先级会覆盖卡牌选择的返回按钮
end

function init_data(self, bagId)
	self:getNinjaListForSoul(e_obj_ninja)
	if bagId ~= nil then
		self:getNinjaIndexByBagId(bagId)
	end

	-- 获得炼化品质表的数据，并存入表中，利用炼化品质作为索引，获得可以炼化的忍魂数量
	if not ui_trainNinjaListLayer.TrainQualityToSoul then
		local struct_count = DataMgr.GetDataCount("Struct_Refinery_Info")
		-- cclog("1111----soul:quality1:%d", struct_count)
		if struct_count > 0 then
			ui_trainSoulLayer.TrainQualityToSoul = { }
		end
		for i = 1, struct_count do
			local struct_info = DataMgr.GetDataByID("Struct_Refinery_Info", i)
			ui_trainSoulLayer.TrainQualityToSoul[struct_info.m_item_quality] = struct_info.m_item_count
			-- cclog("1111----soul:quality2:%d", struct_info.m_item_quality)
		end
	end
end

function init_ui(self)
	if self.proxy_ ~= nil then
		self.sprite_playermedal = tolua.cast(self.proxy_:getNode("sprite_playermedal"), "CCSprite")
		self.label_level = tolua.cast(self.proxy_:getNode("label_level"), "CCLabelBMFont")
		self.label_curexp = tolua.cast(self.proxy_:getNode("label_curexp"), "CCLabelBMFont")
		self.label_name = tolua.cast(self.proxy_:getNode("label_name"), "CCLabelTTF")
		self.sprite_vipinfo = tolua.cast(self.proxy_:getNode("sprite_vipinfo"), "CCSprite")
		self.label_bodyval = tolua.cast(self.proxy_:getNode("label_bodyval"), "CCLabelBMFont")
		self.label_attackval = tolua.cast(self.proxy_:getNode("label_attackval"), "CCLabelBMFont")
		self.label_goldval = tolua.cast(self.proxy_:getNode("label_goldval"), "CCLabelBMFont")
		self.label_silverval = tolua.cast(self.proxy_:getNode("label_silverval"), "CCLabelBMFont")
		self.ctrl_btnplayermsg = tolua.cast(self.proxy_:getNode("ctrl_btnplayermsg"), "CCControlButton")
		self.sprite_levelstate = tolua.cast(self.proxy_:getNode("sprite_levelstate"), "CCSprite")
		self.sprite_bodyratio = tolua.cast(self.proxy_:getNode("sprite_bodyratio"), "CCSprite")
		self.sprite_attackratio = tolua.cast(self.proxy_:getNode("sprite_attackratio"), "CCSprite")

		self.ctrl_btn_trainsoul = tolua.cast(self.proxy_:getNode("ctrl_btn_trainsoul"), "CCControlButton")
		self.ctrl_btn_add_or_exchange = tolua.cast(self.proxy_:getNode("ctrl_btn_add_or_exchange"), "CCControlButton")
		self.ctrl_btn_secretshop = tolua.cast(self.proxy_:getNode("ctrl_btn_secretshop"), "CCControlButton")
		self.ctrl_btn_description = tolua.cast(self.proxy_:getNode("ctrl_btn_description"), "CCControlButton")
		self.ctrl_btn_back = tolua.cast(self.proxy_:getNode("ctrl_btn_back"), "CCControlButton")

		self.sprite_add_or_exchange = tolua.cast(self.proxy_:getNode("sprite_add_or_exchange"), "CCSprite")
		-- self.sprite_train_soul = tolua.cast(self.proxy_:getNode("sprite_train_soul"), "CCSprite")
		-- self.sprite_secretshop = tolua.cast(self.proxy_:getNode("sprite_secretshop"), "CCSprite")
		self.label_get_soul_tips = tolua.cast(self.proxy_:getNode("label_get_soul_tips"), "CCLabelTTF")
		self.lable_get_soul_num = tolua.cast(self.proxy_:getNode("lable_get_soul_num"), "CCLabelTTF")

		self.node_circle = tolua.cast(self.proxy_:getNode("node_circle"), "CCNode")
		self.node_rotate = tolua.cast(self.proxy_:getNode("node_rotate"), "CCNode")

		-- cards
		for i = 1, 5 do
			self.btnCard[i] = tolua.cast(self.proxy_:getNode("btn_card" .. i), "CCControlButton")
			self.nodeCard[i] = tolua.cast(self.proxy_:getNode("node_card" .. i), "CCNode")
			self.nodeSquare[i] = tolua.cast(self.proxy_:getNode("node_square" .. i), "CCNode")
		end
		self.cardsize = self.nodeCard[1]:getContentSize()

		self:update_btn_addorchange()

		self:playAnimation(false)
	end
end

function resetCards(self)
	ui_trainNinjaListLayer.selectedList = { }

	for i = 1, 5 do
		self.nodeCard[i]:removeAllChildrenWithCleanup(true)
	end
	self.cardlist = {}

	self:getNinjaListForSoul(e_obj_ninja)
	self:doShowAwardData()
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()
	self:addTrainResultDlg()
	initHeader(self.proxy_)
	self.ctrl_btnplayermsg:setTouchPriority(-2)
	self:update_btn_addorchange()
	self:playAnimation(false)
end
-- 根据状态，播放不同的动画
function playAnimation(self, istraining)
	local amount = #ui_trainNinjaListLayer.selectedList
	if amount > 0 and istraining == true then
		local rotatenode = createObj(ui_trainSoulAnimation, "lianhua_3", self.node_circle:getContentSize(), istraining)
		self.node_circle:removeAllChildrenWithCleanup(true)
		self.node_rotate:removeAllChildrenWithCleanup(true)

		-- 炼化完成后
		local function animationFinished()
			if self.disappear ~= nil then
				CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.disappear)
				self.disappear = nil
				self.node_rotate:removeAllChildrenWithCleanup(true)

				for key, var in ipairs(ui_trainNinjaListLayer.selectedList) do
					CPlayerDataMgr:instance():RemoveObjByID(ui_trainSoulLayer.TrainNinjaList[var]:GetGUID())
				end

				self:resetCards()
			end
		end
		self.disappear = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(animationFinished, 2, false)
		self.node_rotate:addChild(rotatenode.bglayer)
		self.node_rotate:addChild(rotatenode.node_)

	elseif amount > 0 then
		local circlenode = createObj(ui_trainSoulAnimation, "lianhua_02", self.node_circle:getContentSize())
		local localSize = circlenode.node_:getContentSize()
		circlenode.node_:setPosition(localSize.width / 2, localSize.height / 2)
		circlenode.node_:setAnchorPoint(ccp(0.5, 0.5))
		self.node_rotate:removeAllChildrenWithCleanup(true)
		self.node_circle:removeAllChildrenWithCleanup(true)
		self.node_circle:addChild(circlenode.node_)
	else
		self.node_rotate:removeAllChildrenWithCleanup(true)
		self.node_circle:removeAllChildrenWithCleanup(true)
	end

	for i = 1, 5 do
		self.nodeSquare[i]:removeAllChildrenWithCleanup(true)
		if i > amount then
			local suqarenode = createObj(ui_trainSoulAnimation, "lianhua_01", self.nodeSquare[i]:getContentSize())
			local localSize = suqarenode.node_:getContentSize()
			suqarenode.node_:setPosition(localSize.width / 2, localSize.height / 2)
			suqarenode.node_:setAnchorPoint(ccp(0.5, 0.5))
			self.nodeSquare[i]:addChild(suqarenode.node_)
		end

	end

	if amount < 5 then
		local frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("trainsoul_11")
		if frame ~= nil then
			self.sprite_add_or_exchange:setDisplayFrame(frame)
		end
	end
end

function getCardsStr(self)
	local str = ""
	for i, v in ipairs(ui_trainNinjaListLayer.selectedList) do
		id = ui_trainSoulLayer.TrainNinjaList[v]:GetGUID()
		str = str .. id .. '|'
	end

	str = string.sub(str, 1, string.len(str) -1)
	-- 去掉末尾的|
	return str
end

function getBestQuality(self)
	local bestQuality = 0
	for i, v in ipairs(ui_trainNinjaListLayer.selectedList) do
		local info = DataMgr.GetDataByID("Struct_Ninjainfo", tonumber(ui_trainSoulLayer.TrainNinjaList[v]:GetDataID()))
		if info.m_lianhua_pinzhi > bestQuality then
			bestQuality = info.m_lianhua_pinzhi
		end
	end
	return bestQuality
end

function autoSelect(self)
	-- 先删除已选入的
	for key, var in ipairs(ui_trainNinjaListLayer.selectedList) do
		for i, v in ipairs(self.tempList) do
			if v == var then
				table.remove(self.tempList, i)
			end
		end
	end

	local max = 5
	local remain = #self.tempList
	if remain == 0 then
		-- 提示已经换完了
		return
	elseif remain < 5 then
		max = remain
	end

	ui_trainNinjaListLayer.selectedList = { }
	for i = 1, max do
		table.insert(ui_trainNinjaListLayer.selectedList, self.tempList[i])
	end

end

function init_binding_event(self)
	if self.proxy_ ~= nil then

		local function trainsoul()
			if #ui_trainNinjaListLayer.selectedList > 0 then
				local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 3, protocol.URL_X_MYSTERY_SHOP)
				urlpath = AddData(urlpath, "BagId", self:getCardsStr())
				-- urlpath = "http://192.168.0.236/reward1.xml"
				GetMainMenu():ShowLoadingDlg()
				-- 获取信息的时候，不允许操作
				CCHttpRequest:open(urlpath, kHttpPost, "query=param1&other=params"):sendWithHandler(
				function(res, hnd)
					GetMainMenu():CloseLoadding()
					-- 获取信息完成时，解除禁止操作
					local resData = res:getResponseData()
					-- cclog("1111----resData:%s", resData)
					local code = res:getResponseCode()
					local xfile = xml.parse(resData)
					local item = xfile:find("RENLONG")
					local retcode = item.code
					if retcode == "0" then
						local awardXML = item:find("award")
						-- ShowAward(awardXML)							
						-- self.trainAward, self.awardCardCount, self.awardPropCount = ShowAward(awardXML)					
						self.trainAward = AddSoulAwardData(awardXML)
						self:playAnimation(true)
					else
						GetMainMenu():ShowErrorTip(tonumber(retcode), -1)
					end
				end )
			else
				GetMainMenu():ShowTextTip(localizable.ui_train_soul_tips, -1)
			end
		end

		local function begain_train_soul()
			local best = self:getBestQuality()
			if best > 4 then
				local dlg = CommonDialogView.create()
				CommonDialogView.m_selfview = dlg
				dlg:SetTitle(localizable.ui_train_tips_title)
				dlg:SetDescription(localizable.ui_train_tips_info)
				dlg:loadCCBI()
				dlg:initUI()
				dlg:SetConfirmHandler(trainsoul)
				GetMainMenu():GetModelLayer():AddDialog(dlg, 3)
			else
				trainsoul()
			end
		end

		local function goto_secretshop()
			GetMainMenu():ChangeToActivitySubMenu("ShowSecretShopView", "gSecretShopEntry={prePage=\"soul\"}")
			-- GetMainMenu():ChangeToActivitySubMenu("ShowSecretShopView", )
		end

		local function open_trainlist()
			local cellsize = self.node_:getContentSize()
			local trainlistLayer = createObj(ui_trainNinjaListLayer)
			self.node_:addChild(trainlistLayer.node_)
		end

		local function add_or_exchange()
			self:autoSelect()
			self:update_btn_addorchange()
		end

		local function open_description()
			local descriptionLayer = createObj(ui_trainSoulDescription)
			GetMainMenu():GetModelLayer():AddDialog(descriptionLayer.node_, 3)
		end

		local function goto_pre_page()
			if self.trainSoulEntry.prePage == "backpack" then
				GetMainMenu():ChangeToSub(E_BACKPACKVIEW);
			elseif self.trainSoulEntry.prePage == "secretshop" then
				GetMainMenu():ChangeToActivitySubMenu("ShowSecretShopView", "gSecretShopEntry={prePage=\"soul\"}")
			else
				GetMainMenu():ChangeToSub(E_DEFAULTMENU);
			end
		end

		self.ctrl_btn_trainsoul:setTouchPriority(-2)
		self.ctrl_btn_secretshop:setTouchPriority(-2)
		self.ctrl_btn_add_or_exchange:setTouchPriority(-2)
		self.ctrl_btn_description:setTouchPriority(-2)
		self.ctrl_btn_back:setTouchPriority(-2)

		self.proxy_:handleControlEvent(self.ctrl_btn_trainsoul, begain_train_soul, CCControlEventTouchUpInside)
		self.proxy_:handleControlEvent(self.ctrl_btn_secretshop, goto_secretshop, CCControlEventTouchUpInside)
		self.proxy_:handleControlEvent(self.ctrl_btn_add_or_exchange, add_or_exchange, CCControlEventTouchUpInside)
		self.proxy_:handleControlEvent(self.ctrl_btn_description, open_description, CCControlEventTouchUpInside)
		self.proxy_:handleControlEvent(self.ctrl_btn_back, goto_pre_page, CCControlEventTouchUpInside)

		for i = 1, 5 do
			self.btnCard[i]:setTouchPriority(-2)
			self.proxy_:handleControlEvent(self.btnCard[i], open_trainlist, CCControlEventTouchUpInside)
		end

	end
end

-- 根据卡的类型，获得满足炼魂条件的卡的列表
function getNinjaListForSoul(self, cardtype)
	ui_trainSoulLayer.TrainNinjaList = { }
	local objlist = CPlayerDataMgr:instance():GetObjectList(cardtype)
	local count = objlist:size() -1
	for i = 0, count do
		local quality = objlist[i]:GetQuality()
		if objlist[i]:IsUsingInAnyTeam() == false and quality >= 3 and quality <= 6 then
			table.insert(ui_trainSoulLayer.TrainNinjaList, objlist[i])
		end
	end

	local function sortByQuality(a, b)
		if a:GetQuality() == b:GetQuality() then
			return a:GetStrengthLevel() < b:GetStrengthLevel()
		else
			return a:GetQuality() < b:GetQuality()
		end
	end

	table.sort(ui_trainSoulLayer.TrainNinjaList, sortByQuality)

	-- 拷贝一份，用于“换一批”操作
	self.tempList = {}
	for key, var in ipairs(ui_trainSoulLayer.TrainNinjaList) do
		table.insert(self.tempList, key)
	end

end

-- 通过背包ID，获得卡牌在 TrainNinjaList 中的索引Index
function getNinjaIndexByBagId(self, bagId)
	local iBagId = tonumber(bagId)
	for i = 1, #ui_trainSoulLayer.TrainNinjaList do
		local tmpNinja = ui_trainSoulLayer.TrainNinjaList[i]
		if tmpNinja:GetGUID() == iBagId then
			ui_trainNinjaListLayer.selectedList = { i }
			break
		end
	end
end

-- 当按下增加忍者按钮或者从“忍者选择”界面返回时，更新按钮状态以及忍者图标信息
function update_btn_addorchange(self)
	if #ui_trainSoulLayer.TrainNinjaList == 0 then
		self.lable_get_soul_num:setString("0")
		return
	end

	if #ui_trainNinjaListLayer.selectedList < 5 then
		local frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("trainsoul_11")
		if frame ~= nil then
			self.sprite_add_or_exchange:setDisplayFrame(frame)
		end
	else
		local frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("trainsoul_10")
		if frame ~= nil then
			self.sprite_add_or_exchange:setDisplayFrame(frame)
		end
	end

	for i, index in ipairs(ui_trainNinjaListLayer.selectedList) do
		if i > 5 then break end

		local cardnode = createObj(ui_trainNinjaCard, self.cardsize, index)
		self.nodeCard[i]:addChild(cardnode.node_)
		self.cardlist[i] = cardnode
	end

	self:playAnimation(false)

	self:requestTotalSoul()
end

function requestTotalSoul(self)
	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 5, "rl_x_mystery_shop")
	urlpath = AddData(urlpath, "BagId", self:getCardsStr())
	local function callback(renlong)
		local totalsoul = tonumber(renlong:find('total_val')[1])
		self.lable_get_soul_num:setString(totalsoul)

		local souls = renlong:find('card_list')
		self.soullist = {}
		for _, soul in ipairs(souls) do
			local tmp = {bagid = tonumber(soul:find('bagid')[1]),
						soul = tonumber(soul:find('lianhun_val')[1]) }
			table.insert(self.soullist,tmp)
		end 
		
		for _, card in ipairs(self.cardlist) do
			card:setSoul(self.soullist)
		end
		
	end
	sendRequest(urlpath, callback, 1)
end

function getTotalSoul(self)
	local total = 0
	for i, v in ipairs(ui_trainNinjaListLayer.selectedList) do
		local info = DataMgr.GetDataByID("Struct_Ninjainfo", tonumber(ui_trainSoulLayer.TrainNinjaList[v]:GetDataID()))
		total = total + ui_trainSoulLayer.TrainQualityToSoul[info.m_lianhua_pinzhi]
	end

	return total
end
function doShowAwardData(self)
	self.awardSpriteAndCount = { }
	if self.trainAward ~= nil then
		if self.trainAward.m_markchip ~= 0 then
			local fragment = CPlayerMarkFragmentsMgr:instance():GetFragment(self.trainAward.m_markchip)
			local card = fragment:GetMark()
			local iconcache = card:GetCardIcon(E_FRAMETYPE_SMALL)
			table.insert(self.awardSpriteAndCount, { icon = iconcache, num = 1 })
		end
		local awardCardCount = self.trainAward:cardCount()
		if awardCardCount > 0 then
			for i = 0, awardCardCount - 1 do
				local netdata = self.trainAward:getCardData(i)
				local iconcache, sprite_frame = rl_get_iconsprite("1", netdata.m_type, E_FRAMETYPE_SMALL, netdata.m_dataid)
				table.insert(self.awardSpriteAndCount, { icon = iconcache, num = netdata.m_count, frame = sprite_frame })
			end
		end
		local propCount = self.trainAward:propCount()
		if propCount > 0 then
			for j = 0, propCount - 1 do
				local consumdata = self.trainAward:getPropData(j)
				local iconcache = rl_get_iconsprite("2", 0, E_FRAMETYPE_SMALL, consumdata.m_id)
				table.insert(self.awardSpriteAndCount, { icon = iconcache, num = consumdata.m_count, frame = sprite_frame })
			end
		end
		local chipCount = self.trainAward:chipCardCount()
		if chipCount > 0 then
			for j = 0, chipCount - 1 do
				local netdata = self.trainAward:getChipCardData(j)
				local iconcache, sprite_frame = rl_get_iconsprite("1", netdata.m_type, E_FRAMETYPE_SMALL, netdata.m_dataid)
				table.insert(self.awardSpriteAndCount, { icon = iconcache, num = netdata.m_piecenum, frame = sprite_frame })
			end
		end
		if self.trainAward.m_gold ~= 0 then
			local iconcache = rl_get_iconsprite("4", 0, E_FRAMETYPE_SMALL)
			table.insert(self.awardSpriteAndCount, { icon = iconcache, num = self.trainAward.m_gold })
		end
		if self.trainAward.m_silver ~= 0 then
			local iconcache = rl_get_iconsprite("3", 0, E_FRAMETYPE_SMALL)
			table.insert(self.awardSpriteAndCount, { icon = iconcache, num = self.trainAward.m_silver })
		end
		if self.trainAward.m_soul ~= 0 then
			local iconcache = rl_get_iconsprite("6", 0, E_FRAMETYPE_SMALL)
			table.insert(self.awardSpriteAndCount, { icon = iconcache, num = self.trainAward.m_soul })
		end
	end
end

function addTrainResultDlg(self)
	local resultLayer = createObj(ui_trainResultLayer, self.awardSpriteAndCount)
	GetMainMenu():GetModelLayer():AddDialog(resultLayer.node_, 3)
	resultLayer.node_container:setScale(0)
	local scaleTo = CCScaleTo:create(0.1, 1)
	resultLayer.node_container:runAction(scaleTo)
end

function onNodeCleanup(self)
	if self.proxy_ then
		self.proxy_:release()
	end
	ui_trainSoulLayer.TrainNinjaList = nil
	ui_trainSoulLayer.Instance = nil

	local plistNameList = { "ccbResources/train_soul.plist", "ccbResources/train_soul_animation.plist" }
	for k, v in ipairs(plistNameList) do
		CCSpriteFrameCache:sharedSpriteFrameCache():removeSpriteFramesFromFile(v)
		local imagePath = string.format("%s.pvr.ccz", string.sub(v, 1, string.len(v) -6))
		CCTextureCache:sharedTextureCache():removeTextureForKey(imagePath)
		imagePath = string.format("%s.pvr", string.sub(v, 1, string.len(v) -6))
		CCTextureCache:sharedTextureCache():removeTextureForKey(imagePath)
		imagePath = string.format("%s.png", string.sub(v, 1, string.len(v) -6))
		CCTextureCache:sharedTextureCache():removeTextureForKey(imagePath)
	end

	layer_base_t.onNodeCleanup(self)
end