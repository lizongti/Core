module("LuckyCal", package.seeall)
require "Util/TableExt"
require "Common/CommonCal"
require "Common/ActionType"

-- 仅仅用于记录信息
local function AddLuckyHistoryGame(save_data, game_type)
    local is_exist_game_type = false
    for k, v in pairs(save_data.force_win_info.his_game_type) do
        if (v == game_type) then
            is_exist_game_type = true
        end
    end
    if (not is_exist_game_type) then
        table.insert(save_data.force_win_info.his_game_type, game_type)
    end
end

function GetLuckyJsonInfo(player, save_data, player_json_data)
    local lucky_info = GetLuckyInfo(player, save_data, player_json_data)

    if lucky_info then
        return json.encode(lucky_info)
    end

    return ""
end

function GetLuckyInfo(player, save_data, player_json_data)
    Spark:NormalCtl(
        player,
        {
            [1] = player_json_data and player_json_data.last_normal_credit1 or 0,
            [2] = player_json_data and player_json_data.last_normal_credit2 or 0,
            [3] = player_json_data and player_json_data.normal_credit_change1 or 0,
            [4] = player_json_data and player_json_data.normal_credit_change2 or 0,
            [5] = player_json_data and player_json_data.normal_spin_count1 or 0,
            [6] = player_json_data and player_json_data.normal_spin_count2 or 0
        }
    )
    if Base.Enviroment.pro_spec_t ~= "online" then
        local lucky_info = {
            force_win_info = save_data.force_win_info,
            lucky_type = player.character.lucky_type,
            stage_type = player.character.stage_type,
            lucky_credit_change = player.character.lucky_credit_change,
            lucky  = player.character.lucky,
            unlucky_credit_change = player.character.unlucky_credit_change,
            unlucky  = player.character.unlucky,
            ContinuousSpinWithoutBankrupt = player_json_data and player_json_data.ContinuousSpinWithoutBankrupt or nil,
            ContinuousSpinNoPay = player_json_data and player_json_data.ContinuousSpinNoPay or nil,
            LastEnterGameCredits = player_json_data and player_json_data.LastEnterGameCredits or nil,

            last_normal_credit1 = player_json_data and player_json_data.last_normal_credit1 or nil,
            last_normal_credit2 = player_json_data and player_json_data.last_normal_credit2 or nil,
            normal_credit_change1 = player_json_data and player_json_data.normal_credit_change1 or nil,
            normal_credit_change2 = player_json_data and player_json_data.normal_credit_change2 or nil,
            normal_spin_count1 = player_json_data and player_json_data.normal_spin_count1 or nil,
            normal_spin_count2 = player_json_data and player_json_data.normal_spin_count2 or nil,
        }
        return lucky_info
    end

    return nil
end

function OnEnterGamePrivate(session, player, save_data, game_type, player_game_info)
    InitGameMode(session, save_data, game_type, player_game_info)

    if (IsLuckyOn(player, game_type) == 1) then
        local player_extern = CommonCal.Calculate.get_player_extern(session, task, player)
        local player_json_data = player_extern.save_data

        if (player.character.lucky_type == LuckyType.ModeTypes.Normal) then
            player_json_data.LastEnterGameCredits = player.character.chip
        else
            player_json_data.LastEnterGameCredits = 0
        end
    end

    AddLuckyHistoryGame(save_data, game_type)
end

function OnEnterGame(session, player, save_data, game_type, player_game_info)
    local success, error = pcall(OnEnterGamePrivate, session, player, save_data, game_type, player_game_info)
    
    if not success then
        LOG(RUN, INFO).Format("[LuckyCal][OnEnterGame] player %s error %s", session.player.id, error)
    end
end

function OnBonusFinished(session, player_game_info, game_type, lineNum, chip_cost, base_total_win)
    local player = session.player
    local task = session.task
    local player_extern = CommonCal.Calculate.get_player_extern(session, task, player)
    local player_json_data = player_extern.save_data
    local lineNum = LineNum[game_type]()
    -- spin结束时已经扣除了chip_cost，不需要再次扣除
    local chip_cost = 0
    
    if IsLuckyOn(player, game_type) == 1 then
        -- TODO
    end
end

