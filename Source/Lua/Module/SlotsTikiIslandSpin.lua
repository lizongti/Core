require"Common/SlotsGameCalculate" 
require"Common/SlotsGameCal" 
require"Common/LineNum"

local MAX_COUNT = 15

SlotsTikiIslandSpin = {}

local Types = _G["TikiIslandTypeArray"].Types

local function ConvertClientChips(chips)
    local v = {}
    for i=1, #chips do
        table.insert(v, {
            pos = {chips[i].row, chips[i].col},
            data = {
                prize_type = chips[i].prize_type,
                amount = chips[i].amount
            }
        })
    end
    return v
end

-- 入口
function SlotsTikiIslandSpin:Enter()
    local task = self.parameters.task
    local player = self.parameters.player
    local game_room_config = self.parameters.game_room_config
    local player_game_info = self.parameters.player_game_info
    local session = self.parameters.session
    local player_game_status = self.parameters.player_game_status

    local bonus_info = {}
    local save_data = player_game_info.save_data

    -- jackpot初始化
    if not save_data.jackpot_param_v2 then
        save_data.jackpot_param_v2 = {}
        local config = CommonCal.Calculate.get_config(player, "TikiIslandJackpotConfig")
        CommonCal.Calculate.InitJackpotParam(save_data.jackpot_param_v2, config)
    end
    
    bonus_info.jackpot_param = CommonCal.Calculate.GetJakcpotParamToClient(save_data.jackpot_param_v2)

    local status = GameStatusCal.Calculate.GetGameStatus(player_game_status)

    if status == GameStatusDefine.AllTypes.HoldSpinGame then
        bonus_info.extra_info_arr = ConvertClientChips(save_data.hold_spin_items)
    end

    return bonus_info
end

IsBonusGame = function(game_room_config, player, player_game_info)
    return false
end

local function GenerateHoldSpinItem(player, row, col, total_amount, config_table)
    local chip_config = CommonCal.Calculate.get_config(player, config_table.spin_ball_weight_config)
    local weights = {}

    for i=1, #chip_config do
        table.insert(weights, chip_config[i].hold_spin_prize_weight)
    end

    local config = chip_config[math.rand_weight(player, weights)]
    
    local item = {
        row = row,
        col = col,
        prize_type = config.prize_type,
        amount = config.prize_value * total_amount
    }

    return item
end

local function RandHoldSpinItemChip(player, pos_list, total_amount, is_hold_spin, config_table)
    local chip_config = CommonCal.Calculate.get_config(player, config_table.spin_ball_weight_config)
    local weights = {}

    for i=1, #chip_config do
        table.insert(weights, chip_config[i].base_prize_weight)
    end

    local chips = {}

    for i=1, #pos_list do
        local config = chip_config[math.rand_weight(player, weights)]
        table.insert(chips, {
            row = pos_list[i].row,
            col = pos_list[i].col,
            prize_type = config.prize_type,
            amount = config.prize_value * total_amount
        })
    end

    return chips
end

