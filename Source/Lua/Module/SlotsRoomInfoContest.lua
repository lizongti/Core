require "Common/RequestFilter"
require "Common/LineNum"
require "Module/SlotsAliceinWonderlandContest"

module("SlotsRoomInfoContest", package.seeall)


QueryRoomBrief = function( _M, session, request)
	local response = {
		header = {
			router = "AsyncResponse", 
			client_id = session.client_id, 
			task_id = request.header.task_id
		}
	}
    
    local game_type = request.game_type
    local game_room_config = GameRoomConfig[game_type]

    local room = nil
    
    if (game_room_config.const_game_name == "SlotsGameContest") then
        SlotsGameContest.SlotsGameContainer:Init():NewRoom(game_room_config.room_name)
        room = SlotsGameContest.SlotsGameContainer[game_room_config.room_name] 
    else
        _G[game_room_config.const_game_name]["Slots"..game_room_config.game_name.."Container"]:Init():NewRoom(game_room_config.room_name)
        room = _G[game_room_config.const_game_name]["Slots"..game_room_config.game_name.."Container"][game_room_config.room_name]
    end
    
    local room_info = {}
    room_info.table_list = {}

    local player_count = 0

    for k, tab in pairs(room) do
        for i, seat in ipairs(tab) do
            if (seat.player ~= nil) then
                player_count = player_count + 1
            else
                
            end   
        end     
    end

    response.ret = Return.OK()
    response.player_count = player_count

    return response
end

Query = function( _M, session, request)
	local response = {
		header = {
			router = "AsyncResponse", 
			client_id = session.client_id, 
			task_id = request.header.task_id
		}
	}
    
    local game_type = request.game_type
    local game_room_config = GameRoomConfig[game_type]

    local room = nil
    if (game_room_config.const_game_name == "SlotsGameContest") then
        SlotsGameContest.SlotsGameContainer:Init():NewRoom(game_room_config.room_name)
        room = SlotsGameContest.SlotsGameContainer[game_room_config.room_name] 
    else
        _G[game_room_config.const_game_name]["Slots"..game_room_config.game_name.."Container"]:Init():NewRoom(game_room_config.room_name)
        room = _G[game_room_config.const_game_name]["Slots"..game_room_config.game_name.."Container"][game_room_config.room_name]
    end
    
    local room_info = {}
    room_info.table_list = {}

    for k, tab in pairs(room) do
        room_info.table_list[tab.id] = {}
        room_info.table_list[tab.id].seats = {}
        room_info.table_list[tab.id].free_seats = {}

        for i, seat in ipairs(tab) do
            if (seat.player ~= nil) then
                table.insert(room_info.table_list[tab.id].seats, {id = seat.id, table_id = seat.table.id, player_type = seat.player.character.player_type, player_id = seat.player.id})
            else
                table.insert(room_info.table_list[tab.id].free_seats, {id = seat.id, table_id = seat.table.id})
            end   
        end     
    end

    response.room_info = json.encode(room_info)
    response.ret = Return.OK()

    return response
end

TableInfo = function( _M, session, request)
	local response = {
		header = {
			router = "AsyncResponse", 
			client_id = session.client_id, 
			task_id = request.header.task_id
		}
	}
    --LOG(RUN, INFO).Format("[SlotsRoomInfoContest][TableInfo] request is: %s", Table2Str(request))

    local game_type = request.game_type
    local game_room_config = GameRoomConfig[game_type]
    local player_id = request.player_id


    local seat = nil

    if (game_room_config.const_game_name ~= "SlotsGameContest") then
        _G[game_room_config.const_game_name]["Slots"..game_room_config.game_name.."Container"]:Init():NewRoom(game_room_config.room_name)
        seat = _G[game_room_config.const_game_name]["Slots"..game_room_config.game_name.."Container"]:LocateSeat(player_id)
    else
        SlotsGameContest.SlotsGameContainer:Init():NewRoom(game_room_config.room_name)
        seat = SlotsGameContest.SlotsGameContainer:LocateSeat(player_id)
    end

	if not seat then
		response.ret = Return.GAME_CONTEST_CANNOT_FIND_PLAYER()
		return response
    end
    
    local tab = seat.table

	response.table = {
		seat = {},
	}
	for i, seat in pairs(tab) do
		table.insert(response.table.seat, {
			id = seat.id,
			player = seat.player,
			online = seat.online,
		})
    end
    
    response.ret = Return.OK()

    --LOG(RUN, INFO).Format("[SlotsRoomInfoContest][TableInfo] response is: %s", Table2Str(response))
    return response
end


