require "Common/SlotsGameCal"
require "Common/DailyMissionsCal"
require "Common/RequestFilter"
require "Module/DailyTask"
require "Common/CommonCal"
require "Common/LineNum"
require "Common/RobotAction"
require "Common/GameType"
require "Module/SlotsOldGame"
require "Module/SlotsNewGame"

module("SlotsGame", package.seeall)

-----------------------------------------------
-- 进入房间
------------------------------------------------
Enter = function(_M, session, request)
    local game_type = request.game_type
 
    if (GameType.NewGameTypes[game_type] == nil) then
        return SlotsOldGame.Enter(_M, session, request)
    else
        return SlotsNewGame.Enter(_M, session, request)
    end
end

Bonus = function(_M, session, request)
    local game_type = request.game_type
    if (GameType.NewGameTypes[game_type] == nil) then
        return SlotsOldGame.Bonus(_M, session, request)
    else
        return SlotsNewGame.Bonus(_M, session, request)
    end
end

-- 开始slots
Start = function(_M, session, request)
    local response = {header = {router = "Response"}}

    local filter_ret = RequestFilter.Filter("SlotsGame", "Start", session, request, true)
    if filter_ret then
        response.ret = filter_ret
        return response
    end

    local player = session.player
    local game_type = player.game_type

    if (GameType.NewGameTypes[game_type] == nil) then
        return SlotsOldGame.Start(_M, session, request)
    else
        return SlotsNewGame.Start(_M, session, request)
    end
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
    local game_type = player.game_type
 
    if (GameType.NewGameTypes[game_type] == nil) then
        return SlotsOldGame.Exit(_M, session, request)
    else
        return SlotsNewGame.Exit(_M, session, request)
    end

end
