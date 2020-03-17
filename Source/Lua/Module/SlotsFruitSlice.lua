require "Common/SlotsFruitSliceCal"
require "Common/RequestFilter"
require "Module/DailyTask"
module("SlotsFruitSlice", package.seeall)

-----------------------------------------------
-- 进入房间
------------------------------------------------
Enter = function(_M, session, request)
	local response = {header = {router = "Response"}}
	local filter_ret = RequestFilter.Filter("SlotsFruitSlice", "Enter", session, request, true)
	if filter_ret then
		response.ret = filter_ret
		return response
	end
	local task = session.task
	local player = session.player

	local player_slots_info = CommonCal.Calculate.get_slots_info(session, task, player, GameType.AllTypes.FruitSlice)
	local fruit_slice = json.decode(player_slots_info.content)

	CommonCal.Calculate.MakeUpInRoom(session, task)
	local isLock = CommonCal.Calculate.LevelReq(player, GameType.AllTypes.FruitSlice)
	if (isLock == 1) then
		response.ret = Return.LOCK_GAME()
		return response
	end

	local table_id = request.table_id
	local async_request = nil
	local game_room_config = GameRoomConfig[GameType.AllTypes.FruitSlice]

	if (table_id and table_id > 0) then
		local channel_id = string.format("%s.%s.%s", "SlotsFruitSliceContest", game_room_config.room_name, table_id)
		fruit_slice.channel_id = channel_id
		async_request = {
			header = {
				router = "AsyncRequest",
				service_name = game_room_config.contest_client_name,
				task_id = task.id,
				module_id = "SlotsFruitSliceContest",
				message_id = "SlotsFruitSliceContest_Enter_Request"
			},
			player = {
				id = player.id,
				user = player.user,
				account = player.account,
				game_type = GameType.AllTypes.FruitSlice,
				character = {
					chip = player.character.chip,
					vip = player.character.vip,
					level = player.character.level,
					experience = player.character.experience,
					player_type = player.character.player_type
				},
				record = player.record,
				fruit_slice = fruit_slice
			}
		}
	else
		async_request = {
			header = {
				router = "AsyncRequest",
				service_name = game_room_config.contest_client_name,
				task_id = task.id,
				module_id = "SlotsFruitSliceContest",
				message_id = "SlotsFruitSliceContest_Enter_Request"
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
					player_type = player.character.player_type
				},
				record = player.record,
				fruit_slice = fruit_slice
			}
		}
	end

	local async_response = session:ContactPacket(task, async_request)
	LOG(CSL, INFO).Format("[SlotsFruitSlice][Enter] player %s successfully entered SlotsFruitSliceContest", player.id)
	if async_response.ret.code ~= 0 then
		response.ret = async_response.ret
		return response
	end
	local table_sync_notice = {
		header = {
			router = "Notice"
		},
		table = async_response.table,
		bonus = async_response.bonus
	}

	fruit_slice.channel_id = async_response.channel_id

	--opt entertable
	local channel_id = async_response.channel_id
	local contest_id, room_id, table_id = unpack(string.split(channel_id, "."))
	local table_mates = {}
	for _, v in pairs(async_response.table.seat) do
		if v.player then
			table.insert(table_mates, v.player.id)
		end
	end

	Spark:EnterTable(
		player,
		{
			[1] = contest_id,
			[2] = room_id,
			[3] = table_id,
			[4] = #table_mates,
			[5] = table_mates
		}
	)

	local async_request = {
		header = {
			router = "AsyncRequest",
			service_name = "NotificationClientService",
			task_id = task.id,
			module_id = "Distributor",
			message_id = "Distributor_Register_Request"
		},
		session_id = session.id,
		player_id = player.id,
		channel_id = {async_response.channel_id},
		drop_channel_id = {"Hall"},
		player_type = session.player.character.player_type
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

	fruit_slice.bouts_id = 0
	 --进场的时候把cd清空掉
	fruit_slice.enter_chip = player.character.chip
	fruit_slice.spined_times = 0
	fruit_slice.trigger_times = 0
	fruit_slice.trigger_amounts = "[]"

	response.ret = Return.OK()
	response.player = {
		fruit_slice = fruit_slice,
		character = {
			chip = player.character.chip
		}
	}
	player.game_type = GameType.AllTypes.FruitSlice

	player_slots_info.content = json.encode(fruit_slice)
	CommonCal.Calculate.UpdateSlotsToDbCache(task, player, player_slots_info)

	return response, table_sync_notice
end

--开始slots
Start = function(_M, session, request)
	local response = {header = {router = "Response"}}

	local filter_ret = RequestFilter.Filter("SlotsFruitSlice", "Start", session, request, true)
	if filter_ret then
		response.ret = filter_ret
		return response
	end

	local task = session.task
	local player = session.player

	local player_slots_info = CommonCal.Calculate.get_slots_info(session, task, player, GameType.AllTypes.FruitSlice)
	local fruit_slice = json.decode(player_slots_info.content)

	CommonCal.Calculate.BeginStart(session, task, player)

	if GlobalState:IsSlotsMaintenance(session, task, player.id) == 1 then
		response.ret = Return.SERVER_NEAR_MAINENANCE()
		return response
	end
	if (player.game_type ~= GameType.AllTypes.FruitSlice) then
		response.ret = Return.HAVE_ALREADY_EXIT_GAME()
		return response
	end
	local is_lock = CommonCal.Calculate.IsAppear(player)
	if (is_lock == 1) then
		response.ret = Return.LOCK_GAME()
		return response
	end

	local amount = request.amount
	local chip_cost = amount * 25

	if not Player:Consume(player, {"Chip", chip_cost}, Reason.FRUITSLICE_BET_CHIP_CONSUME()) then
		response.ret = Return.GAME_PLAYER_CHIP_NOT_ENOUGH()
		return response
	end
	fruit_slice.bet_amount = amount

	if (Base.Enviroment.pro_spec_t ~= "online" and player.character.player_type ~= tonumber(ConstValue[5].value)) then
		local async_request = {
			header = {
				router = "LocalRequest",
				service_name = "DispatcherService",
				task_id = task.id,
				module_id = "SlotsTest",
				message_id = "SlotsTest_Init_Request"
			},
			player_id = player.id
		}

		local async_response = session:ContactPacket(task, async_request)
	end

	fruit_slice.bouts_id = os.time()
	local game_room_config = GameRoomConfig[GameType.AllTypes.FruitSlice]
	local tran_init_result, all_prize, all_drop_items, all_erase_items, all_total_payrate, trigger_bonus, reel_file_name =
		SlotsFruitSliceCal.Calculate.GenItemResult(player)

	local all_prize_items = all_prize

	response.ret = Return.OK()
	response.item_ids = SlotsFruitSliceCal.Calculate.TransResultToList(tran_init_result)
	response.all_prize = all_prize
	response.all_drop_items = all_drop_items
	response.all_erase_items = all_erase_items

	if trigger_bonus then
		response.trigger_bonus = 1
		fruit_slice.trigger_times = math.min(fruit_slice.trigger_times + 1, 6)
		local trigger_amounts = json.decode(fruit_slice.trigger_amounts)
		table.insert(trigger_amounts, amount)
		fruit_slice.trigger_amounts = json.encode(trigger_amounts)
		--tell contest to increase this room's trigger_times
		local async_request = {
			header = {
				router = "AsyncRequest",
				service_name = game_room_config.contest_client_name,
				task_id = task.id,
				module_id = "SlotsFruitSliceContest",
				message_id = "SlotsFruitSliceContest_Start_Request" --增加进度协议
			},
			player_id = player.id,
			erase_times = #all_erase_items
		}
		local async_response = session:ContactPacket(task, async_request)
		if async_response.ret.code ~= 0 then
			response.ret = async_response.ret
			return response
		end
	end

	local all_win_chip = {}
	local all_win_chip_value = 0
	local total_payrate = 0
	for k, v in ipairs(all_total_payrate) do
		all_win_chip[k] = v * amount
		all_win_chip_value = all_win_chip_value + v * amount
		total_payrate = total_payrate + v
	end
	response.win_chip = all_win_chip
	response.all_win_chip = all_win_chip_value

	local FruitSliceBetAmountConfig = CommonCal.Calculate.get_config(player, "FruitSliceBetAmountConfig")
	local bet_amount_conf
	for k, v in ipairs(FruitSliceBetAmountConfig) do
		if v.single_amount == amount then
			bet_amount_conf = v
			break
		end
	end

	----记录record
	player.record.total_spin = player.record.total_spin + 1

	local win_chip = total_payrate * amount

	if win_chip > 0 then
		Player:Obtain(player, {"Chip", win_chip}, Reason.FRUITSLICE_BET_CHIP_OBTAIN())

		--记录每日、每周赢钱,进排行榜
		RankHelper:ChallengeDailyWin(player)
		RankHelper:ChallengeWeeklyWin(player)
		--free spin不计入biggest win的统计
		local rep_free_spin = 0
		local rep_data = {
			item_ids = response.item_ids,
			bet_amount = amount,
			all_prize = all_prize,
			all_drop_items = all_drop_items,
			all_erase_items = all_erase_items,
			win_chip = all_win_chip, --保证客户端字段名一致,win_chip实际上是个数组
			all_win_chip = win_chip,
			free_spin = rep_free_spin
		}
		RankHelper:ChallengeDailyBiggestWin(player, GameType.AllTypes.FruitSlice, rep_data)
		RankHelper:ChallengeWeeklyBiggestWin(player, GameType.AllTypes.FruitSlice, rep_data)
		----记录record
		player.record.spin_won = player.record.spin_won + 1
		player.record.total_win = player.record.total_win + win_chip
		if win_chip > player.record.biggest_win then
			player.record.biggest_win = win_chip
		end
	end

	local free_win_amount = 0
	if (is_free_spin) then
		free_win_amount = win_chip
	end

	local FruitSlicePrizeConfig = CommonCal.Calculate.get_config(player, "FruitSlicePrizeConfig")

	--accomplish tasks
	local task_req_data = {
		five_line = CommonCal.Calculate.GetFiveLineCount(all_prize),
		base_spin = not is_free_spin,
		win_amount = win_chip,
		bet_amount = amount * 25,
		max_bet = amount >= SlotsFruitSliceCal.Calculate.GetMaxBetAmount(player),
		bonus_game = fruit_slice.trigger_times == 6,
		free_win_amount = free_win_amount,
		epic_win = (total_payrate / 25) >= FruitSlicePrizeConfig[3].min_multiple
	}
	DailyTask:CompleteTask(session, player, task_req_data)

	local history_games = json.decode(player.statistics.history_games)
	local is_exist = false
	for _, v in pairs(history_games) do
		if (v == player.game_type) then
			is_exist = true
			break
		end
	end
	if (not is_exist) then
		table.insert(history_games, player.game_type)
	end
	player.statistics.history_games = json.encode(history_games)
	player.statistics.last_game = player.game_type
	if ((win_chip / (amount * 25)) >= FruitSlicePrizeConfig[3].min_multiple) then
		player.statistics.epicwin_num = player.statistics.epicwin_num + 1
	elseif ((win_chip / (amount * 25)) >= FruitSlicePrizeConfig[2].min_multiple) then
		player.statistics.megawin_num = player.statistics.megawin_num + 1
	elseif ((win_chip / (amount * 25)) >= FruitSlicePrizeConfig[1].min_multiple) then
		player.statistics.bigwin_num = player.statistics.bigwin_num + 1
	end

	if (fruit_slice.trigger_times == 6) then
		player.statistics.bonus_game_num = player.statistics.bonus_game_num + 1
	end

	if (fruit_slice.bonus_win_chip > 0) then
		local number = fruit_slice.bonus_win_chip / (fruit_slice.bet_amount * 25)
		CommonCal.Calculate.CalBonusAward(player, number)
		fruit_slice.bonus_win_chip = 0
	end

	Player:BroadCastChip(session, task, amount * 25, win_chip)

	local can_multiply = SlotsGameCal.Calculate.WinChipInMultiply(win_chip)
	if (can_multiply) then
		if ((total_payrate / 25) >= FruitSlicePrizeConfig[1].min_multiple and not is_free_spin) then
			response.is_multiply = CommonCal.Calculate.IsMultiply(session, win_chip)
		end

		if ((total_payrate / 25) >= ForbiddenCityPrizeConfig[1].min_multiple and not is_free_spin) then
			RobotAction.BigWinAction(session, task)
		end
	end

	--广播
	local win_info = {
		bet_amount = amount,
		total_bet = amount * 25,
		win_chip = win_chip
	}
	Communication:OnBcEvent(session, BroadcastType.AllTypes.FruitSliceSpin, win_info, 15)

	--LOG(RUN, INFO).Format("[SlotsFruitSlice][Start] player %s all_prize_items is %s", player.id, Table2Str(all_prize_items))
	--opt
	local contest_id, room_id, table_id = unpack(string.split(fruit_slice.channel_id, "."))
	if (is_free_spin) then
		Spark:SlotsAward(
			player,
			{
				[1] = GameType.AllTypes.FruitSlice,
				[2] = "FruitSlice",
				[3] = table_id,
				[4] = fruit_slice.bouts_id,
				[5] = fruit_slice.bet_amount,
				[6] = win_chip,
				[7] = json.encode(origin_result),
				[8] = "[]",
				[9] = reel_file_name,
				[10] = fruit_slice.free_spin_bouts,
				[11] = CommonCal.Calculate.GetFiveLineCount(all_prize_items) > 0 and 1 or 0,
				[12] = player.record.total_spin,
				[13] = amount * 25
			}
		)
	else
		Spark:SlotsStart(
			player,
			{
				[1] = GameType.AllTypes.FruitSlice,
				[2] = "FruitSlice",
				[3] = table_id,
				[4] = fruit_slice.bouts_id,
				[5] = amount,
				[6] = amount * 25,
				[7] = win_chip,
				[8] = json.encode(tran_init_result),
				[9] = "[]",
				[10] = false,
				[11] = reel_file_name,
				[12] = CommonCal.Calculate.GetFiveLineCount(all_prize_items) > 0 and 1 or 0,
				[13] = player.record.total_spin
			}
		)
	end

	--buyloss的局数+1
	fruit_slice.spined_times = fruit_slice.spined_times + 1

	-- response.win_chip = win_chip

	CommonCal.Calculate.EndStart(session, task, player, request, response, fruit_slice, 25, chip_cost, win_chip)

	--gain exp
	local exp = chip_cost
	local exp_request = {
		type = "SlotsFruitSlice",
		ante_gold = amount * 25,
		gain_exp = exp
	}
	Player:GainExp(session, exp_request)

	player_slots_info.content = json.encode(fruit_slice)
	CommonCal.Calculate.UpdateSlotsToDbCache(task, player, player_slots_info)

	--锦标赛玩家得分更新
	CommonCal.Calculate.UpdateTournamentPlayerInfo(session, player.game_type, player, chip_cost, win_chip)

	response.player = {
		unlock_games = player.unlock_games,
		character = {
			chip = player.character.chip,
			experience = player.character.experience,
			level = player.character.level
		},
		fruit_slice = {
			bet_amount = amount
		}
	}

	return response
end

-----------------------------------------------
-- 退出房间
------------------------------------------------
Exit = function(_M, session, request)
	local response = {header = {router = "Response"}}
	local filter_ret = RequestFilter.Filter("SlotsFruitSlice", "Exit", session, request, true)
	if filter_ret then
		response.ret = filter_ret
		return response
	end

	local player = session.player
	local task = session.task

	local player_slots_info = CommonCal.Calculate.get_slots_info(session, task, player, GameType.AllTypes.FruitSlice)
	local fruit_slice = json.decode(player_slots_info.content)

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
			module_id = "SlotsFruitSliceContest",
			message_id = "SlotsFruitSliceContest_Exit_Request"
		},
		player_id = player.id
	}

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

	Spark:LeaveTable(
		player,
		{
			[1] = contest_id,
			[2] = room_id,
			[3] = table_id,
			[4] = #table_mates,
			[5] = table_mates
		}
	)

	local async_request = {
		header = {
			router = "AsyncRequest",
			service_name = "NotificationClientService",
			task_id = task.id,
			module_id = "Distributor",
			message_id = "Distributor_Register_Request"
		},
		session_id = session.id,
		player_id = player.id,
		channel_id = {"Hall"},
		drop_channel_id = {async_response.channel_id},
		player_type = session.player.character.player_type
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

	local trigger_buyloss, total_loss, diamond, goods_id =
		BuyLoss:Trigger(session, task, GameType.AllTypes.FruitSlice, player)
	if trigger_buyloss then
		fruit_slice.total_loss = total_loss
		session:WriteRouterPacket(
			{
				header = {
					router = "SpecificNotice",
					session_id = session.id,
					player_id = player.id,
					module_id = "BuyLoss",
					message_id = "BuyLoss_Trigger_Notice"
				},
				total_loss = total_loss,
				diamond = diamond,
				goods_id = goods_id
			}
		)
	end
	fruit_slice.spined_times = 0

	fruit_slice.trigger_times = 0
	fruit_slice.trigger_amounts = "[]"

	response = {
		header = response.header,
		ret = Return.OK(),
		player = {
			character = {
				chip = player.character.chip
			}
		}
	}

	player_slots_info.content = json.encode(fruit_slice)
	CommonCal.Calculate.UpdateSlotsToDbCache(task, player, player_slots_info)

	LOG(RUN, INFO).Format("[SlotsFruitSlice][Exit] ok player %s", player.id)
	return response
end

Slice = function(_M, session, request)
	local response = {header = {router = "Response"}}
	local filter_ret = RequestFilter.Filter("SlotsFruitSlice", "Slice", session, request, true)
	if filter_ret then
		response.ret = filter_ret
		return response
	end

	local player = session.player
	local task = session.task
	local fruit_id = request.fruit_id

	local player_slots_info = CommonCal.Calculate.get_slots_info(session, task, player, GameType.AllTypes.FruitSlice)
	local fruit_slice = json.decode(player_slots_info.content)

	local combo = #fruit_id
	combo = math.min(combo, 23)
	 --最多23连
	combo = math.max(combo, 1)
	 --最少1连
	local trigger_times = 1
	 --fruit_slice.trigger_times

	local trigger_amounts = json.decode(fruit_slice.trigger_amounts)

	local FruitSliceBetAmountConfig = CommonCal.Calculate.get_config(player, "FruitSliceBetAmountConfig")

	local bet_amount
	if trigger_amounts and #trigger_amounts > 0 then
		local sum = 0
		for _, v in ipairs(trigger_amounts) do
			sum = sum + v
		end
		local avg = sum / #trigger_amounts
		for _, v in ipairs(FruitSliceBetAmountConfig) do
			if v.single_amount >= avg then
				bet_amount = v.single_amount
				break
			end
		end
		if not bet_amount then
			bet_amount = FruitSliceBetAmountConfig[1].single_amount
		end
	else
		bet_amount = FruitSliceBetAmountConfig[1].single_amount
	end

	LOG(RUN, INFO).Format(
		"[SlotsFruitSlice][Slice] trigger_times %s combo %s bet_amount %s",
		tostring(trigger_times),
		tostring(combo),
		tostring(bet_amount)
	)
	local win_chip =
		CommonCal.Calculate.get_config(player, "FruitSliceComboConfig")[trigger_times].combo[combo] * bet_amount * 25

	fruit_slice.bonus_win_chip = fruit_slice.bonus_win_chip + win_chip
	local game_room_config = GameRoomConfig[GameType.AllTypes.FruitSlice]

	local async_request = {
		header = {
			router = "AsyncRequest",
			service_name = game_room_config.contest_client_name,
			task_id = task.id,
			module_id = "SlotsFruitSliceContest",
			message_id = "SlotsFruitSliceContest_Slice_Request"
		},
		fruit_id = fruit_id,
		player_id = player.id,
		win_chip = win_chip
	}
	local async_response = session:ContactPacket(task, async_request)
	if async_response.ret.code ~= 0 then
		response.ret = async_response.ret
		return response
	end

	Player:Obtain(player, {"Chip", win_chip}, Reason.FRUITSLICE_SLICE_CHIP_OBTAIN())

	Player:BroadCastChip(session, task, 0, 0)

	local task_req_data = {
		bonus_win_amount = win_chip
	}
	DailyTask:CompleteTask(session, player, task_req_data)

	response.player = {
		character = {
			chip = player.character.chip
		}
	}
	response.win_chip = win_chip
	response.ret = Return.OK()

	-- opt exit
	local contest_id, room_id, table_id = unpack(string.split(fruit_slice.channel_id, "."))
	local table_mates = {}

	Spark:FruitSliceSlice(
		player,
		{
			[1] = contest_id,
			[2] = room_id,
			[3] = table_id,
			[4] = fruit_slice.bouts_id,
			[5] = bet_amount,
			[6] = bet_amount * 25,
			[7] = table_mates,
			[8] = combo,
			[9] = win_chip
		}
	)

	--锦标赛玩家得分更新
	CommonCal.Calculate.UpdateTournamentPlayerInfo(session, player.game_type, player, 0, win_chip)

	player_slots_info.content = json.encode(fruit_slice)
	CommonCal.Calculate.UpdateSlotsToDbCache(task, player, player_slots_info)

	return response
end
