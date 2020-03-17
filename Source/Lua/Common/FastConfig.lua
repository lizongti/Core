------------------
--  Fast Config --
------------------
require "Base/Path"
require "Util/PrintExt"

_G.FastConfig = {}

function FastConfig:New(base_config, fast_config)
	setmetatable(self, {
		__index = base_config
	})
	self.base_config = base_config
	self.fast_config = fast_config
	self.config = {}
end

function FastConfig:Get()
	return self.config
end

function FastConfig:LoggerService()
	log_types = log_types or {"SYS", "RUN", "CSL", "OPT", "TST", "SPK"}
	self.config.LoggerService = {
		logs = {}
	}
	for _, log_type in ipairs(log_types) do
		table.insert(self.config.LoggerService.logs, {
	        properties = "log.properties",
	        logger = log_type,
		})
	end
	return self
end

function FastConfig:ManagerService(concurrency)
	concurrency = concurrency or self.fast_config.concurrency
	self.config.ManagerService = {
		zeromqs = {},
		lua = {
			id = 0,
			concurrency = 1,
			file = "../Source/Lua/Drive/Manager.lua",
			frame = 60
		},
		rabbitmq_readers = {},
		rabbitmq_writers = {},
	}
	for index = 0, concurrency - 1, 1 do
		table.insert(self.config.ManagerService.zeromqs, {
			host = self.base_config.zeromq.manager.host,
			port = self.base_config.zeromq.manager.port + index,
			is_server = 1,
		})
	end
	return self
end

function FastConfig:NotificationService(concurrency)
	concurrency = concurrency or self.fast_config.concurrency
	self.config.NotificationService = {
		zeromqs = {},
		lua = {
			id = 0,
			concurrency = 1,
			file = "../Source/Lua/Drive/Notification.lua",
			frame = 60
		}
	}
	for index = 0, concurrency - 1, 1 do
		table.insert(self.config.NotificationService.zeromqs, {
			host = self.base_config.zeromq.notification.host,
			port = self.base_config.zeromq.notification.port + index,
			is_server = 1,
		})
	end
	return self
end

function FastConfig:CacheIntegratedService(concurrency)
	-- concurrency = concurrency or self.fast_config.concurrency
	concurrency = 1 -- 和HeartBeat.lua的遍历个数对应
	self.config.CacheIntegratedService = {
		lines = {}
	}
	for index = 0, concurrency - 1, 1 do
		table.insert(self.config.CacheIntegratedService.lines, {
			redis = {
				host = self.base_config.redis.host,
				port = self.base_config.redis.port,
				password = self.base_config.redis.password
			}
		})
	end
	return self
end

function FastConfig:DatabaseIntegratedService(concurrency)
	-- concurrency = concurrency or self.fast_config.concurrency
	concurrency = 1 -- 和HeartBeat.lua的遍历个数对应
	self.config.DatabaseIntegratedService = {
		lines = {}
	}
	for index = 0, concurrency - 1, 1 do
		table.insert(self.config.DatabaseIntegratedService.lines, {
			mysql = {
				host = self.base_config.mysql.host,
				port = self.base_config.mysql.port,
				username = self.base_config.mysql.username,
				password = self.base_config.mysql.password,
				dbname = self.base_config.mysql.dbname,
			}
		})
	end
	return self
end

function FastConfig:ManagerClientService(index)
	index = index or self.fast_config.index
	self.config.ManagerClientService = {
		zeromq = {
			host = self.base_config.zeromq.manager.host,
			port = self.base_config.zeromq.manager.port + index,
			is_server = 0 
		}
	}
	return self
end

function FastConfig:NotificationClientService(index)
	index = index or self.fast_config.index
	self.config.NotificationClientService = {
		zeromq = {
			host = self.base_config.zeromq.notification.host,
			port = self.base_config.zeromq.notification.port + index,
			is_server = 0 
		}
	}
	return self
end

function FastConfig:DispatcherService(index)
	index = index or self.fast_config.index
	self.config.DispatcherService = {
		tcp_server = {
			host = "0.0.0.0",
			port = self.base_config.tcp.dispatcher + index,
			lua = {
				id = 0,
				concurrency = 1,
				file = "../Source/Lua/Drive/Dispatcher.lua",
				frame = 60
			}
		}
	}
	return self
end

function FastConfig:BackstageService()
	self.config.BackstageService = {
		lua = {
			id = 0,
			concurrency = 1,
			file = "../Source/Lua/Drive/Backstage.lua",
			frame = 60
		}
	}
	return self
end
