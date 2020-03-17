module("BoosterCal", package.seeall)

function SaveBoosterInfo(session)
    ActivityCal.Calculate.UpdateActivityInfo(session, ActivityDefine.AllTypes.Booster)
end

local function GetCashbackChips(session)
    local task = Task:Current()
    task.create_time = os.time()

    local key = string.format("hget cashback_players %s", session.player.id)
    local async_request = {[1] = key}
    local response = LuaSession:ContactJson("CacheClientService", task, async_request, 0)

    if not response then
        return 0
    end

    if response and response[1] == "" then
        return 0
    end

    return tonumber(response[1])
end

function GetBoosterInfo(session)
    local booster = ActivityCal.Calculate.GetActivityInfo(session, ActivityDefine.AllTypes.Booster)
    booster.cashback_end_time = booster.cashback_end_time or 0

    if booster.cashback_end_time < os.time() then
        booster.cashback_end_time = 0
    end

    booster.cashback_chips = GetCashbackChips(session) or 0
    booster.cashback_rate = booster.cashback_rate or 0
    booster.bundle_double_count = booster.bundle_double_count or 0

    booster.levelrush_end_time = booster.levelrush_end_time or 0

    if booster.levelrush_end_time < os.time() then
        booster.levelrush_end_time = 0
        booster.levelrush_chips = 0
    else
        booster.levelrush_chips = GetLevelRushChips(session, booster)
    end

    booster.levelrush_chips = booster.levelrush_chips or 0

    return booster
end


function OnGameSpinPrivate(session, total_amount)
    -- 增加cash
    local booster = GetBoosterInfo(session)

    if booster.cashback_end_time < os.time() then
        return
    end

    local rate = tonumber(booster.cashback_rate)
    local increase_chips = math.floor(total_amount * rate)

    local task = Task:Current()
    task.create_time = os.time()

    -- 更新cashback
    local key = string.format("HINCRBY cashback_players %s %s", session.player.id, increase_chips)
    local async_request = {[1] = key}
    LuaSession:ContactJson("CacheClientService", task, async_request, 0)

    LOG(RUN, INFO).Format("[BoosterCal] OnGameSpinPrivate %s cashback chips %s", session.player.id, booster.cashback_chips)

    SaveBoosterInfo(session)
end

function GetLevelRushMultiple(session)
    local booster = GetBoosterInfo(session) 

    if not booster then
        return 1
    end

    if os.time() > booster.levelrush_end_time then
        return 1
    end

    local level = session.player.character.level

    local config = CommonCal.Calculate.get_config(session.player, "LevelRushConfig")[1]
    local multiple = 1

    if level % config.special_level_interval == 0 then
        multiple = config.special_level_multiplier
    else
        multiple = config.normal_coin_multiplier
    end

    return multiple
end

function GetLevelRushChips(session, booster) 
    if not booster then
        return 
    end

    local level = session.player.character.level

    local level_up_chip = Player:CalcLevelUpAddChip(level+1)
    local config = CommonCal.Calculate.get_config(session.player, "LevelRushConfig")[1]
    local multiple = 1

    if level % config.special_level_interval == 0 then
        multiple = config.special_level_multiplier
    else
        multiple = config.normal_coin_multiplier
    end

    return level_up_chip * multiple
end

function AddBuff(session, config_id, is_double)
    local config = CommonCal.Calculate.get_config(session.player, "ShopBoosterTypeConfig")[config_id]
    
    local booster = GetBoosterInfo(session)

    local multiple = is_double and 2 or 1
    
    if config.booster_type == 1 then
        -- cash back
        if booster.cashback_end_time > 0 then
            booster.cashback_end_time = booster.cashback_end_time + config.booster_time * multiple
        else
            booster.cashback_end_time = os.time() + config.booster_time * multiple
        end
        booster.cashback_rate = config.booster_parameter
    elseif config.booster_type == 2 then
        -- level rush
        if booster.levelrush_end_time > 0 then
            booster.levelrush_end_time = booster.levelrush_end_time + config.booster_time * multiple
        else
            booster.levelrush_end_time = os.time() + config.booster_time * multiple
        end
        booster.levelrush_chips = GetLevelRushChips(session, booster)
    end

    SaveBoosterInfo(session)
end

function OnPurchasePrivate(session, player, goods_id, goods_conf)
    local config = CommonCal.Calculate.get_config(player, "ShopItemBoosterConfig")[goods_id]

    if not config then
        return
    end

    local booster = GetBoosterInfo(session)

    -- 是否是bundle
    local is_double = false
    if config.booster_bundle_id == 1 and booster.bundle_double_count == 0 then
        is_double = true
        booster.bundle_double_count = booster.bundle_double_count + 1
        SaveBoosterInfo(session)
    end

    for i=1, #config.booster_ID do
        if config.booster_ID[i] > 0 then
            AddBuff(session, config.booster_ID[i], is_double)
        end
    end

end

function OnPurchase(session, player, goods_id, goods_conf)
    local success, error = pcall(OnPurchasePrivate, session, player, goods_id, goods_conf)

    if not success then
        LOG(RUN, INFO).Format("[BoosterCal] OnPurchase error %s", error)
    end
end

function OnGameSpin(session, total_amount)
    local success, error = pcall(OnGameSpinPrivate, session, total_amount)

    if not success then
        LOG(RUN, INFO).Format("[BoosterCal] OnGameSpin error %s", error)
    end
end

function SendCashbackMail(player_id, chips)
    local packet = {
        header = {
            router = "LocalRequest",
            service_name = "BackstageService",
            module_id = "Mail",
            message_id = "Mail_BoosterCashback_Request"
        },
        player_id = player_id,
        chips = chips
    }

    LuaSession:WriteRouterPacket(packet)
end

function ProcessCashbackMail()
    LOG(RUN, INFO).Format("[BoosterCal] ProcessCashbackMail")
    -- 获取所有的用户
    local task = Task:Current()
    task.create_time = os.time()

    local async_request = {[1] = string.format("hgetall cashback_players")}
    local players = LuaSession:ContactJson("CacheClientService", task, async_request, 0)

    if players[1] == "" then
        return
    end
    
    for i=1, #players, 2 do
        local player_id = tonumber(players[i])
        local chips = tonumber(players[i+1])
        SendCashbackMail(player_id, chips)

        local task = Task:Current()
        task.create_time = os.time()
        async_request = {[1] = string.format("hdel cashback_players %s", player_id)}
        LuaSession:ContactJson("CacheClientService", task, async_request, 0)

        LOG(RUN, INFO).Format("[BoosterCal] ProcessCashbackMail %s chip %s", player_id, chips)
    end
end

local booster_update_time = os.time()

function OnScheduleUpdatePrivate()
    if os.time() - booster_update_time < 60 then
        return
    end

    LOG(RUN, INFO).Format("[BoosterCal] OnScheduleUpdate check %s %s", booster_update_time, os.same_day(booster_update_time, os.time()))

    if not os.same_day(booster_update_time, os.time()) then
        booster_update_time = os.time()
        pcall(ProcessCashbackMail)
    else
        booster_update_time = os.time()
    end

end

function OnScheduleUpdate()
    local success, error = pcall(OnScheduleUpdatePrivate, session, total_amount)

    if not success then
        LOG(RUN, INFO).Format("[BoosterCal] OnScheduleUpdate error %s", error)
    end
end

