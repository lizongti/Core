-----------------
--  LuaSession --
-----------------
require "Base/Path"
require "Base/LuaPacket"
require "Base/TableCache"
require "Module/Distributor"
require "Config/system/ConstValue"
require "Util/MathExt"

_G.LuaSession = {
	local_packets = {}
}

-- client_id
-- time
-- action

-----------------------------------------------
-- 1. 请求和响应
-- Request : 与Unity客户端通信时的请求
-- Response : 与Unity客户端通信时的响应
-- AsyncRequest : 服务器之间通信时的客户端请求
-- AsyncResponse : 服务器之间通信时的服务器响应
------------------------------------------------
-- 2. 单人消息推送
-- Notice : 获得PlayerSession时的单人消息推送
-- SpecificNotice : 没有获得PlayerSession时的单人消息推送
-- ContestNotice : Contest进程的对单人消息推送
------------------------------------------------
-- 3. 广播
-- Broadcast : 当前进程中有NotificationClientService时的聊天广播推送
-- AsyncBroadcast : 当前进程中没有NotificationClientService时的聊天广播推送
-- ContestBroadcast : Contest进程的逻辑广播推送(逻辑广播与聊天广播是不同的系统)
------------------------------------------------
-- 4. 服务器内部单向通信
-- Inform : 服务器之间通信时的客户端发起的单向通信
-- Command : 服务器之间通信时的服务器发起的单向通信
------------------------------------------------
-- 5. 本地执行消息
-- LocalRequest : 本地同步调用消息所指向的handler并返回结果，需要重新登陆的玩法适用，取代AsyncRequest
-- LocalBroadcast : 本地同步发送逻辑广播，需要重新登陆的玩法适用, 取代ContestBroadcast
-- LocalNotice : 本地同步发送单人消息，需要重新登陆的玩法适用，取代ContestNotice
------------------------------------------------

--ReadPacket由middlewire负责创建，LuaSession负责销毁
--WritePacket由LuaSession负责创建，middleware负责销毁

local function copy_data(data)
	local n = {}
	for k, v in pairs(data) do
		if type(v) == "table" then
			n[k] = copy_data(getmetatable(v).data)
		else
			n[k] = v
		end
	end
	return n
end

local function parse_data(data)
	for k, v in pairs(data) do
		local m = getmetatable(v)
		if m and m.data then
			data[k] = copy_data(m.data)
		end
	end
	return data
end

