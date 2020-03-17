require "Common/SlotsGameCal" --旧的接口

NewPurrfectPetsCalClass = {}
NewPurrfectPetsCalClass.__index = NewPurrfectPetsCalClass

--检查保存数据的完整性
function NewPurrfectPetsCalClass:GetSaveData(_player, _player_game_info, _game_name, _SPIN_ENUM)
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
                feature_file_name = nil,
                wild_cols = {}
            }
        }
    end
    --金币金额信息
    if not save_data.coin_info_arr then
        save_data.coin_info_arr = {}
    end
    save_data.coin_info_arr = self:ListToArr_2(save_data.coin_info_arr)
    --coin_spin_bouts数量处理
    if not save_data.coin_spin_bouts then
        save_data.coin_spin_bouts = 0
        save_data.coin_spin_param = {
            play_again_bouts = 0, --再次玩的机会
            lock_coin_info_arr = {}, --锁定金币信息
            all_amount = 0, --所有的奖励金额
            spin_times = 0, --这是本轮coin_spin的第几次spin（play coin_spin agin时，清空为1）
            trigger_by_collect = false, --是否由收集触发
            point_amount_when_spin = 0 --spin时制定的下注金额（仅当trigger_by_collect时有效）
        }
    end
    save_data.coin_spin_param.lock_coin_info_arr = self:ListToArr_2(save_data.coin_spin_param.lock_coin_info_arr)
    --coin_spin_v2（新加主key，防止老玩家出现缓存不存在的情况） 新加功能处理,用于控制coin-spin每次出来的金币数量
    if not save_data.coin_spin_param_v2 then
        save_data.coin_spin_param_v2 = {
            left_coin_count_sequence = {0, 1, 0, 3, 1} --剩余随机出金币的序列(默认赠送5个，针对使用老代码触发coin-spin的老玩家)
        }
    end

    --reels_spin数据处理
    if not save_data.reels_spin_bouts then
        save_data.reels_spin_bouts = 0
        save_data.reels_spin_param = {
            --各轴信息
            reels = {
                [1] = {
                    row_num = 3, --行数
                    col_num = 5, --列数
                    wild_cols = {} --有wild的列
                }
            },
            trigger_by_collect = false, --是否由收集触发
            trigger_by_bix_box = false, --是否由收集的开启大盒子触发
            point_amount_when_spin = 0 --spin时制定的下注金额（仅当trigger_by_collect时有效）
        }
    end
    --bonus_game数据处理
    if not save_data.bonus_game_bouts then
        save_data.bonus_game_bouts = 0
        save_data.bonus_game_param = {
            bonus_win = 0, --小游戏赢的筹码
            walk_pos = 0, --当前在地图中行走到的位置
            walk_end = false, --是否行走已经结束。当为true时，则说明行走已经结束，需要调用小游戏结算的接口
            --多轴转动的参数
            reels_spin_param = {
                --轴的结果
                reels = {},
                --转动的次数
                reels_spin_bouts = 0
            },
            -- --转盘配置
            -- turnaround_config = nil,
            -- --当前地图的内容
            -- map_info = nil
            trigger_by_collect = false, --是否由收集触发
            base_amount = 0, --筹码奖励的基数(用作筹码奖励时的基数，与奖励系数相乘)
            --地图每个格子的奖励使用信息数组
            map_prize_use_info_arr = {
                ordinary_item_use_arr = {}, --普通物品的使用信息数组
                special_item_use_arr = {} --特殊物品的使用信息数组
            },
            --下次spin是否走到终点的预判数组
            next_spin_predict = {}
        }
    end
    --游戏内jackpot
    if not save_data.jackpot_param then
        --赋值初始值
        save_data.jackpot_param = {}
        save_data.jackpot_param.prize_pool = {}
        local jackpot_config = CommonCal.Calculate.get_config(_player, _game_name .. "JackpotConfig")
        for _, prize_config in ipairs(jackpot_config) do
            save_data.jackpot_param.prize_pool[prize_config.prize_type] = {
                start_point = prize_config.start_point,
                extra_chip = 0
            }
        end
    end
    --收集系统
    if not save_data.collect_param then
        local collect_prize_page_config =
            CommonCal.Calculate.get_config(_player, _game_name .. "CollectPrizePageConfig")
        save_data.collect_param = {
            collect_num = 0, --已经收集的个数
            amount_per_collect = 500, --每个收集元素的价值
            curr_page = 1, --当前所处的页数
            collect_page_open_arr = self:GenNewCollectPageOpenArr(_player, collect_prize_page_config) --收集礼盒的开启信息
        }
    end

    ----返回
    return save_data
end

--保存sava_data
function NewPurrfectPetsCalClass:RecordSaveData(_player_game_info, _save_data)
    --不连续table进行转化处理
    --金币金额信息
    _save_data.coin_info_arr = self:ArrToList_2(_save_data.coin_info_arr)
    --锁定金币信息
    _save_data.coin_spin_param.lock_coin_info_arr = self:ArrToList_2(_save_data.coin_spin_param.lock_coin_info_arr)
end

--数组转化为列表
function NewPurrfectPetsCalClass:ArrToList_2(_arr)
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
function NewPurrfectPetsCalClass:ListToArr_2(_list)
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

--根据带有权重的信息表获取一个随机
function NewPurrfectPetsCalClass:GetRandomItemByWeightTab(_player, _item_with_weight_tab)
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

--更新当前的转轴阵形
function NewPurrfectPetsCalClass:UpdateCurrReelInfoArr(_save_data, _SPIN_ENUM)
    local fomation_id_start = 1 --formation中的id数字
    local curr_spin_type = _save_data.curr_spin_type
    if curr_spin_type == _SPIN_ENUM.BASE_SPIN then
        fomation_id_start = 1
        _save_data.reel_info_arr = {
            {
                id = fomation_id_start,
                formation_name = "Formation1",
                line_name = "Lines1",
                feature_file_name = nil,
                wild_cols = {}
            }
        }
    elseif curr_spin_type == _SPIN_ENUM.COIN_SPIN then
        fomation_id_start = 1
        _save_data.reel_info_arr = {
            {
                id = fomation_id_start,
                formation_name = "Formation1",
                line_name = "Lines1",
                feature_file_name = "NewPurrfectPetsCoinReelServerConfig",
                wild_cols = {}
            }
        }
    elseif curr_spin_type == _SPIN_ENUM.REELS_SPIN then
        --设置reel的信息
        local reels = _save_data.reels_spin_param.reels
        _save_data.reel_info_arr = {}
        for reel_idx = 1, #reels, 1 do
            local reel = reels[reel_idx]
            fomation_id_start = (reel.row_num == 4) and 6 or 2
            local formation_name = (reel.row_num == 4) and "Formation1" or "Formation2"
            local line_name = (reel.row_num == 4) and "Lines1" or "Lines2"
            local feature_file_name =
                _save_data.reels_spin_param.trigger_by_collect and "NewPurrfectPetsBoxFreeSpinReelConfig" or nil
            _save_data.reel_info_arr[reel_idx] = {
                id = fomation_id_start + reel_idx - 1,
                formation_name = formation_name,
                line_name = line_name,
                feature_file_name = feature_file_name,
                wild_cols = reel.wild_cols
            }
        end
    end
