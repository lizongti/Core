module("SlotsForbiddenCityContest", package.seeall)

Enter = function ( _M, session, request )
	local response = {
		header = {
			router = "AsyncResponse", 
			client_id = session.client_id, 
			task_id = request.header.task_id
		}
	}

	local player_id = request.player.id
	local seat = nil
	local game_room_config = GameRoomConfig[GameType.AllTypes.ForbiddenCity]

	SlotsForbiddenCityContainer:Init():NewRoom(game_room_config.room_name)
	
	if (request.player.game_type and request.player.game_type == GameType.AllTypes.ForbiddenCity)
	then
		local designated_channel_id = request.player.forbidden_city.channel_id
		local contest_id, room_id, table_id = unpack(string.split(designated_channel_id, "."))
		table_id = tonumber(table_id)
		local designated_seat = SlotsForbiddenCityContainer:MakeDesignatedSit(SlotsForbiddenCityContainer[game_room_config.room_name], player_id, table_id)
		if (designated_seat == nil)
		then
			response.ret = Return.CLUB_ALREADY_FULL()
			return response
		end
		seat = designated_seat
	else
		seat = SlotsForbiddenCityContainer:MakeSit(SlotsForbiddenCityContainer[game_room_config.room_name], player_id)
	end

	seat.player = request.player
	seat.online = 1
	seat.expire = 0
	
	local channel_id = string.format("%s.%s.%s", "SlotsForbiddenCityContest", seat.table.room.name, seat.table.id)
	response.channel_id = channel_id
	response.table = {
		seat = {}
	}
	for i, seat in pairs(seat.table) do
		table.insert(response.table.seat, {
				id = seat.id,
				player = seat.player,
				online = seat.online,
			})
	end

	response.ret = Return.OK()

	return response
end

-----------------------------------------------
-- 退出房间
------------------------------------------------
Exit = function ( _M, session, request )
	local response = {
		header = {
			router = "AsyncResponse", 
			client_id = session.client_id, 
			task_id = request.header.task_id
		}
	}

	local player_id = request.player_id
	local seat = SlotsForbiddenCityContainer:LocateSeat(player_id)
	if not seat then
		response.ret = Return.GAME_CONTEST_CANNOT_FIND_PLAYER()
		return response
	end

	if not SlotsForbiddenCityContainer:MakeStand(player_id) then
		response.ret = Return.FORBIDDENCITY_CONTEST_NULL_EXIT()
		return response
	end

	local game_room_config = GameRoomConfig[GameType.AllTypes.ForbiddenCity]

	local tab = seat.table
	local channel_id = string.format("%s.%s.%s", "SlotsForbiddenCityContest", seat.table.room.name, seat.table.id)
	--insert players in this table for operative
	response.table = {
		seat = {},
	}
	for i, seat in pairs(tab) do
		table.insert(response.table.seat, {
			id = seat.id,
			player = seat.player,
			online = seat.online,
		})
	end

	response.channel_id = channel_id
	response.ret = Return.OK()

	return response
end

Offline = function ( _M, session, request )
	local response = {
		header = {
			router = "AsyncResponse", 
			client_id = session.client_id, 
			task_id = request.header.task_id
		}
	}

	local player_id = request.player_id

	local seat = SlotsForbiddenCityContainer:LocateSeat(player_id)
	if not seat then
		response.ret = Return.GAME_CONTEST_CANNOT_FIND_PLAYER()
		return response
	end

	if not SlotsForbiddenCityContainer:MakeStand(player_id) then
		response.ret = Return.GAME_CONTEST_NULL_EXIT()
		return response
	end

	local game_room_config = GameRoomConfig[GameType.AllTypes.ForbiddenCity]

	seat.online = 0
	seat.exit = 1
	seat.expire = os.time()

	local channel_id = string.format("%s.%s.%s", "SlotsForbiddenCityContest", seat.table.room.name, seat.table.id)
	
	session:ReadRouterPacket({
		header = {
			router = "Inform",
			service_name = game_room_config.contest_client_name,
			module_id = "Distributor",
			message_id = "Distributor_Deregister_Request",
		},
		player_id = player_id
	})

	response = {
		header = response.header,
		ret = Return.OK()
	}

	return response
