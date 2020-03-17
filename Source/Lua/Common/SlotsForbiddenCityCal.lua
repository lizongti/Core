module("SlotsForbiddenCityCal", package.seeall)
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
        Palace = 1,
        GuZheng = 2,
        China = 3,
        JinZan = 4,
        Flower = 5,
        Ace = 6,
        King = 7,
        Queue = 8,
        Jack = 9,
        Ten = 10,
        Scatter = 11,
        Wild = 12,
    },

    PrizeDirection = {
		LEFT = 1,
		RIGHT = 2,
	}
}

Util = {
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
    --产生一行(这里的一行已经将wild换成它可以替换的图标了)的中奖结果
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

    CompareNormalAndWild = function (player, item_id, continue_count, wild_count, prize_list, direction )
		local has_normal_prize = item_id and continue_count and (continue_count >= 3)
		local has_wild_prize = wild_count and (wild_count >= 3)
        if has_wild_prize and has_normal_prize then
            local ForbiddenCityPayrateConfig = CommonCal.Calculate.get_config(player, "ForbiddenCityPayrateConfig")
			local normal_payrate = ForbiddenCityPayrateConfig[item_id].payrate[continue_count - 2]
			local wild_payrate = ForbiddenCityPayrateConfig[Const.Types.Wild].payrate[wild_count - 2]
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

    GenFreeSpin = function(data)
        local scatter_count = 0
        for i = 1, 3 do
            for j = 1, 5 do
                if data[i][j] == Const.Types.Scatter then
                    scatter_count = scatter_count + 1
                end
            end
        end
        -- return (scatter_count >= 3) and ForbiddenCityOthersConfig[1].free_spin_delta or 0
        return scatter_count >= 3
    end,

--产生一列,column表示第几列,allow_wild表示是否能出现wild,config是经过了is_free_spin判断了之后的config
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

    GetMaxBetAmount = function(player)
        local ForbiddenCityBetAmountConfig = CommonCal.Calculate.get_config(player, "ForbiddenCityBetAmountConfig")
        local old_req_level = 0
        for k, v in ipairs(ForbiddenCityBetAmountConfig)
        do
            if (player.character.level >= old_req_level and player.character.level < v.required_level)
            then
                return ForbiddenCityBetAmountConfig[k - 1].single_amount
            end
            old_req_level = v.required_level
        end

        local max_index = #ForbiddenCityBetAmountConfig
		if (player.character.level >= ForbiddenCityBetAmountConfig[max_index].required_level)
		then
			return ForbiddenCityBetAmountConfig[max_index].single_amount
		end
        return 0
    end,

--产生原始序列 3*5 matrix
    GenItemResult = function(player, is_free_spin)
        local reel_file_name = is_free_spin and "ForbiddenCityFeatureReelConfig" or "ForbiddenCityBaseReelConfig"
        local config = is_free_spin and CommonCal.Calculate.get_config(player, reel_file_name)

        reel_file_name, config = CommonCal.Calculate.get_new_hand_config(player, is_free_spin, reel_file_name, config, "ForbiddenCity")


        local result = {}
        for i = 1, 5 do
            result[i] = Calculate.GenColumn(player, config, i)
        end

        -- result[1][2] = Const.Types.Wild
        -- result[1][3] = Const.Types.Wild
        -- result[1][1] = Const.Types.Wild

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
        local ForbiddenCityPayrateConfig = CommonCal.Calculate.get_config(player, "ForbiddenCityPayrateConfig")
		for line_index, v in ipairs(Const.Lines) do
			local line_data = {}
			for i = 1, 5 do
				--v[i]是行,i是列
				table.insert(line_data, result[v[i]][i])
            end

            local one_line_prize = Calculate.GenOneLinePrize(player, line_data)

			
			for _, item in ipairs(one_line_prize) do
				
				local config = ForbiddenCityPayrateConfig[item.item_id]
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

    TransExtraWildPosToList = function(wild_pos)
        local list = {}
        for _,v in ipairs(wild_pos) do
            table.insert(list, (v.row - 1) * 5 + v.column)
        end
        return list
    end,
}
