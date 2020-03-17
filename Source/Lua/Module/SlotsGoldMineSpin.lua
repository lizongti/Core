require "Common/SlotsGameCalculate" --重写的接口
require "Common/SlotsGameCal" --旧的接口
require "Common/SlotsGoldMineCal" --专用的函数
require "dkjson"

--变量缓存
--变量缓存
local Types = _G["GoldMineTypeArray"].Types
local my_cal = GoldMineCalClass
--枚举定义
--spin类型
local SPIN_ENUM = {
    BASE_SPIN = 1, --基础spin
    HOLD_SPIN = 2, --炸药合成Spin
    FREE_SPIN = 3 --Free Spin
}
--Bonus类型
local BONUS_ENUM = {
    PICK_BONUS_1 = 1, --捡取的小游戏1
    PICK_BONUS_2 = 2, --捡取的小游戏2
    TURNAROUND_BONUS = 3, --转盘小游戏
    SPIN_BONUS = 4 --选择spin类型的小游戏
}
--奖励类型
local PRIZE_TYPE_ENUM = {
    JAKCPOT_MEGA = 1,
    JAKCPOT_GRAND = 2,
    JACKPOT_MAJOR = 3,
    JACKPOT_MINOR = 4,
    JACKPOT_MINI = 5,
    CHIP = 6,
    JACKPOT_DOUBLE = 7
}
--方法对象初始化
SlotsGoldMineSpin = {}

