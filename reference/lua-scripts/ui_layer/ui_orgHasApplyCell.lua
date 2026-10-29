--descriptioin:工会申请页面
--company: xckoo
--author: litao
--date: 2014-10-24
---------------------------------------------
module("ui_orgHasApplyCell", package.seeall)
baseClass(layer_base_t, ui_orgHasApplyCell)

function init(self)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	self.contentSize_ = GetMainMenu():GetSubContentNode():getContentSize()
	local ccbiAttrTable = {name="sub_ui/OrgApplyView.ccbi", size=self.contentSize_}
	layer_base_t.init(self, true, ccbiAttrTable)

	--pre page
	self.back_page = E_DEFAULTMENU

    --data
    self.preNode = node
    self.m_add_desc_data = {}
    --is open
    self.isOpening = false

    --init
	self:init_ui()
	self:init_binding_event()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		--node
		self.node_anim_container = tolua.cast(self.proxy_:getNode("node_anim_container"), "CCNode")
		self.node_content = tolua.cast(self.proxy_:getNode("node_content"), "CCNode")
		self.node_cell = tolua.cast(self.proxy_:getNode("node_cell"), "CCNode")
		--label
		self.label_cur_soul = tolua.cast(self.proxy_:getNode("label_cur_soul"), "CCLabelTTF")
		self.label_cost_soul = tolua.cast(self.proxy_:getNode("label_cost_soul"), "CCLabelTTF")
		self.label_cost_silver = tolua.cast(self.proxy_:getNode("label_cost_silver"), "CCLabelTTF")
		self.label_gate_lv = tolua.cast(self.proxy_:getNode("label_gate_lv"), "CCLabelTTF")

		self.label_add_att = tolua.cast(self.proxy_:getNode("label_add_att"), "CCLabelTTF")
		self.label_add_def = tolua.cast(self.proxy_:getNode("label_add_def"), "CCLabelTTF")
		self.label_add_chakra = tolua.cast(self.proxy_:getNode("label_add_chakra"), "CCLabelTTF")
	
		self.label_add_att_per = tolua.cast(self.proxy_:getNode("label_add_att_per"), "CCLabelTTF")
		self.label_add_def_per = tolua.cast(self.proxy_:getNode("label_add_def_per"), "CCLabelTTF")
		self.label_add_chakra_per = tolua.cast(self.proxy_:getNode("label_add_chakra_per"), "CCLabelTTF")

		self.label_gold = tolua.cast(self.proxy_:getNode("label_gold"), "CCLabelBMFont")
		self.label_silver = tolua.cast(self.proxy_:getNode("label_silver"), "CCLabelBMFont")
		--btn
		self.btn_back = tolua.cast(self.proxy_:getNode("btn_back"), "CCControlButton")
		self.btn_limitTrain = tolua.cast(self.proxy_:getNode("btn_limitTrain"), "CCControlButton")
		self.btn_open = tolua.cast(self.proxy_:getNode("btn_open"), "CCControlButton")
		--spr
		self.spr_gate = tolua.cast(self.proxy_:getNode("spr_gate"), "CCSprite")
		for i=1,8 do
			self["spr_gate_num_"..tostring(i)] = tolua.cast(self.proxy_:getNode("spr_gate_num_"..tostring(i)), "CCSprite")
		end
		self.spr_line = tolua.cast(self.proxy_:getNode("spr_line"), "CCSprite")
		
		--base request
		self:requestBaseLayerInfo()
	end
end

