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

local c = {concurrency = 20}
FastConfig:New(BaseConfig, c)

FastConfig:BackstageService()
FastConfig:LoggerService()
FastConfig:CacheIntegratedService()
FastConfig:DatabaseIntegratedService()
