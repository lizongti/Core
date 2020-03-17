require "Common/SlotsGameCalculate"     --重写的接口
require "Common/SlotsGameCal"           --旧的接口
---require "Common/ActionType"
module("SlotsPresidentTrumpSpin", package.seeall)


Enter = function(task, player, game_room_config)
    local bonus_info = {}
    return bonus_info
end

local ReplaceBlock = function(result_row)
    --后续替换规则可以改成可配置，而不是只能应用一种情况
    --LOG(RUN, INFO).Format("转换前：%s",Table2Str(result_row))
    local xLen=#result_row[1] --几列
    local yLen=#result_row    --几行
    for x=1,xLen do
        local block1Start=101
        local block2Start=111
        local num1=0
        local stop1=false
        local num2=0
        local stop2=false
        for y=1,yLen do
            if(result_row[y][x]==2)then
                result_row[y][x]=block1Start
                block1Start=block1Start+1
                if(stop1==false)then
                    num1=num1+1
                end
            else
                stop1=true
            end
            if(result_row[y][x]==3)then
                result_row[y][x]=block2Start
                block2Start=block2Start+1
                if(stop2==false)then
                    num2=num2+1
                end
            else
                stop2=true
            end
        end
        num1=yLen-num1
        num2=yLen-num2
        for n=1,num1 do
            for y=1,yLen do
                if(result_row[y][x]==2 or (result_row[y][x]>100 and result_row[y][x]<110))then
                    result_row[y][x]=101+ result_row[y][x]%yLen
                end
            end
        end
        for n=1,num2 do
            for y=1,yLen do
                if(result_row[y][x]==3 or (result_row[y][x]>110))then
                    result_row[y][x]=111+ (result_row[y][x]-10)%yLen
                end
            end
        end

    end
    --LOG(RUN, INFO).Format("转换后：%s",Table2Str(result_row))
    return result_row
end

Respin = function(player, is_free_spin, has_free_spin, slots_spin_list, game_room_config, result, lastTable, counter, loop_num, extern_param, player_feature_condition)
    local reel_file_name
    
    local pre_action_list = {}
    local parameter_list = {}
    --lastTable 注入到 当前结果中
    for i=1,#result do 
        for j=1,#result[1] do
            if(lastTable[i][j] == 2 or lastTable[i][j] == 3)then
                result[i][j] = lastTable[i][j]
            end
        end
    end

    if(counter <= 0)then 
        return has_free_spin, result, slots_spin_list
    end
    
    counter = counter - 1


    --再讲当前结果注入到lastTable
    for i = 1, #result do 
        for j = 1, #result[1] do
            if(result[i][j] == 2 or result[i][j] == 3)then
                if(lastTable[i][j] ~= 2 and lastTable[i][j] ~= 3)then
                    lastTable[i][j] = result[i][j]
                end
                table.insert(parameter_list,{j,i})
            end
        end
    end

    local tfResult=ReplaceBlock(result)
    table.insert(pre_action_list, {
        action_type = ActionType.ActionTypes.DaanLockItem,
        parameter_list=parameter_list,
    })
    local dd= json.encode(pre_action_list)
    table.insert(slots_spin_list, {
        item_ids = json.encode(SlotsGameCal.Calculate.TransResultToCList(tfResult, game_room_config)),
        prize_items = {},
        win_chip = 0,
        pre_action_list=dd,
    })

    if(SlotsGameCal.Calculate.GenFreeSpinCount(result,game_room_config,1,10)>0)then
        has_free_spin=true
    end

    ------201810310936开始------------------

    ------201810310936结束------------------
    loop_num = loop_num + 1

    result, reel_file_name = SlotsGameCal.Calculate.GenItemResult(player, game_room_config.game_type, is_free_spin, game_room_config, nil)
    return Respin(player, is_free_spin, has_free_spin, slots_spin_list, game_room_config, result, lastTable, counter, loop_num, extern_param, player_feature_condition)
end

