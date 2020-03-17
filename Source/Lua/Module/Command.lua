--------------
--  Command，manager进程给dispatcher进程发送消息的处理--
--------------
require "Common/Return"
require "Config/ServerConfig"
require "Config/system/ConstValue"
require "Common/RobotManager"
require "Common/DailyMissionsCal"
require "Common/PaymentCal"
require "Common/FeverQuestCal"
require "Common/BoosterCal"
module("Command", package.seeall)

-- manager control to drop players, other player login same account
-- manager通知玩家顶号
Drop = function(_M, session, request)
	local session_id = request.session_id
	local player_id = request.player_id
	local player_session = PlayerSession:Get(session_id)

	local player_type = ConstValue[5].value
	if player_session and player_session.id == session_id and player_session.player and player_session.player.id == request.player_id and player_session.player.character.player_type ~= tonumber(player_type) then
		player_session:Stop()
	else
		session:WriteRouterPacket({
			header = {
				router = "Inform",
				service_name = "NotificationClientService",
				module_id = "Distributor",
				message_id = "Distributor_Deregister_Request",
			},
			player_id = player_id
		})

		--inform contest
		for k, v in pairs(GameRoomConfig) do
            session:WriteRouterPacket({
                header = {
                    router = "Inform",
                    service_name = v.contest_client_name,
                    module_id = v.const_game_name,
                    message_id = string.format("%s_Offline_Request", v.const_game_name),
                },
                player_id = player_id
            })
        end
	end
end

-- drop players finished, inform other server, caused by session Stop
-- 玩家掉线，tcp断开连接
FinishDrop = function(_M, session, request)
	local player_session = PlayerSession:Get(request.session_id)

	if not player_session.player then
		return
	end
	
	local player = player_session.player
	local player_id = player_session.player.id

	local task = session.task

	local binding_status = "normal"
	if (player.account.facebook_id ~= "")
	then
		binding_status = "facebook"
	elseif (player.account.google_id ~= "")
	then
		binding_status = "google"
	end

	-- log Logout
	
	Spark:Logout(player, {
        [1] = player.daily_wheel.continue_login_days,
		[2] = player.daily_wheel.acc_login_days,
		[3] = player.character.login_time,
		[4] = player.character.level,
		[5] = binding_status,
		[6] = player.character.create_time,
		[7] = player.character.recharge_count,
		[8] = player.statistics.history_games,
		[9] = player.statistics.last_game,
		[10] = player.statistics.bigwin_num,
		[11] = player.statistics.megawin_num,
		[12] = player.statistics.epicwin_num,
		[13] = player.statistics.bonus_game_num,
		[14] = player.statistics.bonus_award,
		[15] = player.record.total_spin,
	})

	-- inform notification
	session:WriteRouterPacket({
		header = {
			router = "Inform",
			service_name = "NotificationClientService",
			module_id = "Distributor",
			message_id = "Distributor_Deregister_Request",
		},
		player_id = player_id
	})
	
	--通知游戏服务器
	for k, v in pairs(GameRoomConfig) do
		if v.game_type == player.game_type then
			session:WriteRouterPacket({
				header = {
					router = "Inform",
					service_name = v.contest_client_name,
					module_id = v.const_game_name,
					message_id = string.format("%s_Offline_Request", v.const_game_name),
				},
				player_id = player_id
			})
		end
	end
end

-- manager expires player, force drop off, caused by manager
Expire = function(_M, session, request)
	local session_id = request.session_id
	local player_id = request.player_id
	local player_session = PlayerSession:Get(session_id)

	local player_type = ConstValue[5].value
	
	if player_session and player_session.id == session_id and player_session.player and player_session.player.id == request.player_id and player_session.player.character.player_type ~= tonumber(player_type)  then
		LOG(RUN, INFO).Format("[Command][Expire]  player id: %s, player_type is:%s", player_id, player_session.player.character.player_type)
		player_session:Stop()
	else
		-- inform notification
		session:WriteRouterPacket({
			header = {
				router = "Inform",
				service_name = "NotificationClientService",
				module_id = "Distributor",
				message_id = "Distributor_Deregister_Request",
			},
			player_id = player_id
		})

		LOG(RUN, INFO).Format("[Command][Expire] player %s expire", player_id)
		-- inform manager
		session:WriteRouterPacket({
			header = {
				router = "Inform",
				service_name = "ManagerClientService",
				module_id = "PlayerWatcher",
				message_id = "PlayerWatcher_Deregister_Request",
			},
			player_id = player_id
		})

		--inform contests
		local player = player_session.player
		if player then
			for k, v in pairs(GameRoomConfig) do
				if player.game_type == v.game_type then
					session:WriteRouterPacket({
						header = {
							router = "Inform",
							service_name = v.contest_client_name,
							module_id = v.const_game_name,
							message_id = string.format("%s_Offline_Request", v.const_game_name),
						},
						player_id = player_id
					})
				end
			end
		end
	end
