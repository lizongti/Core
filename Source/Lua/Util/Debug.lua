module("Debug", package.seeall)

local tconcat = table.concat
local tinsert = table.insert
local srep = string.rep
local type = type
local pairs = pairs
local tostring = tostring
local next = next

local socks_prompt = "debug>"
local debug_env = {}
local debug_cmd = {}
local im_cmd = {}
local enter_im = false
local in_hook = false

local function tostring_r(root)
    if not root then
        return nil
    end
    if type(root) ~= "table" then
        return tostring(root)
    end
    local cache = {[root] = "."}
    local function _dump(t, space, name)
        local temp = {}
        for k, v in pairs(t) do
            local key = tostring(k).." ** "
            if cache[v] then
                tinsert(temp, "+" .. key .. " {" .. cache[v] .. "}")
            elseif type(v) == "table" then
                local new_key = name .. "." .. key
                cache[v] = new_key
                tinsert(temp, "+" .. key .. _dump(v, space .. (next(t, k) and "|" or " ") .. srep(" ", #key), new_key))
            else
                tinsert(temp, "+" .. key .. " [" .. tostring(v) .. "]")
            end
        end
        return tconcat(temp, "\n"..space)
    end
    return _dump(root, "", "")
end


local function short_value(root)
    if type(root) ~= "table" then
        if type(root) == "string" then
            return string.format("'%s'", root)
        end
        return tostring(root)
    end
    local cache = {[root] = "."}
    local function _dump(t, name, depth)
        local temp = {}
        for k, v in ipairs(t) do
            if v and type(v) == "table" then
                local key = tostring(k)
                local new_key = string.format("[%d].%s", k, key)
                tinsert(temp, _dump(v, new_key, depth + 1))
            else
                tinsert(temp, tostring(v))
            end
        end
        for k, v in pairs(t) do
            local key
            if type(k) ~= "number" then
                key = tostring(k)
                k = 0
            else
                key = "[" .. k .. "]"
            end
            if not(k > 0 and k <= #t) then
                if cache[v] then
                    tinsert(temp, string.format("%s = @%s", key, cache[v]))
                elseif v and type(v) == "table" and depth < 3 then
                    local new_key = name .. "." .. key
                    cache[v] = new_key
                    tinsert(temp, string.format("%s = { %s }", key, _dump(v, new_key, depth + 1)))
                else
                    if type(v) == "string" and v then
                        v = string.format("'%s'", v)
                    end
                    tinsert(temp, string.format("%s = %s", key, tostring(v)))
                end
            end
        end
        return tconcat(temp, ", ")
    end
    local v = _dump(root, "", 0)
    if #v > 512 then
        return string.format("{ %s ...}", string.sub(v, 1, 510))
    else
        return string.format("{ %s }", v)
    end
end

function info(...)
    io.write("[Debug][Variable]")
    for _, v in ipairs {...} do
        io.write(type(v) .. " \n"..tostring_r(v) .. " ")
    end
    print()
end

local function localinfo(level)
    local s = level or 2
    local info = debug.getinfo(s, "uf")

    local tmp = {}

    local index = 1
    while true do
        local name, value = debug.getlocal(s, index)
        if name == nil then
            break
        end
        tinsert(tmp, string.format("L %s : %s", name, short_value(value)))
        index = index + 1
    end
    for i = 1, info.nups do
        local name, value = debug.getupvalue(info.func, i)
        tinsert(tmp, string.format("U %s : %s", name, short_value(value)))
    end

    Debug.info("local var:", tmp)
end

local function line(level)
    local info = debug.getinfo(level, "Sl")
    return string.format("%s:%d>", info.short_src, info.currentline)
end

local function lineshort(level)
    local info = debug.getinfo(level, "Sl")
    return string.format("%s:%d>", info.short_src:match("/(%w+.lua)"), info.currentline)
end

function localvars()
    print(string.format("------------------- local vars(%s) ----------------", lineshort(3)))
    --localinfo(2)
    localinfo(3)
    --localinfo(4)
    print("--------------- end of local vars ----------------")
end

function tick(time, id)
	local t = system.time()
    time = time or t
	LOG(RUN, INFO).Format("%s---------------tick: %s", id, t-time)
	return t
end

function error(msg)
    LOG(RUN, FATAL).Format("[Task][Sandbox]%s", debug.traceback(coroutine.running(), msg))
end

