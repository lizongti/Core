------------------
-- Rank Helper --
------------------

_G.RankHelper = {}

--[[
player = 2;		// always needed
player_id = 3;	// always needed
timestamp = 4;	// always needed
chip = 5;		// always needed
category = 6;	// always needed
sub_type = 7;	// conditional eg:中奖类型
extend = 8;		// conditional eg:中奖视频
sub_category = 9; // conditional eg:设备号
prize = 10;		// conditional eg:上榜奖励
score = 11;		// conditional eg:豪胜榜分数
]]

function RankHelper:Challenge(data)
    -- Base.ManagerClientService:WriteRouterPacket({
    --     header = {
    --         router = "AsyncRequest",
    --         service_name = "ManagerClientService",
    --         task_id = Task:GetGlobalId(),
    --         module_id = "Rank",
    --         message_id = "Rank_Challenge_Request",
    --     },
    --     data_json = json.encode(data),
    -- })
end

function RankHelper:ChallengeChip(player, origin_chip)
    -- if player.character.player_type == tonumber(ConstValue[5].value) then
    --     return
    -- end
    -- if origin_chip >= GlobalState:Get("Rank.rank_chip_min") or player.character.chip >= GlobalState:Get("Rank.rank_chip_min") then
    --     self:Challenge({
    --         player_id = player.id,
    --         category = "rank_chip",
    --         timestamp = os.time(),
    --         chip = player.character.chip, -- client show this as chip
    --         player = Player:GetBrief(player)
    --     })
    -- end
end

function RankHelper:ChallengeDailyWin(player)

end

function RankHelper:ChallengeWeeklyWin(player)

end

function RankHelper:ChallengeDailyBiggestWin(player, game_type, rep_data)

end

function RankHelper:ChallengeWeeklyBiggestWin(player, game_type, rep_data)

end

function RankHelper:ChallengeExperience(player)
    -- if player.character.player_type == tonumber(ConstValue[5].value) then
    --     return
    -- end
    -- if player.character.experience >= GlobalState:Get("Rank.rank_experience_min") then
    --     self:Challenge({
    --         player_id = player.id,
    --         category = "rank_experience",
    --         timestamp = os.time(),
    --         experience = player.character.experience,
    --         player = Player:GetBrief(player),
    --         score = player.character.experience,
    --     })
    -- end
end

function RankHelper:ChallengeUpdate(player)
    -- if player.character.player_type == tonumber(ConstValue[5].value) then
    --     return
    -- end
    -- RankHelper:ChallengeExperience(player)
    -- --RankHelper:ChallengeDailyWin(player)
    -- --RankHelper:ChallengeWeeklyWin(player)
end

