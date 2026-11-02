--
-- Author: Tango
-- Date: 2015-08-24 21:01:47
-- 宠物列表

module("ui_petListLayer", package.seeall)
baseClass(layer_base_t, ui_petListLayer)

require('ui_layer/ui_petListCell')


function init(self, contentSize, parent)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	local ccbiAttrTable = { name = "sub_ui/PetListView.ccbi", size = contentSize }
	layer_base_t.init(self, true, ccbiAttrTable)

	self.parent = parent
	self.tab = 0
	self.cellNodes = {}

	self.pets = {}

	self:init_ui()
	--self:init_binding_event()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		self.node_content = tolua.cast(self.proxy_:getNode("node_content"), "CCNode")
		self.node_cell = tolua.cast(self.proxy_:getNode("node_cell"), "CCNode")

		self:requestBaseLayerInfo()
	end
end


function requestBaseLayerInfo(self)
	--获取基本信息
	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 3, "rl_x_pet")
	--cclog("rl_x_pet & cmd = 3---%s", urlpath)
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
			--cclog("rl_x_pet ret = %s", resData)
			if item.code == "0" then
				self.pets = {}
				local pets = item:find('pets')
				local size = #pets
				for i=1,size do
					local _id = tonumber(pets[i]:find('id')[1])
					local _typeid = tonumber(pets[i]:find("pet_id")[1])
					local _level = tonumber(pets[i]:find('level')[1])
					local _rank = tonumber(pets[i]:find('rank')[1])
					local _atk = pets[i]:find('attack')[1]
					local _def = pets[i]:find('defense')[1]
					local _chakra = pets[i]:find('chakala')[1]
					local _atkAdd = pets[i]:find('attack_buff')[1]
					local _defAdd = pets[i]:find('defense_buff')[1]
					local _chakraAdd = pets[i]:find('chakala_buff')[1]
					local _star = tonumber(pets[i]:find('star')[1])
                    local _inuse = tonumber(pets[i]:find('work')[1])

					table.insert(self.pets,{
						id = _id, typeid = _typeid, lv = _level, grade =  _rank, star = _star, atk = _atk, def = _def, chakra = _chakra, atkAdd = _atkAdd, defAdd = _defAdd, chakraAdd = _chakraAdd, inuse = _inuse,
						info = CPlayerPet:new(_typeid, _level, _rank, _star), listLayer = self
						})
					
				end

				self:init_ext_ui()
			else
				GetMainMenu():ShowErrorTip(tonumber(item.code),-1)
			end
		end)
end

function init_ext_ui(self)
	--排序  品质>等级>id
    table.sort(self.pets, function (a, b)
    if a.info:getQuality() == b.info:getQuality() then
        if a.info:getLevel() == b.info:getLevel() then
            if a.info:getEqu() == b.info:getEqu() then
                return a.info:getStar() > b.info:getStar()
            else
                return a.info:getEqu() > b.info:getEqu()
            end
        else
            return a.info:getLevel() > b.info:getLevel()
        end
    else
        return a.info:getQuality() > b.info:getQuality()
    end
end)
    --最后插入一行获取入口提示
    table.insert(self.pets, {id = 0, typeid = 0, listLayer = self})
	self:createTableView()
end

function init_binding_event(self)
	if self.proxy_ ~= nil then
		local function CCLayerTouch(event, x, y)
			local rect = self.node_:boundingBox()
			rect.origin = ccp(0, 0)
			local p = self.node_:convertToNodeSpace(ccp(x, y))
			if event == "began" then
				if rect:containsPoint(p) == true then
					return true
				else
					return false
				end
			end
		end

		self.node_:setTouchEnabled(true)
		self.node_:registerScriptTouchHandler(CCLayerTouch, false, -4, true)
	end
end


function createTableView(self)
	-- body
	if self._tableView == nil then
		local cellContentSize = self.node_cell:getContentSize()
		self.cell_size = CCSizeMake(cellContentSize.width, cellContentSize.height)

		self.content_size = self.node_content:getContentSize()
		self:initPicTableHandle()
		self._tableView = LuaTableView:createWithHandler(self._tableViewHandler, CCSizeMake(self.content_size.width, self.content_size.height))
		self._tableView:setDirection(kCCScrollViewDirectionVertical)
		self._tableView:setVerticalFillOrder(kCCTableViewFillTopDown)
		self._tableView:setTouchPriority(kCCMenuHandlerPriority - 1)

		self.node_content:addChild(self._tableView)
	else
		self._tableView:reloadData()
	end
end

function initPicTableHandle(self)
	self._tableViewHandler = LuaEventHandler:create( function(fn, table, a1, a2, x, y)
		local r
		if fn == "cellSize" then
			r = self.cell_size;
		elseif fn == "cellAtIndex" then
			local nodeLayer = createObj(ui_petListCell, self.cell_size, self.pets[a1 + 1], self)
			-- tableView cell container
			self.cellNodes[a1 + 1] = nodeLayer
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
			r = #self.pets;
			-- Cell events:
		elseif fn == "cellTouched" then
			-- A cell was touched, a1 is cell that be touched. This is not necessary.
			--- [[
			local cell_index = a1:getIdx() + 1
			local _layer = self.cellNodes[cell_index]

--			if _layer.btnGet:boundingBox():containsPoint(self.m_touchPoint) then
--				self:onClickedGet(cell_index)
--			end

			self.m_touchPoint = nil
			-- ]]
		elseif fn == "cellTouchBegan" then
			-- A cell is touching, a1 is cell, a2 is CCTouch
			self.m_touchPoint = a2:getLocation()
			self.m_touchPoint = a1:convertToNodeSpace(self.m_touchPoint)

			local cell_index = a1:getIdx() + 1

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


function update_ui(self)
	self:requestBaseLayerInfo()
    self.parent:refreshData()
end

function onNodeCleanup(self)
	-- cclog("1111---001")
	if self.proxy_ then
		self.proxy_:release()
	end
	if self.tableData ~= nil then
		table.remove(self.tableData)
	end
	layer_base_t.onNodeCleanup(self)
end