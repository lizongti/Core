require"Common/SlotsGameCalculate" -- 重写的接口
require"Common/SlotsGameCal" -- 旧的接口
module("SlotsPiggyJackpotSpin", package.seeall)

local Banks = {3, 7, 12, 18}
local MAX_STEP = 18

local BankSpecial = {
    EXTRA_FREE_SPIN = 1,
    MAP_ADD_ROW = 2,
    INCREASE_PIGGY_COINS = 3,
    MAP_ADD_COL = 4,
    ADD_PIGGY_ON_REELS = 5
}

local FormationType = {
    Normal = 1,
    FreeSpin = 2,
    SuperFreeSpin = 3,
    SuperFreeSpinRow = 4,
    SuperFreeSpinCol = 5,
    SuperFreeSpinRowCol = 6,
}

local function GetFixedAmount(amount)
    local v = math.floor(amount/100.0)*100
    return v
end

local function GetFixedMulti(multi)
    local multi = math.floor((multi+0.05)*10)/10
    return multi
end

local function GetBankIndex(step)
    for i=1, #Banks do
        if Banks[i] == step then
            return i
        end
    end
    return 0
end

local function IsBankStep(step)
    for i=1, #Banks do
        if Banks[i] == step then
            return true
        end
    end
    return false
end

local function GetCurBankIndex(step)
    for i=4, 1, -1 do
        if step > Banks[i] then
            return i+1
        end
    end
    return 1
end

local function GetBankPrevStep(bank_step)
    local index = GetBankIndex(bank_step)
    local prev_bank_step = Banks[index-1] or 0
    return prev_bank_step
end

local function CheckJackpot(session, result_row, pre_action_list, is_free_spin, player_game_info, game_room_config, save_data, player, special_parameter, amount)
    local type = _G[game_room_config.game_name .. "TypeArray"].Types
    -- 如果没中奖,就把中间的图标替换成空图标

    local config_table = GetConfigTable(session, game_room_config, player_game_info)
    local config = CommonCal.Calculate.get_config(player, config_table.jackpot_config)

    save_data.jackpot_grand = save_data.jackpot_grand + config[1].bet_to_chip_percent
    if save_data.jackpot_grand > config[1].max_hold_point then
        save_data.jackpot_grand = config[1].max_hold_point
    end

    save_data.jackpot_major = save_data.jackpot_major + config[2].bet_to_chip_percent
    if save_data.jackpot_major > config[2].max_hold_point then
        save_data.jackpot_major = config[2].max_hold_point
    end

    save_data.jackpot_minor = save_data.jackpot_minor + config[3].bet_to_chip_percent
    if save_data.jackpot_minor > config[3].max_hold_point then
        save_data.jackpot_minor = config[3].max_hold_point
    end

    save_data.jackpot_mini = save_data.jackpot_mini + config[4].bet_to_chip_percent
    if save_data.jackpot_mini > config[4].max_hold_point then
        save_data.jackpot_mini = config[4].max_hold_point
    end

    local tab_rnd = {}
    local buzhong = 1
    for i = 1, #config do
        table.insert(tab_rnd, config[i].Winning_probability)
        buzhong = buzhong - config[i].Winning_probability
    end

    table.insert(tab_rnd, buzhong)

    local index = math.rand_weight(player, tab_rnd)

    if (GlobalSlotsTest[player.id] ~= nil) then
        if (GlobalSlotsTest[player.id].flag ~= 0) then
            index = GlobalSlotsTest[player.id].flag
        end
    end

    local final_id = 100
    local final_bet = 0
    if config[index] ~= nil then

        if config[index].prize_type == 2 then
            final_id = type.grand
            final_bet = save_data.jackpot_grand
            save_data.jackpot_grand = config[index].start_point

            if is_free_spin then
                special_parameter.piggyjackpot_zhong_jackpot_grand = 1
                special_parameter.piggyjackpot_free_jackpot_grand_value = math.floor(final_bet * amount * 20)
            else
                special_parameter.piggyjackpot_zhong_jackpot_grand_base = 1
                special_parameter.piggyjackpot_base_jackpot_grand_value = math.floor(final_bet * amount * 20)
            end

        elseif config[index].prize_type == 3 then
            final_id = type.major
            final_bet = save_data.jackpot_major
            save_data.jackpot_major = config[index].start_point

            if is_free_spin then
                special_parameter.piggyjackpot_zhong_jackpot_major = 1
                special_parameter.piggyjackpot_free_jackpot_major_value = math.floor(final_bet * amount * 20)
            else
                special_parameter.piggyjackpot_zhong_jackpot_major_base = 1
                special_parameter.piggyjackpot_base_jackpot_major_value = math.floor(final_bet * amount * 20)
            end

        elseif config[index].prize_type == 4 then
            final_id = type.minor
            final_bet = save_data.jackpot_minor
            save_data.jackpot_minor = config[index].start_point

            if is_free_spin then
                special_parameter.piggyjackpot_zhong_jackpot_minor = 1
                special_parameter.piggyjackpot_free_jackpot_minor_value = math.floor(final_bet * amount * 20)
            else
                special_parameter.piggyjackpot_zhong_jackpot_minor_base = 1
                special_parameter.piggyjackpot_base_jackpot_minor_value = math.floor(final_bet * amount * 20)
            end

        elseif config[index].prize_type == 5 then
            final_id = type.mini
            final_bet = save_data.jackpot_mini
            save_data.jackpot_mini = config[index].start_point

            if is_free_spin then
                special_parameter.piggyjackpot_zhong_jackpot_mini = 1
                special_parameter.piggyjackpot_free_jackpot_mini_value = math.floor(final_bet * amount * 20)
            else
                special_parameter.piggyjackpot_zhong_jackpot_mini_base = 1
                special_parameter.piggyjackpot_base_jackpot_mini_value = math.floor(final_bet * amount * 20)
            end

        end

        result_row[1][6] = 100
        result_row[3][6] = 100
    end

    result_row[2][6] = final_id

    table.insert(pre_action_list, {
        action_type = ActionType.ActionTypes.GameJackpotPool,
        id = final_id,
        bet = final_bet,
        grand = save_data.jackpot_grand,
        major = save_data.jackpot_major,
        minor = save_data.jackpot_minor,
        mini = save_data.jackpot_mini,
    })

    return result_row, final_bet, pre_action_list
end

