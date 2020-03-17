require "Common/SlotsGameCalculate"     --重写的接口
require "Common/SlotsGameCal"           --旧的接口
require "Common/LineNum"

SlotsTheSlotFatherSpin = {}

--入口
function SlotsTheSlotFatherSpin:Enter()
    local bonus_info = {}
    return bonus_info
end

local block_type = {1,2}

local function RecordFeature(game_room_config, pre_action_list, action_type, source_pos, des_pos,item_id, parameter_list)
    --行为记录
    local pre_action = {}
    pre_action.action_type = action_type
    pre_action.source_pos = json.encode(SlotsGameCal.Calculate.TransResultToCList(SlotsGameCal.Calculate.ReplaceBlock(source_pos,block_type), game_room_config))
    pre_action.des_pos = json.encode(SlotsGameCal.Calculate.TransResultToCList(SlotsGameCal.Calculate.ReplaceBlock(des_pos,block_type), game_room_config))
    pre_action.item_id = item_id
    pre_action.parameter_list = parameter_list
    table.insert(pre_action_list, pre_action)
    --LOG(RUN, INFO).Format("[TheSlotFather][RecordFeature] pre_action_list[%s]",Table2Str(pre_action_list))
    return pre_action_list
end

local function RandomWildsFeature(player, pre_action_list, game_room_config, result_row, type, feature_columes)
    -- LOG(RUN, INFO).Format("[TheSlotFather][ExpendingWildsFeature] Enter RandomWildsFeature")
    -- 获取配置表 取得对应触发概率
    local random_feature_config = CommonCal.Calculate.get_config(player, game_room_config.game_name.."RandomFeatureConfig")
    local random_feature_tab = {}
    for i = 1, #random_feature_config do
        table.insert(random_feature_tab, random_feature_config[i].probability)
    end
    --计算触发了哪一个条件对应的index
    local appear_index = math.rand_weight(player, random_feature_tab)
    local wild_number = random_feature_config[appear_index].wild_number
    local origin_result = table.DeepCopy(result_row)

    local parameter = {}
    parameter.type = 2
    parameter.value = wild_number
    parameter.postion = {}
    parameter.feature_columes = feature_columes
    local parameter_list = {}
    parameter_list.parameter = parameter
    --随机将其他wild_number个任意不为Wild图标变为Wild图标
    local random_time = 0
    while (wild_number > 0) do
        local col = math.random_ext(player, 1,5)
        local row = math.random_ext(player, 1,3)
        if not(SlotsGameCal.Util.IsWild(type, result_row[row][col])) then
            result_row[row][col] = type.Wild
            wild_number = wild_number - 1
            table.insert(parameter.postion,{wild_row=row,wild_col=col})
        end
        --防止死循环
        random_time = random_time + 1
        if(random_time > 100) then
            local not_is_wild_number = 0
            for i = 1, #result_row do
                for j = 1, #result_row[1] do
                    if not(SlotsGameCal.Util.IsWild(type, result_row[row][col])) then
                        not_is_wild_number = not_is_wild_number + 1
                    end
                end
            end
            if(not_is_wild_number < wild_number) then 
                wild_number = not_is_wild_number
            end
            random_time = 0
        end
    end
    --行为记录
    pre_action_list = RecordFeature(game_room_config, pre_action_list, 14, origin_result, result_row, type.Wild, parameter_list)
    return result_row, pre_action_list
end 

local function NudgeFeature(player,is_free_spin, pre_action_list, game_room_config, result_row, type, colume_num, last_show_row, type_id, counter_num)
    local trigger = false
    -- LOG(RUN, INFO).Format("[TheSlotFather][NudgeFeature] Enter NudgeFeature")
    -- 获取配置表 取得对应触发概率
    local nudge_feature_config = CommonCal.Calculate.get_config(player, game_room_config.game_name.."NudgeFeatureConfig")
    local probability = 0
    for k, v in ipairs(nudge_feature_config) do
        if(nudge_feature_config[k].symbol == type_id and nudge_feature_config[k].number == counter_num) then
            probability = nudge_feature_config[k].probability
            break
        end
    end
    if (GlobalSlotsTest[player.id] ~= nil) then
        if (GlobalSlotsTest[player.id].flag == 1) then
            probability = 1
        end
    end
    --freespin一定触发
    if is_free_spin then 
        probability = 1
    end
    --概率触发NudgeFeature
    if math.rand_event(player, probability) then
        local origin_result = table.DeepCopy(result_row)
        for i = 1, #result_row do
            result_row[i][colume_num] = type_id
        end
        trigger = true
        --行为记录
        local parameter = {}
        parameter.type = 1
        parameter.col = colume_num
        parameter.row = last_show_row
        parameter.move_time = #result_row - counter_num
        local parameter_list = {}
        parameter_list.parameter = parameter
        pre_action_list = RecordFeature(game_room_config, pre_action_list, 14, origin_result, result_row, type_id, parameter_list)
    end 
    return trigger, result_row, pre_action_list
end

