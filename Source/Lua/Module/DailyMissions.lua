require "Base/TableDefine"
require "Base/CacheDefine"
require "Common/CommonCal"
require "Common/DailyMissionsCal"
require "Common/DailyMissionsState"
module("DailyMissions", package.seeall)

ConType = {

}

RefreshDailyMessions = function(_M, session, request, force_refresh)
    local task = Task:Current()
    local week_status = DailyMissionsState:WeekPeriodStatus(session, task)
	local daily_status = DailyMissionsState:DailyPeriodStatus(session, task)
	
	if force_refresh then
		daily_status = 1
	end

    if (daily_status == 1) then
        -------------刷新每日任务
        DailyMissionsState:RefreshDailyMissions(session, task)
    elseif (daily_status == 2) then
		----需要从缓存中取出
        DailyMissionsState:LoadDailyMissions(session, task)
    end

    if (week_status == 1) then
        DailyMissionsState:RefreshWeekTime(session, task)
    end
end

FinalCollect = function (_M, session, request)
	local response = {header = {router = "Response"}}
	local task = session.task
	local player = session.player

	local old_chip = player.character.chip

	local reward_type = request.reward_type--- 1:任务一的奖励 2:任务二的奖励 3:任务三的奖励  51:进度奖励1的奖励  52:进度奖励2的奖励

	local json_value = json.decode(player.task_info.daily_missions)

	local ret, chips, mission_points = DailyMissionsCal.Calculate.GetDailyMissionsAward(player, reward_type, json_value)
	if (chips ~= nil) then

		LOG(RUN, INFO).Format("[DailyMissions][Collect] chips is:%s", chips)
		if (request.has_ad and request.has_ad == 1) then
			chips = chips * tonumber(ConstValue[25].value)
			LOG(RUN, INFO).Format("[DailyMissions][Collect] change chips is:%s", chips)
		end
		
		Player:Obtain(player, {"Chip", chips}, Reason.DAILY_MISSIONS_CHIP_OBTAIN())
	end

	if (reward_type <= 50) then
		if (json_value.mission_points < DailyMissionsProgressConfig[1].progressone_points) then
			if (json_value.progressone_chips == nil) then
				json_value.progressone_chips = 0
			end
			json_value.progressone_chips = json_value.progressone_chips + chips
		elseif (json_value.mission_points < DailyMissionsProgressConfig[1].progresstwo_points) then
			if (json_value.progresstwo_chips == nil) then
				json_value.progresstwo_chips = 0
			end
			json_value.progresstwo_chips = json_value.progresstwo_chips + chips
		end
	elseif (reward_type == 51) then
		FeverCardCal.OnDailyMission(session, player, 1)
		json_value.progressone_chips = 0
	elseif (reward_type == 52) then
		FeverCardCal.OnDailyMission(session, player, 2)
		json_value.progresstwo_chips = 0
	end
	json_value.mission_points = json_value.mission_points + mission_points

	player.task_info.daily_missions = json.encode(json_value)

	response.ret = ret
	response.chips = chips
	response.mission_points = mission_points
	--LOG(RUN, INFO).Format("[DailyMissions][FinalCollect] response: %s", Table2Str(response))

    session:WriteRouterPacket({
        header = {
            router = "SpecificNotice",
            session_id = session.id,
            player_id = player.id,
            module_id = "Command",
            message_id = "Command_Player_Notice",
        },
        player = {
            character = {
                chip = player.character.chip,
            },
		},
		collect_chip = player.character.chip - old_chip
	})
	
	return response
end

Collect = function (_M, session, request)
	local response = {header = {router = "Response"}}
	local task = session.task
	local player = session.player

	local reward_type = request.reward_type--- 1:任务一的奖励 2:任务二的奖励 3:任务三的奖励  51:进度奖励1的奖励  52:进度奖励2的奖励

	local json_value = json.decode(player.task_info.daily_missions)

	local ret, chips, mission_points = DailyMissionsCal.Calculate.GetDailyMissionsAward(player, reward_type, json_value)


	
	response.ret = ret
	response.chips = chips
	response.mission_points = mission_points
	response.reward_type = reward_type
	--LOG(RUN, INFO).Format("[DailyMissions][Collect] response: %s", Table2Str(response))

	return response
end

local LoadDailyMissions = function(session, task)
	local redis_request = {
		[1] = string.format("HGET daily_missions daily_missions_info"),
		[2] = string.format("HGET daily_missions daily_refresh_time"),
		[3] = string.format("HGET daily_missions week_refresh_time"),
	}
	local redis_response = session:ContactJson("CacheClientService", task, redis_request, 0)
	local daily_missions_info = json.decode(redis_response[1])
	local daily_refresh_time = tonumber(redis_response[2])
	local week_refresh_time = tonumber(redis_response[3])
	return daily_missions_info, daily_refresh_time, week_refresh_time
end

---返回任务信息
Info = function ( _M, session, request )
	local response = {header = {router = "Response"}}
	local task = session.task
	local player = session.player

	if (player == nil) then
		
		response.ret = Return.PLAYER_NOT_FOUND()
		return response
	end

	if (DailyMissionsCal.Calculate.IsLocked(player)) then
		response.ret = Return.CLIMB_SLIDE_IS_LOCK_FOR_YOU()
		return response
	end

	local json_value = json.decode(player.task_info.daily_missions)

	local daily_missions_info, daily_refresh_time, week_refresh_time = LoadDailyMissions(session, task)
	--LOG(RUN, INFO).Format("[DailyMissions][Info] daily_missions_info is:%s, daily_refresh_time is: %s, week_refresh_time is:%s", Table2Str(daily_missions_info), daily_refresh_time, week_refresh_time)
	--LOG(RUN, INFO).Format("[DailyMissions][Info] json_value is:%s", Table2Str(json_value))
	local content = {}
	if (json_value.daily_refresh_time == nil or daily_refresh_time ~= json_value.daily_refresh_time) then
		content.daily_status = 1----0不刷新,1刷新，2服务器重启了，需要从缓存中取出
	end

	if (json_value.week_refresh_time == nil or week_refresh_time ~= json_value.week_refresh_time) then
		content.week_status = 1
	end
	
	content.daily_missions = daily_missions_info
	content.daily_refresh_time = daily_refresh_time
	content.week_refresh_time = week_refresh_time

	--LOG(RUN, INFO).Format("[DailyMissions][Info] content is:%s", Table2Str(content))
	DailyMissionsCal.Calculate.Refresh(player, json_value, content)

	--LOG(RUN, INFO).Format("[DailyMissions][Info] json_value222 is:%s", Table2Str(json_value))
	local cur_time = os.time()

	local res_content = DailyMissionsCal.Calculate.GetDailyMissionsInfo(json_value, player.character.level)

	local finished_num = DailyMissionsCal.Calculate.GetFinishedNum(res_content)
	
	response.ret = Return.OK()
	response.daily_missions_info = {
		mission_points = res_content.mission_points,
		total_mission_points = res_content.total_mission_points,
		left_days = res_content.left_days,
		gift_box_status = res_content.gift_box_status,
		big_treasure_box_status = res_content.big_treasure_box_status,
		left_mission_times = res_content.left_mission_times,
		missions = json.encode(res_content.missions),
	}
	response.finished_num = finished_num

	player.task_info.daily_missions = json.encode(json_value)
	
	--LOG(RUN, INFO).Format("[DailyMissions][Info] playerid:%s response: %s", player.id, Table2Str(response))
	return response
end