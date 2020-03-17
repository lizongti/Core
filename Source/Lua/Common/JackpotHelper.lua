require "Config/system/JackpotConfig"

_G.JackpotHelper = {}
-- dispatcher服务器

local function LockWinJackpot(session, task, game_type, jackpot_type)
    local async_request = {
        [1] = string.format("setnx jackpot_lock_%d_%d %s", game_type, jackpot_type, system.time()),
        [2] = string.format("EXPIRE jackpot_lock_%d_%d 5", game_type, jackpot_type)
    }

    local async_response = session:ContactJson("CacheClientService", task, async_request, game_type)
    local value = tonumber(async_response[1])
    return value == 1
end

local function GetPlayerCount(task, game_type)
    local game_room_config = GameRoomConfig[game_type]

    local async_request = {
        header = {
            router = "AsyncRequest",
            service_name = game_room_config.contest_client_name,
            task_id = task.id,
            module_id = "SlotsRoomInfoContest",
            message_id = "SlotsRoomInfoContest_QueryRoomBrief_Request"
        }
    }

    async_request.game_type = game_room_config.game_type
    local async_response = Base[game_room_config.contest_client_name]:ContactPacket(task, async_request)

    if async_response.ret.code ~= 0 then
        return
    end
    return async_response.player_count
end

local function GetAllReward(jackpot_type)
    local configs = {}
    for k, v in pairs(JackpotConfig) do
        if v.reward_type == jackpot_type then
            table.insert(configs, v)
        end
    end
    table.sort(configs, function(a, b)
        return a.total_bet > b.total_bet
    end)
    return configs
end

local function CalcPossibleReward(jackpot_type, charged, is_robot)
    local configs = {}
    for k, v in pairs(JackpotConfig) do
        if v.reward_type == jackpot_type then
            if charged or is_robot then
                table.insert(configs, v)
            elseif v.reward_type == 1 then
                -- 没有充值的玩家只能随机到第一种奖
                table.insert(configs, v)
            end
        end
    end
    table.sort(configs, function(a, b)
        return a.total_bet > b.total_bet
    end)
    return configs
end

local function RandReward(configs, pool_value, total_bet_value, current_bet_player_count, game_type)
    for i = 1, #configs do
        local rate = configs[i].rate or 0
        local reward_rate = 1.0 / ((pool_value / total_bet_value) * current_bet_player_count * 100)

        if reward_rate > 0.2 then
            reward_rate = 0.2
        end

        reward_rate = reward_rate + rate
        local mr = math.random()
        local is_win = mr < reward_rate

        if is_win then
            LOG(RUN, INFO).Format(
                "[JackpotHelper][RandReward]pool_value %s math.random %s reward_rate %s game_type %s",
                pool_value,
                mr,
                reward_rate,
                game_type
            )
            return configs[i]
        end
    end

    return nil
end

local function Spin(player, game_type, jackpot_type, player_game_info, current_bet_player_count)
    local is_robot = (player.character.player_type == tonumber(ConstValue[5].value))

    local jackpot_config = JackpotTypeConfig[jackpot_type]
    -- 中奖押注最低次数
    local key = string.format("bet_count_%s_%s", game_type, jackpot_type)
    -- @debug
    local spin_count = CommonCal.Calculate.get_game_json_value(player_game_info, key) or 0
    spin_count = spin_count + 1
    CommonCal.Calculate.set_game_json_value(player_game_info, key, spin_count)

    if spin_count < jackpot_config.min_bet_count and not is_robot then
        LOG(RUN, INFO).Format("[JackpotHelper][StartSpin]jackpot min_bet_count %s %s", spin_count, jackpot_config.min_bet_count)
        return
    end

    -- 获取奖池大小
    local key = string.format("Slots.Jackpot.Game%s.Type%s", game_type, jackpot_type)
    local pool_value = GlobalState:Get(key)
    if not pool_value or pool_value == 0 then
        LOG(RUN, INFO).Format("[JackpotHelper][StartSpin]jackpot pool_value is ", pool_value)
        return
    end

    local must_win = false
    -- 筹码数量限制
    if not is_robot then
        -- 玩家
        if pool_value < jackpot_config.jackpot_player_min_limit then
            LOG(RUN, INFO).Format("[JackpotHelper][StartSpin]jackpot pool_value limit1 %s %s", pool_value, jackpot_config.jackpot_player_min_limit)
            return
        end
        if pool_value > jackpot_config.jackpot_player_max_limit then
            LOG(RUN, INFO).Format("[JackpotHelper][StartSpin]jackpot pool_value limit2 %s %s", pool_value, jackpot_config.jackpot_player_max_limit)
            return
        end
    else
        -- 机器人
        if pool_value < jackpot_config.jackpot_player_min_limit then
            return
        end
        if pool_value > jackpot_config.jackpot_player_max_limit then
            must_win = true
        end
    end

    -- 累计开奖前所有玩家的押注金额
    local key = string.format("Slots.Jackpot.Game%s.TotalBetValue%s", game_type, jackpot_type)
    local total_bet_value = GlobalState:Get(key)
    total_bet_value = total_bet_value > 0 and total_bet_value or 1

    if is_robot and must_win then
        local rand = math.random(1, 2)
        if rand == 1 then
            local r = GetAllReward(jackpot_type)
            return r[1]
        end
    end

    -- 计算概率
    -- 通过当前押注获取所有的可能中奖情况
    local configs = CalcPossibleReward(jackpot_type, (player.character.charge or 0) > 0, is_robot)
    local reward_config = RandReward(configs, pool_value, total_bet_value, current_bet_player_count, game_type)

    if not reward_config then
        LOG(RUN, INFO).Format(
            "[JackpotHelper][StartSpin]bet_value %s charge %s player_count %s total_bet %s pool %s",
            bet_value or 0,
            player.character.charge or 0,
            current_bet_player_count or 0,
            total_bet_value or 0,
            pool_value or 0
        )
        return
    end

    return reward_config
