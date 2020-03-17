require "Base/LuaSession"
require "Module/Gift"
require "Common/CommonCal"
require "Config/ServerConfig"

_G.RobotManager = {}
local this = RobotManager

function RobotManager.New()
	return this
end

function RobotManager.Print()
	for session_id, robot_session in pairs(this.robot_session_vec) do
		--LOG(RUN, INFO).Format("[RobotManager][Print] session_id is: %s", session_id)
	end
end

function RobotManager.Init()
	if (this.has_init == nil) then
		this.has_init = 1

		this.init_finish = false

		this.club_time = os.time()
		this.robot_session_list = {}
		this.robot_session_vec = {}
		this.event_list = {}

		this.robot_count = 750
		this.event_list = {}
		this.robot_flag_list = {}

		local create_date_st = string.split("2018:12:27:01:00", ":")
		 --string.split(ConstValue[2].value, ":")
		this.create_time =
			os.time(
			{
				year = tonumber(create_date_st[1]),
				month = tonumber(create_date_st[2]),
				day = tonumber(create_date_st[3]),
				hour = tonumber(create_date_st[4]),
				min = tonumber(create_date_st[5]),
				sec = tonumber(create_date_st[6])
			}
		)

		this.InitRobotIndex()
	end
end

function RobotManager.InitRobotIndex()
	if (this.has_init == nil) then
		return
	end

	local period_index = 0
	 --math.floor((os.time() - this.create_time) / (15 * 24 * 60 * 60))
	local start_index = 1

	local org_start_index = 1

	local end_index = this.robot_count

	LOG(RUN, INFO).Format(
		"[RobotManager][InitRobotIndex] period_index: %s, start_index: %s, org_start_index:%s。 end_index is: %s",
		period_index,
		start_index,
		org_start_index,
		end_index
	)

	for i = org_start_index, end_index, 1 do
		local add_time = math.floor((i - org_start_index) / 20)
		if (math.mod(i, 50) == 0) then
			LOG(RUN, INFO).Format("[RobotManager][InitRobotIndex] add_time is: %s, i is: %s", add_time, i)
		end

		table.insert(this.robot_flag_list, {index = i, init_time = os.time() + add_time, is_del = false, is_online = true})
	end
end

function RobotManager.InitRobots(server_index)
	this.server_index = server_index
	if (this.has_init == nil) then
		return
	end

	for k, v in pairs(this.robot_flag_list) do
		if (v.is_del) then
			this.robot_flag_list[k] = nil
		end
	end

	this.init_finish = true

	if (this.game_room_config_list == nil) then
		this.game_room_config_list = {}
		for game_type, game_room_config in pairs(GameRoomConfig) do
			if (RobotRoomConfig[game_type] ~= nil and RobotRoomConfig[game_type].number > 0) then
				-- local modvalue = math.fmod(game_room_config.game_type, 2)
				-- if modvalue + 1 == this.server_index then
				this.game_room_config_list[game_type] = game_room_config
			-- end
			end
		end

		LOG(RUN, INFO).Format(
			"[RobotManager][InitRobots] this.server_index is:%s, server_index is: %s, this.game_room_config_list is: %s",
			this.server_index,
			server_index,
			json.encode(this.game_room_config_list)
		)
	end

	------初始化机器人-------------------
	for k, v in pairs(this.robot_flag_list) do
		if (os.time() > v.init_time) then
			--LOG(RUN, INFO).Format("[RobotManager][InitRobots] cur_time is: %s", os.time())
			local task = Task:New()
			task:Init(
				function()
					v.is_del = true
					local i = v.index
					local robot_flag = 10000000 * server_index + this.robot_count + i
					local session_id = 10000 + i
					local robot_id = 0
					local async_request = {
						string.format("select id from slots_account.gen_player_id_table where test_str = '%s'", robot_flag)
					}
					local async_response = LuaSession:ContactJson("DatabaseClientService", task, async_request, robot_flag)

					if (v.is_online) then
						if async_response[1].row_num <= 0 then
							local async_request = {
								string.format("insert into slots_account.gen_player_id_table(test_str) values('%s')", robot_flag)
							}
							local async_response = LuaSession:ContactJson("DatabaseClientService", task, async_request, robot_flag)

							local async_request = {
								string.format("select id from slots_account.gen_player_id_table where test_str = '%s'", robot_flag)
							}
							local async_response = LuaSession:ContactJson("DatabaseClientService", task, async_request, robot_flag)
							robot_id = this.GenPlayerId(tonumber(async_response[1].data_set[1][1]))
							LOG(RUN, INFO).Format("[RobotManager][GenPlayerId] robot_id1 is: %s", robot_id)
						else
							robot_id = this.GenPlayerId(tonumber(async_response[1].data_set[1][1]))
							LOG(RUN, INFO).Format("[RobotManager][GenPlayerId] robot_id2 is: %s", robot_id)
						end

						LOG(RUN, INFO).Format("[RobotManager][GenPlayerId] robot_id is: %s", robot_id)
						this.InitSession(robot_id, session_id)
					else
						if async_response[1].row_num > 0 then
							robot_id = this.GenPlayerId(tonumber(async_response[1].data_set[1][1]))
							for room_id, room_info in pairs(this.game_room_config_list) do
								local async_request = {
									header = {
										router = "AsyncRequest",
										service_name = room_info.contest_client_name,
										task_id = task.id,
										module_id = room_info.const_game_name,
										message_id = room_info.const_game_name .. "_Exit_Request"
									},
									player_id = robot_id
								}
								local async_response = LuaSession:ContactPacket(task, async_request)
							end
						end
					end
				end
			)
			task:Start()
		end
	end
end

