--说明：提供一个工具接口，包括经常用到的方法以及通用算法等
--公司：深圳市炫彩酷游
--add by chenchun

----------------------------------------------------------------------
module("tools", package.seeall )

--函数列表以及说明
--[[
shallowcopy   --------------  浅拷贝对象
split                         分割字符串
getSpriteScaleForFitSize      等比例缩放Sprite到指定的toSize

]]

-- 浅拷贝对象
function shallowcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

--分隔字符串
function split(s, delim)
  assert (type (delim) == "string" and string.len (delim) > 0,
          "bad delimiter")

  local start = 1
  local t = {}  -- results table

  -- find each instance of a string followed by the delimiter
  while true do
    local pos = string.find (s, delim, start, true) -- plain find

    if not pos then
      break
    end

    table.insert (t, string.sub (s, start, pos - 1))
    start = pos + string.len (delim)
  end -- while

  -- insert final one (after last delimiter)
  table.insert (t, string.sub (s, start))
  return t

end -- function split

-- 等比例缩放Sprite到指定的toSize
function getSpriteScaleForFitSize( sprite, toSize )
     -- 计算缩放比.
    local standWidth,standHeight = toSize.width, toSize.height
    local spriteContentSize = sprite:getContentSize()
    local factorW = standWidth / spriteContentSize.width
    local factorH = standHeight / spriteContentSize.height
    local factor = factorH < factorW and factorH or factorW
    return factor
end

function stretchSpriteToFillSize( sprite, fillSize )
    local originalSize = sprite:getContentSize()
    local scaleX = fillSize.width / originalSize.width
    local scaleY = fillSize.height / originalSize.height
    sprite:setScaleX( scaleX )
    sprite:setScaleY( scaleY )

    return scaleX, scaleY
end

function convertTableStrToNum (_t)
    local t = {}
    local function str2Num(i,v)
        table.insert(t, tonumber(v))
    end
    table.foreach(_t, str2Num)
    return t
end

function convertTimeToTable(_time)
    local ss = 0
    local mm = 0
    local hh = 0
    local dd = 0
    if _time > 0 then
        ss = _time%60
    end
    if _time - ss > 0 then
        mm = (_time - ss) % 3600 / 60
    end
    if _time - 60*mm - ss > 0 then
        hh = (_time - 60*mm - ss)%86400 / 3600
    end
    if _time - 3600*hh - 60*mm - ss > 0 then
        dd = (_time - 3600*hh - 60*mm - ss)/86400
    end
    --cclog("转换后的時间为:d=%d,h=%d,m=%d,s=%d",dd,hh,mm,ss)
    local time = {d=dd,h=hh,m=mm,s=ss}
    return time
end

function convertTimeElectronicWatch( _sec, _cout )
    local time = convertTimeToTable(_sec)
    if time.d > 0 then
        time.h = time.h + (24 * time.d)
    end

    if _cout == 3 then
        if time.h > 0 then
            return string.format("%02d:%02d:%02d", time.h, time.m, time.s)
        elseif time.m > 0 then
            return string.format("%02d:%02d", time.m, time.s)
        else
            return string.format("%02d", time.s)
        end
    elseif _cout == 2 then
        time.m = time.h * 60 + time.m
        if time.m > 0 then
            return string.format("%02d:%02d", time.m, time.s)
        else
            return string.format("%02d", time.s)
        end
    else
        return string.format("%02d:%02d:%02d",time.h, time.m, time.s)
    end
end

function convertTimeElectronicWatchHaveDay( _sec, _cout )
    local time = convertTimeToTable(_sec)
    --if time.d > 0 then
    --    time.h = time.h + (24 * time.d)
    --end

    if _cout == 3 then
        if time.d > 0 then
            return string.format("%d:%d:%d:%d:", time.d, time.h, time.m, time.s)
        elseif time.h > 0 then
            return string.format("%d:%d:%d", time.h, time.m, time.s)
        elseif time.m > 0 then
            return string.format("%d:%d", time.m, time.s)
        else
            return string.format("%d", time.s)
        end
    elseif _cout == 2 then
        time.m = time.h * 60 + time.m
        if time.m > 0 then
            return string.format("%d:%d", time.m, time.s)
        else
            return string.format("%d", time.s)
        end
    else
        return string.format("%d:%d:%d",time.h, time.m, time.s)
    end
end

function convertTimeElectronicWatchChinese( _sec, _cout )
    local time = convertTimeToTable(_sec)
    --if time.d > 0 then
    --    time.h = time.h + (24 * time.d)
    --end

    if _cout == 3 then
        if time.d > 0 then
            return string.format("%d:%d:%d:%d", time.d, time.h, time.m, time.s)
        elseif time.h > 0 then
            return string.format("%d:%d:%d", time.h, time.m, time.s)
        elseif time.m > 0 then
            return string.format("%d:%d", time.m, time.s)
        else
            return string.format("%d", time.s)
        end
    elseif _cout == 2 then
        time.m = time.h * 60 + time.m
        if time.m > 0 then
            return string.format("%d:%d", time.m, time.s)
        else
            return string.format("%d", time.s)
        end
    else
        return string.format("%d:%d:%d", time.h, time.m, time.s)
    end
