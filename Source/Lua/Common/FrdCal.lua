--------------
--  LineNum  --
--------------
require "Base/Path"
module("FrdCal", package.seeall)

Calculate = {
	Friend2Player = function (friend_brif)
		local player = {
			id = friend_brif.player_id,
			user = {
				sex = friend_brif.sex,
				avatar = friend_brif.avatar,
				nickname = friend_brif.nickname,
			},
			account = {
				google_id  = friend_brif.google_id,
				facebook_id = friend_brif.facebook_id,
		
			},
			character = {
				level = friend_brif.level,
			}
		}
		return player
	end,

	Player2FrdDetail = function (player)
		local FrdDetail = {
			id = player.id,
			game_type = player.game_type,
			user = player.user,
			account = player.account,
			character = player.character,
			record = {
				total_spin = player.record.total_spin,
				spin_won = player.record.spin_won,
				total_win = player.record.total_win,
				biggest_win = player.record.biggest_win,
				bonus_game = player.record.bonus_game,
				free_spin = player.record.free_spin,
			},
		}
		
		return FrdDetail
	end,

	Player2FrdBrief = function (player)
		local FrdBrief = {
			player_id = player.id,
			sex = player.user.sex,
			avatar = player.user.avatar,
			nickname = player.user.nickname,
			google_id  = player.account.google_id,
			facebook_id = player.account.facebook_id,
			level = player.character.level,
		}
		return FrdBrief
	end,

	UpdateFriendBrief = function(player)
		if (player.character.player_type == tonumber(ConstValue[5].value)) then
			return
		end

		local player_id = player.id
		local task = Task:Current()
		local friend_brif = Calculate.Player2FrdBrief(player)
		friend_brif.nickname = string.encode(friend_brif.nickname)
		
		local json_str = json.encode(friend_brif)

		local async_request = {
 			string.format("update slots.friend_brief_%s set json_str = \'%s\' where player_id = %s", math.mod(player_id, 16), json_str, player_id)
		}
		-- LOG(RUN, INFO).Format("[UpdateFriendBrief] update slots.friend_brief player %s, async_request is:%s", player_id, Table2Str(async_request))
		local async_response = LuaSession:ContactJson("DatabaseClientService", task, async_request, player_id)
		LOG(RUN, INFO).Format("[UpdateFriendBrief] update slots.friend_brief success player %s", player_id)
		local redis_request = {
			[1] = string.format("HMSET friend friend[%s] %s", player_id, json_str),
		}

		LOG(RUN, INFO).Format("[UpdateFriendBrief] HMSET friend friend player %s", player_id)
		local redis_response = LuaSession:ContactJson("CacheClientService", task, redis_request, player_id)
		LOG(RUN, INFO).Format("[UpdateFriendBrief] HMSET friend success friend player %s", player_id)
	end,

	InsertFriendBrief = function(player)
		
		if (player.character.player_type == tonumber(ConstValue[5].value)) then
			return
		end
		local player_id = player.id

		local friend_brief = Calculate.Player2FrdBrief(player)
		local task = Task:Current()
		friend_brif.nickname = string.encode(friend_brif.nickname)
		json_str = json.encode(friend_brief)
		LOG(RUN, INFO).Format("[InsertFriendBrief] player %s, json_str is: %s", player_id, json_str)
		--是否已经存在好友信息表中
		local async_request = {string.format("select * from slots.friend_brief_%s where player_id = %s", math.mod(player_id, 16), player_id)}
		LOG(RUN, INFO).Format("[InsertFriendBrief] select friend_brief player %s", player_id)
		local async_response = LuaSession:ContactJson("DatabaseClientService", task, async_request, player_id)
		LOG(RUN, INFO).Format("[InsertFriendBrief] select friend_brief success player %s", player_id)
		if async_response[1].row_num <= 0 then
			async_request = {string.format("insert into slots.friend_brief_%s(player_id, json_str) values(%s, \'%s\')", math.mod(player_id, 16), player_id, json_str)}
			-- LOG(RUN, INFO).Format("[InsertFriendBrief] insert  friend_brief player %s, async_request is:%s", player_id, Table2Str(async_request))
			local async_response = LuaSession:ContactJson("DatabaseClientService", task, async_request, player_id)
			LOG(RUN, INFO).Format("[InsertFriendBrief] insert success friend_brief player %s", player_id)
			if async_response[1].row_num < 0 then
				LOG(RUN, INFO).Format("[InsertFriendBrief] select friend_brief player %s return error", player_id)
				--return Return.ACCOUNT_DATABASE_ERROR()			
			end
		end
		LOG(RUN, INFO).Format("[InsertFriendBrief] select friend_brief player %s return ok", player_id)
		--return Return.OK()
	end,

	GetFriendInfo = function(fid)
		local task = Task:Current()
		local redis_request = {
            [1] = string.format("HGET friend friend[%s]", fid),
		}
		LOG(RUN, INFO).Format("[GetFriendInfo] HGET friend player %s", fid)
		local redis_response = LuaSession:ContactJson("CacheClientService", task, redis_request, fid)
		LOG(RUN, INFO).Format("[GetFriendInfo] HGET friend success player %s", fid)
        if (not redis_response[1] or #redis_response[1] == 0)
        then
            local async_request = {string.format("select json_str from slots.friend_brief_%s where player_id = %s", math.mod(fid, 16), fid)}
			LOG(RUN, INFO).Format("[GetFriendInfo] select friend_brief DatabaseClientService player %s", fid)
			local async_response = LuaSession:ContactJson("DatabaseClientService", task, async_request, fid)
			LOG(RUN, INFO).Format("[GetFriendInfo] select friend_brief DatabaseClientService success player %s", fid)
            if async_response[1].row_num > 0 then
                local json_str = async_response[1].data_set[1][1]
				local friend_brif = json.decode(json_str)
				friend_brif.nickname = string.encode(friend_brif.nickname)
				local player = FrdCal.Calculate.Friend2Player(friend_brif)

                json_str = json.encode(friend_brif)
                local redis_request = {
                    [1] = string.format("HMSET friend friend[%s] %s", fid, json_str),
                }

				LOG(RUN, INFO).Format("[GetFriendInfo] HMSET friend player %s", fid)
				local redis_response = LuaSession:ContactJson("CacheClientService", task, redis_request, fid)
				LOG(RUN, INFO).Format("[GetFriendInfo] HMSET friend success player %s", fid)
				
				return player
			end
        else
            local json_str = redis_response[1]
			local friend_brif = json.decode(json_str)
			friend_brif.nickname = string.encode(friend_brif.nickname)
            local player = FrdCal.Calculate.Friend2Player(friend_brif)
            return player
		end
		return nil
	end,
}