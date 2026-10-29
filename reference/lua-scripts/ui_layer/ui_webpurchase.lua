--评分界面
--chenchun
---------------------------------------------
module("ui_webpurchase", package.seeall)
baseClass(layer_base_t, ui_webpurchase)

--m_isEvaluate = 0
function init(self)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	self.contentNode_ = GetActivityView():GetNodeContent()
	self.contentSize_ = self.contentNode_:getContentSize()
	local ccbiAttrTable = {name="activity/ThaiPayView.ccbi", size=self.contentSize_}
	layer_base_t.init(self, true, ccbiAttrTable)

	self.getStatus = 1
	self.is_evaluate = 0  --是否評價
	self.giftlist = {}
	self:init_ui()
	self:init_binding_event()
end


function init_ui(self)
	if self.proxy_ ~= nil then
		self.btn_pay = tolua.cast(self.proxy_:getNode("btn_pay"), "CCControlButton")
			
	end
end

function init_binding_event(self)
	--评价回调函数
	local function web_purchase_callback(btn, event)
		local puchaseLayer = createObj(ui_purchaseLayerForWeb)
        GetMainMenu():GetModelLayer():AddDialog(puchaseLayer.node_, 3);
	end


	if self.proxy_ ~= nil then
		self.proxy_:handleControlEvent(self.btn_pay, web_purchase_callback, CCControlEventTouchUpInside)
	end
end

function onNodeCleanup(self)
    --cclog("onNodeCleanup1111")
    if self.proxy_ then
    	self.proxy_:release()
    end
    layer_base_t.onNodeCleanup(self)
end