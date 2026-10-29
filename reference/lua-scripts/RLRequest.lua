-- renlong network interface
require "util/localizable"

function GetInGameNewsUrl()
    local urlpath = CServerListMgr:instance():GetAreaUrl()
    local urlpath1 = string.gsub(urlpath, "xk_r_dir", "")
    return urlpath1
end

function GetNormalUrl()
	local urlpath = GetAeraURL().."/"
	return urlpath
end
function GetDIRlUrl()
	local urlpath = CServerListMgr:instance():GetServerConfig().m_url.."/"
	return urlpath
end
function SetCgiUrl(url, cgi)
	local urlpath = url..cgi.."?"
	return urlpath
end

function AddData(url, key, data)
	local urlpath = url.."&"..key.."="..tostring(data)
	return urlpath
end

function AddFirstData(url, key, data)
	local urlpath = url..key.."="..tostring(data)
	return urlpath
end

function AddCmd(url, cmdCode)
	return AddFirstData(url, "Cmd", cmdCode)
end

function GetUrlNormalHeader(uid, cmdCode, cgi)
	local urlpath = SetCgiUrl(GetNormalUrl(), cgi)
	urlpath = AddCmd(urlpath, cmdCode)
	urlpath = AddData(urlpath, "Uid", CNetUser:instance():GetUserID())
	urlpath = AddData(urlpath, "Session", CNetUser:instance():GetSessionID())
	urlpath = AddData(urlpath, "Clinettime", GetClinetTime())
	urlpath = AddData(urlpath, "Platform", GetPlatForm())
	urlpath = AddData(urlpath, "Version", GetGameVersion())
	urlpath = AddData(urlpath, "Pt", CNetUser:instance():GetPlatformID())
	urlpath = AddData(urlpath, "ServerID", CNetUser:instance():GetAreaID())
	urlpath = AddData(urlpath, "GroupID", CNetUser:instance():GetGroupID())
	return urlpath
end

function GetDirNormalHeader(uid, cmdCode, cgi)
	local urlpath = SetCgiUrl(GetDIRlUrl(), cgi)
	urlpath = AddCmd(urlpath, cmdCode)
	urlpath = AddData(urlpath, "Uid", CNetUser:instance():GetUserID())
	urlpath = AddData(urlpath, "Session", CNetUser:instance():GetSessionID())
	urlpath = AddData(urlpath, "Clinettime", GetClinetTime())
	urlpath = AddData(urlpath, "Platform", GetPlatForm())
	urlpath = AddData(urlpath, "Version", GetGameVersion())
	urlpath = AddData(urlpath, "Pt", CNetUser:instance():GetPlatformID())
	urlpath = AddData(urlpath, "ServerID", CNetUser:instance():GetAreaID())
	urlpath = AddData(urlpath, "GroupID", CNetUser:instance():GetGroupID())
	return urlpath
end

function GetInGameNewsNormalHeader(uid, cmdCode, cgi)
	local urlpath = SetCgiUrl(GetInGameNewsUrl(), cgi)
	urlpath = AddCmd(urlpath, cmdCode)
	urlpath = AddData(urlpath, "Uid", CNetUser:instance():GetUserID())
	urlpath = AddData(urlpath, "Session", CNetUser:instance():GetSessionID())
	urlpath = AddData(urlpath, "Clinettime", GetClinetTime())
	urlpath = AddData(urlpath, "Platform", GetPlatForm())
	urlpath = AddData(urlpath, "Version", GetGameVersion())
	urlpath = AddData(urlpath, "Pt", CNetUser:instance():GetPlatformID())
	urlpath = AddData(urlpath, "ServerID", CNetUser:instance():GetAreaID())
	urlpath = AddData(urlpath, "GroupID", CNetUser:instance():GetGroupID())
	return urlpath
end

function GetAccountNormalHeader(uid, cmdCode, cgi)
	local urlpath = CServerListMgr:instance():GetServerConfig().m_accounturl .."/" .. cgi .. "?"
	urlpath = AddCmd(urlpath, cmdCode)
	urlpath = AddData(urlpath, "Uid", CNetUser:instance():GetUserID())
	urlpath = AddData(urlpath, "Session", CNetUser:instance():GetSessionID())
	urlpath = AddData(urlpath, "Clinettime", GetClinetTime())
	urlpath = AddData(urlpath, "Platform", GetPlatForm())
	urlpath = AddData(urlpath, "Version", GetGameVersion())
	urlpath = AddData(urlpath, "Pt", CNetUser:instance():GetPlatformID())
	urlpath = AddData(urlpath, "ServerID", CNetUser:instance():GetAreaID())
	urlpath = AddData(urlpath, "GroupID", CNetUser:instance():GetGroupID())
	return urlpath
