require"Common/SlotsGameCalculate" -- 重写的接口
require"Common/SlotsGameCal" -- 旧的接口
require"Common/LineNum"

SlotsThunderZeusSpin = {}

local Types = _G["ThunderZeusTypeArray"].Types

local function WinJackpot(current_result, prev_result)
    local thunders = {}
    for i = 1, #current_result do
        for j = 1, #current_result[i] do
            if current_result[i][j] == Types.Jackpot then
                if prev_result and prev_result[i][j] == Types.Jackpot then
                    -- 之前这个位置也是jackpot，分组是累加的
                else
                    -- 新出现的jackpot
                    table.insert(thunders, {
                        row = i,
                        col = j
                    })
                end
            end
        end
    end
    return thunders
end

-- 入口
function SlotsThunderZeusSpin:Enter()
    local task = self.parameters.task
    local player = self.parameters.player
    local game_room_config = self.parameters.game_room_config
    local player_game_info = self.parameters.player_game_info
    local session = self.parameters.session
    local player_game_status = self.parameters.player_game_status

    local bonus_info = {}
    local save_data = player_game_info.save_data

    -- jackpot初始化
    if not save_data.jackpot_param_v2 then
        save_data.jackpot_param_v2 = {}
        local config = CommonCal.Calculate.get_config(player, "ThunderZeusJackpotConfig")
        CommonCal.Calculate.InitJackpotParam(save_data.jackpot_param_v2, config)
    end
    bonus_info.jackpot_param = CommonCal.Calculate.GetJakcpotParamToClient(save_data.jackpot_param_v2)

    -- respin 状态
    if save_data.groups then
        local groups = save_data.groups
        local respin_count = save_data.respin_count

        local item_ids = SlotsGameCal.Calculate.TransResultToCList(groups[respin_count].result, game_room_config)
        bonus_info.respin_info = {
            max_respin = #groups,
            max_show_respin = save_data.max_show_respin,
            current_respin = respin_count,
            is_empty = groups[respin_count].is_empty,
            item_ids = item_ids,
            thunders = save_data.thunders or {},
            current_win_chip = save_data.respin_current_win_chip or 0,
            respin_acc_chip = save_data.respin_acc_chip or 0
        }
    end

    -- 初始化superstack元素
    local super_stack_config = CommonCal.Calculate.get_config(player, game_room_config.game_name.."SuperStackFeatureConfig")
    if not save_data.super_stack_replace_item_id or save_data.super_stack_replace_item_id <= 0 then
        local super_stack_replace_item_id = SlotsGameCal.Calculate.SuperStackReplace(player, nil, game_room_config, Types.SuperStack, super_stack_config)
        save_data.super_stack_replace_item_id = super_stack_replace_item_id
    end
    bonus_info.super_stack_replace_item_id = save_data.super_stack_replace_item_id

    return bonus_info
end

IsBonusGame = function(game_room_config, player, player_game_info)
    return false
end

local function RandRespin(session, is_free_spin, game_room_config, player_game_info, amount)
    local player = session.player
    local lineNum = LineNum[game_room_config.game_type]()
    local config_table = SlotsGameCal.Calculate.GetMapConfigTable(session, game_room_config, player_game_info, amount * lineNum)
    local reel_file = config_table.base_respin_config

    local config = CommonCal.Calculate.get_config(player, reel_file)[1]

    if not is_free_spin then
        local weights = {
            config.base_feature_probability[1],
            config.base_feature_probability[2],
            1 - config.base_feature_probability[1] - config.base_feature_probability[2]
        }

        local rand_index = math.rand_weight(player, weights)

        if rand_index == 1 then
            return true, 3
        end

        if rand_index == 2 then
            return true, 4
        end

        return false
    end

    local weights = {
        config.freespin_feature_probability[1],
        config.freespin_feature_probability[2],
        1 - config.freespin_feature_probability[1] - config.freespin_feature_probability[2]
    }

    local rand_index = math.rand_weight(player, weights)

    if rand_index == 1 then
        return true, 3
    end

    if rand_index == 2 then
        return true, 4
    end

    return false
end

