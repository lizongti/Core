module("FeverQuestCal", package.seeall)

local is_fever_quest_open = true

local fever_quest_update_time = os.time()
local last_season_id = nil
local finished_season_id = 0

FeverQuestTierType = {
    TierTypeNovice = 1,
    TierTypeVeteran = 2,
    TierTypeLegend = 3,
    TierTypeAncient = 4,
    TierTypeDivine = 5,
}

FeverQuestMissionType = {
    MissionTypeBaseGameBetCount = 1,
    MissionTypeBaseGameWinCount = 2,
    MissionTypeBaseGameWinChip = 3,
    MissionTypeFreeSpinCount = 4,
    MissionTypeFreeSpinWinChip = 5,
    -- TIKI的hold spin
    MissionTypeHoldSpinCount = 6,
    MissionTypeHoldSpinWinChip = 7,
    MissionTypeLightingRespinCount = 8,
    MissionTypeLightingRespinWinChip = 9,
    MissionTypeDynamiteRespinCount = 10,
    MissionTypeDynamiteRespinWinChip = 11,
    -- 
    MissionTypeCoinRespinCount = 12,
    MissionTypeCoinRespinWinChip = 13, --ok
    -- 进入bonus小游戏
    MissionTypeMiniGameCount = 14, 
    MissionTypeMiniGameWinChip = 15,
    MissionTypeRapidHitClassicCount = 16, --
    MissionTypeRapidHitMiniClassicCount = 17, --
    MissionTypePiggyMapStepCount = 18,
    MissionTypeFrozenRespinCount = 19,
    MissionTypeFrozenRespinWinChip = 20,
    -- 中minor jackpot
    MissionTypeMinorJackpotCount = 21,
    MissionTypeCashRainFeatureCount = 22,
    MissionTypeCashRainFeatureWinChip = 23,
    -- lucky
    MissionTypeLuckyChristmasRespinCount = 24,
    MissionTypeLuckyChristmasRespinWinChip = 25,
}

-- 51023464
function GetSeasonFirstTaskId(season_id)
    if season_id <= 0 then
        return 0
    end

    for i=1, #QuestFeverMissionSortConfig do
        local v = QuestFeverMissionSortConfig[i]
        if v.season_id == season_id then
            return v.id
        end
    end

    return 1
end

function GetFeverQuestProgresses(session, fever_quest_info)
    local sort_config = QuestFeverMissionSortConfig[fever_quest_info.task_id]

    if not sort_config then
        LOG(RUN, INFO).Format("[FeverQuestCal][GetFeverQuestProgresses] sort config is null player %s task_id %s", 
            session.player.id, fever_quest_info.task_id)
        return {}
    end

    local mission = QuestFeverMissionConfig[sort_config.gametype]
    local progresses = {}

    for i=1, #mission.mission_type do
        local _type = mission.mission_type[i]
        fever_quest_info.missions = fever_quest_info.missions or {}
        local value = fever_quest_info.missions["type".._type] or 0
        local total_progress = GetTotalProgress(sort_config, fever_quest_info, mission.parameter_value[i], mission.parameter_is_disturbed[i])

        table.insert(progresses, {
            mission_type = _type,
            mission_progress = value,
            mission_target = total_progress
        })
    end

    return progresses
end

function GetFeverQuestInfoAll(session)
    if not is_fever_quest_open then
        LOG(RUN, INFO).Format("[FeverQuestCal][GetFeverQuestInfoAll] is_fever_quest_open is false")
        return
    end

    local player = session.player

    LOG(RUN, INFO).Format("[FeverQuestCal][GetFeverQuestInfoAll] get activity %s", player.id)
    local fever_quest_info = ActivityCal.Calculate.GetActivityInfo(session, ActivityDefine.AllTypes.FeverQuest)

    local current_season_id = GetCurrentSeasonId()

    if current_season_id <= 0 then
        return
    end

    LOG(RUN, INFO).Format("[FeverQuestCal][GetFeverQuestInfoAll] datas %s current_season_id %s ", player.id, current_season_id)

    -- 初始化为第一关
    fever_quest_info.task_id = fever_quest_info.task_id or GetSeasonFirstTaskId(current_season_id)

    fever_quest_info.task_fetch_level = fever_quest_info.task_fetch_level or player.character.level
    
    -- 初始化难度为0
    fever_quest_info.hard_level = fever_quest_info.hard_level or 0
    
    -- 星星初始化为0
    fever_quest_info.star = fever_quest_info.star or 0
    
    -- 是否加速
    fever_quest_info.boost_end_time = fever_quest_info.boost_end_time or 0
    fever_quest_info.boost_multier = fever_quest_info.boost_multier or 1

    -- 当前排名等级
    -- 上一个季度的阶位
    fever_quest_info.last_tier = fever_quest_info.last_tier or FeverQuestTierType.TierTypeNovice
    fever_quest_info.tier_update_season_id = fever_quest_info.tier_update_season_id or 1

    -- 新的季度，暂时屏蔽
    if current_season_id > fever_quest_info.tier_update_season_id then
        local star = fever_quest_info.star
        local last_season_id = fever_quest_info.tier_update_season_id
        local tier = fever_quest_info.last_tier
        -- 清空星星
        fever_quest_info.star = 0
        -- 获取新的季度第一个关卡
        fever_quest_info.task_id = GetSeasonFirstTaskId(current_season_id)

        fever_quest_info.task_fetch_level = player.character.level

        -- 更新season_id
        fever_quest_info.tier_update_season_id = current_season_id
        
        -- 升级
        if star >= QuestFeverRankTierConfig[tier].tierup_stars then
            fever_quest_info.last_tier = fever_quest_info.last_tier + 1
        end

        -- 降级
        if star <= QuestFeverRankTierConfig[tier].tierdown_stars then
            fever_quest_info.last_tier = fever_quest_info.last_tier - 1
        end

        -- 看下中间有几个季度没有参加
        local season_delta = current_season_id - last_season_id

        fever_quest_info.last_tier = fever_quest_info.last_tier - (season_delta-1)

        -- 添加到历史记录中
        fever_quest_info.history = fever_quest_info.history or {}

        fever_quest_info.history["season"..last_season_id] = {
            season = last_season_id,
            tier_type = tier,
            rank = GetRankWithSeasonTier(session, last_season_id, tier)
        }

        for i=1, (season_delta-1) do
            local sid = last_season_id+i
            local skip_tier = tier - i

            if skip_tier < 1 then skip_tier = 1 end

            fever_quest_info.history["season"..sid] = {
                season = sid,
                tier_type = skip_tier,
                rank = GetRankWithSeasonTier(session, sid, skip_tier)
            }
        end

        LOG(RUN, INFO).Format("[FeverQuestCal][GetFeverQuestInfoAll] 新的季度 player %s tier %s last_season_id %s season %s", 
            player.id, fever_quest_info.last_tier, last_season_id, current_season_id)

        SaveFeverQuestInfo(session)
    end

    return fever_quest_info
