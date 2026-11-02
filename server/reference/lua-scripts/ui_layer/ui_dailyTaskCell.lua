--日常任务_Cell
--litao
--2014.5.6
---------------------------------------------
module("ui_dailyTaskCell", package.seeall)
baseClass(layer_base_t, ui_dailyTaskCell)

function init(self, cellSize, data)
	local ccbiAttrTable = {name="sub_ui/DailyTaskCell.ccbi", size=cellSize}
	layer_base_t.init(self, true, ccbiAttrTable)

	self.cellData = data
	--init
	self:init_ui()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		--spr/node/lebel
		self.spr_task_icon = tolua.cast(self.proxy_:getNode("spr_task_icon"), "CCSprite")
		self.label_name = tolua.cast(self.proxy_:getNode("label_name"), "CCLabelTTF")
		self.label_progress = tolua.cast(self.proxy_:getNode("label_progress"), "CCLabelTTF")
		self.label_desc = tolua.cast(self.proxy_:getNode("label_desc"), "CCLabelTTF")
		self.label_score = tolua.cast(self.proxy_:getNode("label_score"), "CCLabelTTF")
		self.btn_goto = tolua.cast(self.proxy_:getNode("btn_goto"), "CCControlButton")
		self.spr_task_done = tolua.cast(self.proxy_:getNode("spr_task_done"), "CCSprite")

		--getinfo
		self:getTaskInfo()
		--init info
		self:init_ui_ext()
	end
end

function getTaskInfo(self)
	---[[
	local _info = DataMgr.GetDataByID("Struct_Dailytask_Info", tonumber(self.cellData.id))
	local _title = _info.m_dailytask_title
	local _desc = _info.m_dailytask_name
	local _need_process = _info.m_dailytask_value1
	local _can_get_score = _info.m_dailytask_points

	--init info
	self.label_name:setString(tostring(_title))
	self.label_desc:setString(tostring(_desc))
	self.label_score:setString(tostring(_can_get_score))
	self.label_progress:setString(tostring(self.cellData.cur_process.."/".._need_process))

	if tonumber(self.cellData.cur_process) >= tonumber(_need_process) then
		self.spr_task_done:setVisible(true)
		self.btn_goto:setVisible(false)
	else
		self.spr_task_done:setVisible(false)
		self.btn_goto:setVisible(true)
	end
	--]]
end

--
function init_ui_ext(self)
	--
	CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile("ccbResources/daily_task.plist")
	--init icon
	local _icon = CCSprite:createWithSpriteFrameName(tostring("daily_icon_"..self.cellData.id))
	if nil ~= _icon then
		self.spr_task_icon:addChild(_icon)
		local _size = self.spr_task_icon:getContentSize()
		_icon:setPosition(ccp(_size.width * 0.5, _size.height * 0.5))
		_icon:setAnchorPoint(ccp(0.5, 0.5))
	end
end

function init_binding_event(self)
	--
end

function onNodeCleanup(self)
	---[[
	if self.proxy_ then
    	self.proxy_:release()
    	self.proxy_ = nil
    end
    --]]
    layer_base_t.onNodeCleanup(self)
end