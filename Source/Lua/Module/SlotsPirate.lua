require "Common/SlotsPirateCal"
require "Common/RequestFilter"
require "Module/DailyTask"
require "Common/RobotAction"
module("SlotsPirate", package.seeall)

-----------------------------------------------
-- 进入房间
------------------------------------------------
Enter = function(_M, session, request)
    local response = {header = {router = "Response"}}

    local filter_ret = RequestFilter.Filter("SlotsPirate", "Enter", session, request, true)
    if filter_ret then
        response.ret = filter_ret
        return response
    end
    local task = session.task
    local player = session.player

    local player_slots_info = CommonCal.Calculate.get_slots_info(session, task, player, GameType.AllTypes.Pirate)
    local pirate = json.decode(player_slots_info.content)

    CommonCal.Calculate.MakeUpInRoom(session, task)

    LOG(RUN, INFO).Format("[SlotsPirate][Enter] player %s", player.id)

    local isLock = CommonCal.Calculate.LevelReq(player, GameType.AllTypes.Pirate)
    if (isLock == 1) then
        response.ret = Return.LOCK_GAME()
        return response
    end

    pirate.bouts_id = 0
     --进场的时候把cd清空掉
    pirate.enter_chip = player.character.chip
    pirate.spined_times = 0
    pirate.step_num = 0

    local table_id = request.table_id
    local async_request = nil
    local game_room_config = GameRoomConfig[GameType.AllTypes.AgentBond]

    if (table_id and table_id > 0) then
        local channel_id = string.format("%s.%s.%s", "SlotsPirateContest", game_room_config.room_name, table_id)
        pirate.channel_id = channel_id
        async_request = {
            header = {
                router = "AsyncRequest",
                service_name = game_room_config.contest_client_name,
                task_id = task.id,
                module_id = "SlotsPirateContest",
                message_id = "SlotsPirateContest_Enter_Request"
            },
            player = {
                id = player.id,
                user = player.user,
                account = player.account,
                game_type = GameType.AllTypes.Pirate,
                character = {
                    chip = player.character.chip,
                    vip = player.character.vip,
                    level = player.character.level,
                    experience = player.character.experience,
                    player_type = player.character.player_type
                },
                record = player.record,
                pirate = pirate
            }
        }
    else
        async_request = {
            header = {
                router = "AsyncRequest",
                service_name = game_room_config.contest_client_name,
                task_id = task.id,
                module_id = "SlotsPirateContest",
                message_id = "SlotsPirateContest_Enter_Request"
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
                pirate = pirate
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

    pirate.channel_id = async_response.channel_id

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
        pirate = pirate,
        character = {
            chip = player.character.chip
        }
    }
    player.game_type = GameType.AllTypes.Pirate

    -----------------紧急修复-------------------
    if (pirate.free_spin_bouts > 50) then
        pirate.free_spin_bouts = 0
    end

    player_slots_info.content = json.encode(pirate)
    CommonCal.Calculate.UpdateSlotsToDbCache(task, player, player_slots_info)

    return response, table_sync_notice
end

Slots = function(_M, session, request)
    local response = {header = {router = "Response"}}

    local filter_ret = RequestFilter.Filter("SlotsPirate", "Slots", session, request, true)
    if filter_ret then
        response.ret = filter_ret
        return response
    end
    local LineNum = #SlotsPirateCal.Const.Lines
    local task = session.task
    local amount = request.amount * LineNum
    local player = session.player

    local player_slots_info = CommonCal.Calculate.get_slots_info(session, task, player, GameType.AllTypes.Pirate)
    local pirate = json.decode(player_slots_info.content)

    if GlobalState:IsSlotsMaintenance(session, task, player.id) == 1 then
        response.ret = Return.SERVER_NEAR_MAINENANCE()
        return response
    end

    if (pirate.is_slots <= 0) then
        response.ret = Return.PIRATE_BONUS_PROGRESS_NOT_ENOUGH()
        return response
    end

    local old_chip = player.character.chip

    local game_room_config = GameRoomConfig[player.game_type]

    local step_num_array = {[1] = 0.1, [2] = 0.1, [3] = 0.1, [4] = 0.1, [5] = 0.1, [6] = 0.1}
    local step_num = math.rand_weight(player, step_num_array)

    local PirateSlotsConfig = CommonCal.Calculate.get_config(player, "PirateSlotsConfig")

    local step_max = #PirateSlotsConfig
    local old_step_num = pirate.step_num
    pirate.step_num = pirate.step_num + step_num
    pirate.step_num = (pirate.step_num - 1) % step_max + 1

    local slotsConfigInfo = PirateSlotsConfig[pirate.step_num]

    local winAmount = amount

    if (pirate.step_num < old_step_num) then
        winAmount = winAmount * (slotsConfigInfo.bet_num + 5)
    else
        winAmount = winAmount * slotsConfigInfo.bet_num
    end

    local line_num = #SlotsPirateCal.Const.Lines
    local number = winAmount / (pirate.bet_amount * line_num)
    CommonCal.Calculate.CalBonusAward(player, number)

    local async_request = {
        header = {
            router = "AsyncRequest",
            service_name = game_room_config.contest_client_name,
            task_id = task.id,
            module_id = "SlotsPirateContest",
            message_id = "SlotsPirateContest_Slots_Request"
        },
        player = {
            id = player.id,
            pirate = {
                step_num = pirate.step_num
            }
        }
    }
    local async_response = session:ContactPacket(task, async_request)

    if (winAmount > 0) then
        Player:Obtain(player, {"Chip", winAmount}, Reason.PIRATE_BET_CHIP_Slots())

        local task_req_data = {
            bonus_win_amount = winAmount
        }
        DailyTask:CompleteTask(session, player, task_req_data)
    end

    if (slotsConfigInfo.free_spin_num > 0) then
        local task_req_data = {
            free_spin = true
         --本次下注是否触发freespin
        }
        DailyTask:CompleteTask(session, player, task_req_data)

        pirate.free_spin_num = slotsConfigInfo.free_spin_num
        pirate.free_spin_bouts = pirate.free_spin_bouts + slotsConfigInfo.free_spin_num
        response.free_spin_num = slotsConfigInfo.free_spin_num
    end

    pirate.is_slots = 0
    response.bet_num = slotsConfigInfo.bet_num
    response.bet_multiple_num = slotsConfigInfo.bet_multiple_num
    response.win_amount = winAmount
    response.step_num = pirate.step_num

    response.ret = Return.OK()

    response.player = {
        pirate = {
            free_spin_bouts = pirate.free_spin_bouts
        },
        character = {
            chip = player.character.chip
        }
    }

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
                pirate = {
                    step_num = pirate.step_num
                }
            },
            collect_chip = player.character.chip - old_chip
        }
    )

    local table_sync_notice = {
        header = {
            router = "Notice"
        },
        table = async_response.table
    }

    Spark:PirateSlots(
        player,
        {
            [1] = contest_id,
            [2] = room_id,
            [3] = table_id,
            [4] = pirate.bouts_id,
            [5] = amount,
            [6] = amount * LineNum,
            [7] = winAmount,
            [8] = pirate.step_num
        }
    )

    --锦标赛玩家得分更新
    CommonCal.Calculate.UpdateTournamentPlayerInfo(session, player.game_type, player, 0, winAmount)

    player_slots_info.content = json.encode(pirate)
    CommonCal.Calculate.UpdateSlotsToDbCache(task, player, player_slots_info)

    return response, table_sync_notice
