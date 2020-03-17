require "Common/SlotsGameCalculate" --重写的接口
require "Common/SlotsGameCal" --旧的接口
require "Common/SlotsNewPurrfectPetsCal" --专用的函数
require "dkjson"
module("SlotsNewPurrfectPetsSpinV1", package.seeall)

--变量缓存
--spin类型
local SPIN_ENUM = {
    BASE_SPIN = 1, --基础spin
    COIN_SPIN = 2, --金币的锁定spin
    REELS_SPIN = 3 --多轴的spin
}
--金币上奖励的类型
local COIN_PRIZE_ENUM = {
    CHIP = 1, --筹码奖励
    JACKPOT_GRAND = 2, --Grand Jackpot
    JACKPOT_MAJOR = 3, --Major Jackpot
    JACKPOT_MINOR = 4, --Minor Jackpot
    JACKPOT_MINI = 5, --Mini Jackpot
    PLAY_AGAIN = 6 --获得再次进行coin_spin的游戏机会
}
--地图奖励枚举
local MAP_PRIZE_ENUM = {
    CHIP = 1, --筹码奖励
    ADD_REELS = 2, --添加新的转轴
    ADD_FREE_SPIN = 3, --添加FREE_SPIN
    ADD_WILD_REELS = 4, --添加WILD列
    ADD_A_ROW = 5 --给所有奖励转轴添加行
}
--转盘结果枚举
local TURNAROUND_RESULT_ENUM = {
    WALK_TO_YELLOW = 1, --走到色块
    WALK_TO_ORANGE = 2, --走到色块
    WALK_TO_GREEN = 3, --走到色块
    WALK_TO_PURPLE = 4, --走到色块
    WALK_TO_BLUE = 5, --走到色块
    COLLECT = 6 --收集物品 不走路
}
--收集奖励枚举
local COLLECT_PRIZE_ENUM = {
    CHIP = 1, --筹码奖励
    COIN_SPIN = 2, --金币的锁定spin
    BONUS_GAME = 3, --走地图小游戏
    REELS_SPIN = 4 --多轴spin
}

--计算辅助类缓存
local my_cal = NewPurrfectPetsCalClass

