--[[-------->>在线奖励管理器 纯静态]]
LobbyBonusV2RedisHelperClass = {
	ENUM = {
		REDIS_KEY = {
			PLAYERBONUSSTATE_MAP = "LobbyBonusV2_PlayerBonusState_Map" --开启在线奖励的游戏id数组
		}
	}
}
LobbyBonusV2RedisHelperClass.__index = LobbyBonusV2RedisHelperClass --补充索引器

do --共有有方法
	--Redis执行方法 单条
	--in[
	--	_task:传入的可用的task
	--	_operredis:操作语句 例如："HGET friend friend[1000]"等
	--]
	function LobbyBonusV2RedisHelperClass:RedisExcute(_task, ...)
		--初始化返回值
		local response = nil

		--进行redis操作
		if (LuaSession ~= nil) then
			--操作列表记录
			local oper_table = {...}
			--检测task是否可用
			if not task then
				local task = Task:Current()
			end
			--执行操作
			response = LuaSession:ContactJson("CacheClientService", task, oper_table, 0)
		else
			LOG(RUN, INFO).Format(
				"[LobbyBonusV2RedisHelperClass][RedisExcute] (LuaSession is nil time: %d",
				tonumber(os.date("%Y%m%d%H%M%S"))
			)
		end

		--返回
		return response
	end

	--查询玩家的奖励状态信息
	--in[
	--	_task：可用的task，用于执行redis操作
	--	_player_id：玩家id
	-- ]
	--out[
	--	info：玩家的状态信息
	-- ]
	function LobbyBonusV2RedisHelperClass:GetPlayerBonusStateInfo(_task, _player_id)
		--初始化返回值
		local info = nil

		--查询数据变量
		local key = self.ENUM.REDIS_KEY.PLAYERBONUSSTATE_MAP
		local oper = string.format("HGET %s %d", key, _player_id)
		--执行redis操作
		local response = self:RedisExcute(oper)
		if (response and response[1] and response[1] ~= "") then
			info = json.decode(response[1])
		end

		--返回
		return info
	end

	--设置玩家的奖励状态信息
	--in[
	--	_task：可用的task，用于执行redis操作
	--	_player_id：玩家id
	--	_info:：玩家的状态信息
	-- ]
	function LobbyBonusV2RedisHelperClass:SetPlayerBonusStateInfo(_task, _player_id, _info)
		local key = self.ENUM.REDIS_KEY.PLAYERBONUSSTATE_MAP
		local oper = string.format("HSET %s %d %s", key, _player_id, json.encode(_info))
		--执行redis操作
		self:RedisExcute(oper)
	end
end
--[[<<--------在线奖励帮助器]]