end

function convertTimeSecondsToStr(_time)
    return convertTimeToStr(convertTimeToTable(_time))
end

--针对首充活动页面的截止時间，最后不显示秒。如果还有几秒钟，则显示为0分
function convertTimeSecondsToStrForPurchase(_time)
    return convertTimeToStrForPurchase(convertTimeToTable(_time))
end

--针对首充活动页面的截止時间，最后不显示秒。如果还有几秒钟，则显示为0分
function convertTimeToStrForPurchase(_time)
    if _time.d ~= 0 then
        if _time.h ~= 0 then
            return string.format("%d天%d小時", _time.d, _time.h)
        else
            return string.format("%d天", _time.d)
        end
    elseif _time.h ~= 0 then
        if _time.m ~= 0 then
            return string.format("%d小時%d分钟", _time.h, _time.m)
        else
            return string.format("%d小時", _time.h)
        end
    elseif _time.m ~= 0 then
        return string.format("%d分钟", _time.m)
    elseif _time.s ~= 0 then
        return string.format("0分钟")
    else
        return "0分钟"
    end
end

function convertTimeToStr(_time)
    if _time.d ~= 0 then
        if _time.h ~= 0 then
            return string.format("%d天 %d小時", _time.d, _time.h)
        else
            return string.format("%d天", _time.d)
        end
    elseif _time.h ~= 0 then
        if _time.m ~= 0 then
            return string.format("%d小時 %d分钟", _time.h, _time.m)
        else
            return string.format("%d小時", _time.h)
        end
    elseif _time.m ~= 0 then
        if _time.s ~= 0 then
            return string.format("%d分钟 %d秒", _time.m, _time.s)
        else
            return string.format("%d分钟", _time.m)
        end
    elseif _time.s ~= 0 then
        return string.format("%d秒", _time.s)
    else
        return "None"
    end
end

function convertTimeToSec(_time)
    return _time.d*86400+_time.h*3600+_time.m*60+_time.s
end

function convertSecToStr(_second, _showAll)
     local d, h, m, s
     s = math.floor(_second) % 60
     _minute = _second / 60
     if _minute < 1 then
        return string.format("%ds", s)
     end

     m = math.floor(_minute) % 60
     _hour = _minute / 60
     if _hour < 1 then
        if _showAll then
            return string.format("%dmin %s", m, s)
        elseif s >= 1 then
            return string.format("%dmin %ds", m, s)
        else
            return string.format("%dmin", m)
        end
     end

     h = math.floor(_hour) % 24
     _day = _hour / 24
     if _day < 1 then
        if _showAll then
            return string.format("%dh %dmin %ds", h, m, s)
        elseif m >= 1 then
            return string.format("%dh %dmin", h, m)
        else
            return string.format("%dh", h)
        end
     end

     d = math.floor(_day)
     if _showAll then
        return string.format("%d day %dh %dmin %ds", d, h, m, s)
     elseif h >= 1 then
        return string.format("%d day %dh", d, h)
     else
        return string.format("%d day", d)
     end
end

function convertSecToTable(_second, _showAll)
     local d, h, m, s
     local time = {}
     s = math.floor(_second) % 60
     _minute = _second / 60
     if _minute < 1 then
        time["s"] = s
        return time
     end

     m = math.floor(_minute) % 60
     _hour = _minute / 60
     if _hour < 1 then
        if _showAll then
            time["m"] = m
            time["s"] = s
            return time
        elseif s >= 1 then
            time["m"] = m
            time["s"] = s
            return time
        else
            time["m"] = m
            return time
        end
     end

     h = math.floor(_hour) % 24
     _day = _hour / 24
     if _day < 1 then
        if _showAll then
            time["h"] = h
            time["m"] = m
            time["s"] = s
            return time
        elseif m >= 1 then
            time["h"] = h
            time["m"] = m
            return time
        else
            time["h"] = h
            return time
        end
     end

     d = math.floor(_day)
     if _showAll then
        time["d"] = d
        time["h"] = h
        time["m"] = m
        time["s"] = s

        return time
     elseif h >= 1 then
        time["d"] = d
        time["h"] = h
        return time
     else
        time["d"] = d
        return time
     end
end

---检测邮箱地址是否符合规则
---符合返回true,否则false
function isEmailRegular(_address)
        local start,last ,_,_,_ = string.find(_address,"([a-zA-Z0-9_-]+)@([a-zA-Z0-9_-]+).([a-zA-Z0-9_-]+)")
        if start == 1 and last== string.len(_address) then
            return true
        else
            start,last ,_,_,_ = string.find(_address,"([a-zA-Z0-9_-]+)@([a-zA-Z0-9_-]+).([a-zA-Z0-9_-]+).[a-zA-Z]+")
            if start == 1 and last== string.len(_address) then
                return true
            else
                return false
            end
        end
