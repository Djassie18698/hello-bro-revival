--descriptioin:炼化动画
--company: xckoo
--author: chenchun
--date: 2013-1-20
---------------------------------------------
module("ui_trainSoulAnimation", package.seeall)
baseClass(layer_base_t, ui_trainSoulAnimation)

function init(self, animationName, size, istraining)
	--self.contentSize_ = CCDirector:sharedDirector():getWinSize()
	self.contentSize_ = size
	local ccbiAttrTable = {name="animations/" .. animationName .. ".ccbi", size = self.contentSize_ }
	layer_base_t.init(self, true, ccbiAttrTable)
	self:init_ui(istraining)
end

function init_ui(self, istraining)
	if self.proxy_ ~= nil then
		--tolua.cast(self.proxy_:getNode("label_gold_num" ), "CCLabelTTF"):setString(tostring(self.goldData))
		if istraining then


			self.winSize_ = CCDirector:sharedDirector():getWinSize()
			self.bglayer = CCLayerColor:create(ccc4(0, 0, 0, 175), self.winSize_.width * 2, self.winSize_.height * 2)
			self.bglayer:setAnchorPoint(ccp(0.5, 0.5))
			self.bglayer:setPosition(self.contentSize_.width / 2, self.contentSize_.height / 2)
			self.bglayer:ignoreAnchorPointForPosition(false)

			local function CCLayerTouch(event, x, y)
				if event == "began" then			
					return true
				end
			end

			self.bglayer:setTouchEnabled(true)
			self.bglayer:registerScriptTouchHandler(CCLayerTouch, false, -5, true)
		end
	end
end

function onNodeCleanup(self)
	if self.proxy_ then
    	self.proxy_:release()
    end
    if self.bglayer ~= nil then
    	self.bglayer:removeFromParentAndCleanup(true)
    end
    layer_base_t.onNodeCleanup(self)
end