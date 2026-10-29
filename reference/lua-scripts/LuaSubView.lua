require "extern"

LuaSubView=class(
	"LuaSubView",
    function()
        return CCBProxy:create() 
    end
)

LuaSubView.__index = LuaSubView;

function LuaSubView:create()
	local subview = LuaSubView:new();
	return subview;
end

function LuaSubView:LoadCCBI(filename,size)		
	local n = self:readCCBFromFileBySize(filename, size)
    local layer = tolua.cast(n, "CCLayer")
    self:addChild(layer);
end