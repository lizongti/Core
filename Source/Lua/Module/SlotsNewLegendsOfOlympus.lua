require "Common/SlotsGameCalculate" --重写的接口
require "Common/SlotsGameCal" --旧的接口
require "Common/GameStatusDefine"
require "Module/SlotsNewLegendsOfOlympusSpin"
require "Module/SlotsBaseSpin"

module("SlotsNewLegendsOfOlympus", package.seeall)

Enter = function(args)
    local functions_info = {
        [GameStatusDefine.AllTypes.BaseSpinGame] = "Spin",
        [GameStatusDefine.AllTypes.FreeSpinGame] = "FreeSpin",
        [GameStatusDefine.AllTypes.HoldSpinGame] = "HoldSpin"
    }

    CommonCal.Calculate.InitFunctions(args.player, functions_info)

    ---值越大越先执行
    local priority_level = {
        [GameStatusDefine.AllTypes.BaseSpinGame] = 1,
        [GameStatusDefine.AllTypes.FreeSpinGame] = 2,
        [GameStatusDefine.AllTypes.BonusSpinGame] = 3
    }

    CommonCal.Calculate.InitPriorityLevel(args.game_room_config.game_type, priority_level)
    CommonCal.Calculate.InitSortedPriorityLevel(args.game_room_config.game_type)

    local SlotsGameSpin = SlotsBaseSpin:Create(SlotsNewLegendsOfOlympusSpin, args)
    return SlotsGameSpin:Enter()
end

Spin = function(args)
    local SlotsGameSpin = SlotsBaseSpin:InitParameters(args)
    CommonCal.Calculate.InitSortedPriorityLevel(args.game_room_config.game_type)
    return SlotsGameSpin:Spin()
end

FreeSpin = function(args)
    local SlotsGameSpin = SlotsBaseSpin:InitParameters(args)
    CommonCal.Calculate.InitSortedPriorityLevel(args.game_room_config.game_type)
    return SlotsGameSpin:Spin()
end

IsBonusGame = function(game_room_config, player, player_game_info)
    if (player_game_info.bonus_game_type > 0) then
        return true
    end
    return false
end

NewLegendsOfOlympusBonusStart = function(args)
    local SlotsGameSpin = SlotsBaseSpin:InitParameters(args)
    return SlotsGameSpin:BonusStart()
end

NewLegendsOfOlympusBonusFinish = function(args)
    local SlotsGameSpin = SlotsBaseSpin:InitParameters(args)
    return SlotsGameSpin:BonusFinish()
end
