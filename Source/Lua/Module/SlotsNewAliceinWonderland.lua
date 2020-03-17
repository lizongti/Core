require "Common/SlotsGameCalculate"     --重写的接口
require "Common/SlotsGameCal"           --旧的接口
require "Common/GameStatusDefine"
require "Module/SlotsNewAliceinWonderlandSpin"
module("SlotsNewAliceinWonderland", package.seeall)

Enter = function(args)
    ---状态和处理函数的关联
    local functions_info = {
        [GameStatusDefine.AllTypes.BaseSpinGame] = "Spin",
        [GameStatusDefine.AllTypes.FreeSpinGame] = "FreeSpin",
        [GameStatusDefine.AllTypes.ReSpinGame] = "ReSpin",
    }
    CommonCal.Calculate.InitFunctions(args.player, functions_info)

    local SlotsGameSpin = SlotsBaseSpin:Create(SlotsNewAliceinWonderlandSpin, args)
    LOG(RUN, INFO).Format("[SlotsNewAliceinWonderland][Enter] begin")

    ---值越大越先执行
    local priority_level = {
        [GameStatusDefine.AllTypes.BaseSpinGame] = 1,
        [GameStatusDefine.AllTypes.FreeSpinGame] = 1,
        [GameStatusDefine.AllTypes.BonusSpinGame] = 1,
        [GameStatusDefine.AllTypes.ReSpinGame] = 2,
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

CheckNeedClearGameInfo = function(player_game_info)
    -- LOG(RUN, INFO).Format("CheckNeedClearGameInfo begin")
    return false
end
-----------------------------------------------
-- Bonus Game
-----------------------------------------------
NewAliceinWonderlandBonusStart = function (args)
    local SlotsGameSpin = SlotsBaseSpin:InitParameters(args)

    return SlotsGameSpin:NewAliceinWonderlandBonusStart()
end

NewAliceinWonderlandBonusFinish = function (args)
    local SlotsGameSpin = SlotsBaseSpin:InitParameters(args)
    LOG(RUN, INFO).Format("[SlotsNewAliceinWonderland][Spin] begin")
    return SlotsGameSpin:NewAliceinWonderlandBonusFinish()
end

Spin = function(args)
    local SlotsGameSpin = SlotsBaseSpin:InitParameters(args)
    CommonCal.Calculate.InitSortedPriorityLevel(args.game_room_config.game_type)
    LOG(RUN, INFO).Format("[SlotsNewAliceinWonderland][Spin] begin")
    return SlotsGameSpin:NormalSpin()

end

ReSpin = function(args)
    local SlotsGameSpin = SlotsBaseSpin:InitParameters(args)
    CommonCal.Calculate.InitSortedPriorityLevel(args.game_room_config.game_type)
    LOG(RUN, INFO).Format("[SlotsNewAliceinWonderland][Spin] begin")
    return SlotsGameSpin:NormalSpin()
end

FreeSpin = function(args)
    local SlotsGameSpin = SlotsBaseSpin:InitParameters(args)
    CommonCal.Calculate.InitSortedPriorityLevel(args.game_room_config.game_type)
    LOG(RUN, INFO).Format("[SlotsNewAliceinWonderland][FreeSpin] begin")
    return SlotsGameSpin:NormalSpin()
end

FeatureEnd = function(game_room_config, player_game_info, player, status_info, pre_action_list, special_parameter)---完成的状态，总金额，总spin次数
    local save_data = player_game_info.save_data


    ----没有收集奖励，不给玩家
    return true
end