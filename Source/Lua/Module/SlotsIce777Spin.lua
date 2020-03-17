require "Common/SlotsGameCalculate"     --重写的接口
require "Common/SlotsGameCal"           --旧的接口
module("SlotsIce777Spin", package.seeall)
----------------------------------------------------------------------------------------------
--Config
--滚筒的数据类型
local gameTypes = {
    [1] = "Red 7",              --红7
    [2] = "White 7",            --白7
    [3] = "T Bar",              --3个Bar
    [4] = "D Bar",              --2个Bar
    [5] = "Bar",                --1个Bar
    [6] = 2,                     --"2X Wild"
    [7] = 3,                     --"3X Wild"
    [8] = 4,                     --"4X Wild"
    [9] = "Empty",
    WildList = {
        [6] = true,
        [7] = true,
        [8] = true,
    },
}

--矩阵
local Formation = {
    [1] = 5,
    [2] = 5,
    [3] = 5,
}
--赔付规则
--元素必须一模一样
local sameElementPayrate1 = {
    elements = {6, 6, 6},
    payrate = 200
}
local sameElementPayrate2 = {
    elements = {6, 6, 7},
    payrate = 300
}
local sameElementPayrate3 = {
    elements = {6, 6, 8},
    payrate = 1000
}
local sameElementList = {sameElementPayrate1, sameElementPayrate2, sameElementPayrate3}
--3连,可以用Wild替换
local lineUseWild1 = {
    elements = {1},
    payrate = 25
}
local lineUseWild2 = {
    elements = {2},
    payrate = 15
}
local lineUseWild3 = {
    elements = {3},
    payrate = 10
}
local lineUseWild4 = {
    elements = {4},
    payrate = 5
}
local lineUseWild5 = {
    elements = {5},
    payrate = 3
}
--只包含其中元素,可以用Wild替换
local lineUseWild6 = {
    elements = {2, 5},
    payrate = 3
}

