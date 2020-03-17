require "Common/SlotsWorldCupCal"
require "Common/RequestFilter"
require "Module/DailyTask"
require "Common/CommonCal"
module("SlotsWorldCup", package.seeall)

-----------------------------------------------
-- 进入房间
------------------------------------------------
Enter = function( _M, session, request)
    local response = {header = {router = "Response"}}
    
    local filter_ret = RequestFilter.Filter("SlotsWorldCup", "Enter", session, request, true)
    if filter_ret then
        response.ret = filter_ret
        return response
    end

    local task = session.task
    local player = session.player

    CommonCal.Calculate.MakeUpInRoom(session, task)
    
    LOG(RUN, INFO).Format("[SlotsWorldCup][Enter] player %s", player.id)

    local isLock = CommonCal.Calculate.LevelReq(player, GameType.AllTypes.WorldCup)
    if (isLock == 1)
    then
        response.ret = Return.LOCK_GAME()
        return response
    end

    local table_id = request.table_id
    local async_request = nil
    local game_room_config = GameRoomConfig[GameType.AllTypes.WorldCup]

    if (table_id and table_id > 0)
    then
        local channel_id = string.format("%s.%s.%s", "SlotsWorldCupContest", game_room_config.room_name, table_id)
        player.world_cup.channel_id = channel_id
        async_request = {
            header = {
                router = "AsyncRequest",
                service_name = game_room_config.contest_client_name,
                task_id = task.id,
                module_id = "SlotsWorldCupContest",
                message_id = "SlotsWorldCupContest_Enter_Request",
            },
            player = {
                id = player.id,
                user = player.user,
                account = player.account,
                game_type = GameType.AllTypes.WorldCup,
                character = {
                    chip = player.character.chip,
                    vip = player.character.vip,
                    level = player.character.level,
                    experience = player.character.experience,   
                    player_type = player.character.player_type,
                },
                record = player.record,
                world_cup = player.world_cup
            },
        }
    else
        async_request = {
            header = {
                router = "AsyncRequest",
                service_name = game_room_config.contest_client_name,
                task_id = task.id,
                module_id = "SlotsWorldCupContest",
                message_id = "SlotsWorldCupContest_Enter_Request",
            },
            player = {
                id = player.id,
                user = player.user,
                account = player.account,
                character = {
                    chip = player.character.chip,
                    vip = player.character.vip,
                    level = player.character.level,
                    experience = player.character.experience,   
                    player_type = player.character.player_type,
                },
                record = player.record,
                world_cup = player.world_cup
            },
        }
    end

	local async_response = session:ContactPacket(task, async_request)

	if async_response.ret.code ~= 0 then
		response.ret = async_response.ret
		return response
	end
    local table_sync_notice = {
        header = {
            router = "Notice",
        },
        table = async_response.table
    }

    player.world_cup.channel_id = async_response.channel_id

    --opt entertable
    local channel_id = async_response.channel_id
    local contest_id, room_id, table_id = unpack(string.split(channel_id, "."))
    local table_mates = {}
    for _,v in pairs(async_response.table.seat) do
        if v.player then
            table.insert(table_mates, v.player.id)
        end
    end


    Spark:EnterTable(player, {
        [1] = contest_id,
        [2] = room_id,
        [3] = table_id,
        [4] = #table_mates,
        [5] = table_mates,
    })

    local async_request = {
		header = {
			router = "AsyncRequest",
			service_name = "NotificationClientService",
			task_id = task.id,
			module_id = "Distributor",
			message_id = "Distributor_Register_Request",
		},
		session_id = session.id,
		player_id = player.id,
		channel_id = {async_response.channel_id},
        drop_channel_id = {"Hall"},
        player_type = session.player.character.player_type,
	}
	local async_response = session:ContactPacket(task, async_request)
	if async_response.ret.code ~= 0 then
		response.ret = async_response.ret
		return response
	end

	async_request.header.service_name = game_room_config.contest_client_name
	local async_response = session:ContactPacket(task, async_request)
	if async_response.ret.code ~= 0 then
		response.ret = async_response.ret
		return response
	end

    player.world_cup.bouts_id = 0--进场的时候把cd清空掉
    player.world_cup.enter_chip = player.character.chip
    player.world_cup.spined_times = 0

    if (player.world_cup.free_spin_num_str)
    then
        local free_spin_num_array = json.decode(player.world_cup.free_spin_num_str)
        SlotsWorldCupCal.Calculate.UpdateFreeBous(player.world_cup, free_spin_num_array)

        if (free_spin_num_array and #free_spin_num_array > 0)
        then
            free_spin_type = tonumber(free_spin_num_array[1].free_spin_type)
            player.world_cup.free_spin_type = free_spin_type
        end
    end

    response.ret = Return.OK()
    response.player = {
        world_cup = player.world_cup,
        character = {
            chip = player.character.chip,
        },
        world_cup = player.world_cup,
    }
    player.game_type = GameType.AllTypes.WorldCup

    -----------------紧急修复-------------------
    if (player.world_cup.free_spin_bouts > 50)
    then
        player.world_cup.free_spin_bouts = 0
    end
    
    return response, table_sync_notice
end

-----------------------------------------------
-- 开始slots
-----------------------------------------------
Start = function (_M, session, request )
    local response = {header = {router = "Response"}}

    return response
end

-----------------------------------------------
-- 退出房间
------------------------------------------------
Exit = function (_M, session, request )
    local response = {header = {router = "Response"}}
    
    local filter_ret = RequestFilter.Filter("SlotsWorldCup", "Exit", session, request, true)
    if filter_ret then
        response.ret = filter_ret
        return response
    end

	local player = session.player
    local task = session.task
    local game_room_config = GameRoomConfig[player.game_type]
    if (game_room_config == nil) then
        response.ret = Return.HAVE_ALREADY_EXIT_GAME()
        return response
    end
	local async_request = {
		header = {
			router = "AsyncRequest",
			service_name = game_room_config.contest_client_name,
			task_id = task.id,
			module_id = "SlotsWorldCupContest",
			message_id = "SlotsWorldCupContest_Exit_Request",
		},
		player_id = player.id,
	}
    LOG(RUN, INFO).Format("[SlotsWorldCup][Exit] player %s start exit from SlotsWorldCupContest", player.id)
	local async_response = session:ContactPacket(task, async_request)
	if async_response.ret.code ~= 0 then
		response.ret = async_response.ret
		return response
	end

    -- opt exit
    local contest_id, room_id, table_id = unpack(string.split(async_response.channel_id, "."))
    local table_mates = {}
    for _, v in pairs(async_response.table.seat) do
        if v.player then
            table.insert(table_mates, v.player.id)
        end
    end


    Spark:LeaveTable(player, {
        [1] = contest_id,
        [2] = room_id,
        [3] = table_id,
        [4] = #table_mates,
        [5] = table_mates
    })

	local async_request = {
		header = {
			router = "AsyncRequest",
			service_name = "NotificationClientService",
			task_id = task.id,
			module_id = "Distributor",
			message_id = "Distributor_Register_Request",
		},
		session_id = session.id,
		player_id = player.id,
		channel_id = {"Hall"},
        drop_channel_id = {async_response.channel_id},
        player_type = session.player.character.player_type,
	}
	local async_response = session:ContactPacket(task, async_request)
	if async_response.ret.code ~= 0 then
		response.ret.code = async_response.ret.code
		return response
	end

	async_request.header.service_name = game_room_config.contest_client_name
	local async_response = session:ContactPacket(task, async_request)
	if async_response.ret.code ~= 0 then
		response.ret = async_response.ret
		return response
	end

    local trigger_buyloss, total_loss, diamond, goods_id = BuyLoss:Trigger(session, task, GameType.AllTypes.WorldCup, player) ---当玩家钱减少到一定数量时，提示玩家充值
    if trigger_buyloss then
        player.world_cup.total_loss = total_loss
        session:WriteRouterPacket({
            header = {
                router = "SpecificNotice",
                session_id = session.id,
                player_id = player.id,
                module_id = "BuyLoss",
                message_id = "BuyLoss_Trigger_Notice",
            },
            total_loss = total_loss,
            diamond = diamond,
            goods_id = goods_id,
        })
    end
    player.world_cup.spined_times = 0
	response = {
		header = response.header,
		ret = Return.OK(),
		player = {
			character = {
				chip = player.character.chip,
			},
		},
    }

    return response
end