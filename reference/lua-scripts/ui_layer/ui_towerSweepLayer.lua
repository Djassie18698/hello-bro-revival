--descriptioin:闯关扫荡
--company: xckoo
--litao
--2014.5.6
---------------------------------------------
module("ui_towerSweepLayer", package.seeall)
baseClass(layer_base_t, ui_towerSweepLayer)

function init(self, node, cur_index)
	self.contentSize_ = GetMainMenu():GetModelLayer():getContentSize()

	local ccbiAttrTable = {name="sub_ui/TowerSweepView.ccbi", size=self.contentSize_}
	layer_base_t.init(self, true, ccbiAttrTable)

	--用户info
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	--pre info
	self.preNode = node

	--tableView cell container
	self.cellNodes = {}
	--data
	self.m_levelDatas = {}
	--sweep_selected
	self.m_selectedDatas = {}
	--
	self.m_awardDatas = {}
	--touch
	self.m_touchPoint = nil
	--is all selected
	self.isAllSelected = false

	--create data
	--self:createData()

	--init
	self:init_ui()		
	self:init_binding_event()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		--label
		self.label_select_num = tolua.cast(self.proxy_:getNode("label_select_num"), "CCLabelTTF")
		self.label_left_sweep_times = tolua.cast(self.proxy_:getNode("label_left_sweep_times"), "CCLabelTTF")
		self.label_next_vip = tolua.cast(self.proxy_:getNode("label_next_vip"), "CCLabelTTF")
		--node
		self.node_content = tolua.cast(self.proxy_:getNode("node_content"), "CCNode")
		self.node_cell = tolua.cast(self.proxy_:getNode("node_cell"), "CCNode")
		self.node_touch_all_select = tolua.cast(self.proxy_:getNode("node_touch_all_select"), "CCNode")
		self.node_touch_all_select:setScale(1.1)
		--spr
		self.spr_selectall = tolua.cast(self.proxy_:getNode("spr_selectall"), "CCSprite")
		self.spr_selectall:setVisible(false)
		--btn
		self.btn_sweep = tolua.cast(self.proxy_:getNode("leftButton"), "CCControlButton")
		self.btn_cancel = tolua.cast(self.proxy_:getNode("rightButton"), "CCControlButton")
		self.btn_close_dlg = tolua.cast(self.proxy_:getNode("closeButton"), "CCControlButton")

		--get info
		self:getLevelData()
	end
end

function getLevelData(self)
	---[[
	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 7002, "rl_r_dup")
	--cclog("rl_r_dup----%s", urlpath)

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
				local dup_count = item:find("dup_count")
				if dup_count then
					self.total_sweep_nums = tonumber(dup_count:find("total")[1])
					self.left_sweep_nums = tonumber(dup_count:find("remain")[1])
					self.vip_add_nums = tonumber(dup_count:find("vip")[1])
				end

				local dup_list = item:find("dup_list")
				if dup_list then
					local t_level_datas = {}
					for i=1, #dup_list do
						local t_item = {}
						t_item.id = i
						t_item.bSelected = false
						t_item.name = tostring(dup_list[i].name)
						t_item.select_status = tonumber(dup_list[i].selectable)
						table.insert(t_level_datas, t_item)
					end

					--重新排列数据结构/每4个作一个子table
					self.m_levelDatas = {}
					local index = 0
					for i = 1, #t_level_datas do
						local inpart, decimal = tools.getIntAndDecimal(i / 4)
						if decimal == 0 then
							index = inpart
						else
							index = inpart + 1
						end
						self.m_levelDatas[index] = self.m_levelDatas[index] or {}
						table.insert(self.m_levelDatas[index], t_level_datas[i])
					end		
				end

				if self.m_levelDatas then
					self:init_ext_ui()
				end
			else
				GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
			end
		end)	
end

