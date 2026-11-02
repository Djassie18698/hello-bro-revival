----------------------------------------------------------------------
--  Copyright (c) 2014-2016, XCKOO. All Rights Reserved.
--  Author :Tango
--  Time   :2014/11/18 16:27:04
--  Remark :成员开除
----------------------------------------------------------------------
module("ui_orgMemExpelLayer", package.seeall)
baseClass(layer_base_t, ui_orgMemExpelLayer)

require("ui_layer/ui_orgMemExpelCell")

local json = require("json")

function init(self, node)
	self.contentSize_ = GetMainMenu():GetModelLayer():getContentSize()
	local ccbiAttrTable = {name="sub_ui/OrgMemExpelView.ccbi", size=self.contentSize_}
	layer_base_t.init(self, true, ccbiAttrTable)

	--用户info
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	--pre info
	self.preNode = node
	--tableView cell container
	self.cellNodes = {}

	self.tableData = {}
	self.m_touchPoint = nil
	
	--init
	self:init_ui()		
	self:init_binding_event()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		self.node_content = tolua.cast(self.proxy_:getNode("node_content"), "CCNode")
		self.node_cell = tolua.cast(self.proxy_:getNode("node_cell"), "CCNode")
		--btn
		self.btnClose = tolua.cast(self.proxy_:getNode("btn_close"), "CCControlButton")
		self.btnOk = tolua.cast(self.proxy_:getNode("btn_OK"), "CCControlButton")

		--get info
		self:requestBaseInfo()
	end
end


function requestBaseInfo(self)
	--获取基本信息
	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 2, "rl_w_group_admin")
	--cclog("rl_w_group_admin & cmd = 2---%s", urlpath)
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
			--cclog("rl_w_group_admin ret = %s", resData)
			local retcode = item.code
			if retcode == "0" then
				self.tableData = item:find("member_list")
													
				--ext init ui
				self:init_ext_ui()
			else
				GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
			end
		end)
end

function init_ext_ui(self)	
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
    		local nodeLayer = createObj(ui_orgMemExpelCell, self._cell_size, self.tableData[a1 + 1])
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
			r = #self.tableData
		    -- Cell events:
		elseif fn == "cellTouched" then			-- A cell was touched, a1 is cell that be touched. This is not necessary.
			local cell_index = a1:getIdx() + 1
			local cellData = self.tableData[cell_index]
			local cellNode = self.cellNodes[cell_index]
			self.m_touchPoint = nil  
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


function onBtnOk( self )
	--收集信息
	local mems = {}
	local disband = false
	for i,cell in ipairs(self.cellNodes) do
		if cell.selected then
			table.insert(mems, self.tableData[i].uid)
			if self.tableData[i].uid == self.playerData_.m_uid and self.tableData[i].postion == "3" then
				disband = true
			end
		end
	end

	if #mems == 0 then
		GetMainMenu():ShowTextTip(localizable.ui_org_pls_select, -1)
		return nil
	end
	local memStr = json.encode(mems) -- 转成json字符串

	if disband == true then
		local function doDisband()
			self:requestExpel(memStr)
		end

		local dlg = CommonDialogView.create()
		CommonDialogView.m_selfview = dlg
		dlg:SetTitle(localizable.ui_rouletteLayer_title)
		dlg:SetDescription(localizable.ui_orgDisbandTip)
		dlg:loadCCBI()
		dlg:initUI()
		dlg:SetConfirmHandler(doDisband)
		GetMainMenu():GetModelLayer():AddDialog(dlg, 3)
	else
		self:requestExpel(memStr)
	end
	
end

function requestExpel(self, memStr)
	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 3, "rl_w_group_admin")
	urlpath = AddData(urlpath, "Members", memStr)
	urlpath = AddData(urlpath, "GroupId", global.myOrgId)
	--cclog("rl_w_group_admin & cmd = 3---%s", urlpath)
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
			--cclog("rl_w_group_admin ret = %s", resData)
			local retcode = item.code
			if retcode == "0" then
				local disband = item:find("dismiss_group")[1]
				if disband == '1' then -- 解散
					GetMainMenu():ShowTextTip(localizable.ui_orgDisbanded, -1)
					self.node_:removeFromParentAndCleanup(true)
					GetMainMenu():ChangeToSub(E_DEFAULTMENU)
					global.myOrgid = 0
				else
					self.tableData = item:find("member_list")
					self._tableView:reloadData()
					GetMainMenu():ShowTextTip(localizable.ui_operationSuc, -1)
				end
			else
				GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
			end
		end)
end

function init_binding_event(self)
	if self.proxy_ ~= nil then
		--屏蔽掉后层触摸事件
		local function CCLayerTouch(event, x, y)
			if event == "began" then
				 return true
			end
		end

		self.node_:setTouchEnabled(true)
		self.node_:registerScriptTouchHandler(CCLayerTouch, false, kCCMenuHandlerPriority-1, true)

		self.btnClose:setTouchPriority(kCCMenuHandlerPriority-1)
		self.btnClose:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btnClose, function(button, event)
			self.preNode:refresh()
			self.node_:removeFromParentAndCleanup(true)
			return nil
		end, CCControlEventTouchDown)

		self.btnOk:setTouchPriority(kCCMenuHandlerPriority-1)
		self.proxy_:handleButtonEvent(self.btnOk, function(button, event)
			self:onBtnOk()
		end, CCControlEventTouchDown)

	end
end

function onNodeCleanup(self)
	if self.proxy_ then
    	self.proxy_:release()
    end

    layer_base_t.onNodeCleanup(self)
end

function createTestData( self )
	self.tableData = {
		{duty = '公会一', level = 4, leader = '刘德华',contr = '21342'},
		{duty = '聚义堂', level = 5, leader = '刘诗诗',contr = '45645'}
	}
	self:init_ext_ui()
end