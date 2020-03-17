require "Common/SlotsGameCalculate" --重写的接口
require "Common/SlotsGameCal" --旧的接口
require "Common/LineNum"

SlotsNewLeprechaunTreasureSpin = {}

local lines_num = 80
local bet_transform_rate = 0.01
local collect_complete_times = 100
local bonus_number = 8

local bool
is_init_bonus = false

local special_parameter = {
    new_leprechaun_treasure = 1,
    expanding_time = {},
    expanding_col_times = {},
    multiplier_time = 0,
    freespin_round = 0,
    freespin_spin_win = {}
}

local function ReSetSpecialParameter()
    special_parameter.expanding_time[1] = 0
    special_parameter.expanding_time[2] = 0
    special_parameter.expanding_time[3] = 0
    special_parameter.expanding_time[4] = 0
    special_parameter.expanding_col_times[2] = 0
    special_parameter.expanding_col_times[3] = 0
    special_parameter.expanding_col_times[4] = 0
    special_parameter.expanding_col_times[5] = 0
    special_parameter.multiplier_time = 0
    for i = 1, 8 do
        special_parameter.freespin_spin_win[i] = 0
    end
end

local function CollectItems(player, pre_action_list, game_room_config, result_row, type, player_game_info, amount)
    -- body
    local collect_pos_list = SlotsGameCal.Calculate.GetItemPosition(result_row, game_room_config, type.Collect)
    if not (#collect_pos_list > 0) then
        return result_row, pre_action_list
    end
    local save_data = player_game_info.save_data
    local collect_times = save_data.collect_times or 0
    local collect_amount = save_data.collect_amount or 0
    local collect_base = amount * lines_num * bet_transform_rate

    collect_times = collect_times + #collect_pos_list
    collect_amount = collect_amount + #collect_pos_list * collect_base
    if collect_times >= collect_complete_times then
        local pre_action = {}
        pre_action.action_type = ActionType.ActionTypes.EnterBonus
        table.insert(pre_action_list, pre_action)
        player_game_info.bonus_game_type = 1
    end

    save_data.collect_amount = collect_amount
    save_data.collect_times = collect_times

    local pre_action = {}
    pre_action.action_type = ActionType.ActionTypes.CollectItem
    pre_action.item_id = type.Collect
    pre_action.collect_pos_list = collect_pos_list
    pre_action.collect_percentage = collect_times / collect_complete_times
    pre_action.collect_base = collect_base
    pre_action.collect_amount = collect_amount
    table.insert(pre_action_list, pre_action)

    return result_row, pre_action_list
end

local function ExpandingWild(player, pre_action_list, game_room_config, result_row, type, player_game_info)
    -- body
    local origin_result = table.DeepCopy(result_row)
    local wild_pos_list = SlotsGameCal.Calculate.GetItemPosition(result_row, game_room_config, type.Wild)
    --LOG(RUN, INFO).Format("[NewLeprechaunTreasure][ExpandingWild] wild_pos_list[%s]",Table2Str(wild_pos_list))
    if not (#wild_pos_list > 0) then
        return result_row, pre_action_list
    end
    for k, v in ipairs(wild_pos_list) do
        for i = 1, #result_row do
            result_row[i][v.col] = type.BigWild
        end
    end

    local payrate_file = CommonCal.Calculate.get_config(player, game_room_config.game_name .. "PayrateConfig")
    local left_or_right = game_room_config.direction_type
    -- local prize_items, total_payrate = SlotsGameCal.Calculate.GenPrizeInfo(result_row, game_room_config, payrate_file, left_or_right, type)

    local wilds_on_line =
        SlotsGameCal.Calculate.GetWildsOnLine(result_row, game_room_config, payrate_file, left_or_right, type)
    --LOG(RUN, INFO).Format("[NewLeprechaunTreasure][ExpandingWild] wilds_on_line[%s]",Table2Str(wilds_on_line))
    if not (#wilds_on_line > 0) then
        -- result_row = origin_result
        return origin_result, pre_action_list
    end
    local cols = {}
    for k, v in ipairs(wilds_on_line) do
        for rowIndex = 1, #origin_result do
            local row = origin_result[rowIndex]
            row[v.col] = type.BigWild
            cols[v.col] = true
        end
    end
    local expanding_wild_pos_list = {}
    for k, v in ipairs(wild_pos_list) do
        if cols[v.col] == true then
            table.insert(expanding_wild_pos_list, v)
        end
    end
    local pre_action = {}
    pre_action.action_type = ActionType.ActionTypes.ExpandingWild
    pre_action.item_id = type.BigWild
    pre_action.expanding_wild_pos_list = expanding_wild_pos_list
    table.insert(pre_action_list, pre_action)

    return origin_result, pre_action_list
end

local function MultiplierFeature(player, pre_action_list, game_room_config, slots_win_chip, prize_items, config_table)
    -- body
    local multiplier_config = CommonCal.Calculate.get_config(player, config_table.multiplier_config)
    local multiplier_trigger_prob = multiplier_config[1].Multiplier_trigger_prob
    local multiplier_trigger_result = math.rand_prob(player, multiplier_trigger_prob)

    --测试用 必出MultiplierFeature
    if (GlobalSlotsTest[player.id] ~= nil) then
        if (GlobalSlotsTest[player.id].flag == 1) then
            multiplier_trigger_result = true
        end
    end
    local multiplier_win_chip = 0

    if multiplier_trigger_result and slots_win_chip > 0 then
        local random_bonus_tab = {}
        for i = 1, #multiplier_config do
            table.insert(random_bonus_tab, multiplier_config[i].probability)
        end
        local appear_index = math.rand_weight(player, random_bonus_tab)
        local bonus = multiplier_config[appear_index].bonus

        local pre_action = {}
        pre_action.action_type = ActionType.ActionTypes.MultiplierFeature
        pre_action.slots_win_chip = slots_win_chip
        pre_action.bonus = bonus
        table.insert(pre_action_list, pre_action)
        special_parameter.multiplier_time = 1
        multiplier_win_chip = slots_win_chip * (bonus - 1)

        for i, v in ipairs(prize_items) do
            v.payrate = v.payrate * bonus
        end
    end
    return multiplier_win_chip, pre_action_list, prize_items
end

local function FreeSpinFeature(
    player,
    is_free_spin,
    pre_action_list,
    game_room_config,
    result_row,
    type,
    player_game_info,
    config_table)
    -- body
    local save_data = player_game_info.save_data
    if not is_free_spin then
        if not save_data.new_round then
            save_data.new_round = true
            if save_data.money_box then
                local count = 0
                for i = 1, #save_data.money_box do
                    -- body
                    if save_data.money_box[i + 1] == 4 then
                        count = count + 1
                        special_parameter.expanding_col_times[i + 1] = 1
                    end
                end
                special_parameter.expanding_time[count] = 1
            end
            save_data.money_box = {}
            save_data.money_box[2] = 0
            save_data.money_box[3] = 0
            save_data.money_box[4] = 0
            save_data.money_box[5] = 0
        end
        return result_row, pre_action_list
    end
    local money_box = save_data.money_box or {}
    for j = 2, 5 do
        if money_box[j] and money_box[j] >= 4 then
            for i = 1, #result_row do
                result_row[i][j] = type.BigWild
            end
        end
    end
    local money_box_pos_list = SlotsGameCal.Calculate.GetItemPosition(result_row, game_room_config, type.MoneyBox)

    if (#money_box_pos_list > 0) then
        local throw_config = CommonCal.Calculate.get_config(player, config_table.throw_config)

        local money_box_collect = {}
        for k, v in ipairs(money_box_pos_list) do
            local throw_count = math.rand_weight(player, throw_config[v.col].throw_probability)
            if not money_box[v.col] then
                money_box[v.col] = throw_count
            elseif money_box[v.col] + throw_count > 4 then
                throw_count = 4 - money_box[v.col]
                money_box[v.col] = 4
            else
                money_box[v.col] = money_box[v.col] + throw_count
            end

            if money_box[v.col] == 4 then
                for i = 1, #result_row do
                    result_row[i][v.col] = type.BigWild
                end
            end
            local money_box_collect_info = {}
            money_box_collect_info.col = v.col
            money_box_collect_info.throw_count = throw_count
            money_box_collect_info.collected = money_box[v.col]
            money_box_collect_info.pos = v
            table.insert(money_box_collect, money_box_collect_info)
        end

        local pre_action = {}
        pre_action.action_type = ActionType.ActionTypes.CollectThrowCoin
        pre_action.item_id = type.BigWild
        pre_action.money_box_collect = money_box_collect
        table.insert(pre_action_list, pre_action)

        save_data.money_box = money_box
    end

    save_data.new_round = false
    return result_row, pre_action_list
end

local function InitBonusInfo(player, game_room_config, player_game_info)
    if (not is_init_bonus) then
        is_init_bonus = true
        local bonus_base_config =
            CommonCal.Calculate.get_config(player, game_room_config.game_name .. "BonusBaseConfig")
        bet_transform_rate = bonus_base_config[1].Base_bonus or 0.01
        collect_complete_times = bonus_base_config[1].Collection_number or 100
        bonus_number = bonus_base_config[1].Bonus_number or 8
        lines_num = LineNum[player_game_info.game_type]() or 80
    end
end

--入口
function SlotsNewLeprechaunTreasureSpin:Enter()
    local task = self.parameters.task
    local player = self.parameters.player
    local game_room_config = self.parameters.game_room_config
    local player_game_info = self.parameters.player_game_info
    local player_game_status = self.parameters.player_game_status

    InitBonusInfo(player, game_room_config, player_game_info)
    local bonus_info = {}
    if (player_game_info.bonus_game_type > 0) then
        bonus_info.bonus_game = true
    end
    local save_data = player_game_info.save_data
    local collect_times = save_data.collect_times or 0
    local collect_amount = save_data.collect_amount or 0
    local free_spin_money_can = save_data.money_box or {}
    bonus_info.collect_percentage = collect_times / collect_complete_times
    bonus_info.collect_amount = collect_amount
    bonus_info.free_spin_money_can = free_spin_money_can

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

-----------------------------------------------
-- 点击Spin
-----------------------------------------------
function SlotsNewLeprechaunTreasureSpin:NormalSpin()
    local player = self.parameters.player
    local game_type = self.parameters.game_type
    local amount = self.parameters.amount
    local is_free_spin = self.parameters.is_free_spin
    local game_room_config = self.parameters.game_room_config
    local player_game_info = self.parameters.player_game_info
    local player_game_status = self.parameters.player_game_status
    local player_feature_condition = self.parameters.player_feature_condition
    local extern_param = self.parameters.extern_param

    ReSetSpecialParameter()
    local session = extern_param.session
    local lineNum = LineNum[game_type]()
    local config_table =
        SlotsGameCal.Calculate.GetMapConfigTable(session, game_room_config, player_game_info, amount * lineNum)

    --对应GameConst里的TheSlotFatherTypeArray.Types
    local type = _G[game_room_config.game_name .. "TypeArray"].Types
    player_game_info.bonus_game_type = 0
    --转动滚筒,获取结果
    local reel_file = nil
    local weight_file = nil
    if is_free_spin then
        reel_file = config_table.feature_reel_config
        weight_file = config_table.feature_reel_weight_config
    else
        reel_file = config_table.base_reel_config
        weight_file = config_table.base_reel_weight_config
    end

    --转动滚筒,权重轴出结果
    local origin_result, reel_file_name =
        SlotsGameCal.Calculate.GenItemResultWithWeight(
        player,
        game_type,
        is_free_spin,
        game_room_config,
        reel_file,
        weight_file
    )

    local super_stack_pos_list =
        SlotsGameCal.Calculate.GetItemPosition(origin_result, game_room_config, type.SuperStack)

    if #super_stack_pos_list > 0 then
        local save_data = player_game_info.save_data
        for k, v in ipairs(super_stack_pos_list) do
            origin_result[v.row][v.col] = save_data.super_stack_replace_item_id
        end
    end
    --行为记录
    local pre_action_list = {}
    local final_result = table.DeepCopy(origin_result)

    --特殊逻辑
    if not is_free_spin then
        final_result, pre_action_list =
            CollectItems(player, pre_action_list, game_room_config, final_result, type, player_game_info, amount)
        final_result, pre_action_list =
            ExpandingWild(player, pre_action_list, game_room_config, final_result, type, player_game_info)
    end

    final_result, pre_action_list =
        FreeSpinFeature(
        player,
        is_free_spin,
        pre_action_list,
        game_room_config,
        final_result,
        type,
        player_game_info,
        config_table
    )

    --赔率配置
    local payrate_file = CommonCal.Calculate.get_config(player, game_room_config.game_name .. "PayrateConfig")
    --连线规则, 1左连线，2右, 3左右连线
    local left_or_right = game_room_config.direction_type

    local others_config = CommonCal.Calculate.get_config(player, game_room_config.game_name .. "OthersConfig")
    local bet_ratio = 1
    if others_config then
        bet_ratio = others_config[1].Base_Bet_Ratio or 1
    end

    --获得连线结果
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
    --将连线结果放入all_prize_list
    local all_prize_list = {}
    table.insert(all_prize_list, prize_items)

    --slots赢取的筹码 = 倍率和 * 筹码
    local slots_win_chip = total_payrate * amount
    local multiplier_win_chip = 0
    if not is_free_spin then
        multiplier_win_chip, pre_action_list, prize_items =
            MultiplierFeature(player, pre_action_list, game_room_config, slots_win_chip, prize_items, config_table)
    end
    --赢取的总筹码,slots筹码+游戏等特殊筹码
    local total_win_chip = slots_win_chip + multiplier_win_chip
    if is_free_spin then
        special_parameter.freespin_round = special_parameter.freespin_round + 1
        local total_bet = amount * lines_num
        special_parameter.freespin_spin_win[special_parameter.freespin_round] = total_win_chip / total_bet
    else
        special_parameter.freespin_round = 0
    end

    --FreeSpin判断处理
    local free_spin_bouts = SlotsGameCal.Calculate.GenFreeSpinCount(origin_result, game_room_config, type.Scatter, 7)
    if free_spin_bouts > 0 then
        GameStatusCal.Calculate.AddGameStatus(
            player_game_status,
            GameStatusDefine.AllTypes.FreeSpinGame,
            free_spin_bouts,
            1,
            amount
        )
    end
    --SuperStack替换
    local super_stack_config = {}

    if free_spin_bouts > 0 or is_free_spin then
        super_stack_config = CommonCal.Calculate.get_config(player, config_table.super_stack_feature_config)
    else
        super_stack_config = CommonCal.Calculate.get_config(player, config_table.super_stack_base_config)
    end

    local save_data = player_game_info.save_data
    save_data.super_stack_replace_item_id =
        SlotsGameCal.Calculate.SuperStackReplace(player, nil, game_room_config, type.SuperStack, super_stack_config)

    local pre_action = {}
    pre_action.action_type = ActionType.ActionTypes.SuperStackReplaceItemId
    pre_action.super_stack_replace_item_id = save_data.super_stack_replace_item_id or 0
    table.insert(pre_action_list, pre_action)

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
            final_item_ids = json.encode(
                SlotsGameCal.Calculate.TransResultToCList(
                    SlotsGameCal.Calculate.ReplaceBlock(final_result, type.BigWild),
                    game_room_config
                )
            )
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

    local result = {}
    result.final_result = final_result --结果数组
    result.total_win_chip = total_win_chip --总奖金
    result.all_prize_list = all_prize_list --所有连线列表
    result.free_spin_bouts = free_spin_bouts --freespin的次数
    result.formation_list = formation_list --阵型列表
    result.reel_file_name = reel_file_name --reel表名
    result.slots_win_chip = slots_win_chip --总奖励
    result.special_parameter = special_parameter --其他参数，主要给模拟器传参

    return result
end

-----------------------------------------------
-- Bonus Game
-----------------------------------------------
function SlotsNewLeprechaunTreasureSpin:NewLeprechaunTreasureBonusStart()
    local player_game_status = self.parameters.player_game_status
    local player = self.parameters.player
    local game_room_config = self.parameters.game_room_config
    local parameter = json.decode(self.parameters.parameter)
    local player_game_info = self.parameters.player_game_info
    local game_type = self.parameters.game_type
    local session = self.parameters.session

    local content = {}

    local lineNum = LineNum[player_game_info.game_type]()

    local config_table =
        SlotsGameCal.Calculate.GetMapConfigTable(
        session,
        game_room_config,
        player_game_info,
        player_game_info.bet_amount * lineNum
    )

    local save_data = player_game_info.save_data
    local collect_amount = save_data.collect_amount or 0

    local bonus_config = CommonCal.Calculate.get_config(player, config_table.bonus_config)
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
    save_data.max_bonus_multiple = max_bonus_multiple

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
    return content
end

function SlotsNewLeprechaunTreasureSpin:NewLeprechaunTreasureBonusFinish()
    local player_game_status = self.parameters.player_game_status
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
    save_data.max_bonus_multiple = 0
    save_data.bonus_win_chip = 0

    FeverQuestCal.OnMiniGameEnd(session, game_type, content.win_chip)

    return content
end
