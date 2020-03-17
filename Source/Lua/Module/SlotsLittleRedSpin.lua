require "Common/SlotsGameCalculate"     --重写的接口
require "Common/SlotsGameCal"           --旧的接口
module("SlotsLittleRedSpin", package.seeall)

--入口
Enter = function(task, player, game_room_config, player_game_info)
    local bonus_info = {}
    if (player_game_info.bonus_game_type > 0) then
        bonus_info.bonus_game = true
    end
    return bonus_info
end

IsBonusGame = function(game_room_config, player, player_game_info)
	if (player_game_info.bonus_game_type > 0) then
        return true
    end
    return false
end

local function WalkingWildFeature(player, pre_action_list, game_room_config, amount, result_row, type, player_game_info)
	-- body
	local origin_result = table.DeepCopy(result_row)
	local save_data = player_game_info.save_data
    local walking_wild_pos_list = save_data.walking_wild_pos_list or {}
	if(#walking_wild_pos_list > 0 and amount <= player_game_info.bet_amount) then
		for k, v in ipairs(walking_wild_pos_list) do
			if(v.col > 1) then 
				result_row[v.row][v.col - 1] = type.Wild
			end
		end
    end
    walking_wild_pos_list = SlotsGameCal.Calculate.GetItemPosition(result_row,game_room_config,type.Wild)
    if(#walking_wild_pos_list > 0) then
        local pre_action = {}
        pre_action.action_type = ActionType.ActionTypes.HorizontalShift
        pre_action.source_pos = json.encode(SlotsGameCal.Calculate.TransResultToCList(origin_result, game_room_config))
        pre_action.des_pos = json.encode(SlotsGameCal.Calculate.TransResultToCList(result_row, game_room_config))
        pre_action.item_id = type.Wild
        pre_action.parameter_list = walking_wild_pos_list
        --LOG(RUN, INFO).Format("[LittleRed][WalkingWildFeature] pre_action.parameter_list[%s]",Table2Str(pre_action.parameter_list))
        table.insert(pre_action_list, pre_action)
    end
    --把walking_wild_pos_list存下来
    save_data.walking_wild_pos_list = walking_wild_pos_list

    return result_row, pre_action_list
end
-----------------------------------------------
-- 点击Spin
------------------------------------------------
local SpinProcess = function(player, game_type, is_free_spin, game_room_config, amount, player_feature_condition, extern_param, player_game_info)
    --对应GameConst里的TheSlotFatherTypeArray.Types
    local type = _G[game_room_config.game_name.."TypeArray"].Types
    player_game_info.bonus_game_type = 0  
    --转动滚筒,获取结果
    local origin_result, reel_file_name = SlotsGameCal.Calculate.GenItemResult(player, game_type, is_free_spin, game_room_config)
    --行为记录
    local pre_action_list = {}
    local final_result = table.DeepCopy(origin_result)
    --特殊逻辑   

    --WalkingWildFeature
    final_result, pre_action_list = WalkingWildFeature(player, pre_action_list, game_room_config, amount, final_result, type, player_game_info)

    --获得出现的bonus的个数
    local bonus_count = #SlotsGameCal.Calculate.GetItemPosition(origin_result, game_room_config, type.Bonus)
    
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
    local free_spin_bouts = SlotsGameCal.Calculate.GenFreeSpinCount(origin_result, game_room_config, type.Scatter, 10)

    if(bonus_count >= 3) then
    	local pre_action = {}
    	pre_action.action_type = ActionType.ActionTypes.EnterBonus
    	table.insert(pre_action_list, pre_action)
	player_game_info.bonus_game_type = 1
    end

    --最后一次数据记录
    local slots_spin_list = {}
    table.insert(slots_spin_list, {
        item_ids = json.encode(SlotsGameCal.Calculate.TransResultToCList(origin_result, game_room_config)),
        prize_items = prize_items,
        win_chip = total_win_chip,
        slots_win_chip = slots_win_chip,
        pre_action_list = json.encode(pre_action_list),
        final_item_ids = json.encode(SlotsGameCal.Calculate.TransResultToCList(final_result, game_room_config)),     
    })
    --客户端接收的表
    local formation_list={}
    table.insert(formation_list, {
        slots_spin_list=slots_spin_list,
        id = 1,
    })
    --服务器客户端通讯数据参数列表game_server\Server\Source\Idl\Protobuf
    --参数解释V1.1，新玩法请直接复制，不要改名字，不然对不上了。。。。
    --     ↓结果数组↓↓    ↓↓↓↓总奖金↓↓↓↓  ↓↓所有连线列表↓  ↓freespin的次数↓ ↓客户端接收的列表↓ ↓↓↓reel表名↓↓↓  ↓↓↓转动奖金↓↓↓
    return final_result, total_win_chip, all_prize_list, free_spin_bouts, formation_list, reel_file_name, slots_win_chip
 end

Spin = function(player, game_type, is_free_spin, game_room_config, amount, player_feature_condition, extern_param, player_game_info)
    return SpinProcess(player, game_type, is_free_spin, game_room_config, amount, player_feature_condition, extern_param, player_game_info)
end

-----------------------------------------------
-- Bonus Game
-----------------------------------------------
LittleRedBonusStart = function (task, player, game_room_config, parameter, player_game_info)
	local content = {}
    
	local amount = player_game_info.bet_amount * 30 --进Bonus时下注的金额
    --LOG(RUN, INFO).Format("[LittleRed][BonusGame] amount %d", amount)
	local bonus_config = CommonCal.Calculate.get_config(player, game_room_config.game_name.."BonusConfig")

    local before_game_amount = amount

    for i = 1, #bonus_config do 
        local winning_probability = bonus_config[i].winning_probability
        local bonus_result = math.rand_prob(player, winning_probability) --玩家的选择是否正确的结果
        if (i == 9) then 
            bonus_result = false
        end
        local bonus_win_amount = 0
        local bonus_amount_change = 0

        if bonus_result then
            --选对的结算
            bonus_win_amount = amount * bonus_config[i].winning_bonus
            bonus_amount_change = bonus_win_amount - before_game_amount
        else
            --选错的结算
            bonus_win_amount = amount * bonus_config[i].losing_bonus
            bonus_amount_change = bonus_win_amount - before_game_amount
        end

        before_game_amount = bonus_win_amount
        local result = {}
        result.bonus_result = bonus_result
        result.bonus_win_amount = bonus_win_amount
        result.bonus_amount_change = bonus_amount_change
        table.insert(content,result)
    end
    --LOG(RUN, INFO).Format("[LittleRed][LittleRedBonusStart] content[%s]",Table2Str(content))    
    return content
end

LittleRedBonusFinish = function (task, player, game_room_config, parameter, player_game_info, game_type, session)
    local content = {}

	player_game_info.bonus_game_type = 0

    local param = json.decode(parameter)

    content.win_chip = param.win_chip

    FeverQuestCal.OnMiniGameEnd(session, game_type, content.win_chip)

    return content
end