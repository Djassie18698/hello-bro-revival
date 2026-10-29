require "util/localizable"

collectCellView=class(
		"collectCellView",
    function()
        return LuaSubView:create() 
    end
)

collectCellView.m_index=0;
collectCellView.m_data={};
collectCellView.canget=true;

function collectCellView:create()
	local view = collectCellView.new();
	view:SetClearPlist(false);
	return view;
end

function collectCellView:loadCCBI()
	self:LoadCCBI("activity/CollectCardView.ccbi",self.m_cellsize);
end

function collectCellView:getTargetNotInUseCountByDataId(id, type)
	local objlist = CPlayerDataMgr:instance():GetObjectList(type)
	local count = 0
	for i = 1, objlist:size() do
		if objlist[i]:IsUsingInAnyTeam() == false and objlist[i]:GetDataID() == id then
			count = count + 1
		end
	end
	return count
end

function collectCellView:initUI()
	local meteriallist = self.m_data:find("materiallist")
	local awardlist = self.m_data:find("drop")
	self.canget = true

	for i = 1, 5 do
		local countLabelName = "label_collect_item_count"..tostring(i)
		local spriteIconName = "sprite_collect_item"..tostring(i)
		local spriteFrameName = "label_collect_item_frame"..tostring(i)
		local attackIconName = "sprite_fight_icon"..tostring(i)
		local defenseIconName = "sprite_defense_icon"..tostring(i)
		local godIconName = "sprite_god_icon"..tostring(i)
		--转生标志_litao_2014.5.28
		local spr_frame_corner1 = "spr_frame_corner1_"..tostring(i)
		local spr_frame_corner2 = "spr_frame_corner2_"..tostring(i)
		--卡牌等级
		local spr_lv = "spr_lv_"..tostring(i)
		local label_card_lv = "label_card_lv_"..tostring(i)
		--初始化卡牌
		if 	i <= #meteriallist 	then
			-- 添加图标
			local iconName = meteriallist[i]:find("icon")[1];	
			local itemType = meteriallist[i]:find("type")[1];
			local attackType = meteriallist[i]:find("kind")[1];
			--转生/等级
			local card_lv = tonumber(meteriallist[i]:find("level")[1])
			local card_newlife = tonumber(meteriallist[i]:find("newlife")[1])
			--设等级
			tolua.cast(self:getNode(label_card_lv), "CCLabelBMFont"):setString(card_lv)
			--转生等级
			local topinlayframe = CGameObjElement:GetTopInlayFrame(E_FRAMETYPE_SMALL, card_newlife)
			if topinlayframe ~= nil then
				tolua.cast(self:getNode(spr_frame_corner1), "CCSprite"):setDisplayFrame(topinlayframe)
				self:getNode(spr_frame_corner1):setVisible(true)
			else
				self:getNode(spr_frame_corner1):setVisible(false)
			end

			local downinlayframe = CGameObjElement:GetDownInlayFrame(E_FRAMETYPE_SMALL, card_newlife)
			if downinlayframe ~= nil then
				tolua.cast(self:getNode(spr_frame_corner2), "CCSprite"):setDisplayFrame(downinlayframe)
				self:getNode(spr_frame_corner2):setVisible(true)
			else
				self:getNode(spr_frame_corner2):setVisible(false)
			end
			--卡牌框
			local frame = self:getItemFrame(tonumber(itemType), iconName)
			if frame ~= nil then
				local icon = CCSprite:createWithSpriteFrame(frame)
				local size = tolua.cast(self:getNode(spriteIconName), "CCSprite"):getContentSize()
				self:getNode(spriteIconName):removeAllChildrenWithCleanup(true)
				tolua.cast(self:getNode(spriteIconName), "CCSprite"):addChild(icon)
				icon:setPosition(size.width/2, size.height/2)
				icon:setAnchorPoint(ccp(0.5,0.5));
				if itemType == "1" then
					icon:setScale(0.9)
				end
			end
			
			-- 添加拥有的数目
			tolua.cast(self:getNode(spriteFrameName), "CCSprite"):setVisible(true)
			tolua.cast(self:getNode(countLabelName), "CCLabelBMFont"):setVisible(true)
			local count = meteriallist[i]:find("havecount")[1]
			local needcount = meteriallist[i]:find("needcount")[1]
			tolua.cast(self:getNode(countLabelName), "CCLabelBMFont"):setString(count.."/"..needcount)
			if tonumber(needcount) > tonumber(count) then
				self.canget = false
			end
			
			if i-1 > 0 then
				local plusName = "sprite_collect_plus"..tostring(i-1)
				tolua.cast(self:getNode(plusName), "CCSprite"):setVisible(true)
			end
			
			if itemType == "1" then
				if attackType == "1" then    --功卡
					self:getNode(attackIconName):setVisible(true)
					self:getNode(defenseIconName):setVisible(false)
					self:getNode(godIconName):setVisible(false)
				elseif attackType == "2" then	 --防御卡
					self:getNode(attackIconName):setVisible(false)
					self:getNode(defenseIconName):setVisible(true)
					self:getNode(godIconName):setVisible(false)
				else                       --神卡
					self:getNode(attackIconName):setVisible(false)
					self:getNode(defenseIconName):setVisible(false)
					self:getNode(godIconName):setVisible(true)
				end
			else
				self:getNode(attackIconName):setVisible(false)
				self:getNode(defenseIconName):setVisible(false)
				self:getNode(godIconName):setVisible(false)
				--隐藏转生标志和等级标志
				self:getNode(spr_frame_corner1):setVisible(false)
				self:getNode(spr_frame_corner2):setVisible(false)
				self:getNode(label_card_lv):setVisible(false)
				self:getNode(spr_lv):setVisible(false)
			end
		else
			tolua.cast(self:getNode(spriteFrameName), "CCSprite"):setVisible(false)
			tolua.cast(self:getNode(countLabelName), "CCLabelBMFont"):setVisible(false)
			tolua.cast(self:getNode(spriteIconName), "CCSprite"):removeAllChildrenWithCleanup(true)
			self:getNode(attackIconName):setVisible(false)
			self:getNode(defenseIconName):setVisible(false)
			self:getNode(godIconName):setVisible(false)
			
			CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile("com_res/small_icon_frame.plist")
			local frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("small_no_obj_frame")
			if frame ~= nil then
				local icon = CCSprite:createWithSpriteFrame(frame)
				local size = tolua.cast(self:getNode(spriteIconName), "CCSprite"):getContentSize()
				self:getNode(spriteIconName):removeAllChildrenWithCleanup(true)
				tolua.cast(self:getNode(spriteIconName), "CCSprite"):addChild(icon)
				icon:setPosition(size.width/2, size.height/2)
				icon:setAnchorPoint(ccp(0.5,0.5));
			end
			
			if i-1 > 0 then
				local plusName = "sprite_collect_plus"..tostring(i-1)
				tolua.cast(self:getNode(plusName), "CCSprite"):setVisible(false)
			end
			--隐藏转生标志和等级标志
			self:getNode(spr_frame_corner1):setVisible(false)
			self:getNode(spr_frame_corner2):setVisible(false)
			self:getNode(label_card_lv):setVisible(false)
			self:getNode(spr_lv):setVisible(false)
		end
    end
	for i = 1, 3 do
		local spriteIconName = "sprite_reward_item"..tostring(i)
		local attackIconName = "reward_fight_icon"..tostring(i)
		local defenseIconName = "reward_defense_icon"..tostring(i)
		local godIconName = "reward_god_icon"..tostring(i)
		--转生标志_litao_2014.5.28
		local spr_frame_corner1 = "spr_reward_frame_corner1_"..tostring(i)
		local spr_frame_corner2 = "spr_reward_frame_corner2_"..tostring(i)
		--卡牌等级
		local spr_lv = "spr_reward_lv_"..tostring(i)
		local label_card_lv = "label_reward_card_lv_"..tostring(i)
		--显示卡牌信息
		if 	i <= #awardlist	then
			--转生/等级
			local card_lv = tonumber(awardlist[i]:find("icon").level)
			local card_newlife = tonumber(awardlist[i]:find("icon").newlife)
			--设等级
			tolua.cast(self:getNode(label_card_lv), "CCLabelBMFont"):setString(card_lv)
			--转生等级
			local topinlayframe = CGameObjElement:GetTopInlayFrame(E_FRAMETYPE_SMALL, card_newlife)
			if topinlayframe ~= nil then
				tolua.cast(self:getNode(spr_frame_corner1), "CCSprite"):setDisplayFrame(topinlayframe)
				self:getNode(spr_frame_corner1):setVisible(true)
			else
				self:getNode(spr_frame_corner1):setVisible(false)
			end

			local downinlayframe = CGameObjElement:GetDownInlayFrame(E_FRAMETYPE_SMALL, card_newlife)
			if downinlayframe ~= nil then
				tolua.cast(self:getNode(spr_frame_corner2), "CCSprite"):setDisplayFrame(downinlayframe)
				self:getNode(spr_frame_corner2):setVisible(true)
			else
				self:getNode(spr_frame_corner2):setVisible(false)
			end
			-- 添加图标
			local iconName =  awardlist[i]:find("icon").value;
			local itemType = awardlist[i]:find("icon").type;
			local attackType = awardlist[i]:find("icon").kind;
			local frame = self:getItemFrame(tonumber(itemType), iconName)
			if frame ~= nil then
				local icon = CCSprite:createWithSpriteFrame(frame)
				local size = tolua.cast(self:getNode(spriteIconName), "CCSprite"):getContentSize()
				self:getNode(spriteIconName):removeAllChildrenWithCleanup(true)
				tolua.cast(self:getNode(spriteIconName), "CCSprite"):addChild(icon)
				icon:setPosition(size.width/2, size.height/2)
				icon:setAnchorPoint(ccp(0.5,0.5));
				
				if itemType == "1" then
					icon:setScale(0.9)
				end
			end
			
			if i-1 > 0 then
				local plusName = "sprite_reward_plus"..tostring(i-1)
				tolua.cast(self:getNode(plusName), "CCSprite"):setVisible(true)
			end
			
			if itemType == "1" then
				if attackType == "1" then
					self:getNode(attackIconName):setVisible(true)
					self:getNode(defenseIconName):setVisible(false)
					self:getNode(godIconName):setVisible(false)
				elseif attackType == "2" then
					self:getNode(attackIconName):setVisible(false)
					self:getNode(defenseIconName):setVisible(true)
					self:getNode(godIconName):setVisible(false)
				else
					self:getNode(attackIconName):setVisible(false)
					self:getNode(defenseIconName):setVisible(false)
					self:getNode(godIconName):setVisible(true)
				end
			else
				self:getNode(attackIconName):setVisible(false)
				self:getNode(defenseIconName):setVisible(false)
				self:getNode(godIconName):setVisible(false)
				--隐藏转生标志和等级标志
				self:getNode(spr_frame_corner1):setVisible(false)
				self:getNode(spr_frame_corner2):setVisible(false)
				self:getNode(label_card_lv):setVisible(false)
				self:getNode(spr_lv):setVisible(false)
			end
		else
			tolua.cast(self:getNode(spriteIconName), "CCSprite"):removeAllChildrenWithCleanup(true)
			self:getNode(attackIconName):setVisible(false)
			self:getNode(defenseIconName):setVisible(false)
			self:getNode(godIconName):setVisible(false)
			
			CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile("com_res/small_icon_frame.plist")
			local frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("small_no_obj_frame")
			if frame ~= nil then
				local icon = CCSprite:createWithSpriteFrame(frame)
				local size = tolua.cast(self:getNode(spriteIconName), "CCSprite"):getContentSize()
				self:getNode(spriteIconName):removeAllChildrenWithCleanup(true)
				tolua.cast(self:getNode(spriteIconName), "CCSprite"):addChild(icon)
				icon:setPosition(size.width/2, size.height/2)
				icon:setAnchorPoint(ccp(0.5,0.5));
			end
			
			if i-1 > 0 then
				local plusName = "sprite_reward_plus"..tostring(i-1)
				tolua.cast(self:getNode(plusName), "CCSprite"):setVisible(false)
			end
			--隐藏转生标志和等级标志
			self:getNode(spr_frame_corner1):setVisible(false)
			self:getNode(spr_frame_corner2):setVisible(false)
			self:getNode(label_card_lv):setVisible(false)
			self:getNode(spr_lv):setVisible(false)
		end
	end
	
	-- title
	local collectType = self.m_data:find("type")[1]
	local canexchangetime = self.m_data:find("canexchangetime")[1]
	local hasexchangetime = self.m_data:find("hasexchangetime")[1]
	
	if tonumber(hasexchangetime) >= tonumber(canexchangetime) then
		self.canget = false
	end
	
	if self.canget == false then
		local program = CCShaderCache:sharedShaderCache():programForKey("greysprite")
		if program ~= nil then
			tolua.cast(self:getNode("sprite_btn_get"), "CCNode"):setShaderProgram(program)
		end
	else
	    local program = CCShaderCache:sharedShaderCache():programForKey("ShaderPositionTextureColor")
		if program ~= nil then
			tolua.cast(self:getNode("sprite_btn_get"), "CCNode"):setShaderProgram(program)
		end
	end

	if collectType == "2" then
		local title = localizable.collect_cell_title_desc..tostring(hasexchangetime).."/"..tostring(canexchangetime)..localizable.collect_cell_onetime_desc
		tolua.cast(self:getNode("label_card_title"), "CCLabelTTF"):setString(title)
		self:getNode("label_get"):setVisible(true)
		self:getNode("label_charge"):setVisible(false)
	else
		local title = localizable.collect_cell_title_desc..tostring(hasexchangetime).."/"..tostring(canexchangetime)..localizable.collect_cell_onetime_desc
		tolua.cast(self:getNode("label_card_title"), "CCLabelTTF"):setString(title)
		self:getNode("label_get"):setVisible(false)
		self:getNode("label_charge"):setVisible(true)
	end
	
	--tolua.cast(self:getNode("label_card_name"), "CCLabelTTF"):setString(self.m_data:find("content")[1])
	if collectType == "2" then
	    tolua.cast(self:getNode("label_card_type_name"), "CCLabelTTF"):setString(localizable.collect_cell_can_collect_desc)
	else
	    tolua.cast(self:getNode("label_card_type_name"), "CCLabelTTF"):setString(localizable.collect_cell_can_exchange_desc)
	end
	return nil
