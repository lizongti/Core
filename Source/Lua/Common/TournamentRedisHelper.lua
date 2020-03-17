--[[-------->>锦标赛管理器 纯静态]]
TournamentRedisHelperClass = {
	ENUM = {
		REDIS_KEY = {
			GAME_IDWITHMATCH_SET = "Tournament_GameIdWitchMatch", --开启锦标赛的游戏id数组
			GAME_BASE_INFO = "Tournament_BaseInfo_ModuleId", --比赛的基本信息
			GAME_PLAYERWINCHIP_SORTEDSET = "Tournament_PlayerWinChip_ModuleId", --比赛玩家得分
			GAME_AllPLAYER_MAP = "Tournament_PlayerInfo_ModuleId", --参与比赛的玩家信息
			GAME_PLAYERPRIZEINFO_MAP = "Tournament_PrizeInfo_ModuleId", --玩家的奖励信息表
			GAME_PLAYERPRIZERECEIVE_SORTEDSET = "Tournament_PrizeReceive_ModuleId" --玩家的奖励领取状态表
		},
		MATCH_STATE = {
			UNKOWN = 0, --未知状态
			IN_RANK = 1, --玩家比赛排名中
			RANK_END = 2, --玩家排名结束
			IN_REST = 3, --休息中
			REST_END = 4, --休息结束
			MATCH_OVER = 5 --比赛结束
		}
	}
}
TournamentRedisHelperClass.__index = TournamentRedisHelperClass --补充索引器