local function GetBankFeatureTypes(player, bank_step)
    local bank_step_prev = GetBankPrevStep(bank_step)
    local config = CommonCal.Calculate.get_config(player, "PiggyJackpotWheelConfig")
    local types = {}
    for i=1, #config do
        local v = config[i]
        if v.Wheel > bank_step_prev and v.Wheel < bank_step then
            if v.Wheel_extra_bonus > 0 then
                table.insert(types, v.Wheel_extra_bonus)
            end
        end
    end
    return types
end

local function GetBankFeatureStep(player, bank_step, feature_type)
    local bank_step_prev = GetBankPrevStep(bank_step)
    local config = CommonCal.Calculate.get_config(player, "PiggyJackpotWheelConfig")
    local types = {}
    for i=1, #config do
        local v = config[i]
        if v.Wheel > bank_step_prev and v.Wheel < bank_step then
            if v.Wheel_extra_bonus == feature_type then
                return v.Wheel
            end
        end
    end
    return 0
end

local function GetBankResult(map_result, bank_step)
    local bank_step_prev = GetBankPrevStep(bank_step)
    local result = {}
    for i = bank_step_prev + 1, bank_step - 1 do
        if map_result[i] and map_result[i].options then
            local r = map_result[i].options[map_result[i].final_index]
            table.insert(result, r)
        end
    end
    return result
end

local function GetBankFeatureState(player, save_data, map_result, bank_step, feature_type)
    local result = GetBankResult(map_result, bank_step)
    local feature_step = GetBankFeatureStep(player, bank_step, feature_type)

    local state = {
        show = save_data.map_step >= feature_step,
        get = false,
    }

    for i=1, #result do
        if result[i].Wheel_extra_bonus == feature_type then
            -- 超过位置
            state.get = state.show and true
            break
        end
    end
    return state
end

function GetConfigTable(session, game_room_config, player_game_info)
    local lineNum = LineNum[game_room_config.game_type]()
    local total_amount = (player_game_info.bet_amount or 0) * lineNum
    local config_table = SlotsGameCal.Calculate.GetMapConfigTable(session, game_room_config, player_game_info, total_amount)
    return config_table
end

local function CalPiggyValues(session, game_room_config, player_game_info, player, save_data)
    local config_table = GetConfigTable(session, game_room_config, player_game_info)

    local pig_multi_config = CommonCal.Calculate.get_config(player, "PiggyJackpotPigMultiConfig")
    local coin_collect_config = CommonCal.Calculate.get_config(player, "PiggyJackpotCoinCollectConfig")
    local cur_multiple = GetFixedMulti(save_data.current_piggy_multi)

    local base_average_piggy_value = save_data.spin_amount_per_freespin_round / save_data.spin_times_per_freespin_round
    if save_data.spin_times_per_freespin_round == 0 then
        base_average_piggy_value = 0
    end

    local current_bank = GetCurBankIndex(save_data.map_step)

    local piggy_values = {}
    
    for i=1, 4 do
        if i < current_bank then
            piggy_values[i] = math.modf(base_average_piggy_value * pig_multi_config[i].Max_Multi / 1000) * 1000
        end
        if i == current_bank then
            piggy_values[i] = math.modf(base_average_piggy_value * cur_multiple / 1000) * 1000
        end
        if i > current_bank then
            piggy_values[i] = math.modf(base_average_piggy_value * pig_multi_config[i].Min_Multi / 1000) * 1000
        end
    end

    return piggy_values
end

local function GetMapInfo(session, game_room_config, player_game_info, player, save_data)
    local map_info = {
        step = save_data.map_step,
        bank_stage = {}
    }

    local bank_stage = map_info.bank_stage
    local map_result = save_data.map_result

    local piggy_values = CalPiggyValues(session, game_room_config, player_game_info, player, save_data)

    for i=1, 4 do
        local bank_step = Banks[i]
        bank_stage[i] = {}
        bank_stage[i].is_open = save_data.map_step >= Banks[i]
        bank_stage[i].piggy_value = piggy_values[i]

        bank_stage[i].feature_status = {}

        local features = GetBankFeatureTypes(player, bank_step)

        for j=1, #features do
            bank_stage[i].feature_status[j] = {}
            bank_stage[i].feature_status[j].feature_type = features[j]
            local state = GetBankFeatureState(player, save_data, map_result, bank_step, features[j])
            bank_stage[i].feature_status[j].is_feature_show = state.show
            bank_stage[i].feature_status[j].is_feature_get = state.get
        end
    end

    return map_info
end

-- PIGGY BONUS FEATURE
local function CheckCoinFeature(collect_pos_list, collect_value_list, game_room_config)
    local lines = _G[game_room_config.game_name .. "LineArray"].Lines1
    if #collect_pos_list < 5 then
        return false, 0
    end

    local total_prize = 0
    for i = 1, #collect_value_list do
        total_prize = total_prize + collect_value_list[i]
    end

    return true, total_prize
end

local function InitSaveData(session, player_game_info, player, game_room_config)
    local save_data = player_game_info.save_data

    if save_data == nil then
        save_data = {
            map_step = 0
        }
    end

    if save_data.jackpot_grand == nil then
        local config_table = GetConfigTable(session, game_room_config, player_game_info)
        local config = CommonCal.Calculate.get_config(player, config_table.jackpot_config)

        if save_data.jackpot_grand == nil then
            save_data.jackpot_grand = config[1].start_point
        end
        if save_data.jackpot_major == nil then
            save_data.jackpot_major = config[2].start_point
        end
        if save_data.jackpot_minor == nil then
            save_data.jackpot_minor = config[3].start_point
        end
        if save_data.jackpot_mini == nil then
            save_data.jackpot_mini = config[4].start_point
        end
    end

    if (save_data.collect_times == nil) then
        save_data.collect_times = 0
    end

    if (save_data.collect_total_times == nil) then
        save_data.collect_total_times = 0
    end

    if (save_data.collect_total_value == nil) then
        save_data.collect_total_value = 0
    end

    if (save_data.collect_average == nil) then
        save_data.collect_average = 0
    end

    if (save_data.super_free_spin_total_spin_count == nil) then
        save_data.super_free_spin_total_spin_count = 0
    end

    if (save_data.super_free_spin_total_amount_count == nil) then
        save_data.super_free_spin_total_amount_count = 0
    end

    if (save_data.super_free_spin_average_amount_count == nil) then
        save_data.super_free_spin_average_amount_count = 0
    end
    
    if (save_data.super_free_spin_extra == nil) then
        save_data.super_free_spin_extra = false
    end

    if (save_data.coin_feature_pig_prize == nil) then
        save_data.coin_feature_pig_prize = 0
    end

    if (save_data.formation_id == nil) then
        save_data.formation_id = FormationType.Normal
    end

    if save_data.current_piggy_multi == nil then
        local current_bank = GetCurBankIndex((save_data.map_step or 0)+1)
        local config_table = GetConfigTable(session, game_room_config, player_game_info)
        local pig_multi_config = CommonCal.Calculate.get_config(player, "PiggyJackpotPigMultiConfig")
        save_data.current_piggy_multi = pig_multi_config[current_bank].Min_Multi
    end

    -- 小轮记录的数据
    if save_data.spin_times_per_round == nil then
        save_data.spin_times_per_round = 0
        save_data.spin_amount_per_round = 0
    end

    if save_data.last_spin_amount_per_round == nil then
        save_data.last_spin_amount_per_round = 0
        save_data.last_spin_times_per_round = 0
    end
    
    -- 一轮FreeSpin记录的数据
    if save_data.spin_times_per_freespin_round == nil then
        save_data.spin_times_per_freespin_round = 0
        save_data.spin_amount_per_freespin_round = 0
    end

    if save_data.map_step == nil then
        save_data.map_step = 0
        save_data.map_result = nil
    end

    if (save_data.max_collect_times == nil) then
        local config_table = GetConfigTable(session, game_room_config, player_game_info)
        local collect_times_config = CommonCal.Calculate.get_config(player, "PiggyJackpotCoinCollectConfig")
        
        local step = save_data.map_step + 1
        if step > 18 then
            step = 1
        end
        save_data.max_collect_times = collect_times_config[step].collect_count
    end

    if save_data.map_result == nil then
        save_data.map_result = {}
    end
