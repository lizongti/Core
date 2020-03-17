----------
-- PlayerMail --
----------
module("PlayerMail", package.seeall)
require "Config/ServerConfig"
require "Common/MailType"
require "Common/MailDAL"
local PropType = {
	Common = 1,
	--普通道具标记为1
	Charge = 2
	--为充值加的道具,标记为2
}
--查询邮件
Query = function(_M, session, request)
	local response = {header = {router = "Response"}}
	local task = session.task
	local player = session.player

	LOG(RUN, INFO).Format("[PlayerMail] %s, Query request %s", player.id, Table2Str(request))

	local data_list = MailDAL.Calculate.GetMails(Task:Current(), player.id)
	response.ret = Return.OK()
	response.data_list = json.encode(data_list)
	LOG(RUN, INFO).Format("[PlayerMail] %s, Query response %s", player.id, Table2Str(response))
	return response
end

--查询邮件
Hot = function(_M, session, request)
	local player = session.player
	LOG(RUN, INFO).Format("[PlayerMail] %s, Hot request %s", player.id, Table2Str(request))
	LOG(RUN, INFO).Format("[PlayerMail] %s, Hot charge %s", player.id, player.character.charge)
	if player.character.charge < 499 then
		local wath_vido_data_list =
			MailDAL.Calculate.GetMailsByType(Task:Current(), player.id, MailType.MailTypes.INCENTIVE_VIDEO)
		if #wath_vido_data_list == 0 then
			local data = {}
			data.mail_type = MailType.MailTypes.INCENTIVE_VIDEO
			data.player_id = player.id
			data.timestamp = os.time()
			data.content = "Watch a video to claim"
			data.title = "INBOX SALE"
			data.attachments = "[]"
			data.sender = "system"
			MailDAL.Calculate.AddMail(Task:Current(), player.id, data)
		end

		local block_ad_data_list =
			MailDAL.Calculate.GetMailsByType(Task:Current(), player.id, MailType.MailTypes.BLOCK_AD_POINT)
		local old_goods_id = 0
		if (#block_ad_data_list > 0) then
			for k, v in ipairs(block_ad_data_list) do
				local attachments = json.decode(v.attachments)
				if attachments and attachments[1] and attachments[1][1] then
					old_goods_id = attachments[1][1]
				end
			end
		end
		local data = {}
		local goods_id = 0
		for k, inbox_sale in ipairs(InboxSaleConfig) do
			if 1 == inbox_sale.sale_type then
				if (old_goods_id ~= inbox_sale.shop_id) then
					goods_id = inbox_sale.shop_id
				end
			end
		end
		data.mail_type = MailType.MailTypes.BLOCK_AD_POINT
		data.player_id = player.id
		data.timestamp = os.time()
		data.content = "Blocking all ads by making any purchase"
		data.title = "INBOX SALE"
		data.attachments = string.format("[[%s,0]]", goods_id)
		data.sender = "system"

		if (#block_ad_data_list > 0) then
			data.id = block_ad_data_list[1].id
			MailDAL.Calculate.UpdateMail(Task:Current(), player.id, data)
		else
			MailDAL.Calculate.AddMail(Task:Current(), player.id, data)
		end

		return Query(_M, session, request)
	end

	local data_list = MailDAL.Calculate.GetMailsByType(Task:Current(), player.id, MailType.MailTypes.INCENTIVE_VIDEO)
	LOG(RUN, INFO).Format("[PlayerMail] %s, type111 datalist: %s", player.id, Table2Str(data_list))
	if (#data_list > 0) then
		for k, v in ipairs(data_list) do
			MailDAL.Calculate.DelMail(Task:Current(), player.id, v.id)
		end
	end
	local data_list = MailDAL.Calculate.GetMailsByType(Task:Current(), player.id, MailType.MailTypes.BLOCK_AD_POINT)
	if (#data_list > 0) then
		for k, v in ipairs(data_list) do
			MailDAL.Calculate.DelMail(Task:Current(), player.id, v.id)
		end
	end

	local rand_value = math.random_ext(player, 1, 2)

	local sale_goods_id = 0
	for k, inbox_sale in ipairs(InboxSaleConfig) do
		if 2 == inbox_sale.sale_type then
			if rand_value == 1 then
				if
					(player.character.his_max_charge >= (inbox_sale.max_charge_min * 100) and
						player.character.his_max_charge <= (inbox_sale.max_charge_max * 100))
				 then
					sale_goods_id = inbox_sale.shop_id
					break
				end
			else
				local player_extern = CommonCal.Calculate.get_player_extern(session, Task:Current(), player)
				local player_json_data = player_extern.save_data
				local inbox_sale_charge = player.character.charge
				if player_json_data.inbox_sale_charge ~= nil then
					LOG(RUN, INFO).Format("[PlayerMail] %s, 777777 inbox_sale_charge: %s", player.id, inbox_sale_charge)
					inbox_sale_charge = player_json_data.inbox_sale_charge
				end

				if
					(inbox_sale_charge >= (inbox_sale.recent_charge_min * 100) and
						inbox_sale_charge <= (inbox_sale.recent_charge_max * 100))
				 then
					sale_goods_id = inbox_sale.shop_id
					break
				end
			end
		end
	end
	if (sale_goods_id ~= 0) then
		local data = {}
		data.mail_type = MailType.MailTypes.INBOX_SALE
		data.player_id = player.id
		data.timestamp = os.time()
		data.content = "Special Offer only for you!"
		data.title = "INBOX SALE"
		data.attachments = string.format("[[%s,0]]", sale_goods_id)
		data.sender = "system"

		local data_list = MailDAL.Calculate.GetMailsByType(Task:Current(), player.id, MailType.MailTypes.INBOX_SALE)
		if (#data_list > 0) then
			data.id = data_list[1].id
			MailDAL.Calculate.UpdateMail(Task:Current(), player.id, data)
		else
			MailDAL.Calculate.AddMail(Task:Current(), player.id, data)
		end
	end

	return Query(_M, session, request)
end

--删除邮件
Delete = function(_M, session, request)
	local response = {header = {router = "Response"}}
	local task = session.task
	local player = session.player
	local mail_id = request.mail_id

	LOG(RUN, INFO).Format("[PlayerMail] %s, Delete request %s", player.id, Table2Str(request))

	MailDAL.Calculate.DelMail(Task:Current(), player.id, mail_id)
	response.ret = Return.OK()
	response.data_list = json.encode(MailDAL.Calculate.GetMails(Task:Current(), player.id))
	-- response.data_list = json.encode(data_list)
	LOG(RUN, INFO).Format("[PlayerMail] %s, Delete response %s", player.id, Table2Str(response))
	return response
end

local fetchMail = function(session, player, data_list)
	local prop_list = json.decode(data_list[1].attachments)
	for _, item in pairs(prop_list) do
		local cur_shop_config = CommonCal.Calculate.get_config(player, "ShopConfig")
		local shop_good_info = cur_shop_config[item[1]]

		if shop_good_info == nil then
			LOG(RUN, INFO).Format("[PlayerMail] %s, Fetch common", player.id)
			local old_chip = player.character.chip
			Player:Obtain(player, item, Reason.GET_ATTACHMENT_PROP_OBTAIN())

			session:WriteRouterPacket(
				{
					header = {
						router = "SpecificNotice",
						session_id = session.id,
						player_id = player.id,
						module_id = "Command",
						message_id = "Command_Player_Notice"
					},
					player = {
						character = {
							chip = player.character.chip,
							level = player.character.level,
							charge = player.character.charge,
							vip = player.character.vip,
							experience = player.character.experience,
							android_charge = player.character.android_charge,
							ios_charge = player.character.ios_charge,
							month_charge = player.character.month_charge,
							daily_charge = player.character.daily_charge,
							charge_time = player.character.charge_time,
							vip_points = player.character.vip_points,
							last_charge = player.character.last_charge,
							last_charge_str = player.character.last_charge_str,
							charge_str = player.character.charge_str,
							his_max_charge = player.character.his_max_charge
						}
					},
					collect_chip = player.character.chip - old_chip
				}
			)
			local items = {}
			for _, v in ipairs(prop_list) do
				table.insert(items, {id = v[1], amount = v[2]})
			end

			session:WriteRouterPacket(
				{
					header = {
						router = "SpecificNotice",
						session_id = session.id,
						player_id = player.id,
						module_id = "Command",
						message_id = "Command_GetAttachments_Notice"
					},
					item = items,
					attachments_type = 3
				}
			)
		else
			LOG(RUN, INFO).Format("[PlayerMail] %s, Fetch charge", player.id)
			old_player_id = 0
			if (item[3] ~= nil) then
				old_player_id = tonumber(item[3])
			end
			for i = 1, item[2] do
				local data = {
					player_id = player.id,
					goods_id = shop_good_info.id,
					old_player_id = old_player_id
				}
				session:ReadRouterPacket(
					{
						header = {
							router = "Command",
							module_id = "Command",
							message_id = "Command_GetGoods_Request"
						},
						session_id = session.id,
						content = json.encode(data)
					}
				)
			end
			break
		end
	end
end

--领取支付邮件
FetchPayment = function(_M, session, request)
	local response = {header = {router = "Response"}}
	local task = session.task
	local player = session.player

	LOG(RUN, INFO).Format("[PlayerMail]begin %s, FetchPayment request %s", player.id, Table2Str(request))

	local data_list = MailDAL.Calculate.GetMailsByType(Task:Current(), player.id, MailType.MailTypes.COMMODITY_REISSUE)
	if #data_list == 0 then
		response.ret = Return.PAYMENT_MAIL_HAVE_FETCHED()
		LOG(RUN, INFO).Format("[PlayerMail]error %s, FetchPayment response %s", player.id, Table2Str(response))
		return response
	end

	fetchMail(session, player, data_list)

	MailDAL.Calculate.DelMail(Task:Current(), player.id, data_list[1].id)
	response.ret = Return.OK()
	response.data_list = json.encode(MailDAL.Calculate.GetMails(Task:Current(), player.id))
	-- response.data_list = json.encode(data_list)
	LOG(RUN, INFO).Format("[PlayerMail] %s, FetchPayment response %s", player.id, Table2Str(response))
	return response
end

--领取邮件
Fetch = function(_M, session, request)
	local response = {header = {router = "Response"}}
	local task = session.task
	local player = session.player
	local mail_id = request.mail_id

	LOG(RUN, INFO).Format("[PlayerMail]begin %s, Fetch request %s", player.id, Table2Str(request))

	local data_list = MailDAL.Calculate.GetMails(Task:Current(), player.id, mail_id)
	if #data_list == 0 then
		response.ret = Return.MAIL_HAVE_FETCHED()
		LOG(RUN, INFO).Format("[PlayerMail]error %s, Fetch response %s", player.id, Table2Str(response))
		return response
	end

	fetchMail(session, player, data_list)

	MailDAL.Calculate.DelMail(Task:Current(), player.id, mail_id)
	response.ret = Return.OK()
	response.data_list = json.encode(MailDAL.Calculate.GetMails(Task:Current(), player.id))
	-- response.data_list = json.encode(data_list)
	LOG(RUN, INFO).Format("[PlayerMail] %s, Fetch response %s", player.id, Table2Str(response))
	return response
end