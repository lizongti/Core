require "Common/SlotsGameCalculate"     --重写的接口
require "Common/SlotsGameCal"           --旧的接口
require "Common/LineNum"

SlotsDancingDrumsSpin = {}

-------此玩法特色信息的初始化
local InitExternInfo = function(game_room_config, jackpot_config, save_data)
    if (save_data.jackpot == nil) then
        save_data.jackpot = {}
        for k, sub_config in pairs(jackpot_config) do
            save_data.jackpot[sub_config.id] = 0
        end
    end
end

---获取jackpot奖池信息
local AddJacpotPool = function(session, game_room_config, pre_action_list, amount, save_data, wild_count, is_free_spin, lines_num, player_game_info)
    local player = session.player
    local type = _G[game_room_config.game_name.."TypeArray"].Types

    local config_table = SlotsGameCal.Calculate.GetMapConfigTable(session, game_room_config, player_game_info, amount * lines_num)

    local jackpot_config = CommonCal.Calculate.get_config(player, config_table.Jackpot_config)


    InitExternInfo(game_room_config, jackpot_config, save_data)

    local jackpot_win_chip = 0
    save_data.bonus_win_index = 0

    local jackpot_pool = {}
    for k, v in ipairs(jackpot_config) do
        local add_value = save_data.jackpot[v.id]
        save_data.jackpot[v.id] = save_data.jackpot[v.id] + v.bet_to_chip_percent * amount * lines_num
        table.insert(jackpot_pool, {base_payrate = v.start_point, add_value = add_value})
    end

    local cur_jacpot_conf = nil
    if (wild_count > 0) then

        local random_tab = {}
        local not_win_probality = 1
        for i = 1, #jackpot_config do
            local probability_value = jackpot_config[i].Winning_probability
            if (GlobalSlotsTest[player.id] ~= nil) then
                if (GlobalSlotsTest[player.id].flag == 1) then
                    probability_value = 0.25
                end
            end
            table.insert(random_tab, probability_value)
            not_win_probality = not_win_probality - probability_value
        end
        if (not_win_probality < 0) then
            not_win_probality = 0
        end
        table.insert(random_tab, not_win_probality)
        local win_index = math.rand_weight(player, random_tab)
        cur_jacpot_conf = jackpot_config[win_index]
    end
    if (cur_jacpot_conf ~= nil) then---触发jackpot
        jackpot_win_chip = cur_jacpot_conf.start_point * amount * lines_num + save_data.jackpot[cur_jacpot_conf.id]
        save_data.jackpot[cur_jacpot_conf.id] = 0
    
        save_data.bonus_win_chip = jackpot_win_chip
        save_data.bonus_win_index = cur_jacpot_conf.id
        save_data.is_free_spin = is_free_spin and 1 or 0
        local pre_action = {}
        pre_action.action_type = ActionType.ActionTypes.EnterBonus
        table.insert(pre_action_list, pre_action)

        local pre_action = {}
        pre_action.action_type = ActionType.ActionTypes.GameJackpotPool
        pre_action.jackpot_pool = jackpot_pool
        table.insert(pre_action_list, pre_action)
    end
    return jackpot_win_chip
end

local GetJackpotInfo = function(session, game_room_config, save_data, pre_action_list, player_game_info, amount)
    local player = session.player
    local lineNum = LineNum[player_game_info.game_type]()
    local config_table = SlotsGameCal.Calculate.GetMapConfigTable(session, game_room_config, player_game_info, amount * lineNum)

    local jackpot_config = CommonCal.Calculate.get_config(player, config_table.Jackpot_config)

    InitExternInfo(game_room_config, jackpot_config, save_data)
    local jackpot_pool = {}
    for k, v in ipairs(jackpot_config) do
        local add_value = save_data.jackpot[v.id]

        table.insert(jackpot_pool, {base_payrate = v.start_point, add_value = add_value})
    end

    local pre_action = {}
    pre_action.action_type = ActionType.ActionTypes.GameJackpotPool
    pre_action.jackpot_pool = jackpot_pool
    table.insert(pre_action_list, pre_action)
end

