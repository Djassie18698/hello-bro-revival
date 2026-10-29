--月签到cell
--liyongkang
--2015-10-13
---------------------------------------------
module("ui_monthSignCell", package.seeall)
require("ui_layer/ui_monthSignAnim")

baseClass(layer_base_t, ui_monthSignCell)

function init(self, cellSize, data)
	local ccbiAttrTable = {name="activity/MonthSignCell.ccbi", size=cellSize}
	layer_base_t.init(self, true, ccbiAttrTable)

    self.data = data;
	self:init_ui()
end

function init_ui(self)
	if self.proxy_ ~= nil then

        for i=1 , #self.data do   
            --ICON 
            self["sprite_quality_bg_0" .. tostring(i)] = tolua.cast(self.proxy_:getNode("sprite_quality_bg_0" .. tostring(i)), "CCSprite")        
            CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile("props/" .. self.data[i].award_icon .. ".plist")
		    local pFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(self.data[i].award_icon)
		    local pIcon
            if pFrame ~= nil then
			    pIcon = CCSprite:createWithSpriteFrame(pFrame);
			    local size = self["sprite_quality_bg_0" .. tostring(i)]:getContentSize()
			    if pIcon ~= nil then
				    self["sprite_quality_bg_0" .. tostring(i)]:addChild(pIcon)
				    pIcon:setPosition(ccp(size.width/2, size.height/2))
				    pIcon:setAnchorPoint(ccp(0.5, 0.5))
			    end
		    end
            --number
            self["label_number_0" .. tostring(i)] = tolua.cast(self.proxy_:getNode("label_number_0"..tostring(i)), "CCLabelTTF")
            self["label_number_0" .. tostring(i)]:setString("x"..self.data[i].award_num)

            --底图
            self["sprite_icon_bg_0" .. tostring(i)] = tolua.cast(self.proxy_:getNode("sprite_icon_bg_0" .. tostring(i)), "CCSprite")        
       

            self["sprite_vip_bg_0" .. tostring(i)] = tolua.cast(self.proxy_:getNode("sprite_vip_bg_0" .. tostring(i)), "CCSprite")
            if tonumber (self.data[i].need_vip ) == 0 then
                self["sprite_vip_bg_0" .. tostring(i)]:setVisible(false)
            end 
                               
            self["label_need_vip_0" .. tostring(i)] = tolua.cast(self.proxy_:getNode("label_need_vip_0"..tostring(i)), "CCLabelTTF")
            self["label_need_vip_0" .. tostring(i)]:setString("v"..self.data[i].need_vip)

            --
            self["sprite_select_0" .. tostring(i)] = tolua.cast(self.proxy_:getNode("sprite_select_0" .. tostring(i)), "CCSprite")

            --不同的底框 放在activity02.plist中        
            CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile("ccbResources/activity_02.plist")		            
            if  tonumber(self.data[i].status) == 0 then --未签到 但是今天可以签到
                 local pFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("month_sign_icon_02")
                 if pFrame ~=nil then
                    self["sprite_icon_bg_0" .. tostring(i)]:setDisplayFrame(pFrame)
                 end
            local animLayer = createObj(ui_monthSignAnim)
           -- animLayer.node_:setPosition(70,70)
            self["sprite_icon_bg_0" .. tostring(i)]:addChild(animLayer.node_)

            elseif tonumber(self.data[i].status) == 1 then --已签到  --需要特殊处理图片变灰
                 local pFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("month_sign_icon_01")
                 if pFrame ~=nil then
                    self["sprite_icon_bg_0" .. tostring(i)]:setDisplayFrame(pFrame)
                    local pProgram = CCShaderCache:sharedShaderCache():programForKey("greysprite");
                    if pProgram ~= nil then
                        self["sprite_quality_bg_0" .. tostring(i)]:setShaderProgram(pProgram)
                        pIcon:setShaderProgram(pProgram)
                        self["sprite_vip_bg_0" .. tostring(i)]:setShaderProgram(pProgram)
                    end
                 end
                self["sprite_select_0" .. tostring(i)]:setVisible(true)
            elseif tonumber(self.data[i].status) == 2 then --签到一半                  
                 local pFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("month_sign_icon_03")
                 if pFrame ~=nil then
                    self["sprite_icon_bg_0" .. tostring(i)]:setDisplayFrame(pFrame)
                 end
            elseif tonumber(self.data[i].status) == 3 then --未到签到时间
                local pFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("month_sign_icon_02")
                if pFrame ~=nil then
                    self["sprite_icon_bg_0" .. tostring(i)]:setDisplayFrame(pFrame)
                end
            end
        end

        if #self.data < 4 then
            for i=#self.data + 1 , 4 do
                self["sprite_icon_bg_0" .. tostring(i)] = tolua.cast(self.proxy_:getNode("sprite_icon_bg_0" .. tostring(i)), "CCSprite")  
                self["sprite_icon_bg_0" .. tostring(i)]:setVisible(false)
            end
        end

	end
end


function onNodeCleanup(self)
    layer_base_t.onNodeCleanup(self)
end