require "Common/SlotsPurrfectPetsCal"
require "Common/RequestFilter"
require "Module/DailyTask"
require "Common/CommonCal"
require "Common/LineNum"
require "Common/RobotAction"
module("SlotsPurrfectPets", package.seeall)

-----------------------------------------------
-- 进入房间
------------------------------------------------
Enter = function(_M, session, request)
    local response = {header = {router = "Response"}}
    local filter_ret = RequestFilter.Filter("SlotsPurrfectPets", "Enter", session, request, true)
    if filter_ret then
        response.ret = filter_ret
        return response
    end
    local task = session.task
    local player = session.player

    local player_slots_info = CommonCal.Calculate.get_slots_info(session, task, player, GameType.AllTypes.PurrfectPets)
    local purrfect_pets = json.decode(player_slots_info.content)

    LOG(RUN, INFO).Format("[SlotsPurrfectPetsContest][Enter]player %s", player.id)
    CommonCal.Calculate.MakeUpInRoom(session, task)
    local isLock = CommonCal.Calculate.LevelReq(player, GameType.AllTypes.PurrfectPets)
    if (isLock == 1) then
        response.ret = Return.LOCK_GAME()
        return response
    end

    local table_id = request.table_id
    local async_request = nil
    local game_room_config = GameRoomConfig[GameType.AllTypes.PurrfectPets]

    if (table_id and table_id > 0) then
        local channel_id = string.format("%s.%s.%s", "SlotsPurrfectPetsContest", game_room_config.room_name, table_id)
        purrfect_pets.channel_id = channel_id
        async_request = {
            header = {
                router = "AsyncRequest",
                service_name = game_room_config.contest_client_name,
                task_id = task.id,
                module_id = "SlotsPurrfectPetsContest",
                message_id = "SlotsPurrfectPetsContest_Enter_Request"
            },
            player = {
                id = player.id,
                user = player.user,
                account = player.account,
                game_type = GameType.AllTypes.PurrfectPets,
                character = {
                    chip = player.character.chip,
                    vip = player.character.vip,
                    level = player.character.level,
                    experience = player.character.experience,
                    player_type = player.character.player_type
                },
                record = player.record,
                purrfect_pets = purrfect_pets
            }
        }
    else
        async_request = {
            header = {
                router = "AsyncRequest",
                service_name = game_room_config.contest_client_name,
                task_id = task.id,
                module_id = "SlotsPurrfectPetsContest",
                message_id = "SlotsPurrfectPetsContest_Enter_Request"
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
                purrfect_pets = purrfect_pets
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

    purrfect_pets.channel_id = async_response.channel_id

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

    purrfect_pets.bouts_id = 0
     --进场的时候把cd清空掉
    purrfect_pets.enter_chip = player.character.chip
    purrfect_pets.spined_times = 0

    -- response.item_ids = SlotsOpenSesameCal.Calculate.GenInitItem()
    response.ret = Return.OK()
    response.player = {
        purrfect_pets = purrfect_pets,
        character = {
            chip = player.character.chip
        }
    }

    player.game_type = GameType.AllTypes.PurrfectPets

    player_slots_info.content = json.encode(purrfect_pets)
    CommonCal.Calculate.UpdateSlotsToDbCache(task, player, player_slots_info)

    return response, table_sync_notice
end

--开始slots
Start = function(_M, session, request)
    local response = {header = {router = "Response"}}

    local filter_ret = RequestFilter.Filter("SlotsPurrfectPets", "Start", session, request, true)
    if filter_ret then
        response.ret = filter_ret
        return response
    end

    local LineNum = #SlotsPurrfectPetsCal.Const.Lines
     --LineNum[GameType.AllTypes.PurrfectPets]()

    local task = session.task
    local amount
    local player = session.player

    local player_slots_info = CommonCal.Calculate.get_slots_info(session, task, player, GameType.AllTypes.PurrfectPets)
    local purrfect_pets = json.decode(player_slots_info.content)

    local chip_cost = 0
    CommonCal.Calculate.BeginStart(session, task, player)

    if GlobalState:IsSlotsMaintenance(session, task, player.id) == 1 then
        response.ret = Return.SERVER_NEAR_MAINENANCE()
        return response
    end

    if (player.game_type ~= GameType.AllTypes.PurrfectPets) then
        response.ret = Return.HAVE_ALREADY_EXIT_GAME()
        return response
    end
    local is_lock = CommonCal.Calculate.IsAppear(player)
    if (is_lock == 1) then
        response.ret = Return.LOCK_GAME()
        return response
    end
    local is_free_spin = purrfect_pets.free_spin_bouts > 0

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

    --free spin不扣钱, free spin下amount不会改
    if is_free_spin then
        amount = purrfect_pets.bet_amount
        purrfect_pets.free_spin_bouts = math.max(purrfect_pets.free_spin_bouts - 1, 0)
    else
        amount = request.amount
        chip_cost = amount * LineNum

        if not Player:Consume(player, {"Chip", chip_cost}, Reason.PURRFECT_PETS_BET_CHIP_CONSUME()) then
            response.ret = Return.GAME_PLAYER_CHIP_NOT_ENOUGH()
            return response
        end
        purrfect_pets.bet_amount = amount
    end

    response.is_free_spin = is_free_spin and 1 or 0
    local flag = 0

    if (GlobalSlotsTest[player.id] ~= nil) then
        if (GlobalSlotsTest[player.id].flag == 1) then
            flag = 1
        end
    end

    local PurrfectPetsBetAmountConfig = CommonCal.Calculate.get_config(player, "PurrfectPetsBetAmountConfig")
    local bet_amount_conf
    for k, v in ipairs(PurrfectPetsBetAmountConfig) do
        if v.single_amount == amount then
            bet_amount_conf = v
            break
        end
    end
    response.ret = Return.OK()

    local is_get_free_spin = false
    local origin_result, reel_file_name
    local all_freeze_list = {}
    local result = {{}, {}, {}, {}, {}}
    local item_list = {}
    local all_prize_items = {}
    local loop_num = 0
    local total_win_chip = 0
    while hasWild == 1 do
        CommonCal.Calculate.SetLoopNum(player.id, loop_num)
        local freeze_list = nil
        if is_free_spin then
            origin_result, freeze_list, reel_file_name =
                SlotsPurrfectPetsCal.Calculate.GenItemResult(player, result, all_freeze_list, true)
        else
            origin_result, freeze_list, reel_file_name =
                SlotsPurrfectPetsCal.Calculate.GenItemResult(player, result, all_freeze_list, false)
        end

        local result_with_wild = table.DeepCopy(origin_result)

        SlotsPurrfectPetsCal.Calculate.GenWildResult(result_with_wild, all_freeze_list)

        if (#freeze_list > 0) then
            hasWild = 1
            table.insert(all_freeze_list, freeze_list)
        else
            hasWild = 0
        end

        local prize_items, total_payrate = SlotsPurrfectPetsCal.Calculate.GenPrizeInfo(player, result_with_wild)
        table.insert(all_prize_items, prize_items)
        local item_ids = SlotsPurrfectPetsCal.Calculate.TransResultToList(origin_result)
        local prize_items = prize_items

        local win_chip = total_payrate * amount

        total_win_chip = total_win_chip + win_chip

        local free_spin_bouts, free_item_id = SlotsPurrfectPetsCal.Calculate.GenFreeSpinCount(origin_result)
        if (free_spin_bouts > 0) then
            is_get_free_spin = true
        end
        -- if (not is_free_spin)
        --then
        purrfect_pets.free_spin_bouts = purrfect_pets.free_spin_bouts + free_spin_bouts
        --end

        ----记录record
        player.record.total_spin = player.record.total_spin + 1
        if is_free_spin then
            player.record.free_spin = player.record.free_spin + 1
        end

        -----记录free spin中总赢取
        if is_free_spin then
            purrfect_pets.free_total_win = purrfect_pets.free_total_win + win_chip
        else
            purrfect_pets.free_total_win = 0
        end

        --response.win_chip = win_chip
        if (loop_num > 0) then
            local SlotsPurrfectPets_Item = {}
            SlotsPurrfectPets_Item.item_ids = item_ids
            SlotsPurrfectPets_Item.prize_items = prize_items
            SlotsPurrfectPets_Item.win_chip = win_chip
            table.insert(item_list, SlotsPurrfectPets_Item)
        else
            response.item_ids = item_ids
            response.prize_items = prize_items
            response.win_chip = win_chip
        end
        loop_num = loop_num + 1
    end
    response.item_list = item_list

    response.all_freeze_list = json.encode(all_freeze_list)

    --buyloss的局数+1
    purrfect_pets.spined_times = purrfect_pets.spined_times + 1

    local free_win_amount = 0
    if (is_free_spin) then
        free_win_amount = total_win_chip
    end

    if (not is_free_spin and is_get_free_spin) then
        purrfect_pets.bouts_id = os.time()
    end

    local PurrfectPetsPrizeConfig = CommonCal.Calculate.get_config(player, "PurrfectPetsPrizeConfig")
    --accomplish tasks
    local task_req_data = {
        five_line = CommonCal.Calculate.GetFiveLineCount(all_prize_items),
        base_spin = not is_free_spin,
        free_spin = is_get_free_spin,
         --本次下注是否属于freespin
        win_amount = total_win_chip,
        bet_amount = amount * LineNum,
        max_bet = amount >= SlotsPurrfectPetsCal.Calculate.GetMaxBetAmount(player),
        free_win_amount = free_win_amount,
        epic_win = (total_win_chip / (amount * LineNum)) >= PurrfectPetsPrizeConfig[3].min_multiple
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
    if ((total_win_chip / (amount * LineNum)) >= PurrfectPetsPrizeConfig[3].min_multiple) then
        player.statistics.epicwin_num = player.statistics.epicwin_num + 1
    elseif ((total_win_chip / (amount * LineNum)) >= PurrfectPetsPrizeConfig[2].min_multiple) then
        player.statistics.megawin_num = player.statistics.megawin_num + 1
    elseif ((total_win_chip / (amount * LineNum)) >= PurrfectPetsPrizeConfig[1].min_multiple) then
        player.statistics.bigwin_num = player.statistics.bigwin_num + 1
    end

    --广播
    local win_info = {
        bet_amount = amount,
        total_bet = amount * LineNum,
        win_chip = total_win_chip
    }
    Communication:OnBcEvent(session, BroadcastType.AllTypes.PurrfectPets, win_info, 15)

    local can_multiply = SlotsGameCal.Calculate.WinChipInMultiply(total_win_chip)
    if (can_multiply) then
        if ((total_win_chip / (amount * LineNum)) >= PurrfectPetsPrizeConfig[2].min_multiple and not is_free_spin) then
            response.is_multiply = CommonCal.Calculate.IsMultiply(session, total_win_chip)
        end

        if ((total_win_chip / (amount * LineNum)) >= PurrfectPetsPrizeConfig[1].min_multiple and not is_free_spin) then
            RobotAction.BigWinAction(session, task)
        end
    end

    if total_win_chip > 0 then
        Player:Obtain(player, {"Chip", total_win_chip}, Reason.PURRFECT_PETS_BET_CHIP_OBTAIN())

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
            item_list = response.item_list,
            item_ids = response.item_ids,
            prize_items = response.prize_items,
            win_chip = response.win_chip,
            all_win_chip = total_win_chip,
            bet_amount = amount,
            free_spin = rep_free_spin,
            all_freeze_list = json.encode(all_freeze_list)
        }
        RankHelper:ChallengeDailyBiggestWin(player, GameType.AllTypes.PurrfectPets, rep_data)
        RankHelper:ChallengeWeeklyBiggestWin(player, GameType.AllTypes.PurrfectPets, rep_data)
        --end
        ----记录record
        player.record.spin_won = player.record.spin_won + 1
        player.record.total_win = player.record.total_win + total_win_chip
        if total_win_chip > player.record.biggest_win then
            player.record.biggest_win = total_win_chip
        end
    end

    Player:BroadCastChip(session, task, amount * LineNum, total_win_chip)

    local contest_id, room_id, table_id = unpack(string.split(purrfect_pets.channel_id, "."))
    local feature_items = {}
    for k, v in ipairs(item_list) do
        table.insert(feature_items, v.item_ids)
    end

    if (is_free_spin) then
        Spark:SlotsAward(
            player,
            {
                [1] = GameType.AllTypes.PurrfectPets,
                [2] = "PurrfectPets",
                [3] = table_id,
                [4] = purrfect_pets.bouts_id,
                [5] = purrfect_pets.bet_amount,
                [6] = total_win_chip,
                [7] = json.encode(origin_result),
                [8] = json.encode(feature_items),
                [9] = reel_file_name,
                [10] = purrfect_pets.free_spin_bouts,
                [11] = CommonCal.Calculate.GetFiveLineCount(all_prize_items) > 0 and 1 or 0,
                [12] = player.record.total_spin,
                [13] = amount * LineNum
            }
        )
    else
        Spark:SlotsStart(
            player,
            {
                [1] = GameType.AllTypes.PurrfectPets,
                [2] = "PurrfectPets",
                [3] = table_id,
                [4] = purrfect_pets.bouts_id,
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

    CommonCal.Calculate.EndStart(
        session,
        task,
        player,
        request,
        response,
        purrfect_pets,
        LineNum,
        chip_cost,
        total_win_chip
    )

    --gain exp
    if not is_free_spin then
        local exp = chip_cost
        local exp_request = {
            type = "SlotsPurrfectPets",
            ante_gold = amount * LineNum,
            gain_exp = exp
        }
        Player:GainExp(session, exp_request)
    end

    player_slots_info.content = json.encode(purrfect_pets)
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
        purrfect_pets = {
            bet_amount = amount,
            bonus_progress = purrfect_pets.bonus_progress,
            free_spin_bouts = purrfect_pets.free_spin_bouts,
            free_total_win = purrfect_pets.free_total_win
        }
    }
    return response
end

-----------------------------------------------
-- 退出房间
------------------------------------------------
Exit = function(_M, session, request)
    local response = {header = {router = "Response"}}
    local filter_ret = RequestFilter.Filter("SlotsPurrfectPets", "Exit", session, request, true)
    if filter_ret then
        response.ret = filter_ret
        return response
    end

    local player = session.player
    local task = session.task

    local player_slots_info = CommonCal.Calculate.get_slots_info(session, task, player, GameType.AllTypes.PurrfectPets)
    local purrfect_pets = json.decode(player_slots_info.content)

    local game_room_config = GameRoomConfig[player.game_type]
    if (game_room_config == nil) then
        response.ret = Return.HAVE_ALREADY_EXIT_GAME()
        return response
    end
    LOG(RUN, INFO).Format("[SlotsPurrfectPets][Exit] player %s", player.id)
    local async_request = {
        header = {
            router = "AsyncRequest",
            service_name = game_room_config.contest_client_name,
            task_id = task.id,
            module_id = "SlotsPurrfectPetsContest",
            message_id = "SlotsPurrfectPetsContest_Exit_Request"
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
        BuyLoss:Trigger(session, task, GameType.AllTypes.PurrfectPets, player) ---当玩家钱减少到一定数量时，提示玩家充值
    if trigger_buyloss then
        purrfect_pets.total_loss = total_loss
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
    purrfect_pets.spined_times = 0

    response = {
        header = response.header,
        ret = Return.OK(),
        player = {
            character = {
                chip = player.character.chip
            }
        }
    }
    LOG(RUN, INFO).Format("[SlotsPurrfectPets][Exit] ok player %s, game type is: %s", player.id, player.game_type)

    player_slots_info.content = json.encode(purrfect_pets)
    CommonCal.Calculate.UpdateSlotsToDbCache(task, player, player_slots_info)

    return response
end
