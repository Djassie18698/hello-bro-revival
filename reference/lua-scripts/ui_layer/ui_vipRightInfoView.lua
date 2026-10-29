--descriptioin:VIP特权信息
--company: xckoo
--author: litao
--date: 2014-4-2
---------------------------------------------
module("ui_vipRightInfoView", package.seeall)
baseClass(layer_base_t, ui_vipRightInfoView)

function init(self, node, data)
	--player info
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()
	--
	self.contentSize_ = GetMainMenu():GetModelLayer():getContentSize()
	local ccbiAttrTable = {name="store/VipRightInfoView.ccbi", size=self.contentSize_}
	layer_base_t.init(self, true, ccbiAttrTable)

	--
	self.m_big_vipframes={'vip_0','vip_1','vip_2','vip_3','vip_4','vip_5','vip_6','vip_7','vip_8','vip_9','vip_10','vip_11','vip_12','vip_13','vip_14','vip_15','vip_16','vip_17','vip_18'}
	--
	self.m_curData = data
	--
	self.m_vipRightInfoData = {}
	--testdata
	self:createData()
	--
	self:init_ui()		
	self:init_binding_event()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		--btn
		self.btn_close = tolua.cast(self.proxy_:getNode("ctrl_close"), "CCControlButton")
		--sprite
		self.spr_vip_level = tolua.cast(self.proxy_:getNode("sprite_viplevel"), "CCSprite")
		--node
		self.node_content = tolua.cast(self.proxy_:getNode("node_content"), "CCNode")
		self.node_cell = tolua.cast(self.proxy_:getNode("node_cellsize"), "CCNode")
		--
		self.label_cur_vip_exp = tolua.cast(self.proxy_:getNode("label_vipratio"), "CCLabelBMFont")
		self.cc9_spr_cur_vip_exp =  tolua.cast(self.proxy_:getNode("sprite_viplevelbar"), "CCScale9Sprite")
		--
		self:init_ext_ui()

		--cell
		self:createTableView()
	end
end

function init_ext_ui(self)
	if self.proxy_ ~= nil then
		--cur vip spr
		local viplevel = self.playerMgr_:GetVipLevel()
		local frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(self.m_big_vipframes[viplevel+1])
		self.spr_vip_level:setDisplayFrame(frame)

		if self.m_curData ~= nil then
			--VIP升级经验
			if self.m_curData.need_exp > 0 then
				local expratio = self.m_curData.cur_exp / self.m_curData.need_exp
				self.cc9_spr_cur_vip_exp:setScaleX(expratio)
				local textexp = tostring(self.m_curData.cur_exp..'/'..self.m_curData.need_exp)
				self.label_cur_vip_exp:setString(textexp)
			else
				self.cc9_spr_cur_vip_exp:setScaleX(0)
				local textexp = tostring(self.m_curData.cur_exp..'/'..self.m_curData.cur_exp)
				self.label_cur_vip_exp:setString(textexp)
			end
		end	
	end
end

function createTableView(self)
	if self.tableView == nil then
		local cellContentSize = self.node_cell:getContentSize()
		self._cellsize = CCSizeMake(cellContentSize.width,cellContentSize.height)

		self._tableContentSize = self.node_content:getContentSize()
		self:initRankTableHandle()
		self.tableView = LuaTableView:createWithHandler(self.tableViewHandler, CCSizeMake(self._tableContentSize.width, self._tableContentSize.height))
		self.tableView:setDirection(kCCScrollViewDirectionVertical)
		self.tableView:setVerticalFillOrder(kCCTableViewFillTopDown)
		self.tableView:setTouchPriority(kCCMenuHandlerPriority - 3)

		self.node_content:addChild(self.tableView)
	else
		self.tableView:reloadData()
	end
end

