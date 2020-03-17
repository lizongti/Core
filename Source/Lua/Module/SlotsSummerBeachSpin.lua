require "Common/SlotsGameCal"
require "Common/CommonCal"
require "Common/LineNum"
module("SlotsSummerBeachSpin", package.seeall)
Enter = function(task, player, game_room_config)
    local bonus_info = {}
    return bonus_info
end

Spin = function(player, game_type, is_free_spin, game_room_config, amount, player_feature_condition, extern_param, player_game_info)
    return SpinProcess(player, game_type, is_free_spin, game_room_config, amount, player_feature_condition, extern_param, player_game_info)
end

-----------------------------------------------
-- 点击Spin
------------------------------------------------
SpinProcess = function(player, game_type, is_free_spin, game_room_config, amount, player_feature_condition, extern_param, player_game_info)

    local LineNum = LineNum[game_type]()

    local Types = _G[game_room_config.game_name.."TypeArray"].Types

    ------201810310936开始------------------

    if (player_feature_condition ~= nil)
    then
        player_feature_condition.spin_num = player_feature_condition.spin_num + 1
    end


    ------201810310936结束------------------

    local origin_result, reel_file_name = SlotsGameCal.Calculate.GenItemResult(player, game_type, is_free_spin, game_room_config, nil)

    local item_ids = json.encode(SlotsGameCal.Calculate.TransResultToCList(origin_result, game_room_config))

    local item_list = SlotsGameCal.Calculate.TransResultToList(origin_result, game_room_config)
    local sel_item_id = 0
    local camera_feature_config = CommonCal.Calculate.get_config(player, game_room_config.game_name.."CameraFeatureConfig")
    --CAMERA FEATURE出现概率
    local camera_appear_tab = {[1] = 0.08, [2] = 0.92}
    local local_appear_index = math.rand_weight(player, camera_appear_tab)
    if (GlobalSlotsTest[player.id] and GlobalSlotsTest[player.id].flag == 1)
    then
        local_appear_index = 1
    end

    local local_ok_index = math.random_ext(player, 1, 2)

    if (local_appear_index == 1)
    then
        local sel_item_ids = {}
        for k, v in ipairs(item_list)
        do
            local is_find = false
            for sub_k, sub_v in ipairs(sel_item_ids)
            do
                if (sub_k == v)
                then
                    is_find = true
                    break
                end
            end

            if (not is_find and camera_feature_config[v])
            then
                sel_item_ids[v] = camera_feature_config[v].probability
            end 
        end

        sel_item_id = math.rand_weight(player, sel_item_ids)
    end

    local multiple_value = 0
    local pos_list = {}
    if (local_appear_index == 1 and local_ok_index == 1)
    then
        multiple_value = camera_feature_config[sel_item_id].pay_multiple

        pos_list = SlotsGameCal.Calculate.GetPos(game_room_config, origin_result, sel_item_id)
    end

    local all_prize_items = {} 
    local payrate_file = CommonCal.Calculate.get_config(player, game_room_config.game_name.."PayrateConfig")
    local left_or_right = game_room_config.direction_type--1左连线，2右, 3左右连线
    local prize_items, total_payrate = SlotsGameCal.Calculate.GenPrizeInfo(origin_result, game_room_config, payrate_file, left_or_right, Types)
    table.insert(all_prize_items, prize_items)

    local slots_win_chip = total_payrate * amount 

    local win_chip = total_payrate * amount + amount * LineNum * multiple_value

    local free_spin_bouts, free_item_id = SlotsGameCal.Calculate.GenFreeSpinCount(origin_result, game_room_config, Types.Scatter)

    local slots_spin_list = {}

    local slots_spin_info = {}

    slots_spin_info.item_ids = item_ids
    slots_spin_info.prize_items = prize_items
    slots_spin_info.win_chip = win_chip
    slots_spin_info.final_item_ids = item_ids

    if (#pos_list > 0)
    then
        local index = math.random_ext(player, 1, #pos_list)
        local sel_pos = pos_list[index]

        local pre_action_list = {}

        local pre_action = {}
        pre_action.action_type = ActionType.ActionTypes.TakePhoto
        pre_action.source_pos = sel_pos
        pre_action.des_pos = sel_pos
        pre_action.item_id = sel_item_id
        local parameter = {}
        parameter.type = 1
        parameter.value = multiple_value
        local parameter_list = {}
        table.insert(parameter_list, parameter)
        pre_action.parameter_list = parameter_list

        table.insert(pre_action_list, pre_action)

        --LOG(RUN, INFO).Format("[SlotsGame][Start] player %s init pre_action1", player.id)

        slots_spin_info.pre_action_list = json.encode(pre_action_list)
    elseif (local_appear_index == 1 and sel_item_id > 0)--假拍照
    then
        pos_list = SlotsGameCal.Calculate.GetPos(game_room_config, origin_result, sel_item_id)
        local index = math.random_ext(player, 1, #pos_list)
        local sel_pos = pos_list[index]

        local pre_action_list = {}

        local pre_action = {}
        pre_action.action_type = ActionType.ActionTypes.TakePhotoFaker
        pre_action.source_pos = sel_pos
        pre_action.des_pos = sel_pos
        pre_action.item_id = sel_item_id
        local parameter = {}
        parameter.type = 1
        parameter.value = 1
        local parameter_list = {}
        table.insert(parameter_list, parameter)
        pre_action.parameter_list = parameter_list

        table.insert(pre_action_list, pre_action)
        --LOG(RUN, INFO).Format("[SlotsGame][Start] player %s init pre_action2", player.id)
        slots_spin_info.pre_action_list = json.encode(pre_action_list)
    end

    table.insert(slots_spin_list, slots_spin_info)

    local formation_list = {}
    local formation_info = {}
    formation_info.slots_spin_list = slots_spin_list
    table.insert(formation_list, formation_info)

    formation_info.id = 1

    return origin_result, win_chip, all_prize_items, free_spin_bouts, formation_list, reel_file_name, slots_win_chip
end

IsBonusGame = function(game_room_config, player)
    return false
end