LuaSession.read_routers = {
	--读取
	Request = function(self, packet) -- packet from client
		-- check handler valid
		local handler = Protocol:Handler(packet.object.module_id, packet.object.message_id)
		if not handler then
			return true
		end

		local request = packet.data
		if not request.header.sequence_id or request.header.sequence_id == 0 then
			request.header.sequence_id = packet.object.sequence_id
		end

		if not handler.object then
			LOG(RUN, ERROR).Format("[LuaSession][read_routers] Request handler.object is nil.")
			return true
		end

		local output
		if packet.object.module_id == 100 and packet.object.message_id == 1 or self.player then
			-- execute handler
			output = {
				handler.object(
					handler.module.object,
					self,
					request --proto数据
				)
			}
		else
			local response = {header = {router = "Response"}, ret = Return.PLAYER_NOT_FOUND()}
			output = {response}
		end

		-- log exception
		for index, data in ipairs(output or {}) do
			if data.ret and data.ret.code ~= 0 then
				Spark:ResponseInfo(
					nil,
					{
						[1] = data.ret.code,
						[2] = data.ret.msg
					}
				)
			end
		end

		-- router output
		for index, data in pairs(output or {}) do
			data = parse_data(data)
			data.header.module_id = Protocol:Module(handler.module.id).name
			data.header.message_id = Protocol:Message(handler.module.id, handler.response[index].id).name
			local packet = LuaPacket:CreateWritePacket(data, request.header.sequence_id, request.header.time)
			self:WriteRouter(packet)
		end

		return true
	end,
	Notice = function(self, packet) -- dispatcher handle notice
		if self.object then
			self.object:WritePacket(packet.object)
			return false
		end
		return true
	end,
	SpecificNotice = function(self, packet) -- dispatcher specific player
		if packet.data.header and packet.data.header.session_id and packet.data.header.player_id then
			local session_id = packet.data.header.session_id
			local player_id = packet.data.header.player_id
			local session = PlayerSession:Get(session_id)
			if session and session.player and session.player.id == player_id and session.object then
				session.object:WritePacket(packet.object)
				return false
			end
		else
			LOG(RUN, ERROR).Format("[LuaSession][read_routers] SpecificNotice packet leak header data!")
		end
		return true
	end,
	Broadcast = function(self, packet) -- dispatcher broadcast packet
		local notify_data = Distributor:Notify(self, packet.data)
		for _, one_notify_data in pairs(notify_data) do
			packet.data.header.router = "SpecificNotice"
			packet.data.header.session_id = one_notify_data.session_id
			packet.data.header.player_id = one_notify_data.player_id
			local data = packet.data
			local packet = LuaPacket:CreateWritePacket(data)
			if self.object then
				self.object:WritePacket(one_notify_data.client_id, packet.object)
			end
		end
		return true
	end,
	AsyncBroadcast = function(self, packet) -- async broadcast packet
		packet.data.header.router = "Broadcast"
		local data = packet.data
		self:WriteRouterPacket(data)
		return true
	end,
	AsyncRequest = function(self, packet) -- request between servers
		-- check handler valid
		local handler = Protocol:Handler(packet.object.module_id, packet.object.message_id)
		if not handler then
			return true
		end

		-- execute handler
		local output = {
			handler.object(handler.module.object, self, packet.data)
		}
		-- router output
		for index, data in pairs(output or {}) do
			data.header.module_id = Protocol:Module(handler.module.id).name
			data.header.message_id = Protocol:Message(handler.module.id, handler.response[index].id).name
			self:WriteRouterPacket(data)
		end

		return true
	end,
	AsyncResponse = function(self, packet) -- request between servers
		if packet.data.header and packet.data.header.task_id then
			local task = Task:Get(packet.data.header.task_id)

			if task then
				local data = packet.data
				task:Activate(data)
			end
		else
			LOG(RUN, ERROR).Format("[LuaSession][read_routers] AsyncResponse packet leak header data!")
		end
		return true
	end,
	Command = function(self, packet) -- Command from manager server
		-- check handler valid
		local handler = Protocol:Handler(packet.object.module_id, packet.object.message_id)
		if not handler then
			return true
		end
		-- execute handler
		local output = {
			handler.object(handler.module.object, self, packet.data)
		}

		return true
	end,
	Inform = function(self, packet)
		-- check handler valid
		local handler = Protocol:Handler(packet.object.module_id, packet.object.message_id)
		if not handler then
			return true
		end
		-- execute handler
		local output = {
			handler.object(handler.module.object, self, packet.data)
		}

		return true
	end,
	ContestBroadcast = function(self, packet)
		local notify_data = Distributor:Notify(self, packet.data)
		for _, one_notify_data in pairs(notify_data) do
			packet.data.header.router = "SpecificNotice"
			packet.data.header.session_id = one_notify_data.session_id
			packet.data.header.player_id = one_notify_data.player_id
			local data = packet.data
			local packet = LuaPacket:CreateWritePacket(data)
			if self.object then
				self.object:WritePacket(one_notify_data.client_id, packet.object)
			end
		end
		return true
	end,
	ContestNotice = function(self, packet)
		local one_notify_data = Distributor:SpecificNotify(self, packet.data)
		if one_notify_data then
			packet.data.header.router = "SpecificNotice"
			packet.data.header.session_id = one_notify_data.session_id
			packet.data.header.player_id = one_notify_data.player_id
			if self.object then
				self.object:WritePacket(one_notify_data.client_id, packet.object)
				return false
			end
		end
		return true
	end,
	LocalRequest = function(self, packet)
		if not packet.data.header or not packet.data.header.service_name or not Base[packet.data.header.service_name] then
			LOG(RUN, ERROR).Format("[LuaSession][write_routers] LocalRequest packet header not correct!")
			return true
		end
		local session = Base[packet.data.header.service_name]

		-- check handler valid
		local handler = Protocol:Handler(packet.object.module_id, packet.object.message_id)
		if not handler then
			return true
		end

		-- execute handler
		local output = {
			handler.object(handler.module.object, session, packet.data)
		}

		self:ClearLocalPacket()
		for index, data in ipairs(output or {}) do
			data.header.module_id = Protocol:Module(handler.module.id).name
			data.header.message_id = Protocol:Message(handler.module.id, handler.response[index].id).name

			if index == 1 then
				local packet = LuaPacket:CreateWritePacket(data)
				self:PushLocalPacket(packet) -- must be self
			else
				self:WriteRouterPacket(data)
			end
		end

		return true
	end
}
--写出routers
LuaSession.write_routers = {
	--返回
	Response = function(self, packet) -- session write
		if self.object then
			self.object:WritePacket(packet.object)
			return false
		end
		return true
	end,
	Notice = function(self, packet)
		if self.object then
			self.object:WritePacket(packet.object)
			return false
		end
		return true
	end,
	SpecificNotice = function(self, packet)
		if packet.data.header and packet.data.header.session_id and packet.data.header.player_id then
			local session_id = packet.data.header.session_id
			local player_id = packet.data.header.player_id
			local session = PlayerSession:Get(session_id)
			local player_type = ConstValue[5].value
			if
				session and session.player and session.player.id == player_id and
					session.player.character.player_type ~= tonumber(player_type)
			 then
				session.object:WritePacket(packet.object)
				return false
			end
		else
			LOG(RUN, ERROR).Format("[LuaSession][write_routers] SpecificNotice packet leak header data!")
		end
		return true
	end,
	Broadcast = function(self, packet) -- broadcast
		if packet.data.header and packet.data.header.channel_id then
			if Base.ManagerClientService and Base.ManagerClientService.object then
				Base.ManagerClientService.object:WritePacket(packet.object)
				return false
			end
		else
			LOG(RUN, ERROR).Format("[LuaSession][write_routers] Broadcast packet leak header data!")
		end
		return true
	end,
	AsyncBroadcast = function(self, packet) -- async broadcast packet
		if
			packet.data.header and packet.data.header.channel_id and packet.data.header.client_id and
				packet.data.header.service_name
		 then
			if Base[packet.data.header.service_name] and Base[packet.data.header.service_name].object then
				Base[packet.data.header.service_name].object:WritePacket(packet.data.header.client_id, packet.object)
				return false
			end
		else
			LOG(RUN, ERROR).Format("[LuaSession][write_routers] AsyncBroadcast packet leak header data!")
		end
		return true
	end,
	AsyncRequest = function(self, packet)
		if packet.data.header and packet.data.header.service_name and packet.data.header.task_id then
			if Base[packet.data.header.service_name] and Base[packet.data.header.service_name].object then
				Base[packet.data.header.service_name].object:WritePacket(packet.object)
				return false
			end
		else
			LOG(RUN, ERROR).Format("[LuaSession][write_routers] AsyncRequest packet leak header data!")
		end
		return true
	end,
	AsyncResponse = function(self, packet)
		if packet.data.header and packet.data.header.task_id and packet.data.header.client_id then
			if self.object then
				self.object:WritePacket(packet.data.header.client_id, packet.object)
				return false
			end
		else
			LOG(RUN, ERROR).Format("[LuaSession][write_routers] AsyncResponse packet leak header data!")
		end
		return true
	end,
	Command = function(self, packet)
		if packet.data.header and packet.data.header.client_id then
			if self.object then
				self.object:WritePacket(packet.data.header.client_id, packet.object)
				return false
			end
		else
			LOG(RUN, ERROR).Format("[LuaSession][write_routers] Command packet leak header data!")
		end
		return true
	end,
	--往对应的contest发送packet
	Inform = function(self, packet)
		if packet.data.header and packet.data.header.service_name then
			if Base[packet.data.header.service_name] and Base[packet.data.header.service_name].object then
				Base[packet.data.header.service_name].object:WritePacket(packet.object)
				return false
			end
		else
			LOG(RUN, ERROR).Format("[LuaSession][write_routers] Inform packet leak header data!")
		end
		return true
	end,
	ContestBroadcast = function(self, packet)
		local notify_data = Distributor:Notify(self, packet.data)
		for _, one_notify_data in pairs(notify_data) do
			packet.data.header.router = "SpecificNotice"
			LOG(RUN, INFO).Format("[LuaSession][write_routers] session_id is: %s", one_notify_data.session_id)
			packet.data.header.session_id = one_notify_data.session_id
			packet.data.header.player_id = one_notify_data.player_id
			local data = packet.data
			local packet = LuaPacket:CreateWritePacket(data)
			if self.object then
				self.object:WritePacket(one_notify_data.client_id, packet.object)
			end
		end
		return true
	end,
	ContestNotice = function(self, packet)
		local one_notify_data = Distributor:SpecificNotify(self, packet.data)
		if one_notify_data then
			packet.data.header.router = "SpecificNotice"
			packet.data.header.session_id = one_notify_data.session_id
			packet.data.header.player_id = one_notify_data.player_id
			local data = packet.data
			local packet = LuaPacket:CreateWritePacket(data)
			if self.object then
				self.object:WritePacket(one_notify_data.client_id, packet.object)
			end
		end
		return true
	end,
	LocalRequest = function(self, packet)
		if not packet.data.header or not packet.data.header.service_name or not Base[packet.data.header.service_name] then
			LOG(RUN, ERROR).Format("[LuaSession][write_routers] LocalRequest packet header not correct!")
			return true
		end
		local session = Base[packet.data.header.service_name]

		-- check handler valid
		local handler = Protocol:Handler(packet.object.module_id, packet.object.message_id)
		if not handler then
			return true
		end

		-- execute handler
		local output = {
			handler.object(handler.module.object, session, packet.data)
		}

		self:ClearLocalPacket()
		for index, data in ipairs(output or {}) do
			data.header.module_id = Protocol:Module(handler.module.id).name
			data.header.message_id = Protocol:Message(handler.module.id, handler.response[index].id).name

			if index == 1 then
				local packet = LuaPacket:CreateWritePacket(data)
				self:PushLocalPacket(packet) -- must be self
			else
				self:WriteRouterPacket(data)
			end
		end

		return true
	end,
	LocalBroadcast = function(self, packet)
		local notify_data = Distributor:Notify(self, packet.data)
		for _, one_notify_data in pairs(notify_data) do
			local session_id = one_notify_data.session_id
			local player_id = one_notify_data.player_id

			local data = packet.data
			data.header.router = "SpecificNotice"
			data.header.session_id = session_id
			data.header.player_id = player_id

			local packet = LuaPacket:CreateWritePacket(data)
			local session = PlayerSession:Get(session_id)
			if session and session.player and session.player.id == player_id then
				session.object:WritePacket(packet.object)
			end
		end
		return true
	end,
	LocalNotice = function(self, packet)
		local one_notify_data = Distributor:SpecificNotify(self, packet.data)
		if one_notify_data then
			local session_id = one_notify_data.session_id
			local player_id = one_notify_data.player_id

			local data = packet.data
			data.header.router = "SpecificNotice"
			data.header.session_id = session_id
			data.header.player_id = player_id

			local packet = LuaPacket:CreateWritePacket(data)
			local session = PlayerSession:Get(session_id)
			if session and session.player and session.player.id == player_id then
				session.object:WritePacket(packet.object)
			end
		end
		return true
	end
}

