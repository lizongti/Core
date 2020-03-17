module("SlotsWildCircusCal", package.seeall)
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
		Singham = 9,
		BrownBear = 8,
		Monkey  = 7,
		MagicCane  = 6,
		A = 5,
		K = 4,
		Q = 3,
		J = 2,
		Ten = 1,
		Wild = 10,
		MulWild = 11,
		Scatter = 13,
		FreeSpinScatter = 14,
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
			if line_data[i] == Const.Types.Wild or line_data[i] == Const.Types.MulWild then
				table.insert(pos, i)
			end
		end
		return pos
	end,


	GenWildReplaceValue = function( line_data, wild_pos)
        if wild_pos == 1 then
			for i = 2, 5, 1 do
                if line_data[i] ~= Const.Types.Wild and line_data[i] ~= Const.Types.MulWild then
                    return line_data[i]
                end
            end
        elseif wild_pos == 5 then
			for i = 4, 1, -1 do
                if line_data[i] ~= Const.Types.Wild and line_data[i] ~= Const.Types.MulWild then
                    return line_data[i]
                end
            end
        else
            local left_value
			for i = wild_pos-1, 1, -1 do
                if line_data[i] ~= Const.Types.Wild and line_data[i] ~= Const.Types.MulWild then
                    left_value = line_data[i]
                    break
                end
            end
            local right_value
			for i = wild_pos + 1, 5, 1 do
                if line_data[i] ~= Const.Types.Wild and line_data[i] ~= Const.Types.MulWild then
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
		local item_id = 0
		local continue_count = 0

		if not start or not stop or not step
		then
			return item_id, continue_count
		end


		for i = start, stop, step do
			if line_data[i] == Const.Types.Scatter or line_data[i] == Const.Types.FreeSpinScatter then
				break
			end
			if item_id ~= 0 then
				if line_data[i] ~= item_id and line_data[i] ~= Const.Types.Wild and line_data[i] ~= Const.Types.MulWild then
					continue_count = math.abs(start - i)
					break
				else
					continue_count = math.abs(start - i) + 1
				end
			else
				if line_data[i] ~= Const.Types.Wild and line_data[i] ~= Const.Types.MulWild then
					item_id = line_data[i]
				end
			end
		end

		return item_id, continue_count
	end,

	GetMaxBetAmount = function(player)
		local WildCircusBetAmountConfig = CommonCal.Calculate.get_config(player, "WildCircusBetAmountConfig")
        local old_req_level = 0
        for k, v in ipairs(WildCircusBetAmountConfig)
        do
            if (player.character.level >= old_req_level and player.character.level < v.required_level)
            then
                return WildCircusBetAmountConfig[k - 1].single_amount
            end
            old_req_level = v.required_level
		end

		local max_index = #WildCircusBetAmountConfig
		if (player.character.level >= WildCircusBetAmountConfig[max_index].required_level)
		then
			return WildCircusBetAmountConfig[max_index].single_amount
		end
        return 0
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
            if line_data[i] == Const.Types.Wild or line_data[i] == Const.Types.MulWild then
                wild_count = wild_count + 1
            else
                break
            end
        end
        return wild_count
	end,

