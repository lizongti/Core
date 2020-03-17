require "Common/SlotsGameCal"
require "Common/DailyMissionsCal"
require "Common/RequestFilter"
require "Module/DailyTask"
require "Common/CommonCal"
require "Common/LineNum"
require "Common/RobotAction"
require "Module/SlotsAliceinWonderlandSpin"
require "Common/GameStatusCal"
require "Common/LuckyCal"
require "Common/ClimbSlideCal"

module("SlotsNewGame", package.seeall)

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
    local is_fever_quest = request.is_fever_quest
    local task = session.task
    local player = session.player

    if is_fever_quest == 1 then
        session.player.is_fever_quest = 1
    else
        session.player.is_fever_quest = 0
    end

    LOG(RUN, INFO).Format("[SlotsGame][Enter] playerid %d, game_type %d", player.id, game_type)

    -- 根据游戏类型获取房间的配置
    local game_room_config = GameRoomConfig[game_type]
    if not game_room_config then
        LOG(RUN, INFO).Format(
            "[SlotsGame][Enter] game config not found, player_id %d, game_type %d",
            player.id,
            game_type
        )
    end

    local module_name = "Slots" .. game_room_config.game_name
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

    local game_object = _G["Slots" .. game_room_config.game_name]

    local player_game_info = SlotsGameCal.Calculate.InitPlayerGameInfo(session, task, player, game_type)

    if game_object["CheckNeedClearGameInfo"] and game_object["CheckNeedClearGameInfo"](player_game_info) then
        session.game_info = {}
        session.game_info[game_type] = CommonCal.Calculate.get_init_game_info(player, game_type)

        player_game_info = SlotsGameCal.Calculate.InitPlayerGameInfo(session, task, player, game_type)
    end
    local save_data = player_game_info.save_data

    local isLock = CommonCal.Calculate.LevelReq(player, game_type)
    -- 房间未解锁
    if (isLock == 1) then
        response.ret = Return.LOCK_GAME()
        LOG(RUN, INFO).Format("[SlotsGame][Enter] end playerid %d, game_type %d lock game", player.id, game_type)
        return response
    end

    CommonCal.Calculate.MakeUpInRoom(session, task)

    player_game_info.channel_id = string.format("%s.%s.%s", game_room_config.game_name, 1, 1)

    Spark:EnterTable(
        player,
        {
            [1] = game_room_config.game_name
        }
    )
    LOG(RUN, INFO).Format("[SlotsGame][Enter] end playerid %d,  %d", player.id, game_type)

    local player_game_status = CommonCal.Calculate.GetPlayerGameStatus(session, task, player, game_type)
    GameStatusCal.Calculate.InitGamStatus(player_game_status)

    if (GameStatusCal.Calculate.FinishedInfo(player_game_status, GameStatusDefine.AllTypes.BaseSpinGame) ~= nil) then
        GameStatusCal.Calculate.ClearGameStatus(player_game_status)
    end

    response.ret = Return.OK()
    response.player = {character = {chip = player.character.chip}}

    local game_parameters = {
        task = task,
        player = player,
        game_room_config = game_room_config,
        player_game_info = player_game_info,
        session = session,
        player_game_status = player_game_status
    }

    local bonus_info = game_object["Enter"](game_parameters)

    --处理lucky
    LuckyCal.OnEnterGame(session, player, save_data, game_type, player_game_info)

    local player_extern = CommonCal.Calculate.get_player_extern(session, task, player)
    local player_json_data = player_extern.save_data
    bonus_info.lucky_info = LuckyCal.GetLuckyJsonInfo(player, save_data, player_json_data)

    response.bonus_info = json.encode(bonus_info)

    --response.game_info = player_game_info
    local free_spin_bouts = GameStatusCal.Calculate.GetFreeSpinBouts(player_game_status)
    local total_free_spin_num = GameStatusCal.Calculate.GetTotalFreeSpinNum(player_game_status)
    response.game_info = {
        bet_amount = SlotsGameCal.Calculate.GetBetAmount(player_game_info),
        free_spin_bouts = free_spin_bouts,
        total_spin_bouts = total_free_spin_num,
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

    player.game_type = game_type

    response.game_status_list = json.encode(GameStatusCal.Calculate.GetAllGameStatus(player_game_status))
    CommonCal.Calculate.update_bonus_info(session, task, player, json.encode(bonus_info))

    CommonCal.Calculate.UpdatePlayerGameStatus(session, task, player, game_type, player_game_status)

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

    local old_chip = player.character.chip

    local game_type = request.game_type
    local command_name = request.command_name

    local parameter = request.parameter

    local game_room_config = GameRoomConfig[game_type]

    if not game_room_config then
        return
    end

    local player_game_info = SlotsGameCal.Calculate.InitPlayerGameInfo(session, task, player, game_type)

    if
        ((Base.Enviroment.pro_spec_t == "local" or Base.Enviroment.pro_spec_t == "docker-local" or
            Base.Enviroment.pro_spec_t == "dev" or
            Base.Enviroment.pro_spec_t == "docker-dev") and
            player.character.player_type ~= tonumber(ConstValue[5].value))
     then
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

        session:ContactPacket(task, async_request)
    end

    --调用具体游戏的Bonus函数
    local spin_file_name = "Slots" .. game_room_config.game_name
    local player_game_status = CommonCal.Calculate.GetPlayerGameStatus(session, task, player, game_type)
    local content =
        _G[spin_file_name][command_name](
        {
            task = task,
            player = player,
            game_room_config = game_room_config,
            parameter = parameter,
            player_game_info = player_game_info,
            game_type = game_type,
            session = session,
            player_game_status = player_game_status
        }
    ) or {}

    --Finish时，Bonus的StatusInfo的流程+1
    local bonus_win_chip = content.win_chip or 0
    if (string.find(command_name, "Finish") ~= nil) or content.is_finished then
        GameStatusCal.Calculate.UpdateGameStatus(player_game_status, 1, bonus_win_chip)
    end

    --尝试插入待加入的游戏流程
    GameStatusCal.Calculate.FlushGameStatus(player_game_status)

    --BaseGame结算(此处会加筹码)
    local base_finish_info =
        GameStatusCal.Calculate.FinishedInfo(player_game_status, GameStatusDefine.AllTypes.BaseSpinGame)
    local base_total_win = base_finish_info and base_finish_info.total_win_chip or 0
    if base_total_win > 0 then
        --发放筹码
        local reason =
            Reason[game_room_config.reason_name .. "_BET_CHIP_OBTAIN"]() or game_room_config.game_name .. " 投注道具获得"
        Player:Obtain(player, {"Chip", base_total_win}, reason)
        --玩家信息改变
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
                collect_chip = base_total_win
            }
        )
        --Bonus中奖的日志
        local OperativeInfo = {
            [1] = game_type,
            [2] = game_room_config.game_name,
            [3] = 1,
            [4] = player_game_info.bouts_id,
            [5] = SlotsGameCal.Calculate.GetBetAmount(player_game_info),
            [6] = base_total_win
        }
        Spark:SlotsBonusAward(player, OperativeInfo)

        -- 更新锦标赛记录
        CommonCal.Calculate.UpdateTournamentPlayerInfo(session, game_type, player, 0, base_total_win)

        ---处理lucky
        LuckyCal.OnBonusFinished(session, player_game_info, game_type, lineNum, chip_cost, base_total_win)
    end

    --填写回包信息
    content.game_status_list = json.encode(GameStatusCal.Calculate.GetAllGameStatus(player_game_status))
    response.content = json.encode(content)
    response.ret = Return.OK()
    response.game_type = game_type
    response.command_name = command_name
    LOG(RUN, INFO).Format(
        "[SlotsGame][%s] OK playerid %d, game_type %d, response is:%s",
        command_name,
        player.id,
        game_type,
        Table2Str(response)
    )

    --清理已经完成的流程
    GameStatusCal.Calculate.ClearFinishedStatus(player_game_status)
    if (GameStatusCal.Calculate.FinishedInfo(player_game_status, GameStatusDefine.AllTypes.BaseSpinGame) ~= nil) then
        GameStatusCal.Calculate.ClearGameStatus(player_game_status)
    end
    --保存数据
    CommonCal.Calculate.UpdateGameInfoToDbCache(task, player, player_game_info)
    CommonCal.Calculate.UpdatePlayerGameStatus(session, task, player, game_type, player_game_status)

    return response