end

local PropType = {
	Common = 1,--普通道具标记为1
	Charge = 2,--为充值加的道具,标记为2
}

---------离线邮件发送过来的---------------
GetAttachments = function(_M, session, request)
	local player_session = PlayerSession:Get(request.session_id)
	local props = request.props
	local prop_list = json.decode(props)
	local player = player_session.player
	local player_id = request.player_id

	if not player or player.id ~= player_id then
		session:WriteRouterPacket({
			header = {
				router = "LocalRequest",
				service_name = "ManagerClientService",
				module_id = "Mail",
				message_id = "Mail_AutoFetch_Request",
			},
			player_id = player_id,
			props = props,
		})
		return 
	end

	player_session:Work(function()
		for _, item in pairs(prop_list) do
			local cur_shop_config = CommonCal.Calculate.get_config(player, "ShopConfig")
			local shop_good_info = cur_shop_config[item[1]]

			if shop_good_info == nil then
				local old_chip = player.character.chip
				Player:Obtain(player, item, Reason.GET_ATTACHMENT_PROP_OBTAIN())

				player_session:WriteRouterPacket({
					header = {
						router = "SpecificNotice",
						session_id = player_session.id,
						player_id = player.id,
						module_id = "Command",
						message_id = "Command_Player_Notice",
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
							his_max_charge = player.character.his_max_charge,
						},
					},
					collect_chip = player.character.chip - old_chip
				})
				local items = {}
				for _,v in ipairs(prop_list) do
					table.insert(items, {id = v[1], amount = v[2]})
				end
				
				player_session:WriteRouterPacket({
					header = {
						router = "SpecificNotice",
						session_id = player_session.id,
						player_id = player.id,
						module_id = "Command",
						message_id = "Command_GetAttachments_Notice",
					},
					item = items,
					attachments_type = 3,
				})
			else
				old_player_id = 0
				if (item[3] ~= nil)
				then
					old_player_id = tonumber(item[3])
				end
				for i = 1, item[2] do
					local data = {
						player_id = player_id,
						goods_id = shop_good_info.id,
						old_player_id = old_player_id
					}
					player_session:ReadRouterPacket({
						header = {
							router = "Command",
							module_id = "Command",
							message_id = "Command_GetGoods_Request",
						},
						session_id = player_session.id,
						content = json.encode(data),
					})
				end
				return
			end
			
		end
	end)
end

ResetPotInfo = function(_M, session, request)


end

local function IsDoublePurchase(player, goods_id, goods_conf, prop_id_array, client_is_double_purchase)
	if player.character.double_purchase_goods_id ~= goods_id then
		return false
	end
	if not goods_conf.is_double_purchase then
		return false
	end
	if client_is_double_purchase == 0 then
		return false
	end
	return true
end

local function GetGoodsDoublePurchase(player, goods_conf, goods_id, client_is_double_purchase)
	if not goods_conf.is_double_purchase then
		return false
	end
	-- 这是复购，不能够再次复购
	if player.character.double_purchase_goods_id == goods_id then
		return client_is_double_purchase == 0
	end
	return true
end

local function UpdateDoublePurchase(player, goods_conf, goods_id, client_is_double_purchase)
	if not goods_conf.is_double_purchase then
		player.character.double_purchase_goods_id = 0
		return
	end
	-- client_is_double_purchase为1表示本次使用了复购，清掉上次数据
	if player.character.double_purchase_goods_id == goods_id and client_is_double_purchase == 1 then
		player.character.double_purchase_goods_id = 0
		return
	end
	player.character.double_purchase_goods_id = goods_id
end

