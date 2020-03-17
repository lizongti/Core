------------------
-- Player和DbPlayer.proto是一致，玩家登陆时根据DbPlayer.proto从redis中读取数据保存到Player.lua中。Player.proto作为传输协议，每加一个玩法就要将Player.proto更新 --
------------------
require "Config/ServerConfig"

_G.Player = {}

local init_player = {
	id = 0,
	expire = 0,
	version = 0,
	game_type = 0,
	unlock_games = "[]",
	unlock_diamond_games = "[]",
	--钻石解锁的游戏
	unlock_free_games = "[]",
	--升级解锁
	mega_win_chips = "[]",
	mega_win_time = 0,
	mega_win_number = 0,
	cash_casino_chips = 0,
	cash_casino_time = 0,
	cash_casino_number = 0,
	total_pure_win_chip = 0,
	user = {
		sex = 0,
		nickname = "NewUser",
		location = "",
		age = 0,
		country = "",
		signature = "Enjoy life, playing Vegas Slots!",
		avatar = math.random(1, 10)
		--0 stands for facebook avatar
	},
	account = {
		account_type = "",
		facebook_id = "",
		google_id = ""
	},
	client = {
		app_name = "",
		package = "",
		version = "",
		channel = "",
		eth_ip = "",
		ip = "",
		mac = "",
		device = "",
		os = "",
		os_version = "",
		imei_idfa = "",
		device_id = "",
		device_token = ""
	},
	character = {
		chip = 0,
		level = 1,
		charge = 0,
		vip = 0,
		login_time = 0,
		last_login_time = 0,
		experience = 0,
		android_charge = 0,
		ios_charge = 0,
		month_charge = 0,
		daily_charge = 0,
		create_time = 0,
		action = "",
		chat_time = 0,
		emotion_time = 0,
		init_channel = "",
		charge_time = 0,
		diamond = 0,
		like = 0,
		daily_win = 0,
		weekly_win = 0,
		last_collect_time = 0,
		--os.time() - 0.5 * 3600,--player first login, can get a 0.5 hour lobby bonus
		vip_points = 0,
		treat_time = 0,
		pot_points = 10000,
		daily_biggest_win = 0,
		weekly_biggest_win = 0,
		yes_daily_win = 0,
		yes_biggest_win = 0,
		purchased_pot = 0, --存钱罐,激活状态.0为未激活,1是激活状态->可以按照时间领取奖励
		complete_guidance = 0,
		alms_fetch_time = 0,
		rated_us = 0,
		daily_task_reset_time = 0,
		login_award_time = 0,
		collect_times = 0,
		last_collect_reset_time = 0,
		has_reset_cllect = 0,
		login_award_seconds = 0,
		off_line_time = 0,
		daily_task_week_reset_time = 0,
		daily_task_week_complete_count = 0,
		daily_task_week_info = "[]",
		bronze_fetched = 0,
		silver_fetched = 0,
		gold_fetched = 0,
		is_old_hand = 1,
		is_get_vip_award = 0,
		recharge_count = 0,
		spin_number = 0,
		pot_limit_time = 0, --存钱罐,服务到期时间
		pot_collect_time = 0, --存钱罐,下次可领取时间
		pot_last_collect_time = 0, --存钱罐,最后一次计算存钱罐自动增长筹码,的时间
		player_type = 0,
		last_charge = 0,
		order_payment_ids = "[]",
		level_up_chip = 0,
		last_charge_str = "0",
		charge_str = "0",
		collect_ad = 0,
		total_login_times = 0,
		fir_chips = 0,
		last_wheel_time = 0,
		pay_fail_award = 0,
		rand_seed = 0,
		rand_num = 0,
		his_max_charge = 0,

		lucky = 0,
		unlucky = 0,
		lucky_credit_change = 0,
		

		lucky_mode = "Normal",
		piggy_bank_pay_count = 0, --购买次数
		piggy_bank_chip = 0,
		unlucky_credit_change = 0,

		enter_lucky = 0,
		enter_unlucky = 0,

		lucky_type = 1,
		stage_type = 1,
		experience_scale = -100,
	},
	prop = {
		normal = "[]"
	},
	task_info = {
		daily_task = "[]",
		daily_missions = "[]",
		panther_tracks = "[]"
	},
	record = {
		total_spin = 0,
		spin_won = 0,
		total_win = 0,
		biggest_win = 0,
		bonus_game = 0,
		free_spin = 0
	},
	daily_wheel = {
		continue_login_days = 0,
		acc_login_days = 0,
		json_str = "[]"
	},
	statistics = {
		history_games = "[]",
		last_game = 0,
		bigwin_num = 0,
		megawin_num = 0,
		epicwin_num = 0,
		bonus_game_num = 0,
		bonus_award = "[]"
	},
	new_hand_award = {
		pay_chip = 0, --玩家购买后所携带的chips
		ratio_a = 0,
		ratio_b = 0,
		ratio_d = 0,
		remain_num = 0
		--剩余次数
	},
	first_charge = {
		charge_info = "[]"
	},
	club_info = {
		club_id = -1,
		cups_winning = 0,
		last_fund_timestamp = 0,
		joined_club = 0
	},
	notice = {
		check_lobby_bonus = 0
	}
}

