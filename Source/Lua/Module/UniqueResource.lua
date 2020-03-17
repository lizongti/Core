--------------------
-- UniqueResource --
--------------------
require "Common/Return"

module("UniqueResource", package.seeall)

GetRandom = function(_M, session, request)
	local response = {
		header = {
			router = "AsyncResponse", 
			client_id = session.client_id, 
			task_id = request.header.task_id
		},
	}
	local random_id = request.random_id
	local random_limit = request.random_limit
	local num = RandomContainer.Get(random_id, random_limit)
	response = {
		header = response.header,
		ret = Return.OK(),
		random_num = num,
	}
	return response
end

GetGlobalState = function(_M, session, request)
	local response = {
		header = {
			router = "AsyncResponse", 
			client_id = session.client_id, 
			task_id = request.header.task_id
		},
	}

	response = {
		header = response.header,
		ret = Return.OK(),
		data_json = GlobalState.data_json
	}

	return response
end

RandomContainer = {
	random = Container:Get("RandomContainer.nums"),

	Regulate = function(random_id, random_limit)
		if not RandomContainer.random[random_id] then -- not load, load it from cache
			local task = Task:Current()
			local commands = {}
			table.insert(commands, string.format("HMGET random_%s id", random_id))
			table.insert(commands, string.format("HMGET random_%s limit", random_id))
			table.insert(commands, string.format("HMGET random_%s index", random_id))
			local replies = LuaSession:ContactJson("CacheClientService", task, commands, 0)
			if not replies[1] or replies[1] == "" or not replies[2] or replies[2] == "" or not replies[3] or replies[3] == "" then
				RandomContainer.Reset(random_id, random_limit) -- not inited, reset it
			else
				RandomContainer.random[random_id] = {
					id = tonumber(replies[1]),
					limit = tonumber(replies[2]),
					index = tonumber(replies[3]),
				}
				LOG(RUN, INFO).Format("[UniqueResource][Regulate] random id %s, random limit %s, random index %s init from cache", replies[1], replies[2], replies[3])
			end
		end
		if random_limit ~= RandomContainer.random[random_id].limit  -- limit not match, reset it
			or RandomContainer.random[random_id].limit < RandomContainer.random[random_id].index -- if num used over, reset it
		then
			RandomContainer.Reset(random_id, random_limit)
		end
	end,

	Reset = function(random_id, random_limit)
		local unpeated_random_set = math.unrepeated_random_set(random_limit)
		RandomContainer.random[random_id] = {
			id = random_id,
			limit = random_limit,
			index = 1,
		}
		local task = Task:Current()
		local commands = {}
		table.insert(commands, string.format("DEL random_%s", random_id))
		table.insert(commands, string.format("HMSET random_%s id %s", random_id, random_limit))
		table.insert(commands, string.format("HMSET random_%s limit %s", random_id, random_limit))
		table.insert(commands, string.format("HMSET random_%s index %s", random_id, 1))
		LuaSession:ContactJson("CacheClientService", task, commands, 0)
		
		local current_index = 1
		while current_index <= random_limit do
			if current_index % 100 == 1 then
				commands = {}
			end
			table.insert(commands, string.format("HMSET random_%s %s %s", random_id, current_index, unpeated_random_set[current_index]))
			if current_index % 100 == 0 or current_index == random_limit then
				LuaSession:ContactJson("CacheClientService", task, commands, 0)
			end
			current_index = current_index + 1
		end
		LOG(RUN, INFO).Format("[UniqueResource][Reset] random id %s, random limit %s, random index %s reset to cache", random_id, random_limit, 1)
	end,

	Get = function(random_id, random_limit)
		RandomContainer.Regulate(random_id, random_limit)
		local task = Task:Current()
		local commands = {}
		table.insert(commands, string.format("HMGET random_%s %s ", random_id, RandomContainer.random[random_id].index))
		table.insert(commands, string.format("HMSET random_%s index %s", random_id, RandomContainer.random[random_id].index + 1))
		local replies = LuaSession:ContactJson("CacheClientService", task, commands, 0)
		local num
		if not replies[1] or replies[1] == "" then
			num = 1
		else
			num = tonumber(replies[1])
		end
		
		LOG(RUN, INFO).Format("[UniqueResource][Get] random id %s, random limit %s, random index %s get num %s", 
			random_id, random_limit, RandomContainer.random[random_id].index, num)
		
		RandomContainer.random[random_id].index = RandomContainer.random[random_id].index + 1
		
		return num
	end
}