--descriptioin:7_days
--company: xckoo
--litao
--2014.4.11
---------------------------------------------
require("config/firstpurchase_config")
require("ui_layer/ui_purchaseLayer")
require("ui_layer/ui_purchaseTableCell")

module("ui_sevenDayView", package.seeall)
baseClass(layer_base_t, ui_sevenDayView)

function init(self, node, cur_index)
	self.contentNode_ = GetActivityView():GetNodeContent()
	self.contentSize_ = self.contentNode_:getContentSize()

	local ccbiAttrTable = {name="activity/SevenDayPlanView.ccbi", size=self.contentSize_}
	layer_base_t.init(self, true, ccbiAttrTable)

	--用户info
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	--pre info
	self.preNode = node
	self.login_days = CPlayerDataMgr:instance():GetTotalLoginDay()
	self.cur_day_index = CPlayerDataMgr:instance():GetTotalLoginDay()

	--data
	self.m_planDatas = {}
	--spr data
	self.m_spr_planDatas = {}
	--tableView cell container
	self.cellNodes = {}
	self.spr_cellNodes = {}
	--
	self.m_awardDatas = {}
	--touch
	self.m_touchPoint = nil
	self.m_touchBegan = nil
	self.m_touchEnd = nil
	--奖励是否过期
	self._award_overdue = false

	--create data
	--self:createData()

	--init
	self:init_ui()		
	self:init_binding_event()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		--spr
		self.spr_lock = tolua.cast(self.proxy_:getNode("spr_lock"), "CCSprite")
		self.spr_got = tolua.cast(self.proxy_:getNode("spr_got"), "CCSprite")
		self.btn_get_award = tolua.cast(self.proxy_:getNode("btn_get_award"), "CCSprite")

		self.spr_pre_arrow = tolua.cast(self.proxy_:getNode("spr_pre_arrow"), "CCSprite")
		self.spr_next_arrow = tolua.cast(self.proxy_:getNode("spr_next_arrow"), "CCSprite")

		for i=1,3 do
			self["spr_gift_icon_"..i] = tolua.cast(self.proxy_:getNode("sprite_gift_icon_"..i), "CCSprite")
		end

		--btn		
		for i=1,3 do
			self["btn_award_"..i] = tolua.cast(self.proxy_:getNode("btn_award_"..i), "CCControlButton")
		end
		--label
		self.label_day_left = tolua.cast(self.proxy_:getNode("label_day_left"), "CCLabelTTF")
		self.label_btn_get = tolua.cast(self.proxy_:getNode("label_btn_get"), "CCLabelTTF")
		self.label_lock = tolua.cast(self.proxy_:getNode("label_login_num_to_lock"), "CCLabelTTF")
		self.label_get_award_day_left = tolua.cast(self.proxy_:getNode("label_get_award_day_left"), "CCLabelTTF")

		for i=1,3 do
			self["label_num_"..i] = tolua.cast(self.proxy_:getNode("label_num_"..i), "CCLabelTTF")
		end
		--node
		self.node_content = tolua.cast(self.proxy_:getNode("node_content"), "CCNode")
		self.node_cell = tolua.cast(self.proxy_:getNode("node_cell"), "CCNode")
		self.spr_node_content = tolua.cast(self.proxy_:getNode("spr_node_content"), "CCNode")
		self.spr_node_cell = tolua.cast(self.proxy_:getNode("spr_node_cell"), "CCNode")

		--
		if self.cur_day_index <= 0 then
			self.cur_day_index = 1 
		elseif self.cur_day_index > 7 then
			self.cur_day_index = 7
		end

		local config_info_days = DataMgr.GetDataByID("Struct_Functionconfig", 13)
		if nil ~= config_info_days then
			self.label_day_left:setString(string.format(localizable.ui_seven_day_tips1, tostring(tonumber(config_info_days.m_needlevel) - self.login_days)))
		else 
			self.label_day_left:setString(string.format(localizable.ui_seven_day_tips1, tostring(8 - self.login_days)))
		end

		--get info
		self:getSevenDayData()
	end
