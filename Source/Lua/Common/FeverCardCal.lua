module("FeverCardCal", package.seeall)

_G.IsFeverCardOpen = true

_G.FeverCardSource = {
    GameSpin = 1,
    Purchase = 2,
    DailyMission = 3,
    LevelUp = 4,
    EpicMachine = 5,
    StarWheel = 6,
    LevelUpUnlock = 7,
    WildCard = 8,
    FeverQuestFinishTask = 9,
    FeverQuestRank = 10
}

_G.FeverCardRare = {
    Common = 1,
    Rare = 2,
    Epic = 3,
}

local function GetCardAlbum(id)
    local card = FeverCardsCardsConfig[id]
    local set = FeverCardsSetConfig[card.set_id]
    return set.album_id
end

local function GetOutputConfig(level, bet_amount)
    -- 产出
    local v = nil
    local s = {}
    for i=1, #FeverCardsSpinOutputConfig do
        if level <= FeverCardsSpinOutputConfig[i].max_level then
            for j=i, #FeverCardsSpinOutputConfig do
                if bet_amount <= FeverCardsSpinOutputConfig[j].max_bet then
                    return FeverCardsSpinOutputConfig[j]
                end
            end
        end
    end
end

function GetAlbumSetConfig(album_id)
    local s = {}
    for i=1, #FeverCardsSetConfig do
        if FeverCardsSetConfig[i].album_id == album_id then
            table.insert(s, FeverCardsSetConfig[i])
        end
    end
    return s
end

function IsFeverCardOpen(player)
    local config = nil

    for i=#FeverCardsLevelOutputConfig, 1, -1 do
        if FeverCardsLevelOutputConfig[i].is_unlock_level == 1 then
            config = FeverCardsLevelOutputConfig[i]
            break
        end
    end

    return player.character.level >= config.player_level
end

function CalcSetCompleteReward(set_id, level)
    local base = FeverCardsSetConfig[set_id].set_prize
    local level_extra_bonus = FeverCardsSetConfig[set_id].level_extra_bonus

    local value = 0
    local vs = {}
    for k, v in pairs(level_extra_bonus) do
        table.insert(vs, {k, v})
    end

    table.sort(vs, function(a, b)
        return a[1] < b[1]
    end)

    for i, v in ipairs(vs) do
        if level < v[1] then
            break
        end
        value = v[2]
    end

    return base * (1 + value)
end

function CalcAlbumCompleteReward(album_id, level)
    local base = FeverCardsAlbumConfig[album_id].album_prize
    local level_extra_bonus = FeverCardsAlbumConfig[album_id].level_extra_bonus

    local value = 0
    local vs = {}
    for k, v in pairs(level_extra_bonus) do
        table.insert(vs, {k, v})
    end

    table.sort(vs, function(a, b)
        return a[1] < b[1]
    end)

    for i, v in ipairs(vs) do
        if level < v[1] then
            break
        end
        value = v[2]
    end

    return base * (1 + value)
end

local function CompleteSet(session, fever_card_info, packet)
    local player = session.player
    local album_config = GetCurrentAlbum()
    local album_id = album_config.id
    -- 检查卡册集齐
    local set_configs = GetAlbumSetConfig(album_id)
    packet.set_complete_arr = {}

    for i=1, #set_configs do
        local set_id = set_configs[i].id

        local configs = FeverCardCal.GetSetCardConfig(set_id)
        local current_count = FeverCardCal.GetSetCardCount(fever_card_info, set_id)

        if current_count >= #configs then
            fever_card_info.fever_info.set_rewards = fever_card_info.fever_info.set_rewards or {}
            fever_card_info.fever_info.set_reward_chips = fever_card_info.fever_info.set_reward_chips or {}

            if fever_card_info.fever_info.set_rewards[tostring(set_id)] ~= 1 then
                fever_card_info.fever_info.set_rewards[tostring(set_id)] = 0
            end

            if not fever_card_info.fever_info.set_reward_chips[tostring(set_id)] then
                fever_card_info.fever_info.set_reward_chips[tostring(set_id)] = CalcSetCompleteReward(set_id, player.character.level)
            end
            
            if fever_card_info.fever_info.set_rewards[tostring(set_id)] ~= 1 then
                -- 收集奖励
                local request = {set_id = set_id}
                FeverCard:GetSetCompleteReward(session, request, fever_card_info)
                -- 设置包内容
                table.insert(packet.set_complete_arr, {
                    set_id = set_id,
                    chip = fever_card_info.fever_info.set_reward_chips[tostring(set_id)],
                    player = {
                        character = {
                            chip = player.character.chip
                        }
                    }
                })
            end
        end
    end
