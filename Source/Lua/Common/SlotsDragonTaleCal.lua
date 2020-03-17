module("SlotsDragonTaleCal", package.seeall)
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
		[25] = {2,1,3,1,2}
	},

	Types = {
		Slayer = 1,--火女
		CrystalMaiden = 2,--冰女
		Crown = 3,--王冠
		Spear = 4,--长枪
		Sword = 5,--长剑
		Shield = 6,--盾牌
		DragonEggRed = 7,--龙蛋红
		DragonEggCyan = 8,--龙蛋青
		DragonEggGreen = 9,--龙蛋绿
		DragonEggYellow = 10,--龙蛋黄
		Scatter = 11,--宝箱
		Wild = 12,
	},

	Dragon = {
		IceDragon = 1,
		FireDragon = 2,
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

-------只有第2-4列可能会有wild
    GenWildReplaceValue = function( line_data, wild_pos )
        if wild_pos == 1 then
            for i = 2, 5, 1 do
                if line_data[i] == Const.Types.Scatter then return end
                if line_data[i] ~= Const.Types.Wild then
                    return line_data[i]
                end
            end
        elseif wild_pos == 5 then
            for i = 4, 1, -1 do
                if line_data[i] == Const.Types.Scatter then return end
                if line_data[i] ~= Const.Types.Wild then
                    return line_data[i]
                end
            end
        else
            local left_value
            for i = wild_pos-1, 1, -1 do
                if line_data[i] == Const.Types.Scatter then return end
                if line_data[i] ~= Const.Types.Wild then
                    left_value = line_data[i]
                    break
                end
            end
            local right_value
            for i = wild_pos + 1, 5, 1 do
                if line_data[i] == Const.Types.Scatter then break end
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

    GenWildPos = function(line_data)
        local pos = {}
        for i = 1, 5 do
            if line_data[i] == Const.Types.Wild then
                table.insert(pos, i)
            end
        end
        return pos
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
    
    GenWildContinueCount = function(line_data)
        local wild_count = 0
        for i = 1, 5 do
            if line_data[i] == Const.Types.Wild then
                wild_count = wild_count + 1
            else
                break
            end
        end
        return wild_count
    end,

    GetMaxBetAmount = function(player)
        local DragonTaleBetAmountConfig = CommonCal.Calculate.get_config(player, "DragonTaleBetAmountConfig")
        local old_req_level = 0
        for k, v in ipairs(DragonTaleBetAmountConfig)
        do
            if (player.character.level >= old_req_level and player.character.level < v.required_level)
            then
                return DragonTaleBetAmountConfig[k - 1].single_amount
            end
            old_req_level = v.required_level
        end

        local max_index = #DragonTaleBetAmountConfig
		if (player.character.level >= DragonTaleBetAmountConfig[max_index].required_level)
		then
			return DragonTaleBetAmountConfig[max_index].single_amount
		end

        return 0
    end,

    CompareNormalAndWild = function (player, item_id, continue_count, wild_count, prize_list, direction )
        local DragonTalePayrateConfig = CommonCal.Calculate.get_config(player, "DragonTalePayrateConfig")
		local has_normal_prize = item_id and continue_count and (continue_count >= 3)
		local has_wild_prize = wild_count and (wild_count >= 3)
		if has_wild_prize and has_normal_prize then
            local normal_payrate = 0
            if (DragonTalePayrateConfig[item_id] and DragonTalePayrateConfig[item_id].payrate)
            then
                normal_payrate = DragonTalePayrateConfig[item_id].payrate[continue_count - 2]
            end
            local wild_payrate = 0
            if (DragonTalePayrateConfig[Const.Types.Wild] and DragonTalePayrateConfig[Const.Types.Wild].payrate)
            then
                wild_payrate = DragonTalePayrateConfig[Const.Types.Wild].payrate[wild_count - 2]
            end
            
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
        --LOG(RUN, INFO).Format("[SlotsDragonTale][GenOneLinePrize] prize_list: %s", Table2Str(prize_list))
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

        
		if (left_continue_count >= 3 or left_wild_count == 5)
		then
			Calculate.CompareNormalAndWild(player, left_item_id, left_continue_count, left_wild_count, prize_list, Const.PrizeDirection.LEFT)
		end

		return prize_list
    end,
    
    --GenOneLinePrize = function(line_data)
    --    local prize_list = {}
    --    local wild_count = Calculate.GenWildContinueCount(line_data)
    --    if wild_count >= 5 then
    --        table.insert(prize_list, {
    --            continue_count = wild_count,
    --            item_id = Const.Types.Wild,
    --        })
    --    end

    --    local wild_pos_list = Util.GenWildPos(line_data)
    --    local wild_pos_len = #wild_pos_list
    --    local rep_line_data = table.copy(line_data)
    --    if wild_pos_len > 0 then
    --        for i = 1, wild_pos_len do
    --            local rep_value = Util.GenWildReplaceValue(line_data, wild_pos_list[i])
    --            if rep_value then
    --                rep_line_data[wild_pos_list[i]] = rep_value
    --            end
    --        end
    --    end
    --    LOG(RUN, INFO).Format("[SlotsDragonTale][GenOneLinePrize] rep_line_data: %s", Table2Str(rep_line_data))
    --    local item_id, continue_count = Calculate.GenNormalContinueCount(rep_line_data)
    --    if item_id and continue_count then
    --        LOG(RUN, INFO).Format("[SlotsDragonTale][GenOneLinePrize] wild_count is: %s, item_id is: %s, continue_count is: %s", wild_count, item_id, continue_count)
    --        table.insert(prize_list, {
    --            continue_count = continue_count,
    --            item_id = item_id,
    --        })
    --   end
        
    --    return prize_list
    --end,

    --产生一行(这里的一行已经将wild换成它可以替换的图标了)的中奖结果
    --[[
    GenNormalContinueCount = function(line_data)
        local item_id = line_data[1]
        local continue_count = 1
        for i = 2, 5 do
            if line_data[i] == item_id then
                continue_count = continue_count + 1
            else
                break
            end
        end

        if item_id >= Const.Types.Slayer and item_id <= Const.Types.DragonEggYellow and continue_count >= 3 then
        	return item_id, continue_count
        else
        	return nil, nil
        end
    end,
    --]]

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

    GenFreeSpinCount = function(player, data)
        local scatter_count = 0
        for i = 1, 3 do
            for j = 1, 5 do
                if data[i][j] == Const.Types.Scatter then
                    scatter_count = scatter_count + 1
                end
            end
        end
        local DragonTaleOthersConfig = CommonCal.Calculate.get_config(player, "DragonTaleOthersConfig")
        return (scatter_count >= 3) and DragonTaleOthersConfig[1].free_spin_delta or 0
    end,

--将3*5的矩阵转换成一维数组
    TransResultToList = function(result)
        local list = {}
        for i = 1,5 do
            for j = 1, 3 do
                table.insert(list, result[j][i])
            end
        end
        return list
    end,

    GenPrizeInfo = function(player, result)
		local prize_info = {}
        local total_payrate = 0
        local DragonTalePayrateConfig = CommonCal.Calculate.get_config(player, "DragonTalePayrateConfig")
		for line_index, v in ipairs(Const.Lines) do
			local line_data = {}
			for i = 1, 5 do
				--v[i]是行,i是列
				table.insert(line_data, result[v[i]][i])
            end
            --if (line_index == 2)
            --then
            --    LOG(RUN, INFO).Format("[SlotsDragonTable][GenPrizeInfo] begin line_data %s", Table2Str(line_data))
            --end
            local one_line_prize = Calculate.GenOneLinePrize(player, line_data)
            
            --if (line_index == 2)
           -- then
            --    LOG(RUN, INFO).Format("[SlotsDragonTable][GenPrizeInfo] end line_data %s", Table2Str(line_data))
            --end
			
			for _, item in ipairs(one_line_prize) do
				
				local config = DragonTalePayrateConfig[item.item_id]
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
        --LOG(RUN, INFO).Format("[SlotsDragonTable][GenPrizeInfo] prize_info %s", Table2Str(prize_info))
		return prize_info, total_payrate
    end,

--产生一列,column表示第几列,config是经过了is_free_spin判断了之后的config
    GenColumn = function(player, config, column)
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

    GenItemResult = function (player, is_free_spin, is_final, feature_file)
    	local base_or_feature = is_free_spin and "Feature" or "Base"
        local reel_index = is_final and "2" or "1"

        local reel_file_name = "DragonTale" .. base_or_feature .. "Reel" .. reel_index .. "Config"
        if (not is_final)
        then
            if (feature_file ~= nil and feature_file == "DragonTaleMFReelConfig")
            then
                reel_file_name = feature_file
            end
        else
            if (feature_file ~= nil and feature_file ~= "")
            then
                reel_file_name = feature_file
            end            
        end
        local config = CommonCal.Calculate.get_config(player, reel_file_name)
        if (player.character.level <= tonumber(ConstValue[8].value))
		then		
			reel_file_name = "DragonTaleNewHand1" .. base_or_feature .. "Reel" .. reel_index .. "Config"
		elseif (player.character.level <= tonumber(ConstValue[9].value))
		then
			reel_file_name = "DragonTaleNewHand2" .. base_or_feature .. "Reel" .. reel_index .. "Config"
		elseif (player.character.level <= tonumber(ConstValue[10].value))
		then
			reel_file_name = "DragonTaleNewHand3" .. base_or_feature .. "Reel" .. reel_index .. "Config"
        end

        if (feature_file ~= nil and feature_file ~= "")
        then
            reel_file_name = feature_file
        end
        config = CommonCal.Calculate.get_config(player, reel_file_name)

        local result = {}
    
    	for i = 1, 5 do
            result[i] = Calculate.GenColumn(player, config, i)
        end
        


    	local tran_result = Calculate.TransResult(result)
    	return tran_result, reel_file_name
    end,

--trans 5*3 matrix to 3*5 matrix
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

    GenDragonType = function ( player )
    	local col1_dragon = math.random_ext(player, 1,2)
    	local col5_dragon = math.random_ext(player, 1,2)
    	return {col1_dragon, col5_dragon}
        -- return {2, 2}
    end,

    NeedRespin = function(player)
        if (GlobalSlotsTest[player.id] ~= nil)
        then
            if (GlobalSlotsTest[player.id].flag == 1)
            then
                return 1
            end
        end

        local DragonTaleOthersConfig = CommonCal.Calculate.get_config(player, "DragonTaleOthersConfig")

        local prob = is_free_spin and DragonTaleOthersConfig[1].free_trigger_wild_prob or DragonTaleOthersConfig[1].trigger_wild_prob
    	return math.rand_prob(player, prob)
        -- return true
    end,

    ReplaceSideLinesToWild = function(result)
        local rep_result = table.copy(result)
        for i = 1, 3 do
            rep_result[i][1] = Const.Types.Wild
            rep_result[i][5] = Const.Types.Wild
        end
        return rep_result
    end,
}