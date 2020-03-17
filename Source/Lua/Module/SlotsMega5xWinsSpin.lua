require "Common/SlotsGameCalculate"     --重写的接口
require "Common/SlotsGameCal"           --旧的接口
module("SlotsMega5xWinsSpin", package.seeall)
----------------------------------------------------------------------------------------------
--Config
--滚筒的数据类型
local gameTypes = {
    [1] = "Red 7",              --红7
    [2] = "Black 7",            --黑7
    [3] = "Violet 7",           --紫7
    [4] = "V7&Bar",             --紫7和1个Bar
    [5] = "Bar",                --1个Bar
    [6] = "DBar",               --2个Bar
    [7] = "TBar",               --3个Bar
    [8] = 2,                    --wild2                
    [9] = 3,                    --wild3
    [10] = 4,                   --wild4
    [11] = 5,                   --wild5
    [12] = "Empty",
    WildList = {
        [8]  = true,
        [9]  = true,
        [10] = true,
        [11] = true,
    },
}

--1:不需要替换wild，
--2:1个Wildx2,
--3:1个Wildx3,
--4:1个Wildx4,
--5:1个Wildx5,
--6:2个Wildx2,
--7:Wildx2 and Wildx3,
--8:Wildx2 and Wildx4,
--9:Wildx2 and Wildx5,
--10:Wildx2 and Wildx3 and Wildx2,
--11:Wildx2 and Wildx4 and Wildx2,
--12:Wildx2 and Wildx5 and Wildx2
local ReplaceWild = {
    [1] = nil,
    [2] = {[8] = 1},
    [3] = {[9] = 1},
    [4] = {[10] = 1},
    [5] = {[11] = 1},
    [6] = {[8] = 1, [8] = 1},
    [7] = {[8] = 1, [9] = 1},
    [8] = {[8] = 1, [10] = 1},
    [9] = {[8] = 1, [11] = 1},
    [10] = {[8] = 1, [9] = 1, [8] = 1},
    [11] = {[8] = 1, [10] = 1, [8] = 1},
    [12] = {[8] = 1, [11] = 1, [8] = 1}
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
    elements = {8, 8, 9},
    payrate = 300
}
local sameElementPayrate2 = {
    elements = {8, 8, 10},
    payrate = 400
}
local sameElementPayrate3 = {
    elements = {8, 8, 11},
    payrate = 1000
}
local sameElementList = {sameElementPayrate1, sameElementPayrate2, sameElementPayrate3}
--3连,可以用Wild替换
local lineUseWild1 = {
    elements = {1},
    payrate = 20
}
local lineUseWild2 = {
    elements = {2},
    payrate = 15
}
local lineUseWild3 = {
    elements = {3},
    payrate = 12
}
local lineUseWild4 = {
    elements = {4},
    payrate = 10
}
local lineUseWild5 = {
    elements = {7},
    payrate = 5
}
local lineUseWild6 = {
    elements = {6},
    payrate = 4
}
local lineUseWild7 = {
    elements = {5},
    payrate = 3
}

--只包含其中元素,可以用Wild替换
local lineUseWild8 = {
    elements = {1, 2, 3, 4},
    payrate = 3
}

local lineUseWild9 = {
    elements = {5, 4},
    payrate = 3
}