function AddNormalCreditChange(player, player_json_data, normal_credit_change, win_chip)
    player_json_data[normal_credit_change] = (player_json_data[normal_credit_change] or 0) + win_chip
    LOG(RUN, DEBUG).Format("[LuckyCal][AddNormalCreditChange] player %s, name:%s, value:%s", 
        player.id, normal_credit_change, string.chip(player_json_data[normal_credit_change]))
end

function AddLuckyCredit(player, value)
    player.character.lucky_credit_change = player.character.lucky_credit_change + value
    LOG(RUN, DEBUG).Format("[+AddLuckyCredit] lucky_credit_change %s lucky %s 赢钱 %s chip %s pool %s", 
        string.chip(player.character.lucky_credit_change), string.chip(player.character.lucky), value,
        string.chip(player.character.chip),string.chip(player.character.chip+player.character.lucky_credit_change))
end

function AddUnluckyCredit(player, value)
    player.character.unlucky_credit_change = player.character.unlucky_credit_change + value
    LOG(RUN, DEBUG).Format("[-AddUnluckyCredit] unlucky_credit_change %s unlucky %s 输钱 %s chip %s pool %s", 
        string.chip(player.character.unlucky_credit_change), string.chip(player.character.unlucky), value,
        string.chip(player.character.chip), string.chip(player.character.chip+player.character.unlucky_credit_change))
end

function AddSpinCount(save_data, game_type)
    save_data.force_win_info["game"..game_type].spin_count = (save_data.force_win_info["game"..game_type].spin_count or 0) + 1
end

function IsForceWinPure(player, max_spin_count, current_spin_count, max_feature_count, current_feature_count)
    if max_spin_count <= 0 then
        return false, 0, 0
    end

    if (current_spin_count <= max_spin_count) then
        local left_spin_count = max_spin_count - current_spin_count

        if left_spin_count < 0 then
            left_spin_count = 0
        end

        local rand_value = 0

        if left_spin_count > 0 then
            rand_value = math.random_ext(player, left_spin_count)
        end

        local left_feature_count = max_feature_count - current_feature_count

        if left_feature_count < 0 then
            left_feature_count = 0
        end

        if left_feature_count > 0 and rand_value <= left_feature_count then
            return true, LuckyType.ModeTypes.ForceWin, 1
        end
    end

    return false, 0, 0
end

-- 判断是否为ForceWin
function IsForceWin(player, save_data, game_type, spin_context)
    local force_win_spin = spin_context.player_json_data.force_win_spin or 0
    local force_win_feature = spin_context.player_json_data.force_win_feature or 0

    local new_spin_num = save_data.force_win_info["game"..game_type].new_spin_num + force_win_spin
    local spin_count = save_data.force_win_info["game"..game_type].spin_count
    local new_feature_num = save_data.force_win_info["game"..game_type].new_feature_num + force_win_feature
    local new_award_num = save_data.force_win_info["game"..game_type].new_award_num
    local is_force_win, lucky_type, stage = IsForceWinPure(player, new_spin_num, spin_count, new_feature_num, new_award_num)
    return is_force_win, lucky_type, stage
end

---判断是否为Lucky
function IsLucky(player, total_amount)
    local lucky_mode_config = CommonCal.Calculate.get_config(player, "RTPModeLuckyConfig")
    if (lucky_mode_config ~= nil) then
        LOG(RUN, INFO).Format("[SlotsGame][Start] player %s begin deal lucky:%s, total amount:%s", player.id, player.character.lucky, total_amount)
        local lucky_level = player.character.lucky / total_amount
        if (lucky_level > 0) then
            for k, v in ipairs(lucky_mode_config) do
                if lucky_level > v.lucky_min and lucky_level <= v.lucky_max then
                    local stage = player.character.lucky_credit_change / player.character.lucky
                    LOG(RUN, INFO).Format("[SlotsGame][Start] player %s stage is:%f, player.character.lucky_credit_change is:%s", player.id, stage, player.character.lucky_credit_change)
                    for stage_k, stage_v in ipairs(v.stage) do
                        if (stage <= stage_v) then
                            return true, LuckyType.ModeTypes.Lucky, stage_k
                        end
                    end
                    LOG(RUN, INFO).Format("[SlotsGame][Start] player %s lucky_type is:%s, stage_type is:%s", player.id, player.character.lucky_type, player.character.stage_type)
                    break
                end
            end
        end
    end
    return false, 0, 0
