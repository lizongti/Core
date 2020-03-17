require "Common/SlotsGameCal" --旧的接口

GoldMineCalClass = {}
GoldMineCalClass.__index = GoldMineCalClass

--根据优先级排序好的大炸药信息表
GoldMineCalClass.ranked_big_detonator_info_tab = {
    [1] = {type = 1, row_len = 3, col_len = 5, area = 15},
    [2] = {type = 2, row_len = 3, col_len = 4, area = 12},
    [3] = {type = 3, row_len = 2, col_len = 5, area = 10},
    [4] = {type = 4, row_len = 3, col_len = 3, area = 9},
    [5] = {type = 5, row_len = 2, col_len = 4, area = 8},
    [6] = {type = 6, row_len = 3, col_len = 2, area = 6},
    [7] = {type = 7, row_len = 2, col_len = 3, area = 6},
    [8] = {type = 8, row_len = 2, col_len = 2, area = 4},
    [9] = {type = 9, row_len = 3, col_len = 1, area = 3},
    [10] = {type = 10, row_len = 2, col_len = 1, area = 2},
    [11] = {type = 11, row_len = 1, col_len = 1, area = 1}
}

--检查保存数据的完整性
function GoldMineCalClass:GetSaveData(_player, _player_game_info, _game_name, _SPIN_ENUM, _PRIZE_TYPE_ENUM)
    --初始化返回值
    local save_data = {}

    ----读取缓缓
    save_data = _player_game_info.save_data

    ----完整性检测
    --当前spin类型
    if not save_data.curr_spin_type then
        save_data.curr_spin_type = _SPIN_ENUM.BASE_SPIN
    end

    --转轴信息
    if not save_data.reel_info_arr then
        --转轴的信息数组
        save_data.reel_info_arr = {
            {
                id = 1,
                formation_name = "Formation1",
                line_name = "Lines1",
                feature_file_name = nil
            }
        }
    end

    --hold_spin信息
    if not save_data.hold_spin_param then
        save_data.hold_spin_param = {
            bouts = 0, --剩余次数
            total_amount = 0, --指定的金额
            lock_info_arr = {}, --锁定图标的位置信息数组
            big_detonator_info_arr = {}, --合成的大的炸药信息数组
            -- last_final_result = nil --最后一次合成后的结果显示
            point_reel_info_arr_list = nil, --指定reel_info_arr的列表，当有元素时依次取出进行spin
            enter_info = {} --进入时的信息
        }
    end

    --hold_spin统计信息
    if not save_data.hold_spin_statisitc then
        save_data.hold_spin_statisitc = {
            total_bouts = 0, --总次数
            detonator_count_trigger = 0 --触发时小炸药的个数
        }
    end

    --free_spin信息
    if not save_data.free_spin_param then
        save_data.free_spin_param = {
            bouts = 0, --剩余次数
            total_amount = 0 --指定的金额
        }
    end

    --jackpotV2信息
    if not save_data.jackpot_param_v2 then
        --取出变量
        local jackpot_config = CommonCal.Calculate.get_config(_player, _game_name .. "JackpotConfig")

        --初始化
        save_data.jackpot_param_v2 = {
            prize_pool = {} --奖池信息
        }
        --设置参数
        self:InitJackpotParam(save_data, jackpot_config)
    end

    --绳子燃烧信息
    if not save_data.fire_rope_param then
        --获取烧绳子的配置
        local rope_length_config = CommonCal.Calculate.get_config(player, _game_name .. "RopeLengthConfig")

        --填写默认缓存
        save_data.fire_rope_param = {
            curr_rope_idx = 1,
            fire_same_knat_times = 0, --燃烧同一绳结的次数（绳结被烧成功时，清0）
            left_knat_count = rope_length_config[1].knat_count, --剩余的绳节数
            bet_total_amount = 0, --烧绳子的下注总金额
            bet_times = 0 --下注总次数
        }
    end

    --pick_bonus信息
    if not save_data.pick_bonus_param then
        save_data.pick_bonus_param = {
            bouts = 0, --触发的次数
            rope_idx = 0, --由第几节绳子燃烧触发
            --捡取游戏的信息
            pick_game_info = {
                max_pick_count = 0, --最多捡取的个数
                curr_pick_count = 0, --当前pick到了第几个
                pick_history = {}, --捡取的历史信息
                prize_pool = {}, --奖池信息
                total_amount = 0, --奖励的基准值
                win_chip = 0 --游戏结束时的总收益
            }
        }
    end

    --turnaround_bonus信息
    if not save_data.turnaround_bonus_param then
        save_data.turnaround_bonus_param = {
            bouts = 0, --触发的次数
            --转盘游戏信息
            turnaround_game_info = {
                max_rotate_count = 0, --最多的转动次数
                curr_rotate_count = 0, --当前的转动次数
                turnaround_info = {}, --转盘的信息
                roate_result_arr = {}, --每次转动的转盘结果（对应转盘的索引）
                total_amount = 0, --奖励的基准值
                win_chip = 0 --游戏结束时的总收益
            }
        }
    end

    --spin_bonus信息
    if not save_data.spin_bonus_param then
        save_data.spin_bonus_param = {
            bouts = 0, --触发的次数
            enter_info = {}, --进入时的信息
            --可选择的spin的次数
            select_param = {
                total_amount = 0,
                free_spin_bouts = 10,
                hold_spin_bouts = 5
            }
        }
    end

    ----返回
    return save_data
