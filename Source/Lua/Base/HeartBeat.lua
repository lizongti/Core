---------------
--  HeartBeat  --
---------------
require "Base/Path"
require "Base/TableDefine"

_G.HeartBeat = {}

-- @static
function HeartBeat:Cache(session)
	for i = 1, 1, 1 do
		session:Work(function(task)
			local commands = { -- 两种命令写法都支持
				[1] = "PING",
				-- [2] = { -- redisAppendCommand 写法，key或者value中有空格时使用，数字自动转字符串
				-- 	cmd = "%s",
				-- 	args = {"PING"}
				-- }
			}
			session:ContactJson("CacheClientService", task, commands, i)
		end)
	end
end

-- @static
function HeartBeat:Database(session)
	for i = 1, 1, 1 do
		session:Work(function(task)
			local commands = {-- 两种命令写法都支持
				[1] = "SELECT 1",
				-- [2] = { -- SQL EscapeString 写法，防止客户端或者字符串sql注入时使用，数字自动转字符串
				-- 	sql = "SELECT ?",
				-- 	args = {1}
				-- }
			}
			session:ContactJson("DatabaseClientService", task, commands, i)
		end)
	end
end