end

--判断是否为UnLucky
function IsUnLucky(player, total_amount)
    local unlucky_mode_config = CommonCal.Calculate.get_config(player, "RTPModeUnLuckyConfig")

    if (unlucky_mode_config ~= nil) then
        local unlucky_level = player.character.unlucky / total_amount
        if (unlucky_level > 0) then
            for k, v in ipairs(unlucky_mode_config) do
                if unlucky_level > v.unlucky_min and unlucky_level <= v.unlucky_max then
                    local stage = player.character.unlucky_credit_change / player.character.unlucky
                    for stage_k, stage_v in ipairs(v.stage) do
                        if (stage <= stage_v) then
                            return true, LuckyType.ModeTypes.Unlucky, stage_k
                        end
                    end
                    break
                end
            end
        end
    end
    return false, 0, 0
end

function SetPlayerLuckyType(player, lucky_type)
    player.character.lucky_type = lucky_type
    LOG(RUN, DEBUG).Format("[LuckyCal][SetPlayerLuckyType] set lucky type %s", LuckyType.name(lucky_type))
end

function IsLuckyOn(player, game_type)
    local config = CommonCal.Calculate.get_config(player, "RTPModeOnOffConfig")
    local on_off = config[game_type] and config[game_type].on_off or 0
    return on_off
end

local function CalcCurrentLuckyType(session, spin_context)
    local game_type = spin_context.game_type
    local save_data = spin_context.player_game_info.save_data
    local total_amount = spin_context.lineNum * spin_context.amount
    local player = session.player

    local result, lucky_type, stage_type = IsForceWin(player, save_data, game_type, spin_context)

    if result then
        return lucky_type, stage_type
    end

    result, lucky_type, stage_type = IsLucky(player, total_amount)
    if result then
        return lucky_type, stage_type
    end

    result, lucky_type, stage_type = IsUnLucky(player, total_amount)

    if (result) then
        return lucky_type, stage_type
    end

    return LuckyType.ModeTypes.Normal, 1
end

function AddForceWinCount(save_data, player_json_data, game_type)
    -- 优先增加机台forcewin
    local new_feature_num = save_data.force_win_info["game"..game_type].new_feature_num
    local new_award_num = save_data.force_win_info["game"..game_type].new_award_num

    local force_win_feature = player_json_data.force_win_feature or 0

    if new_feature_num > new_award_num then
        save_data.force_win_info["game"..game_type].new_award_num = save_data.force_win_info["game"..game_type].new_award_num + 1
    elseif force_win_feature > 0 then
        player_json_data.force_win_feature = player_json_data.force_win_feature - 1
    end
end

function GainLucky(player, add_lucky)
	LOG(RUN, INFO).Format("[LuckyCal][GainLucky]  player %s, add_lucky:%s", player.id, add_lucky)
	player.character.lucky = player.character.lucky + add_lucky
end

function GainUnLucky(player, add_unlucky)
	LOG(RUN, INFO).Format("[LuckyCal][GainUnLucky]  player %s, add_unlucky:%s", player.id, add_unlucky)
	player.character.unlucky = player.character.unlucky + add_unlucky
end