function SlotsDancingDrumsSpin:Enter()
    local task = self.parameters.task
    local player = self.parameters.player
    local game_room_config = self.parameters.game_room_config
    local player_game_info = self.parameters.player_game_info
    local player_game_status = self.parameters.player_game_status
    local session = self.parameters.session

    local bonus_info = {}
    
    local save_data = player_game_info.save_data
    if (save_data.bonus_win_index ~= nil and save_data.bonus_win_index > 0) then
        bonus_info.bonus_game = true
    end

    if (save_data.collect_count == nil) then
        save_data.collect_count = 0
    end

    local collect_status_conf = CommonCal.Calculate.get_config(player, game_room_config.game_name.."CollectStatusConfig")
    if (save_data.collect_count <= collect_status_conf[1].count) then
        save_data.pot_status = 0
    elseif (save_data.collect_count <= collect_status_conf[2].count) then
        save_data.pot_status = 1
    else
        save_data.pot_status = 2
    end

    if (save_data.pot_status == nil) then
        bonus_info.pot_status = 0
    else
        bonus_info.pot_status = save_data.pot_status
    end

    local pre_action_list = {}
    GetJackpotInfo(session, game_room_config, save_data, pre_action_list, player_game_info, player_game_info.bet_amount)

    bonus_info.pre_action_list = pre_action_list

    return bonus_info
end