function requestBaseLayerInfo(self)
	--获取基本信息
	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 1, "rl_w_eight_gate")
	urlpath = AddData(urlpath, "version", 2)
	--cclog("rl_w_eight_gate & cmd = 1---%s", urlpath)
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
			--cclog("rl_w_eight_gate ret = %s", resData)
			local retcode = item.code
			if retcode == "0" then
				local _basic = item:find("basic")
				if _basic then
					self.cur_soul = tonumber(_basic:find("soul")[1])
					self.cur_gate_level = tonumber(_basic:find("gate_level")[1])
					self.cur_cost_soul = tonumber(_basic:find("cost_soul")[1])
					self.cur_cost_silver = tonumber(_basic:find("cost_coin")[1])
					--当前门加成描述
					local cur_gate_data = _basic:find("gate_id")
					self.cur_gate_id = tonumber(cur_gate_data.id)
					--cclog("next_open_gate = %s", tostring(self.cur_gate_id))
					if self.cur_gate_id < 1 then
						self.cur_gate_id = 1
					end
					self.m_add_desc_data = {}
					for i=1,#cur_gate_data do
						local item = {}
						item.type = tonumber(cur_gate_data[i].type)
						item.add_num = tonumber(cur_gate_data[i].value)
						table.insert(self.m_add_desc_data, item)
					end
				end

				local _att_add = item:find("attribute")
				if _att_add then
					self.add_att = tonumber(_att_add:find("add_attack")[1])
					self.add_def = tonumber(_att_add:find("add_defense")[1])
					self.add_chakra = tonumber(_att_add:find("add_chakala")[1])
					--self.add_ninjasu_per = tonumber(_att_add:find("add_skill")[1])
					self.add_att_per = tonumber(_att_add:find("add_attack_per")[1])
					self.add_def_per = tonumber(_att_add:find("add_defense_per")[1])
					self.add_chakra_per = tonumber(_att_add:find("add_chakala_per")[1])
				end
													
				--ext init ui
				self:init_ext_ui()
			else
				GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
			end
		end)
end

function init_ext_ui(self)
	CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile("ccbResources/limitTrain.plist")
	--显示基本信息
	self.label_gold:setString(tostring(self.playerData_.m_gold))
	self.label_silver:setString(tostring(self.playerData_.m_silver))

	self.label_cur_soul:setString(tostring(self.cur_soul))

	self.label_cost_soul:setString(tostring(self.cur_cost_soul))
	self.label_cost_silver:setString(tostring(self.cur_cost_silver))
	self.label_gate_lv:setString("LV:"..tostring(self.cur_gate_level))

	self.label_add_att:setString("+"..tostring(self.add_att))
	self.label_add_def:setString("+"..tostring(self.add_def))
	self.label_add_chakra:setString("+"..tostring(self.add_chakra))

	--att
	if self.add_att_per > 0 then
		self.label_add_att_per:setString("+"..tostring(self.add_att_per/10).."%")
	else
		self.label_add_att_per:setString("0")
	end
	--def
	if self.add_def_per > 0 then
		self.label_add_def_per:setString("+"..tostring(self.add_def_per/10).."%")
	else
		self.label_add_def_per:setString("0")
	end
	--chakra
	if self.add_chakra_per > 0 then
		self.label_add_chakra_per:setString("+"..tostring(self.add_chakra_per/10).."%")
	else
		self.label_add_chakra_per:setString("0")
	end

	--遁甲亮点
	for i=1,8 do
		self["spr_gate_num_"..tostring(self.cur_gate_id)]:setScale(1)
		if i < self.cur_gate_id then
			local frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("limitTrain_open")
			if frame ~= nil then
				self["spr_gate_num_"..tostring(i)]:setDisplayFrame(frame)
			end
		else
			local frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("limitTrain_close")
			if frame ~= nil then
				self["spr_gate_num_"..tostring(i)]:setDisplayFrame(frame)
			end
		end
	end

	local _gate_frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("limitTrain_gate"..tostring(self.cur_gate_id))
	self.spr_gate:setDisplayFrame(_gate_frame)

	self:next_open_gate_tip()

	self:createTableView()

	--待开启动画
	local animNodeSize = self["spr_gate_num_"..tostring(self.cur_gate_id)]:getContentSize()
	self.m_animLayer = createObj(ui_limitTrainAnim, animNodeSize, 1)

	self["spr_gate_num_"..tostring(self.cur_gate_id)]:addChild(self.m_animLayer.node_)

	self.m_animLayer.node_:setPosition(ccp(-animNodeSize.width * 1, -animNodeSize.height * 1))
	self.m_animLayer.node_:setAnchorPoint(ccp(0.5, 0.5))
	self.m_animLayer.node_:setTag(99)
end

function next_open_gate_tip(self)
	--待开启图标展示
	local frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("limitTrain_next")
	if frame ~= nil then
		self["spr_gate_num_"..tostring(self.cur_gate_id)]:setDisplayFrame(frame)
	end
	--带开启属性位置变化
	local ptx,pty = self["spr_gate_num_"..tostring(self.cur_gate_id)]:getPosition()
	self.spr_line:setPosition(ccp(ptx, pty))
