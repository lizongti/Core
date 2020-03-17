require "Base/TableDefine"
require "Base/CacheDefine"
require "Common/CommonCal"
--require "Common/ClimbSlideCal"
module("ClimbSlide", package.seeall)

---返回活动状态
Collect = function ( _M, session, request )
	local response = {header = {router = "Response"}}
	local task = session.task
	local player = session.player

	if (player == nil) then
		response.ret = Return.PLAYER_NOT_FOUND()
		return response
	end

	local activity_type = ActivityDefine.AllTypes.ClimbSlide
	local count_down_info = ActivityCal.Calculate.CountDown(activity_type)
	if (count_down_info.distance_start_time > 0 or count_down_info.distance_end_time == 0 ) then
		---没有到期或期限已经过期
		response.ret = Return.CLIMB_SLIDE_EXPIRED()
		return response
	end

	local cur_activity = ClimbSlideCal.Calculate.GetActivityInfo(session, activity_type)
	if (cur_activity.init_config == nil) then
		LOG(RUN, INFO).Format("[ClimbSlide][Collect] player:%s, not opent", player.id)
		response.ret = Return.CLIMB_SLIDE_EXPIRED()
		return response
	end
	
	ClimbSlideCal.Calculate.AddExternSpins(session)

	local rs_activity_list = table.DeepCopy(cur_activity.activity_list)
	for k, v in ipairs(rs_activity_list) do
		v.prize = ClimbSlideCal.Calculate.GetPrize(cur_activity.activity_list[k])
	end

	response.ret = Return.OK()
	response.climb_slide_info = {
		collect_amount = cur_activity.collect_amount,
		total_collect_amount = cur_activity.total_collect_amount,
		spin_count = cur_activity.spin_count,
		sel_level = cur_activity.sel_level,
		activity_list = json.encode(rs_activity_list),
		final_prize = cur_activity.final_prize
	}

	LOG(RUN, INFO).Format("[ClimbSlide][Collect] player:%s, response: %s", player.id, Table2Str(response))
	return response
end

FinalCollect = function ( _M, session, request )
	local response = {header = {router = "Response"}}
	local task = session.task
	local player = session.player

	if (player == nil) then
		response.ret = Return.PLAYER_NOT_FOUND()
		return response
	end
	LOG(RUN, INFO).Format("[ClimbSlide][FinalCollect] player:%s, request: %s", player.id, Table2Str(request))

	local activity_type = ActivityDefine.AllTypes.ClimbSlide
	local count_down_info = ActivityCal.Calculate.CountDown(activity_type)
	if (count_down_info.distance_start_time > 0 or count_down_info.distance_end_time == 0 ) then
		---没有到期或期限已经过期
		response.ret = Return.CLIMB_SLIDE_EXPIRED()
		return response
	end

	local cur_activity = ClimbSlideCal.Calculate.GetActivityInfo(session, activity_type)
	if (cur_activity.init_config == nil) then
		LOG(RUN, INFO).Format("[ClimbSlide][Collect] player:%s, not opent", player.id)
		response.ret = Return.CLIMB_SLIDE_EXPIRED()
		return response
	end
	
	ClimbSlideCal.Calculate.AddExternSpins(session)

	for k, v in ipairs(cur_activity.activity_list) do
		if (cur_activity.activity_list[k].status ~= 2) then
			response.ret = Return.CLIMB_SLIDE_EXPIRED()
			return response
		end
	end

	---给最终奖励
	response.final_prize = cur_activity.final_prize
	Player:Obtain(player, {"Chip", cur_activity.final_prize}, Reason.CLIMB_SLIDE_CHIP_OBTAIN())

	response.ret = Return.OK()
	response.player = {
        character = {
            chip = player.character.chip,
        }
    }

	LOG(RUN, INFO).Format("[ClimbSlide][FinalCollect] player:%s, response: %s", player.id, Table2Str(response))
	return response
end

Booster = function ( _M, session, request )
	local response = {header = {router = "Response"}}
	local task = session.task
	local player = session.player

	if (player == nil) then
		
		response.ret = Return.PLAYER_NOT_FOUND()
		return response
	end

	LOG(RUN, INFO).Format("[ClimbSlide][Booster] player:%s, request: %s", player.id, Table2Str(request))
	local status, climb_slide_start_buf_time, climb_slide_end_buf_time, climb_slide_buff_time = ClimbSlideCal.Calculate.GetBooster(session)

	
	response.stamp_start_time = climb_slide_start_buf_time
	response.stamp_end_time = climb_slide_end_buf_time
	response.cutdown_time = climb_slide_buff_time

	response.status = status
	response.ret = Return.OK()


	LOG(RUN, INFO).Format("[ClimbSlide][Booster] player:%s, response: %s", player.id, Table2Str(response))
	return response
end

