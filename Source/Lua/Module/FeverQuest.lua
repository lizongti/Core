module("FeverQuest", package.seeall)

-- 获取fever quest信息
GetQuestInfo = function(_M, session, request)
    local player = session.player

    local fever_quest_info = FeverQuestCal.GetFeverQuestInfoAll(session)

    if not fever_quest_info then
        LOG(RUN, INFO).Format("[FeverQuest][GetQuestInfo]当前不存在FeverQuest活动，确认开关是否关闭或者配置过期")
        return
    else
        LOG(RUN, INFO).Format("[FeverQuest][GetQuestInfo] player id %s", player.id)
    end

    LOG(RUN, INFO).Format("[FeverQuest][GetQuestInfo] player id %s get rank info begin", player.id)

    local rank_info = FeverQuestCal.GetRankInfo(session, fever_quest_info)

    LOG(RUN, INFO).Format("[FeverQuest][GetQuestInfo] player id %s get rank info end", player.id)

    local boost_left_time = FeverQuestCal.GetBoostLeftTime(fever_quest_info)

    local response = {
        header = {router = "Response"},
        ret = Return.OK(),
        season = FeverQuestCal.GetCurrentSeasonId(),
        task_id = fever_quest_info.task_id,
        hard_level = fever_quest_info.hard_level,
        star = fever_quest_info.star,
        is_boost = (boost_left_time > 0) and 1 or 0,
        rank_info = rank_info,
        progresses = FeverQuestCal.GetFeverQuestProgresses(session, fever_quest_info),
        task_fetch_level = fever_quest_info.task_fetch_level,
        left_time = FeverQuestCal.GetLeftTime(),
        boost_left_time = boost_left_time,
    }

    return response
end

GetRankInfo = function(_M, session, request)
    local player = session.player

    local fever_quest_info = FeverQuestCal.GetFeverQuestInfoAll(session)

    if not fever_quest_info then
        LOG(RUN, INFO).Format("[FeverQuest][GetRankInfo]当前不存在FeverQuest活动，确认开关是否关闭或者配置过期")
        return
    else
        LOG(RUN, INFO).Format("[FeverQuest][GetRankInfo] player id %s", player.id)
    end

    local start_index = request.start_index
    local end_index = request.end_index

    local rank_info = FeverQuestCal.GetRankInfo(session, fever_quest_info)

    local ranks, pool_value, start_index, end_index = FeverQuestCal.GetRanks(session, fever_quest_info, start_index, end_index)

    local response = {
        header = {router = "Response"},
        ret = Return.OK(),
        ranks = ranks,
        start_index = start_index,
        end_index = end_index,
        pool_value = pool_value,
        rank_info = rank_info,
        left_time = 0,
        tier_type = rank_info.tier_type
    }

    return response
end

SetQuestHardLevel = function(_M, session, request)
    local player = session.player

    if request.hard_level <= 0 or request.hard_level > 3 then
        LOG(RUN, INFO).Format("[FeverQuest][SetQuestHardLevel]fever quest hard level error:", request.hard_level)
        return
    end

    local fever_quest_info = FeverQuestCal.GetFeverQuestInfoAll(session)

    if fever_quest_info.hard_level > 0 then
        LOG(RUN, INFO).Format("[FeverQuest][SetQuestHardLevel]fever quest hard level has been set")
        return
    end

    fever_quest_info.hard_level = request.hard_level
    fever_quest_info.task_fetch_level = player.character.level

    FeverQuestCal.SaveFeverQuestInfo(session)

    if not fever_quest_info then
        LOG(RUN, INFO).Format("[FeverQuest][GetQuestInfo]当前不存在FeverQuest活动")
        return
    end

    local response = {
        header = {router = "Response"},
        ret = Return.OK(),
        hard_level = fever_quest_info.hard_level,
    }

    return response
end