end

local function GetReelConfig(session, game_room_config, formation_id, extra, player_game_info, amount)
    local player = session.player
    if extra then
    end
    extra = extra or false

    local reel_file = nil
    local weight_file = nil

    local lineNum = LineNum[game_room_config.game_type]()

    local config_table = SlotsGameCal.Calculate.GetMapConfigTable(session, game_room_config, player_game_info, amount * lineNum)

    if (formation_id == FormationType.Normal or formation_id == FormationType.FreeSpin) then
        if formation_id == FormationType.FreeSpin then
            reel_file = config_table.feature_reel_config
            weight_file = config_table.feature_reel_weight_config
        else
            reel_file = config_table.base_reel_config
            weight_file = config_table.base_reel_weight_config
        end
        return reel_file, weight_file
    end

    -- No Add or Add Row (just 5 Cols) 
    if (formation_id == FormationType.SuperFreeSpin or formation_id == FormationType.SuperFreeSpinRow) then
        if extra then
            reel_file = config_table.jackpot_super_extra_five_reel_config
            weight_file = config_table.jackpot_super_extra_five_reel_weight_config
            return reel_file, weight_file
        else
            reel_file = config_table.jackpot_super_five_reel_config
            weight_file = config_table.jackpot_super_five_reel_weight_config
            return reel_file, weight_file
        end
    end
    -- Add Col or Add Row And Col(just 6 Cols) 
    if (formation_id == FormationType.SuperFreeSpinCol or formation_id == FormationType.SuperFreeSpinRowCol) then
        if extra then
            reel_file = config_table.jackpot_super_extra_six_reel_config
            weight_file = config_table.jackpot_super_extra_six_reel_weight_config
            return reel_file, weight_file
        else
            reel_file = config_table.jackpot_super_six_reel_config
            weight_file = config_table.jackpot_super_six_reel_weight_config
            return reel_file, weight_file
        end

    end
end

local function GetFormation(formation_id)
    -- 3x5
    if (formation_id == 1 or formation_id == 2) then
        return 'Formation1'
    end
    -- No Add 3x5
    if (formation_id == 3) then
        return 'Formation2'
    end
    -- Add Row 4x5
    if (formation_id == 4) then
        return 'Formation3'
    end
    -- Add Col 3x6
    if (formation_id == 5) then
        return 'Formation4'
    end

    -- Add Col And Row 4x6
    if (formation_id == 6) then
        return 'Formation5'
    end
end

local function GetLine(formation_id)
    if (formation_id == 1 or formation_id == 2) then
        return 1
    end
    return formation_id - 1
end

local function GetGroupId(cur_formation_id)
    return (cur_formation_id == 1 or cur_formation_id == 2) and 1 or cur_formation_id - 1
end