MapInfo = function ( _M, session, request )
	local response = {header = {router = "Response"}}
	local task = session.task
	local player = session.player

	if (player == nil) then
		response.ret = Return.PLAYER_NOT_FOUND()
		return response
	end

	local activity_type = ActivityDefine.AllTypes.ClimbSlide
	local count_down_info = ActivityCal.Calculate.CountDown(activity_type)
	if (count_down_info.distance_start_time > 0 or count_down_info.distance_end_time == 0 ) then
		---没有到期或期限已经过期
		response.ret = Return.CLIMB_SLIDE_EXPIRED()
		return response
	end

	local cur_activity = ClimbSlideCal.Calculate.GetActivityInfo(session, activity_type)
	if (cur_activity.init_config == nil) then
		LOG(RUN, INFO).Format("[ClimbSlide][Collect] player:%s, not opent", player.id)
		response.ret = Return.CLIMB_SLIDE_EXPIRED()
		return response
	end
	ClimbSlideCal.Calculate.AddExternSpins(session)
	---地图最终位置
	local end_pos = ClimbLevelMapConfig[cur_activity.sel_level].end_pos---配置读取

	local sel_activity_info = cur_activity.activity_list[cur_activity.sel_level]

	local MapConfig = _G[ClimbLevelMapConfig[cur_activity.sel_level].config_name]

	local start_pos = cur_activity.pos

	response.start_pos = start_pos
	response.end_pos = end_pos
	response.level = cur_activity.sel_level
	response.count = cur_activity.spin_count
	response.prize_pool = ClimbSlideCal.Calculate.GetPrize(sel_activity_info)
	response.ext_percent = sel_activity_info.ext_percent
	response.ret = Return.OK()

	LOG(RUN, INFO).Format("[ClimbSlide][MapInfo] player: %s,  response: %s", player.id, Table2Str(response))
	return response
end

ResetMap = function(_M, session, request)
	local response = {header = {router = "Response"}}
	local activity_type = ActivityDefine.AllTypes.ClimbSlide
	local cur_activity = ClimbSlideCal.Calculate.GetActivityInfo(session, activity_type)
	ClimbSlideCal.Calculate.EnterNextMap(cur_activity, 1)
	ClimbSlideCal.Calculate.ResetActivity(session, activity_type)

	ClimbSlideCal.Calculate.AddExternSpins(session)

	local rs_activity_list = table.DeepCopy(cur_activity.activity_list)
	for k, v in ipairs(rs_activity_list) do
		v.prize = ClimbSlideCal.Calculate.GetPrize(cur_activity.activity_list[k])
	end

	response.ret = Return.OK()
	response.climb_slide_info = {
		collect_amount = cur_activity.collect_amount,
		total_collect_amount = cur_activity.total_collect_amount,
		spin_count = cur_activity.spin_count,
		sel_level = cur_activity.sel_level,
		activity_list = json.encode(rs_activity_list),
		final_prize = cur_activity.final_prize
	}
	return response
end

