require "Common/SlotsGameCalculate" -- 重写的接口
require "Common/SlotsGameCal" -- 旧的接口
require "Common/LineNum"
module("SlotsCashRainSpin", package.seeall)

local PRIZE_TYPE_ENUM = {
    JAKCPOT_GRAND = 1,
    JACKPOT_MAJOR = 2,
    JACKPOT_MINOR = 3,
    JACKPOT_MINI = 4,
    BONUS = 5,
    CHIP = 6,
    PICKCOUNT = 7,
    CHIPMULTIPLE = 8,
    WHEELRESPIN = 9
}

local function AddJackpotInfo(player, save_data, total_amount, prize_config)
    local config = CommonCal.Calculate.get_config(player, "CashRainJackpotConfig")

    local jackpot_param = save_data.jackpot_param
    local total_value = 0

    local win_infos = {}

    local type = prize_config.prize_type
    total_value = total_amount * config[type].start_point + jackpot_param[type]
    jackpot_param[type] = 0

    return total_value
end

local function GetJakcpotParamToClient(_jackpot_param)
    --初始化返回值
    local jackpot_param_cliect = {prize_pool = {}}

    --处理返回值
    for jackpot_type, extra_chip in pairs(_jackpot_param) do
        --初始化返回给客户端的jackpot信息
        local jackpot_prize_clinet = {}
        jackpot_prize_clinet.extra_chip = extra_chip --额外筹码
        --插入返回的表中
        jackpot_param_cliect.prize_pool[jackpot_type] = jackpot_prize_clinet
    end

    --返回
    return jackpot_param_cliect
end

local function InitWheelInfo(save_data)
    if not save_data.bonus_content then
        local content = {
            result = {
                win_chip = 0,
                turn_type = 1,
                index = 0
            },
            progress = 0
        }
        save_data.bonus_content = content
    end

    return save_data.bonus_content
end

local function CalcJackpot(player, save_data, prize_config, player_game_info)
    --如果是jackpot，直接加钱
    if prize_config.prize_type >= 1 and prize_config.prize_type <= 4 then
        --add jackpot
        local lineNum = LineNum[player_game_info.game_type]()
        local total_amount = lineNum * player_game_info.bet_amount
        local win_chip = AddJackpotInfo(player, save_data, total_amount, prize_config)
        save_data.bonus_content.win_chip = win_chip
        save_data.is_bonus_game = false
    end
end

local function BonusProgress0(task, player, game_room_config, parameter, player_game_info, game_type, save_data)
    local wheel_config = CommonCal.Calculate.get_config(player, "CashRainWheelConfig")
    -- 进度为0，开始随机大转盘
    -- 随机大转盘信息
    local weights = {}
    for i = 1, #wheel_config do
        if wheel_config[i].wheel_type == 1 then
            table.insert(weights, wheel_config[i].wheel_weight)
        end
    end

    local index = math.rand_weight(player, weights)
    local prize_config = wheel_config[index]
    --返回转的index
    save_data.bonus_content = {
        progress = 1,
        result = {
            turn_type = 1,
            index = index
        }
    }

    CalcJackpot(player, save_data, prize_config, player_game_info)
end

local function CalcBonusPick(player, player_game_info, save_data, wheel_config, progress)
    --bonus game 捡钱
    --随机选择一个pick
    local weights = {}
    for i = 1, #wheel_config do
        if wheel_config[i].wheel_type == 2 then
            table.insert(weights, wheel_config[i].wheel_weight)
        end
    end

    local index = math.rand_weight(player, weights) + 16
    save_data.bonus_content = {
        progress = progress,
        result = {
            turn_type = 2,
            index = index
        }
    }
    --进入bonus game逻辑，大转盘逻辑结束
    --随机pick的值
    local pick_info = {
        pick_count = wheel_config[index].value_param,
        types = {},
        win_chip = 0,
        bet_amount = player_game_info.bet_amount,
    }

    save_data.pick_info = pick_info
    local types = {}
    local pick_config = CommonCal.Calculate.get_config(player, "CashRainBonusPickConfig")
    local weights = {}

    for i = 1, #pick_config do
        table.insert(weights, pick_config[i].pick_payrate_weight)
    end

    for i = 1, pick_info.pick_count do
        local index = math.rand_weight(player, weights)
        local type = pick_config[index].id
        local payrate = pick_config[index].pick_payrate
        types[type] = types[type] or {type = type, count = 0, payrate = payrate}
        types[type].count = types[type].count + 1
    end

    for k, v in pairs(types) do
        table.insert(pick_info.types, {type = k, count = v.count, payrate = v.payrate})
        pick_info.win_chip = pick_info.win_chip + player_game_info.bet_amount * v.payrate * v.count
    end