function initRankTableHandle(self)
	self.tableViewHandler = LuaEventHandler:create(function(fn, table, a1, a2, x, y)
		local r
		if fn == "cellSize" then
			r = self._cellsize;
		elseif fn == "cellAtIndex" then
    		local nodeLayer = createObj(ui_vipRightInfoCell, self._cellsize, self.m_vipRightInfoData[a1 + 1])
			if not a2 then
				a2 = CCTableViewCell:create()
				a2:addChild(nodeLayer.node_)
			else
				a2:removeAllChildrenWithCleanup(true)
        		a2:addChild(nodeLayer.node_)
			end
			r = a2
		elseif fn == "numberOfCells" then
			r = #self.m_vipRightInfoData;
		    -- Cell events:
		elseif fn == "cellTouched" then			-- A cell was touched, a1 is cell that be touched. This is not necessary.
			--local cellIndex = a1:getIdx() + 1
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

function init_binding_event(self)
	if self.proxy_ ~= nil then
		local function onBtnOk(btn)
			self.node_:removeFromParentAndCleanup(true)
			--GetMainMenu():ChangeToSub(E_GAMEGROUPVIEW)
		end

		--屏蔽掉后层触摸事件
		local function CCLayerTouch(event, x, y)
			if event == "began" then
			 	return true
			end	
		end

		self.node_:setTouchEnabled(true)
		self.node_:registerScriptTouchHandler(CCLayerTouch, false, kCCMenuHandlerPriority-3, true)

		--按钮
		---[[
		self.btn_close:setTouchPriority(kCCMenuHandlerPriority-3)
		self.btn_close:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btn_close, function(button, event)
			onBtnOk(button)
			return nil
		end, CCControlEventTouchDown)
		--]]
	end
end

function onNodeCleanup(self)
	if self.proxy_ then
    	self.proxy_:release()
    	self.proxy_ = nil
    end

    layer_base_t.onNodeCleanup(self)
end

--创建测试数据
function createData(self)
	---[[
	local need_show = nil
	if self.m_curData.need_show then
		need_show = self.m_curData.need_show + 1
		if need_show > #self.m_big_vipframes then
			need_show = #self.m_big_vipframes
		end
	else
		need_show = #self.m_big_vipframes
	end
	for i=1,need_show do
		local t_data = {}
		t_data.vip_level = tonumber(i-1)
		if t_data.vip_level == 0 then
			--vip info
			local vipData = DataMgr.GetDataByID("Struct_Vipinfo", tonumber(i))
			t_data.param1 = tostring("1."..vipData.m_vip_props1_info)
			t_data.param2 = tostring("2."..vipData.m_vip_props2_info)
			t_data.param3 = tostring("3."..vipData.m_vip_fun1_info)
			t_data.param4 = tostring("4."..vipData.m_vip_fun2_info)
			t_data.param5 = tostring("5."..vipData.m_vip_fun3_info)
			t_data.param6 = tostring("6."..vipData.m_vip_fun4_info)

			t_data.param7 = tostring("7."..vipData.m_vip_fun5_info)
			--t_data.param8 = tostring("8."..vipData.m_vip_fun6_info)
		else
			t_data.param1 = tostring(string.format(localizable.vip_first_item_desc, tostring(i-1)))
			--vip info
			local vipData = DataMgr.GetDataByID("Struct_Vipinfo", tonumber(i))
			t_data.param2 = tostring("2."..vipData.m_vip_props1_info)
			t_data.param3 = tostring("3."..vipData.m_vip_props2_info)
			t_data.param4 = tostring("4."..vipData.m_vip_fun1_info)
			t_data.param5 = tostring("5."..vipData.m_vip_fun2_info)
			t_data.param6 = tostring("6."..vipData.m_vip_fun3_info)
			t_data.param7 = tostring("7."..vipData.m_vip_fun4_info)

			--t_data.param8 = tostring("8."..vipData.m_vip_fun5_info)
			--t_data.param9 = tostring("9."..vipData.m_vip_fun6_info)
		end

		self.m_vipRightInfoData[i] = t_data
	end
	--]]
end