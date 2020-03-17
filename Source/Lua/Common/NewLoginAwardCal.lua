module("NewLoginAwardCal", package.seeall)

local DAY_TIME = 3600*24

function GetDay7Chips(login_info)

    return 0
end

function GetMultiByLevel(level)
    for i=#ContinuousLoginLevelConfig,1,-1 do
        if level >= ContinuousLoginLevelConfig[i].level then
            return ContinuousLoginLevelConfig[i].multiple
        end
    end
    return 0
end

function GetNewLoginAward(session)
    if session.player.character.level <= ConstValue.NewLoginAward_LevelLimit then
        return
    end

    local login_info = ActivityCal.Calculate.GetActivityInfo(session, ActivityDefine.AllTypes.NewLoginAward)

    if login_info.is_newbie == nil then
        login_info.is_newbie = 1
    elseif login_info.is_newbie == 1 then
        login_info.is_newbie = 0
    end

    -- 记录上次登录时间
    login_info.last_login_time = login_info.last_login_time or 0

    -- 查看当前状态
    login_info.lock_state = login_info.lock_state or 0

    -- 记录当前天数
    login_info.current_day = login_info.current_day or 1

    -- 如果超过N天
    local day_delta = os.day(os.time()) - os.day(login_info.last_login_time)
    
    -- 不管之前的状态怎样，超过N天后重置到第一天
    if day_delta > ConstValue.NewLoginAward_ReturnDay then
        login_info.lock_start_time = os.time()
        login_info.lock_state = 1
        login_info.current_day = 1
    end

    if day_delta >= 1 and day_delta <= 7 then

    end

    return login_info
end

function SaveNewLoginAward(session)
    ActivityCal.Calculate.UpdateActivityInfo(session, ActivityDefine.AllTypes.NewLoginAward)
end

local function OnPlayerLoginPrivate(session)
    local login_info = GetNewLoginAward(session)

end

function OnPlayerLogin(session)
    local success, error = pcall(OnPlayerLoginPrivate, session)
    
    if not success then
        LOG(RUN, INFO).Format("[NewLoginAwardCal] on player %s login error %s", session.player.id, error)
    end
end

