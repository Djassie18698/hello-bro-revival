require "LuaSubView.lua"
require "RLRequest"
require "LuaXml.lua"
require "CommonBuyItemCellView.lua"

require("config/firstpurchase_config")
require("ui_layer/ui_purchaseLayer")
require("ui_layer/ui_purchaseTableCell")
require "util/localizable"

local m_touchPoint

CommonBuyItemDialog=class(
		"CommonBuyItemDialog",
    function()
        return CCLayer:create() 
    end
)

CommonBuyItemDialog.m_touchPriority = kCCMenuHandlerPriority-1;
CommonBuyItemDialog.m_selectedIndex = 0;
CommonBuyItemDialog.m_itemList = {}


--vip
CommonBuyItemDialog.m_vipframes={'vip_015','vip_003','vip_004','vip_005','vip_006','vip_007','vip_008','vip_009','vip_010','vip_011','vip_012','vip_013','vip_014','vip_s_13','vip_s_14','vip_s_15','vip_s_16','vip_s_17','vip_s_18'}

function CommonBuyItemDialog_onTouch(event, x, y)
    if event == "began" then   
        return true
    end
end

function CommonBuyItemDialog:create()
	local view = CommonBuyItemDialog.new();
	return view;
end

function CommonBuyItemDialog:loadCCBI()
	local view = LuaSubView:create();	
	local win = CCDirector:sharedDirector():getWinSize();
	view:LoadCCBI("dlg_ui/CommonBuyItemDialog.ccbi",CCSize(768,win.height));
	self:addChild(view)
	view:setPosition(CCPoint(win.width / 2, win.height / 2));
	self.m_dlgview = view;
end

function CommonBuyItemDialog:initTable()	
	self:initHandle();
	
	self.m_contentview = self.m_dlgview:getNode("node_table_container");
	local contentsize = self.m_contentview:getContentSize();
	self.m_cellsize = self.m_dlgview:getNode("node_tablecell"):getContentSize();
	
	local tableview = LuaTableView:createWithHandler(self.m_handler, CCSizeMake(contentsize.width,contentsize.height))
	self.m_tableview = tableview
	tableview:setDirection(kCCScrollViewDirectionVertical);
	tableview:setVerticalFillOrder(kCCTableViewFillTopDown);
	tableview:reloadData()
	self.m_contentview:addChild(tableview);
	tableview:setTouchPriority(CommonBuyItemDialog.m_touchPriority);
end

function CommonBuyItemDialog:CheckItemCount()
	local itemInfo
	self.m_targetItemId = self.m_itemList[self.m_selectedIndex+1]
	if self.m_itemType == kConsumableTypeItem then
		itemInfo = tolua.cast(CTradeMgr:instance():GetConsumByIDForLua(self.m_targetItemId), "ConsumeInfo")
		if itemInfo.m_bagnum > 0 then
			tolua.cast(self.m_dlgview:getNode("label_confirm"), "CCLabelTTF"):setString(localizable.commonBuy_use_desc)
		else
			tolua.cast(self.m_dlgview:getNode("label_confirm"), "CCLabelTTF"):setString(localizable.commonBuy_buy_desc)
		end
	else
		itemInfo = tolua.cast(CTradeMgr:instance():GetGiftByIDForLua(self.m_targetItemId), "Struct_Giftinfo")
		tolua.cast(self.m_dlgview:getNode("label_confirm"), "CCLabelTTF"):setString(localizable.commonBuy_buy_desc)
	end
end

function CommonBuyItemDialog:SetDefaultItem()
	local itemInfo
	local chosen = false
	
	for i = 1, #self.m_itemList do
		if self.m_itemType == kConsumableTypeItem then
			local itemId = self.m_itemList[i]
			itemInfo = tolua.cast(CTradeMgr:instance():GetConsumByIDForLua(itemId), "ConsumeInfo")
			if itemInfo.m_bagnum > 0 then
				if chosen == false then
					self.m_selectedIndex = i-1
					chosen = true
				end
			end
		end
	end
end

