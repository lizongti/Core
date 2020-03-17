require "Common/SlotsHalloweenNightCal"
require "Common/RequestFilter"
require "Module/DailyTask"
require "Module/SlotsHalloweenNightSpin"
require "Common/RobotAction"
require "Common/DailyMissionsCal"
module("SlotsHalloweenNight", package.seeall)

-----------------------------------------------
-- 进入房间
------------------------------------------------
Enter = function(_M, session, request)
    local response = {header = {router = "Response"}}
    local filter_ret = RequestFilter.Filter("SlotsHalloweenNight", "Enter", session, request, true)
    if filter_ret then
        response.ret = filter_ret
        return response
    end
    local task = session.task
    local player = session.player

    local player_slots_info =
        CommonCal.Calculate.get_slots_info(session, task, player, GameType.AllTypes.HalloweenNight)
    local halloween_night = json.decode(player_slots_info.content)

    CommonCal.Calculate.MakeUpInRoom(session, task)
    local isLock = CommonCal.Calculate.LevelReq(player, GameType.AllTypes.HalloweenNight)
    if (isLock == 1) then
        response.ret = Return.LOCK_GAME()
        return response
    end

    local table_id = request.table_id
    local async_request = nil
    local game_room_config = GameRoomConfig[GameType.AllTypes.HalloweenNight]

    if (table_id and table_id > 0) then
        local channel_id = string.format("%s.%s.%s", "SlotsHalloweenNightContest", game_room_config.room_name, table_id)
        halloween_night.channel_id = channel_id
        async_request = {
            header = {
                router = "AsyncRequest",
                service_name = game_room_config.contest_client_name,
                task_id = task.id,
                module_id = "SlotsHalloweenNightContest",
                message_id = "SlotsHalloweenNightContest_Enter_Request"
            },
            player = {
                id = player.id,
                user = player.user,
                account = player.account,
                game_type = GameType.AllTypes.HalloweenNight,
                character = {
                    chip = player.character.chip,
                    vip = player.character.vip,
                    level = player.character.level,
                    experience = player.character.experience,
                    player_type = player.character.player_type
                },
                record = player.record,
                halloween_night = halloween_night
            }
        }
    else
        async_request = {
            header = {
                router = "AsyncRequest",
                service_name = game_room_config.contest_client_name,
                task_id = task.id,
                module_id = "SlotsHalloweenNightContest",
                message_id = "SlotsHalloweenNightContest_Enter_Request"
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
                halloween_night = halloween_night
            }
        }
    end

    LOG(RUN, INFO).Format("[SlotsHalloweenNight][Enter] player %s start enter SlotsHalloweenNightContest", player.id)
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

    halloween_night.channel_id = async_response.channel_id

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

    halloween_night.bouts_id = 0
     --进场的时候把cd清空掉
    halloween_night.enter_chip = player.character.chip
    halloween_night.spined_times = 0

    response.ret = Return.OK()
    response.player = {
        halloween_night = halloween_night,
        character = {
            chip = player.character.chip
        }
    }

    player.game_type = GameType.AllTypes.HalloweenNight

    player_slots_info.content = json.encode(halloween_night)
    CommonCal.Calculate.UpdateSlotsToDbCache(task, player, player_slots_info)

    return response, table_sync_notice
end

