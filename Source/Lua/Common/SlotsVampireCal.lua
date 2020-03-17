module("SlotsVampireCal", package.seeall)
require "Util/TableExt"
require "Common/CommonCal"

Const = {
    Lines = {
        [1] = {4,3,3,3,4},
        [2] = {3,2,2,2,3},
        [3] = {2,1,1,1,2},
        [4] = {1,1,1,1,1},
        [5] = {2,2,2,2,2},
        [6] = {3,3,3,3,3},
        [7] = {1,1,2,3,4},
        [8] = {4,3,2,1,1},
        [9] = {4,3,2,3,4},
        [10] = {3,2,1,2,3},
        [11] = {1,1,2,1,1},
        [12] = {2,2,3,2,2},
        [13] = {3,3,3,2,2},
        [14] = {2,2,2,1,1},
        [15] = {2,1,1,2,3},
        [16] = {3,2,2,3,4},
        [17] = {3,3,2,3,3},
        [18] = {2,2,1,2,2},
        [19] = {2,1,2,1,2},
        [20] = {1,1,3,1,1},
        [21] = {4,3,1,3,4},
        [22] = {3,3,1,3,3},
        [23] = {2,1,3,1,2},
        [24] = {2,3,1,3,2},
        [25] = {3,1,3,1,3},
    },

    Types = {
        MaleVampire = 1,--男吸血鬼
        FemaleVampire = 2,--女吸血鬼
        CandleStick = 3,--烛台
        Cross = 4,--十字架
        HolyWater = 5,--圣水
        King = 6,--K
        Queue = 7,--Q
        Jack = 8,--J
        Scatter = 9,--棺材
        Wild = 10,--书本Wild
    },

    PrizeDirection = {
		LEFT = 1,
		RIGHT = 2,
	}
}

Util = {
    GenWildReplaceValue = function( line_data, wild_pos )
        if wild_pos == 1 then
            for i = 2, 5, 1 do
                if line_data[i] == Const.Types.Scatter or line_data[i] == Const.Types.Bonus then return end
                if line_data[i] ~= Const.Types.Wild then
                    return  line_data[i]
                end
            end
        elseif wild_pos == 5 then
            for i = 4, 1, -1 do
                if line_data[i] == Const.Types.Scatter or line_data[i] == Const.Types.Bonus then return end
                if line_data[i] ~= Const.Types.Wild then
                    return line_data[i]
                end
            end
        else
            local left_value
            for i = wild_pos-1, 1, -1 do
                if line_data[i] == Const.Types.Scatter or line_data[i] == Const.Types.Bonus then return end
                if line_data[i] ~= Const.Types.Wild then
                    left_value = line_data[i]
                    break
                end
            end
            local right_value
            for i = wild_pos + 1, 5, 1 do
                if line_data[i] == Const.Types.Scatter or line_data[i] == Const.Types.Bonus then break end
                if line_data[i] ~= Const.Types.Wild then
                    right_value = line_data[i]
                    break
                end
            end
            if left_value then
                return left_value
            else
                return right_value
            end
        end
    end,

    GenWildPos = function(line_data)
        local pos = {}
        for i = 1, 5 do
            if line_data[i] == Const.Types.Wild then
                table.insert(pos, i)
            end
        end
        return pos
    end,

}