function LuaSession:New()
	local Instance = {}
	setmetatable(Instance, self)
	self.__index = self

	return Instance
end

function LuaSession:Work(work) -- give a sanbox for async work
	local task = Task:New()
	task:Init(
		function()
			work(task)
		end
	)
	task:Start()
end

function LuaSession:WriteRouter(packet)
	if packet.data.header and packet.data.header.router then
		if self.write_routers[packet.data.header.router] then
			if self.write_routers[packet.data.header.router](self, packet) then
				-- 这里并不表明是否执行成功，只表明是否需要销毁
				packet:Abandon()
			end
		else
			LOG(RUN, ERROR).Format("[LuaSession][WriteRouter] router %s not found!", packet.data.header.router)
			packet:Abandon()
		end
	else
		LOG(RUN, ERROR).Format("[LuaSession][WriteRouter] packet has not field router")
		packet:Abandon()
	end
end

function LuaSession:ReadRouter(packet)
	if packet.data.header and packet.data.header.router then
		if self.read_routers[packet.data.header.router] then
			if self.read_routers[packet.data.header.router](self, packet) then
				-- 这里并不表明是否执行成功，只表明是否需要销毁
				packet:Abandon()
			end
		else
			LOG(RUN, ERROR).Format("[LuaSession][ReadRouter] router %s not found!", packet.data.header.router)
			packet:Abandon()
		end
	else
		LOG(RUN, ERROR).Format("[LuaSession][ReadRouter] packet has not field router")
		packet:Abandon()
	end
