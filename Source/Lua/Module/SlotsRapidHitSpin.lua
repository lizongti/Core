require "Common/SlotsGameCalculate"     --重写的接口
require "Common/SlotsGameCal"           --旧的接口
require "Common/SlotsRapidHitCal"
require "Module/SlotsBaseSpin"
---require "Common/ActionType"
-- module("SlotsRapidHitSpin", package.seeall)

SlotsRapidHitSpin = {}

function SlotsRapidHitSpin:InitParameters(parameters)
    parameters.session.slots_game_spin.parameters = parameters

    parameters.formation_list={}
    local slots_spin_list = {}
    table.insert(parameters.formation_list, {
        slots_spin_list = slots_spin_list,
        id = 1,
    })

    parameters.pre_action_list = {}
    parameters.all_prize_list={}
    return parameters.session.slots_game_spin
end

function SlotsRapidHitSpin:GenItemResult()
    --player, game_type, is_free_spin, game_room_config, amount, player_feature_condition, extern_param, player_game_info
    if (self.parameters.formation_id == nil) then
        self.parameters.formation_id = 1
        self.parameters.formation_name = "Formation"..self.parameters.formation_id
    end
    if (self.parameters.line_id == nil) then
        self.parameters.line_id = "Lines1"
    end
    
    local player = self.parameters.player
    local game_type = self.parameters.game_type
    local is_free_spin = self.parameters.is_free_spin
    local game_room_config = self.parameters.game_room_config
    local amount = self.parameters.amount
    local player_feature_condition = self.parameters.player_feature_condition
    local extern_param = self.parameters.extern_param
    local player_game_info = self.parameters.player_game_info
    local line_id = self.parameters.line_id
    local formation_id= self.parameters.formation_id
    local formation_name = self.parameters.formation_name
    local reel_file_name = self.parameters.reel_file_name

    local formation_list = self.parameters.formation_list

    local total_win_chip, free_spin_bouts, slots_win_chip = 0, 0, 0
    local result_row ={}

    local lines_num = LineNum[game_type]()

    local type = _G[game_room_config.game_name.."TypeArray"].Types

    result_row, reel_file_name = SlotsGameCal.Calculate.GenItemResult(player, game_room_config.game_type, is_free_spin, game_room_config, nil, formation_name, extern_param, reel_file_name)

    self.parameters.result_row = result_row
    self.parameters.reel_file_name = reel_file_name

end

function SlotsRapidHitSpin:GetSpinList()
    local formation_list = self.parameters.formation_list
    return formation_list[1].slots_spin_list
    -- -- for index, formation_info in ipairs(formation_list) do
    -- --     if (formation_info.id == formation_id) then
    -- --         return formation_info.slots_spin_list
    -- --     end
    -- -- end
    -- return nil
end


function SlotsRapidHitSpin:ApplySlotsSpinList()
    local result_row = self.parameters.result_row
    local game_room_config = self.parameters.game_room_config
    local formation_name = self.parameters.formation_name
    local prize_items = self.parameters.prize_items
    local total_win_chip = self.parameters.total_win_chip
    local slots_win_chip = self.parameters.slots_win_chip
    local pre_action_list = self.parameters.pre_action_list
    local final_result = self.parameters.final_result

    local slots_spin_list = self:GetSpinList()

    table.insert(slots_spin_list, {
        item_ids = json.encode(SlotsGameCal.Calculate.TransResultToCList(result_row, game_room_config, formation_name)),
        prize_items = prize_items,
        win_chip = total_win_chip,
        slots_win_chip = slots_win_chip,
        pre_action_list =  json.encode(pre_action_list),
        final_item_ids = json.encode(SlotsGameCal.Calculate.TransResultToCList(final_result, game_room_config, formation_name)),   
    })
end

