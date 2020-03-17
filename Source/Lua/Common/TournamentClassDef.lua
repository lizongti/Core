--redis帮助类
local tournament_redis = TournamentRedisHelperClass

--比赛中需要用到的枚举
local ENUM = {
    MATCH_STATE = {
        UNKOWN = 0, --未知状态
        IN_RANK = 1, --玩家比赛排名中
        RANK_END = 2, --玩家排名结束
        IN_REST = 3, --休息中
        REST_END = 4, --休息结束
        MATCH_OVER = 5, --比赛结束
        PREPARE_NEXT = 6 --等待开启下一场比赛
    }
}

local REDIS_KEY = {
    GAME_IDWITHMATCH_SET = "Tournament_GameIdWitchMatch_Set", --开启锦标赛的游戏id数组
    GAME_BASE_INFO = "Tournament_BaseInfo_ModuleId", --比赛的基本信息
    GAME_PLAYERWINCHIP_SORTEDSET = "Tournament_PlayerWinChipSortedSet_ModuleId", --比赛玩家得分
    GAME_AllPLAYER_MAP = "Tournament_AllPlayerMAP_ModuleId", --参与比赛的玩家信息
    GAME_PLAYERPRIZEINFO_MAP = "Tournament_PlayerPrizeInfoMap_ModuleId", --玩家的奖励信息表
    GAME_PLAYERPRIZERECEIVE_SORTEDSET = "Tournament_PlayerPrizeReceiveSortedSet_ModuleId" --玩家的奖励领取状态表
}

--[[Tournament  各游戏的竞标赛
2018.12.10
]]
--[[-------->>单个游戏的玩家排名表]]
local GameRankInfoClass = {} --类的实体表
GameRankInfoClass.__index = GameRankInfoClass --补充索引器

do --私有方法
    --根据排名获取玩家的在奖池中的奖励百分比
    --in[
    --	_rank:玩家排名
    --]
    --out[
    --	percent:获奖占奖池的百分比
    --]
    function GameRankInfoClass:getPlayerAwardPercentInPoolByRank(_rank)
        --初始化返回值
        local percent = 0

        --填写返回值
        for _, award_config in ipairs(self.match_config.award_config_arr) do
            if (_rank >= award_config.min_rank and _rank <= award_config.max_rank) then
                percent = award_config.award_percent
                break
            end
        end

        --返回
        return percent
    end

    --通过邮件给玩家发送奖励
    --in[
    --	_module_id:游戏id
    --	_player_id:玩家id
    --	_prize_info:奖励信息
    --	_session:Manager会话信息
    -- ]
    function GameRankInfoClass:sendPrizeToPlayerByMail(_module_id, _player_id, _prize_info, _session)
        --拼接排名信息
        local rank = _prize_info.rank
        local rank_str = ""
        if (rank >= 1 and rank <= 3) then
            local tail_str = {"st", "nd", "rd"}
            rank_str = rank .. tail_str[rank]
        else
            rank_str = rank .. "th"
        end
        --奖励信息
        local props = json.encode({[1] = {1000, _prize_info.prize_chips}})

        if _session and _prize_info.prize_chips > 0 then --有筹码时，进行发放
            local packet = {
                header = {
                    router = "LocalRequest",
                    service_name = "BackstageService",
                    module_id = "Mail",
                    message_id = "Mail_TournamentPrize_Request"
                },
                player_id = _player_id,
                props = props,
                rank_str = rank_str,
                json_str = json.encode({_module_id = _module_id})
            }
            _session:WriteRouterPacket(packet)

            LOG(RUN, INFO).Format(
                "[GameRankInfoClass][sendPrizeToPlayerByMail] _module_id[%d] _player_id[%d] packet[%s]",
                _module_id,
                _player_id,
                Table2Str(packet)
            )
        else --没有筹码
            LOG(RUN, ERROR).Format(
                "[GameRankInfoClass][sendPrizeToPlayerByMail] _module_id[%d] _player_id[%d] win [%d]chip by rank[%d]",
                _module_id,
                _player_id,
                _prize_info.prize_chips,
                _prize_info.rank
            )
        end
    end
