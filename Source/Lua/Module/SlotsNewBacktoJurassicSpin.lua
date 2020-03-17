require "Common/SlotsGameCalculate" -- 重写的接口
require "Common/SlotsGameCal" -- 旧的接口
require "Common/LineNum"
module("SlotsNewBacktoJurassicSpin", package.seeall)

function SlotsNewBacktoJurassicSpin:Enter()
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

    -- 没有bonus游戏，直接返回
    local bonus_info = {}
    local save_data = player_game_info.save_data

    if not save_data.jackpot_param_v2 then
        save_data.jackpot_param_v2 = {}
        local config = CommonCal.Calculate.get_config(player, "NewBacktoJurassicJackpotConfig")
        CommonCal.Calculate.InitJackpotParam(save_data.jackpot_param_v2, config)
    end

    bonus_info.jackpot_param = CommonCal.Calculate.GetJakcpotParamToClient(save_data.jackpot_param_v2)

    return bonus_info
end

-- 随机赔付值
local function RandExtraPayoutValue(player, grade, is_free_spin)
    local config = CommonCal.Calculate.get_config(player, "NewBacktoJurassicExtraPayoutValueConfig")
    local weights = {}

    for i = 1, #config do
        if is_free_spin then
            table.insert(weights, config[i].free_probability[grade])
        else
            table.insert(weights, config[i].base_probability[grade])
        end
    end

    local rand_config = math.rand_weight(player, weights)
    return config[rand_config].prize_type
end

-- 获取下注配置
local function GetBetAmountConfig(player, player_game_info, amount)
    local config = _G[GameMapConfig[player_game_info.game_type].bet_amount_config]

    for i = 1, #config do
        if config[i].single_amount == amount then
            return config[i]
        end
    end
end

-- 获取图标中额外赔付的概率
local function GetExtraRandRate(player, item_id, grade, is_free_spin)
    local config = CommonCal.Calculate.get_config(player, "NewBacktoJurassicExtraPayoutConfig")

    if is_free_spin then
        return config[item_id].free_probability[grade]
    else
        return config[item_id].base_probability[grade]
    end
end

local function AddRecord(record_info, item_id, type, value, is_free_spin)
    if not is_free_spin then
        record_info = record_info.base
    else
        record_info = record_info.free
    end

    record_info[item_id] = record_info[item_id] or {}
    record_info[item_id][type] = record_info[item_id][type] or {
        count = 0,
        value = 0,
        type = type,
        item_id = item_id,
        is_free_spin = is_free_spin,
    }

    record_info[item_id][type].count = record_info[item_id][type].count + 1
    record_info[item_id][type].value = record_info[item_id][type].value + value
end

local function TransformExtraPayout(extra)
    local pos_list = {}
    local value_list = {}

    for row, v in pairs(extra) do
        for col, multi in pairs(v) do
            table.insert(pos_list, {row=row, col=col})
            table.insert(value_list, multi)
        end
    end

    return value_list, pos_list
end

local function GenerateFakeExtra(player, config, pos_list, result_row)
    local extra = {}

    for i = 1, #result_row do
        for j=3, #result_row[i] do
            local row = i
            local col = j
            local item_id = result_row[i][j]

            if col >= 3 and item_id == 3 then
                -- 霸王龙直接添加
                extra[i] = extra[i] or {}
                extra[i][j] = RandExtraPayoutValue(player, config.bet_interval, is_free_spin)
            elseif col >= 3 then
                -- 普通元素随机添加
                local rate = GetExtraRandRate(player, item_id, config.bet_interval, is_free_spin)
                if math.rand_prob(player, rate) then
                    extra[i] = extra[i] or {}
                    extra[i][j] = RandExtraPayoutValue(player, config.bet_interval, is_free_spin)
                end
            end
        end
    end
    return extra
end

local function ConvertBackExtra(items)
    local extra_payout = {}
    for i=1, #items do
        local r = items[i].row
        local c = items[i].col
        extra_payout[r] = extra_payout[r] or {}
        extra_payout[r][c] = items[i].multi
    end
    return extra_payout
end

local function ConvertExtra(extra_payout, result)
    local items = {}
    for row, v in pairs(extra_payout) do
        for col, multi in pairs(v) do
            table.insert(items, {row = row, col = col, multi = multi, item_id = result[row][col]})
        end
    end
    return items
end

