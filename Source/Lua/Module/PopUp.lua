-----------------
--     PopUp    --
-----------------
module("PopUp", package.seeall)

Button = function( _M, session, request )
	
end

Toast = function(_M, session, request)
	local channel = Channel:Get(request.type)
	local channel_id = channel:Id()
	local notice = {
		header = {
			router = "Broadcast",
			channel_id = channel_id,
			module_id = "PopUp",
			message_id = "PopUp_Toast_Notice",
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