end

function GetRankWithSeasonTier(session, season_id, tier)
    local player = session.player
    local rank_key = string.format("fever_quest_season%s_tier%s", season_id, tier)
    local async_request = {[1] = string.format("zrank %s %s", rank_key, player.id)}

    LOG(RUN, INFO).Format("[FeverQuest][GetRankWithSeasonTier] player id %s zrank %s begin", player.id, async_request[1])

    local task = Task:Current()
    task.create_time = os.time()

    local response = LuaSession:ContactJson("CacheClientService", task, async_request, 0)

    LOG(RUN, INFO).Format("[FeverQuest][GetRankWithSeasonTier] player id %s end", player.id)

    if tonumber(response[1]) then
        return tonumber(response[1]) + 1
    end

    return 0
end

-- task_id为0表示当前没有任务了
-- task_id为nil表示没有初始化
function GetFeverQuestInfo(session)
    if not is_fever_quest_open then
        return
    end
    
    local player = session.player

    local fever_quest_info = ActivityCal.Calculate.GetActivityInfo(session, ActivityDefine.AllTypes.FeverQuest)

    local current_season_id = GetCurrentSeasonId()

    if not current_season_id or current_season_id <= 0 then
        return
    end

    -- 初始化为第一关
    fever_quest_info.task_id = fever_quest_info.task_id or 1

    fever_quest_info.task_fetch_level = fever_quest_info.task_fetch_level or player.character.level

    -- 初始化难度为0
    fever_quest_info.hard_level = fever_quest_info.hard_level or 1

    -- 星星初始化为0
    fever_quest_info.star = fever_quest_info.star or 0
    
    -- 是否加速
    fever_quest_info.boost_end_time = fever_quest_info.boost_end_time or 0
    fever_quest_info.boost_multier = fever_quest_info.boost_multier or 1

    -- 当前排名等级
    fever_quest_info.last_tier = fever_quest_info.last_tier or FeverQuestTierType.TierTypeNovice
    fever_quest_info.tier_update_season_id = fever_quest_info.tier_update_season_id or 1

    return fever_quest_info
end

function CalcNewTierWithStar(tier_type, season_id, star)
    local config = QuestFeverRankTierConfig[tier_type]
    if not config then
        return 1
    end

    return 1
end

function GetRankInfo(session, fever_quest_info)
    local info = {}
    info.tier_type = fever_quest_info.last_tier
    info.rank = 0
    info.star = fever_quest_info.star

    local player = session.player

    info.rank = GetRankWithSeasonTier(session, GetCurrentSeasonId(), fever_quest_info.last_tier)

    -- 历史排名
    local current_season_id = GetCurrentSeasonId()

    fever_quest_info.history = fever_quest_info.history or {}

    local historys = {}
    for i=1, current_season_id-1 do
        local data = fever_quest_info.history["season"..i]
        if data then
            table.insert(historys, data)
        end
    end

    LOG(RUN, INFO).Format("[FeverQuestCal][GetRankInfo] 获取排名 player %s last_tier %s rank %s", 
        player.id, info.tier_type, info.rank)

    info.historys = historys

    return info
end

function GetCurrentGameType(fever_quest_info)
    if not fever_quest_info then
        return 0
    end
    
    local task_id = fever_quest_info.task_id
    if not QuestFeverMissionSortConfig[task_id] then
        return 0
    end
    
    return QuestFeverMissionSortConfig[task_id].gametype
end

function GetCurrentSeasonId()
    local config
    for i=1, #QuestFeverSeasonConfig do
        local v = QuestFeverSeasonConfig[i]

        LOG(RUN, INFO).Format("GetCurrentSeasonId: season_id %s start_time %s end_time %s", v.season_id, v.season_start_time, v.season_end_time)

        local start = os.string2time(v.season_start_time)
        local end_time = os.string2time(v.season_end_time)
        local current = os.time()
        if current > start and current < end_time then
            config = v
            break
        end
    end

    if not config then return 0 end
    LOG(RUN, INFO).Format("GetCurrentSeasonId: %s", config.season_id)

    return config.season_id
end

