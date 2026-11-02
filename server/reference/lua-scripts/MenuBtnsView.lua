require "LuaSubView.lua"
require "MenuBtnsData"
require "MenuBtnsCellView"
MenuBtnsView=class(
	"MenuBtnsView",
    function()
        return LuaSubView:create() 
    end
)
local m_selfview={};
local m_messagecount="0";
local m_reincarnationCount=0
local m_messagecell=nil;
local m_reincarnationcell=nil

function MenuBtnsView:create()
	local view = MenuBtnsView.new();
	m_selfview = view;
	return view;
end
function MenuBtnsView:setViewSize(size)
	self.m_cellsize = size;
end
function MenuBtnsView:setContentView(view)
	self.m_contentview = view;
end

function MenuBtnsView:initUI()	
	self.cellNodes = {}
	
	self:initTable()
end
function MenuBtnsView:initTable()	
	self:initHandle();
	local contentsize = self.m_contentview:getContentSize();
	self.m_tableview = LuaTableView:createWithHandler(self.m_handler, CCSizeMake(contentsize.width,contentsize.height))
	self.m_tableview:setDirection(kCCScrollViewDirectionHorizontal)
	--self.m_tableview:setVerticalFillOrder(kCCTableViewFillTopDown)
	self.m_tableview:reloadData()
	self.m_contentview:addChild(self.m_tableview);
	self:initUIBtns();
end
function MenuBtnsView:initUIBtns()
	local pBackgroundButton = CCScale9Sprite:createWithSpriteFrameName("com_top_bk_05");
	local pBackgroundHighlightedButton = CCScale9Sprite:createWithSpriteFrameName("com_top_bk_05")
	pBackgroundButton:setRotation(180);
	pBackgroundHighlightedButton:setRotation(180);
	
	local size = self.m_contentview:getContentSize()
	local pButton = CCControlButton:create(pBackgroundButton)
	pButton:setBackgroundSpriteForState(pBackgroundHighlightedButton, CCControlStateHighlighted)
	pButton:setTitleColorForState(ccc3(255,255,255), CCControlStateHighlighted)
	self.m_contentview:addChild(pButton);
	pButton:setPosition(ccp(-10,30));
	pButton:setPreferredSize(27,32);
	local function touchLeftAction()
		local pt = self.m_tableview:minContainerOffset();
		local point = self.m_tableview:getContentOffset();
		if point.x > pt.x then
		    point.x = point.x-self.m_cellsize.width;
		    self.m_tableview:setContentOffsetInDuration(point,0.2);
		end
	end
	
	pButton:addHandleOfControlEvent(touchLeftAction,CCControlEventTouchUpInside);	
	
	
	local pBackgroundButtonright = CCScale9Sprite:createWithSpriteFrameName("com_top_bk_05");
	local pBackgroundHighlightedButtonright = CCScale9Sprite:createWithSpriteFrameName("com_top_bk_05")

	local pButtonright = CCControlButton:create(pBackgroundButtonright)
	pButtonright:setBackgroundSpriteForState(pBackgroundHighlightedButtonright, CCControlStateHighlighted)
	pButtonright:setTitleColorForState(ccc3(255,255,255), CCControlStateHighlighted)
	self.m_contentview:addChild(pButtonright);
	pButtonright:setPosition(ccp(size.width+10,30));
	pButtonright:setPreferredSize(27,32);
	local function touchRightAction()
		local pt = self.m_tableview:maxContainerOffset();
		local point = self.m_tableview:getContentOffset();
		if point.x < pt.x then
		    point.x =point.x + self.m_cellsize.width;
		    self.m_tableview:setContentOffsetInDuration(point,0.2);
		end
	end
	
	pButtonright:addHandleOfControlEvent(touchRightAction,CCControlEventTouchUpInside);	
