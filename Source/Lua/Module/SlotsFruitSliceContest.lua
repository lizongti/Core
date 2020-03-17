module("SlotsFruitSliceContest", package.seeall)
require "Common/SlotsFruitSliceCal"

--进房间
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

	local game_room_config = GameRoomConfig[GameType.AllTypes.FruitSlice]

	SlotsFruitSliceContainer:Init():NewRoom(game_room_config.room_name)
	
	--进入之前的小游戏 TODO
	if (request.player.game_type and request.player.game_type == GameType.AllTypes.FruitSlice) then
		local designated_channel_id = request.player.fruit_slice.channel_id

		local contest_id, room_id, table_id = unpack(string.split(designated_channel_id, "."))

		table_id = tonumber(table_id)

		local designated_seat = SlotsFruitSliceContainer:MakeDesignatedSit(SlotsFruitSliceContainer[game_room_config.room_name], player_id, table_id)

		if (designated_seat == nil) then
			response.ret = Return.CLUB_ALREADY_FULL()
			return response
		end

		seat = designated_seat
	else
		seat = SlotsFruitSliceContainer:MakeSit(SlotsFruitSliceContainer[game_room_config.room_name], player_id)
	end

	seat.player = request.player
	seat.online = 1
	seat.expire = 0
	
	--广播id
	local channel_id = string.format("%s.%s.%s", "SlotsFruitSliceContest", seat.table.room.name, seat.table.id)
	response.channel_id = channel_id

	response.table = {
		seat = {}
	}

    response.bonus = seat.table.bonus

	for i, seat in ipairs(seat.table) do
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
	local seat = SlotsFruitSliceContainer:LocateSeat(player_id)
	if not seat then
		response.ret = Return.GAME_CONTEST_CANNOT_FIND_PLAYER()
		return response
	end

	if not SlotsFruitSliceContainer:MakeStand(player_id) then
		response.ret = Return.FRUITSLICE_CONTEST_NULL_EXIT()
		return response
	end

	local game_room_config = GameRoomConfig[GameType.AllTypes.FruitSlice]

	local tab = seat.table
	local channel_id = string.format("%s.%s.%s", "SlotsFruitSliceContest", seat.table.room.name, seat.table.id)
	--insert players in this table for operative
	response.table = {
		seat = {},
	}
	for i, seat in ipairs(tab) do
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

	local seat = SlotsFruitSliceContainer:LocateSeat(player_id)
	if not seat then
		response.ret = Return.FRUITSLICE_CONTEST_CANNOT_FIND_PLAYER()
		return response
	end

	if not SlotsFruitSliceContainer:MakeStand(player_id) then
		response.ret = Return.FRUITSLICE_CONTEST_NULL_EXIT()
		return response
	end

	local game_room_config = GameRoomConfig[GameType.AllTypes.FruitSlice]

	seat.online = 0
	seat.exit = 1
	seat.expire = os.time()

	local channel_id = string.format("%s.%s.%s", "SlotsFruitSliceContest", seat.table.room.name, seat.table.id)
	
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

    if process_name == "SlotsFruitSliceContest" then
        for i = 1, #module_name do
			local path = module_path[i]
			local name = module_name[i]
            local full_path = string.format("%s/%s", path, name)
			if package.loaded[full_path] then
				package.loaded[full_path] = nil
				require (full_path)
			end
		end
    end
    response.ret = Return.OK()
    return response
end

local function CreateGame(tab, seat)
	return {
		seat=seat, tab=tab, id=seat.id,
		state = MiniGameStates.Rest,
		bonus = 0,
		state_start_time = tonumber(LoggerService:GetTimestamp()),
		player_count = 0,
		last_throw_time = 0,
        last_sliced_time = 0,
	}
end