function SlotsRapidHitSpin:GenPrizeInfo()
    local player = self.parameters.player
    local game_type = self.parameters.game_type
    local is_free_spin = self.parameters.is_free_spin
    local game_room_config = self.parameters.game_room_config
    local amount = self.parameters.amount
    local player_feature_condition = self.parameters.player_feature_condition
    local extern_param = self.parameters.extern_param
    local player_game_info = self.parameters.player_game_info
    local result_row = self.parameters.result_row
    local reel_file_name = self.parameters.reel_file_name
    local formation_id = self.parameters.formation_id
    local formation_name = self.parameters.formation_name
    local line_id = self.parameters.line_id

    
    local final_result = table.DeepCopy(result_row)

    local type = _G[game_room_config.game_name.."TypeArray"].Types
    --计算大奖哦
    local left_or_right = game_room_config.direction_type
    local payrate_file = CommonCal.Calculate.get_config(player, game_room_config.game_name.."PayrateConfig")

    local other_file = CommonCal.Calculate.get_config(player, game_room_config.game_name.."OthersConfig")

    local prize_items, total_payrate = SlotsGameCal.Calculate.GenPrizeInfo(final_result, game_room_config, payrate_file, left_or_right, type, formation_name, line_id, other_file[1].Base_Bet_Ratio)
 
    table.insert(self.parameters.all_prize_list, prize_items)

    self.parameters.total_payrate = total_payrate
    self.parameters.prize_items = prize_items
    self.parameters.final_result = final_result

    local slots_win_chip = total_payrate * amount

    self.parameters.slots_win_chip = total_payrate * amount

    self.parameters.total_win_chip = self.parameters.slots_win_chip
end


function SlotsRapidHitSpin:ReplaceSuperStackStar()
    local player = self.parameters.player
    local game_room_config = self.parameters.game_room_config
    local player_game_info = self.parameters.player_game_info
    local save_data = player_game_info.save_data

    local pre_action_list = self.parameters.pre_action_list
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


----替换Super Stack Star元素
function SlotsRapidHitSpin:GenSuperStackStar()
    local player = self.parameters.player
    local result_row = self.parameters.result_row
    local formation_name = self.parameters.formation_name
    local player_game_info = self.parameters.player_game_info
    local game_room_config = self.parameters.game_room_config

    local type = _G[game_room_config.game_name.."TypeArray"].Types

    local super_stack_star_pos_list = SlotsGameCal.Calculate.GetItemPosition(result_row, game_room_config, type.SuperStackStar, formation_name)

    if #super_stack_star_pos_list > 0 then
        local super_stack_star_config = {}
 
        if is_free_spin then 
            if (special_parameter.is_super_free) then
                super_stack_star_config = CommonCal.Calculate.get_config(player, game_room_config.game_name .. "SuperFeatureSuperStackStarConfig")
            else
                super_stack_star_config = CommonCal.Calculate.get_config(player, game_room_config.game_name .. "FeatureSuperStackStarConfig")
            end
        else
            super_stack_star_config = CommonCal.Calculate.get_config(player, game_room_config.game_name .. "BaseSuperStackStarConfig")
        end
        local super_stack_star_replace_item_id = SlotsGameCal.Calculate.SuperStackReplace(player, nil, game_room_config, type.SuperStackStar, super_stack_star_config)
 
        for k,v in ipairs(super_stack_star_pos_list) do
            if (super_stack_star_replace_item_id == type.SuperStackStar) then
                if (v.col == 1) then
                    result_row[v.row][v.col] = type.OneStar
                elseif (v.col == 2) then
                    result_row[v.row][v.col] = type.TwoStar
                elseif (v.col == 3) then
                    result_row[v.row][v.col] = type.ThreeStar
                elseif (v.col == 4) then
                    result_row[v.row][v.col] = type.FiveStar
                elseif (v.col == 5) then
                    result_row[v.row][v.col] = type.TwoThreeFiveStar
                end
            else
                result_row[v.row][v.col] = super_stack_star_replace_item_id
            end
        end
    end
 
    ----替换Super Stack元素
    local super_stack_pos_list = SlotsGameCal.Calculate.GetItemPosition(result_row, game_room_config, type.SuperStack, formation_name)
 
    if #super_stack_pos_list > 0 then
        local save_data = player_game_info.save_data
        for k,v in ipairs(super_stack_pos_list) do
            result_row[v.row][v.col] = save_data.super_stack_replace_item_id
        end
    end
