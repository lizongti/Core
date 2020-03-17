---------------------
--  Player Watcher --
---------------------
require "Common/Return"
require "Common/FrdCal"
require "Common/CommonCal"
require "Config/system/ConstValue"

module("PlayerWatcher", package.seeall)

Register = function(_M, session, request)
    local response = {
        header = {
            router = "AsyncResponse",
            client_id = session.client_id,
            task_id = request.header.task_id
        }
    }
    PlayerWatcherContainer.default_client_id = session.client_id
    local player = PlayerWatcherContainer.players[request.player_id]
    if player then -- has old data
        player.expire = os.time() + 300

        if player.dropping_time == 0 then -- not dropping
            session:WriteRouterPacket(
                {
                    header = {
                        router = "Command",
                        client_id = player.client_id,
                        module_id = "Command",
                        message_id = "Command_Drop_Request"
                    },
                    session_id = player.session_id,
                    player_id = player.player_id
                }
            )

            player.dropping_time = os.time()

            PlayerWatcherContainer.players[request.player_id] = nil
        end
    end

    player = PlayerWatcherContainer.players[request.player_id]
    if not player then
        PlayerWatcherContainer.players[request.player_id] = {
            client_id = session.client_id,
            session_id = request.session_id,
            player_id = request.player_id,
            dropping_time = 0,
            expire = os.time() + 300,
            player_type = request.player_type
        }
    end

    local is_drop = player and (player.dropping_time > 0 and true or false) or false
    if (is_drop) then
        response.dropping = 0
    else
        response.dropping = 1
    end
    response.ret = Return.OK()

    LOG(RUN, INFO).Format(
        "[PlayerWatcher][Register] player is %s, dropping is:%s",
        request.player_id,
        response.dropping
    )
    return response
end

Deregister = function(_M, session, request)
    local response = {
        header = {
            router = "AsyncResponse",
            client_id = session.client_id,
            task_id = request.header.task_id
        }
    }

    PlayerWatcherContainer.players[request.player_id] = nil

    LOG(RUN, INFO).Format(
        "[PlayerWatcher][Deregister] end dropping old, by stop connection, player_id:%s",
        request.player_id
    )

    response.ret = Return.OK()

    return response
end

HeartBeat = function(_M, session, request)
    local response = {
        header = {
            router = "AsyncResponse",
            client_id = session.client_id,
            task_id = request.header.task_id
        }
    }
    local current_time = os.time()
    local player = PlayerWatcherContainer.players[request.player_id]
    if player then
        -- LOG(RUN, INFO).Format("[PlayerWatcher][HeartBeat] add expire succussfully, player_id:%s", request.player_id)
        player.expire = current_time + 300
    else
        -- LOG(RUN, INFO).Format("[PlayerWatcher][HeartBeat] add expire failed, player_id:%s", request.player_id)
    end
    response.ret = Return.OK()

    return response
end

SetBackground = function(_M, session, request)
    response.ret = Return.OK()
    return response
end

CheckActive = function(_M, session, request)
    for player_id, player in pairs(PlayerWatcherContainer.players) do
        if (player.player_type ~= tonumber(ConstValue[5].value)) then
            if player.expire < os.time() then
                session:WriteRouterPacket(
                    {
                        header = {
                            router = "Command",
                            client_id = player.client_id,
                            module_id = "Command",
                            message_id = "Command_Expire_Request"
                        },
                        session_id = player.session_id,
                        player_id = player.player_id
                    }
                )
            end
        end
    end
end

CheckMaintenance = function(_M, session, request)
    if GlobalState:Get("Maintenance.DropAccount") == 1 then
        for player_id, player in pairs(PlayerWatcherContainer.players) do
            if (player.player_type ~= tonumber(ConstValue[5].value)) then
                local is_test_id = GlobalState:CheckTestID(tostring(player_id))

                if is_test_id == 0 then
                    session:WriteRouterPacket(
                        {
                            header = {
                                router = "Command",
                                client_id = player.client_id,
                                module_id = "Command",
                                message_id = "Command_Drop_Request"
                            },
                            session_id = player.session_id,
                            player_id = player_id
                        }
                    )
                end
            end
        end
    end
end

