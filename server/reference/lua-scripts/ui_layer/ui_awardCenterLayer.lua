----------------------------------------------------------------------
--  Copyright (c) 2014-2016, XCKOO. All Rights Reserved.
--  Author :Tango
--  Time   :2015/1/19 17:08:50
--  Remark :领奖中心
----------------------------------------------------------------------
require "util/localizable"

module("ui_awardCenterLayer", package.seeall)
baseClass(layer_base_t, ui_awardCenterLayer)

require("ui_layer/ui_awardCenterCell")

function init(self, node, cur_index)
	self.contentSize_ = GetMainMenu():GetModelLayer():getContentSize()

	local ccbiAttrTable = {name="activity/AwardCenterView.ccbi", size=self.contentSize_}
	layer_base_t.init(self, true, ccbiAttrTable)

	--用户info
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	--pre info`
	self.preNode = node
	--tableView cell container
	self.cellNodes = {}

	self.tableData = {}
	self.m_touchPoint = nil
	--时间增量
	self.deltatime = 0
	
	self.price = 0
	--init
	self:init_ui()		
	self:init_binding_event()

	self:init_ext_ui()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		self.labelExpiry = tolua.cast(self.proxy_:getNode("label_expiry"),"CCLabelTTF")

		--node
		self.node_content = tolua.cast(self.proxy_:getNode("node_content"), "CCNode")
		self.node_cell = tolua.cast(self.proxy_:getNode("node_cell"), "CCNode")
		
		--btn
		self.btnClose = tolua.cast(self.proxy_:getNode("btn_close"), "CCControlButton")
		self.btnGetAll = tolua.cast(self.proxy_:getNode("btn_getall"), "CCControlButton")

		--get info
		self:requestBaseInfo()
	end
end

function requestBaseInfo(self)
	---[[
	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 1, "rl_x_award_msg")
	cclog("rl_x_award_msg----%s", urlpath)

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
			--cclog("resData = %s", resData)
			if retcode == "0" then
				local expiry = item:find("expiry")[1] -- 奖励保存时间
				self.labelExpiry:setString(expiry)

				local msglist = item:find("msglist")
				if msglist ~= nil then
					self.tableData = msglist
				end

				if self.tableData then
					self:init_ext_ui()
				end

			else
				GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
			end
		end)	
end	

function init_ext_ui(self)	
	self:createTableView()
	getLabelTTFFromCCB(self.proxy_, 'label_title'):setString(localizable.ui_awardCenter_text1)

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

function onClickedIcon( self, line, i )
	CSoundMgr:instance():PlayEffect(SOUND_BUTTON)
	if line < 0 or line > #self.tableData then
		GetMainMenu():ShowTextTip(localizable.ui_hall_net_error, -1)
		return nil
	end
	if i < 0 or i > #self.tableData[line] then
		return nil
	end

	local _id_icon = tonumber(self.tableData[line][i].dropid)
	if nil ~= _id_icon then
		CGameObjElement:ShowDropByID(_id_icon)
	end
	
end

function initTableHandle(self)
	self._tableViewHandler = LuaEventHandler:create(function(fn, table, a1, a2, x, y)
		local r
		if fn == "cellSize" then
			r = self._cell_size;
		elseif fn == "cellAtIndex" then
    		local nodeLayer = createObj(ui_awardCenterCell, self._cell_size, self.tableData[a1 + 1],self)
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
			-- for i=1,2 do
			-- 	if cellNode["spr_item_" .. tostring(i)]:boundingBox():containsPoint(self.m_touchPoint) then
			-- 		self:onClickedIcon(cell_index,i)
			-- 		break
			-- 	end
			-- end
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

		local function onBtnClose(btn, event)
			self.node_:removeFromParentAndCleanup(true)
		end

		self.btnClose:setTouchPriority(kCCMenuHandlerPriority-1)
		self.proxy_:handleButtonEvent(self.btnClose, function(button, event)
			onBtnClose(button)
			return nil
		end, CCControlEventTouchDown)

		self.btnGetAll:setTouchPriority(kCCMenuHandlerPriority-1)
		self.proxy_:handleButtonEvent(self.btnGetAll, function(button, event)
			self:requestGetAll()
		end, CCControlEventTouchDown)

	end
end

function requestGetAward( self, id )
	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 2, "rl_x_award_msg")
	urlpath = AddData(urlpath, "MsgID", id)
	cclog("rl_x_award_msg----%s", urlpath)

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
			--cclog("resData = %s", resData)
			if retcode == "0" then
				local awardXML = item:find("award")
				--只加入背包/显示掉落动画	
				ShowAward(awardXML)
				GetMainMenu():ShowTextTip(localizable.ui_awardCenter_suc, -1)
				self:requestBaseInfo()
			else
				GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
			end
		end)	
end

function requestGetAll( self )
	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 3, "rl_x_award_msg")
	cclog("rl_x_award_msg----%s", urlpath)

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
			--cclog("resData = %s", resData)
			if retcode == "0" then
				local awardXML = item:find("award")
				--只加入背包/显示掉落动画	
				ShowAward(awardXML)
				GetMainMenu():ShowTextTip(localizable.ui_awardCenter_suc, -1)
				self:requestBaseInfo()
			else
				GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
			end
		end)
end

function onNodeCleanup(self)
	if self.proxy_ then
    	self.proxy_:release()
    end

    layer_base_t.onNodeCleanup(self)
end
