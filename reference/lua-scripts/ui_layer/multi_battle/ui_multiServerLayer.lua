--descriptioin:跨服战斗
--company: xckoo
--author: chenchun
--date: 2013-02-19
---------------------------------------------
module("ui_multiServerLayer", package.seeall)
baseClass(layer_base_t, ui_multiServerLayer)

gBattleStatus = 1
GoldLabelNode = nil
function init(self)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	self.contentSize_ = GetMainMenu():GetSubContentNode():getContentSize()
	--local currentlayer = tolua.cast(GetMainMenu():GetCurrentSubMenu(), "CCLayer")
	--self.contentSize_ =currentlayer:getContentSize()

	local ccbiAttrTable = {name="multiserverbattle/multiServer.ccbi", size=self.contentSize_}
	layer_base_t.init(self, true, ccbiAttrTable)

	self.curTag = 1
	self.battleStatus = 1    --1表示活动没开始，2，表示活动在购买门票阶段，3、表示活动正在进行
	self.leftTime = 0
	--self:createTestData()
	self:init_ui()
	self:init_binding_event()

end


function init_ui(self)
	if self.proxy_ ~= nil then
		self.sprite_playermedal = tolua.cast(self.proxy_:getNode("sprite_playermedal"), "CCSprite")
		self.label_level = tolua.cast(self.proxy_:getNode("label_level"), "CCLabelBMFont")
		self.label_curexp = tolua.cast(self.proxy_:getNode("label_curexp"), "CCLabelBMFont")
		self.label_name = tolua.cast(self.proxy_:getNode("label_name"), "CCLabelTTF")
		self.sprite_vipinfo = tolua.cast(self.proxy_:getNode("sprite_vipinfo"), "CCSprite")
		self.label_bodyval = tolua.cast(self.proxy_:getNode("label_bodyval"), "CCLabelBMFont")
		self.label_attackval = tolua.cast(self.proxy_:getNode("label_attackval"), "CCLabelBMFont")
		self.label_goldval = tolua.cast(self.proxy_:getNode("label_goldval"), "CCLabelBMFont")
		self.label_silverval = tolua.cast(self.proxy_:getNode("label_silverval"), "CCLabelBMFont")
		self.ctrl_btnplayermsg = tolua.cast(self.proxy_:getNode("ctrl_btnplayermsg"), "CCControlButton")
		self.sprite_levelstate = tolua.cast(self.proxy_:getNode("sprite_levelstate"), "CCSprite")
		self.sprite_bodyratio = tolua.cast(self.proxy_:getNode("sprite_bodyratio"), "CCSprite")
		self.sprite_attackratio = tolua.cast(self.proxy_:getNode("sprite_attackratio"), "CCSprite")

		self.node_subcontent = tolua.cast(self.proxy_:getNode("node_subcontent"), "CCNode")
		self.ctrl_battle =  tolua.cast(self.proxy_:getNode("ctrl_battle"), "CCControlButton")
		self.ctrl_honour =  tolua.cast(self.proxy_:getNode("ctrl_honour"), "CCControlButton")
		self.ctrl_bingo =  tolua.cast(self.proxy_:getNode("ctrl_bingo"), "CCControlButton")
		self.ctrl_description =  tolua.cast(self.proxy_:getNode("ctrl_description"), "CCControlButton")

		self.subNodeSize = self.node_subcontent:getContentSize()

		ui_multiServerLayer.GoldLabelNode = self.label_goldval
		self:init_config_data()
		self:init_normalTopBar()

		self.ctrl_battle:setTag(1)
		self.ctrl_honour:setTag(2)
		self.ctrl_bingo:setTag(3)
		self.ctrl_description:setTag(4)

		self.ctrl_battle:setEnabled(false)
		self.btns = {[1] = self.ctrl_battle, [2] = self.ctrl_honour, [3] = self.ctrl_bingo, [4] = self.ctrl_description}
		self.modules = {[1] = ui_multiBattleBefore, [2] = ui_multiBattleRank, [3]=ui_multiBattleRank, [4]=ui_multiBattleDesc}
	end
end