do --Spin
    function SlotsGoldMineSpin:Enter()
        --返回数据初始化
        local bonus_info = nil

        --取出变量
        local player = self.parameters.player
        local game_room_config = self.parameters.game_room_config
        local player_game_info = self.parameters.player_game_info
        local player_game_status = self.parameters.player_game_status
        local game_name = game_room_config.game_name --游戏名字
        local save_data = my_cal:GetSaveData(player, player_game_info, game_name, SPIN_ENUM, PRIZE_TYPE_ENUM) --检查缓存数据的完整性

        --返回数据计算
        ----Spin信息
        local curr_spin_type = SPIN_ENUM.BASE_SPIN
        local spin_bouts = -1
        local spin_status_info = GameStatusCal.Calculate.GetSpinStatusInfo(player_game_status)
        if spin_status_info then
            if spin_status_info.status_id == GameStatusDefine.AllTypes.FreeSpinGame then
                curr_spin_type = SPIN_ENUM.REELS_SPIN
                spin_bouts = spin_status_info.total_process - spin_status_info.process
            elseif spin_status_info.status_id == GameStatusDefine.AllTypes.FreeSpinGame then
                curr_spin_type = SPIN_ENUM.COIN_SPIN
                spin_bouts = spin_status_info.total_process - spin_status_info.process
            end
        else --2中情况：1.新玩家 2.2代服务器缓存的老玩家玩家
            --进行数据清理
            save_data.curr_spin_type = curr_spin_type
            save_data.reel_info_arr = {
                {
                    id = 1,
                    formation_name = "Formation1",
                    line_name = "Lines1",
                    feature_file_name = nil,
                    wild_cols = {}
                }
            }
        end
        ----Bonus信息
        local bonus_game_type = 0
        local cur_status_info = GameStatusCal.Calculate.GetGameStatusInfo(player_game_status)
        if cur_status_info and cur_status_info.status_id == GameStatusDefine.AllTypes.BonusSpinGame then
            bonus_game_type = player_game_info.bonus_game_type
        end
        --返回数据填入
        bonus_info = {
            in_bonus_game = bonus_game_type > 0,
            bonus_game_type = bonus_game_type,
            curr_spin_type = curr_spin_type,
            spin_bouts = spin_bouts,
            reel_info_arr = save_data.reel_info_arr,
            jackpot_param = my_cal:GetJakcpotParamToClient(save_data.jackpot_param_v2),
            curr_rope = {
                rope_idx = save_data.fire_rope_param.curr_rope_idx,
                left_knat_count = save_data.fire_rope_param.left_knat_count
            }
        }
        --保存缓存数据
        my_cal:RecordSaveData(player_game_info, save_data)

        --返回
        return bonus_info
    end

    function SlotsGoldMineSpin:NormalSpin()
        --取出变量
        ----统一取出
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
        local game_name = game_room_config.game_name --游戏名字
        local ITEM_ENUM = _G[game_name .. "TypeArray"].Types --图标的枚举
        local jackpot_config = CommonCal.Calculate.get_config(player, game_name .. "JackpotConfig")
        local save_data = my_cal:GetSaveData(player, player_game_info, game_name, SPIN_ENUM, PRIZE_TYPE_ENUM) --检查缓存数据的完整性

        --确定spin的特性
        local pre_action_list = {} --传给客户端的动作
        local add_free_spin_bouts = 0 --本次spin中增加的reels_spin次数
        local reel_file_name  --reel表名
        local total_win_chip = 0 --本次spin的赢钱

        --确定转轴
        local use_last_point_reel = false --select—bonus中触发的hold-spin，在hold-spin一次后，才算是真正hold-spin的开始
        local weight_file_name = nil --权重轴的名字
        local curlineNum = LineNum[player_game_info.game_type]()
        local config_table =
            SlotsGameCal.Calculate.GetMapConfigTable(
            extern_param.session,
            game_room_config,
            player_game_info,
            amount * curlineNum
        )
        local spin_reel_info_arr = save_data.reel_info_arr --spin使用的转轴信息
        if save_data.curr_spin_type == SPIN_ENUM.BASE_SPIN then
            weight_file_name = config_table.base_reel_weight_config
        elseif save_data.curr_spin_type == SPIN_ENUM.HOLD_SPIN then
            --指定spin转轴的信息的处理
            local point_reel_info_arr_list = save_data.hold_spin_param.point_reel_info_arr_list
            if point_reel_info_arr_list and point_reel_info_arr_list[1] then
                spin_reel_info_arr = point_reel_info_arr_list[1] --取出第一个指定的转轴信息
                table.remove(point_reel_info_arr_list, 1) --使用后一处

                --判断是否时hold_spin的最后一个指定轴
                if #point_reel_info_arr_list == 0 then
                    use_last_point_reel = true
                    weight_file_name = config_table.holdspin_start_reel_weight_config
                else
                    weight_file_name = config_table.holdspin_reel_weight_config
                end
            end
        elseif save_data.curr_spin_type == SPIN_ENUM.FREE_SPIN then
            weight_file_name = config_table.feature_reel_weight_config
        end
        --确定投注额度
        local reel_line_name = spin_reel_info_arr[1].line_name
        local lineNum = #(_G[game_name .. "LineArray"][reel_line_name]) --线数
        if (save_data.curr_spin_type == SPIN_ENUM.HOLD_SPIN) then
            amount = save_data.hold_spin_param.total_amount / lineNum
        elseif (save_data.curr_spin_type == SPIN_ENUM.FREE_SPIN) then
            amount = save_data.free_spin_param.total_amount / lineNum
        end
        local total_amount = amount * lineNum --总共下注用的钱
        --生成滚动结果
        local origin_result_arr = {}
        for result_idx = 1, #spin_reel_info_arr, 1 do
            local reel_info = spin_reel_info_arr[result_idx]
            origin_result_arr[result_idx], reel_file_name =
                SlotsGameCal.Calculate.GenItemResultWithWeight(
                player,
                game_type,
                is_free_spin,
                game_room_config,
                reel_info.feature_file_name,
                weight_file_name,
                reel_info.formation_name
            )
        end
        --测试代码
        -- if save_data.curr_spin_type == SPIN_ENUM.BASE_SPIN then
        --     local origin_result = origin_result_arr[1]
        --     origin_result[1][1] = 5
            -- origin_result[1][2] = 5
            -- origin_result[1][3] = 5
            -- origin_result[1][4] = 5
            -- origin_result[1][5] = 5

            -- origin_result[2][1] = 5
            -- origin_result[2][2] = 1
            -- origin_result[2][3] = 1
            -- origin_result[2][4] = 1
            -- origin_result[2][5] = 5

            -- origin_result[3][1] = 5
            -- origin_result[3][2] = 5
            -- origin_result[3][3] = 5
            -- origin_result[3][4] = 5
            -- origin_result[3][5] = 5
        -- elseif (save_data.curr_spin_type == SPIN_ENUM.FREE_SPIN) then
        --     local origin_result = origin_result_arr[1]

        --     origin_result[1][1] = 6
        --     origin_result[1][2] = 6
        --     origin_result[1][3] = 6
        --     -- origin_result[1][4] = 5
        --     -- origin_result[1][5] = 5

        --     origin_result[2][1] = 6
        --     origin_result[2][2] = 6
        --     origin_result[2][3] = 6
        --     -- origin_result[2][4] = 1
        --     -- origin_result[2][5] = 1

        --     origin_result[3][1] = 6
        --     origin_result[3][2] = 6
        --     origin_result[3][3] = 3
        -- -- origin_result[3][4] = 1
        -- -- origin_result[3][5] = 1
        -- end
        --测试代码

        local final_result_arr = table.DeepCopy(origin_result_arr) --最终结果
        local settle_result_arr = table.DeepCopy(origin_result_arr) --结算结果

        --进入其他流程前的进入信息
        local formation_name = spin_reel_info_arr[1].formation_name
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
            --游戏类型标记
            GoldMine = true,
            --当前spin类型
            spin_type = save_data.curr_spin_type,
            --FreeSpin
            free_spin = {
                line_payrate_map = {} --每条线的赔率
            },
            --烧绳子的统计
            fire_rope = {
                need_statistic = false, --是否需要统计
                rope_idx = 0, --当前绳子的索引
                is_try_fire = false, --是否尝试燃烧过了
                have_fire_whole_rope = false --是否烧完了整条绳子
            },
            --HoldSpin统计
            hold_spin = {
                is_over = false, --是否结束
                total_bouts = 0, --spin的总次数
                detonator_count_trigger = 0, --触发时小炸药的个数
                detonator_type_arr = {}, --炸药类型的数组
                detonator_result = nil, --炸药的结果形成的字符串
                jackpot_arr = {}, --jackpot数组
                win_chip = 0 --赢钱
            }
        }

        --需要执行功能列举
        local need_add_jackpot = false --是否需要累加jackpot奖池筹码
        local need_push_jackpot = false --是否需要推送jackpot奖池信息
        local need_check_fire_rope = false --是否需要检测燃烧绳子
        local nedd_check_add_hold_spin_bouts = false --是否检查增加hold_spin的次数
        local need_check_add_spin_bonus = false --是否需要检查增加spin-bonus的次数
        local need_handle_hold_spin = false --是否需要处理hold-spin数据
        local need_handle_free_spin = false --是否需要处理free-spin数据
        local need_move_wild = false --是否需要触发move_wild特性
        local need_line_prize = false --是否需要连线奖励
        local need_check_free_spin_over = false --是否需要检测free-spin结束

        --根据当前spin的类型，设置需要执行的功能
        if (save_data.curr_spin_type == SPIN_ENUM.BASE_SPIN) then
            need_add_jackpot = true
            need_push_jackpot = true
            need_check_fire_rope = true
            nedd_check_add_hold_spin_bouts = true
            need_check_add_spin_bonus = true
            need_line_prize = true
        elseif (save_data.curr_spin_type == SPIN_ENUM.HOLD_SPIN) then
            need_push_jackpot = true
            need_handle_hold_spin = true
        elseif (save_data.curr_spin_type == SPIN_ENUM.FREE_SPIN) then
            need_handle_free_spin = true
            need_move_wild = true
            need_line_prize = true
            need_check_free_spin_over = true
        end

        ----各功能执行
        --刷新jackpot奖池
        if need_add_jackpot then
            my_cal:AddJackpotExtraChip(save_data, total_amount, jackpot_config) --奖池点数增长
        end

        --推送jackpot奖池信息
        if need_push_jackpot then
            table.insert(
                pre_action_list,
                {
                    action_type = ActionType.ActionTypes.GameJackpotPool,
                    jackpot_param = my_cal:GetJakcpotParamToClient(save_data.jackpot_param_v2)
                }
            )
        end

        --绳子燃烧
        if need_check_fire_rope then
            --统计逻辑
            special_parameter.fire_rope.need_statistic = true
            special_parameter.fire_rope.rope_idx = save_data.fire_rope_param.curr_rope_idx

            --检查是否有足够点燃的雷管
            local detonator_fire_count = my_cal:GetItemCountInItemArr(origin_result_arr[1], ITEM_ENUM.Detonator_Fire)
            if detonator_fire_count > 0 then
                --变量读取
                local fire_rope_param = save_data.fire_rope_param
                local fire_rope_config = CommonCal.Calculate.get_config(player, game_name .. "RopeFireConfig")
                --烧绳子的Action
                local fire_rope_action = {
                    action_type = ActionType.ActionTypes.CollectItem
                }
                table.insert(pre_action_list, fire_rope_action)
                --统计逻辑
                special_parameter.fire_rope.is_try_fire = true

                --烧绳子逻辑处理
                --燃烧火苗的起点
                local origin_result_only_detonator_fire =
                    my_cal:FilterPointItemTypeArr(origin_result_arr[1], ITEM_ENUM.Detonator_Fire) --只有带火炸药的结果信息
                local detonator_fire_pos_arr = my_cal:ArrToList_2(origin_result_only_detonator_fire) --转换为数组
                fire_rope_action.detonator_fire_pos_arr = detonator_fire_pos_arr --记录进action
                --确定烧绳子的节数
                local fire_knat_count_weight_tab = fire_rope_config[#fire_rope_config].fire_knat_count_weight_tab --当前绳子燃烧段数的配置
                for _, fire_knat_config in ipairs(fire_rope_config) do
                    if fire_rope_param.fire_same_knat_times <= fire_knat_config.max_fire_same_knat_times then --寻找到范围内的
                        fire_knat_count_weight_tab = fire_knat_config.fire_knat_count_weight_tab
                        break
                    end
                end
                local fire_knat_count = my_cal:GetRandomItemByWeightTab(player, fire_knat_count_weight_tab).count --随机燃烧的段数
                fire_knat_count = math.min(fire_knat_count, fire_rope_param.left_knat_count) --防止绳子段数烧成负数

                --烧绳子成功的处理
                if fire_knat_count > 0 then
                    --更新烧绳子的下注值
                    fire_rope_param.bet_total_amount = fire_rope_param.bet_total_amount + total_amount
                    fire_rope_param.bet_times = fire_rope_param.bet_times + 1
                    --当前绳子减少
                    fire_rope_param.fire_same_knat_times = 0 --同一绳结的燃烧次数清零
                    fire_rope_param.left_knat_count = fire_rope_param.left_knat_count - fire_knat_count --减去烧的绳子节数
                    --写入剩余的绳结数（不管是否烧绳子成功）
                    fire_rope_action.curr_rope = {
                        rope_idx = fire_rope_param.curr_rope_idx,
                        left_knat_count = fire_rope_param.left_knat_count
                    }

                    --检查绳子是否烧完
                    if fire_rope_param.left_knat_count == 0 then
                        --触发bonus的信息设置
                        if fire_rope_param.curr_rope_idx <= 2 then
                            my_cal:SetPickBonusBeforeEnter(
                                save_data,
                                player,
                                game_name,
                                fire_rope_param.curr_rope_idx,
                                PRIZE_TYPE_ENUM
                            )
                        else
                            my_cal:SetTurnaroundBonusBeforeEnter(save_data, player, game_name, PRIZE_TYPE_ENUM)
                        end
                        --生成新的绳子并更新缓存
                        local rope_length_config =
                            CommonCal.Calculate.get_config(player, game_name .. "RopeLengthConfig")
                        local new_rope_idx = (fire_rope_param.curr_rope_idx) % (#rope_length_config) + 1 --新绳子的索引
                        fire_rope_param.curr_rope_idx = new_rope_idx
                        fire_rope_param.left_knat_count = rope_length_config[new_rope_idx].knat_count
                        fire_rope_param.bet_total_amount = 0
                        fire_rope_param.bet_times = 0
                        --新绳子信息记录写入action
                        fire_rope_action.new_rope = {
                            rope_idx = fire_rope_param.curr_rope_idx,
                            left_knat_count = fire_rope_param.left_knat_count
                        }

                        --统计逻辑
                        special_parameter.fire_rope.have_fire_whole_rope = true
                    end
                else
                    --同一绳结的燃烧次数累加
                    fire_rope_param.fire_same_knat_times = fire_rope_param.fire_same_knat_times + detonator_fire_count
                    --写入剩余的绳结数（不管是否烧绳子成功）
                    fire_rope_action.curr_rope = {
                        rope_idx = fire_rope_param.curr_rope_idx,
                        left_knat_count = fire_rope_param.left_knat_count
                    }
                end
            end
        end

        --检查增加hold_spin的次数
        if nedd_check_add_hold_spin_bouts then
            --检测是否触发
            local trigger_hold_spin = false --触发了hold_spin
            local origin_result = origin_result_arr[1] --BaseGame只会有1个Reel的结果
            local detonator_count = --雷管的总个数
                my_cal:GetItemCountInItemArr(origin_result, ITEM_ENUM.Detonator) +
                my_cal:GetItemCountInItemArr(origin_result, ITEM_ENUM.Detonator_Fire)
            if detonator_count >= 6 then
                trigger_hold_spin = true
            end
            --触发后的操作
            if trigger_hold_spin then
                --取出变量
                local final_result = final_result_arr[1]
                --设置参数
                my_cal:SetHoldSpinBeforeEnter(
                    save_data,
                    player,
                    game_name,
                    total_amount,
                    origin_result,
                    5,
                    nil,
                    enter_info,
                    ITEM_ENUM
                )
                my_cal:UpdateFinalResultByDetonatorInfoArr(
                    final_result,
                    save_data.hold_spin_param.big_detonator_info_arr
                ) --更新最终结果的图标
                my_cal:SetHoldSpinStatistic(save_data) --设置触发的统计信息

                --锁定信息发送
                table.insert(
                    pre_action_list,
                    {
                        action_type = ActionType.ActionTypes.LockItem,
                        spin_bouts = save_data.hold_spin_param.bouts,
                        lock_info_arr = save_data.hold_spin_param.lock_info_arr
                    }
                )
            end
        end

        -- 处理hold-spin数据
        if need_handle_hold_spin then
            --变量取出
            local hold_spin_param = save_data.hold_spin_param

            --剩余次数更新
            hold_spin_param.bouts = hold_spin_param.bouts - 1
            save_data.feature_spin_count = hold_spin_param.bouts

            --更新锁定信息并将锁定图标替换到转动结果中
            local origin_result = origin_result_arr[1] --BaseGame只会有1个Reel的结果
            local final_result = final_result_arr[1]
            local lock_info_arr = hold_spin_param.lock_info_arr --已经有的锁定信息
            for row, row_item in ipairs(origin_result) do
                for col, item in ipairs(row_item) do
                    if lock_info_arr[row][col] then --原本已经锁定的
                        origin_result[row][col] = ITEM_ENUM.Detonator --替换转动结果为炸药
                        final_result[row][col] = ITEM_ENUM.Detonator --替换转动结果为炸药
                    elseif origin_result[row][col] == ITEM_ENUM.Detonator then --转动结果为带火的炸药
                        lock_info_arr[row][col] = true --更新锁定信息数组
                    end
                end
            end

            --将初始信息中的Detonator_Fire改为合成后最小炸药的图标（客户端需求）
            local _1x1_detonator_info = my_cal.ranked_big_detonator_info_tab[11]
            local _1x1_detonator_item = _1x1_detonator_info.type * 100 + _1x1_detonator_info.row_len
            for row, row_item in ipairs(origin_result) do
                for col, item in ipairs(row_item) do
                    if item == ITEM_ENUM.Detonator then
                        origin_result[row][col] = _1x1_detonator_item
                    end
                end
            end

            --更新炸药合成信息
            local big_detonator_info_arr = my_cal:GenBigDetonatorInfoArr(save_data) --合成大炸药信息
            hold_spin_param.big_detonator_info_arr = big_detonator_info_arr --炸药信息记录
            my_cal:UpdateFinalResultByDetonatorInfoArr(final_result, big_detonator_info_arr) --更新最终结果的图标
            --检查hold_spin的是否结束（两种可能：1.次数用完 2.全部都是炸药）
            local all_is_detonator =
                my_cal:GetItemCountInItemArr(lock_info_arr, true) == #lock_info_arr * (#lock_info_arr[1]) --是否全是炸药
            if all_is_detonator then
                hold_spin_param.bouts = 0
                save_data.feature_spin_count = hold_spin_param.bouts
            end
            --设置由select-bonus触发的hold-spin的统计信息
            if use_last_point_reel then
                my_cal:SetHoldSpinStatistic(save_data)
            end

            --锁定信息发送
            table.insert(
                pre_action_list,
                {
                    action_type = ActionType.ActionTypes.LockItem,
                    spin_bouts = hold_spin_param.bouts,
                    lock_info_arr = hold_spin_param.lock_info_arr
                }
            )

            local hold_spin_over = hold_spin_param.bouts == 0 --本次完了之后是否结束
            --结算
            if hold_spin_over then
                --计算hold_spin的赢钱
                --变量取出
                local hold_spin_win = 0 --总共赢钱
                local prize_info_arr = {} --所有的奖励信息
                local prize_config = CommonCal.Calculate.get_config(player, game_name .. "HoldSpinPrizeConfig") --奖励配置
                --奖励生成
                local settle_action = {
                    action_type = ActionType.ActionTypes.HoldSpinSettle,
                    explosion_info_arr = {}, --爆炸信息数组
                    win_chip = 0, --总共赢钱
                    enter_info = hold_spin_param.enter_info --进入时的信息
                }
                --遍历大的炸药信息，进行奖励生成
                --将结算中的炸药信息按照以下规则排序：1.炸药面积从小到大 2.列数从小到大
                table.sort(
                    big_detonator_info_arr,
                    function(l, r)
                        --初始化返回值
                        local is_ok = false

                        --处理是否排好序了
                        if l.area < r.area then
                            is_ok = true
                        elseif l.area == r.area then
                            if l.start_pos[2] < r.start_pos[2] then
                                is_ok = true
                            elseif l.start_pos[2] == r.start_pos[2] then
                                if l.start_pos[1] < r.start_pos[1] then
                                    is_ok = true
                                end
                            end
                        end

                        --返回
                        return is_ok
                    end
                )
                --遍历每个炸药生成奖励
                for big_detonator_idx, big_detonator_info in pairs(big_detonator_info_arr) do
                    --随机得到一个奖励
                    local area = big_detonator_info.area --炸药的面积
                    local prize_pool_config = prize_config[area].prize_pool --配置的奖池
                    local _, item_result_idx = my_cal:GetRandomItemByWeightTab(player, prize_pool_config) --随机到的奖励信息
                    --生成客户端奖励的reel表
                    local prize_reel_info_client = {}
                    for try_item_result_idx, try_prize_info_config in ipairs(prize_pool_config) do
                        --item的数值
                        local prize_type = try_prize_info_config.prize_type
                        local item = 2 * 10000 + big_detonator_info.type * 100 + prize_type
                        --奖励的数值
                        local prize_val = 0
                        if prize_type >= PRIZE_TYPE_ENUM.JAKCPOT_MEGA and prize_type <= PRIZE_TYPE_ENUM.JACKPOT_MINI then
                            prize_val = my_cal:GetJackpotPoolChipVal(save_data, prize_type, total_amount)
                            my_cal:ResetJackpotExtraChip(save_data, prize_type) --清零奖池的额外筹码
                        elseif prize_type == PRIZE_TYPE_ENUM.CHIP then
                            prize_val = try_prize_info_config.prize_val * total_amount
                        end
                        --加入发送给客户端的reel表中
                        prize_reel_info_client[try_item_result_idx] = {
                            item = item,
                            prize_val = prize_val
                        }
                    end
                    --确定最终奖励结果信息
                    local prize_info_result = {
                        prize_type = prize_pool_config[item_result_idx].prize_type,
                        prize_val = prize_reel_info_client[item_result_idx].prize_val
                    }

                    --总奖励金额累计
                    hold_spin_win = hold_spin_win + prize_info_result.prize_val
                    --将奖励信息加入aciotn中
                    settle_action.explosion_info_arr[big_detonator_idx] = {
                        start_pos = big_detonator_info.start_pos, --炸药的开始位置
                        reel_info = area >= 4 and prize_reel_info_client or nil, --转轴信息(大于等于4格时，才发送转轴)
                        item_result_idx = item_result_idx, --最终转到的结果
                        prize_info = prize_info_result --奖励信息
                    }
                end

                --更新jackpot基础金额
                my_cal:SetJackpotAmount(save_data, false, 0)
                --算入总奖励中
                total_win_chip = total_win_chip + hold_spin_win
                --添加Action
                settle_action.win_chip = hold_spin_win --赋值赢得总金额
                table.insert(pre_action_list, settle_action) --插入action

                --统计计算
                --触发信息
                local hold_spin_statisitc = save_data.hold_spin_statisitc
                ----大炸药结果统计
                --大炸药类型个数的统计map初始化
                local detonator_type_arr = {} --炸药类型构成的数组
                local detonator_type_count_map = {}
                for type, _ in ipairs(my_cal.ranked_big_detonator_info_tab) do --初始化
                    detonator_type_count_map[type] = 0
                end
                --遍历大炸药结果，进行个数统计
                for big_detonator_idx, big_detonator_info in pairs(big_detonator_info_arr) do
                    local type = big_detonator_info.type
                    table.insert(detonator_type_arr, type) --全部炸药类型数组插入元素
                    detonator_type_count_map[type] = detonator_type_count_map[type] + 1 --类型数据量统计map更新
                end

                --拼接本次大炸药结果的key
                local detonator_result = ""
                for type, num in ipairs(detonator_type_count_map) do
                    if num > 0 then
                        local big_detonator_info = my_cal.ranked_big_detonator_info_tab[type]
                        detonator_result =
                            detonator_result ..
                            string.format("%dx%d:%d ", big_detonator_info.row_len, big_detonator_info.col_len, num)
                    end
                end
                ----jackpot次数统计
                local jackpot_arr = {}
                for big_detonator_idx, explosion_info in ipairs(settle_action.explosion_info_arr) do
                    local prize_type = explosion_info.prize_info.prize_type
                    table.insert(jackpot_arr, prize_type)
                end
                --整个hold-spin的统计结果赋值
                special_parameter.hold_spin = {
                    is_over = true, --是否结束
                    total_bouts = hold_spin_statisitc.total_bouts, --spin的总次数
                    detonator_count_trigger = hold_spin_statisitc.detonator_count_trigger, --触发时小炸药的个数
                    detonator_type_arr = detonator_type_arr, --炸药类型的数组
                    detonator_result = detonator_result, --炸药的结果形成的字符串
                    jackpot_arr = jackpot_arr, --jackpot数组
                    win_chip = hold_spin_win --赢钱
                }

                --触发
                FeverQuestCal.OnDynamiteRespinEnd(extern_param.session, hold_spin_win)
            end
        end

        -- 处理free-spin数据
        if need_handle_free_spin then
            save_data.free_spin_param.bouts = save_data.free_spin_param.bouts - 1
        end

        --检查增加spin-bonus的次数
        if need_check_add_spin_bonus then
            --检测是否触发
            local origin_result = origin_result_arr[1] --BaseGame只会有1个Reel的结果
            local _bonus_item_count = my_cal:GetItemCountInItemArr(origin_result, ITEM_ENUM.Bonus)
            --触发了时的数据处理
            if (_bonus_item_count >= 3) then
                my_cal:SetSpinBonusBeforEnter(save_data, _bonus_item_count, total_amount, enter_info)
            end
        end

        --move_wild特性
        if need_move_wild then
            --取出变量
            local origin_result = origin_result_arr[1]
            local final_result = final_result_arr[1]
            local settle_result = settle_result_arr[1]
            local origin_result_force_move = table.DeepCopy(origin_result)
            local payrate_config = CommonCal.Calculate.get_config(player, game_room_config.game_name .. "PayrateConfig")
            local left_or_right = game_room_config.direction_type

            --先强制移动wild
            local colNum = #(origin_result_force_move[1])
            for col = 1, colNum, 1 do
                --判断该列
                local have_wild = false
                for row, row_item in ipairs(origin_result_force_move) do
                    local item = row_item[col]
                    if ITEM_ENUM.Wild_Col_Map[item] then
                        have_wild = true
                        break
                    end
                end
                --进行强制移动
                if have_wild then
                    for row, row_item in ipairs(origin_result_force_move) do
                        row_item[col] = ITEM_ENUM["Wild_Col_" .. row]
                    end
                end
            end

            --取出可以移动的wild的位置数组
            local move_wild_pos_arr =
                SlotsGameCal.Calculate.GetWildsOnLine(
                origin_result_force_move,
                game_room_config,
                payrate_config,
                left_or_right,
                ITEM_ENUM
            )
            --过滤move_wild_pos_arr中单独wild的位置（因为单独的wild不允许Move）
            for idx, move_wild_pos in pairs(move_wild_pos_arr) do
                local wild_item = origin_result_force_move[move_wild_pos.row][move_wild_pos.col]
                if not ITEM_ENUM.Wild_Col_Map[wild_item] then
                    move_wild_pos_arr[idx] = nil
                end
            end

            --触发了movewild，进行相应的处理
            if next(move_wild_pos_arr) then
                --生成需要move_wild的列
                local move_wild_col_map = {}
                for _, move_wild_pos in pairs(move_wild_pos_arr) do
                    local wild_col = move_wild_pos.col --整列为wild的列
                    move_wild_col_map[wild_col] = true --记录
                end

                --更新final_result，将整列设置为wild
                for wild_col, _ in pairs(move_wild_col_map) do
                    for row, row_item in ipairs(final_result) do --每一行的该列替换为wild
                        local move_to_item = ITEM_ENUM["Wild_Col_" .. row]
                        final_result[row][wild_col] = move_to_item
                        settle_result[row][wild_col] = move_to_item
                    end
                end
                --添加move_wild的action
                local wild_col_arr = {} --需要move_wild的列的数组
                for wild_col, _ in pairs(move_wild_col_map) do
                    table.insert(wild_col_arr, wild_col)
                end
                table.insert(
                    pre_action_list,
                    {
                        action_type = ActionType.ActionTypes.MoveWildTrigger,
                        feature = wild_col_arr
                    }
                )
            end
        end

        --连线奖励
        local slots_win_chip = 0 --连线赢得钱
        local formation_list = {} --结果展示表
        local all_prize_list = {} --所有的连线奖励表
        local extra_payrate_ratio = 1 --额外赔付系数
        --根据转轴类型设置spin参数
        if save_data.curr_spin_type == SPIN_ENUM.BASE_SPIN then
            extra_payrate_ratio = CommonCal.Calculate.get_config(player, game_name .. "OthersConfig")[1].Base_Bet_Ratio --base_spin需要奖励赔付倍率
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
            spin_reel_info_arr,
            amount,
            extra_payrate_ratio,
            need_line_prize,
            ITEM_ENUM,
            SPIN_ENUM
        )
        --本次赢得所有钱（连线赢得钱+特殊点赢钱）
        total_win_chip = total_win_chip + slots_win_chip

        --单线赔率计算
        if save_data.curr_spin_type == SPIN_ENUM.FREE_SPIN then
            local line_payrate_map = special_parameter.free_spin.line_payrate_map
            for result_idx, prize_item_arr in pairs(all_prize_list) do
                for _, prize_item in pairs(prize_item_arr) do --遍历所有的连线奖励
                    --数据缓存
                    local line_index = prize_item.line_index
                    local payrate = prize_item.payrate
                    --数据检查
                    if not line_payrate_map[line_index] then
                        line_payrate_map[line_index] = 0
                    end
                    line_payrate_map[line_index] = line_payrate_map[line_index] + payrate --累加
                end
            end
        end

        --检测free_spin结束
        if need_check_free_spin_over then
        -- if (save_data.free_spin_param.bouts == 0) then
        --     --计算free_spin的总赢钱
        --     local free_total_win =
        --         player_game_info.free_total_win + CommonCal.Calculate.GetFreeWin(is_free_spin, total_win_chip)

        --     --插入action
        --     table.insert(
        --         pre_action_list,
        --         {
        --             action_type = ActionType.ActionTypes.TotalFreeSpinWin,
        --             free_total_win = free_total_win,
        --             total_free_spin_times = player_game_info.total_spin_bouts
        --         }
        --     )
        -- end
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
            PRIZE_TYPE_ENUM,
            self.parameters
        )

        --返回结果中插入aciton
        local pre_action_list_json = json.encode(pre_action_list)
        for _, formation in pairs(formation_list) do
            for _, slots_spin in pairs(formation.slots_spin_list) do
                slots_spin.pre_action_list = pre_action_list_json
            end
        end

        --返回
        local result = {}
        result.final_result = final_result_arr --结果数组
        result.total_win_chip = total_win_chip --总奖金
        result.all_prize_list = all_prize_list --所有连线列表
        result.free_spin_bouts = add_free_spin_bouts --freespin的次数
        result.formation_list = formation_list --阵型列表
        result.reel_file_name = reel_file_name --reel表名
        result.slots_win_chip = slots_win_chip --总奖励
        result.special_parameter = special_parameter --其他参数，主要给模拟器传参

        --保存缓存数据
        my_cal:RecordSaveData(player_game_info, save_data)

        return result
    end
