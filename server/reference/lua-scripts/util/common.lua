--description：该文件主要用来存储项目中的一些与游戏业务相关的公共的配置性文件
--company：xckoo
require "LuaXml"
require "util/localizable"

function new(moduleName)
    local obj = {}
    setmetatable(obj, {__index = moduleName})
    return obj
end

function baseClass(base, myClass)
    setmetatable(myClass, {__index = base})
end

function createObj(moduleName, ...)
    local obj = new(moduleName)
    obj:init(...)
    return obj
end

-- for CCLuaEngine traceback
function __G__TRACKBACK__(msg)
    if is_debug then
        cclog("----------------------------------------")
        cclog("LUA ERROR: " .. tostring(msg) .. "\n")
        cclog(debug.traceback())
        cclog("----------------------------------------")
    else
        local playerMgr = CPlayerDataMgr:instance()
        local playerData = playerMgr:GetPlayerInfoData()
        local tmpUrlPath = GetUrlNormalHeader(playerData.m_uid, protocol.LOG_CMD_FOR_SYSTEM_ERROR, protocol.URL_W_LOG)
        local transData = "LUA ERROR: " .. tostring(msg) .. "\n" .. debug.traceback()
        transData = tools.urlencode(transData)
        tmpUrlPath = AddData(tmpUrlPath, "Content", transData)
        CCHttpRequest:open(tmpUrlPath, kHttpPost, "query=param1&other=params"):sendWithHandler(
            function(res, hnd)

            end)
    end
end

--configData  配置公共文件
country_config = {}
country_config[0] = localizable.ui_border_country_wind
country_config[1] = localizable.ui_border_country_thunder
country_config[2] = localizable.ui_border_country_water
country_config[3] = localizable.ui_border_country_fire
country_config[4] = localizable.ui_border_country_earth

normal_apple_goods_prefix = "com.xckoo.renlong.en.normal."
month_apple_goods_prefix = "com.xckoo.renlong.en.month"

--跨服战相关配置
--MULTI_BATTLE_CGI_IP = "http://203.195.189.76:8080"
if CServerListMgr:instance():GetServerConfig().m_url ~= "http://203.90.233.3:8080" then
    if GetPlatformStr() == "IOS" then
        MULTI_BATTLE_CGI_IP = "http://23.91.96.227:8080"
    elseif GetPlatformStr() == "Android" then
        MULTI_BATTLE_CGI_IP = "http://23.91.96.227:8080"
    else
        MULTI_BATTLE_CGI_IP = "http://23.91.96.227:8080"
    end
else
    MULTI_BATTLE_CGI_IP = "http://203.90.233.3:8080"
end
MULTI_BATTLE_INSPIRE_VALUE = 10
MULTI_BATTLE_INSPIRE_COST = 200
MULTI_BATTLE_BUY_TICKET = 500
MULTI_BATTLE_BATTLE_PERSON_COUNT = 20
MULTI_BATTLE_TIME_SCALE_VALUE = 60
MULTI_INSPIRE_TIME = 300

quality_color_config = {}

quality_color_config[1] = ccc3(0,255,255)
quality_color_config[2] = ccc3(255,251,0)
quality_color_config[3] = ccc3(0,255,0)
quality_color_config[4] = ccc3(40,190,255)
quality_color_config[5] = ccc3(255,0,254)
quality_color_config[6] = ccc3(255,78,0)

