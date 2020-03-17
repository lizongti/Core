--------------
--  LineNum  --
--------------
module("PaymentCal", package.seeall)

Calculate = {
	AsyncAddPayment = function(player_id, content)
		local table_name = "OfflineProps"
		local redis_request = {
			[1] = {
				cmd = "%s %s %s",
				args = {"LPUSH", string.format("%s[%s]", table_name, player_id), content}
			}
		}
		LOG(RUN, INFO).Format("[PaymentCal][AsyncAddPayment] player %s redis_request is: %s", player_id, Table2Str(redis_request))
		local redis_response = LuaSession:ContactJson("CacheClientService", Task:Current(), redis_request, table_name)	
		LOG(RUN, INFO).Format("[PaymentCal][AsyncAddPayment] player %s redis_response is: %s", player_id, Table2Str(redis_response))	
	end,
	AsyncDealPayment = function(session)
		local player = session.player
		local player_id = player.id
		local table_name = "OfflineProps"
		local redis_request = {
			[1] = string.format("LRANGE %s[%s] 0 -1", table_name, player.id),
		}
		LOG(RUN, INFO).Format("[PaymentCal][AsyncDealPayment] player %s redis_request is: %s", player_id, Table2Str(redis_request))
		local redis_response = LuaSession:ContactJson("CacheClientService", Task:Current(), redis_request, table_name)	
		LOG(RUN, INFO).Format("[PaymentCal][AsyncDealPayment] player %s redis_response is: %s", player_id, Table2Str(redis_response))
	
		local msg_len = 0
		for k, content in ipairs(redis_response) do
			msg_len = msg_len + 1
			local async_request = {
				header = {
					router = "LocalRequest",
					service_name = "DispatcherService",
					task_id = Task:Current().id,
					module_id = "Command",
					message_id = "Command_GetGoods_Request",
				},
				session_id = session.id,
				content = content,
			}
	
			local async_response = session:ContactPacket(Task:Current(), async_request)
		end

		local redis_request = {
			[1] = string.format("LTRIM %s[%s] 0 -%s", table_name, player.id, (1 + msg_len)),
		}
		LOG(RUN, INFO).Format("[PaymentCal][AsyncDealPayment] player %s redis_request is: %s", player_id, Table2Str(redis_request))
		local redis_response = LuaSession:ContactJson("CacheClientService", Task:Current(), redis_request, table_name)	
		LOG(RUN, INFO).Format("[PaymentCal][AsyncDealPayment] player %s redis_response is: %s", player_id, Table2Str(redis_response))
		

	end,
}