function init_ext_ui(self)	
	self.label_select_num:setString(localizable.ui_tower_sweep_tips1)
	self.label_left_sweep_times:setString(localizable.ui_tower_sweep_tips2..self.left_sweep_nums.."/"..self.total_sweep_nums)
	if self.vip_add_nums > 0 then
		self.label_next_vip:setString(string.format(localizable.ui_tower_sweep_tips3, tostring(self.vip_add_nums)))
	else
		self.label_next_vip:setString(localizable.ui_tower_sweep_tips4)
	end
	--列表
	self:createTableView()
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
    		local nodeLayer = createObj(ui_towerSweepCell, self._cell_size, self.m_levelDatas[a1 + 1])
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
			r = #self.m_levelDatas
		    -- Cell events:
		elseif fn == "cellTouched" then			-- A cell was touched, a1 is cell that be touched. This is not necessary.
			---[[
			local cell_index = a1:getIdx() + 1
			local cellData = self.m_levelDatas[cell_index]

			for i=1, #self.m_levelDatas[cell_index] do
				--local _select = tolua.cast(self.cellNodes[cell_index].proxy_:getNode("spr_select_"..i), "CCSprite")
				local _selectNode = tolua.cast(self.cellNodes[cell_index].proxy_:getNode("node_content_"..i), "CCNode")
				--local p = _selectNode:convertToNodeSpace(self.m_touchPoint)
				if _selectNode:boundingBox():containsPoint(self.m_touchPoint) then
					--cclog("px = %s, py = %s",cell_index, i)
					self:onClickSelectFrame(cell_index, i)				
					break
				end
			end

			self.m_touchPoint = nil  
			--]]
		elseif fn == "cellTouchBegan" then		-- A cell is touching, a1 is cell, a2 is CCTouch
			self.m_touchPoint = a2:getLocation()	
			self.m_touchPoint = a1:convertToNodeSpace(self.m_touchPoint)
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

function onClickSelectFrame(self, _index, _sub_index)
	if _index > 0 and _sub_index > 0 then
		if 2 == self.m_levelDatas[_index][_sub_index].select_status then 
			local _t_selected = {}
			_t_selected._id_level = tonumber((_index - 1) * 4 + _sub_index)

			if nil == self.m_selectedDatas then
				self.m_selectedDatas = {}
			end
			
			--已选则删除
			if self.m_levelDatas[_index][_sub_index].bSelected then
				self.m_levelDatas[_index][_sub_index].bSelected = false
				for i=1,#self.m_selectedDatas do
					if nil ~= self.m_selectedDatas[i] then
						if self.m_selectedDatas[i]._id_level == _t_selected._id_level then
							table.remove(self.m_selectedDatas, i)
							break
						end
					end
				end
			else
				table.insert(self.m_selectedDatas, _t_selected)
				self.m_levelDatas[_index][_sub_index].bSelected = true
			end
			--刷新界面
			self.isAllSelected = false
			self:updateInfo()
		elseif 1 == self.m_levelDatas[_index][_sub_index].select_status then
			GetMainMenu():ShowTextTip(localizable.ui_tower_sweep_tips5, -1)
		else
			GetMainMenu():ShowTextTip(localizable.ui_tower_sweep_tips6, -1)
		end
	end
end

function updateInfo(self)
	local _num = 0
	if #self.m_selectedDatas > 0 then
		_num = #self.m_selectedDatas
	end
	self.label_select_num:setString(string.format(localizable.ui_tower_sweep_tips7, tostring(_num)))
	--刷新数据
	if self._tableView ~= nil then
		local offset = self._tableView:getContentOffset()
		self._tableView:reloadData()
	end
	--
	self.spr_selectall:setVisible(self.isAllSelected)

	return nil
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

function doAllSelect(self)
	--
	if self.isAllSelected then
		self.isAllSelected = false
	else
		self.isAllSelected = true
	end
	self.spr_selectall:setVisible(self.isAllSelected)
	--
	if self.isAllSelected == false then
		for i=1, #self.m_levelDatas do
			for j=1,#self.m_levelDatas[i] do
				self.m_levelDatas[i][j].bSelected = self.isAllSelected
			end
		end
		self.m_selectedDatas = {}
		GetMainMenu():ShowTextTip(localizable.ui_tower_sweep_tips8, -1)
	else
		self.m_selectedDatas = {}
		for i=1, #self.m_levelDatas do
			for j=1,#self.m_levelDatas[i] do
				if 2 == self.m_levelDatas[i][j].select_status then
					local _t_selected = {}
					_t_selected._id_level = tonumber((i - 1) * 4 + j)
					table.insert(self.m_selectedDatas, _t_selected)
					self.m_levelDatas[i][j].bSelected = self.isAllSelected
				end
			end
		end

		local num = #self.m_selectedDatas
		GetMainMenu():ShowTextTip(string.format(localizable.ui_tower_sweep_tips9, tostring(num)), -1)
	end
	
	--刷新界面
	self:updateInfo()
end

