module("SlotsPurrfectPetsCal", package.seeall)
require "Util/TableExt"
require "Common/CommonCal"
Const = {
	Lines = {
		[1] = {2,2,2,2,2},
		[2] = {1,1,1,1,1},
		[3] = {3,3,3,3,3},
		[4] = {1,2,3,2,1},
		[5] = {3,2,1,2,3},
		[6] = {1,1,2,3,3},
		[7] = {3,3,2,1,1},
		[8] = {2,1,2,3,2},
		[9] = {2,3,2,1,2},
		[10] = {1,2,2,2,3},
		[11] = {3,2,2,2,1},
		[12] = {2,1,1,2,3},
		[13] = {2,3,3,2,1},
		[14] = {2,2,1,2,3},
		[15] = {2,2,3,2,1},
		[16] = {1,1,2,3,2},
		[17] = {3,3,2,1,2},
		[18] = {1,2,1,2,3},
		[19] = {3,2,3,2,1},
		[20] = {1,1,3,1,1},
		[21] = {3,3,1,3,3},
		[22] = {1,3,1,3,1},
		[23] = {3,1,3,1,3},
		[24] = {1,3,3,3,1},
		[25] = {3,1,1,1,3},
		[26] = {2,1,3,1,2},
		[27] = {2,3,1,3,2},
		[28] = {1,3,2,3,1},
		[29] = {3,1,2,1,3},
		[30] = {2,1,1,1,2},
	},

	Types = {
		Garfield = 1,--异短
		SiameseCat = 2,--暹罗
		Poodle  = 3,--贵宾
		Schnauzer = 4,--雪纳瑞
		Tin = 5,--罐头
		Milk = 6,--牛奶
		Bone = 7,--骨头
		Scatter = 8,
		Wild = 9,
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
		local item_id
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
		local PurrfectPetsPayrateConfig = CommonCal.Calculate.get_config(player, "PurrfectPetsPayrateConfig")
		local has_normal_prize = item_id and continue_count and (continue_count >= 3)
		local has_wild_prize = wild_count and (wild_count >= 3)
		if has_wild_prize and has_normal_prize then
			local normal_payrate = PurrfectPetsPayrateConfig[item_id].payrate[continue_count - 2]
			local wild_payrate = PurrfectPetsPayrateConfig[Const.Types.Wild].payrate[wild_count - 2]
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

	GenJackpotOneLinePrize = function(player, line_data)
		local prize_list = {}

		local wild_pos_list = Util.GenWildPos(line_data)
        local wild_pos_len = #wild_pos_list
		local rep_line_data = table.copy(line_data)

		local left_item_id, left_continue_count = Calculate.GenJackpotContinueCount(rep_line_data, Const.PrizeDirection.LEFT)
		--local left_wild_count = Calculate.GenWildContinueCount(line_data, Const.PrizeDirection.LEFT)
		if (left_continue_count == 5)
		then
			Calculate.CompareNormalAndWild(player, left_item_id, left_continue_count, 0, prize_list, Const.PrizeDirection.LEFT)
		end

		return prize_list
	end,

	GenOneLinePrize = function(player, line_data, winAmount)
		local prize_list = {}

		local wild_pos_list = Util.GenWildPos(line_data)
        local wild_pos_len = #wild_pos_list
		local rep_line_data = table.copy(line_data)
		if wild_pos_len > 0 then
            for i = 1, wild_pos_len do
                local rep_value = Util.GenWildReplaceValue(line_data, wild_pos_list[i], winAmount)
                if rep_value then
                    rep_line_data[wild_pos_list[i]] = rep_value
                end
            end
        end

		local left_item_id, left_continue_count = Calculate.GenNormalContinueCount(rep_line_data, Const.PrizeDirection.LEFT)
		local left_wild_count = Calculate.GenWildContinueCount(line_data, Const.PrizeDirection.LEFT)
		--if (left_continue_count >= 3)
		--then
		Calculate.CompareNormalAndWild(player, left_item_id, left_continue_count, left_wild_count, prize_list, Const.PrizeDirection.LEFT)
		--end

		return prize_list
	end,

	-- --trans 5*4 matrix to 4*5 matrix
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
			for j = 1, 3 do
				if (result[j][i] > 0)
				then
					table.insert(list, result[j][i])
				end
			end
		end
		
		return list
	end,

	GenPurrfectPetsColumn = function(player, config, column)
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

	GenWildResult = function(result, all_freeze_list)
		for k, v in pairs(all_freeze_list)
		do
			for subk, subv in pairs(v)
			do
				result[subv.row][subv.column] = Const.Types.Wild
			end
		end
	end,

	GetMaxBetAmount = function(player)
		local PurrfectPetsBetAmountConfig = CommonCal.Calculate.get_config(player, "PurrfectPetsBetAmountConfig")
        local old_req_level = 0
        for k, v in ipairs(PurrfectPetsBetAmountConfig)
        do
            if (player.character.level >= old_req_level and player.character.level < v.required_level)
            then
                return PurrfectPetsBetAmountConfig[k - 1].single_amount
            end
            old_req_level = v.required_level
		end
		
		local max_index = #PurrfectPetsBetAmountConfig
		if (player.character.level >= PurrfectPetsBetAmountConfig[max_index].required_level)
		then
			return PurrfectPetsBetAmountConfig[max_index].single_amount
		end
        return 0
	end,
	
	IsWild = function (item_id1, item_id2, item_id3, item_id4)
		local array = {}
		table.insert(array, item_id1)
		table.insert(array, item_id2)
		table.insert(array, item_id3)
		table.insert(array, item_id4)

		local target_array = {}
		table.insert(target_array, Const.Types.Garfield)
		table.insert(target_array, Const.Types.SiameseCat)
		table.insert(target_array, Const.Types.Poodle)
		table.insert(target_array, Const.Types.Schnauzer)

		for k, v in ipairs(array)
		do
			for tartget_k, target_v in ipairs(target_array)
			do
				if (target_v == v)
				then
					table.remove(target_array, tartget_k)
					break
				end
			end
		end
		
		return #target_array == 0 and 1 or 0
	end,

	IsInFreeze = function(item, all_freeze_list)
		for k, v in pairs(all_freeze_list)
		do
			for subk, subv in pairs(v)
			do
				if (subv.row == item.row and subv.column == item.column)
				then
					return 1
				end
			end
		end		
		return 0
	end,

	GenItemResult = function (player, result, all_freeze_list, is_free_spin)
		local col_start_index = {}
		local reel_file_name = "PurrfectPetsBaseReelConfig"
		if (is_free_spin)
		then
			reel_file_name = "PurrfectPetsFeatureReelConfig"
		else
			reel_file_name = "PurrfectPetsBaseReelConfig"
		end

		local config = CommonCal.Calculate.get_config(player, reel_file_name)

		reel_file_name, config = CommonCal.Calculate.get_new_hand_config(player, is_free_spin, reel_file_name, config, "PurrfectPets")

		local tran_result = nil

		--先随第1至5列是否出现wild
		local wild_columns = {1, 2, 3, 4, 5}
		for _,v in ipairs(wild_columns) do
			local localResult = Calculate.GenPurrfectPetsColumn(player, config, v)

			for local_k, local_v in pairs(localResult)
			do
				local is_freeze = 0
				for free_k, free_v in pairs(all_freeze_list)
				do
					for subk, subv in pairs(free_v)
					do
						if (subv.row == local_k and subv.column == v)
						then
							is_freeze = 1
							break
						end
					end
					if (is_freeze == 1)
					then
						break
					end
				end
				if (is_freeze == 0)
				then
					result[v][local_k] = localResult[local_k]
				end
			end
			--result[v] = localResult
		end

		tran_result = Calculate.TransResult(result)
		
		local result_with_wild = table.DeepCopy(tran_result)

        SlotsPurrfectPetsCal.Calculate.GenWildResult(result_with_wild, all_freeze_list)

		local freeze_list = {}

		for i = 1, 3 do
			if (Calculate.IsWild(result_with_wild[i][1], result_with_wild[i][2], result_with_wild[i][3], result_with_wild[i][4]) == 1)
			then 
				for column = 1, 4, 1
				do
					if (Calculate.IsInFreeze({row = i, column = column}, all_freeze_list) == 0)
					then
						table.insert(freeze_list, {row = i, column = column})
					end
				end
			elseif (Calculate.IsWild(result_with_wild[i][2], result_with_wild[i][3], result_with_wild[i][4], result_with_wild[i][5]) == 1)
			then
				for column = 2, 5, 1
				do
					if (Calculate.IsInFreeze({row = i, column = column}, all_freeze_list) == 0)
					then
						table.insert(freeze_list, {row = i, column = column})
					end
				end
			end
		end

		return tran_result, freeze_list, reel_file_name
	end,

    GenFreeSpinCount = function(data)
        local scatter_count = 0

        for i = 1, 3 do
            for j = 1, 5 do
                if data[i][j] == Const.Types.Scatter then
                    scatter_count = scatter_count + 1
                end
            end
		end
		
		if (scatter_count >= 3)
		then
			return 20, Const.Types.Scatter
		end
        return 0, 0
    end,


-- --generate总的中奖信息
	GenPrizeInfo = function(player, result)
		local PurrfectPetsPayrateConfig = CommonCal.Calculate.get_config(player, "PurrfectPetsPayrateConfig")
		local prize_info = {}
		local total_payrate = 0

		for line_index, v in ipairs(Const.Lines) do
			local line_data = {}
			for i = 1, 5 do
				--v[i]是行,i是列

				table.insert(line_data, result[v[i]][i])
			end
			local one_line_prize = Calculate.GenOneLinePrize(player, line_data, winAmount)
			
			for _, item in ipairs(one_line_prize) do
				if (PurrfectPetsPayrateConfig[item.item_id] ~= nil)
				then
					local payrate = PurrfectPetsPayrateConfig[item.item_id].payrate[item.continue_count - 2]
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

}
