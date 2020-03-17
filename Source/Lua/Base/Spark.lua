-----------
-- Spark --
-----------
require "Base/Path"
require "Config/system/ConstValue"
require "Base/Operative"

_G.Spark = {}

function Spark:Init()
    self.split_str = '|'
    self.category_count = {}
    self.server_tag = string.format("%s.%s", Base.Enviroment.init_time, Base.Enviroment.thread_id)

    local meta_tab = {}
    meta_tab.__index = function(t, name)
        return function(s, player, content)
            if type(player) ~= "table" then player = nil end
            self:AddCategoryCount(name)
            self:Log(name, player, content)
            if Operative[name] then
                Operative[name](Operative, player, content)
            end
        end
    end
    setmetatable(self, meta_tab)
end

function Spark:AddCategoryCount(name)
    self.category_count[name] = self.category_count[name] or 0
    self.category_count[name] = self.category_count[name] + 1
end

function Spark:Flush()
    self.log = {}
end

function Spark:SetHeader(name, player)
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
    table.insert(self.log, player and player.character.player_type or "")--AB测试类型
    table.insert(self.log, player and player.character.level or "")--等级

    local lucky_type = player and player.character.lucky_type or 0
    local stage_type = player and player.character.stage_type or 0
    local lucky = player and player.character.lucky or 0
    local lucky_credit_change = player and player.character.lucky_credit_change or 0
    local unlucky = player and player.character.unlucky or 0
    local unlucky_credit_change = player and player.character.unlucky_credit_change or 0
    local on_off = player and player.character.enter_unlucky or 0
    local lucky_info =  ""



    if (lucky_type == 3) then
        lucky_info = lucky_type.."_"..stage_type.."_"..lucky.."_"..lucky_credit_change.."_"..on_off
    elseif (lucky_type == 4) then
        lucky_info = lucky_type.."_"..stage_type.."_"..unlucky.."_"..unlucky_credit_change.."_"..on_off
    else
        lucky_info = lucky_type.."_"..stage_type.."_"..lucky.."_"..lucky_credit_change.."_"..on_off
    end

    local player_extern = player and player.player_extern or nil
    if player_extern ~= nil then
        local player_json_data = player_extern.save_data
        if (player_json_data ~= nil) then
            local last_normal_credit1 = player_json_data and player_json_data.last_normal_credit1 or 0
            local last_normal_credit2 = player_json_data and player_json_data.last_normal_credit2 or 0
            local normal_credit_change1 = player_json_data and player_json_data.normal_credit_change1 or 0
            local normal_credit_change2 = player_json_data and player_json_data.normal_credit_change2 or 0
            local normal_spin_count1 = player_json_data and player_json_data.normal_spin_count1 or 0
            local normal_spin_count2 = player_json_data and player_json_data.normal_spin_count2 or 0
            lucky_info = lucky_info.."_"..last_normal_credit1.."_"..last_normal_credit2.."_"..normal_credit_change1.."_"..normal_credit_change2.."_"..normal_spin_count1.."_"..normal_spin_count2
        end
    end

    table.insert(self.log, lucky_info)--模式
    table.insert(self.log, player and player.record.total_spin or 0)
    table.insert(self.log, "")
    table.insert(self.log, "")
    table.insert(self.log, "")
    table.insert(self.log, "")
    table.insert(self.log, "")
end

function Spark:SetContent(content)
    content = content or {}
    for _, v in ipairs(content) do
        table.insert(self.log, v)
    end
end

function Spark:Output()
    for k, v in ipairs(self.log) do
        self.log[k] = tostring(v)
    end
    local str = table.concat(self.log, self.split_str)
    LOG(SPK, INFO).Format(str)
end

function Spark:Log(name, player, content)
    
    if (player and player.character.player_type == tonumber(ConstValue[5].value)) then
        return
    end
    if type(player) ~= "table" then player = nil end
    self:Flush()
    self:SetHeader(name, player)
    self:SetContent(content)
    self:Output()
end

Spark:Init()