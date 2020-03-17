require "Common/SlotsWildCircusCal"
require "Common/RequestFilter"
require "Module/DailyTask"
require "Common/CommonCal"
require "Common/RobotAction"
module("SlotsWildCircus", package.seeall)

-----------------------------------------------
-- 进入房间
------------------------------------------------
Enter = function(_M, session, request)
    local response = {header = {router = "Response"}}

    local filter_ret = RequestFilter.Filter("SlotsWildCircus", "Enter", session, request, true)
    if filter_ret then
        response.ret = filter_ret
        return response
    end

    local task = session.task
    local player = session.player
    local player_slots_info = CommonCal.Calculate.get_slots_info(session, task, player, GameType.AllTypes.WildCircus)
    local wild_circus = json.decode(player_slots_info.content)

    CommonCal.Calculate.MakeUpInRoom(session, task)

    LOG(RUN, INFO).Format("[SlotsWildCircus][Enter] SlotsWildCircus_Enter_Request begin player %s", player.id)
    local isLock = CommonCal.Calculate.LevelReq(player, GameType.AllTypes.WildCircus)

    if (isLock == 1) then
        response.ret = Return.LOCK_GAME()
        return response
    end

    local table_id = request.table_id
    local async_request = nil
    local game_room_config = GameRoomConfig[GameType.AllTypes.WildCircus]

    if (table_id and table_id > 0) then
        local channel_id = string.format("%s.%s.%s", "SlotsWildCircusContest", game_room_config.room_name, table_id)
        wild_circus.channel_id = channel_id
        async_request = {
            header = {
                router = "AsyncRequest",
                service_name = game_room_config.contest_client_name,
                task_id = task.id,
                module_id = "SlotsWildCircusContest",
                message_id = "SlotsWildCircusContest_Enter_Request"
            },
            player = {
                id = player.id,
                user = player.user,
                account = player.account,
                game_type = GameType.AllTypes.WildCircus,
                character = {
                    chip = player.character.chip,
                    vip = player.character.vip,
                    level = player.character.level,
                    experience = player.character.experience,
                    player_type = player.character.player_type
                },
                record = player.record,
                wild_circus = wild_circus
            }
        }
    else
        async_request = {
            header = {
                router = "AsyncRequest",
                service_name = game_room_config.contest_client_name,
                task_id = task.id,
                module_id = "SlotsWildCircusContest",
                message_id = "SlotsWildCircusContest_Enter_Request"
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
                wild_circus = wild_circus
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

    wild_circus.channel_id = async_response.channel_id

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

    wild_circus.bouts_id = 0
     --进场的时候把cd清空掉
    wild_circus.enter_chip = player.character.chip
    wild_circus.spined_times = 0

    response.ret = Return.OK()
    response.player = {
        wild_circus = wild_circus,
        character = {
            chip = player.character.chip
        },
        wild_circus = wild_circus
    }
    player.game_type = GameType.AllTypes.WildCircus

    player_slots_info.content = json.encode(wild_circus)
    CommonCal.Calculate.UpdateSlotsToDbCache(task, player, player_slots_info)

    return response, table_sync_notice
end

--开始slots
Start = function(_M, session, request)
    local response = {header = {router = "Response"}}

    local filter_ret = RequestFilter.Filter("SlotsWildCircus", "Start", session, request, true)
    if filter_ret then
        response.ret = filter_ret
        return response
    end

    local LineNum = #SlotsWildCircusCal.Const.Lines

    local task = session.task
    local amount
    local player = session.player

    local player_slots_info = CommonCal.Calculate.get_slots_info(session, task, player, GameType.AllTypes.WildCircus)
    local wild_circus = json.decode(player_slots_info.content)

    CommonCal.Calculate.BeginStart(session, task, player)

    if GlobalState:IsSlotsMaintenance(session, task, player.id) == 1 then
        response.ret = Return.SERVER_NEAR_MAINENANCE()
        return response
    end

    if (player.game_type ~= GameType.AllTypes.WildCircus) then
        response.ret = Return.HAVE_ALREADY_EXIT_GAME()
        return response
    end
    local is_lock = CommonCal.Calculate.IsAppear(player)
    if (is_lock == 1) then
        response.ret = Return.LOCK_GAME()
        return response
    end
    local is_free_spin = wild_circus.free_spin_bouts > 0
    response.is_free_spin = is_free_spin and 1 or 0
    local is_get_free_spin = false
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
        amount = wild_circus.bet_amount
        wild_circus.free_spin_bouts = math.max(wild_circus.free_spin_bouts - 1, 0)
        wild_circus.total_free_spin_bouts = wild_circus.total_free_spin_bouts + 1
    else
        amount = request.amount
        chip_cost = amount * LineNum

        if not Player:Consume(player, {"Chip", chip_cost}, Reason.WILD_CIRCUS_BET_CHIP_CONSUME()) then
            response.ret = Return.GAME_PLAYER_CHIP_NOT_ENOUGH()
            return response
        end

        wild_circus.bet_amount = amount
        wild_circus.free_spin_scatter_count = 0

        wild_circus.total_free_spin_bouts = 0
    end

    local WildCircusBetAmountConfig = CommonCal.Calculate.get_config(player, "WildCircusBetAmountConfig")
    local bet_amount_conf
    for k, v in ipairs(WildCircusBetAmountConfig) do
        if v.single_amount == amount then
            bet_amount_conf = v
            break
        end
    end

    local origin_result, extra_wild, reel_file_name
    local item_list = {}

    if is_free_spin then
        origin_result, reel_file_name =
            SlotsWildCircusCal.Calculate.GenItemResult(player, wild_circus.free_spin_scatter_count)
    else
        origin_result, reel_file_name = SlotsWildCircusCal.Calculate.GenItemResult(player, nil)
    end

    local item_ids = SlotsWildCircusCal.Calculate.TransResultToList(origin_result)

    local free_spin_bouts, free_item_id = SlotsWildCircusCal.Calculate.GenFreeSpinCount(origin_result)

    local free_spin_scatter_count = 0
    local new_free_spin_scatter_count = 0
    local old_free_spin_scatter_count = wild_circus.free_spin_scatter_count
    if (is_free_spin) then
        free_spin_scatter_count = SlotsWildCircusCal.Calculate.GenFreeSpinScatterCount(origin_result)
        new_free_spin_scatter_count = wild_circus.free_spin_scatter_count + free_spin_scatter_count
        if (wild_circus.free_spin_scatter_count < 3 and new_free_spin_scatter_count >= 3) then
            wild_circus.free_spin_bouts = wild_circus.free_spin_bouts + 2
        end

        if (wild_circus.free_spin_scatter_count < 8 and new_free_spin_scatter_count >= 8) then
            wild_circus.free_spin_bouts = wild_circus.free_spin_bouts + 2
        end

        if (wild_circus.free_spin_scatter_count < 13 and new_free_spin_scatter_count >= 13) then
            wild_circus.free_spin_bouts = wild_circus.free_spin_bouts + 2
        end

        wild_circus.free_spin_scatter_count = wild_circus.free_spin_scatter_count + free_spin_scatter_count
    end

    local spec_wild_list = {}
    if (wild_circus.free_spin_scatter_count >= 13) then
        --雄狮,棕熊,猴子变为WILD, Singham,BrownBear,Monkey
        table.insert(spec_wild_list, SlotsWildCircusCal.Const.Types.Singham)
        table.insert(spec_wild_list, SlotsWildCircusCal.Const.Types.BrownBear)
        table.insert(spec_wild_list, SlotsWildCircusCal.Const.Types.Monkey)
    elseif (wild_circus.free_spin_scatter_count >= 8) then
        --棕熊,猴子变为WILD, BrownBear,Monkey
        table.insert(spec_wild_list, SlotsWildCircusCal.Const.Types.BrownBear)
        table.insert(spec_wild_list, SlotsWildCircusCal.Const.Types.Monkey)
    elseif (wild_circus.free_spin_scatter_count >= 3) then
        --猴子变为WILD, Monkey
        table.insert(spec_wild_list, SlotsWildCircusCal.Const.Types.Monkey)
    end
    response.free_spin_scatter_count = wild_circus.free_spin_scatter_count
    response.spec_wild_list = spec_wild_list

    local wild_result = table.copy(origin_result)

    for i = 1, 3 do
        for j = 1, 5 do
            local is_wild = false
            for _, item in pairs(spec_wild_list) do
                if (item == wild_result[i][j]) then
                    is_wild = true
                end
            end
            if is_wild then
                wild_result[i][j] = SlotsWildCircusCal.Const.Types.Wild
            end
        end
    end

    local prize_items, total_payrate, TotalMulWildNum, test_prize_items =
        SlotsWildCircusCal.Calculate.GenPrizeInfo(player, wild_result, player.id)

    table.insert(all_prize_items, prize_items)

    local win_chip = total_payrate * amount

    if (free_spin_bouts > 0) then
        is_get_free_spin = true
    end

    if (not is_free_spin and free_spin_bouts > 0) then
        wild_circus.bouts_id = os.time()
    end

    wild_circus.free_spin_bouts = wild_circus.free_spin_bouts + free_spin_bouts

    if (not is_free_spin and wild_circus.free_spin_bouts <= 0) then --当不处于free状态并且没有free item时告诉客户端free_item_id为0
        free_item_id = 0
    end
    wild_circus.free_item_id = free_item_id

    ----记录record
    player.record.total_spin = player.record.total_spin + 1
    if is_free_spin then
        player.record.free_spin = player.record.free_spin + 1
    end

    -----记录free spin中总赢取
    if is_free_spin then
        wild_circus.free_total_win = wild_circus.free_total_win + win_chip
    else
        wild_circus.free_total_win = 0
    end

    local free_win_amount = 0
    if (is_free_spin) then
        free_win_amount = win_chip
    end

    local WildCircusPrizeConfig = CommonCal.Calculate.get_config(player, "WildCircusPrizeConfig")
    --accomplish tasks
    local task_req_data = {
        five_line = CommonCal.Calculate.GetFiveLineCount(all_prize_items),
        base_spin = not is_free_spin,
        free_spin = is_get_free_spin,
         --本次下注是否属于freespin
        win_amount = win_chip,
        bet_amount = amount * LineNum,
        max_bet = amount >= SlotsWildCircusCal.Calculate.GetMaxBetAmount(player),
        free_win_amount = free_win_amount,
        epic_win = (total_payrate / LineNum) >= WildCircusPrizeConfig[3].min_multiple
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
    if ((win_chip / (amount * LineNum)) >= WildCircusPrizeConfig[3].min_multiple) then
        player.statistics.epicwin_num = player.statistics.epicwin_num + 1
    elseif ((win_chip / (amount * LineNum)) >= WildCircusPrizeConfig[2].min_multiple) then
        player.statistics.megawin_num = player.statistics.megawin_num + 1
    elseif ((win_chip / (amount * LineNum)) >= WildCircusPrizeConfig[1].min_multiple) then
        player.statistics.bigwin_num = player.statistics.bigwin_num + 1
    end

    Player:BroadCastChip(session, task, amount * LineNum, win_chip)

    local can_multiply = SlotsGameCal.Calculate.WinChipInMultiply(win_chip)
    if (can_multiply) then
        if ((total_payrate / LineNum) >= WildCircusPrizeConfig[2].min_multiple and not is_free_spin) then
            response.is_multiply = CommonCal.Calculate.IsMultiply(session, win_chip)
        end

        if ((total_payrate / LineNum) >= WildCircusPrizeConfig[1].min_multiple and not is_free_spin) then
            RobotAction.BigWinAction(session, task)
        end
    end

    --广播
    local win_info = {
        bet_amount = amount,
        total_bet = amount * LineNum,
        win_chip = win_chip
    }
    Communication:OnBcEvent(session, BroadcastType.AllTypes.WildCircus, win_info, 15)

    if win_chip > 0 then
        Player:Obtain(player, {"Chip", win_chip}, Reason.WILD_CIRCUS_BET_CHIP_OBTAIN())

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
            item_ids = item_ids,
            prize_items = prize_items,
            win_chip = win_chip,
            bet_amount = amount,
            free_spin_scatter_count = response.free_spin_scatter_count,
            old_free_spin_scatter_count = old_free_spin_scatter_count,
            free_spin_bouts = wild_circus.free_spin_bouts,
            free_spin = rep_free_spin
        }
        RankHelper:ChallengeDailyBiggestWin(player, GameType.AllTypes.WildCircus, rep_data)
        RankHelper:ChallengeWeeklyBiggestWin(player, GameType.AllTypes.WildCircus, rep_data)
        --end
        ----记录record
        player.record.spin_won = player.record.spin_won + 1
        player.record.total_win = player.record.total_win + win_chip
        if win_chip > player.record.biggest_win then
            player.record.biggest_win = win_chip
        end
    end

    --buyloss的局数+1
    wild_circus.spined_times = wild_circus.spined_times + 1

    response.item_ids = item_ids
    response.prize_items = prize_items
    response.win_chip = win_chip

    local contest_id, room_id, table_id = unpack(string.split(wild_circus.channel_id, "."))
    if (is_free_spin) then
        Spark:SlotsAward(
            player,
            {
                [1] = GameType.AllTypes.WildCircus,
                [2] = "WildCircus",
                [3] = table_id,
                [4] = wild_circus.bouts_id,
                [5] = wild_circus.bet_amount,
                [6] = win_chip,
                [7] = json.encode(origin_result),
                [8] = "[]",
                [9] = reel_file_name,
                [10] = wild_circus.free_spin_bouts,
                [11] = CommonCal.Calculate.GetFiveLineCount(all_prize_items) > 0 and 1 or 0,
                [12] = player.record.total_spin,
                [13] = amount * LineNum
            }
        )
    else
        Spark:SlotsStart(
            player,
            {
                [1] = GameType.AllTypes.WildCircus,
                [2] = "WildCircus",
                [3] = table_id,
                [4] = wild_circus.bouts_id,
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
    response.ret = Return.OK()

    if (Base.Enviroment.pro_spec_t ~= "online" and GlobalSlotsTest[player.id] ~= nil) then
        local test_response = table.copy(response)
        test_response.prize_items = test_prize_items

        GlobalSlotsTest[player.id].response = json.encode(test_response)

        Task:Work(
            function()
                CommonCal.Calculate.SlotsTestUpdate(player.id)
            end
        )
    end

    CommonCal.Calculate.EndStart(session, task, player, request, response, wild_circus, LineNum, chip_cost, win_chip)

    --gain exp
    if not is_free_spin then
        local exp = chip_cost
        local exp_request = {
            type = "SlotsWildCircus",
            ante_gold = amount * LineNum,
            gain_exp = exp
        }
        Player:GainExp(session, exp_request)
    end

    player_slots_info.content = json.encode(wild_circus)
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
        wild_circus = {
            bet_amount = amount,
            bonus_progress = wild_circus.bonus_progress,
            free_spin_bouts = wild_circus.free_spin_bouts,
            free_total_win = wild_circus.free_total_win,
            free_item_id = wild_circus.free_item_id
        }
    }

    return response
end

-----------------------------------------------
-- 退出房间
------------------------------------------------
Exit = function(_M, session, request)
    local response = {header = {router = "Response"}}

    local filter_ret = RequestFilter.Filter("SlotsWildCircus", "Exit", session, request, true)
    if filter_ret then
        response.ret = filter_ret
        return response
    end

    local player = session.player
    local task = session.task

    local player_slots_info = CommonCal.Calculate.get_slots_info(session, task, player, GameType.AllTypes.WildCircus)
    local wild_circus = json.decode(player_slots_info.content)

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
            module_id = "SlotsWildCircusContest",
            message_id = "SlotsWildCircusContest_Exit_Request"
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
        BuyLoss:Trigger(session, task, GameType.AllTypes.WildCircus, player) ---当玩家钱减少到一定数量时，提示玩家充值
    if trigger_buyloss then
        wild_circus.total_loss = total_loss
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
    wild_circus.spined_times = 0
    response = {
        header = response.header,
        ret = Return.OK(),
        player = {
            character = {
                chip = player.character.chip
            }
        }
    }
    LOG(RUN, INFO).Format("[SlotsWildCircus][Exit] ok player %s, game type is: %s", player.id, player.game_type)

    player_slots_info.content = json.encode(wild_circus)
    CommonCal.Calculate.UpdateSlotsToDbCache(task, player, player_slots_info)

    return response
end
