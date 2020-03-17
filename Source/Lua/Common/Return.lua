--------------
--  Return  --
--------------
require "Base/Path"
require "Util/PrintExt"
require "Util/TableExt"
require "Config/system/I18nTextConfig"
require "Config/system/ReturnConfig"
-- Usage: 
--      ret = Return.OK()

_G.Return = {}
Return.objects = {}

function Return:Init()
    setmetatable(self, {
	    __index = self.objects
    })
    for k,v in pairs(ReturnConfig) do
        local tag = v.alias
        local code = v.code
        self.objects[tag] = function()
            local ret = {
                code = code,
                msg = "",
            }
            if I18nTextConfig[v.error_text_id] then
                ret.msg = I18nTextConfig[v.error_text_id].text_lan[_G.LANGUAGE]
            end
            return ret
        end
    end
end

Return:Init()