local function CheckMissionFinished(session, fever_quest_info)
    -- 更新任务进度
    local sort_config = QuestFeverMissionSortConfig[fever_quest_info.task_id]
    local mission = QuestFeverMissionConfig[sort_config.gametype]
    local player = session.player
    local season_id = GetCurrentSeasonId()

    local complete = true

    for i=1, #mission.mission_type do
        local type = mission.mission_type[i]
        local value = fever_quest_info.missions["type"..type] or 0

        local total_progress = GetTotalProgress(sort_config, fever_quest_info, mission.parameter_value[i], mission.parameter_is_disturbed[i])

        if value < total_progress then
            complete = false
            break
        end
    end

    if complete then
        local level = fever_quest_info.task_fetch_level or session.player.character.level
        -- (ROUNDDOWN(level/10,0)-parameter_level_difficuly_a)*parameter_level_difficuly_b
        -- =C14*(1+B12)*(1+D12)*(1+F12)
        local level_extra = 1 + (math.floor(level/10) - sort_config.parameter_level_difficuly_a) * sort_config.parameter_level_difficuly_b
        local hard_level_extra = (1+sort_config.mode_extra_difficulty[fever_quest_info.hard_level])

        if level_extra < 1 then level_extra = 1 end
        if hard_level_extra < 1 then hard_level_extra = 1 end

        local total_chip = sort_config.base_prize_coins * (1 + sort_config.sort_extra_difficulty) * level_extra * hard_level_extra

        total_chip = math.floor(total_chip+0.5)

        -- 获取chip
        Player:Obtain(player, {"Chip", total_chip}, Reason.FEVERQUEST_FINISH_OBTAIN())

        -- 添加星星
        fever_quest_info.star = 0 --(fever_quest_info.star or 0) + sort_config.prize_stars

        -- 更新排名
        local rank_key = string.format("fever_quest_season%s_tier%s", GetCurrentSeasonId(), fever_quest_info.last_tier)

        local async_request = {
            [1] = string.format("zadd %s %s %s", rank_key, fever_quest_info.star, player.id) 
            }

        local task = Task:Current()
        task.create_time = os.time()

        LuaSession:ContactJson("CacheClientService", task, async_request, 0)

        LOG(RUN, INFO).Format("[FeverQuestCal][UpdateMissionProgress]更新排名 player %s rank %s star %s", player.id, rank_key, 
            fever_quest_info.star)

        -- 卡包
        if sort_config.prize_package > 0 then
            local fever_card_info = FeverCardCal.GetFeverCardInfo(session)
            FeverCardCal.OpenSourcePackage(session, fever_card_info, sort_config.prize_package, FeverCardSource.FeverQuestFinishTask)
        end

        -- 发送奖励
        session:WriteRouterPacket({
            header = {
                router = "Notice",
                module_id = "FeverQuest",
                message_id = "FeverQuest_FinishQuest_Notice",
            },
            task_id = fever_quest_info.task_id,
            star = fever_quest_info.star,
            player = {
                character = {
                    chip = player.character.chip
                },
            },
            win_chip = total_chip,
            is_finish = 1
        })

        LOG(RUN, INFO).Format(string.format("完成任务：%d chip %s star %s", fever_quest_info.task_id, total_chip, fever_quest_info.star))

        -- 清空数据
        fever_quest_info.task_id = GetNextTaskId(player, fever_quest_info, fever_quest_info.task_id)
        fever_quest_info.missions = {}

        Spark:FinishQuestFeverMission(session.player, {
            [1] = fever_quest_info.task_id,
            [2] = total_chip,
            [3] = sort_config.prize_stars,
            [4] = sort_config.prize_package,
            [5] = sort_config.season_id,
            [6] = sort_config.id,
            [7] = sort_config.level_id,
            [8] = fever_quest_info.hard_level,
            [9] = fever_quest_info.last_tier or 0
        })
    end

end

function GetFirstTaskId(season_id)
    for i=1, #QuestFeverMissionSortConfig do
        if QuestFeverMissionSortConfig[i].season_id == season_id then
            return QuestFeverMissionSortConfig[i].id
        end
    end
end

function IsLastTask(season_id, task_id)
    local f = false
    for i=#QuestFeverMissionSortConfig,1,-1 do
        if QuestFeverMissionSortConfig[i].season_id == season_id then
            f = QuestFeverMissionSortConfig[i].id == task_id
            break
        end
    end
    LOG(RUN, INFO).Format("检查是否是最后一关 season %s task_id %s %s", 
            season_id, task_id, f)
    return f
end

function GetNextTaskId(player, fever_quest_info, task_id)
    local sort_config = QuestFeverMissionSortConfig[task_id]
    local next_config = QuestFeverMissionSortConfig[task_id+1]
    local new_task_id = 0
    if next_config then new_task_id = next_config.id end

    -- 如果是最后一关，则重新开始
    if IsLastTask(sort_config.season_id, task_id) then
        local new_task_id = GetFirstTaskId(sort_config.season_id)
        LOG(RUN, INFO).Format("最后一关，重新开始 player %s season %s task_id %s new_task_id %s", player.id, 
            sort_config.season_id, task_id, new_task_id)
        fever_quest_info.hard_level = 0
        return new_task_id
    end

    local next_config = QuestFeverMissionSortConfig[task_id+1]

    if not next_config then
        -- 0 表示没有任务了
        return 0
    end

    local task = QuestFeverMissionConfig[sort_config.gametype]
    if sort_config.season_id == next_config.season_id then
        if sort_config.level_id ~= next_config.level_id then
            fever_quest_info.hard_level = 0
        end
        return next_config.id
    end

    -- 不同的season，等待season结束
    fever_quest_info.hard_level = 0
    return 0
end

function GetTotalProgress(sort_config, fever_quest_info, base_value, disturb)

    if fever_quest_info.hard_level == 0 then
        return 0
    end

    if base_value == -1 then
        return base_value
    end

    if disturb == 0 then
        return base_value
    end

    local level = fever_quest_info.task_fetch_level
    -- 等级加成
    local level_extra = 1 + (math.floor(level/10) - sort_config.parameter_level_difficuly_a) * sort_config.parameter_level_difficuly_b
    -- 难度加成
    local hard_level_extra = (1+sort_config.mode_extra_difficulty[fever_quest_info.hard_level])

    if level_extra < 1 then level_extra = 1 end
    if hard_level_extra < 1 then hard_level_extra = 1 end

    local total_value = base_value * (1 + sort_config.sort_extra_difficulty) * level_extra * hard_level_extra

    total_value = math.floor(total_value+0.5)

    return total_value
end