--比较普通中奖和wild中奖，以赔率大的作为一条中奖项
	CompareNormalAndWild = function (player, item_id, continue_count, wild_count, prize_list, direction )
		local WildCircusPayrateConfig = CommonCal.Calculate.get_config(player, "WildCircusPayrateConfig")
		local has_normal_prize = item_id and continue_count and (continue_count >= 3)
		local has_wild_prize = wild_count and (wild_count >= 3)

		if has_wild_prize and has_normal_prize then
			local normal_payrate = WildCircusPayrateConfig[item_id].payrate[continue_count - 2]
			local wild_payrate = WildCircusPayrateConfig[Const.Types.Wild].payrate[wild_count - 2]

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

	GenWildCircusColumn = function(player, config, column)
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

	GetMultiply = function(item_id)
		if (item_id == Const.Types.TyrannosaurusRex)
		then
			return 2
		end

		if (item_id == Const.Types.Triceratops)
		then
			return 3
		end

		if (item_id == Const.Types.Stegosaurus)
		then
			return 4
		end

		if (item_id == Const.Types.Brontosaurus)
		then
			return 5
		end

		if (item_id == Const.Types.Velociraptor)
		then
			return 6
		end

		return 0
	end,

	GenItemResult = function (player, free_spin_scatter_count)
		local tran_result = nil
		local result = {}
		local free_spin_type = 0

		local reel_file_name = "WildCircusBaseReelConfig"

		if (player.character.level <= tonumber(ConstValue[8].value))
		then
			reel_file_name = "WildCircusNewHand1BaseReelConfig"
		elseif (player.character.level <= tonumber(ConstValue[9].value))
		then
			reel_file_name = "WildCircusNewHand2BaseReelConfig"
		elseif (player.character.level <= tonumber(ConstValue[10].value))
		then
			reel_file_name = "WildCircusNewHand3BaseReelConfig"
		end

		if (free_spin_scatter_count)
		then
			if (free_spin_scatter_count <= 3)
			then
				reel_file_name = "WildCircusFeature1ReelConfig"

				if (player.character.level <= tonumber(ConstValue[8].value))
				then
					reel_file_name = "WildCircusNewHand1Feature1ReelConfig"
				elseif (player.character.level <= tonumber(ConstValue[9].value))
				then
					reel_file_name = "WildCircusNewHand2Feature1ReelConfig"
				elseif (player.character.level <= tonumber(ConstValue[10].value))
				then
					reel_file_name = "WildCircusNewHand3Feature1ReelConfig"
				end

			elseif (free_spin_scatter_count <= 8)
			then
				reel_file_name = "WildCircusFeature4ReelConfig"
				if (player.character.level <= tonumber(ConstValue[8].value))
				then
					reel_file_name = "WildCircusNewHand1Feature4ReelConfig"
				elseif (player.character.level <= tonumber(ConstValue[9].value))
				then
					reel_file_name = "WildCircusNewHand2Feature4ReelConfig"
				elseif (player.character.level <= tonumber(ConstValue[10].value))
				then
					reel_file_name = "WildCircusNewHand3Feature4ReelConfig"
				end
			elseif (free_spin_scatter_count <= 13)
			then
				reel_file_name = "WildCircusFeature9ReelConfig"

				if (player.character.level <= tonumber(ConstValue[8].value))
				then
					reel_file_name = "WildCircusNewHand1Feature9ReelConfig"
				elseif (player.character.level <= tonumber(ConstValue[9].value))
				then
					reel_file_name = "WildCircusNewHand2Feature9ReelConfig"
				elseif (player.character.level <= tonumber(ConstValue[10].value))
				then
					reel_file_name = "WildCircusNewHand3Feature9ReelConfig"
				end
			else
				reel_file_name = "WildCircusFeature14ReelConfig"
				if (player.character.level <= tonumber(ConstValue[8].value))
				then
					reel_file_name = "WildCircusNewHand1Feature14ReelConfig"
				elseif (player.character.level <= tonumber(ConstValue[9].value))
				then
					reel_file_name = "WildCircusNewHand2Feature14ReelConfig"
				elseif (player.character.level <= tonumber(ConstValue[10].value))
				then
					reel_file_name = "WildCircusNewHand3Feature14ReelConfig"
				end
			end
		end
		local config = CommonCal.Calculate.get_config(player, reel_file_name)

		local wild_columns = {1, 2, 3, 4, 5}
		for _,v in ipairs(wild_columns) do
			local localResult

			localResult = Calculate.GenWildCircusColumn(player, config, v)

			result[v] = localResult
		end

		tran_result = Calculate.TransResult(result)


		return tran_result, reel_file_name
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

	GenFreeSpinScatterCount = function(data)
        local scatter_count = 0

        for i = 1, 3 do
            for j = 1, 5 do
                if data[i][j] == Const.Types.FreeSpinScatter then
                    scatter_count = scatter_count + 1
                end
            end
		end

		return scatter_count
	end,


	-- --generate总的中奖信息
	GenPrizeInfo = function(player, result, player_id)

		local WildCircusPayrateConfig = CommonCal.Calculate.get_config(player, "WildCircusPayrateConfig")

		local prize_info = {}

		local test_prize_info = {}

		local TotalMulWildNum = 0

		local total_payrate = 0
		for line_index, v in ipairs(Const.Lines) do
			local line_data = {}
			for i = 1, 5 do
				--v[i]是行,i是列
				table.insert(line_data, result[v[i]][i])
			end
			local one_line_prize = Calculate.GenOneLinePrize(player, line_data)

			for _, item in ipairs(one_line_prize) do
				local MulWildNum = 0
				for index = 1, item.continue_count do
					local row = v[index]
					local column = index
					if (result[row][column] == Const.Types.MulWild)
					then
						MulWildNum = MulWildNum + 1
					end
				end

				if (MulWildNum > 3)
				then
					MulWildNum = 3
				end

				local config = WildCircusPayrateConfig[item.item_id]
				if (config ~= nil)
				then
					local payrate = config.payrate[item.continue_count - 2]
					if (payrate > 0)
					then
						item.payrate = payrate  * (MulWildNum + 1)
						item.line_index = line_index
						table.insert(prize_info, item)
						total_payrate = total_payrate + item.payrate

						if (Base.Enviroment.pro_spec_t ~= "online" and GlobalSlotsTest[player_id] ~= nil)
						then
							local test_item = table.copy(item)
							test_item.MultiNum = (MulWildNum + 1)
							table.insert(test_prize_info, test_item)
						end
					end
				end

				TotalMulWildNum = TotalMulWildNum + MulWildNum
			end
		end

		return prize_info, total_payrate, TotalMulWildNum, test_prize_info


	end,
}
