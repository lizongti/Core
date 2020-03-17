module("LuckyModeNormal", package.seeall)

local LuckyModeNormalObject = {}

local GetSpinCountMax = function(player, config_name)
    local noraml_spin_lucky_change_conf = CommonCal.Calculate.get_config(player, config_name)
    local cur_level = player.character.level
    local spin_count_max = -1
    for k, v in ipairs(noraml_spin_lucky_change_conf) do
        if cur_level > v.level_min and cur_level <= v.level_max then
            spin_count_max = v.spin_count_max
            break
        end
    end
    return spin_count_max
end

local InitNormalControl = function(session, spin_context)
    local player = session.player
    if (player.character.lucky_type ~= LuckyType.ModeTypes.Normal) then
        return
    end

    local player_json_data = spin_context.player_json_data
    local spin_count_max1 = GetSpinCountMax(player, "NomalSpinLuckyChange1")

    if spin_count_max1 ~= -1 then
        if player_json_data.last_normal_credit1 == nil or player_json_data.last_normal_credit1 == -1 then
            player_json_data.last_normal_credit1 = player.character.chip
            player_json_data.normal_spin_count1 = 0
            player_json_data.normal_credit_change1 = 0
        end
    end

    local spin_count_max2 = GetSpinCountMax(player, "NomalSpinLuckyChange2")

    if spin_count_max2 ~= -1 then
        if player_json_data.last_normal_credit2 == nil or player_json_data.last_normal_credit2 == -1 then
            player_json_data.last_normal_credit2 = player.character.chip
            player_json_data.normal_spin_count2 = 0
            player_json_data.normal_credit_change2 = 0
        end
    end
end

local function AddPlayerForceWin(player_json_data, config)
    player_json_data.force_win_spin = (player_json_data.force_win_spin or 0) + config.forcewinspin
    player_json_data.force_win_feature = (player_json_data.force_win_feature or 0) + config.forcewinfeature
end

local RunNormalControlPrivate = function(session, parameters)
    local session = parameters.session
    local task = parameters.task
    local player = parameters.player
    local save_data = parameters.save_data
    local player_json_data = parameters.player_json_data
    local chip_cost = parameters.chip_cost
    local win_chip = parameters.win_chip
    local last_normal_credit_name = parameters.last_normal_credit_name
    local normal_credit_change_name = parameters.normal_credit_change_name
    local normal_spin_count_name = parameters.normal_spin_count_name
    local config_name = parameters.config_name
    local game_type = parameters.game_type

    local spin_count_max = GetSpinCountMax(player, config_name)

    if spin_count_max == -1 then
        LOG(RUN, DEBUG).Format("[LuckyCal][RunNormalControl]  player %s can't find max spin count!", player.id)
        return
    end

    LuckyCal.AddNormalCreditChange(player, player_json_data, normal_credit_change_name, win_chip - chip_cost)

    if 	chip_cost > 0 then
        player_json_data[normal_spin_count_name] = player_json_data[normal_spin_count_name] + 1
    end

    local credit_change_scale = player_json_data[normal_credit_change_name] / player_json_data[last_normal_credit_name]

    local normal_spin_count = player_json_data[normal_spin_count_name]
    local last_normal_credit = player_json_data[last_normal_credit_name]

    local cur_level = player.character.level
    local cur_config = nil
    local noraml_spin_lucky_change_conf = CommonCal.Calculate.get_config(player, config_name)

    for k, v in ipairs(noraml_spin_lucky_change_conf) do
        local check = true

        if last_normal_credit <= v.last_normal_credit_min or last_normal_credit > v.last_normal_credit_max then
            check = false
        end

        if cur_level <= v.level_min or cur_level > v.level_max then
            check = false
        end

        if normal_spin_count <= v.spin_count_min or normal_spin_count > v.spin_count_max then
            check = false
        end

        if credit_change_scale < v.creditschange_min or credit_change_scale >= v.creditschange_max then
            check = false
        end

        if check then
            cur_config = v
            break
        end
    end

    local is_reset = false

    if cur_config ~= nil then
        -- 增加lucky和unlucky
        local add_lucky = math.floor(cur_config.luckygiven * math.abs(player_json_data[normal_credit_change_name]))
        local add_unlucky = math.floor(cur_config.unluckygiven * math.abs(player_json_data[normal_credit_change_name]))
        LuckyCal.GainLucky(player, add_lucky, "normal")
        LuckyCal.GainUnLucky(player, add_unlucky, "normal")

        AddPlayerForceWin(player_json_data, cur_config)

        is_reset = true
    else
        -- 一定次数后重置normal
        if normal_spin_count >= spin_count_max then
            is_reset = true
        end
    end

    if is_reset then
        LOG(RUN, DEBUG).Format("[RunNormalControl] player %s, reset", player.id)
        player_json_data[last_normal_credit_name] = -1
        player_json_data[normal_spin_count_name] = 0
        player_json_data[normal_credit_change_name] = 0
    end
end

local RunNormalControl = function(session, parameters)
    local success, error = pcall(RunNormalControlPrivate, session, parameters)
    
    if not success then
        LOG(RUN, DEBUG).Format("[LuckyCal][RunNormalControl] player %s error %s", session.player.id, error)
    end
end

function LuckyModeNormalObject:OnBaseSpinStart(session, spin_context)
    local player = session.player
    InitNormalControl(session, spin_context)
end

function LuckyModeNormalObject:OnBaseSpinEnd(session, spin_context)
    for i=1, 2 do
        local v = {
            session = session,
            task = session.task,
            player = session.player,
            save_data = spin_context.player_game_info.save_data,
            player_json_data = spin_context.player_json_data,
            chip_cost = spin_context.chip_cost,
            win_chip = spin_context.win_chip,
            last_normal_credit_name = "last_normal_credit"..i,
            normal_credit_change_name = "normal_credit_change"..i,
            normal_spin_count_name = "normal_spin_count"..i,
            config_name = "NomalSpinLuckyChange"..i,
            game_type = spin_context.game_type
        }
        RunNormalControl(session, v)
    end

    local player_json_data = spin_context.player_json_data
    player_json_data.ContinuousSpinWithoutBankrupt = player_json_data.ContinuousSpinWithoutBankrupt + 1
    player_json_data.ContinuousSpinNoPay = player_json_data.ContinuousSpinNoPay + 1
end

function Create(self)
    local obj = {}
    setmetatable(obj, {__index = LuckyModeNormalObject})
    return obj
end
