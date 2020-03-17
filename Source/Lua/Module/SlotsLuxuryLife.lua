require "Common/SlotsLuxuryLifeCal"
require "Common/RequestFilter"
require "Module/DailyTask"
require "Common/CommonCal"
require "Common/RobotAction"
module("SlotsLuxuryLife", package.seeall)

-----------------------------------------------
-- 进入房间
------------------------------------------------
Enter = function(_M, session, request)
    local response = {header = {router = "Response"}}

    local filter_ret = RequestFilter.Filter("SlotsLuxuryLife", "Enter", session, request, true)
    if filter_ret then
        response.ret = filter_ret
        return response
    end

    local task = session.task
    local player = session.player

    local player_slots_info = CommonCal.Calculate.get_slots_info(session, task, player, GameType.AllTypes.LuxuryLife)
    local luxury_life = json.decode(player_slots_info.content)

    CommonCal.Calculate.MakeUpInRoom(session, task)

    LOG(RUN, INFO).Format("[SlotsLuxuryLife][Enter] player %s", player.id)

    local isLock = CommonCal.Calculate.LevelReq(player, GameType.AllTypes.LuxuryLife)
    if (isLock == 1) then
        response.ret = Return.LOCK_GAME()
        return response
    end

    local table_id = request.table_id
    local async_request = nil
    local game_room_config = GameRoomConfig[GameType.AllTypes.LuxuryLife]

    if (table_id and table_id > 0) then
        local channel_id = string.format("%s.%s.%s", "SlotsLuxuryLifeContest", game_room_config.room_name, table_id)
        luxury_life.channel_id = channel_id
        async_request = {
            header = {
                router = "AsyncRequest",
                service_name = game_room_config.contest_client_name,
                task_id = task.id,
                module_id = "SlotsLuxuryLifeContest",
                message_id = "SlotsLuxuryLifeContest_Enter_Request"
            },
            player = {
                id = player.id,
                user = player.user,
                account = player.account,
                game_type = GameType.AllTypes.LuxuryLife,
                character = {
                    chip = player.character.chip,
                    vip = player.character.vip,
                    level = player.character.level,
                    experience = player.character.experience,
                    player_type = player.character.player_type
                },
                record = player.record,
                luxury_life = luxury_life
            }
        }
    else
        async_request = {
            header = {
                router = "AsyncRequest",
                service_name = game_room_config.contest_client_name,
                task_id = task.id,
                module_id = "SlotsLuxuryLifeContest",
                message_id = "SlotsLuxuryLifeContest_Enter_Request"
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
                luxury_life = luxury_life
            }
        }
    end

    LOG(RUN, INFO).Format("[SlotsLuxuryLife][Enter] SlotsLuxuryLifeContest_Enter_Request player %s", player.id)
    local async_response = session:ContactPacket(task, async_request)

    if async_response.ret.code ~= 0 then
        response.ret = async_response.ret
        return response
    end
    local table_sync_notice = {header = {router = "Notice"}, table = async_response.table}

    luxury_life.channel_id = async_response.channel_id

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

    luxury_life.bouts_id = 0 -- 进场的时候把cd清空掉
    luxury_life.enter_chip = player.character.chip
    luxury_life.spined_times = 0

    response.ret = Return.OK()
    response.player = {
        luxury_life = luxury_life,
        character = {chip = player.character.chip},
        luxury_life = luxury_life
    }
    player.game_type = GameType.AllTypes.LuxuryLife

    player_slots_info.content = json.encode(luxury_life)
    CommonCal.Calculate.UpdateSlotsToDbCache(task, player, player_slots_info)

    return response, table_sync_notice
end

