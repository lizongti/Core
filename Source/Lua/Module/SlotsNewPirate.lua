require "Common/SlotsGameCalculate" --重写的接口
require "Common/SlotsGameCal" --旧的接口
require "Common/GameStatusDefine"
require "Module/SlotsNewPirateSpin"
require "Module/SlotsBaseSpin"

module("SlotsNewPirate", package.seeall)

Enter = function(args)
    local functions_info = {
        [GameStatusDefine.AllTypes.BaseSpinGame] = "Spin",
        [GameStatusDefine.AllTypes.FreeSpinGame] = "FreeSpin"
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

    local SlotsGameSpin = SlotsBaseSpin:Create(SlotsNewPirateSpin, args)
    return SlotsGameSpin:Enter()
end

IsBonusGame = function(game_room_config, player, player_game_info)
    if (player_game_info.bonus_game_type > 0) then
        return true
    end
    return false
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

NewPirateBonusStart = function(args)
    local SlotsGameSpin = SlotsBaseSpin:InitParameters(args)
    return SlotsGameSpin:BonusStart()
end

NewPirateBonusFinish = function(args)
    local SlotsGameSpin = SlotsBaseSpin:InitParameters(args)
    return SlotsGameSpin:BonusFinish()
end