end

local function BonusProgress1(task, player, game_room_config, parameter, player_game_info, game_type, save_data)
    local wheel_config = CommonCal.Calculate.get_config(player, "CashRainWheelConfig")
    local content = save_data.bonus_content
    --小转盘：bonus游戏或者prize奖励
    local index = content.result.index
    local prize_config = wheel_config[index]
    local big_wheel_value = prize_config.value_param

    if prize_config.prize_type == 5 then
        CalcBonusPick(player, player_game_info, save_data, wheel_config, 2)
    elseif prize_config.prize_type == 6 then
        --直接金钱奖励
        --随机一个小转盘，如果是1倍转到
        local weights = {}

        for i = 1, #wheel_config do
            if wheel_config[i].wheel_type == 3 then
                table.insert(weights, wheel_config[i].wheel_weight)
            end
        end

        local index = math.rand_weight(player, weights) + 21
        local prize_config = wheel_config[index]

        save_data.bonus_content = {
            progress = 2,
            result = {
                turn_type = 2,
                index = index
            }
        }

        if prize_config.value_param > 1 then
            save_data.is_bonus_game = false
            save_data.bonus_content.progress = -1
        end

        --结算金钱
        save_data.bonus_content.win_chip = prize_config.value_param * big_wheel_value * player_game_info.bet_amount
    end
end

--只有转到了金钱奖励 x1才会走到这里
local function BonusProgress2(task, player, game_room_config, parameter, player_game_info, game_type, save_data)
    local wheel_config = CommonCal.Calculate.get_config(player, "CashRainWheelConfig")

    --检查index
    local index = save_data.bonus_content.result.index

    if wheel_config[index].wheel_type == 3 and wheel_config[index].value_param == 1 then
    else
        return {}
    end

    --进度为0，开始随机大转盘
    --随机大转盘信息
    local weights = {}
    for i = 1, #wheel_config do
        if wheel_config[i].wheel_type == 1 then
            table.insert(weights, wheel_config[i].wheel_weight)
        end
    end

    local index = math.rand_weight(player, weights)
    local prize_config = wheel_config[index]
    --返回转的index
    save_data.bonus_content = {
        progress = 3,
        result = {
            turn_type = 1,
            index = index
        }
    }

    CalcJackpot(player, save_data, prize_config, player_game_info)
end

local function BonusProgress3(task, player, game_room_config, parameter, player_game_info, game_type, save_data)
    local wheel_config = CommonCal.Calculate.get_config(player, "CashRainWheelConfig")
    --小转盘：bonus游戏或者prize奖励
    local index = save_data.bonus_content.result.index

    local prize_config = wheel_config[index]

    local big_wheel_value = prize_config.value_param

    if prize_config.prize_type == 5 then
        CalcBonusPick(player, player_game_info, save_data, wheel_config, 4)
    elseif prize_config.prize_type == 6 then
        --prize info
        --随机一个小转盘，不可能转到1
        local weights = {}

        for i = 1, #wheel_config do
            if wheel_config[i].wheel_type == 4 then
                table.insert(weights, wheel_config[i].wheel_weight)
            end
        end

        local index = math.rand_weight(player, weights) + 26
        local prize_config = wheel_config[index]

        save_data.bonus_content = {
            progress = -1,
            result = {
                turn_type = 2,
                index = index
            }
        }
        --结算奖励
        save_data.is_bonus_game = false
        save_data.bonus_content.win_chip = prize_config.value_param * big_wheel_value * player_game_info.bet_amount
    end
end

function SlotsCashRainSpin:BonusWheelEnter()
    local player_game_status = self.parameters.player_game_status
    local player = self.parameters.player
    local game_room_config = self.parameters.game_room_config
    local parameter = json.decode(self.parameters.parameter)
    local player_game_info = self.parameters.player_game_info
    local game_type = self.parameters.game_type
    local save_data = player_game_info.save_data
    local session = self.parameters.session
    LOG(RUN, INFO).Format("BonusWheelEnter")
    save_data.bonus_content = nil

    local save_data = player_game_info.save_data

    local content = InitWheelInfo(save_data)

    content.jackpot_param = GetJakcpotParamToClient(save_data.jackpot_param)

    return content