end

function LuaSession:ClearLocalPacket()
	for _, packet in pairs(self.local_packets) do
		packet:Abandon()
	end
	self.local_packets = {}
end

function LuaSession:PushLocalPacket(packet)
	table.insert(self.local_packets, packet)
end

function LuaSession:PopLocalPacket()
	local packet = self.local_packets[1]
	if packet then
		table.remove(self.local_packets, 1)
	end
	return packet
end

function LuaSession:PacketToData(packet)
	local data = packet.data
	packet:Abandon()
	return data
end

function LuaSession:Update(client_id)
	self.client_id = client_id
	while true do
		-- read packet
		local data
		if self.client_id then
			data = self.object:ReadPacket(self.client_id)
		else
			data = self.object:ReadPacket()
		end
		if not data then
			break
		end

		self:Work(
			function()
				-- create input_packet
				local packet = LuaPacket:CreateReadPacket(data)
				self:ReadRouter(packet)
			end
		)
	end
end

function LuaSession:WriteRouterPacket(data)
	if data.header.service_name == "NotificationClientService" then
		data.header.service_name = "ManagerClientService"
		return self:WriteRouterPacket(data)
	end
	if data.header.service_name == "ContestClientService" then
		if Base.DispatcherService then
			data.header.service_name = "DispatcherService"
		elseif Base.BackstageService then
			data.header.service_name = "BackstageService"
		end
		data.header.router = "LocalRequest"
		return self:WriteRouterPacket(data)
	end

	local packet = LuaPacket:CreateWritePacket(data)
	self:WriteRouter(packet)