end

function getSevenDayData(self)
	---[[
	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 9002, "rl_r_activity")
	--cclog("getSevenDayData----%s", urlpath)

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
				--
				local seven_target = item:find("seven_target")
				if seven_target then
					self.m_planDatas = {}
					for i=1,#seven_target do
						local t_item = {}
						t_item._index = tonumber(seven_target[i]:find("day")[1])
						if t_item._index == self.cur_day_index then
							t_item._focus = true
						else
							t_item._focus = false
						end
						t_item._reward = tonumber(seven_target[i]:find("reward")[1])
						t_item._planData = seven_target[i]:find("tlist")
						table.insert(self.m_planDatas, t_item)
					end
				end

				if self.m_planDatas then
					self:init_ext_ui()
				end
			else
				GetMainMenu():ShowTextTip(tostring(item.msg),-1)
			end
		end)	
end

function init_ext_ui(self)	
	--卡牌列表
	self:createPicTableView()
	--任务列表
	self:createPlanTableView()
	--奖励
	self:set_award_info()
end

function createPicTableView(self)
	if self._spr_tableView == nil then
		local cellContentSize = self.spr_node_cell:getContentSize()
		self._spr_cell_size = CCSizeMake(cellContentSize.width,cellContentSize.height)

		self._spr_content_size = self.spr_node_content:getContentSize()
		self:initPicTableHandle()
		self._spr_tableView = LuaTableView:createWithHandler(self._spr_tableViewHandler, CCSizeMake(self._spr_content_size.width, self._spr_content_size.height))
		self._spr_tableView:setDirection(kCCScrollViewDirectionHorizontal)
		self._spr_tableView:setVerticalFillOrder(kCCTableViewFillTopDown)
		self._spr_tableView:setTouchPriority(kCCMenuHandlerPriority - 1)

		local _offset = -(self.cur_day_index - 2) * self._spr_cell_size.width
		self._spr_tableView:setContentOffset(_offset, 0)

		self.spr_node_content:addChild(self._spr_tableView)
	else
		self._spr_tableView:reloadData()
	end
end