local gid = 1
function ChangeMode(session, spin_context)
    local save_data = spin_context.player_game_info.save_data
    local chip_cost = spin_context.chip_cost
    local game_type = spin_context.game_type
    local total_amount = spin_context.lineNum * spin_context.amount
    local player_game_info = spin_context.player_game_info

    if chip_cost <= 0 then
        LOG(RUN, DEBUG).Format("[LuckyCal][ChangeMode] error state chip_cost %s", chip_cost)
        return
    end

    InitGameMode(session, save_data, game_type, player_game_info)

    local player = session.player
    local last_lucky_type = player.character.lucky_type
    local last_stage_type = player.character.stage_type

    local lucky_type, stage_type = CalcCurrentLuckyType(session, spin_context)

    if last_lucky_type == lucky_type and last_stage_type == stage_type then
        LOG(RUN, DEBUG).Format("[LuckyCal][ChangeMode] %s 当前模式 %s 等级 %s", gid, LuckyType.name(lucky_type), stage_type)
        gid = gid + 1
        return
    end

    if last_lucky_type == lucky_type then
        player.character.stage_type = stage_type
        LOG(RUN, DEBUG).Format("[LuckyCal][ChangeMode] change stage_type old %s new %s", last_stage_type, stage_type)
        return
    end

    if lucky_type == LuckyType.ModeTypes.ForceWin then
        SetPlayerLuckyType(player, lucky_type)
        return
    end

    if lucky_type == LuckyType.ModeTypes.Lucky then
        LOG(RUN, DEBUG).Format("[ChangeMode]进入lucky模式 old %s", LuckyType.name(last_lucky_type))
        SetPlayerLuckyType(player, lucky_type)
        player.character.stage_type = stage_type
        return
    end

    if lucky_type == LuckyType.ModeTypes.Unlucky then
        LOG(RUN, DEBUG).Format("[ChangeMode]进入unlucky模式 old %s", LuckyType.name(last_lucky_type))
        -- 进unlucky清空lucky
        SetPlayerLuckyType(player, lucky_type)
        player.character.stage_type = stage_type
        player.character.lucky = 0
        player.character.lucky_credit_change = 0
        return
    end

    if lucky_type == LuckyType.ModeTypes.Normal then
        LOG(RUN, DEBUG).Format("[ChangeMode]进入normal模式 old %s", LuckyType.name(last_lucky_type))
        SetPlayerLuckyType(player, lucky_type)
        player.character.lucky = 0
        player.character.lucky_credit_change = 0
        player.character.unlucky = 0
        player.character.unlucky_credit_change = 0
    else
        LOG(RUN,DEBUG).Format("[LuckyCal][ChangeMode] error lucky_type %s", lucky_type)
    end
end

function InitGameMode(session, save_data, game_type, player_game_info)
    local player = session.player
    
    if (save_data.force_win_info == nil) then
        save_data.force_win_info = {}
        if (save_data.force_win_info.his_game_type == nil) then
            save_data.force_win_info.his_game_type = {}
        end
    end

    if save_data.force_win_info["game"..game_type] == nil then
        save_data.force_win_info["game"..game_type] = {}
        save_data.force_win_info["game"..game_type].spin_count = 0
    end

    InitNewGameForceWinInfo(session, save_data, game_type)
end

function OnLevelUpPrivate(player, level)
    if not LevelConfig[level] then
        return
    end
    --添加lucky值
    local add_lucky = LevelConfig[level].lucky
    if add_lucky and add_lucky > 0 then
        LOG(RUN, INFO).Format("[Player][GainExp] player id:%s, add_lucky:%s", player.id, add_lucky)
        GainLucky(player, add_lucky)
    end
end

function OnLevelUp(player, level)
    local success, error = pcall(OnLevelUpPrivate, player, level)
    
    if not success then
        LOG(RUN, INFO).Format("[LuckyCal][OnLevelUp] player %s error %s", player.id, error)
    end
end

