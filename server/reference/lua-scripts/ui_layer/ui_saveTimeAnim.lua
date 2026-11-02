--xckoo
--litao
--2014-6-20
---------------------------------------------
module("ui_saveTimeAnim", package.seeall)
baseClass(layer_base_t, ui_saveTimeAnim)

function init(self, parentSize, data)
	local ccbiAttrTable = {name="animations/showSaveTime.ccbi", size=parentSize}
	layer_base_t.init(self, true, ccbiAttrTable)

	self.m_data = data

	--init
	self:init_ui()	
end

function init_ui(self)
	--label
	self.label_exp = tolua.cast(self.proxy_:getNode("label_exp"), "CCLabelBMFont")
	self.label_coin = tolua.cast(self.proxy_:getNode("label_coin"), "CCLabelBMFont")
	self.label_ratio = tolua.cast(self.proxy_:getNode("label_ratio"), "CCLabelBMFont")
	--spr
	self.spr_succeed = tolua.cast(self.proxy_:getNode("spr_succeed"), "CCSprite")
	self.spr_ratio = tolua.cast(self.proxy_:getNode("spr_ratio"), "CCSprite")

	--ext init
	self:init_ui_ext()
end

function init_ui_ext(self)
	self.label_exp:setString("+"..tostring(self.m_data.exchange_exp))
	self.label_coin:setString("+"..tostring(self.m_data.exchange_coin))
	--暴击
	if self.m_data.exchange_ratio > 1 then
		self.label_ratio:setVisible(true)
		self.spr_ratio:setVisible(true)
		self.label_ratio:setString(tostring(self.m_data.exchange_ratio))
	else
		self.label_ratio:setVisible(false)
		self.spr_ratio:setVisible(false)
		--成功置中
		local _size = self.node_:getContentSize()
		local pos_x, pos_y = self.spr_succeed:getPosition()
		self.spr_succeed:setPosition(CCPoint(_size.width * 0.5, pos_y))
	end
end

function onNodeCleanup(self)
	--cclog("1111---001:")
	if self.proxy_ then
    	self.proxy_:release()
    end
    layer_base_t.onNodeCleanup(self)
end