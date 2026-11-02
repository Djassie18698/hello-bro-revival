--descriptioin:属性丹 
--company: xckoo
--author: litao
--date: 2014-05-13
---------------------------------------------
module("ui_attributeDanNinjaListLayer", package.seeall)
baseClass(layer_base_t, ui_attributeDanNinjaListLayer)

function init(self, node, data)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	self.contentSize_ = GetMainMenu():GetSubContentNode():getContentSize()
	local ccbiAttrTable = {name="sub_ui/AttributeDanNinjaList.ccbi", size=self.contentSize_}
	layer_base_t.init(self, true, ccbiAttrTable)

	self.preNode = node

	self.m_ninjaList = data

	--
	--tableView cell container
	self.cellNodes = {}
	--touch
	self.m_touchPoint = nil
	
	self:init_ui()
	self:init_binding_event()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		self.btn_back = tolua.cast(self.proxy_:getNode("btn_back"), "CCControlButton")
		self.node_table_content = tolua.cast(self.proxy_:getNode("node_tablecontent"), "CCNode")
		self.node_card_cell = tolua.cast(self.proxy_:getNode("node_cardcontent"), "CCNode")

		--
		self:initTopBar()

		self:initTableView()	
	end
end

function initTopBar(self)
	if self.proxy_ ~= nil then
		self.sprite_playermedal = tolua.cast(self.proxy_:getNode("sprite_playermedal"), "CCSprite")
		self.label_level = tolua.cast(self.proxy_:getNode("label_level"), "CCLabelBMFont")
		self.label_curexp = tolua.cast(self.proxy_:getNode("label_curexp"), "CCLabelBMFont")
		self.label_name = tolua.cast(self.proxy_:getNode("label_name"), "CCLabelTTF")
		self.sprite_vipinfo = tolua.cast(self.proxy_:getNode("sprite_vipinfo"), "CCSprite")
		self.label_bodyval = tolua.cast(self.proxy_:getNode("label_bodyval"), "CCLabelBMFont")
		self.label_attackval = tolua.cast(self.proxy_:getNode("label_attackval"), "CCLabelBMFont")
		self.label_goldval = tolua.cast(self.proxy_:getNode("label_goldval"), "CCLabelBMFont")
		self.label_silverval = tolua.cast(self.proxy_:getNode("label_silverval"), "CCLabelBMFont")
		self.ctrl_btnplayermsg = tolua.cast(self.proxy_:getNode("ctrl_btnplayermsg"), "CCControlButton")
		self.sprite_levelstate = tolua.cast(self.proxy_:getNode("sprite_levelstate"), "CCSprite")
		self.sprite_bodyratio = tolua.cast(self.proxy_:getNode("sprite_bodyratio"), "CCSprite")
		self.sprite_attackratio = tolua.cast(self.proxy_:getNode("sprite_attackratio"), "CCSprite")

		self:init_ext_topBar()
	end
end

--人物信息
function init_ext_topBar(self)
	if self.proxy_ ~= nil then
		local meritIcon = self.playerMgr_:GetMeritIcon()
		if meritIcon ~= nil then
			local pFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(meritIcon)
			if pFrame ~= nil then
				self.sprite_playermedal:setDisplayFrame(pFrame)
			end
		end
		--exp
		self.label_name:setString(self.playerData_.m_name)
		local nextExp = self.playerMgr_:GetNextLevelExp()
		local expStr = tostring(self.playerData_.m_exp) .. "/" .. tostring(nextExp)
		self.label_curexp:setString(expStr)
		self.sprite_levelstate:setScaleX(self.playerData_.m_exp / nextExp)

		--vipinfo
		local viplevel = self.playerData_.m_viplevel
		local vipframes={[0] = "vip_015",[1]="vip_003",[2]="vip_004",[3]="vip_005",[4]="vip_006",
			[5]="vip_007",[6]="vip_008",[7]="vip_009",[8]="vip_010",[9]="vip_011",[10]="vip_012",[11]="vip_013",[12]="vip_014",[13]="vip_s_13",[14] = "vip_s_14",[15] = "vip_s_15",[16]="vip_s_16",[17]="vip_s_17",[18]="vip_s_18"}
		if self.sprite_vipinfo ~= nil then
			local pFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(vipframes[viplevel])
			self.sprite_vipinfo:setDisplayFrame(pFrame)
		end

		--bodyval
		local maxbodyval = self.playerMgr_:GetMaxBodyValue()
		local bodyValStr = tostring(self.playerData_.m_bodyvalue) .. "/" .. tostring(maxbodyval)
		self.label_bodyval:setString(bodyValStr)
		local scaleVal = self.playerData_.m_bodyvalue / maxbodyval
		if scaleVal > 1 then
			scaleVal = 1
		end
		self.sprite_bodyratio:setScaleX(scaleVal)

		--attack
		local maxattack = self.playerMgr_:GetMaxAttackCount()
		local attackValStr = tostring(self.playerData_.m_fightcount) .. "/" .. tostring(maxattack)
		self.label_attackval:setString(attackValStr)
		self.sprite_attackratio:setScaleX(self.playerData_.m_fightcount / maxattack)

		--gold & silver
		self.label_goldval:setString(tostring(self.playerData_.m_gold))
		self.label_silverval:setString(tostring(self.playerData_.m_silver))
		self.label_level:setString(tostring(self.playerData_.m_level))
	end
