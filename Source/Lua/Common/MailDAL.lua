--------------
--  LineNum  --
--------------
module("MailDAL", package.seeall)

Calculate = {
	AddMail = function(task, player_id, data)
		if data.attachments then
			local content = json.decode(data.attachments)
			LOG(RUN, INFO).Format("[MailDAL] add mail player %s data.attachments is:%s", player_id, data.attachments)		
			for k1, v1 in ipairs(content) do
				for k2, v2 in ipairs(v1) do
					v1[k2] = tonumber(v2)
				end
			end
			data.attachments = json.encode(content)
		end  
		local async_request = {string.format("insert into slots.mail_%s(player_id, title, timestamp, content, sender, attachments, status, mail_type, json_str) values(%s, '%s', %s, '%s', '%s', '%s', %s, %s, '%s')", math.mod(player_id, 16), player_id, data.title, os.time(), data.content, data.sender, data.attachments, 0, data.mail_type and data.mail_type or 0, data.json_str and data.json_str or "[]")}
		
		local async_response = LuaSession:ContactJson("DatabaseClientService", task, async_request, player_id)

		if async_response[1].row_num < 0 then
			LOG(RUN, INFO).Format("[MailDAL] add mail player %s return error", player_id)		
		end	
	end,

	UpdateMail = function(task, player_id, data)
		local async_request = {string.format("update slots.mail_%s set player_id = %s, title = '%s', timestamp = %s, content = '%s', sender = '%s', attachments = '%s', status = %s, mail_type = %s, json_str = '%s' where id = %s", math.mod(player_id, 16), player_id, data.title, os.time(), data.content, data.sender, data.attachments, 0, data.mail_type and data.mail_type or 0, data.json_str and data.json_str or "[]", data.id)}
		
		-- LOG(RUN, INFO).Format("[MailDAL] %s, UpdateMail %s", player_id, Table2Str(async_request))
		local async_response = LuaSession:ContactJson("DatabaseClientService", task, async_request, player_id)
		-- LOG(RUN, INFO).Format("[MailDAL] UpdateMail success mail player %s", player_id)
		if async_response[1].row_num < 0 then
			LOG(RUN, INFO).Format("[MailDAL] add mail player %s return error", player_id)		
		end	
	end,

	DelMail = function(task, player_id, mail_id)
		local async_request = {string.format("delete from slots.mail_%s where player_id = %s and id = %s", math.mod(player_id, 16), player_id, mail_id)}
		-- LOG(RUN, INFO).Format("[MailDAL] %s, DelMail %s", player_id, Table2Str(async_request))
		local async_response = LuaSession:ContactJson("DatabaseClientService", task, async_request, player_id)
		-- LOG(RUN, INFO).Format("[MailDAL] del mail success player %s, info is:%s", player_id, Table2Str(async_response))
	end,

	GetMailsByType = function(task, player_id, mail_type)
		local async_request = {string.format("select id, player_id, title, timestamp, content, sender, attachments, status, mail_type, json_str from slots.mail_%s where player_id = %s and mail_type = %s limit 50", math.mod(player_id, 16), player_id, mail_type)}
		
		-- LOG(RUN, INFO).Format("[MailDAL] %s, GetMails %s", player_id, Table2Str(async_request))
		local async_response = LuaSession:ContactJson("DatabaseClientService", task, async_request, player_id)
		-- LOG(RUN, INFO).Format("[MailDAL] get mail success player %s, info is:%s", player_id, Table2Str(async_response))
		local data_list = {}
		if async_response[1].row_num > 0 then
			local data_set = async_response[1].data_set
			for k, info in ipairs(data_set) do
				local data = {
					id = tonumber(info[1]),
					player_id = tonumber(info[2]),
					title = info[3],
					timestamp = tonumber(info[4]),
					content = info[5],
					sender = info[6],
					attachments = info[7],
					status = tonumber(info[8]),
					mail_type = tonumber(info[9]),
					json_str = info[10]
				}
				table.insert(data_list, data)
			end
		end
		return data_list
	end,

	GetMails = function(task, player_id, mail_id)
		local async_request = {}
		if mail_id == nil or mail_id == 0 then
			async_request = {string.format("select id, player_id, title, timestamp, content, sender, attachments, status, mail_type, json_str from slots.mail_%s where player_id = %s order by mail_type limit 50", math.mod(player_id, 16), player_id)}
		else
			async_request = {string.format("select id, player_id, title, timestamp, content, sender, attachments, status, mail_type, json_str from slots.mail_%s where player_id = %s and id = %s limit 50", math.mod(player_id, 16), player_id, mail_id)}
		end
		-- LOG(RUN, INFO).Format("[MailDAL] %s, GetMails %s", player_id, Table2Str(async_request))
		local async_response = LuaSession:ContactJson("DatabaseClientService", task, async_request, player_id)
		-- LOG(RUN, INFO).Format("[MailDAL] get mail success player %s, info is:%s", player_id, Table2Str(async_response))
		local data_list = {}
		if async_response[1].row_num > 0 then
			local data_set = async_response[1].data_set
			for k, info in ipairs(data_set) do
				local data = {
					id = tonumber(info[1]),
					player_id = tonumber(info[2]),
					title = info[3],
					timestamp = tonumber(info[4]),
					content = info[5],
					sender = info[6],
					attachments = info[7],
					status = tonumber(info[8]),
					mail_type = tonumber(info[9]),
					json_str = info[10]
				}
				table.insert(data_list, data)
			end
		end
		return data_list
	end
}