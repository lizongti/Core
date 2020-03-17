------------------
--  DailyMissionsState --
------------------
require "Config/ServerConfig"

_G.DailyMissionsState = {
	daily_missions_info = {},
}

function DailyMissionsState:GetDailyMissions()
	return self.daily_missions_info.daily_missions
end

function DailyMissionsState:GetDailyRefreshTime()
	return self.daily_missions_info.daily_refresh_time
end

function DailyMissionsState:GetWeekRefreshTime()
	return self.daily_missions_info.week_refresh_time
end

function DailyMissionsState:LoadDailyMissions(session, task)
	local redis_request = {
		[1] = string.format("HGET daily_missions daily_missions_info"),
	}
	local redis_response = session:ContactJson("CacheClientService", task, redis_request, "daily_missions")

	local content = json.decode(redis_response[1])
	self.daily_missions_info.daily_missions = content
end

function DailyMissionsState:RefreshDailyMissions(session, task)
	-------------刷新每日任务
	local missions_conf = {}
	local missions_weight = {}
	local missions_index = {}

	local local_missions_conf = {}
	local des_missions_conf = {}
	for k, conf in pairs(DailyMissionsInfoConfig) do
		if (local_missions_conf[conf.task_type] == nil) then
			local_missions_conf[conf.task_type] = {}
		end
		
		local task_conf = _G["DailyMissions"..conf.task_name.."Config"]
		for task_k, task_info in ipairs(task_conf) do
			local is_exist = false
			for de_k, de_v in ipairs(local_missions_conf[conf.task_type]) do
				if (de_v.task_level == task_info.task_level) then
					is_exist = true
					break
				end
			end

			if (not is_exist) then
				local temp_conf = {}
				for sub_k, sub_v in pairs(task_info) do
					temp_conf[sub_k] = sub_v
				end
				for sub_k, sub_v in pairs(conf) do
					temp_conf[sub_k] = sub_v
				end

				table.insert(local_missions_conf[conf.task_type], temp_conf)
			end
		end
	end

	for task_type, conf_list in pairs(local_missions_conf) do
		local weight_list = {}
		for sub_k, sub_v in ipairs(conf_list) do
			table.insert(weight_list, sub_v.weight)
		end

		local weight_index =  math.rand_weight(player, weight_list)
		for sub_k, sub_v in ipairs(conf_list) do
			if (sub_k == weight_index) then
				table.insert(des_missions_conf, sub_v)
			end
		end
	end

	for k, conf in pairs(des_missions_conf) do
		if (missions_conf[conf.task_level] == nil) then
			missions_conf[conf.task_level] = {}
		end
		if (missions_weight[conf.task_level] == nil) then
			missions_weight[conf.task_level] = {}
		end
		table.insert(missions_conf[conf.task_level], conf)
		table.insert(missions_weight[conf.task_level], conf.weight)
	end

	for task_level, weight_list in pairs(missions_weight) do
		missions_index[task_level] = math.rand_weight(player, weight_list)
	end

	if (self.daily_missions_info.daily_missions == nil) then
		self.daily_missions_info.daily_missions = {}
	end

	LOG(RUN, INFO).Format("[DailyMissionsState][RefreshDailyMissions] missions_index is:%s", Table2Str(missions_index))
	for task_level, weight_index in pairs(missions_index) do
		self.daily_missions_info.daily_missions[task_level] = {task_level = task_level, task_type = missions_conf[task_level][weight_index].task_type}
	end

	LOG(RUN, INFO).Format("[DailyMissionsState][RefreshDailyMissions] daily_missions is:%s", Table2Str(self.daily_missions_info.daily_missions))

	local content = self.daily_missions_info.daily_missions

	local redis_request = {
		[1] = string.format("HMSET daily_missions daily_missions_info %s", json.encode(content)),
		[2] = string.format("HMSET daily_missions daily_refresh_time %s", os.time()),
	}

	local redis_response = session:ContactJson("CacheClientService", task, redis_request, "daily_missions")
end

