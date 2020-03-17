----------
-- Mail --
----------
module("Mail", package.seeall)

require "Common/MailType"
require "Common/MailDAL"




-- 自动补单
AutoFetch = function(_M, session, request)
	local response = {
		header = {
			router = "AsyncResponse",
			client_id = session.client_id,
			task_id = request.header.task_id
		}
	}

	local prop_list = json.decode(request.props)

	local data = {
		title = MailType.TitleContentConfig["AutoFetch"].title,
		content = MailType.TitleContentConfig["AutoFetch"].content,
		sender = "system",
		attachments = json.encode(prop_list),
		player_id = request.player_id,
		mail_type = MailType.MailTypes.COMMODITY_REISSUE,--类型1:激励视频，2：屏蔽广告计费点，3：INBOX SALE，4：Tournament奖励，5：升级客户端版本奖励，6：商品补发邮件，7：后台道具补发邮件
	}

	-- session:WriteQueue("present", json.encode(data))
	MailDAL.Calculate.AddMail(Task:Current(), request.player_id, data)

	response = {
		header = response.header,
		ret = Return.OK()
	}

	return response
end

-- 发送通用邮件接口
sendSystemMail = function(_M, session, request)
	local response = {
		header = {
			router = "AsyncResponse",
			client_id = session.client_id,
			task_id = request.header.task_id
		}
	}

	local prop_list = json.decode(request.props)

	for k, v in pairs(prop_list) do
		local name_or_id = prop_list[k][1]
		prop_list[k][1] = PropConfig.PropMap[name_or_id].id
	end

	local data = {
		title = request.title,
		content = request.content,
		sender = request.from,
		attachments = json.encode(prop_list),
		player_id = request.player_id,
		mail_type = MailType.MailTypes.PROP_REISSUE,--类型1:激励视频，2：屏蔽广告计费点，3：INBOX SALE，4：Tournament奖励，5：升级客户端版本奖励，6：商品补发邮件，7：后台道具补发邮件
	}

	-- session:WriteQueue("present", json.encode(data))
	MailDAL.Calculate.AddMail(Task:Current(), request.player_id, data)

	response = {
		header = response.header,
		ret = Return.OK()
	}

	return response
end

SendChips = function(_M, session, request)
	local response = {
		header = {
			router = "AsyncResponse",
			client_id = session.client_id,
			task_id = request.header.task_id
		}
	}

	local props = json.decode(request.props)
	local chip_count = props[1000] and props[1000] or 0
	local sender = request.sender
	local data = {
		title = string.format(MailType.TitleContentConfig["SendChips"].title, sender),
		content = string.format(MailType.TitleContentConfig["SendChips"].content, sender),
		sender = sender,
		attachments = json.encode(props),
		player_id = request.player_id,
		mail_type = MailType.MailTypes.PROP_REISSUE,--类型1:激励视频，2：屏蔽广告计费点，3：INBOX SALE，4：Tournament奖励，5：升级客户端版本奖励，6：商品补发邮件，7：后台道具补发邮件
	}

	MailDAL.Calculate.AddMail(Task:Current(), request.player_id, data)

	response = {
		header = response.header,
		ret = Return.OK()
	}

	return response
end

FinishClubChallenge = function(_M, session, request)
	local response = {
		header = {
			router = "AsyncResponse",
			client_id = session.client_id,
			task_id = request.header.task_id
		}
	}

	local all_player_id = request.player_id
	--player_id is repeated
	local props = json.decode(request.props)
	for k, v in ipairs(all_player_id) do
		local data = {
			title = MailType.TitleContentConfig["FinishClubChallenge"].title,
			content = MailType.TitleContentConfig["FinishClubChallenge"].content,
			sender = "system",
			attachments = json.encode(props),
			player_id = v,
			mail_type = MailType.MailTypes.PROP_REISSUE,--类型1:激励视频，2：屏蔽广告计费点，3：INBOX SALE，4：Tournament奖励，5：升级客户端版本奖励，6：商品补发邮件，7：后台道具补发邮件
		}
		-- session:WriteQueue("present", json.encode(data))
		MailDAL.Calculate.AddMail(Task:Current(), request.player_id, data)
	end

	response.ret = Return.OK()
	--LOG
	return response
end

FeverQuestPrizeCardPackage = function(_M, session, request)
	local response = {
		header = {
			router = "AsyncResponse",
			client_id = session.client_id,
			task_id = request.header.task_id
		}
	}

	local player_id = request.player_id
	local props = json.decode(request.props)

	LOG(RUN, INFO).Format("[Mail][FeverQuestPrizeCardPackage] 发送邮件 player %s props %s", player_id, props)

	local data = {
		title = MailType.TitleContentConfig["FeverQuestPrizeCardPackage"].title,
		content = MailType.TitleContentConfig["FeverQuestPrizeCardPackage"].content,
		sender = "system",
		attachments = json.encode(props),
		player_id = player_id,
		mail_type = MailType.MailTypes.FEVER_QUEST_CARD_PACKAGE
	}
	-- session:WriteQueue("present", json.encode(data))
	MailDAL.Calculate.AddMail(Task:Current(), request.player_id, data)

	response.ret = Return.OK()
	return response
