require "Common/SlotsGameCal"
require "Common/DailyMissionsCal"
require "Common/RequestFilter"
require "Module/DailyTask"
require "Common/CommonCal"
require "Common/LineNum"
require "Common/RobotAction"
require "Module/SlotsAliceinWonderlandSpin"
require "Common/ClimbSlideCal"

module("SlotsOldGame", package.seeall)

local function InitPlayerGameInfo(session, task, player, game_type)
    local player_game_info = nil

    if (CommonCal.Calculate.is_old_game(game_type)) then
        local player_slots_info = CommonCal.Calculate.get_slots_info(session, task, player, game_type)
        player_game_info = json.decode(player_slots_info.content)
    else
        --这个有可能从缓存里面直接取，不经过json_str
        player_game_info = CommonCal.Calculate.get_game_info(session, task, player, game_type)
    end

    --只有不存在时才从json_str里面取
    if not player_game_info.save_data then
        player_game_info.save_data = json.decode(player_game_info.json_str or "") or {}
    end

    player_game_info.json_str = nil
    return player_game_info
end

-----------------------------------------------
-- 进入房间
------------------------------------------------
Enter = function(_M, session, request)
    local response = {header = {router = "Response"}}

    local filter_ret = RequestFilter.Filter("SlotsGame", "Enter", session, request, true)

    if filter_ret then
        response.ret = filter_ret
        return response
    end

    local game_type = request.game_type
    local task = session.task
    local player = session.player
    local is_fever_quest = request.is_fever_quest

    if is_fever_quest == 1 then
        session.player.is_fever_quest = 1
    else
        session.player.is_fever_quest = 0
    end

    LOG(RUN, INFO).Format("[SlotsGame][Enter] playerid %d, game_type %d", player.id, game_type)

    -- 根据游戏类型获取房间的配置
    local game_room_config = GameRoomConfig[game_type]

    local module_name = "Slots" .. game_room_config.game_name .. "Spin"
    LOG(RUN, INFO).Format(
        "[SlotsGame][Enter] playerid %d, game_type %d, module_name is:%s, require begin",
        player.id,
        game_type,
        module_name
    )
    if not _G[module_name] then
        require("Module/" .. module_name)
    end
    LOG(RUN, INFO).Format(
        "[SlotsGame][Enter] playerid %d, game_type %d, module_name is:%s, require end",
        player.id,
        game_type,
        module_name
    )

    local player_game_info = InitPlayerGameInfo(session, task, player, game_type)

    local isLock = CommonCal.Calculate.LevelReq(player, game_type)
    -- 房间未解锁
    if (isLock == 1) then
        response.ret = Return.LOCK_GAME()
        LOG(RUN, INFO).Format("[SlotsGame][Enter] end playerid %d, game_type %d lock game", player.id, game_type)
        return response
    end
    local save_data = player_game_info.save_data

    CommonCal.Calculate.MakeUpInRoom(session, task)

    player_game_info.channel_id = string.format("%s.%s.%s", game_room_config.game_name, 1, 1)

    Spark:EnterTable(
        player,
        {
            [1] = game_room_config.game_name
        }
    )

    LOG(RUN, INFO).Format("[SlotsGame][Enter] end playerid %d,  %d ", player.id, game_type)

    response.ret = Return.OK()
    response.player = {character = {chip = player.character.chip}}
    local bonus_info =
        _G["Slots" .. game_room_config.game_name .. "Spin"]["Enter"](
        task,
        player,
        game_room_config,
        player_game_info,
        session
    )
    response.bonus_info = json.encode(bonus_info)

    --处理lucky
    LuckyCal.OnEnterGame(session, player, save_data, game_type, player_game_info)

    local player_extern = CommonCal.Calculate.get_player_extern(session, task, player)
    local player_json_data = player_extern.save_data
    bonus_info.lucky_info = LuckyCal.GetLuckyJsonInfo(player, save_data, player_json_data)

    response.bonus_info = json.encode(bonus_info)

    player.game_type = game_type

    response.game_info = {
        bet_amount = SlotsGameCal.Calculate.GetBetAmount(player_game_info),
        --player_game_info.bet_amount,
        free_spin_bouts = player_game_info.free_spin_bouts,
        total_spin_bouts = player_game_info.total_spin_bouts,
        free_spin_num = player_game_info.free_spin_num,
        bouts_id = player_game_info.bouts_id,
        channel_id = player_game_info.channel_id,
        total_loss = player_game_info.total_loss,
        enter_chip = player_game_info.enter_chip,
        spined_times = player_game_info.spined_times,
        free_total_win = player_game_info.free_total_win,
        free_item_id = player_game_info.free_item_id,
        free_spined_count = player_game_info.free_spined_count
    }

    if (player_game_info.last_formation_list and string.len(player_game_info.last_formation_list) > 15) then
        response.last_formation_list = player_game_info.last_formation_list
    else
        response.last_formation_list = "[]"
    end

    if (CommonCal.Calculate.is_old_game(game_type)) then
        local player_slots_info = CommonCal.Calculate.get_slots_info(session, task, player, game_type)
        CommonCal.Calculate.UpdateSlotsToDbCache(task, player, player_slots_info, player_game_info)
    else
        CommonCal.Calculate.UpdateGameInfoToDbCache(task, player, player_game_info)
    end

    player_game_info.bouts_id = 0 -- 进场的时候把cd清空掉
    player_game_info.enter_chip = player.character.chip

    CommonCal.Calculate.update_bonus_info(session, task, player, json.encode(bonus_info))
    LOG(RUN, INFO).Format("[SlotsGame][Enter] successful playerid %d, game_type %d", player.id, game_type)
    return response
