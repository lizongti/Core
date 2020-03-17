-----------------------
--     Dispatcher    --
-----------------------
package.path = package.path .. ";" .. Base.Enviroment.cwd .. "/../Source/Lua/?.lua;"
require "Common/Common"
require "Module/SlotsRobotServer"
require "Common/TournamentManager"
require "Util/Debug"

LuaService:New("LoggerService")

function OnNewPacket(index, packet)
	PlayerSession:Get(index):OnNewPacket(packet)
end

function OnCacheReply(reply)
	-- print("read cache json:", reply)
	local response = json.decode(reply)
	local task = Task:Get(response.id)
	if task then
		task:Activate(response)
	end
end

function OnDatabaseReply(reply)
	-- print("read database json:", reply)
	local response = json.decode(reply)
	local task = Task:Get(response.id)
	if task then
		task:Activate(response)
	end
end

function OnConnectionEvent(index, connection, event)
	if connection then
		if event == "Construct" then
			PlayerSession:Get(index):Construct(connection, index)
		elseif event == "Destroy" then
			PlayerSession:Get(index):Destroy()
		elseif event == "Update" then
			PlayerSession:Get(index):Update()
		end
	end
end

LuaService:New("DispatcherService"):Loop(
	function(self)
		self:EverySecond(
			function()
				GlobalState:SyncGlobalState(self)
				GlobalState:SaveChangesToCache(self)
			end
		)
		Container:Update(self)
	end
)

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

LuaService:New("ManagerClientService"):Loop(
	function(self)
		self:Update()
	end
)