function SlotsDancingDrumsSpin:NormalSpin()
    local player = self.parameters.player
    local player_game_info = self.parameters.player_game_info
    local is_free_spin = self.parameters.is_free_spin
    local game_room_config = self.parameters.game_room_config
    local player_game_status = self.parameters.player_game_status
    local amount = self.parameters.amount
    local game_type = self.parameters.game_type
    local player_feature_condition = self.parameters.player_feature_condition
    local extern_param = self.parameters.extern_param

    LOG(RUN, INFO).Format("[SlotsDancingDrums][Sping] begin player id %s", player.id)

    local save_data = player_game_info.save_data

    local lineNum = LineNum[player_game_info.game_type]()

    local config_table = SlotsGameCal.Calculate.GetMapConfigTable(extern_param.session, game_room_config, player_game_info, lineNum * amount)

    local reel_file = nil
    local weight_file = nil
    if is_free_spin then
        reel_file = config_table.feature_reel_config
        weight_file = config_table.feature_reel_weight_config
    else
        reel_file = config_table.base_reel_config
        weight_file = config_table.base_reel_weight_config
    end
    -- print("level is:", player.character.level)
    -- print("reel file is:", reel_file)

    ---这些是玩法开发用到的东西，直接复制吧---
    local total_win_chip, free_spin_bouts, slots_win_chip = 0, 0, 0
    local result_row ={}
    local all_prize_list={}

    local formation_list={}
    local reel_file_name = reel_file

    local type = _G[game_room_config.game_name.."TypeArray"].Types

    if (save_data.total_free_spin_times == nil or not is_free_spin) then
        save_data.total_free_spin_times = 0
    end

    if (is_free_spin) then
        save_data.total_free_spin_times = save_data.total_free_spin_times + 1
    end
    ---------------------------------------

    -- result_row, reel_file_name = SlotsGameCal.Calculate.GenItemResult(player, game_room_config.game_type, is_free_spin, game_room_config, reel_file)
    result_row = SlotsGameCal.Calculate.GenItemResultWithWeight(player, game_room_config.game_type, is_free_spin, game_room_config, reel_file, weight_file)

    local final_result = table.DeepCopy(result_row)
    --计算大奖哦
    local left_or_right = game_room_config.direction_type
    local payrate_file = CommonCal.Calculate.get_config(player, game_room_config.game_name.."PayrateConfig")

    local other_file = CommonCal.Calculate.get_config(player, game_room_config.game_name.."OthersConfig")
    local prize_items, pos_list, total_payrate, total_line_count = GenReelWayPrizeInfo(final_result, game_room_config, payrate_file, other_file[1].Base_Bet_Ratio)
    --SlotsGameCal.Calculate.GenPrizeInfo(final_result, game_room_config, payrate_file, left_or_right, type, nil, nil, other_file[1].Base_Bet_Ratio)
    table.insert(all_prize_list, prize_items)

    --FreeSpin判断处理
    local cols = {1, 3, 5}
    --if (is_free_spin) then
    --    cols = {1, 2, 3, 4, 5}
    --end
    local free_spin_bouts =  SlotsGameCal.Calculate.FreeSpinCheck(player, final_result, game_room_config, is_free_spin, type.Scatter)
    if free_spin_bouts > 0 then
        GameStatusCal.Calculate.AddGameStatus(player_game_status, GameStatusDefine.AllTypes.FreeSpinGame, free_spin_bouts, 1, amount)
    end   
    if (not is_free_spin) then
        if (free_spin_bouts > 0) then
            save_data.trigger_free_count = 1
        else
            save_data.trigger_free_count = 0
        end
    else
        if (free_spin_bouts > 0) then
            save_data.trigger_free_count = save_data.trigger_free_count + 1

            player_game_info.free_spin_num = free_spin_bouts----客户端弹出对话框后才加free spin次数
            
        end
    end

    --基础奖金
    slots_win_chip = total_payrate * amount
    total_win_chip = slots_win_chip

    local slots_spin_list = {}
    local pre_action_list = {}

    ---------获取wild个数
    LOG(RUN, INFO).Format("[SlotsDancingDrums][Spin]777 end player id %s", player.id)
    local wild_pos_list = SlotsGameCal.Calculate.GetItemPosition(result_row, game_room_config, type.Wild, cur_formation)
    LOG(RUN, INFO).Format("[SlotsDancingDrums][Spin]888 end player id %s, wild_pos_list is: %s", player.id, Table2Str(wild_pos_list))
    save_data.bonus_win_index = nil
    if (save_data.collect_count == nil) then
        save_data.collect_count = 0
    end

    if (save_data.pot_status == nil) then
        save_data.pot_status = 0
    end

    if (not is_free_spin) then
        AddJacpotPool(extern_param.session, game_room_config, pre_action_list, amount, save_data, #wild_pos_list, is_free_spin, lineNum, player_game_info)
    end
    GetJackpotInfo(extern_param.session, game_room_config, save_data, pre_action_list, player_game_info, amount)
    if (#wild_pos_list > 0) then

        table.insert(pre_action_list, {
            action_type = ActionType.ActionTypes.WildEffect,
            parameter_list={[1]=
            {
                positions = wild_pos_list
            }}
        })   
        
        local collect_status_conf = CommonCal.Calculate.get_config(player, game_room_config.game_name.."CollectStatusConfig")
        if (save_data.collect_count <= collect_status_conf[1].count) then
            save_data.pot_status = 0
        elseif (save_data.collect_count <= collect_status_conf[2].count) then
            save_data.pot_status = 1
        else
            save_data.pot_status = 2
        end

        save_data.collect_count = save_data.collect_count + 1
    end

    table.insert(pre_action_list,{
        action_type = ActionType.ActionTypes.DacingDrumsPotStatus,
        parameter_list={[1]=
        {
            pot_status = save_data.pot_status
        }}
    })

    if (free_spin_bouts > 0) then
        table.insert(pre_action_list,{
            action_type = ActionType.ActionTypes.TriggerFreeSpin,
            trigger_free_count = save_data.trigger_free_count,---0没有对话框，1弹出对话框让玩家选择，大于1弹出对话框告诉玩家免费次数叠加
            free_spin_bouts = free_spin_bouts,
            pos = SlotsGameCal.Calculate.GetItemPosition(final_result, game_room_config, type.Scatter)
        })
    end

    local reel_ways_info = {}
    reel_ways_info.pos_list = pos_list
    reel_ways_info.total_line_count = total_line_count

    --print("result_row2 is:", json.encode(final_result))
    table.insert(slots_spin_list, {
        item_ids = json.encode(SlotsGameCal.Calculate.TransResultToCList(result_row, game_room_config)),
        prize_items = prize_items,
        win_chip = total_win_chip,
        pre_action_list =  json.encode(pre_action_list),
        final_item_ids = json.encode(SlotsGameCal.Calculate.TransResultToCList(final_result, game_room_config)),   
        reel_ways_info = json.encode(reel_ways_info),
        ways_type = 1,
    })
    table.insert(formation_list, {
        slots_spin_list=slots_spin_list,
        id = 1,
    })

    LOG(RUN, INFO).Format("[SlotsDancingDrums][Sping] end player id %s", player.id)

    local result = {}
    result.final_result = final_result --结果数组
    result.total_win_chip = total_win_chip  --总奖金
    result.all_prize_list = all_prize_list --所有连线列表
    result.free_spin_bouts = free_spin_bouts --freespin的次数
    result.formation_list = formation_list --阵型列表
    result.reel_file_name = reel_file_name --reel表名
    result.slots_win_chip = slots_win_chip --总奖励
    result.special_parameter = special_parameter --其他参数，主要给模拟器传参

    return result
end

-----------------------------------------------
-- Bonus Game
-----------------------------------------------
function SlotsDancingDrumsSpin:DancingDrumsBonusStart()
    local player_game_status = self.parameters.player_game_status
    local player = self.parameters.player
    local game_room_config = self.parameters.game_room_config
    local parameter = json.decode(self.parameters.parameter)
    local player_game_info = self.parameters.player_game_info
    local game_type = self.parameters.game_type
    local session = self.parameters.session

    local content = {}
    local save_data = player_game_info.save_data

    if (save_data.bonus_win_index == nil) then
        content.bonus_win_chip = 0
        return content
    end
    
    local pick_count = math.random_ext(player, 1, 8)

    local award_bonus_item_list = {}
    local free_bonus_item_list = {}
    local bonus_item_list = {}

    local lineNum = LineNum[player_game_info.game_type]()
    local config_table = SlotsGameCal.Calculate.GetMapConfigTable(session, game_room_config, player_game_info, player_game_info.bet_amount * lineNum)

    local jackpot_file = CommonCal.Calculate.get_config(player, config_table.Jackpot_config)
    if (save_data.bonus_win_index > 0) then

        --save_data.bonus_win_chip = jackpot_file[save_data.bonus_win_index].start_point * player_game_info.bet_amount * lineNum

        for i = 1, 3, 1 do
            table.insert(award_bonus_item_list, save_data.bonus_win_index)
        end

        for item_id = 1, #jackpot_file, 1 do
            if (item_id ~= save_data.bonus_win_index) then
                local count = math.random_ext(player, 1, 2)
                for i = 1, count, 1 do
                    table.insert(free_bonus_item_list, item_id)
                end
            end
        end
    end

    free_bonus_item_list = math.rand_table(player, free_bonus_item_list)
    
    local min_pick_count = math.random_ext(player, 2, #free_bonus_item_list)
    for item_index = min_pick_count + 1, #free_bonus_item_list, 1 do
        table.insert(award_bonus_item_list, free_bonus_item_list[item_index])
    end

    award_bonus_item_list = math.rand_table(player, award_bonus_item_list)

    for item_index = 1, min_pick_count, 1 do
        table.insert(bonus_item_list, free_bonus_item_list[item_index])
    end

    for item_index = 1, #award_bonus_item_list, 1 do
        table.insert(bonus_item_list, award_bonus_item_list[item_index])
    end

    LOG(RUN, INFO).Format("[SlotsDancingDrums][Sping] player id %s, free_bonus_item_list is:%s", player.id, Table2Str(free_bonus_item_list))

    LOG(RUN, INFO).Format("[SlotsDancingDrums][Sping] player id %s, award_bonus_item_list is:%s", player.id, Table2Str(award_bonus_item_list))

    LOG(RUN, INFO).Format("[SlotsDancingDrums][Sping] player id %s, bonus_item_list is:%s", player.id, Table2Str(bonus_item_list))

    content.pick_list = bonus_item_list

    content.bonus_win_chip = save_data.bonus_win_chip

    content.jacpot_type = save_data.bonus_win_index

    content.is_free_spin = save_data.is_free_spin

    if (save_data.last_bonus ~= nil) then
        content = save_data.last_bonus
    end

    if GlobalSlotsTest[player.id] ~= nil and GlobalSlotsTest[player.id].bonus ~= nil then
        content = GlobalSlotsTest[player.id].bonus
    end

    save_data.last_bonus = content
    
    local bet_amount = player_game_info.bet_amount
    
    content.now = bet_amount * lineNum

    return content
end

function SlotsDancingDrumsSpin:DancingDrumsBonusFinish()
    local player_game_status = self.parameters.player_game_status
    local player = self.parameters.player
    local game_room_config = self.parameters.game_room_config
    local parameter = json.decode(self.parameters.parameter)
    local player_game_info = self.parameters.player_game_info
    local game_type = self.parameters.game_type
    local session = self.parameters.session

    local content = {}

    local save_data = player_game_info.save_data
    if (save_data.bonus_win_index == nil) then
        return content
    end

    content.win_chip = save_data.bonus_win_chip
    content.is_free_spin = 0
    if (save_data.is_free_spin == 1) then
        player_game_info.free_total_win = player_game_info.free_total_win + save_data.bonus_win_chip

        content.free_total_win = player_game_info.free_total_win
        content.is_free_spin = save_data.is_free_spin
    end

    save_data.bonus_win_index = nil

    save_data.last_bonus = nil

    save_data.pot_status = 0
    save_data.collect_count = 0

    FeverQuestCal.OnMiniGameEnd(session, game_type, content.win_chip)

    return content
end