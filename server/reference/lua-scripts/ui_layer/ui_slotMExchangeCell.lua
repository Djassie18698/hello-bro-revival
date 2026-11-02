----------------------------------------------------------------------
--  Copyright (c) 2014-2016, XCKOO. All Rights Reserved.
--  Author :Tango
--  Time   :2015/7/2 20:51:38
--  Remark :老虎机兑换
----------------------------------------------------------------------
module("ui_slotMExchangeCell", package.seeall)
baseClass(layer_base_t, ui_slotMExchangeCell)

function init(self, cellSize, data,parent)
	local ccbiAttrTable = { name = "activity/SlotMExchangeCell.ccbi", size = cellSize }
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()
	layer_base_t.init(self, true, ccbiAttrTable)

	self.cellData = data
	self:init_ui()
	self:init_binding_event()
	self.parent = parent
end

function init_ui(self)
	if self.proxy_ ~= nil then
		-- label
		self.label_item_title = tolua.cast(self.proxy_:getNode("label_item_title"), "CCLabelTTF")

		for i = 1, 4 do
			self["btn_item_" .. i] = tolua.cast(self.proxy_:getNode("btn_item_" .. i), "CCControlButton")
			self["sprite_item" .. i] = tolua.cast(self.proxy_:getNode("sprite_item" .. i), "CCSprite")
		end

		self.btnGet = tolua.cast(self.proxy_:getNode("btn_get"), "CCControlButton")
		self.labelGet = tolua.cast(self.proxy_:getNode("label_get"), "CCLabelTTF")
		self.sprHasGot = tolua.cast(self.proxy_:getNode("sprite_hasgot"), "CCSprite")

		-- show info
		self:showInfo()
	end
end

--
function showInfo(self)
	self.label_item_title:setString(localizable.ui_slotExchange_text1 .. self.cellData.score)
	--1 可领取
	--2 无奖励
	--3 已领取
	local state = tonumber(self.cellData.status)
	self.btnGet:setVisible(true)
	if 1 == state then
		setBtnEnabled(self.btnGet,true)
		self.labelGet:setVisible(true)
		self.sprHasGot:setVisible(false)
	elseif 2 == state then
		setBtnEnabled(self.btnGet,false)
		self.labelGet:setVisible(true)
		self.sprHasGot:setVisible(false)
	elseif 3 == state then
		setBtnEnabled(self.btnGet,true)
		self.labelGet:setVisible(false)
		self.sprHasGot:setVisible(true)
		self.btnGet:setVisible(false)
	end

	--- [[
	for i = 1, 4 do
		local _icon = self["sprite_item" .. tostring(i)]:getChildByTag(99)
		if _icon then
			_icon:removeFromParentAndCleanup(true)
		end

		if self.cellData['drop' .. i] ~= '0' then
			-- icon/frame
			local _maintype = 0
			local _subtype = 0
			local _id = -1
			local _num = -1
			local _drop_type = 0
			local _obj_info = { }
			_maintype, _subtype, _id, _num, _drop_type = setObjTypeInfo(tonumber(self.cellData['drop' .. i]))
			_obj_info.pIcon, _obj_info.pFrame, _obj_info.quality, _obj_info.objname = rl_get_iconsprite(_maintype, _subtype, E_FRAMETYPE_SMALL, _id)
			if nil ~= _obj_info.pFrame then
				self["sprite_item" .. tostring(i)]:setDisplayFrame(_obj_info.pFrame)
			end
			-- 合集icon用发过来的,防止集合出现问题
			if _drop_type == 1 then
				local pathName = "props/" .. self.cellData['icon' .. i] .. ".plist"
				CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile(pathName)
				local frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(self.cellData['icon' .. i])
				if frame ~= nil then
					_obj_info.pIcon = CCSprite:createWithSpriteFrame(frame)
				end
			end
			if nil ~= _obj_info.pIcon then
				self["sprite_item" .. tostring(i)]:addChild(_obj_info.pIcon)
				local size = self["sprite_item" .. tostring(i)]:getContentSize()
				_obj_info.pIcon:setPosition(ccp(size.width * 0.5, size.height * 0.5))
				_obj_info.pIcon:setAnchorPoint(ccp(0.5, 0.5))
				_obj_info.pIcon:setTag(99)
				if _drop_type ~= 1 then
					_obj_info.pIcon:setScale(0.9)
				end
			end

		else
			local pFrameNoGiftBK = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("small_no_obj_frame")
			self["sprite_item" .. tostring(i)]:setDisplayFrame(pFrameNoGiftBK)
		end
	end
	-- ]]
end

function init_binding_event(self)
	 self.btnGet:setTouchPriority(kCCMenuHandlerPriority-2)
	 self.proxy_:handleButtonEvent(self.btnGet,function(button, event)
	 	if '1' == self.cellData.status then
	 		self:requestExchange()
	 	end
	 	return nil
	 end , CCControlEventTouchUpInside)
end

function requestExchange(self)
	local id = tonumber(self.cellData.id)

	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 25, "rl_w_comm")
	urlpath = AddData(urlpath, "ID", id)
	GetMainMenu():ShowLoadingDlg()
	CCHttpRequest:open(urlpath, kHttpPost, "query=param1&other=params"):sendWithHandler(
	function(res, hnd)
		GetMainMenu():CloseLoadding();
		local resData = res:getResponseData()
		local code = res:getResponseCode()
		local xfile = xml.parse(resData)
		local item = xfile:find("RENLONG")
		if item == nil then
			-- cclog("CGI : rl_r_comm is down!")
			return nil
		end
		local retcode = item.code
		if retcode == "0" then
			local awardXML = item:find("award")
			-- 只加入背包/显示掉落动画	
			ShowAward(awardXML)

			if self.parent then
				self.parent:onExchangeSuc()
			end

		elseif retcode == '600002' then
			GetMainMenu():ShowTextTip(localizable.ui_slotExchange_text4, -1)
		else
			GetMainMenu():ShowErrorTip(tonumber(retcode), -1)
		end
	end )
end

function onNodeCleanup(self)
	--- [[
	if self.proxy_ then
		self.proxy_:release()
		self.proxy_ = nil
	end
	-- ]]
	layer_base_t.onNodeCleanup(self)
end