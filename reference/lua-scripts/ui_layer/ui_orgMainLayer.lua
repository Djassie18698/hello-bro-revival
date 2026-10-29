----------------------------------------------------------------------
--  Copyright (c) 2014-2016, XCKOO. All Rights Reserved.
--  Author :Tango
--  Time   :2014/11/11 11:28:07
--  Remark :组织主页面
----------------------------------------------------------------------
module("ui_orgMainLayer", package.seeall)
baseClass(layer_base_t, ui_orgMainLayer)

function init(self)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	self.contentSize_ = GetMainMenu():GetSubContentNode():getContentSize()
	local ccbiAttrTable = { name = "sub_ui/OrgMainView.ccbi", size = self.contentSize_ }
	layer_base_t.init(self, true, ccbiAttrTable)

	-- pre page
	self.back_page = E_DEFAULTMENU

	-- data
	self.tableData = { }
	self.cellNodes = { }

	self.myPos = 0  --我的职位

	-- init
	self:init_ui()
	self:init_binding_event()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		-- node
		self.node_content = tolua.cast(self.proxy_:getNode("node_content"), "CCNode")
		self.node_cell = tolua.cast(self.proxy_:getNode("node_cell"), "CCNode")
		-- btn
		self.btn_back = tolua.cast(self.proxy_:getNode("btn_back"), "CCControlButton")
		self.btnManage = tolua.cast(self.proxy_:getNode("btn_manage"), "CCControlButton")
		self.btnSetting = tolua.cast(self.proxy_:getNode("btn_setting"), "CCControlButton")
		self.btnUpgrade = tolua.cast(self.proxy_:getNode("btn_upgrade"), "CCControlButton")
		self.btnQuit = tolua.cast(self.proxy_:getNode("btn_quit"), "CCControlButton")

		-- label
		self.labelOrgName = tolua.cast(self.proxy_:getNode("label_orgName"), "CCLabelTTF")
		self.labelOrgLv = tolua.cast(self.proxy_:getNode("label_org_level"), "CCLabelTTF")
		self.labelOrgBuild = tolua.cast(self.proxy_:getNode("label_build"), "CCLabelTTF")
		self.labelOrgPopulation = tolua.cast(self.proxy_:getNode("label_population"), "CCLabelTTF")

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
	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 1, "rl_w_group_admin")
	-- cclog("rl_w_group_admin & cmd = 1---%s", urlpath)
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
			local info = item:find("group_info")
			self.labelOrgName:setString(info:find("name")[1])
			self.labelOrgLv:setString(info:find("level")[1])
			self.labelOrgBuild:setString(info:find("score")[1])
			self.labelOrgPopulation:setString(info:find("curcount")[1] .. "/" .. info:find("totalcount")[1])

			self.myPos = tonumber(item:find("pos")[1])

			-- ext init ui
			self:init_ext_ui()
		else
			GetMainMenu():ShowErrorTip(tonumber(retcode), -1)
		end
	end )
end

function init_ext_ui(self)
	--
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
			local nodeLayer = createObj(ui_orgMainCell, self._cell_size, self.tableData[a1 + 1])
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
			--
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

function updateUI(self)
	-- update UI
end

function init_binding_event(self)
	if self.proxy_ ~= nil then
		local function onBtnBack(btn, event)
			-- GetMainMenu():ChangeToSub(self.back_page)
			self.node_:removeFromParentAndCleanup(true)
			ShowOrgMapLayer()
		end

		local function onBtnManage(btn, event)
			require("ui_layer/ui_orgMemManageLayer")
			showModelLayer(ui_orgMemManageLayer, self)
		end

		local function onBtnSetting(btn, event)
			require("ui_layer/ui_orgSettingLayer")
			showModelLayer(ui_orgSettingLayer)
		end

		local function onBtnUpgrade(btn, event)
			require("ui_layer/ui_orgUpgradeLayer")
			showModelLayer(ui_orgUpgradeLayer, self)
		end

		self.btn_back:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.btn_back:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btn_back, function(button, event)
			onBtnBack(button)
			return nil
		end , CCControlEventTouchDown)

		self.btnSetting:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.btnSetting:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btnSetting, function(button, event)
			onBtnSetting(button)
			return nil
		end , CCControlEventTouchDown)

		self.btnManage:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.btnManage:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btnManage, function(button, event)
			onBtnManage(button)
			return nil
		end , CCControlEventTouchDown)

		self.btnUpgrade:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.btnUpgrade:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btnUpgrade, function(button, event)
			onBtnUpgrade(button)
			return nil
		end , CCControlEventTouchDown)

		self.ctrl_btnplayermsg:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.ctrl_btnplayermsg:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.ctrl_btnplayermsg, function(button, event)
			GetMainMenu():OnShowUserInfo()
			return nil
		end , CCControlEventTouchDown)

		self.btnQuit:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.proxy_:handleButtonEvent(self.btnQuit, function(button, event)
			self:quit()
			return nil
		end , CCControlEventTouchDown)
	end
end

function quit( self )
	local function gotoDemise( )
		require("ui_layer/ui_orgMemOfficeLayer")
		showModelLayer(ui_orgMemOfficeLayer,self)
	end

	local function doQuit( )
		self:requestQuit()
	end

	if self.myPos == 3 then -- 首领不能直接退出
		local dlg = CommonDialogView.create()
		CommonDialogView.m_selfview = dlg
		dlg:SetTitle(localizable.ui_rouletteLayer_title)
		dlg:SetDescription(localizable.ui_orgLeaderQuit)
		dlg:loadCCBI()
		dlg:initUI()
		dlg:SetConfirmHandler(gotoDemise)
		GetMainMenu():GetModelLayer():AddDialog(dlg, 3)
	else
		local dlg = CommonDialogView.create()
		CommonDialogView.m_selfview = dlg
		dlg:SetTitle(localizable.ui_rouletteLayer_title)
		dlg:SetDescription(localizable.ui_orgMemQuit)
		dlg:loadCCBI()
		dlg:initUI()
		dlg:SetConfirmHandler(doQuit)
		GetMainMenu():GetModelLayer():AddDialog(dlg, 3)
	end

end

function requestQuit( self )
	-- 获取基本信息
	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 10, "rl_r_group_comm")
	-- cclog("rl_r_group_comm & cmd = 10---%s", urlpath)
	GetMainMenu():ShowLoadingDlg()
	CCHttpRequest:open(urlpath, kHttpPost, "query=param1&other=params"):sendWithHandler(
	function(res, hnd)
		GetMainMenu():CloseLoadding()
		local resData = res:getResponseData()
		local code = res:getResponseCode()
		local xfile = xml.parse(resData)
		local item = xfile:find("RENLONG")
		if item.code == "0" then
			GetMainMenu():ShowTextTip(localizable.ui_orgQuitSuc, -1)
			self.node_:removeFromParentAndCleanup(true)
			GetMainMenu():ChangeToSub(E_DEFAULTMENU)
			global.myOrgid = 0
		else
			GetMainMenu():ShowErrorTip(tonumber(item.code), -1)
		end
	end )
end

function createTestData(self)
	-- testdata
	for i = 1, 10 do
		local data = { }
		data.name = "成员名称" .. tostring(i)
		data.level = tostring(i)
		data.title = "职位" .. tostring(i)
		data.contribution = tostring(777 * i)
		data.lastLogin = tostring(i) .. '三天前'
		table.insert(self.tableData, data)
	end
end

function refresh(self)
	self:requestBaseLayerInfo()
end

function onNodeCleanup(self)
	if self.proxy_ then
		self.proxy_:release()
	end

	layer_base_t.onNodeCleanup(self)
end
