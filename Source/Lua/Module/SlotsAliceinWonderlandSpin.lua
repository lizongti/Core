require "Common/SlotsGameCalculate"     --重写的接口
require "Common/SlotsGameCal"           --旧的接口

module("SlotsAliceinWonderlandSpin", package.seeall)


IsBonusGame = function(game_room_config, player)
    return false
end

-----------------------------------------------
-- Bonus Game
-----------------------------------------------
AliceinWonderlandBonusStart = function (task, player, game_room_config, parameter, player_game_info)
	local content = {}

    local save_data = player_game_info.save_data

    if (save_data.is_bonus == nil or save_data.is_bonus == 0) then
        return content
    end

    save_data.bonus_info = {}
    
    local pick_bonus_config = CommonCal.Calculate.get_config(player, game_room_config.game_name .. "PickBonusConfig")

    local rose_bonus_config = CommonCal.Calculate.get_config(player, game_room_config.game_name .. "RoseBonusConfig")

    local round_value = 5

    local round_info_list = {}
    for round = 1, round_value, 1 do
        -----每局信息-----------
        local config_list = {}
        local local_weight_tab = {}

        for k, v in ipairs(pick_bonus_config) do
            if (v.Round == round) then
                table.insert(config_list, v)
            end
        end

        for k, v in ipairs(config_list)
        do
           local_weight_tab[k] = v.Probability
        end
        local local_index = math.rand_weight(player, local_weight_tab)	

        local round_info = {}
        for k, v in ipairs(config_list) do
            if (k == local_index) then
                table.insert(round_info, {bonus = v.Bonus, is_sel = 1})
            else
                table.insert(round_info, {bonus = v.Bonus, is_sel = 0})
            end
        end
        
        table.insert(round_info_list, round_info)
    end

    save_data.bonus_info.round_info_list = round_info_list
    
    local rose_weight_tab = {}

    for k, v in ipairs(rose_bonus_config)
    do
        rose_weight_tab[k] = v.Probability
    end
    local rose_index = math.rand_weight(player, rose_weight_tab)	

    local rose_info = {}
    for k, v in ipairs(rose_bonus_config) do
        if (k == rose_index) then
            table.insert(rose_info, {bonus = v.Bonus, is_sel = 1})
        else
            table.insert(rose_info, {bonus = v.Bonus, is_sel = 0})
        end
    end

    save_data.bonus_info.rose_info = rose_info

    --[[
    {"bonus_info":
        {
            "rose_info":
            [{"is_sel":1,"bonus":0},{"is_sel":0,"bonus":3},{"is_sel":0,"bonus":2}],
            "round_info_list":----5轮的信息
            [
                [{"is_sel":1,"bonus":0.2},{"is_sel":0,"bonus":0.5},{"is_sel":0,"bonus":1},{"is_sel":0,"bonus":2}],
                [{"is_sel":1,"bonus":0.5},{"is_sel":0,"bonus":1},{"is_sel":0,"bonus":2},{"is_sel":0,"bonus":3}],
                [{"is_sel":1,"bonus":1},{"is_sel":0,"bonus":2},{"is_sel":0,"bonus":3},{"is_sel":0,"bonus":4}],
                [{"is_sel":0,"bonus":2},{"is_sel":1,"bonus":3},{"is_sel":0,"bonus":4},{"is_sel":0,"bonus":5}],
                [{"is_sel":1,"bonus":3},{"is_sel":0,"bonus":4},{"is_sel":0,"bonus":5},{"is_sel":0,"bonus":6}]
            ]
        }
    }
    --]]
    return save_data
end

AliceinWonderlandBonusFinish = function (task, player, game_room_config, parameter, player_game_info)
    local content = {}

    local save_data = player_game_info.save_data

    if (save_data.bonus_info == nil) then
        return content
    end

    local total_bonus = 0
    for round_info_index, round_info in ipairs(save_data.bonus_info.round_info_list) do
        for detail_index, detail in ipairs(round_info) do
            if (detail.is_sel == 1) then
                total_bonus = total_bonus + detail.bonus
            end
        end
    end

    for rose_index, rose_detail in ipairs(save_data.bonus_info.rose_info) do
        if (rose_detail.is_sel == 1) then
            if (rose_detail.bonus == 0) then
                player_game_info.free_spin_bouts = player_game_info.free_spin_bouts + 10
            else
                total_bonus = total_bonus * rose_detail.bonus
            end
        end
    end    

    content.win_chip = total_bonus *  player_game_info.bet_amount * 25

    player_game_info.save_data = {}
    save_data = {}

    return content
end