GetAttachments = function(_M, session, request)
    local player_id = request.player_id
    local player = PlayerWatcherContainer.players[request.player_id]
    local props = json.decode(request.props)
    local old_player_id = request.old_player_id
    for k, v in pairs(props) do
        table.insert(v, old_player_id)
    end
    props = json.encode(props)

    if not player then
        session:ReadRouterPacket(
            {
                header = {
                    router = "LocalRequest",
                    service_name = "ManagerClientService",
                    module_id = "Mail",
                    message_id = "Mail_AutoFetch_Request"
                },
                player_id = player_id,
                props = props
            }
        )

        return
    end

    session:WriteRouterPacket(
        {
            header = {
                router = "Command",
                client_id = player.client_id,
                module_id = "Command",
                message_id = "Command_GetAttachments_Request"
            },
            player_id = player_id,
            session_id = player.session_id,
            props = props
        }
    )
end

-- manager进程的购买逻辑
GetGoods = function(_M, session, request)
    local content = request.content
    local data = json.decode(content)

    local player_id = data.player_id
    local goods_id = data.goods_id
    local old_player_id = data.old_player_id

    local prop_list = {{goods_id, 1}}

    if (old_player_id ~= nil) then
        prop_list = {{goods_id, 1, old_player_id}}
    end

    local props = json.encode(prop_list)
    local player = PlayerWatcherContainer.players[player_id]

    LOG(RUN, INFO).Format(
        "[PlayerWatcher][GetGoods] get goods from drive, player_id:%s, request is::%s",
        player_id,
        Table2Str(request)
    )

    if not player then
        -- 玩家不存在的情况
        local cur_shop_config = CommonCal.Calculate.get_config(nil, "ShopConfig")
        goods_id = tonumber(goods_id)
        local goods_conf = cur_shop_config[goods_id]

        -- PaymentCal.Calculate.AsyncAddPayment(player_id, prop_list)
        session:ReadRouterPacket(
            {
                header = {
                    router = "LocalRequest",
                    service_name = "ManagerClientService",
                    module_id = "Mail",
                    message_id = "Mail_AutoFetch_Request"
                },
                player_id = player_id,
                props = props
            }
        )
        LOG(RUN, INFO).Format(
            "[PlayerWatcher][GetGoods] cannot find player, send attachment to mail, player_id:%s, props:%s",
            player_id,
            props
        )
        return
    end

    -- 玩家存在的情况，发送消息给dispatcher
    session:WriteRouterPacket(
        {
            header = {
                router = "Command",
                client_id = player.client_id,
                module_id = "Command",
                message_id = "Command_GetGoods_Request"
            },
            session_id = player.session_id,
            content = content
        }
    )
    LOG(RUN, INFO).Format("[PlayerWatcher][GetGoods] get goods from mail, player_id:%s, props:%s", player_id, props)
end

OptLog = function(_M, session, request)
    local player_id = request.player_id
    local category = request.category
    local data = request.data
    local player = PlayerWatcherContainer.players[request.player_id]
    if player then
        session:WriteRouterPacket(
            {
                header = {
                    router = "Command",
                    client_id = player.client_id,
                    module_id = "Command",
                    message_id = "Command_OptLog_Request"
                },
                player_id = player_id,
                session_id = player.session_id,
                category = category,
                data = data
            }
        )
    else
        local data_list = json.decode(data)
        if (category == "FinishPayment") then
            local goods_id = tonumber(data_list[5])
            local channel_type = data_list[7]

            local cur_shop_config = CommonCal.Calculate.get_config(player, "ShopConfig")

            local goods_conf = cur_shop_config[goods_id]
            table.insert(data_list, goods_conf.desc)
            table.insert(data_list, "")
        end

        Spark[category](Operative, player, data_list)
    end
end