do --共有有方法
	--Redis执行方法 单条
	--in[
	--	_operredis:操作语句 例如："HGET friend friend[1000]"等
	--]
	function TournamentRedisHelperClass:RedisExcute(...)
		--初始化返回值
		local response = nil

		--进行redis操作
		if (LuaSession ~= nil) then
			local oper_table = {...}
			local task = Task:Current()
			task.create_time = os.time() --更新创建时间，防止任务执行超时
			response = LuaSession:ContactJson("CacheClientService", task, oper_table, 0)
		else
			LOG(RUN, INFO).Format(
				"[TournamentRedisHelperClass][RedisExcute] (LuaSession is nil time: %d",
				tonumber(os.date("%Y%m%d%H%M%S"))
			)
		end

		-- if not string.find(Table2Str({...}), "HMSET Tournament_BaseInfo_ModuleId41") then
		-- 	LOG(RUN, INFO).Format(
		-- 		"[TournamentRedisHelperClass][RedisExcute] return (oper_table=%s  response=%s ",
		-- 		Table2Str({...}),
		-- 		Table2Str(response)
		-- 	)
		-- end

		--返回
		return response
	end

	--从Redis获取拥有比赛的游戏id数组
	--out[
	--	module_id_arr:游戏id的数组
	--]
	function TournamentRedisHelperClass:GetAllHaveMachGameIdInRedis()
		--初始化返回值
		local module_id_arr = nil

		--从redis获取
		local oper = string.format("SMEMBERS %s", self.ENUM.REDIS_KEY.GAME_IDWITHMATCH_SET)
		local response = self:RedisExcute(oper)

		--获取游戏id的table
		if (response) then
			module_id_arr = {}
			for idx, module_id_str in pairs(response) do
				if (module_id_str ~= "") then
					module_id_arr[idx] = tonumber(module_id_str)
				end
			end
		end

		--返回
		return module_id_arr
	end

	--添加有比赛的游戏id到Redis
	--in[
	-- _add_module_id:添加的游戏id
	--]
	function TournamentRedisHelperClass:AddHaveMachGameIdArr(_add_module_id_arr)
		--保存redis
		local oper = string.format("SADD %s", self.ENUM.REDIS_KEY.GAME_IDWITHMATCH_SET)
		for _, add_module_id in ipairs(_add_module_id_arr) do
			oper = oper .. " " .. add_module_id
		end
		local response = self:RedisExcute(oper)
	end

	--移除有比赛的游戏id到Redis
	--in[
	-- _remove_module_id:移除的游戏id
	--]
	function TournamentRedisHelperClass:RemoveHaveMachGameId(_remove_module_id)
		local oper = string.format("SREM %s %d", self.ENUM.REDIS_KEY.GAME_IDWITHMATCH_SET, _remove_module_id)
		local response = self:RedisExcute(oper)
	end

	--游戏是否有比赛正在运行
	--in[
	--	_module_id:游戏Id
	--]
	--out[
	--	have:游戏是否有比赛
	--]
	function TournamentRedisHelperClass:IsGameHaveMatch(_module_id)
		--初始化返回值
		local have = false

		--读取redis数据库
		local oper = string.format("SISMEMBER %s %d", self.ENUM.REDIS_KEY.GAME_IDWITHMATCH_SET, _module_id)
		local response = self:RedisExcute(oper)
		--判断结果
		if (response and response[1] and response[1] ~= "" and tonumber(response[1]) == 1) then
			have = true
		end

		--返回
		return have
	end

	--获取游戏的比赛配置
	--in[
	--	_module_id:游戏Id
	--]
	function TournamentRedisHelperClass:GetMatchConfig(_module_id)
		--初始化返回值
		local match_config = nil

		--读取redis数据库进行信息填写
		local key = self.ENUM.REDIS_KEY.GAME_BASE_INFO .. _module_id --key名字
		local oper = string.format("HMGET %s ", key)
		oper = oper .. " match_config"
		local response = self:RedisExcute(oper)
		if (response and response[1] and response[1] ~= "") then
			match_config = json.decode(response[1])
		end

		--返回
		return match_config
	end

	--保存所有的比赛信息到Redis（会覆盖旧的）
	--[
	--	match_info:比赛信息
	-- ]
	function TournamentRedisHelperClass:SettMatchInfo(match_info)
		local module_id = match_info.module_id

		-- 新建基础信息
		local key_base = self.ENUM.REDIS_KEY.GAME_BASE_INFO .. module_id --key名字
		local oper_base_create = string.format("HMSET %s", key_base) --创建基本信息
		oper_base_create = oper_base_create .. " module_id " .. module_id
		oper_base_create = oper_base_create .. " match_config " .. json.encode(match_info.match_config)
		oper_base_create = oper_base_create .. " last_tick_time " .. match_info.last_tick_time
		oper_base_create = oper_base_create .. " run_time " .. match_info.run_time
		oper_base_create = oper_base_create .. " match_state " .. match_info.match_state
		oper_base_create = oper_base_create .. " match_id " .. match_info.match_id
		oper_base_create = oper_base_create .. " chips_in_pool " .. match_info.chips_in_pool

		--执行redis操作
		self:RedisExcute(oper_base_create)
	end

	--删除排名和奖励信息
	--[
	--	_module_id:游戏id
	-- ]
	function TournamentRedisHelperClass:DeleteRankAndPrizeInfo(_module_id)
		--排名信息删除
		local key_rank = self.ENUM.REDIS_KEY.GAME_PLAYERWINCHIP_SORTEDSET .. _module_id
		local opera_rank_del = string.format("DEL %s", key_rank)
		--参与比赛的玩家相信信息删除
		local key_player = self.ENUM.REDIS_KEY.GAME_AllPLAYER_MAP .. _module_id
		local oper_player_del = string.format("DEL %s", key_player)
		--奖励信息删除
		local key_prize = self.ENUM.REDIS_KEY.GAME_PLAYERPRIZEINFO_MAP .. _module_id
		local oper_prize_del = string.format("DEL %s", key_prize)
		--奖励领取记录删除
		local key_receive = self.ENUM.REDIS_KEY.GAME_PLAYERPRIZERECEIVE_SORTEDSET .. _module_id
		local oper_receive_del = string.format("DEL %s", key_receive)

		--执行操作
		self:RedisExcute(opera_rank_del, oper_player_del, oper_prize_del, oper_receive_del)
	end

	--删除比赛基本信息
	--[
	--	_module_id:游戏id
	-- ]
	function TournamentRedisHelperClass:DeleteMatchBaseInfo(_module_id)
		--基本信息删除
		local key_base = self.ENUM.REDIS_KEY.GAME_BASE_INFO .. _module_id --key名字
		local oper_base_del = string.format("DEL %s", key_base) --删除旧的基本信息表

		--执行操作
		self:RedisExcute(oper_base_del)
	end

	--从Redis获取所有的比赛信息
	--in[
	--	_module_id:游戏Id
	--]
	--out[
	--	info:比赛的基本信息
	--]
	function TournamentRedisHelperClass:GetMatchInfo(_module_id)
		--初始化返回值
		local info = nil

		--读取redis数据库进行信息填写
		--基础数据
		local key = self.ENUM.REDIS_KEY.GAME_BASE_INFO .. _module_id --key名字
		local oper = string.format("HMGET %s", key)
		oper = oper .. " module_id"
		oper = oper .. " match_config"
		oper = oper .. " last_tick_time"
		oper = oper .. " run_time"
		oper = oper .. " match_state"
		oper = oper .. " match_id"
		oper = oper .. " chips_in_pool"
		--执行redis操作
		local response = self:RedisExcute(oper)
		if (response and #response == 7) then
			--检查结果数据
			local have_all_data = true --是否包含所有数据
			for _, str in ipairs(response) do
				if not (str and str ~= "") then
					have_all_data = false
					break
				end
			end

			--数据填写
			if (have_all_data) then
				info = {}
				--基础数据填写
				info.module_id = tonumber(response[1])
				info.match_config = json.decode(response[2])
				info.last_tick_time = tonumber(response[3])
				info.run_time = tonumber(response[4])
				info.match_state = tonumber(response[5])
				info.match_id = tonumber(response[6])
				info.chips_in_pool = tonumber(response[7])
			end
		end

		--返回
		return info
	end

	--设置比赛状态
	--in[
	--	_module_id:游戏Id
	-- _match_state:设置当前的比赛状态
	--]
	function TournamentRedisHelperClass:SetMatchState(_module_id, _match_state)
		local key = self.ENUM.REDIS_KEY.GAME_BASE_INFO .. _module_id --key名字
		local oper = string.format("HSET %s", key) --创建基本信息
		oper = oper .. " match_state " .. _match_state
		self:RedisExcute(oper)
	end

	--从Redis获比赛状态
	--in[
	--	_module_id:游戏Id
	--]
	--out[
	--	state:比赛状态
	--]
	function TournamentRedisHelperClass:GetMatchState(_module_id)
		--初始化返回值
		local state = self.ENUM.MATCH_STATE.UNKOWN

		--读取redis数据库进行信息填写
		--基础数据
		local key = self.ENUM.REDIS_KEY.GAME_BASE_INFO .. _module_id --key名字
		local oper = string.format("HMGET %s", key)
		oper = oper .. " match_state"
		--执行redis操作
		local response = self:RedisExcute(oper)
		if (response and response[1] and response[1] ~= "") then
			state = tonumber(response[1])
		end

		--返回
		return state
	end

	--更新比赛的运行时间
	--in[
	--	_module_id:游戏id
	--	_last_tick_time:上次轮询的时间
	--	_run_time:游戏运行的时间
	--]
	function TournamentRedisHelperClass:SetMatchTime(_module_id, _last_tick_time, _run_time)
		local key = self.ENUM.REDIS_KEY.GAME_BASE_INFO .. _module_id --key名字
		local oper = string.format("HMSET %s", key) --创建基本信息
		oper = oper .. " last_tick_time " .. _last_tick_time
		oper = oper .. " run_time " .. _run_time
		self:RedisExcute(oper)
	end

	--添加奖池中的筹码
	--in[
	--	_module_id:游戏Id
	--	_add_chip_num:添加的筹码
	--]
	function TournamentRedisHelperClass:AddChipsInPool(_module_id, _add_chip_num)
		if _add_chip_num > 0 then
			local key = self.ENUM.REDIS_KEY.GAME_BASE_INFO .. _module_id
			local oper = string.format("HINCRBY %s chips_in_pool %d", key, _add_chip_num)
			self:RedisExcute(oper)
		end
	end

	--增加玩家赢钱冰添加奖池筹码
	function TournamentRedisHelperClass:AddPlayerWinChipAndChipsInPool(_module_id, _player_id, _add_win_chip, _cost_chip)
		--操作数组
		local oper_arr = {}
		--玩家赢分增加
		if _add_win_chip > 0 then
			local key = self.ENUM.REDIS_KEY.GAME_PLAYERWINCHIP_SORTEDSET .. _module_id
			local oper = string.format("ZINCRBY %s %s %d", key, _add_win_chip, _player_id)
			table.insert(oper_arr, oper)
		end
		--奖池筹码增肌
		if _cost_chip > 0 then
			local key = self.ENUM.REDIS_KEY.GAME_BASE_INFO .. _module_id
			local oper = string.format("HINCRBY %s chips_in_pool %d", key, _cost_chip)
			table.insert(oper_arr, oper)
		end

		--执行操作
		if #oper_arr > 0 then
			self:RedisExcute(unpack(oper_arr))
		end
	end

	--获取游戏比赛的奖池筹码数目
	--in[
	--	_module_id:游戏Id
	--]
	--out[
	--	chips_in_pool:奖池的筹码数
	--]
	function TournamentRedisHelperClass:GetChipsInPool(_module_id)
		--初始化返回值
		local chips_in_pool = 0

		--赋值返回值
		local key = self.ENUM.REDIS_KEY.GAME_BASE_INFO .. _module_id
		local oper = string.format("HGET %s chips_in_pool", key)
		local response = self:RedisExcute(oper)
		if (response and response[1] and response[1] ~= "") then
			chips_in_pool = tonumber(response[1])
		end

		--返回
		return chips_in_pool
	end

	--Redis是否已经有玩家的信息
	--in[
	--	_module_id:
	--	_player_id:玩家id
	-- ]
	--out[
	--	have:是否已经拥有
	--]
	function TournamentRedisHelperClass:IsPlayerInfoInRedis(_module_id, _player_id)
		--初始化返回值
		local have = false

		--查询redis
		local key = self.ENUM.REDIS_KEY.GAME_AllPLAYER_MAP .. _module_id
		local oper = string.format("HEXISTS %s %s", key, _player_id)
		local response = self:RedisExcute(oper)
		if (response and response[1] and response[1] ~= "") then
			if (tonumber(response[1]) == 1) then
				have = true
			end
		end

		--返回
		return have
	end

	--更新比赛玩家信息表
	--int[
	--	_module_id:游戏Id
	--	_player:玩家信息
	--]
	function TournamentRedisHelperClass:UpdatePlayerInfoMap(_module_id, _player)
		--玩家信息
		local player_id = _player.id
		if (not self:IsPlayerInfoInRedis(_module_id, player_id)) then
			local player_info = json.encode(_player)
			--存入redis
			local key = self.ENUM.REDIS_KEY.GAME_AllPLAYER_MAP .. _module_id
			local oper = string.format("HSET %s %s %s", key, player_id, player_info)
			local response = self:RedisExcute(oper)
		end
	end

	--获取前3名和相近3名的玩家信息
	--[
	--	_module_id:游戏Id
	--	_player_id:玩家id
	--]
	function TournamentRedisHelperClass:GetTop3PlayerAndNear3PlayerInfo(_module_id, _player_id)
		--初始化返回值
		local top3_player_arr = {}
		local near3_player_arr = {}

		--填充返回数据
		local all_player_score_map = self:GetRankRangePlayerScoreMap(_module_id, 1, 30) --所有玩家的得分信息表
		local game_player_num = #all_player_score_map
		if (game_player_num > 0) then
			------获取得分信息
			----前3名玩家
			local top3_player_score_map = {}
			for rank = 1, 3, 1 do
				local score_info = all_player_score_map[rank]
				if (score_info) then
					top3_player_score_map[score_info.id] = score_info
				end
			end
			----相邻的3名玩家
			--确定玩家自己的排名
			local player_rank = 0 --请求排名玩家自己的排名
			for rank, score_info in ipairs(all_player_score_map) do
				if (score_info.id == _player_id) then
					player_rank = rank
					break
				end
			end
			--寻找附近玩家排名
			local near3_player_score_map = {}
			if (player_rank ~= 0) then --找到了玩家的排名
				--确定起止排名
				local max_rank_num = #all_player_score_map
				local rank_start = player_rank - 1
				local rank_end = player_rank + 1
				if (rank_start < 1) then --第一个玩家位置已经超过了第一名，取出玩家数据后移
					rank_end = rank_end + (1 - rank_start) --截至排名后移
					rank_start = 1
				end
				if (rank_end > max_rank_num) then --最后一个玩家已经超出最后一名，则后面的数据进行截断到最后一名
					rank_start = rank_start - (rank_end - max_rank_num) --开始排名前移
					rank_end = max_rank_num
				end
				--加入玩家排名信息
				for rank = rank_start, rank_end, 1 do
					local score_info = all_player_score_map[rank]
					if (score_info) then
						near3_player_score_map[score_info.id] = score_info
					end
				end
			end

			--填充玩家详细信息数据
			--生成需要获取玩家信息的id数组
			local player_id_arr = {}
			for player_id, _ in pairs(top3_player_score_map) do
				table.insert(player_id_arr, player_id)
			end
			for player_id, _ in pairs(near3_player_score_map) do
				table.insert(player_id_arr, player_id)
			end
			--获取玩家信息
			local player_base_info_map = self:GetPlayerInfoMul(_module_id, player_id_arr)
			--返回值填入
			for player_id, win_chip_info in pairs(top3_player_score_map) do
				if (player_base_info_map[player_id]) then
					local player_info = win_chip_info
					player_info.player = player_base_info_map[player_id]
					player_info.player.user.nickname = string.encode(player_info.player.user.nickname)
					table.insert(top3_player_arr, player_info)
				end
			end
			for player_id, win_chip_info in pairs(near3_player_score_map) do
				if (player_base_info_map[player_id]) then
					local player_info = win_chip_info
					player_info.player = player_base_info_map[player_id]
					player_info.player.user.nickname = string.encode(player_info.player.user.nickname)
					table.insert(near3_player_arr, player_info)
				end
			end
		end

		--返回
		return top3_player_arr, near3_player_arr
	end

	--获取参与比赛的玩家人数
	--int[
	--	_module_id:游戏Id
	--]
	function TournamentRedisHelperClass:GetMatchPlayerNum(_module_id)
		--初始化返回值
		local num = 0

		--读取redis数据库
		local key = self.ENUM.REDIS_KEY.GAME_AllPLAYER_MAP .. _module_id
		local oper = string.format("HLEN %s", key)
		local response = self:RedisExcute(oper)
		if (response and response[1] and response[1] ~= "") then
			num = tonumber(response[1])
		end

		--返回
		return num
	end

	--获取玩家的信息
	--int[
	--	_module_id:游戏Id
	--	_player_id:玩家id
	--]
	--out[
	--	info_map:玩家信息的map:key[player_id]->val[playerInfo]
	--]
	function TournamentRedisHelperClass:GetPlayerInfo(_module_id, _player_id)
		--初始化返回值
		local info = nil

		--读取redis数据库
		local key = self.ENUM.REDIS_KEY.GAME_AllPLAYER_MAP .. _module_id
		local oper = string.format("HGET %s %d", key, _player_id)
		local response = self:RedisExcute(oper)
		--将结果填入table
		if (response and response[1] and response[1] ~= "") then
			info = json.decode(response[1])
		end

		--返回
		return info
	end

	--获取多个玩家的信息
	--int[
	--	_module_id:游戏Id
	--	_player_id_arr:玩家id数组
	--]
	--out[
	--	info_map:玩家信息的map:key[player_id]->val[playerInfo]
	--]
	function TournamentRedisHelperClass:GetPlayerInfoMul(_module_id, _player_id_arr)
		--初始化返回值
		local info_map = {}

		--读取redis数据库
		local key = self.ENUM.REDIS_KEY.GAME_AllPLAYER_MAP .. _module_id
		local oper = string.format("HMGET %s", key)
		for idx, player_id in ipairs(_player_id_arr) do
			oper = oper .. " " .. player_id
		end
		local response = self:RedisExcute(oper)
		--将结果填入table
		if (response) then
			for idx, player_id in ipairs(_player_id_arr) do
				if (response[idx] and response[idx] ~= "") then
					info_map[player_id] = json.decode(response[idx])
				end
			end
		end

		--返回
		return info_map
	end

	--添加玩家的赢得筹码
	--[
	--	_module_id:游戏Id
	--	_player_id:玩家id
	--	_add_win_chip:增加的赢得筹码
	--]
	function TournamentRedisHelperClass:AddPlayerWinChip(_module_id, _player_id, _add_win_chip)
		local key = self.ENUM.REDIS_KEY.GAME_PLAYERWINCHIP_SORTEDSET .. _module_id
		local oper = string.format("ZINCRBY %s %s %d", key, _add_win_chip, _player_id)
		self:RedisExcute(oper)
	end

	--获取玩家的得分
	--in[
	--	_module_id:游戏Id
	--	_player_id:玩家id
	--]
	--out[
	--	win_scores:玩家得分
	--]
	function TournamentRedisHelperClass:GetPlayerSocre(_module_id, _player_id)
		--初始化返回值
		local win_scores = 0

		--读取redis
		local match_config = self:GetMatchConfig(_module_id)
		if (match_config) then
			local chip_score_percent = match_config.chip_score_percent --下注筹码转换为得分的比例
			local key = self.ENUM.REDIS_KEY.GAME_PLAYERWINCHIP_SORTEDSET .. _module_id
			local oper = string.format("ZSCORE %s %s", key, _player_id)
			local response = self:RedisExcute(oper)
			if (response and response[1] and response[1] ~= "") then
				win_scores = math.floor(tonumber(response[1]) * chip_score_percent)
			end
		end

		--返回
		return win_scores
	end

	--获取玩家的排名
	--[
	--	_module_id:游戏Id
	--	_player_id:玩家id
	--]
	function TournamentRedisHelperClass:GetPlayerRank(_module_id, _player_id)
		--初始化返回值
		local rank = 0

		--读取redis
		local key = self.ENUM.REDIS_KEY.GAME_PLAYERWINCHIP_SORTEDSET .. _module_id
		local oper = string.format("ZREVRANK %s %s", key, _player_id)
		local response = self:RedisExcute(oper)
		if (response and response[1] and response[1] ~= "") then
			rank = tonumber(response[1])
		end

		--返回
		return rank
	end

	--获取排名范围内的玩家得分信息
	--in[
	--	_module_id:游戏Id
	--	rank_start:开始名次
	--	rank_end:结束名次
	--]
	--out[
	--	id_win_score_info_map:玩家排名得分信息map:key[rank]->val[win_score_info]
	--]
	function TournamentRedisHelperClass:GetRankRangePlayerScoreMap(_module_id, rank_start, rank_end)
		--初始化返回值
		local id_win_score_info_map = {}

		--读取redis
		local match_config = self:GetMatchConfig(_module_id)
		if (match_config) then
			--需要使用的临时变量获取
			local chip_score_percent = match_config.chip_score_percent --下注筹码转换为得分的比例
			local key = self.ENUM.REDIS_KEY.GAME_PLAYERWINCHIP_SORTEDSET .. _module_id
			local oper = string.format("ZREVRANGE %s %d %d WITHSCORES", key, rank_start - 1, rank_end - 1)
			local response = self:RedisExcute(oper)
			if (response) then
				local data_idx = 1
				for rank = rank_start, #response, 1 do
					if (response[data_idx] and response[data_idx] ~= "" and response[data_idx + 1] and response[data_idx + 1] ~= "") then
						-- 玩家基本信息
						local win_score_info = {}
						win_score_info.rank = rank
						win_score_info.id = tonumber(response[data_idx])
						data_idx = data_idx + 1
						win_score_info.win_scores = math.floor(tonumber(response[data_idx]) * chip_score_percent)
						data_idx = data_idx + 1
						-- 入表
						id_win_score_info_map[rank] = win_score_info
					else
						break
					end
				end
			end
		end

		--返回
		return id_win_score_info_map
	end

	--保存比赛的奖励信息
	--in[
	--	_module_id:游戏Id
	--	_player_prize_map:玩家的奖励信息
	--	_player_receive_map:玩家的是否获取过奖励的信息
	--]
	function TournamentRedisHelperClass:SetMatchPrize(_module_id, _player_prize_map, _player_receive_map)
		--奖励信息
		local key_prize = self.ENUM.REDIS_KEY.GAME_PLAYERPRIZEINFO_MAP .. _module_id
		local oper_prize = string.format("HMSET %s", key_prize)
		for player_id, prize_info in pairs(_player_prize_map) do
			oper_prize = oper_prize .. string.format(" %d %s", player_id, json.encode(prize_info))
		end
		--领取记录
		local key_receive = self.ENUM.REDIS_KEY.GAME_PLAYERPRIZERECEIVE_SORTEDSET .. _module_id
		local oper_receive = string.format("ZADD %s", key_receive)
		for player_id, state in pairs(_player_receive_map) do
			oper_receive = oper_receive .. string.format(" %d %d", state, player_id)
		end
		--执行操作
		self:RedisExcute(oper_prize, oper_receive)
	end

	--获取玩家奖励信息
	--in[
	--	_module_id:游戏Id
	--	_player_id:玩家id
	--]
	--out[
	--	prize_info:玩家的奖励信息
	--]
	function TournamentRedisHelperClass:GetPlayerPrizeInfo(_module_id, _player_id)
		--初始化返回值
		local prize_info = nil

		--填入数据
		local key = self.ENUM.REDIS_KEY.GAME_PLAYERPRIZEINFO_MAP .. _module_id
		local oper = string.format("HGET %s %d", key, _player_id)
		local response = self:RedisExcute(oper)
		if (response and response[1] and response[1] ~= "") then
			prize_info = json.decode(response[1])
		end

		--返回
		return prize_info
	end

	--获取多个玩家奖励信息
	--in[
	--	_module_id:游戏Id
	--	_player_id_arr:玩家id数组
	-- ]
	--out[
	--	player_prize_map:玩家的奖励信息Map
	--]
	function TournamentRedisHelperClass:GetPlayerPrizeInfoMul(_module_id, _player_id_arr)
		--初始化返回值
		local player_prize_map = {}

		--从redis获取
		if #_player_id_arr > 0 then
			local key = self.ENUM.REDIS_KEY.GAME_PLAYERPRIZEINFO_MAP .. _module_id
			local oper = string.format("HMGET %s", key)
			for _, player_id in ipairs(_player_id_arr) do
				oper = oper .. " " .. player_id
			end
			local response_prize = self:RedisExcute(oper)

			if response_prize then
				for idx, player_prize_str in ipairs(response_prize) do
					local player_id = _player_id_arr[idx]
					if (player_prize_str ~= "") then
						player_prize_map[player_id] = json.decode(player_prize_str)
					end
				end
			end
		end

		--返回
		return player_prize_map
	end

	--获取未领奖玩家的id数组
	--int[
	--	_module_id:游戏id
	-- ]
	--out[
	--	player_id_arr:未领奖玩家的id数组
	--]
	function TournamentRedisHelperClass:GetNoReceivePrizePlayerIdArr(_module_id)
		--返回值初始化
		local player_id_arr = {}

		--获取没有领奖的玩家数组
		local key_no_receive = self.ENUM.REDIS_KEY.GAME_PLAYERPRIZERECEIVE_SORTEDSET .. _module_id
		local oper_no_receive = string.format("ZRANGEBYSCORE %s 0 0", key_no_receive)
		local response_no_receive = self:RedisExcute(oper_no_receive)
		if (response_no_receive) then
			for _, player_id in ipairs(response_no_receive) do
				table.insert(player_id_arr, tonumber(player_id))
			end
		end

		-- LOG(RUN, INFO).Format(
		-- 	"[TournamentRedisHelperClass][GetNoReceivePrizePlayerIdArr] _module_id[%d] oper_no_receive[%s], player_id_arr[%s]",
		-- 	_module_id,
		-- 	oper_no_receive,
		-- 	Table2Str(player_id_arr)
		-- )

		--返回
		return player_id_arr
	end

	--玩家尝试领奖
	--in[
	--	_module_id:游戏Id
	--	_player_id:玩家id
	--]
	--out[
	--	success: 领奖是否成功
	-- ]
	function TournamentRedisHelperClass:TryTakePrize(_module_id, _player_id)
		--初始化返回值
		local success = false

		--进行redis操作
		local key = self.ENUM.REDIS_KEY.GAME_PLAYERPRIZERECEIVE_SORTEDSET .. _module_id
		local oper = string.format("ZINCRBY %s 1 %d", key, _player_id)
		local response = self:RedisExcute(oper)
		if (response and response[1] and response[1] ~= "" and tonumber(response[1]) == 1) then
			success = true
		end

		--返回
		return success
	end

	--玩家主动领取奖励
	--in[
	--	_module_id:游戏Id
	--	_player_id:玩家id
	--]
	--out[
	--	have_prize:
	--	had_received:
	--	prize_info:
	-- ]
	function TournamentRedisHelperClass:PlayerTakePrize(_module_id, _player_id)
		--初始化返回值
		local have_prize = false
		local had_received = false
		local prize_info = nil

		--填入返回值
		if (self:IsGameHaveMatch(_module_id)) then --有这个比赛
			local key = self.ENUM.REDIS_KEY.GAME_PLAYERPRIZERECEIVE_SORTEDSET .. _module_id
			local oper_have = string.format("ZSCORE %s %d", key, _player_id)
			local response_have = self:RedisExcute(oper_have)
			if (response_have and response_have[1] and response_have[1] ~= "") then
				have_prize = true
				if (tonumber(response_have[1]) == 1) then
					had_received = true
				end
			end

			--根据玩家获奖结果尝试发奖
			if (have_prize and not had_received) then
				--尝试领奖(进行自增操作，根据自增结果判断，是否为首次领奖，防止并发领奖出现的重复领奖问题)
				success = self:TryTakePrize(_module_id, _player_id)
				had_received = not success
				--根据尝试结果，确定是否确实需要发奖
				if (success) then
					prize_info = self:GetPlayerPrizeInfo(_module_id, _player_id)
				end
			end
		end

		--返回
		return have_prize, had_received, prize_info
	end
end
--[[<<--------锦标赛帮助器]]
--新加游戏锦标赛的功能