end
do --共有方法
    --构造方法
    function GameRankInfoClass:New(_module_id, _match_config)
        --初始化返回值
        local info = {
            ----需要存入redis的数据
            module_id = _module_id, --游戏id
            match_config = _match_config, --比赛配置
            last_tick_time = system.time(), --上次调用刷新的时间
            run_time = 0, --已经进行的时间
            match_state = ENUM.MATCH_STATE.IN_RANK, --比赛状态
            match_id = tonumber(os.date("%Y%m%d%H%M%S")), --比赛id
            chips_in_pool = 0, --奖池中的筹码数
            ----内存数据
            last_time_set_match_time = 0, --上次redis中设置比赛时间的时刻（定时存储比赛时间）
            --用于防止多协程重复更新的问题
            in_update = false, --是否正在更新比赛状态中
            in_update_time = 0 --进入更新状态的时间
        }
        --设置元表信息
        setmetatable(info, self)
        --保存进redis
        tournament_redis:DeleteRankAndPrizeInfo(_module_id)
        tournament_redis:SettMatchInfo(info)

        --返回
        return info
    end

    --从数据库恢复比赛信息
    function GameRankInfoClass:LoadFromDB(_module_id)
        --初始化返回值
        local info = nil

        --从数据库加载
        info = tournament_redis:GetMatchInfo(_module_id)

        if (info) then --加载成功
            --设置上次调用的时间为当前时间（避免停服时间较长的情况下，在开服后，计算run_time时，将停服时间计入）
            info.last_tick_time = system.time()
            --填入更新逻辑用到的控制变量（与比赛无关）
            info.last_time_set_match_time = 0 --上次redis中设置比赛时间的时刻（定时存储比赛时间）
            info.in_update = false
            info.in_update_time = 0
            --设置元表信息
            setmetatable(info, self)
        end

        --返回
        return info
    end

    --获取比赛配置
    --out[
    --	match_config:比赛配置
    --]
    function GameRankInfoClass:GetMatchConfig()
        --初始化返回值
        local match_config = self.match_config

        --返回
        return match_config
    end
    --更新比赛的运行时间
    --in[
    --  _forceWriteRedis:强制写入Redis
    --]
    function GameRankInfoClass:UpdateMatchRunTime(_forceWriteRedis)
        --更新内存
        local now_time = system.time()
        self.run_time = self.run_time + (now_time - self.last_tick_time)
        self.last_tick_time = now_time

        --更新Redis
        if _forceWriteRedis or (now_time - self.last_time_set_match_time >= 10000) then
            self.last_time_set_match_time = now_time --记录本次保存时间
            tournament_redis:SetMatchTime(self.module_id, self.last_tick_time, self.run_time) --更新数据
        end
    end
    --获取当前和下一个比赛状态
    --out[
    -- next_state:当前和下一个比赛状态
    --]
    function GameRankInfoClass:GetCurrAndNextMatchState()
        --初始化返回值
        local curr_state = self.match_state --当前游戏状态
        local next_state = self.match_state --下次状态默认为当前状态

        --下个比赛状态的获取
        local curr_satate = self.match_state
        local run_time = self.run_time --运行时间
        local rank_time = self.match_config.rank_time --排名竞赛时间
        local rest_time = self.match_config.rest_time --休息时间
        --根据当前比赛状态，由时间来判断
        if (curr_satate == ENUM.MATCH_STATE.IN_RANK) then
            if (run_time > rank_time) then
                next_state = ENUM.MATCH_STATE.RANK_END
            end
        elseif (curr_satate == ENUM.MATCH_STATE.RANK_END) then
            if (run_time - rank_time > 200) then --等待一段时间后进行发奖，并切换到休息
                next_state = ENUM.MATCH_STATE.IN_REST
            end
        elseif (curr_satate == ENUM.MATCH_STATE.IN_REST) then
            if (run_time > rank_time + rest_time) then
                next_state = ENUM.MATCH_STATE.REST_END
            end
        elseif (curr_satate == ENUM.MATCH_STATE.REST_END) then --休息结束后，服务器主动给获奖却没有确认奖励的玩家发送邮件，然后将比赛设置为比赛结束状态
            next_state = ENUM.MATCH_STATE.MATCH_OVER
        elseif (curr_satate == ENUM.MATCH_STATE.MATCH_OVER) then --休息结束后，服务器主动给获奖却没有确认奖励的玩家发送邮件，然后将比赛设置为比赛结束状态
            next_state = ENUM.MATCH_STATE.PREPARE_NEXT
        end

        --返回
        return curr_state, next_state
    end

    --设置比赛状态
    --in[
    -- _match_state:设置当前的比赛状态
    --]
    function GameRankInfoClass:SetMatchState(_match_state)
        if (self.match_state ~= _match_state) then
            --更新内存
            self.match_state = _match_state
            --更新Redis
            tournament_redis:SetMatchState(self.module_id, _match_state)
        end
    end

    --更新奖池中的筹码
    --in[
    --	_spin_chip:下注的筹码数
    --]
    function GameRankInfoClass:UpdateChipsInPool(_spin_chip)
        self.chips_in_pool = self.chips_in_pool + _spin_chip * self._match_config.pool_prize_percent
    end

    --生成玩家的奖励信息(包括玩家奖励信息表和领取记录表)
    function GameRankInfoClass:GeneratePlayerPrizeMapInRedis()
        --比赛配置
        local module_id = self.module_id
        local match_config = self.match_config
        local pool_chips = tournament_redis:GetChipsInPool(module_id)
        local prize_chips_all = math.floor(pool_chips * match_config.pool_prize_percent)

        --计算有奖的最大排名
        local max_rank_have_prize = 0
        for _, award_config in ipairs(match_config.award_config_arr) do
            if (award_config.max_rank > max_rank_have_prize) then
                max_rank_have_prize = award_config.max_rank
            end
        end

        --获取有奖玩家的得分排名信息
        local player_prize_map = {} --玩家的奖励Map
        local player_receive_map = {} --玩家奖励领取的Map
        local player_win_chip_map = tournament_redis:GetRankRangePlayerScoreMap(module_id, 1, max_rank_have_prize) --玩家的得分信息Map
        for rank, win_chip_info in pairs(player_win_chip_map) do
            --生成玩家的奖励信息
            local player_id = win_chip_info.id
            local prize_info = win_chip_info
            local award_percent = self:getPlayerAwardPercentInPoolByRank(rank)
            prize_info.prize_chips = math.floor(award_percent * prize_chips_all)
            --入表
            player_prize_map[player_id] = prize_info
            player_receive_map[player_id] = 0
        end

        --存入Redis
        tournament_redis:SetMatchPrize(module_id, player_prize_map, player_receive_map)
    end

    --向未领取的玩家发送奖励
    --in[
    --	_session:Manager会话信息
    -- ]
    function GameRankInfoClass:SendPrizeToNoReceivePlayer(_session, _module_id)
        --获取没有领奖的玩家数组
        local player_id_arr = tournament_redis:GetNoReceivePrizePlayerIdArr(_module_id)
        --获取没有领奖玩家的获奖信息
        local player_prize_map = tournament_redis:GetPlayerPrizeInfoMul(_module_id, player_id_arr)

        --通过邮件进行发奖
        -- local PlayerWatcherContainer = PlayerWatcher.PlayerWatcherContainer --玩家信息容器
        for player_id, prize_info in pairs(player_prize_map) do
            -- local player_info = PlayerWatcherContainer.players[player_id] --玩家信息
            -- if not (player_info and player_info.player_type == tonumber(ConstValue[5].value)) then ----玩家非机器人时才发送邮件奖励
            local take_success = tournament_redis:TryTakePrize(_module_id, player_id)
            if (take_success) then
                self:sendPrizeToPlayerByMail(_module_id, player_id, prize_info, _session)
            end
            -- end
        end
    end
