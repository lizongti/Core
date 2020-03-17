---------------
--  Task    --
---------------
require "Base/Path"
require "Util/PrintExt"

local TASK_TIME = 10

_G.Task = {list = Container:Get("Task.list"), count = Container:Get("Task.count")}

-- @static
function Task:GetGlobalId()
    self.count[0] = self.count[0] and self.count[0] + 1 or 0
    return string.format("%s.%s.%s", Base.Enviroment.init_time, Base.Enviroment.thread_id, self.count[0])
end

local task_counter = 0
-- @static
function Task:New()
    task_counter = task_counter + 1

    local Instance = {id = self:GetGlobalId(), create_time = os.time(), name = task_counter}

    self.list[Instance.id] = Instance
    setmetatable(Instance, self)
    self.__index = self
    return Instance
end

-- @static
function Task:Get(id)
    return self.list[id]
end

-- @static
function Task:Current()
    local coro = coroutine.running()
    for k, task in pairs(self.list) do
        if task.coro == coro then
            return task
        end
    end
    return
end

-- @static
function Task:Delete(id)
    self.list[id] = nil
end

-- @static
local lastUpdateTime = os.time()
local lastNames = {}

function Task:Update()
    local now_time = os.time()
    local newNames = {}
    if now_time - lastUpdateTime > 1 then
        local count = 0
        for k, task in pairs(self.list) do
            count = count + 1
            if now_time - task.create_time > TASK_TIME then
                self.list[k] = nil
            end
            table.insert(newNames, task.name)
        end
        lastUpdateTime = now_time

        lastNames = newNames
    end
end

function Task:Count()
    local count = 0
    for k, task in pairs(self.list) do
        count = count + 1
    end
    return count
end

function Task:Init(func)
    self.coro = coroutine.create(function()
        func()
        self.list[self.id] = nil
    end)
	
    return self
end

function Task:Input()
    return coroutine.yield()
end

function Task:Start()
    self:Activate()
    return self
end

function Task:Activate(...)
    local status, result = coroutine.resume(self.coro, ...)
    if not status then
        LOG(RUN, FATAL).Format("[Task][Sandbox]%s", debug.traceback(self.coro, result))
        return false
    end
    return self
end

function Task:Work(work)
    local task = Task:New()
    task:Init(function()
        work(task)
    end)
    task:Start()
end