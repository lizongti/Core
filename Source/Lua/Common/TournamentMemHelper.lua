--[[-------->>锦标赛内存帮助器.游戏中的数据，优先从内存的缓存数据中取，没有或者过期时，才使用Redis数据]]
TournamentMemHelperClass = {
	have_match_mem_map = {}, --各游戏是否有比赛的信息
	match_config_mem_map = {}, --各游戏的比赛配置信息
	match_state_mem_map = {}, --各比赛的状态信息
	match_info_mem_map = {}, --比赛信息的信息
	match_player_num_mem_map = {}, --比赛中玩家的数量信息
	player_exist_mem_map = {} --各比赛中玩家的存在状态信息
}
TournamentMemHelperClass.__index = TournamentMemHelperClass --补充索引器

--部分变量定义
local tournament_redis = TournamentRedisHelperClass --锦标赛帮助器

do --共有有方法
	--获取游戏是否开启了比赛
	--in[
	--	_module_id：游戏Id
	--]
	function TournamentMemHelperClass:IsGameHaveMatch(_module_id)
		--初始化返回值
		local have_match = false

		--获取逻辑
		local have_match_mem = self.have_match_mem_map[_module_id] --内存中的缓存数据
		if have_match_mem then
			if system.time() - have_match_mem.fresh_time > 10000 then --过期
				--从redis重新获取
				have_match = tournament_redis:IsGameHaveMatch(_module_id)
				--更新内存数据
				have_match_mem.have_match = have_match
				have_match_mem.fresh_time = system.time()
			else --未过期
				have_match = have_match_mem.have_match --直接使用内存数据
			end
		else --内存无数据
			--从redis获取
			have_match = tournament_redis:IsGameHaveMatch(_module_id)
			--更新内存数据
			self.have_match_mem_map[_module_id] = {
				have_match = have_match,
				fresh_time = system.time()
			}
		end

		--返回
		return have_match
	end

	--获取比赛状态
	function TournamentMemHelperClass:GetMatchState(_module_id)
		--初始化返回值
		local match_sate = tournament_redis.ENUM.MATCH_STATE.UNKOWN

		--获取逻辑
		local match_info = self:GetMatchInfo(_module_id)
		if match_info then
			match_sate = match_info.match_state
		end

		--返回
		return match_sate
	end

	--获取比赛配置
	function TournamentMemHelperClass:GetMatchConfig(_module_id)
		--初始化返回值
		local match_config = nil

		--获取逻辑
		local match_info = self:GetMatchInfo(_module_id)
		if match_info then
			match_config = match_info.match_config
		end

		--返回
		return match_config
	end

	--获取比赛信息
	--in[
	--	_module_id：游戏Id
	--]
	function TournamentMemHelperClass:GetMatchInfo(_module_id)
		--初始化返回值
		local match_info = nil

		--获取逻辑
		local match_info_mem = self.match_info_mem_map[_module_id] --内存中的比赛状态数据
		if match_info_mem then --内存有数据
			if system.time() - match_info_mem.fresh_time > 1000 then --过期
				--从redis重新获取
				match_info = tournament_redis:GetMatchInfo(_module_id)
				--获取失败重试一次
				if not match_info then
					match_info = tournament_redis:GetMatchInfo(_module_id)
				end
				--更新内存数据
				if match_info then
					match_info_mem.match_info = match_info
					match_info_mem.fresh_time = system.time()
				end
			else --未过期
				match_info = match_info_mem.match_info --直接使用内存数据
			end
		else --内存无数据
			--从redis获取
			match_info = tournament_redis:GetMatchInfo(_module_id)
			--获取失败重试一次
			if not match_info then
				match_info = tournament_redis:GetMatchInfo(_module_id)
			end
			--更新内存数据
			if match_info then
				self.match_info_mem_map[_module_id] = {
					match_info = match_info,
					fresh_time = system.time()
				}
			end
		end

		--返回
		return match_info
	end

	--获取比赛玩家数量
	function TournamentMemHelperClass:GetMatchPlayerNum(_module_id)
		--初始化返回值
		local match_player_num = nil

		--获取逻辑
		local match_player_num_mem = self.match_player_num_mem_map[_module_id] --内存中的比赛状态数据
		if match_player_num_mem then --内存有数据
			if system.time() - match_player_num_mem.fresh_time > 2000 then --过期
				--从redis重新获取
				match_player_num = tournament_redis:GetMatchPlayerNum(_module_id)

				--更新内存数据
				match_player_num_mem.match_player_num = match_player_num
				match_player_num_mem.fresh_time = system.time()
			else --未过期
				match_player_num = match_player_num_mem.match_player_num --直接使用内存数据
			end
		else --内存无数据
			--从redis获取
			match_player_num = tournament_redis:GetMatchPlayerNum(_module_id)
			--更新内存数据
			self.match_player_num_mem_map[_module_id] = {
				match_player_num = match_player_num,
				fresh_time = system.time()
			}
		end

		--返回
		return match_player_num
	end

	--更新玩家Map
	--in[
	--	_module_id：游戏Id
	--	_player_base_info: 玩家基础信息
	--]
	function TournamentMemHelperClass:UpdatePlayerInfoMap(_module_id, _player_base_info)
		--取出数据
		local player_id = _player_base_info.id --玩家id
		local player_exist_mem_game_map = self.player_exist_mem_map[_module_id] --单个游戏的玩家信息Map
		if player_exist_mem_game_map then --玩家信息Map存在
			local player_exist_mem = player_exist_mem_game_map[player_id] --玩家的存在信息
			if player_exist_mem then --有玩家的存在信息
				--计算过期时间
				local expire_time = nil
				for _, tournamentMapInfo in ipairs(GameTournamentInfoMapConfig) do
					if tournamentMapInfo.module_id == _module_id then
						local tournament_config_id = tournamentMapInfo.tournament_config_id
						expire_time = GameTournamentInfoConfig[tournament_config_id].rest_time --玩家信息在更新一次后，最短可以存活一个休息周期（从排名结束，到开始下一场比赛最短需要这个时间）
						break
					end
				end
				--处理玩家的信息
				if system.time() - player_exist_mem.fresh_time > expire_time then --过期（因为一场比赛有，会将比赛中的玩家信息清空）
					--操作内存
					player_exist_mem.fresh_time = system.time()
					--操作redis
					tournament_redis:UpdatePlayerInfoMap(_module_id, _player_base_info)
				else --未过期，则什么都不做
				end
			else --没有玩家信息
				--操作内存
				player_exist_mem_game_map[player_id] = {fresh_time = system.time()} --存入玩家信息
				--操作redis
				tournament_redis:UpdatePlayerInfoMap(_module_id, _player_base_info)
			end
		else --游戏的玩家信息表是空的
			--操作内存
			self.player_exist_mem_map[_module_id] = {} -- 新建内存中改游戏的玩家存在表
			self.player_exist_mem_map[_module_id][player_id] = {fresh_time = system.time()} --存入玩家信息
			--操作redis
			tournament_redis:UpdatePlayerInfoMap(_module_id, _player_base_info)
		end
	end
end
--[[<<--------锦标赛帮助器]]
--新加游戏锦标赛的功能
