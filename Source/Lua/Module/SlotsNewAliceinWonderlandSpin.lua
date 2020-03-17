require "Common/SlotsGameCalculate"     --重写的接口
require "Common/SlotsGameCal"           --旧的接口
require "Module/SlotsBaseSpin"
require "Common/SlotsAliceinWonderlandCal"
SlotsNewAliceinWonderlandSpin = {}

----替换Super Stack Star元素
function SlotsNewAliceinWonderlandSpin:GenSuperStackStar()
    local player = self.parameters.player
    local formation_id= self.parameters.formation_id
    local result_row = self.parameters.result_row_list[formation_id]
    local formation_name = self.parameters.formation_name
    local player_game_info = self.parameters.player_game_info
    local game_room_config = self.parameters.game_room_config

    local type = _G[game_room_config.game_name.."TypeArray"].Types
 
    ----替换Super Stack元素
    local super_stack_pos_list = SlotsGameCal.Calculate.GetItemPosition(result_row, game_room_config, type.SuperStack, formation_name)
 
    if #super_stack_pos_list > 0 then
        local save_data = player_game_info.save_data
        for k,v in ipairs(super_stack_pos_list) do
            result_row[v.row][v.col] = save_data.super_stack_replace_item_id
        end
    end
end

function SlotsNewAliceinWonderlandSpin:ReplaceSuperStackStar()
    local player = self.parameters.player
    local game_room_config = self.parameters.game_room_config
    local player_game_info = self.parameters.player_game_info
    local save_data = player_game_info.save_data
    local formation_id= self.parameters.formation_id
    local pre_action_list = self.parameters.all_pre_action_list[formation_id]
    local type = _G[game_room_config.game_name.."TypeArray"].Types
    --SuperStack替换
    local super_stack_config = {}

    super_stack_config = CommonCal.Calculate.get_config(player, game_room_config.game_name .. "SuperStackConfig")
 
    save_data.super_stack_replace_item_id = SlotsGameCal.Calculate.SuperStackReplace(player, nil, game_room_config, type.SuperStack, super_stack_config)

    local pre_action = {}
    pre_action.action_type = ActionType.ActionTypes.SuperStackReplaceItemId 
    pre_action.super_stack_replace_item_id = save_data.super_stack_replace_item_id or 0
    table.insert(pre_action_list, pre_action)
end

function SlotsNewAliceinWonderlandSpin:TriggerFreeSpin()
    local player_game_info = self.parameters.player_game_info
    local player_game_status = self.parameters.player_game_status
    local formation_id = self.parameters.formation_id
    local formation_name = self.parameters.formation_name
    local pre_action_list = self.parameters.all_pre_action_list[formation_id]

    local final_result = self.parameters.final_result_list[formation_id]---这个只会在GenItemResult执行后出现
    local game_room_config = self.parameters.game_room_config
    local type = _G[game_room_config.game_name.."TypeArray"].Types

    local amount = self.parameters.amount

    local save_data = player_game_info.save_data

    local cur_status = GameStatusCal.Calculate.GetGameStatus(player_game_status)
    local is_in_free_spin = (cur_status == GameStatusDefine.AllTypes.FreeSpinGame) and true or false
    if (cur_status == GameStatusDefine.AllTypes.ReSpinGame) then
        local parent_status = GameStatusCal.Calculate.GetParentStatus(player_game_status, cur_status)
        is_in_free_spin = (parent_status == GameStatusDefine.AllTypes.FreeSpinGame) and true or false
    end

    ---触发freespin
    local free_spin_bouts =  SlotsGameCal.Calculate.FreeSpinCheck(player, final_result, game_room_config, is_in_free_spin, type.Scatter)   

    if (free_spin_bouts > 0) then
        if (save_data.trigger_free_count == nil) then
            save_data.trigger_free_count = 0
        end
        if (not is_in_free_spin) then
            save_data.trigger_free_count = 0
        else
            save_data.trigger_free_count = save_data.trigger_free_count + 1
        end

        local cur_status = GameStatusCal.Calculate.GetGameStatus(player_game_status)
        local action_info = {
            action_type = ActionType.ActionTypes.TriggerFreeSpin,
            trigger_free_count = save_data.trigger_free_count,---0第一次触发，大于0表示是在free spin中触发
            free_spin_bouts = free_spin_bouts,
            pos = SlotsGameCal.Calculate.GetItemPosition(result_row, game_room_config, type.Scatter)
        }

        if (cur_status == GameStatusDefine.AllTypes.FreeSpinGame) then
            table.insert(pre_action_list, action_info)
        else
            SlotsGameCal.Calculate.AddActionLater(player_game_info, action_info, {"free_spin_bouts"})
        end
        
        GameStatusCal.Calculate.AddGameStatus(player_game_status, GameStatusDefine.AllTypes.FreeSpinGame, free_spin_bouts, 1, amount)
    end