end

--物品数组里是否有足够的指定物品
function NewPurrfectPetsCalClass:HaveEnoughItemInItemArr(_item_arr, _item_type, _need_num)
    --初始化返回值
    local have_enough = false

    --统计个数
    local item_num = 0
    for row, item_row in pairs(_item_arr) do
        for col, item in pairs(item_row) do
            if item == _item_type then
                item_num = item_num + 1
                --检测触发
                if (item_num >= _need_num) then
                    have_enough = true
                    return have_enough
                end
            end
        end
    end

    --返回
    return have_enough
end

--从原始的结果数组中筛选出只有制定类型的数组
function NewPurrfectPetsCalClass:FilterPointItemTypeArr(_orign_result, _point_item_type)
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

--获取可生成新金币的位置
function NewPurrfectPetsCalClass:GetGenNewCoinItemPosList(_orign_result, _lock_coin_info_arr, _ITEM_ENUM)
    --初始化返回值
    local coin_pos_list = {}

    --根据lock信息，计算可新生成金币图标的位置
    for row, item_row in ipairs(_orign_result) do
        for col, _ in ipairs(item_row) do
            --此处是否可新生成金币图标
            local can_gen = false
            if _lock_coin_info_arr then --有锁定金币信息时，如果此处没有金币，则可以生成
                if not (_lock_coin_info_arr[row] and _lock_coin_info_arr[row][col]) then
                    can_gen = true
                end
            else --没有锁定金币信息时，可直接生成
                can_gen = true
            end

            --根据结果，插入可生成的位置
            if can_gen then
                table.insert(coin_pos_list, {pos = {row, col}})
            end
        end
    end

    --返回
    return coin_pos_list
end

--获取生成金币信息的位置数组
function NewPurrfectPetsCalClass:GetGenCoinInfoPosArr(_orign_result, _lock_coin_info_arr, _ITEM_ENUM)
    --初始化返回值
    local coin_pos_arr = {}

    --设置生成金币位置
    for row, item_row in ipairs(_orign_result) do
        for col, item in ipairs(item_row) do
            if item == _ITEM_ENUM.Coin then
                --此处是否需要生成金币信息
                local need_gen = false
                if _lock_coin_info_arr then --有锁定金币信息时，如果此处没有金币，则可以生成
                    if not (_lock_coin_info_arr[row] and _lock_coin_info_arr[row][col]) then
                        need_gen = true
                    end
                else --没有锁定金币信息时，可直接生成
                    need_gen = true
                end
                --填充信息
                if need_gen then
                    --数据行检查
                    if not coin_pos_arr[row] then
                        coin_pos_arr[row] = {}
                    end
                    --填入数据
                    coin_pos_arr[row][col] = true
                end
            end
        end
    end

    --返回
    return coin_pos_arr
end

--生成金币信息数组
function NewPurrfectPetsCalClass:GenCoinInfoArr(
    _save_data,
    _player,
    _coin_pos_arr,
    _config,
    _feature_again_type,
    _max_play_agin_coin_num,
    _send_jackpot_prize_arr,
    _total_amount)
    --初始化返回值
    local coin_info_arr = {}
    local gen_play_again_coin_num = 0

    --根据配置进行生产
    --生成权重表
    local weight_tab = {}
    for idx, item in ipairs(_config) do
        weight_tab[idx] = item.probability
    end
    --进行生成金币信息
    local curr_feature_agin_coin_num = 0 --当前生成的feature_agin的金币数量
    for row, coin_pos_row in pairs(_coin_pos_arr) do
        for col, _ in pairs(coin_pos_row) do
            --生成金币信息（对feature_agin图标的最大数量有限制）
            local coin_info = nil
            repeat
                local jackpot_prize_type = _send_jackpot_prize_arr[1]
                if jackpot_prize_type then --先尝试取送的jackpot奖励
                    --使用jackpot奖励
                    coin_info = {
                        prize_type = jackpot_prize_type,
                        amount = 0
                    }
                    --更新_send_jackpot_prize_arr表
                    table.remove(_send_jackpot_prize_arr, 1)
                else --再随机奖励
                    --随机到结果信息
                    local result_idx = math.rand_weight(_player, weight_tab)
                    --金币信息初始化
                    coin_info = {
                        prize_type = _config[result_idx].prize_type,
                        amount = math.floor(_config[result_idx].bonus_percent * _total_amount)
                    }
                end
            until (coin_info.prize_type ~= _feature_again_type or
                curr_feature_agin_coin_num + 1 <= _max_play_agin_coin_num)

            --jackpot奖励的奖励值赋值d
            local prize_pool = _save_data.jackpot_param.prize_pool --jackpot奖池
            local prize_type = coin_info.prize_type
            local jackpot_prize = prize_pool[prize_type]
            if (jackpot_prize) then
                coin_info.amount = math.floor(jackpot_prize.start_point * _total_amount + jackpot_prize.extra_chip) --填写奖金
            end

            --记录生成feature_agin_coin数量
            if coin_info.prize_type == _feature_again_type then
                gen_play_again_coin_num = gen_play_again_coin_num + 1
            end

            --记录返回结果
            if not coin_info_arr[row] then --行数据检查
                coin_info_arr[row] = {}
            end
            coin_info_arr[row][col] = coin_info --数据记录
        end
    end

    --返回值
    return coin_info_arr, gen_play_again_coin_num
end

--获取指定类型金币的数量在金币信息数组中
function NewPurrfectPetsCalClass:GetAppointTypeNumInCoinArr(_coin_info_arr, _appoint_prize_type)
    --初始化返回值
    local item_num = 0

    --进行数量统计
    for row, coin_info_row in pairs(_coin_info_arr) do
        for col, coin_info in pairs(coin_info_row) do
            if coin_info.prize_type == _appoint_prize_type then
                item_num = item_num + 1
            end
        end
    end

    --返回
    return item_num
end

