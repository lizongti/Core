require "Common/Return"
require "Common/DailyMissionsCal"
require "Common/RequestFilter"
require "Common/LineNum"
require "Common/FrdCal"
require "Common/PaymentCal"
require "Config/ServerConfig"
module("LobbyBonus", package.seeall)

------------------------大厅奖励---------------------------------
Collect = function(_M, session, request)
    local response = {header = {router = "Response"}}
    local filter_ret = RequestFilter.Filter("LobbyBonus", "Collect", session, request, true)
    if filter_ret then
        response.ret = filter_ret
        return response
    end
    local player = session.player

    
    local ret, total_chip = CommonCal.Calculate.Collect(session, player, 0)
    if (ret < 0) 
    then
        response.ret = Return.LOBBYBONUS_CANNOT_COLLECT()
        return response
    end

    if (total_chip > 0)
    then

        Player:Obtain(player, {"Chip", total_chip}, Reason.LOBBYBONUS_COLLECT_OBTAIN())
    end

    response.chip_get = total_chip
    response.ret = Return.OK()
    response.player = {
        character = {
            chip = player.character.chip,
        }
    }

    return response
end

Display = function(_M, session, request)
    local response = {header = {router = "Response"}}
    local filter_ret = RequestFilter.Filter("LobbyBonus", "Display", session, request, true)
    if filter_ret then
        response.ret = filter_ret
        return response
    end

    local current_time = os.time()
    local next_collect_time = 0
    local player = session.player

    if (player.character.collect_times < #CollectTimesConfig) then
        local dur_time = tonumber(ConstValue[21].value)
        next_collect_time = player.character.last_collect_time + dur_time
    else
        local daily_last_collect_date = os.date("*t", player.character.last_collect_reset_time)
		next_collect_time =
		os.time(
			{
				year = daily_last_collect_date.year,
				month = daily_last_collect_date.month,
				day = daily_last_collect_date.day + 1,
				hour = 3,
				min = 0,
				sec = 0
			}
        )
    end

    local acc_seconds = next_collect_time - current_time

    if (acc_seconds < 0) then
        acc_seconds = 0
    end
    if acc_seconds == 0 then
        response.can_collect = 1

        ------------------根据等级领取奖励---------------
        local display_collect = player.character.collect_times + 1
        if (display_collect > #CollectTimesConfig) then
            display_collect = #CollectTimesConfig
        end

        local level = player.character.level
        local sel_lv = 0
        for lv, award_value in pairs(CollectTimesConfig[display_collect].level_award) do
            if (lv <= level) then
                if (sel_lv < lv) then
                    sel_lv = lv
                end
            end
        end
        local chip_may_get = CollectTimesConfig[display_collect].level_award[sel_lv]

        ----VIP加成
        local vip = player.character.vip
        local extra_percent = VIPConfig[vip].lobby_bonus
        response.chip_may_get = chip_may_get + chip_may_get * extra_percent
    else
        response.can_collect = 0
    end

    if not os.same_day(player.character.last_collect_reset_time, current_time) 
    then
        player.character.last_collect_reset_time = current_time
        player.character.collect_times = 0
    end


    
    response.acc_seconds = acc_seconds
    response.collect_times = player.character.collect_times
    response.ret = Return.OK()

    return response
end

IgnoreOrAcceptFrd = function(_M, session, request)
    local response = {header = {router = "Response"}}
    local task = session.task
    local player = session.player 
    local action = tonumber(request.action)
    local fid = request.frd_id
    
    if (action == 0)--解除好友关系
    then
        local async_request = {
            [1] = {
                sql = string.format("delete from slots.friend_ralationship_%s where uid = %s and fid = %s", math.mod(player.id, 16), player.id, fid)
            },
            [2] = {
                sql = string.format("delete from slots.friend_ralationship_%s where uid = %s and fid = %s", math.mod(fid, 16), fid, player.id)
            },
        }
    
        local async_response = session:ContactJson("DatabaseClientService", task, async_request, player.id)
    elseif (action > 0)--同意好友申请
    then
        local async_request = {
            [1] = {
                sql = string.format("update slots.friend_ralationship_%s set status = 1 where uid = %s and fid = %s", math.mod(player.id, 16), player.id,  fid)
            },
            [2] = {
                sql = string.format("update slots.friend_ralationship_%s set status = 1 where uid = %s and fid = %s", math.mod(fid, 16), fid, player.id)
            },
        }
        
        local async_response = session:ContactJson("DatabaseClientService", task, async_request, player.id)
        if (async_response[1].row_num < 0 or async_response[2].row_num < 0)
        then
            --response.ret = Return.LOBBYBONUS_NOT_FRD()--不是好友
            response.ret = Return.OK()
            return response
        end
        
        --local frdInfo = FrdCal.Calculate.GetFriendInfo(task, session, fid)
        local async_request = {
            header = {
                router = "LocalRequest",
                service_name = "DispatcherService",
                task_id = task.id,
                module_id = "Friend",
                message_id = "Friend_Get_Request",
            },
            fid = fid
        }

        local async_response = session:ContactPacket(task, async_request)
        local frdInfo = async_response.player

        if (frdInfo ~= nil)
        then
            response.friend = frdInfo
        end


        
    end

    -------------------------通知好友ID列表给双方------------------------------
    local async_request = {
        header = {
            router = "AsyncRequest",
            service_name = "ManagerClientService",
            task_id = task.id,
            module_id = "PlayerWatcher",
            message_id = "PlayerWatcher_FrdList_Request",
        },
        player_id = player.id,
        friend_id = fid,
    }
    local async_response = session:ContactPacket(task, async_request)
    if async_response.ret.code ~= 0 then
        response.ret = Return.PLAYER_NOT_FOUND()
        return response
    end


    response.ret = Return.OK()
    return response
end

InviteFrd = function(_M, session, request)
    local response = {header = {router = "Response"}}

    local task = session.task
    local player = session.player 
    local frd_id_list = request.frd_id_list

    local game_type = player.game_type
    local channel_id = ""

	if (game_type > 0)
    then
        channel_id = CommonCal.Calculate.get_game_info(session, task, player, game_type).channel_id
    else
        response.ret = Return.PLAYER_NOT_FOUND()
        return response
	end

    local my_table_id = 0
    if (string.len(channel_id) > 5)
	then
		local contest_id, room_id, table_id = unpack(string.split(channel_id, "."))
		my_table_id = tonumber(table_id)
    end
    
    local async_request = {
        header = {
            router = "AsyncRequest",
            service_name = "ManagerClientService",
            task_id = task.id,
            module_id = "PlayerWatcher",
            message_id = "PlayerWatcher_InviteFrd_Request",
        },
        player = FrdCal.Calculate.Player2FrdDetail(player),
        table_id = my_table_id,
        frd_id_list = frd_id_list,
    }
    local async_response = session:ContactPacket(task, async_request)
    if async_response.ret.code ~= 0 then
        response.ret = Return.PLAYER_NOT_FOUND()
        return response
    end
    response.ret = Return.OK()

    return response	
end

FrdInfo = function(_M, session, request)
    local response = {header = {router = "Response"}}

    local task = session.task
    local player = session.player 
    local frd_id = request.frd_id

    --是否已经是好友
    local async_request = {
		[1] = {
			sql = string.format("select * from slots.friend_ralationship_%s where uid = %s and fid = %s", math.mod(player.id, 16), player.id, frd_id)
		},
    }

    local async_response = session:ContactJson("DatabaseClientService", task, async_request, player.id)
	if async_response[1].row_num <= 0 then
		response.ret = Return.LOBBYBONUS_NOT_FRD()			
		return response
    end 
    local name = string.format("player[%s]", frd_id)
	local proto_func = _G["Player_pb"]["Player"]
    local async_request = TableCache:GetBuildCommand(name, proto_func)
   -- LOG(RUN, INFO).Format("[LobbyBonus][FrdInfo] frd_id %s, async_request211 is: %s", frd_id, Table2Str(async_request))
	local async_response = session:ContactJson("CacheClientService", task, async_request, player.id)
    local friend = TableCache:BuildTable(async_response, name, proto_func)

    --if (not friend.id)
    --then
    local async_request = {
        header = {
            router = "AsyncRequest",
            service_name = "ManagerClientService",
            task_id = task.id,
            module_id = "PlayerWatcher",
            message_id = "PlayerWatcher_FrdInfo_Request",
        },
        frd_id = frd_id,
    }

    async_response = session:ContactPacket(task, async_request)
    if async_response.ret.code ~= 0 then
        response.ret = Return.PLAYER_NOT_FOUND()
        return response
    end

    response.ret = Return.OK()
    if (async_response.game_type == 0)--玩家不在线上，肯定没有玩游戏
    then
        response.game_type = async_response.game_type
        response.table_id = async_response.table_id
        response.player = async_response.player
    else
        local game_type = friend.game_type
        local channel_id = ""
        if (game_type and game_type > 0)
        then
            response.game_type = game_type
        end
        response.player = FrdCal.Calculate.Player2FrdDetail(friend)
        if (game_type and game_type > 0)
        then
            channel_id = CommonCal.Calculate.get_game_info(session, task, friend, game_type).channel_id
            ---channel_id = friend[GameRoomConfig[game_type].key_name].channel_id
        end

        if (string.len(channel_id) > 5)
        then
            local contest_id, room_id, table_id = unpack(string.split(channel_id, "."))
            table_id = tonumber(table_id)
            if (table_id > 0)
            then
                response.table_id = table_id
            end
        end
    end
 
    return response


end

OnlineFrdList = function(_M, session, request)
    local response = {header = {router = "Response"}}

    local player = session.player 

    local task = session.task

    local async_request = {
		[1] = {
			sql = string.format("select id, uid, fid, status from slots.friend_ralationship_%s where uid = %s and status = 1", math.mod(player.id, 16), player.id)
		},
    } 
    local async_response = session:ContactJson("DatabaseClientService", task, async_request, player.id)
	if async_response[1].row_num <= 0 then
        response.ret = Return.OK()
        response.friend_list = {}		
		return response
    end
    local data_set = async_response[1].data_set

    local friend_list = {}

    for k, v in pairs(data_set)
    do
        --local frdInfo = FrdCal.Calculate.GetFriendInfo(task,session, v[3])
        local async_request = {
            header = {
                router = "LocalRequest",
                service_name = "DispatcherService",
                task_id = task.id,
                module_id = "Friend",
                message_id = "Friend_Get_Request",
            },
            fid = v[3]
        }

        local async_response = session:ContactPacket(task, async_request)
        local frdInfo = async_response.player

        if (frdInfo ~= nil)
        then
            local frd_id = v[3]
            local name = string.format("player[%s]", frd_id)
            local proto_func = _G["Player_pb"]["Player"]
            local async_request = TableCache:GetBuildCommand(name, proto_func)
            --LOG(RUN, INFO).Format("[LobbyBonus][FrdInfo] frd_id %s, async_request211 is: %s", frd_id, Table2Str(async_request))
            local async_response = session:ContactJson("CacheClientService", task, async_request, player.id)
            local friend = TableCache:BuildTable(async_response, name, proto_func)
            
            if (friend.id)
            then
                local game_type = friend.game_type
                local channel_id = ""
                local my_channel_id = ""
                if (game_type and game_type > 0)
                then
                    channel_id = CommonCal.Calculate.get_game_info(session, task, friend, game_type).channel_id
                    my_channel_id = CommonCal.Calculate.get_game_info(session, task, player, game_type).channel_id
                end
            
                if (string.len(channel_id) > 5)
                then
                    local contest_id, room_id, table_id = unpack(string.split(channel_id, "."))
                    local my_contest_id, my_room_id, my_table_id = unpack(string.split(my_channel_id, "."))
                    my_table_id = tonumber(my_table_id)
                    table_id = tonumber(table_id)

                    if ((table_id ~= my_table_id) or (game_type ~= player.game_type))
                    then
                        table.insert(friend_list, frdInfo)
                    end
                else
                    table.insert(friend_list, frdInfo)
                end
            end
        end
    end 

    local async_request = {
        header = {
            router = "AsyncRequest",
            service_name = "ManagerClientService",
            task_id = task.id,
            module_id = "PlayerWatcher",
            message_id = "PlayerWatcher_OnlineFrdList_Request",
        },
        friend_list = friend_list,
    }
    local async_response = session:ContactPacket(task, async_request)
    if async_response.ret.code ~= 0 then
        response.ret = Return.PLAYER_NOT_FOUND()
        return response
    end

    response.friend_list = async_response.friend_list
    response.ret = Return.OK()
    return response
end

FrdList = function(_M, session, request)
    local response = {header = {router = "Response"}}

    local player = session.player 

    local task = session.task
    local async_request = {
		[1] = {
			sql = string.format("select id, uid, fid, status from slots.friend_ralationship_%s where uid = %s and status = 1", math.mod(player.id, 16), player.id)
		},
    }
    local async_response = session:ContactJson("DatabaseClientService", task, async_request, player.id)
	if async_response[1].row_num <= 0 then
        response.ret = Return.OK()
        response.friend_list = {}		
		return response
    end
    
    local data_set = async_response[1].data_set

    local friend_list = {}

    for k, v in pairs(data_set)
    do
        --local frdInfo = FrdCal.Calculate.GetFriendInfo(task,session, v[3])
        local async_request = {
            header = {
                router = "LocalRequest",
                service_name = "DispatcherService",
                task_id = task.id,
                module_id = "Friend",
                message_id = "Friend_Get_Request",
            },
            fid = v[3]
        }

        local async_response = session:ContactPacket(task, async_request)
        local frdInfo = async_response.player

        if (frdInfo ~= nil)
        then
            table.insert(friend_list, frdInfo)
        else
            LOG(RUN, INFO).Format("[LobbyBonus][ApplyFrd] player %s, player error", player.id)
        end
    end 

    if (#friend_list > 0)
    then
        local async_request = {
            header = {
                router = "AsyncRequest",
                service_name = "ManagerClientService",
                task_id = task.id,
                module_id = "PlayerWatcher",
                message_id = "PlayerWatcher_IdentifyFrd_Request",
            },
            friend_list = friend_list,
        }
        async_response = session:ContactPacket(task, async_request)

        response.online_friend_list  = async_response.online_friend_list
        response.offline_friend_list = async_response.offline_friend_list

    end

    response.ret = Return.OK()
    return response
end

Jackpot = function(_M, session, request)
    local response = {header = {router = "Response"}}

    local player = session.player 
    local task = session.task

    local NUM_FLAG = 1--10000.0
    local alicein_wonderland_jackpot = 0
    for selIndex = 1, #AliceinWonderlandJackpotBetConfig do
        local GJackpotK = "AliceWonderJackpot.Amount"..selIndex
        local curValue = GlobalState:GetLatest(GJackpotK)  / NUM_FLAG
        if (alicein_wonderland_jackpot < curValue)
        then
            alicein_wonderland_jackpot = curValue
        end
    end

    local elves_epic_jackpot = 0
    for selIndex = 1, #AliceinWonderlandJackpotBetConfig do
        local GJackpotK = "Jackpot.Amount"..selIndex
        local curValue = GlobalState:GetLatest(GJackpotK)  / NUM_FLAG
        if (elves_epic_jackpot < curValue)
        then
            elves_epic_jackpot = curValue
        end
    end

    response.alicein_wonderland_jackpot = alicein_wonderland_jackpot
    response.elves_epic_jackpot = elves_epic_jackpot

    response.ret = Return.OK()
    return response
end

CashCasino = function(_M, session, request)
    local response = {header = {router = "Response"}}

    -- local player = session.player 
    -- local task = session.task

    -- local chips = request.chips

    -- local currentTime = os.time()

    -- if (player == nil) then
    --     response.ret = Return.HAVE_ALREADY_EXIT_GAME()
    --     return response        
    -- end
    -- local old_chip = player.character.chip
    -- ------------------只能是每天领10次, 单次金额不能超过1万----------------------
    -- local lastTime = CommonCal.Calculate.convertTimeForm(player.cash_casino_time)
    -- local curTime = CommonCal.Calculate.convertTimeForm(currentTime)
    -- if (curTime ~= lastTime)
    -- then
    --     player.cash_casino_number = 0
    -- end
    -- if (player.cash_casino_number >= CashCasinoConfig[1].max_number)
    -- then
    --     response.ret = Return.CASH_CASINO_TOO_BIG()
    --     return response
    -- end

    -- if (chips > CashCasinoConfig[1].max_chip)
    -- then
    --     response.ret = Return.CASH_CASINO_TOO_BIG()
    --     return response
    -- end
    

    -- Player:Obtain(player, {"Chip", chips}, Reason.CASH_CASINO_OBTAIN())
    -- player.cash_casino_chips = player.cash_casino_chips + chips
    -- player.cash_casino_time = currentTime
    -- player.cash_casino_number = player.cash_casino_number + 1

    -- session:WriteRouterPacket({
    --     header = {
    --         router = "SpecificNotice",
    --         session_id = session.id,
    --         player_id = player.id,
    --         module_id = "Command",
    --         message_id = "Command_Player_Notice",
    --     },
    --     player = {
    --         cash_casino_time = player.cash_casino_time,
    --         cash_casino_chips = player.cash_casino_chips,
    --         cash_casino_number = player.cash_casino_number,
    --         character = {
    --             chip = player.character.chip,
    --         },
    --     },
    --     collect_chip = player.character.chip - old_chip
    -- })

    response.ret = Return.OK()
    return response
end

ApplyFrd = function(_M, session, request)
    local response = {header = {router = "Response"}}


    local player = session.player 

    local task = session.task

    local async_request = {
		[1] = {
			sql = string.format("select id, uid, fid, status from slots.friend_ralationship_%s where uid = %s and (status = 0 or status = 2)", math.mod(player.id, 16), player.id)
		},
    }
    local async_response = session:ContactJson("DatabaseClientService", task, async_request, player.id)
	if async_response[1].row_num <= 0 then
        response.ret = Return.OK()
        response.friend_list = {}		
		return response
    end
    local data_set = async_response[1].data_set

    local friend_list = {}

    for k, v in pairs(data_set)
    do
        --local frdInfo = FrdCal.Calculate.GetFriendInfo(task, session, v[3])
        local async_request = {
            header = {
                router = "LocalRequest",
                service_name = "DispatcherService",
                task_id = task.id,
                module_id = "Friend",
                message_id = "Friend_Get_Request",
            },
            fid = v[3]
        }

        local async_response = session:ContactPacket(task, async_request)

        local frdInfo = async_response.player
        
        if (frdInfo ~= nil)
        then
            table.insert(friend_list, frdInfo)
        end
    end 

    response.friend_list = friend_list
    response.ret = Return.OK()
    return response
end

AddFrd = function(_M, session, request)
    local response = {header = {router = "Response"}}

    local frd_id = request.frd_id
    local player = session.player 

    local task = session.task

    if (player.id == frd_id)
    then
        response.ret = Return.LOBBYBONUS_CAN_NOT_ADD_SELF()
        return response
    end
    -----------------------是否存在该好友玩家-----------------------------
    local redis_request = {
        [1] = string.format("HGET Player[%s] Player[%s].id", frd_id, frd_id),
    }
    local redis_response = session:ContactJson("CacheClientService", task, redis_request, player.id)
    if (not redis_response[1] or redis_response[1] == "")
    then
        local async_request = {
            [1] = {
                sql = string.format("select * from slots.club_player_info where player_id = %s", frd_id)
            },
        }
        local async_response = session:ContactJson("DatabaseClientService", task, async_request, player.id)
        if async_response[1].row_num == 0 then
            response.ret = Return.ACCOUNT_TOKEN_NOT_EXIST()
            return response
        end
    end
    --------------------------------------------------------------------
    --是否已经是好友
    local async_request = {
		header = {
			router = "AsyncRequest",
			service_name = "ManagerClientService",
			task_id = task.id,
			module_id = "FriendPasser",
			message_id = "FriendPasser_AddFriend_Request",
		},
		player_id = frd_id,
    }

	local async_response = session:ContactPacket(task, async_request)
	if async_response.ret.code ~= 0 then
        response.ret = async_response.ret
        LOG(RUN, INFO).Format("[LobbyBonus][AddFrd] end send to manager player is: %s, frd_id is: %s failed", player.id, frd_id)
		--return response
    end
    
    local async_request = {
		[1] = {
			sql = string.format("select * from slots.friend_ralationship_%s where uid = %s and fid = %s", math.mod(player.id, 16), player.id, frd_id)
		},
    }
    local async_response = session:ContactJson("DatabaseClientService", task, async_request, player.id)
	if async_response[1].row_num > 0 then
        local async_request = {
            [1] = {
                sql = string.format("update slots.friend_ralationship_%s set status = 2 where uid = %s and fid = %s", math.mod(frd_id, 16), frd_id,  player.id)
            },
        }
        local async_response = session:ContactJson("DatabaseClientService", task, async_request, player.id)
    
        response.ret = Return.OK()
        --response.ret = Return.LOBBYBONUS_HAVE_APPLY()	
		return response
	end

	async_request = {
		[1] = {
			sql = string.format("insert into slots.friend_ralationship_%s(uid, fid, status) values(%s, %s, %s)", math.mod(player.id, 16), player.id, frd_id, 3)
        },
        [2] = {
			sql = string.format("insert into slots.friend_ralationship_%s(uid, fid, status) values(%s, %s, %s)", math.mod(frd_id, 16), frd_id, player.id, 0)
        },
    }
    async_response = session:ContactJson("DatabaseClientService", task, async_request, player.id)
	if async_response[1].row_num < 0 or async_response[2].row_num < 0 then
		response.ret = Return.ACCOUNT_DATABASE_ERROR()			
		return response
    end


    response.ret = Return.OK()

    return response
end

UnLock = function(_M, session, request)
    local response = {header = {router = "Response"}}
    local filter_ret = RequestFilter.Filter("LobbyBonus", "UnLock", session, request, true)
    if filter_ret then
        response.ret = filter_ret
        return response
    end

    response.ret = Return.OK()
    return response
end

Multiply = function(_M, session, request)
    local response = {header = {router = "Response"}}
    local filter_ret = RequestFilter.Filter("LobbyBonus", "Multiply", session, request, true)
    if filter_ret then
        response.ret = filter_ret
        return response
    end

    local player = session.player

    local old_chip = player.character.chip
    LOG(RUN, INFO).Format("[LobbyBonus][Multiply] player id is:%s, player game type is: %s", player.id, player.game_type) 
    if (player.game_type <= 0)
    then
        response.ret = Return.SERVER_NEAR_MAINENANCE()
        return response
    end

    local game_type = player.game_type
    local amount = request.amount

    local linenum = LineNum[game_type]()

    if (linenum == 0)
    then
        response.ret = Return.LOBBYBONUS_CANNOT_MULTIPLY()
        return response
    end

    local chip_mount = amount * linenum
    local config = nil
    --local needDiamond = 0

    local mega_win_chips = json.decode(player.mega_win_chips)
    LOG(RUN, INFO).Format("[LobbyBonus][Multiply] player id is:%s, mega_win_chips is: %s", player.id, player.mega_win_chips) 
    if (#mega_win_chips == 0)
    then
        response.ret = Return.LOBBYBONUS_NOT_MEGA_WIN()
        return response
    end

    local mega_win_value = tonumber(mega_win_chips[1])

    local multiply_prize_config = nil
    for k, v in pairs(MultiplePrizeConfig) do
        if (mega_win_value > v.min_chip and mega_win_value <= v.max_chip)
        then
            multiply_prize_config = v
            if (k == 1)
            then
                config = MultipleAward1Config
            elseif (k == 2)
            then
                config = MultipleAward2Config
            elseif (k == 3)
            then
                config = MultipleAward3Config
            elseif (k == 4)
            then
                config = MultipleAward4Config
            elseif (k == 5)
            then
                config = MultipleAward5Config
            elseif (k == 6)
            then
                config = MultipleAward6Config
            elseif (k == 7)
            then
                config = MultipleAward7Config
            elseif (k == 8)
            then
                config = MultipleAward8Config
            elseif (k == 9)
            then
                config = MultipleAward9Config
            elseif (k == 10)
            then
                config = MultipleAward10Config
            elseif (k == 11)
            then
                config = MultipleAward11Config
            elseif (k == 12)
            then
                config = MultipleAward12Config
            elseif (k == 13)
            then
                config = MultipleAward13Config
            end
            --needDiamond = v.diamonds
        end
    end
    if (config == nil)
    then
        response.ret = Return.LOBBYBONUS_CANNOT_COLLECT()
        return response
    end

   
    player.mega_win_number = 0
    
    
    --if (player.mega_win_number >= 3)
    --then
    --    response.ret = Return.LOBBYBONUS_CANNOT_MULTIPLY()
    --    return response
    --end

    --player.mega_win_number = 0


    table.remove(mega_win_chips, 1)
    player.mega_win_chips = json.encode(mega_win_chips)


    local local_weight_tab = {}
    for k, v in pairs(config) do
        local_weight_tab[k] = v.weight_value
    end
    --Player:Consume(player, {"Diamond", needDiamond}, Reason.LOBBYBONUS_MULTIPLY_CONSUME())

    local task_req_data = {
        buy_multiply_win = 1
    }
    DailyTask:CompleteTask(session, player, task_req_data)
    
    --local local_weight_tab = {[1] = config[1].weight_value, [2] = config[2].weight_value, [3] = config[3].weight_value, [4] = config[4].weight_value, [5] = 0.1, [6] = 0.1, [7] = 0.1}
    local local_index = math.rand_weight(player, local_weight_tab)
    
    local multiply = config[local_index].mutiple

    LOG(RUN, INFO).Format("[LobbyBonus][Multiply] player id is:%s, config is: %s", player.id, Table2Str(config[local_index])) 
    local win_amount = mega_win_value * (multiply - 1)

    LOG(RUN, INFO).Format("[LobbyBonus][Multiply] player id is:%s, player chip is: %s, win_amount is: %s", player.id, player.character.chip, win_amount) 
    Player:Obtain(player, {"Chip", win_amount}, Reason.LOBBYBONUS_MULTIPLY_OBTAIN())
     


    response.ret = Return.OK()
    response.conf_index = local_index
    response.amount = mega_win_value * multiply --仅仅显示用
    response.goods_id = multiply_prize_config.goods_id
    response.diff_amount = win_amount
    response.player = {
        character = {
            chip = player.character.chip,
        },
    }
    LOG(RUN, INFO).Format("[LobbyBonus][Multiply] player id is:%s, response is: %s", player.id, Table2Str(response)) 
    return response
end 

LoginAward = function(_M, session, request)
    local response = {header = {router = "Response"}}
    local filter_ret = RequestFilter.Filter("LobbyBonus", "LoginAward", session, request, true)
    if filter_ret then
        response.ret = filter_ret
        return response
    end

    local player = session.player
    --LOG(RUN, INFO).Format("[LobbyBonus][LoginAward] player_id:%s, chip is: %s", player.id, player.character.chip)

    if (player.character.login_award_time < player.character.off_line_time)
	then
		local off_line_seconds = os.time() - player.character.off_line_time
		player.character.login_award_time = player.character.login_award_time + off_line_seconds
		player.character.off_line_time = 0
	end
    player.character.login_award_seconds = os.time() - player.character.login_award_time
    if (player.character.login_award_seconds < 1800)
    then
        response.player = {
            character = {
                chip = player.character.chip,
                login_award_seconds = player.character.login_award_seconds,
            }
        }
        response.ret = Return.LOBBYBONUS_CANNOT_GET_LOGIN_AWARD()
        return response
    end

    Player:Obtain(player, {"Chip", 20000}, Reason.LOBBYBONUS_LOGIN_AWARD_OBTAIN())
    player.character.login_award_time = os.time()

    player.character.login_award_seconds = 0
    response.ret = Return.OK()
    response.player = {
        character = {
            chip = player.character.chip,
            login_award_seconds = player.character.login_award_seconds,
        }
    }
    return response
end


--获取存钱罐的状态
local getPotStat = function(player, currentTime)
    local left_limit_time = 0   --存钱罐到期剩余时间
    local left_collect_time = 0 --存钱罐可领取剩余时间



    return 0, left_limit_time, left_collect_time
end

--每隔一段时间获取存钱罐的状态
PotCountDown = function(_M, session, request)
    local response = {header = {router = "Response"}}
    if not session or not session.player then
        response.ret = Return.PLAYER_NOT_FOUND()
        return response
    end

    local player = session.player
    local task = session.task
        
    response.ret = Return.OK()


	return response
end

CollectPot = function(_M, session, request)
    local response = {header = {router = "Response"}}
    local filter_ret = RequestFilter.Filter("LobbyBonus", "CollectPot", session, request, true)
    if filter_ret then
        response.ret = filter_ret
        return response
    end

    local player = session.player
    local current_time = os.time()

    return response
end

