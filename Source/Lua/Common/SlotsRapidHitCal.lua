module("SlotsRapidHitCal", package.seeall)
require "Util/TableExt"
require "Common/CommonCal"

------获得某种item列表此次转动结果出现的位置
GetItemsCount = function(data, game_room_config, item_ids, formation_id)
    local count_list = {}
    formation_id = formation_id or 'Formation1'
    local formation = _G[game_room_config.game_name .. "FormationArray"][formation_id]

    local total_count = 0
    for j = 1, #formation do
        for i = 1, formation[j] do
            for k, item_id in pairs(item_ids) do
                if data[i][j] == item_id then
                    local item_count_key = "item"..item_id
                    if (count_list[item_count_key] == nil) then
                        count_list[item_count_key] = {total_count = 1, left_count = 1}
                    else
                        count_list[item_count_key].total_count = count_list[item_count_key].total_count + 1
                        count_list[item_count_key].left_count = count_list[item_count_key].total_count
                    end
                    total_count = total_count + 1
                    break
                end
            end
        end
    end

    return count_list, total_count
end

InitExternInfo = function(game_room_config, save_data)
    if (save_data.trigger_free_count == nil) then
        save_data.trigger_free_count = 0
    end

    if (save_data.new_free_count == nil) then
        save_data.new_free_count = 0
    end

    if (save_data.his_bet_amount == nil) then
        save_data.his_bet_amount = {}
    end

    
    if (save_data.rapithit_jackpot == nil) then
        save_data.rapithit_jackpot = {}
        local rapidhit_jackpot_config = CommonCal.Calculate.get_config(player, game_room_config.game_name .. "RapidHitConfig")
        for k, sub_config in pairs(rapidhit_jackpot_config) do
            save_data.rapithit_jackpot[sub_config.id] = 0
        end
    end

    if (save_data.classic_jackpot == nil) then
        save_data.classic_jackpot = {}
        local classic_jackpot_config = CommonCal.Calculate.get_config(player, game_room_config.game_name .. "JackpotConfig")
        for k, sub_config in pairs(classic_jackpot_config) do
            save_data.classic_jackpot[sub_config.id] = 0
        end
    end

    if (save_data.is_super_free == nil) then
        save_data.is_super_free = 0
    end

    if (save_data.total_free_spin_times == nil) then
        save_data.total_free_spin_times = 0
    end    
end

-------获取classic类型的ID
GetStarKeys = function(game_room_config)
    local type = _G[game_room_config.game_name.."TypeArray"].Types
    return {type.OneStar, type.TwoStar, type.ThreeStar, type.FiveStar, type.TwoThreeFiveStar}
end

GetClassicTypes = function(game_room_config)
    local type = _G[game_room_config.game_name.."TypeArray"].Types
    local classic_types = {}
    classic_types[type.OneStar] = 1
    classic_types[type.TwoStar] = 2
    classic_types[type.ThreeStar] = 3
    classic_types[type.FiveStar] = 4
    classic_types[type.TwoThreeFiveStar] = 5
    return classic_types
end