local function _GetGoods(player_session, request)
	local player = player_session.player
	local content = request.content
	local data = json.decode(content)

	local prop_list = {{data.goods_id, 1}}
	local props = json.encode(prop_list)
	local player_id = data.player_id
	local old_player_id = data.old_player_id

	local payment_amount = data.payment_amount
	local payment_id = data.payment_id
	local inner_payment_id = data.inner_payment_id 
	local goods_id = data.goods_id
	local payment_type = data.payment_type
	local pot_time = data.pot_time
	local client_is_double_purchase = tonumber(data.is_double_purchase or 0)

	LOG(RUN, INFO).Format("[Command][GetGoods] player %s content is: %s", player_id, content)

	-- 追加的恢复存钱罐功能
	if not player or player.id ~= player_id then
		-- PaymentCal.Calculate.AsyncAddPayment(player_id, content)
		player_session:WriteRouterPacket({
			header = {
				router = "LocalRequest",
				service_name = "ManagerClientService",
				module_id = "Mail",
				message_id = "Mail_AutoFetch_Request",
			},
			player_id = player_id,
			props = props,
		})
		LOG(RUN, INFO).Format("[Command][GetGoods] cannot find player, send goods to mail, player_id:%s, props:%s", player_id, props)
		return
	end

	---处理状态变化
	if (player.game_type > 0) then
		
		local old_game_info = SlotsGameCal.Calculate.InitPlayerGameInfo(player_session, Task:Current(), player, player.game_type)
		local save_data = old_game_info.save_data
		if (LineNum[player.game_type] ~= nil) then
			local oldlineNum = LineNum[player.game_type]()
			local old_chip_cost = old_game_info.bet_amount * oldlineNum

			LuckyCal.ChangeMode(player_session, save_data, old_chip_cost, player.game_type, old_chip_cost, old_game_info)
		end
	end	

	local cur_shop_config = CommonCal.Calculate.get_config(player, "ShopConfig")

	player_session:Work(function()
		local goods_id = tonumber(data.goods_id)
		local payment_id = data.payment_id
		local payment_type = data.payment_type
		local old_player_id = data.old_player_id
		
		local task = Task:Current()
		local goods_conf = cur_shop_config[goods_id]

		if not goods_conf then 
			LOG(RUN, INFO).Format("[get goods] can't find goods config %s", goods_id)
			return
		end

		local old_chip = player.character.chip

        if goods_conf.first_charge then
        	local charge_info_tab = json.decode(player.first_charge.charge_info)
            if charge_info_tab[tostring(goods_id)] then
				LOG(RUN, INFO).Format("[Command][GetGoods] player %s try to charge first charge goods %s twice", player_id, goods_id)
        		return
        	else
        		charge_info_tab[tostring(goods_id)] = true
        	end
        	player.first_charge.charge_info = json.encode(charge_info_tab)
        end

		local all_items = {}
		local is_double_purchase = false
		local is_next_double_purchase = GetGoodsDoublePurchase(player, goods_conf, goods_id, client_is_double_purchase)
		local prev_vip_points = player.character.vip_points
		local prev_chip = player.character.chip

		local activity_type = ActivityDefine.AllTypes.ClimbSlide

		local count_down_info = ActivityCal.Calculate.CountDown(activity_type)
		local cur_activity = ClimbSlideCal.Calculate.GetActivityInfo(player_session, activity_type)
		if (count_down_info.distance_start_time <= 0 and count_down_info.distance_end_time > 0 ) then
			if (cur_activity.activity_list ~= nil and cur_activity.activity_list[cur_activity.sel_level] ~= nil) then
				cur_activity.spin_count = cur_activity.spin_count + goods_conf.wheel_spins
				cur_activity.activity_list[cur_activity.sel_level].spin_count = cur_activity.spin_count
			end
		end

		---处理活动商品的buff奖励
		for key, config_info in ipairs(BoosterSaleFlyAndSlide) do
			if player_session.player.is_fever_quest == 1 then
				LOG(RUN, INFO).Format("[Command][get goods]player: %s, is fever", player_session.player.id)
				break
			end
			if (config_info.shop_id == goods_id) then
				cur_activity.climb_slide_start_buf_time = os.time()
				cur_activity.climb_slide_end_buf_time = os.time() + config_info.double_collect_time

				local status, climb_slide_start_buf_time, climb_slide_end_buf_time, climb_slide_buff_time = ClimbSlideCal.Calculate.GetBooster(player_session)
				
				ClimbSlideCal.Calculate.AddExternSpins(player_session)

				local rs_activity_list = table.DeepCopy(cur_activity.activity_list)
				for k, v in ipairs(rs_activity_list) do
					v.prize = ClimbSlideCal.Calculate.GetPrize(cur_activity.activity_list[k])
				end

				player_session:WriteRouterPacket({
					header = {
						router = "SpecificNotice",
						session_id = player_session.id,
						player_id = player.id,
						module_id = "ClimbSlide",
						message_id = "ClimbSlide_Booster_Notice",
					},
					stamp_start_time = climb_slide_start_buf_time,
					stamp_end_time = climb_slide_end_buf_time,
					cutdown_time = climb_slide_buff_time,
					status = status,
					climb_slide_info = {
						collect_amount = cur_activity.collect_amount,
						total_collect_amount = cur_activity.total_collect_amount,
						spin_count = cur_activity.spin_count,
						sel_level = cur_activity.sel_level,
						activity_list = json.encode(rs_activity_list),
						final_prize = cur_activity.final_prize
					}
				})

				break
			end
		end

		ActivityCal.Calculate.UpdateActivityInfo(player_session, activity_type)

		FeverCardCal.OnPurchase(player_session, player, goods_conf.price)
		FeverQuestCal.OnPurchase(player_session, player, goods_id, goods_conf.price)
		BoosterCal.OnPurchase(player_session, player, goods_id, goods_conf)

		local vip_level = player.character.vip
		is_double_purchase = IsDoublePurchase(player, goods_id, goods_conf, goods_conf.prop_id_array, client_is_double_purchase)
		
		for k,v in ipairs(goods_conf.prop_id_array) do
			local prop_id = v
			local item = {
				id = prop_id,
				amount = 0,
			}
			
			local base_amount = goods_conf.base_prop_amount_array[k]
			base_amount = CommonCal.Calculate.CalcBaseWithLevel(base_amount, player.character.level)

			local extra_percent = goods_conf.extra_percent_array[k]
			local free_extra_percent = goods_conf.free_extra_percent_array[k]
			local vip_affect = goods_conf.vip_affect_array[k]
			local amount_with_extra = 0


			local dont_miss_it_conf = nil
			for k, v in pairs(DontMissItConfig) do
				if (v.shop_id == goods_id) then
					dont_miss_it_conf = v
					break
				end
			end

			if (player.character.charge == 0) then
				local dur_time  = math.floor((os.time() - player.character.create_time) / 3600)
				
				local miss_percent = 0
				if (dont_miss_it_conf) then
					local last_buy_time_extra_percent = dont_miss_it_conf.free_last_buy_time_extra_percent
					local sel_index = 0
					for miss_k, miss_v in pairs(last_buy_time_extra_percent) do
						if (miss_k <= dur_time) then
							if (miss_k > sel_index) then
								sel_index = miss_k
							end
						end
					end
					miss_percent = last_buy_time_extra_percent[sel_index]
				end

				LOG(RUN, INFO).Format("[Command][GetGoods] amount_with_extra11:%s, free_extra_percent:%s, miss_percent:%s", amount_with_extra, free_extra_percent, miss_percent)
				amount_with_extra = math.ceil(base_amount * (1 + free_extra_percent + miss_percent))
				LOG(RUN, INFO).Format("[Command][GetGoods] amount_with_extra22:%s, free_extra_percent:%s, miss_percent:%s", amount_with_extra, free_extra_percent, miss_percent)
			
			else
				local dur_time  = math.floor((os.time() - player.character.charge_time) / 3600)
				
				local miss_percent = 0
				if (dont_miss_it_conf) then
					local last_buy_time_extra_percent = dont_miss_it_conf.last_buy_time_extra_percent
					local sel_index = 0
					for miss_k, miss_v in pairs(last_buy_time_extra_percent) do
						if (miss_k <= dur_time) then
							if (miss_k > sel_index) then
								sel_index = miss_k
							end
						end
					end
					miss_percent = last_buy_time_extra_percent[sel_index]
				end

				LOG(RUN, INFO).Format("[Command][GetGoods] amount_with_extra11:%s, extra_percent:%s, miss_percent:%s", amount_with_extra, extra_percent, miss_percent)
				amount_with_extra = math.ceil(base_amount * (1 + extra_percent + miss_percent))
				LOG(RUN, INFO).Format("[Command][GetGoods] amount_with_extra22:%s, extra_percent:%s, miss_percent:%s", amount_with_extra, extra_percent, miss_percent)
			end

			if vip_affect and (is_double_purchase == false) then
				local multiply_config, res = CommonCal.Calculate.get_shop_config(player)

				local normal_shop_config = CommonCal.Calculate.get_config(player, "ShopConfig")
				if res then
					--base_amount = goods_conf.prop_amount_array[k]
					local vip_extra_percent = VIPConfig[vip_level].purchase_bonus

					local activity_value = multiply_config[goods_id].prop_amount_array[k]
					local normal_value = normal_shop_config[goods_id].prop_amount_array[k]

					local number = activity_value / normal_value
					amount_with_extra = amount_with_extra * number

					LOG(RUN, INFO).Format("[Command][GetGoods] amount_with_extra:%s, vip_extra_percent is:%s", amount_with_extra, vip_extra_percent)
					local vip_extra_amount = math.ceil(amount_with_extra * vip_extra_percent)
					LOG(RUN, INFO).Format("[Command][GetGoods] vip_extra_amount:%s", vip_extra_amount)
					item.amount = item.amount + amount_with_extra
					Player:Obtain(player, {prop_id, amount_with_extra, goods_id}, Reason.CHARGE_PROP_OBTAIN())
					item.amount = item.amount + vip_extra_amount
					LOG(RUN, INFO).Format("[Command][GetGoods] amount:%s", item.amount)
					Player:Obtain(player, {prop_id, vip_extra_amount}, Reason.CHARGE_VIP_EXTRA_PROP_OBTAIN())
				else
					local vip_extra_percent = VIPConfig[vip_level].purchase_bonus
					LOG(RUN, INFO).Format("[Command][GetGoods] amount_with_extra:%s, vip_extra_percent is:%s", amount_with_extra, vip_extra_percent)
					local vip_extra_amount = math.ceil(amount_with_extra * vip_extra_percent)
					LOG(RUN, INFO).Format("[Command][GetGoods] vip_extra_amount:%s", vip_extra_amount)
					item.amount = item.amount + amount_with_extra
					Player:Obtain(player, {prop_id, amount_with_extra, goods_id}, Reason.CHARGE_PROP_OBTAIN())
					item.amount = item.amount + vip_extra_amount
					LOG(RUN, INFO).Format("[Command][GetGoods] amount:%s", item.amount)
					Player:Obtain(player, {prop_id, vip_extra_amount}, Reason.CHARGE_VIP_EXTRA_PROP_OBTAIN())
				end
			elseif is_double_purchase == false then
				item.amount = item.amount + amount_with_extra
				Player:Obtain(player, {prop_id, amount_with_extra, goods_id}, Reason.CHARGE_PROP_OBTAIN())
			end

			table.insert(all_items, item)
		end
		
		LOG(RUN, INFO).Format("[Command][GetGoods] double_purchase_goods_id:%s", goods_id)

		---增加玩家lucky值
		LuckyCal.OnPurchase(player_session, goods_id)

		local player_extern = CommonCal.Calculate.get_player_extern(player_session, task, player)
		local player_json_data = player_extern.save_data
		player_json_data.LastEnterGameCredits = 0
		player_json_data.ContinuousSpinWithoutBankrupt = 0
		player_json_data.ContinuousSpinNoPay = 0
		for k, v in ipairs(InboxSaleConfig) do
			if v.shop_id == goods_id then
				local price = math.floor(goods_conf.price * 100 + 0.5)
				player_json_data.inbox_sale_charge = price
				break
			end
		end

		CommonCal.Calculate.update_player_extern(player_session, task, player)

		-- update vip level
		if is_double_purchase then
			local chip = player.character.double_purchase_chip*2
			Player:Obtain(player, {"Chip", chip, goods_id}, Reason.DOUBLE_PURCHASE_EXTRA_PROP_OBTAIN())

			Player:UpdateVIP(player_session, goods_id, player.character.double_purchase_vip_points * 2)
			all_items = {}
			table.insert(all_items, {id=1000, amount=player.character.double_purchase_chip*2})
		else
			Player:UpdateVIP(player_session, goods_id)
		end

		if is_next_double_purchase then
			player.character.double_purchase_chip = player.character.chip - prev_chip
			player.character.double_purchase_vip_points = player.character.vip_points - prev_vip_points
		end

		-- LOG(RUN, INFO).Format("[Command][GetGoods] get goods, player_id:%s, brif_player:%s", data.player_id, Table2Str(brif_player))
		local piggy_bak_info = nil--PiggyBankConfig[goods_id]
		for k, v in ipairs(PiggyBankConfig) do
			if v.shop_id == goods_id then
				piggy_bak_info = v
				break
			end
		end 
		if (piggy_bak_info ~= nil) then
			player.character.piggy_bank_pay_count = player.character.piggy_bank_pay_count + 1
			Player:Obtain(player, {"Chip", player.character.piggy_bank_chip}, Reason.PIGGY_BANK_CHIP_OBTAIN())
			local item = {
				id = 1000,
				amount = player.character.piggy_bank_chip,
			}
			table.insert(all_items, item)
			-- for key, piggy_bank_info in ipairs(PiggyBankConfig) do
			for index = #PiggyBankConfig, 1, -1 do
				local config_info = PiggyBankConfig[index]
				if (config_info.maxbuytime <= (player.character.piggy_bank_pay_count + 1)) then
					player.character.piggy_bank_chip = CommonCal.Calculate.CalcBaseWithLevel(config_info.minamout, player.character.level)
					break
				end
			end
			LOG(RUN, INFO).Format("[Command][GetGoods] get goods, player_id:%s, piggy_bank_chip:%s", data.player_id, player.character.piggy_bank_chip)
		end

		
		local brif_player = {
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
				his_max_charge = player.character.his_max_charge,
				piggy_bank_chip = player.character.piggy_bank_chip,
				piggy_bank_pay_count = player.character.piggy_bank_pay_count,
			},
		}

		player_session:WriteRouterPacket({
			header = {
				router = "SpecificNotice",
				session_id = player_session.id,
				player_id = player.id,
				module_id = "Command",
				message_id = "Command_Player_Notice",
			},
			player = brif_player,
			collect_chip = player.character.chip - old_chip
		})

		local double_purchase = nil

		if is_next_double_purchase then
			double_purchase = {
				vip_points = (player.character.vip_points - prev_vip_points)*2,
				chip = (player.character.chip - prev_chip)*2,
				goods_id = goods_id
			}
		end

		player_session:WriteRouterPacket({
			header = {
				router = "SpecificNotice",
				session_id = player_session.id,
				player_id = player.id,
				module_id = "Command",
				message_id = "Command_GetGoods_Notice",
			},
			item = all_items,
			goods_id = goods_id,
			payment_id = payment_id,
			payment_type = payment_type,
			double_purchase = double_purchase,
			vip_points = player.character.vip_points - prev_vip_points,
		})

		-- set last goods id
		UpdateDoublePurchase(player, goods_conf, goods_id, client_is_double_purchase)


	end)
