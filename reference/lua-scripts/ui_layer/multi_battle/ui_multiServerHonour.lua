--descriptioin:跨服战上期战报界面
--company: xckoo
--author: chenchun
--date: 2014-2-19
---------------------------------------------
module("ui_multiServerHonour", package.seeall)
baseClass(layer_base_t, ui_multiServerHonour)

function init(self)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	self.contentSize_ = CCDirector:sharedDirector():getWinSize()
	local ccbiAttrTable = {name="multiserverbattle/multiServerHonour.ccbi", size=self.contentSize_}
	layer_base_t.init(self, true, ccbiAttrTable)

	self:init_ui()
	self:init_binding_event()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		self.ctrl_close = tolua.cast(self.proxy_:getNode("ctrl_close"), "CCControlButton")

		self.label_praise1 = tolua.cast(self.proxy_:getNode("label_praise1"), "CCLabelBMFont")
		self.layer_icon = tolua.cast(self.proxy_:getNode("layer_icon"), "CCLayer")
		self.ctrl_btn_praise1 = tolua.cast(self.proxy_:getNode("ctrl_btn_praise1"), "CCControlButton")
		self.label_cardname1 = tolua.cast(self.proxy_:getNode("label_cardname1"), "CCLabelTTF")

		self.node_icon2 = tolua.cast(self.proxy_:getNode("node_icon2"), "CCNode")
		self.label_cardname2 = tolua.cast(self.proxy_:getNode("label_cardname2"), "CCLabelTTF")
		self.label_level2 = tolua.cast(self.proxy_:getNode("label_level2"), "CCLabelBMFont")
		self.label_praise2 = tolua.cast(self.proxy_:getNode("label_praise2"), "CCLabelBMFont")
		self.ctrl_btn_praise2 = tolua.cast(self.proxy_:getNode("ctrl_btn_praise2"), "CCControlButton")

		self.node_icon3 = tolua.cast(self.proxy_:getNode("node_icon3"), "CCNode")
		self.label_cardname3 = tolua.cast(self.proxy_:getNode("label_cardname3"), "CCLabelTTF")
		self.label_level3 = tolua.cast(self.proxy_:getNode("label_level3"), "CCLabelBMFont")
		self.label_praise3 = tolua.cast(self.proxy_:getNode("label_praise3"), "CCLabelBMFont")
		self.ctrl_btn_praise3 = tolua.cast(self.proxy_:getNode("ctrl_btn_praise3"), "CCControlButton")

		--[[
		local urlpath = GetUrlNormalHeader(self.playerData_.m_uid,  protocol.CMD_R_COMM, protocol.URL_R_COMM)
		GetMainMenu():ShowLoadingDlg()	--获取信息的时候，不允许操作
		CCHttpRequest:open(urlpath, kHttpPost,"query=param1&other=params"):sendWithHandler(
			function(res, hnd)
				GetMainMenu():CloseLoadding() --获取信息完成时，解除禁止操作
				local resData = res:getResponseData()
				local code = res:getResponseCode()
				local xfile = xml.parse(resData)
				local item = xfile:find("RENLONG")
				local retcode = item.code
				if retcode == "0" then

				end
			end)
		]]
	end
end


function init_binding_event(self)

	if self.proxy_ ~= nil then
		local function close_window(btn, event)
			self.node_:removeFromParentAndCleanup(true)
		end

		self.ctrl_close:setTouchPriority(-2)
		self.ctrl_btn_praise1:setTouchPriority(-2)
		self.ctrl_btn_praise2:setTouchPriority(-2)
		self.ctrl_btn_praise2:setTouchPriority(-2)

		self.proxy_:handleControlEvent(self.ctrl_close, close_window, CCControlEventTouchUpInside)
	end
end



function onNodeCleanup(self)
	--cclog("1111---001")
	if self.proxy_ then
    	self.proxy_:release()
    end
    layer_base_t.onNodeCleanup(self)
end