function AddProgress(session, fever_quest_info, type, value, game_type)
    if not is_fever_quest_open then
        return
    end

    local current_game_type = GetCurrentGameType(fever_quest_info)
    if current_game_type ~= game_type then
        LOG(RUN, INFO).Format("[FeverQuestCal][AddProgress] different game type %s %s", current_game_type, game_type)
        return
    end

    local sort_config = QuestFeverMissionSortConfig[fever_quest_info.task_id]

    if not sort_config then
        LOG(RUN, INFO).Format("[FeverQuestCal][AddProgress] sort config is null player %s task_id %s", 
            session.player.id, fever_quest_info.task_id)
        return
    end

    local mission = QuestFeverMissionConfig[sort_config.gametype]

    local updated = false

    local multi_value = value * GetBoostValue(fever_quest_info)

    for i=1, #mission.mission_type do
        local _type = mission.mission_type[i]
        if _type == type then
            fever_quest_info.missions = fever_quest_info.missions or {}
            fever_quest_info.missions["type"..type] = (fever_quest_info.missions["type"..type] or 0) + multi_value
            
            local total_progress = GetTotalProgress(sort_config, fever_quest_info, mission.parameter_value[i], 
                mission.parameter_is_disturbed[i])
            
            if fever_quest_info.missions["type"..type] > total_progress then
                fever_quest_info.missions["type"..type] = total_progress
            end

            updated = true

            LOG(RUN, INFO).Format(string.format("任务类型 %s 当前进度 %s/%s", type, fever_quest_info.missions["type"..type], total_progress))
        end
    end

    if updated then
        SendMissionProgressNotice(session, fever_quest_info)
        CheckMissionFinished(session, fever_quest_info)
        SaveFeverQuestInfo(session)
    end
end

function SendMissionProgressNotice(session, fever_quest_info)
    local sort_config = QuestFeverMissionSortConfig[fever_quest_info.task_id]
    local mission = QuestFeverMissionConfig[sort_config.gametype]

    -- 发送奖励
    session:WriteRouterPacket({
        header = {
            router = "Notice",
            module_id = "FeverQuest",
            message_id = "FeverQuest_UpdateQuestProgress_Notice",
        },
        task_id = fever_quest_info.task_id,
        progresses = GetFeverQuestProgresses(session, fever_quest_info)
    })
end

-----------------任务类型--------------------
function OnGameSpin(session, player, game_type, player_game_info, request, response, chip_cost, win_chip)
    if not is_fever_quest_open then
        return
    end

    if session.player.is_fever_quest ~= 1 then
        LOG(RUN, INFO).Format("[FeverQuestCal][OnGameSpin] spin is not from fever quest")
        return
    end

    local fever_quest_info = GetFeverQuestInfo(session)

    if not fever_quest_info then
        LOG(RUN, INFO).Format("[FeverQuestCal][OnGameSpin] fever quest is not open")
        return
    end

    if GetCurrentGameType(fever_quest_info) ~= game_type then
        LOG(RUN, INFO).Format("[FeverQuestCal][OnGameSpin] different game type")
        return
    end

    -- 获取当前season
    local season_id = GetCurrentSeasonId()

    if season_id <= 0 then
        return
    end

    local sort_config = QuestFeverMissionSortConfig[fever_quest_info.task_id]

    if sort_config.season_id ~= season_id then
        -- 时间没有到达这个season
        LOG(RUN, INFO).Format("[FeverQuestCal][OnGameSpin] different season id")
        return
    end

    -- base game
    local player_game_status = CommonCal.Calculate.GetPlayerGameStatus(session, nil, player, game_type)
    local cur_status = GameStatusCal.Calculate.GetGameStatus(player_game_status)

    -- 增加池子的值
    local key = string.format("fever_quest_pool_season%s_tier%s", season_id, fever_quest_info.last_tier)
    local async_request = {[1] = string.format("hincrby %s pool_value %s", key, chip_cost)}

    local task = Task:Current()
    task.create_time = os.time()
    --LuaSession:ContactJson("CacheClientService", task, async_request, 0)

    if cur_status == GameStatusDefine.AllTypes.BaseSpinGame or chip_cost > 0 then
        OnBaseGameSpinCount(session, fever_quest_info, game_type, request.amount, win_chip)
    end

    SaveFeverQuestInfo(session)
end

function SaveFeverQuestInfo(session)
    ActivityCal.Calculate.UpdateActivityInfo(session, ActivityDefine.AllTypes.FeverQuest)
end

-- 进入%d次Cash Rain Feature（Cash Rain）
function OnCashRainFeatureEnd(session, win_chip)
    local is_valid, fever_quest_info = IsQuestValid(session, GameType.AllTypes.CashRain)

    if not is_valid then
        return
    end
    
    if not fever_quest_info then
        return
    end

    local current_game_type = GetCurrentGameType(fever_quest_info)

    if win_chip then
        AddProgress(session, fever_quest_info, FeverQuestMissionType.MissionTypeCashRainFeatureCount, 1, current_game_type)
        AddProgress(session, fever_quest_info, FeverQuestMissionType.MissionTypeCashRainFeatureWinChip, win_chip, current_game_type)
    end
end

-- 中%d次Minor Jackpot（New Wild Circus）
function OnWinMinorJackpot(session, win_chip)
    local is_valid, fever_quest_info = IsQuestValid(session, GameType.AllTypes.NewWildCircus)

    if not is_valid then
        return
    end

    local current_game_type = GetCurrentGameType(fever_quest_info)
    AddProgress(session, fever_quest_info, FeverQuestMissionType.MissionTypeMinorJackpotCount, 1, current_game_type)
end

-- 小游戏 New Leprechaun Treasure，New Legends of Olympus，Dancing Drums，Alice in Wonderland
-- New Leprechaun Treasure，New Legends of Olympus，Dancing Drums，Alice in Wonderland，New Purrfect Pets, Lucky Christmas，Honey Fortune
function OnMiniGameEnd(session, game_type, win_chip)
    local is_valid, fever_quest_info = IsQuestValid(session, game_type)

    if not is_valid then
        return
    end

    if win_chip then
        LOG(RUN, INFO).Format("[FeverQuestCal][OnMiniGameEnd] bonus game win %s player %s", win_chip, session.player.id)
        AddProgress(session, fever_quest_info, FeverQuestMissionType.MissionTypeMiniGameCount, 1, game_type)
        AddProgress(session, fever_quest_info, FeverQuestMissionType.MissionTypeMiniGameWinChip, win_chip, game_type)
    end
