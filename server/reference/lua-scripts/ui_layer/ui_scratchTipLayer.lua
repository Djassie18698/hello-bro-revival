--descriptioin:刮刮乐提示（重写）
--company: xckoo
--author: chenchun
--date: 2013-12-03
---------------------------------------------
module("ui_scratchTipLayer", package.seeall)
baseClass(layer_base_t, ui_scratchTipLayer)

function init(self, callback, touchCallBack)
	self.contentSize_ = CCDirector:sharedDirector():getWinSize()
	local ccbiAttrTable = {name="dlg_ui/GuagualeTipsView.ccbi", size=self.contentSize_}
	layer_base_t.init(self, true, ccbiAttrTable)
	self.callback = callback
	self.touchCallBack = touchCallBack
	self:init_ui()
	self:init_binding_event(callBack)
end

function init_ui(self)
	if self.proxy_ ~= nil then
		self.node_:setPosition(CCPoint(self.contentSize_.width / 2, self.contentSize_.height / 2))
		self.node_:setAnchorPoint(ccp(0.5, 0.5))
	end
end

function init_binding_event(self)
	local function btnTipsSure()
		self.node_:removeFromParentAndCleanup(true)
		self.callback()
	end

	local function onScratchTouch(event)
		if self.node_ ~= nil then
	    	self.node_:removeFromParentAndCleanup(true)
	    	self.touchCallBack()
		end
		if event == "began" then
	        return true
	    end
	end
	if self.proxy_ ~= nil then
		local btn1 = tolua.cast(self.proxy_:getNode("btn_cost"), "CCControlButton")
		btn1:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.node_:setTouchEnabled(true)
		self.node_:registerScriptTouchHandler(onScratchTouch,false,kCCMenuHandlerPriority + 1,true)
		self.node_:setTouchMode(1)

		self.proxy_:handleButtonEvent(btn1, function(button, event)
			btnTipsSure()
			return nil
		end, CCControlEventTouchUpInside)
	end
end


function onNodeCleanup(self)
	--cclog("1111---001")
	if self.proxy_ then
    	self.proxy_:release()
    end
    layer_base_t.onNodeCleanup(self)
end