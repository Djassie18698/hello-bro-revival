--description: 累计充值
--company：xckoo
--author：chenchun
---------------------------------------------
module("ui_growthfundCell", package.seeall)
baseClass(layer_base_t, ui_growthfundCell)

function init(self, cellSize, data)
	local ccbiAttrTable = {name="activity/growth_fund_cell.ccbi", size=cellSize}
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()
	layer_base_t.init(self, true, ccbiAttrTable)
	self.fund_data = data
	self:init_ui()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		
		self.btn_scale_sprite = tolua.cast(self.proxy_:getNode("sprite_btn_get_fund"), "CCScale9Sprite")
		self.btn_get_sprite = tolua.cast(self.proxy_:getNode("sprite_has_get"), "CCSprite")
		
		self.label_item_title = tolua.cast(self.proxy_:getNode("label_fund_title"), "CCLabelTTF")
		self.label_props_desc = tolua.cast(self.proxy_:getNode("label_props_desc"), "CCLabelTTF")
		self.label_props_count = tolua.cast(self.proxy_:getNode("label_props_count"), "CCLabelBMFont")	

		self.label_item_title:setString(self.fund_data.title)
		
		local desc_size = self.label_props_desc:getContentSize()	
		self.label_props_desc:setDimensions(CCSizeMake(desc_size.width, 0))
		self.label_props_desc:setString(self.fund_data.desc)
		
		self.label_props_count:setString(self.fund_data.count);		

		local iconnode = self.proxy_:getNode("node_props_icon");		

   	  	local pathName = "props/props_037.plist"
   	 	CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile(pathName);
		local spriteicon = CCSprite:createWithSpriteFrameName("props_037");

		iconnode:removeAllChildrenWithCleanup(true);
		local size = iconnode:getContentSize();
		spriteicon:setAnchorPoint(ccp(0.5,0.5));
		spriteicon:setPosition(ccp(size.width/2,size.height/2));
		iconnode:addChild(spriteicon);

		if self.fund_data.status == 0 then
			local pProgram = CCShaderCache:sharedShaderCache():programForKey("greysprite");
			self.btn_scale_sprite:setShaderProgram(pProgram);
			self.btn_scale_sprite:setVisible(true);
			self.btn_get_sprite:setVisible(false);
		elseif self.fund_data.status == 1 then
			self.btn_scale_sprite:setVisible(true);
			self.btn_get_sprite:setVisible(false);
			local pProgram = CCShaderCache:sharedShaderCache():programForKey("ShaderPositionTextureColor");
			self.btn_scale_sprite:setShaderProgram(pProgram);
		else
			self.btn_scale_sprite:setVisible(false);
			self.btn_get_sprite:setVisible(true);
		end
		
	end
end

function btn_get_fund_1(self,view)
	if self.fund_data.status ~= 1 then
		return nil;
	end
	local id = self.fund_data.id
	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 3, protocol.URL_GROWTH_FUND_R)
			urlpath = AddData(urlpath,"Id",tonumber(id))
			GetMainMenu():ShowLoadingDlg()	-- 获取信息的时候，不允许操作
			CCHttpRequest:open(urlpath, kHttpPost,"query=param1&other=params"):sendWithHandler(
				function(res, hnd)
					GetMainMenu():CloseLoadding(); --获取信息完成时，解除禁止操作
					local resData = res:getResponseData()
					local code = res:getResponseCode()
					local xfile = xml.parse(resData)
					local item = xfile:find("RENLONG")
					if item == nil then
						return nil
					end
					local retcode = item.code
					if retcode == "0" then
						local preview = item:find("preview");
						self.playerMgr_:AddGold(preview.cash);
						view:reLoadTable();
						GetMainMenu():ShowTextTip(string.format(localizable.ui_growth_get_gold_tip, tostring(self.fund_data.count)),-1)
					else
						GetMainMenu():ShowErrorTip(retcode,-1);
					end
				end)
end