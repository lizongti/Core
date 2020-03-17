require "Common/SlotsGameCalculate" -- 重写的接口
require "Common/SlotsGameCal" -- 旧的接口
module("SlotsFrozenEraSpin", package.seeall)

local DEFAULT_FREE_SPIN_COUNT = 6


local special_parameter = {
    FrozenEra = 1,
    trigger3 = 0,
    trigger4 = 0,
    trigger5 = 0,
    triggerScatter = 0,
    triggerScatter3 = 0,
    triggerScatter4 = 0,
    triggerScatter5 = 0
}

-- 入口
function SlotsFrozenEraSpin:Enter()
    local player = self.parameters.player
    local player_game_info = self.parameters.player_game_info
    local special_parameter = self.parameters.special_parameter
    local is_free_spin = self.parameters.is_free_spin
    local game_room_config = self.parameters.game_room_config
    local player_game_status = self.parameters.player_game_status
    local amount = self.parameters.amount
    local game_type = self.parameters.game_type
    local player_feature_condition = self.parameters.player_feature_condition
    local session = self.parameters.session
    local save_data = player_game_info.save_data

    local save_data = player_game_info.save_data
    if not save_data.jackpot_param then
        -- 取出变量
        local jackpot_config = CommonCal.Calculate.get_config(player,
                                                              game_room_config.game_name ..
                                                                  "JackpotConfig")

        -- 初始化
        save_data.jackpot_param = {}
        -- 设置参数
        CommonCal.Calculate.InitJackpotParam(save_data.jackpot_param,
                                             jackpot_config)
    end
    local bonus_info = {
        content = save_data,
        prize_pool = CommonCal.Calculate.GetJakcpotParamToClient(
            save_data.jackpot_param).prize_pool
    }
    return bonus_info
end

-- 是否含有小游戏
IsBonusGame = function(game_room_config, player) return false end

------------------------------------------------------------------------------------------------------
-- 随机
------------------------------------------------------------------------------------------------------
local RandSelectedAcornCount = function(player, featureConfig)
    local weight = {}
    for __, info in ipairs(featureConfig) do
        weight[info.Random_acorn] = info.probability
    end
    return math.rand_weight(player, weight)
end

-- respin中出橡果时，随机变成普通橡果和金橡果的概率
local RandIsGoldenAcorn = function(player, acornConfig)
    local weight = {
        [1] = acornConfig[1].normal_acorn_weight,
        [2] = acornConfig[1].golden_acorn_weight
    }
    local resultId = math.rand_weight(player, weight)
    return resultId == 2
end

-- 橡果目前只有在触发时会有初始值，Respin中转出均无初始值。此表配置初始值TB倍数。
local RandFrozenBaseMultiple = function(player, frozenConfig, isGolden)
    local weights = {}
    for __, config in ipairs(frozenConfig) do
        if config.Frozen_item == 2 and isGolden or config.Frozen_item == 1 and
            not isGolden then
            weights[config.base_multiple] = config.weight
        end
    end
    return math.rand_weight(player, weights)
end

-- 配置第N次出相邻橡果或不相邻橡果的概率
local RandRespinCount = function(player, respinCountConfig, currentMaxCount,
                                 notAdjacentCount)
    local rndAdjacentRespinCount = 0
    local rndNotAdjacentRespinCount = {}

    -- 相邻是第几次（相邻一次性出完）
    local weights = {}
    for i = 1, currentMaxCount do
        table.insert(weights, respinCountConfig[i].adjacent_acorn)
    end
    local rndAdjacentRespinCount = math.rand_weight(player, weights)

    -- 不相邻分布，每个分别在第几次
    for notAdjacentIndex = 1, notAdjacentCount do
        weights = {}
        for i = 1, rndAdjacentRespinCount do
            table.insert(weights, respinCountConfig[i].notadjacent_acorn)
        end
        table.insert(rndNotAdjacentRespinCount,
                     math.rand_weight(player, weights))
    end
    return rndAdjacentRespinCount, rndNotAdjacentRespinCount
end

-- 金橡果是哪档位jackpot
local RandJackpot = function(player, jackpotConfig)
    local weights = {}
    for __, config in ipairs(jackpotConfig) do
        weights[config.jackpot_type] = config.random_weight
    end
    return math.rand_weight(player, weights)
end

-- 当前已有N个橡果时，这个轮次（3次以内）需要出现的相邻不相邻橡果个数
local RandRespinInfo = function(player, currentAdjacentCount, respinConfig)
    local config = respinConfig[currentAdjacentCount]

    local aid = math.rand_weight(player, {
        config.addoneadjacent_weight, config.addtwoadjacent_weight,
        config.addthreeadjacent_weight, config.noadjacent_weight
    })

    local naid = math.rand_weight(player, {
        config.addonenotadjacent_weight, config.addtwonotadjacent_weight,
        config.addthreenotadjacent_weight, config.nonotadjacent_weight
    })

    local rndAdjacentCount = aid == 4 and 0 or aid
    local rndNotAdjacentCount = naid == 4 and 0 or naid
    return rndAdjacentCount, rndNotAdjacentCount
end

local BonusTable2Map = function(bonusTable)
    local map = {}
    for __, info in ipairs(bonusTable) do
        if not map[info.row] then map[info.row] = {} end
        map[info.row][info.col] = {bonus = info.bonus, itemType = info.itemType}
    end
    return map
end

local BonusMap2Table = function(bonusMap)
    local retTable = {}
    for rowIndex, row in pairs(bonusMap) do
        for colIndex, item in pairs(row) do
            table.insert(retTable, {
                row = rowIndex,
                col = colIndex,
                bonus = item.bonus,
                itemType = item.itemType
            })
        end
    end
    return retTable
end

local Map2Table = function(map)
    local retTable = {}
    for rowIndex, row in pairs(map) do
        for colIndex, item in pairs(row) do
            table.insert(retTable, {row = rowIndex, col = colIndex})
        end
    end
    return retTable
end

-- 处理当前轮次相邻信息
local HandleRoundAdjacentInfo = function(player, respinConfig,
                                         respinCountConfig, currentMaxCount,
                                         frozenCount)
    local rndAdjacentCount, rndNotAdjacentCount =
        RandRespinInfo(player, frozenCount, respinConfig)
    local rndAdjacentRespinCount, rndNotAdjacentRespinCount =
        RandRespinCount(player, respinCountConfig, currentMaxCount,
                        rndNotAdjacentCount)
    -- 获得第rndAdjacentRespinCount次出现rndAdjacentCount个相邻橡果
    -- 第rndNotAdjacentRespinCount[i]次出现不相邻橡果
    return {
        AdjacentRespinCount = rndAdjacentRespinCount,
        AdjacentCount = rndAdjacentCount,
        NotAdjacentRespinCounts = rndNotAdjacentRespinCount
    }
end

local IsAcornPos = function(acornMap, row, col)
    return acornMap[row] and acornMap[row][col]
end

local AddAcornPos = function(acorns, row, col)
    if not acorns[row] then acorns[row] = {} end
    acorns[row][col] = true
end

