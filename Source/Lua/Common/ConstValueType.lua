local DataType = {
    String = 1,
    Number = 2,
}

local AllTypes = {
    FeverQuest_LevelLimit = {20, DataType.Number},
    NewLoginAward_ReturnDay = {26, DataType.Number},
    NewLoginAward_LevelLimit = {27, DataType.Number},
}

local function InitType(id)
    for k, v in pairs(AllTypes) do
        if id == v[1] then
            local s = {key = k}
            s.id = v[1]
            s.type = v[2]
            if s.type == DataType.String then
                ConstValue[k] = tostring(ConstValue[id].value)
            elseif s.type == DataType.Number then
                ConstValue[k] = tonumber(ConstValue[id].value)
            end
        end
    end
end

function InitValues()
    for k, v in pairs(ConstValue) do
        InitType(k)
    end
end

InitValues()
