module("SlotsLuxuryLifeCal", package.seeall)
require "Util/TableExt"
require "Common/CommonCal"

Const = {
	BaseLines = {
		[1] = {1,1,1,1,1,1},
		[2] = {1,1,2,2,1,1},
		[3] = {1,1,3,3,1,1},
		[4] = {1,1,4,4,1,1},
		[5] = {2,3,4,4,3,2},
		[6] = {2,3,3,3,3,2},
		[7] = {2,3,2,2,3,2},
		[8] = {2,3,1,1,3,2},
		[9] = {2,2,2,2,2,2},
		[10] = {2,2,1,1,2,2},
		[11] = {2,2,3,3,2,2},
		[12] = {2,2,4,4,2,2},
		[13] = {1,2,3,3,2,1},
		[14] = {1,2,4,4,2,1},
		[15] = {1,2,2,2,2,1},
		[16] = {1,2,1,1,2,1},
		[17] = {1,3,4,4,3,1},
		[18] = {1,3,3,3,3,1},
		[19] = {1,3,2,2,3,1},
		[20] = {1,3,1,1,3,1},
		[21] = {2,1,1,1,1,2},
		[22] = {2,1,2,2,1,2},
		[23] = {2,1,3,3,1,2},
		[24] = {2,1,4,4,1,2},
		[25] = {1,1,2,3,3,2},
		[26] = {2,3,3,2,1,1},
		[27] = {2,3,3,2,2,1},
		[28] = {1,2,2,3,3,2},
		[29] = {1,1,1,2,2,1},
		[30] = {2,2,2,3,3,2},
		[31] = {1,2,2,1,1,1},
		[32] = {2,3,3,2,2,2},
		[33] = {2,1,3,2,3,1},
		[34] = {1,3,2,3,1,2},
		[35] = {2,2,3,2,2,1},
		[36] = {1,2,2,3,2,2},
		[37] = {2,2,2,3,2,1},
		[38] = {1,2,3,2,2,2},
		[39] = {1,1,1,2,2,2},
		[40] = {2,2,2,1,1,1},
	},

	FreeLines = {
		[1] = {1,1,1,1,1,1},
		[2] = {1,1,2,2,1,1},
		[3] = {1,1,3,3,1,1},
		[4] = {1,1,4,4,1,1},
		[5] = {1,4,4,4,4,1},
		[6] = {1,4,3,3,4,1},
		[7] = {1,4,2,2,4,1},
		[8] = {1,4,1,1,4,1},
		[9] = {2,2,1,1,2,2},
		[10] = {2,2,2,2,2,2},
		[11] = {2,2,3,3,2,2},
		[12] = {2,2,4,4,2,2},
		[13] = {1,2,4,4,2,1},
		[14] = {1,3,3,3,3,1},
		[15] = {1,3,2,2,3,1},
		[16] = {1,3,1,1,3,1},
		[17] = {1,2,1,1,2,1},
		[18] = {1,2,2,2,2,1},
		[19] = {1,2,3,3,2,1},
		[20] = {1,2,4,4,2,1},
		[21] = {2,2,4,4,2,2},
		[22] = {2,3,3,3,3,2},
		[23] = {2,3,2,2,3,2},
		[24] = {2,3,1,1,3,2},
		[25] = {1,1,2,3,4,2},
		[26] = {2,4,3,2,1,1},
		[27] = {2,2,3,2,3,1},
		[28] = {1,3,2,3,2,2},
		[29] = {1,3,2,1,2,2},
		[30] = {2,2,3,2,1,1},
		[31] = {1,3,2,3,4,2},
		[32] = {2,2,3,2,1,1},
		[33] = {1,2,3,4,3,1},
		[34] = {2,3,2,1,2,2},
		[35] = {1,2,3,4,4,2},
		[36] = {2,3,2,1,1,1},
		[37] = {1,1,2,3,2,2},
		[38] = {2,2,3,4,3,1},
		[39] = {2,4,3,2,3,1},
		[40] = {1,3,4,3,4,2},
	},

	Types = {
		Aircraft = 1,--私人飞机
		Yacht = 2,--游艇
		Villa  = 3, --别墅
		LuxuryCar  = 4,--豪车
		DiamondRing = 5, --钻戒
		HandLadle = 6, --手包
		HighHeelShoes = 7, --高跟鞋
		Perfume = 8,--香水
		Spade  = 9,--黑桃
		Hearts = 10, --红桃
		PlumBlossom = 11, --梅花
		SquareSheet = 12,--方片
		Wild = 13,

		Aircraft_4_1 = 1001,
		Aircraft_4_2 = 1002,
		Aircraft_4_3 = 1003,
		Aircraft_4_4 = 1004,

		Yacht_4_1 = 2001,
		Yacht_4_2 = 2002,
		Yacht_4_3 = 2003,
		Yacht_4_4 = 2004,

		Villa_4_1 = 3001,
		Villa_4_2 = 3002,
		Villa_4_3 = 3003,
		Villa_4_4 = 3004,

		LuxuryCar_4_1 = 4001,
		LuxuryCar_4_2 = 4002,
		LuxuryCar_4_3 = 4003,
		LuxuryCar_4_4 = 4004,

		DiamondRing_2_1 = 501,
		DiamondRing_2_2 = 502,

		DiamondRing_4_1 = 5001,
		DiamondRing_4_2 = 5002,
		DiamondRing_4_3 = 5003,
		DiamondRing_4_4 = 5004,

		HandLadle_2_1 = 601,
		HandLadle_2_2 = 602,

		HandLadle_4_1 = 6001,
		HandLadle_4_2 = 6002,
		HandLadle_4_3 = 6003,
		HandLadle_4_4 = 6004,

		HighHeelShoes_2_1 = 701,
		HighHeelShoes_2_2 = 702,

		HighHeelShoes_4_1 = 7001,
		HighHeelShoes_4_2 = 7002,
		HighHeelShoes_4_3 = 7003,
		HighHeelShoes_4_4 = 7004,		

		Perfume_2_1 = 801,
		Perfume_2_2 = 802,

		Perfume_4_1 = 8001,
		Perfume_4_2 = 8002,
		Perfume_4_3 = 8003,
		Perfume_4_4 = 8004,	
	},

	PrizeDirection = {
		LEFT = 1,
		RIGHT = 2,
	}
}

