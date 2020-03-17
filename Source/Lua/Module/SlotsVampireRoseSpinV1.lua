require "Common/SlotsGameCalculate" --重写的接口
require "Common/SlotsGameCal" --旧的接口
require "Common/SlotsVampireRoseCal" --专用的函数
require "dkjson"
module("SlotsVampireRoseSpinV1", package.seeall)

--变量缓存
--spin类型
local SPIN_ENUM = {
    BASE_SPIN = 1, --基础spin
    FREE_SPIN = 2 --free_Spin
}
--Bonus类型
local BONUS_ENUM = {
    SPIN_BONUS = 1 --选择spin类型的小游戏
}
--奖励类型
local PRIZE_TYPE_ENUM = {
    JAKCPOT = 1
}

--计算辅助类缓存
local my_cal = VampireRoseCalClass

--入口
Enter = function(task, player, game_room_config, player_game_info)
    --返回数据初始化
    local bonus_info = {}

    --部分变量缓存
    local game_name = game_room_config.game_name --游戏名字
    --读取缓存数据
    local save_data = my_cal:GetSaveData(player, player_game_info, game_name, SPIN_ENUM, PRIZE_TYPE_ENUM) --检查缓存数据的完整性
    --返回数据计算
    local spin_bouts = -1
    if save_data.curr_spin_type == SPIN_ENUM.HOLD_SPIN then
        spin_bouts = save_data.hold_spin_param.bouts
    elseif save_data.curr_spin_type == SPIN_ENUM.FREE_SPIN then
        spin_bouts = save_data.free_spin_param.bouts
    end
    --返回数据填入
    bonus_info = {
        in_bonus_game = player_game_info.bonus_game_type > 0,
        bonus_game_type = player_game_info.bonus_game_type,
        curr_spin_type = save_data.curr_spin_type,
        spin_bouts = spin_bouts,
        reel_info_arr = save_data.reel_info_arr,
        jackpot_param = CommonCal.Calculate.GetJakcpotParamToClient(save_data.jackpot_param_v2),
        free_spin_multiple_times = save_data.free_spin_param.multiple_times
    }
    --保存缓存数据
    my_cal:RecordSaveData(player_game_info, save_data)

    --返回
    return bonus_info
end

--是否含有小游戏
IsBonusGame = function(game_room_config, player, player_game_info)
    return player_game_info.bonus_game_type > 0
end