end

Bonus = function(_M, session, request)
    local response = {header = {router = "Response"}}
    local task = session.task
    local player = session.player

    local filter_ret = RequestFilter.Filter("SlotsGame", "Bonus", session, request, true)
    if filter_ret then
        response.ret = filter_ret
        return response
    end

    if GlobalState:IsSlotsMaintenance(session, task, player.id) == 1 then
        response.ret = Return.SERVER_NEAR_MAINENANCE()
        return response
    end

    local game_type = request.game_type
    local command_name = request.command_name

    local parameter = request.parameter

    local game_room_config = GameRoomConfig[game_type]

    if not game_room_config then
        return
    end

    local player_game_info = InitPlayerGameInfo(session, task, player, game_type)

    local old_chip = player.character.chip
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

    local lineNum = LineNum[game_type]()

    local spin_file_name = "Slots" .. game_room_config.game_name .. "Spin"

    LOG(RUN, INFO).Format(
        "[SlotsGame][Bonus] request is: %s, spin_file_name: %s, command_name:%s",
        Table2Str(request),
        spin_file_name,
        command_name
    )
    local content =
        _G[spin_file_name][command_name](
        task,
        player,
        game_room_config,
        parameter,
        player_game_info,
        game_type,
        session
    ) or {}

    if content.free_spin_bouts and content.free_spin_bouts > 0 then
        player_game_info.free_spin_bouts = player_game_info.free_spin_bouts + content.free_spin_bouts
        player_game_info.total_spin_bouts = player_game_info.total_spin_bouts + content.free_spin_bouts
    end

    if content.win_chip ~= nil then
        local win_chip = content.win_chip
        local reason =
            Reason[game_room_config.reason_name .. "_BET_CHIP_OBTAIN"]() or game_room_config.game_name .. " 投注道具获得"
        Player:Obtain(player, {"Chip", win_chip}, reason)

        local brif_player = {
            character = {
                chip = player.character.chip,
                level = player.character.level,
                experience = player.character.experience
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
                player = brif_player,
                collect_chip = player.character.chip - old_chip
            }
        )

        local player_extern = CommonCal.Calculate.get_player_extern(session, task, player)
        local player_json_data = player_extern.save_data

        local contest_id, room_id, table_id = unpack(string.split(player_game_info.channel_id, "."))
        local OperativeInfo = {
            [1] = game_type,
            [2] = game_room_config.game_name,
            [3] = table_id,
            [4] = player_game_info.bouts_id,
            [5] = player_game_info.bet_amount,
            [6] = win_chip
        }

        Spark:SlotsBonusAward(player, OperativeInfo)

        -- 更新锦标赛记录
        CommonCal.Calculate.UpdateTournamentPlayerInfo(session, game_type, player, 0, win_chip)

        ---处理lucky
        LuckyCal.OnOldGameBonusEnd(session, game_type, player_game_info, lineNum, win_chip, task, player_json_data)

        CommonCal.Calculate.update_player_extern(session, task, player)
    end

    if (CommonCal.Calculate.is_old_game(game_type)) then
        local player_slots_info = CommonCal.Calculate.get_slots_info(session, task, player, game_type)
        CommonCal.Calculate.UpdateSlotsToDbCache(task, player, player_slots_info, player_game_info)
    else
        CommonCal.Calculate.UpdateGameInfoToDbCache(task, player, player_game_info)
    end

    response.content = json.encode(content)
    response.ret = Return.OK()

    response.game_type = game_type
    response.command_name = command_name

    return response