end

BoosterCashback = function(_M, session, request)
	local response = {
		header = {
			router = "AsyncResponse",
			client_id = session.client_id,
			task_id = request.header.task_id
		}
	}

	local player_id = request.player_id
	local chips = request.chips or 0
	local props = {[1] = {1000, chips}}

	LOG(RUN, INFO).Format("[Mail][BoosterCashback] 发送邮件 player %s chips %s", player_id, chips)
	
	local data = {
		title = MailType.TitleContentConfig["BoosterCashback"].title,
		content = MailType.TitleContentConfig["BoosterCashback"].content,
		sender = "system",
		attachments = json.encode(props),
		player_id = player_id,
		mail_type = MailType.MailTypes.BOOSTER_CASHBACK
	}
	
	MailDAL.Calculate.AddMail(Task:Current(), request.player_id, data)

	response.ret = Return.OK()
	return response
end

FeverQuestPrizeCoin = function(_M, session, request)
	local response = {
		header = {
			router = "AsyncResponse",
			client_id = session.client_id,
			task_id = request.header.task_id
		}
	}

	local player_id = request.player_id
	local win_chip = request.win_chip or 0
	local props = json.decode(request.props)

	LOG(RUN, INFO).Format("[Mail][FeverQuestPrizeCoin] 发送邮件 player %s win_chip %s props %s", player_id, win_chip, props)
	
	local data = {
		title = MailType.TitleContentConfig["FeverQuestPrizeCoin"].title,
		content = string.format(MailType.TitleContentConfig["FeverQuestPrizeCoin"].content, win_chip),
		sender = "system",
		attachments = json.encode(props),
		player_id = player_id,
		mail_type = MailType.MailTypes.FEVER_QUEST_CHIP
	}

	MailDAL.Calculate.AddMail(Task:Current(), request.player_id, data)

	response.ret = Return.OK()
	return response
end

FeverQuestPrizeVipPoint = function(_M, session, request)
	local response = {
		header = {
			router = "AsyncResponse",
			client_id = session.client_id,
			task_id = request.header.task_id
		}
	}

	local player_id = request.player_id
	local vip_point = request.vip_point or 0
	local props = json.decode(request.props)

	LOG(RUN, INFO).Format("[Mail][FeverQuestPrizeVipPoint] 发送邮件 player %s vip_point %s props %s", player_id, vip_point, props)
	
	local data = {
		title = MailType.TitleContentConfig["FeverQuestPrizeVipPoint"].title,
		content = string.format(MailType.TitleContentConfig["FeverQuestPrizeVipPoint"].content, vip_point),
		sender = "system",
		attachments = json.encode(props),
		player_id = player_id,
		mail_type = MailType.MailTypes.FEVER_QUEST_VIP_POINT
	}
	-- session:WriteQueue("present", json.encode(data))
	MailDAL.Calculate.AddMail(Task:Current(), request.player_id, data)

	response.ret = Return.OK()
	return response
end

SettleTournament = function(_M, session, request)
	local response = {
		header = {
			router = "AsyncResponse",
			client_id = session.client_id,
			task_id = request.header.task_id
		}
	}

	local all_player_id = request.player_id
	local club_rank = request.rank
	local props = json.decode(request.props)
	for k, v in ipairs(all_player_id) do
		local data = {
			title = MailType.TitleContentConfig["SettleTournament"].title,
			content = string.format(MailType.TitleContentConfig["SettleTournament"].content, club_rank),
			sender = "system",
			attachments = json.encode(props),
			player_id = v,
			mail_type = MailType.MailTypes.TOURNAMENT_AWARD,--类型1:激励视频，2：屏蔽广告计费点，3：INBOX SALE，4：Tournament奖励，5：升级客户端版本奖励，6：商品补发邮件，7：后台道具补发邮件
		}
		-- session:WriteQueue("present", json.encode(data))
		MailDAL.Calculate.AddMail(Task:Current(), request.player_id, data)
	end
	response.ret = Return.OK()
	return response
end

JoinClub = function(_M, session, request)
	local response = {
		header = {
			router = "AsyncResponse",
			client_id = session.client_id,
			task_id = request.header.task_id
		}
	}

	local player_id = request.player_id
	local props = json.decode(request.props)
	local data = {
		title = MailType.TitleContentConfig["JoinClub"].title,
		content = MailType.TitleContentConfig["JoinClub"].content,
		sender = "system",
		attachments = json.encode(props),
		player_id = player_id,
		mail_type = MailType.MailTypes.PROP_REISSUE,--类型1:激励视频，2：屏蔽广告计费点，3：INBOX SALE，4：Tournament奖励，5：升级客户端版本奖励，6：商品补发邮件，7：后台道具补发邮件
	}
	-- session:WriteQueue("present", json.encode(data))
	MailDAL.Calculate.AddMail(Task:Current(), request.player_id, data)
	response.ret = Return.OK()
	return response