end

-- 在地图上前进%d次（Piggy Jackpot）
function OnPiggyMapStep(session)
    local is_valid, fever_quest_info = IsQuestValid(session, GameType.AllTypes.PiggyJackpot)

    if not is_valid then
        return
    end

    local current_game_type = GetCurrentGameType(fever_quest_info)
    AddProgress(session, fever_quest_info, FeverQuestMissionType.MissionTypePiggyMapStepCount, 1, current_game_type)
end

-- Rapid Hit Jackpot
function OnRapidHitClassicSpin(session, fever_quest_info, player_game_info, game_type, win_chip, player_game_status)
    local is_valid, fever_quest_info = IsQuestValid(session, GameType.AllTypes.RapidHit)

    if not is_valid then
        return
    end

    local win_chip = GameStatusCal.Calculate.GetFinishedAward(player_game_status, GameStatusDefine.AllTypes.ClassicSpinGame)

    local current_game_type = GetCurrentGameType(fever_quest_info)

    if win_chip then
        AddProgress(session, fever_quest_info, FeverQuestMissionType.MissionTypeLightingRespinCount, 1, current_game_type)
        AddProgress(session, fever_quest_info, FeverQuestMissionType.MissionTypeLightingRespinWinChip, win_chip, current_game_type)
    end
end

-- Rapid Hit Mini Classic
function OnRapidHitMiniClassicSpin(session, fever_quest_info, player_game_info, game_type, win_chip, player_game_status)
    local is_valid, fever_quest_info = IsQuestValid(session, GameType.AllTypes.RapidHit)

    if not is_valid then
        return
    end

    local win_chip = GameStatusCal.Calculate.GetFinishedAward(player_game_status, GameStatusDefine.AllTypes.ClassicSpinGame)
    
    local current_game_type = GetCurrentGameType(fever_quest_info)

    if win_chip then
        AddProgress(session, fever_quest_info, FeverQuestMissionType.MissionTypeLightingRespinCount, 1, current_game_type)
        AddProgress(session, fever_quest_info, FeverQuestMissionType.MissionTypeLightingRespinWinChip, win_chip, current_game_type)
    end
end

function OnCoinRespinEnd(session, win_chip)
    local is_valid, fever_quest_info = IsQuestValid(session, GameType.AllTypes.NewPurrfectPets)

    if not is_valid then
        return
    end


    local current_game_type = GetCurrentGameType(fever_quest_info)

    if win_chip then
        AddProgress(session, fever_quest_info, FeverQuestMissionType.MissionTypeCoinRespinCount, 1, current_game_type)
        AddProgress(session, fever_quest_info, FeverQuestMissionType.MissionTypeCoinRespinWinChip, win_chip, current_game_type)
    end
end

-- lucky圣诞节
function OnLuckyChristmasRespinEnd(session, win_chip)
    local is_valid, fever_quest_info = IsQuestValid(session, GameType.AllTypes.LuckyChristmas)

    if not is_valid then
        return
    end


    local current_game_type = GetCurrentGameType(fever_quest_info)

    if win_chip then
        AddProgress(session, fever_quest_info, FeverQuestMissionType.MissionTypeLuckyChristmasRespinCount, 1, current_game_type)
        AddProgress(session, fever_quest_info, FeverQuestMissionType.MissionTypeLuckyChristmasRespinWinChip, win_chip, current_game_type)
    end
end

function OnDynamiteRespinEnd(session, win_chip)
    local is_valid, fever_quest_info = IsQuestValid(session, GameType.AllTypes.GoldMine)

    if not is_valid then
        return
    end


    local current_game_type = GetCurrentGameType(fever_quest_info)

    if win_chip then
        AddProgress(session, fever_quest_info, FeverQuestMissionType.MissionTypeDynamiteRespinCount, 1, current_game_type)
        AddProgress(session, fever_quest_info, FeverQuestMissionType.MissionTypeDynamiteRespinWinChip, win_chip, current_game_type)
    end
end

-- 宙斯respin
function OnLightingRespinEnd(session, win_chip)
    local fever_quest_info = GetFeverQuestInfo(session)

    if not fever_quest_info then
        return
    end

    local game_type = GetCurrentGameType(fever_quest_info)

    if game_type ~= GameType.AllTypes.ThunderZeus then
        return
    end

    if win_chip then
        AddProgress(session, fever_quest_info, FeverQuestMissionType.MissionTypeLightingRespinCount, 1, game_type)
        AddProgress(session, fever_quest_info, FeverQuestMissionType.MissionTypeLightingRespinWinChip, win_chip, game_type)
    end
end

-- TIKI hold spin
function OnTikiHoldSpinEnd(session, win_chip)
    local is_valid, fever_quest_info = IsQuestValid(session, GameType.AllTypes.TikiIsland)

    if not is_valid then
        return
    end

    local game_type = GameType.AllTypes.TikiIsland

    if win_chip then
        AddProgress(session, fever_quest_info, FeverQuestMissionType.MissionTypeHoldSpinCount, 1, game_type)
        AddProgress(session, fever_quest_info, FeverQuestMissionType.MissionTypeHoldSpinWinChip, win_chip, game_type)
    end
end

-- 进入%d次Frozen Respin（Frozen Era）
function OnFreeSpin(session, fever_quest_info, game_type, win_chip, total_spin_bouts)
    if total_spin_bouts > 0 then
        -- free spin次数
        AddProgress(session, fever_quest_info, FeverQuestMissionType.MissionTypeFreeSpinCount, total_spin_bouts, game_type)
        AddProgress(session, fever_quest_info, FeverQuestMissionType.MissionTypeFreeSpinWinChip, win_chip, game_type)
    end
end