end

function GetMultiBattleHeader(uid, cmdCode, cgi)
	local urlpath = MULTI_BATTLE_CGI_IP .. "/" .. cgi .. "?"
	--cclog("20160219--  multi_battle_cgi_ip : %s", MULTI_BATTLE_CGI_IP)
	urlpath = AddCmd(urlpath, cmdCode)
	urlpath = AddData(urlpath, "Uid", CNetUser:instance():GetUserID())
	urlpath = AddData(urlpath, "Session", CNetUser:instance():GetSessionID())
	urlpath = AddData(urlpath, "Clinettime", GetClinetTime())
	urlpath = AddData(urlpath, "Platform", GetPlatForm())
	urlpath = AddData(urlpath, "Version", GetGameVersion())
	urlpath = AddData(urlpath, "Pt", CNetUser:instance():GetPlatformID())
	urlpath = AddData(urlpath, "ServerID", CNetUser:instance():GetAreaID())
	urlpath = AddData(urlpath, "GroupID", CNetUser:instance():GetGroupID())
	return urlpath
end

function InitAwardData(rewarddata,awardXML)
	if awardXML ~= nil then
		--rewarddata.type = awardXML.type
		--rewarddata.dropid = awardXML.dropid
		--处理dropid未发过来的情况
		if nil ~= awardXML.dropid then
			rewarddata.m_dropid = awardXML.dropid
		end

		local cardlistXML = awardXML:find("cardlist")
		if cardlistXML then
			local cardCount = #cardlistXML
			for i = 1, cardCount do
				local card = CardNetData:new()
				card.m_dataid = (cardlistXML[i]:find("id"))[1]
				card.m_type = (cardlistXML[i]:find("type"))[1]
				card.m_count = (cardlistXML[i]:find("num"))[1]
				card.m_guid = (cardlistXML[i]:find("bagIndex"))[1]
				card.m_camp = (cardlistXML[i]:find("attri"))[1]
				local _level = cardlistXML[i]:find("level")
				--litao_等级、转生、淬炼等级
				if nil ~= _level then
					card.m_level = tonumber(_level[1])
				end
				local _reincarnationLevel = cardlistXML[i]:find("newlife")
				if nil ~= _reincarnationLevel then
					card.m_reincarnationLevel = tonumber(_reincarnationLevel[1])
				end
				local _starLevel = cardlistXML[i]:find("starlevel")
				if nil ~= _starLevel then
					card.m_strengthLevel = tonumber(_starLevel[1])
				end
				--litao_2014.6.23_培养数值   zhangwy_20160225 培养数值修改
				local _attack = cardlistXML[i]:find("attack_pot_val")
				if nil ~= _attack then
					card.m_attack_add = tonumber(_attack[1])
				end
				local _defense = cardlistXML[i]:find("defense_pot_val")
				if nil ~= _defense then
					card.m_defence_add = tonumber(_defense[1])
				end
				local _chakra = cardlistXML[i]:find("chakra_pot_val")
				if nil ~= _chakra then
					card.m_cha_add = tonumber(_chakra[1])
				end
				--突破信息
				local _tupoLevel = cardlistXML[i]:find("breakthrough_lvl")
				if nil ~= _tupoLevel then
					card.m_tupoLevel = tonumber(_tupoLevel[1])
					--cclog("--20160223-- tupo_level : %d", card.m_tupoLevel)
					--cclog("--20160223-- tupo_level : %d", card.m_tupoLevel)
				end
				local _tupoAtta = cardlistXML[i]:find("breakthrough_att")
				if nil ~= _tupoAtta then
					card.m_nTupoAttactAdd = tonumber(_tupoAtta[1])
					--cclog("--20160224-- tupo_Atta : %d", card.m_nTupoAttactAdd)
				end
				local _tupoDefense = cardlistXML[i]:find("breakthrough_def")
				if nil ~= _tupoDefense then
					card.m_nTupoDefenseAdd = tonumber(_tupoDefense[1])
					--cclog("--20160224-- tupo_defense : %d", card.m_nTupoDefenseAdd)
				end
				local _tupoCha = cardlistXML[i]:find("breakthrough_cha")
				if nil ~= _tupoCha then
					card.m_nTupoChakraAdd = tonumber(_tupoCha[1])
					--cclog("--20160224-- tupo_cha : %d", card.m_nTupoChakraAdd)
				end 

				rewarddata:pushCard(card)
			end
		end
		local proplistXML = awardXML:find("proplist")
		if proplistXML then
		    local propCount = #proplistXML;
		    for i=1,propCount do
		        local prop = DropProData:new()
				prop.m_id = (proplistXML[i]:find("id"))[1]
				prop.m_count = (proplistXML[i]:find("num"))[1]
				rewarddata:pushProp(prop);
		    end
		end

		--增加忍者碎片
		local chipCardListXML = awardXML:find("chipbag")
		if chipCardListXML then
			local chipCount = #chipCardListXML
			for i = 1, chipCount do
				local card = CardNetData:new()
				local id = chipCardListXML[i].id
				local pieceinfo = DataMgr.GetDataByID("Struct_Piece_Info", tonumber(id))
				card.m_pieceid = id
				card.m_dataid = pieceinfo.m_piece_targetthingID
				card.m_type =  pieceinfo.m_piece_type
				card.m_count = 1
				card.m_exp = 0
				card.m_isused = false
				card.m_pieceid = pieceinfo.m_id
				card.m_piecenum = tonumber(chipCardListXML[i].num)
				rewarddata:pushChipCard(card)
			end
		end

		rewarddata.m_silver = awardXML:find("coin")[1]
		rewarddata.m_gold = awardXML:find("cash")[1]
		rewarddata.m_exp = awardXML:find("exp")[1]
		rewarddata.m_markchip = awardXML:find("chip")[1]
		rewarddata.m_bodyvalue = awardXML:find("action")[1]
		rewarddata.m_merit = awardXML:find("merit")[1]
		rewarddata.m_fightvalue = awardXML:find("pk_action")[1]
		rewarddata.m_soul = awardXML:find("soul")[1]

		return rewarddata
	end
	return nil
