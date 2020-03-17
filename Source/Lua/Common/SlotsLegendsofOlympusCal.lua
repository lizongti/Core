module("SlotsLegendsofOlympusCal", package.seeall)
require "Util/TableExt"
require "Common/CommonCal"
Const = {
	Lines = {
		[1] = {1,1,1,1,1},
		[2] = {2,2,2,2,2},
		[3] = {3,3,3,3,3},
		[4] = {4,4,4,4,4},
		[5] = {1,2,2,2,1},
		[6] = {2,3,3,3,2},
		[7] = {3,4,4,4,3},
		[8] = {4,3,3,3,4},
		[9] = {3,2,2,2,3},
		[10] = {2,1,1,1,2},
		[11] = {1,2,3,2,1},
		[12] = {2,3,4,3,2},
		[13] = {4,3,2,3,4},
		[14] = {3,2,1,2,3},
		[15] = {1,2,1,2,1},
		[16] = {2,3,2,3,2},
		[17] = {3,4,3,4,3},
		[18] = {2,1,2,1,2},
		[19] = {3,2,3,2,3},
		[20] = {4,3,4,3,4},
		[21] = {1,1,2,1,1},
		[22] = {2,2,3,2,2},
		[23] = {3,3,4,3,3},
		[24] = {4,4,3,4,4},
        [25] = {3,3,2,3,3},
		[26] = {2,2,1,2,2},
		[27] = {1,4,1,4,1},
		[28] = {4,1,4,1,4},
		[29] = {4,2,4,2,4},
		[30] = {3,1,3,1,3},
		[31] = {1,3,1,3,1},
		[32] = {2,4,2,4,2},
		[33] = {4,3,3,2,1},
		[34] = {1,2,2,3,4},
		[35] = {1,2,3,3,4},
		[36] = {4,3,2,2,1},
		[37] = {2,1,4,3,2},
		[38] = {3,4,1,2,3},
		[39] = {4,4,1,4,4},
		[40] = {1,1,4,1,1},
		[41] = {4,1,1,1,4},
		[42] = {1,4,4,4,1},
		[43] = {4,2,2,2,4},
		[44] = {1,3,3,2,1},
		[45] = {4,2,3,2,4},
		[46] = {1,3,2,3,1},
		[47] = {4,1,2,1,4},
		[48] = {1,4,2,4,1},
		[49] = {4,4,2,4,4},
		[50] = {1,1,3,1,1},
	},

	Types = {
		Zeus = 1,
		Poseidon = 2,
		Hardis  = 3,
		Hella = 4,
		Thunderclap = 5,
		Trident = 6,
		InvisibleHelmet  = 7,
		Balance = 8,
		Crosier = 9,
		Stean = 10,
		Wild = 11,
		Scatter = 12,
		Zeus_2_1 = 101,
		Zeus_2_2 = 102,
		Zeus_3_1 = 1001,
		Zeus_3_2 = 1002,
		Zeus_3_3 = 1003,
		Zeus_4_1 = 10001,
		Zeus_4_2 = 10002,
		Zeus_4_3 = 10003,
		Zeus_4_4 = 10004,
		Poseidon_2_1 = 201,
		Poseidon_2_2 = 202,
		Poseidon_3_1 = 2001,
		Poseidon_3_2 = 2002,
		Poseidon_3_3 = 2003,
		Poseidon_4_1 = 20001,
		Poseidon_4_2 = 20002,
		Poseidon_4_3 = 20003,
		Poseidon_4_4 = 20004,
		Hardis_2_1 = 301,
		Hardis_2_2 = 302,
		Hardis_3_1 = 3001,
		Hardis_3_2 = 3002,
		Hardis_3_3 = 3003,
		Hardis_4_1 = 30001,
		Hardis_4_2 = 30002,
		Hardis_4_3 = 30003,
		Hardis_4_4 = 30004,
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
			if line_data[i] == Const.Types.Scatter then
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
		local LegendsofOlympusPayrateConfig = CommonCal.Calculate.get_config(player, "LegendsofOlympusPayrateConfig")

		local has_normal_prize = item_id and continue_count and (continue_count >= 3)
		local has_wild_prize = wild_count and (wild_count >= 3)
		if has_wild_prize and has_normal_prize then
			local normal_payrate = LegendsofOlympusPayrateConfig[item_id].payrate[continue_count - 2]
			local wild_payrate = LegendsofOlympusPayrateConfig[Const.Types.Wild].payrate[wild_count - 2]
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
		for row = 1, 4 do
			tran_result[row] = {}
			for col = 1, 5 do
				tran_result[row][col] = result[col][row]
			end
		end
		return tran_result
	end,

	ReplaceWild = function(result, item_type)
		for i = 1, 5 do
			for j = 1, 4 do
				if (result[j][i] == item_type)
				then
					result[j][i] = Const.Types.Wild
				end
			end
		end
	end,

	ReplaceBigItemCol = function (result, i, Item_Type, Item_Type_2_Array, Item_Type_3_Array, Item_Type_4_Array)
		local Count = 0
		local Start_Pos = 0
		for j = 1, 4 do
			--Zeus是否是连续
			if (result[j][i] == Item_Type)
			then
				if (Count == 0)
				then
					Start_Pos = j
				end
				Count = Count + 1
			else
				Count = 0
			end
			if (Count >= 2)
			then
				for pos = Start_Pos, Start_Pos + Count - 1 do
					if (Count == 2)
					then
						result[pos][i] = Item_Type_2_Array[pos - Start_Pos + 1]
					end
					if (Count == 3)
					then
						result[pos][i] = Item_Type_3_Array[pos - Start_Pos + 1]
					end
					if (Count == 4)
					then
						result[pos][i] = Item_Type_4_Array[pos - Start_Pos + 1]
					end
				end
			end
			
		end
	end,

	ReplaceBigItem = function(result)
		local Zeus_2_Array = {}
		Zeus_2_Array[1] = Const.Types.Zeus_2_1
		Zeus_2_Array[2] = Const.Types.Zeus_2_2

		local Zeus_3_Array = {}
		Zeus_3_Array[1] = Const.Types.Zeus_3_1
		Zeus_3_Array[2] = Const.Types.Zeus_3_2
		Zeus_3_Array[3] = Const.Types.Zeus_3_3

		local Zeus_4_Array = {}
		Zeus_4_Array[1] = Const.Types.Zeus_4_1
		Zeus_4_Array[2] = Const.Types.Zeus_4_2
		Zeus_4_Array[3] = Const.Types.Zeus_4_3
		Zeus_4_Array[4] = Const.Types.Zeus_4_4	

		local Poseidon_2_Array = {}
		Poseidon_2_Array[1] = Const.Types.Poseidon_2_1
		Poseidon_2_Array[2] = Const.Types.Poseidon_2_2

		local Poseidon_3_Array = {}
		Poseidon_3_Array[1] = Const.Types.Poseidon_3_1
		Poseidon_3_Array[2] = Const.Types.Poseidon_3_2
		Poseidon_3_Array[3] = Const.Types.Poseidon_3_3

		local Poseidon_4_Array = {}
		Poseidon_4_Array[1] = Const.Types.Poseidon_4_1
		Poseidon_4_Array[2] = Const.Types.Poseidon_4_2
		Poseidon_4_Array[3] = Const.Types.Poseidon_4_3
		Poseidon_4_Array[4] = Const.Types.Poseidon_4_4

		local Hardis_2_Array = {}
		Hardis_2_Array[1] = Const.Types.Hardis_2_1
		Hardis_2_Array[2] = Const.Types.Hardis_2_2

		local Hardis_3_Array = {}
		Hardis_3_Array[1] = Const.Types.Hardis_3_1
		Hardis_3_Array[2] = Const.Types.Hardis_3_2
		Hardis_3_Array[3] = Const.Types.Hardis_3_3

		local Hardis_4_Array = {}
		Hardis_4_Array[1] = Const.Types.Hardis_4_1
		Hardis_4_Array[2] = Const.Types.Hardis_4_2
		Hardis_4_Array[3] = Const.Types.Hardis_4_3
		Hardis_4_Array[4] = Const.Types.Hardis_4_4


		for i = 1, 5 do
			Calculate.ReplaceBigItemCol(result, i, Const.Types.Zeus, Zeus_2_Array, Zeus_3_Array, Zeus_4_Array)
			Calculate.ReplaceBigItemCol(result, i, Const.Types.Poseidon, Poseidon_2_Array, Poseidon_3_Array, Poseidon_4_Array)
			Calculate.ReplaceBigItemCol(result, i, Const.Types.Hardis, Hardis_2_Array, Hardis_3_Array, Hardis_4_Array)
		end
	end,

	ReplaceBigItemOneColumn = function (resultCol, Item_Type, Item_Type_2_Array, Item_Type_3_Array, Item_Type_4_Array)
		local Count = 0
		local Start_Pos = 0
		for j = 1, 4 do
			--Zeus是否是连续
			if (resultCol[j] == Item_Type)
			then
				if (Count == 0)
				then
					Start_Pos = j
				end
				Count = Count + 1
			else
				Count = 0
			end
			if (Count >= 2)
			then
				for pos = Start_Pos, Start_Pos + Count - 1 do
					if (Count == 2)
					then
						resultCol[pos] = Item_Type_2_Array[pos - Start_Pos + 1]
					end
					if (Count == 3)
					then
						resultCol[pos] = Item_Type_3_Array[pos - Start_Pos + 1]
					end
					if (Count == 4)
					then
						resultCol[pos] = Item_Type_4_Array[pos - Start_Pos + 1]
					end
				end
			end
			
		end
	end,

	ReplaceSubBigItem = function(resultCol)
		local Zeus_2_Array = {}
		Zeus_2_Array[1] = Const.Types.Zeus_2_1
		Zeus_2_Array[2] = Const.Types.Zeus_2_2

		local Zeus_3_Array = {}
		Zeus_3_Array[1] = Const.Types.Zeus_3_1
		Zeus_3_Array[2] = Const.Types.Zeus_3_2
		Zeus_3_Array[3] = Const.Types.Zeus_3_3

		local Zeus_4_Array = {}
		Zeus_4_Array[1] = Const.Types.Zeus_4_1
		Zeus_4_Array[2] = Const.Types.Zeus_4_2
		Zeus_4_Array[3] = Const.Types.Zeus_4_3
		Zeus_4_Array[4] = Const.Types.Zeus_4_4	

		local Poseidon_2_Array = {}
		Poseidon_2_Array[1] = Const.Types.Poseidon_2_1
		Poseidon_2_Array[2] = Const.Types.Poseidon_2_2

		local Poseidon_3_Array = {}
		Poseidon_3_Array[1] = Const.Types.Poseidon_3_1
		Poseidon_3_Array[2] = Const.Types.Poseidon_3_2
		Poseidon_3_Array[3] = Const.Types.Poseidon_3_3

		local Poseidon_4_Array = {}
		Poseidon_4_Array[1] = Const.Types.Poseidon_4_1
		Poseidon_4_Array[2] = Const.Types.Poseidon_4_2
		Poseidon_4_Array[3] = Const.Types.Poseidon_4_3
		Poseidon_4_Array[4] = Const.Types.Poseidon_4_4

		local Hardis_2_Array = {}
		Hardis_2_Array[1] = Const.Types.Hardis_2_1
		Hardis_2_Array[2] = Const.Types.Hardis_2_2

		local Hardis_3_Array = {}
		Hardis_3_Array[1] = Const.Types.Hardis_3_1
		Hardis_3_Array[2] = Const.Types.Hardis_3_2
		Hardis_3_Array[3] = Const.Types.Hardis_3_3

		local Hardis_4_Array = {}
		Hardis_4_Array[1] = Const.Types.Hardis_4_1
		Hardis_4_Array[2] = Const.Types.Hardis_4_2
		Hardis_4_Array[3] = Const.Types.Hardis_4_3
		Hardis_4_Array[4] = Const.Types.Hardis_4_4


		Calculate.ReplaceBigItemOneColumn(resultCol, Const.Types.Zeus, Zeus_2_Array, Zeus_3_Array, Zeus_4_Array)
		Calculate.ReplaceBigItemOneColumn(resultCol, Const.Types.Poseidon, Poseidon_2_Array, Poseidon_3_Array, Poseidon_4_Array)
		Calculate.ReplaceBigItemOneColumn(resultCol, Const.Types.Hardis, Hardis_2_Array, Hardis_3_Array, Hardis_4_Array)
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

	GenLegendsofOlympusColumn = function(player, config, column)
		local player_id = player.id
		local sequence = config[column].sequence_array
		local sequence_len = #sequence
		local index = math.random_ext(player, 1, sequence_len)

		if (GlobalSlotsTest[player_id] ~= nil)
		then
			sequence, sequence_len, index = CommonCal.Calculate.GetSequence(player_id, column)
		end

		local index_1, index_2, index_3 = index % sequence_len + 1, (index + 1) % sequence_len + 1, (index + 2) % sequence_len + 1

		return {sequence[index], sequence[index_1], sequence[index_2], sequence[index_3]}
	end,

	GetMaxBetAmount = function(player)
		local LegendsofOlympusBetAmountConfig = CommonCal.Calculate.get_config(player, "LegendsofOlympusBetAmountConfig")
        local old_req_level = 0
        for k, v in ipairs(LegendsofOlympusBetAmountConfig)
        do
            if (player.character.level >= old_req_level and player.character.level < v.required_level)
            then
                return LegendsofOlympusBetAmountConfig[k - 1].single_amount
            end
            old_req_level = v.required_level
		end
		
		local max_index = #LegendsofOlympusBetAmountConfig
		if (player.character.level >= LegendsofOlympusBetAmountConfig[max_index].required_level)
		then
			return LegendsofOlympusBetAmountConfig[max_index].single_amount
		end
        return 0
	end,
	
	GenItemResult = function (player, last_win_chip, result, free_spin_num, loop_num)
		local tran_result = nil
		
		local reel_file_name = "LegendsofOlympusBaseReelConfig"

		if (player.character.level <= tonumber(ConstValue[8].value))
		then		
			reel_file_name = "LegendsofOlympusNewHand1BaseReelConfig"
		elseif (player.character.level <= tonumber(ConstValue[9].value))
		then
			reel_file_name = "LegendsofOlympusNewHand2BaseReelConfig"
		elseif (player.character.level <= tonumber(ConstValue[10].value))
		then
			reel_file_name = "LegendsofOlympusNewHand3BaseReelConfig"
		end
		
		if (free_spin_num == 20)
		then
			reel_file_name = "LegendsofOlympusfeature1ReelConfig"

			if (player.character.level <= tonumber(ConstValue[8].value))
			then		
				reel_file_name = "LegendsofOlympusNewHand1feature1ReelConfig"
			elseif (player.character.level <= tonumber(ConstValue[9].value))
			then
				reel_file_name = "LegendsofOlympusNewHand2feature1ReelConfig"
			elseif (player.character.level <= tonumber(ConstValue[10].value))
			then
				reel_file_name = "LegendsofOlympusNewHand3feature1ReelConfig"
			end

		elseif (free_spin_num == 10)
		then
			reel_file_name = "LegendsofOlympusfeature2ReelConfig"

			if (player.character.level <= tonumber(ConstValue[8].value))
			then		
				reel_file_name = "LegendsofOlympusNewHand1feature2ReelConfig"
			elseif (player.character.level <= tonumber(ConstValue[9].value))
			then
				reel_file_name = "LegendsofOlympusNewHand2feature2ReelConfig"
			elseif (player.character.level <= tonumber(ConstValue[10].value))
			then
				reel_file_name = "LegendsofOlympusNewHand3feature2ReelConfig"
			end
		elseif (free_spin_num == 5)
		then
			reel_file_name = "LegendsofOlympusfeature3ReelConfig"

			if (player.character.level <= tonumber(ConstValue[8].value))
			then		
				reel_file_name = "LegendsofOlympusNewHand1feature3ReelConfig"
			elseif (player.character.level <= tonumber(ConstValue[9].value))
			then
				reel_file_name = "LegendsofOlympusNewHand2feature3ReelConfig"
			elseif (player.character.level <= tonumber(ConstValue[10].value))
			then
				reel_file_name = "LegendsofOlympusNewHand3feature3ReelConfig"
			end
		end
		local config = CommonCal.Calculate.get_config(player, reel_file_name)

		local drop_items_list = {}
		if (last_win_chip > 0)
		then
			local wild_columns = {4, 3, 2, 1}
			for _,v in pairs(wild_columns) do
				result[v + 1] = table.DeepCopy(result[v])
			end

			local localResult = Calculate.GenLegendsofOlympusColumn(player, config, 1)

			--LOG(RUN, INFO).Format("[SlotsLegendsofOlympus][drop item list1] : %s", Table2Str(localResult))	
			result[1] = localResult

			
			local tempResult = table.DeepCopy(localResult)

			Calculate.ReplaceSubBigItem(tempResult)

			--LOG(RUN, INFO).Format("[SlotsLegendsofOlympus][drop item list2] : %s", Table2Str(tempResult))	
			for _, drop_item in pairs(tempResult) do
				table.insert(drop_items_list, drop_item)
			end
			
		else

			local wild_columns = {1, 2, 3, 4, 5}
			for _,v in ipairs(wild_columns) do
				local localResult = Calculate.GenLegendsofOlympusColumn(player, config, v)
	
			
				result[v] = localResult
			end
			--------------------------test begin --------------------------
			--[[
			local test_result = {{9, 6, 8, 10}, {1, 5, 11, 4}, {5, 4, 10, 11}, {11, 8, 3, 3}, {2, 2, 2, 9}}

			for _,v in ipairs(wild_columns) do
				result[v] = test_result[v]
			end
			--]]
			--------------------------test end--------------------------------

		end
		tran_result = Calculate.TransResult(result)

		--LOG(RUN, INFO).Format("[SlotsLegendsofOlympus][GenItemResult] origin_result结果")	
		--for i = 1, 4 do
		--	LOG(RUN, INFO).Format("%s, %s, %s, %s, %s", tran_result[i][1], tran_result[i][2], tran_result[i][3], tran_result[i][4], tran_result[i][5])	
		--end

		--local drop_item_str = json.encode(drop_items_list)
		
		return tran_result, drop_items_list, reel_file_name
	end,
	
	UpdateFreeBous = function(legendsof_olympus, free_spin_num_array)
		legendsof_olympus.free_spin_bouts = 0
		if (#free_spin_num_array > 0)
		then
			for k, v in pairs(free_spin_num_array)
			do
				legendsof_olympus.free_spin_bouts = legendsof_olympus.free_spin_bouts + v.free_spin_bouts
			end
		end
	end,

	GetScatterCount = function(data)
        local scatter_count = 0

        for i = 1, 4 do
            for j = 1, 5 do
                if data[i][j] == Const.Types.Scatter then
                    scatter_count = scatter_count + 1
                end
            end
		end
		
        return scatter_count
    end,
    
-- --generate总的中奖信息
	GenPrizeInfo = function(player, result)
		local prize_info = {}
		local remove_item_list = {}
		local total_payrate = 0
		local LegendsofOlympusPayrateConfig = CommonCal.Calculate.get_config(player, "LegendsofOlympusPayrateConfig")
		for line_index, v in ipairs(Const.Lines) do
			local line_data = {}
			local test_line_data = {}
			for i = 1, 5 do
				--v[i]是行,i是列
				table.insert(line_data, result[v[i]][i])
				table.insert(test_line_data, {row = v[i], column = i, result[v[i]][i]})
			end

			local one_line_prize = Calculate.GenOneLinePrize(player, line_data)

			for _, item in ipairs(one_line_prize) do
				
				local config = LegendsofOlympusPayrateConfig[item.item_id]
				if (config ~= nil)
				then
					local payrate = config.payrate[item.continue_count - 2]
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
