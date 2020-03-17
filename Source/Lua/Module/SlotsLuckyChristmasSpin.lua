require"Common/SlotsGameCalculate" -- 重写的接口
require"Common/SlotsGameCal" -- 旧的接口
require"Common/LineNum"

SlotsLuckyChristmasSpin = {}

local Types = _G["LuckyChristmasTypeArray"].Types

local ENUM = {
    --Bonus类型
    BONUS_TYPE = {
        PICK = 1, --捡取的Bonus
        SPIN_SELECT = 2 --选择Spin类型的Bonus
    },
    --星星类型
    STAR_TYPE = {
        COPPER = 1, --铜
        SILVER = 2, --银
        GOLD = 3, --金
        COLOUR = 4 --彩色
    },
    --Jackpot类型
    JACKPOT_TYPE = {
        MEGA = 1,
        GRAND = 2,
        MAJOR = 3,
        MINOR = 4,
        MINI = 5
    }
}

local star_items = {}
star_items[Types.CopperStar] = ENUM.STAR_TYPE.COPPER
star_items[Types.SilverStar] = ENUM.STAR_TYPE.SILVER
star_items[Types.SilverWildStar] = ENUM.STAR_TYPE.SILVER
star_items[Types.GoldStar] = ENUM.STAR_TYPE.GOLD
star_items[Types.ColourStar] = ENUM.STAR_TYPE.COLOUR

local PickPrizeType = {
    Bonus = 1,
    BonusAddPick = 2,
    Multiple = 3
}

local function GetStarType(item)
    return star_items[item]
end

function GetConfigTableConfig(session, game_room_config, player_game_info, config_name)
    local lineNum = LineNum[game_room_config.game_type]()
    local total_amount = (player_game_info.bet_amount or 0) * lineNum
    local config_table = SlotsGameCal.Calculate.GetMapConfigTable(session, game_room_config, player_game_info, total_amount)
    local config = CommonCal.Calculate.get_config(player, config_table[config_name])
    return config
end

local function GenerateCopperStarValue(player)
    local configs = CommonCal.Calculate.get_config(player, "LuckyChristmasStarValueConfig")
    local config = math.rand_config(player, configs, "weight")
    return config.star_value
end

local function GenerateStarValue(player, star_type)
    if star_type == Types.CopperStar then
        return GenerateCopperStarValue(player)
    else
        return 0
    end
end

local function AddCopperStarValue(player, save_data, result, total_amount)
    local star_info_arr = {}
    for i=1, 3 do
        for j=1, 5 do
            local star_type = GetStarType(result[i][j])
            if star_type == ENUM.STAR_TYPE.COPPER then
                local item = {
                    pos =  {i, j},
                    data = {
                        star_type = star_type,
                        prize_type = 1,
                        jackpot_type = 0,
                        amount = GenerateStarValue(player, result[i][j])*total_amount,
                    }
                }
                table.insert(star_info_arr, item)
            end
        end
    end

    return star_info_arr
end

-- 随机jackpot值
local function WinJackpot(player, save_data, total_amount, pre_action_list)
    local weights = {}
    local config = CommonCal.Calculate.get_config(player, "LuckyChristmasJackpotConfig")

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

local function CheckIsBonusGame(save_data)
    local is_bonus_game = false
    if save_data.trigger_bonus_state_arr then
        for i=1, #save_data.trigger_bonus_state_arr do
            if save_data.trigger_bonus_state_arr[i] == true then
                is_bonus_game = true
            end
        end
    end

    return is_bonus_game
end

-- 入口
function SlotsLuckyChristmasSpin:Enter()
    local task = self.parameters.task
    local player = self.parameters.player
    local game_room_config = self.parameters.game_room_config
    local player_game_info = self.parameters.player_game_info
    local session = self.parameters.session
    local player_game_status = self.parameters.player_game_status
    local save_data = player_game_info.save_data

    local is_bonus_game = CheckIsBonusGame(save_data)

    local bonus_info = {
        in_bonus_game = is_bonus_game,
        trigger_bonus_state_arr = is_bonus_game and save_data.trigger_bonus_state_arr or nil,
        star_info_arr = save_data.star_info_arr
    }

    -- jackpot初始化
    if not save_data.jackpot_param_v2 then
        save_data.jackpot_param_v2 = {}
        local config = CommonCal.Calculate.get_config(player, "LuckyChristmasJackpotConfig")
        CommonCal.Calculate.InitJackpotParam(save_data.jackpot_param_v2, config)
    end

    bonus_info.jackpot_param = CommonCal.Calculate.GetJakcpotParamToClient(save_data.jackpot_param_v2)

    return bonus_info
end

IsBonusGame = function(game_room_config, player, player_game_info)
    return CheckIsBonusGame(player_game_info.save_data)