end
function ShowAward(awardXML,tips)
	if awardXML ~= nil then
		local rewarddata = FightReward:new()
		InitAwardData(rewarddata,awardXML)
		CPlayerDataMgr:instance():AddDataFromReward(rewarddata)
        --if rewarddata:propCount() > 0 or rewarddata:cardCount() > 0 or rewarddata:chipCardCount() > 0 then
		    GetMainMenu():ShowCommonBox(rewarddata)
		--end
		if rewarddata.m_gold ~= 0 then
			GetMainMenu():ShowTextTip(string.format(localizable.localizable.RLRequest_got_god, tostring(rewarddata.m_gold)),-1);
		end
		if rewarddata.m_silver ~= 0 then
			GetMainMenu():ShowTextTip(string.format(localizable.RLRequest_got_silver, tostring(rewarddata.m_silver)),-1);
		end

		return rewarddata
	end
end

function AddSoulAwardData(awardXML)
	if awardXML ~= nil then
		local rewarddata = FightReward:new()
		InitAwardData(rewarddata,awardXML)
		CPlayerDataMgr:instance():AddDataFromReward(rewarddata)
		return rewarddata
	end
end

function ShowAwardForFightReward(fightRewardData)
	if fightRewardData ~= nil then
		CPlayerDataMgr:instance():AddDataFromReward(fightRewardData)
        if fightRewardData:propCount() > 0 or fightRewardData:cardCount() > 0 then
		    GetMainMenu():ShowCommonBox(fightRewardData)
		end
		if fightRewardData.m_gold ~= 0 then
			GetMainMenu():ShowTextTip(string.format(localizable.localizable.RLRequest_got_god, tostring(fightRewardData.m_gold)),-1);
		end
		if fightRewardData.m_silver ~= 0 then
			GetMainMenu():ShowTextTip(string.format(localizable.RLRequest_got_silver, tostring(fightRewardData.m_silver)),-1);
		end
	end
end

