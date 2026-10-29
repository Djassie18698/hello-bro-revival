require "LuaSubView.lua"
require "VipCellView.lua"
require "RLRequest"
require "LuaXml.lua"
require "util/localizable"
VipListView=class(
	"VipListView",
    function()
        return LuaSubView:create() 
    end
)
VipListView.m_vipframes={'vip_015','vip_003','vip_004','vip_005','vip_006','vip_007','vip_008','vip_009','vip_010','vip_011','vip_012','vip_013','vip_014','vip_s_13','vip_s_14','vip_s_15','vip_s_16','vip_s_17','vip_s_18'}
VipListView.m_viptips=localizable.vip_list_vipTips;

local m_selfview={};
function VipListView:create()
	local view = VipListView.new();
	m_selfview = view;
	view:SetClearPlist(false);
	return view;
end

function VipListView:initUI()	
    self.m_currexp = 0;
	self.m_needexp = 1000;
	self:LoadCCBI("store/VipListView.ccbi",self.m_contentsize);	
	tolua.cast(self:getNode("label_vipdesc"), "CCLabelTTF"):setString(VipListView.m_viptips);
	self.m_cellsize = self:getNode("node_cardcontent"):getContentSize();
	local vipicon = self:getNode("sprite_viplevel");
	local playerMgr = CPlayerDataMgr:instance();
	local viplevel = playerMgr:GetVipLevel();
	local frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(VipListView.m_vipframes[viplevel+1]);
	tolua.cast(self:getNode("sprite_viplevel"),"CCSprite"):setDisplayFrame(frame);	
	local expratio = self.m_currexp /self.m_needexp;
	self:getNode("sprite_viplevelbar"):setScaleX(expratio);	
	local textexp = self.m_currexp..'/'..self.m_needexp;
	tolua.cast(self:getNode("label_vipratio"), "CCLabelBMFont"):setString(textexp);

	--vip right btn
	self.btn_vip_right = tolua.cast(self:getNode("vip_right_btn"), "CCControlButton")
	
	self:LoadList();
end

function VipListView:init_binding_event()
	local function showVipRight()
		--
		local data = {}
		data.cur_exp = tonumber(self.m_currexp)
		data.need_exp = tonumber(self.m_needexp)
		local _len = #self.m_listdata
		data.need_show = tonumber(self.m_listdata[_len]:find("vip")[1])
		local vip_right_layer = createObj(ui_vipRightInfoView, self, data)
		local _size = GetMainMenu():GetModelLayer():getContentSize()
		vip_right_layer.node_:setAnchorPoint(ccp(0.5, 0.5))
		vip_right_layer.node_:setPosition(ccp(_size.width * 0.5, _size.height * 0.5))
		GetMainMenu():GetModelLayer():addChild(vip_right_layer.node_)
	end
	--
	self:handleControlEvent(self.btn_vip_right, showVipRight, CCControlEventTouchUpInside)
end

function VipListView:initTable()
	local playerMgr = CPlayerDataMgr:instance();
	local viplevel = playerMgr:GetVipLevel();
	local frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(VipListView.m_vipframes[viplevel+1]);
	tolua.cast(self:getNode("sprite_viplevel"),"CCSprite"):setDisplayFrame(frame);	
	local expratio = self.m_currexp /self.m_needexp;
	self:getNode("sprite_viplevelbar"):setScaleX(expratio);	
	local textexp = self.m_currexp..'/'..self.m_needexp;
	tolua.cast(self:getNode("label_vipratio"), "CCLabelBMFont"):setString(textexp)
	--next exp gold
	local need_gold = tonumber(self.m_needexp - self.m_currexp)
	--next vip
	local next_vip = viplevel + 2
	if next_vip > #self.m_vipframes then
		next_vip = #self.m_vipframes
		need_gold = 0
	end
	local next_frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(VipListView.m_vipframes[next_vip])
	if next_frame ~= nil then
		tolua.cast(self:getNode("sprite_next_viplevel"), "CCSprite"):setDisplayFrame(next_frame)
	end
	--need_gold
	tolua.cast(self:getNode("label_next_vipdesc"), "CCLabelTTF"):setString(string.format(localizable.vip_list_need_gold, tostring(need_gold/10)))
	
	self.cellNodes = {}
	local contentsize = self:getNode("node_vipcontent"):getContentSize();
	self:initHandle();	
	self.m_tableview = LuaTableView:createWithHandler(self.m_handler, CCSizeMake(contentsize.width,contentsize.height))
	self.m_tableview:setDirection(kCCScrollViewDirectionVertical)
	self.m_tableview:setVerticalFillOrder(kCCTableViewFillTopDown)
	self.m_tableview:reloadData()
	self:getNode("node_vipcontent"):addChild(self.m_tableview);