function initPicTableHandle(self)
	self._spr_tableViewHandler = LuaEventHandler:create(function(fn, table, a1, a2, x, y)
		local r
		if fn == "cellSize" then
			r = self._spr_cell_size;
		elseif fn == "cellAtIndex" then
    		local nodeLayer = createObj(ui_sevenDaySprCell, self._spr_cell_size, self.m_planDatas[a1 + 1])
			--tableView cell container
			self.spr_cellNodes[a1+1] = nodeLayer
			if not a2 then
				a2 = CCTableViewCell:create()
				a2:addChild(nodeLayer.node_)
			else
				a2:removeAllChildrenWithCleanup(true)
        		a2:addChild(nodeLayer.node_)
			end

			nodeLayer.node_:setTag(100)

			r = a2
		elseif fn == "numberOfCells" then
			r = #self.m_planDatas;
		    -- Cell events:
		elseif fn == "cellTouched" then			-- A cell was touched, a1 is cell that be touched. This is not necessary.
			---[[
			local cell_index = a1:getIdx() + 1
			local _layer = a1:getChildByTag(100)

			if self.spr_cellNodes[cell_index].spr_pic_day:boundingBox():containsPoint(self.m_touchPoint) then
				if math.abs(self.spr_cellNodes[cell_index].cellData._index - self.cur_day_index) <= 1 then
					self.cur_day_index = self.spr_cellNodes[cell_index].cellData._index
					self:sprTableSlide()
					self:updateInfo()
				end
			end

			self.m_touchPoint = nil
			--]]
		elseif fn == "cellTouchBegan" then		-- A cell is touching, a1 is cell, a2 is CCTouch
			self.m_touchPoint = a2:getLocation()
			self.m_touchPoint = a1:convertToNodeSpace(self.m_touchPoint)

			local cell_index = a1:getIdx() + 1

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

function createPlanTableView(self)
	if self._tableView == nil then
		local cellContentSize = self.node_cell:getContentSize()
		self._cell_size = CCSizeMake(cellContentSize.width,cellContentSize.height)

		self._content_size = self.node_content:getContentSize()
		self:initPlanTableHandle()
		self._tableView = LuaTableView:createWithHandler(self._tableViewHandler, CCSizeMake(self._content_size.width, self._content_size.height))
		self._tableView:setDirection(kCCScrollViewDirectionVertical)
		self._tableView:setVerticalFillOrder(kCCTableViewFillTopDown)
		self._tableView:setTouchPriority(kCCMenuHandlerPriority - 1)

		self.node_content:addChild(self._tableView)
	else
		self._tableView:reloadData()
	end
end

function initPlanTableHandle(self)
	self._tableViewHandler = LuaEventHandler:create(function(fn, table, a1, a2, x, y)
		local r
		if fn == "cellSize" then
			r = self._cell_size;
		elseif fn == "cellAtIndex" then
    		local nodeLayer = createObj(ui_sevenDayCell, self._cell_size, self.m_planDatas[self.cur_day_index]._planData[a1 + 1])
			--tableView cell container
			self.cellNodes[a1+1] = nodeLayer
			if not a2 then
				a2 = CCTableViewCell:create()
				a2:addChild(nodeLayer.node_)
			else
				a2:removeAllChildrenWithCleanup(true)
        		a2:addChild(nodeLayer.node_)
			end
			r = a2
		elseif fn == "numberOfCells" then
			r = #self.m_planDatas[self.cur_day_index]._planData
		    -- Cell events:
		elseif fn == "cellTouched" then			-- A cell was touched, a1 is cell that be touched. This is not necessary.
			---[[
			local cell_index = a1:getIdx() + 1
			local cellData = self.m_planDatas[self.cur_day_index]._planData[cell_index]
			self.cellNodes[cell_index].btn_goto:setScale(1)
			if self.cellNodes[cell_index].btn_goto:boundingBox():containsPoint(self.m_touchPoint) then
				if tonumber(cellData:find("st")[1]) == 0 then
					self:OnBtnGoto(cell_index)
				end
				self.m_touchPoint = nil   
			end
			--]]
		elseif fn == "cellTouchBegan" then		-- A cell is touching, a1 is cell, a2 is CCTouch
			self.m_touchPoint = a2:getLocation()
			self.m_touchPoint = a1:convertToNodeSpace(self.m_touchPoint)

			local cell_index = a1:getIdx() + 1
			local cellData = self.m_planDatas[self.cur_day_index]._planData[cell_index]
			if self.cellNodes[cell_index].btn_goto:boundingBox():containsPoint(self.m_touchPoint) then
				self.cellNodes[cell_index].btn_goto:setScale(1.1)  
			end

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

function set_award_info(self)
	--assert
	if self.cur_day_index < 1 or self.cur_day_index > 7 then
		return nil
	end

	if self.cur_day_index == 1 then
		local pProgram = CCShaderCache:sharedShaderCache():programForKey("greysprite")
		self.spr_pre_arrow:setShaderProgram(pProgram)
	elseif self.cur_day_index == 7 then
		local pProgram = CCShaderCache:sharedShaderCache():programForKey("greysprite")
		self.spr_next_arrow:setShaderProgram(pProgram)
	else
		local pre_program = CCShaderCache:sharedShaderCache():programForKey("ShaderPositionTextureColor")
		self.spr_pre_arrow:setShaderProgram(pre_program)
		local next_program = CCShaderCache:sharedShaderCache():programForKey("ShaderPositionTextureColor")
		self.spr_next_arrow:setShaderProgram(next_program)
	end

	self.m_awardDatas = {}
	--get info from table_bin
	local award_info = DataMgr.GetDataByID("Struct_Sevendays_Info", self.cur_day_index)
	local t_obj_1 = {}
	t_obj_1._id = tonumber(award_info.m_sevendays_drop1)
	t_obj_1._iconName = award_info.m_sevendays_pic1
	t_obj_1._num = tonumber(award_info.m_sevendays_dropnum1) 
	table.insert(self.m_awardDatas, t_obj_1)

	if award_info.m_sevendays_drop2 > 0 then
		local t_obj_2 = {}
		t_obj_2._id = tonumber(award_info.m_sevendays_drop2)
		t_obj_2._iconName = award_info.m_sevendays_pic2
		t_obj_2._num = tonumber(award_info.m_sevendays_dropnum2) 
		table.insert(self.m_awardDatas, t_obj_2)
	end

	if award_info.m_sevendays_drop3 > 0 then
		local t_obj_3 = {}
		t_obj_3._id = tonumber(award_info.m_sevendays_drop3)
		t_obj_3._iconName = award_info.m_sevendays_pic3
		t_obj_3._num = tonumber(award_info.m_sevendays_dropnum3) 
		table.insert(self.m_awardDatas, t_obj_3)
	end

	--init icon
	for i=1,3 do --#self.m_awardDatas
		local _icon = self["spr_gift_icon_"..tostring(i)]:getChildByTag(100)
		if _icon then
			_icon:removeFromParentAndCleanup(true)
		end

		if i <= #self.m_awardDatas then
			local _itemInfo = ItemDataInfo:new()
			CGameObjElement:GetItemInfoByDropid(tonumber(self.m_awardDatas[i]._id), _itemInfo)
			--物品图标frame
			local _pIcon, _iconFrame = rl_get_iconsprite(_itemInfo.mainType, _itemInfo.subType, E_FRAMETYPE_SMALL, _itemInfo.itemId)
			if nil ~= _iconFrame then
				self["spr_gift_icon_"..tostring(i)]:setDisplayFrame(_iconFrame)
			end

			CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile("props/"..self.m_awardDatas[i]._iconName..".plist")
			local pFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(self.m_awardDatas[i]._iconName)
			if pFrame ~= nil then
				local pIcon = CCSprite:createWithSpriteFrame(pFrame);
				local size = self["spr_gift_icon_"..tostring(i)]:getContentSize()
				if pIcon ~= nil then
					self["spr_gift_icon_"..tostring(i)]:addChild(pIcon)
					pIcon:setPosition(ccp(size.width/2, size.height/2))
					pIcon:setAnchorPoint(ccp(0.5, 0.5))
					pIcon:setTag(100)
				end
			end

			--label
			self["label_num_"..i]:setTag(101)
			self["label_num_"..i]:setVisible(true)
			self["label_num_"..i]:setString(tostring("x"..self.m_awardDatas[i]._num))
		else
			self["label_num_"..i]:setTag(101)
			self["label_num_"..i]:setVisible(false)
		end
	end

	self:setLockInfo() 
end

function retCurDayPlanIsFinished(self, _index)
	--
	for i=1,#self.m_planDatas[_index]._planData do
		local _data = self.m_planDatas[_index]._planData[i]
		if tonumber(_data:find("st")[1]) == 0 then
			return false
		end
	end

	return true
end

function setLockInfo(self)
	--重置奖励是否过期
	self._award_overdue = false
	--奖励信息
	if self.login_days >= self.m_planDatas[self.cur_day_index]._index then
		self.label_lock:setVisible(false)
		self.spr_lock:setVisible(false)	
		--增加奖励过期提示
		self.label_get_award_day_left:setVisible(true)
		if self.login_days == self.m_planDatas[self.cur_day_index]._index then
			self.label_get_award_day_left:setString(localizable.ui_seven_day_2day_left)
		elseif self.login_days == self.m_planDatas[self.cur_day_index]._index + 1 then
			self.label_get_award_day_left:setString(localizable.ui_seven_day_1day_left)
		elseif self.login_days > self.m_planDatas[self.cur_day_index]._index + 1 then--已经过期
			self.label_get_award_day_left:setString(localizable.ui_seven_day_award_lost)
			self._award_overdue = true
		end	

		if self.m_planDatas[self.cur_day_index]._reward == 0 then       --未领取
			if self:retCurDayPlanIsFinished(self.cur_day_index) == false or self._award_overdue == true then   --不能领取
				self.btn_get_award:setVisible(true)
				self.label_btn_get:setVisible(true)
				local pProgram = CCShaderCache:sharedShaderCache():programForKey("greysprite")
				self.btn_get_award:setShaderProgram(pProgram)

				self.spr_got:setVisible(false)
			else     --可领取但是没有领取
				self.btn_get_award:setVisible(true)
				self.label_btn_get:setVisible(true)
				self.spr_got:setVisible(false)
				local program = CCShaderCache:sharedShaderCache():programForKey("ShaderPositionTextureColor")
				self.btn_get_award:setShaderProgram(program)
			end
		elseif self.m_planDatas[self.cur_day_index]._reward == 1 then   --已领取
			self.btn_get_award:setVisible(false)
			self.label_btn_get:setVisible(false)
			self.spr_got:setVisible(true)
		end
	else
		self.label_get_award_day_left:setVisible(false)
		self.spr_got:setVisible(false)
		self.spr_lock:setVisible(true)
		self.label_btn_get:setVisible(true)
		self.btn_get_award:setVisible(true)
		local pProgram = CCShaderCache:sharedShaderCache():programForKey("greysprite")
		self.btn_get_award:setShaderProgram(pProgram)

		self.label_lock:setVisible(true)
		self.label_lock:setString(string.format(localizable.ui_seven_day_tips2, tostring(self.m_planDatas[self.cur_day_index]._index)))
	end
end

function updateInfo(self)
	if self.cur_day_index < 1 or self.cur_day_index > 7 then
		return nil
	end

	--刷新数据
	if self._tableView ~= nil then
		local offset = self._tableView:getContentOffset()
		self._tableView:reloadData()
	end

	self:set_award_info()

	return nil
end

--获取礼包数据
function OnBtnGoto(self, _id)
	---[[
	local _data = self.m_planDatas[self.cur_day_index]._planData[_id]
	if _data then
		local quest_info = DataMgr.GetDataByID("Struct_Sevendays_Quest", tonumber(_data:find("id")[1]))
		self:gotoLayerByName(tonumber(quest_info.m_sevendays_quest_tape))
	end
	--]]
end

function getIntPart(self, x)
    if x <= 0 then
       return 0
    end

    if math.abs(math.ceil(x) - x) < 0.005 then
       x = math.ceil(x)
    else
       x = math.ceil(x) - 1
    end
    return x
end

function init_binding_event(self)
	if self.proxy_ ~= nil then
		local function onBtnGetAward()
			--btn sound
			CSoundMgr:instance():PlayEffect(SOUND_BUTTON)

			if self.m_planDatas[self.cur_day_index]._reward == 1 then
				return nil
			end

			--登录天数不够
			if self.login_days < self.cur_day_index then
				GetMainMenu():ShowTextTip(localizable.ui_seven_day_tips3, -1)
				return nil
			end

			--奖励已经过期
			if self._award_overdue == true then
				GetMainMenu():ShowTextTip(localizable.ui_seven_day_award_lost, -1)
				return nil
			end

			---[[得到奖励
			local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 9100, "rl_w_activity")
			urlpath = AddData(urlpath, "ActType", 7)
			urlpath = AddData(urlpath, "ActID", self.cur_day_index)
			cclog("onBtnGetAward---%s", urlpath)
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
					local retcode = item.code
					if retcode == "0" then
						---[[	
						local awardXML = xfile:find("award")		
						ShowAward(awardXML)			
						GetMainMenu():ShowTextTip(localizable.ui_seven_day_tips4,-1)					
					
						--重新拉取一次数据
						self.playerData_ = self.playerMgr_:GetPlayerInfoData()
						self:getSevenDayData()
					else
						--通过错误码提示信息
						--GetMainMenu():ShowTextTip(tostring(retcode), -1)
						GetMainMenu():ShowErrorTip(retcode,-1)
					end
				end)
		end

		--重写相应的触摸函数
		local function onTouchBegan(x, y)
		    self.m_touchBegan = CCPointMake(x,y)
			return true
		end

		local function onTouchMoved(x, y)
		end

		local function onTouchEnded(x, y)
			if self.m_touchBegan == nil then
				return nil
			end

			self.m_touchEnd = ccp(x,y)
			if self.m_touchEnd.x ~= self.m_touchBegan.x then
				self._spr_tableView:unscheduleAllSelectors()
				--local offset = self._spr_tableView:getContentOffset()

				if self.m_touchEnd.x - self.m_touchBegan.x < -50 then--向左滑动
					if self.cur_day_index < #self.m_planDatas then
						self.cur_day_index = self.cur_day_index + 1
					end
				elseif self.m_touchEnd.x - self.m_touchBegan.x > 50 then--向右滑动
					if self.cur_day_index > 1 then
						self.cur_day_index = self.cur_day_index - 1
					end
				else
				    --不超过50则默认是点击
				end

				self:sprTableSlide()
				--[[
				for i=1,#self.m_planDatas do
					if self.cur_day_index == self.m_planDatas[i]._index then
						self.m_planDatas[i]._focus = true
					else
						self.m_planDatas[i]._focus = false
					end
				end

				self._spr_tableView:reloadData()
				self._spr_tableView:setContentOffset(offset.x, offset.y)

				local targetCardOffsetX = -(self.cur_day_index - 2) * self._spr_cell_size.width
				--local adjustAnimDelay = 0.5
				self._spr_tableView:setContentOffsetInDuration(ccp(targetCardOffsetX, 0), 0.5)
				--]]
			end

			--refresh data
			self:updateInfo()
		end

		--屏蔽掉后层触摸事件
		local function CCLayerTouch(event, x, y)
			local rect = self.node_:boundingBox()
			rect.origin = ccp(0,0)
			local p = self.node_:convertToNodeSpace(ccp(x,y))	
			--截获界面内后层的信息
			if rect:containsPoint(p) ==  true then
				local _cur_Node = self.spr_node_content:boundingBox()		
				local cur_p = self.spr_node_content:convertToNodeSpace(ccp(x,y))
				if event == "began" then
					--领奖btn
					if self.btn_get_award:boundingBox():containsPoint(p) then
						if self.m_planDatas[self.cur_day_index]._reward == 0 then
							onBtnGetAward()
						end		
					else
						--判断滑动区域							
						_cur_Node.origin = ccp(0,0)								
						if _cur_Node:containsPoint(cur_p) == true then				
							onTouchBegan(x,y)
						end
					end
					
				 	return true
				elseif event == "moved" then
					if _cur_Node:containsPoint(cur_p) == true then				
						return onTouchMoved(x,y)
					end
				else			
					return onTouchEnded(x,y)
				end
			else
				return false
			end		
		end

		self.node_:setTouchEnabled(true)
		self.node_:registerScriptTouchHandler(CCLayerTouch, false, kCCMenuHandlerPriority-1, true)

		--奖励详情
		local function onBtnClickAwardIcon(btn)
			CSoundMgr:instance():PlayEffect(SOUND_BUTTON)
			local btnIndex = btn:getTag()

			if btnIndex > #self.m_awardDatas then
				return nil
			end

			if btnIndex > 0 and btnIndex <= 3 then
				local _id_icon = tonumber(self.m_awardDatas[btnIndex]._id)
				if nil ~= _id_icon then
					CGameObjElement:ShowDropByID(_id_icon)
				end
			end
		end

		for i=1,3 do
			self["btn_award_"..i]:setTouchPriority(kCCMenuHandlerPriority - 1)
			self["btn_award_"..i]:setTouchEnabled(true)
			self.proxy_:handleButtonEvent(self["btn_award_"..i], function(button, event)
				onBtnClickAwardIcon(button)
				return nil
			end, CCControlEventTouchDown)
		end
	end
end

function sprTableSlide(self)
	--offset
	local offset = self._spr_tableView:getContentOffset()
	--focus
	for i=1,#self.m_planDatas do
		if self.cur_day_index == self.m_planDatas[i]._index then
			self.m_planDatas[i]._focus = true
		else
			self.m_planDatas[i]._focus = false
		end
	end

	self._spr_tableView:reloadData()
	self._spr_tableView:setContentOffset(offset.x, offset.y)

	local targetCardOffsetX = -(self.cur_day_index - 2) * self._spr_cell_size.width
	--cclog("change offset = %d", math.abs(targetCardOffsetX))
	--local adjustAnimDelay = 0.5
	self._spr_tableView:setContentOffsetInDuration(ccp(targetCardOffsetX, 0), 0.5)

	self.m_touchBegan = nil
	self.m_touchEnd = nil
end

function onNodeCleanup(self)
	if self.proxy_ then
    	self.proxy_:release()
    end

    layer_base_t.onNodeCleanup(self)
end

function gotoLayerByName(self, _index)
	if _index == 1 then--历练升级exp
		GetMainMenu():ChangeToSub(E_GAMEROUND)
	elseif _index == 2 then--队伍最高级忍者等级
		GetMainMenu():ChangeToSub(E_GAMEGROUPVIEW)
	elseif _index == 3 then--玩家VIP
		--GetMainMenu():ChangeToSub(E_STOREITEMSVIEW)
		local puchaseLayer = createObj(ui_purchaseLayer)
		GetMainMenu():GetModelLayer():AddDialog(puchaseLayer.node_, 3)
	elseif _index == 4 then--忍者淬炼等级
		GetMainMenu():ChangeToSub(E_STRENGTHVIEW)
	elseif _index == 5 then--通过历练关卡
		GetMainMenu():ChangeToSub(E_GAMEROUND)
	elseif _index == 6 then--忍阶等级(武勋)
		GetMainMenu():ChangeToSub(E_FIGHTLISTEVIEW)
	elseif _index == 7 then--闯关
		GetMainMenu():ChangeToSub(E_TOWERVIEW)
	elseif _index == 8 then--竞技场
		GetMainMenu():ChangeToSub(E_ARENAVIEW)
	elseif _index == 9 then--队伍最大攻击力
		GetMainMenu():ChangeToSub(E_GAMEGROUPVIEW)
	elseif _index == 10 then--队伍最大防御力
		GetMainMenu():ChangeToSub(E_GAMEGROUPVIEW)
	elseif _index == 11 then--拥有1转紫卡的数量
		GetMainMenu():ChangeToSub(E_REINCARNATIONVIEW)
	elseif _index == 12 then--累积上交国家宝藏数量
		GetMainMenu():ChangeToSub(E_COUNTRYTREASURE)
	elseif _index == 13 then--50级忍者数量
		GetMainMenu():ChangeToSub(E_GAMEGROUPVIEW)
	elseif _index == 14 then--拥有X个1转忍者(占坑）
		GetMainMenu():ChangeToSub(E_REINCARNATIONVIEW)
	elseif _index == 15 then--拥有X个2转忍者(占坑）
		GetMainMenu():ChangeToSub(E_REINCARNATIONVIEW)
	elseif _index == 16 then--拥有X个3转忍者(占坑）
		GetMainMenu():ChangeToSub(E_REINCARNATIONVIEW)
	end
end

--创建测试数据
function createData(self)
	---[[
	for i=1,5 do
		local tempdata = {}
		tempdata.plan_desc = tostring("plan:等级达到"..i.."级")
		tempdata.isDone = true
		table.insert(self.m_planDatas, tempdata)
	end

	for i=1,7 do
		local spr_t_data = {}
		spr_t_data._index = i
		table.insert(self.m_spr_planDatas, spr_t_data)
	end
	--]]
end