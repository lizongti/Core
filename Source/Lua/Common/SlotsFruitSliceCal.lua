module("SlotsFruitSliceCal", package.seeall)
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
		Pitaya = 1,
		Pomegranate = 2,
		Pineapple = 3,
		Watermelon = 4,
		Banana = 5,
		Kiwifruit = 6,
		Lemon = 7,
		Apple = 8,
		Strawberry = 9,
		Cherry = 10,
		Wild = 11,
		Bonus = 12,
	},

	PrizeDirection = {
		LEFT = 1,
		RIGHT = 2,
	}
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
			if line_data[i] == Const.Types.Wild then
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

	GenWildReplaceValue = function( line_data, wild_pos)
        if wild_pos == 1 then
			for i = 2, 5, 1 do
                if line_data[i] ~= Const.Types.Wild then
                    return  line_data[i]
                end
            end
        elseif wild_pos == 5 then
			for i = 4, 1, -1 do
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
            local right_value
			for i = wild_pos + 1, 5, 1 do
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
		if not start or not stop or not step 
		then 
			return 
		end

		local item_id = 0
		local continue_count = 0
		for i = start, stop, step do
			if line_data[i] == Const.Types.Bonus then
				break
			end
			if item_id ~= 0 then
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

	GetMaxBetAmount = function(player)
		local FruitSliceBetAmountConfig = CommonCal.Calculate.get_config(player, "FruitSliceBetAmountConfig")

        local old_req_level = 0
        for k, v in ipairs(FruitSliceBetAmountConfig)
        do
            if (player.character.level >= old_req_level and player.character.level < v.required_level)
            then
                return FruitSliceBetAmountConfig[k - 1].single_amount
            end
            old_req_level = v.required_level
		end
		
		local max_index = #FruitSliceBetAmountConfig
		if (player.character.level >= FruitSliceBetAmountConfig[max_index].required_level)
		then
			return FruitSliceBetAmountConfig[max_index].single_amount
		end
        return 0
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