end

--保存sava_data
function GoldMineCalClass:RecordSaveData(_player_game_info, _save_data)
    --不连续table进行转化处理
    --金币金额信息
    -- _save_data.coin_info_arr = self:ArrToList_2(_save_data.coin_info_arr)
    --序列化后保存
end

--数组转化为列表
function GoldMineCalClass:ArrToList_2(_arr)
    --初始化返回值
    local list = {}

    --填入数据
    for row, item_row in pairs(_arr) do
        for col, item in pairs(item_row) do
            table.insert(
                list,
                {
                    pos = {row, col},
                    data = item
                }
            )
        end
    end

    --返回
    return list
end

--列表转化为数组
function GoldMineCalClass:ListToArr_2(_list)
    --初始化返回值
    local tab = {}

    --填入数据
    for _, item in ipairs(_list) do
        --位置取出
        local pos = item.pos

        --行检查
        if not tab[pos[1]] then
            tab[pos[1]] = {}
        end
        --写入数据
        tab[pos[1]][pos[2]] = item.data
    end

    --返回
    return tab
end

--随机交换table中的内容
function GoldMineCalClass:RandSwapItemInTab(_player, _tab, _swap_count)
    local tab_length = #_tab
    for swap_idx = 1, _swap_count, 1 do --开始交换
        local pos_a = math.random_ext(_player, tab_length)
        local pos_b = math.random_ext(_player, tab_length)
        if pos_a ~= pos_b then
            _tab[pos_b], _tab[pos_a] = _tab[pos_a], _tab[pos_b]
        end
    end
end

--物品数组里是获取的指定物品的数量
function GoldMineCalClass:GetItemCountInItemArr(_item_arr, _item_type)
    --初始化返回值
    local item_num = 0

    --统计个数
    for row, item_row in pairs(_item_arr) do
        for col, item in pairs(item_row) do
            if item == _item_type then
                item_num = item_num + 1
            end
        end
    end

    --返回
    return item_num
end

--根据带有权重的信息表获取一个随机
function GoldMineCalClass:GetRandomItemByWeightTab(_player, _item_with_weight_tab)
    --初始化返回值
    local item = nil
    local result_idx = -1

    ----随机处理
    --生成随机表
    local weight_tab = {}
    for idx, item_with_weight in ipairs(_item_with_weight_tab) do
        weight_tab[idx] = item_with_weight.weight
    end
    --生成成随机结果
    result_idx = math.rand_weight(_player, weight_tab)
    item = _item_with_weight_tab[result_idx]

    --返回
    return item, result_idx
end

--从原始的结果数组中筛选出只有制定类型的数组
function GoldMineCalClass:FilterPointItemTypeArr(_orign_result, _point_item_type)
    --初始化返回值
    local point_type_arr = {}

    --填写数据
    for row, item_row in ipairs(_orign_result) do
        for col, item in ipairs(item_row) do
            if item == _point_item_type then
                --数据行检查
                if not point_type_arr[row] then
                    point_type_arr[row] = {}
                end
                --填入数据
                point_type_arr[row][col] = _point_item_type
            end
        end
    end

    --返回
    return point_type_arr
end

