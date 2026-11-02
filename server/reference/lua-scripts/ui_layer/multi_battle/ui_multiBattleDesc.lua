--descriptioin:跨服战说明界面
--company: xckoo
--author: chenchun
--date: 2014-2-19
---------------------------------------------
module("ui_multiBattleDesc", package.seeall)
baseClass(layer_base_t, ui_multiBattleDesc)

function init(self, parentSize)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	self.contentSize_ = parentSize
	local ccbiAttrTable = {name="multiserverbattle/multiBattleDesc.ccbi", size=self.contentSize_}
	layer_base_t.init(self, true, ccbiAttrTable)

	self:init_ui()
	self:init_binding_event()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		self.label_multiBattle_desc = tolua.cast(self.proxy_:getNode("label_multiBattle_desc"), "CCLabelTTF")
		self.label_bingo_desc = tolua.cast(self.proxy_:getNode("label_bingo_desc"), "CCLabelTTF")

		self.label_multiBattle_desc:setString(localizable.ui_multi_description)
		self.label_bingo_desc:setString(localizable.ui_bingo_description)
	end
end

function init_binding_event(self)

	if self.proxy_ ~= nil then

	end
end


function onNodeCleanup(self)
	if self.proxy_ then
    	self.proxy_:release()
    end
    layer_base_t.onNodeCleanup(self)
end