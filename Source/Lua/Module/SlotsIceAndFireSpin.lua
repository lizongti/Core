require "Common/SlotsGameCal"
require "Common/LineNum"
require "Common/CommonCal"
module("SlotsIceAndFireSpin", package.seeall)

function SlotsIceAndFireSpin:Enter()
    local task = self.parameters.task
    local player = self.parameters.player
    local game_room_config = self.parameters.game_room_config
    local player_game_info = self.parameters.player_game_info
    local session = self.parameters.session
    local player_game_status = self.parameters.player_game_status
    local save_data = player_game_info.save_data

    local bonus_info = {}
    bonus_info.bonus_type = player_game_info.bonus_game_type
    bonus_info.content = {}
    bonus_info.content.mother_dragons_type =
        player_game_info.mother_dragons_type

    if (player_game_info.free_spin_bouts <= 0 and bonus_info.bonus_type == 1) then
        bonus_info.bonus_type = 0
    end

    if (player_game_info.free_spin_bouts > 0 and bonus_info.bonus_type == 0) then
        bonus_info.bonus_type = 1
    end

    return bonus_info
end

-----------------------------------------------
-- 点击Spin
------------------------------------------------
Spin = function(player, game_type, is_free_spin, game_room_config, amount,
                player_feature_condition, extern_param, player_game_info)
    if (is_free_spin) then
        return FeatureSpinProcess(player, game_type, is_free_spin,
                                  game_room_config, amount,
                                  player_feature_condition, extern_param,
                                  player_game_info)
    else
        return BaseSpinProcess(player, game_type, is_free_spin,
                               game_room_config, amount,
                               player_feature_condition, extern_param,
                               player_game_info)
    end
end

function SlotsIceAndFireSpin:FreeSpin()
    local FeatureTypes = _G[game_room_config.game_name .. "TypeArray"]
                             .FeatureTypes
    local LineNum = LineNum[game_type]()

    local all_prize_items = {}

    if (player_game_info.bonus_game_type ~= 1) then
        return
    end

    local slots_spin_info = {}

    local origin_result, reel_file_name
    local item_list = {}

    origin_result, reel_file_name = SlotsGameCal.Calculate.GenItemResult(player,
                                                                         game_type,
                                                                         is_free_spin,
                                                                         game_room_config)

    local local_wild_result = table.DeepCopy(origin_result)
    local feature_type = SlotsGameCal.Calculate.ReplaceIceAndFireWildItem(
                             game_room_config, local_wild_result,
                             slots_spin_info, FeatureTypes)
    local item_ids = json.encode(SlotsGameCal.Calculate.TransResultToCList(
                                     origin_result, game_room_config))

    local payrate_file = CommonCal.Calculate.get_config(player,
                                                        game_room_config.game_name ..
                                                            "PayrateConfig")
    local left_or_right = game_room_config.direction_type -- 1左连线，2右, 3左右连线
    local prize_items, total_payrate = SlotsGameCal.Calculate.GenPrizeInfo(
                                           local_wild_result, game_room_config,
                                           payrate_file, left_or_right,
                                           FeatureTypes)

    table.insert(all_prize_items, prize_items)
    local win_chip = total_payrate * amount

    local slots_spin_list = {}

    slots_spin_info.item_ids = item_ids
    slots_spin_info.prize_items = prize_items
    slots_spin_info.win_chip = win_chip

    if (slots_spin_info.pre_action_list == nil) then
        slots_spin_info.pre_action_list = "[]"
    end

    local pre_action_list = json.decode(slots_spin_info.pre_action_list)
    local parameter_list = {}

    if (player_game_info.free_spin_bouts <= 0) then
        table.insert(parameter_list, {Enter = false})
        table.insert(pre_action_list, {
            action_type = ActionType.ActionTypes.EnterBonus,
            parameter_list = parameter_list
        })
    end

    local dd = json.encode(pre_action_list)

    slots_spin_info.pre_action_list = dd
    table.insert(slots_spin_list, slots_spin_info)

    local formation_list = {}
    local formation_info = {}
    formation_info.slots_spin_list = slots_spin_list
    formation_info.id = 2
    table.insert(formation_list, formation_info)

    return origin_result, win_chip, all_prize_items, 0, formation_list,
           reel_file_name, win_chip
