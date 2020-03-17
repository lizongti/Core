module("FeverCard", package.seeall)

local EpicMachinePrizeType = {
    Chip = 1,
    ChipRespin = 2,
    CardPackage = 3,
    VipPoint = 4,
}

local StarWheelPrizeType = {
    Chip = 1,
    Package = 2,
    ChipPackage = 3,
    ChipWildCard = 4,
}

local function InitCards(set_id)
    local cards = {}
    for i=1, #FeverCardsCardsConfig do
        local c = FeverCardsCardsConfig[i]
        if c.id == set_id then
            cards[i] = {
                
            }
        end
    end
end

local function InitCardSetInfo(player, album_id)
    local sets = {}
    for i=1, #FeverCardsSetConfig do
        local s = FeverCardsSetConfig[i]
        if FeverCardsSetConfig[i].album_id == album_id then
            sets[i] = {
                cards = InitCards(s.id)
            }
        end
    end
end

local function InitAlbumInfo(player, fever_card_info)
    for i=1, #FeverCardsAlbumConfig do
        local album = FeverCardsAlbumConfig[i]
        if fever_card_info[album.album_id] == nil then
            fever_card_info[album.album_id] = {
                sets = InitCardSetInfo(album.album_id)
            }
        end
    end
end

local function GetCardSetId(card_id)
    local c = FeverCardsCardsConfig[card_id]
    return c.set_id
end

local function GetSetAlbumId(set_id)
    local c = FeverCardsSetConfig[set_id]
    return c.album_id
end

local function InitCardsInfo(player, fever_card_info)
    fever_card_info.cards = {}
    fever_card_info.album_infos = {}
end

local function IsAlbumRewarded(fever_card_info)
    return false
end

local function GetAlbumSetConfig(album_id)
    local s = {}
    for i=1, #FeverCardsSetConfig do
        if FeverCardsSetConfig[i].album_id == album_id then
            table.insert(s, FeverCardsSetConfig[i])
        end
    end
    return s
end

local function IsSetRewarded(set_id)
    return false
end

local function GetSetCards(fever_card_info, set_id)
    local s = {}
    local set = FeverCardsSetConfig[set_id]
    local album_id = set.album_id
    local cards = fever_card_info.cards[album_id]

    for i=1, #cards do
        local id = cards[i].id
        if set_id == GetCardSetId(id) then
            table.insert(s, cards[i])
        end
    end
    return s
end

local function GetEpicMachineConfigs(level)
    local configs = {}
    local max_level = 0
    for i=1, #FeverCardsEpicMachineConfig do
        local c = FeverCardsEpicMachineConfig[i]
        if level < c.max_level then
            max_level = c.max_level
            break
        end
    end
    for i=1, #FeverCardsEpicMachineConfig do
        local c = FeverCardsEpicMachineConfig[i]
        if max_level == c.max_level then
            table.insert(configs, c)
        end
    end
    return configs
end

GetAlbumCompleteReward = function(_M, session, request, fever_card_info)
    local response = {header = {router = "Response"}}
    response.ret = Return.OK()
    local player = session.player
    local fever_card_info = fever_card_info or FeverCardCal.GetFeverCardInfo(session)
    fever_card_info.fever_info.album_rewards = fever_card_info.fever_info.album_rewards or {}

    local fever_info = fever_card_info.fever_info
    local album_id = request.album_id
    -- 计算卡牌是否全部完成
    local configs = FeverCardCal.GetAlbumCardConfig(request.album_id)
    local current_count = FeverCardCal.GetAlbumCardCount(fever_card_info, request.album_id)
    local config = FeverCardsAlbumConfig[album_id]

    if not config then
        return response
    end

    if current_count < #configs then
        return response
    end

    if fever_card_info.fever_info.album_rewards[tostring(album_id)] == 1 then
        return response
    end

    local chip = 0
    
    if not fever_card_info.fever_info.album_reward_chips then
        fever_card_info.fever_info.album_reward_chips = {}
        fever_card_info.fever_info.album_reward_chips[tostring(album_id)] = 
            FeverCardCal.CalcAlbumCompleteReward(album_id, player.character.level)
    end
    
    chip = fever_card_info.fever_info.album_reward_chips[tostring(album_id)] or 0
    
    Player:Obtain(player, {"Chip", chip}, Reason.FEVERCARD_ALBUM_REWARD_OBTAIN())
    fever_card_info.fever_info.album_rewards[tostring(album_id)] = 1

    response.chip = chip
    response.player = {
        character = {
            chip = player.character.chip
        }
    }

    response.album_id = album_id

    FeverCardCal.SaveFeverInfo(session)

    -- 卡簿集齐日志


    Spark:CompleteAlbum(session.player, {
        [1] = album_id,
        [2] = chip
    })

    return response
