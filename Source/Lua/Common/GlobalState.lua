------------------
--  GlobalState --
------------------
require "Config/ServerConfig"
require "Util/TableExt"

local NUM_FLAG = 1.0

_G.GlobalState = {
	data_json = "",
	load_finished = false,
	reader_data = Container:Get("GlobalState.reader_data"),
	writer_data = Container:Get("GlobalState.writer_data"),
	append_data = Container:Get("GlobalState.append_data"),
	reader_init = {
		["Maintenance.DropAccount"] = 0,
		["Maintenance.StopSpin"] = 0,
		["Maintenance.State"] = "running", -- "running","resting","stopping","starting"
		["Maintenance.StopJackpot"] = 0, --用于停jackpot,后续可能用到

	},

	amend_funcs = {
	},
	list_test_id = {},
	daily_missions_info = {},
}

local function JackpotAmend(amend_funcs, key, info)
	amend_funcs[key] = function()
		local value = GlobalState:Get(key)
		if not value or value <= 0 then
			local v = info.jackpot_init_value_max - info.jackpot_init_value_min
			local value = info.jackpot_init_value_min + math.random() * v
			value = math.ceil(value)
			GlobalState:Append(key, value)
		elseif value and value + info.grow_chip_second < info.jackpot_max_limit then
		    --每秒钟增加一定值
		    GlobalState:Append(key, info.grow_chip_second)
		end
	end
end

function GlobalState:Init()
	--初始化jackpot的更新函数
	local amend_funcs = self.amend_funcs
	for game_name, game_id in pairs(GameType.AllTypes) do
		for id, info in pairs(JackpotTypeConfig) do
			local key = string.format("Slots.Jackpot.Game%s.Type%s", game_id, id)
			JackpotAmend(amend_funcs, key, info)
			self.reader_init[key] = 0
		end
	end
	--玩家押注金额
	for game_name, game_id in pairs(GameType.AllTypes) do
		for id, info in pairs(JackpotTypeConfig) do
			local key = string.format("Slots.Jackpot.Game%s.TotalBetValue%s", game_id, id)
			self.reader_init[key] = 0
		end
	end

	for k, v in pairs(self.reader_init) do
		self.reader_data[k] = self.reader_data[k] or v
	end
end

GlobalState:Init()

function GlobalState:LoadFinished()
	return self.load_finished
end

function GlobalState:Append(key, value)
	self.append_data[key] = (self.append_data[key] or 0) + math.round(value)
end

function GlobalState:Set(key, value)
	self.writer_data[key] = value
end

function GlobalState:Get(key)
	if type(self.reader_init[key]) == "number" then
		return self.reader_data[key] or 0
	elseif type(self.reader_init[key]) == "string" then
		return self.reader_data[key] or "none"
	end
end

function GlobalState:CheckTestID(playerid)
	if self.list_test_id[playerid] then
		return 1
	else 
		return 0
	end
end

function GlobalState:IsSlotsMaintenance(session, task, player_id)
	return 0
end

function GlobalState:IsMaintenance(session, task, player_id)
	local commands = {}
	table.insert(commands, string.format("HGETALL list_test_id"))
	local replies = session:ContactJson("CacheClientService", task, commands, player_id)
	--LOG(RUN, INFO).Format("[GlobalState][list_test_id] list_test_id is:%s", Table2Str(replies))
	self.list_test_id = {}
	for k,v in ipairs(replies) do
		if k % 2 == 1 then
			key = v
		else
			value = v
			self.list_test_id[key] = value
		end
	end	

	local is_test_id = 0
	if self.list_test_id[tostring(player_id)] then
		is_test_id = 1
	else 
		is_test_id = 0
	end

	if (GlobalState:Get("Maintenance.DropAccount") == 1 and is_test_id == 0) then
		return 1
	end

	return 0
end

