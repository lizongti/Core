module("SlotsHalloweenNightCal", package.seeall)
require "Common/CommonCal"
Const = {
    Lines = {
        [1] = {1,1,1,1,1},
        [2] = {1,2,2,2,1},
        [3] = {2,3,3,3,2},
        [4] = {1,1,2,1,1},
        [5] = {1,3,2,3,1},
        [6] = {1,1,3,1,1},
        [7] = {1,3,1,3,1},
        [8] = {1,3,2,1,1},
        [9] = {1,1,2,3,1},
        [10] = {1,1,2,2,1},
        [11] = {1,3,2,2,1},
        [12] = {1,2,1,2,1},
        [13] = {1,2,3,2,1},
        [14] = {2,1,1,1,2},
        [15] = {2,2,2,2,2},
        [16] = {2,2,1,2,2},
        [17] = {2,2,3,2,2},
        [18] = {2,1,2,1,2},
        [19] = {2,1,3,1,2},
        [20] = {2,1,2,3,2},
        [21] = {2,3,1,2,2},
        [22] = {2,3,1,3,2},
        [23] = {1,2,2,3,2},
        [24] = {2,3,3,2,1},
        [25] = {1,2,3,3,2},
        [26] = {2,3,2,2,1},
        [27] = {2,2,1,2,1},
        [28] = {1,1,2,3,2},
        [29] = {2,3,2,1,1},
        [30] = {2,3,2,3,1}
    },

    Types = {
        Zombie = 1,
        WereWolf = 2,
        BlackCat = 3,
        Bat = 4,
        Candy = 5,
        Ace = 6,
        King = 7,
        Queue = 8,
        Jack = 9,
        StickyWild = 10,
        CountDownWild = 11,
        Scatter = 12,
        Tomb = 13,
        BigWild = 14
    },
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
                if line_data[i] == Const.Types.Scatter or line_data[i] == Const.Types.Tomb then return end
                if line_data[i] ~= Const.Types.BigWild and line_data[i] ~= Const.Types.StickyWild and line_data[i] ~= Const.Types.CountDownWild then
                    return line_data[i]
                end
            end
        elseif wild_pos == 5 then
            for i = 4, 1, -1 do
                if line_data[i] == Const.Types.Scatter or line_data[i] == Const.Types.Tomb then return end
                if line_data[i] ~= Const.Types.BigWild and line_data[i] ~= Const.Types.StickyWild and line_data[i] ~= Const.Types.CountDownWild then
                    return line_data[i]
                end
            end
        else
            local left_value
            for i = wild_pos-1, 1, -1 do
                if line_data[i] == Const.Types.Scatter or line_data[i] == Const.Types.Tomb then return end
                if line_data[i] ~= Const.Types.BigWild and line_data[i] ~= Const.Types.StickyWild and line_data[i] ~= Const.Types.CountDownWild then
                    left_value = line_data[i]
                    break
                end
            end
            local right_value
            for i = wild_pos + 1, 5, 1 do
                if line_data[i] == Const.Types.Scatter or line_data[i] == Const.Types.Tomb then break end
                if line_data[i] ~= Const.Types.BigWild and line_data[i] ~= Const.Types.StickyWild and line_data[i] ~= Const.Types.CountDownWild then
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
            if line_data[i] == Const.Types.StickyWild or line_data[i] == Const.Types.CountDownWild or line_data[i] == Const.Types.BigWild then
                table.insert(pos, i)
            end
        end
        return pos
    end,
}

    -----------------------------test----------------------------------
    local isTest = 0
    local isFir = 1
    -----------------------------test----------------------------------