end

Hotfix = function(_M, session, request)
	local response = {
		header = {
			router = "AsyncResponse", 
			client_id = session.client_id, 
			task_id = request.header.task_id
		}
	}

    local process_name = request.process_name
    local module_path = request.module_path
    local module_name = request.module_name

    if process_name == "SlotsForbiddenCityContest" then
        for i = 1, #module_name do
			local path = module_path[i]
			local name = module_name[i]
            local full_path = string.format("%s/%s", path, name)
			if package.loaded[full_path] then
				package.loaded[full_path] = nil
				require (full_path)
                LOG(RUN, INFO).Format("[SlotsForbiddenCityContest][Hotfix] successfully hotfixed %s", full_path)
			end
		end
    end
    response.ret = Return.OK()
    return response
end

SlotsForbiddenCityContainer = {
	rooms = Container:Get("SlotsForbiddenCity.rooms"),
	player_seat = Container:Get("SlotsForbiddenCity.player_seat"),
	Init = function(self)
		setmetatable(self, {
			__index = self.rooms
		})
		return self
	end,

	LocateSeat = function(self, player_id)
		return self.player_seat[player_id]
	end,

	NewRoom = function(self, name)
		if (self.rooms[name] ~= nil)
		then
			return self.rooms[name]
		end
		self.rooms[name] = {}
		local new_room = self.rooms[name]
		local meta = {
			free_seats = {},
			name = name,
			max_table = 0,
		}
		meta.meta = meta
		setmetatable(new_room, {
			__index = meta
		})
		return new_room
	end,

	NewTable = function(self, room)
		room.meta.max_table = room.max_table + 1
		local new_table = {}
		local meta = {
			room = room,
			id = room.max_table
		}
		meta.meta = meta
		setmetatable(new_table, {
			__index = meta
		})
		for i = 1, 5, 1 do
			local new_seat = self:NewSeat(new_table, i)
			table.insert(room.free_seats, new_seat)
		end
		table.insert(room, new_table)
		return new_table
	end,
	
	NewSeat = function(self, table, id)
		local new_seat = {}
		local meta = {
			table = table,
			id = id
		}
		meta.meta = meta
		setmetatable(new_seat, {
			__index = meta
		})
		_G.table.insert(table, new_seat)
		return new_seat
	end,

	MakeDesignatedSit = function(self, room, player_id, table_id)
		local seat = self.player_seat[player_id]
		if seat then
			return seat
		end

		for index, seat in pairs(room.free_seats) do
			if (room.free_seats[index].table.id == table_id)
			then
				room.free_seats[index] = nil
				self.player_seat[player_id] = seat
				return seat
			end
		end

		return nil
	end,

	MakeSit = function(self, room, player_id)
		local seat = self.player_seat[player_id]
		if seat then
			return seat
		end

		local min_table_id = 99999
		local sel_index = -1
		for index, seat in pairs(room.free_seats) do
			if (room.free_seats[index].table.id < min_table_id) then
				min_table_id = room.free_seats[index].table.id
				sel_index = index
			end
		end

		if sel_index ~= -1 then
			self.player_seat[player_id] = room.free_seats[sel_index]
			room.free_seats[sel_index] = nil

			seat = self.player_seat[player_id]
			return seat
		end

		self:NewTable(room)
		
		return self:MakeSit(room, player_id)
	end,
	
	MakeStand = function(self, player_id)
		local seat = self.player_seat[player_id]
		if not seat then
			return false
		end
		for k, _ in pairs(seat) do
			seat[k] = nil
		end
		table.insert(seat.table.room.free_seats, seat)
        self.player_seat[player_id] = nil
		return true
	end,
}