local CheckMegaSpin = function(player, is_free_spin,slots_spin_list, game_room_config,result, extern_param, player_feature_condition)

    local lastTable={}

    for i=1,#result do

        local item= result[i][1]
        if(is_free_spin and item~=3)then
            return false,result,slots_spin_list
        end
        if(not is_free_spin and item~=2)then
            return false,result,slots_spin_list
        end
        table.insert(lastTable,{})
        for j=1,#result[i] do
            table.insert(lastTable[i],0)
        end
    end
    local loop_num = 1
    return Respin(player,is_free_spin,false,slots_spin_list,game_room_config,result,lastTable,3, loop_num, extern_param, player_feature_condition)
end

local SpinProcess = function(player, game_type, is_free_spin, game_room_config, amount, player_feature_condition, extern_param)

    ---这些是玩法开发用到的东西，直接复制吧---
    local total_win_chip, free_spin_bouts, slots_win_chip = 0, 0, 0
    local result_row ={}
    local all_prize_list={}

    local formation_list={}
    local reel_file_name
    ---------------------------------------
    local slots_spin_list = {}
    local type = _G[game_room_config.game_name.."TypeArray"].Types
    --特殊逻辑，在该玩法下，直接freespin时，川普老婆才是wild图标
    if(is_free_spin)then
        type.Wilds={2,3}
    else
        type.Wilds={2}
    end

    ------201810310936开始------------------
    if (player_feature_condition ~= nil)
    then
        player_feature_condition.spin_num = player_feature_condition.spin_num + 1
    end


    ------201810310936结束------------------

    result_row, reel_file_name = SlotsGameCal.Calculate.GenItemResult(player, game_room_config.game_type, is_free_spin, game_room_config, nil)
    
    -- --测试
    --  result_row[1][1]=3
    --  result_row[2][1]=3
    --  result_row[3][1]=3
    --  result_row[4][1]=7

    -- result_row[1][5]=2
    -- result_row[2][5]=6
    -- result_row[3][5]=7
    -- result_row[4][5]=2
    local has_free_spin
    has_free_spin,result_row,slots_spin_list=CheckMegaSpin(player,is_free_spin,slots_spin_list,game_room_config,result_row, extern_param, player_feature_condition)

    -- result_row[1][5]=6
    -- result_row[2][5]=3
    -- result_row[3][5]=3
    -- result_row[4][5]=3


    --计算大奖哦
    local left_or_right = game_room_config.direction_type
    local payrate_file = CommonCal.Calculate.get_config(player, game_room_config.game_name.."PayrateConfig")
    local prize_items, total_payrate = SlotsGameCal.Calculate.GenPrizeInfo(result_row, game_room_config, payrate_file, left_or_right, type)
    table.insert(all_prize_list,prize_items)
    --基础奖金
    slots_win_chip=total_payrate*amount
    total_win_chip=slots_win_chip
    
    --大图标处理，后续可以抽离出来公共接口，用于将大图标替换
    result_row=ReplaceBlock(result_row)
    
    --计算freespin次数
    if(has_free_spin)then
        free_spin_bouts=10
    else
        free_spin_bouts = SlotsGameCal.Calculate.GenFreeSpinCount(result_row,game_room_config,1,10)
    end




    table.insert(slots_spin_list, {
        item_ids = json.encode(SlotsGameCal.Calculate.TransResultToCList(result_row, game_room_config)),
        prize_items = prize_items,
        win_chip = total_win_chip,
        
    })
    table.insert(formation_list, {
        slots_spin_list=slots_spin_list,
        id = 1,
    })
    --参数解释V1.0，新玩法请直接复制，不要改名字，不然对不上了。。。。
    --     ↓结果数组↓↓  ↓↓↓↓总奖金↓↓↓↓  ↓↓所有连线列表↓  ↓freespin的次数↓  ↓↓什么什么列表↓  ↓↓↓reel表名↓↓↓  ↓↓↓↓经验↓↓↓↓  ↓↓↓转动奖金↓↓↓
    return result_row, total_win_chip, all_prize_list, free_spin_bouts, formation_list, reel_file_name, slots_win_chip
 end

Spin = function(player, game_type, is_free_spin, game_room_config, amount, player_feature_condition, chip_cost)
    return SpinProcess(player, game_type, is_free_spin, game_room_config, amount, player_feature_condition, chip_cost)
end
IsBonusGame = function(game_room_config, player)
    return false
end





