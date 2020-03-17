require "Common/CommonCal"
module("SlotsTest", package.seeall)

Init = function(_M, session, request)
    local response = {
        header = {
            router = "AsyncResponse",
            client_id = session.client_id,
            task_id = request.header.task_id
        }
    }

    local local_player_id = request.player_id
    local task = Task:Current()

    if (Base.Enviroment.pro_spec_t ~= "online") then
        GlobalSlotsTest[local_player_id] = nil

        local key = "SlotsTest" .. "[" .. local_player_id .. "]"
        local redis_request = {
            [1] = string.format("HGET %s value", key),
            [2] = string.format("HGET %s auto_value1", key),
            [3] = string.format("HGET %s auto_value2", key),
            [4] = string.format("HGET %s auto_value3", key),
            [5] = string.format("HGET %s auto_value4", key),
            [6] = string.format("HGET %s auto_value5", key),
            [7] = string.format("HGET %s auto_value6", key),
            [8] = string.format("HGET %s auto_value7", key),
            [9] = string.format("HGET %s auto_value8", key),
            [10] = string.format("HGET %s flag", key),
            [11] = string.format("HGET %s bonus", key)
        }

        local redis_response = LuaSession:ContactJson("CacheClientService", task, redis_request, 0)

        local result = redis_response[1]
        local autoResult1 = redis_response[2]
        local autoResult2 = redis_response[3]
        local autoResult3 = redis_response[4]
        local autoResult4 = redis_response[5]
        local autoResult5 = redis_response[6]
        local autoResult6 = redis_response[7]
        local autoResult7 = redis_response[8]
        local autoResult8 = redis_response[9]
        local flag = tonumber(redis_response[10])
        local bonus = redis_response[11]

        if (string.len(result) > 15) then
            LOG(RUN, INFO).Format("[SlotsTest] init test")
            GlobalSlotsTest[local_player_id] = {}
            GlobalSlotsTest[local_player_id].result = nil
            GlobalSlotsTest[local_player_id].loopNum = 0
            GlobalSlotsTest[local_player_id].result = json.decode(result)
            GlobalSlotsTest[local_player_id].autoResult1 = json.decode(autoResult1)
            GlobalSlotsTest[local_player_id].autoResult2 = json.decode(autoResult2)
            GlobalSlotsTest[local_player_id].autoResult3 = json.decode(autoResult3)
            GlobalSlotsTest[local_player_id].autoResult4 = json.decode(autoResult4)
            GlobalSlotsTest[local_player_id].autoResult5 = json.decode(autoResult5)
            GlobalSlotsTest[local_player_id].autoResult6 = json.decode(autoResult6)
            GlobalSlotsTest[local_player_id].autoResult7 = json.decode(autoResult7)
            GlobalSlotsTest[local_player_id].autoResult8 = json.decode(autoResult8)

            if (string.len(bonus) > 2) then
                LOG(RUN, INFO).Format("[SlotsTest] bonus is: %s", bonus)
                GlobalSlotsTest[local_player_id].bonus = json.decode(bonus)
            end

            GlobalSlotsTest[local_player_id].flag = flag
        end
    end
    response.ret = Return.OK()
    return response
end