function Player:GetInitPlayer()
	return init_player
end

function Player:GetBaseInfo(player)
	local player_brief = {
		id = player.id,
		account = {
			facebook_id = player.account.facebook_id,
			google_id = player.account.google_id
		},
		user = {
			sex = player.user.sex,
			nickname = player.user.nickname,
			avatar = player.user.avatar
		},
		character = {
			chip = player.character.chip,
			vip = player.character.vip,
			level = player.character.level,
			experience = player.character.experience
		}
	}

	return player_brief
end

function Player:GetBrief(player)
	local player_brief = {
		id = player.id,
		account = {
			facebook_id = player.account.facebook_id,
			google_id = player.account.google_id
		},
		user = {
			sex = player.user.sex,
			nickname = player.user.nickname,
			signature = player.user.signature,
			age = player.user.age,
			country = player.user.country,
			location = player.user.location,
			avatar = player.user.avatar
		},
		character = {
			chip = player.character.chip,
			vip = player.character.vip,
			level = player.character.level,
			experience = player.character.experience
		},
		record = {
			total_spin = player.record.total_spin,
			spin_won = player.record.spin_won,
			total_win = player.record.total_win,
			biggest_win = player.record.biggest_win,
			bonus_game = player.record.bonus_game,
			free_spin = player.record.free_spin
		}
	}

	return player_brief
end

-------------------------- prop  start -------------------------
function Player:Count(player, item)
	return PropOperation:Type(item):Count(player)
end

function Player:Has(player, item, reason)
	if item[2] == 0 then
		return true
	end
	return PropOperation:Type(item):Has(player, item, reason)
end

function Player:Set(player, item, reason_obtain, reason_consume)
	local count = PropOperation:Type(item):Count(player)
	if count > item[2] then
		PropOperation:Type(item):Consume(player, {item[1], count - item[2]}, reason_consume)
	elseif count < item[2] then
		PropOperation:Type(item):Obtain(player, {item[1], item[2] - count}, reason_obtain)
	end
end