end

--开始slots
Start = function(_M, session, request)
    local response = {header = {router = "Response"}}

    local filter_ret = RequestFilter.Filter("SlotsPirate", "Start", session, request, true)
    if filter_ret then
        response.ret = filter_ret
        return response
    end

    local is_get_free_spin = false

    local LineNum = #SlotsPirateCal.Const.Lines
    local task = session.task
    local amount
    local player = session.player

    local player_slots_info = CommonCal.Calculate.get_slots_info(session, task, player, GameType.AllTypes.Pirate)
    local pirate = json.decode(player_slots_info.content)

    CommonCal.Calculate.BeginStart(session, task, player)

    if GlobalState:IsSlotsMaintenance(session, task, player.id) == 1 then
        response.ret = Return.SERVER_NEAR_MAINENANCE()
        return response
    end

    if (player.game_type ~= GameType.AllTypes.Pirate) then
        response.ret = Return.HAVE_ALREADY_EXIT_GAME()
        return response
    end
    local is_lock = CommonCal.Calculate.IsAppear(player)
    if (is_lock == 1) then
        response.ret = Return.LOCK_GAME()
        return response
    end
    local is_free_spin = pirate.free_spin_bouts > 0
    response.is_free_spin = is_free_spin and 1 or 0

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
    pirate.bouts_id = os.time()

    local hasWild = 1

    --free spin不扣钱, free spin下amount不会改
    local chip_cost = 0
    if is_free_spin then
        amount = pirate.bet_amount
        pirate.free_spin_bouts = math.max(pirate.free_spin_bouts - 1, 0)
    else
        amount = request.amount
        chip_cost = amount * LineNum

        if not Player:Consume(player, {"Chip", chip_cost}, Reason.PIRATE_BET_CHIP_CONSUME()) then
            response.ret = Return.GAME_PLAYER_CHIP_NOT_ENOUGH()
            return response
        end

        pirate.bet_amount = amount
    end

    local PirateBetAmountConfig = CommonCal.Calculate.get_config(player, "PirateBetAmountConfig")
    local bet_amount_conf
    for k, v in ipairs(PirateBetAmountConfig) do
        if v.single_amount == amount then
            bet_amount_conf = v
            break
        end
    end

    local origin_result, extra_wild, reel_file_name
    local wild = {{}, {}, {}, {}, {}}
    local result = {{}, {}, {}, {}, {}}
    local item_list = {}
    local all_prize_items = {}
    local loop_num = 0
    local oldIndex = 0
    local total_win_chip = 0
    pirate.is_slots = 0
    while hasWild == 1 do
        CommonCal.Calculate.SetLoopNum(player.id, loop_num)
        if is_free_spin then
            origin_result, oldIndex, reel_file_name =
                SlotsPirateCal.Calculate.GenItemResult(player, result, wild, pirate.free_spin_num, loop_num, oldIndex)
        else
            origin_result, oldIndex, reel_file_name =
                SlotsPirateCal.Calculate.GenItemResult(player, result, wild, 0, loop_num, oldIndex)
        end

        local prize_items, total_payrate = SlotsPirateCal.Calculate.GenPrizeInfo(player, origin_result)
        local item_ids = SlotsPirateCal.Calculate.TransResultToList(origin_result)

        table.insert(all_prize_items, prize_items)
        local win_chip = total_payrate * amount
        total_win_chip = total_win_chip + win_chip

        local is_slots = SlotsPirateCal.Calculate.IsSlots(origin_result)

        if (loop_num == 0) then
            hasWild = SlotsPirateCal.Calculate.Has2And4Wild(origin_result)
        else
            hasWild = 0
        end
        if (is_slots == 1) then
            pirate.is_slots = is_slots

            if (player.character.player_type == tonumber(ConstValue[5].value)) then
                local request = {}
                request.header = {}

                request.amount = amount
                Slots(nil, session, request)
            end
        end

        ----记录record
        player.record.total_spin = player.record.total_spin + 1
        if is_free_spin then
            player.record.free_spin = player.record.free_spin + 1
        end

        -----记录free spin中总赢取
        if is_free_spin then
            pirate.free_total_win = pirate.free_total_win + win_chip
        else
            pirate.free_total_win = 0
        end

        if (loop_num > 0) then
            local SlotsPirate_Item = {}
            SlotsPirate_Item.item_ids = item_ids
            SlotsPirate_Item.prize_items = prize_items
            SlotsPirate_Item.win_chip = win_chip
            table.insert(item_list, SlotsPirate_Item)
        else
            response.item_ids = item_ids
            response.prize_items = prize_items
            response.win_chip = win_chip
        end
        loop_num = loop_num + 1
    end

    DailyMissionsCal.Calculate.UpdateGameDailyMissions(
        session,
        player,
        amount,
        chip_cost,
        total_win_chip,
        is_free_spin,
        player.game_type,
        0
    )

    --广播
    local win_info = {
        bet_amount = amount,
        total_bet = amount * LineNum,
        win_chip = total_win_chip
    }
    Communication:OnBcEvent(session, BroadcastType.AllTypes.Pirate, win_info, 15)

    local free_win_amount = 0
    if (is_free_spin) then
        free_win_amount = total_win_chip
    end

    local PiratePrizeConfig = CommonCal.Calculate.get_config(player, "PiratePrizeConfig")

    --accomplish tasks
    local task_req_data = {
        five_line = CommonCal.Calculate.GetFiveLineCount(all_prize_items),
        base_spin = not is_free_spin,
        win_amount = total_win_chip,
        bet_amount = amount * LineNum,
        max_bet = amount >= SlotsPirateCal.Calculate.GetMaxBetAmount(player),
        bonus_game = pirate.is_slots > 0,
        free_win_amount = free_win_amount,
        epic_win = (total_win_chip / (amount * LineNum)) >= PiratePrizeConfig[3].min_multiple
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
    if ((total_win_chip / (amount * LineNum)) >= PiratePrizeConfig[3].min_multiple) then
        player.statistics.epicwin_num = player.statistics.epicwin_num + 1
    elseif ((total_win_chip / (amount * LineNum)) >= PiratePrizeConfig[2].min_multiple) then
        player.statistics.megawin_num = player.statistics.megawin_num + 1
    elseif ((total_win_chip / (amount * LineNum)) >= PiratePrizeConfig[1].min_multiple) then
        player.statistics.bigwin_num = player.statistics.bigwin_num + 1
    end
    if (pirate.is_slots > 0) then
        player.statistics.bonus_game_num = player.statistics.bonus_game_num + 1
    end

    Player:BroadCastChip(session, task, amount * LineNum, total_win_chip)

    --buyloss的局数+1
    pirate.spined_times = pirate.spined_times + 1

    if total_win_chip > 0 then
        Player:Obtain(player, {"Chip", total_win_chip}, Reason.PIRATE_BET_CHIP_OBTAIN())

        --记录每日、每周赢钱,进排行榜
        RankHelper:ChallengeDailyWin(player)
        RankHelper:ChallengeWeeklyWin(player)
        --free spin不计入biggest win的统计
        --if not is_free_spin then
        local rep_free_spin = 0
        if (is_free_spin) then
            rep_free_spin = 1
        end
        local rep_data = {
            item_list = item_list,
            item_ids = response.item_ids,
            prize_items = response.prize_items,
            win_chip = response.win_chip,
            all_win_chip = total_win_chip,
            bet_amount = amount,
            free_spin = rep_free_spin
        }
        RankHelper:ChallengeDailyBiggestWin(player, GameType.AllTypes.Pirate, rep_data)
        RankHelper:ChallengeWeeklyBiggestWin(player, GameType.AllTypes.Pirate, rep_data)
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
                [1] = GameType.AllTypes.Pirate,
                [2] = "Pirate",
                [3] = is_free_spin and 1 or 0,
                [4] = "WildRespinFeature",
                [5] = number
            }
        )
    end

    local can_multiply = SlotsGameCal.Calculate.WinChipInMultiply(total_win_chip)
    if (can_multiply) then
        if ((total_win_chip / (amount * LineNum)) >= PiratePrizeConfig[2].min_multiple and not is_free_spin) then
            response.is_multiply = CommonCal.Calculate.IsMultiply(session, total_win_chip)
        end

        if ((total_win_chip / (amount * LineNum)) >= PiratePrizeConfig[1].min_multiple and not is_free_spin) then
            RobotAction.BigWinAction(session, task)
        end
    end

    response.item_list = item_list

    local contest_id, room_id, table_id = unpack(string.split(pirate.channel_id, "."))
    local feature_items = {}
    for k, v in ipairs(item_list) do
        table.insert(feature_items, v.item_ids)
    end

    if (is_free_spin) then
        Spark:SlotsAward(
            player,
            {
                [1] = GameType.AllTypes.Pirate,
                [2] = "Pirate",
                [3] = table_id,
                [4] = pirate.bouts_id,
                [5] = pirate.bet_amount,
                [6] = total_win_chip,
                [7] = json.encode(origin_result),
                [8] = json.encode(feature_items),
                [9] = reel_file_name,
                [10] = pirate.free_spin_bouts,
                [11] = CommonCal.Calculate.GetFiveLineCount(all_prize_items) > 0 and 1 or 0,
                [12] = player.record.total_spin,
                [13] = amount * LineNum
            }
        )
    else
        Spark:SlotsStart(
            player,
            {
                [1] = GameType.AllTypes.Pirate,
                [2] = "Pirate",
                [3] = table_id,
                [4] = pirate.bouts_id,
                [5] = amount,
                [6] = amount * LineNum,
                [7] = total_win_chip,
                [8] = json.encode(origin_result),
                [9] = json.encode(feature_items),
                [10] = is_free_spin,
                [11] = reel_file_name,
                [12] = CommonCal.Calculate.GetFiveLineCount(all_prize_items) > 0 and 1 or 0,
                [13] = player.record.total_spin
            }
        )
    end

    CommonCal.Calculate.EndStart(session, task, player, request, response, pirate, LineNum, chip_cost, total_win_chip)

    --gain exp
    if not is_free_spin then
        local exp = chip_cost
        local exp_request = {
            type = "SlotsPirate",
            ante_gold = amount * LineNum,
            gain_exp = exp
        }
        Player:GainExp(session, exp_request)
    end

    player_slots_info.content = json.encode(pirate)
    CommonCal.Calculate.UpdateSlotsToDbCache(task, player, player_slots_info)

    --锦标赛玩家得分更新
    CommonCal.Calculate.UpdateTournamentPlayerInfo(session, player.game_type, player, chip_cost, total_win_chip)

    response.ret = Return.OK()

    response.player = {
        unlock_games = player.unlock_games,
        character = {
            chip = player.character.chip,
            experience = player.character.experience,
            level = player.character.level
        },
        pirate = {
            bet_amount = amount,
            bonus_progress = pirate.bonus_progress,
            free_spin_bouts = pirate.free_spin_bouts,
            free_total_win = pirate.free_total_win,
            is_slots = pirate.is_slots
        }
    }

    return response