Calculate = {
    --产生一行(这里的一行已经将wild换成它可以替换的图标了)的中奖结果
    GenNormalContinueCount = function(line_data)
        local item_id = line_data[1]
        if item_id >= Const.Types.StickyWild then return nil, nil end
        local continue_count = 1
        for i = 2, 5 do
            if line_data[i] == item_id then
                continue_count = continue_count + 1
            else
                break
            end
        end
        if item_id >= Const.Types.Zombie and item_id <= Const.Types.Jack and continue_count >= 3 then
            return item_id, continue_count
        else
            return nil, nil
        end
    end,

    GenOneLinePrize = function(line_data)
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
        local item_id, continue_count = Calculate.GenNormalContinueCount(rep_line_data)
        if item_id and continue_count then
            table.insert(prize_list, {
                continue_count = continue_count,
                item_id = item_id,
            })
        end
        return prize_list
    end,

    GenFreeSpinCount = function(player, data)
        local HalloweenNightOthersConfig = CommonCal.Calculate.get_config(player, "HalloweenNightOthersConfig")
        local scatter_count = 0
        for col = 1, 5 do
            for row = 1, 3 do
                if data[col][row] and data[col][row] == Const.Types.Scatter then
                    scatter_count = scatter_count + 1
                end
            end
        end
        return (scatter_count >= 3) and HalloweenNightOthersConfig[1].free_spin_delta or 0
    end,



--产生一列,column表示第几列,allow_wild表示是否能出现wild,config是经过了is_free_spin判断了之后的config
    GenColumn = function(player, config, column, allow_count_down)
        local player_id = player.id
        local sequence = config[column].sequence_array
        local sequence_len = #sequence
        local index = math.random_ext(player, 1, sequence_len)

		if (GlobalSlotsTest[player_id] ~= nil)
		then
            sequence, sequence_len, index = CommonCal.Calculate.GetSequence(player_id, column)
		end
        
        if column == 1 or column == 5 then
            local index_1 = index % sequence_len + 1
            return {sequence[index], sequence[index_1]}
        elseif (column == 3 and not allow_count_down) then
            local index_1, index_2 = index % sequence_len + 1, (index + 1) % sequence_len + 1
            while sequence[index] == Const.Types.CountDownWild or sequence[index_1] == Const.Types.CountDownWild or sequence[index_2] == Const.Types.CountDownWild do
                index = math.random_ext(player, 1, sequence_len)
                index_1, index_2 = index % sequence_len + 1, (index + 1) % sequence_len + 1
            end
            return {sequence[index], sequence[index_1], sequence[index_2]}
        else
            local index_1, index_2 = index % sequence_len + 1, (index + 1) % sequence_len + 1
            -------------------------------test----------------------------
            --print("SlotsHalloweenNightCal.isFir sss is:")
            --print(isFir)
            if (isTest == 1)
            then
                if (isFir == 1)
                then
                    isFir = 0
                    local weight_tab = {[1] = 0.1, [2] = 0.1, [3] = 0.1}
                    local result_index = math.rand_weight(player, weight_tab)
                    if (result_index == 1)
                    then
                        return {Const.Types.StickyWild, sequence[index_1], sequence[index_2]}
                    elseif (result_index == 2)
                    then
                        return {sequence[index], Const.Types.StickyWild, sequence[index_2]}
                    else
                        return {sequence[index], sequence[index_1], Const.Types.StickyWild}
                    end
                end
            end
			-------------------------------test----------------------------
            return {sequence[index], sequence[index_1], sequence[index_2]}
        end
    end,

    GetMaxBetAmount = function(player)
        local HalloweenNightBetAmountConfig = CommonCal.Calculate.get_config(player, "HalloweenNightBetAmountConfig")
        local old_req_level = 0
        for k, v in ipairs(HalloweenNightBetAmountConfig)
        do
            if (player.character.level >= old_req_level and player.character.level < v.required_level)
            then
                return HalloweenNightBetAmountConfig[k - 1].single_amount
            end
            old_req_level = v.required_level
        end

        local max_index = #HalloweenNightBetAmountConfig
		if (player.character.level >= HalloweenNightBetAmountConfig[max_index].required_level)
		then
			return HalloweenNightBetAmountConfig[max_index].single_amount
		end
        return 0
    end,

    GetStickyWildCount = function ( result )
        local sticky_count = 0
        for _,col in ipairs({2,4}) do
            for i = 1, 3 do
                if result[col][i] == Const.Types.StickyWild then
                    sticky_count = sticky_count + 1
                end
            end
        end
        return sticky_count
    end,

----返回一个5列的矩阵,第1、5列2行,其他3行
    GenItemResult = function(player, is_free_spin, sticky_wild_pos_list, cd_wild_index, feature_file)

        local reel_file_name = is_free_spin and "HalloweenNightFeatureReelConfig" or "HalloweenNightBaseReelConfig"
        if (feature_file ~= nil and feature_file ~= "")
        then
            reel_file_name = feature_file
        end
        local config = CommonCal.Calculate.get_config(player, reel_file_name)
        
        reel_file_name, config = CommonCal.Calculate.get_new_hand_config(player, is_free_spin, reel_file_name, config, "HalloweenNight")

        local result = {}
        --如果有count down wild,那么就不允许再出现count down wild了
        ------------------------------test-----------------------
        isFir = 1
        ------------------------------test------------------------
        local allow_count_down = (cd_wild_index == nil)
        for i = 1, 5 do
            
            result[i] = Calculate.GenColumn(player, config, i, allow_count_down)
        end
        -----------------注意测试工具的使用，小心卡住-------------------
        while Calculate.GetStickyWildCount(result) > 1 do
            for i = 1, 5 do
                result[i] = Calculate.GenColumn(player, config, i, allow_count_down)
            end
        end

        if (sticky_wild_pos_list ~= nil and #sticky_wild_pos_list > 0)
        then
            for _, sticky_wild_pos in ipairs(sticky_wild_pos_list) do
                local col_index = math.floor(sticky_wild_pos / 4) + 1
                local col = col_index == 1 and 2 or 4
                local row = sticky_wild_pos - (col_index - 1) * 3
                result[col][row] = Const.Types.StickyWild
            end
        end

        ---insert count down wild
        if cd_wild_index then
            result[3][cd_wild_index] = Const.Types.CountDownWild
        end

        local new_cd_wild_index
        for i = 1, 3 do
            if result[3][i] == Const.Types.CountDownWild and i ~= cd_wild_index then
                new_cd_wild_index = i
                break
            end
        end
        return result, new_cd_wild_index, reel_file_name
    end,

--将3*5的矩阵转换成一维数组
    TransResultToList = function(result)
        local list = {}
        for col = 1, 5 do
            for row = 1, 3 do
                ---屏蔽第1,5列的第3个
                if result[col][row] then
                    table.insert(list, result[col][row])
                end
            end
        end
        return list
    end,

--generate总的中奖信息
    GenPrizeInfo = function(player, result, new_sticky_list)
        local HalloweenNightPayrateConfig = CommonCal.Calculate.get_config(player, "HalloweenNightPayrateConfig")

        local prize_info = {}
        local total_payrate = 0
        for line_index, v in ipairs(Const.Lines) do
            local line_data = {}
            for i = 1, 5 do
                --v[i]是行,i是列
                table.insert(line_data, result[i][v[i]])
            end
            local one_line_prize = Calculate.GenOneLinePrize(line_data)
            for _, item in ipairs(one_line_prize) do
                if (HalloweenNightPayrateConfig[item.item_id] ~= nil)
                then
                    local payrate = HalloweenNightPayrateConfig[item.item_id].payrate[item.continue_count - 2]
                    if (payrate > 0)
                    then
                        item.line_index = line_index
                        item.payrate = payrate
                        table.insert(prize_info, item)
                        total_payrate = total_payrate + payrate
        
                        for i = 1, 5 do
                            --v[i]是行,i是列
                            local col = i
                            local row = v[i]
                            if result[col][row] == Const.Types.StickyWild then
                                local col_index = (col == 2) and 1 or 2
                                local new_sticky_wild_pos = (col_index - 1) * 3 + row
        
                                local is_same_wild_pos = 0
                                for _, sticky_wild_pos in pairs(new_sticky_list) do
                                    if (new_sticky_wild_pos == sticky_wild_pos)
                                    then
                                        is_same_wild_pos = 1
                                        break
                                    end
                                end
                                if (is_same_wild_pos == 0)
                                then
                                    table.insert(new_sticky_list, new_sticky_wild_pos)
                                end
                            end
                        end
                    end
                end
            end
        end
        return prize_info, total_payrate
    end,

    --宝箱仅仅在第5列出现
    GetTreasureIndex = function ( result )
        for i = 1, 2 do
            if result[5][i] == Const.Types.Tomb then
                return i
            end
        end
    end,

    HasBigWild = function ( result )
        return (result[3][1] == Const.Types.BigWild and result[3][2] == Const.Types.BigWild and result[3][3] == Const.Types.BigWild)
    end,
}