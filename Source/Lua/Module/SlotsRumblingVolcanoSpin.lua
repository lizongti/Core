require"Common/SlotsGameCalculate" 
require"Common/SlotsGameCal" 
require"Common/LineNum"

SlotsRumblingVolcanoSpin = {}

local Types = _G["RumblingVolcanoTypeArray"].Types

-- 入口
function SlotsRumblingVolcanoSpin:Enter()
    local task = self.parameters.task
    local player = self.parameters.player
    local game_room_config = self.parameters.game_room_config
    local player_game_info = self.parameters.player_game_info
    local session = self.parameters.session
    local player_game_status = self.parameters.player_game_status

    local bonus_info = {}
    local save_data = player_game_info.save_data

    -- 初始化superstack元素
    local super_stack_config = CommonCal.Calculate.get_config(player, game_room_config.game_name.."SuperStackBaseConfig")
    if not save_data.super_stack_replace_item_id or save_data.super_stack_replace_item_id <= 0 then
        local super_stack_replace_item_id = SlotsGameCal.Calculate.SuperStackReplace(player, nil, game_room_config, Types.SuperStack, super_stack_config)
        save_data.super_stack_replace_item_id = super_stack_replace_item_id
    end
    bonus_info.super_stack_replace_item_id = save_data.super_stack_replace_item_id

    return bonus_info
end

IsBonusGame = function(game_room_config, player, player_game_info)
    return false
end

local function RandMulti(player, game_type, is_free_spin, game_room_config, config_table)
    local multi_config = CommonCal.Calculate.get_config(player, config_table.multiplier_config)
    local v = {}
    for i=1, 4 do
        table.insert(v, is_free_spin and multi_config[i].feature_game_weight or multi_config[i].base_game_weight)
    end
    local index = math.rand_weight(player, v)
    return multi_config[index].bonus
end

local function RandSproutWild(player, wild_count)
    local type_config = CommonCal.Calculate.get_config(player, "RumblingVolcanoRandomWildTypeConfig")
    local weight = nil
    for i=1, #type_config do
        if type_config[i].wild_count == wild_count then
            weight = type_config[i].type_weight_
        end
    end

    local sprout_type = math.rand_weight(player, weight)

    if sprout_type == 1 or sprout_type == 2 then
        local typeab_config = CommonCal.Calculate.get_config(player, "RumblingVolcanoRandomWildCountTypeABConfig")
        local weight = typeab_config[wild_count].random_weight
        local sprout_count = math.rand_weight(player, weight)
        local sprout_info = {
            type = sprout_type,
            total_count = sprout_count,
            counts = {sprout_count}
        }
        return sprout_info
    else
        local typec_config = CommonCal.Calculate.get_config(player, "RumblingVolcanoRandomWildCountTypeCConfig")
        
        local weights = {}
        local start = nil
        for i=1, #typec_config do
            if wild_count == typec_config[i].wild_count then
                if not start then start = i end
                table.insert(weights, typec_config[i].weight)
            end
        end
        local index = math.rand_weight(player, weights) + start - 1
        local sprout_info = {
            type = sprout_type,
            total_count = typec_config[index].wild_array[1]+typec_config[index].wild_array[2],
            counts = {typec_config[index].wild_array[1], typec_config[index].wild_array[2]}
        }

        return sprout_info
    end
end

-- 计算最终的数据
local function RandSproutResult(player, wild_count, sprout_info, origin_result)
    sprout_info.origin_result = origin_result
    sprout_info.final_result = table.DeepCopy(origin_result)
    local weights = {}
    for i=1, wild_count do
        table.insert(weights, 1)
    end
    local indexes = math.rand_weights(player, weights, sprout_info.total_count)
    table.sort(indexes, function(a, b)
        return a < b
    end)
    local index = 1
    local k = 1
    local pos = {}
    for i=1, #origin_result do
        for j=1, #origin_result[i] do
            if origin_result[i][j] == Types.Wild or origin_result[i][j] == Types.ScatterWild then
                if indexes[k] == index then
                    if origin_result[i][j] == Types.ScatterWild then
                        origin_result[i][j] = Types.Scatter
                    else
                        origin_result[i][j] = math.random_ext(player, 5, 13)
                    end
                    k = k + 1
                    if sprout_info.type == 1 then
                        table.insert(pos, {row=i, col=j, type=1})
                    elseif sprout_info.type == 2 then
                        table.insert(pos, {row=i, col=j, type=2})
                    else
                        if index <= sprout_info.counts[1] then
                            table.insert(pos, {row=i, col=j, type=1})
                        else
                            table.insert(pos, {row=i, col=j, type=2})
                        end
                    end
                end
                index = index + 1
            end
        end
    end

    sprout_info.wild_pos = pos
