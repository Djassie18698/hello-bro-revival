
boxOpenRewardCellView=class(
		"boxOpenRewardCellView",
    function()
        return LuaSubView:create() 
    end
)

function boxOpenRewardCellView:create()
	local view = boxOpenRewardCellView.new();
	return view;
end

function boxOpenRewardCellView:loadCCBI()
	self:LoadCCBI("activity/BoxDetailCellView.ccbi",self.m_cellsize);
end

function boxOpenRewardCellView:initUI()
	--local icon = self.m_data:find("icon")[1]	
	--local name = self.m_data:find("name")[1]
	--local desc = self.m_data:find("description")[1]
	
	local icon = self.m_data.awardIcon
	local name = self.m_data.awardContent
	local desc = self.m_data.awardDesc
	
	tolua.cast(self:getNode("sprite_item"), "CCSprite"):removeAllChildrenWithCleanup(true)
	
	local pathName = "props/"..icon..".plist"
	CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile(pathName)
	local frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(icon)
	if frame ~= nil then
		local icon = CCSprite:createWithSpriteFrame(frame)
		local size = tolua.cast(self:getNode("sprite_item"), "CCSprite"):getContentSize()
		tolua.cast(self:getNode("sprite_item"), "CCSprite"):addChild(icon)
		icon:setPosition(size.width/2, size.height/2)
		local point = CCPoint:new()
		point.x = 0.5;
		point.y = 0.5;
		icon:setAnchorPoint(point);
	end
	
	tolua.cast(self:getNode("label_cell_name"), "CCLabelTTF"):setString(name)
	tolua.cast(self:getNode("label_cell_desc"), "CCLabelTTF"):setString(desc)
	return nil
end

function boxOpenRewardCellView:setIndex(idx)
	self.m_index = idx;
end

function boxOpenRewardCellView:getIndex()
	return self.m_index;
end

function boxOpenRewardCellView:setCellSize(size)
	self.m_cellsize = size;
end

function boxOpenRewardCellView:setCellData(celldata)
	self.m_data = celldata;
end

function boxOpenRewardCellView:getCellData()
	return self.m_data;
end


