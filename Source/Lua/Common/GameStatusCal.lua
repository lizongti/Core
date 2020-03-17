module("GameStatusCal", package.seeall)
require "Common/GameStatusDefine"

Calculate = {
    ---------兼容旧的数据
    InitGamStatus = function(player_game_status)
        if (#player_game_status.history_data.info > 0) then
            if (player_game_status.history_data.info[1].total_win_chip == nil) then
                player_game_status.history_data = {}
                player_game_status.history_data.info = {}
                player_game_status.history_swap = {}
            end
        end

        for k, index in ipairs(GameStatusDefine.SortedPriorityLevel) do
            if (player_game_status.history_swap[index] ~= nil) then
                if (#player_game_status.history_swap[index] > 0) then
                    if (player_game_status.history_swap[index][1].total_win_chip == nil) then
                        player_game_status.history_data = {}
                        player_game_status.history_data.info = {}
                        player_game_status.history_swap = {}
                    end
                end
            end
        end
    end,
    GameStatusCount = function(player_game_status)
        return #player_game_status.history_data.info
    end,
    AddBaseGameStatus = function(player_game_status, bet_amount)
        table.insert(
            player_game_status.history_data.info,
            {
                status_id = GameStatusDefine.AllTypes.BaseSpinGame,
                bet_amount = bet_amount,
                total_win_chip = 0,
                process = 0,
                total_process = 1
            }
        )
    end,
    AddStatusImmediately = function(player_game_status, status_id, total_process, bet_amount)
        ----运行次数加1
        Calculate.UpdateGameStatus(player_game_status, 1, 0)

        table.insert(
            player_game_status.history_data.info,
            {
                status_id = status_id,
                bet_amount = bet_amount,
                total_win_chip = 0,
                process = 0,
                total_process = total_process
            }
        )
    end,
    ----获取当前状态
    GetSelGameStatusPos = function(player_game_status, status_id)
        for index = #player_game_status.history_data.info, 1, -1 do
            local his_info = player_game_status.history_data.info[index]
            if (his_info.status_id == status_id) then
                return index
            end
        end
        return 0
    end,
    InsertGameStatus = function(player_game_status, sel_status_id, status_id, total_process, action_type, bet_amount)
        if (action_type == nil) then
            action_type = 0 ---即使有相同的状态也将该状态放到队列尾
        end

        if (action_type == 1) then
            for pos = #player_game_status.history_data.info, 1, -1 do
                if (status_id == player_game_status.history_data.info[pos].status_id) then
                    player_game_status.history_data.info[pos].total_process =
                        player_game_status.history_data.info[pos].total_process + total_process
                    return
                end
            end
        end

        local sel_pos = Calculate.GetSelGameStatusPos(player_game_status, sel_status_id)

        if (sel_pos > 0) then
            table.insert(
                player_game_status.history_data.info,
                sel_pos,
                {
                    status_id = status_id,
                    bet_amount = bet_amount,
                    total_win_chip = 0,
                    process = 0,
                    total_process = total_process
                }
            )
        else
            Calculate.AddGameStatus(player_game_status, status_id, total_process, action_type, bet_amount)
        end
    end,
    AddGameStatus = function(player_game_status, status_id, total_process, action_type, bet_amount, priority)
        if total_process == 0 then
            return
        end
        if (action_type == nil) then
            -- 0:由自己触发的累加，不是自己触发的不累加(类似respin)
            -- 1：累加（类似freespin)
            -- 2: total_process覆盖已有的
            -- 3: 无论如何，都会产生新的添加到队列
            action_type = 0
        end

        if (priority == nil) then
            priority = CommonCal.Calculate.GetPriorityLevel(player_game_status.game_type, status_id)
        else
            CommonCal.Calculate.SetPriorityLevel(player_game_status.game_type, status_id, priority)
        end
        if (player_game_status.history_swap[priority] == nil) then
            player_game_status.history_swap[priority] = {}
        end
        if (action_type == 0 or action_type == 3) then
            if (#player_game_status.history_swap[priority] == 0) then
                table.insert(
                    player_game_status.history_swap[priority],
                    {
                        status_id = status_id,
                        bet_amount = bet_amount,
                        total_win_chip = 0,
                        process = 0,
                        total_process = total_process,
                        action_type = action_type,
                        is_new = true
                    }
                )
            else
                local end_pos = #player_game_status.history_swap[priority]
                local end_status_info = player_game_status.history_swap[priority][end_pos]
                if (end_status_info.status_id ~= status_id or action_type == 3) then
                    table.insert(
                        player_game_status.history_swap[priority],
                        {
                            status_id = status_id,
                            bet_amount = bet_amount,
                            total_win_chip = 0,
                            process = 0,
                            total_process = total_process,
                            action_type = action_type,
                            is_new = true
                        }
                    )
                else
                    end_status_info.total_process = end_status_info.total_process + total_process
                end
            end
        else
            local is_exist = false
            for k, status_info in pairs(player_game_status.history_swap[priority]) do
                if (status_info.status_id == status_id) then
                    if (action_type == 2) then
                        status_info.total_process = total_process
                    else
                        status_info.total_process = status_info.total_process + total_process
                    end
                    is_exist = true
                end
            end
            if (not is_exist) then
                table.insert(
                    player_game_status.history_swap[priority],
                    {
                        status_id = status_id,
                        bet_amount = bet_amount,
                        total_win_chip = 0,
                        process = 0,
                        total_process = total_process,
                        action_type = action_type,
                        is_new = true
                    }
                )
            end
        end
    end,
    FlushGameStatus = function(player_game_status)
        for k, index in ipairs(GameStatusDefine.GtSortedPriorityLevel) do
            if (player_game_status.history_swap[index] ~= nil) then
                for k, status_info in pairs(player_game_status.history_swap[index]) do
                    status_info.is_new = false
                end
            end
        end

        ---是否需要取出新的节点
        local end_pos = #player_game_status.history_data.info
        local end_status_info = player_game_status.history_data.info[end_pos]

        ---取出要执行的一个节点
        local swap_priority = 0
        local swap_pos = 0

        for k, index in ipairs(GameStatusDefine.GtSortedPriorityLevel) do
            if (player_game_status.history_swap[index] ~= nil) then
                local tmp_pos = #player_game_status.history_swap[index]
                if (tmp_pos > 0) then
                    swap_pos = tmp_pos
                    swap_priority = index
                    break
                end
            end
        end

        if (swap_pos == 0 or swap_priority == 0) then
            return
        end

        local data_info = player_game_status.history_swap[swap_priority][swap_pos]

        ----只允许优先级比当前的高才可以马上加入运行队列
        local end_priority =
            CommonCal.Calculate.GetPriorityLevel(player_game_status.game_type, end_status_info.status_id)
        if end_status_info.status_id ~= data_info.status_id then
            if end_priority >= swap_priority then
                if (end_status_info.process < end_status_info.total_process) then
                    return
                end
            end
        end

        ---加入执行队列
        if (data_info.action_type == 0 or data_info.action_type == 3) then
            if (end_status_info.status_id ~= data_info.status_id) or data_info.action_type == 3 then
                table.insert(
                    player_game_status.history_data.info,
                    {
                        status_id = data_info.status_id,
                        bet_amount = data_info.bet_amount,
                        total_win_chip = data_info.total_win_chip,
                        process = data_info.process,
                        total_process = data_info.total_process,
                        action_type = data_info.action_type
                    }
                )
            else
                end_status_info.process = end_status_info.process + data_info.process
                end_status_info.total_process = end_status_info.total_process + data_info.total_process
            end
        elseif (data_info.action_type == 1) then
            local is_exist = false
            for pos = #player_game_status.history_data.info, 1, -1 do
                local his_info = player_game_status.history_data.info[pos]
                if
                    ((his_info.status_id == data_info.status_id) and
                        ((his_info.total_process + data_info.total_process) >= (his_info.process + data_info.process)))
                 then
                    ----total_win_chip在UpdateGameStatus中已经累加了
                    his_info.process = his_info.process + data_info.process
                    his_info.total_process = his_info.total_process + data_info.total_process
                    is_exist = true
                    break
                end
            end
            if (not is_exist) then
                table.insert(
                    player_game_status.history_data.info,
                    {
                        status_id = data_info.status_id,
                        bet_amount = data_info.bet_amount,
                        total_win_chip = data_info.total_win_chip,
                        process = data_info.process,
                        total_process = data_info.total_process
                    }
                )
            end
        elseif (data_info.action_type == 2) then
            local is_exist = false
            for pos = #player_game_status.history_data.info, 1, -1 do
                local his_info = player_game_status.history_data.info[pos]
                if
                    ((his_info.status_id == data_info.status_id) and
                        ((his_info.total_process + data_info.total_process) >= (his_info.process + data_info.process)))
                 then
                    ----total_win_chip在UpdateGameStatus中已经累加了
                    his_info.process = data_info.process
                    his_info.total_process = data_info.total_process
                    is_exist = true
                    break
                end
            end
            if (not is_exist) then
                table.insert(
                    player_game_status.history_data.info,
                    {
                        status_id = data_info.status_id,
                        bet_amount = data_info.bet_amount,
                        total_win_chip = data_info.total_win_chip,
                        process = data_info.process,
                        total_process = data_info.total_process
                    }
                )
            end
        end

        table.remove(player_game_status.history_swap[swap_priority], swap_pos)

        Calculate.ResortGamestatus(player_game_status)
    end,
    ---获取得到的总free spin次数
    GetTotalRespinNum = function(player_game_status)
        for pos = 1, #player_game_status.history_data.info, 1 do
            local history_info = player_game_status.history_data.info[pos]
            if (history_info.status_id == GameStatusDefine.AllTypes.ReSpinGame) then
                return history_info.total_process
            end
        end
        return 0
    end,
    ---获取得到的总free spin次数
    GetTotalFreeSpinNum = function(player_game_status)
        local total_free_spin_bouts = 0
        for pos = 1, #player_game_status.history_data.info, 1 do
            local history_info = player_game_status.history_data.info[pos]
            if (history_info.status_id == GameStatusDefine.AllTypes.FreeSpinGame) then
                total_free_spin_bouts = total_free_spin_bouts + history_info.total_process
            end
        end

        for k, index in ipairs(GameStatusDefine.SortedPriorityLevel) do
            if (player_game_status.history_swap[index] ~= nil) then
                for k, data_info in ipairs(player_game_status.history_swap[index]) do
                    if (data_info.status_id == GameStatusDefine.AllTypes.FreeSpinGame) then
                        total_free_spin_bouts = total_free_spin_bouts + data_info.total_process
                    end
                end
            end
        end

        return total_free_spin_bouts
    end,
    GetNewFreeSpinBouts = function(player_game_status)
        local free_spin_bouts = 0
        for k, index in ipairs(GameStatusDefine.SortedPriorityLevel) do
            if (player_game_status.history_swap[index] ~= nil) then
                for k, data_info in ipairs(player_game_status.history_swap[index]) do
                    if data_info.is_new and data_info.status_id == GameStatusDefine.AllTypes.FreeSpinGame then
                        free_spin_bouts = free_spin_bouts + data_info.total_process
                    end
                end
            end
        end
        return free_spin_bouts
    end,
    ----获取剩余的free spin次数
    GetFreeSpinBouts = function(player_game_status)
        local free_spin_bouts = 0

        for pos = 1, #player_game_status.history_data.info, 1 do
            local history_info = player_game_status.history_data.info[pos]
            if (history_info.status_id == GameStatusDefine.AllTypes.FreeSpinGame) then
                local remain_free_spin_bouts = history_info.total_process - history_info.process
                free_spin_bouts = free_spin_bouts + remain_free_spin_bouts
            end
        end

        local cur_status = Calculate.GetGameStatus(player_game_status)
        if (cur_status == GameStatusDefine.AllTypes.FreeSpinGame) then
            return free_spin_bouts - 1 ----最后一次还没有更新次数
        end

        return free_spin_bouts
    end,
    ----获取剩余的free spin次数
    GetFreeSpinBoutsInEnd = function(player_game_status)
        local free_spin_bouts = 0

        for pos = 1, #player_game_status.history_data.info, 1 do
            local history_info = player_game_status.history_data.info[pos]
            if (history_info.status_id == GameStatusDefine.AllTypes.FreeSpinGame) then
                local remain_free_spin_bouts = history_info.total_process - history_info.process
                free_spin_bouts = free_spin_bouts + remain_free_spin_bouts
            end
        end

        return free_spin_bouts
    end,
    ----获取free spin的总奖励
    GetTotalFreeSpinWin = function(player_game_status)
        local total_free_spin_win = 0
        for pos = 1, #player_game_status.history_data.info, 1 do
            local history_info = player_game_status.history_data.info[pos]
            if (history_info.status_id == GameStatusDefine.AllTypes.FreeSpinGame) then
                total_free_spin_win = total_free_spin_win + history_info.total_win_chip
            end
        end
        return total_free_spin_win
    end,
    ----更新当前状态
    ----更新当前状态
    UpdateGameStatus = function(player_game_status, trigger_times, total_win_chip, priority)
        if (priority == nil) then
            priority = GameStatusDefine.SortedPriorityLevel[1]
        end

        local cur_status_info, cur_pos = Calculate.GetGameStatusInfo(player_game_status)

        if (cur_status_info == nil) then
            return
        end

        cur_status_info.process = cur_status_info.process + trigger_times

        for index = 1, cur_pos, 1 do
            local his_info = player_game_status.history_data.info[index]
            his_info.total_win_chip = his_info.total_win_chip + total_win_chip
            his_info.cur_win_chip = total_win_chip
        end

        return false
    end,
    ----清空历史状态
    ClearGameStatus = function(player_game_status)
        player_game_status.history_data = {}
        player_game_status.history_data.info = {}
    end,
    ----获取当前状态的触发状态
    GetParentStatus = function(player_game_status, status_id)
        -- body
        for index = #player_game_status.history_data.info, 1, -1 do
            local his_info = player_game_status.history_data.info[index]
            if (his_info.process > 0 and his_info.status_id ~= status_id) then
                return his_info.status_id
            end
        end
        return 0
    end,
    ---获取所有的状态列表
    GetAllGameStatus = function(player_game_status)
        return player_game_status.history_data.info
    end,
    -- 获取当前状态
    GetGameStatusInfo = function(player_game_status)
        for index = #player_game_status.history_data.info, 1, -1 do
            local his_info = player_game_status.history_data.info[index]
            if (his_info.process < his_info.total_process) then
                return his_info, index
            end
        end

        return nil, 0
    end,
    --获取Spin状态的信息(不包含BonusGame)
    GetSpinStatusInfo = function(player_game_status)
        for index = #player_game_status.history_data.info, 1, -1 do
            local his_info = player_game_status.history_data.info[index]
            if
                (his_info.status_id ~= GameStatusDefine.AllTypes.BonusSpinGame) and
                    (his_info.process < his_info.total_process)
             then
                return his_info, index
            end
        end

        return nil, 0
    end,
    ----获取当前状态
    GetGameStatus = function(player_game_status)
        for index = #player_game_status.history_data.info, 1, -1 do
            local his_info = player_game_status.history_data.info[index]
            if (his_info.process < his_info.total_process) then
                return his_info.status_id, index
            end
        end
        return 0, 0
    end,
    ResortGamestatus = function(player_game_status)
        local new_queue = {}
        --LOG(RUN, INFO).Format("[GameStatusCal][ResortGamestatus] player %s, GameStatusDefine.SortedPriorityLevel is:%s", player_game_status.player_id, json.encode(GameStatusDefine.SortedPriorityLevel))
        for k, index in ipairs(GameStatusDefine.SortedPriorityLevel) do
            for pos = 1, #player_game_status.history_data.info, 1 do
                local status_info = player_game_status.history_data.info[pos]
                local priority_value =
                    CommonCal.Calculate.GetPriorityLevel(player_game_status.game_type, status_info.status_id)
                if (priority_value == index) then
                    ---将相邻的两个状态合并
                    local new_queue_len = #new_queue
                    if
                        (new_queue_len > 0 and new_queue[new_queue_len].status_id == status_info.status_id) and
                            status_info.action_type ~= 3
                     then
                        new_queue[new_queue_len].process = new_queue[new_queue_len].process + status_info.process
                        new_queue[new_queue_len].total_process =
                            new_queue[new_queue_len].total_process + status_info.total_process
                        new_queue[new_queue_len].total_win_chip =
                            new_queue[new_queue_len].total_win_chip + status_info.total_win_chip
                    else
                        table.insert(new_queue, table.DeepCopy(status_info))
                    end
                end
            end
        end

        player_game_status.history_data.info = new_queue
    end,
    ----清除完成的状态
    ClearFinishedStatus = function(player_game_status)
        local status_id_list = {}
        for pos = #player_game_status.history_data.info, 1, -1 do
            local status_id = player_game_status.history_data.info[pos].status_id
            local is_exist = false
            for _, status_info in ipairs(status_id_list) do
                if (status_info.status_id == status_id) then
                    is_exist = true
                    break
                end
            end
            if (not is_exist) then
                table.insert(
                    status_id_list,
                    {
                        status_id = status_id
                    }
                )
            end
        end

        for _, status_info in ipairs(status_id_list) do
            Calculate.FinishedInfo(player_game_status, status_info.status_id, true)
        end
    end,
    ----返回完成状态的奖励
    GetFinishedAward = function(player_game_status, status_id)
        local award_info_list = GameStatusCal.Calculate.GetFinishedStatus(player_game_status)
        if (#award_info_list > 0) then
            for _, award_info in ipairs(award_info_list) do
                if (award_info.status_id == status_id) then
                    return award_info.collect_info.total_win_chip
                end
            end
        end
        return nil
    end,
    ----获取完成的状态
    GetFinishedStatus = function(player_game_status)
        local status_id_list = {}
        for pos = #player_game_status.history_data.info, 1, -1 do
            local status_id = player_game_status.history_data.info[pos].status_id
            local is_exist = false
            for _, status_info in ipairs(status_id_list) do
                if (status_info.status_id == status_id) then
                    is_exist = true
                    break
                end
            end
            if (not is_exist) then
                table.insert(
                    status_id_list,
                    {
                        status_id = status_id
                    }
                )
            end
        end

        local award_info_list = {}

        for _, status_info in ipairs(status_id_list) do
            local collect_info = Calculate.FinishedInfo(player_game_status, status_info.status_id)
            if collect_info ~= nil then
                table.insert(
                    award_info_list,
                    {
                        status_id = status_info.status_id,
                        collect_info = collect_info
                    }
                )
            end
        end

        return award_info_list
    end,
    ---指定状态是否结束，nil表示没有结束，其他表示结束
    FinishedInfo = function(player_game_status, status_id, is_clear)
        local start_pos = 0
        ----查找最晚触发该状态的位置
        for pos = #player_game_status.history_data.info, 1, -1 do
            if (player_game_status.history_data.info[pos].status_id == status_id) then
                start_pos = pos
                break
            end
        end

        if (start_pos == 0) then
            return {
                total_win_chip = 0,
                spin_count = 0
            }
        end

        ---由该状态触发的其他状态和他本身是否结束
        if (start_pos > 0) then
            for pos = start_pos, #player_game_status.history_data.info, 1 do
                if
                    (player_game_status.history_data.info[pos].process <
                        player_game_status.history_data.info[pos].total_process)
                 then
                    return nil
                end
            end
        end

        local total_win_chip = player_game_status.history_data.info[start_pos].total_win_chip
        local spin_count = player_game_status.history_data.info[start_pos].process

        if (is_clear) then
            local base_status_info = nil
            for i = #player_game_status.history_data.info, start_pos, -1 do
                if (player_game_status.history_data.info[i].status_id == GameStatusDefine.AllTypes.BaseSpinGame) then
                    base_status_info = player_game_status.history_data.info[i]
                end

                table.remove(player_game_status.history_data.info, i)
            end

            if (base_status_info ~= nil) then
                base_status_info.total_win_chip = 0
                table.insert(player_game_status.history_data.info, base_status_info)
            end
        end

        return {
            total_win_chip = total_win_chip,
            spin_count = spin_count
        }
    end
}