end

local function CalcSetReward(config, level)
    local ratio = 1
    local config = nil
    for k, v in pairs(config.level_extra_bonus) do

    end
end

-- 获取卡册完成奖励
GetSetCompleteReward = function(_M, session, request, fever_card_info)
    local response = {header = {router = "Response"}}
    response.ret = Return.OK()
    local player = session.player
    local fever_card_info = fever_card_info or FeverCardCal.GetFeverCardInfo(session)
    fever_card_info.fever_info.set_rewards = fever_card_info.fever_info.set_rewards or {}

    local set_id = request.set_id

    local configs = FeverCardCal.GetSetCardConfig(request.set_id)
    local current_count = FeverCardCal.GetSetCardCount(fever_card_info, request.set_id)

    if current_count < #configs then
        LOG(RUN, INFO).Format("[FeverCard][GetSetCompleteReward] count limit. player_id %s", player.id)
        return response
    end

    if fever_card_info.fever_info.set_rewards[tostring(set_id)] == 1 then
        LOG(RUN, INFO).Format("[FeverCard][GetSetCompleteReward] reward fetched. player_id %s", player.id)
        return response
    end

    local set_id = request.set_id
    local config = FeverCardsSetConfig[set_id]
    
    local chip = 0 
    
    if not fever_card_info.fever_info.set_reward_chips then
        fever_card_info.fever_info.set_reward_chips = {}
        fever_card_info.fever_info.set_reward_chips[tostring(set_id)] = FeverCardCal.CalcSetCompleteReward(set_id, player.character.level)
    end

    chip = fever_card_info.fever_info.set_reward_chips[tostring(set_id)] or 0

    Player:Obtain(player, {"Chip", chip}, Reason.FEVERCARD_SET_REWARD_OBTAIN())
    fever_card_info.fever_info.set_rewards[tostring(set_id)] = 1

    LOG(RUN, INFO).Format("[FeverCard][GetSetCompleteReward] reward chip %s. player_id %s", chip, player.id)

    response.chip = chip
    response.player = {
        character = {
            chip = player.character.chip
        }
    }
    response.set_id = set_id

    FeverCardCal.SaveFeverInfo(session)

    -- 卡册集齐日志

    
    Spark:CompleteSets(session.player, {
        [1] = set_id,
        [2] = chip
    })

    return response
end