function InitFightXML(fightXML, fightdata)
	if fightXML ~= nil and fightdata ~= nil then
		local userinfo = fightXML:find("userinfo")
		if userinfo ~= nil then
			local passtime = tonumber(userinfo:find("LastSPUpdatePastTime")[1])
			CPlayerDataMgr:instance():SetPkPassTime(passtime)
		end

		local fightinfo = fightXML:find("fight")
		if fightinfo ~= nil then
			local previewinfo = fightinfo:find("preview")
			fightdata:SetAttackType(tonumber(previewinfo.type))
			fightdata:SetFightResult(tonumber(previewinfo.result))
			if previewinfo.defenseviplevel ~= nil then
				fightdata:SetDefenseVipLevel(tonumber(previewinfo.defenseviplevel))
			else
				fightdataSetDefenseVipLevel(-1)
			end
            --这么赋值应该是错误的，先保留
			fightdata:GetEnemyInfo().m_enemyname = previewinfo.defensenick
			fightdata:GetEnemyInfo().m_enemyid = tonumber(previewinfo.defenseuid)
			fightdata:GetEnemyInfo().m_enemycountryid = tonumber(previewinfo.defensecountry)
			fightdata:GetEnemyInfo().m_enemylevel = tonumber(previewinfo.defenselevel)
            --cclog
            fightdata:SetEnemyName(previewinfo.defensenick)
            if tonumber(previewinfo.defenselevel) then 
                fightdata:SetEnemyLevel(tonumber(previewinfo.defenselevel))
            end
          --  local name = fightdata:GetEnemyInfo().m_enemyname
			if fightdata:GetMyFightType() == 0 then
				local enemyninja = fightXML:find("guard")
				local myninja = fightXML:find("killer")
				InitFightAddEnemyNinja(enemyninja,fightdata)
				InitFightAddMyNinja(myninja, fightdata)
			elseif fightdata:GetMyFightType() == 1 then
				local enemyninja = fightXML:find("killer")
				local myninja = fightXML:find("guard")
				InitFightAddEnemyNinja(enemyninja,fightdata)
				InitFightAddMyNinja(myninja, fightdata)
			else
				local enemyninja = fightXML:find("guard")
				local myninja = fightXML:find("killer")
				InitFightAddEnemyNinja(enemyninja,fightdata)
				InitFightAddMyNinja(myninja, fightdata)
			end
			InitFightRoundData(fightXML:find("roundlist"), fightdata)
		end
		fightdata:CalcAttackVal()
	end
end
function InitFightAddEnemyNinja(enemyninja, fightdata)
	if enemyninja == nil then
		return nil
	end
	local ninjalist = enemyninja:find("ninjalist")
	if ninjalist ~= nil then
		local ninjadataCount = #ninjalist
		for i = 1, ninjadataCount do
			local ninjacard = FightNinjaData:new()
			ninjacard.m_dataid = tonumber(ninjalist[i]:find("id")[1])
			ninjacard.m_bagid = tonumber(ninjalist[i]:find("bagid")[1])
			ninjacard.m_attackmin = tonumber(ninjalist[i]:find("low")[1])
			ninjacard.m_attackmax = tonumber(ninjalist[i]:find("high")[1])
			ninjacard.m_attackvalue = tonumber(ninjalist[i]:find("end")[1])
			ninjacard.m_level = tonumber(ninjalist[i]:find("level")[1])
			ninjacard.m_attri = tonumber(ninjalist[i]:find("attri")[1])
			if ninjalist[i]:find("starlevel") ~= nil then
				ninjacard.m_starlevel = tonumber(ninjalist[i]:find("starlevel")[1])
			end
			if ninjalist[i]:find("newlife") ~= nil then
				ninjacard.m_newlife = tonumber(ninjalist[i]:find("newlife")[1])
			end

			fightdata:pushEnemyNinja(ninjacard)
		end
	end

	-- added begin
    local pet = enemyninja:find("master_pet")
    local pet_id = 0
    if pet ~= nil then
        pet_id = tonumber(pet:find("pet_id")[1])
        if pet_id <= 0 then
            pet_id = 0
        end
    end
    fightdata:SetEnemyMasterPetid(pet_id)	
    -- added end
