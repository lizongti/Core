module("SlotsPharaohTreasureCal", package.seeall)
require "Util/TableExt"
require "Common/CommonCal"
Const = {
    Lines = {
        [1] = {2,2,2,2,2},
        [2] = {1,1,1,1,1},
        [3] = {3,3,3,3,3},
        [4] = {1,2,3,2,1},
        [5] = {3,2,1,2,3},
        [6] = {2,1,1,1,2},
        [7] = {2,3,3,3,2},
        [8] = {1,1,2,3,3},
        [9] = {3,3,2,1,1},
        [10] = {2,3,2,1,2},
        [11] = {2,1,2,3,2},
        [12] = {1,2,2,2,1},
        [13] = {3,2,2,2,3},
        [14] = {3,3,2,3,3},
        [15] = {1,1,2,1,1},
        [16] = {3,3,1,3,3},
        [17] = {1,1,3,1,1},
        [18] = {3,2,1,2,1},
        [19] = {1,2,3,2,3},
        [20] = {1,2,1,2,1},
        [21] = {3,2,3,2,3},
        [22] = {3,1,1,1,3},
        [23] = {1,3,3,3,1},
        [24] = {2,3,1,3,2},
        [25] = {2,1,3,1,2}
    },

    Types = {
        Tablet = 1,--石碑
        EyeOfHorus = 2,--荷鲁斯之眼
        PharaohCoffin = 3,--法老棺椁
        Cross = 4,--十字架
        Ace = 5,
        King = 6,
        Queue = 7,
        Jack = 8,
        Bonus = 9,
        Wild = 10,
    },

    PrizeDirection = {
        LEFT = 1,
        RIGHT = 2,
    },

    --某一线对应的第六列的第几行的倍数
    LineMulti = {
        [1] = 2,
        [2] = 1,
        [3] = 3,
        [4] = 1,
        [5] = 3,
        [6] = 2,
        [7] = 2,
        [8] = 3,
        [9] = 1,
        [10] = 2,
        [11] = 2,
        [12] = 1,
        [13] = 3,
        [14] = 3,
        [15] = 1,
        [16] = 3,
        [17] = 1,
        [18] = 1,
        [19] = 3,
        [20] = 1,
        [21] = 3,
        [22] = 3,
        [23] = 1,
        [24] = 2,
        [25] = 2,
    },

    --小游戏中,每一级对应的格子的ID
    LevelIndexes = {
        [1] = {1,2,3,4,5},
        [2] = {6,7,8,9},
        [3] = {10,11,12},
        [4] = {13,14},
        [5] = {15},
    },
}

Util = {
    SliceTable = function ( tab, from_index, to_index )
        local res = {}
        for i = from_index, to_index, 1 do
            table.insert(res, tab[i])
        end
        return res
    end,

    GenWildPos = function(line_data)
		local pos = {}
		for i = 1, 5 do
			if line_data[i] == Const.Types.Wild1 or line_data[i] == Const.Types.Wild2 or line_data[i] == Const.Types.Wild3 then
				table.insert(pos, i)
			end
		end
		return pos
    end,
    
    GenLeftWildReplaceValue = function( line_data, wild_pos)
        if wild_pos == 1 then
			for i = 2, 5, 1 do
                if line_data[i] ~= Const.Types.Wild then
                    return  line_data[i]
                end
            end
        else
            local left_value
			for i = wild_pos-1, 1, -1 do
                if line_data[i] ~= Const.Types.Wild then
                    left_value = line_data[i]
                    break
                end
            end
            if left_value then
                return left_value
            end
		end
		
		return nil
	end,
	
	GenRightWildReplaceValue = function( line_data, wild_pos)
		if wild_pos == 5 then
			for i = 4, 1, -1 do
                if line_data[i] ~= Const.Types.Wild then
                    return  line_data[i]
                end
            end
        else
            local right_value
			for i = wild_pos + 1, 5, 1 do
                if line_data[i] ~= Const.Types.Wild then
                    right_value = line_data[i]
                    break
                end
            end
            if right_value then
                return right_value
            end
		end
		return nil
    end,
}