end

-----------------------------------------------
-- 退出房间
------------------------------------------------
Exit = function(_M, session, request)
    local response = {header = {router = "Response"}}

    local filter_ret = RequestFilter.Filter("SlotsPirate", "Exit", session, request, true)
    if filter_ret then
        response.ret = filter_ret
        return response
    end

    local player = session.player
    local task = session.task

    local player_slots_info = CommonCal.Calculate.get_slots_info(session, task, player, GameType.AllTypes.Pirate)
    local pirate = json.decode(player_slots_info.content)

    local game_room_config = GameRoomConfig[player.game_type]
    if (game_room_config == nil) then
        response.ret = Return.HAVE_ALREADY_EXIT_GAME()
        return response
    end

    local old_chip = player.character.chip

    local async_request = {
        header = {
            router = "AsyncRequest",
            service_name = game_room_config.contest_client_name,
            task_id = task.id,
            module_id = "SlotsPirateContest",
            message_id = "SlotsPirateContest_Exit_Request"
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
        BuyLoss:Trigger(session, task, GameType.AllTypes.Pirate, player) ---当玩家钱减少到一定数量时，提示玩家充值
    if trigger_buyloss then
        pirate.total_loss = total_loss
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
    pirate.spined_times = 0

    pirate.step_num = 0

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
                pirate = {
                    step_num = pirate.step_num
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
    LOG(RUN, INFO).Format("[SlotsPirate][Exit] ok player %s, game type is: %s", player.id, player.game_type)

    player_slots_info.content = json.encode(pirate)
    CommonCal.Calculate.UpdateSlotsToDbCache(task, player, player_slots_info)

    return response
end
