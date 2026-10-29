require "LuaSubView.lua"

MenuBtnsCellView=class(
	"MenuBtnsCellView",
    function()
        return LuaSubView:create() 
    end
)

function MenuBtnsCellView:create()
	local view = MenuBtnsCellView.new();
	return view;
end

function MenuBtnsCellView:setData(data)
	self.m_data = data;
end

function MenuBtnsCellView:getData()
	return self.m_data;
end

function MenuBtnsCellView:setSize(size)
	self.m_size = size;
end
function MenuBtnsCellView:getBtnRect()
    return self.m_sprite:boundingBox();
end

function MenuBtnsCellView:getSprite()
	return self.m_sprite;
end

function MenuBtnsCellView:setIndex(index)
	self.m_index = index;
end
function MenuBtnsCellView:getIndex()
	return self.m_index;
end
function MenuBtnsCellView:initUI()
	local spritename = self.m_data["icon"];
	local sprite = CCSprite:createWithSpriteFrameName(spritename);
	self:removeChildByTag(120,true);
	self:addChild(sprite);
	--self:setContentSize(self.m_size);
	sprite:setAnchorPoint(CCPoint(0,0))
	sprite:setPosition(CCPoint(0,0));
	sprite:setTag(120);
	self.m_sprite = sprite;
end