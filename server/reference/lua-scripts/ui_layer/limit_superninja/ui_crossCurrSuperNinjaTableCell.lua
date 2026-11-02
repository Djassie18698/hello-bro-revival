--Description:跨服限时神将活动本期超忍TableCell
--Company:XCKOO
--Author:litao
--Creation Date:2014-08-25
-----------------------------------------------------
module("ui_crossCurrSuperNinjaTableCell", package.seeall)
baseClass(layer_base_t, ui_crossCurrSuperNinjaTableCell)

function init(self, cellSize, data)
	local ccbiAttrTable = {name = "activity/LimitCurrSuperNinjaCellForCross.ccbi", size = cellSize}
	layer_base_t.init(self, true, ccbiAttrTable)  --加载ccbi
	self.ninja_data = data  --获取cell数据
	self:init_ui()  --初始化UI
end

function init_ui(self)
	if self.proxy_ ~= nil then
		--获取忍者信息
		self.ninjaIcon = nil
		self.ninjaFrame = nil
		self.quality = nil
		self.ninjaIcon, self.ninjaFrame, self.quality = rl_get_iconsprite("1", "1", E_FRAMETYPE_MIDDLE, self.ninja_data.ninjaid)

		if self.ninjaIcon ~= nil then
			self.ninja_attr        = tolua.cast(self.proxy_:getNode("ninja_attr"), "CCSprite")
			self.node_ninja        = tolua.cast(self.proxy_:getNode("node_ninja"), "CCSprite")

			for i = 1, 5 do
				self["sprite_star" .. tostring(i)] = tolua.cast(self.proxy_:getNode("sprite_star" .. tostring(i)), "CCSprite")
				self["sprite_star" .. tostring(i)]:setVisible(false)
			end

			self.ninjaFrame = rl_get_ninjaFrame(E_FRAMETYPE_MIDDLE, self.quality)
			if self.ninjaFrame ~= nil then
				self.node_ninja:setDisplayFrame(self.ninjaFrame)
			end

			local size = self.node_ninja:getContentSize()
			self.ninjaIcon:setPosition(size.width/2, size.height/2)
			self.ninjaIcon:setScale(0.6)
			self.node_ninja:addChild(self.ninjaIcon)

			if self.ninja_data.attr == 1 then--攻
				self.attrStr = "com_text_attack_small_icon"
			elseif self.ninja_data.attr == 2 then--防
				self.attrStr = "com_text_defense_small_icon"
			elseif self.ninja_data.attr == 3 then--神
				self.attrStr = "com_text_god_small_icon"
			end
			local pFrameNinjaAttr = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(tostring(self.attrStr))
			self.ninja_attr:setDisplayFrame(pFrameNinjaAttr)

			if self.quality > 5 then
				self.quality = 5
			end
			for i=1,self.quality do
				self["sprite_star" .. tostring(i)]:setVisible(true)
			end
		end
	end
end