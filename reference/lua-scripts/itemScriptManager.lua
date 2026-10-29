require "LuaSubView.lua"
require "RLRequest"
require "LuaXml.lua"


function useItemHandler(bagid,item,consumeType)
	--GetMainMenu():ChangeToActivity("fightBossView");
	if consumeType == 11 then
		GetMainMenu():ChangeToActivity("boxOpenActivityView")
	end
end