end
function InitFightAddMyNinja(myninja, fightdata)
	if myninja == nil then
		return nil
	end
	local ninjalist = myninja:find("ninjalist")
	if ninjalist ~= nil then
		local ninjadataCount = #ninjalist
		for i = 1, ninjadataCount do
			local ninjacard = FightNinjaData:new()
			ninjacard.m_dataid = tonumber(ninjalist[i]:find("id")[1])
			ninjacard.m_bagid = tonumber(ninjalist[i]:find("bagid")[1])
			ninjacard.m_attackmin = tonumber(ninjalist[i]:find("low")[1])
			ninjacard.m_attackmax = tonumber(ninjalist[i]:find("high")[1])
			ninjacard.m_attackvalue = tonumber(ninjalist[i]:find("end")[1])
			ninjacard.m_level = tonumber(ninjalist[i]:find("level")[1])
			ninjacard.m_attri = tonumber(ninjalist[i]:find("attri")[1])
			if ninjalist[i]:find("starlevel") ~= nil then
				ninjacard.m_starlevel = tonumber(ninjalist[i]:find("starlevel")[1])
			end
			if ninjalist[i]:find("newlife") ~= nil then
				ninjacard.m_newlife = tonumber(ninjalist[i]:find("newlife")[1])
			end

			fightdata:pushMyNinja(ninjacard)
		end
	end

    -- added begin
    local pet = myninja:find("master_pet")
    local pet_id = 0
    if pet ~= nil then
        pet_id = tonumber(pet:find("pet_id")[1])
        if pet_id <= 0 then
            pet_id = 0
        end
    end
    fightdata:SetMyMasterPetid(pet_id)	
    -- added end