--开始slots
Start = function(_M, session, request)
    local response = {header = {router = "Response"}}

    local filter_ret = RequestFilter.Filter("SlotsHalloweenNight", "Start", session, request, true)
    if filter_ret then
        response.ret = filter_ret
        return response
    end

    local LineNum = #SlotsHalloweenNightCal.Const.Lines

    local task = session.task
    local amount
    local player = session.player

    local player_slots_info =
        CommonCal.Calculate.get_slots_info(session, task, player, GameType.AllTypes.HalloweenNight)
    local halloween_night = json.decode(player_slots_info.content)

    CommonCal.Calculate.BeginStart(session, task, player)

    if GlobalState:IsSlotsMaintenance(session, task, player.id) == 1 then
        response.ret = Return.SERVER_NEAR_MAINENANCE()
        return response
    end

    if (player.game_type ~= GameType.AllTypes.HalloweenNight) then
        response.ret = Return.HAVE_ALREADY_EXIT_GAME()
        return response
    end
    local is_lock = CommonCal.Calculate.IsAppear(player)
    if (is_lock == 1) then
        response.ret = Return.LOCK_GAME()
        return response
    end
    local all_prize_items = {}
    local is_free_spin = halloween_night.free_spin_bouts > 0
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

    ------201810310936开始------------------

    local player_feature_condition = CommonCal.Calculate.get_feature_condition(session, task, player, player.game_type)
    ------201810310936结束------------------

    local isfreeze = 0
    --free spin不扣钱, free spin下amount不会改
    local chip_cost = 0
    if is_free_spin then
        ------201810310936开始------------------

        player_feature_condition.free_spin_count = player_feature_condition.free_spin_count + 1
        ------201810310936结束------------------
        amount = halloween_night.bet_amount

        halloween_night.free_spin_bouts = math.max(halloween_night.free_spin_bouts - 1, 0)
    else
        amount = request.amount

        chip_cost = amount * LineNum

        if not Player:Consume(player, {"Chip", chip_cost}, Reason.HALLOWEENNIGHT_BET_CHIP_CONSUME()) then
            response.ret = Return.GAME_PLAYER_CHIP_NOT_ENOUGH()
            return response
        end
    end

    --------------------------------------------------开始修改----------------------------------
    local extern_param = {}
    extern_param.chip_cost = chip_cost

    ----记录record
    player.record.total_spin = player.record.total_spin + 1
    if is_free_spin then
        player.record.free_spin = player.record.free_spin + 1
    end

    --local origin_result, win_chip, prize_items, free_spin_bouts, reel_file_name, slots_win_chip, res_sticky_wild_list, treasure_row, treasure_chip, sticky_wild_list, bet_amount_conf, total_payrate = SlotsHalloweenNightSpin.SpinProcess(player, game_type, is_free_spin, nil, amount)
    local origin_result,
        win_chip,
        all_prize_items,
        free_spin_bouts,
        formation_list,
        reel_file_name,
        slots_win_chip,
        special_parameter =
        SlotsHalloweenNightSpin.SpinProcess(
        player,
        game_type,
        is_free_spin,
        nil,
        amount,
        player_feature_condition,
        extern_param,
        halloween_night
    )

    local res_sticky_wild_list = special_parameter.res_sticky_wild_list
    local treasure_row = special_parameter.treasure_row
    local treasure_chip = special_parameter.treasure_chip
    local sticky_wild_list = special_parameter.sticky_wild_list
    local total_payrate = special_parameter.total_payrate

    if is_free_spin and SlotsHalloweenNightCal.Calculate.HasBigWild(origin_result) then
        response.has_big_wild = 1
    end

    if (not is_free_spin and free_spin_bouts > 0) then
        halloween_night.bouts_id = os.time()
    end

    local HalloweenNightBetAmountConfig = CommonCal.Calculate.get_config(player, "HalloweenNightBetAmountConfig")

    local bet_amount_conf
    for k, v in ipairs(HalloweenNightBetAmountConfig) do
        if v.single_amount == amount then
            bet_amount_conf = v
            break
        end
    end

    response.ret = Return.OK()
    response.item_ids = SlotsHalloweenNightCal.Calculate.TransResultToList(origin_result)
    response.sticky_wild_list = res_sticky_wild_list
    response.prize_items = all_prize_items[1]

    if (treasure_row > 0) then
        response.treasure_row = treasure_row
        response.treasure_chip = treasure_chip
    end

    if is_free_spin and SlotsHalloweenNightCal.Calculate.HasBigWild(origin_result) then
        response.has_big_wild = 1
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

    if win_chip > 0 then
        Player:Obtain(player, {"Chip", win_chip}, Reason.HALLOWEENNIGHT_BET_CHIP_OBTAIN())

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
            item_ids = response.item_ids,
            prize_items = response.prize_items,
            win_chip = win_chip,
            bet_amount = amount,
            treasure_chip = treasure_chip,
            treasure_row = treasure_index,
            cd_wild_index = halloween_night.cd_wild_index,
            cd_wild_times = halloween_night.cd_wild_times,
            sticky_wild_pos_list = halloween_night.sticky_wild_pos_list,
            free_spin = rep_free_spin
        }
        RankHelper:ChallengeDailyBiggestWin(player, GameType.AllTypes.HalloweenNight, rep_data)
        RankHelper:ChallengeWeeklyBiggestWin(player, GameType.AllTypes.HalloweenNight, rep_data)
        --end
        ----记录record
        player.record.spin_won = player.record.spin_won + 1
        player.record.total_win = player.record.total_win + win_chip
        if win_chip > player.record.biggest_win then
            player.record.biggest_win = win_chip
        end
    end

    if (halloween_night.cd_wild_times > 0) and CommonCal.Calculate.table_leng(sticky_wild_list) > 0 then
        local number = win_chip / (amount * LineNum)
        number = math.floor(number + 0.5)

        Spark:FeatureSpecialWin(
            player,
            {
                [1] = player.game_type,
                [2] = "HalloweenNight",
                [3] = is_free_spin and 1 or 0,
                [4] = "CountDownWildFeatureAndStickyWild",
                [5] = number
            }
        )
    elseif (halloween_night.cd_wild_times > 0) then
        local number = win_chip / (amount * LineNum)
        number = math.floor(number + 0.5)

        Spark:FeatureSpecialWin(
            player,
            {
                [1] = player.game_type,
                [2] = "HalloweenNight",
                [3] = is_free_spin and 1 or 0,
                [4] = "CountDownWildFeature",
                [5] = number
            }
        )
    elseif (CommonCal.Calculate.table_leng(sticky_wild_list) > 0) then
        local number = win_chip / (amount * LineNum)
        number = math.floor(number + 0.5)

        Spark:FeatureSpecialWin(
            player,
            {
                [1] = player.game_type,
                [2] = "HalloweenNight",
                [3] = is_free_spin and 1 or 0,
                [4] = "StickyWild",
                [5] = number
            }
        )
    end

    -----记录free spin中总赢取
    if is_free_spin then
        halloween_night.free_total_win = halloween_night.free_total_win + win_chip
    else
        halloween_night.free_total_win = 0
    end

    local free_win_amount = 0
    if (is_free_spin) then
        free_win_amount = win_chip
    end

    local HalloweenNightPrizeConfig = CommonCal.Calculate.get_config(player, "HalloweenNightPrizeConfig")
    --accomplish tasks
    local task_req_data = {
        five_line = CommonCal.Calculate.GetFiveLineCount(all_prize_items),
        base_spin = not is_free_spin,
        free_spin = free_spin_bouts > 0,
         --本次下注是否属于freespin
        win_amount = win_chip,
        bet_amount = amount * LineNum,
        max_bet = amount >= SlotsHalloweenNightCal.Calculate.GetMaxBetAmount(player),
        free_win_amount = free_win_amount,
        epic_win = (total_payrate / LineNum) >= HalloweenNightPrizeConfig[3].min_multiple
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
    if ((win_chip / (amount * LineNum)) >= HalloweenNightPrizeConfig[3].min_multiple) then
        player.statistics.epicwin_num = player.statistics.epicwin_num + 1
    elseif ((win_chip / (amount * LineNum)) >= HalloweenNightPrizeConfig[2].min_multiple) then
        player.statistics.megawin_num = player.statistics.megawin_num + 1
    elseif ((win_chip / (amount * LineNum)) >= HalloweenNightPrizeConfig[1].min_multiple) then
        player.statistics.bigwin_num = player.statistics.bigwin_num + 1
    end

    Player:BroadCastChip(session, task, amount * LineNum, win_chip)

    local can_multiply = SlotsGameCal.Calculate.WinChipInMultiply(win_chip)
    if (can_multiply) then
        if ((total_payrate / LineNum) >= HalloweenNightPrizeConfig[2].min_multiple and not is_free_spin) then
            response.is_multiply = CommonCal.Calculate.IsMultiply(session, win_chip)
        end

        if ((total_payrate / LineNum) >= HalloweenNightPrizeConfig[1].min_multiple and not is_free_spin) then
            RobotAction.BigWinAction(session, task)
        end
    end

    --广播
    local win_info = {
        bet_amount = amount,
        total_bet = amount * LineNum,
        win_chip = win_chip
    }
    Communication:OnBcEvent(session, BroadcastType.AllTypes.HalloweenNightSpin, win_info, 15)

    --opt
    local contest_id, room_id, table_id = unpack(string.split(halloween_night.channel_id, "."))
    if (is_free_spin) then
        Spark:SlotsAward(
            player,
            {
                [1] = GameType.AllTypes.HalloweenNight,
                [2] = "HalloweenNight",
                [3] = table_id,
                [4] = halloween_night.bouts_id,
                [5] = halloween_night.bet_amount,
                [6] = win_chip,
                [7] = json.encode(origin_result),
                [8] = "[]",
                [9] = reel_file_name,
                [10] = halloween_night.free_spin_bouts,
                [11] = CommonCal.Calculate.GetFiveLineCount(all_prize_items) > 0 and 1 or 0,
                [12] = player.record.total_spin,
                [13] = amount * LineNum
            }
        )
    else
        Spark:SlotsStart(
            player,
            {
                [1] = GameType.AllTypes.HalloweenNight,
                [2] = "HalloweenNight",
                [3] = table_id,
                [4] = halloween_night.bouts_id,
                [5] = amount,
                [6] = amount * LineNum,
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
    halloween_night.spined_times = halloween_night.spined_times + 1

    response.win_chip = win_chip

    halloween_night.bet_amount = amount

    CommonCal.Calculate.EndStart(
        session,
        task,
        player,
        request,
        response,
        halloween_night,
        LineNum,
        chip_cost,
        win_chip
    )

    --gain exp
    if not is_free_spin then
        local exp = chip_cost
        local exp_request = {
            type = "SlotsHalloweenNight",
            ante_gold = amount * LineNum,
            gain_exp = exp
        }
        Player:GainExp(session, exp_request)
    end

    player_slots_info.content = json.encode(halloween_night)
    CommonCal.Calculate.UpdateSlotsToDbCache(task, player, player_slots_info)

    ------201810310936开始------------------

    CommonCal.Calculate.UpdateToDbCache(task, player, "feature_condition", player_feature_condition)
    ------201810310936结束------------------

    --锦标赛玩家得分更新
    CommonCal.Calculate.UpdateTournamentPlayerInfo(session, player.game_type, player, chip_cost, win_chip)

    response.player = {
        unlock_games = player.unlock_games,
        character = {
            chip = player.character.chip,
            experience = player.character.experience,
            level = player.character.level
        },
        halloween_night = {
            bet_amount = amount,
            free_spin_bouts = halloween_night.free_spin_bouts,
            cd_wild_times = halloween_night.cd_wild_times,
            cd_wild_index = halloween_night.cd_wild_index,
            free_total_win = halloween_night.free_total_win
        }
    }

    return response
end

-----------------------------------------------
-- 退出房间
------------------------------------------------
Exit = function(_M, session, request)
    local response = {header = {router = "Response"}}
    local filter_ret = RequestFilter.Filter("SlotsHalloweenNight", "Exit", session, request, true)
    if filter_ret then
        response.ret = filter_ret
        return response
    end

    local player = session.player
    local task = session.task

    local player_slots_info =
        CommonCal.Calculate.get_slots_info(session, task, player, GameType.AllTypes.HalloweenNight)
    local halloween_night = json.decode(player_slots_info.content)

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
            module_id = "SlotsHalloweenNightContest",
            message_id = "SlotsHalloweenNightContest_Exit_Request"
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
        BuyLoss:Trigger(session, task, GameType.AllTypes.HalloweenNight, player)
    if trigger_buyloss then
        halloween_night.total_loss = total_loss

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

    halloween_night.spined_times = 0
    response = {
        header = response.header,
        ret = Return.OK(),
        player = {
            character = {
                chip = player.character.chip
            }
        }
    }
    LOG(RUN, INFO).Format("[SlotsHalloweenNight][Exit] ok player %s, game type is: %s", player.id, player.game_type)

    player_slots_info.content = json.encode(halloween_night)
    CommonCal.Calculate.UpdateSlotsToDbCache(task, player, player_slots_info)

    return response
end