--获取最新的缓存值,只能是number的
function GlobalState:GetLatest(key)
	--LOG(RUN, INFO).Format("[GlobalState][GetLatest]%s", key)
	if type(self.reader_init[key]) ~= "number" then
		--LOG(RUN, INFO).Format("[GlobalState][GetLatest]%s not number", key)
    	return 0
	end
	local value1 = self.reader_data[key] or 0
	--LOG(RUN, INFO).Format("[GlobalState][GetLatest]value1 is: %s", value1)
	local value2 = self.append_data[key] or 0
	--LOG(RUN, INFO).Format("[GlobalState][GetLatest]value2 is: %s", value2)

	return value1 + value2
end

-- every second, execute in dispatcher & manager
function GlobalState:SyncReaderData(data_json)
	local data = json.decode(data_json)
	if data then
		for k, _ in pairs(self.reader_init) do
			local v = data[k]
			if type(self.reader_init[k]) == "number" then
				self.reader_data[k] = tonumber(v) or 0
			elseif type(self.reader_init[k]) == "string" then
				self.reader_data[k] = v or "none"
			end
		end
		self.load_finished = true
	end
end

-- every second, execute in dispatcher
function GlobalState:SaveChangesToCache(session)
	local task = Task:New()
	task:Init(function()
		local commands = {}
		for key, value in pairs(self.writer_data) do
			table.insert(commands, string.format("HMSET global_state %s %s", key, value))
		end
		for key, value in pairs(self.append_data) do
			table.insert(commands, string.format("HINCRBY global_state %s %s", key, math.floor(value)))
		end
		self.writer_data = {}
		self.append_data = {}
		if #commands > 0 then
			--LOG(RUN, DEBUG).Format("[GlobalState][SaveChangesToCache]%s", json.encode(commands))
			session:ContactJson("CacheClientService", task, commands, 0)
		end
	end)
	task:Start()
end

-- every second, execute in dispatcher
function GlobalState:SyncGlobalState(self)
	local task = Task:New()
	task:Init(function()
		local task = Task:Current()
		local async_request = {
			header = {
				router = "AsyncRequest",
				service_name = "ManagerClientService",
				task_id = task.id,
				module_id = "UniqueResource",
				message_id = "UniqueResource_GetGlobalState_Request",
			},
		}
		local async_response = Base.ManagerClientService:ContactPacket(task, async_request)
		if async_response.ret.code ~= 0 then
			return
		end

		GlobalState:SyncReaderData(async_response.data_json)
	end)
	task:Start()
end

-- every second, execute in manager
function GlobalState:SyncFromCacheData(session)
	local task = Task:New()
	task:Init(function()

		-- get cache global state data
		local commands = {}
		table.insert(commands, string.format("HGETALL global_state"))
		local replies = session:ContactJson("CacheClientService", task, commands, 0)
		local key, value
		local data = {}
		for k, v in ipairs(replies) do
			if k % 2 == 1 then
				key = v
			else
				value = v
				data[key] = value
			end
		end

		local data_json = json.encode(data)
		self:SyncReaderData(data_json)

		-- get list_test_id from cache 
		local commands = {}
		table.insert(commands, string.format("HGETALL list_test_id"))
		local replies = session:ContactJson("CacheClientService", task, commands, 0)
		--LOG(RUN, INFO).Format("[GlobalState][list_test_id] list_test_id is:%s", Table2Str(replies))
		self.list_test_id = {}
		for k,v in ipairs(replies) do
			if k % 2 == 1 then
				key = v
			else
				value = v
				self.list_test_id[key] = value
			end
		end	
		--LOG(RUN, INFO).Format("[GlobalState][list_test_id] list_test_id is:%s， self.list_test_id is： %s", Table2Str(replies), Table2Str(self.list_test_id))

		-- maintainance, may need write cache
		for _, func in pairs(self.amend_funcs) do
			func()
		end
		local commands = {}
		for key, value in pairs(self.writer_data) do
			table.insert(commands, string.format("HMSET global_state %s %s", key, value))
		end
		for key, value in pairs(self.append_data) do
			table.insert(commands, string.format("HINCRBY global_state %s %s", key, math.floor(value)))
		end
		self.writer_data = {}
		self.append_data = {}
		if #commands > 0 then
			session:ContactJson("CacheClientService", task, commands, 0)
		end

		self.data_json = data_json
	end)
	task:Start()
end

