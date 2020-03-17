require "Common/SlotsGameCalculate" --重写的接口
require "Common/SlotsGameCal" --旧的接口
require "Module/SlotsBaseSpin"

module("SlotsNewLegendsOfOlympusSpin", package.seeall)

local ZeusFunc = {
    ColHasZeus = function(self, type, result, col) -- 列是否有宙斯
        local row_max = #result
        for row = 1, row_max do
            if result[row][col] == type.Zeus_Normal or result[row][col] == type.Zeus_Angry then
                return true
            end
        end
        return false
    end,
    MaxValidCol = function(self, type, result, formation) -- 合法最大列
        local col_max = #formation
        for col = 1, col_max do
            if not self:ColHasZeus(type, result, col) then
                return col - 1
            end
        end
        return col_max
    end,
    CollectZeus = function(self, type, result, col, zeus_pos_list, angry_zeus_pos_list) -- 收集宙斯
        local row_max = #result
        for row = 1, row_max do
            if result[row][col] == type.Zeus_Normal or result[row][col] == type.Zeus_Angry then
                table.insert(zeus_pos_list, {col = col, row = row})
            end
            if result[row][col] == type.Zeus_Angry then
                table.insert(angry_zeus_pos_list, {col = col, row = row})
            end
        end
    end,
    ReplaceAngryZeus = function(self, type, result, angry_zeus) -- 替换愤怒的宙斯
        for _, grid in pairs(angry_zeus) do
            result[grid.row][grid.col] = type.Wild
        end
    end,
    MergeAngryZeus = function(self, angry_zeus, new_angry_zeus)
        for _, grid in pairs(new_angry_zeus) do
            table.insert(angry_zeus, grid)
        end
        return angry_zeus
    end
}

-- 每行挨着5个
local CheckZeusLightingFeature = function(result, player_game_info, save_data, game_room_config, is_free_spin)
    save_data.angry_zeus = is_free_spin and save_data.angry_zeus or {}

    local type = _G[game_room_config.game_name .. "TypeArray"].Types
    local formation = _G[game_room_config.game_name .. "FormationArray"].Formation1
    ZeusFunc:ReplaceAngryZeus(type, result, save_data.angry_zeus)

    -- 统计合法宙斯集合
    local zeus_pos_list = {}
    local angry_zeus_pos_list = {}
    for col = 1, ZeusFunc:MaxValidCol(type, result, formation) do
        ZeusFunc:CollectZeus(type, result, col, zeus_pos_list, angry_zeus_pos_list)
    end

    -- 判定触发新的free_spin, 愤怒的宙斯重置，次数累加
    local zeus_count = #zeus_pos_list >= 5 and #zeus_pos_list or 0
    save_data.angry_zeus =
        zeus_count >= 5 and ZeusFunc:MergeAngryZeus(save_data.angry_zeus, angry_zeus_pos_list) or save_data.angry_zeus
    local free_spin_num = zeus_count >= 5 and (zeus_count - 4) * 5 or 0
    if (is_free_spin) then
        player_game_info.free_spin_num = free_spin_num
    end

    return free_spin_num, #angry_zeus_pos_list, zeus_count >= 5 and 1 or 0, angry_zeus_pos_list, zeus_pos_list
end