end

function createTableView(self)
	if self._tableView == nil then
		local cellContentSize = self.node_cell:getContentSize()
		self._cell_size = CCSizeMake(cellContentSize.width,cellContentSize.height)

		self._content_size = self.node_content:getContentSize()
		self:initTableHandle()
		self._tableView = LuaTableView:createWithHandler(self._tableViewHandler, CCSizeMake(self._content_size.width, self._content_size.height))
		self._tableView:setDirection(kCCScrollViewDirectionVertical)
		self._tableView:setVerticalFillOrder(kCCTableViewFillTopDown)
		self._tableView:setTouchPriority(kCCMenuHandlerPriority - 1)

		self.node_content:addChild(self._tableView)
	else
		self._tableView:reloadData()
	end
end

function initTableHandle(self)
	self._tableViewHandler = LuaEventHandler:create(function(fn, table, a1, a2, x, y)
		local r
		if fn == "cellSize" then
			r = self._cell_size;
		elseif fn == "cellAtIndex" then
    		local nodeLayer = createObj(ui_limitTrainCell, self._cell_size, self.m_add_desc_data[a1 + 1])
			--tableView cell container
			--self.cellNodes[a1+1] = nodeLayer
			if not a2 then
				a2 = CCTableViewCell:create()
				a2:addChild(nodeLayer.node_)
			else
				a2:removeAllChildrenWithCleanup(true)
        		a2:addChild(nodeLayer.node_)
			end
			r = a2
		elseif fn == "numberOfCells" then
			r = #self.m_add_desc_data;
		    -- Cell events:
		elseif fn == "cellTouched" then			-- A cell was touched, a1 is cell that be touched. This is not necessary.
			---[[
			local cell_index = a1:getIdx() + 1
			--]]
		elseif fn == "cellTouchBegan" then		-- A cell is touching, a1 is cell, a2 is CCTouch
			r = true
		elseif fn == "cellTouchEnded" then		-- A cell was touched, a1 is cell, a2 is CCTouch
			r = true
		elseif fn == "cellHighlight" then		-- A cell is highlighting, coco2d-x 2.1.3 or above
		elseif fn == "cellUnhighlight" then		-- A cell had been unhighlighted, coco2d-x 2.1.3 or above
		elseif fn == "cellWillRecycle" then		-- A cell will be recycled, coco2d-x 2.1.3 or above
		end
		return r
	end)
end

function playGotoTrainTipAnim(self)
	if self.btn_limitTrain:getActionByTag(99) then
		self.btn_limitTrain:stopActionByTag(99)
		self.btn_limitTrain:setScale(1.0)
	end
	--骰子呼吸
	local move = CCScaleBy:create(0.2, 1.2)
	local array = CCArray:create()
	array:addObject(move)
	array:addObject(move:reverse())

	array:addObject(move)
	array:addObject(move:reverse())

	array:addObject(move)
	array:addObject(move:reverse())

	array:addObject(move)
	array:addObject(move:reverse())

	array:addObject(move)
	array:addObject(move:reverse())
	--array:addObject(CCDelayTime:create(1.5))
	local once = CCSequence:create(array)
	once:setTag(99)
	self.btn_limitTrain:runAction(once)
end

function playOpenAnim(self, openIndex)
	--清除light动画
	for i=1,8 do
		local pre_animLayer = self["spr_gate_num_"..tostring(i)]:getChildByTag(100)
		if pre_animLayer then
			pre_animLayer:removeFromParentAndCleanup(true)
		end

		local pre_animLayer_1 = self["spr_gate_num_"..tostring(i)]:getChildByTag(99)
		if pre_animLayer_1 then
			pre_animLayer_1:removeFromParentAndCleanup(true)
		end
	end
	---[[
	--播放light动画	
	local animNodeSize = self["spr_gate_num_"..tostring(openIndex)]:getContentSize()
	self.m_animLayer = createObj(ui_limitTrainAnim, animNodeSize, 2)

	self["spr_gate_num_"..tostring(openIndex)]:addChild(self.m_animLayer.node_)

	self.m_animLayer.node_:setPosition(ccp(-animNodeSize.width * 0.8, -animNodeSize.height * 0.8))
	self.m_animLayer.node_:setAnchorPoint(ccp(0.5, 0.5))
	self.m_animLayer.node_:setTag(100)
	--]]

	local function toDoUpdate()
		self:updateUI()
	end

	local ccArray = CCArray:create()
    ccArray:addObject(CCDelayTime:create(0.4))
    ccArray:addObject(CCCallFuncN:create(toDoUpdate))
	local sequen = CCSequence:create(ccArray)  

    --播放动画
	self["spr_gate_num_"..tostring(openIndex)]:runAction(sequen)
