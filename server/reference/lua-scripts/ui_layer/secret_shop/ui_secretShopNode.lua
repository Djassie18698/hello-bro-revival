--descriptioin:神秘商店卡片節點
--company: xckoo
--author: chenchun
--date: 2014-03-12
---------------------------------------------
module("ui_secretShopNode", package.seeall)
baseClass(layer_base_t, ui_secretShopNode)

function init(self, cellSize, data, parentObj)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	self.contentSize_ = cellSize
	local ccbiAttrTable = {name="secretshop/secretShopItem.ccbi", size=self.contentSize_}
	layer_base_t.init(self, true, ccbiAttrTable)

	self.data = data
	self.parentObj = parentObj
	self:init_ui()
	self:init_binding_event()
end

function init_ui(self)
	if self.proxy_ ~= nil then

		self.sprite_card_bk = tolua.cast(self.proxy_:getNode("sprite_card_bk"), "CCSprite")
		self.sprite_exchange_font = tolua.cast(self.proxy_:getNode("sprite_exchange_font"), "CCSprite")

		self.sprite_type = tolua.cast(self.proxy_:getNode("sprite_type"), "CCSprite")
		self.label_card_name = tolua.cast(self.proxy_:getNode("label_card_name"), "CCLabelTTF")
		self.label_cost_type = tolua.cast(self.proxy_:getNode("label_cost_type"), "CCLabelTTF")
		self.label_cost_num = tolua.cast(self.proxy_:getNode("label_cost_num"), "CCLabelBMFont")
		self.ctrl_btn_exchange = tolua.cast(self.proxy_:getNode("ctrl_btn_exchange"), "CCControlButton")
		self.label_card_num = tolua.cast(self.proxy_:getNode("label_card_num"), "CCLabelBMFont")
		self.sprite_attribute = tolua.cast(self.proxy_:getNode("sprite_attribute"), "CCSprite")
		self.ctrl_show_info = tolua.cast(self.proxy_:getNode("ctrl_show_info"), "CCControlButton")

		self.sprite_cost_type = tolua.cast(self.proxy_:getNode("sprite_cost_type"), "CCSprite")

		self.cardNodeSize = self.sprite_card_bk:getContentSize()

		self.oldShaderProgram = self.sprite_exchange_font:getShaderProgram()
		self:refresh_ui()
	end
end


function init_binding_event(self)
	if self.proxy_ ~= nil then
		local function exchangeCard()
			local urlpath = GetUrlNormalHeader(self.playerData_.m_uid,  4, protocol.URL_X_MYSTERY_SHOP)
			urlpath = AddData(urlpath,"Soul", self.data.id)
			--urlpath = "http://192.168.0.236/reward1.xml"
			GetMainMenu():ShowLoadingDlg()	--获取信息的时候，不允许操作
			CCHttpRequest:open(urlpath, kHttpPost,"query=param1&other=params"):sendWithHandler(
				function(res, hnd)
					GetMainMenu():CloseLoadding() --获取信息完成时，解除禁止操作
					local resData = res:getResponseData()
					--cclog("1111---resdata:%s", resData)
					local code = res:getResponseCode()
					local xfile = xml.parse(resData)
					local item = xfile:find("RENLONG")
					local retcode = item.code
					if retcode == "0" then
						local awardXML = item:find("award")
						ShowAward(awardXML)
						self.ctrl_btn_exchange:setEnabled(false)
						local pProgram = CCShaderCache:sharedShaderCache():programForKey("greysprite")
						self.sprite_exchange_font:setShaderProgram(pProgram)
						self.data.status = "1"
						self.parentObj:update_label_soul(self.data.costtype, self.data.cost)
					else
						GetMainMenu():ShowErrorTip(tonumber(retcode), -1)
					end
				end)
			
		end
		
		local function show_info()
			if self.data.type == "5" then
				local descStr = self.data.name .. localizable.ui_secret_shop_suipian .. tostring(self.data.num)
				--CGameObjElement:ShowCommonItemDetail(tonumber(self.data.type), tonumber(self.data.subtype), tonumber(self.data.icon), descStr)
				local info = DataMgr.GetDataByID("Struct_Piece_Info", tonumber(self.data.icon))
				if info.m_piece_type == 1 then
		            CGameObjElement:ShowCommonItemDetail(1, 1, tonumber(info.m_piece_targetthingID), descStr)
		        elseif info.m_piece_type == 2 then
		            CGameObjElement:ShowCommonItemDetail(1, 2, tonumber(info.m_piece_targetthingID), descStr)
		        elseif info.m_piece_type == 3 then
		            CGameObjElement:ShowCommonItemDetail(1, 3, tonumber(info.m_piece_targetthingID), descStr)
                elseif info.m_piece_type == 5 then--宠物碎片，显示宠物详情
                    CGameObjElement:ShowCommonItemDetail(7, 5, tonumber(info.m_piece_targetthingID), descStr)
		        end    
			elseif self.data.type == "1" and self.data.subtype == "5" then
				local descStr = self.data.name .. localizable.ui_secret_shop_suipian .. tostring(self.data.num)
				CGameObjElement:ShowCommonItemDetail(tonumber(self.data.type), tonumber(self.data.subtype), tonumber(self.data.icon), descStr)
            else
				local descStr = self.data.name .. " x " .. tostring(self.data.num)
				CGameObjElement:ShowCommonItemDetail(tonumber(self.data.type), tonumber(self.data.subtype), tonumber(self.data.icon), descStr)
			end
		end

		self.ctrl_show_info:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.proxy_:handleControlEvent(self.ctrl_show_info, show_info, CCControlEventTouchUpInside)

		self.ctrl_btn_exchange:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.proxy_:handleControlEvent(self.ctrl_btn_exchange, exchangeCard, CCControlEventTouchUpInside)
		if self.data.status == "1" then		
			self.ctrl_btn_exchange:setEnabled(false)
			local pProgram = CCShaderCache:sharedShaderCache():programForKey("greysprite")
			self.sprite_exchange_font:setShaderProgram(pProgram)
		else
			self.ctrl_btn_exchange:setEnabled(true)
		end


	end
