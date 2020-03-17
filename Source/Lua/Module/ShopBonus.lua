module("ShopBonus", package.seeall)

-- logic -> config

GetStatus = function(_M, session, request)
    local response = {
        header = {
            router = "Response"
        }
    }

    local player = session.player
    if player == nil then
        response.ret = Return.PLAYER_NOT_FOUND()
        return response
    end
    local time_interval = os.time() - (player.character.shop_bonus_collect_time or 0)
    local config = nil

    for k, v in ipairs(ShopBonusConfig) do
        if (v.max_level > player.character.level) then
            config = v
            break
        end
    end

    if time_interval >= config.cool_down then
        -- 能够获取
        response.can_collect = 1
        response.chip_may_get = config.award
        response.cool_time = 0
    else
        response.can_collect = 0
        response.chip_may_get = 0
        response.cool_time = config.cool_down - time_interval
        if response.cool_time < 0 then response.cool_time = 0 end
    end

    response.ret = Return.OK()

    return response
end

GetBonus = function(_M, session, request)
    local response = {
        header = {
            router = "Response"
        }
    }

    local player = session.player
    local time_interval = os.time() - (player.character.shop_bonus_collect_time or 0)
    local config = nil

    for k, v in ipairs(ShopBonusConfig) do
        if (v.max_level > player.character.level) then
            config = v
            break
        end
    end

    if time_interval < config.cool_down then
        response.ret = Return.SHOPBONUS_NOT_COOL_DOWN_YET()
        return response
    end
    local vip_level = player.character.vip

    local total_chip = config.award * (VIPConfig[vip_level].shop_bonus + 1)

    Player:Obtain(player, {
        "Chip",
        total_chip
    }, Reason.SHOPBONUS_COLLECT_OBTAIN())

    response.chip_get = total_chip
    response.ret = Return.OK()
    response.cool_time = config.cool_down

    response.player = {
        character = {
            chip = player.character.chip
        }
    }

    player.character.shop_bonus_collect_time = os.time()

    return response
end

