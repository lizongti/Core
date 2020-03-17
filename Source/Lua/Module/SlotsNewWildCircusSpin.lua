require "Common/SlotsGameCalculate"     --重写的接口
require "Common/SlotsGameCal"           --旧的接口
require "Common/LineNum"

SlotsNewWildCircusSpin = {}

local lines_num = 100

local function ReSetSpecialParameter(special_parameter)
    special_parameter.new_wild_circus = 1
    special_parameter.scatter_count_times = {}
    special_parameter.scatter_count_times[3] = 0
    special_parameter.scatter_count_times[4] = 0
    special_parameter.scatter_count_times[5] = 0
    special_parameter.base_jackpot_level_times = {}
    special_parameter.base_jackpot_level_times[1] = 0
    special_parameter.base_jackpot_level_times[2] = 0
    special_parameter.base_jackpot_level_times[3] = 0
    special_parameter.base_jackpot_win = 0
    special_parameter.feature_jackpot_level_times = {}
    special_parameter.feature_jackpot_level_times[1] = 0
    special_parameter.feature_jackpot_level_times[2] = 0
    special_parameter.feature_jackpot_level_times[3] = 0
    special_parameter.feature_jackpot_win = 0
    special_parameter.base_balloon_times = 0
    special_parameter.base_multiplier_times = {}
    special_parameter.base_multiplier_times[2] = 0
    special_parameter.base_multiplier_times[3] = 0
    special_parameter.base_multiplier_times[4] = 0
    special_parameter.base_multiplier_times[5] = 0
    special_parameter.base_multiplier_win = 0
    special_parameter.free_spin_multiplier_times = {}
    special_parameter.free_spin_multiplier_times[2] = 0
    special_parameter.free_spin_multiplier_times[3] = 0
    special_parameter.free_spin_multiplier_times[4] = 0
    special_parameter.free_spin_multiplier_times[5] = 0
    special_parameter.free_spin_multiplier_times[6] = 0
    special_parameter.free_spin_multiplier_times[8] = 0
    special_parameter.free_spin_multiplier_win = 0
    special_parameter.base_major_trigger_times = 0
    special_parameter.feature_major_trigger_times = 0
end

local function CollectJackpot(session, player, pre_action_list, game_room_config, result_row, type, player_game_info, amount, is_free_spin, special_parameter)
    -- body
    local collect_pos_list = SlotsGameCal.Calculate.GetItemPosition(result_row,game_room_config,type.Collect)
    local jackpot_level = 0
    local jackpot_win_chip = 0
    local jackpot_config = CommonCal.Calculate.get_config(player, game_room_config.game_name .. "JackpotConfig")

    for k,v in ipairs(jackpot_config) do
        if #collect_pos_list >= v.jackpot_collect_count then
            jackpot_level = v.jackpot_level
            jackpot_win_chip = amount * lines_num * v.jackpot_base_bonus
            break
        end
    end

    if #collect_pos_list > 0 then
        local pre_action = {}
        pre_action.action_type = ActionType.ActionTypes.CollectItem 
        pre_action.item_id = type.Collect
        pre_action.collect_pos_list = collect_pos_list
        pre_action.jackpot_level = jackpot_level
        pre_action.jackpot_win_chip = jackpot_win_chip
        table.insert(pre_action_list, pre_action)

        if jackpot_level == 3 then
            FeverQuestCal.OnWinMinorJackpot(session, jackpot_win_chip)
        end

        if is_free_spin then
            special_parameter.feature_jackpot_level_times[jackpot_level] = 1
        else
            special_parameter.base_jackpot_level_times[jackpot_level] = 1
        end
    end

    return jackpot_win_chip, pre_action_list
end

