module("BuyLoss", package.seeall)

local function gen_gear(total_loss)
    local len = #BuyLossConfig
    if total_loss == BuyLossConfig[1].loss_lower_limit then
        return 1
    elseif total_loss > BuyLossConfig[len].loss_lower_limit then
        return len
    else
        for i = 1, len - 1 do
            if total_loss > BuyLossConfig[i].loss_lower_limit and total_loss <= BuyLossConfig[i].loss_higher_limit then
                return i
            end
        end
    end
end

Buy = function(_M, session, request)
    local response = {header = {router = "Response"}}
	if not session or not session.player then
        response.ret = Return.PLAYER_NOT_FOUND()
        return response
    end

    local task = session.task
    
    local player = session.player
    local game_type = request.game_type
    local game_key = GameRoomConfig[game_type].key_name
    local enter_chip = CommonCal.Calculate.get_game_info(session, task, player, game_type).enter_chip
    local leave_chip = player.character.chip
    local gear = gen_gear(enter_chip - leave_chip)
    if not gear then
        response.ret = Return.BUYLOSS_NO_LOSS_TO_BUY()
        return response
    end

    local total_loss = CommonCal.Calculate.get_game_info(session, task, player, game_type).total_loss


    Player:Obtain(player, {"Chip", total_loss}, Reason.BUYLOSS_BUY_OBTAIN())

    response.ret = Return.OK()
    response.player = {
        character = {
            chip = player.character.chip,
        },
    }
    CommonCal.Calculate.get_game_info(session, task, player, game_type).total_loss = 0
    return response
end

Trigger = function(_M, session, task, game_type, player)
    local game_key = GameRoomConfig[game_type].key_name
    local enter_chip = CommonCal.Calculate.get_game_info(session, task, player, game_type).enter_chip
    local leave_chip = player.character.chip
    local spined_times = CommonCal.Calculate.get_game_info(session, task, player, game_type).spined_times

    local trigger_loss_percent = enter_chip > 0 and ((enter_chip - leave_chip) / enter_chip) * 100 >= BuyLossTriggerConfig[1].loss_percent
    local trigger_loss = (enter_chip - leave_chip) >= BuyLossTriggerConfig[1].loss_amount
    -- local trigger_loss_percent = true
    -- local trigger_loss = true
    local trigger_times = spined_times >= BuyLossTriggerConfig[1].bet_times

    if trigger_loss_percent and trigger_loss and trigger_times then
        local gear = gen_gear(enter_chip - leave_chip)
       -- local gear = gen_gear(100000)
        -- print(gear)
        if gear then
            return true, (enter_chip - leave_chip), BuyLossConfig[gear].diamond, BuyLossConfig[gear].goods_id
            -- return true, 100000, BuyLossConfig[gear].diamond
        else
            return false
        end
    else
        return false
    end
end