function Player:RobotBroadCastChip(session, task, bet_amount, win_chip, is_command)
	local player = session.player

	if (player.character.player_type ~= tonumber(ConstValue[5].value)) then
		return
	end

	if (player.game_type == 0 or player.game_type == tonumber(ConstValue[6].value)) then
		return
	end

	local game_service = GameRoomConfig[player.game_type].contest_client_name

	local game_key = GameRoomConfig[player.game_type].key_name

	if (game_key == nil) then
		return
	end

	LOG(RUN, INFO).Format("[RobotBroadCastChip] player %s, game_type is:%s", player.id, player.game_type)

	local async_request = {
		header = {
			router = "AsyncRequest",
			service_name = game_service,
			task_id = task.id,
			module_id = "SlotsBroadCastContest",
			message_id = "SlotsBroadCastContest_Chip_Request"
		}
	}
	async_request.player = {
		id = player.id,
		user = player.user,
		account = player.account,
		game_type = player.game_type,
		character = {
			chip = player.character.chip,
			vip = player.character.vip,
			level = player.character.level,
			experience = player.character.experience,
			player_type = player.character.player_type
		},
		record = player.record
	}

	async_request.chip = win_chip

	if (win_chip > 0 and bet_amount > 0) then
		if (win_chip / bet_amount >= 10) then
			async_request.is_big = 1
		else
			async_request.is_big = 0
		end
	else
		async_request.is_big = 0
	end

	async_request.player.user.avatar = player.user.avatar
	async_request.player.user.nickname = player.user.nickname
	async_request.player.character.level = player.character.level
	

	async_request.player[game_key] = {}
	local game_type = player.game_type
	async_request.player[game_key].channel_id =
		CommonCal.Calculate.get_game_info(session, task, player, game_type).channel_id

	if (is_command ~= nil and is_command == 1) then
		session:WriteRouterPacket(async_request)
	else
		--LOG(RUN, INFO).Format("[Player][BroadCastChip] player %s start end", player.id)
		--LOG(RUN, INFO).Format("[Player][BroadCastChip] player %s start async_request task id:%s", player.id, task.id)--Table2Str(async_request))
		local async_response = session:ContactPacket(task, async_request)
	end
end

function Player:BroadCastChip(session, task, bet_amount, win_chip, is_command)
end

function Player:BroadCastBaseInfo(session, task)
end

function Player:Obtain(player, item, reason)
	if item[2] == 0 then
		return true
	end
	return PropOperation:Type(item):Obtain(player, item, reason)
end

function Player:Consume(player, item, reason)
	if item[2] == 0 then
		return true
	end
	return PropOperation:Type(item):Consume(player, item, reason)
end

function Player:Purchase(player, item, reason)
	if item[2] == 0 then
		return true
	end
	return PropOperation:Type(item):Purchase(player, item, reason)
end

function Player:Use(player, item, reason, session)
	if item[2] == 0 then
		return true
	end
	return PropOperation:Type(item):Use(player, item, reason, session)
end

function Player:Sell(player, item, reason)
	if item[2] == 0 then
		return true
	end
	return PropOperation:Type(item):Sell(player, item, reason)
end

-------------------------- prop end -------------------------

-- function Player:ChallengeOverMaxGold(player, gold)
-- 	if player.record.max_hold_gold < player.character.gold then
-- 		player.record.max_hold_gold = player.character.gold
-- 		TaskInfo:ModifyMaxHoldGold(player, player.record.max_hold_gold)
-- 	end
-- end

-- function Player:ChallengeOverMaxWin(player, win)
--     if player.record.max_win_gold < win then
--         player.record.max_win_gold = win
--     end
-- end

function Player:InitExperience(session)
	local const_exp_value = 100000000000
	local player = session.player
	local level = player.character.level
	local experience = player.character.experience
	--处理旧玩家
	local max_level = #LevelConfig
	local max_experience = LevelConfig[max_level].experience_needed
	
	if level > max_level then
		return const_exp_value	
	end

	if player.character.experience_scale < 0 then
		local cur_experience_need = LevelConfig[level].experience_needed
		local next_experience_need = max_experience
		if level + 1 < max_level then
			next_experience_need = LevelConfig[level + 1].experience_needed
		end
		if level >= max_level then
			player.character.experience_scale = 0 
		else
			local scale_value = (experience - cur_experience_need) / (next_experience_need - cur_experience_need)
			-- LOG(RUN, INFO).Format("[Player][GainExp] player:%s, scale_value:%s", player.id, scale_value)
			if scale_value > 0 then
				player.character.experience_scale = math.floor(scale_value * const_exp_value + 0.5)
			else
				player.character.experience_scale = 0
			end
		end
		player.character.experience = math.floor(player.character.experience_scale / const_exp_value * LevelConfig[level].experience + 0.5)
		-- LOG(RUN, INFO).Format("[Player][GainExp]change player:%s, level:%s, experience:%s", player.id, level, player.character.experience)	
	end


	return const_exp_value		