Start = function ( _M, session, request )
	local response = {
		header = {
			router = "AsyncResponse", 
			client_id = session.client_id, 
			task_id = request.header.task_id
		}
	}

	local player_id = request.player_id
	local seat = SlotsFruitSliceContainer:LocateSeat(player_id)
	
	if not seat then
		response.ret = Return.FRUITSLICE_CONTEST_CANNOT_FIND_PLAYER()
		return response
	end
	
	local tab = seat.table

	if not seat.game then
		seat.game = CreateGame(seat.table, seat)
	end

	local game = seat.game
	game.bonus = game.bonus + 1

    --如果bonus到6了,会额外发一个delay,表示这个玩家触发这个房间的bonusgame,delay标识需要发小游戏prepare的延迟时间
    if request.erase_times then
        tab.erase_times = request.erase_times
	end
	
	--只触发该座位的game
    TableNoticeHelper.BonusIncreaseNotice(seat.game, player_id)

	response.ret = Return.OK()
	return response
end

Slice = function ( _M, session, request )
	local response = {
		header = {
			router = "AsyncResponse", 
			client_id = session.client_id, 
			task_id = request.header.task_id
		}
	}

	local player_id = request.player_id
	local fruit_id = request.fruit_id
	local seat = SlotsFruitSliceContainer:LocateSeat(player_id)

	if not seat then
		response.ret = Return.FRUITSLICE_CONTEST_CANNOT_FIND_PLAYER()
		return response
	end

	local game = seat.game

	--check game state
	if not game or game.state ~= MiniGameStates.Running then
		response.ret = Return.FRUITSLICE_CONTEST_STATE_ERROR()
		return response
	end

    local fruit_count = #fruit_id

    for i = 1, fruit_count do
        local id = fruit_id[i]
		local fruit = FruitControl.GetFruitById(game, id)

		if not fruit then
			response.ret = Return.FRUITSLICE_CONTEST_SLICE_FRUIT_ID_INVALID()
			return response
		end

		if fruit.fruit_type == FruitType.Bomb then
			response.ret = Return.FRUITSLICE_CONTEST_SLICE_HAS_BOMB()
			return response
		end

		local now_clock = tonumber(LoggerService:GetTimestamp())
		if not fruit.first_slice_time then
			fruit.first_slice_time = now_clock
		end

        if i == fruit_count then
            fruit.is_explode = true
            fruit.player_id = player_id
            fruit.win_chip = request.win_chip
        end
	end

	--seat上放这个作为上这个玩家的score
	if seat.score then
		seat.score = seat.score + request.win_chip
	else
		seat.score = request.win_chip
	end

	response.ret = Return.OK()
	return response
end

MiniGameStates = {
	Prepare = 1,
	Running = 2,
	Rest = 3,
}

SlotsFruitSliceContainer = {

	rooms = Container:Get("SlotsFruitSlice.rooms"),

	player_seat = Container:Get("SlotsFruitSlice.player_seat"),

	Init = function(self)
		setmetatable(self, {
			__index = self.rooms
		})
		return self
	end,

	LocateSeat = function(self, player_id)
		return self.player_seat[player_id]
	end,

	--新的房间
	NewRoom = function(self, name)
		--如果存在，则不创建房间
		if (self.rooms[name] ~= nil) then
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

	--新的桌子
	NewTable = function(self, room)
		room.meta.max_table = room.max_table + 1

		local new_table = {
			state = MiniGameStates.Rest,
			bonus = 0,
			state_start_time = tonumber(LoggerService:GetTimestamp()),
			player_count = 0,
			last_throw_time = 0,
            last_sliced_time = 0,
		}

		local meta = {
			room = room,
			id = room.max_table
		}
		meta.meta = meta
		setmetatable(new_table, {
			__index = meta
		})

		--分配5个座位，改成1个座位（单人副本）
		for i = 1, 5 do
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
			if (room.free_seats[index].table.id < min_table_id and seat.table.state == MiniGameStates.Rest) then
				min_table_id = room.free_seats[index].table.id
				sel_index = index
			end
		end

		if sel_index ~= -1 then
			self.player_seat[player_id] = room.free_seats[sel_index]
			local tab = room.free_seats[sel_index].table
			tab.player_count = tab.player_count + 1

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

		local tab = seat.table
		tab.player_count = math.max(tab.player_count - 1, 0)
		if tab.player_count == 0 then
			tab.bonus = 0
		end

        self.player_seat[player_id] = nil
		return true
	end,

}