-- 搜集特性
local CollectItems = function(
    player,
    pre_action_list,
    game_room_config,
    result_row,
    type,
    player_game_info,
    save_data,
    amount)
    local lines = _G[game_room_config.game_name .. "LineArray"].Lines1
    local bonus_config = CommonCal.Calculate.get_config(player, game_room_config.game_name .. "BonusBaseConfig")
    -- body
    local collect_pos_list = SlotsGameCal.Calculate.GetItemPosition(result_row, game_room_config, type.Thunder)
    if not (#collect_pos_list > 0) then
        return pre_action_list
    end

    local collect_times = save_data.collect_times or 0
    local collect_amount = save_data.collect_amount or 0

    collect_times = collect_times + #collect_pos_list
    collect_amount = collect_amount + #collect_pos_list * amount * 80 * bonus_config[1].Base_bonus

    if collect_times >= bonus_config[1].Collection_number then
        local pre_action = {}
        pre_action.action_type = ActionType.ActionTypes.EnterBonus
        pre_action.collect_amount = collect_amount
        table.insert(pre_action_list, pre_action)
        player_game_info.bonus_game_type = 1
    end

    save_data.collect_amount = collect_amount
    save_data.collect_times = collect_times

    local lines_num = 80
    local collect_base = amount * lines_num * bonus_config[1].Base_bonus

    local pre_action = {}
    pre_action.action_type = ActionType.ActionTypes.CollectItem
    pre_action.item_id = type.Collect
    pre_action.collect_pos_list = collect_pos_list
    pre_action.collect_percentage = collect_times / bonus_config[1].Collection_number
    pre_action.collect_base = collect_base
    pre_action.collect_amount = collect_amount
    table.insert(pre_action_list, pre_action)

    return pre_action_list
end

-- 处理旧版FreeSpin
local DealWithOldFreeSpinAction = function(
    pre_action_list,
    free_spin_bouts,
    is_free_spin,
    total_win_chip,
    save_data,
    player_game_status,
    zeus_pos_list,
    player_game_info)
    local is_trigger_free_spin = 0
    if (free_spin_bouts > 0) then
        if (not is_free_spin) then
            is_trigger_free_spin = 1
        else
            is_trigger_free_spin = 2
        end
    end
    save_data.total_free_spin_times = is_free_spin and (save_data.total_free_spin_times or 0) + 1 or 0

    local free_spin_bouts_left = GameStatusCal.Calculate.GetFreeSpinBouts(player_game_status)

    -- 触发增加freeSpin
    if is_free_spin and free_spin_bouts > 0 then
        table.insert(
            pre_action_list,
            {
                action_type = ActionType.ActionTypes.FreeSpinTimesAdd,
                free_spin_bouts = free_spin_bouts
            }
        )
    end

    -- 进入FreeSpin
    if is_trigger_free_spin > 0 then
        table.insert(
            pre_action_list,
            {
                action_type = ActionType.ActionTypes.NewLegendFreeSpin,
                is_trigger_free_spin = is_trigger_free_spin,
                free_spin_bouts = free_spin_bouts,
                pos_list = zeus_pos_list
            }
        )
    end

    -- 退出FreeSpin
    if is_free_spin and free_spin_bouts_left == 0 then
        local free_total_win =
            player_game_info.free_total_win + CommonCal.Calculate.GetFreeWin(is_free_spin, total_win_chip)

        table.insert(
            pre_action_list,
            {
                action_type = ActionType.ActionTypes.TotalFreeSpinWin,
                free_total_win = free_total_win,
                total_free_spin_times = save_data.total_free_spin_times
            }
        )
    end
end

Enter = function(self)
    local task = self.parameters.task
    local player = self.parameters.player
    local game_room_config = self.parameters.game_room_config
    local player_game_info = self.parameters.player_game_info

    local bonus_info = {}
    if (player_game_info.bonus_game_type > 0) then
        bonus_info.bonus_game = true
    end

    local save_data = player_game_info.save_data
    local bonus_config = CommonCal.Calculate.get_config(player, game_room_config.game_name .. "BonusBaseConfig")

    local collect_times = save_data.collect_times or 0
    local collect_amount = save_data.collect_amount or 0
    bonus_info.collect_percentage = collect_times / bonus_config[1].Collection_number
    bonus_info.collect_amount = collect_amount

    if save_data.angry_zeus ~= nil then
        bonus_info.positions = save_data.angry_zeus
    end

    local type = _G[game_room_config.game_name .. "TypeArray"].Types
    local super_stack_config =
        CommonCal.Calculate.get_config(player, game_room_config.game_name .. "SuperStackBaseConfig")
    if not save_data.super_stack_replace_item_id or save_data.super_stack_replace_item_id <= 0 then
        local super_stack_replace_item_id =
            SlotsGameCal.Calculate.SuperStackReplace(player, nil, game_room_config, type.SuperStack, super_stack_config)
        save_data.super_stack_replace_item_id = super_stack_replace_item_id
    end
    bonus_info.super_stack_replace_item_id = save_data.super_stack_replace_item_id

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
    local session = extern_param.session
    local lineNum = LineNum[game_type]()
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

    local origin_result, reel_file_name =
        SlotsGameCal.Calculate.GenItemResultWithWeight(
        player,
        game_type,
        is_free_spin,
        game_room_config,
        reel_file,
        weight_file
    )

    -- 替换superstack
    local super_stack_pos_list =
        SlotsGameCal.Calculate.GetItemPosition(origin_result, game_room_config, type.SuperStack)
    if #super_stack_pos_list > 0 then
        for k, v in ipairs(super_stack_pos_list) do
            origin_result[v.row][v.col] = save_data.super_stack_replace_item_id
        end
    end

    -- 宙斯
    local final_result = table.DeepCopy(origin_result)
    local free_spin_bouts, fir_lock_num, fir_angry, new_lock_pos, zeus_pos_list =
        CheckZeusLightingFeature(final_result, player_game_info, save_data, game_room_config, is_free_spin)

    -- 赔率
    local left_or_right = game_room_config.direction_type
    local payrate_file = CommonCal.Calculate.get_config(player, game_room_config.game_name .. "PayrateConfig")
    local other_file = CommonCal.Calculate.get_config(player, game_room_config.game_name .. "OthersConfig")
    local bet_ratio = other_file[1].Base_Bet_Ratio

    local prize_items, total_payrate =
        SlotsGameCal.Calculate.GenPrizeInfo(
        final_result,
        game_room_config,
        payrate_file,
        left_or_right,
        type,
        nil,
        nil,
        bet_ratio
    )
    -- 将连线结果放入all_prize_list
    local all_prize_list = {}
    table.insert(all_prize_list, prize_items)

    -- slots赢取的筹码 = 倍率和 * 筹码
    local slots_win_chip = total_payrate * amount
    local total_win_chip = slots_win_chip

    local pre_action_list = {}
    pre_action_list =
        CollectItems(player, pre_action_list, game_room_config, final_result, type, player_game_info, save_data, amount)

    -- FreeSpin判断处理
    if free_spin_bouts > 0 then
        GameStatusCal.Calculate.AddGameStatus(
            player_game_status,
            GameStatusDefine.AllTypes.FreeSpinGame,
            free_spin_bouts,
            1,
            amount
        )
    end

    -- 兼容旧的FreeSpin
    DealWithOldFreeSpinAction(
        pre_action_list,
        free_spin_bouts,
        is_free_spin,
        total_win_chip,
        save_data,
        player_game_status,
        zeus_pos_list,
        player_game_info
    )

    -- SuperStack替换
    local super_stack_config = {}
    if free_spin_bouts > 0 or is_free_spin then
        super_stack_config = CommonCal.Calculate.get_config(player, config_table.super_stack_feature_config)
    else
        super_stack_config = CommonCal.Calculate.get_config(player, config_table.super_stack_base_config)
    end
    save_data.super_stack_replace_item_id =
        SlotsGameCal.Calculate.SuperStackReplace(player, nil, game_room_config, type.SuperStack, super_stack_config)
    table.insert(
        pre_action_list,
        {
            action_type = ActionType.ActionTypes.SuperStackReplaceItemId,
            super_stack_replace_item_id = save_data.super_stack_replace_item_id or 0
        }
    )

    -- 客户端表现愤怒的宙斯
    if fir_angry == 1 then
        table.insert(
            pre_action_list,
            {
                action_type = ActionType.ActionTypes.NewLegendLock,
                fir_lock_num = fir_lock_num,
                fir_angry = fir_angry,
                free_spin_bouts = free_spin_bouts,
                parameter_list = {
                    [1] = {
                        positions = new_lock_pos
                    }
                }
            }
        )
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
            final_item_ids = json.encode(SlotsGameCal.Calculate.TransResultToCList(final_result, game_room_config))
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
    local task = self.parameters.task
    local player = self.parameters.player
    local game_room_config = self.parameters.game_room_config
    local parameter = json.decode(self.parameters.parameter)
    local player_game_info = self.parameters.player_game_info
    local bonus_config = CommonCal.Calculate.get_config(player, game_room_config.game_name .. "BonusBaseConfig")
    local bonus_number = bonus_config[1].Bonus_number
    local content = {}
    local save_data = player_game_info.save_data

    if
        (save_data.last_bonus ~= nil and save_data.last_bonus.collect_amount ~= nil and
            save_data.last_bonus.collect_amount ~= 0)
     then
        return save_data.last_bonus
    end

    local collect_amount = save_data.collect_amount or 0

    local bonus_config = CommonCal.Calculate.get_config(player, game_room_config.game_name .. "BonusConfig")
    local pick_count = 1
    for k, v in ipairs(bonus_config) do
        local bonus_result = math.rand_prob(player, v.Win_Prob)
        if not bonus_result then
            break
        end
        pick_count = v.Pick_Count
    end

    local random_spawn_tab = {}
    for i = 1, #bonus_config do
        table.insert(random_spawn_tab, bonus_config[i].Probability)
    end

    local bonus_pool = {}
    local max_bonus_multiple = 0
    for i = 1, bonus_number do
        local appear_index = math.rand_weight(player, random_spawn_tab)
        if bonus_config[appear_index].Bonus == -1 then
            table.remove(random_spawn_tab, appear_index)
        else
            max_bonus_multiple = max_bonus_multiple + bonus_config[appear_index].Bonus
        end
        table.insert(bonus_pool, bonus_config[appear_index].Bonus)
    end

    local picked_pool = {}
    for i = 1, pick_count do
        local index = math.random_ext(player, 1, #bonus_pool)

        local multiple = bonus_pool[index]

        table.insert(picked_pool, multiple)
        table.remove(bonus_pool, index)
        if multiple == -1 then
            break
        end
    end

    local bonus_multiple = 1
    for i = 1, #picked_pool do
        if picked_pool[i] == -1 then
            bonus_multiple = 1 + max_bonus_multiple
            break
        else
            bonus_multiple = bonus_multiple + picked_pool[i]
        end
    end
    save_data.bonus_win_chip = collect_amount * bonus_multiple

    content.collect_amount = collect_amount
    content.bonus_win_chip = save_data.bonus_win_chip
    content.pick_count = pick_count
    content.bonus_pool = bonus_pool
    content.picked_pool = picked_pool

    save_data.last_bonus = content
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

    local content = {}

    player_game_info.bonus_game_type = 0

    local save_data = player_game_info.save_data
    content.win_chip = save_data.bonus_win_chip

    save_data.collect_amount = 0
    save_data.collect_times = 0
    save_data.bonus_win_chip = 0

    FeverQuestCal.OnMiniGameEnd(session, game_type, content.win_chip)

    save_data.last_bonus = nil

    return content
end
