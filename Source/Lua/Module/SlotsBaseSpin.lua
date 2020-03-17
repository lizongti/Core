require "Common/SlotsGameCalculate" --重写的接口
require "Common/SlotsGameCal" --旧的接口
---require "Common/ActionType"

SlotsBaseSpin = {parameters = {}}
SlotsBaseSpin.__index = SlotsBaseSpin

function SlotsBaseSpin:Create(t, parameters)
    local SlotsGameSpin = {}
    setmetatable(SlotsGameSpin, SlotsBaseSpin)
    SlotsGameSpin.parameters = parameters
    CommonCal.Calculate.CopyFunctions(SlotsGameSpin, t)

    parameters.session.slots_game_spin = SlotsGameSpin

    return SlotsGameSpin
end

function SlotsBaseSpin:InitParameters(parameters)
    parameters.session.slots_game_spin.parameters = parameters

    parameters.formation_list = {}

    if (parameters.formation_id == nil) then
        parameters.formation_id = 1
    end

    ---阵型
    if (parameters.formation_name == nil) then
        parameters.formation_name = "Formation1"
    end

    if (parameters.formation_num == nil) then
        parameters.formation_num = 1
    end

    if (parameters.start_id == nil) then
        parameters.start_id = 1
    end

    if (parameters.end_id == nil) then
        parameters.end_id = 1
    end

    if (parameters.line_id == nil) then
        parameters.line_id = "Lines1"
    end

    if (parameters.prize_items_list == nil) then
        parameters.prize_items_list = {}
    end

    if (parameters.slots_win_chip_list == nil) then
        parameters.slots_win_chip_list = {}
    end

    if (parameters.total_win_chip_list == nil) then
        parameters.total_win_chip_list = {}
    end

    if (parameters.result_row_list == nil) then
        parameters.result_row_list = {}
    end

    if (parameters.final_result_list == nil) then
        parameters.final_result_list = {}
    end

    parameters.all_pre_action_list = {}

    for id = 1, parameters.formation_num, 1 do
        local slots_spin_list = {}
        table.insert(
            parameters.formation_list,
            {
                slots_spin_list = slots_spin_list,
                id = id
            }
        )
        parameters.all_pre_action_list[id] = {}
    end

    parameters.all_prize_list = {}
    return parameters.session.slots_game_spin
end

function SlotsBaseSpin:GenWinInfo()
    local result = {}
    result.final_result = {}
    for k, v in pairs(self.parameters.final_result_list) do
        table.insert(result.final_result, v)
    end

    local slots_win_chip = 0
    for k, v in pairs(self.parameters.slots_win_chip_list) do
        slots_win_chip = slots_win_chip + v
    end

    local total_win_chip = 0
    for k, v in pairs(self.parameters.total_win_chip_list) do
        total_win_chip = total_win_chip + v
    end

    self.parameters.special_parameter.slots_win_chip = slots_win_chip
    self.parameters.special_parameter.total_win_chip = total_win_chip

    self.parameters.special_parameter.slots_win_chip_list = self.parameters.slots_win_chip_list
    self.parameters.special_parameter.total_win_chip_list = self.parameters.total_win_chip_list

    result.total_win_chip = total_win_chip --总奖金
    result.all_prize_list = self.parameters.all_prize_list --所有连线列表
    result.free_spin_bouts = self.parameters.free_spin_bouts --freespin的次数
    result.formation_list = self.parameters.formation_list --阵型列表
    result.reel_file_name = self.parameters.reel_file_name --reel表名
    result.slots_win_chip = slots_win_chip --总奖励
    result.special_parameter = self.parameters.special_parameter --其他参数，主要给模拟器传参
    return result
end

