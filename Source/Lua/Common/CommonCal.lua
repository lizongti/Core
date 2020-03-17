--------------
--  LineNum  --
--------------
require "Common/GameType"
require "Common/LuckyType"
require "Config/system/ConstValue"
require "Config/system/GameMapConfig"
require "Common/PantherTracksCal"
require "Common/TournamnetInclude"
require "Common/ClimbSlideCal"
module("CommonCal", package.seeall)

NEWHAND_LEVLE0 = 10
NEWHAND_LEVLE1 = 20
NEWHAND_LEVLE2 = 25

--锦标赛相关数据
local tournament_redis = TournamentRedisHelperClass --锦标赛数据帮助器(Redis)
local tournament_mem = TournamentMemHelperClass --锦标赛数据帮助器(内存)

Calculate = {
    RandIndex = function(player, config, key)
        local weights = {}
        for i = 1, #config do
            table.insert(weights, config[i][key])
        end
        local index = math.rand_weight(player, weights)
        return index
    end,
    GetConfig = function(player, is_free_spin, config_base, config_free_spin)
        local config = nil
        if not is_free_spin then
            config = CommonCal.Calculate.get_config(player, config_base)
        else
            config = CommonCal.Calculate.get_config(player, config_free_spin)
        end
        return config
    end,
    UpdateJackpotValues = function(player, save_data, total_amount, config_name)
        save_data.jackpot_param = save_data.jackpot_param or {}
        local jackpot_param = save_data.jackpot_param
        local config = CommonCal.Calculate.get_config(player, config_name)

        -- 初始化jackpot，增加值
        for i = 1, 4 do
            if not jackpot_param[i] then
                jackpot_param[i] = 0
            end
            local add_value = total_amount * config[i].bet_to_chip_percent
            jackpot_param[i] = jackpot_param[i] + add_value
        end
    end,
    GetBetIndex = function(game_type, amount)
        local game_bet_amount_conf = _G[GameMapConfig[game_type].bet_amount_config]

        for k, v in ipairs(game_bet_amount_conf) do
            if v.single_amount == amount then
                return k
            end
        end

        for k, v in ipairs(game_bet_amount_conf) do
            local next_amount = 999999999999
            if game_bet_amount_conf[k + 1] ~= nil then
                next_amount = game_bet_amount_conf[k + 1].single_amount
            end
            if v.single_amount <= amount and amount < next_amount then
                return k
            end
        end

        return 1
    end,
    --更新jackpot
    UpdateJackpotExtraChip = function(is_free_spin, config_name, save_data, total_amount, pre_action_list)
        if not is_free_spin then
            table.insert(
                pre_action_list,
                {
                    action_type = ActionType.ActionTypes.GameJackpotPool,
                    jackpot_param = CommonCal.Calculate.GetJakcpotParamToClient(save_data.jackpot_param_v2)
                }
            )

            local config = CommonCal.Calculate.get_config(player, config_name)
            CommonCal.Calculate.AddJackpotExtraChip(save_data.jackpot_param_v2, total_amount, config)
        end
    end,
    InitJackpotValues = function(player, save_data)
        save_data.jackpot_param = save_data.jackpot_param or {}
        local jackpot_param = save_data.jackpot_param
        local config = CommonCal.Calculate.get_config(player, "NewBacktoJurassicJackpotConfig")

        -- 初始化jackpot，增加值
        for i = 1, #config do
            if not jackpot_param[i] then
                jackpot_param[i] = 0
            end
        end
    end,
    LevelReq = function(player, game_type)
        return 0
    end,
    IsAppear = function(player)
        local is_lock = CommonCal.Calculate.LevelReq(player, player.game_type)
        return is_lock
    end,
    GetUnLockInfo = function(player)
        local unlock_games = {}
        player.unlock_games = json.encode(unlock_games)
    end,
    UpdatePlayerLock = function(player)
    end,
    get_shop_config = function(player)
        local ActivityTimeConfig = CommonCal.Calculate.get_config(player, "ActivityTimeConfig")
        for k, v in pairs(ActivityTimeConfig) do
            local res, start_time, end_time, current_time, file_name = CommonCal.Calculate.GetActivityInfo(player, k)
            if (res and file_name ~= "") then
                return Calculate.get_config(player, file_name), true
            end
        end

        return Calculate.get_config(player, "ShopConfig"), false
    end,
    
    update_bonus_info = function(session, task, player, bonus_info)
        local player_extern = Calculate.get_player_extern(session, task, player)

        -- LOG(RUN, INFO).Format("[SlotsGame][update_bonus_info] player is: %s, player_extern is:%s", player.id, Table2Str(player_extern))
        local json_str = player_extern.save_data

        if (json_str["bonus_info"] ~= bonus_info) then
            json_str["bonus_info"] = bonus_info

            Calculate.update_player_extern(session, task, player)
        end
    end,
    ---更新免费用户中倍数为mega win的次数
    update_feature_mega = function(session, task, player, feature_num_info)
        local player_extern = Calculate.get_player_extern(session, task, player)

        local json_str = player_extern.save_data

        if (json_str["feature_num_info"] ~= feature_num_info) then
            json_str["feature_num_info"] = feature_num_info

            Calculate.update_player_extern(session, task, player)
        end
    end,
    get_extern_info = function(session, task, player, key)
        local player_extern = Calculate.get_player_extern(session, task, player)

        local json_str = player_extern.save_data

        if (json_str[key] == nil) then
            return "[]"
        end
        return json_str[key]
    end,
    update_player_extern = function(session, task, player)
        session.player_extern.json_str = json.encode(session.player_extern.save_data)
        CommonCal.Calculate.UpdateToDbCache(task, player, "player_extern", session.player_extern)
    end,
    CalcBaseWithLevel = function(base, player_level)
        local configs = {}

        for k, v in pairs(ShopExtraCoinConfig) do
            table.insert(configs, v)
        end

        table.sort(
            configs,
            function(a, b)
                return a.id > b.id
            end
        )

        local c = nil

        for i = 1, #configs do
            if player_level >= configs[i].id then
                c = configs[i]
                break
            end
        end

        if not c then
            return base
        end

        return base * (1 + c.base_extra_coins)
    end,
    get_player_extern = function(session, task, player)
        if (session.player_extern == nil) then
            if (session.is_monitor == nil) then
                local async_response = CommonCal.Calculate.LoadFromDbCache(task, player, "player_extern", player.id)
                if (async_response[1].row_num > 0) then
                    local data_set = async_response[1].data_set
                    for k, v in pairs(data_set) do
                        local player_extern = {}

                        for itemk, itemv in pairs(v) do
                            player_extern[itemv.column_name] = itemv.value
                        end

                        session.player_extern = player_extern
                    end
                end
            end

            if (session.player_extern == nil) then
                ----------------创建初始值---------------------
                session.player_extern = {
                    player_id = player.id,
                    json_str = "[]"
                }
                if (session.is_monitor == nil) then
                    CommonCal.Calculate.SaveToDbCache(task, "player_extern", session.player_extern)
                end
            end
        end

        --只有不存在时才从json_str里面取
        if not session.player_extern.save_data then
            session.player_extern.save_data = json.decode(session.player_extern.json_str or "[]") or {}
        end

        ---增加freespin次数
        if (session.player_extern.save_data.is_free_spin_ad == nil) then
            session.player_extern.save_data.is_free_spin_ad = 0
        end

        --破产次数初始化
        if (session.player_extern.save_data.ContinuousSpinWithoutBankrupt == nil) then
            session.player_extern.save_data.ContinuousSpinWithoutBankrupt = 0
        end

        if (session.player_extern.save_data.ContinuousSpinNoPay == nil) then
            session.player_extern.save_data.ContinuousSpinNoPay = 0
        end

        player.player_extern = session.player_extern

        return session.player_extern
    end,
    UpdatePlayerGameStatus = function(session, task, player, game_type, player_game_status)
        local game_status = Calculate.GetGameStatus(session, task, player, game_type)

        game_status.history_data = json.encode(player_game_status.history_data)
        game_status.history_swap = json.encode(player_game_status.history_swap)

        if session.is_monitor == nil then
            local table_name = string.format("slots_status_%s", math.mod(player.id, 16))

            CommonCal.Calculate.UpdateToDbCache(task, player, table_name, game_status)
        end
    end,
    GetPlayerGameStatus = function(session, task, player, game_type)
        local game_status = Calculate.GetGameStatus(session, task, player, game_type)
        local player_game_status = {}
        player_game_status.history_data = json.decode(game_status.history_data)
        player_game_status.history_swap = json.decode(game_status.history_swap)
        player_game_status.game_type = game_status.game_type
        player_game_status.player_id = player.id
        if (player_game_status.history_data == nil) then
            player_game_status.history_data = {}
        end
        if (player_game_status.history_swap == nil) then
            player_game_status.history_swap = {}
        end
        if (player_game_status.history_data.info == nil) then
            player_game_status.history_data.info = {}
        end
        return player_game_status
    end,
    GetGameStatus = function(session, task, player, game_type)
        if (session.game_status ~= nil and session.game_status[game_type] ~= nil) then
            return session.game_status[game_type]
        end

        local table_name = string.format("slots_status_%s", math.mod(player.id, 16))
        if (session.game_status == nil) then
            session.game_status = {}

            if (session.is_monitor == nil) then
                local async_response = CommonCal.Calculate.LoadFromDbCache(task, player, table_name, player.id)
                if (async_response[1].row_num > 0) then
                    local data_set = async_response[1].data_set
                    for datak, datav in pairs(data_set) do
                        for k, v in pairs(datav) do
                            local game_status = {}

                            for itemk, itemv in pairs(v) do
                                game_status[itemv.column_name] = itemv.value
                            end

                            session.game_status[game_status.game_type] = game_status
                        end
                    end
                end
            end
        end

        local is_update = false
        for k, v in pairs(session.game_status) do
            is_update = true
            break
        end

        if (session.game_status[game_type] == nil) then
            session.game_status[game_type] = {
                player_id = player.id,
                game_type = game_type,
                history_data = "[]",
                history_swap = "[]"
            }

            if (session.is_monitor == nil) then
                if (is_update) then
                    CommonCal.Calculate.UpdateToDbCache(task, player, table_name, session.game_status[game_type])
                else
                    CommonCal.Calculate.SaveToDbCache(task, table_name, session.game_status[game_type])
                end
            end
        end
        LOG(RUN, INFO).Format("[SlotsGame][GetGameStatus] player is: %s OK", player.id)
        return session.game_status[game_type]
    end,
    get_feature_condition = function(session, task, player, game_type)
        local table_define = TableDefine["feature_condition"]

        if (session.feature_condition ~= nil and session.feature_condition[game_type] ~= nil) then
            return session.feature_condition[game_type]
        end

        if (session.feature_condition == nil) then
            session.feature_condition = {}
            local async_response = CommonCal.Calculate.LoadFromDbCache(task, player, "feature_condition", player.id)
            if (async_response[1].row_num > 0) then
                local data_set = async_response[1].data_set
                for datak, datav in pairs(data_set) do
                    for k, v in pairs(datav) do
                        local feature_condition = {}

                        for itemk, itemv in pairs(v) do
                            feature_condition[itemv.column_name] = itemv.value
                        end

                        session.feature_condition[feature_condition.game_type] = feature_condition
                    end
                end
            end
        end

        if (session.feature_condition[game_type] == nil) then
            ----------------创建初始值---------------------
            session.feature_condition[game_type] = {
                chips = 999999999,
                spin_num = 0,
                bet_amount = 999999999,
                game_type = game_type,
                player_id = player.id,
                free_spin_count = 0,
                enter_num = 0,
                is_multiply = 0
            }

            CommonCal.Calculate.SaveToDbCache(task, "feature_condition", session.feature_condition[game_type])
        end
        return session.feature_condition[game_type]
    end,
    get_new_hand_config = function(player, free_item_id, reel_file_name, config, game_name, feature_file)
        if (player.character.vip == 0) then
            if (player.character.level <= tonumber(ConstValue[8].value)) then
                reel_file_name =
                    free_item_id and game_name .. "NewHand1FeatureReelConfig" or game_name .. "NewHand1BaseReelConfig"
            elseif (player.character.level <= tonumber(ConstValue[9].value)) then
                reel_file_name =
                    free_item_id and game_name .. "NewHand2FeatureReelConfig" or game_name .. "NewHand2BaseReelConfig"
            elseif (player.character.level <= tonumber(ConstValue[10].value)) then
                reel_file_name =
                    free_item_id and game_name .. "NewHand3FeatureReelConfig" or game_name .. "NewHand3BaseReelConfig"
            end
        end

        if (feature_file ~= nil and feature_file ~= "") then
            reel_file_name = feature_file
        end
        config = CommonCal.Calculate.get_config(player, reel_file_name)
        return reel_file_name, config
    end,
    get_name = function()
        local first_name = {}
        local last_name = {}
        for k, v in pairs(SlotsNameConfig) do
            if (v.first_name ~= "") then
                table.insert(first_name, v.first_name)
            end
            if (v.last_name ~= "") then
                table.insert(last_name, v.last_name)
            end
        end

        local first_name_len = #first_name
        local first_name_index = math.random(1, first_name_len)
        local last_name_len = #last_name
        local last_name_index = math.random(1, last_name_len)
        local new_name = first_name[first_name_index] .. " " .. last_name[last_name_index]
        return new_name
    end,
    GetFreeWin = function(is_free_spin, win_chip, is_feature_spin_in_free_spin)
        local free_win = 0
        if (is_free_spin) then
            free_win = win_chip
        else
            if is_feature_spin_in_free_spin then
                free_win = win_chip
            end
        end
        return free_win
    end,
    is_old_game = function(game_type)
        local table_define = TableDefine["game_info"]

        if (game_type == GameType.AllTypes.IceAndFire) then
            return false
        end

        if (game_type == GameType.AllTypes.WestWorld) then
            return true
        end

        if (game_type == GameType.AllTypes.Ice777) then
            return true
        end

        if (game_type < GameType.AllTypes.LeprechaunTreasure) then
            return true
        end

        return false
    end,
    ---------------修改玩家的json_str内容
    set_game_json_value = function(player_game_info, key, value)
        local save_data = player_game_info.save_data
        if (save_data == nil) then
            save_data = {}
        end

        save_data[key] = value
    end,
    ---------------获取玩家的json_str内容
    get_game_json_value = function(player_game_info, key)
        local save_data = player_game_info.save_data

        if (save_data == nil) then
            return nil
        end

        return save_data[key]
    end,
    copy_game_info = function(game_type, s_game_info, d_game_info)
        for k, v in pairs(s_game_info) do
            d_game_info[k] = v
        end
    end,
    get_init_game_info = function(player, game_type)
        ----------------创建初始值---------------------
        local game_info = {
            bet_amount = 100,
            free_spin_bouts = 0,
            free_spin_num = 0,
            bouts_id = 0,
            channel_id = "",
            total_loss = 0,
            enter_chip = 0,
            spined_times = 0,
            free_total_win = 0,
            free_item_id = 0,
            game_type = game_type,
            player_id = player.id,
            json_str = "[]",
            bonus_game_type = 0,
            last_formation_list = "[]",
            total_spined_times = 0,
            mother_dragons_type = 0,
            mother_dragons_str = "[]",
            raven_prophet_str = "[]",
            sticky_wild_pos_list = "[]",
            extral_spin_bouts = 0,
            total_spin_bouts = 0,
            free_spined_count = 0
        }
        return game_info
    end,
    get_game_info = function(session, task, player, game_type)
        local game_room_config = GameRoomConfig[game_type]

        --if (not Calculate.is_old_game(game_type)) then
        if (session.game_info ~= nil and session.game_info[game_type] ~= nil) then
            return session.game_info[game_type]
        end

        local table_name = string.format("game_info_%s", math.mod(player.id, 16))

        if (session.game_info == nil) then
            session.game_info = {}
            local async_response = CommonCal.Calculate.LoadFromDbCache(task, player, table_name, player.id)
            if (async_response[1].row_num > 0) then
                local data_set = async_response[1].data_set
                for k, v in pairs(data_set) do
                    for itemk, itemv in pairs(v) do
                        local game_info = {}

                        for subitemk, subitemv in pairs(itemv) do
                            game_info[subitemv.column_name] = subitemv.value
                        end

                        ---如果在原有的表上添加新字段，先给默认值
                        session.game_info[game_info.game_type] =
                            Calculate.get_init_game_info(player, game_info.game_type)

                        for subitemk, subitemv in pairs(itemv) do
                            session.game_info[game_info.game_type][subitemv.column_name] = subitemv.value
                        end
                    end
                end
            end
        end

        local is_update = false
        for k, v in pairs(session.game_info) do
            is_update = true
            break
        end

        if (session.game_info[game_type] == nil) then
            ---如果在原有的表上添加新字段，先给默认值
            session.game_info[game_type] = Calculate.get_init_game_info(player, game_type)

            if (is_update) then
                CommonCal.Calculate.UpdateToDbCache(task, player, table_name, session.game_info[game_type])
            else
                CommonCal.Calculate.SaveToDbCache(task, table_name, session.game_info[game_type])
            end
        end
        return session.game_info[game_type]
    end,
    InitFunctions = function(player, info)
        GameStatusDefine.AllFuncs[player.id] = info
    end,
    GetFunctions = function(player)
        return GameStatusDefine.AllFuncs[player.id]
    end,
    CopyFunctions = function(target, from)
        if (from and target) then
            for key, value in pairs(from) do
                if (type(from[key]) == "function") then
                    target[key] = from[key]
                end
            end
        end
    end,
    InitPriorityLevel = function(game_type, info)
        local key = "game" .. game_type
        GameStatusDefine.PriorityLevel[key] = info
    end,
    InitSortedPriorityLevel = function(game_type)
        local key = "game" .. game_type
        local info = GameStatusDefine.PriorityLevel[key]
        GameStatusDefine.SortedPriorityLevel = {}
        GameStatusDefine.GtSortedPriorityLevel = {}
        function SortGT(a, b)
            return a > b
        end

        for k, v in pairs(info) do
            local is_exist = false
            for sub_k, sub_v in pairs(GameStatusDefine.SortedPriorityLevel) do
                if (sub_v == v) then
                    is_exist = true
                    break
                end
            end
            if (not is_exist) then
                table.insert(GameStatusDefine.SortedPriorityLevel, v)
                table.insert(GameStatusDefine.GtSortedPriorityLevel, v)
            end
        end
        table.sort(GameStatusDefine.SortedPriorityLevel)
        table.sort(GameStatusDefine.GtSortedPriorityLevel, SortGT)
    end,
    SetPriorityLevel = function(game_type, status_id, priority_value)
        local key = "game" .. game_type
        local info = GameStatusDefine.PriorityLevel[key]
        info[status_id] = priority_value
    end,
    GetPriorityLevel = function(game_type, status_id)
        local key = "game" .. game_type
        local info = GameStatusDefine.PriorityLevel[key]
        return info[status_id] or 1
    end,
    get_default_slots_info = function(game_type)
        local content_table = {}
        if (game_type == GameType.AllTypes.AgentBond) then
            content_table = {
                bet_amount = 100,
                free_spin_bouts = 0,
                free_spin_num = 0,
                bouts_id = 0,
                channel_id = "",
                total_loss = 0,
                enter_chip = 0,
                spined_times = 0,
                free_total_win = 0,
                bonus_num = 0,
                bonus_game_chip_info = "[]",
                DragonTalePayrateConfig = "[]",
                bet_amount_history = "[]",
                --begin --> 修改bons玩法 201811291444
                bonus_collect_id = 0, --触发bons需要收集的物品id
                bonus_collect_count_need = 0, --触发bonsbons需要收集物品的数量
                bonus_collect_count_have = 0, --触发bonsbons已经收集物品的数量
                --end   <-- 修改bons玩法 201811291444
                json_str = "[]",
                total_spined_times = 0,
                extral_spin_bouts = 0,
                total_spin_bouts = 0,
                free_spined_count = 0
            }
        elseif (game_type == GameType.AllTypes.AliceinWonderland) then
            content_table = {
                bet_amount = 100,
                free_spin_bouts = 0,
                bouts_id = 0,
                channel_id = "",
                total_loss = 0,
                enter_chip = 0,
                spined_times = 0,
                free_total_win = 0,
                is_jackpot = 0,
                free_item_id = 0,
                protect_number = 0,
                protect_index = 0,
                json_str = "[]",
                total_spined_times = 0,
                extral_spin_bouts = 0,
                total_spin_bouts = 0,
                free_spined_count = 0
            }
        elseif (game_type == GameType.AllTypes.BacktoJurassic) then
            content_table = {
                bet_amount = 100,
                free_spin_bouts = 0,
                free_spin_num = 0,
                bouts_id = 0,
                channel_id = "",
                total_loss = 0,
                enter_chip = 0,
                spined_times = 0,
                free_total_win = 0,
                free_item_id = 0,
                free_spin_type = 0,
                free_spin_num_str = "",
                json_str = "[]",
                total_spined_times = 0,
                extral_spin_bouts = 0,
                total_spin_bouts = 0,
                free_spined_count = 0
            }
        elseif (game_type == GameType.AllTypes.BruceLee) then
            content_table = {
                bet_amount = 100,
                free_spin_bouts = 0,
                free_spin_num = 0,
                -- bouts_id = 0,
                channel_id = "",
                total_loss = 0,
                enter_chip = 0,
                spined_times = 0,
                free_total_win = 0,
                free_spin_num_str = "[]",
                free_spin_type = 0,
                json_str = "[]",
                total_spined_times = 0,
                extral_spin_bouts = 0,
                total_spin_bouts = 0,
                free_spined_count = 0
            }
        elseif (game_type == GameType.AllTypes.CashSpin) then
            content_table = {
                bet_amount = 100,
                bouts_id = 0,
                channel_id = "",
                total_loss = 0,
                enter_chip = 0,
                spined_times = 0,
                is_bonus_game = 0,
                bonus_sel_items = "[]",
                bonus_unsel_items = "[]",
                bonus_remain_items = "[]",
                freeze_list = "[]",
                item_ids = "[]",
                json_str = "[]",
                total_spined_times = 0,
                extral_spin_bouts = 0,
                total_spin_bouts = 0,
                free_spined_count = 0
            }
        elseif (game_type == GameType.AllTypes.ChefsChoice) then
            content_table = {
                bet_amount = 100,
                free_spin_bouts = 0,
                free_spin_num = 0,
                bouts_id = 0,
                channel_id = "",
                total_loss = 0,
                enter_chip = 0,
                spined_times = 0,
                free_total_win = 0,
                free_spin_num_str = "[]",
                json_str = "[]",
                total_spined_times = 0,
                extral_spin_bouts = 0,
                total_spin_bouts = 0,
                free_spined_count = 0
            }
        elseif (game_type == GameType.AllTypes.ChineseNewYear) then
            content_table = {
                bet_amount = 100,
                free_spin_bouts = 0,
                bouts_id = 0,
                channel_id = "",
                total_loss = 0,
                enter_chip = 0,
                spined_times = 0,
                free_total_win = 0,
                free_spin_type = 0,
                is_bonus_bet = 0,
                scatter_count = 0,
                bet_chip = 0,
                json_str = "[]",
                total_spined_times = 0,
                extral_spin_bouts = 0,
                total_spin_bouts = 0,
                free_spined_count = 0
            }
        elseif (game_type == GameType.AllTypes.Ice777) then
            content_table = {
                bet_amount = 100,
                free_spin_bouts = 0,
                free_spin_num = 0,
                bouts_id = 0,
                channel_id = "",
                total_loss = 0,
                enter_chip = 0,
                spined_times = 0,
                free_total_win = 0,
                free_item_id = 0,
                json_str = "[]",
                total_spined_times = 0,
                extral_spin_bouts = 0,
                total_spin_bouts = 0,
                free_spined_count = 0
            }
        elseif (game_type == GameType.AllTypes.IceAndFire) then
            content_table = {
                bet_amount = 100,
                free_spin_bouts = 0,
                free_spin_num = 0,
                bouts_id = 0,
                channel_id = "",
                total_loss = 0,
                enter_chip = 0,
                spined_times = 0,
                free_total_win = 0,
                free_item_id = 0,
                json_str = "[]",
                total_spined_times = 0,
                extral_spin_bouts = 0,
                total_spin_bouts = 0,
                free_spined_count = 0
            }
        elseif (game_type == GameType.AllTypes.LeprechaunTreasure) then
            content_table = {
                bet_amount = 100,
                free_spin_bouts = 0,
                free_spin_num = 0,
                bouts_id = 0,
                channel_id = "",
                total_loss = 0,
                enter_chip = 0,
                spined_times = 0,
                free_total_win = 0,
                free_item_id = 0,
                json_str = "[]",
                total_spined_times = 0,
                extral_spin_bouts = 0,
                total_spin_bouts = 0,
                free_spined_count = 0
            }
        elseif (game_type == GameType.AllTypes.DragonTale) then
            content_table = {
                bet_amount = 100,
                free_spin_bouts = 0,
                bouts_id = 0,
                channel_id = "",
                total_loss = 0,
                enter_chip = 0,
                spined_times = 0,
                free_total_win = 0,
                json_str = "[]",
                total_spined_times = 0,
                extral_spin_bouts = 0,
                total_spin_bouts = 0,
                free_spined_count = 0
            }
        elseif (game_type == GameType.AllTypes.ElvesEpic) then
            content_table = {
                bet_amount = 100,
                free_spin_bouts = 0,
                bouts_id = 0,
                channel_id = "",
                total_loss = 0,
                enter_chip = 0,
                spined_times = 0,
                free_total_win = 0,
                is_jackpot = 0,
                json_str = "[]",
                total_spined_times = 0,
                extral_spin_bouts = 0,
                total_spin_bouts = 0,
                free_spined_count = 0
            }
        elseif (game_type == GameType.AllTypes.SummerBeach) then
            content_table = {
                bet_amount = 100,
                free_spin_bouts = 0,
                free_spin_num = 0,
                bouts_id = 0,
                channel_id = "",
                total_loss = 0,
                enter_chip = 0,
                spined_times = 0,
                free_total_win = 0,
                free_item_id = 0,
                json_str = "[]",
                total_spined_times = 0,
                extral_spin_bouts = 0,
                total_spin_bouts = 0,
                free_spined_count = 0
            }
        elseif (game_type == GameType.AllTypes.ForbiddenCity) then
            content_table = {
                bet_amount = 100,
                free_spin_bouts = 0,
                free_spin_multi = 1,
                bouts_id = 0,
                channel_id = "",
                trigger_free_spin = 0,
                total_loss = 0,
                enter_chip = 0,
                spined_times = 0,
                free_total_win = 0,
                json_str = "[]",
                total_spined_times = 0,
                extral_spin_bouts = 0,
                total_spin_bouts = 0,
                free_spined_count = 0
            }
        elseif (game_type == GameType.AllTypes.FruitSlice) then
            content_table = {
                bet_amount = 100,
                bouts_id = 0,
                channel_id = "",
                trigger_times = 0,
                total_loss = 0,
                enter_chip = 0,
                spined_times = 0,
                trigger_amounts = "[]",
                bonus_win_chip = 0,
                json_str = "[]",
                total_spined_times = 0,
                extral_spin_bouts = 0,
                total_spin_bouts = 0,
                free_spined_count = 0
            }
        elseif (game_type == GameType.AllTypes.HalloweenNight) then
            content_table = {
                bet_amount = 100,
                free_spin_bouts = 0,
                bouts_id = 0,
                channel_id = "",
                cd_wild_times = 0,
                cd_wild_index = 0,
                total_loss = 0,
                enter_chip = 0,
                spined_times = 0,
                free_total_win = 0,
                sticky_wild_pos_list = "[]",
                json_str = "[]",
                total_spined_times = 0,
                extral_spin_bouts = 0,
                total_spin_bouts = 0,
                free_spined_count = 0
            }
        elseif (game_type == GameType.AllTypes.LegendsofOlympus) then
            content_table = {
                bet_amount = 100,
                free_spin_bouts = 0,
                free_spin_num = 0,
                bouts_id = 0,
                channel_id = "",
                total_loss = 0,
                enter_chip = 0,
                spined_times = 0,
                free_total_win = 0,
                free_spin_num_str = "[]",
                scatter_count = 0,
                json_str = "[]",
                total_spined_times = 0,
                extral_spin_bouts = 0,
                total_spin_bouts = 0,
                free_spined_count = 0
            }
        elseif (game_type == GameType.AllTypes.LuxuryLife) then
            content_table = {
                bet_amount = 100,
                free_spin_bouts = 0,
                free_spin_num = 0,
                bouts_id = 0,
                channel_id = "",
                total_loss = 0,
                enter_chip = 0,
                spined_times = 0,
                free_total_win = 0,
                free_item_id = 0,
                free_spin_type = 0,
                free_spin_progress_str = "[]",
                special_item_str = "[]",
                his_bet_mount = "[]",
                json_str = "[]",
                total_spined_times = 0,
                extral_spin_bouts = 0,
                total_spin_bouts = 0,
                free_spined_count = 0
            }
        elseif (game_type == GameType.AllTypes.OpenSesame) then
            content_table = {
                bet_amount = 100,
                bonus_progress = 0,
                free_spin_bouts = 0,
                bouts_id = 0,
                channel_id = "",
                total_loss = 0,
                enter_chip = 0,
                spined_times = 0,
                free_total_win = 0,
                his_bet_mount = "[]",
                json_str = "[]",
                total_spined_times = 0,
                extral_spin_bouts = 0,
                total_spin_bouts = 0,
                free_spined_count = 0
            }
        elseif (game_type == GameType.AllTypes.PharaohTreasure) then
            content_table = {
                bet_amount = 100,
                bouts_id = 0,
                channel_id = "",
                choose_times = 0,
                bg_level = 1,
                history = "[]",
                total_loss = 0,
                enter_chip = 0,
                spined_times = 0,
                total_bonus = 0,
                json_str = "[]",
                total_spined_times = 0,
                extral_spin_bouts = 0,
                total_spin_bouts = 0,
                free_spined_count = 0
            }
        elseif (game_type == GameType.AllTypes.Pirate) then
            content_table = {
                bet_amount = 100,
                free_spin_bouts = 0,
                free_spin_num = 0,
                bouts_id = 0,
                channel_id = "",
                total_loss = 0,
                enter_chip = 0,
                spined_times = 0,
                free_total_win = 0,
                is_slots = 0,
                step_num = 0,
                json_str = "[]",
                total_spined_times = 0,
                extral_spin_bouts = 0,
                total_spin_bouts = 0,
                free_spined_count = 0
            }
        elseif (game_type == GameType.AllTypes.PurrfectPets) then
            content_table = {
                bet_amount = 100,
                free_spin_bouts = 0,
                bouts_id = 0,
                channel_id = "",
                total_loss = 0,
                enter_chip = 0,
                spined_times = 0,
                free_total_win = 0,
                free_item_id = 0,
                json_str = "[]",
                total_spined_times = 0,
                extral_spin_bouts = 0,
                total_spin_bouts = 0,
                free_spined_count = 0
            }
        elseif (game_type == GameType.AllTypes.SantaSuprise) then
            content_table = {
                bet_amount = 100,
                free_spin_bouts = 0,
                free_spin_num = 0,
                bouts_id = 0,
                channel_id = "",
                total_loss = 0,
                enter_chip = 0,
                spined_times = 0,
                free_total_win = 0,
                gift_item = 0,
                item_ids = "[]",
                wild_pos = 0,
                json_str = "[]",
                total_spined_times = 0,
                extral_spin_bouts = 0,
                total_spin_bouts = 0,
                free_spined_count = 0
            }
        elseif (game_type == GameType.AllTypes.Vampire) then
            content_table = {
                bet_amount = 100,
                free_spin_bouts = 0,
                bouts_id = 0,
                channel_id = "",
                total_loss = 0,
                enter_chip = 0,
                spined_times = 0,
                free_total_win = 0,
                json_str = "[]",
                total_spined_times = 0,
                extral_spin_bouts = 0,
                total_spin_bouts = 0,
                free_spined_count = 0
            }
        elseif (game_type == GameType.AllTypes.WestWorld) then
            content_table = {
                bet_amount = 100,
                free_spin_bouts = 0,
                bouts_id = 0,
                channel_id = "",
                total_loss = 0,
                enter_chip = 0,
                spined_times = 0,
                free_total_win = 0,
                json_str = "[]",
                total_spined_times = 0,
                extral_spin_bouts = 0,
                total_spin_bouts = 0,
                free_spined_count = 0
            }
        elseif (game_type == GameType.AllTypes.WildCircus) then
            content_table = {
                bet_amount = 100,
                free_spin_bouts = 0,
                free_spin_num = 0,
                bouts_id = 0,
                channel_id = "",
                total_loss = 0,
                enter_chip = 0,
                spined_times = 0,
                free_total_win = 0,
                free_spin_scatter_count = 0,
                total_free_spin_bouts = 0,
                json_str = "[]",
                total_spined_times = 0,
                extral_spin_bouts = 0,
                total_spin_bouts = 0,
                free_spined_count = 0
            }
        end
        return content_table
        -- body
    end,
    
    get_slots_info = function(session, task, player, game_type)
        local game_room_config = GameRoomConfig[game_type]

        if (session.slots_info ~= nil and session.slots_info[game_type] ~= nil) then
            return session.slots_info[game_type]
        end

        local table_name = string.format("slots_info_%s", math.mod(player.id, 16))

        if (session.slots_info == nil) then
            session.slots_info = {}

            local async_response = CommonCal.Calculate.LoadFromDbCache(task, player, table_name, player.id)
            if (async_response[1].row_num > 0) then
                local data_set = async_response[1].data_set
                for datak, datav in pairs(data_set) do
                    for k, v in pairs(datav) do
                        local sel_game_type = 0
                        local sel_content = {}

                        for itemk, itemv in pairs(v) do
                            if (itemv.column_name == "game_type") then
                                sel_game_type = itemv.value
                            elseif (itemv.column_name == "content") then
                                sel_content = json.decode(itemv.value)
                            end
                        end

                        local content_table = CommonCal.Calculate.get_default_slots_info(sel_game_type)

                        if sel_content then
                            for column_name, value in pairs(sel_content) do
                                content_table[column_name] = value
                            end
                        end

                        session.slots_info[sel_game_type] = {
                            game_type = sel_game_type,
                            player_id = player.id,
                            content = json.encode(content_table)
                        }
                    end
                end
            end
        end

        if (session.slots_info[game_type] == nil) then
            local content_table = CommonCal.Calculate.get_default_slots_info(game_type)
            ----------------创建初始值---------------------
            session.slots_info[game_type] = {
                game_type = game_type,
                player_id = player.id,
                content = json.encode(content_table)
            }

            local is_update = false
            for k, v in pairs(session.slots_info) do
                is_update = true
                break
            end
            if (is_update) then
                CommonCal.Calculate.UpdateToDbCache(task, player, table_name, session.slots_info[game_type])
            else
                CommonCal.Calculate.SaveToDbCache(task, table_name, session.slots_info[game_type])
            end
        end

        return session.slots_info[game_type]
    end,
    --------------翻倍活动奖励
    GetActivityInfo = function(player, activity_type)
        local ActivityTimeConfig = CommonCal.Calculate.get_config(player, "ActivityTimeConfig")
        if (ActivityTimeConfig[activity_type] == nil) then
            return false, 0, 0, 0, ""
        end
        local start_time_str = ActivityTimeConfig[activity_type].start_time
        local end_time_str = ActivityTimeConfig[activity_type].end_time

        local start_date = string.split(start_time_str, ":")
        local end_date = string.split(end_time_str, ":")

        local start_time =
            os.time(
            {
                year = start_date[1],
                month = start_date[2],
                day = start_date[3],
                hour = start_date[4],
                min = start_date[5],
                sec = 0
            }
        )
        local end_time =
            os.time(
            {year = end_date[1], month = end_date[2], day = end_date[3], hour = end_date[4], min = end_date[5], sec = 0}
        )

        local current_time = os.time()

        if (current_time >= start_time and current_time < end_time) then
            return true, start_time, end_time, current_time, ActivityTimeConfig[activity_type].file_name
        end

        return false, start_time, end_time, current_time, ActivityTimeConfig[activity_type].file_name
    end,
    get_config = function(player, config_name)
        if not player then
            return _G["formal_android_mirror_testa" .. config_name]
        end
        local player_type = player.character.player_type
        local prefix = ""
        local server_type = (Base.Enviroment.pro_spec_t == "temporay") and "temporay" or "formal"
        local system_type = "android"
        local channel_type = "testa"

        local os_type = player.client.os
        if (string.find(os_type, "iOS") or string.find(os_type, "Mac")) then
            system_type = "ios"
        else
            system_type = "android"
        end

        if (PlayerTypeConfig[player_type] ~= nil) then
            channel_type = PlayerTypeConfig[player_type].name
        end

        local file_name =
            server_type .. "_" .. system_type .. "_" .. player.client.channel .. "_" .. channel_type .. config_name

        if (_G[file_name] == nil) then
            file_name = "formal_android_mirror_" .. channel_type .. config_name
        end

        if (_G[file_name] == nil) then
            file_name = "formal_android_mirror_testa" .. config_name
        end

        return _G[file_name]
    end,
    table_leng = function(t)
        local leng = 0
        for k, v in pairs(t) do
            leng = leng + 1
        end
        return leng
    end,
    convertTimeForm = function(second)
        local timeDay = math.floor(second / 86400)
        local timeHour = math.fmod(math.floor(second / 3600), 24)
        local timeMinute = math.fmod(math.floor(second / 60), 60)
        local timeSecond = math.fmod(second, 60)

        return timeDay, timeHour, timeMinute, timeSecond
    end,
    UpdateSlotsToDbCache = function(task, player, player_slots_info, player_game_info)
        --在SlotsGame里面特殊处理
        if player_game_info then
            local save_data = player_game_info.save_data
            player_game_info.save_data = nil
            --禁止其他时候存在json_str
            assert(player_game_info.json_str == nil)
            player_game_info.json_str = json.encode(save_data)
            player_slots_info.content = json.encode(player_game_info)
            player_game_info.save_data = save_data
            player_game_info.json_str = nil
        end

        local table_name = string.format("slots_info_%s", math.mod(player.id, 16))
        CommonCal.Calculate.UpdateToDbCache(task, player, table_name, player_slots_info)
    end,
    UpdateGameInfoToDbCache = function(task, player, player_game_info)
        assert(player_game_info.json_str == nil)
        player_game_info.json_str = json.encode(player_game_info.save_data)
        local table_name = string.format("game_info_%s", math.mod(player.id, 16))
        CommonCal.Calculate.UpdateToDbCache(task, player, table_name, player_game_info)
        player_game_info.json_str = nil
    end,
    -----------------新的存储开始--------------
    ---更新数据到DbCache
    UpdateToDbCache = function(task, player, table_name, table_content)
        if (player.character.player_type == tonumber(ConstValue[5].value)) then
            return
        end

        Calculate.SaveToDbCache(task, table_name, table_content)
    end,
    ---保存数据到DbCache
    SaveToDbCache = function(task, table_name, table_content)
        local table_info = {
            name = table_name,
            content = {}
        }

        local table_define = TableDefine[table_name]
        local cache_define = CacheDefine[table_name]

        local redis_commands = {}
        for k, v in pairs(table_define.content) do
            local value = string.encode(tostring(table_content[k]))
            local redis_command =
                string.format(
                "HMSET %s[%s] %s[%s].%s %s",
                table_name,
                table_content[cache_define.cache_key],
                table_name,
                table_content[cache_define.hash_key],
                k,
                value
            )
            table.insert(redis_commands, redis_command)
        end
        --LOG(RUN, INFO).Format("[CommonCal][SaveToDbCache] redis_commands: %s", Table2Str(redis_commands))

        LuaSession:Work(
            function()
                local cur_task = Task:Current()
                LuaSession:ContactJson("CacheClientService", cur_task, redis_commands, table_name)
            end
        )
    end,
    ---从DbCache获取数据
    LoadFromDbCache = function(task, player, table_name, load_id)
        local async_response = {}
        if (player ~= nil and player.character.player_type == tonumber(ConstValue[5].value)) then
            async_response[1] = {row_num = 0}
            return async_response
        end
        local table_define = TableDefine[table_name]

        local redis_command = string.format("HGETALL %s[%s]", table_name, load_id)

        --LOG(RUN, INFO).Format("[CommonCal][LoadFromDbCache] redis_command: %s", Table2Str(redis_command))

        local cur_task = Task:Current()

        local redis_request = {}
        table.insert(redis_request, redis_command)

        local redis_response = LuaSession:ContactJson("CacheClientService", Task:Current(), redis_request, table_name)
        --LOG(RUN, INFO).Format("[CommonCal][LoadFromDbCache] redis_response: %s", Table2Str(redis_response))
        async_response[1] = {row_num = 0}
        async_response[1].data_set = {}
        if (redis_response[1] and redis_response[1] ~= "") then
            local hash_key = nil
            local value = nil
            local column_name = nil
            for k, v in ipairs(redis_response) do
                if k % 2 == 1 then
                    key = v
                    local key_list = string.split(v, ".")
                    if (#key_list > 1) then
                        column_name = key_list[2]
                        key_list = string.split(key_list[1], "[")
                        temp_list = string.split(key_list[2], "]")
                        hash_key = tonumber(temp_list[1])
                    --LOG(RUN, INFO).Format("[CommonCal][LoadFromDbCache] hash_key: %s, column_name is:%s", hash_key, column_name)
                    end
                else
                    value = v
                    if (hash_key ~= nil and column_name ~= nil) then
                        if (hash_key == load_id) then
                            if (async_response[1].data_set[load_id] == nil) then
                                async_response[1].data_set[load_id] = {}
                            end
                            local value_type = table_define.content[column_name]
                            if (value_type ~= nil) then
                                if
                                    (string.find(value_type, "tinyint") or string.find(value_type, "smallint") or
                                        string.find(value_type, "bigint") or
                                        string.find(value_type, "int") or
                                        string.find(value_type, "float") or
                                        string.find(value_type, "double"))
                                 then
                                    value = tonumber(value)
                                end
                                table.insert(
                                    async_response[1].data_set[load_id],
                                    {column_name = column_name, value = value}
                                )
                            end
                        else
                            if (async_response[1].data_set[load_id] == nil) then
                                async_response[1].data_set[load_id] = {}
                            end
                            if (async_response[1].data_set[load_id][hash_key] == nil) then
                                async_response[1].data_set[load_id][hash_key] = {}
                            end
                            local value_type = table_define.content[column_name]
                            if (value_type ~= nil) then
                                if
                                    (string.find(value_type, "tinyint") or string.find(value_type, "smallint") or
                                        string.find(value_type, "bigint") or
                                        string.find(value_type, "int") or
                                        string.find(value_type, "float") or
                                        string.find(value_type, "double"))
                                 then
                                    value = tonumber(value)
                                end
                                table.insert(
                                    async_response[1].data_set[load_id][hash_key],
                                    {column_name = column_name, value = value}
                                )
                            end
                        end
                        async_response[1].row_num = async_response[1].row_num + 1
                    end
                end
            end
        end

        --LOG(RUN, INFO).Format("[CommonCal][LoadFromDbCache] async_response: %s", Table2Str(async_response))
        return async_response
    end,
    -----------------新的存储结束--------------
    MakeUpInRoom = function(session, task)
        local player = session.player

        if (player.game_type == 0) then
            return
        end

        if (player.game_type == tonumber(ConstValue[6].value)) then
            return
        end

        for k, v in pairs(GameRoomConfig) do
            if (v.game_type == player.game_type) then
                local async_request = {
                    header = {
                        router = "AsyncRequest",
                        service_name = v.contest_client_name,
                        task_id = task.id,
                        module_id = v.const_game_name,
                        message_id = v.const_game_name .. "_Exit_Request"
                    },
                    player_id = player.id
                }
                local async_response = session:ContactPacket(task, async_request)
                return
            end
        end
    end,
    GetFiveLineCount = function(all_prize_items)
        local five_line = 0
        for _, prize_info in ipairs(all_prize_items) do
            local prize_items = prize_info.prize_items
            if (prize_items == nil) then
                prize_items = prize_info
            end
            for k, v in ipairs(prize_items) do
                if v.continue_count and v.continue_count >= 5 then
                    five_line = five_line + 1
                end
            end
        end

        return five_line
    end,
    IsMultiply = function(session, total_win_chip)
        local player = session.player
        local currentTime = os.time()
        --local lastTime = CommonCal.Calculate.convertTimeForm(player.mega_win_time)
        --local curTime = CommonCal.Calculate.convertTimeForm(currentTime)

        local IsMultiplyFlag = 0
        if (not os.same_day(currentTime, player.mega_win_time)) then
            player.mega_win_time = currentTime
            player.mega_win_number = 0
        end
        IsMultiplyFlag = 1
        LOG(RUN, INFO).Format(
            "[IsMultiplyFlag] player is:%s mega_win_time is: %s, total_win_chip is:%s, mega_win_number is:%s, IsMultiplyFlag is:%s",
            player.id,
            player.mega_win_time,
            total_win_chip,
            player.mega_win_number,
            IsMultiplyFlag
        )

        player.mega_win_number = player.mega_win_number + 1

        --if (IsMultiplyFlag == 1) then
        player.mega_win_chips = "[]"
        local mega_win_chips = json.decode(player.mega_win_chips)
        table.insert(mega_win_chips, total_win_chip)
        player.mega_win_chips = json.encode(mega_win_chips)
        --end

        return IsMultiplyFlag
    end,
    Collect = function(session, player, is_ad)
        --local response = {header = {router = "Response"}}

        local total_chip = 0

        local current_time = os.time()
        local next_collect_time = 0
        local player = session.player

        if (player.character.collect_times < #CollectTimesConfig) then
            local dur_time = tonumber(ConstValue[21].value)
            next_collect_time = player.character.last_collect_time + dur_time
        else
            local daily_last_collect_date = os.date("*t", player.character.last_collect_reset_time)
            next_collect_time =
                os.time(
                {
                    year = daily_last_collect_date.year,
                    month = daily_last_collect_date.month,
                    day = daily_last_collect_date.day + 1,
                    hour = 3,
                    min = 0,
                    sec = 0
                }
            )
        end

        local acc_seconds = next_collect_time - current_time

        if not os.same_day(player.character.last_collect_reset_time, current_time) then
            player.character.last_collect_reset_time = current_time
            player.character.collect_times = 0
        end

        local chip_get = 0

        if (is_ad == 0 and acc_seconds > 0) then
            --response.ret = Return.LOBBYBONUS_CANNOT_COLLECT()
            --return response
            return -1
        end

        ---------每天只能领取#CollectTimesConfig次
        if (player.character.collect_times > #CollectTimesConfig) then
            return -1
        end

        player.character.collect_times = player.character.collect_times + 1

        local extra_chip = 0

        local extra_times_percent = 0
        -- if (player.character.collect_times <= #CollectTimesConfig) then
        --     extra_times_percent = CollectTimesConfig[player.character.collect_times].extra
        -- end

        ------------------根据等级领取奖励---------------

        local level = player.character.level
        local sel_lv = 0
        for lv, award_value in pairs(CollectTimesConfig[player.character.collect_times].level_award) do
            if (lv <= level) then
                if (sel_lv < lv) then
                    sel_lv = lv
                end
            end
        end
        chip_get = CollectTimesConfig[player.character.collect_times].level_award[sel_lv]

        -- VIP的额外加成
        local vip = player.character.vip
        local extra_percent = VIPConfig[vip].lobby_bonus
        extra_chip = chip_get * extra_percent

        local extra_times_chip = chip_get * extra_times_percent
        extra_times_chip = 0

        total_chip = chip_get + extra_chip + extra_times_chip

        player.character.last_collect_time = os.time()
        player.notice.check_lobby_bonus = 0

        Spark:LobbyBonus(
            player,
            {
                [1] = chip_get,
                [2] = extra_chip,
                [3] = total_chip
            }
        )

        local task_req_data = {
            lobby_bonus = true
        }
        DailyTask:CompleteTask(session, player, task_req_data)

        return 0, total_chip
    end,
    ResetBonusAward = function(player)
        if (string.find(player.statistics.bonus_award, "null")) then
            player.statistics.bonus_award = "[]"
        end
        local bonus_award = json.decode(player.statistics.bonus_award)

        local num_info = {}

        for k, v in pairs(bonus_award) do
            if (num_info[k] == nil) then
                num_info[k] = v
            else
                num_info[k] = num_info[k] + v
            end
        end
        bonus_award = num_info
        player.statistics.bonus_award = json.encode(bonus_award)
    end,
    CalBonusAward = function(player, number)
        if (not number) then
            return
        end
        if (number <= 0) then
            return
        end
        LOG(RUN, INFO).Format("CalBonusAward is: %s", player.statistics.bonus_award)
        local bonus_award = json.decode(player.statistics.bonus_award)

        local is_exist = false
        number = math.floor(number + 0.5)
        for k, v in pairs(bonus_award) do
            if (k == number) then
                bonus_award[k] = bonus_award[k] + 1
                is_exist = true
                break
            end
        end
        if (not is_exist) then
            bonus_award[number] = 1
        end
        player.statistics.bonus_award = json.encode(bonus_award)
    end,
    SetLoopNum = function(player_id, loop_num)
        --LOG(RUN, INFO).Format("set loop num is: %s", loop_num)
        if (GlobalSlotsTest[player_id] ~= nil) then
            GlobalSlotsTest[player_id].loopNum = loop_num
        end
    end,
    SlotsTestUpdate = function(player_id)
        local task = Task:Current()
        local local_player_id = player_id

        local key = SlotsTest .. "[" .. player_id .. "]"
        local redis_request = {
            [1] = string.format("HSET %s response %s", key, GlobalSlotsTest.response)
        }

        --LOG(RUN, INFO).Format("[UpdateFriendBrief] HSET SlotsTest: %s", Table2Str(redis_request))
        local redis_response = LuaSession:ContactJson("CacheClientService", task, redis_request, player_id)
    end,
    GetSubSequence = function(player_id, column)
        local sequence = nil
        if (GlobalSlotsTest[player_id].loopNum == 0) then
            sequence = GlobalSlotsTest[player_id].result[column]
        elseif (GlobalSlotsTest[player_id].loopNum == 1) then
            sequence = GlobalSlotsTest[player_id].autoResult1[column]
        elseif (GlobalSlotsTest[player_id].loopNum == 2) then
            sequence = GlobalSlotsTest[player_id].autoResult2[column]
        elseif (GlobalSlotsTest[player_id].loopNum == 3) then
            sequence = GlobalSlotsTest[player_id].autoResult3[column]
        elseif (GlobalSlotsTest[player_id].loopNum == 4) then
            sequence = GlobalSlotsTest[player_id].autoResult4[column]
        elseif (GlobalSlotsTest[player_id].loopNum == 5) then
            sequence = GlobalSlotsTest[player_id].autoResult5[column]
        elseif (GlobalSlotsTest[player_id].loopNum == 6) then
            sequence = GlobalSlotsTest[player_id].autoResult6[column]
        elseif (GlobalSlotsTest[player_id].loopNum == 7) then
            sequence = GlobalSlotsTest[player_id].autoResult7[column]
        elseif (GlobalSlotsTest[player_id].loopNum == 8) then
            sequence = GlobalSlotsTest[player_id].autoResult8[column]
        end
        return sequence
    end,
    GetSequence = function(player_id, column)
        local sequence = nil
        local sequence_len = 0
        local index = 0

        sequence = CommonCal.Calculate.GetSubSequence(player_id, column)

        sequence_len = #sequence
        index = 1

        return sequence, sequence_len, index
    end,
    BeginStart = function(session, task, player)
        local game_type = player.game_type
        local game_room_config = GameRoomConfig[game_type]
        if (game_room_config == nil) then
            return
        end
        LOG(RUN, INFO).Format("%s begin start %s", player.id, game_room_config.game_name)
    end,
    EndStart = function(
        session,
        task,
        player,
        request,
        response,
        player_game_info,
        lineNum,
        chip_cost,
        win_chip,
        is_new_game)
        request.jackpot = (request.jackpot == nil) and true

        local game_type = player.game_type
        local game_room_config = GameRoomConfig[game_type]
        if (game_room_config == nil) then
            return
        end

        LOG(RUN, INFO).Format("%s end start %s", player.id, game_room_config.game_name)

        FeverCardCal.OnGameSpin(session, player, game_type, player_game_info)
        FeverQuestCal.OnGameSpin(session, player, game_type, player_game_info, request, response, chip_cost, win_chip)

        if not is_new_game and (win_chip and win_chip <= 0) then
            -- 老游戏直接在这里判断
            BoosterCal.OnGameSpin(session, chip_cost)
        end

        if (chip_cost > 0) then
            PantherTracksCal.Calculate.UpdatePantherTracks(session, player, request.amount * lineNum)
            SlotsGameCal.Calculate.ObtainPiggyBankAward(player, chip_cost)
        end

        ClimbSlideCal.Calculate.UpdateProcess(session, player, player_game_info.bet_amount * lineNum)
    end,
    --更新竞标赛的玩家信息
    UpdateTournamentPlayerInfo = function(session, _module_id, _player, _cost_chip, _win_chip)
        --条件筛选
        if _player.character.level < tonumber(ConstValue[19].value) or _player.is_fever_quest == 1 then --Tournament没有解锁 或 在fever_quest中,则不处理不处理
            return
        end

        Task:Work(
            function()
                local match_sate = tournament_mem:GetMatchState(_module_id) --游戏比赛正在排名中
                if (match_sate == tournament_redis.ENUM.MATCH_STATE.IN_RANK) then
                    --玩家基本信息初始化
                    local player_id = _player.id
                    local player_base_info = {
                        id = _player.id,
                        user = {
                            nickname = string.encode(_player.user.nickname),
                            avatar = _player.user.avatar
                        },
                        account = {
                            facebook_id = _player.account.facebook_id
                        },
                        game_type = game_type,
                        character = {
                            chip = _player.character.chip,
                            vip = _player.character.vip,
                            level = _player.character.level,
                            experience = _player.character.experience,
                            player_type = _player.character.player_type
                        }
                    }
                    --更新玩家得分值与奖池
                    tournament_redis:AddPlayerWinChipAndChipsInPool(_module_id, player_id, _win_chip, _cost_chip)
                    --更新参与比赛的玩家信息
                    tournament_mem:UpdatePlayerInfoMap(_module_id, player_base_info)
                end
            end
        )
    end,
    --[[****jackpot通用函数 begin****]]
    --初始化jackpot参数
    InitJackpotParam = function(jackpot_param, _jackpot_config)
        --取出变量
        jackpot_param.prize_pool = {} --初始化奖池table
        local prize_pool = jackpot_param.prize_pool --取出奖池的引用

        --奖池赋值
        for prize_type, jackpot_prize_config in pairs(_jackpot_config) do
            prize_pool[prize_type] = {
                start_point = jackpot_prize_config.start_point,
                extra_chip = 0,
                is_point_amount = false,
                total_amount = 0
            }
        end
    end,
    --增加jackpot的额外筹码值
    AddJackpotExtraChip = function(_jackpot_param, _total_amount, _jackpot_config)
        local prize_pool = _jackpot_param.prize_pool
        for prize_type, jackpot_info in pairs(prize_pool) do
            jackpot_info.extra_chip =
                math.floor(jackpot_info.extra_chip + _total_amount * _jackpot_config[prize_type].bet_to_chip_percent)
        end
    end,
    --重置奖池中jackpot的额外筹码值
    ResetJackpotExtraChip = function(_jackpot_param, _jackpot_type)
        _jackpot_param.prize_pool[_jackpot_type].extra_chip = 0
    end,
    --获取Jackpot奖池的筹码值
    GetJackpotPoolChipVal = function(_jackpot_param, _jackpot_type, _total_amount)
        --初始化返回值
        local chip_val = 0

        --根据jackpot奖池的信息来判断
        local jackpot_info = _jackpot_param.prize_pool[_jackpot_type]
        local total_amount = jackpot_info.is_point_amount and jackpot_info.total_amount or _total_amount --金额值
        chip_val = math.floor(jackpot_info.start_point * total_amount + jackpot_info.extra_chip)

        --返回
        return chip_val
    end,
    --获取客户端的jackpot参数
    GetJakcpotParamToClient = function(_jackpot_param)
        --初始化返回值
        local jackpot_param_cliect = {prize_pool = {}}

        --处理返回值
        for jackpot_type, jackpot_prize_server in pairs(_jackpot_param.prize_pool) do
            --初始化返回给客户端的jackpot信息
            local jackpot_prize_clinet = {}
            -- jackpot_prize_clinet.start_point = jackpot_prize_server.start_point * 10000 --点数（点数进行放大）
            jackpot_prize_clinet.extra_chip = jackpot_prize_server.extra_chip --额外筹码
            if jackpot_prize_server.is_point_amount then --指定金额时，需要发送金额
                jackpot_prize_clinet.is_point_amount = true
                jackpot_prize_clinet.total_amount = jackpot_prize_server.total_amount
            end
            --插入返回的表中
            jackpot_param_cliect.prize_pool[jackpot_type] = jackpot_prize_clinet
        end

        --返回
        return jackpot_param_cliect
    end
    --[[----jackpot通用函数 end------]]
}