end

function LuaSession:ReadRouterPacket(data)
	if data.header.service_name == "NotificationClientService" then
		data.header.service_name = "ManagerClientService"
		return self:ReadRouterPacket(data)
	end
	if data.header.service_name == "ContestClientService" then
		if Base.DispatcherService then
			data.header.service_name = "DispatcherService"
		elseif Base.BackstageService then
			data.header.service_name = "BackstageService"
		end
		data.header.router = "LocalRequest"
		return self:ReadRouterPacket(data)
	end

	if data.header.service_name == "ManagerClientService" then
		data.header.service_name = "ManagerService"
	end

	local packet = LuaPacket:CreateWritePacket(data)
	self:ReadRouter(packet)
end

function LuaSession:ContactPacket(task, data)
	if data.header.service_name ~= "BackstageService" and data.player_type == tonumber(ConstValue[5].value) then
		data.header.service_name = "BackstageService"
		data.header.router = "LocalRequest"
		return self:ContactPacket(task, data)
	end
	if data.header.service_name == "NotificationClientService" then
		data.header.service_name = "ManagerClientService"
		return self:ContactPacket(task, data)
	end
	if data.header.service_name == "ContestClientService" then
		if Base.DispatcherService then
			data.header.service_name = "DispatcherService"
		elseif Base.BackstageService then
			data.header.service_name = "BackstageService"
		end
		data.header.router = "LocalRequest"
		return self:ContactPacket(task, data)
	end
	if data.header.router == "LocalRequest" then
		local packet = LuaPacket:CreateWritePacket(data)
		self:WriteRouter(packet)
		local packet = self:PopLocalPacket()
		if packet then
			return self:PacketToData(packet)
		end
	else
		self:WriteRouterPacket(data)
		return task:Input()
	end