end


--获取随机小数(_min ~ _max)，暂時精确到0.01
function getRanDecimal(_min, _max, _precision)
    _precision = 100
    return math.random(_min * _precision, _max * _precision) / _precision
end

function countForLongTime( _time )
    local days = math.floor((os.time() - _time)/(24 * 3600))
    local hours = math.floor((os.time() - _time)%(24 * 3600)/3600)
    if hours < 10 then
        return days.."天 "..hours.." 小時前，"
    else
        return days.."天"..hours.."小時前，"
    end
end

function parseFontString( strContent )
    local nOldTime = os.clock()
    local nPosFont = string.find(strContent, "<font")
    if nPosFont then
        local nPosColor = string.find(strContent, "#", nPosFont + 5)
        local r = tonumber("0x" .. string.sub(strContent, nPosColor + 1, nPosColor + 2))
        local g = tonumber("0x" .. string.sub(strContent, nPosColor + 3, nPosColor + 4))
        local b = tonumber("0x" .. string.sub(strContent, nPosColor + 5, nPosColor + 6))

        local nPosBegin = string.find(strContent, ">", nPosFont + 5) + 1
        --local nPosEnd = string.find(strContent, "</font>", nPosBegin + 1) - 1
        strContent = string.sub(strContent, nPosBegin)

        return strContent, ccc3(r, g, b)
    else
        return strContent, ccc3(255, 255, 255)
    end
end

function tableIsEmpty(t)
    return t == nil or _G.next( t ) == nil
end

--获取表的长度
function tableLength(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

--复制一个表
function copyTab(st)
    local tab = {}
    for k, v in pairs(st or {}) do
        if type(v) ~= "table" then
            tab[k] = v
        else
            tab[k] = copyTab(v)
        end
    end
    return tab
end

function urlencode(str)
    if (str) then
        str = string.gsub (str, "\n", "\r\n")
        str = string.gsub (str, "([^%w ])",
            function (c) return string.format ("%%%02X", string.byte(c)) end)
        str = string.gsub (str, " ", "+")
    end
    return str
end

-- 得到数字的整数部分
function getIntPart(x)
    local intPart = math.modf(x)
    return intPart
end

function getIntAndDecimal(x)
    local intPart, decimalPart = math.modf(x)
    return intPart, decimalPart
end
--打印表的内容
function printTable4Level(table, strName)
    -- body
    print(strName,"===================")
    for k,v in pairs(table) do
        print(" --",k,v)
            if type(v) == "table" then
                for m,n in pairs(v) do
                    print("  |-",m,n)
                    if type(n) == "table" then
                        for p,q in pairs(n) do
                            print("     |-",p,q)
                            if type(q) == "table" then
                                for a,b in pairs( q ) do
                                    print("         |-", a, b)
                                end
                            end
                        end
                    end
                end
            end
    end
    print("==========================")
end

--打印表的内容(3层)
function printTable3Level(table, strName)
    print(strName,"===================")
    for k,v in pairs(table) do
        print(" --",k,v)
        if type(v) == "table" then
            for m,n in pairs(v) do
                print("  |-",m,n)
                if type(n) == "table" then
                    for p,q in pairs(n) do
                        print("     |-",p,q)
                    end
                end
            end
        end
    end
    print("==========================")
end

function getAttributeIcon(attr)
	if attr == 1 then
		return "com_text_water_icon"
	elseif attr == 2 then
		return "com_text_fire_icon"
	elseif attr == 3 then
		return "com_text_wind_icon"
	elseif attr == 4 then
		return "com_text_soild_icon"
	elseif attr == 5 then
		return "com_text_thunder_icon"
	else
		return "com_text_water_icon"
	end
end

function getAttributeBigIcon(attr)
	if attr == 1 then
		return "com_text_water_big_icon"
	elseif attr == 2 then
		return "com_text_fire_big_icon"
	elseif attr == 3 then
		return "com_text_wind_big_icon"
	elseif attr == 4 then
		return "com_text_soild_big_icon"
	elseif attr == 5 then
		return "com_text_thunder_big_icon"
	else
		return "com_text_water_big_icon"
	end
end

function getAttributeSmallIcon(attr)
	if attr == 1 then
		return "Contrast lineup_watar"
	elseif attr == 2 then
		return "Contrast lineup_fire"
	elseif attr == 3 then
		return "Contrast lineup_wind"
	elseif attr == 4 then
		return "Contrast lineup_soil"
	elseif attr == 5 then
		return "Contrast lineup_thunder"
	else
		return "Contrast lineup_watar"
	end
end