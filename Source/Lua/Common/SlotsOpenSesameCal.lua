module("SlotsOpenSesameCal", package.seeall)
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
        Maid = 1,
        Bandit = 2,
        Duck = 3,
        BroadSword = 4,
        Hat = 5,
        Pot = 6,
        Wild = 7,--阿里巴巴
        Scatter = 8,--宝藏
        Bonus = 9,--芝麻开门
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

    GenWildReplaceValue = function( line_data, wild_pos )
        if wild_pos == 1 then
            for i = 2, 5, 1 do
                if line_data[i] == Const.Types.Scatter or line_data[i] == Const.Types.Bonus then return end
                if line_data[i] ~= Const.Types.Wild then
                    return  line_data[i]
                end
            end
        elseif wild_pos == 5 then
            for i = 4, 1, -1 do
                if line_data[i] == Const.Types.Scatter or line_data[i] == Const.Types.Bonus then return end
                if line_data[i] ~= Const.Types.Wild then
                    return line_data[i]
                end
            end
        else
            local left_value
            for i = wild_pos-1, 1, -1 do
                if line_data[i] == Const.Types.Scatter or line_data[i] == Const.Types.Bonus then return end
                if line_data[i] ~= Const.Types.Wild then
                    left_value = line_data[i]
                    break
                end
            end
            local right_value
            for i = wild_pos + 1, 5, 1 do
                if line_data[i] == Const.Types.Scatter or line_data[i] == Const.Types.Bonus then break end
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

    RandUnrepeated = function(player, tab, count)
        if count > #tab then return end
        local new_tab = table.copy(tab)
        local result = {}
        for i = 1, count, 1 do
            local rand_index = math.random_ext(player, #new_tab)
            table.insert(result, new_tab[rand_index])
            table.remove(new_tab, rand_index)
        end
        return result
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
        local OpenSesamePayrateConfig = CommonCal.Calculate.get_config(player, "OpenSesamePayrateConfig")
		local has_normal_prize = item_id and continue_count and (continue_count >= 3)
		local has_wild_prize = wild_count and (wild_count >= 3)
        if has_wild_prize and has_normal_prize then
            local normal_payrate = 0
            local wild_payrate = 0
            if (OpenSesamePayrateConfig[item_id] and OpenSesamePayrateConfig[item_id].payrate[continue_count - 2])
            then
                normal_payrate = OpenSesamePayrateConfig[item_id].payrate[continue_count - 2]
            end

            if (OpenSesamePayrateConfig[item_id] and OpenSesamePayrateConfig[Const.Types.Wild].payrate[wild_count - 2])
            then
                wild_payrate = OpenSesamePayrateConfig[Const.Types.Wild].payrate[wild_count - 2]
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
    end,

	GenOneLinePrize = function(player, line_data)
		local prize_list = {}
        ----LOG(RUN, INFO).Format("[SlotsOpenSesame][Start] player %s, line_data is: %s", player.id, Table2Str(line_data))
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
        ----LOG(RUN, INFO).Format("[SlotsOpenSesame][Start] player %s, prize_list is: %s", player.id, Table2Str(prize_list))
		return prize_list
	end,

    GenFreeSpinCount = function(player, data)
        local OpenSesameOthersConfig = CommonCal.Calculate.get_config(player, "OpenSesameOthersConfig")
        local scatter_count = 0
        for i = 1, 3 do
            for j = 1, 5 do
                if data[i][j] == Const.Types.Scatter then
                    scatter_count = scatter_count + 1
                end
            end
        end
        return (scatter_count >= 3) and OpenSesameOthersConfig[1].free_spin_delta or 0
    end,

    GenBonusProgress = function(player, data)
        local OpenSesameOthersConfig = CommonCal.Calculate.get_config(player, "OpenSesameOthersConfig")
        local bonus_count = 0
        for i = 1, 3 do
            for j = 1, 5 do
                if data[i][j] == Const.Types.Bonus then
                    bonus_count = bonus_count + 1
                end
            end
        end
        return (bonus_count >= 3) and OpenSesameOthersConfig[1].bonus_game_delta or 0
    end,
--产生一列,column表示第几列,allow_wild表示是否能出现wild,config是经过了is_free_spin判断了之后的config
    GenColumn = function(player, config, column, allow_wild)
        local player_id = player.id
        local sequence = config[column].sequence_array
        local sequence_len = #sequence
        local index = math.random_ext(player, 1, sequence_len)

        if (GlobalSlotsTest[player_id] ~= nil)
        then
            sequence, sequence_len, index = CommonCal.Calculate.GetSequence(player_id, column)
            allow_wild = 1
		end

        
        local index_1, index_2 = index % sequence_len + 1, (index + 1) % sequence_len + 1
        if not allow_wild then
            while sequence[index] == Const.Types.Wild or sequence[index_1] == Const.Types.Wild or sequence[index_2] == Const.Types.Wild do
                index = math.random_ext(player, 1, #sequence)
                index_1 = index % sequence_len + 1
                index_2 = (index + 1) % sequence_len + 1
            end
        end
        return {sequence[index], sequence[index_1], sequence[index_2]}
    end,

--产生原始序列 3*5 matrix和extra_wild,extra_wild 需要提前随出来
    GenItemResult = function(player, is_free_spin, feature_file)
        local reel_file_name = is_free_spin and "OpenSesameReelFreeSpinConfig" or "OpenSesameReelConfig"
        if (feature_file ~= nil and feature_file ~= "")
        then
            reel_file_name = feature_file
        end

        if (player.character.level <= tonumber(ConstValue[8].value))
		then		
			reel_file_name = is_free_spin and "OpenSesameNewHand1ReelFreeSpinConfig" or "OpenSesameNewHand1ReelConfig"
		elseif (player.character.level <= tonumber(ConstValue[9].value))
		then
			reel_file_name = is_free_spin and "OpenSesameNewHand2ReelFreeSpinConfig" or "OpenSesameNewHand2ReelConfig"
		elseif (player.character.level <= tonumber(ConstValue[10].value))
		then
			reel_file_name = is_free_spin and "OpenSesameNewHand3ReelFreeSpinConfig" or "OpenSesameNewHand3ReelConfig"
        end

        if (feature_file ~= nil and feature_file ~= "")
        then
            reel_file_name = feature_file
        end

        local config = CommonCal.Calculate.get_config(player, reel_file_name)

        --result is a 5*3 matrix22
        local result = {{}, {}, {}, {}, {}}
        --先随第3列,如果第3列第二行是wild,则其他列均不出现wild
        result[3] = Calculate.GenColumn(player, config, 3, true)
        local is_middle_wild = (result[3][1] == Const.Types.Wild or result[3][2] == Const.Types.Wild or result[3][3] == Const.Types.Wild)--is col3 row 2 wild
        local other_columns = {1,2,4,5}
        local extra_wild = Calculate.GenExtraWildPos(player, result[3])
        if is_free_spin then
            local no_wild_cols = {}
            for k,v in ipairs(extra_wild) do
                table.insert(no_wild_cols, v.column)
            end
            for _,v in ipairs(other_columns) do
                --如果中间是wild,那么就随额外的3个wild的位置,被这3个wild所占的列不能出现wild
                local allow_wild = not (is_middle_wild and (table.find(no_wild_cols, v)))
                result[v] = Calculate.GenColumn(player, config, v, allow_wild)
            end
        else
            for _,v in ipairs(other_columns) do
                result[v] = Calculate.GenColumn(player, config, v, not is_middle_wild)
            end
        end
        local tran_result = Calculate.TransResult(result)
        
        return tran_result, extra_wild, reel_file_name
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

--在原始序列加入wild,extra_wild是另外三个wild的row和col
    GenResultWithWild = function(result, extra_wild)
        local result_with_wild = table.copy(result)
        for column = 1, 5 do
            if result_with_wild[1][column] == Const.Types.Wild or result_with_wild[2][column] == Const.Types.Wild or result_with_wild[3][column] == Const.Types.Wild then
                result_with_wild[1][column] = Const.Types.Wild
                result_with_wild[2][column] = Const.Types.Wild
                result_with_wild[3][column] = Const.Types.Wild
            end
        end

        for _,v in ipairs(extra_wild) do
            result_with_wild[v.row][v.column] = Const.Types.Wild
        end

        return result_with_wild
    end,

    GetMaxBetAmount = function(player)
        local OpenSesameBetAmountConfig = CommonCal.Calculate.get_config(player, "OpenSesameBetAmountConfig")
        local old_req_level = 0
        for k, v in ipairs(OpenSesameBetAmountConfig)
        do
            if (player.character.level >= old_req_level and player.character.level < v.required_level)
            then
                return OpenSesameBetAmountConfig[k - 1].single_amount
            end
            old_req_level = v.required_level
        end

        local max_index = #OpenSesameBetAmountConfig
		if (player.character.level >= OpenSesameBetAmountConfig[max_index].required_level)
		then
			return OpenSesameBetAmountConfig[max_index].single_amount
        end
        
        return 0
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

    --把按行排列的转成按列排列的
    TranRowToCol = function (list)
        local result = {}
        for k,v in ipairs(list) do
            local row = math.floor((k - 1) / 5) + 1
            local col = k - 5 * (row - 1)
            result[(col - 1) * 3 + row] = v
        end
        return result
    end,

    --把按行的index转成按列排的index
    TranRowToColIndex = function(index)
        local row = math.floor((index - 1) / 5) + 1
        local col = index - 5 * (row - 1)
        return (col - 1) * 3 + row
    end,

    --for guidance
    TransListToResult = function ( list )
        local result = {}
        for i = 1, 3 do
            result[i] = {}
            for j = 1, 5 do
                result[i][j] = list[(i - 1) * 5 + j]
            end
        end
        return result
    end,


--generate总的中奖信息
    GenPrizeInfo = function(player, result)
        local OpenSesamePayrateConfig = CommonCal.Calculate.get_config(player, "OpenSesamePayrateConfig")
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
				
				local config = OpenSesamePayrateConfig[item.item_id]
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

--这里只传第三列
    GenExtraWildPos = function(player, col_3)
        local OpenSesameExtraWildConfig = CommonCal.Calculate.get_config(player, "OpenSesameExtraWildConfig")
        if col_3[1] == Const.Types.Wild or col_3[2] == Const.Types.Wild or col_3[3] == Const.Types.Wild then
            local weight_tab = {}
            for k,v in ipairs(OpenSesameExtraWildConfig) do
                table.insert(weight_tab, v.weight)
            end
            local result_index = math.rand_weight(player, weight_tab)
            local column_array = OpenSesameExtraWildConfig[result_index].columns_array
            local count_array = OpenSesameExtraWildConfig[result_index].count_array
            local wild_pos = {}
            for i = 1, #column_array do
                local column = column_array[i]
                local wild_row_list = Util.RandUnrepeated(player, {1,2,3}, count_array[i])
                for _,row in ipairs(wild_row_list) do
                    table.insert(wild_pos, {row = row, column = column})
                end
            end
            return wild_pos
        else
            return {}
        end
    end,

    TransExtraWildPosToList = function(wild_pos)
        local list = {}
        for _,v in ipairs(wild_pos) do
            -- table.insert(list, (v.row - 1) * 5 + v.column)
            table.insert(list, (v.column - 1) * 3 + v.row)
        end
        return list
    end,

------generate bonus game payrate
    GenBonusGamePayrate = function(player)
        local OpenSesameBonusGameConfig = CommonCal.Calculate.get_config(player, "OpenSesameBonusGameConfig")
        local weight_tab = {}
        for _,v in ipairs(OpenSesameBonusGameConfig) do
            table.insert(weight_tab, v.weight)
        end
        local prize_level = math.rand_weight(player, weight_tab)
        return OpenSesameBonusGameConfig[prize_level].payrate
    end,
}
