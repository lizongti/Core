require "Common/SlotsGameCalculate"     --重写的接口
require "Common/SlotsGameCal"           --旧的接口

require "Module/SlotsBaseSpin"
---require "Common/ActionType"
-- module("SlotsRapidHitSpin", package.seeall)
SlotsMagicScarabSpin = {}

local InitActionList = function(save_data, cur_status, formation_id)
    -- body
    if (save_data.pre_action_list == nil) then
        save_data.pre_action_list = {}
    end


    if (save_data.pre_action_list["formation"..formation_id] == nil) then
        save_data.pre_action_list["formation"..formation_id] = {}
    end
end

local GetRoundInfo = function(save_data, game_status, amount_index)
    for k, v in pairs(save_data.round_info["status"..game_status]) do
        if (v.amount_index == amount_index) then
            return v
        end
    end
end

local ConvertPos = function(col, row, col_num)
    local conv_pos = col + (row - 1) * col_num
    return conv_pos
end

local GetColRow = function(pos, col_num)
    local row = math.floor(pos / col_num)
    local mod = math.fmod(pos, col_num) 
    if (mod > 0) then
        row = row + 1
    end
    local col = pos - col_num * (row - 1)
    return row, col
end

local InitRoundInfo = function(save_data, cur_status, amount_index)
    if (save_data.round_info == nil) then
        save_data.round_info = {}
    end
    if (save_data.round_info["status"..cur_status] == nil) then
        save_data.round_info["status"..cur_status] = {}
    end
    local is_exist = false
    for k, v in pairs(save_data.round_info["status"..cur_status]) do
        if (v.amount_index == amount_index) then
            is_exist = true
            break
        end
    end
    if (not is_exist) then
        table.insert(save_data.round_info["status"..cur_status], {amount_index = amount_index, round = 0, max_round = 10})
    end
end

