require "Common/SlotsGameCal" --旧的接口

VampireRoseCalClass = {}
VampireRoseCalClass.__index = VampireRoseCalClass

--检查保存数据的完整性
function VampireRoseCalClass:GetSaveData(_player, _player_game_info, _game_name, _SPIN_ENUM, _PRIZE_TYPE_ENUM)
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

    --free_spin信息
    if not save_data.free_spin_param then
        save_data.free_spin_param = {
            bouts = 0, --剩余次数
            total_amount = 0, --指定的金额
            level = 0, --free_spin的等级
            multiple_times = 1, --最后赢钱的加倍数
            base_total_win_chip = 0 --free_spin基础的总共赢钱
        }
    end

    --jackpot信息
    if not save_data.jackpot_param_v2 then
        --取出变量
        local jackpot_config = CommonCal.Calculate.get_config(_player, _game_name .. "JackpotConfig")

        --初始化
        save_data.jackpot_param_v2 = {}
        --设置参数
        CommonCal.Calculate.InitJackpotParam(save_data.jackpot_param_v2, jackpot_config)
    end

    --spin_bonus信息
    if not save_data.spin_bonus_param then
        save_data.spin_bonus_param = {
            bouts = 0, --触发的次数
            enter_info = {}, --进入时的信息
            --可选择的spin的次数
            select_param = {
                total_amount = 0, --进入时的下注额度
                free_spin_bouts_level_arr = {0, 0, 0} --选择的free_spin等级对应的free_spin的次数
            }
        }
    end

    ----返回
    return save_data
end

--保存sava_data
function VampireRoseCalClass:RecordSaveData(_player_game_info, _save_data)
    --不连续table进行转化处理
    --金币金额信息
    -- _save_data.coin_info_arr = self:ArrToList_2(_save_data.coin_info_arr)
end

--数组转化为列表
function VampireRoseCalClass:ArrToList_1(_arr)
    --初始化返回值
    local list = {}

    --填入数据
    for row, item in pairs(_arr) do
        table.insert(
            list,
            {
                pos = {row},
                data = item
            }
        )
    end

    --返回
    return list
end

--数组转化为列表
function VampireRoseCalClass:ArrToList_2(_arr)
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
function VampireRoseCalClass:ListToArr_1(_list)
    --初始化返回值
    local tab = {}

    --填入数据
    for _, item in ipairs(_list) do
        --位置取出
        local pos = item.pos

        --写入数据
        tab[pos[1]] = item.data
    end

    --返回
    return tab
end

--列表转化为数组
function VampireRoseCalClass:ListToArr_2(_list)
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
function VampireRoseCalClass:RandSwapItemInTab(_player, _tab, _swap_count)
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
function VampireRoseCalClass:GetItemCountInItemArr(_item_arr, _item_type)
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
function VampireRoseCalClass:GetRandomItemByWeightTab(_player, _item_with_weight_tab)
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
function VampireRoseCalClass:FilterPointItemTypeArr(_orign_result, _point_item_type)
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
function VampireRoseCalClass:GenLinePrize(
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
        local slots_spin_list = {
            [1] = {
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
        }
        --spin转轴结果
        table.insert(
            formation_list,
            {
                slots_spin_list = slots_spin_list,
                id = reel_info.id
            }
        )
        --spin连线
        table.insert(all_prize_list, prize_items)
    end

    --返回
    return slots_win_chip, formation_list, all_prize_list
end

--进入选择spin类型的小游戏前设置参数
function VampireRoseCalClass:SetSpinBonusBeforEnter(
    _save_data,
    _bonus_item_count,
    _scatter_config,
    _total_amount,
    _enter_info)
    local spin_bonus_param = _save_data.spin_bonus_param
    local select_param = spin_bonus_param.select_param
    --bonus数据赋值
    spin_bonus_param.bouts = spin_bonus_param.bouts + 1 --游戏触发的次数
    spin_bonus_param.enter_info = _enter_info --设置进入时的信息
    select_param.total_amount = _total_amount --触发时候的金额
    select_param.free_spin_bouts_level_arr =
        (_scatter_config[_bonus_item_count] or _scatter_config[#_scatter_config]).free_spin_bouts_level_arr --具体的选项
end

--设置free_spin的参数在进入之前
function VampireRoseCalClass:SetFreeSpinBeforeEnter(_save_data, _total_amount, _spin_bouts, _level, _parameters)
    --取出变量
    local game_type = _parameters.game_type
    local player_game_status = _parameters.player_game_status
    local player = _parameters.player
    local player_game_info = _parameters.player_game_info
    local session = _parameters.session
    local task = session.task
    local free_spin_param = _save_data.free_spin_param

    --缓存赋值
    free_spin_param.bouts = _spin_bouts --剩余次数
    free_spin_param.total_amount = _total_amount --指定的金额
    free_spin_param.level = _level --free_spin的等级
    free_spin_param.multiple_times = 1 --最后赢钱的加倍数
    free_spin_param.base_total_win_chip = 0 --free_spin基础的总共赢钱

    --外围变量
    GameStatusCal.Calculate.AddGameStatus(
        player_game_status,
        GameStatusDefine.AllTypes.FreeSpinGame,
        _spin_bouts,
        1,
        SlotsGameCal.Calculate.GetBetAmount(player_game_info)
    )
end

--获取下一步游戏的走向
function VampireRoseCalClass:GetGameChangeToStepInControl(_save_data, _SPIN_ENUM, _BONUS_ENUM)
    --初始化返回值
    local change_to_spin_type = nil
    local change_to_bonus_type = nil

    --根据当前的状态，确定游戏的走向
    if _save_data.curr_spin_type == _SPIN_ENUM.BASE_SPIN then
        if _save_data.spin_bonus_param.bouts > 0 then --选择spin的bonus
            change_to_bonus_type = _BONUS_ENUM.SPIN_BONUS
        elseif _save_data.free_spin_param.bouts > 0 then --free_spin
            change_to_spin_type = _SPIN_ENUM.FREE_SPIN
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
function VampireRoseCalClass:MoveTotGameChangeToStepInControl(
    _save_data,
    _pre_action_list,
    _player,
    _game_name,
    _player_game_info,
    _change_to_spin_type,
    _change_to_bonus_type,
    _SPIN_ENUM,
    _BONUS_ENUM,
    _PRIZE_TYPE_ENUM)
    --根据参数，移动到下个步骤
    if _change_to_spin_type then
        --游戏内的变量设置
        _save_data.curr_spin_type = _change_to_spin_type --更改当前的spin类型
        self:UpdateCurrReelInfoArr(_save_data, _SPIN_ENUM) --更新转轴信息

        --外围通用变量设置
        local spin_bouts = -1 --切换到的spin的次数
        if _change_to_spin_type == _SPIN_ENUM.BASE_SPIN then
        elseif _change_to_spin_type == _SPIN_ENUM.FREE_SPIN then
            --spin次数记录
            spin_bouts = _save_data.free_spin_param.bouts
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
        if _change_to_bonus_type == _BONUS_ENUM.SPIN_BONUS then
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
function VampireRoseCalClass:UpdateCurrReelInfoArr(_save_data, _SPIN_ENUM)
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
    elseif curr_spin_type == _SPIN_ENUM.FREE_SPIN then
        fomation_id_start = 1
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
