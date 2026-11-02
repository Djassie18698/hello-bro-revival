--descriptioin:煉化結果界面
--company: xckoo
--author: chenchun
--date: 2014-3-17
---------------------------------------------
module("ui_trainResultLayer", package.seeall)
baseClass(layer_base_t, ui_trainResultLayer)

function init(self, data)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	self.contentSize_ = CCDirector:sharedDirector():getWinSize()
	local ccbiAttrTable = {name="secretshop/trainSoulReward.ccbi", size=self.contentSize_}
	layer_base_t.init(self, true, ccbiAttrTable)

	self.data = data or {}
	self:init_ui()
	self:init_binding_event()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		for i = 1, 4 do
			self["sprite_award_bk" .. tostring(i)] = tolua.cast(self.proxy_:getNode("sprite_award_bk" .. tostring(i)), "CCSprite")
			self["label_card_num" .. tostring(i)] = tolua.cast(self.proxy_:getNode("label_card_num" .. tostring(i)), "CCLabelBMFont")
			self["label_card_num" .. tostring(i)]:setVisible(false)
		end
		local contentSize = self["sprite_award_bk1"]:getContentSize()
		--cclog("1111---count:%d", #self.data)
		for i = 1, #self.data do
			local pSprite = self.data[i].icon
			if self.data[i].frame ~= nil then
				self["sprite_award_bk" .. tostring(i)]:setDisplayFrame(self.data[i].frame)
			end
			self["sprite_award_bk" .. tostring(i)]:addChild(pSprite)
		    pSprite:setPosition(contentSize.width * 0.5, contentSize.height * 0.5)
		    pSprite:setAnchorPoint(ccp(0.5, 0.5))
		   	local iconsize = pSprite:getContentSize()
			local scalex = 83 / iconsize.width
			local scaley = 83 / iconsize.height
			if scalex > scaley then
				pSprite:setScale(scaley)
			else
				pSprite:setScale(scalex)
			end
			self["label_card_num" .. tostring(i)]:setVisible(true)
			self["label_card_num" .. tostring(i)]:setString(tostring(self.data[i].num))
			
		end
		self.closeButton =  tolua.cast(self.proxy_:getNode("closeButton"), "CCControlButton")
		self.btn_ok =  tolua.cast(self.proxy_:getNode("btn_ok"), "CCControlButton")
		self.node_container = tolua.cast(self.proxy_:getNode("node_container"), "CCNode")
	end
end

function init_binding_event(self)
	if self.proxy_ ~= nil then
		local function closeDlg()
			self.node_:removeFromParentAndCleanup(true)
		end
		self.closeButton:setTouchPriority(-10)
		self.btn_ok:setTouchPriority(-10)

		self.proxy_:handleControlEvent(self.closeButton, closeDlg, CCControlEventTouchUpInside)
		self.proxy_:handleControlEvent(self.btn_ok, closeDlg, CCControlEventTouchUpInside)

		local function CCLayerTouch(event, x, y)
			if event == "began" then			
				return true
			end
		end

		self.node_:setTouchEnabled(true)
		self.node_:registerScriptTouchHandler(CCLayerTouch, false, -6, true)
	end
end

function onNodeCleanup(self)
	if self.proxy_ then
    	self.proxy_:release()
    end
    layer_base_t.onNodeCleanup(self)
end