Push = function(_M, session, request)
    local channel = Channel:Get(request.channel_name)
    local channel_id = channel:Id()
    if request.method == "chat" then
        session:WriteRouterPacket(
            {
                header = {
                    router = "AsyncBroadcast",
                    client_id = PlayerWatcherContainer.default_client_id,
                    service_name = "ManagerService",
                    channel_id = channel_id,
                    module_id = "Communication",
                    message_id = "Communication_Chat_Notice"
                },
                type = channel.type,
                content = request.content
            }
        )
    elseif request.method == "toast" then
        session:WriteRouterPacket(
            {
                header = {
                    router = "AsyncBroadcast",
                    client_id = PlayerWatcherContainer.default_client_id,
                    service_name = "ManagerService",
                    channel_id = channel_id,
                    module_id = "PopUp",
                    message_id = "PopUp_Toast_Notice"
                },
                type = channel.type,
                content = request.content
            }
        )
    end
end

-- drop player when ban
DropBanned = function(_M, session, request)
    local player_id_list = request.player_id_list
    for _, player_id in ipairs(player_id_list) do
        local player = PlayerWatcherContainer.players[player_id]
        if player then
            if (player.player_type ~= tonumber(ConstValue[5].value)) then
                session:WriteRouterPacket(
                    {
                        header = {
                            router = "Command",
                            client_id = player.client_id,
                            module_id = "Command",
                            message_id = "Command_Drop_Request"
                        },
                        player_id = player_id,
                        session_id = player.session_id
                    }
                )
            end
        end
    end
end

-- 赠送chips给别的玩家的逻辑,player_id指的是被赠送的玩家的id
SendChips = function(_M, session, request)
    local response = {
        header = {
            router = "AsyncResponse",
            client_id = session.client_id,
            task_id = request.header.task_id
        }
    }

    local player_id_list = request.to_player_id
    local chip_count = request.chip_count
    for _, player_id in ipairs(player_id_list) do
        local player = PlayerWatcherContainer.players[player_id]
        local props = json.encode({[1] = {1000, chip_count}})
        if not player then
            session:ReadRouterPacket(
                {
                    header = {
                        router = "LocalRequest",
                        service_name = "ManagerClientService",
                        module_id = "Mail",
                        message_id = "Mail_SendChips_Request"
                    },
                    player_id = player_id,
                    props = props,
                    sender = request.sender
                }
            )
        end

        if player then
            session:WriteRouterPacket(
                {
                    header = {
                        router = "Command",
                        client_id = player.client_id,
                        module_id = "Command",
                        message_id = "Command_GetSendChips_Request"
                    },
                    sender = request.sender,
                    session_id = player.session_id,
                    chip_count = chip_count,
                    player_id = player_id
                }
            )
        end
    end

    response.ret = Return.OK()
    return response
end

Hotfix = function(_M, session, request)
    local response = {
        header = {
            router = "AsyncResponse",
            client_id = session.client_id,
            task_id = request.header.task_id
        }
    }

    local process_name = request.process_name
    local module_path = request.module_path
    local module_name = request.module_name

    if process_name == "Manager" then
        for i = 1, #module_name do
            local path = module_path[i]
            local name = module_name[i]
            local full_path = string.format("%s/%s", path, name)
            if package.loaded[full_path] then
                package.loaded[full_path] = nil
                -- _G[name] = nil
                require(full_path)
            end
        end
    elseif process_name == "Dispatcher" or string.find(process_name, "Contest") then
        for client_id = 0, Base.Enviroment.client_count - 1, 1 do
            session:WriteRouterPacket(
                {
                    header = {
                        router = "Command",
                        client_id = client_id,
                        module_id = "Command",
                        message_id = "Command_Hotfix_Request"
                    },
                    process_name = request.process_name,
                    module_path = request.module_path,
                    module_name = request.module_name
                }
            )
        end
    end

    response.ret = Return.OK()
    return response
end

ClubKickOut = function(_M, session, request)
    local response = {
        header = {
            router = "AsyncResponse",
            client_id = session.client_id,
            task_id = request.header.task_id
        }
    }

    local player_id = request.player_id
    local player = PlayerWatcherContainer.players[player_id]
    if player then
        session:WriteRouterPacket(
            {
                header = {
                    router = "Command",
                    client_id = player.client_id,
                    module_id = "Command",
                    message_id = "Command_ClubKickOut_Request"
                },
                session_id = player.session_id,
                player_id = player_id
            }
        )
    end

    response.ret = Return.OK()
    return response
end