---获取classic的jackpot奖池信息
GenClassicJacpotPool = function(player, game_room_config, pre_action_list, amount, save_data, is_get_pool, lines_num, reel_value)
    local type = _G[game_room_config.game_name.."TypeArray"].Types

    local jackpot_config = CommonCal.Calculate.get_config(player, game_room_config.game_name .. "JackpotConfig")
    local jackpot_win_chip = 0
    if (not is_get_pool) then
        local classic_jackpot_pool = {}
        for k, v in ipairs(jackpot_config) do
            --local base_value = v.start_point * amount * lines_num
            save_data.classic_jackpot[v.id] = save_data.classic_jackpot[v.id] + v.jackpot_spin_inject_rate * amount * lines_num
            local add_value = save_data.classic_jackpot[v.id]
            table.insert(classic_jackpot_pool, {base_payrate = v.start_point, add_value = math.floor(add_value)})
        end

        local classic_types = GetClassicTypes(game_room_config)

        local cur_jacpot_conf = jackpot_config[reel_value.is_jackpot]

        local jackpot_point = 0
        if (cur_jacpot_conf ~= nil) then
            if (cur_jacpot_conf.bet_amount_req > 0) then
                if (amount >= cur_jacpot_conf.bet_amount_req) then
                    jackpot_point = cur_jacpot_conf.start_point
                else
                    jackpot_point = cur_jacpot_conf.base_point
                end
            else
                jackpot_point = cur_jacpot_conf.base_point
            end
        end

        if (jackpot_point > 0) then
            jackpot_win_chip = jackpot_point * amount * lines_num + save_data.classic_jackpot[cur_jacpot_conf.id]
            save_data.classic_jackpot[cur_jacpot_conf.id] = 0
        end

        table.insert(pre_action_list, {
            action_type = ActionType.ActionTypes.ClassicJackpotPool,
            jackpot_pool = classic_jackpot_pool,
            jackpot_win_chip = math.floor(jackpot_win_chip),
        })
    else
        local classic_jackpot_pool = {}
        for k, v in ipairs(jackpot_config) do
            --local base_value = v.start_point * amount * lines_num
            save_data.classic_jackpot[v.id] = save_data.classic_jackpot[v.id] + v.jackpot_spin_inject_rate * amount * lines_num
            local add_value = save_data.classic_jackpot[v.id]
            table.insert(classic_jackpot_pool, {base_payrate = v.start_point, add_value = math.floor(add_value)})
        end

        table.insert(pre_action_list, {
            action_type = ActionType.ActionTypes.ClassicJackpotPool,
            jackpot_pool = classic_jackpot_pool,
            jackpot_win_chip = math.floor(jackpot_win_chip),
        })
    end
    return math.floor(jackpot_win_chip)
end

---获取rapit hit的jackpot奖池信息
GenJacpotPool = function(player, game_room_config, pre_action_list, amount, save_data, is_get_pool, result_row, lines_num)
    local type = _G[game_room_config.game_name.."TypeArray"].Types
    local jackpot_config = CommonCal.Calculate.get_config(player, game_room_config.game_name .. "RapidHitConfig")
    local rabit_hit_count = 0
    local jackpot_win_chip = 0
    if (not is_get_pool) then

        local jackpot_pool = {}
        for k, v in ipairs(jackpot_config) do
            --local base_value = v.start_point * amount * lines_num

            save_data.rapithit_jackpot[v.id] = save_data.rapithit_jackpot[v.id] + v.rapid_hit_spin_inject_rate * amount * lines_num

            local add_value = save_data.rapithit_jackpot[v.id]
            table.insert(jackpot_pool, {base_payrate = v.start_point, add_value = math.floor(add_value)})
        end

        local rapidhit_pos_list = SlotsGameCal.Calculate.GetItemPosition(result_row, game_room_config, type.RapidHit)
        local wild_rapidhit_pos_list = SlotsGameCal.Calculate.GetItemPosition(result_row, game_room_config, type.WildJackpot)
        for k, pos in pairs(wild_rapidhit_pos_list) do
            table.insert(rapidhit_pos_list, pos)
        end

        rabit_hit_count = #rapidhit_pos_list > 9 and 9 or #rapidhit_pos_list
        if (rabit_hit_count == 0) then
            rabit_hit_count = 1
        end
        local jackpot_point = 0
        local cur_jacpot_conf = jackpot_config[rabit_hit_count]
        if (cur_jacpot_conf ~= nil) then
            if (cur_jacpot_conf.bet_amount_req > 0) then
                if (amount >= cur_jacpot_conf.bet_amount_req) then 
                    jackpot_point = cur_jacpot_conf.start_point
                else
                    jackpot_point = cur_jacpot_conf.base_point
                end
            else
                jackpot_point = cur_jacpot_conf.base_point
            end
        end

        if (jackpot_point > 0) then
            jackpot_win_chip = jackpot_point * amount * lines_num + save_data.rapithit_jackpot[cur_jacpot_conf.id]

            save_data.rapithit_jackpot[cur_jacpot_conf.id] = 0
        end

        table.insert(pre_action_list, {
            action_type = ActionType.ActionTypes.GameJackpotPool,
            jackpot_pool = jackpot_pool,
            rabit_hit_count = rabit_hit_count,
            jackpot_win_chip = math.floor(jackpot_win_chip),
            rapidhit_pos_list = rapidhit_pos_list,
        })
    else
        local jackpot_pool = {}
        for k, v in ipairs(jackpot_config) do
            --local base_value = v.start_point * amount * lines_num
            local add_value = save_data.rapithit_jackpot[v.id]

            table.insert(jackpot_pool, {base_payrate = v.start_point, add_value = math.floor(add_value)})
        end

        table.insert(pre_action_list, {
            action_type = ActionType.ActionTypes.GameJackpotPool,
            jackpot_pool = jackpot_pool,
            rabit_hit_count = rabit_hit_count,
            jackpot_win_chip = math.floor(jackpot_win_chip),
            rapidhit_pos_list = {},
        })
    end

    return math.floor(jackpot_win_chip)
