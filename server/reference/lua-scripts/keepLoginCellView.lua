require "util/localizable"

keepLoginCellView=class(
		"keepLoginCellView",
    function()
        return LuaSubView:create() 
    end
)

keepLoginCellView.m_index=0;

function keepLoginCellView:create()
	local view = keepLoginCellView.new();
	view:SetClearPlist(false);
	return view;
end

function keepLoginCellView:loadCCBI()
	self:LoadCCBI("activity/KeepLoginNodeView.ccbi",self.m_cellsize);
end

function keepLoginCellView:initUI()
	---[[
	for i = 1, 3 do
		--i = 1
		local id = "keeplogin_id"
		local name = "keeplogin_name"..i
		local iconName = "keeplogin_icon"..i
		local labelName = "label_item_name"..tostring(i)
		local dropId = keeplogin_data[self.m_index+1]["keeplogin_drop" .. tostring(i)]
		local spriteIconName = "sprite_item"..tostring(i)
		if 	keeplogin_data[self.m_index+1][id] ~= 0	then
			tolua.cast(self:getNode(labelName), "CCLabelTTF"):setVisible(true)
			tolua.cast(self:getNode(labelName), "CCLabelTTF"):setString(keeplogin_data[self.m_index+1][name])
			
			local itemInfo = ItemDataInfo:new()
			CGameObjElement:GetItemInfoByDropid(dropId, itemInfo)
			-- TODO 添加物品图标
			local pIcon, iconFrame = rl_get_iconsprite(itemInfo.mainType, itemInfo.subType, E_FRAMETYPE_SMALL, itemInfo.itemId)
			local pathName = "props/"..keeplogin_data[self.m_index+1][iconName]..".plist"
			CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile(pathName)
			local frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(keeplogin_data[self.m_index+1][iconName])
			if frame ~= nil then
				local icon = CCSprite:createWithSpriteFrame(frame)
				tolua.cast(self:getNode(spriteIconName), "CCSprite"):setDisplayFrame(iconFrame)
				local size = tolua.cast(self:getNode(spriteIconName), "CCSprite"):getContentSize()
				tolua.cast(self:getNode(spriteIconName), "CCSprite"):addChild(icon)
				icon:setPosition(size.width/2, size.height/2)
				local point = CCPoint:new()
				point.x = 0.5;
				point.y = 0.5;
				icon:setAnchorPoint(point);
			end
		else
			tolua.cast(self:getNode(labelName), "CCLabelTTF"):setVisible(false)
			tolua.cast(self:getNode(spriteIconName), "CCSprite"):removeAllChildrenWithCleanup(true)
		end
    end
    --]]

    local titleIndex = self.m_index + 1
    local label_item_title = string.format(localizable.keepLogin_cell_title_desc, tostring(titleIndex))
    if titleIndex >= 7 then
    	label_item_title = localizable.keepLogin_cell_title_desc_2
    end
	tolua.cast(self:getNode("label_item_title"), "CCLabelTTF"):setVisible(true)
	tolua.cast(self:getNode("label_item_title"), "CCLabelTTF"):setString(label_item_title)
	
	tolua.cast(self:getNode("label_get_title"), "CCLabelTTF"):setVisible(true)

	if keeploginData[self.m_index+1] == 0 then -- 可领取
		local program = CCShaderCache:sharedShaderCache():programForKey("ShaderPositionTextureColor")
		if program ~= nil then
			tolua.cast(self:getNode("sprite_btn_get"), "CCNode"):setShaderProgram(program)
		end		
		tolua.cast(self:getNode("label_get_title"), "CCLabelTTF"):setString(localizable.ui_status_1)
	elseif keeploginData[self.m_index+1] == 1 then -- 不可领取
		local program = CCShaderCache:sharedShaderCache():programForKey("greysprite")
		if program ~= nil then
			tolua.cast(self:getNode("sprite_btn_get"), "CCNode"):setShaderProgram(program)
		end
		tolua.cast(self:getNode("label_get_title"), "CCLabelTTF"):setString(localizable.ui_status_1)
	else -- 已领取
		local program = CCShaderCache:sharedShaderCache():programForKey("greysprite")
		if program ~= nil then
			tolua.cast(self:getNode("sprite_btn_get"), "CCNode"):setShaderProgram(program)
		end
		tolua.cast(self:getNode("label_get_title"), "CCLabelTTF"):setString(localizable.ui_status_2)
		tolua.cast(self:getNode("node_btn_container"), "CCNode"):setVisible(false)
		tolua.cast(self:getNode("sprite_hasgot"), "CCSprite"):setVisible(true)
	end

	return nil
end

function keepLoginCellView:setIndex(idx)
	self.m_index = idx;
end

function keepLoginCellView:getIndex()
	return self.m_index;
end

function keepLoginCellView:setCellSize(size)
	self.m_cellsize = size;
end