end

function SlotsCashRainSpin:BonusWheelClear()
    local player_game_status = self.parameters.player_game_status
    local player = self.parameters.player
    local game_room_config = self.parameters.game_room_config
    local parameter = json.decode(self.parameters.parameter)
    local player_game_info = self.parameters.player_game_info
    local game_type = self.parameters.game_type
    local save_data = player_game_info.save_data
    local session = self.parameters.session
    LOG(RUN, INFO).Format("BonusWheelClear")

    save_data.is_bonus_game = true
    save_data.bonus_content.progress = 0
end

function SlotsCashRainSpin:BonusWheelClick()
    local player_game_status = self.parameters.player_game_status
    local player = self.parameters.player
    local game_room_config = self.parameters.game_room_config
    local parameter = json.decode(self.parameters.parameter)
    local player_game_info = self.parameters.player_game_info
    local game_type = self.parameters.game_type
    local save_data = player_game_info.save_data
    local session = self.parameters.session

    LOG(RUN, INFO).Format("BonusWheelClick")

    local progress = save_data.bonus_content.progress or 0

    if progress == 0 then
        BonusProgress0(task, player, game_room_config, parameter, player_game_info, game_type, save_data)
    elseif progress == 1 then
        BonusProgress1(task, player, game_room_config, parameter, player_game_info, game_type, save_data)
    elseif progress == 2 then
        --小转盘再来一次
        BonusProgress2(task, player, game_room_config, parameter, player_game_info, game_type, save_data)
    elseif progress == 3 then
        --第二次的小转盘
        BonusProgress3(task, player, game_room_config, parameter, player_game_info, game_type, save_data)
    end

    local content = table.DeepCopy(save_data.bonus_content)

    if not save_data.is_bonus_game then
        content.is_finished = true
    end

    return content
end

function SlotsCashRainSpin:BonusMoneyPickEnter()
    local player_game_status = self.parameters.player_game_status
    local player = self.parameters.player
    local game_room_config = self.parameters.game_room_config
    local parameter = json.decode(self.parameters.parameter)
    local player_game_info = self.parameters.player_game_info
    local game_type = self.parameters.game_type
    local save_data = player_game_info.save_data
    local session = self.parameters.session
    LOG(RUN, INFO).Format("BonusMoneyPickEnter")

    --清除大转盘相关数据
    local save_data = player_game_info.save_data
    local pick_info = save_data.pick_info

    if not pick_info then
        local wheel_config = CommonCal.Calculate.get_config(player, "CashRainWheelConfig")
        CalcBonusPick(player, player_game_info, save_data, wheel_config, 2)
        pick_info = save_data.pick_info
    end

    local content = {
        max_pick_count = pick_info.pick_count,
        base_credit = pick_info.bet_amount,
        bonus_win = pick_info.win_chip,
        pick_result = pick_info.types
    }

    content.jackpot_param = GetJakcpotParamToClient(save_data.jackpot_param)

    return content
end

function SlotsCashRainSpin:BonusMoneyPickFinish()
    local player_game_status = self.parameters.player_game_status
    local player = self.parameters.player
    local game_room_config = self.parameters.game_room_config
    local parameter = json.decode(self.parameters.parameter)
    local player_game_info = self.parameters.player_game_info
    local game_type = self.parameters.game_type
    local save_data = player_game_info.save_data
    local session = self.parameters.session
    LOG(RUN, INFO).Format("BonusMoneyPickFinish")

    --清除pick相关数据
    local save_data = player_game_info.save_data
    local pick_info = save_data.pick_info

    if not pick_info then
        return
    end

    local content = {
        progress = -1,
        max_pick_count = pick_info.pick_count,
        base_credit = pick_info.bet_amount,
        bonus_win = pick_info.win_chip,
        pick_result = pick_info.types
    }

    content.win_chip = pick_info.win_chip

    save_data.is_bonus_game = false
    save_data.pick_info = nil
    save_data.bonus_content = nil

    FeverQuestCal.OnCashRainBonusGameEnd(session, pick_info.win_chip)

    return content
end

