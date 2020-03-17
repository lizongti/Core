module("AccountVersionCal", package.seeall)

Calculate = {
	GetAccountVersion = function(session)
		local player_id = session.player.id

		local redis_request = {
			[1] = string.format("HGET accountversion player[%s]", player_id)
		}
		local redis_response = LuaSession:ContactJson("CacheClientService", Task:Current(), redis_request, player_id)
		local account_version = 0
		if (redis_response and redis_response[1] ~= "") then
			account_version = tonumber(redis_response[1])
		end
		return account_version
	end,
	UpdateAccountVersion = function(session, account_version)
		local player_id = session.player.id
		local redis_request = {}

		table.insert(redis_request, string.format("HMSET accountversion player[%s] %s", player_id, account_version))

		local redis_response = LuaSession:ContactJson("CacheClientService", Task:Current(), redis_request, player_id)
	end,
	GetLoginVersion = function(session, player)
		local system_type = "android"

		local os_type = player.client.os
		if (string.find(os_type, "iOS") or string.find(os_type, "Mac")) then
			system_type = "ios"
		else
			system_type = "android"
		end

		local redis_request = {}

		table.insert(redis_request, string.format("GET loginversion_%s_%s", player.client.channel, system_type))

		local redis_response = LuaSession:ContactJson("CacheClientService", Task:Current(), redis_request, player.id)

		return redis_response[1]
	end
}