end

local function GetItemCount(origin_result, type)
    local count = 0
    local pos = {}
    for i = 1, 3 do
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
    local configs = CommonCal.Calculate.get_config(player, "LuckyChristmasWildIncreaseConfig")

    local weights = {}

    for i=1, #configs do
        table.insert(weights, configs[i].WildWeight)
    end

    return configs[math.rand_weight(player, weights)].WildIncrease
end

local function CheckEnterBonus(save_data, pre_action_list, origin_result, pick_jackpot)
    local copper_star_count, copper_star_pos = GetItemCount(origin_result, Types.CopperStar)

    local is_spin_select = copper_star_count >= 6

    if is_spin_select then
        save_data.copper_star_count = copper_star_count
        save_data.copper_star_pos = copper_star_pos
    end

    if is_spin_select or pick_jackpot then
        -- 进入bonus选择
        save_data.trigger_bonus_state_arr = {
            [ENUM.BONUS_TYPE.PICK] = pick_jackpot, --是否触发PickBonus
            [ENUM.BONUS_TYPE.SPIN_SELECT] = is_spin_select --是否触发选择Spin的Bonus
        }

        local count = 1
        if pick_jackpot and is_spin_select then
            count = 2
        end

        table.insert(
            pre_action_list,
            {
                action_type = ActionType.ActionTypes.EnterBonus,
                trigger_bonus_state_arr = save_data.trigger_bonus_state_arr,
                count = count
            }
        )
    end
end

local function RandBox(session, game_room_config, player_game_info, i, j, star_info_arr, save_data, player, total_amount, origin_result, final_result)
    local configs = GetConfigTableConfig(session, game_room_config, player_game_info, "box_config")
    local config = math.rand_config(player, configs, "Weight")

    if config.Box_Type >= 1 and config.Box_Type <= 5 then
        -- jackpot
        local jackpot_param_v2 = save_data.jackpot_param_v2
        local add_value = CommonCal.Calculate.GetJackpotPoolChipVal(jackpot_param_v2, config.Box_Type, total_amount)

        local item = {
            pos =  {i, j},
            data = {
                star_type = ENUM.STAR_TYPE.COLOUR,
                prize_type = 2,
                jackpot_type = config.Box_Type,
                amount = add_value,
            }
        }
        final_result[i][j] = Types.ColourStar
        table.insert(star_info_arr, item)
        return add_value
    end

    if config.Box_Type == 6 then
        -- silver star
        local star_type = GetStarType(origin_result[i][j])
        local item = {
            pos =  {i, j},
            data = {
                star_type = ENUM.STAR_TYPE.SILVER,
                prize_type = 1,
                jackpot_type = 0,
                amount = save_data.silver_star_val or 0,
            }
        }
        final_result[i][j] = Types.SilverWildStar
        table.insert(star_info_arr, item)
        return save_data.silver_star_val or 0
    end
end

local function AddFreeSpinSpecialStar(session, game_room_config, player_game_info, star_info_arr, save_data, player, total_amount, origin_result, final_result)
    local silver_star_val = GetSilverStarValue(save_data)
    -- 添加银星星的价值
    -- 添加彩色星星的价值
    local total_win_chip = 0

    for j=1, 5 do
        for i=1, 3 do
            if origin_result[i][j] == Types.Box then
                local win_chip = RandBox(session, game_room_config, player_game_info, i, j, star_info_arr, save_data, player, total_amount, origin_result, final_result)
                total_win_chip = total_win_chip + win_chip
            end
        end
    end

    return total_win_chip
end