end

function SlotsRapidHitSpin:TriggerClassic()
    local result_row = self.parameters.result_row
    local game_room_config = self.parameters.game_room_config
    local player_game_info = self.parameters.player_game_info

    local player_game_status = self.parameters.player_game_status

    local special_parameter = self.parameters.special_parameter
    local save_data = player_game_info.save_data

    local pre_action_list = self.parameters.pre_action_list

    local amount = self.parameters.amount

    local total_classic_count = 0
    save_data.classic_item_count, total_classic_count = SlotsRapidHitCal.GetItemsCount(result_row, game_room_config, SlotsRapidHitCal.GetStarKeys(game_room_config))

    LOG(RUN, INFO).Format("[SlotsRapidHitSpin][TriggerClassic] total_classic_count is:%s", total_classic_count)
    LOG(RUN, INFO).Format("[SlotsRapidHitSpin][TriggerClassic] save_data.classic_item_count is:%s", Table2Str(save_data.classic_item_count))
    if (total_classic_count >= 3) then
        local c_classic_item_count = {}
        for k, v in ipairs(SlotsRapidHitCal.GetStarKeys(game_room_config)) do
            local item_count_key = "item"..v
            if (save_data.classic_item_count[item_count_key] ~= nil) then
                c_classic_item_count[k] = {item_id = v, left_count = save_data.classic_item_count[item_count_key].left_count, total_count = save_data.classic_item_count[item_count_key].total_count}
            else
                c_classic_item_count[k] = 0
            end
        end
        table.insert(pre_action_list, {
            action_type = ActionType.ActionTypes.ClassicGameInfo,
            classic_item_count = c_classic_item_count,
            left_classic_num = total_classic_count,
            is_finally_classic = 0,--是否为最后一次
            calssic_win_chip = save_data.calssic_win_chip,--classic累计奖励
        })
        LOG(RUN, INFO).Format("[SlotsRapidHitSpin][TriggerClassic] pre_action_list is:%s", Table2Str(pre_action_list))
        --special_parameter.extral_spin_bouts = total_classic_count

        -- print("total_classic_count is:"..total_classic_count)
        -- print("classic_item_count is:"..json.encode(save_data.classic_item_count))
        ---------------触发状态
        GameStatusCal.Calculate.AddGameStatus(player_game_status, GameStatusDefine.AllTypes.ClassicSpinGame, total_classic_count, 1, amount)
    end
end

function SlotsRapidHitSpin:NormalSpinJackpot()
    local player = self.parameters.player
    local game_room_config = self.parameters.game_room_config
    local pre_action_list = self.parameters.pre_action_list
    local amount = self.parameters.amount
    local player_game_info = self.parameters.player_game_info
    local save_data = player_game_info.save_data
    local game_type = self.parameters.game_type
    local result_row = self.parameters.result_row

    -- print("session2 is:"..json.encode(self.parameters.extern_param.session))

    local lines_num = LineNum[game_type]()

    local classic_jackpot_win_chip = SlotsRapidHitCal.GenClassicJacpotPool(player, game_room_config, pre_action_list, amount, save_data, true, lines_num, nil)
    local jackpot_win_chip = SlotsRapidHitCal.GenJacpotPool(player, game_room_config, pre_action_list, amount, save_data, false, result_row, lines_num)

    local type = _G[game_room_config.game_name.."TypeArray"].Types
    local rapidhit_pos_list = SlotsGameCal.Calculate.GetItemPosition(result_row, game_room_config, type.RapidHit)
    if #rapidhit_pos_list >= 5 then
        FeverQuestCal.OnRapidHitClassicSpinEnd(self.parameters.extern_param.session, jackpot_win_chip)
    end

    self.parameters.jackpot_win_chip = jackpot_win_chip
    self.parameters.classic_jackpot_win_chip = classic_jackpot_win_chip