local function BalloonMultiplierFeature(player, is_free_spin, pre_action_list, game_room_config, slots_win_chip, prize_items, special_parameter)
    local multiplier_win_chip = 0

    if slots_win_chip <= 0 then return multiplier_win_chip, prize_items end
    
    -- body
    local multiplier_config = {}
    if is_free_spin then
        multiplier_config = CommonCal.Calculate.get_config(player, game_room_config.game_name .. "FeatureMultiplierConfig")
    else
        multiplier_config = CommonCal.Calculate.get_config(player, game_room_config.game_name .. "BaseMultiplierConfig")
    end
    
    --气球膨胀触发概率
    local balloon_trigger_prob = multiplier_config[1].balloon_trigger_prob
    local balloon_trigger_result = math.rand_prob(player, balloon_trigger_prob)
    --Multiplier触发概率
    local multiplier_trigger_prob = multiplier_config[1].multiplier_trigger_prob
    local multiplier_trigger_result = math.rand_prob(player, multiplier_trigger_prob)

    --测试用 BalloonMultiplierFeature
    if (GlobalSlotsTest[player.id] ~= nil) then
        if (GlobalSlotsTest[player.id].flag == 1) then
            balloon_trigger_result = true
            multiplier_trigger_result = true
        end
    end

    -- --freespin 必出BalloonMultiplierFeature
    -- if is_free_spin then
    --     balloon_trigger_result = true
    --     multiplier_trigger_result = true
    -- end

    if balloon_trigger_result and multiplier_trigger_result  then
        local random_bonus_tab = {}
        for i = 1, #multiplier_config do
            table.insert(random_bonus_tab, multiplier_config[i].probability)
        end
        local appear_index = math.rand_weight(player, random_bonus_tab)
        local bonus_multiple = multiplier_config[appear_index].bonus_multiple

        local pre_action = {}
        pre_action.action_type = ActionType.ActionTypes.MultiplierFeature
        pre_action.balloon_trigger_result = true
        pre_action.multiplier_trigger_result = true
        pre_action.slots_win_chip = slots_win_chip
        pre_action.bonus_multiple = bonus_multiple
        table.insert(pre_action_list, pre_action)

        
        if is_free_spin then
            special_parameter.free_spin_multiplier_times[bonus_multiple] = 1
        else
            special_parameter.base_balloon_times = 1
            special_parameter.base_multiplier_times[bonus_multiple] = 1
        end
        
        multiplier_win_chip = slots_win_chip * (bonus_multiple - 1)

        for i,v in ipairs(prize_items) do
            v.payrate = v.payrate * bonus_multiple
        end
    elseif balloon_trigger_result and slots_win_chip > 0 then
        local pre_action = {}
        pre_action.action_type = ActionType.ActionTypes.MultiplierFeature
        pre_action.balloon_trigger_result = true
        pre_action.multiplier_trigger_result = false
        table.insert(pre_action_list, pre_action)

        if not is_free_spin then
            special_parameter.base_balloon_times = 1
        end
    end

    return multiplier_win_chip, prize_items
end

local function RevealSymbol(player, result_row, pre_action_list, game_room_config, type, config_table)
    -- body
    local box_pos_list = SlotsGameCal.Calculate.GetItemPosition(result_row,game_room_config,type.Box)
    if #box_pos_list > 0 then
        --LOG(RUN, INFO).Format("[SlotsNewWildCircusSpin][RevealSymbol] RevealSymbol RevealSymbol RevealSymbol RevealSymbol RevealSymbol")
        local box_replace_config = CommonCal.Calculate.get_config(player, config_table.box_replace_config)

        local random_replace_tab = {}
        for i = 1, #box_replace_config do
            table.insert(random_replace_tab, box_replace_config[i].weight)
        end
        --LOG(RUN, INFO).Format("[SlotsNewWildCircusSpin][RevealSymbol] random_replace_tab is %s", Table2Str(random_replace_tab))
        local appear_index = math.rand_weight(player, random_replace_tab)
        local replace_item_id = box_replace_config[appear_index].item_id
        --LOG(RUN, INFO).Format("[SlotsNewWildCircusSpin][RevealSymbol] appear_index is %s replace_item_id is %s", appear_index, replace_item_id)
        while replace_item_id == type.Wild do
            local without_col_1 = true
            for k,v in ipairs(box_pos_list) do
                if v.col == 1 then
                    without_col_1 = false
                    appear_index = math.rand_weight(player, random_replace_tab)
                    replace_item_id = box_replace_config[appear_index].item_id
                    --LOG(RUN, INFO).Format("[SlotsNewWildCircusSpin][RevealSymbol] rerandom appear_index is %s replace_item_id is %s", appear_index, replace_item_id)
                    break
                end
            end
            if without_col_1 then
                break
            end
        end

        for k,v in ipairs(box_pos_list) do
            result_row[v.row][v.col] = replace_item_id
        end

        local pre_action = {}
        pre_action.action_type = 99 --等加 
        pre_action.replace_item_id = replace_item_id
        pre_action.box_pos_list = box_pos_list
        table.insert(pre_action_list, pre_action)
    end

    return result_row, pre_action_list
end

--入口
function SlotsNewWildCircusSpin:Enter()
    local bonus_info = {}
    
    return bonus_info
end

