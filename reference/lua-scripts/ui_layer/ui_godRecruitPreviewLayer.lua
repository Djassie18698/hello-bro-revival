--
-- Author: tango
-- Date: 2015-12-28 17:37:45
--

require("CommonBuyItemDialog.lua")
require("ui_layer/ui_godRecruitPreviewCell.lua")

module("ui_godRecruitPreviewLayer", package.seeall)
baseClass(layer_base_t, ui_godRecruitPreviewLayer)

function init(self, node, ninjas)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	--Load res
	self.contentSize_ = GetMainMenu():GetSubContentNode():getContentSize()
	local ccbiAttrTable = {name="activity/GodRecruitPreview.ccbi", size=self.contentSize_}
	layer_base_t.init(self, true, ccbiAttrTable)

	self.preNode = node

	self.m_itemlist = self:splitNinjas(ninjas)

	--tableView cell container
	self.cellNodes = {}
	--
	self.m_touchPoint = nil

	--创建测试数据信息
	--self:createTestData()

	--init && bindEvent
	---[[
	self:init_ui()
	self:init_binding_event()
	--]]
end


function init_ui(self)
	if self.proxy_ ~= nil then
		self.btnClose = tolua.cast(self.proxy_:getNode("btn_close"),"CCControlButton")

		self.node_content = tolua.cast(self.proxy_:getNode("node_content"), "CCNode")
		self.node_cell = tolua.cast(self.proxy_:getNode("node_cell"), "CCNode")

		getLabelTTFFromCCB(self.proxy_, 'label_title'):setString(localizable.ui_godRecruit_preview)
		self:createTableView()
	end
end

function splitNinjas( self, ninjas )
	local ret = {}
	local item4 = {}
	local count = 0
	for i = 1, #ninjas do
		table.insert(item4,ninjas[i])
		if #ninjas - count*4 >= 4 then --剩下的 >= 4个
			if 4 == #item4 then
				table.insert(ret, item4)
				item4 = {}
				count = count+1
			end
		end
	end

	-- 剩下不足4个的
	if #item4 > 0 then
		table.insert(ret, item4)
	end
	
	return ret
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
			CSoundMgr:instance():PlayEffect(SOUND_BUTTON)
			--GetMainMenu():ChangeToSub(E_DEFAULTMENU)
			self.node_:removeFromParentAndCleanup(true)
		end

		--back
		self.btnClose:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.proxy_:handleControlEvent(self.btnClose, onBtnClose, CCControlEventTouchUpInside)
	end
end

function createTableView(self)
	if self.tableView == nil then
		local cellContentSize = self.node_cell:getContentSize()
		self.rank_cellsize = CCSizeMake(cellContentSize.width,cellContentSize.height)

		self.rank_tableContentSize = self.node_content:getContentSize()
		self:initTableHandle()
		self.tableView = LuaTableView:createWithHandler(self.tableViewHandler, CCSizeMake(self.rank_tableContentSize.width, self.rank_tableContentSize.height))
		self.tableView:setDirection(kCCScrollViewDirectionVertical)
		self.tableView:setVerticalFillOrder(kCCTableViewFillTopDown)
		self.tableView:setTouchPriority(kCCMenuHandlerPriority - 1)

		self.node_content:addChild(self.tableView)
	else
		self.tableView:reloadData()
	end
end

function initTableHandle(self)
	self.tableViewHandler = LuaEventHandler:create(function(fn, table, a1, a2, x, y)
		local r
		if fn == "cellSize" then
			r = self.rank_cellsize;
		elseif fn == "cellAtIndex" then
    		local nodeLayer = createObj(ui_godRecruitPreviewCell, self.rank_cellsize, self.m_itemlist[a1 + 1])
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
			r = #self.m_itemlist;
		    -- Cell events:
		elseif fn == "cellTouched" then			-- A cell was touched, a1 is cell that be touched. This is not necessary.
			local cell_index = a1:getIdx() + 1
			local cellNode = self.cellNodes[cell_index]
			for i=1,4 do
				cclog('clicked:'..tostring(i))
				if cellNode["spr_icon_" .. tostring(i)]:boundingBox():containsPoint(self.m_touchPoint) then
					self:onBtnIcon(cell_index,i)
					break
				end
				--cellNode["btn_icon" .. tostring(i)]:setScale(1.0);
			end
			self.m_touchPoint = nil
			
		elseif fn == "cellTouchBegan" then		-- A cell is touching, a1 is cell, a2 is CCTouch
			local cell_index = a1:getIdx() + 1
			self.m_touchPoint = a2:getLocation()
			self.m_touchPoint = a1:convertToNodeSpace(self.m_touchPoint)
			r = true
		elseif fn == "cellTouchEnded" then		-- A cell was touched, a1 is cell, a2 is CCTouch
			-- local cell_index = a1:getIdx() + 1
			-- self.cellNodes[cell_index].btn_fight:setScale(1.0);
			r = true
		elseif fn == "cellHighlight" then		-- A cell is highlighting, coco2d-x 2.1.3 or above
		elseif fn == "cellUnhighlight" then		-- A cell had been unhighlighted, coco2d-x 2.1.3 or above
			-- local cell_index = a1:getIdx() + 1
			-- self.cellNodes[cell_index].btn_fight:setScale(1.0);
		elseif fn == "cellWillRecycle" then		-- A cell will be recycled, coco2d-x 2.1.3 or above
		end
		return r
	end)
end

function onBtnIcon(self, line,i)
	CSoundMgr:instance():PlayEffect(SOUND_BUTTON)
	if line < 0 or line > #self.m_itemlist then
		GetMainMenu():ShowTextTip(localizable.ui_hall_net_error, -1)
		return nil
	end

	if i < 0 or i > #self.m_itemlist[line] then
		return nil
	end

	local _id_icon = tonumber(self.m_itemlist[line][i].drop_id)
	if nil ~= _id_icon then
		CGameObjElement:ShowDropByID(_id_icon)
	end
	
end

function onNodeCleanup(self)
    --cclog("onNodeCleanup")
    if self.proxy_ then
    	self.proxy_:release()
    end
    layer_base_t.onNodeCleanup(self)
end

function createTestData(self)
	return nil
end