--入口
Enter = function(task, player, game_room_config, player_game_info)
    --返回数据初始化
    local bonus_info = {}

    --部分变量缓存
    local game_name = game_room_config.game_name --游戏名字
    --读取缓存数据
    local save_data = my_cal:GetSaveData(player, player_game_info, game_name, SPIN_ENUM) --检查缓存数据的完整性
    --返回数据计算
    local spin_bouts = -1
    if save_data.curr_spin_type == SPIN_ENUM.COIN_SPIN then
        spin_bouts = save_data.coin_spin_bouts
    elseif save_data.curr_spin_type == SPIN_ENUM.REELS_SPIN then
        spin_bouts = save_data.reels_spin_bouts
    end
    --返回数据填入
    bonus_info = {
        in_bonus_game = player_game_info.bonus_game_type > 0,
        collect_num = save_data.collect_param.collect_num,
        curr_spin_type = save_data.curr_spin_type,
        spin_bouts = spin_bouts,
        reel_info_arr = save_data.reel_info_arr,
        prize_pool = my_cal:GetJakcpotPrizePoolToClient(save_data.jackpot_param.prize_pool, COIN_PRIZE_ENUM)
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
    local jackpot_config = CommonCal.Calculate.get_config(player, game_name .. "JackpotConfig")
    local ITEM_ENUM = _G[game_name .. "TypeArray"].Types --图标的枚举
    --读取缓存数据
    local save_data = my_cal:GetSaveData(player, player_game_info, game_name, SPIN_ENUM) --检查缓存数据的完整性

    --确定spin的特性
    local pre_action_list = {} --传给客户端的动作
    local add_free_spin_bouts = 0 --本次spin中增加的reels_spin次数
    local reel_file_name  --reel表名
    local weight_file_name = nil --权重轴的名字
    local curlineNum = LineNum[player_game_info.game_type]()
    local config_table =
        SlotsGameCal.Calculate.GetMapConfigTable(extern_param.session, game_room_config, player_game_info, amount * curlineNum)
    --确定投注额度与转轴的权重表
    local reel_line_name = save_data.reel_info_arr[1].line_name
    local lineNum = #(_G[game_name .. "LineArray"][reel_line_name]) --线数
    if (save_data.curr_spin_type == SPIN_ENUM.BASE_SPIN) then
        reel_file_name = config_table.base_reel_config
        weight_file_name = config_table.base_reel_weight_config
    elseif (save_data.curr_spin_type == SPIN_ENUM.COIN_SPIN) then --由收集触发的特殊spin，需要获得指定的下注额度
        reel_file_name = config_table.coin_reel_config
        weight_file_name = config_table.coin_reel_weight_config
        amount = save_data.coin_spin_param.point_amount_when_spin
    elseif (save_data.curr_spin_type == SPIN_ENUM.REELS_SPIN) then --由收集触发的特殊spin，需要获得指定的下注额度
        amount = save_data.reels_spin_param.point_amount_when_spin
        if save_data.reels_spin_param.trigger_by_collect then
            reel_file_name = config_table.box_reel_config
            weight_file_name = config_table.box_reel_weight_config
        else
            reel_file_name = config_table.feature_reel_config
            weight_file_name = config_table.feature_reel_weight_config
        end
    end
    local total_amount = amount * lineNum --总共下注用的钱
    --生成滚动结果
    local origin_result_arr = {}
    for result_idx = 1, #save_data.reel_info_arr, 1 do
        local reel_info = save_data.reel_info_arr[result_idx]
        origin_result_arr[result_idx], reel_file_name =
            SlotsGameCal.Calculate.GenItemResultWithWeight(
            player,
            game_type,
            is_free_spin,
            game_room_config,
            reel_file_name,
            weight_file_name,
            reel_info.formation_name
        )
    end
    --由于coin-spin转轴中没有金币图标，所以需要进行赠送金币图标
    local need_gen_coin_item = save_data.curr_spin_type == SPIN_ENUM.COIN_SPIN
    if need_gen_coin_item then
        --变量缓存
        local origin_result = origin_result_arr[1]
        local coin_spin_param_v2 = save_data.coin_spin_param_v2

        --确定生成金币的数量
        local gen_coin_count = 0 --生成金币的数量
        if coin_spin_param_v2.left_coin_count_sequence[1] then
            gen_coin_count = coin_spin_param_v2.left_coin_count_sequence[1]
            table.remove(coin_spin_param_v2.left_coin_count_sequence, 1) --移除第一个数据
        end

        --进行金币生成
        if gen_coin_count > 0 then
            --变量取出
            local lock_coin_info_arr =
                (save_data.curr_spin_type == SPIN_ENUM.BASE_SPIN) and {} or save_data.coin_spin_param.lock_coin_info_arr --已经锁定的金币信息(--base_spin中，不能使用之前coin_spin的lock信息)
            local gen_coin_pos_list =
                my_cal:GetGenNewCoinItemPosList(origin_result_arr[1], lock_coin_info_arr, ITEM_ENUM) --可生成金币的位置列表

            --进行图标的替换
            for send_coin_idx = 1, gen_coin_count, 1 do
                --确定位置
                local result_idx = math.random_ext(player, #gen_coin_pos_list) --随机拿到一个位置信息的索引
                local pos = gen_coin_pos_list[result_idx].pos --取出位置信息
                table.remove(gen_coin_pos_list, result_idx) --用过的位置，进行移除，防止下次随机在同一位置

                --替换图标
                origin_result[pos[1]][pos[2]] = ITEM_ENUM.Coin
            end
        end
    end

    --最终结果
    local final_result_arr = origin_result_arr

    -- ---------------测试代码-----------
    -- if (save_data.curr_spin_type == SPIN_ENUM.BASE_SPIN) then
    --     local origin_result = origin_result_arr[1]

    --     origin_result[1][1] = 3
    --     origin_result[1][2] = 3
    --     origin_result[1][3] = 3
    --     origin_result[1][4] = 3
    --     origin_result[1][5] = 3

    --     origin_result[2][1] = 3
    -- -- origin_result[2][2] = 3
    -- -- origin_result[2][3] = 3
    -- -- origin_result[2][4] = 3
    -- -- origin_result[2][5] = 3

    -- -- origin_result[3][1] = 3
    -- -- origin_result[3][2] = 3
    -- -- origin_result[3][3] = 3
    -- -- origin_result[3][4] = 3
    -- -- origin_result[3][5] = 3

    -- -- origin_result[4][1] = 3
    -- -- origin_result[4][2] = 3
    -- -- origin_result[4][3] = 3
    -- -- origin_result[4][4] = 3
    -- -- origin_result[4][5] = 3
    -- end
    -- ---------------测试代码-----------

    --金币信息
    local origin_coin_info_arr = {} --初始金币信息
    local final_coin_info_arr = {} --最终金币信息
    local gen_play_again_coin_num = 0 --生成palyAgin金币的数量
    for result_idx = 1, #save_data.reel_info_arr, 1 do
        origin_coin_info_arr[result_idx] = {}
        final_coin_info_arr[result_idx] = {}
    end
    --收集信息
    local collect_info_arr = {}
    --统计信息
    local special_parameter = {
        --下次是否是base_spin
        is_next_base_spin = true,
        --下次是否coin_spin
        is_next_coin_spin = true,
        --Formation的名字
        formation_name = save_data.reel_info_arr[1].formation_name,
        --reels_spin的统计
        reels_spin_param = {
            trigger_by_collect = save_data.reels_spin_param.trigger_by_collect, --reels_spin是否由开盒子触发
            trigger_by_big_box = save_data.reels_spin_param.trigger_by_big_box --reels_spin是否由开启大盒子触发
        },
        --coin_spin的统计
        coin_spin = {
            trigger_times_in_coin = 0,
            end_coin_count = nil, --结算时，金币的数量
            win_chip = 0 --赢钱
        },
        --游戏内jackpot统计
        game_jackpot = {
            [2] = {trigger_times = 0, win_chip = 0},
            [3] = {trigger_times = 0, win_chip = 0},
            [4] = {trigger_times = 0, win_chip = 0},
            [5] = {trigger_times = 0, win_chip = 0}
        },
        --走地图统计
        can_enter_bonus_by_spin = false
    }

    --需要执行功能列举
    local need_check_add_coin_spin_bouts = false --检测是否增加coin_spin次数
    local need_check_add_bonus_game_bouts = false --检测是否会增加bonus_game次数
    local need_gen_coin_info_arr = false --是否需要生成金币信息
    local need_gen_collect_info_arr = false --是否需要生成收集信息
    local need_replace_wild_col = false --是否需要将整列替换为wild（reels_spin进入时，会带有这种奖励的wild列）
    local need_add_jackpot_pool = false --是否需要对jackpot奖池进行增长
    local need_handle_coin_spin = false --是否需要处理coin_spin特性（如金币锁定，coin_spin次数刷新，金币奖励结算）
    local need_handle_reels_spin = false --是否需要处理reel_spin 特性
    local need_line_prize = false --是否需要连线奖励

    --根据当前spin的类型，设置需要执行的功能
    if (save_data.curr_spin_type == SPIN_ENUM.BASE_SPIN) then
        need_check_add_coin_spin_bouts = true
        need_check_add_bonus_game_bouts = true
        need_gen_coin_info_arr = true
        need_gen_collect_info_arr = true
        need_add_jackpot_pool = true
        need_line_prize = true
    elseif (save_data.curr_spin_type == SPIN_ENUM.COIN_SPIN) then
        need_gen_coin_info_arr = true
        need_handle_coin_spin = true
    elseif (save_data.curr_spin_type == SPIN_ENUM.REELS_SPIN) then
        need_replace_wild_col = true
        need_handle_reels_spin = true
        need_line_prize = true
    end

    ----各功能执行
    --检测是否增加coin_spin的次数
    local triger_coin_spin_in_base = false --在base_spin中触发了coin_spin
    if need_check_add_coin_spin_bouts then
        --检测是否触发
        local origin_result = origin_result_arr[1] --BaseGame只会有1个Reel的结果
        local have_trigger = my_cal:HaveEnoughItemInItemArr(origin_result, ITEM_ENUM.Coin, 6)
        --触发了时的数据处理
        if (have_trigger) then
            --游戏信息
            triger_coin_spin_in_base = true
            save_data.coin_spin_bouts = 3
        end
    end

    --检测是否增加bonus_game的次数
    if need_check_add_bonus_game_bouts then
        --检测是否触发
        local origin_result = origin_result_arr[1] --BaseGame只会有1个Reel的结果
        local have_trigger = my_cal:HaveEnoughItemInItemArr(origin_result, ITEM_ENUM.Bonus, 3)
        --触发了时的数据处理
        if (have_trigger) then
            save_data.bonus_game_bouts = save_data.bonus_game_bouts + 1
        end
    end

    --生成金币信息
    if need_gen_coin_info_arr then
        --生成金币的金额信息
        local gen_coin_prize_config = CommonCal.Calculate.get_config(player, game_name .. "CoinConfig")
        for result_idx, origin_result in ipairs(origin_result_arr) do
            --已经锁定的金币信息(--base_spin中，不能使用之前coin_spin的lock信息)
            local lock_coin_info_arr =
                (save_data.curr_spin_type == SPIN_ENUM.BASE_SPIN) and {} or save_data.coin_spin_param.lock_coin_info_arr
            --金币信息生成位置确定
            local gen_coin_pos_arr = my_cal:GetGenCoinInfoPosArr(origin_result, lock_coin_info_arr, ITEM_ENUM)
            --play_agin奖励最大次数限制
            local curr_play_agin_coin_num =
                my_cal:GetAppointTypeNumInCoinArr(lock_coin_info_arr, COIN_PRIZE_ENUM.PLAY_AGAIN) --lock信息中已经有的again图标数量
            local max_play_agin_coin_num = 1 - curr_play_agin_coin_num --再生成的feature_agin的金币图标最大值
            --送出的jackpot的prize表确定
            local send_jackpot_prize_arr = {}
            if triger_coin_spin_in_base then
                local prize_pool = save_data.jackpot_param.prize_pool
                for _, prize_config in ipairs(jackpot_config) do
                    local prize_type = prize_config.prize_type
                    local jackpot_prize = prize_pool[prize_type]
                    local can_win_chip = jackpot_prize.start_point * total_amount + jackpot_prize.extra_chip
                    if can_win_chip / total_amount >= prize_config.max_hold_point then
                        table.insert(send_jackpot_prize_arr, prize_type)
                    end
                end
            end
            --进行金币生成
            origin_coin_info_arr[result_idx], gen_play_again_coin_num =
                my_cal:GenCoinInfoArr(
                save_data,
                player,
                gen_coin_pos_arr,
                gen_coin_prize_config,
                COIN_PRIZE_ENUM.PLAY_AGAIN,
                max_play_agin_coin_num,
                send_jackpot_prize_arr,
                total_amount
            )
            --更新coin_spin中的play_again_bouts次数
            if (save_data.curr_spin_type == SPIN_ENUM.COIN_SPIN) then
                save_data.coin_spin_param.play_again_bouts =
                    save_data.coin_spin_param.play_again_bouts + gen_play_again_coin_num
            end

            -- ---------------测试代码-----------
            -- if (save_data.curr_spin_type == SPIN_ENUM.BASE_SPIN) then
            --     local have_set = false
            --     for row, coin_info_row in pairs(origin_coin_info_arr[result_idx]) do
            --         for col, coin_info in pairs(coin_info_row) do
            --             coin_info.prize_type = COIN_PRIZE_ENUM.PLAY_AGAIN
            --             have_set = true
            --             break
            --         end

            --         if have_set then
            --             break
            --         end
            --     end
            -- end
            -- ---------------测试代码-----------
        end
        final_coin_info_arr = table.DeepCopy(origin_coin_info_arr)
    end

    --生成收集信息
    if need_gen_collect_info_arr then
        --生成收集信息
        local formation_name = save_data.reel_info_arr[1].formation_name
        local formation = _G[game_name .. "FormationArray"][formation_name]
        local row_num = #formation
        local col_num = formation[1]
        local collect_info_arr, gen_count =
            my_cal:GenCollectInfoArr(save_data, player, game_name, origin_result_arr[1], ITEM_ENUM)
        --更新玩家的收集个数与收集元素的金额
        local collect_param = save_data.collect_param
        if collect_param.collect_num + gen_count > 0 then
            --更新每个收集元素的金额
            collect_param.amount_per_collect =
                (collect_param.collect_num * collect_param.amount_per_collect + gen_count * total_amount) /
                (collect_param.collect_num + gen_count)
            --更新收集元素的个数
            collect_param.collect_num = collect_param.collect_num + gen_count
        end
        --发送action给客户端
        if gen_count > 0 then
            table.insert(
                pre_action_list,
                {
                    action_type = ActionType.ActionTypes.CollectItem,
                    add_collect_num = gen_count,
                    curr_collect_num = collect_param.collect_num,
                    collect_info_arr = my_cal:ArrToList_2(collect_info_arr)
                }
            )
        end
    end

    --整列替换为wild
    if need_replace_wild_col then
        -----------------------
        for result_idx, origin_result in ipairs(origin_result_arr) do
            local reel = save_data.reels_spin_param.reels[result_idx]
            if #reel.wild_cols > 0 then --有整轴wild
                --改变origin_result的结果
                for _, col in ipairs(reel.wild_cols) do
                    for row, item_row in pairs(origin_result) do
                        if item_row[col] then
                            item_row[col] = ITEM_ENUM.Wild
                        end
                    end
                end
            -- --添加Action
            -- table.insert(
            --     pre_action_list,
            --     {
            --         action_type = ActionType.ActionTypes.WholeColWild,
            --         feature = {wild_cols = reel.wild_cols}
            --     }
            -- )
            end
        end
    end

    --jackpot奖池增长
    if need_add_jackpot_pool then
        --奖池数据增长
        local prize_pool = save_data.jackpot_param.prize_pool --jackpot奖池
        for _, prize_config in ipairs(jackpot_config) do
            local prize_type = prize_config.prize_type
            local jackpot_prize = prize_pool[prize_type]
            jackpot_prize.extra_chip =
                math.floor(jackpot_prize.extra_chip + total_amount * prize_config.bet_to_chip_percent)
        end
        --添加action
        table.insert(
            pre_action_list,
            {
                action_type = ActionType.ActionTypes.GameJackpotPool,
                parameter_list = {
                    prize_pool = my_cal:GetJakcpotPrizePoolToClient(prize_pool, COIN_PRIZE_ENUM)
                }
            }
        )
    end

    --处理coin_spin的特性
    local is_coin_spin_over = false
    local coin_spin_win = 0 --coin_spin赢得钱
    if need_handle_coin_spin then
        --处理金币spin的信息
        is_coin_spin_over, coin_spin_win, have_take_jackpot =
            my_cal:HandleCoinSpin(
            origin_result_arr,
            final_coin_info_arr,
            save_data,
            jackpot_config,
            total_amount,
            ITEM_ENUM,
            COIN_PRIZE_ENUM,
            special_parameter
        )

        if is_coin_spin_over then
            FeverQuestCal.OnCoinRespinEnd(extern_param.session, coin_spin_win)
        end

        --统计信息
        special_parameter.coin_spin.win_chip = special_parameter.coin_spin.win_chip + coin_spin_win
        if is_coin_spin_over then
            --统计结束时金币的数量
            local end_coin_count = 0
            local lock_coin_info_arr = save_data.coin_spin_param.lock_coin_info_arr
            for row, row_coin_info in pairs(lock_coin_info_arr) do
                for col, coin_info in pairs(row_coin_info) do
                    end_coin_count = end_coin_count + 1
                end
            end
            --结束时，金币数量赋值
            special_parameter.coin_spin.end_coin_count = end_coin_count
        end

        --jackpot被领取时，刷新一次jackpot
        if have_take_jackpot then
            --添加action
            table.insert(
                pre_action_list,
                {
                    action_type = ActionType.ActionTypes.GameJackpotPool,
                    parameter_list = {
                        prize_pool = my_cal:GetJakcpotPrizePoolToClient(
                            save_data.jackpot_param.prize_pool,
                            COIN_PRIZE_ENUM
                        )
                    }
                }
            )
        end

        --插入锁住金币的信息（在coin_spin_win中）
        --计算所有金币的筹码之
        local all_coin_amount = 0
        local lock_coin_info_arr = save_data.coin_spin_param.lock_coin_info_arr
        for row, row_coin_info in pairs(lock_coin_info_arr) do
            for col, coin_info in pairs(row_coin_info) do
                all_coin_amount = all_coin_amount + coin_info.amount
            end
        end
        --添加Action
        table.insert(
            pre_action_list,
            {
                action_type = ActionType.ActionTypes.LockItem,
                parameter_list = {
                    play_again_bouts = save_data.coin_spin_param.play_again_bouts,
                    coin_spin_bouts = save_data.coin_spin_bouts,
                    all_coin_amount = all_coin_amount,
                    lock_coin_info_arr = my_cal:ArrToList_2(lock_coin_info_arr)
                }
            }
        )
    end

    -- reel_spin处理
    if need_handle_reels_spin then
        save_data.reels_spin_bouts = save_data.reels_spin_bouts - 1
        player_game_info.free_spin_bouts = save_data.reels_spin_bouts
    end

    --连线奖励
    local slots_win_chip = 0 --连线赢得钱
    local formation_list = {} --结果展示表
    local all_prize_list = {} --所有的连线奖励表
    local extra_payrate_ratio = CommonCal.Calculate.get_config(player, game_name .. "OthersConfig")[1].Base_Bet_Ratio
    --额外赔付系数
    slots_win_chip, formation_list, all_prize_list =
        my_cal:GenLinePrize(
        player,
        game_room_config,
        game_name,
        save_data.curr_spin_type,
        origin_result_arr,
        final_result_arr,
        save_data.reel_info_arr,
        amount,
        extra_payrate_ratio,
        need_line_prize,
        ITEM_ENUM,
        SPIN_ENUM
    )
    --本次赢得所有钱（连线赢得钱+特殊点赢钱）
    local total_win_chip = slots_win_chip + coin_spin_win

    --检测下次需要进入的spin类型
    local change_to_spin_type = nil --要改变为的游戏状态（如果没有改变，则为nil）
    local can_enter_bonus_game = false --是否可进入小游戏
    local is_agin_coin_spin = false --是否是再次coin_spin
    change_to_spin_type, can_enter_bonus_game, is_agin_coin_spin =
        my_cal:GetChangeToSpinType(save_data, is_coin_spin_over, SPIN_ENUM)

    --直接spin状态进行切换
    local last_spin_type = save_data.curr_spin_type --上次spin的类型
    if change_to_spin_type then --下次的spin类型发生改变
        --额外数据处理
        if (change_to_spin_type == SPIN_ENUM.BASE_SPIN) then
            SlotsGameCal.Calculate.RestoreBetAmountInRunning(player_game_info)
        elseif change_to_spin_type == SPIN_ENUM.COIN_SPIN then
            if is_agin_coin_spin then --再次coin_spin
                --游戏信息
                local coin_spin_param = save_data.coin_spin_param
                coin_spin_param.play_again_bouts = coin_spin_param.play_again_bouts - 1 --减少play_again_bouts次数
                my_cal:SetCoinSpinParamBeforeEnter(
                    save_data,
                    player,
                    game_name,
                    {},
                    coin_spin_param.trigger_by_collect,
                    coin_spin_param.point_amount_when_spin
                ) --再次coin_spin时，清理锁定金币信息
                --统计信息
                special_parameter.coin_spin.trigger_times_in_coin =
                    special_parameter.coin_spin.trigger_times_in_coin + 1
            else
                --设置一般参数
                local coin_spin_param = save_data.coin_spin_param
                local final_coin_info = final_coin_info_arr[1]
                my_cal:SetCoinSpinParamBeforeEnter(save_data, player, game_name, final_coin_info, false, amount)
                --设置起始的play_again_bouts
                local play_again_num = my_cal:GetAppointTypeNumInCoinArr(final_coin_info, COIN_PRIZE_ENUM.PLAY_AGAIN)
                coin_spin_param.play_again_bouts = play_again_num
            end
        elseif change_to_spin_type == SPIN_ENUM.REELS_SPIN then --不存在这种情况，不处理
        end

        --当前spin状态进行切换
        save_data.curr_spin_type = change_to_spin_type --更改spin类型
        my_cal:UpdateCurrReelInfoArr(save_data, SPIN_ENUM) --更新阵形信息
    end

    --填写下次spin的类型数据
    special_parameter.is_next_base_spin = (save_data.curr_spin_type == SPIN_ENUM.BASE_SPIN)
    special_parameter.is_next_coin_spin = (save_data.curr_spin_type == SPIN_ENUM.COIN_SPIN)

    --插入切换spin类型的action
    if change_to_spin_type then
        --确定spin次数
        local spin_bouts = -1
        if change_to_spin_type == SPIN_ENUM.COIN_SPIN then
            spin_bouts = save_data.coin_spin_bouts
        end
        --发送阵形的信息
        table.insert(
            pre_action_list,
            {
                action_type = ActionType.ActionTypes.SwitchSpinType,
                parameter_list = {
                    spin_type = save_data.curr_spin_type,
                    spin_bouts = spin_bouts,
                    reel_info_arr = save_data.reel_info_arr
                }
            }
        )
    end

    --触发可进入bonus_game
    if can_enter_bonus_game then
        player_game_info.bonus_game_type = 1 --记录进入bonus_game
        my_cal:SetBonusGameParamBeforeEnter( --设置进入bonus_game的数据
            save_data,
            player,
            game_name,
            false,
            total_amount,
            MAP_PRIZE_ENUM,
            TURNAROUND_RESULT_ENUM
        )
        --通知客户端action
        table.insert(pre_action_list, {action_type = ActionType.ActionTypes.EnterBonus})

        --统计信息
        special_parameter.can_enter_bonus_by_spin = true
    end

    --显示的金币信息更新
    --内存信息更新
    save_data.coin_info_arr = final_coin_info_arr[1]
    --发送给客户端
    if next(save_data.coin_info_arr) then
        table.insert(
            pre_action_list,
            {
                action_type = ActionType.ActionTypes.CoinInfoArr,
                parameter_list = my_cal:ArrToList_2(save_data.coin_info_arr)
            }
        )
    end

    --插入锁住金币的信息（首次进入coin——spin时）
    if last_spin_type ~= SPIN_ENUM.COIN_SPIN and save_data.curr_spin_type == SPIN_ENUM.COIN_SPIN then
        --计算所有金币的筹码之
        local all_coin_amount = 0
        local lock_coin_info_arr = save_data.coin_spin_param.lock_coin_info_arr
        for row, row_coin_info in pairs(lock_coin_info_arr) do
            for col, coin_info in pairs(row_coin_info) do
                all_coin_amount = all_coin_amount + coin_info.amount
            end
        end

        --添加Action
        table.insert(
            pre_action_list,
            {
                action_type = ActionType.ActionTypes.LockItem,
                parameter_list = {
                    play_again_bouts = save_data.coin_spin_param.play_again_bouts,
                    coin_spin_bouts = save_data.coin_spin_bouts,
                    all_coin_amount = all_coin_amount,
                    lock_coin_info_arr = my_cal:ArrToList_2(lock_coin_info_arr)
                }
            }
        )
    end

    --返回结果中插入aciton
    local pre_action_list_json = json.encode(pre_action_list)
    for _, formation in pairs(formation_list) do
        for _, slots_spin in pairs(formation.slots_spin_list) do
            slots_spin.pre_action_list = pre_action_list_json
        end
    end

    --保存缓存数据
    my_cal:RecordSaveData(player_game_info, save_data)
    -------------------------------------------------------------
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

--------------------------------------------------
--*********************Bonus**********************
--进入小游戏
BonusEnter = function(task, player, game_room_config, parameter, player_game_info)
    --初始化返回值
    local content = {}

    --部分变量缓存
    local game_name = game_room_config.game_name --游戏名字
    --读取缓存数据
    local save_data = my_cal:GetSaveData(player, player_game_info, game_name, SPIN_ENUM) --检查缓存数据的完整性

    --逻辑处理
    if save_data.bonus_game_bouts > 0 then
        local get_config_func = CommonCal.Calculate.get_config
        local ordinary_item_arr_config = get_config_func(player, game_name .. "BonusMapOrdinaryItemArrConfig") --地图普通格子配置
        local special_item_arr_config = get_config_func(player, game_name .. "BonusMapSpecialItemArrConfig") --地图特殊格子配置
        local turnaround_config = get_config_func(player, game_name .. "BonusTurnaroundConfig") --转盘配置
        local bonus_game_param = save_data.bonus_game_param --bonus参数取出
        ----返回的地图信息生成
        local client_map_info = {ordinary_item_arr = {}, special_item_arr = {}}
        --普通格子
        local ordinary_item_use_arr = bonus_game_param.map_prize_use_info_arr.ordinary_item_use_arr
        for item_idx, item_info in ipairs(ordinary_item_arr_config) do --普通格子获取
            local item_use_info = ordinary_item_use_arr[item_idx]
            client_map_info.ordinary_item_arr[item_idx] =
                my_cal:GetClinetMapOrdinaryItemInfo(
                item_info,
                item_use_info,
                bonus_game_param.base_amount,
                MAP_PRIZE_ENUM
            )
        end
        --特殊格子
        local special_item_use_arr = bonus_game_param.map_prize_use_info_arr.special_item_use_arr
        for item_idx, item_info in ipairs(special_item_arr_config) do --特殊格子获取
            local item_use_info = special_item_use_arr[item_idx]
            client_map_info.special_item_arr[item_idx] = my_cal:GetClinetMapSpecialItemInfo(item_info, item_use_info)
        end

        --填入数据
        content = {
            bonus_win = bonus_game_param.bonus_win,
            collect_num = save_data.collect_param.collect_num,
            walk_pos = bonus_game_param.walk_pos,
            walk_end = bonus_game_param.walk_end,
            reels_spin_param = bonus_game_param.reels_spin_param,
            turnaround_config = turnaround_config,
            map_info = client_map_info,
            next_spin_predict = bonus_game_param.next_spin_predict
        }
    end

    --保存缓存数据
    my_cal:RecordSaveData(player_game_info, save_data)

    --返回
    return content
end

--小游戏转转盘行走
BonusWalk = function(task, player, game_room_config, parameter, player_game_info)
    --初始化返回值
    local content = {}

    --部分变量缓存
    local game_name = game_room_config.game_name --游戏名字
    --读取缓存数据
    local save_data = my_cal:GetSaveData(player, player_game_info, game_name, SPIN_ENUM) --检查缓存数据的完整性
    local bonus_game_param = save_data.bonus_game_param --小游戏的参数

    --逻辑处理
    if save_data.bonus_game_bouts > 0 then
        local get_config_func = CommonCal.Calculate.get_config
        local ordinary_item_arr_config = get_config_func(player, game_name .. "BonusMapOrdinaryItemArrConfig") --地图普通格子配置
        local special_item_arr_config = get_config_func(player, game_name .. "BonusMapSpecialItemArrConfig") --地图特殊格子配置
        local turnaround_config = get_config_func(player, game_name .. "BonusTurnaroundConfig") --转盘配置

        --生成转盘结果
        local turnaround_result_idx, turnaround_result, collect_num =
            my_cal:GenBonusTurnaroundReslut(player, turnaround_config)
        local turnaround_prize = {collect_num = collect_num} --转盘奖励
        save_data.collect_param.collect_num = save_data.collect_param.collect_num + collect_num --更新收集记录
        ----开始行走并计算奖励
        local walk_prize = {} --行走产生的奖励
        if (turnaround_result ~= TURNAROUND_RESULT_ENUM.COLLECT) then --轮盘结果为非收集，则可以走动
            --部分变量缓存
            local start_pos = bonus_game_param.walk_pos --起点位置
            local curr_pos = start_pos --当前的位置
            local gen_wild_col_config = CommonCal.Calculate.get_config(player, game_name .. "WildReelConfig") --wild列生成的配置表
            --第一步普通行走
            local walk_end, destination_pos_1 =
                my_cal:GetDestinPosByTurnaroundReslut(
                ordinary_item_arr_config,
                special_item_arr_config,
                turnaround_result,
                curr_pos
            )
            if walk_end then --本次行走超过了终点，没有地方可走了
                bonus_game_param.walk_end = true --结束行走
            else --有可以走到的地方
                --已经到了地图最后一格，行走也结束了
                if destination_pos_1 == #ordinary_item_arr_config then
                    bonus_game_param.walk_end = true --结束行走
                end

                --位置
                curr_pos = destination_pos_1 --更新当前位置
                bonus_game_param.walk_pos = curr_pos --更新缓存数据
                --奖励
                local ordinary_item_use = bonus_game_param.map_prize_use_info_arr.ordinary_item_use_arr[curr_pos]
                local receive_prize, change_ordinary_item =
                    my_cal:ConsumMapPrizeWhenWalkIntoOridinary(
                    ordinary_item_arr_config[curr_pos],
                    ordinary_item_use,
                    bonus_game_param.base_amount,
                    MAP_PRIZE_ENUM
                ) --获取并消耗奖励
                --服务器奖励进行记录
                my_cal:PlayerReceiveMapItemPrize(save_data, player, receive_prize, gen_wild_col_config, MAP_PRIZE_ENUM)
                --返回给客户端的行走记录
                local change_ordinary_item_client =
                    change_ordinary_item and {pos = {curr_pos}, data = change_ordinary_item} or nil

                table.insert(
                    walk_prize,
                    {
                        destin_pos = curr_pos,
                        prize = receive_prize,
                        map_change_info = {
                            ordinary_item_arr = {
                                change_ordinary_item_client
                            }
                        }
                    }
                )
            end
            --检测第二部特殊行走（即滑梯）
            if not bonus_game_param.walk_end then
                --寻找可用的特殊物品
                local use_special_item_idx = nil
                for item_idx, special_item in ipairs(special_item_arr_config) do
                    if special_item.from_pos == curr_pos then
                        local special_item_use = bonus_game_param.map_prize_use_info_arr.special_item_use_arr[item_idx]
                        if special_item.prize_bouts == -1 or special_item_use.bouts < special_item.prize_bouts then
                            use_special_item_idx = item_idx
                            break
                        end
                    end
                end
                --使用特殊物品
                if use_special_item_idx then
                    --走滑梯
                    local special_item = special_item_arr_config[use_special_item_idx] --使用的特殊物品
                    local special_item_use =
                        bonus_game_param.map_prize_use_info_arr.special_item_use_arr[use_special_item_idx]
                    local destination_pos_2, change_special_item =
                        my_cal:ConsumMapPrizeWhenWalkIntoSpecial(special_item, special_item_use) --消耗特殊格子的奖励

                    --走入普通格子
                    curr_pos = destination_pos_2 --更新当前位置
                    bonus_game_param.walk_pos = curr_pos --更新缓存数据

                    --奖励
                    local ordinary_item_use = bonus_game_param.map_prize_use_info_arr.ordinary_item_use_arr[curr_pos]
                    local receive_prize, change_ordinary_item =
                        my_cal:ConsumMapPrizeWhenWalkIntoOridinary(
                        ordinary_item_arr_config[curr_pos],
                        ordinary_item_use,
                        bonus_game_param.base_amount,
                        MAP_PRIZE_ENUM
                    ) --获取并消耗奖励
                    --服务器奖励进行记录
                    my_cal:PlayerReceiveMapItemPrize(
                        save_data,
                        player,
                        receive_prize,
                        gen_wild_col_config,
                        MAP_PRIZE_ENUM
                    )
                    --返回给客户端的行走记录
                    local change_ordinary_item_client =
                        change_ordinary_item and {pos = {curr_pos}, data = change_ordinary_item} or nil
                    local change_special_item_client =
                        change_special_item and {pos = {use_special_item_idx}, data = change_special_item} or nil
                    table.insert(
                        walk_prize,
                        {
                            destin_pos = curr_pos,
                            prize = receive_prize,
                            map_change_info = {
                                ordinary_item_arr = {
                                    change_ordinary_item_client
                                },
                                special_item_arr = {
                                    change_special_item_client
                                }
                            }
                        }
                    )
                end
            end
        end
        --计算客户端下次转盘转到各个色块，是否结束游戏的预判结果
        local next_spin_predict =
            my_cal:GetBonusNextSpinPredictArr(
            ordinary_item_arr_config,
            special_item_arr_config,
            turnaround_config,
            bonus_game_param.walk_pos,
            TURNAROUND_RESULT_ENUM
        )
        bonus_game_param.next_spin_predict = next_spin_predict --缓存数据记录
        --填入数据
        content = {
            walk_end = bonus_game_param.walk_end,
            turnaround_result_idx = turnaround_result_idx,
            turnaround_prize = turnaround_prize,
            walk_prize = walk_prize,
            next_spin_predict = next_spin_predict
        }
    end

    --保存缓存数据
    my_cal:RecordSaveData(player_game_info, save_data)

    --返回
    return content
end

--小游戏结算
BonusSettle = function(task, player, game_room_config, parameter, player_game_info, game_type, session)
    --初始化返回值
    local content = {}

    --部分变量缓存
    local game_name = game_room_config.game_name --游戏名字
    --读取缓存数据
    local save_data = my_cal:GetSaveData(player, player_game_info, game_name, SPIN_ENUM) --检查缓存数据的完整性
    local bonus_game_param = save_data.bonus_game_param --小游戏的参数

    --逻辑处理
    if save_data.bonus_game_bouts > 0 then
        --玩家的数据处理
        player_game_info.bonus_game_type = 0 --清空玩家当前的bond_game_type
        save_data.bonus_game_bouts = save_data.bonus_game_bouts - 1 --bonus_game次数减少
        --从bonus_game数据获取多轴转动的数据
        --确定下注额度
        local point_amount_when_spin = 0
        local reel_line_name = save_data.reel_info_arr[1].line_name
        local line_num = #(_G[game_name .. "LineArray"][reel_line_name]) --线数
        local point_amount_when_spin = bonus_game_param.base_amount / line_num
        --更改当前spin状态为REELS_SPIN
        save_data.curr_spin_type = SPIN_ENUM.REELS_SPIN --当前spin状态进行切换
        my_cal:SetReelsSpinParamBeforeEnter( --设置多轴转动的参数
            save_data,
            player_game_info,
            bonus_game_param.reels_spin_param.reels_spin_bouts,
            bonus_game_param.reels_spin_param.reels,
            bonus_game_param.trigger_by_collect,
            false,
            point_amount_when_spin
        )
        my_cal:UpdateCurrReelInfoArr(save_data, SPIN_ENUM) --更新转轴信息
        player_game_info.free_total_win = 0 --清零free-spin的总赢钱
        --添加action数据
        local pre_action_list = {}
        local spin_bouts = save_data.reels_spin_bouts
        --发送阵形的信息
        table.insert(
            pre_action_list,
            {
                action_type = ActionType.ActionTypes.SwitchSpinType,
                parameter_list = {
                    spin_type = save_data.curr_spin_type,
                    spin_bouts = spin_bouts,
                    reel_info_arr = save_data.reel_info_arr
                }
            }
        )
        --发送下注值改变的信息
        SlotsGameCal.Calculate.ChangeBetAmountInRunning(
            player_game_info,
            pre_action_list,
            math.floor(point_amount_when_spin),
            spin_bouts,
            0
        )

        --填写返回值
        content = {
            --用于通知客户端
            bonus_win = bonus_game_param.bonus_win,
            collect_num = save_data.collect_param.collect_num,
            reels_spin_param = bonus_game_param.reels_spin_param,
            pre_action_list = pre_action_list,
            --通用逻辑加钱
            win_chip = bonus_game_param.bonus_win
        }

        FeverQuestCal.OnMiniGameEnd(session, game_type, bonus_game_param.bonus_win)
    end

    --保存缓存数据
    my_cal:RecordSaveData(player_game_info, save_data)

    --返回
    return content
end

--统计使用 直接bonus走到终点
StatisticsBonusWalkToEnd = function(player, game_room_config, player_game_info)
    --初始化返回值
    local win_chip = 0
    local collect_num = 0
    local reels_spin_bouts = 0
    local wild_cols = {}
    local add_row = 0
    local add_reel = 0

    --部分变量缓存
    local game_name = game_room_config.game_name --游戏名字
    --读取缓存数据
    local save_data = my_cal:GetSaveData(player, player_game_info, game_name, SPIN_ENUM) --检查缓存数据的完整性
    local collect_num_before_walk = save_data.collect_param.collect_num
    my_cal:RecordSaveData(player_game_info, save_data) --保存缓存数据
    --走地图
    while true do
        --调用走路接口
        local walk_content = BonusWalk(nil, player, game_room_config, nil, player_game_info)
        --走到终点时，停止
        if walk_content.walk_end then
            break
        end
    end
    --结算
    local settle_content = BonusSettle(nil, player, game_room_config, nil, player_game_info)
    win_chip = settle_content.win_chip
    collect_num = settle_content.collect_num - collect_num_before_walk
    reels_spin_bouts = settle_content.reels_spin_param.reels_spin_bouts
    wild_cols = settle_content.reels_spin_param.reels[1].wild_cols
    add_row = settle_content.reels_spin_param.reels[1].row_num - 3
    add_reel = #(settle_content.reels_spin_param.reels) - 1

    --返回
    return win_chip, collect_num, reels_spin_bouts, wild_cols, add_row, add_reel
end

--************************************************
--------------------------------------------------

--------------------------------------------------
--********************Collect*********************
--进入收集页面
CollectEnter = function(task, player, game_room_config, parameter, player_game_info)
    --初始化返回值
    local content = nil
    --部分变量缓存
    local game_name = game_room_config.game_name --游戏名字
    --读取缓存数据
    local save_data = my_cal:GetSaveData(player, player_game_info, game_name, SPIN_ENUM) --检查缓存数据的完整性

    --配置获取
    local collect_prize_page_config = CommonCal.Calculate.get_config(player, game_name .. "CollectPrizePageConfig")
    --填入数据
    local collect_param = save_data.collect_param
    content = {
        collect_num = collect_param.collect_num,
        curr_page = collect_param.curr_page,
        collect_page_arr = my_cal:GetClientCollectPageArr(
            collect_prize_page_config,
            collect_param.collect_page_open_arr
        )
    }

    --保存缓存数据
    my_cal:RecordSaveData(player_game_info, save_data)

    --返回
    return content
end

--打开盒子
CollectOpenBox = function(task, player, game_room_config, parameter, player_game_info)
    --初始化返回值
    local content = nil
    --部分变量缓存
    local game_name = game_room_config.game_name --游戏名字
    --读取缓存数据
    local save_data = my_cal:GetSaveData(player, player_game_info, game_name, SPIN_ENUM) --检查缓存数据的完整性

    --请求数据获取
    local open_request = json.decode(parameter)
    local box_pos = open_request.box_pos
    local is_open_big_box = open_request.is_open_big_box

    --请求响应逻辑
    local success = false --开启是否成功
    local prize_info = nil --开启的奖励
    local change_collect_page_arr = {} --开启后，对奖品礼盒产生影响
    local amount_the_open_collect = 0 --开启盒子的使用的收集物品的价值
    local collect_prize_page_config = CommonCal.Calculate.get_config(player, game_name .. "CollectPrizePageConfig")
    local collect_param = save_data.collect_param
    success, prize_info, change_collect_page_arr, amount_the_open_collect =
        my_cal:OpenCollectBox(
        save_data,
        player,
        game_name,
        collect_prize_page_config,
        collect_param.amount_per_collect,
        is_open_big_box,
        box_pos.page_idx,
        box_pos.arr_idx,
        COLLECT_PRIZE_ENUM
    )

    --奖励发放
    local collect_win_chip = 0
    local pre_action_list = {}
    if (success) then
        local need_switch_spin_type = false --是否会切换spin的类型
        local prize_type = prize_info.prize_type --奖励类型
        local prize_val = prize_info.prize_val
        local point_amount_when_spin = 0
        if prize_type == COLLECT_PRIZE_ENUM.CHIP then --筹码类型奖励
            collect_win_chip = prize_val
        elseif prize_type == COLLECT_PRIZE_ENUM.COIN_SPIN then --coin_spin类型
            --设置游戏状态
            need_switch_spin_type = true
            save_data.curr_spin_type = SPIN_ENUM.COIN_SPIN
            my_cal:SetCoinSpinParamBeforeEnter(save_data, player, game_name, {}, true, 0)
            my_cal:UpdateCurrReelInfoArr(save_data, SPIN_ENUM)
            --确定下注额度
            local reel_line_name = save_data.reel_info_arr[1].line_name
            local line_num = #(_G[game_name .. "LineArray"][reel_line_name]) --线数
            point_amount_when_spin = amount_the_open_collect / line_num
            save_data.coin_spin_param.point_amount_when_spin = point_amount_when_spin
        elseif prize_type == COLLECT_PRIZE_ENUM.BONUS_GAME then --BONUS_GAME类型
            --设置游戏状态
            save_data.bonus_game_bouts = save_data.bonus_game_bouts + 1 --bonus_game_bouts次数累加
            player_game_info.bonus_game_type = 1 --记录进入bonus_game
            my_cal:SetBonusGameParamBeforeEnter( --设置进入bonus_game的数据
                save_data,
                player,
                game_name,
                true,
                collect_param.amount_per_collect,
                MAP_PRIZE_ENUM,
                TURNAROUND_RESULT_ENUM
            )
            --添加action
            table.insert(pre_action_list, {action_type = ActionType.ActionTypes.EnterBonus})
            SlotsGameCal.Calculate.ClearFreeSpinedCount(player_game_info)
            SlotsGameCal.Calculate.ClearTotalFreeSpinCount(player_game_info)
        elseif prize_type == COLLECT_PRIZE_ENUM.REELS_SPIN then --REELS_SPIN类型
            --确定下注额度
            local reel_line_name = save_data.reel_info_arr[1].line_name
            local line_num = #(_G[game_name .. "LineArray"][reel_line_name]) --线数
            point_amount_when_spin = amount_the_open_collect / line_num
            --设置游戏状态
            ----清除上次FreeSpin的状态
            player_game_info.free_total_win = 0 --清零free-spin的总赢钱
            SlotsGameCal.Calculate.ClearFreeSpinedCount(player_game_info)
            SlotsGameCal.Calculate.ClearTotalFreeSpinCount(player_game_info)
            ----设置本次FreeSpin
            need_switch_spin_type = true
            save_data.curr_spin_type = SPIN_ENUM.REELS_SPIN
            my_cal:SetReelsSpinParamBeforeEnter(
                save_data,
                player_game_info,
                prize_val.reels_spin_bouts,
                prize_val.reels,
                true,
                true,
                point_amount_when_spin
            )
            my_cal:UpdateCurrReelInfoArr(save_data, SPIN_ENUM)
        end

        --阵形变化的aciton
        if need_switch_spin_type then
            --确定spin次数
            local spin_bouts = -1
            if save_data.curr_spin_type == SPIN_ENUM.COIN_SPIN then
                spin_bouts = save_data.coin_spin_bouts
            elseif save_data.curr_spin_type == SPIN_ENUM.REELS_SPIN then
                spin_bouts = save_data.reels_spin_bouts
            end
            --发送阵形的信息
            table.insert(
                pre_action_list,
                {
                    action_type = ActionType.ActionTypes.SwitchSpinType,
                    parameter_list = {
                        spin_type = save_data.curr_spin_type,
                        spin_bouts = spin_bouts,
                        reel_info_arr = save_data.reel_info_arr
                    }
                }
            )
            --发送下注值改变的信息
            SlotsGameCal.Calculate.ChangeBetAmountInRunning(
                player_game_info,
                pre_action_list,
                math.floor(point_amount_when_spin),
                spin_bouts,
                0
            )
        end
    end

    --填入数据
    content = {
        --玩法逻辑参数
        open_request = open_request,
        open_result = {
            success = success,
            collect_num = collect_param.collect_num,
            curr_page = collect_param.curr_page,
            prize_info = prize_info,
            change_collect_page_arr = change_collect_page_arr,
            pre_action_list = pre_action_list
        },
        --通用逻辑加钱
        win_chip = collect_win_chip
    }

    --保存缓存数据
    my_cal:RecordSaveData(player_game_info, save_data)

    --返回
    return content
end

--统计系统开启盒子
StatisticsCollectOpenBox = function(player, game_room_config, player_game_info)
    --初始化返回值
    local open_success = false
    local win_chip = 0
    local reels_spin_bouts = 0
    local wild_cols = nil
    local can_enter_bonus_game = false
    local can_enter_coin_spin = false

    --部分变量缓存
    local game_name = game_room_config.game_name --游戏名字
    --读取缓存数据
    local save_data = my_cal:GetSaveData(player, player_game_info, game_name, SPIN_ENUM) --检查缓存数据的完整性
    local collect_param = save_data.collect_param --收集信息
    local collect_page_open_arr = collect_param.collect_page_open_arr --开启的信息
    local collect_prize_page_config = CommonCal.Calculate.get_config(player, game_name .. "CollectPrizePageConfig")
    my_cal:RecordSaveData(player_game_info, save_data) --保存缓存数据
    --尝试开盒子
    local open_request = nil --开盒子的请求
    --寻找可以开的盒子
    for page_idx, page_prize_config in ipairs(collect_prize_page_config) do
        local need_collect_num = page_prize_config.need_collect_num
        local collect_page_open = collect_page_open_arr[page_idx]
        --先找小盒子
        if collect_param.collect_num >= need_collect_num then
            for box_idx, little_box_open_info in ipairs(collect_page_open.little_box_open_info_arr) do
                if not little_box_open_info.opened then
                    open_request = {
                        box_pos = {
                            page_idx = page_idx,
                            arr_idx = box_idx
                        },
                        is_open_big_box = false
                    }
                    break
                end
            end
        end
        --找到了可以开启的盒子就不找了
        if open_request then
            break
        end

        --再找大盒子
        if collect_page_open.big_box_open_info.can_open then
            open_request = {
                box_pos = {
                    page_idx = page_idx,
                    arr_idx = 0
                },
                is_open_big_box = true
            }
            break
        end
    end
    --尝试开启盒子
    if open_request then
        --触发次数
        open_success = true
        --赢钱
        local content = CollectOpenBox(nil, player, game_room_config, json.encode(open_request), player_game_info)
        local prize_info = content.open_result.prize_info
        local prize_type = prize_info.prize_type
        local prize_val = prize_info.prize_val
        if prize_type == COLLECT_PRIZE_ENUM.CHIP then
            win_chip = prize_val
        elseif prize_type == COLLECT_PRIZE_ENUM.COIN_SPIN then
            can_enter_coin_spin = true
        elseif prize_type == COLLECT_PRIZE_ENUM.BONUS_GAME then
            can_enter_bonus_game = true
        elseif prize_type == COLLECT_PRIZE_ENUM.REELS_SPIN then --REELS_SPIN类型
            reels_spin_bouts = prize_val.reels_spin_bouts
            wild_cols = prize_val.reels[1].wild_cols
        end
    end

    --返回
    return open_success, win_chip, reels_spin_bouts, wild_cols, can_enter_bonus_game, can_enter_coin_spin
end
--************************************************
--------------------------------------------------