-- 返回卡片的图标ccsprite ，底框frame的 CCSpriteFrame， 卡牌的品質,  图标名字
function rl_get_iconsprite(maintype, subtype, sizetype, cardId, bReturnFrame)
    maintype = tostring(maintype)
    subtype = tostring(subtype)
    --maintype = "5"
    if maintype == "1" then
        if subtype == "1" then
            local info = DataMgr.GetDataByID("Struct_Ninjainfo", tonumber(cardId))
            local obj = CGameObjElement:GetNinjaIcon(sizetype, info.m_ninjaicon)
            if bReturnFrame ~= nil and bReturnFrame == true then
            else
                obj = CCSprite:createWithSpriteFrame(obj)
            end
            return obj, rl_get_frameicon(sizetype, info.m_quality), info.m_quality, info.m_ninjaname
        elseif subtype == "2" then
            local info = DataMgr.GetDataByID("Struct_Equipmentinfo", tonumber(cardId))
            local obj = CGameObjElement:GetEquipIcon(sizetype, info.m_equipicon)
            if bReturnFrame ~= nil and bReturnFrame == true then
            else
                obj = CCSprite:createWithSpriteFrame(obj)
            end
            return obj, rl_get_frameicon(sizetype, info.m_quality), info.m_quality, info.m_equipname
        elseif subtype == "3" or subtype == "5" then
            local info = DataMgr.GetDataByID("Struct_Markinfo", tonumber(cardId))
            local obj = CGameObjElement:GetMarkFragmentIcon(sizetype, info.m_markicon)
            if bReturnFrame ~= nil and bReturnFrame == true then
            else
                obj = CCSprite:createWithSpriteFrame(obj)
            end
            return obj, rl_get_frameicon(sizetype, info.m_quality), info.m_quality, info.m_markname
        elseif subtype == "4" then
            local info = DataMgr.GetDataByID("Struct_Ninjutsuinfo", tonumber(cardId))
            local obj = CGameObjElement:GetNinjutsuIcon(sizetype, info.m_icon)
            if bReturnFrame ~= nil and bReturnFrame == true then
            else
                obj = CCSprite:createWithSpriteFrame(obj)
            end
            return obj, rl_get_frameicon(sizetype, info.m_quality), info.m_quality, info.m_ninjutsuName
        end
    elseif maintype == "2" then
        -- 消耗品
        local info = DataMgr.GetDataByID("Struct_Consumeinfo", tonumber(cardId))
        local obj = CGameObjElement:GetConsumeIcon(sizetype, info.m_icon)
            if bReturnFrame ~= nil and bReturnFrame == true then
            else
                obj = CCSprite:createWithSpriteFrame(obj)
            end
        if sizetype == E_FRAMETYPE_SMALL then
            return obj, CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("small_box_skill_01"), 1, info.m_namestr
        else
            return obj, CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("small_box01"), 1, info.m_namestr
        end
    elseif maintype == "3" then
        -- 银子
        local obj = CGameObjElement:GetConsumeIcon(sizetype, "props_036")
            if bReturnFrame ~= nil and bReturnFrame == true then
            else
                obj = CCSprite:createWithSpriteFrame(obj)
            end
        if nil ~= cardId then
            local info = DataMgr.GetDataByID("Struct_Dropinfo", tonumber(cardId))
            if sizetype == E_FRAMETYPE_SMALL then
                return obj, CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("small_box_skill_01"), 1, info.m_dropdesc
            else
                return obj, CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("small_box01"), 1, info.m_dropdesc
            end
        else
            if sizetype == E_FRAMETYPE_SMALL then
                return obj, CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("small_box_skill_01"), 1, localizable.ui_common_silver
            else
                return obj, CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("small_box01"), 1, localizable.ui_common_silver
            end
        end
    elseif maintype == "4" then
        -- 金币
        local obj = CGameObjElement:GetConsumeIcon(sizetype, "props_037")
            if bReturnFrame ~= nil and bReturnFrame == true then
            else
                obj = CCSprite:createWithSpriteFrame(obj)
            end
        if nil ~= cardId then
            local info = DataMgr.GetDataByID("Struct_Dropinfo", tonumber(cardId))
            if sizetype == E_FRAMETYPE_SMALL then
                return obj, CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("small_box_skill_01"), 1, info.m_dropdesc
            else
                return obj, CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("small_box01"), 1, info.m_dropdesc
            end
        else
            if sizetype == E_FRAMETYPE_SMALL then
                return obj, CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("small_box_skill_01"), 1, localizable.ui_common_gold
            else
                return obj, CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("small_box01"), 1, localizable.ui_common_gold
            end
        end
    elseif maintype == "5" then
        -- 碎片
        local info = DataMgr.GetDataByID("Struct_Piece_Info", tonumber(cardId))
        if info.m_piece_type == 1 then
            local info1 = DataMgr.GetDataByID("Struct_Ninjainfo", tonumber(info.m_piece_targetthingID))
            local obj = CGameObjElement:GetNinjaIcon(sizetype, info1.m_ninjaicon)
            if bReturnFrame ~= nil and bReturnFrame == true then
            else
                obj = CCSprite:createWithSpriteFrame(obj)
            end
            return obj, rl_get_frameicon(sizetype, info1.m_quality), info1.m_quality, info1.m_ninjaname
        elseif info.m_piece_type == 2 then
            local info1 = DataMgr.GetDataByID("Struct_Equipmentinfo", tonumber(info.m_piece_targetthingID))
            local obj = CGameObjElement:GetNinjaIcon(sizetype, info1.m_equipicon)
            if bReturnFrame ~= nil and bReturnFrame == true then
            else
                obj = CCSprite:createWithSpriteFrame(obj)
            end
            return obj, rl_get_frameicon(sizetype, info1.m_quality), info1.m_quality, info1.m_equipname
        elseif info.m_piece_type == 3 then
            local info1 = DataMgr.GetDataByID("Struct_Ninjutsuinfo", tonumber(info.m_piece_targetthingID))
            local obj = CGameObjElement:GetNinjaIcon(sizetype, info1.m_markicon)
            if bReturnFrame ~= nil and bReturnFrame == true then
            else
                obj = CCSprite:createWithSpriteFrame(obj)
            end
            return obj, rl_get_frameicon(sizetype, info1.m_quality), info1.m_quality, info1.m_ninjutsuName
        elseif info.m_piece_type == 5 then
            local info1 = DataMgr.GetDataByID("Struct_Petinfo", tonumber(info.m_piece_targetthingID))
            local obj = CGameObjElement:GetNinjaIcon(sizetype, info1.m_pet_icon)
            if bReturnFrame ~= nil and bReturnFrame == true then
            else
                obj = CCSprite:createWithSpriteFrame(obj)
            end
            return obj, rl_get_frameicon(sizetype, info1.m_pet_quality), info1.m_pet_quality, info1.m_pet_name
        end

    elseif maintype == "6" then
        -- 忍魂
        local obj = CGameObjElement:GetConsumeIcon(sizetype, "props_164")
            if bReturnFrame ~= nil and bReturnFrame == true then
            else
                obj = CCSprite:createWithSpriteFrame(obj)
            end
        if nil ~= cardId then
            local info = DataMgr.GetDataByID("Struct_Dropinfo", tonumber(cardId))
            if sizetype == E_FRAMETYPE_SMALL then
                return obj, CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("small_box_skill_01"), 1, info.m_dropdesc
            else
                return obj, CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("small_box01"), 1, info.m_dropdesc
            end
        else
            if sizetype == E_FRAMETYPE_SMALL then
                return obj, CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("small_box_skill_01"), 1, localizable.ui_common_soul
            else
                return obj, CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("small_box01"), 1, localizable.ui_common_soul
            end
        end

    elseif maintype == "7" then
        -- 通灵兽
        local info = DataMgr.GetDataByID("Struct_Petinfo", tonumber(cardId))
        local obj = CGameObjElement:GetNinjaIcon(sizetype, info.m_pet_icon)
            if bReturnFrame ~= nil and bReturnFrame == true then
            else
                obj = CCSprite:createWithSpriteFrame(obj)
            end
        return obj, rl_get_frameicon(sizetype, info.m_pet_quality), info.m_pet_quality, info.m_pet_name
        
    elseif maintype == "9" then
        -- 掉落,与忍者处理相同
        if subtype == "9" then
            local obj = CGameObjElement:GetConsumeIcon(sizetype, "props_121")
            if bReturnFrame ~= nil and bReturnFrame == true then
            else
                obj = CCSprite:createWithSpriteFrame(obj)
            end
            local iconSpr = CCSprite:createWithSpriteFrame(icon)
            local frame = rl_get_frameicon(sizetype, 3)

            return obj, frame, 1, ""
        end
    end
