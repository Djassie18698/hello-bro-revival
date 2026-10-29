--description: 活动表格的tablecell
--company：xckoo
--author：chenchun
--date：2013-12-24
---------------------------------------------

module("ui_activityPopupTableCell", package.seeall)
baseClass(layer_base_t, ui_activityPopupTableCell)

ispopup = false

function init(self, cellSize, data)
	local ccbiAttrTable = {name="activity/ActivityPopupItem.ccbi", size=cellSize}
	layer_base_t.init(self, true, ccbiAttrTable)

	self.activity_data = data
	self:init_ui()
end

function init_ui(self)
	if self.proxy_ ~= nil then

		local function onBtnActivity(btn, event)
			if not ui_activityPopupTableCell.ispopup then
				ui_activityPopupTableCell.ispopup = true
				local id = btn:getTag()
				GetMainMenu():ChangeToActivity(self.activity_data[id].name)
			end
		end
		for i = 1, #self.activity_data do
			self["node_content_" .. tostring(i)] =  tolua.cast(self.proxy_:getNode("node_content_" .. tostring(i)), "CCNode")
			self["sprite_new_" .. tostring(i)] =  tolua.cast(self.proxy_:getNode("sprite_new_" .. tostring(i)), "CCSprite")
			self["sprite_hot_" .. tostring(i)] =  tolua.cast(self.proxy_:getNode("sprite_hot_" .. tostring(i)), "CCSprite")
			self["sprite_activity_frame_" .. tostring(i)] =  tolua.cast(self.proxy_:getNode("sprite_activity_frame_" .. tostring(i)), "CCSprite")
			self["label_activity_news_" .. tostring(i)] =  tolua.cast(self.proxy_:getNode("label_activity_news_" .. tostring(i)), "CCLabelBMFont")
			self["sprite_notify_" .. tostring(i)] =  tolua.cast(self.proxy_:getNode("sprite_notify_" .. tostring(i)), "CCSprite")
			self["sprite_activity_" .. tostring(i)] = tolua.cast(self.proxy_:getNode("sprite_activity_" .. tostring(i)), "CCSprite")
			self["node_content_" .. tostring(i)]:setVisible(true)
			self["sprite_activity_bg_" .. tostring(i)] =  tolua.cast(self.proxy_:getNode("sprite_activity_bg_" .. tostring(i)), "CCScale9Sprite")

			--2014.1.3
			--CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile("ccbResources/activity_btns.plist")
			--cclog("1111----%s", self.activity_data[i].icon)
			CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile("ccbResources/activity_btns.plist")
			CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile("ccbResources/activity_btns_2.plist")
			CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile("ccbResources/activity_btns_3.plist")
			local pFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(self.activity_data[i].icon)
			self["sprite_activity_" .. tostring(i)]:setDisplayFrame(pFrame)

			if self.activity_data[i].status == 1 then
				self["sprite_new_" .. tostring(i)]:setVisible(false)
				self["sprite_hot_" .. tostring(i)]:setVisible(true)
				self["sprite_activity_frame_" .. tostring(i)]:setVisible(false)
				self["label_activity_news_" .. tostring(i)]:setVisible(false)
				self["sprite_notify_" .. tostring(i)]:setVisible(false)
			elseif self.activity_data[i].status == 2 then
				self["sprite_new_" .. tostring(i)]:setVisible(true)
				self["sprite_hot_" .. tostring(i)]:setVisible(false)
				self["sprite_activity_frame_" .. tostring(i)]:setVisible(false)
				self["label_activity_news_" .. tostring(i)]:setVisible(false)
				self["sprite_notify_" .. tostring(i)]:setVisible(false)
			elseif self.activity_data[i].newscount <= 0 and self.activity_data[i].status == 0 then
				self["sprite_new_" .. tostring(i)]:setVisible(false)
				self["sprite_hot_" .. tostring(i)]:setVisible(false)
				self["sprite_activity_frame_" .. tostring(i)]:setVisible(false)
				self["label_activity_news_" .. tostring(i)]:setVisible(false)
				self["sprite_notify_" .. tostring(i)]:setVisible(false)
			elseif self.activity_data[i].newscount > 0 and self.activity_data[i].status == 0 then
				self["sprite_new_" .. tostring(i)]:setVisible(false)
				self["sprite_hot_" .. tostring(i)]:setVisible(false)
				self["sprite_activity_frame_" .. tostring(i)]:setVisible(false)
				self["label_activity_news_" .. tostring(i)]:setVisible(false)
				self["sprite_notify_" .. tostring(i)]:setVisible(true)
				--updated by gongsun 2014.4.12 小红点提示
				--[[
				self["sprite_activity_frame_" .. tostring(i)]:setVisible(true)
				self["label_activity_news_" .. tostring(i)]:setVisible(true)
				self["label_activity_news_" .. tostring(i)]:setString(tostring(self.activity_data[i].newscount))
				--]]
			end
		end
	end
end

function onNodeCleanup(self)
    --cclog("onNodeCleanup")
    --[[
    if self.node_:retainCount() == 1 then
        self.proxy_:release()
    end
    ]]
    if self.proxy_ ~= nil then
        self.proxy_:release()
        self.proxy_ = nil
    end
    layer_base_t.onNodeCleanup(self)
end

function btn_change_to_sub(self, index)
	if self.activity_data[index] then
		local defaultMenu = tolua.cast(GetMainMenu():GetCurrentSubMenu(), "CDefaultMainMenu")
		if defaultMenu ~= nil then
			defaultMenu:onStepNext()
		end
		
		GetMainMenu():ChangeToActivity(self.activity_data[index].name)
	end
end