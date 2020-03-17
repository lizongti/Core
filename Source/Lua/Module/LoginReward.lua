-----------------------
--   Login Reward   --
-----------------------
require "Base/Path"
require "Util/TableExt"
require "Util/MathExt"
require "Util/OsExt"
require "Common/Return"

module("LoginReward", package.seeall)

require "Config/ServerConfig"

Login = function(_M, session, request)
	local response = {header = {router = "Response"}}

	local player = session.player
	local now_date = os.now_date()

	if not player.login_reward.month or player.login_reward.month ~= now_date.month then
		player.login_reward.month = now_date.month
		player.login_reward.month_login_days = 1
		player.login_reward.month_login_level = 0
	elseif not os.same_day(player.character.login_time, player.character.last_login_time) then
		player.login_reward.month_login_days = player.login_reward.month_login_days + 1
	end
	
	if os.is_yesterday(player.character.last_login_time) then
		player.login_reward.continuous_login_days = player.login_reward.continuous_login_days + 1
	elseif not os.is_today(player.character.last_login_time) then
		player.login_reward.continuous_login_days = 1
	end
    
	player.login_reward.continuous_login_days = player.login_reward.continuous_login_days < 7 and player.login_reward.continuous_login_days or 7
    --player.login_reward.acc_login_days = player.login_reward.acc_login_days + 1

	response.ret = Return.OK()
	LOG(RUN, INFO).Format("[LoginReward][Login] player %s refresh login reward, continuous_login_days %s, month_login_days %s", 
		player.id, player.login_reward.continuous_login_days,player.login_reward.month_login_days)
	return response
end

Display = function(_M, session, request)
	local response = {header = {router = "Response"}}
	if not session or not session.player then
		response.ret = Return.PLAYER_NOT_FOUND()
		return response
	end

	local player = session.player

	local continuous_login_days = player.login_reward.continuous_login_days < 7 and player.login_reward.continuous_login_days or 7

	response.obtain_time = player.login_reward.obtain_time
	response.month = player.login_reward.month
	response.month_login_days = player.login_reward.month_login_days
	response.month_login_level = player.login_reward.month_login_level
	response.continuous_login_days = continuous_login_days
	response.month_rule = table.copy(LoginRewardConfig.MonthRule)
	response.continuous_rule = table.copy(LoginRewardConfig.ContinuousRule)

	for _, v in pairs(response.month_rule) do
		v.gold = v.gold * VIPConfig.VIP[player.character.vip].login_reward_rate
	end

	for _, v in pairs(response.continuous_rule) do
		v.gold = v.gold * VIPConfig.VIP[player.character.vip].login_reward_rate
	end

	if os.is_today(player.login_reward.obtain_time) then
		response.can_obtain = false
	else 
		response.can_obtain = true
	end

	response.ret = Return.OK()

	return response
end

Obtain = function(_M, session, request)
	local response = {header = {router = "Response"}}
	if not session or not session.player then
		response.ret = Return.PLAYER_NOT_FOUND()
		return response
	end 
	local player = session.player

	if os.is_today(player.login_reward.obtain_time) then
	   response.ret = Return.LOGIN_REWARD_ALREADY_OBTAINED()
	   return response
	end

	local continuous_login_days = player.login_reward.continuous_login_days < 7 and player.login_reward.continuous_login_days or 7
	local month_login_days = player.login_reward.month_login_days
	local month_login_level = player.login_reward.month_login_level

	local continous_obtain_gold = 0
	for k,v in ipairs(LoginRewardConfig.ContinuousRule) do
		if v.days == continuous_login_days then
			continous_obtain_gold = continous_obtain_gold + v.gold
		end
	end

	local month_obtain_gold = 0
	for k,v in ipairs(LoginRewardConfig.MonthRule) do
		if v.days <= month_login_days and k > month_login_level then
			month_obtain_gold = month_obtain_gold + v.gold
			month_login_level = k
		end
	end

	local obtain_gold = continous_obtain_gold + month_obtain_gold
	obtain_gold = obtain_gold * VIPConfig.VIP[player.character.vip].login_reward_rate
	
	player.login_reward.obtain_time = os.time()
	player.login_reward.month_login_level = month_login_level
	Player:Obtain(player, {"Gold", obtain_gold}, Reason.LOGIN_REWARD_PROP_OBTAIN())

	
	Spark:LoginReward(player, {
        [1] = player.login_reward.continuous_login_days,
        [2] = player.login_reward.month_login_days,
		[3] = continous_obtain_gold,
		[4] = month_obtain_gold,
		[5] = VIPConfig.VIP[player.character.vip].login_reward_rate,
		[6] = VIPConfig.VIP[player.character.vip].login_reward_rate,
		[7] = continous_obtain_gold * VIPConfig.VIP[player.character.vip].login_reward_rate,
		[8] = month_obtain_gold * VIPConfig.VIP[player.character.vip].login_reward_rate
    })

	response.player = {
		character = {
			gold = player.character.gold
		}
	}
	response.obtain_time = player.login_reward.obtain_time
	response.month = player.login_reward.month
	response.month_login_days = player.login_reward.month_login_days
	response.month_login_level = player.login_reward.month_login_level
	response.continuous_login_days = player.login_reward.continuous_login_days

	response.ret = Return.OK()
	response.obtain_gold = obtain_gold

	return response
end 