local function GetBonusType(player, index)
    local wheel_config = CommonCal.Calculate.get_config(player, "CashRainWheelConfig")
    local prize_config = wheel_config[index]
    
    if prize_config and prize_config.wheel_type == 2 then
        return 2
    end
    return 1
end

-- 入口
function SlotsCashRainSpin:Enter()
    local task = self.parameters.task
    local player = self.parameters.player
    local game_room_config = self.parameters.game_room_config
    local player_game_info = self.parameters.player_game_info
    local session = self.parameters.session
    local player_game_status = self.parameters.player_game_status
    local save_data = player_game_info.save_data

    local bonus_info = {
        is_bonus_game = save_data.is_bonus_game and 1 or 0,
        bonus_type = 0,
    }

    if save_data.is_bonus_game then
        if save_data.bonus_content == nil then
            InitWheelInfo(save_data)
        end

        bonus_info.content = save_data.bonus_content
        if save_data.pick_info then
            bonus_info.content.pick_info = save_data.pick_info
        end

        bonus_info.bonus_type = GetBonusType(player, bonus_info.content.result.index)

        assert(bonus_info.bonus_type)
        bonus_info.is_bonus_game = 1
    end

    CommonCal.Calculate.InitJackpotValues(player, save_data)
    bonus_info.jackpot_param = GetJakcpotParamToClient(save_data.jackpot_param)

    return bonus_info
end

local function CashRandSpecialItem(player, game_type, is_free_spin, game_room_config, reel_file)
    local type = _G[game_room_config.game_name .. "TypeArray"].Types
    local result = {}
    local weights = {1, 1, 1, 1, 1, 1, 1, 1}

    for i = 1, 3 do
        result[i] = {}
        for j = 1, 5 do
            local index = math.rand_weight(player, weights)
            table.insert(result[i], index)
        end
    end

    --添加scatter
    local config =
        CommonCal.Calculate.GetConfig(
        player,
        is_free_spin,
        "CashRainBaseScatterShowConfig",
        "CashRainFeatureScatterShowConfig"
    )

    local weights = {}
    for i = 0, #config do
        table.insert(weights, config[i].show_weight)
    end

    local index = math.rand_weight(player, weights)

    local scatter_count = config[index - 1].scatter_show_count

    for i = 1, scatter_count do
        local r = math.random_ext(player, 1, 3)
        local c = math.random_ext(player, 1, 5)
        result[r][c] = type.Scatter
    end

    --添加bonus
    local config =
        CommonCal.Calculate.GetConfig(
        player,
        is_free_spin,
        "CashRainBaseBonusShowConfig",
        "CashRainFeatureBonusShowConfig"
    )

    local weights = {}

    for i = 0, #config do
        if scatter_count >= 3 then
            table.insert(weights, config[i].trigger_scatter_show_weight)
        else
            table.insert(weights, config[i].not_trigger_scatter_show_weight)
        end
    end

    local index = math.rand_weight(player, weights) - 1
    local bonus_count = config[index].bonus_show_count

    return scatter_count, bonus_count
end

local function CashRandWinItem(i, player, game_type, is_free_spin, game_room_config, left_count)
    --先判定是否中奖
    local config =
        CommonCal.Calculate.GetConfig(player, is_free_spin, "CashRainBaseWinRateConfig", "CashRainFeatureWinRateConfig")
    local keys = {"first", "second", "third"}
    local keys2 = {"First", "Second"}

    local rate = config[1][keys[i] .. "_item_win_rate"]

    if math.rand_prob(player, rate) then
        --中奖
        --确定item_id
        local config =
            CommonCal.Calculate.GetConfig(
            player,
            is_free_spin,
            "CashRainBaseWinItemConfig",
            "CashRainFeatureWinItemConfig"
        )
        local index = CommonCal.Calculate.RandIndex(player, config, "win_weight")
        local item_id = config[index].item_id
        --确定个数
        local item_count = 5

        if left_count > 5 then
            local config =
                CommonCal.Calculate.GetConfig(
                player,
                is_free_spin,
                "CashRainBase" .. keys2[i] .. "WinConfig",
                "CashRainFeature" .. keys2[i] .. "WinConfig"
            )
            local weights = config[left_count].weight_of_win_count
            local index = math.rand_weight(player, weights)
            item_count = index + 4
        end

        return {item_id = item_id, item_count = item_count}
    end

    return nil
end

