require"Common/SlotsGameCalculate" -- 重写的接口
require"Common/SlotsGameCal" -- 旧的接口
require"Common/LineNum"

local PickPrizeType = {
    Bonus = 1,
    BonusAddPick = 2,
    Multiple = 3
}

SlotsHoneyFortuneSpin = {}

local Types = _G["HoneyFortuneTypeArray"].Types

local function UpdateBaseBet(is_free_spin, save_data, total_amount)
    save_data.base_spin_count = save_data.base_spin_count or 0
    save_data.base_spin_value = save_data.base_spin_value or 0

    if not is_free_spin then
        save_data.base_spin_count = save_data.base_spin_count + 1
        save_data.base_spin_value = save_data.base_spin_value + total_amount
    end
end

local function GenerateHoneyHoles()
    local v = {}
    for i=1, 5 do
        v[i] = {}
        for j=1, 5 do
            v[i][j] = 1
        end
    end
    v[4][1] = 0
    v[5][1] = 0
    v[5][2] = 0
    v[4][5] = 0
    v[5][5] = 0
    v[5][4] = 0
    return v
end

local function CheckHoneyHoles(save_data)
    if not save_data.honey_holes then
        save_data.honey_holes = GenerateHoneyHoles()
    end

    -- 当前收集的等级
    save_data.collect_level = save_data.collect_level or 1
    save_data.collect_chip = save_data.collect_chip or 0
end

local function CalcCollectPositions(save_data)
    local v = GenerateHoneyHoles()
    local s = {}
    for i=1, 5 do
        for j=1, 5 do
            if v[i][j] == 1 and save_data.honey_holes[i][j] == 0 then
                table.insert(s, {pos = {i, j}})
            end
        end
    end
    return s
end

local function AddNewHole(pre_action_list, new_collect_pos, collect_chip)
    table.insert(pre_action_list, {
        action_type = ActionType.ActionTypes.CollectItem,
        total_chip = collect_chip,
        collect_honey_info_arr = new_collect_pos
    })
end

local function OnCollectFinished(pre_action_list, save_data)
    -- 重置蜂蜜的数据
    save_data.honey_holes = GenerateHoneyHoles()
    -- 重置数值
    save_data.base_spin_count = 0
    save_data.base_spin_value = 0
    -- 进入bonus小游戏
    table.insert(
        pre_action_list,
        {
            action_type = ActionType.ActionTypes.EnterBonus
        }
    )
    save_data.is_bonus_game = true

    -- 更新罐子等级action
    table.insert(
        pre_action_list,
        {
            action_type = ActionType.ActionTypes.HoneyUpdateLevel,
            level = save_data.collect_level % 3 + 1
        }
    )
end

local function CheckCollectFinished(pre_action_list, save_data)
    -- 检查是否收集完成
    local is_finished = true
    for i=1, 5 do
        for j=1, 5 do
            if save_data.honey_holes[i][j] == 1 then
                is_finished = false
                break
            end
        end
    end

    if is_finished then
        OnCollectFinished(pre_action_list, save_data)
    end
end

local function GetPotRatio(player, level)
    local config = CommonCal.Calculate.get_config(player, "HoneyFortunePotRatioConfig")
    return config[level].Base_Pot_ratio
end