end

function SlotsRapidHitSpin:TriggerFreeSpin()
    local player = self.parameters.player
    local final_result = self.parameters.final_result
    local game_room_config = self.parameters.game_room_config
    local is_free_spin = self.parameters.is_free_spin
    local special_parameter = self.parameters.special_parameter

    local pre_action_list = self.parameters.pre_action_list

    local player_game_status = self.parameters.player_game_status

    local player_game_info = self.parameters.player_game_info

    local amount = self.parameters.amount
    local game_type = self.parameters.game_type

    local type = _G[game_room_config.game_name.."TypeArray"].Types
    local save_data = player_game_info.save_data

    LOG(RUN, INFO).Format("[SlotsRapidHitSpin][TriggerFreeSpin] final_result:%s, is_free_spin:%s", final_result, is_free_spin)

    local free_spin_bouts =  SlotsGameCal.Calculate.FreeSpinCheck(player, final_result, game_room_config, is_free_spin, type.Scatter)   

    LOG(RUN, INFO).Format("[SlotsRapidHitSpin][TriggerFreeSpin] free_spin_bouts:%s", free_spin_bouts)
    if (free_spin_bouts > 0) then
        ---test begin------
        -- free_spin_bouts = 2
        ---test end---------
        ---------------触发状态
        GameStatusCal.Calculate.AddGameStatus(player_game_status, GameStatusDefine.AllTypes.FreeSpinGame, free_spin_bouts, 1, amount)
    end
    
    special_parameter.is_super_free_spin = 0
    special_parameter.is_free_spin = 0

    local is_super_free_start = 0

    if (not is_free_spin) then
        --print("is not free spin")
        if (free_spin_bouts > 0) then
            --print("trigger free_spin_bouts is:"..free_spin_bouts)
            save_data.trigger_free_count = 1
            save_data.new_free_count = save_data.new_free_count + 1
            table.insert(save_data.his_bet_amount, amount)
            ----说明下次触发SuperFreeSpin
            if (save_data.new_free_count > 9) then
                is_super_free_start = 1
                save_data.is_super_free = 1
                special_parameter.is_super_free_spin = 1

                if (#save_data.his_bet_amount > 0) then
                    local local_total_bet_amount = 0
                    for k, v in pairs(save_data.his_bet_amount) do
                        local_total_bet_amount = local_total_bet_amount + v
                    end
                    amount = math.floor(local_total_bet_amount / #save_data.his_bet_amount)
                    local lineNum = LineNum[game_type]()
                    SlotsGameCal.Calculate.ChangeBetAmountInRunning(player_game_info, pre_action_list, amount,  free_spin_bouts, 0)
                end

            else
                special_parameter.is_free_spin = 1
            end
        end
    else
        if (free_spin_bouts > 0) then
            save_data.trigger_free_count = save_data.trigger_free_count + 1

            player_game_info.free_spin_num = free_spin_bouts----客户端弹出对话框后才加free spin次数

        end
    end
    --print("free_spin_bouts is:"..free_spin_bouts.."final_result is:"..json.encode(final_result))

    table.insert(pre_action_list, {
        action_type = ActionType.ActionTypes.SuperFreeSpinProgress,
        super_free_spin_progress = save_data.new_free_count,---进度
    })

    if (free_spin_bouts > 0) then
        table.insert(pre_action_list, {
            action_type = ActionType.ActionTypes.TriggerFreeSpin,
            trigger_free_count = save_data.trigger_free_count,---0没有对话框，1弹出对话框让玩家选择，大于1弹出对话框告诉玩家免费次数叠加
            is_super_free_start = is_super_free_start,--是否为super free spin
            free_spin_bouts = free_spin_bouts,
            pos = SlotsGameCal.Calculate.GetItemPosition(final_result, game_room_config, type.Scatter)
        })
    end
end

function SlotsRapidHitSpin:NormalSpin()
    local player_game_info = self.parameters.player_game_info
    local special_parameter = self.parameters.special_parameter
    local is_free_spin = self.parameters.is_free_spin
    local game_room_config = self.parameters.game_room_config
    local player_game_status = self.parameters.player_game_status
    local amount = self.parameters.amount
    local pre_action_list = self.parameters.pre_action_list

    local save_data = player_game_info.save_data

    LOG(RUN, INFO).Format("[SlotsRapidHitSpin][NormalSpin] begin")

   -- GameStatusCal.Calculate.FinishedInfo(temp_game_status, GameStatusDefine.AllTypes.FreeSpinGame)

    SlotsRapidHitCal.InitExternInfo(game_room_config, save_data)

    local cur_status = GameStatusCal.Calculate.GetGameStatus(player_game_status)

    if (is_free_spin) then
        LOG(RUN, INFO).Format("[SlotsRapidHitSpin][NormalSpin] this is freespin")
    else
        LOG(RUN, INFO).Format("[SlotsRapidHitSpin][NormalSpin] this is normalspin")
    end
    --print("NormalSpin----------")
    -----玩法特色元素初始化
    save_data.calssic_win_chip = 0

    if (save_data.is_super_free == 1) then

        special_parameter.is_super_free = true
    else
        special_parameter.is_super_free = false
    end

    if (is_free_spin) then
        save_data.total_free_spin_times = save_data.total_free_spin_times + 1
    else
        save_data.total_free_spin_times = 0
    end

    if is_free_spin then 
        if (special_parameter.is_super_free) then
            self.parameters.reel_file_name = game_room_config.game_name .. "SuperFeatureReelConfig"
        else
            self.parameters.reel_file_name = game_room_config.game_name .. "FeatureReelConfig"
        end
    else
        self.parameters.reel_file_name = game_room_config.game_name .. "BaseReelConfig"
    end

    ----转出元素
    self:GenItemResult()

    ----替换元素
    self:GenSuperStackStar()

    ----计算大奖
    self:GenPrizeInfo()

    self:NormalSpinJackpot()

    self:TriggerFreeSpin()

    ---是否触发classic,触发发送action给客户端
    self:TriggerClassic()

    self:ReplaceSuperStackStar()

    self.parameters.total_win_chip = self.parameters.slots_win_chip + self.parameters.jackpot_win_chip + self.parameters.classic_jackpot_win_chip

    ----将奖励信息，阵型信息，连线信息，action信息都封装到slots_spin_list中
    self:ApplySlotsSpinList()

    special_parameter.is_classic = false
    special_parameter.slots_win_chip = self.parameters.slots_win_chip
    special_parameter.jackpot_win_chip = self.parameters.jackpot_win_chip
    special_parameter.classic_jackpot_win_chip = self.parameters.classic_jackpot_win_chip

    local result = {}
    result.final_result = self.parameters.final_result --结果数组
    result.total_win_chip = self.parameters.total_win_chip  --总奖金
    result.all_prize_list = self.parameters.all_prize_list --所有连线列表
    result.free_spin_bouts = self.parameters.free_spin_bouts --freespin的次数
    result.formation_list = self.parameters.formation_list --阵型列表
    result.reel_file_name = self.parameters.reel_file_name --reel表名
    result.slots_win_chip = self.parameters.slots_win_chip --总奖励
    result.special_parameter = self.parameters.special_parameter --其他参数，主要给模拟器传参

    LOG(RUN, INFO).Format("[SlotsRapidHitSpin][NormalSpin] end, formation is:%s", Table2Str(result.formation_list ))
    return result
end

function SlotsRapidHitSpin:GenClassicItemResult()
    if (self.parameters.formation_id == nil) then
        self.parameters.formation_id = 1
        self.parameters.formation_name = "Formation"..self.parameters.formation_id
    end
    if (self.parameters.line_id == nil) then
        self.parameters.line_id = "Lines1"
    end

    local player = self.parameters.player
    local game_type = self.parameters.game_type
    local game_room_config = self.parameters.game_room_config
    local amount = self.parameters.amount
    local player_feature_condition = self.parameters.player_feature_condition
    local extern_param = self.parameters.extern_param
    local player_game_info = self.parameters.player_game_info
    local line_id = self.parameters.line_id
    local formation_id= self.parameters.formation_id
    local formation_name = self.parameters.formation_name
    local reel_file_name = self.parameters.reel_file_name

    local formation_list = self.parameters.formation_list

    local save_data = player_game_info.save_data
    
    local classic_types = SlotsRapidHitCal.GetClassicTypes(game_room_config)

    local classic_item_id = 0
    -- print("111save_data.classic_item_count is:"..json.encode(save_data.classic_item_count))
    LOG(RUN, INFO).Format("[SlotsRapidHitSpin][GenClassicItemResult] classic_item_count1 is: %s", Table2Str(save_data.classic_item_count))
    for k, v in ipairs(SlotsRapidHitCal.GetStarKeys(game_room_config)) do
        local item_count_key = "item"..v
        --LOG(RUN, INFO).Format("[SlotsRapidHitSpin][111111] player id %s, v is:%s", player.id, item_count_key)
        --LOG(RUN, INFO).Format("[SlotsRapidHitSpin][111111] player id %s, classic_item_count is:%s", player.id, Table2Str(save_data.classic_item_count[item_count_key]))
        if (save_data.classic_item_count[item_count_key] ~= nil and save_data.classic_item_count[item_count_key].left_count > 0) then
            save_data.classic_item_count[item_count_key].left_count = save_data.classic_item_count[item_count_key].left_count - 1
            classic_item_id = v
            break
        end
    end

    LOG(RUN, INFO).Format("[SlotsRapidHitSpin][GenClassicItemResult] classic_item_count2 is: %s", Table2Str(save_data.classic_item_count))

    ---这些是玩法开发用到的东西，直接复制吧---
    local total_win_chip, free_spin_bouts, slots_win_chip = 0, 0, 0
    local result_row = {}

    
    local reel_file_name
    local reel_value

    local lines_num = LineNum[game_type]()

    LOG(RUN, INFO).Format("[SlotsRapidHitSpin][GenClassicItemResult] classic_item_id is: %s", classic_item_id)

    result_row, reel_file_name, reel_value = SlotsRapidHitCal.GenClassicItemResult(player, game_room_config.game_type, game_room_config, classic_types[classic_item_id], formation_id)

    self.parameters.result_row = result_row
    self.parameters.reel_file_name = reel_file_name

    self.parameters.reel_value = reel_value

end

function SlotsRapidHitSpin:GenClassicPrizeInfo()
    local player = self.parameters.player
    local game_type = self.parameters.game_type
    local is_free_spin = self.parameters.is_free_spin
    local game_room_config = self.parameters.game_room_config
    local amount = self.parameters.amount
    local player_feature_condition = self.parameters.player_feature_condition
    local extern_param = self.parameters.extern_param
    local player_game_info = self.parameters.player_game_info
    local result_row = self.parameters.result_row
    local reel_file_name = self.parameters.reel_file_name
    local formation_id = self.parameters.formation_id
    local formation_name = self.parameters.formation_name
    local line_id = self.parameters.line_id

    local pre_action_list = self.parameters.pre_action_list

    local save_data = player_game_info.save_data
    local final_result = table.DeepCopy(result_row)

    local reel_value = self.parameters.reel_value

    local lines_num = LineNum[game_type]()

    -- local is_finally_classic = 1
    -- if (total_classic_count > 0) then
    --     is_finally_classic = 0
    -- end

    local classic_jackpot_win_chip = SlotsRapidHitCal.GenClassicJacpotPool(player, game_room_config, pre_action_list, amount, save_data, false, lines_num, reel_value)
    local jackpot_win_chip = SlotsRapidHitCal.GenJacpotPool(player, game_room_config, pre_action_list, amount, save_data, true, result_row, lines_num)
 
   -------------计算奖励-----------

    local total_payrate = reel_value.payrate * lines_num
    slots_win_chip = total_payrate * amount
    total_win_chip = slots_win_chip + jackpot_win_chip + classic_jackpot_win_chip

    save_data.calssic_win_chip = save_data.calssic_win_chip + total_win_chip

    local prize_items = SlotsRapidHitCal.GetPrizeList(result_row[3], total_payrate)

    table.insert(self.parameters.all_prize_list, prize_items)

    self.parameters.total_payrate = total_payrate
    self.parameters.prize_items = prize_items
    self.parameters.final_result = final_result

    self.parameters.slots_win_chip = slots_win_chip

    self.parameters.total_win_chip = total_win_chip

    self.parameters.jackpot_win_chip = jackpot_win_chip

    self.parameters.classic_jackpot_win_chip = classic_jackpot_win_chip
end

function SlotsRapidHitSpin:ClassicSpin()
    local player = self.parameters.player
    local game_type = self.parameters.game_type
    local game_room_config = self.parameters.game_room_config
    local amount = self.parameters.amount
    local player_feature_condition = self.parameters.player_feature_condition
    local extern_param = self.parameters.extern_param
    local player_game_info = self.parameters.player_game_info

    local special_parameter = self.parameters.special_parameter

    local pre_action_list = self.parameters.pre_action_list

    local save_data = player_game_info.save_data

    LOG(RUN, INFO).Format("[SlotsRapidHitSpin][ClassicSpin] begin")

    SlotsRapidHitCal.InitExternInfo(game_room_config, save_data)

    local formation_id = self.parameters.formation_id
    local formation_name = self.parameters.formation_name

    if (save_data.is_super_free == 1) then
        special_parameter.is_super_free = true
    else
        special_parameter.is_super_free = false
    end

    --print("ClassicSpin----------")
    self:GenClassicItemResult()

    self:GenClassicPrizeInfo()

    local total_classic_count = 0
    for k, v in ipairs(SlotsRapidHitCal.GetStarKeys(game_room_config)) do
        local item_count_key = "item"..v
        if (save_data.classic_item_count[item_count_key] ~= nil and save_data.classic_item_count[item_count_key].left_count > 0) then
            total_classic_count = total_classic_count + save_data.classic_item_count[item_count_key].left_count
        end
    end

    local is_finally_classic = 1
    if (total_classic_count > 0) then
        is_finally_classic = 0
    end

    local c_classic_item_count = {}
    for k, v in ipairs(SlotsRapidHitCal.GetStarKeys(game_room_config)) do
        local item_count_key = "item"..v
        if (save_data.classic_item_count[item_count_key] ~= nil) then
            c_classic_item_count[k] = {item_id = v, left_count = save_data.classic_item_count[item_count_key].left_count, total_count = save_data.classic_item_count[item_count_key].total_count}
        else
            c_classic_item_count[k] = 0
        end
    end
    table.insert(pre_action_list, {
        action_type = ActionType.ActionTypes.ClassicGameInfo,
        classic_item_count = c_classic_item_count,
        left_classic_num = total_classic_count,
        is_finally_classic = is_finally_classic,--是否为最后一次
        calssic_win_chip = save_data.calssic_win_chip,--classic累计奖励
    })

    ----将奖励信息，阵型信息，连线信息，action信息都封装到slots_spin_list中
    self:ApplySlotsSpinList()

    -----传给模拟器统计要使用的参数
    special_parameter.is_classic = true
    special_parameter.slots_win_chip = self.parameters.slots_win_chip
    special_parameter.jackpot_win_chip = self.parameters.jackpot_win_chip
    special_parameter.classic_jackpot_win_chip = self.parameters.classic_jackpot_win_chip
    
    if is_finally_classic == 1 then
        FeverQuestCal.OnRapidHitMiniClassSpinEnd(self.parameters.extern_param.session, self.parameters.total_win_chip)
    end
    ----返回参数给上层用
    local result = {}
    result.final_result = self.parameters.final_result --结果数组
    result.total_win_chip = self.parameters.total_win_chip  --总奖金
    result.all_prize_list = self.parameters.all_prize_list --所有连线列表
    result.free_spin_bouts = self.parameters.free_spin_bouts --freespin的次数
    result.formation_list = self.parameters.formation_list --阵型列表
    result.reel_file_name = self.parameters.reel_file_name --reel表名
    result.slots_win_chip = self.parameters.slots_win_chip --总奖励
    result.special_parameter = self.parameters.special_parameter --其他参数，主要给模拟器传参

    LOG(RUN, INFO).Format("[SlotsRapidHitSpin][ClassicSpin] end")
    return result
end

function SlotsRapidHitSpin:Enter()
   local task = self.parameters.task
   local player = self.parameters.player
   local game_room_config = self.parameters.game_room_config
   local player_game_info = self.parameters.player_game_info
   local player_game_status = self.parameters.player_game_status
   local total_classic_count = 0

   local save_data = player_game_info.save_data

   SlotsRapidHitCal.InitExternInfo(game_room_config, save_data)
   local bonus_info = {}
   local pre_action_list = {}

   if (GameStatusCal.Calculate.GameStatusCount(player_game_status) > 0) then
        if (save_data.classic_item_count ~= nil) then
            LOG(RUN, INFO).Format("[SlotsRapidHitSpin]begin player id %s, classic_item_count is:%s", player.id, Table2Str(save_data.classic_item_count))
            LOG(RUN, INFO).Format("[SlotsRapidHitSpin]begin player id %s, keys is:%s", player.id, Table2Str(SlotsRapidHitCal.GetStarKeys(game_room_config)))
            for k, v in ipairs(SlotsRapidHitCal.GetStarKeys(game_room_config)) do
                local item_count_key = "item"..v
                if (save_data.classic_item_count[item_count_key] ~= nil and save_data.classic_item_count[item_count_key].left_count > 0) then
                    total_classic_count = total_classic_count + save_data.classic_item_count[item_count_key].left_count
                end
            end
        end

            
        if (total_classic_count > 0) then
            local c_classic_item_count = {}
            for k, v in ipairs(SlotsRapidHitCal.GetStarKeys(game_room_config)) do
                local item_count_key = "item"..v
                if (save_data.classic_item_count[item_count_key] ~= nil and save_data.classic_item_count[item_count_key].left_count > 0) then
                    c_classic_item_count[k] = {item_id = v, left_count = save_data.classic_item_count[item_count_key].left_count, total_count = save_data.classic_item_count[item_count_key].total_count}
                else
                    c_classic_item_count[k] = 0
                end
            end

            table.insert(pre_action_list, {
                action_type = ActionType.ActionTypes.ClassicGameInfo,
                classic_item_count = c_classic_item_count,
                left_classic_num = total_classic_count,
                is_finally_classic = 0,
                calssic_win_chip = save_data.calssic_win_chip,--classic累计奖励
            })
        end
    end

    table.insert(pre_action_list, {
        action_type = ActionType.ActionTypes.SuperFreeSpinProgress,
        super_free_spin_progress = save_data.new_free_count,---进度
    })
    
    local classic_jackpot_win_chip = SlotsRapidHitCal.GenClassicJacpotPool(player, game_room_config, pre_action_list, 0, save_data, true, 0)
    local jackpot_win_chip = SlotsRapidHitCal.GenJacpotPool(player, game_room_config, pre_action_list, 0, save_data, true, nil, 0)

    bonus_info.pre_action_list = pre_action_list

    ----------Super stack 特性------------
    local type = _G[game_room_config.game_name.."TypeArray"].Types
    local super_stack_config = CommonCal.Calculate.get_config(player, game_room_config.game_name .. "SuperStackConfig")
    if not save_data.super_stack_replace_item_id or save_data.super_stack_replace_item_id <= 0 then
        local super_stack_replace_item_id = SlotsGameCal.Calculate.SuperStackReplace(player, nil, game_room_config, type.SuperStack, super_stack_config)
        save_data.super_stack_replace_item_id = super_stack_replace_item_id
    end
    bonus_info.super_stack_replace_item_id = save_data.super_stack_replace_item_id

    return bonus_info
end

