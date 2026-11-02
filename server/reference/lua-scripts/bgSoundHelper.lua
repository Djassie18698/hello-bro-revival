require "LuaSubView.lua"
require "RLRequest"
require "LuaXml.lua"
require "config/bgSoundConfig"

function findTargetBgSoundById(mainType,subType)
	for i = 1, #bgSoundConfig_module.bgSoundConfig do
		if (bgSoundConfig_module.bgSoundConfig[i].mainType == mainType) and (bgSoundConfig_module.bgSoundConfig[i].subType == subType) then
			return bgSoundConfig_module.bgSoundConfig[i].soundId
		end
    end
	return SOUND_BEIJINGMAIN
end

function playBgSoundHelper(mainType,subType)
	local soundMgr = CSoundMgr:instance();
	if soundMgr:CanChangeBgSound() == false then
		return nil
	end

	local targetSoundId = findTargetBgSoundById(mainType,subType)
	if targetSoundId == soundMgr:GetPlayingBgSound() then
		if soundMgr:IsBackgroundSoundPlaying() == false then
			soundMgr:StopAllEffect()
			soundMgr:PlayBackgroundSound(targetSoundId,true)
		end
	else
		soundMgr:StopAllEffect()
		soundMgr:StopBackgroundSound()
		soundMgr:PlayBackgroundSound(targetSoundId, true)
	end
end


