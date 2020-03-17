----------------
--  LuaService --
----------------

require "Base/Logger"
require "Base/Protocol"
require "protobuf"
require "Base/LuaSession"
require "Base/Task"

-- Performance:
-- lua state packet digest 7k/s

_G.LuaService = {}

setmetatable(
	LuaService,
	{
		__index = LuaSession
	}
)

LuaService.services = {}

Base.Loop = function()
	for _, service in pairs(LuaService.services) do
		if service.loop then
			LuaService:Work(
				function()
					service.loop(service)
				end
			)
		end
	end
	LuaService:EverySecond(
		function()
			LuaService:Work(
				function()
					Task:Update()
				end
			)
			for _, service in pairs(LuaService.services) do
				service:CheckTimedWork()
			end
		end
	)
end

-- @static
function LuaService:New(service_name, setup_protocol)
	if Base[service_name] then
		return Base[service_name]
	end

	if not _G[service_name] then
		LOG(SYS, INFO).Format("[LuaService][New] %s service not exist!", service_name)
		return
	end

	local obj
	if _G[service_name].Instance then
		obj = _G[service_name]:Instance()
	else
		local f = _G[service_name].Create
		obj = f(_G[service_name])
	end

	local Instance = {
		name = service_name,
		package = _G[service_name],
		object = obj,
		client_id = nil,
		timed_works = {}
	}

	setmetatable(Instance, self)
	self.__index = self

	Base[service_name] = Instance
	table.insert(LuaService.services, Instance)

	if setup_protocol == nil or setup_protocol == true then
		Protocol:Init(service_name)
	end

	return Instance
end

function LuaService:Loop(loop)
	self.loop = loop
end

function LuaService:TimedWork(work, time)
	table.insert(
		self.timed_works,
		{
			work = work,
			time = time
		}
	)
end

function LuaService:CheckTimedWork()
	local now_time = os.time()
	for k, v in pairs(self.timed_works) do
		if now_time >= v.time then
			LuaService:Work(v.work)
			self.timed_works[k] = nil
		end
	end
end
