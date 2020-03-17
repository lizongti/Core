-----------------------
--     Dispatcher    --
-----------------------
package.path = package.path..";"..Base.Enviroment.cwd.."/../Source/Lua/?.lua;"
require "Common/Common"
require "Module/SlotsRobotServer"
require "Common/TournamentManager"
require "Util/Debug"


LuaService:New("LoggerService")

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

LuaService:New("BackstageService"):Loop(
	function(self)
		SlotsRobotServer.Run(self)
		Container:Update(self)
	end
)

LuaService:New("CacheIntegratedService"):Loop(
	function(self)
		self:EveryServeralSecond(function()
			HeartBeat:Cache(self)
		end, 10)
	end
)

LuaService:New("DatabaseIntegratedService"):Loop(
	function(self)
		self:EveryServeralSecond(function()
            HeartBeat:Database(self)
		end, 10)
	end
)