local lineUseWild7 = {
    elements = {2, 3, 4, 5},
    payrate = 2
}
local lineListUseWild = {lineUseWild1, lineUseWild2, lineUseWild3, lineUseWild4, lineUseWild5, lineUseWild6, lineUseWild7}
local PayrateConfig = {
    sameElementList = sameElementList,
    haveElementList = lineListUseWild,
}
--Config
----------------------------------------------------------------------------------------------
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
----------------------------------------------------------------------------------------------
local ice777ActionCheck = function(resultRow, nextRespin, isWildAnimation)
    --暂时是Ice777的特殊处理,可以考虑抽成回调,放在这里被调用
    local pre_action_list = {}
    -- print("ice777ActionCheck")

    Print_r(pre_action_list)

    if (nextRespin) then
        local pre_action = {}
        --action_type
        pre_action.action_type = 9
        
        --parameter_list
        local parameter = {}
        local parameter_list = {}
        table.insert(parameter_list, parameter)
        pre_action.parameter_list = parameter_list

        table.insert(pre_action_list, pre_action)
    end

    Print_r(resultRow)
    --前两个元素是相同的7
    if ((resultRow[3][1] == 1 or resultRow[3][1] == 2) and (resultRow[3][1] == resultRow[3][2])) then
        local pre_action = {}
        --action_type
        pre_action.action_type = ActionType.ActionTypes.TakePhoto --11
        
        --parameter_list
        local parameter = {}
        local parameter_list = {}
        table.insert(parameter_list, parameter)
        pre_action.parameter_list = parameter_list

        table.insert(pre_action_list, pre_action)

    end

    Print_r(resultRow)
    if (isWildAnimation) then
        local pre_action = {}
        --action_type
        pre_action.action_type = 12
        
        --parameter_list
        local parameter = {}
        local parameter_list = {}
        table.insert(parameter_list, parameter)
        pre_action.parameter_list = parameter_list

        table.insert(pre_action_list, pre_action)

    end

    Print_r(pre_action_list)
    if (#pre_action_list > 0) then
        return json.encode(pre_action_list)
    end

    return nil
end



--777模式中只有固定1条线,并且在前端不需要展示连线
local getPrizeList = function(middleRow, payrate, is_wild_prize)
    local pos_list = {}
    if (is_wild_prize)
    then
        ----------只有wild中奖，在第三行中查找wild,将wild所在位置发给客户端
       for k, v in pairs(middleRow)
       do
            if (v == 6 or v == 7 or v == 8)
            then
                table.insert(pos_list, k)
            end
       end
    else
        ---------不是wild中奖，在第三行将非空元素所在位置发给客户端
        for k, v in pairs(middleRow)
        do
             if (v ~= 9)
             then
                 table.insert(pos_list, k)
             end
        end
    end
    local prize_list = {}
    local prize = {
        item_id = 0,
        continue_count = 0,
        payrate = payrate,
        line_index = 1,
        from_index = 0,
        to_index = 0,
        pos_list = json.encode(pos_list),
    }
    table.insert(prize_list, prize)
    return prize_list
end

--spinType指代这一次是否是Respin,FreeSpin等状态
local saveSpinInfo = function(resultRow, payrate, amount, slotsSpinList, allPrizeList, gameRoomConfig, nextRespin, isWildAnimation, is_wild_prize)
    local prize_list = getPrizeList(resultRow[3], payrate, is_wild_prize)

    --记录所有连线结果
    table.insert(allPrizeList, prize_list)

    --将行排序数组还原成列排序
    local result_column = SlotsGameCal.Calculate.TransResultToCList(resultRow, gameRoomConfig)

    --记录SpinInfo
    local slots_spin_info = {}

    slots_spin_info.item_ids = json.encode(result_column) 
    -- slots_spin_info.item_ids = result_column

    
    slots_spin_info.win_chip = amount * payrate

    if (slots_spin_info.win_chip > 0)
    then
        slots_spin_info.prize_items = prize_list
    end


    --特殊处理,需要提取归类
    local pre_action_list_data = ice777ActionCheck(resultRow, nextRespin, isWildAnimation)
    if ((pre_action_list_data ~= nil)) and (#pre_action_list_data > 0) then
        slots_spin_info.pre_action_list = pre_action_list_data
    end

    table.insert(slotsSpinList, slots_spin_info)
end

local getAllSlotsSinChip = function(slotsSpinList)
    local slots_win_chip = 0
    for key, slots_spin_info in pairs(slotsSpinList)
    do
        slots_win_chip = slots_win_chip + slots_spin_info.win_chip
    end
    return slots_win_chip
end
----------------------------------------------------------------------------------------------
--检查中间一行是否是3个Wild,个数为3
local checkMiddle3Wild = function(middleElements)
    for key, element_config in ipairs(PayrateConfig.sameElementList)
    do
        if (GameSlots777.CheckElementsHaveAll(middleElements, element_config.elements))
        then
            return element_config.payrate
        end
    end
    return 0
end

--检查中间行的普通判定(3连, 包含指定元素等.可以用Wild替代)
local checkMiddleNormal = function(middleElements)
    for key, element_config in ipairs(PayrateConfig.haveElementList)
    do
        if (GameSlots777.CheckElementsAndWild(middleElements, element_config.elements, gameTypes))
        then
            return element_config.payrate
        end
    end
    return 0
end
----------------------------------------------------------------------------------------------
--中间一行是有Wild的处理
local middleHaveWild = function(resultRow, middleElements, amount, wildPayrate, slotsSpinList, allPrizeList, gameRoomConfig, nextRespin, isWildAnimation)
    -- print("3Wild赔付判定:", middleElements[1], middleElements[2], middleElements[3])
    --3Wild赔付判定
    tmp_payrate = checkMiddle3Wild(middleElements)
    -- print("tmp_payrate 3Wild:", tmp_payrate)
    if (tmp_payrate > 0)
    then
        saveSpinInfo(resultRow, tmp_payrate, amount, slotsSpinList, allPrizeList, gameRoomConfig, nextRespin, isWildAnimation, false)
        --3Wild判定成功则直接退出
        return
    end

    --3连和包含判定
    tmp_payrate = checkMiddleNormal(middleElements)
    -- print("tmp_payrate Normal:", tmp_payrate)
    if (tmp_payrate > 0)
    then
        --普通的赔付需要加上Wild赔付
        tmp_payrate = tmp_payrate * wildPayrate
        saveSpinInfo(resultRow, tmp_payrate, amount, slotsSpinList, allPrizeList, gameRoomConfig, nextRespin, isWildAnimation, false)
        return
    end

    saveSpinInfo(resultRow, wildPayrate, amount, slotsSpinList, allPrizeList, gameRoomConfig, nextRespin, isWildAnimation, true)
end

--中间一行Wild检查
--中间一行如果出现了Wild,会进行Respin
--在Respin之前,有可能会有特殊动画,进行一次额外的Wild选择
local checkMiddleRow = function(resultRow, amount, slotsSpinList, allPrizeList, gameRoomConfig, nextRespin, isWildAnimation)
    local wild_payrate = 1
    --获得中间一行的元素
    local middle_row = resultRow[3]
    --Wild会有自己的单个赔付,若是普通的赔付需要加上Wild的赔付;3Wild不需要
    for key, element in ipairs(middle_row)
    do
        if (gameTypes.WildList[element])
        then
            wild_payrate = wild_payrate * gameTypes[element]
        end
    end
    -- print("wild_payrate:", wild_payrate)

    if (wild_payrate > 1)
    --有Wild赔付则证明这一行里面有Wild
    then
        --包含Wild赔付的处理
        middleHaveWild(resultRow, middle_row, amount, wild_payrate, slotsSpinList, allPrizeList, gameRoomConfig, nextRespin, isWildAnimation)
        return
    end

    --不包含Wild,只用走普通赔付
    local tmp_payrate = checkMiddleNormal(middle_row)

    saveSpinInfo(resultRow, tmp_payrate, amount, slotsSpinList, allPrizeList, gameRoomConfig, nextRespin, isWildAnimation, false)

    --没有赔付
end
----------------------------------------------------------------------------------------------
--ReSpin一次
local reSpinOnce = function(middleColumn, amount, slotsSpinList, allPrizeList, player, gameRoomConfig, isFreeSpin, nextRespin, feature_file)
    --转动滚筒,再次获得结果
    --初始结果是行排序数组
    local result_row, reel_file_name = SlotsGameCal.Calculate.GenItemResult(player, gameRoomConfig.game_type, isFreeSpin, gameRoomConfig, feature_file)

    -- print("ReSpin结果替换前")
    -- Print_r(result_row)

    --ReSpin时,中间一列锁住,不会重新转动
    --替换中间一列的数据,替换为原始数组
    result_row[1][2] = middleColumn[1]
    result_row[2][2] = middleColumn[2]
    result_row[3][2] = middleColumn[3]
    result_row[4][2] = middleColumn[4]
    result_row[5][2] = middleColumn[5]
    -- print("ReSpin结果替换后")
    -- Print_r(result_row)
    --对中间一行进行检查,并将结果放入slotsSpinList
    checkMiddleRow(result_row, amount, slotsSpinList, allPrizeList, gameRoomConfig, nextRespin, false)
    -- Print_r(slots_spin_list)
end

--ReSpin逻辑
local reSpin = function(result_row, amount, slotsSpinList, allPrizeList, player, gameRoomConfig, isFreeSpin, extern_param, player_feature_condition)
    --检查是否需要ReSpin
    local reSpin_key = result_row[3][2]
    -- print("ReSpin Key:", reSpin_key)
    if (not gameTypes.WildList[reSpin_key])
    then
        return
    end

    --获取中间一列
    local middle_Column = SlotsGameCal.Calculate.TransResultToCList(result_row, gameRoomConfig)[2]
    -- print("middle_Column", middle_Column[1], middle_Column[2], middle_Column[3], middle_Column[4], middle_Column[5])

    --2XWild ReSpin3次,3XWild ReSpin2次,4XWild ReSpin1次
    --根据Wild进行ReSpin
    local loop_num = 1
    for i = reSpin_key, 8, 1
    do
        local next_respin = false
        if (i < 8) then
            next_respin = true
        else
            next_respin = false
        end
        CommonCal.Calculate.SetLoopNum(player.id, loop_num)
        loop_num = loop_num + 1


        --进行ReSpin
        reSpinOnce(middle_Column, amount, slotsSpinList, allPrizeList, player, gameRoomConfig, isFreeSpin, next_respin, nil)
    end
    -- Print_r(slots_spin_list)
end
----------------------------------------------------------------------------------------------
SpinProcess = function(player, game_type, is_free_spin, game_room_config, amount, player_feature_condition, extern_param)
    local total_win_chip, free_spin_bouts, slots_win_chip = 0, 0, 0
    local slots_spin_list = {}
    local all_prize_list = {}
    local formation_list = {}

    ------201810310936开始------------------

    if (player_feature_condition ~= nil)
    then
        player_feature_condition.spin_num = player_feature_condition.spin_num + 1
    end

    ------201810310936结束------------------

    --转动滚筒,获取初始结果
    --初始结果是行排序数组
    local result_row, reel_file_name = SlotsGameCal.Calculate.GenItemResult(player, game_room_config.game_type, is_free_spin, game_room_config, nil)
    -- result_row = {
    --     {9,4,4},
    --     {6,9,9},
    --     {5,3,4},
    --     {5,9,9},
    --     {9,5,3},
    -- }
    -- Print_r(result_row)

    local nextRespin = false
    if (gameTypes.WildList[result_row[3][2]]) then
        nextRespin = true
    end
    --对中间一行进行检查,并将结果放入slotsSpinList
    checkMiddleRow(result_row, amount, slots_spin_list, all_prize_list, game_room_config, nextRespin, nextRespin)
    -- print("1")
    -- Print_r(slots_spin_list)
    
    --检查ReSpin
    reSpin(result_row, amount, slots_spin_list, all_prize_list, player, game_room_config, is_free_spin, extern_param, player_feature_condition)
    -- print("2")
    -- Print_r(slots_spin_list)
    --游戏赢取筹码-Slots部分
    slots_win_chip = getAllSlotsSinChip(slots_spin_list)
    --游戏赢取筹码-所有
    total_win_chip = slots_win_chip
    -- print("3")
    -- Print_r(slots_spin_list)
    --formation
    local formation_list = {}
    local formation_info = {}
    formation_info.id = 1
    formation_info.slots_spin_list = slots_spin_list
    table.insert(formation_list, formation_info)
    return result_row, total_win_chip, all_prize_list, free_spin_bouts, formation_list, reel_file_name, slots_win_chip
end