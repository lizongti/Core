module("Booster", package.seeall)

-- 获取cash back信息
GetCashbackInfo = function(_M, session, request)
    local player = session.player

    local booster = BoosterCal.GetBoosterInfo(session)

    if not booster then
        return
    end

    local left_time = booster.cashback_end_time - os.time()

    if left_time < 0 then
        left_time = 0
    end

    local response = {
        header = {router = "Response"},
        ret = Return.OK(),
        cashback_left_time = left_time,
        cashback_chips = booster.cashback_chips,
        cashback_rate = booster.cashback_rate
    }

    return response
end

-- 获取cash back信息
GetLevelRushInfo = function(_M, session, request)
    local player = session.player

    local booster = BoosterCal.GetBoosterInfo(session)

    if not booster then
        return
    end

    local left_time = booster.levelrush_end_time - os.time()

    if left_time < 0 then
        left_time = 0
    end

    local response = {
        header = {router = "Response"},
        ret = Return.OK(),
        levelrush_left_time = left_time,
        levelrush_chips = booster.levelrush_chips,
    }

    return response
end

GetBoosterBundleInfo = function(_M, session, request)
    local player = session.player

    local booster = BoosterCal.GetBoosterInfo(session)

    if not booster then
        return
    end

    local can_first_buy = 1
    if booster.bundle_double_count > 0 then
        can_first_buy = 0
    end

    local response = {
        header = {router = "Response"},
        ret = Return.OK(),
        can_first_buy = can_first_buy,
    }

    return response
end
