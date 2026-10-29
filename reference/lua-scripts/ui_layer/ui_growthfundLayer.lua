--玩家累计充值活动
--chenchun
---------------------------------------------
module("ui_growthfundLayer", package.seeall)
baseClass(layer_base_t, ui_growthfundLayer)

function init(self)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	self.contentNode_ = GetActivityView():GetNodeContent()
	self.contentSize_ = self.contentNode_:getContentSize()
	local ccbiAttrTable = {name="activity/growth_fund.ccbi", size=self.contentSize_}
	layer_base_t.init(self, true, ccbiAttrTable)

	--vip_litao
	self.m_vipframes={[0] = "vip_015",[1]="vip_003",[2]="vip_004",[3]="vip_005",[4]="vip_006",[5]="vip_007",[6]="vip_008",[7]="vip_009",[8]="vip_010",[9]="vip_011",[10]="vip_012",[11]="vip_013",[12]="vip_014",[13]="vip_s_13",[14] = "vip_s_14",[15] = "vip_s_15",[16]="vip_s_16",[17]="vip_s_17",[18]="vip_s_18"}

	self.fundData = {}
	self.gotIds = {}
	self.money = 0
	self.cellNodes = {}
	--self:createTestData()
	self:init_ui()
	self:init_binding_event()
end

function init_ui(self)
	if self.proxy_ ~= nil then		
		self.label_fund_desc1 = tolua.cast(self.proxy_:getNode("label_fund_desc1"), "CCLabelTTF")
		self.label_fund_desc2 = tolua.cast(self.proxy_:getNode("label_fund_desc2"), "CCLabelTTF")
		self.label_fund_desc3 = tolua.cast(self.proxy_:getNode("label_fund_desc3"), "CCLabelTTF")
		self.label_fund_desc4 = tolua.cast(self.proxy_:getNode("label_fund_desc4"), "CCLabelTTF")
		self.label_fund_desc5 = tolua.cast(self.proxy_:getNode("label_fund_desc5"), "CCLabelTTF")
		self.label_value1 = tolua.cast(self.proxy_:getNode("label_val_1"), "CCLabelBMFont")
		self.label_value2 = tolua.cast(self.proxy_:getNode("label_val_2"), "CCLabelBMFont")
		self.label_value3 = tolua.cast(self.proxy_:getNode("label_val_3"), "CCLabelBMFont")

		--vip info_litao_8.30
		self.spr_vip = tolua.cast(self.proxy_:getNode("spr_vip"), "CCSprite")

		self.label_fund_desc1:setVisible(false);
		self.label_fund_desc2:setVisible(false);
		self.label_fund_desc3:setVisible(false);
		self.label_fund_desc4:setVisible(false);
		self.label_fund_desc5:setVisible(false);
		self.label_value1:setVisible(false);
		self.label_value2:setVisible(false);
		self.label_value3:setVisible(false);

		self.node_cell_node = tolua.cast(self.proxy_:getNode("node_gift_cell_node"), "CCNode")
		self.node_content_node = tolua.cast(self.proxy_:getNode("node_table_content"), "CCLayer")
		
		local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 1, protocol.URL_GROWTH_FUND_R)
		GetMainMenu():ShowLoadingDlg();	
		CCHttpRequest:open(urlpath, kHttpPost,"query=param1&other=params"):sendWithHandler(
			function(res, hnd)
				GetMainMenu():CloseLoadding()

				local resData = res:getResponseData()
				--cclog("1111---%s",resData)
				local code = res:getResponseCode()
				local xfile = xml.parse(resData)
				local item = xfile:find("RENLONG")
				local retcode = item.code
				if retcode == "0" then
					local preview = item:find("preview");
					local price = preview.buycash;
					self.fund_price = tonumber(price);
					local mult = preview.multiple;
					local totalaward = preview.totalcash;
					self.buy_state = tonumber(preview.buystate);

					--vip lv _litao_8.30
					self.need_vip_lv = tonumber(preview.needvip)
					local frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(self.m_vipframes[self.need_vip_lv])
					if frame ~= nil then
						self.spr_vip:setDisplayFrame(frame)
					end

					self.label_fund_desc1:setString(localizable.ui_growth_tips1);
					self.label_value1:setString(tostring(price));
					self.label_fund_desc2:setString(localizable.ui_growth_tips2);
					--[[
					local desc1posx,desc1posy = self.label_fund_desc1:getPosition();
					local desc1size = self.label_fund_desc1:getContentSize();
					local sizew = desc1size.width;
					local val1size = self.label_value1:getContentSize();
					self.label_value1:setPosition(ccp(desc1posx+desc1size.width,desc1posy));
					self.label_fund_desc2:setPosition(ccp(desc1posx+desc1size.width+val1size.width,desc1posy));
					--]]
					
					self.label_fund_desc3:setString(localizable.ui_growth_tips3);
					self.label_value2:setString(tostring(mult));
					self.label_fund_desc4:setString(localizable.ui_growth_tips4);
					self.label_value3:setString(tostring(totalaward));
					self.label_fund_desc5:setString(localizable.ui_border_gold);
					--[[
					local desc3posx,desc3posy = self.label_fund_desc3:getPosition();
					local desc3size = self.label_fund_desc3:getContentSize();
					local value2size = self.label_value2:getContentSize();
					local desc4size = self.label_fund_desc4:getContentSize();
					local value3size = self.label_value3:getContentSize();

					self.label_value2:setPosition(ccp(desc3posx+desc3size.width,desc3posy));
					self.label_fund_desc4:setPosition(ccp(desc3posx+desc3size.width+value2size.width,desc3posy));
					self.label_value3:setPosition(ccp(desc3posx+desc3size.width+value2size.width+desc4size.width,desc3posy));
					self.label_fund_desc5:setPosition(ccp(desc3posx+desc3size.width+value2size.width+desc4size.width+value3size.width,desc3posy));
					--]]
					self.label_fund_desc1:setVisible(true);
					self.label_fund_desc2:setVisible(true);
					self.label_fund_desc3:setVisible(true);
					self.label_fund_desc4:setVisible(true);
					self.label_fund_desc5:setVisible(true);
					self.label_value1:setVisible(true);
					self.label_value2:setVisible(true);
					self.label_value3:setVisible(true);

					local Items = item:find("fundlist")

					if Items then
						for i = 1, #Items do
							self.fundData[i] = {id=tonumber(Items[i].id),
							level=tonumber(Items[i].level), 
							title=localizable.ui_growth_tips5..tostring(Items[i].level), 
							desc=string.format(localizable.ui_growth_tips6, tostring(Items[i].level), tostring(Items[i].cash)),
							count=tonumber(Items[i].cash);
							status=tonumber(Items[i].state)}
						end
					end
					self:createFundTableView()
				else
					GetMainMenu():ShowErrorTip(retcode,-1);
				end
			end)

	end
