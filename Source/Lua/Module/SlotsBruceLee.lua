require "Common/SlotsBruceLeeCal"
require "Common/RequestFilter"
require "Module/DailyTask"
require "Common/RobotAction"
module("SlotsBruceLee", package.seeall)

-----------------------------------------------
-- 进入房间
------------------------------------------------
Enter = function(_M, session, request)
    local response = {header = {router = "Response"}}

    local filter_ret = RequestFilter.Filter("SlotsBruceLee", "Enter", session, request, true)
    if filter_ret then
        response.ret = filter_ret
        return response
    end
    local task = session.task
    local player = session.player

    local player_slots_info = CommonCal.Calculate.get_slots_info(session, task, player, GameType.AllTypes.BruceLee)
    local bruce_lee = json.decode(player_slots_info.content)

    CommonCal.Calculate.MakeUpInRoom(session, task)

    LOG(RUN, INFO).Format("[SlotsBruceLee][Enter] player %s", player.id)

    local isLock = CommonCal.Calculate.LevelReq(player, GameType.AllTypes.BruceLee)
    if (isLock == 1) then
        response.ret = Return.LOCK_GAME()
        return response
    end

    bruce_lee.bouts_id = 0
     --进场的时候把cd清空掉
    bruce_lee.enter_chip = player.character.chip
    bruce_lee.spined_times = 0

    local game_room_config = GameRoomConfig[GameType.AllTypes.BruceLee]

    local table_id = request.table_id
    local async_request = nil
    if (table_id and table_id > 0) then
        local channel_id = string.format("%s.%s.%s", "SlotsBruceLeeContest", game_room_config.room_name, table_id)
        bruce_lee.channel_id = channel_id
        async_request = {
            header = {
                router = "AsyncRequest",
                service_name = game_room_config.contest_client_name,
                task_id = task.id,
                module_id = "SlotsBruceLeeContest",
                message_id = "SlotsBruceLeeContest_Enter_Request"
            },
            player = {
                id = player.id,
                user = player.user,
                account = player.account,
                game_type = GameType.AllTypes.BruceLee,
                character = {
                    chip = player.character.chip,
                    vip = player.character.vip,
                    level = player.character.level,
                    experience = player.character.experience,
                    player_type = player.character.player_type
                },
                record = player.record,
                bruce_lee = bruce_lee
            }
        }
    else
        async_request = {
            header = {
                router = "AsyncRequest",
                service_name = game_room_config.contest_client_name,
                task_id = task.id,
                module_id = "SlotsBruceLeeContest",
                message_id = "SlotsBruceLeeContest_Enter_Request"
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
                bruce_lee = bruce_lee
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

    bruce_lee.channel_id = async_response.channel_id

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
    local free_spin_num_array = json.decode(bruce_lee.free_spin_num_str)
    SlotsBruceLeeCal.Calculate.UpdateFreeBous(bruce_lee, free_spin_num_array)
    -- response.item_ids = SlotsOpenSesameCal.Calculate.GenInitItem()
    response.ret = Return.OK()
    response.player = {
        bruce_lee = bruce_lee,
        character = {
            chip = player.character.chip
        }
    }
    player.game_type = GameType.AllTypes.BruceLee

    player_slots_info.content = json.encode(bruce_lee)
    CommonCal.Calculate.UpdateSlotsToDbCache(task, player, player_slots_info)

    return response, table_sync_notice
end

--开始slots
Start = function(_M, session, request)
    local response = {header = {router = "Response"}}

    local filter_ret = RequestFilter.Filter("SlotsBruceLee", "Start", session, request, true)
    if filter_ret then
        response.ret = filter_ret
        return response
    end

    local LineNum = #SlotsBruceLeeCal.Const.Lines
    local task = session.task
    local amount
    local player = session.player

    local player_slots_info = CommonCal.Calculate.get_slots_info(session, task, player, GameType.AllTypes.BruceLee)
    local bruce_lee = json.decode(player_slots_info.content)

    CommonCal.Calculate.BeginStart(session, task, player)

    if GlobalState:IsSlotsMaintenance(session, task, player.id) == 1 then
        response.ret = Return.SERVER_NEAR_MAINENANCE()
        return response
    end

    if (player.game_type ~= GameType.AllTypes.BruceLee) then
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

    local has_freeze = 1

    local free_spin_num_array = json.decode(bruce_lee.free_spin_num_str)

    SlotsBruceLeeCal.Calculate.UpdateFreeBous(bruce_lee, free_spin_num_array)

    local is_free_spin = bruce_lee.free_spin_bouts > 0

    response.is_free_spin = is_free_spin and 1 or 0
    local chip_cost = 0
    --free spin不扣钱, free spin下amount不会改
    if is_free_spin then
        amount = bruce_lee.bet_amount

        if (#free_spin_num_array > 0) then
            if (free_spin_num_array[1].free_spin_bouts == 0) then
                table.remove(free_spin_num_array, 1)
            end
            free_spin_num_array[1].free_spin_bouts = math.max(tonumber(free_spin_num_array[1].free_spin_bouts) - 1, 0)
        end

        SlotsBruceLeeCal.Calculate.UpdateFreeBous(bruce_lee, free_spin_num_array)
    else
        amount = request.amount
        chip_cost = amount * LineNum

        if not Player:Consume(player, {"Chip", chip_cost}, Reason.BRUCE_LEE_BET_CHIP_CONSUME()) then
            response.ret = Return.GAME_PLAYER_CHIP_NOT_ENOUGH()
            return response
        end
        bruce_lee.bet_amount = amount
        free_spin_num_array = {}
    end

    local bet_amount_conf
    local BruceLeeBetAmountConfig = CommonCal.Calculate.get_config(player, "BruceLeeBetAmountConfig")
    for k, v in ipairs(BruceLeeBetAmountConfig) do
        if v.single_amount == amount then
            bet_amount_conf = v
            break
        end
    end

    --local item_list = {}
    local freeze_list = {}
    local total_win_chip = 0
    local all_respin_items = {}
    local all_freeze_items = {}
    local all_prize_items = {}
    local all_win_chip = 0
    local win_chips = {}

    local is_get_free_spin = false
    local origin_result, reel_file_name
    local ColumnIndexList = {}
    local result = {{}, {}, {}, {}, {}}

    local next_free_spin_type = 0
    local free_spin_type = 0
    if (#free_spin_num_array > 0) then
        free_spin_type = tonumber(free_spin_num_array[1].free_spin_type)
    end

    local loop_num = 0

    while has_freeze > 0 do
        has_freeze = 0
        local free_spin_num = 0
        CommonCal.Calculate.SetLoopNum(player.id, loop_num)

        local respin_items_str = nil
        if is_free_spin then
            local respin_items_list = nil
            origin_result, respin_items_list, reel_file_name =
                SlotsBruceLeeCal.Calculate.GenItemResult(player, result, free_spin_type, loop_num, freeze_list)
            if (#respin_items_list > 0) then
                respin_items_str = json.encode(respin_items_list)
            end
        else
            local respin_items_list = nil
            origin_result, respin_items_list, reel_file_name =
                SlotsBruceLeeCal.Calculate.GenItemResult(player, result, 0, loop_num, freeze_list)
            if (#respin_items_list > 0) then
                respin_items_str = json.encode(respin_items_list)
            end
        end
        --LOG(RUN, INFO).Format("[SlotsBruceLee][GenItemResult] begin respin_items_str is: %s", respin_items_str)
        if (respin_items_str ~= nil) then
            table.insert(all_respin_items, respin_items_str)
        end

        --local local_wild_result = table.DeepCopy(origin_result)

        local gongfu_count = SlotsBruceLeeCal.Calculate.GetGongFuCount(origin_result)
        if (gongfu_count > 0) then
            freeze_list = SlotsBruceLeeCal.Calculate.IsFreeze(origin_result)
            has_freeze = #freeze_list

            if (has_freeze > 0) then
                table.insert(all_freeze_items, json.encode(freeze_list))
            end

        --SlotsBruceLeeCal.Calculate.GenWildResult(local_wild_result, freeze_list)
        end

        local prize_items, total_payrate = SlotsBruceLeeCal.Calculate.GenPrizeInfo(player, origin_result)
        local item_ids = SlotsBruceLeeCal.Calculate.TransResultToList(origin_result)

        local win_chip = total_payrate * amount
        if (free_spin_type == 10) then
            win_chip = win_chip * 1
        elseif (free_spin_type == 15) then
            win_chip = win_chip * 2
        elseif (free_spin_type == 20) then
            win_chip = win_chip * 3
        end

        total_win_chip = total_win_chip + win_chip

        local scatter_count = SlotsBruceLeeCal.Calculate.GetScatterCount(origin_result)

        if (scatter_count == 3) then
            local free_spin_item = {}
            free_spin_item["free_spin_type"] = 10
            free_spin_item["free_spin_bouts"] = 10
            table.insert(free_spin_num_array, free_spin_item)
            is_get_free_spin = true
        elseif (scatter_count == 4) then
            local free_spin_item = {}
            free_spin_item["free_spin_type"] = 15
            free_spin_item["free_spin_bouts"] = 15
            table.insert(free_spin_num_array, free_spin_item)
            is_get_free_spin = true
        elseif (scatter_count == 5) then
            local free_spin_item = {}
            free_spin_item["free_spin_type"] = 20
            free_spin_item["free_spin_bouts"] = 20
            table.insert(free_spin_num_array, free_spin_item)
            is_get_free_spin = true
        end

        bruce_lee.free_spin_num_str = json.encode(free_spin_num_array)
        SlotsBruceLeeCal.Calculate.UpdateFreeBous(bruce_lee, free_spin_num_array)
        ----记录record
        player.record.total_spin = player.record.total_spin + 1
        if is_free_spin then
            player.record.free_spin = player.record.free_spin + 1
        end

        -----记录free spin中总赢取
        if is_free_spin then
            bruce_lee.free_total_win = bruce_lee.free_total_win + win_chip
        else
            bruce_lee.free_total_win = 0
        end

        --if (win_chip > 0)
        -- then
        table.insert(all_prize_items, {prize_items = prize_items})
        table.insert(win_chips, win_chip)
        all_win_chip = win_chip + all_win_chip
        -- end
        if (loop_num == 0) then
            response.item_ids = item_ids
        end
        loop_num = loop_num + 1
    end

    --广播
    local win_info = {
        bet_amount = amount,
        total_bet = amount * LineNum,
        win_chip = total_win_chip
    }
    Communication:OnBcEvent(session, BroadcastType.AllTypes.BruceLee, win_info, 15)

    local free_win_amount = 0
    if (is_free_spin) then
        free_win_amount = total_win_chip
    end

    if (not is_free_spin and is_get_free_spin) then
        bruce_lee.bouts_id = os.time()
    end

    local BruceLeePrizeConfig = CommonCal.Calculate.get_config(player, "BruceLeePrizeConfig")
    --accomplish tasks
    local task_req_data = {
        five_line = CommonCal.Calculate.GetFiveLineCount(all_prize_items),
        base_spin = not is_free_spin,
        free_spin = is_get_free_spin,
         --本次下注是否触发freespin
        win_amount = total_win_chip,
        bet_amount = amount * LineNum,
        max_bet = amount >= SlotsBruceLeeCal.Calculate.GetMaxBetAmount(player),
        free_win_amount = free_win_amount,
        epic_win = (total_win_chip / (amount * LineNum)) >= BruceLeePrizeConfig[3].min_multiple
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
    if ((total_win_chip / (amount * LineNum)) >= BruceLeePrizeConfig[3].min_multiple) then
        player.statistics.epicwin_num = player.statistics.epicwin_num + 1
    elseif ((total_win_chip / (amount * LineNum)) >= BruceLeePrizeConfig[2].min_multiple) then
        player.statistics.megawin_num = player.statistics.megawin_num + 1
    elseif ((total_win_chip / (amount * LineNum)) >= BruceLeePrizeConfig[1].min_multiple) then
        player.statistics.bigwin_num = player.statistics.bigwin_num + 1
    end

    Player:BroadCastChip(session, task, amount * LineNum, total_win_chip)

    response.freeze_list = all_freeze_items
    response.all_respin_items = all_respin_items
    response.all_prize_items = all_prize_items
    response.all_win_chip = all_win_chip
    response.win_chip = win_chips

    --buyloss的局数+1
    bruce_lee.spined_times = bruce_lee.spined_times + 1

    if total_win_chip > 0 then
        Player:Obtain(player, {"Chip", total_win_chip}, Reason.BRUCE_LEE_BET_CHIP_OBTAIN())

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
            freeze_list = all_freeze_items,
            all_respin_items = all_respin_items,
            win_chip = win_chips, --保证客户端字段名一致,win_chip实际上是个数组
            all_win_chip = all_win_chip,
            free_spin = rep_free_spin
        }

        RankHelper:ChallengeDailyBiggestWin(player, GameType.AllTypes.BruceLee, rep_data)
        RankHelper:ChallengeWeeklyBiggestWin(player, GameType.AllTypes.BruceLee, rep_data)
        --end
        ----记录record
        player.record.spin_won = player.record.spin_won + 1
        player.record.total_win = player.record.total_win + total_win_chip
        if total_win_chip > player.record.biggest_win then
            player.record.biggest_win = total_win_chip
        end
    end

    if (loop_num > 1) then
        local number = total_win_chip / (amount * LineNum)
        number = math.floor(number + 0.5)

        Spark:FeatureSpecialWin(
            player,
            {
                [1] = GameType.AllTypes.BruceLee,
                [2] = "BruceLee",
                [3] = is_free_spin and 1 or 0,
                [4] = "KongFuFeature",
                [5] = number
            }
        )
    end

    local can_multiply = SlotsGameCal.Calculate.WinChipInMultiply(total_win_chip)
    if (can_multiply) then
        if ((total_win_chip / (amount * LineNum)) >= BruceLeePrizeConfig[1].min_multiple and not is_free_spin) then
            response.is_multiply = CommonCal.Calculate.IsMultiply(session, total_win_chip)
        end

        if (total_win_chip / (amount * LineNum) >= BruceLeePrizeConfig[1].min_multiple and not is_free_spin) then
            RobotAction.BigWinAction(session, task)
        end
    end

    if (#free_spin_num_array > 0) then
        next_free_spin_type = tonumber(free_spin_num_array[1].free_spin_type)
    end
    bruce_lee.free_spin_type = next_free_spin_type
    --response.item_list = item_list

    local contest_id, room_id, table_id = unpack(string.split(bruce_lee.channel_id, "."))

    if (is_free_spin) then
        Spark:SlotsAward(
            player,
            {
                [1] = GameType.AllTypes.BruceLee,
                [2] = "BruceLee",
                [3] = table_id,
                [4] = bruce_lee.bouts_id,
                [5] = bruce_lee.bet_amount,
                [6] = total_win_chip,
                [7] = json.encode(origin_result),
                [8] = json.encode(all_respin_items),
                [9] = reel_file_name,
                [10] = bruce_lee.free_spin_bouts,
                [11] = CommonCal.Calculate.GetFiveLineCount(all_prize_items) > 0 and 1 or 0,
                [12] = player.record.total_spin,
                [13] = amount * LineNum
            }
        )
    else
        Spark:SlotsStart(
            player,
            {
                [1] = GameType.AllTypes.BruceLee,
                [2] = "BruceLee",
                [3] = table_id,
                [4] = bruce_lee.bouts_id,
                [5] = amount,
                [6] = amount * LineNum,
                [7] = total_win_chip,
                [8] = json.encode(origin_result),
                [9] = json.encode(all_respin_items),
                [10] = is_free_spin,
                [11] = reel_file_name,
                [12] = CommonCal.Calculate.GetFiveLineCount(all_prize_items) > 0 and 1 or 0,
                [13] = player.record.total_spin
            }
        )
    end

    response.ret = Return.OK()

    if (Base.Enviroment.pro_spec_t ~= "online" and GlobalSlotsTest[player.id] ~= nil) then
        local test_response = table.copy(response)
        test_response.free_spin_type = free_spin_type

        GlobalSlotsTest[player.id].response = json.encode(test_response)

        Task:Work(
            function()
                CommonCal.Calculate.SlotsTestUpdate(player.id)
            end
        )
    end

    CommonCal.Calculate.EndStart(
        session,
        task,
        player,
        request,
        response,
        bruce_lee,
        LineNum,
        chip_cost,
        total_win_chip
    )

    --gain exp
    if not is_free_spin then
        local exp = chip_cost
        local exp_request = {
            type = "SlotsBruceLee",
            ante_gold = amount * LineNum,
            gain_exp = exp
        }
        Player:GainExp(session, exp_request)
    end

    player_slots_info.content = json.encode(bruce_lee)
    CommonCal.Calculate.UpdateSlotsToDbCache(task, player, player_slots_info)

    --锦标赛玩家得分更新
    CommonCal.Calculate.UpdateTournamentPlayerInfo(session, player.game_type, player, chip_cost, total_win_chip)

    response.player = {
        unlock_games = player.unlock_games,
        character = {
            chip = player.character.chip,
            experience = player.character.experience,
            level = player.character.level
        },
        bruce_lee = {
            bet_amount = amount,
            bonus_progress = bruce_lee.bonus_progress,
            free_spin_bouts = bruce_lee.free_spin_bouts,
            free_total_win = bruce_lee.free_total_win,
            is_slots = bruce_lee.is_slots,
            free_spin_type = bruce_lee.free_spin_type
        }
    }

    return response
end

-----------------------------------------------
-- 退出房间
------------------------------------------------
Exit = function(_M, session, request)
    local response = {header = {router = "Response"}}

    local filter_ret = RequestFilter.Filter("SlotsBruceLee", "Exit", session, request, true)
    if filter_ret then
        response.ret = filter_ret
        return response
    end

    local player = session.player
    local task = session.task

    local old_chip = player.character.chip

    local player_slots_info = CommonCal.Calculate.get_slots_info(session, task, player, GameType.AllTypes.BruceLee)
    local bruce_lee = json.decode(player_slots_info.content)

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
            module_id = "SlotsBruceLeeContest",
            message_id = "SlotsBruceLeeContest_Exit_Request"
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
        BuyLoss:Trigger(session, task, GameType.AllTypes.BruceLee, player) ---当玩家钱减少到一定数量时，提示玩家充值
    if trigger_buyloss then
        bruce_lee.total_loss = total_loss
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
    bruce_lee.spined_times = 0

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
                bruce_lee = {
                    step_num = bruce_lee.step_num
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

    player_slots_info.content = json.encode(bruce_lee)
    CommonCal.Calculate.UpdateSlotsToDbCache(task, player, player_slots_info)
    LOG(RUN, INFO).Format("[SlotsBruceLee][Exit] ok player %s", player.id)
    return response
end