end

function TestGoods(player_session, request)
	_GetGoods(player_session, request)
end

---------购买商品，玩家在线---------------
GetGoods = function(_M, session, request)
	local player_session = PlayerSession:Get(request.session_id)
	_GetGoods(player_session, request)
end

AsyncPayBack = function(_M, session, request)
	local player_session = PlayerSession:Get(request.session_id)
	local props = request.props
	local prop_list = json.decode(props)
	local player = player_session.player
	local player_id = request.player_id

	if not player or player.id ~= player_id then
		session:WriteRouterPacket({
			header = {
				router = "LocalRequest",
				service_name = "ManagerClientService",
				module_id = "Mail",
				message_id = "Mail_NoticeFetch_Request",
			},
			player_id = player_id,
			props = props,
			type = "AsyncPayBack"
		})
		return 
	end

	local old_chip = player.character.chip

	player_session:Work(function()
		for _, item in pairs(prop_list) do
			local prop_config = PropConfig.PropMap[item[1]]
			if prop_config then
				if prop_config.type == "charge" then
					player_session:ReadRouterPacket({
						header = {
							router = "Command",
							module_id = "Command",
							message_id = "Command_GetGoods_Request",
						},
						session_id = player_session.id,
						player_id = player_id,
						goods_id = prop_config.id
					})
					return
				elseif prop_config.type == "void" then -- 虚空道具/自动补单
					Player:Obtain(player, item, Reason.GET_VOID_PROP_OBTAIN())
				elseif item[2] < 0 then -- 系统减单
					if Player:Has(player, {item[1], (-1) * item[2]}) then
						Player:Consume(player, item, Reason.GET_SYSTEM_DROP_PROP_OBTAIN())
					else
						Player:Set(player, {item[1], 0}, Reason.GET_SYSTEM_DROP_PROP_OBTAIN(), Reason.GET_SYSTEM_DROP_PROP_CONSUME())
					end
				else -- 常规领取（骰子/非骰子）
					Player:Obtain(player, item, Reason.ASYNC_PAY_BACK_PROP_OBTAIN())
				end
			end
		end
		player_session:WriteRouterPacket({
			header = {
				router = "SpecificNotice",
				session_id = player_session.id,
				player_id = player.id,
				module_id = "Command",
				message_id = "Command_Player_Notice",
			},
			player = player,
			collect_chip = player.character.chip - old_chip
		})
	end)
