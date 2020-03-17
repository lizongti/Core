module("SlotsBacktoJurassicCal", package.seeall)
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
		DinosaurSkeletonsHead = 1,--恐龙骨架（头）
		ArchaeologicalMen = 2,
		Archaeology  = 3,
		Jeep  = 4,
		Amber = 5,
		DragonEgg1 = 6,
		DragonEgg2 = 7,
		DragonEgg3 = 8,
		DragonEgg4 = 9,
		Wild = 10,
		Scatter = 11,
		TyrannosaurusRexHead = 12,--霸王龙头
		TriceratopsHead = 13,--三角龙头
		StegosaurusHead = 14,--剑龙头
		BrontosaurusHead = 15, --雷龙头
		Velociraptor = 16, --迅猛龙

		DinosaurSkeletonsHead_2_1 = 101,
		DinosaurSkeletonsHead_2_2 = 102,


		TyrannosaurusRexHead_3_1 = 2001,
		TyrannosaurusRexHead_3_2 = 2002,
		TyrannosaurusRexHead_3_3 = 2003,

		TriceratopsHead_2_1 = 301,
		TriceratopsHead_2_2 = 302,

		StegosaurusHead_2_1 = 401,
		StegosaurusHead_2_2 = 402,

		BrontosaurusHead_3_1 = 5001,
		BrontosaurusHead_3_2 = 5002,
		BrontosaurusHead_3_3 = 5003,
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



	GenLeftWildReplaceValue = function( line_data, wild_pos)
        if wild_pos == 1 then
			for i = 2, 5, 1 do
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
            if left_value then
                return left_value
            end
		end
		
		return nil
	end,
	
	GenRightWildReplaceValue = function( line_data, wild_pos)
		if wild_pos == 5 then
			for i = 4, 1, -1 do
                if line_data[i] ~= Const.Types.Wild then
                    return  line_data[i]
                end
            end
        else
            local right_value
			for i = wild_pos + 1, 5, 1 do
                if line_data[i] ~= Const.Types.Wild then
                    right_value = line_data[i]
                    break
                end
            end
            if right_value then
                return right_value
            end
		end
		return nil
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

	ReplaceBigItemCol = function (result, i, Item_Type, Item_Type_2_Array, Item_Type_3_Array)
		local is_replace = 0
		local Count = 0
		local Start_Pos = 0
		for j = 1, 3 do
			if (result[j][i] == Item_Type)
			then
				if (Count == 0)
				then
					Start_Pos = j
				end
				Count = Count + 1
			else
				Count = 0
			end
			if (Count >= 2)
			then
				for pos = Start_Pos, Start_Pos + Count - 1 do
					if (Count == 2)
					then
						if (Item_Type_2_Array ~= nil)
						then
							result[pos][i] = Item_Type_2_Array[pos - Start_Pos + 1]
							is_replace = 1
						end
					end
					if (Count == 3)
					then
						if (Item_Type_3_Array ~= nil)
						then
							result[pos][i] = Item_Type_3_Array[pos - Start_Pos + 1]
							is_replace = 1
						end
					end
				end
			end
		end
		return is_replace
	end,

	ReplaceBigItem = function(result)
		local DinosaurSkeletonsHead_2_Array = {}
		DinosaurSkeletonsHead_2_Array[1] = Const.Types.DinosaurSkeletonsHead_2_1
		DinosaurSkeletonsHead_2_Array[2] = Const.Types.DinosaurSkeletonsHead_2_2

		--local DinosaurSkeletonsHead_3_Array = {}
		--DinosaurSkeletonsHead_3_Array[1] = Const.Types.DinosaurSkeletonsHead_3_1
		---DinosaurSkeletonsHead_3_Array[2] = Const.Types.DinosaurSkeletonsHead_3_2
		--DinosaurSkeletonsHead_3_Array[3] = Const.Types.DinosaurSkeletonsHead_3_3

		--local TyrannosaurusRexHead_2_Array = {}
		--TyrannosaurusRexHead_2_Array[1] = Const.Types.TyrannosaurusRexHead_2_1
		--TyrannosaurusRexHead_2_Array[2] = Const.Types.TyrannosaurusRexHead_2_2

		local TyrannosaurusRexHead_3_Array = {}
		TyrannosaurusRexHead_3_Array[1] = Const.Types.TyrannosaurusRexHead_3_1
		TyrannosaurusRexHead_3_Array[2] = Const.Types.TyrannosaurusRexHead_3_2
		TyrannosaurusRexHead_3_Array[3] = Const.Types.TyrannosaurusRexHead_3_3


		local TriceratopsHead_2_Array = {}
		TriceratopsHead_2_Array[1] = Const.Types.TriceratopsHead_2_1
		TriceratopsHead_2_Array[2] = Const.Types.TriceratopsHead_2_2

		--local TriceratopsHead_3_Array = {}
		--TriceratopsHead_3_Array[1] = Const.Types.TriceratopsHead_3_1
		--TriceratopsHead_3_Array[2] = Const.Types.TriceratopsHead_3_2
		--TriceratopsHead_3_Array[3] = Const.Types.TriceratopsHead_3_3

		local StegosaurusHead_2_Array = {}
		StegosaurusHead_2_Array[1] = Const.Types.StegosaurusHead_2_1
		StegosaurusHead_2_Array[2] = Const.Types.StegosaurusHead_2_2

		--local StegosaurusHead_3_Array = {}
		--StegosaurusHead_3_Array[1] = Const.Types.StegosaurusHead_3_1
		--StegosaurusHead_3_Array[2] = Const.Types.StegosaurusHead_3_2
		--StegosaurusHead_3_Array[3] = Const.Types.StegosaurusHead_3_3

		--local BrontosaurusHead_2_Array = {}
		--BrontosaurusHead_2_Array[1] = Const.Types.BrontosaurusHead_2_1
		--BrontosaurusHead_2_Array[2] = Const.Types.BrontosaurusHead_2_2

		local BrontosaurusHead_3_Array = {}
		BrontosaurusHead_3_Array[1] = Const.Types.BrontosaurusHead_3_1
		BrontosaurusHead_3_Array[2] = Const.Types.BrontosaurusHead_3_2
		BrontosaurusHead_3_Array[3] = Const.Types.BrontosaurusHead_3_3

		--local Velociraptor_2_Array = {}
		--Velociraptor_2_Array[1] = Const.Types.Velociraptor_2_1
		--Velociraptor_2_Array[2] = Const.Types.Velociraptor_2_2

		--local Velociraptor_3_Array = {}
		--Velociraptor_3_Array[1] = Const.Types.Velociraptor_3_1
		--Velociraptor_3_Array[2] = Const.Types.Velociraptor_3_2
		--Velociraptor_3_Array[3] = Const.Types.Velociraptor_3_3

		for i = 1, 5 do
			local loop = 1
			while (loop == 1)
			do
				loop = Calculate.ReplaceBigItemCol(result, i, Const.Types.DinosaurSkeletonsHead, DinosaurSkeletonsHead_2_Array, nil)
			end
			
			loop = 1
			while (loop == 1)
			do
				loop = Calculate.ReplaceBigItemCol(result, i, Const.Types.TyrannosaurusRexHead, nil, TyrannosaurusRexHead_3_Array)
			end
			
			loop = 1
			while (loop == 1)
			do
				loop = Calculate.ReplaceBigItemCol(result, i, Const.Types.TriceratopsHead, TriceratopsHead_2_Array, nil)
			end
			
			loop = 1
			while (loop == 1)
			do
				loop = Calculate.ReplaceBigItemCol(result, i, Const.Types.StegosaurusHead, StegosaurusHead_2_Array, nil)
			end
			
			loop = 1
			while (loop == 1)
			do
				loop = Calculate.ReplaceBigItemCol(result, i, Const.Types.BrontosaurusHead, nil, BrontosaurusHead_3_Array)
			end
			
			--Calculate.ReplaceBigItemCol(result, i, Const.Types.Velociraptor, Velociraptor_2_Array, Velociraptor_3_Array)
		end
	end,

	IsRepeatedPrize = function(prize_list, item)

		local i = 1
		local is_exist = 0
		while (i <= #prize_list) do
			local v = prize_list[i]
			if (v.item_id == item.item_id and v.continue_count == item.continue_count and v.from_index == item.from_index and v.to_index == item.to_index)
			then
				i = i + 1
				is_exist = 1
			elseif (v.item_id == item.item_id and v.continue_count < item.continue_count)
			then
				table.remove(prize_list, i)  
			else
				i = i + 1
			end
		end

		return is_exist
	end,

	--比较普通中奖和wild中奖，以赔率大的作为一条中奖项
	CompareNormalAndWild = function (player, item_id, continue_count, wild_count, prize_list, direction )
		local has_normal_prize = item_id and continue_count and (continue_count >= 3)
		local has_wild_prize = wild_count and (wild_count >= 3)
		local BacktoJurassicPayrateConfig = CommonCal.Calculate.get_config(player, "BacktoJurassicPayrateConfig")

		if has_wild_prize and has_normal_prize then
			local normal_payrate = BacktoJurassicPayrateConfig[item_id].payrate[continue_count - 2]
			local wild_payrate = BacktoJurassicPayrateConfig[Const.Types.Wild].payrate[wild_count - 2]
			if normal_payrate >= wild_payrate then
				local item = {
					item_id = item_id,
					continue_count = continue_count,
					from_index = (direction == Const.PrizeDirection.LEFT) and 1 or (5 - continue_count + 1),
					to_index = (direction == Const.PrizeDirection.LEFT) and continue_count or 5,
				}
				if (Calculate.IsRepeatedPrize(prize_list, item) == 0)
				then
					table.insert(prize_list, item)
				end
			else
				local item = {
					item_id = Const.Types.Wild,
					continue_count = wild_count,
					from_index = (direction == Const.PrizeDirection.LEFT) and 1 or (5 - wild_count + 1),
					to_index = (direction == Const.PrizeDirection.LEFT) and wild_count or 5,
				}
				if (Calculate.IsRepeatedPrize(prize_list, item) == 0)
				then
					table.insert(prize_list, item)
				end
			end
		elseif has_normal_prize then
			local item = {
				item_id = item_id,
				continue_count = continue_count,
				from_index = (direction == Const.PrizeDirection.LEFT) and 1 or (5 - continue_count + 1),
				to_index = (direction == Const.PrizeDirection.LEFT) and continue_count or 5,
			}
			if (Calculate.IsRepeatedPrize(prize_list, item) == 0)
			then
				table.insert(prize_list, item)
			end
			
		elseif has_wild_prize then
			local item = {
				item_id = Const.Types.Wild,
				continue_count = wild_count,
				from_index = (direction == Const.PrizeDirection.LEFT) and 1 or (5 - wild_count + 1),
				to_index = (direction == Const.PrizeDirection.LEFT) and wild_count or 5,
			}
			if (Calculate.IsRepeatedPrize(prize_list, item) == 0)
			then
				table.insert(prize_list, item)
			end
		end
	end,

	GenOneLinePrize = function(player, line_data)
		local prize_list = {}

		local wild_pos_list = Util.GenWildPos(line_data)
		local wild_pos_len = #wild_pos_list
		

		local left_rep_line_data = table.copy(line_data)

		if wild_pos_len > 0 then
            for i = 1, wild_pos_len do
                local rep_value = Util.GenLeftWildReplaceValue(line_data, wild_pos_list[i])
                if rep_value then
                    left_rep_line_data[wild_pos_list[i]] = rep_value
                end
            end
		end

		local left_item_id, left_continue_count = Calculate.GenNormalContinueCount(left_rep_line_data, Const.PrizeDirection.LEFT)
		local left_wild_count = Calculate.GenWildContinueCount(line_data, Const.PrizeDirection.LEFT)
		Calculate.CompareNormalAndWild(player, left_item_id, left_continue_count, left_wild_count, prize_list, Const.PrizeDirection.LEFT)

		local right_item_id, right_continue_count = Calculate.GenNormalContinueCount(left_rep_line_data, Const.PrizeDirection.RIGHT)
		local right_wild_count = Calculate.GenWildContinueCount(line_data, Const.PrizeDirection.RIGHT)
		Calculate.CompareNormalAndWild(player, right_item_id, right_continue_count, right_wild_count, prize_list, Const.PrizeDirection.RIGHT)

		local right_rep_line_data = table.copy(line_data)

		if wild_pos_len > 0 then
            for i = 1, wild_pos_len do
                local rep_value = Util.GenRightWildReplaceValue(line_data, wild_pos_list[i])
                if rep_value then
                    right_rep_line_data[wild_pos_list[i]] = rep_value
                end
            end
		end
		

		local left_item_id, left_continue_count = Calculate.GenNormalContinueCount(right_rep_line_data, Const.PrizeDirection.LEFT)
		local left_wild_count = Calculate.GenWildContinueCount(line_data, Const.PrizeDirection.LEFT)
		Calculate.CompareNormalAndWild(player, left_item_id, left_continue_count, left_wild_count, prize_list, Const.PrizeDirection.LEFT)

		local right_item_id, right_continue_count = Calculate.GenNormalContinueCount(right_rep_line_data, Const.PrizeDirection.RIGHT)
		local right_wild_count = Calculate.GenWildContinueCount(line_data, Const.PrizeDirection.RIGHT)
		Calculate.CompareNormalAndWild(player, right_item_id, right_continue_count, right_wild_count, prize_list, Const.PrizeDirection.RIGHT)


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

	--[[
	HasItem = function(line_data, item_id)
		for k, v in pairs(line_data) do
			if (v == item_id)
			then
				return 1
			end
		end

		return 0
	end,

	Is2Continue = function(line_data, item_id)
		
		for i = 1, 4 do
			if (line_data[i] == item_id and line_data[i + 1] == item_id)
			then
				local line_pos = {}
				table.insert(line_pos, i)
				table.insert(line_pos, i + 1)
				return 1, line_pos
			end
		end

		return 0, nil
	end,

	Is3Continue = function(line_data, item_id)
		for i = 1, 3 do
			if (line_data[i] == item_id and line_data[i + 1] == item_id and line_data[i + 2] == item_id)
			then
				local line_pos = {}
				table.insert(line_pos, i)
				table.insert(line_pos, i + 1)
				table.insert(line_pos, i + 2)
				return 1, line_pos
			end
		end

		return 0, nil
	end,

	Deal3TopContinue = function(result, item_id)
		-------查看第一行是否有连续的大牌
		local top_data = {{}, {}, {}, {}, {}}
		for i = 1, 2 do
			for j = 1, 5 do
				top_data[i][j] = 0
			end
		end
		
		local line_data = {}
		for i= 1， 5 do
			table.insert(line_data, result[1][i])
		end
		local res, line_pos = Calculate.Is3Continue(line_data, item_id)
		if (res == 1)
		then
			---------------下一行是否有item---------------------
			local next_line_data = {}
			for k, v in pairs(line_pos) do
				table.insert(next_line_data, result[2][v])
			end
			local hasItem = Calculate.HasItem(next_line_data, item_id)
			if (hasItem == 0)
			then
				for k, v in pairs(line_pos) do
					top_data[2][v] = item_id
				end
			end
		end

		return top_data
	end

	Deal2TopContinue = function(result, item_id)
		-------查看第一行是否有连续的大牌
		local top_data = {{}, {}, {}, {}, {}}
		for i = 1, 2 do
			for j = 1, 5 do
				top_data[i][j] = 0
			end
		end
		
		local line_data = {}
		for i= 1， 5 do
			table.insert(line_data, result[1][i])
		end
		local res, line_pos = Calculate.Is2Continue(line_data, item_id)
		if (res == 1)
		then
			---------------下一行是否有item---------------------
			local next_line_data = {}
			for k, v in pairs(line_pos) do
				table.insert(next_line_data, result[2][v])
			end
			local hasItem = Calculate.HasItem(next_line_data, item_id)
			if (hasItem == 0)
			then
				for k, v in pairs(line_pos) do
					top_data[2][v] = item_id
				end
			end
		end

		return top_data
	end

	Deal2BottomContinue = function(result, item_id)
		-------查看第一行是否有连续的大牌
		local bottom_data = {{}, {}, {}, {}, {}}
		for i = 1, 2 do
			for j = 1, 5 do
				bottom_data[i][j] = 0
			end
		end
		
		local line_data = {}
		for i= 1， 5 do
			table.insert(line_data, result[3][i])
		end
		local res, line_pos = Calculate.Is2Continue(line_data, item_id)
		if (res == 1)
		then
			---------------上一行是否有item---------------------
			local next_line_data = {}
			for k, v in pairs(line_pos) do
				table.insert(next_line_data, result[2][v])
			end
			local hasItem = Calculate.HasItem(next_line_data, item_id)
			if (hasItem == 0)
			then
				for k, v in pairs(line_pos) do
					top_data[1][v] = item_id
				end
			end
		end

		return top_data
	end
	--]]

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

	GetMaxBetAmount = function(player)
		local BacktoJurassicBetAmountConfig = CommonCal.Calculate.get_config(player, "BacktoJurassicBetAmountConfig")
        local old_req_level = 0
        for k, v in ipairs(BacktoJurassicBetAmountConfig)
        do
            if (player.character.level >= old_req_level and player.character.level < v.required_level)
            then
                return BacktoJurassicBetAmountConfig[k - 1].single_amount
            end
            old_req_level = v.required_level
		end
		
		local max_index = #BacktoJurassicBetAmountConfig
		if (player.character.level >= BacktoJurassicBetAmountConfig[max_index].required_level)
		then
			return BacktoJurassicBetAmountConfig[max_index].single_amount
		end
        return 0
    end,

	GenBacktoJurassicColumn = function(player, config, column)
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

	GetMultiply = function(item_id, free_spin_type)
		local target_item_id = 0
		if (free_spin_type == 2)
		then
			target_item_id = 12
		elseif (free_spin_type == 3)
		then
			target_item_id = 13
		elseif (free_spin_type == 4)
		then
			target_item_id = 14
		elseif (free_spin_type == 5)
		then
			target_item_id = 15
		elseif (free_spin_type == 6)
		then
			target_item_id = 16
		end
		if (item_id == target_item_id)
		then
			if (target_item_id == Const.Types.TyrannosaurusRexHead)
			then
				return 2
			end

			if (target_item_id == Const.Types.TriceratopsHead)
			then
				return 3
			end

			if (target_item_id == Const.Types.StegosaurusHead)
			then
				return 4
			end

			if (target_item_id == Const.Types.BrontosaurusHead)
			then
				return 5
			end

			if (target_item_id == Const.Types.Velociraptor)
			then
				return 6
			end
		end

		return 0
	end,

	UpdateFreeBous = function(backto_jurassic, free_spin_num_array)
		backto_jurassic.free_spin_bouts = 0
		if (free_spin_num_array and #free_spin_num_array > 0) then
			for k, v in pairs(free_spin_num_array)
			do
				backto_jurassic.free_spin_bouts = backto_jurassic.free_spin_bouts + v.free_spin_bouts
			end
		end
	end,

	GenItemResult = function (player, free_spin_type)
		local tran_result = nil
		local result = {}
		local reel_file_name = "BacktoJurassicBaseReelConfig"

		if (player.character.level <= tonumber(ConstValue[8].value))
		then		
			reel_file_name = "BacktoJurassicNewHand1BaseReelConfig"
		elseif (player.character.level <= tonumber(ConstValue[9].value))
		then
			reel_file_name = "BacktoJurassicNewHand2BaseReelConfig"
		elseif (player.character.level <= tonumber(ConstValue[10].value))
		then
			reel_file_name = "BacktoJurassicNewHand3BaseReelConfig"
		end

		if (free_spin_type == 2)
		then
			reel_file_name = "BacktoJurassicFreeSpin2Config"

			if (player.character.level <= tonumber(ConstValue[8].value))
			then		
				reel_file_name = "BacktoJurassicNewHand1FreeSpin2Config"
			elseif (player.character.level <= tonumber(ConstValue[9].value))
			then
				reel_file_name = "BacktoJurassicNewHand2FreeSpin2Config"
			elseif (player.character.level <= tonumber(ConstValue[10].value))
			then
				reel_file_name = "BacktoJurassicNewHand3FreeSpin2Config"
			end
		elseif (free_spin_type == 3)
		then	
			reel_file_name = "BacktoJurassicFreeSpin3Config"

			if (player.character.level <= tonumber(ConstValue[8].value))
			then		
				reel_file_name = "BacktoJurassicNewHand1FreeSpin3Config"
			elseif (player.character.level <= tonumber(ConstValue[9].value))
			then
				reel_file_name = "BacktoJurassicNewHand2FreeSpin3Config"
			elseif (player.character.level <= tonumber(ConstValue[10].value))
			then
				reel_file_name = "BacktoJurassicNewHand3FreeSpin3Config"
			end
		elseif (free_spin_type == 4)
		then
			reel_file_name = "BacktoJurassicFreeSpin4Config"

			if (player.character.level <= tonumber(ConstValue[8].value))
			then		
				reel_file_name = "BacktoJurassicNewHand1FreeSpin4Config"
			elseif (player.character.level <= tonumber(ConstValue[9].value))
			then
				reel_file_name = "BacktoJurassicNewHand2FreeSpin4Config"
			elseif (player.character.level <= tonumber(ConstValue[10].value))
			then
				reel_file_name = "BacktoJurassicNewHand3FreeSpin4Config"
			end
		elseif (free_spin_type == 5)
		then
			reel_file_name = "BacktoJurassicFreeSpin5Config"

			if (player.character.level <= tonumber(ConstValue[8].value))
			then		
				reel_file_name = "BacktoJurassicNewHand1FreeSpin5Config"
			elseif (player.character.level <= tonumber(ConstValue[9].value))
			then
				reel_file_name = "BacktoJurassicNewHand2FreeSpin5Config"
			elseif (player.character.level <= tonumber(ConstValue[10].value))
			then
				reel_file_name = "BacktoJurassicNewHand3FreeSpin5Config"
			end
		elseif (free_spin_type == 6)
		then
			reel_file_name = "BacktoJurassicFreeSpin6Config"

			if (player.character.level <= tonumber(ConstValue[8].value))
			then		
				reel_file_name = "BacktoJurassicNewHand1FreeSpin6Config"
			elseif (player.character.level <= tonumber(ConstValue[9].value))
			then
				reel_file_name = "BacktoJurassicNewHand2FreeSpin6Config"
			elseif (player.character.level <= tonumber(ConstValue[10].value))
			then
				reel_file_name = "BacktoJurassicNewHand3FreeSpin6Config"
			end	
		end
		config = CommonCal.Calculate.get_config(player, reel_file_name)

		local wild_columns = {1, 2, 3, 4, 5}
		for _,v in ipairs(wild_columns) do
			local localResult
			
			localResult = Calculate.GenBacktoJurassicColumn(player, config, v)
			
			result[v] = localResult
		end
		
		tran_result = Calculate.TransResult(result)

		--tran_result = {{6, 7, 1, 5, 10}, {4, 11, 4, 4, 5}, {7, 3, 8, 2, 9}}
		
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
	
	-- --generate总的中奖信息
	GenPrizeInfo = function(player, result, free_spin_type)
		local prize_info = {}
		local total_payrate = 0
		local BacktoJurassicPayrateConfig = CommonCal.Calculate.get_config(player, "BacktoJurassicPayrateConfig")
		for line_index, v in ipairs(Const.Lines) do
			local line_data = {}
			local number = 0
			for i = 1, 5 do
				--v[i]是行,i是列
				table.insert(line_data, result[v[i]][i])
			end
			local one_line_prize = Calculate.GenOneLinePrize(player, line_data)

			for _, item in ipairs(one_line_prize) do

				number = Calculate.GetMultiply(item.item_id, free_spin_type)
				
				local config = BacktoJurassicPayrateConfig[item.item_id]
				if (config ~= nil)
				then
					local payrate = config.payrate[item.continue_count - 2]
					if (payrate > 0)
					then
						item.payrate = payrate
						item.line_index = line_index
						table.insert(prize_info, item)
						if (number > 0)
						then
							total_payrate = total_payrate + item.payrate * number
						else
							total_payrate = total_payrate + item.payrate
						end
					end				
				end

			end
		end
		--LOG(RUN, INFO).Format("[SlotsBacktoJurassic][GenPrizeInfo] total_payrate is: %s", total_payrate)
		return prize_info, total_payrate
	end,
}
