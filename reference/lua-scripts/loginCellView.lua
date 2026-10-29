require "util/localizable"

loginCellView=class(
		"loginCellView",
    function()
        return LuaSubView:create() 
    end
)

loginCellView.m_index=0;

function loginCellView:create()
	local view = loginCellView.new();
	view:SetClearPlist(false);
	return view;
end

function loginCellView:loadCCBI()
	self:LoadCCBI("activity/ActivityCardView.ccbi",self.m_cellsize);
end

function loginCellView:initUI()
	for i = 1, 4 do
		local id = "login_drop"..i.."id"
		local name = "login_drop"..i.."name"
		local iconName = "login_drop"..i.."icon"
		local labelName = "label_item_name"..tostring(i)
		local spriteIconName = "sprite_item"..tostring(i)
		local dropId = loginPackData[self.m_index+1]["login_drop" .. tostring(i) .. "id"]
		if 	loginPackData[self.m_index+1][id] ~= 0	then
			tolua.cast(self:getNode(labelName), "CCLabelTTF"):setVisible(true)
			tolua.cast(self:getNode(labelName), "CCLabelTTF"):setString(loginPackData[self.m_index+1][name])
			
			local itemInfo = ItemDataInfo:new()
			CGameObjElement:GetItemInfoByDropid(dropId, itemInfo)
			-- TODO 添加物品图标
			local pIcon, iconFrame = rl_get_iconsprite(itemInfo.mainType, itemInfo.subType, E_FRAMETYPE_SMALL, itemInfo.itemId)
			local pathName = "props/"..loginPackData[self.m_index+1][iconName]..".plist"
			CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile(pathName)
			local frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(loginPackData[self.m_index+1][iconName])
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

    --已領取圖標設置為不可見
    tolua.cast(self:getNode("sprite_hasgot"), "CCSprite"):setVisible(false)

	if self.m_index == 1 then
		self:getNode("sprite_forsecond"):setVisible(true)
	else
		self:getNode("sprite_forsecond"):setVisible(false)	
	end
	if loginData[self.m_index+1] == 0 then -- 可领取
		local program = CCShaderCache:sharedShaderCache():programForKey("ShaderPositionTextureColor")
		if program ~= nil then
			tolua.cast(self:getNode("sprite_btn_get"), "CCNode"):setShaderProgram(program)
		end
		tolua.cast(self:getNode("label_hasgot"), "CCLabelTTF"):setVisible(false)
		tolua.cast(self:getNode("label_get"), "CCLabelTTF"):setVisible(true)
	elseif loginData[self.m_index+1] == 1 then -- 不可领取
		local program = CCShaderCache:sharedShaderCache():programForKey("greysprite")
		if program ~= nil then
			tolua.cast(self:getNode("sprite_btn_get"), "CCNode"):setShaderProgram(program)
		end
		tolua.cast(self:getNode("label_hasgot"), "CCLabelTTF"):setVisible(false)
		tolua.cast(self:getNode("label_get"), "CCLabelTTF"):setVisible(true)
	else -- 已领取
		local program = CCShaderCache:sharedShaderCache():programForKey("greysprite")
		if program ~= nil then
			tolua.cast(self:getNode("sprite_btn_get"), "CCNode"):setShaderProgram(program)
		end
		tolua.cast(self:getNode("label_hasgot"), "CCLabelTTF"):setVisible(true)
		tolua.cast(self:getNode("label_get"), "CCLabelTTF"):setVisible(false)
		tolua.cast(self:getNode("node_btn_container"), "CCNode"):setVisible(false)
		tolua.cast(self:getNode("sprite_hasgot"), "CCSprite"):setVisible(true)
	end

	local tile = string.format(localizable.login_item_title_desc, tostring(self.m_index+1)) 
	tolua.cast(self:getNode("label_item_title"), "CCLabelTTF"):setString(tile)
	local subtitle = string.format(localizable.login_item_subtitle_desc, tostring(self.m_index+1))
	tolua.cast(self:getNode("label_item_subtitle"), "CCLabelTTF"):setString(subtitle)
	return nil
end

function loginCellView:setIndex(idx)
	self.m_index = idx;
end

function loginCellView:getIndex()
	return self.m_index;
end

function loginCellView:setCellSize(size)
	self.m_cellsize = size;
end


