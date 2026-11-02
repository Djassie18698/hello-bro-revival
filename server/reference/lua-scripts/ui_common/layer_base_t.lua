--description: the base layer, the custom layer should inherite from layer_base_t.
--company:xckoo

module("layer_base_t", package.seeall)
baseClass(node_base_t, layer_base_t)

--isCCBI,用来标示layer 是否是从ccbi创建
--ccbiAttribute 为table，第一个值为ccbi的名称：ccbiAttribute['name']，第二个值为大小:ccbiAttribute['size']
function init(self, isCCBI, ccbiAttribute, bMaxAuthority)
    if isCCBI == true then
        self.proxy_ = CCBProxy:create()
        self.proxy_:retain()
        self.proxy_:SetClearPlist(false)
        local layer = nil
        if ccbiAttribute["size"] ~= nil then
            layer = self.proxy_:readCCBFromFileBySize(ccbiAttribute["name"], ccbiAttribute["size"])
        else
            layer = self.proxy_:readCCBFromFile(ccbiAttribute["name"])
        end
        self.node_ = tolua.cast(layer, "CCLayer")
    else
        self.node_ = CCLayer:create()
    end

    self.node_:ignoreAnchorPointForPosition(false)
    self.node_:setAnchorPoint(ccp(0, 0))

    node_base_t.init(self, self.node_)

    self.touchHandler_ = {}

    --[[
    local function onTouched(_eventType, ...)
        --cclog("_eventType = %s", _eventType)
        local result = self.touchHandler_[_eventType](self, ...)
        if self.touchBegan ~= nil and _eventType == "began" then
            assert(result ~= nil, "touchBegan must return a result!")

            local ret

            if result == true then
                ret = 1
            else
                ret = 0
            end
            return ret
        end
    end

    if self.touchBegan ~= nil then
        --单点触控
        self.node_:setTouchEnabled(true)
        if bMaxAuthority then
            self.node_:registerScriptTouchHandler(onTouched, false, -129, true)
        else
            self.node_:registerScriptTouchHandler(onTouched, false, -128, true)
        end

        self.touchHandler_["began"] = self.touchBegan
        self.touchHandler_["moved"] = self.touchMoved
        self.touchHandler_["ended"] = self.touchEnded
        self.touchHandler_["cancelled"] = self.touchCancelled
    elseif self.touchesBegan ~= nil then
        --多点触控
        self.node_:setTouchEnabled(true)
        self.node_:registerScriptTouchHandler(onTouched, true)

        self.touchHandler_["began"] = self.touchesBegan
        self.touchHandler_["moved"] = self.touchesMoved
        self.touchHandler_["ended"] = self.touchesEnded
        self.touchHandler_["cancelled"] = self.touchesCancelled
    end
    ]]
end

--[[
function touchesBegan(self, _touches)
    --cclog("touchesBegan")
end

function touchesMoved(self, _touches)
    --cclog("touchesMoved")
end

function touchesEnded(self, _touches)
    --cclog("touchesEnded")
end

function touchesCancelled(self, _touches)
    --cclog("touchesCancelled")
end



function touchBegan(self, _touchX, _touchY, _preTouchX, _preTouchY)
    --cclog("touchBegan")
    return true
end

function touchMoved(self, _touchX, _touchY, _preTouchX, _preTouchY)
    --cclog("touchMoved")
end

function touchEnded(self, _touchX, _touchY, _preTouchX, _preTouchY)
    --cclog("touchEnded")
end

function touchCancelled(self, _touchX, _touchY, _preTouchX, _preTouchY)
    --cclog("touchCancelled")
end

]]
function onNodeCleanup(self)
    node_base_t.onNodeCleanup(self)
end