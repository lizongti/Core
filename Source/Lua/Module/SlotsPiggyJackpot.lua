require "Common/SlotsGameCalculate"     --重写的接口
require "Common/SlotsGameCal"           --旧的接口
require "Common/GameStatusDefine"
require "Module/SlotsPiggyJackpotSpin"
require "Module/SlotsBaseSpin"

module("SlotsPiggyJackpot", package.seeall)

Enter = function(args)
    local functions_info = {
        [GameStatusDefine.AllTypes.BaseSpinGame] = "Spin",
        [GameStatusDefine.AllTypes.FreeSpinGame] = "FreeSpin",
        [GameStatusDefine.AllTypes.SuperFreeSpinGame] = "SuperFreeSpin",
    }

    CommonCal.Calculate.InitFunctions(args.player, functions_info)

    --值越大越先执行
    local priority_level = {
        [GameStatusDefine.AllTypes.BaseSpinGame] = 1,
        [GameStatusDefine.AllTypes.FreeSpinGame] = 1,
        [GameStatusDefine.AllTypes.SuperFreeSpinGame] = 1,
        [GameStatusDefine.AllTypes.BonusSpinGame] = 1,
    }

    CommonCal.Calculate.InitPriorityLevel(args.game_room_config.game_type, priority_level)
    CommonCal.Calculate.InitSortedPriorityLevel(args.game_room_config.game_type)

    local SlotsGameSpin = SlotsBaseSpin:Create(SlotsPiggyJackpotSpin, args)
    return SlotsGameSpin:Enter()
end

IsBonusGame = function(game_room_config, player, player_game_info)
    return false
end

SpinWheelEnter = function (args)
    local SlotsGameSpin = SlotsBaseSpin:InitParameters(args)
    return SlotsGameSpin:SpinWheelEnter()
end

SpinWheelAdEnter = function (args)
    local SlotsGameSpin = SlotsBaseSpin:InitParameters(args)
    return SlotsGameSpin:SpinWheelAdEnter()
end

SpinWheelFinish = function (args)
    local SlotsGameSpin = SlotsBaseSpin:InitParameters(args)
    return SlotsGameSpin:SpinWheelFinish()
end

Spin = function(args)
    local SlotsGameSpin = SlotsBaseSpin:InitParameters(args)
    CommonCal.Calculate.InitSortedPriorityLevel(args.game_room_config.game_type)
    return SlotsGameSpin:NormalSpin()
end

FreeSpin = function(args)
    local SlotsGameSpin = SlotsBaseSpin:InitParameters(args)
    CommonCal.Calculate.InitSortedPriorityLevel(args.game_room_config.game_type)
    return SlotsGameSpin:NormalSpin()
end

SuperFreeSpin = function(args)
    local SlotsGameSpin = SlotsBaseSpin:InitParameters(args)
    CommonCal.Calculate.InitSortedPriorityLevel(args.game_room_config.game_type)
    return SlotsGameSpin:NormalSpin()
end

FeatureEnd = function(game_room_config, player_game_info, player, status_info, pre_action_list, special_parameter)
    local status_id = status_info.status_id
    local win_chip = status_info.win_chip
    local spin_count = status_info.spin_count
    local save_data = player_game_info.save_data

    if status_id == GameStatusDefine.AllTypes.FreeSpinGame then
        table.insert(pre_action_list, {
            action_type = ActionType.ActionTypes.TotalFreeSpinWin,
            free_total_win = player_game_info.free_total_win,
            total_free_spin_times = spin_count
        })

        special_parameter.wild_win_chip = save_data.wild_win_chip
        special_parameter.free_total_win = win_chip
        save_data.wild_win_chip = 0
    end
    
    return true
end