ClubApprove = function(_M, session, request)
    local response = {
        header = {
            router = "AsyncResponse",
            client_id = session.client_id,
            task_id = request.header.task_id
        }
    }

    local club_id = request.club_id
    local player_id = request.player_id
    local player = PlayerWatcherContainer.players[player_id]
    if player then
        session:WriteRouterPacket(
            {
                header = {
                    router = "Command",
                    client_id = player.client_id,
                    module_id = "Command",
                    message_id = "Command_ClubApprove_Request"
                },
                session_id = player.session_id,
                player_id = player_id,
                club_id = club_id
            }
        )
    end

    response.ret = Return.OK()
    return response
end

ClubReject = function(_M, session, request)
    local response = {
        header = {
            router = "AsyncResponse",
            client_id = session.client_id,
            task_id = request.header.task_id
        }
    }

    local club_name = request.club_name
    local player_id = request.player_id
    local player = PlayerWatcherContainer.players[player_id]
    if player then
        session:WriteRouterPacket(
            {
                header = {
                    router = "Command",
                    client_id = player.client_id,
                    module_id = "Command",
                    message_id = "Command_ClubReject_Request"
                },
                session_id = player.session_id,
                player_id = player_id,
                club_name = club_name
            }
        )
    end

    response.ret = Return.OK()
    return response
end

ClubPromote = function(_M, session, request)
    local response = {
        header = {
            router = "AsyncResponse",
            client_id = session.client_id,
            task_id = request.header.task_id
        }
    }

    local player_id = request.player_id
    local new_identity = request.new_identity
    local player = PlayerWatcherContainer.players[player_id]
    if player then
        session:WriteRouterPacket(
            {
                header = {
                    router = "Command",
                    client_id = player.client_id,
                    module_id = "Command",
                    message_id = "Command_ClubPromote_Request"
                },
                session_id = player.session_id,
                player_id = player_id,
                new_identity = new_identity
            }
        )
    end

    response.ret = Return.OK()
    return response
end

ClubDemote = function(_M, session, request)
    local response = {
        header = {
            router = "AsyncResponse",
            client_id = session.client_id,
            task_id = request.header.task_id
        }
    }

    response.ret = Return.OK()
    return response
end

-- facebook or googleplay be replaced by others, send notice
Replaced = function(_M, session, request)
    local response = {
        header = {
            router = "AsyncResponse",
            client_id = session.client_id,
            task_id = request.header.task_id
        }
    }

    local player_id = request.player_id
    local player = PlayerWatcherContainer.players[player_id]
    if player then
        session:WriteRouterPacket(
            {
                header = {
                    router = "Command",
                    client_id = player.client_id,
                    module_id = "Command",
                    message_id = "Command_Replaced_Request"
                },
                session_id = player.session_id,
                player_id = player_id,
                type = request.type
            }
        )
    end

    response.ret = Return.OK()
    return response
end

-- first time bind facebook, send bonus to player
BindFacebook = function(_M, session, request)
    local response = {
        header = {
            router = "AsyncResponse",
            client_id = session.client_id,
            task_id = request.header.task_id
        }
    }

    local player_id = request.player_id
    local player = PlayerWatcherContainer.players[player_id]

    if not player then
        local props = json.encode({[1] = {1000, tonumber(ConstValue[22].value)}}) ----------绑定奖励---------------
        session:ReadRouterPacket(
            {
                header = {
                    router = "LocalRequest",
                    service_name = "ManagerClientService",
                    module_id = "Mail",
                    message_id = "Mail_BindFacebook_Request"
                },
                player_id = player_id,
                props = props
            }
        )
        return
    end

    if player then
        session:WriteRouterPacket(
            {
                header = {
                    router = "Command",
                    client_id = player.client_id,
                    module_id = "Command",
                    message_id = "Command_BindFacebook_Request"
                },
                session_id = player.session_id,
                player_id = player_id
            }
        )
    end

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

    -- local player_id = tonumber(request.player_id)
    -- -- LOG(RUN, INFO).Format("[PlayerWatcher][VersionAward] Request is:%s", Table2Str(request))

    -- local props = json.encode({[1] = {1000, 100000}})
    -- session:ReadRouterPacket({
    --     header = {
    --         router = "LocalRequest",
    --         service_name = "ManagerClientService",
    --         module_id = "Mail",
    --         message_id = "Mail_VersionAward_Request",
    --     },
    -- player_id = player_id,
    --     props = props,
    -- })
    return
