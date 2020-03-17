module("SlotsGameCal", package.seeall)
require "Util/TableExt"
require "Common/CommonCal"
require "Common/DailyMissionsCal"
require "Common/FeverCardCal"
require "Common/FeverQuestCal"
require "Common/LuckyModeFacade"
require "Common/GameConst"
require "Common/ActionType"

Const = {
	PrizeDirection = {
		LEFT = 1,
		RIGHT = 2
	}
}

Util = {
	IsFeatureSpinInFreeSpin = function(player_game_info)
		local info = player_game_info.save_data
		if info then
			local feature_spin_count = info.feature_spin_count
			local feature_spin_type = info.feature_spin_type
			return feature_spin_count and tonumber(feature_spin_count) > 0 and feature_spin_type and feature_spin_type == 1
		end
		return false
	end,
	IsFeatureSpin = function(player_game_info)
		local info = player_game_info.save_data
		if info then
			local feature_spin_count = info.feature_spin_count
			return feature_spin_count and tonumber(feature_spin_count) > 0
		end
		return false
	end,
	IsWild = function(Types, item_id)
		local is_wild = false
		for wild_k, wild_v in pairs(Types.Wilds) do
			if (wild_v == item_id) then
				is_wild = true
				break
			end
		end
		return is_wild
	end,
	GenWildPos = function(line_data, game_room_config, Types, formation_id)
		formation_id = formation_id or "Formation1"
		local formation = _G[game_room_config.game_name .. "FormationArray"][formation_id]

		local pos = {}
		for i = 1, #formation do
			if Util.IsWild(Types, line_data[i]) then
				table.insert(pos, i)
			end
		end
		return pos
	end,
	RandUnrepeated = function(player, tab, count)
		if count > #tab then
			return
		end
		local new_tab = table.copy(tab)
		local result = {}
		for i = 1, count, 1 do
			local rand_index = math.random_ext(player, #new_tab)
			table.insert(result, new_tab[rand_index])
			table.remove(new_tab, rand_index)
		end
		return result
	end,
	--获取左起的普通元素
	--第一个
	GenLeftWildReplaceValue = function(line_data, wild_pos, game_room_config, Types, formation_id)
		formation_id = formation_id or "Formation1"
		local formation = _G[game_room_config.game_name .. "FormationArray"][formation_id]
		if wild_pos == 1 then
			for i = 2, #formation, 1 do
				if not Util.IsWild(Types, line_data[i]) then
					return line_data[i]
				end
			end
		else
			local left_value
			for i = wild_pos - 1, 1, -1 do
				if not Util.IsWild(Types, line_data[i]) then
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
	GenRightWildReplaceValue = function(line_data, wild_pos, game_room_config, Types, formation_id)
		formation_id = formation_id or "Formation1"
		local formation = _G[game_room_config.game_name .. "FormationArray"][formation_id]
		if wild_pos == #formation then
			for i = #formation - 1, 1, -1 do
				if not Util.IsWild(Types, line_data[i]) then
					return line_data[i]
				end
			end
		else
			local right_value
			for i = wild_pos + 1, #formation, 1 do
				if not Util.IsWild(Types, line_data[i]) then
					right_value = line_data[i]
					break
				end
			end
			if right_value then
				return right_value
			end
		end
		return nil
	end
}

--获取一个图标所需要连线的最少数量
local function GetItemContinueRequire(id, Types)
	return (Types.Special_Continue_Count and Types.Special_Continue_Count[id]) and Types.Special_Continue_Count[id] or
		(Types.Normal_Continue_Count or 3)
end

local function GetItemContinuePosition(line, info)
	local pos = {}
	for i = info.from_index, info.to_index do
		local r = line[i]
		table.insert(pos, {row = r, col = i})
	end
	return pos
end

Calculate = {
	--获取Reel配置文件的名称
	GetReelFileName = function(player, game_type, is_free_spin, game_room_config, feature_file)
		--初始化返回值

		--填写返回值
		if (feature_file ~= nil and feature_file ~= "") then --有指定特性
			return feature_file
		end

		--根据是否free_spin进行分别处理
		if (is_free_spin) then
			return game_room_config.game_name .. "FeatureReelConfig"
		else
			return game_room_config.game_name .. "BaseReelConfig"
		end
	end,
	GenNormalContinueCount = function(line_data, direction, game_room_config, Types, formation_id)
		formation_id = formation_id or "Formation1"
		local formation = _G[game_room_config.game_name .. "FormationArray"][formation_id]
		local start, stop, step
		if direction == Const.PrizeDirection.LEFT then
			start = 1
			stop = #formation
			step = 1
		elseif direction == Const.PrizeDirection.RIGHT then
			start = #formation
			stop = 1
			step = -1
		end
		if not start or not stop or not step then
			return
		end
		local item_id
		local continue_count = 0
		for i = start, stop, step do
			if line_data[i] == Types.Scatter then
				break
			end
			if item_id then
				if line_data[i] ~= item_id and not Util.IsWild(Types, line_data[i]) then
					continue_count = math.abs(start - i)
					break
				else
					continue_count = math.abs(start - i) + 1
				end
			else
				if not Util.IsWild(Types, line_data[i]) then
					item_id = line_data[i]
				end
			end
		end
		return item_id, continue_count
	end,
	GenWildContinueCount = function(line_data, direction, game_room_config, Types, formation_id)
		formation_id = formation_id or "Formation1"
		local formation = _G[game_room_config.game_name .. "FormationArray"][formation_id]
		local wild_count = 0
		local wild_id = 0
		local start, stop, step
		if direction == Const.PrizeDirection.LEFT then
			start, stop, step = 1, #formation, 1
		elseif direction == Const.PrizeDirection.RIGHT then
			start, stop, step = #formation, 1, -1
		end
		for i = start, stop, step do
			if Util.IsWild(Types, line_data[i]) then
				wild_count = wild_count + 1
				wild_id = line_data[i]
			else
				break
			end
		end
		return wild_count, wild_id
	end,
	IsRepeatedPrize = function(prize_list, item)
		local i = 1
		local is_exist = 0
		while (i <= #prize_list) do
			local v = prize_list[i]
			if
				(v.item_id == item.item_id and v.continue_count == item.continue_count and v.from_index == item.from_index and
					v.to_index == item.to_index)
			 then
				i = i + 1
				is_exist = 1
			elseif (v.item_id == item.item_id and v.continue_count < item.continue_count) then
				table.remove(prize_list, i)
			else
				i = i + 1
			end
		end

		return is_exist
	end,
	--比较普通中奖和wild中奖，以赔率大的作为一条中奖项
	CompareNormalAndWild = function(
		item_id,
		continue_count,
		wild_id,
		wild_count,
		prize_list,
		direction,
		payrate_config,
		game_room_config,
		Types)
		local normal_item_continue_count = GetItemContinueRequire(item_id, Types)
		local wild_item_continue_count = GetItemContinueRequire(wild_id, Types)

		local has_normal_prize = item_id and continue_count and (continue_count >= normal_item_continue_count)
		local has_wild_prize = wild_count and (wild_count >= wild_item_continue_count)

		if has_wild_prize and has_normal_prize then
			local normal_payrate = payrate_config[item_id].payrate[continue_count - (normal_item_continue_count - 1)]

			-- print("wild_id:"..wild_id.." wild_count is:"..wild_count.." wild_item_continue_count is:"..wild_item_continue_count)
			local wild_payrate = payrate_config[wild_id].payrate[wild_count - (wild_item_continue_count - 1)]
			if normal_payrate >= wild_payrate then
				local item = {
					item_id = item_id,
					continue_count = continue_count,
					--这他妈巨坑,以后如果重右连,就GG
					from_index = (direction == Const.PrizeDirection.LEFT) and 1 or (5 - continue_count + 1),
					to_index = (direction == Const.PrizeDirection.LEFT) and continue_count or 5
				}
				if (Calculate.IsRepeatedPrize(prize_list, item) == 0) then
					table.insert(prize_list, item)
				end
			else
				local item = {
					item_id = wild_id,
					continue_count = wild_count,
					--这他妈巨坑,以后如果重右连,就GG
					from_index = (direction == Const.PrizeDirection.LEFT) and 1 or (5 - wild_count + 1),
					to_index = (direction == Const.PrizeDirection.LEFT) and wild_count or 5
				}
				if (Calculate.IsRepeatedPrize(prize_list, item) == 0) then
					table.insert(prize_list, item)
				end
			end
		elseif has_normal_prize then
			local item = {
				item_id = item_id,
				continue_count = continue_count,
				--这他妈巨坑,以后如果重右连,就GG
				from_index = (direction == Const.PrizeDirection.LEFT) and 1 or (5 - continue_count + 1),
				to_index = (direction == Const.PrizeDirection.LEFT) and continue_count or 5
			}
			if (Calculate.IsRepeatedPrize(prize_list, item) == 0) then
				table.insert(prize_list, item)
			end
		elseif has_wild_prize then
			local item = {
				item_id = wild_id,
				continue_count = wild_count,
				--这他妈巨坑,以后如果重右连,就GG
				from_index = (direction == Const.PrizeDirection.LEFT) and 1 or (5 - wild_count + 1),
				to_index = (direction == Const.PrizeDirection.LEFT) and wild_count or 5
			}
			if (Calculate.IsRepeatedPrize(prize_list, item) == 0) then
				table.insert(prize_list, item)
			end
		end
	end,
	InitPlayerGameInfo = function(session, task, player, game_type)
		local player_game_info = nil

		if (CommonCal.Calculate.is_old_game(game_type)) then
			local player_slots_info = CommonCal.Calculate.get_slots_info(session, task, player, game_type)
			player_game_info = json.decode(player_slots_info.content)
		else
			--这个有可能从缓存里面直接取，不经过json_str
			player_game_info = CommonCal.Calculate.get_game_info(session, task, player, game_type)
		end

		--只有不存在时才从json_str里面取
		if not player_game_info.save_data then
			player_game_info.save_data = json.decode(player_game_info.json_str or "") or {}
		end

		player_game_info.json_str = nil
		return player_game_info
	end,
	GenOneLinePrize = function(line_data, game_room_config, payrate_config, left_or_right, Types, formation_id)
		local prize_list = {}
		local wild_pos_list = Util.GenWildPos(line_data, game_room_config, Types, formation_id)

		local wild_pos_len = #wild_pos_list

		local left_rep_line_data = table.copy(line_data)

		if wild_pos_len > 0 then
			for i = 1, wild_pos_len do
				local rep_value = Util.GenLeftWildReplaceValue(line_data, wild_pos_list[i], game_room_config, Types, formation_id)
				if rep_value then
					left_rep_line_data[wild_pos_list[i]] = rep_value
				end
			end
		end

		if (left_or_right == 1 or left_or_right == 3) then
			local left_item_id, left_continue_count =
				Calculate.GenNormalContinueCount(
				left_rep_line_data,
				Const.PrizeDirection.LEFT,
				game_room_config,
				Types,
				formation_id
			)

			local left_wild_count, wild_id =
				Calculate.GenWildContinueCount(line_data, Const.PrizeDirection.LEFT, game_room_config, Types, formation_id)

			Calculate.CompareNormalAndWild(
				left_item_id,
				left_continue_count,
				wild_id,
				left_wild_count,
				prize_list,
				Const.PrizeDirection.LEFT,
				payrate_config,
				game_room_config,
				Types
			)
		end

		if (left_or_right == 2 or left_or_right == 3) then
			local right_rep_line_data = table.copy(line_data)

			if wild_pos_len > 0 then
				for i = 1, wild_pos_len do
					local rep_value = Util.GenRightWildReplaceValue(line_data, wild_pos_list[i], game_room_config, Types, formation_id)
					if rep_value then
						right_rep_line_data[wild_pos_list[i]] = rep_value
					end
				end
			end

			local right_item_id, right_continue_count =
				Calculate.GenNormalContinueCount(
				right_rep_line_data,
				Const.PrizeDirection.RIGHT,
				game_room_config,
				Types,
				formation_id
			)
			local right_wild_count, wild_id =
				Calculate.GenWildContinueCount(line_data, Const.PrizeDirection.RIGHT, game_room_config, Types, formation_id)
			Calculate.CompareNormalAndWild(
				right_item_id,
				right_continue_count,
				wild_id,
				right_wild_count,
				prize_list,
				Const.PrizeDirection.RIGHT,
				payrate_config,
				game_room_config,
				Types
			)
		end
		return prize_list
	end,
	-- --trans 5*3 matrix to 3*5 matrix
	TransResult = function(result, game_room_config, formation_id)
		formation_id = formation_id or "Formation1"
		local formation = _G[game_room_config.game_name .. "FormationArray"][formation_id]
		local tran_result = {}
		local max_row_num = 0
		for i = 1, #formation, 1 do
			if (max_row_num < formation[i]) then
				max_row_num = formation[i]
			end
		end
		for row = 1, max_row_num do
			tran_result[row] = {}
			for col = 1, #formation do
				tran_result[row][col] = result[col][row]
			end
		end
		return tran_result
	end,
	-- --trans 3*5 matrix to 5*3 matrix
	-- TransResultEx = function(result, game_room_config,formation_id)
	-- 	formation_id = formation_id or 'Formation1'
	-- 	local formation = _G[game_room_config.game_name .. "FormationArray"][formation_id]
	-- 	local tran_result = {}
	-- 	local max_row_num = 0
	-- 	for i = 1, #formation, 1 do
	-- 		if (max_row_num < formation[i]) then
	-- 			max_row_num = formation[i]
	-- 		end
	-- 	end

	-- 	for col = 1, #formation do
	-- 		tran_result[col] = {}
	-- 		for row = 1, max_row_num do
	-- 			tran_result[col][row] = result[row][col]
	-- 		end
	-- 	end

	-- 	return tran_result
	-- end,

	--将3*5的矩阵转换成一维数组,以列优先
	TransResultToList = function(result, game_room_config, formation_id)
		formation_id = formation_id or "Formation1"
		local formation = _G[game_room_config.game_name .. "FormationArray"][formation_id]
		local list = {}
		local max_row_num = 0
		for i = 1, #formation, 1 do
			if (max_row_num < formation[i]) then
				max_row_num = formation[i]
			end
		end
		for i = 1, #formation do
			for j = 1, max_row_num do
				if (result[j][i] and result[j][i] > 0) then
					table.insert(list, result[j][i])
				end
			end
		end
		return list
	end,
	TransResultToCList = function(result, game_room_config, formation_id)
		formation_id = formation_id or "Formation1"
		local formation = _G[game_room_config.game_name .. "FormationArray"][formation_id]
		local list = {}
		local max_row_num = 0
		for i = 1, #formation, 1 do
			if (max_row_num < formation[i]) then
				max_row_num = formation[i]
			end
		end
		for i = 1, #formation do
			local local_info = {}
			for j = 1, max_row_num do
				if (result[j][i] and result[j][i] > 0) then
					table.insert(local_info, result[j][i])
				end
			end
			table.insert(list, local_info)
		end
		return list
	end,
	GetMaxBetAmount = function(player, bet_amount_config)
		local old_req_level = 0
		local old_key = 1
		for k, v in ipairs(bet_amount_config) do
			if (player.character.level >= old_req_level and player.character.level < v.required_level) then
				return bet_amount_config[old_key].single_amount
			end
			old_req_level = v.required_level
			old_key = k
		end

		local max_index = #bet_amount_config
		if (player.character.level >= bet_amount_config[max_index].required_level) then
			return bet_amount_config[max_index].single_amount
		end
		return 0
	end,
	GetPos = function(game_room_config, result, item_id, formation_id)
		formation_id = formation_id or "Formation1"
		local formation = _G[game_room_config.game_name .. "FormationArray"][formation_id]
		local list = {}
		local max_row_num = 0
		for i = 1, #formation, 1 do
			if (max_row_num < formation[i]) then
				max_row_num = formation[i]
			end
		end

		local pos_list = {}
		for i = 1, #formation do
			for j = 1, max_row_num do
				if (result[j][i] == item_id) then
					table.insert(pos_list, {row = j, column = i})
				end
			end
		end

		return pos_list
	end,
	GenColumnWeight = function(player, config, column, game_room_config, formation_id, weight_config)
		local player_id = player.id
		local sequence = config[column].sequence_array
		local sequence_len = #sequence

		local col_weights = {}
		for i = 1, #weight_config do
			table.insert(col_weights, weight_config[i].reel_weight_[column])
		end

		local index = math.rand_weight(player, col_weights)

		if #col_weights == 0 then
			index = math.random_ext(player, 1, sequence_len)
		end

		if (GlobalSlotsTest[player_id] ~= nil) then
			sequence, sequence_len, index = CommonCal.Calculate.GetSequence(player_id, column)
		end

		formation_id = formation_id or "Formation1"

		local formation = _G[game_room_config.game_name .. "FormationArray"][formation_id]

		local number = formation[column]

		local column_value = {}

		for i = 1, number, 1 do
			local pos = (index + i - 2) % sequence_len + 1
			table.insert(column_value, sequence[pos])
		end

		return column_value, index
	end,
	GenColumn = function(player, config, column, game_room_config, formation_id)
		local player_id = player.id
		local sequence = config[column].sequence_array
		local sequence_len = #sequence
		local index = math.random_ext(player, 1, sequence_len)

		if (GlobalSlotsTest[player_id] ~= nil) then
			sequence, sequence_len, index = CommonCal.Calculate.GetSequence(player_id, column)
		end

		formation_id = formation_id or "Formation1"

		local formation = _G[game_room_config.game_name .. "FormationArray"][formation_id]

		local number = formation[column]

		local column_value = {}

		for i = 1, number, 1 do
			local pos = (index + i - 2) % sequence_len + 1
			table.insert(column_value, sequence[pos])
		end

		return column_value, index
	end,
	--这种把冰与火逻辑写到公共类里的行为就该死
	GenResultWithIceAndFireLock = function(
		game_room_config,
		result,
		lock_wild,
		extra_wild,
		extra_daenerys,
		slots_spin_info,
		Types,
		formation_id)
		formation_id = formation_id or "Formation1"
		local formation = _G[game_room_config.game_name .. "FormationArray"][formation_id]

		if (slots_spin_info.pre_action_list == nil) then
			slots_spin_info.pre_action_list = json.encode({})
		end
		local pre_action_list = json.decode(slots_spin_info.pre_action_list)

		local list = {}
		local max_row_num = 0
		for i = 1, #formation, 1 do
			if (max_row_num < formation[i]) then
				max_row_num = formation[i]
			end
		end

		local result_with_lock_item = table.copy(result)

		local daenerysFeatureParm = extra_daenerys
		local lockFeatureParm = {}
		local wildFeatureParm = {col = extra_wild, id = Types.Wild, list = {}}
		for column = 1, #formation do
			--按照所有的Wild赔付
			for row_index = 1, max_row_num do
				--先进行龙妈替换，因为有可能把wild顶
				if (extra_daenerys[column]) then
					result_with_lock_item[row_index][column] = Types.Daenerys1
					lock_wild[row_index][column] = nil
				end
				if (lock_wild[row_index][column]) then
					result_with_lock_item[row_index][column] = Types.Wild
				end
				if (column == extra_wild) then
					table.insert(wildFeatureParm.list, {row_index, column})
				end
			end
			if (lock_wild[1][column]) then
				table.insert(lockFeatureParm, {col = column, state = true})
			end
		end
		--插入Wild特征
		if (wildFeatureParm.col ~= 0) then
			table.insert(
				pre_action_list,
				{
					action_type = ActionType.ActionTypes.DragonFlyWithFire,
					parameter_list = wildFeatureParm
				}
			)
		end
		--插入龙妈特征
		if (#daenerysFeatureParm > 0) then
			table.insert(
				pre_action_list,
				{
					action_type = ActionType.ActionTypes.CombineItem,
					parameter_list = daenerysFeatureParm
				}
			)
		end

		if (#lockFeatureParm > 0) then
			table.insert(
				pre_action_list,
				{
					action_type = ActionType.ActionTypes.SetColLock,
					parameter_list = lockFeatureParm
				}
			)
		end

		slots_spin_info.pre_action_list = json.encode(pre_action_list)
		return result_with_lock_item
	end,
	GenIceAndFireExtResult = function(player, game_room_config, result, wild, lockWildCol, loop_num, Types, formation_id)
		formation_id = formation_id or "Formation1"
		local formation = _G[game_room_config.game_name .. "FormationArray"][formation_id]
		local list = {}
		local max_row_num = 0
		for i = 1, #formation, 1 do
			if (max_row_num < formation[i]) then
				max_row_num = formation[i]
			end
		end

		for column = 1, #formation do
			for row = 1, max_row_num do
				if (wild[row][column]) then
					result[row][column] = Types.Wild
				end
			end
		end

		--哪几列有龙妈
		local new_daenerys = {false, false, false, false, false}
		--那一列有龙
		local new_wild = 0
		local has_daenerys = 0
		local pos_list = {}

		for i = 1, #formation do
			local is_daenerys = false
			if (loop_num > 0) then
				--是否锁住
				is_daenerys =
					(result[1][i] == Types.Daenerys1 or result[2][i] == Types.Daenerys1 or result[3][i] == Types.Daenerys1)
			else
				is_daenerys =
					(result[1][i] == Types.Daenerys1 and result[2][i] == Types.Daenerys1 and result[3][i] == Types.Daenerys1)
			end

			if (is_daenerys) then
				new_daenerys[i] = true
				has_daenerys = 1
			end
		end
		if (has_daenerys > 0) then
			--查找没有锁住的列,将该列变为Wild
			local local_weight_tab = {}
			for i = 1, #formation, 1 do
				--如果之前没有被锁住，并且没有被龙妈占领
				if (not lockWildCol[i] and not new_daenerys[i]) then
					local_weight_tab[i] = 0.1
				end
			end
			local len = 0
			for k, v in pairs(local_weight_tab) do
				len = len + 1
			end

			if (len > 0) then
				new_wild = math.rand_weight(player, local_weight_tab)
				lockWildCol[new_wild] = true
				for row = 1, max_row_num do
					wild[row][new_wild] = true
				end
			end
		end
		return new_wild, new_daenerys, has_daenerys
	end,
	ReplaceIceAndFireWildItem = function(game_room_config, result, slots_spin_info, Types, formation_id)
		formation_id = formation_id or "Formation1"
		local formation = _G[game_room_config.game_name .. "FormationArray"][formation_id]
		local list = {}
		local max_row_num = 0
		for i = 1, #formation, 1 do
			if (max_row_num < formation[i]) then
				max_row_num = formation[i]
			end
		end

		local feature_type = 0
		local night_king_row = 0
		local night_king_column = 0
		for i = 1, max_row_num do
			if result[i][1] == Types.Daenerys2 then
				feature_type = Types.Daenerys2
			elseif result[i][1] == Types.NightKing then
				feature_type = Types.NightKing
				night_king_row = i
				night_king_column = 1
			end
		end

		if (feature_type == Types.Daenerys2) then
			local pos_list = {}

			for i = 1, max_row_num do
				for j = 1, #formation do
					if result[i][j] == Types.WhiteWalkers or result[i][j] == Types.Ghouls or result[i][j] == Types.FrostWyrm then
						result[i][j] = Types.Wild

						table.insert(pos_list, {row = i, column = j})
					end
				end
			end

			if (slots_spin_info ~= nil and #pos_list > 0) then
				if (slots_spin_info.pre_action_list == nil) then
					slots_spin_info.pre_action_list = "[]"
				end
				local pre_action_list = json.decode(slots_spin_info.pre_action_list)

				local pre_action = {}
				pre_action.action_type = ActionType.ActionTypes.DragonFly
				pre_action.source_pos = {row = pos_list[1].row, column = pos_list[1].column}
				pre_action.des_pos = {row = pos_list[1].row, column = pos_list[1].column}
				pre_action.item_id = Types.Wild
				local parameter = {}
				parameter.type = 2
				parameter.value = json.encode(pos_list)
				local parameter_list = {}
				table.insert(parameter_list, parameter)
				pre_action.parameter_list = parameter_list

				table.insert(pre_action_list, pre_action)

				slots_spin_info.pre_action_list = json.encode(pre_action_list)
			end
		end

		if (feature_type == Types.NightKing) then
			local pos_list = {}
			for i = 1, max_row_num do
				for j = 1, #formation do
					if result[i][j] == Types.Snow or result[i][j] == Types.NightWatchPeople or result[i][j] == Types.BlackDragons then
						result[i][j] = Types.IceWild

						table.insert(pos_list, {row = i, column = j})
					end
				end
			end
			if (slots_spin_info ~= nil and #pos_list > 0) then
				if (slots_spin_info.pre_action_list == nil) then
					slots_spin_info.pre_action_list = "[]"
				end

				local pre_action_list = json.decode(slots_spin_info.pre_action_list)

				local pre_action = {}
				pre_action.action_type = ActionType.ActionTypes.NightKing
				pre_action.source_pos = {row = night_king_row, column = night_king_column}
				pre_action.des_pos = {row = night_king_row, column = night_king_column}
				pre_action.item_id = Types.IceWild
				local parameter = {}
				parameter.type = 2
				parameter.value = json.encode(pos_list)
				local parameter_list = {}
				table.insert(parameter_list, parameter)
				pre_action.parameter_list = parameter_list

				table.insert(pre_action_list, pre_action)

				slots_spin_info.pre_action_list = json.encode(pre_action_list)
			end
		end
		return feature_type
	end,
	GenItemResultAli = function(
		player,
		game_type,
		is_free_spin,
		game_room_config,
		feature_file,
		formation_id,
		extern_param,
		reel_file_name,
		result_row,
		wild,
		types)
		--返回值初始化

		local tran_result = nil
		formation_id = formation_id or "Formation1"
		--获取基本的配置
		if (reel_file_name == nil) then
			reel_file_name = Calculate.GetReelFileName(player, game_type, is_free_spin, game_room_config, feature_file)
		end

		local config = CommonCal.Calculate.get_config(player, reel_file_name)

		local formation = _G[game_room_config.game_name .. "FormationArray"][formation_id]

		--生成结果
		local new_wild = {}
		for v = 1, #formation do
			if (wild[v][1] ~= types.Wild) then
				result_row[v] = Calculate.GenColumn(player, config, v, game_room_config, formation_id)
				local is_wild = (result_row[v][1] == types.Wild or result_row[v][2] == types.Wild or result_row[v][3] == types.Wild)
				if (is_wild) then
					-- wild[v][1] = Const.Types.Wild
					-- wild[v][2] = Const.Types.Wild
					-- wild[v][3] = Const.Types.Wild
					hasWild = 1
					for row = 1, 3, 1 do
						wild[v][row] = types.Wild
						table.insert(new_wild, {col = v, row = row})
					end
				end
			end
		end
		-- print("result_row2 is:"..json.encode(result_row))
		tran_result = Calculate.TransResult(result_row, game_room_config, formation_id)
		-- print("tran_result3 is:"..json.encode(tran_result))
		--返回
		return tran_result, reel_file_name, new_wild
	end,
	-- 支持string、table配置
	GetReelWeightConfigs = function(player, config_table, is_free_spin)
		local reel_file = nil
		local weight_file = nil

		local function get(config)
			if not config then
				return nil
			end
			if type(config) == "string" then
				return config
			end

			local configs = config
			local weights = {}
			for i = 1, #configs do
				table.insert(weights, configs[i].weight)
			end
			return configs[math.rand_weight(player, weights)].config
		end

		if is_free_spin then
			reel_file = get(config_table.feature_reel_config)
			weight_file = get(config_table.feature_reel_weight_config)
		else
			reel_file = get(config_table.base_reel_config)
			weight_file = get(config_table.base_reel_weight_config)
		end
		return reel_file, weight_file
	end,
	GenItemResultWithWeight = function(
		player,
		game_type,
		is_free_spin,
		game_room_config,
		reel_file_name,
		weight_file_name,
		formation_name)
		--返回值初始化
		local tran_result = nil

		--获取基本的配置
		if (reel_file_name == nil) then
			reel_file_name = Calculate.GetReelFileName(player, game_type, is_free_spin, game_room_config)
		end

		formation_name = formation_name or "Formation1"

		local config = CommonCal.Calculate.get_config(player, reel_file_name)
		local formation = _G[game_room_config.game_name .. "FormationArray"][formation_name]

		local weight_config = nil

		if weight_file_name then
			weight_config = CommonCal.Calculate.get_config(player, weight_file_name)
		end

		--生成结果
		local result = {}
		local reel_index_list = {}
		for v = 1, #formation do
			result[v], reel_index_list[v] =
				Calculate.GenColumnWeight(player, config, v, game_room_config, formation_name, weight_config or {})
		end

		tran_result = Calculate.TransResult(result, game_room_config, formation_name)
		--返回
		return tran_result, reel_file_name, reel_index_list
	end,
	GenItemResult = function(
		player,
		game_type,
		is_free_spin,
		game_room_config,
		feature_file,
		formation_name,
		extern_param,
		reel_file_name)
		--返回值初始化
		local tran_result = nil
		formation_name = formation_name or "Formation1"
		--获取基本的配置
		if (reel_file_name == nil) then
			reel_file_name = Calculate.GetReelFileName(player, game_type, is_free_spin, game_room_config, feature_file)
		end

		local config = CommonCal.Calculate.get_config(player, reel_file_name)

		local formation = _G[game_room_config.game_name .. "FormationArray"][formation_name]

		--生成结果
		local result = {}
		for v = 1, #formation do
			result[v] = Calculate.GenColumn(player, config, v, game_room_config, formation_name)
		end
		tran_result = Calculate.TransResult(result, game_room_config, formation_name)
		--特殊处理
		if (GameType.AllTypes.Ice777 == game_type and feature_file ~= nil and feature_file ~= "") then
			tran_result = {
				{2, 7, 3},
				{9, 9, 9},
				{1, 1, 1},
				{9, 9, 9},
				{4, 3, 2}
			}
		end
		--返回
		return tran_result, reel_file_name
	end,
	--生成多个Reel结果
	GenItemResultMul = function(
		player,
		game_type,
		is_free_spin,
		game_room_config,
		feature_file,
		reel_formation_name,
		reel_num)
		--返回值初始化
		local tran_result_arr = {}

		--获取基本的配置
		local reel_file_name = Calculate.GetReelFileName(player, game_type, is_free_spin, game_room_config, feature_file)
		local config = CommonCal.Calculate.get_config(player, reel_file_name)
		local formation = _G[game_room_config.game_name .. "FormationArray"][reel_formation_name]
		--生成结果
		for reel_idx = 1, reel_num, 1 do --多个reel结果
			local result = {}
			for v = 1, #formation, 1 do
				result[v] = Calculate.GenColumn(player, config, v, game_room_config, reel_formation_name)
			end
			tran_result_arr[reel_idx] = Calculate.TransResult(result, game_room_config, reel_formation_name)
		end

		--返回
		return tran_result_arr, reel_file_name
	end,
	--这三个方法好像没人调用
	ReplaceBigItem = function(game_room_config, loop_num, result, Types, formation_id)
		formation_id = formation or "Formation1"
		local formation = _G[game_room_config.game_name .. "FormationArray"][formation_id]
		if (loop_num == 0) then
			local res_result = {{}, {}, {}, {}, {}}
			for i = 1, #formation, 1 do
				local tempResult = table.DeepCopy(result[i])
				Calculate.ReplaceSubBigItem(game_room_config, tempResult, Types)
				res_result[i] = tempResult
			end
			return Calculate.TransResult(res_result, game_room_config, formation_id)
		else
			return Calculate.TransResult(result, game_room_config, formation_id)
		end
	end,
	ReplaceSubBigItem = function(game_room_config, resultCol, Types, formation_id)
		formation_id = formation or "Formation1"
		local formation = _G[game_room_config.game_name .. "FormationArray"][formation_id]

		local max_row_num = 0
		for i = 1, #formation, 1 do
			if (max_row_num < formation[i]) then
				max_row_num = formation[i]
			end
		end

		local Daenerys_3_Array = {}
		for row_index = 1, max_row_num do
			Daenerys_3_Array[row_index] = Types["Daenerys_3_" .. row_index]
		end
		--Daenerys_3_Array[1] = Const.Types.Daenerys_3_1
		--Daenerys_3_Array[2] = Const.Types.Daenerys_3_2
		--Daenerys_3_Array[3] = Const.Types.Daenerys_3_3

		Calculate.ReplaceBigItemOneColumn(game_room_config, resultCol, Types.Daenerys, nil, Daenerys_3_Array, nil)
	end,
	ReplaceBigItemOneColumn = function(
		game_room_config,
		resultCol,
		Item_Type,
		Item_Type_2_Array,
		Item_Type_3_Array,
		Item_Type_4_Array,
		formation_id)
		formation_id = formation_id or "Formation1"
		local formation = _G[game_room_config.game_name .. "FormationArray"][formation_id]

		local max_row_num = 0
		for i = 1, #formation, 1 do
			if (max_row_num < formation[i]) then
				max_row_num = formation[i]
			end
		end

		local Count = 0
		local Start_Pos = 0
		for j = 1, max_row_num do
			--Zeus是否是连续
			if (resultCol[j] == Item_Type) then
				if (Count == 0) then
					Start_Pos = j
				end
				Count = Count + 1
			else
				Count = 0
			end
			if (Count >= 2) then
				for pos = Start_Pos, Start_Pos + Count - 1 do
					if (Count == 3) then
						resultCol[pos] = Item_Type_3_Array[pos - Start_Pos + 1]
					end
				end
			end
		end
	end,
	--这三个方法好像没人调用

	GetColNum = function(game_room_config, formation_name)
		local formation = _G[game_room_config.game_name .. "FormationArray"][formation_name]
		return #formation
	end,
	--这个方法可以(最好)被 Calculate.GetItemPosition 取代
	GenFreeSpinCount = function(data, game_room_config, item_id, count, formation_name)
		local scatter_count = 0
		formation_name = formation_name or "Formation1"
		count = count or 10
		local formation = _G[game_room_config.game_name .. "FormationArray"][formation_name]

		local max_row_num = 0
		for i = 1, #formation, 1 do
			if (max_row_num < formation[i]) then
				max_row_num = formation[i]
			end
		end

		for i = 1, max_row_num do
			for j = 1, #formation do
				if data[i][j] == item_id then
					scatter_count = scatter_count + 1
				end
			end
		end

		if (scatter_count >= 3) then
			return count, item_id
		end
		return 0, 0
	end,
	----从左至右，item_id出现的个数
	GetItemCount = function(result, game_room_config, item_id, cols, formation_id)
		local continue_count = 0
		formation_id = formation_id or "Formation1"
		local formation = _G[game_room_config.game_name .. "FormationArray"][formation_id]

		local max_row_num = 0
		for i = 1, #formation, 1 do
			if (max_row_num < formation[i]) then
				max_row_num = formation[i]
			end
		end

		for k, col in ipairs(cols) do
			local item_count = 0
			for row = 1, max_row_num do
				if (result[row][col] == item_id) then
					item_count = item_count + 1
				end
			end
			if (item_count > 0) then
				continue_count = continue_count + 1
			end
		end

		return continue_count
	end,
	--获得某种item此次转动结果出现的位置
	GetItemPosition = function(data, game_room_config, item_id, formation_id)
		local pos_list = {}
		if (data == nil) then
			return pos_list
		end
		formation_id = formation_id or "Formation1"
		local formation = _G[game_room_config.game_name .. "FormationArray"][formation_id]

		for j = 1, #formation do
			for i = 1, formation[j] do
				if data[i][j] == item_id then
					local pos = {}
					pos.row = i
					pos.col = j
					table.insert(pos_list, pos)
				end
			end
		end

		return pos_list
	end,
	--获得某种item此次转动结果出现的位置
	GetItemPositionAli = function(data, game_room_config, item_id, formation_id)
		local pos_list = {}
		if (data == nil) then
			return pos_list
		end
		formation_id = formation_id or "Formation1"
		local formation = _G[game_room_config.game_name .. "FormationArray"][formation_id]

		for j = 1, #formation do
			for i = 1, formation[j] do
				if data[j][i] == item_id then
					local pos = {}
					pos.row = i
					pos.col = j
					table.insert(pos_list, pos)
				end
			end
		end

		return pos_list
	end,
	--将阵型中出现的客户ID变为大图标的ID
	ReplaceSID = function(final_result, item_id)
		local row_len = #final_result --几行
		local col_len = #final_result[1] --几列
		local replace_start_num = 100

		for j = 1, col_len do
			for i = 1, row_len do
				if (final_result[i][j] >= replace_start_num) then
					final_result[i][j] = item_id
				end
			end
		end
	end,
	ObtainPiggyBankAward = function(player, total_bet_amount)
		for index = #PiggyBankConfig, 1, -1 do
			local piggy_bank_info = PiggyBankConfig[index]
			if (piggy_bank_info.maxbuytime <= (player.character.piggy_bank_pay_count + 1)) then
				local addratio = piggy_bank_info.addratio
				local award_chip = total_bet_amount * addratio
				player.character.piggy_bank_chip = player.character.piggy_bank_chip + award_chip
				LOG(RUN, INFO).Format(
					"[Command][ObtainPiggyBankAward]1 get goods, player_id:%s, piggy_bank_info id is:%s, piggy_bank_chip:%s",
					player.id,
					key,
					player.character.piggy_bank_chip
				)
				if
					(player.character.piggy_bank_chip >
						CommonCal.Calculate.CalcBaseWithLevel(piggy_bank_info.maxamout, player.character.level))
				 then
					player.character.piggy_bank_chip =
						CommonCal.Calculate.CalcBaseWithLevel(piggy_bank_info.maxamout, player.character.level)
				end
				LOG(RUN, INFO).Format(
					"[Command][ObtainPiggyBankAward]2 get goods, player_id:%s, piggy_bank_chip:%s",
					player.id,
					player.character.piggy_bank_chip
				)
				break
			end
		end
	end,
	--将大图标转换成客户端需要的ID
	ReplaceBlock = function(origin_result, block_type)
		local result_row = table.DeepCopy(origin_result)
		local row_len = #result_row --几行
		local col_len = #result_row[1] --几列
		local replace_start_num = 100
		local block_type_table = {}
		if type(block_type) ~= "table" then
			table.insert(block_type_table, block_type)
		else
			block_type_table = block_type
		end
		for k, v in ipairs(block_type_table) do --要替换对象
			for j = 1, col_len do --一列列排查
				local counter = 0
				if (result_row[1][j] == v) then --是否从上开始
					if (result_row[row_len][j] ~= v) then --底部不为对应对象
						for i = 2, row_len do --逆向排查最后一个一定是尾部
							if (result_row[row_len + 1 - i][j] == v) then
								counter = counter + 1
								result_row[row_len + 1 - i][j] = replace_start_num * k + row_len + 1 - counter
							end
						end
					else
						local break_row = row_len + 1 --中断的行
						for i = 2, row_len - 1 do
							if (result_row[i][j] ~= v) then
								break_row = i
								break
							end
						end
						for i = 1, break_row - 1 do
							result_row[i][j] = replace_start_num * k + row_len + 1 - break_row + i
						end
						if (break_row ~= row_len + 1) then
							for i = break_row + 1, row_len do
								if (result_row[i][j] == v) then
									counter = counter + 1
									result_row[i][j] = replace_start_num * k + counter
								end
							end
						end
					end
				else --不是从上开始顺着排查第一个一定是头部
					for i = 2, row_len do
						if (result_row[i][j] == v) then
							counter = counter + 1
							result_row[i][j] = replace_start_num * k + counter
						end
					end
				end
			end
		end
		return result_row
	end,
	--generate总的中奖信息
	GenPrizeInfoAli = function(
		result,
		game_room_config,
		payrate_config,
		left_or_right,
		Types,
		formation_id,
		line_id,
		bet_ratio,
		is_free_spin)
		--将连线结果放入all_prize_list)
		formation_id = formation_id or "Formation1"
		line_id = line_id or "Lines1"
		bet_ratio = bet_ratio or 1
		local formation = _G[game_room_config.game_name .. "FormationArray"][formation_id]
		local Lines = _G[game_room_config.game_name .. "LineArray"][line_id]
		local prize_info = {}
		local total_payrate = 0

		for line_index, v in ipairs(Lines) do
			local line_data = {}
			local number = 0
			for i = 1, #formation do
				if (v[i]) then
					--v[i]是行,i是列
					table.insert(line_data, result[v[i]][i])
				end
			end
			local one_line_prize =
				Calculate.GenOneLinePrize(line_data, game_room_config, payrate_config, left_or_right, Types, formation_id)
			for _, item in ipairs(one_line_prize) do
				local config = payrate_config[item.item_id]
				if (config ~= nil) then
					local pay_count = GetItemContinueRequire(item.item_id, Types)
					local payrate = config.payrate[item.continue_count - (pay_count - 1)]

					if (payrate > 0) then
						if (is_free_spin) then
							local wild_count = 0
							for index = 1, item.continue_count do
								if (result[v[index]][index] == Types.Wild) then
									wild_count = wild_count + 1
								end
							end
							if (wild_count > 0) then
								payrate = payrate * 2
							end
						end
						item.payrate = payrate * bet_ratio * 1000
						item.line_index = line_index
						table.insert(prize_info, item)

						total_payrate = total_payrate + payrate
					end
				end
			end
		end
		total_payrate = total_payrate * bet_ratio
		--LOG(RUN, INFO).Format("[SlotsGame][Start] prize_info is:%s, total_payrate is: %s", Table2Str(prize_info), total_payrate)
		return prize_info, total_payrate
	end,
	--generate总的中奖信息
	GenPrizeInfo = function(
		result,
		game_room_config,
		payrate_config,
		left_or_right,
		Types,
		formation_id,
		line_id,
		bet_ratio)
		--将连线结果放入all_prize_list)
		formation_id = formation_id or "Formation1"
		line_id = line_id or "Lines1"
		bet_ratio = bet_ratio or 1
		local formation = _G[game_room_config.game_name .. "FormationArray"][formation_id]
		local Lines = _G[game_room_config.game_name .. "LineArray"][line_id]
		local prize_info = {}
		local total_payrate = 0

		for line_index, v in ipairs(Lines) do
			local line_data = {}
			local number = 0
			for i = 1, #formation do
				if (v[i]) then
					--v[i]是行,i是列
					table.insert(line_data, result[v[i]][i])
				end
			end
			local one_line_prize =
				Calculate.GenOneLinePrize(line_data, game_room_config, payrate_config, left_or_right, Types, formation_id)
			for _, item in ipairs(one_line_prize) do
				local config = payrate_config[item.item_id]
				if (config ~= nil) then
					local pay_count = GetItemContinueRequire(item.item_id, Types)
					local payrate = config.payrate[item.continue_count - (pay_count - 1)]
					if (payrate > 0) then
						item.payrate = payrate * bet_ratio * 1000
						item.line_index = line_index
						table.insert(prize_info, item)

						total_payrate = total_payrate + payrate
					end
				end
			end
		end
		total_payrate = total_payrate * bet_ratio
		--LOG(RUN, INFO).Format("[SlotsGame][Start] prize_info is:%s, total_payrate is: %s", Table2Str(prize_info), total_payrate)
		return prize_info, total_payrate
	end,
	ConvertPrizeItems = function(
		player,
		result,
		game_room_config,
		payrate_config,
		left_or_right,
		Types,
		options,
		prize_items,
		pos_list)
		local spin_type = options.spin_type
		local formation_id = options.formation_id or "Formation1"
		local line_id = options.line_id or "Lines1"
		local bet_ratio = options.bet_ratio or 1
		local formation = _G[game_room_config.game_name .. "FormationArray"][formation_id]
		local Lines = _G[game_room_config.game_name .. "LineArray"][line_id]
		local prize_info = {}
		local total_payrate = 0

		local new_prize_items = {}

		for i = 1, #prize_items do
			local v = prize_items[i]

			local item = {
				payrate = v.payrate,
				line_index = v.line_index,
				item_pos_arr = v.item_pos_arr
			}

			table.insert(new_prize_items, new_item)
		end

		return new_prize_items
	end,
	-- 新的生成中奖信息
	GenPrizeItems = function(player, result, game_room_config, payrate_config, left_or_right, Types, options)
		local spin_type = options.spin_type
		local formation_id = options.formation_id or "Formation1"
		local line_id = options.line_id or "Lines1"
		local bet_ratio = options.bet_ratio or 1
		local formation = _G[game_room_config.game_name .. "FormationArray"][formation_id]
		local Lines = _G[game_room_config.game_name .. "LineArray"][line_id]
		local prize_info = {}
		local total_payrate = 0

		-- 遍历所有的线，看是否中奖，中奖就加赔率
		for line_index, v in ipairs(Lines) do
			local line_data = {}
			local number = 0
			for i = 1, #formation do
				if v[i] then
					table.insert(line_data, result[v[i]][i])
				end
			end

			local one_line_prize =
				Calculate.GenOneLinePrize(line_data, game_room_config, payrate_config, left_or_right, Types, formation_id)

			for _, item in ipairs(one_line_prize) do
				local is_jackpot_five = false

				if item.continue_count == 5 and item.item_id == Types.Jackpot then
					-- is_jackpot_five = true
					for i = 1, #line_data do
						if line_data[i] == Types.Wild then
							is_jackpot_five = false
							break
						end
					end
				end

				local config = payrate_config[item.item_id]
				if config ~= nil and not is_jackpot_five then
					local pay_count = GetItemContinueRequire(item.item_id, Types)
					local payrate = config.payrate[item.continue_count - (pay_count - 1)]
					if payrate > 0 then
						local new_item = {
							item_pos_arr = GetItemContinuePosition(v, item),
							payrate = payrate,
							line_index = line_index
						}
						table.insert(prize_info, new_item)
						total_payrate = total_payrate + payrate
					end
				end
			end
		end

		-- 处理scatter的赔率
		local scatter_positions = Calculate.GetItemPosition(result, game_room_config, Types.Scatter)
		local scatter_config = CommonCal.Calculate.get_config(player, game_room_config.game_name .. "ScatterConfig")
		local scatter_count = #scatter_positions

		if scatter_count and scatter_count > 0 and scatter_config then
			local v = scatter_config[scatter_count]
			if v and v.payrate[spin_type] and v.payrate[spin_type] > 0 then
				local payrate = v.payrate[spin_type]
				total_payrate = total_payrate + payrate
				local item = {
					line_index = 0,
					payrate = payrate,
					item_pos_arr = scatter_positions
				}
				table.insert(prize_info, item)
			end
		end

		total_payrate = total_payrate * bet_ratio
		return prize_info, total_payrate
	end,
	GenPrizeInfoNew = function(
		result,
		game_room_config,
		payrate_config,
		left_or_right,
		gameTypes,
		minContinue,
		lines,
		formation_id)
		formation_id = formation_id or "Formation1"
		local formation = _G[game_room_config.game_name .. "FormationArray"][formation_id]
		local Lines = lines
		local prize_info = {}
		local total_payrate = 0

		for line_index, v in ipairs(Lines) do
			local line_data = {}
			local number = 0
			for i = 1, #formation do
				--v[i]是行,i是列
				table.insert(line_data, result[v[i]][i])
			end
			local one_line_prize =
				Calculate.GenOneLinePrizeNew(
				line_data,
				game_room_config,
				payrate_config,
				left_or_right,
				gameTypes,
				minContinue,
				formation_id
			)

			for _, item in ipairs(one_line_prize) do
				local config = payrate_config[item.item_id]
				if (config ~= nil) then
					local payrate = config.payrate[item.continue_count - minContinue + 1]
					if (payrate > 0) then
						--矮人玩法特殊处理
						--判断是几连,和左右,矮人只有左起
						if (item.payrate == 2) then
							item.payrate = payrate * 2
						else
							item.payrate = payrate
						end
						-- item.payrate = payrate
						item.line_index = line_index
						table.insert(prize_info, item)

						-- for k, v in ipairs(line_data) do
						-- 	if(k <= item.continue_count and gameTypes.WildList[v])
						-- 	then
						-- 		item.payrate = item.payrate * 2
						-- 		break
						-- 	end
						-- end
						total_payrate = total_payrate + item.payrate
					end
				end
			end
		end
		return prize_info, total_payrate
	end,
	GenOneLinePrizeNew = function(
		line_data,
		game_room_config,
		payrate_config,
		left_or_right,
		gameTypes,
		minContinue,
		formation_id)
		local prize_list = {}

		local wild_pos_list = Util.GenWildPos(line_data, game_room_config, gameTypes, formation_id)
		local wild_pos_len = #wild_pos_list

		local left_rep_line_data = table.copy(line_data)

		--左连的元素里面是否有wild
		if wild_pos_len > 0 then
			for i = 1, wild_pos_len do
				local rep_value =
					Util.GenLeftWildReplaceValue(line_data, wild_pos_list[i], game_room_config, gameTypes, formation_id)
				if rep_value then
					left_rep_line_data[wild_pos_list[i]] = rep_value
				end
			end
		end

		if (left_or_right == 1 or left_or_right == 3) then
			local left_item_id, left_continue_count =
				Calculate.GenNormalContinueCount(
				left_rep_line_data,
				Const.PrizeDirection.LEFT,
				game_room_config,
				gameTypes,
				formation_id
			)
			local left_wild_count, wild_id =
				Calculate.GenWildContinueCount(line_data, Const.PrizeDirection.LEFT, game_room_config, gameTypes, formation_id)
			Calculate.CompareNormalAndWildNew(
				left_item_id,
				left_continue_count,
				wild_id,
				left_wild_count,
				prize_list,
				Const.PrizeDirection.LEFT,
				payrate_config,
				game_room_config,
				gameTypes,
				minContinue,
				wild_pos_list
			)
		end

		if (left_or_right == 2 or left_or_right == 3) then
			local right_rep_line_data = table.copy(line_data)

			if wild_pos_len > 0 then
				for i = 1, wild_pos_len do
					local rep_value =
						Util.GenRightWildReplaceValue(line_data, wild_pos_list[i], game_room_config, gameTypes, formation_id)
					if rep_value then
						right_rep_line_data[wild_pos_list[i]] = rep_value
					end
				end
			end

			local right_item_id, right_continue_count =
				Calculate.GenNormalContinueCount(
				right_rep_line_data,
				Const.PrizeDirection.RIGHT,
				game_room_config,
				gameTypes,
				formation_id
			)
			local right_wild_count, wild_id =
				Calculate.GenWildContinueCount(line_data, Const.PrizeDirection.RIGHT, game_room_config, gameTypes, formation_id)
			Calculate.CompareNormalAndWildNew(
				right_item_id,
				right_continue_count,
				wild_id,
				right_wild_count,
				prize_list,
				Const.PrizeDirection.RIGHT,
				payrate_config,
				game_room_config,
				gameTypes,
				minContinue,
				wild_pos_list
			)
		end
		return prize_list
	end,
	--这种把小绿人的逻辑写到公共类里的都该死

	--比较普通中奖和wild中奖，以赔率大的作为一条中奖项
	CompareNormalAndWildNew = function(
		item_id,
		continue_count,
		wild_id,
		wild_count,
		prize_list,
		direction,
		payrate_config,
		game_room_config,
		gameTypes,
		minContinue,
		wild_pos_list)
		local has_normal_prize = item_id and continue_count and (continue_count >= minContinue)
		local has_wild_prize = wild_count and (wild_count >= minContinue)

		if has_wild_prize and has_normal_prize then
			local normal_payrate = payrate_config[item_id].payrate[continue_count - minContinue + 1]
			--普通的连线中有wild则倍率*2
			--因为这个玩法只有左连,所以判断wild的index是否都不大于continue_count
			local is_have_wild = false
			for k, wild_index in pairs(wild_pos_list) do
				if (wild_index <= continue_count) then
					normal_payrate = normal_payrate * 2
					is_have_wild = true
					break
				end
			end
			local wild_payrate = payrate_config[gameTypes.Wild].payrate[wild_count - minContinue + 1]
			if normal_payrate >= wild_payrate then
				local item = {
					item_id = item_id,
					continue_count = continue_count,
					from_index = (direction == Const.PrizeDirection.LEFT) and 1 or (5 - continue_count + 1),
					to_index = (direction == Const.PrizeDirection.LEFT) and continue_count or 5
				}
				--这里把有wild连线的payrate记录为2
				if (is_have_wild) then
					item.payrate = 2
				end

				if (Calculate.IsRepeatedPrize(prize_list, item) == 0) then
					table.insert(prize_list, item)
				end
			else
				local item = {
					item_id = wild_id,
					continue_count = wild_count,
					from_index = (direction == Const.PrizeDirection.LEFT) and 1 or (5 - wild_count + 1),
					to_index = (direction == Const.PrizeDirection.LEFT) and wild_count or 5
				}
				if (Calculate.IsRepeatedPrize(prize_list, item) == 0) then
					table.insert(prize_list, item)
				end
			end
		elseif has_normal_prize then
			--普通的连线中有wild则倍率*2
			--因为这个玩法只有左连,所以判断wild的index是否都不大于continue_count
			local is_have_wild = false
			for k, wild_index in pairs(wild_pos_list) do
				if (wild_index <= continue_count) then
					is_have_wild = true
					break
				end
			end

			local item = {
				item_id = item_id,
				continue_count = continue_count,
				from_index = (direction == Const.PrizeDirection.LEFT) and 1 or (5 - continue_count + 1),
				to_index = (direction == Const.PrizeDirection.LEFT) and continue_count or 5
			}
			--这里把有wild连线的payrate记录为2
			if (is_have_wild) then
				item.payrate = 2
			end

			if (Calculate.IsRepeatedPrize(prize_list, item) == 0) then
				table.insert(prize_list, item)
			end
		elseif has_wild_prize then
			local item = {
				item_id = wild_id,
				continue_count = wild_count,
				from_index = (direction == Const.PrizeDirection.LEFT) and 1 or (5 - wild_count + 1),
				to_index = (direction == Const.PrizeDirection.LEFT) and wild_count or 5
			}
			if (Calculate.IsRepeatedPrize(prize_list, item) == 0) then
				table.insert(prize_list, item)
			end
		end
	end,
	GetWildsOnLine = function(
		origin_result,
		game_room_config,
		payrate_config,
		left_or_right,
		gameTypes,
		formation_id,
		line_id)
		formation_id = formation_id or "Formation1"
		line_id = line_id or "Lines1"
		local formation = _G[game_room_config.game_name .. "FormationArray"][formation_id]
		local Lines = _G[game_room_config.game_name .. "LineArray"][line_id]
		local wildsResult = {}
		for line_index, v in ipairs(Lines) do
			local line_data = {}
			local wilds = {}
			for i = 1, #formation do
				--v[i]是行,i是列
				local rowIndex = v[i]
				local colIndex = i
				local itemId = origin_result[rowIndex][colIndex]
				table.insert(line_data, itemId)
				if Util.IsWild(gameTypes, itemId) then
					table.insert(wilds, {row = rowIndex, col = colIndex})
				end
			end
			if #wilds > 0 then
				local one_line_prize =
					Calculate.GenOneLinePrize(line_data, game_room_config, payrate_config, left_or_right, gameTypes, formation_id)
				for _, item in ipairs(one_line_prize) do
					local config = payrate_config[item.item_id]
					if config ~= nil then
						local pay_count = GetItemContinueRequire(item.item_id, gameTypes)
						local payrate = config.payrate[item.continue_count - (pay_count - 1)]
						if payrate > 0 then
							for __, wild in ipairs(wilds) do
								if item.from_index <= wild.col and wild.col <= item.to_index then
									table.insert(wildsResult, wild)
								end
							end
						end
					end
				end
			end
		end
		return wildsResult
	end,
	WinChipInMultiply = function(win_chip)
		local can_multiply = false
		for k, v in ipairs(MultiplePrizeConfig) do
			if (win_chip >= v.min_chip and win_chip <= v.max_chip) then
				can_multiply = true
				break
			end
		end
		return can_multiply
	end,
	--走表形式的通用FreeSpin检查
	FreeSpinCheck = function(player, item_result, game_room_config, is_free_spin, scatter_id)
		-- body
		local scatter_count = #Calculate.GetItemPosition(item_result, game_room_config, scatter_id)
		local free_spin_bouts = 0
		if scatter_count > 0 then
			local scatter_config = CommonCal.Calculate.get_config(player, game_room_config.game_name .. "ScatterConfig")

			scatter_count = scatter_count > #scatter_config and #scatter_config or scatter_count

			if is_free_spin then
				free_spin_bouts = scatter_config[scatter_count].free_spin_extra_bouts
			else
				free_spin_bouts = scatter_config[scatter_count].free_spin_bouts
			end
		end
		return free_spin_bouts
	end,
	--连续图标SuperStack替换通用函数
	SuperStackReplace = function(player, item_result, game_room_config, super_stack_id, super_stack_config)
		local super_stack_replace_tab = {}
		for i = 1, #super_stack_config do
			table.insert(super_stack_replace_tab, super_stack_config[i].weight)
		end
		local appear_index = math.rand_weight(player, super_stack_replace_tab)
		local replace_item_id = super_stack_config[appear_index].item_id

		return replace_item_id
	end,
	GetBetAmount = function(player_game_info)
		local save_data = player_game_info.save_data
		if (save_data.bet_amount_swap ~= nil and save_data.bet_amount_swap > 0) then
			return save_data.bet_amount_swap
		end
		return player_game_info.bet_amount
	end,
	-------改变单线赌注
	ChangeBetAmountInRunning = function(player_game_info, action_list, bet_amount, total_count, spined_count)
		local save_data = player_game_info.save_data
		save_data.bet_amount_swap = bet_amount

		table.insert(
			action_list,
			{
				action_type = ActionType.ActionTypes.ChangeBetAmount,
				bet_amount = bet_amount,
				total_count = total_count,
				spined_count = spined_count
			}
		)
	end,
	ClearFreeSpinedCount = function(player_game_info)
		player_game_info.free_spined_count = 0
	end,
	ClearTotalFreeSpinCount = function(player_game_info)
		player_game_info.total_spin_bouts = 0
	end,
	-------还原单线赌注
	RestoreBetAmountInRunning = function(player_game_info)
		local save_data = player_game_info.save_data
		save_data.bet_amount_swap = nil
	end,
	---等待状态结束后生效的action
	AddActionLater = function(player_game_info, action_info, add_up_keys, formation_id)
		if (formation_id == nil) then
			formation_id = 1
		end
		local save_data = player_game_info.save_data
		if (save_data.action_wait_list == nil) then
			save_data.action_wait_list = {}
		end
		if (save_data.action_wait_list["formation" .. formation_id] == nil) then
			save_data.action_wait_list["formation" .. formation_id] = {}
		end

		if (add_up_keys ~= nil) then
			for k, v in ipairs(save_data.action_wait_list["formation" .. formation_id]) do
				if (v.action_type == action_info.action_type) then
					for index, add_up_key in ipairs(add_up_keys) do
						v[add_up_key] = v[add_up_key] + action_info[add_up_key]
					end
					return
				end
			end
		end
		table.insert(save_data.action_wait_list["formation" .. formation_id], action_info)
	end,
	AddFreeSpinBouts = function(player_game_info, free_spin_bouts)
		player_game_info.free_spin_bouts = player_game_info.free_spin_bouts + free_spin_bouts
		player_game_info.total_spin_bouts = player_game_info.total_spin_bouts + free_spin_bouts
	end,
	GetMapInfoTable = function(player, game_room_config, single_map_config)
		for column_name, column_value in pairs(single_map_config) do
			if (type(column_value) == "table") then
				if (column_value.type == 1) then
					---平均随机
					local weights = {}
					for i = 1, #column_value.info do
						table.insert(weights, column_value.info[i].weight)
					end
					local index = math.rand_weight(player, weights)
					local map_info_id = column_value.info[index].map_info_id

					local map_info_config = CommonCal.Calculate.get_config(player, game_room_config.game_name .. "MapInfoConfig")
					local cur_map_info = map_info_config[map_info_id]
					LOG(RUN, INFO).Format("[SlotsGameCal][GetMapInfoTable] column_value.info is:%s", json.encode(column_value.info))
					return cur_map_info
				end
			end
		end
	end,
	--获得当前玩家在当前玩法需要的表的映射列表
	GetMapConfigTable = function(session, game_room_config, player_game_info, total_bet_amount)
		local player = session.player
		local player_extern = CommonCal.Calculate.get_player_extern(session, task, player)
		local player_json_data = player_extern.save_data
		
		local map_config = CommonCal.Calculate.get_config(player, game_room_config.game_name .. "MapConfig")
		for k, v in ipairs(map_config) do
			while (true) do
				local player_lucky_type = LuckyType.ModeTypes.Normal
				local player_stage_type = 1
				
				if (LuckyCal.IsLuckyOn(player, game_room_config.game_type) == 1) then
					player_lucky_type = player.character.lucky_type
					player_stage_type = player.character.stage_type
				end

				if v.lucky_type ~= nil and v.lucky_type ~= -1 and v.lucky_type ~= player_lucky_type then
					break
				end

				if v.stage_type ~= nil and v.stage_type ~= -1 and v.stage_type ~= player_stage_type then
					break
				end

				local level_require_min = 0
				if v.level_require_min ~= nil then
					level_require_min = v.level_require_min
				end

				if player.character.level >= v.level_require then
					-- LOG(RUN, INFO).Format("[SlotsGameCal][GetMapConfigTable]player %s, v.level_require is:%s, player.character.level is:%s", player.id, v.level_require, player.character.level)
					break
				end
				if player.character.level < v.level_require_min then
					-- LOG(RUN, INFO).Format("[SlotsGameCal][GetMapConfigTable]player %s, v.level_require_min is:%s, player.character.level is:%s", player.id, v.level_require_min, player.character.level)
					break
				end
				if player.record.total_spin > v.total_spin_count_require then
					-- LOG(RUN, INFO).Format("[SlotsGameCal][GetMapConfigTable]player %s, v.total_spin_count_require is:%s, player.character.level is:%s", player.id, v.total_spin_count_require, player.record.total_spin)
					break
				end

				if player.record.total_spin ~= v.total_spin_count_equal_require and v.total_spin_count_equal_require ~= -1 then
					-- LOG(RUN, INFO).Format("[SlotsGameCal][GetMapConfigTable]player %s, v.total_spin_count_equal_require is:%s, player.record.total_spin is:%s", player.id, v.total_spin_count_equal_require, player.record.total_spin)
					break
				end

				if player.character.chip >= v.total_chips_less_require and v.total_chips_less_require ~= -1 then
					-- LOG(RUN, INFO).Format("[SlotsGameCal][GetMapConfigTable]player %s, v.total_chips_less_require is:%s, player.character.chip is:%s", player.id, v.total_chips_less_require, player.character.chip)
					break
				end

				if player.character.vip > v.vip_level_less_require and v.vip_level_less_require ~= -1 then
					-- LOG(RUN, INFO).Format("[SlotsGameCal][GetMapConfigTable]player %s, v.vip_level_less_require is:%s, player.character.vip is:%s", player.id, v.vip_level_less_require,player.character.vip)
					break
				end

				if
					v.game_spin_count_require and player_game_info.spined_times > v.game_spin_count_require and
						v.game_spin_count_require ~= -1
				 then
					-- LOG(RUN, INFO).Format("[SlotsGameCal][GetMapConfigTable]player %s, v.game_spin_count_require is:%s, player_game_info.spined_times is:%s", player.id, v.game_spin_count_require, player_game_info.spined_times)
					break
				end

				if total_bet_amount and v.bet_amount_limit and total_bet_amount > v.bet_amount_limit and v.bet_amount_limit ~= -1 then
					-- LOG(RUN, INFO).Format("[SlotsGameCal][GetMapConfigTable]player %s, v.bet_amount_limit is:%s, total_bet_amount is:%s", player.id, v.bet_amount_limit, total_bet_amount)
					break
				end

				if
					player_json_data.is_free_spin_add ~= nil and v.is_free_spin_add ~= nil and
						player_json_data.is_free_spin_add ~= v.is_free_spin_add and
						v.is_free_spin_add ~= -1
				 then
					-- LOG(RUN, INFO).Format("[SlotsGameCal][GetMapConfigTable]player %s, v.is_free_spin_add is:%s, player_json_data.is_free_spin_add is:%s", player.id, v.is_free_spin_add, player_json_data.is_free_spin_add)
					break
				end

				-- LOG(RUN, INFO).Format("[SlotsGameCal][GetMapConfigTable] player %s, begin use map config", player.id)
				if (player_game_info.save_data.map_config_info == nil) then
					player_game_info.save_data.map_config_info = Calculate.GetMapInfoTable(player, game_room_config, v)
				end
				return player_game_info.save_data.map_config_info
			end
		end
		if (player_game_info.save_data.map_config_info == nil) then
			player_game_info.save_data.map_config_info =
				Calculate.GetMapInfoTable(player, game_room_config, map_config[#map_config])
		end
		return player_game_info.save_data.map_config_info
	end
}
