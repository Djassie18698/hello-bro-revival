require "util/localizable"
require "RLRequest"

local m_touchPoint
local tableview



-- 刷新数据
local function freshTableData()
	if tableview then
		local offset = tableview:getContentOffset()
		tableview:reloadData()
		tableview:setContentOffset(offset.x, offset.y)
	end
	return nil
end

local function clickGetPack(index)
	CSoundMgr:instance():PlayEffect(SOUND_BUTTON)
	
	if payhisData[index+1] == 0 then
		local playerMgr = CPlayerDataMgr:instance()
		local playerData = playerMgr:GetPlayerInfoData()
		local uid = playerData.m_uid
		local urlpath = GetUrlNormalHeader(uid,2,"rl_w_paypack")
		urlpath = AddData(urlpath, "HeapID", index+1)
		local p = CCPoint:new()
		p.x = index
		GetMainMenu():ShowLoadingDlg()
		CCHttpRequest:openWithUserData(urlpath, kHttpPost, p, "query=param1&other=params"):sendWithHandler(
		function(res, hnd)
			GetMainMenu():CloseLoadding()
			local p = res:getHttpRequest():getUserData()
			local index = tolua.cast(p, "CCPoint").x
			local resData = res:getResponseData()
			local code = res:getResponseCode()
			local xfile = xml.parse(resData)
			local item = xfile:find("RENLONG")
			if item == nil then
				return nil
			end
			local retcode = item.code
			if retcode == "0" then
				local awardXML = xfile:find("award")
				if awardXML ~= nil then
					ShowAward(awardXML)
					
					if newsCount > 0 then
						newsCount = newsCount - 1
					end
					--updated by gongsun 2014.4.14 将开关上的新消息标志刷新
					if ui_activityPopupLayer.getPopupActivityData then
						for k, v in pairs(ui_activityPopupLayer.getPopupActivityData) do
							if v.icon == "activity5" and tonumber(v.newscount) > 0 then
								v.newscount = tonumber(v.newscount) - 1
							CPlayerDataMgr:instance():SetActivityNews("activity5", v.newscount)
								break
							end
						end
					end
					------------------------------------------------------
					CPlayerDataMgr:instance():SetActivityNewsNum(newsCount)
					GetActTopBarView():Refresh()
					
					payhisData[index+1] = 2
					freshTableData()
				end
			else
				GetMainMenu():ShowErrorTip(retcode,-1)
			end
		end)
	end
	return nil
end

