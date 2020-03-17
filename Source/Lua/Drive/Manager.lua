--------------------
--  Manager  --
--------------------
package.path = package.path .. ";" .. Base.Enviroment.cwd .. "/../Source/Lua/?.lua;"
require "Common/Common"
require "Module/Distributor"

LuaService:New("LoggerService")

LuaService:New("ManagerService"):Loop(
	function(self)
		if Container:LoadFinished() then
			for client_id = 0, Base.Enviroment.client_count - 1, 1 do
				self:Update(client_id)
			end
		end

		-- 处理与外部通信的消息队列
		for k, v in pairs(QueueCenter) do
			self:ReadQueue(k, v)
		end

		self:EverySecond(
			function()
				GlobalState:SyncFromCacheData(self)
				-- PlayerWatcher:CheckActive(self) -- disable expire feature
				PlayerWatcher:CheckMaintenance(self)
			end
		)

		Container:Update(self)
		Distributor:Update(self)
	end
)

function OnCacheReply(reply)
	--print("read cache json:", reply)
	local response = json.decode(reply)
	local task = Task:Get(response.id)
	if task then
		task:Activate(response)
	else
		LOG(RUN, INFO).Format("[CacheIntegratedService][Loop] response json find task null %s!!!", reply)
	end
end

function OnDatabaseReply(reply)
	--print("read database json", reply)
	local response = json.decode(reply)
	local task = Task:Get(response.id)
	if task then
		task:Activate(response)
	else
		LOG(RUN, INFO).Format("[DatabaseIntegratedService][Loop] response json find task null %s!!!", response_str)
	end
end

LuaService:New("CacheIntegratedService"):Loop(
	function(self)
		self:EveryServeralSecond(
			function()
				HeartBeat:Cache(self)
			end,
			10
		)
	end
)

LuaService:New("DatabaseIntegratedService"):Loop(
	function(self)
		self:EveryServeralSecond(
			function()
				HeartBeat:Database(self)
			end,
			10
		)
	end
)