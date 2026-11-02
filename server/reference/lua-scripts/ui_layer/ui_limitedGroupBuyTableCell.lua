--[[
Description:全服限时限量团购活动TableCell
Company:XCKOO
Author:gongsun
Creation Date:2014/1/9
]]
module("ui_limitedGroupBuyTableCell", package.seeall)
baseClass(layer_base_t, ui_limitedGroupBuyTableCell)

function init(self, cellSize, data)
	local ccbiAttrTable = {name = "activity/LimitedGroupBuyItem.ccbi", size = cellSize}
	--获取用户信息
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()
	layer_base_t.init(self, true, ccbiAttrTable)  --加载ccbi
	self.gift_data = data  --获取cell数据
	self:init_ui()  --初始化UI
end

function init_ui(self)
	if self.proxy_ ~= nil then
		local pFrameNoGiftBK = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("small_no_obj_frame")
		local pFrameHasGiftBk = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("small_box_skill_05")
		for i = 1, 4 do  --获取4个item的信息
			self["sprite_item" .. tostring(i)] = tolua.cast(self.proxy_:getNode("sprite_item" .. tostring(i)), "CCSprite")
			self["label_item_name" .. tostring(i)] = tolua.cast(self.proxy_:getNode("label_item_name" .. tostring(i)), "CCLabelTTF")
			self["sprite_item" .. tostring(i)]:setDisplayFrame(pFrameNoGiftBK)
			self["label_item_name" .. tostring(i)]:setVisible(false)
			--转生标志_litao_2014.8.2
			self["spr_frame_corner1_"..tostring(i)] = tolua.cast(self.proxy_:getNode("spr_frame_corner1_" .. tostring(i)), "CCSprite")
			self["spr_frame_corner2_"..tostring(i)] = tolua.cast(self.proxy_:getNode("spr_frame_corner2_" .. tostring(i)), "CCSprite")
		end
		self.btn_scale_sprite = tolua.cast(self.proxy_:getNode("btn_scale_sprite"), "CCScale9Sprite")  --购买按钮
		self.btn_scale_sprite2 = tolua.cast(self.proxy_:getNode("btn_scale_sprite2"), "CCScale9Sprite")  --购买按钮按下
		self.label_rest_amount = tolua.cast(self.proxy_:getNode("label_rest_amount"), "CCLabelBMFont")  --剩余数量
		self.label_rest_amount:setString(self.gift_data.restnum)
		self.label_price = tolua.cast(self.proxy_:getNode("label_price"), "CCLabelBMFont")  --售价
		self.label_price:setString(self.gift_data.cost)
		--litao_2014.6.3_限量礼包原价
		self.label_origincost = tolua.cast(self.proxy_:getNode("label_original_price"), "CCLabelBMFont")
		self.label_origincost:setString(self.gift_data.origincost)
		--litao_2014.6.3_红线
		self.spr_red_line = tolua.cast(self.proxy_:getNode("spr_red_line"), "CCSprite")
		self.spr_red_line:setScaleX(0.9)

		if self.gift_data.status == 2 then  --已经售完、还未开始、结束等，无法购买
			local program = CCShaderCache:sharedShaderCache():programForKey("greysprite")
			if program ~= nil then
				self.btn_scale_sprite:setShaderProgram(program)
			end
		else  --可以购买
			local program = CCShaderCache:sharedShaderCache():programForKey("ShaderPositionTextureColor")
			if program ~= nil then
				self.btn_scale_sprite:setShaderProgram(program)
			end
		end

		local index = 1
		for k, v in pairs(self.gift_data.gift) do  --显示每个Cell中的gift内容
			--边框按照品质来litao_2014.6.21
			local _t_card = {}
			local _maintype = 0
			local _subtype = 0
			local _id = -1
			_maintype, _subtype, _id = setObjTypeInfo(v.dropid)
			_t_card.pIcon, _t_card.pFrame = rl_get_iconsprite(_maintype, _subtype, E_FRAMETYPE_SMALL, _id)
			--frame
			if nil ~= _t_card.pFrame then
				self["sprite_item"..tostring(index)]:setDisplayFrame(_t_card.pFrame)
			end
			--self["sprite_item" .. tostring(index)]:setDisplayFrame(pFrameHasGiftBk)
			CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile("props/" .. v.icon .. ".plist")
			local sprite_icon = CCSprite:createWithSpriteFrameName(v.icon)
			local contentSize = self["sprite_item" .. tostring(index)]:getContentSize()
			sprite_icon:setPosition(contentSize.width / 2, contentSize.height / 2)
			sprite_icon:setAnchorPoint(ccp(0.5, 0.5))
			self["sprite_item" .. tostring(index)]:addChild(sprite_icon)
			self["label_item_name" .. tostring(index)]:setString(v.name)
			self["label_item_name" .. tostring(index)]:setVisible(true)
			--增加转生等级_litao_2014.8.2
			if v.newlife > 0 then
				self["spr_frame_corner1_"..tostring(index)]:setVisible(true)
				self["spr_frame_corner2_"..tostring(index)]:setVisible(true)
				local topinlayframe = CGameObjElement:GetTopInlayFrame(E_FRAMETYPE_SMALL, v.newlife)
				if topinlayframe ~= nil then
					self["spr_frame_corner1_"..tostring(index)]:setDisplayFrame(topinlayframe)
				end

				local downinlayframe = CGameObjElement:GetDownInlayFrame(E_FRAMETYPE_SMALL, v.newlife)
				if downinlayframe ~= nil then
					self["spr_frame_corner2_"..tostring(index)]:setDisplayFrame(downinlayframe)
				end
			else
				self["spr_frame_corner1_"..tostring(index)]:setVisible(false)
				self["spr_frame_corner2_"..tostring(index)]:setVisible(false)		
			end
			index = index + 1
		end

		--隐藏没有物品的节点框转生标志_litao_2014.8.2
		for i=1,4 do
			if i > #self.gift_data.gift then
				self["spr_frame_corner1_"..tostring(i)]:setVisible(false)
				self["spr_frame_corner2_"..tostring(i)]:setVisible(false)
			end
		end
	end