-- 开始slots
Start = function(_M, session, request)
    local response = {header = {router = "Response"}}

    local filter_ret = RequestFilter.Filter("SlotsLuxuryLife", "Start", session, request, true)
    if filter_ret then
        response.ret = filter_ret
        return response
    end

    local LineNum = 40
    local task = session.task
    local amount
    local player = session.player

    local player_slots_info = CommonCal.Calculate.get_slots_info(session, task, player, GameType.AllTypes.LuxuryLife)
    local luxury_life = json.decode(player_slots_info.content)

    CommonCal.Calculate.BeginStart(session, task, player)

    if GlobalState:IsSlotsMaintenance(session, task, player.id) == 1 then
        response.ret = Return.SERVER_NEAR_MAINENANCE()
        return response
    end

    if (player.game_type ~= GameType.AllTypes.LuxuryLife) then
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
    local is_free_spin = luxury_life.free_spin_bouts > 0

    response.is_free_spin = is_free_spin and 1 or 0
    if (luxury_life.free_spin_progress_str) then
        local free_spin_progress_array = {}
        free_spin_progress_array = json.decode(luxury_life.free_spin_progress_str)
        if (free_spin_progress_array[1] == nil) then
            free_spin_progress_array[1] = {}
        end
        if (#free_spin_progress_array[1] == 4) then
            free_spin_progress_array = {{}, {}}
        end
        if (free_spin_progress_array[2] == nil) then
            free_spin_progress_array[2] = {}
        end
        if (#free_spin_progress_array[2] == 4) then
            free_spin_progress_array = {{}, {}}
        end
        -- free_spin_progress_array[1] = table.DeepCopy(free_spin_progress_array[2])
        for k1, v1 in ipairs(free_spin_progress_array[1]) do
            local is_exist = 0
            for k2, v2 in ipairs(free_spin_progress_array[2]) do
                if (v1 == v2) then
                    is_exist = 1
                    break
                end
            end
            if (is_exist == 0) then
                table.insert(free_spin_progress_array[2], v1)
            end
        end
        free_spin_progress_array[1] = table.DeepCopy(free_spin_progress_array[2])
        luxury_life.free_spin_progress_str = json.encode(free_spin_progress_array)
    end

    -- free spin不扣钱, free spin下amount不会改
    local chip_cost = 0
    if is_free_spin then
        amount = luxury_life.bet_amount
        luxury_life.free_spin_bouts = math.max(luxury_life.free_spin_bouts - 1, 0)
    else
        amount = request.amount
        chip_cost = amount * LineNum
        if not Player:Consume(player, {"Chip", chip_cost}, Reason.LUXURY_LIFE_BET_CHIP_CONSUME()) then
            response.ret = Return.GAME_PLAYER_CHIP_NOT_ENOUGH()
            return response
        end
        luxury_life.bet_amount = amount
    end

    local LuxuryLifeBetAmountConfig = CommonCal.Calculate.get_config(player, "LuxuryLifeBetAmountConfig")
    local bet_amount_conf
    for k, v in ipairs(LuxuryLifeBetAmountConfig) do
        if v.single_amount == amount then
            bet_amount_conf = v
            break
        end
    end

    -- local item_list = {}
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
    local result = {{}, {}, {}, {}, {}, {}}

    local loop_num = 0

    luxury_life.special_item_str = "[]"
    while has_freeze > 0 and loop_num < 2 do
        has_freeze = 0
        local free_spin_num = 0
        CommonCal.Calculate.SetLoopNum(player.id, loop_num)

        local respin_items_str = nil

        origin_result, reel_file_name =
            SlotsLuxuryLifeCal.Calculate.GenItemResult(player, result, is_free_spin, loop_num, freeze_list)

        freeze_list = SlotsLuxuryLifeCal.Calculate.IsFreeze(origin_result)
        has_freeze = #freeze_list

        local local_wild_result = table.DeepCopy(origin_result)
        if (has_freeze > 0) then
            table.insert(all_freeze_items, json.encode(freeze_list))

            SlotsLuxuryLifeCal.Calculate.GenWildResult(local_wild_result, freeze_list)
        end

        local prize_items, total_payrate =
            SlotsLuxuryLifeCal.Calculate.GenPrizeInfo(player, local_wild_result, is_free_spin)

        local local_big_result = table.DeepCopy(origin_result)

        SlotsLuxuryLifeCal.Calculate.ReplaceBigItem(is_free_spin, local_big_result)

        local item_ids = SlotsLuxuryLifeCal.Calculate.TransResultToList(local_big_result)
        local prize_items = prize_items

        local win_chip = total_payrate * amount

        total_win_chip = total_win_chip + win_chip

        if (not is_free_spin) then
            if not luxury_life.free_spin_progress_str then
                return
            end
            local free_spin_progress_array = json.decode(luxury_life.free_spin_progress_str)

            local special_item_array = json.decode(luxury_life.special_item_str)
            local special_item = 0
            free_spin_progress_array, special_item =
                SlotsLuxuryLifeCal.Calculate.AddFreeProgress(loop_num, free_spin_progress_array, origin_result)
            table.insert(special_item_array, special_item)
            if (special_item > 0) then
                local his_bet_mount_array = json.decode(luxury_life.his_bet_mount)
                table.insert(his_bet_mount_array, amount)
                luxury_life.his_bet_mount = json.encode(his_bet_mount_array)
            end

            luxury_life.free_spin_progress_str = json.encode(free_spin_progress_array)
            luxury_life.special_item_str = json.encode(special_item_array)
            if (#free_spin_progress_array[loop_num + 1] == 4 and not is_get_free_spin) then
                is_get_free_spin = true
                luxury_life.free_spin_bouts = luxury_life.free_spin_bouts + 10

                local his_bet_mount_array = json.decode(luxury_life.his_bet_mount)
                if (#his_bet_mount_array > 0) then
                    local total_mount = 0
                    for k, v in ipairs(his_bet_mount_array) do
                        total_mount = total_mount + v
                    end
                    local equa_mount = total_mount / #his_bet_mount_array

                    if (equa_mount <= LuxuryLifeBetAmountConfig[1].single_amount) then
                        luxury_life.bet_amount = LuxuryLifeBetAmountConfig[1].single_amount
                    elseif (equa_mount >= LuxuryLifeBetAmountConfig[#LuxuryLifeBetAmountConfig].single_amount) then
                        luxury_life.bet_amount = LuxuryLifeBetAmountConfig[#LuxuryLifeBetAmountConfig].single_amount
                    else
                        for k, v in ipairs(LuxuryLifeBetAmountConfig) do
                            if
                                equa_mount <= v.single_amount and
                                    equa_mount > LuxuryLifeBetAmountConfig[k - 1].single_amount
                             then
                                luxury_life.bet_amount = v.single_amount
                                break
                            end
                        end
                    end
                end

            -- luxury_life.his_bet_mount = "[]"
            end
        end

        ----记录record
        player.record.total_spin = player.record.total_spin + 1
        if is_free_spin then
            player.record.free_spin = player.record.free_spin + 1
        end

        -----记录free spin中总赢取
        if is_free_spin then
            luxury_life.free_total_win = luxury_life.free_total_win + win_chip
        else
            luxury_life.free_total_win = 0
        end

        table.insert(all_prize_items, {prize_items = prize_items})
        table.insert(win_chips, win_chip)
        all_win_chip = win_chip + all_win_chip

        if (loop_num == 0) then
            response.item_ids = item_ids
        else
            local respin_items_list = {}
            for i = 1, 6 do
                for j = 1, 4 do
                    if (local_big_result[j][i] ~= 0) then
                        table.insert(respin_items_list, local_big_result[j][i])
                    end
                end
            end

            respin_items_str = json.encode(respin_items_list)
            table.insert(all_respin_items, respin_items_str)
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

    -- 广播
    local win_info = {bet_amount = amount, total_bet = amount * LineNum, win_chip = total_win_chip}
    Communication:OnBcEvent(session, BroadcastType.AllTypes.LuxuryLife, win_info, 15)

    local free_win_amount = 0
    if (is_free_spin) then
        free_win_amount = total_win_chip
    end

    if (not is_free_spin and is_get_free_spin) then
        luxury_life.bouts_id = os.time()
    end

    local LuxuryLifePrizeConfig = CommonCal.Calculate.get_config(player, "LuxuryLifePrizeConfig")
    -- accomplish tasks
    local task_req_data = {
        five_line = CommonCal.Calculate.GetFiveLineCount(all_prize_items),
        base_spin = not is_free_spin,
        free_spin = is_get_free_spin, -- 本次下注是否属于freespin
        win_amount = total_win_chip,
        bet_amount = amount * LineNum,
        max_bet = amount >= SlotsLuxuryLifeCal.Calculate.GetMaxBetAmount(player),
        free_win_amount = free_win_amount,
        epic_win = (total_win_chip / (amount * LineNum)) >= LuxuryLifePrizeConfig[3].min_multiple
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
    if ((total_win_chip / (amount * LineNum)) >= LuxuryLifePrizeConfig[3].min_multiple) then
        player.statistics.epicwin_num = player.statistics.epicwin_num + 1
    elseif ((total_win_chip / (amount * LineNum)) >= LuxuryLifePrizeConfig[2].min_multiple) then
        player.statistics.megawin_num = player.statistics.megawin_num + 1
    elseif ((total_win_chip / (amount * LineNum)) >= LuxuryLifePrizeConfig[1].min_multiple) then
        player.statistics.bigwin_num = player.statistics.bigwin_num + 1
    end

    Player:BroadCastChip(session, task, amount * LineNum, total_win_chip)

    response.freeze_list = all_freeze_items
    response.all_respin_items = all_respin_items
    response.all_prize_items = all_prize_items
    response.all_win_chip = all_win_chip
    response.win_chip = win_chips

    -- buyloss的局数+1
    luxury_life.spined_times = luxury_life.spined_times + 1

    if total_win_chip > 0 then
        Player:Obtain(player, {"Chip", total_win_chip}, Reason.LUXURY_LIFE_BET_CHIP_OBTAIN())

        -- 记录每日、每周赢钱,进排行榜
        RankHelper:ChallengeDailyWin(player)
        RankHelper:ChallengeWeeklyWin(player)
        -- free spin不计入biggest win的统计
        -- if not is_free_spin then
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
            win_chip = win_chips, -- 保证客户端字段名一致,win_chip实际上是个数组
            all_win_chip = all_win_chip,
            free_spin = rep_free_spin
        }

        RankHelper:ChallengeDailyBiggestWin(player, GameType.AllTypes.LuxuryLife, rep_data)
        RankHelper:ChallengeWeeklyBiggestWin(player, GameType.AllTypes.LuxuryLife, rep_data)
        -- end
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
                [1] = GameType.AllTypes.LuxuryLife,
                [2] = "LuxuryLife",
                [3] = is_free_spin and 1 or 0,
                [4] = "ExpandingRespinFeature",
                [5] = number
            }
        )
    end

    local can_multiply = SlotsGameCal.Calculate.WinChipInMultiply(total_win_chip)
    if (can_multiply) then
        if ((total_win_chip / (amount * LineNum)) >= LuxuryLifePrizeConfig[2].min_multiple and not is_free_spin) then
            response.is_multiply = CommonCal.Calculate.IsMultiply(session, total_win_chip)
        end

        if ((total_win_chip / (amount * LineNum)) >= LuxuryLifePrizeConfig[1].min_multiple and not is_free_spin) then
            RobotAction.BigWinAction(session, task)
        end
    end

    -- response.item_list = item_list

    local contest_id, room_id, table_id = unpack(string.split(luxury_life.channel_id, "."))

    if (is_free_spin) then
        local his_bet_mount_array = json.decode(luxury_life.his_bet_mount)
        for k, v in ipairs(his_bet_mount_array) do
            Spark:SlotsAward(
                player,
                {
                    [1] = GameType.AllTypes.LuxuryLife,
                    [2] = "LuxuryLife",
                    [3] = table_id,
                    [4] = luxury_life.bouts_id,
                    [5] = v,
                    [6] = total_win_chip,
                    [7] = json.encode(origin_result),
                    [8] = json.encode(all_respin_items),
                    [9] = reel_file_name,
                    [10] = luxury_life.free_spin_bouts,
                    [11] = CommonCal.Calculate.GetFiveLineCount(all_prize_items) > 0 and 1 or 0,
                    [12] = player.record.total_spin,
                    [13] = amount * LineNum
                }
            )
        end
    else
        Spark:SlotsStart(
            player,
            {
                [1] = GameType.AllTypes.LuxuryLife,
                [2] = "LuxuryLife",
                [3] = table_id,
                [4] = luxury_life.bouts_id,
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

    if (luxury_life.free_spin_bouts == 0 and is_free_spin) then
        luxury_life.his_bet_mount = "[]"
    end

    CommonCal.Calculate.EndStart(
        session,
        task,
        player,
        request,
        response,
        luxury_life,
        LineNum,
        chip_cost,
        total_win_chip
    )

    -- gain exp
    if not is_free_spin then
        local exp = chip_cost
        local exp_request = {type = "SlotsLuxuryLife", ante_gold = amount * LineNum, gain_exp = exp}
        Player:GainExp(session, exp_request)
    end

    player_slots_info.content = json.encode(luxury_life)
    CommonCal.Calculate.UpdateSlotsToDbCache(task, player, player_slots_info)

    -- 锦标赛玩家得分更新
    CommonCal.Calculate.UpdateTournamentPlayerInfo(session, player.game_type, player, chip_cost, total_win_chip)

    response.player = {
        unlock_games = player.unlock_games,
        character = {
            chip = player.character.chip,
            experience = player.character.experience,
            level = player.character.level
        },
        luxury_life = {
            bet_amount = amount,
            free_spin_progress_str = luxury_life.free_spin_progress_str,
            special_item_str = luxury_life.special_item_str,
            free_spin_bouts = luxury_life.free_spin_bouts,
            free_total_win = luxury_life.free_total_win,
            is_slots = luxury_life.is_slots
        }
    }

    return response
end

-----------------------------------------------
-- 退出房间
------------------------------------------------
Exit = function(_M, session, request)
    local response = {header = {router = "Response"}}

    local filter_ret = RequestFilter.Filter("SlotsLuxuryLife", "Exit", session, request, true)
    if filter_ret then
        response.ret = filter_ret
        return response
    end

    local player = session.player
    local task = session.task

    local player_slots_info = CommonCal.Calculate.get_slots_info(session, task, player, GameType.AllTypes.LuxuryLife)
    local luxury_life = json.decode(player_slots_info.content)

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
            module_id = "SlotsLuxuryLifeContest",
            message_id = "SlotsLuxuryLifeContest_Exit_Request"
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
        BuyLoss:Trigger(session, task, GameType.AllTypes.LuxuryLife, player) ---当玩家钱减少到一定数量时，提示玩家充值
    if trigger_buyloss then
        luxury_life.total_loss = total_loss
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
    luxury_life.spined_times = 0
    response = {
        header = response.header,
        ret = Return.OK(),
        player = {character = {chip = player.character.chip}}
    }
    LOG(RUN, INFO).Format("[SlotsLuxuryLife][Exit] ok player %s, game type is: %s", player.id, player.game_type)

    player_slots_info.content = json.encode(luxury_life)
    CommonCal.Calculate.UpdateSlotsToDbCache(task, player, player_slots_info)

    return response
end