function RobotManager.GenPlayerId(robot_id)
	----LOG(RUN, INFO).Format("[RobotManager][GenPlayerId] robot id is: %s", robot_id)
	local id = robot_id + 80362409
	----LOG(RUN, INFO).Format("[RobotManager][GenPlayerId] id is: %s", id)
	local digits = {}
	digits[1] = math.floor(id / 10000000)
	id = id % 10000000
	digits[3] = math.floor(id / 1000000)
	id = id % 1000000
	digits[5] = math.floor(id / 100000)
	id = id % 100000
	digits[7] = math.floor(id / 10000)
	id = id % 10000
	digits[4] = math.floor(id / 1000)
	id = id % 1000
	digits[8] = math.floor(id / 100)
	id = id % 100
	digits[2] = math.floor(id / 10)
	id = id % 10
	digits[6] = math.floor(id / 1)
	----LOG(RUN, INFO).Format("[RobotManager][GenPlayerId] digits is: %s", Table2Str(digits))
	local player_id_str = ""
	for k, digit in ipairs(digits) do
		player_id_str = player_id_str .. digit
	end
	local player_id = tonumber(player_id_str)
	----LOG(RUN, INFO).Format("[RobotManager][GenPlayerId] player_id is: %s", player_id)
	return player_id
end

-- function RobotManager.GetFreeSession()
-- 	if (this.has_init == nil) then
-- 		return
-- 	end
-- 	for k, robot_session in pairs(this.robot_session_list)
-- 	do
-- 		if (robot_session.player ~= nil and robot_session.player.game_type == 0 and os.time() - robot_session.status_time > 10)
-- 		then
-- 			robot_session.player.game_type = tonumber(ConstValue[6].value)
-- 			return robot_session
-- 		end
-- 	end

-- 	return nil
-- end

function RobotManager.BroadCast()
	--[[
	if (this.has_init == nil) then
		return
	end

	if (this.broad_cast_dur == nil) then
		this.broad_cast_dur = 50
	end

	if (this.broad_cast_flag == nil) then
		this.broad_cast_flag = -1
	end
	if (this.broad_cast_flag >= this.broad_cast_dur - 1) then
		this.broad_cast_flag = -1
	end
	this.broad_cast_flag = this.broad_cast_flag + 1

	for k, robot_session in pairs(this.robot_session_list)
	do
		----LOG(RUN, INFO).Format("[RobotManager][BroadCast] begin session id is:%s, robot id %s, nickname:%s", robot_session.id, robot_session.player.id, robot_session.player.user.nickname)

		if (robot_session.player.game_type > 0 and game_type ~= tonumber(ConstValue[6].value)) then
			local robot_mod = math.mod(robot_session.id, this.broad_cast_dur)
			----LOG(RUN, INFO).Format("[RobotManager][BroadCast]broad_cast_flag:%s id:%s,broad_cast_dur:%s,  robot_mod:%s", this.broad_cast_flag, robot_session.id, this.broad_cast_dur, robot_mod)
			if (robot_mod == this.broad_cast_flag) then
				----LOG(RUN, INFO).Format("[RobotManager][BroadCast] RobotBroadCastChip %s, nickname:%s", robot_session.player.id, robot_session.player.user.nickname)

				local task = Task:New()
				task:Init(function()
					Player:RobotBroadCastChip(robot_session, task, 0, 0)
				end)
				task:Start()
			end
		end
	end
	--]]
end