end

function itemClick(self, touchPoint)
	for i=1,#self.gift_data.gift do
		local rect = self["sprite_item" .. tostring(i)]:boundingBox()
		if rect:containsPoint(touchPoint) then
			--掉落详情优化litao_2014.6.21
			CGameObjElement:ShowDropByID(self.gift_data.gift[i].dropid)
			break
			--[[
			local dlg = CommonDialogView.create()
			CommonDialogView.m_selfview = dlg;
			dlg:SetTitle(localizable.ui_limit_title)
			dlg:SetDescription(self.gift_data.gift[i].name)
			dlg:loadCCBI();
			dlg:initUI()
			GetMainMenu():GetModelLayer():AddDialog(dlg, 3);
			--]]
		end
	end
end

function btn_buy(self)
	--litao_限制刷小号_等级限制_2014.6.24
	local _playerData_ = CPlayerDataMgr:instance():GetPlayerInfoData()
	--get info from table_bin
	local config_info_level = DataMgr.GetDataByID("Struct_Functionconfig", 19)
	--判断等级
	if nil ~= config_info_level then 
	    if _playerData_.m_level < tonumber(config_info_level.m_needlevel) then
			GetMainMenu():ShowTextTip(tostring(config_info_level.m_tipinfo), -1)
			return nil
		end
	end
	CSoundMgr:instance():PlayEffect(SOUND_BUTTON)
	if self.gift_data.status == 1 then
		local id = self.gift_data.id
		local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 8, protocol.URI_R_LIMIT_BUY)
				urlpath = AddData(urlpath, "LimitPackID", id)
				--cclog("1111----%s", urlpath)
				GetMainMenu():ShowLoadingDlg()	-- 获取信息的时候，不允许操作
				CCHttpRequest:open(urlpath, kHttpPost,"query=param1&other=params"):sendWithHandler(
					function(res, hnd)
						GetMainMenu():CloseLoadding(); --获取信息完成时，解除禁止操作
						local resData = res:getResponseData()
						local code = res:getResponseCode()
						local xfile = xml.parse(resData)
						local item = xfile:find("RENLONG")
						local retcode = item.code
						if retcode == "0" then
							local preview = xfile:find("preview")
							if preview then
								self.gift_data.restnum = preview.restnum
								self.label_rest_amount:setString(preview.restnum)
								if preview.restnum == "0" then
									self.gift_data.status = 2
									local program = CCShaderCache:sharedShaderCache():programForKey("greysprite")
									if program ~= nil then
										self.btn_scale_sprite:setShaderProgram(program)
									end
								end
							end
							local awardXML = xfile:find("award")
							ShowAward(awardXML)
							GetMainMenu():ShowTextTip(localizable.ui_growth_tips8,-1)
						else
							GetMainMenu():ShowErrorTip(retcode,-1)
						end
					end)
	end
end