module("Jackpot", package.seeall)

GetJackpot = function(_M, session, request)
    local response = {header = {router = "Response"}}

    local task = session.task
    local player = session.player

    local jackpots = request.jackpots

    local v = {}
    for i=1,#jackpots do
        local s = jackpots[i]
        if not s.jackpot_type or s.jackpot_type == 0 then
            for j=1, 4 do
                local config = JackpotTypeConfig[j]

                if not config then
                    return
                end

                local key = string.format("Slots.Jackpot.Game%s.Type%s", s.game_type, j)
                
                local t = {
                    game_type = s.game_type,
                    jackpot_type = j,
                    jackpot_value = GlobalState:Get(key) or 0,
                    jackpot_time = os.time(),
                }
                table.insert(v, t)
            end
        else
            local config = JackpotTypeConfig[s.jackpot_type]

            if not config then
                return
            end
    
            local key = string.format("Slots.Jackpot.Game%s.Type%s", s.game_type, s.jackpot_type)
            
            local t = {
                game_type = s.game_type,
                jackpot_type = s.jackpot_type,
                jackpot_value = GlobalState:Get(key) or 0,
                jackpot_time = os.time(),
            }
            table.insert(v, t)
        end
    end

    --返回数据
    response.jackpots = v
    response.ret = Return.OK()
    return response
end



