--descriptioin:VIP_Gift_View
--company: xckoo
--litao
--2014.4.10
---------------------------------------------
module("ui_giftDetailView", package.seeall)
baseClass(layer_base_t, ui_giftDetailView)

function init(self, node, cur_gift_index)
	self.contentSize_ = GetMainMenu():GetModelLayer():getContentSize()
	local ccbiAttrTable = {name="store/GiftDetailView.ccbi", size=self.contentSize_}
	layer_base_t.init(self, true, ccbiAttrTable)

	--用户info
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	--pre info
	self.preNode = node
	self.cur_gift_index = cur_gift_index

	--data
	self.m_giftDatas = {}
	--tableView cell container
	self.cellNodes = {}
	--touch
	self.m_touchPoint = nil

	--init
	self:init_ui()		
	self:init_binding_event()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		--btn
		self.btn_ok = tolua.cast(self.proxy_:getNode("ctrl_ok"), "CCControlButton")
		self.btn_close = tolua.cast(self.proxy_:getNode("ctrl_close"), "CCControlButton")
		self.btn_cancle = tolua.cast(self.proxy_:getNode("ctrl_cancle"), "CCControlButton")
		--ttf
		self.label_vip_gift_desc = tolua.cast(self.proxy_:getNode("label_vip_desc"), "CCLabelTTF")
		--node
		self.node_content = tolua.cast(self.proxy_:getNode("node_content"), "CCNode")
		self.node_cell = tolua.cast(self.proxy_:getNode("node_cell"), "CCNode")

		self:init_ext_ui()
	end
end

function init_ext_ui(self)
	self.label_vip_gift_desc:setString(tostring("VIP"..self.cur_gift_index..localizable.ui_gift_tips))
	--init ext info
	self:getGiftData(self.cur_gift_index)

	if self.m_giftDatas then
		self:createRankTableView()
	end
end

function createRankTableView(self)
	if self._tableView == nil then
		local cellContentSize = self.node_cell:getContentSize()
		self._cell_size = CCSizeMake(cellContentSize.width,cellContentSize.height)

		self._content_size = self.node_content:getContentSize()
		self:initRankTableHandle()
		self._tableView = LuaTableView:createWithHandler(self._tableViewHandler, CCSizeMake(self._content_size.width, self._content_size.height))
		self._tableView:setDirection(kCCScrollViewDirectionVertical)
		self._tableView:setVerticalFillOrder(kCCTableViewFillTopDown)
		self._tableView:setTouchPriority(kCCMenuHandlerPriority - 1)

		self.node_content:addChild(self._tableView)
	else
		self._tableView:reloadData()
	end
end

function initRankTableHandle(self)
	self._tableViewHandler = LuaEventHandler:create(function(fn, table, a1, a2, x, y)
		local r
		if fn == "cellSize" then
			r = self._cell_size;
		elseif fn == "cellAtIndex" then
    		local nodeLayer = createObj(ui_giftDetailCell, self._cell_size, self.m_giftDatas[a1 + 1])
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
			r = #self.m_giftDatas;
		    -- Cell events:
		elseif fn == "cellTouched" then			-- A cell was touched, a1 is cell that be touched. This is not necessary.
			---[[
			local cell_index = a1:getIdx() + 1
			if self.cellNodes[cell_index].spr_gift_icon:boundingBox():containsPoint(self.m_touchPoint) then
				local _drop_id = self.m_giftDatas[cell_index]._id
				CGameObjElement:ShowDropByID(_drop_id)
			end
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

--获取礼包数据
function getGiftData(self, _id)
	---[[
	--gift info by id
	local _data = DataMgr.GetDataByID("Struct_Vip_Gift", tonumber(_id))
	--掉落id
	local tempitem_1 = {}
	tempitem_1._id = self:getIntPart(tonumber(_data.m_vip_dropid1))
	if tempitem_1._id > 0 then
		table.insert(self.m_giftDatas, tempitem_1)
	end

	local tempitem_2 = {}
	tempitem_2._id = self:getIntPart(tonumber(_data.m_vip_dropid2))
	if tempitem_2._id > 0 then
		table.insert(self.m_giftDatas, tempitem_2)
	end

	local tempitem_3 = {}
	tempitem_3._id = self:getIntPart(tonumber(_data.m_vip_dropid3))
	if tempitem_3._id > 0 then
		table.insert(self.m_giftDatas, tempitem_3)
	end

	local tempitem_4 = {}
	tempitem_4._id = self:getIntPart(tonumber(_data.m_vip_dropid4))
	if tempitem_4._id > 0 then
		table.insert(self.m_giftDatas, tempitem_4)
	end

	local tempitem_5 = {}
	tempitem_5._id = self:getIntPart(tonumber(_data.m_vip_dropid5))
	if tempitem_5._id > 0 then
		table.insert(self.m_giftDatas, tempitem_5)
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
		local function onBtnOk(btn)
			self.node_:removeFromParentAndCleanup(true)
		end

		--屏蔽掉后层触摸事件
		local function CCLayerTouch(event, x, y)
			local rect = self.node_:boundingBox()
			rect.origin = ccp(0,0)
			local p = self.node_:convertToNodeSpace(ccp(x,y))			
			--截获界面内后层的信息
			if rect:containsPoint(p) == true then
				if event == "began" then
				 	return true
				end
			end		
		end

		self.node_:setTouchEnabled(true)
		self.node_:registerScriptTouchHandler(CCLayerTouch, false, kCCMenuHandlerPriority-1, true)

		--按钮
		---[[
		self.btn_close:setTouchPriority(kCCMenuHandlerPriority-1)
		self.btn_close:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btn_close, function(button, event)
			onBtnOk(button)
			return nil
		end, CCControlEventTouchDown)

		self.btn_cancle:setTouchPriority(kCCMenuHandlerPriority-1)
		self.btn_cancle:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btn_cancle, function(button, event)
			onBtnOk(button)
			return nil
		end, CCControlEventTouchDown)

		self.btn_ok:setTouchPriority(kCCMenuHandlerPriority-1)
		self.btn_ok:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btn_ok, function(button, event)
			onBtnOk(button)
			return nil
		end, CCControlEventTouchDown)
		--]]
	end
end

function onNodeCleanup(self)
	if self.proxy_ then
    	self.proxy_:release()
    end

    layer_base_t.onNodeCleanup(self)
end

--创建测试数据
function createTestData(self)
	--[[
	--]]
end