module("SlotsMonkeyKingCal", package.seeall)

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
        Cup = 1,
        Scroll = 2,
        Shield = 3,
        Hoop = 4,
        Potion = 5,
        Spade = 6,
        Heart = 7,
        Club = 8,
        Diamond = 9,
        StickyWild = 10,
        CountDownWild = 11,
        Scatter = 12,
        Treasure = 13,
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
                if line_data[i] == Const.Types.Scatter or line_data[i] == Const.Types.Treasure then return end
                if line_data[i] ~= Const.Types.BigWild and line_data[i] ~= Const.Types.StickyWild and line_data[i] ~= Const.Types.CountDownWild then
                    return line_data[i]
                end
            end
        elseif wild_pos == 5 then
            for i = 4, 1, -1 do
                if line_data[i] == Const.Types.Scatter or line_data[i] == Const.Types.Treasure then return end
                if line_data[i] ~= Const.Types.BigWild and line_data[i] ~= Const.Types.StickyWild and line_data[i] ~= Const.Types.CountDownWild then
                    return line_data[i]
                end
            end
        else
            local left_value
            for i = wild_pos-1, 1, -1 do
                if line_data[i] == Const.Types.Scatter or line_data[i] == Const.Types.Treasure then return end
                if line_data[i] ~= Const.Types.BigWild and line_data[i] ~= Const.Types.StickyWild and line_data[i] ~= Const.Types.CountDownWild then
                    left_value = line_data[i]
                    break
                end
            end
            local right_value
            for i = wild_pos + 1, 5, 1 do
                if line_data[i] == Const.Types.Scatter or line_data[i] == Const.Types.Treasure then break end
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
        if item_id >= Const.Types.Cup and item_id <= Const.Types.Diamond and continue_count >= 3 then
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

    GenFreeSpinCount = function(data)
        local scatter_count = 0
        for col = 1, 5 do
            for row = 1, 3 do
                if data[col][row] and data[col][row] == Const.Types.Scatter then
                    scatter_count = scatter_count + 1
                end
            end
        end
        return (scatter_count >= 3) and MonkeyKingOthersConfig[1].free_spin_delta or 0
    end,

--产生一列,column表示第几列,allow_wild表示是否能出现wild,config是经过了is_free_spin判断了之后的config
    GenColumn = function(config, column, allow_count_down)

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
    GenItemResult = function(is_free_spin, sticky_wild_pos, cd_wild_index)
        local config = is_free_spin and MonkeyKingFeatureReelConfig or MonkeyKingBaseReelConfig
        
        local result = {}
        --如果有count down wild,那么就不允许再出现count down wild了
        local allow_count_down = (cd_wild_index == nil)
        for i = 1, 5 do
            result[i] = Calculate.GenColumn(config, i, allow_count_down)
        end
        while Calculate.GetStickyWildCount(result) > 1 do
            for i = 1, 5 do
                result[i] = Calculate.GenColumn(config, i, allow_count_down)
            end
        end

        local new_sticky_wild_pos
        for _,col in ipairs({2, 4}) do
            for row = 1, 3 do
                if result[col][row] == Const.Types.StickyWild then
                    local col_index = (col == 2) and 1 or 2
                    new_sticky_wild_pos = (col_index - 1) * 3 + row
                end
            end
        end

        -----insert sticky wild
        if sticky_wild_pos then
            local col_index = math.floor(sticky_wild_pos / 4) + 1
            local col = col_index == 1 and 2 or 4
            local row = sticky_wild_pos - (col_index - 1) * 3
            result[col][row] = Const.Types.StickyWild
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

        return result, new_sticky_wild_pos, new_cd_wild_index
    end,

--将3*5的矩阵转换成一维数组
    TransResultToList = function(result)
        local list = {}
        for col = 1, 5 do
            for row = 1, 3 do
                ---屏蔽第1,5列的第3个
                if result[col][row - 1] then
                    table.insert(list, result[col][row - 1])
                end
            end
        end
        return list
    end,

--generate总的中奖信息
    GenPrizeInfo = function(result)
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
                local payrate = MonkeyKingPayrateConfig[item.item_id].payrate[item.continue_count - 2]
                item.line_index = line_index
                item.payrate = payrate
                table.insert(prize_info, item)
                total_payrate = total_payrate + payrate
            end
        end
        return prize_info, total_payrate
    end,

    --宝箱仅仅在第5列出现
    GetTreasureIndex = function ( result )
        for i = 1, 2 do
            if result[5][i] == Const.Types.Treasure then
                return i
            end
        end
    end,

    HasBigWild = function ( result )
        return (result[3][1] == Const.Types.BigWild and result[3][2] == Const.Types.BigWild and result[3][3] == Const.Types.BigWild)
    end,
}
