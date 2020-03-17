module("BankruptProtect", package.seeall)

Fetch = function ( _M, session, request )
	local response = {header = {router = "Response"}}
	if not session or not session.player then
        response.ret = Return.PLAYER_NOT_FOUND()
        return response
    end

    local player = session.player

    if player.character.chip > BankruptProtectConfig[1].threshold then
    	response.ret = Return.BANKRUPT_PLAYER_CHIP_MORE_THAN_THRESHOLD()
    	return response
    end

    -- if os.time() - player.character.alms_fetch_time < 24 * 3600 then
    if os.same_day(os.time(), player.character.alms_fetch_time) then
    	response.ret = Return.BANKRUPT_NOT_COOL_DOWN()
    	return response
    end

    -- player.character.chip = player.character.chip + BankruptProtectConfig[1].bonus
    Player:Obtain(player, {"Chip", BankruptProtectConfig[1].bonus}, Reason.BANKRUPT_PROTECT_OBTAIN())
    player.character.alms_fetch_time = os.time()

    response.ret = Return.OK()
    response.player = {
    	character = {
    		chip = player.character.chip,
     	}
	}
	return response
end