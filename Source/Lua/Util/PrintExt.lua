require "Util/TableExt"

GlobalSlotsTest = {}

ToString = function(o)
    if (Base.Enviroment.pro_spec_t ~= "online") then
        if "nil" == type(o) then
            return tostring(nil)
        elseif "table" == type(o) then
            return table.show(o)
        elseif "string" == type(o) then
            return o
        else
            return tostring(o)
        end
    end
end

Print = function(...)
    local data = {...}
    table.foreach(
        data,
        function(k, v)
            data[k] = ToString(v)
        end
    )
    local str = ""
    for _, v in pairs(data) do
        str = string.format("%s%s", str, v)
    end
    print(str)
end

Table2Str = function(...)
    if (Base.Enviroment.pro_spec_t ~= "online") then
        local data = {...}
        for k, v in pairs(data) do
            data[k] = ToString(v)
        end

        local str = ""
        for _, v in pairs(data) do
            str = string.format("%s%s", str, v)
        end
        return str
    else
        return ""
    end
end
