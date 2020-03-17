module("DailyWheel", package.seeall)
require "Config/ServerConfig"

Login = function(_M, session)
    local player = session.player
    local vip_point_award = 0

    local daily_wheel_json = json.decode(player.daily_wheel.json_str)

    local old_wheel_name = "None"
    local cur_wheel_name = ""
    local index, chip_get, vip_extra_chip, con_login_reward, con_login_diamonds, vip_extra_bonus
    if not os.same_day(player.character.last_wheel_time, player.character.login_time) then
        -- 累计登陆天数+1,做日志用,业务上这个字段不影响daily_wheel的奖励
        -- 只是字段放daily_wheel下,后续功能可能需要用到
        player.daily_wheel.acc_login_days = player.daily_wheel.acc_login_days + 1
        -- 转盘的逻辑
        local daily_wheel_conf_name = ""
        local max_index = #DailyWheelLevelConfig
        if (player.character.level < DailyWheelLevelConfig[max_index].level) then
            for k, v in ipairs(DailyWheelLevelConfig) do
                if (v.level <= player.character.level and player.character.level < DailyWheelLevelConfig[k + 1].level) then
                    daily_wheel_conf_name = v.table_name
                    break
                end
            end
        else
            daily_wheel_conf_name = DailyWheelLevelConfig[max_index].table_name
        end

        if (daily_wheel_json.old_daily_wheel_conf_name == nil) then
            daily_wheel_json.old_daily_wheel_conf_name = "None"
        end

        if (daily_wheel_json.max_con_login_days == nil) then
            daily_wheel_json.max_con_login_days = 0
        end

        -- old_wheel_name = daily_wheel_json.old_daily_wheel_conf_name
        old_wheel_name = daily_wheel_conf_name
        cur_wheel_name = daily_wheel_conf_name

        daily_wheel_json.old_daily_wheel_conf_name = daily_wheel_conf_name
        
        local weight_tab = {}
        for k, v in ipairs(_G[daily_wheel_conf_name]) do
            table.insert(weight_tab, v.weight)
        end
        index = math.rand_weight(player, weight_tab)

        chip_get = _G[daily_wheel_conf_name][index].bonus

        local lucky_info = _G[daily_wheel_conf_name][index].lucky
        
        if (lucky_info ~= nil) then
            local weights = {}
            for i = 1, #lucky_info do
                table.insert(weights, lucky_info[i].weight)
            end

            local index = math.rand_weight(player, weights)
            local add_lucky = lucky_info[index].value
            LOG(RUN, INFO).Format("[DailyWheel][Login] player id:%s, add_lucky:%s", player.id, add_lucky)
            LuckyCal.GainLucky(player, add_lucky)
        end

        local vip_level = player.character.vip
        Player:Obtain(player, {"Chip", chip_get}, Reason.DAILYWHEEL_LOGIN_OBTAIN())
        vip_extra_bonus = VIPConfig[vip_level].daily_wheel_bonus * 1000
        vip_extra_chip = chip_get * VIPConfig[vip_level].daily_wheel_bonus
        Player:Obtain(player, {"Chip", vip_extra_chip}, Reason.DAILYWHEEL_VIP_EXTRA_OBTAIN())

        -- 连续登录奖励的逻辑
        if os.is_yesterday(player.character.last_wheel_time) then
            player.daily_wheel.continue_login_days = player.daily_wheel.continue_login_days + 1
            if player.daily_wheel.continue_login_days > 7 then
                player.daily_wheel.continue_login_days = 1
                player.character.is_old_hand = 1
            end
        else
            player.daily_wheel.continue_login_days = 1
            if (player.character.last_wheel_time == 0) then
                player.character.is_old_hand = 0
            -- else
            --     player.character.is_old_hand = 1
            end
        end

        local his_max_con_login_days = daily_wheel_json.max_con_login_days

        local con_login_days = player.daily_wheel.continue_login_days

        if (con_login_days > daily_wheel_json.max_con_login_days) then
            daily_wheel_json.max_con_login_days = con_login_days
        end

        con_login_reward = LoginRewardConfig[con_login_days].bonus
        con_login_diamonds = LoginRewardConfig[con_login_days].diamonds

        if (con_login_days > his_max_con_login_days) then
            con_login_reward = con_login_reward + LoginRewardConfig[con_login_days].extra_bonus
        end

        if (daily_wheel_json.his_collect_info == nil) then
            daily_wheel_json.his_collect_info = {}
        end
        local his_collect_info = daily_wheel_json.his_collect_info
        if (his_collect_info["day_"..player.daily_wheel.continue_login_days] == nil) then
            his_collect_info["day_"..player.daily_wheel.continue_login_days] = 1
        else
            his_collect_info["day_"..player.daily_wheel.continue_login_days] = his_collect_info["day_"..player.daily_wheel.continue_login_days] + 1
        end
    
        Player:Obtain(player, {"Chip", con_login_reward}, Reason.LOGIN_REWARD_OBTAIN())
        -- Player:Obtain(player, {"Diamond", con_login_diamonds}, Reason.LOGIN_REWARD_OBTAIN())

        if (vip_point_award > 0) then
            player.character.vip_points = player.character.vip_points + vip_point_award
            Player:UpdateVIP(session)
        end

        -- opt

        Spark:DailyWheel(player, {
            [1] = chip_get,
            [2] = con_login_days,
            [3] = con_login_reward,
            [4] = con_login_diamonds,
            [5] = vip_extra_chip,
        })
    end
    player.daily_wheel.json_str = json.encode(daily_wheel_json)
    return index, chip_get, vip_extra_bonus, con_login_reward, con_login_diamonds, player.daily_wheel.continue_login_days, vip_point_award, cur_wheel_name, old_wheel_name, daily_wheel_json.his_collect_info 
end
