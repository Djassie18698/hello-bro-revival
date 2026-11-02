--descriptioin:月卡签到
--company: xckoo
--author: liyongkang
--date: 2015-10-13
---------------------------------------------
--签到状态说明  status
--0	未签到
--1	已签到
--2	充值升vip后可补充签到
--3	不能签到
---------------------------------------------

module("ui_monthSign", package.seeall)
require("ui_layer/ui_monthSignCell")
require("ui_layer/ui_monthSignDesc")
baseClass(layer_base_t, ui_monthSign)

local monthName = {'January', 'February','March','April','May','June','July','August','September','October','November','December'}

function init(self)
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()

	self.contentNode_ = GetActivityView():GetNodeContent()
	self.contentSize_ = self.contentNode_:getContentSize()

	local ccbiAttrTable = {name="activity/MonthSign.ccbi", size=self.contentSize_}
	layer_base_t.init(self, true, ccbiAttrTable)

    self.datas = {};
    self.cellNodes ={};
    self.m_playerDatas ={};
    self.array ={};
    --self:createTestData();
	self:init_ui()
    self:init_binding_event()
end

function createTestData(self)

   
    self.teststring = {
    [1] ={sign_id ="1",need_vip ="1",award_id ="1537",award_name ="x1",award_icon ="props_035",award_state = "0"},
    [2] ={sign_id ="2",need_vip ="2",award_id ="1306",award_name ="x2",award_icon ="props_129",award_state = "1"},
    [3] ={sign_id ="3",need_vip ="3",award_id ="1537",award_name ="x3",award_icon ="props_035",award_state = "2"},
    [4] ={sign_id ="4",need_vip ="4",award_id ="1306",award_name ="x4",award_icon ="props_170",award_state = "3"},
    [5] ={sign_id ="5",need_vip ="5",award_id ="1537",award_name ="x24",award_icon ="props_035",award_state = "0"},
    [6] ={sign_id ="6",need_vip ="6",award_id ="1306",award_name ="x21",award_icon ="props_035",award_state = "1"},
    [7] ={sign_id ="7",need_vip ="7",award_id ="1537",award_name ="x2",award_icon ="props_170",award_state = "2"},
    [8] ={sign_id ="8",need_vip ="8",award_id ="1306",award_name ="x2",award_icon ="props_035",award_state = "3"},
    [9] ={sign_id ="9",need_vip ="9",award_id ="1537",award_name ="x2",award_icon ="props_035",award_state = "0"},
    [10] ={sign_id ="10",need_vip ="10",award_id ="1306",award_name ="x2",award_icon ="props_170",award_state = "1"},
    [11] ={sign_id ="11",need_vip ="11",award_id ="1537",award_name ="x2",award_icon ="props_035",award_state = "2"},
    [12] ={sign_id ="12",need_vip ="12",award_id ="1306",award_name ="x2",award_icon ="props_035",award_state = "3"},
    [13] ={sign_id ="13",need_vip ="13",award_id ="1537",award_name ="x2",award_icon ="props_170",award_state = "0"},
    [14] ={sign_id ="14",need_vip ="14",award_id ="1306",award_name ="x1",award_icon ="props_170",award_state = "0"},
    [15] ={sign_id ="15",need_vip ="15",award_id ="1537",award_name ="x3",award_icon ="props_035",award_state = "0"},    
    }
    self.array ={}
    for i=1,3 do
        self.array[i] = {}
          for j=1,4 do
              self.array[i][j] = self.teststring[i*j]
          end
    end    
end