Update = function ( _M, session )
	for _, room in pairs(SlotsFruitSliceContainer.rooms) do
		for _, tab in pairs(room) do
			for i=1,5 do
				if tab[i] and tab[i].player and tab[i].online == 1 then
					if not tab[i].game then 
						tab[i].game = CreateGame(tab, tab[i])
					end
					StateMachine:Update(tab[i].game)
				end
			end
		end
	end
end

StateMachine = {
	Update = function ( self, game )
		local tab = game.tab
		local state = self.states[game.state]
		state:UpdateState(game)

		local next_state = state:ChangeState(game)
		if next_state then
			local now_clock = tonumber(LoggerService:GetTimestamp())
			local duration = now_clock - game.state_start_time
			state:LeaveState(game)

			game.state = next_state
			game.state_start_time = now_clock

			state = self.states[next_state]
			state:EnterState(game)
		end
	end,

	states = {
		[MiniGameStates.Rest] = {
			EnterState = function ( self, game )
				--send state sync notice
                TableNoticeHelper.StateSyncNotice(game)
			end,
			UpdateState = function ( self, game )
				--pass
			end,
			LeaveState = function ( self, game )
				--pass
			end,
			ChangeState = function ( self, game )
				if game.bonus >= FruitSliceOthersConfig[1].trigger_bonus_count then
					return MiniGameStates.Prepare
				end
			end,
		},

		[MiniGameStates.Prepare] = {
			EnterState = function ( self, game )
				--send table state sync notice
				--根据进入Prepare时候的人数生成每次投放哪些水果
				FruitControl.GenThrownFruit(game)
                local delay = SlotsFruitSliceCal.Calculate.GenDelayTime(game.erase_times)
				TableNoticeHelper.StateSyncNotice(game, delay)
                TableNoticeHelper.PlayerScoreNotice(game, delay)
			end,

			UpdateState = function ( self, game )
				--pass
			end,
			LeaveState = function ( self, game )
				--pass
			end,
			ChangeState = function ( self, game )
				local now_clock = tonumber(LoggerService:GetTimestamp())
                local delay = SlotsFruitSliceCal.Calculate.GenDelayTime(game.erase_times)
				if now_clock >= game.state_start_time + (FruitSliceOthersConfig[1].prepare_time + delay) * 1000000 then
					return MiniGameStates.Running
				end
			end,
		},

		[MiniGameStates.Running] = {
			EnterState = function ( self, game )
				--send table state sync notice
				TableNoticeHelper.StateSyncNotice(game)
				TableNoticeHelper.PlayerScoreNotice(game)
			end,
			UpdateState = function ( self, game )
				--send fruit notice
				local now_clock = tonumber(LoggerService:GetTimestamp())
				if now_clock - game.last_throw_time >= FruitSliceOthersConfig[1].throw_interval * 1000000 then
					TableNoticeHelper.FruitThrowNotice(game)
					TableNoticeHelper.PlayerScoreNotice(game)
					game.last_throw_time = now_clock
				end
			end,
			LeaveState = function ( self, game )
				local tab = game.tab
				local seat = game.seat
				--reset
				game.thrown_fruits = nil
				--清空game
				game.seat.game = nil
				
				game.throw_times = 1
				game.last_throw_time = tonumber(LoggerService:GetTimestamp())
				TableNoticeHelper.PlayerScoreNotice(game)
                game.bonus = 0
                seat.score = 0
                game.last_sliced_time = tonumber(LoggerService:GetTimestamp())

                local tab_players = {}
                table.insert(tab_players, seat.player.id)

                TableNoticeHelper.BonusIncreaseNotice(tab)
                --通知dispatcher要把这个桌子里的玩家的trigger_times置为0
                Base.ManagerClientService:WriteRouterPacket({
                    header = {
                        router = "Inform",
                        service_name = "ManagerClientService",
                        module_id = "PlayerWatcher",
                        message_id = "PlayerWatcher_ClearTriggerTimes_Request"
                    },
                    player_id = tab_players,
                })
			end,
			ChangeState = function ( self, game )
				if not game.throw_finish_time and game.throw_times >= game.total_throw_times then
					-- return MiniGameStates.Rest
                    game.throw_finish_time = os.time()
				end
                if game.throw_finish_time and os.time() - game.throw_finish_time >= 3 then
                    game.throw_finish_time = nil
                    return MiniGameStates.Rest
                end
			end,
		},
	}
}