end

BindFacebook = function(_M, session, request)
	local response = {
		header = {
			router = "AsyncResponse",
			client_id = session.client_id,
			task_id = request.header.task_id
		}
	}

	local player_id = request.player_id
	local props = json.decode(request.props)
	local data = {
		title = MailType.TitleContentConfig["BindFacebook"].title,
		content = MailType.TitleContentConfig["BindFacebook"].content,
		sender = "system",
		attachments = json.encode(props),
		player_id = player_id,
		mail_type = MailType.MailTypes.PROP_REISSUE,--类型1:激励视频，2：屏蔽广告计费点，3：INBOX SALE，4：Tournament奖励，5：升级客户端版本奖励，6：商品补发邮件，7：后台道具补发邮件
	}
	MailDAL.Calculate.AddMail(Task:Current(), request.player_id, data)
	--session:WriteQueue("present", json.encode(data))
	response.ret = Return.OK()
	return response
end

VersionAward = function(_M, session, request)
	local response = {
		header = {
			router = "AsyncResponse",
			client_id = session.client_id,
			task_id = request.header.task_id
		}
	}

	local player_id = request.player_id
	local props = json.decode(request.props)
	LOG(RUN, INFO).Format("[Mail][VersionAward] Request is:%s", Table2Str(request))
	local data = {
		title = MailType.TitleContentConfig["VersionAward"].title,
		content = MailType.TitleContentConfig["VersionAward"].content,
		sender = "system",
		attachments = json.encode(props),
		player_id = player_id,
		mail_type = MailType.MailTypes.UPDATE_VERSION,--类型1:激励视频，2：屏蔽广告计费点，3：INBOX SALE，4：Tournament奖励，5：升级客户端版本奖励，6：商品补发邮件，7：后台道具补发邮件
	}
	--session:WriteQueue("present", json.encode(data))
	MailDAL.Calculate.AddMail(Task:Current(), request.player_id, data)
	response.ret = Return.OK()

	return response
end

-- 锦标赛奖励
TournamentPrize = function(_M, session, request)
	local response = {
		header = {
			router = "AsyncResponse",
			client_id = session.client_id,
			task_id = request.header.task_id
		}
	}

	local prop_list = json.decode(request.props)

	local data = {
		title = MailType.TitleContentConfig["TournamentPrize"].title,
		content = string.format(MailType.TitleContentConfig["TournamentPrize"].content, request.rank_str),
		sender = "system",
		attachments = json.encode(prop_list),
		player_id = request.player_id,
		mail_type = MailType.MailTypes.TOURNAMENT_AWARD,--类型1:激励视频，2：屏蔽广告计费点，3：INBOX SALE，4：Tournament奖励，5：升级客户端版本奖励，6：商品补发邮件，7：后台道具补发邮件
		json_str = request.json_str,
	}
	LOG(RUN, INFO).Format("[Mail][TournamentPrize] player %s, data is:%s", request.player_id, Table2Str(data))
	--session:WriteQueue("present", json.encode(data))
	MailDAL.Calculate.AddMail(Task:Current(), request.player_id, data)
	response.ret = Return.OK()

	return response
end

-- 每日Bonus奖励
DailyBonusAward = function(_M, session, request)
	local response = {
		header = {
			router = "AsyncResponse",
			client_id = session.client_id,
			task_id = request.header.task_id
		}
	}

	LOG(RUN, INFO).Format("[Mail][DailyBonusAward] player %s", request.player_id)
	local daily_bonus_data_list = MailDAL.Calculate.GetMailsByType(Task:Current(), request.player_id, MailType.MailTypes.DAILY_BONUS_AWARD)
	if #daily_bonus_data_list == 0 then
		local prop_list = json.decode(request.props)

		local data = {
			title = MailType.TitleContentConfig["DailyBonus"].title,
			content = MailType.TitleContentConfig["DailyBonus"].content,
			sender = "system",
			attachments = json.encode(prop_list),
			player_id = request.player_id,
			mail_type = MailType.MailTypes.DAILY_BONUS_AWARD,--类型1:激励视频，2：屏蔽广告计费点，3：INBOX SALE，4：Tournament奖励，5：升级客户端版本奖励，6：商品补发邮件，7：后台道具补发邮件, 8每日Bonus奖励
		}
		MailDAL.Calculate.AddMail(Task:Current(), request.player_id, data)
	end
	response.ret = Return.OK()

	return response
end