end

do --PickBonus
    function SlotsGoldMineSpin:PickBonusEnter()
        --取出变量
        local player = self.parameters.player
        local game_room_config = self.parameters.game_room_config
        local parameter = self.parameters.parameter
        local player_game_info = self.parameters.player_game_info
        local game_type = self.parameters.game_type
        local game_name = game_room_config.game_name --游戏名字
        local save_data = my_cal:GetSaveData(player, player_game_info, game_name, SPIN_ENUM) --检查缓存数据的完整性

        --初始化返回值
        local content = {}

        --逻辑处理
        local pick_bonus_param = save_data.pick_bonus_param
        if pick_bonus_param.bouts > 0 then
            --数据处理
            --取出变量
            local pre_action_list = {}
            --jackpot信息
            table.insert(
                pre_action_list,
                {
                    action_type = ActionType.ActionTypes.GameJackpotPool,
                    jackpot_param = my_cal:GetJakcpotParamToClient(save_data.jackpot_param_v2)
                }
            )

            --填入数据
            content = {
                rope_idx = pick_bonus_param.rope_idx, --由第几节绳子燃烧触发
                pick_game_info = pick_bonus_param.pick_game_info, --捡取游戏的信息
                pre_action_list = pre_action_list --action列表
            }
        end

        --保存缓存数据
        my_cal:RecordSaveData(player_game_info, save_data)

        --返回
        return content
    end

    function SlotsGoldMineSpin:PickBonusPick()
        --取出变量
        local player_game_status = self.parameters.player_game_status
        local player = self.parameters.player
        local game_room_config = self.parameters.game_room_config
        local parameter = self.parameters.parameter
        local player_game_info = self.parameters.player_game_info
        local game_type = self.parameters.game_type
        local game_name = game_room_config.game_name --游戏名字
        local save_data = my_cal:GetSaveData(player, player_game_info, game_name, SPIN_ENUM) --检查缓存数据的完整性

        --初始化返回值
        local content = {}

        --逻辑处理
        local pick_bonus_param = save_data.pick_bonus_param
        local pick_game_info = pick_bonus_param.pick_game_info
        if pick_bonus_param.bouts > 0 then
            --变量声明
            local pre_action_list = {}

            --判断捡取是否合法
            local pick_pos = json.decode(parameter).pick_pos
            local pick_success = true
            for _, pick_pos_his in ipairs(pick_game_info.pick_history) do
                if pick_pos_his == pick_pos then
                    pick_success = false
                    break
                end
            end
            --记录捡取的位置
            if pick_success then
                --记录行走的位置
                table.insert(pick_game_info.pick_history, pick_pos)
                pick_game_info.curr_pick_count = pick_game_info.curr_pick_count + 1
                --重置中的jackpot奖励的额外筹码
                local prize_info = pick_game_info.prize_pool[pick_game_info.curr_pick_count]
                local prize_type = prize_info.prize_type
                if prize_type >= PRIZE_TYPE_ENUM.JAKCPOT_MEGA and prize_type <= PRIZE_TYPE_ENUM.JACKPOT_MINI then
                    my_cal:ResetJackpotExtraChip(save_data, prize_type) --清零奖池的额外筹码
                end
            end
            --判断捡取是否结束
            local is_over = pick_game_info.curr_pick_count == pick_game_info.max_pick_count
            local win_chip = 0
            if pick_success and is_over then --本次捡取导致游戏结束
                --赢钱数据赋值
                win_chip = pick_game_info.win_chip

                --缓存数据处理
                --bonus数据
                pick_bonus_param.bouts = 0 --pick游戏的次数归0
                player_game_info.bonus_game_type = 0 --外围数据赋值
                --jackpot数据
                my_cal:SetJackpotAmount(save_data, false, 0) --更新jackpot为下注的状态
                table.insert( --新加action
                    pre_action_list,
                    {
                        action_type = ActionType.ActionTypes.GameJackpotPool,
                        jackpot_param = my_cal:GetJakcpotParamToClient(save_data.jackpot_param_v2)
                    }
                )

                --流程控制
                --BonusGame的流程进度手动+1
                GameStatusCal.Calculate.UpdateGameStatus(player_game_status, 1, win_chip)
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
                    PRIZE_TYPE_ENUM,
                    self.parameters
                )
            end

            --填入数据
            content = {
                ----客户端的请求信息
                request = {
                    pick_pos = pick_pos --客户端捡取的UI对应顺序
                },
                ----服务器的回复信息
                pick_success = pick_success, --捡取是否成功
                curr_pick_count = pick_game_info.curr_pick_count, --当前pick到了第几个
                is_over = is_over, --游戏是否结束了
                win_chip = win_chip, --游戏结束时，赢取的总金额（仅当pick_success and is_over == true时才有效）
                pre_action_list = pre_action_list --会触发的Action列表(用于游戏的流程控制)
            }
        end

        --保存缓存数据
        my_cal:RecordSaveData(player_game_info, save_data)

        --返回
        return content
    end