local function initCard(card, index)
	card:SetIndex(index)
	
	for i = 1, 4 do
		local id = "drop"..i.."id"
		local name = "drop"..i.."name"
		local iconName = "drop"..i.."icon"
		local labelName = "label_item_name"..tostring(i)
		local spriteIconName = "sprite_item"..tostring(i)
		local dropId = pay_history_drop[index+1]["drop" .. i .. tostring("id")]
		if 	pay_history_drop[index+1][id] ~= 0	then
			tolua.cast(card:GetNode(labelName), "CCLabelTTF"):setVisible(true)
			tolua.cast(card:GetNode(labelName), "CCLabelTTF"):setString(pay_history_drop[index+1][name])
			
			if dropId ~= 0 then
				local itemInfo = ItemDataInfo:new()
				CGameObjElement:GetItemInfoByDropid(dropId, itemInfo)
				--cclog("11111----item:%d, %d, %d, %d", dropId, i, itemInfo.mainType, itemInfo.subType)
				local pIcon, iconFrame = rl_get_iconsprite(itemInfo.mainType, itemInfo.subType, E_FRAMETYPE_SMALL, itemInfo.itemId)
				tolua.cast(card:GetNode(spriteIconName), "CCSprite"):setDisplayFrame(iconFrame)
			end
			local pathName = "props/"..pay_history_drop[index+1][iconName]..".plist"
			CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile(pathName)
			local frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(pay_history_drop[index+1][iconName])
			if frame ~= nil then
				--cclog("11111----frame")
				local icon = CCSprite:createWithSpriteFrame(frame)
				local size = tolua.cast(card:GetNode(spriteIconName), "CCSprite"):getContentSize()
				tolua.cast(card:GetNode(spriteIconName), "CCSprite"):addChild(icon)
				icon:setPosition(size.width/2, size.height/2)
				local point = CCPoint:new()
				point.x = 0.5;
				point.y = 0.5;
				icon:setAnchorPoint(point);
			end
		else
			tolua.cast(card:GetNode(labelName), "CCLabelTTF"):setVisible(false)
			tolua.cast(card:GetNode(spriteIconName), "CCSprite"):removeAllChildrenWithCleanup(true)
			local pFrame1 = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("small_box_skill_01")
			tolua.cast(card:GetNode(spriteIconName), "CCSprite"):setDisplayFrame(pFrame1)
		end
    end
	
	if payhisData[index+1] == 0 then -- 可领取
		local program = CCShaderCache:sharedShaderCache():programForKey("ShaderPositionTextureColor")
		if program ~= nil then
			tolua.cast(card:GetNode("sprite_btn_get"), "CCNode"):setShaderProgram(program)
		end
		tolua.cast(card:GetNode("label_hasgot"), "CCLabelTTF"):setVisible(false)
		tolua.cast(card:GetNode("label_get"), "CCLabelTTF"):setVisible(true)
	elseif payhisData[index+1] == 250011 then -- 不可领取
		local program = CCShaderCache:sharedShaderCache():programForKey("greysprite")
		if program ~= nil then
			tolua.cast(card:GetNode("sprite_btn_get"), "CCNode"):setShaderProgram(program)
		end
		tolua.cast(card:GetNode("label_hasgot"), "CCLabelTTF"):setVisible(false)
		tolua.cast(card:GetNode("label_get"), "CCLabelTTF"):setVisible(true)
	else -- 已领取
		local program = CCShaderCache:sharedShaderCache():programForKey("greysprite")
		if program ~= nil then
			tolua.cast(card:GetNode("sprite_btn_get"), "CCNode"):setShaderProgram(program)
		end
		tolua.cast(self:getNode("node_btn_container"), "CCNode"):setVisible(false)
		tolua.cast(self:getNode("sprite_hasgot"), "CCSprite"):setVisible(true)
		tolua.cast(card:GetNode("label_hasgot"), "CCLabelTTF"):setVisible(true)
		tolua.cast(card:GetNode("label_get"), "CCLabelTTF"):setVisible(false)
	end

	local money = pay_history_drop[index+1]["month_dayback"]
	local tile = string.format(localizable.payhistorydrop_info1, tostring(money))
	tolua.cast(card:GetNode("label_item_title"), "CCLabelTTF"):setString(tile)
	local subtitle = string.format(localizable.payhistorydrop_info2, tostring(money))
	tolua.cast(card:GetNode("label_item_subtitle"), "CCLabelTTF"):setString(subtitle)
	return nil
end

local function createCard(index)
	local proxy = CCBProxy:create()
	local size = CCSize(681,266)
	local n = proxy:readCCBFromFileBySize("activity/ActivityCardView.ccbi", size)
    local layer = tolua.cast(n, "CCLayer")
	local card = CActivityCommonCardView:create()
	card:setTag(100)
	card:SetProxy(proxy)
	card:AssignCCBMemberVariable(proxy:getMemberVariables())
	initCard(card, index)
	layer:addChild(card)
	layer:setTag(100)
	return layer
end

