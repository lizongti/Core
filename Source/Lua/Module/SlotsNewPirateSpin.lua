require "Common/SlotsGameCalculate" --重写的接口
require "Common/SlotsGameCal" --旧的接口
require "Module/SlotsBaseSpin"

module("SlotsNewPirateSpin", package.seeall)

local function trigger_bonus(result, type)
    local bonus_count = 0
    for row_index, row in ipairs(result) do
        for grid_index, grid in ipairs(row) do
            if grid == type.Bonus then
                bonus_count = bonus_count + 1
            end
        end
    end
    return bonus_count >= 3
end

Enter = function(self)
    local task = self.parameters.task
    local player = self.parameters.player
    local game_room_config = self.parameters.game_room_config
    local player_game_info = self.parameters.player_game_info
    local save_data = player_game_info.save_data

    local bonus_info = {}
    if (player_game_info.bonus_game_type > 0) then
        bonus_info.bonus_game = true
    end

    return bonus_info
end

Spin = function(self)
    local player = self.parameters.player
    local game_type = self.parameters.game_type
    local amount = self.parameters.amount
    local is_free_spin = self.parameters.is_free_spin
    local game_room_config = self.parameters.game_room_config
    local player_game_info = self.parameters.player_game_info
    local player_game_status = self.parameters.player_game_status
    local player_feature_condition = self.parameters.player_feature_condition
    local extern_param = self.parameters.extern_param
    local formation_id = self.parameters.formation_id
    local session = extern_param.session
    local lineNum = LineNum[game_type]()
    local formation = _G[game_room_config.game_name .. "FormationArray"]["Formation" .. formation_id]
    local save_data = player_game_info.save_data
    local config_table =
        SlotsGameCal.Calculate.GetMapConfigTable(session, game_room_config, player_game_info, amount * lineNum)

    -- 滚轴
    local reel_file = nil
    local weight_file = nil
    local type = _G[game_room_config.game_name .. "TypeArray"].Types
    if is_free_spin then
        reel_file = config_table.feature_reel_config
        weight_file = config_table.feature_reel_weight_config
    else
        reel_file = config_table.base_reel_config
        weight_file = config_table.base_reel_weight_config
    end

    local origin_result, reel_file_name, reel_index_list =
        SlotsGameCal.Calculate.GenItemResultWithWeight(
        player,
        game_type,
        is_free_spin,
        game_room_config,
        reel_file,
        weight_file
    )
    local final_result = origin_result
    local free_spin_bouts = 0

    -- 赔率
    local left_or_right = game_room_config.direction_type
    local payrate_file = CommonCal.Calculate.get_config(player, game_room_config.game_name .. "PayrateConfig")
    local other_file = CommonCal.Calculate.get_config(player, game_room_config.game_name .. "OthersConfig")
    local bet_ratio = other_file[1].Base_Bet_Ratio

    -- 获得连线结果
    local options = {
        spin_type = is_free_spin and 2 or 1
    }

    local prize_items, total_payrate =
        SlotsGameCal.Calculate.GenPrizeItems(
        player,
        final_result,
        game_room_config,
        payrate_file,
        left_or_right,
        type,
        options
    )

    -- 将连线结果放入all_prize_list
    local all_prize_list = {prize_items}

    -- slots赢取的筹码 = 倍率和 * 筹码
    local slots_win_chip = total_payrate * amount
    local total_win_chip = slots_win_chip

    local pre_action_list = {}

    -- 检查第二列和第四列是否有wild
    local second_col_has_wild = false
    local forth_col_has_wild = false
    local trigger_nudge = false
    for row_index, row in ipairs(origin_result) do
        if row[2] == type.Wild then
            second_col_has_wild = true
            break
        end
    end
    for row_index, row in ipairs(origin_result) do
        if row[4] == type.Wild then
            forth_col_has_wild = true
            break
        end
    end
    if second_col_has_wild and forth_col_has_wild then
        trigger_nudge = true
    end

    -- 检查是否有bonus
    local has_trigger_bonus = trigger_bonus(origin_result, type)

    -- 第一滚轴移动一个格子
    if trigger_nudge then
        local config = CommonCal.Calculate.get_config(player, reel_file_name)
        local sequence_length = #config[1].sequence_array
        local nudge_reel_index =
            reel_index_list[1] - 1 > 0 and reel_index_list[1] - 1 or reel_index_list[1] - 1 + sequence_length
        local nudge_item_id = config[1].sequence_array[nudge_reel_index]
        local nudge_result = table.DeepCopy(origin_result)
        -- 滚动reel 1
        for index = #nudge_result, 2, -1 do
            nudge_result[index][1] = nudge_result[index - 1][1]
        end
        nudge_result[1][1] = nudge_item_id

        -- 再次触发bonus
        if not has_trigger_bonus then
            has_trigger_bonus = trigger_bonus(nudge_result, type)
        end

        local nudge_prize_items, nudge_total_payrate =
            SlotsGameCal.Calculate.GenPrizeItems(
            player,
            nudge_result,
            game_room_config,
            payrate_file,
            left_or_right,
            type,
            options
        )
        local nudge_slots_win_chip = nudge_total_payrate * amount
        total_win_chip = total_win_chip + nudge_slots_win_chip
        local nudge_all_prize_list = {nudge_prize_items}
        table.insert(
            pre_action_list,
            {
                action_type = ActionType.ActionTypes.NudgeReel,
                nudge_item_id = nudge_item_id,
                all_prize_list = nudge_all_prize_list,
                origin_chips = slots_win_chip,
                nudge_slots_win_chip = nudge_slots_win_chip
            }
        )
    end

    -- 添加bonus的game status
    if has_trigger_bonus then
        --设置游戏状态
        player_game_info.bonus_game_type = 3 --记录进入bonus_game
        --添加action
        table.insert(pre_action_list, {action_type = ActionType.ActionTypes.EnterBonus})
    end

    --最后一次数据记录
    local slots_spin_list = {}
    table.insert(
        slots_spin_list,
        {
            item_ids = json.encode(SlotsGameCal.Calculate.TransResultToCList(origin_result, game_room_config)),
            prize_items = prize_items,
            win_chip = total_win_chip,
            slots_win_chip = slots_win_chip,
            pre_action_list = json.encode(pre_action_list),
            final_item_ids = json.encode(SlotsGameCal.Calculate.TransResultToCList(final_result, game_room_config)),
            ways_type = 2
        }
    )

    --客户端接收的表
    local formation_list = {}
    table.insert(
        formation_list,
        {
            slots_spin_list = slots_spin_list,
            id = 1
        }
    )

    -- 返回结果
    local result = {
        final_result = final_result, -- 结果数组
        total_win_chip = total_win_chip, -- 总奖金
        all_prize_list = all_prize_list, -- 所有连线列表
        free_spin_bouts = free_spin_bouts, -- freespin的次数
        formation_list = formation_list, -- 阵型列表
        reel_file_name = reel_file_name, -- reel表名
        slots_win_chip = slots_win_chip -- ↓转动奖金
    }
    return result
