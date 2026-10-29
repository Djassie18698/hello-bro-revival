--descriptioin:日常任务
--company: xckoo
--litao
--2014.5.9
---------------------------------------------
require("ui_layer/ui_saveTimeLayer")
require("ui_layer/ui_saveTimeAnim")

module("ui_dailyTaskLayer", package.seeall)
baseClass(layer_base_t, ui_dailyTaskLayer)

function init(self, node, cur_index)
	self.contentSize_ = GetMainMenu():GetModelLayer():getContentSize()

	local ccbiAttrTable = {name="sub_ui/DailyTaskView.ccbi", size=self.contentSize_}
	layer_base_t.init(self, true, ccbiAttrTable)

	--用户info
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	--pre info
	self.preNode = node

	--tableView cell container
	self.cellNodes = {}
	self.awardcellNodes = {}
	--data
	self.m_taskDatas = {}
	--
	self.m_awardDatas = {}
	--touch
	self.m_touchPoint = nil
	--
	self.cur_award_box = 1

	--create data
	--self:createData()

	--init
	self:init_ui()		
	self:init_binding_event()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		--label
		self.label_cur_score = tolua.cast(self.proxy_:getNode("label_cur_score"), "CCLabelTTF")
		--node
		self.node_content = tolua.cast(self.proxy_:getNode("node_content"), "CCNode")
		self.node_cell = tolua.cast(self.proxy_:getNode("node_cell"), "CCNode")

		self.node_award_content = tolua.cast(self.proxy_:getNode("node_award_content"), "CCNode")
		self.node_award_cell = tolua.cast(self.proxy_:getNode("node_award_cell"), "CCNode")
		--btn
		self.btn_close_dlg = tolua.cast(self.proxy_:getNode("closeButton"), "CCControlButton")
		self.btn_pre_award = tolua.cast(self.proxy_:getNode("btn_pre_award"), "CCControlButton") 
		self.btn_next_award = tolua.cast(self.proxy_:getNode("btn_next_award"), "CCControlButton") 
		--spr
		self.spr_progress = tolua.cast(self.proxy_:getNode("spr_progress"), "CCScale9Sprite")

		--get info
		self:getTaskData()
	end
end

function getTaskData(self)
	---[[
	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 1, "rl_r_dailytask")
	cclog("rl_r_daily_task----%s", urlpath)

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
			cclog("resData = %s", resData)
			if retcode == "0" then
				--
				local _player = item:find("player")
				if _player then
					self.total_score = tonumber(_player:find("total")[1])
					self.cur_score = tonumber(_player:find("current")[1])
				end

				local _task_list = item:find("task_list")
				if _task_list then
					self.m_taskDatas = {}
					for i=1, #_task_list do
						local t_item = {}
						t_item.id = _task_list[i].id
						t_item.cur_process = _task_list[i].process
						table.insert(self.m_taskDatas, t_item)
					end
				end

				local _award_list = item:find("award_list")
				if _award_list then
					self.m_awardDatas = {}
					for i=1, #_award_list do
						local t_item = {}
						t_item.id = tonumber(_award_list[i].id)
						t_item.status = tonumber(_award_list[i].status)
						t_item.needscore = tonumber(_award_list[i].cost)
						t_item.prop_list = _award_list[i]:find("drop_list")
						table.insert(self.m_awardDatas, t_item)
					end
				end

				if self.m_awardDatas and self.m_taskDatas then
					self:init_ext_ui()
				end
			else
				GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
			end
		end)	
end

function init_ext_ui(self)	
	self.label_cur_score:setString(tostring(self.cur_score.."/"..self.total_score))
	--process
	local p_scale = tonumber(self.cur_score/(self.total_score * 1.0))
	self.spr_progress:setScaleX(p_scale)
	--列表
	self:createTableView()
	--
	self:createAwardTableView()
end

function createAwardTableView(self)
	if self._award_tableView == nil then
		local cellContentSize = self.node_award_cell:getContentSize()
		self._award_cell_size = CCSizeMake(cellContentSize.width,cellContentSize.height)

		self._award_content_size = self.node_award_content:getContentSize()
		self:initAwardTableHandle()
		self._award_tableView = LuaTableView:createWithHandler(self._award_tableViewHandler, CCSizeMake(self._award_content_size.width, self._award_content_size.height))
		self._award_tableView:setDirection(kCCScrollViewDirectionHorizontal)
		self._award_tableView:setVerticalFillOrder(kCCTableViewFillTopDown)
		self._award_tableView:setTouchPriority(kCCMenuHandlerPriority - 1)

		local _offset = -(self.cur_award_box - 1) * self._award_cell_size.width
		self._award_tableView:setContentOffset(_offset, 0)

		self.node_award_content:addChild(self._award_tableView)
	else
		self._award_tableView:reloadData()
	end