end

OptLog = function(_M, session, request)
	local player_session = PlayerSession:Get(request.session_id)
	local player = player_session.player
	local category = request.category
	local data = request.data

	if not player or player.id ~= request.player_id then
		LOG(RUN, INFO).Format("[Command][OptLog] cannot find player, opt log fail, player_id:%s", request.player_id)
		local data_list = json.decode(data)
		if (category == "FinishPayment") then
			local goods_id = tonumber(data_list[5])

			local channel_type = data_list[7]
			local cur_shop_config = CommonCal.Calculate.get_shop_config(player)

			local goods_conf = cur_shop_config[goods_id]
			table.insert(data_list, goods_conf.desc)
			table.insert(data_list, "")
		end

		Spark[category](Operative, player, data_list)
	else
		local data_list = json.decode(data)
		if (category == "FinishPayment") then
			local goods_id = tonumber(data_list[5])
			local channel_type = data_list[7]
			local cur_shop_config = CommonCal.Calculate.get_shop_config(player)

			local goods_conf = cur_shop_config[goods_id]

			local game_name = ""
			if (player.game_type > 0) then
				LOG(RUN, INFO).Format("[Command][OptLog] cannot find player, opt log fail, player_id:%s, player.game_type is:%s", request.player_id, player.game_type)
				local game_room_config = GameRoomConfig[player.game_type]
				game_name = game_room_config.game_name
			end

			table.insert(data_list, goods_conf.desc)
			table.insert(data_list, game_name)
		end

		Spark[category](Operative, player, data_list)
	end
