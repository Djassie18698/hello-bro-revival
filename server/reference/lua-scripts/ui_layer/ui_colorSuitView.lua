--descriptioin:颜色套
--company: xckoo
--author: litao
--date: 2014-2-13
---------------------------------------------
module("ui_colorSuitView", package.seeall)
baseClass(layer_base_t, ui_colorSuitView)

function init(self)
	--self.contentSize_ = GetMainMenu():GetSubContentNode():getContentSize()
	self.contentSize_ = GetMainMenu():GetModelLayer():getContentSize()
	local ccbiAttrTable = {name="sub_ui/SuitEffectView.ccbi", size=self.contentSize_}
	layer_base_t.init(self, true, ccbiAttrTable)

	--用户info
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()
	--队伍info
	if self.playerData_.m_selectTeamId == -1 then
		self.m_teamData = CPlayerDataMgr:instance():GetActiveTeam()
	else
		self.m_teamData = CPlayerDataMgr:instance():GetTeamByIndex(self.playerData_.m_selectTeamId)
	end
	self.m_colorSuitId = self.m_teamData:GetSuitInfo(1)

	--套装信息数据
	self.m_colorSuitData = {}

	--是否有套装激活
	self.isColorSuitActivate = false

	--第一位显示info
	self.m_firstShowColorType = -1
	self.m_firstShowColorNum = -1

	self:init_ui()		
	self:init_binding_event()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		--btn
		self.btn_ok = tolua.cast(self.proxy_:getNode("suit_effect_ok"), "CCControlButton")
		self.btn_close = tolua.cast(self.proxy_:getNode("ctrl_close"), "CCControlButton")
		--ttf
		self.title_suit = tolua.cast(self.proxy_:getNode("_title_suit"), "CCLabelTTF")
		--node
		self["node_content_1"] = tolua.cast(self.proxy_:getNode("node_content_1"), "CCNode")
		self["node_content_2"] = tolua.cast(self.proxy_:getNode("node_content_2"), "CCNode")
		self["node_content_3"] = tolua.cast(self.proxy_:getNode("node_content_3"), "CCNode")
		self["node_content_4"] = tolua.cast(self.proxy_:getNode("node_content_4"), "CCNode")

		--setSuitData
		self:setSuitData()
	end
end

function setSuitData(self)
	--title
	self.title_suit:setString(localizable.ui_suit_color_card)
	--没有激活套装则从最开始开始激活
	if self.m_colorSuitId < 0  then
		self.m_colorSuitId = 1
	else
		self.isColorSuitActivate = true
	end

	--1-4 cur颜色、next颜色、cur颜色+1、next颜色+1
	--cur颜色套info
	local colorSuitData = DataMgr.GetDataByID("Struct_Suit_Info", tonumber(self.m_colorSuitId))	
	self.m_firstShowColorType = tonumber(colorSuitData.m_suit_param)
	self.m_firstShowColorNum = tonumber(colorSuitData.m_suit_num)
	
	local color_c3 = ccc3(0,0,0)
	if self.m_firstShowColorType == 3 then--绿色
		color_c3 = ccc3(0,170,0)
	elseif self.m_firstShowColorType == 4 then--蓝色
		color_c3 = ccc3(0,100,255)
	elseif	self.m_firstShowColorType == 5 then--紫色
		color_c3 = ccc3(170,0,255)
	elseif self.m_firstShowColorType == 6 then--橙色
		color_c3 = ccc3(255,100,0)
	else
		color_c3 = ccc3(40,40,40)
	end

	--整理后的4个node信息
	self:getNode_id()
	--node_1
	local suitData_1 = {}
	if self.m_suit_1 == self.m_colorSuitId then
		suitData_1.isActivate = self.isColorSuitActivate
	else
		suitData_1.isActivate = false
	end	
	suitData_1.c3_color = color_c3
	suitData_1.data = self:retSuitData(self.m_suit_1)
	table.insert(self.m_colorSuitData, suitData_1)
	--node_2
	local suitData_2 = {}
	if self.m_suit_2 == self.m_colorSuitId then
		suitData_2.isActivate = self.isColorSuitActivate
	else
		suitData_2.isActivate = false
	end	
	suitData_2.c3_color = color_c3
	suitData_2.data = self:retSuitData(self.m_suit_2)
	table.insert(self.m_colorSuitData, suitData_2)
	--node_3
	local suitData_3 = {}
	if self.m_suit_3 == self.m_colorSuitId then
		suitData_3.isActivate = self.isColorSuitActivate
	else
		suitData_3.isActivate = false
	end
	suitData_3.c3_color = color_c3	
	suitData_3.data = self:retSuitData(self.m_suit_3)
	table.insert(self.m_colorSuitData, suitData_3)
	--node_4
	local suitData_4 = {}
	if self.m_suit_4 == self.m_colorSuitId then
		suitData_4.isActivate = self.isColorSuitActivate
	else
		suitData_4.isActivate = false
	end	
	suitData_4.c3_color = color_c3
	suitData_4.data = self:retSuitData(self.m_suit_4)
	table.insert(self.m_colorSuitData, suitData_4)
	
	---[[
	for i=1,4 do
		--if self.m_colorSuitData[i].id_suit > 0 then		
			local size = self["node_content_"..tostring(i)]:getContentSize()
			local nodeLayer = createObj(ui_suitCell, size, self.m_colorSuitData[i])
			self["node_content_"..tostring(i)]:addChild(nodeLayer.node_)
			nodeLayer.node_:setPosition(ccp(size.width/2, size.height/2))
			nodeLayer.node_:setAnchorPoint(ccp(0.5,0.5))
			self["node_content_"..tostring(i)]:setVisible(true)
		--else
		--	self["node_content_"..tostring(i)]:setVisible(false)
		--end
	end	
	--]]