end

function initAwardTableHandle(self)
	self._award_tableViewHandler = LuaEventHandler:create(function(fn, table, a1, a2, x, y)
		local r
		if fn == "cellSize" then
			r = self._award_cell_size;
		elseif fn == "cellAtIndex" then
    		local nodeLayer = createObj(ui_dailyTaskAwardCell, self._award_cell_size, self.m_awardDatas[a1 + 1])
			--tableView cell container
			self.awardcellNodes[a1+1] = nodeLayer
			if not a2 then
				a2 = CCTableViewCell:create()
				a2:addChild(nodeLayer.node_)
			else
				a2:removeAllChildrenWithCleanup(true)
        		a2:addChild(nodeLayer.node_)
			end
			r = a2
		elseif fn == "numberOfCells" then
			r = #self.m_awardDatas;
		    -- Cell events:
		elseif fn == "cellTouched" then			-- A cell was touched, a1 is cell that be touched. This is not necessary.
			---[[
			local cell_index = a1:getIdx() + 1
			--local cellData = self.m_taskDatas[cell_index]
			if self.awardcellNodes[cell_index].spr_box:boundingBox():containsPoint(self.m_touchPoint) then
				self:ShowAwardBox(cell_index)
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
    		local nodeLayer = createObj(ui_dailyTaskCell, self._cell_size, self.m_taskDatas[a1 + 1])
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
			r = #self.m_taskDatas
		    -- Cell events:
		elseif fn == "cellTouched" then			-- A cell was touched, a1 is cell that be touched. This is not necessary.
			---[[
			local cell_index = a1:getIdx() + 1
			local cellData = self.m_taskDatas[cell_index]
			self.cellNodes[cell_index].btn_goto:setScale(1.0)
			if self.cellNodes[cell_index].btn_goto:boundingBox():containsPoint(self.m_touchPoint) then
				self:gotoLayerById(tonumber(cellData.id), cell_index)
			end

			self.m_touchPoint = nil  
			--]]
		elseif fn == "cellTouchBegan" then		-- A cell is touching, a1 is cell, a2 is CCTouch
			self.m_touchPoint = a2:getLocation()	
			self.m_touchPoint = a1:convertToNodeSpace(self.m_touchPoint)

			local cell_index = a1:getIdx() + 1
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

function ShowAwardBox(self, _index)
	--通用奖励框	
	local view = createObj(ui_dailyRewardLayer, self, self.m_awardDatas[_index])
	GetMainMenu():GetModelLayer():addChild(view.node_)
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
		--屏蔽掉后层触摸事件
		local function CCLayerTouch(event, x, y)
			if event == "began" then
				 return true
			end
		end

		local function onBtnClose(btn, event)
			self.node_:removeFromParentAndCleanup(true)
		end

		local function onBtnNextBox(btn, event)
			--		
			self.cur_award_box = self.cur_award_box + 1
			if self.cur_award_box > #self.m_awardDatas - 1 then
				self.cur_award_box = #self.m_awardDatas - 1
			end
			local targetCardOffsetX = -(self.cur_award_box - 1) * self._award_cell_size.width
			--local adjustAnimDelay = 0.5
			self._award_tableView:setContentOffsetInDuration(ccp(targetCardOffsetX, 0), 0.5)
		end

		local function onBtnPreBox(btn, event)
			--	
			self.cur_award_box = self.cur_award_box - 1
			if self.cur_award_box < 0 then
				self.cur_award_box = 0
			end
			local targetCardOffsetX = -(self.cur_award_box - 1) * self._award_cell_size.width
			--local adjustAnimDelay = 0.5
			self._award_tableView:setContentOffsetInDuration(ccp(targetCardOffsetX, 0), 0.5)
		end

		self.node_:setTouchEnabled(true)
		self.node_:registerScriptTouchHandler(CCLayerTouch, false, kCCMenuHandlerPriority-1, true)

		self.btn_pre_award:setTouchPriority(kCCMenuHandlerPriority-1)
		self.btn_pre_award:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btn_pre_award, function(button, event)
			onBtnPreBox(button)
			return nil
		end, CCControlEventTouchDown)

		self.btn_next_award:setTouchPriority(kCCMenuHandlerPriority-1)
		self.btn_next_award:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btn_next_award, function(button, event)
			onBtnNextBox(button)
			return nil
		end, CCControlEventTouchDown)

		self.btn_close_dlg:setTouchPriority(kCCMenuHandlerPriority-1)
		self.btn_close_dlg:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btn_close_dlg, function(button, event)
			onBtnClose(button)
			return nil
		end, CCControlEventTouchDown)
	end
