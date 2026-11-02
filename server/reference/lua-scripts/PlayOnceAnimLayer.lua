require "util/localizable"
require "LuaSubView.lua"


PlayOnceAnimLayer=class(
	"PlayOnceAnimLayer",
    function()
        return LuaSubView:create() 
    end
)

local m_selfview={};
function PlayOnceAnimLayer:create()
	local view = PlayOnceAnimLayer.new();
	PlayOnceAnimLayer.m_selfview = view;
	return view;
end

function PlayOnceAnimLayer:initUI(ccbiname, contentsize, duration)	
	self:LoadCCBI(ccbiname,contentsize);	
	
	local function animationFinished(fDeltaTime)
		self.show_deltatime = self.show_deltatime + fDeltaTime
		if self.show_deltatime >= self.m_duration then
			self:removeFromParentAndCleanup(true) 
			self.show_deltatime = 0
		end
	end
	
	self.show_deltatime = 0
	self.m_duration = duration
	self:scheduleUpdateWithPriorityLua(animationFinished, 0)
end