end


function rl_get_frameicon(sizetype, quality)
    if sizetype == E_FRAMETYPE_SMALL then
        local iconname = "small_box_skill_0" .. tostring(quality)
        return CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(iconname)
    elseif sizetype == E_FRAMETYPE_MIDDLE then
        local iconname = "small_box0" .. tostring(quality)
        return CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(iconname)
    else
        local iconname = "frame_big_0" .. tostring(quality)
        return CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(iconname)
    end
end

function rl_get_ninjaFrame(sizetype, quality)
    return CGameObjElement:GetNinjaFrame(sizetype, quality)
end

function showErrorTextTip(retcode)
	if text.text_config[tonumber(retcode)] == nil then
		return
	end
	GetMainMenu():ShowTextTip(text.text_config[tonumber(retcode)].description,-1);
end

local path = CCFileUtils:sharedFileUtils():getWritablePath().."ActivityData.xml"

--读取当前用户活动数据，传入uid，返回user活动数据
function readActivityData(uid)
    -- 加载XML文件
    local file = io.open(path)
    if file == nil then--第一次进入，创建一个xml的文件
        local activity = xml.new("activity")
        local user = activity:append("user")
        user.uid = uid
        activity:save(path)
    else
        file:close()
        local xfile = xml.load(path)
        local activity = xfile:find("activity")
        for i=1,#activity do
            --local user = activity:find("user")--存在user
            if tonumber(activity[i].uid) == tonumber(uid) then
                return activity[i]
            end
        end
        --不存在user
        local user = activity:append("user")
        user.uid = uid
        activity:save(path)
    end
    return nil
