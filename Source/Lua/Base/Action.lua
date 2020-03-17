-----------
-- Action --
-----------
require "Base/Path"

_G.Action = {}

function Action:Init()
    self.split_str = '|'
    self.category_count = {}
    self.server_tag = string.format("%s.%s", Base.Enviroment.init_time, Base.Enviroment.thread_id)

    local meta_tab = {}
    meta_tab.__index = function(t, name)
        return function(s, player, content)
            if type(player) ~= "table" then player = nil end
            self:AddCategoryCount(name)
            self:Log(name, player, content)
        end
    end
    setmetatable(self, meta_tab)
end

function Action:AddCategoryCount(name)
    self.category_count[name] = self.category_count[name] or 0
    self.category_count[name] = self.category_count[name] + 1
end

function Action:Flush()
    self.log = {}
end

function Action:SetHeader(name, player)
    table.insert(self.log, os.time()) -- 时间戳
    table.insert(self.log, "slots") -- 游戏名称
    table.insert(self.log, self.server_tag) -- 服务器id
    table.insert(self.log, name) -- 日志类型
    table.insert(self.log, self.category_count[name]) -- 日志序列
    table.insert(self.log, player and player.id or "") -- 玩家id
    table.insert(self.log, player and player.client.device or "") -- 手机型号
    table.insert(self.log, player and player.client.os or "") -- 操作系统
    table.insert(self.log, player and player.client.os_version or "") -- 操作系统版本号
    table.insert(self.log, player and player.client.eth_ip or "") -- 内网ip
    table.insert(self.log, player and player.client.ip or "") -- 外网ip
    table.insert(self.log, player and player.client.mac or "") -- mac
    table.insert(self.log, player and player.client.imei_idfa or "") -- imei_idfa
    table.insert(self.log, player and player.client.package or "") -- 包名
    table.insert(self.log, player and player.client.channel or "") -- 渠道
    table.insert(self.log, player and player.client.version or "") -- 版本号
    table.insert(self.log, player and player.character.chip or "") -- 金币数量  
    table.insert(self.log, player and player.prop.normal or "") -- 道具
    table.insert(self.log, player and player.character.charge or "") -- 累计充值
    table.insert(self.log, player and player.character.month_charge or "") -- 当月充值
    table.insert(self.log, player and player.character.daily_charge or "") -- 当日充值
end

function Action:SetContent(content)
    content = content or {}
    for _, v in ipairs(content) do
        table.insert(self.log, v)
    end
end

function Action:Output()
    for k, v in ipairs(self.log) do
        self.log[k] = tostring(v)
    end
    local str = table.concat(self.log, self.split_str)
    LOG(ACT, INFO).Format(str)
end

function Action:Log(name, player, content)
    if type(player) ~= "table" then player = nil end
    self:Flush()
    self:SetHeader(name, player)
    self:SetContent(content)
    self:Output()
end

Action:Init()