function SlotsBaseSpin:GenItemResult()
    --player, game_type, is_free_spin, game_room_config, amount, player_feature_condition, extern_param, player_game_info

    local player = self.parameters.player
    local game_type = self.parameters.game_type
    local is_free_spin = self.parameters.is_free_spin
    local game_room_config = self.parameters.game_room_config
    local amount = self.parameters.amount
    local player_feature_condition = self.parameters.player_feature_condition
    local extern_param = self.parameters.extern_param
    local player_game_info = self.parameters.player_game_info
    local line_id = self.parameters.line_id
    local formation_id = self.parameters.formation_id
    local formation_name = self.parameters.formation_name
    local reel_file_name = self.parameters.reel_file_name

    local formation_list = self.parameters.formation_list

    local result_row = {}

    local lines_num = LineNum[game_type]()

    local type = _G[game_room_config.game_name .. "TypeArray"].Types

    result_row, reel_file_name =
        SlotsGameCal.Calculate.GenItemResult(
        player,
        game_room_config.game_type,
        is_free_spin,
        game_room_config,
        nil,
        formation_name,
        extern_param,
        reel_file_name
    )

    self.parameters.reel_file_name = reel_file_name

    self.parameters.result_row_list[formation_id] = result_row
    self.parameters.final_result_list[formation_id] = table.DeepCopy(result_row)
end

function SlotsBaseSpin:GetSpinList()
    local formation_list = self.parameters.formation_list
    local formation_id = self.parameters.formation_id
    for index, formation_info in ipairs(formation_list) do
        if (formation_info.id == formation_id) then
            return formation_info.slots_spin_list
        end
    end
    return nil
end

function SlotsBaseSpin:ApplySlotsSpinList()
    local formation_id = self.parameters.formation_id
    local formation_name = self.parameters.formation_name
    local game_room_config = self.parameters.game_room_config
    local pre_action_list = self.parameters.all_pre_action_list[formation_id]
    local result_row = self.parameters.result_row_list[formation_id]
    local prize_items = self.parameters.prize_items_list[formation_id]
    local total_win_chip = self.parameters.total_win_chip_list[formation_id]
    local slots_win_chip = self.parameters.slots_win_chip_list[formation_id]
    local final_result = self.parameters.final_result_list[formation_id]

    local slots_spin_list = self:GetSpinList()

    table.insert(
        slots_spin_list,
        {
            item_ids = json.encode(
                SlotsGameCal.Calculate.TransResultToCList(result_row, game_room_config, formation_name)
            ),
            prize_items = prize_items,
            win_chip = total_win_chip,
            slots_win_chip = slots_win_chip,
            pre_action_list = json.encode(pre_action_list),
            final_item_ids = json.encode(
                SlotsGameCal.Calculate.TransResultToCList(final_result, game_room_config, formation_name)
            )
        }
    )
end

function SlotsBaseSpin:GenPrizeInfo()
    local player = self.parameters.player
    local game_type = self.parameters.game_type
    local is_free_spin = self.parameters.is_free_spin
    local game_room_config = self.parameters.game_room_config
    local amount = self.parameters.amount
    local player_feature_condition = self.parameters.player_feature_condition
    local extern_param = self.parameters.extern_param
    local player_game_info = self.parameters.player_game_info
    local formation_id = self.parameters.formation_id
    local formation_name = self.parameters.formation_name
    local final_result = self.parameters.final_result_list[formation_id]
    local reel_file_name = self.parameters.reel_file_name
    local line_id = self.parameters.line_id

    local type = _G[game_room_config.game_name .. "TypeArray"].Types
    --计算大奖哦
    local left_or_right = game_room_config.direction_type
    local payrate_file = CommonCal.Calculate.get_config(player, game_room_config.game_name .. "PayrateConfig")

    local other_file = CommonCal.Calculate.get_config(player, game_room_config.game_name .. "OthersConfig")

    local prize_items, total_payrate =
        SlotsGameCal.Calculate.GenPrizeInfo(
        final_result,
        game_room_config,
        payrate_file,
        left_or_right,
        type,
        formation_name,
        line_id,
        other_file[1].Base_Bet_Ratio
    )

    table.insert(self.parameters.all_prize_list, prize_items)

    local slots_win_chip = total_payrate * amount

    local total_win_chip = slots_win_chip

    LOG(RUN, INFO).Format(
        "[SlotsRapidHitSpin][GenPrizeInfo] total_payrate is:%s, slots_win_chip is:%s, total_win_chip is:%s",
        total_payrate,
        slots_win_chip,
        total_win_chip
    )
    self.parameters.prize_items_list[formation_id] = prize_items
    self.parameters.slots_win_chip_list[formation_id] = slots_win_chip
    self.parameters.total_win_chip_list[formation_id] = total_win_chip
end

function SlotsBaseSpin:Spin()
    self:GenItemResult()
    self:GenPrizeInfo()
    self:ApplySlotsSpinList()
end