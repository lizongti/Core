---------------
--  Account  --
---------------
require "Base/Path"
require "Util/TableExt"
require "Util/StringExt"
require "Base/Task"
require "Common/Return"
require "Common/RequestFilter"
require "Module/DailyWheel"
require "Base/TableDefine"
require "Base/CacheDefine"
require "Common/AccountVersionCal"
require "Common/NewLoginAwardCal"
require "Common/MailType"

_G.luajwt_success, _G.luajwt = pcall(require, "luajwt")
module("Account", package.seeall)

---------------登录，activity,config慢---------------------
Login = function(_M, session, request)
    local t = system.time()
    LOG(RUN, INFO).Format("[Account][Login] token %s start login", request.token)
    local response = {header = {router = "Response"}}

    local player_id = player_id_
    local task = session.task

    if not player_id then
        local filter_ret = RequestFilter.Filter("Account", "Login", session, request)
        if filter_ret then
            LOG(RUN, INFO).Format("[Account][Login] filter_ret error")
            response.ret = filter_ret
            return response
        end

        if _G.luajwt_success then
            local data = _G.luajwt.decode(request.token, "zwMKRFwlGdtB1nfFSdtCgHduYF3ZCXVY", "HS256")
            player_id = data.id
            LOG(RUN, INFO).Format("[Account][Login] luajwt decode player_id %s", player_id)
        else
            LOG(RUN, INFO).Format("[Account][Login] redis hash get player_id begin")
            local async_request = {[1] = string.format("hmget jwt_to_id %s", request.token)}
            local async_response = session:ContactJson("CacheClientService", task, async_request, request.token)
            player_id = tonumber(async_response[1])
            LOG(RUN, INFO).Format("[Account][Login] redis hash get player_id %s end", player_id)
        end
    end

    -- 异步登记到store列表中，不影响登录速度
    Task:Work(
        function(task)
            session:ContactJson(
                "CacheClientService",
                task,
                {string.format("sadd store_player_list %s", player_id)},
                player_id
            )
        end
    )

    if not player_id then
        LOG(RUN, INFO).Format("[Account][Login] token not exist:%s", request.token)
        response.ret = Return.ACCOUNT_TOKEN_NOT_EXIST()
        return response
    end

    if GlobalState:IsMaintenance(session, task, player_id) == 1 then
        response.ret = Return.SERVER_NEAR_MAINENANCE()
        LOG(RUN, INFO).Format("[Account][Login] server is maintence")
        return response
    end

    LOG(RUN, INFO).Format("[Account][Login] player %s register player watcher start.", player_id)

    -- drop player from other servers
    local async_request = {
        header = {
            router = "AsyncRequest",
            service_name = "ManagerClientService",
            task_id = task.id,
            module_id = "PlayerWatcher",
            message_id = "PlayerWatcher_Register_Request"
        },
        session_id = session.id,
        player_id = player_id,
        player_type = 0
    }

    local dropping = 0
    while dropping == 0 do
        local async_response = session:ContactPacket(task, async_request)
        if async_response.ret.code ~= 0 then
            return response
        end
        dropping = async_response.dropping
    end
    LOG(RUN, INFO).Format("[Account][Login] player %s register player watcher ok.", player_id)

    -- pull player info
    LOG(RUN, INFO).Format("[Account][Login] player %s start init player", player_id)
    local name = string.format("player[%s]", player_id)
    local proto_func = _G["DbPlayer_pb"]["DbPlayer"]
    local async_request = TableCache:GetBuildCommand(name, proto_func)

    local async_response = session:ContactJson("CacheClientService", task, async_request, player_id)
    session.player = TableCache:BuildTable(async_response, name, proto_func)
    local is_newer = false
    if session.player.id then
        for module_key, module_value in pairs(Player:GetInitPlayer()) do
            if not session.player[module_key] then
                session.player[module_key] = module_value
            elseif type(module_value) == "table" then
                for item_key, item_value in pairs(module_value) do
                    if
                        not session.player[module_key][item_key] or
                            type(session.player[module_key][item_key]) ~= type(item_value)
                     then
                        session.player[module_key][item_key] = item_value
                    end
                end
            elseif type(module_value) ~= type(session.player[module_key]) then
                session.player[module_key] = module_value
            end
        end
        if (session.player.character.total_login_times == 0) then
            session.player.character.total_login_times = 50
        end
    else
        table.assign(Player:GetInitPlayer(), session.player)
        session.player.user.avatar = math.random(1, 10)
        session.player.id = player_id
        is_newer = true
    end

    local player = session.player

    if (player.character.player_type == 0) then
        local weight = {}
        for type_id, config_info in ipairs(PlayerTypeConfig) do
            if (#config_info.players == 0) then
                table.insert(weight, config_info.rand_weight)
            else
                table.insert(weight, 0)
            end
        end
        player.character.player_type = math.rand_weight(player, weight)
    end

    LOG(RUN, INFO).Format("[Account][Login] player %s, player_type is:%s", player_id, player.character.player_type)
    for type_id, config_info in ipairs(PlayerTypeConfig) do
        for k, p_id in ipairs(config_info.players) do
            LOG(RUN, INFO).Format(
                "[Account][Login] player %s, p_id is:%s, player_type is:%s",
                player_id,
                p_id,
                player.character.player_type
            )
            if p_id == player.id then
                player.character.player_type = type_id
            end
        end
    end
    LOG(RUN, INFO).Format("[Account][Login] player %s, player_type is:%s", player_id, player.character.player_type)

    -- register distributor
    local register_channel_id = {"Global", "Hall"}
    -- if player.club_info.club_id ~= -1 then
    --     table.insert(register_channel_id, string.format("Slots.Club.%s", player.club_info.club_id))
    -- end

    LOG(RUN, INFO).Format("[Account][Login] player %s register notification start.", player_id)
    local async_request = {
        header = {
            router = "AsyncRequest",
            service_name = "NotificationClientService",
            task_id = task.id,
            module_id = "Distributor",
            message_id = "Distributor_Register_Request"
        },
        session_id = session.id,
        player_id = session.player.id,
        channel_id = register_channel_id,
        player_type = session.player.character.player_type
    }

    local async_response = session:ContactPacket(task, async_request)
    if async_response.ret.code ~= 0 then
        LOG(RUN, INFO).Format("[Account][Login]old player %s start register distributor end", player_id)
        response.ret = async_response.ret
        return response
    end
    LOG(RUN, INFO).Format("[Account][Login] player %s register notification ok.", player_id)

    Player:UpdateAccountClient(session, {account = request.account, client = request.client})

    player.character.last_login_time = player.character.login_time or 0
    if player.character.login_time == 0 or not os.same_day(player.character.last_login_time, os.time()) then
        LOG(RUN, INFO).Format("[Account][Login] player %s begin deal daily bonus", player_id)

        player.character.login_time = os.time()
        local chip_award = 20000
        if (player.character.level >= 25) then
            chip_award = 100000
        end
        local props = json.encode({[1] = {1000, chip_award}})

        session:WriteRouterPacket(
            {
                header = {
                    router = "LocalRequest",
                    service_name = "ManagerClientService",
                    module_id = "Mail",
                    message_id = "Mail_DailyBonusAward_Request"
                },
                player_id = player.id,
                props = props
            }
        )
    else
        player.character.login_time = os.time()
    end

    Player:UpdateVIP(session)
    Player:SettleChargeInfo(session)
    Player:LoginReset(player)

    -----新玩家第一次登陆，直接进入玩法，不弹出转盘
    if (not is_newer) then
        local wheel_index,
            wheel_chip_get,
            vip_extra_bonus,
            con_login_reward,
            con_login_diamonds,
            continue_login_days,
            vip_point_award,
            cur_wheel_name,
            old_wheel_name,
            his_collect_info = DailyWheel:Login(session)

        if wheel_index and wheel_chip_get and con_login_reward then
            response.daily_wheel = {
                index = wheel_index,
                chip_get = wheel_chip_get,
                vip_extra_chip = vip_extra_bonus,
                con_login_reward = con_login_reward,
                con_login_diamonds = con_login_diamonds,
                continue_login_days = continue_login_days,
                vip_point_award = vip_point_award,
                cur_wheel_name = cur_wheel_name,
                old_wheel_name = old_wheel_name,
                his_collect_info = json.encode(his_collect_info),
                is_old_hand = player.character.is_old_hand
            }
            LOG(RUN, INFO).Format("[Account][Login] daily_wheel is:%s", Table2Str(response.daily_wheel))
        end

        player.character.last_wheel_time = player.character.login_time or 0
    end

    if player.character.last_login_time == 0 then
        local OpenSesameOthersConfig = CommonCal.Calculate.get_config(player, "OpenSesameOthersConfig")
        Player:Obtain(player, {"Chip", OpenSesameOthersConfig[1].player_init_chip}, Reason.INIT_PROP_OBTAIN())

        player.character.level = 1
        player.character.create_time = os.time()
        player.user.nickname = CommonCal.Calculate.get_name()
        player.user.sex = 0
        player.user.signature = "Enjoy life, playing Cash Fever Slots!"

        Spark:Activate(player)

        --新手Lucky
        LuckyCal.OnFirstLogin(session)
    end

    if (os.same_day(player.character.create_time, player.character.login_time)) then
        response.is_new_player = 1
    else
        response.is_new_player = 0
    end

    local binding_status = "normal"
    if (player.account.facebook_id ~= "") then
        binding_status = "facebook"
    elseif (player.account.google_id ~= "") then
        binding_status = "google"
    end

    CommonCal.Calculate.ResetBonusAward(player)
    -- log login

    Spark:Login(
        player,
        {
            [1] = player.daily_wheel.continue_login_days,
            [2] = player.daily_wheel.acc_login_days,
            [3] = player.character.last_login_time,
            [4] = player.character.level,
            [5] = binding_status,
            [6] = player.character.create_time,
            [7] = player.character.recharge_count,
            [8] = player.statistics.history_games,
            [9] = player.statistics.last_game,
            [10] = player.statistics.bigwin_num,
            [11] = player.statistics.megawin_num,
            [12] = player.statistics.epicwin_num,
            [13] = player.statistics.bonus_game_num,
            [14] = player.statistics.bonus_award,
            [15] = player.record.total_spin
        }
    )

    if (player.character.piggy_bank_chip == 0) then
        player.character.piggy_bank_chip =
            CommonCal.Calculate.CalcBaseWithLevel(PiggyBankConfig[1].minamout, player.character.level)
    end

    response.slots_level_lock_info = "[]"
    response.ret = Return.OK()

    if (player.character.login_award_time < player.character.off_line_time) then
        local off_line_seconds = os.time() - player.character.off_line_time
        player.character.login_award_time = player.character.login_award_time + off_line_seconds
        player.character.off_line_time = 0
    end
    if (player.character.login_award_time > os.time()) then
        player.character.login_award_time = os.time()
    end
    player.character.login_award_seconds = os.time() - player.character.login_award_time
    session.player.task_info.daily_task = "[]"
    session.player.task_info.panther_tracks = "[]"
    session.player.unlock_games = "[]"
    session.player.unlock_free_games = "[]"
    session.player.unlock_diamond_games = "[]"
    response.player = session.player

    if (Base.Enviroment.pro_spec_t ~= "online") then
        response.is_dev = 1
    else
        response.is_dev = 0
    end

    -- response.game_sort_info = json.encode(CommonCal.Calculate.get_config(player, "GameSortConfig"))
    response.game_sort_info = "[]"

    local ui_type = {}
    table.insert(ui_type, {type = 1, value = 0})
    response.ui_type = json.encode(ui_type)

    response.slot_level_config = "[]"

    if (player.character.pay_fail_award == 0) then
        response.pay_award = 0
    else
        response.pay_award = 1
    end

    -- 清除指定日期前的玩家LUCKY值
    local clear_mode_str = string.split(ConstValue[24].value, ":")
    local clear_mode_time =
        os.time(
        {
            year = tonumber(clear_mode_str[1]),
            month = tonumber(clear_mode_str[2]),
            day = tonumber(clear_mode_str[3]),
            hour = tonumber(clear_mode_str[4]),
            min = tonumber(clear_mode_str[5]),
            sec = tonumber(clear_mode_str[6])
        }
    )

    if (clear_mode_time >= player.character.create_time) then
        if player.character.enter_lucky ~= 999 then
            player.character.enter_lucky = 999
            player.character.lucky = 0
            player.character.unlucky = 0
            player.character.lucky_credit_change = 0
            player.character.unlucky_credit_change = 0
        end
    end

    Player:InitExperience(session)

    if request.version and request.version > 0 then
        local cur_version = AccountVersionCal.Calculate.GetAccountVersion(session)
        if request.version > cur_version then
            local props = json.encode({[1] = {1000, 100000}})
            local data = {
                title = MailType.TitleContentConfig["VersionAward"].title,
                content = MailType.TitleContentConfig["VersionAward"].content,
                sender = "system",
                attachments = props,
                mail_type = MailType.MailTypes.UPDATE_VERSION,
                player_id = player.id
            }

            if cur_version ~= 0 then
                MailDAL.Calculate.AddMail(Task:Current(), player.id, data)
            end

            AccountVersionCal.Calculate.UpdateAccountVersion(session, request.version)
        end
    end

    -- 每日登录奖励
    NewLoginAwardCal.OnPlayerLogin(session)

    response.res_version = AccountVersionCal.Calculate.GetLoginVersion(session, player)

    LOG(RUN, INFO).Format("[Account][Login] player %s login successfully", player.id)

    return response
end

AgentLogin = function(_M, session, request)
    if session.player then
        --玩家已经登录了
        local response = {header = {router = "Response"}}
        response.ret = Return.OK()
        return response
    end

    local response = Login(_M, session, request, tonumber(request.token))
    return response
end

PayFailAward = function(_M, session, request)
    local response = {header = {router = "Response"}}
    local player = session.player

    local task = session.task

    if (player.character.pay_fail_award == 1) then
        response.ret = Return.OK()
        return response
    end

    local old_chip = player.character.chip

    player.character.pay_fail_award = 1

    local award_value = tonumber(ConstValue[1].value)
    local all_items = {}
    local item = {id = 1000, amount = award_value}
    table.insert(all_items, item)

    Player:Obtain(player, {"Chip", award_value}, Reason.PAY_FAIL_AWARD())
    session:WriteRouterPacket(
        {
            header = {
                router = "SpecificNotice",
                session_id = session.id,
                player_id = player.id,
                module_id = "Command",
                message_id = "Command_GetAttachments_Notice"
            },
            item = all_items,
            attachments_type = 1
        }
    )

    session:WriteRouterPacket(
        {
            header = {
                router = "SpecificNotice",
                session_id = session.id,
                player_id = player.id,
                module_id = "Command",
                message_id = "Command_Player_Notice"
            },
            player = {character = {chip = player.character.chip}},
            collect_chip = player.character.chip - old_chip
        }
    )

    response.ret = Return.OK()
    return response
end

Logout = function(_M, session, request)
    local response = {header = {router = "Response"}}
    local player = session.player

    response.ret = Return.OK()
    return response
end

ClientAction = function(_M, session, request)
    local response = {header = {router = "Response"}}

    local player = session.player

    local content = request.content

    Action:ClientAction(player, {[1] = content})

    response.ret = Return.OK()
    return response
end

Config = function(_M, session, request)
    local response = {header = {router = "Response"}}

    local player = session.player

    if (player == nil) then
        LOG(RUN, INFO).Format("[Account][Config] player is null: %s")
        local table_content = {}
        response.table_content = table_content
        response.ret = Return.PLAYER_NOT_FOUND()
        return response
    end
    -- LOG(RUN, INFO).Format("[Account][Config] player %s begin: %s", player.id, Table2Str(request))

    local game_room_config = GameRoomConfig[request.game_type]

    local table_content = {}

    for _, table_name in ipairs(request.table_name) do
        local config = CommonCal.Calculate.get_config(player, table_name)
        if (config ~= nil) then
            table.insert(table_content, json.encode({name = table_name, content = config}))
        elseif (_G[table_name] ~= nil) then
            table.insert(table_content, json.encode({name = table_name, content = _G[table_name]}))
        end
    end

    response.table_content = table_content
    response.ret = Return.OK()
    return response
end

RateUs = function(_M, session, request)
    local response = {header = {router = "Response"}}

    local player = session.player

    player.mega_win_number = player.mega_win_number - 1
    if (player.mega_win_number < 0) then
        player.mega_win_number = 0
    end

    response.ret = Return.OK()
    return response
end

SetBackground = function(_M, session, request)
    local response = {header = {router = "Response"}}
    local common_ret = RequestFilter.AllFilter.Common(session, request)
    if common_ret then
        response.ret = common_ret
        return response
    end

    local async_request = {
        header = {
            router = "AsyncRequest",
            service_name = "ManagerClientService",
            task_id = task.id,
            module_id = "PlayerWatcher",
            message_id = "PlayerWatcher_SetBackground_Request"
        },
        session_id = session.id,
        player_id = player_id
    }

    local async_response = session:ContactPacket(task, async_request)

    response.ret = Return.OK()
    return response
end

SetUser = function(_M, session, request)
    local response = {header = {router = "Response"}}
    local common_ret = RequestFilter.AllFilter.Common(session, request)
    if common_ret then
        response.ret = common_ret
        return response
    end

    response.player = {user = {}}
    local player = session.player
    local task = session.task

    LOG(RUN, INFO).Format("[Account][SetUser] player %s request:%s", player.id, Table2Str(request))
    if request.user.nickname and request.user.nickname ~= "" then
        LOG(RUN, INFO).Format("[Account][SetUser] player %s nickname begin", player.id)
        local nickname_ret = RequestFilter.Filter("Account", "SetUser", session, request, false, "Nickname")
        if nickname_ret then
            LOG(RUN, INFO).Format("[Account][SetUser] player %s error nickname:%s", player.id, request.user.nickname)
            response.ret = nickname_ret
            return response
        end

        local origin_nickname = player.user.nickname
        player.user.nickname = request.user.nickname
        response.player.user.nickname = request.user.nickname
        -- opt

        Spark:SetUser(player, {[1] = "nickname", [2] = origin_nickname, [3] = player.user.nickname})

        RankHelper:ChallengeUpdate(session.player)

        Player:BroadCastBaseInfo(session, task)
    end

    if request.user.sex and request.user.sex ~= 0 then
        LOG(RUN, INFO).Format("[Account][SetUser] player %s sex begin", player.id)
        local sex_ret = RequestFilter.Filter("Account", "SetUser", session, request, false, "Sex")
        if sex_ret then
            LOG(RUN, INFO).Format("[Account][SetUser] player %s error sex:%s", player.id, request.user.sex)
            response.ret = sex_ret
            return response
        end
        local origin_sex = session.player.user.sex
        session.player.user.sex = request.user.sex
        response.player.user.sex = request.user.sex
        -- opt

        Spark:SetUser(player, {[1] = "sex", [2] = origin_sex, [3] = session.player.user.sex})

        RankHelper:ChallengeUpdate(session.player)
    end

    if request.user.signature and request.user.signature ~= "" then
        LOG(RUN, INFO).Format("[Account][SetUser] player %s signature begin", player.id)
        local signature_ret = RequestFilter.Filter("Account", "SetUser", session, request, false, "Signature")
        if signature_ret then
            response.ret = signature_ret
            return response
        end
        local origin_signature = session.player.user.signature
        session.player.user.signature = request.user.signature
        response.player.user.signature = request.user.signature

        Spark:SetUser(
            player,
            {
                [1] = "signature",
                [2] = origin_signature,
                [3] = session.player.user.signature
            }
        )
    end

    if request.user.age and request.user.age ~= 0 then
        LOG(RUN, INFO).Format("[Account][SetUser] player %s age begin", player.id)
        local age_ret = RequestFilter.Filter("Account", "SetUser", session, request, false, "Age")
        if age_ret then
            LOG(RUN, INFO).Format("[Account][SetUser] player %s error age:%s", player.id, request.user.age)
            response.ret = age_ret
            return response
        end
        local origin_age = session.player.user.age
        session.player.user.age = request.user.age
        response.player.user.age = request.user.age
        -- opt

        Spark:SetUser(player, {[1] = "age", [2] = origin_age, [3] = session.player.user.age})
    end

    if request.user.location and request.user.location ~= "" then
        LOG(RUN, INFO).Format("[Account][SetUser] player %s location begin", player.id)
        local location_ret = RequestFilter.Filter("Account", "SetUser", session, request, false, "Location")
        if location_ret then
            LOG(RUN, INFO).Format("[Account][SetUser] player %s error location:%s", player.id, request.user.location)
            response.ret = location_ret
            return response
        end
        local origin_location = session.player.user.location
        session.player.user.location = request.user.location
        response.player.user.location = request.user.location
        -- opt

        Spark:SetUser(
            player,
            {
                [1] = "location",
                [2] = origin_location,
                [3] = session.player.user.location
            }
        )
    end

    if request.user.country and request.user.country ~= "" then
        LOG(RUN, INFO).Format("[Account][SetUser] player %s country begin", player.id)
        local country_ret = RequestFilter.Filter("Account", "SetUser", session, request, false, "Country")
        if country_ret then
            LOG(RUN, INFO).Format("[Account][SetUser] player %s error country:%s", player.id, request.user.country)
            response.ret = country_ret
            return response
        end
        local origin_country = session.player.user.country
        session.player.user.country = request.user.country
        response.player.user.country = request.user.country
        -- opt

        Spark:SetUser(player, {[1] = "country", [2] = origin_country, [3] = session.player.user.country})
    end

    if request.user.avatar and request.user.avatar ~= 0 then
        LOG(RUN, INFO).Format("[Account][SetUser] player %s avatar begin", player.id)
        local origin_avatar = session.player.user.avatar
        session.player.user.avatar = request.user.avatar
        response.player.user.avatar = request.user.avatar

        -- opt

        Spark:SetUser(player, {[1] = "avatar", [2] = origin_avatar, [3] = session.player.user.avatar})

        RankHelper:ChallengeUpdate(session.player)
        Player:BroadCastBaseInfo(session, task)
    end

    -- if player.club_info.club_id ~= -1 and (request.user.avatar or request.user.nickname) then
    --     local player_brief_info = Player:GetBrief(player)
    --     local player_id = player.id
    --     local async_request = {string.format(
    --             "update slots.club_player_info set player_info = '%s' where player_id = %s",
    --             json.encode(player_brief_info),
    --             player_id
    --         )
    --     }
    --     async_response = session:ContactJson("DatabaseClientService", task, async_request, player_id)
    -- end
    LOG(RUN, INFO).Format("[Account][SetUser] player %s end, response is:%s", player.id, Table2Str(response))
    response.ret = Return.OK()
    return response
end

HeartBeat = function(_M, session, request)
    local response = {header = {router = "Response"}}
    if not session or not session.player then
        -- response.ret = Return.PLAYER_NOT_FOUND()
        -- 兼容gateway
        response.ret = Return.OK()
        return response
    end

    local player = session.player
    local task = session.task

    -- LOG(RUN, INFO).Format("[Account][HeartBeat] send player watcher successfully, player_id:%s", player.id)

    session:WriteRouterPacket(
        {
            header = {
                router = "Inform",
                service_name = "ManagerClientService",
                task_id = task.id,
                module_id = "PlayerWatcher",
                message_id = "PlayerWatcher_HeartBeat_Request"
            },
            player_id = session.player.id
        }
    )

    response.ret = Return.OK()

    return response
end

GetBriefInfo = function(_M, session, request)
    local response = {header = {router = "Response"}}
    if not session or not session.player then
        response.ret = Return.PLAYER_NOT_FOUND()
        return response
    end

    local player = session.player
    local des_player_id = request.player_id
    local task = session.task
    local async_request = {
        string.format(
            "select data from slots.player_brief_%s where id = %s",
            math.mod(des_player_id, 16),
            des_player_id
        )
    }

    local async_response = session:ContactJson("DatabaseClientService", task, async_request, des_player_id)
    if async_response[1].row_num < 0 then
        response.ret = Return.ACCOUNT_DATABASE_ERROR()
        return response
    end

    if async_response[1].row_num == 0 then
        response.ret = Return.ACCOUNT_SENDITEM_PLAYER_NOT_FOUND()
        return response
    end
    local data = async_response[1].data_set[1]

    response.user = json.decode(data[1])
    response.ret = Return.OK()

    return response
end

OnSignal = function(_M, session, request)
    LOG(RUN, INFO).Format("[Account][OnSignal] begin")
    local response = {header = {router = "Response"}}
    if not session or not session.player then
        response.ret = Return.PLAYER_NOT_FOUND()
        return response
    end

    local player = session.player
    local include_player_id = request.include_player_id

    player.client.device_token = include_player_id

    response.ret = Return.OK()

    return response
end

InWhiteList = function(_M, session, request)
    -- 检测合法性
    local response = {header = {router = "Response"}}
    if not session or not session.player then
        response.ret = Return.PLAYER_NOT_FOUND()
        return response
    end

    -- 生成返回数据
    local player_id = session.player.id
    local is_in = false
    if AccountWhiteList[player_id] then
        is_in = true
    end
    -- 填入返回数据
    response.ret = Return.OK()
    response.is_in = is_in

    -- 返回
    return response
end

Ping = function(_M, session, request)
    local response = {header = {router = "Response"}}
    response.ret = Return.OK()
    return response
end

Cheat = function(_M, session, request)
    local response = {header = {router = "Response"}}
    local player = session.player

    response.ret = Return.OK()

    -- chip 1000
    if request.arg1 == "chip" then
        player.character.chip = player.character.chip + tonumber(request.arg2)
        LOG(RUN, INFO).Format("[Account][Cheat] add gold %s %s", player.character.chip, tonumber(request.arg2))
    elseif request.arg1 == "buy" then
        local content = {
            payment_id = 130000000,
            payment_type = "apple",
            goods_id = tonumber(request.arg2) or 10005,
            player_id = player.id,
            is_double_purchase = tonumber(request.arg2)
        }
        request.content = json.encode(content)
        Command.TestGoods(session, request)
    elseif request.arg1 == "level" then
        player.character.level = tonumber(request.arg2)
        LOG(RUN, INFO).Format("[Account][Cheat] set level %s", player.character.level)
    elseif request.arg1 == "exp" then
        player.character.experience = player.character.experience + tonumber(request.arg2)
        LOG(RUN, INFO).Format("[Account][Cheat] add exp %s %s", player.character.experience, tonumber(request.arg2))
    elseif request.arg1 == "boost" then
        BoosterCal.ProcessCashbackMail()
    elseif request.arg1 == "daily" then
        LOG(RUN, INFO).Format("[Account][Cheat] refresh daily")
        DailyMissions.RefreshDailyMessions(_M, session, request, true)
    else
        response.ret = Return.SERVER_NEAR_MAINENANCE()
    end

    return response
end
