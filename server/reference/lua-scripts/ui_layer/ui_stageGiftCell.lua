--[[----------------------------------------------------
  Author :tango
  FName  :ui_stageGiftLayer.lua
  Time   :2014/10/14 11:25:33
  Remark :新手阶段性礼包
-------------------------------------------------------]]
module("ui_stageGiftCell", package.seeall)
baseClass(layer_base_t, ui_stageGiftCell)

function init(self, cellSize, data)
	local ccbiAttrTable = {name="sub_ui/StageGiftCell.ccbi", size=cellSize}
	layer_base_t.init(self, true, ccbiAttrTable)
	
	self.cellData = data
	--init
	self:init_ui()
end

function init_ui(self)
	if self.proxy_ ~= nil then
		
		for i=1,2 do
			local stri = tostring(i)
			self["spr_item_" .. stri] = tolua.cast(self.proxy_:getNode("spr_item_" .. stri),"CCSprite")
			self["label_desc_" .. stri] = tolua.cast(self.proxy_:getNode("label_desc_" .. stri),"CCLabelTTF")
			self["label_num_" .. stri] = tolua.cast(self.proxy_:getNode("label_num_" .. stri),"CCLabelBMFont")
			self["node_icon_"..stri] = tolua.cast(self.proxy_:getNode("node_icon_" .. stri),"CCNode")
		end
		
		--init info
		self:init_ui_ext()
	end
end

function clear( self )
	for i=1,2 do
		local stri = tostring(i)
		self["label_desc_" .. stri]:setVisible(fasle)
		self["label_num_" .. stri]:setVisible(fasle)
		self["node_icon_"..stri]:setVisible(fasle)
	end
end
--
function init_ui_ext(self)
	self:clear()

	for i=1,#self.cellData do
		local sprItemFrame = self["spr_item_"..tostring(i)]
		local nodeItem = self["node_icon_"..tostring(i)]
		
		local _icon = nodeItem:getChildByTag(99)
		if _icon then
			_icon:removeFromParentAndCleanup(true)
		end
		local item = self.cellData[i]
		--icon/frame
		local _maintype = 0
		local _subtype = 0
		local _id = -1
		local _num = -1
		local _drop_type = 0
		local _obj_info = {}
		_maintype, _subtype, _id, _num, _drop_type = setObjTypeInfo(tonumber(item.dropid))
		_obj_info.pIcon, _obj_info.pFrame, _obj_info.quality, _obj_info.objname = rl_get_iconsprite(_maintype, _subtype, E_FRAMETYPE_SMALL, _id)
		if nil ~= _obj_info.pFrame then
			sprItemFrame:setDisplayFrame(_obj_info.pFrame)
		end
		--合集icon用发过来的,防止集合出现问题
		if _drop_type == 1 then
			local pathName = "props/"..item.icon..".plist"
			CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile(pathName)
			local frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(item.icon)
			if frame ~= nil then
				_obj_info.pIcon = CCSprite:createWithSpriteFrame(frame)
			end
		end
		if nil ~= _obj_info.pIcon then
			nodeItem:setVisible(true)
			nodeItem:addChild(_obj_info.pIcon)
			local size = nodeItem:getContentSize()
			_obj_info.pIcon:setPosition(ccp(size.width * 0.5, size.height * 0.5))
			_obj_info.pIcon:setAnchorPoint(ccp(0.5, 0.5))
			_obj_info.pIcon:setTag(99)
			if _drop_type ~= 1 then
				_obj_info.pIcon:setScale(0.9)
			end
		end
		
		self["label_desc_"..tostring(i)]:setString(item.name)
		self["label_desc_"..tostring(i)]:setVisible(true)

		if _num > 1 then
			self["label_num_" .. tostring(i)]:setString(_num)
			self["label_num_" .. tostring(i)]:setVisible(true)
		end

		
	end
end

function init_binding_event(self)
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
