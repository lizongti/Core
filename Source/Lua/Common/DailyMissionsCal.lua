module("DailyMissionsCal", package.seeall)

Calculate = {
	GetDailyMissionsAward = function(player, reward_type, json_value)
		local chips = 0
		local mission_points = 0
		local task_level = reward_type
		local cur_missions_info = json_value.missions_info[task_level]
		local ret = Return.OK()

		if (task_level <= 50) then
			
			if (cur_missions_info.cur_value < cur_missions_info.valid_value) then
				ret = Return.GAME_PLAYER_CHIP_NOT_ENOUGH()
				return ret, 0, 0			
			end

			if (cur_missions_info.status ~= 0) then
				ret = Return.GAME_PLAYER_CHIP_NOT_ENOUGH()
				return ret, 0, 0			
			end
			cur_missions_info.status = 1

			local daily_missions_conf = cur_missions_info.daily_missions_conf
			local sel_task = cur_missions_info.task_conf[1]
			chips = math.floor(cur_missions_info.total_bet_amount * sel_task.award_percent / 1000) * 1000 
			cur_missions_info.total_bet_amount = 0
			mission_points = sel_task.points		
		end
	
		if (task_level == 51) then
			if (json_value.mission_points < DailyMissionsProgressConfig[1].progressone_points) then
				ret = Return.GAME_PLAYER_CHIP_NOT_ENOUGH()
				return ret, 0, 0
			end
			json_value.gift_box_status = 2--已经领取
			chips = math.floor(json_value.progressone_chips * DailyMissionsProgressConfig[1].progressone_chips)
		elseif (task_level == 52) then
			if (json_value.mission_points < DailyMissionsProgressConfig[1].progresstwo_points) then
				ret = Return.GAME_PLAYER_CHIP_NOT_ENOUGH()
				return ret, 0, 0
			end
			json_value.big_treasure_box_status = 2--已经领取
	
			if (json_value.progresstwo_chips == nil) then
				json_value.progresstwo_chips = 0
			end
			chips = math.floor(json_value.progresstwo_chips * DailyMissionsProgressConfig[1].progresstwo_chips)
		end

		return ret, chips, mission_points
	end,

	Refresh = function (player, json_value, content)
		if (Calculate.IsLocked(player)) then
			return
		end

		local week_status = content.week_status
		local daily_status = content.daily_status----0不刷新,1刷新，2服务器重启了，需要从缓存中取出
		local daily_missions = content.daily_missions
		local daily_refresh_time = content.daily_refresh_time
		local week_refresh_time = content.week_refresh_time
		
		if (daily_status == 1) then--daily
			json_value.missions_info = {}
			for task_level, info in ipairs(daily_missions) do
				json_value.missions_info[task_level] = {task_level = info.task_level, task_type = info.task_type, status = 0}
				local pre_task_status = 1
				if (task_level > 1) then
					pre_task_status = json_value.missions_info[task_level - 1].status
				end
				DailyMissionsCal.Calculate.UpdateDailyMissionsJs(player, pre_task_status, json_value.missions_info[task_level], DailyMissionsInfoConfig[info.task_type].task_name, 0, nil, 0)
			end
			json_value.daily_refresh_time = daily_refresh_time
		end
	
		if (week_status == 1) then
			json_value.week_refresh_time = week_refresh_time
			json_value.mission_points = 0
			json_value.gift_box_status = 0
			json_value.big_treasure_box_status = 0
		end
	end,

	InitResMission = function(level, mission_info, conf)
		local res_mission = {}

		local valide_info = mission_info.valide_info
		local desc = conf.desc
		for k, v in pairs(valide_info) do
			desc = string.gsub(desc, "%["..k.."%]", string.get_readable_number(v))
		end
		res_mission.task_des = desc
		res_mission.cur_value = mission_info.cur_value
		res_mission.valid_value = mission_info.valid_value
		res_mission.status = mission_info.status
		return res_mission
	end,

	GetDailyMissionsInfo = function(json_value, level)
		local cur_time = os.time()
		local missions = {}

		if (json_value.mission_points >DailyMissionsProgressConfig[1].progresstwo_points) then
			json_value.mission_points = DailyMissionsProgressConfig[1].progresstwo_points
		end

		if (json_value.big_treasure_box_status == 0) then
			if (json_value.mission_points >= DailyMissionsProgressConfig[1].progresstwo_points) then
				json_value.big_treasure_box_status = 1
	
			end
		end

		if (json_value.gift_box_status == 0) then
			if (json_value.mission_points >= DailyMissionsProgressConfig[1].progressone_points) then
				json_value.gift_box_status = 1
			end
		end
	
		local cur_date = os.date("*t", os.time())
		local daily_refresh_date = os.date("*t", json_value.daily_refresh_time)
		local limit_mission_times =
		os.time(
			{
				year = daily_refresh_date.year,
				month = daily_refresh_date.month,
				day = daily_refresh_date.day + 1,
				hour = 3,
				min = 0,
				sec = 0
			}
		)

		local left_mission_times = limit_mission_times - cur_time

		local cur_day = cur_date.wday
		if (cur_day == 1) then  ---周日的wday=1,周六的wday=7
			cur_day = 8
		end

		local left_days = 8 - cur_day
		
		-------json_value.missions_info的每等级只会出现一个任务
		for task_level, info in ipairs(json_value.missions_info) do
			for k, v in ipairs(DailyMissionsInfoConfig) do
				if (v.task_type == info.task_type) then
					local res_mission = DailyMissionsCal.Calculate.InitResMission(level, info, v)
					if (task_level > 1) then
						local is_all_finished = true
						for pre_level = 1, task_level - 1, 1 do
							if (missions[pre_level].status == 0) then ---说明前面任务没有领取
								is_all_finished = false
							end
						end
						if (is_all_finished) then
							res_mission.is_lock = 0
						else
							res_mission.is_lock = 1
						end
					else
						res_mission.is_lock = 0
					end

					missions[task_level] = res_mission
				end 
			end
		end
		
		local content = {}
		content.mission_points = json_value.mission_points
		content.total_mission_points = tonumber(ConstValue[12].value)
		content.left_days = left_days
		content.gift_box_status = json_value.gift_box_status
		content.big_treasure_box_status = json_value.big_treasure_box_status
		content.left_mission_times = left_mission_times
		content.missions = missions

		return content
	end,

	GetFinishedNum = function(res_content)
		local finished_num = 0

		for task_level, mission_info in pairs(res_content.missions) do
			if (mission_info.valid_value ~= mission_info.cur_value) then
				finished_num = finished_num + 1 
			end
		end
		return finished_num
	end, 

	IsLocked = function(player)
		if (player.character.level < tonumber(ConstValue[18].value)) then
			return true
		end
		return false
	end,

	UpdateGameDailyMissions = function(session, player, amount, chip_cost, total_win_chip, is_free_spin, game_type, free_spin_bouts, cur_status)
		if (Calculate.IsLocked(player)) then
			return
		end

		local game_room_config = GameRoomConfig[game_type]
		
		local prize_conf =  _G[GameMapConfig[game_type].prize_config]
		local max_bet_amount_conf = nil
		local game_bet_amount_conf = _G[GameMapConfig[game_type].bet_amount_config]
		for k, v in ipairs(game_bet_amount_conf) do
			if (player.character.level >= v.required_level) then
				max_bet_amount_conf = v
			end
		end
	
		local lineNum = LineNum[game_type]()

		chip_cost = amount *  lineNum

		if (not is_free_spin) then
			if (amount == max_bet_amount_conf.single_amount) then
				DailyMissionsCal.Calculate.UpdateDailyMissions(session, player, "MaxBetSpin", 1,  {[1] = 1}, chip_cost)
			end
			DailyMissionsCal.Calculate.UpdateDailyMissions(session, player, "SpinTimes", 1, {[1] = 1}, chip_cost)
		end
	
		if (chip_cost > 0) then

			DailyMissionsCal.Calculate.UpdateDailyMissions(session, player, "BetAward", chip_cost, {[1] = chip_cost}, chip_cost)
		end

		if (is_free_spin) then
			if (total_win_chip > 0) then
				DailyMissionsCal.Calculate.UpdateDailyMissions(session, player, "WinInFreeSpins", total_win_chip, {[1] = total_win_chip}, chip_cost)
			end
		end
	
		if (free_spin_bouts > 0) then
			-- DailyMissionsCal.Calculate.UpdateDailyMissions(session, player, "HitFreeSpins", 1, {[1] = 1}, chip_cost)
		end
	
		if (total_win_chip > 0) then
			DailyMissionsCal.Calculate.UpdateDailyMissions(session, player, "WinAward", total_win_chip, {[1] = total_win_chip}, chip_cost)

			DailyMissionsCal.Calculate.UpdateDailyMissions(session, player, "WinAwardInTimes", total_win_chip, {[1] = 1, [2] = total_win_chip}, chip_cost)

			DailyMissionsCal.Calculate.UpdateDailyMissions(session, player, "WinAwardEachTime", total_win_chip, {[1] = 1}, chip_cost)
		end
	
		local can_ecpic_win = false
		if (cur_status ~= nil) then
			LOG(RUN, INFO).Format("[UpdateGameDailyMissions] player:%s, cur_status: %s", player.id, cur_status)
		end
		if (cur_status == GameStatusDefine.AllTypes.ClassicSpinGame) then
			can_ecpic_win = true
		elseif (chip_cost > 0) then
			can_ecpic_win = true
		end
		if (can_ecpic_win) then
			if ((total_win_chip / (amount * lineNum)) >= prize_conf[3].min_multiple) then
				DailyMissionsCal.Calculate.UpdateDailyMissions(session, player, "HitEpicWin", 1, {[1] = 1}, chip_cost)
			end
		end
	end,

	--------value用于进度，value_info用于任务描述
	UpdateDailyMissions = function (session, player, task_name, value, value_info, bet_amount)
		if (Calculate.IsLocked(player)) then
			return
		end

		local json_value = json.decode(player.task_info.daily_missions)

		if (json_value.missions_info == nil) then
			return
		end

		local need_notice = false

		for task_level, info in pairs(json_value.missions_info) do
			local pre_task_status = 1
			if (task_level > 1) then
				pre_task_status = json_value.missions_info[task_level - 1].status
			end
			if (Calculate.UpdateDailyMissionsJs(player, pre_task_status, info, task_name, value, value_info, bet_amount)) then
				need_notice = true
			end
		end

		if need_notice then
			
			local res_content = DailyMissionsCal.Calculate.GetDailyMissionsInfo(json_value, player.character.level)

			local finished_num = Calculate.GetFinishedNum(res_content)

			-- LOG(RUN, INFO).Format("[DailyMissionsCal][UpdateDailyMissions] id:%s, need_notice begin: %s", player.id, task_name)
			local daily_missions_info = {
				mission_points = res_content.mission_points,
				total_mission_points = res_content.total_mission_points,
				left_days = res_content.left_days,
				gift_box_status = res_content.gift_box_status,
				big_treasure_box_status = res_content.big_treasure_box_status,
				left_mission_times = res_content.left_mission_times,
				missions = json.encode(res_content.missions),
			}
			session:WriteRouterPacket({
				header = {
					router = "Notice",
					module_id = "DailyMissions",
					message_id = "DailyMissions_Info_Notice"
				},
				daily_missions_info = daily_missions_info,
				finished_num = finished_num
			})
			-- LOG(RUN, INFO).Format("[DailyMissionsCal][UpdateDailyMissions] id:%s, daily_missions_info end: %s", player.id, Table2Str(daily_missions_info))
		end
		player.task_info.daily_missions = json.encode(json_value)
	end,

	ResetInvalidTask = function(conf, missions_info)
		local value_info = missions_info.value_info
		local valide_info = missions_info.valide_info

		if (conf.task_name == "WinAwardInTimes") then
			----在spin valide_info["value1"]次数，获得的累加奖励没有达到 valide_info["value2"]就清空
			if (value_info[1] >= valide_info["value_a"] and value_info[2] < valide_info["value_b"]) then
				missions_info.cur_value = 0
				missions_info.value_info = nil
			end
		end
	end,

	switch = {
		[1] = function(player, sel_task)
			local valid_value = 0
			local valide_info = {}
			valid_value = math.floor(sel_task.value)
			valide_info["value"] = valid_value
			-- LOG(RUN, INFO).Format("[DailyMissionsCal][switch] 1 valide value: %s", valid_value)
			return valid_value, valide_info
		end,
		[2] = function(player, sel_task)
			local valid_value = 0
			local valide_info = {}
			valid_value = math.floor(player.character.chip * sel_task.value)
			if (valid_value < sel_task.value_min) then
				valid_value = sel_task.value_min
			elseif (valid_value > sel_task.value_max) then
				valid_value = sel_task.value_max
			end
			valide_info["value"] = valid_value
			-- LOG(RUN, INFO).Format("[DailyMissionsCal][switch] 2 valide value: %s", valid_value)
			return valid_value, valide_info
		end,
		----------总赢取筹码表示进度
		[3] = function(player, sel_task)
			local valid_value1 = 0----限定要赢取的总赢取筹码
			local valid_value2 = 0----限定次数
			local valide_info = {}
			valid_value1 = math.floor(player.character.chip * sel_task.value_a)
			if (valid_value1 < sel_task.value_a_min) then
				valid_value1 = sel_task.value_a_min
			elseif (valid_value1 > sel_task.value_a_max) then
				valid_value1 = sel_task.value_a_max
			end

			valid_value2 = sel_task.value_b
			valide_info["value_a"] = valid_value1
			valide_info["value_b"] = valid_value2
			-- LOG(RUN, INFO).Format("[DailyMissionsCal][switch] 3 valide_info: %s", Table2Str(valide_info))
			return valid_value1, valide_info
		end,
		------------次数表示进度
		[4] = function(player, sel_task)
			local valid_value1 = 0----限定要赢取的总赢取筹码
			local valid_value2 = 0----限定次数
			local valide_info = {}
			valid_value1 = math.floor(player.character.chip * sel_task.value_a)
			if (valid_value1 < sel_task.value_a_min) then
				valid_value1 = sel_task.value_a_min
			elseif (valid_value1 > sel_task.value_a_max) then
				valid_value1 = sel_task.value_a_max
			end

			valid_value2 = sel_task.value_b
			valide_info["value_a"] = valid_value1
			valide_info["value_b"] = valid_value2
			-- LOG(RUN, INFO).Format("[DailyMissionsCal][switch] 4 valide_info: %s", Table2Str(valide_info))
			return valid_value2, valide_info
		end,
	},

	GetMissionValue = function(player, daily_missions_conf, task_conf) 
		local sel_task = task_conf[1]
		
		local valid_value = 0
		local valide_info = {}

		if (daily_missions_conf.task_name == "WinAward") then
			valid_value, valide_info = Calculate.switch[2](player, sel_task)
		elseif (daily_missions_conf.task_name == "BetAward") then
			valid_value, valide_info = Calculate.switch[2](player, sel_task)
		elseif (daily_missions_conf.task_name == "WinAwardInTimes") then
			valid_value, valide_info = Calculate.switch[3](player, sel_task)
		elseif (daily_missions_conf.task_name == "WinAwardEachTime") then
			valid_value, valide_info = Calculate.switch[4](player, sel_task)
			-- valid_value = conf.value.value2 --次数 
			-- valide_info["value1"] = math.floor(player.character.chip * conf.value.value1.chip_multiple) ---达到次值才能将次数加1
			-- valide_info["value2"] = conf.value.value2 --次数
		elseif (daily_missions_conf.task_name == "WinInFreeSpins") then
			valid_value, valide_info = Calculate.switch[2](player, sel_task)
		else
			valid_value, valide_info = Calculate.switch[1](player, sel_task)
		end
		-- LOG(RUN, INFO).Format("[DailyMissionsCal][UpdateDailyMissions]11cur_missions_info is:%s", Table2Str(cur_missions_info))
		return valid_value, valide_info
	end,


	----更新玩家的任务进度
	UpdateDailyMissionsJs = function(player, pre_task_status, cur_missions_info, task_name, value, value_info, bet_amount)
		-- LOG(RUN, INFO).Format("[DailyMissionsCal][UpdateDailyMissions] begin task_name: %s", task_name)
		-- LOG(RUN, INFO).Format("[DailyMissionsCal][UpdateDailyMissions] begin missions_info: %s", Table2Str(cur_missions_info))

		----前一个任务完成前不能升级,value为0表示在初始化
		if (value > 0) then
			if (pre_task_status == 0) then---前一个任务没有领取
				return false
			end
		end
	
		local need_notice = false
		for k, conf in pairs(DailyMissionsInfoConfig) do
			--LOG(RUN, INFO).Format("[DailyMissionsCal][UpdateDailyMissions] info is:%s, conf is:%s", Table2Str(info), Table2Str(conf))

			if (conf.task_type == cur_missions_info.task_type) then
				if (cur_missions_info.task_conf == nil) then
					cur_missions_info.task_conf = {}
					cur_missions_info.daily_missions_conf = conf
					local task_conf = _G["DailyMissions"..task_name.."Config"]
					for task_k, task_info in ipairs(task_conf) do
						if (task_info.task_level == cur_missions_info.task_level) then
							table.insert(cur_missions_info.task_conf, task_info)
						end
					end
				end

				local sel_task = cur_missions_info.task_conf[1]
				if (task_name == nil or conf.task_name == task_name) then
					if (cur_missions_info.cur_value == nil) then
						cur_missions_info.cur_value = 0
					end

					if (cur_missions_info.valid_value == nil) then
						cur_missions_info.valid_value = 0
					end

					if (cur_missions_info.total_bet_amount == nil) then
						cur_missions_info.total_bet_amount = 0
					end
					--LOG(RUN, INFO).Format("[DailyMissionsCal][UpdateDailyMissions] 222222222222222")
					if (value == 0 or cur_missions_info.valide_info == nil) then
						cur_missions_info.cur_value = 0
						cur_missions_info.value_info = nil

						cur_missions_info.total_bet_amount = 0
						
						local valid_value, valide_info = DailyMissionsCal.Calculate.GetMissionValue(player, cur_missions_info.daily_missions_conf, cur_missions_info.task_conf)
						cur_missions_info.valid_value = valid_value
						cur_missions_info.valide_info = valide_info
						
					end

					-- LOG(RUN, INFO).Format("[DailyMissionsCal][UpdateDailyMissions]11cur_missions_info is:%s", Table2Str(cur_missions_info))
					local old_value = cur_missions_info.cur_value

					if (cur_missions_info.value_info == nil) then
						cur_missions_info.value_info = {}
						for index = 1, 5, 1 do
							cur_missions_info.value_info[index] = 0
						end
					end
					if (task_name == "WinAwardEachTime") then
						---------赢取的奖励达到cur_missions_info.valide_info[1],次数累加
						-- LOG(RUN, INFO).Format("[DailyMissionsCal][UpdateDailyMissions]33 value is:%s, value_info is:%s", value, Table2Str(value_info))
						if (value >= cur_missions_info.valide_info["value_a"]) then
							if (cur_missions_info.cur_value < cur_missions_info.valid_value) then
								-- LOG(RUN, INFO).Format("[DailyMissionsCal][UpdateDailyMissions]11total_bet_amount is:%s, bet_amount is:%s", cur_missions_info.total_bet_amount, bet_amount)
								cur_missions_info.total_bet_amount = cur_missions_info.total_bet_amount + bet_amount
								-- LOG(RUN, INFO).Format("[DailyMissionsCal][UpdateDailyMissions]22total_bet_amount is:%s, bet_amount is:%s", cur_missions_info.total_bet_amount, bet_amount)
							end
							----次数都加1
							cur_missions_info.cur_value = cur_missions_info.cur_value + 1

							if (value_info ~= nil) then
								for k, v in pairs(value_info) do
									cur_missions_info.value_info[k] = value_info[k] + v
								end
							end
							

						end
					else
						if (cur_missions_info.cur_value < cur_missions_info.valid_value) then
							-- LOG(RUN, INFO).Format("[DailyMissionsCal][UpdateDailyMissions]11total_bet_amount is:%s, bet_amount is:%s", cur_missions_info.total_bet_amount, bet_amount)
							cur_missions_info.total_bet_amount = cur_missions_info.total_bet_amount + bet_amount
							-- LOG(RUN, INFO).Format("[DailyMissionsCal][UpdateDailyMissions]22total_bet_amount is:%s, bet_amount is:%s", cur_missions_info.total_bet_amount, bet_amount)
						end
						cur_missions_info.cur_value = cur_missions_info.cur_value + value
						if (value_info ~= nil) then
							for k, v in pairs(value_info) do
								cur_missions_info.value_info[k] = value_info[k] + v
							end
						end

					end

					-- LOG(RUN, INFO).Format("[DailyMissionsCal][UpdateDailyMissions]22 cur_missions_info is:%s", Table2Str(cur_missions_info))
					Calculate.ResetInvalidTask(conf, cur_missions_info)
					-- LOG(RUN, INFO).Format("[DailyMissionsCal][UpdateDailyMissions]33 cur_missions_info is:%s", Table2Str(cur_missions_info))

					if (cur_missions_info.cur_value > cur_missions_info.valid_value) then
						cur_missions_info.cur_value = cur_missions_info.valid_value
					end
					
					if (old_value ~= cur_missions_info.cur_value) then
						need_notice = true
					end
				end
				

			end

			
		end
		--LOG(RUN, INFO).Format("[DailyMissionsCal][UpdateDailyMissions] end missions_info: %s", Table2Str(cur_missions_info))

		return need_notice

	end,
}