local function CashRandResult(player, game_type, is_free_spin, game_room_config, reel_file)
    local type = _G[game_room_config.game_name .. "TypeArray"].Types
    local scatter_count, bonus_count = CashRandSpecialItem(player, game_type, is_free_spin, game_room_config, reel_file)
    local left_count = 15 - scatter_count - bonus_count

    --随机3个中奖元素元素
    local items = {}

    local index = 1
    while left_count >= 5 do
        local item = CashRandWinItem(index, player, game_type, is_free_spin, game_room_config, left_count)
        if not item then
            break
        end
        left_count = left_count - item.item_count
        table.insert(items, item)
        index = index + 1
    end
    --通过上述信息生成result
    --首先顺序排列
    local result1d = {}
    for i = 1, scatter_count do
        table.insert(result1d, type.Scatter)
    end
    for i = 1, bonus_count do
        table.insert(result1d, type.Bonus)
    end

    local left_items = {1, 1, 1, 1, 1, 1, 1, 1}

    if is_free_spin then
        left_items[1] = 0
    end

    local item_id_counts = {0, 0, 0, 0, 0, 0, 0, 0}

    for i = 1, #items do
        left_items[items[i].item_id] = 0
        for j = 1, items[i].item_count do
            table.insert(result1d, items[i].item_id)
        end
    end
    local c = 15 - #result1d
    for i = 1, c do
        local id = math.rand_weight(player, left_items)
        table.insert(result1d, id)
        item_id_counts[id] = item_id_counts[id] + 1

        if item_id_counts[id] == 4 then
            left_items[id] = 0
        end
    end
    --随机打乱
    for i = 1, #result1d do
        local t = result1d[i]
        local j = math.random_ext(player, 1, #result1d)
        result1d[i] = result1d[j]
        result1d[j] = t
    end

    local result = {}
    local k = 1
    for i = 1, 3 do
        result[i] = {}
        for j = 1, 5 do
            result[i][j] = result1d[k]
            k = k + 1
        end
    end

    return result, scatter_count, bonus_count, items
end

local function CashGenPrizeInfo(final_result, game_room_config, payrate_file, left_or_right, type)
    local items = {}
    for i = 1, #final_result do
        for j = 1, #final_result[i] do
            local item_id = final_result[i][j]
            items[item_id] = items[item_id] or 0
            items[item_id] = items[item_id] + 1
        end
    end

    local config = CommonCal.Calculate.get_config(player, "CashRainPayrateConfig")

    local prize_items = {}
    local total_payrate = 0

    for item_id, count in pairs(items) do
        if config[item_id].payrate[count] and config[item_id].payrate[count] > 0 then
            local info = {
                item_id = item_id,
                payrate = config[item_id].payrate[count],
                continue_count = count
            }
            total_payrate = total_payrate + config[item_id].payrate[count]
            table.insert(prize_items, info)
        end
    end

    return prize_items, total_payrate
end

local function IsRevealItem(player, item_id, is_free_spin)
    local config = CommonCal.Calculate.get_config(player, "CashRainRevealItemConfig")
    
    if not config[item_id] then
        return false
    end

    if is_free_spin then
        return config[item_id].feature_show == 1
    end
    return config[item_id].base_show == 1
end

local function ChooseRevealItem(player, choose_win_item, result, prize_items, is_free_spin)
    if choose_win_item then
        local config = CommonCal.Calculate.get_config(player, "CashRainRevealCountConfig")
        --选择中奖的元素
        local items = {}
        local index = math.random_ext(player, 1, #prize_items)
        local item_id = prize_items[index].item_id
        local weights = {}

        for i, v in pairs(config) do
            if config[i].reveal_count <= prize_items[index].continue_count then
                table.insert(weights, {index = i, val = config[i].reveal_count_weight})
            end
        end

        table.sort(
            weights,
            function(a, b)
                return a.index < b.index
            end
        )

        local weights_ = {}
        for i = 1, #weights do
            table.insert(weights_, weights[i].val)
        end

        local index = math.rand_weight(player, weights_)
        local count = config[index].reveal_count

        if IsRevealItem(player, item_id, is_free_spin) then
            return item_id, count
        else
            return
        end
    end

    --未中奖元素
    --找出2个以上的
    local items = {}
    for i = 1, #result do
        for j = 1, #result[i] do
            local item_id = result[i][j]
            items[item_id] = items[item_id] or 0
            items[item_id] = items[item_id] + 1
        end
    end
    local item_infos = {}
    for item_id, count in pairs(items) do
        local is_legal = false

        if IsRevealItem(player, item_id, is_free_spin) then
            is_legal = true
        end

        if count >= 2 and is_legal then
            table.insert(
                item_infos,
                {
                    item_id = item_id,
                    count = count
                }
            )
        end
    end

    if #item_infos == 0 then
        return
    end

    local index = math.random_ext(player, #item_infos)
    local info = item_infos[index]
    return info.item_id, info.count
end

local function ResultRevealModify(
    game_room_config,
    player,
    player_game_info,
    result,
    win_chip,
    is_free_spin,
    prize_items)
    local type = _G[game_room_config.game_name .. "TypeArray"].Types
    local config =
        CommonCal.Calculate.GetConfig(
        player,
        is_free_spin,
        "CashRainBaseRevealRateConfig",
        "CashRainFeatureRevealRateConfig"
    )
    local rand_val = 0

    if win_chip > 0 then
        rand_val = config[1].win_reveal_rate
    else
        rand_val = config[1].no_win_reveal_rate
    end

    if not math.rand_prob(player, rand_val) then
        return
    end

    --选择中奖还是非中奖
    local choose_win_item = true
    if not math.rand_prob(player, config[1].if_win_item_rate) then
        choose_win_item = false
    end
    if #prize_items <= 0 then
        choose_win_item = false
    end
    --选择元素
    local item_id, count = ChooseRevealItem(player, choose_win_item, result, prize_items, is_free_spin)

    if not item_id then
        return
    end

    local reveal_info = {}

    table.iterate2d(
        result,
        function(i, j, id)
            if count == 0 then
                return
            end
            if item_id == id then
                result[i][j] = is_free_spin and type.CashReveal2 or type.CashReveal1
                table.insert(
                    reveal_info,
                    {
                        raw_item_id = item_id,
                        new_item_id = result[i][j],
                        row = i,
                        col = j
                    }
                )
                count = count - 1
            end
        end
    )

    return reveal_info, item_id
end

local function EnterSkyWheel(player, save_data, total_amount, pre_action_list, thunder_count, bonus_count)
    save_data.is_bonus_game = true
    table.insert(
        pre_action_list,
        {
            action_type = ActionType.ActionTypes.EnterBonus
        }
    )
end

local function AddRevealCol(player, save_data, reveal_item_id, item_ids, is_free_spin)
    save_data.reveal_item_id = save_data.reveal_item_id or 0
    reveal_item_id = reveal_item_id or 0

    local changed = false
    --如果字段发生变化，则改变保存的数据
    if reveal_item_id ~= 0 and save_data.reveal_item_id ~= reveal_item_id then
        save_data.reveal_item_id = reveal_item_id
        changed = true
    end

    local weights = {1, 1, 1, 1, 1, 1, 1, 1}
    
    if is_free_spin then
        weights = {0, 0, 0, 0, 1, 1, 1, 1}
    end

    --固定在第三个
    if save_data.reveal_item_id == 0 and not save_data.reveal_items then
        --说明是第一次
        save_data.reveal_items = {}
        for i = 1, 4 do
            local index = math.rand_weight(player, weights)
            weights[index] = 0
            table.insert(save_data.reveal_items, index)
        end
    elseif changed then
        save_data.reveal_items = {}
        weights[save_data.reveal_item_id] = 0

        for i = 1, 4 do
            local index = math.rand_weight(player, weights)
            weights[index] = 0
            table.insert(save_data.reveal_items, index)
        end
        save_data.reveal_items[3] = save_data.reveal_item_id
    end

    table.insert(item_ids, save_data.reveal_items)
end

local function CalcPosList(origin_result, prize_items)
    local pos_list = {}
    for i = 1, #prize_items do
        local item_id = prize_items[i].item_id
        for m = 1, #origin_result do
            for n = 1, #origin_result[m] do
                if origin_result[m][n] == item_id then
                    table.insert(pos_list, {row = m, col = n})
                end
            end
        end
    end
    return pos_list
end

function SlotsCashRainSpin:NormalSpin()
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
    local session = self.parameters.session
    local save_data = player_game_info.save_data

    local save_data = player_game_info.save_data
    local lineNum = LineNum[player_game_info.game_type]()
    local total_amount = lineNum * amount

    local type = _G[game_room_config.game_name .. "TypeArray"].Types
    player_game_info.bonus_game_type = 0

    local origin_result, scatter_count, bonus_count, items =
        CashRandResult(player, game_type, is_free_spin, game_room_config, reel_file)

    -- 行为记录
    local pre_action_list = {}
    local final_result = origin_result

    -- 赔率配置
    local payrate_file = CommonCal.Calculate.get_config(player, game_room_config.game_name .. "PayrateConfig")
    -- 连线规则, 1左连线，2右, 3左右连线

    -- 获得连线结果
    local prize_items, total_payrate =
        CashGenPrizeInfo(final_result, game_room_config, payrate_file, left_or_right, type, nil, nil, bet_ratio)

    local reel_ways_info = {}
    reel_ways_info.pos_list = CalcPosList(origin_result, prize_items)

    -- 将连线结果放入all_prize_list
    local all_prize_list = {}
    table.insert(all_prize_list, prize_items)

    -- slots赢取的筹码 = 倍率和 * 筹码
    local slots_win_chip = total_payrate * amount

    local reveal_info, reveal_id =
        ResultRevealModify(
        game_room_config,
        player,
        player_game_info,
        final_result,
        slots_win_chip,
        is_free_spin,
        prize_items
    )

    local reveal_item_id = reveal_id or 0

    if reveal_info and #reveal_info > 0 then
        --存在替换
        table.insert(
            pre_action_list,
            {
                action_type = ActionType.ActionTypes.RevealInfo,
                reveal_info = reveal_info,
                item_id = reveal_id
            }
        )
    end

    -- 赢取的总筹码,slots筹码+游戏等特殊筹码
    local total_win_chip = slots_win_chip

    --更新jackpot
    if not is_free_spin then
        assert(#save_data.jackpot_param == 4)
        CommonCal.Calculate.UpdateJackpotValues(player, save_data, total_amount, "CashRainJackpotConfig")
        table.insert(
            pre_action_list,
            {
                action_type = ActionType.ActionTypes.GameJackpotPool,
                jackpot_param = GetJakcpotParamToClient(save_data.jackpot_param)
            }
        )
    end

    -- FreeSpin判断处理
    local free_spin_bouts =
        SlotsGameCal.Calculate.FreeSpinCheck(player, final_result, game_room_config, is_free_spin, type.Scatter)

    if free_spin_bouts > 0 then
        GameStatusCal.Calculate.AddGameStatus(player_game_status, GameStatusDefine.AllTypes.FreeSpinGame, free_spin_bouts, 1, amount)
    end

    if bonus_count >= 3 then
        --进入大转盘
        EnterSkyWheel(player, save_data, total_amount, pre_action_list, thunder_count, bonus_count)
    end

    -- 最后一次数据记录
    local slots_spin_list = {}

    --处理最后发送总值总次数
    if (is_free_spin) then
        save_data.total_free_spin_times = save_data.total_free_spin_times or 0
        save_data.total_free_spin_times = save_data.total_free_spin_times + 1
    end

    if is_free_spin and player_game_info.free_spin_bouts == 0 and free_spin_bouts == 0 then
        player_game_info.free_total_win = player_game_info.free_total_win or 0
        local free_total_win = player_game_info.free_total_win + total_win_chip

        table.insert(
            pre_action_list,
            {
                action_type = ActionType.ActionTypes.TotalFreeSpinWin,
                free_total_win = free_total_win,
                total_free_spin_times = save_data.total_free_spin_times
            }
        )
    end

    local item_ids = SlotsGameCal.Calculate.TransResultToCList(origin_result, game_room_config)
    local final_item_ids = SlotsGameCal.Calculate.TransResultToCList(final_result, game_room_config)

    AddRevealCol(player, save_data, reveal_item_id, item_ids, is_free_spin)
    AddRevealCol(player, save_data, reveal_item_id, final_item_ids, is_free_spin)

    table.insert(
        slots_spin_list,
        {
            item_ids = json.encode(item_ids),
            prize_items = prize_items,
            win_chip = total_win_chip,
            pre_action_list = json.encode(pre_action_list),
            final_item_ids = json.encode(final_item_ids),
            ways_type = 1,
            reel_ways_info = json.encode(reel_ways_info)
        }
    )

    -- 客户端接收的表
    local formation_list = {}
    table.insert(formation_list, {slots_spin_list = slots_spin_list, id = 1})

    special_parameter = {
        reward_items = items
    }

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