--进入coin_spin前设置coin_spin相关的信息
function NewPurrfectPetsCalClass:SetCoinSpinParamBeforeEnter(
    _save_data,
    _player,
    _game_name,
    _lock_coin_info,
    _trigger_by_collect,
    _point_amount_when_spin,
    _parameters)
    --取出变量
    local game_type = _parameters.game_type
    local player_game_status = _parameters.player_game_status
    local player_game_info = _parameters.player_game_info
    local session = _parameters.session
    local task = session.task
    --游戏内的变量设置
    _save_data.coin_spin_bouts = 3
    _save_data.coin_spin_param.lock_coin_info_arr = _lock_coin_info
    _save_data.coin_spin_param.spin_times = 0
    _save_data.coin_spin_param.trigger_by_collect = _trigger_by_collect
    _save_data.coin_spin_param.point_amount_when_spin = _point_amount_when_spin
    --外围逻辑变量设置（用于触发feature_spin）
    GameStatusCal.Calculate.AddGameStatus(
        player_game_status,
        GameStatusDefine.AllTypes.HoldSpinGame,
        _save_data.coin_spin_bouts,
        3,
        SlotsGameCal.Calculate.GetBetAmount(player_game_info)
    )

    ----coin-spin每次的随机到的金币个数控制
    --变量取出
    local all_coin_count_config =
        CommonCal.Calculate.get_config(_player, _game_name .. "CoinSpinGenerateAllCoinCountConfig") --总共剩余金币的个数配置表
    local left_coin_count_per_spin_config =
        CommonCal.Calculate.get_config(_player, _game_name .. "CoinSpinGenerateLeftCoinCountPerSpinConfig") --剩余金币每次spin出来的金币数量配置
    --接下来每次出coin的数量序列初始化
    local left_coin_count_sequence_real = {}
    --触发时，金币的数量统计
    local coin_count_when_trigger = 0
    for row, row_item in pairs(_lock_coin_info) do
        for col, _ in pairs(row_item) do
            coin_count_when_trigger = coin_count_when_trigger + 1
        end
    end
    --触发时，如果没有金币，则下次先赠送6个
    if coin_count_when_trigger == 0 then
        coin_count_when_trigger = 6
        table.insert(left_coin_count_sequence_real, coin_count_when_trigger)
    end
    --确定本次spin的总金币数量
    local coin_count_all = self:GetRandomItemByWeightTab(_player, all_coin_count_config).coin_count
    if coin_count_all < coin_count_when_trigger then --首次触发的金币比得到的总金币多，则总金币变为首次触发的金币
        coin_count_all = coin_count_when_trigger
    end
    --确定剩余金币出现的数量序列
    local coin_count_left = coin_count_all - coin_count_when_trigger
    if coin_count_left > 0 then --有剩余的金币
        --得到剩余金币出现的个数序列
        local left_coin_count_sequence_weight_tab =
            left_coin_count_per_spin_config[coin_count_left].left_coin_count_sequence_weight_tab --剩余金币对应的出现序列的权重表
        local left_coin_count_sequence_config =
            table.DeepCopy(self:GetRandomItemByWeightTab(_player, left_coin_count_sequence_weight_tab).squence) --进行随机，得到出现的序列

        --将配置的序列前n-1个进行随机
        local left_coin_count_sequence_random = {}
        local sequence_len = #left_coin_count_sequence_config
        --取出最后一个(放在最后)
        left_coin_count_sequence_random[1] = left_coin_count_sequence_config[sequence_len]
        table.remove(left_coin_count_sequence_config, sequence_len)
        --随机取前n-1个
        while (#left_coin_count_sequence_config > 0) do
            local take_idx = math.random_ext(_player, #left_coin_count_sequence_config)
            table.insert(left_coin_count_sequence_random, 1, left_coin_count_sequence_config[take_idx]) --插入随机拿到的数据
            table.remove(left_coin_count_sequence_config, take_idx) --移除已经取出的数据
        end

        --将随机得到的序列填入到真实的序列中
        for _, coin_count in ipairs(left_coin_count_sequence_random) do
            --出金币前，插入不出现金币的情况
            local zero_coin_count_times = math.random_ext(_player, 0, 2)
            for zero_idx = 1, zero_coin_count_times, 1 do
                table.insert(left_coin_count_sequence_real, 0)
            end

            --插入出现的金币的个数
            table.insert(left_coin_count_sequence_real, coin_count)
        end
    end

    --设置出现金币的真实序列
    _save_data.coin_spin_param_v2.left_coin_count_sequence = left_coin_count_sequence_real
end

--处理CoinSpin的结果
function NewPurrfectPetsCalClass:HandleCoinSpin(
    _origin_result_arr,
    _final_coin_info_arr,
    _save_data,
    _jackpot_config,
    _total_amount,
    _ITEM_ENUM,
    _COIN_PRIZE_ENUM,
    _special_parameter,
    _parameters)
    --初始化返回值
    local is_coin_spin_over = false
    local coin_spin_win = 0
    local have_take_jackpot = false

    --取出变量
    local game_type = _parameters.game_type
    local player_game_status = _parameters.player_game_status
    local player_game_info = _parameters.player_game_info
    local session = _parameters.session
    local task = session.task
    local cur_status_info = GameStatusCal.Calculate.GetGameStatusInfo(player_game_status)
    --处理结果
    ----将锁定金币结果更新到spin结果中
    local lock_coin_info_arr = _save_data.coin_spin_param.lock_coin_info_arr --上次的金币信息
    local origin_result = _origin_result_arr[1] --feature只会有一个reel
    local final_coin_info = _final_coin_info_arr[1] --feature只会有一个reel
    local new_coin_count = 0 --本次spin中新增加的coin图标
    local not_coin_count = 0 --非coin的图标

    for row, item_row in pairs(origin_result) do
        for col, item in pairs(item_row) do
            if (lock_coin_info_arr[row] and lock_coin_info_arr[row][col]) then --已经锁定时，则使用锁定信息
                local lock_coin_info = lock_coin_info_arr[row][col]
                origin_result[row][col] = _ITEM_ENUM.Coin --赋值spin结果
                --赋值显示的金币信息
                if not final_coin_info[row] then --行检查
                    final_coin_info[row] = {}
                end
                final_coin_info[row][col] = lock_coin_info
            elseif (final_coin_info[row] and final_coin_info[row][col]) then --没有锁定，但有新的金币信息时，采用新的金币信息
                new_coin_count = new_coin_count + 1 --新的金币数量统计
                local new_coin_info = final_coin_info[row][col] --新的金币信息
                origin_result[row][col] = _ITEM_ENUM.Coin --赋值spin结果
                --更新锁定金币信息
                if not lock_coin_info_arr[row] then
                    lock_coin_info_arr[row] = {}
                end
                lock_coin_info_arr[row][col] = new_coin_info
            else
                not_coin_count = not_coin_count + 1
            end
        end
    end

    --更新coin_spin次数
    ----已经Spin次数
    _save_data.coin_spin_param.spin_times = _save_data.coin_spin_param.spin_times + 1 --游戏内变量
    ----剩余次数
    if not_coin_count == 0 then --全为金币是 游戏结束
        _save_data.coin_spin_bouts = 0
    else --否则走正常流程
        if (new_coin_count > 0) then
            _save_data.coin_spin_bouts = 3
        else
            _save_data.coin_spin_bouts = _save_data.coin_spin_bouts - 1
        end
    end
    ------外围变量
    local addSpinBouts = _save_data.coin_spin_bouts - (cur_status_info.total_process - (cur_status_info.process + 1)) --注意此处cur_status_info.process的+1需要等到Spin函数完后，外围统一调用
    if addSpinBouts > 0 then
        GameStatusCal.Calculate.AddGameStatus(
            player_game_status,
            GameStatusDefine.AllTypes.HoldSpinGame,
            addSpinBouts,
            1,
            SlotsGameCal.Calculate.GetBetAmount(player_game_info)
        )
    end

    is_coin_spin_over = (_save_data.coin_spin_bouts == 0)
    if (is_coin_spin_over) then --本轮coin_spin结束
        ----jackpot奖励计算
        local prize_type_taked_arr = {} --拿了jackpot奖励的奖励id数组
        local prize_pool = _save_data.jackpot_param.prize_pool --jackpot奖池
        for row, coin_info_row in pairs(final_coin_info) do
            for col, coin_info in pairs(coin_info_row) do
                local prize_type = coin_info.prize_type
                local jackpot_prize = prize_pool[prize_type]
                if (jackpot_prize) then
                    --标记jackpot奖励被拿走
                    have_take_jackpot = true
                    --记录拿走的jackpot
                    prize_type_taked_arr[prize_type] = true
                    --统计信息
                    local jackpot_statistics = _special_parameter.game_jackpot[prize_type]
                    jackpot_statistics.trigger_times = jackpot_statistics.trigger_times + 1
                    jackpot_statistics.win_chip = jackpot_statistics.win_chip + coin_info.amount
                end
            end
        end

        --被赢取的jackpot恢复到初始值
        for _, prize_config in ipairs(_jackpot_config) do
            local prize_type = prize_config.prize_type
            if (prize_type_taked_arr[prize_type]) then
                prize_pool[prize_type].start_point = prize_config.start_point
                prize_pool[prize_type].extra_chip = 0
            end
        end

        ----统计赢钱信息
        for row, coin_info_row in pairs(final_coin_info) do
            for col, coin_info in pairs(coin_info_row) do
                coin_spin_win = coin_spin_win + coin_info.amount
            end
        end
    end

    --返回
    return is_coin_spin_over, coin_spin_win, have_take_jackpot
end

--生成连线奖励
function NewPurrfectPetsCalClass:GenLinePrize(
    _player,
    _game_room_config,
    _game_name,
    _curr_spin_type,
    _origin_result_arr,
    _final_result_arr,
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
    local payrate_file_name = _curr_spin_type == _SPIN_ENUM.REELS_SPIN and "FreeSpinPayrateConfig" or "PayrateConfig"
    local payrate_file = CommonCal.Calculate.get_config(_player, _game_name .. payrate_file_name) --赔率配置
    --对每个结果进行结算
    for result_idx, origin_result in ipairs(_origin_result_arr) do
        --变量缓存
        local reel_info = _reel_info_arr[result_idx] --转轴的信息
        ----获得连线结果
        local prize_items = {}
        local total_payrate = 0
        if _need_line_prize then
            prize_items, total_payrate =
                SlotsGameCal.Calculate.GenPrizeInfo(
                origin_result,
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
        local final_result = _final_result_arr[result_idx]
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

function NewPurrfectPetsCalClass:GetChangeToSpinType(_save_data, _is_coin_spin_over, _SPIN_ENUM)
    --初始化返回值
    local change_to_spin_type = nil --要改变为的游戏状态（如果没有改变，则为nil）
    local can_enter_bonus_game = false --是否可进入小游戏
    local is_agin_coin_spin = false --是否是再次coin_spin

    --确定切换到的spin类型
    if _save_data.curr_spin_type == _SPIN_ENUM.BASE_SPIN then
        --确定下次spin的类型
        if _save_data.coin_spin_bouts > 0 then
            change_to_spin_type = _SPIN_ENUM.COIN_SPIN
        end

        --必须没有coin_spin情况 才能进入bonus_game
        if _save_data.coin_spin_bouts == 0 then
            if _save_data.bonus_game_bouts > 0 then
                can_enter_bonus_game = true
            end
        end
    elseif _save_data.curr_spin_type == _SPIN_ENUM.COIN_SPIN then
        if _is_coin_spin_over then
            --确定下次spin的类型
            if _save_data.coin_spin_param.play_again_bouts > 0 then --有play_again
                change_to_spin_type = _SPIN_ENUM.COIN_SPIN
                is_agin_coin_spin = true
            else --没有play_again,则下次为普通spin
                change_to_spin_type = _SPIN_ENUM.BASE_SPIN
            end

            --必须没有coin_spin情况 才能进入bonus_game
            if _save_data.coin_spin_param.play_again_bouts == 0 then
                if _save_data.bonus_game_bouts > 0 then
                    can_enter_bonus_game = true
                end
            end
        end
    elseif _save_data.curr_spin_type == _SPIN_ENUM.REELS_SPIN then
        if _save_data.reels_spin_bouts == 0 then
            change_to_spin_type = _SPIN_ENUM.BASE_SPIN
        end
    end

    --返回
    return change_to_spin_type, can_enter_bonus_game, is_agin_coin_spin
end

--进入bonus_game前设置bonus_game的参数
function NewPurrfectPetsCalClass:SetBonusGameParamBeforeEnter(
    _save_data,
    _player,
    _game_name,
    _trigger_by_collect,
    _total_amount,
    _MAP_PRIZE_ENUM,
    _TURNAROUND_RESULT_ENUM)
    ----获取需要用到的配置
    local get_config_func = CommonCal.Calculate.get_config
    local ordinary_item_arr_config = get_config_func(_player, _game_name .. "BonusMapOrdinaryItemArrConfig") --地图普通格子配置
    local special_item_arr_config = get_config_func(_player, _game_name .. "BonusMapSpecialItemArrConfig") --地图特殊格子配置
    local turnaround_config = get_config_func(_player, _game_name .. "BonusTurnaroundConfig") --转盘配置

    ----生成地图奖励使用信息
    --普通格子的使用信息
    local ordinary_item_use_arr = {}
    for itme_idx, item_info in ipairs(ordinary_item_arr_config) do
        ordinary_item_use_arr[itme_idx] = {}
        for prize_idx, prize_info in ipairs(item_info.prize_arr) do
            ordinary_item_use_arr[itme_idx][prize_idx] = {
                bouts = 0 --奖励使用的次数
            }
        end
    end
    --特殊格子的使用信息
    local special_item_use_arr = {}
    for item_idx, item_info in ipairs(special_item_arr_config) do
        --添加通用参数
        special_item_use_arr[item_idx] = {
            bouts = 0 --奖励使用的次数
        }
    end

    --记录进save_data数据
    local walk_pos = 0
    _save_data.bonus_game_param = {
        bonus_win = 0, --小游戏赢的筹码
        walk_pos = 0, --当前在地图中行走到的位置
        walk_end = false, --是否行走已经结束。当为true时，则说明行走已经结束，需要调用小游戏结算的接口
        --多轴转动的参数
        reels_spin_param = {
            --轴的结果
            reels = {
                --奖励得到的转轴
                [1] = {
                    row_num = 3, --行数
                    col_num = 5, --列数
                    wild_cols = {} --有wild的列
                }
            },
            --转动的次数
            reels_spin_bouts = 5
        },
        trigger_by_collect = _trigger_by_collect, --是否由收集触发
        base_amount = _total_amount, --筹码奖励的基数(用作筹码奖励时的基数，与奖励系数相乘)
        --地图每个格子的奖励使用信息数组
        map_prize_use_info_arr = {
            ordinary_item_use_arr = ordinary_item_use_arr, --普通物品的使用信息数组
            special_item_use_arr = special_item_use_arr --特殊物品的使用信息数组
        },
        --下次spin结果的预判数据
        next_spin_predict = self:GetBonusNextSpinPredictArr(
            ordinary_item_arr_config,
            special_item_arr_config,
            turnaround_config,
            walk_pos,
            _TURNAROUND_RESULT_ENUM
        )
    }
end

--获取客户端的普通格子信息
function NewPurrfectPetsCalClass:GetClinetMapOrdinaryItemInfo(
    _server_item_info,
    _server_item_user_info,
    _base_amount,
    _MAP_PRIZE_ENUM)
    --初始化返回值
    local client_item_info = {
        prize_type = 0,
        prize_val = 0
    }

    --填入信息
    for prize_idx, prize_info in ipairs(_server_item_info.prize_arr) do --寻找未用的prize
        local prize_use_info = _server_item_user_info[prize_idx]
        if (prize_info.prize_bouts == -1 or prize_use_info.bouts < prize_info.prize_bouts) then --有无限的使用次数或者还有剩余使用次数
            --筹码奖励进行特殊处理
            local prize_val = prize_info.prize_val
            if prize_info.prize_type == _MAP_PRIZE_ENUM.CHIP then
                prize_val = math.floor(prize_val * _base_amount)
            end
            --赋值奖励
            client_item_info.prize_type = prize_info.prize_type
            client_item_info.prize_val = prize_val
            break
        end
    end

    --返回
    return client_item_info
end

--获取客户端的特殊格子信息
function NewPurrfectPetsCalClass:GetClinetMapSpecialItemInfo(_server_item_info, _item_use_info)
    --初始化返回值
    local client_item_info = {
        visable = false
    }

    --填入信息
    if (_server_item_info.prize_bouts == -1 or _item_use_info.bouts < _server_item_info.prize_bouts) then --有无限的使用次数或者还有剩余使用次数
        client_item_info.visable = true
    end

    --返回
    return client_item_info
end

--生成转盘的转动结果
function NewPurrfectPetsCalClass:GenBonusTurnaroundReslut(_player, _config)
    --初始化返回值
    local turnaround_result_idx = 1 --转盘结果索引
    local turnaround_result = 1 --转盘结果
    local collect_num = 0 --收集的数量

    --计算转盘返回值
    --生成权重表
    local weight_tab = {}
    for idx, item in ipairs(_config) do
        weight_tab[idx] = item.weight
    end
    --随机得到结果
    turnaround_result_idx = math.rand_weight(_player, weight_tab)
    turnaround_result = _config[turnaround_result_idx].result_id
    collect_num = _config[turnaround_result_idx].collect_num

    --返回
    return turnaround_result_idx, turnaround_result, collect_num
end

--根据转盘的结果获取行走的目的地
function NewPurrfectPetsCalClass:GetDestinPosByTurnaroundReslut(
    _ordinary_item_arr_config,
    _special_item_arr_config,
    _turnaround_result,
    _curr_pos)
    --初始化返回值
    local walk_end = true --本次行走是否已经到达终点（此时呆在原地，视为行走失败，并结束行走的整个流程开始结算）
    local destination_pos = _curr_pos

    --计算行走的位置
    for try_pos = _curr_pos + 1, #_ordinary_item_arr_config, 1 do
        if _ordinary_item_arr_config[try_pos].result_id == _turnaround_result then --找到了相同色块，行走成功
            walk_end = false
            destination_pos = try_pos
            break
        end
    end

    --返回
    return walk_end, destination_pos
end

--走进普通格子时，对格子的奖励进行消耗
function NewPurrfectPetsCalClass:ConsumMapPrizeWhenWalkIntoOridinary(
    _ordinary_item,
    _ordinary_item_use,
    _base_amount,
    _MAP_PRIZE_ENUM)
    --初始化返回值
    local receive_prize = nil --得到的奖励
    local change_ordinary_item = nil --普通格子产生的显示改变（由于奖励被消耗掉）

    --奖励进行消耗
    for prize_idx, prize in ipairs(_ordinary_item.prize_arr) do
        local prize_use = _ordinary_item_use[prize_idx]
        if prize.prize_bouts == -1 or prize_use.bouts < prize.prize_bouts then --找到可用的奖励
            --更新奖励的已经领取次数
            prize_use.bouts = prize_use.bouts + 1
            --设置获得的奖励
            local prize_val = prize.prize_val
            if prize.prize_type == _MAP_PRIZE_ENUM.CHIP then
                prize_val = math.floor(prize_val * _base_amount)
            end
            receive_prize = {prize_type = prize.prize_type, prize_val = prize_val}
            --检测是地图格子显示更新
            if prize.prize_bouts ~= -1 and prize_use.bouts == prize.prize_bouts then
                change_ordinary_item =
                    self:GetClinetMapOrdinaryItemInfo(_ordinary_item, _ordinary_item_use, _base_amount, _MAP_PRIZE_ENUM)
            end
            --退出循环
            break
        end
    end

    --返回
    return receive_prize, change_ordinary_item
end

--走进特殊格子时，对格子的奖励进行消耗
function NewPurrfectPetsCalClass:ConsumMapPrizeWhenWalkIntoSpecial(_special_item, _special_item_use)
    --初始化返回值
    local destination_pos = nil
    local change_special_item = nil --特殊格子产生的显示改变（由于奖励被消耗掉）

    --奖励进行消耗
    if _special_item.prize_bouts == -1 or _special_item_use.bouts < _special_item.prize_bouts then --找到可用的奖励
        --设置目的地
        destination_pos = _special_item.to_pos
        --更新奖励的已经领取次数
        _special_item_use.bouts = _special_item_use.bouts + 1
        --检测是地图格子显示更新
        if _special_item.prize_bouts ~= -1 and _special_item_use.bouts == _special_item.prize_bouts then
            change_special_item = self:GetClinetMapSpecialItemInfo(_special_item, _special_item_use)
        end
    end

    --返回
    return destination_pos, change_special_item
end

--玩家获取地图上格子的奖励
function NewPurrfectPetsCalClass:PlayerReceiveMapItemPrize(
    _save_data,
    _player,
    _receive_prize,
    _gen_wild_col_config,
    _MAP_PRIZE_ENUM)
    if _receive_prize then
        --变量缓存
        local prize_type = _receive_prize.prize_type --奖励类型
        local prize_val = _receive_prize.prize_val --奖励值
        local bonus_game_param = _save_data.bonus_game_param
        local reels_spin_param = bonus_game_param.reels_spin_param --多轴转动的参数

        --是否需要在_receive_prize中添加转轴的信息
        local need_add_reel_info = false
        --更具不同类型发奖励
        if prize_type == _MAP_PRIZE_ENUM.CHIP then
            bonus_game_param.bonus_win = bonus_game_param.bonus_win + prize_val
        elseif prize_type == _MAP_PRIZE_ENUM.ADD_REELS then
            need_add_reel_info = true

            for num = 1, prize_val, 1 do
                local add_reel = table.DeepCopy(reels_spin_param.reels[1])
                table.insert(reels_spin_param.reels, add_reel)
            end
        elseif prize_type == _MAP_PRIZE_ENUM.ADD_FREE_SPIN then
            reels_spin_param.reels_spin_bouts = reels_spin_param.reels_spin_bouts + prize_val
        elseif prize_type == _MAP_PRIZE_ENUM.ADD_WILD_REELS then
            need_add_reel_info = true

            --生成可以转变为wild的列数组
            local can_turn_wild_cols = {}
            for col = 2, reels_spin_param.reels[1].col_num do --第一列永远不为wild
                --检查是否已经含有该wil列
                local have_wild_col = false
                for _, wild_col in ipairs(reels_spin_param.reels[1].wild_cols) do
                    if col == wild_col then
                        have_wild_col = true
                        break
                    end
                end
                --添加可以随机的wild列
                if not have_wild_col then
                    table.insert(can_turn_wild_cols, col)
                end
            end

            --随机找出一列变为wild
            --生成权重表
            local weight_tab = {}
            for idx, col in ipairs(can_turn_wild_cols) do
                weight_tab[idx] = _gen_wild_col_config[col].weight
            end
            --随机得到结果
            local result_idx = math.rand_weight(_player, weight_tab)
            local add_wild_col = can_turn_wild_cols[result_idx]
            --将每个转轴的wild_cols都加上这个列
            for _, reel in ipairs(reels_spin_param.reels) do
                table.insert(reel.wild_cols, add_wild_col)
            end
        elseif prize_type == _MAP_PRIZE_ENUM.ADD_A_ROW then
            need_add_reel_info = true

            for _, reel in ipairs(reels_spin_param.reels) do
                reel.row_num = reel.row_num + 1
            end
        end

        --添加转轴信息
        if need_add_reel_info then
            local copy_reels = table.DeepCopy(reels_spin_param.reels)
            _receive_prize.reels = copy_reels
        end
    end
end

--获取bonus_game下次spin的是否结束走地图的预判结果
function NewPurrfectPetsCalClass:GetBonusNextSpinPredictArr(
    _ordinary_item_arr_config,
    _special_item_arr_config,
    _turnaround_config,
    _curr_pos,
    _TURNAROUND_RESULT_ENUM)
    --初始化返回值
    local next_spin_predict = {}

    --生成预判结果
    for idx, turnaround_result_info in ipairs(_turnaround_config) do
        --进行尝试行走
        local walk_end = false
        local turnaround_result = turnaround_result_info.result_id
        if turnaround_result ~= _TURNAROUND_RESULT_ENUM.COLLECT then
            walk_end =
                self:GetDestinPosByTurnaroundReslut(
                _ordinary_item_arr_config,
                _special_item_arr_config,
                turnaround_result,
                _curr_pos
            )
        end
        --写入预判结果
        next_spin_predict[idx] = walk_end
    end

    --返回
    return next_spin_predict
end

--生成收集个数的信息数组
function NewPurrfectPetsCalClass:GenCollectInfoArr(_save_data, _player, _game_name, _origin_result, _ITEM_ENUM)
    --初始化返回值
    local collect_info_arr = nil
    local gen_count = 0

    ----确定生成的收集物品的组数
    do
        --生成权重表
        local collect_arr_config = CommonCal.Calculate.get_config(_player, _game_name .. "GenCollectArrNumConfig")
        local weight_tab = {}
        for idx, info in ipairs(collect_arr_config) do
            weight_tab[idx] = info.probability
        end
        --生成随机结果
        local result_idx = math.rand_weight(_player, weight_tab)
        local collect_arr_num = collect_arr_config[result_idx].arr_num
        --插入收集位置信息
        if collect_arr_num > 0 then
            --生成已有的位置信息数组
            local all_pos_info_arr = {}
            for row, item_row in ipairs(_origin_result) do
                for col, item in ipairs(item_row) do
                    if item ~= _ITEM_ENUM.Bonus and item ~= _ITEM_ENUM.Wild and item ~= _ITEM_ENUM.Coin then
                        table.insert(all_pos_info_arr, {row = row, col = col})
                    end
                end
            end
            --确定需要生成的收集物品所在的位置
            collect_info_arr = {}
            for collect_arr_idx = 1, collect_arr_num, 1 do
                --获取生成的位置信息
                if #all_pos_info_arr == 0 then --没有空位时，不进行继续生成
                    break
                end
                local gen_pos_idx = math.random_ext(_player, #all_pos_info_arr) --生成位置信息的索引
                local gen_pos_info = all_pos_info_arr[gen_pos_idx] --生成的位置信息
                table.remove(all_pos_info_arr, gen_pos_idx) --已经生成，则从数组中删除该信息
                --更新收集信息数组
                local gen_row = gen_pos_info.row
                local gen_col = gen_pos_info.col
                if not collect_info_arr[gen_row] then --行数组检查
                    collect_info_arr[gen_row] = {}
                end
                collect_info_arr[gen_row][gen_col] = {item_id = _origin_result[gen_row][gen_col], collect_num = 0}
            end
        end
    end
    ----确定每组收集的物品个数
    do
        if collect_info_arr then --有收集物品时，才生成个数
            --生成权重列表
            local collect_num_config =
                CommonCal.Calculate.get_config(_player, _game_name .. "GenCollectNumPerArrConfig")
            local weight_tab = {}
            for idx, info in ipairs(collect_num_config) do
                weight_tab[idx] = info.probability
            end
            --生成随机结果
            for row, collect_info_row in pairs(collect_info_arr) do
                for col, _ in pairs(collect_info_row) do
                    --得到收集个数
                    local result_idx = math.rand_weight(_player, weight_tab)
                    local collect_num = collect_num_config[result_idx].collect_num
                    --更新收集信息数组
                    collect_info_arr[row][col].collect_num = collect_num
                    --统计总共生成的个数
                    gen_count = gen_count + collect_num
                end
            end
        end
    end

    --返回
    return collect_info_arr, gen_count
end

--生成新的收集页信息
function NewPurrfectPetsCalClass:GenNewCollectPageOpenArr(_player, _collect_prize_page_config)
    --初始化返回值
    local collect_page_open_arr = {}

    --根据配置填写信息
    for page_idx, page_prize_config in ipairs(_collect_prize_page_config) do
        --页初始化
        collect_page_open_arr[page_idx] = {}
        --每次开启小盒子使用的收集物品的平均价值之和
        collect_page_open_arr[page_idx].all_amount_per_collect = 0
        --小礼盒初始化
        collect_page_open_arr[page_idx].little_box_open_info_arr = {}
        local little_box_open_info_arr = collect_page_open_arr[page_idx].little_box_open_info_arr
        for box_id, _ in ipairs(page_prize_config.little_box_info_arr) do
            little_box_open_info_arr[box_id] = {
                box_id = box_id,
                opened = false,
                val = 0 --开启盒子真正拿到的个数
            }
        end
        --大礼盒初始化
        collect_page_open_arr[page_idx].big_box_open_info = {
            can_open = false,
            opened = false
        }
    end
    --小礼盒的位置打乱
    for page_idx, collect_page_open in ipairs(collect_page_open_arr) do
        local little_box_open_info_arr = collect_page_open.little_box_open_info_arr
        local little_box_open_num = #little_box_open_info_arr --每页小盒子数量
        local swap_num = 2 * little_box_open_num --交换次数
        for swap_idx = 1, swap_num, 1 do --开始交换
            local box_id_a = math.random_ext(_player, little_box_open_num)
            local box_id_b = math.random_ext(_player, little_box_open_num)
            if box_id_a ~= box_id_b then
                little_box_open_info_arr[box_id_b], little_box_open_info_arr[box_id_a] =
                    little_box_open_info_arr[box_id_a],
                    little_box_open_info_arr[box_id_b]
            end
        end
    end

    --返回
    return collect_page_open_arr
end

--获取客户端需要的收集页信息
function NewPurrfectPetsCalClass:GetClientCollectPageArr(_collect_prize_page_config, _collect_page_open_arr)
    --初始化返回值
    local collect_page_arr_total_info = {}

    --填入奖励信息
    for page_idx, collect_page_open in ipairs(_collect_page_open_arr) do
        --页信息生成
        collect_page_arr_total_info[page_idx] = {}
        local collect_page_total_info = collect_page_arr_total_info[page_idx]
        --开启每个box需要消耗的收集数量
        collect_page_total_info.need_collect_num = _collect_prize_page_config[page_idx].need_collect_num
        --小盒子信息
        collect_page_total_info.little_box_info_arr = {} --小盒子信息数组
        local little_box_config_info_arr = _collect_prize_page_config[page_idx].little_box_info_arr
        for box_idx, little_box_open_info in ipairs(collect_page_open.little_box_open_info_arr) do --遍历开启信息
            --读取盒子的开启信息
            local box_id = little_box_open_info.box_id
            local opened = little_box_open_info.opened
            --写入客户端需要的信息
            local prize_info = nil
            if opened then
                prize_info = {
                    prize_type = little_box_config_info_arr[box_id].prize_info.prize_type,
                    prize_val = little_box_open_info.val
                }
            end
            collect_page_total_info.little_box_info_arr[box_idx] = {
                opened = opened,
                prize_info = prize_info
            }
        end
        --大盒子信息
        collect_page_total_info.big_box_info = {
            can_open = collect_page_open.big_box_open_info.can_open,
            opened = collect_page_open.big_box_open_info.opened,
            prize_info = _collect_prize_page_config[page_idx].big_box_info.prize_info
        }
    end

    --返回
    return collect_page_arr_total_info
end

--开启收集礼盒
function NewPurrfectPetsCalClass:OpenCollectBox(
    _save_data,
    _player,
    _game_name,
    _collect_prize_page_config,
    _amount_per_collect,
    _is_open_big_box,
    _page_idx,
    _arr_idx,
    _COLLECT_PRIZE_ENUM)
    --初始化返回值
    local success = false --开启是否成功
    local prize_info = nil --开启的奖励
    local change_collect_page_arr = {} --开启后，对奖品礼盒产生影响
    local amount_the_open_collect = 0 --开启盒子的使用的收集物品的价值

    --开礼盒逻辑
    local collect_param = _save_data.collect_param
    local collect_page_open_arr = collect_param.collect_page_open_arr --收集页面数组
    local collect_page_open = collect_page_open_arr[_page_idx]
    local collect_page_config = _collect_prize_page_config[_page_idx]
    if _is_open_big_box then --开启大盒子
        --尝试开启
        local big_box_open_info = collect_page_open.big_box_open_info
        if big_box_open_info.can_open then --开启成功
            --奖励信息赋值
            success = true
            prize_info = collect_page_config.big_box_info.prize_info
            amount_the_open_collect =
                math.floor((collect_page_open.all_amount_per_collect) / #collect_page_open.little_box_open_info_arr)
            --大盒子的状态改变
            big_box_open_info.can_open = false --开过后就不能再开了
            big_box_open_info.opened = true --记录开启记录
            --开启导致礼盒的改变
            local all_big_box_opened = true --是否所有的大盒子都开启了
            for _, for_collect_page_open in ipairs(collect_page_open_arr) do
                if not for_collect_page_open.big_box_open_info.opened then
                    all_big_box_opened = false
                    break
                end
            end
            if all_big_box_opened then --开启的为最后一页大礼盒，则整个页面需要重新生成
                --生成新的收集礼品页面
                collect_param.curr_page = 1
                local new_collect_page_open_arr = self:GenNewCollectPageOpenArr(_player, _collect_prize_page_config)
                collect_param.collect_page_open_arr = new_collect_page_open_arr
                --填充改变信息
                change_collect_page_arr =
                    self:GetClientCollectPageArr(_collect_prize_page_config, new_collect_page_open_arr)
            else --开启不为最后一个大礼盒，则仅大礼盒的状态改变
                collect_param.curr_page = collect_param.curr_page + 1
                change_collect_page_arr = {
                    [_page_idx] = {
                        big_box_info = {
                            can_open = big_box_open_info.can_open,
                            opened = big_box_open_info.opened,
                            prize_info = prize_info
                        }
                    }
                }
            end
        end
    else --开启小盒子
        --尝试开启
        local little_box_open_info = collect_page_open.little_box_open_info_arr[_arr_idx]
        local need_collect_num = collect_page_config.need_collect_num
        if ((not little_box_open_info.opened) and collect_param.collect_num >= need_collect_num) then
            --统计每次开盒子的收集物品价值之和
            collect_page_open.all_amount_per_collect = collect_page_open.all_amount_per_collect + _amount_per_collect
            --小盒子奖励信息
            local box_id = little_box_open_info.box_id
            local little_box_config_info = collect_page_config.little_box_info_arr[box_id]
            ----小礼盒状态改变
            little_box_open_info.opened = true --盒子打开状态设置
            local little_box_config_prize_info = little_box_config_info.prize_info
            if little_box_config_prize_info.prize_type == _COLLECT_PRIZE_ENUM.CHIP then --筹码奖励盒子计算筹码值
                little_box_open_info.val = math.floor(_amount_per_collect * little_box_config_prize_info.prize_val)
            elseif little_box_config_prize_info.prize_type == _COLLECT_PRIZE_ENUM.COIN_SPIN then
                little_box_open_info.val = little_box_config_prize_info.prize_val
                amount_the_open_collect = math.floor(_amount_per_collect)
            else
                little_box_open_info.val = little_box_config_prize_info.prize_val
            end
            ----奖励信息赋值
            success = true
            prize_info = {
                prize_type = little_box_config_prize_info.prize_type,
                prize_val = little_box_open_info.val
            }
            collect_param.collect_num = collect_param.collect_num - need_collect_num --消耗收集元素
            ----开启导致礼盒的改变
            --检测本页的小礼盒是否全部，导致大礼盒可以打开
            local change_big_box_info = nil --改变的大礼盒信息
            local all_little_box_opened = true
            for _, box in ipairs(collect_page_open.little_box_open_info_arr) do
                if (not box.opened) then
                    all_little_box_opened = false
                    break
                end
            end
            if all_little_box_opened then --小礼盒都打开，则本页大礼盒也可以打开
                --设置大礼盒为可以打开
                collect_page_open.big_box_open_info.can_open = true
                --赋值改变的大的礼盒信息
                change_big_box_info = {
                    can_open = collect_page_open.big_box_open_info.can_open,
                    opened = collect_page_open.big_box_open_info.opened,
                    prize_info = collect_page_config.big_box_info.prize_info
                }
            end
            --填入改变信息
            change_collect_page_arr = {
                [_page_idx] = {
                    little_box_info_arr = {
                        [_arr_idx] = {
                            opened = little_box_open_info.opened,
                            prize_info = prize_info
                        }
                    },
                    big_box_info = change_big_box_info
                }
            }
        end
    end

    --返回
    return success, prize_info, change_collect_page_arr, amount_the_open_collect
end

--设置多轴转动的参数在进入之前
function NewPurrfectPetsCalClass:SetReelsSpinParamBeforeEnter(
    _save_data,
    _player_game_info,
    _reels_spin_bouts,
    _reels,
    _trigger_by_collect,
    _trigger_by_big_box,
    _point_amount_when_spin,
    _parameters)
    --取出变量
    local game_type = _parameters.game_type
    local player_game_status = _parameters.player_game_status
    local player = _parameters.player
    local player_game_info = _parameters.player_game_info
    local session = _parameters.session
    local task = session.task
    local free_spin_param = _save_data.free_spin_param

    --游戏内部变量设置
    _save_data.reels_spin_bouts = _reels_spin_bouts --设置多轴转动的次数
    _save_data.reels_spin_param.reels = _reels --转轴信息
    _save_data.reels_spin_param.trigger_by_collect = _trigger_by_collect --是否由收集触发
    _save_data.reels_spin_param.trigger_by_big_box = _trigger_by_big_box --是否由收集的大盒子触发
    _save_data.reels_spin_param.point_amount_when_spin = _point_amount_when_spin --制定spin的金额

    --外围变量
    GameStatusCal.Calculate.AddGameStatus(
        player_game_status,
        GameStatusDefine.AllTypes.FreeSpinGame,
        _reels_spin_bouts,
        3,
        SlotsGameCal.Calculate.GetBetAmount(player_game_info)
    )
end

--获取客户端的jackpot参数
function NewPurrfectPetsCalClass:GetJakcpotPrizePoolToClient(_prize_pool, _COIN_PRIZE_ENUM)
    --初始化返回值
    local prize_pool_cliect = {}

    --处理返回值
    for prize_type = _COIN_PRIZE_ENUM.JACKPOT_GRAND, _COIN_PRIZE_ENUM.JACKPOT_MINI, 1 do
        local jackpot_prize = table.DeepCopy(_prize_pool[prize_type])
        jackpot_prize.start_point = math.floor(jackpot_prize.start_point * 10000) --点数做放大，兼容小数点
        prize_pool_cliect[prize_type] = jackpot_prize
    end

    --返回
    return prize_pool_cliect
end
