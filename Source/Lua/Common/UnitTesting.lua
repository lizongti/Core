module("UnitTesting", package.seeall)


local function RunAllSuitePrivate()
    package.path = package.path .. ";" .. Base.Enviroment.cwd .. "/../Source/Lua/Testing/?.lua;"
    -- require("Testing/example_with_luaunit")
    require("Testing/StringTest")
    require("Testing/LuckyCalTest")

    local lu = require('luaunit')
    local runner = lu.LuaUnit.new()
    runner:setOutputType("tap")
    runner:runSuite()
end

function RunAllSuite()
    local success, error = pcall(RunAllSuitePrivate)
    if not success then
        print("unit test error:", error)
    end
end

RunAllSuite()