local function CheckRespin(origin_result, type)
    -- body
    local counter = 0

    for i = 1, #origin_result do
        if(origin_result[i][1] == type.Zeus) then
            counter = counter + 1
        end
    end

    return counter >= 3, count  
end

local function GenerateGroups(player, group_count, zeus_count, rand_pos, empty_pos)
    table.sort(rand_pos, function(a, b)
        return a < b
    end)

    local groups = {}

    for i = 1, #rand_pos do
        table.insert(groups, {
            group_id = i,
            is_empty = false,
            zeus_count = rand_pos[i] - (rand_pos[i - 1] or 0)
        })
    end

    -- 最后一个
    table.insert(groups, {
        group_id = #rand_pos + 1,
        is_empty = false,
        zeus_count = zeus_count - (rand_pos[#rand_pos] or 0)
    })

    table.sort(groups, function(a, b)
        return a.zeus_count > b.zeus_count
    end)

    -- 设置顺序
    local order_config = CommonCal.Calculate.get_config(player, "ThunderZeusRespinOrderConfig")
    local weights = {}

    for i = 1, #order_config do
        table.insert(weights, order_config[i].weight[group_count])
    end

    local pos = {}
    local new_groups = {}
    for i = 1, group_count do
        table.insert(pos, i)
    end

    for i = 1, group_count do
        local index = math.rand_weight(player, weights)
        local val = pos[index]
        table.remove(weights, index)
        table.remove(pos, index)
        table.insert(new_groups, groups[val])
    end

    groups = new_groups

    -- 插入空白
    for i = 1, #empty_pos do
        table.insert(groups, empty_pos[i], {
            is_empty = true
        })
    end

    -- 最后一组插入一个empty
    if zeus_count <= 15 then
        table.insert(groups, {
            is_empty = true
        })
    end

    return groups
end

local function GenerateRowCol(player, result, reel)
    local weights = {}
    local pos = {}

    for i = 1, #result do
        result[i][1] = 0
        for j = 2, #result[i] do
            if result[i][j] ~= 13 and result[i][j] > 0 then
                table.insert(weights, reel[j - 1])
                table.insert(pos, {
                    row = i,
                    col = j
                })
            else
                result[i][j] = 0
            end
        end
    end

    local index = math.rand_weight(player, weights)
    local row = pos[index].row
    local col = pos[index].col
    local val = result[row][col]
    result[row][col] = 0
    return row, col, val
end

local function GenerateResult(player, result, reel, count)
    local v = {}
    for i = 1, #result do
        v[i] = {}
        v[i][1] = 3
        for j = 2, #result[i] do
            v[i][j] = 0
        end
    end

    for i = 1, count do
        local row, col, val = GenerateRowCol(player, result, reel)
        v[row][col] = val
    end

    return v
end

local function MergeResult(r1, r2)
    local r = {}
    for i = 1, #r1 do
        r[i] = {}
        r[i][1] = 3
        for j = 2, #r1[i] do
            if r1[i][j] ~= 13 and r1[i][j] > 0 then
                r[i][j] = r1[i][j]
            elseif r2[i][j] ~= 13 and r2[i][j] > 0 then
                r[i][j] = r2[i][j]
            else
                r[i][j] = 13
            end
        end
    end
    return r
end

local function PrintResult(i, is_empty, r)
    local s = ""
    local e = 0
    if is_empty then
        e = 1
    end

    for i = 1, #r do
        for j = 1, #r[i] do
            -- if r[i][j] == 13 then r[i][j] = 0 end
            s = s .. r[i][j] .. " "
        end
        s = s .. "\n"
    end
    print("" .. i .. " " .. e .. "-------\n" .. s)
end

local function GenerateResults(player, origin_result, groups, zeus_count)
    local pos_config = CommonCal.Calculate.get_config(player, "ThunderZeusRespinSymbolSelectConfig")
    local reel = pos_config[1].reel
    local result = table.DeepCopy(origin_result)

    for i = 1, #groups do
        if not groups[i].is_empty then
            groups[i].result = GenerateResult(player, result, reel, groups[i].zeus_count)
        else
            groups[i].result = GenerateResult(player, result, reel, 0)
        end
    end

    groups[1].result = MergeResult(groups[1].result, groups[1].result)
    -- PrintResult(1, groups[1].is_empty, groups[1].result)
    for i = 2, #groups do
        groups[i].result = MergeResult(groups[i - 1].result, groups[i].result)
        -- PrintResult(i, groups[i].is_empty, groups[i].result)
    end

    -- 特殊处理16个宙斯满了的情况，删除后面的空白
    if zeus_count == 16 then
        for i = #groups, 1, -1 do
            if groups[i].is_empty then
                table.remove(groups, #groups)
            else
                break
            end
        end
    end
end

local function RespinBudget(session, save_data, groups, has_empty)
    if not has_empty and save_data.respin_count ~= #groups then
        LOG(RUN, INFO).Format("[SlotsThunderZeusSpin][RespinBudget] 提前集齐16个宙斯！")
    end

    local total_win_chip = 0
    local slots_win_chip = 0

    local prize_items = {}

    if save_data.respin_count == #groups or not has_empty then
        total_win_chip = save_data.respin_win_chip
        slots_win_chip = total_win_chip
        prize_items = save_data.prize_items
        save_data.groups = nil
        save_data.respin_count = nil
        save_data.respin_win_chip = nil
        save_data.thunders = nil
        save_data.jackpot_win_chip = nil
        save_data.prize_items = nil
        save_data.feature_spin_count = 0

        FeverQuestCal.OnLightingRespinEnd(session, total_win_chip)
    end

    return total_win_chip, slots_win_chip, prize_items
end

local function GetPlayerJackpots(player, bet_amount)
    local config = CommonCal.Calculate.get_config(player, "ThunderZeusJackpotConfig")
    local level = player.character.level
    local levels = {1, 10 , 25, 35}
    for i=4, 1, -1 do
        if level >= levels[i] then
            level = levels[i]
            break
        end
    end
    local ids = {}
    for i = 1, 5 do
        local limit = config[i].jackpot_limit
        if bet_amount >= limit[level] then
            table.insert(ids, i)
        end
    end
    return ids
end

-- 随机jackpot值
local function AddJackpotInfo(player, save_data, total_amount, pre_action_list, thunders)
    local weights = {}
    local config = CommonCal.Calculate.get_config(player, "ThunderZeusJackpotConfig")

    local ids = GetPlayerJackpots(player, total_amount)

    for i = 1, #config do
        local limit = true
        for j = 1, #ids do
            if ids[j] == i then
                limit = false
                break
            end
        end
        if limit then
            table.insert(weights, 0)
        else
            table.insert(weights, config[i].hit_weight)
        end
    end

    local jackpot_param_v2 = save_data.jackpot_param_v2
    local total_value = 0
    local win_infos = {}
    for i = 1, #thunders do
        local type = math.rand_weight(player, weights)
        local add_value = CommonCal.Calculate.GetJackpotPoolChipVal(jackpot_param_v2, type, total_amount) -- 获取jackpot金额
        CommonCal.Calculate.ResetJackpotExtraChip(jackpot_param_v2, type) -- 重置jackpot中的金额
        total_value = total_value + add_value

        table.insert(win_infos, {
            type = type,
            value = add_value
        })

        thunders[i].type = type
        thunders[i].value = add_value

        save_data.thunders = save_data.thunders or {}
        table.insert(save_data.thunders, thunders[i])
    end

    table.insert(pre_action_list, {
        action_type = ActionType.ActionTypes.WinGameJackpot,
        win_infos = win_infos
    })

    return total_value
end

local function ModifyFirstColZeusResult(player, origin_result)
    local item_id = math.random_ext(player, 4, 11)
    if math.rand_prob(player, 0.5) then
        origin_result[1][1] = item_id
    else
        origin_result[4][1] = item_id
    end
end

-- 如果限制没有宙斯，修改分组
local function JackpotLevelLimit(groups, player, bet_amount)
    local ids = GetPlayerJackpots(player, bet_amount)

    if #ids > 0 then
        return
    end

    for i = 1, #groups do
        local result = groups[i].result
        for r = 1, #result do
            for c = 1, #result[r] do
                if result[r][c] == Types.Jackpot then
                    result[r][c] = Types.Zeus
                end
            end
        end
    end
end

RespinSpawn = function(session, game_type, is_free_spin, game_room_config, amount, player_feature_condition, 
    extern_param, player_game_info, first_col_count, player_game_status)
    local player = session.player
    if is_free_spin then
        LOG(RUN, INFO).Format("[SlotsThunderZeusSpin][Respin] free spin中进入respin")
    end

    local save_data = player_game_info.save_data
    local lineNum = LineNum[player_game_info.game_type]()
    local total_amount = lineNum * amount

    local reel_file = "ThunderZeusRespinReelConfig"
    local config_table = SlotsGameCal.Calculate.GetMapConfigTable(session, game_room_config, player_game_info, amount * lineNum)
    reel_file = config_table.respin_reel_config
    local weight_file = config_table.respin_reel_weight_config

    local origin_result, reel_file_name = SlotsGameCal.Calculate.GenItemResultWithWeight(player, game_type, is_free_spin, 
        game_room_config, reel_file, weight_file)

    local final_result = table.DeepCopy(origin_result)

    -- 赔率配置
    local payrate_file = CommonCal.Calculate.get_config(player, game_room_config.game_name .. "PayrateConfig")
    local left_or_right = game_room_config.direction_type

    local type = _G[game_room_config.game_name .. "TypeArray"].Types

    -- 获得连线结果
    local prize_items, total_payrate = SlotsGameCal.Calculate.GenPrizeInfo(final_result, game_room_config, payrate_file, left_or_right, type, nil, nil, bet_ratio)

    -- 保存起来最后一次发送
    save_data.prize_items = prize_items
    prize_items = {}

    local zeus_count = 0
    for i = 1, #origin_result do
        for j = 2, #origin_result[i] do
            if origin_result[i][j] == type.Zeus or origin_result[i][j] == type.Jackpot then
                zeus_count = zeus_count + 1
            end
        end
    end

    -- 读取宙斯count config，设置分组数量
    local count_config = CommonCal.Calculate.get_config(player, "ThunderZeusRespinCountConfig")
    local count_weights = {}
    for i = 1, 16 do
        local val = count_config[i].count[zeus_count - 1]
        table.insert(count_weights, val)
    end

    local count_index = math.rand_weight(player, count_weights)
    local group_count = count_index
    -- 随机插入位置
    local positions = {}
    local positions_val = {}
    for i = 1, zeus_count - 1 do
        table.insert(positions, 1)
        table.insert(positions_val, i)
    end

    local rand_pos = {}
    for i = 1, group_count - 1 do
        local index = math.rand_weight(player, positions)
        local val = positions_val[index]
        table.remove(positions, index)
        table.remove(positions_val, index)
        table.insert(rand_pos, val)
    end

    -- 分组完成，计算空白的位置
    local empty_config = CommonCal.Calculate.get_config(player, "ThunderZeusRespinEmptyConfig")
    local weights = {}
    for i = 1, #empty_config do
        table.insert(weights, empty_config[i].empty_weight[group_count])
    end
    -- 插入2次空白
    local empty_pos = {}
    for i = 1, 2 do
        local index = math.rand_weight(player, weights)
        table.insert(empty_pos, index)
    end

    -- 开始对每一组中的元素进行位置抽取
    local groups = GenerateGroups(player, group_count, zeus_count, rand_pos, empty_pos)

    -- 计算位置
    GenerateResults(player, origin_result, groups, zeus_count)

    -- 如果level限制没有宙斯，修改jackpot为宙斯 完成分组
    JackpotLevelLimit(groups, player, total_amount)

    local origin_result = table.DeepCopy(groups[1].result)
    local total_win_chip = 0
    local pre_action_list = {}
    local final_result = table.DeepCopy(groups[1].result)
    local free_spin_bouts = 0

    local slots_win_chip = 0
    local special_parameter = {}

    if groups[1].is_empty then
        save_data.max_show_respin = 3
    else
        save_data.max_show_respin = 3 + 1
    end

    table.insert(pre_action_list, {
        action_type = ActionType.ActionTypes.Respin,
        max_respin = #groups,
        current_respin = 1,
        max_show_respin = save_data.max_show_respin,
        is_empty = groups[1].is_empty
    })

    -- 闪电个数
    local thunders = WinJackpot(groups[1].result, nil)

    local jackpot_win_chip = 0

    if #thunders > 0 then
        save_data.jackpot_win_chip = save_data.jackpot_win_chip or 0
        jackpot_win_chip = AddJackpotInfo(player, save_data, total_amount, pre_action_list, thunders)
    end

    local slots_spin_list = {}

    save_data.respin_count = 1
    total_win_chip, slots_win_chip, prize_items = RespinBudget(session, save_data, groups, true)
    total_win_chip = total_win_chip + jackpot_win_chip

    -- 将连线结果放入all_prize_list
    local all_prize_list = {}
    table.insert(all_prize_list, prize_items)

    if first_col_count == 3 then
        ModifyFirstColZeusResult(player, origin_result)
    end

    -- 底层不完善的问题
    if not is_free_spin then
        player_game_info.free_total_win = 0
    end

    player_game_info.free_total_win = player_game_info.free_total_win or 0
    save_data.respin_current_win_chip = player_game_info.free_total_win + jackpot_win_chip
    save_data.respin_acc_chip = jackpot_win_chip

    table.insert(slots_spin_list, {
        item_ids = json.encode(SlotsGameCal.Calculate.TransResultToCList(origin_result, game_room_config)),
        prize_items = prize_items,
        win_chip = total_win_chip,
        pre_action_list = json.encode(pre_action_list),
        final_item_ids = json.encode(SlotsGameCal.Calculate.TransResultToCList(final_result, game_room_config))
    })

    -- 客户端接收的表
    local formation_list = {}
    table.insert(formation_list, {
        slots_spin_list = slots_spin_list,
        id = 1
    })

    -- 保存所有数据
    save_data.groups = groups
    save_data.respin_count = 1
    -- print("####--- respin first:", save_data.respin_count, #groups)
    save_data.respin_win_chip = total_payrate * amount
    save_data.feature_spin_count = #groups - 1
    save_data.feature_spin_type = 1
    save_data.respin_is_free_spin = is_free_spin

    -- 消耗一次free spin
    if is_free_spin then
        save_data.total_free_spin_times = save_data.total_free_spin_times or 0
        save_data.total_free_spin_times = save_data.total_free_spin_times + 1
    end
    
    GameStatusCal.Calculate.AddStatusImmediately(player_game_status, GameStatusDefine.AllTypes.ReSpinGame, #groups, amount)

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

function SlotsThunderZeusSpin:ReSpin()
    local player = self.parameters.player
    local session = self.parameters.session
    local player_game_info = self.parameters.player_game_info
    local special_parameter = self.parameters.special_parameter
    local is_free_spin = self.parameters.is_free_spin
    local game_room_config = self.parameters.game_room_config
    local player_game_status = self.parameters.player_game_status
    local amount = self.parameters.amount
    local game_type = self.parameters.game_type
    local player_feature_condition = self.parameters.player_feature_condition
    local extern_param = self.parameters.extern_param

    local type = _G[game_room_config.game_name .. "TypeArray"].Types
    local save_data = player_game_info.save_data
    local lineNum = LineNum[player_game_info.game_type]()
    local total_amount = lineNum * amount

    local groups = save_data.groups

    -- 更新feature_spin_count
    save_data.feature_spin_count = save_data.feature_spin_count - 1

    local respin_count = save_data.respin_count + 1
    local origin_result = groups[respin_count].result
    local prize_items = {}
    local total_win_chip = 0
    local pre_action_list = {}
    local final_result = groups[respin_count].result
    local free_spin_bouts = 0
    local slots_win_chip = 0
    local special_parameter = {}

    if groups[respin_count].is_empty then
        save_data.max_show_respin = save_data.max_show_respin or 0
    else
        save_data.max_show_respin = (save_data.max_show_respin or 0) + 1
    end

    table.insert(pre_action_list, {
        action_type = ActionType.ActionTypes.Respin,
        max_respin = #groups,
        max_show_respin = save_data.max_show_respin,
        current_respin = respin_count,
        is_empty = groups[respin_count].is_empty
    })

    local thunders = WinJackpot(groups[respin_count].result, groups[respin_count - 1].result)

    local jackpot_win_chip = 0

    if thunders and #thunders > 0 then
        save_data.jackpot_win_chip = save_data.jackpot_win_chip or 0
        jackpot_win_chip = AddJackpotInfo(player, save_data, total_amount, pre_action_list, thunders)
        save_data.respin_current_win_chip = (save_data.respin_current_win_chip or 0) + jackpot_win_chip
        save_data.respin_acc_chip = (save_data.respin_acc_chip or 0) + jackpot_win_chip
    end

    -- 将连线结果放入all_prize_list
    local slots_spin_list = {}

    save_data.respin_count = save_data.respin_count + 1
    -- print("#### current respin count:", save_data.respin_count, #groups)

    -- 检查是否集齐16个宙斯
    local has_empty = false
    for i = 1, #origin_result do
        for j = 2, #origin_result[i] do
            if origin_result[i][j] == type.Empty then
                has_empty = true
                break
            end
        end
    end

    local respin_win_chip = save_data.respin_win_chip
    total_win_chip, slots_win_chip, prize_items = RespinBudget(session, save_data, groups, has_empty)
    total_win_chip = total_win_chip + jackpot_win_chip

    if save_data.respin_is_free_spin then
        player_game_info.free_total_win = player_game_info.free_total_win or 0
    end

    if total_win_chip > 0 then
        save_data.respin_current_win_chip = (save_data.respin_current_win_chip or 0) + respin_win_chip
        save_data.respin_acc_chip = (save_data.respin_acc_chip or 0) + respin_win_chip
    end

    local all_prize_list = {}
    table.insert(all_prize_list, prize_items)

    table.insert(slots_spin_list, {
        item_ids = json.encode(SlotsGameCal.Calculate.TransResultToCList(origin_result, game_room_config)),
        prize_items = prize_items,
        win_chip = total_win_chip,
        pre_action_list = json.encode(pre_action_list),
        final_item_ids = json.encode(SlotsGameCal.Calculate.TransResultToCList(final_result, game_room_config))
    })

    -- 客户端接收的表
    local formation_list = {}
    table.insert(formation_list, {
        slots_spin_list = slots_spin_list,
        id = 1
    })

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

function SlotsThunderZeusSpin:NormalSpin()
    local player = self.parameters.player
    local player_game_info = self.parameters.player_game_info
    local special_parameter = self.parameters.special_parameter
    local is_free_spin = self.parameters.is_free_spin
    local game_room_config = self.parameters.game_room_config
    local player_game_status = self.parameters.player_game_status
    local amount = self.parameters.amount
    local game_type = self.parameters.game_type
    local player_feature_condition = self.parameters.player_feature_condition
    local extern_param = self.parameters.extern_param

    local session = self.parameters.extern_param.session

    local save_data = player_game_info.save_data

    if save_data.groups then
        print("must be something wrong.")
    end

    save_data.feature_spin_count = 0
    save_data.feature_spin_type = 0

    local lineNum = LineNum[player_game_info.game_type]()
    local total_amount = lineNum * amount

    local type = _G[game_room_config.game_name .. "TypeArray"].Types
    player_game_info.bonus_game_type = 0

    local config_table = SlotsGameCal.Calculate.GetMapConfigTable(session, game_room_config, player_game_info, amount * lineNum)
    local reel_file = nil
    local weight_file = nil

    if is_free_spin then
        reel_file = config_table.feature_reel_config
        weight_file = config_table.feature_reel_weight_config
    else
        reel_file = config_table.base_reel_config
        weight_file = config_table.base_reel_weight_config
    end

    local origin_result, reel_file_name = SlotsGameCal.Calculate.GenItemResultWithWeight(player, game_type, is_free_spin, 
        game_room_config, reel_file, weight_file)

    local is_respin, count = CheckRespin(origin_result,type)

    if is_respin then
        local free_spin_bouts_left = GameStatusCal.Calculate.GetFreeSpinBouts(player_game_status)
        return RespinSpawn(session, game_type, is_free_spin, game_room_config, amount, player_feature_condition, 
            extern_param, player_game_info, count, player_game_status)
    end

    -- 如果是freespin，进行替换
    local super_stack_pos_list = SlotsGameCal.Calculate.GetItemPosition(origin_result, game_room_config, Types.SuperStack)

	if #super_stack_pos_list > 0 then
        for k,v in ipairs(super_stack_pos_list) do
            origin_result[v.row][v.col] = save_data.super_stack_replace_item_id
        end
    end

    -- 行为记录
    local pre_action_list = {}
    local final_result = table.DeepCopy(origin_result)

    -- 赔率配置
    local payrate_file = CommonCal.Calculate.get_config(player, game_room_config.game_name .. "PayrateConfig")
    -- 连线规则, 1左连线，2右, 3左右连线
    local left_or_right = game_room_config.direction_type

    -- 获得连线结果
    local prize_items, total_payrate = SlotsGameCal.Calculate.GenPrizeInfo(final_result, game_room_config, payrate_file, left_or_right, type, nil, nil, bet_ratio)

    -- 将连线结果放入all_prize_list
    local all_prize_list = {}
    table.insert(all_prize_list, prize_items)

    -- slots赢取的筹码 = 倍率和 * 筹码
    local slots_win_chip = total_payrate * amount

    -- 赢取的总筹码,slots筹码+游戏等特殊筹码
    local total_win_chip = slots_win_chip

    -- 更新jackpot
    CommonCal.Calculate.UpdateJackpotExtraChip(is_free_spin, "ThunderZeusJackpotConfig", save_data, total_amount, pre_action_list)

    -- FreeSpin判断处理
    local free_spin_bouts = SlotsGameCal.Calculate.FreeSpinCheck(player, final_result, game_room_config, is_free_spin, type.Scatter)

    if free_spin_bouts and free_spin_bouts > 0 then
        -- print("free_spin_bouts:", free_spin_bouts)
    end

    -- 最后一次数据记录
    local slots_spin_list = {}

    local free_spin_bouts_left = GameStatusCal.Calculate.GetFreeSpinBouts(player_game_status)

    -- 处理最后发送总值总次数
    if is_free_spin then
        save_data.total_free_spin_times = save_data.total_free_spin_times or 0
        save_data.total_free_spin_times = save_data.total_free_spin_times + 1
    else
        save_data.total_free_spin_times = nil
    end

    if is_free_spin and free_spin_bouts > 0 then
        player_game_info.free_spin_num = free_spin_bouts
    end

    if free_spin_bouts > 0 then
        GameStatusCal.Calculate.AddGameStatus(player_game_status, GameStatusDefine.AllTypes.FreeSpinGame, free_spin_bouts, 1, amount)
    end

    if is_free_spin and free_spin_bouts_left == 0 and free_spin_bouts == 0 then
        player_game_info.free_total_win = player_game_info.free_total_win or 0
        local free_total_win = player_game_info.free_total_win + total_win_chip
        --assert(save_data.total_free_spin_times ~= 11)
    end

    if is_free_spin then
        local super_stack_config = CommonCal.Calculate.get_config(player, game_room_config.game_name.."SuperStackFeatureConfig")
        save_data.super_stack_replace_item_id = SlotsGameCal.Calculate.SuperStackReplace(player, nil, game_room_config, Types.SuperStack, super_stack_config)

        local action_super_stack = {
            action_type = ActionType.ActionTypes.SuperStackReplaceItemId,
            super_stack_replace_item_id = save_data.super_stack_replace_item_id or 0
        }

        table.insert(pre_action_list, action_super_stack)
    end

    table.insert(slots_spin_list, {
        item_ids = json.encode(SlotsGameCal.Calculate.TransResultToCList(origin_result, game_room_config)),
        prize_items = prize_items,
        win_chip = total_win_chip,
        slots_win_chip = slots_win_chip,
        pre_action_list = json.encode(pre_action_list),
        final_item_ids = json.encode(SlotsGameCal.Calculate.TransResultToCList(final_result, game_room_config))
    })

    -- 客户端接收的表
    local formation_list = {}
    table.insert(formation_list, {
        slots_spin_list = slots_spin_list,
        id = 1
    })

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