end

-------只有固定1条线,并且在前端不需要展示连线
GetPrizeList = function(middleRow, payrate)
    local pos_list = {}

    ---------不是wild中奖，在第三行将非空元素所在位置发给客户端
    for k, v in pairs(middleRow)
    do
        if (v ~= 12)
        then
            table.insert(pos_list, k)
        end
    end

    local prize_list = {}
    local prize = {
        item_id = 0,
        continue_count = 3,
        payrate = payrate,
        line_index = 1,
        from_index = 0,
        to_index = 3,
        pos_list = json.encode(pos_list),
    }
    table.insert(prize_list, prize)
    return prize_list
end

-------获取转轴的信息
GenClassicItemResult = function(player, game_type, game_room_config, classic_type, formation_id)
    --返回值初始化
    local tran_result = nil
    formation_id = formation_id or '1'

    --获取基本的配置
    local formation_name = "Formation"..formation_id
    local filename = "RapidHitClassic"..classic_type.."SpinReelConfig"

    local config = CommonCal.Calculate.get_config(player, filename)

    local formation = _G[game_room_config.game_name .. "FormationArray"][formation_name]


    --生成结果
    local result = {}
    for v = 1, #formation do
        result[v] = SlotsGameCal.Calculate.GenColumn(player, config, v, game_room_config, formation_name)
    end
    tran_result = SlotsGameCal.Calculate.TransResult(result, game_room_config, formation_name)

    --获取中间一行的数据
    local reel_rate_list = {}
    local RapidHitClassicReelResultConfig = CommonCal.Calculate.get_config(player, "RapidHitClassic"..classic_type.."ReelResultConfig")
    for k, v in ipairs(RapidHitClassicReelResultConfig)
    do
        reel_rate_list[k] = v.weights
    end

    local id = math.rand_weight(player, reel_rate_list)

    LOG(RUN, INFO).Format("[SlotsRapidHitSpin][GenClassicItemResult] player id %s, classic_type is:%s", player.id, classic_type)
    LOG(RUN, INFO).Format("[SlotsRapidHitSpin][GenClassicItemResult] player id %s, id is:%s", player.id, id)
    local reel_value = RapidHitClassicReelResultConfig[id]

    local item_array = table.DeepCopy(reel_value.item_array)

    local rand_pos = {[1] = 1, [2] = 1, [3] = 1}
    if (reel_value.order == 0)--随机变换位置
    then
        local tmp_value = {}
        for index = 1, 3, 1
        do
            local pos = math.rand_weight(player, rand_pos)
            tmp_value[index] = item_array[pos]
            rand_pos[pos] = 0
        end

        item_array = tmp_value
    end

    tran_result[3] = item_array


    --返回
    return tran_result, reel_file_name, reel_value
end