require "Common/SlotsChefsChoiceCal"
require "Common/RequestFilter"
require "Module/DailyTask"
require "Common/RobotAction"
module("SlotsChefsChoice", package.seeall)

-----------------------------------------------
-- 进入房间
------------------------------------------------
Enter = function(_M, session, request)
    local response = {header = {router = "Response"}}

    local filter_ret = RequestFilter.Filter("SlotsChefsChoice", "Enter", session, request, true)
    if filter_ret then
        response.ret = filter_ret
        return response
    end
    local task = session.task
    local player = session.player

    CommonCal.Calculate.MakeUpInRoom(session, task)

    LOG(RUN, INFO).Format("[SlotsChefsChoice][Enter] player %s", player.id)

    local isLock = CommonCal.Calculate.LevelReq(player, GameType.AllTypes.ChefsChoice)
    if (isLock == 1) then
        response.ret = Return.LOCK_GAME()
        return response
    end

    local player_slots_info = CommonCal.Calculate.get_slots_info(session, task, player, GameType.AllTypes.ChefsChoice)
    local chefs_choice = json.decode(player_slots_info.content)

    chefs_choice.bouts_id = 0
     --进场的时候把cd清空掉
    chefs_choice.enter_chip = player.character.chip
    chefs_choice.spined_times = 0

    local game_room_config = GameRoomConfig[GameType.AllTypes.ChefsChoice]

    local table_id = request.table_id
    local async_request = nil
    if (table_id and table_id > 0) then
        local channel_id = string.format("%s.%s.%s", "SlotsChefsChoiceContest", game_room_config.room_name, table_id)
        chefs_choice.channel_id = channel_id
        async_request = {
            header = {
                router = "AsyncRequest",
                service_name = game_room_config.contest_client_name,
                task_id = task.id,
                module_id = "SlotsChefsChoiceContest",
                message_id = "SlotsChefsChoiceContest_Enter_Request"
            },
            player = {
                id = player.id,
                user = player.user,
                account = player.account,
                game_type = GameType.AllTypes.ChefsChoice,
                character = {
                    chip = player.character.chip,
                    vip = player.character.vip,
                    level = player.character.level,
                    experience = player.character.experience,
                    player_type = player.character.player_type
                },
                record = player.record,
                chefs_choice = chefs_choice
            }
        }
    else
        async_request = {
            header = {
                router = "AsyncRequest",
                service_name = game_room_config.contest_client_name,
                task_id = task.id,
                module_id = "SlotsChefsChoiceContest",
                message_id = "SlotsChefsChoiceContest_Enter_Request"
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
                chefs_choice = chefs_choice
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

    chefs_choice.channel_id = async_response.channel_id

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

    local free_spin_num_array = json.decode(chefs_choice.free_spin_num_str)

    SlotsChefsChoiceCal.Calculate.UpdateFreeBous(chefs_choice, free_spin_num_array)
    -- response.item_ids = SlotsOpenSesameCal.Calculate.GenInitItem()
    response.ret = Return.OK()
    response.player = {
        chefs_choice = chefs_choice,
        character = {
            chip = player.character.chip
        }
    }
    player.game_type = GameType.AllTypes.ChefsChoice

    player_slots_info.content = json.encode(chefs_choice)
    CommonCal.Calculate.UpdateSlotsToDbCache(task, player, player_slots_info)

    return response, table_sync_notice
end

--开始slots
Start = function(_M, session, request)
    local response = {header = {router = "Response"}}

    local filter_ret = RequestFilter.Filter("SlotsChefsChoice", "Start", session, request, true)
    if filter_ret then
        response.ret = filter_ret
        return response
    end

    local LineNum = #SlotsChefsChoiceCal.Const.Lines
    local task = session.task
    local amount
    local player = session.player

    local player_slots_info = CommonCal.Calculate.get_slots_info(session, task, player, GameType.AllTypes.ChefsChoice)
    local chefs_choice = json.decode(player_slots_info.content)

    CommonCal.Calculate.BeginStart(session, task, player)

    if GlobalState:IsSlotsMaintenance(session, task, player.id) == 1 then
        response.ret = Return.SERVER_NEAR_MAINENANCE()
        return response
    end

    if (player.game_type ~= GameType.AllTypes.ChefsChoice) then
        response.ret = Return.HAVE_ALREADY_EXIT_GAME()
        return response
    end
    local is_lock = CommonCal.Calculate.IsAppear(player)
    if (is_lock == 1) then
        response.ret = Return.LOCK_GAME()
        return response
    end
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

    local free_spin_num_array = json.decode(chefs_choice.free_spin_num_str)

    SlotsChefsChoiceCal.Calculate.UpdateFreeBous(chefs_choice, free_spin_num_array)

    local is_free_spin = chefs_choice.free_spin_bouts > 0

    response.is_free_spin = is_free_spin and 1 or 0
    LOG(RUN, INFO).Format(
        "[SlotsChefsChoice][Start] player %s's free_spin_num_str is: %s",
        player.id,
        chefs_choice.free_spin_num_str
    )
    local chip_cost = 0
    --free spin不扣钱, free spin下amount不会改
    if is_free_spin then
        amount = chefs_choice.bet_amount
        --chefs_choice.free_spin_bouts = math.max(chefs_choice.free_spin_bouts - 1, 0)

        if (#free_spin_num_array > 0) then
            if (free_spin_num_array[1].free_spin_bouts == 0) then
                table.remove(free_spin_num_array, 1)
            end
            free_spin_num_array[1].free_spin_bouts = math.max(tonumber(free_spin_num_array[1].free_spin_bouts) - 1, 0)
        end

        SlotsChefsChoiceCal.Calculate.UpdateFreeBous(chefs_choice, free_spin_num_array)
    else
        amount = request.amount
        chip_cost = amount * LineNum

        if not Player:Consume(player, {"Chip", chip_cost}, Reason.CHEFSCHOICE_BET_CHIP_CONSUME()) then
            response.ret = Return.GAME_PLAYER_CHIP_NOT_ENOUGH()
            return response
        end
        chefs_choice.bet_amount = amount
        LOG(RUN, INFO).Format("[SlotsChefsChoice][Start] player %s's chip2 is %s", player.id, player.character.chip)
    end

    local bet_amount_conf
    local ChefsChoiceBetAmountConfig = CommonCal.Calculate.get_config(player, "ChefsChoiceBetAmountConfig")
    for k, v in ipairs(ChefsChoiceBetAmountConfig) do
        if v.single_amount == amount then
            bet_amount_conf = v
            break
        end
    end

    --local item_list = {}
    local total_win_chip = 0
    local all_erase_items = {}
    local all_drop_items = {}
    local all_prize_items = {}
    local all_win_chip = 0
    local win_chips = {}

    local is_get_free_spin = false
    local reel_file_name

    local trigger_free_spin = 0
    local is_respin = 1
    while (is_respin == 1) do
        is_respin = 0

        local hasRemove = 1

        --LOG(RUN, INFO).Format("table.copy begin, spined_times: %s", chefs_choice.spined_times)
        local local_chefs_choice = table.DeepCopy(chefs_choice)
        --LOG(RUN, INFO).Format("table.copy end, local_chefs_choice spined_times：%s", local_chefs_choice.spined_times)

        local local_record = table.DeepCopy(player.record)
        local local_exp_request_list = {}
        local local_free_spin_num_array = table.DeepCopy(free_spin_num_array)
        -- LOG(RUN, INFO).Format("local_chefs_choice is: %s, chefs_choice is: %s, spined_times is: %s", table.show(local_chefs_choice), table.show(chefs_choice), local_chefs_choice.spined_times)
        local local_pot_points_list = {}
        local local_response = table.DeepCopy(response)

        --local cur_free_type = chefs_choice.free_spin_num
        local origin_result
        local ColumnIndexList = {}
        local result = {{}, {}, {}, {}, {}}
        local last_remove_item_list = {}

        --item_list = {}
        total_win_chip = 0
        all_erase_items = {}
        all_drop_items = {}
        all_prize_items = {}
        all_win_chip = 0
        win_chips = {}

        local loop_num = 0

        local add_free_spin_bouts = 0

        while hasRemove == 1 do
            local free_spin_num = 0
            CommonCal.Calculate.SetLoopNum(player.id, loop_num)
            local free_spin_type = 0
            if (#local_free_spin_num_array > 0) then
                free_spin_type = tonumber(local_free_spin_num_array[1].free_spin_type)
            end
            local drop_items_list = {}
            if is_free_spin then
                origin_result, ColumnIndexList, drop_items_list, reel_file_name =
                    SlotsChefsChoiceCal.Calculate.GenItemResult(
                    player,
                    last_remove_item_list,
                    ColumnIndexList,
                    result,
                    free_spin_type,
                    loop_num
                )
            else
                origin_result, ColumnIndexList, drop_items_list, reel_file_name =
                    SlotsChefsChoiceCal.Calculate.GenItemResult(
                    player,
                    last_remove_item_list,
                    ColumnIndexList,
                    result,
                    0,
                    loop_num
                )
            end
            if (#drop_items_list > 0) then
                table.insert(all_drop_items, {drop_items = drop_items_list})
            end
            local prize_items, total_payrate, remove_item_list =
                SlotsChefsChoiceCal.Calculate.GenPrizeInfo(player, origin_result)
            local item_ids = SlotsChefsChoiceCal.Calculate.TransResultToList(origin_result)

            local win_chip = total_payrate * amount
            total_win_chip = total_win_chip + win_chip

            if (#remove_item_list > 0) then
                hasRemove = 1
                last_remove_item_list = remove_item_list

                local erase_item_list = {}
                for _, item in pairs(remove_item_list) do
                    local row = item.row
                    local column = item.column
                    local slots_item = {}
                    slots_item.row = row
                    slots_item.col = column
                    table.insert(erase_item_list, slots_item)
                end
                --local local_erase_items = {}
                -- table.insert(local_erase_items, {erase_items = erase_item_list})
                table.insert(all_erase_items, {erase_items = erase_item_list})
            else
                hasRemove = 0
                last_remove_item_list = {}

                if (loop_num == 4) then --连消4次，得到5次free spin
                    free_spin_num = 5
                elseif (loop_num == 5) then --连消5次，得到10次free spin
                    free_spin_num = 10
                elseif (loop_num == 6) then
                    free_spin_num = 20
                elseif (loop_num >= 7) then
                    free_spin_num = 50
                end

                if (free_spin_type == 50 and free_spin_num == 50) then --处于50次的free spin中不能再出现50
                    is_respin = 1
                end
            end

            add_free_spin_bouts = free_spin_num

            if (free_spin_num > 0) then
                local_chefs_choice.free_spin_num = free_spin_num

                local free_spin_item = {}
                free_spin_item["free_spin_type"] = free_spin_num
                free_spin_item["free_spin_bouts"] = free_spin_num
                table.insert(local_free_spin_num_array, free_spin_item)

                is_get_free_spin = true

                trigger_free_spin = 1
            end

            SlotsChefsChoiceCal.Calculate.UpdateFreeBous(local_chefs_choice, local_free_spin_num_array)
            --local_chefs_choice.free_spin_bouts = local_chefs_choice.free_spin_bouts + free_spin_num

            ----记录record
            local_record.total_spin = local_record.total_spin + 1
            if is_free_spin then
                local_record.free_spin = local_record.free_spin + 1
            end

            -----记录free spin中总赢取
            if is_free_spin then
                local_chefs_choice.free_total_win = local_chefs_choice.free_total_win + win_chip
            else
                local_chefs_choice.free_total_win = 0
            end

            if (win_chip > 0) then
                table.insert(all_prize_items, {prize_items = prize_items})
                table.insert(win_chips, win_chip)
                all_win_chip = win_chip + all_win_chip
            end
            if (loop_num == 0) then
                local_response.item_ids = item_ids
            end
            local_response.free_spin_num = free_spin_num
            loop_num = loop_num + 1
        end

        if (is_respin == 0) then
            SlotsChefsChoiceCal.Calculate.GetChefsChoice(chefs_choice, local_chefs_choice)
            SlotsChefsChoiceCal.Calculate.GetRecord(player, local_record)
            free_spin_num_array = local_free_spin_num_array
            response = table.DeepCopy(local_response)
        end
    end

    if (not is_free_spin and is_get_free_spin) then
        chefs_choice.bouts_id = os.time()
    end

    DailyMissionsCal.Calculate.UpdateGameDailyMissions(
        session,
        player,
        amount,
        chip_cost,
        total_win_chip,
        is_free_spin,
        player.game_type,
        trigger_free_spin
    )

    --广播
    local win_info = {
        bet_amount = amount,
        total_bet = amount * LineNum,
        win_chip = total_win_chip
    }
    Communication:OnBcEvent(session, BroadcastType.AllTypes.ChefsChoice, win_info, 15)

    local free_win_amount = 0
    if (is_free_spin) then
        free_win_amount = total_win_chip
    end
    local ChefsChoicePrizeConfig = CommonCal.Calculate.get_config(player, "ChefsChoicePrizeConfig")
    --accomplish tasks
    local task_req_data = {
        five_line = CommonCal.Calculate.GetFiveLineCount(all_prize_items),
        base_spin = not is_free_spin,
        free_spin = is_get_free_spin,
         --本次下注是否属于freespin
        win_amount = total_win_chip,
        bet_amount = amount * LineNum,
        max_bet = amount >= SlotsChefsChoiceCal.Calculate.GetMaxBetAmount(player),
        free_win_amount = free_win_amount,
        epic_win = (total_win_chip / (amount * LineNum)) >= ChefsChoicePrizeConfig[3].min_multiple
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
    if ((total_win_chip / (amount * LineNum)) >= ChefsChoicePrizeConfig[3].min_multiple) then
        player.statistics.epicwin_num = player.statistics.epicwin_num + 1
    elseif ((total_win_chip / (amount * LineNum)) >= ChefsChoicePrizeConfig[2].min_multiple) then
        player.statistics.megawin_num = player.statistics.megawin_num + 1
    elseif ((total_win_chip / (amount * LineNum)) >= ChefsChoicePrizeConfig[1].min_multiple) then
        player.statistics.bigwin_num = player.statistics.bigwin_num + 1
    end

    Player:BroadCastChip(session, task, amount * LineNum, total_win_chip)

    response.all_erase_items = all_erase_items
    response.all_drop_items = all_drop_items
    response.all_prize_items = all_prize_items
    response.all_win_chip = all_win_chip
    response.win_chip = win_chips
    --buyloss的局数+1
    chefs_choice.spined_times = chefs_choice.spined_times + 1

    if total_win_chip > 0 then
        Player:Obtain(player, {"Chip", total_win_chip}, Reason.CHEFSCHOICE_BET_CHIP_OBTAIN())

        --记录每日、每周赢钱,进排行榜
        RankHelper:ChallengeDailyWin(player)
        RankHelper:ChallengeWeeklyWin(player)
        --free spin不计入biggest win的统计
        --if not is_free_spin then
        --[[
            local rep_data = {
                item_list = item_list,
                item_ids = response.item_ids,
                prize_items = response.prize_items,
                win_chip = response.win_chip,
                all_win_chip = total_win_chip,
                bet_amount = amount,
            }
            --]]
        local rep_free_spin = 0
        if (is_free_spin) then
            rep_free_spin = 1
        end
        local rep_data = {
            item_ids = response.item_ids,
            bet_amount = amount,
            all_prize_items = all_prize_items,
            all_drop_items = all_drop_items,
            all_erase_items = all_erase_items,
            win_chip = win_chips, --保证客户端字段名一致,win_chip实际上是个数组
            all_win_chip = all_win_chip,
            free_spin = rep_free_spin
        }

        RankHelper:ChallengeDailyBiggestWin(player, GameType.AllTypes.ChefsChoice, rep_data)
        RankHelper:ChallengeWeeklyBiggestWin(player, GameType.AllTypes.ChefsChoice, rep_data)
        --end
        ----记录record
        player.record.spin_won = player.record.spin_won + 1
        player.record.total_win = player.record.total_win + total_win_chip
        if total_win_chip > player.record.biggest_win then
            player.record.biggest_win = total_win_chip
        end
    end

    local can_multiply = SlotsGameCal.Calculate.WinChipInMultiply(total_win_chip)

    if (can_multiply) then
        if ((total_win_chip / (amount * LineNum)) >= ChefsChoicePrizeConfig[1].min_multiple and not is_free_spin) then
            response.is_multiply = CommonCal.Calculate.IsMultiply(session, total_win_chip)
        end

        if ((total_win_chip / (amount * LineNum)) >= ChefsChoicePrizeConfig[1].min_multiple and not is_free_spin) then
            RobotAction.BigWinAction(session, task)
        end
    end

    --response.item_list = item_list

    ----记录record
    player.record.total_spin = player.record.total_spin + 1
    if is_free_spin then
        player.record.free_spin = player.record.free_spin + 1
    end

    local contest_id, room_id, table_id = unpack(string.split(chefs_choice.channel_id, "."))
    if (is_free_spin) then
        Spark:SlotsAward(
            player,
            {
                [1] = GameType.AllTypes.ChefsChoice,
                [2] = "ChefsChoice",
                [3] = table_id,
                [4] = chefs_choice.bouts_id,
                [5] = chefs_choice.bet_amount,
                [6] = all_win_chip,
                [7] = json.encode(origin_result),
                [8] = json.encode(all_drop_items and all_drop_items or {}),
                [9] = reel_file_name,
                [10] = chefs_choice.free_spin_bouts,
                [11] = CommonCal.Calculate.GetFiveLineCount(all_prize_items) > 0 and 1 or 0,
                [12] = player.record.total_spin,
                [13] = amount * LineNum
            }
        )
    else
        Spark:SlotsStart(
            player,
            {
                [1] = GameType.AllTypes.ChefsChoice,
                [2] = "ChefsChoice",
                [3] = table_id,
                [4] = chefs_choice.bouts_id,
                [5] = amount,
                [6] = amount * LineNum,
                [7] = total_win_chip,
                [8] = json.encode(origin_result),
                [9] = json.encode(all_drop_items and all_drop_items or {}),
                [10] = is_free_spin,
                [11] = reel_file_name,
                [12] = CommonCal.Calculate.GetFiveLineCount(all_prize_items) > 0 and 1 or 0,
                [13] = player.record.total_spin
            }
        )
    end

    CommonCal.Calculate.EndStart(
        session,
        task,
        player,
        request,
        response,
        chefs_choice,
        LineNum,
        chip_cost,
        total_win_chip
    )
    --gain exp
    if not is_free_spin then
        local exp = chip_cost
        local exp_request = {
            type = "SlotsChefsChoice",
            ante_gold = amount * LineNum,
            gain_exp = exp
        }
        Player:GainExp(session, exp_request)
    end

    --锦标赛玩家得分更新
    CommonCal.Calculate.UpdateTournamentPlayerInfo(session, player.game_type, player, chip_cost, total_win_chip)

    chefs_choice.free_spin_num_str = json.encode(free_spin_num_array)
    response.ret = Return.OK()

    player_slots_info.content = json.encode(chefs_choice)
    CommonCal.Calculate.UpdateSlotsToDbCache(task, player, player_slots_info)

    response.player = {
        unlock_games = player.unlock_games,
        character = {
            chip = player.character.chip,
            experience = player.character.experience,
            level = player.character.level
        },
        chefs_choice = {
            bet_amount = amount,
            bonus_progress = chefs_choice.bonus_progress,
            free_spin_bouts = chefs_choice.free_spin_bouts,
            free_total_win = chefs_choice.free_total_win,
            is_slots = chefs_choice.is_slots
        }
    }

    return response
end

-----------------------------------------------
-- 退出房间
------------------------------------------------
Exit = function(_M, session, request)
    local response = {header = {router = "Response"}}

    local filter_ret = RequestFilter.Filter("SlotsChefsChoice", "Exit", session, request, true)
    if filter_ret then
        response.ret = filter_ret
        return response
    end

    local player = session.player
    local task = session.task

    local player_slots_info = CommonCal.Calculate.get_slots_info(session, task, player, GameType.AllTypes.ChefsChoice)
    local chefs_choice = json.decode(player_slots_info.content)

    local game_room_config = GameRoomConfig[player.game_type]
    if (game_room_config == nil) then
        response.ret = Return.HAVE_ALREADY_EXIT_GAME()
        return response
    end
    local async_request = {
        header = {
            router = "AsyncRequest",
            service_name = game_room_config.contest_client_name,
            task_id = task.id,
            module_id = "SlotsChefsChoiceContest",
            message_id = "SlotsChefsChoiceContest_Exit_Request"
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
        BuyLoss:Trigger(session, task, GameType.AllTypes.ChefsChoice, player) ---当玩家钱减少到一定数量时，提示玩家充值
    if trigger_buyloss then
        chefs_choice.total_loss = total_loss
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
    chefs_choice.spined_times = 0

    --------客户端的小游戏退出后，获取该值到baseGame

    response = {
        header = response.header,
        ret = Return.OK(),
        player = {
            character = {
                chip = player.character.chip
            }
        }
    }

    player_slots_info.content = json.encode(chefs_choice)
    CommonCal.Calculate.UpdateSlotsToDbCache(task, player, player_slots_info)
    LOG(RUN, INFO).Format("[SlotsChefsChoice][Exit] ok player %s", player.id)
    return response
end
