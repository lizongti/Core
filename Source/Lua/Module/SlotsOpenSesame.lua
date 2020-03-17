require "Common/SlotsOpenSesameCal"
require "Common/RequestFilter"
require "Module/DailyTask"
require "Common/RobotAction"
require "Common/DailyMissionsCal"
module("SlotsOpenSesame", package.seeall)

-----------------------------------------------
-- 进入房间
------------------------------------------------
Enter = function(_M, session, request)
    local response = {header = {router = "Response"}}
    local filter_ret = RequestFilter.Filter("SlotsOpenSesame", "Enter", session, request, true)
    if filter_ret then
        response.ret = filter_ret
        return response
    end
    local task = session.task
    local player = session.player

    local player_slots_info = CommonCal.Calculate.get_slots_info(session, task, player, GameType.AllTypes.OpenSesame)
    local open_sesame = json.decode(player_slots_info.content)

    CommonCal.Calculate.MakeUpInRoom(session, task)
    local isLock = CommonCal.Calculate.LevelReq(player, GameType.AllTypes.OpenSesame)
    if (isLock == 1) then
        response.ret = Return.LOCK_GAME()
        return response
    end

    local table_id = request.table_id
    local async_request = nil
    local game_room_config = GameRoomConfig[GameType.AllTypes.OpenSesame]

    if (table_id and table_id > 0) then
        local channel_id = string.format("%s.%s.%s", "SlotsOpenSesameContest", game_room_config.room_name, table_id)
        open_sesame.channel_id = channel_id
        async_request = {
            header = {
                router = "AsyncRequest",
                service_name = game_room_config.contest_client_name,
                task_id = task.id,
                module_id = "SlotsOpenSesameContest",
                message_id = "SlotsOpenSesameContest_Enter_Request"
            },
            player = {
                id = player.id,
                user = player.user,
                account = player.account,
                game_type = GameType.AllTypes.OpenSesame,
                character = {
                    chip = player.character.chip,
                    vip = player.character.vip,
                    level = player.character.level,
                    experience = player.character.experience,
                    player_type = player.character.player_type
                },
                record = player.record,
                open_sesame = open_sesame
            }
        }
    else
        async_request = {
            header = {
                router = "AsyncRequest",
                service_name = game_room_config.contest_client_name,
                task_id = task.id,
                module_id = "SlotsOpenSesameContest",
                message_id = "SlotsOpenSesameContest_Enter_Request"
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
                open_sesame = open_sesame
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

    open_sesame.channel_id = async_response.channel_id

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

    open_sesame.bouts_id = 0
     --进场的时候把cd清空掉
    open_sesame.enter_chip = player.character.chip
    open_sesame.spined_times = 0

    response.ret = Return.OK()
    response.player = {
        open_sesame = open_sesame,
        character = {
            chip = player.character.chip
        }
    }
    player.game_type = GameType.AllTypes.OpenSesame

    player_slots_info.content = json.encode(open_sesame)
    CommonCal.Calculate.UpdateSlotsToDbCache(task, player, player_slots_info)

    return response, table_sync_notice
end

--开始slots
Start = function(_M, session, request)
    local response = {header = {router = "Response"}}

    local filter_ret = RequestFilter.Filter("SlotsOpenSesame", "Start", session, request, true)
    if filter_ret then
        response.ret = filter_ret
        return response
    end

    -- print("hello everyone")
    local all_prize_items = {}
    local task = session.task
    local amount
    local player = session.player

    local player_slots_info = CommonCal.Calculate.get_slots_info(session, task, player, GameType.AllTypes.OpenSesame)
    local open_sesame = json.decode(player_slots_info.content)

    CommonCal.Calculate.BeginStart(session, task, player)

    if GlobalState:IsSlotsMaintenance(session, task, player.id) == 1 then
        response.ret = Return.SERVER_NEAR_MAINENANCE()
        return response
    end

    if (player.game_type ~= GameType.AllTypes.OpenSesame) then
        response.ret = Return.HAVE_ALREADY_EXIT_GAME()
        return response
    end
    local is_lock = CommonCal.Calculate.IsAppear(player)
    if (is_lock == 1) then
        response.ret = Return.LOCK_GAME()
        return response
    end
    local is_free_spin = open_sesame.free_spin_bouts > 0

    response.is_free_spin = is_free_spin and 1 or 0
    local origin_result, extra_wild, reel_file_name
    local chip_cost = 0

    ------201810310936开始------------------
    local extern_param = {}

    local player_feature_condition = CommonCal.Calculate.get_feature_condition(session, task, player, player.game_type)
    ------201810310936结束------------------

    local contest_id, room_id, table_id = unpack(string.split(open_sesame.channel_id, "."))

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
    if is_free_spin then
        ------201810310936开始------------------

        player_feature_condition.free_spin_count = player_feature_condition.free_spin_count + 1
        ------201810310936结束------------------
        amount = open_sesame.bet_amount
        open_sesame.free_spin_bouts = math.max(open_sesame.free_spin_bouts - 1, 0)
    else
        amount = request.amount
        chip_cost = amount * 25

        if not Player:Consume(player, {"Chip", chip_cost}, Reason.OPENSESAME_BET_CHIP_CONSUME()) then
            response.ret = Return.GAME_PLAYER_CHIP_NOT_ENOUGH()
            return response
        end
        open_sesame.bet_amount = amount
    end

    ------201810310936开始------------------
    extern_param.chip_cost = chip_cost

    player_feature_condition.spin_num = player_feature_condition.spin_num + 1
    ------201810310936结束------------------

    ------201810310936开始------------------

    ------201810310936结束------------------

    origin_result, extra_wild, reel_file_name = SlotsOpenSesameCal.Calculate.GenItemResult(player, is_free_spin, nil)

    local OpenSesameBetAmountConfig = CommonCal.Calculate.get_config(player, "OpenSesameBetAmountConfig")
    local bet_amount_conf
    for k, v in ipairs(OpenSesameBetAmountConfig) do
        if v.single_amount == amount then
            bet_amount_conf = v
            break
        end
    end
    response.ret = Return.OK()
    response.item_ids = SlotsOpenSesameCal.Calculate.TransResultToList(origin_result)
    local result_with_wild = SlotsOpenSesameCal.Calculate.GenResultWithWild(origin_result, extra_wild)
    local prize_items, total_payrate = SlotsOpenSesameCal.Calculate.GenPrizeInfo(player, result_with_wild)

    local OpenSesameOthersConfig = CommonCal.Calculate.get_config(player, "OpenSesameOthersConfig")
    response.prize_items = prize_items
    table.insert(all_prize_items, prize_items)
    local free_spin_bouts = SlotsOpenSesameCal.Calculate.GenFreeSpinCount(player, origin_result)
    open_sesame.free_spin_bouts = open_sesame.free_spin_bouts + free_spin_bouts
    local bonus_progress_delta = SlotsOpenSesameCal.Calculate.GenBonusProgress(player, origin_result)
    open_sesame.bonus_progress = open_sesame.bonus_progress + bonus_progress_delta

    if (bonus_progress_delta > 0) then
        local his_bet_mount_array = json.decode(open_sesame.his_bet_mount)
        table.insert(his_bet_mount_array, amount)
        open_sesame.his_bet_mount = json.encode(his_bet_mount_array)
        if (open_sesame.bonus_progress == OpenSesameOthersConfig[1].bonus_game_threshold) then
            local his_bet_mount_array = json.decode(open_sesame.his_bet_mount)
            if (#his_bet_mount_array > 0) then
                local total_mount = 0
                for k, v in ipairs(his_bet_mount_array) do
                    total_mount = total_mount + v
                end
                local equa_mount = total_mount / #his_bet_mount_array

                if (equa_mount <= OpenSesameBetAmountConfig[1].single_amount) then
                    open_sesame.bet_amount = OpenSesameBetAmountConfig[1].single_amount
                elseif (equa_mount >= OpenSesameBetAmountConfig[#OpenSesameBetAmountConfig].single_amount) then
                    open_sesame.bet_amount = OpenSesameBetAmountConfig[#OpenSesameBetAmountConfig].single_amount
                else
                    for k, v in ipairs(OpenSesameBetAmountConfig) do
                        if equa_mount <= v.single_amount and equa_mount > OpenSesameBetAmountConfig[k - 1].single_amount then
                            open_sesame.bet_amount = v.single_amount
                            break
                        end
                    end
                end
            end

            --for k, v in ipairs(his_bet_mount_array)
            --do

            --end

            open_sesame.his_bet_mount = "[]"

            if (player.character.player_type == tonumber(ConstValue[5].value)) then
                local request = {}
                request.header = {}

                OpenBox(nil, session, request)
            end
        end
    end

    response.wilds = SlotsOpenSesameCal.Calculate.TransExtraWildPosToList(extra_wild)

    local is_get_free_spin = false

    if free_spin_bouts > 0 then
        is_get_free_spin = true
    end

    if (not is_free_spin and is_get_free_spin) then
        open_sesame.bouts_id = os.time()
    end

    ----记录record
    player.record.total_spin = player.record.total_spin + 1
    if is_free_spin then
        player.record.free_spin = player.record.free_spin + 1
    end

    local win_chip = total_payrate * amount
    if win_chip > 0 then
        Player:Obtain(player, {"Chip", win_chip}, Reason.OPENSESAME_BET_CHIP_OBTAIN())

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
            wilds = response.wilds,
            prize_items = prize_items,
            win_chip = win_chip,
            bet_amount = amount,
            free_spin = rep_free_spin
        }
        RankHelper:ChallengeDailyBiggestWin(player, GameType.AllTypes.OpenSesame, rep_data)
        RankHelper:ChallengeWeeklyBiggestWin(player, GameType.AllTypes.OpenSesame, rep_data)
        --end
        ----记录record
        player.record.spin_won = player.record.spin_won + 1
        player.record.total_win = player.record.total_win + win_chip
        if win_chip > player.record.biggest_win then
            player.record.biggest_win = win_chip
        end
    end

    if (result_with_wild[2][3] == 7) then
        local number = win_chip / (amount * 25)
        number = math.floor(number + 0.5)

        Spark:FeatureSpecialWin(
            player,
            {
                [1] = player.game_type,
                [2] = "OpenSesame",
                [3] = is_free_spin and 1 or 0,
                [4] = "ExpandingDynamicWild",
                [5] = number
            }
        )
    end

    Player:BroadCastChip(session, task, amount * 25, win_chip)

    -----记录free spin中总赢取
    if is_free_spin then
        open_sesame.free_total_win = open_sesame.free_total_win + win_chip
    else
        open_sesame.free_total_win = 0
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

    local bet_amount_conf
    for k, v in ipairs(OpenSesameBetAmountConfig) do
        if v.single_amount == amount then
            bet_amount_conf = v
            break
        end
    end

    local free_win_amount = 0
    if (is_free_spin) then
        free_win_amount = win_chip
    end

    local OpenSesamePrizeConfig = CommonCal.Calculate.get_config(player, "OpenSesamePrizeConfig")
    --accomplish tasks
    local task_req_data = {
        five_line = CommonCal.Calculate.GetFiveLineCount(all_prize_items),
        base_spin = not is_free_spin,
        free_spin = is_get_free_spin,
         --本次下注是否属于freespin
        win_amount = win_chip,
        bet_amount = amount * 25,
        max_bet = amount >= SlotsOpenSesameCal.Calculate.GetMaxBetAmount(player),
        bonus_game = (open_sesame.bonus_progress == OpenSesameOthersConfig[1].bonus_game_threshold),
        free_win_amount = free_win_amount,
        epic_win = (total_payrate / 25) >= OpenSesamePrizeConfig[3].min_multiple
    }

    --LOG(RUN, INFO).Format("[SlotsOpenSesame][Start] player %s's task_req_data is: %s, max_bet_value is:%s", player.id, Table2Str(task_req_data), SlotsOpenSesameCal.Calculate.GetMaxBetAmount(player))
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
    if ((win_chip / (amount * 25)) >= OpenSesamePrizeConfig[3].min_multiple) then
        player.statistics.epicwin_num = player.statistics.epicwin_num + 1
    elseif ((win_chip / (amount * 25)) >= OpenSesamePrizeConfig[2].min_multiple) then
        player.statistics.megawin_num = player.statistics.megawin_num + 1
    elseif ((win_chip / (amount * 25)) >= OpenSesamePrizeConfig[1].min_multiple) then
        player.statistics.bigwin_num = player.statistics.bigwin_num + 1
    end
    if (open_sesame.bonus_progress == OpenSesameOthersConfig[1].bonus_game_threshold) then
        player.statistics.bonus_game_num = player.statistics.bonus_game_num + 1
    end

    local can_multiply = SlotsGameCal.Calculate.WinChipInMultiply(win_chip)
    if (can_multiply) then
        if ((total_payrate / 25) >= OpenSesamePrizeConfig[2].min_multiple and not is_free_spin) then
            response.is_multiply = CommonCal.Calculate.IsMultiply(session, win_chip)
        end

        if ((total_payrate / 25) >= OpenSesamePrizeConfig[1].min_multiple and not is_free_spin) then
            RobotAction.BigWinAction(session, task)
        end
    end

    --广播
    local win_info = {
        bet_amount = amount,
        total_bet = amount * 25,
        win_chip = win_chip
    }

    Communication:OnBcEvent(session, BroadcastType.AllTypes.OpenSesameSpin, win_info, 15)

    --buyloss的局数+1
    open_sesame.spined_times = open_sesame.spined_times + 1

    response.win_chip = win_chip

    local contest_id, room_id, table_id = unpack(string.split(open_sesame.channel_id, "."))
    if (is_free_spin) then
        Spark:SlotsAward(
            player,
            {
                [1] = GameType.AllTypes.OpenSesame,
                [2] = "OpenSesame",
                [3] = table_id,
                [4] = open_sesame.bouts_id,
                [5] = open_sesame.bet_amount,
                [6] = win_chip,
                [7] = json.encode(origin_result),
                [8] = "[]",
                [9] = reel_file_name,
                [10] = open_sesame.free_spin_bouts,
                [11] = CommonCal.Calculate.GetFiveLineCount(all_prize_items) > 0 and 1 or 0,
                [12] = player.record.total_spin,
                [13] = amount * 25
            }
        )
    else
        Spark:SlotsStart(
            player,
            {
                [1] = GameType.AllTypes.OpenSesame,
                [2] = "OpenSesame",
                [3] = table_id,
                [4] = open_sesame.bouts_id,
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

    CommonCal.Calculate.EndStart(session, task, player, request, response, open_sesame, 25, chip_cost, win_chip)

    --gain exp
    if not is_free_spin then
        local exp = chip_cost
        local exp_request = {
            type = "SlotsOpenSesame",
            ante_gold = amount * 25,
            gain_exp = exp
        }
        Player:GainExp(session, exp_request)
    end

    player_slots_info.content = json.encode(open_sesame)
    CommonCal.Calculate.UpdateSlotsToDbCache(task, player, player_slots_info)

    CommonCal.Calculate.UpdateToDbCache(task, player, "feature_condition", player_feature_condition)

    --锦标赛玩家得分更新
    CommonCal.Calculate.UpdateTournamentPlayerInfo(session, player.game_type, player, chip_cost, win_chip)

    response.player = {
        unlock_games = player.unlock_games,
        character = {
            chip = player.character.chip,
            experience = player.character.experience,
            level = player.character.level
        },
        open_sesame = {
            bet_amount = amount,
            bonus_progress = open_sesame.bonus_progress,
            free_spin_bouts = open_sesame.free_spin_bouts,
            free_total_win = open_sesame.free_total_win
        }
    }

    return response
end

-----------------------------------------------
-- 退出房间
------------------------------------------------
Exit = function(_M, session, request)
    local response = {header = {router = "Response"}}
    local filter_ret = RequestFilter.Filter("SlotsOpenSesame", "Exit", session, request, true)
    if filter_ret then
        response.ret = filter_ret
        return response
    end

    local player = session.player
    local task = session.task

    local player_slots_info = CommonCal.Calculate.get_slots_info(session, task, player, GameType.AllTypes.OpenSesame)
    local open_sesame = json.decode(player_slots_info.content)

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
            module_id = "SlotsOpenSesameContest",
            message_id = "SlotsOpenSesameContest_Exit_Request"
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
        BuyLoss:Trigger(session, task, GameType.AllTypes.OpenSesame, player)
    if trigger_buyloss then
        open_sesame.total_loss = total_loss
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
    open_sesame.spined_times = 0

    response = {
        header = response.header,
        ret = Return.OK(),
        player = {
            character = {
                chip = player.character.chip
            }
        }
    }
    LOG(RUN, INFO).Format("[SlotsOpenSesame][Exit] ok player %s, game type is: %s", player.id, player.game_type)

    player_slots_info.content = json.encode(open_sesame)
    CommonCal.Calculate.UpdateSlotsToDbCache(task, player, player_slots_info)

    return response
end

OpenBox = function(_M, session, request)
    local response = {header = {router = "Response"}}
    local filter_ret = RequestFilter.Filter("SlotsOpenSesame", "OpenBox", session, request, true)
    if filter_ret then
        response.ret = filter_ret
        return response
    end
    local player = session.player

    local task = session.task
    --set player's bonus game progress to 0
    local player_slots_info = CommonCal.Calculate.get_slots_info(session, task, player, GameType.AllTypes.OpenSesame)
    local open_sesame = json.decode(player_slots_info.content)

    local OpenSesameOthersConfig = CommonCal.Calculate.get_config(player, "OpenSesameOthersConfig")
    if open_sesame.bonus_progress < OpenSesameOthersConfig[1].bonus_game_threshold then
        LOG(RUN, INFO).Format(
            "[SlotsOpenSesame][OpenBox] player %s 's bonus progress is equal or larger than the threshold",
            session.player.id
        )
        response.ret = Return.OPENSESAME_BONUS_PROGRESS_NOT_ENOUGH()
        return response
    end

    open_sesame.bonus_progress = 0
    local payrate = SlotsOpenSesameCal.Calculate.GenBonusGamePayrate(player)
    local chip_get = payrate * 25 * open_sesame.bet_amount
    Player:Obtain(player, {"Chip", chip_get}, Reason.OPENSESAME_BONUS_GAME_OBTAIN())

    Player:BroadCastChip(session, task, 0, 0)

    local task_req_data = {
        bonus_win_amount = chip_get
    }
    DailyTask:CompleteTask(session, player, task_req_data)

    ----记录每日、每周赢钱,进排行榜
    RankHelper:ChallengeDailyWin(player)
    RankHelper:ChallengeWeeklyWin(player)
    player.record.bonus_game = player.record.bonus_game + 1
    player.record.total_win = player.record.total_win + chip_get

    --记录free spin total win
    if open_sesame.free_spin_bouts > 0 then
        open_sesame.free_total_win = open_sesame.free_total_win + chip_get
    end

    --广播
    local win_info = {
        bet_amount = open_sesame.bet_amount,
        total_bet = open_sesame.bet_amount * 25,
        win_chip = chip_get
    }
    Communication:OnBcEvent(session, BroadcastType.AllTypes.OpenSesameBonusGame, win_info, 15)

    local number = chip_get / (open_sesame.bet_amount * 25)
    CommonCal.Calculate.CalBonusAward(player, number)

    --opt
    local contest_id, room_id, table_id = unpack(string.split(open_sesame.channel_id, "."))

    Spark:SlotsBonusAward(
        player,
        {
            [1] = GameType.AllTypes.OpenSesame,
            [2] = "OpenSesame",
            [3] = table_id,
            [4] = os.time(),
            [5] = open_sesame.bet_amount,
            [6] = chip_get
        }
    )

    --[[


    Spark:OpenSesameOpenBox(player, {
        [1] = contest_id,
        [2] = room_id,
        [3] = table_id,
        [4] = open_sesame.bet_amount,
        [5] = open_sesame.bet_amount * 25,
        [6] = chip_get,
    })
    --]]
    --锦标赛玩家得分更新
    CommonCal.Calculate.UpdateTournamentPlayerInfo(session, player.game_type, player, 0, chip_get)

    response.ret = Return.OK()
    response.chip_get = chip_get
    response.player = {
        character = {
            chip = player.character.chip
        },
        open_sesame = {
            bonus_progress = open_sesame.bonus_progress
        }
    }

    player_slots_info.content = json.encode(open_sesame)
    CommonCal.Calculate.UpdateSlotsToDbCache(task, player, player_slots_info)
    return response
end
