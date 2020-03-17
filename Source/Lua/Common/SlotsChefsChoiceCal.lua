module("SlotsChefsChoiceCal", package.seeall)
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
		[25] = {2,1,3,1,2},
	},

	Types = {
		GooseLiver = 1,
		Lobster = 2,
		Steak  = 3,
		Salmon = 4,
		CreamSoup = 5,
		Broccoli = 6,
		Salad = 7,
		Cake = 8,
		RedWine = 9,
		Wild = 10,
	},

	PrizeDirection = {
		LEFT = 1,
		RIGHT = 2,
	}
}

Util = {
	GenWildPos = function(line_data)
		local pos = {}
		for i = 1, 5 do
			if line_data[i] == Const.Types.Wild then
				table.insert(pos, i)
			end
		end
		return pos
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
		if not start or not stop or not step then return end
		local item_id
		local continue_count = 0
		for i = start, stop, step do
			if line_data[i] == Const.Types.Bonus then
				break
			end
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
		local ChefsChoicePayrateConfig = CommonCal.Calculate.get_config(player, "ChefsChoicePayrateConfig")
		local has_normal_prize = item_id and continue_count and (continue_count >= 3)
		local has_wild_prize = wild_count and (wild_count >= 3)
		if has_wild_prize and has_normal_prize then
			local normal_payrate = ChefsChoicePayrateConfig[item_id].payrate[continue_count - 2]
			local wild_payrate = ChefsChoicePayrateConfig[Const.Types.Wild].payrate[wild_count - 2]
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

		if (left_continue_count >=3 or left_wild_count >= 3)
		then
			Calculate.CompareNormalAndWild(player, left_item_id, left_continue_count, left_wild_count, prize_list, Const.PrizeDirection.LEFT)
		end

		return prize_list
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

	-- --将4*5的矩阵转换成一维数组,以列优先
	TransResultToList = function(result)
		local list = {}

		for i = 1, 5 do
			for j = 1, 3 do
				if (result[j][i] > 0)
				then
					table.insert(list, result[j][i])
				end
			end
		end
		
		return list
	end,

	GetMaxBetAmount = function(player)
		local ChefsChoiceBetAmountConfig = CommonCal.Calculate.get_config(player, "ChefsChoiceBetAmountConfig")
        local old_req_level = 0
        for k, v in ipairs(ChefsChoiceBetAmountConfig)
        do
            if (player.character.level >= old_req_level and player.character.level < v.required_level)
            then
                return ChefsChoiceBetAmountConfig[k - 1].single_amount
            end
            old_req_level = v.required_level
		end
		
		local max_index = #ChefsChoiceBetAmountConfig
		if (player.character.level >= ChefsChoiceBetAmountConfig[max_index].required_level)
		then
			return ChefsChoiceBetAmountConfig[max_index].single_amount
		end
        return 0
    end,

	GenChefsChoiceColumn = function(player, config, column)
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

	GenDownColumn = function(player, config, result_column, remove_item_list, oldIndex, drop_items_col)
		local player_id = player.id
		--local drop_items = {}
		local column = remove_item_list[1].column
		
		local sequence = config[column].sequence_array

		local sequence_len = #sequence

		local drop_num = #remove_item_list
		
		local index_list = {}
		for i = 1, drop_num do
			local index = oldIndex - i
			if (index <= 0)
			then
				index = sequence_len
			end
	
			if (index > sequence_len)
			then
				index = math.random_ext(player, 1, sequence_len)
			end
			table.insert(index_list, index)
		end
		
		if (GlobalSlotsTest[player_id] ~= nil)
		then
			index_list = {}

			sequence = CommonCal.Calculate.GetSubSequence(player_id, column)

			sequence_len = #sequence
			for i = 1, drop_num do
				table.insert(index_list, i)
			end
		end
		local ret_index = index_list[drop_num]

		--先消掉
		for _, item in pairs(remove_item_list) do
			local row = item.row
			if (row == 1)
			then
				local column_items = {0, result_column[2], result_column[3]}
				result_column = column_items
			elseif (row == 2)
			then
				local column_items = {result_column[1], 0, result_column[3]}	
				result_column = column_items
			elseif (row == 3)
			then
				local column_items = {result_column[1], result_column[2], 0}	
				result_column = column_items
			end
		end

		--再下滑
		while (result_column[3] == 0)
		do
			local index = index_list[1]
			local drop_item = sequence[index]
			local column_items = {drop_item, result_column[1], result_column[2]}
			result_column = column_items
			table.remove(index_list, 1)
			table.insert(drop_items_col[column], 1, drop_item)
		end

		while (result_column[2] == 0)
		do
			local index = index_list[1]
			local drop_item = sequence[index]
			local column_items = {drop_item, result_column[1], result_column[3]}
			result_column = column_items
			table.remove(index_list, 1)
			table.insert(drop_items_col[column], 1, drop_item)
		end

		while (result_column[1] == 0)
		do
			local index = index_list[1]
			local drop_item = sequence[index]
			local column_items = {drop_item, result_column[2], result_column[3]}
			result_column = column_items
			table.remove(index_list, 1)
			table.insert(drop_items_col[column], 1, drop_item)
		end

		return result_column, ret_index
	end,

	GenItemResult = function (player, last_remove_item_list, ColumnIndexList, result, free_spin_num, loop_num)
		local tran_result = nil
		
		local reel_file_name = "ChefsChoiceBaseReelConfig"
		if (player.character.level <= tonumber(ConstValue[8].value))
		then		
			reel_file_name = "ChefsChoiceNewHand1BaseReelConfig"
		elseif (player.character.level <= tonumber(ConstValue[9].value))
		then
			reel_file_name = "ChefsChoiceNewHand2BaseReelConfig"
		elseif (player.character.level <= tonumber(ConstValue[10].value))
		then
			reel_file_name = "ChefsChoiceNewHand3BaseReelConfig"
		end
		
		if (free_spin_num == 5)
		then
			reel_file_name = "ChefsChoiceFree5ReelConfig"

			if (player.character.level <= tonumber(ConstValue[8].value))
			then		
				reel_file_name = "ChefsChoiceNewHand1Free5ReelConfig"
			elseif (player.character.level <= tonumber(ConstValue[9].value))
			then
				reel_file_name = "ChefsChoiceNewHand2Free5ReelConfig"
			elseif (player.character.level <= tonumber(ConstValue[10].value))
			then
				reel_file_name = "ChefsChoiceNewHand3Free5ReelConfig"
			end
		elseif (free_spin_num == 10)
		then
			reel_file_name = "ChefsChoiceFree10ReelConfig"
			if (player.character.level <= tonumber(ConstValue[8].value))
			then		
				reel_file_name = "ChefsChoiceNewHand1Free10ReelConfig"
			elseif (player.character.level <= tonumber(ConstValue[9].value))
			then
				reel_file_name = "ChefsChoiceNewHand2Free10ReelConfig"
			elseif (player.character.level <= tonumber(ConstValue[10].value))
			then
				reel_file_name = "ChefsChoiceNewHand3Free10ReelConfig"
			end
		elseif (free_spin_num == 20)
		then
			reel_file_name = "ChefsChoiceFree20ReelConfig"
			if (player.character.level <= tonumber(ConstValue[8].value))
			then		
				reel_file_name = "ChefsChoiceNewHand1Free20ReelConfig"
			elseif (player.character.level <= tonumber(ConstValue[9].value))
			then
				reel_file_name = "ChefsChoiceNewHand2Free20ReelConfig"
			elseif (player.character.level <= tonumber(ConstValue[10].value))
			then
				reel_file_name = "ChefsChoiceNewHand3Free20ReelConfig"
			end
		elseif (free_spin_num == 50)
		then
			reel_file_name = "ChefsChoiceFree50ReelConfig"
			if (player.character.level <= tonumber(ConstValue[8].value))
			then		
				reel_file_name = "ChefsChoiceNewHand1Free50ReelConfig"
			elseif (player.character.level <= tonumber(ConstValue[9].value))
			then
				reel_file_name = "ChefsChoiceNewHand2Free50ReelConfig"
			elseif (player.character.level <= tonumber(ConstValue[10].value))
			then
				reel_file_name = "ChefsChoiceNewHand3Free50ReelConfig"
			end
		end

		local config = CommonCal.Calculate.get_config(player, reel_file_name)

		local drop_items_list = {}

		if (#last_remove_item_list > 0)
		then
			local drop_items_col = {{}, {}, {}, {}, {}}
			local remove_items_col = {{}, {}, {}, {}, {}}
			for _, local_remove_item in ipairs(last_remove_item_list) do
				table.insert(remove_items_col[local_remove_item.column], local_remove_item)
			end
			for _, remove_item_list in pairs(remove_items_col) do
				if (#remove_item_list > 0)
				then
					local column = remove_item_list[1].column
					local oldIndex = ColumnIndexList[column]
					local result_column = result[column]
					local localResult, ColumnIndex = Calculate.GenDownColumn(player, config, result_column, remove_item_list, oldIndex, drop_items_col)
					result[column] = localResult	
					ColumnIndexList[column] = ColumnIndex
				end
			end
			for i = 1, 5 do
				local local_drop_items = {}
				for _, drop_item in ipairs(drop_items_col[i]) do
					table.insert(local_drop_items, drop_item)
				end
				--if (#local_drop_items > 0)
				--then
				table.insert(drop_items_list, {item_ids = local_drop_items})
				--end
			end
		else
			local wild_columns = {1, 2, 3, 4, 5}
			for _,v in ipairs(wild_columns) do
				local localResult, ColumnIndex = Calculate.GenChefsChoiceColumn(player, config, v)
	
				result[v] = localResult
				ColumnIndexList[v] = ColumnIndex
			end

		end
		tran_result = Calculate.TransResult(result)

		return tran_result, ColumnIndexList, drop_items_list, reel_file_name
	end,

	
    GetChefsChoice = function(chefs_choice, local_chefs_choice)
        chefs_choice.bet_amount = local_chefs_choice.bet_amount
        chefs_choice.free_spin_bouts = local_chefs_choice.free_spin_bouts
        chefs_choice.free_spin_num = local_chefs_choice.free_spin_num
        chefs_choice.bouts_id = local_chefs_choice.bouts_id
        chefs_choice.channel_id = local_chefs_choice.channel_id
        chefs_choice.total_loss = local_chefs_choice.total_loss
        chefs_choice.enter_chip = local_chefs_choice.enter_chip
        chefs_choice.spined_times = local_chefs_choice.spined_times
        chefs_choice.free_total_win = local_chefs_choice.free_total_win
        chefs_choice.free_spin_num_str = local_chefs_choice.free_spin_num_str
    end,
    
    GetRecord = function(player, local_record)
        player.record.total_spin = local_record.total_spin
        player.record.spin_won = local_record.spin_won
        player.record.total_win = local_record.total_win
        player.record.biggest_win = local_record.biggest_win
        player.record.bonus_game = local_record.bonus_game
        player.record.free_spin = local_record.free_spin
	end,
	
	UpdateFreeBous = function(chefs_choice, free_spin_num_array)
		chefs_choice.free_spin_bouts = 0
		if (#free_spin_num_array > 0)
		then
			for k, v in pairs(free_spin_num_array)
			do
				chefs_choice.free_spin_bouts = chefs_choice.free_spin_bouts + v.free_spin_bouts
			end
		end
	end,
    
-- --generate总的中奖信息
	GenPrizeInfo = function(player, result)
		local prize_info = {}
		local remove_item_list = {}
		local total_payrate = 0
		for line_index, v in ipairs(Const.Lines) do
			local line_data = {}
			local test_line_data = {}
			for i = 1, 5 do
				--v[i]是行,i是列
				table.insert(line_data, result[v[i]][i])
				table.insert(test_line_data, {row = v[i], column = i, result[v[i]][i]})
			end

			local one_line_prize = Calculate.GenOneLinePrize(player, line_data)

			local ChefsChoicePayrateConfig = CommonCal.Calculate.get_config(player, "ChefsChoicePayrateConfig")
			for _, item in ipairs(one_line_prize) do
				
				local config = ChefsChoicePayrateConfig[item.item_id]
				if (config ~= nil)
				then
					local payrate = config.payrate[item.continue_count - 2]
					if (payrate > 0)
					then
						item.payrate = payrate
						item.line_index = line_index
						table.insert(prize_info, item)
						total_payrate = total_payrate + item.payrate
		
						
						for index = 1, item.continue_count do
							local remove_item = {}
							remove_item.row = v[index]
							remove_item.column = index
							remove_item.item_id = item.item_id
		
							local is_exist = false
							for _, local_remove_item in ipairs(remove_item_list) do
								if (local_remove_item.row == remove_item.row and local_remove_item.column == remove_item.column)
								then
									is_exist = true
									break
								end
							end
							
							if (not is_exist)
							then
								table.insert(remove_item_list, remove_item)
							end
						end
					end
				end

			end
		end

		return prize_info, total_payrate, remove_item_list
	end,
}
