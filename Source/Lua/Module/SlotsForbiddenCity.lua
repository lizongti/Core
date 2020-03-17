require "Common/SlotsForbiddenCityCal"
require "Common/RequestFilter"
require "Module/DailyTask"
require "Common/RobotAction"
module("SlotsForbiddenCity", package.seeall)

-----------------------------------------------
-- 进入房间
------------------------------------------------
Enter = function(_M, session, request)
    local response = {header = {router = "Response"}}
    local filter_ret = RequestFilter.Filter("SlotsForbiddenCity", "Enter", session, request, true)
    if filter_ret then
        response.ret = filter_ret
        return response
    end
    local task = session.task
    local player = session.player

    CommonCal.Calculate.MakeUpInRoom(session, task)
    local isLock = CommonCal.Calculate.LevelReq(player, GameType.AllTypes.ForbiddenCity)
    if (isLock == 1) then
        response.ret = Return.LOCK_GAME()
        return response
    end

    local player_slots_info = CommonCal.Calculate.get_slots_info(session, task, player, GameType.AllTypes.ForbiddenCity)
    local forbidden_city = json.decode(player_slots_info.content)

    local table_id = request.table_id
    local async_request = nil
    local game_room_config = GameRoomConfig[GameType.AllTypes.ForbiddenCity]

    if (table_id and table_id > 0) then
        local channel_id = string.format("%s.%s.%s", "SlotsForbiddenCityContest", game_room_config.room_name, table_id)
        forbidden_city.channel_id = channel_id
        async_request = {
            header = {
                router = "AsyncRequest",
                service_name = game_room_config.contest_client_name,
                task_id = task.id,
                module_id = "SlotsForbiddenCityContest",
                message_id = "SlotsForbiddenCityContest_Enter_Request"
            },
            player = {
                id = player.id,
                user = player.user,
                account = player.account,
                game_type = GameType.AllTypes.ForbiddenCity,
                character = {
                    chip = player.character.chip,
                    vip = player.character.vip,
                    level = player.character.level,
                    experience = player.character.experience,
                    player_type = player.character.player_type
                },
                record = player.record,
                forbidden_city = forbidden_city
            }
        }
    else
        async_request = {
            header = {
                router = "AsyncRequest",
                service_name = game_room_config.contest_client_name,
                task_id = task.id,
                module_id = "SlotsForbiddenCityContest",
                message_id = "SlotsForbiddenCityContest_Enter_Request"
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
                forbidden_city = forbidden_city
            }
        }
    end

    local async_response = session:ContactPacket(task, async_request)
    LOG(RUN, INFO).Format(
        "[SlotsForbiddenCity][Enter] player %s successfully entered SlotsForbiddenCityContest",
        player.id
    )
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

    forbidden_city.channel_id = async_response.channel_id

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

    forbidden_city.bouts_id = 0
     --进场的时候把cd清空掉
    forbidden_city.enter_chip = player.character.chip
    forbidden_city.spined_times = 0

    -- response.item_ids = SlotsForbiddenCityCal.Calculate.GenInitItem()
    response.ret = Return.OK()
    response.player = {
        forbidden_city = forbidden_city,
        character = {
            chip = player.character.chip
        }
    }
    player.game_type = GameType.AllTypes.ForbiddenCity

    player_slots_info.content = json.encode(forbidden_city)
    CommonCal.Calculate.UpdateSlotsToDbCache(task, player, player_slots_info)
    return response, table_sync_notice
end