end


function init_binding_event(self)
	if self.proxy_ ~= nil then
		local function buy_fund_callback(btn, event)
			if self.buy_state == 1 then
				GetMainMenu():ShowTextTip(localizable.ui_growth_tips7,-1);
				return nil;
			end
			--cclog("self.playerData_.m_viplevel---%d",self.playerData_.m_viplevel);
			if tonumber(self.playerData_.m_viplevel) < self.need_vip_lv then
				GetMainMenu():ShowErrorTip(315,-1);
				return nil;
			end
			local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 2, protocol.URL_GROWTH_FUND_R)
		GetMainMenu():ShowLoadingDlg();	
		CCHttpRequest:open(urlpath, kHttpPost,"query=param1&other=params"):sendWithHandler(
			function(res, hnd)
				GetMainMenu():CloseLoadding()

				local resData = res:getResponseData()
				--cclog("1111---%s",resData)
				local code = res:getResponseCode()
				local xfile = xml.parse(resData)
				local item = xfile:find("RENLONG")
				local retcode = item.code
				if retcode == "0" then
					local preview = item:find("preview");
					self.buy_state = preview.buystate;
					local Items = item:find("fundlist")

					if Items then
						for i = 1, #Items do
							self.fundData[i] = {id=tonumber(Items[i].id),
							level=tonumber(Items[i].level), 
							title=tostring(Items[i].level) .. localizable.ui_growth_tips5, 
							desc = string.format(localizable.ui_growth_tips6, tostring(Items[i].level), tostring(Items[i].cash)),
							count=tonumber(Items[i].cash);
							status=tonumber(Items[i].state)}
						end
					end
					self:reLoadTable()
					GetMainMenu():ShowTextTip(localizable.ui_growth_tips8,-1);
				else
					GetMainMenu():ShowErrorTip(retcode,-1);
				end
			end)
		end
		local function btn_charge_callback(btn,event)
			local puchaseLayer = createObj(ui_purchaseLayer)
			GetMainMenu():GetModelLayer():AddDialog(puchaseLayer.node_, 3)
		end
		self.btn_charge = tolua.cast(self.proxy_:getNode("btn_charge"), "CCControlButton")
		self.btn_buy_fund = tolua.cast(self.proxy_:getNode("btn_buy_fund"), "CCControlButton")

		self.proxy_:handleControlEvent(self.btn_buy_fund, buy_fund_callback, CCControlEventTouchUpInside)
		self.proxy_:handleControlEvent(self.btn_charge, btn_charge_callback, CCControlEventTouchUpInside)
	end
