require "Base/TableDefine"
require "Base/CacheDefine"
require "Common/CommonCal"
module("Ad", package.seeall)

local reset_left_times = function(json_value, ad_config)
	-----激励视频广告请求的最大次数
	json_value["ad_poor"] = AdExternConfig[1].ad_limit
	
	----插屏广告请求
	json_value["ad_block"] = AdExternConfig[3].ad_limit
	
	local ad_key = "adinfo"..ad_config.id

	json_value[ad_key] = ad_config.max_count
end

local init_click_time = function(json_value, ad_config_info)
	local json_key = "ad"..ad_config_info.extern_type
	if (json_value[json_key] == nil) then
		json_value[json_key] = {}
		json_value[json_key].click_time = 0
	end

	local json_id = "ad"..ad_config_info.id
	if (json_value[json_id] == nil) then
		json_value[json_id] = {}
		json_value[json_id].click_time = 0
	end
end

local get_left_times = function(session, task, player, json_value, single_ad_config)
	
	-----激励视频广告请求的最大次数
	if (json_value["ad_poor"] == nil) then
		reset_left_times(json_value, single_ad_config)
	end

	local left_times = 0
	local ad_key = "adinfo"..single_ad_config.id

	if (json_value[ad_key] == nil) then
		json_value[ad_key] = single_ad_config.max_count
	end

	if (single_ad_config.extern_type == 1) then
		if (json_value["ad_poor"] > json_value[ad_key]) then
			left_times = json_value[ad_key]
		else
			left_times = json_value["ad_poor"]
		end
	elseif (single_ad_config.extern_type == 3) then
		if (json_value["ad_block"] > json_value[ad_key]) then
			left_times = json_value[ad_key]
		else
			left_times = json_value["ad_block"]
		end
	end
	return left_times
end

local update_left_times = function(session, task, player, json_value, single_ad_config)
	if (single_ad_config.extern_type == 1) then
		json_value["ad_poor"] = json_value["ad_poor"] - 1
	elseif (single_ad_config.extern_type == 3) then
		json_value["ad_block"] = json_value["ad_block"] - 1
	end

	local ad_key = "adinfo"..single_ad_config.id
	json_value[ad_key] = json_value[ad_key] - 1
end

local reset_ad_info = function(json_value)
	local currentTime = os.time()

	if json_value["ad_old_time"] == nil then
		json_value["ad_old_time"] = 0
	end
	local update_his_time = false

	for k, v in pairs(AdConfig) do
		local ad_config_info = v
		
		local extern_type = ad_config_info.extern_type
		local ad_extern_config = AdExternConfig[extern_type]

		init_click_time(json_value, ad_config_info)

		if (not os.same_day(currentTime, json_value["ad_old_time"]))
		then
			update_his_time = true
			reset_left_times(json_value, ad_config_info)

			local json_key = "ad"..ad_config_info.extern_type
			local json_id = "ad"..ad_config_info.id

			json_value[json_key].click_time = 0
			json_value[json_id].click_time = 0
		end
	end

	if (update_his_time) then
		json_value["ad_old_time"] = currentTime
	end
end

local get_cooldown = function(ad_config_info, ad_extern_config)
	local ad_cooldown = 0
	if (ad_config_info.ad_cooldown < 0) then	
		ad_cooldown = ad_extern_config.ad_cooldown
	else
		ad_cooldown = ad_config_info.ad_cooldown
	end
	return ad_cooldown
end

local get_cur_adinfo = function(player, json_value, ad_config_info, ad_extern_config)
	init_click_time(json_value, ad_config_info)

	local currentTime = os.time()
	local json_key = "ad"..ad_config_info.extern_type
	local json_id = "ad"..ad_config_info.id

	local left_times = get_left_times(session, task, player, json_value, ad_config_info)

	local ad_cooldown = get_cooldown(ad_config_info, ad_extern_config)
	local left_cd_time1 = ad_cooldown - (currentTime - json_value[json_id].click_time)
	if left_cd_time1 < 0 then
		left_cd_time1 = 0
	end

	local left_cd_time2 = ad_cooldown - (currentTime - json_value[json_key].click_time)
	if left_cd_time2 < 0 then
		left_cd_time2 = 0
	end

	local left_cd_time = 0
	if left_cd_time1 < left_cd_time2 then
		left_cd_time = left_cd_time2
	else 
		left_cd_time = left_cd_time1
	end
	local ad_info ={
			player_id = player.id,
			ad_type = ad_config_info.id,
			left_times = left_times,
			left_cd_time = left_cd_time,
	}
	return ad_info
end

AddFreeSpin = function( _M, session, request )
	local response = {header = {router = "Response"}}

	local task = session.task
	local player = session.player

	if (player.game_type == GameType.AllTypes.MagicScarab) then
		response.ret = Return.OK()

		return response
	end


	local player_game_info = SlotsGameCal.Calculate.InitPlayerGameInfo(session, task, player, player.game_type)

	local player_game_status = CommonCal.Calculate.GetPlayerGameStatus(session, task, player, player.game_type)
	if (player_game_status.history_data ~= nil) then
		local cur_status = GameStatusCal.Calculate.GetGameStatus(player_game_status)
		if (cur_status == GameStatusDefine.AllTypes.FreeSpinGame) then
			GameStatusCal.Calculate.AddGameStatus(player_game_status, GameStatusDefine.AllTypes.FreeSpinGame, 1, 1, SlotsGameCal.Calculate.GetBetAmount(player_game_info))
			GameStatusCal.Calculate.FlushGameStatus(player_game_status)
			CommonCal.Calculate.UpdatePlayerGameStatus(session, task, player, player.game_type, player_game_status)
		end
	end
	player_game_info.total_spin_bouts = player_game_info.total_spin_bouts + 1
	player_game_info.free_spin_bouts = player_game_info.free_spin_bouts + 1

    if (CommonCal.Calculate.is_old_game(player.game_type)) then
        local player_slots_info = CommonCal.Calculate.get_slots_info(session, task, player, player.game_type)
        CommonCal.Calculate.UpdateSlotsToDbCache(task, player, player_slots_info, player_game_info)
    else
        CommonCal.Calculate.UpdateGameInfoToDbCache(task, player, player_game_info)
	end

	local player_extern = CommonCal.Calculate.get_player_extern(session, task, player)
	local player_json_data = player_extern.save_data
	player_json_data.is_free_spin_add = 1
	CommonCal.Calculate.update_player_extern(session, task, player)
	
	response.ret = Return.OK()

    return response