end

--查看当前活动期数，与文件中活动期数对比，相等=不提示0，不相等=提示1
--传入user活动数据userData和当前活动actid和当前期数curPeriod
function showActivityNotify(userData, actid, curPeriod)
    for i=1,#userData do
        if tonumber(userData[i].actid) == tonumber(actid) then
            if userData[i].period == curPeriod then
                return 0
            else
                return 1
            end
        end
    end
    return 1
end

--写入活动数据
function writeActivityData(uid, actid, curPeriod)
    -- 加载XML文件  
    local xfile = xml.load(path)
    local activity = xfile:find("activity")
    for j=1,#activity do
        local user = activity[j]
        if tonumber(user.uid) == tonumber(uid) then
            if #user == 0 then--无活动数据  直接插入新数据
                local item = user:append("item")
                item.actid = actid
                item.period = curPeriod
                xfile:save(path)
                break
            else
                for i=1,#user do--查找是否存在此活动节点
                    if tonumber(user[i].actid) == tonumber(actid) then
                        user[i].period = curPeriod--更新节点数据
                        xfile:save(path)
                        return nil
                    end
                end
                local item = user:append("item")
                item.actid = actid
                item.period = curPeriod
                xfile:save(path)
                break
            end
        end
    end
    return nil
end

--通过物品掉落id获取物品的主类型、子类型、映射表的id、数量、掉落类型(1集合)
function setObjTypeInfo(cardId)
    ---[[
    local data = DataMgr.GetDataByID("Struct_Dropinfo", tonumber(cardId))
    if data then
        if tonumber(data.m_ninja_id) > 0 then               --忍者卡
            return 1, 1, tonumber(data.m_ninja_id), data.m_drop_num, data.m_drop_type
        elseif tonumber(data.m_equip_id) > 0 then           --装备卡
            return 1, 2, tonumber(data.m_equip_id), data.m_drop_num, data.m_drop_type
        elseif tonumber(data.m_skill_id) > 0 then           --忍术卡
            return 1, 4, tonumber(data.m_skill_id), data.m_drop_num, data.m_drop_type
        elseif tonumber(data.m_mark_id) > 0 then            --印记/印记碎片
            return 1, 3, tonumber(data.m_mark_id), data.m_drop_num, data.m_drop_type
        elseif tonumber(data.m_prop_id) > 0 then            --物品卡
            return 2, 0, tonumber(data.m_prop_id), data.m_drop_num, data.m_drop_type
        elseif tonumber(data.m_suipians_id) > 0 then        --装备碎片
            return 5, 0, tonumber(data.m_suipians_id), data.m_drop_num, data.m_drop_type
        elseif tonumber(data.m_yinzi_num) > 0 then          --银两
            return 3, 0, tonumber(cardId), data.m_drop_num, data.m_drop_type
        elseif tonumber(data.m_yuanbao_num) > 0 then          --元宝
            return 4, 0, tonumber(cardId), data.m_drop_num, data.m_drop_type
        elseif tonumber(data.m_renhuns_num) > 0 then          --忍魂
            return 6, 0, tonumber(cardId), data.m_drop_num, data.m_drop_type
        end
    end
    --]]
