---------------------
--  Player Session --
--------------------
require "Base/Path"
require "Base/LuaSession"
require "Common/RobotManager"

local TASK_TIME = 10

local player_save_flag = -1
local player_save_time = 0

_G.PlayerSession = {
    sessions = Container:Get("PlayerSession.sessions"),
    player_index = Container:Get("PlayerSession.player_index")
}
setmetatable(PlayerSession, {__index = LuaSession})

-- @static
function PlayerSession:Get(index) -- by session id
    local robot_session = RobotManager.GetSessionByIndex(index)
    if (robot_session ~= nil) then
        return robot_session
    end

    self.sessions[index] = self.sessions[index] or self:New()
    return self.sessions[index]
end

-- @static
function PlayerSession:New()
    local Instance = {object = nil}
    setmetatable(Instance, self)
    self.__index = self

    return Instance
end

-- @static
function PlayerSession:Construct(connection, id)
    self.connection = connection
    -- object是一个c++对象
    self.object = Session:Construct(id)
    self.read_sequence_id = 0 -- start from 1
    self.id = id
    self.object:BindConnection(connection)
    self.task = nil
    self.task_list = {}
    self.player = nil
    self.logined = false
    self.stopped = false
    self.action_time = os.time()
    self.sessions[id] = self
    self.have_notify_destroy = false

    self.player_ad = nil -- 广告信息

    self.game_info = nil

    self.feature_condition = nil

    self.player_extern = nil

    self.slots_info = nil

    self.activity_info = nil

    self.delay_requests = {} -- 登录后再执行的包

    LOG(RUN, INFO).Format("[PlayerSession][Construct] already constructed, session id %s", self.id)
    return self
end

-- 设置session的player
function PlayerSession:SetPlayer(data, player_id)
    self.player = data
    self.player_index[player_id] = self
end

function PlayerSession:QueryPlayerIndex(player_id)
    return self.player_index[player_id]
end

function PlayerSession:Destroy()
    self:CheckTask()
    local task_count = 0
    for k, task in pairs(self.task_list) do
        task_count = task_count + 1
    end
    if (not self.have_notify_destroy) then
        self.have_notify_destroy = true
        if self.player then
            self:Work(
                function()
                    self.player.character.off_line_time = os.time()
                    LOG(RUN, INFO).Format(
                        "[PlayerSession][Destroy] player_id:%s, time is: %s",
                        self.player.id,
                        self.player.character.off_line_time
                    )
                end
            )
        end
        Base.ManagerClientService:ReadRouterPacket(
            {
                header = {
                    router = "Command",
                    module_id = "Command",
                    message_id = "Command_FinishDrop_Request"
                },
                session_id = self.id
            }
        )
    end

    self:Save(true)
    self.object:UnbindConnection()
    Session:Destroy(self.object)
    self.object = nil
    LOG(RUN, INFO).Format("[PlayerSession][Destory] already destroyed, session id %s", self.id)

    if self.sessions[self.id] and self.sessions[self.id].player and self.sessions[self.id].player.id then
        local player_id = self.sessions[self.id].player.id
        LOG(RUN, INFO).Format("[PlayerSession][Destory] already destroyed, player_id %s", player_id)
        self.player_index[player_id] = nil
    end
    self.sessions[self.id] = nil
    return true
end

function PlayerSession:Stop()
    if self.stopped then
        LOG(RUN, INFO).Format("[PlayerSession][Stop] repeated stop, session id %s", self.id)
        self.object:StopConnection()
    else
        LOG(RUN, INFO).Format("[PlayerSession][Stop] first stop, session id %s", self.id)
        self.object:StopConnection()
        self.stopped = true
    end
end

function PlayerSession:Save(force)
    if self.player and not self.player.save_time then
        self.player.save_time = self.player.save_time or 0
    end

    if self.player and (os.time() - self.player.save_time > 2 or force) then
        self.player.version = (self.player.version or 0) + 1
        self.player.save_time = os.time()
        self.player.expire = os.time() + 600
        local commands = TableCache:GetActionCommand(self.player)
        local task = Task:New()
        task:Init(
            function()
                self:ContactJson("CacheClientService", task, commands, self.player.id)
            end
        )
        task:Start()
    end
end

function PlayerSession:Work(work)
    -- 每一次work，都会重新设置该task
    local task = Task:New()
    self.task = task
    self.task_list[task.id] = task

    self.task:Init(
        function()
            work(task)
            self.task_list[task.id] = nil
        end
    )

    self.task:Start()

    self.action_time = os.time()
end

function PlayerSession:CheckActive()
    local now_time = os.time()

    -- over time stop connection
    if now_time - self.action_time > 300 then
        LOG(RUN, INFO).Format("[PlayerSession][Stop] over time not action, force stop, session id %s", self.id)
        self:Stop()
        return false
    end

    return true
end

function PlayerSession:CheckTask()
    local now_time = os.time()

    -- over time clear task
    for k, task in pairs(self.task_list) do
        if now_time - task.create_time > TASK_TIME then
            self.task_list[k] = nil
        end
    end
end

function PlayerSession:OnNewPacket(object)
    self:Work(
        function()
            -- create input_packet
            self.read_sequence_id = self.read_sequence_id + 1
            -- 创建一个lua中用的包
            local packet = LuaPacket:CreateReadPacket(object, self.read_sequence_id)

            -- check packet valid
            if not packet then
                LOG(RUN, ERROR).Format("[PlayerSession][Update] packet is not valid, session id %s", self.id)
                self.connection:Stop()
                return
            end

            -- check message valid
            if not packet.data then
                LOG(RUN, ERROR).Format("[PlayerSession][Update] input message not valid, session id %s", self.id)
                packet:Abandon()
                return
            end

            -- 这是一个客户端请求包
            -- force router as Request
            packet.data.header.router = "Request"
            local header = packet.data.header
            self:ReadRouter(packet)
        end
    )
end

-- 客户端会话更新
function PlayerSession:Update()
    -- self:CheckActive() -- disable expire feature
    self:CheckTask()
    self:Save()
end