local function UpdateHoneyHoles(player, prize_items, save_data, pre_action_list, jackpot_pos)
    local new_collect_pos = {}
    local holes = save_data.honey_holes
    local pot_ratio = GetPotRatio(player, save_data.collect_level)

    local virtual_prize_items = table.DeepCopy(prize_items)

    if jackpot_pos then
        -- 将jackpot的位置加入到prize_items中
        local item = {
            item_pos_arr = jackpot_pos
        }
        table.insert(virtual_prize_items, item)
    end

    for i=1, #virtual_prize_items do
        local positions = virtual_prize_items[i].item_pos_arr

        for j=1, #positions do
            local row = positions[j].row
            local col = positions[j].col

            if save_data.honey_holes[row][col] == 1 then
                save_data.honey_holes[row][col] = 0
                table.insert(new_collect_pos, {pos = {row, col}})
                -- 增加价值
                local count = save_data.base_spin_count
                if count == 0 then count = 1 end
                local average_bet_amount = save_data.base_spin_value/count
                save_data.collect_chip = save_data.collect_chip + average_bet_amount * pot_ratio * 1
            end
        end
    end

    if #new_collect_pos > 0 then
        save_data.collect_chip = math.floor(save_data.collect_chip/1000.0)*1000
        AddNewHole(pre_action_list, new_collect_pos, save_data.collect_chip)
        CheckCollectFinished(pre_action_list, save_data)
    end
end

-- 随机jackpot值
local function WinJackpot(player, save_data, total_amount, pre_action_list)
    local weights = {}
    local config = CommonCal.Calculate.get_config(player, "HoneyFortuneJackpotConfig")

    local jackpot_param_v2 = save_data.jackpot_param_v2

    local type = 1
    local add_value = CommonCal.Calculate.GetJackpotPoolChipVal(jackpot_param_v2, type, total_amount) -- 获取jackpot金额
    CommonCal.Calculate.ResetJackpotExtraChip(jackpot_param_v2, type) -- 重置jackpot中的金额

    table.insert(pre_action_list, {
        action_type = ActionType.ActionTypes.WinGameJackpot,
        chip = add_value
    })

    return add_value
end

local function CheckJackpot(player, save_data, total_amount, final_result, pre_action_list, special_parameter)
    local jackpot_count = 0
    local pos = {}
    for i=1, #final_result do
        local r = final_result[i]
        for k, v in pairs(r) do
            if v == Types.Jackpot then
                jackpot_count = jackpot_count + 1
                table.insert(pos, {row=i, col=k})
            end
        end
    end

    if jackpot_count >= 5 then
        local win_chip = WinJackpot(player, save_data, total_amount, pre_action_list)
        special_parameter.jackpot_win_chip = win_chip
        return win_chip, pos
    end
end

-- 入口
function SlotsHoneyFortuneSpin:Enter()
    local task = self.parameters.task
    local player = self.parameters.player
    local game_room_config = self.parameters.game_room_config
    local player_game_info = self.parameters.player_game_info
    local session = self.parameters.session
    local player_game_status = self.parameters.player_game_status
    local save_data = player_game_info.save_data

    CheckHoneyHoles(save_data)

    local bonus_info = {
        in_bonus_game = save_data.is_bonus_game,
        wild_value = save_data.wild_value
    }

    -- jackpot初始化
    if not save_data.jackpot_param_v2 then
        save_data.jackpot_param_v2 = {}
        local config = CommonCal.Calculate.get_config(player, "HoneyFortuneJackpotConfig")
        CommonCal.Calculate.InitJackpotParam(save_data.jackpot_param_v2, config)
    end

    bonus_info.jackpot_param = CommonCal.Calculate.GetJakcpotParamToClient(save_data.jackpot_param_v2)

    bonus_info.collect_info = {
        total_chip = save_data.collect_chip,
        level = save_data.collect_level,
        collect_honey_info_arr = CalcCollectPositions(save_data)
    }

    return bonus_info
end

IsBonusGame = function(game_room_config, player, player_game_info)
    return false
end

-- 随机wild的初始价值
local function RandInitWildValue(player)
    local configs = CommonCal.Calculate.get_config(player, "HoneyFortuneWildInitialConfig")
    local weights = {}
    for i=1, #configs do
        table.insert(weights, configs[i].WildWeight)
    end
    return configs[math.rand_weight(player, weights)].WildInitial
end