end

function updateUI(self)
	--update UI
	CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile("ccbResources/limitTrain.plist")
	self.label_gold:setString(tostring(self.playerData_.m_gold))
	self.label_silver:setString(tostring(self.playerData_.m_silver))

	self.label_cur_soul:setString(tostring(self.cur_soul))

	self.label_cost_soul:setString(tostring(self.cur_cost_soul))
	self.label_cost_silver:setString(tostring(self.cur_cost_silver))
	self.label_gate_lv:setString("LV:"..tostring(self.cur_gate_level))

	self.label_add_att:setString("+"..tostring(self.add_att))
	self.label_add_def:setString("+"..tostring(self.add_def))
	self.label_add_chakra:setString("+"..tostring(self.add_chakra))

	--att
	if self.add_att_per > 0 then
		self.label_add_att_per:setString("+"..tostring(self.add_att_per/10).."%")
	else
		self.label_add_att_per:setString("0")
	end
	--def
	if self.add_def_per > 0 then
		self.label_add_def_per:setString("+"..tostring(self.add_def_per/10).."%")
	else
		self.label_add_def_per:setString("0")
	end
	--chakra
	if self.add_chakra_per > 0 then
		self.label_add_chakra_per:setString("+"..tostring(self.add_chakra_per/10).."%")
	else
		self.label_add_chakra_per:setString("0")
	end

	--遁甲亮点
	for i=1,8 do
		self["spr_gate_num_"..tostring(self.cur_gate_id)]:setScale(1)
		if i < self.cur_gate_id then
			local frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("limitTrain_open")
			if frame ~= nil then
				self["spr_gate_num_"..tostring(i)]:setDisplayFrame(frame)
			end
		else
			local frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("limitTrain_close")
			if frame ~= nil then
				self["spr_gate_num_"..tostring(i)]:setDisplayFrame(frame)
			end
		end
	end

	local _gate_frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("limitTrain_gate"..tostring(self.cur_gate_id))
	self.spr_gate:setDisplayFrame(_gate_frame)

	self:next_open_gate_tip()

	self._tableView:reloadData()
	--标志
	self.isOpening = false
	--待开启动画
	local animNodeSize = self["spr_gate_num_"..tostring(self.cur_gate_id)]:getContentSize()
	self.m_animLayer = createObj(ui_limitTrainAnim, animNodeSize, 1)

	self["spr_gate_num_"..tostring(self.cur_gate_id)]:addChild(self.m_animLayer.node_)

	self.m_animLayer.node_:setPosition(ccp(-animNodeSize.width * 1.1, -animNodeSize.height * 0.95))
	self.m_animLayer.node_:setAnchorPoint(ccp(0.5, 0.5))
	self.m_animLayer.node_:setTag(99)
end