Calculate = {
    --产生一行(这里的一行已经将wild换成它可以替换的图标了)的中奖结果
    GenNormalContinueCount = function(line_data)
        local item_id = line_data[1]
        if item_id >= Const.Types.Wild then return nil, nil end
        local continue_count = 1
        for i = 2, 5 do
            if line_data[i] == item_id then
                continue_count = continue_count + 1
            else
                break
            end
        end
        if item_id >= Const.Types.MaleVampire and item_id <= Const.Types.Jack and continue_count >= 3 then
            return item_id, continue_count
        else
            return nil, nil
        end
    end,

    GenWildContinueCount = function(line_data)
        local wild_count = 0
        for i = 1, 5 do
            if line_data[i] == Const.Types.Wild then
                wild_count = wild_count + 1
            else
                break
            end
        end
        return wild_count
    end,

    CompareNormalAndWild = function (player, item_id, continue_count, wild_count, prize_list, direction )
        local VampirePayrateConfig = CommonCal.Calculate.get_config(player, "VampirePayrateConfig")
		local has_normal_prize = item_id and continue_count and (continue_count >= 3)
		local has_wild_prize = wild_count and (wild_count >= 3)
		if has_wild_prize and has_normal_prize then
			local normal_payrate = VampirePayrateConfig[item_id].payrate[continue_count - 2]
			local wild_payrate = VampirePayrateConfig[Const.Types.Wild].payrate[wild_count - 2]
			if normal_payrate >= wild_payrate then
				table.insert(prize_list, {
					item_id = item_id,
					continue_count = continue_count,
					from_index = (direction == Const.PrizeDirection.LEFT) and 1 or (5 - continue_count + 1),
					to_index = (direction == Const.PrizeDirection.LEFT) and continue_count or 5,
				})
			else
				table.insert(prize_list, {
					item_id = Const.Types.Wild,
					continue_count = wild_count,
					from_index = (direction == Const.PrizeDirection.LEFT) and 1 or (5 - wild_count + 1),
					to_index = (direction == Const.PrizeDirection.LEFT) and wild_count or 5,
				})
			end
		elseif has_normal_prize then
			table.insert(prize_list, {
				item_id = item_id,
				continue_count = continue_count,
				from_index = (direction == Const.PrizeDirection.LEFT) and 1 or (5 - continue_count + 1),
				to_index = (direction == Const.PrizeDirection.LEFT) and continue_count or 5,
			})
		elseif has_wild_prize then
            table.insert(prize_list, {
                item_id = Const.Types.Wild,
                continue_count = wild_count,
                from_index = (direction == Const.PrizeDirection.LEFT) and 1 or (5 - wild_count + 1),
                to_index = (direction == Const.PrizeDirection.LEFT) and wild_count or 5,
            })
        end
    end,
    
    GenOneLinePrize = function(player, line_data)
        local prize_list = {}
        
        local wild_pos_list = Util.GenWildPos(line_data)
        local wild_pos_len = #wild_pos_list
        local rep_line_data = table.copy(line_data)
        if wild_pos_len > 0 then
            for i = 1, wild_pos_len do
                local rep_value = Util.GenWildReplaceValue(line_data, wild_pos_list[i])
                if rep_value then
                    rep_line_data[wild_pos_list[i]] = rep_value
                end
            end
        end

        local left_item_id, left_continue_count = Calculate.GenNormalContinueCount(rep_line_data, Const.PrizeDirection.LEFT)
        local left_wild_count = Calculate.GenWildContinueCount(line_data, Const.PrizeDirection.LEFT)

        if ((left_continue_count and left_continue_count >=3) or (left_wild_count and left_wild_count >= 3))
        then
            Calculate.CompareNormalAndWild(player, left_item_id, left_continue_count, left_wild_count, prize_list, Const.PrizeDirection.LEFT)
        end

        return prize_list
    end,

    GenFreeSpinCount = function(player, data)
        local VampireOthersConfig = CommonCal.Calculate.get_config(player, "VampireOthersConfig")
        local scatter_count = 0
        for _, column in ipairs(data) do
            for _, v in ipairs(column) do
                if v == Const.Types.Scatter then
                    scatter_count = scatter_count + 1
                end
            end
        end
        return (scatter_count >= 3) and VampireOthersConfig[1].free_spin_delta or 0
    end,

--产生一列,column表示第几列,allow_wild表示是否能出现wild,config是经过了is_free_spin判断了之后的config
    GenColumn = function(player, config, column)
        local player_id = player.id
        local sequence = config[column].sequence_array
        local sequence_len = #sequence
        local index = math.random_ext(player, 1, sequence_len)

		if (GlobalSlotsTest[player_id] ~= nil)
		then
			sequence, sequence_len, index = CommonCal.Calculate.GetSequence(player_id, column)
		end
        
        
        if column == 1 or column == 5 then
            local index_1, index_2, index_3 = index % sequence_len + 1, (index + 1) % sequence_len + 1, (index + 2) % sequence_len + 1
            return {sequence[index], sequence[index_1], sequence[index_2], sequence[index_3]}
        else
            local index_1, index_2 = index % sequence_len + 1, (index + 1) % sequence_len + 1
            return {sequence[index], sequence[index_1], sequence[index_2]}
        end
    end,

--产生原始序列 5*3 matrix,这个地方和其他玩法不一样,其他玩法是3*5,这个玩法5*3方便计算
    GenItemResult = function(player, is_free_spin)
        local config = is_free_spin and CommonCal.Calculate.get_config(player, "VampireFeatureReelConfig") or CommonCal.Calculate.get_config(player, "VampireBaseReelConfig")
        local reel_file_name = is_free_spin and "VampireFeatureReelConfig" or "VampireBaseReelConfig"

        reel_file_name, config = CommonCal.Calculate.get_new_hand_config(player, is_free_spin, reel_file_name, config, "Vampire")
        
        local result = {}
        for i = 1, 5 do
            result[i] = Calculate.GenColumn(player, config, i)
        end

        return result, reel_file_name
    end,

--将结果的矩阵转换成一维数组
    TransResultToList = function(result)
        local list = {}
        for i = 1, 5 do
            for j = 1, 4 do
                if result[i][j] then
                    table.insert(list, result[i][j])
                end
            end
        end
        return list
    end,

--generate总的中奖信息
    GenPrizeInfo = function(player, result, merge_indexes)
        local VampirePayrateConfig = CommonCal.Calculate.get_config(player, "VampirePayrateConfig")
        local VampireOthersConfig = CommonCal.Calculate.get_config(player, "VampireOthersConfig")
        local prize_info = {}
        local total_payrate = 0
        for line_index, v in ipairs(Const.Lines) do
            local line_data = {}
            for i = 1, 5 do
                --v[i]是行,i是列
                table.insert(line_data, result[i][v[i]])
            end

            ----------is_cross_merge_item,有合并的话,这一线是否经过合并的区域------------
            local is_cross_merge_item
            if merge_indexes then
                is_cross_merge_item = Calculate.IsLineCrossMergeItem(line_index, merge_indexes)
            end

            local one_line_prize = Calculate.GenOneLinePrize(player, line_data)
            for _, item in ipairs(one_line_prize) do
                local config = VampirePayrateConfig[item.item_id]
                if (config ~= nil)
                then 
                    if is_cross_merge_item then
                        item.payrate = config.payrate[item.continue_count - 2] * VampireOthersConfig[1].extra_payrate_multi
                        item.extra_paid = 1
                    else
                        item.payrate = config.payrate[item.continue_count - 2]
                        item.extra_paid = 0
                    end
                    if (item.payrate >0)
                    then
                        item.line_index = line_index
                        table.insert(prize_info, item)
                        total_payrate = total_payrate + item.payrate
                    end
                end
            end
        end
        return prize_info, total_payrate
    end,

    GetMaxBetAmount = function(player)
        local VampireBetAmountConfig = CommonCal.Calculate.get_config(player, "VampireBetAmountConfig")
        local old_req_level = 0
        for k, v in ipairs(VampireBetAmountConfig)
        do
            if (player.character.level >= old_req_level and player.character.level < v.required_level)
            then
                return VampireBetAmountConfig[k - 1].single_amount
            end
            old_req_level = v.required_level
        end

        local max_index = #VampireBetAmountConfig
		if (player.character.level >= VampireBetAmountConfig[max_index].required_level)
		then
			return VampireBetAmountConfig[max_index].single_amount
		end
        return 0
    end,

    CanMergeVampire = function ( result )
        local inner_mat = Calculate.GenInnerMatrix(result)
        
        for i = 1, 2 do
            for j = 1, 2 do
                local items = {}
                items[1] = inner_mat[i][j]
                items[2] = inner_mat[i][j + 1]
                items[3] = inner_mat[i + 1][j]
                items[4] = inner_mat[i + 1][j + 1]
                local can_merge = true
                local org_item = nil

                --col和row都是大table里的row,col不是3*3小表里的索引
                local merge_indexes = {
                    [1] = {col = i + 1, row = j},
                    [2] = {col = i + 1, row = j + 1},
                    [3] = {col = i + 2, row = j},
                    [4] = {col = i + 2, row = j + 1}
                }
                for _,item in ipairs(items) do

                    if item ~= Const.Types.MaleVampire and item ~= Const.Types.FemaleVampire then
                        can_merge = false
                    else
                        if (org_item == nil)
                        then
                            org_item = item
                        elseif (org_item ~= item)
                        then
                            can_merge = false
                        end
                    end
                end
                if can_merge then
                    return true, merge_indexes
                end
            end
        end
        return false, nil
    end,

    TranMergeItemToList = function ( merge_indexes )
        local list = {}
        for _,item in ipairs(merge_indexes) do
            table.insert(list, ((item.row - 1) * 5 + item.col))
        end
        return list
    end,

    --取出中间的3*3矩阵
    GenInnerMatrix = function ( result )
        local inner_mat = {}
        for i = 1, 3 do
            inner_mat[i] = result[i + 1]
        end
        return inner_mat
    end,

    IsLineCrossMergeItem = function ( line_index, merge_indexes )
        local line = Const.Lines[line_index]
        for i = 1, 5 do
            local col = i
            local row = line[i]
            for _, item in ipairs(merge_indexes) do
                if col == item.col and row == item.row then
                    return true
                end
            end
        end
        return false
    end,

    RespinSideLines = function (player, is_free_spin )
        local config = is_free_spin and CommonCal.Calculate.get_config(player, "VampireFeatureReelConfig") or CommonCal.Calculate.get_config(player, "VampireBaseReelConfig")
        local col_1 = Calculate.GenColumn(player, config, 1)
        local col_5 = Calculate.GenColumn(player, config, 5)
        return col_1, col_5
    end,

    ReplaceSideLines = function ( result, col_1, col_5 )
        local rep_result = table.copy(result)
        rep_result[1] = col_1
        rep_result[5] = col_5
        return rep_result
    end,
}
