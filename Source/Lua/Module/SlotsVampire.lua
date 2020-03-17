require "Common/SlotsVampireCal"
require "Common/RequestFilter"
require "Module/DailyTask"
require "Common/RobotAction"
require "Common/DailyMissionsCal"
module("SlotsVampire", package.seeall)

-----------------------------------------------
-- 进入房间
------------------------------------------------
Enter = function(_M, session, request)
    local response = {header = {router = "Response"}}
    local filter_ret = RequestFilter.Filter("SlotsVampire", "Enter", session, request, true)
    if filter_ret then
        response.ret = filter_ret
        return response
    end
    local task = session.task
    local player = session.player
    local player_slots_info = CommonCal.Calculate.get_slots_info(session, task, player, GameType.AllTypes.Vampire)
    local vampire = json.decode(player_slots_info.content)
    CommonCal.Calculate.MakeUpInRoom(session, task)
    local isLock = CommonCal.Calculate.LevelReq(player, GameType.AllTypes.Vampire)
    if (isLock == 1) then
        response.ret = Return.LOCK_GAME()
        return response
    end

    local table_id = request.table_id
    local async_request = nil
    local game_room_config = GameRoomConfig[GameType.AllTypes.Vampire]

    if (table_id and table_id > 0) then
        local channel_id = string.format("%s.%s.%s", "SlotsVampireContest", game_room_config.room_name, table_id)
        vampire.channel_id = channel_id
        async_request = {
            header = {
                router = "AsyncRequest",
                service_name = game_room_config.contest_client_name,
                task_id = task.id,
                module_id = "SlotsVampireContest",
                message_id = "SlotsVampireContest_Enter_Request"
            },
            player = {
                id = player.id,
                user = player.user,
                account = player.account,
                game_type = GameType.AllTypes.Vampire,
                character = {
                    chip = player.character.chip,
                    vip = player.character.vip,
                    level = player.character.level,
                    experience = player.character.experience,
                    player_type = player.character.player_type
                },
                record = player.record,
                vampire = vampire
            }
        }
    else
        async_request = {
            header = {
                router = "AsyncRequest",
                service_name = game_room_config.contest_client_name,
                task_id = task.id,
                module_id = "SlotsVampireContest",
                message_id = "SlotsVampireContest_Enter_Request"
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
                vampire = vampire
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
    vampire.channel_id = async_response.channel_id

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

    vampire.bouts_id = 0
     --进场的时候把cd清空掉
    vampire.enter_chip = player.character.chip
    vampire.spined_times = 0

    response.ret = Return.OK()
    response.player = {
        vampire = vampire,
        character = {
            chip = player.character.chip
        }
    }
    player.game_type = GameType.AllTypes.Vampire

    player_slots_info.content = json.encode(vampire)
    CommonCal.Calculate.UpdateSlotsToDbCache(task, player, player_slots_info)
    return response, table_sync_notice
end

--开始slots
Start = function(_M, session, request)
    local response = {header = {router = "Response"}}

    local filter_ret = RequestFilter.Filter("SlotsVampire", "Start", session, request, true)
    if filter_ret then
        response.ret = filter_ret
        return response
    end

    local task = session.task
    local amount
    local player = session.player

    local player_slots_info = CommonCal.Calculate.get_slots_info(session, task, player, GameType.AllTypes.Vampire)
    local vampire = json.decode(player_slots_info.content)

    CommonCal.Calculate.BeginStart(session, task, player)

    if GlobalState:IsSlotsMaintenance(session, task, player.id) == 1 then
        response.ret = Return.SERVER_NEAR_MAINENANCE()
        return response
    end

    if (player.game_type ~= GameType.AllTypes.Vampire) then
        response.ret = Return.HAVE_ALREADY_EXIT_GAME()
        return response
    end
    local is_lock = CommonCal.Calculate.IsAppear(player)
    if (is_lock == 1) then
        response.ret = Return.LOCK_GAME()
        return response
    end
    local all_prize_items = {}
    local is_free_spin = vampire.free_spin_bouts > 0
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

    local chipAmount = 0
    local chip_cost = 0
    --free spin不扣钱, free spin下amount不会改
    if is_free_spin then
        amount = vampire.bet_amount
        chipAmount = amount * 25
        vampire.free_spin_bouts = math.max(vampire.free_spin_bouts - 1, 0)
    else
        amount = request.amount
        chip_cost = amount * 25
        chipAmount = amount * 25

        if not Player:Consume(player, {"Chip", chip_cost}, Reason.VAMPIRE_BET_CHIP_CONSUME()) then
            response.ret = Return.GAME_PLAYER_CHIP_NOT_ENOUGH()
            return response
        end
        vampire.bet_amount = amount
    end

    CommonCal.Calculate.SetLoopNum(player.id, 0)
    --第一次生成items
    local origin_result, reel_file_name = SlotsVampireCal.Calculate.GenItemResult(player, is_free_spin)
    local can_merge, merge_indexes = SlotsVampireCal.Calculate.CanMergeVampire(origin_result)
    local prize_items, origin_total_payrate =
        SlotsVampireCal.Calculate.GenPrizeInfo(player, origin_result, merge_indexes)
    table.insert(all_prize_items, prize_items)
    local total_payrate = origin_total_payrate
    local respin_payrate = 0
    local rep_result
    local is_special_win = false
    if can_merge and merge_indexes then
        CommonCal.Calculate.SetLoopNum(player.id, 1)
        local col_1_items, col_5_items = SlotsVampireCal.Calculate.RespinSideLines(player, is_free_spin)
        response.can_merge = 1
        response.merge_indexes = SlotsVampireCal.Calculate.TranMergeItemToList(merge_indexes)
        response.col_1_items = col_1_items
        response.col_5_items = col_5_items
        rep_result = SlotsVampireCal.Calculate.ReplaceSideLines(origin_result, col_1_items, col_5_items)
        local respin_prize_items, respin_total_payrate =
            SlotsVampireCal.Calculate.GenPrizeInfo(player, rep_result, merge_indexes)
        table.insert(all_prize_items, respin_prize_items)
        response.respin_prize_items = respin_prize_items
        --total_payrate = total_payrate + respin_total_payrate
        respin_payrate = respin_total_payrate

        is_special_win = true
    else
        response.can_merge = 0
    end

    local free_spin_bouts = SlotsVampireCal.Calculate.GenFreeSpinCount(player, origin_result)
    vampire.free_spin_bouts = vampire.free_spin_bouts + free_spin_bouts

    if (not is_free_spin and free_spin_bouts > 0) then
        vampire.bouts_id = os.time()
    end

    response.item_ids = SlotsVampireCal.Calculate.TransResultToList(origin_result)
    response.prize_items = prize_items
    response.ret = Return.OK()

    local VampireBetAmountConfig = CommonCal.Calculate.get_config(player, "VampireBetAmountConfig")
    local bet_amount_conf
    for k, v in ipairs(VampireBetAmountConfig) do
        if v.single_amount == amount then
            bet_amount_conf = v
            break
        end
    end
    ----记录record
    player.record.total_spin = player.record.total_spin + 1
    if is_free_spin then
        player.record.free_spin = player.record.free_spin + 1
    end

    local win_chip = total_payrate * amount
    local respin_win_chip = respin_payrate * amount
    local total_win_chip = win_chip + respin_win_chip

    if total_win_chip > 0 then
        Player:Obtain(player, {"Chip", total_win_chip}, Reason.VAMPIRE_BET_CHIP_OBTAIN())

        --记录每日、每周赢钱,进排行榜
        RankHelper:ChallengeDailyWin(player)
        RankHelper:ChallengeWeeklyWin(player)
        --free spin不计入biggest win的统计
        -- if not is_free_spin then
        local rep_free_spin = 0
        if (is_free_spin) then
            rep_free_spin = 1
        end
        local rep_data = {
            item_ids = response.item_ids,
            can_merge = response.can_merge,
            merge_indexes = response.merge_indexes,
            col_1_items = response.col_1_items,
            col_5_items = response.col_5_items,
            prize_items = response.prize_items,
            respin_prize_items = response.respin_prize_items,
            win_chip = win_chip,
            all_win_chip = total_win_chip,
            total_payrate = total_payrate,
            bet_amount = amount,
            free_spin = rep_free_spin,
            respin_win_chip = respin_win_chip
        }
        RankHelper:ChallengeDailyBiggestWin(player, GameType.AllTypes.Vampire, rep_data)
        RankHelper:ChallengeWeeklyBiggestWin(player, GameType.AllTypes.Vampire, rep_data)
        --end
        ----记录record
        player.record.spin_won = player.record.spin_won + 1
        player.record.total_win = player.record.total_win + total_win_chip
        if total_win_chip > player.record.biggest_win then
            player.record.biggest_win = total_win_chip
        end
    end

    if (is_special_win) then
        local number = total_win_chip / (amount * 25)
        number = math.floor(number + 0.5)

        Spark:FeatureSpecialWin(
            player,
            {
                [1] = player.game_type,
                [2] = "Vampire",
                [3] = is_free_spin and 1 or 0,
                [4] = "RespinFeature",
                [5] = number
            }
        )
    end

    -----记录free spin中总赢取
    if is_free_spin then
        vampire.free_total_win = vampire.free_total_win + total_win_chip
    else
        vampire.free_total_win = 0
    end

    DailyMissionsCal.Calculate.UpdateGameDailyMissions(
        session,
        player,
        amount,
        chip_cost,
        win_chip,
        is_free_spin,
        player.game_type,
        free_spin_bouts
    )

    local free_win_amount = 0
    if (is_free_spin) then
        free_win_amount = total_win_chip
    end

    local VampirePrizeConfig = CommonCal.Calculate.get_config(player, "VampirePrizeConfig")
    --accomplish tasks
    local task_req_data = {
        five_line = CommonCal.Calculate.GetFiveLineCount(all_prize_items),
        base_spin = not is_free_spin,
        free_spin = free_spin_bouts > 0,
         --本次下注是否属于freespin
        win_amount = total_win_chip,
        bet_amount = amount * 25,
        max_bet = amount >= SlotsVampireCal.Calculate.GetMaxBetAmount(player),
        free_win_amount = free_win_amount,
        epic_win = (total_win_chip / chipAmount) >= VampirePrizeConfig[3].min_multiple
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
    if ((win_chip / (amount * 25)) >= VampirePrizeConfig[3].min_multiple) then
        player.statistics.epicwin_num = player.statistics.epicwin_num + 1
    elseif ((win_chip / (amount * 25)) >= VampirePrizeConfig[2].min_multiple) then
        player.statistics.megawin_num = player.statistics.megawin_num + 1
    elseif ((win_chip / (amount * 25)) >= VampirePrizeConfig[1].min_multiple) then
        player.statistics.bigwin_num = player.statistics.bigwin_num + 1
    end

    Player:BroadCastChip(session, task, amount * 25, total_win_chip)

    local can_multiply = SlotsGameCal.Calculate.WinChipInMultiply(total_win_chip)
    if (can_multiply) then
        if ((total_win_chip / chipAmount) >= VampirePrizeConfig[2].min_multiple and not is_free_spin) then
            response.is_multiply = CommonCal.Calculate.IsMultiply(session, total_win_chip)
        end

        if ((total_win_chip / chipAmount) >= VampirePrizeConfig[1].min_multiple and not is_free_spin) then
            RobotAction.BigWinAction(session, task)
        end
    end

    --广播
    local win_info = {
        bet_amount = amount,
        total_bet = amount * 25,
        win_chip = total_win_chip
    }
    Communication:OnBcEvent(session, BroadcastType.AllTypes.VampireSpin, win_info, 15)

    --opt
    local contest_id, room_id, table_id = unpack(string.split(vampire.channel_id, "."))

    if (is_free_spin) then
        Spark:SlotsAward(
            player,
            {
                [1] = GameType.AllTypes.Vampire,
                [2] = "Vampire",
                [3] = table_id,
                [4] = vampire.bouts_id,
                [5] = vampire.bet_amount,
                [6] = win_chip,
                [7] = json.encode(origin_result),
                [8] = "[]",
                [9] = reel_file_name,
                [10] = vampire.free_spin_bouts,
                [11] = CommonCal.Calculate.GetFiveLineCount(all_prize_items) > 0 and 1 or 0,
                [12] = player.record.total_spin,
                [13] = amount * 25
            }
        )
    else
        Spark:SlotsStart(
            player,
            {
                [1] = GameType.AllTypes.Vampire,
                [2] = "Vampire",
                [3] = table_id,
                [4] = vampire.bouts_id,
                [5] = amount,
                [6] = amount * 25,
                [7] = win_chip,
                [8] = json.encode(origin_result),
                [9] = "[]",
                [10] = is_free_spin,
                [11] = reel_file_name,
                [12] = CommonCal.Calculate.GetFiveLineCount(all_prize_items) > 0 and 1 or 0,
                [13] = player.record.total_spin
            }
        )
    end

    --buyloss的局数+1
    vampire.spined_times = vampire.spined_times + 1

    response.win_chip = win_chip
    response.respin_win_chip = respin_win_chip

    CommonCal.Calculate.EndStart(session, task, player, request, response, vampire, 25, chip_cost, win_chip)

    --gain exp
    if not is_free_spin then
        local exp = chip_cost
        local exp_request = {
            type = "SlotsVampire",
            ante_gold = amount * 25,
            gain_exp = exp
        }
        Player:GainExp(session, exp_request)
    end

    player_slots_info.content = json.encode(vampire)
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
        vampire = {
            bet_amount = amount,
            free_spin_bouts = vampire.free_spin_bouts,
            free_total_win = vampire.free_total_win
        }
    }

    return response
end

-----------------------------------------------
-- 退出房间
------------------------------------------------
Exit = function(_M, session, request)
    local response = {header = {router = "Response"}}
    local filter_ret = RequestFilter.Filter("SlotsVampire", "Exit", session, request, true)
    if filter_ret then
        response.ret = filter_ret
        return response
    end

    local player = session.player
    local task = session.task

    local player_slots_info = CommonCal.Calculate.get_slots_info(session, task, player, GameType.AllTypes.Vampire)
    local vampire = json.decode(player_slots_info.content)

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
            module_id = "SlotsVampireContest",
            message_id = "SlotsVampireContest_Exit_Request"
        },
        player_id = player.id
    }
    LOG(RUN, INFO).Format("[SlotsVampire][Exit] player %s start exit from SlotsVampireContest", player.id)
    local async_response = session:ContactPacket(task, async_request)
    if async_response.ret.code ~= 0 then
        response.ret = async_response.ret
        return response
    end
    --opt
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
        BuyLoss:Trigger(session, task, GameType.AllTypes.Vampire, player)
    if trigger_buyloss then
        vampire.total_loss = total_loss
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
    vampire.spined_times = 0

    response = {
        header = response.header,
        ret = Return.OK(),
        player = {
            character = {
                chip = player.character.chip
            }
        }
    }
    LOG(RUN, INFO).Format("[SlotsVampire][Exit] ok player %s, game type is: %s", player.id, player.game_type)

    player_slots_info.content = json.encode(vampire)
    CommonCal.Calculate.UpdateSlotsToDbCache(task, player, player_slots_info)

    return response
end