end
-- 启用、禁用按钮，当禁用时按钮灰色
function setBtnEnabled( btn, flag )
    btn:setEnabled(flag)
    local target = nil
    local program = nil
    if flag then
        target = btn:getBackgroundSpriteForState(CCControlStateNormal)
        program = CCShaderCache:sharedShaderCache():programForKey("ShaderPositionTextureColor")
    else
        target = btn:getBackgroundSpriteForState(CCControlStateDisabled)
        program = CCShaderCache:sharedShaderCache():programForKey("greysprite")
    end

    if target ~= nil and  program ~= nil then
        target:setShaderProgram(program)
    end
end

function setBtnTitle( btn, title )
    btn:setTitleForState(title, CCControlStateNormal)
    btn:setTitleForState(title, CCControlStateHighlighted)
    btn:setTitleForState(title, CCControlStateDisabled)
    btn:setTitleForState(title, CCControlStateSelected)
end

--计算两点间距离的平方
function distanceSQ(pt1,pt2)
    x = pt1.x - pt2.x
    y = pt1.y - pt2.y
    return x*x + y*y
end

function showModelLayer( layerModule, ... )
    local layer = createObj(layerModule, ...)
    local size1 = GetMainMenu():GetModelLayer():getContentSize()
    layer.node_:setAnchorPoint(ccp(0.5, 0.5))
    layer.node_:setPosition(size1.width / 2, size1.height / 2)
    GetMainMenu():GetModelLayer():addChild(layer.node_)
end

function countryIcon( countryId )
    CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile("com_res/Resident.plist")

    local icons = {"com_icon_country_Wind","com_icon_country_Mine","com_icon_country_Water","com_icon_country_Fire","com_icon_country_Earth"}
    if countryId <0 or countryId > #icons - 1 then
        return ""
    end
    return icons[countryId+1]
end

-- 打印table
function printTable (lua_table, indent)
    if lua_table == nil or type(lua_table) ~= "table" then
        return
    end

    local function print_func(str)
        cclog("--" .. tostring(str))
    end
    indent = indent or 0
    for k, v in pairs(lua_table) do
        if type(k) == "string" then
            k = string.format("%q", k)
        end
        local szSuffix = ""
        if type(v) == "table" then
            szSuffix = "{"
        end
        local szPrefix = string.rep("    ", indent)
        formatting = szPrefix.."["..k.."]".." = "..szSuffix
        if type(v) == "table" then
            print_func(formatting)
            printTable(v, indent + 1)
            print_func(szPrefix.."},")
        else
            local szValue = ""
            if type(v) == "string" then
                szValue = string.format("%q", v)
            else
                szValue = tostring(v)
            end
            print_func(formatting..szValue..",")
        end
    end