end

--[[-------->>所有游戏的玩家排名表]]
local AllGameRankInfoClass = {} --类的实体表
AllGameRankInfoClass.__index = AllGameRankInfoClass --补充索引器
do --私有方法
    --尝试开启下一场比赛
    --in[
    -- _module_id:游戏id
    --]
    --out[
    -- have_next_game:是否有下一场比赛
    --]
    function AllGameRankInfoClass:tryStartNextMatch(_module_id)
        --返回值初始化
        local have_next_game = false

        --确定是否有下一场比赛
        local tournament_config = nil
        for _, game_tournament_map_info in ipairs(GameTournamentInfoMapConfig) do --遍历映射表，实例每个拥有比赛游戏的比赛信息
            if (game_tournament_map_info.module_id == _module_id) then
                local config_id = game_tournament_map_info.tournament_config_id
                if (GameTournamentInfoConfig[config_id] ~= nil) then
                    have_next_game = true
                    tournament_config = GameTournamentInfoConfig[config_id]
                end
                break
            end
        end
        --根据配置结果对下一场比赛进行操作
        if (have_next_game) then --有下一场比赛，则开启一个新的，废弃旧的
            local game_rank_info = GameRankInfoClass:New(_module_id, tournament_config) --初始化比赛信息
            self.game_rank_tab[_module_id] = game_rank_info --插入所有比赛信息的table中
        else --没有下一场比赛，则移除旧的比赛
        end

        --返回
        return have_next_game
    end
