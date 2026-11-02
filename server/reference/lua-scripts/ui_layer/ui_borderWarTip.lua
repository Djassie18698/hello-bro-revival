--边界碑_公告
--litao
--2014.2.15
---------------------------------------------
require "LuaSubView.lua"
require "RLRequest"
require "LuaXml.lua"
require "ui_layer/ui_marqueeShowTip"

--公告信息
m_noticeDatas = {}
--跑马灯信息
m_marqueeDatas = {}

--弹出一条公告信息
function showNoticeTip()
	--只有挑衅才提示
	if #m_noticeDatas < 1 then
		return nil
	end

	local tipLayer = createObj(ui_borderWarShowTip, m_noticeDatas)
	local size1 = GetMainMenu():GetModelLayer():getContentSize()
	tipLayer.node_:setAnchorPoint(ccp(0.5, 0.5))

	tipLayer.node_:setPosition(ccp(size1.width / 2, size1.height * 0.65))
	GetMainMenu():GetModelLayer():addChild(tipLayer.node_)
end 

function showMarqueeTip()
	--跑马灯信息
	if #m_marqueeDatas < 1 then
		return nil
	end

	local tipLayer = createObj(ui_marqueeShowTip, m_marqueeDatas)
	---[[
	local size1 = GetMainMenu():GetModelLayer():getContentSize()
	tipLayer.node_:setAnchorPoint(ccp(0.5, 0.5))

	tipLayer.node_:setPosition(ccp(size1.width / 2, size1.height * 0.65))
	if nil ~= GetMainMenu():GetModelLayer():getChildByTag(168) then
		GetMainMenu():GetModelLayer():removeChildByTag(168, true)	
	end
	GetMainMenu():GetModelLayer():addChild(tipLayer.node_, 3, 168)
	--]]
end

--请求边界碑公告信息
function startRequestNoticeInfo()
	local levellimit = DataMgr.GetDataByID("Struct_Functionconfig",11).m_needlevel;
	
	local playerMgr_ = CPlayerDataMgr:instance()
	local playerData_ = playerMgr_:GetPlayerInfoData()
	
	if playerData_.m_level < tonumber(levellimit) then
		return;
	end
	
	local urlpath = GetUrlNormalHeader(playerData_.m_uid, 2, "rl_r_frontiers_war_info")
	urlpath = AddData(urlpath, "Country", playerData_.m_countrytype)

	--cclog("borderWarNoticeInfo----%s", urlpath)
	CCHttpRequest:open(urlpath, kHttpPost, "query=param1&other=params"):sendWithHandler(
		function(res, hnd)
			local resData = res:getResponseData()
			local code = res:getResponseCode()
			local xfile = xml.parse(resData)
			local item = xfile:find("RENLONG")
			if item == nil then
				--cclog("CGI : rl_r_frontiers_war_info is down!")
				return nil
			end
			--cclog("rl_r_frontiers_war_info...报文!%s", resData)
			local retcode = item.code
			if retcode == "0" then
				m_noticeDatas = {}
				local notice_list = item:find("notice")
				if #notice_list > 0 then
					for i = 1, #notice_list do
						local msg_item = {}
						msg_item.countryId = notice_list[i].my_country
						msg_item.nameText = notice_list[i].my_nick
						msg_item.status = notice_list[i].status
						msg_item.toNameText = notice_list[i].enemy_nick
						msg_item.toCountryId = notice_list[i].enemy_country
						--litao_2014.6.3_是否是边境信息
						msg_item.isBorderWar = true
						table.insert(m_noticeDatas, msg_item)
					end	
				end
				--显示公告
				showNoticeTip()
			end
		end)
end

--请求跑马灯公告信息
function startRequestMarqueeNoticeInfo()	
	local playerMgr_ = CPlayerDataMgr:instance()
	local playerData_ = playerMgr_:GetPlayerInfoData()
	
	local urlpath = GetUrlNormalHeader(playerData_.m_uid, 1, "rl_r_marquee")
	--litao_2014.6.3_增加一个msgid
	local _msgId = 0
	local userData = readActivityData(playerData_.m_uid)
	if userData then
		for i=1,#userData do
			if userData[i].actid == activity_config.activityTipConfig.maxMsgId then
				_msgId = tonumber(userData[i].period)
				break
			end
		end
	end	
	--msgId
	urlpath = AddData(urlpath, "MsgID", _msgId)

	--cclog("marqueeNoticeInfo----%s", urlpath)
	CCHttpRequest:open(urlpath, kHttpPost, "query=param1&other=params"):sendWithHandler(
		function(res, hnd)
			local resData = res:getResponseData()
			local code = res:getResponseCode()
			local xfile = xml.parse(resData)
			local item = xfile:find("RENLONG")
			if item == nil then
				--cclog("CGI : marqueeNoticeInfo is down!")
				return nil
			end
			--cclog("marqueeNoticeInfo...报文!%s", resData)
			local retcode = item.code
			if retcode == "0" then
				m_marqueeDatas = {}
				--litao_2014.6.3跑马灯信息
				local marquee_list = item:find("marquee")
				local maxMsgId = 0
				if #marquee_list > 0 then
					for i = 1, #marquee_list do
						local msg_item = {}
						if tonumber(marquee_list[i].id) > maxMsgId then
							maxMsgId = tonumber(marquee_list[i].id)
							cclog("marquee_list[i].id = %s", tonumber(marquee_list[i].id))
						end
						msg_item.type = tonumber(marquee_list[i].type)
						msg_item.arg1 = marquee_list[i].arg1
						if marquee_list[i].arg2 then
							msg_item.arg2 = marquee_list[i].arg2
						end
						if marquee_list[i].arg3 then
							msg_item.arg3 = marquee_list[i].arg3
						end
						msg_item.isBorderWar = false
						table.insert(m_marqueeDatas, msg_item)
					end	
				end
				--将队列里面最大的msgid存储进xml
				if maxMsgId > _msgId then
					writeActivityData(playerData_.m_uid, activity_config.activityTipConfig.maxMsgId, maxMsgId)
				end
				--显示跑马灯信息
				showMarqueeTip()
			end
		end)
end

startRequestNoticeInfo()
startRequestMarqueeNoticeInfo()