end

function update_data(self, data)
	self.data = data
	self:refresh_ui()
end

--local funtion

function refresh_ui(self)
	self.sprite_card_bk:removeAllChildrenWithCleanup(true)
	--self:getIcon()
	self.sprite_icon = nil
	self.sprite_frame = nil
	self.quality = nil
    cclog("icon id = " .. self.data.icon)
	self.sprite_icon, self.sprite_frame, self.quality = rl_get_iconsprite(self.data.type, self.data.subtype, E_FRAMETYPE_SMALL, tonumber(self.data.icon))
	if self.sprite_icon ~= nil then
		if self.sprite_frame ~= nil then
			self.sprite_card_bk:setDisplayFrame(self.sprite_frame)
		else
			self.sprite_card_bk:setDisplayFrame(CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("small_box_skill_01"))
		end
		self.sprite_icon:setPosition(self.cardNodeSize.width / 2, self.cardNodeSize.height / 2)
		self.sprite_icon:setAnchorPoint(ccp(0.5, 0.5))
		self.sprite_card_bk:addChild(self.sprite_icon)
		local iconsize = self.sprite_icon:getContentSize()
		local scalex = 83 / iconsize.width
		local scaley = 83 / iconsize.height
		if scalex > scaley then
			self.sprite_icon:setScale(scaley)
		else
			self.sprite_icon:setScale(scalex)
		end
	end
	if self.data.type == "5" then
		self.sprite_type:setVisible(true)
	elseif self.data.type == "1" and self.data.subtype == "5" then
		self.sprite_type:setVisible(true)
	else
		self.sprite_type:setVisible(false)
	end

	self.label_card_num:setString(self.data.num)

	self.label_cost_num:setString(self.data.cost)
	self.sprite_attribute:setVisible(true)
	if self.data.attacktype == "1" then
		self.sprite_attribute:setDisplayFrame(CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("com_text_fight_icon"))
	elseif self.data.attacktype == "2" then
		self.sprite_attribute:setDisplayFrame(CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("com_text_defense_icon"))
	elseif self.data.attacktype == "3" then
		self.sprite_attribute:setDisplayFrame(CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("com_text_god_small_icon"))
	else
		self.sprite_attribute:setVisible(false)
	end

	self.label_card_name:setString(self.data.name)
	if not self.quality then
		self.label_card_name:setColor(quality_color_config[1])
	else
		self.label_card_name:setColor(quality_color_config[self.quality])
	end 
	
	if self.data.costtype == "1" then
		self.label_cost_type:setString(localizable.ui_secret_shop_soul)
		self.sprite_cost_type:setDisplayFrame(CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("com_soul_icon"))
	else
		self.label_cost_type:setString(localizable.ui_secret_shop_gold)
		self.sprite_cost_type:setDisplayFrame(CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("com_gold_icon"))
	end

	if self.data.status == "1" then	
		self.ctrl_btn_exchange:setEnabled(false)
		local pProgram = CCShaderCache:sharedShaderCache():programForKey("greysprite")
		self.sprite_exchange_font:setShaderProgram(pProgram)
	else
		self.sprite_exchange_font:setShaderProgram(self.oldShaderProgram)
		self.ctrl_btn_exchange:setEnabled(true)
	end
end

function onNodeCleanup(self)
	if self.proxy_ then
    	self.proxy_:release()
    end
    layer_base_t.onNodeCleanup(self)
end