-- 进入%d次Cash Rain Feature（Cash Rain）
function OnCashRainBonusGameEnd(session, win_chip)
    local fever_quest_info = GetFeverQuestInfo(session)

    local current_game_type = GetCurrentGameType(fever_quest_info)

    if win_chip then
        AddProgress(session, fever_quest_info, FeverQuestMissionType.MissionTypeCashRainFeatureCount, 1, current_game_type)
        AddProgress(session, fever_quest_info, FeverQuestMissionType.MissionTypeCashRainFeatureWinChip, win_chip, current_game_type)
    end
end

-- 中%d次Minor Jackpot（New Wild Circus）
function OnNewWildCircusWinMinorJackpot(session, win_chip)
    local fever_quest_info = GetFeverQuestInfo(session)

    local current_game_type = GetCurrentGameType(fever_quest_info)

    if win_chip then
        AddProgress(session, fever_quest_info, FeverQuestMissionType.MissionTypeMinorJackpotCount, 1, current_game_type)
    end
end

-- 进入%d次Frozen Respin（Frozen Era）
function OnFrozenEraRespinEnd(session, win_chip)
    local is_valid, fever_quest_info = IsQuestValid(session, GameType.AllTypes.FrozenEra)

    if not is_valid then
        return
    end

    local current_game_type = GetCurrentGameType(fever_quest_info)

    if win_chip then
        AddProgress(session, fever_quest_info, FeverQuestMissionType.MissionTypeFrozenRespinCount, 1, current_game_type)
        AddProgress(session, fever_quest_info, FeverQuestMissionType.MissionTypeFrozenRespinWinChip, win_chip, current_game_type)
    end
end

-- 中Rapid Hit特性%d次
function OnRapidHitClassicSpinEnd(session, win_chip)
    local is_valid, fever_quest_info = IsQuestValid(session, GameType.AllTypes.RapidHit)

    if not is_valid then
        return
    end


    local current_game_type = GetCurrentGameType(fever_quest_info)

    if win_chip then
        AddProgress(session, fever_quest_info, FeverQuestMissionType.MissionTypeRapidHitClassicCount, 1, current_game_type)
    end
end

-- 中Mini Classic特性%d次
function OnRapidHitMiniClassSpinEnd(session, win_chip)
    local is_valid, fever_quest_info = IsQuestValid(session, GameType.AllTypes.RapidHit)

    if not is_valid then
        return
    end


    local current_game_type = GetCurrentGameType(fever_quest_info)

    if win_chip then
        AddProgress(session, fever_quest_info, FeverQuestMissionType.MissionTypeRapidHitMiniClassicCount, 1, current_game_type)
    end
end

function IsQuestValid(session, game_type)
    if not is_fever_quest_open then
        return false
    end

    if session.player.is_fever_quest ~= 1 then
        LOG(RUN, INFO).Format("[FeverQuestCal][OnGameSpin] spin is not from fever quest")
        return false
    end

    local fever_quest_info = GetFeverQuestInfo(session)

    if not fever_quest_info then
        LOG(RUN, INFO).Format("[FeverQuestCal][OnGameSpin] fever quest is not open")
        return false
    end

    local current_game_type = GetCurrentGameType(fever_quest_info)

    if current_game_type ~= game_type then
        return
    end

    return true, fever_quest_info
end

function OnFreeGameEnd(session, game_type, bet_amount, win_chip, total_spin_bouts)
    local is_valid, fever_quest_info = IsQuestValid(session, game_type)
    if not is_valid then
        return
    end

    OnFreeSpin(session, fever_quest_info, game_type, win_chip, total_spin_bouts)
end

function OnBaseGameEnd(session, game_type, bet_amount, win_chip)
    local is_valid, fever_quest_info = IsQuestValid(session, game_type)
    if not is_valid then
        return
    end

    OnBaseGameSpin(session, fever_quest_info, game_type, bet_amount, win_chip)
end

function OnBaseGameSpinCount(session, fever_quest_info, game_type, bet_amount, win_chip)
    local current_game_type = GetCurrentGameType(fever_quest_info)
    -- 增加base game spin次数
    AddProgress(session, fever_quest_info, FeverQuestMissionType.MissionTypeBaseGameBetCount, 1, current_game_type)
end

function OnBaseGameSpin(session, fever_quest_info, game_type, bet_amount, win_chip)
    local current_game_type = GetCurrentGameType(fever_quest_info)

    -- 增加base game spin次数
    -- AddProgress(session, fever_quest_info, FeverQuestMissionType.MissionTypeBaseGameBetCount, 1, current_game_type)

    -- 增加赢得次数
    if win_chip and win_chip > 0 then
        AddProgress(session, fever_quest_info, FeverQuestMissionType.MissionTypeBaseGameWinCount, 1, current_game_type)
        AddProgress(session, fever_quest_info, FeverQuestMissionType.MissionTypeBaseGameWinChip, win_chip, current_game_type)
    end
end

--------------------------------------------
function GetBoostValue(fever_quest_info)
    if fever_quest_info.boost_end_time > os.time() then
        return fever_quest_info.boost_multier
    end

    fever_quest_info.boost_multier = 1
    return fever_quest_info.boost_multier
end

-- 购买加速
function OnPurchase(session, player, shop_id, price)
    if not is_fever_quest_open then
        return
    end

    local config
    for i=1, #BoosterSaleQuestFever do
        local v = BoosterSaleQuestFever[i]
        if v.shop_id == shop_id then
            config = v
            break
        end
    end

    if not config then
        return
    end

    local fever_quest_info = GetFeverQuestInfo(session)
    -- 取较大值
    if config.buff_multiplier[1] > fever_quest_info.boost_multier then
        fever_quest_info.boost_multier = config.buff_multiplier[1]
    end

    if fever_quest_info.boost_end_time then
        local left_time = fever_quest_info.boost_end_time - os.time()
        if left_time < 0 then left_time = 0 end
        fever_quest_info.boost_end_time = os.time() + config.buff_time + left_time
    else
        fever_quest_info.boost_end_time = os.time() + config.buff_time
    end

    SaveFeverQuestInfo(session)