local function ExpendingWildsFeature(player, is_free_spin, pre_action_list, game_room_config, result_row, type)
    --LOG(RUN, INFO).Format("[TheSlotFather][ExpendingWildsFeature] Enter ExpendingWildsFeature")
    local parameter = {}
    parameter.type = 3
    parameter.value = 3
    local parameter_list = {}
    --ExpendingWildsFeature判断   
    local counter = 0
    local last_show_row = 0
    for i = 1, #result_row do
        if(result_row[i][3] == type.GangMale) then
            counter = counter + 1
            last_show_row = i
        end
    end
    --LOG(RUN, INFO).Format("[TheSlotFather][ExpendingWildsFeature] GangMale counter[%d]",counter)
    --铺满触发ExpendingWildsFeature
    if counter == #result_row then
        local origin_result = table.DeepCopy(result_row)
        for i = 1, #result_row do
            result_row[i][2] = type.GangMale
            result_row[i][4] = type.GangMale
        end
        --行为记录
        parameter_list.parameter = parameter
        pre_action_list = RecordFeature(game_room_config,pre_action_list,14,origin_result,result_row,type.GangMale,parameter_list)
        return result_row, pre_action_list
    elseif counter > 0 then
        local trigger = false
        trigger, result_row, pre_action_list = NudgeFeature(player,is_free_spin, pre_action_list,game_room_config,result_row,type, 3, last_show_row, type.GangMale, counter)
        if(trigger) then
            local origin_result = table.DeepCopy(result_row)
            for i = 1, #result_row do
            result_row[i][2] = type.GangMale
            result_row[i][4] = type.GangMale
            end
            --行为记录            
            parameter_list.parameter = parameter
            pre_action_list = RecordFeature(game_room_config,pre_action_list,14,origin_result,result_row,type.GangMale,parameter_list)
        end
    end
    return result_row, pre_action_list
end

local function CheckRandomWildsFeature(player, is_free_spin, pre_action_list, game_room_config, result_row, type)
    --LOG(RUN, INFO).Format("[TheSlotFather][CheckRandomWildsFeature] Enter CheckRandomWildsFeature")
    --LOG(RUN, INFO).Format("[TheSlotFather][CheckRandomWildsFeature] result_row[%s]",Table2Str(result_row))
    -- RandomWildsFeature判断
    local feature_columes = {}
    for j = 1, #result_row[1] do
       local counter = 0
       local last_show_row = 0
       for i = 1, #result_row do
            if(result_row[i][j] == type.GangFemale) then
                counter = counter + 1
                last_show_row = i
            end
       end
       --LOG(RUN, INFO).Format("[TheSlotFather][CheckRandomWildsFeature] GangFemale counter[%d]",counter)
       if counter == #result_row then
            table.insert(feature_columes,j)
       elseif counter > 0 then
            local trigger = false
            trigger, result_row, pre_action_list = NudgeFeature(player,is_free_spin, pre_action_list,game_room_config,result_row,type, j, last_show_row, type.GangFemale, counter)
            if(trigger) then
                table.insert(feature_columes,j)
            end
       end
    end      
    return result_row, pre_action_list, feature_columes
end 
-----------------------------------------------
-- 点击Spin
------------------------------------------------
function SlotsTheSlotFatherSpin:NormalSpin()
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


    --对应GameConst里的TheSlotFatherTypeArray.Types
    local type = _G[game_room_config.game_name.."TypeArray"].Types   
    --转动滚筒,获取结果
    local origin_result, reel_file_name = SlotsGameCal.Calculate.GenItemResult(player, game_type, is_free_spin, game_room_config)
    --行为记录
    local pre_action_list = {}
    local final_result = table.DeepCopy(origin_result)
    --特殊逻辑
    local feature_columes = {}
    final_result, pre_action_list, feature_columes = CheckRandomWildsFeature(player, is_free_spin, pre_action_list, game_room_config, final_result, type)
    
    while(#feature_columes > 2) do
        origin_result, reel_file_name = SlotsGameCal.Calculate.GenItemResult(player, game_type, is_free_spin, game_room_config)
        pre_action_list = {}
        feature_columes_num = 0
        final_result = table.DeepCopy(origin_result)
        final_result, pre_action_list, feature_columes = CheckRandomWildsFeature(player, is_free_spin, pre_action_list, game_room_config, final_result, type)
        --LOG(RUN, INFO).Format("[TheSlotFather][SpinProcess] Too Much Feature And Respin Data")
    end
    --先触发RandomWildsFeature 再判断ExpendingWildsFeature
    if(#feature_columes > 0) then
        final_result, pre_action_list = RandomWildsFeature(player, pre_action_list, game_room_config, final_result, type, feature_columes)
    end
    final_result, pre_action_list = ExpendingWildsFeature(player, is_free_spin, pre_action_list, game_room_config, final_result, type)
    --LOG(RUN, INFO).Format("[TheSlotFather][SpinProcess] Finish Special Feature")

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

    if free_spin_bouts > 0 then
        GameStatusCal.Calculate.AddGameStatus(player_game_status, GameStatusDefine.AllTypes.FreeSpinGame, free_spin_bouts, 1, amount)
        if is_free_spin then
            local action_info = {
                action_type = ActionType.ActionTypes.FreeSpinTimesAdd,
                free_spin_bouts = free_spin_bouts
            }
            table.insert(pre_action_list, action_info)
        end
    end

    --LOG(RUN, INFO).Format("[TheSlotFather][SpinProcess] pre_action_list[%s]",Table2Str(pre_action_list))
    --最后一次数据记录
    local slots_spin_list = {}
    table.insert(slots_spin_list, {
        item_ids = json.encode(SlotsGameCal.Calculate.TransResultToCList(SlotsGameCal.Calculate.ReplaceBlock(origin_result,block_type), game_room_config)),
        prize_items = prize_items,
        win_chip = total_win_chip,
        slots_win_chip = slots_win_chip,
        pre_action_list = json.encode(pre_action_list),
        final_item_ids = json.encode(SlotsGameCal.Calculate.TransResultToCList(SlotsGameCal.Calculate.ReplaceBlock(final_result,block_type), game_room_config)),               
    })
    --客户端接收的表
    local formation_list={}
    table.insert(formation_list, {
        slots_spin_list=slots_spin_list,
        id = 1,
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