function SlotsMagicScarabSpin:TriggerFreeSpin()
    local player_game_info = self.parameters.player_game_info
    local player_game_status = self.parameters.player_game_status
    local formation_id = self.parameters.formation_id
    local formation_name = self.parameters.formation_name
    local game_type = self.parameters.game_type

    local pre_action_list = self.parameters.all_pre_action_list[formation_id]

    local result_row = self.parameters.result_row_list[formation_id]

    local game_room_config = self.parameters.game_room_config
    local type = _G[game_room_config.game_name.."TypeArray"].Types

    local amount = self.parameters.amount

    local save_data = player_game_info.save_data

    local cur_status = GameStatusCal.Calculate.GetGameStatus(player_game_status)
    local is_in_free_spin = (cur_status == GameStatusDefine.AllTypes.FreeSpinGame) and true or false

    ---触发freespin
    local free_spin_bouts =  SlotsGameCal.Calculate.FreeSpinCheck(player, result_row, game_room_config, is_in_free_spin, type.Scatter)   

    if (free_spin_bouts > 0) then
        save_data.trigger_free_count = save_data.trigger_free_count + 1

        table.insert(save_data.his_bet_amount, amount)

        if (save_data.trigger_free_count < 10) then
            save_data.spin_status = 1 ---0:normal,1:free spin,2 super free spin
        else
            
            save_data.spin_status = 2 ---0:normal,1:free spin,2 super free spin

            if (#save_data.his_bet_amount > 0) then
                local local_total_bet_amount = 0
                for k, v in pairs(save_data.his_bet_amount) do
                    local_total_bet_amount = local_total_bet_amount + v
                end
                amount = math.floor(local_total_bet_amount / #save_data.his_bet_amount)
                local lineNum = LineNum[game_type]()
                SlotsGameCal.Calculate.ChangeBetAmountInRunning(player_game_info, pre_action_list, amount,  free_spin_bouts, 0)
            end


        end
    end

    local is_super_free = 0
    if save_data.spin_status == 2 then
        is_super_free = 1
    else
        is_super_free = 0
    end

    ---此玩法在free spin中不能触发free spin
    if (free_spin_bouts > 0) then
        local cur_status = GameStatusCal.Calculate.GetGameStatus(player_game_status)
        local action_info = {
            action_type = ActionType.ActionTypes.TriggerFreeSpin,
            trigger_free_count = save_data.trigger_free_count,
            free_spin_bouts = free_spin_bouts,
            is_super_free = is_super_free,
        }

        table.insert(pre_action_list, action_info)
        ---------------触发FreeSpin状态
        GameStatusCal.Calculate.AddGameStatus(player_game_status, GameStatusDefine.AllTypes.FreeSpinGame, free_spin_bouts, 1, amount)
    end

    local action_info = {
        action_type = ActionType.ActionTypes.SuperFreeSpinInfo,
        is_super_free = is_super_free
    }
    table.insert(pre_action_list, action_info)

    if (is_super_free == 1) then
        save_data.trigger_free_count = 0
    end
end

function SlotsMagicScarabSpin:GenItemResult()
    local player = self.parameters.player
    local game_type = self.parameters.game_type

    local game_room_config = self.parameters.game_room_config
    local amount = self.parameters.amount
    local player_feature_condition = self.parameters.player_feature_condition
    local extern_param = self.parameters.extern_param
    local player_game_info = self.parameters.player_game_info
    local line_id = self.parameters.line_id
    local formation_id = self.parameters.formation_id
    local formation_name = self.parameters.formation_name
    local reel_file_name = self.parameters.reel_file_name
    local player_game_status = self.parameters.player_game_status
    local pre_action_list = self.parameters.all_pre_action_list[formation_id]
    local type = _G[game_room_config.game_name.."TypeArray"].Types
    local save_data = player_game_info.save_data

    local amount_index = CommonCal.Calculate.GetBetIndex(game_type, amount)

    -- LOG(RUN, INFO).Format("[SlotsMagicScarabSpin][GenItemResult] player:%s, amount is:%s, amount_index is:%s, formation_id is:%s", player.id, amount, amount_index, formation_id)
    local cur_status = GameStatusCal.Calculate.GetGameStatus(player_game_status)

    local total_win_chip, slots_win_chip = 0, 0

    local lines_num = LineNum[game_type]()

    local result_row = {}
    result_row = SlotsGameCal.Calculate.GenItemResultWithWeight(player, game_room_config.game_type, false, game_room_config, reel_file_name, self.parameters.weight_file)

    local final_result = SlotsGameCal.Calculate.ReplaceBlock(result_row, type.Cleopatra)
    self.parameters.result_row_list[formation_id] = SlotsGameCal.Calculate.ReplaceBlock(result_row, type.Cleopatra)
    self.parameters.final_result_list[formation_id] = final_result

    local cur_wild_pos_list = SlotsGameCal.Calculate.GetItemPosition(result_row, game_room_config, type.Wild, formation_name)

    InitActionList(save_data, cur_status, formation_id)

    local new_wild = {}
    local col_num = SlotsGameCal.Calculate.GetColNum(game_room_config, formation_name)
    for wild_k, wild_v in pairs(cur_wild_pos_list) do
        local is_exist = false
        for k, v in pairs(save_data.pre_action_list["formation"..formation_id]) do
            local action_info = v
            if (action_info.action_type == ActionType.ActionTypes.WildEffect and amount_index == action_info.amount_index) then
                local wild_pos_list = action_info.wild_pos_list
                for pos_k, pos_v in pairs(wild_pos_list) do
                    -- local row = math.floor(pos_v / col_num)
                    -- local mod = math.fmod(pos_v, col_num) 
                    -- if (mod > 0) then
                    --     row = row + 1
                    -- end
                    -- local col = pos_v - col_num * (row - 1)
                    local row, col = GetColRow(pos_v, col_num)
                    if (col == wild_v.col and row == v.row) then
                        is_exist = true
                        break                        
                    end
                end
            end
        end
        if (not is_exist) then
            local conv_pos = ConvertPos(wild_v.col, wild_v.row, col_num)
            table.insert(new_wild, conv_pos)
        end
    end
    
    if #new_wild > 0 then
        -- print("new_wild2 is:"..json.encode(new_wild))
        local action_info = {
            action_type = ActionType.ActionTypes.WildEffect,
            wild_pos_list = new_wild,
            amount_index = amount_index,
            formation_id = formation_id,
        }
        table.insert(save_data.pre_action_list["formation"..formation_id], action_info)
        table.insert(pre_action_list, action_info)
    end

    -- LOG(RUN, INFO).Format("[SlotsMagicScarabSpin][NormalSpin] player:%s, final final_result is:%s", player.id, Table2Str(final_result))

    local cur_round_info = GetRoundInfo(save_data, cur_status, amount_index)
    if (cur_round_info.round == cur_round_info.max_round) then 
        
        ---wild变为可以计算的wild
        for k, v in pairs(save_data.pre_action_list["formation"..formation_id]) do
            local action_info = v
            if (action_info.action_type == ActionType.ActionTypes.WildEffect and amount_index == action_info.amount_index) then
                local wild_pos_list = action_info.wild_pos_list
                for pos_k, pos_v in pairs(wild_pos_list) do
                    pos_v = tonumber(pos_v)
                    local row, col = GetColRow(pos_v, col_num)
                    -- LOG(RUN, INFO).Format("[SlotsMagicScarabSpin][NormalSpin] player:%s, pos_v:%s, row:%s, col:%s", player.id, pos_v, row, col)
                    final_result[row][col] = type.CWild---最终变化
                end
            end
        end
    end

    self.parameters.reel_file_name = reel_file_name
end


function SlotsMagicScarabSpin:WildFly()
    local player = self.parameters.player
    local game_type = self.parameters.game_type
    local formation_id = self.parameters.formation_id
    local formation_name = self.parameters.formation_name
    local player_game_status = self.parameters.player_game_status
    local game_room_config = self.parameters.game_room_config
    local type = _G[game_room_config.game_name.."TypeArray"].Types
    local player_game_info = self.parameters.player_game_info
    local save_data = player_game_info.save_data

    local cur_status = GameStatusCal.Calculate.GetGameStatus(player_game_status)

    if (cur_status == GameStatusDefine.AllTypes.BaseSpinGame) then
        return
    end

    local amount = self.parameters.amount
    local amount_index = CommonCal.Calculate.GetBetIndex(game_type, amount)

    local col_num = SlotsGameCal.Calculate.GetColNum(game_room_config, formation_name)

    for id = self.parameters.start_id, self.parameters.end_id, 1 do
        local cur_id = id
        InitActionList(save_data, cur_status, cur_id)
        local result_row = self.parameters.result_row_list[cur_id]
        local final_result = self.parameters.final_result_list[cur_id]
        local pre_action_list = self.parameters.all_pre_action_list[cur_id]

        ----发现黄金甲壳虫，将其他阵型替换为wild
        local cur_wild_pos_list = SlotsGameCal.Calculate.GetItemPosition(result_row, game_room_config, type.GoldWild, formation_name)
        local new_wild = {}
        for wild_k, wild_v in pairs(cur_wild_pos_list) do
            local is_exist = false
            for k, v in pairs(save_data.pre_action_list["formation"..cur_id]) do
                local action_info = v
                if (action_info.action_type == ActionType.ActionTypes.WildFly and amount_index == action_info.amount_index) then
                    local wild_pos_list = action_info.wild_pos_list
                    for pos_k, pos_v in pairs(wild_pos_list) do
                        local row, col = GetColRow(pos_v, col_num)
                        if (col == wild_v.col and row == v.row) then
                            is_exist = true
                            break                        
                        end
                    end
                end
            end
            if (not is_exist) then
                local conv_pos = ConvertPos(wild_v.col, wild_v.row, col_num)
                table.insert(new_wild, conv_pos)
            end
        end

        if #new_wild > 0 then
            -- print("new_wild1 is:"..json.encode(new_wild))
            local action_info = {
                action_type = ActionType.ActionTypes.WildFly,
                wild_pos_list = new_wild,
                amount_index = amount_index,
                formation_id = cur_id,
            }
            table.insert(pre_action_list, action_info)

            ---将其他阵型都替换
            for sub_id = self.parameters.start_id, self.parameters.end_id, 1 do
                local action_info = {
                    action_type = ActionType.ActionTypes.WildFly,
                    wild_pos_list = new_wild,
                    amount_index = amount_index,
                    formation_id = sub_id,
                }
                table.insert(save_data.pre_action_list["formation"..sub_id], action_info)
            end
        end

        local cur_round_info = GetRoundInfo(save_data, cur_status, amount_index)

        for sub_id = self.parameters.start_id, self.parameters.end_id, 1 do
            --将所有阵型变为wild
            if (cur_round_info.round == cur_round_info.max_round) then 
                for k, v in pairs(save_data.pre_action_list["formation"..cur_id]) do
                    local action_info = v
                    if (action_info.action_type == ActionType.ActionTypes.WildFly and amount_index == action_info.amount_index) then
                        local wild_pos_list = action_info.wild_pos_list
                        for pos_k, pos_v in pairs(wild_pos_list) do
                            local row, col = GetColRow(pos_v, col_num)
                            self.parameters.final_result_list[sub_id][row][col] = type.CWild
                        end
                    end
                end
            else
                for pos_k, pos_v in pairs(cur_wild_pos_list) do
                    self.parameters.final_result_list[sub_id][pos_v.row][pos_v.col] = type.GoldWild
                end
            end
        end
    end
end

function SlotsMagicScarabSpin:GenPrizeInfo()
    local player = self.parameters.player
    local game_type = self.parameters.game_type

    local game_room_config = self.parameters.game_room_config
    local amount = self.parameters.amount
    local player_feature_condition = self.parameters.player_feature_condition
    local extern_param = self.parameters.extern_param
    local player_game_info = self.parameters.player_game_info
    local formation_id = self.parameters.formation_id
    local formation_name = self.parameters.formation_name
    local final_result = self.parameters.final_result_list[formation_id]

    local line_id = self.parameters.line_id
    local player_game_status = self.parameters.player_game_status

    local amount_index = CommonCal.Calculate.GetBetIndex(game_type, amount)

    --print("final_result is:"..json.encode(final_result))

    local type = _G[game_room_config.game_name.."TypeArray"].Types
    --计算大奖哦
    local left_or_right = game_room_config.direction_type
    local payrate_file = CommonCal.Calculate.get_config(player, game_room_config.game_name.."PayrateConfig")

    local other_file = CommonCal.Calculate.get_config(player, game_room_config.game_name.."OthersConfig")

    local cur_status = GameStatusCal.Calculate.GetGameStatus(player_game_status)
    local is_in_free_spin = false

    -- type.Cleopatra
    local prize_final_result = table.DeepCopy(final_result)

    SlotsGameCal.Calculate.ReplaceSID(prize_final_result, type.Cleopatra)

    local prize_items, total_payrate = SlotsGameCal.Calculate.GenPrizeInfo(prize_final_result, game_room_config, payrate_file, left_or_right, type, formation_name, line_id, other_file[1].bet_ratio)
 

    table.insert(self.parameters.all_prize_list, prize_items)


    local slots_win_chip = total_payrate * amount

    local total_win_chip = slots_win_chip

    self.parameters.prize_items_list[formation_id] = prize_items
    self.parameters.slots_win_chip_list[formation_id] = slots_win_chip
    self.parameters.total_win_chip_list[formation_id] = total_win_chip
end

function SlotsMagicScarabSpin:AddRound() 
    local game_type = self.parameters.game_type
    local player = self.parameters.player
    local formation_id = self.parameters.formation_id
    local player_game_info = self.parameters.player_game_info
    local amount = self.parameters.amount
    local save_data = player_game_info.save_data
    local player_game_status = self.parameters.player_game_status
    local cur_status = GameStatusCal.Calculate.GetGameStatus(player_game_status)
    local amount_index = CommonCal.Calculate.GetBetIndex(game_type, amount)
    local cur_round_info = GetRoundInfo(save_data, cur_status, amount_index)
    cur_round_info.round = cur_round_info.round + 1

    for id = self.parameters.start_id, self.parameters.end_id, 1 do
        local pre_action_list = self.parameters.all_pre_action_list[id]
        local action_info = {
            action_type = ActionType.ActionTypes.RoundInfo,
            round = cur_round_info.round,
            max_round = cur_round_info.max_round,
            amount_index = amount_index
        }
        LOG(RUN, INFO).Format("[SlotsGame][AddRound] player %s, formation id is:%s,  ActionInfo is:%s", player.id, id, Table2Str(action_info))
        table.insert(pre_action_list, action_info)
    end
end

function SlotsMagicScarabSpin:ApplySlotsSpinList()
    local formation_id = self.parameters.formation_id
    local player = self.parameters.player
    local formation_name = self.parameters.formation_name
    local game_room_config = self.parameters.game_room_config
    local pre_action_list = self.parameters.all_pre_action_list[formation_id]
    local result_row = self.parameters.result_row_list[formation_id]
    local prize_items = self.parameters.prize_items_list[formation_id]
    local total_win_chip = self.parameters.total_win_chip_list[formation_id]
    local slots_win_chip = self.parameters.slots_win_chip_list[formation_id]
    local final_result = self.parameters.final_result_list[formation_id]

    local slots_spin_list = self:GetSpinList()

    local type = _G[game_room_config.game_name.."TypeArray"].Types
    LOG(RUN, INFO).Format("[SlotsGame][ApplySlotsSpinList] player %s, formation_id is:%s, ActionInfo is:%s", player.id, formation_id, Table2Str(pre_action_list))
    table.insert(slots_spin_list, {
        item_ids = json.encode(SlotsGameCal.Calculate.TransResultToCList(result_row, game_room_config, formation_name)),
        prize_items = prize_items,
        win_chip = total_win_chip,
        slots_win_chip = slots_win_chip,
        pre_action_list =  json.encode(pre_action_list),
        final_item_ids = json.encode(SlotsGameCal.Calculate.TransResultToCList(final_result, game_room_config, formation_name)),   
    })
end

function SlotsMagicScarabSpin:NormalSpin()
    local game_type = self.parameters.game_type
    local player_game_info = self.parameters.player_game_info
    local special_parameter = self.parameters.special_parameter

    local game_room_config = self.parameters.game_room_config
    local player_game_status = self.parameters.player_game_status
    local amount = self.parameters.amount
    local player = self.parameters.player

    local formation_name = self.parameters.formation_name

    local session = self.parameters.extern_param.session

    local save_data = player_game_info.save_data

    local lineNum = LineNum[game_type]()

    local amount_index = CommonCal.Calculate.GetBetIndex(game_type, amount)

    -- LOG(RUN, INFO).Format("[SlotsMagicScarabSpin][NormalSpin] begin")

    local cur_status = GameStatusCal.Calculate.GetGameStatus(player_game_status)

    local is_in_free_spin = (cur_status == GameStatusDefine.AllTypes.FreeSpinGame) and true or false

    InitRoundInfo(save_data, cur_status, amount_index)
    
    self:AddRound() 

    local cur_round_info = GetRoundInfo(save_data, cur_status, amount_index)

    local config_table = nil
    if ((player.character.lucky_type ~= LuckyType.ModeTypes.ForceWin)) then
        if (save_data.round_config["amount"..amount_index] == nil) then
            save_data.round_config["amount"..amount_index] = SlotsGameCal.Calculate.GetMapConfigTable(session, game_room_config, player_game_info, amount * lineNum)
        end
        config_table = save_data.round_config["amount"..amount_index]
    else
        config_table = SlotsGameCal.Calculate.GetMapConfigTable(session, game_room_config, player_game_info, amount * lineNum)
    end

    local reel_file = nil
    local weight_file = nil
    if cur_status == GameStatusDefine.AllTypes.FreeSpinGame then
        --save_data.spin_status = 2 ---0:normal,1:free spin,2 super free spin
        if (save_data.spin_status == 1) then
            reel_file = "MagicScarabFeatureReelConfig"
            weight_file = config_table.feature_reel_weight_config
        elseif (save_data.spin_status == 2) then
            reel_file = "MagicScarabFeatureReelConfig"
            weight_file = config_table.super_free_spin_reel_weight_config
        end
    else
        reel_file = "MagicScarabBaseReelConfig"
        weight_file = config_table.base_reel_weight_config
    end

    self.parameters.reel_file_name = reel_file
    self.parameters.weight_file = weight_file
    
    for id = self.parameters.start_id, self.parameters.end_id, 1 do
        self.parameters.formation_id = id
        ----转出元素
        self:GenItemResult()
    end

    self:WildFly()

    if (cur_round_info.round == cur_round_info.max_round) then
        local type = _G[game_room_config.game_name.."TypeArray"].Types
        for id = self.parameters.start_id, self.parameters.end_id, 1 do
            local formation = _G[game_room_config.game_name .. "FormationArray"][formation_name]
            if (formation ~= nil) then
                local col_num = SlotsGameCal.Calculate.GetColNum(game_room_config, formation_name)
                local pre_action_list = self.parameters.all_pre_action_list[id]
                local final_result = self.parameters.final_result_list[id]
                local result_row = self.parameters.result_row_list[id]

                local round_wild_pos = {}
                local round_scatter_pos = {}

                -- LOG(RUN, INFO).Format("[SlotsMagicScarabSpin][NormalSpin] replace cwild final_result is:%s, col_num is:%s", Table2Str(final_result), col_num)
    
                for col = 1, #formation, 1 do
                    for row = 1, formation[col], 1 do
                        -- LOG(RUN, INFO).Format("[SlotsMagicScarabSpin][NormalSpin] replace cwild1 row is:%s, col is:%s", row, col)
                        if (final_result[row] ~= nil and final_result[row][col] == type.CWild) then
                            -- LOG(RUN, INFO).Format("[SlotsMagicScarabSpin][NormalSpin] replace cwild2 row is:%s, col is:%s", row, col)
                            local conv_pos = ConvertPos(col, row, col_num)
                            table.insert(round_wild_pos, conv_pos)
                        end
                    end
                end

                for col = 1, #formation, 1 do
                    for row = 1, formation[col], 1 do
                        if (result_row[row] ~= nil and result_row[row][col] == type.Scatter) then
                            -- LOG(RUN, INFO).Format("[SlotsMagicScarabSpin][NormalSpin] replace Scatter row is:%s, col is:%s", row, col)
                            local conv_pos = ConvertPos(col, row, col_num)
                            local is_scatter_wild = false
                            for wild_k, wild_v in ipairs(round_wild_pos) do
                                if (wild_v == conv_pos) then
                                    is_scatter_wild = true
                                    break
                                end
                            end
                            if (is_scatter_wild) then
                                table.insert(round_scatter_pos, conv_pos)
                            end
                        end
                    end
                end
                -- LOG(RUN, INFO).Format("[SlotsMagicScarabSpin][NormalSpin] replace cwild round_wild_pos is:%s", Table2Str(round_wild_pos))
                local action_info1 = {
                    action_type = ActionType.ActionTypes.WildRoundEffect,
                    wild_pos_list = round_wild_pos,
                    amount_index = amount_index,
                    formation_id = id,
                }
                table.insert(pre_action_list, action_info1)

                local action_info2 = {
                    action_type = ActionType.ActionTypes.ScatterInfo,
                    scatter_pos_list = round_scatter_pos,
                    amount_index = amount_index,
                    formation_id = id,
                }
                table.insert(pre_action_list, action_info2)
            end
        end
    end

    for id = self.parameters.start_id, self.parameters.end_id, 1 do
        self.parameters.formation_id = id
        self:TriggerFreeSpin()
        ----计算大奖
        self:GenPrizeInfo()
        ----将奖励信息，阵型信息，连线信息，action信息都封装到slots_spin_list中
        self:ApplySlotsSpinList()
    end
    
    self.parameters.special_parameter.rounds = cur_round_info.round
    if (cur_round_info.round == cur_round_info.max_round) then
        for id = self.parameters.start_id, self.parameters.end_id, 1 do
            if (save_data.pre_action_list["formation"..id] ~= nil) then
                local action_info_list = {}
                for k, v in pairs(save_data.pre_action_list["formation"..id]) do
                    local action_info = v
                    if (action_info.amount_index ~= amount_index) then
                        table.insert(action_info_list, action_info)
                    end
                end
                save_data.pre_action_list["formation"..id] = action_info_list
            end
        end
    end



    special_parameter.spin_status = save_data.spin_status
    special_parameter.cur_free_status = save_data.cur_free_status

    if (cur_round_info.round == cur_round_info.max_round) then
        save_data.round_config["amount"..amount_index] = nil
        --print("round reach max_round amount_index is:"..amount_index)
    end

    if (cur_round_info.round == cur_round_info.max_round) then
        cur_round_info.round = 0
    end
    return self:GenWinInfo()
end

function SlotsMagicScarabSpin:Enter()
    -- LOG(RUN, INFO).Format("[SlotsMagicScarab][Enter] begin")
    local task = self.parameters.task
    local player = self.parameters.player
    local game_room_config = self.parameters.game_room_config
    local player_game_info = self.parameters.player_game_info
    local player_game_status = self.parameters.player_game_status

    local cur_status = GameStatusCal.Calculate.GetGameStatus(player_game_status)
    local save_data = player_game_info.save_data
    if (save_data.bonus_info == nil) then
        save_data.bonus_info = {}
    end
    InitActionList(save_data, cur_status, 1)
    
    if (save_data.trigger_free_count == nil) then
        save_data.trigger_free_count = 0
    end
    
    if (save_data.his_bet_amount == nil) then
        save_data.his_bet_amount = {}
    end
    
    if (save_data.round_config == nil) then
        save_data.round_config = {}
    end

    local content = {}
    content.bonus_info = {}
    content.bonus_info.action_info = {}
    for k, v in pairs(save_data.pre_action_list) do
        -- LOG(RUN, INFO).Format("[SlotsMagicScarab][Enter] action_info k is:%s, v is:%s", k, Table2Str(v))
        for action_index, action_info in pairs(v) do
            -- LOG(RUN, INFO).Format("[SlotsMagicScarab][Enter] action_info is:%s", Table2Str(action_info))
            -- if (content.bonus_info.action_info["formation"..action_info.formation_id] == nil) then
            --     content.bonus_info.action_info["formation"..action_info.formation_id] = {}
            -- end
            -- if (content.bonus_info.action_info["formation"..action_info.formation_id]["amount_index"..action_info.amount_index] == nil) then
            --     content.bonus_info.action_info["formation"..action_info.formation_id]["amount_index"..action_info.amount_index] = {}
            -- end
            if (content.bonus_info.action_info == nil) then
                content.bonus_info.action_info = {}
            end
            for wild_index, wild_pos in pairs(action_info.wild_pos_list) do
                local is_wild_exist = false
                local is_formation_exist = false
                for action_k, action_v in pairs(content.bonus_info.action_info) do
                    if (action_v.formation_id == action_info.formation_id and action_v.amount_index == action_info.amount_index) then
                        for his_wild_k, his_wild_v in pairs(action_v.wild_pos_list) do
                            if (his_wild_v == wild_pos) then
                                is_wild_exist = true
                                break
                            end
                        end
                        is_formation_exist = true
                    end
                end
                if (not is_formation_exist) then
                    table.insert(content.bonus_info.action_info, {formation_id = action_info.formation_id, amount_index = action_info.amount_index, wild_pos_list = {}})
                end
                if (not is_wild_exist) then
                    for action_k, action_v in pairs(content.bonus_info.action_info) do
                        if (action_v.formation_id == action_info.formation_id and action_v.amount_index == action_info.amount_index) then
                            table.insert(action_v.wild_pos_list, wild_pos)
                        end
                    end
                end
            end
            --table.insert(content.bonus_info.action_info["formation"..action_info.formation_id]["amount_index"..action_info.amount_index], {wild_pos_list = action_info.wild_pos_list, amount_index = action_info.amount_index})
        end
    end

    content.bonus_info.trigger_free_count = save_data.trigger_free_count

    if save_data.spin_status == 2 then
        content.bonus_info.is_super_free = 1
    else
        content.bonus_info.is_super_free = 0
    end
    local round = {}
    -- LOG(RUN, INFO).Format("[SlotsMagicScarab][Enter] cur_status is:%s, save_data.round_info is:%s", cur_status, json.encode(save_data.round_info))
    if (cur_status == 0) then
        cur_status = GameStatusDefine.AllTypes.BaseSpinGame
    end

    InitRoundInfo(save_data, cur_status, 1)

    if (save_data.round_info ~= nil) then
        local sel_status = GameStatusDefine.AllTypes.BaseSpinGame
        if save_data.round_info["status"..sel_status] ~= nil then
            round = save_data.round_info["status"..sel_status]
        end
    end
    
    content.bonus_info.round_info = round

    -- LOG(RUN, INFO).Format("[SlotsMagicScarab][Enter] content is:%s", json.encode(content))
    return content
end

function SlotsMagicScarabSpin:MagicScarabBonusStart()
    local content = {}
    return content
end

function SlotsMagicScarabSpin:MagicScarabBonusFinish()
    local content = {}
    return content
end