--生成连线奖励
function GoldMineCalClass:GenLinePrize(
    _player,
    _game_room_config,
    _game_name,
    _curr_spin_type,
    _origin_result_arr,
    _final_result_arr,
    _settle_result_arr,
    _reel_info_arr,
    _amount,
    _extra_payrate_ratio,
    _need_line_prize,
    _ITEM_ENUM,
    _SPIN_ENUM)
    --初始化返回值
    local slots_win_chip = 0 --连线赢得钱
    local formation_list = {} --结果展示表
    local all_prize_list = {} --所有的连线奖励表

    --连线计算
    --确定结算的类型
    local left_or_right = _game_room_config.direction_type --连线规则, 1左连线，2右, 3左右连线
    local payrate_file_name = "PayrateConfig"
    local payrate_file = CommonCal.Calculate.get_config(_player, _game_name .. payrate_file_name) --赔率配置
    --对每个结果进行结算
    for result_idx, _ in ipairs(_settle_result_arr) do
        --变量缓存
        local reel_info = _reel_info_arr[result_idx] --转轴的信息
        local origin_result = _origin_result_arr[result_idx]
        local final_result = _final_result_arr[result_idx]
        local settle_result = _settle_result_arr[result_idx]
        ----获得连线结果
        local prize_items = {}
        local total_payrate = 0
        if _need_line_prize then
            prize_items, total_payrate =
                SlotsGameCal.Calculate.GenPrizeInfo(
                settle_result,
                _game_room_config,
                payrate_file,
                left_or_right,
                _ITEM_ENUM,
                reel_info.formation_name,
                reel_info.line_name,
                _extra_payrate_ratio
            )
        end
        ----连线结果产生的数据统计
        --钱相关
        local once_win_chip = math.floor(total_payrate * _amount)
        slots_win_chip = slots_win_chip + once_win_chip
        --展示结果相关
        local slots_spin_list = {}
        table.insert(
            slots_spin_list,
            {
                item_ids = json.encode(
                    SlotsGameCal.Calculate.TransResultToCList(
                        origin_result,
                        _game_room_config,
                        reel_info.formation_name
                    )
                ),
                prize_items = prize_items,
                slots_win_chip = once_win_chip,
                win_chip = once_win_chip,
                final_item_ids = json.encode(
                    SlotsGameCal.Calculate.TransResultToCList(final_result, _game_room_config, reel_info.formation_name)
                )
            }
        )
        table.insert(
            formation_list,
            {
                slots_spin_list = slots_spin_list,
                id = reel_info.id
            }
        )
        table.insert(all_prize_list, prize_items)
    end

    --返回
    return slots_win_chip, formation_list, all_prize_list
end

--初始化jackpot参数
function GoldMineCalClass:InitJackpotParam(_save_data, _jackpot_config)
    --取出变量
    local prize_pool = _save_data.jackpot_param_v2.prize_pool

    --奖池赋值
    for jackpot_type, jackpot_info_config in pairs(_jackpot_config) do
        prize_pool[jackpot_type] = {
            start_point = jackpot_info_config.start_point,
            extra_chip = 0,
            double = false,
            is_point_amount = false,
            total_amount = 0
        }
    end
end

--设置jackpot的金额
function GoldMineCalClass:SetJackpotAmount(_save_data, _is_point_amount, _total_amount)
    --取出变量
    local prize_pool = _save_data.jackpot_param_v2.prize_pool

    --奖池赋值
    for jackpot_type, jackpot_info in pairs(prize_pool) do
        jackpot_info.is_point_amount = _is_point_amount
        jackpot_info.total_amount = _total_amount
    end
end

--设置jackpot是否加倍
function GoldMineCalClass:SetJackpotDouble(_save_data, _double)
    --取出变量
    local prize_pool = _save_data.jackpot_param_v2.prize_pool

    --奖池赋值
    for jackpot_type, jackpot_info in pairs(prize_pool) do
        jackpot_info.double = _double
    end
end

--增加jackpot的额外筹码值
function GoldMineCalClass:AddJackpotExtraChip(_save_data, _total_amount, _jackpot_config)
    local prize_pool = _save_data.jackpot_param_v2.prize_pool
    for prize_type, jackpot_info in pairs(prize_pool) do
        jackpot_info.extra_chip =
            math.floor(jackpot_info.extra_chip + _total_amount * _jackpot_config[prize_type].bet_to_chip_percent)
    end
end

--重置奖池中jackpot的额外筹码值
function GoldMineCalClass:ResetJackpotExtraChip(_save_data, _jackpot_type)
    _save_data.jackpot_param_v2.prize_pool[_jackpot_type].extra_chip = 0
end

--获取Jackpot奖池的筹码值
function GoldMineCalClass:GetJackpotPoolChipVal(_save_data, _jackpot_type, _total_amount)
    --初始化返回值
    local chip_val = 0

    --计算筹码值
    local jackpot_param_v2 = _save_data.jackpot_param_v2
    local jackpot_info = jackpot_param_v2.prize_pool[_jackpot_type]
    local total_amount = jackpot_info.is_point_amount and jackpot_info.total_amount or _total_amount --金额值
    local double_mutiple = jackpot_info.double and 2 or 1
    chip_val = math.floor((jackpot_info.start_point * total_amount + jackpot_info.extra_chip) * double_mutiple)

    --返回
    return chip_val