end

function GetBoostLeftTime(fever_quest_info)
    if fever_quest_info.boost_end_time then
        local left_time = fever_quest_info.boost_end_time - os.time()
        if left_time < 0 then left_time = 0 end
        return left_time
    end

    return 0
end

function GetLeftTime()
    local season_id = GetCurrentSeasonId()
    local config = QuestFeverSeasonConfig[season_id]

    if not config then
        return 0
    end

    local start = os.string2time(config.season_start_time)
    local end_time = os.string2time(config.season_end_time)

    local left_time = end_time - os.time()

    if left_time < 0 then
        left_time = 0
    end

    LOG(RUN, INFO).Format("[FeverQuestCal] GetLeftTime %s %s %s", config.season_start_time, config.season_end_time, left_time)

    return left_time
end

function IsSeasonTimeUp(season_id)
    local config = QuestFeverSeasonConfig[season_id]

    if not config then
        return false
    end

    local start = os.string2time(config.season_start_time)
    local end_time = os.string2time(config.season_end_time)
    return os.time() >= end_time
end

-- 检查是否结束season
function OnFeverQuestSeasonTimeUpdate(session)
    if not is_fever_quest_open then
        return
    end

    if finished_season_id == nil then
        InitFinishedSeasonId(session)
    end

    if os.time() == fever_quest_update_time then
        return
    end

    fever_quest_update_time = os.time()

    if finished_season_id < 0 then
        return
    end

    -- 查看新的季度是否到时间
    if IsSeasonTimeUp(finished_season_id + 1) then
        finished_season_id = finished_season_id + 1
        OnSeasonFinished(session, finished_season_id)
        UpdateFinishedSeasonId(finished_season_id)
    end
end

function GetFeverQuestRankConfig(tier_type, rank_index)
    for i=1, #QuestFeverRankConfig do
        local v = QuestFeverRankConfig[i]
        if v.rank_id == tier_type and rank_index >= v.rank[1] and rank_index <= v.rank[2] then
            return v
        end
    end
end

function GetRankWinChip(pool_value, tier_type, rank_index)
    local config = GetFeverQuestRankConfig(tier_type, rank_index)
    if not config then
        return 0
    end

    if config.prize_coins > 0 then
        return math.floor(pool_value * config.prize_coins)
    end

    return 0
end

-- 排名奖励
function OnFeverQuestFinishReward(session, season_id, tier_type, player_id, star, rank_index, pool_value)
    local config = GetFeverQuestRankConfig(tier_type, rank_index)
    if not config then
        LOG(RUN, INFO).Format("[FeverQuestCal][OnFeverQuestFinishReward] reward config is null %s %s",
            tier_type, rank_index)
        return
    end

    if config.prize_coins > 0 then
        local win_chip = math.floor(pool_value * config.prize_coins)
        local props = json.encode({[1] = {1000, win_chip}})

        local packet = {
            header = {
                router = "LocalRequest",
                service_name = "ManagerClientService",
                module_id = "Mail",
                message_id = "Mail_FeverQuestPrizeCoin_Request"
            },
            player_id = player_id,
            props = props,
            rank = rank_index,
            tier_type = tier_type,
            win_chip = win_chip
        }

        session:WriteRouterPacket(packet)

        LOG(RUN, INFO).Format("[FeverQuestCal][OnFeverQuestFinishReward] player_id %s season id %s win chip %s tier %s star %s rank %s pool %s", 
            player_id, season_id, win_chip, tier_type, star, rank_index, pool_value)
    end

    if config.prize_package > 0 then
        local props = json.encode({[1] = {1003, config.prize_package}})

        local packet = {
            header = {
                router = "LocalRequest",
                service_name = "ManagerClientService",
                module_id = "Mail",
                message_id = "Mail_FeverQuestPrizeCardPackage_Request"
            },
            player_id = player_id,
            props = props,
            rank = rank_index,
            tier_type = tier_type,
            package_id = config.prize_package
        }

        session:WriteRouterPacket(packet)

        LOG(RUN, INFO).Format("[FeverQuestCal][OnFeverQuestFinishReward] player_id %s season id %s prize_package %s tier %s star %s rank %s pool %s", 
            player_id, season_id, config.prize_package, tier_type, star, rank_index, pool_value)
    end

    if config.prize_vip > 0 then
        local props = json.encode({[1] = {1002, config.prize_vip}})

        local packet = {
            header = {
                router = "LocalRequest",
                service_name = "ManagerClientService",
                module_id = "Mail",
                message_id = "Mail_FeverQuestPrizeVipPoint_Request"
            },
            player_id = player_id,
            props = props,
            rank = rank_index,
            tier_type = tier_type,
            vip_point = config.prize_vip
        }

        session:WriteRouterPacket(packet)

        LOG(RUN, INFO).Format("[FeverQuestCal][OnFeverQuestFinishReward] player_id %s season id %s vip_point %s tier %s star %s rank %s pool %s", 
            player_id, season_id, config.prize_vip, tier_type, star, rank_index, pool_value)
    end

end

