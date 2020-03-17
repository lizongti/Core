------------------------------
--  Customer Service Passer --
------------------------------

module("CustomerServicePasser", package.seeall)

CustomerSay = function(_M, session, request)
	local response = {
		header = {
			router = "AsyncResponse", 
			client_id = session.client_id, 
			task_id = request.header.task_id
		}
	}
	LOG(RUN, INFO).Format("[CustomerServicePasser][CustomerSay] request: %s", json.encode(request))

	local item = request.item
	local player_id = request.player.id
	local data = {
		type = CustomerServiceType.CustomerSay,
		user_id = request.player.id,
		nick = request.player.user.nickname,
		client_ip = request.player.client.ip,
		game = "slots",
		plat = request.player.client.os,
		package = request.player.client.package,
		channel = request.player.client.channel,
		version = request.player.client.version,
		plat_version = request.player.client.os_version,
		mac = request.player.client.mac,
		timestamp = item.timestamp,
		content = item.content,
	}

	LOG(RUN, INFO).Format("[CustomerServicePasser][CustomerSay] WriteQueue: %s", json.encode(data))
	session:WriteQueue("customer_service", json.encode(data))

	local PlayerWatcherContainer = PlayerWatcher.PlayerWatcherContainer
	local player = PlayerWatcherContainer.players[request.player.id]

	if player then
		session:WriteRouterPacket({
			header = {
				router = "Command",
				client_id = player.client_id,
				module_id = "CustomerService",
				message_id = "CustomerService_PushNewItem_Request",
			},
			player_id = player_id,
			session_id = player.session_id,
			item = {
				timestamp = item.timestamp,
				index = 0,
				type = CustomerServiceType.CustomerSay,
				content = item.content,
			},
		})
	end
	
	response.ret = Return.OK()
	LOG(RUN, INFO).Format("[CustomerServicePasser][CustomerSay] response: %s", json.encode(response))
	return response
end

StaffSay = function(_M, session, request)
	local response = {
		header = {
			router = "AsyncResponse", 
			client_id = session.client_id, 
			task_id = request.header.task_id
		}
	}
	LOG(RUN, INFO).Format("[CustomerServicePasser][StaffSay] request: %s", json.encode(request))

	local player_id = request.player_id
	local item = request.item
	
	local PlayerWatcherContainer = PlayerWatcher.PlayerWatcherContainer
	local player = PlayerWatcherContainer.players[request.player_id]

	if player then
		session:WriteRouterPacket({
			header = {
				router = "Command",
				client_id = player.client_id,
				module_id = "CustomerService",
				message_id = "CustomerService_PushNewItem_Request",
			},
			player_id = player_id,
			session_id = player.session_id,
			item = {
				timestamp = item.timestamp,
				index = item.index,
				type = CustomerServiceType.StaffSay,
				content = item.content,
			},
		})
	end

	response.ret = Return.OK()
	LOG(RUN, INFO).Format("[CustomerServicePasser][StaffSay] response: %s", json.encode(response))
	return response
end

CustomerServiceType = {
	CustomerSay = 0,
	StaffSay = 1,
}