end

function collectCellView:checkItemClick(touchPoint)
	local meteriallist = self.m_data:find("materiallist")
	local awardlist = self.m_data:find("drop")
	
	for i = 1, 5 do
		local spriteIconName = "sprite_collect_item"..tostring(i)
		local rect = self:getNode(spriteIconName):boundingBox()
		if rect:containsPoint(touchPoint) then
			if 	i <= #meteriallist 	then
				CSoundMgr:instance():PlayEffect(SOUND_BUTTON)
				
				local dlg = CommonDialogView.create()
				CommonDialogView.m_selfview = dlg;
				dlg:SetTitle("物品介绍")
				local showContent = meteriallist[i]:find("show")[1]
				dlg:SetDescription(showContent)
				dlg:loadCCBI();
				dlg:initUI()
				GetMainMenu():GetModelLayer():AddDialog(dlg, 3);
			end
		end
    end
	
	for i = 1, 3 do
		local spriteIconName = "sprite_reward_item"..tostring(i)
		local rect = self:getNode(spriteIconName):boundingBox()
		if rect:containsPoint(touchPoint) then
			if 	i <= #awardlist 	then
				local dlg = CommonDialogView.create()
				CSoundMgr:instance():PlayEffect(SOUND_BUTTON)
				
				CommonDialogView.m_selfview = dlg;
				dlg:SetTitle("物品介绍")
				local showContent = awardlist[i]:find("icon").show
				dlg:SetDescription(showContent)
				dlg:loadCCBI();
				dlg:initUI()
				GetMainMenu():GetModelLayer():AddDialog(dlg, 3);
			end
		end
    end
end

function collectCellView:getItemFrame(itemType, iconName)
	if itemType == 1 then
		local pathName = "icon/"..iconName..".plist"
		CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile(pathName)
		local frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(iconName)
		return frame
	elseif itemType == 2 then
		local pathName = "equip/"..iconName..".plist"
		CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile(pathName)
		local frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(iconName)
		return frame
	elseif itemType == 3 then
		local pathName = "skill/"..iconName..".plist"
		CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile(pathName)
		local frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(iconName)
		return frame
	elseif itemType == 4 then
		local pathName = "props/"..iconName..".plist"
		CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile(pathName)
		local frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(iconName)
		return frame
	else
		return nil
	end
	return nil
end

function collectCellView:setIndex(idx)
	self.m_index = idx;
end

function collectCellView:getIndex()
	return self.m_index;
end

function collectCellView:setCellSize(size)
	self.m_cellsize = size;
end

function collectCellView:setCellData(celldata)
	self.m_data = celldata;
end

function collectCellView:getCellData()
	return self.m_data;
end

function collectCellView:cangetPack()
	return self.canget;
end


