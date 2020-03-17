module("SlotsElvesEpicCal", package.seeall)
require "Util/TableExt"
require "Common/CommonCal"

Const = {
	Lines = {
		[1] = {1,1,1,1,1},
		[2] = {1,1,2,2,2},
		[3] = {1,1,3,3,3},
		[4] = {1,1,4,4,4},
		[5] = {2,2,1,1,1},
		[6] = {2,2,2,2,2},
		[7] = {2,2,3,3,3},
		[8] = {2,2,4,4,4},
		[9] = {1,1,2,1,1},
		[10] = {1,1,2,3,3},
		[11] = {2,1,2,2,3},
		[12] = {1,2,3,3,2},
		[13] = {2,2,3,2,2},
		[14] = {2,2,3,4,4},
		[15] = {1,1,3,2,2},
		[16] = {2,2,4,3,3},
		[17] = {1,1,1,2,2},
		[18] = {2,2,2,3,3},
		[19] = {1,2,2,3,2},
		[20] = {2,1,3,2,3},
		[21] = {1,2,4,3,2},
		[22] = {2,1,1,2,3},
		[23] = {1,1,1,2,3},
		[24] = {2,2,2,3,4},
		[25] = {1,1,3,2,1},
		[26] = {2,2,4,3,2},
		[27] = {1,1,1,4,1},
		[28] = {2,2,1,4,1},
		[29] = {1,1,4,1,4},
		[30] = {2,2,4,1,4}
	},

	Types = {
		Bow = 1,
		Axe = 2,
		Shield  = 3,
		Bucket = 4,
		K = 5,
		Q = 6,
		J = 7,
		Wild1 = 8,
		Wild2 = 9,
		Wild3 = 10,
		Jackpot = 11,
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
	
	GenWildReplaceValue = function( line_data, wild_pos )
        if wild_pos == 1 then
            for i = 2, 5, 1 do
                if line_data[i] == Const.Types.Jackpot then return end
                if line_data[i] ~= Const.Types.Wild1 and line_data[i] ~= Const.Types.Wild2 and line_data[i] ~= Const.Types.Wild3 then
                    return  line_data[i]
                end
            end
        elseif wild_pos == 5 then
            for i = 4, 1, -1 do
                if line_data[i] == Const.Types.Jackpot then return end
                if line_data[i] ~= Const.Types.Wild1 and line_data[i] ~= Const.Types.Wild2 and line_data[i] ~= Const.Types.Wild3 then
                    return  line_data[i]
                end
            end
        else
            local left_value
            for i = wild_pos-1, 1, -1 do
                if line_data[i] == Const.Types.Jackpot then return end
                if line_data[i] ~= Const.Types.Wild1 and line_data[i] ~= Const.Types.Wild2 and line_data[i] ~= Const.Types.Wild3 then
                    left_value = line_data[i]
                    break
                end
            end
            local right_value
            for i = wild_pos + 1, 5, 1 do
                if line_data[i] == Const.Types.Jackpot then break end
                if line_data[i] ~= Const.Types.Wild1 and line_data[i] ~= Const.Types.Wild2 and line_data[i] ~= Const.Types.Wild3 then
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
			if item_id then
				if line_data[i] ~= item_id and line_data[i] ~= Const.Types.Wild1 and line_data[i] ~= Const.Types.Wild2 and line_data[i] ~= Const.Types.Wild3 then
					continue_count = math.abs(start - i)
					break
				else
					continue_count = math.abs(start - i) + 1
				end
			else
				if line_data[i] ~= Const.Types.Wild1 and line_data[i] ~= Const.Types.Wild2 and line_data[i] ~= Const.Types.Wild3 then
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

	GenJackpotContinueCount = function(line_data, direction)
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
		local item_id = -1
		local continue_count = 0
		for i = start, stop, step do
			if line_data[i] ~= Const.Types.Jackpot then
				break
			end
			if item_id then
				if line_data[i] == item_id then
					continue_count = math.abs(start - i) + 1
				end
			else
				if line_data[i] == Const.Types.Jackpot then
					item_id = line_data[i]
				end
			end
		end
		return item_id, continue_count
	end,

	--比较普通中奖和wild中奖，以赔率大的作为一条中奖项
	CompareNormalAndWild = function (player, item_id, continue_count, wild_count, prize_list, direction )
		local has_normal_prize = item_id and continue_count and (continue_count >= 3)
		local has_wild_prize = wild_count and (wild_count >= 3)

		local ElvesEpicPayrateConfig = CommonCal.Calculate.get_config(player, "ElvesEpicPayrateConfig")
		if has_wild_prize and has_normal_prize then
			local normal_payrate = ElvesEpicPayrateConfig[item_id].payrate[continue_count - 2]
			local wild_payrate = ElvesEpicPayrateConfig[Const.Types.Wild].payrate[wild_count - 2]
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


	GenJackpotOneLinePrize = function(player, line_data)
		local prize_list = {}

		local wild_pos_list = Util.GenWildPos(line_data)
        local wild_pos_len = #wild_pos_list
		local rep_line_data = table.copy(line_data)

		local left_item_id, left_continue_count = Calculate.GenJackpotContinueCount(rep_line_data, Const.PrizeDirection.LEFT)
		if (left_continue_count == 5)
		then
			Calculate.CompareNormalAndWild(player, left_item_id, left_continue_count, 0, prize_list, Const.PrizeDirection.LEFT)
		end
		local right_item_id, right_continue_count = Calculate.GenJackpotContinueCount(rep_line_data, Const.PrizeDirection.RIGHT)
		
		if (right_continue_count == 5)
		then
			Calculate.CompareNormalAndWild(player, right_item_id, right_continue_count, 0, prize_list, Const.PrizeDirection.RIGHT)
		end

		return prize_list
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



	-- --trans 5*4 matrix to 4*5 matrix
	TransResult = function(result)
		local tran_result = {}
		for row = 1, 4 do
			tran_result[row] = {}
			for col = 1, 5 do
				tran_result[row][col] = result[col][row]
			end
		end
		return tran_result
	end,

	-- --trans 5*4 matrix to 4*5 matrix
	TransWildResult = function(result)
		local tran_result = {}
		for row = 1, 4 do
			tran_result[row] = {}
			for col = 1, 3 do
				tran_result[row][col] = result[col][row]
			end
		end
		return tran_result
	end,

	-- --将4*5的矩阵转换成一维数组,以列优先
	TransResultToList = function(result)
		local list = {}
		for i = 1, 5 do
			for j = 1, 4 do
				if (result[j][i] > 0)
				then
					table.insert(list, result[j][i])
				end
			end
		end
		return list
	end,

	GetMaxBetAmount = function(player)
		local old_req_level = 0
		local ElvesEpicBetAmountConfig = CommonCal.Calculate.get_config(player, "ElvesEpicBetAmountConfig")
        for k, v in ipairs(ElvesEpicBetAmountConfig)
        do
            if (player.character.level >= old_req_level and player.character.level < v.required_level)
            then
                return ElvesEpicBetAmountConfig[k - 1].single_amount
            end
            old_req_level = v.required_level
		end
		local max_index = #ElvesEpicBetAmountConfig
		if (player.character.level >= ElvesEpicBetAmountConfig[max_index].required_level)
		then
			return ElvesEpicBetAmountConfig[max_index].single_amount
		end
        return 0
    end,

	GenElvesEpicColumn = function(player, config, column)
		local player_id = player.id
		if column > 2
		then
			local sequence = config[column].sequence_array
			local sequence_len = #sequence
			local index = math.random_ext(player, 1, sequence_len)

			if (GlobalSlotsTest[player_id] ~= nil)
			then
				sequence, sequence_len, index = CommonCal.Calculate.GetSequence(player_id, column)
			end
			
			local index_1, index_2, index_3 = index % sequence_len + 1, (index + 1) % sequence_len + 1, (index + 2) % sequence_len + 1

			return {sequence[index], sequence[index_1], sequence[index_2], sequence[index_3]}, index

		else
			local sequence = config[column].sequence_array
			local sequence_len = #sequence
			local index = math.random_ext(player, 1, sequence_len)

			if (GlobalSlotsTest[player_id] ~= nil)
			then
				sequence, sequence_len, index = CommonCal.Calculate.GetSequence(player_id, column)
			end

			local index_1 = index % sequence_len + 1
			return {sequence[index], sequence[index_1], 0, 0}, index
		end
	end,

--在原始序列加入wild,extra_wild
    GenResultWithWild = function(result, extra_wild)
        local result_with_wild = table.copy(result)
        --[[
        for column = 1, 5 do
            if result_with_wild[1][column] == Const.Types.Wild or result_with_wild[2][column] == Const.Types.Wild or result_with_wild[3][column] == Const.Types.Wild then
                result_with_wild[1][column] = Const.Types.Wild
                result_with_wild[2][column] = Const.Types.Wild
                result_with_wild[3][column] = Const.Types.Wild
           
        end
        --]]

		for column = 3, 5 do
			if (extra_wild[1][column - 2])
			then
				result_with_wild[1][column] = extra_wild[1][column - 2]
			end
			if (extra_wild[2][column - 2])
			then
				result_with_wild[2][column] = extra_wild[2][column - 2]
			end
			if (extra_wild[3][column - 2])
			then
				result_with_wild[3][column] = extra_wild[3][column - 2]
			end
			if (extra_wild[4][column - 2])
			then
				result_with_wild[4][column] = extra_wild[4][column - 2]
			end
        end

        return result_with_wild
    end,

	GenItemResult = function (player, is_free_spin, winAmount, free_item_id)
		local has_big_wild = 0
		local init_result = {}
		local col_start_index = {}
		local reel_file_name = is_free_spin and "ElvesEpicFeatureReelConfig" or "ElvesEpicBaseReelConfig"
		local config = is_free_spin and CommonCal.Calculate.get_config(player, reel_file_name)

		reel_file_name, config = CommonCal.Calculate.get_new_hand_config(player, is_free_spin, reel_file_name, config, "ElvesEpic")

		local result = {{}, {}, {}, {}, {}}
		local wild = {{}, {}, {}}
		--先随第3列,4列，5列,如果3,4,5列上同时出现WILD图标，则3,4,5列上的Wild会延展至该列的全部四格区域
		result[3] = Calculate.GenElvesEpicColumn(player, config, 3)
        local is_three_wild = (result[3][1] == Const.Types.Wild1  or result[3][2] == Const.Types.Wild1 or result[3][3] == Const.Types.Wild1 or result[3][4] == Const.Types.Wild1)--Wild1(女精灵只会出现在第三列)

		result[4] = Calculate.GenElvesEpicColumn(player, config, 4)
        local is_four_wild  = (result[4][1] == Const.Types.Wild2  or result[4][2] == Const.Types.Wild2 or result[4][3] == Const.Types.Wild2 or result[4][4] == Const.Types.Wild2)--Wild2(男精灵只会出现在第四列)

		result[5] = Calculate.GenElvesEpicColumn(player, config, 5)
        local is_five_wild  = (result[5][1] == Const.Types.Wild3  or result[5][2] == Const.Types.Wild3 or result[5][3] == Const.Types.Wild3 or result[5][4] == Const.Types.Wild3)--Wild3(矮人只会出现在第五列)

		if (winAmount > 0)--保证3,4,5列上不会同时出现WILD图标
		then
			if (is_three_wild and is_four_wild and is_five_wild)
			then
				local weight_tab = {[1] = 0.1, [2] = 0.1, [3] = 0.1}
				local result_index = math.rand_weight(player, weight_tab)
				for i = 1, 4, 1
				do
					if (result[result_index][i] == Const.Types.Wild1 or result[result_index][i] == Const.Types.Wild2 or result[result_index][i] == Const.Types.Wild3)
					then
						local local_weight_tab = {[1] = 0.1, [2] = 0.1, [3] = 0.1, [4] = 0.1, [5] = 0.1, [6] = 0.1, [7] = 0.1, [11] = 0.1}
						local local_index = math.rand_weight(player, local_weight_tab)
						result[result_index][i] = local_index
					end
				end
			end 
		else
			if (is_three_wild and is_four_wild and is_five_wild)
			then
				wild[1][1] = Const.Types.Wild1
				wild[1][2] = Const.Types.Wild1
				wild[1][3] = Const.Types.Wild1
				wild[1][4] = Const.Types.Wild1
	
			    wild[2][1] = Const.Types.Wild2
				wild[2][2] = Const.Types.Wild2
				wild[2][3] = Const.Types.Wild2
				wild[2][4] = Const.Types.Wild2       	
	
				wild[3][1] = Const.Types.Wild3
				wild[3][2] = Const.Types.Wild3
				wild[3][3] = Const.Types.Wild3
				wild[3][4] = Const.Types.Wild3
				has_big_wild = 1
			end
		end
		

        local other_columns = {1,2}

        if not is_free_spin then
            for _,v in ipairs(other_columns) do
                result[v] = Calculate.GenElvesEpicColumn(player, config, v)
			end
		else
			for _,v in ipairs(other_columns) do
                result[v] = {free_item_id, free_item_id, 0, 0}
			end
        end

 		local tran_result = Calculate.TransResult(result)

 		local extra_wild  = Calculate.TransWildResult(wild)

		
		return tran_result, extra_wild, has_big_wild, reel_file_name
		
	end,

    GenFreeSpinCount = function(data)
        local scatter_count = 0

        for i = 1, 2 do
            for j = 1, 2 do
                if data[i][j] ~=  data[1][1] then
                    return 0, 0
                end
            end
        end
        return 10, data[1][1]
    end,

	TransExtraWildPosToList = function(origin_result, has_big_wild)
		local list = {}
		if (has_big_wild == 0)
		then
			return list
		end
		local result_data = table.copy(origin_result)

		local pos = 0
		for row = 1, 5 do
			--tran_result[row] = {}
			for col = 1, 4 do
				if (col < 3 and row < 3)
				then
					pos = pos + 1
				end
				if (row >= 3)
				then
					pos = pos + 1
				end
				--tran_result[row][col] = result[col][row]
				if (result_data[col][row] == Const.Types.Wild1 or result_data[col][row] == Const.Types.Wild2 or result_data[col][row] == Const.Types.Wild3)
				then
					local newPos = pos
					table.insert(list, newPos)
				end
			end
		end

        return list
    end,

    GenJackpotProgress = function(data)
        local jackpot_count = 0
        for i = 1, 3 do
            for j = 1, 5 do
                if data[i][j] == Const.Types.Jackpot then
                    jackpot_count = jackpot_count + 1
                end
            end
        end
        return jackpot_count >= 5
    end,

-- --generate总的中奖信息
	GenPrizeInfo = function(player, result, winAmount, origin_result)
		local prize_info = {}
		local total_payrate = 0

		local ElvesEpicPayrateConfig = CommonCal.Calculate.get_config(player, "ElvesEpicPayrateConfig")
		for line_index, v in ipairs(Const.Lines) do
			local line_data = {}
			for i = 1, 5 do
				--v[i]是行,i是列

				table.insert(line_data, result[v[i]][i])
			end
			local one_line_prize = Calculate.GenOneLinePrize(player, line_data)
			
			for _, item in ipairs(one_line_prize) do
				if (ElvesEpicPayrateConfig[item.item_id] ~= nil)
				then
					local payrate = ElvesEpicPayrateConfig[item.item_id].payrate[item.continue_count - 2]
					if (payrate > 0)
					then
						item.payrate = payrate
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
            return erase_times * ElvesEpicOthersConfig[1].delay_per_erase + 2
        end
        return 2
    end,
}
