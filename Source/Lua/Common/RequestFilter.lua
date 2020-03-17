---------------
--  RequestFilter  --
---------------
require "Common/Return"
require "Common/ClubConsts"
require "Common/LineNum"
require "Config/system/ConstValue"
-- require "Config/OpenSesameBetAmountConfig"
-- require "Config/OpenSesameOthersConfig"
-- require "Config/GiftTreatsConfig"
-- require "Config/GiftChipsConfig"
module("RequestFilter", package.seeall)

--call_common:是否调用common filter
--sub_handler_name 有的过滤分了好几部分
Filter = function(module_name, handler_name, session, request, call_common, sub_handler_name)
    if (session.player ~= nil) then
        if (session.player.character.player_type == tonumber(ConstValue[5].value)) then
            local ret
            if call_common then
                ret = AllFilter.Common(session, request)
                if ret then
                    return ret
                end
            end
            if sub_handler_name then
                filters = AllFilter[module_name][handler_name][sub_handler_name]
            else
                filters = AllFilter[module_name][handler_name]
            end

            if (filters == nil) then
                LOG(RUN, INFO).Format(
                    "[Filter][error] module name is: %s, handler name is: %s",
                    module_name,
                    handler_name
                )
            end

            for k, v in ipairs(filters) do
                ret = v(session, request)
                if ret then
                    if (ret.code == 138002) then
                        return ret
                    end
                end
            end
            return nil
        end
    end
    local ret
    if call_common then
        ret = AllFilter.Common(session, request)
        if ret then
            return ret
        end
    end
    if sub_handler_name then
        filters = AllFilter[module_name][handler_name][sub_handler_name]
    else
        filters = AllFilter[module_name][handler_name]
    end

    if (filters == nil) then
        LOG(RUN, INFO).Format("[Filter][error] module name is: %s, handler name is: %s", module_name, handler_name)
    end

    for k, v in ipairs(filters) do
        ret = v(session, request)
        if ret then
            return ret
        end
    end
end

local GAME_LOCK_TIME = -1

