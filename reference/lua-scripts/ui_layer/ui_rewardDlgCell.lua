--descriptioin:奖励框cell
--company: xckoo
--litao
--2014.5.8
---------------------------------------------
module("ui_rewardDlgCell", package.seeall)
baseClass(layer_base_t, ui_rewardDlgCell)

function init(self, cellSize, data)
	local ccbiAttrTable = {name="sub_ui/SweepRewardDlgCell.ccbi", size=cellSize}
	layer_base_t.init(self, true, ccbiAttrTable)

	--用户info
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()
	--
	self.m_awardDatas = data
	--
	self.m_cardDatas = {}

	--tableView cell container
	self.cellNodes = {}
	--data
	self.m_levelDatas = {}
	--touch
	self.m_touchPoint = nil

	--create data
	--self:createData()

	--init
	self:init_ui()		
	self:init_binding_event()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		--label
		self.label_title = tolua.cast(self.proxy_:getNode("label_title_name"), "CCLabelTTF")
		self.label_silver = tolua.cast(self.proxy_:getNode("label_silver"), "CCLabelTTF")
		self.label_exp = tolua.cast(self.proxy_:getNode("label_exp"), "CCLabelTTF")
		--node
		self.node_exp_sliver = tolua.cast(self.proxy_:getNode("node_exp_sliver"), "CCNode")
		self.node_content = tolua.cast(self.proxy_:getNode("node_content"), "CCNode")
		self.node_cell = tolua.cast(self.proxy_:getNode("node_cell"), "CCNode")
		--spr
		self.spr_sliver = tolua.cast(self.proxy_:getNode("spr_sliver"), "CCSprite")
		self.spr_exp = tolua.cast(self.proxy_:getNode("spr_exp"), "CCSprite")

		--get info
		self:init_ext_ui()
	end
end

function init_ext_ui(self)	
	if nil == self.m_awardDatas then
		return nil
	end
	self.label_title:setString(self.m_awardDatas.name)
	self.label_silver:setString(self.m_awardDatas.m_silver)
	self.label_exp:setString(self.m_awardDatas.m_exp)

	if #self.m_awardDatas.m_chiplist > 0 then
		for i=1,#self.m_awardDatas.m_chiplist do
			local t_info = self.m_awardDatas.m_chiplist[i]
			table.insert(self.m_cardDatas, t_info)
		end	
	end	
	if #self.m_awardDatas.m_cardlist > 0 then
		for i=1,#self.m_awardDatas.m_cardlist do
			local t_info = self.m_awardDatas.m_cardlist[i]
			table.insert(self.m_cardDatas, t_info)
		end	
	end
	if #self.m_awardDatas.m_proplist > 0 then
		for i=1,#self.m_awardDatas.m_proplist do
			local t_info = self.m_awardDatas.m_proplist[i]
			table.insert(self.m_cardDatas, t_info)
		end	
	end

	--列表
	if #self.m_cardDatas > 0 then
		--cclog("m_cardDatas_count = %s", #self.m_cardDatas)
		self:createTableView()
	end
end

function createTableView(self)
	if self._tableView == nil then
		local cellContentSize = self.node_cell:getContentSize()
		self._cell_size = CCSizeMake(cellContentSize.width,cellContentSize.height)

		self._content_size = self.node_content:getContentSize()
		self:initTableHandle()
		self._tableView = LuaTableView:createWithHandler(self._tableViewHandler, CCSizeMake(self._content_size.width, self._content_size.height))
		self._tableView:setDirection(kCCScrollViewDirectionHorizontal)
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
    		local nodeLayer = createObj(ui_rewardDlgCell_cell, self._cell_size, self.m_cardDatas[a1 + 1])
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
			r = #self.m_cardDatas
		    -- Cell events:
		elseif fn == "cellTouched" then			-- A cell was touched, a1 is cell that be touched. This is not necessary.
			---[[
			local cell_index = a1:getIdx() + 1		
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
	end
end

function onNodeCleanup(self)
	---[[
	if self.proxy_ then
    	self.proxy_:release()
    	self.proxy_ = nil
    end
	--]]
    layer_base_t.onNodeCleanup(self)
end

--创建测试数据
function createData(self)
	---[[
	--]]
end