function init_ui(self)
	if self.proxy_ ~= nil then
        --月份
	    self.label_month =  tolua.cast(self.proxy_:getNode("label_month"), "CCLabelTTF")
        
        --当前签到次数
  	    self.label_sign_number = tolua.cast(self.proxy_:getNode("label_sign_number"), "CCLabelBMFont")
        --签到规则
        self.button_sign = tolua.cast(self.proxy_:getNode("button_sign"), "CCControlButton")

	    self.node_tablecontent = tolua.cast(self.proxy_:getNode("node_tablecontent"), "CCNode")
        self.node_cardcontent = tolua.cast(self.proxy_:getNode("node_cardcontent"), "CCNode")
        ---[[
		--月签信息
		local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 7, "rl_x_small_activity")
		urlpath = AddData(urlpath, "page", 1)
		cclog("monorank111----%s", urlpath)
		GetMainMenu():ShowLoadingDlg()
		CCHttpRequest:open(urlpath, kHttpPost,"query=param1&other=params"):sendWithHandler(
			function(res, hnd)
				GetMainMenu():CloseLoadding()
				local resData = res:getResponseData()
				cclog("monorank_rank_data----%s", resData)
				local code = res:getResponseCode()
				local xfile = xml.parse(resData)
				local item = xfile:find("RENLONG")
				local retcode = item.code
				if retcode == "0" then                    
                    local item_user = xfile:find("user")
                    if item_user then
                        --当前签到天数
                        self.days = item_user:find("days")[1]
                        self.label_sign_number:setString(self.days)
                    end
                   
                    local item_month = xfile:find("month")
                    if item_month then
                        self.curr_month = item_month.mth
                        self.label_month:setString(monthName[tonumber(self.curr_month)])
                        for i = 1, #item_month do
							local tempitem = {}
							tempitem.sign_id = tonumber(item_month[i]:find("sign_id")[1]) --id
							tempitem.need_vip = tonumber(item_month[i]:find("need_vip")[1]) --需要的VIP
							tempitem.award_id = item_month[i]:find("award_id")[1] --掉落ID
							tempitem.award_icon = item_month[i]:find("award_icon")[1] --掉落的ICON
                            tempitem.award_num = item_month[i]:find("award_num")[1] --掉落的数量
							tempitem.status = tonumber(item_month[i]:find("status")[1]) --当前签到状态
							table.insert(self.m_playerDatas, tempitem)
						end
                        --每4个分一组  tabelview lua不能实现多行多列

                        local  rowCount =  math.modf(#self.m_playerDatas / 4)
                        --#self.m_playerDatas / 4 ;
	                    if  #self.m_playerDatas%4 >0 then	                    
		                    rowCount = rowCount + 1
	                    end

                         for i=1,rowCount do
                         self.array[i] = {}
                              for j=1,4 do
                                  self.array[i][j] = self.m_playerDatas[4*(i-1) + j]
                              end
                          end    
                         --创建tabelview
                         self:createRankTableView()
                    end
              
				else
					--GetMainMenu():ShowTextTip(tostring(text.text_config[tonumber(retcode)].description), -1)
                     GetMainMenu():ShowErrorTip(tonumber(retcode), -1)
				end
			end)
		--]]
        
	   
	end
end

function init_binding_event(self)
    
    local function onBtnSign(btn)
        --cclog("onBtnSign")      
        local monthLayer = createObj(ui_monthSignDesc)
		local size1 = GetMainMenu():GetModelLayer():getContentSize()
		monthLayer.node_:setAnchorPoint(ccp(0.5, 0.5))

		monthLayer.node_:setPosition(size1.width / 2, size1.height / 2)
		GetMainMenu():GetModelLayer():addChild(monthLayer.node_)
                                  
    end    

    self.button_sign:setTouchPriority(kCCMenuHandlerPriority - 1)
    self.proxy_:handleButtonEvent(self.button_sign, function(button, event)
		onBtnSign(button)
		return nil
	end, CCControlEventTouchUpInside)

end


function createRankTableView(self)
	-- body
	if self.rankTableView == nil then
		self.rank_cellsize = self.node_cardcontent:getContentSize()
		self.rank_tableContentSize = self.node_tablecontent:getContentSize()
		self:initRankTableHandle()
		self.rankTableView = LuaTableView:createWithHandler(self.rankTableViewHandler, CCSizeMake(self.rank_tableContentSize.width, self.rank_tableContentSize.height))
		self.rankTableView:setDirection(kCCScrollViewDirectionVertical)
		self.rankTableView:setVerticalFillOrder(kCCTableViewFillTopDown)
		self.rankTableView:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.node_tablecontent:addChild(self.rankTableView)
    else
        self.rankTableView:reloadData()
	end
end