end

-- 开始slots
Start = function(_M, session, request)
    local response = {header = {router = "Response"}}

    local filter_ret = RequestFilter.Filter("SlotsGame", "Start", session, request, true)
    if filter_ret then
        response.ret = filter_ret
        return response
    end

    local task = session.task
    local amount
    local player = session.player
    LOG(RUN, INFO).Format("[SlotsGame][Start] player %s request %s", player.id, Table2Str(request))

    CommonCal.Calculate.BeginStart(session, task, player)

    local game_type = player.game_type
    local game_room_config = GameRoomConfig[game_type]
    local lineNum = LineNum[game_type]()

    if GlobalState:IsSlotsMaintenance(session, task, player.id) == 1 then
        response.ret = Return.SERVER_NEAR_MAINENANCE()
        return response
    end

    if (player.game_type == 0) then
        response.ret = Return.HAVE_ALREADY_EXIT_GAME()
        return response
    end

    if (game_room_config == nil) then
        response.ret = Return.GAME_CONTEST_NULL_EXIT()
        return response
    end

    if (GameMapConfig[game_type] == nil) then
        response.ret = Return.GAME_CONTEST_NULL_EXIT()
        return response
    end

    local bet_amount_conf = nil

    local max_bet_amount_conf = nil

    local game_bet_amount_conf = _G[GameMapConfig[game_type].bet_amount_config]

    local amount = 0
    if (request.bet_amount_id ~= nil and request.bet_amount_id > 0) then
        LOG(RUN, INFO).Format("[SlotsGame][Start] player %s request.bet_amount_id %s", player.id, request.bet_amount_id)
        for k, v in ipairs(game_bet_amount_conf) do
            if k == request.bet_amount_id then
                bet_amount_conf = v
                amount = bet_amount_conf.single_amount
            end

            if (player.character.level >= v.required_level) then
                max_bet_amount_conf = v
            end
        end
        if (amount == 0) then
            amount = game_bet_amount_conf[#game_bet_amount_conf].single_amount
        end
    else
        amount = request.amount
        for k, v in ipairs(game_bet_amount_conf) do
            if v.single_amount == amount then
                bet_amount_conf = v
            end

            if (player.character.level >= v.required_level) then
                max_bet_amount_conf = v
            end
        end
    end

    local player_feature_condition = CommonCal.Calculate.get_feature_condition(session, task, player, player.game_type)

    local player_game_info = InitPlayerGameInfo(session, task, player, game_type)

    local player_extern = CommonCal.Calculate.get_player_extern(session, task, player)
    local player_json_data = player_extern.save_data

    player_game_info.game_type = game_type

    player_game_info.free_spin_num = 0

    player_game_info.save_data.map_config_info = nil

    local is_lock = CommonCal.Calculate.IsAppear(player)
    if (is_lock == 1) then
        response.ret = Return.LOCK_GAME()
        return response
    end

    local is_feature_free_spin = SlotsGameCal.Util.IsFeatureSpin(player_game_info)
    local is_feature_spin_in_free_spin = SlotsGameCal.Util.IsFeatureSpinInFreeSpin(player_game_info)
    local is_free_spin = not is_feature_free_spin and player_game_info.free_spin_bouts > 0

    local is_extral_spin = player_game_info.extral_spin_bouts and player_game_info.extral_spin_bouts > 0

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

    -- free spin不扣钱, free spin下amount不会改
    -- 这里只会处理消耗freespin，但是是否进入freespin 要在对应玩法逻辑中处理
    local chip_cost = 0

    local is_base_game = false
    if (is_extral_spin) then
        player_game_info.extral_spin_bouts = math.max(player_game_info.extral_spin_bouts - 1, 0)
        is_free_spin = false
        amount = SlotsGameCal.Calculate.GetBetAmount(player_game_info)
    elseif is_free_spin then
        player_feature_condition.free_spin_count = player_feature_condition.free_spin_count + 1
        player_game_info.free_spined_count = player_game_info.free_spined_count + 1
        amount = SlotsGameCal.Calculate.GetBetAmount(player_game_info)
        player_game_info.free_spin_bouts = math.max(player_game_info.free_spin_bouts - 1, 0)
    elseif is_feature_free_spin then -- 特性freespin独立计算
        amount = SlotsGameCal.Calculate.GetBetAmount(player_game_info)
    else
        SlotsGameCal.Calculate.ClearFreeSpinedCount(player_game_info)
        is_base_game = true
        chip_cost = amount * lineNum
        local reason = game_room_config.game_name .. " 投注道具消耗"

        if not Player:Consume(player, {"Chip", chip_cost}, reason) then
            response.ret = Return.GAME_PLAYER_CHIP_NOT_ENOUGH()
            return response
        end

        player_json_data.is_free_spin_add = 0
    end

    --处理lucky
    local spin_context = {}
    spin_context.lineNum = lineNum
    spin_context.amount = amount
    spin_context.game_type = game_type
    spin_context.player_game_info = player_game_info
    spin_context.chip_cost = chip_cost

    LuckyCal.OnSpinInit(session, spin_context)

    local extern_param = {}

    extern_param.session = session

    local temp_game_info = table.DeepCopy(player_game_info)

    local old_chip = player.character.chip
    local old_level = player.character.level
    local old_experience = player.character.experience

    -- 执行游戏逻辑
    local origin_result,
        win_chip,
        all_prize_items,
        free_spin_bouts,
        formation_list,
        reel_file_name,
        slots_win_chip,
        special_parameter =
        _G["Slots" .. game_room_config.game_name .. "Spin"].Spin(
        player,
        game_type,
        is_free_spin,
        game_room_config,
        amount,
        player_feature_condition,
        extern_param,
        temp_game_info
    )

    win_chip = math.floor(win_chip)
    slots_win_chip = math.floor(slots_win_chip)

    local need_deal_multiple = true
    if (player.character.lucky_type == LuckyType.ModeTypes.ForceWin) then
        need_deal_multiple = false
    end
    --先处理额外的次数
    if
        (special_parameter == nil or special_parameter.extral_spin_bouts == nil or
            special_parameter.extral_spin_bouts == 0)
     then
        -----如果玩家在free spin期间没有中奖，必中奖
        temp_game_info.free_total_win =
            temp_game_info.free_total_win +
            CommonCal.Calculate.GetFreeWin(is_free_spin, win_chip, is_feature_spin_in_free_spin)

        if (is_free_spin and temp_game_info.free_spin_bouts == 0) then
            local loop_times = 0

            while (temp_game_info.free_total_win <= 0) do
                if (loop_times >= 5) then
                    break
                end
                local temp_game_info = table.DeepCopy(player_game_info)

                loop_times = loop_times + 1

                player.character.level = old_level
                player.character.chip = old_chip
                player.character.experience = old_experience

                origin_result,
                    win_chip,
                    all_prize_items,
                    free_spin_bouts,
                    formation_list,
                    reel_file_name,
                    slots_win_chip =
                    _G["Slots" .. game_room_config.game_name .. "Spin"].Spin(
                    player,
                    game_type,
                    is_free_spin,
                    game_room_config,
                    amount,
                    player_feature_condition,
                    extern_param,
                    temp_game_info
                )

                win_chip = math.floor(win_chip)
                slots_win_chip = math.floor(slots_win_chip)

                temp_game_info.free_total_win =
                    temp_game_info.free_total_win + CommonCal.Calculate.GetFreeWin(is_free_spin, win_chip)
                need_deal_multiple = false
            end
        end
    else
        temp_game_info.extral_spin_bouts = temp_game_info.extral_spin_bouts + special_parameter.extral_spin_bouts
    end

    if (need_deal_multiple) then
        ----中奖倍数限制
        local cur_level = player.character.level
        local cur_total_bet_amount = amount * lineNum

        local WinningMultipleLimitConfig =
            CommonCal.Calculate.get_config(player, game_room_config.game_name .. "WinningMultipleLimitConfig")
        local sel_config_info = nil
        for k, v in ipairs(WinningMultipleLimitConfig) do
            if
                (v.level_min < cur_level and cur_level <= v.level_max) and
                    (v.bet_amount_min < cur_total_bet_amount and cur_total_bet_amount <= v.bet_amount_max)
             then
                sel_config_info = v
                break
            end
        end

        if sel_config_info ~= nil then
            local cur_winning_multiple = win_chip / cur_total_bet_amount
            local loop_times = 0

            while (cur_winning_multiple > sel_config_info.winning_multiple) do
                if (loop_times >= 3) then
                    break
                end
                LOG(RUN, INFO).Format("[SlotsGame][Start] player %s, begin deal normal control loop", player.id)
                local temp_game_info = table.DeepCopy(player_game_info)

                loop_times = loop_times + 1

                player.character.level = old_level
                player.character.chip = old_chip
                player.character.experience = old_experience

                origin_result,
                    win_chip,
                    all_prize_items,
                    free_spin_bouts,
                    formation_list,
                    reel_file_name,
                    slots_win_chip =
                    _G["Slots" .. game_room_config.game_name .. "Spin"].Spin(
                    player,
                    game_type,
                    is_free_spin,
                    game_room_config,
                    amount,
                    player_feature_condition,
                    extern_param,
                    temp_game_info
                )

                win_chip = math.floor(win_chip)
                slots_win_chip = math.floor(slots_win_chip)

                temp_game_info.free_total_win =
                    temp_game_info.free_total_win + CommonCal.Calculate.GetFreeWin(is_free_spin, win_chip)

                cur_winning_multiple = win_chip / cur_total_bet_amount
            end
        end
    end

    response.is_free_spin = (is_free_spin or is_feature_spin_in_free_spin) and 1 or 0
    CommonCal.Calculate.set_game_json_value(temp_game_info, "is_free_spin", response.is_free_spin)

    temp_game_info.last_formation_list = table.DeepCopy(formation_list)

    for k, v in pairs(temp_game_info.last_formation_list) do
        for sub_k, sub_v in pairs(v.slots_spin_list) do
            sub_v.prize_items = nil
        end
    end

    temp_game_info.last_formation_list = json.encode(temp_game_info.last_formation_list)

    if (CommonCal.Calculate.is_old_game(game_type)) then
        player_game_info = temp_game_info
    else
        session.game_info[game_type] = temp_game_info
        player_game_info = session.game_info[game_type]
    end

    if (old_experience ~= player.character.experience) then
        LOG(RUN, INFO).Format(
            "[SlotsGame][Start] error player id %s, game_type is: %s, old experience is: %s, current experience is:%s",
            player.id,
            game_type,
            old_experience,
            player.character.experience
        )
    end

    if (old_chip ~= player.character.chip) then
        LOG(RUN, INFO).Format(
            "[SlotsGame][Start] error player id %s, game_type is:%s, old chip is: %s, current chip is:%s",
            player.id,
            game_type,
            old_chip,
            player.character.chip
        )
    end

    -- freespin处理
    if (free_spin_bouts > 0) then
        player_game_info.free_spin_bouts = player_game_info.free_spin_bouts + free_spin_bouts
        local tmp_total_spin_bouts = (player_game_info.total_spin_bouts or 0) + free_spin_bouts
        player_game_info.total_spin_bouts = tmp_total_spin_bouts
    end

    if (not is_free_spin and player_game_info.free_spin_bouts <= 0) then
        -- 当不处于free状态并且没有free item时告诉客户端free_item_id为0
        free_item_id = 0
    end

    player_game_info.free_item_id = free_item_id

    if (game_type ~= GameType.AllTypes.RapidHit) then
        if (is_free_spin) then
            -----记录free spin中总赢取
            player.record.free_spin = player.record.free_spin + 1
        else
            if not is_feature_spin_in_free_spin then
                player_game_info.free_total_win = 0
            end
        end
    else
        if (is_free_spin) then
            -----记录free spin中总赢取
            player.record.free_spin = player.record.free_spin + 1
        end

        if (chip_cost > 0) then
            player_game_info.free_total_win = 0
        end
    end

    if (not is_free_spin) then
        -- 记录record
        player.record.total_spin = player.record.total_spin + 1
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

    if (not is_free_spin and free_spin_bouts > 0) then
        player_game_info.bouts_id = os.time()
    end

    local parameters = {
        {
            session = session,
            task = task,
            player = player,
            save_data = player_game_info.save_data,
            player_json_data = player_json_data,
            chip_cost = chip_cost,
            win_chip = win_chip,
            last_normal_credit_name = "last_normal_credit1",
            normal_credit_change_name = "normal_credit_change1",
            normal_spin_count_name = "normal_spin_count1",
            config_name = "NomalSpinLuckyChange1",
            game_type = game_type
        },
        {
            session = session,
            task = task,
            player = player,
            save_data = player_game_info.save_data,
            player_json_data = player_json_data,
            chip_cost = chip_cost,
            win_chip = win_chip,
            last_normal_credit_name = "last_normal_credit2",
            normal_credit_change_name = "normal_credit_change2",
            normal_spin_count_name = "normal_spin_count2",
            config_name = "NomalSpinLuckyChange2",
            game_type = game_type
        }
    }
    for k, v in ipairs(parameters) do
        LuckyCal.RunNormalControl(v)
    end

    -- gain exp
    if not is_free_spin and not is_feature_free_spin then
        local exp = chip_cost
        local exp_request = {
            type = "Slots" .. game_room_config.game_name,
            ante_gold = amount * lineNum,
            gain_exp = exp
        }
        Player:GainExp(session, exp_request)
    end

    if (LuckyCal.IsLuckyOn(player, game_type) == 1) then
        --增加UnLucky
        LuckyCal.AddUnlucky(session, task, player, chip_cost, player_game_info.save_data, game_type)
    end

    local free_win_amount = 0

    if (is_free_spin) then
        free_win_amount = win_chip
    end

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

    local prize_config = _G[GameMapConfig[game_type].prize_config]

    --计算大奖倍增
    local win_chip_cal_multiple = win_chip --用于计算大奖倍增的赢钱值
    if special_parameter and special_parameter.win_chip_cal_multiple then
        win_chip_cal_multiple = special_parameter.win_chip_cal_multiple
    end
    local multiply_value = (win_chip_cal_multiple / (amount * lineNum))
    if (multiply_value >= prize_config[3].min_multiple) then
        player.statistics.epicwin_num = player.statistics.epicwin_num + 1
    elseif (multiply_value >= prize_config[2].min_multiple) then
        player.statistics.megawin_num = player.statistics.megawin_num + 1
    elseif (multiply_value >= prize_config[1].min_multiple) then
        player.statistics.bigwin_num = player.statistics.bigwin_num + 1
    end
    response.multiply_value = multiply_value * 1000

    local is_bonus_game = false

    if _G["Slots" .. game_room_config.game_name .. "Spin"].IsBonusGame then
        is_bonus_game =
            _G["Slots" .. game_room_config.game_name .. "Spin"].IsBonusGame(game_room_config, player, player_game_info)
    end

    if is_bonus_game then
        player.statistics.bonus_game_num = player.statistics.bonus_game_num + 1
    end

    Player:BroadCastChip(session, task, amount * lineNum, win_chip)

    local can_multiply = SlotsGameCal.Calculate.WinChipInMultiply(win_chip)
    if (can_multiply and multiply_value >= prize_config[1].min_multiple and not is_free_spin) then
        response.is_multiply = CommonCal.Calculate.IsMultiply(session, win_chip)
    end

    if (can_multiply and multiply_value >= prize_config[1].min_multiple and not is_free_spin) then
        RobotAction.BigWinAction(session, task)
    end

    ----首付促销
    local feature_num_info = json.decode(CommonCal.Calculate.get_extern_info(session, task, player, "feature_num_info"))

    if (feature_num_info["feature_num"] == nil) then
        feature_num_info["feature_num"] = 0
    end
    if (feature_num_info["feature_num"] < 3 and player.character.vip == 0) then
        if (multiply_value >= prize_config[2].min_multiple and not is_free_spin) then
            feature_num_info["feature_num"] = feature_num_info["feature_num"] + 1
            CommonCal.Calculate.update_feature_mega(session, task, player, json.encode(feature_num_info))
            response.is_multiply = -1
        end
    end

    -- 广播
    local win_info = {bet_amount = amount, total_bet = amount * lineNum, win_chip = win_chip}
    Communication:OnBcEvent(session, game_room_config.broadcast_type, win_info, 15)

    -- buyloss的局数+1
    player_game_info.spined_times = player_game_info.spined_times + 1

    if (is_base_game) then
        player_game_info.bet_amount = amount
    end
    response.formation_list = formation_list

    local contest_id, room_id, table_id = unpack(string.split(player_game_info.channel_id, "."))

    if (is_free_spin) then
        Spark:SlotsAward(
            player,
            {
                [1] = game_type,
                [2] = game_room_config.game_name,
                [3] = table_id,
                [4] = player_game_info.bouts_id,
                [5] = amount,
                [6] = win_chip,
                [7] = json.encode(origin_result),
                [8] = "[]",
                [9] = reel_file_name and reel_file_name or "",
                [10] = player_game_info.free_spin_bouts,
                [11] = CommonCal.Calculate.GetFiveLineCount(all_prize_items) > 0 and 1 or 0,
                [12] = player.record.total_spin,
                [13] = amount * lineNum
            }
        )
    else
        Spark:SlotsStart(
            player,
            {
                [1] = game_type,
                [2] = game_room_config.game_name,
                [3] = table_id,
                [4] = player_game_info.bouts_id,
                [5] = amount,
                [6] = amount * lineNum,
                [7] = win_chip,
                [8] = json.encode(origin_result),
                [9] = "[]",
                [10] = is_free_spin,
                [11] = reel_file_name and reel_file_name or "",
                [12] = CommonCal.Calculate.GetFiveLineCount(all_prize_items) > 0 and 1 or 0,
                [13] = player.record.total_spin
            }
        )
    end

    response.game_info = {
        bet_amount = amount,
        free_spin_bouts = player_game_info.free_spin_bouts,
        total_spin_bouts = player_game_info.total_spin_bouts,
        free_spin_num = player_game_info.free_spin_num,
        bouts_id = player_game_info.bouts_id,
        channel_id = player_game_info.channel_id,
        total_loss = player_game_info.total_loss,
        enter_chip = player_game_info.enter_chip,
        spined_times = player_game_info.spined_times,
        free_total_win = player_game_info.free_total_win,
        free_item_id = player_game_info.free_item_id,
        free_spined_count = player_game_info.free_spined_count
    }

    if is_free_spin and player_game_info.free_spin_bouts <= 0 then
        LOG(RUN, INFO).Format("[SlotsOldGame]player id %s clean total free spin", player.id)
        SlotsGameCal.Calculate.ClearTotalFreeSpinCount(player_game_info)
    end

    ---处理lucky
    if (LuckyCal.IsLuckyOn(player, game_type) == 1) then
        LuckyCal.AddModeValue(player, game_type, chip_cost, win_chip)
        LuckyCal.FirAddLucky(session, task, player, win_chip)
    end

    if win_chip > 0 then
        local reason =
            Reason[game_room_config.reason_name .. "_BET_CHIP_OBTAIN"]() or game_room_config.game_name .. " 投注道具获得"
        Player:Obtain(player, {"Chip", win_chip}, reason)
        -- 记录每日、每周赢钱,进排行榜
        RankHelper:ChallengeDailyWin(player)
        RankHelper:ChallengeWeeklyWin(player)
        -- free spin不计入biggest win的统计
        if slots_win_chip > 0 then
            local rep_free_spin = 0
            if (is_free_spin) then
                rep_free_spin = 1
            end

            local rep_data = {
                bonus_info = CommonCal.Calculate.get_extern_info(session, task, player, "bonus_info"),
                formation_list = response.formation_list,
                game_info = response.game_info,
                win_chip = slots_win_chip, -- win_chip,
                bet_amount = amount,
                free_spin = rep_free_spin,
                multiply_value = multiply_value
            }

            RankHelper:ChallengeDailyBiggestWin(player, game_type, rep_data)
            RankHelper:ChallengeWeeklyBiggestWin(player, game_type, rep_data)
        end
        ----记录record
        player.record.spin_won = player.record.spin_won + 1
        player.record.total_win = player.record.total_win + win_chip
        if win_chip > player.record.biggest_win then
            player.record.biggest_win = win_chip
        end
    end

    response.lucky_info = LuckyCal.GetLuckyJsonInfo(player, player_game_info.save_data, player_json_data)

    CommonCal.Calculate.EndStart(
        session,
        task,
        player,
        request,
        response,
        player_game_info,
        lineNum,
        chip_cost,
        win_chip
    )

    if (CommonCal.Calculate.is_old_game(game_type)) then
        local player_slots_info = CommonCal.Calculate.get_slots_info(session, task, player, game_type)
        CommonCal.Calculate.UpdateSlotsToDbCache(task, player, player_slots_info, player_game_info)
    else
        CommonCal.Calculate.UpdateGameInfoToDbCache(task, player, player_game_info)
    end
    -- 新加游戏锦标赛的功能
    CommonCal.Calculate.UpdateTournamentPlayerInfo(session, game_type, player, chip_cost, win_chip)
    CommonCal.Calculate.UpdateToDbCache(task, player, "feature_condition", player_feature_condition)
    CommonCal.Calculate.update_player_extern(session, task, player)

    response.ret = Return.OK()

    response.player = {
        unlock_games = player.unlock_games,
        character = {
            chip = player.character.chip,
            experience = player.character.experience,
            level = player.character.level,
            piggy_bank_chip = player.character.piggy_bank_chip,
            piggy_bank_pay_count = player.character.piggy_bank_pay_count
        }
    }

    return response
end

-----------------------------------------------
-- 退出房间
------------------------------------------------
Exit = function(_M, session, request)
    local response = {header = {router = "Response"}}
    local filter_ret = RequestFilter.Filter("SlotsGame", "Exit", session, request, true)

    if filter_ret then
        response.ret = filter_ret
        return response
    end

    local player = session.player
    local task = session.task
    local game_type = player.game_type
    local game_room_config = GameRoomConfig[game_type]

    if (game_room_config == nil) then
        response.ret = Return.HAVE_ALREADY_EXIT_GAME()
        return response
    end

    Spark:LeaveTable(
        player,
        {
            [1] = game_room_config.game_name
        }
    )

    local player_game_info = InitPlayerGameInfo(session, task, player, game_type)

    local trigger_buyloss, total_loss, diamond, goods_id = BuyLoss:Trigger(session, task, game_type, player) ---当玩家钱减少到一定数量时，提示玩家充值

    if trigger_buyloss then
        player_game_info.total_loss = total_loss
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

    response = {
        header = response.header,
        ret = Return.OK(),
        player = {character = {chip = player.character.chip}}
    }

    LOG(RUN, INFO).Format("[SlotsGame][Exit] ok player %s, game type is: %s", player.id, player.game_type)

    local table_define = TableDefine["game_info"]

    if (CommonCal.Calculate.is_old_game(game_type)) then
        local player_slots_info = CommonCal.Calculate.get_slots_info(session, task, player, game_type)
        --防止保存save_data
        CommonCal.Calculate.UpdateSlotsToDbCache(task, player, player_slots_info, player_game_info)
    else
        CommonCal.Calculate.UpdateGameInfoToDbCache(task, player, player_game_info)
    end

    return response
end
