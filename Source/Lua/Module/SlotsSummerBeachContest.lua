
module("SlotsSummerBeachContest", package.seeall)

Enter = function ( _M, session, request )
    local response = {header = {router = "Response"}}
    
    response.ret = Return.OK()
    return response
end