end

function LuaSession:ContactJson(service_name, task, commands, hash)
	local request = {
		id = task.id,
		commands = commands
	}

	if not hash then
		LOG(RUN, ERROR).Format("[LuaSession][ContactJson] ContactJson must have a hash arg!")
	end

	if service_name == "CacheClientService" or service_name == "CacheIntegratedService" then
		hash = math.transform_hash(hash) or math.random()
		Base.CacheIntegratedService.object:RedisCommand(hash, json.encode(request))
	elseif service_name == "DatabaseClientService" or service_name == "DatabaseIntegratedService" then
		hash = math.transform_hash(hash) or math.random()
		Base.DatabaseIntegratedService.object:MysqlCommand(hash, json.encode(request))
	else
		Base[service_name].object:WriteJson(json.encode(request))
	end
	local response = task:Input()

	return response.replies
end

function LuaSession:EverySecond(work)
	local now_time = os.time()
	if self.time ~= now_time then
		self.time = now_time
		work()
	end
end

function LuaSession:EveryServeralSecond(work, second)
	local now_time = os.time()
	if self.time ~= now_time and now_time % second == 0 then
		self.time = now_time
		work()
	end
end

function LuaSession:EveryMinute(work)
	local now_time = os.time()
	if (self.heart_time == nil) then
		self.heart_time = now_time
	end
	if now_time - self.heart_time > 60 then
		self.heart_time = now_time
		work()
	end
end

function LuaSession:BroadcastWriteQueue(queue_name, message)
	local commands
	if
		Base.Enviroment.pro_spec_t == "online" or Base.Enviroment.pro_spec_t == "online2" or
			Base.Enviroment.pro_spec_t == "temporay"
	 then
		commands = {
			[1] = {
				cmd = "%s %s %s",
				args = {"LPUSH", string.format("%s.%s.reader", "online", queue_name), message}
			},
			[2] = {
				cmd = "%s %s %s",
				args = {"LPUSH", string.format("%s.%s.reader", "online2", queue_name), message}
			},
			[3] = {
				cmd = "%s %s %s",
				args = {"LPUSH", string.format("%s.%s.reader", "temporay", queue_name), message}
			}
		}
	else
		commands = {
			[1] = {
				cmd = "%s %s %s",
				args = {"LPUSH", string.format("%s.%s.reader", Base.Enviroment.pro_spec_t, queue_name), message}
			}
		}
	end
	self:Work(
		function(task)
			self:ContactJson("CacheIntegratedService", task, commands, math.random())
		end
	)
end

function LuaSession:WriteQueue(queue_name, message)
	local commands = {
		[1] = {
			cmd = "%s %s %s",
			args = {"LPUSH", string.format("%s.%s.writer", Base.Enviroment.pro_spec_t, queue_name), message}
		}
	}

	self:Work(
		function(task)
			self:ContactJson("CacheIntegratedService", task, commands, math.random())
		end
	)
end

function LuaSession:ReadQueue(queue_name, callback)
	local commands = {}
	table.insert(commands, string.format("RPOP %s.%s.reader", Base.Enviroment.pro_spec_t, queue_name))
	self:Work(
		function(task)
			while true do
				local messages = self:ContactJson("CacheIntegratedService", task, commands, math.random())
				if not messages or #messages == 0 or not messages[1] or messages[1] == "" then
					break
				end
				local message = messages[1]
				self:Work(
					function()
						callback(self, message)
					end
				)
			end
		end
	)
end
