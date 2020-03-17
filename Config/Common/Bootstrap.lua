module("Bootstrap", package.seeall)

Run = function(self, config)
    -- for service_name, service_config in pairs(config) do
    --     local service = LuaService:New(service_name, true)
    --     if not service then
    --         LOG(SYS, ERROR).Format("[LuaService][Boot] %s Init Failed!", service_name)
    --         return
    --     end
    --     service.config = json.encode(service_config)
    --     if not service.object:Running() then
    --         if service.object:Init(service.config) then
    --             LOG(SYS, INFO).Format("[LuaService][Boot] %s Init Success!", service_name)
    --         else
    --             LOG(SYS, ERROR).Format("[LuaService][Boot] %s Init Failed!", service_name)
    --             return
    --         end
    --     end
    -- end
    -- for service_name, _ in pairs(config) do
    --     local service = LuaService:New(service_name)
    --     if not service.object:Running() then
    --         if service.object:Boot() then
    --             LOG(SYS, INFO).Format("[LuaService][Boot] %s Boot Success!", service_name)
    --         else
    --             LOG(SYS, ERROR).Format("[LuaService][Boot] %s Boot Failed!", service_name)
    --             return
    --         end
    --     end
    -- end
    -- if Base.LoggerService then
    --     LOG(SYS, INFO).Format("[LuaService][Boot] Wait For Logger Service Finish!")
    -- else
    --     LOG(SYS, FATAL).Format("[LuaService][Boot] Logger Service Did Not Boot!")
    -- end
end