-- 每个阶段的排行处理
function OnTierFinished(session, season_id, tier_type)
    if season_id == 0 or tier_type <= 0 then
        return
    end

    -- 进阶
    local config = QuestFeverRankTierConfig[tier_type]
    if not config then
        return
    end

    local task = Task:Current()
    task.create_time = os.time()

    -- 读取本阶段的前50名（取1000个数据查50名，防止并列排名）
    local key = string.format("fever_quest_season%s_tier%s", season_id, tier_type)
    local async_request = {[1] = string.format("zrevrange %s 0 999 withscores", key)}
    local player_ids = LuaSession:ContactJson("CacheClientService", task, async_request, 0)

    LOG(RUN, INFO).Format("[FeverQuestCal][OnTierFinished] 玩家数量 %s season_id %s tier_type %s",
        math.floor(#player_ids/2), season_id, tier_type)

    if #player_ids <= 1 then
        return
    end

    local key = string.format("fever_quest_pool_season%s_tier%s", season_id, tier_type)
    local async_request = {[1] = string.format("hget %s pool_value", key)}
    local pool_value = LuaSession:ContactJson("CacheClientService", task, async_request, 0)[1]

    pool_value = tonumber(pool_value) or 0

    LOG(RUN, INFO).Format("[FeverQuestCal][OnTierFinished] pool value: key %s pool_value %s", key, pool_value)

    local rank_index = 0
    local rank_count = 0
    local prev_star = 0
    
    for i=1, #player_ids, 2 do
        local id = tonumber(player_ids[i])
        local star = tonumber(player_ids[i+1])

        if prev_star == 0 then
            rank_index = 1
        elseif prev_star == star then
            -- 并列排名
        else
            rank_index = rank_index + 1

            -- 只有在rank增加的时候才触发这个限制
            if rank_count > 50 then
                break
            end
        end

        if rank_index > 50 then
            break
        end

        rank_count = rank_count + 1

        OnFeverQuestFinishReward(session, session_id, tier_type, id, star, rank_index, pool_value)
        prev_star = star
    end

end

function BroadCastSeasonEnd(session, season_id)
    local channel = Channel:Get(2)
    local channel_id = channel:Id()
    local notice = {
        header = {
            router = "Broadcast",
            channel_id = channel_id,
            module_id = "FeverQuest",
            message_id = "FeverQuest_SeasonEnd_Notice",
            time = os.time()
        },
        type = channel.type,
        season_id = season_id
    }

    local data_str = json.encode(notice)
    session:BroadcastWriteQueue("broadcast", data_str)
    LOG(RUN, INFO).Format("[FeverQuestCal][BroadCastSeasonEnd] Broadcast data: %s", data_str)
end

function OnSeasonFinished(session, season_id)
    if not is_fever_quest_open then
        return
    end
    
    LOG(RUN, INFO).Format("[FeverQuestCal][OnSeasonFinished]季度结束，开始结算FeverQuest排行榜数据")
    -- 每个阶段的排行榜
    for i = FeverQuestTierType.TierTypeNovice, FeverQuestTierType.TierTypeDivine do
        -- OnTierFinished(session, season_id, i)
    end
    
    -- 对所有玩家发送通知
    BroadCastSeasonEnd(session, season_id)
end

-- 更新当前的season_id
function UpdateFinishedSeasonId(season_id)
    local task = Task:New()
    task:Init(function()
        -- 服务器季度结束时记录一下finished_season_id，便于下次启动时查看season_id是否变化
        local async_request = {[1] = string.format("hset fever_quest_info finished_season_id %s", season_id)}
        LuaSession:ContactJson("CacheClientService", task, async_request, 0)
    end)
    task:Start()
end

-- 更新当前的season_id
function InitFinishedSeasonId(session)
    if not is_fever_quest_open then
        return
    end

    finished_season_id = 0
    local task = Task:Current()
    task.create_time = os.time()

    local async_request = {[1] = string.format("hget fever_quest_info finished_season_id")}
    local season_id = LuaSession:ContactJson("CacheClientService", task, async_request, 0)

    if season_id and tonumber(season_id[1]) then
        finished_season_id = tonumber(season_id[1])
    else
        -- 季度没有完成过
        finished_season_id = 0
    end

    LOG(RUN, INFO).Format("[FeverQuestCal] 服务器 finished_season_id: %s", finished_season_id)
end

local function GetPlayerRankInfo(player_id)
    local task = Task:Current()
    task.create_time = os.time()
    
    local key = string.format("player[%s]", player_id)
    local key_nickname = string.format("%s.user.nickname", key)
    local key_avatar = string.format("%s.user.avatar", key)
    local key_facebook_id = string.format("%s.account.facebook_id", key)
    local async_request = {[1] = string.format("hmget %s %s %s %s", key, key_nickname, key_avatar, key_facebook_id)}
    local player_ids = LuaSession:ContactJson("CacheClientService", task, async_request, 0)

    local info = {}
    info.nickname = player_ids[1]:split("|")[2] or ""
    info.avatar = tonumber(player_ids[2]:split("|")[2]) or 0
    info.facebook_id = tonumber(player_ids[3]:split("|")[2]) or 0

    return info
end

function GetPoolValue(season_id, tier_type)
    local task = Task:Current()
    task.create_time = os.time()

    local key = string.format("fever_quest_pool_season%s_tier%s", season_id, tier_type)
    local async_request = {[1] = string.format("hget %s pool_value", key)}
    local pool_value = LuaSession:ContactJson("CacheClientService", task, async_request, 0)[1]

    return tonumber(pool_value)
end

function GetRanks(session, fever_quest_info, start_index, end_index)
    local task = Task:Current()
    task.create_time = os.time()

    local tier_type = fever_quest_info.last_tier
    local season_id = GetCurrentSeasonId()

    local pool_value = GetPoolValue(season_id, tier_type)

    local key = string.format("fever_quest_season%s_tier%s", season_id, tier_type)
    local async_request = {[1] = string.format("zrevrange %s %s %s withscores", key, start_index, end_index)}
    local player_ids = LuaSession:ContactJson("CacheClientService", task, async_request, 0)

    if #player_ids <= 1 then
        return {}, pool_value, 0, 0
    end

    local ranks = {}

    local current_rank = 1
    local current_star = -1

    for i=1, #player_ids, 2 do
        local player_id = tonumber(player_ids[i])
        local star = tonumber(player_ids[i+1])

        if current_star == -1 then
            current_star = star
        end

        if current_star ~= star then
            current_rank = current_rank + 1
            current_star = star
        end

        local rank = GetPlayerRankInfo(player_id)
        rank.star = star
        rank.rank = current_rank
        rank.prize_chip = GetRankWinChip(pool_value, tier_type, rank.rank)
        table.insert(ranks, rank)
    end

    return ranks, pool_value, start_index, math.floor(start_index + (#player_ids/2) - 1)
end