end

function getNode_id(self)
	local colorSuitData = DataMgr.GetDataByID("Struct_Suit_Info", tonumber(self.m_colorSuitId))
	self.m_suit_1 = tonumber(colorSuitData.m_suit_small_up)
	self.m_suit_2 = tonumber(colorSuitData.m_suit_big_up)
	self.m_suit_3 = tonumber(colorSuitData.m_suit_small_down)
	self.m_suit_4 = tonumber(colorSuitData.m_suit_big_down)
end

--获取套装数据
function retSuitData(self, _id)
	---[[
	--颜色套info
	local colorSuitData = DataMgr.GetDataByID("Struct_Suit_Info", tonumber(_id))
	--3-5 绿蓝紫
	local retSuitData = {}
	retSuitData.title = tostring(colorSuitData.m_suit_desc)
	retSuitData.attack_num = tonumber(colorSuitData.m_suit_attack_num)
	retSuitData.attack_per = tostring(self:getIntPart(tonumber(colorSuitData.m_suit_attack_percent * 100.0)).."%")
	retSuitData.def_num = tonumber(colorSuitData.m_suit_defense_num)
	retSuitData.def_per = tostring(self:getIntPart(tonumber(colorSuitData.m_suit_defense_percent * 100.0)).."%")
	retSuitData.chakra_num = tonumber(colorSuitData.m_suit_chacra_num)
	retSuitData.chakra_per = tostring(self:getIntPart(tonumber(colorSuitData.m_suit_chacra_percent * 100.0)).."%")
	return retSuitData
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
			--GetMainMenu():ChangeToSub(E_GAMEGROUPVIEW)
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
			else
				return false
			end		
		end

		self.node_:setTouchEnabled(true)
		self.node_:registerScriptTouchHandler(CCLayerTouch, false, kCCMenuHandlerPriority-1, true)

		--返回按钮
		---[[
		self.btn_close:setTouchPriority(kCCMenuHandlerPriority-2)
		self.btn_close:setTouchEnabled(true)
		self.proxy_:handleButtonEvent(self.btn_close, function(button, event)
			onBtnOk(button)
			return nil
		end, CCControlEventTouchDown)

		self.btn_ok:setTouchPriority(kCCMenuHandlerPriority-2)
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
    --[[
	local plistNameList = {"ccbResources/borderWar.plist"}
    for k, v in ipairs(plistNameList) do
		CCSpriteFrameCache:sharedSpriteFrameCache():removeSpriteFramesFromFile(v)
		local imagePath = string.format( "%s.pvr.ccz", string.sub(v, 1, string.len(v) - 6) )
		CCTextureCache:sharedTextureCache():removeTextureForKey( imagePath )
		imagePath = string.format( "%s.pvr", string.sub(v, 1, string.len(v) - 6) )
		CCTextureCache:sharedTextureCache():removeTextureForKey( imagePath )
		imagePath = string.format( "%s.png", string.sub(v, 1, string.len(v) - 6) )
		CCTextureCache:sharedTextureCache():removeTextureForKey( imagePath )
	end
	--]]

    layer_base_t.onNodeCleanup(self)
end

--创建测试数据
function createTestData(self)
	--1-4 cur星阶、cur星阶+1、next星阶_num+1、next星阶+1_num+1
	--[[
	for i=1,4 do		
		local data = {}
		data.title = tostring("五件六星卡效果")
		data.attack_num = tostring("100")
		data.def_num = tostring("100")
		data.chakra_num = tostring("100")
		data.attack_per = tostring("5%")
		data.def_per = tostring("5%")
		data.chakra_per = tostring("5%")
		local size = self["node_content_"..tostring(i)]:getContentSize()
		local nodeLayer = createObj(ui_suitCell, size, data)
		self["node_content_"..tostring(i)]:addChild(nodeLayer.node_)
		nodeLayer.node_:setPosition(ccp(size.width/2, size.height/2))
		nodeLayer.node_:setAnchorPoint(ccp(0.5,0.5))
	end	
	--]]
end