end

function SlotsIceAndFireSpin:NormalSpin()
    local player = self.parameters.player
    local player_game_info = self.parameters.player_game_info
    local special_parameter = self.parameters.special_parameter
    local is_free_spin = self.parameters.is_free_spin
    local game_room_config = self.parameters.game_room_config
    local player_game_status = self.parameters.player_game_status
    local amount = self.parameters.amount
    local game_type = self.parameters.game_type
    local player_feature_condition = self.parameters.player_feature_condition
    local session = self.parameters.session
    local save_data = player_game_info.save_data

    local has_daenerys = 1

    player_game_info.bonus_game_type = 0

    local LineNum = LineNum[game_type]()
    local BaseTypes = _G[game_room_config.game_name .. "TypeArray"].BaseTypes
    local FeatureTypes = _G[game_room_config.game_name .. "TypeArray"]
                             .FeatureTypes
    local origin_result, extra_wild, extra_daenerys, reel_file_name
    local wild = {{}, {}, {}, {}, {}}
    local lockWildCol = {}
    local item_list = {}
    local all_prize_items = {}
    local loop_num = 0
    local total_win_chip = 0
    local total_free_spin_bouts = 0
    local slots_spin_list = {}
    local canEnterBonus = false

    while has_daenerys == 1 do
        local slots_spin_info = {}

        CommonCal.Calculate.SetLoopNum(player.id, loop_num)

        -- 给玩家的数据
        origin_result, reel_file_name = SlotsGameCal.Calculate.GenItemResult(
                                            player, game_type, is_free_spin,
                                            game_room_config)
        -- 哪行Wild   哪几行龙妈
        extra_wild, extra_daenerys, has_daenerys =
            SlotsGameCal.Calculate.GenIceAndFireExtResult(player,
                                                          game_room_config,
                                                          origin_result, wild,
                                                          lockWildCol, loop_num,
                                                          BaseTypes)
        -- 参与赔付的数据
        local result_with_lock_item = SlotsGameCal.Calculate
                                          .GenResultWithIceAndFireLock(
                                              game_room_config, origin_result,
                                              wild, extra_wild, extra_daenerys,
                                              slots_spin_info, BaseTypes)

        local payrate_file = CommonCal.Calculate.get_config(player,
                                                            game_room_config.game_name ..
                                                                "PayrateConfig")
        local left_or_right = game_room_config.direction_type -- 1左连线，2右, 3左右连线
        local prize_items, total_payrate =
            SlotsGameCal.Calculate.GenPrizeInfo(result_with_lock_item,
                                                game_room_config, payrate_file,
                                                left_or_right, BaseTypes)

        table.insert(all_prize_items, prize_items)

        local item_ids = json.encode(SlotsGameCal.Calculate.TransResultToCList(
                                         origin_result, game_room_config))

        local prize_items = prize_items

        local win_chip = total_payrate * amount

        total_win_chip = total_win_chip + win_chip

        if (has_daenerys == 1) then
            if (slots_spin_info.pre_action_list == nil) then
                local item = {}
                slots_spin_info.pre_action_list = json.encode(item)
            end

            local pre_action_list = json.decode(slots_spin_info.pre_action_list)
            local pre_action = {}
            pre_action.action_type = ActionType.ActionTypes.Respin
            local parameter = {}

            local parameter_list = {}
            table.insert(parameter_list, parameter)
            pre_action.parameter_list = parameter_list
            table.insert(pre_action_list, pre_action)
            slots_spin_info.pre_action_list = json.encode(pre_action_list)
        end

        local free_spin_bouts, free_item_id =
            SlotsGameCal.Calculate.GenFreeSpinCount(origin_result,
                                                    game_room_config,
                                                    BaseTypes.Bonus)

        if (free_spin_bouts > 0) then 
            canEnterBonus = true 
        end

        -- ~=1的那一刻，就是最后一次respin，这时候结算Enter Bonus
        if (has_daenerys ~= 1 and canEnterBonus) then
            local bonus_config = CommonCal.Calculate.get_config(player,
                                                                game_room_config.game_name ..
                                                                    "BonusConfig")
            local bonusList = {}
            for k, v in ipairs(bonus_config) do
                bonusList[k] = v.weight_value
            end

            local index = math.rand_weight(player, bonusList)

            if (GlobalSlotsTest[player.id] ~= nil) then
                if (GlobalSlotsTest[player.id].flag > 0) then
                    index = GlobalSlotsTest[player.id].flag
                end
            end

            if (slots_spin_info.pre_action_list == nil) then
                local item = {}
                slots_spin_info.pre_action_list = json.encode(item)
            end
            
            local pre_action_list = json.decode(slots_spin_info.pre_action_list)
            local pre_action = {}
            pre_action.action_type = ActionType.ActionTypes.EnterBonus
            local parameter_list = {}
            table.insert(parameter_list, {Enter = true, type = 3, value = index})
            pre_action.parameter_list = parameter_list

            table.insert(pre_action_list, pre_action)

            slots_spin_info.pre_action_list = json.encode(pre_action_list)

            if (index == 1) then
                total_free_spin_bouts = 10
            end
            
            player_game_info.bonus_game_type = index
        end

        if (loop_num > 0) then
            local wild_pos = {}
            for i = 1, 5, 1 do
                if (wild[i][1] ~= nil) then
                    table.insert(wild_pos, i)
                end
            end
        end

        slots_spin_info.item_ids = item_ids
        slots_spin_info.prize_items = prize_items
        slots_spin_info.win_chip = win_chip
        table.insert(slots_spin_list, slots_spin_info)

        loop_num = loop_num + 1
    end

    local formation_list = {}
    local formation_info = {}
    formation_info.slots_spin_list = slots_spin_list
    formation_info.id = 1
    table.insert(formation_list, formation_info)

    local all_prize_list = {}
    table.insert(all_prize_list, prize_items)

    if total_free_spin_bouts and total_free_spin_bouts > 0 then
        GameStatusCal.Calculate.AddGameStatus(player_game_status, GameStatusDefine.AllTypes.FreeSpinGame, total_free_spin_bouts, 1, amount)
    end

    local result = {}
    result.final_result = origin_result -- 结果数组
    result.total_win_chip = total_win_chip -- 总奖金
    result.all_prize_list = all_prize_list -- 所有连线列表
    result.free_spin_bouts = total_free_spin_bouts -- freespin的次数
    result.formation_list = formation_list -- 阵型列表
    result.reel_file_name = reel_file_name -- reel表名
    result.slots_win_chip = total_win_chip -- 总奖励
    result.special_parameter = special_parameter -- 其他参数，主要给模拟器传参
    return result
