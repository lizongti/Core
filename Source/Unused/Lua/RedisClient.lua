module("RedisClient", package.seeall)

local redis = nil

function Init()
    if not redis then
        dofile(system.get_config_path().."/base.lua")
		redis = redis_client.connect(base_config.redis.host, base_config.redis.port, base_config.redis.password)
        _G.redis = redis
		if not redis then
			print("redis connect error.")
			return
		end
	end
end

--协程调用
function Execute(_, task, commands)
    if not redis then
        Init()
    end

    if not commands or #commands == 0 then
        return
    end

    if not task then
        redis:cmd_write(commands)
        return
    end

    local start_time = system.time()
    redis:cmd_asyn(commands)
    local data = task:Input()

    if #data == 1 and type(data[1]) == "table" then
        data = data[1]
    end

    local delta = system.time() - start_time

    if delta > 30 then
        LOG(RUN, INFO).Format("[RedisClient][Execute] spend a lot time %s cmd:%s", delta, commands[1])
    end
    return data
end