--头部信息的初始化
function init_normalTopBar(self)
		local meritIcon = self.playerMgr_:GetMeritIcon()
		if meritIcon ~= nil then
			local pFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(meritIcon)
			if pFrame ~= nil then
				self.sprite_playermedal:setDisplayFrame(pFrame)
			end
		end
		--exp
		self.label_name:setString(self.playerData_.m_name)
		local nextExp = self.playerMgr_:GetNextLevelExp()
		local expStr = tostring(self.playerData_.m_exp) .. "/" .. tostring(nextExp)
		self.label_curexp:setString(expStr)
		self.sprite_levelstate:setScaleX(self.playerData_.m_exp / nextExp)

		--vipinfo
		local viplevel = self.playerData_.m_viplevel
		local vipframes={[0] = "vip_015",[1]="vip_003",[2]="vip_004",[3]="vip_005",[4]="vip_006",
			[5]="vip_007",[6]="vip_008",[7]="vip_009",[8]="vip_010",[9]="vip_011",[10]="vip_012",[11]="vip_013",[12]="vip_014", [13]="vip_s_13", [14] = "vip_s_14", [15] = "vip_s_15",[16]="vip_s_16",[17]="vip_s_17",[18]="vip_s_18"}
		if self.sprite_vipinfo ~= nil then
			local pFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(vipframes[viplevel])
			self.sprite_vipinfo:setDisplayFrame(pFrame)
		end

		--bodyval
		local maxbodyval = self.playerMgr_:GetMaxBodyValue()
		local bodyValStr = tostring(self.playerData_.m_bodyvalue) .. "/" .. tostring(maxbodyval)
		self.label_bodyval:setString(bodyValStr)
		local scaleVal = self.playerData_.m_bodyvalue / maxbodyval
		if scaleVal > 1 then
			scaleVal = 1
		end
		self.sprite_bodyratio:setScaleX(scaleVal)

		--attack
		local maxattack = self.playerMgr_:GetMaxAttackCount()
		local attackValStr = tostring(self.playerData_.m_fightcount) .. "/" .. tostring(maxattack)
		self.label_attackval:setString(attackValStr)
		self.sprite_attackratio:setScaleX(self.playerData_.m_fightcount / maxattack)

		--gold & silver
		self.label_goldval:setString(tostring(self.playerData_.m_gold))
		self.label_silverval:setString(tostring(self.playerData_.m_silver))
		self.label_level:setString(tostring(self.playerData_.m_level))
end

function init_binding_event(self)
	if self.proxy_ ~= nil then

		local function CCLayerTouch(event, x, y)
			local rect = self.node_:boundingBox()
			rect.origin = ccp(0,0)
			local p = self.node_:convertToNodeSpace(ccp(x,y))
			if event == "began" then
				if rect:containsPoint(p) == true then
					return true
				else
					return false
				end
			end
		end

		self.node_:setTouchEnabled(true)
		self.node_:registerScriptTouchHandler(CCLayerTouch, false, -1, true)

		local function open_tabs(btn)
			if btn:getTag() == 3 then
				GetMainMenu():ShowTextTip(localizable.ui_bingo_description, -1)
			elseif btn:getTag() ~= self.curTag then
				self.btns[self.curTag]:setEnabled(true)
				btn:setEnabled(false)
				self.node_subcontent:removeAllChildrenWithCleanup(true)
				local nodeLayer = nil
				if btn:getTag() == 1 then
					self:init_config_data()
				else
					nodeLayer = createObj(self.modules[btn:getTag()], self.subNodeSize, self.leftTime, self.playerInfo, self.othersPlayerInfo)
					self.node_subcontent:addChild(nodeLayer.node_)
				end
				self.curTag = btn:getTag()
			end
		end

		local function open_playermsg()
			GetMainMenu():OnShowUserInfo()
		end

		self.ctrl_battle:setTouchPriority(-2)
		self.ctrl_honour:setTouchPriority(-2)
		self.ctrl_bingo:setTouchPriority(-2)
		self.ctrl_description:setTouchPriority(-2)
		self.ctrl_btnplayermsg:setTouchPriority(-2)

		self.proxy_:handleControlEvent(self.ctrl_battle, open_tabs, CCControlEventTouchUpInside)
		self.proxy_:handleControlEvent(self.ctrl_honour, open_tabs, CCControlEventTouchUpInside)
		self.proxy_:handleControlEvent(self.ctrl_bingo, open_tabs, CCControlEventTouchUpInside)
		self.proxy_:handleControlEvent(self.ctrl_description, open_tabs, CCControlEventTouchUpInside)
		self.proxy_:handleControlEvent(self.ctrl_btnplayermsg, open_playermsg, CCControlEventTouchUpInside)
	end