end

-- 深拷贝表，支持环形表
function table.deepcopy(object)
	local lookup_table = { }
	local function _copy(object)
		if type(object) ~= "table" then
			return object
		elseif lookup_table[object] then
			return lookup_table[object]
		end
		local new_table = { }
		lookup_table[object] = new_table
		for index, value in pairs(object) do
			new_table[_copy(index)] = _copy(value)
		end
		return setmetatable(new_table, getmetatable(object))
	end
	return _copy(object)
end

function initHeader(proxy)
	if not proxy then return end

	local sprite_playermedal = tolua.cast(proxy:getNode("sprite_playermedal"), "CCSprite")
	local label_level = tolua.cast(proxy:getNode("label_level"), "CCLabelBMFont")
	local label_curexp = tolua.cast(proxy:getNode("label_curexp"), "CCLabelBMFont")
	local label_name = tolua.cast(proxy:getNode("label_name"), "CCLabelTTF")
	local sprite_vipinfo = tolua.cast(proxy:getNode("sprite_vipinfo"), "CCSprite")
	local label_bodyval = tolua.cast(proxy:getNode("label_bodyval"), "CCLabelBMFont")
	local label_attackval = tolua.cast(proxy:getNode("label_attackval"), "CCLabelBMFont")
	local label_goldval = tolua.cast(proxy:getNode("label_goldval"), "CCLabelBMFont")
	local label_silverval = tolua.cast(proxy:getNode("label_silverval"), "CCLabelBMFont")
	local ctrl_btnplayermsg = tolua.cast(proxy:getNode("ctrl_btnplayermsg"), "CCControlButton")
	local sprite_levelstate = tolua.cast(proxy:getNode("sprite_levelstate"), "CCSprite")
	local sprite_bodyratio = tolua.cast(proxy:getNode("sprite_bodyratio"), "CCSprite")
	local sprite_attackratio = tolua.cast(proxy:getNode("sprite_attackratio"), "CCSprite")


	local dataMgr = CPlayerDataMgr:instance()
	local playerData = dataMgr:GetPlayerInfoData()

	local meritIcon = dataMgr:GetMeritIcon()
	if meritIcon ~= nil then
		local pFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(meritIcon)
		if pFrame ~= nil then
			sprite_playermedal:setDisplayFrame(pFrame)
		end
	end
	-- exp
	label_name:setString(playerData.m_name)
	local nextExp = dataMgr:GetNextLevelExp()
	local expStr = tostring(playerData.m_exp) .. "/" .. tostring(nextExp)
	label_curexp:setString(expStr)
	sprite_levelstate:setScaleX(playerData.m_exp / nextExp)

	-- vipinfo
	local viplevel = playerData.m_viplevel
	local vipframes = {
		[0] = "vip_015",
		[1] = "vip_003",
		[2] = "vip_004",
		[3] = "vip_005",
		[4] = "vip_006",
		[5] = "vip_007",
		[6] = "vip_008",
		[7] = "vip_009",
		[8] = "vip_010",
		[9] = "vip_011",
		[10] = "vip_012",
		[11] = "vip_013",
		[12] = "vip_014",
		[13] = "vip_s_13",
		[14] = "vip_s_14",
		[15] = "vip_s_15",
		[16] = "vip_s_16",
		[17] = "vip_s_17",
		[18] = "vip_s_18"
	}
	if sprite_vipinfo ~= nil then
		local pFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(vipframes[viplevel])
		sprite_vipinfo:setDisplayFrame(pFrame)
	end

	-- bodyval
	local maxbodyval = dataMgr:GetMaxBodyValue()
	local bodyValStr = tostring(playerData.m_bodyvalue) .. "/" .. tostring(maxbodyval)
	label_bodyval:setString(bodyValStr)
	local scaleVal = playerData.m_bodyvalue / maxbodyval
	if scaleVal > 1 then
		scaleVal = 1
	end
	sprite_bodyratio:setScaleX(scaleVal)

	-- attack
	local maxattack = dataMgr:GetMaxAttackCount()
	local attackValStr = tostring(playerData.m_fightcount) .. "/" .. tostring(maxattack)
	label_attackval:setString(attackValStr)
	sprite_attackratio:setScaleX(playerData.m_fightcount / maxattack)

	-- gold & silver
	label_goldval:setString(tostring(playerData.m_gold))
	label_silverval:setString(tostring(playerData.m_silver))
	label_level:setString(tostring(playerData.m_level))

    ctrl_btnplayermsg:setTouchPriority(kCCMenuHandlerPriority - 1)
    ctrl_btnplayermsg:setTouchEnabled(true)
    proxy:handleButtonEvent(ctrl_btnplayermsg, function(button, event)
        GetMainMenu():OnShowUserInfo()
        return nil
    end, CCControlEventTouchDown)
