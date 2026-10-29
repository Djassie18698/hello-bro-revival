----------------------------------------------------------------------
--  Copyright (c) 2014-2016, XCKOO. All Rights Reserved.
--  Author :Tango
--  Time   :2014/12/3 10:14:06
--  Remark :捐献忍术
----------------------------------------------------------------------

module("ui_orgDonateNinjutsuLayer", package.seeall)
baseClass(layer_base_t, ui_orgDonateNinjutsuLayer)

require("ui_layer/ui_orgDonateNinjutsuCell")
local json = require("json")

function init(self,data, preLayer)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	self.contentSize_ = GetMainMenu():GetSubContentNode():getContentSize()
	local ccbiAttrTable = { name = "sub_ui/OrgDonateNinjutsuView.ccbi", size = self.contentSize_ }
	layer_base_t.init(self, true, ccbiAttrTable)

	-- pre page
	self.back_page = E_DEFAULTMENU

	-- data
	self.tableData = { }
	self.cellNodes = { }

	self.data = data
	self.selectList = {}

	self.amount = 0
	self.addBuild = 0
	self.addContrib = 0

	self.preLayer = preLayer

	-- init
	self:init_ui()
	self:init_binding_event()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		-- node
		self.nodeMiddle = tolua.cast(self.proxy_:getNode("node_middle"), "CCNode")
		self.node_content = tolua.cast(self.proxy_:getNode("node_content"), "CCNode")
		self.node_cell = tolua.cast(self.proxy_:getNode("node_cell"), "CCNode")
		-- btn
		self.btn_back = tolua.cast(self.proxy_:getNode("btn_back"), "CCControlButton")
		self.btnOk = tolua.cast(self.proxy_:getNode("btn_ok"), "CCControlButton")

		self.labelAmount = tolua.cast(self.proxy_:getNode("label_select_amount"), "CCLabelTTF")
		self.labelAddBuild = tolua.cast(self.proxy_:getNode("label_addBuild"), "CCLabelTTF")
		self.labelAddContrib = tolua.cast(self.proxy_:getNode("label_addContrib"), "CCLabelTTF")


		self:initTopBar()
		self:init_ext_topBar()

		-- base request
		self:requestBaseLayerInfo()
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
	end
end

-- 人物信息
function init_ext_topBar(self)
	if self.proxy_ ~= nil then
		local meritIcon = self.playerMgr_:GetMeritIcon()
		if meritIcon ~= nil then
			local pFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(meritIcon)
			if pFrame ~= nil then
				self.sprite_playermedal:setDisplayFrame(pFrame)
			end
		end
		-- exp
		self.label_name:setString(self.playerData_.m_name)
		local nextExp = self.playerMgr_:GetNextLevelExp()
		local expStr = tostring(self.playerData_.m_exp) .. "/" .. tostring(nextExp)
		self.label_curexp:setString(expStr)
		self.sprite_levelstate:setScaleX(self.playerData_.m_exp / nextExp)

		-- vipinfo
		local viplevel = self.playerData_.m_viplevel
		local vipframes = {
			[0] = "vip_015",
			[1] = "vip_003",
			[2] = "vip_004",
			[3] = "vip_005",
			[4] = "vip_006",
			[5] = "vip_007",
			[6] = "vip_008",
			[7] = "vip_009",
			[8] = "vip_010",
			[9] = "vip_011",
			[10] = "vip_012",
			[11] = "vip_013",
			[12] = "vip_014",
			[13] = "vip_s_13",
			[14] = "vip_s_14",
			[15] = "vip_s_15",
			[16] = "vip_s_16",
			[17] = "vip_s_17",
			[18] = "vip_s_18"
		}
		if self.sprite_vipinfo ~= nil then
			local pFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(vipframes[viplevel])
			self.sprite_vipinfo:setDisplayFrame(pFrame)
		end

		-- bodyval
		local maxbodyval = self.playerMgr_:GetMaxBodyValue()
		local bodyValStr = tostring(self.playerData_.m_bodyvalue) .. "/" .. tostring(maxbodyval)
		self.label_bodyval:setString(bodyValStr)
		local scaleVal = self.playerData_.m_bodyvalue / maxbodyval
		if scaleVal > 1 then
			scaleVal = 1
		end
		self.sprite_bodyratio:setScaleX(scaleVal)

		-- attack
		local maxattack = self.playerMgr_:GetMaxAttackCount()
		local attackValStr = tostring(self.playerData_.m_fightcount) .. "/" .. tostring(maxattack)
		self.label_attackval:setString(attackValStr)
		self.sprite_attackratio:setScaleX(self.playerData_.m_fightcount / maxattack)

		-- gold & silver
		self.label_goldval:setString(tostring(self.playerData_.m_gold))
		self.label_silverval:setString(tostring(self.playerData_.m_silver))
		self.label_level:setString(tostring(self.playerData_.m_level))
	end
end

function requestBaseLayerInfo(self)
	-- 获取基本信息
	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 3, "rl_r_group_contri")
	urlpath = AddData(urlpath, "GroupId", global.myOrgId)
	urlpath = AddData(urlpath, "ContriType", 4)
	-- cclog("rl_r_group_contri & cmd = 3---%s", urlpath)
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
		-- cclog("rl_r_group_contri ret = %s", resData)
		local retcode = item.code
		if retcode == "0" then
			self.tableData = {}
			local itemlist = item:find("item_list")
			for i = 1, #itemlist do
				itemlist[i]["selected"] = false
				table.insert(self.tableData, itemlist[i])
			end
			
			-- ext init ui
			self:init_ext_ui()
		else
			GetMainMenu():ShowErrorTip(tonumber(retcode), -1)
		end
	end )