-- 搜集特性
local function CollectItems(session, player, game_room_config, result_row, type, player_game_info, amount, line, formation_id)
    local lines = _G[game_room_config.game_name .. "LineArray"]['Lines' .. line]
    -- body
    local collect_pos_list = SlotsGameCal.Calculate.GetItemPosition(result_row, game_room_config, type.Coin, GetFormation(formation_id))

    local collect_value_list = {}

    if not (#collect_pos_list > 0) then
        return collect_pos_list, collect_value_list
    end

    local str_config_type = #collect_pos_list >= 5 and 'Real_Probability' or 'Fake_Probability'

    local config_table = GetConfigTable(session, game_room_config, player_game_info)
    local config = CommonCal.Calculate.get_config(player, config_table.coin_config)

    local table_rand = {}

    for i = 1, #config do
        table.insert(table_rand, config[i][str_config_type])
    end

    for i = 1, #collect_pos_list do
        local rate = config[math.rand_weight(player, table_rand)].Coin_Bonus
        table.insert(collect_value_list, amount * #lines * rate)
    end

    return collect_pos_list, collect_value_list
end

local function CheckPig(result, total_value, game_room_config, type, player, formation_id)
    local collect_pos_list = SlotsGameCal.Calculate.GetItemPosition(result, game_room_config, type.pig, GetFormation(formation_id))

    parm_list = {}
    local config = CommonCal.Calculate.get_config(player, game_room_config.game_name .. 'OthersConfig')

    local rnd_free_spin = {}

    for i = 1, #config do
        table.insert(rnd_free_spin, config[i].Probability)
    end

    local total_reward = 0
    local total_free_spin = 0
    for i = 1, #collect_pos_list do
        total_reward = total_reward + total_value
        local rnd = math.rand_weight(player, rnd_free_spin)
        local result_rnd = config[rnd].Freespin_Plus
        if formation_id > 2 then
            result_rnd = 0
        end

        total_free_spin = total_free_spin + result_rnd
        table.insert(parm_list, {
            value = total_value,
            parm = result_rnd,
        })
    end

    return collect_pos_list, parm_list, total_free_spin, total_reward
end

local function CalPigAverageValueFromSpin(session, player, game_room_config, save_data)
    local pig_multi_config = CommonCal.Calculate.get_config(player, "PiggyJackpotPigMultiConfig")
    local coin_collect_config = CommonCal.Calculate.get_config(player, "PiggyJackpotCoinCollectConfig")

    local cur_multiple = GetFixedMulti(save_data.current_piggy_multi)

    if save_data.spin_times_per_freespin_round == 0 then
        return 0
    end

    local average_piggy_value = save_data.spin_amount_per_freespin_round / save_data.spin_times_per_freespin_round
    local piggy_value = math.modf(average_piggy_value * cur_multiple / 1000) * 1000
    return piggy_value
end

-- 进入地图逻辑
local function CheckMapFeature(session, save_data, pre_action_list, player_game_info, amount, game_room_config, formation_id, special_parameter, player)
    local lines = _G[game_room_config.game_name .. "LineArray"]['Lines' .. GetLine(formation_id)]
    local super_free_spin_count = 0
    local reward = 0
    
    if save_data.collect_times < save_data.max_collect_times then
        return super_free_spin_count, save_data, reward
    end

    -- 前进一步
    special_parameter.piggyjackpot_enter_map_normal = 1
    save_data.map_step = save_data.map_step + 1
    save_data.collect_times = 0

    FeverQuestCal.OnPiggyMapStep(session)

    -- 一小轮Spin的平均下注
    local spin_average_amount = save_data.spin_amount_per_round / save_data.spin_times_per_round
    spin_average_amount = math.modf(spin_average_amount / 1000) * 1000

    -- 进入super free spin
    if IsBankStep(save_data.map_step) then
        local bank_step = save_data.map_step
        local map_result = save_data.map_result
        -- 设置bank的信息
        save_data.map_result[save_data.map_step] = {}
        save_data.map_result[save_data.map_step].result = GetBankResult(map_result, bank_step, Banks[GetBankIndex(bank_step)-1] or 0)

        special_parameter.piggyjackpot_enter_map_super = 1
        special_parameter.piggyjackpot_enter_map_super_parm = ''
        special_parameter.piggyjackpot_enter_map_super_pig_value = save_data.collect_average

        save_data.collect_total_times = 0
        save_data.collect_total_value = 0

        save_data.formation_id = FormationType.SuperFreeSpin
        super_free_spin_count = 10
        save_data.super_free_spin_extra = false

        for k, v in pairs(save_data.map_result[save_data.map_step].result) do
            if v.Wheel_extra_bonus > 0 then
                special_parameter.piggyjackpot_enter_map_super_parm = special_parameter.piggyjackpot_enter_map_super_parm .. tostring(v.Wheel_extra_bonus)
            end

            if v.Wheel_extra_bonus == BankSpecial.EXTRA_FREE_SPIN then
                super_free_spin_count = super_free_spin_count + 5
            elseif v.Wheel_extra_bonus == BankSpecial.MAP_ADD_ROW then
                if save_data.formation_id == FormationType.SuperFreeSpin then
                    save_data.formation_id = FormationType.SuperFreeSpinRow
                elseif save_data.formation_id == FormationType.SuperFreeSpinCol then
                    save_data.formation_id = FormationType.SuperFreeSpinRowCol
                end
            elseif v.Wheel_extra_bonus == BankSpecial.INCREASE_PIGGY_COINS then
                -- save_data.collect_average = save_data.collect_average * 1.5
                -- print("#### 增加SUPER FREE SPIN中的存钱猪价值", save_data.collect_average)
            elseif v.Wheel_extra_bonus == BankSpecial.MAP_ADD_COL then
                if save_data.formation_id == FormationType.SuperFreeSpin then
                    save_data.formation_id = FormationType.SuperFreeSpinCol
                elseif save_data.formation_id == FormationType.SuperFreeSpinCol then
                    save_data.formation_id = FormationType.SuperFreeSpinRowCol
                end
            elseif v.Wheel_extra_bonus == BankSpecial.ADD_PIGGY_ON_REELS then
                save_data.super_free_spin_extra = true
            end
        end

        save_data.collect_average = math.modf(save_data.collect_average)

        SlotsGameCal.Calculate.ChangeBetAmountInRunning(
            player_game_info,
            pre_action_list,
            GetFixedAmount(save_data.super_free_spin_average_amount_count),
            super_free_spin_count,
            0
        )

        -- super freespin action
        table.insert(pre_action_list, {
            action_type = ActionType.ActionTypes.DragonFlyWithFire,
            step = save_data.map_step,
            result = save_data.map_result[save_data.map_step].result,
            free_spin_count = super_free_spin_count,
            average = save_data.collect_average,
        })
    end

    -- 进入地图action
    local action_enter_map = {
        action_type = ActionType.ActionTypes.PiggyEnterMap,
        step = save_data.map_step,
        is_enter_super_free_spin = IsBankStep(save_data.map_step)
    }

    if IsBankStep(save_data.map_step) then
        action_enter_map.map_info = GetMapInfo(session, game_room_config, player_game_info, player, save_data)
        action_enter_map.bank_index = GetCurBankIndex(save_data.map_step)
        action_enter_map.super_free_spin_count = super_free_spin_count
    end

    table.insert(pre_action_list, action_enter_map)

    -- 小轮结束清空一小轮的数据
    if IsBankStep(save_data.map_step) then
        save_data.last_spin_amount_per_round = 0
        save_data.last_spin_times_per_round = 0
        
        save_data.spin_times_per_freespin_round = 0
        save_data.spin_amount_per_freespin_round = 0
    else
        save_data.last_spin_amount_per_round = save_data.spin_amount_per_round
        save_data.last_spin_times_per_round = save_data.spin_times_per_round
    end

    save_data.spin_amount_per_round = 0
    save_data.spin_times_per_round = 0
    -- 清空一步记录的数据
    save_data.max_collect_times = nil

    return super_free_spin_count, save_data, reward
end

function SlotsPiggyJackpotSpin:Enter()
    local player = self.parameters.player
    local player_game_info = self.parameters.player_game_info
    local special_parameter = self.parameters.special_parameter
    local is_free_spin = self.parameters.is_free_spin
    local game_room_config = self.parameters.game_room_config
    local player_game_status = self.parameters.player_game_status
    local amount = self.parameters.amount
    local game_type = self.parameters.game_type
    local player_feature_condition = self.parameters.player_feature_condition
    local extern_param = self.parameters.extern_param
    local session = self.parameters.session
    local save_data = player_game_info.save_data

    -- 初始化游戏数据
    InitSaveData(session, player_game_info, player, game_room_config)

    local save_data = player_game_info.save_data

    local bonus_info = {}
    bonus_info.slots_type = save_data.formation_id
    -- 收集进度
    bonus_info.collect_times = save_data.collect_times
    bonus_info.max_collect_times = save_data.max_collect_times
    bonus_info.collect_average_value = save_data.collect_average

    if save_data.map_step == MAX_STEP then
        save_data.map_step = 0
    end

    bonus_info.free_spin_coin_value = save_data.coin_feature_pig_prize
    bonus_info.jackpot_grand = save_data.jackpot_grand
    bonus_info.jackpot_major = save_data.jackpot_major
    bonus_info.jackpot_minor = save_data.jackpot_minor
    bonus_info.jackpot_mini = save_data.jackpot_mini

    -- 地图信息
    bonus_info.map_step = save_data.map_step
    bonus_info.super_free_spin_extra = save_data.super_free_spin_extra
    -- 新版地图信息
    bonus_info.map_info = GetMapInfo(session, game_room_config, player_game_info, player, save_data)
    
    if save_data.need_clear_last_spin_info ~= 1 and save_data.last_spin_amount_per_round and save_data.last_spin_amount_per_round > 0 then
        bonus_info.is_spin_wheel = true
    end
    
    return bonus_info
end

local function InitSpecialParamter()
    return {
        piggyjackpot_enter_map_normal = 0, -- 进入普通地图的次数
        piggyjackpot_enter_map_super = 0, -- 进入super地图的次数
        piggyjackpot_enter_map_super_pig_value = 0, -- 进入super的猪的价值
        piggyjackpot_enter_map_super_parm = '', -- 进入super 的参数分布
        piggyjackpot_zhong_jackpot_grand = 0, -- 中奖次数

        piggyjackpot_zhong_jackpot_major = 0, -- 中奖次数
        piggyjackpot_zhong_jackpot_minor = 0, -- 中奖次数
        piggyjackpot_zhong_jackpot_mini = 0, -- 中奖次数

        piggyjackpot_zhong_jackpot_grand_base = 0, -- 中奖次数
        piggyjackpot_zhong_jackpot_major_base = 0, -- 中奖次数
        piggyjackpot_zhong_jackpot_minor_base = 0, -- 中奖次数
        piggyjackpot_zhong_jackpot_mini_base = 0, -- 中奖次数
        piggyjackpot_super_free_spin_reward = 0, -- super free spin 的价值
        piggyjackpot_super_free_spin_count = 0, -- super free spin 的次数

        piggyjackpot_free_spin_trigger_count = 0, -- free spin 触发的次数.不算里面的retrigger
        piggyjackpot_free_spin_total_count = 0, -- free spin 总次数
        piggyjackpot_free_spin_total_value = 0, -- free spin 总返奖

        piggyjackpot_free_spin_pig_total_value = 0, -- free spin 中猪猪的总返奖
        piggyjackpot_free_spin_pig_total_count = 0, -- free spin 中猪猪的总次数
        piggyjackpot_free_spin_extra_1 = 0, -- free spin 中 猪猪续命+1
        piggyjackpot_free_spin_extra_2 = 0, -- free spin 中 猪猪续命+2

        piggyjackpot_super_free_spin_pig_total_value = 0, -- super free spin 中猪猪的总返奖
        piggyjackpot_super_free_spin_pig_total_count = 0, -- super free spin 中猪猪的总次数

        piggyjackpot_wheel_reward = 0,

        piggyjackpot_base_spin_total_count = 0,
        piggyjackpot_base_spin_total_value = 0,
        piggyjackpot_base_zhong_total_count = 0,
        piggyjackpot_base_jackpot_grand_value = 0,
        piggyjackpot_base_jackpot_major_value = 0,
        piggyjackpot_base_jackpot_minor_value = 0,
        piggyjackpot_base_jackpot_mini_value = 0,

        piggyjackpot_free_jackpot_grand_value = 0,
        piggyjackpot_free_jackpot_major_value = 0,
        piggyjackpot_free_jackpot_minor_value = 0,
        piggyjackpot_free_jackpot_mini_value = 0,
    }
end

local function GetPiggyMulti(session, game_room_config, player_game_info, save_data, count)
    local config_table = GetConfigTable(session, game_room_config, player_game_info)
    local pig_multi_config = CommonCal.Calculate.get_config(player, "PiggyJackpotPigMultiConfig")
    local coin_collect_config = CommonCal.Calculate.get_config(player, "PiggyJackpotCoinCollectConfig")

    local cur_multiple = 0

    for i = 1, #pig_multi_config do
        -- 计算已经开了的
        if save_data.map_step < pig_multi_config[i].Bank_Stage then
            local index = 1
            if i ~= 1 then
                index = pig_multi_config[i - 1].Bank_Stage + 1
            end

            local total_collect_times = 0
            for j = index, pig_multi_config[i].Bank_Stage do
                total_collect_times = total_collect_times + coin_collect_config[j].collect_count
            end

            local dt = pig_multi_config[i].Max_Multi - pig_multi_config[i].Min_Multi
            local v = dt * count
            local t = v/total_collect_times
            -- print("----t:", t, v, total_collect_times)
            return t

            -- local total_multiple_step = (pig_multi_config[i].Max_Multi - pig_multi_config[i].Min_Multi) / pig_multi_config[i].Multi_Unit
            -- local collect_times_per_step = math.modf(total_collect_times / total_multiple_step)
            -- local cur_multiple_step = math.modf(count / collect_times_per_step)
            -- return cur_multiple_step * pig_multi_config[i].Multi_Unit
        end
    end

    return 0
end

local function _NormalSpin(session, player, game_room_config, result_row, type, player_game_info, amount, cur_formation_id, 
    pre_action_list, special_parameter, total_win_chip, free_spin_bouts)
    local save_data = player_game_info.save_data
    -- 只有非freespin的时候,才可能收集金币和进入金币feature
    local collect_pos_list = {}
    local collect_value_list = {}
    local can_coin_feature = false

    -- 获取金币图标
    collect_pos_list, collect_value_list = CollectItems(session, player, game_room_config, result_row, type, player_game_info, 
        amount, GetLine(cur_formation_id), cur_formation_id)
    can_coin_feature, save_data.coin_feature_pig_prize = CheckCoinFeature(collect_pos_list, collect_value_list, game_room_config)

    -- 根据等级限制
    local limit_config = CommonCal.Calculate.get_config(player, game_room_config.game_name .. 'CollectionLimitConfig')
    local level = player.character.level

    -- 清除数据
    if save_data.need_clear_last_spin_info == 1 then
        save_data.last_spin_amount_per_round = 0
        save_data.last_spin_times_per_round = 0
        save_data.need_clear_last_spin_info = 0
    end

    local index = 1
    for i = 1, #limit_config do
        if level < limit_config[i].Level then
            break
        end
        index = i
    end

    local can_collect = false
    -- 下注额大于限制才可以收集金币
    if amount >= limit_config[index].Limit then
        can_collect = true
    end

    if can_collect then
        local lines = _G[game_room_config.game_name .. "LineArray"]['Lines' .. GetLine(cur_formation_id)]
        -- 记录本轮spin次数
        save_data.spin_times_per_round = save_data.spin_times_per_round + 1
        -- 记录本轮spin下注总额度
        save_data.spin_amount_per_round = save_data.spin_amount_per_round + amount * #lines
        
        save_data.spin_times_per_freespin_round = save_data.spin_times_per_freespin_round + 1
        save_data.spin_amount_per_freespin_round = save_data.spin_amount_per_freespin_round + amount * #lines

        if (#collect_pos_list > 0) then
            local count = #collect_pos_list
            save_data.collect_times = save_data.collect_times + count
            save_data.collect_total_times = save_data.collect_total_times + count
            local add_multi = GetPiggyMulti(session, game_room_config, player_game_info, save_data, count)
            save_data.current_piggy_multi = save_data.current_piggy_multi + add_multi
            -- print("##### 增加倍数：", save_data.collect_times, save_data.collect_total_times, add_multi, " current:", save_data.current_piggy_multi)
        end
    end

    local old_value = save_data.collect_average
    save_data.collect_average = CalPigAverageValueFromSpin(session, player, game_room_config, save_data)
    if old_value ~= save_data.collect_average then
    end

    save_data.piggy_values = CalPiggyValues(session, game_room_config, player_game_info, player, save_data)

    -- 每次spin更新piggy value
    table.insert(pre_action_list, {
        action_type = ActionType.ActionTypes.SpinPiggyValue,
        piggy_values = save_data.piggy_values,
    })

    if (#collect_pos_list > 0) then
        if can_collect then
            special_parameter.collect_hit = #collect_pos_list

            table.insert(pre_action_list, {
                action_type = ActionType.ActionTypes.CollectItem,
                pos_list = collect_pos_list,
                cur_count = save_data.collect_times,
                max_count = save_data.max_collect_times,
                average = save_data.collect_average
            })
        end

        table.insert(pre_action_list, {
            action_type = 68,
            pos_list = collect_pos_list,
            value_list = collect_value_list,
        })
    end

    -- 如果金币大于5个,则进入free spin
    if (can_coin_feature) then
        free_spin_bouts = 5
        save_data.formation_id = FormationType.FreeSpin
        special_parameter.piggyjackpot_free_spin_trigger_count = 1

        table.insert(pre_action_list, {
            action_type = ActionType.ActionTypes.TakePhoto,
            total_value = save_data.coin_feature_pig_prize
        })
    else
        local map_reward = 0
        -- 检查是否进bank的super freespin
        free_spin_bouts, save_data, map_reward = CheckMapFeature(session, save_data, pre_action_list, player_game_info, 
            amount, game_room_config, cur_formation_id, special_parameter, player)
        total_win_chip = total_win_chip + map_reward
    end

    return total_win_chip, free_spin_bouts
end

local function _FreeSpin(session, save_data, cur_formation_id, result_row, game_room_config, type, player, total_win_chip, 
    special_parameter, pre_action_list, player_game_info, player_game_status)

    local pos_list = {}
    local value_list = {}
    local total_reward = 0
    local total_value = cur_formation_id > 2 and save_data.collect_average or save_data.coin_feature_pig_prize
    
    pos_list, value_list, free_spin_bouts, total_reward = CheckPig(result_row, total_value, game_room_config, type, player, cur_formation_id)

    player_game_info.free_spin_num = free_spin_bouts

    total_win_chip = total_win_chip + total_reward

    if #pos_list > 0 then
        if cur_formation_id == FormationType.FreeSpin then
            special_parameter.piggyjackpot_free_spin_pig_total_count = #pos_list
            special_parameter.piggyjackpot_free_spin_pig_total_value = total_reward
            if value_list then
                for i = 1, #value_list do
                    if value_list[i].parm == 1 then
                        special_parameter.piggyjackpot_free_spin_extra_1 = 1
                    elseif value_list[i].parm == 2 then
                        special_parameter.piggyjackpot_free_spin_extra_2 = 1
                    end
                end
            end
        elseif cur_formation_id > 2 then
            special_parameter.piggyjackpot_super_free_spin_pig_total_count = #pos_list
            special_parameter.piggyjackpot_super_free_spin_pig_total_value = total_reward
        end
        table.insert(pre_action_list, {
            action_type = ActionType.ActionTypes.TakePhotoFaker,
            pos_list = pos_list,
            value_list = value_list,
            count = free_spin_bouts,
        })
    end

    -- 如果是最后一次,则直接切换场景了
    local free_spin_bouts_left = GameStatusCal.Calculate.GetFreeSpinBouts(player_game_status)

    if (free_spin_bouts_left == 0 and free_spin_bouts == 0) then
        save_data.formation_id = FormationType.Normal
        local map_reward = 0
        free_spin_bouts, save_data = CheckMapFeature(session, save_data, pre_action_list, player_game_info, amount, game_room_config, cur_formation_id, special_parameter, player)
        total_win_chip = total_win_chip + map_reward
    end

    return total_win_chip, free_spin_bouts
end

function SlotsPiggyJackpotSpin:NormalSpin()
    local player = self.parameters.player
    local player_game_info = self.parameters.player_game_info
    local special_parameter = self.parameters.special_parameter
    local is_free_spin = self.parameters.is_free_spin
    local game_room_config = self.parameters.game_room_config
    local player_game_status = self.parameters.player_game_status
    local amount = self.parameters.amount
    local game_type = self.parameters.game_type
    local player_feature_condition = self.parameters.player_feature_condition
    local extern_param = self.parameters.extern_param
    local session = self.parameters.extern_param.session
    local save_data = player_game_info.save_data
    
    local total_win_chip, free_spin_bouts, slots_win_chip = 0, 0, 0
    local result_row = {}
    local all_prize_list = {}

    local formation_list = {}
    local reel_file_name
    local pre_action_list = {}
    local slots_spin_list = {}
    local session = extern_param.session

    local special_parameter = InitSpecialParamter()

    local type = _G[game_room_config.game_name .. "TypeArray"].Types

    InitSaveData(session, player_game_info, player, game_room_config)
    local save_data = player_game_info.save_data

    if not is_free_spin then
        save_data.formation_id = FormationType.Normal
        save_data.super_free_spin_extra = false
        save_data.super_free_spin_total_spin_count = save_data.super_free_spin_total_spin_count + 1
        save_data.super_free_spin_total_amount_count = save_data.super_free_spin_total_amount_count + amount
        save_data.super_free_spin_average_amount_count = save_data.super_free_spin_total_amount_count / save_data.super_free_spin_total_spin_count
    else
        if save_data.formation_id > 2 then
            amount = GetFixedAmount(save_data.super_free_spin_average_amount_count)
        end
    end

    -- 当前这一轮的formation_id,不管特新如何变化
    local cur_formation_id = save_data.formation_id
    
    -- 这里差一个 reel表切换
    local reel_file, weight_file = GetReelConfig(session, game_room_config, cur_formation_id, save_data.super_free_spin_extra, player_game_info, amount)

    result_row, reel_file_name = SlotsGameCal.Calculate.GenItemResultWithWeight(player, 
        game_room_config.game_type, is_free_spin, game_room_config, 
        reel_file, weight_file, GetFormation(cur_formation_id))

    -- 替换jackpot图标,不影响赔付
    local jackpot_win_chip = 0
    if cur_formation_id <= 2 then
        result_row, jackpot_win_chip, pre_action_list = CheckJackpot(session, result_row, pre_action_list, is_free_spin, player_game_info, game_room_config, save_data, player, special_parameter, amount)
        jackpot_win_chip = math.floor(jackpot_win_chip * amount * 20)
    end

    -- 计算大奖
    local left_or_right = game_room_config.direction_type
    local payrate_file = CommonCal.Calculate.get_config(player, game_room_config.game_name .. "PayrateConfig")
    local prize_items, total_payrate = SlotsGameCal.Calculate.GenPrizeInfo(result_row, game_room_config, payrate_file, left_or_right, type, GetFormation(cur_formation_id), 'Lines' .. GetLine(cur_formation_id))

    table.insert(all_prize_list, prize_items)
    -- 基础奖金
    slots_win_chip = total_payrate * amount
    total_win_chip = slots_win_chip
    total_win_chip = total_win_chip + jackpot_win_chip
    total_win_chip = math.modf(total_win_chip)

    local free_spin_total_win_chip = player_game_info.free_total_win

    if is_free_spin then
        total_win_chip, free_spin_bouts = _FreeSpin(session, save_data, cur_formation_id, result_row, game_room_config, type, player, total_win_chip, 
            special_parameter, pre_action_list, player_game_info, player_game_status)
    else
        total_win_chip, free_spin_bouts = _NormalSpin(session, player, game_room_config, result_row, type, player_game_info, amount, cur_formation_id, 
            pre_action_list, special_parameter, total_win_chip, free_spin_bouts)
    end

    if free_spin_bouts > 0 then
        if save_data.formation_id == FormationType.FreeSpin then
            GameStatusCal.Calculate.AddGameStatus(player_game_status, GameStatusDefine.AllTypes.FreeSpinGame, free_spin_bouts, 1, amount)
        else
            GameStatusCal.Calculate.AddGameStatus(player_game_status, GameStatusDefine.AllTypes.FreeSpinGame, free_spin_bouts, 3, amount)
        end
    end

    -- 增加取整
    total_win_chip = math.floor(total_win_chip)
    free_spin_total_win_chip = math.floor(free_spin_total_win_chip)

    free_spin_total_win_chip = free_spin_total_win_chip + total_win_chip

    if save_data.formation_id ~= cur_formation_id then
        -- formation id 发生变化发送action
        table.insert(pre_action_list, {
            action_type = ActionType.ActionTypes.PiggyFormationId,
            formation_id = save_data.formation_id,
            super_free_spin_extra = save_data.super_free_spin_extra 
        })

        if cur_formation_id == FormationType.FreeSpin and save_data.formation_id ~= FormationType.FreeSpin then
            table.insert(pre_action_list, {
                action_type = ActionType.ActionTypes.Ice777Respin,
                win = free_spin_total_win_chip,
            })
        end

        -- cur_formation_id 大于free spin即为super spin
        if cur_formation_id > FormationType.FreeSpin and save_data.formation_id == FormationType.Normal then
            local temp_map_step = (save_data.map_step == 0 or save_data.map_step > MAX_STEP) and MAX_STEP or save_data.map_step
            table.insert(pre_action_list, {
                action_type = ActionType.ActionTypes.Ice777Dobule7,
                result = save_data.map_result[temp_map_step].result,
                win = free_spin_total_win_chip,
                map_info = GetMapInfo(session, game_room_config, player_game_info, player, save_data),
            })

            if save_data.map_step >= MAX_STEP then
                save_data.map_step = 0
                save_data.map_result = nil
                save_data.max_collect_times = nil
            end

            save_data.super_free_spin_total_spin_count = 0
            save_data.super_free_spin_total_amount_count = 0
            save_data.current_piggy_multi = nil

            SlotsGameCal.Calculate.RestoreBetAmountInRunning(player_game_info)
        end
    end

    if cur_formation_id > FormationType.FreeSpin then
        special_parameter.piggyjackpot_super_free_spin_reward = total_win_chip
        special_parameter.piggyjackpot_super_free_spin_count = 1
    end

    if cur_formation_id == FormationType.FreeSpin then
        special_parameter.piggyjackpot_free_spin_total_count = 1
        special_parameter.piggyjackpot_free_spin_total_value = total_win_chip
    end

    if cur_formation_id == FormationType.Normal then
        special_parameter.piggyjackpot_base_spin_total_count = 1
        special_parameter.piggyjackpot_base_spin_total_value = slots_win_chip
        if slots_win_chip > 0 then
            special_parameter.piggyjackpot_base_zhong_total_count = 1
        end
    end
    
    table.insert(slots_spin_list, {
        item_ids = json.encode(SlotsGameCal.Calculate.TransResultToCList(result_row, game_room_config, GetFormation(cur_formation_id))),
        prize_items = prize_items,
        win_chip = total_win_chip,
        slots_win_chip = total_win_chip,
        pre_action_list = json.encode(pre_action_list),
        final_item_ids = json.encode(SlotsGameCal.Calculate.TransResultToCList(result_row, game_room_config, GetFormation(cur_formation_id))),
    })

    table.insert(formation_list, {
        slots_spin_list = slots_spin_list,
        id = GetGroupId(cur_formation_id),
    })

    local result = {}
    result.final_result = final_result --结果数组
    result.total_win_chip = total_win_chip  --总奖金
    result.all_prize_list = all_prize_list --所有连线列表
    result.free_spin_bouts = free_spin_bouts --freespin的次数
    result.formation_list = formation_list --阵型列表
    result.reel_file_name = reel_file_name --reel表名
    result.slots_win_chip = slots_win_chip --总奖励
    result.special_parameter = special_parameter --其他参数，主要给模拟器传参
    return result
end

IsBonusGame = function(game_room_config, player)
    return false
end

local function RandResult(session, game_room_config, player_game_info, player, step)
    local lineNum = LineNum[game_room_config.game_type]()
    local total_amount = player_game_info.bet_amount * lineNum
    local config_table = SlotsGameCal.Calculate.GetMapConfigTable(session, game_room_config, player_game_info, total_amount)
    local config = CommonCal.Calculate.get_config(player, config_table.wheel_config)
    local options = {}
    local result = {options = options}
    
    for i = 1, #config do
        local item = config[i]
        if item.Wheel == step then
            table.insert(options, item)
        end
    end

    if #options == 0 then
        return
    end

    local list_options = {}
    local special = 0
    for i = 1, #options do
        if options[i].Wheel_extra_bonus > 0 then
            special = options[i].Wheel_extra_bonus
        end
        table.insert(list_options, options[i].Probability)
    end

    local index = math.rand_weight(player, list_options)
    result.final_index = index or 0
    result.special = special
    return result
end

function SlotsPiggyJackpotSpin:SpinWheelEnter()
    local player_game_status = self.parameters.player_game_status
    local player = self.parameters.player
    local game_room_config = self.parameters.game_room_config
    local parameter = json.decode(self.parameters.parameter)
    local player_game_info = self.parameters.player_game_info
    local game_type = self.parameters.game_type
    local save_data = player_game_info.save_data
    local session = self.parameters.session

    local save_data = player_game_info.save_data

    if save_data.last_spin_amount_per_round == 0 or save_data.last_spin_times_per_round == 0 then
        return
    end
    
    local spin_amount_per_round = save_data.last_spin_amount_per_round
    local spin_times_per_round = save_data.last_spin_times_per_round
    if spin_times_per_round == 0 then spin_times_per_round = 1 end

    local spin_average_amount = spin_amount_per_round / spin_times_per_round
    spin_average_amount = math.modf(spin_average_amount / 1000) * 1000

    local step = save_data.map_step

    if IsBankStep(step) then return end

    local result = save_data.map_result[step]

    if save_data.map_result[step] == nil then
        result = RandResult(session, game_room_config, player_game_info, player, step)
        if not result then return end
        save_data.map_result[step] = result
    end

    local wheel_options = {}

    for i=1, #result.options do
        wheel_options[i] = {}
        wheel_options[i].wheel_value = result.options[i].Wheel_bonus * spin_average_amount
        wheel_options[i].feature_type = result.options[i].Wheel_extra_bonus
    end

    local info = {
        map_info = GetMapInfo(session, game_room_config, player_game_info, player, save_data),
        wheel_options_info = wheel_options,
        wheel_final_index = result.final_index
    }

    return info
end

function SlotsPiggyJackpotSpin:SpinWheelAdEnter()
    local player_game_status = self.parameters.player_game_status
    local player = self.parameters.player
    local game_room_config = self.parameters.game_room_config
    local parameter = json.decode(self.parameters.parameter)
    local player_game_info = self.parameters.player_game_info
    local game_type = self.parameters.game_type
    local save_data = player_game_info.save_data
    local session = self.parameters.session

    local save_data = player_game_info.save_data

    if save_data.last_spin_amount_per_round == 0 or save_data.last_spin_times_per_round == 0 then
        return
    end
    
    local spin_amount_per_round = save_data.last_spin_amount_per_round
    local spin_times_per_round = save_data.last_spin_times_per_round
    if spin_times_per_round == 0 then spin_times_per_round = 1 end

    local spin_average_amount = spin_amount_per_round / spin_times_per_round
    spin_average_amount = math.modf(spin_average_amount / 1000) * 1000

    local step = save_data.map_step

    if IsBankStep(step) then return end

    local result = save_data.map_result[step]

    if save_data.map_result[step] == nil or true then
        result = RandResult(session, game_room_config, player_game_info, player, step)
        if not result then return end
        save_data.map_result[step] = result
    end

    local wheel_options = {}

    for i=1, #result.options do
        wheel_options[i] = {}
        wheel_options[i].wheel_value = result.options[i].Wheel_bonus * spin_average_amount
        wheel_options[i].feature_type = result.options[i].Wheel_extra_bonus
    end

    local info = {
        map_info = GetMapInfo(session, game_room_config, player_game_info, player, save_data),
        wheel_options_info = wheel_options,
        wheel_final_index = result.final_index
    }

    return info
end

function SlotsPiggyJackpotSpin:SpinWheelFinish()
    local player_game_status = self.parameters.player_game_status
    local player = self.parameters.player
    local game_room_config = self.parameters.game_room_config
    local parameter = json.decode(self.parameters.parameter)
    local player_game_info = self.parameters.player_game_info
    local game_type = self.parameters.game_type
    local save_data = player_game_info.save_data
    local session = self.parameters.session

    local save_data = player_game_info.save_data

    if save_data.last_spin_amount_per_round == 0 or save_data.last_spin_times_per_round == 0 then
        return
    end
    
    local spin_amount_per_round = save_data.last_spin_amount_per_round
    local spin_times_per_round = save_data.last_spin_times_per_round
    if spin_times_per_round == 0 then spin_times_per_round = 1 end

    local spin_average_amount = spin_amount_per_round / spin_times_per_round
    spin_average_amount = math.modf(spin_average_amount / 1000) * 1000

    local step = save_data.map_step
    local result = save_data.map_result[step]

    if not result then
        return
    end

    if IsBankStep(step) then return end

    local feature_type = result.options[result.final_index].Wheel_extra_bonus

    local info = {
        map_info = GetMapInfo(session, game_room_config, player_game_info, player, save_data),
        wheel_options_info = {
            wheel_value = math.floor(result.options[result.final_index].Wheel_bonus * spin_average_amount),
            feature_type = feature_type,
            wheel_final_index = result.final_index
        }
    }

    if feature_type == BankSpecial.INCREASE_PIGGY_COINS then
        save_data.current_piggy_multi = save_data.current_piggy_multi * 1.5
    end
    
    save_data.need_clear_last_spin_info = 1

    local content = {
        win_chip = math.floor(result.options[result.final_index].Wheel_bonus * spin_average_amount)
    }

    return content
end