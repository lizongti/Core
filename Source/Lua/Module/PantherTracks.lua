require "Base/TableDefine"
require "Base/CacheDefine"
require "Common/CommonCal"
require "Common/PantherTracksCal"
module("PantherTracks", package.seeall)

--选择难度
Select = function(_M, session, request)
	local response = {header = {router = "Response"}}
	local task = session.task
	local player = session.player

	if (player == nil) then
		response.ret = Return.PLAYER_NOT_FOUND()
		return response
	end

	LOG(RUN, INFO).Format("[PantherTracks][Select] player:%s, request: %s", player.id, Table2Str(request))

	local difficulty_type = request.difficulty_type

	local json_value = json.decode(player.task_info.panther_tracks)
	----没有初始化
	if (json_value.difficulty_type == nil) then
		PantherTracksCal.Calculate.ResetPantherTracks(json_value, PanthersTracksInfoConfig)
	end

	---已经选择过
	if (json_value.difficulty_type == difficulty_type) then
		response.ret = Return.GAME_PLAYER_CHIP_NOT_ENOUGH()
		return response
	end

	json_value.difficulty_type = difficulty_type

	player.task_info.panther_tracks = json.encode(json_value)

	response.ret = Return.OK()
	response.difficulty_type = difficulty_type

	LOG(RUN, INFO).Format("[PantherTracks][Select] player:%s, response: %s", player.id, Table2Str(response))
	return response
end

---返回任务信息
Info = function (_M, session, request)
	local response = {header = {router = "Response"}}
	local task = session.task
	local player = session.player

	if (player == nil) then
		response.ret = Return.PLAYER_NOT_FOUND()
		return response
	end
	LOG(RUN, INFO).Format("[PantherTracks][Info] player:%s, request: %s", player.id, Table2Str(request))

	local json_value = json.decode(player.task_info.panther_tracks)

	LOG(RUN, INFO).Format("[PantherTracks][Info] player:%s, difficulty_type: %s", player.id, json_value.difficulty_type)

	----信息初始化
	if (json_value.difficulty_type == nil) then
		PantherTracksCal.Calculate.ResetPantherTracks(json_value, PanthersTracksInfoConfig)
	else
		PantherTracksCal.Calculate.InitPantherTracks(json_value, PanthersTracksInfoConfig)
	end

	PantherTracksCal.Calculate.CountDown(player, json_value)

	response.ret = Return.OK()

	response.panther_tracks_info = {
		difficulty_type = json_value.difficulty_type,
		info = json.encode(json_value.info),
		distance_start_time = json_value.distance_start_time,
		distance_end_time = json_value.distance_end_time,
		distance_refresh_time = json_value.distance_refresh_time
	}

	player.task_info.panther_tracks = json.encode(json_value)
	
	LOG(RUN, INFO).Format("[PantherTracks][Info] player:%s, response: %s", player.id, Table2Str(response))
	return response
end