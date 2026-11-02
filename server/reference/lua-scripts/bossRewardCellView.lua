
bossRewardCellView=class(
		"bossRewardCellView",
    function()
        return LuaSubView:create() 
    end
)

function bossRewardCellView:create()
	local view = bossRewardCellView.new();
	return view;
end

function bossRewardCellView:loadCCBI()
	self:LoadCCBI("activity/BossAwardCellView.ccbi",self.m_cellsize);
end

function bossRewardCellView:initUI()
	local icon = self.m_data:find("icon")[1];	
	local reputation = self.m_data:find("cost")[1]	
	local dropId = tonumber(self.m_data:find("dropid")[1])

	local itemInfo = ItemDataInfo:new()
	CGameObjElement:GetItemInfoByDropid(dropId, itemInfo)
	local pIcon, iconFrame = rl_get_iconsprite(itemInfo.mainType, itemInfo.subType, E_FRAMETYPE_SMALL, itemInfo.itemId)
	tolua.cast(self:getNode("sprite_frame"),"CCSprite"):setDisplayFrame(iconFrame)
	local pathName = "props/"..icon..".plist"
	CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile(pathName)
	local frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(icon)
	if frame ~= nil then
		tolua.cast(self:getNode("sprite_box_icon"),"CCSprite"):setDisplayFrame(frame)
	end
	
	tolua.cast(self:getNode("label_reputation"), "CCLabelTTF"):setString(reputation)
	return nil
end

function bossRewardCellView:setIndex(idx)
	self.m_index = idx;
end

function bossRewardCellView:getIndex()
	return self.m_index;
end

function bossRewardCellView:setCellSize(size)
	self.m_cellsize = size;
end

function bossRewardCellView:setCellData(celldata)
	self.m_data = celldata;
end

function bossRewardCellView:getCellData()
	return self.m_data;
end