function init_binding_event(self)
	if self.proxy_ ~= nil then
		local function onBtnBack(btn, event)
			GetMainMenu():ChangeToSub(self.back_page)
		end

		local function onBtnGotoLimitTrain(btn, event)
			--进入极限训练
			GetMainMenu():ChangeToActivitySubMenu("ShowLimitTrainSoulView")
			--self.node_:removeFromParentAndCleanup(true)
		end

		local function onBtnOpen(btn, event)
			--litao_等级限制_2014.7.22
			local _playerData_ = CPlayerDataMgr:instance():GetPlayerInfoData()
			--get info from table_bin
			local config_info_level = DataMgr.GetDataByID("Struct_Functionconfig", 20)
			--判断等级
			if nil ~= config_info_level then 
			    if _playerData_.m_level < tonumber(config_info_level.m_needlevel) then
					GetMainMenu():ShowTextTip(tostring(config_info_level.m_tipinfo), -1)
					return nil
				end
			end

			--银币不足
			local _cur_open_cost_silver = 0
			if self.playerData_.m_silver < self.cur_cost_silver then
				GetMainMenu():ShowTextTip(localizable.ui_attribute_silver_not_enough, -1)
				--购买银票
				ShowCommonBuyItemDialog(kConsumableTypeItem, SMALL_COIN_ITEM_ID, BIG_COIN_ITEM_ID, 0)
				return nil
			else
				_cur_open_cost_silver = self.cur_cost_silver
			end

			if self.isOpening == true then
				GetMainMenu():ShowTextTip(localizable.ui_limitTrainSoul_isDoing, -1)
				return nil
			end

			--开启八门遁甲
			---[[
			local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 2, "rl_w_eight_gate")
			urlpath = AddData(urlpath, "version", 2)
			urlpath = AddData(urlpath, "SrcCardIndex", tostring(_cur_card_bag_id_src))
			--cclog("rl_w_eight_gate & cmd = 2---%s", urlpath)
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
					--cclog("rl_w_eight_gate ret = %s", resData)
					local retcode = item.code
					if retcode == "0" then
						local _basic = item:find("basic")
						if _basic then
							--扣除银子
							self.playerMgr_:AddSilver(-_cur_open_cost_silver)
							self.playerData_ = self.playerMgr_:GetPlayerInfoData()
							self.label_gold:setString(tostring(self.playerData_.m_gold))
							self.label_silver:setString(tostring(self.playerData_.m_silver))	
							--
							self.cur_soul = tonumber(_basic:find("soul")[1])
							self.cur_gate_level = tonumber(_basic:find("gate_level")[1])
							--保存本次开启的门的id
							local pre_gate_id = self.cur_gate_id
							--下一门加成描述
							local cur_gate_data = _basic:find("gate_id")
							self.cur_gate_id = tonumber(cur_gate_data.id)
							if self.cur_gate_id < 1 then
								self.cur_gate_id = 1
							end
							self.m_add_desc_data = {}
							for i=1,#cur_gate_data do
								local item = {}
								item.type = tonumber(cur_gate_data[i].type)
								item.add_num = tonumber(cur_gate_data[i].value)
								table.insert(self.m_add_desc_data, item)
							end

							local _att_add = item:find("attribute")
							if _att_add then
								self.add_att = tonumber(_att_add:find("add_attack")[1])
								self.add_def = tonumber(_att_add:find("add_defense")[1])
								self.add_chakra = tonumber(_att_add:find("add_chakala")[1])
								--self.add_ninjasu_per = tonumber(_att_add:find("add_skill")[1])
								self.add_att_per = tonumber(_att_add:find("add_attack_per")[1])
								self.add_def_per = tonumber(_att_add:find("add_defense_per")[1])
								self.add_chakra_per = tonumber(_att_add:find("add_chakala_per")[1])
							end

							self.cur_cost_soul = tonumber(_basic:find("cost_soul")[1])
							self.cur_cost_silver = tonumber(_basic:find("cost_coin")[1])

							--标志
							self.isOpening = true
							--update ui
							self:playOpenAnim(pre_gate_id)
						end		
					else
						self.isOpening = false
						GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
						--魂不够加号按钮闪烁
						if tonumber(retcode) == 400006 then
							self:playGotoTrainTipAnim()
						end
					end
				end)
	            --]]
		end

		self.btn_back:setTouchPriority(kCCMenuHandlerPriority-1)
		self.btn_back:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btn_back, function(button, event)
			onBtnBack(button)
			return nil
		end, CCControlEventTouchDown)

		self.btn_limitTrain:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.btn_limitTrain:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btn_limitTrain, function(button, event)
			onBtnGotoLimitTrain(button)
			return nil
		end, CCControlEventTouchDown)

		self.btn_open:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.btn_open:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btn_open, function(button, event)
			onBtnOpen(button)
			return nil
		end, CCControlEventTouchDown)
	end
end

function onNodeCleanup(self)
	if self.proxy_ then
    	self.proxy_:release()
    end

    layer_base_t.onNodeCleanup(self)
end