end
function InitFightRoundData(roundlist, fightdata)
	if roundlist == nil then
		return nil
	end

	local roundCount = #roundlist
	for i = 1, roundCount do
		local rounddata = FightRoundData:new()
		if fightdata:GetMyFightType() == 0 then
			rounddata.m_attackninja = tonumber(roundlist[i]:find("AttackNinja")[1])
			rounddata.m_attackvalue = tonumber(roundlist[i]:find("Attack")[1])
			rounddata.m_attackattri = tonumber(roundlist[i]:find("AttackAttri")[1])
			rounddata.m_defenseninja = tonumber(roundlist[i]:find("DefenseNinja")[1])
			rounddata.m_defensevalue = tonumber(roundlist[i]:find("Defense")[1])
			rounddata.m_defensattri = tonumber(roundlist[i]:find("DefenseAttri")[1])
			rounddata.m_causelimit = tonumber(roundlist[i]:find("CauseLimit")[1])
			rounddata.m_limitvalue = tonumber(roundlist[i]:find("LimitVal")[1])
			rounddata.m_finalAttack = tonumber(roundlist[i]:find("FinalAttack")[1])
			rounddata.m_finaldefense = tonumber(roundlist[i]:find("FinalDefense")[1])
            -- added begin
            rounddata.m_attpetattack = tonumber(roundlist[i]:find("AttPetAttack")[1])
            rounddata.m_attpetdefense = tonumber(roundlist[i]:find("AttPetDefense")[1])
            rounddata.m_defpetattack = tonumber(roundlist[i]:find("DefPetAttack")[1])
            rounddata.m_defpetdefense = tonumber(roundlist[i]:find("DefPetDefense")[1])
            rounddata.m_attpetskillhurt = tonumber(roundlist[i]:find("AttPetSkillHurt")[1])
            rounddata.m_defpetskillhurt = tonumber(roundlist[i]:find("DefpetSkillHurt")[1])
            rounddata.m_attgateattack = tonumber(roundlist[i]:find("AttGateAttack")[1])
            rounddata.m_attgatedefense = tonumber(roundlist[i]:find("AttGateDefense")[1])
            rounddata.m_defgateattack = tonumber(roundlist[i]:find("DefGateAttack")[1])
            rounddata.m_defgatedefense = tonumber(roundlist[i]:find("DefGateDefense")[1])	
            -- added end	

		else
			rounddata.m_attackninja = tonumber(roundlist[i]:find("DefenseNinja")[1])
			rounddata.m_attackvalue = tonumber(roundlist[i]:find("Defense")[1])
			rounddata.m_attackattri = tonumber(roundlist[i]:find("DefenseAttri")[1])
			rounddata.m_defenseninja = tonumber(roundlist[i]:find("AttackNinja")[1])
			rounddata.m_defensevalue = tonumber(roundlist[i]:find("Attack")[1])
			rounddata.m_defensattri = tonumber(roundlist[i]:find("AttackAttri")[1])
			rounddata.m_causelimit = tonumber(roundlist[i]:find("CauseLimit")[1])
			rounddata.m_limitvalue = tonumber(roundlist[i]:find("LimitVal")[1])
			rounddata.m_finaldefense = tonumber(roundlist[i]:find("FinalAttack")[1])
			rounddata.m_finalAttack = tonumber(roundlist[i]:find("FinalDefense")[1])
			-- added begin
			rounddata.m_attpetattack = tonumber(roundlist[i]:find("DefPetAttack")[1])
            rounddata.m_attpetdefense = tonumber(roundlist[i]:find("DefPetDefense")[1])
            rounddata.m_defpetattack = tonumber(roundlist[i]:find("AttPetAttack")[1])
            rounddata.m_defpetdefense = tonumber(roundlist[i]:find("AttPetDefense")[1])
            rounddata.m_attpetskillhurt = tonumber(roundlist[i]:find("DefpetSkillHurt")[1])
            rounddata.m_defpetskillhurt = tonumber(roundlist[i]:find("AttPetSkillHurt")[1])
            rounddata.m_attgateattack = tonumber(roundlist[i]:find("DefGateAttack")[1])
            rounddata.m_attgatedefense = tonumber(roundlist[i]:find("DefGateDefense")[1])
            rounddata.m_defgateattack = tonumber(roundlist[i]:find("AttGateAttack")[1])
            rounddata.m_defgatedefense = tonumber(roundlist[i]:find("AttGateDefense")[1])
            -- added end
		end

		local skillList = roundlist[i]:find("skills")
		if skillList ~= nil and #skillList >= 1 then
			local skillCount = #skillList
			for j = 1, skillCount do
				if fightdata:GetMyFightType() == 0 then
					rounddata.m_skillDataID = tonumber(skillList[j]:find("cardid")[1])
					rounddata.m_chakraattack = tonumber(skillList[j]:find("chakraattack")[1])
					rounddata.m_chakraval = tonumber(skillList[j]:find("chakra")[1])
				else
					rounddata.m_enemyskillDataID = tonumber(skillList[j]:find("cardid")[1])
					rounddata.m_enemychakraattack = tonumber(skillList[j]:find("chakraattack")[1])
					rounddata.m_enemychakraval = tonumber(skillList[j]:find("chakra")[1])
				end
			end
		end
		skillList = roundlist[i]:find("defense_skills")
		if skillList ~= nil and #skillList >= 1 then
			local skillCount = #skillList
			for j = 1, skillCount do
				if fightdata:GetMyFightType() == 0 then
					rounddata.m_enemyskillDataID = tonumber(skillList[j]:find("cardid")[1])
					rounddata.m_enemychakraattack = tonumber(skillList[j]:find("chakraeffval")[1])
					rounddata.m_enemychakraval = tonumber(skillList[j]:find("chakra")[1])
				else
					rounddata.m_skillDataID = tonumber(skillList[j]:find("cardid")[1])
					rounddata.m_chakraattack = tonumber(skillList[j]:find("chakraeffval")[1])
					rounddata.m_chakraval = tonumber(skillList[j]:find("chakra")[1])
				end
			end
		end
		fightdata:pushFightRoundData(rounddata)
	end
end

