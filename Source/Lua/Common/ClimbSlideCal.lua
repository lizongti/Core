module("ClimbSlideCal", package.seeall)
require "Config/ServerConfig"
require"Common/ActivityDefine"
require"Common/ActivityCal"
Calculate = {
	GetBaseValue = function(player, is_init)

		local init_config = nil
		for index = #ClimbSlideInitDataConfig, 1, -1 do
			local config_info = ClimbSlideInitDataConfig[index]
			if (player.character.level >= config_info.player_level) then
				init_config = config_info
				break
			end
		end

		if (init_config == nil) then
			return init_config
		end

		local base_value = 0
		local base_value1 = math.floor(player.character.chip * init_config.base_value_by_coefficient_of_total_chip / 1000) * 1000
		local base_value2 = init_config.base_value
		base_value = base_value1
		if (base_value1 < base_value2) then
			base_value = base_value2
		end
		if (base_value > init_config.max_base_value) then
			base_value = init_config.max_base_value
		end
		return init_config, base_value
	end,

	-- Clear = function(session, activity_type)
	-- 	local cur_activity = ActivityCal.Calculate.GetActivityInfo(session, activity_type)
	-- 	cur_activity = {}
	-- 	ActivityCal.Calculate.UpdateActivityInfo(session, activity_type)
	-- end,

	GetActivityInfo = function(session, activity_type)
		local cur_activity = ActivityCal.Calculate.GetActivityInfo(session, activity_type)
		local player = session.player

		if (cur_activity.activity_list == nil or cur_activity.final_prize == nil) then
			cur_activity.activity_list = {}
			Calculate.InitActivity(player, cur_activity)
			Calculate.InitActivityList(cur_activity)
		elseif (cur_activity.init_config == nil) then
			Calculate.InitActivity(player, cur_activity)
			Calculate.InitActivityList(cur_activity)
		end
		return cur_activity
	end,

	ResetActivity = function(session, activity_type) 
		local cur_activity = ActivityCal.Calculate.GetActivityInfo(session, activity_type)
		local player = session.player

		Calculate.InitActivity(player, cur_activity, true)
		Calculate.InitActivityList(cur_activity, true)
	end,

	InitActivityList = function(cur_activity, is_reset)
		if (cur_activity.init_config == nil) then
			return
		end
		if (is_reset == nil) then
			is_reset = false
		end
		local init_config = cur_activity.init_config
		local base_value = cur_activity.base_value
		local count = #ClimbLevelMapConfig--配置读取
		
		--{level:1,prize:25000000(奖励池金额),status=1(0没有开始，1正在进行，2已经完成),spin_count = 10(剩余次数),ext_percent=10(奖励池额外的百分比)}
		if (not is_reset) then
			for k = 1, count, 1 do
				local item = {
					level = k,
					prize = base_value * init_config.prize_coefficient_level[k],--配置读取
					status = 0,
					ext_percent = 0,
					spin_count = 0
				}

				table.insert(cur_activity.activity_list, item)
			end
		else
			for k = 1, count, 1 do
				cur_activity.activity_list[k].prize = base_value * init_config.prize_coefficient_level[k]--配置读取
				cur_activity.activity_list[k].status = 0
				cur_activity.activity_list[k].ext_percent = 0
			end
		end
		cur_activity.activity_list[1].status = 1
		cur_activity.sel_level = 1
		cur_activity.final_prize = base_value * init_config.final_prize_coefficient--最终奖池
	end,

	InitActivity = function(player, cur_activity, is_reset)
		if (is_reset == nil) then
			is_reset = false
		end
		
		cur_activity.collect_amount = 0
		if (not is_reset) then
			cur_activity.spin_count = 0
		end
		---头像当前位置
		cur_activity.pos = 0
		---已经走过礼物格子列表
		cur_activity.his_pos = {}

		local init_config, base_value = Calculate.GetBaseValue(player)

		Calculate.InitBaseInfo(player, cur_activity, init_config, base_value)
		-- LOG(RUN, INFO).Format("[ClimbSlideCal][InitActivity] player:%s, cur_activity: %s", player.id, Table2Str(cur_activity))
	end,

	InitBaseInfo = function(player, cur_activity, init_config, base_value)
		if (init_config == nil) then
			return
		end
		---计算每次收集的金额上限
		cur_activity.init_config = init_config
		cur_activity.base_value = base_value

		local old_total_collect_amount = cur_activity.total_collect_amount
		
		cur_activity.total_collect_amount = base_value + init_config.collect_extra_value

		LOG(RUN, INFO).Format("[ClimbSlideCal][InitBaseInfo] player:%s, old_total_collect_amount: %s, total_collect_amount: %s", player.id, old_total_collect_amount, cur_activity.total_collect_amount)
		if (old_total_collect_amount ~= nil) then
			cur_activity.collect_amount = cur_activity.collect_amount * cur_activity.total_collect_amount / old_total_collect_amount
		end
	end,

	GetBufCountDown = function(session)
		local activity_type = ActivityDefine.AllTypes.ClimbSlide

		local cur_activity = Calculate.GetActivityInfo(session, activity_type)
	
		local climb_slide_buff_time = 0
		if (cur_activity.climb_slide_end_buf_time ~= nil) then
			climb_slide_buff_time = cur_activity.climb_slide_end_buf_time - os.time()
			if (climb_slide_buff_time < 0) then
				climb_slide_buff_time = 0
			end
		end
		return climb_slide_buff_time, cur_activity.climb_slide_start_buf_time, cur_activity.climb_slide_end_buf_time
	end,

	AddExternSpins = function(session)
		-- local activity_type = ActivityDefine.AllTypes.ClimbSlide
		-- ----配置读取判断是否触发收集
		-- local cur_activity = Calculate.GetActivityInfo(session, activity_type)
		-- local climb_slide_buff_time = Calculate.GetBufCountDown(session)
		-- if (climb_slide_buff_time > 0 and cur_activity.added_spin_count > 0) then
		-- 	cur_activity.spin_count = cur_activity.spin_count + cur_activity.added_spin_count
		-- 	cur_activity.activity_list[cur_activity.sel_level].spin_count = cur_activity.spin_count
		-- 	cur_activity.added_spin_count = 0
		-- end
		
	end,

	GetBooster = function(session)
		local climb_slide_buff_time, climb_slide_start_buf_time, climb_slide_end_buf_time = Calculate.GetBufCountDown(session)
		
		local status = 1
		if (climb_slide_buff_time == 0) then
			---已经过期
			status = 0
		end
		return status, climb_slide_start_buf_time, climb_slide_end_buf_time, climb_slide_buff_time
	end,

	GetPrize = function(sel_activity_info)
		local total_prize = sel_activity_info.prize * (100 + sel_activity_info.ext_percent) / 100
		local reason_info = "prize:"..sel_activity_info.prize.."ext_percent:"..sel_activity_info.ext_percent.."total_prize is:"..total_prize
		return total_prize, reason_info
	end,

	EnterNextMap = function(cur_activity, next_level)
		cur_activity.activity_list[cur_activity.sel_level].status = 2--活动已经完成
		cur_activity.activity_list[cur_activity.sel_level].spin_count = 0--当前地图已满

		cur_activity.activity_list[next_level].status = 1--正在开始的活动
		cur_activity.activity_list[next_level].spin_count = cur_activity.spin_count--下个地图还剩多少次spin
		cur_activity.sel_level = next_level
	end,

	GetGift = function(player, cur_activity, sel_activity_info, ClimbLevelMapConfig, MapConfig, next_pos, award_info)
		if (MapConfig[next_pos] == nil) then
			return next_pos
		end
		local gift_config = _G[ClimbLevelMapConfig[cur_activity.sel_level].gift_config_name]
		---是否是礼盒
		---1.礼盒(有四种礼盒) 4,上行 5下行 6终点
		if (MapConfig[next_pos].grid_type == 1) then
			---生成礼盒
			local weight_tab = {}
			for k, v in ipairs(gift_config) do
				weight_tab[k] = v.weight
			end
			local config_index = math.rand_weight(player, weight_tab)
			local sel_config = gift_config[config_index]
			
			if (sel_config.gift_type == 1) then
				local award_spin_count = sel_config.value

				cur_activity.spin_count = cur_activity.spin_count + award_spin_count

				table.insert(award_info, {pos = next_pos, type = sel_config.gift_type, value = award_spin_count})--行动次数
			elseif (sel_config.gift_type == 2) then
				local init_config = cur_activity.init_config
				local base_value = cur_activity.base_value
				local award_value = base_value * init_config.gift_prize_coefficient
				award_value = math.floor(award_value * sel_config.value)
				Player:Obtain(player, {"Chip", award_value}, Reason.CLIMB_SLIDE_CHIP_OBTAIN())
				table.insert(award_info, {pos = next_pos, type = sel_config.gift_type, value = award_value})--金币奖励
			elseif (sel_config.gift_type == 3) then
				sel_activity_info.ext_percent = sel_activity_info.ext_percent + math.floor(sel_config.value * 100)
				--sel_activity_info.prize = math.floor(sel_activity_info.prize + sel_config.value * sel_activity_info.prize)
				table.insert(award_info, {pos = next_pos, type = sel_config.gift_type, value = sel_config.value * 100})--奖池增加
			elseif (sel_config.gift_type == 4) then
				table.insert(award_info, {pos = next_pos, type = 6, goal_pos = sel_config.value})---奖励上行
				next_pos = sel_config.value
			end
		end
		return next_pos
	end,

	UpdateProcess = function(session, player, total_bet_amount)
		if session.player.is_fever_quest == 1 then
			LOG(RUN, INFO).Format("[ClimbSlide][UpdateProcess]player: %s, is fever", player.id)
			return
		end
		local activity_type = ActivityDefine.AllTypes.ClimbSlide
		local count_down_info = ActivityCal.Calculate.CountDown(activity_type)
		if (count_down_info.distance_start_time > 0 or count_down_info.distance_end_time == 0 ) then
			---没有到期或期限已经过期
			-- Calculate.Clear(session, activity_type)
			LOG(RUN, INFO).Format("[ClimbSlide][UpdateProcess]player: %s", player.id)
			return
		end

		local init_config, base_value = Calculate.GetBaseValue(player)
		---没有达到等级
		if (init_config == nil) then
			LOG(RUN, INFO).Format("[ClimbSlide][UpdateProcess]player: %s", player.id)
			return
		end

		----配置读取判断是否触发收集
		local cur_activity = Calculate.GetActivityInfo(session, activity_type)

		---是否收集
		local need_collect = math.rand_prob(player, init_config.spin_collect_probablity)
		if (not need_collect) then
			LOG(RUN, INFO).Format("[ClimbSlide][UpdateProcess]player: %s", player.id)
			return
		end

		---收集次数达到上限
		local flying_status = 0
		if (cur_activity.spin_count >= ClimbSlideSpinTimesConfig[1].limit_collect_spin_times) then
			LOG(RUN, INFO).Format("[ClimbSlide][UpdateProcess]player: %s", player.id)
			return
		end

		Calculate.InitBaseInfo(player, cur_activity, init_config, base_value)

		cur_activity.collect_amount = cur_activity.collect_amount + total_bet_amount

		if (cur_activity.collect_amount >= cur_activity.total_collect_amount) then
			
			local climb_slide_buff_time = ClimbSlideCal.Calculate.GetBufCountDown(session)
			-- LOG(RUN, INFO).Format("[ClimbSlide][Spin]11 player: %s, climb_slide_buff_time is:%s, add_spin_times is:%s", player.id, climb_slide_buff_time, add_spin_times)
			local add_spin_times = ClimbSlideSpinTimesConfig[1].each_collection_gain_spin_times
			if (climb_slide_buff_time > 0) then
				add_spin_times = add_spin_times * 2
			end
			-- LOG(RUN, INFO).Format("[ClimbSlide][Spin]22 player: %s, climb_slide_buff_time is:%s, add_spin_times is:%s", player.id, climb_slide_buff_time, add_spin_times)

			cur_activity.spin_count = cur_activity.spin_count + add_spin_times ---配置读取
			
			cur_activity.collect_amount = 0
			flying_status = 1
		end

		---计算奖池
		if (cur_activity.activity_list ~= nil) then
			cur_activity.activity_list[cur_activity.sel_level].spin_count = cur_activity.spin_count
			for k, v in ipairs(cur_activity.activity_list) do
				if (cur_activity.activity_list[k].status ~= 2) then
					cur_activity.activity_list[k].prize = base_value * init_config.prize_coefficient_level[k]
				end
			end
		end

		ActivityCal.Calculate.UpdateActivityInfo(session, activity_type)

		-- LOG(RUN, INFO).Format("[ClimbSlide][UpdateProcess]player %s, end ClimbSlide_Collect_Notice is: %s", player.id, Table2Str(cur_activity))
		session:WriteRouterPacket({
			header = {
				router = "Notice",
				module_id = "ClimbSlide",
				message_id = "ClimbSlide_Collect_Notice"
			},
			climb_slide_info = {
				collect_amount = cur_activity.collect_amount,
				total_collect_amount = cur_activity.total_collect_amount,
				spin_count = cur_activity.spin_count,
				sel_level = cur_activity.sel_level,
				activity_list = json.encode(cur_activity.activity_list),
				final_prize = cur_activity.final_prize,
				flying_status = flying_status
			}

		})
	end,

}