end

local function CalcAmount(session, request)
    local player = session.player
    local game_type = player.game_type
    local bet_amount_conf = nil
    local max_bet_amount_conf = nil
    local game_bet_amount_conf = _G[GameMapConfig[game_type].bet_amount_config]

    local amount = 0
    if (request.bet_amount_id ~= nil and request.bet_amount_id > 0) then
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
            amount = #game_bet_amount_conf
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
    return amount
end

local function IsSpinValid(session, request, response)
    local filter_ret = RequestFilter.Filter("SlotsGame", "Start", session, request, true)

    if filter_ret then
        response.ret = filter_ret
        return false
    end

    local task = session.task
    local player = session.player

    CommonCal.Calculate.BeginStart(session, task, player)

    local game_type = player.game_type
    local game_room_config = GameRoomConfig[game_type]
    local lineNum = LineNum[game_type]()

    if GlobalState:IsSlotsMaintenance(session, task, player.id) == 1 then
        response.ret = Return.SERVER_NEAR_MAINENANCE()
        return false
    end

    if (player.game_type == 0) then
        response.ret = Return.HAVE_ALREADY_EXIT_GAME()
        return false
    end

    if (game_room_config == nil) then
        response.ret = Return.GAME_CONTEST_NULL_EXIT()
        return false
    end

    if (GameMapConfig[game_type] == nil) then
        response.ret = Return.GAME_CONTEST_NULL_EXIT()
        return false
    end

    return true
