module("SlotsSummerBeach", package.seeall)


Enter = function( _M, session, request)
    local response = {header = {router = "Response"}}

    response.ret = Return.OK()
    return response, table_sync_notice
end

--开始slots
Start = function (_M, session, request )
    local response = {header = {router = "Response"}}
    

    response.ret = Return.OK()

    return response
end

-----------------------------------------------
-- 退出房间
-----------------------------------------------
Exit = function (_M, session, request )
    local response = {header = {router = "Response"}}
    
    response.ret = Return.OK()
    return response
end