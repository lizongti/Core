module("SlotsBruceLeeCal", package.seeall)
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
		GongFu = 1,
		Dress_Lee = 2,
		Barebacked_Lee = 3,
		Green_Hornet_Lee = 4,
		Jeet_Kune_Do = 5,
		Nunchakus = 6,
		Wooden_Pile = 7,
		Long = 8,
		Wild = 9,
		Yellow_Clothes_Lee = 10,
		Scatter = 11,
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
		local BruceLeePayrateConfig = CommonCal.Calculate.get_config(player, "BruceLeePayrateConfig")
		local has_normal_prize = item_id and continue_count and (continue_count >= 3)
		local has_wild_prize = wild_count and (wild_count >= 3)
		if has_wild_prize and has_normal_prize then
			local normal_payrate = BruceLeePayrateConfig[item_id].payrate[continue_count - 2]
			local wild_payrate = BruceLeePayrateConfig[Const.Types.Wild].payrate[wild_count - 2]
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
		Calculate.CompareNormalAndWild(player, left_item_id, left_continue_count, left_wild_count, prize_list, Const.PrizeDirection.LEFT)
	

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

	GetMaxBetAmount = function(player)
		local BruceLeeBetAmountConfig = CommonCal.Calculate.get_config(player, "BruceLeeBetAmountConfig")
        local old_req_level = 0
        for k, v in ipairs(BruceLeeBetAmountConfig)
        do
            if (player.character.level >= old_req_level and player.character.level < v.required_level)
            then
                return BruceLeeBetAmountConfig[k - 1].single_amount
            end
            old_req_level = v.required_level
		end
		
		local max_index = #BruceLeeBetAmountConfig
		if (player.character.level >= BruceLeeBetAmountConfig[max_index].required_level)
		then
			return BruceLeeBetAmountConfig[max_index].single_amount
		end
        return 0
	end,
	
	GenBruceLeeColumn = function(player, config, column)
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

	GenItemResult = function (player, result, free_spin_num, loop_num, freeze_list)
		local tran_result = nil
		local respin_items_list = {}
		local config = CommonCal.Calculate.get_config(player, "BruceLeeBaseReelConfig")
		local reel_file_name = "BruceLeeBaseReelConfig"
		if (free_spin_num > 0)
		then
			if (loop_num == 0)
			then
				reel_file_name = "BruceLeeFeatureReelConfig"

				if (player.character.level <= tonumber(ConstValue[8].value))
				then		
					reel_file_name = "BruceLeeNewHand1FeatureReelConfig"
				elseif (player.character.level <= tonumber(ConstValue[9].value))
				then
					reel_file_name = "BruceLeeNewHand2FeatureReelConfig"
				elseif (player.character.level <= tonumber(ConstValue[10].value))
				then
					reel_file_name = "BruceLeeNewHand3FeatureReelConfig"
				end

			else
				config = CommonCal.Calculate.get_config(player, "BruceLeeFeatureRespinReelConfig")
				reel_file_name = "BruceLeeFeatureRespinReelConfig"

				if (player.character.level <= tonumber(ConstValue[8].value))
				then		
					reel_file_name = "BruceLeeNewHand1FeatureRespinReelConfig"
				elseif (player.character.level <= tonumber(ConstValue[9].value))
				then
					reel_file_name = "BruceLeeNewHand2FeatureRespinReelConfig"
				elseif (player.character.level <= tonumber(ConstValue[10].value))
				then
					reel_file_name = "BruceLeeNewHand3FeatureRespinReelConfig"
				end
			end
		else
			if (loop_num == 0)
			then
				reel_file_name = "BruceLeeBaseReelConfig"

				if (player.character.level <= tonumber(ConstValue[8].value))
				then		
					reel_file_name = "BruceLeeNewHand1BaseReelConfig"
				elseif (player.character.level <= tonumber(ConstValue[9].value))
				then
					reel_file_name = "BruceLeeNewHand2BaseReelConfig"
				elseif (player.character.level <= tonumber(ConstValue[10].value))
				then
					reel_file_name = "BruceLeeNewHand3BaseReelConfig"
				end
			else
				reel_file_name = "BruceLeeBaseRespinReelConfig"

				if (player.character.level <= tonumber(ConstValue[8].value))
				then		
					reel_file_name = "BruceLeeNewHand1BaseRespinReelConfig"
				elseif (player.character.level <= tonumber(ConstValue[9].value))
				then
					reel_file_name = "BruceLeeNewHand2BaseRespinReelConfig"
				elseif (player.character.level <= tonumber(ConstValue[10].value))
				then
					reel_file_name = "BruceLeeNewHand3BaseRespinReelConfig"
				end
			end
		end
		config = CommonCal.Calculate.get_config(player, reel_file_name)

		local wild_columns = {1, 2, 3, 4, 5}
		for _, v in ipairs(wild_columns) do
			local localResult = Calculate.GenBruceLeeColumn(player, config, v)
		
			result[v] = localResult
		end

		tran_result = Calculate.TransResult(result)

		---------------------test begin--------------------------------
		--if (loop_num == 0)
		--then
		--	tran_result = {{9, 2, 7, 11, 7}, {7, 2, 7, 2, 7}, {7, 9, 1, 2, 3}, {7, 9, 8, 2, 3}}
		--end
		---------------------test end----------------------------------
		if (#freeze_list > 0)
		then
			for k, v in pairs(freeze_list)
			do
				tran_result[v.row][v.column] = Const.Types.Wild
			end

			for i = 1, 5 do
				for j = 1, 4 do
					table.insert(respin_items_list, tran_result[j][i])
				end
			end
		end
		return tran_result, respin_items_list, reel_file_name
	end,
	
	UpdateFreeBous = function(bruce_lee, free_spin_num_array)
		bruce_lee.free_spin_bouts = 0
		if (#free_spin_num_array > 0)
		then
			for k, v in pairs(free_spin_num_array)
			do
				bruce_lee.free_spin_bouts = bruce_lee.free_spin_bouts + v.free_spin_bouts
			end
		end
	end,

	IsFreeze = function(result)
		local freeze_list = {}
		for i = 1, 5 do
			for j = 1, 4 do
				if (result[j][i] == Const.Types.Dress_Lee)
				then
					table.insert(freeze_list, {row = j, column = i})
				end
			end
		end

		return freeze_list
	end,
	
	GenWildResult = function(result, freeze_list)
		for k, v in pairs(freeze_list)
		do
			result[v.row][v.column] = Const.Types.Wild
		end
	end,

	GetGongFuCount = function(data)
		local gongfu_count = 0
		for i = 1, 4 do
			if data[i][3] == Const.Types.GongFu then
				gongfu_count = gongfu_count + 1
			end
		end
		return gongfu_count
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
		local BruceLeePayrateConfig = CommonCal.Calculate.get_config(player, "BruceLeePayrateConfig")
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
				local config = BruceLeePayrateConfig[item.item_id]
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