TableNoticeHelper = {
	StateSyncNotice = function ( game, delay )
		local game_room_config = GameRoomConfig[GameType.AllTypes.FruitSlice]
		local tab = game.tab
        local channel_id = string.format("%s.%s.%s", "SlotsFruitSliceContest", tab.room.name, tab.id)
        local data = {
            header = {
                router = "ContestNotice",
                channel_id = channel_id,
                module_id = "SlotsFruitSliceContest",
                message_id = "SlotsFruitSliceContest_StateSync_Notice",
                service_name = game_room_config.contest_name,
                player_id = game.seat.player.id
            },
            state = game.state
        }
		if delay then
            Base[game_room_config.contest_name]:TimedWork(function()
                Base[game_room_config.contest_name]:WriteRouterPacket(data)
            end, os.time() + delay)
        else
            Base[game_room_config.contest_name]:WriteRouterPacket(data)
        end
	end,

	FruitThrowNotice = function ( game )
		local game_room_config = GameRoomConfig[GameType.AllTypes.FruitSlice]
		local tab = game.tab
		local channel_id = string.format("%s.%s.%s", "SlotsFruitSliceContest", tab.room.name, tab.id)
		local data = {
			header = {
				router = "ContestNotice",
				channel_id = channel_id,
				module_id = "SlotsFruitSliceContest",
				message_id = "SlotsFruitSliceContest_Fruit_Notice",
				service_name = game_room_config.contest_name,
				player_id = game.seat.player.id
			},
		}
		local fruit_id = {}
		local fruit_type = {}

        if game.thrown_fruits and game.thrown_fruits[game.throw_times] then
            for k,v in ipairs(game.thrown_fruits[game.throw_times]) do
                table.insert(fruit_id, v.fruit_id)
                table.insert(fruit_type, v.fruit_type)
            end
            data.fruit_id = fruit_id
            data.fruit_type = fruit_type
            data.timestamp = os.time()

            game.throw_times = game.throw_times + 1

            Base[game_room_config.contest_name]:WriteRouterPacket(data)
        end
	end,

	FruitSlicedNotice = function ( game, fruit_id, fruit_explode )
		local game_room_config = GameRoomConfig[GameType.AllTypes.FruitSlice]
		local tab = game.tab
		local channel_id = string.format("%s.%s.%s", "SlotsFruitSliceContest", tab.room.name, tab.id)
		local data = {
			header = {
				router = "ContestNotice",
				channel_id = channel_id,
				module_id = "SlotsFruitSliceContest",
				message_id = "SlotsFruitSliceContest_FruitSliced_Notice",
				service_name = game_room_config.contest_name,
				player_id = game.seat.player.id
			},
			fruit_id = fruit_id,
            fruit_explode = fruit_explode,
		}
		Base[game_room_config.contest_name]:WriteRouterPacket(data)
	end,

	BonusIncreaseNotice = function ( game, player_id )
		local game_room_config = GameRoomConfig[GameType.AllTypes.FruitSlice]
		local tab = game.tab
		
		if not tab then
			return
		end

		local channel_id = string.format("%s.%s.%s", "SlotsFruitSliceContest", tab.room.name, tab.id)
		local data = {
			header = {
				router = "ContestNotice",
				channel_id = channel_id,
				module_id = "SlotsFruitSliceContest",
				message_id = "SlotsFruitSliceContest_Bonus_Notice",
				service_name = game_room_config.contest_name,
				player_id = player_id,
				player_id = game.seat.player.id
			},
			bonus = game.bonus,
            trigger_player = player_id,
		}
		Base[game_room_config.contest_name]:WriteRouterPacket(data)
	end,

	PlayerScoreNotice = function ( game, delay )
		local game_room_config = GameRoomConfig[GameType.AllTypes.FruitSlice]
		local tab = game.tab
		local channel_id = string.format("%s.%s.%s", "SlotsFruitSliceContest", tab.room.name, tab.id)
		local data = {
			header = {
				router = "ContestNotice",
				channel_id = channel_id,
				module_id = "SlotsFruitSliceContest",
				message_id = "SlotsFruitSliceContest_PlayerScore_Notice",
				service_name = game_room_config.contest_name,
				player_id = game.seat.player.id
			},
		}
		local all_seat = {}
		local all_player_score = {}
		for i, seat in ipairs(tab) do
            if seat.player then
                local brief_player = {
                    user = {
                        nickname = seat.player.user.nickname,
                        avatar = seat.player.user.avatar,
                    },
                    id = seat.player.id,
                }
                table.insert(all_seat, {
                    id = seat.id,
                    player = brief_player,
                    online = seat.online,
                })
                local seat_score = seat.score and seat.score or 0
                table.insert(all_player_score, seat_score)
            end
		end
		data.seat = all_seat
		data.player_score = all_player_score
        if delay then
            Base[game_room_config.contest_name]:TimedWork(function()
                Base[game_room_config.contest_name]:WriteRouterPacket(data)
            end, os.time() + delay)
        else
		    Base[game_room_config.contest_name]:WriteRouterPacket(data)
        end
	end,
}