function OnSpinEndBankruptCheckPrivate(session, spin_context)
    local player = session.player
    local chip_cost = spin_context.chip_cost
    local player_json_data = spin_context.player_json_data

    --玩家付费、破产和进入UnLucky模式时ContinuousSpinWithoutBankrupt和ContinuousSpinNoPay清零
    if (chip_cost > player.character.chip) then
        player_json_data.ContinuousSpinWithoutBankrupt = 0 --记录玩家连续不破产的spin次数
        player_json_data.ContinuousSpinNoPay = 0---记录付费玩家连续不付费的spin次数

        -- 在玩家破产且没有Lucky值的时候清空玩家的Unlucky值
        if (player.character.lucky <= 0) then
            player.character.unlucky = 0
        end
    end

    local add_unlucky = 0

    if (player.character.charge == 0) then
        player_json_data.ContinuousSpinNoPay = 0 --对于免费玩家，该值始终为0
        local delta_day = (os.time() - player.character.create_time) / 86400
        local NonPayUnLuckyIncreaseConfig  = CommonCal.Calculate.get_config(player, "NonPayUnLuckyIncreaseConfig")
        if (NonPayUnLuckyIncreaseConfig ~= nil and player_json_data.ContinuousSpinWithoutBankrupt > 0) then
            for k, v in ipairs(NonPayUnLuckyIncreaseConfig) do
                if (delta_day < v.registertime) then
                    if player_json_data.ContinuousSpinWithoutBankrupt == v.nobankruptmax then
                        add_unlucky =  math.floor(v.unlucky * player.character.chip)
                        LOG(INFO, DEBUG).Format("[OnSpinEndBankruptCheck]免费玩家准备破产：%s", add_unlucky)
                        GainUnLucky(player, add_unlucky, "bankrupt")
                    end
                    break
                end
            end
        end
    else
        player_json_data.ContinuousSpinWithoutBankrupt = 0 --对于付费玩家，该值始终为0
        local PayUserUnLuckyIncresaeConfig  = CommonCal.Calculate.get_config(player, "PayUserUnLuckyIncresaeConfig")
        if (PayUserUnLuckyIncresaeConfig ~= nil and player_json_data.ContinuousSpinNoPay > 0) then
            for k, v in ipairs(PayUserUnLuckyIncresaeConfig) do
                if (player.character.charge <= v.payamount) then
                    if player_json_data.ContinuousSpinNoPay == v.nobankruptmax then
                        add_unlucky =  math.floor(v.unlucky * player.character.chip)
                        LOG(INFO, DEBUG).Format("[OnSpinEndBankruptCheck]付费玩家准备破产：%s", add_unlucky)
                        GainUnLucky(player, add_unlucky, "bankrupt")
                    end
                    break
                end
            end
        end
    end

    if (add_unlucky > 0) then
        player_json_data.ContinuousSpinWithoutBankrupt = 0
        player_json_data.ContinuousSpinNoPay = 0
    end
end

function OnSpinEndBankruptCheck(session, spin_context)
    local success, error = pcall(OnSpinEndBankruptCheckPrivate, session, spin_context)
    
    if not success then
        LOG(RUN, INFO).Format("[LuckyCal][OnSpinEndBankruptCheck] player %s error %s", session.player.id, error)
    end
end

local function InitNewGameForceWinInfoPrivate(session, save_data, game_type)
    local player = session.player
    local NewRTPModeForceWinConfig  = CommonCal.Calculate.get_config(player, "NewRTPModeForceWinConfig")
    
    if NewRTPModeForceWinConfig ~= nil then
        for k, v in pairs(NewRTPModeForceWinConfig) do
            if v.game_id == game_type then
                if save_data.force_win_info["game"..game_type].new_spin_num == nil then
                    save_data.force_win_info["game"..game_type].new_spin_num = v.spin
                    save_data.force_win_info["game"..game_type].new_feature_num = v.feature
                    save_data.force_win_info["game"..game_type].new_award_num = 0
                end
                break
            end
        end
    end
end

function InitNewGameForceWinInfo(session, save_data, game_type)
    local success, error = pcall(InitNewGameForceWinInfoPrivate, session, save_data, game_type)
    
    if not success then
        LOG(RUN, INFO).Format("[LuckyCal][InitNewGameForceWinInfo] player %s error %s", session.player.id, error)
    end
end

local function GetPurchaseLucky(player)
	local LuckyIncreaseRechargeMultipleConfig = CommonCal.Calculate.get_config(player, "LuckyIncreaseRechargeMultipleConfig")
	local maxIndex = #LuckyIncreaseRechargeMultipleConfig
	for index = maxIndex, 1, -1  do
		if player.character.level >= LuckyIncreaseRechargeMultipleConfig[index].level then
            LOG(RUN, INFO).Format("[LuckyCal][OnPurchase] player %s extra_lucky is: %s", 
                player.id, LuckyIncreaseRechargeMultipleConfig[index].extra_lucky)
			return LuckyIncreaseRechargeMultipleConfig[index].extra_lucky
		end
	end
	return 0
end