function SlotsLuckyChristmasSpin:NormalSpin()
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

    save_data.total_amount = total_amount

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

    -- 添加星星价值
    local star_info_arr = AddCopperStarValue(player, save_data, origin_result, total_amount)
    local box_win_chip = 0

    if is_free_spin then
        box_win_chip = AddFreeSpinSpecialStar(session, game_room_config, player_game_info, star_info_arr, save_data, player, total_amount, origin_result, final_result)
    end

    table.insert(pre_action_list, {
            action_type = ActionType.ActionTypes.CoinInfoArr,
            star_info_arr = star_info_arr
        }
    )

    save_data.star_info_arr = star_info_arr

    local payrate_file = CommonCal.Calculate.get_config(player, game_room_config.game_name.."PayrateConfig")
    local other_file = GetConfigTableConfig(session, game_room_config, player_game_info, "others_config")

    local prize_items, pos_list, total_payrate, total_line_count = GenReelWayPrizeInfo(final_result, game_room_config,
        payrate_file, other_file[1].Base_Bet_Ratio, nil, true)

    local options = {
        spin_type = is_free_spin and 2 or 1
    }

    local new_prize_items = {}

    if #prize_items > 0 then
        new_prize_items = SlotsGameCal.Calculate.ConvertPrizeItems(player, final_result, game_room_config, payrate_file,
            left_or_right, type, options, prize_items)
    end

    -- slots赢取的筹码 = 倍率和 * 筹码
    local slots_win_chip = total_payrate * amount
    -- 赢取的总筹码,slots筹码+游戏等特殊筹码
    local total_win_chip = slots_win_chip + box_win_chip

    local jackpot_win_chip, jackpot_pos = CheckJackpot(player, save_data, total_amount, final_result, pre_action_list, special_parameter)
    if jackpot_win_chip and jackpot_win_chip > 0 then
        slots_win_chip = slots_win_chip + jackpot_win_chip
        total_win_chip = total_win_chip + jackpot_win_chip
    end

    -- 更新jackpot
    CommonCal.Calculate.UpdateJackpotExtraChip(is_free_spin, "LuckyChristmasJackpotConfig", save_data, total_amount, pre_action_list)

    -- 将连线结果放入all_prize_list
    local all_prize_list = {}
    table.insert(all_prize_list, prize_items)

    -- FreeSpin判断处理
    local free_spin_bouts = SlotsGameCal.Calculate.FreeSpinCheck(player, final_result, game_room_config, is_free_spin, type.Scatter)
    local pick_jackpot = false

    local other_config = GetConfigTableConfig(session, game_room_config, player_game_info, "others_config")[1]
    local wild_count = GetItemCount(origin_result, Types.Wild)

    if wild_count > 0 then
        if is_free_spin then
            pick_jackpot = math.rand_prob(player, other_config.Free_Wild_Bonus)
        else
            pick_jackpot = math.rand_prob(player, other_config.Base_Wild_Bonus)
        end
    end

    -- 星星图标是否有6个，是否中jackpot
    if not is_free_spin then
        CheckEnterBonus(save_data, pre_action_list, origin_result, pick_jackpot)
    end

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
        -- 记录次数
        special_parameter.scatter_count = scatter_count
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

    local reel_ways_info = {}
    reel_ways_info.pos_list = pos_list
    reel_ways_info.total_line_count = total_line_count

    table.insert(slots_spin_list, {
        item_ids = json.encode(SlotsGameCal.Calculate.TransResultToCList(origin_result, game_room_config)),
        prize_items = prize_items,
        win_chip = total_win_chip,
        slots_win_chip = slots_win_chip,
        pre_action_list = json.encode(pre_action_list),
        final_item_ids = json.encode(SlotsGameCal.Calculate.TransResultToCList(final_result, game_room_config)),
        reel_ways_info = json.encode(reel_ways_info),
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

-- 通过所有的铜星星计算银星星
function GetSilverStarValue(save_data)
    local total_value = 0
    for i=1, #save_data.star_info_arr do
        local v = save_data.star_info_arr[i]
        if v.data.star_type == ENUM.STAR_TYPE.COPPER then
            total_value = total_value + v.data.amount
        end
    end
    if total_value > 0 then
        save_data.silver_star_val = total_value
    end
    return save_data.silver_star_val
end

local ElementType = {
    Mini = 1,
    Minor = 2,
    Majar = 3,
    Grand = 4,
    Mega = 5,
    Wild = 6,
    Bump = 7,
}

local function RandElement(player, elements)
    local weights = {}
    for i=1, #elements do
        table.insert(weights, elements[i].weight)
    end
    local index = math.rand_weight(player, weights)
    return elements[index].index, index
end

local function IsContainValue(values, v)
    for i=1, #values do
        if values[i] == v then
            return true
        end
    end
    return false
end

local function IsLessThan3()

end

local function AddElementMoreThanOne(list, target_info, item)
    -- 处理有2个以上元素的情况
    if item == ElementType.Wild then
        for i=1, 5 do
            -- 其他元素不能超过2个
            if list[i] + 1 >= 2 and (not IsContainValue(target_info.values, i)) then
                return false
            end
        end
        for i=1, 5 do
            -- 目标元素不能超过3个
            if list[i] + 1 >= 4 and IsContainValue(target_info.values, i) then
                return false
            end
        end
        for i=1, 5 do
            list[i] = list[i] + 1
        end
        return true
    end

    if item == ElementType.Bump then
        if list[item] < target_info.bump_count then
            list[item] = list[item] + 1
            return true
        end
        return false
    end

    if IsContainValue(target_info.values, item) then
        if list[item] < 3 then
            list[item] = list[item] + 1
            return true
        end
        return false
    end

    local item_count = list[item] + 1
    if item_count > 2 then
        return false
    end

    list[item] = list[item] + 1
    return true
end

local function AddElement(list, target_info, item)
    if target_info.count > 1 then
        return AddElementMoreThanOne(list, target_info, item)
    end

    -- 处理只有1个元素的情况
    if item == ElementType.Wild then
        for i=1, 5 do
            if list[i] + 1 >= 4 and i ~= target_info.values[1] then
                return false
            end
        end
        for i=1, 5 do
            list[i] = list[i] + 1
        end
        return true
    end

    if item == ElementType.Bump then
        if list[item] < target_info.bump_count then
            list[item] = list[item] + 1
            return true
        end
        return false
    end

    if item == target_info.values[1] then
        list[item] = list[item] + 1
        return true
    end

    local item_count = list[item] + 1
    if item_count >= 4 then
        return false
    end

    list[item] = list[item] + 1
    return true
end

local function CheckFinishedMoreThan1(list, target_info)
    for i=1, #target_info.values do
        local index = target_info.values[i]
        if list[index] < 3 then
            return false
        end
    end

    -- 检查bump数量
    if list[ElementType.Bump] < target_info.bump_count then
        -- return false
        -- 将剩余的
    end

    -- 最后加上wild
    list[ElementType.Wild] = list[ElementType.Wild] + 1

    return true
end

local function CheckFinished(list, target_info)
    if target_info.count > 1 then
        return CheckFinishedMoreThan1(list, target_info)
    end

    local f = true
    for i=1, #target_info.values do
        local item = target_info.values[i]
        if list[item] < 4 then
            f = false
            break
        end
    end

    -- 检查bump数量
    if list[ElementType.Bump] < target_info.bump_count then
        -- f = false
    end

    return f
end

local function RandLeftJackpots(path)
    local counts = {
        6, 5, 5, 4, 3, 4, 3
    }
    for i=1, #path do
        local index = path[i]
        counts[index] = counts[index] - 1
    end
    local weights = {}
    for i=1, #counts do
        for j=1, counts[i] do
            table.insert(weights, {index=i, weight=1})
        end
    end

    for i=1, #weights do
        local config = math.rand_config(player, weights, "weight")
        table.insert(path, config.index)
        config.weight = 0
    end
end

local function GetRandElements()
    local counts = {
        6, 5, 5, 4, 3, 4, 3
    }
    local weights = {}
    for i=1, #counts do
        for j=1, counts[i] do
            table.insert(weights, {index = i, weight=1})
        end
    end
    return weights
end

local function GeneratePicks(path)
    local picks = {}
    for i=1, #path do
        table.insert(picks, {
            prize_type = path[i] <= 5 and 1 or (path[i]-4),
            prize_val = path[i] <= 5 and (6-path[i]) or 0
        })
    end
    return picks
end

local function GenerateWinChip(save_data, player_game_info, target_info)
    local win = 0
    local jackpot_param_v2 = save_data.jackpot_param_v2
    local lineNum = LineNum[player_game_info.game_type]()
    local total_amount = player_game_info.bet_amount * lineNum

    for i=1, #target_info.values do
        local jackpot_type = 6 - target_info.values[i]
        local add_value = CommonCal.Calculate.GetJackpotPoolChipVal(jackpot_param_v2, jackpot_type, total_amount)
        win = win + add_value
    end
    for i=1, target_info.bump_count do
        win = win * 2
    end
    return win
end

local function GetTargetElements(target_info)
    local elements = {}

    for i=1, #target_info.values do
        table.insert(elements, target_info.values[i])
    end

    table.insert(elements, ElementType.Wild)

    -- 增加bump类型
    if target_info.bump_count > 0 then
        table.insert(elements, ElementType.Bump)
    end

    return elements
end

local function RandTargetElement(player, target_elements, elements)
    local target_index = math.random_ext(player, 1, #target_elements)
    local target = target_elements[target_index]

    local weights = {}
    for i=1, #elements do
        if target == elements[i].index then
            table.insert(weights, elements[i].weight)
        else
            table.insert(weights, 0)
        end
    end
    local index = math.rand_weight(player, weights)
    return elements[index].index, index
end

local function RandInsertBump(player, path, target_info)
    local c = 0
    for i=1, #path do
        if path[i] == ElementType.Bump then
            c = c+1
        end
    end
    while c < target_info.bump_count do
        local index = math.random_ext(player, 1, #path-1)
        table.insert(path, index, ElementType.Bump)
        c = c+1
    end
end

local function InitJackpotPicks(player, game_room_config, player_game_info, save_data)
    local configs = CommonCal.Calculate.get_config(player, "LuckyChristmasBonusConfig")
    local config = math.rand_config(player, configs, "Weight")

    local target = config.Jackpot
    local count = 0
    local values = {}
    for i=1, #target do
        if target[i] > 0 then
            count = count + 1
            table.insert(values, i)
        end
    end

    local target_info = {
        target = target,
        count = count,
        values = values,
        bump_count = config.Bump
    }

    local finished = false
    local list = {}
    for i=1, 7 do list[i] = 0 end

    -- 如果有2个元素，加入一个wild在最后
    if target_info.count > 1 then
    end

    local path = {}
    local loop_count = 0
    local elements = GetRandElements()
    local target_elements = GetTargetElements(target_info)

    local rand_target = false

    while not finished do
        local item, index = RandElement(player, elements)

        if rand_target then
            -- 直接从目标元素里随机
            item, index = RandTargetElement(player, target_elements, elements)
        end

        if AddElement(list, target_info, item) then
            table.insert(path, item)
            elements[index].weight = 0
            finished = CheckFinished(list, target_info)
            -- 如果是最后一次且中将元素数量有多个，在最后加一个wild
            if target_info.count > 1 and finished then
                table.insert(path, ElementType.Wild)
            end
            rand_target = false
        else
            rand_target = math.rand_prob(player, 1.0)
        end

        loop_count = loop_count + 1
        if loop_count > 1000 then
            LOG(RUN, ERROR).Format("[SlotsLuckyChristmasSpin][InitJackpotPicks] over 1000 times")
            return
        end
    end

    -- 随机插入剩余的bump
    RandInsertBump(player, path, target_info)

    local real_count = #path
    -- 随机放置剩余的数据
    RandLeftJackpots(path)

    local picks = GeneratePicks(path)
    local win_chip = GenerateWinChip(save_data, player_game_info, target_info)
    return picks, win_chip, config.id, target_info, real_count
end

local function GetJackpotInitValues(save_data)
    local v = {}
    local jackpot_param_v2 = save_data.jackpot_param_v2
    for i=1, #jackpot_param_v2.prize_pool do
        local base = jackpot_param_v2.prize_pool[i].start_point * save_data.total_amount
        v[i] = base + jackpot_param_v2.prize_pool[i].extra_chip
    end
    return v
end

function SlotsLuckyChristmasSpin:BonusStart()
    local player_game_status = self.parameters.player_game_status
    local player = self.parameters.player
    local game_room_config = self.parameters.game_room_config
    local parameter = json.decode(self.parameters.parameter)
    local player_game_info = self.parameters.player_game_info
    local game_type = self.parameters.game_type
    local save_data = player_game_info.save_data
    local session = self.parameters.session

    local bonus_type = parameter.bonus_type
    

    local content = {
        bonus_type = bonus_type
    }

    if bonus_type == ENUM.BONUS_TYPE.PICK then
        -- 初始化pick的数据
        if not save_data.bonus_info then
            save_data.bonus_info = {}
            save_data.bonus_info.pick_history = {}
            -- 随机出30个
            save_data.bonus_info.jackpot_start_chip_arr = GetJackpotInitValues(save_data)
            for i=1, 1000 do
                local picks, chip, config_id, target_info, real_count = InitJackpotPicks(player, game_room_config, player_game_info, save_data)
                if picks then
                    save_data.bonus_info.pick_prize_pool = picks
                    save_data.bonus_info.chip = chip
                    save_data.bonus_info.config_id = config_id
                    save_data.bonus_info.target_info = target_info
                    save_data.bonus_info.real_count = real_count
                    break
                end
            end
        end

        content = {
            bonus_type = ENUM.BONUS_TYPE.PICK,
            chip = save_data.bonus_info.chip,
            pick_history = save_data.bonus_info.pick_history,
            jackpot_start_chip_arr = save_data.bonus_info.jackpot_start_chip_arr,
            pick_prize_pool = save_data.bonus_info.pick_prize_pool,
            config_id = save_data.bonus_info.config_id,
            max_pick_count = save_data.bonus_info.real_count
        }

        return content
    end

    if bonus_type == ENUM.BONUS_TYPE.SPIN_SELECT then
        content.silver_star_val = GetSilverStarValue(save_data)
        self:InitHoldSpin()
        local config = GetConfigTableConfig(session, game_room_config, player_game_info, "others_config")[1]
        content.free_spin_bouts = config.Free_Times
        content.hold_spin_bouts = 5
        return content
    end

    return content
end

function SlotsLuckyChristmasSpin:BonusPick()
    local player_game_status = self.parameters.player_game_status
    local player = self.parameters.player
    local game_room_config = self.parameters.game_room_config
    local parameter = json.decode(self.parameters.parameter)
    local player_game_info = self.parameters.player_game_info
    local game_type = self.parameters.game_type
    local save_data = player_game_info.save_data

    local bonus_type = parameter.bonus_type

    local content = {
        bonus_type = bonus_type
    }

    local pos = parameter.pick_pos
    table.insert(save_data.bonus_info.pick_history, pos)

    content.pick_history = save_data.bonus_info.pick_history

    return content
end

local function ResetBonusJackpot(player, save_data, target_info)
    -- 重置jackpot
    local jackpot_param_v2 = save_data.jackpot_param_v2
    for i=1, #target_info.values do
        local jackpot_type = 6 - target_info.values[i]
        CommonCal.Calculate.ResetJackpotExtraChip(jackpot_param_v2, jackpot_type)
    end
end

function SlotsLuckyChristmasSpin:BonusFinish()
    local player_game_status = self.parameters.player_game_status
    local player = self.parameters.player
    local game_room_config = self.parameters.game_room_config
    local parameter = json.decode(self.parameters.parameter)
    local player_game_info = self.parameters.player_game_info
    local game_type = self.parameters.game_type
    local save_data = player_game_info.save_data
    local session = self.parameters.session

    local bonus_type = parameter.bonus_type

    local content = {
        bonus_type = bonus_type
    }

    if not save_data.bonus_info and bonus_type == ENUM.BONUS_TYPE.PICK then
        return content
    end

    if bonus_type == ENUM.BONUS_TYPE.PICK then
        content.win_chip = save_data.bonus_info.chip
        ResetBonusJackpot(player, save_data, save_data.bonus_info.target_info)
        save_data.bonus_info = nil
        save_data.trigger_bonus_state_arr[ENUM.BONUS_TYPE.PICK] = false
        FeverQuestCal.OnMiniGameEnd(session, game_type, content.win_chip)
        return content
    end

    if bonus_type == ENUM.BONUS_TYPE.SPIN_SELECT then
        content.select_spin_type = parameter.select_spin_type

        if parameter.select_spin_type == 2 then
            self:EnterHoldSpin()
            if #save_data.hold_spin_steps == 0 then
                content.win_chip = save_data.silver_star_val
            end
        else
            self:EnterFreeSpin()
        end

        save_data.trigger_bonus_state_arr[ENUM.BONUS_TYPE.SPIN_SELECT] = false
        -- 清空respin的记录
        save_data.respin_count = nil
    end

    return content
end

local function RandHoldSpinType(session, game_room_config, player_game_info, player, count)
    local weights = {}
    local configs = GetConfigTableConfig(session, game_room_config, player_game_info, "respin_type")
    for i=1, #configs do
        table.insert(weights, configs[i].Weight_Num[count-5])
    end
    local config = configs[math.rand_weight(player, weights)]
    return config
end

local function GenerateHoldSpinInit(copper_pos)
    local result = {}
    for i=1, 3 do
        result[i] = result[i] or {}
        for j=1, 5 do
            result[i][j] = Types.Empty
        end
    end

    for i=1, #copper_pos do
        result[copper_pos[i].row][copper_pos[i].col] = Types.CopperStar
    end

    return result
end

function SlotsLuckyChristmasSpin:EnterFreeSpin()
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
    local save_data = player_game_info.save_data
    local session = self.parameters.session
    local task = session.task

    -- 随机hold spin的次数
    local config = GetConfigTableConfig(session, game_room_config, player_game_info, "others_config")[1]

    GameStatusCal.Calculate.AddGameStatus(player_game_status, GameStatusDefine.AllTypes.FreeSpinGame, config.Free_Times, 1,
        SlotsGameCal.Calculate.GetBetAmount(player_game_info))
    GameStatusCal.Calculate.FlushGameStatus(player_game_status)
    CommonCal.Calculate.UpdatePlayerGameStatus(session, task, player, game_type, player_game_status)
end

function SlotsLuckyChristmasSpin:InitHoldSpin()
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
    local save_data = player_game_info.save_data
    local session = self.parameters.session
    local task = session.task

    if save_data.respin_count then
        return
    end

    -- 随机hold spin的次数
    local configs = CommonCal.Calculate.get_config(player, "LuckyChristmasRespinTimesConfig")
    local config = math.rand_config(player, configs, "Weight")
    local respin_count = config.Respin_Times

    save_data.respin_count = respin_count
end

function SlotsLuckyChristmasSpin:EnterHoldSpin()
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
    local save_data = player_game_info.save_data
    local session = self.parameters.session
    local task = session.task

    -- 随机hold spin的次数
    local respin_count = save_data.respin_count

    local add_count = respin_count - 5
    -- 随机插板子
    local pos = {}
    if add_count > 0 then
        for i=1, add_count do
            local type = math.random_ext(player, 1, 5)
            pos[type] = pos[type] or 0
            pos[type] = pos[type] + 1
        end
    end
    -- 合成最终结果
    local picks = {}
    for i=1, 5 do
        if pos[i] and pos[i] > 0 then
            for j=1, pos[i] do
                -- 添加add spin图标
                table.insert(picks, 2)
            end
        end

        table.insert(picks, 1)
    end

    -- 添加holdspin到状态
    save_data.hold_spin_results = {}

    local gold_count = 0
    local silver_count = 0
    local copper_count = save_data.copper_star_count
    local copper_pos = save_data.copper_star_pos

    local total_count = copper_count
    local steps = {}
    for i=1, #picks do
        if total_count >= 15 then
            break
        end

        local config = RandHoldSpinType(session, game_room_config, player_game_info, player, total_count)
        gold_count = gold_count + config.Gold_Num
        silver_count = silver_count + config.Sliver_Num
        total_count = total_count + config.Gold_Num
        total_count = total_count + config.Sliver_Num

        -- 每一步记录有几个
        table.insert(steps, {
            gold_count = config.Gold_Num,
            silver_count = config.Sliver_Num,
            total_count = total_count,
            is_add_spin = picks[i] == 2
        })

        if total_count >= 15 then
            break
        end
    end

    save_data.hold_spin_steps = steps
    save_data.hold_spin_step = 0
    save_data.current_hold_spin_result = GenerateHoldSpinInit(copper_pos)

    GameStatusCal.Calculate.AddGameStatus(player_game_status, GameStatusDefine.AllTypes.HoldSpinGame, 5, 1,
        SlotsGameCal.Calculate.GetBetAmount(player_game_info))
    GameStatusCal.Calculate.FlushGameStatus(player_game_status)
    CommonCal.Calculate.UpdatePlayerGameStatus(session, task, player, game_type, player_game_status)
end

-- 生成新的
local function GenerateNewHoldSpin(player, result, steps, step)
    local poses = {}
    for i=1, 3 do
        for j=1, 5 do
            if result[i][j] == Types.AddSpin then
                result[i][j] = Types.Empty
            end
            if result[i][j] == Types.Empty then
                table.insert(poses, {row=i, col=j, weight=1})
            end
        end
    end

    if #poses == 0 then
        -- 已经填充了15个星星
        return result, {}, nil
    end

    local count = steps[step].gold_count + steps[step].silver_count

    if steps[step].is_add_spin then
        count = count + 1
    end

    local set = {}
    for i=1, count do
        local config, index = math.rand_config(player, poses, "weight")
        table.insert(set, config)
        poses[index].weight = 0
    end

    -- 位置做一个排序
    table.sort(set, function(a, b)
        if a.row == b.row then
            return a.col < b.col
        end
        return a.row < b.row
    end)

    local new_pos = {}
    local v = 1
    for i=1, steps[step].gold_count do
        result[set[v].row][set[v].col] = Types.GoldStar
        table.insert(new_pos, {row=set[v].row, col=set[v].col, type = Types.GoldStar})
        v = v+1
    end
    for i=1, steps[step].silver_count do
        result[set[v].row][set[v].col] = Types.SilverStar
        table.insert(new_pos, {row=set[v].row, col=set[v].col, type = Types.SilverStar})
        v=v+1
    end
    local add_spin_pos = nil
    -- 增加一个观赏性add spin图标
    if steps[step].is_add_spin and set[v] then
        add_spin_pos = {}
        result[set[v].row][set[v].col] = Types.AddSpin
        add_spin_pos.row = set[v].row
        add_spin_pos.col = set[v].col
    end
    return result, new_pos, add_spin_pos
end

local function HoldSpinBudget(save_data)
    local star_win_chip = GetGoldValue(save_data.star_info_arr)

    local mega_win_chip = 0

    if #save_data.star_info_arr == 15 then
        -- 获取grand jackpot
        local jackpot_param_v2 = save_data.jackpot_param_v2
        local total_amount = save_data.total_amount
        local add_value = CommonCal.Calculate.GetJackpotPoolChipVal(jackpot_param_v2, ENUM.JACKPOT_TYPE.MEGA, total_amount)
        CommonCal.Calculate.ResetJackpotExtraChip(jackpot_param_v2, ENUM.JACKPOT_TYPE.MEGA)
        mega_win_chip = add_value
    end

    return star_win_chip, mega_win_chip
end

function GetGoldValue(star_info_arr)
    local v = 0
    for i=1, #star_info_arr do
        v = v + star_info_arr[i].data.amount
    end
    return v
end

local function AddHoldSpinStarValue(player, save_data, result, new_pos)
    -- 银星星
    local star_info_arr = save_data.star_info_arr or {}
    --
    for i=1, #new_pos do
        local type = new_pos[i].type
        if type == Types.SilverStar then
            local row = new_pos[i].row
            local col = new_pos[i].col

            result[row][col] = Types.SilverStar

            local star_type = GetStarType(result[row][col])

            local item = {
                pos =  {row, col},
                data = {
                    star_type = star_type,
                    prize_type = 1,
                    jackpot_type = 0,
                    amount = save_data.silver_star_val,
                }
            }

            table.insert(star_info_arr, item)
        end
    end

    for i=1, #new_pos do
        local type = new_pos[i].type
        if type == Types.GoldStar then
            local row = new_pos[i].row
            local col = new_pos[i].col

            result[row][col] = Types.GoldStar

            local star_type = GetStarType(result[row][col])
            local gold_value = GetGoldValue(star_info_arr)

            local item = {
                pos =  {row, col},
                data = {
                    star_type = star_type,
                    prize_type = 1,
                    jackpot_type = 0,
                    amount = gold_value,
                }
            }

            table.insert(star_info_arr, item)
        end
    end

    return star_info_arr
end

local function ReplaceEmptyWithRandItem(player, result)
    local new_result = table.DeepCopy(result)
    for i=1, 3 do
        for j=1, 5 do
            if new_result[i][j] == Types.Empty then
                new_result[i][j] = math.random_ext(player, Types.Boy, Types.Nine)
            end
        end
    end
    return new_result
end

function SlotsLuckyChristmasSpin:HoldSpin()
    local player = self.parameters.player
    local player_game_info = self.parameters.player_game_info
    local special_parameter = self.parameters.special_parameter
    local is_free_spin = self.parameters.is_free_spin
    local game_room_config = self.parameters.game_room_config
    local player_game_status = self.parameters.player_game_status
    local amount = self.parameters.amount
    local game_type = self.parameters.game_type
    local player_feature_condition = self.parameters.player_feature_condition
    local session = self.parameters.session
    local save_data = player_game_info.save_data

    local current_status = GameStatusCal.Calculate.GetGameStatusInfo(player_game_status)

    local step = (save_data.hold_spin_step or 0) + 1

    if step > #save_data.hold_spin_steps then
        LOG(RUN, INFO).Format("[SlotsLuckyChristmasSpin][HoldSpin] step count error %s, player %s", step, player.id)
        step = #save_data.hold_spin_steps
    end

    save_data.hold_spin_step = step

    local result, new_pos, add_spin_pos = GenerateNewHoldSpin(player, save_data.current_hold_spin_result, save_data.hold_spin_steps, step)
    save_data.current_hold_spin_result = result

    local new_result = ReplaceEmptyWithRandItem(player, result)

    local origin_result = new_result
    local final_result = new_result
    local prize_items = {}
    local total_win_chip = 0
    local slots_win_chip = 0
    local pre_action_list = {}
    local all_prize_list = {}
    local free_spin_bouts = 0
    local slots_spin_list = {}

    local step_info = save_data.hold_spin_steps[step]

    -- 添加星星价值
    local star_info_arr = AddHoldSpinStarValue(player, save_data, origin_result, new_pos)
    table.insert(pre_action_list, {
            action_type = ActionType.ActionTypes.CoinInfoArr,
            star_info_arr = star_info_arr
        }
    )

    save_data.star_info_arr = star_info_arr

    if step_info.is_add_spin and add_spin_pos and #star_info_arr < 15 then
        table.insert(pre_action_list, {
            action_type = ActionType.ActionTypes.LuckyChristmasAddSpin,
            add_spin_bouts = 1,

            item_info_arr = {
                {
                    pos = {add_spin_pos.row, add_spin_pos.col},
                    data = {add_spin_bouts = 1}
                }
            }
        })

        GameStatusCal.Calculate.AddGameStatus(player_game_status, GameStatusDefine.AllTypes.HoldSpinGame, 1, 1,
            SlotsGameCal.Calculate.GetBetAmount(player_game_info))
    end

    -- 最后一次结算
    if step == #save_data.hold_spin_steps or #star_info_arr >= 15 then
        local star_win_chip, jackpot_win_chip = HoldSpinBudget(save_data)

        table.insert(pre_action_list, {
            action_type = ActionType.ActionTypes.HoldSpinSettle,
            star_amount = star_win_chip,
            grand_info = {
                have = jackpot_win_chip > 0,
                amount = jackpot_win_chip
            },
            total_amount = star_win_chip + jackpot_win_chip
        })

        total_win_chip = star_win_chip + jackpot_win_chip
        slots_win_chip = star_win_chip + jackpot_win_chip
        special_parameter.hold_spin_win_chip = total_win_chip

        --任何时候结算都设置process
        local delta = current_status.total_process - current_status.process
        if delta > 0 then
            GameStatusCal.Calculate.UpdateGameStatus(player_game_status, delta, total_win_chip)
        end

        FeverQuestCal.OnLuckyChristmasRespinEnd(session, total_win_chip)
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