-- 添加额外赔付
local function AddExtraPayout(player_game_info, prize_items, pos_list, player, game_room_config, amount, result_row, pre_action_list, is_free_spin, record_info)
    local config = GetBetAmountConfig(player, player_game_info, amount)

    if #prize_items == 0 then
        local extra = GenerateFakeExtra(player, config, pos_list, result_row)
        table.insert(pre_action_list, {action_type = ActionType.ActionTypes.ExtraPayout, 
            extra_payout = ConvertExtra(extra, result_row)})
        return {multi = 0, jackpots = {}}
    end

    local multi = 0
    local jackpots = {}

    local extra = {}

    --随机添加
    for i = 1, #result_row do
        for j=3, #result_row[i] do
            local row = i
            local col = j
            local item_id = result_row[i][j]

            if col >= 3 and item_id == 3 then
                -- 霸王龙直接添加
                extra[i] = extra[i] or {}
                extra[i][j] = RandExtraPayoutValue(player, config.bet_interval, is_free_spin)
            elseif col >= 3 then
                -- 普通元素随机添加
                local rate = GetExtraRandRate(player, item_id, config.bet_interval, is_free_spin)
                if math.rand_prob(player, rate) then
                    extra[i] = extra[i] or {}
                    extra[i][j] = RandExtraPayoutValue(player, config.bet_interval, is_free_spin)
                end
            end
        end
    end

    --给中奖元素添加
    for k = 1, #pos_list do
        local row = pos_list[k].row
        local col = pos_list[k].col
        local i = row
        local j = col
        local item_id = result_row[i][j]

        if col >= 3 and item_id == 3 then
            -- 霸王龙直接添加
            extra[i] = extra[i] or {}
            extra[i][j] = RandExtraPayoutValue(player, config.bet_interval, is_free_spin)

            if extra[i][j] > 1000 then
                table.insert(jackpots, {item_id = item_id, row=i,col=j, type = extra[i][j], is_free_spin=is_free_spin})
            else
                multi = multi + extra[i][j]
                AddRecord(record_info, item_id, extra[i][j], extra[i][j] * record_info.lineNum * amount, is_free_spin)
            end
        elseif col >= 3 then
            -- 普通元素随机添加
            local rate = GetExtraRandRate(player, item_id, config.bet_interval, is_free_spin)
            if math.rand_prob(player, rate) then
                extra[i] = extra[i] or {}
                extra[i][j] = RandExtraPayoutValue(player, config.bet_interval, is_free_spin)

                if extra[i][j] > 1000 then
                    table.insert(jackpots, {item_id = item_id, row=i,col=j, type = extra[i][j], is_free_spin=is_free_spin})
                else
                    multi = multi + extra[i][j]
                    AddRecord(record_info, item_id, extra[i][j], extra[i][j] * record_info.lineNum * amount, is_free_spin)
                end
            end
        end
    end
    
    table.insert(pre_action_list, {action_type = ActionType.ActionTypes.ExtraPayout, extra_payout = ConvertExtra(extra, result_row)})

    local extra_info = {multi = multi, jackpots = jackpots,}

    return extra_info
end

local function WinJackpots(save_data, total_amount, jackpots, record_info)
    if #jackpots == 0 or not save_data.jackpot_param_v2 then
        return 0, {}
    end

    local jackpot_types = {}

    local config = CommonCal.Calculate.get_config(player, "NewBacktoJurassicJackpotConfig")

    local jackpot_param_v2 = save_data.jackpot_param_v2
    local total_value = 0

    for i = 1, #jackpots do
        local type = jackpots[i].type - 1000
        table.insert(jackpot_types, {type = type, row=jackpots[i].row, col=jackpots[i].col})
        local point = CommonCal.Calculate.GetJackpotPoolChipVal(jackpot_param_v2, type, total_amount)
        local add_value = point
        total_value = total_value + add_value
        AddRecord(record_info, jackpots[i].item_id, jackpots[i].type, add_value, jackpots[i].is_free_spin)
        CommonCal.Calculate.ResetJackpotExtraChip(jackpot_param_v2, type) 
    end

    return total_value, jackpot_types
end

local function UpdateFreeSpin(player, player_game_info, scatter_count, is_free_spin)
    local config = CommonCal.Calculate.get_config(player, "NewBacktoJurassicScatterConfig")

    if scatter_count <= 0 then
        return 0
    end

    if scatter_count > 5 then
        scatter_count = 5
    end

    local free_spin_bouts = 0

    if is_free_spin then
        if config[scatter_count].free_spin_extra_bouts > 0 then
            free_spin_bouts = config[scatter_count].free_spin_extra_bouts
            player_game_info.free_spin_num = free_spin_bouts
        end
    else
        if config[scatter_count].free_spin_bouts > 0 then
            free_spin_bouts = config[scatter_count].free_spin_bouts
        end
    end

    return free_spin_bouts
end

local function Convert(player, player_game_info, amount, item_ids)
    local config = GetBetAmountConfig(player, player_game_info, amount)

    for i=1, #item_ids do
        for j=1, #item_ids[i] do
            if item_ids[i][j] == 3 then
                if config.bet_interval ~= 1 then
                    item_ids[i][j] = 10 + config.bet_interval
                end
            end
        end
    end
end

