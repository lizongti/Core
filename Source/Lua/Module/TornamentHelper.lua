--[[
Tornament  各游戏的竞标赛
2018.12.10
]]
--[[-------->>玩家得分信息类]]
local PlayerScoreInfoClass = {} --类的实体表
PlayerScoreInfoClass.__index = PlayerScoreInfoClass --补充索引器
do --共有方法
	-- 构造方法
	-- in[
	--	_id:玩家id
	--	_score:得分
	--	]
	function PlayerScoreInfoClass:New(_id, _score)
		--初始化返回值
		info = {
			id = _id, --玩家id
			score = _score
			--玩家得分
		}
		--设置元表信息
		setmetatable(info, self)

		--返回
		return info
	end
	-- 设置玩家得分
	-- in[
	--	_score:最新得分
	--]
	function PlayerScoreInfoClass:SetSocre(_score)
		self.score = _score
	end
end
--[[<<--------玩家得分信息类]]
--[[-------->>单个游戏的玩家排名表]]
local GameRankInfoClass = {} --类的实体表
GameRankInfoClass.__index = GameRankInfoClass --补充索引器

do --私有方法
	--更新排序表信息
	--in[
	--	change_socre_player_idx:改变分数玩家的索引
	--]
	function GameRankInfoClass:updateRankTab(change_socre_player_idx)
		--先移除改变玩家的数据
		local change_player_info = self.rank_player_tab[change_socre_player_idx]
		table.remove(self.rank_player_tab, change_socre_player_idx)
		--确定新数据插入的位置
		local insert_pos = 0
		for idx, info in ipairs(self.rank_player_tab) do
			if (change_player_info.score > info.score) then
				insert_pos = idx
				break
			end
		end
		--进行数据插入与原数据的移除
		if (insert_pos ~= 0) then --找到了位置
			table.insert(self.rank_player_tab, insert_pos, change_player_info)
		else --没有找到位置，得分最低，插入尾端
			table.insert(self.rank_player_tab, change_player_info)
		end

		--数组过大时进行剪切
		local player_num = #self.rank_player_tab
		while (player_num > self.match_config.rank_val_max) do
			table.remove(self.rank_player_tab, player_num) --移除最后一个元素
			player_num = player_num - 1
		end
		--更新最低分
		self.min_score = self.rank_player_tab[player_num].score --最后一名即为最低分
	end

	--添加玩家信息
	--in[
	--	_player_socre_info:玩家的得分信息
	--]
	--out[
	--	player_idx:添加玩家在表中的索引
	--]
	function GameRankInfoClass:addPlayerInfo(_player_socre_info)
		--初始化返回值
		local player_idx = 0

		--进入数据添加
		table.insert(self.rank_player_tab, _player_socre_info)
		player_idx = #self.rank_player_tab

		--返回
		return player_idx
	end
end
do --共有方法
	--构造方法
	function GameRankInfoClass:New(_match_config)
		--初始化返回值
		local info = {
			match_config = _match_config, --比赛配置、
			start_time = os.time(), --比赛开始时间
			match_id = os.data, --比赛id
			chips_in_pool = 0, --奖池中的筹码数
			rank_player_tab = {}, --玩家的排名表 【key：rank, val: PlayerScoreInfoClass 按照积分从高到低排序】
			min_score = 0 --所有玩家得分中最低的得分
		}
		--设置元表信息
		setmetatable(info, self)

		--返回
		return info
	end
	--更新奖池中的筹码
	--in[
	--	_spin_chip:下注的筹码数
	--]
	function GameRankInfoClass:UpdateChipsInPool(_spin_chip)
		self.chips_in_pool = self.chips_in_pool + _spin_chip * self._match_config.spin_chip_percent
	end
	--根据玩家id获取玩家的排名信息
	--in[
	--	_player_id:玩家id
	--]
	--out
	--	player_score_info:玩家得分信息（当不再tab中时，返回nil）
	--	player_rank:玩家信息在tab中的位置
	--]
	function GameRankInfoClass:GetPlayerRankInfoById(_player_id)
		--初始化返回值
		local player_score_info = nil
		local player_rank = 0

		--查询
		for idx, info in ipairs(self.rank_player_tab) do
			if (info.id == _player_id) then
				player_score_info = info
				player_rank = idx
				break
			end
		end

		--返回
		return player_score_info, player_rank
	end

	--更新玩家积分并进行获取排名
	--in[
	--	_match_id:比赛场次
	--	_player_id:玩家id
	--	_win_chip:赢取的筹码数
	--	_orgin_score:原始分数
	--]
	--out[
	--	curr_match_id:当前实际参加的场次
	--	player_id:玩家id
	--	curr_score:当前积分
	--	curr_rank:当前排名（返回0时，代表未上榜）
	--]
	function GameRankInfoClass:UpdatePlayerSocreAndGetRank(_match_id, _player_id, _win_chip, _orgin_score)
		--初始化返回值
		local curr_match_id = self.match_id
		local player_id = _player_id
		local curr_score = 0
		local curr_rank = 0

		--判断当前加分的比赛场次是否已经过期
		if (_match_id ~= self.match_id) then
			_orgin_score = 0 --原始积分清零
		end
		--计算玩家得分后的积分并累计奖池
		curr_score = _orgin_score + _win_chip
		--尝试更新玩家的排序表
		local needSortInTab = false --是否需要加入table进行排序
		local player_score_info, player_rank = self:GetPlayerRankInfoById(_player_id) --玩家在table中的信息
		local change_socre_player_idx = 0 --改变分数的玩家在table中的索引
		if (player_score_info) then --在表中
			needSortInTab = true
			player_score_info.SetSocre(curr_score) --设置当前的积分
			change_socre_player_idx = player_rank --设置当前玩家的索引
		else --不在表中
			if (#(self.rank_player_tab) < self.match_config.rank_val_max or curr_score > self.min_score) then --表的人数未满或者满了但是得分大于最低分，则有资格参加排序
				needSortInTab = true
				local new_player_info = PlayerScoreInfoClass:New(_player_id, curr_score)
				change_socre_player_idx = self:addPlayerInfo(new_player_info)
			else --低于最低分，则不参加排序
			end
		end
		--获得玩家排名
		if (needSortInTab) then
			self:updateRankTab(change_socre_player_idx)
			_, curr_rank = self:GetPlayerRankInfoById(_player_id)
		end

		--返回
		return curr_match_id, player_id, curr_score, curr_rank
	end
end
--[[<<--------单个游戏的玩家排名表]]
function GameRankInfoClass:Print()
	print("\n\n")
	for rank, info in ipairs(self.rank_player_tab) do
		print("matchId=" .. self.match_id .. " pid=" .. info.id .. " score=" .. info.score .. " rank=" .. rank)
	end
	print("\n\n")
end

--[[-------->>所有游戏的玩家排名表]]
local AllGameRankInfoClass = {} --类的实体表
AllGameRankInfoClass.__index = AllGameRankInfoClass --补充索引器
do --共有方法
	--构造方法
	function AllGameRankInfoClass:New()
		--初始化返回值
		local info = {
			game_rank_tab = {}
		}
		--设置元表信息
		setmetatable(info, self)

		--返回
		return info
	end

	--初始化方法
	function AllGameRankInfoClass:Init()
	end
end

--[[<<--------所有游戏的玩家排名表]]