function DailyMissionsState:RefreshWeekTime(session, task)
	local redis_request = {
		[1] = string.format("HMSET daily_missions week_refresh_time %s", os.time()),
	}

	local redis_response = session:ContactJson("CacheClientService", task, redis_request, "daily_missions")
	LOG(RUN, INFO).Format("[DailyMissionsState][RefreshWeekTime] begin")
end

function DailyMissionsState:WeekPeriodStatus(session, task)
	local status = 0--0不刷新,1刷新，2服务器重启了，需要从缓存中取出
	local refresh_time = 0
	local cur_time = os.time()
	if (self.daily_missions_info.week_refresh_time == nil) then
		
		local redis_request = {
			[1] = string.format("HGET daily_missions week_refresh_time"),
		}

		local redis_response = session:ContactJson("CacheClientService", task, redis_request, "daily_missions") 

	
		if (not redis_response[1] or #redis_response[1] == 0) then
			
			local redis_request = {
				[1] = string.format("HMSET daily_missions week_refresh_time %s", cur_time),
			}

			local redis_response = session:ContactJson("CacheClientService", task, redis_request, "daily_missions")

			refresh_time = cur_time
			self.daily_missions_info.week_refresh_time = cur_time
			status = 1
			LOG(RUN, INFO).Format("[DailyMissionsState][WeekPeriodStatus]1 status is: %s", status)
		else
			refresh_time = tonumber(redis_response[1])

			if (os.same_week(cur_time, refresh_time)) then
				self.daily_missions_info.week_refresh_time = refresh_time
				status = 2
			else
				self.daily_missions_info.week_refresh_time = cur_time
				status = 1
			end
			LOG(RUN, INFO).Format("[DailyMissionsState][WeekPeriodStatus]2 status is: %s", status)
		end
		
	else
		if (os.same_week(cur_time, self.daily_missions_info.week_refresh_time)) then
			status = 0
		else
			self.daily_missions_info.week_refresh_time = cur_time
			status = 1
			LOG(RUN, INFO).Format("[DailyMissionsState][WeekPeriodStatus]3 status is: %s", status)
		end		
	end

	return status
end

function DailyMissionsState:DailyPeriodStatus(session, task)
	local status = 0--0不刷新,1刷新，2服务器重启了，需要从缓存中取出
	local refresh_time = 0
	local cur_time = os.time()
	if (self.daily_missions_info.daily_refresh_time == nil) then
		
		local redis_request = {
			[1] = string.format("HGET daily_missions daily_refresh_time"),
		}
		local redis_response = session:ContactJson("CacheClientService", task, redis_request, "daily_missions")
	
		if (not redis_response[1] or #redis_response[1] == 0) then
			
			local redis_request = {
				[1] = string.format("HMSET daily_missions daily_refresh_time %s", cur_time),
			}

			local redis_response = session:ContactJson("CacheClientService", task, redis_request, "daily_missions")

			refresh_time = cur_time
			self.daily_missions_info.daily_refresh_time = cur_time
			
			status = 1
			LOG(RUN, INFO).Format("[DailyMissionsState][DailyPeriodStatus]1refresh time:%s, status:%s", cur_time, status)
		else
			refresh_time = tonumber(redis_response[1])
			if (os.same_day(cur_time, refresh_time)) then
				self.daily_missions_info.daily_refresh_time = refresh_time
				status = 2
			else
				self.daily_missions_info.daily_refresh_time = cur_time
				status = 1
			end
			LOG(RUN, INFO).Format("[DailyMissionsState][DailyPeriodStatus]2refresh time:%s, status:%s", cur_time, status)
		end		
	else
		if (os.same_day(cur_time, self.daily_missions_info.daily_refresh_time)) then
			status = 0
		else
			self.daily_missions_info.daily_refresh_time = cur_time
			status = 1
			LOG(RUN, INFO).Format("[DailyMissionsState][DailyPeriodStatus]3refresh time:%s, status:%s", cur_time, status)
		end	
	end

	return status
end