end

--获取客户端的jackpot参数
function GoldMineCalClass:GetJakcpotParamToClient(_jackpot_param)
    --初始化返回值
    local jackpot_param_cliect = table.DeepCopy(_jackpot_param)

    --处理返回值
    for _, jackpot_prize in pairs(jackpot_param_cliect.prize_pool) do
        jackpot_prize.start_point = math.floor(jackpot_prize.start_point * 10000)
    end

    --返回
    return jackpot_param_cliect
end

--进入爆炸Bonus前设置参数
function GoldMineCalClass:SetPickBonusBeforeEnter(_save_data, _player, _game_name, _rope_idx, _PRIZE_TYPE_ENUM)
    --取出变量
    local pick_config = CommonCal.Calculate.get_config(player, _game_name .. "ExplosionBonusPickConfig")[_rope_idx]

    --确定奖励信息
    --确定捡取次数
    local pick_count = 0
    --生成捡取顺序的奖池
    local prize_pool_pick = {} --实际拾取的奖池
    local pick_over = false --捡取是否结束了
    local prize_pool_config = table.DeepCopy(pick_config.prize_pool_weight_tab) --配置的带权重的奖池
    local total_amount = math.floor(_save_data.fire_rope_param.bet_total_amount / _save_data.fire_rope_param.bet_times) --bonus进入是的指定下注值
    while #prize_pool_config > 0 do
        --确定一个奖励信息
        local prize_info, prize_idx = self:GetRandomItemByWeightTab(_player, prize_pool_config) --随机一种奖励
        local prize_type = prize_info.prize_type
        --更新捡取的次数
        if not pick_over then
            --次数累计
            pick_count = pick_count + 1
            --更新结束状态
            if prize_info.is_end then
                pick_over = true
            end
        end
        --奖励金额确定
        if prize_type >= _PRIZE_TYPE_ENUM.JAKCPOT_MEGA and prize_type <= _PRIZE_TYPE_ENUM.JACKPOT_MINI then --jackpot奖励
            prize_info.prize_val = self:GetJackpotPoolChipVal(_save_data, prize_type, total_amount) --获取奖励金额
        elseif prize_type == _PRIZE_TYPE_ENUM.CHIP then
            prize_info.prize_val = prize_info.prize_val * total_amount
        end
        --更新奖池
        table.insert(prize_pool_pick, prize_info) --添加拾取的奖励
        table.remove(prize_pool_config, prize_idx) --去掉已经拿到的奖励
    end

    --计算总奖励
    local win_chip = 0
    for try_pick_idx = 1, pick_count do
        win_chip = win_chip + prize_pool_pick[try_pick_idx].prize_val
    end

    --设置奖励参数
    _save_data.pick_bonus_param = {
        bouts = 1, --触发的次数
        rope_idx = _rope_idx, --由第几节绳子燃烧触发
        --捡取游戏的信息
        pick_game_info = {
            max_pick_count = pick_count, --最多捡取的个数
            curr_pick_count = 0, --当前pick到了第几个
            pick_history = {}, --捡取的历史信息
            prize_pool = prize_pool_pick, --奖池信息
            total_amount = total_amount, --奖励的基准值
            win_chip = win_chip --游戏结束时的总收益
        }
    }
end