end

local function CalcLevelUpChipOverMax(level)
	return 50000000 + ((math.ceil((level-500)/10) - 1) + (math.ceil((level-500)/100) - 1)) * 2000000
end

local function CalcLevelUpNeedExpOverMax(target_level)
	return 3400000000 + ((math.ceil((target_level-500)/10) - 1) + (math.ceil((target_level-500)/100) - 1)) * 200000000
end

function Player:CalcLevelUpNeedExp(level)
	local max_level = #LevelConfig
	local need_exp = 0
	if level > max_level then
		local target_level = level + 1
		need_exp = CalcLevelUpNeedExpOverMax(target_level)
	else
		need_exp = LevelConfig[level].experience
	end
	return need_exp
end

function Player:CalcLevelUpAddChip(try_level)
	local max_level = #LevelConfig
	local add_chip = 0
	if try_level > max_level then
		add_chip = CalcLevelUpChipOverMax(try_level)
	else
		add_chip = LevelConfig[try_level-1].award
	end
	return add_chip
end

function Player:GainExp(session, request)
	local ante_gold = request.ante_gold
	local gain_exp = request.gain_exp
	local player = session.player
	local level = player.character.level
	local experience = player.character.experience
	local level_up_gold = 0

	if gain_exp == 0 then
		return
	end

	local next_level = level
	local next_experience = experience

	--处理旧玩家
	
	local const_exp_value  = Player:InitExperience(session)
	experience = math.floor(player.character.experience_scale / const_exp_value * Player:CalcLevelUpNeedExp(level) + 0.5)
	local max_level = #LevelConfig

	next_experience = experience + gain_exp
	local need_exp = Player:CalcLevelUpNeedExp(next_level)
	if (next_experience >= need_exp) then
		next_level = level + 1
		next_experience = next_experience - need_exp
	end
	player.character.experience_scale = math.floor(next_experience / Player:CalcLevelUpNeedExp(next_level)  * const_exp_value + 0.5)

	player.character.experience = next_experience
	player.character.level = next_level

	--计算奖励
	local level_up_chip = 0 --升级奖励筹码
	local level_up_box_chip = 0 --升级礼盒的筹码奖励
	local level_up_box_award = nil --升级礼盒奖励信息
	local level_up_next_box_tip = nil --下个奖励盒子的提示

	if next_level > level then --存在升级时
		--任务完成触发
		DailyMissionsCal.Calculate.UpdateDailyMissions(session, player, "LevelUp", 1, {[1] = 1}, request.ante_gold)

		for i=level+1, next_level do
			FeverCardCal.OnLevelUp(session, player, i)
		end

		--奖励累计
		for try_level = level + 1, next_level do
			local add_chip = 0
			if try_level > max_level then
				--500级后的升级奖励
				--50000000+(ROUNDUP((下一等级-500)/10,0)-1)*2000000+2000000*((ROUNDUP((下一等级-500)/100,0))-1)
				local target_level = next_level + 1
				add_chip = CalcLevelUpChipOverMax(target_level)
			else
				--升级筹码奖励
				add_chip = LevelConfig[try_level].award
				LuckyCal.OnLevelUp(player, try_level)
			end
			
			--升级筹码奖励
			level_up_chip = add_chip * BoosterCal.GetLevelRushMultiple(session)

			--升级礼盒
			local try_award = LevelUpBoxAwardConfig[try_level] --等级的奖励
			if try_award then --存在盒子奖励
				--更新盒子总奖励
				level_up_box_chip = level_up_box_chip + try_award.chip

				--更新盒子信息
				if level_up_box_award then --之前已经有奖励，则累计
					level_up_box_award.box_type = try_award.box_type
					level_up_box_award.chip = level_up_box_award.chip + try_award.chip
				else --没有则直接赋值
					level_up_box_award = table.DeepCopy(try_award)
				end
			end
		end

		--下个奖励的提示
		level_up_next_box_tip = LevelUpBoxTIpConfig[next_level]
	end

	--筹码增加
	if level_up_chip > 0 then
		Player:Obtain(player, {"Chip", level_up_chip}, Reason.LEVEL_UP_PROP_OBTAIN())
	end
	if level_up_box_chip > 0 then
		Player:Obtain(player, {"Chip", level_up_box_chip}, Reason.LEVEL_UP_BOX_PROP_OBTAIN())
	end
	--经验增加
	player.character.level = next_level
	player.character.experience = current_experience
	RankHelper:ChallengeExperience(player)

	Spark:GainExp(
		player,
		{
			[1] = request.type,
			[2] = "Chip",
			[3] = ante_gold,
			[4] = gain_exp,
			[5] = level,
			[6] = next_level,
			[7] = "Chip",
			[8] = level_up_chip,
			[9] = player.character.create_time
		}
	)

	player.character.level_up_chip = level_up_chip
	-- notice
	--玩家从1级升到2级的时候不发notice,这个是属于新手引导的,新手引导的升级客户端自己处理的,不需要服务器的notice
	if next_level ~= level then
		session:WriteRouterPacket(
			{
				header = {
					router = "Notice",
					module_id = "Account",
					message_id = "Account_LevelUp_Notice"
				},
				experience = player.character.experience,
				level = player.character.level,
				chip = level_up_chip,
				box_award = level_up_box_award,
				next_box_tip = level_up_next_box_tip
			}
		)
	end
