require "Common/SlotsGameCalculate"     --重写的接口
require "Common/SlotsGameCal"           --旧的接口
require "Common/GameStatusDefine"
require "Module/SlotsMagicScarabSpin"
module("SlotsMagicScarab", package.seeall)

Enter = function(args)
    ---状态和处理函数的关联
    local functions_info = {
        [GameStatusDefine.AllTypes.BaseSpinGame] = "Spin",
        [GameStatusDefine.AllTypes.FreeSpinGame] = "FreeSpin",
    }
    CommonCal.Calculate.InitFunctions(args.player, functions_info)

    local SlotsGameSpin = SlotsBaseSpin:Create(SlotsMagicScarabSpin, args)
    LOG(RUN, INFO).Format("[SlotsMagicScarab][Enter] begin")

    ---值越大越先执行
    local priority_level = {
        [GameStatusDefine.AllTypes.BaseSpinGame] = 1,
        [GameStatusDefine.AllTypes.FreeSpinGame] = 1,
    }
    CommonCal.Calculate.InitPriorityLevel(args.game_room_config.game_type, priority_level)
    CommonCal.Calculate.InitSortedPriorityLevel(args.game_room_config.game_type)

    return SlotsGameSpin:Enter()
end

IsBonusGame = function(game_room_config, player, player_game_info)
    return false
end

Spin = function(args)
    args.formation_num = 7
    args.start_id = 1
    args.end_id = 1
    local SlotsGameSpin = SlotsBaseSpin:InitParameters(args)
    CommonCal.Calculate.InitSortedPriorityLevel(args.game_room_config.game_type)
    LOG(RUN, INFO).Format("[SlotsMagicScarab][Spin] begin")
    return SlotsGameSpin:NormalSpin()
end

FreeSpin = function(args)
    local player_game_info = args.player_game_info
    local save_data = player_game_info.save_data
    --save_data.spin_status = 0 ---0:normal,1:free spin,2 super free spin
    if (save_data.spin_status == 1) then
        args.formation_num = 7
        args.start_id = 2
        args.end_id = 3
        save_data.cur_free_status = 1---当前free spin状态,1是normal free spin,2是super free spin
    elseif (save_data.spin_status == 2) then
        args.formation_num = 7
        args.start_id = 4
        args.end_id = 7
        save_data.cur_free_status = 2---当前free spin状态,1是normal free spin,2是super free spin
    end
    local SlotsGameSpin = SlotsBaseSpin:InitParameters(args)
    CommonCal.Calculate.InitSortedPriorityLevel(args.game_room_config.game_type)
    LOG(RUN, INFO).Format("[SlotsMagicScarab][FreeSpin] begin")
    return SlotsGameSpin:NormalSpin()
end

FeatureEnd = function(game_room_config, player_game_info, player, status_info, pre_action_list, special_parameter)---完成的状态，总金额，总spin次数
    local status_id = status_info.status_id
    local win_chip = status_info.win_chip
    local spin_count = status_info.spin_count
    local save_data = player_game_info.save_data
    if (status_id == GameStatusDefine.AllTypes.FreeSpinGame) then
        if (save_data.spin_status == 2) then
            save_data.his_bet_amount = {}
            SlotsGameCal.Calculate.RestoreBetAmountInRunning(player_game_info)
        end
    end
    ----没有收集奖励，不给玩家
    return true
end