local function InitHoldSpinData(player, total_amount, save_data, count, pos_list, final_item_ids, player_game_status, amount, config_table)
    local config_count = CommonCal.Calculate.get_config(player, "TikiIslandHoldSpinFinalBallCountWeightConfig")
    local weights = {}
    for i=1, #config_count do
        if config_count[i].final_ball_count > count then
            table.insert(weights, config_count[i].count_weight)
        end
    end
    local rand_index = math.rand_weight(player, weights) or 0
    local max_count = config_count[rand_index+count].final_ball_count
    local left_count = max_count - count
    --剩余的里面随机出现的时间
    local split_counts = {}
    local show_config = CommonCal.Calculate.get_config(player, "TikiIslandHoldSpinShowBallCountWeightConfig")
    local round_config = CommonCal.Calculate.get_config(player, "TikiIslandHoldSpinShowRoundWeightConfig")

    while left_count > 0 do
        local show_weight = nil
        local round_weight = nil
        for i=1, #show_config do
            if show_config[i].remain_ball_count == left_count then
                show_weight = show_config[i].show_weight
                break
            end
        end

        for i=1, #round_config do
            if round_config[i].remain_ball_count == left_count then
                round_weight = round_config[i].show_round_weight
                break
            end
        end

        local sub_count = math.rand_weight(player, show_weight)
        local round = math.rand_weight(player, round_weight)
        left_count = left_count - sub_count
        table.insert(split_counts, {count = sub_count, round=round})
    end

    -- 插入最后一轮空的
    if count == MAX_COUNT then
        table.insert(split_counts, {count = 0, round=1})
        GameStatusCal.Calculate.AddGameStatus(player_game_status, GameStatusDefine.AllTypes.HoldSpinGame, 1, 1, amount)
    else
        if max_count ~= MAX_COUNT then
            table.insert(split_counts, {count = 0, round=3})
        end
        if max_count == MAX_COUNT and #split_counts == 1 then
            GameStatusCal.Calculate.AddGameStatus(player_game_status, GameStatusDefine.AllTypes.HoldSpinGame, split_counts[1].round, 1, amount)
        else
            GameStatusCal.Calculate.AddGameStatus(player_game_status, GameStatusDefine.AllTypes.HoldSpinGame, 3, 1, amount)
        end
    end

    -- 记录当前的holdspin次数和round
    save_data.current_index = 1
    save_data.current_round = 1
    save_data.max_count = max_count
    save_data.split_counts = split_counts
    save_data.final_item_ids = final_item_ids
    -- 添加HoldSpin金币信息
    save_data.hold_spin_items = RandHoldSpinItemChip(player, pos_list, total_amount, nil, config_table)
    -- print(string.format("HoldSpin初始化 HoldSpin数量 %s 分%s次执行", max_count, #save_data.split_counts))
    return save_data.hold_spin_items
end

local function RemoveHoldSpin(player, origin_result)
    table.iterate2d(origin_result, function(i, j, item) 
        if item == Types.HoldSpin then
            origin_result[i][j] = math.random_ext(player, 5, 13)
        end
    end)
end

local function RandFreePos(player, origin_result)
    local pos = {}
    table.iterate2d(origin_result, function(row, col, item) 
        if item ~= Types.HoldSpin then
            table.insert(pos, {row = row, col = col})
        end
    end)
    if #pos == 0 then
        return nil
    end
    assert(#pos > 0)
    local v = pos[math.random_ext(player, 1, #pos)]
    return v
end

local function IsHoldSpinTriggerNewRound(save_data)
    local split_info = save_data.split_counts[save_data.current_index]

    -- 最后一次，不再产生新的
    if #save_data.split_counts == save_data.current_index and split_info.round == save_data.current_round then
        return false
    end

    if split_info.round == save_data.current_round then
        return true
    end
    return false
end

local function AddCurrentHoldSpinItems(player, save_data, origin_result, total_amount, config_table)
    local hold_spin_items = save_data.hold_spin_items
    
    -- 如果中了就添加位置
    for i=1, #hold_spin_items do
        local row = hold_spin_items[i].row
        local col = hold_spin_items[i].col
        origin_result[row][col] = Types.HoldSpin
    end

    -- 检测当前是否中HoldSpin
    local split_info = save_data.split_counts[save_data.current_index]
    
    if split_info.round == save_data.current_round then
        for i=1, split_info.count do
            local pos = RandFreePos(player, origin_result)
            if pos == nil then
                return
            end
            local item = GenerateHoldSpinItem(player, pos.row, pos.col, total_amount, config_table)
            table.insert(hold_spin_items, item)
            origin_result[pos.row][pos.col] = Types.HoldSpin
        end
    end
end

-- 随机jackpot值
local function FetchJackpotValue(save_data, jackpot_type, total_amount)
    local jackpot_param_v2 = save_data.jackpot_param_v2
    local value = CommonCal.Calculate.GetJackpotPoolChipVal(jackpot_param_v2, jackpot_type, total_amount)
    CommonCal.Calculate.ResetJackpotExtraChip(jackpot_param_v2, jackpot_type)
    return value
end

local function HoldSpinBudget(session, save_data, total_amount)
    local split_info = save_data.split_counts[save_data.current_index]
    local max_index = #save_data.split_counts

    if max_index == save_data.current_index and split_info.round == save_data.current_round then
        local win_chip = 0
        local budget_info = {
            action_type = ActionType.ActionTypes.HoldSpinSettle,
        }
        local extra_info_arr = {}
        budget_info.extra_info_arr = extra_info_arr

        local client_data = ConvertClientChips(save_data.hold_spin_items)

        for i=1, #save_data.hold_spin_items do
            local v = table.DeepCopy(client_data[i])

            if save_data.hold_spin_items[i].prize_type == 5 then
                win_chip = win_chip + save_data.hold_spin_items[i].amount
            else
                local real = FetchJackpotValue(save_data, save_data.hold_spin_items[i].prize_type, total_amount)
                win_chip = win_chip + real
                v.data.amount = real
            end

            table.insert(extra_info_arr, v)
        end

        -- grand
        local grand_info = {
            have = false,
            amount = 0,
        }

        budget_info.grand_info = grand_info

        if #save_data.hold_spin_items == MAX_COUNT then
            grand_info.have = true
            grand_info.amount = FetchJackpotValue(save_data, 1, total_amount)
            win_chip = grand_info.amount + win_chip
        end

        budget_info.total_amount = win_chip
        budget_info.enter_info = {
            final_item_ids = save_data.final_item_ids
        }

        FeverQuestCal.OnTikiHoldSpinEnd(session, win_chip)

        return win_chip, budget_info

    end

    return 0
end

local function UpdateHoldSpinRound(save_data)
    local split_info = save_data.split_counts[save_data.current_index]

    if split_info.round == save_data.current_round then
        save_data.current_index = save_data.current_index + 1
        save_data.current_round = 1
    else
        save_data.current_round = save_data.current_round + 1
    end
end

function SlotsTikiIslandSpin:HoldSpin()
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
    local session = self.parameters.extern_param.session

    local lineNum = LineNum[player_game_info.game_type]()
    local total_amount = lineNum * amount
    local type = _G[game_room_config.game_name .. "TypeArray"].Types

    local config_table = SlotsGameCal.Calculate.GetMapConfigTable(session, game_room_config, player_game_info, amount * lineNum)
    local reel_file = "TikiIslandHoldSpinReelConfig"
    local origin_result, reel_file_name = SlotsGameCal.Calculate.GenItemResult(player, game_type, is_free_spin, game_room_config, reel_file)

    local split_info = save_data.split_counts[save_data.current_index]
    -- print(string.format("开始一次HoldSpin 当前index %s 当前round %s 目标round %s", 
        --  save_data.current_index, save_data.current_round, split_info.round))

    -- 去掉HoldSpin图标
    RemoveHoldSpin(player, origin_result)

    -- 装上现有的图标
    AddCurrentHoldSpinItems(player, save_data, origin_result, total_amount, config_table)

    local pre_action_list = {}
    local final_result = table.DeepCopy(origin_result)

    local infos = ConvertClientChips(save_data.hold_spin_items)
    table.insert(pre_action_list, {
        action_type = ActionType.ActionTypes.CoinInfoArr,
        extra_info_arr = infos
    })

    local all_prize_list = {}
    local slots_win_chip = 0
    local total_win_chip = 0

    if IsHoldSpinTriggerNewRound(save_data) then
        -- print("HoldSpin新的一轮")
        if save_data.max_count == MAX_COUNT then
            local sp_count = #save_data.split_counts
            if save_data.current_index == #save_data.split_counts - 1 then
                local next_round = save_data.split_counts[sp_count].round
                local v = next_round - (3 - save_data.current_round)
                GameStatusCal.Calculate.AddGameStatus(player_game_status, GameStatusDefine.AllTypes.HoldSpinGame, v, 1, amount)
            else
                GameStatusCal.Calculate.AddGameStatus(player_game_status, GameStatusDefine.AllTypes.HoldSpinGame, save_data.current_round, 1, amount)
            end
        else
            GameStatusCal.Calculate.AddGameStatus(player_game_status, GameStatusDefine.AllTypes.HoldSpinGame, save_data.current_round, 1, amount)
        end
    end

    -- 最后一次结算，是否触发Grand大奖
    local win_chip, budget_info = HoldSpinBudget(session, save_data, total_amount)

    if win_chip == 0 then
        UpdateHoldSpinRound(save_data)
    else
        -- print(string.format("HoldSpin完成结算 赢钱%s", win_chip))
        table.insert(pre_action_list, budget_info)
        if save_data.max_count == MAX_COUNT then
            -- GameStatusCal.Calculate.AddGameStatus(player_game_status, GameStatusDefine.AllTypes.HoldSpinGame, 0, 2, amount)
        end
    end

    slots_win_chip = win_chip
    total_win_chip = win_chip

    local slots_spin_list = {}

    table.insert(slots_spin_list, {
        item_ids = json.encode(SlotsGameCal.Calculate.TransResultToCList(origin_result, game_room_config)),
        prize_items = prize_items or {},
        win_chip = total_win_chip,
        pre_action_list = json.encode(pre_action_list),
        final_item_ids = json.encode(SlotsGameCal.Calculate.TransResultToCList(final_result, game_room_config)),
        slots_win_chip = slots_win_chip,
    })

    local formation_list = {}
    table.insert(formation_list, {
        slots_spin_list = slots_spin_list,
        id = 1
    })

    special_parameter.total_win_chip = total_win_chip

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

local function MergeVolcano(game_room_config, prize_items, origin_result, is_free_spin)
    if #prize_items == 0 then
        return
    end

    local wild_type = is_free_spin and Types.Wild_x2 or Types.Wild

    local wilds = table.DeepCopy(origin_result)
    for i=1, #wilds do
        for j=1, #wilds[i] do
            wilds[i][j] = 0
        end
    end

    local type = _G[game_room_config.game_name .. "LineArray"]["Lines1"]

    for i=1, #prize_items do
        local v = prize_items[i]
        local t = type[v.line_index]
        for j=v.from_index, v.to_index do
            if origin_result[t[j]][j] == wild_type then
                wilds[t[j]][j] = 1
            end
        end
    end

    for i=2, #wilds do
        for j=1, #wilds[i] do
            if wilds[i][j] == 1 and wilds[i-1][j] >= 1 then
                wilds[i][j] = wilds[i-1][j] + 1
            end
        end
    end

    for i=#wilds, 2, -1 do
        for j=1, #wilds[i] do
            if wilds[i][j] > 1 then
                if wilds[i][j] == 2 then
                    wilds[i][j] = 0
                    wilds[i-1][j] = 0
                    origin_result[i-1][j] = 121 + (is_free_spin and 100 or 0)
                    origin_result[i][j] = 122 + (is_free_spin and 100 or 0)
                end
                if wilds[i][j] == 3 then
                    wilds[i][j] = 0
                    wilds[i-1][j] = 0
                    wilds[i-2][j] = 0
                    origin_result[i-2][j] = 131 + (is_free_spin and 100 or 0)
                    origin_result[i-1][j] = 132 + (is_free_spin and 100 or 0)
                    origin_result[i][j] = 133 + (is_free_spin and 100 or 0)
                end
            end
        end
    end
end

local function GetWildMultiChip(prize_items, origin_result)
    if #prize_items == 0 then
        return 0
    end

    local type = _G["TikiIslandLineArray"]["Lines1"]

    local wilds = table.DeepCopy(origin_result)
    for i=1, #wilds do
        for j=1, #wilds[i] do
            wilds[i][j] = 0
        end
    end

    local total = 0

    for i=1, #prize_items do
        local r = prize_items[i].payrate
        local v = prize_items[i]
        local t = type[v.line_index]
        for j=v.from_index, v.to_index do
            if origin_result[t[j]][j] == Types.Wild_x2 then
                r = r * 2
            end
        end
        total = total + r
    end
    total = total / 1000
    return total
end

function SlotsTikiIslandSpin:NormalSpin()
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
    local session = self.parameters.extern_param.session

    local lineNum = LineNum[player_game_info.game_type]()
    local total_amount = lineNum * amount
    local type = _G[game_room_config.game_name .. "TypeArray"].Types

    local config_table = SlotsGameCal.Calculate.GetMapConfigTable(session, game_room_config,player_game_info, lineNum * amount)
    local reel_file, weight_file = SlotsGameCal.Calculate.GetReelWeightConfigs(player, config_table, is_free_spin)

    local origin_result, reel_file_name = SlotsGameCal.Calculate.GenItemResultWithWeight(player, game_type, is_free_spin, 
        game_room_config, reel_file, weight_file)

    local pre_action_list = {}
    local final_result = table.DeepCopy(origin_result)

    local payrate_file = CommonCal.Calculate.get_config(player, game_room_config.game_name .. "PayrateConfig")
    local left_or_right = game_room_config.direction_type

    local prize_items, total_payrate = SlotsGameCal.Calculate.GenPrizeInfo(final_result, game_room_config, payrate_file, 
        left_or_right, type, nil, nil, bet_ratio)

    local all_prize_list = {}
    table.insert(all_prize_list, prize_items)

    local slots_win_chip = GetWildMultiChip(prize_items, origin_result) * amount
    special_parameter.is_wild_multi = slots_win_chip > total_payrate * amount

    local total_win_chip = slots_win_chip

    CommonCal.Calculate.UpdateJackpotExtraChip(is_free_spin, "TikiIslandJackpotConfig", save_data, total_amount, pre_action_list)

    local free_spin_bouts = SlotsGameCal.Calculate.FreeSpinCheck(player, final_result, game_room_config, is_free_spin, type.Scatter)

    local slots_spin_list = {}

    local free_spin_bouts_left = GameStatusCal.Calculate.GetFreeSpinBouts(player_game_status)

    local pos_list = SlotsGameCal.Calculate.GetItemPosition(final_result, game_room_config, type.HoldSpin)

    if is_free_spin and free_spin_bouts > 0 then
        local action_info = {
            action_type = ActionType.ActionTypes.FreeSpinTimesAdd,
            free_spin_bouts = free_spin_bouts
        }
        if #pos_list < 6 then
            table.insert(pre_action_list, action_info)
        else
            SlotsGameCal.Calculate.AddActionLater(player_game_info, action_info, {"FreeSpinTimesAdd"})
        end
    end

    if #pos_list >= 6 then
        -- print("BaseGame触发HoldSpin")
        local final_item_ids = json.encode(SlotsGameCal.Calculate.TransResultToCList(final_result, game_room_config))
        local infos = InitHoldSpinData(player, total_amount, save_data, #pos_list, pos_list, final_item_ids, player_game_status, amount, config_table)
        local infos = ConvertClientChips(infos)
        table.insert(pre_action_list, {
            action_type = ActionType.ActionTypes.CoinInfoArr,
            extra_info_arr = infos
        })
        special_parameter.trigger_hold_spin = true
    else
        -- 为每一个HoldSpin图标加上chips
        local infos = RandHoldSpinItemChip(player, pos_list, total_amount, nil, config_table)
        local infos = ConvertClientChips(infos)
        table.insert(pre_action_list, {
            action_type = ActionType.ActionTypes.CoinInfoArr,
            extra_info_arr = infos
        })
        special_parameter.trigger_hold_spin = false
    end

    if free_spin_bouts > 0 then
        GameStatusCal.Calculate.AddGameStatus(player_game_status, GameStatusDefine.AllTypes.FreeSpinGame, free_spin_bouts, 1, amount)
    end

    if not is_free_spin then
        MergeVolcano(game_room_config, prize_items, final_result, is_free_spin)
    end

    table.insert(slots_spin_list, {
        item_ids = json.encode(SlotsGameCal.Calculate.TransResultToCList(origin_result, game_room_config)),
        prize_items = prize_items,
        win_chip = total_win_chip,
        pre_action_list = json.encode(pre_action_list),
        final_item_ids = json.encode(SlotsGameCal.Calculate.TransResultToCList(final_result, game_room_config)),
        slots_win_chip = slots_win_chip,
    })

    local formation_list = {}
    table.insert(formation_list, {
        slots_spin_list = slots_spin_list,
        id = 1
    })

    special_parameter.final_result = final_result
    special_parameter.total_win_chip = total_win_chip

    local result = {}
    result.final_result = final_result --结果数组
    result.total_win_chip = total_win_chip  --总奖金
    result.all_prize_list = all_prize_list --所有连线列表
    result.free_spin_bouts = free_spin_bouts --freespin的次数
    result.formation_list = formation_list --阵型列表
    result.reel_file_name = reel_file_name --reel表名
    result.slots_win_chip = 11 --总奖励
    result.special_parameter = special_parameter --其他参数，主要给模拟器传参
    return result
end