end

do --TurnaroundBonus
    function SlotsGoldMineSpin:TurnaroundBonusEnter()
        --取出变量
        local player = self.parameters.player
        local game_room_config = self.parameters.game_room_config
        local parameter = self.parameters.parameter
        local player_game_info = self.parameters.player_game_info
        local game_type = self.parameters.game_type
        local game_name = game_room_config.game_name --游戏名字
        local save_data = my_cal:GetSaveData(player, player_game_info, game_name, SPIN_ENUM) --检查缓存数据的完整性

        --初始化返回值
        local content = {}

        --逻辑处理
        local turnaround_bonus_param = save_data.turnaround_bonus_param
        local turnaround_game_info = turnaround_bonus_param.turnaround_game_info
        if turnaround_bonus_param.bouts > 0 then
            --数据处理
            --取出变量
            local pre_action_list = {}
            --jackpot信息发送
            table.insert(
                pre_action_list,
                {
                    action_type = ActionType.ActionTypes.GameJackpotPool,
                    jackpot_param = my_cal:GetJakcpotParamToClient(save_data.jackpot_param_v2)
                }
            )

            --填入数据
            content = {
                turnaround_game_info = {
                    max_rotate_count = turnaround_game_info.max_rotate_count, --最多的转动次数
                    curr_rotate_count = turnaround_game_info.curr_rotate_count, --当前的转动次数
                    turnaround_info = turnaround_game_info.turnaround_info, --转盘的信息
                    roate_result_arr = turnaround_game_info.roate_result_arr, --每次转动的转盘结果
                    win_chip = turnaround_game_info.win_chip --游戏结束时的总收益
                },
                pre_action_list = pre_action_list --Action列表
            }
        end

        --保存缓存数据
        my_cal:RecordSaveData(player_game_info, save_data)

        --返回
        return content
    end

    function SlotsGoldMineSpin:TurnaroundBonusRotate()
        --取出变量
        local player_game_status = self.parameters.player_game_status
        local player = self.parameters.player
        local game_room_config = self.parameters.game_room_config
        local parameter = self.parameters.parameter
        local player_game_info = self.parameters.player_game_info
        local game_type = self.parameters.game_type
        local game_name = game_room_config.game_name --游戏名字
        local save_data = my_cal:GetSaveData(player, player_game_info, game_name, SPIN_ENUM) --检查缓存数据的完整性

        --初始化返回值
        local content = {}

        --逻辑处理
        local turnaround_bonus_param = save_data.turnaround_bonus_param
        local turnaround_game_info = turnaround_bonus_param.turnaround_game_info
        if turnaround_bonus_param.bouts > 0 then
            --变量声明
            local rotate_success = false
            local prize_type = nil
            local turnaround_change_info = nil
            local is_over = true
            local win_chip = 0
            local pre_action_list = {}

            --判断捡取是否合法
            rotate_success = turnaround_game_info.curr_rotate_count < turnaround_game_info.max_rotate_count
            --转动产生的结果
            if rotate_success then
                turnaround_game_info.curr_rotate_count = turnaround_game_info.curr_rotate_count + 1
                --检查转盘是否变化
                local turnaround_idx = turnaround_game_info.roate_result_arr[turnaround_game_info.curr_rotate_count] --转盘结果的索引
                prize_type = turnaround_game_info.turnaround_info[turnaround_idx].prize_type --得到的奖励类型
                if (prize_type == PRIZE_TYPE_ENUM.JACKPOT_DOUBLE) then --双倍的jackpot时，转盘要改变同时jackpot的奖励值也要改变
                    --缓存中的转盘信息改变
                    turnaround_game_info.turnaround_info[turnaround_idx].prize_type = PRIZE_TYPE_ENUM.JACKPOT_MINI
                    --填入改变信息
                    turnaround_change_info = {
                        pos = {turnaround_idx},
                        data = turnaround_game_info.turnaround_info[turnaround_idx]
                    }
                    --jackpot信息改变
                    --更新jackpot
                    my_cal:SetJackpotDouble(save_data, true)
                    --jackpot信息发送
                    table.insert(
                        pre_action_list,
                        {
                            action_type = ActionType.ActionTypes.GameJackpotPool,
                            jackpot_param = my_cal:GetJakcpotParamToClient(save_data.jackpot_param_v2)
                        }
                    )
                end
                --判断捡取是否结束
                is_over = turnaround_game_info.curr_rotate_count == turnaround_game_info.max_rotate_count
                if is_over then --本次捡取导致游戏结束
                    --赢钱数据赋值
                    win_chip = turnaround_game_info.win_chip

                    --缓存数据处理
                    turnaround_bonus_param.bouts = 0 --pick游戏的次数归0
                    player_game_info.bonus_game_type = 0 --外围数据赋值
                    --jackpot数据
                    my_cal:SetJackpotAmount(save_data, false, 0) --更新jackpot基础金额
                    my_cal:SetJackpotDouble(save_data, false) --还原double值
                    my_cal:ResetJackpotExtraChip(save_data, prize_type) --清零额外筹码
                    table.insert( --新加action
                        pre_action_list,
                        {
                            action_type = ActionType.ActionTypes.GameJackpotPool,
                            jackpot_param = my_cal:GetJakcpotParamToClient(save_data.jackpot_param_v2)
                        }
                    )

                    --流程控制
                    --BonusGame的流程进度手动+1
                    GameStatusCal.Calculate.UpdateGameStatus(player_game_status, 1, win_chip)
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
                        PRIZE_TYPE_ENUM,
                        self.parameters
                    )
                end
            end

            --填入数据
            content = {
                rotate_success = rotate_success,
                prize_type = prize_type,
                curr_rotate_count = turnaround_game_info.curr_rotate_count,
                turnaround_change_info = turnaround_change_info,
                is_over = is_over,
                win_chip = win_chip, --游戏结束时，赢取的总金额（仅当rotate_success and is_over == true时才有效）
                pre_action_list = pre_action_list --会触发的Action列表(用于游戏的流程控制)
            }
        end

        --保存缓存数据
        my_cal:RecordSaveData(player_game_info, save_data)

        --返回
        return content
    end