-- Epic机器抽奖
EpicMachine = function(_M, session, request)
    local response = {header = {router = "Response"}}
    response.ret = Return.OK()
    local player = session.player
    local fever_card_info = FeverCardCal.GetFeverCardInfo(session)

    local card_id = request.card_id

    local card_config = FeverCardsCardsConfig[card_id]
    if card_config.rare_level ~= FeverCardRare.Epic then
        LOG(RUN, INFO).Format("[FeverCard] run epic machine error card card_id %s", card_id)
        return
    end

    local card = FeverCardCal.GetCard(fever_card_info, card_id)
    if card.epic_count <= 0 then
        LOG(RUN, INFO).Format("[FeverCard] run epic machine error count card_id %s count %s", card_id, card.epic_count)
        return response
    end
    
    card.epic_count = card.epic_count - 1

    local configs = GetEpicMachineConfigs(player.character.level)
    local weights = {}
    for i=1, #configs do
        table.insert(weights, configs[i].weight)
    end
    local config = configs[math.rand_weight(player, weights)]

    local ratio = 1 + config.star_epic_card_bonus[card_config.star_number]

    local win_chip = 0
    local win_vip_points = 0
    local is_respin = 0

    if config.prize_type == EpicMachinePrizeType.Chip then
        win_chip = config.coin_prize * ratio
        response.chip = win_chip
        Player:Obtain(player, {"Chip", win_chip}, Reason.FEVERCARD_EPIC_MACHINE_OBTAIN())
        LOG(RUN, INFO).Format("[FeverCard][EpicMachine] win chip %s. card_id %s epic_count %s", win_chip, card_id, card.epic_count)
    elseif config.prize_type == EpicMachinePrizeType.ChipRespin then
        win_chip = config.coin_prize * ratio
        response.chip = win_chip
        response.respin_count = 1
        card.epic_count = card.epic_count + 1
        Player:Obtain(player, {"Chip", win_chip}, Reason.FEVERCARD_EPIC_MACHINE_OBTAIN())
        LOG(RUN, INFO).Format("[FeverCard][EpicMachine] win chip %s. card_id %s epic_count %s", win_chip, card_id, card.epic_count)
    elseif config.prize_type == EpicMachinePrizeType.CardPackage then
        response.cards = FeverCardCal.OpenSourcePackage(session, fever_card_info, config.package_type, FeverCardSource.EpicMachine)
        LOG(RUN, INFO).Format("[FeverCard][EpicMachine] reward card package %s. player_id %s", config.package_type, player.id)
    elseif config.prize_type == EpicMachinePrizeType.VipPoint then
        win_vip_points = config.vip_points * ratio
        player.character.vip_points = player.character.vip_points + win_vip_points
        response.vip_point = win_vip_points
        Player:UpdateVIP(session)
        LOG(RUN, INFO).Format("[FeverCard][EpicMachine] reward vip point %s. player_id %s", config.vip_points, player.id)

        session:WriteRouterPacket({
            header = {
                router = "SpecificNotice",
                session_id = session.id,
                player_id = player.id,
                module_id = "Command",
                message_id = "Command_Player_Notice",
            },
            player = {
                character = {
                    vip = player.character.vip
                },
            }
        })
    end

    -- 更新卡牌
    FeverCardCal.SaveCurrentCardInfo(session)

    response.card_id = request.card_id
    response.reward_id = config.id
    response.player = {
        character = {
            chip = player.character.chip,
            vip_points = player.character.vip_points,
            vip = player.character.vip
		}
    }

    local win_cards = {}
    if response.cards then
        for i=1, #response.cards do
            table.insert(win_cards, response.cards[i].id)
        end
    end
    -- EpicMachine日志

    Spark:EpicMachineSpin(session.player, {
        [1] = request.card_id,
        [2] = win_chip,
        [3] = json.encode(win_cards),
        [4] = win_vip_points,
        [5] = response.respin_count or 0,
        [6] = card.epic_count
    })
    
    return response
end

local function GetStar(level, type)
    for i=1, #FeverCardsStarWheelConsumptionConfig do
        local f = FeverCardsStarWheelConsumptionConfig[i]
        if level <= f.max_level then
            return f.star_consumption[type]
        end
    end
end

local function GetStarWheelRatio(wheel_config, level)
    local level_bonus = wheel_config.level_bonus
    local lbs = {}
    for k, v in pairs(level_bonus) do
        table.insert(lbs, {level=k, ratio=v})
    end
    table.sort(lbs, function(a, b)
        return a.level < b.level
    end)
    local r = 0
    for i=1, #lbs do
        if level < lbs[i].level then
            break
        end
        r = lbs[i].ratio
    end
    return r
end

