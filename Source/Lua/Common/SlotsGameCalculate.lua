-------------------------------------------------------------------------------------------------------------------------------------------------------------
--对外接口
-------------------------------------------------------------------------------------------------------------------------------------------------------------
--获取所有连线结果
function CheckAllLine(result, lines, payrateConfig, leftOrRight, gameTypes)
    --总赔率
    local slots_payrate = 0
    local prize_list = {}
    --遍历所有的连线模式
    for line_index, line in pairs(lines) do
        --检查指定连线模式,指定连线号下,当前摇出来的组合是否可以组成连线
        --返回连线结果{element1,element2,element3...},和这个连线结果中是否是左连
        local line_result, is_left = CheckOneLine(line, result, leftOrRight, gameTypes)

        if(line_result ~= nil)
        then
            --连线成功则计算倍率
            local prize = OneResultToPrize(line_result, line_index, is_left, gameTypes, payrateConfig)
            if(prize ~= nil)
            then
                --总赔率
                slots_payrate = slots_payrate + prize["payrate"]
                table.insert(prize_list, prize)
            end
        end
    end

    return prize_list, slots_payrate
end


--检查一条连线规则是否成立,成立则返回点,不成立返回nil
--line: 连线的配置;滚筒结果;左右起始点
 function CheckOneLine(line, result, leftOrRight, gameTypes)
    local tmp_list = {}
    local element4, element5
    local isLeft = true           --连线结果是否是左连
    --左连,或者左右可连进行左连判断
    --记录前3个元素,判断是否3连
    --分别记录后2个值,用于判断是否4连,5连
    if(leftOrRight == 1 or leftOrRight == 3)
    then
        --左连
        tmp_list, element4, element5 = getElements(line, result, isLeft)
        -- print(string.format("%d %d %d %d %d",tmp_list[1], tmp_list[2], tmp_list[3], element4, element5))
    elseif(leftOrRight == 2)
    then
        isLeft = false
        --右连
        tmp_list, element4, element5 = getElements(line, result, isLeft)
        -- print(string.format("%d %d %d %d %d",tmp_list[1], tmp_list[2], tmp_list[3], element4, element5))

    end

    --判断是否3连
    local same_element = getSameElement(tmp_list, gameTypes) 

    --不是3连,但是左右都可以连接,则额外再判断一次右连
    if(same_element == nil and leftOrRight == 3)
    then
        isLeft = false
        tmp_list, element4, element5 = getElements(line, result, isLeft)
        -- print(string.format("%d %d %d %d %d",tmp_list[1], tmp_list[2],tmp_list[3],element4,element5))
        same_element = getSameElement(tmp_list, gameTypes) 
    end

    --没有连线
    if(same_element == nil)
    then
        return nil, isLeft
    end


    tmp_list = getLineResult(same_element, element4, element5, tmp_list, gameTypes)

    return tmp_list, isLeft
end


local CheckInTable = function(table_list, pos)
    for k, v in pairs(table_list) do
        if v.col == pos.col and v.row == pos.row then
            return true
        end
    end
    return false
end

local function SingleIsWild(item, type)
    if item == type.Wild then
        return true
    end

    if type.Wilds then
        for i=1, #type.Wilds do
            if type.Wilds[i] == item then
                return true
            end
        end
    end

    return false
end

----挨着3个及以上
local GenSinglePrizeLines = function(prize_list, pos_list, result, item_id, game_room_config, formation, payrate_config, bet_ratio, is_new)
    local type = _G[game_room_config.game_name.."TypeArray"].Types

    bet_ratio = bet_ratio or 1
    local cur_payrate = 0

    local continue_count = 0
    local line_count = 0

    local cur_pos_list = {}
    local item_count_list = {}
    --从左至右，连续N列上有相同图标出现即可进行赔付
    for col = 1, #formation do
        local item_count = 0
        for row = 1, #result do
            if (result[row][col] == item_id or SingleIsWild(result[row][col], type)) then
                item_count = item_count + 1
                table.insert(cur_pos_list, {col = col, row = row})
            end
        end
        if (item_count > 0) then
            continue_count = continue_count + 1

            table.insert(item_count_list, item_count)
        else
            break
        end
    end

    if (continue_count >= 3) then
        line_count = 1
        for k, v in pairs(item_count_list) do
            line_count = line_count * v
        end

        local config = payrate_config[item_id]
        if (config ~= nil) then
            local payrate = config.payrate[continue_count - 2]
            local local_payrate = payrate * line_count

            if (local_payrate > 0) then
                if is_new then
                    local prize = {
                        payrate = payrate * 1000,
                        line_index = 0,
                        item_pos_arr = cur_pos_list
                    }
                    table.insert(prize_list, prize)
                else
                    local prize = {
                        line_count = line_count,
                        item_id = item_id,
                        continue_count = continue_count,
                        payrate = payrate * 1000,
                        line_index = 0,
                        item_pos_arr = cur_pos_list
                    }
                    table.insert(prize_list, prize)
                end
                
                cur_payrate = cur_payrate + local_payrate

                for k, pos in pairs(cur_pos_list) do
                    if (not CheckInTable(pos_list, pos)) then
                        table.insert(pos_list, {col = pos.col, row = pos.row})
                    end
                end                
            end
        end
    end

    return cur_payrate, line_count
