require "Bootstrap"
require "FastConfig"
require "BaseConfig"

local c = {concurrency = 20, index = 3}
FastConfig:New(BaseConfig, c)
print(string.format("dispatcher%s - manager通信zmq端口%s", c.index, BaseConfig.zeromq.manager.port + c.index))

FastConfig:DispatcherService()
FastConfig:ManagerClientService()
FastConfig:LoggerService()
FastConfig:CacheIntegratedService()
FastConfig:DatabaseIntegratedService()