Util = {
	GenWildPos = function(line_data)
		local pos = {}
		for i = 1, 6 do
			if line_data[i] == Const.Types.Wild then
				table.insert(pos, i)
			end
		end
		return pos
	end,


	GenLeftWildReplaceValue = function( line_data, wild_pos)
        if wild_pos == 1 then
			for i = 2, 6, 1 do
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
		if wild_pos == 6 then
			for i = 5, 1, -1 do
                if line_data[i] ~= Const.Types.Wild then
                    return  line_data[i]
                end
            end
        else
            local right_value
			for i = wild_pos + 1, 6, 1 do
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
			for i = 2, 6, 1 do
                if line_data[i] ~= Const.Types.Wild then
                    return  line_data[i]
                end
            end
        elseif wild_pos == 6 then
			for i = 5, 1, -1 do
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
			for i = wild_pos + 1, 6, 1 do
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
			stop = 6
			step = 1
		elseif direction == Const.PrizeDirection.RIGHT then
			start = 6
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

    GenWildContinueCount = function(line_data, direction)
        local wild_count = 0
        local start, stop, step
        if direction == Const.PrizeDirection.LEFT then
            start, stop, step = 1, 6, 1
        elseif direction == Const.PrizeDirection.RIGHT then
            start, stop, step = 6, 1, -1
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

	GenWildResult = function(result, freeze_list)
		for k, v in pairs(freeze_list)
		do
			result[v.row][v.column] = Const.Types.Wild
		end
	end,

	ReplaceBigItemCol = function (result, i, Item_Type, Item_Type_2_Array, Item_Type_4_Array)
		local is_replace = 0
		local Count = 0
		local Start_Pos = 0
		for j = 1, 4 do
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
						if (Item_Type_2_Array ~= nil)
						then
							result[pos][i] = Item_Type_2_Array[pos - Start_Pos + 1]
							is_replace = 1
						end
					end
					if (Count == 4)
					then
						if (Item_Type_4_Array ~= nil)
						then
							result[pos][i] = Item_Type_4_Array[pos - Start_Pos + 1]
							is_replace = 1
						end
					end
				end
			end
		end
		return is_replace
	end,

	ReplaceBigItem = function(is_free_spin, result)
		local Aircraft_4_Array = {}
		Aircraft_4_Array[1] = Const.Types.Aircraft_4_1
		Aircraft_4_Array[2] = Const.Types.Aircraft_4_2
		Aircraft_4_Array[3] = Const.Types.Aircraft_4_3
		Aircraft_4_Array[4] = Const.Types.Aircraft_4_4

		local Yacht_4_Array = {}
		Yacht_4_Array[1] = Const.Types.Yacht_4_1
		Yacht_4_Array[2] = Const.Types.Yacht_4_2
		Yacht_4_Array[3] = Const.Types.Yacht_4_3
		Yacht_4_Array[4] = Const.Types.Yacht_4_4

		local Yacht_4_Array = {}
		Yacht_4_Array[1] = Const.Types.Yacht_4_1
		Yacht_4_Array[2] = Const.Types.Yacht_4_2
		Yacht_4_Array[3] = Const.Types.Yacht_4_3
		Yacht_4_Array[4] = Const.Types.Yacht_4_4

		local Villa_4_Array = {}
		Villa_4_Array[1] = Const.Types.Villa_4_1
		Villa_4_Array[2] = Const.Types.Villa_4_2
		Villa_4_Array[3] = Const.Types.Villa_4_3
		Villa_4_Array[4] = Const.Types.Villa_4_4


		local LuxuryCar_4_Array = {}
		LuxuryCar_4_Array[1] = Const.Types.LuxuryCar_4_1
		LuxuryCar_4_Array[2] = Const.Types.LuxuryCar_4_2
		LuxuryCar_4_Array[3] = Const.Types.LuxuryCar_4_3
		LuxuryCar_4_Array[4] = Const.Types.LuxuryCar_4_4

		local DiamondRing_2_Array = {}
		DiamondRing_2_Array[1] = Const.Types.DiamondRing_2_1
		DiamondRing_2_Array[2] = Const.Types.DiamondRing_2_2

		local DiamondRing_4_Array = {}
		DiamondRing_4_Array[1] = Const.Types.DiamondRing_4_1
		DiamondRing_4_Array[2] = Const.Types.DiamondRing_4_2
		DiamondRing_4_Array[3] = Const.Types.DiamondRing_4_3
		DiamondRing_4_Array[4] = Const.Types.DiamondRing_4_4

		local HandLadle_2_Array = {}
		HandLadle_2_Array[1] = Const.Types.HandLadle_2_1
		HandLadle_2_Array[2] = Const.Types.HandLadle_2_2

		local HandLadle_4_Array = {}
		HandLadle_4_Array[1] = Const.Types.HandLadle_4_1
		HandLadle_4_Array[2] = Const.Types.HandLadle_4_2
		HandLadle_4_Array[3] = Const.Types.HandLadle_4_3
		HandLadle_4_Array[4] = Const.Types.HandLadle_4_4

		local HighHeelShoes_2_Array = {}
		HighHeelShoes_2_Array[1] = Const.Types.HighHeelShoes_2_1
		HighHeelShoes_2_Array[2] = Const.Types.HighHeelShoes_2_2

		local HighHeelShoes_4_Array = {}
		HighHeelShoes_4_Array[1] = Const.Types.HighHeelShoes_4_1
		HighHeelShoes_4_Array[2] = Const.Types.HighHeelShoes_4_2
		HighHeelShoes_4_Array[3] = Const.Types.HighHeelShoes_4_3
		HighHeelShoes_4_Array[4] = Const.Types.HighHeelShoes_4_4

		local Perfume_2_Array = {}
		Perfume_2_Array[1] = Const.Types.Perfume_2_1
		Perfume_2_Array[2] = Const.Types.Perfume_2_2

		local Perfume_4_Array = {}
		Perfume_4_Array[1] = Const.Types.Perfume_4_1
		Perfume_4_Array[2] = Const.Types.Perfume_4_2
		Perfume_4_Array[3] = Const.Types.Perfume_4_3
		Perfume_4_Array[4] = Const.Types.Perfume_4_4

		local wild_columns = {1, 2, 3, 4, 5, 6}
		if (not is_free_spin)
		then
			wild_columns = {3, 4}
		end
		for _, i in ipairs(wild_columns)
		do
			local loop = 1
			while (loop == 1)
			do
				loop = Calculate.ReplaceBigItemCol(result, i, Const.Types.Aircraft, nil, Aircraft_4_Array)
			end
			
			loop = 1
			while (loop == 1)
			do
				loop = Calculate.ReplaceBigItemCol(result, i, Const.Types.Yacht, nil, Yacht_4_Array)
			end
			
			loop = 1
			while (loop == 1)
			do
				loop = Calculate.ReplaceBigItemCol(result, i, Const.Types.Villa, nil, Villa_4_Array)
			end
			
			loop = 1
			while (loop == 1)
			do
				loop = Calculate.ReplaceBigItemCol(result, i, Const.Types.LuxuryCar, nil, LuxuryCar_4_Array)
			end
			
			loop = 1
			while (loop == 1)
			do
				loop = Calculate.ReplaceBigItemCol(result, i, Const.Types.DiamondRing, DiamondRing_2_Array, DiamondRing_4_Array)
			end
			
			loop = 1
			while (loop == 1)
			do
				loop = Calculate.ReplaceBigItemCol(result, i, Const.Types.HandLadle, HandLadle_2_Array, HandLadle_4_Array)
			end

			loop = 1
			while (loop == 1)
			do
				loop = Calculate.ReplaceBigItemCol(result, i, Const.Types.HighHeelShoes, HighHeelShoes_2_Array , HighHeelShoes_4_Array)
			end

			loop = 1
			while (loop == 1)
			do
				loop = Calculate.ReplaceBigItemCol(result, i, Const.Types.Perfume, Perfume_2_Array  , Perfume_4_Array )
			end
		end

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
		local has_normal_prize = item_id and continue_count and (continue_count >= 3)
		local has_wild_prize = wild_count and (wild_count >= 3)

		local LuxuryLifePayrateConfig = CommonCal.Calculate.get_config(player, "LuxuryLifePayrateConfig")
		if has_wild_prize and has_normal_prize then
			local normal_payrate = LuxuryLifePayrateConfig[item_id].payrate[continue_count - 2]
			local wild_payrate = LuxuryLifePayrateConfig[Const.Types.Wild].payrate[wild_count - 2]
			if normal_payrate >= wild_payrate then
				local item = {
					item_id = item_id,
					continue_count = continue_count,
					from_index = (direction == Const.PrizeDirection.LEFT) and 1 or (6 - continue_count + 1),
					to_index = (direction == Const.PrizeDirection.LEFT) and continue_count or 6,
				}
				if (Calculate.IsRepeatedPrize(prize_list, item) == 0)
				then
					table.insert(prize_list, item)
				end
			else
				local item = {
					item_id = Const.Types.Wild,
					continue_count = wild_count,
					from_index = (direction == Const.PrizeDirection.LEFT) and 1 or (6 - wild_count + 1),
					to_index = (direction == Const.PrizeDirection.LEFT) and wild_count or 6,
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
				from_index = (direction == Const.PrizeDirection.LEFT) and 1 or (6 - continue_count + 1),
				to_index = (direction == Const.PrizeDirection.LEFT) and continue_count or 6,
			}
			if (Calculate.IsRepeatedPrize(prize_list, item) == 0)
			then
				table.insert(prize_list, item)
			end
			
		elseif has_wild_prize then
			local item = {
				item_id = Const.Types.Wild,
				continue_count = wild_count,
				from_index = (direction == Const.PrizeDirection.LEFT) and 1 or (6 - wild_count + 1),
				to_index = (direction == Const.PrizeDirection.LEFT) and wild_count or 6,
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

		return prize_list
	end,



	-- --trans 5*4 matrix to 4*5 matrix
	TransResult = function(result)
		local tran_result = {}
		for row = 1, 4 do
			tran_result[row] = {}
			for col = 1, 6 do
				tran_result[row][col] = result[col][row]
			end
		end
		return tran_result
	end,

	-- --将4*6的矩阵转换成一维数组,以列优先
	TransResultToList = function(result)
		local list = {}

		for i = 1, 6 do
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
		local LuxuryLifeBetAmountConfig = CommonCal.Calculate.get_config(player, "LuxuryLifeBetAmountConfig")
        local old_req_level = 0
        for k, v in ipairs(LuxuryLifeBetAmountConfig)
        do
            if (player.character.level >= old_req_level and player.character.level < v.required_level)
            then
                return LuxuryLifeBetAmountConfig[k - 1].single_amount
            end
            old_req_level = v.required_level
		end
		
		local max_index = #LuxuryLifeBetAmountConfig
		if (player.character.level >= LuxuryLifeBetAmountConfig[max_index].required_level)
		then
			return LuxuryLifeBetAmountConfig[max_index].single_amount
		end
        return 0
    end,

	GenLuxuryLifeColumn = function(player, config, column)
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

	GetMultiply = function(item_id, free_spin_type)
		local target_item_id = 0
		if (free_spin_type == 2)
		then
			target_item_id = 12
		elseif (free_spin_type == 3)
		then
			target_item_id = 13
		elseif (free_spin_type == 4)
		then
			target_item_id = 14
		elseif (free_spin_type == 5)
		then
			target_item_id = 15
		elseif (free_spin_type == 6)
		then
			target_item_id = 16
		end
		if (item_id == target_item_id)
		then
			if (target_item_id == Const.Types.TyrannosaurusRexHead)
			then
				return 2
			end

			if (target_item_id == Const.Types.TriceratopsHead)
			then
				return 3
			end

			if (target_item_id == Const.Types.StegosaurusHead)
			then
				return 4
			end

			if (target_item_id == Const.Types.BrontosaurusHead)
			then
				return 5
			end

			if (target_item_id == Const.Types.Velociraptor)
			then
				return 6
			end
		end

		return 0
	end,

	UpdateFreeBous = function(luxury_life, free_spin_num_array)
		luxury_life.free_spin_bouts = 0
		if (free_spin_num_array and #free_spin_num_array > 0)
		then
			for k, v in pairs(free_spin_num_array)
			do
				luxury_life.free_spin_bouts = luxury_life.free_spin_bouts + v.free_spin_bouts
			end
		end
	end,

	AddFreeProgress = function(loop_num, free_spin_progress_array, result)
		local free_spin_progress_info = nil
		if (loop_num == 0)
		then
			free_spin_progress_info = free_spin_progress_array[1]
			if (free_spin_progress_info == nil)
			then
				free_spin_progress_info = {}
			end
		else
			free_spin_progress_array[2] = table.DeepCopy(free_spin_progress_array[1])
			free_spin_progress_info = free_spin_progress_array[2]
			if (free_spin_progress_info == nil)
			then
				free_spin_progress_info = {}
			end			
		end
		local item_id = nil
		for i = 3, 4 do
			for j = 2, 3 do
				if (result[j][i] > 0)
				then
					if (item_id == nil)
					then
						item_id = result[j][i]
					elseif (item_id ~= result[j][i])
					then
						item_id = 0
						break
					end
					--table.insert(list, result[j][i])
				end
			end
			if (item_id == 0)
			then
				break
			end
		end

		local special_item = 0
		if (item_id == Const.Types.DiamondRing or item_id == Const.Types.HandLadle or item_id == Const.Types.HighHeelShoes or item_id == Const.Types.Perfume)
		then
			local is_exist = 0
			for k, v in pairs(free_spin_progress_info)
			do
				if (v == item_id)
				then
					is_exist = 1
					break
				end
			end
			if (is_exist == 0)
			then
				special_item = item_id
				table.insert(free_spin_progress_info, item_id)
			end
		end

		if (loop_num == 0)
		then
			free_spin_progress_array[1] = free_spin_progress_info
		else
			free_spin_progress_array[2]	= free_spin_progress_info	
		end

		return free_spin_progress_array, special_item
	end,

	IsFreeze = function(result)
		local freeze_list = {}
		local is_all_freeze = 1
		local wild_columns = {2, 5}
		for _, v in pairs(wild_columns) do
			local is_freeze = 0
			for i = 1, 4 do
				if (result[i][v] == Const.Types.Wild)
				then
					is_freeze = 1
					break
				end
			end
			if (is_freeze == 0)
			then
				is_all_freeze = 0
			end
		end

		if (is_all_freeze == 1)
		then
			for _, v in pairs(wild_columns) do
				for i = 1, 4 do
					if (result[i][v] ~= 0)
					then
						table.insert(freeze_list, {row = i, column = v})
					end
				end
			end
		end

		return freeze_list
	end,

	GenItemResult = function (player, result, is_free_spin, loop_num, freeze_list)
		local tran_result = nil
		--local respin_items_list = {}
		
		local reel_file_name = is_free_spin and "LuxuryLifeFeatureReelConfig" or "LuxuryLifeBaseReelConfig"
		local config = CommonCal.Calculate.get_config(player, reel_file_name)

		reel_file_name, config = CommonCal.Calculate.get_new_hand_config(player, is_free_spin, reel_file_name, config, "LuxuryLife")

		local wild_columns = {1, 2, 3, 4, 5, 6}
		if (loop_num > 0)
		then
			wild_columns = {3, 4}
		end

		local item_count_list = {}
		local sequence = config[2].sequence_array
		local sequence_len = #sequence
		for i = 1, sequence_len do
			local item = sequence[i]
			if (item_count_list[item] == nil)
			then
				item_count_list[item] = 1
			else
				item_count_list[item] = item_count_list[item] + 1
			end
		end

		local local_weight_tab = {}

		for local_k, local_v in pairs(item_count_list)
		do
			local rand_value = local_v / sequence_len
			local_weight_tab[local_k] = rand_value
		end
		
		local item_id = math.rand_weight(player, local_weight_tab)

		for _,v in ipairs(wild_columns) do
			local localResult = Calculate.GenLuxuryLifeColumn(player, config, v)

			if (GlobalSlotsTest[player.id] == nil)
			then
				if (is_free_spin)
				then
					if (v >= 2 and v <= 5)
					then
						localResult = {item_id, item_id, item_id, item_id}
					end		

					if (v == 1 or v == 6)
					then
						localResult[3] = 0
						localResult[4] = 0
					end
				else
					if (v == 1 or v == 6)
					then
						localResult[3] = 0
						localResult[4] = 0
					elseif (v == 2 or v == 5)
					then
						localResult[4] = 0
					end
				end
			end

			result[v] = localResult
		end

		tran_result = Calculate.TransResult(result)
		if (#freeze_list > 0)
		then
			for k, v in pairs(freeze_list)
			do
				tran_result[v.row][v.column] = Const.Types.Wild
			end

			--[[
			for i = 1, 6 do
				for j = 1, 4 do
					if (tran_result[j][i] ~= 0)
					then
						table.insert(respin_items_list, tran_result[j][i])
					end
				end
			end
			--]]
		end
		return tran_result, reel_file_name--, respin_items_list
	end,
	
    GenFreeSpinCount = function(data)
        local scatter_count = 0

        for i = 1, 4 do
            for j = 1, 6 do
                if data[i][j] == Const.Types.Scatter then
                    scatter_count = scatter_count + 1
                end
            end
		end
		
		if (scatter_count >= 3)
		then
			return 10, Const.Types.Scatter
		end
        return 0, 0
	end,
	

	-- --generate总的中奖信息
	GenPrizeInfo = function(player, result, is_free_spin)
		local prize_info = {}
		local total_payrate = 0

		local LuxuryLifePayrateConfig = CommonCal.Calculate.get_config(player, "LuxuryLifePayrateConfig")

		local Lines = Const.BaseLines
		if (is_free_spin)
		then
			Lines = Const.FreeLines
		end
		for line_index, v in ipairs(Lines) do
			local line_data = {}
			local number = 0
			for i = 1, 6 do
				--v[i]是行,i是列
				table.insert(line_data, result[v[i]][i])
			end
			local one_line_prize = Calculate.GenOneLinePrize(player, line_data)

			for _, item in ipairs(one_line_prize) do

				number = Calculate.GetMultiply(item.item_id, free_spin_type)
				
				local config = LuxuryLifePayrateConfig[item.item_id]
				if (config ~= nil)
				then
					local payrate = config.payrate[item.continue_count - 2]
					if (payrate > 0)
					then
						item.payrate = payrate
						item.line_index = line_index
						table.insert(prize_info, item)
						if (number > 0)
						then
							total_payrate = total_payrate + item.payrate * number
						else
							total_payrate = total_payrate + item.payrate
						end
					end				
				end

			end
		end
		--LOG(RUN, INFO).Format("[SlotsLuxuryLife][GenPrizeInfo] total_payrate is: %s", total_payrate)
		return prize_info, total_payrate
	end,
}
