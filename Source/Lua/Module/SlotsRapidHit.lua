require "Common/SlotsGameCalculate"     --重写的接口
require "Common/SlotsGameCal"           --旧的接口
require "Common/SlotsRapidHitCal"
require "Common/GameStatusDefine"
require "Module/SlotsRapidHitSpin"
module("SlotsRapidHit", package.seeall)

Enter = function(args)
    ---状态和处理函数的关联
    local functions_info = {
        [GameStatusDefine.AllTypes.BaseSpinGame] = "Spin",
        [GameStatusDefine.AllTypes.FreeSpinGame] = "FreeSpin",
        [GameStatusDefine.AllTypes.ClassicSpinGame] = "ClassicSpin",
    }
    CommonCal.Calculate.InitFunctions(args.player, functions_info)

    local SlotsGameSpin = SlotsBaseSpin:Create(SlotsRapidHitSpin, args)

    ---值越大越先执行
    local priority_level = {
        [GameStatusDefine.AllTypes.BaseSpinGame] = 1,
        [GameStatusDefine.AllTypes.FreeSpinGame] = 1,
        [GameStatusDefine.AllTypes.ClassicSpinGame] = 2,
    }
    CommonCal.Calculate.InitPriorityLevel(args.game_room_config.game_type, priority_level)
    CommonCal.Calculate.InitSortedPriorityLevel(args.game_room_config.game_type)

    return SlotsGameSpin:Enter()
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
RapidHitBonusStart = function (args)
    local player_game_status = args.player_game_status

    local bonus_number = GetBonusConfig(player, game_room_config)[1].Bonus_number
	local content = {}
    
    return content
end

RapidHitBonusFinish = function (task, player, game_room_config, parameter, player_game_info)
    local content = {}

    return content
end

Spin = function(args)
    local SlotsGameSpin = SlotsBaseSpin:InitParameters(args)
    SlotsGameSpin:InitParameters(args)
    CommonCal.Calculate.InitSortedPriorityLevel(args.game_room_config.game_type)
    LOG(RUN, INFO).Format("[SlotsRapidHit][Spin] begin")
    return SlotsGameSpin:NormalSpin()
end

FreeSpin = function(args)

    local SlotsGameSpin = SlotsBaseSpin:InitParameters(args)
    SlotsGameSpin:InitParameters(args)
    CommonCal.Calculate.InitSortedPriorityLevel(args.game_room_config.game_type)
    LOG(RUN, INFO).Format("[SlotsRapidHit][FreeSpin] begin")
    return SlotsGameSpin:NormalSpin()
end

ClassicSpin = function(args)
    args.formation_id = 2
    args.formation_name = "Formation"..args.formation_id
    local SlotsGameSpin = SlotsBaseSpin:InitParameters(args)
    SlotsGameSpin:InitParameters(args)
    CommonCal.Calculate.InitSortedPriorityLevel(args.game_room_config.game_type)
    LOG(RUN, INFO).Format("[SlotsRapidHit][ClassicSpin] begin")
    return SlotsGameSpin:ClassicSpin()
end

FeatureEnd = function(game_room_config, player_game_info, player, status_info, pre_action_list, special_parameter)---完成的状态，总金额，总spin次数
    local status_id = status_info.status_id
    local win_chip = status_info.win_chip
    local spin_count = status_info.spin_count
    local save_data = player_game_info.save_data
    if (status_id == GameStatusDefine.AllTypes.FreeSpinGame) then
        local is_super_free_end = 0
        if (save_data.is_super_free == 1) then
            is_super_free_end = 1
            save_data.is_super_free = 0
            save_data.new_free_count = 0
            save_data.his_bet_amount = {}

            SlotsGameCal.Calculate.RestoreBetAmountInRunning(player_game_info)
        end

        table.insert(pre_action_list, {
            action_type = ActionType.ActionTypes.TotalFreeSpinWin,
            free_total_win = win_chip,
            total_free_spin_times = spin_count,
            is_super_free_end = is_super_free_end,
        })
    end

    ----没有收集奖励，不给玩家
    return true
end