end

local function OnBaseSpinStart(session, spin_context)
    LuckyCal.OnBaseSpinStart(session, spin_context)
end

local function OnBaseSpinEnd(session, spin_context, base_info)
    local game_type = spin_context.game_type
    local amount = spin_context.amount
    local lineNum = spin_context.lineNum
    local chip_cost = spin_context.chip_cost

    FeverQuestCal.OnBaseGameEnd(session, game_type, amount, base_info.total_win_chip)

    if base_info.total_win_chip <= 0 then
        BoosterCal.OnGameSpin(session, amount * lineNum)
    end

    LuckyCal.OnBaseSpinEnd(session, spin_context)
end

local function OnFreeSpinEnd(session, spin_context, free_info)
    local game_type = spin_context.game_type
    local amount = spin_context.amount
    local lineNum = spin_context.lineNum
    local player = session.player

    FeverQuestCal.OnFreeGameEnd(session, game_type, amount, free_info.total_win_chip, free_info.spin_count)
    DailyMissionsCal.Calculate.UpdateDailyMissions(session, player, "HitFreeSpins", 1, {[1] = 1}, amount * lineNum)
end

local function FreeSpinMustWin(session, res_info, spin_context)
    local loop_times = 0
    local player = session.player
    local free_spin_bouts = GameStatusCal.Calculate.GetFreeSpinBouts(spin_context.player_game_status)
    local is_free_spin = spin_context.is_free_spin
    local amount = spin_context.amount
    local game_room_config = spin_context.game_room_config
    local player_game_info = spin_context.player_game_info
    local player_game_status = spin_context.player_game_status
    local extern_param = spin_context.extern_param

    while (res_info.total_win_chip <= 0 and free_spin_bouts == 0) do
        if (loop_times >= 5) then
            break
        end

        spin_context.temp_game_info = table.DeepCopy(player_game_info)
        spin_context.temp_game_status = table.DeepCopy(player_game_status)

        loop_times = loop_times + 1

        player.character.level = old_level
        player.character.chip = old_chip
        player.character.experience = old_experience

        res_info =
            _G["Slots" .. game_room_config.game_name][spin_context.func_name](
            {
                player = player,
                game_type = game_type,
                is_free_spin = is_free_spin,
                game_room_config = game_room_config,
                amount = amount,
                player_feature_condition = player_feature_condition,
                extern_param = extern_param,
                player_game_info = spin_context.temp_game_info,
                player_game_status = spin_context.temp_game_status,
                session = session,
                special_parameter = {}
            }
        )

        res_info.total_win_chip = math.floor(res_info.total_win_chip)
        res_info.slots_win_chip = math.floor(res_info.slots_win_chip)
        spin_context.need_deal_multiple = false
    end

    return res_info