AllFilter = {
    --Common
    Common = function(session, request)
        if not session or not session.player then
            LOG(RUN, INFO).Format("[Filter][Common] player not found filter")
            return Return.PLAYER_NOT_FOUND()
        end
    end,
    -- account
    Account = {
        Login = {
            --重复登陆过滤
            [1] = function(session, request)
                if session.logined then
                    LOG(RUN, INFO).Format("[Account][Login]token %s repeated login", request.token)
                    return Return.ACCOUNT_REPEATED_LOGIN()
                else
                    session.logined = true
                end
            end,
            --kick self

            [2] = function(session, request)
                if session.player then
                    LOG(RUN, INFO).Format("[Account][Login] token %s is already has player", request.token)
                    return Return.ALREADY_HAS_PLAYER()
                end
            end
        },
        SetUser = {
            Nickname = {
                --check if nickname has special character
                [1] = function(session, request)
                    local nickname = request.user.nickname
                    if not string.check_special_char(request.user.nickname, {" "}) then
                        LOG(RUN, INFO).Format(
                            "[Account][SetUser] splayer%s's new nickname has special character",
                            session.player.id
                        )
                        return Return.ACCOUNT_NICKNAME_INVALID()
                    end
                end,
                --check if nickname over length
                [2] = function(session, request)
                    local nickname = request.user.nickname
                    if string.len(nickname) > 64 or string.len(nickname) == 0 then
                        LOG(RUN, INFO).Format("[Account][SetUser] player%s's new nickname's length", session.player.id)
                        return Return.ACCOUNT_NICKNAME_OVER_LENGTH()
                    end
                end
            },
            Sex = {
                [1] = function(session, request)
                    local sex = request.user.sex
                    --0:not set 1:male 2:female
                    if sex > 2 or sex < 0 then
                        LOG(RUN, INFO).Format(
                            "[Account][SetUser] player%s set sex to %s,  is valid",
                            session.player.id,
                            request.user.sex
                        )
                        return Return.ACCOUNT_SEX_INVALID()
                    end
                end
            },
            Signature = {
                --check if signature is valid
                [1] = function(session, request)
                    if not string.check_special_char(request.user.signature, ClubConsts.AllowedChars) then
                        LOG(RUN, INFO).Format(
                            "[Account][SetUser] player%s's new signature %s has special character",
                            session.player.id,
                            request.user.signature
                        )
                        return Return.ACCOUNT_SIGNATURE_INVALID()
                    end
                end,
                --check signature length
                [2] = function(session, request)
                    if string.len(request.user.signature) > 96 then
                        LOG(RUN, INFO).Format(
                            "[Account][SetUser] player%s's new signature %s 's length",
                            session.player.id,
                            request.user.signature
                        )
                        return Return.ACCOUNT_SIGNATURE_OVER_LENGTH()
                    end
                end
            },
            Age = {
                [1] = function(session, request)
                    if request.user.age < 0 or request.user.age > 500 then
                        LOG(RUN, INFO).Format(
                            "[Account][SetUser] player%s new age %s is valid",
                            session.player.id,
                            request.user.age
                        )
                        return Return.ACCOUNT_AGE_INVALID()
                    end
                end
            },
            Location = {
                [1] = function(session, request)
                    if not string.check_special_char(request.user.location, {" "}) then
                        LOG(RUN, INFO).Format(
                            "[Account][SetUser] player%s's new location %s has special character",
                            session.player.id,
                            request.user.location
                        )
                        return Return.ACCOUNT_LOCATION_INVALID()
                    end
                end,
                [2] = function(session, request)
                    if string.len(request.user.location) > 96 then
                        LOG(RUN, INFO).Format(
                            "[Account][SetUser] player%s's new location %s 's length",
                            session.player.id,
                            request.user.location
                        )
                        return Return.ACCOUNT_LOCATION_OVER_LENGTH()
                    end
                end
            },
            Country = {
                [1] = function(session, request)
                    if not string.check_special_char(request.user.country, {" "}) then
                        LOG(RUN, INFO).Format(
                            "[Account][SetUser] player%s's new country %s has special character",
                            session.player.id,
                            request.user.country
                        )
                        return Return.ACCOUNT_COUNTRY_INVALID()
                    end
                end,
                [2] = function(session, request)
                    if string.len(request.user.country) > 96 then
                        LOG(RUN, INFO).Format(
                            "[Account][SetUser] player%s's new country %s 's length",
                            session.player.id,
                            request.user.country
                        )
                        return Return.ACCOUNT_COUNTRY_OVER_LENGTH()
                    end
                end
            },
            SetBackground = {}
        }
    },
    SlotsOpenSesame = {
        Start = {
            --check is bet amount valid
            [1] = function(session, request)
                local player = session.player
                local amount = request.amount

                local OpenSesameBetAmountConfig = CommonCal.Calculate.get_config(player, "OpenSesameBetAmountConfig")

                local amount_valid = false
                for k, v in ipairs(OpenSesameBetAmountConfig) do
                    if amount == v.single_amount then
                        amount_valid = true
                    end
                end
                if not amount_valid then
                    LOG(RUN, INFO).Format("[SlotsOpenSesame][Start] player %s's bet amount %s valid", player.id, amount)
                    return Return.OPENSESAME_BET_AMOUNT_NOT_VALID()
                end
            end
        },
        --slots open sesame 只有一个common filter
        Enter = {},
        Exit = {},
        OpenBox = {}
    },
    SlotsElvesEpic = {
        Start = {
            --check is bet amount valid
            [1] = function(session, request)
                local player = session.player
                local amount = request.amount

                local ElvesEpicBetAmountConfig = CommonCal.Calculate.get_config(player, "ElvesEpicBetAmountConfig")

                local amount_valid = false
                for k, v in ipairs(ElvesEpicBetAmountConfig) do
                    if amount == v.single_amount then
                        amount_valid = true
                    end
                end
                if not amount_valid then
                    LOG(RUN, INFO).Format("[SlotsElvesEpic][Start] player %s's bet amount %s valid", player.id, amount)
                    return Return.ELVESEPIC_BET_AMOUNT_NOT_VALID()
                end
            end
        },
        --slots open sesame 只有一个common filter
        Enter = {},
        Exit = {},
        UpdateBetAmount = {}
    },
    SlotsAliceinWonderland = {
        Start = {
            --check is bet amount valid
            [1] = function(session, request)
                local player = session.player
                local amount = request.amount
                local AliceinWonderlandBetAmountConfig =
                    CommonCal.Calculate.get_config(player, "AliceinWonderlandBetAmountConfig")

                local amount_valid = false
                for k, v in ipairs(AliceinWonderlandBetAmountConfig) do
                    if amount == v.single_amount then
                        amount_valid = true
                    end
                end
                if not amount_valid then
                    return Return.GAME_BET_AMOUNT_NOT_VALID()
                end
            end
        },
        --slots open sesame 只有一个common filter
        Enter = {},
        Exit = {},
        UpdateBetAmount = {}
    },
    SlotsPirate = {
        Start = {
            --check is bet amount valid
            [1] = function(session, request)
                local player = session.player
                local amount = request.amount

                local PirateBetAmountConfig = CommonCal.Calculate.get_config(player, "PirateBetAmountConfig")
                LOG(RUN, INFO).Format(
                    "[SlotsPirate][Start] start check is player %s's bet amount %s valid",
                    player.id,
                    amount
                )
                local amount_valid = false
                for k, v in ipairs(PirateBetAmountConfig) do
                    if amount == v.single_amount then
                        amount_valid = true
                    end
                end
                if not amount_valid then
                    return Return.GAME_BET_AMOUNT_NOT_VALID()
                end
                LOG(RUN, INFO).Format("[SlotsPirate][Start] player %s's bet amount %s is valid", player.id, amount)
            end
        },
        --slots open sesame 只有一个common filter
        Enter = {},
        Exit = {},
        Slots = {}
    },
    SlotsAgentBond = {
        Start = {
            --check is bet amount valid
            [1] = function(session, request)
                local player = session.player
                local amount = request.amount
                LOG(RUN, INFO).Format(
                    "[SlotsAgentBond][Start] start check is player %s's bet amount %s valid",
                    player.id,
                    amount
                )
                local amount_valid = false
                local config = CommonCal.Calculate.get_config(player, "AgentBondBetAmountConfig")
                for k, v in ipairs(config) do
                    if amount == v.single_amount then
                        amount_valid = true
                    end
                end
                if not amount_valid then
                    return Return.GAME_BET_AMOUNT_NOT_VALID()
                end
                LOG(RUN, INFO).Format("[SlotsAgentBond][Start] player %s's bet amount %s is valid", player.id, amount)
            end
        },
        --slots open sesame 只有一个common filter
        Enter = {},
        Exit = {},
        Bonus = {}
    },
    SlotsChineseNewYear = {
        Start = {
            --check is bet amount valid
            [1] = function(session, request)
                local player = session.player
                local amount = request.amount
                LOG(RUN, INFO).Format(
                    "[SlotsChineseNewYear][Start] start check is player %s's bet amount %s valid",
                    player.id,
                    amount
                )
                local amount_valid = false
                local ChineseNewYearBetAmountConfig =
                    CommonCal.Calculate.get_config(player, "ChineseNewYearBetAmountConfig")
                for k, v in ipairs(ChineseNewYearBetAmountConfig) do
                    if amount == v.single_amount then
                        amount_valid = true
                    end
                end
                if not amount_valid then
                    return Return.GAME_BET_AMOUNT_NOT_VALID()
                end
                LOG(RUN, INFO).Format(
                    "[SlotsChineseNewYear][Start] player %s's bet amount %s is valid",
                    player.id,
                    amount
                )
            end
        },
        --slots open sesame 只有一个common filter
        Enter = {},
        Exit = {},
        Bonus = {},
        SelFreeStyle = {}
    },
    SlotsLegendsofOlympus = {
        Start = {
            --check is bet amount valid
            [1] = function(session, request)
                local player = session.player
                local amount = request.amount
                local LegendsofOlympusBetAmountConfig =
                    CommonCal.Calculate.get_config(player, "LegendsofOlympusBetAmountConfig")
                LOG(RUN, INFO).Format(
                    "[SlotsLegendsofOlympus][Start] start check is player %s's bet amount %s valid",
                    player.id,
                    amount
                )
                local amount_valid = false
                for k, v in ipairs(LegendsofOlympusBetAmountConfig) do
                    if amount == v.single_amount then
                        amount_valid = true
                    end
                end
                if not amount_valid then
                    return Return.GAME_BET_AMOUNT_NOT_VALID()
                end
                LOG(RUN, INFO).Format(
                    "[SlotsLegendsofOlympus][Start] player %s's bet amount %s is valid",
                    player.id,
                    amount
                )
            end
        },
        --slots open sesame 只有一个common filter
        Enter = {},
        Exit = {},
        Bonus = {}
    },
    SlotsBruceLee = {
        Start = {
            --check is bet amount valid
            [1] = function(session, request)
                local player = session.player
                local amount = request.amount
                LOG(RUN, INFO).Format(
                    "[SlotsBruceLee][Start] start check is player %s's bet amount %s valid",
                    player.id,
                    amount
                )
                local amount_valid = false
                local BruceLeeBetAmountConfig = CommonCal.Calculate.get_config(player, "BruceLeeBetAmountConfig")
                for k, v in ipairs(BruceLeeBetAmountConfig) do
                    if amount == v.single_amount then
                        amount_valid = true
                    end
                end
                if not amount_valid then
                    return Return.GAME_BET_AMOUNT_NOT_VALID()
                end
                LOG(RUN, INFO).Format("[SlotsBruceLee][Start] player %s's bet amount %s is valid", player.id, amount)
            end
        },
        --slots open sesame 只有一个common filter
        Enter = {},
        Exit = {},
        Bonus = {}
    },
    SlotsIceAndFire = {
        Start = {
            --check is bet amount valid
            [1] = function(session, request)
                local player = session.player
                local amount = request.amount
                LOG(RUN, INFO).Format(
                    "[SlotsIceAndFire][Start] start check is player %s's bet amount %s valid",
                    player.id,
                    amount
                )
                local amount_valid = false
                for k, v in ipairs(IceAndFireBetAmountConfig) do
                    if amount == v.single_amount then
                        amount_valid = true
                    end
                end
                if not amount_valid then
                    return Return.GAME_BET_AMOUNT_NOT_VALID()
                end
                LOG(RUN, INFO).Format("[SlotsIceAndFire][Start] player %s's bet amount %s is valid", player.id, amount)
            end
        },
        Feature_Start = {
            --check is bet amount valid
            [1] = function(session, request)
                local player = session.player
                local amount = request.amount
                LOG(RUN, INFO).Format(
                    "[SlotsIceAndFire][Feature_Start] start check is player %s's bet amount %s valid",
                    player.id,
                    amount
                )
                local amount_valid = false
                for k, v in ipairs(IceAndFireBetAmountConfig) do
                    if amount == v.single_amount then
                        amount_valid = true
                    end
                end
                if not amount_valid then
                    return Return.GAME_BET_AMOUNT_NOT_VALID()
                end
                LOG(RUN, INFO).Format(
                    "[SlotsIceAndFire][Feature_Start] player %s's bet amount %s is valid",
                    player.id,
                    amount
                )
            end
        },
        --slots open sesame 只有一个common filter
        Enter = {},
        Exit = {}
    },
    SlotsChefsChoice = {
        Start = {
            --check is bet amount valid
            [1] = function(session, request)
                local player = session.player
                local amount = request.amount
                local ChefsChoiceBetAmountConfig = CommonCal.Calculate.get_config(player, "ChefsChoiceBetAmountConfig")
                LOG(RUN, INFO).Format(
                    "[SlotsChefsChoice][Start] start check is player %s's bet amount %s valid",
                    player.id,
                    amount
                )
                local amount_valid = false
                for k, v in ipairs(ChefsChoiceBetAmountConfig) do
                    if amount == v.single_amount then
                        amount_valid = true
                    end
                end
                if not amount_valid then
                    return Return.GAME_BET_AMOUNT_NOT_VALID()
                end
                LOG(RUN, INFO).Format("[SlotsChefsChoice][Start] player %s's bet amount %s is valid", player.id, amount)
            end
        },
        --slots open sesame 只有一个common filter
        Enter = {},
        Exit = {}
    },
    SlotsWildCircus = {
        Start = {
            --check is bet amount valid
            [1] = function(session, request)
                local player = session.player
                local amount = request.amount
                local WildCircusBetAmountConfig = CommonCal.Calculate.get_config(player, "WildCircusBetAmountConfig")
                LOG(RUN, INFO).Format(
                    "[SlotsWildCircus][Start] start check is player %s's bet amount %s valid",
                    player.id,
                    amount
                )
                local amount_valid = false
                for k, v in ipairs(WildCircusBetAmountConfig) do
                    if amount == v.single_amount then
                        amount_valid = true
                    end
                end
                if not amount_valid then
                    return Return.GAME_BET_AMOUNT_NOT_VALID()
                end
                LOG(RUN, INFO).Format("[SlotsWildCircus][Start] player %s's bet amount %s is valid", player.id, amount)
            end
        },
        --slots open sesame 只有一个common filter
        Enter = {},
        Exit = {}
    },
    SlotsSantaSuprise = {
        Start = {
            --check is bet amount valid
            [1] = function(session, request)
                local player = session.player
                local amount = request.amount
                local SantaSupriseBetAmountConfig =
                    CommonCal.Calculate.get_config(player, "SantaSupriseBetAmountConfig")
                LOG(RUN, INFO).Format(
                    "[SlotsSantaSuprise][Start] start check is player %s's bet amount %s valid",
                    player.id,
                    amount
                )
                local amount_valid = false
                for k, v in ipairs(SantaSupriseBetAmountConfig) do
                    if amount == v.single_amount then
                        amount_valid = true
                    end
                end
                if not amount_valid then
                    return Return.GAME_BET_AMOUNT_NOT_VALID()
                end
                LOG(RUN, INFO).Format(
                    "[SlotsSantaSuprise][Start] player %s's bet amount %s is valid",
                    player.id,
                    amount
                )
            end
        },
        --slots open sesame 只有一个common filter
        Enter = {},
        Exit = {}
    },
    SlotsBacktoJurassic = {
        Start = {
            --check is bet amount valid
            [1] = function(session, request)
                local player = session.player
                local amount = request.amount
                LOG(RUN, INFO).Format(
                    "[SlotsBacktoJurassic][Start] start check is player %s's bet amount %s valid",
                    player.id,
                    amount
                )
                local amount_valid = false
                local BacktoJurassicBetAmountConfig =
                    CommonCal.Calculate.get_config(player, "BacktoJurassicBetAmountConfig")
                for k, v in ipairs(BacktoJurassicBetAmountConfig) do
                    if amount == v.single_amount then
                        amount_valid = true
                    end
                end
                if not amount_valid then
                    return Return.GAME_BET_AMOUNT_NOT_VALID()
                end
                LOG(RUN, INFO).Format(
                    "[SlotsBacktoJurassic][Start] player %s's bet amount %s is valid",
                    player.id,
                    amount
                )
            end
        },
        --slots open sesame 只有一个common filter
        Enter = {},
        Exit = {}
    },
    SlotsLuxuryLife = {
        Start = {
            --check is bet amount valid
            [1] = function(session, request)
                local player = session.player
                local amount = request.amount
                local LuxuryLifeBetAmountConfig = CommonCal.Calculate.get_config(player, "LuxuryLifeBetAmountConfig")
                LOG(RUN, INFO).Format(
                    "[SlotsLuxuryLife][Start] start check is player %s's bet amount %s valid",
                    player.id,
                    amount
                )
                local amount_valid = false
                for k, v in ipairs(LuxuryLifeBetAmountConfig) do
                    if amount == v.single_amount then
                        amount_valid = true
                    end
                end
                if not amount_valid then
                    return Return.GAME_BET_AMOUNT_NOT_VALID()
                end
                LOG(RUN, INFO).Format("[SlotsLuxuryLife][Start] player %s's bet amount %s is valid", player.id, amount)
            end
        },
        --slots open sesame 只有一个common filter
        Enter = {},
        Exit = {}
    },
    SlotsPurrfectPets = {
        Start = {
            --check is bet amount valid
            [1] = function(session, request)
                local player = session.player
                local amount = request.amount
                local PurrfectPetsBetAmountConfig =
                    CommonCal.Calculate.get_config(player, "PurrfectPetsBetAmountConfig")
                LOG(RUN, INFO).Format(
                    "[SlotsPurrfectPets][Start] start check is player %s's bet amount %s valid",
                    player.id,
                    amount
                )
                local amount_valid = false
                for k, v in ipairs(PurrfectPetsBetAmountConfig) do
                    if amount == v.single_amount then
                        amount_valid = true
                    end
                end
                if not amount_valid then
                    return Return.GAME_BET_AMOUNT_NOT_VALID()
                end
                LOG(RUN, INFO).Format(
                    "[SlotsAliceinWonder][Start] player %s's bet amount %s is valid",
                    player.id,
                    amount
                )
            end
        },
        Enter = {},
        Exit = {}
    },
    SlotsCashSpin = {
        Start = {
            --check is bet amount valid
            [1] = function(session, request)
                local player = session.player
                local amount = request.amount
                local CashSpinBetAmountConfig = CommonCal.Calculate.get_config(player, "CashSpinBetAmountConfig")
                LOG(RUN, INFO).Format(
                    "[SlotsCashSpin][Start] start check is player %s's bet amount %s valid",
                    player.id,
                    amount
                )
                local amount_valid = false
                for k, v in ipairs(CashSpinBetAmountConfig) do
                    if amount == v.single_amount then
                        amount_valid = true
                    end
                end
                if not amount_valid then
                    return Return.GAME_BET_AMOUNT_NOT_VALID()
                end
                LOG(RUN, INFO).Format("[SlotsCashSpin][Start] player %s's bet amount %s is valid", player.id, amount)
            end
        },
        --slots open sesame 只有一个common filter
        Enter = {},
        Exit = {},
        Pick = {}
    },
    SlotsSummerBeach = {
        Start = {
            --check is bet amount valid
            [1] = function(session, request)
                local player = session.player
                local amount = request.amount
                LOG(RUN, INFO).Format(
                    "[SlotsSummerBeach][Start] start check is player %s's bet amount %s valid",
                    player.id,
                    amount
                )
                local amount_valid = false
                for k, v in ipairs(SummerBeachBetAmountConfig) do
                    if amount == v.single_amount then
                        amount_valid = true
                    end
                end
                if not amount_valid then
                    return Return.GAME_BET_AMOUNT_NOT_VALID()
                end
                LOG(RUN, INFO).Format("[SlotsSummerBeach][Start] player %s's bet amount %s is valid", player.id, amount)
            end
        },
        --slots open sesame 只有一个common filter
        Enter = {},
        Exit = {},
        Pick = {}
    },
    SlotsGame = {
        Start = {},
        Bonus = {},
        Enter = {},
        Exit = {}
    },
    LobbyBonus = {
        Display = {},
        Collect = {},
        Multiply = {},
        AddFrd = {},
        ApplyFrd = {},
        UnLock = {},
        LoginAward = {},
        CollectPot = {}
    },
    LobbyBonusV2 = {
        GetConfig = {},
        GetStatus = {},
        GetChipBonus = {},
        GetWheelBonus = {}
    },
    Gift = {
        SendTreats = {
            --赠送treat时筹码是否够
            [1] = function(session, request)
                local treat_id = request.treat_id
                local cost_type = GiftTreatsConfig[treat_id].cost_type
                local cost_amount = GiftTreatsConfig[treat_id].cost_amount
                local to_player_id_list = request.to_player_id
                local to_player_count = #to_player_id_list
                local total_cost = to_player_count * cost_amount
                local player = session.player
                LOG(RUN, INFO).Format(
                    "[Gift][SendTreats] start check is player %s has enough prop:{%s, %s}",
                    player.id,
                    cost_type,
                    cost_amount
                )
                if not Player:Has(player, {cost_type, total_cost}) then
                    return Return.GIFT_PRESENT_NOT_ENOUGH_CHIP()
                end
                LOG(RUN, INFO).Format(
                    "[Gift][SendTreats] player %s has enough prop:{%s, %s}",
                    player.id,
                    cost_type,
                    cost_amount
                )
            end,
            [2] = function(session, request)
                LOG(RUN, INFO).Format("[Gift][SendTreats] start check is player %s's channel valid", session.player.id)
                local channel = Channel:Get(request.type)
                if not channel then
                    return Return.GIFT_PRESENT_CHANNEL_NOT_EXIST()
                end
                LOG(RUN, INFO).Format("[Gift][SendTreats] player %s's channel is valid", session.player.id)
            end
        },
        SendChips = {
            [1] = function(session, request)
                local chip_id = request.chip_id
                local cost_type = GiftChipsConfig[chip_id].cost_type
                local cost_amount = GiftChipsConfig[chip_id].cost_amount
                local to_player_id_list = request.to_player_id
                local to_player_count = #to_player_id_list
                local total_cost = cost_amount * to_player_count
                local player = session.player
                LOG(RUN, INFO).Format(
                    "[Gift][SendChips] start check is player %s has enough prop:{%s, %s}",
                    player.id,
                    cost_type,
                    total_cost
                )
                if not Player:Has(player, {cost_type, total_cost}) then
                    return Return.GIFT_PRESENT_NOT_ENOUGH_DIAMOND()
                end
                LOG(RUN, INFO).Format(
                    "[Gift][SendChips] player %s has enough prop:{%s, %s}",
                    player.id,
                    cost_type,
                    total_cost
                )
            end,
            [2] = function(session, request)
                LOG(RUN, INFO).Format("[Gift][SendChips] start check is player %s's channel valid", session.player.id)
                local channel = Channel:Get(request.type)
                if not channel then
                    return Return.GIFT_PRESENT_CHANNEL_NOT_EXIST()
                end
                LOG(RUN, INFO).Format("[Gift][SendChips] player %s's channel is valid", session.player.id)
            end
        }
    },
    SlotsDragonTale = {
        Start = {
            --check is bet amount valid
            [1] = function(session, request)
                local player = session.player
                local amount = request.amount
                local DragonTaleBetAmountConfig = CommonCal.Calculate.get_config(player, "DragonTaleBetAmountConfig")
                LOG(RUN, INFO).Format(
                    "[SlotsDragonTale][Start] start check is player %s's bet amount %s valid",
                    player.id,
                    amount
                )
                local amount_valid = false
                for k, v in ipairs(DragonTaleBetAmountConfig) do
                    if amount == v.single_amount then
                        amount_valid = true
                    end
                end
                if not amount_valid then
                    return Return.DRAGONTALE_BET_AMOUNT_NOT_VALID()
                end
                LOG(RUN, INFO).Format("[SlotsDragonTale][Start] player %s's bet amount %s is valid", player.id, amount)
            end
        },
        --slots open sesame 只有一个common filter
        Enter = {},
        Exit = {}
    },
    SlotsWestWorld = {
        Start = {
            --check is bet amount valid
            [1] = function(session, request)
                local player = session.player
                local amount = request.amount
                local WestWorldBetAmountConfig = CommonCal.Calculate.get_config(player, "WestWorldBetAmountConfig")
                LOG(RUN, INFO).Format(
                    "[SlotsWestWorld][Start] start check is player %s's bet amount %s valid",
                    player.id,
                    amount
                )
                local amount_valid = false
                for k, v in ipairs(WestWorldBetAmountConfig) do
                    if amount == v.single_amount then
                        amount_valid = true
                    end
                end
                if not amount_valid then
                    return Return.GAME_BET_AMOUNT_NOT_VALID()
                end
                LOG(RUN, INFO).Format("[SlotsWestWorld][Start] player %s's bet amount %s is valid", player.id, amount)
            end
        },
        --slots open sesame 只有一个common filter
        Enter = {},
        Exit = {}
    },
    SlotsForbiddenCity = {
        Start = {
            --check is bet amount valid
            [1] = function(session, request)
                local player = session.player
                local amount = request.amount
                local ForbiddenCityBetAmountConfig =
                    CommonCal.Calculate.get_config(player, "ForbiddenCityBetAmountConfig")
                LOG(RUN, INFO).Format(
                    "[SlotsForbiddenCity][Start] start check is player %s's bet amount %s valid",
                    player.id,
                    amount
                )
                local amount_valid = false
                for k, v in ipairs(ForbiddenCityBetAmountConfig) do
                    if amount == v.single_amount then
                        amount_valid = true
                    end
                end
                if not amount_valid then
                    return Return.FORBIDDENCITY_BET_AMOUNT_NOT_VALID()
                end
                LOG(RUN, INFO).Format(
                    "[SlotsForbiddenCity][Start] player %s's bet amount %s is valid",
                    player.id,
                    amount
                )
            end
        },
        --slots open sesame 只有一个common filter
        Enter = {},
        Exit = {},
        ChooseFreeSpin = {
            [1] = function(session, request)
                local player = session.player
                local ForbiddenCityFreeSpinConfig =
                    CommonCal.Calculate.get_config(player, "ForbiddenCityFreeSpinConfig")
                LOG(RUN, INFO).Format(
                    "[SlotsForbiddenCity][ChooseFreeSpin] start check player %s's index valid",
                    session.player.id
                )
                local index = request.index
                if index <= 0 or index > #ForbiddenCityFreeSpinConfig then
                    return Return.FORBIDDENCITY_CHOOSE_INDEX_INVALID()
                end
                LOG(RUN, INFO).Format(
                    "[SlotsForbiddenCity][ChooseFreeSpin] player %s's index is valid",
                    session.player.id
                )
            end
        }
    },
    SlotsVampire = {
        Start = {
            --check is bet amount valid
            [1] = function(session, request)
                local player = session.player
                local amount = request.amount
                local VampireBetAmountConfig = CommonCal.Calculate.get_config(player, "VampireBetAmountConfig")
                LOG(RUN, INFO).Format(
                    "[SlotsVampire][Start] start check is player %s's bet amount %s valid",
                    player.id,
                    amount
                )
                local amount_valid = false
                for k, v in ipairs(VampireBetAmountConfig) do
                    if amount == v.single_amount then
                        amount_valid = true
                    end
                end
                if not amount_valid then
                    return Return.VAMPIRE_BET_AMOUNT_NOT_VALID()
                end
                LOG(RUN, INFO).Format("[SlotsVampire][Start] player %s's bet amount %s is valid", player.id, amount)
            end
        },
        --slots open sesame 只有一个common filter
        Enter = {},
        Exit = {}
    },
    SlotsFruitSlice = {
        Start = {
            --check is bet amount valid
            [1] = function(session, request)
                local player = session.player
                local amount = request.amount
                local FruitSliceBetAmountConfig = CommonCal.Calculate.get_config(player, "FruitSliceBetAmountConfig")
                LOG(RUN, INFO).Format(
                    "[SlotsFruitSlice][Start] start check is player %s's bet amount %s valid",
                    player.id,
                    amount
                )
                local amount_valid = false
                for k, v in ipairs(FruitSliceBetAmountConfig) do
                    if amount == v.single_amount then
                        amount_valid = true
                    end
                end
                if not amount_valid then
                    return Return.FRUITSLICE_BET_AMOUNT_NOT_VALID()
                end
                LOG(RUN, INFO).Format("[SlotsFruitSlice][Start] player %s's bet amount %s is valid", player.id, amount)
            end
        },
        Enter = {},
        Exit = {},
        Slice = {}
    },
    SlotsPharaohTreasure = {
        Start = {
            --check is bet amount valid
            [1] = function(session, request)
                local player = session.player
                local amount = request.amount
                local PharaohTreasureBetAmountConfig =
                    CommonCal.Calculate.get_config(player, "PharaohTreasureBetAmountConfig")
                LOG(RUN, INFO).Format(
                    "[SlotsPharaohTreasure][Start] start check is player %s's bet amount %s valid",
                    player.id,
                    amount
                )
                local amount_valid = false
                for k, v in ipairs(PharaohTreasureBetAmountConfig) do
                    if amount == v.single_amount then
                        amount_valid = true
                    end
                end
                if not amount_valid then
                    return Return.PHARAOHTREASURE_BET_AMOUNT_NOT_VALID()
                end
                LOG(RUN, INFO).Format(
                    "[SlotsPharaohTreasure][Start] player %s's bet amount %s is valid",
                    player.id,
                    amount
                )
            end
        },
        Enter = {},
        Exit = {},
        Pick = {}
    },
    SlotsHalloweenNight = {
        Start = {
            --check is bet amount valid
            [1] = function(session, request)
                local player = session.player
                local amount = request.amount

                local HalloweenNightBetAmountConfig =
                    CommonCal.Calculate.get_config(player, "HalloweenNightBetAmountConfig")
                LOG(RUN, INFO).Format(
                    "[SlotsHalloweenNight][Start] start check is player %s's bet amount %s valid",
                    player.id,
                    amount
                )
                local amount_valid = false
                for k, v in ipairs(HalloweenNightBetAmountConfig) do
                    if amount == v.single_amount then
                        amount_valid = true
                    end
                end
                if not amount_valid then
                    return Return.HALLOWEENNIGHT_BET_AMOUNT_NOT_VALID()
                end
                LOG(RUN, INFO).Format(
                    "[SlotsHalloweenNight][Start] player %s's bet amount %s is valid",
                    player.id,
                    amount
                )
            end
        },
        Enter = {},
        Exit = {}
    }
}
