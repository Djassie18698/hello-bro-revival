--description: the node layer, the custom node should inherite from node_base_t.
--company:xckoo

module("node_base_t", package.seeall)

function init(self, _node)
    if _node == nil then
        self.node_ = CCNode:create()
        self.node_:ignoreAnchorPointForPosition(false)
        self.node_:setAnchorPoint(ccp(0, 0))
    end
    
    --CCNode的事件
    local function onNodeEvent(event)
        --cclog("event name = %s", event["name"])
        if event == "enter" then
            self:onNodeEnter()
        elseif event == "exit" then
            self:onNodeExit()
        elseif event == "cleanup" then
            self:onNodeCleanup()
        end
    end
    
    self.node_:registerScriptHandler(onNodeEvent)
end

function getCCScene(self)
    local scene = CCScene:create()
    scene:addChild(self.node_)
    return scene
end

function onNodeEnter(self)
    --cclog("onNodeEnter")
end

function onNodeExit(self)
    --cclog("onNodeExit")
end

function onNodeCleanup(self)
    --cclog("onNodeCleanup")
end