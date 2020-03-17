module("SlotsCashSpinCal", package.seeall)
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
		HundredDollars = 1,
		FiftyDollars = 2,
		TwentyDollars = 3,
		TenDollars = 4,
		FiveDollars = 5,
		TwoDollars = 6,
		OneDollars = 7,
		Bonus = 8,
		Wild = 9,
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
		local CashSpinPayrateConfig = CommonCal.Calculate.get_config(player, "CashSpinPayrateConfig")
		local has_normal_prize = item_id and continue_count and (continue_count >= 3)
		local has_wild_prize = wild_count and (wild_count >= 3)
		if has_wild_prize and has_normal_prize then
			local normal_payrate = CashSpinPayrateConfig[item_id].payrate[continue_count - 2]
			local wild_payrate = CashSpinPayrateConfig[Const.Types.Wild].payrate[wild_count - 2]
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
		for row = 1, 3 do
			tran_result[row] = {}
			for col = 1, 5 do
				tran_result[row][col] = result[col][row]
			end
		end
		return tran_result
	end,

	ReplaceWild = function(result, item_type)
		for i = 1, 5 do
			for j = 1, 3 do
				if (result[j][i] == item_type)
				then
					result[j][i] = Const.Types.Wild
				end
			end
		end
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

	GetMaxBetAmount = function(player)
		local CashSpinBetAmountConfig = CommonCal.Calculate.get_config(player, "CashSpinBetAmountConfig")
        local old_req_level = 0
        for k, v in ipairs(CashSpinBetAmountConfig)
        do
            if (player.character.level >= old_req_level and player.character.level < v.required_level)
            then
                return CashSpinBetAmountConfig[k - 1].single_amount
            end
            old_req_level = v.required_level
		end
		
		local max_index = #CashSpinBetAmountConfig
		if (player.character.level >= CashSpinBetAmountConfig[max_index].required_level)
		then
			return CashSpinBetAmountConfig[max_index].single_amount
		end
        return 0
    end,

	GenCashSpinColumn = function(player, config, column)
		local player_id = player.id
		local sequence = config[column].sequence_array
		local sequence_len = #sequence
		local index = math.random_ext(player, 1, sequence_len)

		if (GlobalSlotsTest[player_id] ~= nil)
		then
			sequence, sequence_len, index = CommonCal.Calculate.GetSequence(player_id, column)
		end

		local index_1, index_2 = index % sequence_len + 1, (index + 1) % sequence_len + 1

		return {sequence[index], sequence[index_1], sequence[index_2]}
	end,

	GenItemResult = function (player)
		local tran_result = nil
		local respin_items_list = {}

		local config = CommonCal.Calculate.get_config(player, "CashSpinBaseReelConfig")
		local reel_file_name = "CashSpinBaseReelConfig"

		reel_file_name, config = CommonCal.Calculate.get_new_hand_config(player, nil, reel_file_name, config, "CashSpin")


		local result = {{}, {}, {}, {}, {}}
		local wild_columns = {1, 2, 3, 4, 5}
		for _, v in ipairs(wild_columns) do
			local localResult = Calculate.GenCashSpinColumn(player, config, v)
		
			result[v] = localResult
		end

		tran_result = Calculate.TransResult(result)

		---------------------test begin--------------------------------
		--if (loop_num == 0 or loop_num == 3 or loop_num == 6 or loop_num == 9)
		--then
		--	tran_result = {{1, 1, 2, 8, 4}, {3, 5, 1, 1, 2}, {5, 2, 5, 2, 7}}
		--elseif (loop_num == 1 or loop_num == 4 or loop_num == 7 or loop_num == 10)
		--then
		--	tran_result = {{1, 1, 1, 8, 5}, {3, 5, 1, 1, 6}, {5, 2, 5, 2, 7}}
		--elseif (loop_num == 2 or loop_num == 5 or loop_num == 8 or loop_num == 11)
		--then
		--	tran_result = {{1, 1, 1, 8, 7}, {3, 5, 1, 1, 4}, {5, 2, 1, 2, 7}}
		--end
		---------------------test end----------------------------------
		--[[
		if (#freeze_list > 0)
		then
			for k, v in pairs(freeze_list)
			do
				tran_result[v.row][v.column] = Const.Types.Wild
			end
		end
		--]]
		return tran_result, reel_file_name
	end,
	
	GenWildResult = function(result, freeze_list)
		for k, v in pairs(freeze_list)
		do
			result[v.row][v.column] = Const.Types.Wild
		end
	end,

	GetBonusCount = function(data)
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
	
	GenFreezeListInfo = function(freeze_list, prize_lines, item)
		--[[
		for k, v in ipairs(freeze_list)
		do
			if (v.count == 4)
			then
				v.delete = 1
			end
		end
		--]]
		--LOG(RUN, INFO).Format("[SlotsCashSpin][GenFreezeListInfo] freeze_list:%s", Table2Str(freeze_list))	
		--LOG(RUN, INFO).Format("[SlotsCashSpin][GenFreezeListInfo] prize_lines:%s", Table2Str(prize_lines))	
		--处理存在的元素
		for k, v in ipairs(freeze_list)
		do
			local is_exist = 0
			local i = 1
			while i <= #prize_lines do
				local item = prize_lines[i]
				if (v.row == item.row)
				then
					is_exist = 1
					table.remove(prize_lines, i)
				else
					i = i + 1
				end
			end
			if (is_exist == 1)
			then
				if (v.count ~= 4)
				then
					v.count = v.count + 1
					v.delete = 0
				end
			end
		end
		--LOG(RUN, INFO).Format("[SlotsCashSpin][GenFreezeListInfo]22 freeze_list:%s", Table2Str(freeze_list))	
		--LOG(RUN, INFO).Format("[SlotsCashSpin][GenFreezeListInfo]22 prize_lines:%s", Table2Str(prize_lines))	
		--处理新添加的元素
		for key, item in ipairs(prize_lines)
		do
			local freeze_item = {}
			freeze_item.row = item.row
			freeze_item.column = 3
			freeze_item.item_id = item.item_id
			freeze_item.count = 1
			freeze_item.delete = 0

			local is_exist = 0
			for k, v in ipairs(freeze_list)
			do
				if (v.row == freeze_item.row)
				then
					is_exist = 1
				end
			end
	
			if (is_exist == 0)
			then
				table.insert(freeze_list, freeze_item)
			end
		end
	end,
    
-- --generate总的中奖信息
	GenPrizeInfo = function(player, result, freeze_list)
		local CashSpinPayrateConfig = CommonCal.Calculate.get_config(player, "CashSpinPayrateConfig")
		local prize_info = {}
		local total_payrate = 0
		local old_freeze_list = table.DeepCopy(freeze_list)
		local prize_lines = {}
		for line_index, v in ipairs(Const.Lines) do
			local line_data = {}
			for i = 1, 5 do
				--v[i]是行,i是列
				table.insert(line_data, result[v[i]][i])
			end

			local one_line_prize = Calculate.GenOneLinePrize(player, line_data)

			for _, item in ipairs(one_line_prize) do
				local config = CashSpinPayrateConfig[item.item_id]
				if (config ~= nil)
				then
					local payrate = config.payrate[item.continue_count - 2]
					if (payrate > 0)
					then

						local times = 1
						for k, freeze_item in pairs(old_freeze_list)
						do
							if (freeze_item.row == v[3])
							then
								times = freeze_item.count
								break
							end
						end

						if (times == 4)
						then
							times = 5
						end

						item.payrate = payrate
						item.line_index = line_index
						table.insert(prize_info, item)
						total_payrate = total_payrate + item.payrate * times

						local item = {row = v[3], item_id = item.item_id}
						table.insert(prize_lines, item)
						
					end
				end
			end
		end

		Calculate.GenFreezeListInfo(freeze_list, prize_lines, item)
		return prize_info, total_payrate
	end,
}