end

function init_binding_event(self)
	if self.proxy_ ~= nil then
		local function onBtnBack(btn, event)
			self.node_:removeFromParentAndCleanup(true)
		end

		local function CCLayerTouch(event, x, y)
			local rect = self.node_:boundingBox()
			rect.origin = ccp(0,0)
			local p = self.node_:convertToNodeSpace(ccp(x,y))
			if event == "began" then
				if rect:containsPoint(p) == true then
					return true
				else
					return false
				end
			end
		end

		self.node_:setTouchEnabled(true)
		self.node_:registerScriptTouchHandler(CCLayerTouch, false, kCCMenuHandlerPriority-2, true)

		self.btn_back:setTouchPriority(kCCMenuHandlerPriority-2)
		self.btn_back:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btn_back, function(button, event)
			onBtnBack(button)
			return nil
		end, CCControlEventTouchDown)
	end
end

function initTableView(self)
	-- body
	if self.tableview == nil then
		self.cellsize = self.node_card_cell:getContentSize()
		self.tableContentSize = self.node_table_content:getContentSize()
		self:initHandle()
		self.tableview = LuaTableView:createWithHandler(self.tableViewHandler, CCSizeMake(self.tableContentSize.width, self.tableContentSize.height))

		self.tableview:setDirection(kCCScrollViewDirectionVertical)
		self.tableview:setVerticalFillOrder(kCCTableViewFillTopDown)
		self.tableview:setTouchPriority(kCCMenuHandlerPriority-2)
		self.node_table_content:addChild(self.tableview)
	else
		self.tableview:reloadData()
	end
end


function initHandle(self)
	self.tableViewHandler = LuaEventHandler:create(function(fn, table, a1, a2, x, y)
		local r
		if fn == "cellSize" then
			r = self.cellsize
		elseif fn == "cellAtIndex" then
    		local nodeLayer = createObj(ui_attributeDanNinjaItem, self.m_ninjaList[a1 + 1], self.cellsize, a1 + 1)
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
			r = #self.m_ninjaList
		-- Cell events:
		elseif fn == "cellTouched" then			-- A cell was touched, a1 is cell that be touched. This is not necessary.
			local cell_index = a1:getIdx() + 1
			--local cellData = self.m_taskDatas[cell_index]
			self.cellNodes[cell_index].spr_btn_select:setScale(1.0)
			if self.cellNodes[cell_index].spr_btn_select:boundingBox():containsPoint(self.m_touchPoint) then
				self:setSelectedCardBagID(cell_index)
			end

			self.m_touchPoint = nil  
		elseif fn == "cellTouchBegan" then		-- A cell is touching, a1 is cell, a2 is CCTouch
			self.m_touchPoint = a2:getLocation()	
			self.m_touchPoint = a1:convertToNodeSpace(self.m_touchPoint)

			local cell_index = a1:getIdx() + 1
			if self.cellNodes[cell_index].spr_btn_select:boundingBox():containsPoint(self.m_touchPoint) then
				self.cellNodes[cell_index].spr_btn_select:setScale(1.1)		
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

function setSelectedCardBagID(self, _index)
	--
	local _id = self.m_ninjaList[_index]:GetGUID()
	self.preNode:setSelectedNinjaForChange(_index)

	self.node_:removeFromParentAndCleanup(true)	
end

function onNodeCleanup(self)
	--cclog("1111---001")
	if self.proxy_ then
    	self.proxy_:release()
    end
 
    layer_base_t.onNodeCleanup(self)
end