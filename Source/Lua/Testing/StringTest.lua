local lu = require('luaunit')

TestString = {}

function TestString:setUp()
    
end

function TestString:test1_chip()
    lu.assertEquals(string.chip(12), "12")
    lu.assertEquals(string.chip(0), "0")
    lu.assertEquals(string.chip(-10), "-10")
    lu.assertEquals(string.chip(1234567), "1,234,567")
    lu.assertEquals(string.chip(1234), "1,234")
    lu.assertEquals(string.chip(123), "123")
end
