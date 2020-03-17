require "Common/Return"
require "Util/OsExt"
require "Util/OsExt"

module("Tournament", package.seeall)

--初始化帮助器
local tournament_redis = TournamentRedisHelperClass --锦标赛数据帮助器(Redis)
local tournament_mem = TournamentMemHelperClass --锦标赛数据帮助器(内存)

--获取比赛是否在排名阶段，以及剩余时间
--in[
--	_match_info:比赛信息
-- ]
--out[
--	in_ranking:是否在排名阶段中
--	left_time:剩余时间
-- ]
local function getMatchInRankAndTimeToClient(_match_info)
	--初始化返回值
	local in_ranking = false
	local left_time = 1

	--处理返回值
	if (_match_info ~= nil) then
		local rank_time = _match_info.match_config.rank_time
		local rest_time = _match_info.match_config.rest_time
		local run_time = _match_info.run_time + (system.time() - _match_info.last_tick_time)
		if (_match_info.match_state <= tournament_redis.ENUM.MATCH_STATE.RANK_END) then
			in_ranking = true
			left_time = math.ceil((rank_time - run_time) / 1000)
		else
			in_ranking = false
			left_time = math.ceil((rank_time + rest_time - run_time) / 1000)
		end
		--防止时间返回负值或0
		if (left_time <= 0) then
			left_time = 1
		end
	end

	--返回
	return in_ranking, left_time
end

--获取比赛配置
GetConfig = function(_M, session, request)
	--初始化返回值
	local response = {header = {router = "Response"}}
	--检查合法性
	-- local filter_ret = RequestFilter.Filter("Tournament", "GetConfig", session, request, true)
	-- if filter_ret then
	-- 	response.ret = filter_ret
	-- 	return response
	-- end

	--回复的处理
	--获取数据
	local module_id_arr = request.module_id_arr --请求的游戏配置的数组
	local match_config_arr = {} --比赛的配置数组
	if (module_id_arr ~= nil) then
		for idx, module_id in ipairs(module_id_arr) do
			--初始化单个游戏的返回消息的配置
			local match_config_msg = {
				module_id = module_id,
				have_match = 0
			}
			--有比赛时才进行获取
			if (tournament_mem:IsGameHaveMatch(module_id)) then
				--从redis获取比赛的配置
				local match_config_mem = tournament_mem:GetMatchConfig(module_id)
				--将Redis取出的配置转换为消息结构的配置
				if (match_config_mem) then
					match_config_msg.have_match = 1
					match_config_msg.rank_time = math.ceil((match_config_mem.rank_time) / 1000)
					match_config_msg.rest_time = math.ceil((match_config_mem.rest_time) / 1000)
					match_config_msg.award_config_arr = table.DeepCopy(match_config_mem.award_config_arr)
					--得奖比例放大一定比例后用整形发送给客户端
					for _, award_config in pairs(match_config_msg.award_config_arr) do
						award_config.award_percent = math.floor(award_config.award_percent * 10000)
					end
				end
			end
			--填入返回信息表
			match_config_arr[idx] = match_config_msg
		end
	end
	--填入回复内容
	response.ret = Return.OK()
	response.match_config_arr = match_config_arr

	--返回
	return response
end