end

local function CompleteAlbum(session, fever_card_info, packet)
    local player = session.player
    local album_config = GetCurrentAlbum()
    local album_id = album_config.id
    local configs = FeverCardCal.GetAlbumCardConfig(album_config.id)
    local current_count = FeverCardCal.GetAlbumCardCount(fever_card_info, album_config.id)
    local config = FeverCardsAlbumConfig[album_config.id]

    packet.album_complete_arr = {}

    -- 检查卡簿集齐
    if config and current_count >= #configs then
        -- 集齐卡牌
        fever_card_info.fever_info.album_rewards = fever_card_info.fever_info.album_rewards or {}
        fever_card_info.fever_info.album_reward_chips = fever_card_info.fever_info.album_reward_chips or {}

        if fever_card_info.fever_info.album_rewards[tostring(album_id)] ~= 1 then
            fever_card_info.fever_info.album_rewards[tostring(album_id)] = 0
        end

        if not fever_card_info.fever_info.album_reward_chips[tostring(album_id)] then
            fever_card_info.fever_info.album_reward_chips[tostring(album_id)] = CalcAlbumCompleteReward(album_id, player.character.level)
        end

        if fever_card_info.fever_info.album_rewards[tostring(album_id)] ~= 1 then
            -- 收集奖励
            local request = {album_id = album_id}
            FeverCard:GetAlbumCompleteReward(session, request, fever_card_info)
            -- 设置包内容
            table.insert(packet.album_complete_arr, {
                album_id = album_id,
                chip = fever_card_info.fever_info.album_reward_chips[tostring(album_id)],
                player = {
                    character = {
                        chip = player.character.chip
                    }
                }
            })
        end
    end
end

local function CheckCardCompleteReward(session, fever_card_info, packet)
    CompleteSet(session, fever_card_info, packet)
    CompleteAlbum(session, fever_card_info, packet)
end

function GetStarWheelLeftTime(fever_card_info)
    -- 记录上次获取时间
    local last_time = FeverCardCal.GetLastStarWheelTime(fever_card_info)
    local star_wheel_left_time = 0

    if last_time - os.time() < 24*3600 then
        local dt = last_time + 24*3600 - os.time()
        
        LOG(RUN, INFO).Format("[FeverCardCal][GetStarWheelLeftTime] last_time %s current %s delta %s", 
            last_time, os.time(), dt)

        star_wheel_left_time = dt
    end

    if star_wheel_left_time < 0 then
        star_wheel_left_time = 0
    end

    return star_wheel_left_time
end

function GetLastStarWheelTime(fever_card_info)
    local fever_info = fever_card_info.fever_info
    return fever_info.star_wheel_time or 0
end

function AddSourceCard(session, fever_card_info, card_id, source)
    local cards = {}
    table.insert(cards, {
        id = card_id,
        count = 1,
        epic_count = GetCardEpicCount(card_id)
    })

    local packet = {
        header = {
            router = "Notice",
            module_id = "FeverCard",
            message_id = "FeverCard_NewCard_Notice"
        },
        cards = cards,
        type = 1,
        time = os.time(),
        source = source
    }

    local card_config = FeverCardsCardsConfig[card_id]

    MergeCards(fever_card_info.cards, card_config)
    FeverCardCal.AddCardHistory(session, card_config.id, source)

    -- 开卡后检查是否集齐所有卡牌
    CheckCardCompleteReward(session, fever_card_info, packet)
    SaveCurrentCardInfo(session)
    session:WriteRouterPacket(packet)
