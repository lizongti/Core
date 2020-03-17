require "Common/SlotsGameCalculate"     --重写的接口
require "Common/SlotsGameCal"           --旧的接口
module("SlotsLeprechaunTreasureSpin", package.seeall)
--滚筒的数据类型
local gameTypes = {
    [1] = "Wild",               --钱罐
    [2] = "Scatter",            --四叶草
    [3] = "LeprechaunTreasure", --小矮人
    [4] = "Rainbow",            --彩虹
    [5] = "Horseshoe",          --马蹄铁
    [6] = "Stout",              --黑啤,烈性啤酒
    [7] = "Pipe",               --烟斗
    [8] = "A",
    [9] = "K",
    [10] = "Q",
    [11] = "J",
    [12] = "Ten", 
    [13] = "Nine", 
    Scatter = 2,
    WildList = {
        [1] = true
    },
    Wild = 1,
    Wilds = {
        [1] = 1
    },
}

--可连线数组
local Lines = {
	[1] = {2, 2, 2, 2, 2},
	[2] = {1, 1, 1, 1, 1},
	[3] = {3, 3, 3, 3, 3},
	[4] = {1, 2, 3, 2, 1},
    [5] = {3, 2, 1, 2, 3},
	[6] = {1, 1, 2, 1, 1},
	[7] = {3, 3, 2, 3, 3},
	[8] = {2, 3, 3, 3, 2},
	[9] = {2, 1, 1, 1, 2},
    [10] = {1, 2, 2, 2, 1},
    [11] = {3, 2, 2, 2, 3},
    [12] = {1, 2, 1, 2, 1},
    [13] = {3, 2, 3, 2, 3},
    [14] = {2, 1, 2, 1, 2},
    [15] = {2, 3, 2, 3, 2},
    [16] = {2, 2, 1, 2, 2},
    [17] = {2, 2, 3, 2, 2},
    [18] = {1, 3, 1, 3, 1},
    [19] = {3, 1, 3, 1, 3},
    [20] = {2, 1, 3, 1, 2},
}

GetLinesNum = function()
    return #Lines
end


Enter = function(task, player, game_room_config)
    local bonus_info = {}
    return bonus_info
end

Spin = function(player, game_type, is_free_spin, game_room_config, amount, player_feature_condition, extern_param)
    return SpinProcess(player, game_type, is_free_spin, game_room_config, amount, player_feature_condition, extern_param)
end

IsBonusGame = function(game_room_config, player)
    return false
end

SpinProcess = function(player, game_type, is_free_spin, game_room_config, amount, player_feature_condition, extern_param)
    -- LOG(RUN, INFO).Format("[LeprechaunTreasure][Spin] start !")
    --转动滚筒,获取结果
    local origin_result, reel_file_name = SlotsGameCal.Calculate.GenItemResult(player, game_type, is_free_spin, game_room_config)

    --赔率配置
    local payrate_config = CommonCal.Calculate.get_config(player, game_room_config.game_name.."PayrateConfig")
    --连线规则, 1左连线，2右, 3左右连线
    local left_or_right = game_room_config.direction_type

    --获得连线结果
    local prize_list, slots_payrate = SlotsGameCal.Calculate.GenPrizeInfoNew(origin_result, game_room_config, payrate_config, left_or_right, gameTypes, 2, Lines)

    --Scatter不参与连线
    local tmp_prize_list = {}
    for k, prize in pairs(prize_list)
    do
        if (prize.item_id ~= gameTypes.Scatter)
        then
            table.insert( tmp_prize_list, prize)
        end
    end
    prize_list = tmp_prize_list
    --Scatter不参与连线

    --判断这次是否出现了2个以上的Scatter
    local count = 0
    for k, list in pairs(origin_result) do
        for key, itemId in pairs(list) do
            if(itemId == gameTypes.Scatter)
            then
                count = count + 1
            end
        end
    end
    
    if(count > 1)
    then
        local scatter_payrate = (payrate_config[gameTypes.Scatter].payrate[count - 1]) * GetLinesNum()
        slots_payrate = slots_payrate + scatter_payrate
        local prize = {}
        prize.payrate = scatter_payrate
        prize.item_id = gameTypes.Scatter
        prize.continue_count = count
        prize.line_index = 1001                     --约定,用于屏幕上出现Scatter计算赔率
        prize.from_index = 1
        prize.to_index = 1
        table.insert(prize_list, prize)
    end
 
    --将连线结果放入all_prize_list
    local all_prize_list = {}
    table.insert(all_prize_list, prize_list)


    --slots赢取的筹码 = 倍率和 * 筹码
    local slots_win_chip = slots_payrate * amount 

    --特殊处理
    --这一次是FreeSpin则倍率 * 3
    if(is_free_spin)
    then
        slots_win_chip = slots_win_chip * 3
    end
    --特殊处理

    --FreeSpin判断处理
    local free_spin_bouts, free_item_id = SlotsGameCal.Calculate.GenFreeSpinCount(origin_result, game_room_config, gameTypes.Scatter)

    if(free_spin_bouts > 0)
    then 
        free_spin_bouts = 15
    end

    --赢取的总筹码,slots筹码+游戏等特殊筹码
    local total_win_chip = slots_win_chip

    --formation
    local item_ids = json.encode(SlotsGameCal.Calculate.TransResultToCList(origin_result, game_room_config))

    local slots_spin_info = {}
    local slots_spin_list = {}
    slots_spin_info.item_ids = item_ids
    slots_spin_info.prize_items = prize_list
    slots_spin_info.win_chip = total_win_chip
    table.insert(slots_spin_list, slots_spin_info)

    local formation_list = {}
    local formation_info = {}
    formation_info.id = 1
    formation_info.slots_spin_list = slots_spin_list
    table.insert(formation_list, formation_info)

    return origin_result, total_win_chip, all_prize_list, free_spin_bouts, formation_list, reel_file_name, slots_win_chip
end


getAllPrize = function(result, payrateConfig, leftOrRight)
    --总赔率
    local slots_payrate = 0
    local prize_list = {}
    --遍历所有的连线模式
    for line_index, line in pairs(Lines) do
        --检查指定连线模式,指定连线号下,当前摇出来的组合是否可以组成连线
        --返回连线结果{element1,element2,element3...},和这个连线结果中是否是左连
        local line_result, is_left = CheckOneLine(line, result, leftOrRight, gameTypes)

        if(line_result ~= nil)
        then
            --连线成功则计算倍率
            local prize = OneResultToPrize(line_result, line_index, is_left, gameTypes, payrateConfig)

            --连线中有Wild则这条线的赔率*2
            --特殊处理
            if(IsHaveWild(line_result, gameTypes))
            then
                prize["payrate"] = prize["payrate"] * 2
            end
            --特殊处理

            if(prize ~= nil)
            then
                --总赔率
                slots_payrate = slots_payrate + prize["payrate"]
                table.insert(prize_list, prize)
            end
        end
    end
    
    return prize_list, slots_payrate
end