Spin = function ( _M, session, request )
	local response = {header = {router = "Response"}}
	local task = session.task
	local player = session.player

	if (player == nil) then
		response.ret = Return.PLAYER_NOT_FOUND()
		return response
	end

	local activity_type = ActivityDefine.AllTypes.ClimbSlide
	local count_down_info = ActivityCal.Calculate.CountDown(activity_type)
	LOG(RUN, INFO).Format("[ClimbSlide][Spin] player: %s,  count_down_info: %s", player.id, Table2Str(count_down_info))
	if (count_down_info.distance_start_time > 0 or count_down_info.distance_end_time == 0 ) then
		---没有到期或期限已经过期
		response.ret = Return.CLIMB_SLIDE_EXPIRED()
		return response
	end

	local cur_activity = ClimbSlideCal.Calculate.GetActivityInfo(session, activity_type)
	if (cur_activity.init_config == nil) then
		LOG(RUN, INFO).Format("[ClimbSlide][Collect] player:%s, not opent", player.id)
		response.ret = Return.CLIMB_SLIDE_EXPIRED()
		return response
	end
	ClimbSlideCal.Calculate.AddExternSpins(session)
	LOG(RUN, INFO).Format("[ClimbSlide][Spin]player %s, begin cur_activity is: %s", player.id, Table2Str(cur_activity))
	---------spin剩余次数是否大于0
	if (cur_activity.spin_count <= 0) then
		LOG(RUN, INFO).Format("[ClimbSlide][Spin] player: %s, spin count is:%s", player.id, cur_activity.spin_count)
		--response.ret = Return.GAME_PLAYER_CHIP_NOT_ENOUGH()
		return response
	end

	---地图最终位置
	local end_pos = ClimbLevelMapConfig[cur_activity.sel_level].end_pos---配置读取
	if (cur_activity.pos > end_pos) then
		LOG(RUN, INFO).Format("[ClimbSlide][Spin] player: %s, pos is:%s", player.id, cur_activity.pos)
		response.ret = Return.GAME_PLAYER_CHIP_NOT_ENOUGH()
		return response		
	end

	cur_activity.spin_count = cur_activity.spin_count - 1

	local sel_activity_info = cur_activity.activity_list[cur_activity.sel_level]

	local MapConfig = _G[ClimbLevelMapConfig[cur_activity.sel_level].config_name]

	-----下次要到达的格子
	local local_weight_tab = {}
	for pos = 1, 6, 1 do
		if (MapConfig[cur_activity.pos + pos] ~= nil) then
			if (cur_activity.his_pos[cur_activity.pos + pos] == nil) then
				local_weight_tab[pos] = MapConfig[cur_activity.pos + pos].grid_first_arrive_weight
			else
				local_weight_tab[pos] = MapConfig[cur_activity.pos + pos].grid_normal_weight
			end			
		else
			local_weight_tab[pos] = 1
		end
	end

	local local_index = math.rand_weight(player, local_weight_tab)
	
	local rand_pos = cur_activity.pos + local_index

	local next_pos = rand_pos

	if (next_pos > end_pos) then
		next_pos = end_pos
	end

	local move_count = rand_pos - cur_activity.pos
	local start_pos = cur_activity.pos

	local goal_pos = next_pos

	local award_info = {}
	
	if (MapConfig[next_pos] ~= nil) then
		cur_activity.his_pos[next_pos] = 1

		next_pos = ClimbSlideCal.Calculate.GetGift(player, cur_activity, sel_activity_info, ClimbLevelMapConfig, MapConfig, next_pos, award_info)
		goal_pos = next_pos
		---最终位置
		if (MapConfig[next_pos] ~= nil) then
			if (MapConfig[next_pos].grid_type >= 2 and MapConfig[next_pos].grid_type <= 5) then
				goal_pos = MapConfig[next_pos].move_to_grid_id
				if (MapConfig[next_pos].grid_type == 4) then
					table.insert(award_info, {pos = next_pos, type = 4, goal_pos = goal_pos})---上行
				elseif (MapConfig[next_pos].grid_type == 5) then
					table.insert(award_info, {pos = next_pos, type = 5, goal_pos = goal_pos})--下行
				end
	
				--新的位置是否有奖励
				goal_pos = ClimbSlideCal.Calculate.GetGift(player, cur_activity, sel_activity_info, ClimbLevelMapConfig, MapConfig, goal_pos, award_info)
			end
	
			cur_activity.activity_list[cur_activity.sel_level].spin_count = cur_activity.spin_count
			--终点是否有奖励
			if (MapConfig[end_pos] ~= nil and goal_pos == end_pos) then
				--给奖励
				local award_prize, reason_info = ClimbSlideCal.Calculate.GetPrize(sel_activity_info)
				reason_info = reason_info.."sel_level:"..cur_activity.sel_level
				response.prize = award_prize
				Player:Obtain(player, {"Chip", award_prize}, Reason.CLIMB_SLIDE_SPIN_CHIP_OBTAIN())
				Spark:ReasonInfo(
					player,
					{
						[1] = reason_info
					}
				)
				if (cur_activity.sel_level < #cur_activity.activity_list) then
					ClimbSlideCal.Calculate.EnterNextMap(cur_activity, cur_activity.sel_level + 1)
				else
					cur_activity.activity_list[cur_activity.sel_level].status = 2--活动已经完成
				end

				local init_config, base_value = ClimbSlideCal.Calculate.GetBaseValue(player)

				ClimbSlideCal.Calculate.InitBaseInfo(player, cur_activity, init_config, base_value)
			end
		end

	else
		cur_activity.activity_list[cur_activity.sel_level].spin_count = cur_activity.spin_count
	end

	if (goal_pos == end_pos) then
		cur_activity.pos = 0
	else
		cur_activity.pos = goal_pos
	end
	ActivityCal.Calculate.UpdateActivityInfo(session, activity_type)
	response.move_count = move_count
	response.start_pos = start_pos
	response.end_pos = end_pos
	response.award_info = json.encode(award_info)
	response.level = cur_activity.sel_level
	response.goal_pos = goal_pos
	response.count = cur_activity.spin_count

	response.prize_pool = ClimbSlideCal.Calculate.GetPrize(sel_activity_info)

	response.player = {
        character = {
            chip = player.character.chip,
        }
    }

	LOG(RUN, INFO).Format("[ClimbSlide][Spin]player %s, end cur_activity is: %s", player.id, Table2Str(cur_activity))

	LOG(RUN, INFO).Format("[ClimbSlide][Spin] player: %s, end  response: %s", player.id, Table2Str(response))
	return response
end