end

Gm = function(_M, session, request)
    local response = {
        header = {
            router = "AsyncResponse",
            client_id = session.client_id,
            task_id = request.header.task_id
        }
    }

    LOG(RUN, INFO).Format("[PlayerWatcher][Gm] Request is:%s", Table2Str(request))
    local content = json.decode(request.content)

    local player_id = tonumber(content.PlayerID)
    local player = PlayerWatcherContainer.players[player_id]
    if (not player) then
        return response
    end

    session:WriteRouterPacket(
        {
            header = {
                router = "Command",
                client_id = player.client_id,
                module_id = "Command",
                message_id = "Command_Gm_Request"
            },
            player_id = player_id,
            session_id = player.session_id,
            content = request.Content
        }
    )
    return
end

ResetPotInfo = function(_M, session, request)
    local response = {
        header = {
            router = "AsyncResponse",
            client_id = session.client_id,
            task_id = request.header.task_id
        }
    }
    response.ret = Return.OK()

    return response
end

OnlineFrdList = function(_M, session, request)
    local response = {
        header = {
            router = "AsyncResponse",
            client_id = session.client_id,
            task_id = request.header.task_id
        }
    }

    local friend_list = request.friend_list
    -- LOG(RUN, INFO).Format("[PlayerWatcher][OnlineFrdList] request is: %s", Table2Str(request))
    local online_friend_list = {}
    for k, v in ipairs(friend_list) do
        local player_id = v.id
        local friend = PlayerWatcherContainer.players[player_id]
        if (friend) then
            table.insert(online_friend_list, v)
        end
    end

    response.friend_list = online_friend_list
    response.ret = Return.OK()
    -- LOG(RUN, INFO).Format("[PlayerWatcher][OnlineFrdList] response is: %s", Table2Str(response))
    return response
end

IdentifyFrd = function(_M, session, request)
    local response = {
        header = {
            router = "AsyncResponse",
            client_id = session.client_id,
            task_id = request.header.task_id
        }
    }
    -- LOG(RUN, INFO).Format("[PlayerWatcher][IdentifyFrd]request is: %s", Table2Str(request))
    local friend_list = request.friend_list

    local online_friend_list = {}
    local offline_friend_list = {}
    for k, v in pairs(friend_list) do
        local value = v
        local friend = PlayerWatcherContainer.players[value.id]
        if (friend) then
            table.insert(online_friend_list, value)
        else
            table.insert(offline_friend_list, value)
        end
    end

    response.online_friend_list = online_friend_list
    response.offline_friend_list = offline_friend_list
    response.ret = Return.OK()

    -- LOG(RUN, INFO).Format("[PlayerWatcher][IdentifyFrd]response is: %s", Table2Str(response))
    return response
end

FrdList = function(_M, session, request)
    local response = {
        header = {
            router = "AsyncResponse",
            client_id = session.client_id,
            task_id = request.header.task_id
        }
    }

    local player_id = request.player_id
    local friend_id = request.friend_id

    -- LOG(RUN, INFO).Format("[PlayerWatcher][FrdList] player %s, request is: %s", player_id, Table2Str(request))

    if (friend_id) then
        local friend = PlayerWatcherContainer.players[friend_id]
        if (friend) then
            session:WriteRouterPacket(
                {
                    header = {
                        router = "Command",
                        client_id = friend.client_id,
                        module_id = "Command",
                        message_id = "Command_FrdList_Request"
                    },
                    session_id = friend.session_id,
                    player_id = friend_id
                }
            )
        end
    end

    if (player_id) then
        local Player = PlayerWatcherContainer.players[player_id]
        if (Player) then
            session:WriteRouterPacket(
                {
                    header = {
                        router = "Command",
                        client_id = Player.client_id,
                        module_id = "Command",
                        message_id = "Command_FrdList_Request"
                    },
                    session_id = Player.session_id,
                    player_id = player_id
                }
            )
        end
    end

    response.ret = Return.OK()
    return response
end