end

local function SpinLimitMultiple(session, res_info, spin_context)
    local player = session.player
    local free_spin_bouts = GameStatusCal.Calculate.GetFreeSpinBouts(spin_context.player_game_status)
    local is_free_spin = spin_context.is_free_spin
    local amount = spin_context.amount
    local lineNum = spin_context.lineNum
    local game_room_config = spin_context.game_room_config
    local player_game_info = spin_context.player_game_info
    local player_game_status = spin_context.player_game_status
    local extern_param = spin_context.extern_param

    -- 中奖倍数限制
    local cur_level = player.character.level
    local total_amount = amount * lineNum

    local WinningMultipleLimitConfig =
        CommonCal.Calculate.get_config(player, game_room_config.game_name .. "WinningMultipleLimitConfig")
    local sel_config_info = nil

    for k, v in ipairs(WinningMultipleLimitConfig) do
        if
            (cur_level > v.level_min and cur_level <= v.level_max) and
                (total_amount > v.bet_amount_min and total_amount <= v.bet_amount_max)
         then
            sel_config_info = v
            break
        end
    end

    if not sel_config_info then
        return res_info
    end

    local cur_winning_multiple = res_info.total_win_chip / total_amount
    local loop_times = 0

    while (cur_winning_multiple > sel_config_info.winning_multiple) do
        if (loop_times >= 3) then
            break
        end
        LOG(RUN, INFO).Format("[SlotsGame][Start] player %s, begin deal normal control loop", player.id)

        spin_context.temp_game_info = table.DeepCopy(player_game_info)
        spin_context.temp_game_status = table.DeepCopy(player_game_status)

        loop_times = loop_times + 1

        player.character.level = old_level
        player.character.chip = old_chip
        player.character.experience = old_experience

        res_info =
            _G["Slots" .. game_room_config.game_name][spin_context.func_name](
            {
                player = player,
                game_type = game_type,
                is_free_spin = is_free_spin,
                game_room_config = game_room_config,
                amount = amount,
                player_feature_condition = player_feature_condition,
                extern_param = extern_param,
                player_game_info = spin_context.temp_game_info,
                player_game_status = spin_context.temp_game_status,
                session = session,
                special_parameter = {}
            }
        )

        res_info.total_win_chip = math.floor(res_info.total_win_chip)
        res_info.slots_win_chip = math.floor(res_info.slots_win_chip)

        cur_winning_multiple = res_info.total_win_chip / total_amount
    end

    return res_info
end