end

GenReelWayPrizeInfo = function(result, game_room_config, payrate_config, bet_ratio, formation_id, is_new)
    formation_id = formation_id or 'Formation1'
    local formation = _G[game_room_config.game_name.."FormationArray"][formation_id]
    local type = _G[game_room_config.game_name.."TypeArray"].Types

    local prize_list = {}

    local total_payrate = 0

    local total_line_count = 0

    local pos_list = {}

    --print("result1 is:", json.encode(result))

    local item_ids = {}
    for col = 1, #formation do
        for row = 1, #result do
            if (result[row][col] ~= type.Wild) then
                local is_exist = false
                for k, v in pairs(item_ids) do
                    if (v == result[row][col]) then
                        is_exist = true
                        break
                    end
                end
                if (not is_exist) then
                    table.insert(item_ids, result[row][col])
                end
            end
        end
    end
    --LOG(RUN, INFO).Format("[SlotsGameCalculate][GenPrizeInfo1] item_ids: %s", Table2Str(item_ids))
    for k, item_id in pairs(item_ids) do
        local single_payrate, single_line_count = GenSinglePrizeLines(prize_list, pos_list, result, 
            item_id, game_room_config, formation, payrate_config, bet_ratio, is_new)
        total_payrate = total_payrate + single_payrate
        total_line_count = total_line_count + single_line_count
    end
    return prize_list, pos_list, total_payrate, total_line_count
end