-- @param fn string Callback type
-- @param table LuaTableView
-- @param a1 & a2 mixed Difference means for every "fn"
local h = LuaEventHandler:create(function(fn, table, a1, a2, x, y)
	local r
	if fn == "cellSize" then
		-- Return cell size
		-- a1 is cell index (-1 means default size, in cocos2d-x version below 2.1.3, it's always -1)
		r = CCSize(681,266)
	elseif fn == "cellAtIndex" then
		-- Return CCTableViewCell, a1 is cell index (zero based), a2 is dequeued cell (maybe nil)
		-- Do something to create cell and change the content
		if not a2 then
			a2 = CCTableViewCell:create()
			local card = createCard(a1)
			a2:addChild(card)
		else			
			local n = a2:getChildByTag(100)
			local layer = tolua.cast(n, "CCLayer")
			local c = layer:getChildByTag(100)
			local card = tolua.cast(c, "CActivityCommonCardView")
			initCard(card, a1)
		end
		
		r = a2
	elseif fn == "numberOfCells" then
		-- Return number of cells
		r = #pay_history_drop
	-- Cell events:
	elseif fn == "cellTouched" then			-- A cell was touched, a1 is cell that be touched. This is not necessary.	
		local n = a1:getChildByTag(100)
		local layer = tolua.cast(n, "CCLayer")
		local c = layer:getChildByTag(100)
		local card = tolua.cast(c, "CActivityCommonCardView")
		if card:GetNode("node_btn_container"):boundingBox():containsPoint(m_touchPoint) then
			clickGetPack(card:GetIndex())
		end

		for i = 1, 4 do
			local itemName = "sprite_item".. i
			local id = "drop" .. i .. tostring("id")
			if card:GetNode(itemName):boundingBox():containsPoint(m_touchPoint) then
				if 	pay_history_drop[card:GetIndex()+1][id] ~= 0 and pay_history_drop[card:GetIndex()+1][id] ~= nil then
					CGameObjElement:ShowDropByID(pay_history_drop[card:GetIndex()+1][id])
				end
			end
		end
	elseif fn == "cellTouchBegan" then		-- A cell is touching, a1 is cell, a2 is CCTouch
		m_touchPoint = a2:getLocation()
		local n = a1:getChildByTag(100)
		local layer = tolua.cast(n, "CCLayer")
		m_touchPoint = layer:convertToNodeSpace(m_touchPoint)
		local c = layer:getChildByTag(100)
		local card = tolua.cast(c, "CActivityCommonCardView")
		local rect = card:GetNode("sprite_btn_get"):boundingBox()
		if card:GetNode("node_btn_container"):boundingBox():containsPoint(m_touchPoint) then
			--[[local size = tolua.cast(card:GetNode("sprite_btn_get"), "CCScale9Sprite"):getPreferredSize()
			local btn = CCSprite:createWithSpriteFrameName("com_btn_red_02")
			card:GetNode("sprite_btn_get"):addChild(btn)
			btn:setContentSize(size.width, size.height)
			btn:setAnchorPoint(ccp(0,0))
			btn:setPosition(ccp(0,0))
			btn:setTag(123)]]
			card:GetNode("sprite_btn_get"):setVisible(false)
			card:GetNode("sprite_btn_get2"):setVisible(true)
		end
		r = true
	elseif fn == "cellTouchEnded" then		-- A cell was touched, a1 is cell, a2 is CCTouch
		r = true
	elseif fn == "cellHighlight" then		-- A cell is highlighting, coco2d-x 2.1.3 or above
	elseif fn == "cellUnhighlight" then		-- A cell had been unhighlighted, coco2d-x 2.1.3 or above
		local n = a1:getChildByTag(100)
		local layer = tolua.cast(n, "CCLayer")
		local c = layer:getChildByTag(100)
		local card = tolua.cast(c, "CActivityCommonCardView")
		--[[if card:GetNode("sprite_btn_get"):getChildByTag(123) ~= nil then
			card:GetNode("sprite_btn_get"):removeChildByTag(123,true)
		end]]
		card:GetNode("sprite_btn_get"):setVisible(true)
		card:GetNode("sprite_btn_get2"):setVisible(false)
	elseif fn == "cellWillRecycle" then		-- A cell will be recycled, coco2d-x 2.1.3 or above
	end
	return r
end)


local activityView = GetActivityView()
local contentNode = activityView:GetNodeContent()
local contentSize = contentNode:getContentSize()

tableview = LuaTableView:createWithHandler(h, CCSizeMake(contentSize.width,contentSize.height))
tableview:setDirection(kCCScrollViewDirectionVertical)
tableview:setVerticalFillOrder(kCCTableViewFillTopDown)
tableview:reloadData()

contentNode:addChild(tableview)