-- 开始slots
Start = function(_M, session, request)
    local response = {header = {router = "Response"}}

    if not IsSpinValid(session, request, response) then
        return response
    end

    local spin_context = {}

    local task = session.task
    local player = session.player
    local game_type = player.game_type
    local game_room_config = GameRoomConfig[game_type]
    local lineNum = LineNum[game_type]()
    local amount = CalcAmount(session, request)
    local player_feature_condition = CommonCal.Calculate.get_feature_condition(session, task, player, game_type)
    local player_game_info = SlotsGameCal.Calculate.InitPlayerGameInfo(session, task, player, game_type)
    local player_game_status = CommonCal.Calculate.GetPlayerGameStatus(session, task, player, game_type)

    player_game_info.game_type = game_type
    player_game_info.free_spin_num = 0
    player_game_info.save_data.map_config_info = nil

    spin_context.lineNum = lineNum
    spin_context.amount = amount
    spin_context.game_type = game_type
    spin_context.player_game_info = player_game_info

    local is_lock = CommonCal.Calculate.IsAppear(player)
    if (is_lock == 1) then
        response.ret = Return.LOCK_GAME()
        return response
    end

    GameStatusCal.Calculate.ClearFinishedStatus(player_game_status)

    if (GameStatusCal.Calculate.FinishedInfo(player_game_status, GameStatusDefine.AllTypes.BaseSpinGame) ~= nil) then
        GameStatusCal.Calculate.ClearGameStatus(player_game_status)
        GameStatusCal.Calculate.AddBaseGameStatus(player_game_status, amount)
    end

    local player_extern = CommonCal.Calculate.get_player_extern(session, task, player)
    local player_json_data = player_extern.save_data
    spin_context.player_json_data = player_json_data

    local cur_status = GameStatusCal.Calculate.GetGameStatus(player_game_status)

    if (cur_status == GameStatusDefine.AllTypes.BonusSpinGame) then
        response.ret = Return.GAME_CANNOT_PLAYE_BONUS_GAME()
        return response
    end

    local functions = CommonCal.Calculate.GetFunctions(player)
    if not functions or not functions[cur_status] then
        response.ret = Return.GAME_NOT_ENTER()
        return response
    end

    local func_name = functions[cur_status]

    local is_free_spin = false

    if (cur_status == GameStatusDefine.AllTypes.FreeSpinGame) then
        is_free_spin = true
    end

    if
        ((Base.Enviroment.pro_spec_t == "local" or Base.Enviroment.pro_spec_t == "docker-local" or
            Base.Enviroment.pro_spec_t == "dev" or
            Base.Enviroment.pro_spec_t == "docker-dev") and
            player.character.player_type ~= tonumber(ConstValue[5].value))
     then
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

        session:ContactPacket(task, async_request)
    end

    -- free spin不扣钱, free spin下amount不会改
    -- 这里只会处理消耗freespin，但是是否进入freespin 要在对应玩法逻辑中处理
    local chip_cost = 0

    if (cur_status == GameStatusDefine.AllTypes.BaseSpinGame) then
        SlotsGameCal.Calculate.ClearFreeSpinedCount(player_game_info)
        chip_cost = amount * lineNum

        local reason = game_room_config.game_name .. " 投注道具消耗"

        if not Player:Consume(player, {"Chip", chip_cost}, reason) then
            response.ret = Return.GAME_PLAYER_CHIP_NOT_ENOUGH()
            return response
        end
        player_game_info.save_data.spin_status = 0 ---0:normal,1:free spin,2 super free spin
        player_game_info.save_data.cur_free_status = 0

        player_json_data.is_free_spin_add = 0
    else
        if (cur_status == GameStatusDefine.AllTypes.FreeSpinGame) then
            player_game_info.free_spined_count = player_game_info.free_spined_count + 1
        end
        amount = SlotsGameCal.Calculate.GetBetAmount(player_game_info)
    end

    spin_context.chip_cost = chip_cost
    spin_context.player_game_info = player_game_info
    spin_context.player_game_status = player_game_status
    spin_context.game_room_config = game_room_config
    spin_context.is_free_spin = is_free_spin
    spin_context.func_name = func_name

    if cur_status == GameStatusDefine.AllTypes.BaseSpinGame then
        OnBaseSpinStart(session, spin_context)
    end

    local extern_param = {}
    spin_context.extern_param = extern_param

    extern_param.session = session

    local temp_game_info = table.DeepCopy(player_game_info)
    local temp_game_status = table.DeepCopy(player_game_status)
    spin_context.temp_game_info = temp_game_info
    spin_context.temp_game_status = temp_game_status

    local old_chip = player.character.chip
    local old_level = player.character.level
    local old_experience = player.character.experience

    local enter_status = cur_status

    -- 执行游戏逻辑
    local res_info =
        _G["Slots" .. game_room_config.game_name][func_name](
        {
            player = player,
            game_type = game_type,
            is_free_spin = is_free_spin,
            game_room_config = game_room_config,
            amount = amount,
            player_feature_condition = player_feature_condition,
            extern_param = extern_param,
            player_game_info = spin_context.temp_game_info,
            player_game_status = spin_context.temp_game_status,
            session = session,
            special_parameter = {}
        }
    )

    res_info.total_win_chip = math.floor(res_info.total_win_chip)
    res_info.slots_win_chip = math.floor(res_info.slots_win_chip)

    spin_context.need_deal_multiple = true
    if (player.character.lucky_type == LuckyType.ModeTypes.ForceWin) then
        spin_context.need_deal_multiple = false
    end

    local cur_status = GameStatusCal.Calculate.GetGameStatus(spin_context.temp_game_status)
    -- 如果玩家在free spin期间没有中奖，必中奖
    if (cur_status == GameStatusDefine.AllTypes.FreeSpinGame) then
        res_info = FreeSpinMustWin(session, res_info, spin_context)
    end

    if spin_context.need_deal_multiple then
        res_info = SpinLimitMultiple(session, res_info, spin_context)
    end

    local cur_status = GameStatusCal.Calculate.GetGameStatus(spin_context.temp_game_status)

    local win_chip = res_info.total_win_chip
    local final_result = res_info.final_result
    local all_prize_items = res_info.all_prize_list

    local formation_list = res_info.formation_list
    local reel_file_name = res_info.reel_file_name
    local slots_win_chip = res_info.slots_win_chip
    local special_parameter = res_info.special_parameter

    response.is_free_spin = is_free_spin and 1 or 0
    CommonCal.Calculate.set_game_json_value(temp_game_info, "is_free_spin", response.is_free_spin)

    if (is_free_spin) then
        player.record.free_spin = player.record.free_spin + 1
    end

    local free_win_amount = 0

    if (is_free_spin) then
        free_win_amount = win_chip
    end

    -- 局数+1
    temp_game_info.spined_times = temp_game_info.spined_times + 1
    local free_spin_bouts = GameStatusCal.Calculate.GetNewFreeSpinBouts(player_game_status)

    --当前流程的进度+1
    GameStatusCal.Calculate.UpdateGameStatus(spin_context.temp_game_status, 1, win_chip)

    local total_free_spin_num = GameStatusCal.Calculate.GetTotalFreeSpinNum(spin_context.temp_game_status)

    if (not is_free_spin and free_spin_bouts > 0) then
        temp_game_info.bouts_id = os.time()
    end

    if (enter_status == GameStatusDefine.AllTypes.BaseSpinGame) then
        -- 记录record
        player.record.total_spin = player.record.total_spin + 1
    end

    if (enter_status == GameStatusDefine.AllTypes.BaseSpinGame) then
        temp_game_info.bet_amount = amount
    end

    local multiply_value = 0
    local prize_config = _G[GameMapConfig[game_type].prize_config]

    --统一为进入的Bonus添加StatusInfo
    for formation_id = 1, #formation_list, 1 do
        local slots_spin_list = formation_list[formation_id].slots_spin_list
        if (#slots_spin_list > 0) then
            local slots_spin_info = slots_spin_list[1]
            local pre_action_list = json.decode(slots_spin_info.pre_action_list)

            for k, v in ipairs(pre_action_list) do
                if (v.action_type == ActionType.ActionTypes.EnterBonus) then
                    LOG(RUN, INFO).Format("[SlotsGame][Start] player %s, enter bonus", player.id)
                    if v.count and v.count > 0 then
                        GameStatusCal.Calculate.AddGameStatus(
                            spin_context.temp_game_status,
                            GameStatusDefine.AllTypes.BonusSpinGame,
                            v.count,
                            0,
                            1
                        )
                    else
                        GameStatusCal.Calculate.AddGameStatus(
                            spin_context.temp_game_status,
                            GameStatusDefine.AllTypes.BonusSpinGame,
                            1,
                            0,
                            1
                        )
                    end

                    break
                end
            end
            slots_spin_info.pre_action_list = json.encode(pre_action_list)
        end
    end

    --单个流程结束的结算提示框(此处只是提示信息，并没有真正给玩家筹码)
    GameStatusCal.Calculate.FlushGameStatus(spin_context.temp_game_status)

    local award_info_list = GameStatusCal.Calculate.GetFinishedStatus(spin_context.temp_game_status)
    if (_G["Slots" .. game_room_config.game_name].FeatureEnd ~= nil) then --有特性结束的处理函数（FreeSpin、HoldSpin）
        for _, award_info in ipairs(award_info_list) do
            --状态信息
            local status_info = {
                status_id = award_info.status_id,
                win_chip = award_info.collect_info.total_win_chip,
                spin_count = award_info.collect_info.spin_count
            }

            --每个转轴都传入该特性的结算信息
            for formation_id = 1, #formation_list, 1 do
                local slots_spin_list = formation_list[formation_id].slots_spin_list
                if (#slots_spin_list > 0) then
                    local slots_spin_info = slots_spin_list[1]
                    local pre_action_list = json.decode(slots_spin_info.pre_action_list or "{}")
                    _G["Slots" .. game_room_config.game_name].FeatureEnd(
                        game_room_config,
                        temp_game_info,
                        player,
                        status_info,
                        pre_action_list,
                        special_parameter
                    )
                    slots_spin_info.pre_action_list = json.encode(pre_action_list)
                end
            end
        end
    end

    --BaseGame结算(此处会加筹码)
    local base_finish_info =
        GameStatusCal.Calculate.FinishedInfo(spin_context.temp_game_status, GameStatusDefine.AllTypes.BaseSpinGame)
    local base_total_win = base_finish_info and base_finish_info.total_win_chip or 0

    if base_total_win > 0 then
        local reason =
            Reason[game_room_config.reason_name .. "_BET_CHIP_OBTAIN"]() or game_room_config.game_name .. " 投注道具获得"
        Player:Obtain(player, {"Chip", base_total_win}, reason)

        --计算大奖倍增
        local win_chip_cal_multiple = base_total_win --用于计算大奖倍增的赢钱值
        if special_parameter and special_parameter.win_chip_cal_multiple then
            win_chip_cal_multiple = special_parameter.win_chip_cal_multiple
        end
        multiply_value = (win_chip_cal_multiple / (amount * lineNum))
        if (multiply_value >= prize_config[3].min_multiple) then
            player.statistics.epicwin_num = player.statistics.epicwin_num + 1
        elseif (multiply_value >= prize_config[2].min_multiple) then
            player.statistics.megawin_num = player.statistics.megawin_num + 1
        elseif (multiply_value >= prize_config[1].min_multiple) then
            player.statistics.bigwin_num = player.statistics.bigwin_num + 1
        end
        response.multiply_value = multiply_value * 1000

        local can_multiply = SlotsGameCal.Calculate.WinChipInMultiply(base_total_win)
        if (can_multiply and multiply_value >= prize_config[1].min_multiple and not is_free_spin) then
            response.is_multiply = CommonCal.Calculate.IsMultiply(session, base_total_win)
        end
    end

    local new_free_spin_bouts = GameStatusCal.Calculate.GetFreeSpinBoutsInEnd(spin_context.temp_game_status)

    response.game_status_list = json.encode(GameStatusCal.Calculate.GetAllGameStatus(spin_context.temp_game_status))

    temp_game_info.last_formation_list = table.DeepCopy(formation_list)

    for k, v in pairs(temp_game_info.last_formation_list) do
        for sub_k, sub_v in pairs(v.slots_spin_list) do
            sub_v.prize_items = nil
        end
    end

    temp_game_info.last_formation_list = json.encode(temp_game_info.last_formation_list)

    session.game_info[game_type] = temp_game_info
    session.game_status = spin_context.temp_game_status
    player_game_info = session.game_info[game_type]
    player_game_status = session.game_status

    -- gain exp
    if enter_status == GameStatusDefine.AllTypes.BaseSpinGame then
        local exp = chip_cost
        local exp_request = {
            type = "Slots" .. game_room_config.game_name,
            ante_gold = amount * lineNum,
            gain_exp = exp
        }
        Player:GainExp(session, exp_request)
    end

    DailyMissionsCal.Calculate.UpdateGameDailyMissions(
        session,
        player,
        amount,
        chip_cost,
        win_chip,
        is_free_spin,
        player.game_type,
        new_free_spin_bouts,
        cur_status
    )

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

    local is_bonus_game = false

    if _G["Slots" .. game_room_config.game_name].IsBonusGame then
        is_bonus_game =
            _G["Slots" .. game_room_config.game_name].IsBonusGame(game_room_config, player, player_game_info)
    end

    if is_bonus_game then
        player.statistics.bonus_game_num = player.statistics.bonus_game_num + 1
    end

    Player:BroadCastChip(session, task, amount * lineNum, win_chip)

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

    response.formation_list = formation_list

    if (is_free_spin) then
        Spark:SlotsAward(
            player,
            {
                [1] = game_type,
                [2] = game_room_config.game_name,
                [3] = 1,
                [4] = player_game_info.bouts_id,
                [5] = amount,
                [6] = win_chip,
                [7] = json.encode(final_result),
                [8] = "[]",
                [9] = reel_file_name and reel_file_name or "",
                [10] = free_spin_bouts,
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
                [3] = 1,
                [4] = player_game_info.bouts_id,
                [5] = amount,
                [6] = chip_cost,
                [7] = win_chip,
                [8] = json.encode(final_result),
                [9] = "[]",
                [10] = is_free_spin,
                [11] = reel_file_name and reel_file_name or "",
                [12] = CommonCal.Calculate.GetFiveLineCount(all_prize_items) > 0 and 1 or 0,
                [13] = player.record.total_spin
            }
        )
    end

    local base_info = GameStatusCal.Calculate.FinishedInfo(player_game_status, GameStatusDefine.AllTypes.BaseSpinGame)

    if base_info ~= nil then
        spin_context.win_chip = base_total_win
        OnBaseSpinEnd(session, spin_context, base_info)
    end

    local free_info = GameStatusCal.Calculate.FinishedInfo(player_game_status, GameStatusDefine.AllTypes.FreeSpinGame)

    if free_info ~= nil and free_info.spin_count and free_info.spin_count > 0 then
        OnFreeSpinEnd(session, spin_context, free_info)
    end

    response.game_info = {
        bet_amount = amount,
        free_spin_bouts = GameStatusCal.Calculate.GetFreeSpinBoutsInEnd(player_game_status),
        total_spin_bouts = total_free_spin_num,
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

    if win_chip > 0 then
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
                win_chip = win_chip,
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
        win_chip,
        true
    )

    -- 新加游戏锦标赛的功能
    CommonCal.Calculate.UpdateTournamentPlayerInfo(session, game_type, player, chip_cost, win_chip)
    CommonCal.Calculate.UpdateToDbCache(task, player, "feature_condition", player_feature_condition)
    CommonCal.Calculate.update_player_extern(session, task, player)

    --填写回包数据
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

    --清理已经完成的流程
    GameStatusCal.Calculate.ClearFinishedStatus(player_game_status)
    if (GameStatusCal.Calculate.FinishedInfo(player_game_status, GameStatusDefine.AllTypes.BaseSpinGame) ~= nil) then
        GameStatusCal.Calculate.ClearGameStatus(player_game_status)
    end
    --保存数据
    CommonCal.Calculate.UpdateGameInfoToDbCache(task, player, player_game_info)
    CommonCal.Calculate.UpdatePlayerGameStatus(session, task, player, game_type, player_game_status)

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

    local player_game_info = SlotsGameCal.Calculate.InitPlayerGameInfo(session, task, player, game_type)

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
    player.game_type = 0

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
