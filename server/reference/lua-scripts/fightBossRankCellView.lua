
bossRankCellView=class(
		"bossRankCellView",
    function()
        return LuaSubView:create() 
    end
)

function bossRankCellView:create()
	local view = bossRankCellView.new();
	return view;
end

function bossRankCellView:loadCCBI()
	self:LoadCCBI("activity/BossRuleCellView.ccbi",self.m_cellsize);
end

function bossRankCellView:initUI()
	local rank = self.m_data:find("rank")[1]
	local reputation = self.m_data:find("val")[1]
	local rankStr = localizable.fightBoss_hurt_desc_1..tostring(rank)
	
	tolua.cast(self:getNode("label_name"), "CCLabelTTF"):setString(rankStr)
	tolua.cast(self:getNode("label_reputation"), "CCLabelTTF"):setString(reputation)
	return nil
end

function bossRankCellView:setIndex(idx)
	self.m_index = idx;
end

function bossRankCellView:getIndex()
	return self.m_index;
end

function bossRankCellView:setCellSize(size)
	self.m_cellsize = size;
end

function bossRankCellView:setCellData(celldata)
	self.m_data = celldata;
end

function bossRankCellView:getCellData()
	return self.m_data;
end