end

function gotoLayerById(self, _index, _nPos)
	local _info = DataMgr.GetDataByID("Struct_Dailytask_Info", tonumber(_index))
	local _need_process = _info.m_dailytask_value1
	if tonumber(self.m_taskDatas[_nPos].cur_process) >= tonumber(_need_process) then
		return nil
	end

	if _index == 1 then--历练
		GetMainMenu():ChangeToSub(E_GAMEROUND)
	elseif _index == 2 then--闯关
		GetMainMenu():ChangeToSub(E_TOWERVIEW)
	elseif _index == 3 then--夺宝xxxxxxx
		GetMainMenu():ChangeToSub(E_MARKLSTVIEW)
	elseif _index == 4 then--竞技场
		GetMainMenu():ChangeToSub(E_ARENAVIEW)
	elseif _index == 5 then--淬炼xxxxxxxx
		GetMainMenu():ChangeToSub(E_STRENGTHVIEW)
	elseif _index == 6 then--切磋
		GetMainMenu():ChangeToSub(E_FIGHTLISTEVIEW)
	elseif _index == 7 then--炼魂xxxxxx
		GetMainMenu():ChangeToActivitySubMenu("ShowTrainSoulView")
		--GetMainMenu():ChangeToSub(E_TOWERVIEW)
	elseif _index == 8 then--世界BOSSxxxxxxx
		GetMainMenu():ChangeToActivity("fightBossView")
	elseif _index == 9 then--刮刮乐xxxxx
		GetMainMenu():ChangeToActivity("ScratchCardActivity")
	elseif _index == 10 then--国战xxxxxx
		GetMainMenu():ChangeToSub(E_COUNTRYWARDEFAULT)
	elseif _index == 11 then--边境xxxxxx
		GetMainMenu():ChangeToActivitySubMenu("ShowBorderWarView")
	elseif _index == 12 then--培养xxxxxx
		GetMainMenu():ChangeToSub(E_POTENTIALVIEW)
	elseif _index == 13 then--充值
		local puchaseLayer = createObj(ui_purchaseLayer)
		GetMainMenu():GetModelLayer():AddDialog(puchaseLayer.node_, 3)
	elseif _index == 14 then--万里挑一xxxxx
		GetMainMenu():ChangeToSub(E_STOREITEMSVIEW)
	elseif _index == 15 then--百宝箱xxxxx
		GetMainMenu():ChangeToActivity("boxOpenActivityView")
	elseif _index == 16 then--使用3次拉面XXX
		local saveTimeLayer = createObj(ui_saveTimeLayer)
		GetMainMenu():GetModelLayer():AddDialog(saveTimeLayer.node_, 3)
	elseif _index == 17 then--参与3次摇钱树
		GetMainMenu():ChangeToSub(E_MONEYTREEVIEW)
	elseif _index == 18 then--商城购买道具1次
		GetMainMenu():ChangeToSub(E_STOREITEMSVIEW)
	elseif _index == 19 then--获得1000点竞技场声望
		GetMainMenu():ChangeToSub(E_ARENAVIEW)
	elseif _index == 20 then--忍者升级3次
		GetMainMenu():ChangeToSub(E_BACKPACKVIEW)
	elseif _index == 21 then--转生1次
		GetMainMenu():ChangeToSub(E_REINCARNATIONVIEW)
	elseif _index == 22 then--极限训练
		GetMainMenu():ChangeToActivitySubMenu("ShowLimitTrainView")
	elseif _index == 23 then--极限训练翻倍
		GetMainMenu():ChangeToActivitySubMenu("ShowLimitTrainSoulView")
	elseif _index == 24 then--神秘商店
		GetMainMenu():ChangeToActivitySubMenu("ShowSecretShopView")
	end

	self.node_:removeFromParentAndCleanup(true)
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
	--]]
end