end

function OpenSourcePackage(session, fever_card_info, package_type, source, is_level_open)
    if not is_level_open and not IsFeverCardOpen(session.player) then
        return
    end

    local card_configs = OpenPackage(session, fever_card_info, package_type, source)
    local cards = {}

    for i=1, #card_configs do
        table.insert(cards, {
            id = card_configs[i].id,
            count = 1,
            epic_count = GetCardEpicCount(card_configs[i].id)
        })
    end

    local pkg_config = FeverCardsPackageConfig[package_type]

    local packet = {
        header = {
            router = "Notice",
            module_id = "FeverCard",
            message_id = "FeverCard_NewCard_Notice"
        },
        cards = cards,
        type = pkg_config.package_appearance,
        time = os.time(),
        source = source
    }

    -- 开卡后检查是否集齐所有卡牌
    CheckCardCompleteReward(session, fever_card_info, packet)
    SaveCurrentCardInfo(session)
    
    session:WriteRouterPacket(packet)

    local cardids = {}
    for i=1, #card_configs do
        table.insert(cardids, card_configs[i].id)
    end
    -- 添加获取日志

    Spark:ReceiveCards(session.player, {
        [1] = package_type,
        [2] = json.encode(cardids),
        [3] = source,
    })

    return cards
end

local function RandCard(current_cards, player, fever_card_info, star, rare, config)
    local configs = {}
    local w = {}

    for i=1, #FeverCardsCardsConfig do
        local c = FeverCardsCardsConfig[i]
        local weight = 0

        if (c.star_number == star or star == 0) and  (c.rare_level == rare or rare == 0) then
            local filter_ok = true
            -- 金卡星级过滤
            if c.rare_level == FeverCardRare.Epic and (c.star_number < config.epic_min_star or c.star_number > config.epic_max_star) then
                -- 只有金卡star没有设置才启用这个过滤
                if star == 0 then
                    filter_ok = false
                end
            end
            
            if filter_ok then
                if FeverCardCal.IsCardExist(fever_card_info, c.id) then
                    weight = c.own_weight
                else
                    weight = c.weight
                end
            end
        end

        if current_cards[tostring(c.id)] == true then
            weight = 0
        end

        table.insert(w, weight)
    end

    local index = math.rand_weight(player, w)
    local c = FeverCardsCardsConfig[index]
    return c
end

-- 非必出卡
local function RandNormalCard(current_cards, player, fever_card_info, config)
    local w = {}
    for i=1, #FeverCardsCardsConfig do
        local c = FeverCardsCardsConfig[i]
        local weight = 0

        local filter_ok = true

        -- 金卡星级过滤
        if c.rare_level == FeverCardRare.Epic and c.star_number < config.epic_min_star and c.star_number > config.epic_max_star then
            filter_ok = false
        end
        
        -- 过滤卡牌星级和rare
        for i=1, #config.left_filter_star_type do
            if config.left_filter_star_type[i] == c.star_number then
                filter_ok = false
            end
        end

        for i=1, #config.left_filter_rarity_type do
            if config.left_filter_rarity_type[i] == c.rare_level then
                filter_ok = false
            end
        end

        if filter_ok then
            if FeverCardCal.IsCardExist(fever_card_info, c.id) then
                weight = c.own_weight
            else
                weight = c.weight
            end
        end

        if current_cards[tostring(c.id)] == true then
            weight = 0
        end

        table.insert(w, weight)
    end

    local index = math.rand_weight(player, w)
    local c = FeverCardsCardsConfig[index]
    return c
end

function IsEpicCard(card_id)
    return FeverCardCal.GetCardEpicCount(card_id) == 1
end