-- StarWheel机器
StarWheel = function(_M, session, request)
    local response = {header = {router = "Response"}}
    response.ret = Return.OK()
    local player = session.player
    local fever_card_info = FeverCardCal.GetFeverCardInfo(session)

    local type = request.type
    local cards = request.cards

    local star = 0
    local has_rare = false
    for i=1, #cards do
        local card_config = FeverCardsCardsConfig[cards[i].id]
        local card = FeverCardCal.GetCard(fever_card_info, cards[i].id)
        if not card then
            return
        end
        if cards[i].count > card.count-1 then
            response.ret = Return.CARD_NOT_ENOUGH()
            return response 
        end

        if card_config.rare_level == FeverCardRare.Rare then
            has_rare = true
        end

        if card_config.rare_level == FeverCardRare.Epic then
            star = star + card_config.star_number * 2 * cards[i].count
        else
            star = star + card_config.star_number * cards[i].count
        end
    end

    -- 是否足够
    local need_star = GetStar(player.character.level, type)

    if star < need_star then
        LOG(RUN, INFO).Format("[FeverCard][StarWheel] star limit %s. player_id %s", star, player.id)
        response.ret = Return.STAR_NOT_ENOUGH()
        return response
    end

    local left_time = FeverCardCal.GetStarWheelLeftTime(fever_card_info)
    
    if left_time > 0 then
        LOG(RUN, INFO).Format("[FeverCard][StarWheel] time limit %s. player_id %s", left_time, player.id)
        response.ret = Return.STAR_COOL_TIME()
        return response
    end

    -- 消耗卡牌
    for i=1, #cards do
        local card = FeverCardCal.GetCard(fever_card_info, cards[i].id)
        card.count = card.count - cards[i].count
    end

    local wheel_configs = {}
    for i=1, #FeverCardsStarWheelConfig do
        if FeverCardsStarWheelConfig[i].wheel_level == type then
            table.insert(wheel_configs, FeverCardsStarWheelConfig[i])
        end
    end

    local weights = {}
    for i=1, #wheel_configs do
        table.insert(weights, wheel_configs[i].weight)
    end

    local wheel_config = wheel_configs[math.rand_weight(player, weights)]

    -- 奖励类型
    local win_chip = 0
    local ratio = GetStarWheelRatio(wheel_config, player.character.level)

    fever_card_info.fever_info.star_wheel_wild = nil

    if wheel_config.prize_type == StarWheelPrizeType.Chip then
        win_chip = wheel_config.coins_number * (1.0 + ratio)
        
        if has_rare then
            win_chip = win_chip * 1.15
        end

        win_chip = math.floor(win_chip)

        response.chip = win_chip
        Player:Obtain(player, {"Chip", win_chip}, Reason.FEVERCARD_STAR_WHEEL_OBTAIN())
        LOG(RUN, INFO).Format("[FeverCard][Star Wheel] win chip %s. player_id %s", win_chip, player.id)
    elseif wheel_config.prize_type == StarWheelPrizeType.Package then
        response.cards = FeverCardCal.OpenSourcePackage(session, fever_card_info, wheel_config.package_type, FeverCardSource.StarWheel)
        LOG(RUN, INFO).Format("[FeverCard][StarWheel] reward card package %s. player_id %s", wheel_config.package_type, player.id)
    elseif wheel_config.prize_type == StarWheelPrizeType.ChipPackage then
        win_chip = wheel_config.coins_number * (1.0 + ratio)
        
        if has_rare then
            win_chip = win_chip * 1.15
        end
        
        win_chip = math.floor(win_chip)
        
        response.chip = win_chip
        Player:Obtain(player, {"Chip", win_chip}, Reason.FEVERCARD_STAR_WHEEL_OBTAIN())
        response.cards = FeverCardCal.OpenSourcePackage(session, fever_card_info, wheel_config.package_type, FeverCardSource.StarWheel)
        LOG(RUN, INFO).Format("[FeverCard][StarWheel] reward chip and card package %s. player_id %s", wheel_config.package_type, player.id)
    elseif wheel_config.prize_type == StarWheelPrizeType.ChipWildCard then
        win_chip = wheel_config.coins_number * (1.0 + ratio)
        
        if has_rare then
            win_chip = win_chip * 1.15
        end
        
        win_chip = math.floor(win_chip)
        
        response.chip = win_chip
        Player:Obtain(player, {"Chip", win_chip}, Reason.FEVERCARD_STAR_WHEEL_OBTAIN())
        
        local album = FeverCardCal.GetCurrentAlbum()
        fever_card_info.fever_info.star_wheel_wild = album.id

        LOG(RUN, INFO).Format("[FeverCard][StarWheel] reward chip and wild %s. player_id %s", wheel_config.package_type, player.id)
    end
    
    response.consume_cards = request.cards
    response.reward_id = wheel_config.id
    response.wild_card_album_id = fever_card_info.fever_info.star_wheel_wild
    -- 更新时间
    fever_card_info.fever_info.star_wheel_time = os.time()
    FeverCardCal.SaveFeverInfo(session)
    response.star_wheel_left_time = FeverCardCal.GetStarWheelLeftTime(fever_card_info)

    -- 更新卡牌
    FeverCardCal.SaveCurrentCardInfo(session)

    response.player = {
        character = {
			chip = player.character.chip
		}
    }

    local win_cards = {}
    if response.cards then
        for i=1, #response.cards do
            table.insert(win_cards, response.cards[i].id)
        end
    end
    -- StarWheel日志
    Spark:StarWheelSpin(session.player, {
        [1] = request.type,
        [2] = json.encode(request.cards),
        [3] = win_chip,
        [4] = json.encode(win_cards),
    })
    
    return response
end

