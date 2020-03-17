module("SlotsWorldCupCal", package.seeall)
require "Util/TableExt"
require "Common/CommonCal"

Const = {
	LeftLines1 = {
		[1] = {1,1,1},
		[2] = {1,1,2},
		[3] = {2,2,2},
		[4] = {2,2,3},
		[5] = {3,3,3},
		[6] = {3,3,4},
		[7] = {2,1,1},
		[8] = {3,2,2},
		[9] = {1,2,2},
		[10] = {2,3,3},
		[11] = {1,2,3},
		[12] = {2,3,4},
		[13] = {2,1,2},
		[14] = {3,2,3},
		[15] = {1,2,1},
		[16] = {2,3,2},
		[17] = {2,1,3},
		[18] = {3,2,4},
		[19] = {3,1,1},
		[20] = {1,3,4},
	},

	RightLines1 = {
		[1] = {1,1,1},
		[2] = {2,1,1},
		[3] = {2,2,2},
		[4] = {3,2,2},
		[5] = {3,3,3},
		[6] = {4,3,3},
		[7] = {1,1,2},
		[8] = {2,2,3},
		[9] = {2,2,1},
		[10] = {3,3,2},
		[11] = {3,2,1},
		[12] = {4,3,2},
		[13] = {2,1,2},
		[14] = {3,2,3},
		[15] = {1,2,1},
		[16] = {2,3,2},
		[17] = {3,1,2},
		[18] = {4,2,3},
		[19] = {1,1,3},
		[20] = {4,3,1},
	},

	LeftLines2 = {
		[1] = {1,1,1},
		[2] = {1,2,1},
		[3] = {2,2,2},
		[4] = {2,3,2},
		[5] = {3,3,3},
		[6] = {3,4,3},
		[7] = {2,1,1},
		[8] = {2,4,3},
		[9] = {2,2,1},
		[10] = {3,3,2},
		[11] = {1,2,3},
		[12] = {2,3,3},
		[13] = {1,1,2},
		[14] = {2,2,3},
		[15] = {3,1,1},
		[16] = {3,2,2},
		[17] = {2,1,2},
		[18] = {2,4,2},
		[19] = {1,2,3},
		[20] = {3,3,1},
	},

	RightLines2 = {
		[1] = {1,1,1},
		[2] = {1,2,1},
		[3] = {2,2,2},
		[4] = {2,3,2},
		[5] = {3,3,3},
		[6] = {3,4,3},
		[7] = {1,1,2},
		[8] = {3,4,2},
		[9] = {1,2,2},
		[10] = {2,3,3},
		[11] = {2,2,1},
		[12] = {3,3,2},
		[13] = {2,1,1},
		[14] = {3,2,2},
		[15] = {1,1,3},
		[16] = {2,2,3},
		[17] = {2,1,2},
		[18] = {2,4,2},
		[19] = {3,2,1},
		[20] = {1,3,3},
	},

	LeftLines3 = {
		[1] = {1,1,1},
		[2] = {2,2,1},
		[3] = {2,2,2},
		[4] = {3,3,1},
		[5] = {3,3,2},
		[6] = {4,4,2},
		[7] = {1,2,1},
		[8] = {2,3,2},
		[9] = {3,2,1},
		[10] = {4,3,2},
		[11] = {2,1,1},
		[12] = {3,2,2},
		[13] = {2,3,1},
		[14] = {3,4,2},
		[15] = {1,2,2},
		[16] = {4,3,1},
		[17] = {2,1,2},
		[18] = {3,4,1},
		[19] = {1,1,2},
		[20] = {4,4,1},
	},

	RightLines3 = {
		[1] = {1,1,1},
		[2] = {1,2,2},
		[3] = {2,2,2},
		[4] = {1,3,3},
		[5] = {2,3,3},
		[6] = {2,4,4},
		[7] = {1,2,1},
		[8] = {2,3,2},
		[9] = {1,2,3},
		[10] = {2,3,4},
		[11] = {1,1,2},
		[12] = {2,2,3},
		[13] = {1,3,2},
		[14] = {2,4,3},
		[15] = {2,2,1},
		[16] = {1,3,4},
		[17] = {2,1,2},
		[18] = {1,4,3},
		[19] = {2,1,1},
		[20] = {1,4,4},
	},

	Types = {
		Footballer1 = 1,--球员1
		Footballer2 = 2,--球员2
		PoloShirt  = 3, --球衣
		GymShoes  = 4,--球鞋
		Gloves = 5,--手套
		Black = 6,--黑
		Red = 7,--红
		Plum = 8,--梅
		Square = 9,--方
		Scatter = 10,
		Bonus = 11,
		Wild = 12,
	},

	Countrys = {
		Russia = 1,--俄罗斯
		Germany = 2, --德国
		Brazil = 3, --巴西
		Portuguesa = 4, --葡萄牙
		Argentina = 5, --阿根廷
		Belgium = 6, --比利时
		Poland = 7, --波兰
		France = 8, --法国
		Spain = 9, --西班牙
		Peru = 10, --秘鲁
		Switzerland = 11, --瑞士
		England = 12, --英格兰
		Columbia = 13, --哥伦比亚
		Mexico = 14, --墨西哥
		Uruguay = 15, --乌拉圭
		Croatia = 16, --克罗地亚
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
		local WorldCupPayrateConfig = CommonCal.Calculate.get_config(player, "WorldCupPayrateConfig")

		local has_normal_prize = item_id and continue_count and (continue_count >= 3)
		local has_wild_prize = wild_count and (wild_count >= 3)

		if has_wild_prize and has_normal_prize then
			local normal_payrate = WorldCupPayrateConfig[item_id].payrate[continue_count - 2]
			local wild_payrate = WorldCupPayrateConfig[Const.Types.Wild].payrate[wild_count - 2]
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

	-- --trans 5*4 matrix to 4*5 matrix
	TransResult = function(result)
		local tran_result = {}
		for row = 1, 4 do
			tran_result[row] = {}
			for col = 1, 3 do
				tran_result[row][col] = result[col][row]
			end
		end
		return tran_result
	end,

	GenWildResult = function(result, wild_list)
		for k, v in ipairs(wild_list)
		do
			local row = v.row
			local column = v.column
			result[row][column] = Const.Types.Wild
		end
	end,

	GenWild = function(player, left_result, right_result)
		local left_has_wild = 0
		local left_wild_list = {}
		local right_has_wild = 0
		local right_wild_list = {}
		for i = 1, 3 do--列
			for j = 1, 4 do--行
				if (left_result[j][i] > 0 and left_result[j][i] == Const.Types.Wild)
				then
					left_has_wild = 1
					break
				end
			end
		end

		for i = 1, 3 do--列
			for j = 1, 4 do--行
				if (right_result[j][i] > 0 and right_result[j][i] == Const.Types.Wild)
				then
					right_has_wild = 1
					break
				end
			end
		end

		local config = CommonCal.Calculate.get_config(player, "WorldCupPassFeatureConfig")
		
		if (left_has_wild == 1)
		then
			local local_weight_tab = {}
			for k, v in ipairs(config)
			do
				local_weight_tab[k] = v.ratio
			end
			local local_index = math.rand_weight(player, local_weight_tab)
			local number = config[local_index].pass_num

			local history = {}
			for loop = 1, number, 1
			do
				local has_kick = 0
				for i = 1, 3 do--列
					local is_exit = 0
					for k, v in ipairs(history)
					do
						if (v == i)
						then
							is_exist = 1
							break
						end
					end
					if (is_exist == 0)
					then
						table.insert(history, i)
						local local_weight_tab = {}
						local value_list = {}
						for j = 1, 4 do--行
							if (right_result[j][i] > 0 and right_result[j][i] ~= Const.Types.Wild)
							then
								table.insert(local_weight_tab, 0.1)
								table.insert(value_list, j)
							end
						end
						if (#value_list > 0)
						then
							local local_index = math.rand_weight(player, local_weight_tab)

							local row = value_list[local_index]
							local column = i
							table.insert(right_wild_list, {row = row, column = column})
							has_kick = 1
						end
					end
					if (has_kick == 1)
					then
						break
					end
				end
			end
		end

		if (right_has_wild == 1)
		then
			local local_weight_tab = {}
			for k, v in ipairs(config)
			do
				local_weight_tab[k] = v.ratio
			end
			local local_index = math.rand_weight(player, local_weight_tab)
			local number = config[local_index].pass_num

			local history = {}
			for loop = 1, number, 1
			do
				local has_kick = 0
				for i = 1, 3 do--列
					local is_exit = 0
					for k, v in ipairs(history)
					do
						if (v == i)
						then
							is_exist = 1
							break
						end
					end
					if (is_exist == 0)
					then
						table.insert(history, i)
						local local_weight_tab = {}
						local value_list = {}
						for j = 1, 4 do--行
							if (left_result[j][i] > 0 and left_result[j][i] ~= Const.Types.Wild)
							then
								table.insert(local_weight_tab, 0.1)
								table.insert(value_list, j)
							end
						end
						if (#value_list > 0)
						then
							local local_index = math.rand_weight(player, local_weight_tab)

							local row = value_list[local_index]
							local column = i
							table.insert(left_wild_list, {row = row, column = column})
							has_kick = 1
						end
					end
					if (has_kick == 1)
					then
						break
					end
				end
			end
		end

		return left_wild_list, right_wild_list
	end,

	-- --将矩阵转换成一维数组,以列优先
	TransResultToList = function(result)
		local list = {}

		for i = 1, 3 do--列
			for j = 1, 4 do--行
				if (result[j][i] > 0)
				then
					table.insert(list, result[j][i])
				end
			end
		end
		
		return list
	end,

	GetMaxBetAmount = function(player)
		local WorldCupBetAmountConfig = CommonCal.Calculate.get_config(player, "WorldCupBetAmountConfig")
        local old_req_level = 0
        for k, v in ipairs(WorldCupBetAmountConfig)
        do
            if (player.character.level >= old_req_level and player.character.level < v.required_level)
            then
                return WorldCupBetAmountConfig[k - 1].single_amount
            end
            old_req_level = v.required_level
		end
		
		local max_index = #WorldCupBetAmountConfig
		if (player.character.level >= WorldCupBetAmountConfig[max_index].required_level)
		then
			return WorldCupBetAmountConfig[max_index].single_amount
		end
        return 0
    end,

	GenWorldCupColumn = function(player_id, config, column)

	end,


	UpdateFreeBous = function(backto_jurassic, free_spin_num_array)
		backto_jurassic.free_spin_bouts = 0
		if (free_spin_num_array and #free_spin_num_array > 0)
		then
			for k, v in pairs(free_spin_num_array)
			do
				backto_jurassic.free_spin_bouts = backto_jurassic.free_spin_bouts + v.free_spin_bouts
			end
		end
	end,

	GenItemResult = function (player, is_free_spin, type, left_or_right)
		local tran_result = nil
		local result = {}
		local config = CommonCal.Calculate.get_config(player, "WorldCup334LeftBaseReelConfig")
		local reel_file_name = "WorldCup334LeftBaseReelConfig"
		if (left_or_right == 1)
		then
			if (type == 1)
			then
				config = CommonCal.Calculate.get_config(player, "WorldCup334LeftBaseReelConfig")
				reel_file_name = "WorldCup334LeftBaseReelConfig"
			elseif (type == 2)
			then
				config = CommonCal.Calculate.get_config(player, "WorldCup343LeftBaseReelConfig")
				reel_file_name = "WorldCup343LeftBaseReelConfig"	
			elseif (type == 3)
			then
				config = CommonCal.Calculate.get_config(player, "WorldCup442LeftBaseReelConfig")
				reel_file_name = "WorldCup442LeftBaseReelConfig"			
			end
		else
			if (type == 1)
			then
				config = CommonCal.Calculate.get_config(player, "WorldCup334RightBaseReelConfig")
				reel_file_name = "WorldCup334RightBaseReelConfig"
			elseif (type == 2)
			then
				config = CommonCal.Calculate.get_config(player, "WorldCup343RightBaseReelConfig")
				reel_file_name = "WorldCup343RightBaseReelConfig"	
			elseif (type == 3)
			then
				config = CommonCal.Calculate.get_config(player, "WorldCup442RightBaseReelConfig")
				reel_file_name = "WorldCup442RightBaseReelConfig"			
			end
		end

		if (is_free_spin)
		then
			config = CommonCal.Calculate.get_config(player, "WorldCupLeftFeatureReelConfig")
			reel_file_name = "WorldCupLeftFeatureReelConfig"

		end

		local wild_columns = {1, 2, 3}
		for _, v in ipairs(wild_columns) do
			result[v] = Calculate.GenWorldCupColumn(player.id, config, v)

			if (left_or_right == 1)
			then
				if (type == 1)
				then
					if (v ~= 3)--334
					then
						result[v][4] = 0
					end
				elseif (type == 2)
				then
					if (v ~= 2)--343
					then
						result[v][4] = 0
					end	
				elseif (type == 3)
				then
					if (v == 3)--442
					then
						result[v][3] = 0
						result[v][4] = 0
					end				
				end
			else
				if (type == 1)
				then
					if (v ~= 1)--334
					then
						result[v][4] = 0
					end
				elseif (type == 2)
				then
					if (v ~= 2)--343
					then
						result[v][4] = 0
					end	
				elseif (type == 3)
				then
					if (v == 1)--442
					then
						result[v][2] = 0
						result[v][4] = 0
					end				
				end
			end

		end
		
		tran_result = Calculate.TransResult(result)

		return tran_result, reel_file_name
	end,
	
    GenFreeSpinCount = function(data)
        local scatter_count = 0

        for i = 1, 4 do
            for j = 1, 3 do
                if data[i][j] == Const.Types.Scatter then
                    scatter_count = scatter_count + 1
                end
            end
		end
		
		if (scatter_count >= 3)
		then
			return 4, Const.Types.Scatter
		end
        return 0, 0
	end,
	
	GetScore = function(data)
        local score = 0

        for i = 1, 4 do
            for j = 1, 3 do
                if data[i][j] == Const.Types.Wild then
                    score = score + 1
                end
            end
		end
		
        return score
	end,

	-- --generate总的中奖信息
	GenPrizeInfo = function(player, result)
		local WorldCupPayrateConfig = CommonCal.Calculate.get_config(player, "WorldCupPayrateConfig")
		local prize_info = {}
		local total_payrate = 0
		for line_index, v in ipairs(Const.Lines) do
			local line_data = {}

			for i = 1, 3 do
				--v[i]是行,i是列
				table.insert(line_data, result[v[i]][i])
			end
			local one_line_prize = Calculate.GenOneLinePrize(player, line_data)

			for _, item in ipairs(one_line_prize) do

				local config = WorldCupPayrateConfig[item.item_id]
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
		--LOG(RUN, INFO).Format("[SlotsWorldCup][GenPrizeInfo] total_payrate is: %s", total_payrate)
		return prize_info, total_payrate
	end,
}
