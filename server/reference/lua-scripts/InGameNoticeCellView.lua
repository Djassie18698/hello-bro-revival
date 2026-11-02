require "LuaSubView.lua"
require "util/localizable"

InGameNoticeCellView=class(
	"InGameNoticeCellView",
    function()
        return LuaSubView:create() 
    end
)
function InGameNoticeCellView:loadCellCCBI()	
	self:LoadCCBI("sub_ui/NoticeCell.ccbi",self.m_size);
end
function InGameNoticeCellView:create()
	local view = InGameNoticeCellView.new();
	return view;
end

function InGameNoticeCellView:setData(data)
	self.m_data = data;
end

function InGameNoticeCellView:getData()
	return self.m_data;
end

function InGameNoticeCellView:setSize(size)
	self.m_size = size;
end
function InGameNoticeCellView:getBtnRect()
    return self.m_sprite:boundingBox();
end

function InGameNoticeCellView:getSprite()
	return self.m_sprite;
end

function InGameNoticeCellView:setIndex(index)
	self.m_index = index;
end
function InGameNoticeCellView:getIndex()
	return self.m_index;
end
function InGameNoticeCellView:initUI()
	self.m_sprite = self:getNode("sprite_btngoto");
	
	local title = self.m_data:find("title")[1];		
	tolua.cast(self:getNode("label_title"), "CCLabelTTF"):setString(title);
	local desc = self.m_data:find("inside")[1];	
	tolua.cast(self:getNode("label_content"), "CCLabelTTF"):setString(desc);
	tolua.cast(self:getNode("label_title"), "CCLabelTTF"):setVisible(false);
	tolua.cast(self:getNode("label_toptitle"), "CCLabelTTF"):setVisible(true);
	tolua.cast(self:getNode("label_toptitle"), "CCLabelTTF"):setString(title);
	local ideval = self:getIndex();
	if ideval == 1 then
		local sprite = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("inner_notice_02");
		tolua.cast(self:getNode("sprite_toptip"), "CCSprite"):setDisplayFrame(sprite);
	elseif ideval == 2 then
		local sprite = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("inner_notice_03");
		tolua.cast(self:getNode("sprite_toptip"), "CCSprite"):setDisplayFrame(sprite);
	elseif ideval == 3 then
		local sprite = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("inner_notice_04");
		tolua.cast(self:getNode("sprite_toptip"), "CCSprite"):setDisplayFrame(sprite);
	else
		tolua.cast(self:getNode("label_title"), "CCLabelTTF"):setVisible(true);
		tolua.cast(self:getNode("label_toptitle"), "CCLabelTTF"):setVisible(false);
		tolua.cast(self:getNode("sprite_toptip"), "CCSprite"):setVisible(false);
	end
	
end