end

--props以dict格式存
GetSendChips = function ( _M, session, request )
	local player_session = PlayerSession:Get(request.session_id)
	local player = player_session.player
	

	local player_id = request.player_id
	local chip_count = request.chip_count
	local props = json.encode({[1] = {1000, chip_count}})
 	
	--if player is not online then send chips to mail
	if not player or player.id ~= player_id then
		session:ReadRouterPacket({
			header = {
				router = "LocalRequest",
				service_name = "ManagerClientService",
				module_id = "Mail",
				message_id = "Mail_SendChips_Request",
			},
			player_id = player_id,
			props = props,
			sender = request.sender,
		})
	end

	player_session:Work(function (  )
		if chip_count > 0 then
			local old_chip = player.character.chip
			Player:Obtain(player, {"Chip", chip_count}, Reason.GIFT_PRESENT_CHIP_OBTAIN())

			local task = Task:Current()
			LOG(RUN, INFO).Format("[Command][GetSendChips] task id %s", task.id)
			Player:BroadCastChip(player_session, task, 0, 0, 1)
			Player:RobotBroadCastChip(player_session, task, 0, 1)
			player_session:WriteRouterPacket({
				header = {
					router = "SpecificNotice",
					session_id = player_session.id,
					player_id = player.id,
					module_id = "Command",
					message_id = "Command_Player_Notice",
				},
				player = player,
				collect_chip = player.character.chip - old_chip
			})

			player_session:WriteRouterPacket({
				header = {
					router = "SpecificNotice",
					session_id = player_session.id,
					player_id = player.id,
					module_id = "Command",
					message_id = "Command_GetSendChips_Notice",
				},
				chip_count = chip_count,			
			})
		end
	end)
