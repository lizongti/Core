require "Common/RequestFilter"
require "Common/LineNum"
require "Common/Player"
require "Common/RobotManager"
require "Module/DailyMissions"
module("SlotsRobotServer", package.seeall)
dur_time = os.time()
g_action_time = os.time() + 5--1000
g_init_time = os.time()
g_flag = 1
Run = function(self)
    local cur_time = os.time()
    if ((Base.Enviroment.program_name == "robot") and cur_time - g_init_time > 10) then
        RobotManager.Init()
        RobotManager.InitRobots(1)

        RobotManager.EventLoop()

        if (os.time() >= g_action_time) then
            g_action_time = g_action_time + 1

            RobotManager.Save()

            RobotManager.ResetFreeSession()

            RobotManager.Spin()

            --RobotManager.BroadCast()

            RobotManager.Monitor()
        end
    end

    if (Base.Enviroment.program_name == "schedule" and cur_time - g_init_time > 10) then
        if os.time() - dur_time > 60 then
            dur_time = os.time()
            LOG(RUN, INFO).Format("[SlotsRobotServer]running...")
        end
        DailyMissions:RefreshDailyMessions(self)
        TournamentManager:TimeTick(self) 	--锦标赛的定时调用
        FeverQuestCal.OnFeverQuestSeasonTimeUpdate(self) --刷新fever quest排行
        BoosterCal.OnScheduleUpdate(self) --刷新booster cashback
    end
end