end

function init_ext_ui(self)
	self:createTableView()

	self:updateUI()
end

function updateUI( self )
	self.labelAmount:setString(self.amount)
	self.labelAddBuild:setString(self.addBuild)
	self.labelAddContrib:setString(self.addContrib)
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

function donate(self)
	if #self.selectList == 0 then
		GetMainMenu():ShowTextTip(localizable.ui_orgDonate_pls_select, -1)
		return nil
	end
	local listStr = json.encode(self.selectList) -- 转成json字符串

	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 4, "rl_r_group_contri")
	urlpath = AddData(urlpath, "BagIndex", listStr)
	urlpath = AddData(urlpath, "ContriType", 4)
	urlpath = AddData(urlpath, "GroupId", global.myOrgId)
	--cclog("rl_r_group_contri & cmd = 4---%s", urlpath)
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
			--cclog("rl_r_group_contri ret = %s", resData)
			local retcode = item.code
			if retcode == "0" then
				GetMainMenu():ShowTextTip(localizable.ui_orgDonate_suc, -1)
				-- 清空选择数据
				self.amount = 0
				self.addBuild = 0
				self.addContrib = 0
				self:updateUI()

				-- 删除捐献的卡
				for i,id in ipairs(self.selectList) do
					CPlayerDataMgr:instance():RemoveObjByID(tonumber(id))
				end

				self.tableData = {}
				local itemlist = item:find("item_list")
				for i = 1, #itemlist do
					itemlist[i]["selected"] = false
					table.insert(self.tableData, itemlist[i])
				end

				self._tableView:reloadData()
				self.node_:removeFromParentAndCleanup(true)

				if self.preLayer then
					self.preLayer:onDonateSuc()
				end
			else
				GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
			end
		end)
end
function initTableHandle(self)

	local function onBtnDetail(index)
		cclog('sdfsdfs:%d',index)
		local cardid = tonumber(self.tableData[index].cardid)
		if nil ~= cardid then
			-- 前两个参数代表大类型和子类型，c++层搜索ShowCommonItemDetail可知详细
			CGameObjElement:ShowCommonItemDetail(1,4,cardid,"")
		end
	end

	self._tableViewHandler = LuaEventHandler:create( function(fn, table, a1, a2, x, y)
		local r
		if fn == "cellSize" then
			r = self._cell_size;
		elseif fn == "cellAtIndex" then
			local nodeLayer = createObj(ui_orgDonateNinjutsuCell, self._cell_size, self.tableData[a1 + 1],self)
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
			r = #self.tableData;
			-- Cell events:
		elseif fn == "cellTouched" then
			-- A cell was touched, a1 is cell that be touched. This is not necessary.
			--- [[
			local cell_index = a1:getIdx() + 1
			local _layer = self.cellNodes[cell_index]
			local pos = a1:convertToNodeSpace(ccp(x, y))
			if _layer.sprCardFrame:boundingBox():containsPoint(pos) then
				onBtnDetail(cell_index)
			end
			-- ]]
		elseif fn == "cellTouchBegan" then
			-- A cell is touching, a1 is cell, a2 is CCTouch
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

function init_binding_event(self)
	if self.proxy_ ~= nil then
		--屏蔽掉后层触摸事件
		local function CCLayerTouch(event, x, y)
			if event == "began" then
				local rect = self.nodeMiddle:boundingBox()
				rect.origin = ccp(0,0)
				local p = self.nodeMiddle:convertToNodeSpace(ccp(x,y))
				if rect:containsPoint(p) == true then
					return true
				else
					return false
				end
			end
		end
		
		self.node_:setTouchEnabled(true)
		self.node_:registerScriptTouchHandler(CCLayerTouch, false, kCCMenuHandlerPriority-1, true)

		local function onBtnBack(btn, event)
			self.node_:removeFromParentAndCleanup(true)
			--ShowOrgMapLayer()
		end

		self.btn_back:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.btn_back:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btn_back, function(button, event)
			onBtnBack(button)
			return nil
		end , CCControlEventTouchDown)

		self.btnOk:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.btnOk:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btnOk, function(button, event)
			self:donate()
			return nil
		end , CCControlEventTouchDown)

		self.ctrl_btnplayermsg:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.ctrl_btnplayermsg:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.ctrl_btnplayermsg, function(button, event)
			GetMainMenu():OnShowUserInfo()
			return nil
		end, CCControlEventTouchDown)

	end
end

function onSelectChanged(self)
	self.selectList = {}
	self.addContrib = 0
	self.addBuild = 0
	for i,cell in ipairs(self.cellNodes) do
		local celldata = self.tableData[i]
		if celldata.selected == true then
			if celldata.star_level == "4" then
				self.addContrib = self.addContrib + tonumber(self.data.user_score4)
				self.addBuild = self.addBuild + tonumber(self.data.group_score4)
			elseif celldata.star_level == "5" then
				self.addContrib = self.addContrib + tonumber(self.data.user_score5)
				self.addBuild = self.addBuild + tonumber(self.data.group_score5)
			end
			
			table.insert(self.selectList,celldata.bagindex)
		end
	end
	self.amount = #self.selectList
	self:updateUI()
end


function onNodeCleanup(self)
	if self.proxy_ then
		self.proxy_:release()
	end

	layer_base_t.onNodeCleanup(self)
end