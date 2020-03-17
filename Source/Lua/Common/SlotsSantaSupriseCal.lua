module("SlotsSantaSupriseCal", package.seeall)
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
		SanaGirl = 1,
		Deer = 2,
		SmallBell  = 3,
		Gingerbread  = 4,
		RedSox = 5,
		A = 6,
		K = 7,
		Q = 8,
		J = 9,
		Scatter = 10,
		Wild = 11,
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

	GenSticklyNormalContinueCount = function(reel_data)
		local item_continue_count = {}
		local item_id = reel_data[1]
		if (item_id ~= Const.Types.Scatter and item_id ~= Const.Types.Wild)
		then
			item_continue_count[item_id] = 1
		else
			item_id = 0
		end
		
		if (item_id == reel_data[2])
		then
			item_continue_count[item_id] = item_continue_count[item_id] + 1
			
			if (item_id == reel_data[3])
			then
				item_continue_count[item_id] = item_continue_count[item_id] + 1
			else
				item_id = reel_data[3]
				if (item_id ~= Const.Types.Scatter and item_id ~= Const.Types.Wild)
				then
					item_continue_count[item_id] = 1
				else
					item_id = 0
				end
			end
		else
			item_id = reel_data[2]
			if (item_id ~= Const.Types.Scatter and item_id ~= Const.Types.Wild)
			then
				item_continue_count[item_id] = 1
			else
				item_id = 0
			end
			
			if (item_id == reel_data[3])
			then
				item_continue_count[item_id] = item_continue_count[item_id] + 1
			else
				item_id = reel_data[3]
				if (item_id ~= Const.Types.Scatter and item_id ~= Const.Types.Wild)
				then
					item_continue_count[item_id] = 1
				else
					item_id = 0
				end
			end
		end

		return item_continue_count
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

		local SantaSuprisePayrateConfig = CommonCal.Calculate.get_config(player, "SantaSuprisePayrateConfig")

		local has_normal_prize = item_id and continue_count and (continue_count >= 3)
		local has_wild_prize = wild_count and (wild_count >= 3)
		if has_wild_prize and has_normal_prize then
			local normal_payrate = SantaSuprisePayrateConfig[item_id].payrate[continue_count - 2]
			local wild_payrate = SantaSuprisePayrateConfig[Const.Types.Wild].payrate[wild_count - 2]
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

	GetMaxBetAmount = function(player)
		local SantaSupriseBetAmountConfig = CommonCal.Calculate.get_config(player, "SantaSupriseBetAmountConfig")
        local old_req_level = 0
        for k, v in ipairs(SantaSupriseBetAmountConfig)
        do
            if (player.character.level >= old_req_level and player.character.level < v.required_level)
            then
                return SantaSupriseBetAmountConfig[k - 1].single_amount
            end
            old_req_level = v.required_level
		end
		
		local max_index = #SantaSupriseBetAmountConfig
		if (player.character.level >= SantaSupriseBetAmountConfig[max_index].required_level)
		then
			return SantaSupriseBetAmountConfig[max_index].single_amount
		end
        return 0
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

	GenSantaSupriseColumn = function(player, config, column)
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

	Gen1Column = function(config, oldIndex)
		local index = oldIndex - 1

		local sequence = config[1].sequence_array
		local sequence_len = #sequence
		if (index <= 0)
		then
			index = sequence_len
		end
		--local index_1, index_2, index_3, index_4 = index % sequence_len + 1, (index + 1) % sequence_len + 1, (index + 2) % sequence_len + 1, (index + 3) % sequence_len + 1
		--LOG(RUN, INFO).Format("[Slotspirate][Gen1Column] oldIndex is: %s, value1 is: %s, value2 is: %s, value3 is:%s, value4 is:%s", oldIndex)
		local index_1, index_2, index_3, index_4 = index , index % sequence_len + 1, (index + 1) % sequence_len + 1, (index + 2) % sequence_len + 1
		--LOG(RUN, INFO).Format("[Slotspirate][Gen1Column] oldIndex is: %s, index1 is: %s, index2 is: %s, index3 is:%s, index4 is:%s", oldIndex, index_1, index_2, index_3, index_4)
		return {sequence[index_1], sequence[index_2], sequence[index_3], sequence[index_4]}, index_1
	end,

	GenItemResult = function (player, result, free_item_id, wild_pos)
		local tran_result = nil
		
		local reel_file_name = "SantaSupriseBaseReelConfig"

		if (player.character.level <= tonumber(ConstValue[8].value))
		then		
			reel_file_name = "SantaSupriseNewHand1BaseReelConfig"
		elseif (player.character.level <= tonumber(ConstValue[9].value))
		then
			reel_file_name = "SantaSupriseNewHand2BaseReelConfig"
		elseif (player.character.level <= tonumber(ConstValue[10].value))
		then
			reel_file_name = "SantaSupriseNewHand3BaseReelConfig"
		end

        if (free_item_id and wild_pos)
		then
			local index = math.floor((wild_pos - 1) / 3) + 1 --列
			if (index == 2)
			then
				reel_file_name = "SantaSupriseNewHand1Feature2ReelConfig"
				if (player.character.level <= tonumber(ConstValue[8].value))
				then		
					reel_file_name = "SantaSupriseNewHand2Feature2ReelConfig"
				elseif (player.character.level <= tonumber(ConstValue[9].value))
				then
					reel_file_name = "SantaSupriseNewHand2BaseReelConfig"
				elseif (player.character.level <= tonumber(ConstValue[10].value))
				then
					reel_file_name = "SantaSupriseNewHand3Feature2ReelConfig"
				end
			elseif (index == 3)
			then
				reel_file_name = "SantaSupriseFeature3ReelConfig"
				if (player.character.level <= tonumber(ConstValue[8].value))
				then		
					reel_file_name = "SantaSupriseNewHand1Feature3ReelConfig"
				elseif (player.character.level <= tonumber(ConstValue[9].value))
				then
					reel_file_name = "SantaSupriseNewHand2Feature3ReelConfig"
				elseif (player.character.level <= tonumber(ConstValue[10].value))
				then
					reel_file_name = "SantaSupriseNewHand3Feature3ReelConfig"
				end
			elseif (index == 4)
			then
				reel_file_name = "SantaSupriseFeature4ReelConfig"

				if (player.character.level <= tonumber(ConstValue[8].value))
				then		
					reel_file_name = "SantaSupriseNewHand1Feature4ReelConfig"
				elseif (player.character.level <= tonumber(ConstValue[9].value))
				then
					reel_file_name = "SantaSupriseNewHand2Feature4ReelConfig"
				elseif (player.character.level <= tonumber(ConstValue[10].value))
				then
					reel_file_name = "SantaSupriseNewHand3Feature4ReelConfig"
				end
			elseif (index == 5)
			then
				reel_file_name = "SantaSupriseFeature5ReelConfig"
				if (player.character.level <= tonumber(ConstValue[8].value))
				then		
					reel_file_name = "SantaSupriseNewHand1Feature5ReelConfig"
				elseif (player.character.level <= tonumber(ConstValue[9].value))
				then
					reel_file_name = "SantaSupriseNewHand2Feature5ReelConfig"
				elseif (player.character.level <= tonumber(ConstValue[10].value))
				then
					reel_file_name = "SantaSupriseNewHand3Feature5ReelConfig"
				end	
			end
		end
		
		local config = CommonCal.Calculate.get_config(player, reel_file_name)

		local wild_columns = {1, 2, 3, 4, 5}
		for _,v in ipairs(wild_columns) do
			local localResult
			
			localResult = Calculate.GenSantaSupriseColumn(player, config, v)
			
			result[v] = localResult
		end
		
		tran_result = Calculate.TransResult(result)
		
		return tran_result, reel_file_name
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

	GenGiftSpin = function(player, data)
		local SantaSuprisePayrateConfig = CommonCal.Calculate.get_config(player, "SantaSuprisePayrateConfig")
		local item_info = {} 
		--计算出每个牌的连续个数
		for i = 1, 5 do
			local reel_data = {}
			for j = 1, 3 do
				local item_id = data[j][i]
				table.insert(reel_data, item_id)
			end
			local item_continue_count = Calculate.GenSticklyNormalContinueCount(reel_data)
			table.insert(item_info, item_continue_count)
		end

		--计算出最高个数
		local maxNum = 0
		for k, v in pairs(item_info) do
			for subK, subV in pairs(v) do
				local item_id = subK
				local item_num = subV
				if (maxNum < item_num)
				then
					maxNum = item_num
				end
			end
		end
		if (maxNum > 1)
		then
			local max_item_info = {}
			local sel_item_info = {}
			--筛选出最高个数的几个牌
			for k, v in pairs(item_info) do
				for subK, subV in pairs(v) do
					local item_id = subK
					local item_num = subV
					if (maxNum == item_num)
					then
						table.insert(max_item_info, item_id)
					end
				end
			end
			--在最高个数的牌中筛选出最高赔率
			local maxPayrate = 0
			for k, v in pairs(max_item_info) do
				local config = SantaSuprisePayrateConfig[v]
				local payrate = config.payrate[3]
				if (maxPayrate < payrate)
				then
					maxPayrate = payrate
				end
			end
			--筛选出最高赔率的牌
			for k, v in pairs(max_item_info) do
				local config = SantaSuprisePayrateConfig[v]
				local payrate = config.payrate[3]
				if (maxPayrate == payrate)
				then
					table.insert(sel_item_info, v)
				end
			end

			local rand_index = math.random_ext(player, #sel_item_info)
			return sel_item_info[rand_index]
		else --if (maxNum <= 0)
			local max_item_info = {}
			local sel_item_info = {}

			--计算出每个牌的个数
			local item_num_list = {}
			for i = 1, 5 do
				for j = 1, 3 do
					local item_id = data[j][i]
					if (item_id ~= Const.Types.Scatter and item_id ~= Const.Types.Wild)
					then
						if (item_num_list[item_id])
						then
							item_num_list[item_id] = item_num_list[item_id] + 1
						else
							item_num_list[item_id] = 1
						end
					end
				end
			end

			--计算出最高个数
			maxNum = 0
			for k, v in pairs(item_num_list) do
				local item_id = k
				local item_num = v
				if (maxNum < item_num)
				then
					maxNum = item_num
				end
			end

			--筛选出最高个数的几个牌
			for k, v in pairs(item_num_list) do
				local item_id = k
				local item_num = v
				if (maxNum == item_num)
				then
					table.insert(max_item_info, item_id)
				end
			end

			--在最高个数的牌中筛选出最高赔率
			local maxPayrate = 0
			for k, v in pairs(max_item_info) do
				local config = SantaSuprisePayrateConfig[v]
				local payrate = config.payrate[3]
				if (maxPayrate < payrate)
				then
					maxPayrate = payrate
				end
			end
			--筛选出最高赔率的牌
			for k, v in pairs(max_item_info) do
				local config = SantaSuprisePayrateConfig[v]
				local payrate = config.payrate[3]
				if (maxPayrate == payrate)
				then
					table.insert(sel_item_info, v)
				end
			end
			local rand_index = math.random_ext(player, #sel_item_info)
			return sel_item_info[rand_index]
		end
	
        return 0
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

-- --generate总的中奖信息
	GenPrizeInfo = function(player, result, wild_pos)

		local SantaSuprisePayrateConfig = CommonCal.Calculate.get_config(player, "SantaSuprisePayrateConfig")

		local column = 0
		local row = 0
		if (wild_pos > 0)
		then
			column = math.floor((wild_pos - 1) / 3) + 1 --列
			
			row = wild_pos - (column - 1) * 3 --行
		end

		--print("GenPrizeInfo column is:", column, " row is:", row)
		local prize_info = {}
		local total_payrate = 0
		for line_index, v in ipairs(Const.Lines) do
			local line_data = {}
			for i = 1, 5 do
				--v[i]是行,i是列
				if (v[i] == row and i == column)
				then
					table.insert(line_data, Const.Types.Wild)
				else
					table.insert(line_data, result[v[i]][i])
				end
			end
			local one_line_prize = Calculate.GenOneLinePrize(player, line_data)
			
			for _, item in ipairs(one_line_prize) do
				
				local config = SantaSuprisePayrateConfig[item.item_id]
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