-- {
--     ["from_index"] = 1;
--     ["payrate"] = 2;
--     ["item_id"] = 5;
--     ["continue_count"] = 3;
--     ["line_index"] = 3;
--     ["to_index"] = 3;
-- }
--计算这条线的赔率
--赔率是线里的元素对应n连的赔率
--Wild可以当做是单独的元素,也可以被转化为别的元素来计算.Wild的3连如果比元素TMP的5连赔率高,则取Wild3连
function OneResultToPrize(lineResult, lineIndex, isLeft, gameTypes, payRateConfig)
    if(lineResult == nil or #lineResult < 3 or payRateConfig == nil)
    then
        return nil
    end
   
    --wild连线的赔率
    local  wild_payrate, wild_id, wild_continue, normal_id, wild_isLeft = checkWildPayrate(lineResult, isLeft, gameTypes, payRateConfig)
    --普通元素连线的赔率
    local normal_payrate = payRateConfig[normal_id].payrate[(#lineResult - 2)]


    local from_index, to_index, item_id, payrate, continue_count
    --Wild连线自己的赔率就比较大
    if(wild_payrate > normal_payrate)
    then
        item_id = wild_id
        continue_count = wild_continue
        payrate = wild_payrate
        --按照Wild的连线方式
        isLeft = wild_isLeft
    else
        --Wild当做普通元素做连线的赔率比较大
        item_id = normal_id
        continue_count = #lineResult
        payrate = normal_payrate
    end

    --获取起始点和截止点
    if(isLeft)
    then
        from_index = 1
        to_index = continue_count
    else
        from_index = 5
        to_index = 6 - continue_count     --5 - continue_count + 1
    end

    local prize = {
        item_id = item_id,
        continue_count = continue_count,
        payrate = payrate,
        line_index = lineIndex,
        from_index = from_index,
        to_index = to_index,
    }
   
    return prize
end

--是否出现FreeSpin
--摇出来的结果的table, 出现freeSpin的需要的最小个数
-- result = {
--     {5, 2, 5, 7, 3}, 
--     {9, 5, 6, 12, 3},
--     {11, 13, 2, 4, 7},
-- }
function IsFreeSpin(result, min, scatterId)
    local count = 0
    for k, list in pairs(result) do
        for key, itemId in pairs(list) do
            if(itemId == scatterId)
            then
                count = count + 1
            end
        end
    end

    if(count < min)
    then
        return false
    end

    return true
end

--检查一维数组中是否有Wild
function IsHaveWild(lineResult, gameTypes)
    for k, v in pairs(lineResult) do
        if(gameTypes.WildList[v])
        then
            return true
        end
    end

    return false
end

--检查指定元素是否是Wild
function IsWild(element, gameTypes)
    if(gameTypes.WildList[v])
    then
        return true
    end

    return false
end
-------------------------------------------------------------------------------------------------------------------------------------------------------------
--内部调用功能性函数
-------------------------------------------------------------------------------------------------------------------------------------------------------------
--根据左起或右起取出元素
function getElements(line, result, isLeft)
    --临时存储
    local tmp_list = {}         --根据连线规则取出的元素列表1~3或5~3

    if(isLeft)
    then
        --遍历连线配置,根据连线配置取出对应的值[1~3],用于判断3连
        for index = 1, 3, 1 do
            local row = line[index]
            table.insert(tmp_list, result[row][index])
        end
        return tmp_list, result[line[4]][4], result[line[5]][5]
    end

    --遍历连线配置,根据连线配置取出对应的值[5~3],用于判断3连
    for index = 5, 3, -1 do
        local row = line[index]
        table.insert(tmp_list, result[row][index])
        -- tmp_list[index] = result[row][index]
    end

    return tmp_list, result[line[2]][2], result[line[1]][1]
end


--前3个相同的元素,元素4和元素5
 function getLineResult(sameElement, element4, element5, tmpList, gameTypes)
    --3连情况1: 3个都为Wild
    if(sameElement == 0)
    then
        if(isSameWithWild(element4, element5, gameTypes))
        then   
            --4,5号元素一致(包含Wild),则为5连
            table.insert(tmpList, element4)
            table.insert(tmpList, element5)
        else
            table.insert(tmpList, element4)
        end
        return tmpList
    end

    --3个不都为Wild,需要判断是否与same_element相同
    if(isSameWithWild(sameElement,element4, gameTypes))
    then
        --4号元素也相同,则判断5号元素
        table.insert(tmpList, element4)
        if(isSameWithWild(sameElement, element5, gameTypes))
        then
            --5号也相同,则是5连
            table.insert(tmpList, element5)
        end
        return tmpList
    end
   
    --4号元素不同,则直接判定为3连
    return tmpList
end

--判断2个元素是否相同,若其中一个元素为Wild,则视为相同
 function isSameWithWild(element1, element2, gameTypes)
    -- print(string.format("比较元素[%d][%d]",element1, element2))
    if(gameTypes.WildList[element1] or gameTypes.WildList[element2])
    then
        return true
    elseif(element1 == element2)
    then
        return true
    end

    return false
end

--获取相同的元素
--有wild和其他的唯一element,则返回element;有wild,其余的element不相同,则返回nil;都是wild,则返回0
--默认只写了3个元素的判断,用于3连,则不需要遍历
function getSameElement(elementList, gameTypes)
    local element = nil

    for key, value in ipairs(elementList) do
        -- print(element,key, value)
        --元素是否是wild
        if(gameTypes.WildList[value] ~= true)
        then
            -- print("value不是Wild")
            --不是wild则赋值并比较
            if (element == nil)
            then
                -- print("第一次为element赋值")
                --第一次出现普通元素则赋值
                element = value
            else
                -- print("比较element和value", element, value)
                --不是则进行比较
                if(element ~= value)
                then
                    -- print("element和value不同,直接返回nil")
                    --不同则可以直接返回nil
                    return nil
                end
                -- print("element和value相同")
                --相同则不用处理
            end
        end
        --元素是wild则不用处理
    end

    if(element == nil)
    then
        --都是wild返回0
        return 0
    end

    return element
end

 function elementIsWild(gameTypes, element)
    if(gameTypes.WildList[element] == true)
    then
        return true
    end

    return false
end

--计算连线中的Wild赔率
--返回Wild赔率和,Wild的连线方向
function checkWildPayrate(lineResult, isLeft, gameTypes, payRateConfig)
    local wild_continue = 0     --Wild连线个数
    local wild_payrate = 0      --Wild连线赔率
    local wild_id = 0           --Wild的Id
    local normal_id = 0         --连线中的普通元素Id
    --遍历结果,计算是否有Wild连线
    for k, item_id in ipairs(lineResult) do

        --按照顺序第一个就是Wild可以正确运行,若第一个就不是Wild则不会知道WildId
        if (elementIsWild(gameTypes, item_id))
        then
            wild_id = item_id
            --是Wild则对Wild连线数+1
            wild_continue = wild_continue + 1
        else
            normal_id = item_id
            --碰到不是Wild则直接退出
            break
        end
    end

    --按照连线顺序已经有了Wild连线,则计算Wild连线赔率
    if(wild_continue > 2)
    then
        wild_payrate = payRateConfig[wild_id].payrate[wild_continue - 2]
        return wild_payrate, wild_id, wild_continue, normal_id, isLeft
    end

    wild_continue = 0
    --若不是,还有一种可能是5元素,反着连也有可能出现Wild连线
    if (#lineResult == 5 and elementIsWild(gameTypes, lineResult[5]))
    then
        wild_id = lineResult[5]
        wild_continue = 1
        for index = 4, 1, -1 do
            if(lineResult[index] == wild_id)
            then
                wild_continue = wild_continue + 1
            else
                break
            end
        end
    end
    
     --按照连线顺序已经有了Wild连线,则计算Wild连线赔率
    if(wild_continue > 2)
    then
        wild_payrate = payRateConfig[wild_id].payrate[wild_continue - 2]
        return wild_payrate, wild_id, wild_continue, normal_id, isLeft
    end

    return wild_payrate, wild_id, wild_continue, normal_id, isLeft
end


--------------------------------------------------------------------------------------------------------------------------------------------------
--777类玩法
--------------------------------------------------------------------------------------------------------------------------------------------------
function Print_r ( t )  
    local print_r_cache={}
    local function sub_print_r(t,indent)
        if (print_r_cache[tostring(t)]) then
            print(indent.."*"..tostring(t))
        else
            print_r_cache[tostring(t)]=true
            if (type(t)=="table") then
                for pos,val in pairs(t) do
                    if (type(val)=="table") then
                        print(indent.."["..pos.."] => "..tostring(t).." {")
                        sub_print_r(val,indent..string.rep(" ",string.len(pos)+8))
                        print(indent..string.rep(" ",string.len(pos)+6).."}")
                    elseif (type(val)=="string") then
                        print(indent.."["..pos..'] => "'..val..'"')
                    else
                        print(indent.."["..pos.."] => "..tostring(val))
                    end
                end
            else
                print(indent..tostring(t))
            end
        end
    end
    if (type(t)=="table") then
        print(tostring(t).." {")
        sub_print_r(t,"  ")
        print("}")
    else
        sub_print_r(t,"  ")
    end
    print()
end

--将线的配置{1, 2, 1}-->{[1] = 2, [2] = 1}
local function getElementInfoByLine(line)
    local element_info = {}
    for key, value in pairs(line)
    do
        if (element_info[value] == nil)
        then
            element_info[value] = 1
        else
            element_info[value] = element_info[value] + 1
        end
    end
    return element_info
end

--检查是否所有元素都是Wild
local function checkElementsIsAllWild(lineResult, gameTypes)
    for key, value in pairs(lineResult)
    do
        if (not gameTypes.WildList[value])
        then
            return false
        end
    end
    return true
end


--检查是否包含指定的目标元素,不分顺序
--入参都是一维table
local function checkElementsHaveAll(lineResult, lineConfig)
    --记录已有元素个数
    local element_info = getElementInfoByLine(lineResult)
    -- Print_r(element_info)
    -- Print_r(lineConfig)
    --对比指定的元素,个数是否相同
    for key, value in pairs(lineConfig)
    do
        if (element_info[value] == nil or element_info[value] == 0)
        then
            -- print("不一样")
            return false
        else
            element_info[value] = element_info[value] - 1
        end
    end
    -- print("完全一致")
    return true
end

--包含指定的元素或Wild
--3连就是指定1种元素和Wid
--普通的奖励就是指定2种或3种元素和Wild
local function checkElementsAndWild(lineResult, lineConfig, gameTypes)
    --记录获取配置信息
    local config_element_info = getElementInfoByLine(lineConfig)
    -- Print_r(element_info)
    -- Print_r(lineConfig)
    for kev, value in pairs(lineResult)
    do
        --不是规定的元素,并且也不是Wild.则次规则不成立
        if ((config_element_info[value] == nil) and (not gameTypes.WildList[value]))
        then
            -- print("普通判定不成立", value)
            return false
        end
    end
    -- print("普通判定成功")
    return true
end

GameSlots777 = {
    CheckElementsHaveAll = checkElementsHaveAll,
    CheckElementsAndWild = checkElementsAndWild,
}

GameSlotsMega5xWins = {
    CheckElementsHaveAll = checkElementsHaveAll,
    CheckElementsAndWild = checkElementsAndWild,
}

