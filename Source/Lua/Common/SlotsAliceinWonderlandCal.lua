module("SlotsAliceinWonderlandCal", package.seeall)
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
		rabbit = 1,
		cat = 2,
		cup  = 3,
		watch = 4,
		A = 5,
		K = 6,
		Q = 7,
		J = 8,
		Scatter = 9,
		Jackpot = 10,
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


	GenWildReplaceValue = function( line_data, wild_pos, winAmount)
        if wild_pos == 1 then
			for i = 2, 5, 1 do
				if (winAmount > 0)
				then
					if line_data[i] == Const.Types.Jackpot then return end
				end
                if line_data[i] ~= Const.Types.Wild then
                    return  line_data[i]
                end
            end
        elseif wild_pos == 5 then
			for i = 4, 1, -1 do
				if (winAmount > 0)
				then
					if line_data[i] == Const.Types.Jackpot then return end
				end
                if line_data[i] ~= Const.Types.Wild then
                    return  line_data[i]
                end
            end
        else
            local left_value
			for i = wild_pos-1, 1, -1 do
				if (winAmount > 0)
				then
					if line_data[i] == Const.Types.Jackpot then return end
				end
                if line_data[i] ~= Const.Types.Wild then
                    left_value = line_data[i]
                    break
                end
            end
            local right_value
			for i = wild_pos + 1, 5, 1 do
				if (winAmount > 0)
				then
					if line_data[i] == Const.Types.Jackpot then break end
				end
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
		local config = CommonCal.Calculate.get_config(player, "AliceinWonderlandPayrateConfig")
		local has_normal_prize = item_id and continue_count and (continue_count >= 3)
		local has_wild_prize = wild_count and (wild_count >= 3)
		if has_wild_prize and has_normal_prize then
			local normal_payrate = config[item_id].payrate[continue_count - 2]
			local wild_payrate = config[Const.Types.Wild].payrate[wild_count - 2]
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

	GenAliceinWonderlandColumn = function(player, config, column)
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

--在原始序列加入wild,extra_wild
    GenResultWithWild = function(result, extra_wild)
        local result_with_wild = table.copy(result)
        
        for column = 1, 5 do
            if result_with_wild[1][column] == Const.Types.Wild or result_with_wild[2][column] == Const.Types.Wild or result_with_wild[3][column] == Const.Types.Wild then
                result_with_wild[1][column] = Const.Types.Wild
                result_with_wild[2][column] = Const.Types.Wild
				result_with_wild[3][column] = Const.Types.Wild
			end
        end
        
        return result_with_wild
    end,


	GetMaxBetAmount = function(player)
		local config = CommonCal.Calculate.get_config(player, "AliceinWonderlandBetAmountConfig")
        local old_req_level = 0
        for k, v in ipairs(config)
        do
            if (player.character.level >= old_req_level and player.character.level < v.required_level)
            then
                return config[k - 1].single_amount
            end
            old_req_level = v.required_level
		end
		
		local max_index = #config
		if (player.character.level >= config[max_index].required_level)
		then
			return config[max_index].single_amount
		end
        return 0
    end,

	GenItemResult = function (player, result, wild, is_free_spin, winAmount, free_item_id, feature_file, player_extern)
		local init_result = {}
		local col_start_index = {}
		local reel_file_name = "AliceinWonderlandBaseReelConfig"
		if (feature_file ~= nil and feature_file ~= "")
		then
			reel_file_name = feature_file
		end

		if (is_free_spin)
		then
			reel_file_name = "AliceinWonderlandFeatureReelConfig"
			if (feature_file ~= nil and feature_file ~= "")
			then
				reel_file_name = feature_file
			end
		else
			reel_file_name = "AliceinWonderlandBaseReelConfig"
			if (feature_file ~= nil and feature_file ~= "")
			then
				reel_file_name = feature_file
			end
		end

		local total_spin_num = 0
		if (player_extern ~= nil) then
			local json_str = player_extern.save_data

	        if (json_str["spin_num"] == nil) then
	            json_str["spin_num"] = 0
			end
			total_spin_num = json_str["spin_num"] + 1
		end

		reel_file_name, config = CommonCal.Calculate.get_new_hand_config(player, free_item_id, reel_file_name, config, "AliceinWonderland", feature_file)

		if (player_extern ~= nil and total_spin_num < 3) then
			reel_file_name = "AliceinWonderlandNewHand"..total_spin_num.."BaseReelConfig"
		end
		
		local config = CommonCal.Calculate.get_config(player, reel_file_name)

		
		local tran_result = nil
		
		local extra_wild  = nil

		
		--先随第1至5列是否出现wild
		local hasWild = 0
		local wild_columns = {1, 2, 3, 4, 5}
		for _,v in ipairs(wild_columns) do
			if (wild[v][1] ~= Const.Types.Wild)
			then
				local localResult = Calculate.GenAliceinWonderlandColumn(player, config, v)

				local is_wild  = (localResult[1] == Const.Types.Wild  or localResult[2] == Const.Types.Wild or localResult[3] == Const.Types.Wild)
				if (winAmount > 0)--保证1,2,3,4,5列上不会出现WILD图标
				then
					if (is_wild)
					then
						for i = 1, 3, 1
						do
							local local_weight_tab = {[1] = 0.1, [2] = 0.1, [3] = 0.1, [4] = 0.1, [5] = 0.1, [6] = 0.1, [7] = 0.1, [8] = 0.1, [9] = 0.1, [10] = 0.1}
							local local_index = math.rand_weight(player, local_weight_tab)
							localResult[i] = local_index
						end
					end 
				end
				if (is_wild)
				then
					wild[v][1] = Const.Types.Wild
					wild[v][2] = Const.Types.Wild
					wild[v][3] = Const.Types.Wild
					hasWild = 1
				end
				result[v] = localResult
			end
		end

		tran_result = Calculate.TransResult(result)
		
		extra_wild  = Calculate.TransResult(wild)

		return tran_result, extra_wild, hasWild, reel_file_name
	end,

	GetBonusCount = function (data)
		local bonus_count = 0

        for i = 1, 3 do
            for j = 1, 5 do
                if data[i][j] == Const.Types.Bonus then
                    bonus_count = bonus_count + 1
                end
            end
		end
		
        return bonus_count	
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
			return 10, Const.Types.Scatter
		end
        return 0, 0
    end,

	TransExtraWildPosToList = function(origin_result)
		local list = {}

		local pos = 0
		for row = 1, 5 do
			for col = 1, 3 do
				pos = pos + 1
				if (origin_result[col][row] == Const.Types.Wild)
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
	GenPrizeInfo = function(player, result, winAmount, origin_result, is_free_spin)
		local prize_info = {}
		local total_payrate = 0

		local config = CommonCal.Calculate.get_config(player, "AliceinWonderlandPayrateConfig")
		for line_index, v in ipairs(Const.Lines) do
			local line_data = {}
			for i = 1, 5 do
				--v[i]是行,i是列

				table.insert(line_data, result[v[i]][i])
			end
			local one_line_prize = Calculate.GenOneLinePrize(player, line_data, winAmount)
			
			for _, item in ipairs(one_line_prize) do
				if (config[item.item_id] ~= nil)
				then
					local payrate = config[item.item_id].payrate[item.continue_count - 2]
					if (payrate > 0)
					then
						if (is_free_spin) then
							local wild_count = 0
							for index = 1, item.continue_count do
								if (result[v[index]][index] == Const.Types.Wild) then
									wild_count = wild_count + 1
								end
							end
							if (wild_count > 0) then
								payrate = payrate * 2
							end
						end

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

}
