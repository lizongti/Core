module("SlotsPirateCal", package.seeall)
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
		PirateMan = 1,
		PirateGirl = 2,
		Parrot  = 3,
		Anchor = 4,
		GoldCoin = 5,
		SilverCoin = 6,
		CopperCoin = 7,
		IronCoin = 8,
		Bonus = 9,
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
		local PiratePayrateConfig = CommonCal.Calculate.get_config(player, "PiratePayrateConfig")
		local has_normal_prize = item_id and continue_count and (continue_count >= 3)
		local has_wild_prize = wild_count and (wild_count >= 3)
		if has_wild_prize and has_normal_prize then
			local normal_payrate = PiratePayrateConfig[item_id].payrate[continue_count - 2]
			local wild_payrate = PiratePayrateConfig[Const.Types.Wild].payrate[wild_count - 2]
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

	GenPirateColumn = function(player, config, column)
		local player_id = player.id
		
		local sequence = config[column].sequence_array
		local sequence_len = #sequence
		local index = math.random_ext(player, 1, sequence_len)

		if (GlobalSlotsTest[player_id] ~= nil)
		then
			sequence, sequence_len, index = CommonCal.Calculate.GetSequence(player_id, column)
		end

		local index_1, index_2, index_3 = index % sequence_len + 1, (index + 1) % sequence_len + 1, (index + 2) % sequence_len + 1
		-----------------------------test------------------------------------------------
		--return {10, sequence[index_1], sequence[index_2], sequence[index_3]}, index
		--LOG(RUN, INFO).Format("[Slotspirate][Gen1Column] Index is: %s, index1 is: %s, index2 is: %s, index3 is:%s", index, index_1, index_2, index_3)
		--[[
		if (column == 2 or column == 4)
		then
			return {10, sequence[index_1], 10, sequence[index_3]}, index
		elseif (column == 1)
		then
			return {sequence[index], Const.Types.Bonus, sequence[index_2], sequence[index_3]}, index
		else
			return {sequence[index], Const.Types.Bonus, Const.Types.Bonus, sequence[index_3]}, index
		end	    
		--]]
		

		--return {Const.Types.Bonus, sequence[index_1], sequence[index_2], sequence[index_3]}, index
		-----------------------------test------------------------------------------------
		return {sequence[index], sequence[index_1], sequence[index_2], sequence[index_3]}, index
		
	end,

	GetMaxBetAmount = function(player)
		local PirateBetAmountConfig = CommonCal.Calculate.get_config(player, "PirateBetAmountConfig")
        local old_req_level = 0
        for k, v in ipairs(PirateBetAmountConfig)
        do
            if (player.character.level >= old_req_level and player.character.level < v.required_level)
            then
                return PirateBetAmountConfig[k - 1].single_amount
            end
            old_req_level = v.required_level
		end
		
		local max_index = #PirateBetAmountConfig
		if (player.character.level >= PirateBetAmountConfig[max_index].required_level)
		then
			return PirateBetAmountConfig[max_index].single_amount
		end
		
        return 0
    end,

	Gen1Column = function(player_id, config, oldIndex)
		local index = oldIndex - 1

		local sequence = config[1].sequence_array
		local sequence_len = #sequence
		if (index <= 0)
		then
			index = sequence_len
		end

		if (GlobalSlotsTest[player_id] ~= nil)
		then
			sequence, sequence_len, index = CommonCal.Calculate.GetSequence(player_id, 1)
		end
		--local index_1, index_2, index_3, index_4 = index % sequence_len + 1, (index + 1) % sequence_len + 1, (index + 2) % sequence_len + 1, (index + 3) % sequence_len + 1
		--LOG(RUN, INFO).Format("[Slotspirate][Gen1Column] oldIndex is: %s, value1 is: %s, value2 is: %s, value3 is:%s, value4 is:%s", oldIndex)
		local index_1, index_2, index_3, index_4 = index , index % sequence_len + 1, (index + 1) % sequence_len + 1, (index + 2) % sequence_len + 1
		--LOG(RUN, INFO).Format("[Slotspirate][Gen1Column] oldIndex is: %s, index1 is: %s, index2 is: %s, index3 is:%s, index4 is:%s", oldIndex, index_1, index_2, index_3, index_4)
		return {sequence[index_1], sequence[index_2], sequence[index_3], sequence[index_4]}, index_1
	end,

	GenItemResult = function (player, result, wild, free_spin_num, loop_num, oldIndex)
		local tran_result = nil
		
		
		local reel_file_name = "PirateBaseReelConfig"

		if (player.character.level <= tonumber(ConstValue[8].value))
		then		
			reel_file_name = "PirateNewHand1BaseReelConfig"
		elseif (player.character.level <= tonumber(ConstValue[9].value))
		then
			reel_file_name = "PirateNewHand2BaseReelConfig"
		elseif (player.character.level <= tonumber(ConstValue[10].value))
		then
			reel_file_name = "PirateNewHand3BaseReelConfig"
		end

        if (free_spin_num == 8)
        then
			reel_file_name = "Pirate8FreeReelConfig"

			if (player.character.level <= tonumber(ConstValue[8].value))
			then		
				reel_file_name = "PirateNewHand18FreeReelConfig"
			elseif (player.character.level <= tonumber(ConstValue[9].value))
			then
				reel_file_name = "PirateNewHand28FreeReelConfig"
			elseif (player.character.level <= tonumber(ConstValue[10].value))
			then
				reel_file_name = "PirateNewHand38FreeReelConfig"
			end

        elseif (free_spin_num == 10)
        then
			reel_file_name = "Pirate10FreeReelConfig"

			if (player.character.level <= tonumber(ConstValue[8].value))
			then		
				reel_file_name = "PirateNewHand110FreeReelConfig"
			elseif (player.character.level <= tonumber(ConstValue[9].value))
			then
				reel_file_name = "PirateNewHand210FreeReelConfig"
			elseif (player.character.level <= tonumber(ConstValue[10].value))
			then
				reel_file_name = "PirateNewHand310FreeReelConfig"
			end
        elseif (free_spin_num == 12)
        then
			reel_file_name = "Pirate12FreeReelConfig"
			if (player.character.level <= tonumber(ConstValue[8].value))
			then		
				reel_file_name = "PirateNewHand112FreeReelConfig"
			elseif (player.character.level <= tonumber(ConstValue[9].value))
			then
				reel_file_name = "PirateNewHand212FreeReelConfig"
			elseif (player.character.level <= tonumber(ConstValue[10].value))
			then
				reel_file_name = "PirateNewHand312FreeReelConfig"
			end
        end

		local config = CommonCal.Calculate.get_config(player, reel_file_name)
		local firstColumnIndex = 0
		
		if (loop_num == 0)
		then
			local wild_columns = {1, 2, 3, 4, 5}
			for _,v in ipairs(wild_columns) do
				local localResult
				
				if (v == 1)
				then
					localResult, firstColumnIndex = Calculate.GenPirateColumn(player, config, v)
				else
					localResult = Calculate.GenPirateColumn(player, config, v)
				end
				
				result[v] = localResult
			end
		else
			local localResult = Calculate.Gen1Column(player, config, oldIndex)
			
			result[1] = localResult
		end
		
		
		tran_result = Calculate.TransResult(result)
		
		return tran_result, firstColumnIndex, reel_file_name
	end,
    
    IsSlots = function(data)
        local bonus_count = 0
        
        for i = 1, 4 do
            for j = 1, 5 do
                if data[i][j] == Const.Types.Bonus then
                    bonus_count = bonus_count + 1
                end
            end
        end
        
        if (bonus_count >= 3)
        then
            return 1
        end
        return 0
    end,

	Has2And4Wild = function(data)
        local has2Wild = 0
        local has4Wild = 0
	
		for j = 1, 4 do
			if data[j][2] == Const.Types.Wild then
				has2Wild = 1
				break
			end
		end
 
		for j = 1, 4 do
			if data[j][4] == Const.Types.Wild then
				has4Wild = 1
				break
			end
		end
        
        if (has2Wild == 1 and has4Wild == 1)
        then
            return 1
        end
        return 0
	end,
	
    GenFreeSpinCount = function(data)
        local bonus_count = 0

        for i = 1, 3 do
            for j = 1, 5 do
                if data[i][j] == Const.Types.Bonus then
                    bonus_count = bonus_count + 1
                end
            end
		end
		
		if (bonus_count >= 3)
		then
			return 10, Const.Types.Bonus
		end
        return 0, 0
    end,

-- --generate总的中奖信息
	GenPrizeInfo = function(player, result)
		local prize_info = {}
		local total_payrate = 0
		local PiratePayrateConfig = CommonCal.Calculate.get_config(player, "PiratePayrateConfig")
		for line_index, v in ipairs(Const.Lines) do
			local line_data = {}
			for i = 1, 5 do
				--v[i]是行,i是列
				table.insert(line_data, result[v[i]][i])
			end
			local one_line_prize = Calculate.GenOneLinePrize(player, line_data)
			
			for _, item in ipairs(one_line_prize) do
				
				local config = PiratePayrateConfig[item.item_id]
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