end

ClubKickOut = function ( _M, session, request )

end

ClubApprove = function ( _M, session, request )
	
end

ClubReject = function ( _M, session, request )

end

ClubPromote = function ( _M, session, request )
	
end

ClubDemote = function ( _M, session, request )
	
end



Hotfix = function(_M, session, request)
	
end

Replaced = function ( _M, session, request )
	local player_session = PlayerSession:Get(request.session_id)
	local player = player_session.player
	local player_id = request.player_id

	--if player is offline, then ignore
	if player and player_id == player.id then
		player_session:Work(function (  )
			player_session:WriteRouterPacket({
				header = {
					router = "SpecificNotice",
					session_id = player_session.id,
					player_id = player.id,
					module_id = "Command",
					message_id = "Command_Replaced_Notice",
				},
				type = request.type,
			})
		end)
	end	
end

InviteFrd = function ( _M, session, request )
	local player_session = PlayerSession:Get(request.session_id)
	local player = player_session.player
	local player_id = request.player_id

	--if player is offline, then ignore
	if player and player_id == player.id then
		player_session:Work(function (  )
			player_session:WriteRouterPacket({
				header = {
					router = "SpecificNotice",
					session_id = player_session.id,
					player_id = player.id,
					module_id = "Command",
					message_id = "Command_InviteFrd_Notice",
				},
				player_id = request.player_id,
				friend = request.friend,
				frd_table_id = request.frd_table_id,
			})
		end)
	end	
end

FrdList = function ( _M, session, request )

end

Gm = function(_M, session, request)
	local response = {header = {router = "Response"}}
	local player_id = tonumber(request.player_id)
	LOG(RUN, INFO).Format("[Command][Gm] player id:%s, Request is: %s", player_id, Table2Str(request))
	local content = json.decode(request.content)
	local player_session = PlayerSession:Get(request.session_id)
	local player = player_session.player

	local req_info = content.Content

	LOG(RUN, INFO).Format("[Command][Gm] begin player id:%s, chip is: %s, experience is:%s, vip_points is:%s, player_type is:%s", player_id, player.character.chip, player.character.experience, player.character.vip_points, player.character.player_type)
	if (req_info.Chip ~= nil) then
		player.character.chip = tonumber(req_info.Chip)
	end

	if (req_info.Experience ~= nil) then
		player.character.experience = tonumber(req_info.Experience)
	end

	if (req_info.VipPoints ~= nil) then
		player.character.vip_points = tonumber(req_info.VipPoints)
	end
	if (req_info.PlayerType ~= nil) then
		player.character.player_type = tonumber(req_info.PlayerType)
	end
	LOG(RUN, INFO).Format("[Command][Gm] end player id:%s, chip is: %s, experience is:%s, vip_points is:%s, player_type is:%s", player_id, player.character.chip, player.character.experience, player.character.vip_points, player.character.player_type)
end

