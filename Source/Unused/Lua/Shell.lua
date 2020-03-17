shell = shell or {}

local function sprint(v)
    local vals = string.split(v, ".")
    local t = _G[vals[1]]
    for i = 2, #vals do t = t[vals[i]] end
    return inspect(t)
end

local function enableDDZLog(enabled) _G.DDZAntibug.enable_log = enabled end

local function ddz()
    local room_count = 0
    local lock_room_count = 0
    for _, room in pairs(DDZContest.DDZContainer.rooms) do
        for _, tab in pairs(room) do
            room_count = room_count + 1
            if tab.need_robot == 0 then lock_room_count = lock_room_count + 1 end
        end
    end
    return string.format("room:%s %s", room_count, lock_room_count)
end

local function reloadModule() Protocol:Reload() end

local function reload(f)
    if f then
        local path = Base.Enviroment.cwd .. "/../Source/Lua/" .. f
        LOG(RUN, INFO).Format("reload:%s", path)
        dofile(path)
	    
	    if f:find("Module") then
		    local mod = f:gsub("Module/", "")
	        mod = mod:gsub(".lua", "")
		    Protocol:ReloadModule(mod)
		end
    end
end

function shell.cmd(cmd)
    local cmds = string.split(cmd, " ")
    if cmds[1] == "p" then return sprint(cmds[2]) end

    if cmds[1] == "ddz" then return ddz() end

    if cmds[1] == "reload" then
        reload(cmds[2])
        return "reload ok"
    end

    if cmds[1] == "reloadm" then
        reloadModule()
        return "reload module ok"
    end

    if cmds[1] == "log" then
        enableDDZLog(cmds[2] == '1')

        if cmds[2] == '1' then
            return "enable ok"
        else
            return "disable ok"
        end
    end

    return string.format("command %s not found", cmd)
end

