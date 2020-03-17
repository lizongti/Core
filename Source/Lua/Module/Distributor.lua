-------------------
--  Distributor --
-------------------
require "Common/Return"
require "Util/StringExt"
require "Common/CommonCal"
require "Config/system/ConstValue"

module("Distributor", package.seeall)

GlobalOnlineTime = 0

Update = function ( _M, session )
	local current_time = os.time()
	if (math.mod(current_time, 60) == 0 and current_time - GlobalOnlineTime >= 60)
	then
		GlobalOnlineTime = current_time
        local prefix = (Base.Enviroment.pro_spec_t == "temporay") and "temporay" or "formal"

		local player_num_info = {}
		local player_number = 0
		for _, v in pairs(DistributorContainer.players) do
			if (v.player_type ~= tonumber(ConstValue[5].value)) then
				for sub_k, sub_v in pairs(v.channels) do
					if (string.find(sub_k, "Contest")) then
						local contest_id, room_id, table_id = unpack(string.split(sub_v, "."))

						local key = contest_id..room_id

						if (player_num_info[key] == nil) then
							player_num_info[key] = 1
						else
							player_num_info[key] = player_num_info[key] + 1
						end

					end
				end
				player_number = player_number + 1
			end
		end
		local player_num_str = json.encode(player_num_info)
		

		
		Spark:Statistics(player, {
			[1] = player_num_str,
			[2] = prefix,
		})

	end


end

Notify = function(_M, session, request)
	local module_id = request.module_id
	local message_id = request.message_id
	local channel_id = request.header.channel_id
	DistributorContainer.channels[channel_id] = DistributorContainer.channels[channel_id] or {}
	return DistributorContainer.channels[channel_id]
end

SpecificNotify = function(_M, session, request)
	return DistributorContainer.players[request.header.player_id]
end

Register = function(_M, session, request)
	local response = {
		header = {
			router = "AsyncResponse", 
			client_id = session.client_id, 
			task_id = request.header.task_id
		}
	}

	DistributorContainer.players[request.player_id] = DistributorContainer.players[request.player_id] or {}
	
	local player = DistributorContainer.players[request.player_id]    
	player.client_id = session.client_id
	player.session_id = request.session_id or player.session_id
	player.player_id = request.player_id or player.player_id
	player.channels = player.channels or {}
	player.player_type = request.player_type or 0 ---0为机器人，

	-- drop channels
	if request.drop_channel_id then
		for _, channel_id in ipairs(request.drop_channel_id) do
			local channel_type = string.split(channel_id, ".")[1]
			DistributorContainer.players[request.player_id].channels[channel_type] = nil
			DistributorContainer.channels[channel_id] = DistributorContainer.channels[channel_id] or {}
			DistributorContainer.channels[channel_id][request.player_id] = nil
		end
	end

	-- join channels
	if request.channel_id then
		for _, channel_id in ipairs(request.channel_id) do
			local channel_type = string.split(channel_id, ".")[1]
			if player.channels[channel_type] then
				-- kick old channel
				local old_channel_id = player.channels[channel_type]
				DistributorContainer.channels[old_channel_id] = DistributorContainer.channels[old_channel_id] or {}
				DistributorContainer.channels[old_channel_id][player.player_id] = nil
			end
			player.channels[channel_type] = channel_id

			DistributorContainer.channels[channel_id] = DistributorContainer.channels[channel_id] or {}
			DistributorContainer.channels[channel_id][request.player_id] = DistributorContainer.players[request.player_id]
		end
	end

	response.ret = Return.OK()
	return response
end

Deregister = function(_M, session, request)
	local response = {
		header = {
			router = "AsyncResponse", 
			client_id = session.client_id, 
			task_id = request.header.task_id
		}
	}

	if request.channel_id and #request.channel_id > 0 then
		for _, channel_id in ipairs(request.channel_id) do
			local channel_type = string.split(channel_id, ".")[1]
			DistributorContainer.players[request.player_id].channels[channel_type] = nil
			DistributorContainer.channels[channel_id] = DistributorContainer.channels[channel_id] or {}
			DistributorContainer.channels[channel_id][request.player_id] = nil
		end
	else
		DistributorContainer.players[request.player_id] = nil
		for _, channel in pairs(DistributorContainer.channels) do
			channel[request.player_id] = nil
		end
	end

	response.ret = Return.OK()

	return response
end

DistributorContainer = {
	channels = Container:Get("Distributor.channels"),
	players = Container:Get("Distributor.players"),
}