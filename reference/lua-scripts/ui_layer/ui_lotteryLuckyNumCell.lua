--descriptioin:lucky num cell
--company: xckoo
--litao
--2014.5.16
---------------------------------------------
module("ui_lotteryLuckyNumCell", package.seeall)
baseClass(layer_base_t, ui_lotteryLuckyNumCell)

function init(self, cellSize, data)
	local ccbiAttrTable = {name="activity/LotteryLuckyNumCell.ccbi", size=cellSize}
	layer_base_t.init(self, true, ccbiAttrTable)

	--用户info
	self.playerMgr_ = CPlayerDataMgr:instance()
	self.playerData_ = self.playerMgr_:GetPlayerInfoData()
	--
	self.m_cellData = data

	--init
	self:init_ui()		
end

function init_ui(self)
	if self.proxy_ ~= nil then
		--node
		self.label_lucky_num = tolua.cast(self.proxy_:getNode("label_lucky_num"), "CCLabelBMFont")
		--get info
		self:init_ext_ui()
	end
end

function init_ext_ui(self)	
	if nil == self.m_cellData then
		return nil
	end
	--
	self.label_lucky_num:setString(tostring(self.m_cellData.num))
end

function getIntPart(self, x)
    if x <= 0 then
       return 0
    end

    if math.abs(math.ceil(x) - x) < 0.005 then
       x = math.ceil(x)
    else
       x = math.ceil(x) - 1
    end
    return x
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

--创建测试数据
function createData(self)
	---[[
	--]]
end