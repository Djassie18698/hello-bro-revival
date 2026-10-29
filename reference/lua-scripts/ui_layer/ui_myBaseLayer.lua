----------------------------------------------------------------------
--  Copyright (c) 2014-2016, XCKOO. All Rights Reserved.
--  Author :Tango
--  Time   :2015-8-19 21:23:19
--  Remark :个人基地
----------------------------------------------------------------------


module("ui_myBaseLayer", package.seeall)
baseClass(layer_base_t, ui_myBaseLayer)

require('ui_layer/ui_petMainLayer')
require("ui_layer/ui_ninjaTestMain")
require("ui_layer/ui_tupoLayer")

local buildings = {
	{name = localizable.ui_label_petlist_text, openlv = 150, moduleName = ui_petMainLayer},
	{name = localizable.ui_label_ninjatest_text, openlv = 45, moduleName = ui_ninjaTestMain},
	{name = localizable.ui_myBase_building3, openlv = 0, moduleName = "ShowAdvanceEquipView"},
	{name = localizable.ui_label_tupo, openlv = 0, moduleName = ui_tupoLayer}
}

function init(self)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	self.contentSize_ = GetMainMenu():GetSubContentNode():getContentSize()
	local ccbiAttrTable = { name = "sub_ui/MyBaseView.ccbi", size = self.contentSize_ }
	layer_base_t.init(self, true, ccbiAttrTable)

	-- pre page
	self.back_page = E_DEFAULTMENU

	self.sprBuildings = { }
	self.lbOpenLv = { }

	self.amount = #buildings

	-- init
	self:init_ui()
	self:init_binding_event()
end

function refreshData(self)
    getLabelBMFontFromCCB(self.proxy_,"label_goldval"):setString(self.playerData_.m_gold)
    getLabelBMFontFromCCB(self.proxy_,"label_silverval"):setString(self.playerData_.m_silver)
end

function init_ui(self)
	if self.proxy_ ~= nil then
		for i=1,self.amount do
			table.insert(self.sprBuildings, tolua.cast(self.proxy_:getNode("spr_building" .. i), "CCSprite"))
			table.insert(self.lbOpenLv, tolua.cast(self.proxy_:getNode("lb_name" .. i), "CCLabelTTF"))
		end

		self.container = tolua.cast(self.proxy_:getNode("node_container"), "CCNode")

		initHeader(self.proxy_)

		--self:requestBaseLayerInfo()

		for i,v in ipairs(buildings) do
			self.lbOpenLv[i]:setString(v.name)
		end
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

			else
				GetMainMenu():ShowErrorTip(tonumber(retcode),-1)
			end
		end)
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
					for i, v in ipairs(self.sprBuildings) do
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
				for i,v in ipairs(self.sprBuildings) do
					local pos = ccp(v:getPosition())
					if distanceSQ(pos, p) < radiusSQ then
						v:runAction(CCScaleTo:create(0.1, 1.0))
						if buildings[i].openlv < 0 then -- 暂未开放
							GetMainMenu():ShowTextTip(localizable.ui_myBase_text2, -1)
						elseif buildings[i].openlv > self.playerData_.m_level then -- 等级不够
							GetMainMenu():ShowTextTip(buildings[i].openlv .. localizable.ui_myBase_text1, -1)
						else
							--self.node_:removeFromParentAndCleanup(true)
                            if buildings[i].moduleName == "ShowAdvanceEquipView" then
                                GetMainMenu():ChangeToActivitySubMenu("ShowAdvanceEquipView", "gAdvanceEquipEntry={prePage=\"myBase\"}")
                            else
						        local view = createObj(buildings[i].moduleName, self)
                                AddViewToActivitySubMenu(view.node_)
                            end
						end
						return 
					end
				end
				-- 全都没命中，则恢复原来大小
				for i, v in ipairs(self.sprBuildings) do
					v:runAction(CCScaleTo:create(0.1, 1.0))
				end
			end
		end

		self.node_:setTouchEnabled(true)
		self.node_:registerScriptTouchHandler(CCLayerTouch, false, kCCMenuHandlerPriority - 1, true)
	end
end

function onNodeCleanup(self)
	if self.proxy_ then
		self.proxy_:release()
	end

	layer_base_t.onNodeCleanup(self)
end