require "LuaSubView.lua"
require "InGameNoticeCellView.lua"
require ("util/protocol")
require "util/localizable"

InGameNoticeListView=class(
	"InGameNoticeListView",
    function()
        return CCLayer:create()
    end
)
InGameNoticeListView.m_touchPriority = kCCMenuHandlerPriority-1;
function InGameNoticeListView:create()
	local view = InGameNoticeListView.new();
	InGameNoticeListView.m_selfview = view;
	return view;
end
function onTouch(event, x, y)
     if event == "began" then
        return true
    end
end

function InGameNoticeListView:initUI()

	local view = LuaSubView:create();
	local win = CCDirector:sharedDirector():getWinSize();
	view:LoadCCBI("sub_ui/SystemNotice.ccbi",CCSize(768,win.height));
	self:addChild(view)
	view:setPosition(CCPoint(win.width / 2, win.height / 2));
	self.m_dlgview = view;
	
	self.cellNodes = {}

	self:BindControl();
	self:LoadList();
	self:setTouchEnabled(true)
	self:setTouchMode(0)
	self:registerScriptTouchHandler(onTouch,false,InGameNoticeListView.m_touchPriority,true)
end
function InGameNoticeListView:initTable()
	self:initHandle();
	self.m_contentview = self.m_dlgview:getNode("node_content");
	local contentsize = self.m_contentview:getContentSize();
	self.m_cellsize = self.m_dlgview:getNode("node_cellcontent"):getContentSize();
	local tableview = LuaTableView:createWithHandler(self.m_handler, CCSizeMake(contentsize.width,contentsize.height))
	tableview:setDirection(kCCScrollViewDirectionVertical);
	tableview:setVerticalFillOrder(kCCTableViewFillTopDown);
	tableview:reloadData()
	self.m_contentview:addChild(tableview);
	tableview:setTouchPriority(InGameNoticeListView.m_touchPriority);
end
function InGameNoticeListView:BindControl()
	local btnclose = tolua.cast(self.m_dlgview:getNode("btn_close"), "CCControlButton");
    btnclose:setTouchPriority(InGameNoticeListView.m_touchPriority);
	self.m_dlgview:handleButtonEvent(btnclose, function(button, event)
		self:CloseView();
		return nil
	end, CCControlEventTouchUpInside)
end
function InGameNoticeListView:CloseView()
	-- body
	InGameNoticeListView.m_selfview:removeFromParentAndCleanup(true);
	
	local info = CUserGuideManager:instance():CheckUserGuide();
	if info ~= nil then
		if info.levelStep:GetLevel() == 5 and info.condition.stepNo == 1 then
			CUserGuideManager:instance():NextStep()
			return
		end
		
		if info.levelStep:GetLevel() == 10 and info.condition.stepNo == 1 then
			CUserGuideManager:instance():NextStep()
			return
		end
		
		if info.levelStep:GetLevel() == 20 and info.condition.stepNo == 1 then
			CUserGuideManager:instance():NextStep()
			return
		end
		
		if info.levelStep:GetLevel() == 25 and info.condition.stepNo == 1 then
			CUserGuideManager:instance():NextStep()
			return
		end
		
		if info.levelStep:GetLevel() == 30 and info.condition.stepNo == 1 then
			CUserGuideManager:instance():NextStep()
			return
		end
		
		if info.levelStep:GetLevel() == 35 and info.condition.stepNo == 1 then
			CUserGuideManager:instance():NextStep()
			return
		end
		
		if info.levelStep:GetLevel() == 40 and info.condition.stepNo == 1 then
			CUserGuideManager:instance():NextStep()
			return
		end
	end
end
function InGameNoticeListView:initHandle()
	self.m_handler = LuaEventHandler:create(function(fn, table, a1, a2, x, y)
		local r
		if fn == "cellSize" then
			-- Return cell size
			-- a1 is cell index (-1 means default size, in cocos2d-x version below 2.1.3, it's always -1)
			r = self.m_cellsize;
		elseif fn == "cellAtIndex" then
			-- Return CCTableViewCell, a1 is cell index (zero based), a2 is dequeued cell (maybe nil)
			-- Do something to create cell and change the content
			local cell = InGameNoticeCellView:create();
			cell:setData(self.m_listdata[a1+1]);
			cell:setSize(self.m_cellsize);
			cell:loadCellCCBI();
			cell:setIndex(a1+1);
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
			if cell:getBtnRect():containsPoint(m_touchPoint) then
			    local sp = cell:getData();
				local funcs = sp:find("gopage")[1];
                --GetMainMenu():ChangeToSub(E_ACTIVITYVIEW);
                --GetActivityView():SetCurrentActIndex(7);
                --;
				CSoundMgr:instance():PlayEffect(SOUND_BUTTON)
				loadstring(funcs)();
                self:CloseView();
			end
		elseif fn == "cellTouchBegan" then		-- A cell is touching, a1 is cell, a2 is CCTouch
			m_touchPoint = a2:getLocation()

			local layer = self.cellNodes[a1:getIdx() + 1]
			local card = layer;
			m_touchPoint = layer:convertToNodeSpace(m_touchPoint)
			local rect = card:getBtnRect();
            if rect:containsPoint(m_touchPoint) then
				card:getSprite():setScale(1.05);
			end
			r = true
		elseif fn == "cellTouchEnded" then		-- A cell was touched, a1 is cell, a2 is CCTouch
			r = true
		elseif fn == "cellHighlight" then		-- A cell is highlighting, coco2d-x 2.1.3 or above
		elseif fn == "cellUnhighlight" then		-- A cell had been unhighlighted, coco2d-x 2.1.3 or above
			local card = self.cellNodes[a1:getIdx() + 1]
            card:getSprite():setScale(1.0);
			r = true;
		elseif fn == "cellWillRecycle" then		-- A cell will be recycled, coco2d-x 2.1.3 or above
		end
		return r
	end)
end
function InGameNoticeListView:LoadList()
		self.m_listdata = nil;
		local areaid = CNetUser:instance():GetAreaID();
		--calc view news id
		local playerMgr = CPlayerDataMgr:instance()
		local playerData = playerMgr:GetPlayerInfoData()
		local uid = playerData.m_uid
        local urlpath = GetInGameNewsNormalHeader(uid, 2, protocol.URL_R_NOTICE)    
		GetMainMenu():ShowLoadingDlg()
		CCHttpRequest:open(urlpath, kHttpPost,"query=param1&other=params"):sendWithHandler(
		function(res, hnd)
			local resData = res:getResponseData()
			local code = res:getResponseCode()
			local xfile = xml.parse(resData)
			local item = xfile:find("RENLONG")
			if item == nil then			
				GetMainMenu():CloseLoadding()
				return nil
			end
			local retcode = item.code
			if retcode == "0" then
                local oinnews_info_data = item:find("innnernews");
                local size = #oinnews_info_data;
				for k=1,size do
					local visual = oinnews_info_data[k]:find("way")[1];
					local list = Split(visual,'|');
					for i = 1, #list
					do
						if tonumber(list[i]) == areaid then
							if self.m_listdata == nil then
								self.m_listdata={};
								self.m_listdata[1] = oinnews_info_data[k];
							else
								self.m_listdata[#self.m_listdata+1] = oinnews_info_data[k];
							end
							break;
						end
					end
				end
				self:initTable();
			end			
			GetMainMenu():CloseLoadding()
		end)

end
function showInGameNoticeView()
	--暂时关闭内公告
	-- local view = InGameNoticeListView:create();
	-- view:initUI();
	-- GetMainMenu():GetModelLayer():addChild(view);
	-- view:setTag(100);
end