end

function onNodeCleanup(self)
	--cclog("1111---002")
	if self.proxy_ then
    	self.proxy_:release()
    end
    layer_base_t.onNodeCleanup(self)
end

--local funtion
function createFundTableView(self, data)
	-- body
	if self.fundTableView == nil then
		self.gift_cellsize = self.node_cell_node:getContentSize()
		self.gift_tableContentSize = self.node_content_node:getContentSize()
		self:initfundTableHandle()
		self.fundTableView = LuaTableView:createWithHandler(self.fundTableViewHandler, CCSizeMake(self.gift_tableContentSize.width, self.gift_tableContentSize.height))
		self.fundTableView:setDirection(kCCScrollViewDirectionVertical)
		self.fundTableView:setVerticalFillOrder(kCCTableViewFillTopDown)
		self.node_content_node:addChild(self.fundTableView)
	else
		local pos = self.fundTableView:getContentOffset();
		self.fundTableView:reloadData();
		self.fundTableView:setContentOffset(pos.x,pos.y);
	end
end
function reLoadTable(self)
	self:init_ui();
end
function initfundTableHandle(self)
	self.fundTableViewHandler = LuaEventHandler:create(function(fn, table, a1, a2, x, y)
		local r
		if fn == "cellSize" then
			r = self.gift_cellsize
		elseif fn == "cellAtIndex" then
    		local nodeLayer = createObj(ui_growthfundCell, self.gift_cellsize, self.fundData[a1 + 1])
    		self.cellNodes[a1 + 1] = nodeLayer
			if not a2 then
				a2 = CCTableViewCell:create()
				nodeLayer.node_:setTag(100)
				a2:addChild(nodeLayer.node_)
			else
				a2:removeAllChildrenWithCleanup(true)
				nodeLayer.node_:setAnchorPoint(ccp(0.5,0.5))
				nodeLayer.node_:setPosition(self.gift_cellsize.width / 2, self.gift_cellsize.height / 2)
				nodeLayer.node_:ignoreAnchorPointForPosition(false)
				nodeLayer.node_:setTag(100)
        		a2:addChild(nodeLayer.node_)
			end
			r = a2
		elseif fn == "numberOfCells" then
			r = #self.fundData;
		    -- Cell events:
		elseif fn == "cellTouched" then			-- A cell was touched, a1 is cell that be touched. This is not necessary.
			local cellIndex = a1:getIdx() + 1
			if self.cellNodes[cellIndex].btn_scale_sprite:boundingBox():containsPoint(self.m_touchPoint) then
				self.cellNodes[cellIndex]:btn_get_fund_1(self)
			end
			local cellIndex = a1:getIdx() + 1
			self.cellNodes[cellIndex].btn_scale_sprite:setScale(1.0);
		elseif fn == "cellTouchBegan" then		-- A cell is touching, a1 is cell, a2 is CCTouch
			self.m_touchPoint = a2:getLocation()
			local cellIndex = a1:getIdx() + 1
			local cell = a1:getChildByTag(100);
			self.m_touchPoint = cell:convertToNodeSpace(self.m_touchPoint)
			
			if self.cellNodes[cellIndex].btn_scale_sprite:boundingBox():containsPoint(self.m_touchPoint) then
				self.cellNodes[cellIndex].btn_scale_sprite:setScale(1.1);
			end
			r = true
		elseif fn == "cellTouchEnded" then		-- A cell was touched, a1 is cell, a2 is CCTouch
			r = true
			local cellIndex = a1:getIdx() + 1
			self.cellNodes[cellIndex].btn_scale_sprite:setScale(1.0);
		elseif fn == "cellHighlight" then		-- A cell is highlighting, coco2d-x 2.1.3 or above
		elseif fn == "cellUnhighlight" then		-- A cell had been unhighlighted, coco2d-x 2.1.3 or above
			local cellIndex = a1:getIdx() + 1
			self.cellNodes[cellIndex].btn_scale_sprite:setScale(1.0);
		elseif fn == "cellWillRecycle" then		-- A cell will be recycled, coco2d-x 2.1.3 or above
		end
		return r
	end)
end

--创建测试数据
function createTestData(self)
	self.fundData = {}
	for i = 1, 3 do
		--status---1 ->> 已经领取
		self.fundData[i] = {id=i, level=15,title="15级成长基金",status=1,desc="到达15级可以领取",count=i*50}
	end
end