end

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

    --获取比赛配置
    --in[
    --	_module_id:游戏id
    --]
    --out[
    -- 	match_config:比赛配置
    --]
    function AllGameRankInfoClass:GetMatchConfig(_module_id)
        --初始化返回值
        local match_config = nil

        --返回赋值
        local match_info = self.game_rank_tab[_module_id]
        if (match_info) then
            match_config = match_info:GetMatchConfig()
        end

        --返回
        return match_config
    end

    --初始化比赛信息
    function AllGameRankInfoClass:InitMathInfo()
        --初始化返回值
        local init_success = false

        --进行初始化
        local module_id_arr_old = tournament_redis:GetAllHaveMachGameIdInRedis()
        if (module_id_arr_old ~= nil) then
            init_success = true --初始化成功
            --从缓存加载之前的游戏
            for _, module_id in pairs(module_id_arr_old) do
                local game_rank_info = GameRankInfoClass:LoadFromDB(module_id)
                if (game_rank_info) then
                    game_rank_info:UpdateMatchRunTime(true) --强制更新一边比赛的时间，使的Redis中的last_tick_time为当前值，避免中途停赛后，dispatcher从Reids中获取的last_tick_time为停赛之前的，导致本地计算的比赛时间很长，导致客户端显示异常
                    self.game_rank_tab[module_id] = game_rank_info --入表
                else
                    tournament_redis:RemoveHaveMachGameId(module_id) --移除在在全部比赛id列表中的记录
                    tournament_redis:DeleteMatchBaseInfo(module_id) --删除比赛的信息
                    tournament_redis:DeleteRankAndPrizeInfo(module_id) --删除排名和奖励的信息
                end
            end

            --读取游戏与比赛的索引表，初始配置中新加的游戏
            local add_module_id_arr = {} --新添加的比赛的游戏id
            for _, tournament_map_info in ipairs(GameTournamentInfoMapConfig) do --遍历映射表，实例每个拥有比赛游戏的比赛信息
                --读取配置
                local module_id = tournament_map_info.module_id --游戏id
                local tournament_config = GameTournamentInfoConfig[tournament_map_info.tournament_config_id] --比赛配置
                --实例化新加的游戏比赛信息并插入表中
                if (not self.game_rank_tab[module_id]) then --已经从缓存恢复的比赛跳过，只添加配置中新增比赛
                    local game_rank_info = GameRankInfoClass:New(module_id, tournament_config) --初始化比赛信息
                    self.game_rank_tab[module_id] = game_rank_info --插入所有比赛信息的table中
                    table.insert(add_module_id_arr, module_id) --插入到有比赛的游戏id数组中
                end
            end
            --保存redis
            if (#add_module_id_arr > 0) then
                tournament_redis:AddHaveMachGameIdArr(add_module_id_arr) --新添加的比赛游戏id存入redis
            end
        end

        --更新一边比赛
        self:UpdateMatchState()

        if (init_success) then
            LOG(RUN, INFO).Format("[AllGameRankInfoClass][InitMathInfo] success! ")
        else
            LOG(RUN, INFO).Format("[AllGameRankInfoClass][InitMathInfo] failed!!! ")
        end

        --返回
        return init_success
    end

    --更新比赛状态
    --in[
    --	session:Manager会话信息
    -- ]
    function AllGameRankInfoClass:UpdateMatchState(_session)
        --更新所有的现有比赛
        for module_id, game_rank_info in pairs(self.game_rank_tab) do
            --处理多协程重复更新的问题
            local can_update = false
            if (game_rank_info.in_update) then
                if (system.time() - game_rank_info.in_update_time > 10000) then --上次处理超时，直接跳过上次
                    can_update = true
                    game_rank_info.in_update_time = system.time() --记录进入时间
                end
            else
                can_update = true
                game_rank_info.in_update = true --设置标志量
                game_rank_info.in_update_time = system.time() --记录进入时间
            end

            if (can_update) then
                --更新比赛时间
                local forceWriteRedis = (next_state ~= curr_satate) --状态改变时，强制写入Redis
                game_rank_info:UpdateMatchRunTime(forceWriteRedis)
                --更新比赛状态
                local curr_satate, next_state = game_rank_info:GetCurrAndNextMatchState()
                if (next_state ~= curr_satate) then
                    if (next_state == ENUM.MATCH_STATE.RANK_END) then --排名结束，进行发奖操作
                        --首次从排名竞赛状态切换到结束状态时,先设置比赛状态，不直接发奖
                        --需要等待dispatcher同步比赛状态，防止在dispatcher在结束状态下，仍然在进行更新排名操作
                        game_rank_info:SetMatchState(next_state)
                    elseif (next_state == ENUM.MATCH_STATE.IN_REST) then --休息结束后，未确认获奖提示的玩家补发邮件
                        --排名结束状态的维持,则进行发奖
                        game_rank_info:GeneratePlayerPrizeMapInRedis() --生成奖励信息
                        game_rank_info:SetMatchState(next_state)
                    elseif (next_state == ENUM.MATCH_STATE.REST_END) then --休息结束后，未确认获奖提示的玩家补发邮件
                        game_rank_info:SetMatchState(next_state)
                    elseif (next_state == ENUM.MATCH_STATE.MATCH_OVER) then --比赛结束后，开启下一场比赛
                        game_rank_info:SendPrizeToNoReceivePlayer(_session, module_id) --给为未获奖用户发奖
                        game_rank_info:SetMatchState(next_state) --更新状态
                    elseif (next_state == ENUM.MATCH_STATE.PREPARE_NEXT) then --比赛结束后，开启下一场比赛
                        local have_next = self:tryStartNextMatch(module_id) --检查新的比赛
                        if (not have_next) then
                            self.game_rank_tab[module_id] = nil --更新内存信息
                            tournament_redis:RemoveHaveMachGameId(module_id) --更新有比赛的id数组redis记录
                            tournament_redis:DeleteMatchBaseInfo(module_id) --删除比赛的信息
                            tournament_redis:DeleteRankAndPrizeInfo(module_id) --删除排名和奖励的信息
                        end
                    end
                end
                --更新完毕，重置标志量
                game_rank_info.in_update = false
            end
        end
    end
end

--[[<<--------所有游戏的玩家排名表]]
--[[-------->>锦标赛管理器]]
TournamentManagerClass = {} --类的实体表
TournamentManagerClass.__index = TournamentManagerClass --补充索引器
do --共有方法
    --构造方法
    --in[
    --]
    function TournamentManagerClass:New()
        --初始化返回值
        local info = {
            init_success = false, --初始化是否成功
            is_initing = false, --是否在初始化中
            last_fresh_time = system.time(), --上次刷新的事件
            all_game_rank_info = AllGameRankInfoClass:New()
        }
        --设置元表信息
        setmetatable(info, self)

        --返回
        return info
    end

    --初始化比赛信息
    function TournamentManagerClass:InitMathInfo()
        if not self.is_initing then
            self.is_initing = true
            self.init_success = self.all_game_rank_info:InitMathInfo()
            self.is_initing = false
        end
    end

    --定时调用的计时器
    --in[
    --	_session:Manager会话信息
    -- ]
    function TournamentManagerClass:TimeTick(_session)
        --特殊处理逻辑,送审服不进行更新比赛状态
        --（防止正式服、送审服同时对Redis进行操作，出现两个控制比赛流程的进程导致比赛状态混乱的情况）
        if Base.Enviroment.pro_spec_t == "temporay" then --非送审服时，才进行更新比赛
            return
        end

        --定时调用
        local fresh_interval_time = 0.2 --每次刷新的事件间隔(秒)
        if (system.time() - self.last_fresh_time >= fresh_interval_time * 1000) then
            --设置刷新时间
            self.last_fresh_time = system.time()

            --执行逻辑
            if (self.init_success) then
                self.all_game_rank_info:UpdateMatchState(_session)
            else
                self:InitMathInfo()
            end
        end
    end
end