function CommonBuyItemDialog:initUI()		
	self.cellNodes = {}

	self:loadCCBI()
	self:SetDefaultItem()
	self:initTable()
	self:BindControl()
	self.m_targetItemId = self.m_itemList[self.m_selectedIndex+1]
	--self:CheckItemCount()
	
	if self.m_itemList[1] == SMALL_ENERGY_ITEM_ID then
		tolua.cast(self.m_dlgview:getNode("node_energy_container"), "CCNode"):setVisible(true)
		
		local playerMgr = CPlayerDataMgr:instance()
		local playerData = playerMgr:GetPlayerInfoData()
		local maxbodyval = playerMgr:GetMaxBodyValue()
		local currbodyval = playerData.m_bodyvalue
		local textbodyval = currbodyval.."/"..maxbodyval;
		tolua.cast(self.m_dlgview:getNode("label_current_energy"), "CCLabelBMFont"):setString(textbodyval)
		
		local resttext = CTradeMgr:instance():GetRemenLimitRest().."";
		tolua.cast(self.m_dlgview:getNode("label_energy_left"), "CCLabelBMFont"):setString(resttext);
	elseif self.m_itemList[1] == SMALL_PK_ENERGY_ITEM_ID then
		--兵粮丸
		tolua.cast(self.m_dlgview:getNode("node_energy_container"), "CCNode"):setVisible(true)

		--icon
		local fight_frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(tostring("com_text_fight"))
		tolua.cast(self.m_dlgview:getNode("spr_obj"), "CCSprite"):setDisplayFrame(fight_frame)
		
		local playerMgr = CPlayerDataMgr:instance()
		local playerData = playerMgr:GetPlayerInfoData()
		local max_fgt_val = playerMgr:GetMaxAttackCount()
		local cur_fgt_val = playerData.m_fightcount
		local text_val = tostring(cur_fgt_val.."/"..max_fgt_val)
		tolua.cast(self.m_dlgview:getNode("label_current_energy"), "CCLabelBMFont"):setString(text_val)
		
		local resttext = CTradeMgr:instance():GetHyourouganLmtRest()
		tolua.cast(self.m_dlgview:getNode("label_energy_left"), "CCLabelBMFont"):setString(resttext)
	else
		tolua.cast(self.m_dlgview:getNode("node_energy_container"), "CCNode"):setVisible(false)
	end

	--next vip icon
	local playerMgr = CPlayerDataMgr:instance()
	local viplevel = playerMgr:GetVipLevel()
	local next_vip = viplevel + 2
	if next_vip > #self.m_vipframes then
		next_vip = #self.m_vipframes
	end
	local next_frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(CommonBuyItemDialog.m_vipframes[next_vip])
	tolua.cast(self.m_dlgview:getNode("sprite_next_viplevel"), "CCSprite"):setDisplayFrame(next_frame)
	--add label
	local cur_vipData = DataMgr.GetDataByID("Struct_Vipinfo", tonumber(viplevel + 1))
	
	local next_vip_lv = viplevel + 1
	if next_vip_lv > #self.m_vipframes - 1 then
		tolua.cast(self.m_dlgview:getNode("label_next_level_add"), "CCLabelTTF"):setString(localizable.commonBuy_max_vipLv_desc)
	else
		local next_vipData = DataMgr.GetDataByID("Struct_Vipinfo", tonumber(next_vip_lv + 1))

		local next_box_num = 0
		local cur_box_num = 0
		if self.m_itemList[1] == SMALL_ENERGY_ITEM_ID then
			cur_box_num = tonumber(cur_vipData.m_vip_props1_num)
			next_box_num = tonumber(next_vipData.m_vip_props1_num)
		elseif self.m_itemList[1] == SMALL_PK_ENERGY_ITEM_ID then
			--兵粮丸
			cur_box_num = tonumber(cur_vipData.m_vip_props2_num)
			next_box_num = tonumber(next_vipData.m_vip_props2_num)
		end	
		local label_add = tostring("+"..tonumber(next_box_num-cur_box_num)..localizable.commonBuy_vipLv_add_desc)
		tolua.cast(self.m_dlgview:getNode("label_next_level_add"), "CCLabelTTF"):setString(label_add)
	end

end

