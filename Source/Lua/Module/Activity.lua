require "Base/Path"
require "Util/TableExt"
require "Util/StringExt"
require"Common/ActivityCal"
module("Activity", package.seeall)

local GetNewerActivityInfo = function(player)
	local ActivityTimeConfig = CommonCal.Calculate.get_config(player, "ActivityTimeConfig")
	local start_time_str = ActivityTimeConfig[2].start_time
	local end_time_str = ActivityTimeConfig[2].end_time

	local start_date = string.split(start_time_str, ":")
	local end_date = string.split(end_time_str, ":")

	local current_time = os.time()

	local dur_days = tonumber(end_date[3]) - tonumber(start_date[3])

	local start_time = player.character.create_time 
	local dur_time = dur_days * 24 * 60 * 60

	local end_time = start_time + dur_time

	local start_date = os.date("*t", start_time)
	local end_date = os.date("*t", end_time)


	local end_date_str = string.format("%s年%s月%s日%s时%s分%s秒", end_date.year, end_date.month, end_date.day, end_date.hour, end_date.min, end_date.sec)

	local start_date_str = string.format("%s年%s月%s日%s时%s分%s秒", start_date.year, start_date.month, start_date.day, start_date.hour, start_date.min, start_date.sec)

	--LOG(RUN, INFO).Format("[Activity][GetNewerActivityInfo] player id is:%s, start_date is:%s, end_date is:%s", player.id, start_date_str, end_date_str)

	if (current_time >= start_time and current_time < end_time)
	then
		return true, start_time, end_time, current_time
	end

	return false, start_time, end_time, current_time
end

Info = function(_M, session, request)
	local task = session.task
	local player = session.player

	local response = {header = {router = "Response"}}

	--LOG(RUN, INFO).Format("[Activity][Info] player id is:%s", player.id)

	response.ret = Return.OK()

	if (player == nil) then
        response.ret = Return.HAVE_ALREADY_EXIT_GAME()
        return response        
    end
	
	local activity_info = {}

	local ActivityTimeConfig = CommonCal.Calculate.get_config(player, "ActivityTimeConfig")
	for id, activity_time_config in ipairs(ActivityTimeConfig) do
		if (activity_time_config.activity_type == "NewerActivity") then
			local res, start_time, end_time, current_time = GetNewerActivityInfo(player)
			if (res) then
				table.insert(activity_info, {type = id, start_time = start_time, end_time = end_time, current_time = current_time, value = 1})
			else
				table.insert(activity_info, {type = id, start_time = start_time, end_time = end_time, current_time = current_time, value = 0})
			end
		else
			local res, start_time, end_time, current_time = CommonCal.Calculate.GetActivityInfo(player, id)
			if (res) then
				table.insert(activity_info, {type = id, start_time = start_time, end_time = end_time, current_time = current_time, value = 1})
			else
				table.insert(activity_info, {type = id, start_time = start_time, end_time = end_time, current_time = current_time, value = 0})
			end			
		end
	end

	response.activity_info = json.encode(activity_info)

    return response
end

Status = function(_M, session, request)
	local task = session.task
	local player = session.player

	local response = {header = {router = "Response"}}

	response.ret = Return.OK()

	if (player == nil) then
        response.ret = Return.HAVE_ALREADY_EXIT_GAME()
        return response        
    end
	
	local activity_type = request.activity_type

	local count_down_info = ActivityCal.Calculate.CountDown(activity_type)

	local status = 1
	if (count_down_info.distance_start_time > 0 or count_down_info.distance_end_time == 0 ) then
		---没有到期或期限已经过期
		status = 0
	end

	response.distance_start_time = count_down_info.distance_start_time
	response.distance_end_time = count_down_info.distance_end_time
	response.stamp_start_time = count_down_info.start_time
	response.stamp_end_time = count_down_info.end_time
	response.status = status
    return response
end