-- 获取玩家卡牌历史记录
History = function(_M, session, request)
    local response = {header = {router = "Response"}}
    response.ret = Return.OK()
    local player = session.player
    local card_history = ActivityCal.Calculate.GetActivityInfo(session, ActivityDefine.AllTypes.FeverCardHistory)

    local his = card_history

    local his_infos = {}
    for i=1, #his do
        local v = {
            id = his[i].id,
            time = his[i].time,
            source = his[i].source,
        }
        table.insert(his_infos, v)
    end

    response.historys = his_infos
    LOG(RUN, INFO).Format("[FeverCard][History] history size %s. player_id %s", #his_infos, player.id)

    return response
end

-- 获取卡簿里面的所有卡册和卡牌
AlbumCardsInfo = function(_M, session, request)
    local response = {header = {router = "Response"}}
    response.ret = Return.OK()
    local player = session.player
    local fever_card_info = FeverCardCal.GetFeverCardInfo(session)

    local album_id = request.album_id
    
    local album = {
        id = album_id,
        count = FeverCardCal.GetAlbumCardCount(fever_card_info, album_id),
        rewarded = FeverCardCal.GetAlbumIsRewarded(fever_card_info, album_id) and 1 or 0,
        rewardedChips = FeverCardCal.GetAlbumRewardChips(fever_card_info, album_id),
    }
    
    local sets = {}
    local configs = GetAlbumSetConfig(album_id)

    for i=1, #configs do
        local set_id = configs[i].id
        local v = {
            set_id = set_id,
            rewarded = FeverCardCal.GetSetIsRewarded(fever_card_info, set_id) and 1 or 0,
            rewardedChips = FeverCardCal.GetSetRewardChips(fever_card_info, set_id),
            cards = GetSetCards(fever_card_info, set_id)
        }
        table.insert(sets, v)
    end

    album.sets = sets

    response.album = album

    return response
end

-- 获取卡簿
AlbumInfo = function(_M, session, request)
    local response = {header = {router = "Response"}}
    local player = session.player
    local fever_card_info = FeverCardCal.GetFeverCardInfo(session)
    -- 初始化
    if fever_card_info.cards == nil then
        InitCardsInfo(player, fever_card_info)
    end

    local album_id_arr = {}
    for i=1, #FeverCardsAlbumConfig do
        local album = {
            id = FeverCardsAlbumConfig[i].id,
            count = FeverCardCal.GetAlbumCardCount(fever_card_info, FeverCardsAlbumConfig[i].id),
            rewarded = IsAlbumRewarded(fever_card_info) and 1 or 0,
            rewardedChips = FeverCardCal.GetAlbumRewardChips(fever_card_info, FeverCardsAlbumConfig[i].id),
        }
        table.insert(album_id_arr, FeverCardsAlbumConfig[i].id)
    end

    response.ret = Return.OK()
    response.album_id_arr = album_id_arr

    -- 记录上次获取时间
    response.star_wheel_left_time = FeverCardCal.GetStarWheelLeftTime(fever_card_info)

    if response.star_wheel_left_time <= 0 then
        response.wild_card_album_id = nil
    else
        response.wild_card_album_id = fever_card_info.fever_info.star_wheel_wild
    end

    return response
end

-- 兑换wild卡牌
ConfirmWildCard = function(_M, session, request)
    local response = {header = {router = "Response"}}
    response.ret = Return.OK()
    local player = session.player
    local fever_card_info = FeverCardCal.GetFeverCardInfo(session)

    if fever_card_info.fever_info.star_wheel_wild == nil then
        LOG(RUN, INFO).Format("[FeverCard][ConfirmWildCard] star_wheel_wild is nil. player_id %s", player.id)
        return
    end

    local star_wheel_left_time = FeverCardCal.GetStarWheelLeftTime(fever_card_info)

    if star_wheel_left_time <= 0 then
        LOG(RUN, INFO).Format("[FeverCard][ConfirmWildCard] time limit %s. player_id %s", star_wheel_left_time, player.id)
        response.ret = Return.STAR_COOL_TIME()
        return response
    end

    if not FeverCardCal.IsAlbumCard(fever_card_info, fever_card_info.fever_info.star_wheel_wild, request.card_id) then
        LOG(RUN, INFO).Format("[FeverCard][ConfirmWildCard] not album card %s %s. player_id %s", 
            fever_card_info.fever_info.star_wheel_wild, request.card_id, player.id)
        return
    end

    local card_id = request.card_id
    fever_card_info.fever_info.star_wheel_wild = nil
    
    -- 更新wild
    FeverCardCal.SaveFeverInfo(session)

    -- 兑换卡牌
    FeverCardCal.AddSourceCard(session, fever_card_info, card_id, FeverCardSource.WildCard)

    -- 更新卡牌
    FeverCardCal.SaveCurrentCardInfo(session)

    response.card_id = card_id
    return response
end