function CommonBuyItemDialog:initHandle()
	self.m_handler = LuaEventHandler:create(function(fn, table, a1, a2, x, y)
		local r
		if fn == "cellSize" then
			-- Return cell size
			-- a1 is cell index (-1 means default size, in cocos2d-x version below 2.1.3, it's always -1)
			r = self.m_cellsize;
		elseif fn == "cellAtIndex" then
			-- Return CCTableViewCell, a1 is cell index (zero based), a2 is dequeued cell (maybe nil)
			-- Do something to create cell and change the content
			local cell = CommonBuyItemCellView:create();
			cell:setIndex(a1)
			cell:setItemType(self.m_itemType)
			cell:setItemIdData(self.m_itemList[a1+1])
			if a1 == self.m_selectedIndex then
				cell:setSelected(true)
			else
				cell:setSelected(false)
			end
			cell:setCellSize(self.m_cellsize)
			cell:loadCCBI()
			cell:initUI()
			self.cellNodes[a1+1] = cell
			if not a2 then
				a2 = CCTableViewCell:create()
			else			
				a2:removeAllChildrenWithCleanup(true)
			end
			a2:addChild(cell);
			cell:setTag(100);
			r = a2
		elseif fn == "numberOfCells" then
			r = #self.m_itemList
		-- Cell events:
		elseif fn == "cellTouched" then			-- A cell was touched, a1 is cell that be touched. This is not necessary.	
			local cell = self.cellNodes[a1:getIdx() + 1]
			if cell ~= nil and cell:getNode("sprite_bottom_light"):boundingBox():containsPoint(m_touchPoint) then
			    self.m_selectedIndex = cell:getIndex()
			    --litao_2014.6.21_触摸结束更新选中id
				--self:CheckItemCount()
				self.m_targetItemId = self.m_itemList[self.m_selectedIndex+1]
				self.m_tableview:reloadData()
			end
		elseif fn == "cellTouchBegan" then		-- A cell is touching, a1 is cell, a2 is CCTouch
			m_touchPoint = a2:getLocation()
			
			local cell = self.cellNodes[a1:getIdx() + 1]
			m_touchPoint = cell:convertToNodeSpace(m_touchPoint)	
			
			r = true
		elseif fn == "cellTouchEnded" then		-- A cell was touched, a1 is cell, a2 is CCTouch
			r = true
		elseif fn == "cellHighlight" then		-- A cell is highlighting, coco2d-x 2.1.3 or above
		elseif fn == "cellUnhighlight" then		-- A cell had been unhighlighted, coco2d-x 2.1.3 or above
			r = true;
		elseif fn == "cellWillRecycle" then		-- A cell will be recycled, coco2d-x 2.1.3 or above
		end
		return r
	end)
end

function CommonBuyItemDialog:BindControl()
	CommonBuyItemDialog.m_selfview:setTouchEnabled(true)
	CommonBuyItemDialog.m_selfview:registerScriptTouchHandler(CommonBuyItemDialog_onTouch,false,kCCMenuHandlerPriority-1,true)
	CommonBuyItemDialog.m_selfview:setTouchMode(0) 
	
	self.m_btn_use = tolua.cast(self.m_dlgview:getNode("btn_use"), "CCControlButton")
	self.m_btn_buy = tolua.cast(self.m_dlgview:getNode("btn_buy"), "CCControlButton")
	self.m_btn_pay = tolua.cast(self.m_dlgview:getNode("btn_pay"), "CCControlButton")
	self.m_btn_close = tolua.cast(self.m_dlgview:getNode("closeButton"), "CCControlButton")
	
	-- 初始化按钮
	self.m_btn_use:setTouchPriority(CommonBuyItemDialog.m_touchPriority);
	self.m_dlgview:handleButtonEvent(self.m_btn_use, function(button, event)
		self:ClickUse();
		return nil
	end, CCControlEventTouchUpInside)

	self.m_btn_buy:setTouchPriority(CommonBuyItemDialog.m_touchPriority);
	self.m_dlgview:handleButtonEvent(self.m_btn_buy, function(button, event)
		self:ClickBuy();
		return nil
	end, CCControlEventTouchUpInside)
	
	self.m_btn_pay:setTouchPriority(CommonBuyItemDialog.m_touchPriority);
	self.m_dlgview:handleButtonEvent(self.m_btn_pay, function(button, event)
		self:ClickPay();
		return nil
	end, CCControlEventTouchUpInside)
	
	self.m_btn_close:setTouchPriority(CommonBuyItemDialog.m_touchPriority);
	self.m_dlgview:handleButtonEvent(self.m_btn_close, function(button, event)
		self:CloseView();
		return nil
	end, CCControlEventTouchUpInside)
end

function CommonBuyItemDialog:ClickBuy()
	local itemInfo
	self.m_targetItemId = self.m_itemList[self.m_selectedIndex+1]
	if self.m_itemType == kConsumableTypeItem then
		itemInfo = tolua.cast(CTradeMgr:instance():GetConsumByIDForLua(self.m_targetItemId), "ConsumeInfo")
		--if itemInfo.m_bagnum > 0 then
		--	self:UseItem(self.m_targetItemId)
		--else
			if (itemInfo.m_needgold > 0 and CPlayerDataMgr:instance():GetPlayerInfoData().m_gold >= itemInfo.m_needgold) or
				(itemInfo.m_needsilver > 0 and CPlayerDataMgr:instance():GetPlayerInfoData().m_silver >= itemInfo.m_needsilver) then
				self:BuyItem(self.m_targetItemId)
			else
				if itemInfo.m_needgold > 0 then
					GetMainMenu():ShowTextTip(localizable.fightBoss_god_not_enough_desc, -1);
					--通用付费引导
					local prePayLayer = createObj(ui_commonPrePay)
					GetMainMenu():GetModelLayer():AddDialog(prePayLayer.node_, 3)
				end
				
				if itemInfo.m_needsilver > 0 then
					GetMainMenu():ShowTextTip(localizable.ui_attribute_silver_not_enough, -1);
				end
				
				self:CloseView()
			end
		--end
	else
		itemInfo = tolua.cast(CTradeMgr:instance():GetGiftByIDForLua(self.m_targetItemId), "Struct_Giftinfo")
		if (itemInfo.m_price_gold > 0 and CPlayerDataMgr:instance():GetPlayerInfoData().m_gold >= itemInfo.m_price_gold) or
				(itemInfo.m_price_silver > 0 and CPlayerDataMgr:instance():GetPlayerInfoData().m_silver >= itemInfo.m_price_silver) then
			self:BuyGift(self.m_targetItemId)
		else
			if itemInfo.m_price_gold > 0 then
				GetMainMenu():ShowTextTip(localizable.fightBoss_god_not_enough_desc, -1);
				--通用付费引导
				local prePayLayer = createObj(ui_commonPrePay)
				GetMainMenu():GetModelLayer():AddDialog(prePayLayer.node_, 3)
			end
			
			if itemInfo.m_price_silver > 0 then
				GetMainMenu():ShowTextTip(localizable.ui_attribute_silver_not_enough, -1);
			end
			
			self:CloseView()
		end
	end
end

function CommonBuyItemDialog:ClickUse()
	--litao_2014.6.21
	local itemId = tonumber(self.m_targetItemId)
	--info
	local playerMgr = CPlayerDataMgr:instance()
	local playerData = playerMgr:GetPlayerInfoData()
	local uid = playerData.m_uid
	local urlpath = GetUrlNormalHeader(uid,1800,"rl_w_propuse")
	urlpath = AddData(urlpath,"Goodsid",itemId)
	GetMainMenu():ShowLoadingDlg();
	CCHttpRequest:openWithUserData(urlpath, kHttpPost, p, "query=param1&other=params"):sendWithHandler(
	function(res, hnd)
		GetMainMenu():CloseLoadding();
		local p = res:getHttpRequest():getUserData()
		local resData = res:getResponseData()
		local code = res:getResponseCode()
		local xfile = xml.parse(resData)
		local item = xfile:find("RENLONG")
		local retcode = item.code
			if item == nil then
			return;
		end
		if retcode == "0" then	
			if CTradeMgr:instance():UseConsumeItemByID(resData, self.m_targetItemId) == true then
				GetMainMenu():GetCurrentSubMenu():InitNormalHeader()
				GetMainMenu():ShowTextTip(localizable.commonBuy_use_success_desc, -1)
				--更新数量litao_2014.6.20_使用不关闭
				--self:CloseView()
				--刷新数量
				self.m_tableview:reloadData()
			end
		else
			GetMainMenu():ShowErrorTip(retcode,-1)
		end	
	end)
end

function CommonBuyItemDialog:BuyItem(itemId)
	local playerMgr = CPlayerDataMgr:instance()
	local playerData = playerMgr:GetPlayerInfoData()
	local uid = playerData.m_uid
	local urlpath = GetUrlNormalHeader(uid,1700,"rl_w_shopbuy")
	urlpath = AddData(urlpath,"Goodsid",itemId)
	urlpath = AddData(urlpath,"Count",1)
	GetMainMenu():ShowLoadingDlg();
	CCHttpRequest:openWithUserData(urlpath, kHttpPost, p, "query=param1&other=params"):sendWithHandler(
	function(res, hnd)
		GetMainMenu():CloseLoadding();
		local p = res:getHttpRequest():getUserData()
		local resData = res:getResponseData()
		local code = res:getResponseCode()
		local xfile = xml.parse(resData)
		local item = xfile:find("RENLONG")
		local retcode = item.code
		if item == nil then
			return;
		end
		if retcode == "0" then	
			local awardXML = xfile:find("shopbuy")					
			local costyb = awardXML["costyb"]
			local costyz = awardXML["costyz"]
			playerMgr:AddGold(-costyb)
			playerMgr:AddSilver(-costyz)
			
			local count = tolua.cast(CTradeMgr:instance():GetConsumByIDForLua(self.m_targetItemId), "ConsumeInfo").m_bagnum
			CTradeMgr:instance():SetConsumItemCountByID(self.m_targetItemId, count+1)
			--刷新数量
			self.m_tableview:reloadData()
			--使用
			--self:UseItem(self.m_targetItemId)
		else
			GetMainMenu():ShowErrorTip(retcode,-1);
		end				
	end)
end

function CommonBuyItemDialog:BuyGift(itemId)
	local playerMgr = CPlayerDataMgr:instance()
	local playerData = playerMgr:GetPlayerInfoData()
	local uid = playerData.m_uid
	local urlpath = GetUrlNormalHeader(uid,1701,"rl_w_shopbuy")
	urlpath = AddData(urlpath,"Packageid",itemId)
	urlpath = AddData(urlpath,"Count",1)
	GetMainMenu():ShowLoadingDlg();
	CCHttpRequest:openWithUserData(urlpath, kHttpPost, p, "query=param1&other=params"):sendWithHandler(
	function(res, hnd)
		GetMainMenu():CloseLoadding();
		local p = res:getHttpRequest():getUserData()
		local resData = res:getResponseData()
		local code = res:getResponseCode()
		local xfile = xml.parse(resData)
		local item = xfile:find("RENLONG")
		local retcode = item.code
			if item == nil then
			return;
		end
		if retcode == "0" then	
			if CTradeMgr:instance():UseGiftPackItem(resData) == true then
				GetMainMenu():GetCurrentSubMenu():InitNormalHeader()
				GetMainMenu():ShowTextTip(localizable.commonBuy_use_success_desc, -1)
				self:CloseView()
			end
		else
			GetMainMenu():ShowErrorTip(retcode,-1);
		end				
	end)
end

function CommonBuyItemDialog:ClickPay()
	local puchaseLayer = createObj(ui_purchaseLayer)
	GetMainMenu():GetModelLayer():AddDialog(puchaseLayer.node_, 3);
end

function CommonBuyItemDialog:CloseView()    
	CommonBuyItemDialog.m_selfview:removeFromParentAndCleanup(true);
end

function ShowCommonBuyItemDialog(itemType,itemId1,itemId2,itemId3)
	CommonBuyItemDialog.m_itemType = itemType
	CommonBuyItemDialog.m_itemList = {}
	
	if itemId1 > 0 then
		CommonBuyItemDialog.m_itemList[#CommonBuyItemDialog.m_itemList+1] = itemId1
	end
	
	if itemId2 > 0 then
		CommonBuyItemDialog.m_itemList[#CommonBuyItemDialog.m_itemList+1] = itemId2
	end
	
	if itemId3 > 0 then
		CommonBuyItemDialog.m_itemList[#CommonBuyItemDialog.m_itemList+1] = itemId3
	end
	
	local view = CommonBuyItemDialog:create();	
	CommonBuyItemDialog.m_selfview = view
	view:initUI()
	GetMainMenu():AddDialog(view);
end