--从掉落award中提取所需icon(card/消耗品)
function InitAwardIconData(awardXML)
	if awardXML ~= nil then
		--icon data
		local awardIconDatas = {}
        --处理dropid未发过来的情况
		if nil ~= awardXML.dropid then
			awardIconDatas.m_dropid = awardXML.dropid
		end
		local cardlistXML = awardXML:find("cardlist")
		if cardlistXML then
			local cardListIconDatas = {}
			for i = 1, #cardlistXML do
				local card = CardNetData:new()
				card.m_dataid = (cardlistXML[i]:find("id"))[1]
				card.m_type = (cardlistXML[i]:find("type"))[1]
				card.m_count = (cardlistXML[i]:find("num"))[1]
				card.m_guid = (cardlistXML[i]:find("bagIndex"))[1]
				card.m_camp = (cardlistXML[i]:find("attri"))[1]
				--
				local _t_card = {}
				_t_card.num = card.m_count
				_t_card.maintype = 1
				_t_card.subtype = card.m_type
				_t_card.id = card.m_dataid
				_t_card.guid = card.m_guid
				_t_card.camp = card.m_camp
				local _level = cardlistXML[i]:find("level")
				--litao_等级、转生、淬炼等级
				if nil ~= _level then
					_t_card.m_level = tonumber(_level[1])
				end
				local _reincarnationLevel = cardlistXML[i]:find("newlife")
				if nil ~= _reincarnationLevel then
					_t_card.m_reincarnationLevel = tonumber(_reincarnationLevel[1])
				end
				local _starLevel = cardlistXML[i]:find("starlevel")
				if nil ~= _starLevel then
					_t_card.m_strengthLevel = tonumber(_starLevel[1])
				end
				--litao_2014.6.23_培养数值
				local _attack = cardlistXML[i]:find("attack_pot_val")
				if nil ~= _attack then
					_t_card.m_attackPotentialValue = tonumber(_attack[1])
				end
				local _defense = cardlistXML[i]:find("defense_pot_val")
				if nil ~= _defense then
					_t_card.m_defensePotentialValue = tonumber(_defense[1])
				end
				--_t_card.pIcon, _t_card.pFrame, _t_card.quality, _t_card.objname = rl_get_iconsprite(1, card.m_type, E_FRAMETYPE_SMALL, card.m_dataid)
				table.insert(cardListIconDatas, _t_card)
			end
			awardIconDatas.m_cardlist = cardListIconDatas
		end

		local proplistXML = awardXML:find("proplist")
		if proplistXML then
			local propListIconDatas = {}
		    for i=1,#proplistXML do
		        local prop = DropProData:new()
				prop.m_id = (proplistXML[i]:find("id"))[1]
				prop.m_count = (proplistXML[i]:find("num"))[1]
				--
				local _t_prop = {}
				_t_prop.num = prop.m_count
				_t_prop.maintype = 2
				_t_prop.subtype = 0
				_t_prop.id = prop.m_id
				--_t_prop.pIcon, _t_prop.pFrame, _t_prop.objname = rl_get_iconsprite(2, 0, E_FRAMETYPE_SMALL, prop.m_id)
				table.insert(propListIconDatas, _t_prop)
		    end
		    awardIconDatas.m_proplist = propListIconDatas
		end

		--增加忍者碎片
		local chipCardListXML = awardXML:find("chipbag")
		if chipCardListXML then
			local chipListIconDatas = {}
			for i = 1, #chipCardListXML do
				local card = CardNetData:new()
				local id = chipCardListXML[i].id
				local pieceinfo = DataMgr.GetDataByID("Struct_Piece_Info", tonumber(id))
				card.m_pieceid = id
				card.m_dataid = pieceinfo.m_piece_targetthingID
				card.m_type =  pieceinfo.m_piece_type
				card.m_count = 1
				card.m_exp = 0
				card.m_isused = false
				card.m_pieceid = pieceinfo.m_id
				card.m_piecenum = tonumber(chipCardListXML[i].num)
				--
				local _t_chip = {}
				_t_chip.num = card.m_piecenum
				_t_chip.maintype = 5
				_t_chip.subtype = 0
				_t_chip.id = card.m_pieceid
				--_t_chip.pIcon, _t_chip.pFrame, _t_chip.quality, _t_chip.objname = rl_get_iconsprite(5, 0, E_FRAMETYPE_SMALL, card.m_pieceid)
				table.insert(chipListIconDatas, _t_chip)
			end
			awardIconDatas.m_chiplist = chipListIconDatas
		end

		awardIconDatas.m_silver = awardXML:find("coin")[1]
		awardIconDatas.m_gold = awardXML:find("cash")[1]
		awardIconDatas.m_exp = awardXML:find("exp")[1]
		awardIconDatas.m_markchip = awardXML:find("chip")[1]
		awardIconDatas.m_bodyvalue = awardXML:find("action")[1]
		awardIconDatas.m_merit = awardXML:find("merit")[1]
		awardIconDatas.m_fightvalue = awardXML:find("pk_action")[1]
		awardIconDatas.m_soul = awardXML:find("soul")[1]

		return awardIconDatas
	end
	return nil
end