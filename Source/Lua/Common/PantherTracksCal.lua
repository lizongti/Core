module("PantherTracksCal", package.seeall)

Calculate = {
	CountDown = function(player, json_value)
		----计算倒计时
		local start_date = string.split(ConstValue[16].value, ":")
		local end_date = string.split(ConstValue[17].value, ":")

		local start_time = os.time({year = start_date[1], month = start_date[2], day = start_date[3], hour = start_date[4], min = start_date[5], sec = start_date[6]})
		local end_time = os.time({year = end_date[1], month = end_date[2], day = end_date[3], hour = end_date[4], min = end_date[5], sec = end_date[6]})

		local refresh_time = tonumber(ConstValue[15].value)
		local cur_time = os.time()

		local distance_start_time = start_time - cur_time
		if (distance_start_time < 0) then
			distance_start_time = 0
		end

		local distance_end_time = end_time - cur_time
		if (distance_end_time < 0) then
			distance_end_time = 0
		end	

		json_value.distance_start_time = distance_start_time
		json_value.distance_end_time = distance_end_time

		if (json_value.distance_start_time > 0 or json_value.distance_end_time == 0 ) then
			---没有到期或期限已经过期或刷新时间到,清空
			LOG(RUN, INFO).Format("[PantherTracks][Info] player:%s, task is over!", player.id)
			Calculate.ResetPantherTracks(json_value, PanthersTracksInfoConfig)
		end

		----计算下次刷新时间
		local refresh_num = math.floor((end_time - start_time) / refresh_time + 0.5) --可以刷新几次

		LOG(RUN, INFO).Format("[PantherTracks][Info] player:%s, end_time: %s, start_time:%s, refresh_num:%s", player.id, end_time, start_time, refresh_num)

		local next_refresh_time = 0
		for index = 1, refresh_num, 1 do
			json_value.distance_refresh_time = start_time + refresh_time * index - cur_time

			next_refresh_time = start_time + refresh_time * index
			if (json_value.distance_refresh_time < 0) then
				json_value.distance_refresh_time = 0
			end
			if (json_value.distance_refresh_time > 0) then
				break
			end
		end

		---刷新时间变化了，重新刷新
		if (json_value.refresh_time == nil or next_refresh_time ~= json_value.refresh_time) then
			json_value.refresh_time = next_refresh_time
			Calculate.ResetPantherTracks(json_value, PanthersTracksInfoConfig)
		end
		LOG(RUN, INFO).Format("[PantherTracks][Info] player:%s, end:%s", player.id, json_value.distance_refresh_time)

	end,
	------更新进度并通知客户端
	UpdatePantherTracks = function(session, player, total_bet)
		local json_value = json.decode(player.task_info.panther_tracks)
		local info = json_value.info
		if (json_value.info == nil) then
			return
		end
		if (json_value.difficulty_type == nil) then
			return
		end
		if (json_value.difficulty_type == 0) then
			return
		end

		if (player.character.level < tonumber(ConstValue[20].value)) then
			return
		end

		local step_info = info[json_value.difficulty_type].step_info
		local award_points= 0

		for step_type, detail_info in ipairs(step_info) do
			---按顺序计算点数
			if (detail_info.status == 0) then
				local base_chip = 0
				for k, config in ipairs(PanthersTracksCollectConfig) do
					if (config.task_difficult == json_value.difficulty_type and config.collect_step == step_type) then
						base_chip = config.base_chip
					end
				end
				---计算点数
				LOG(RUN, INFO).Format("[PantherTracks][UpdatePantherTracks] total_bet: %s, base_chip:%s", total_bet, base_chip)
				local points = total_bet / base_chip
				local random_value = points * 100
				if (random_value <= 100) then
					---计算获取的概率
					local cur_value = math.random_ext(player, 100)
					if (cur_value <= random_value) then
						award_points = 1
					end
				else
					award_points = points
				end
				break
			end
		end

		LOG(RUN, INFO).Format("[PantherTracks][UpdatePantherTracks] award_points: %s", award_points)

		local cur_points = step_info[1].cur_points
		cur_points = cur_points + award_points

		local finish_info = {}
		----------获取奖励，更新进度
		local is_all_finished = true
		for step_type, detail_info in ipairs(step_info) do
			detail_info.cur_points = cur_points
			detail_info.chips = 0
			if (detail_info.cur_points >= detail_info.end_points) then
				if (detail_info.status == 0) then
					Player:Obtain(player, {"Chip", detail_info.award}, Reason.PANTHER_TRACKS_CHIP_OBTAIN())
					detail_info.status = 1

					detail_info.chips = detail_info.award

					table.insert(finish_info, step_type)
				end
			else
				is_all_finished = false
			end
		end

		if (is_all_finished) then
			info[json_value.difficulty_type].status = 1
		end

		Calculate.CountDown(player, json_value)

		player.task_info.panther_tracks = json.encode(json_value)

		local res_panther_tracks_info = {
			difficulty_type = json_value.difficulty_type,
			info = json.encode(json_value.info),
			distance_start_time = json_value.distance_start_time,
			distance_end_time = json_value.distance_end_time,
			distance_refresh_time = json_value.distance_refresh_time
		}

		LOG(RUN, INFO).Format("[PantherTracks][UpdatePantherTracks] res_panther_tracks_info: %s", Table2Str(res_panther_tracks_info))

		----通知客户端
		if (award_points > 0) then
			session:WriteRouterPacket({
				header = {
					router = "Notice",
					module_id = "PantherTracks",
					message_id = "PantherTracks_Info_Notice"
				},
				panther_tracks_info = res_panther_tracks_info,
				award_points = award_points,
				finish_info = json.encode(finish_info)
			})
		end
	end,

	----全部从新开始
	ResetPantherTracks = function(json_value, info_config)
		json_value.difficulty_type = 0--没有选择人物难度
		--json_value.refresh_time = os.time()
		local info = {}

		for k, single_conf in ipairs(info_config) do
			if (info[single_conf.task_difficult] == nil) then
				info[single_conf.task_difficult] = {}
				info[single_conf.task_difficult].difficulty_type = single_conf.task_difficult
				info[single_conf.task_difficult].total_award = 0---先为0，在下面累加
				info[single_conf.task_difficult].status = 0
				info[single_conf.task_difficult].step_info = {}
			end

			local step_info = {}
			step_info.step_type = single_conf.task_step
			step_info.award = single_conf.chips_prize
			step_info.end_points = single_conf.sum_collect_points
			step_info.cur_points = 0
			
			if (single_conf.task_step > 1) then
				step_info.start_points = info_config[k - 1].sum_collect_points
			else
				step_info.start_points = 0
			end
			step_info.status = 0
			info[single_conf.task_difficult].total_award = info[single_conf.task_difficult].total_award + step_info.award --累加

			info[single_conf.task_difficult].step_info[step_info.step_type] = step_info
		end

		json_value.info = info
	end,

	---只更新和配置文件相关的
	InitPantherTracks = function(json_value, info_config)
		local info = json_value.info
		for k, single_conf in ipairs(info_config) do
			local step_info = info[single_conf.task_difficult].step_info[single_conf.task_step]
			step_info.award = single_conf.chips_prize
			step_info.end_points = single_conf.sum_collect_points

			if (single_conf.task_step > 1) then
				step_info.start_points = info_config[k - 1].sum_collect_points
			else
				step_info.start_points = 0
			end			
		end
	end,

}