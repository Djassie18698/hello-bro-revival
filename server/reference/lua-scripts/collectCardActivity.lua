
require "LuaSubView.lua"
require "collectCellView.lua"
require "RLRequest"
require "LuaXml.lua"
require "CommonDialogView"
require "util/localizable"

local m_touchPoint


collectCardView=class(
	"collectCardView",
    function()
        return LuaSubView:create() 
    end
)

local m_selfview={};
function collectCardView:create()
	local view = collectCardView.new();
	view:SetClearPlist(false);
	m_selfview = view;
	return view;
end

function collectCardView:initTable()
	local activityView = GetActivityView()
	local contentNode = self:getNode("node_contentview")
	local contentsize = contentNode:getContentSize()
	
	self.cellNodes = {}
	
	if self.m_tableview == nil then
		self.m_cellsize = CCSize(681,266)
		self:initHandle();
		self.m_tableview = LuaTableView:createWithHandler(self.m_handler, CCSizeMake(contentsize.width,contentsize.height))
		self.m_tableview:setDirection(kCCScrollViewDirectionVertical)
		self.m_tableview:setVerticalFillOrder(kCCTableViewFillTopDown)
		contentNode:addChild(self.m_tableview)
	end
	self:freshTableData()
		
	local title = self.m_listdata[1]:find("title")[1]
	local content = self.m_listdata[1]:find("content")[1]
	tolua.cast(self:getNode("label_title"), "CCLabelTTF"):setString(title)
	tolua.cast(self:getNode("label_content"), "CCLabelTTF"):setString(content)

	--剩余时间_litao_2014.5.28
	self.label_remain_time = tolua.cast(self:getNode("label_remain_time"), "CCLabelBMFont")
	self.deal_time = 0

	--剩余时间倒计时_litao_2014.5.28
	local function updateRemainTime(fDeltaTime)
		--			
		self.deal_time = self.deal_time + fDeltaTime
		--每秒递减
		if self.deal_time > 1 then
			local intPart, floatPart = math.modf(self.deal_time)
			self.m_remain_time = self.m_remain_time - intPart
			--剩余时间显示
			local timeStr = nil
			if self.m_remain_time > 0 then
				timeStr = tools.convertTimeElectronicWatch(self.m_remain_time, 3)
			else
				timeStr = 0
				self.label_remain_time:unscheduleUpdate()
			end
			self.label_remain_time:setString(timeStr)		
			self.deal_time = floatPart
		end
	end
	self.label_remain_time:scheduleUpdateWithPriorityLua(updateRemainTime, 0)	
	self.label_remain_time:setString(tools.convertTimeElectronicWatch(self.m_remain_time, 3))
end

function collectCardView:initUI()	
	self:LoadCCBI("activity/CollectCardTableView.ccbi",self.m_contentsize);	
	self:LoadList();
end

