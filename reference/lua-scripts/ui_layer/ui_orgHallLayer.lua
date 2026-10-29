----------------------------------------------------------------------
--  Copyright (c) 2014-2016, XCKOO. All Rights Reserved.
--  Author :Tango
--  Time   :2014/11/13 14:27:05
--  Remark :组织大厅
----------------------------------------------------------------------
module("ui_orgHallLayer", package.seeall)
baseClass(layer_base_t, ui_orgHallLayer)

function init(self)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	self.contentSize_ = GetMainMenu():GetSubContentNode():getContentSize()
	local ccbiAttrTable = {name="sub_ui/OrgHallView.ccbi", size=self.contentSize_}
	layer_base_t.init(self, true, ccbiAttrTable)

	--pre page
	self.back_page = E_DEFAULTMENU

    --data
   self.tableData = {}
    self.cellNodes = {}

	self.tasks = {}
	self.btnExcute = {nil,nil,nil}
	self.hasExcutedToday = 0

    --init
	self:init_ui()
	self:init_binding_event()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		--node
		self.node_content = tolua.cast(self.proxy_:getNode("node_content"), "CCNode")
		self.node_cell = tolua.cast(self.proxy_:getNode("node_cell"), "CCNode")
		--btn
		self.btn_back = tolua.cast(self.proxy_:getNode("btn_back"), "CCControlButton")
		self.btnManage = tolua.cast(self.proxy_:getNode("btn_manage"), "CCControlButton")
		self.btnSetting = tolua.cast(self.proxy_:getNode("btn_setting"), "CCControlButton")
		self.btnUpgrade = tolua.cast(self.proxy_:getNode("btn_upgrade"), "CCControlButton")

		self.labelMyScore = tolua.cast(self.proxy_:getNode("label_myscore"),"CCLabelTTF") 

		for i=1,3 do
			self.btnExcute[i] = tolua.cast(self.proxy_:getNode("btn_excute_"..tostring(i)), "CCControlButton")
		end
		
		self:initTopBar()
		self:init_ext_topBar()

		--base request
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

function requestBaseLayerInfo(self)
	--获取基本信息
	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 1, "rl_r_group_hall")
	--cclog("rl_r_group_hall & cmd = 1---%s", urlpath)
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
			--cclog("rl_r_group_hall ret = %s", resData)
			local retcode = item.code
			if retcode == "0" then
				local mycheckin = item:find("my_checkin")
				self.hasExcutedToday = tonumber(mycheckin:find("today_checkin")[1])
				self.labelMyScore:setString(localizable.ui_orgMyScore .. mycheckin:find("score")[1])

				self.tasks = item:find("task_list")
				self.tableData = item:find("checkin_log")

				--ext init ui
				self:init_ext_ui()
			else
				GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
			end
		end)
end

function init_ext_ui(self)
	self:createTableView()

	local frameSilver = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("com_silver_icon")
	local frameGold = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("com_gold_icon")
	for i=1,3 do
		local strI = tostring(i)
		local labelBuild = tolua.cast(self.proxy_:getNode("label_addBuild_"..strI), "CCLabelTTF")
		local labelContribution = tolua.cast(self.proxy_:getNode("label_addContribution_"..strI), "CCLabelTTF")
		local labelCost = tolua.cast(self.proxy_:getNode("label_cost_"..strI), "CCLabelBMFont")

		labelBuild:setString(self.tasks[i].group_score)
		labelContribution:setString(self.tasks[i].member_score)
		self.btnExcute[i]:setTag(tonumber(self.tasks[i].taskid))
		labelCost:setString(self.tasks[i].consume)

		local sprConsumeIcon = tolua.cast(self.proxy_:getNode("spr_consume_icon_"..strI), "CCSprite")
		if self.tasks[i].consume_type == "1" then -- 消耗元宝
			sprConsumeIcon:setDisplayFrame(frameGold)
		else -- 消耗银子
			sprConsumeIcon:setDisplayFrame(frameSilver)
		end

	end
	
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
    		local nodeLayer = createObj(ui_orgHallCell, self._cell_size,self.tableData[a1 + 1])
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
			r = #self.tableData;
		    -- Cell events:
		elseif fn == "cellTouched" then			-- A cell was touched, a1 is cell that be touched. This is not necessary.
			--
		elseif fn == "cellTouchBegan" then		-- A cell is touching, a1 is cell, a2 is CCTouch
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


function requestExcute( self, i )
	local taskid = tonumber(self.tasks[i].taskid)
	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 2, "rl_r_group_hall")
	urlpath = AddData(urlpath, "TaskID", taskid)
	--cclog("rl_r_group_hall & cmd = 2---%s", urlpath)
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
			--cclog("rl_r_group_hall ret = %s", resData)
			local retcode = item.code
			if retcode == "0" then -- 刷新近期签到列表
				self.tableData = item:find("checkin_log")
				self._tableView:reloadData()

				local cost = tonumber(self.tasks[i].consume)
				if self.tasks[i].consume_type == "1" then -- 消耗元宝
					--扣除元宝
					self.playerMgr_:AddGold(-cost)
					self.label_goldval:setString(self.playerMgr_:GetPlayerInfoData().m_gold)
				else -- 消耗银子
					self.playerMgr_:AddSilver(-cost)
					self.label_silverval:setString(self.playerMgr_:GetPlayerInfoData().m_silver)
				end

				self.label_goldval:setString(item:find("cash")[1])
				self.label_silverval:setString(item:find("coin")[1])
				self.labelMyScore:setString(localizable.ui_orgMyScore .. item:find("score")[1])
				self.hasExcutedToday = 1
				GetMainMenu():ShowTextTip(localizable.ui_orgHall_taskDone, -1)
			else
				GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
			end
		end)
end

function init_binding_event(self)
	if self.proxy_ ~= nil then
		local function onBtnBack(btn, event)
			--GetMainMenu():ChangeToSub(self.back_page)
			self.node_:removeFromParentAndCleanup(true)
			ShowOrgMapLayer()
		end

		local function onBtnExcute(i)
			if self.hasExcutedToday == 1 then
				GetMainMenu():ShowTextTip(localizable.ui_orgHall_hasSignIn, -1)
				return nil
			end
			self:requestExcute(i)
		end

		self.btn_back:setTouchPriority(kCCMenuHandlerPriority-1)
		self.btn_back:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btn_back, function(button, event)
			onBtnBack(button)
			return nil
		end, CCControlEventTouchDown)

		for i=1,3 do
			self.btnExcute[i]:setTouchPriority(kCCMenuHandlerPriority - 1)
			self.proxy_:handleButtonEvent(self.btnExcute[i], function(button, event)
				onBtnExcute(i)
				return nil
			end, CCControlEventTouchDown)
		end

		self.ctrl_btnplayermsg:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.ctrl_btnplayermsg:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.ctrl_btnplayermsg, function(button, event)
			GetMainMenu():OnShowUserInfo()
			return nil
		end, CCControlEventTouchDown)
	end
end

function createTestData(self)
	for i = 1, 10 do
		local task = {id = i, addBuild = 33*i, addCtrb = 11*i, cost = (10-i)*3}
		table.insert(self.tasks,task)
	end

	--testdata
	for i=1,10 do
		local data = {}
		data.time = 13579*i
		data.name = "成员名称"..tostring(i)
		data.taskType = math.random(3)
		table.insert(self.tableData, data)
		 
	end 
end

function onNodeCleanup(self)
	if self.proxy_ then
    	self.proxy_:release()
    end

    layer_base_t.onNodeCleanup(self)
end