end

function Player:UpdateVIP(session, goods_id, double_purchase_vip_points)
	local player = session.player
	--unit of charge amount is cent, eg:2.99 dollar eq 299 cents
	LOG(RUN, INFO).Format("[Player][UpdateVIP] player_id:%s", player.id)
	if goods_id then
		cur_chop_config = CommonCal.Calculate.get_shop_config(player)
		local goods_conf = cur_chop_config[goods_id]
		local price = math.floor(goods_conf.price * 100 + 0.5)

		local price1 = goods_conf.price * 100

		LOG(RUN, INFO).Format(
			"[Player][UpdateVIP] player_id:%s, price is: %s, goods_conf.price is: %s, price1 is: %s",
			player.id,
			price,
			goods_conf.price,
			price1
		)
		local os_type = player.client.os
		if (string.find(os_type, "iOS") or string.find(os_type, "Mac")) then
			player.character.ios_charge = player.character.ios_charge + price
		else
			player.character.android_charge = player.character.android_charge + price
		end
		--if goods_conf.operation_sys == "IOS" then
		--    player.character.ios_charge = player.character.ios_charge + price
		-- elseif goods_conf.operation_sys == "Android" then
		--   player.character.android_charge = player.character.android_charge + price
		--end

		player.character.charge = player.character.ios_charge + player.character.android_charge

		if (player.character.his_max_charge < price) then
			player.character.his_max_charge = price
		end
		player.character.month_charge = player.character.month_charge + price
		player.character.daily_charge = player.character.daily_charge + price
		player.character.charge_time = os.time()

		player.character.last_charge = price

		player.character.charge_str = tostring(player.character.charge)
		player.character.last_charge_str = tostring(player.character.last_charge)

		local extra_vip_points = 0
		if (goods_conf.extra_vip_points ~= nil) then
			extra_vip_points = goods_conf.extra_vip_points
		end

		if double_purchase_vip_points then
			player.character.vip_points = player.character.vip_points + double_purchase_vip_points
		else
			player.character.vip_points = player.character.vip_points + goods_conf.vip_points + extra_vip_points
		end

		player.character.recharge_count = player.character.recharge_count + 1
	end

	local final_level
	for level = #VIPConfig, 0, -1 do
		if player.character.vip_points >= VIPConfig[level].vip_point_needed then
			final_level = VIPConfig[level].level
			break
		end
	end
	if not final_level then
		final_level = 0
	end

	local origin_vip = player.character.vip
	player.character.vip = final_level