function MergeCards(_cards, card_config)
    if not card_config then
        return
    end
    local cards = _cards[GetCardAlbum(card_config.id)]
    local id = card_config.id
    local f = false
    for i=1, #cards do
        if cards[i].id == id then
            cards[i].count = cards[i].count + 1
            cards[i].epic_count = cards[i].epic_count + FeverCardCal.GetCardEpicCount(id)
            f = true
            break
        end
    end
    if not f then
        table.insert(cards, {id=id, count=1, epic_count=FeverCardCal.GetCardEpicCount(id)})
    end
end

function SaveAlbumCards(session, album_id)
    local type = ActivityDefine.AllTypes.FeverCard + FeverCardsAlbumConfig[album_id].id
    ActivityCal.Calculate.UpdateActivityInfo(session, type)
end

function IsCardExist(fever_card_info, card_id)
    local c = FeverCardCal.GetCard(fever_card_info, card_id)
    return c ~= nil
end

function GetCard(fever_card_info, card_id)
    local album_id = GetCardAlbumId(card_id)
    local cards = fever_card_info.cards[album_id]
    for i=1, #cards do
        if cards[i].id == card_id then
            return cards[i]
        end
    end
end

-- 获取卡牌信息的接口
-- 卡牌信息
-- fever_info是通用存储信息，不包括卡牌信息
-- cards是所有卡簿的卡牌信息
function GetFeverCardInfo(session)
    local fever_card_info = {}
    fever_card_info.fever_info = ActivityCal.Calculate.GetActivityInfo(session, ActivityDefine.AllTypes.FeverCard)

    local cards_all = {}
    for i=1, #FeverCardsAlbumConfig do
        local album_id = FeverCardsAlbumConfig[i].id
        local type = ActivityDefine.AllTypes.FeverCard + FeverCardsAlbumConfig[i].id
        local cards = ActivityCal.Calculate.GetActivityInfo(session, type)
        cards_all[album_id] = cards
    end

    fever_card_info.cards = cards_all
    return fever_card_info
end

function IsAlbumCard(fever_card_info, album_id, card_id)
    local card = FeverCardsCardsConfig[card_id]
    if not card then return false end
    local set = FeverCardsSetConfig[card.set_id]
    if not set then return false end
    return set.album_id == album_id
end

function GetCurrentAlbum()
    local album = nil
    local t = os.time()
    for i=1, #FeverCardsAlbumConfig do
        local start_time = os.string2date(FeverCardsAlbumConfig[i].start_time)
        local end_time = os.string2date(FeverCardsAlbumConfig[i].end_time)
        if t >= start_time and t <= end_time then
            return FeverCardsAlbumConfig[i]
        end
    end
end