InviteFrd = function(_M, session, request)
    local response = {
        header = {
            router = "AsyncResponse",
            client_id = session.client_id,
            task_id = request.header.task_id
        }
    }

    local player = request.player
    local table_id = request.table_id
    local frd_id_list = request.frd_id_list

    -- LOG(RUN, INFO).Format("[PlayerWatcher][InviteFrd] player %s, request is: %s", player.id, Table2Str(request))
    for k, v in ipairs(frd_id_list) do
        local friend = PlayerWatcherContainer.players[v]
        if (friend) then
            session:WriteRouterPacket(
                {
                    header = {
                        router = "Command",
                        client_id = friend.client_id,
                        module_id = "Command",
                        message_id = "Command_InviteFrd_Request"
                    },
                    session_id = friend.session_id,
                    player_id = v,
                    friend = player,
                    frd_table_id = table_id
                }
            )
        end
    end

    response.ret = Return.OK()
    return response
end

FrdInfo = function(_M, session, request)
    local response = {
        header = {
            router = "AsyncResponse",
            client_id = session.client_id,
            task_id = request.header.task_id
        }
    }
    response.ret = Return.OK()
    return response
end

--------------踢玩家下线---------------------
KickOffInfo = function(_M, session, request)
    local response = {
        header = {
            router = "AsyncResponse",
            client_id = session.client_id,
            task_id = request.header.task_id
        }
    }

    response.ret = Return.OK()

    local player_id = tonumber(request.player_id)

    local player = PlayerWatcherContainer.players[player_id]
    if (not player) then
        LOG(RUN, INFO).Format("[PlayerWatcher][KickOffInfo] player not find")
        return response
    end

    if (player.player_type ~= tonumber(ConstValue[5].value)) then
        session:WriteRouterPacket(
            {
                header = {
                    router = "Command",
                    client_id = player.client_id,
                    module_id = "Command",
                    message_id = "Command_Drop_Request"
                },
                session_id = player.session_id,
                player_id = player_id
            }
        )
    end
    return response
end

BindPlayerInfo = function(_M, session, request)
    local response = {
        header = {
            router = "AsyncResponse",
            client_id = session.client_id,
            task_id = request.header.task_id
        }
    }

    local player_id = tonumber(request.player_id)

    LOG(RUN, INFO).Format("[PlayerWatch][BindPlayerInfo] player id:%s, Request is: %s", player_id, Table2Str(request))
    local platform_head_id = request.platform_head_id
    local nickname = request.nickname
    local action = request.action

    local player = PlayerWatcherContainer.players[player_id]
    if player then
        session:WriteRouterPacket(
            {
                header = {
                    router = "Command",
                    client_id = player.client_id,
                    module_id = "Command",
                    message_id = "Command_BindPlayerInfo_Request"
                },
                session_id = player.session_id,
                player_id = player_id,
                platform_head_id = platform_head_id,
                nickname = nickname,
                action = action
            }
        )
    end

    response.ret = Return.OK()
    return response
end

-- in contest5, fruit slice, when bonus game ended, clear player's trigger times in this table
ClearTriggerTimes = function(_M, session, request)
    local response = {
        header = {
            router = "AsyncResponse",
            client_id = session.client_id,
            task_id = request.header.task_id
        }
    }

    local player_id_list = request.player_id
    if not player_id_list then
        response.ret = Return.OK()
        return response
    end

    for _, player_id in ipairs(player_id_list) do
        local player = PlayerWatcherContainer.players[player_id]
        if player then
            session:WriteRouterPacket(
                {
                    header = {
                        router = "Command",
                        client_id = player.client_id,
                        module_id = "Command",
                        message_id = "Command_ClearTriggerTimes_Request"
                    },
                    session_id = player.session_id,
                    player_id = player_id
                }
            )
        end
    end
    response.ret = Return.OK()
    return response
end

Ping = function(_M, session, request)
    local response = {
        header = {
            router = "AsyncResponse",
            client_id = session.client_id,
            task_id = request.header.task_id
        }
    }

    response.time = system.time()
    response.ret = Return.OK()
    return response
end

PlayerWatcherContainer = {
    default_client_id = 0,
    players = Container:Get("hash_player_watcher_players")
}
