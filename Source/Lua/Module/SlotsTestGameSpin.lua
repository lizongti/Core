require"Common/SlotsGameCalculate" -- 重写的接口
require"Common/SlotsGameCal" -- 旧的接口
require"Common/LineNum"

SlotsTestGameSpin = {}

local Types = _G["TestGameTypeArray"].Types

-- 入口
function SlotsTestGameSpin:Enter()
    local task = self.parameters.task
    local player = self.parameters.player
    local game_room_config = self.parameters.game_room_config
    local player_game_info = self.parameters.player_game_info
    local session = self.parameters.session
    local player_game_status = self.parameters.player_game_status

    local bonus_info = {}

    return bonus_info
end

IsBonusGame = function(game_room_config, player, player_game_info)
    return false
end

local function GetReelConfig(player, game_room_config, is_free_spin)
    -- body
    local reel_file = 'TestGameBaseReelConfig'
    local reel_weight_config = CommonCal.Calculate.get_config(player, "TestGameBaseReelWeightConfig")
    if is_free_spin then
        reel_file = 'TestGameFeatureReelConfig'
        reel_weight_config = CommonCal.Calculate.get_config(player, "TestGameFeatureReelWeightConfig")
    end
    return reel_config, reel_weight_config
end

local function InitSaveData(player, player_game_info, game_room_config)
    local save_data = player_game_info.save_data
    if save_data.round_time == nil then
        save_data.round_time = 0
    end

    if save_data.wild_result == nil then
        save_data.wild_result = {}
        for i=1,4 do
            save_data.wild_result[i] = {}
            for j=1,5 do
                save_data.wild_result[i][j] = 0
            end
        end
    end
end

local function SaveWildResult(game_room_config, result_row, type, save_data)
    local wild_pos_list = SlotsGameCal.Calculate.GetItemPosition(result_row,game_room_config,type.Wild)

    if #wild_pos_list > 0 then
        for k,v in ipairs(wild_pos_list) do
            save_data.wild_result[v.row][v.col] = type.Wild
        end
    end
end

local function ChangeToWildResult(result_row, type, save_data)
    for i=1,4 do
        for j=1,5 do
            if save_data.wild_result[i][j] == type.Wild then
                result_row[i][j] = type.Wild
                save_data.wild_result[i][j] = 0
            end
        end
    end
    return result_row
end

function SlotsTestGameSpin:NormalSpin()
    --基本参数
    local player = self.parameters.player
    local player_game_info = self.parameters.player_game_info
    local special_parameter = self.parameters.special_parameter
    local is_free_spin = self.parameters.is_free_spin
    local game_room_config = self.parameters.game_room_config
    local player_game_status = self.parameters.player_game_status
    local amount = self.parameters.amount
    local game_type = self.parameters.game_type
    local player_feature_condition = self.parameters.player_feature_condition
    local extern_param = self.parameters.extern_param

    --一些需要存储的数据初始化（根据不同情况可放在进房间时初始化）
    local save_data = player_game_info.save_data
    InitSaveData(player, player_game_info, game_room_config)

    --对应GameConst里的玩法元素ID的Types
    local type = _G[game_room_config.game_name.."TypeArray"].Types
    --获取对应转动轴配置
    local reel_file, reel_weight_config = GetReelConfig(player, game_room_config, is_free_spin)
    --转动滚筒,获取结果
    --权重轴取结果
    --local origin_result, reel_file_name = SlotsGameCal.Calculate.GenItemResultWithWeight(player, game_type, is_free_spin, game_room_config, reel_file, reel_weight_config)
    --正常轴取结果
    local origin_result, reel_file_name = SlotsGameCal.Calculate.GenItemResult(player, game_type, is_free_spin, game_room_config, reel_file)

    --如有SuperStack替换逻辑
    --...
    --SuperStack替换

    --行为记录
    local pre_action_list = {}
    local final_result = table.DeepCopy(origin_result)

    --特殊逻辑
    save_data.round_time = save_data.round_time + 1
    SaveWildResult(game_room_config, final_result, type, save_data)
    if save_data.round_time == 10 then
        ChangeToWildResult(final_result, type, save_data)
        save_data.round_time = 0
    end

    --赔率配置
    local payrate_file = CommonCal.Calculate.get_config(player, game_room_config.game_name.."PayrateConfig")
    --连线规则, 1左连线，2右, 3左右连线
    local left_or_right = game_room_config.direction_type

    --获得连线结果
    local prize_items, total_payrate = SlotsGameCal.Calculate.GenPrizeInfo(final_result, game_room_config, payrate_file, left_or_right, type)
    --将连线结果放入all_prize_list
    local all_prize_list = {}
    table.insert(all_prize_list,prize_items)

    --slots赢取的筹码 = 倍率和 * 筹码
    local slots_win_chip = total_payrate * amount
    
    --赢取的总筹码,slots筹码+游戏等特殊筹码
    local total_win_chip = slots_win_chip

    --FreeSpin判断处理
    local free_spin_bouts =  SlotsGameCal.Calculate.FreeSpinCheck(player, final_result, game_room_config, is_free_spin, type.Scatter)

    --最后一次数据记录
    local slots_spin_list = {}
    table.insert(slots_spin_list, {
        item_ids = json.encode(SlotsGameCal.Calculate.TransResultToCList(origin_result, game_room_config)),
        prize_items = prize_items,
        win_chip = total_win_chip,
        pre_action_list = json.encode(pre_action_list),
        final_item_ids = json.encode(SlotsGameCal.Calculate.TransResultToCList(final_result, game_room_config)),     
    })
    --客户端接收的表
    local formation_list={}
    table.insert(formation_list, {
        slots_spin_list=slots_spin_list,
        id = 1,
    })

    local result = {}
    result.final_result = final_result --转动结果数组
    result.total_win_chip = total_win_chip  --总奖金
    result.all_prize_list = all_prize_list --所有连线列表
    result.free_spin_bouts = free_spin_bouts --freespin的次数
    result.formation_list = formation_list --阵型列表
    result.reel_file_name = reel_file_name --reel表名
    result.slots_win_chip = slots_win_chip --连线奖励
    result.special_parameter = special_parameter --其他参数，主要给模拟器传参
    return result
end