end

do --SpinBonus
    function SlotsGoldMineSpin:SpinBonusEnter()
        --取出变量
        local player = self.parameters.player
        local game_room_config = self.parameters.game_room_config
        local parameter = self.parameters.parameter
        local player_game_info = self.parameters.player_game_info
        local game_type = self.parameters.game_type
        local game_name = game_room_config.game_name --游戏名字
        local save_data = my_cal:GetSaveData(player, player_game_info, game_name, SPIN_ENUM) --检查缓存数据的完整性

        --初始化返回值
        local content = {}

        --逻辑处理
        local spin_bonus_param = save_data.spin_bonus_param
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

    function SlotsGoldMineSpin:SpinBonusSelect()
        --取出变量
        local player_game_status = self.parameters.player_game_status
        local player = self.parameters.player
        local game_room_config = self.parameters.game_room_config
        local parameter = self.parameters.parameter
        local player_game_info = self.parameters.player_game_info
        local game_type = self.parameters.game_type
        local game_name = game_room_config.game_name --游戏名字
        local save_data = my_cal:GetSaveData(player, player_game_info, game_name, SPIN_ENUM) --检查缓存数据的完整性

        --初始化返回值
        local content = {}

        --逻辑处理
        local ITEM_ENUM = _G[game_name .. "TypeArray"].Types --图标的枚举
        local spin_bonus_param = save_data.spin_bonus_param
        if spin_bonus_param.bouts > 0 then
            --变量声明
            local pre_action_list = {} --pre_action_list声明
            local request_success = true --设置标志量
            local free_spin_bouts = 0 --增加的free-spin次数
            local origin_result = nil --hold_spin时，进入时的炸药结果
            local final_result = nil --hold_spin时，进入时的炸药的合成后的结果

            --读取请求参数
            local select_request = json.decode(parameter)

            --请求处理
            --取出变量
            local select_param = spin_bonus_param.select_param
            --设置参数
            if select_request.is_free_spin then --free_spin
                free_spin_bouts = select_param.free_spin_bouts --选择的free-spin次数
                my_cal:SetFreeSpinBeforeEnter(save_data, select_param.total_amount, select_param.free_spin_bouts) --设置free_spin的参数
            else --hold_spin
                --生成进入时的转轴结果
                local formation_name = "Formation1"
                local formation = _G[game_name .. "FormationArray"][formation_name]
                origin_result = {}
                for col = 1, #formation, 1 do
                    for row = 1, formation[col], 1 do
                        --行检查
                        if origin_result[row] == nil then
                            origin_result[row] = {}
                        end
                        --填入数据
                        origin_result[row][col] = ITEM_ENUM.Empty
                    end
                end
                final_result = table.DeepCopy(origin_result)
                --在随机位置，赠送6个炸药图标
                local detonator_pos_info_arr = {
                    {pos = {1, 2}, weight = 1},
                    {pos = {1, 3}, weight = 1},
                    {pos = {1, 4}, weight = 1},
                    {pos = {2, 2}, weight = 1},
                    {pos = {2, 3}, weight = 1},
                    {pos = {2, 4}, weight = 1},
                    {pos = {3, 2}, weight = 1},
                    {pos = {3, 3}, weight = 1},
                    {pos = {3, 4}, weight = 1}
                }
                for send_count = 1, 6, 1 do
                    local detonator_pos_info, result_idx =
                        my_cal:GetRandomItemByWeightTab(player, detonator_pos_info_arr)
                    local pos = detonator_pos_info.pos
                    origin_result[pos[1]][pos[2]] = ITEM_ENUM.Detonator --替换图标
                    table.remove(detonator_pos_info_arr, result_idx) --移除已经随机到的位置
                end
                --设置进入hold_spin的参数
                --spin-bonus进入的hold-spin送一次指定转轴的spin
                local reel_info_arr_list = {}
                table.insert(
                    reel_info_arr_list,
                    {
                        {
                            id = 1,
                            formation_name = "Formation1",
                            line_name = "Lines1",
                            feature_file_name = "GoldMineHoldSpinStartReelConfig"
                        }
                    }
                )
                my_cal:SetHoldSpinBeforeEnter(
                    save_data,
                    player,
                    game_name,
                    select_param.total_amount,
                    origin_result,
                    select_param.hold_spin_bouts + 1,
                    reel_info_arr_list,
                    spin_bonus_param.enter_info,
                    ITEM_ENUM
                )
                my_cal:UpdateFinalResultByDetonatorInfoArr(
                    final_result,
                    save_data.hold_spin_param.big_detonator_info_arr
                ) --更新最终结果的图标
                --锁定信息发送
                table.insert(
                    pre_action_list,
                    {
                        action_type = ActionType.ActionTypes.LockItem,
                        spin_bouts = save_data.hold_spin_param.bouts,
                        lock_info_arr = save_data.hold_spin_param.lock_info_arr
                    }
                )
            end
            --成功后，将spin-bonus次数清零
            if request_success then
                spin_bonus_param.bouts = 0
                player_game_info.bonus_game_type = 0
                GameStatusCal.Calculate.UpdateGameStatus(player_game_status, 1, 0) --BonusGame的流程进度手动+1
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
                PRIZE_TYPE_ENUM,
                self.parameters
            )

            --填入数据
            content = {
                select_request = select_request, --请求
                request_success = request_success, --请求是否成功
                free_spin_bouts = free_spin_bouts, --增加的free-spin次数
                origin_result = origin_result, --hold_spin时，进入时的炸药结果
                final_result = final_result, --最终结果
                pre_action_list = pre_action_list --会触发的Action列表(用于游戏的流程控制)
            }
        end

        --保存缓存数据
        my_cal:RecordSaveData(player_game_info, save_data)

        --返回
        return content
    end
end