end
function MenuBtnsView:initHandle()
	self.m_handler = LuaEventHandler:create(function(fn, table, a1, a2, x, y)
		local r
		if fn == "cellSize" then
			-- Return cell size
			-- a1 is cell index (-1 means default size, in cocos2d-x version below 2.1.3, it's always -1)
			r = self.m_cellsize;
		elseif fn == "cellAtIndex" then
			-- Return CCTableViewCell, a1 is cell index (zero based), a2 is dequeued cell (maybe nil)
			-- Do something to create cell and change the content
			local cell = MenuBtnsCellView:create();
			cell:setData(MeunBtnsData[a1+1]);
			cell:setSize(self.m_cellsize);
			cell:initUI();
			cell:setIndex(a1+1);
			self.cellNodes[a1+1] = cell
			if not a2 then
				a2 = CCTableViewCell:create()
			else			
				a2:removeAllChildrenWithCleanup(true)
			end
			
			a2:addChild(cell);
			cell:setTag(100);
			if a1==1 then
				m_messagecell = cell;
				initmessageCell()
			elseif a1==6 then
				m_reincarnationcell = cell
				initreincarnationCell()
			end
			r = a2
		elseif fn == "numberOfCells" then
			r = #MeunBtnsData;
		-- Cell events:
		elseif fn == "cellTouched" then			-- A cell was touched, a1 is cell that be touched. This is not necessary.	
			local cell = self.cellNodes[a1:getIdx() + 1]
			if cell:getBtnRect():containsPoint(m_touchPoint) then
				CSoundMgr:instance():PlayEffect(SOUND_BUTTON)
			    local sp = cell:getData();
				loadstring(sp["actionscript"])();				
			end
		elseif fn == "cellTouchBegan" then		-- A cell is touching, a1 is cell, a2 is CCTouch
			m_touchPoint = a2:getLocation()
			
			local layer = self.cellNodes[a1:getIdx() + 1]
			local card = layer;
			m_touchPoint = layer:convertToNodeSpace(m_touchPoint)	
			local rect = card:getBtnRect();
            if rect:containsPoint(m_touchPoint) then
				card:getChildByTag(120):setScale(1.05);
			end
			r = true
		elseif fn == "cellTouchEnded" then		-- A cell was touched, a1 is cell, a2 is CCTouch
			r = true
		elseif fn == "cellHighlight" then		-- A cell is highlighting, coco2d-x 2.1.3 or above
		elseif fn == "cellUnhighlight" then		-- A cell had been unhighlighted, coco2d-x 2.1.3 or above
			local card = self.cellNodes[a1:getIdx() + 1]
            card:getChildByTag(120):setScale(1.0);
			r = true;
		elseif fn == "cellWillRecycle" then		-- A cell will be recycled, coco2d-x 2.1.3 or above
		end
		return r
	end)
end
function initmessageCell()
	if tonumber(m_messagecount) > 0 then
		if m_messagecell ~= nil then
			local sprite = m_messagecell:getSprite();
			sprite:removeChildByTag(120,true);
			local bk = CCSprite:createWithSpriteFrameName("com_red_infoframe");
			local font = CCLabelBMFont:create(m_messagecount,"characters/number_24.fnt");
			bk:addChild(font);
			local bkrect = bk:boundingBox();
			font:setAnchorPoint(ccp(0.5,0.5));
			font:setPosition(ccp(bkrect.size.width/2,bkrect.size.height/2))
			sprite:addChild(bk);
			local rect = sprite:boundingBox();
			bk:setPosition(ccp(rect.size.width*3/4,rect.size.height*3/4));
			bk:setTag(120)
		end
	end
end

function SetMessageCount(count)
	m_messagecount = count;
	initmessageCell();
end
--added by gongsun 2014.4.14 转生提示
function initreincarnationCell()
	if m_reincarnationCount >= 80 then
		if m_reincarnationcell ~= nil then
			local sprite = m_reincarnationcell:getSprite();
			sprite:removeChildByTag(130,true);
			local bk = CCSprite:createWithSpriteFrameName("com_tip_icon");
			sprite:addChild(bk);
			local rect = sprite:boundingBox();
			bk:setPosition(ccp(rect.size.width*3/4,rect.size.height*3/4));
			bk:setTag(130)
		end
	end
end

function SetReincarnationCount(ballcount)
	m_reincarnationCount = tonumber(ballcount)
	initreincarnationCell()
end

function InitMenuBtnsView(view)
	m_messagecount = 0;
	m_reincarnationCount = 0
	local node = view:getNode("node_menubtns");
	local view = MenuBtnsView:create();
	local size = CCSize(78,58);
	view:setViewSize(size);
	view:setContentView(node);
	view:initUI();
	node:addChild(view);
	view:setTag(100);
end