--开始slots
Start = function(_M, session, request)
    local response = {header = {router = "Response"}}

    local filter_ret = RequestFilter.Filter("SlotsForbiddenCity", "Start", session, request, true)
    if filter_ret then
        response.ret = filter_ret
        return response
    end

    local task = session.task
    local amount
    local player = session.player

    local player_slots_info = CommonCal.Calculate.get_slots_info(session, task, player, GameType.AllTypes.ForbiddenCity)
    local forbidden_city = json.decode(player_slots_info.content)

    CommonCal.Calculate.BeginStart(session, task, player)

    if GlobalState:IsSlotsMaintenance(session, task, player.id) == 1 then
        response.ret = Return.SERVER_NEAR_MAINENANCE()
        return response
    end

    if (player.game_type ~= GameType.AllTypes.ForbiddenCity) then
        response.ret = Return.HAVE_ALREADY_EXIT_GAME()
        return response
    end
    local is_lock = CommonCal.Calculate.IsAppear(player)
    if (is_lock == 1) then
        response.ret = Return.LOCK_GAME()
        return response
    end
    local is_free_spin = forbidden_city.free_spin_bouts > 0

    response.is_free_spin = is_free_spin and 1 or 0
    local all_prize_items = {}

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
    local chip_cost = 0
    if is_free_spin then
        amount = forbidden_city.bet_amount
        forbidden_city.free_spin_bouts = math.max(forbidden_city.free_spin_bouts - 1, 0)
    else
        amount = request.amount
        chip_cost = amount * 25

        if not Player:Consume(player, {"Chip", chip_cost}, Reason.FORBIDDENCITY_BET_CHIP_CONSUME()) then
            response.ret = Return.GAME_PLAYER_CHIP_NOT_ENOUGH()
            return response
        end
        forbidden_city.bet_amount = amount
    end

    local origin_result, reel_file_name = SlotsForbiddenCityCal.Calculate.GenItemResult(player, is_free_spin)
    local prize_items, total_payrate = SlotsForbiddenCityCal.Calculate.GenPrizeInfo(player, origin_result)
    table.insert(all_prize_items, prize_items)
    local ForbiddenCityFreeSpinConfig = CommonCal.Calculate.get_config(player, "ForbiddenCityFreeSpinConfig")
    local trigger_free_spin = SlotsForbiddenCityCal.Calculate.GenFreeSpin(origin_result)
    if trigger_free_spin then
        forbidden_city.trigger_free_spin = forbidden_city.trigger_free_spin + 1

        if (player.character.player_type == tonumber(ConstValue[5].value)) then
            local request = {}
            request.header = {}

            request.index = math.random_ext(player, 1, #ForbiddenCityFreeSpinConfig)
            ChooseFreeSpin(nil, session, request)
        end
    end

    if (not is_free_spin and trigger_free_spin) then
        forbidden_city.bouts_id = os.time()
    end

    response.ret = Return.OK()
    response.item_ids = SlotsForbiddenCityCal.Calculate.TransResultToList(origin_result)
    response.prize_items = prize_items

    local ForbiddenCityBetAmountConfig = CommonCal.Calculate.get_config(player, "ForbiddenCityBetAmountConfig")
    local bet_amount_conf
    for k, v in ipairs(ForbiddenCityBetAmountConfig) do
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

    if is_free_spin then
        local multi = forbidden_city.free_spin_multi
        if multi > 0 then
            win_chip = win_chip * multi
        end
    end
    if win_chip > 0 then
        Player:Obtain(player, {"Chip", win_chip}, Reason.FORBIDDENCITY_BET_CHIP_OBTAIN())

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
            free_spin = rep_free_spin
        }
        RankHelper:ChallengeDailyBiggestWin(player, GameType.AllTypes.ForbiddenCity, rep_data)
        RankHelper:ChallengeWeeklyBiggestWin(player, GameType.AllTypes.ForbiddenCity, rep_data)
        --end
        ----记录record
        player.record.spin_won = player.record.spin_won + 1
        player.record.total_win = player.record.total_win + win_chip
        if win_chip > player.record.biggest_win then
            player.record.biggest_win = win_chip
        end
    end

    -----记录free spin中总赢取
    if is_free_spin then
        forbidden_city.free_total_win = forbidden_city.free_total_win + win_chip
    else
        forbidden_city.free_total_win = 0
    end

    local free_win_amount = 0
    if (is_free_spin) then
        free_win_amount = win_chip
    end

    local ForbiddenCityPrizeConfig = CommonCal.Calculate.get_config(player, "ForbiddenCityPrizeConfig")
    --accomplish tasks
    local task_req_data = {
        five_line = CommonCal.Calculate.GetFiveLineCount(all_prize_items),
        base_spin = not is_free_spin,
        free_spin = trigger_free_spin,
         --本次下注是否属于freespin
        win_amount = win_chip,
        bet_amount = amount * 25,
        max_bet = amount >= SlotsForbiddenCityCal.Calculate.GetMaxBetAmount(player),
        free_win_amount = free_win_amount,
        epic_win = (total_payrate / 25) >= ForbiddenCityPrizeConfig[3].min_multiple
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
    if ((win_chip / (amount * 25)) >= ForbiddenCityPrizeConfig[3].min_multiple) then
        player.statistics.epicwin_num = player.statistics.epicwin_num + 1
    elseif ((win_chip / (amount * 25)) >= ForbiddenCityPrizeConfig[2].min_multiple) then
        player.statistics.megawin_num = player.statistics.megawin_num + 1
    elseif ((win_chip / (amount * 25)) >= ForbiddenCityPrizeConfig[1].min_multiple) then
        player.statistics.bigwin_num = player.statistics.bigwin_num + 1
    end

    Player:BroadCastChip(session, task, amount * 25, win_chip)

    local can_multiply = SlotsGameCal.Calculate.WinChipInMultiply(win_chip)
    if (can_multiply) then
        if ((total_payrate / 25) >= ForbiddenCityPrizeConfig[1].min_multiple and not is_free_spin) then
            response.is_multiply = CommonCal.Calculate.IsMultiply(session, win_chip)
        end

        if ((total_payrate / 25) >= ForbiddenCityPrizeConfig[1].min_multiple and not is_free_spin) then
            RobotAction.BigWinAction(session, task)
        end
    end

    --广播
    local win_info = {
        bet_amount = amount,
        total_bet = amount * 25,
        win_chip = win_chip
    }
    Communication:OnBcEvent(session, BroadcastType.AllTypes.ForbiddenCitySpin, win_info, 15)

    --opt
    local contest_id, room_id, table_id = unpack(string.split(forbidden_city.channel_id, "."))
    if (is_free_spin) then
        Spark:SlotsAward(
            player,
            {
                [1] = GameType.AllTypes.ForbiddenCity,
                [2] = "ForbiddenCity",
                [3] = table_id,
                [4] = forbidden_city.bouts_id,
                [5] = forbidden_city.bet_amount,
                [6] = win_chip,
                [7] = json.encode(origin_result),
                [8] = "[]",
                [9] = reel_file_name,
                [10] = forbidden_city.free_spin_bouts,
                [11] = CommonCal.Calculate.GetFiveLineCount(all_prize_items) > 0 and 1 or 0,
                [12] = player.record.total_spin,
                [13] = amount * 25
            }
        )
    else
        Spark:SlotsStart(
            player,
            {
                [1] = GameType.AllTypes.ForbiddenCity,
                [2] = "ForbiddenCity",
                [3] = table_id,
                [4] = forbidden_city.bouts_id,
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
    forbidden_city.spined_times = forbidden_city.spined_times + 1

    response.win_chip = win_chip

    CommonCal.Calculate.EndStart(session, task, player, request, response, forbidden_city, 25, chip_cost, win_chip)

    --gain exp
    if not is_free_spin then
        local exp = chip_cost
        local exp_request = {
            type = "SlotsForbiddenCity",
            ante_gold = amount * 25,
            gain_exp = exp
        }
        Player:GainExp(session, exp_request)
    end

    player_slots_info.content = json.encode(forbidden_city)
    CommonCal.Calculate.UpdateSlotsToDbCache(task, player, player_slots_info)

    --锦标赛玩家得分更新
    CommonCal.Calculate.UpdateTournamentPlayerInfo(session, player.game_type, player, chip_cost, win_chip)

    response.player = {
        unlock_games = player.unlock_games,
        character = {
            chip = player.character.chip,
            experience = player.character.experience,
            level = player.character.level
        },
        forbidden_city = {
            bet_amount = amount,
            free_spin_bouts = forbidden_city.free_spin_bouts,
            trigger_free_spin = forbidden_city.trigger_free_spin,
            free_total_win = forbidden_city.free_total_win
        }
    }

    return response
end

ChooseFreeSpin = function(_M, session, request)
    local response = {header = {router = "Response"}}
    local filter_ret = RequestFilter.Filter("SlotsForbiddenCity", "ChooseFreeSpin", session, request, true)
    if filter_ret then
        response.ret = filter_ret
        return response
    end

    local player = session.player
    local index = request.index

    local player_slots_info = CommonCal.Calculate.get_slots_info(session, task, player, GameType.AllTypes.ForbiddenCity)
    local forbidden_city = json.decode(player_slots_info.content)

    local ForbiddenCityFreeSpinConfig = CommonCal.Calculate.get_config(player, "ForbiddenCityFreeSpinConfig")
    local bouts_count = ForbiddenCityFreeSpinConfig[index].free_spin_count
    local multi = ForbiddenCityFreeSpinConfig[index].multi
    forbidden_city.free_spin_bouts = bouts_count
    forbidden_city.free_spin_multi = multi
    forbidden_city.trigger_free_spin = forbidden_city.trigger_free_spin - 1

    response.ret = Return.OK()
    response.player = {
        forbidden_city = {
            free_spin_bouts = forbidden_city.free_spin_bouts,
            free_spin_multi = forbidden_city.free_spin_multi,
            trigger_free_spin = forbidden_city.trigger_free_spin
        }
    }

    player_slots_info.content = json.encode(forbidden_city)
    CommonCal.Calculate.UpdateSlotsToDbCache(task, player, player_slots_info)

    return response
end

-----------------------------------------------
-- 退出房间
------------------------------------------------
Exit = function(_M, session, request)
    local response = {header = {router = "Response"}}
    local filter_ret = RequestFilter.Filter("SlotsForbiddenCity", "Exit", session, request, true)
    if filter_ret then
        response.ret = filter_ret
        return response
    end

    local player = session.player
    local task = session.task

    local player_slots_info = CommonCal.Calculate.get_slots_info(session, task, player, GameType.AllTypes.ForbiddenCity)
    local forbidden_city = json.decode(player_slots_info.content)

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
            module_id = "SlotsForbiddenCityContest",
            message_id = "SlotsForbiddenCityContest_Exit_Request"
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
        BuyLoss:Trigger(session, task, GameType.AllTypes.ForbiddenCity, player)
    if trigger_buyloss then
        forbidden_city.total_loss = total_loss
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
    forbidden_city.spined_times = 0

    response = {
        header = response.header,
        ret = Return.OK(),
        player = {
            character = {
                chip = player.character.chip
            }
        }
    }

    player_slots_info.content = json.encode(forbidden_city)
    CommonCal.Calculate.UpdateSlotsToDbCache(task, player, player_slots_info)

    LOG(RUN, INFO).Format("[SlotsForbiddenCity][Exit] ok player %s", player.id)
    return response
end
