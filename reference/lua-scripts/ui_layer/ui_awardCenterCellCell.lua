----------------------------------------------------------------------
--  Copyright (c) 2014-2016, XCKOO. All Rights Reserved.
--  Author :Tango
--  Time   :2015/1/20 10:29:51
--  Remark :领奖中心子页面
----------------------------------------------------------------------

module("ui_awardCenterCellCell", package.seeall)
baseClass(layer_base_t, ui_awardCenterCellCell)

function init(self, cellSize, data)
	local ccbiAttrTable = {name="activity/AwardCenterCellCell.ccbi", size=cellSize}
	layer_base_t.init(self, true, ccbiAttrTable)

	self.cellData = data
	--init	

	self:init_ui()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		--spr
		self.spr_item = tolua.cast(self.proxy_:getNode("spr_item"), "CCSprite")
		--label
		self.labelName = tolua.cast(self.proxy_:getNode("label_item"), "CCLabelTTF")
		self.labelNum = tolua.cast(self.proxy_:getNode("label_item_num"), "CCLabelBMFont")
		--node
		self.nodeIcon = tolua.cast(self.proxy_:getNode("node_icon"), "CCNode")
		self.btnIcon = tolua.cast(self.proxy_:getNode("btn_icon"), "CCControlButton")

		--init info
		self:init_ui_ext()
		self:init_binding_event()
	end
end

--
function init_ui_ext(self)
	local _icon = self.spr_item:getChildByTag(99)
	if _icon then
		_icon:removeFromParentAndCleanup(true)
	end
	local item = self.cellData

	--icon/frame
	local _maintype = 0
	local _subtype = 0
	local _id = -1
	local _num = -1
	local _drop_type = 0
	local _obj_info = {}
	--cclog("20151113 type:%s dropid:%s", item.type, item.dropid)

	if item.type == "1" then --读掉落表
		_maintype, _subtype, _id, _num, _drop_type = setObjTypeInfo(tonumber(item.dropid))
		_obj_info.pIcon, _obj_info.pFrame, _obj_info.quality, _obj_info.objname = rl_get_iconsprite(_maintype, _subtype, E_FRAMETYPE_SMALL, _id)
	elseif item.type == "2" then -- 银子，数量由后台计算出来的
		_obj_info.objname = localizable.ui_awardCenter_silver .. item.dropid
		local spriteFrame = CGameObjElement:GetConsumeIcon(E_FRAMETYPE_SMALL,"props_036")
		_obj_info.pIcon = CCSprite:createWithSpriteFrame(spriteFrame)
		_obj_info.pFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("small_box_skill_01")
	elseif item.type == "3" then -- 竞技声望
		_obj_info.objname = localizable.ui_awardCenter_prestige .. item.dropid
		CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile("com_res/Resident.plist")
		local spriteFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("com_popularity _icon")
		_obj_info.pIcon = CCSprite:createWithSpriteFrame(spriteFrame)
		_obj_info.pIcon:setScale(1.6)
		_obj_info.pFrame = rl_get_frameicon(E_FRAMETYPE_SMALL, 3)
	elseif item.type == "10" then -- 组织贡献
		_obj_info.objname = localizable.ui_awardCenter_contribution.. "*" .. item.dropid
		CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile("com_res/Resident.plist")
		local spriteFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("com_bangpai_gongxian_icon")
		_obj_info.pIcon = CCSprite:createWithSpriteFrame(spriteFrame)
		--_obj_info.pIcon:setScale(1.6)
		_obj_info.pFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("small_box_skill_01")	
	elseif item.type == "99" then --  万里挑一
		_obj_info.pIcon, _obj_info.pFrame, _obj_info.quality, _obj_info.objname = rl_get_iconsprite(9,9, E_FRAMETYPE_SMALL, 0)
		_obj_info.objname = localizable.ui_awardCenter_name1
	end
	
	if nil ~= _obj_info.pFrame then
		self.spr_item:setDisplayFrame(_obj_info.pFrame)
	end

	self.labelName:setString(tostring(_obj_info.objname))

	if nil ~= _obj_info.pIcon then
		self.nodeIcon:addChild(_obj_info.pIcon)
		self.nodeIcon:setVisible(true)

		local size = self.nodeIcon:getContentSize()
		_obj_info.pIcon:setPosition(ccp(size.width * 0.5, size.height * 0.5))
		_obj_info.pIcon:setAnchorPoint(ccp(0.5, 0.5))
		_obj_info.pIcon:setTag(99)
--		if _drop_type ~= 1 then
--			_obj_info.pIcon:setScale(0.9)
--		end
	end

	if _num and _num > 1 then
		self.labelNum:setVisible(true)
		self.labelNum:setString(tostring(_num))
	else
		self.labelNum:setVisible(false)
	end

end

function init_binding_event(self)
	if self.proxy_ ~= nil then
		--奖励详情
		local function onBtnClickAwardIcon(btn)
			if self.cellData.type == "1" then
				local _id = tonumber(self.cellData.dropid)
				if nil ~= _id then
					CGameObjElement:ShowDropByID(_id)
				end
			elseif self.cellData.type == "99" then
				CGameObjElement:ShowCommonItemDetail(0, 0, 0, localizable.ui_awardCenter_wanlitiaoyi)
			elseif self.cellData.type == "10" then
				CGameObjElement:ShowCommonItemDetail(0, 0, 0, localizable.ui_awardCenter_contribution)
			end
		end

		self.btnIcon:setTouchPriority(kCCMenuHandlerPriority - 1)
		self.proxy_:handleButtonEvent(self.btnIcon, function(button, event)
			onBtnClickAwardIcon()
			return nil
		end, CCControlEventTouchUpInside)
	end
	
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