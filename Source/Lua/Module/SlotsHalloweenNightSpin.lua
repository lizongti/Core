require "Common/SlotsGameCal"
require "Common/CommonCal"
require "Common/LineNum"
require "dkjson"
require "Common/SlotsHalloweenNightCal"
module("SlotsHalloweenNightSpin", package.seeall)
Enter = function(task, player, game_room_config)
    local bonus_info = {}
    return bonus_info
end

Spin = function(player, game_type, is_free_spin, game_room_config, amount, player_feature_condition, extern_param, player_game_info)
    return SpinProcess(player, game_type, is_free_spin, game_room_config, amount, player_feature_condition, extern_param, player_game_info)
end


GetLinesNum = function()
    return 30
end
-----------------------------------------------
-- 点击Spin
------------------------------------------------
SpinProcess = function(player, game_type, is_free_spin, game_room_config, amount, player_feature_condition, extern_param, player_game_info)
    ------201810310936开始------------------
    local conditions = {}

    ------201810310936结束------------------

    local LineNum = #SlotsHalloweenNightCal.Const.Lines

    local sticky_wild_pos_list = json.decode(player_game_info.sticky_wild_pos_list)

    --LOG(RUN, INFO).Format("[SlotsHalloweenNight][Start] player %s", player.id)
    local isfreeze = 0
    --free spin不扣钱, free spin下amount不会改
    if not is_free_spin then
        if (amount > player_game_info.bet_amount and (player_game_info.cd_wild_index > 0 or #sticky_wild_pos_list > 0))
        then
            isfreeze = 1
        end
    end
    --------------------------------------------------开始修改----------------------------------
    local cd_wild_index

    if (isfreeze == 1)
    then
        sticky_wild_pos_list = {}

        player_game_info.cd_wild_index = 0
        player_game_info.cd_wild_times = 0        
    end
    
    if player_game_info.cd_wild_times > 0 then
        cd_wild_index = player_game_info.cd_wild_index
        player_game_info.cd_wild_times = player_game_info.cd_wild_times - 1
    end
    if player_game_info.cd_wild_times == 0 then
        player_game_info.cd_wild_index = 0
    end


    local sticky_wild_list = {}
    if #sticky_wild_pos_list > 0 then
        sticky_wild_list = sticky_wild_pos_list
    end

    local HalloweenNightOthersConfig = CommonCal.Calculate.get_config(player, "HalloweenNightOthersConfig")

    ------201810310936开始------------------

    player_feature_condition.spin_num = player_feature_condition.spin_num + 1

    ------201810310936结束------------------

    
    local origin_result, new_cd_wild_index, reel_file_name = SlotsHalloweenNightCal.Calculate.GenItemResult(player, is_free_spin, sticky_wild_list, cd_wild_index,  nil)
    if new_cd_wild_index then
        player_game_info.cd_wild_index = new_cd_wild_index
        player_game_info.cd_wild_times = HalloweenNightOthersConfig[1].count_down_times
    end

    local all_prize_items = {}
    local new_sticky_list = {}
    local prize_items, total_payrate = SlotsHalloweenNightCal.Calculate.GenPrizeInfo(player, origin_result, new_sticky_list)
    table.insert(all_prize_items, prize_items)
    sticky_wild_list = new_sticky_list

    local res_sticky_wild_list = nil
    if total_payrate > 0 and #sticky_wild_pos_list < 6 then
        --response.sticky_wild_list = sticky_wild_list
        res_sticky_wild_list = sticky_wild_list
        sticky_wild_pos_list = {}
        for _, value in ipairs(sticky_wild_list)
        do
            table.insert(sticky_wild_pos_list, value)
        end
    else
        sticky_wild_pos_list = {}
        res_sticky_wild_list = {}
        --response.sticky_wild_list = {}
    end

    player_game_info.sticky_wild_pos_list = json.encode(sticky_wild_pos_list)
    
    local free_spin_bouts = SlotsHalloweenNightCal.Calculate.GenFreeSpinCount(player, origin_result)
    player_game_info.free_spin_bouts = player_game_info.free_spin_bouts + free_spin_bouts
    local treasure_index = SlotsHalloweenNightCal.Calculate.GetTreasureIndex(origin_result)

    local treasure_chip = 0
    local treasure_row = 0
    if treasure_index then
        treasure_row = treasure_index
        treasure_chip = amount * HalloweenNightOthersConfig[1].treasure_payrate * LineNum
    end


    local win_chip = total_payrate * amount + treasure_chip


    local slots_win_chip = win_chip

    ----------------兼容模拟器-------------------
    local formation_list = {}
    if (game_room_config ~= nil)
    then
        local slots_spin_list = {}
        local slots_spin_info = {}
        local tran_result = SlotsGameCal.Calculate.TransResult(origin_result, game_room_config)
        local result_column = SlotsGameCal.Calculate.TransResultToCList(tran_result, game_room_config)

        slots_spin_info.item_ids = json.encode(result_column)
        slots_spin_info.prize_items = prize_items
        slots_spin_info.win_chip = win_chip

        table.insert(slots_spin_list, slots_spin_info)


        local formation_info = {}
        formation_info.slots_spin_list = slots_spin_list
        formation_info.id = 1
        table.insert(formation_list, formation_info)
    end

    local special_parameter = {}

    special_parameter.res_sticky_wild_list = res_sticky_wild_list
    special_parameter.treasure_row = treasure_row
    special_parameter.treasure_chip = treasure_chip
    special_parameter.sticky_wild_list = sticky_wild_list
    special_parameter.total_payrate = total_payrate
    special_parameter.new_cd_wild_index = new_cd_wild_index

    return origin_result, win_chip, all_prize_items, free_spin_bouts, formation_list, reel_file_name, slots_win_chip, special_parameter


end

IsBonusGame = function(game_room_config, player)
    return false
end