BindPlayerInfo = function ( _M, session, request )
	local response = {header = {router = "Response"}}
	response.player = {
		account = {},
		user = {},
	}
	local player_session = PlayerSession:Get(request.session_id)
	local player = player_session.player
	local player_id = tonumber(request.player_id)
	local platform_head_id = request.platform_head_id
	local nickname = request.nickname
	local action = request.action
	local old_chip = player.character.chip
	LOG(RUN, INFO).Format("[Command][BindPlayerInfo] player id:%s, Request is: %s", player_id, Table2Str(request))
	if (action == "facebookbind" or action == "facebookreplace")
	then
		player.account.facebook_id = platform_head_id
		player.user.nickname = nickname
		player.user.avatar = 0
	
		Player:BroadCastBaseInfo(player_session, player_session.task)

		if player and player_id == player.id then
			player_session:Work(function()		
				player_session:WriteRouterPacket({
					header = {
						router = "SpecificNotice",
						session_id = player_session.id,
						player_id = player.id,
						module_id = "Command",
						message_id = "Command_Player_Notice",
					},
					player = {
						account = {
							facebook_id = player.account.facebook_id,
						},
						user = {
							nickname = player.user.nickname,
							avatar = player.user.avatar,
						},
					},
					collect_chip = player.character.chip - old_chip
				})
			end)
		end
	elseif (action == "facebookunbind")
	then
		player.account.facebook_id = ""
		--player.user.nickname = nickname
		player.user.avatar = math.random(1, 10)
		if player and player_id == player.id then
			player_session:Work(function (  )		
				player_session:WriteRouterPacket({
					header = {
						router = "SpecificNotice",
						session_id = player_session.id,
						player_id = player.id,
						module_id = "Command",
						message_id = "Command_Player_Notice",
					},
					player = {
						account = {
							facebook_id = player.account.facebook_id,
						},
						user = {
							nickname = player.user.nickname,
							avatar = player.user.avatar,
						},
					},
					collect_chip = player.character.chip - old_chip
				})
			end)
		end

		Player:BroadCastBaseInfo(player_session, player_session.task)
	elseif (action == "googlebind" or action == "googlereplace")
	then
		player.account.google_id = platform_head_id
		player.user.nickname = nickname
		player.user.avatar = 0
	
		if player and player_id == player.id then
			player_session:Work(function (  )		
				player_session:WriteRouterPacket({
					header = {
						router = "SpecificNotice",
						session_id = player_session.id,
						player_id = player.id,
						module_id = "Command",
						message_id = "Command_Player_Notice",
					},
					player = {
						account = {
							google_id = player.account.google_id,
						},
						user = {
							nickname = player.user.nickname,
							avatar = player.user.avatar,
						},
					},
					collect_chip = player.character.chip - old_chip
				})
			end)
		end
		Player:BroadCastBaseInfo(player_session, player_session.task)
	elseif (action == "googleunbind")
	then
		player.account.google_id = ""
		--player.user.nickname = nickname
		player.user.avatar = math.random(1, 10)
		if player and player_id == player.id then
			player_session:Work(function (  )		
				player_session:WriteRouterPacket({
					header = {
						router = "SpecificNotice",
						session_id = player_session.id,
						player_id = player.id,
						module_id = "Command",
						message_id = "Command_Player_Notice",
					},
					player = {
						account = {
							google_id = player.account.google_id,
						},
						user = {
							nickname = player.user.nickname,
							avatar = player.user.avatar,
						},
					},
					collect_chip = player.character.chip - old_chip
				})
			end)
		end
		Player:BroadCastBaseInfo(player_session, player_session.task)
	end
end

DailyMissions = function(_M, session, request) 
	local player_session = PlayerSession:Get(request.session_id)
	local player        = player_session.player
	local player_id     = request.player_id
	if (player == nil) then
		return 
	end
	
	--local task = player_session.task

	local content = json.decode(request.content)

	LOG(RUN, INFO).Format("[Command][DailyMissions] player id:%s, Request is: %s", player.id, Table2Str(request))

	local json_value = json.decode(player.task_info.daily_missions)
	DailyMissionsCal.Calculate.Refresh(player, json_value, content)
	player.task_info.daily_missions = json.encode(json_value)

end

BindFacebook = function ( _M, session, request )
	local player_session = PlayerSession:Get(request.session_id)
	local player = player_session.player
	local player_id = request.player_id

	if not player or player.id ~= player_id then
		local props = json.encode({[1] = {1000, tonumber(ConstValue[22].value)}}) ----------绑定奖励---------------
		session:WriteRouterPacket({
			header = {
				router = "LocalRequest",
				service_name = "ManagerClientService",
				module_id = "Mail",
				message_id = "Mail_BindFacebook_Request",
			},
			player_id = player_id,
			props = props,
		})
		return
	end

	if player and player_id == player.id then
		player_session:Work(function ()
			local old_chip = player.character.chip
			Player:Obtain(player, {"Chip", tonumber(ConstValue[22].value)}, Reason.BIND_FACEBOOK_OBTAIN())
			player_session:WriteRouterPacket({
				header = {
					router = "SpecificNotice",
					session_id = player_session.id,
					player_id = player.id,
					module_id = "Command",
					message_id = "Command_Player_Notice",
				},
				player = {
					character = {
						chip = player.character.chip,
					}
				},
				collect_chip = player.character.chip - old_chip
			})
		end)
	end	
end

--clear trigger times in fruit slice when bonus game ended
ClearTriggerTimes = function(_M, session, request)
    local player_session = PlayerSession:Get(request.session_id)
	local player = player_session.player
	local player_id = request.player_id
    if player and player.id == player_id then
        player_session:Work(function (  )
            player.fruit_slice.trigger_times = 0
            --一局小游戏结束后,触发额度清空
            player.fruit_slice.trigger_amounts = "[]"
        end)
    end
end