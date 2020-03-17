-----------------------
--   Login Reward   --
-----------------------
require "Base/Path"
require "Util/TableExt"
require "Util/MathExt"
require "Util/OsExt"
require "Common/Return"

module("NewLoginAward", package.seeall)

require "Config/ServerConfig"

CollectDailyAward = function(_M, session, request)
    local response = {header = {router = "Response"}}
    local player = session.player
    local login_info = NewLoginAwardCal.GetNewLoginAward(session)
    
    local current_day =  login_info.current_day
    local config = ContinuousLoginConfig[current_day]
    local add_multi = config.increase_mutiplier
    local base_coins = config.base_coins
    local total_coins = base_coins * (1+NewLoginAwardCal.GetMultiByLevel(player.character.level))

    response = {
        header = {router = "Response"},
        ret = Return.OK(),
        is_return = is_return,
        chips = total_coins,
        day = current_day,
        multiple = add_multi
    }

    return response
end

WeekInfo = function(_M, session, request)
	local response = {header = {router = "Response"}}
    local player = session.player
    
    local login_info = NewLoginAwardCal.GetNewLoginAward(session)
    local day_delta = os.day(os.time()) - os.day(login_info.last_login_time)

    local is_return = 0
    if day_delta > ConstValue.NewLoginAward_ReturnDay then
        is_return = 1
    end

    local day7_chips = NewLoginAwardCal.GetDay7Chips(login_info)
    
    response = {
        header = {router = "Response"},
        ret = Return.OK(),
        is_return = is_return,
        is_start = login_info.is_newbie,
        current_day = login_info.current_day,
        day7_coins = day7_chips,
        week_info = {}
    }
    
	return response
end

DailyWheelInfo = function(_M, session, request)
	local response = {header = {router = "Response"}}
	local player = session.player
	
	return response
end

FeverWheelInfo = function(_M, session, request)
	local response = {header = {router = "Response"}}
	local player = session.player
	
	return response
end