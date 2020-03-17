require "Common/SlotsPharaohTreasureCal"
require "Common/RequestFilter"
require "Module/DailyTask"
require "Common/RobotAction"
require "Common/DailyMissionsCal"
module("SlotsPharaohTreasure", package.seeall)

-----------------------------------------------
-- 进入房间
------------------------------------------------
Enter = function(_M, session, request)
    local response = {header = {router = "Response"}}
    local filter_ret = RequestFilter.Filter("SlotsPharaohTreasure", "Enter", session, request, true)
    if filter_ret then
        response.ret = filter_ret
        return response
    end
    local task = session.task
    local player = session.player

    local player_slots_info =
        CommonCal.Calculate.get_slots_info(session, task, player, GameType.AllTypes.PharaohTreasure)
    local pharaoh_treasure = json.decode(player_slots_info.content)

    CommonCal.Calculate.MakeUpInRoom(session, task)
    local isLock = CommonCal.Calculate.LevelReq(player, GameType.AllTypes.PharaohTreasure)
    if (isLock == 1) then
        response.ret = Return.LOCK_GAME()
        return response
    end

    local table_id = request.table_id
    local async_request = nil
    local game_room_config = GameRoomConfig[GameType.AllTypes.PharaohTreasure]

    if (table_id and table_id > 0) then
        local channel_id =
            string.format("%s.%s.%s", "SlotsPharaohTreasureContest", game_room_config.room_name, table_id)
        pharaoh_treasure.channel_id = channel_id
        async_request = {
            header = {
                router = "AsyncRequest",
                service_name = game_room_config.contest_client_name,
                task_id = task.id,
                module_id = "SlotsPharaohTreasureContest",
                message_id = "SlotsPharaohTreasureContest_Enter_Request"
            },
            player = {
                id = player.id,
                user = player.user,
                account = player.account,
                game_type = GameType.AllTypes.PharaohTreasure,
                character = {
                    chip = player.character.chip,
                    vip = player.character.vip,
                    level = player.character.level,
                    experience = player.character.experience,
                    player_type = player.character.player_type
                },
                record = player.record,
                pharaoh_treasure = pharaoh_treasure
            }
        }
    else
        async_request = {
            header = {
                router = "AsyncRequest",
                service_name = game_room_config.contest_client_name,
                task_id = task.id,
                module_id = "SlotsPharaohTreasureContest",
                message_id = "SlotsPharaohTreasureContest_Enter_Request"
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
                pharaoh_treasure = pharaoh_treasure
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

    pharaoh_treasure.channel_id = async_response.channel_id

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

    pharaoh_treasure.bouts_id = 0
     --进场的时候把cd清空掉
    pharaoh_treasure.enter_chip = player.character.chip
    pharaoh_treasure.spined_times = 0

    if pharaoh_treasure.history then
        local pick_history = json.decode(pharaoh_treasure.history)
        response.pick_history = pick_history
    end

    response.ret = Return.OK()
    response.player = {
        pharaoh_treasure = pharaoh_treasure,
        character = {
            chip = player.character.chip
        }
    }

    player.game_type = GameType.AllTypes.PharaohTreasure

    player_slots_info.content = json.encode(pharaoh_treasure)
    CommonCal.Calculate.UpdateSlotsToDbCache(task, player, player_slots_info)

    return response, table_sync_notice
end

--开始slots
Start = function(_M, session, request)
    local response = {header = {router = "Response"}}

    local filter_ret = RequestFilter.Filter("SlotsPharaohTreasure", "Start", session, request, true)
    if filter_ret then
        response.ret = filter_ret
        return response
    end

    local is_free_spin = false

    local task = session.task
    -- local amount
    local player = session.player

    local player_slots_info =
        CommonCal.Calculate.get_slots_info(session, task, player, GameType.AllTypes.PharaohTreasure)
    local pharaoh_treasure = json.decode(player_slots_info.content)

    CommonCal.Calculate.BeginStart(session, task, player)

    if GlobalState:IsSlotsMaintenance(session, task, player.id) == 1 then
        response.ret = Return.SERVER_NEAR_MAINENANCE()
        return response
    end

    if (player.game_type ~= GameType.AllTypes.PharaohTreasure) then
        response.ret = Return.HAVE_ALREADY_EXIT_GAME()
        return response
    end

    local is_lock = CommonCal.Calculate.IsAppear(player)
    if (is_lock == 1) then
        response.ret = Return.LOCK_GAME()
        return response
    end
    local amount = request.amount
    local chip_cost = amount * 25

    ------201810310936开始------------------
    local extern_param = {}

    local player_feature_condition = CommonCal.Calculate.get_feature_condition(session, task, player, player.game_type)

    ------201810310936结束------------------

    ------201810310936开始------------------
    extern_param.chip_cost = chip_cost

    player_feature_condition.spin_num = player_feature_condition.spin_num + 1
    ------201810310936结束------------------

    local all_prize_items = {}

    pharaoh_treasure.bouts_id = os.time()

    if not Player:Consume(player, {"Chip", chip_cost}, Reason.PHARAOHTREASURE_BET_CHIP_CONSUME()) then
        response.ret = Return.GAME_PLAYER_CHIP_NOT_ENOUGH()
        return response
    end

    pharaoh_treasure.bet_amount = amount

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
    local event_json = {}
    if (player_feature_condition.event_json ~= nil) then
        event_json = json.decode(player_feature_condition.event_json)
    end
    ------201810310936结束------------------

    local init_result, prize_info, total_payrate, multis, reel_file_name =
        SlotsPharaohTreasureCal.Calculate.GenItemResult(player, nil)

    table.insert(all_prize_items, prize_info)

    local PharaohTreasureOthersConfig = CommonCal.Calculate.get_config(player, "PharaohTreasureOthersConfig")

    response.ret = Return.OK()
    response.item_ids = SlotsPharaohTreasureCal.Calculate.TransResultToList(init_result)
    response.prize_multi = multis
    response.prize_items = prize_info
    local trigger_bonus_game = SlotsPharaohTreasureCal.Calculate.TriggerBonus(init_result)
    if trigger_bonus_game then
        if (event_json.trigger_bonus_count == nil) then
            event_json.trigger_bonus_count = 1
        else
            event_json.trigger_bonus_count = event_json.trigger_bonus_count + 1
        end
        pharaoh_treasure.choose_times = PharaohTreasureOthersConfig[1].choose_times

        if (player.character.player_type == tonumber(ConstValue[5].value)) then
            local request = {}
            request.header = {}
            for i = 1, PharaohTreasureOthersConfig[1].choose_times, 1 do
                local bg_level = pharaoh_treasure.bg_level

                local pick_index = 1
                for index = 1, 6, 1 do
                    if table.has_value(SlotsPharaohTreasureCal.Const.LevelIndexes[bg_level], index) then
                        local history = json.decode(pharaoh_treasure.history)
                        local is_exist = false
                        for _, item in pairs(history) do
                            local his_pick_index = item.pick_index
                            if (his_pick_index == index) then
                                is_exist = true
                                break
                            end
                        end
                        if (not is_exist) then
                            pick_index = index
                        end
                    end
                end

                request.index = pick_index
                Pick(nil, session, request)
            end
        end
    end

    local PharaohTreasureBetAmountConfig = CommonCal.Calculate.get_config(player, "PharaohTreasureBetAmountConfig")
    local bet_amount_conf
    for k, v in ipairs(PharaohTreasureBetAmountConfig) do
        if v.single_amount == amount then
            bet_amount_conf = v
            break
        end
    end

    ----记录record
    player.record.total_spin = player.record.total_spin + 1

    local win_chip = total_payrate * amount
    if win_chip > 0 then
        Player:Obtain(player, {"Chip", win_chip}, Reason.PHARAOHTREASURE_BET_CHIP_OBTAIN())

        --记录每日、每周赢钱,进排行榜
        RankHelper:ChallengeDailyWin(player)
        RankHelper:ChallengeWeeklyWin(player)

        local rep_free_spin = 0
        local rep_data = {
            item_ids = response.item_ids,
            wilds = response.wilds,
            prize_items = prize_info,
            win_chip = win_chip,
            bet_amount = amount,
            prize_multi = multis,
            free_spin = rep_free_spin
        }
        RankHelper:ChallengeDailyBiggestWin(player, GameType.AllTypes.PharaohTreasure, rep_data)
        RankHelper:ChallengeWeeklyBiggestWin(player, GameType.AllTypes.PharaohTreasure, rep_data)
        ----记录record
        player.record.spin_won = player.record.spin_won + 1
        player.record.total_win = player.record.total_win + win_chip
        if win_chip > player.record.biggest_win then
            player.record.biggest_win = win_chip
        end
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

    local free_win_amount = 0
    if (is_free_spin) then
        free_win_amount = win_chip
    end

    local PharaohTreasurePrizeConfig = CommonCal.Calculate.get_config(player, "PharaohTreasurePrizeConfig")
    --accomplish tasks
    local task_req_data = {
        five_line = CommonCal.Calculate.GetFiveLineCount(all_prize_items),
        base_spin = not is_free_spin,
        free_spin = is_free_spin,
         --本次下注是否属于freespin
        win_amount = win_chip,
        bet_amount = amount * 25,
        max_bet = amount >= SlotsPharaohTreasureCal.Calculate.GetMaxBetAmount(player),
        bonus_game = trigger_bonus_game,
        free_win_amount = free_win_amount,
        epic_win = (total_payrate / 25) >= PharaohTreasurePrizeConfig[3].min_multiple
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
    if ((win_chip / (amount * 25)) >= PharaohTreasurePrizeConfig[3].min_multiple) then
        player.statistics.epicwin_num = player.statistics.epicwin_num + 1
    elseif ((win_chip / (amount * 25)) >= PharaohTreasurePrizeConfig[2].min_multiple) then
        player.statistics.megawin_num = player.statistics.megawin_num + 1
    elseif ((win_chip / (amount * 25)) >= PharaohTreasurePrizeConfig[1].min_multiple) then
        player.statistics.bigwin_num = player.statistics.bigwin_num + 1
    end
    if (trigger_bonus_game) then
        player.statistics.bonus_game_num = player.statistics.bonus_game_num + 1
    end

    Player:BroadCastChip(session, task, amount * 25, win_chip)

    local can_multiply = SlotsGameCal.Calculate.WinChipInMultiply(win_chip)
    if (can_multiply) then
        if ((total_payrate / 25) >= PharaohTreasurePrizeConfig[2].min_multiple and not is_free_spin) then
            response.is_multiply = CommonCal.Calculate.IsMultiply(session, win_chip)
        end

        if ((total_payrate / 25) >= PharaohTreasurePrizeConfig[1].min_multiple and not is_free_spin) then
            RobotAction.BigWinAction(session, task)
        end
    end

    --广播
    local win_info = {
        bet_amount = amount,
        total_bet = amount * 25,
        win_chip = win_chip
    }
    Communication:OnBcEvent(session, BroadcastType.AllTypes.PharaohTreasureSpin, win_info, 15)

    --opt
    local contest_id, room_id, table_id = unpack(string.split(pharaoh_treasure.channel_id, "."))

    if (is_free_spin) then
        Spark:SlotsAward(
            player,
            {
                [1] = GameType.AllTypes.PharaohTTreasure,
                [2] = "PharaohTTreasure",
                [3] = table_id,
                [4] = pharaoh_treasure.bouts_id,
                [5] = pharaoh_treasure.bet_amount,
                [6] = win_chip,
                [7] = json.encode(init_result),
                [8] = "[]",
                [9] = reel_file_name,
                [10] = pharaoh_treasure.free_spin_bouts,
                [11] = CommonCal.Calculate.GetFiveLineCount(all_prize_items) > 0 and 1 or 0,
                [12] = player.record.total_spin,
                [13] = amount * 25
            }
        )
    else
        Spark:SlotsStart(
            player,
            {
                [1] = GameType.AllTypes.PharaohTreasure,
                [2] = "PharaohTreasure",
                [3] = table_id,
                [4] = pharaoh_treasure.bouts_id,
                [5] = amount,
                [6] = amount * 25,
                [7] = win_chip,
                [8] = json.encode(init_result),
                [9] = "[]",
                [10] = false,
                [11] = reel_file_name,
                [12] = CommonCal.Calculate.GetFiveLineCount(all_prize_items) > 0 and 1 or 0,
                [13] = player.record.total_spin
            }
        )
    end

    --buyloss的局数+1
    pharaoh_treasure.spined_times = pharaoh_treasure.spined_times + 1

    response.win_chip = win_chip

    CommonCal.Calculate.EndStart(session, task, player, request, response, pharaoh_treasure, 25, chip_cost, win_chip)

    --gain exp
    local exp = chip_cost
    local exp_request = {
        type = "SlotsPharaohTreasure",
        ante_gold = amount * 25,
        gain_exp = exp
    }
    Player:GainExp(session, exp_request)

    player_slots_info.content = json.encode(pharaoh_treasure)
    CommonCal.Calculate.UpdateSlotsToDbCache(task, player, player_slots_info)

    ------201810310936开始------------------
    player_feature_condition.event_json = json.encode(event_json)
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
        pharaoh_treasure = {
            bet_amount = amount,
            choose_times = pharaoh_treasure.choose_times
        }
    }
    return response
end

-----------------------------------------------
-- 退出房间
------------------------------------------------
Exit = function(_M, session, request)
    local response = {header = {router = "Response"}}
    local filter_ret = RequestFilter.Filter("SlotsPharaohTreasure", "Exit", session, request, true)
    if filter_ret then
        response.ret = filter_ret
        return response
    end

    local player = session.player
    local task = session.task

    local player_slots_info =
        CommonCal.Calculate.get_slots_info(session, task, player, GameType.AllTypes.PharaohTreasure)
    local pharaoh_treasure = json.decode(player_slots_info.content)

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
            module_id = "SlotsPharaohTreasureContest",
            message_id = "SlotsPharaohTreasureContest_Exit_Request"
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
        BuyLoss:Trigger(session, task, GameType.AllTypes.PharaohTreasure, player)
    if trigger_buyloss then
        pharaoh_treasure.total_loss = total_loss
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
    pharaoh_treasure.spined_times = 0

    response = {
        header = response.header,
        ret = Return.OK(),
        player = {
            character = {
                chip = player.character.chip
            }
        }
    }
    LOG(RUN, INFO).Format("[SlotsPharaohTreasure][Exit] ok player %s, game type is: %s", player.id, player.game_type)

    player_slots_info.content = json.encode(pharaoh_treasure)
    CommonCal.Calculate.UpdateSlotsToDbCache(task, player, player_slots_info)

    return response
end

Pick = function(_M, session, request)
    local response = {header = {router = "Response"}}
    response.ret = Return.OK()

    local filter_ret = RequestFilter.Filter("SlotsPharaohTreasure", "Pick", session, request, true)
    if filter_ret then
        response.ret = filter_ret
        -- LOG(RUN, INFO).Format("[SlotsPharaohTreasure]Pick response is:%s, and pick error", Table2Str(response))
        return response
    end

    local player_slots_info =
        CommonCal.Calculate.get_slots_info(session, task, player, GameType.AllTypes.PharaohTreasure)
    local pharaoh_treasure = json.decode(player_slots_info.content)

    local player = session.player

    if pharaoh_treasure.choose_times <= 0 then
        response.ret = Return.PHARAOHTREASURE_PICK_INVALID()
        return response
    end

    if pharaoh_treasure.bg_level >= 5 then
        response.ret = Return.PHARAOHTREASURE_PICK_ALREADY_REACH_TOP()
        return response
    end

    local old_chip = player.character.chip

    local bg_level = pharaoh_treasure.bg_level
    local amount = pharaoh_treasure.bet_amount
    local pick_index = request.index

    if not table.has_value(SlotsPharaohTreasureCal.Const.LevelIndexes[bg_level], pick_index) then
        response.ret = Return.PHARAOHTREASURE_PICK_INVALID()
        return response
    end
    local history = json.decode(pharaoh_treasure.history)

    for _, item in pairs(history) do
        local his_pick_index = item.pick_index
        if (his_pick_index == pick_index) then
            response.ret = Return.PHARAOHTREASURE_PICK_INVALID()
            return response
        end
    end

    local pick_multi = SlotsPharaohTreasureCal.Calculate.GenPickMulti(bg_level, player)
     --pick_multi为值表示没有选到upstairs,为nil表示选到了upstairs
    local is_upstairs = SlotsPharaohTreasureCal.Calculate.CheckIfGenUpstairs(bg_level, history)
     --如果玩家选的是这一级的最后一个,那么必出upstairs
    local strUpstairs = 0
    if (is_upstairs) then
        strUpstairs = 1
    end

    local PharaohTreasureOthersConfig = CommonCal.Calculate.get_config(player, "PharaohTreasureOthersConfig")
    if not is_upstairs and pick_multi then
        --把数据floor一下
        local win_chip = SlotsPharaohTreasureCal.Calculate.FloorWinChip(pick_multi * 25 * amount)
        response.win_chip = win_chip
        Player:Obtain(player, {"Chip", win_chip}, Reason.PHARAOHTREASURE_PICK_CHIP_OBTAIN())

        local task_req_data = {
            bonus_win_amount = win_chip
        }
        DailyTask:CompleteTask(session, player, task_req_data)

        pharaoh_treasure.total_bonus = pharaoh_treasure.total_bonus + win_chip
        response.upstairs = 0
        table.insert(
            history,
            {
                pick_index = pick_index,
                win_chip = win_chip
            }
        )
        --在没有选到升级的时候扣除一次choose_times
        pharaoh_treasure.choose_times = math.max(pharaoh_treasure.choose_times - 1, 0)

        local number = win_chip / (pharaoh_treasure.bet_amount * 25)
        CommonCal.Calculate.CalBonusAward(player, number)
    else
        response.upstairs = 1

        table.insert(
            history,
            {
                pick_index = pick_index,
                win_chip = 0
             --如果选到了上升那么win_chip就是0
            }
        )
        --玩家到达最高层,获得相应的奖励
        pharaoh_treasure.bg_level = pharaoh_treasure.bg_level + 1
        if pharaoh_treasure.bg_level >= 5 then
            local top_multi = PharaohTreasureOthersConfig[1].top_multi
            LOG(RUN, INFO).Format("[SlotsPharaohTreasure][Pick] top_multi is： %s, amount is: %s", top_multi, amount)
            local top_win_chip = SlotsPharaohTreasureCal.Calculate.FloorWinChip(top_multi * 25 * amount)
            LOG(RUN, INFO).Format("[SlotsPharaohTreasure][Pick] top_win_chip is: %s", top_win_chip)
            Player:Obtain(player, {"Chip", top_win_chip}, Reason.PHARAOHTREASURE_PICK_CHIP_OBTAIN())
            response.win_chip = top_win_chip
            --到达最高层后将level再置为1
            pharaoh_treasure.bg_level = 1

            pharaoh_treasure.choose_times = 0

            LOG(RUN, INFO).Format("[SlotsPharaohTreasure][Pick] pharaoh_treasure.bg_level >= 5")

            local contest_id, room_id, table_id = unpack(string.split(pharaoh_treasure.channel_id, "."))

            Spark:SlotsBonusAward(
                player,
                {
                    [1] = GameType.AllTypes.LeprechaunTreasure,
                    [2] = "LeprechaunTreasure",
                    [3] = table_id,
                    [4] = pharaoh_treasure.bouts_id,
                    [5] = pharaoh_treasure.bet_amount,
                    [6] = top_win_chip
                }
            )
        end
    end

    --没有选择次数了,小游戏结束,清空history
    if pharaoh_treasure.choose_times == 0 then
        history = {}
        pharaoh_treasure.bg_level = 1
        pharaoh_treasure.total_bonus = 0
    end

    pharaoh_treasure.history = json.encode(history)

    -- LOG(RUN, INFO).Format("[SlotsPharaohTreasure][Pick] player %s, history is:%s", player.id, Table2Str(pharaoh_treasure.history))

    response.player = {
        character = {
            chip = player.character.chip
        },
        pharaoh_treasure = {
            choose_times = pharaoh_treasure.choose_times,
            bg_level = pharaoh_treasure.bg_level
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
                pharaoh_treasure = {
                    history = pharaoh_treasure.history
                }
            },
            collect_chip = player.character.chip - old_chip
        }
    )

    local contest_id, room_id, table_id = unpack(string.split(pharaoh_treasure.channel_id, "."))

    Spark:PharaohTreasurePick(
        player,
        {
            [1] = contest_id,
            [2] = room_id,
            [3] = table_id,
            [4] = pharaoh_treasure.bouts_id,
            [5] = amount,
            [6] = amount * 25,
            [7] = pharaoh_treasure.choose_times,
            [8] = json.encode(pharaoh_treasure.history),
            [9] = response.win_chip,
            [10] = is_upstairs
        }
    )

    --锦标赛玩家得分更新
    if (response.win_chip) then
        CommonCal.Calculate.UpdateTournamentPlayerInfo(session, player.game_type, player, 0, response.win_chip)
    end

    player_slots_info.content = json.encode(pharaoh_treasure)
    CommonCal.Calculate.UpdateSlotsToDbCache(task, player, player_slots_info)

    return response
end