function AddCardHistory(session, card_id, source)
    local card_history = ActivityCal.Calculate.GetActivityInfo(session, ActivityDefine.AllTypes.FeverCardHistory)
    table.insert(card_history, {
        id = card_id,
        time = os.time(),
        source = source,
    })
    while #card_history > 50 do
        table.remove(card_history, 1)
    end
    LOG(RUN, INFO).Format("[FeverCardCal] add card history:card_id %s count %s", card_id, #card_history)
    ActivityCal.Calculate.UpdateActivityInfo(session, ActivityDefine.AllTypes.FeverCardHistory)
end

function GetCardSetId(card_id)
    local c = FeverCardsCardsConfig[card_id]
    return c.set_id
end

function GetSetAlbumId(set_id)
    local s = FeverCardsSetConfig[set_id]
    return s.album_id
end

function GetCardAlbumId(card_id)
    local c = FeverCardsCardsConfig[card_id]
    local s = FeverCardsSetConfig[c.set_id]
    return s.album_id
end

-- 获取用户的卡牌数量
function GetAlbumCardConfig(album_id)
    local cards = {}
    -- 获取所有的卡册
    for i=1, #FeverCardsCardsConfig do
        local c = FeverCardsCardsConfig[i]
        if GetCardAlbumId(c.id) == album_id then
            table.insert(cards, c)
        end
    end
    return cards
end

-- 获取用户的卡册数量
function GetSetCardConfig(set_id)
    local cards = {}
    -- 获取所有的卡册
    for i=1, #FeverCardsCardsConfig do
        local c = FeverCardsCardsConfig[i]
        if c.set_id == set_id then
            table.insert(cards, c)
        end
    end
    return cards
end

-- 获取用户的卡牌数量
function GetAlbumCardCount(fever_card_info, album_id)
    local c = fever_card_info.cards[album_id]
    if not c then
        fever_card_info.cards[album_id] = {}
        return 0
    end
    return #c
end

-- 获取
function GetSetCardCount(fever_card_info, set_id)
    local album_id = GetSetAlbumId(set_id)
    local c = fever_card_info.cards[album_id]
    if not c then
        fever_card_info.cards[album_id] = {}
        return 0
    end

    local cards = {}
    for i=1, #c do
        if GetCardSetId(c[i].id) == set_id then
            table.insert(cards, c[i])
        end
    end

    return #cards
end

-- 卡包，获取卡牌，记录历史
function OpenPackage(session, fever_card_info, package_type, source)
    local player = session.player
    local config = FeverCardsPackageConfig[package_type]
    -- 随机卡牌数量
    local s = {}
    for i=1, #config.cards_number do
        table.insert(s, 1)
    end
    local count = config.cards_number[math.rand_weight(player, s)]

    LOG(RUN, INFO).Format("[FeverCardCal] open package:player %s package type %s source %s count %s", player.id,
        package_type, source, count)
    -- 随机卡牌
    fever_card_info.cards = fever_card_info.cards or {}
    local cards = fever_card_info.cards
    local card_configs = {}
    
    local current_cards = {}

    for i=1, count do
        -- 首先从必出里面查找
        local star = config._guarantee_card_star[i] or 0
        local rare = config._guarantee_card_rarity[i] or 0

        local card_config
        if star > 0 or rare > 0 then
            card_config = RandCard(current_cards, player, fever_card_info, star, rare, config)
        else
            card_config = RandNormalCard(current_cards, player, fever_card_info, config)
        end

        if card_config then
            MergeCards(cards, card_config)
            table.insert(card_configs, card_config)
            FeverCardCal.AddCardHistory(session, card_config.id, source)
            current_cards[tostring(card_config.id)] = true
        else
            LOG(RUN, INFO).Format("[FeverCardCal][OpenPackage] open package card config is nil star %s rare %s", star, rare)
        end
    end

    return card_configs
end

function SaveCurrentCardInfo(session)
    ActivityCal.Calculate.UpdateActivityInfo(session, ActivityDefine.AllTypes.FeverCard)
    local current = GetCurrentAlbum()
    SaveAlbumCards(session, current.id)
end

function SaveFeverInfo(session)
    ActivityCal.Calculate.UpdateActivityInfo(session, ActivityDefine.AllTypes.FeverCard)
end

function SaveFeverCardInfo(session, fever_card_info, album_id)
    ActivityCal.Calculate.UpdateActivityInfo(session, ActivityDefine.AllTypes.FeverCard)
    for i=1, #FeverCardsAlbumConfig do
        local album_id = FeverCardsAlbumConfig[i].id
        SaveAlbumCards(session, album_id)
    end
end

function GetSetRewardChips(fever_card_info, set_id)
    if not fever_card_info.fever_info.set_reward_chips then
        return 0
    end
    return fever_card_info.fever_info.set_reward_chips[tostring(set_id)] or 0
end

function GetSetIsRewarded(fever_card_info, set_id)
    if not fever_card_info.fever_info.set_rewards then
        return false
    end

    local v = fever_card_info.fever_info.set_rewards[tostring(set_id)] == 1
    return v
end

function GetAlbumRewardChips(fever_card_info, album_id)
    if not fever_card_info.fever_info.album_reward_chips then
        return 0
    end
    return fever_card_info.fever_info.album_reward_chips[tostring(album_id)] or 0
end

function GetAlbumIsRewarded(fever_card_info, album_id)
    if not fever_card_info.fever_info.album_rewards then
        return false
    end
    return fever_card_info.fever_info.album_rewards[tostring(album_id)] == 1
end

function GetCardEpicCount(card_id)
    local c = FeverCardsCardsConfig[card_id]
    if c.rare_level == FeverCardRare.Epic then
        return 1
    end
    return 0
end

-- 游戏Spin
function OnGameSpin(session, player, game_type, player_game_info)
    if not IsFeverCardOpen then
        return
    end

    local fever_card_info = GetFeverCardInfo(session)
    local config = GetOutputConfig(player.character.level, player_game_info.bet_amount)

    local is_epic_game = false
    local GameSortConfig = CommonCal.Calculate.get_config(player, "GameSortConfig")
    for id, game_config in pairs(GameSortConfig) do
        if game_type == game_config.gameType then
            is_epic_game = game_config.is_normal_epic == 1
            break
        end
    end


    if is_epic_game then
        local package_type = 0
        local weights = {config.collect_probabilty, config.epic_collect_probability, 1-config.epic_collect_probability-config.collect_probabilty}
        local index = math.rand_weight(player, weights)

        if index == 1 then
            OpenSourcePackage(session, fever_card_info, config.package_type, FeverCardSource.GameSpin)
        elseif index == 2 then
            OpenSourcePackage(session, fever_card_info, config.epic_package_type, FeverCardSource.GameSpin)
        end
    else
        local package_type = 0
        local weights = {config.collect_probabilty, 1-config.collect_probabilty}
        local index = math.rand_weight(player, weights)

        if index == 1 then
            OpenSourcePackage(session, fever_card_info, config.package_type, FeverCardSource.GameSpin)
        end
    end
end

-- 购买
function OnPurchase(session, player, price)
    if not IsFeverCardOpen then
        return
    end
    
    local fever_card_info = GetFeverCardInfo(session)
    local config = nil
    
    for i=1, #FeverCardsPurchaseOutputConfig do
        if FeverCardsPurchaseOutputConfig[i].pay_amount == price then
            config = FeverCardsPurchaseOutputConfig[i]
            break
        end
    end

    if not config then
        return
    end

    OpenSourcePackage(session, fever_card_info, config.package_type, FeverCardSource.Purchase)
end

-- 日常任务
function OnDailyMission(session, player, reward_type)
    if not IsFeverCardOpen then
        return
    end
    local fever_card_info = GetFeverCardInfo(session)
    local config = nil

    if not (reward_type == 1 or reward_type == 2) then
        return
    end

    config = FeverCardsDailyMissionOutputConfig[reward_type]
    
    OpenSourcePackage(session, fever_card_info, config.package_type, FeverCardSource.DailyMission)
end

function GetUnlockLevel()
    local config = nil

    for i=#FeverCardsLevelOutputConfig, 1, -1 do
        if FeverCardsLevelOutputConfig[i].is_unlock_level == 1 then
            config = FeverCardsLevelOutputConfig[i]
            break
        end
    end

    return config.player_level
end

-- 玩家升级
function OnLevelUp(session, player, new_level)
    if not IsFeverCardOpen then
        return
    end

    local fever_card_info = GetFeverCardInfo(session)
    
    local config = nil

    for i=#FeverCardsLevelOutputConfig, 1, -1 do
        if new_level == FeverCardsLevelOutputConfig[i].player_level then
            config = FeverCardsLevelOutputConfig[i]
            break
        end
    end

    if not config then
        return
    end

    LOG(RUN, INFO).Format("[FeverCardCal][OnLevelUp] new_level %s player_id %s config.player_level %s", new_level, 
        player.id, config.player_level)

    if config.is_unlock_level == 1 and config.player_level == new_level then
        OpenSourcePackage(session, fever_card_info, config.package_type, FeverCardSource.LevelUpUnlock, true)
    else
        OpenSourcePackage(session, fever_card_info, config.package_type, FeverCardSource.LevelUp, new_level >= GetUnlockLevel() )
    end
end