end

EggStart = function(task, player, game_room_config, parameter, player_game_info,
                    game_type)
    -- LOG(RUN, INFO).Format("[SlotsGame][Bonus] player %s, EggStart begin", player.id)
    local parameter = json.decode(parameter)
    local content = {}

    if (player.game_type ~= GameType.AllTypes.IceAndFire) then
        -- LOG(RUN, INFO).Format("game is not ice and fire")
        return content
    end

    if (player_game_info.bonus_game_type ~= 2) then
        -- LOG(RUN, INFO).Format("not trigger bnous game")
        local content_list = json.decode(player_game_info.mother_dragons_str)
        content = content_list
        return content
    end

    local IceAndFireMotherDragonsBonusConfig =
        CommonCal.Calculate.get_config(player,
                                       "IceAndFireMotherDragonsBonusConfig")

    local mother_dragons_type = parameter.mother_dragons_type

    player_game_info.mother_dragons_type = mother_dragons_type

    local content_list = {}
    local array1 = {}
    local array2 = {}
    local array3 = {}
    -- 1铜，2银，3金
    for k, v in ipairs(IceAndFireMotherDragonsBonusConfig) do
        if (v.type == mother_dragons_type) then
            if (v.sub_type == 1) then table.insert(array1, v) end
            if (v.sub_type == 2) then table.insert(array2, v) end
            if (v.sub_type == 3) then table.insert(array3, v) end
        end
    end

    for type = 1, 3, 1 do
        local array = nil
        if (type == 1) then
            array = array1
        elseif (type == 2) then
            array = array2
        elseif (type == 3) then
            array = array3
        end
        local weightList = {}
        local probabilityList = {}
        for k, v in ipairs(array) do
            weightList[k] = v.weight_value
            probabilityList[k] = v.probability
        end

        local item = {}
        for i = 1, mother_dragons_type, 1 do
            local index1 = math.rand_weight(player, weightList)
            local index2 = math.rand_weight(player, probabilityList)
            local data1 = array[index1]
            local data2 = array[index2]
            table.insert(item, {
                round = type,
                original_bonus = data1.original_bonus,
                multiple = data2.multiple
            })
        end
        table.insert(content_list, item)
    end

    player_game_info.mother_dragons_str = json.encode(content_list)

    -- LOG(RUN, INFO).Format("[SlotsGame][Bonus] player %s, select end", player.id)
    return content_list