function init_binding_event(self)
	if self.proxy_ ~= nil then
		--重写相应的触摸函数
		local function onTouchEnded(x, y)
			--local rect = self.node_:boundingBox()
			--rect.origin = ccp(0,0)
			local p = self.spr_selectall:convertToNodeSpace(ccp(x,y))
			local s_p = self.node_touch_all_select:convertToNodeSpace(ccp(x,y))
			if self.node_touch_all_select:boundingBox():containsPoint(s_p) then --self.spr_selectall:boundingBox():containsPoint(p) or 
				self:doAllSelect()
			end
		end

		--屏蔽掉后层触摸事件
		local function CCLayerTouch(event, x, y)
			if event == "began" then
				return true
			elseif event == "moved" then
				return true
			else	
				return onTouchEnded(x,y)
			end
		end

		local function onBtnClose(btn, event)
			GetMainMenu():ChangeToSub(E_DEFAULTMENU)
			self.node_:removeFromParentAndCleanup(true)
		end

		local function onBtnSweep(btn, event)
			--btn sound
			CSoundMgr:instance():PlayEffect(SOUND_BUTTON)
			
			if #self.m_selectedDatas < 1 then
				GetMainMenu():ShowTextTip(localizable.ui_tower_sweep_tips10, -1)
				return nil
			end

			if #self.m_selectedDatas > self.left_sweep_nums then
				GetMainMenu():ShowTextTip(localizable.ui_tower_sweep_tips11, -1)
				return nil
			end

			local str_sweep_id = tostring(self.m_selectedDatas[1]._id_level)
			for i = 2, #self.m_selectedDatas do
				str_sweep_id = tostring(str_sweep_id.."|"..self.m_selectedDatas[i]._id_level)
			end

			---[[得到奖励
			local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 3102, "rl_w_dup")
			urlpath = AddData(urlpath, "DupId", tostring(str_sweep_id))
			--cclog("rl_w_dup_sweep---%s", urlpath)
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
					--cclog("%s", resData)
					local retcode = item.code
					if retcode == "0" then
						---[[	
						local dup_award_list = xfile:find("dup_list")
						if nil ~= dup_award_list then
							self.m_awardDatas = {}
							for i=1,#dup_award_list do
								local awardXML = dup_award_list[i]:find("award")
								--只加入背包不显示掉落动画		
								AddSoulAwardData(awardXML)	
								--获取award中信息
								local t_awardIconDatas = {}
								t_awardIconDatas = InitAwardIconData(awardXML)
								t_awardIconDatas.name = dup_award_list[i].name
								table.insert(self.m_awardDatas, t_awardIconDatas)
							end

							if nil ~= self.m_awardDatas then
								local view = createObj(ui_rewardDlgLayer, self, self.m_awardDatas)
								local currentlayer = GetMainMenu():GetModelLayer()
								local size1 = self.node_:getContentSize()
								view.node_:setAnchorPoint(ccp(0.5, 0.5))
								view.node_:setPosition(ccp(size1.width / 2, size1.height / 2))
								currentlayer:addChild(view.node_, 3)
							end
						end
															
						--重新拉取一次数据
						self.playerData_ = {}
						self.playerData_ = self.playerMgr_:GetPlayerInfoData()
						--重置标志
						self.m_selectedDatas = {}
						self.isAllSelected = false
						self.spr_selectall:setVisible(false)
						--刷新界面
						self:getLevelData()
					else
						GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
					end
				end)
		end

		self.node_:setTouchEnabled(true)
		self.node_:registerScriptTouchHandler(CCLayerTouch, false, kCCMenuHandlerPriority-1, true)

		self.btn_close_dlg:setTouchPriority(kCCMenuHandlerPriority-1)
		self.btn_close_dlg:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btn_close_dlg, function(button, event)
			onBtnClose(button)
			return nil
		end, CCControlEventTouchDown)

		self.btn_cancel:setTouchPriority(kCCMenuHandlerPriority-1)
		self.btn_cancel:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btn_cancel, function(button, event)
			onBtnClose(button)
			return nil
		end, CCControlEventTouchDown)

		self.btn_sweep:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.btn_sweep:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btn_sweep, function(button, event)
			onBtnSweep(button)
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

--创建测试数据
function createData(self)
	---[[
	local t_level_datas = {}
	for i=1, 25 do
		local t_item = {}
		t_item.id = i
		t_item.bSelected = false
		t_item.name = tostring("木叶大劫")
		t_item.select_status = 2
		table.insert(t_level_datas, t_item)
	end	

	--重新排列数据结构/每4个作一个子table
	self.m_levelDatas = {}
	local index = 0
	for i = 1, #t_level_datas do
		local inpart, decimal = tools.getIntAndDecimal(i / 4)
		if decimal == 0 then
			index = inpart
		else
			index = inpart + 1
		end
		self.m_levelDatas[index] = self.m_levelDatas[index] or {}
		table.insert(self.m_levelDatas[index], t_level_datas[i])
	end
	--]]
end