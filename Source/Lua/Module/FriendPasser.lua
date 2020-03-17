------------------------------
--  Customer Service Passer --
------------------------------

module("FriendPasser", package.seeall)

AddFriend = function(_M, session, request)
	local response = {
		header = {
			router = "AsyncResponse", 
			client_id = session.client_id, 
			task_id = request.header.task_id
		}
	}
	local player_id = request.player_id


	local PlayerWatcherContainer = PlayerWatcher.PlayerWatcherContainer
	local player = PlayerWatcherContainer.players[player_id]

	if player then
		session:WriteRouterPacket({
			header = {
				router = "Command",
				client_id = player.client_id,
				module_id = "Friend",
				message_id = "Friend_PushAddFriendNotice_Request",
			},
			player_id = player_id,
			session_id = player.session_id,
		})
	end
	
	response.ret = Return.OK()
	return response
end