local function GetItemCount(origin_result, type)
    local count = 0
    local pos = {}
    for i = 1, 5 do
        for j = 1, 5 do
            if origin_result[i][j] == type then
                count = count + 1
                table.insert(pos, {row=i, col=j})
            end
        end
    end
    return count, pos
end

local function GetWildIncrease(player)
    local configs = CommonCal.Calculate.get_config(player, "HoneyFortuneWildIncreaseConfig")

    local weights = {}

    for i=1, #configs do
        table.insert(weights, configs[i].WildWeight)
    end

    return configs[math.rand_weight(player, weights)].WildIncrease
end

function SlotsHoneyFortuneSpin:NormalSpin()
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

    local session = self.parameters.extern_param.session

    local save_data = player_game_info.save_data

    local lineNum = LineNum[player_game_info.game_type]()
    local total_amount = lineNum * amount

    if not is_free_spin then
        UpdateBaseBet(is_free_spin, save_data, total_amount)
    end

    local type = _G[game_room_config.game_name .. "TypeArray"].Types
    player_game_info.bonus_game_type = 0

    local config_table = SlotsGameCal.Calculate.GetMapConfigTable(session, game_room_config, player_game_info, amount * lineNum)
    local reel_file = nil
    local weight_file = nil

    if is_free_spin then
        reel_file = config_table.feature_reel_config
        weight_file = config_table.feature_reel_weight_config
    else
        reel_file = config_table.base_reel_config
        weight_file = config_table.base_reel_weight_config
    end

    local origin_result, reel_file_name = SlotsGameCal.Calculate.GenItemResultWithWeight(player, game_type, is_free_spin, 
        game_room_config, reel_file, weight_file)

    -- 行为记录
    local pre_action_list = {}
    local final_result = table.DeepCopy(origin_result)

    -- 赔率配置
    local payrate_file = CommonCal.Calculate.get_config(player, game_room_config.game_name .. "PayrateConfig")
    -- 连线规则, 1左连线，2右, 3左右连线
    local left_or_right = game_room_config.direction_type

    -- 获得连线结果
    local options = {
        spin_type = is_free_spin and 2 or 1
    }

    local prize_items, total_payrate = SlotsGameCal.Calculate.GenPrizeItems(player, final_result, game_room_config, payrate_file, 
        left_or_right, type, options)

    -- slots赢取的筹码 = 倍率和 * 筹码
    local slots_win_chip = total_payrate * amount
    -- 赢取的总筹码,slots筹码+游戏等特殊筹码
    local total_win_chip = slots_win_chip

    local jackpot_win_chip, jackpot_pos = CheckJackpot(player, save_data, total_amount, final_result, pre_action_list, special_parameter)
    if jackpot_win_chip and jackpot_win_chip > 0 then
        slots_win_chip = slots_win_chip + jackpot_win_chip
        total_win_chip = total_win_chip + jackpot_win_chip
    end

    -- 更新jackpot
    CommonCal.Calculate.UpdateJackpotExtraChip(is_free_spin, "HoneyFortuneJackpotConfig", save_data, total_amount, pre_action_list)

    -- 查找是否中奖蜂蜜
    if #prize_items > 0 and not is_free_spin then
        UpdateHoneyHoles(player, prize_items, save_data, pre_action_list, jackpot_pos)
    end

    -- 将连线结果放入all_prize_list
    local all_prize_list = {}
    table.insert(all_prize_list, prize_items)

    -- FreeSpin判断处理
    local free_spin_bouts = SlotsGameCal.Calculate.FreeSpinCheck(player, final_result, game_room_config, is_free_spin, type.Scatter)

    -- 最后一次数据记录
    local slots_spin_list = {}

    local free_spin_bouts_left = GameStatusCal.Calculate.GetFreeSpinBouts(player_game_status)

    -- 处理最后发送总值总次数
    if is_free_spin then
        save_data.total_free_spin_times = save_data.total_free_spin_times or 0
        save_data.total_free_spin_times = save_data.total_free_spin_times + 1
    else
        save_data.total_free_spin_times = nil
    end

    if is_free_spin and free_spin_bouts > 0 then
        player_game_info.free_spin_num = free_spin_bouts
    end

    if free_spin_bouts > 0 then
        GameStatusCal.Calculate.AddGameStatus(player_game_status, GameStatusDefine.AllTypes.FreeSpinGame, free_spin_bouts, 1, amount)
    end

    local scatter_count = GetItemCount(origin_result, Types.Scatter)
    local wild_count, wild_pos = GetItemCount(origin_result, Types.WildFreeSpin)

    -- 第一次
    if not is_free_spin and free_spin_bouts > 0 then
        -- 初始化wild值
        save_data.wild_value = RandInitWildValue(player) * total_amount
        table.insert(pre_action_list, {
            action_type = ActionType.ActionTypes.HoneyInitWildValue,
            wild_value = save_data.wild_value
        })
        -- 记录次数
        special_parameter.scatter_count = scatter_count
    end
    
    if is_free_spin and wild_count > 0 then
        -- 每一个wild增加chip
        local win_chip = wild_count * save_data.wild_value
        slots_win_chip = slots_win_chip + win_chip
        total_win_chip = slots_win_chip

        local item = {
            line_index = 0,
            item_pos_arr = wild_pos
        }
        table.insert(prize_items, item)

        save_data.wild_win_chip = save_data.wild_win_chip or 0
        save_data.wild_win_chip = save_data.wild_win_chip + win_chip
    end
    
    if scatter_count >= 2 and is_free_spin then
        -- 增加wild的值
        save_data.wild_value = save_data.wild_value + GetWildIncrease(player)  * total_amount
        table.insert(pre_action_list, {
            action_type = ActionType.ActionTypes.HoneyUpdateWildValue,
            wild_value = save_data.wild_value
        })
    end

    -- 最后一次
    if is_free_spin and free_spin_bouts_left == 0 and free_spin_bouts == 0 then
        player_game_info.free_total_win = player_game_info.free_total_win or 0
        save_data.wild_value = nil
    end

    if is_free_spin and free_spin_bouts > 0 then
        table.insert(pre_action_list, {
                action_type = ActionType.ActionTypes.FreeSpinTimesAdd,
                free_spin_bouts = free_spin_bouts
            }
        )
    end

    table.insert(slots_spin_list, {
        item_ids = json.encode(SlotsGameCal.Calculate.TransResultToCList(origin_result, game_room_config)),
        prize_items = prize_items,
        win_chip = total_win_chip,
        slots_win_chip = slots_win_chip,
        pre_action_list = json.encode(pre_action_list),
        final_item_ids = json.encode(SlotsGameCal.Calculate.TransResultToCList(final_result, game_room_config)),
        ways_type = 2, -- 新的way type
    })

    -- 客户端接收的表
    local formation_list = {}
    table.insert(formation_list, {
        slots_spin_list = slots_spin_list,
        id = 1
    })

    local result = {}
    result.final_result = final_result --结果数组
    result.total_win_chip = total_win_chip  --总奖金
    result.all_prize_list = all_prize_list --所有连线列表
    result.free_spin_bouts = free_spin_bouts --freespin的次数
    result.formation_list = formation_list --阵型列表
    result.reel_file_name = reel_file_name --reel表名
    result.slots_win_chip = slots_win_chip --总奖励
    result.special_parameter = special_parameter --其他参数，主要给模拟器传参
    return result
