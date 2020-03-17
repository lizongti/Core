require "Common/SlotsCashSpinCal"
require "Common/RequestFilter"
require "Module/DailyTask"
require "Common/RobotAction"
module("SlotsCashSpin", package.seeall)

-----------------------------------------------
-- 进入房间
------------------------------------------------
Enter = function(_M, session, request)
    local response = {header = {router = "Response"}}

    local filter_ret = RequestFilter.Filter("SlotsCashSpin", "Enter", session, request, true)
    if filter_ret then
        response.ret = filter_ret
        return response
    end
    local task = session.task
    local player = session.player

    CommonCal.Calculate.MakeUpInRoom(session, task)

    LOG(RUN, INFO).Format("[SlotsCashSpin][Enter] player %s", player.id)

    local isLock = CommonCal.Calculate.LevelReq(player, GameType.AllTypes.CashSpin)
    if (isLock == 1) then
        response.ret = Return.LOCK_GAME()
        return response
    end

    local player_slots_info = CommonCal.Calculate.get_slots_info(session, task, player, GameType.AllTypes.CashSpin)
    local cash_spin = json.decode(player_slots_info.content)

    cash_spin.bouts_id = 0
     --进场的时候把cd清空掉
    cash_spin.enter_chip = player.character.chip
    cash_spin.spined_times = 0

    local game_room_config = GameRoomConfig[GameType.AllTypes.CashSpin]

    local table_id = request.table_id
    local async_request = nil
    if (table_id and table_id > 0) then
        local channel_id = string.format("%s.%s.%s", "SlotsCashSpinContest", game_room_config.room_name, table_id)
        cash_spin.channel_id = channel_id
        async_request = {
            header = {
                router = "AsyncRequest",
                service_name = game_room_config.contest_client_name,
                task_id = task.id,
                module_id = "SlotsCashSpinContest",
                message_id = "SlotsCashSpinContest_Enter_Request"
            },
            player = {
                id = player.id,
                user = player.user,
                account = player.account,
                game_type = GameType.AllTypes.CashSpin,
                character = {
                    chip = player.character.chip,
                    vip = player.character.vip,
                    level = player.character.level,
                    experience = player.character.experience,
                    player_type = player.character.player_type
                },
                record = player.record,
                cash_spin = cash_spin
            }
        }
    else
        async_request = {
            header = {
                router = "AsyncRequest",
                service_name = game_room_config.contest_client_name,
                task_id = task.id,
                module_id = "SlotsCashSpinContest",
                message_id = "SlotsCashSpinContest_Enter_Request"
            },
            player = {
                id = player.id,
                user = player.user,
                account = player.account,
                character = {
                    chip = player.character.chip,
                    vip = player.character.vip,
                    level = player.character.level,
                    experience = player.character.experience,
                    player_type = player.character.player_type
                },
                record = player.record,
                cash_spin = cash_spin
            }
        }
    end

    local async_response = session:ContactPacket(task, async_request)

    if async_response.ret.code ~= 0 then
        response.ret = async_response.ret
        return response
    end
    local table_sync_notice = {
        header = {
            router = "Notice"
        },
        table = async_response.table
    }

    cash_spin.channel_id = async_response.channel_id

    --opt entertable
    local channel_id = async_response.channel_id
    local contest_id, room_id, table_id = unpack(string.split(channel_id, "."))
    local table_mates = {}
    for _, v in pairs(async_response.table.seat) do
        if v.player then
            table.insert(table_mates, v.player.id)
        end
    end

    Spark:EnterTable(
        player,
        {
            [1] = contest_id,
            [2] = room_id,
            [3] = table_id,
            [4] = #table_mates,
            [5] = table_mates
        }
    )

    local async_request = {
        header = {
            router = "AsyncRequest",
            service_name = "NotificationClientService",
            task_id = task.id,
            module_id = "Distributor",
            message_id = "Distributor_Register_Request"
        },
        session_id = session.id,
        player_id = player.id,
        channel_id = {async_response.channel_id},
        drop_channel_id = {"Hall"},
        player_type = session.player.character.player_type
    }
    local async_response = session:ContactPacket(task, async_request)
    if async_response.ret.code ~= 0 then
        response.ret = async_response.ret
        return response
    end

    async_request.header.service_name = game_room_config.contest_client_name
    local async_response = session:ContactPacket(task, async_request)
    if async_response.ret.code ~= 0 then
        response.ret = async_response.ret
        return response
    end

    -- response.item_ids = SlotsOpenSesameCal.Calculate.GenInitItem()
    response.ret = Return.OK()
    response.player = {
        cash_spin = cash_spin,
        character = {
            chip = player.character.chip
        }
    }
    player.game_type = GameType.AllTypes.CashSpin

    player_slots_info.content = json.encode(cash_spin)
    CommonCal.Calculate.UpdateSlotsToDbCache(task, player, player_slots_info)

    return response, table_sync_notice
