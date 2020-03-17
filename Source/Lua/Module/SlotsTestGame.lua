require "Common/SlotsGameCalculate"     --重写的接口
require "Common/SlotsGameCal"           --旧的接口
require "Common/GameStatusDefine"
require "Module/SlotsTestGameSpin"
require "Module/SlotsBaseSpin"

module("SlotsTestGame", package.seeall)

Enter = function(args)
    local functions_info = {
        [GameStatusDefine.AllTypes.BaseSpinGame] = "Spin",
        [GameStatusDefine.AllTypes.FreeSpinGame] = "FreeSpin",
    }

    CommonCal.Calculate.InitFunctions(args.player, functions_info)

    local SlotsGameSpin = SlotsBaseSpin:Create(SlotsTestGameSpin, args)
    return SlotsGameSpin:Enter()
end

IsBonusGame = function(game_room_config, player, player_game_info)
    return false
end

Spin = function(args)
    local SlotsGameSpin = SlotsBaseSpin:InitParameters(args)
    return SlotsGameSpin:NormalSpin()
end

FreeSpin = function(args)
    local SlotsGameSpin = SlotsBaseSpin:InitParameters(args)
    return SlotsGameSpin:NormalSpin()
end

FeatureEnd = function(game_room_config, player_game_info, player, status_info, pre_action_list, special_parameter)
    local status_id = status_info.status_id
    local win_chip = status_info.win_chip
    local spin_count = status_info.spin_count
    return true
end