end

local function RandIsMulti(session, game_type, is_free_spin, game_room_config, special_parameter, player_game_info, amount)
    local player = session.player
    local id = is_free_spin and 2 or 1
    -- 首先通过wild判断是否触发
    local is_multi
    local result = {}

    local lineNum = LineNum[game_type]()

    local config_table = SlotsGameCal.Calculate.GetMapConfigTable(session, game_room_config, player_game_info, amount * lineNum)
    local other_config = CommonCal.Calculate.get_config(player, config_table.other_config)
    if math.rand_prob(player, other_config[id].rock_fire_probablity) then
        local origin_result, reel_file_name = SlotsGameCal.Calculate.GenItemResultWithWeight(player, game_type, is_free_spin, 
            game_room_config, "RumblingVolcanoFireReelConfig", config_table.fire_reel_weight_config)
        
        local wilds = SlotsGameCal.Calculate.GetItemPosition(origin_result, game_room_config, Types.Wild)
        local scatter_wilds = SlotsGameCal.Calculate.GetItemPosition(origin_result, game_room_config, Types.ScatterWild)

        special_parameter.less_scatter = true
        is_multi = math.rand_prob(player, other_config[id].rock_fire_multi_pro)

        if #wilds + #scatter_wilds >= other_config[id].wild_count_require then
            local wild_count = #wilds + #scatter_wilds
            local sprout_info = RandSproutWild(player, wild_count)
            RandSproutResult(player, wild_count, sprout_info, origin_result)
            result.origin_result = sprout_info.origin_result
            result.final_result = sprout_info.final_result
            return is_multi, sprout_info, result
        end

        result.origin_result = origin_result

        for i=1, #origin_result do
            for j=1, #origin_result[i] do
                if origin_result[i][j] == Types.ScatterWild then
                    origin_result[i][j] = Types.Scatter
                end
            end
        end

        result.final_result = table.DeepCopy(origin_result)
    else
        is_multi = math.rand_prob(player, other_config[id].base_multiplier_probablity)
    end

    return is_multi, nil, result
end