Calculate = {
    GenNormalContinueCount = function(line_data, direction)
        local start, stop, step
        if direction == Const.PrizeDirection.LEFT then
            start = 1
            stop = 5
            step = 1
        elseif direction == Const.PrizeDirection.RIGHT then
            start = 5
            stop = 1
            step = -1
        end
        if not start or not stop or not step then return end

        local item_id, continue_count
        for i = start, stop, step do
            if item_id then
                if line_data[i] ~= item_id and line_data[i] ~= Const.Types.Wild then
                    continue_count = math.abs(start - i)
                    break
                else
                    continue_count = math.abs(start - i) + 1
                end
            else
                if line_data[i] ~= Const.Types.Wild then
                    item_id = line_data[i]
                end
            end
        end
        return item_id, continue_count
    end,

	IsRepeatedPrize = function(prize_list, item)

		local i = 1
		local is_exist = 0
		while (i <= #prize_list) do
			local v = prize_list[i]
			if (v.item_id == item.item_id and v.continue_count == item.continue_count and v.from_index == item.from_index and v.to_index == item.to_index)
			then
				i = i + 1
				is_exist = 1
			elseif (v.item_id == item.item_id and v.continue_count < item.continue_count)
			then
				table.remove(prize_list, i)  
			else
				i = i + 1
			end
		end

		return is_exist
	end,


    GenWildContinueCount = function(line_data, direction)
        local wild_count = 0
        local start, stop, step
        if direction == Const.PrizeDirection.LEFT then
            start, stop, step = 1, 5, 1
        elseif direction == Const.PrizeDirection.RIGHT then
            start, stop, step = 5, 1, -1
        end
        for i = start, stop, step do
            if line_data[i] == Const.Types.Wild then
                wild_count = wild_count + 1
            else
                break
            end
        end
        return wild_count
    end,

    --比较普通中奖和wild中奖，以赔率大的作为一条中奖项
	CompareNormalAndWild = function (player, item_id, continue_count, wild_count, prize_list, direction )
		local has_normal_prize = item_id and continue_count and (continue_count >= 3)
		local has_wild_prize = wild_count and (wild_count >= 3)
        local PharaohTreasurePayrateConfig = CommonCal.Calculate.get_config(player, "PharaohTreasurePayrateConfig")
		if has_wild_prize and has_normal_prize then
			local normal_payrate = PharaohTreasurePayrateConfig[item_id].payrate[continue_count - 2]
			local wild_payrate = PharaohTreasurePayrateConfig[Const.Types.Wild].payrate[wild_count - 2]
			if normal_payrate >= wild_payrate then
				local item = {
					item_id = item_id,
					continue_count = continue_count,
					from_index = (direction == Const.PrizeDirection.LEFT) and 1 or (5 - continue_count + 1),
					to_index = (direction == Const.PrizeDirection.LEFT) and continue_count or 5,
				}
				if (Calculate.IsRepeatedPrize(prize_list, item) == 0)
				then
					table.insert(prize_list, item)
				end
			else
				local item = {
					item_id = Const.Types.Wild,
					continue_count = wild_count,
					from_index = (direction == Const.PrizeDirection.LEFT) and 1 or (5 - wild_count + 1),
					to_index = (direction == Const.PrizeDirection.LEFT) and wild_count or 5,
				}
				if (Calculate.IsRepeatedPrize(prize_list, item) == 0)
				then
					table.insert(prize_list, item)
				end
			end
		elseif has_normal_prize then
			local item = {
				item_id = item_id,
				continue_count = continue_count,
				from_index = (direction == Const.PrizeDirection.LEFT) and 1 or (5 - continue_count + 1),
				to_index = (direction == Const.PrizeDirection.LEFT) and continue_count or 5,
			}
			if (Calculate.IsRepeatedPrize(prize_list, item) == 0)
			then
				table.insert(prize_list, item)
			end
			
		elseif has_wild_prize then
			local item = {
				item_id = Const.Types.Wild,
				continue_count = wild_count,
				from_index = (direction == Const.PrizeDirection.LEFT) and 1 or (5 - wild_count + 1),
				to_index = (direction == Const.PrizeDirection.LEFT) and wild_count or 5,
			}
			if (Calculate.IsRepeatedPrize(prize_list, item) == 0)
			then
				table.insert(prize_list, item)
			end
		end
    end,

    GenOneLinePrize = function(player, line_data)
		local prize_list = {}

		local wild_pos_list = Util.GenWildPos(line_data)
		local wild_pos_len = #wild_pos_list
		

		local left_rep_line_data = table.copy(line_data)

		if wild_pos_len > 0 then
            for i = 1, wild_pos_len do
                local rep_value = Util.GenLeftWildReplaceValue(line_data, wild_pos_list[i])
                if rep_value then
                    left_rep_line_data[wild_pos_list[i]] = rep_value
                end
            end
		end

		local left_item_id, left_continue_count = Calculate.GenNormalContinueCount(left_rep_line_data, Const.PrizeDirection.LEFT)
		local left_wild_count = Calculate.GenWildContinueCount(line_data, Const.PrizeDirection.LEFT)
		Calculate.CompareNormalAndWild(player, left_item_id, left_continue_count, left_wild_count, prize_list, Const.PrizeDirection.LEFT)

		local right_item_id, right_continue_count = Calculate.GenNormalContinueCount(left_rep_line_data, Const.PrizeDirection.RIGHT)
		local right_wild_count = Calculate.GenWildContinueCount(line_data, Const.PrizeDirection.RIGHT)
		Calculate.CompareNormalAndWild(player, right_item_id, right_continue_count, right_wild_count, prize_list, Const.PrizeDirection.RIGHT)

		local right_rep_line_data = table.copy(line_data)

		if wild_pos_len > 0 then
            for i = 1, wild_pos_len do
                local rep_value = Util.GenRightWildReplaceValue(line_data, wild_pos_list[i])
                if rep_value then
                    right_rep_line_data[wild_pos_list[i]] = rep_value
                end
            end
		end
		

		local left_item_id, left_continue_count = Calculate.GenNormalContinueCount(right_rep_line_data, Const.PrizeDirection.LEFT)
		local left_wild_count = Calculate.GenWildContinueCount(line_data, Const.PrizeDirection.LEFT)
		Calculate.CompareNormalAndWild(player, left_item_id, left_continue_count, left_wild_count, prize_list, Const.PrizeDirection.LEFT)

		local right_item_id, right_continue_count = Calculate.GenNormalContinueCount(right_rep_line_data, Const.PrizeDirection.RIGHT)
		local right_wild_count = Calculate.GenWildContinueCount(line_data, Const.PrizeDirection.RIGHT)
		Calculate.CompareNormalAndWild(player, right_item_id, right_continue_count, right_wild_count, prize_list, Const.PrizeDirection.RIGHT)


		return prize_list
    end,
    
    GetMaxBetAmount = function(player)
        local PharaohTreasureBetAmountConfig = CommonCal.Calculate.get_config(player, "PharaohTreasureBetAmountConfig")
        local old_req_level = 0
        for k, v in ipairs(PharaohTreasureBetAmountConfig)
        do
            if (player.character.level >= old_req_level and player.character.level < v.required_level)
            then
                return PharaohTreasureBetAmountConfig[k - 1].single_amount
            end
            old_req_level = v.required_level
        end

        local max_index = #PharaohTreasureBetAmountConfig
		if (player.character.level >= PharaohTreasureBetAmountConfig[max_index].required_level)
		then
			return PharaohTreasureBetAmountConfig[max_index].single_amount
        end

        return 0
    end,

    GenColumn = function(player, config, column)
        local player_id = player.id
        local sequence = config[column].sequence_array
        local sequence_len = #sequence
        local index = math.random_ext(player, 1, sequence_len)

		if (GlobalSlotsTest[player_id] ~= nil)
		then
			sequence, sequence_len, index = CommonCal.Calculate.GetSequence(player_id, column)
		end
        
        local index_1, index_2 = index % sequence_len + 1, (index + 1) % sequence_len + 1
        return {sequence[index], sequence[index_1], sequence[index_2]}, index
    end,

    GenItemResult = function ( player, feature_file)

        local init_result = {}
        
        local reel_file_name = "PharaohTreasureBaseReelConfig"
        if (feature_file ~= nil and feature_file ~= "")
        then
            reel_file_name = feature_file
        end
        local config = CommonCal.Calculate.get_config(player, reel_file_name)

        reel_file_name, config = CommonCal.Calculate.get_new_hand_config(player, false, reel_file_name, config, "PharaohTreasure", feature_file)
        
    
        for i = 1, 5 do
            init_result[i] = Calculate.GenColumn(player, config, i)
        end

        -- init_result[1][1] = Const.Types.Bonus
        -- init_result[2][2] = Const.Types.Bonus
        -- init_result[3][3] = Const.Types.Bonus

        local tran_result = Calculate.TransResult(init_result)
        local multis = Calculate.GenMulti(player)
        local prize_info, total_payrate = Calculate.GenPrizeInfo(player, tran_result, multis)
        -- local item_result = Calculate.TransResultToList(tran_result)
        return tran_result, prize_info, total_payrate, multis, reel_file_name
    end,

-- --trans 5*3 matrix to 3*5 matrix
    TransResult = function(result)
        local tran_result = {}
        for row = 1, 3 do
            tran_result[row] = {}
            for col = 1, 5 do
                tran_result[row][col] = result[col][row]
            end
        end
        return tran_result
    end,

-- --将3*5的矩阵转换成一维数组,以列优先
    TransResultToList = function(result)
        local list = {}
        for i = 1, 5 do
            for j = 1, 3 do
                table.insert(list, result[j][i])
            end
        end
        return list
    end,

-- --generate总的中奖信息
    GenPrizeInfo = function(player, result, multis)
        local PharaohTreasurePayrateConfig = CommonCal.Calculate.get_config(player, "PharaohTreasurePayrateConfig")
        local prize_info = {}
        local total_payrate = 0
        for line_index, v in ipairs(Const.Lines) do
            local line_data = {}
            for i = 1, 5 do
                --v[i]是行,i是列
                table.insert(line_data, result[v[i]][i])
            end
            local one_line_prize = Calculate.GenOneLinePrize(player, line_data)
            for _, item in ipairs(one_line_prize) do
                if (PharaohTreasurePayrateConfig[item.item_id] ~= nil)
                then
                    local payrate = PharaohTreasurePayrateConfig[item.item_id].payrate[item.continue_count - 2]
                    if (payrate > 0)
                    then
                        local multi = multis[Const.LineMulti[line_index]]
                        item.payrate = payrate * multi
                        item.line_index = line_index
                        table.insert(prize_info, item)
                        total_payrate = total_payrate + item.payrate
                    end
                end
            end
        end
        return prize_info, total_payrate
    end,

    --随出第六列的额外倍数
    GenMulti = function ( player )
        local PharaohTreasureMultiConfig = CommonCal.Calculate.get_config(player, "PharaohTreasureMultiConfig")
        local prob_tab = {}
        for k,v in ipairs(PharaohTreasureMultiConfig) do
            prob_tab[v.multi] = v.prob
        end
        local result = {}
        for i = 1, 3 do
            result[i] = math.rand_weight(player, prob_tab)
        end
        return result
    end,

    TriggerBonus = function ( result )
        local bonus_count = 0
        for i = 1, 3 do
            for j = 1, 5 do
                if result[i][j] == Const.Types.Bonus then
                    bonus_count = bonus_count + 1
                end
            end
        end
        return bonus_count >= 3
    end,

    --生成bonus game一次的结果,如果是选到筹码直接返回倍数,如果是随到upstairs那么返回nil
    GenPickMulti = function ( level, player )
        local PharaohTreasureBonusGameConfig = CommonCal.Calculate.get_config(player, "PharaohTreasureBonusGameConfig")
        local level_len = #PharaohTreasureBonusGameConfig
        if level < 1 or level > level_len then return end
        local prob_array = PharaohTreasureBonusGameConfig[level].prob_array
        local multi_array = PharaohTreasureBonusGameConfig[level].multi_array
        local result_index = math.rand_weight(player, prob_array)

        if (GlobalSlotsTest[player.id] ~= nil and GlobalSlotsTest[player.id].bonus ~= nil)
        then
            if (GlobalSlotsTest[player.id].PharaohTreasureIndex == nil)
            then
                GlobalSlotsTest[player.id].PharaohTreasureIndex = 1
            else
                GlobalSlotsTest[player.id].PharaohTreasureIndex = GlobalSlotsTest[player.id].PharaohTreasureIndex + 1
            end

            if (GlobalSlotsTest[player.id].level ~= level)
            then
                GlobalSlotsTest[player.id].PharaohTreasureIndex = 1
            end
            GlobalSlotsTest[player.id].level = level
            return GlobalSlotsTest[player.id].bonus[level][GlobalSlotsTest[player.id].PharaohTreasureIndex]
        end
        return multi_array[result_index]
    end,

    --把win_chip floor掉,为防止客户端出现3.75k这样的数据,服务器把pick得到的筹码按K(千)和M(Millon)floor一下
    FloorWinChip = function(win_chip)
        if win_chip >= 1000000000 then
            return math.floor(win_chip / 100000000) * 100000000
        elseif win_chip >= 1000000 then
            return math.floor(win_chip / 100000) * 100000
        elseif win_chip >= 1000 then
            return math.floor(win_chip / 100) * 100
        else
            return win_chip
        end
    end,

    --检查玩家是否是选择到了这一排的最后一个,如果是那么一定出upstairs,如果不是就按GenPickMulti来正常随
    CheckIfGenUpstairs = function(level, history)
        if level > 5 or level < 1 then return end
        local indexes = Const.LevelIndexes[level]
        local count = #indexes

        local chosen_count = 0
        for _,v in ipairs(indexes) do
            for _,v1 in ipairs(history) do
                --如果这一层已经出了上升的箭头,直接返回false
                if v1.win_chip == 0 then
                    --查看层数是否一样
                    local isSameLv = 0
                    for _, detail in ipairs(indexes) do
                        if (detail == v1.pick_index)
                        then
                            isSameLv = 1
                            break
                        end
                    end
                    if (isSameLv == 1)
                    then
                        return false
                    end
                end
                if v1.pick_index == v then
                    chosen_count = chosen_count + 1
                end
            end
        end
        --如果这一级只剩下一个没有选了,那么直接给升级
        if count - chosen_count == 1 then
            return true
        end
        return false
    end,
}
