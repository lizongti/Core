require "Common/SlotsAliceinWonderlandCal"
require "Common/RequestFilter"
require "Module/DailyTask"
require "Common/CommonCal"
require "Common/RobotAction"
module("SlotsAliceinWonderland", package.seeall)

-----------------------------------------------
-- 进入房间
------------------------------------------------
Enter = function(_M, session, request)
    local response = {header = {router = "Response"}}
    local filter_ret = RequestFilter.Filter("SlotsAliceinWonderland", "Enter", session, request, true)
    if filter_ret then
        response.ret = filter_ret
        return response
    end
    local task = session.task
    local player = session.player
    LOG(RUN, INFO).Format("[SlotsAliceinWonderlandContest][Enter]player %s", player.id)
    CommonCal.Calculate.MakeUpInRoom(session, task)
    local isLock = CommonCal.Calculate.LevelReq(player, GameType.AllTypes.AliceinWonderland)
    if (isLock == 1) then
        response.ret = Return.LOCK_GAME()
        return response
    end

    local player_slots_info =
        CommonCal.Calculate.get_slots_info(session, task, player, GameType.AllTypes.AliceinWonderland)
    local alicein_wonderland = json.decode(player_slots_info.content)

    local game_room_config = GameRoomConfig[GameType.AllTypes.AliceinWonderland]
    local table_id = request.table_id
    local async_request = nil

    if (table_id and table_id > 0) then
        local channel_id =
            string.format("%s.%s.%s", "SlotsAliceinWonderlandContest", game_room_config.room_name, table_id)
        alicein_wonderland.channel_id = channel_id
        async_request = {
            header = {
                router = "AsyncRequest",
                service_name = game_room_config.contest_client_name,
                task_id = task.id,
                module_id = "SlotsAliceinWonderlandContest",
                message_id = "SlotsAliceinWonderlandContest_Enter_Request"
            },
            player = {
                id = player.id,
                user = player.user,
                account = player.account,
                game_type = GameType.AllTypes.AliceinWonderland,
                character = {
                    chip = player.character.chip,
                    vip = player.character.vip,
                    level = player.character.level,
                    experience = player.character.experience,
                    player_type = player.character.player_type
                },
                record = player.record,
                alicein_wonderland = alicein_wonderland
            }
        }
    else
        async_request = {
            header = {
                router = "AsyncRequest",
                service_name = game_room_config.contest_client_name,
                task_id = task.id,
                module_id = "SlotsAliceinWonderlandContest",
                message_id = "SlotsAliceinWonderlandContest_Enter_Request"
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
                alicein_wonderland = alicein_wonderland
            }
        }
    end

    local async_response = session:ContactPacket(task, async_request)
    if async_response.ret.code ~= 0 then
        response.ret = async_response.ret
        return response
    end
    local table_sync_notice = {header = {router = "Notice"}, table = async_response.table}

    alicein_wonderland.channel_id = async_response.channel_id

    -- opt entertable
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

    alicein_wonderland.bouts_id = 0 -- 进场的时候把cd清空掉
    alicein_wonderland.enter_chip = player.character.chip
    alicein_wonderland.spined_times = 0

    -- response.item_ids = SlotsOpenSesameCal.Calculate.GenInitItem()
    response.ret = Return.OK()
    response.player = {
        alicein_wonderland = alicein_wonderland,
        character = {chip = player.character.chip}
    }
    player.game_type = GameType.AllTypes.AliceinWonderland

    -----------------紧急修复-------------------
    player_slots_info.content = json.encode(alicein_wonderland)
    CommonCal.Calculate.UpdateSlotsToDbCache(task, player, player_slots_info)

    return response, table_sync_notice
end

UpdateBetAmount = function(_M, session, request)
    local response = {header = {router = "Response"}}

    local filter_ret = RequestFilter.Filter("SlotsAliceinWonderland", "UpdateBetAmount", session, request, true)
    if filter_ret then
        response.ret = filter_ret
        return response
    end

    local task = session.task

    local betAmount = request.amount

    local game_room_config = GameRoomConfig[GameType.AllTypes.AliceinWonderland]
    local async_request = {
        header = {
            router = "AsyncRequest",
            service_name = game_room_config.contest_client_name,
            task_id = task.id,
            module_id = "SlotsAliceinWonderlandContest",
            message_id = "SlotsAliceinWonderlandContest_Award_Request"
        },
        amount = betAmount
    }

    local async_response = session:ContactPacket(task, async_request)

    response.ret = Return.OK()
    response.amount = async_response.amount

    return response
