package.path =
    table.concat(
    {
        package.path,
        Base.Enviroment.config_path .. "/?.lua",
        Base.Enviroment.config_path .. "/Common/?.lua",
        Base.Enviroment.config_path .. "/Enviroment/" .. Base.Enviroment.enviroment_variable .. "/?.lua",
        Base.Enviroment.config_path .. "/Instance/?.lua",
        string.match(string.sub(debug.getinfo(1).source, 2, -1), "^.*/") .. "?.lua"
    },
    ";"
)

require(Base.Enviroment.instance_name)

Bootstrap.Run(FastConfig:Get())
