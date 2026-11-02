----------------------------------------------------------------------
--  Copyright (c) 2014-2016, XCKOO. All Rights Reserved.
--  Author :Tango
--  Time   :2014/11/19 21:20:48
--  Remark :职务管理
----------------------------------------------------------------------

module("ui_orgMemOfficeLayer", package.seeall)
baseClass(layer_base_t, ui_orgMemOfficeLayer)

require("ui_layer/ui_orgMemOfficeCell")

local json = require("json")

function init(self, node)
	self.contentSize_ = GetMainMenu():GetModelLayer():getContentSize()
	local ccbiAttrTable = { name = "sub_ui/OrgMemOfficeView.ccbi", size = self.contentSize_ }
	layer_base_t.init(self, true, ccbiAttrTable)

	-- 用户info
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	-- pre info
	self.preNode = node
	-- tableView cell container
	self.cellNodes = { }

	self.tableData = { }
	self.m_touchPoint = nil

	-- init
	self:init_ui()
	self:init_binding_event()

	self.myPosition = 0

	self:init_ext_ui()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		self.node_content = tolua.cast(self.proxy_:getNode("node_content"), "CCNode")
		self.node_cell = tolua.cast(self.proxy_:getNode("node_cell"), "CCNode")
		-- btn
		self.btnClose = tolua.cast(self.proxy_:getNode("btn_close"), "CCControlButton")
		self.btnPromotion = tolua.cast(self.proxy_:getNode("btn_promotion"), "CCControlButton")
		self.btnDemotion = tolua.cast(self.proxy_:getNode("btn_demotion"), "CCControlButton")

		self:requestBaseInfo()
	end
end


function requestBaseInfo(self)
	-- 获取基本信息
	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 2, "rl_w_group_admin")
	-- cclog("rl_w_group_admin & cmd = 2---%s", urlpath)
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
		-- cclog("rl_w_group_admin ret = %s", resData)
		local retcode = item.code
		if retcode == "0" then
			self.tableData = item:find("member_list")
			self.myPosition = item:find("pos")[1]

			-- ext init ui
			self:init_ext_ui()
		else
			GetMainMenu():ShowErrorTip(tonumber(retcode), -1)
		end
	end )
end

function init_ext_ui(self)
	self:createTableView()
end



function createTableView(self)
	if self._tableView == nil then
		local cellContentSize = self.node_cell:getContentSize()
		self._cell_size = CCSizeMake(cellContentSize.width, cellContentSize.height)

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
	self._tableViewHandler = LuaEventHandler:create( function(fn, table, a1, a2, x, y)
		local r
		if fn == "cellSize" then
			r = self._cell_size;
		elseif fn == "cellAtIndex" then
			local nodeLayer = createObj(ui_orgMemOfficeCell, self._cell_size, self.tableData[a1 + 1])
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
			r = #self.tableData
			-- Cell events:
		elseif fn == "cellTouched" then
			-- A cell was touched, a1 is cell that be touched. This is not necessary.
			local cell_index = a1:getIdx() + 1
			local cellData = self.tableData[cell_index]
			local cellNode = self.cellNodes[cell_index]
			self.m_touchPoint = nil
		elseif fn == "cellTouchBegan" then
			-- A cell is touching, a1 is cell, a2 is CCTouch
			self.m_touchPoint = a2:getLocation()
			self.m_touchPoint = a1:convertToNodeSpace(self.m_touchPoint)
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

-- 升职
function onBtnPromotion(self)
	-- 收集信息
	local mems = { }
	local abdicate = false
	for i, cell in ipairs(self.cellNodes) do
		if cell.selected then
			table.insert(mems, self.tableData[i].uid)
			-- 升职副首领，则为禅让
			if self.tableData[i].postion == '2' and self.myPosition == '3' then
				abdicate = true
			end
		end
	end
	if #mems == 0 then
		GetMainMenu():ShowTextTip(localizable.ui_org_pls_select, -1)
		return nil
	end
	local memStr = json.encode(mems)
	-- 转成json字符串

	if abdicate == true then
		local function doPromotion()
			self:requestAction(memStr, 1)
		end

		local dlg = CommonDialogView.create()
		CommonDialogView.m_selfview = dlg
		dlg:SetTitle(localizable.ui_rouletteLayer_title)
		dlg:SetDescription(localizable.ui_orgAbdicate)
		dlg:loadCCBI()
		dlg:initUI()
		dlg:SetConfirmHandler(doPromotion)
		GetMainMenu():GetModelLayer():AddDialog(dlg, 3)
	else
		self:requestAction(memStr,1)
	end
end

-- 降职
function onBtnDeomotion(self)
	-- 收集信息
	local mems = { }
	for i, cell in ipairs(self.cellNodes) do
		if cell.selected then
			table.insert(mems, self.tableData[i].uid)
		end
	end
	if #mems == 0 then
		GetMainMenu():ShowTextTip(localizable.ui_org_pls_select, -1)
		return nil
	end
	local memStr = json.encode(mems)
	-- 转成json字符串
	self:requestAction(memStr, 2)
end

function requestAction(self, memStr, action)
	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 5, "rl_w_group_admin")
	urlpath = AddData(urlpath, "Members", memStr)
	urlpath = AddData(urlpath, "PositionAction", action)
	urlpath = AddData(urlpath, "GroupId", global.myOrgId)
	-- cclog("rl_w_group_admin & cmd = 5---%s", urlpath)
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
		-- cclog("rl_w_group_admin ret = %s", resData)
		local retcode = item.code
		if retcode == "0" then
			self.tableData = item:find("member_list")
			self._tableView:reloadData()
			GetMainMenu():ShowTextTip(localizable.ui_operationSuc, -1)
		else
			GetMainMenu():ShowErrorTip(tonumber(retcode), -1)
		end
	end )

end

function init_binding_event(self)
	if self.proxy_ ~= nil then
		-- 屏蔽掉后层触摸事件
		local function CCLayerTouch(event, x, y)
			if event == "began" then
				return true
			end
		end

		self.node_:setTouchEnabled(true)
		self.node_:registerScriptTouchHandler(CCLayerTouch, false, kCCMenuHandlerPriority - 1, true)

		self.btnClose:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.btnClose:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btnClose, function(button, event)
			self.preNode:refresh()
			self.node_:removeFromParentAndCleanup(true)
			return nil
		end , CCControlEventTouchDown)

		self.btnPromotion:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.proxy_:handleButtonEvent(self.btnPromotion, function(button, event)
			self:onBtnPromotion()
		end , CCControlEventTouchDown)

		self.btnDemotion:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.proxy_:handleButtonEvent(self.btnDemotion, function(button, event)
			self:onBtnDeomotion()
		end , CCControlEventTouchDown)
	end
end

function onNodeCleanup(self)
	if self.proxy_ then
		self.proxy_:release()
	end

	layer_base_t.onNodeCleanup(self)
end

function createTestData(self)
	self.tableData = {
		{ name = '刘德华', level = 4, contrib = '13211', duty = "职位" },
		{ name = '刘诗诗', level = 5, contrib = '45654', duty = "职位" }
	}
	self:init_ext_ui()
end