--首冲界面的礼包列表的cell
--chenchun
---------------------------------------------

module("ui_purchaseTableCell", package.seeall)
baseClass(layer_base_t, ui_purchaseTableCell)

function init(self, cellSize, data,isopen,multi,bFirstPay,multiple)
	local ccbiAttrTable = {name="store/PurchaseItemView.ccbi", size=cellSize}
	layer_base_t.init(self, true, ccbiAttrTable)

	self.rechargeData = data
	self.mulisopen = isopen
	self.multicount = multi
	--活动翻倍
	self.multiple = multiple
	--是否首充litao_2014.6.24
	self.bFirstPay = bFirstPay
	self:init_ui()
end

function init_ui(self)
	if self.proxy_ ~= nil then	
		self.label_getgold = tolua.cast(self.proxy_:getNode("label_getgold"), "CCLabelTTF")
		self.label_rmb =  tolua.cast(self.proxy_:getNode("label_rmb"), "CCLabelTTF")		
		self.label_rmb:setString(tostring(tonumber(self.rechargeData.rmb) / 100))
		--litao_首充3倍_2014.6.24
		self.spr_first_pay = tolua.cast(self.proxy_:getNode("spr_first_pay"), "CCSprite")
		self.proxy_:getNode("spr_act_muti"):setVisible(false)
		if 0 == self.bFirstPay then
			--未首充
			self.spr_first_pay:setVisible(true)
			--隐藏其他信息
			self.proxy_:getNode("sprite_give"):setVisible(false)
			self.proxy_:getNode("sprite_extgold"):setVisible(false)
			self.proxy_:getNode("label_extragold"):setVisible(false)
			self.proxy_:getNode("label_multip1"):setVisible(false)
			self.proxy_:getNode("sprite_mulicon"):setVisible(false)		
			self.proxy_:getNode("label_multip2"):setVisible(false)
			--self.proxy_:getNode("spr_act_muti"):setVisible(false)
			--
			self.label_getgold:setColor(ccc3(0,0,0));
			self.label_getgold:setString(self.rechargeData.yuanbao*3);
		else
			--已经首充
			self.spr_first_pay:setVisible(false)
			if self.mulisopen == 1 then
				self.proxy_:getNode("label_extragold"):setVisible(false);
				self.proxy_:getNode("sprite_extgold"):setVisible(false);
				self.proxy_:getNode("sprite_give"):setVisible(false);
				self.proxy_:getNode("label_multip1"):setVisible(true);
				--self.proxy_:getNode("label_multip2"):setVisible(true);
				self.proxy_:getNode("sprite_mulicon"):setVisible(true);
				--self.proxy_:getNode("spr_act_muti"):setVisible(false)
				local framename = "Shop_mul_"..self.multicount;
				local frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(framename);			
				tolua.cast(self.proxy_:getNode("sprite_mulicon"), "CCSprite"):setDisplayFrame(frame);
				self.label_getgold:setColor(ccc3(255,0,0));
				self.label_getgold:setString(self.rechargeData.yuanbao*self.multicount);
			else
				if self.multiple > 1 then
					--有翻倍信息
					--self.proxy_:getNode("spr_act_muti"):setVisible(true)
					--隐藏其他信息
					self.proxy_:getNode("sprite_give"):setVisible(false)
					self.proxy_:getNode("sprite_extgold"):setVisible(false)
					self.proxy_:getNode("label_extragold"):setVisible(false)
					self.proxy_:getNode("label_multip1"):setVisible(false)
					self.proxy_:getNode("sprite_mulicon"):setVisible(false)		
					self.proxy_:getNode("label_multip2"):setVisible(false)
					--
					self.label_getgold:setColor(ccc3(0,0,0));
					self.label_getgold:setString(self.rechargeData.yuanbao*self.multiple*0.1);
				else
					self.proxy_:getNode("spr_act_muti"):setVisible(false)
					self.label_getgold:setString(self.rechargeData.yuanbao)
					self.proxy_:getNode("label_extragold"):setVisible(true);
					self.proxy_:getNode("sprite_give"):setVisible(true);
					self.proxy_:getNode("sprite_extgold"):setVisible(true);
					self.proxy_:getNode("label_multip1"):setVisible(false);
					--self.proxy_:getNode("label_multip2"):setVisible(false);
					self.proxy_:getNode("sprite_mulicon"):setVisible(false);
					self.label_getgold:setColor(ccc3(0,0,0));
					self.label_extragold = tolua.cast(self.proxy_:getNode("label_extragold"), "CCLabelTTF")
					self.label_extragold:setString(self.rechargeData.yuanbao_give)
				end
			end
			self.proxy_:getNode("label_multip2"):setVisible(false);
		end
	end
end

function update_ui(self, data)
	if data then
		self.label_rmb:setString(tostring(tonumber(data.rmb) / 100))
		self.label_getgold:setString(data.yuanbao)
		self.label_extragold:setString(data.yuanbao_give)
	end
end

function onNodeCleanup(self)
    --cclog("onNodeCleanup")
    --[[
    if self.node_:retainCount() == 1 then
        self.proxy_:release()
    end
    ]]
    --cclog("1111---" .. tostring(self.node_) .. "---" .. tostring(self.rechargeData.rmb) .. "----" .. tostring(self.node_:retainCount()))
    layer_base_t.onNodeCleanup(self)
end