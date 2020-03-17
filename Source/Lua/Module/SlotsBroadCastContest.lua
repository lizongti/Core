require"Common/CommonCal"

module("SlotsBroadCastContest", package.seeall)

Chip = function ( _M, session, request )
	local player = request.player

	local game_type = player.game_type

	local game_service = GameRoomConfig[game_type].contest_name

	local game_key = GameRoomConfig[game_type].key_name

	local chip = request.chip
	local is_big = request.is_big

	if game_key then
		local notice = {
			header = {
				router = "ContestBroadcast",
				channel_id = player[game_key].channel_id,
				service_name = game_service,
				module_id = "SlotsBroadCastContest",
				message_id = "SlotsBroadCastContest_Chip_Notice",
			},
			chip = chip,
			player = player,
			is_big = is_big,
		}
		session:WriteRouterPacket(notice)
	end

	local response = {
		header = {
			router = "AsyncResponse", 
			client_id = session.client_id, 
			task_id = request.header.task_id,
		},
		ret = Return.OK()
	}
	return response
end