--比较普通中奖和wild中奖，以赔率大的作为一条中奖项
	CompareNormalAndWild = function (player, item_id, continue_count, wild_count, prize_list, direction )
		local FruitSlicePayrateConfig = CommonCal.Calculate.get_config(player, "FruitSlicePayrateConfig")

		local has_normal_prize = item_id and continue_count and (continue_count >= 3)
		local has_wild_prize = wild_count and (wild_count >= 3)

		if has_wild_prize and has_normal_prize then
			local normal_payrate = FruitSlicePayrateConfig[item_id].payrate[continue_count - 2]
			local wild_payrate = FruitSlicePayrateConfig[Const.Types.Wild].payrate[wild_count - 2]
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

		--LOG(RUN, INFO).Format("[SlotsBacktoJurassic][GenOneLinePrize] prize_list is: %s", Table2Str(prize_list))

		return prize_list
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

	GenItemResult = function (player)
		local init_result = {}
		local col_start_index = {}
		
		local reel_file_name = "FruitSliceBaseReelConfig"
		local config = CommonCal.Calculate.get_config(player, reel_file_name)

		reel_file_name, config = CommonCal.Calculate.get_new_hand_config(player, false, reel_file_name, config, "FruitSlice")

		for i = 1, 5 do
			init_result[i], col_start_index[i] = Calculate.GenColumn(player, config, i)
		end
		local FruitSliceBaseReelConfig = CommonCal.Calculate.get_config(player, "FruitSliceBaseReelConfig")
		local tran_init_result = Calculate.TransResult(init_result)
		local all_prize = {}
		local all_total_payrate = {}
		local all_drop_items = {}
		local all_erase_items = {}
		local erase_time = 1--第几次消除,第n次消除的赔率会乘以一个系数
		local one_time_prize, one_time_payrate = Calculate.GenPrizeInfo(player, tran_init_result, erase_time)
		erase_time = erase_time + 1
		local result_last_time = table.copy(init_result)
		
		while #one_time_prize > 0 and one_time_payrate > 0 do
			table.insert(all_prize, {prize_items = one_time_prize})
			table.insert(all_total_payrate, one_time_payrate)
			
			--计算要掉落的item, 计算要消除的item
			local erase_items = Calculate.GenEraseItems(one_time_prize)
			table.insert(all_erase_items, {erase_items = erase_items})

			local drop_items = {}
			local col_drop_count = Calculate.GenColDropCount(erase_items)
			for i = 1, 5 do
				local drop_item_ids = {}
				if col_drop_count[i] then
					local start_index = col_start_index[i]
					local sequence = FruitSliceBaseReelConfig[i].sequence_array
					local sequence_len = #sequence
					if (GlobalSlotsTest[player.id] ~= nil)
					then
						sequence, sequence_len, index = CommonCal.Calculate.GetSequence(player.id, i)
					end

					for j = col_drop_count[i], 1, -1  do
						local drop_item_index = (start_index - j - 1) % sequence_len + 1
                        local drop_item_id = sequence[drop_item_index]
						table.insert(drop_item_ids, drop_item_id)
					end
                    col_start_index[i] = (col_start_index[i] - col_drop_count[i] - 1) % sequence_len + 1
				end
				table.insert(drop_items, {item_ids = drop_item_ids})
			end
			table.insert(all_drop_items, {drop_items = drop_items})

			Calculate.GenResultAfterDrop(result_last_time, erase_items, drop_items)
			local tran_result_last_time = Calculate.TransResult(result_last_time)
			one_time_prize, one_time_payrate = Calculate.GenPrizeInfo(player, tran_result_last_time, erase_time)
			erase_time = erase_time + 1
			if (GlobalSlotsTest[player.id] ~= nil)
			then
				GlobalSlotsTest[player.id].loopNum = GlobalSlotsTest[player.id].loopNum + 1
			end
		end

		local trigger_bonus = Calculate.TriggerBonus(result_last_time)

		return tran_init_result, all_prize, all_drop_items, all_erase_items, all_total_payrate, trigger_bonus, reel_file_name
	end,

	GenResultAfterDrop = function ( result_last_time, erase_items, drop_items )
		for _,v in ipairs(erase_items) do
			result_last_time[v.col][v.row] = nil
		end
		for i = 1, 5 do
			local j = 1
			while j <= #result_last_time[i] do
				if not result_last_time[i][j] then
					table.remove(result_last_time[i], j)
				else
					j = j + 1
				end
			end
		end

		for i = 1, 5 do
			local drop_item_ids = drop_items[i].item_ids
			for j = #drop_item_ids, 1, -1 do
				table.insert(result_last_time[i], 1, drop_item_ids[j])
			end
		end
	end,

	GenEraseItems = function ( prize_list )
		local erase_items = {}
		for _, prize_item in ipairs(prize_list) do
			local line = Const.Lines[prize_item.line_index]
			for i = prize_item.from_index, prize_item.to_index do
				local row = line[i]
				local col = i
				Calculate.UnrepeatedInsert(erase_items, {row = row, col = col})
			end
		end
		return erase_items
	end,

	GenColDropCount = function ( erase_items )
		local col_drop_count = {}
		for _,v in ipairs(erase_items) do
			col_drop_count[v.col] = col_drop_count[v.col] and (col_drop_count[v.col] + 1) or 1
		end
		return col_drop_count
	end,

	UnrepeatedInsert = function ( all_items, new_item )
		for _, v in ipairs(all_items) do
			if v.row == new_item.row and v.col == new_item.col then
				return
			end
		end
		table.insert(all_items, new_item)
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
	GenPrizeInfo = function(player, result, erase_time)
		local FruitSliceMultiConfig = CommonCal.Calculate.get_config(player, "FruitSliceMultiConfig")

		local FruitSlicePayrateConfig = CommonCal.Calculate.get_config(player, "FruitSlicePayrateConfig")
		
		local prize_info = {}
		local total_payrate = 0
		local real_erase_time = math.min(erase_time, #FruitSliceMultiConfig)
		local multi = FruitSliceMultiConfig[real_erase_time].multi
		for line_index, v in ipairs(Const.Lines) do
			local line_data = {}
			for i = 1, 5 do
				--v[i]是行,i是列
				table.insert(line_data, result[v[i]][i])
			end

			--if (line_index == 4 or line_index == 17)
			--then
			--	LOG(RUN, INFO).Format("[SlotsBacktoJurassic][GenPrizeInfo] line_index is:%s, line_data is: %s", line_index, Table2Str(line_data))
			--end
			
			local one_line_prize = Calculate.GenOneLinePrize(player, line_data)

			for _, item in ipairs(one_line_prize) do
				if (FruitSlicePayrateConfig[item.item_id] ~= nil)
				then
					local payrate = FruitSlicePayrateConfig[item.item_id].payrate[item.continue_count - 2]
					if (payrate > 0)
					then
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

	TriggerBonus = function ( result )
		local bonus_count = 0
		for i = 1, 5 do
			for j = 1, 3 do
				if result[i][j] == Const.Types.Bonus then
					bonus_count = bonus_count + 1
				end
			end
		end
		return bonus_count >= 3
	end,

    --延迟时间设定为2 + erase_times * 1
    GenDelayTime = function(erase_times)
        if erase_times then
            return erase_times * FruitSliceOthersConfig[1].delay_per_erase + 2
        end
        return 2
    end,
}