end

EggPickFinish = function(task, player, game_room_config, parameter,
                         player_game_info, game_type)
    local content = {}
    local LineNum = GetLinesNum()
    local content_list = json.decode(player_game_info.mother_dragons_str)
    local amount = player_game_info.bet_amount

    local win_chip = 0
    for k, v in ipairs(content_list) do
        local item_list = v
        for sub_k, item in ipairs(item_list) do
            local original_bonus = tonumber(item.original_bonus)
            local multiple = tonumber(item.multiple)

            win_chip = win_chip + amount * LineNum * original_bonus * multiple
        end

    end

    content.win_chip = win_chip

    player_game_info.mother_dragons_str = "[]"
    player_game_info.mother_dragons_type = 0
    player_game_info.bonus_game_type = 0
    return content
end

PropetStart = function(task, player, game_room_config, parameter,
                       player_game_info, game_type)
    -- LOG(RUN, INFO).Format("[SlotsGame][PropetStart] player %s, PropetStart begin", player.id)
    local parameter = json.decode(parameter)
    local content = {}

    if (player_game_info.bonus_game_type ~= 3) then
        -- LOG(RUN, INFO).Format("not trigger bnous game")
        local content_list = json.decode(player_game_info.mother_dragons_str)
        content = content_list
        return content
    end

    local weight_list = {}

    local raven_prophet_list = {}
    local raven_prophet_bonus_config = CommonCal.Calculate.get_config(player,
                                                                      game_room_config.game_name ..
                                                                          "RavenProphetBonusConfig")
    for k, v in ipairs(raven_prophet_bonus_config) do
        weight_list[k] = v.weight_value
    end

    while (true) do
        -- LOG(RUN, INFO).Format("[SlotsGame][PropetStart] player %s  weight_list is: %s", player.id, Table2Str(weight_list))
        local is_empty = true
        for k, v in ipairs(weight_list) do
            if (v > 0.0) then is_empty = false end
        end
        if (is_empty) then break end

        local index = math.rand_weight(player, weight_list)
        table.insert(raven_prophet_list, raven_prophet_bonus_config[index])
        if (raven_prophet_list[1].Bonus ~= nil and raven_prophet_list[1].Bonus ==
            0) then
            table.remove(raven_prophet_list, 1)
        else
            weight_list[index] = 0.0
        end
    end

    local info_list = {}
    for k, item in ipairs(raven_prophet_list) do
        table.insert(info_list, item)
        if (item.id == 8) then break end
    end

    raven_prophet_list = info_list

    player_game_info.raven_prophet_str = json.encode(raven_prophet_list)
    content = raven_prophet_list
    return content
end

PropetPickFinish = function(task, player, game_room_config, parameter,
                            player_game_info, game_type)
    local content = {}
    local LineNum = GetLinesNum()
    local raven_prophet_list = json.decode(player_game_info.raven_prophet_str)
    if (#raven_prophet_list == 0) then return response end

    local win_chip = 0
    for k, item in ipairs(raven_prophet_list) do
        if (item.id ~= 8) then
            local amount = player_game_info.bet_amount
            win_chip = win_chip + amount * LineNum * item.Bonus
        else
            break
        end
    end

    player_game_info.raven_prophet_str = "[]"
    content.win_chip = win_chip
    player_game_info.bonus_game_type = 0
    return content
end

IsBonusGame = function(game_room_config, player, player_game_info)
    if (player_game_info.bonus_game_type > 0) then return true end
    return false
end

-- 获取连线数
GetLinesNum = function() return #IceAndFireLineArray.Lines1 end
