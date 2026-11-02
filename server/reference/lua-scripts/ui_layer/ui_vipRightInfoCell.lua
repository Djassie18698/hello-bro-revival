--VIP特权信息Cell
--litao
--2014.4.2
---------------------------------------------
module("ui_vipRightInfoCell", package.seeall)
baseClass(layer_base_t, ui_vipRightInfoCell)

function init(self, cellSize, data)
	self.cellData = data

	local ccbiAttrTable = {name="store/VipRightInfoCell.ccbi", size=cellSize}
	layer_base_t.init(self, true, ccbiAttrTable)

	--init	
	self.m_vipframes={'vip_0','vip_1','vip_2','vip_3','vip_4','vip_5','vip_6','vip_7','vip_8','vip_9','vip_10','vip_11','vip_12','vip_13','vip_14','vip_15','vip_16','vip_17','vip_18'}
	self.cellSuitInfo = {}
	self.cellSuitInfo = self.cellData.data
	self:init_ui()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		--sprite
		self.spr_vip_level = tolua.cast(self.proxy_:getNode("sprite_viplevel"), "CCSprite")
		--label
		for i=1,7 do
			self["label_right_"..i] = tolua.cast(self.proxy_:getNode("label_right_"..i), "CCLabelTTF")
		end	

		--info
		self:init_ui_ext()	
	end
end

function init_ui_ext(self)
	local cur_vip_lv = self.cellData.vip_level + 1
	if cur_vip_lv > #self.m_vipframes then
		cur_vip_lv = #self.m_vipframes
	end
	local frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(self.m_vipframes[cur_vip_lv])
	self.spr_vip_level:setDisplayFrame(frame)
	--info
	self["label_right_1"]:setString(self.cellData.param1)
	self["label_right_2"]:setString(self.cellData.param2)
	self["label_right_3"]:setString(self.cellData.param3)
	self["label_right_4"]:setString(self.cellData.param4)
	self["label_right_5"]:setString(self.cellData.param5)
	self["label_right_6"]:setString(self.cellData.param6)
	self["label_right_7"]:setString(self.cellData.param7)
	--[[
	self["label_right_8"]:setString(self.cellData.param8)
	if nil ~= self.cellData.param9 then
		self["label_right_9"]:setString(self.cellData.param9)
	else
		self["label_right_9"]:setVisible(false)
	end
	--]]
end

function onNodeCleanup(self)
	if self.proxy_ then
    	self.proxy_:release()
    	self.proxy_ = nil
    end
    layer_base_t.onNodeCleanup(self)
end