end

IsBonusGame = function(game_room_config, player, player_game_info)
    if (player_game_info.bonus_game_type > 0) then
        return true
    end
    return false
end

-----------------------------------------------
-- Bonus Game
-----------------------------------------------
BonusStart = function(self)
    local player_game_status = self.parameters.player_game_status
    local player = self.parameters.player
    local game_room_config = self.parameters.game_room_config
    local parameter = json.decode(self.parameters.parameter)
    local player_game_info = self.parameters.player_game_info
    local amount = player_game_info.bet_amount
    local game_type = self.parameters.game_type
    local session = self.parameters.session
    local lineNum = LineNum[player_game_info.game_type]()
    local bonus_config = CommonCal.Calculate.get_config(player, game_room_config.game_name .. "BonusConfig")
    local config_table =
        SlotsGameCal.Calculate.GetMapConfigTable(session, game_room_config, player_game_info, amount * lineNum)

    local bonus_type_weight_config = CommonCal.Calculate.get_config(player, config_table.bonus_type_weight_config)
    local content = {}

    local save_data = player_game_info.save_data
    if save_data.last_bonus then
        return save_data.last_bonus
    end

    local bonus_pos = save_data.bonus_pos or 1
    local bonus_step = math.random(6)
    local bonus_step_max = #bonus_config
    local bonus_new_pos = (bonus_pos - 1 + bonus_step) % (bonus_step_max) + 1
    local bonus_type = bonus_config[bonus_new_pos].bonus_type

    -- 解析配置
    local bonus_weight_types = {}
    for _, v in ipairs(bonus_type_weight_config) do
        bonus_weight_types[v.bonus_type] = bonus_weight_types[v.bonus_type] or {}
        bonus_weight_types[v.bonus_type][v.id] = v.bonus_weight
    end

    -- 获得奖励
    local bonus_rate = 0
    local bonus_free_spins_times = 0
    if bonus_new_pos < bonus_pos then
        local id = math.rand_weight(player, bonus_weight_types[1])
        bonus_rate = bonus_rate + bonus_type_weight_config[id].bonus_times
    end
    if bonus_type == 2 then
        local id = math.rand_weight(player, bonus_weight_types[2])
        bonus_rate = bonus_rate + bonus_type_weight_config[id].bonus_times
    elseif bonus_type == 3 then
        local id = math.rand_weight(player, bonus_weight_types[3])
        bonus_free_spins_times = bonus_free_spins_times + bonus_type_weight_config[id].bonus_times
    end

    -- 计算奖励
    local total_bet = amount * lineNum
    local bonus_win_chip = total_bet * bonus_rate

    -- 存储数据
    save_data.bonus_pos = bonus_new_pos
    save_data.last_bonus = {
        bonus_old_pos = bonus_pos,
        bonus_new_pos = bonus_new_pos,
        bunus_step = bonus_step,
        bonus_type = bonus_type,
        bonus_rate = bonus_rate,
        bonus_free_spins_times = bonus_free_spins_times,
        bonus_win_chip = bonus_win_chip,
        bonus_bet_amount = amount
    }
    local content = save_data.last_bonus

    return content