end

-- 开始slots
Start = function(_M, session, request)
    local response = {header = {router = "Response"}}

    local filter_ret = RequestFilter.Filter("SlotsAliceinWonderland", "Start", session, request, true)
    if filter_ret then
        response.ret = filter_ret
        return response
    end

    local task = session.task
    local amount
    local player = session.player
    CommonCal.Calculate.BeginStart(session, task, player)

    LOG(RUN, INFO).Format("[SlotsAliceinWonderland][Start] amount begin: %s", amount)

    if GlobalState:IsSlotsMaintenance(session, task, player.id) == 1 then
        response.ret = Return.SERVER_NEAR_MAINENANCE()
        return response
    end

    if (player.game_type ~= GameType.AllTypes.AliceinWonderland) then
        response.ret = Return.HAVE_ALREADY_EXIT_GAME()
        return response
    end

    local is_lock = CommonCal.Calculate.IsAppear(player)
    if (is_lock == 1) then
        response.ret = Return.LOCK_GAME()
        return response
    end

    local player_slots_info =
        CommonCal.Calculate.get_slots_info(session, task, player, GameType.AllTypes.AliceinWonderland)
    local alicein_wonderland = json.decode(player_slots_info.content)

    local save_data = json.decode(alicein_wonderland.json_str)

    local is_free_spin = alicein_wonderland.free_spin_bouts > 0

    local game_room_config = GameRoomConfig[player.game_type]
    ------201810310936开始------------------

    local extern_param = {}

    local player_feature_condition = CommonCal.Calculate.get_feature_condition(session, task, player, player.game_type)
    ------201810310936结束------------------

    local player_extern = CommonCal.Calculate.get_player_extern(session, task, player)

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

    local hasWild = 1

    local jackpotAmount = 0

    local chip_cost = 0

    if (save_data.total_free_spin_bouts == nil) then
        save_data.total_free_spin_bouts = 0
    end

    -- free spin不扣钱, free spin下amount不会改
    if is_free_spin then
        player_feature_condition.free_spin_count = player_feature_condition.free_spin_count + 1

        amount = alicein_wonderland.bet_amount
        jackpotAmount = amount * 25
        alicein_wonderland.free_spin_bouts = math.max(alicein_wonderland.free_spin_bouts - 1, 0)

        save_data.total_free_spin_bouts = save_data.total_free_spin_bouts + 1
    else
        amount = request.amount
        chip_cost = amount * 25
        jackpotAmount = amount * 25
        if not Player:Consume(player, {"Chip", chip_cost}, Reason.ALICEINWONDERLAND_BET_CHIP_CONSUME()) then
            response.ret = Return.GAME_PLAYER_CHIP_NOT_ENOUGH()
            return response
        end
        alicein_wonderland.bet_amount = amount

        if (chip_cost >= 50000) then
            alicein_wonderland.protect_number = -1
        end
        save_data.total_free_spin_bouts = 0
    end

    ------201810310936开始------------------
    extern_param.chip_cost = chip_cost

    player_feature_condition.spin_num = player_feature_condition.spin_num + 1
    ------201810310936结束------------------

    response.is_free_spin = is_free_spin and 1 or 0
    local flag = 0

    if (GlobalSlotsTest[player.id] ~= nil) then
        if (GlobalSlotsTest[player.id].flag == 1) then
            flag = 1
        end
    end

    local winAmount = 0
    local amountArray = 0
    if (not winAmount) then
        winAmount = 0
    end

    local bet_amount_conf

    local AliceinWonderlandBetAmountConfig = _G[GameMapConfig[player.game_type].bet_amount_config]

    for k, v in ipairs(AliceinWonderlandBetAmountConfig) do
        if v.single_amount == amount then
            bet_amount_conf = v
            break
        end
    end
    response.ret = Return.OK()

    if (not is_free_spin) then
        alicein_wonderland.protect_index = alicein_wonderland.protect_index + 1
    end

    local is_get_free_spin = false
    local origin_result, extra_wild, reel_file_name
    local wild = {{}, {}, {}, {}, {}}
    local result = {{}, {}, {}, {}, {}}
    local item_list = {}
    local all_prize_items = {}
    local loop_num = 0
    local total_win_chip = 0
    local is_bonus = 0

    local add_free_bouts = 0

    while hasWild == 1 do
        CommonCal.Calculate.SetLoopNum(player.id, loop_num)

        if is_free_spin then
            origin_result, extra_wild, hasWild, reel_file_name =
                SlotsAliceinWonderlandCal.Calculate.GenItemResult(
                player,
                result,
                wild,
                true,
                winAmount,
                alicein_wonderland.free_item_id,
                nil,
                player_extern
            )
        else
            origin_result, extra_wild, hasWild, reel_file_name =
                SlotsAliceinWonderlandCal.Calculate.GenItemResult(
                player,
                result,
                wild,
                false,
                winAmount,
                nil,
                nil,
                player_extern
            )
        end

        local result_with_wild = SlotsAliceinWonderlandCal.Calculate.GenResultWithWild(origin_result, extra_wild)
        local prize_items, total_payrate =
            SlotsAliceinWonderlandCal.Calculate.GenPrizeInfo(
            player,
            result_with_wild,
            winAmount,
            origin_result,
            is_free_spin
        )
        table.insert(all_prize_items, prize_items)
        local item_ids = SlotsAliceinWonderlandCal.Calculate.TransResultToList(origin_result)
        local prize_items = prize_items

        local win_chip = total_payrate * amount

        total_win_chip = total_win_chip + win_chip

        local free_spin_bouts, free_item_id = SlotsAliceinWonderlandCal.Calculate.GenFreeSpinCount(result_with_wild)
        if (free_spin_bouts > 0) then
            is_get_free_spin = true
            add_free_bouts = free_spin_bouts
        end

        local bonus_count = SlotsAliceinWonderlandCal.Calculate.GetBonusCount(result_with_wild)
        if (is_bonus == 0) then
            if (bonus_count >= 3) then
                is_bonus = 1
            end
        end

        alicein_wonderland.free_spin_bouts = alicein_wonderland.free_spin_bouts + free_spin_bouts

        -----记录free spin中总赢取
        if is_free_spin then
            alicein_wonderland.free_total_win = alicein_wonderland.free_total_win + win_chip
        else
            alicein_wonderland.free_total_win = 0
        end

        if (loop_num > 0) then
            local SlotsAliceinWonderland_Item = {}
            SlotsAliceinWonderland_Item.item_ids = item_ids
            SlotsAliceinWonderland_Item.prize_items = prize_items
            SlotsAliceinWonderland_Item.win_chip = win_chip
            table.insert(item_list, SlotsAliceinWonderland_Item)
        else
            response.item_ids = item_ids
            response.prize_items = prize_items
            response.win_chip = win_chip
        end
        loop_num = loop_num + 1
    end
    response.item_list = item_list

    response.amount = amountArray

    save_data.is_bonus = is_bonus

    DailyMissionsCal.Calculate.UpdateGameDailyMissions(
        session,
        player,
        amount,
        chip_cost,
        total_win_chip,
        is_free_spin,
        player.game_type,
        add_free_bouts
    )

    ----记录record
    player.record.total_spin = player.record.total_spin + 1
    if is_free_spin then
        player.record.free_spin = player.record.free_spin + 1
    end

    -- buyloss的局数+1
    alicein_wonderland.spined_times = alicein_wonderland.spined_times + 1

    if (winAmount > 0) then
        Player:Obtain(player, {"Chip", winAmount}, Reason.ALICEINWONDERLAND_BET_CHIP_JACKPOT())
    end

    local free_win_amount = 0
    if (is_free_spin) then
        free_win_amount = total_win_chip
    end

    if (not is_free_spin and is_get_free_spin) then
        alicein_wonderland.bouts_id = os.time()
    end

    local AliceinWonderlandPrizeConfig = _G[GameMapConfig[player.game_type].prize_config]

    -- accomplish tasks
    local task_req_data = {
        five_line = CommonCal.Calculate.GetFiveLineCount(all_prize_items),
        base_spin = not is_free_spin,
        free_spin = is_get_free_spin, -- 本次下注是否属于freespin
        win_amount = total_win_chip,
        bet_amount = amount * 25,
        max_bet = amount >= SlotsAliceinWonderlandCal.Calculate.GetMaxBetAmount(player),
        free_win_amount = free_win_amount,
        epic_win = (total_win_chip / jackpotAmount) >= AliceinWonderlandPrizeConfig[3].min_multiple
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
    if ((total_win_chip / (amount * 25)) >= AliceinWonderlandPrizeConfig[3].min_multiple) then
        player.statistics.epicwin_num = player.statistics.epicwin_num + 1
    elseif ((total_win_chip / (amount * 25)) >= AliceinWonderlandPrizeConfig[2].min_multiple) then
        player.statistics.megawin_num = player.statistics.megawin_num + 1
    elseif ((total_win_chip / (amount * 25)) >= AliceinWonderlandPrizeConfig[1].min_multiple) then
        player.statistics.bigwin_num = player.statistics.bigwin_num + 1
    end

    if (loop_num > 1) then
        local number = total_win_chip / (amount * 25)
        number = math.floor(number + 0.5)

        Spark:FeatureSpecialWin(
            player,
            {
                [1] = player.game_type,
                [2] = "AliceinWonderland",
                [3] = is_free_spin and 1 or 0,
                [4] = "ExpandingWildRespin",
                [5] = number
            }
        )
    end

    -- 广播
    local win_info = {bet_amount = amount, total_bet = amount * 25, win_chip = total_win_chip}
    Communication:OnBcEvent(session, BroadcastType.AllTypes.AliceinWonderland, win_info, 15)

    response.is_multiply = 0

    local can_multiply = SlotsGameCal.Calculate.WinChipInMultiply(total_win_chip)
    if (can_multiply) then
        if ((total_win_chip / (amount * 25)) >= AliceinWonderlandPrizeConfig[1].min_multiple and not is_free_spin) then
            response.is_multiply = CommonCal.Calculate.IsMultiply(session, total_win_chip)
        end

        if ((total_win_chip / (amount * 25)) >= AliceinWonderlandPrizeConfig[1].min_multiple and not is_free_spin) then
            RobotAction.BigWinAction(session, task)
        end
    end

    if (alicein_wonderland.protect_number == 0) then
        alicein_wonderland.protect_number = math.random_ext(player, 5, 10)
    end

    if total_win_chip > 0 then
        Player:Obtain(player, {"Chip", total_win_chip}, Reason.ALICEINWONDERLAND_BET_CHIP_OBTAIN())

        -- 记录每日、每周赢钱,进排行榜
        RankHelper:ChallengeDailyWin(player)
        RankHelper:ChallengeWeeklyWin(player)
        -- free spin不计入biggest win的统计
        -- if not is_free_spin then
        local rep_free_spin = 0
        if (is_free_spin) then
            rep_free_spin = 1
        end
        local rep_data = {
            item_list = response.item_list,
            item_ids = response.item_ids,
            prize_items = response.prize_items,
            win_chip = response.win_chip,
            all_win_chip = total_win_chip,
            bet_amount = amount,
            free_spin = rep_free_spin
        }

        RankHelper:ChallengeDailyBiggestWin(player, GameType.AllTypes.AliceinWonderland, rep_data)
        RankHelper:ChallengeWeeklyBiggestWin(player, GameType.AllTypes.AliceinWonderland, rep_data)
        -- end
        ----记录record
        player.record.spin_won = player.record.spin_won + 1
        player.record.total_win = player.record.total_win + total_win_chip
        if total_win_chip > player.record.biggest_win then
            player.record.biggest_win = total_win_chip
        end
    end

    Player:BroadCastChip(session, task, jackpotAmount, total_win_chip)

    alicein_wonderland.jackpot_win_chip = winAmount
    local contest_id, room_id, table_id = unpack(string.split(alicein_wonderland.channel_id, "."))
    local feature_items = {}
    for k, v in ipairs(item_list) do
        table.insert(feature_items, v.item_ids)
    end

    if (is_free_spin) then
        Spark:SlotsAward(
            player,
            {
                [1] = GameType.AllTypes.AliceinWonderland,
                [2] = "AliceinWonderland",
                [3] = table_id,
                [4] = alicein_wonderland.bouts_id,
                [5] = alicein_wonderland.bet_amount,
                [6] = total_win_chip,
                [7] = json.encode(origin_result),
                [8] = json.encode(feature_items),
                [9] = reel_file_name,
                [10] = alicein_wonderland.free_spin_bouts,
                [11] = CommonCal.Calculate.GetFiveLineCount(all_prize_items) > 0 and 1 or 0,
                [12] = player.record.total_spin,
                [13] = amount * 25
            }
        )
    else
        Spark:SlotsStart(
            player,
            {
                [1] = GameType.AllTypes.AliceinWonderland,
                [2] = "AliceinWonderland",
                [3] = table_id,
                [4] = alicein_wonderland.bouts_id,
                [5] = amount,
                [6] = amount * 25,
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

    CommonCal.Calculate.EndStart(
        session,
        task,
        player,
        request,
        response,
        alicein_wonderland,
        25,
        chip_cost,
        total_win_chip
    )

    -- gain exp
    if not is_free_spin then
        local exp = chip_cost
        local exp_request = {type = "SlotsAliceinWonderland", ante_gold = amount * 25, gain_exp = exp}
        Player:GainExp(session, exp_request)
    end

    alicein_wonderland.json_str = json.encode(save_data)

    player_slots_info.content = json.encode(alicein_wonderland)
    CommonCal.Calculate.UpdateSlotsToDbCache(task, player, player_slots_info)

    ------201810310936开始------------------
    CommonCal.Calculate.UpdateToDbCache(task, player, "feature_condition", player_feature_condition)
    ------201810310936结束------------------

    -- 锦标赛玩家得分更新
    CommonCal.Calculate.UpdateTournamentPlayerInfo(session, player.game_type, player, chip_cost, total_win_chip)

    response.player = {
        unlock_games = player.unlock_games,
        character = {
            chip = player.character.chip,
            experience = player.character.experience,
            level = player.character.level
        },
        alicein_wonderland = {
            bet_amount = amount,
            bonus_progress = alicein_wonderland.bonus_progress,
            free_spin_bouts = alicein_wonderland.free_spin_bouts,
            free_total_win = alicein_wonderland.free_total_win,
            is_jackpot = alicein_wonderland.is_jackpot,
            json_str = alicein_wonderland.json_str
        }
    }

    return response
end

-----------------------------------------------
-- 退出房间
------------------------------------------------
Exit = function(_M, session, request)
    local response = {header = {router = "Response"}}
    local filter_ret = RequestFilter.Filter("SlotsAliceinWonderland", "Exit", session, request, true)
    if filter_ret then
        response.ret = filter_ret
        return response
    end

    local player = session.player
    local task = session.task
    local game_room_config = GameRoomConfig[player.game_type]
    if (game_room_config == nil) then
        response.ret = Return.HAVE_ALREADY_EXIT_GAME()
        return response
    end
    local player_slots_info =
        CommonCal.Calculate.get_slots_info(session, task, player, GameType.AllTypes.AliceinWonderland)
    local alicein_wonderland = json.decode(player_slots_info.content)

    local async_request = {
        header = {
            router = "AsyncRequest",
            service_name = game_room_config.contest_client_name,
            task_id = task.id,
            module_id = "SlotsAliceinWonderlandContest",
            message_id = "SlotsAliceinWonderlandContest_Exit_Request"
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
        BuyLoss:Trigger(session, task, GameType.AllTypes.AliceinWonderland, player) ---当玩家钱减少到一定数量时，提示玩家充值
    if trigger_buyloss then
        alicein_wonderland.total_loss = total_loss
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
    alicein_wonderland.spined_times = 0

    response = {
        header = response.header,
        ret = Return.OK(),
        player = {character = {chip = player.character.chip}}
    }

    player_slots_info.content = json.encode(alicein_wonderland)
    CommonCal.Calculate.UpdateSlotsToDbCache(task, player, player_slots_info)
    LOG(RUN, INFO).Format("[SlotsAliceinWonderland][Exit] ok player %s", player.id)
    return response
end