function SlotsRumblingVolcanoSpin:NormalSpin()
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
    local save_data = player_game_info.save_data

    local session = self.parameters.extern_param.session

    local lineNum = LineNum[player_game_info.game_type]()
    local total_amount = lineNum * amount
    local type = _G[game_room_config.game_name .. "TypeArray"].Types

    local config_table = SlotsGameCal.Calculate.GetMapConfigTable(session, game_room_config, player_game_info, amount * lineNum)
    local reel_file = nil
    local weight_file = nil

    -- 随机other表，是否触发倍乘
    local is_multi, sprout_info, result = RandIsMulti(session, game_type, is_free_spin, game_room_config, special_parameter, player_game_info, amount)
    local special_multi = 1

    if is_multi then
        special_multi = RandMulti(player, game_type, is_free_spin, game_room_config, config_table)
        special_parameter.special_multi = special_multi
        special_parameter.sprout_info = sprout_info
    end

    if is_free_spin then
        reel_file = config_table.feature_reel_config
        weight_file = config_table.feature_reel_weight_config
    else
        reel_file = config_table.base_reel_config
        weight_file = config_table.base_reel_weight_config
    end

    local origin_result, reel_file_name = SlotsGameCal.Calculate.GenItemResultWithWeight(player, game_type, is_free_spin, 
        game_room_config, reel_file, weight_file)

    local pre_action_list = {}
    local final_result = table.DeepCopy(origin_result)

    -- 如果有火山，则替换
    if sprout_info then
        origin_result = sprout_info.origin_result
        final_result = sprout_info.final_result

        -- 添加action
        table.insert(pre_action_list, {
            action_type = ActionType.ActionTypes.VolcanoSproutInfo,
            sprout_info = {
                type = sprout_info.type,
                counts = sprout_info.counts,
		        wild_pos = sprout_info.wild_pos
            }
        })
    elseif result.origin_result then
        origin_result = result.origin_result
        final_result = result.final_result
    end

    -- super stack
    -- 如果是freespin，进行替换
    local super_stack_pos_list = SlotsGameCal.Calculate.GetItemPosition(origin_result, game_room_config, Types.SuperStack)

	if #super_stack_pos_list > 0 then
        for k,v in ipairs(super_stack_pos_list) do
            origin_result[v.row][v.col] = save_data.super_stack_replace_item_id
            final_result[v.row][v.col] = save_data.super_stack_replace_item_id
        end
    end

    local payrate_file = CommonCal.Calculate.get_config(player, game_room_config.game_name .. "PayrateConfig")
    local left_or_right = game_room_config.direction_type

    local other_config = CommonCal.Calculate.get_config(player, config_table.other_config)
    local bet_ratio = other_config[is_free_spin and 2 or 1].bet_ratio
    local prize_items, total_payrate = SlotsGameCal.Calculate.GenPrizeInfo(final_result, game_room_config, payrate_file, 
        left_or_right, type, nil, nil, bet_ratio)

    local all_prize_list = {}
    table.insert(all_prize_list, prize_items)

    local slots_win_chip = total_payrate * amount * special_multi

    if is_multi and slots_win_chip > 0 then
        -- 添加action
        table.insert(pre_action_list, {
            action_type = ActionType.ActionTypes.MultiplierFeature,
            multi = special_multi
        })
    end

    local total_win_chip = slots_win_chip

    local free_spin_bouts = SlotsGameCal.Calculate.FreeSpinCheck(player, origin_result, game_room_config, is_free_spin, type.Scatter)

    local slots_spin_list = {}

    if free_spin_bouts > 0 then
        GameStatusCal.Calculate.AddGameStatus(player_game_status, GameStatusDefine.AllTypes.FreeSpinGame, free_spin_bouts, 1, amount)
    end

    if is_free_spin and free_spin_bouts > 0 then
        table.insert(pre_action_list, {
                action_type = ActionType.ActionTypes.FreeSpinTimesAdd,
                free_spin_bouts = free_spin_bouts
            }
        )
    end

    -- 随机下一次的super stack
    local super_stack_config = CommonCal.Calculate.get_config(player, game_room_config.game_name.."SuperStackBaseConfig")

    if is_free_spin then
        super_stack_config = CommonCal.Calculate.get_config(player, game_room_config.game_name.."SuperStackFeatureConfig")
    end

    save_data.super_stack_replace_item_id = SlotsGameCal.Calculate.SuperStackReplace(player, nil, game_room_config, Types.SuperStack, super_stack_config)
    local action_super_stack = {
        action_type = ActionType.ActionTypes.SuperStackReplaceItemId,
        super_stack_replace_item_id = save_data.super_stack_replace_item_id or 0
    }
    table.insert(pre_action_list, action_super_stack)

    table.insert(slots_spin_list, {
        item_ids = json.encode(SlotsGameCal.Calculate.TransResultToCList(origin_result, game_room_config)),
        prize_items = prize_items,
        win_chip = total_win_chip,
        pre_action_list = json.encode(pre_action_list),
        final_item_ids = json.encode(SlotsGameCal.Calculate.TransResultToCList(final_result, game_room_config)),
        slots_win_chip = slots_win_chip
    })

    local formation_list = {}
    table.insert(formation_list, {
        slots_spin_list = slots_spin_list,
        id = 1
    })

    special_parameter.total_win_chip = total_win_chip

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
