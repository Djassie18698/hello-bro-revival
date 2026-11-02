require "util/localizable"

moraRankCellView=class(
		"moraRankCellView",
    function()
        return LuaSubView:create() 
    end
)

function moraRankCellView:create()
	local view = moraRankCellView.new();
	return view;
end

function moraRankCellView:loadCCBI()
	self:LoadCCBI("dlg_ui/MoraRankCellView.ccbi",self.m_cellsize);
end

function moraRankCellView:initUI()
	local rank = self.m_data:find("rank")[1];	
	local countryType = self.m_data:find("country")[1]
	local name = self.m_data:find("nick")[1]
	local fortune = self.m_data:find("score")[1]
	
	tolua.cast(self:getNode("label_rank"), "CCLabelTTF"):setString(rank)
	local countryicon = CProfileData:GetCountryIcon(countryType)
	local iconsprite = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(countryicon)
	if tolua.cast(self:getNode("icon_country"), "CCSprite") ~= nil then
		tolua.cast(self:getNode("icon_country"), "CCSprite"):setDisplayFrame(iconsprite)
	end
	tolua.cast(self:getNode("label_playername"), "CCLabelTTF"):setString(name)
	tolua.cast(self:getNode("label_fortune"), "CCLabelTTF"):setString(fortune)
		
	return nil
end

function moraRankCellView:setIndex(idx)
	self.m_index = idx;
end

function moraRankCellView:getIndex()
	return self.m_index;
end

function moraRankCellView:setCellSize(size)
	self.m_cellsize = size;
end

function moraRankCellView:setCellData(celldata)
	self.m_data = celldata;
end

function moraRankCellView:getCellData()
	return self.m_data;
end

function moraRankCellView:cangetPack()
	return self.canget;
end