-----------------------------------------------
-- 点击Spin
-----------------------------------------------
function SlotsNewWildCircusSpin:NormalSpin()
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

    --模拟器特殊数据记录
    ReSetSpecialParameter(special_parameter)

    local session = extern_param.session

    local total_bet_amount = lines_num * amount
    local config_table = SlotsGameCal.Calculate.GetMapConfigTable(session, game_room_config, player_game_info, total_bet_amount)

    --对应GameConst里的TheSlotFatherTypeArray.Types
    local type = _G[game_room_config.game_name.."TypeArray"].Types
    player_game_info.bonus_game_type = 0 
    
    local reel_file = nil
    local weight_file = nil
    --Major必出判断
    local major_trigger_pro = 0
    if is_free_spin then     
        major_trigger_pro = config_table.feature_major_trigger_pro
    else
        major_trigger_pro = config_table.major_trigger_pro
    end

    local major_trigger_result = math.rand_prob(player, major_trigger_pro)
    if major_trigger_result then
        reel_file = config_table.base_reel_config
        weight_file = config_table.major_reel_weight_config
        if is_free_spin then 
            special_parameter.feature_major_trigger_times = 1
        else
            special_parameter.base_major_trigger_times = 1
        end
    else
        if is_free_spin then
            reel_file = config_table.feature_reel_config
            weight_file = config_table.feature_reel_weight_config
        else
            reel_file = config_table.base_reel_config
            weight_file = config_table.base_reel_weight_config
        end
    end
    --转动滚筒,获取结果
    --local origin_result, reel_file_name = SlotsGameCal.Calculate.GenItemResult(player, game_type, is_free_spin, game_room_config, reel_file)
    --转动滚筒,权重轴出结果
    local origin_result, reel_file_name = SlotsGameCal.Calculate.GenItemResultWithWeight(player, game_type, is_free_spin, game_room_config, reel_file, weight_file)
    --Major必出判断
    --origin_result = MajorTrigger(player, origin_result, game_room_config, type, is_free_spin, config_table)

    --行为记录
    local pre_action_list = {}
    local final_result = table.DeepCopy(origin_result)

    --特殊逻辑
    final_result, pre_action_list = RevealSymbol(player, final_result, pre_action_list, game_room_config, type, config_table)

    --赔率配置
    local payrate_file = CommonCal.Calculate.get_config(player, game_room_config.game_name.."PayrateConfig")
    --连线规则, 1左连线，2右, 3左右连线
    local left_or_right = game_room_config.direction_type

    --local others_config = CommonCal.Calculate.get_config(player, game_room_config.game_name .. "OthersConfig")
    local bet_ratio = 1
    -- if others_config then
    --         bet_ratio = others_config[1].Base_Bet_Ratio or 1
    -- end

    --获得连线结果
    local prize_items, total_payrate = SlotsGameCal.Calculate.GenPrizeInfo(final_result, game_room_config, payrate_file, left_or_right, type, nil, nil, bet_ratio)
    --将连线结果放入all_prize_list
    local all_prize_list = {}
    table.insert(all_prize_list,prize_items)

    --slots赢取的筹码 = 倍率和 * 筹码
    local slots_win_chip = total_payrate * amount

    --Balloon Multiplier Feature给的筹码
    local multiplier_win_chip = 0
    multiplier_win_chip, prize_items = BalloonMultiplierFeature(player, is_free_spin, pre_action_list, game_room_config, slots_win_chip, prize_items, special_parameter)

    --Jackpot给的筹码
    local jackpot_win_chip = 0
    jackpot_win_chip, pre_action_list = CollectJackpot(session, player, pre_action_list, game_room_config, final_result, type, player_game_info, amount, is_free_spin, special_parameter)

    if is_free_spin then
        special_parameter.feature_jackpot_win = jackpot_win_chip
        special_parameter.free_spin_multiplier_win = multiplier_win_chip
    else
        special_parameter.base_jackpot_win = jackpot_win_chip
        special_parameter.base_multiplier_win = multiplier_win_chip
    end

    --赢取的总筹码,slots筹码+游戏等特殊筹码
    local total_win_chip = slots_win_chip + multiplier_win_chip + jackpot_win_chip
    
    --FreeSpin判断处理
    local free_spin_bouts =  SlotsGameCal.Calculate.FreeSpinCheck(player, final_result, game_room_config, is_free_spin, type.Scatter)
    if free_spin_bouts > 0 then
        GameStatusCal.Calculate.AddGameStatus(player_game_status, GameStatusDefine.AllTypes.FreeSpinGame, free_spin_bouts, 1, amount)
        local scatter_count = #SlotsGameCal.Calculate.GetItemPosition(final_result, game_room_config, type.Scatter)
        if scatter_count >= 3 then
            special_parameter.scatter_count_times[scatter_count] = 1
        end
    end
    
    if free_spin_bouts > 0 then
        local pre_action = {}
        pre_action.action_type = 847860152 --等加 
        pre_action.count = free_spin_bouts
        pre_action.is_extra = is_free_spin
        pre_action.total = player_game_info.free_spin_bouts + free_spin_bouts
        table.insert(pre_action_list, pre_action)
    end

    if is_free_spin then
        player_game_info.free_spin_num = free_spin_bouts
    end

    local save_data = player_game_info.save_data
    if save_data.total_free_spin_count == nil then
        save_data.total_free_spin_count = 0
    end

    --最后一次数据记录
    local slots_spin_list = {}
    table.insert(slots_spin_list, {
        item_ids = json.encode(SlotsGameCal.Calculate.TransResultToCList(origin_result, game_room_config)),
        prize_items = prize_items,
        win_chip = total_win_chip,
        pre_action_list = json.encode(pre_action_list),
        final_item_ids = json.encode(SlotsGameCal.Calculate.TransResultToCList(final_result, game_room_config)),     
    })
    --客户端接收的表
    local formation_list={}
    table.insert(formation_list, {
        slots_spin_list=slots_spin_list,
        id = 1,
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