-- 获得所有相邻 和所有不相邻，随机选择指定数量
local GetAdjacentFrozenInfo = function(historyMap, frozenMap)
    local adjacentAcorns, notAdjacentAcorns, notAcorns = {}, {}, {}
    local maxCol, maxRow = 5, 3
    for curRowIndex, curRow in pairs(frozenMap) do
        for curColIndex, curItem in pairs(curRow) do
            local leftColIndex = curColIndex - 1
            local RightColIndex = curColIndex + 1
            local TopRowIndex = curRowIndex - 1
            local BottomRowIndex = curRowIndex + 1
            if leftColIndex >= 1 and
                not IsAcornPos(frozenMap, curRowIndex, leftColIndex) then
                AddAcornPos(adjacentAcorns, curRowIndex, leftColIndex)
            end
            if RightColIndex <= maxCol and
                not IsAcornPos(frozenMap, curRowIndex, RightColIndex) then
                AddAcornPos(adjacentAcorns, curRowIndex, RightColIndex)
            end
            if TopRowIndex >= 1 and
                not IsAcornPos(frozenMap, TopRowIndex, curColIndex) then
                AddAcornPos(adjacentAcorns, TopRowIndex, curColIndex)
            end
            if BottomRowIndex <= maxRow and
                not IsAcornPos(frozenMap, BottomRowIndex, curColIndex) then
                AddAcornPos(adjacentAcorns, BottomRowIndex, curColIndex)
            end
        end
    end
    for rowIndex = 1, maxRow do
        for colIndex = 1, maxCol do
            if not IsAcornPos(historyMap, rowIndex, colIndex) then
                AddAcornPos(notAcorns, rowIndex, colIndex)
                if not IsAcornPos(adjacentAcorns, rowIndex, colIndex) then
                    AddAcornPos(notAdjacentAcorns, rowIndex, colIndex)
                end
            end
        end
    end
    return adjacentAcorns, notAdjacentAcorns, notAcorns
end