end

Click = function ( _M, session, request )
	local response = {header = {router = "Response"}}

	local task = session.task
	local player = session.player


	if (player == nil) then
		response.ret = Return.PLAYER_NOT_FOUND()
		return response
	end

	local player_extern = CommonCal.Calculate.get_player_extern(session, task, player)
	local json_value = player_extern.save_data
	reset_ad_info(json_value)

	Ad.GetInfo(session, task, player, json_value)

	local ad_type = request.ad_type

	local currentTime = os.time()

	local ad_config_info = AdConfig[ad_type]

	local extern_type = ad_config_info.extern_type
	local ad_extern_config = AdExternConfig[extern_type]

	local ad_cooldown = get_cooldown(ad_config_info, ad_extern_config)

	
	local json_key = "ad"..ad_config_info.extern_type
	local json_id = "ad"..ad_config_info.id

	local dur_time1 = currentTime - json_value[json_id].click_time
	local dur_time2 = currentTime - json_value[json_key].click_time
	LOG(RUN, INFO).Format("[Ad][Click] player id:%s, ad id:%s, dur_time1:%s, dur_time2:%s, ad_cooldown:%s", player.id, ad_config_info.id, dur_time1, dur_time2, ad_cooldown)
	if (dur_time1 < ad_cooldown)
	then
		if dur_time2 < ad_extern_config.ad_cooldown then
			response.ret = Return.START_TOO_FREQUENT()
			return response
		end
	end

	local ad_info = get_cur_adinfo(player, json_value, ad_config_info, ad_extern_config)

	local left_times = get_left_times(session, task, player, json_value, ad_config_info)
	if (left_times <= 0)
	then
		response.ret = Return.START_TOO_FREQUENT()
        return response
	end

	json_value[json_key].click_time = currentTime
	json_value[json_id].click_time = currentTime

	--------------------奖励---------------------

	local obtain_chip = 0

	if (ad_config_info.adtype == "Levelup")
	then
		obtain_chip = player.character.level_up_chip
	else
		local t = type(ad_config_info.ad_award)
		if (t == "table") then
			local level = player.character.level
			local sel_lv = 0
			for lv, award_value in pairs(ad_config_info.ad_award) do
				if (lv <= level) then
					if (sel_lv < lv) then
						sel_lv = lv
					end
				end
			end
			obtain_chip = ad_config_info.ad_award[sel_lv]
		else
			obtain_chip = ad_config_info.ad_award
		end
	end

	local vip_level = player.character.vip
	if (vip_level > 0) then
		obtain_chip = obtain_chip * ad_config_info.vip[vip_level]
	end

	Player:Obtain(player, {"Chip", obtain_chip}, Reason.AD_CHIP_OBTAIN())

	response.chip_get = obtain_chip
	response.ret = Return.OK()
	response.player = {
		character = {
			chip = player.character.chip,
		}
	}
	response.content = json.encode(session.player_ad)
	response.ad_type = ad_type

	update_left_times(session, task, player, json_value, ad_config_info)

	local items = {}
	if (obtain_chip > 0 and ad_config_info.is_notice == 1) then
		

		table.insert(items, {id = 1000, amount = obtain_chip})
		
		session:WriteRouterPacket({
			header = {
				router = "SpecificNotice",
				session_id = session.id,
				player_id = player.id,
				module_id = "Command",
				message_id = "Command_GetAttachments_Notice",
			},
			item = items,
			attachments_type = 2,
		})
	end
	response.item = json.encode(items)

	CommonCal.Calculate.update_player_extern(session, task, player)


	Spark:AdInfo(player, {
		[1] = ad_config_info.id,
		[2] = ad_config_info.adtype,
		[3] = ad_config_info.name_remarks,
		[4] = json.encode(ad_config_info),
	})

	return response
end

GetInfo = function(session, task, player, json_value)
	local async_response = CommonCal.Calculate.LoadFromDbCache(task, player, "player_ad", player.id)

	-- local table_define = TableDefine["player_ad"]

	local player_ad = {}
	for k, v in ipairs(AdConfig) do
		local ad_config_info = v
		local extern_type = ad_config_info.extern_type
		local ad_extern_config = AdExternConfig[ad_config_info.extern_type]

		local ad_info = get_cur_adinfo(player, json_value, ad_config_info, ad_extern_config)

		player_ad[tonumber(ad_info.ad_type)] = ad_info
	end

	return player_ad
end

Info = function(_M, session, request)
	local task = session.task
	local player = session.player

	local response = {header = {router = "Response"}}

	if (player == nil) then
		response.ret = Return.PLAYER_NOT_FOUND()
		return response
	end

	local player_extern = CommonCal.Calculate.get_player_extern(session, task, player)

	local json_value = player_extern.save_data

	reset_ad_info(json_value)

	response.content = json.encode(Ad.GetInfo(session, task, player, json_value))

	response.ret = Return.OK()

    return response
end