end

function SlotsNewAliceinWonderlandSpin:GenItemResult()
    local player = self.parameters.player
    local game_type = self.parameters.game_type

    local session = self.parameters.session

    local game_room_config = self.parameters.game_room_config
    local amount = self.parameters.amount
    local player_feature_condition = self.parameters.player_feature_condition
    local extern_param = self.parameters.extern_param
    local player_game_info = self.parameters.player_game_info
    local line_id = self.parameters.line_id
    local formation_id= self.parameters.formation_id
    local formation_name = self.parameters.formation_name
    local reel_file_name = self.parameters.reel_file_name
    local player_game_status = self.parameters.player_game_status
    local formation_list = self.parameters.formation_list
    local pre_action_list = self.parameters.all_pre_action_list[formation_id]
    local type = _G[game_room_config.game_name.."TypeArray"].Types
    local save_data = player_game_info.save_data

    local cur_status = GameStatusCal.Calculate.GetGameStatus(player_game_status)

    local is_in_free_spin = (cur_status == GameStatusDefine.AllTypes.FreeSpinGame) and true or false
    if (cur_status == GameStatusDefine.AllTypes.ReSpinGame) then
        local parent_status = GameStatusCal.Calculate.GetParentStatus(player_game_status, cur_status)
        is_in_free_spin = (parent_status == GameStatusDefine.AllTypes.FreeSpinGame) and true or false
    end

    local total_win_chip, free_spin_bouts, slots_win_chip = 0, 0, 0
    

    local lines_num = LineNum[game_type]()

    
    local new_wild = {}

    local config_table = SlotsGameCal.Calculate.GetMapConfigTable(session, game_room_config, player_game_info, amount * lines_num)
    local reel_file_name = nil
    local weight_file = nil

    if is_in_free_spin then
        reel_file_name = "NewAliceinWonderlandFeatureReelConfig"
        weight_file = config_table.feature_reel_weight_config
    else
        reel_file_name = "NewAliceinWonderlandBaseReelConfig"
        weight_file = config_table.base_reel_weight_config
    end

    self.parameters.result_row_list[formation_id] = SlotsGameCal.Calculate.GenItemResultWithWeight(player, game_room_config.game_type, is_in_free_spin, game_room_config, reel_file_name, weight_file)
    ----替换元素
    self:GenSuperStackStar()

    ----如果出现wild，就加一个action
    local wild_pos_list = SlotsGameCal.Calculate.GetItemPosition(self.parameters.result_row_list[formation_id], game_room_config, type.Wild, formation_name)

    if (save_data.pre_action_list == nil) then
        save_data.pre_action_list = {}
    end
    for wild_k, wild_v in pairs(wild_pos_list) do
        local is_exist = false
        for k, v in pairs(save_data.pre_action_list) do
            local action_info = v
            if (action_info.action_type == ActionType.ActionTypes.WildEffect) then
                local wild_pos_list = action_info.wild_pos_list
                for pos_k, pos_v in pairs(wild_pos_list) do
                    if (pos_v.col == wild_v.col) then
                        is_exist = true
                        break                        
                    end
                end
            end
        end
        if (not is_exist) then
            table.insert(new_wild, wild_v)
        end
    end

    if #new_wild > 0 then
        local action_info = {
            action_type = ActionType.ActionTypes.WildEffect,
            wild_pos_list = new_wild,
        }
        table.insert(save_data.pre_action_list, action_info)
        table.insert(pre_action_list, action_info)
    end

    self.parameters.final_result_list[formation_id] = table.DeepCopy(self.parameters.result_row_list[formation_id])

    ----如果出现wild，就将那一列变为wild
    for k, v in pairs(save_data.pre_action_list) do
        local action_info = v
        if (action_info.action_type == ActionType.ActionTypes.WildEffect) then
            local wild_pos_list = action_info.wild_pos_list
            for pos_k, pos_v in pairs(wild_pos_list) do
                self.parameters.final_result_list[formation_id][1][pos_v.col] = type.Wild
                self.parameters.final_result_list[formation_id][2][pos_v.col] = type.Wild
                self.parameters.final_result_list[formation_id][3][pos_v.col] = type.Wild
            end
        end
    end

    LOG(RUN, INFO).Format("[SlotsNewAliceinWonderlandSpin][NormalSpin] player:%s, final row1 is:%s", player.id, Table2Str(self.parameters.final_result_list[formation_id]))

    local pos_list = SlotsGameCal.Calculate.GetItemPosition(self.parameters.final_result_list[formation_id], game_room_config, type.Bonus, formation_name)
    if (#pos_list >= 3 and save_data.is_bonus == 0) then
        save_data.is_bonus = 1
    end

    if #new_wild > 0 then
        GameStatusCal.Calculate.AddGameStatus(player_game_status, GameStatusDefine.AllTypes.ReSpinGame, 1, 0, amount)
    elseif (save_data.is_bonus == 1) then
        LOG(RUN, INFO).Format("[SlotsNewAliceinWonderland][NewAliceinWonderlandBonusStart] player id is:%s, save_data.is_bonus is 1", player.id)
        local pre_action = {}
        pre_action.action_type = ActionType.ActionTypes.EnterBonus
        
        local cur_status = GameStatusCal.Calculate.GetGameStatus(player_game_status)

        if (cur_status == GameStatusDefine.AllTypes.FreeSpinGame) then
            table.insert(pre_action_list, pre_action)

        else
            SlotsGameCal.Calculate.AddActionLater(player_game_info, pre_action)
        end

        if (save_data.bonus_info == nil) then
            save_data.bonus_info = {}
        end
    
        save_data.bonus_info.bonus_type = 1
    end
    

    self.parameters.reel_file_name = reel_file_name

end

function SlotsNewAliceinWonderlandSpin:GenPrizeInfo()
    local player = self.parameters.player
    local game_type = self.parameters.game_type

    local game_room_config = self.parameters.game_room_config
    local formation_id = self.parameters.formation_id
    local formation_name = self.parameters.formation_name
    local amount = self.parameters.amount
    local player_feature_condition = self.parameters.player_feature_condition
    local extern_param = self.parameters.extern_param
    local player_game_info = self.parameters.player_game_info
    local final_result = self.parameters.final_result_list[formation_id]
    local reel_file_name = self.parameters.reel_file_name

    local line_id = self.parameters.line_id
    local player_game_status = self.parameters.player_game_status

    local type = _G[game_room_config.game_name.."TypeArray"].Types
    --计算大奖哦
    local left_or_right = game_room_config.direction_type
    local payrate_file = CommonCal.Calculate.get_config(player, game_room_config.game_name.."PayrateConfig")

    local other_file = CommonCal.Calculate.get_config(player, game_room_config.game_name.."OthersConfig")

    local cur_status = GameStatusCal.Calculate.GetGameStatus(player_game_status)
    local is_in_free_spin = (cur_status == GameStatusDefine.AllTypes.FreeSpinGame) and true or false
    if (cur_status == GameStatusDefine.AllTypes.ReSpinGame) then
        local parent_status = GameStatusCal.Calculate.GetParentStatus(player_game_status, cur_status)
        is_in_free_spin = (parent_status == GameStatusDefine.AllTypes.FreeSpinGame) and true or false
    end

    local prize_items, total_payrate = SlotsGameCal.Calculate.GenPrizeInfoAli(final_result, game_room_config, payrate_file, left_or_right, type, formation_name, line_id, other_file[1].Base_Bet_Ratio, is_in_free_spin)

    table.insert(self.parameters.all_prize_list, prize_items)

    local slots_win_chip = total_payrate * amount

    local total_win_chip = slots_win_chip
    self.parameters.prize_items_list[formation_id] = prize_items
    self.parameters.slots_win_chip_list[formation_id] = slots_win_chip
    self.parameters.total_win_chip_list[formation_id] = total_win_chip
end

function SlotsNewAliceinWonderlandSpin:NormalSpin()
    local player_game_info = self.parameters.player_game_info
    local special_parameter = self.parameters.special_parameter

    local game_room_config = self.parameters.game_room_config
    local player_game_status = self.parameters.player_game_status
    local amount = self.parameters.amount
    local player = self.parameters.player

    local save_data = player_game_info.save_data

    LOG(RUN, INFO).Format("[SlotsNewAliceinWonderlandSpin][NormalSpin] begin")

    local cur_status = GameStatusCal.Calculate.GetGameStatus(player_game_status)

    local is_in_free_spin = (cur_status == GameStatusDefine.AllTypes.FreeSpinGame) and true or false
    if (cur_status == GameStatusDefine.AllTypes.ReSpinGame) then
        
        local parent_status = GameStatusCal.Calculate.GetParentStatus(player_game_status, cur_status)
        is_in_free_spin = (parent_status == GameStatusDefine.AllTypes.FreeSpinGame) and true or false

        local total_count = GameStatusCal.Calculate.GetTotalRespinNum(player_game_status)
        if (total_count > 5) then
            LOG(RUN, INFO).Format("[SlotsNewAliceinWonderland][NewAliceinWonderlandBonusStart] player id is:%s, respin total count is：%s", player.id, total_count)
        end
    end

    if (cur_status ~= GameStatusDefine.AllTypes.ReSpinGame) then
        save_data.pre_action_list = {}
    end

    if (cur_status == GameStatusDefine.AllTypes.BaseSpinGame or cur_status == GameStatusDefine.AllTypes.FreeSpinGame) then
        save_data.is_bonus = 0
        LOG(RUN, INFO).Format("[SlotsNewAliceinWonderland][NewAliceinWonderlandBonusStart] player id is:%s, save_data.is_bonus is 0", player.id)
    end

    if (is_in_free_spin) then
        LOG(RUN, INFO).Format("[SlotsNewAliceinWonderlandSpin][NormalSpin] this is freespin")
    else
        LOG(RUN, INFO).Format("[SlotsNewAliceinWonderlandSpin][NormalSpin] this is normalspin")
    end

    if (save_data.total_free_spin_times == nil) then
        save_data.total_free_spin_times = 0
    end
    if (is_in_free_spin) then
        save_data.total_free_spin_times = save_data.total_free_spin_times + 1
    else
        save_data.total_free_spin_times = 0
    end

    if is_in_free_spin then 
        self.parameters.reel_file_name = game_room_config.game_name .. "FeatureReelConfig"
    else
        self.parameters.reel_file_name = game_room_config.game_name .. "BaseReelConfig"
    end

    ----转出元素
    self:GenItemResult()

    self:TriggerFreeSpin()

    ----计算大奖
    self:GenPrizeInfo()

    self:ReplaceSuperStackStar()

    ----将奖励信息，阵型信息，连线信息，action信息都封装到slots_spin_list中
    self:ApplySlotsSpinList()
    
    return self:GenWinInfo()
end

function SlotsNewAliceinWonderlandSpin:Enter()
    LOG(RUN, INFO).Format("[SlotsNewAliceinWonderland][Enter] begin")
    local task = self.parameters.task
    local player = self.parameters.player
    local game_room_config = self.parameters.game_room_config
    local player_game_info = self.parameters.player_game_info
    local player_game_status = self.parameters.player_game_status
    local total_classic_count = 0

    local save_data = player_game_info.save_data
    if (save_data.bonus_info == nil) then
        save_data.bonus_info = {}
    end

    ----------Super stack 特性------------
    local type = _G[game_room_config.game_name.."TypeArray"].Types
    local super_stack_config = CommonCal.Calculate.get_config(player, game_room_config.game_name .. "SuperStackConfig")
    if not save_data.super_stack_replace_item_id or save_data.super_stack_replace_item_id <= 0 then
        local super_stack_replace_item_id = SlotsGameCal.Calculate.SuperStackReplace(player, nil, game_room_config, type.SuperStack, super_stack_config)
        save_data.super_stack_replace_item_id = super_stack_replace_item_id
    end
    LOG(RUN, INFO).Format("[SlotsNewAliceinWonderland][Enter] end")
    
    local content = {}
    content.super_stack_replace_item_id = save_data.super_stack_replace_item_id
    if (save_data.bonus_info.bonus_type ~= nil) then
        content.bonus_type = save_data.bonus_info.bonus_type
    else
        content.bonus_type = 0
    end
    LOG(RUN, INFO).Format("[SlotsNewAliceinWonderland][Enter] content is:%s", json.encode(content))
    return content
end

function SlotsNewAliceinWonderlandSpin:NewAliceinWonderlandBonusStart()
    local player_game_status = self.parameters.player_game_status
    local player = self.parameters.player
    local game_room_config = self.parameters.game_room_config
    local parameter = self.parameters.parameter
    local player_game_info = self.parameters.player_game_info
    local game_type = self.parameters.game_type

    local save_data = player_game_info.save_data

    LOG(RUN, INFO).Format("[SlotsNewAliceinWonderland][NewAliceinWonderlandBonusStart] player id is:%s", player.id)

    if (save_data.is_bonus == nil or save_data.is_bonus == 0) then
        LOG(RUN, INFO).Format("[SlotsNewAliceinWonderland][NewAliceinWonderlandBonusStart] player id is:%s, save_data.is_bonus is 0", player.id)
        return content
    end

    local pick_bonus_config = CommonCal.Calculate.get_config(player, game_room_config.game_name .. "PickBonusConfig")

    local rose_bonus_config = CommonCal.Calculate.get_config(player, game_room_config.game_name .. "RoseBonusConfig")

    local round_value = 5

    local round_info_list = {}
    for round = 1, round_value, 1 do
        -----每局信息-----------
        local config_list = {}
        local local_weight_tab = {}

        for k, v in ipairs(pick_bonus_config) do
            if (v.Round == round) then
                table.insert(config_list, v)
            end
        end

        for k, v in ipairs(config_list)
        do
           local_weight_tab[k] = v.Probability
        end
        local local_index = math.rand_weight(player, local_weight_tab)	

        local round_info = {}
        for k, v in ipairs(config_list) do
            if (k == local_index) then
                table.insert(round_info, {bonus = v.Bonus, is_sel = 1})
            else
                table.insert(round_info, {bonus = v.Bonus, is_sel = 0})
            end
        end
        
        table.insert(round_info_list, round_info)
    end

    save_data.bonus_info.round_info_list = round_info_list
    
    local rose_weight_tab = {}

    for k, v in ipairs(rose_bonus_config)
    do
        rose_weight_tab[k] = v.Probability
    end
    local rose_index = math.rand_weight(player, rose_weight_tab)	

    local rose_info = {}
    for k, v in ipairs(rose_bonus_config) do
        if (k == rose_index) then
            table.insert(rose_info, {bonus = v.Bonus, is_sel = 1})
        else
            table.insert(rose_info, {bonus = v.Bonus, is_sel = 0})
        end
    end

    save_data.bonus_info.rose_info = rose_info

    local content = {}
    content.bonus_info = save_data.bonus_info

    LOG(RUN, INFO).Format("[SlotsNewAliceinWonderland][NewAliceinWonderlandBonusStart] player id is:%s, content is %s", player.id, Table2Str(content))
    return content
end

function SlotsNewAliceinWonderlandSpin:NewAliceinWonderlandBonusFinish()
    local player_game_status = self.parameters.player_game_status
    local player = self.parameters.player
    local game_room_config = self.parameters.game_room_config
    local parameter = self.parameters.parameter
    local player_game_info = self.parameters.player_game_info
    local game_type = self.parameters.game_type
    local session = self.parameters.session

    local content = {}

    content.bet_amount = player_game_info.bet_amount * 25

    local save_data = player_game_info.save_data

    if (save_data.bonus_info == nil) then
        content.win_chip = 0

        return content
    end

    if (save_data.bonus_info.bonus_type == 0) then
        content.win_chip = 0

        return content
    end

    local total_bonus = 0
    for round_info_index, round_info in ipairs(save_data.bonus_info.round_info_list) do
        for detail_index, detail in ipairs(round_info) do
            if (detail.is_sel == 1) then
                total_bonus = total_bonus + detail.bonus
            end
        end
    end

    for rose_index, rose_detail in ipairs(save_data.bonus_info.rose_info) do
        if (rose_detail.is_sel == 1) then
            if (rose_detail.bonus == 0) then
                ---------------触发状态

                GameStatusCal.Calculate.AddGameStatus(player_game_status, GameStatusDefine.AllTypes.FreeSpinGame, 10, 1, player_game_info.bet_amount)
                --player_game_info.free_spin_bouts = player_game_info.free_spin_bouts + 10
                content.free_spin_bouts = 10
            else
                total_bonus = total_bonus * rose_detail.bonus
            end
        end
    end    

    content.win_chip = total_bonus *  player_game_info.bet_amount * 25
    FeverQuestCal.OnMiniGameEnd(session, game_type, content.win_chip)

    save_data.bonus_info.bonus_type = 0
    save_data.bonus_info.round_info_list = nil
    save_data.bonus_info.rose_info = nil
    return content
end