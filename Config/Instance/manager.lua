------------------
--     Main     --
------------------
package.path =
    table.concat(
    {
        package.path,
        Base.Enviroment.config_path .. "/?.lua",
        string.match(string.sub(debug.getinfo(1).source, 2, -1), "^.*/") .. "?.lua"
    },
    ";"
)

require "Bootstrap"
require "FastConfig"
require "BaseConfig"

FastConfig:New(BaseConfig, {concurrency = 16, index = 8})
FastConfig:ManagerService()
FastConfig:LoggerService()
FastConfig:CacheIntegratedService()
FastConfig:DatabaseIntegratedService()
