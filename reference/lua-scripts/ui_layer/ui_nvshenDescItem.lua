--description: 女神献花说明，表格CELL
--company：xckoo
--author：chenchun
---------------------------------------------
module("ui_nvshenDescItem", package.seeall)
baseClass(layer_base_t, ui_nvshenDescItem)

function init(self, cellSize, data, title_color)
	local ccbiAttrTable = {name="activity/NvShenDescItem.ccbi", size=cellSize}
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()
	layer_base_t.init(self, true, ccbiAttrTable)
	self.gift_data = data
	self.title_color = title_color
	self:init_ui()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		for i = 1, 3 do
			self["sprite_item" .. tostring(i)] = tolua.cast(self.proxy_:getNode("sprite_item" .. tostring(i)), "CCSprite")
			self["label_item_name" .. tostring(i)] = tolua.cast(self.proxy_:getNode("label_item_name" .. tostring(i)), "CCLabelTTF")
			self["ctrl_gift_" .. tostring(i)] = tolua.cast(self.proxy_:getNode("ctrl_gift_" .. tostring(i)), "CCControlButton")
			--转生标志_litao_2014.8.2
			self["spr_frame_corner1_"..tostring(i)] = tolua.cast(self.proxy_:getNode("spr_frame_corner1_" .. tostring(i)), "CCSprite")
			self["spr_frame_corner2_"..tostring(i)] = tolua.cast(self.proxy_:getNode("spr_frame_corner2_" .. tostring(i)), "CCSprite")
		end

		self.label_item_title = tolua.cast(self.proxy_:getNode("label_item_title"), "CCLabelTTF")
		self.label_item_title:setString(self.title_color.title)
		self.label_item_title:setColor(self.title_color.color)
		self.label_get_title = tolua.cast(self.proxy_:getNode("label_get_title"), "CCLabelTTF")
		--self.ctrl_get_gift = tolua.cast(self.proxy_:getNode("ctrl_get_gift"), "CCControlButton")
		
		local index = 1
		for k, v in pairs(self.gift_data) do
			self["ctrl_gift_" .. tostring(index)]:setTag(tonumber(v.id))
			self["sprite_item" .. tostring(index)]:setDisplayFrame(CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("small_box_skill_0" .. v.color))

			CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile(v.folder .. "/" .. v.icon .. ".plist")
			local sprite_icon = CCSprite:createWithSpriteFrameName(v.icon)
			local contentSize = self["sprite_item" .. tostring(index)]:getContentSize()
			sprite_icon:setPosition(contentSize.width / 2, contentSize.height / 2)
			sprite_icon:setAnchorPoint(ccp(0.5, 0.5))
			self["sprite_item" .. tostring(index)]:addChild(sprite_icon)
			self["label_item_name" .. tostring(index)]:setString(v.desc)
			self["label_item_name" .. tostring(index)]:setVisible(true)
			self["label_item_name" .. tostring(index)]:setColor(self.title_color.color)

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
		for i=1,3 do
			if i > #self.gift_data then
				self["spr_frame_corner1_"..tostring(i)]:setVisible(false)
				self["spr_frame_corner2_"..tostring(i)]:setVisible(false)
			end
		end

		local function btn_show_gift(btn)
			local index = btn:getTag()
			CGameObjElement:ShowDropByID(index)
		end

		for k = 1, #self.gift_data do
			self["ctrl_gift_" .. tostring(k)]:setTouchPriority(-3)
			self.proxy_:handleControlEvent(self["ctrl_gift_" .. tostring(k)], btn_show_gift, CCControlEventTouchUpInside)
		end
		
	end
end