function SlotsNewBacktoJurassicSpin:NormalSpin()
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

    local session = extern_param.session

    local lineNum = LineNum[player_game_info.game_type]()
    local total_amount = lineNum * amount

    -- 总赢取筹码，freespin次数
    local total_win_chip, slots_win_chip = 0, 0

    local result_row = {}
    local all_prize_list = {}

    local formation_list = {}
    local reel_file_name

    local type = _G[game_room_config.game_name .. "TypeArray"].Types

    if save_data.total_free_spin_times == nil or not is_free_spin then
        -- 记录freespin的次数    
        save_data.total_free_spin_times = 0
    end

    local config_table = SlotsGameCal.Calculate.GetMapConfigTable(session, game_room_config, player_game_info, amount * lineNum)
    local reel_file = nil
    local weight_file = nil

    if is_free_spin then
        reel_file = config_table.feature_reel_config
        weight_file = config_table.feature_reel_weight_config
    else
        reel_file = config_table.base_reel_config
        weight_file = config_table.base_reel_weight_config
    end

    -- 生成items
    result_row, reel_file_name = SlotsGameCal.Calculate.GenItemResultWithWeight(player, game_type, is_free_spin, 
        game_room_config, reel_file, weight_file)
    
    local final_result = table.DeepCopy(result_row)

    -- 计算大奖
    local left_or_right = game_room_config.direction_type
    local payrate_file = CommonCal.Calculate.get_config(player, game_room_config.game_name .. "PayrateConfig")
    local other_file = CommonCal.Calculate.get_config(player, game_room_config.game_name .. "OthersConfig")

    local prize_items, pos_list, total_payrate, total_line_count = GenReelWayPrizeInfo(final_result, game_room_config, payrate_file, other_file[1].Base_Bet_Ratio)

    table.insert(all_prize_list, prize_items)

    -- FreeSpin判断处理
    local cols = {1, 2, 3, 4, 5}
    local scatter_count = SlotsGameCal.Calculate.GetItemCount(result_row, game_room_config, type.Scatter, cols)

    local free_spin_bouts = UpdateFreeSpin(player, player_game_info, scatter_count, is_free_spin)

    if free_spin_bouts > 0 then
        GameStatusCal.Calculate.AddGameStatus(player_game_status, GameStatusDefine.AllTypes.FreeSpinGame, free_spin_bouts, 1, amount)
    end

    local slots_spin_list = {}
    local pre_action_list = {}

    -- 添加额外赔付
    local record_info = {lineNum = lineNum, base={}, free={}}
    local extra_info = AddExtraPayout(player_game_info, prize_items, pos_list, player, game_room_config, amount, result_row, pre_action_list, is_free_spin, record_info)

    -- 更新jackpot
    CommonCal.Calculate.UpdateJackpotExtraChip(is_free_spin, "NewBacktoJurassicJackpotConfig", save_data, total_amount, pre_action_list)

    local jackpot_win_chip, jackpot_types = WinJackpots(save_data, total_amount, extra_info.jackpots, record_info)

    if #jackpot_types > 0 then
        table.insert(pre_action_list, {
            action_type = ActionType.ActionTypes.WinGameJackpot,
            jackpot_types = jackpot_types,
        })
    end

    slots_win_chip = total_payrate * amount

    if slots_win_chip > 0 then
        slots_win_chip = slots_win_chip + extra_info.multi * total_amount + jackpot_win_chip
    end

    total_win_chip = slots_win_chip

    local reel_ways_info = {}
    reel_ways_info.pos_list = pos_list
    reel_ways_info.total_line_count = total_line_count

    local item_ids = SlotsGameCal.Calculate.TransResultToCList(result_row, game_room_config)
    local final_item_ids = SlotsGameCal.Calculate.TransResultToCList(final_result, game_room_config)

    Convert(player, player_game_info, amount, item_ids)
    Convert(player, player_game_info, amount, final_item_ids)

    --处理最后发送总值总次数
    if is_free_spin then
        save_data.total_free_spin_times = save_data.total_free_spin_times or 0
        save_data.total_free_spin_times = save_data.total_free_spin_times + 1
    else
        save_data.total_free_spin_times = nil
    end

    local free_spin_bouts_left = GameStatusCal.Calculate.GetFreeSpinBouts(player_game_status)

    if is_free_spin and free_spin_bouts_left == 0 and free_spin_bouts == 0 then
        player_game_info.free_total_win = player_game_info.free_total_win or 0
        local free_total_win = player_game_info.free_total_win + total_win_chip

        table.insert(pre_action_list, {
            action_type = ActionType.ActionTypes.TotalFreeSpinWin,
            free_total_win = free_total_win,
            total_free_spin_times = save_data.total_free_spin_times,
        })
    end

    table.insert(
        slots_spin_list,
        {
            item_ids = json.encode(item_ids),
            prize_items = prize_items,
            win_chip = total_win_chip,
            pre_action_list = json.encode(pre_action_list),
            final_item_ids = json.encode(final_item_ids),
            reel_ways_info = json.encode(reel_ways_info),
            ways_type = 1,
            record_info = record_info,
        }
    )

    table.insert(formation_list, {slots_spin_list = slots_spin_list, id = 1,})

    LOG(RUN, INFO).Format("[SlotsNewBackJurassicSpin][Spin] end player id %s", player.id)

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

IsBonusGame = function(game_room_config, player, player_game_info)
    if (player_game_info.bonus_game_type > 0) then
        return true
    end
    return false
end