end

BonusFinish = function(self)
    local task = self.parameters.task
    local player = self.parameters.player
    local game_room_config = self.parameters.game_room_config
    local parameter = json.decode(self.parameters.parameter)
    local player_game_info = self.parameters.player_game_info
    local game_type = self.parameters.game_type
    local session = self.parameters.session
    local player_game_status = self.parameters.player_game_status
    local amount = player_game_info.bet_amount
    local save_data = player_game_info.save_data
    local content = {
        free_spin_bouts = 0,
        bonus_win_chip = 0,
        bonus_bet_amount = amount
    }

    if not save_data.last_bonus then
        return content
    end

    player_game_info.bonus_game_type = 0

    if save_data.last_bonus.bonus_free_spins_times > 0 then
        GameStatusCal.Calculate.AddGameStatus(
            player_game_status,
            GameStatusDefine.AllTypes.FreeSpinGame,
            save_data.last_bonus.bonus_free_spins_times,
            1,
            amount
        )
        content.free_spin_bouts = save_data.last_bonus.bonus_free_spins_times
    end
    if save_data.last_bonus.bonus_win_chip > 0 then
        content.bonus_win_chip = save_data.last_bonus.bonus_win_chip
    end

    FeverQuestCal.OnMiniGameEnd(session, game_type, content.bonus_win_chip)

    save_data.last_bonus = nil

    return content
end