end
function VipListView:initHandle()
	self.m_handler = LuaEventHandler:create(function(fn, table, a1, a2, x, y)
		local r
		if fn == "cellSize" then
			-- Return cell size
			-- a1 is cell index (-1 means default size, in cocos2d-x version below 2.1.3, it's always -1)
			r = self.m_cellsize;
		elseif fn == "cellAtIndex" then
			-- Return CCTableViewCell, a1 is cell index (zero based), a2 is dequeued cell (maybe nil)
			-- Do something to create cell and change the content
			local cell = VipCellView:create();
			cell:setIndex(a1);
			cell:setCellData(self.m_listdata[a1+1]);
			cell:setCellSize(self.m_cellsize);
			cell:loadCCBI();
			cell:initUI();
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
			r = #self.m_listdata;
		-- Cell events:
		elseif fn == "cellTouched" then			-- A cell was touched, a1 is cell that be touched. This is not necessary.	
			local cell = self.cellNodes[a1:getIdx() + 1]
			local _index = cell:getIndex()
			cell:getNode("sprite_btn_buyit"):setScale(1)
			if cell:getNode("sprite_btn_buyit"):boundingBox():containsPoint(m_touchPoint) then
			    local carddata = cell:getCellData()
			    local canbuy = carddata:find("canbuy")[1]		    
				---[[
			    if tonumber(canbuy) == 2 then			    
				    VipListView:BuyItem(carddata, _index)
				elseif tonumber(canbuy) == 0 then
					GetMainMenu():ShowTextTip(localizable.vip_list_vipLv_notEnough,-1)
				end
				--]]
			end
			--点击详情
			local gift_rect = cell:getNode("sprite_goodstype"):boundingBox()
			if gift_rect:containsPoint(m_touchPoint) then
				--cclog("touch cell %d", tonumber(_index + 1))
				VipListView:ShowGiftDetail(_index + 1)
			else
				--cclog("don't touch")
			end
		elseif fn == "cellTouchBegan" then		-- A cell is touching, a1 is cell, a2 is CCTouch
			m_touchPoint = a2:getLocation()
			
			local layer = self.cellNodes[a1:getIdx() + 1]
			local card = layer;
			m_touchPoint = layer:convertToNodeSpace(m_touchPoint)	

			--缩放
			---[[
			local rect = layer:getNode("sprite_btn_buyit"):boundingBox()
            if rect:containsPoint(m_touchPoint) then
                layer:getNode("sprite_btn_buyit"):setScale(1.1)
            end
			--]]
			--[[
			local rect = layer:getNode("sprite_btn_buyit"):boundingBox()
			local cardadta = card:getCellData();
		    local canbuy = cardadta:find("canbuy")[1];
		    if tonumber(canbuy) == 0 then	
                if rect:containsPoint(m_touchPoint) then
                    local size = tolua.cast(card:getNode("sprite_btn_buyit"), "CCScale9Sprite"):getContentSize();
                    local btn = CCSprite:createWithSpriteFrameName("shop_10")
                    card:getNode("sprite_btn_buyit"):addChild(btn)				
                    btn:setAnchorPoint(ccp(0,0))
                    btn:setPosition(ccp(0,0))
                    btn:setTag(123)
                end
			end
			--]]
			r = true
		elseif fn == "cellTouchEnded" then		-- A cell was touched, a1 is cell, a2 is CCTouch
			r = true
		elseif fn == "cellHighlight" then		-- A cell is highlighting, coco2d-x 2.1.3 or above
		elseif fn == "cellUnhighlight" then		-- A cell had been unhighlighted, coco2d-x 2.1.3 or above
			local card = self.cellNodes[a1:getIdx() + 1]
			local cardadta = card:getCellData();
		    local canbuy = cardadta:find("canbuy")[1];
		    if tonumber(canbuy) == 0 then	
                if card:getNode("sprite_btn_buyit"):getChildByTag(123) ~= nil then
                    card:getNode("sprite_btn_buyit"):removeChildByTag(123,true)
                end
			end
			r = true;
		elseif fn == "cellWillRecycle" then		-- A cell will be recycled, coco2d-x 2.1.3 or above
		end
		return r
	end)
end 

--点击礼包详情
function VipListView:ShowGiftDetail(_index)
	if _index < 1 then
		return nil
	end
	--gift detail
	local view = createObj(ui_giftDetailView, self, _index)
	local currentlayer = GetMainMenu():GetModelLayer()
	currentlayer:addChild(view.node_)
end

-- 刷新数据
function VipListView:freshTableData()
	if m_selfview.m_tableview ~= nil then
		local offset = m_selfview.m_tableview:getContentOffset()
		m_selfview.m_tableview:reloadData()
		m_selfview.m_tableview:setContentOffset(offset.x, offset.y)
	end
	return nil
end

function VipListView:BuyItem(itemndata, _index)
		CSoundMgr:instance():PlayEffect(SOUND_BUTTON)
		
		local playerMgr = CPlayerDataMgr:instance()
		local playerData = playerMgr:GetPlayerInfoData()
		local uid = playerData.m_uid
		local urlpath = GetUrlNormalHeader(uid,4000,"rl_w_vipshopbuy");
		urlpath=AddData(urlpath,"GiftId",itemndata.id); 
		GetMainMenu():ShowLoadingDlg();
		CCHttpRequest:openWithUserData(urlpath, kHttpPost, p, "query=param1&other=params"):sendWithHandler(
		function(res, hnd)
			GetMainMenu():CloseLoadding();
			local p = res:getHttpRequest():getUserData()
			local resData = res:getResponseData();
			local code = res:getResponseCode()
			local xfile = xml.parse(resData)
			local item = xfile:find("RENLONG")
			if item == nil then
			    return;
			end
			local retcode = item.code
			if retcode == "0" then	
				local awardXML = xfile:find("award")		
				ShowAward(awardXML);			
				GetMainMenu():ShowTextTip(localizable.ui_buy_success_tips,-1);			
				local gold = playerData.m_gold;
				playerMgr:SetGold(gold-itemndata:find("price")[1]);
				
				GetMainMenu():GetCurrentSubMenu():InitNormalHeader();
				--购买成功更新列表
				itemndata[3][1] = 1
				m_selfview.m_listdata[_index + 1] = itemndata
				m_selfview:freshTableData()
			else
				GetMainMenu():ShowErrorTip(retcode,-1)
			end			
		end)
end

function VipListView:LoadList()
		local playerMgr = CPlayerDataMgr:instance()
		local playerData = playerMgr:GetPlayerInfoData()
		local uid = playerData.m_uid
		local urlpath = GetUrlNormalHeader(uid,4000,"rl_r_vipshop")
		cclog("%s",urlpath)
		GetMainMenu():ShowLoadingDlg();
		CCHttpRequest:openWithUserData(urlpath, kHttpPost, p, "query=param1&other=params"):sendWithHandler(
		function(res, hnd)
			GetMainMenu():CloseLoadding();
			local p = res:getHttpRequest():getUserData()
			local resData = res:getResponseData();			
			local code = res:getResponseCode()
			print(resData)
			local xfile = xml.parse(resData)
			local item = xfile:find("RENLONG")
			if item == nil then
				return nil
			end
			local retcode = item.code
			if retcode == "0" then			
				playerMgr:SetVipLevel(item:find("lv")[1]);
				self.m_currexp = item:find("exp")[1];
				self.m_needexp = item:find("lvexp")[1];
				self.m_listdata = item:find("vipshoplist");	
				self:initTable();			
			else
				GetMainMenu():ShowErrorTip(retcode,-1);
			end
			
		end)
end

function VipListView:setViewSize(size)
	self.m_contentsize = size;
end

function InitVipListView(view)
	local node = view:getNode("node_tablecontent");
	local view = VipListView:create();
	local size = node:getContentSize();
	view:setViewSize(size);
	view:initUI();
	view:init_binding_event();
	node:addChild(view);
	view:setTag(100);
end