function RobotManager.Monitor()
	if (this.has_init == nil) then
		return
	end
	local cur_time = os.time()

	if (this.room_players == nil) then
		this.room_players = {}
		this.room_players.rooms = {}
		this.room_players.robot_count = {}
		this.room_players.action_time = {}
		 --cur_time + this.robot_count

		this.kick_list = {}

		this.enter_list = {}

		this.monitor_time = 0

		for game_type, game_room_config in pairs(this.game_room_config_list) do
			if (this.room_players.action_time[game_type] == nil) then
				this.room_players.action_time[game_type] = 0 --+ this.robot_count
			end
		end
	end

	if (cur_time - this.monitor_time > 60 and this.init_finish) then
		this.monitor_time = cur_time

		this.idle_players = {}
		for game_type, game_room_config in pairs(this.game_room_config_list) do
			this.room_players.rooms[game_type] = {}
			this.room_players.robot_count[game_type] = 0
		end

		local idle_robot_num = 0
		local spin_robot_num = 0
		local wait_robot_num = 0
		local room_num = {}
		for k, robot_session in pairs(this.robot_session_list) do
			if (robot_session.player.game_type == 0) then
				idle_robot_num = idle_robot_num + 1
				table.insert(this.idle_players, robot_session.player.id)
			elseif (robot_session.player.game_type == tonumber(ConstValue[6].value)) then
				wait_robot_num = wait_robot_num + 1
			else
				spin_robot_num = spin_robot_num + 1
				if (room_num[robot_session.player.game_type] == nil) then
					room_num[robot_session.player.game_type] = 0
				end

				room_num[robot_session.player.game_type] = room_num[robot_session.player.game_type] + 1

				table.insert(this.room_players.rooms[robot_session.player.game_type], robot_session.player.id)
				this.room_players.robot_count[robot_session.player.game_type] =
					this.room_players.robot_count[robot_session.player.game_type] + 1
			end
		end
		if #this.idle_players == 0 then
			-- LOG(RUN, INFO).Format("[RobotManager][Monitor] idle_players is zero")
			return
		end

		LOG(RUN, INFO).Format(
			"[RobotManager][Monitor] idle_robot_num: %s, spin_robot_num: %s, wait_robot_num:%s",
			idle_robot_num,
			spin_robot_num,
			wait_robot_num
		)
		for k, v in pairs(room_num) do
			LOG(RUN, INFO).Format("[RobotManager][Monitor] game type: %s, robot num:%s", k, v)
		end

		for game_type, game_room_config in pairs(this.game_room_config_list) do
			local left_kick_count = 0
			local left_enter_count = 0
			if (this.kick_list[game_type]) then
				for k, v in pairs(this.kick_list[game_type]) do
					left_kick_count = left_kick_count + 1
				end
			end

			if (this.enter_list[game_type]) then
				for k, v in pairs(this.enter_list[game_type]) do
					left_enter_count = left_enter_count + 1
				end
			end

			-- LOG(RUN, INFO).Format("[RobotManager][Monitor] game type: %s, left_enter_count:%s, left_kick_count: %s", game_type, left_enter_count, left_kick_count)

			if (left_kick_count == 0 and left_enter_count == 0) then
				if (cur_time > this.room_players.action_time[game_type]) then
					this.room_players.action_time[game_type] = RobotRoomConfig[game_type].dur_time + cur_time

					-----计划房间的人数
					local plan_count =
						RobotRoomConfig[game_type].number +
						math.random(RobotRoomConfig[game_type].min_rand_num, RobotRoomConfig[game_type].max_rand_num)
					-----计划要踢掉的人数
					local kick_count = RobotRoomConfig[game_type].kick_out_num
					-----实际房间的人数
					local cur_count = this.room_players.robot_count[game_type]
					if (kick_count > cur_count) then
						kick_count = cur_count
					end

					-----进入的人数
					local enter_count = plan_count + kick_count - cur_count

					-- LOG(RUN, INFO).Format("[RobotManager][Monitor] game_type:%s, kick_count: %s, enter_count:%s", game_type, kick_count, enter_count)
					----先踢后进
					if (cur_count > RobotRoomConfig[game_type].number - RobotRoomConfig[game_type].max_rand_num) then
						this.kick_list[game_type] = {}
						local kick_index = 1
						for index, robot_id in pairs(this.room_players.rooms[game_type]) do
							if (kick_index > kick_count) then
								break
							end
							--local robot_id = this.room_players.rooms[game_type][index]  --this.room_players.rooms[game_type][index]
							if (robot_id ~= nil) then
								this.room_players.rooms[game_type][index] = nil
								kick_index = kick_index + 1
								LOG(RUN, INFO).Format(
									"[RobotManager][Monitor]1 game_type:%s, kick_count: %s, enter_count:%s, robot_id is:%s",
									game_type,
									kick_count,
									enter_count,
									robot_id
								)
								local action_time = cur_time
								table.insert(this.kick_list[game_type], {robot_id = robot_id, action_time = action_time})
							end
						end
					end

					this.enter_list[game_type] = {}
					-- LOG(RUN, INFO).Format("[RobotManager][Monitor]6 game_type:%s, idle players is:%s", game_type, #this.idle_players)
					local enter_index = 1
					for index, robot_id in pairs(this.idle_players) do
						-- LOG(RUN, INFO).Format("[RobotManager][Monitor]5 game_type:%s, index is:%s, kick_count: %s, enter_count:%s, robot_id is:%s", game_type, index, kick_count, enter_count, robot_id)
						if (enter_index > enter_count) then
							break
						end
						if (robot_id ~= nil) then
							this.idle_players[index] = nil
							enter_index = enter_index + 1
							LOG(RUN, INFO).Format(
								"[RobotManager][Monitor]2 game_type:%s, kick_count: %s, enter_count:%s, robot_id is:%s",
								game_type,
								kick_count,
								enter_count,
								robot_id
							)
							local action_time =
								cur_time + math.random(RobotRoomConfig[game_type].min_rand_dur, RobotRoomConfig[game_type].max_rand_dur)
							table.insert(this.enter_list[game_type], {robot_id = robot_id, action_time = action_time})
						end
					end
				end
			end
		end
	end
end

function RobotManager.ResetFreeSession()
	if (this.has_init == nil) then
		return
	end
	local cur_time = os.time()

	if (this.free_dur == nil) then
		this.free_dur = 50
	end

	if (this.free_flag == nil) then
		this.free_flag = -1
	end
	if (this.free_flag >= this.free_dur - 1) then
		this.free_flag = -1
	end
	this.free_flag = this.free_flag + 1

	for k, robot_session in pairs(this.robot_session_list) do
		if (robot_session.player.game_type > 0 and os.time() - robot_session.status_time > 120) then
			robot_session.status_time = os.time()
			local robot_mod = math.mod(robot_session.id, this.free_dur)
			if (robot_mod == this.free_flag) then
				for room_id, room_info in pairs(this.game_room_config_list) do
					local task = Task:New()
					task:Init(
						function()
							local async_request = {
								header = {
									router = "AsyncRequest",
									service_name = room_info.contest_client_name,
									task_id = task.id,
									module_id = room_info.const_game_name,
									message_id = room_info.const_game_name .. "_Exit_Request"
								},
								player_id = robot_id
							}
							local async_response = LuaSession:ContactPacket(task, async_request)
						end
					)
					task:Start()
				end
				robot_session.player.game_type = 0
			end
		end
	end
end

function RobotManager.SelConfigInfo(player, config_file)
	local local_weight_tab = {}
	for k, v in ipairs(config_file) do
		local_weight_tab[k] = v.random
	end
	local local_index = math.rand_weight(player, local_weight_tab)
	return config_file[local_index]
end

function RobotManager.SaveQuickly(robot_session)
	local task = robot_session.task
	robot_session.save_time = os.time()
	robot_session.player.version = (robot_session.player.version or 0) + 1
	robot_session.player.expire = os.time() + 600

	local commands = TableCache:GetActionCommand(robot_session.player)
	--LOG(RUN, INFO).Format("[RobotManager][Save] player_id is: %s, command is: %s", robot_session.player.id, Table2Str(commands))
	LuaSession:ContactJson("CacheClientService", task, commands, robot_session.player.id)

	local async_request = {
		[1] = string.format("hmset id_to_token %s robot%s", robot_session.player.id, robot_session.player.id),
		[2] = string.format("hmset token_to_id robot%s %s", robot_session.player.id, robot_session.player.id)
	}
	local async_response = LuaSession:ContactJson("CacheClientService", task, async_request, robot_session.player.id)
end

function RobotManager.Save()
	if (this.has_init == nil) then
		return
	end

	if (this.save_dur == nil) then
		this.save_dur = 500
	end

	if (this.save_flag == nil) then
		this.save_flag = -1
	end
	if (this.save_flag >= this.save_dur - 1) then
		this.save_flag = -1
	end

	this.save_flag = this.save_flag + 1

	for k, robot_session in pairs(this.robot_session_list) do
		local robot_mod = math.mod(robot_session.id, this.save_dur)
		if (robot_mod == this.save_flag) then
			local task = Task:New()
			task:Init(
				function()
					--LOG(RUN, INFO).Format("[RobotManager][save] begin: %s", robot_session.id)
					robot_session.player.version = (robot_session.player.version or 0) + 1
					robot_session.player.expire = os.time() + 1000

					local commands = TableCache:GetActionCommand(robot_session.player)
					LuaSession:ContactJson("CacheClientService", task, commands, robot_session.player.id)

					local async_request = {
						[1] = string.format("hmset id_to_token %s robot%s", robot_session.player.id, robot_session.player.id),
						[2] = string.format("hmset token_to_id robot%s %s", robot_session.player.id, robot_session.player.id)
					}
					local async_response = LuaSession:ContactJson("CacheClientService", task, async_request, robot_session.player.id)
				end
			)
			task:Start()
		end
	end
end

function RobotManager.Spin()
	if (this.has_init == nil) then
		return
	end
	if (this.spin_dur == nil) then
		this.spin_dur = 10
	end

	if (this.spin_flag == nil) then
		this.spin_flag = -1
	end
	if (this.spin_flag >= this.spin_dur - 1) then
		this.spin_flag = -1
	end
	this.spin_flag = this.spin_flag + 1
	LOG(RUN, INFO).Format("[RobotManager][Spin] begin")
	for k, robot_session in pairs(this.robot_session_list) do
		--------------每个机器人在房间内按概率选择一套配置进行下注，需要像正常玩家一样，实时显示筹码变化
		local robot_mod = math.mod(robot_session.id, this.spin_dur)
		if (robot_mod == this.spin_flag) then
			local task = Task:New()
			task:Init(
				function()
					this.Start(task, robot_session)
				end
			)
			task:Start()
		end
	end
end

function RobotManager.NotifyChip(robot_id, delay_time) ---补充筹码
	if (this.has_init == nil) then
		return
	end
	--LOG(RUN, INFO).Format("[SlotsRoomInfo][NotifyChip]delay_time: %s", delay_time)
	local action_time = os.time() + delay_time
	table.insert(this.event_list, {type = 3, robot_id = robot_id, action_time = action_time, init_time = os.time()})
end

function RobotManager.EventLoop()
	if (this.has_init == nil) then
		return
	end
	local cur_time = os.time()
	for k, event in pairs(this.event_list) do
		if (cur_time - event.init_time > 120) then
			this.event_list[k] = nil
		end
	end

	for k, event in pairs(this.event_list) do
		if (event.type == 3 and cur_time > event.action_time) then
			LOG(RUN, INFO).Format("[RobotManager]supply")
			local robot_id = event.robot_id
			this.SupplyChip(robot_id)
			this.event_list[k] = nil
		end
	end

	if (this.enter_list ~= nil) then
		for game_type, game_room_config in pairs(this.game_room_config_list) do
			if (this.enter_list[game_type] ~= nil) then
				for key, robot_info in pairs(this.enter_list[game_type]) do
					-- LOG(RUN, INFO).Format("[RobotManager]enter list game type : %s, robot id: %s", game_type, robot_info.robot_id)
					if (cur_time > robot_info.action_time) then
						-- LOG(RUN, INFO).Format("[RobotManager]enter list game type : %s, robot id: %s begin", game_type, robot_info.robot_id)
						local robot_session = this.robot_session_list[robot_info.robot_id]
						--this.enter_list[game_type][key] = nil
						robot_session.enter_key = key
						--robot_session.player.game_type == tonumber(ConstValue[6].value)
						this.EnterRoom(robot_session, game_room_config)
					end
				end
			end
		end
	end

	if (this.kick_list ~= nil) then
		for game_type, game_room_config in pairs(this.game_room_config_list) do
			if (this.kick_list[game_type] ~= nil) then
				for key, robot_info in pairs(this.kick_list[game_type]) do
					-- LOG(RUN, INFO).Format("[RobotManager]kick list game type : %s, robot id: %s", game_type, robot_info.robot_id)
					if (cur_time > robot_info.action_time) then
						-- LOG(RUN, INFO).Format("[RobotManager]kick list game type : %s, robot id: %s begin", game_type, robot_info.robot_id)
						local robot_session = this.robot_session_list[robot_info.robot_id]
						--this.kick_list[game_type][key] = nil
						robot_session.kick_key = key
						this.LeaveRoom(robot_session, game_room_config)
					end
				end
			end
		end
	end
end

function RobotManager.Like(robot_id)
	if (this.has_init == nil) then
		return
	end
	local robot_session = this.robot_session_list[robot_id]
	if (robot_session == nil) then
		return
	end

	if (robot_session.player == nil) then
		return
	end

	local game_type = robot_session.player.game_type
	if (game_type == 0) then
		return
	end

	if (game_type == tonumber(ConstValue[6].value)) then
		return
	end
	local game_room_config = this.game_room_config_list[game_type]

	local task = Task:New()
	task:Init(
		function()
			local async_request = {
				header = {
					router = "AsyncRequest",
					service_name = game_room_config.contest_client_name,
					task_id = task.id,
					module_id = "SlotsRoomInfoContest",
					message_id = "SlotsRoomInfoContest_TableInfo_Request"
				}
			}
			async_request.game_type = game_room_config.game_type
			async_request.player_id = robot_session.player.id

			local async_response = Base[game_room_config.contest_client_name]:ContactPacket(task, async_request)

			if (async_response.ret.code ~= 0) then
				return
			end
			local request = {}
			request.header = {}

			local to_player_ids = {}
			for _, v in pairs(async_response.table.seat) do
				if v.player then
					if (robot_id ~= v.player.id) then
						table.insert(to_player_ids, v.player.id)
					end
				end
			end

			if (#to_player_ids == 0) then
				return
			end

			local index = math.random(1, #to_player_ids)
			local to_player_id = to_player_ids[index]

			if (this.robot_session_list[to_player_id] == nil) then
				return
			end

			local async_request = {
				string.format(
					"select like_count, last_like_time from slots_account.player_like_%s where player_id = %s",
					math.mod(to_player_id, 16),
					to_player_id
				)
			}

			local async_response = LuaSession:ContactJson("DatabaseClientService", task, async_request, to_player_id)
			if async_response[1].row_num <= 0 then
				async_request = {
					string.format(
						"insert into slots_account.player_like_%s(player_id, like_count, last_like_time) values(%s, %s, %s)",
						math.mod(to_player_id, 16),
						player_id,
						1,
						os.time()
					)
				}
				local async_response = LuaSession:ContactJson("DatabaseClientService", task, async_request, to_player_id)
			else
				local like_count = tonumber(async_response[1].data_set[1][1])
				local last_like_time = tonumber(async_response[1].data_set[1][2])
				if (os.time() - last_like_time > 3600) then
					like_count = like_count + 1
					local async_request = {
						string.format(
							"update slots_account.player_like_%s set like_count = %s where player_id = %s",
							math.mod(to_player_id, 16),
							like_count,
							to_player_id
						)
					}
					local async_response = LuaSession:ContactJson("DatabaseClientService", task, async_request, to_player_id)
				end
			end

			robot_session.like_actiom_time = os.time()
		end
	)
	task:Start()
end

function RobotManager.SendChips(robot_id)
end

function RobotManager.SendTreats(robot_id)
	local task = Task:New()
	task:Init(
		function()
			if (this.has_init == nil) then
				return
			end

			local robot_session = this.robot_session_list[robot_id]
			if (robot_session == nil) then
				return
			end
			if (robot_session.player == nil) then
				return
			end

			local game_type = robot_session.player.game_type
			if (game_type == 0) then
				return
			end
			if (game_type == tonumber(ConstValue[6].value)) then
				return
			end

			local game_room_config = this.game_room_config_list[game_type]

			local async_request = {
				header = {
					router = "AsyncRequest",
					service_name = game_room_config.contest_client_name,
					task_id = task.id,
					module_id = "SlotsRoomInfoContest",
					message_id = "SlotsRoomInfoContest_TableInfo_Request"
				}
			}
			async_request.game_type = game_room_config.game_type
			async_request.player_id = robot_session.player.id

			local async_response = Base[game_room_config.contest_client_name]:ContactPacket(task, async_request)

			if (async_response.ret.code ~= 0) then
				return
			end

			local request = {}
			request.header = {}

			local to_player_id = {}
			for _, v in pairs(async_response.table.seat) do
				if v.player then
					if (robot_id ~= v.player.id) then
						if (PlayerSession:QueryPlayerIndex(v.player.id) ~= nil) then
							table.insert(to_player_id, v.player.id)
						elseif (this.robot_session_list[v.player.id] ~= nil) then
							table.insert(to_player_id, v.player.id)
						end
					end
				end
			end

			request.treat_id = math.random(1, #GiftTreatsConfig)
			request.to_player_id = to_player_id
			request.type = game_room_config.game_type

			robot_session.task = task
			Gift.SendTreats(nil, robot_session, request)
		end
	)
	task:Start()
end

function RobotManager.SupplyChip(robot_id)
	if (this.has_init == nil) then
		return
	end
	local robot_session = this.robot_session_list[robot_id]
	if (robot_session == nil) then
		return
	end

	if (robot_session.player == nil) then
		return
	end

	local robot_chip_supply_conf = RobotChipSupplyConfig[robot_session.player.character.vip + 1]
	local VIP_CHIP = {500000, 1000000, 2000000, 5000000, 10000000, 30000000, 50000000, 80000000, 120000000}
	local local_weight_tab = {}
	for k, v in ipairs(robot_chip_supply_conf.random) do
		local_weight_tab[k] = v
	end

	local local_index = math.rand_weight(robot_session.player, local_weight_tab)
	local chip_value = VIP_CHIP[local_index]
	robot_session.player.character.chip = robot_session.player.character.chip + chip_value
end

function RobotManager.EnterRoom(robot_session, game_room_config)
	if (this.has_init == nil) then
		return
	end
	local task = Task:New()
	task:Init(
		function()
			local table_id = 0

			local request = {}
			request.header = {}
			request.table_id = table_id
			request.game_type = game_room_config.game_type

			local module_name = "SlotsGame"

			if (game_room_config.const_game_name ~= "SlotsGameContest") then
				module_name = "Slots" .. game_room_config.game_name
			end

			LOG(RUN, INFO).Format(
				"[RobotManager][EnterRoom] begin enter: %s, nickname is: %s, game type is:%s",
				robot_session.player.id,
				robot_session.player.user.nickname,
				game_room_config.game_type
			)
			robot_session.task = task

			robot_session.status_time = os.time()

			local response = _G[module_name].Enter(nil, robot_session, request)

			this.enter_list[robot_session.player.game_type][robot_session.enter_key] = nil
			if (response.ret.code ~= 0) then
				robot_session.player.game_type = 0
				-- LOG(RUN, INFO).Format("[RobotManager][EnterRoom] player: %s, game type is:%s, error is:%s", robot_session.player.id, game_room_config.game_type, Table2Str(response.ret))
				return
			end
		end
	)
	task:Start()
end

function RobotManager.LeaveRoom(robot_session, game_room_config)
	if (this.has_init == nil) then
		return
	end
	local task = Task:New()
	task:Init(
		function()
			if (robot_session.player == nil) then
				return
			end

			if (robot_session.player.game_type == 0) then
				return
			end

			if (robot_session.player.game_type == tonumber(ConstValue[6].value)) then
				return
			end

			robot_session.status_time = os.time()

			local request = {}
			request.header = {}

			local module_name = "SlotsGame"

			if (game_room_config.const_game_name ~= "SlotsGameContest") then
				module_name = "Slots" .. game_room_config.game_name
			end

			LOG(RUN, INFO).Format(
				"[RobotManager][LeaveRoom] begin leave: %s, nickname is: %s, game type is:%s",
				robot_session.player.id,
				robot_session.player.user.nickname,
				game_room_config.game_type
			)
			robot_session.task = task
			this.kick_list[robot_session.player.game_type][robot_session.kick_key] = nil
			local response = _G[module_name].Exit(nil, robot_session, request)

			if (response.ret.code ~= 0) then
				-- LOG(RUN, INFO).Format("[RobotManager][Exit] player: %s, game type is:%s, error is:%s", robot_session.player.id, game_room_config.game_type, Table2Str(response.ret))
				return
			end
		end
	)
	task:Start()
end

function RobotManager.Start(task, robot_session)
	if (this.has_init == nil) then
		return
	end
	if (robot_session.player == nil) then
		return
	end
	local game_type = robot_session.player.game_type
	if (game_type == 0) then
		LOG(RUN, INFO).Format("[RobotManager][Start] game type is zero")
		return false
	end

	if (game_type == tonumber(ConstValue[6].value)) then
		LOG(RUN, INFO).Format("[RobotManager][Start] game type is error")
		return false
	end
	LOG(RUN, INFO).Format("[RobotManager][Start] begin")

	---每个机器人在房间内按概率选择一套配置进行下注，需要像正常玩家一样，实时显示筹码变化
	local robot_chip_action = this.SelConfigInfo(robot_session.player, RobotChipActionConfig)

	local interval_time = math.random(robot_chip_action.bet_min_time, robot_chip_action.bet_max_time)
	--local interval_time = math.random(10, 40)

	if (os.time() - robot_session.spin_time > interval_time) then
		LOG(RUN, INFO).Format("[RobotManager][Start] start")
		robot_session.status_time = os.time()
		robot_session.spin_time = os.time()

		local game_room_config = this.game_room_config_list[game_type]

		local sel_bet_amount_config_name = game_room_config.game_name .. "BetAmountConfig"

		local GameBetAmountConfig = _G[GameMapConfig[game_type].bet_amount_config]
		if (GameBetAmountConfig == nil) then
			LOG(RUN, INFO).Format("[RobotManager][Start] sel_bet_amount_config_name is: %s", sel_bet_amount_config_name)
		end

		local request = {}
		request.header = {}

		--local CHIP_CONST = {250000, 500000, 1250000, 2500000, 5000000, 12500000, 25000000, 50000000, 125000000, 250000000, 500000000, 990000000000}

		local sel_spin_level = 0

		local min_spin_level = 99999999

		for k, v in pairs(RobotChipSpinConfig) do
			if (min_spin_level > k) then
				min_spin_level = k
			end
			if (k < robot_session.player.character.chip) then
				if (sel_spin_level < k) then
					sel_spin_level = k
				end
			end
		end

		if (sel_spin_level == 0) then
			sel_spin_level = min_spin_level
		end

		-----------------查找和机器人携带筹码匹配的赌注

		--LOG(RUN, INFO).Format("[SlotsRoomInfo][Spin]  #RobotChipSpinConfig[sel_spin_level].bet_type is: %s", #RobotChipSpinConfig[sel_spin_level].bet_type)

		local sel_index = math.random(1, #RobotChipSpinConfig[sel_spin_level].bet_type)

		local sel_bet_index = RobotChipSpinConfig[sel_spin_level].bet_type[sel_index]

		--LOG(RUN, INFO).Format("[SlotsRoomInfo][Spin]11 sel_bet_index is: %s", sel_bet_index)

		sel_bet_index = sel_bet_index > #GameBetAmountConfig and #GameBetAmountConfig or sel_bet_index

		--LOG(RUN, INFO).Format("[SlotsRoomInfo][Spin]22 sel_bet_index is: %s", sel_bet_index)

		request.amount = GameBetAmountConfig[sel_bet_index].single_amount

		local module_name = "SlotsGame"
		if (game_room_config.const_game_name ~= "SlotsGameContest") then
			module_name = "Slots" .. game_room_config.game_name
		end

		robot_session.task = task
		LOG(RUN, INFO).Format(
			"[RobotManager][Start] begin start: %s, nickname is: %s, game type is:%s",
			robot_session.player.id,
			robot_session.player.user.nickname,
			game_room_config.game_type
		)
		local response = _G[module_name].Start(nil, robot_session, request)

		if (response.ret.code == 138002) then
			----处理筹码耗尽
			local chip_action_rand = math.random(1, 100)
			local delay_time = math.random(robot_chip_action.op_min_time, robot_chip_action.op_max_time)

			------------补充筹码
			--LOG(RUN, INFO).Format("[SlotsRoomInfo][Spin] robot %s, supply chip", robot_session.player.id)
			this.NotifyChip(robot_session.player.id, delay_time)

			return true
		end

		return true
	end
	return false
end

function RobotManager.InitSingleRobot(task, robot, robot_id)
	if (this.has_init == nil) then
		return
	end
	table.assign(Player:GetInitPlayer(), robot)
	robot.user.avatar = math.random(1, 10)
	robot.id = robot_id

	local robot_init_chip_conf = this.SelConfigInfo(robot, RobotInitChipConfig)
	local init_chip =
		math.floor(
		(robot_init_chip_conf.max_chip - robot_init_chip_conf.min_chip) * math.random(0, 100) / 100 +
			robot_init_chip_conf.min_chip +
			0.5
	)
	robot.character.chip = init_chip
	local robot_level_conf = this.SelConfigInfo(robot, RobotLevelConfig)
	local level = math.random(robot_level_conf.min_level, robot_level_conf.max_level)
	robot.character.level = level
	robot.character.experience = LevelConfig[level].experience_needed
	local robot_vip_conf = this.SelConfigInfo(robot, RobotVipConfig)

	robot.character.vip = robot_vip_conf.vip_level
	robot.character.vip_points = VIPConfig[robot_vip_conf.vip_level].vip_point_needed
	local location_len = #RobotLocationConfig
	local location_index = math.random(1, location_len)
	robot.user.location = RobotLocationConfig[location_index].location

	if (Base.Enviroment.pro_spec_t ~= "online") then
		robot.user.nickname = "robot" .. CommonCal.Calculate.get_name()
	else
		robot.user.nickname = CommonCal.Calculate.get_name()
	end

	local robot_age_conf = this.SelConfigInfo(robot, RobotAgeConfig)
	local age = math.random(robot_age_conf.min_age, robot_age_conf.max_age)
	robot.user.age = age

	robot.character.player_type = tonumber(ConstValue[5].value)
	------------stats信息生成-----------------
	local sel_total_spin_conf = nil
	for k, conf in ipairs(RobotTotalSpinsConfig) do
		if (level >= conf.min_level and level <= conf.max_level) then
			sel_total_spin_conf = conf
			break
		end
	end

	robot.record.total_spin = math.random(sel_total_spin_conf.min_value, sel_total_spin_conf.max_value)

	local spins_won_min =
		math.ceil(robot.record.total_spin * (RobotSpinWonConfig[1].arg + RobotSpinWonConfig[1].rand_arg_a))
	if (spins_won_min < 0) then
		spins_won_min = 0
	end
	local spins_won_max =
		math.ceil(robot.record.total_spin * (RobotSpinWonConfig[1].arg + RobotSpinWonConfig[1].rand_arg_b))
	if (spins_won_max < 0) then
		spins_won_max = 0
	end
	robot.record.spin_won = math.random(spins_won_min, spins_won_max)

	local sel_total_winnings_conf = nil
	for k, conf in ipairs(RobotTotalWinningsConfig) do
		if (level >= conf.min_level and level <= conf.max_level) then
			sel_total_winnings_conf = conf
			break
		end
	end

	local total_winnings_min = robot.record.spin_won * sel_total_winnings_conf.arg * sel_total_winnings_conf.rand_arg_a
	local total_winnings_max = robot.record.spin_won * sel_total_winnings_conf.arg * sel_total_winnings_conf.rand_arg_b
	robot.record.total_win = math.random(total_winnings_min, total_winnings_max)

	local sel_biggest_win_conf = nil
	for k, conf in ipairs(RobotBiggestWinConfig) do
		if (level >= conf.min_level and level <= conf.max_level) then
			sel_biggest_win_conf = conf
			break
		end
	end

	local random_value =
		math.floor(
		(sel_biggest_win_conf.max_value - sel_biggest_win_conf.min_value) * math.random(0, 100) / 100 +
			sel_biggest_win_conf.min_value +
			0.5
	)

	robot.record.biggest_win = math.ceil(random_value / 1000.0) * 1000

	local bonus_game_min1 = math.ceil(robot.record.total_spin * RobotBonusGameConfig[1].arg)
	if (bonus_game_min1 < 0) then
		bonus_game_min1 = 0
	end
	local bonus_game_min2 = math.ceil(robot.record.total_spin / RobotBonusGameConfig[1].rand_arg_a)
	if (bonus_game_min2 < 0) then
		bonus_game_min2 = 0
	end

	local bonus_game_min = bonus_game_min1 + bonus_game_min2

	local bonus_game_max1 = math.ceil(robot.record.total_spin * RobotBonusGameConfig[1].arg)
	if (bonus_game_max1 < 0) then
		bonus_game_max1 = 0
	end
	local bonus_game_max2 = math.ceil(robot.record.total_spin / RobotBonusGameConfig[1].rand_arg_b)
	if (bonus_game_max2 < 0) then
		bonus_game_max2 = 0
	end

	local bonus_game_max = bonus_game_max1 + bonus_game_max2
	robot.record.bonus_game = math.random(bonus_game_min, bonus_game_max)

	local free_spin_min =
		math.ceil(robot.record.total_spin * RobotFreeSpinsConfig[1].arg * RobotFreeSpinsConfig[1].rand_arg_a)
	if (free_spin_min < 0) then
		free_spin_min = 0
	end

	local free_spin_max =
		math.ceil(robot.record.total_spin * RobotFreeSpinsConfig[1].arg * RobotFreeSpinsConfig[1].rand_arg_b)
	if (free_spin_max < 0) then
		free_spin_max = 0
	end

	robot.record.free_spin = math.random(free_spin_min, free_spin_max)
end

function RobotManager.GetSession(robot_id)
	if (this.has_init == nil) then
		return
	end
	if this.robot_session_list[robot_id] ~= nil and this.robot_session_list[robot_id].player ~= nil then
		return this.robot_session_list[robot_id]
	end
	return nil
end

function RobotManager.GetSessionByIndex(session_id)
	if (this.has_init == nil) then
		return nil
	end
	if this.robot_session_vec[session_id] ~= nil then
		return this.robot_session_vec[session_id]
	end

	return nil
end

function RobotManager.InitSession(robot_id, session_id)
	if (this.has_init == nil) then
		return
	end
	local task = Task:New()
	task:Init(
		function()
			local async_request = {
				string.format("select data from slots.player_%s where id = %s", math.mod(robot_id, 16), robot_id)
			}

			local robot_session = {}

			setmetatable(
				robot_session,
				{
					__index = LuaSession
				}
			)

			robot_session.spin_time = os.time()
			robot_session.save_time = os.time()
			robot_session.id = session_id

			local name = string.format("player[%s]", robot_id)
			local proto_func = _G["DbPlayer_pb"]["DbPlayer"]
			local async_response = LuaSession:ContactJson("DatabaseClientService", task, async_request, robot_id)
			local is_new_player = false

			-- if async_response[1].row_num <= 0 then-------数据库没有数据，新建数据，并写入缓存
			LOG(RUN, INFO).Format("[SlotsRoomInfo][Deal] row num <= 0, robot_id is: %s", robot_id)

			local async_request = TableCache:GetBuildCommand(name, proto_func)
			local redis_response = LuaSession:ContactJson("CacheClientService", task, async_request, robot_id)

			----LOG(RUN, INFO).Format("[SlotsRoomInfo][Deal] row num <= 0, redis_response is: %s", Table2Str(redis_response))
			robot_session.player = TableCache:BuildTable(redis_response, name, proto_func)

			-- elseif async_response[1].row_num > 0 then

			-- 	local async_request = TableCache:GetBuildCommand(name, proto_func)

			-- 	local redis_response = LuaSession:ContactJson("CacheClientService", task, async_request, robot_id)

			-- 	if (not redis_response[2] or redis_response[2] == "")
			-- 	then
			-- 		--------没有用数据库的
			-- 		LOG(RUN, INFO).Format("[SlotsRoomInfo][Deal] content is:%s", Table2Str(async_response))
			-- 		local player_data = json.decode(async_response[1].data_set[1][1])

			-- 		local expire_time = os.time() + 600
			-- 		player_data["player["..robot_id.."].expire"] = "1|"..expire_time
			-- 		local redis_request = {
			-- 		}
			-- 		for k, v in pairs(player_data)
			-- 		do
			-- 			table.insert(redis_request, string.format("HMSET player[%s] %s %s", robot_id, k, v))
			-- 		end
			-- 		--LOG(RUN, INFO).Format("[RobotManager] HSET player: %s", Table2Str(redis_request))
			-- 		LuaSession:ContactJson("CacheClientService", task, redis_request, robot_id)

			-- 		local async_request = TableCache:GetBuildCommand(name, proto_func)

			-- 		local local_redis_response = LuaSession:ContactJson("CacheClientService", task, async_request, robot_id)

			-- 		robot_session.player = TableCache:BuildTable(local_redis_response, name, proto_func)
			-- 		--LOG(RUN, INFO).Format("[SlotsRoomInfo][Deal]11 robot_session.player.id is: %s", robot_session.player.id)
			-- 	else
			-- 		--------用缓存的
			-- 		robot_session.player = TableCache:BuildTable(redis_response, name, proto_func)
			-- 		LOG(RUN, INFO).Format("[SlotsRoomInfo][Deal]22 robot_session.player.id is: %s", robot_session.player.id)
			-- 	end
			-- end

			if robot_session.player.id and robot_session.player.id > 0 then
				LOG(RUN, INFO).Format("[Account][Login]old player %s load from cache. ", robot_session.player.id)
				--LOG(RUN, INFO).Format("[Account][Login] player %s redis facebook_id is: %s, google_id is: %s, nickname is: %s",  player_id, session.player.account.facebook_id, session.player.account.google_id, session.player.user.nickname)
				for module_key, module_value in pairs(Player:GetInitPlayer()) do
					LOG(RUN, INFO).Format(
						"[RobotManager][InitSession] module_key is: %s, module_value is: %s",
						module_key,
						Table2Str(module_value)
					)
					if not robot_session.player[module_key] then
						--LOG(RUN, INFO).Format("[RobotManager][InitSession]11 module_key is: %s, module_value is: %s", module_key, Table2Str(module_value))
						robot_session.player[module_key] = module_value
					elseif type(module_value) == "table" then
						for item_key, item_value in pairs(module_value) do
							if
								not robot_session.player[module_key][item_key] or
									type(robot_session.player[module_key][item_key]) ~= type(item_value)
							 then
								--LOG(RUN, INFO).Format("[RobotManager][InitSession]22 module_key is: %s, module_value is: %s", module_key, Table2Str(module_value))
								robot_session.player[module_key][item_key] = item_value
							end
						end
					elseif type(module_value) ~= type(robot_session.player[module_key]) then
						--LOG(RUN, INFO).Format("[RobotManager][InitSession]33 module_key is: %s, module_value is: %s", module_key, Table2Str(module_value))
						robot_session.player[module_key] = module_value
					end
				end
			end
			local robot = robot_session.player
			this.InitSingleRobot(task, robot, robot_id)

			robot_session.player.game_type = 0

			robot_session.status_time = os.time()

			robot_session.player.expire = os.time() + 600

			local commands = TableCache:GetActionCommand(robot_session.player)
			LuaSession:ContactJson("CacheClientService", task, commands, robot_id)

			this.robot_session_list[robot_id] = robot_session
			this.robot_session_vec[robot_session.id] = robot_session

			-- local register_channel_id = {"Global", "Hall"}
			-- local async_request = {
			-- 	header = {
			-- 		router = "AsyncRequest",
			-- 		service_name = "NotificationClientService",
			-- 		task_id = task.id,
			-- 		module_id = "Distributor",
			-- 		message_id = "Distributor_Register_Request",
			-- 	},
			-- 	session_id = robot_session.id,
			-- 	player_id = robot_session.player.id,
			-- 	channel_id = register_channel_id,
			-- 	player_type = robot_session.player.character.player_type,
			-- }

			-- local async_response = robot_session:ContactPacket(task, async_request)

			local async_request = {
				[1] = string.format("hmset id_to_token %s robot%s", robot_id, robot_id),
				[2] = string.format("hmset token_to_id robot%s %s", robot_id, robot_id)
			}
			local async_response = LuaSession:ContactJson("CacheClientService", task, async_request, robot_id)

			-- local async_request = {
			-- 	header = {
			-- 		router = "AsyncRequest",
			-- 		service_name = "ManagerClientService",
			-- 		task_id = task.id,
			-- 		module_id = "PlayerWatcher",
			-- 		message_id = "PlayerWatcher_Register_Request",
			-- 	},
			-- 	session_id = robot_session.id,
			-- 	player_id = robot_session.player.id,
			-- 	player_type = robot_session.player.character.player_type,
			-- }

			-- local dropping = 0
			-- while dropping == 0 do
			-- 	local async_response = robot_session:ContactPacket(task, async_request)
			-- 	if async_response.ret.code ~= 0 then
			-- 		break
			-- 	end
			-- 	dropping = async_response.dropping
			-- end
		end
	)
	task:Start()
end