end

function init_config_data(self)

	local urlpath = GetMultiBattleHeader(self.playerData_.m_uid, 0, protocol.URI_R_CWARLIST)   --不需要传CMD
	--cclog("1111-----%s", urlpath)
	GetMainMenu():ShowLoadingDlg();	-- 获取信息的时候，不允许操作
	CCHttpRequest:open(urlpath, kHttpPost,"query=param1&other=params"):sendWithHandler(
		function(res, hnd)
			GetMainMenu():CloseLoadding(); --获取信息完成时，解除禁止操作
			local resData = res:getResponseData()
			--cclog("1111-----%s", resData)
			local code = res:getResponseCode()
			local xfile = xml.parse(resData)
			local item = xfile:find("RENLONG")
			local retcode = item.code
			if retcode == "0" then
				self.leftTime = tonumber(item:find("warlefttime")[1])
				self.curWarId = tonumber(item:find("curwarid")[1])
				self.battleStatus = tonumber(item:find("status")[1])
				ui_multiServerLayer.gBattleStatus = self.battleStatus

				--解析玩家信息
				local userItem = item:find("user")
				self:playerInfoForSelf(userItem)

				--解析其他玩家信息
				local otherItem = item:find("positionlist")
				self:playerInfoForOther(otherItem)

				local nodeLayer
				if self.battleStatus == 3 then
					nodeLayer = createObj(ui_multiBattleBefore, self.subNodeSize, self.leftTime, self.playerInfo, self.othersPlayerInfo)
				elseif self.battleStatus == 1 then
					nodeLayer = createObj(ui_multiBattleBuyTicket, self.subNodeSize, self.leftTime, self.playerInfo, self.othersPlayerInfo)
				elseif self.battleStatus == 2 then
					nodeLayer = createObj(ui_multiBattling, self.subNodeSize, self.leftTime, self.playerInfo, self.othersPlayerInfo)
				end
				self.node_subcontent:addChild(nodeLayer.node_)
			else
				GetMainMenu():ShowErrorTip(tonumber(retcode), -1)
			end
		end)
end


function playerInfoForSelf(self, userItem)
	self.playerInfo = {}
	self.playerInfo.uid = userItem:find("uid")[1]
	self.playerInfo.isin = userItem:find("isin")[1]
	self.playerInfo.posid = userItem:find("posid")[1]
	self.playerInfo.pf = userItem:find("pf")[1]
	self.playerInfo.zone = userItem:find("zone")[1]
	self.playerInfo.rank = userItem:find("rank")[1]
	self.playerInfo.score = userItem:find("score")[1]
	self.playerInfo.extra = tonumber(userItem:find("extra")[1])
	self.playerInfo.extra_timeleft = tonumber(userItem:find("extra_timeleft")[1])
	self.playerInfo.keep_left = userItem:find("keep_left")[1]
	self.playerInfo.timeval = userItem:find("timeval")[1]
	self.playerInfo.addscore = userItem:find("addscore")[1]
	self.playerInfo.viplevel = userItem:find("viplevel")[1]
	self.playerInfo.playerlevel = userItem:find("playerlevel")[1]

	self.playerInfo.extra_times_lmt = tonumber(userItem:find("extra_times_lmt")[1])
	self.playerInfo.inspireList = {}
	local inspireList = userItem:find("extra_time_lefts")
	for i = 1, #inspireList do
		table.insert(self.playerInfo.inspireList, tonumber(inspireList:find("timeleft")[1]))
	end
	self.playerInfo.extra_my_times = #inspireList


	self.playerInfo.cardInfo = {}
	local cardInfo = userItem:find("card")
	self.playerInfo.cardInfo.id = cardInfo:find("id")[1]
	self.playerInfo.cardInfo.life = cardInfo:find("life")[1]
	self.playerInfo.cardInfo.strength = cardInfo:find("strength")[1]
end

