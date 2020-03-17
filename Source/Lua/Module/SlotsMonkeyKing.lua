require "Common/SlotsMonkeyKingCal"
require "Common/RequestFilter"
require "Module/DailyTask"
module("SlotsMonkeyKing", package.seeall)

-----------------------------------------------
-- 进入房间
------------------------------------------------
Enter = function( _M, session, request)
    local response = {header = {router = "Response"}}

    
    return response
end

--开始slots
Start = function (_M, session, request )
	local response = {header = {router = "Response"}}


   
	return response
end

-----------------------------------------------
-- 退出房间
------------------------------------------------
Exit = function (_M, session, request )
	local response = {header = {router = "Response"}}
   
    return response
end