local function OnPurchasePrivate(session, goods_id)
    local player = session.player
    local LuckyIncreaseRechargeConfig = CommonCal.Calculate.get_config(player, "LuckyIncreaseRechargeConfig")

    local config = nil
    if (LuckyIncreaseRechargeConfig ~= nil) then
        LOG(RUN, INFO).Format("[LuckyCal][OnPurchase] begin deal lucky:%s", goods_id)
        for k, v in pairs(LuckyIncreaseRechargeConfig) do
            if (v.product_id == goods_id) then
                config = v
                break
            end
        end
    end

    if not config then return end

    local increase_value = math.floor(config.increase_value * (1 + GetPurchaseLucky(player)) + 0.5)
    GainLucky(player, increase_value)
    LOG(RUN, INFO).Format("[LuckyCal][OnPurchase]player%s, lucky:%s", player.id, player.character.lucky)
end

function OnPurchase(session, goods_id)
    local success, error = pcall(OnPurchasePrivate, session, goods_id)
    
    if not success then
        LOG(RUN, INFO).Format("[LuckyCal][OnPurchase] player %s error %s", session.player.id, error)
    end
end

local function OnFirstLoginPrivate(session)
    local player = session.player
    local LuckyIncreaseNewHandConfig = CommonCal.Calculate.get_config(player, "LuckyIncreaseNewHandConfig")

    if (LuckyIncreaseNewHandConfig ~= nil) then
        LOG(RUN, INFO).Format("[Account][Login] deal new hand lucky")
        GainLucky(player, LuckyIncreaseNewHandConfig[1].increase_value)
        LOG(RUN, INFO).Format("[Account][Login] player %s lucky is:%f", player.id, player.character.lucky)
    end
end

function OnFirstLogin(session)
    local success, error = pcall(OnFirstLoginPrivate, session)
    
    if not success then
        LOG(RUN, INFO).Format("[LuckyCal][OnFirstLogin] player %s error %s", session.player.id, error)
    end
end

local function OnBaseSpinStartPrivate(session, spin_context)
	local player = session.player
	local game_type = spin_context.game_type
	local chip_cost = spin_context.chip_cost
	local amount = spin_context.amount
	local lineNum = spin_context.lineNum
	local player_game_info = spin_context.player_game_info

    if IsLuckyOn(player, game_type) ~= 1 then
        return
    end

    AddSpinCount(player_game_info.save_data, game_type)

    ChangeMode(session, spin_context)

    local lucky_object = LuckyModeFacade:CreateModeObject(player.character.lucky_type)

    if lucky_object and lucky_object.OnBaseSpinStart then
        lucky_object:OnBaseSpinStart(session, spin_context)
    else
        LOG(RUN, DEBUG).Format("[LuckyCal][OnBaseSpinStart] error lucky object %s", LuckyType.name(player.character.lucky_type))
    end
end

function OnBaseSpinStart(session, spin_context)
	local success, error = pcall(OnBaseSpinStartPrivate, session, spin_context)
    
    if not success then
        LOG(RUN, DEBUG).Format("[LuckyCal][OnBaseSpinStart] player %s init error %s", session.player.id, error)
    end
end

local function OnBaseSpinEndPrivate(session, spin_context)
    local player = session.player
    local game_type = spin_context.game_type
    local chip_cost = spin_context.chip_cost
    local player_game_info = spin_context.player_game_info
    local save_data = player_game_info.save_data
    local win_chip = spin_context.win_chip

    if (IsLuckyOn(player, game_type) ~= 1) then
        return
    end

    OnSpinEndBankruptCheck(session, spin_context)

    local lucky_object = LuckyModeFacade:CreateModeObject(player.character.lucky_type)
    if lucky_object and lucky_object.OnBaseSpinEnd then
        lucky_object:OnBaseSpinEnd(session, spin_context)
    else
        LOG(RUN, DEBUG).Format("[LuckyCal][OnBaseSpinEnd] error lucky object %s", player.character.lucky_type)
    end

end

function OnBaseSpinEnd(session, spin_context)
    local success, error = pcall(OnBaseSpinEndPrivate, session, spin_context)
    
    if not success then
        LOG(RUN, DEBUG).Format("[LuckyCal][OnBaseSpinEnd] player %s error %s", session.player.id, error)
    end
end

function OnOldGameBonusEnd(session, game_type, player_game_info, lineNum, win_chip, task, player_json_data)
    local player = session.player
    if (IsLuckyOn(player, game_type) == 1) then
        local chip_cost = player_game_info.bet_amount * lineNum
    end

end