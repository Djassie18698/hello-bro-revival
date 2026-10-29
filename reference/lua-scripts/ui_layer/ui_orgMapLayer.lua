----------------------------------------------------------------------
--  Copyright (c) 2014-2016, XCKOO. All Rights Reserved.
--  Author :Tango
--  Time   :2014/11/11 15:23:34
--  Remark :组织地图
----------------------------------------------------------------------


module("ui_orgMapLayer", package.seeall)
baseClass(layer_base_t, ui_orgMapLayer)

local Key = {
	hall = 1,
	org = 2,
	donate = 3,
	rankings = 4,
	shop = 5
}

function init(self)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	self.contentSize_ = GetMainMenu():GetSubContentNode():getContentSize()
	local ccbiAttrTable = { name = "sub_ui/OrgMapView.ccbi", size = self.contentSize_ }
	layer_base_t.init(self, true, ccbiAttrTable)

	-- pre page
	self.back_page = E_DEFAULTMENU

	self.buildings = { }
	self.labelBuildLv = { }

	-- init
	self:init_ui()
	self:init_binding_event()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		self.buildings[Key.hall] = tolua.cast(self.proxy_:getNode("spr_hall"), "CCSprite")
		self.buildings[Key.org] = tolua.cast(self.proxy_:getNode("spr_org"), "CCSprite")
		self.buildings[Key.donate] = tolua.cast(self.proxy_:getNode("spr_donate"), "CCSprite")
		self.buildings[Key.rankings] = tolua.cast(self.proxy_:getNode("spr_rankings"), "CCSprite")
		self.buildings[Key.shop] = tolua.cast(self.proxy_:getNode("spr_shop"), "CCSprite")
		self.container = tolua.cast(self.proxy_:getNode("node_container"), "CCNode")

		for i=1,5 do
			self.labelBuildLv[i] = tolua.cast(self.proxy_:getNode("label_lv_" .. i), "CCLabelTTF")
		end

		self:initTopBar()
		self:init_ext_topBar()

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
	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 9, "rl_r_group_comm")
	urlpath = AddData(urlpath, "GroupId", global.myOrgId)
	--cclog("rl_r_group_comm & cmd = 9---%s", urlpath)
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
			--cclog("rl_r_group_comm ret = %s", resData)
			local retcode = item.code
			if retcode == "0" then
				--local items = item:find("item_list")
				self.labelBuildLv[Key.org]:setString(localizable.ui_orgBuildLv .. item:find("item1").level)
				self.labelBuildLv[Key.shop]:setString(localizable.ui_orgBuildLv .. item:find("item2").level)
				self.labelBuildLv[Key.donate]:setString(localizable.ui_orgBuildLv .. item:find("item3").level)
				self.labelBuildLv[Key.hall]:setString(localizable.ui_orgBuildLv .. item:find("item4").level)
				--self.labelBuildLv[Key.rankings]:setString(localizable.ui_orgBuildLv .. item:find("item5").level)
					
				self:init_ext_ui()
			else
				GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
			end
		end)
end

function init_ext_ui(self)
	--
end


function updateUI(self)
	-- update UI
end

function init_binding_event(self)
	if self.proxy_ ~= nil then
		local function CCLayerTouch(event, x, y)
			local radiusSQ = 10000
			local rect = self.container:boundingBox()
			rect.origin = ccp(0, 0)
			local p = self.node_:convertToNodeSpace(ccp(x, y))
			if event == "began" then
				if rect:containsPoint(p) == true then
					for i, v in ipairs(self.buildings) do
						if distanceSQ(ccp(v:getPosition()), p) < radiusSQ then
							v:runAction(CCScaleTo:create(0.1, 1.1))
							return true
						end
					end
					return true
				else
					return false
				end
			elseif event == "ended" then
				if distanceSQ(ccp(self.buildings[Key.rankings]:getPosition()), p) < radiusSQ then
					self.buildings[Key.rankings]:setScale(1)
					self.node_:removeFromParentAndCleanup(true)
					ShowOrgRankings()
				elseif distanceSQ(ccp(self.buildings[Key.org]:getPosition()), p) < radiusSQ then
					self.buildings[Key.org]:setScale(1)
					self.node_:removeFromParentAndCleanup(true)
					ShowOrgMainView()
				elseif distanceSQ(ccp(self.buildings[Key.hall]:getPosition()), p) < radiusSQ then
					self.buildings[Key.hall]:setScale(1)
					self.node_:removeFromParentAndCleanup(true)
					ShowOrgHall()
				elseif distanceSQ(ccp(self.buildings[Key.donate]:getPosition()), p) < radiusSQ then
					self.buildings[Key.donate]:setScale(1)
					self.node_:removeFromParentAndCleanup(true)
					ShowOrgDonate()
				elseif distanceSQ(ccp(self.buildings[Key.shop]:getPosition()), p) < radiusSQ then
					self.buildings[Key.shop]:setScale(1)
					self.node_:removeFromParentAndCleanup(true)
					ShowOrgShop()
				else
					-- 全都没命中，则恢复原来大小
					for i, v in ipairs(self.buildings) do
						v:runAction(CCScaleTo:create(0.1, 1.0))
					end
				end
			end

		end

		self.node_:setTouchEnabled(true)
		self.node_:registerScriptTouchHandler(CCLayerTouch, false, kCCMenuHandlerPriority - 1, true)

		self.ctrl_btnplayermsg:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.ctrl_btnplayermsg:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.ctrl_btnplayermsg, function(button, event)
			GetMainMenu():OnShowUserInfo()
			return nil
		end, CCControlEventTouchDown)
	end
end

function onNodeCleanup(self)
	if self.proxy_ then
		self.proxy_:release()
	end

	layer_base_t.onNodeCleanup(self)
end