function playerInfoForOther(self, otherInfo)
	self.othersPlayerInfo = {}
	for i = 1, #otherInfo do
		local tmpPlayerInfo = {}
		tmpPlayerInfo.uid = otherInfo[i]:find("uid")[1]
		tmpPlayerInfo.posid = otherInfo[i]:find("posid")[1]
		tmpPlayerInfo.pf = otherInfo[i]:find("pf")[1]
		tmpPlayerInfo.zone = otherInfo[i]:find("zone")[1]
		tmpPlayerInfo.rank = otherInfo[i]:find("rank")[1]
		tmpPlayerInfo.score = otherInfo[i]:find("score")[1]
		tmpPlayerInfo.keep_left = otherInfo[i]:find("keep_left")[1]
		tmpPlayerInfo.timeval = otherInfo[i]:find("timeval")[1]
		tmpPlayerInfo.addscore = otherInfo[i]:find("addscore")[1]
		tmpPlayerInfo.viplevel = otherInfo[i]:find("viplevel")[1]
		tmpPlayerInfo.name = otherInfo[i]:find("name")[1]
		tmpPlayerInfo.playerlevel = otherInfo[i]:find("playerlevel")[1]

		local cardInfo = otherInfo[i]:find("card")
		tmpPlayerInfo.cardInfo = {}
		tmpPlayerInfo.cardInfo.id = cardInfo:find("id")[1]
		tmpPlayerInfo.cardInfo.life = cardInfo:find("life")[1]
		tmpPlayerInfo.cardInfo.strength = cardInfo:find("strength")[1]

		table.insert(self.othersPlayerInfo, tmpPlayerInfo)
	end
end

function onNodeCleanup(self)
	if self.proxy_ then
    	self.proxy_:release()
    end
    local plistName = "ccbResources/multiserver_battle.plist"
	CCSpriteFrameCache:sharedSpriteFrameCache():removeSpriteFramesFromFile(plistName)
	local imagePath = string.format( "%s.pvr.ccz", string.sub(plistName, 1, string.len(plistName) - 6) )
	CCTextureCache:sharedTextureCache():removeTextureForKey( imagePath )
	imagePath = string.format( "%s.pvr", string.sub(plistName, 1, string.len(plistName) - 6) )
	CCTextureCache:sharedTextureCache():removeTextureForKey( imagePath )
	imagePath = string.format( "%s.png", string.sub(plistName, 1, string.len(plistName) - 6) )
	CCTextureCache:sharedTextureCache():removeTextureForKey( imagePath )
	layer_base_t.onNodeCleanup(self)
end

function createTestData(self)
	self.playerInfo = {}
	self.playerInfo.isin = "1"
	self.playerInfo.posid = "1"
	self.playerInfo.pf = "1"
	self.playerInfo.zone = "12"
	self.playerInfo.rank = "7"
	self.playerInfo.score = "20000"
	self.playerInfo.extra = 20
	self.playerInfo.extra_timeleft = 1000
	self.playerInfo.keep_left = "180"
	self.playerInfo.timeval = "90"
	self.playerInfo.addscore = "25"

	self.playerInfo.cardInfo = {}
	self.playerInfo.cardInfo.id = "4"
	self.playerInfo.cardInfo.life = "3"
	self.playerInfo.cardInfo.strength = "1"

	self.othersPlayerInfo = {}
	for i = 1, 20 do
		local tmpPlayerInfo = {}
		tmpPlayerInfo.uid =  tostring(i)
		tmpPlayerInfo.posid = tostring(i)
		tmpPlayerInfo.pf = tostring(i)
		tmpPlayerInfo.zone = tostring(i)
		tmpPlayerInfo.rank = tostring(i)
		tmpPlayerInfo.score =tostring(i)
		tmpPlayerInfo.keep_left = tostring(i * 2)
		tmpPlayerInfo.timeval = tostring(i * 2)
		tmpPlayerInfo.addscore = tostring(i * 3)
		tmpPlayerInfo.viplevel = "4"
		tmpPlayerInfo.name = "消失的影子"
		tmpPlayerInfo.playerlevel = "117"

		tmpPlayerInfo.cardInfo = {}
		tmpPlayerInfo.cardInfo.id = "4"
		tmpPlayerInfo.cardInfo.life = "2"
		tmpPlayerInfo.cardInfo.strength = "4"

		table.insert(self.othersPlayerInfo, tmpPlayerInfo)
	end
end