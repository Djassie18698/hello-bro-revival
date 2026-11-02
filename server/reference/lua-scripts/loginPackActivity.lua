require "util/localizable"
require "LuaSubView.lua"
require "loginCellView.lua"
require "RLRequest"
require "LuaXml.lua"

local actType = "1"
local actId = "1"
local m_touchPoint


loginPackView=class(
	"loginPackView",
    function()
        return LuaSubView:create() 
    end
)

local m_selfview={};
function loginPackView:create()
	local view = loginPackView.new();
	view:SetClearPlist(false);
	m_selfview = view;
	return view;
end

function loginPackView:initTable()
	local activityView = GetActivityView()
	local contentNode = activityView:GetNodeContent()
	local contentsize = contentNode:getContentSize()
	
	self.cellNodes = {}
	self.m_cellsize = CCSize(681,266)
	self:initHandle();
	self.m_tableview = LuaTableView:createWithHandler(self.m_handler, CCSizeMake(contentsize.width,contentsize.height))
	self.m_tableview:setDirection(kCCScrollViewDirectionVertical)
	self.m_tableview:setVerticalFillOrder(kCCTableViewFillTopDown)
	self.m_tableview:reloadData()
	contentNode:addChild(self.m_tableview)
	
	local fromNaruto = activityView:GetFromNaruto()
	if fromNaruto == true then
		local point = self.m_tableview:getContentOffset()
		point.y = point.y + 266*(7-1);
		self.m_tableview:setContentOffset(point.x,point.y)
		return
	end
end

function loginPackView:initHandle()
	self.m_handler = LuaEventHandler:create(function(fn, table, a1, a2, x, y)
		local r
		if fn == "cellSize" then
			-- Return cell size
			-- a1 is cell index (-1 means default size, in cocos2d-x version below 2.1.3, it's always -1)
			r = self.m_cellsize;
		elseif fn == "cellAtIndex" then
			-- Return CCTableViewCell, a1 is cell index (zero based), a2 is dequeued cell (maybe nil)
			-- Do something to create cell and change the content
			local cell = loginCellView:create();
			cell:setIndex(a1);
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
			r = #loginPackData
		-- Cell events:
		elseif fn == "cellTouched" then			-- A cell was touched, a1 is cell that be touched. This is not necessary.	
			local cell = self.cellNodes[a1:getIdx() + 1]
			if cell:getNode("node_btn_container"):boundingBox():containsPoint(m_touchPoint) then
			    loginPackView:clickGetPack(cell:getIndex())
			end
			
			for i = 1, 4 do
				local itemName = "sprite_item"..i
				local id = "login_drop"..i.."id"
				if cell:getNode(itemName):boundingBox():containsPoint(m_touchPoint) then
					if 	loginPackData[cell:getIndex()+1][id] ~= 0	then
						CGameObjElement:ShowDropByID(loginPackData[cell:getIndex()+1][id])
					end
				end
			end
			
		elseif fn == "cellTouchBegan" then		-- A cell is touching, a1 is cell, a2 is CCTouch
			m_touchPoint = a2:getLocation()
			
			local cell = self.cellNodes[a1:getIdx() + 1]
			m_touchPoint = cell:convertToNodeSpace(m_touchPoint)	
			local rect = cell:getNode("node_btn_container"):boundingBox()
            if rect:containsPoint(m_touchPoint) then
                cell:getNode("sprite_btn_get"):setScale(1.1)
				--cell:getNode("sprite_btn_get2"):setVisible(true)
            end
			r = true
		elseif fn == "cellTouchEnded" then		-- A cell was touched, a1 is cell, a2 is CCTouch
			r = true
		elseif fn == "cellHighlight" then		-- A cell is highlighting, coco2d-x 2.1.3 or above
		elseif fn == "cellUnhighlight" then		-- A cell had been unhighlighted, coco2d-x 2.1.3 or above
			local cell = self.cellNodes[a1:getIdx() + 1]
			cell:getNode("sprite_btn_get"):setScale(1.0)
			--cell:getNode("sprite_btn_get2"):setVisible(false)
			r = true;
		elseif fn == "cellWillRecycle" then		-- A cell will be recycled, coco2d-x 2.1.3 or above
		end
		return r
	end)
end

-- 刷新数据
function loginPackView:freshTableData()
	if self.m_tableview ~= nil then
		local offset = self.m_tableview:getContentOffset()
		self.m_tableview:reloadData()
		self.m_tableview:setContentOffset(offset.x, offset.y)
	end
	return nil
end

function loginPackView:clickGetPack(index)
	CSoundMgr:instance():PlayEffect(SOUND_BUTTON)
	
	if loginData[index+1] == 0 then
		local playerMgr = CPlayerDataMgr:instance()
		local playerData = playerMgr:GetPlayerInfoData()
		local uid = playerData.m_uid
		local urlpath = GetUrlNormalHeader(uid,9100,"rl_w_activity")
		urlpath = AddData(urlpath, "ActType", actType)
		urlpath = AddData(urlpath, "ActID", actId)
		urlpath = AddData(urlpath, "SubID", index+1)
		local p = CCPoint:new()
		p.x = index
		GetMainMenu():ShowLoadingDlg()
		CCHttpRequest:openWithUserData(urlpath, kHttpPost, p, "query=param1&other=params"):sendWithHandler(
		function(res, hnd)
			GetMainMenu():CloseLoadding()
			local p = res:getHttpRequest():getUserData()
			local index = tolua.cast(p, "CCPoint").x
			local resData = res:getResponseData()
			local code = res:getResponseCode()
			local xfile = xml.parse(resData)
			local item = xfile:find("RENLONG")
			if item == nil then
				return nil
			end
			local retcode = item.code
			if retcode == "0" then
				local awardXML = xfile:find("award")
				ShowAward(awardXML)
				
				if newsCount > 0 then
					newsCount = newsCount - 1
				end
				--将开关上的新消息标志刷新By_litao_2014.1.13
				if ui_activityPopupLayer.getPopupActivityData then
					for k, v in pairs(ui_activityPopupLayer.getPopupActivityData) do
						if v.icon == "activity1" and tonumber(v.newscount) > 0 then
							v.newscount = tonumber(v.newscount) - 1
							CPlayerDataMgr:instance():SetActivityNews("activity1", v.newscount)
							break
						end
					end
				end
				--------------------------------------------
				CPlayerDataMgr:instance():SetActivityNewsNum(newsCount)
				GetActTopBarView():Refresh()
				
				loginData[index+1] = 2
				m_selfview:freshTableData()
			else
				GetMainMenu():ShowErrorTip(retcode,-1)
			end
		end)
	end
	return nil
end

function InitLoginPackView()
	local view = loginPackView:create();
	view:initTable();
	local activityView = GetActivityView()
	local contentNode = activityView:GetNodeContent()
	contentNode:addChild(view)
	view:setTag(123);
end

InitLoginPackView()