end

-- 玩家点击start，开始计算玩家是否中奖
function JackpotHelper:StartSpin(session, player, total_bet, game_type, task, player_game_info)
    -- 屏蔽部分游戏
    local v = JackpotNumberConfig[game_type]
    if not v or v.Pool_Number == 0 then
        return
    end

    LOG(RUN, INFO).Format("[JackpotHelper][StartSpin]jackpot start spin %s %s %s", player.id, total_bet, game_type)

    local config = JackpotConfig[total_bet]

    if not config then
        return
    end

    -- 加入到押注池
    local key = string.format("Slots.Jackpot.Game%s.TotalBetValue%s", game_type, config.reward_type)
    GlobalState:Append(key, total_bet)

    local current_bet_player_count = GetPlayerCount(task, game_type)

    if not current_bet_player_count then
        return
    end

    local v = nil
    for i = 1, config.reward_type do
        v = Spin(player, game_type, i, player_game_info, current_bet_player_count)
        if v then
            break
        end
    end

    if not v then
        return
    end

    local reward_config = v

    local jackpot_type_config = JackpotTypeConfig[reward_config.reward_type]

    local pool_key = string.format("Slots.Jackpot.Game%s.Type%s", game_type, reward_config.reward_type)
    local pool_value = GlobalState:Get(pool_key)

    local count_key = string.format("jackpot_reward_count_%s_%s", game_type, reward_config.reward_type)
    local reward_count = CommonCal.Calculate.get_game_json_value(player_game_info, count_key) or 0

    if reward_count == 0 then
        -- 锁定jackpot
        local success = LockWinJackpot(session, task, game_type, reward_config.reward_type)
        if not success then
            LOG(RUN, INFO).Format("[JackpotHelper][StartSpin] lock jackpot failed value")
            return
        end

        LOG(RUN, INFO).Format("[JackpotHelper][StartSpin] win jackpot player.id %s pool_value %s reward_count %s", player.id, pool_value, reward_count)

        -- 获取金币
        local win_chip = pool_value
        local game_room_config = GameRoomConfig[game_type]
        Player:Obtain(player, {"Chip", win_chip}, game_room_config.game_name.." Jackpot中奖获得")

        -- 奖池扣除金币
        local v = jackpot_type_config.jackpot_init_value_max - jackpot_type_config.jackpot_init_value_min
        local rand_value = jackpot_type_config.jackpot_init_value_min + math.random() * v
        rand_value = math.ceil(rand_value)
        GlobalState:Append(pool_key, rand_value - win_chip)

        -- 累计押注额度
        local key = string.format("Slots.Jackpot.Game%s.TotalBetValue%s", game_type, reward_config.reward_type)
        local total_bet_value = GlobalState:Get(key)
        GlobalState:Append(key, -total_bet_value)

        -- 开奖周期5次不中奖
        local count_key = string.format("jackpot_reward_count_%s_%s", game_type, reward_config.reward_type)
        CommonCal.Calculate.set_game_json_value(player_game_info, count_key, 4)

        -- 给所有玩家发送通知
        local channel = Channel:Get(2)
        local channel_id = channel:Id(player, session, task)

        -- local notice = {
        --     header = {router = "Broadcast", channel_id = channel_id, module_id = "Jackpot", message_id = "Jackpot_WinReward_Notice",},
        --     type = channel.type,
        --     win_chip = win_chip,
        --     player = {
        --         id = player.id,
        --         user = {nickname = player.user.nickname, avatar = player.user.avatar},
        --         account = {facebook_id = player.account.facebook_id},
        --         game_type = game_type,
        --         character = {
        --             chip = player.character.chip,
        --             vip = player.character.vip,
        --             level = player.character.level,
        --             experience = player.character.experience,
        --             player_type = player.character.player_type
        --         }
        --     },
        --     nickname = player.user.nickname,
        --     player_id = player.id,
        --     game_type = game_type,

        --     jackpot = {game_type = game_type, jackpot_type = reward_config.reward_type, jackpot_value = rand_value, jackpot_time = os.time(),}
        -- }

        -- --发给广播服务器
        -- session:WriteRouterPacket(notice)
        --发给自己
        notice.header = {
            router = "Notice",
            module_id = "Jackpot",
            message_id = "Jackpot_WinReward_Notice"
        }
        notice.show_effect = 1

        session:WriteRouterPacket(notice)

    else
        LOG(RUN, INFO).Format("[JackpotHelper][StartSpin] win jackpot player.id %s pool_value %s reward_count %s", player.id, pool_value, reward_count)
        CommonCal.Calculate.set_game_json_value(player_game_info, count_key, reward_count - 1)
    end
end