function collectCardView:initHandle()
	self.m_handler = LuaEventHandler:create(function(fn, table, a1, a2, x, y)
		local r
		if fn == "cellSize" then
			-- Return cell size
			-- a1 is cell index (-1 means default size, in cocos2d-x version below 2.1.3, it's always -1)
			r = self.m_cellsize;
		elseif fn == "cellAtIndex" then
			-- Return CCTableViewCell, a1 is cell index (zero based), a2 is dequeued cell (maybe nil)
			-- Do something to create cell and change the content
			local cell = collectCellView:create();
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
			if cell:getNode("sprite_btn_get"):boundingBox():containsPoint(m_touchPoint) then
				if cell:cangetPack() == true then
					local cellType = cell:getCellData():find("type")[1]
					if 	cellType == "2"	then
						collectCardView:clickGetPack(cell:getIndex())
					else
						collectCardView:clickExchangePack(cell:getIndex())
					end
				else
					CSoundMgr:instance():PlayEffect(SOUND_BUTTON)
					GetMainMenu():ShowTextTip(localizable.collect_cell_can_not_get_pack_desc,-1);
				end
			    
			end
			
		    cell:checkItemClick(m_touchPoint)
		elseif fn == "cellTouchBegan" then		-- A cell is touching, a1 is cell, a2 is CCTouch
			m_touchPoint = a2:getLocation()
			
			local cell = self.cellNodes[a1:getIdx() + 1]
			m_touchPoint = cell:convertToNodeSpace(m_touchPoint)	
			local rect = cell:getNode("sprite_btn_get"):boundingBox()
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

function collectCardView:LoadList()
		local playerMgr = CPlayerDataMgr:instance()
		local playerData = playerMgr:GetPlayerInfoData()
		local uid = playerData.m_uid
		local urlpath = GetUrlNormalHeader(uid,1,"rl_r_comm")
		GetMainMenu():ShowLoadingDlg();
		CCHttpRequest:openWithUserData(urlpath, kHttpPost, p, "query=param1&other=params"):sendWithHandler(
		function(res, hnd)
			local p = res:getHttpRequest():getUserData()
			local resData = res:getResponseData();			
			local code = res:getResponseCode()
			local xfile = xml.parse(resData)
			local item = xfile:find("RENLONG")
			if item == nil then
				GetMainMenu():CloseLoadding();
				return nil
			end
			local retcode = item.code
			if retcode == "0" then		
				--剩余时间的节点_litao_2014.5.28
				local _basic = item:find("basic")
				if _basic then
					self.m_remain_time = tonumber(_basic:find("remain")[1])
				end
				--卡信息	
				self.m_listdata = item:find("collectlist");	
				self:initTable();		
				GetMainMenu():CloseLoadding();				
			else
				GetMainMenu():ShowErrorTip(retcode,-1);
				GetMainMenu():CloseLoadding();
			end
			
		end)
end


-- 刷新数据
function collectCardView:freshTableData()
	if self.m_tableview ~= nil then
		local offset = self.m_tableview:getContentOffset()
		self.m_tableview:reloadData()
		self.m_tableview:setContentOffset(offset.x, offset.y)
	end
	return nil
end

function collectCardView:getTargetNotInUseByDataId(id, type)
	local objlist = CPlayerDataMgr:instance():GetObjectList(type)
	local target = nil
	for i = 1, objlist:size() do
		if objlist[i]:IsUsingInAnyTeam() == false and objlist[i]:GetDataID() == id then
			if target == nil then
				target = objlist[i]
			else
				if objlist[i]:GetReincarnationLevel() < target:GetReincarnationLevel() then
					target = objlist[i]
				elseif objlist[i]:GetReincarnationLevel() == target:GetReincarnationLevel() then
					if objlist[i]:GetLevel() < target:GetLevel() then
						target = objlist[i]
					end
				end
			end
		end
	end
	return target
end

function collectCardView:clickGetPack(index)
	CSoundMgr:instance():PlayEffect(SOUND_BUTTON)
	
	local collectid = m_selfview.m_listdata[index+1]:find("id")[1]
	local playerMgr = CPlayerDataMgr:instance()
	local playerData = playerMgr:GetPlayerInfoData()
	local uid = playerData.m_uid
	local urlpath = GetUrlNormalHeader(uid,1,"rl_w_comm")
	urlpath = AddData(urlpath, "Collectid", collectid)
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
			GetMainMenu():CloseLoadding();
			return nil
		end
		local retcode = item.code
		if retcode == "0" then
			local decls = xfile:find("delcards")
			for i = 1, #decls do
				local bagid = decls[i].bagindex
				CPlayerDataMgr:instance():RemoveObjByID(bagid)
			end
			local awardXML = xfile:find("award")
			ShowAward(awardXML)
			m_selfview:LoadList()
		else
			GetMainMenu():ShowErrorTip(retcode,-1)
		end
	end)

	return nil
end

function collectCardView:clickExchangePack(index)
	CSoundMgr:instance():PlayEffect(SOUND_BUTTON)
	
	local dlg = CommonDialogView.create()
	CommonDialogView.m_selfview = dlg;
	dlg:SetTitle(localizable.collect_cell_exchange_confirm_tip_desc)
	dlg:SetDescription(localizable.collect_cell_exchange_confirm_desc)
	dlg:loadCCBI();
	dlg:SetConfirmHandler(
		function()
			self:clickGetPack(index)
		end)
	dlg:initUI()
	GetMainMenu():GetModelLayer():AddDialog(dlg, 3);

	return nil
end

function collectCardView:setViewSize(size)
	self.m_contentsize = size;
end

function InitCollectCardView()
	local view = collectCardView:create();
	local activityView = GetActivityView()
	local contentNode = activityView:GetNodeContent()
	view.m_tableview = nil
	view:setViewSize(contentNode:getContentSize())
	view:initUI();
	contentNode:addChild(view)
	view:setTag(123);
end

InitCollectCardView()
