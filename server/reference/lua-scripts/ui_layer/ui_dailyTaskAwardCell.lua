--日常任务_奖励_Cell
--litao
--2014.5.6
---------------------------------------------
module("ui_dailyTaskAwardCell", package.seeall)
baseClass(layer_base_t, ui_dailyTaskAwardCell)

function init(self, cellSize, data)
	local ccbiAttrTable = {name="sub_ui/DailyTaskAwardCell.ccbi", size=cellSize}
	layer_base_t.init(self, true, ccbiAttrTable)

	self.cellData = data
	--init	
	self._data = {} 
	self:init_ui()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		--spr/node/lebel
		self.spr_box = tolua.cast(self.proxy_:getNode("spr_box"), "CCSprite")
		self.label_need_score = tolua.cast(self.proxy_:getNode("label_need_score"), "CCLabelTTF")

		--init info
		self:init_ui_ext()
	end
end

--
function init_ui_ext(self)
	self.label_need_score:setString(tostring(self.cellData.needscore) .. localizable.ui_daily_score)
	--self.label_need_score:enableStroke(ccc3(0, 0, 0), 0.5)
	self.label_need_score:setColor(ccc3(119, 52, 28))
	--1不可领/2已领取/4可领取
	if 2 == self.cellData.status then
		local _frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("daily_box_open")
		self.spr_box:setDisplayFrame(_frame)
	elseif 1 == self.cellData.status then
		local _frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("daily_box_close")
		self.spr_box:setDisplayFrame(_frame)
	else
		local _frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("daily_box")
		self.spr_box:setDisplayFrame(_frame)
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