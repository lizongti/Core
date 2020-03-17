module("Friend", package.seeall)

Get = function ( _M, session, request )
	local response = {
		header = {
			router = "AsyncResponse", 
			client_id = session.client_id, 
			task_id = request.header.task_id
		}
	}

	
	local fid = request.fid
	local task = Task:Current()
	local redis_request = {
		[1] = string.format("HGET friend friend[%s]", fid),
	}
	local redis_response = LuaSession:ContactJson("CacheClientService", task, redis_request, fid)
	if (not redis_response[1] or #redis_response[1] == 0)
	then
		local async_request = {string.format("select json_str from slots.friend_brief_%s where player_id = %s", math.mod(fid, 16), fid)}
		--LOG(RUN, INFO).Format("[Friend][Get] select friend_brief player id is:%s", fid)
		local async_response = LuaSession:ContactJson("DatabaseClientService", task, async_request, fid)
		if async_response[1].row_num > 0 then
			local json_str = async_response[1].data_set[1][1]
			--LOG(RUN, INFO).Format("[Friend][Get] HMSET friend friend player id is:%s, from dababase is:%s", fid, Table2Str(async_response))
			local friend_brif = json.decode(json_str)
			local player = FrdCal.Calculate.Friend2Player(friend_brif)
			friend_brif.nickname = string.encode(friend_brif.nickname)
			json_str = json.encode(friend_brif)
			local redis_request = {
				[1] = string.format("HMSET friend friend[%s] %s", fid, json_str),
			}
			local redis_response = LuaSession:ContactJson("CacheClientService", task, redis_request, fid)
			response.player = player
		end
	else
		local json_str = redis_response[1]
		local friend_brif = json.decode(json_str)
		friend_brif.nickname = string.encode(friend_brif.nickname)
		local player = FrdCal.Calculate.Friend2Player(friend_brif)
		response.player = player
	end
	
	response.ret = Return.OK()
	return response
end

PushAddFriendNotice = function(_M, session, request) -- is a command from manager
	local player_session = PlayerSession:Get(request.session_id)
	local player = player_session.player
	local player_id = request.player_id

	if not player or player.id ~= player_id then
		return
	end

    player_session:WriteRouterPacket({
        header = {
            router = "SpecificNotice",
            session_id = player_session.id,
            player_id = player_id,
            module_id = "Command",
            message_id = "Command_AddFriend_Notice",
        },
        player = {
            id = player_id,
        }
    })
end