-- 替换origin_result
local AddAdjacentResult = function(origin_result, adjacentAcorns, adjacentCount,
                                   notAcorns, itemType, player)
    -- 判断剩余格子，相邻不够就填满
    local adjacentAcornsTab = Map2Table(adjacentAcorns)
    local notAcornsTab = Map2Table(notAcorns)
    if adjacentCount >= #notAcornsTab then
        for __, info in ipairs(notAcornsTab) do
            origin_result[info.row][info.col] = itemType.Xg
        end
    else
        for i = 1, adjacentCount do
            local rndIndex = math.random_ext(player, #adjacentAcornsTab)
            local rndAdjInfo = adjacentAcornsTab[rndIndex]
            table.remove(adjacentAcornsTab, rndIndex)
            origin_result[rndAdjInfo.row][rndAdjInfo.col] = itemType.Xg
        end
    end
end

-- 替换origin_result
local AddNotAdjacentResult = function(origin_result, notAdjacentAcorns,
                                      notAdjacentRespinCount, notAcorns,
                                      itemType, player)
    -- 判断剩余格子，不相邻不够就不加
    if notAdjacentRespinCount > 0 then
        local notAdjacentAcornsTab = Map2Table(notAdjacentAcorns)
        local notAcornsTab = Map2Table(notAcorns)

        if notAdjacentRespinCount <= #notAdjacentAcornsTab then
            for i = 1, notAdjacentRespinCount do
                local rndIndex = math.random_ext(player, #notAdjacentAcornsTab)
                local rndAdjInfo = notAdjacentAcornsTab[rndIndex]
                table.remove(notAdjacentAcornsTab, rndIndex)
                origin_result[rndAdjInfo.row][rndAdjInfo.col] = itemType.Xg
            end
        end
    end
end

-- 橡果替换
local ReplaceAcorn = function(player, origin_result, acornConfig, jackpotConfig,
                              frozenConfig, itemType, feature_spin_count,
                              save_data, respinConfig, respinCountConfig,
                              game_type, amount)
    local currentTable = save_data and save_data.current_bonus_table
    local bonusTable = {}
    local historyTable = currentTable
    local historyMap = nil

    if historyTable then
        bonusTable = table.DeepCopy(historyTable)
        historyMap = BonusTable2Map(historyTable)
    end

    local isInAcornGame = feature_spin_count > 0
    
    if isInAcornGame then
        if not save_data.round_respin_info then
            save_data.round_respin_info =
                HandleRoundAdjacentInfo(player, respinConfig, respinCountConfig,
                                        save_data.feature_spin_max,
                                        #save_data.frozen_table)
        end
        
        local frozenMap = BonusTable2Map(save_data.frozen_table)
        -- 获得所有相邻 和所有不相邻，随机选择指定数量
        local adjacentAcorns, notAdjacentAcorns, notAcorns =
            GetAdjacentFrozenInfo(historyMap, frozenMap)
        -- 判断剩余格子，相邻不够就填满，不相邻不够就不加
        local currentRoundRespinInfo = save_data.round_respin_info
        if feature_spin_count == currentRoundRespinInfo.AdjacentRespinCount then
            -- 加入currentRoundRespinInfo.AdjacentCount个相邻
            AddAdjacentResult(origin_result, adjacentAcorns,
                              currentRoundRespinInfo.AdjacentCount, notAcorns,
                              itemType, player)
        end
        local notAdjacentRespinCount = 0
        for __, respincount in ipairs(
                                   currentRoundRespinInfo.NotAdjacentRespinCounts) do
            if feature_spin_count == respincount then
                notAdjacentRespinCount = notAdjacentRespinCount + 1
            end
        end
        -- 加入notAdjacentRespinCount个不相邻
        AddNotAdjacentResult(origin_result, notAdjacentAcorns,
                             notAdjacentRespinCount, notAcorns, itemType, player)
    end
    
    local acornsFeatureCount = {}
    local goldenAcornInfos = {}

    -- 获得第一次橡果状态
    -- 在特性中新来的橡果基础倍率为0，连上则为1，然后每相邻一次加1，全中橡果加2
    for rowIndex = 1, #origin_result do
        acornsFeatureCount[rowIndex] = 0
        local row = origin_result[rowIndex]
        for colIndex = 1, #row do
            local item = row[colIndex]
            if item == itemType.Xg and
                not (historyMap and historyMap[rowIndex] and
                    historyMap[rowIndex][colIndex]) then
                -- 新出现的橡果
                -- 判断是不是金橡果
                -- 处理jackpot, 算入这次的总winchip
                local isGoldenAcorn = save_data and
                                          RandIsGoldenAcorn(player, acornConfig)
                local baseMulti = 0

                if not isInAcornGame then
                    baseMulti = RandFrozenBaseMultiple(player, frozenConfig,
                                                       isGoldenAcorn)
                end

                if isGoldenAcorn then
                    local jackpot = RandJackpot(player, jackpotConfig)
                    origin_result[rowIndex][colIndex] = itemType.Jxg
                    
                    table.insert(goldenAcornInfos, {
                        row = rowIndex,
                        col = colIndex,
                        jackpot = jackpot,
                        isGet = false
                    }) 

                end
                table.insert(bonusTable, {
                    row = rowIndex,
                    col = colIndex,
                    bonus = baseMulti,
                    itemType = row[colIndex]
                })
                acornsFeatureCount[rowIndex] = acornsFeatureCount[rowIndex] + 1
            elseif item ~= itemType.Xg and item ~= itemType.Jxg and
                isInAcornGame then
                -- 随机生成新一轮橡果以外的数据
                row[colIndex] = itemType.Normals[math.random_ext(player,
                                                                 #itemType.Normals)]
            end
        end
    end

    local noMoveBonusTable = table.DeepCopy(bonusTable)

    -- 判断触发特性spin
    local acornFeatureCount = 0
    if not isInAcornGame then
        local newPosInfo = {}
        for rowIndex, count in pairs(acornsFeatureCount) do
            if count >= 3 then
                local i = count
                for k, info in ipairs(bonusTable) do
                    if rowIndex == info.row then
                        if not save_data.ori_return_result then
                            save_data.ori_return_result =
                                table.DeepCopy(origin_result)
                        end
                        if not newPosInfo[info.row] or
                            not newPosInfo[info.row][info.col] then
                            save_data.ori_return_result[info.row][info.col] =
                                itemType.Normals[math.random_ext(player,
                                                                 #itemType.Normals)]
                        end
                        -- 改掉col向右边靠
                        for m, ginfo in ipairs(goldenAcornInfos) do
                            if ginfo.row == info.row and ginfo.col == info.col then
                                ginfo.col = 6 - i
                            end
                        end

                        info.col = 6 - i

                        i = i - 1
                        save_data.ori_return_result[info.row][info.col] =
                            info.itemType
                        if not newPosInfo[info.row] then
                            newPosInfo[info.row] = {}
                        end
                        newPosInfo[info.row][info.col] = true
                    end
                end
                acornFeatureCount = count
                break
            end
        end

        -- 如果触发了特性，把非触发的橡果替换成普通图标
        if acornFeatureCount > 0 then
            for rowIndex, count in pairs(acornsFeatureCount) do
                if count < 3 then
                    for k, info in pairs(bonusTable) do
                        if rowIndex == info.row and
                            (itemType.Jxg == info.itemType or itemType.Xg ==
                                info.itemType) then
                            bonusTable[k] = nil
                            save_data.ori_return_result[info.row][info.col] =
                                itemType.Normals[math.random_ext(player,
                                                                 #itemType.Normals)]
                            for m, ginfo in ipairs(goldenAcornInfos) do
                                if ginfo.row == info.row and ginfo.col ==
                                    info.col then
                                    ginfo.dontadd = true
                                end
                            end
                        end
                    end
                end
            end
            local tmp = {}
            for k, info in pairs(bonusTable) do
                table.insert(tmp, info)
            end
            bonusTable = tmp
        end
    end

    return bonusTable, acornFeatureCount, goldenAcornInfos, noMoveBonusTable
end

local HandleOriginBonusTable = function(bonus_table)
    -- 剔除操作，只留冰冻的
    local origin_bonus_map = BonusTable2Map(bonus_table)
    local rowAcornCounts = {}
    for rowIndex, row in pairs(origin_bonus_map) do
        rowAcornCounts[rowIndex] = 0
        for colIndex, item in pairs(row) do
            rowAcornCounts[rowIndex] = rowAcornCounts[rowIndex] + 1
        end
    end
    for rowIndex, count in pairs(rowAcornCounts) do
        if count < 3 then origin_bonus_map[rowIndex] = nil end
    end
    return BonusMap2Table(origin_bonus_map)
end

local GetWildsOnLine = function(result, game_room_config, payrate_file,
                                gameTypes)
    local wilds_on_line = {}
    local prize_items, pos_list, total_payrate, total_line_count =
        GenReelWayPrizeInfo(result, game_room_config, payrate_file)
    for __, info in pairs(pos_list) do
        local item = result[info.row][info.col]
        if item == gameTypes.Wild then
            table.insert(wilds_on_line, {row = info.row, col = info.col})
        end
    end
    return wilds_on_line
end

-- 先判断当前连线，有wild在连线就移动，再赔付连线
local MoveWild = function(origin_result, wildId, game_room_config,
                          payrate_config, left_or_right, gameTypes)
    -- 1.所有wild先模拟拓展
    local cols = {}
    local tmp_result = table.DeepCopy(origin_result)
    local wild_pos_list = SlotsGameCal.Calculate.GetItemPosition(tmp_result,
                                                                 game_room_config,
                                                                 gameTypes.Wild)
    if #wild_pos_list == 0 then return tmp_result, false, cols end
    for __, wildInfo in ipairs(wild_pos_list) do
        for rowIndex = 1, #tmp_result do
            tmp_result[rowIndex][wildInfo.col] = wildId
        end
    end

    -- 2。筛选在线上的 修改返回值
    local wilds_on_line = GetWildsOnLine(tmp_result, game_room_config,
                                         payrate_config, gameTypes)
    local final_result = table.DeepCopy(origin_result)
    local isTriggerWild = #wilds_on_line > 0

    if isTriggerWild then
        for __, wildInfo in ipairs(wilds_on_line) do
            for rowIndex = 1, #final_result do
                local row = final_result[rowIndex]
                row[wildInfo.col] = wildId
                cols[wildInfo.col] = true
            end
        end
    end
    return final_result, isTriggerWild, cols
end

local function GetFrozenMapRecursion(currentFrozenMap, leftFindMap)
    local find = false
    for curRowIndex, curRow in pairs(currentFrozenMap) do
        for curColIndex, curItem in pairs(curRow) do
            for rowIndex, row in pairs(leftFindMap) do
                for colIndex, item in pairs(row) do
                    if curRowIndex == rowIndex and
                        (curColIndex == colIndex + 1 or curColIndex == colIndex -
                            1) or curColIndex == colIndex and
                        (curRowIndex == rowIndex + 1 or curRowIndex == rowIndex -
                            1) then
                        find = true
                        if not currentFrozenMap[rowIndex] then
                            currentFrozenMap[rowIndex] = {}
                        end
                        currentFrozenMap[rowIndex][colIndex] = item
                        leftFindMap[rowIndex][colIndex] = nil
                    elseif curRowIndex == rowIndex and curColIndex == colIndex then
                        leftFindMap[rowIndex][colIndex] = nil
                    end
                end
            end
        end
    end
    local left = false
    for rowIndex, row in pairs(leftFindMap) do
        for colIndex, item in pairs(row) do
            left = true
            break
        end
    end
    if find and left then
        return GetFrozenMapRecursion(currentFrozenMap, leftFindMap)
    else
        return currentFrozenMap
    end
end

-- 所有积分+1倍
local AllScoreMultiAdd = function(frozenTable, num)
    for __, info in pairs(frozenTable) do info.bonus = info.bonus + num end
end

local GetFinalTotalScore = function(frozenTable, betAmount)
    local totalScore = 0
    -- print(betAmount)
    for __, info in pairs(frozenTable) do
        totalScore = totalScore + info.bonus
        -- print(info.bonus)
    end
    -- print('@@@@'..totalScore)
    return totalScore * betAmount
end

local GetFrozenMap = function(originMap, finalMap, betAmount, itemTypes)
    local totalScore = 0
    local jxgCount = 0
    local frozenMap = GetFrozenMapRecursion(originMap, finalMap)
    local frozenCount = 0
    local scoreMulti = 1
    local isFull = false
    for rowIndex, row in pairs(frozenMap) do
        for colIndex, item in pairs(row) do
            frozenCount = frozenCount + 1
            if item.itemType == itemTypes.Jxg then
                jxgCount = jxgCount + 1
            end

            totalScore = totalScore + betAmount * item.bonus
        end
    end
    if frozenCount == 15 then
        isFull = true
        scoreMulti = scoreMulti + 2
    end
    -- totalScore = totalScore * scoreMulti
    return frozenMap, totalScore, scoreMulti, isFull
end

local HasNewFrozen = function(oldFrozenTable, newFrozenTable)
    local oldMap = BonusTable2Map(oldFrozenTable)
    for __, info in ipairs(newFrozenTable) do
        if not oldMap[info.row] or not oldMap[info.row][info.col] then
            return true
        end
    end
    return false
end

local HandleFrozen = function(origin_bonus_table, bonusTable, betAmount,
                              itemTypes)
    local originMap = BonusTable2Map(origin_bonus_table)
    local finalMap = BonusTable2Map(bonusTable)
    local frozenMap, totalScore, scoreMulti, isFull =
        GetFrozenMap(originMap, finalMap, betAmount, itemTypes)
    local frozenTable = BonusMap2Table(frozenMap)
    return frozenTable, totalScore, scoreMulti, isFull
end

local CombineAcorn = function(origin_result, bonusTable)
    if bonusTable and #bonusTable > 0 then
        local final_result = BonusTable2Map(origin_result)
        for __, info in ipairs(bonusTable) do
            if not final_result[info.row] then
                final_result[info.row] = {}
            end
            final_result[info.row][info.col] =
                {bonus = info.bonus, itemType = info.itemType}
        end
        return BonusMap2Table(final_result)
    end
    return origin_result
end

function SlotsFrozenEraSpin:HoldSpin()
    local player = self.parameters.player
    local player_game_info = self.parameters.player_game_info
    local special_parameter = self.parameters.special_parameter
    local is_free_spin = self.parameters.is_free_spin
    local game_room_config = self.parameters.game_room_config
    local player_game_status = self.parameters.player_game_status
    local amount = self.parameters.amount
    local game_type = self.parameters.game_type
    local player_feature_condition = self.parameters.player_feature_condition
    local session = self.parameters.session
    local save_data = player_game_info.save_data

    special_parameter.trigger3 = 0
    special_parameter.trigger4 = 0
    special_parameter.trigger5 = 0
    special_parameter.triggerScatter = 0
    special_parameter.triggerScatter3 = 0
    special_parameter.triggerScatter4 = 0
    special_parameter.triggerScatter5 = 0

    local save_data = player_game_info.save_data

    if not save_data.feature_spin_count then 
        save_data.feature_spin_count = 0 
    end

    local feature_spin_count = save_data.feature_spin_count

    if (save_data.total_free_spin_times == nil or
        (not is_free_spin and feature_spin_count == 0)) then
        save_data.total_free_spin_times = 0
    end

    local lineNum = LineNum[game_type]()
    local total_amount = amount * lineNum -- 总共下注用的钱
    local isFirstAcornTrigger = false
    local isInAcornGame = false
    local needReplaceWild = true
    local need_add_jackpot = false
    local action_list = {}

    -- 特性权重表
    local frozenConfig = CommonCal.Calculate.get_config(player,
                                                        game_room_config.game_name ..
                                                            "FrozenConfig")
    local acornConfig = CommonCal.Calculate.get_config(player,
                                                       game_room_config.game_name ..
                                                           "AcornConfig")
    local respinConfig = CommonCal.Calculate.get_config(player,
                                                        game_room_config.game_name ..
                                                            "RespinConfig")
    local respinCountConfig = CommonCal.Calculate.get_config(player,
                                                             game_room_config.game_name ..
                                                                 "RespinCountConfig")
    local jackpotConfig = CommonCal.Calculate.get_config(player,
                                                         game_room_config.game_name ..
                                                             "JackpotConfig")

    -- item枚举
    local itemType = _G[game_room_config.game_name .. "TypeArray"].Types

    if feature_spin_count > 0 or player_game_info.free_spin_bouts > 0 then
        need_add_jackpot = false
    else
        need_add_jackpot = true
    end

    -- 转动滚筒,获取结果origin_result[row][col]
    local feature_file = nil

    if feature_spin_count > 0 then -- 是否在特性中
        feature_file = "FrozenEraFrozenReelConfig"
    end

    local origin_result, reel_file_name =
        SlotsGameCal.Calculate.GenItemResult(player, game_type, is_free_spin,
                                             game_room_config, feature_file)

    -- 橡果变换， 如果不在特性中，则判断是否触发特性，如果在特性中，则需要合并橡果
    local return_result = save_data.ori_return_result or
                              table.DeepCopy(origin_result)
    
    local bonusTable, acornFeatureCount, goldenAcornInfos, noMoveBonusTable =
        ReplaceAcorn(player, return_result, acornConfig, jackpotConfig,
                     frozenConfig, itemType, feature_spin_count, save_data,
                     respinConfig, respinCountConfig, game_type, amount)

    -- 赔率配置
    local payrate_file = CommonCal.Calculate.get_config(player,
                                                        game_room_config.game_name ..
                                                            "PayrateConfig")
    -- 连线规则, 1左连线，2右, 3左右连线
    local left_or_right = game_room_config.direction_type

    local final_result, total_payrate, pos_list, total_line_count
    local prize_items = {}
    local all_prize_list = {}
    local slots_win_chip = 0
    local total_win_chip = 0
    local total_jackpot_win = 0
    -- FreeSpin判断处理，特殊请求了才有freespin次数
    local free_spin_bouts = 0 -- 判断特性6

    -- 判断橡果触发，scatter也能触发
    if feature_spin_count > 0 then 
        -- 是否在橡果小游戏中
        isInAcornGame = true
        needReplaceWild = false
        feature_spin_count = feature_spin_count - 1
        save_data.feature_spin_count = feature_spin_count
        save_data.ori_return_result = return_result
        final_result = return_result
    else
        if acornFeatureCount > 0 then -- 橡果触发了特性
            save_data.origin_bonus_table = HandleOriginBonusTable(bonusTable)
            save_data.frozen_table = save_data.origin_bonus_table
            save_data.feature_spin_count = acornFeatureCount
            save_data.feature_spin_type = is_free_spin and 1 or 0
            save_data.feature_spin_max = acornFeatureCount
            print("spin max:", save_data.feature_spin_max)
            feature_spin_count = acornFeatureCount

            save_data.feature_bet_amount = total_amount
            isInAcornGame = true
            isFirstAcornTrigger = true

            save_data.round_respin_info =
                HandleRoundAdjacentInfo(player, respinConfig, respinCountConfig,
                                        save_data.feature_spin_max,
                                        #save_data.frozen_table)

            -- 普通的spin触发frozen增加次数
            GameStatusCal.Calculate.AddGameStatus(player_game_status,
                    GameStatusDefine.AllTypes.HoldSpinGame, save_data.feature_spin_count, 1, bet_amount)
            print("普通的spin触发frozen增加次数", save_data.feature_spin_count)
        else
            isInAcornGame = false
            save_data.ori_return_result = nil
        end

        -- 移动wild
        local wildcols, isTriggerWild
        final_result, isTriggerWild, wildcols =
            MoveWild(origin_result, itemType.Wild, game_room_config,
                     payrate_file, left_or_right, itemType)

        if isTriggerWild then
            local cols = {}
            for colIndex, _ in pairs(wildcols) do
                table.insert(cols, colIndex)
            end
            local moveWildTriggerAction =
                {
                    action_type = ActionType.ActionTypes.MoveWildTrigger,
                    feature = cols
                }
            table.insert(action_list, moveWildTriggerAction)
        end

        -- 获得连线结果
        prize_items, pos_list, total_payrate, total_line_count =
            GenReelWayPrizeInfo(final_result, game_room_config, payrate_file)
        -- 将连线结果放入all_prize_list
        all_prize_list = {}
        table.insert(all_prize_list, prize_items)

        -- slots赢取的筹码 = 倍率和 * 筹码
        slots_win_chip = total_payrate * amount

        -- 赢取的总筹码,slots筹码+游戏等特殊筹码
        total_win_chip = slots_win_chip
    end

    if not save_data.total_jackpot_win then
        save_data.total_jackpot_win = 0
    end

    local total_jackpot_win = 0
    local newGoldenAcornInfos = {}

    if bonusTable and save_data.origin_bonus_table then
        -- 计算冰冻和积分
        local isFullAcorn = false
        if save_data.current_bonus_table ~= bonusTable then
            local frozenTable, totalScore, scoreMulti, isFull =
                HandleFrozen(save_data.frozen_table, bonusTable,
                             save_data.feature_bet_amount, itemType)
            isFullAcorn = isFull
            local hasNewFrozen =
                HasNewFrozen(save_data.frozen_table, frozenTable)
            
            if isFirstAcornTrigger then
                save_data.score_multi = 1
                print("isFirstAcornTrigger首次触发")
            end

            if hasNewFrozen then
                feature_spin_count = save_data.feature_spin_max

                local delta = save_data.feature_spin_max - save_data.feature_spin_count
                -- delta为用了几次
                GameStatusCal.Calculate.AddGameStatus(player_game_status, GameStatusDefine.AllTypes.HoldSpinGame, delta, 1, bet_amount)

                save_data.feature_spin_count = save_data.feature_spin_max
                print("增加Respin次数:", delta)

                AllScoreMultiAdd(frozenTable, 1)
                AllScoreMultiAdd(bonusTable, 1)
                save_data.round_respin_info =
                    HandleRoundAdjacentInfo(player, respinConfig,
                                            respinCountConfig,
                                            save_data.feature_spin_max,
                                            #frozenTable)
            end
            local expand_multi = scoreMulti - 1
            save_data.score_multi = save_data.score_multi + expand_multi
            if expand_multi > 0 then
                AllScoreMultiAdd(frozenTable, expand_multi)
                AllScoreMultiAdd(bonusTable, expand_multi)
            end
            totalScore = GetFinalTotalScore(frozenTable,
                                            save_data.feature_bet_amount)
            save_data.total_bonus_score = totalScore -- * save_data.score_multi
            save_data.frozen_table = frozenTable
        end

        -- jackpot
        if #goldenAcornInfos > 0 then
            if not save_data.golden_acorn_infos then
                save_data.golden_acorn_infos = {}
            end
            for __, info in ipairs(goldenAcornInfos) do
                local find = false
                for _, infob in ipairs(save_data.golden_acorn_infos) do
                    if infob.row == info.row and infob.col == info.col then
                        find = true
                    end
                end

                if info.dontadd then
                    table.insert(newGoldenAcornInfos, info)
                end

                -- 新出现的金橡果
                if not find and not info.dontadd then
                    table.insert(save_data.golden_acorn_infos, info)
                end
            end

            local frozenMap = BonusTable2Map(save_data.frozen_table)
            for __, info in ipairs(save_data.golden_acorn_infos) do
                if frozenMap[info.row] and frozenMap[info.row][info.col] and
                    not info.isGet then
                    info.isGet = true

                    info.jackpotwin = CommonCal.Calculate.GetJackpotPoolChipVal(
                                          save_data.jackpot_param, info.jackpot,
                                          save_data.feature_bet_amount)

                    CommonCal.Calculate.ResetJackpotExtraChip(
                        save_data.jackpot_param, info.jackpot)
                    table.insert(newGoldenAcornInfos, info)
                    -- 新出现的
                    save_data.total_jackpot_win = save_data.total_jackpot_win + info.jackpotwin
                    LOG(RUN, INFO).Format("新出现的jackpot %s %s %s", info.row, info.col, info.jackpotwin)
                end

                if info.isGet then
                else
                    for _, infob in ipairs(goldenAcornInfos) do
                        if infob.row == info.row and infob.col == infob.col then
                            table.insert(newGoldenAcornInfos, info)
                        end
                    end
                end
            end

        end

        if save_data.golden_acorn_infos then
            for __, info in ipairs(save_data.golden_acorn_infos) do
                if info.isGet then
                    total_jackpot_win = total_jackpot_win + info.jackpotwin
                end
            end
        end

        local frozenTriggerAction = {
            action_type = ActionType.ActionTypes.FrozenTrigger,
            feature = {
                origin_bonus_table = save_data.origin_bonus_table,
                bonus_table = bonusTable,
                frozen_table = save_data.frozen_table,
                total_score = save_data.total_bonus_score,
                score_multi = save_data.score_multi,
                nomove_bonus_table = noMoveBonusTable,
                feature_spin_max = save_data.feature_spin_max
            }
        }
        table.insert(action_list, frozenTriggerAction)
        save_data.current_bonus_table = bonusTable

        -- 结束特性，结算总积分
        print("结束特性feature_spin_count", feature_spin_count, save_data.feature_spin_count)
        if feature_spin_count <= 0 or isFullAcorn then
            total_win_chip = save_data.total_bonus_score or 0
            total_win_chip = total_jackpot_win + total_win_chip
            LOG(RUN, INFO).Format("HoldSpin结算总积分%s %s %s", save_data.total_bonus_score, save_data.total_jackpot_win, total_win_chip)
            save_data.feature_spin_count = 0
            save_data.feature_bet_amount = 0
            save_data.total_bonus_score = 0
            save_data.total_jackpot_win = 0
            save_data.origin_bonus_table = nil
            save_data.current_bonus_table = nil
            save_data.frozen_table = nil
            save_data.golden_acorn_infos = nil
            save_data.score_multi = 1
            save_data.round_respin_info = nil
            save_data.ori_return_result = nil
            FeverQuestCal.OnFrozenEraRespinEnd(session, total_win_chip)
        end
    end

    -- 更新respin次数
    table.insert(action_list, {
        action_type = ActionType.ActionTypes.FeatureSpin,
        feature = save_data.feature_spin_count
    })

    local reel_ways_info = {}
    reel_ways_info.pos_list = pos_list
    reel_ways_info.total_line_count = total_line_count

    if #newGoldenAcornInfos == 0 and #goldenAcornInfos > 0 then
        for __, info in ipairs(goldenAcornInfos) do
            table.insert(newGoldenAcornInfos, info)
        end
    end

    if #newGoldenAcornInfos > 0 then
        table.insert(action_list, {
            action_type = ActionType.ActionTypes.WinGameJackpot,
            feature = newGoldenAcornInfos
        })
    end

    if need_add_jackpot then
        -- 奖池点数增长
        CommonCal.Calculate.AddJackpotExtraChip(save_data.jackpot_param,
                                                total_amount, jackpotConfig)
    end

    if total_jackpot_win > 0 then
        -- 添加action
        table.insert(action_list, {
            action_type = ActionType.ActionTypes.GameJackpotPool,
            parameter_list = {
                prize_pool = CommonCal.Calculate.GetJakcpotParamToClient(
                    save_data.jackpot_param).prize_pool,
                jacpot_win_chip = total_jackpot_win
            }
        })

        LOG(RUN, INFO).Format("触发jackpot%s %s", total_jackpot_win, save_data.total_jackpot_win)
    end

    -- 最后一次数据记录
    local slots_spin_list = {}
    table.insert(slots_spin_list, {
        item_ids = json.encode(SlotsGameCal.Calculate.TransResultToCList(
                                   not needReplaceWild and return_result or
                                       SlotsGameCal.Calculate.ReplaceBlock(
                                           return_result, itemType.Wild),
                                   game_room_config)),
        prize_items = prize_items,
        win_chip = total_win_chip,
        pre_action_list = json.encode(action_list),
        final_item_ids = json.encode(SlotsGameCal.Calculate.TransResultToCList(
                                         not needReplaceWild and final_result or
                                             SlotsGameCal.Calculate
                                                 .ReplaceBlock(final_result,
                                                               itemType.Wild),
                                         game_room_config)),
        reel_ways_info = json.encode(reel_ways_info),
        ways_type = 1
    })
    -- 客户端接收的表
    local formation_list = {}
    table.insert(formation_list, {slots_spin_list = slots_spin_list, id = 1})
    
    local result = {}
    result.final_result = return_result --结果数组
    result.total_win_chip = total_win_chip  --总奖金
    result.all_prize_list = all_prize_list --所有连线列表
    result.free_spin_bouts = free_spin_bouts --freespin的次数
    result.formation_list = formation_list --阵型列表
    result.reel_file_name = reel_file_name --reel表名
    result.slots_win_chip = slots_win_chip --总奖励
    result.special_parameter = special_parameter --其他参数，主要给模拟器传参
    return result
end

function SlotsFrozenEraSpin:NormalSpin()
    local player = self.parameters.player
    local player_game_info = self.parameters.player_game_info
    local special_parameter = self.parameters.special_parameter
    local is_free_spin = self.parameters.is_free_spin
    local game_room_config = self.parameters.game_room_config
    local player_game_status = self.parameters.player_game_status
    local amount = self.parameters.amount
    local game_type = self.parameters.game_type
    local player_feature_condition = self.parameters.player_feature_condition
    local session = self.parameters.session
    local save_data = player_game_info.save_data

    special_parameter.trigger3 = 0
    special_parameter.trigger4 = 0
    special_parameter.trigger5 = 0
    special_parameter.triggerScatter = 0
    special_parameter.triggerScatter3 = 0
    special_parameter.triggerScatter4 = 0
    special_parameter.triggerScatter5 = 0

    local save_data = player_game_info.save_data

    if not save_data.feature_spin_count then 
        save_data.feature_spin_count = 0 
    end

    local feature_spin_count = save_data.feature_spin_count

    if (save_data.total_free_spin_times == nil or
        (not is_free_spin and feature_spin_count == 0)) then
        save_data.total_free_spin_times = 0
    end

    if (is_free_spin) then
        save_data.total_free_spin_times = save_data.total_free_spin_times + 1
    end
    
    local lineNum = LineNum[game_type]()
    local total_amount = amount * lineNum -- 总共下注用的钱
    local isFirstAcornTrigger = false
    local isInAcornGame = false
    local needReplaceWild = true
    local need_add_jackpot = false
    local action_list = {}

    -- 特性权重表
    local frozenConfig = CommonCal.Calculate.get_config(player,
                                                        game_room_config.game_name ..
                                                            "FrozenConfig")
    local acornConfig = CommonCal.Calculate.get_config(player,
                                                       game_room_config.game_name ..
                                                           "AcornConfig")
    local respinConfig = CommonCal.Calculate.get_config(player,
                                                        game_room_config.game_name ..
                                                            "RespinConfig")
    local respinCountConfig = CommonCal.Calculate.get_config(player,
                                                             game_room_config.game_name ..
                                                                 "RespinCountConfig")
    local jackpotConfig = CommonCal.Calculate.get_config(player,
                                                         game_room_config.game_name ..
                                                             "JackpotConfig")

    -- item枚举
    local itemType = _G[game_room_config.game_name .. "TypeArray"].Types

    if feature_spin_count > 0 or player_game_info.free_spin_bouts > 0 then
        need_add_jackpot = false
    else
        need_add_jackpot = true
    end

    -- 转动滚筒,获取结果origin_result[row][col]
    local feature_file = nil

    if feature_spin_count > 0 then -- 是否在特性中
        feature_file = "FrozenEraFrozenReelConfig"
    end

    local origin_result, reel_file_name =
        SlotsGameCal.Calculate.GenItemResult(player, game_type, is_free_spin,
                                             game_room_config, feature_file)

    -- 橡果变换， 如果不在特性中，则判断是否触发特性，如果在特性中，则需要合并橡果
    local return_result = save_data.ori_return_result or
                              table.DeepCopy(origin_result)
    
    local bonusTable, acornFeatureCount, goldenAcornInfos, noMoveBonusTable =
        ReplaceAcorn(player, return_result, acornConfig, jackpotConfig,
                     frozenConfig, itemType, feature_spin_count, save_data,
                     respinConfig, respinCountConfig, game_type, amount)

    -- 赔率配置
    local payrate_file = CommonCal.Calculate.get_config(player,
                                                        game_room_config.game_name ..
                                                            "PayrateConfig")
    -- 连线规则, 1左连线，2右, 3左右连线
    local left_or_right = game_room_config.direction_type

    local final_result, total_payrate, pos_list, total_line_count
    local prize_items = {}
    local all_prize_list = {}
    local slots_win_chip = 0
    local total_win_chip = 0
    local total_jackpot_win = 0
    -- FreeSpin判断处理，特殊请求了才有freespin次数
    local free_spin_bouts = 0 -- 判断特性6
    local left_free_spin = player_game_info.free_spin_bouts + free_spin_bouts

    -- 判断橡果触发，scatter也能触发
    if feature_spin_count > 0 then 
        -- 是否在橡果小游戏中
        isInAcornGame = true
        needReplaceWild = false
        feature_spin_count = feature_spin_count - 1
        save_data.feature_spin_count = feature_spin_count
        print("new feature_spin_count:", feature_spin_count)
        save_data.ori_return_result = return_result
        final_result = return_result
    else
        if acornFeatureCount > 0 then -- 橡果触发了特性
            save_data.origin_bonus_table = HandleOriginBonusTable(bonusTable)
            save_data.frozen_table = save_data.origin_bonus_table
            save_data.feature_spin_count = acornFeatureCount
            save_data.feature_spin_type = is_free_spin and 1 or 0
            save_data.feature_spin_max = acornFeatureCount
            print("spin max:", save_data.feature_spin_max)
            feature_spin_count = acornFeatureCount

            save_data.feature_bet_amount = total_amount
            isInAcornGame = true
            isFirstAcornTrigger = true

            save_data.round_respin_info =
                HandleRoundAdjacentInfo(player, respinConfig, respinCountConfig,
                                        save_data.feature_spin_max,
                                        #save_data.frozen_table)

            -- 普通的spin触发frozen增加次数
            GameStatusCal.Calculate.AddGameStatus(player_game_status,
                    GameStatusDefine.AllTypes.HoldSpinGame, save_data.feature_spin_count, 1, bet_amount)
            print("普通的spin触发frozen增加次数", save_data.feature_spin_count)
        else
            isInAcornGame = false
            save_data.ori_return_result = nil
        end

        -- 移动wild
        local wildcols, isTriggerWild
        final_result, isTriggerWild, wildcols =
            MoveWild(origin_result, itemType.Wild, game_room_config,
                     payrate_file, left_or_right, itemType)

        if isTriggerWild then
            local cols = {}
            for colIndex, _ in pairs(wildcols) do
                table.insert(cols, colIndex)
            end
            local moveWildTriggerAction =
                {
                    action_type = ActionType.ActionTypes.MoveWildTrigger,
                    feature = cols
                }
            table.insert(action_list, moveWildTriggerAction)
        end

        -- triggerScatter触发了以后会选择特性，如果同时触发需要保存状态等待小游戏结束在选择
        local triggerScatter = SlotsGameCal.Calculate.GenFreeSpinCount(
                                   final_result, game_room_config,
                                   itemType.Scatter, 6) > 0
        if triggerScatter then
            -- 触发scatter，选择freespin和respin
            local triggerScatterAction =
            {
                action_type = ActionType.ActionTypes.ScatterTrigger,
                feature = triggerScatter
            }
            table.insert(action_list, triggerScatterAction)
            save_data.need_select = 1
        end

        local need_select = save_data.need_select == 1
        if need_select then
            -- 选择action
            local action = {
                action_type = ActionType.ActionTypes.SelectNeed,
                feature = need_select
            }
            table.insert(action_list, action)

            -- 进入bonus action
            local action = {
                action_type = ActionType.ActionTypes.EnterBonus,
                feature = need_select
            }
            table.insert(action_list, action)
        end

        -- 获得连线结果
        prize_items, pos_list, total_payrate, total_line_count =
            GenReelWayPrizeInfo(final_result, game_room_config, payrate_file)
        -- 将连线结果放入all_prize_list
        all_prize_list = {}
        table.insert(all_prize_list, prize_items)

        -- slots赢取的筹码 = 倍率和 * 筹码
        slots_win_chip = total_payrate * amount

        -- 赢取的总筹码,slots筹码+游戏等特殊筹码
        total_win_chip = slots_win_chip
    end

    local total_jackpot_win = 0
    local newGoldenAcornInfos = {}

    if bonusTable and save_data.origin_bonus_table then
        -- 计算冰冻和积分
        local isFullAcorn = false
        if save_data.current_bonus_table ~= bonusTable then
            local frozenTable, totalScore, scoreMulti, isFull =
                HandleFrozen(save_data.frozen_table, bonusTable,
                             save_data.feature_bet_amount, itemType)
            isFullAcorn = isFull
            local hasNewFrozen =
                HasNewFrozen(save_data.frozen_table, frozenTable)
            
            if isFirstAcornTrigger then
                save_data.score_multi = 1
                print("isFirstAcornTrigger首次触发")
            end

            if hasNewFrozen then
                feature_spin_count = save_data.feature_spin_max

                local delta = save_data.feature_spin_max - save_data.feature_spin_count
                -- delta为用了几次
                GameStatusCal.Calculate.AddGameStatus(player_game_status, GameStatusDefine.AllTypes.HoldSpinGame, delta, 1, bet_amount)

                save_data.feature_spin_count = save_data.feature_spin_max
                print("增加Respin次数:", delta, save_data.feature_spin_max, save_data.feature_spin_count)

                AllScoreMultiAdd(frozenTable, 1)
                AllScoreMultiAdd(bonusTable, 1)
                save_data.round_respin_info =
                    HandleRoundAdjacentInfo(player, respinConfig,
                                            respinCountConfig,
                                            save_data.feature_spin_max,
                                            #frozenTable)
            end
            local expand_multi = scoreMulti - 1
            save_data.score_multi = save_data.score_multi + expand_multi
            if expand_multi > 0 then
                AllScoreMultiAdd(frozenTable, expand_multi)
                AllScoreMultiAdd(bonusTable, expand_multi)
            end
            totalScore = GetFinalTotalScore(frozenTable,
                                            save_data.feature_bet_amount)
            save_data.total_bonus_score = totalScore -- * save_data.score_multi
            save_data.frozen_table = frozenTable
        end

        -- jackpot
        if #goldenAcornInfos > 0 then
            if not save_data.golden_acorn_infos then
                save_data.golden_acorn_infos = {}
            end

            for __, info in ipairs(goldenAcornInfos) do
                local find = false
                for _, infob in ipairs(save_data.golden_acorn_infos) do
                    if infob.row == info.row and infob.col == info.col then
                        find = true
                    end
                end
                if info.dontadd then
                    table.insert(newGoldenAcornInfos, info)
                end
                if not find and not info.dontadd then
                    table.insert(save_data.golden_acorn_infos, info)
                end
            end

            local frozenMap = BonusTable2Map(save_data.frozen_table)
            for __, info in ipairs(save_data.golden_acorn_infos) do
                if frozenMap[info.row] and frozenMap[info.row][info.col] and
                    not info.isGet then
                    info.isGet = true
                    info.jackpotwin = CommonCal.Calculate.GetJackpotPoolChipVal(
                                          save_data.jackpot_param, info.jackpot,
                                          save_data.feature_bet_amount)
                    CommonCal.Calculate.ResetJackpotExtraChip(
                        save_data.jackpot_param, info.jackpot)
                    table.insert(newGoldenAcornInfos, info)
                end

                if info.isGet then
                else
                    for _, infob in ipairs(goldenAcornInfos) do
                        if infob.row == info.row and infob.col == infob.col then
                            table.insert(newGoldenAcornInfos, info)
                        end
                    end
                end
            end

        end

        if save_data.golden_acorn_infos then
            for __, info in ipairs(save_data.golden_acorn_infos) do
                if info.isGet then
                    total_jackpot_win = total_jackpot_win + info.jackpotwin
                end
            end
        end

        local frozenTriggerAction = {
            action_type = ActionType.ActionTypes.FrozenTrigger,
            feature = {
                origin_bonus_table = save_data.origin_bonus_table,
                bonus_table = bonusTable,
                frozen_table = save_data.frozen_table,
                total_score = save_data.total_bonus_score,
                score_multi = save_data.score_multi,
                nomove_bonus_table = noMoveBonusTable,
                feature_spin_max = save_data.feature_spin_max
            }
        }
        table.insert(action_list, frozenTriggerAction)
        save_data.current_bonus_table = bonusTable
        -- 结束特性，结算总积分
        if feature_spin_count <= 0 or isFullAcorn then
            total_win_chip = save_data.total_bonus_score or 0
            total_win_chip = total_jackpot_win + total_win_chip
            save_data.feature_spin_count = 0
            save_data.feature_bet_amount = 0
            save_data.total_bonus_score = 0
            save_data.origin_bonus_table = nil
            save_data.current_bonus_table = nil
            save_data.frozen_table = nil
            save_data.golden_acorn_infos = nil
            save_data.score_multi = 1
            save_data.round_respin_info = nil
            save_data.ori_return_result = nil
            FeverQuestCal.OnFrozenEraRespinEnd(session, total_win_chip)
        end
    end

    table.insert(action_list, {
        action_type = ActionType.ActionTypes.FeatureSpin,
        feature = save_data.feature_spin_count
    })

    local reel_ways_info = {}
    reel_ways_info.pos_list = pos_list
    reel_ways_info.total_line_count = total_line_count

    local free_spin_bouts_left = GameStatusCal.Calculate.GetFreeSpinBouts(player_game_status)

    if (free_spin_bouts_left == 0 and is_free_spin and save_data.feature_spin_count == 0) then
        local free_total_win = player_game_info.free_total_win + total_win_chip
        -- free spin结算
        print("free spin结算")
        table.insert(action_list, {
            action_type = ActionType.ActionTypes.TotalFreeSpinWin,
            free_total_win = free_total_win,
            total_free_spin_times = save_data.total_free_spin_times
        })
    end

    if #newGoldenAcornInfos == 0 and #goldenAcornInfos > 0 then
        for __, info in ipairs(goldenAcornInfos) do
            table.insert(newGoldenAcornInfos, info)
        end

    end

    if #newGoldenAcornInfos > 0 then
        table.insert(action_list, {
            action_type = ActionType.ActionTypes.WinGameJackpot,
            feature = newGoldenAcornInfos
        })
    end

    if need_add_jackpot then
        -- 奖池点数增长
        CommonCal.Calculate.AddJackpotExtraChip(save_data.jackpot_param,
                                                total_amount, jackpotConfig)
    end
    -- 添加action
    table.insert(action_list, {
        action_type = ActionType.ActionTypes.GameJackpotPool,
        parameter_list = {
            prize_pool = CommonCal.Calculate.GetJakcpotParamToClient(
                save_data.jackpot_param).prize_pool,
            jacpot_win_chip = total_jackpot_win
        }
    })

    -- 最后一次数据记录
    local slots_spin_list = {}
    table.insert(slots_spin_list, {
        item_ids = json.encode(SlotsGameCal.Calculate.TransResultToCList(
                                   not needReplaceWild and return_result or
                                       SlotsGameCal.Calculate.ReplaceBlock(
                                           return_result, itemType.Wild),
                                   game_room_config)),
        prize_items = prize_items,
        win_chip = total_win_chip,
        pre_action_list = json.encode(action_list),
        final_item_ids = json.encode(SlotsGameCal.Calculate.TransResultToCList(
                                         not needReplaceWild and final_result or
                                             SlotsGameCal.Calculate
                                                 .ReplaceBlock(final_result,
                                                               itemType.Wild),
                                         game_room_config)),
        reel_ways_info = json.encode(reel_ways_info),
        ways_type = 1
    })
    -- 客户端接收的表
    local formation_list = {}
    table.insert(formation_list, {slots_spin_list = slots_spin_list, id = 1})

    
    local result = {}
    result.final_result = return_result --结果数组
    result.total_win_chip = total_win_chip  --总奖金
    result.all_prize_list = all_prize_list --所有连线列表
    result.free_spin_bouts = free_spin_bouts --freespin的次数
    result.formation_list = formation_list --阵型列表
    result.reel_file_name = reel_file_name --reel表名
    result.slots_win_chip = slots_win_chip --总奖励
    result.special_parameter = special_parameter --其他参数，主要给模拟器传参
    return result
end

-- 选择feature或者freespin，处理free_spin_bouts
function SlotsFrozenEraSpin:SelectBonus()
    local player_game_status = self.parameters.player_game_status
    local player = self.parameters.player
    local game_room_config = self.parameters.game_room_config
    local parameter = self.parameters.parameter
    local player_game_info = self.parameters.player_game_info
    local game_type = self.parameters.game_type
    local save_data = player_game_info.save_data
    local session = self.parameters.session
    local task = session.task
    
    local content = {}
    local save_data = player_game_info.save_data
    
    if save_data and save_data.need_select ~= 1 then
        LOG(RUN, INFO).Format("SelectBonus:无效的次数！！！")
        return content
    end

    if parameter == 'freespin' then
        content.free_spin_bouts = DEFAULT_FREE_SPIN_COUNT
        content.final_free_spin_bouts = player_game_info.free_spin_bouts + DEFAULT_FREE_SPIN_COUNT
        content.need_select = 0
        save_data.need_select = 0

        local bet_amount = SlotsGameCal.Calculate.GetBetAmount(player_game_info)

        GameStatusCal.Calculate.AddGameStatus(player_game_status, GameStatusDefine.AllTypes.FreeSpinGame, content.free_spin_bouts, 1, bet_amount)
    else
        local featureConfig = CommonCal.Calculate.get_config(player,
                                                             game_room_config.game_name ..
                                                                 "FeatureConfig")
        local frozenConfig = CommonCal.Calculate.get_config(player,
                                                            game_room_config.game_name ..
                                                                "FrozenConfig")
        local acornConfig = CommonCal.Calculate.get_config(player,
                                                           game_room_config.game_name ..
                                                               "AcornConfig")
        local jackpotConfig = CommonCal.Calculate.get_config(player,
                                                             game_room_config.game_name ..
                                                                 "JackpotConfig")
        local respinConfig = CommonCal.Calculate.get_config(player,
                                                            game_room_config.game_name ..
                                                                "RespinConfig")
        local respinCountConfig = CommonCal.Calculate.get_config(player,
                                                                 game_room_config.game_name ..
                                                                     "RespinCountConfig")
        local lineNum = LineNum[game_type]()
        local total_amount = player_game_info.bet_amount * lineNum
        local itemTypes = _G[game_room_config.game_name .. "TypeArray"].Types

        local last_formation_list = player_game_info.last_formation_list and
                                        json.decode(
                                            player_game_info.last_formation_list)
        local item_ids = last_formation_list and last_formation_list[1] and
                             SlotsGameCal.Calculate.TransResult(
                                 json.decode(
                                     last_formation_list[1].slots_spin_list[1]
                                         .item_ids), game_room_config)

        local acorncount = RandSelectedAcornCount(player, featureConfig)
        
        save_data.feature_spin_count = acorncount
        save_data.feature_spin_type = save_data.is_free_spin == 1 and 1 or 0
        save_data.feature_spin_max = save_data.feature_spin_count
        print("spin max:", save_data.feature_spin_max)
        save_data.round_respin_info = HandleRoundAdjacentInfo(player,
                                                             respinConfig,
                                                             respinCountConfig,
                                                             save_data.feature_spin_max,
                                                             save_data.feature_spin_max)
        save_data.origin_bonus_table = {}
        local goldenAcornInfos = {}
        for i = 1, acorncount do
            local isGoldenAcorn = RandIsGoldenAcorn(player, acornConfig)
            local baseMulti = RandFrozenBaseMultiple(player, frozenConfig,
                                                     isGoldenAcorn)
            local itemType = itemTypes.Xg
            if isGoldenAcorn then
                itemType = itemTypes.Jxg
                local jackpot = RandJackpot(player, jackpotConfig)
                local jackpotwin = CommonCal.Calculate.GetJackpotPoolChipVal(
                                       save_data.jackpot_param, jackpot,
                                       total_amount)
                -- 奖池初始化
                CommonCal.Calculate.ResetJackpotExtraChip(
                    save_data.jackpot_param, jackpot)
                table.insert(goldenAcornInfos, 1, {
                    row = 2,
                    col = 6 - i,
                    jackpotwin = jackpotwin,
                    jackpot = jackpot,
                    isGet = true
                })
            end
            table.insert(save_data.origin_bonus_table, {
                row = 2,
                col = 6 - i,
                bonus = baseMulti,
                itemType = itemType
            })
        end

        save_data.current_bonus_table = save_data.origin_bonus_table

        local action_list = {}
        -- jackpot
        if #goldenAcornInfos > 0 then
            table.insert(action_list, {
                action_type = ActionType.ActionTypes.WinGameJackpot,
                feature = goldenAcornInfos
            })
            save_data.golden_acorn_infos = goldenAcornInfos
        end

        local total_jackpot_win = 0
        if save_data.golden_acorn_infos then
            for __, info in ipairs(save_data.golden_acorn_infos) do
                total_jackpot_win = total_jackpot_win + info.jackpotwin
            end
        end

        -- 添加action
        table.insert(action_list, {
            action_type = ActionType.ActionTypes.GameJackpotPool,
            parameter_list = {
                prize_pool = CommonCal.Calculate.GetJakcpotParamToClient(
                    save_data.jackpot_param).prize_pool,
                jacpot_win_chip = total_jackpot_win
            }
        })

        save_data.feature_bet_amount = total_amount
        local frozenTable, totalScore, scoreMulti =
            HandleFrozen(save_data.origin_bonus_table,
                         save_data.current_bonus_table,
                         save_data.feature_bet_amount, itemTypes)
        save_data.score_multi = 1
        local expand_multi = scoreMulti - 1
        save_data.score_multi = save_data.score_multi + expand_multi
        if expand_multi > 0 then
            AllScoreMultiAdd(frozenTable, expand_multi)
            AllScoreMultiAdd(save_data.current_bonus_table, expand_multi)
        end
        totalScore =
            GetFinalTotalScore(frozenTable, save_data.feature_bet_amount)

        local return_result = item_ids
        for rowIndex = 1, #return_result do
            local row = return_result[rowIndex]
            for colIndex = 1, #row do
                local item = row[colIndex]
                if itemTypes.Jxg == item or itemTypes.Xg == item then
                    return_result[rowIndex][colIndex] =
                        itemTypes.Normals[math.random_ext(player,
                                                          #itemTypes.Normals)]
                end
            end
        end

        for __, info in ipairs(save_data.current_bonus_table) do
            return_result[info.row][info.col] = info.itemType
        end
        save_data.ori_return_result = return_result

        save_data.total_bonus_score = totalScore -- * scoreMulti
        save_data.frozen_table = frozenTable
        save_data.need_select = 0

        local tmp = table.DeepCopy(save_data)
        tmp.action_list = action_list
        content = tmp

        GameStatusCal.Calculate.AddGameStatus(player_game_status,
            GameStatusDefine.AllTypes.HoldSpinGame, save_data.feature_spin_count, 1, bet_amount)
    end

    content.is_finished = true

    return content
end