end

function showTipsDialog( text )
    require("ui_layer/ui_tipsDialog")
    showModelLayer(ui_tipsDialog,text)
end

--added by milo

Color3 = {}
Color3["Red"] = ccc3(255, 0, 0)
Color3["Green"] = ccc3(0, 255, 0)

function getCtrlFromCCB(ccb_proxy, ctrl_name, type)
    if ccb_proxy == nil then
        return nil
    else
        return tolua.cast(ccb_proxy:getNode(ctrl_name), type)
    end
end

function getButtonFromCCB(ccb_proxy, ctrl_name)
    return getCtrlFromCCB(ccb_proxy, ctrl_name, "CCControlButton")
end
function getLabelBMFontFromCCB(ccb_proxy, ctrl_name)
    return getCtrlFromCCB(ccb_proxy, ctrl_name, "CCLabelBMFont")
end
function getLabelTTFFromCCB(ccb_proxy, ctrl_name)
    return getCtrlFromCCB(ccb_proxy, ctrl_name, "CCLabelTTF")
end
function getNodeFromCCB(ccb_proxy, ctrl_name)
    return getCtrlFromCCB(ccb_proxy, ctrl_name, "CCNode")
end
function getSpriteFromCCB(ccb_proxy, ctrl_name)
    return getCtrlFromCCB(ccb_proxy, ctrl_name, "CCSprite")
end
function getScale9SpriteFromCCB(ccb_proxy, ctrl_name)
    return getCtrlFromCCB(ccb_proxy, ctrl_name, "CCScale9Sprite")
end

function getLayerFromCCB(ccb_proxy, ctrl_name)
    return getCtrlFromCCB(ccb_proxy, ctrl_name, "CCLayer")
end

function sendRequest(urlpath, callback, log)
    log = log or 0
    if urlpath == nil or callback == nil then
        return
    end

    GetMainMenu():ShowLoadingDlg()
    CCHttpRequest:open(urlpath, kHttpPost, "query=param1&other=params"):sendWithHandler(
        function (res, hnd)

            GetMainMenu():CloseLoadding()

            local code = res:getResponseCode()
            local resData = res:getResponseData()
            local data = xml.parse(resData):find("RENLONG")
            if log == 1 then
                cclog('========================Url=========================')
                cclog('url:' .. urlpath)
                cclog('----------------------------------------------------')
                cclog(resData)
                cclog('----------------------------------------------------')
            end

            if data == nil then
                return nil
            end
            
            if data.code == "0" then
                callback(data)    
            else
                cclog("error code = " .. data.code)
                GetMainMenu():ShowErrorTip(tonumber(data.code), -1) 
            end
        end
    )
end

--added end   milo

function showPayRanking( )
    local player =  CPlayerDataMgr:instance():GetPlayerInfoData()
    local params = string.format('uid=%d&sz=%d',player.m_uid, 30)
    local url = 'http://203.90.233.4:8999/TopRank?' .. params
    cclog(url)
    openHyperlink(url)
    -- body
end