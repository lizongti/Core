module("RateUs", package.seeall)

Fetch = function(_M, session, request)
    local response = {header = {router = "Response"}}
	if not session or not session.player then
        response.ret = Return.PLAYER_NOT_FOUND()
        return response
    end

    local player = session.player
    if player.character.rated_us == 1 then
        response.ret = Return.RATEUS_PLAYER_ALREADY_RATED()
        return response
    end
    --这里手写了500000,一个字段,没有导表
    Player:Obtain(player, {"Chip", 500000}, Reason.RATEUS_OBTAIN())

    --标记玩家已经评论过了
    player.character.rated_us = 1

    response.ret = Return.OK()
    response.player = {
        character = {
            chip = player.character.chip,
            rated_us = player.character.rated_us,
        }
    }
    return response
end