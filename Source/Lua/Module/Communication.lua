-----------------------
--   Communication   --
-----------------------
require "Base/Path"
require "Util/TableExt"
require "Util/MathExt"
require "Common/Return"
require "Common/Channel"
require "Config/ServerConfig"
require "Common/ClubConsts"
module("Communication", package.seeall)

Chat = function(_M, session, request)
	local response = {header = {router = "Response"}}
	if not session or not session.player then
		response.ret = Return.PLAYER_NOT_FOUND()
		return response
	end

	local player = session.player
	local task = session.task
	local channel = Channel:Get(request.type)
	if not channel then
		 response.ret = Return.COMMUNICATION_CHAT_TYPE_NOT_VALID()
		return response       
	end

	if not string.check_special_char(request.content, ClubConsts.AllowedChars) then
		response.ret = Return.COMMUNICATION_CHAT_CONTENT_NOT_VALID()
		return response
	end

	local channel_id = channel:Id(player, session, task)
	if string.len(request.content) > 200 then
		response.ret = Return.COMMUNICATION_CHAT_OVER_LENGTH()
		return response
	end

	local notice = {
		header = {
			router = "Broadcast",
			channel_id = channel_id,
		},
		type = channel.type,
        content = request.content,
	}

	if channel.name == "Club" and player.club_info.club_id ~= -1 then
		--俱乐部聊天要存到mysql
		--先要查询到发送该条消息的玩家在俱乐部的身份
		local async_request = {string.format("select identity from slots.club_member where player_id = %s", player.id)}
		local async_response = session:ContactJson("DatabaseClientService", task, async_request, player.id)
		local player_identity
		if async_response[1].row_num <= 0 then
			--LOG不中断回复
		elseif async_response[1].row_num > 0 then
			player_identity = tonumber(async_response[1].data_set[1][1])
		end
		if player_identity then
			notice.player_identity = player_identity
		end
		local is_success, return_info = Club.ClubHelper.InsertChatToClub(session, task, player.club_info.club_id, request.content, player.id)
		if not is_success then
			--LOG 不阻塞response,只打log
            LOG(RUN, INFO).Format("[Communication][Chat] player %s chat %s in club %s, insert chat info to mysql failed!", player.id, request.content, channel_id)
		end
	end

	if session.player then        -- player push broadcast
		-- local now_time = os.time()
		-- if now_time - player.character.chat_time <= 1 then -- cool down 1s
		-- 	response.ret = Return.COMMUNICATION_CHAT_SENDER_NOT_COOL_DOWN()
		-- 	return response
		-- end

		-- player.character.chat_time = now_time

		if channel.name == "SystemInfo" then
			response.ret = Return.SHOULDNOT_SEND_SYSTEM_INFO()
			return response
		end
		local player_brief = Player:GetBrief(player)
		notice.chat_player = player_brief
		--[[
		notice.chat_player = {
			id = session.player.id,
			character = {
				vip = session.player.character.vip,
			},
			user = {
				nickname = session.player.user.nickname,
				sex = session.player.user.sex,
                avatar = session.player.user.avatar,
			}
		}
		--]]
	end

	response.ret = Return.OK()
	response.player = {
		prop = {
			normal = player.prop.normal
		}
	}

	-- opt
	local contest_id, room_id, table_id = unpack(string.split(channel_id, "."))


	Spark:Chat(player, {
		[1] = contest_id, 
		[2] = room_id,
		[3] = table_id,
		[4] = channel.name,
		[5] = channel_id,
		[6] = request.content,
	})

	-- return response, notice
	return response
end

Broadcast = function(_M, session, request)
	local channel = Channel:Get(request.type)
	local channel_id = channel:Id()
	local notice = {
		header = {
			router = "Broadcast",
			channel_id = channel_id,
			module_id = "Communication",
			message_id = "Communication_Chat_Notice",
		},
		type = channel.type,
		content = request.content,
	}
	if session.player then
		local player = session.player
		notice.chat_player = {
			id = player.id,
			character = {
				vip = player.character.vip,
			},
			user = {
				nickname = player.user.nickname,
				sex = player.user.sex,
			}
		}
	elseif request.player then
		local player = request.player
		notice.chat_player = {
			id = player.id,
			character = {
				vip = player.character.vip,
			},
			user = {
				nickname = player.user.nickname,
				sex = player.user.sex,
			}
		}
	end

	-- if not request.time then
	-- 	session:WriteRouterPacket(notice)
	-- else
	-- 	Base.NotificationClientService:TimedWork(function()
	-- 			session:WriteRouterPacket(notice)
	-- 		end, request.time)
	-- end
end

local LastBcTime = {}
OnBcEvent = function(_M, session, bc_type, win_info, time)
	local bet_amount = win_info.bet_amount
	local player = session.player
	local bc_conf
	for k,v in ipairs(BroadcastConfig) do
		if v.bc_type == bc_type and v.bet_amount == bet_amount then
			bc_conf = v
			break
		end
	end
	if not bc_conf then return end
	if win_info.total_bet == 0 then return end

	local payrate = win_info.win_chip / win_info.total_bet

	if not LastBcTime[bc_type] then
		LastBcTime[bc_type] = 0
	end

	local timeLate = time and time or 0
	local current_time = os.time()
	if current_time - LastBcTime[bc_type] <= bc_conf.cd then
		LOG(RUN, INFO).Format("[Communication][OnBcEvent] bc_type:%s broadcast not cool down", bc_type)
	else
		if payrate >= bc_conf.trigger_payrate and win_info.win_chip >= bc_conf.trigger_amount 
			and player.character.vip >= bc_conf.trigger_vip_level and player.character.level >= bc_conf.trigger_player_level then
			Communication:Broadcast(session, {
				type = "SystemInfo",
				content = json.encode({win_chip = win_info.win_chip, bc_type = bc_type}),
				time = os.time() + timeLate
			})		
		end
	end
end