end

local function RandFakeValue(player)
    local config = CommonCal.Calculate.get_config(player, "HoneyFortuneBonusConfig")
    local weights = {}

    for i=1, #config do
        table.insert(weights, config[i].PickWeight)
    end

    local index = math.rand_weight(player, weights)
    return config[index]
end

local function RandBonusAddPickValue(player)
    local config = CommonCal.Calculate.get_config(player, "HoneyFortuneBonusConfig")
    local weights = {}
    local configs = {}

    for i=1, #config do
        if config[i].Pickagain == 1 then
            table.insert(weights, config[i].PickWeight)
            table.insert(configs, config[i])
        end
    end

    local index = math.rand_weight(player, weights)
    return configs[index].Bonus
end

local function RandBonusValue(player)
    local config = CommonCal.Calculate.get_config(player, "HoneyFortuneBonusConfig")
    local weights = {}
    local configs = {}
    for i=1, #config do
        if config[i].Pickagain == 0 then
            table.insert(weights, config[i].PickWeight)
            table.insert(configs, config[i])
        end
    end
    local index = math.rand_weight(player, weights)
    return configs[index].Bonus
end

local function shuffle(tbl, start)
    for i = #tbl, start, -1 do
        local j = math.random(start, #tbl)
        tbl[i], tbl[j] = tbl[j], tbl[i]
    end
    return tbl
end

local function RandPicks(player, save_data)
    local config = CommonCal.Calculate.get_config(player, "HoneyFortunePickTimeConfig")
    local weights = {}
    for i=1, #config do
        table.insert(weights, config[i].Normal_Weight)
    end
    local count = config[math.rand_weight(player, weights)].Pick_Time

    -- 随机最后一次是否中多倍
    local config = CommonCal.Calculate.get_config(player, "HoneyFortuneMultipleConfig")
    local weights = {}
    for i=1, #config do
        table.insert(weights, config[i].Normal_Weight)
    end
    local multi_value = config[math.rand_weight(player, weights)].Multiple
    local normal_count = count

    if multi_value > 0 then
        normal_count = normal_count - 1
    end

    -- 随机插板子
    local add_pick_count = normal_count - 3
    local pos = {}
    if add_pick_count > 0 then
        for i=1, add_pick_count do
            local type = math.random_ext(player, 1, 3)
            pos[type] = pos[type] or 0
            pos[type] = pos[type] + 1
        end
    end

    local picks = {}

    local switch_id = math.random_ext(player, 1, 3)

    for i=1, 3 do
        if pos[i] and pos[i] > 0 then
            for j=1, pos[i] do
                table.insert(picks, 2)
            end
        end
        if multi_value > 0 and i == switch_id then
            -- 特殊处理总数只有3次且multi_value>0的情况
            if count > 3 then
                table.insert(picks, 2)
            end
        else
            table.insert(picks, 1)
        end
    end

    -- 随机奖励
    local prizes = {}
    for i=1, #picks do
        if picks[i] == 2 then
            table.insert(prizes, {
                prize_type = PickPrizeType.BonusAddPick,
                prize_val = RandBonusAddPickValue(player) * save_data.collect_chip
            })
        elseif picks[i] == 1 then
            table.insert(prizes, {
                prize_type = PickPrizeType.Bonus,
                prize_val = RandBonusValue(player) * save_data.collect_chip
            })
        end
    end

    if multi_value > 0 then
        table.insert(prizes, {
            prize_type = PickPrizeType.Multiple,
            prize_val = multi_value
        })
    end

    -- 随机剩余的几个位置
    local mul = {}
    if multi_value == 2 then
        mul = {3}
    elseif multi_value == 3 then
        mul = {2}
    else
        mul = {2, 3}
    end

    for i=1, #mul do
        table.insert(prizes, {
            prize_type = PickPrizeType.Multiple,
            prize_val = mul[i]
        })
    end
    
    for i=1, (12 - count - #mul) do
        local config = RandFakeValue(player)
        if config.Pickagain == 1 then
            table.insert(prizes, {
                prize_type = PickPrizeType.BonusAddPick,
                prize_val = config.Bonus * save_data.collect_chip,
            })
        else
            table.insert(prizes, {
                prize_type = PickPrizeType.Bonus,
                prize_val = config.Bonus * save_data.collect_chip,
            })
        end
    end

    shuffle(prizes, count+1)

    return prizes, count
end

function SlotsHoneyFortuneSpin:BonusStart()
    local player_game_status = self.parameters.player_game_status
    local player = self.parameters.player
    local game_room_config = self.parameters.game_room_config
    local parameter = self.parameters.parameter
    local player_game_info = self.parameters.player_game_info
    local game_type = self.parameters.game_type
    local save_data = player_game_info.save_data

    if save_data.collect_chip <= 0 then
        return
    end

    if not save_data.bonus_info then
        save_data.bonus_info = {}
        save_data.bonus_info.pick_history = {}
        save_data.bonus_info.base_chip = save_data.collect_chip
        -- 随机出12个
        local prizes, count = RandPicks(player, save_data)
        save_data.bonus_info.prizes = prizes
        save_data.bonus_info.max_pick_count = count
    end

    -- 开始翻箱子
    local content = {
        level = save_data.collect_level,
        base_chip = save_data.bonus_info.base_chip,
        max_pick_count = save_data.bonus_info.max_pick_count,
        pick_history = save_data.bonus_info.pick_history,
        pick_prize_pool = save_data.bonus_info.prizes
    }

    return content
end

function SlotsHoneyFortuneSpin:BonusPick()
    local player_game_status = self.parameters.player_game_status
    local player = self.parameters.player
    local game_room_config = self.parameters.game_room_config
    local parameter = self.parameters.parameter
    local player_game_info = self.parameters.player_game_info
    local game_type = self.parameters.game_type
    local save_data = player_game_info.save_data
    local parameter = json.decode(parameter)

    if not save_data.bonus_info then
        return
    end

    local is_picked = false
    for i=1, #save_data.bonus_info.pick_history do
        if save_data.bonus_info.pick_history[i] == parameter.pick_pos then
            is_picked = true
            LOG(RUN, INFO).Format("[SlotsHoneyFortuneSpin][HoneyFortuneBonusPick] player %s duplicate pick position %s",
                player.id, parameter.pick_pos)
            break
        end
    end

    if not is_picked then
        table.insert(save_data.bonus_info.pick_history, parameter.pick_pos)
    end

    local content = {
        base_chip = save_data.bonus_info.base_chip,
        max_pick_count = save_data.bonus_info.max_pick_count,
        pick_history = save_data.bonus_info.pick_history,
        pick_prize_pool = save_data.bonus_info.prizes
    }

    return content
end

function SlotsHoneyFortuneSpin:BonusFinish()
    local player_game_status = self.parameters.player_game_status
    local player = self.parameters.player
    local game_room_config = self.parameters.game_room_config
    local parameter = self.parameters.parameter
    local player_game_info = self.parameters.player_game_info
    local game_type = self.parameters.game_type
    local save_data = player_game_info.save_data
    local session = self.parameters.session

    if not save_data.bonus_info then
        return
    end

    -- 开始结算，加chip
    local win_chip = 1.0 * save_data.collect_chip
    for i=1, save_data.bonus_info.max_pick_count do
        local prize = save_data.bonus_info.prizes[i]

        if prize.prize_type == PickPrizeType.Bonus then
            win_chip = win_chip + prize.prize_val
        elseif prize.prize_type == PickPrizeType.BonusAddPick then
            win_chip = win_chip + prize.prize_val
        else
            win_chip = win_chip * prize.prize_val
        end
    end

    win_chip = math.floor(win_chip)

    -- 罐子变大
    save_data.collect_level = save_data.collect_level % 3 + 1
    -- 清数据
    save_data.bonus_info = nil
    save_data.collect_chip = 0
    save_data.is_bonus_game = false

    local content = {
        win_chip = win_chip,
        bet_amount = player_game_info.bet_amount
    }

    FeverQuestCal.OnMiniGameEnd(session, game_type, win_chip)

    return content
end