function initRankTableHandle(self)
	self.rankTableViewHandler = LuaEventHandler:create(function(fn, table, a1, a2, x, y)
		local r
		if fn == "cellSize" then
			r = self.rank_cellsize;
		elseif fn == "cellAtIndex" then
    		local nodeLayer = createObj(ui_monthSignCell, self.rank_cellsize, self.array[a1+1])--self.m_playerDatas[a1 + 1])
			self.cellNodes[a1+1] = nodeLayer
            if not a2 then
				a2 = CCTableViewCell:create()
				a2:addChild(nodeLayer.node_)
			else
				a2:removeAllChildrenWithCleanup(true)
        		a2:addChild(nodeLayer.node_)
			end
            nodeLayer.node_:setTag(100);
			r = a2
		elseif fn == "numberOfCells" then		
           r =  #self.array
		elseif fn == "cellTouched" then			-- A cell was touched, a1 is cell that be touched. This is not necessary.
            local cell_index = a1:getIdx() + 1
			local _layer = self.cellNodes[cell_index]

            --无法使用按钮 通过图片位置判断点击位置
            for i = 1, 4 do	
                --显示当前物品			
				if  _layer["sprite_icon_bg_0"..tostring(i)]:boundingBox():containsPoint(self.m_touchPoint) 
                    and (tonumber( self.array[cell_index][i].status )~= 0  and tonumber(self.array[cell_index][i].status )~= 2) then
					if tonumber(self.array[cell_index][i].award_id )~= 0  then
						CGameObjElement:ShowDropByID(self.array[cell_index][i].award_id )
                        cclog("cellTouched")
					end
                --签到
                elseif _layer["sprite_icon_bg_0"..tostring(i)]:boundingBox():containsPoint(self.m_touchPoint) 
                    and (tonumber( self.array[cell_index][i].status) == 0 or tonumber( self.array[cell_index][i].status) == 2 )then 
                        --cclog("qiandao")
                        --修改状态                      
                        self:onClickQianDao(self.array[cell_index][i].sign_id ,cell_index,i)
                        --                        
				end
			end

            self.m_touchPoint = nil;

		elseif fn == "cellTouchBegan" then		-- A cell is touching, a1 is cell, a2 is CCTouch 
            self.m_touchPoint = a2:getLocation()			
			local cell = self.cellNodes[a1:getIdx() + 1]
			self.m_touchPoint = cell.node_:convertToNodeSpace(self.m_touchPoint)	
			r = true
		elseif fn == "cellTouchEnded" then		-- A cell was touched, a1 is cell, a2 is CCTouch
			r = true
		elseif fn == "cellHighlight" then		-- A cell is highlighting, coco2d-x 2.1.3 or above
		elseif fn == "cellUnhighlight" then		-- A cell had been unhighlighted, coco2d-x 2.1.3 or above
		elseif fn == "cellWillRecycle" then		-- A cell will be recycled, coco2d-x 2.1.3 or above	
        end
		return r
	end)
end

function onClickQianDao(self,SignId,cell_index,i)
    	local urlpath = GetUrlNormalHeader(self.playerData_.m_uid, 8, "rl_x_small_activity")
		urlpath = AddData(urlpath, "SignId",tonumber(SignId))
		cclog("monorank111----%s", urlpath)
		GetMainMenu():ShowLoadingDlg()
		CCHttpRequest:open(urlpath, kHttpPost,"query=param1&other=params"):sendWithHandler(
			function(res, hnd)
				GetMainMenu():CloseLoadding()
				local resData = res:getResponseData()
				cclog("monorank_rank_data----%s", resData)
				local code = res:getResponseCode()
				local xfile = xml.parse(resData)
				local item = xfile:find("RENLONG")
				local retcode = item.code
				if retcode == "0" then                   
                    local awardXml = xfile:find("award")
                    if awardXml then
					    self.m_awardXml = {}
					    self.m_awardXml = awardXml  
                        ShowAward(self.m_awardXml)                    
                    end  
					if self.array[cell_index][i].status ~= 2 then
                    	 self.days = self.days + 1
                         self.label_sign_number:setString(self.days)    
                    end
                    self.array[cell_index][i].status = 1                                       
                    self.rankTableView:reloadData()     
				else
					--GetMainMenu():ShowTextTip(tostring(text.text_config[tonumber(retcode)].description), -1)
                     GetMainMenu():ShowErrorTip(tonumber(retcode), -1)
				end
		end)

        
		--]]   
end



function onNodeCleanup(self)
	if self.proxy_ then
    	self.proxy_:release()
    end
    layer_base_t.onNodeCleanup(self)
end