end

Pick = function(_M, session, request)
    local response = {header = {router = "Response"}}

    local filter_ret = RequestFilter.Filter("SlotsCashSpin", "Pick", session, request, true)
    if filter_ret then
        response.ret = filter_ret
        return response
    end

    local task = session.task
    local player = session.player

    if GlobalState:IsSlotsMaintenance(session, task, player.id) == 1 then
        response.ret = Return.SERVER_NEAR_MAINENANCE()
        return response
    end

    local player_slots_info = CommonCal.Calculate.get_slots_info(session, task, player, GameType.AllTypes.CashSpin)
    local cash_spin = json.decode(player_slots_info.content)

    if (cash_spin.is_bonus_game == 0) then
        response.ret = Return.GAME_CANNOT_PLAYE_BONUS_GAME()
        return response
    end

    local is_over = request.is_over
    --local amount = request.amount
    -- local is_generate = request.is_generate

    local bonus_remain_item_array = json.decode(cash_spin.bonus_remain_items)
    local bonus_sel_item_array = json.decode(cash_spin.bonus_sel_items)
    --local bonus_unsel_item_array = json.decode(cash_spin.bonus_unsel_items)

    --if (#bonus_remain_item_array == 0)
    --then
    --    response.ret = Return.GAME_BONUS_GAME_OVER()
    --    return response
    --end

    --if (is_generate == 1)
    --then
    --   local generate_num = 0
    --   while (generate_num < amount)
    --    do
    --        table.insert(bonus_unsel_item_array, bonus_remain_item_array[1])
    --       table.remove(bonus_remain_item_array, 1)
    --        generate_num = generate_num + 1
    --    end
    -- end

    --if (#bonus_unsel_item_array == 0)
    --then
    --    response.ret = Return.GAME_NO_NEW_CASH()
    --   return response
    -- end

    local sel_item = {}
    response.is_over = is_over
    if (#bonus_remain_item_array ~= 0 and is_over == 0) then
        sel_item = bonus_remain_item_array[1]
        table.insert(bonus_sel_item_array, sel_item)
        table.remove(bonus_remain_item_array, 1)
    end
    --[[
    if (#bonus_remain_item_array == 0 or is_over == 1)--游戏结束
    then
        response.is_over = 1
    else
        response.is_over = 0

        sel_item = bonus_remain_item_array[1]
        table.insert(bonus_sel_item_array, sel_item)
        table.remove(bonus_remain_item_array, 1)

        LOG(RUN, INFO).Format("[SlotsCashSpin][Pick] player id is: %s, sel item is: %s", player.id, sel_item.award)
    end
    --]]
    local total_award = 0
    for k, v in ipairs(bonus_sel_item_array) do
        total_award = total_award + v.award
    end
    local LineNum = #SlotsCashSpinCal.Const.Lines
    local total_chip = math.floor(total_award * cash_spin.bet_amount * LineNum + 0.5)

    if (response.is_over == 1) then --游戏结束
        cash_spin.is_bonus_game = 0
        Player:Obtain(player, {"Chip", total_chip}, Reason.CASH_SPIN_BONUS_CHIP_OBTAIN())

        local task_req_data = {
            bonus_win_amount = total_chip
        }
        DailyTask:CompleteTask(session, player, task_req_data)

        local line_num = #SlotsAgentBondCal.Const.Lines

        local number = total_chip / (cash_spin.bet_amount * line_num)
        CommonCal.Calculate.CalBonusAward(player, number)

        --锦标赛玩家得分更新
        CommonCal.Calculate.UpdateTournamentPlayerInfo(session, player.game_type, player, 0, total_chip)

        local contest_id, room_id, table_id = unpack(string.split(cash_spin.channel_id, "."))

        Spark:SlotsBonusAward(
            player,
            {
                [1] = GameType.AllTypes.CashSpin,
                [2] = "CashSpin",
                [3] = table_id,
                [4] = cash_spin.bouts_id,
                [5] = cash_spin.bet_amount,
                [6] = total_chip
            }
        )
    else
        response.sel_item = math.floor(sel_item.award * cash_spin.bet_amount * LineNum + 0.5)
    end

    response.total_award = total_chip

    cash_spin.bonus_remain_items = json.encode(bonus_remain_item_array)
    cash_spin.bonus_sel_items = json.encode(bonus_sel_item_array)
    response.player = {
        unlock_games = player.unlock_games,
        character = {
            chip = player.character.chip
        },
        cash_spin = cash_spin
    }

    player_slots_info.content = json.encode(cash_spin)
    CommonCal.Calculate.UpdateSlotsToDbCache(task, player, player_slots_info)

    response.ret = Return.OK()
    return response
end

--开始slots
Start = function(_M, session, request)
    local response = {header = {router = "Response"}}

    local filter_ret = RequestFilter.Filter("SlotsCashSpin", "Start", session, request, true)
    if filter_ret then
        response.ret = filter_ret
        return response
    end

    local LineNum = #SlotsCashSpinCal.Const.Lines

    local task = session.task
    local amount
    local player = session.player
    CommonCal.Calculate.BeginStart(session, task, player)

    if GlobalState:IsSlotsMaintenance(session, task, player.id) == 1 then
        response.ret = Return.SERVER_NEAR_MAINENANCE()
        return response
    end

    if (player.game_type ~= GameType.AllTypes.CashSpin) then
        response.ret = Return.HAVE_ALREADY_EXIT_GAME()
        return response
    end
    local is_lock = CommonCal.Calculate.IsAppear(player)
    if (is_lock == 1) then
        response.ret = Return.LOCK_GAME()
        return response
    end

    local player_slots_info = CommonCal.Calculate.get_slots_info(session, task, player, GameType.AllTypes.CashSpin)
    local cash_spin = json.decode(player_slots_info.content)

    local all_prize_items = {}

    cash_spin.bouts_id = os.time()

    if (Base.Enviroment.pro_spec_t ~= "online" and player.character.player_type ~= tonumber(ConstValue[5].value)) then
        local async_request = {
            header = {
                router = "LocalRequest",
                service_name = "DispatcherService",
                task_id = task.id,
                module_id = "SlotsTest",
                message_id = "SlotsTest_Init_Request"
            },
            player_id = player.id
        }

        local async_response = session:ContactPacket(task, async_request)
    end
    --free spin不扣钱, free spin下amount不会改

    amount = request.amount
    local chip_cost = amount * LineNum
    if not Player:Consume(player, {"Chip", chip_cost}, Reason.CASH_SPIN_BET_CHIP_CONSUME()) then
        response.ret = Return.GAME_PLAYER_CHIP_NOT_ENOUGH()
        return response
    end

    local is_reset = 0
    if (amount > cash_spin.bet_amount) then
        is_reset = 1
    end
    cash_spin.bet_amount = amount

    local CashSpinBetAmountConfig = CommonCal.Calculate.get_config(player, "CashSpinBetAmountConfig")
    local bet_amount_conf
    for k, v in ipairs(CashSpinBetAmountConfig) do
        if v.single_amount == amount then
            bet_amount_conf = v
            break
        end
    end

    local origin_result, reel_file_name
    local item_list = {}
    local freeze_list = json.decode(cash_spin.freeze_list)

    local index = 1
    while index <= #freeze_list do
        freeze_list[index].delete = 1
        index = index + 1
    end

    if (is_reset == 1) then
        local index = 1
        while index <= #freeze_list do
            if freeze_list[index].delete == 1 then
                table.remove(freeze_list, index)
            else
                index = index + 1
            end
        end
    end

    --LOG(RUN, INFO).Format("GlobalSlotsTest.loopNum :%s, freeze_list is: %s", GlobalSlotsTest.loopNum, Table2Str(freeze_list))
    if (GlobalSlotsTest.result ~= nil and GlobalSlotsTest[player.id] ~= nil) then
        if (#freeze_list > 0) then
            --LOG(RUN, INFO).Format("GlobalSlotsTest.loopNum11 :%s, #freeze_list is: %s", GlobalSlotsTest.loopNum, #freeze_list)
            if (cash_spin.loop_num == nil) then
                cash_spin.loop_num = 0
            else
                cash_spin.loop_num = cash_spin.loop_num + 1
            end

            CommonCal.Calculate.SetLoopNum(player.id, cash_spin.loop_num)
        else
            --LOG(RUN, INFO).Format("GlobalSlotsTest.loopNum22 :%s, #freeze_list is: %s", GlobalSlotsTest.loopNum, #freeze_list)
            cash_spin.loop_num = 0
            CommonCal.Calculate.SetLoopNum(player.id, cash_spin.loop_num)
        end
    end

    origin_result, reel_file_name = SlotsCashSpinCal.Calculate.GenItemResult(player)

    --LOG(RUN, INFO).Format("[SlotsCashSpin][GenItemResult] origin_result结果")
    -- for i = 1, 3 do
    --     LOG(RUN, INFO).Format("%s, %s, %s, %s, %s", origin_result[i][1], origin_result[i][2], origin_result[i][3], origin_result[i][4], origin_result[i][5])
    -- end

    local local_wild_result = table.DeepCopy(origin_result)

    SlotsCashSpinCal.Calculate.GenWildResult(local_wild_result, freeze_list)

    local prize_items, total_payrate = SlotsCashSpinCal.Calculate.GenPrizeInfo(player, local_wild_result, freeze_list)

    if (total_payrate <= 0) then
        freeze_list = {}
    end

    local index = 1
    while index <= #freeze_list do
        if freeze_list[index].delete == 1 then
            table.remove(freeze_list, index)
        else
            index = index + 1
        end
    end

    table.insert(all_prize_items, prize_items)

    cash_spin.freeze_list = json.encode(freeze_list)

    local item_ids = SlotsCashSpinCal.Calculate.TransResultToList(origin_result)
    cash_spin.item_ids = json.encode(item_ids)
    local win_chip = total_payrate * amount

    local bonus_remain_item_array = {}
    local bonus_sel_item_array = {}

    local bonus_count = SlotsCashSpinCal.Calculate.GetBonusCount(origin_result)
    if (bonus_count >= 3) then
        cash_spin.is_bonus_game = 1

        local CashSpinBonusGameConfig = CommonCal.Calculate.get_config(player, "CashSpinBonusGameConfig")
        ------随机40张钱
        local local_weight_tab = {}
        for k, v in ipairs(CashSpinBonusGameConfig) do
            local_weight_tab[k] = v.weight_value
        end

        local bonus_unsel_item_array = {}
        local total = 1
        while (total <= 40) do
            local local_index = math.rand_weight(player, local_weight_tab)
            table.insert(
                bonus_remain_item_array,
                {value = CashSpinBonusGameConfig[local_index].value, award = CashSpinBonusGameConfig[local_index].award}
            )
            total = total + 1
        end

    --cash_spin.bonus_unsel_items = json.encode(bonus_unsel_item_array)
    end

    cash_spin.bonus_remain_items = json.encode(bonus_remain_item_array)
    cash_spin.bonus_sel_items = json.encode(bonus_sel_item_array)

    ----记录record
    player.record.total_spin = player.record.total_spin + 1
    if is_free_spin then
        player.record.free_spin = player.record.free_spin + 1
    end

    DailyMissionsCal.Calculate.UpdateGameDailyMissions(
        session,
        player,
        amount,
        chip_cost,
        win_chip,
        is_free_spin,
        player.game_type,
        0
    )

    --gain exp
    if not is_free_spin then
        local exp = chip_cost
        local exp_request = {
            type = "SlotsCashSpin",
            ante_gold = amount * LineNum,
            gain_exp = exp
        }
        Player:GainExp(session, exp_request)
    end

    local free_win_amount = 0
    if (is_free_spin) then
        free_win_amount = win_chip
    end

    local CashSpinPrizeConfig = CommonCal.Calculate.get_config(player, "CashSpinPrizeConfig")
    --accomplish tasks
    local task_req_data = {
        five_line = CommonCal.Calculate.GetFiveLineCount(all_prize_items),
        base_spin = not is_free_spin,
        win_amount = win_chip,
        bet_amount = amount * LineNum,
        max_bet = amount >= SlotsCashSpinCal.Calculate.GetMaxBetAmount(player),
        free_win_amount = free_win_amount,
        bonus_game = (bonus_count >= 3),
        epic_win = (total_payrate / LineNum) >= CashSpinPrizeConfig[3].min_multiple
    }
    DailyTask:CompleteTask(session, player, task_req_data)

    local history_games = json.decode(player.statistics.history_games)
    local is_exist = false
    for _, v in pairs(history_games) do
        if (v == player.game_type) then
            is_exist = true
            break
        end
    end
    if (not is_exist) then
        table.insert(history_games, player.game_type)
    end
    player.statistics.history_games = json.encode(history_games)
    player.statistics.last_game = player.game_type
    if ((win_chip / (amount * LineNum)) >= CashSpinPrizeConfig[3].min_multiple) then
        player.statistics.epicwin_num = player.statistics.epicwin_num + 1
    elseif ((win_chip / (amount * LineNum)) >= CashSpinPrizeConfig[2].min_multiple) then
        player.statistics.megawin_num = player.statistics.megawin_num + 1
    elseif ((win_chip / (amount * LineNum)) >= CashSpinPrizeConfig[1].min_multiple) then
        player.statistics.bigwin_num = player.statistics.bigwin_num + 1
    end
    if (bonus_count >= 3) then
        player.statistics.bonus_game_num = player.statistics.bonus_game_num + 1
    end

    Player:BroadCastChip(session, task, amount * LineNum, win_chip)

    local can_multiply = SlotsGameCal.Calculate.WinChipInMultiply(win_chip)

    if (can_multiply) then
        if ((total_payrate / LineNum) >= CashSpinPrizeConfig[1].min_multiple and not is_free_spin) then
            response.is_multiply = CommonCal.Calculate.IsMultiply(session, win_chip)
        end

        if ((total_payrate / LineNum) >= CashSpinPrizeConfig[1].min_multiple and not is_free_spin) then
            RobotAction.BigWinAction(session, task)
        end
    end

    --广播
    local win_info = {
        bet_amount = amount,
        total_bet = amount * LineNum,
        win_chip = win_chip
    }
    Communication:OnBcEvent(session, BroadcastType.AllTypes.CashSpin, win_info, 15)

    if win_chip > 0 then
        Player:Obtain(player, {"Chip", win_chip}, Reason.CASH_SPIN_BET_CHIP_OBTAIN())

        --记录每日、每周赢钱,进排行榜
        RankHelper:ChallengeDailyWin(player)
        RankHelper:ChallengeWeeklyWin(player)
        --free spin不计入biggest win的统计
        --if not is_free_spin then
        local rep_data = {
            item_ids = item_ids,
            prize_items = prize_items,
            win_chip = win_chip,
            bet_amount = amount,
            free_spin = 0,
            freeze_list = json.encode(freeze_list)
        }
        RankHelper:ChallengeDailyBiggestWin(player, GameType.AllTypes.CashSpin, rep_data)
        RankHelper:ChallengeWeeklyBiggestWin(player, GameType.AllTypes.CashSpin, rep_data)
        --end
        ----记录record
        player.record.spin_won = player.record.spin_won + 1
        player.record.total_win = player.record.total_win + win_chip
        if win_chip > player.record.biggest_win then
            player.record.biggest_win = win_chip
        end
    end

    --buyloss的局数+1
    cash_spin.spined_times = cash_spin.spined_times + 1

    response.item_ids = item_ids
    response.prize_items = prize_items
    response.win_chip = win_chip

    local contest_id, room_id, table_id = unpack(string.split(cash_spin.channel_id, "."))

    if (is_free_spin) then
        Spark:SlotsAward(
            player,
            {
                [1] = GameType.AllTypes.CashSpin,
                [2] = "CashSpin",
                [3] = table_id,
                [4] = cash_spin.bouts_id,
                [5] = cash_spin.bet_amount,
                [6] = win_chip,
                [7] = json.encode(origin_result),
                [8] = "[]",
                [9] = reel_file_name,
                [10] = cash_spin.free_spin_bouts,
                [11] = CommonCal.Calculate.GetFiveLineCount(all_prize_items) > 0 and 1 or 0,
                [12] = player.record.total_spin,
                [13] = amount * LineNum
            }
        )
    else
        Spark:SlotsStart(
            player,
            {
                [1] = GameType.AllTypes.CashSpin,
                [2] = "CashSpin",
                [3] = table_id,
                [4] = cash_spin.bouts_id,
                [5] = amount,
                [6] = amount * LineNum,
                [7] = win_chip,
                [8] = json.encode(origin_result),
                [9] = "[]",
                [10] = false,
                [11] = reel_file_name,
                [12] = CommonCal.Calculate.GetFiveLineCount(all_prize_items) > 0 and 1 or 0,
                [13] = player.record.total_spin
            }
        )
    end

    CommonCal.Calculate.EndStart(session, task, player, request, response, cash_spin, LineNum, chip_cost, win_chip)

    player_slots_info.content = json.encode(cash_spin)
    CommonCal.Calculate.UpdateSlotsToDbCache(task, player, player_slots_info)

    --锦标赛玩家得分更新
    CommonCal.Calculate.UpdateTournamentPlayerInfo(session, player.game_type, player, chip_cost, win_chip)

    response.ret = Return.OK()

    response.player = {
        unlock_games = player.unlock_games,
        character = {
            chip = player.character.chip,
            experience = player.character.experience,
            level = player.character.level
        },
        cash_spin = cash_spin
    }

    return response
end

-----------------------------------------------
-- 退出房间
------------------------------------------------
Exit = function(_M, session, request)
    local response = {header = {router = "Response"}}

    local filter_ret = RequestFilter.Filter("SlotsCashSpin", "Exit", session, request, true)
    if filter_ret then
        response.ret = filter_ret
        return response
    end

    local player = session.player
    local task = session.task

    local old_chip = player.character.chip

    local player_slots_info = CommonCal.Calculate.get_slots_info(session, task, player, GameType.AllTypes.CashSpin)
    local cash_spin = json.decode(player_slots_info.content)

    local game_room_config = GameRoomConfig[player.game_type]
    local async_request = {
        header = {
            router = "AsyncRequest",
            service_name = game_room_config.contest_client_name,
            task_id = task.id,
            module_id = "SlotsCashSpinContest",
            message_id = "SlotsCashSpinContest_Exit_Request"
        },
        player_id = player.id
    }

    local async_response = session:ContactPacket(task, async_request)

    if async_response.ret.code ~= 0 then
        response.ret = async_response.ret
        return response
    end

    -- opt exit
    local contest_id, room_id, table_id = unpack(string.split(async_response.channel_id, "."))
    local table_mates = {}
    for _, v in pairs(async_response.table.seat) do
        if v.player then
            table.insert(table_mates, v.player.id)
        end
    end

    Spark:LeaveTable(
        player,
        {
            [1] = contest_id,
            [2] = room_id,
            [3] = table_id,
            [4] = #table_mates,
            [5] = table_mates
        }
    )

    local async_request = {
        header = {
            router = "AsyncRequest",
            service_name = "NotificationClientService",
            task_id = task.id,
            module_id = "Distributor",
            message_id = "Distributor_Register_Request"
        },
        session_id = session.id,
        player_id = player.id,
        channel_id = {"Hall"},
        drop_channel_id = {async_response.channel_id},
        player_type = session.player.character.player_type
    }
    local async_response = session:ContactPacket(task, async_request)
    if async_response.ret.code ~= 0 then
        response.ret.code = async_response.ret.code
        return response
    end

    async_request.header.service_name = game_room_config.contest_client_name
    local async_response = session:ContactPacket(task, async_request)
    if async_response.ret.code ~= 0 then
        response.ret = async_response.ret
        return response
    end

    local trigger_buyloss, total_loss, diamond, goods_id =
        BuyLoss:Trigger(session, task, GameType.AllTypes.CashSpin, player) ---当玩家钱减少到一定数量时，提示玩家充值
    if trigger_buyloss then
        cash_spin.total_loss = total_loss
        session:WriteRouterPacket(
            {
                header = {
                    router = "SpecificNotice",
                    session_id = session.id,
                    player_id = player.id,
                    module_id = "BuyLoss",
                    message_id = "BuyLoss_Trigger_Notice"
                },
                total_loss = total_loss,
                diamond = diamond,
                goods_id = goods_id
            }
        )
    end
    cash_spin.spined_times = 0

    --------客户端的小游戏退出后，获取该值到baseGame
    session:WriteRouterPacket(
        {
            header = {
                router = "SpecificNotice",
                session_id = session.id,
                player_id = player.id,
                module_id = "Command",
                message_id = "Command_Player_Notice"
            },
            player = {
                cash_spin = {
                    step_num = cash_spin.step_num
                }
            },
            collect_chip = player.character.chip - old_chip
        }
    )

    response = {
        header = response.header,
        ret = Return.OK(),
        player = {
            character = {
                chip = player.character.chip
            }
        }
    }

    player_slots_info.content = json.encode(cash_spin)
    CommonCal.Calculate.UpdateSlotsToDbCache(task, player, player_slots_info)
    LOG(RUN, INFO).Format("[SlotsCashSpin][Exit] ok player %s", player.id)
    return response
end
