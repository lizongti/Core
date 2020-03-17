--------------
--  LineNum  --
--------------
module("ActivityCal", package.seeall)

Calculate = {
	GetActivityInfo = function(session, activity_type)
		local player_id = session.player.id
		if (session.activity_info == nil) then
			session.activity_info = {}
		end

		if (session.is_monitor ~= nil) then

			session.activity_info[activity_type] = {}
			return session.activity_info[activity_type]
		end
		-- LOG(RUN, INFO).Format("[GetActivityInfo]activity_type is: %s", activity_type)
		-- LOG(RUN, INFO).Format("[GetActivityInfo]activity_info is: %s", Table2Str(session.activity_info))
		if (session.activity_info[activity_type] ~= nil) then
			return session.activity_info[activity_type]
		end

		local expire_time = os.time() + 300

		local redis_request = {
			[1] = string.format("HGET activity[%s][%s] content", player_id, activity_type),
			[2] = string.format("HMSET activity[%s] %s %s", player_id, activity_type, expire_time),
		}
		local redis_response = LuaSession:ContactJson("CacheClientService", Task:Current(), redis_request, player_id)
        if (not redis_response[1] or redis_response[1] == "")
		then
			session.activity_info[activity_type] = {}
			local redis_request = {}
			table.insert(redis_request, string.format("HMSET activity[%s][%s] content []", player_id, activity_type))
			table.insert(redis_request, string.format("HMSET activity[%s] %s %s", player_id, activity_type, expire_time))

			local redis_response = LuaSession:ContactJson("CacheClientService", Task:Current(), redis_request, player_id)
		else
			session.activity_info[activity_type] = json.decode(redis_response[1])
		end
		return session.activity_info[activity_type]
	end,

	UpdateActivityInfo = function(session, activity_type)
		local player_id = session.player.id
		local expire_time = os.time() + 300
		local redis_request = {}
		local json_str = json.encode(session.activity_info[activity_type])
		table.insert(redis_request, string.format("HMSET activity[%s][%s] content %s", player_id, activity_type, json_str))
		table.insert(redis_request, string.format("HMSET activity[%s] %s %s", player_id, activity_type, expire_time))

		local redis_response = LuaSession:ContactJson("CacheClientService", Task:Current(), redis_request, player_id)
	end,

	CountDown = function(activity_type)
		local content = {}
		----计算倒计时
		LOG(RUN, INFO).Format("CountDown %s", activity_type)
		local start_date = string.split(ActivityDataConfig[activity_type].start_time, ":")
		local end_date = string.split(ActivityDataConfig[activity_type].end_time, ":")

		local start_time = os.time({year = start_date[1], month = start_date[2], day = start_date[3], hour = start_date[4], min = start_date[5], sec = start_date[6]})
		local end_time = os.time({year = end_date[1], month = end_date[2], day = end_date[3], hour = end_date[4], min = end_date[5], sec = end_date[6]})

		local cur_time = os.time()

		local distance_start_time = start_time - cur_time
		if (distance_start_time < 0) then
			distance_start_time = 0
		end

		local distance_end_time = end_time - cur_time
		if (distance_end_time < 0) then
			distance_end_time = 0
		end	

		content.distance_start_time = distance_start_time
		content.distance_end_time = distance_end_time
		content.start_time = start_time
		content.end_time = end_time

		return content
	end,
}