--进入转盘小游戏时设置参数
function GoldMineCalClass:SetTurnaroundBonusBeforeEnter(_save_data, _player, _game_name, _PRIZE_TYPE_ENUM)
    --取出变量
    local turnaround_config = CommonCal.Calculate.get_config(player, _game_name .. "ExplosionBonusTurnaroundConfig")
    local bnous_jackpot_config = CommonCal.Calculate.get_config(player, _game_name .. "ExplosionBonusJackpotConfig")
    local jackpot_config = CommonCal.Calculate.get_config(player, _game_name .. "JackpotConfig")

    --先统计每种奖励对应的转盘索引
    local prize_type_to_turnaround_idx = {} --每种奖励对应的转盘的索引
    for turnaround_idx, prize_info in ipairs(turnaround_config) do
        local prize_type = prize_info.prize_type
        --加入统计table中
        if prize_type_to_turnaround_idx[prize_type] then
            table.insert(prize_type_to_turnaround_idx[prize_type], turnaround_idx)
        else
            prize_type_to_turnaround_idx[prize_type] = {turnaround_idx}
        end
    end

    --确定本次的奖励结果
    local prize_info = self:GetRandomItemByWeightTab(_player, bnous_jackpot_config)
    local prize_jackpot_type = prize_info.id --最终奖励的jackpot类型
    local prize_have_double = math.rand_prob(_player, prize_info.double_probability) --最终奖励是否双倍
    --计算收益
    local total_amount = math.floor(_save_data.fire_rope_param.bet_total_amount / _save_data.fire_rope_param.bet_times)
    self:SetJackpotDouble(_save_data, prize_have_double) --设置jackpot的加倍
    local win_chip = self:GetJackpotPoolChipVal(_save_data, prize_jackpot_type, total_amount) --获取奖励金额
    self:SetJackpotDouble(_save_data, false) --设置jackpot的加倍后还原

    --生成每次转动结果
    local roate_result_arr = {}
    --生成前n-1次的转盘结果
    for prize_type, turnaround_idx_tab in pairs(prize_type_to_turnaround_idx) do
        local roate_times = 2 --确定转动到本次结果的次数
        if prize_type == _PRIZE_TYPE_ENUM.JACKPOT_DOUBLE then --双倍类型
            if prize_have_double then --中了，就给1次就行
                roate_times = 1
            else --没中就没有
                roate_times = 0
            end
        elseif prize_type == prize_jackpot_type then --为本次中的类型，此处只给2次（最后一次补在最末尾，用来结束转盘游戏）
            roate_times = 2
        else --其他不中的转盘奖励
            roate_times = math.random_ext(_player, 0, 2) --随机0到2次
        end

        --将转盘结果插入转动结果中
        for try_roate_times = 1, roate_times, 1 do
            local turnaround_idx = turnaround_idx_tab[math.random_ext(_player, #turnaround_idx_tab)] --随机取出一个转盘结果
            table.insert(roate_result_arr, turnaround_idx) --插入转动结果中
        end
    end
    self:RandSwapItemInTab(_player, roate_result_arr, #roate_result_arr * 10) --前n-1次结果进行打乱
    --写入最后一次转盘的结果
    local turnaround_idx_tab = prize_type_to_turnaround_idx[prize_jackpot_type] --中将的转盘索引tab
    local turnaround_idx = turnaround_idx_tab[math.random_ext(_player, #turnaround_idx_tab)] --随机取出一个转盘结果
    table.insert(roate_result_arr, turnaround_idx) --插入转动结果中

    --设置缓存参数
    _save_data.turnaround_bonus_param = {
        bouts = 1, --触发的次数
        --转盘游戏信息
        turnaround_game_info = {
            max_rotate_count = #roate_result_arr, --最多的转动次数
            curr_rotate_count = 0, --当前的转动次数
            turnaround_info = table.DeepCopy(turnaround_config), --转盘的信息
            roate_result_arr = roate_result_arr, --每次转动的转盘结果（对应转盘的索引）
            total_amount = total_amount, --奖励的基准值
            win_chip = win_chip --游戏结束时的总收益
        }
    }
end

--进入选择spin类型的小游戏前设置参数
function GoldMineCalClass:SetSpinBonusBeforEnter(_save_data, _bonus_item_count, _total_amount, _enter_info)
    --取出变量
    local spin_bonus_param = _save_data.spin_bonus_param
    local select_param = spin_bonus_param.select_param
    --bonus数据赋值
    spin_bonus_param.bouts = spin_bonus_param.bouts + 1 --游戏触发的次数
    spin_bonus_param.enter_info = _enter_info --设置进入时的信息
    select_param.total_amount = _total_amount --触发时候的金额
    if _bonus_item_count >= 5 then
        select_param.free_spin_bouts = 20
        select_param.hold_spin_bouts = 9
    elseif _bonus_item_count >= 4 then
        select_param.free_spin_bouts = 15
        select_param.hold_spin_bouts = 7
    else
        select_param.free_spin_bouts = 10
        select_param.hold_spin_bouts = 5
    end
end

--设置hold_spin的参数在进入之前
function GoldMineCalClass:SetHoldSpinBeforeEnter(
    _save_data,
    _player,
    _game_name,
    _total_amount,
    _origin_result,
    _spin_bouts,
    _point_reel_info_arr_list,
    _enter_info,
    _ITEM_ENUM)
    --确定锁定信息位置
    local lock_info_arr = {} --锁定位置信息数组
    --根据spin的结果中Detonator与Detonator_Fire确定锁定位置
    for row, row_item in ipairs(_origin_result) do
        lock_info_arr[row] = {} --初始化行
        for col, item in ipairs(row_item) do --行中的每一个
            if item == _ITEM_ENUM.Detonator or item == _ITEM_ENUM.Detonator_Fire then
                lock_info_arr[row][col] = true
            else
                lock_info_arr[row][col] = false
            end
        end
    end

    --缓存赋值
    local hold_spin_param = _save_data.hold_spin_param --取出变量
    hold_spin_param.bouts = _spin_bouts --次数
    hold_spin_param.total_amount = _total_amount --基数
    hold_spin_param.lock_info_arr = lock_info_arr --锁定图标位置信息
    hold_spin_param.big_detonator_info_arr = self:GenBigDetonatorInfoArr(_save_data) --确定炸药信息
    hold_spin_param.point_reel_info_arr_list = _point_reel_info_arr_list
    hold_spin_param.enter_info = _enter_info --进入时的信息
end

--设置free_spin的参数在进入之前
function GoldMineCalClass:SetFreeSpinBeforeEnter(_save_data, _total_amount, _spin_bouts)
    --取出参数
    local free_spin_param = _save_data.free_spin_param

    --缓存赋值
    free_spin_param.bouts = _spin_bouts
    free_spin_param.total_amount = _total_amount
end

--设置HoldSpin的统计参数
function GoldMineCalClass:SetHoldSpinStatistic(_save_data)
    --取出变量
    local hold_spin_param = _save_data.hold_spin_param
    local hold_spin_statisitc = _save_data.hold_spin_statisitc

    --计算变量
    local detonator_count_trigger = 0
    for row, row_item in ipairs(hold_spin_param.lock_info_arr) do
        for col, item in ipairs(row_item) do --行中的每一个
            if item then
                detonator_count_trigger = detonator_count_trigger + 1
            end
        end
    end

    --设置参数
    hold_spin_statisitc.total_bouts = hold_spin_param.bouts --剩余次数作为总次数
    hold_spin_statisitc.detonator_count_trigger = detonator_count_trigger --当前炸药个数
end

--生成大炸药信息
function GoldMineCalClass:GenBigDetonatorInfoArr(_save_data)
    --初始化返回值
    local big_detonator_info_arr = {} --大炸药信息

    --赋值锁定信息数组（因为需要对数组进行改变，所以进行了复制）
    local lock_info_arr = table.DeepCopy(_save_data.hold_spin_param.lock_info_arr)
    --开始进行大炸药的合成
    local find_detonator = true --是否可以寻找到炸药
    repeat
        --确定大炸药开始的位置(遍历每个有炸药的点，找到可合成炸药最大的点作为起始点)
        local start_pos = nil ---本次可合成最大大炸药开始的位置
        local max_big_detonator_idx = #self.ranked_big_detonator_info_tab + 1 --本次可合成的最大炸药信息的索引
        for row, row_info in ipairs(lock_info_arr) do
            for col, info in ipairs(row_info) do
                if info then --找到有炸药的点
                    --尝试从这个点开始合成炸药
                    local try_start_pos = {row, col}
                    for try_detonator_idx = 1, max_big_detonator_idx - 1, 1 do --只找比之前大的炸药（找小的没有意义）
                        --确定炸药的结束为止
                        local try_big_detonator_info = self.ranked_big_detonator_info_tab[try_detonator_idx]
                        local try_end_pos = {
                            try_start_pos[1] + try_big_detonator_info.row_len - 1,
                            try_start_pos[2] + try_big_detonator_info.col_len - 1
                        }

                        --判断锁定的格子所否满足合成条件
                        local try_success = true
                        if #lock_info_arr >= try_end_pos[1] and #lock_info_arr[1] >= try_end_pos[2] then --行列足够
                            --每个格子遍历判断对应格子是否是炸药
                            for try_row = try_start_pos[1], try_end_pos[1], 1 do
                                --遍历该行的列
                                for try_col = try_start_pos[2], try_end_pos[2], 1 do
                                    if not lock_info_arr[try_row][try_col] then --没有炸弹图标，则合成失败
                                        try_success = false
                                        break
                                    end
                                end
                                --若列不满足，也需要停止
                                if not try_success then
                                    break
                                end
                            end
                        else
                            try_success = false --行列不够，尝试失败
                        end

                        --尝试成功时，记录最大炸药信息，并退出循环
                        if try_success then
                            start_pos = try_start_pos
                            max_big_detonator_idx = try_detonator_idx

                            break
                        end
                    end
                end
            end
        end

        --开始尝试合成
        if start_pos then
            --设置标志量
            find_detonator = true
            --将已经使用的炸药从锁定信息中去除
            local max_big_detonator_info = self.ranked_big_detonator_info_tab[max_big_detonator_idx] --最大的炸药信息
            local end_pos = {
                start_pos[1] + max_big_detonator_info.row_len - 1,
                start_pos[2] + max_big_detonator_info.col_len - 1
            }
            for try_row = start_pos[1], end_pos[1], 1 do
                for try_col = start_pos[2], end_pos[2], 1 do
                    lock_info_arr[try_row][try_col] = false
                end
            end
            --记录大炸药信息
            table.insert(
                big_detonator_info_arr,
                {
                    type = max_big_detonator_info.type,
                    area = max_big_detonator_info.area,
                    start_pos = start_pos,
                    end_pos = end_pos
                }
            )
        else
            --设置标志量
            find_detonator = false
        end
    until (not find_detonator)

    --返回
    return big_detonator_info_arr
end

--根据炸药的结果更新最终的结果中的图标信息
function GoldMineCalClass:UpdateFinalResultByDetonatorInfoArr(_final_result, _big_detonator_info_arr)
    for _, big_detonator_info in pairs(_big_detonator_info_arr) do --最后结果
        --变量取出
        local start_pos = big_detonator_info.start_pos
        local end_pos = big_detonator_info.end_pos

        --炸药图标替换Item值
        local start_item = big_detonator_info.type * 100 --大炸药左上角的图标编码
        for row = start_pos[1], end_pos[1], 1 do
            for col = start_pos[2], end_pos[2], 1 do
                _final_result[row][col] = start_item + (row - start_pos[1]) + 1
            end
        end
    end
end

--获取下一步游戏的走向
function GoldMineCalClass:GetGameChangeToStepInControl(_save_data, _SPIN_ENUM, _BONUS_ENUM)
    --初始化返回值
    local change_to_spin_type = nil
    local change_to_bonus_type = nil

    --根据当前的状态，确定游戏的走向
    if _save_data.curr_spin_type == _SPIN_ENUM.BASE_SPIN then
        if _save_data.pick_bonus_param.bouts > 0 then --捡取的小游戏
            if _save_data.pick_bonus_param.rope_idx == 1 then
                change_to_bonus_type = _BONUS_ENUM.PICK_BONUS_1
            elseif _save_data.pick_bonus_param.rope_idx == 2 then
                change_to_bonus_type = _BONUS_ENUM.PICK_BONUS_2
            end
        elseif _save_data.turnaround_bonus_param.bouts > 0 then --转盘小游戏
            change_to_bonus_type = _BONUS_ENUM.TURNAROUND_BONUS
        elseif _save_data.hold_spin_param.bouts > 0 then --hold_spin
            change_to_spin_type = _SPIN_ENUM.HOLD_SPIN
        elseif _save_data.spin_bonus_param.bouts > 0 then --选择spin的bonus
            change_to_bonus_type = _BONUS_ENUM.SPIN_BONUS
        elseif _save_data.free_spin_param.bouts > 0 then --free_spin
            change_to_spin_type = _SPIN_ENUM.FREE_SPIN
        end
    elseif _save_data.curr_spin_type == _SPIN_ENUM.HOLD_SPIN then
        if _save_data.hold_spin_param.bouts == 0 then --结束时才能切换其他的
            if _save_data.spin_bonus_param.bouts > 0 then --选择spin的bonus
                change_to_bonus_type = _BONUS_ENUM.SPIN_BONUS
            elseif _save_data.free_spin_param.bouts > 0 then --free_spin
                change_to_spin_type = _SPIN_ENUM.FREE_SPIN
            else
                change_to_spin_type = _SPIN_ENUM.BASE_SPIN
            end
        end
    elseif _save_data.curr_spin_type == _SPIN_ENUM.FREE_SPIN then
        if _save_data.free_spin_param.bouts == 0 then --结束时才能切换其他的
            change_to_spin_type = _SPIN_ENUM.BASE_SPIN
        end
    end

    --返回
    return change_to_spin_type, change_to_bonus_type
end

--移动到下一个游戏状态
function GoldMineCalClass:MoveTotGameChangeToStepInControl(
    _save_data,
    _pre_action_list,
    _player,
    _game_name,
    _player_game_info,
    _change_to_spin_type,
    _change_to_bonus_type,
    _SPIN_ENUM,
    _BONUS_ENUM,
    _PRIZE_TYPE_ENUM,
    _parameters)
    --取出变量
    local game_type = _parameters.game_type
    local player_game_status = _parameters.player_game_status
    local player_game_info = _parameters.player_game_info
    local session = _parameters.session
    local task = session.task

    --根据参数，移动到下个步骤
    if _change_to_spin_type then
        --游戏内的变量设置
        _save_data.curr_spin_type = _change_to_spin_type --更改当前的spin类型
        self:UpdateCurrReelInfoArr(_save_data, _SPIN_ENUM) --更新转轴信息

        --外围通用变量设置
        local spin_bouts = -1 --切换到的spin的次数
        if _change_to_spin_type == _SPIN_ENUM.BASE_SPIN then
        elseif _change_to_spin_type == _SPIN_ENUM.HOLD_SPIN then
            --spin次数记录
            spin_bouts = _save_data.hold_spin_param.bouts
            --更新jackpot
            self:SetJackpotAmount(_save_data, true, _save_data.hold_spin_param.total_amount)
            --设置外围变量
            -- _save_data.feature_spin_type = 0
            -- _save_data.feature_spin_count = spin_bouts
            GameStatusCal.Calculate.AddGameStatus(
                player_game_status,
                GameStatusDefine.AllTypes.HoldSpinGame,
                spin_bouts,
                3,
                SlotsGameCal.Calculate.GetBetAmount(player_game_info)
            )
        elseif _change_to_spin_type == _SPIN_ENUM.FREE_SPIN then
            --spin次数记录
            spin_bouts = _save_data.free_spin_param.bouts
            --设置外围变量
            _player_game_info.free_total_win = 0 --清零free-spin的总赢钱
            GameStatusCal.Calculate.AddGameStatus(
                player_game_status,
                GameStatusDefine.AllTypes.FreeSpinGame,
                spin_bouts,
                1,
                SlotsGameCal.Calculate.GetBetAmount(player_game_info)
            )
        end

        --插入阵形的信息Action
        table.insert(
            _pre_action_list,
            {
                action_type = ActionType.ActionTypes.SwitchSpinType,
                parameter_list = {
                    spin_type = _save_data.curr_spin_type,
                    spin_bouts = spin_bouts,
                    reel_info_arr = _save_data.reel_info_arr
                }
            }
        )
    elseif _change_to_bonus_type then
        --设置游戏内部数据
        if _change_to_bonus_type == _BONUS_ENUM.PICK_BONUS_1 or _change_to_bonus_type == _BONUS_ENUM.PICK_BONUS_2 then
            --更新jackpot
            self:SetJackpotAmount(_save_data, true, _save_data.pick_bonus_param.pick_game_info.total_amount)
        elseif _change_to_bonus_type == _BONUS_ENUM.TURNAROUND_BONUS then
            --更新jakcpot
            self:SetJackpotAmount(_save_data, true, _save_data.turnaround_bonus_param.turnaround_game_info.total_amount)
        elseif _change_to_bonus_type == _BONUS_ENUM.SPIN_BONUS then
        end

        --外围通用变量设置
        _player_game_info.bonus_game_type = _change_to_bonus_type

        --插入切换Bonus的Action
        table.insert(
            _pre_action_list,
            {
                action_type = ActionType.ActionTypes.EnterBonus,
                bonus_game_type = _change_to_bonus_type
            }
        )
    end
end

--更新当前的转轴阵形
function GoldMineCalClass:UpdateCurrReelInfoArr(_save_data, _SPIN_ENUM)
    local curr_spin_type = _save_data.curr_spin_type
    if curr_spin_type == _SPIN_ENUM.BASE_SPIN then
        local fomation_id_start = 1
        _save_data.reel_info_arr = {
            {
                id = fomation_id_start,
                formation_name = "Formation1",
                line_name = "Lines1",
                feature_file_name = nil
            }
        }
    elseif curr_spin_type == _SPIN_ENUM.HOLD_SPIN then
        local fomation_id_start = 1
        _save_data.reel_info_arr = {
            {
                id = fomation_id_start,
                formation_name = "Formation1",
                line_name = "Lines1",
                feature_file_name = "GoldMineHoldSpinReelConfig"
            }
        }
    elseif curr_spin_type == _SPIN_ENUM.FREE_SPIN then
        local fomation_id_start = 1
        --设置reel的信息
        _save_data.reel_info_arr = {
            {
                id = fomation_id_start,
                formation_name = "Formation1",
                line_name = "Lines1",
                feature_file_name = nil
            }
        }
    end
end