end

function Player:UpdateAccountClient(session, request)
	local player = session.player

	-- set account & client
	local account = request.account
	local client = request.client

	--LOG(RUN, INFO).Format("[Player][UpdateAccountClient] client %s", Table2Str(client))

	if (account.goods_id ~= nil or (account.facebook_id ~= nil and account.facebook_id ~= "")) then
		player.user.avatar = 0
	else
		if (player.user.avatar == 0) then
			player.user.avatar = math.random(1, 10)
		end
	end

	if (account.facebook_id == nil) then
		account.facebook_id = ""
	end
	if (account.google_id == nil) then
		account.google_id = ""
	end

	for k, _ in pairs(account) do
		if type(account[k]) == "string" then
			account[k] = string.filter_client_string(account[k])
			account[k] = string.sub(account[k], 0, 50)
			player.account[k] = account[k]
		end
	end
	for k, _ in pairs(client) do
		if type(client[k]) == "string" then
			client[k] = string.filter_client_string(client[k])
			client[k] = string.sub(client[k], 0, 50)
			player.client[k] = client[k]
		--LOG(RUN, INFO).Format("[Player][UpdateAccountClient] k is %s, v is: %s", k, client[k])
		end
	end
	--player.account = account
	--player.client = client
end

function Player:SettleChargeInfo(session)
	local player = session.player

	-- update daily charge and month charge
	if not os.is_today(player.character.charge_time) then
		player.character.daily_charge = 0
	end

	if not os.is_current_month(player.character.charge_time) then
		player.character.month_charge = 0
	end

	-- vip login broadcast
	-- LOG(RUN, INFO).Format("[player][SettleChargeInfo] player %s login vip:%s", player.id, player.character.vip)
	-- if player.character.vip > 0 and os.time() > player.character.vipBcTime + 1800 then
	-- 		local gameID = 19
	-- 		local winInfo = json.encode({
	-- 		-- type = tostring(gameID),
	-- 		type = "VipUserLogin",
	-- 		vip = player.character.vip
	-- 		})
	-- 		local triggle = {multiple = 0, win = 0, vipLevel = player.character.vip, grade = 0, treeLevel = 0, playerLevel = 0}
	-- 		Communication:OnBcEvent(session, gameID, triggle, winInfo)
	-- end

	LOG(RUN, INFO).Format(
		"[Account][SettleChargeInfo] player %s login successfully, channel is: %s",
		player.id,
		player.client.channel
	)
	--init charge info
	local cur_shop_config = CommonCal.Calculate.get_shop_config(player)
	if player.first_charge.charge_info == "[]" then
		local charge_info_tab = {}
		for k, v in pairs(cur_shop_config) do
			if v.first_charge then
				charge_info_tab[tostring(k)] = false
			-- charge_info_tab[k] = false
			end
		end
		player.first_charge.charge_info = json.encode(charge_info_tab)
	end

	local charge_info_tab = json.decode(player.first_charge.charge_info)
	for k, v in pairs(cur_shop_config) do
		if v.first_charge and charge_info_tab[tostring(k)] == nil then
			-- charge_info_tab[k] = false
			charge_info_tab[tostring(k)] = false
		end
	end

	player.first_charge.charge_info = json.encode(charge_info_tab)
end

function Player:LoginReset(player)
	-- --第二天第一次登录时候需player身上的一些值
	if not os.same_day(player.character.last_login_time, player.character.login_time) then
		player.character.total_login_times = player.character.total_login_times + 1
	end

end