local lineUseWild10 = {
    elements = {7, 6, 5, 4},
    payrate = 3
}
local lineListUseWild = {lineUseWild1, lineUseWild2, lineUseWild3, lineUseWild4, lineUseWild5, lineUseWild6, lineUseWild7, lineUseWild8, lineUseWild9, lineUseWild10}
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
local Mega5xWinsActionCheck = function(resultRow, nextRespin, isWildAnimation)
    --暂时是Mega5xWins的特殊处理,可以考虑抽成回调,放在这里被调用
    local pre_action_list = {}
    --print("Mega5xWinsActionCheck")

    --Print_r(pre_action_list)
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

    --Print_r(resultRow)
    --前两个元素是相同的7
    if ((resultRow[3][1] == 1 or resultRow[3][1] == 2) and (resultRow[3][1] == resultRow[3][2])) then
        local pre_action = {}
        --action_type
        pre_action.action_type = 11
        
        --parameter_list
        local parameter = {}
        local parameter_list = {}
        table.insert(parameter_list, parameter)
        pre_action.parameter_list = parameter_list

        table.insert(pre_action_list, pre_action)

    end

    --Print_r(resultRow)
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

    --Print_r(pre_action_list)
    if (#pre_action_list > 0) then
        return json.encode(pre_action_list)
    end

    return nil
end

--只有固定1条线,并且在前端不需要展示连线
local getPrizeList = function(middleRow, payrate, is_wild_prize)
    local pos_list = {}
    if (is_wild_prize)
    then
        ----------只有wild中奖，在第三行中查找wild,将wild所在位置发给客户端
       for k, v in pairs(middleRow)
       do
            if (v == 8 or v == 9 or v == 10 or v == 11)
            then
                table.insert(pos_list, k)
            end
       end
    else
        ---------不是wild中奖，在第三行将非空元素所在位置发给客户端
        for k, v in pairs(middleRow)
        do
             if (v ~= 12)
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

    slots_spin_info.item_ids = json.encode(result_column)     --怀疑是C++接口,模拟器中暂时屏蔽
    -- slots_spin_info.item_ids = result_column

    slots_spin_info.win_chip = amount * payrate

    if (slots_spin_info.win_chip > 0) then
        slots_spin_info.prize_items = prize_list
    end

    --特殊处理,需要提取归类
    local pre_action_list_data = Mega5xWinsActionCheck(resultRow, nextRespin, isWildAnimation)
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
--检查中间一行是否是3个Wild
local checkMiddle3Wild = function(middleElements)
    for key, element_config in ipairs(PayrateConfig.sameElementList)
    do
        if (GameSlotsMega5xWins.CheckElementsHaveAll(middleElements, element_config.elements))
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
        if (GameSlotsMega5xWins.CheckElementsAndWild(middleElements, element_config.elements, gameTypes))
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
local reSpinOnce = function(middleColumn, amount, slotsSpinList, allPrizeList, player, gameRoomConfig, isFreeSpin, nextRespin)
    --转动滚筒,再次获得结果
    --初始结果是行排序数组
    local result_row, reel_file_name = Mega5xWinsItemResult(player, gameRoomConfig)

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
local reSpin = function(result_row, amount, slotsSpinList, allPrizeList, player, gameRoomConfig, isFreeSpin)
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
        reSpinOnce(middle_Column, amount, slotsSpinList, allPrizeList, player, gameRoomConfig, isFreeSpin, next_respin)
    end
    -- Print_r(slots_spin_list)
end

local Mega5xWinsItemResult = function(player, game_room_config, feature_file)

    --获取中间一行的数据
    local reel_rate_list = {}
    local Mega5xWinsReelResultConfig = CommonCal.Calculate.get_config(player, "Mega5xWinsReelResultConfig")
    for k, v in ipairs(Mega5xWinsReelResultConfig)
    do
        reel_rate_list[k] = v.rate
    end

    local id = math.rand_weight(player, reel_rate_list)


   -- print("id is:"..id)
    local reel_value = Mega5xWinsReelResultConfig[id]

    local item_array = table.DeepCopy(reel_value.item_array)
    --print("reel_value is:")
    --Print_r(reel_value)

    local tran_result = nil
    if (item_array[1] ~= 0 and item_array[2] ~= 0 and item_array[3] ~= 0)--中奖
    then
        -------获取其他四行
        local file_name = "Mega5xWinsSpinReelConfig"
		if (feature_file ~= nil and feature_file ~= "")
        then
            file_name = feature_file
		end

        local Mega5xWinsNorewardsReelConfig = CommonCal.Calculate.get_config(player, file_name)

        local formation = _G[game_room_config.game_name.."FormationArray"].Formation1


        local result = {}
        for v = 1, #formation, 1 do
            local localResult
            
            localResult = SlotsGameCal.Calculate.GenColumn(player, Mega5xWinsNorewardsReelConfig, v, game_room_config)
            result[v] = localResult
        end
        
        tran_result = SlotsGameCal.Calculate.TransResult(result, game_room_config)

        --print("tran_result is:")
        --Print_r(tran_result)
    else
        -------获取其他四行
        local file_rand = {[1] = 1, [2] = 1, [3] = 1}
        local index = math.rand_weight(player, file_rand)

        local file_name = "Mega5xWinsNorewardsReel"..index.."Config"
		if (feature_file ~= nil and feature_file ~= "")
        then
            file_name = feature_file
		end

        local Mega5xWinsNorewardsReelConfig = CommonCal.Calculate.get_config(player, file_name)

        local formation = _G[game_room_config.game_name.."FormationArray"].Formation1

        local result = {}
        for v = 1, #formation, 1 do
            local localResult
            
            localResult = SlotsGameCal.Calculate.GenColumn(player, Mega5xWinsNorewardsReelConfig, v, game_room_config)
            result[v] = localResult
        end
        
        tran_result = SlotsGameCal.Calculate.TransResult(result, game_room_config)

        --print("tran_result is:")
        --Print_r(tran_result)
    end

    if (feature_file ~= nil and feature_file ~= "")
    then
        tran_result = {
            {8, 11, 6},
            {12, 12, 12},
            {1, 1, 1},
            {12, 12, 12},
            {4, 5, 2},
        }
    end

    if (GlobalSlotsTest[player.id] == nil or feature_file == nil or feature_file == "")
    then
        --中奖，替换中间一行
        if (item_array[1] ~= 0 and item_array[2] ~= 0 and item_array[3] ~= 0)
        then
            local rand_pos = {[1] = 1, [2] = 1, [3] = 1}
            if (reel_value.order == 0)--随机变换位置
            then
                local tmp_value = {}
                for index = 1, 3, 1
                do
                    local pos = math.rand_weight(player, rand_pos)
                    tmp_value[index] = item_array[pos]
                    rand_pos[pos] = 0
                end

                item_array = tmp_value
            end

            --是否需要替换wild
            local rate_list = {}
            local rate_num = 0
            for k, v in ipairs(reel_value.wildList)
            do
                if (v > 0 and v < 1)
                then
                    rate_num = rate_num + 1
                end
                if (v < 1)
                then
                    rate_list[k] = v
                end
            end

            if (rate_num > 0)
            then
                local wild_type = math.rand_weight(player, rate_list)
                
                local replace_wild = ReplaceWild[wild_type]
                if (replace_wild ~= nil)
                then
                    --wildx3,wildx4,wildx5只会出现在第2列
                    local tmp_wild = {}
                    for k, v in pairs(replace_wild)
                    do
                        if (k > 8)
                        then
                            tmp_wild[2] = k
                            break--只会出现一次
                        end
                    end

                    local rand_pos = {[1] = 1, [3] = 1}
                    if (tmp_wild[2] == nil)
                    then
                        rand_pos[2] = 1
                    end

                    --wildx2可以在3列出现
                    local tmp_num = 0
                    for k, v in pairs(replace_wild)
                    do
                        if (k == 8)
                        then
                            local pos = math.rand_weight(player, rand_pos)
                            tmp_wild[pos] = k
                            rand_pos[pos] = 0                    
                        end
                    end

                    for k, v in pairs(tmp_wild)
                    do
                        item_array[k] = v
                    end

                end
                
            end

            tran_result[3] = item_array
        end


        --print("Mega5xWinsItemResult begin3")
        for col = 1, 3, 1
        do
            if (tran_result[3][col] ~= 12)
            then
                tran_result[2][col] = 12
                tran_result[4][col] = 12
            else
                local rand_item_id = {[1] = 1, [2] = 1, [3] = 1, [4] = 1, [5] = 1, [6] = 1, [7] = 1}
                tran_result[2][col] = math.rand_weight(player, rand_item_id)   
                tran_result[4][col] = math.rand_weight(player, rand_item_id)  
            end

            if (tran_result[2][col] ~= 12)
            then
                tran_result[1][col] = 12
            else
                local rand_item_id = {[1] = 1, [2] = 1, [3] = 1, [4] = 1, [5] = 1, [6] = 1, [7] = 1}
                tran_result[1][col] = math.rand_weight(player, rand_item_id)   
            end

            if (tran_result[4][col] ~= 12)
            then
                tran_result[5][col] = 12
            else
                local rand_item_id = {[1] = 1, [2] = 1, [3] = 1, [4] = 1, [5] = 1, [6] = 1, [7] = 1}
                tran_result[5][col] = math.rand_weight(player, rand_item_id)   
            end
        end
    end
 

    --print("Mega5xWinsItemResult begin4")
    --print("finally tran_result is:")
    --Print_r(tran_result)
    return tran_result, "Mega5xWinsNorewardsReel"
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
    local result_row, reel_file_name = Mega5xWinsItemResult(player, game_room_config, nil)
    -- result_row = {
    --     {9,4,4},
    --     {6,9,9},
    --     {5,3,4},
    --     {5,9,9},
    --     {9,5,3},
    -- }
    -- Print_r(result_row)

    local nextRespin = false
    --if (gameTypes.WildList[result_row[3][2]]) then
    --    nextRespin = true
    --end
    --对中间一行进行检查,并将结果放入slotsSpinList
    checkMiddleRow(result_row, amount, slots_spin_list, all_prize_list, game_room_config, nextRespin, nextRespin)
    -- print("1")
    -- Print_r(slots_spin_list)
    
    --检查ReSpin
    --reSpin(result_row, amount, slots_spin_list, all_prize_list, player, game_room_config, is_free_spin)
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
    --print("formation_list")
    --Print_r(formation_list)
    return result_row, total_win_chip, all_prize_list, free_spin_bouts, formation_list, reel_file_name, slots_win_chip
end