--------------------------------------------------
--*********************Spin***********************
local SpinProcess = function(
    player,
    game_type,
    is_free_spin,
    game_room_config,
    amount,
    player_feature_condition,
    extern_param,
    player_game_info)
    -------------------------------

    --部分变量缓存
    local game_name = game_room_config.game_name --游戏名字
    local ITEM_ENUM = _G[game_name .. "TypeArray"].Types --图标的枚举
    local jackpot_config = CommonCal.Calculate.get_config(player, game_name .. "JackpotConfig")

    --读取缓存数据
    local save_data = my_cal:GetSaveData(player, player_game_info, game_name, SPIN_ENUM, PRIZE_TYPE_ENUM) --检查缓存数据的完整性

    --确定spin的特性
    local pre_action_list = {} --传给客户端的动作
    local add_free_spin_bouts = 0 --本次spin中增加的reels_spin次数
    local reel_file_name  --reel表名
    local total_win_chip = 0 --本次spin的赢钱

    --确定投注额度
    local reel_line_name = save_data.reel_info_arr[1].line_name
    local lineNum = #(_G[game_name .. "LineArray"][reel_line_name]) --线数
    if (save_data.curr_spin_type == SPIN_ENUM.FREE_SPIN) then
        amount = save_data.free_spin_param.total_amount / lineNum
    end
    local total_amount = amount * lineNum --总共下注用的钱
    --生成滚动结果
    local origin_result_arr = {}
    for result_idx = 1, #save_data.reel_info_arr, 1 do
        local reel_info = save_data.reel_info_arr[result_idx]
        origin_result_arr[result_idx], reel_file_name =
            SlotsGameCal.Calculate.GenItemResult(
            player,
            game_type,
            is_free_spin,
            game_room_config,
            reel_info.feature_file_name,
            reel_info.formation_name
        )
    end
    --测试代码
    -- if save_data.curr_spin_type == SPIN_ENUM.BASE_SPIN then
    --     local origin_result = origin_result_arr[1]
    --     origin_result[1][1] = 4
    --     origin_result[1][2] = 15
    --     origin_result[1][3] = 4
    --     origin_result[1][4] = 4
    --     origin_result[1][5] = 4

    --     origin_result[2][1] = 4
    --     -- origin_result[2][2] = 14
    --     -- origin_result[2][3] = 15
    --     origin_result[2][4] = 4
    --     origin_result[2][5] = 4

    --     origin_result[3][1] = 4
    --     -- origin_result[3][2] = 4
    --     origin_result[3][3] = 1
    --     origin_result[3][4] = 1
    --     origin_result[3][5] = 1

    --     origin_result[4][1] = 3
    --     origin_result[4][2] = 3
    --     origin_result[4][3] = 3
    --     origin_result[4][4] = 3
    --     origin_result[4][5] = 3
    -- elseif (save_data.curr_spin_type == SPIN_ENUM.FREE_SPIN) then
    --     local origin_result = origin_result_arr[1]
    --     origin_result[1][1] = 5
    --     origin_result[1][2] = 5
    --     origin_result[1][3] = 5
    --     origin_result[1][4] = 7
    --     origin_result[1][5] = 4

    --     origin_result[2][1] = 5
    --     origin_result[2][2] = 6
    --     origin_result[2][3] = 7
    --     origin_result[2][4] = 8
    --     origin_result[2][5] = 4

    --     origin_result[3][1] = 5
    --     origin_result[3][2] = 6
    --     origin_result[3][3] = 7
    --     origin_result[3][4] = 8
    --     origin_result[3][5] = 4

    --     origin_result[4][1] = 5
    --     origin_result[4][2] = 6
    --     origin_result[4][3] = 7
    --     origin_result[4][4] = 8
    --     origin_result[4][5] = 4
    -- end

    local final_result_arr = table.DeepCopy(origin_result_arr) --最终结果
    local settle_result_arr = table.DeepCopy(origin_result_arr) --结算结果

    --进入其他流程前的进入信息
    local formation_name = save_data.reel_info_arr[1].formation_name
    local enter_info = {
        item_ids = SlotsGameCal.Calculate.TransResultToCList(origin_result_arr[1], game_room_config, formation_name),
        final_item_ids = SlotsGameCal.Calculate.TransResultToCList(
            final_result_arr[1],
            game_room_config,
            formation_name
        )
    }

    --统计信息
    local special_parameter = {
        --slots通用逻辑的特性字段
        win_chip_cal_multiple = 0,
        --统计数据
        spin_type = save_data.curr_spin_type, --当前spin类型
        win_jackpot = false, --是否赢得了jackpot
        scatter_num = 0, --scatter的数量
        special_whole_col_num = 0, --整理为特殊图标的列数
        --赢钱的组成
        win_chip_form = {
            with_dynamic_wild = 0, --由于dynamic_wild带来的收益
            no_dynamic_wild = 0 --基础带来的收益
        },
        --free_spin的特殊统计
        trigger_free_spin = false, --是否触发free_spin
        free_spin_multiple_times_when_settle = 0 --结算时free_spin结束时倍数
    }

    --需要执行功能列举
    local need_add_jackpot = false --是否需要累加jackpot奖池筹码
    local need_push_jackpot = false --是否需要推送jackpot奖池信息
    local need_check_send_jackpot = false --是否需要检查赠送给玩家jackpot
    local need_gen_dynamic_wild = false --是否需要生成动态的多倍wild
    local need_check_add_spin_bonus = false --是否需要检查增加spin-bonus的次数
    local need_line_prize = false --是否需要连线奖励
    local need_gen_block = false --是否需要生成大块的图标
    local need_handle_base_line = false --是否需要处理基础的连线奖励信息
    local need_handle_dynamic_wild = false --是否需要处理动态wild加倍的特性
    local need_handle_special_whole_col = false --是否需要处理整列为特殊图标的特性
    local need_handle_jackpot = false --是否需要处理了jackpot的中奖
    local need_free_spin_settle = false --是否需要free_spin多倍结算

    --根据当前spin的类型，设置需要执行的功能
    if (save_data.curr_spin_type == SPIN_ENUM.BASE_SPIN) then
        need_add_jackpot = true
        need_push_jackpot = true
        need_check_send_jackpot = true
        need_gen_dynamic_wild = true
        need_check_add_spin_bonus = true
        need_line_prize = true
        need_gen_block = true
        need_handle_base_line = true
        need_handle_dynamic_wild = true
        need_handle_special_whole_col = true
        need_handle_jackpot = true
    elseif (save_data.curr_spin_type == SPIN_ENUM.FREE_SPIN) then
        need_check_send_jackpot = true
        need_gen_dynamic_wild = true
        need_line_prize = true
        need_gen_block = true
        need_handle_base_line = true
        need_handle_dynamic_wild = true
        need_handle_special_whole_col = true
        need_handle_jackpot = true
        need_free_spin_settle = true
    end

    ----各功能执行
    --刷新jackpot奖池
    if need_add_jackpot then
        --奖池点数增长
        CommonCal.Calculate.AddJackpotExtraChip(save_data.jackpot_param_v2, total_amount, jackpot_config)
    end

    --是否需要推送jackpot奖池信息
    if need_push_jackpot then
        --插入action
        table.insert(
            pre_action_list,
            {
                action_type = ActionType.ActionTypes.GameJackpotPool,
                jackpot_param = CommonCal.Calculate.GetJakcpotParamToClient(save_data.jackpot_param_v2)
            }
        )
    end

    --检测赠送玩家jackpot
    local jackpot_win_chip = 0
    if need_check_send_jackpot then
        --判断是否需要赠送
        local send_jackpot_type = nil --赠送的jackpot类型
        local prize_pool = save_data.jackpot_param_v2.prize_pool
        for prize_type, jackpot_info in pairs(prize_pool) do
            local jackpot_pool_chip =
                CommonCal.Calculate.GetJackpotPoolChipVal(save_data.jackpot_param_v2, prize_type, total_amount)
            if jackpot_pool_chip >= jackpot_config[prize_type].max_hold_point * total_amount then
                send_jackpot_type = prize_type
                break
            end
        end

        --进行赠送逻辑
        if send_jackpot_type then
            --确定赠送的金额
            jackpot_win_chip =
                CommonCal.Calculate.GetJackpotPoolChipVal(save_data.jackpot_param_v2, send_jackpot_type, total_amount) --送的金额

            --修改转轴的结果
            --确定修改的线
            local line_arr = _G[game_name .. "LineArray"].Lines1
            local jackpot_line = line_arr[math.random_ext(player, #line_arr)]
            --修改转轴的结果
            for col, row in ipairs(jackpot_line) do
                origin_result_arr[1][row][col] = ITEM_ENUM.Jackpot
                final_result_arr[1][row][col] = ITEM_ENUM.Jackpot
                settle_result_arr[1][row][col] = ITEM_ENUM.Jackpot
            end
        end
    end

    --生成动态的多倍wild
    if need_gen_dynamic_wild then
        --确定生成wild的权重表
        --获取配置
        local gen_dynamic_wild_config_on_line =
            CommonCal.Calculate.get_config(player, game_name .. "GenDynamicWildConfig") --在连线上的wild生成配置表
        local gen_dynamic_wild_config_fake =
            CommonCal.Calculate.get_config(player, game_name .. "GenDynamicWildFakeConfig") --不在连线上的wild生成配置表
        --确定权重表
        local weight_tab_on_line = nil --在连线上的wild生成权重表
        local weight_tab_on_fake = nil --不在连线上的wild生成权重表
        if save_data.curr_spin_type == SPIN_ENUM.BASE_SPIN then
            weight_tab_on_line = gen_dynamic_wild_config_on_line["base"].weight_tab
            weight_tab_on_fake = gen_dynamic_wild_config_fake["base"].weight_tab
        elseif (save_data.curr_spin_type == SPIN_ENUM.FREE_SPIN) then
            weight_tab_on_line =
                gen_dynamic_wild_config_on_line["free_spin_" .. save_data.free_spin_param.level].weight_tab
            weight_tab_on_fake =
                gen_dynamic_wild_config_fake["free_spin_" .. save_data.free_spin_param.level].weight_tab
        end

        --生成一次连线结果，用于确定每个wild是否在连线上
        local _, _, all_prize_list =
            my_cal:GenLinePrize(
            player,
            game_room_config,
            game_name,
            save_data.curr_spin_type,
            origin_result_arr,
            final_result_arr,
            settle_result_arr,
            save_data.reel_info_arr,
            amount,
            extra_payrate_ratio,
            need_line_prize,
            ITEM_ENUM,
            SPIN_ENUM
        )

        --处理每个转轴上的动态wild
        for result_idx, settle_result in ipairs(settle_result_arr) do
            --确定wildx1的位置信息
            local wild_on_line_map = {} --动态wild是否在赔付连线上的map
            for row, row_item in ipairs(settle_result) do
                for col, item in ipairs(row_item) do
                    --1倍的可变wild需要进行替换
                    if item == ITEM_ENUM.Wild_x1 then --有动态wild
                        --行数据检查
                        if wild_on_line_map[row] == nil then
                            wild_on_line_map[row] = {}
                        end
                        --加入数据
                        wild_on_line_map[row][col] = false --默认不在连线上
                    end
                end
            end

            --确定wild是否在连线上
            local prize_item_arr = all_prize_list[result_idx] --奖励信息
            local reel_info = save_data.reel_info_arr[result_idx] --转轴的信息
            local line_arr = _G[game_name .. "LineArray"][reel_info.line_name] --连线数组
            --遍历所有的连线奖励
            for _, prize_item in pairs(prize_item_arr) do
                local line_data = line_arr[prize_item.line_index] --连线信息

                --遍历连线上的元素
                for col = prize_item.from_index, prize_item.to_index, 1 do
                    --取出线上图标的wild倍数
                    local row = line_data[col] --连线对应的行
                    if wild_on_line_map[row] ~= nil and wild_on_line_map[row][col] ~= nil then --该图标为wildx1
                        wild_on_line_map[row][col] = true --设置状态在连线上
                    end
                end
            end

            --进行动态wild生成
            for row, row_item in pairs(wild_on_line_map) do
                for col, on_line in pairs(row_item) do
                    --生成新的wild图标
                    local weight_tab = on_line and weight_tab_on_line or weight_tab_on_fake --替换的权重表
                    local wild_multiple = my_cal:GetRandomItemByWeightTab(player, weight_tab).wild_multiple
                    local new_item = ITEM_ENUM["Wild_x" .. wild_multiple]
                    --结果进行替换
                    origin_result_arr[result_idx][row][col] = new_item
                    final_result_arr[result_idx][row][col] = new_item
                    settle_result_arr[result_idx][row][col] = new_item
                end
            end
        end
    end

    --检查增加spin-bonus的次数
    if need_check_add_spin_bonus then
        --检测是否触发
        local settle_result = settle_result_arr[1] --BaseGame只会有1个Reel的结果
        local scatter_item_count = my_cal:GetItemCountInItemArr(settle_result, ITEM_ENUM.Scatter)
        --触发了时的数据处理
        if (scatter_item_count >= 3) then
            local scatter_config = CommonCal.Calculate.get_config(player, game_name .. "ScatterConfig")
            my_cal:SetSpinBonusBeforEnter(save_data, scatter_item_count, scatter_config, total_amount, enter_info)

            --统计参数
            special_parameter.trigger_free_spin = true
        end

        --统计参数
        special_parameter.scatter_num = scatter_item_count
    end

    --连线奖励
    local slots_win_chip = 0 --连线赢得钱
    local formation_list = {} --结果展示表
    local all_prize_list = {} --所有的连线奖励表
    local extra_payrate_ratio = 1 --额外赔付系数
    local accumulated_win_chip =
        save_data.curr_spin_type == SPIN_ENUM.FREE_SPIN and save_data.free_spin_param.base_total_win_chip or 0 --之前累计赢的钱
    if save_data.curr_spin_type == SPIN_ENUM.BASE_SPIN then --base_spin需要奖励赔付倍率
        extra_payrate_ratio = CommonCal.Calculate.get_config(player, game_name .. "OthersConfig")[1].Base_Bet_Ratio
    end
    slots_win_chip, formation_list, all_prize_list =
        my_cal:GenLinePrize(
        player,
        game_room_config,
        game_name,
        save_data.curr_spin_type,
        origin_result_arr,
        final_result_arr,
        settle_result_arr,
        save_data.reel_info_arr,
        amount,
        extra_payrate_ratio,
        need_line_prize,
        ITEM_ENUM,
        SPIN_ENUM
    )

    --生成大图标
    if need_gen_block then
        --确定可以生成大图标的列（Vampire图标有可能需要进行合成）
        local gen_block_col_arr = {} --需要生成大图标的列
        --1.该列有Vampire图标在连线奖励上，可合成
        for result_idx, prize_item_arr in pairs(all_prize_list) do
            for _, prize_item in pairs(prize_item_arr) do --遍历所有的连线奖励
                if prize_item.item_id == ITEM_ENUM.Vampire then --奖励为吸血鬼
                    for col = prize_item.from_index, prize_item.to_index, 1 do --则从开始到结束的列都可以合成吸血鬼
                        gen_block_col_arr[col] = true
                    end
                end
            end
        end

        --2.有整列的Vampire图标，且有赔付时
        --判读是否需要进行整列的合成
        local need_gen_special_whole_col = false --是否需要对整列图标进行合成
        if save_data.curr_spin_type == SPIN_ENUM.BASE_SPIN then
            if slots_win_chip > 0 then
                need_gen_special_whole_col = true
            end
        elseif save_data.curr_spin_type == SPIN_ENUM.FREE_SPIN then
            need_gen_special_whole_col = true
        end
        --整列合成逻辑
        if need_gen_special_whole_col then --有赔付时
            for result_idx, prize_item_arr in pairs(all_prize_list) do --遍历每个转轴
                local settle_result = settle_result_arr[result_idx] --原始结果
                local col_num = #settle_result[1]
                for col = 1, col_num, 1 do
                    --判断本列是否全为特殊图标
                    local is_special_whole_col = true --本列是否全为特殊图标
                    for row, row_item in ipairs(settle_result) do
                        if row_item[col] ~= ITEM_ENUM.Vampire then
                            is_special_whole_col = false
                            break
                        end
                    end

                    --根据判断结果，更新特殊图标列的数组
                    if is_special_whole_col then
                        gen_block_col_arr[col] = true
                    end
                end
            end
        end

        --针对可以合成整列大图标的列进行合成
        for result_idx, settle_result in ipairs(settle_result_arr) do --遍历每个转轴
            --最终结果的大图标合成
            local have_gen_block_col = false --是否生成了大图标
            local settle_result = settle_result_arr[result_idx] --结算结果
            local row_num = #settle_result --行数
            local final_result = final_result_arr[result_idx] --最终结果
            for col, _ in pairs(gen_block_col_arr) do --可以生成大图标的列
                --遍历改列的数据
                local row = 1
                while row <= row_num do
                    --确定连线的图标并替换
                    if settle_result[row][col] == ITEM_ENUM.Vampire then --找到了吸血鬼图标
                        --计算连续吸血鬼图标的个数
                        local continue_count = 0 --连续的吸血鬼
                        for try_row = row, row_num, 1 do
                            if settle_result[try_row][col] == ITEM_ENUM.Vampire then
                                continue_count = continue_count + 1
                            else
                                break
                            end
                        end

                        --进行图标合成
                        if continue_count >= 2 then --两个以上时，才进行合成
                            --设置标志量
                            have_gen_block_col = true

                            --最终的图标进行替换
                            for try_row = row, row + continue_count - 1, 1 do
                                local continue_idx = try_row - row + 1
                                final_result[try_row][col] =
                                    final_result[try_row][col] * 100 + continue_count * 10 + continue_idx
                            end

                            --已经合成了的吸血鬼就不再检测了
                            row = row + continue_count - 1
                        end
                    end

                    --行数递增
                    row = row + 1
                end
            end

            --更新转轴的结果
            if have_gen_block_col then
                local reel_info = save_data.reel_info_arr[result_idx]
                formation_list[result_idx].slots_spin_list[1].final_item_ids =
                    json.encode(
                    SlotsGameCal.Calculate.TransResultToCList(final_result, game_room_config, reel_info.formation_name)
                )
            end
        end
    end

    --处理基础赢钱
    if need_handle_base_line then
        if slots_win_chip > 0 then
            --剔除中jackpot在连线上的赔率
            for result_idx, prize_item_arr in pairs(all_prize_list) do
                --确定jackpot奖励的奖励
                local jackpot_prize_item = nil
                for _, prize_item in pairs(prize_item_arr) do --遍历所有的连线奖励
                    if prize_item.continue_count == 5 and prize_item.item_id == ITEM_ENUM.Jackpot then --有可能是不带wild的5连jackpot
                        --判断该连线是否全为jackpot图标
                        local settle_result = settle_result_arr[result_idx] --原始结果
                        local reel_info = save_data.reel_info_arr[result_idx] --转轴的信息
                        local line_arr = _G[game_name .. "LineArray"][reel_info.line_name] --连线数组
                        local line_data = line_arr[prize_item.line_index] --连线信息
                        --遍历连线上的元素
                        local is_all_jackpot = true --是否是全是is_all_jackpot
                        for col = prize_item.from_index, prize_item.to_index, 1 do
                            --取出线上图标的wild倍数
                            local row = line_data[col] --连线对应的行
                            local item = settle_result[row][col] --对应线上的坐标
                            if item ~= ITEM_ENUM.Jackpot then
                                is_all_jackpot = false
                                break
                            end
                        end
                        --根据遍历结果，确认当前的奖励连线是否是全为jackpot
                        if is_all_jackpot then
                            jackpot_prize_item = prize_item
                        end
                    end
                end

                --存在jackpot奖励时，进行处理
                if jackpot_prize_item then
                    --计算jackpot的具体赢钱变化
                    local jackpot_line_win = jackpot_prize_item.payrate / 1000 * amount --之前计算连线奖励的钱
                    jackpot_prize_item.payrate = 0 --清零该线的赔率
                    win_chip_not_have_jackpot = slots_win_chip - jackpot_line_win --计算初始赢钱（不包含jackpot该连线）
                    formation_list[result_idx].slots_spin_list[1].win_chip = win_chip_not_have_jackpot --更新转轴的总赢钱
                    slots_win_chip = win_chip_not_have_jackpot --更新总赢钱
                end
            end

            --发送基础的连线信息
            --插入wild结算的action
            table.insert(
                pre_action_list,
                {
                    action_type = ActionType.ActionTypes.BaseLineWinChip,
                    win_chip_origin = accumulated_win_chip,
                    win_chip_final = accumulated_win_chip + slots_win_chip
                }
            )
        end
    end

    --处理动态wild加倍的特性
    if need_handle_dynamic_wild then
        --变量声明
        local win_chip_origin = slots_win_chip --起始金额
        local win_chip_final = 0 --最终金额
        local wild_pos_map = {} --wild所在的位置信息
        local win_chip_with_dynamic_wild = 0 --有wild连线的赢取筹码
        local win_chip_no_dynamic_wild = 0 --没有wild赢取的筹码

        --遍历所有的中奖连线
        for result_idx, prize_item_arr in pairs(all_prize_list) do
            --取出该转轴的信息
            local settle_result = settle_result_arr[result_idx] --原始结果
            local reel_info = save_data.reel_info_arr[result_idx] --转轴的信息
            local line_arr = _G[game_name .. "LineArray"][reel_info.line_name] --连线数组
            local payrate_single_result = 0 --本转轴的赔率

            --遍历所有的连线奖励
            for _, prize_item in pairs(prize_item_arr) do
                --取出声明变量
                local have_wild_on_line = false --连线上是否有动态wild
                local total_wild_times = 0 --wild的总倍数
                local line_data = line_arr[prize_item.line_index] --连线信息

                --遍历连线上的元素
                for col = prize_item.from_index, prize_item.to_index, 1 do
                    --取出线上图标的wild倍数
                    local row = line_data[col] --连线对应的行
                    local item = settle_result[row][col] --对应线上的坐标
                    local wild_times = ITEM_ENUM.DynamicWildTimes[item] --wild图标对应的倍数

                    --如果存在倍数，做部分统计
                    if wild_times then
                        have_wild_on_line = true --设置标志量

                        if wild_times > 1 then
                            --累加wild的倍数
                            total_wild_times = total_wild_times + wild_times

                            --记录多倍wild的位置信息
                            if wild_pos_map[row] == nil then
                                wild_pos_map[row] = {}
                            end
                            wild_pos_map[row][col] = item
                        end
                    end
                end

                --更新连线
                if total_wild_times > 0 then --连线上存在动态wild
                    prize_item.payrate = prize_item.payrate * total_wild_times --更新赔率
                end

                --转轴结果的总统计
                payrate_single_result = payrate_single_result + prize_item.payrate

                --统计参数
                if have_wild_on_line then
                    win_chip_with_dynamic_wild = win_chip_with_dynamic_wild + prize_item.payrate / 1000 * amount
                else
                    win_chip_no_dynamic_wild = win_chip_no_dynamic_wild + prize_item.payrate / 1000 * amount
                end
            end

            --统计总金额
            local win_single_result = payrate_single_result / 1000 * amount
            win_chip_final = math.floor(win_chip_final + win_single_result) --更新最后总赢钱
            formation_list[result_idx].slots_spin_list[1].win_chip = win_chip_final --更新转轴的总赢钱
        end

        --触发动态wild加倍的特性
        if win_chip_origin ~= win_chip_final then
            --更新slots的总赢钱
            slots_win_chip = win_chip_final
            --插入wild结算的action
            table.insert(
                pre_action_list,
                {
                    action_type = ActionType.ActionTypes.SpinWildPosSettle,
                    win_chip_origin = accumulated_win_chip + win_chip_origin,
                    win_chip_final = accumulated_win_chip + win_chip_final,
                    wild_pos_arr = my_cal:ArrToList_2(wild_pos_map)
                }
            )
        end

        --统计参数
        special_parameter.win_chip_form.with_dynamic_wild = win_chip_with_dynamic_wild
        special_parameter.win_chip_form.no_dynamic_wild = win_chip_no_dynamic_wild
    end

    --处理整列为特殊图标
    if need_handle_special_whole_col then
        --变量取出和声明
        local special_whole_col_map = {} --整列为特殊图标的map
        local special_whole_col_num = 0 --整列为特殊图标的总列数
        local settle_result = settle_result_arr[1]

        --确定全为特殊图标的列
        local col_num = #settle_result[1]
        for col = 1, col_num, 1 do
            --判断本列是否全为特殊图标
            local is_special_whole_col = true --本列是否全为特殊图标
            for row, row_item in ipairs(settle_result) do
                if row_item[col] ~= ITEM_ENUM.Vampire then
                    is_special_whole_col = false
                    break
                end
            end

            --根据判断结果，更新特殊图标列的数组
            if is_special_whole_col then
                special_whole_col_map[col] = true
                special_whole_col_num = special_whole_col_num + 1
            end
        end
        --统计参数
        special_parameter.special_whole_col_num = special_whole_col_num

        --根据列数进行spin结果的处理
        if special_whole_col_num > 0 then
            --加倍的倍数
            local multiple_times = special_whole_col_num * 2

            --针对不同的spin类型进行处理
            if (save_data.curr_spin_type == SPIN_ENUM.BASE_SPIN) then --所有连线奖励需要倍数增加
                --变量声明
                local win_chip_origin = slots_win_chip --起始金额
                local win_chip_final = 0 --最终金额

                --遍历所有的中奖连线
                for result_idx, prize_item_arr in pairs(all_prize_list) do
                    --取出该转轴的信息
                    local payrate_single_result = 0 --本转轴的赔率
                    --遍历所有的连线奖励
                    for _, prize_item in pairs(prize_item_arr) do
                        prize_item.payrate = prize_item.payrate * multiple_times --更新连线赔率
                        payrate_single_result = payrate_single_result + prize_item.payrate --转轴结果的总统计
                    end
                    --统计总金额
                    local win_single_result = payrate_single_result / 1000 * amount
                    win_chip_final = math.floor(win_chip_final + win_single_result) --更新最后总赢钱
                    formation_list[result_idx].slots_spin_list[1].win_chip = win_chip_final --更新转轴的总赢钱
                end

                --触发整列为特殊图标的特性
                if win_chip_origin ~= win_chip_final then
                    --更新slots的总赢钱
                    slots_win_chip = win_chip_final
                    --插入wild结算的action
                    table.insert(
                        pre_action_list,
                        {
                            action_type = ActionType.ActionTypes.SpinSpecialItemSettle,
                            win_chip_origin = accumulated_win_chip + win_chip_origin,
                            win_chip_final = accumulated_win_chip + win_chip_final,
                            special_whole_col_arr = my_cal:ArrToList_1(special_whole_col_map)
                        }
                    )
                end

                --统计参数
                special_parameter.win_chip_form.with_dynamic_wild =
                    special_parameter.win_chip_form.with_dynamic_wild * multiple_times
                special_parameter.win_chip_form.no_dynamic_wild =
                    special_parameter.win_chip_form.no_dynamic_wild * multiple_times
            elseif (save_data.curr_spin_type == SPIN_ENUM.FREE_SPIN) then --最后结算的总倍数需要增加
                --变量取出
                local free_spin_param = save_data.free_spin_param

                --free_spin的倍数更新
                if free_spin_param.multiple_times == 1 then
                    free_spin_param.multiple_times = multiple_times --首次为直接替换（如multiple_times：2 ,则1->2）
                else
                    free_spin_param.multiple_times = free_spin_param.multiple_times + multiple_times --原来有倍数，则累加（如multiple_times：4 ,则2->6）
                end

                --插入action
                table.insert(
                    pre_action_list,
                    {
                        action_type = ActionType.ActionTypes.FreeSpinWinMultiple,
                        multiple_times = free_spin_param.multiple_times,
                        special_whole_col_arr = my_cal:ArrToList_1(special_whole_col_map)
                    }
                )
            end
        end
    end

    --处理jackpot
    if need_handle_jackpot then
        --是否赢取了jackpot
        local have_win_jackpot = false

        --针对每个转轴进行处理
        for result_idx, prize_item_arr in pairs(all_prize_list) do
            --确定jackpot奖励的奖励
            local jackpot_prize_item = nil
            for _, prize_item in pairs(prize_item_arr) do --遍历所有的连线奖励
                if prize_item.continue_count == 5 and prize_item.item_id == ITEM_ENUM.Jackpot then --有可能是不带wild的5连jackpot
                    --判断该连线是否全为jackpot图标
                    local settle_result = settle_result_arr[result_idx] --原始结果
                    local reel_info = save_data.reel_info_arr[result_idx] --转轴的信息
                    local line_arr = _G[game_name .. "LineArray"][reel_info.line_name] --连线数组
                    local line_data = line_arr[prize_item.line_index] --连线信息
                    --遍历连线上的元素
                    local is_all_jackpot = true --是否是全是is_all_jackpot
                    for col = prize_item.from_index, prize_item.to_index, 1 do
                        --取出线上图标的wild倍数
                        local row = line_data[col] --连线对应的行
                        local item = settle_result[row][col] --对应线上的坐标
                        if item ~= ITEM_ENUM.Jackpot then
                            is_all_jackpot = false
                            break
                        end
                    end
                    --根据遍历结果，确认当前的奖励连线是否是全为jackpot
                    if is_all_jackpot then
                        jackpot_prize_item = prize_item
                    end
                end
            end

            --存在jackpot奖励时，进行处理
            if jackpot_prize_item then
                --设置表质量
                have_win_jackpot = true

                --赢钱的处理
                local win_chip_origin = 0 --初始赢钱
                local win_chip_final = 0 --最终赢钱

                --计算jackpot的具体赢钱变化
                local jackpot_line_win_before = jackpot_prize_item.payrate / 1000 * amount --之前计算连线奖励的钱
                local jackpot_line_win_curr =
                    CommonCal.Calculate.GetJackpotPoolChipVal(
                    save_data.jackpot_param_v2,
                    PRIZE_TYPE_ENUM.JAKCPOT,
                    total_amount
                ) --实际应该赢取的钱
                jackpot_prize_item.payrate = math.floor(jackpot_line_win_curr / amount * 1000) --更新连线的赔率
                win_chip_origin = slots_win_chip - jackpot_line_win_before --计算初始赢钱（不包含jackpot该连线）
                win_chip_final = slots_win_chip - jackpot_line_win_before + jackpot_line_win_curr --计算最终赢钱
                formation_list[result_idx].slots_spin_list[1].win_chip = win_chip_final --更新转轴的总赢钱
                slots_win_chip = win_chip_final --更新总赢钱

                --action发送
                table.insert(
                    pre_action_list,
                    {
                        action_type = ActionType.ActionTypes.WinGameJackpot,
                        win_chip_origin = accumulated_win_chip + win_chip_origin,
                        win_chip_final = accumulated_win_chip + win_chip_final,
                        jackpot_chip = jackpot_line_win_curr, --jackpot的赢钱
                        line_index = jackpot_prize_item.line_index --jackpot所在连线
                    }
                )
            end
        end

        --更新jackpot奖池
        if have_win_jackpot then
            CommonCal.Calculate.ResetJackpotExtraChip(save_data.jackpot_param_v2, PRIZE_TYPE_ENUM.JAKCPOT) --奖池初始化

            --统计参数
            special_parameter.win_jackpot = true
        end
    end

    --需要free_spin多倍结算
    if need_free_spin_settle then
        --变量取出
        local free_spin_param = save_data.free_spin_param

        --free_spin的次数更新
        --次数递减
        free_spin_param.bouts = free_spin_param.bouts - 1
        --scatter触发增加spin的次数
        local scatter_num = my_cal:GetItemCountInItemArr(settle_result_arr[1], ITEM_ENUM.Scatter)
        if scatter_num > 0 then
            --获取free_spin增加的次数
            local scatter_config = CommonCal.Calculate.get_config(player, game_name .. "ScatterConfig")
            local add_free_spin_bouts_by_scatter =
                scatter_config[scatter_num] and scatter_config[scatter_num].free_spin_extra_bouts or
                scatter_config[#scatter_config].free_spin_extra_bouts --增加free-spin的次数

            --进行增加逻辑
            if add_free_spin_bouts_by_scatter > 0 then
                --变量维护
                free_spin_param.bouts = free_spin_param.bouts + add_free_spin_bouts_by_scatter --自身维护的free_spin次数累加
                add_free_spin_bouts = add_free_spin_bouts_by_scatter --通知外围变量增加free_spin次数

                --添加action
                --free_spin增加的特性
                table.insert(
                    pre_action_list,
                    {
                        action_type = ActionType.ActionTypes.FreeSpinTimesAdd,
                        add_free_spin_bouts = add_free_spin_bouts,
                        free_spin_bouts = free_spin_param.bouts
                    }
                )
                --显示free_spin时，扣除部分的特性
                player_game_info.free_spin_num = add_free_spin_bouts_by_scatter
            end
        end
        --统计参数
        special_parameter.scatter_num = scatter_num

        --free_spin赢钱的更新
        local base_curr_win_chip = slots_win_chip --本次free_spin赢的钱
        free_spin_param.base_total_win_chip = free_spin_param.base_total_win_chip + base_curr_win_chip --更新基础赢钱累计

        --结算信息
        local is_over = free_spin_param.bouts == 0
        if (is_over) then
            --赋值结算信息
            local settle_info = {
                multiple_times = free_spin_param.multiple_times,
                multiple_total_win_chip = free_spin_param.multiple_times * free_spin_param.base_total_win_chip
            }
            --额外加倍的钱计算到总赢钱中
            total_win_chip = total_win_chip + (free_spin_param.multiple_times - 1) * free_spin_param.base_total_win_chip

            --插入free_spin赢钱的action
            table.insert(
                pre_action_list,
                {
                    action_type = ActionType.ActionTypes.FreeSpinSettle,
                    base_curr_win_chip = base_curr_win_chip,
                    base_total_win_chip = free_spin_param.base_total_win_chip,
                    settle_info = settle_info
                }
            )

            --统计参数
            special_parameter.free_spin_multiple_times_when_settle = free_spin_param.multiple_times
        end
    end

    --本次赢得所有钱（连线赢得钱+特殊点赢钱）
    total_win_chip = total_win_chip + slots_win_chip --累加总赢钱
    special_parameter.win_chip_cal_multiple = slots_win_chip --赋值用于计算BeiWin的赢钱

    --流程控制
    --获取下一次Spin的类型、Bnous类型
    local change_to_spin_type, change_to_bonus_type =
        my_cal:GetGameChangeToStepInControl(save_data, SPIN_ENUM, BONUS_ENUM) --要改变为的游戏状态（如果没有改变，则为nil）
    --根据结果，进行切换
    my_cal:MoveTotGameChangeToStepInControl(
        save_data,
        pre_action_list,
        player,
        game_name,
        player_game_info,
        change_to_spin_type,
        change_to_bonus_type,
        SPIN_ENUM,
        BONUS_ENUM,
        PRIZE_TYPE_ENUM
    )

    --返回结果中插入aciton
    local pre_action_list_json = json.encode(pre_action_list)
    for _, formation in pairs(formation_list) do
        for _, slots_spin in pairs(formation.slots_spin_list) do
            slots_spin.pre_action_list = pre_action_list_json
        end
    end

    --保存缓存数据
    my_cal:RecordSaveData(player_game_info, save_data)
    --------------------------------------------------------------
    --服务器客户端通讯数据参数列表game_server\Server\Source\Idl\Protobuf
    --参数解释V1.1，新玩法请直接复制，不要改名字，不然对不上了。。。。
    --     ↓↓↓↓↓结果数组↓↓↓↓  ↓↓↓↓↓总奖金↓↓↓↓ ↓↓↓所有连线列表↓ ↓增加的freespin的次数↓↓客户端接收的列表↓ ↓↓reel表名↓↓   ↓↓↓转动奖金↓↓↓  ↓↓↓统计参数↓↓↓
    return final_result_arr, total_win_chip, all_prize_list, add_free_spin_bouts, formation_list, reel_file_name, slots_win_chip, special_parameter
end

Spin = function(
    player,
    game_type,
    is_free_spin,
    game_room_config,
    amount,
    player_feature_condition,
    extern_param,
    player_game_info)
    return SpinProcess(
        player,
        game_type,
        is_free_spin,
        game_room_config,
        amount,
        player_feature_condition,
        extern_param,
        player_game_info
    )
end
--************************************************
--------------------------------------------------
do --SpinBonus
    --进入
    SpinBonusEnter = function(task, player, game_room_config, parameter, player_game_info)
        --初始化返回值
        local content = {}

        --部分变量缓存
        local game_name = game_room_config.game_name --游戏名字
        --读取缓存数据
        local save_data = my_cal:GetSaveData(player, player_game_info, game_name, SPIN_ENUM, PRIZE_TYPE_ENUM) --检查缓存数据的完整性
        --------------------------------------测试代码-----------------------------------------
        --**********************************************************************************--
        if save_data.spin_bonus_param.bouts == 0 then
            --设置进入bonus数据
            local scatter_config = CommonCal.Calculate.get_config(player, game_name .. "ScatterConfig")
            my_cal:SetSpinBonusBeforEnter(save_data, 5, scatter_config, 10000)

            --流程控制
            --获取下一次Spin的类型、Bnous类型
            local change_to_spin_type, change_to_bonus_type =
                my_cal:GetGameChangeToStepInControl(save_data, SPIN_ENUM, BONUS_ENUM) --要改变为的游戏状态（如果没有改变，则为nil）
            --根据结果，进行切换
            my_cal:MoveTotGameChangeToStepInControl(
                save_data,
                {},
                player,
                game_name,
                player_game_info,
                change_to_spin_type,
                change_to_bonus_type,
                SPIN_ENUM,
                BONUS_ENUM,
                PRIZE_TYPE_ENUM
            )
        end
        --**********************************************************************************--
        --------------------------------------测试代码-----------------------------------------
        local spin_bonus_param = save_data.spin_bonus_param

        --逻辑处理
        if spin_bonus_param.bouts > 0 then
            --填入数据
            content = {
                select_param = spin_bonus_param.select_param
            }
        end

        --保存缓存数据
        my_cal:RecordSaveData(player_game_info, save_data)

        --返回
        return content
    end

    --选择
    --转动
    SpinBonusSelect = function(task, player, game_room_config, parameter, player_game_info)
        --初始化返回值
        local content = {}

        --部分变量缓存
        local game_name = game_room_config.game_name --游戏名字
        local ITEM_ENUM = _G[game_name .. "TypeArray"].Types --图标的枚举
        --读取缓存数据
        local save_data = my_cal:GetSaveData(player, player_game_info, game_name, SPIN_ENUM, PRIZE_TYPE_ENUM) --检查缓存数据的完整性
        local spin_bonus_param = save_data.spin_bonus_param

        --逻辑处理
        if spin_bonus_param.bouts > 0 then
            --变量声明
            local pre_action_list = {} --pre_action_list声明
            local request_success = false --设置标志量

            --读取请求参数
            local select_request = json.decode(parameter) --请求的参数
            local select_level = select_request.level --选择free_spin的等级

            --请求处理
            --取出变量
            local select_param = spin_bonus_param.select_param
            --设置参数
            local slect_free_spin_bouts = select_param.free_spin_bouts_level_arr[select_level]
            if slect_free_spin_bouts then --存在这个选项
                request_success = true --请求成功
                my_cal:SetFreeSpinBeforeEnter(save_data, select_param.total_amount, slect_free_spin_bouts, select_level) --设置free_spin的参数
            end
            --成功后，将spin-bonus次数清零
            if request_success then
                spin_bonus_param.bouts = 0
                player_game_info.bonus_game_type = 0
            end

            --流程控制
            --获取下一次Spin的类型、Bnous类型
            local change_to_spin_type, change_to_bonus_type =
                my_cal:GetGameChangeToStepInControl(save_data, SPIN_ENUM, BONUS_ENUM) --要改变为的游戏状态（如果没有改变，则为nil）
            --根据结果，进行切换
            my_cal:MoveTotGameChangeToStepInControl(
                save_data,
                pre_action_list,
                player,
                game_name,
                player_game_info,
                change_to_spin_type,
                change_to_bonus_type,
                SPIN_ENUM,
                BONUS_ENUM,
                PRIZE_TYPE_ENUM
            )

            --填入数据
            content = {
                select_request = select_request, --请求
                request_success = request_success, --请求是否成功
                free_spin_bouts = save_data.free_spin_param.bouts, --free_spin增加的次数
                pre_action_list = pre_action_list --会触发的Action列表(用于游戏的流程控制)
            }
        end

        --保存缓存数据
        my_cal:RecordSaveData(player_game_info, save_data)

        --返回
        return content
    end

    --统计使用
    StatisticsSpinBonusToEnd = function(player, game_room_config, player_game_info)
        --初始化返回值
        local free_spin_level, free_spin_bouts = 0, 0 --free_spin的次数

        --部分变量缓存
        local game_name = game_room_config.game_name --游戏名字
        --读取缓存数据

        --进入
        local enter_content = SpinBonusEnter(task, player, game_room_config, {}, player_game_info)

        --进行选择
        local select_level = 1 --math.random_ext(player, #enter_content.select_param.free_spin_bouts_level_arr)
        local select_content =
            SpinBonusSelect(task, player, game_room_config, json.encode({level = select_level}), player_game_info)
        --统计
        free_spin_level = select_level
        free_spin_bouts = select_content.free_spin_bouts --得出当前free_spin的次数

        -- print(
        --     string.format(
        --         "[StatisticsSpinBonusToEnd] free_spin_level=%d free_spin_bouts=%d",
        --         free_spin_level,
        --         free_spin_bouts
        --     )
        -- )

        --返回
        return free_spin_level, free_spin_bouts
    end
end
--[[    1.Enter信息补充
    2.流程测试

    3.Tournament请求不到比赛信息
]]
