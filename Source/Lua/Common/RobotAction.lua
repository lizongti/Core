require "Config/ServerConfig"
require "Common/RobotManager"
module("RobotAction", package.seeall)
BigWinAction = function(session, task)
    if (session.player.character.player_type ~= tonumber(ConstValue[5].value)) then
        return
    end

end
