module("SlotsChineseNewYearCal", package.seeall)
require "Util/TableExt"
require "Common/CommonCal"

Const = {
	
	Lines = {
		[1] = {1,1,1,1,1},
		[2] = {1,1,1,1,2},
		[3] = {1,1,1,1,3},

		[4] = {1,1,1,2,1},
		[5] = {1,1,1,2,2},
		[6] = {1,1,1,2,3},

		[7] = {1,1,1,3,1},
		[8] = {1,1,1,3,2},
		[9] = {1,1,1,3,3},

		[10] = {1,1,2,1,1},
		[11] = {1,1,2,1,2},
		[12] = {1,1,2,1,3},

		[13] = {1,1,2,2,1},
		[14] = {1,1,2,2,2},
		[15] = {1,1,2,2,3},

		[16] = {1,1,2,3,1},
		[17] = {1,1,2,3,2},
		[18] = {1,1,2,3,3},

		[19] = {1,1,3,1,1},
		[20] = {1,1,3,1,2},
		[21] = {1,1,3,1,3},

		[22] = {1,1,3,2,1},
		[23] = {1,1,3,2,2},
		[24] = {1,1,3,2,3},

		[25] = {1,1,3,3,1},
		[26] = {1,1,3,3,2},
		[27] = {1,1,3,3,3},

		[28] = {1,2,1,1,1},
		[29] = {1,2,1,1,2},
		[30] = {1,2,1,1,3},

		[31] = {1,2,1,2,1},
		[32] = {1,2,1,2,2},
		[33] = {1,2,1,2,3},

		[34] = {1,2,1,3,1},
		[35] = {1,2,1,3,2},
		[36] = {1,2,1,3,3},

		[37] = {1,2,2,1,1},
		[38] = {1,2,2,1,2},
		[39] = {1,2,2,1,3},

		[40] = {1,2,2,2,1},
		[41] = {1,2,2,2,2},
		[42] = {1,2,2,2,3},

		[43] = {1,2,2,3,1},
		[44] = {1,2,2,3,2},
		[45] = {1,2,2,3,3},

		[46] = {1,2,3,1,1},
		[47] = {1,2,3,1,2},
		[48] = {1,2,3,1,3},

		[49] = {1,2,3,2,1},
		[50] = {1,2,3,2,2},
		[51] = {1,2,3,2,3},

		[52] = {1,2,3,3,1},
		[53] = {1,2,3,3,2},
		[54] = {1,2,3,3,3},

		[55] = {1,3,1,1,1},
		[56] = {1,3,1,1,2},
		[57] = {1,3,1,1,3},

		[58] = {1,3,1,2,1},
		[59] = {1,3,1,2,2},
		[60] = {1,3,1,2,3},

		[61] = {1,3,1,3,1},
		[62] = {1,3,1,3,2},
		[63] = {1,3,1,3,3},

		[64] = {1,3,2,1,1},
		[65] = {1,3,2,1,2},
		[66] = {1,3,2,1,3},

		[67] = {1,3,2,2,1},
		[68] = {1,3,2,2,2},
		[69] = {1,3,2,2,3},

		[70] = {1,3,2,3,1},
		[71] = {1,3,2,3,2},
		[72] = {1,3,2,3,3},

		[73] = {1,3,3,1,1},
		[74] = {1,3,3,1,2},
		[75] = {1,3,3,1,3},

		[76] = {1,3,3,2,1},
		[77] = {1,3,3,2,2},
		[78] = {1,3,3,2,3},

		[79] = {1,3,3,3,1},
		[80] = {1,3,3,3,2},
		[81] = {1,3,3,3,3},

		[82] = {2,1,1,1,1},
		[83] = {2,1,1,1,2},
		[84] = {2,1,1,1,3},

		[85] = {2,1,1,2,1},
		[86] = {2,1,1,2,2},
		[87] = {2,1,1,2,3},

		[88] = {2,1,1,3,1},
		[89] = {2,1,1,3,2},
		[90] = {2,1,1,3,3},

		[91] = {2,1,2,1,1},
		[92] = {2,1,2,1,2},
		[93] = {2,1,2,1,3},

		[94] = {2,1,2,2,1},
		[95] = {2,1,2,2,2},
		[96] = {2,1,2,2,3},

		[97] = {2,1,2,3,1},
		[98] = {2,1,2,3,2},
		[99] = {2,1,2,3,3},

		[100] = {2,1,3,1,1},
		[101] = {2,1,3,1,2},
		[102] = {2,1,3,1,3},

		[103] = {2,1,3,2,1},
		[104] = {2,1,3,2,2},
		[105] = {2,1,3,2,3},

		[106] = {2,1,3,3,1},
		[107] = {2,1,3,3,2},
		[108] = {2,1,3,3,3},

		[109] = {2,2,1,1,1},
		[110] = {2,2,1,1,2},
		[111] = {2,2,1,1,3},

		[112] = {2,2,1,2,1},
		[113] = {2,2,1,2,2},
		[114] = {2,2,1,2,3},

		[115] = {2,2,1,3,1},
		[116] = {2,2,1,3,2},
		[117] = {2,2,1,3,3},

		[118] = {2,2,2,1,1},
		[119] = {2,2,2,1,2},
		[120] = {2,2,2,1,3},

		[121] = {2,2,2,2,1},
		[122] = {2,2,2,2,2},
		[123] = {2,2,2,2,3},

		[124] = {2,2,2,3,1},
		[125] = {2,2,2,3,2},
		[126] = {2,2,2,3,3},

		[127] = {2,2,3,1,1},
		[128] = {2,2,3,1,2},
		[129] = {2,2,3,1,3},

		[130] = {2,2,3,2,1},
		[131] = {2,2,3,2,2},
		[132] = {2,2,3,2,3},

		[133] = {2,2,3,3,1},
		[134] = {2,2,3,3,2},
		[135] = {2,2,3,3,3},

		[136] = {2,3,1,1,1},
		[137] = {2,3,1,1,2},
		[138] = {2,3,1,1,3},

		[139] = {2,3,1,2,1},
		[140] = {2,3,1,2,2},
		[141] = {2,3,1,2,3},

		[142] = {2,3,1,3,1},
		[143] = {2,3,1,3,2},
		[144] = {2,3,1,3,3},

		[145] = {2,3,2,1,1},
		[146] = {2,3,2,1,2},
		[147] = {2,3,2,1,3},

		[148] = {2,3,2,2,1},
		[149] = {2,3,2,2,2},
		[150] = {2,3,2,2,3},

		[151] = {2,3,2,3,1},
		[152] = {2,3,2,3,2},
		[153] = {2,3,2,3,3},

		[154] = {2,3,3,1,1},
		[155] = {2,3,3,1,2},
		[156] = {2,3,3,1,3},

		[157] = {2,3,3,2,1},
		[158] = {2,3,3,2,2},
		[159] = {2,3,3,2,3},

		[160] = {2,3,3,3,1},
		[161] = {2,3,3,3,2},
		[162] = {2,3,3,3,3},

		[163] = {3,1,1,1,1},
		[164] = {3,1,1,1,2},
		[165] = {3,1,1,1,3},

		[166] = {3,1,1,2,1},
		[167] = {3,1,1,2,2},
		[168] = {3,1,1,2,3},

		[169] = {3,1,1,3,1},
		[170] = {3,1,1,3,2},
		[171] = {3,1,1,3,3},

		[172] = {3,1,2,1,1},
		[173] = {3,1,2,1,2},
		[174] = {3,1,2,1,3},

		[175] = {3,1,2,2,1},
		[176] = {3,1,2,2,2},
		[177] = {3,1,2,2,3},

		[178] = {3,1,2,3,1},
		[179] = {3,1,2,3,2},
		[180] = {3,1,2,3,3},

		[181] = {3,1,3,1,1},
		[182] = {3,1,3,1,2},
		[183] = {3,1,3,1,3},

		[184] = {3,1,3,2,1},
		[185] = {3,1,3,2,2},
		[186] = {3,1,3,2,3},

		[187] = {3,1,3,3,1},
		[188] = {3,1,3,3,2},
		[189] = {3,1,3,3,3},

		[190] = {3,2,1,1,1},
		[191] = {3,2,1,1,2},
		[192] = {3,2,1,1,3},

		[193] = {3,2,1,2,1},
		[194] = {3,2,1,2,2},
		[195] = {3,2,1,2,3},

		[196] = {3,2,1,3,1},
		[197] = {3,2,1,3,2},
		[198] = {3,2,1,3,3},

		[199] = {3,2,2,1,1},
		[200] = {3,2,2,1,2},
		[201] = {3,2,2,1,3},

		[202] = {3,2,2,2,1},
		[203] = {3,2,2,2,2},
		[204] = {3,2,2,2,3},

		[205] = {3,2,2,3,1},
		[206] = {3,2,2,3,2},
		[207] = {3,2,2,3,3},

		[208] = {3,2,3,1,1},
		[209] = {3,2,3,1,2},
		[210] = {3,2,3,1,3},

		[211] = {3,2,3,2,1},
		[212] = {3,2,3,2,2},
		[213] = {3,2,3,2,3},

		[214] = {3,2,3,3,1},
		[215] = {3,2,3,3,2},
		[216] = {3,2,3,3,3},

		[217] = {3,3,1,1,1},
		[218] = {3,3,1,1,2},
		[219] = {3,3,1,1,3},

		[220] = {3,3,1,2,1},
		[221] = {3,3,1,2,2},
		[222] = {3,3,1,2,3},

		[223] = {3,3,1,3,1},
		[224] = {3,3,1,3,2},
		[225] = {3,3,1,3,3},

		[226] = {3,3,2,1,1},
		[227] = {3,3,2,1,2},
		[228] = {3,3,2,1,3},

		[229] = {3,3,2,2,1},
		[230] = {3,3,2,2,2},
		[231] = {3,3,2,2,3},

		[232] = {3,3,2,3,1},
		[233] = {3,3,2,3,2},
		[234] = {3,3,2,3,3},

		[235] = {3,3,3,1,1},
		[236] = {3,3,3,1,2},
		[237] = {3,3,3,1,3},

		[238] = {3,3,3,2,1},
		[239] = {3,3,3,2,2},
		[240] = {3,3,3,2,3},

		[241] = {3,3,3,3,1},
		[242] = {3,3,3,3,2},
		[243] = {3,3,3,3,3},
	},
	
	Types = {
		PIC1 = 1,--舞狮
		PIC2 = 2,--金鲤鱼
		PIC3  = 3,--灯笼
		PIC4  = 4,--红包
		PIC5 = 5,--元宝（Bonus）
		A = 6,
		K = 7,
		Q = 8,
		J = 9,
		TEN = 10,
		NINE = 11,
		Wild = 12,
		Scatter = 13,
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
	GenScatterContinueCount = function(line_data, line_index, prize_list)
		local local_item_id = nil
		local local_continue_count = 0
		local from_index = 1
		local to_index = 5
		for i = 1, 5
		do
			if line_data[i] == Const.Types.Scatter then
				local_continue_count = local_continue_count + 1
				to_index = i
				if (local_item_id == nil)
				then
					local_item_id = line_data[i]
					from_index = i
				end
			end
			if (local_item_id == Const.Types.Scatter and line_data[i] ~= Const.Types.Scatter)
			then
				break
			end
		end

		if (local_continue_count >= 3  and from_index == 1)
		then
			if (Calculate.IsExistInScatterPrizeList(prize_list, line_index, local_item_id, from_index, to_index) == 0)
			then
				table.insert(prize_list, {
					line_index = line_index,
					line_data = line_data,
					item_id = local_item_id,
					continue_count = local_continue_count,
					from_index = from_index,
					to_index = to_index,
				})
			end
		end
	end,

	GenNormalContinueCount = function(line_data, direction, line_index, prize_list)
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
	

	IsExistInPrizeList = function(prize_list, line_index, item_id, continue_count)
		local i = 1
		local is_exist = 0
		while (i <= #prize_list) do
			local item = prize_list[i]
			if (item.item_id == item_id)
			then
				if (item.continue_count > continue_count)
				then
					i = i + 1
					is_exist = 1
				elseif (item.continue_count < continue_count)
				then
					table.remove(prize_list, i)
				else
					i = i + 1
					local is_diff = 0
					for pos = 1, item.continue_count do
						if (Const.Lines[line_index][pos] ~= Const.Lines[item.line_index][pos])
						then
							is_diff = 1
							break
						end
					end
					if (is_diff == 0)
					then
						is_exist = 1
					end
				end
			else
				i = i + 1
			end
		end
		return is_exist
	end,

	IsExistInScatterPrizeList = function(prize_list, line_index, item_id, from_index, to_index)
		local i = 1
		local is_exist = 0
		while (i <= #prize_list) do
			local item = prize_list[i]
			if (item.item_id == item_id)
			then
				if (item.from_index <= from_index and item.to_index > to_index)
				then
					i = i + 1
					is_exist = 1
				elseif (item.from_index < from_index and item.to_index >= to_index)
				then
					i = i + 1
					is_exist = 1
				elseif (item.from_index < from_index and item.to_index > to_index)
				then
					i = i + 1
					is_exist = 1
				elseif (item.from_index > from_index and item.to_index < to_index)
				then
					table.remove(prize_list, i)
				elseif (item.from_index >= from_index and item.to_index < to_index)
				then
					table.remove(prize_list, i)
				elseif (item.from_index > from_index and item.to_index <= to_index)
				then
					table.remove(prize_list, i)
				else
					i = i + 1
					local is_diff = 0
					for pos = from_index, to_index do
						if (Const.Lines[line_index][pos] ~= Const.Lines[item.line_index][pos])
						then
							is_diff = 1
							break
						end
					end
					if (is_diff == 0)
					then
						is_exist = 1
					end
				end
			else
				i = i + 1
			end
		end
		return is_exist
	end,

--比较普通中奖和wild中奖，以赔率大的作为一条中奖项
	CompareNormalAndWild = function (player, line_index, line_data, item_id, continue_count, wild_count, prize_list, direction )
		local ChineseNewYearPayrateConfig = CommonCal.Calculate.get_config(player, "ChineseNewYearPayrateConfig")
		local has_normal_prize = item_id and continue_count and (continue_count >= 3)
		local has_wild_prize = wild_count and (wild_count >= 3)
		if has_wild_prize and has_normal_prize then
			local normal_payrate = ChineseNewYearPayrateConfig[item_id].payrate[continue_count - 2]
			local wild_payrate = ChineseNewYearPayrateConfig[Const.Types.Wild].payrate[wild_count - 2]
			if normal_payrate >= wild_payrate then
				if (Calculate.IsExistInPrizeList(prize_list, line_index, item_id, continue_count) == 0)
				then
					table.insert(prize_list, {
						line_index = line_index,
						line_data = line_data,
						item_id = item_id,
						continue_count = continue_count,
						from_index = (direction == Const.PrizeDirection.LEFT) and 1 or (5 - continue_count + 1),
						to_index = (direction == Const.PrizeDirection.LEFT) and continue_count or 5,
					})
				end
			else
				if (Calculate.IsExistInPrizeList(prize_list, line_index, Const.Types.Wild, continue_count) == 0)
				then
					table.insert(prize_list, {
						line_index = line_index,
						line_data = line_data,
						item_id = Const.Types.Wild,
						continue_count = wild_count,
						from_index = (direction == Const.PrizeDirection.LEFT) and 1 or (5 - wild_count + 1),
						to_index = (direction == Const.PrizeDirection.LEFT) and wild_count or 5,
					})
				end
			end
		elseif has_normal_prize then
			if (Calculate.IsExistInPrizeList(prize_list, line_index, item_id, continue_count) == 0)
			then
				table.insert(prize_list, {
					line_index = line_index,
					line_data = line_data,
					item_id = item_id,
					continue_count = continue_count,
					from_index = (direction == Const.PrizeDirection.LEFT) and 1 or (5 - continue_count + 1),
					to_index = (direction == Const.PrizeDirection.LEFT) and continue_count or 5,
				})
			end
		elseif has_wild_prize then
			if (Calculate.IsExistInPrizeList(prize_list, line_index, Const.Types.Wild, continue_count) == 0)
			then
				table.insert(prize_list, {
					line_index = line_index,
					line_data = line_data,
					item_id = Const.Types.Wild,
					continue_count = wild_count,
					from_index = (direction == Const.PrizeDirection.LEFT) and 1 or (5 - wild_count + 1),
					to_index = (direction == Const.PrizeDirection.LEFT) and wild_count or 5,
				})
			end
		end
	end,

	GenOneLinePrize = function(player, line_index, line_data, prize_list)

		local wild_pos_list = Util.GenWildPos(line_data)
        local wild_pos_len = #wild_pos_list
		local rep_line_data = table.copy(line_data)
		Calculate.GenScatterContinueCount(rep_line_data, line_index, prize_list)
		if wild_pos_len > 0 then
            for i = 1, wild_pos_len do
                local rep_value = Util.GenWildReplaceValue(line_data, wild_pos_list[i])
                if rep_value then
                    rep_line_data[wild_pos_list[i]] = rep_value
                end
            end
        end

		local left_item_id, left_continue_count = Calculate.GenNormalContinueCount(rep_line_data, Const.PrizeDirection.LEFT, line_index, prize_list)
		local left_wild_count = Calculate.GenWildContinueCount(line_data, Const.PrizeDirection.LEFT)
		if (left_continue_count >=3 or left_wild_count >= 3)
		then
			Calculate.CompareNormalAndWild(player, line_index, line_data, left_item_id, left_continue_count, left_wild_count, prize_list, Const.PrizeDirection.LEFT)
		end
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

	-- --将3*5的矩阵转换成一维数组,以列优先
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
		local old_req_level = 0
		local ChineseNewYearBetAmountConfig = CommonCal.Calculate.get_config(player, "ChineseNewYearBetAmountConfig")
        for k, v in ipairs(ChineseNewYearBetAmountConfig)
        do
            if (player.character.level >= old_req_level and player.character.level < v.required_level)
            then
                return ChineseNewYearBetAmountConfig[k - 1].single_amount
            end
            old_req_level = v.required_level
		end
		
		local max_index = #ChineseNewYearBetAmountConfig
		if (player.character.level >= ChineseNewYearBetAmountConfig[max_index].required_level)
		then
			return ChineseNewYearBetAmountConfig[max_index].single_amount
		end
        return 0
    end,

	GenChineseNewYearColumn = function(player, config, column)
		local player_id = player.id
		local sequence = config[column].sequence_array
		local sequence_len = #sequence
		local index = math.random_ext(player, 1, sequence_len)

		if (GlobalSlotsTest[player_id] ~= nil)
		then
			sequence, sequence_len, index = CommonCal.Calculate.GetSequence(player_id, column)
		end
		
		local index_1, index_2 = index % sequence_len + 1, (index + 1) % sequence_len + 1

		--return {sequence[index], Const.Types.Scatter, sequence[index_2]}, index
		return {sequence[index], sequence[index_1], sequence[index_2]}, index
	end,


	GenItemResult = function (player, is_bonus_bet, free_spin_type, feature_file)
		local tran_result = nil
		local result = {}
		local config = nil
		local reel_file_name = nil
		if (is_bonus_bet == 0)
		then
			reel_file_name = "ChineseNewYear243ReelConfig"

			if (player.character.level <= tonumber(ConstValue[8].value))
			then		
				reel_file_name = "ChineseNewYearNewHand1243ReelConfig"
			elseif (player.character.level <= tonumber(ConstValue[9].value))
			then
				reel_file_name = "ChineseNewYearNewHand2243ReelConfig"
			elseif (player.character.level <= tonumber(ConstValue[10].value))
			then
				reel_file_name = "ChineseNewYearNewHand3243ReelConfig"
			end
		else
			reel_file_name = "ChineseNewYear243BonusReelConfig"

			if (player.character.level <= tonumber(ConstValue[8].value))
			then		
				reel_file_name = "ChineseNewYearNewHand1243BonusReelConfig"
			elseif (player.character.level <= tonumber(ConstValue[9].value))
			then
				reel_file_name = "ChineseNewYearNewHand2243BonusReelConfig"
			elseif (player.character.level <= tonumber(ConstValue[10].value))
			then
				reel_file_name = "ChineseNewYearNewHand3243BonusReelConfig"
			end
		end
		if (feature_file ~= nil and feature_file ~= "")
		then
			reel_file_name = feature_file
		end
		config = CommonCal.Calculate.get_config(player, reel_file_name)

		local wild_columns = {1, 2, 3, 4, 5}
		for _,v in ipairs(wild_columns) do
			local localResult
			
			localResult = Calculate.GenChineseNewYearColumn(player, config, v)
			
			result[v] = localResult
		end
		
		--result = {{11, 7, 13}, {4, 7, 13}, {8, 10, 12}, {1, 11, 5}, {4, 10, 6}}
		tran_result = Calculate.TransResult(result)


		return tran_result, reel_file_name
	end,

	IsBonusWin = function(data)
		local is_bonus_win = 1
		local bonus_columns = {1, 5}
		for _, v in ipairs(bonus_columns)
		do
			local bonus_count = 0
			for j = 1, 3 
			do
				if data[j][v] == Const.Types.PIC5 then
					bonus_count = bonus_count + 1
					break
                end
			end
			if (bonus_count == 0)
			then
				is_bonus_win = 0
			end
		end
		return is_bonus_win
		--return 0
	end,

	
    GenScatterCount = function(data)
        local total_scatter_count = 0

		for i = 1, 5 
		do
			local scatter_count = 0
			for j = 1, 3 
			do
				if data[j][i] == Const.Types.Scatter then
                    scatter_count = scatter_count + 1
                end
			end

			if (scatter_count == 0)
			then
				if (total_scatter_count < 3)
				then
					break
				end
			else
				total_scatter_count = total_scatter_count + 1
			end
		end

        return total_scatter_count
	end,
	

	-- --generate总的中奖信息
	GenPrizeInfo = function(player, result, free_spin_type)
		local prize_info = {}
		local total_payrate = 0

		local free_spin_config = nil
		local ChineseNewYearFreeSpinTypeConfig = CommonCal.Calculate.get_config(player, "ChineseNewYearFreeSpinTypeConfig")
		if (free_spin_type and free_spin_type > 0)
		then
			free_spin_config = ChineseNewYearFreeSpinTypeConfig[free_spin_type]
		end

		local prize_list = {}

		for line_index, v in ipairs(Const.Lines) do
			local line_data = {}
			for i = 1, 5 do
				--v[i]是行,i是列
				table.insert(line_data, result[v[i]][i])
			end
			Calculate.GenOneLinePrize(player, line_index, line_data, prize_list)
		end

		local ChineseNewYearPayrateConfig = CommonCal.Calculate.get_config(player, "ChineseNewYearPayrateConfig")
		for _, item in ipairs(prize_list) do
			local config = ChineseNewYearPayrateConfig[item.item_id]
			if (config ~= nil)
			then
				local payrate = config.payrate[item.continue_count - 2]
				if (payrate == nil)
				then
					LOG(RUN, INFO).Format("[SlotsChineseNewYear][GenPrizeInfo] item id is: %s, continue_count is: %s", item.id, item.continue_count)
				end
				if (payrate > 0)
				then
					local prize_item = {
						line_index = item.line_index,	
						item_id = item.item_id,
						continue_count = item.continue_count,
						from_index = item.from_index,
						to_index = item.to_index,
					}
					
					prize_item.payrate = payrate
					table.insert(prize_info, prize_item)

					local wild_count = 0
					for k, v in pairs(item.line_data)
					do
						if (v == Const.Types.Wild)
						then
							wild_count = wild_count + 1
						end
					end
					if (free_spin_config and wild_count > 0)
					then
						local weighting = free_spin_config.weighting[wild_count]
						total_payrate = total_payrate + prize_item.payrate * weighting
					else
						total_payrate = total_payrate + prize_item.payrate
					end
				end				
			end
		end
		
		return prize_info, total_payrate
	end,
}