--请求排名信息
GetPlayerRank = function(_M, session, request)
	--初始化返回值
	local response = {header = {router = "Response"}}
	--检查合法性
	if (session.player == nil) then
		response.ret = Return.PLAYER_NOT_FOUND()
		return response
	end
	-- local filter_ret = RequestFilter.Filter("Tournament", "GetPlayerRank", session, request, true)
	-- if filter_ret then
	-- 	response.ret = filter_ret
	-- 	return response
	-- end

	--回复的处理
	--获取数据
	local module_id = request.module_id
	local player_id = session.player.id
	local have_match = tournament_mem:IsGameHaveMatch(module_id)
	local in_ranking = false
	local left_time = 0
	local prize_chips_in_pool = 0
	local game_player_num = 0
	local top3_player_arr = nil
	local near3_player_arr = nil
	if (have_match) then
		--获取比赛信息
		local match_info = tournament_mem:GetMatchInfo(module_id)
		if not match_info then --失败,返回错误
			response.ret = Return.TOURNAMENT_GET_MATCH_BASE_INFO_FAILED()
			return response
		end
		--处理返回需要用到的数据
		in_ranking, left_time = getMatchInRankAndTimeToClient(match_info)
		local chips_in_pool = match_info.chips_in_pool
		local chips_pool_prize_percent = match_info.match_config.pool_prize_percent
		prize_chips_in_pool = math.floor(chips_in_pool * chips_pool_prize_percent)
		game_player_num = tournament_mem:GetMatchPlayerNum(module_id)
		top3_player_arr, near3_player_arr = tournament_redis:GetTop3PlayerAndNear3PlayerInfo(module_id, player_id)
	end
	--填入回复内容
	response.ret = Return.OK()
	response.module_id = module_id
	response.have_match = have_match and 1 or 0
	response.in_ranking = in_ranking and 1 or 0
	response.left_time = left_time
	response.prize_chips_in_pool = prize_chips_in_pool
	response.game_player_num = game_player_num
	response.top3_player_arr = top3_player_arr
	response.near3_player_arr = near3_player_arr

	--返回
	return response
end

--领取奖励
GetPrize = function(_M, session, request)
	--初始化返回值
	local response = {header = {router = "Response"}}
	--检查合法性
	if (session.player == nil) then
		response.ret = Return.PLAYER_NOT_FOUND()
		return response
	end
	-- local filter_ret = RequestFilter.Filter("Tournament", "GetPrize", session, request, true)
	-- if filter_ret then
	-- 	response.ret = filter_ret
	-- 	return response
	-- end

	local task = session.task
	--回复的处理
	--获取数据
	local module_id = request.module_id
	local have_match = tournament_mem:IsGameHaveMatch(module_id)
	local player = session.player
	local player_id = player.id
	local in_ranking = false
	local left_time = 0
	local have_prize = false
	local had_received = false
	local prize_info = nil
	local prize_player = nil
	local curr_rank = 0
	local curr_win_scores = 0
	if (have_match) then
		--获取比赛信息
		local match_info = tournament_mem:GetMatchInfo(module_id)
		if not match_info then --仍然失败,返回错误
			response.ret = Return.TOURNAMENT_GET_MATCH_BASE_INFO_FAILED()
			return response
		end
		--处理返回需要用到的数据
		in_ranking, left_time = getMatchInRankAndTimeToClient(match_info)
		--非排名状态下才尝试领奖
		if (not in_ranking) then
			have_prize, had_received, prize_info = tournament_redis:PlayerTakePrize(module_id, player_id)
			--进行发奖
			if (have_prize and not had_received and prize_info) then
				Player:Obtain(player, {"Chip", prize_info.prize_chips}, Reason.Tournament_PRIZE())
				prize_player = {
					character = {
						chip = player.character.chip
					}
				}
				Player:BroadCastChip(session, task, 0, prize_info.prize_chips, 0) --广播桌上玩家筹码数
			end
		end
		--没有获奖的情况下，填入玩家的当前的排名和得分
		if (not have_prize) then
			curr_rank = tournament_redis:GetPlayerRank(module_id, player_id)
			curr_win_scores = tournament_redis:GetPlayerSocre(module_id, player_id)
		end
	end
	--回复填写
	response.ret = Return.OK()
	response.module_id = module_id
	response.have_match = have_match and 1 or 0
	response.in_ranking = in_ranking and 1 or 0
	response.left_time = left_time
	response.have_prize = have_prize and 1 or 0
	response.had_received = had_received and 1 or 0
	response.prize_info = prize_info
	response.prize_player = prize_player
	response.curr_rank = curr_rank
	response.curr_win_scores = curr_win_scores

	--返回
	return response
end
