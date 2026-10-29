require "util/localizable"

VipCellView=class(
		"VipListView",
    function()
        return LuaSubView:create() 
    end
)
VipCellView.m_index=0;
VipCellView.m_data={};

function VipCellView:create()
	local view = VipCellView.new();
	view:SetClearPlist(false);
	return view;
end

function VipCellView:loadCCBI()
	self:LoadCCBI("store/VipItemView.ccbi",self.m_cellsize);
end

function VipCellView:initUI()
	--原价
	local price = self.m_data:find("price")[1]
	local orgin_price = self.m_data:find("orgin_price")[1]
	tolua.cast(self:getNode("label_price"), "CCLabelTTF"):setString(orgin_price)	
	tolua.cast(self:getNode("label_now_price"), "CCLabelTTF"):setString(price)
	--
	local desc = self.m_data:find("desc")[1]
	local desc_size = tolua.cast(self:getNode("node_descsize"), "CCNode"):getContentSize()
	tolua.cast(self:getNode("label_desc"), "CCLabelTTF"):setDimensions(CCSizeMake(desc_size.width, 0))
	tolua.cast(self:getNode("label_desc"), "CCLabelTTF"):setString(desc);
	local name = "VIP"..self.m_data:find("vip")[1]..localizable.vip_gift_text;
	tolua.cast(self:getNode("label_name"), "CCLabelTTF"):setString(name);	
	local playerMgr = CPlayerDataMgr:instance();
	local viplevel = playerMgr:GetVipLevel();
	local iconName = self.m_data:find("icon")[1];
	local pathName = "props/"..iconName..".plist"
	CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile(pathName)
	local frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(iconName)
	self:getNode("sprite_goodstype"):removeChildByTag(199,true);
	if frame ~= nil then
		local icon = CCSprite:createWithSpriteFrame(frame)
		local size = tolua.cast(self:getNode("sprite_goodstype"), "CCSprite"):getContentSize()
		tolua.cast(self:getNode("sprite_goodstype"), "CCSprite"):addChild(icon)
		icon:setPosition(size.width/2, size.height/2)
		local point = CCPoint:new()
		point.x = 0.5;
		point.y = 0.5;
		icon:setAnchorPoint(point);
		icon:setTag(199);
	end
	
	--local texttip = string.format(localizable.vip_list_cell_need_viplv,tostring(self.m_data:find("vip")[1]))
	--[[
	if viplevel >= tonumber(self.m_data:find("vip")[1]) then		
		if viplevel == 1 then
			texttip="现在拥有购买VIP1的所有VIP礼包的资格。"
		end
		
	else
		texttip="";
	end
	--]]
	--tolua.cast(self:getNode("label_viptips"), "CCLabelTTF"):setString(texttip);	
	
	local canbuy = self.m_data:find("canbuy")[1];
	self:getNode("sprite_btn_buyit"):removeChildByTag(123,true);

	--0未达到买的条件 1已买  2可以够买
	if tonumber(canbuy) == 0 then --290102 then	
    	--local frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("shop_08");
	    --tolua.cast(self:getNode("sprite_textbuy"),"CCSprite"):setDisplayFrame(frame);
		local pProgram = CCShaderCache:sharedShaderCache():programForKey("greysprite");
		tolua.cast(self:getNode("sprite_itemback"),"CCSprite"):setShaderProgram(pProgram);
	    tolua.cast(self:getNode("sprite_textbuy"),"CCSprite"):setShaderProgram(pProgram);
	    tolua.cast(self:getNode("sprite_btn_buyit"),"CCSprite"):setShaderProgram(pProgram);		
	elseif tonumber(canbuy) == 1 then --290104 then		
		local pProgram = CCShaderCache:sharedShaderCache():programForKey("ShaderPositionTextureColor")
		tolua.cast(self:getNode("sprite_itemback"),"CCSprite"):setShaderProgram(pProgram)			
	    tolua.cast(self:getNode("sprite_textbuy"),"CCSprite"):setVisible(false)
	    tolua.cast(self:getNode("sprite_btn_buyit"),"CCSprite"):setVisible(false)
	    tolua.cast(self:getNode("sprite_buyed"),"CCSprite"):setVisible(true)

		--[[
	    local frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("shop_14");
	    tolua.cast(self:getNode("sprite_textbuy"),"CCSprite"):setDisplayFrame(frame);
	    
		local pProgram = CCShaderCache:sharedShaderCache():programForKey("ShaderPositionTextureColor");
		tolua.cast(self:getNode("sprite_itemback"),"CCSprite"):setShaderProgram(pProgram);			
	    tolua.cast(self:getNode("sprite_textbuy"),"CCSprite"):setShaderProgram(pProgram);
	    tolua.cast(self:getNode("sprite_btn_buyit"),"CCSprite"):setShaderProgram(pProgram);
	    local btn = CCSprite:createWithSpriteFrameName("shop_10")
        self:getNode("sprite_btn_buyit"):addChild(btn)				
        btn:setAnchorPoint(ccp(0,0))
        btn:setPosition(ccp(0,0))
        btn:setTag(123)
        --]]
	else		
	    --local frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("shop_08");
		--tolua.cast(self:getNode("sprite_textbuy"),"CCSprite"):setDisplayFrame(frame);
		local pProgram = CCShaderCache:sharedShaderCache():programForKey("ShaderPositionTextureColor");
		tolua.cast(self:getNode("sprite_itemback"),"CCSprite"):setShaderProgram(pProgram);
		tolua.cast(self:getNode("sprite_textbuy"),"CCSprite"):setShaderProgram(pProgram);
		tolua.cast(self:getNode("sprite_btn_buyit"),"CCSprite"):setShaderProgram(pProgram);
	end
end

function VipCellView:setIndex(idx)
	self.m_index = idx;
end

function VipCellView:getIndex()
	return self.m_index;
end

function VipCellView:setCellSize(size)
	self.m_cellsize = size;
end

function VipCellView:setCellData(celldata)
	self.m_data = celldata;
end

function VipCellView:getCellData()
	return self.m_data;
end