FruitType = {
	Pitaya = 1,
	Pomegranate = 2,
	Pineapple = 3,
	Watermelon = 4,
	Banana = 5,
	Kiwifruit = 6,
	Lemon = 7,
	Apple = 8,
	Strawberry = 9,
	Cherry = 10,
	Bomb = 11,
}

FruitControl = {
	GenThrownFruit = function ( game )
		local player_count = 1

		local all_fruits = {}
		local total_count = FruitSliceThrowConfig[player_count].total_count
		local single_count = math.floor(total_count / 10)
		for i = 1, 10 do
			for j = 1, single_count do
				table.insert(all_fruits, i)
			end
		end
		all_fruits = math.disorder_table(all_fruits)

		local throw_times = FruitSliceThrowConfig[player_count].throw_times
		local count_every_time = FruitSliceThrowConfig[player_count].count_every_time
		local bomb_count = FruitSliceThrowConfig[player_count].bomb_count
		local bomb_prob = FruitSliceThrowConfig[player_count].bomb_prob

		local thrown_fruits = {}
		local id_index = 1
		for i = 1, throw_times do
			thrown_fruits[i] = {}
			for j = 1, count_every_time do
				table.insert(thrown_fruits[i], {
					fruit_type = all_fruits[(i - 1) * count_every_time + j],
					fruit_id = id_index,
				})
				id_index = id_index + 1
			end

			for k = 1, bomb_count do
				if math.rand_prob(bomb_prob) then
					local index = math.random(#thrown_fruits[i])
					table.insert(thrown_fruits[i], index, {
						fruit_type = FruitType.Bomb,
						fruit_id = id_index,
					})
					id_index = id_index + 1
				end
			end
		end
		game.thrown_fruits = thrown_fruits
		--用以标记当前是第几次扔水果
		game.throw_times = 1
		game.total_throw_times = throw_times
	end,

	GetFruitById = function ( game, fruit_id )
		if game.thrown_fruits then
			for _, v in ipairs(game.thrown_fruits) do
				for _, fruit in ipairs(v) do
					if fruit.fruit_id == fruit_id then
						return fruit
					end
				end
			end
		end
	end,
}