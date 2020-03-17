-----------------------
--  Customer Service --
-----------------------

module("CustomerService", package.seeall)

GetCurrentPage = function(_M, session, request)
	local response = {header = {router = "Response"}}
	if not session or not session.player then
		response.ret = Return.PLAYER_NOT_FOUND()
		return response
	end
	local player = session.player
	local task = session.task

	local async_request = {
		[1] = string.format("select count(1) from slots.feedback where user_id = %s", player.id),
		[2] = string.format("select create_timestamp, id, type, content from slots.feedback where user_id = %s order by id desc limit 10",
				player.id)
	}
	local async_response = session:ContactJson("DatabaseClientService", task, async_request, player.id)
	if async_response[1].row_num < 0 or async_response[2].row_num < 0 then
		response.ret = Return.ACCOUNT_DATABASE_ERROR()			
		return response
	end
	LOG(RUN, INFO).Format("[CustomerService][GetCurrentPage] player %s async_response: %s!", player.id, Table2Str(async_response))

	local row_count = 0
	if (#async_response[1].data_set > 0)
	then
		row_count = async_response[1].data_set[1][1]
	end
	local current_page = row_count / 10
	local current_row = row_count % 10
	LOG(RUN, INFO).Format("[CustomerService][GetCurrentPage] player %s current_page: %s, current_row: %s", player.id, current_page, current_row)
	local reverse_item_list = {}
	local count = 0
	for _, row in pairs(async_response[2].data_set) do
		local timestamp = tonumber(row[1])
		local index = tonumber(row[2])
		local type = tonumber(row[3])
		local content = tostring(row[4])
		table.insert(reverse_item_list, {
			timestamp = timestamp,
			index = index,
			type = type,
			content = content,
		})
		count = count + 1
		if count == current_row then
			break
		end
	end
	local item_list = {}
	for i = #reverse_item_list, 1, -1 do
		table.insert(item_list, reverse_item_list[i])
	end

	response.page = current_page
	response.item = item_list
	response.ret = Return.OK()


	LOG(RUN, INFO).Format("[CustomerService][GetCurrentPage] player %s response: %s!", player.id, Table2Str(response))
	return response
end

DisplayHistory = function(_M, session, request)
	local response = {header = {router = "Response"}}
	if not session or not session.player then
		response.ret = Return.PLAYER_NOT_FOUND()
		return response
	end
	local player = session.player
	local task = session.task
	LOG(RUN, INFO).Format("[CustomerService][GetCurrentPage] player %s request: %s!", player.id, Table2Str(request))
	local page = request.page
	if page < 0 then
		page = 0
	end
	
	local async_request = {string.format("select create_timestamp, id, type, content from slots.feedback where user_id = %s order by id asc limit %s, 10;",
				player.id, page * 10)}
	local async_response = session:ContactJson("DatabaseClientService", task, async_request, player.id)
	if async_response[1].row_num < 0 then
		response.ret = Return.ACCOUNT_DATABASE_ERROR()			
		return response
	end

	local item_list = {}
	for _, row in pairs(async_response[1].data_set) do
		local timestamp = tonumber(row[1])
		local index = tonumber(row[2])
		local type = tonumber(row[3])
		local content = tostring(row[4])
		table.insert(item_list, {
			timestamp = timestamp,
			index = index,
			type = type,
			content = content,
		})
	end

	response.page = page
	response.item = item_list
	response.ret = Return.OK()
	LOG(RUN, INFO).Format("[CustomerService][GetCurrentPage] player %s response: %s!", player.id, Table2Str(response))
	return response
end

CustomerSay = function(_M, session, request)
	local response = {header = {router = "Response"}}
	if not session or not session.player then
		response.ret = Return.PLAYER_NOT_FOUND()
		return response
	end
	local player = session.player
	local task = session.task

	LOG(RUN, INFO).Format("[CustomerService][CustomerSay] player %s request: %s", player.id, Table2Str(request))
	if string.len(request.content) > 500 then
		response.ret = Return.CUSTOMER_SERVICE_OVER_LENGTH()
	end

	local async_request = {
		header = {
			router = "AsyncRequest",
			service_name = "ManagerClientService",
			task_id = task.id,
			module_id = "CustomerServicePasser",
			message_id = "CustomerServicePasser_CustomerSay_Request",
		},
		player = {
			id = player.id,
			 user = {
				sex = player.user.sex,
				nickname = player.user.nickname,
				location = player.user.location,
				age = player.user.age,
				country = player.user.country,
				signature = player.user.signature,
				avatar = player.user.avatar
			},
			client = {
				app_name = player.client.app_name,
				package = player.client.package,
				version = player.client.version,
				channel = player.client.channel,
				eth_ip = player.client.eth_ip,
				ip = player.client.ip,
				mac = player.client.mac,
				device = player.client.device,
				os = player.client.os,
				os_version = player.client.os_version,
				imei_idfa = player.client.imei_idfa,
				device_id = player.client.device_id,
				device_token = player.client.device_token,
			},
		},
		item = {
			timestamp = os.time(),
			content = request.content
		}
	}
	local async_response = session:ContactPacket(task, async_request)
	if async_response.ret.code ~= 0 then
		response.ret = async_response.ret
		return response
	end

	response.ret = Return.OK()
	LOG(RUN, INFO).Format("[CustomerService][CustomerSay] player %s response: %s", player.id, Table2Str(response))
	return response
end

PushNewItem = function(_M, session, request) -- is a command from manager
	local player_session = PlayerSession:Get(request.session_id)
	local player = player_session.player
	local player_id = request.player_id

	if not player or player.id ~= player_id then
		return
	end

	player_session:Work(function()
		player_session:WriteRouterPacket({
			header = {
				router = "SpecificNotice",
				session_id = player_session.id,
				player_id = player.id,
				module_id = "CustomerService",
				message_id = "CustomerService_PushNewItem_Notice",
			},
			item = request.item
		})
	end)
end

QueryUnread = function(_M, session, request)
	local response = {header = {router = "Response"}}
	if not session or not session.player then
		response.ret = Return.PLAYER_NOT_FOUND()
		return response
	end
	local player = session.player
	local task = session.task

	local player_extern = CommonCal.Calculate.get_player_extern(session, task, player)
	local player_json_data = player_extern.save_data
	local cs_max_read = 0
	if player_json_data.cs_max_read then
		cs_max_read = player_json_data.cs_max_read
	end

	local count = 0
	local async_request = {string.format("select count(1) from slots.feedback where user_id = %s and type = 1 and id > %s", player.id, cs_max_read)}

	local async_response = session:ContactJson("DatabaseClientService", task, async_request, player.id)
	if async_response[1] and async_response[1].data_set and #async_response[1].data_set > 0 then
		count = tonumber(async_response[1].data_set[1][1])
	end

	response.count = count
	response.ret = Return.OK()

	return response
end

SetMaxRead = function(_M, session, request)
	local response = {header = {router = "Response"}}
	if not session or not session.player then
		response.ret = Return.PLAYER_NOT_FOUND()
		return response
	end
	LOG(RUN, INFO).Format("[CustomerService][SetMaxRead] player %s request: %s", session.player.id, Table2Str(request))
	local player = session.player
	local task = session.task

	local player_extern = CommonCal.Calculate.get_player_extern(session, task, player)
	local player_json_data = player_extern.save_data
	local cs_max_read = 0
	if player_json_data.cs_max_read then
		cs_max_read = player_json_data.cs_max_read
	end

	if request.cs_max_read > cs_max_read then
		cs_max_read = request.cs_max_read
	end

	player_json_data.cs_max_read = cs_max_read

	CommonCal.Calculate.update_player_extern(session, task, player)

	response.ret = Return.OK()
	LOG(RUN, INFO).Format("[CustomerService][SetMaxRead] player %s response: %s", session.player.id, Table2Str(response))
	return response
end

