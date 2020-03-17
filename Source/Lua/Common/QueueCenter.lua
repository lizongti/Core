module("QueueCenter", package.seeall)

attachment = function(session, request_json)
    LOG(RUN, DEBUG).Format("[ManagerService][Loop] attachment json: %s", request_json)
    local data = json.decode(request_json)
    session:ReadRouterPacket(
        {
            header = {
                router = "AsyncRequest",
                service_name = "ManagerClientService",
                module_id = "PlayerWatcher",
                message_id = "PlayerWatcher_GetAttachments_Request"
            },
            player_id = data.player_id,
            props = json.encode(data.attachments),
            old_player_id = data.old_player_id
        }
    )
end

goods = function(session, request_json)
    LOG(RUN, INFO).Format("[ManagerService][Loop] goods json: %s", request_json)
    session:ReadRouterPacket(
        {
            header = {
                router = "AsyncRequest",
                service_name = "ManagerClientService",
                module_id = "PlayerWatcher",
                message_id = "PlayerWatcher_GetGoods_Request"
            },
            content = request_json
        }
    )
end

opt = function(session, request_json)
    LOG(RUN, DEBUG).Format("[ManagerService][Loop] opt json: %s", request_json)
    local data = json.decode(request_json)
    session:ReadRouterPacket(
        {
            header = {
                router = "AsyncRequest",
                service_name = "ManagerClientService",
                module_id = "PlayerWatcher",
                message_id = "PlayerWatcher_OptLog_Request"
            },
            player_id = data.player_id,
            category = data.category,
            data = json.encode(data.data)
        }
    )
end

push = function(session, request_json)
    LOG(RUN, DEBUG).Format("[ManagerService][Loop] push json: %s", request_json)
    local data = json.decode(request_json)
    session:ReadRouterPacket(
        {
            header = {
                router = "AsyncRequest",
                service_name = "ManagerClientService",
                module_id = "PlayerWatcher",
                message_id = "PlayerWatcher_Push_Request"
            },
            method = data.method,
            channel_name = data.type,
            content = data.content
        }
    )
end

banplayer = function(session, request_json)
    LOG(RUN, DEBUG).Format("[ManagerService][Loop] banplayer json: %s", request_json)
    local data = json.decode(request_json)
    session:ReadRouterPacket(
        {
            header = {
                router = "AsyncRequest",
                service_name = "ManagerClientService",
                module_id = "PlayerWatcher",
                message_id = "PlayerWatcher_DropBanned_Request"
            },
            player_id_list = data
        }
    )
end

hotfix = function(session, request_json)
    LOG(RUN, DEBUG).Format("[ManagerService][Loop] hotfix json: %s", request_json)
    local data = json.decode(request_json)
    session:ReadRouterPacket(
        {
            header = {
                router = "AsyncRequest",
                service_name = "ManagerClientService",
                module_id = "PlayerWatcher",
                message_id = "PlayerWatcher_Hotfix_Request"
            },
            process_name = data.process_name,
            module_path = data.module_path,
            module_name = data.module_name
        }
    )
end

replacenotice = function(session, request_json)
    LOG(RUN, DEBUG).Format("[ManagerService][Loop] replace notice json: %s", request_json)
    local data = json.decode(request_json)
    session:ReadRouterPacket(
        {
            header = {
                router = "AsyncRequest",
                service_name = "ManagerClientService",
                module_id = "PlayerWatcher",
                message_id = "PlayerWatcher_Replaced_Request"
            },
            player_id = data.player_id,
            type = data.type
        }
    )
end

bindprize = function(session, request_json)
    LOG(RUN, DEBUG).Format("[ManagerService][Loop] bind facebook prize json: %s", request_json)
    local data = json.decode(request_json)
    session:ReadRouterPacket(
        {
            header = {
                router = "AsyncRequest",
                service_name = "ManagerClientService",
                module_id = "PlayerWatcher",
                message_id = "PlayerWatcher_BindFacebook_Request"
            },
            player_id = data.player_id
        }
    )
end

bindplayerinfo = function(session, request_json)
    LOG(RUN, INFO).Format("[ManagerService][Loop] BindPlayerInfo json: %s", request_json)
    local data = json.decode(request_json)
    session:ReadRouterPacket(
        {
            header = {
                router = "AsyncRequest",
                service_name = "ManagerClientService",
                module_id = "PlayerWatcher",
                message_id = "PlayerWatcher_BindPlayerInfo_Request"
            },
            player_id = data.player_id,
            platform_head_id = data.platform_head_id,
            nickname = data.nickname,
            action = data.action
        }
    )
end

version_award = function(session, request_json)
    LOG(RUN, DEBUG).Format("[ManagerService][Loop] version award json: %s", request_json)
    local data = json.decode(request_json)
    session:ReadRouterPacket(
        {
            header = {
                router = "AsyncRequest",
                service_name = "ManagerClientService",
                module_id = "PlayerWatcher",
                message_id = "PlayerWatcher_VersionAward_Request"
            },
            player_id = data.player_id
        }
    )
end

customer_service = function(session, request_json)
    LOG(RUN, DEBUG).Format("[ManagerService][Loop] Customer Service json: %s", request_json)
    local data = json.decode(request_json)
    session:ReadRouterPacket(
        {
            header = {
                router = "AsyncRequest",
                service_name = "ManagerClientService",
                module_id = "CustomerServicePasser",
                message_id = "CustomerServicePasser_StaffSay_Request"
            },
            player_id = data.player_id,
            item = {
                timestamp = data.timestamp,
                index = data.id,
                type = data.type,
                content = data.content
            }
        }
    )
end

kickoffinfo = function(session, request_json)
    LOG(RUN, INFO).Format("[ManagerService][Loop] Kick Off json: %s", request_json)
    local data = json.decode(request_json)
    session:ReadRouterPacket(
        {
            header = {
                router = "AsyncRequest",
                service_name = "ManagerClientService",
                module_id = "PlayerWatcher",
                message_id = "PlayerWatcher_KickOffInfo_Request"
            },
            player_id = data.player_id
        }
    )
end

gm = function(session, request_json)
    LOG(RUN, INFO).Format("[ManagerService][Loop] gm json: %s", request_json)
    session:ReadRouterPacket(
        {
            header = {
                router = "AsyncRequest",
                service_name = "ManagerClientService",
                module_id = "PlayerWatcher",
                message_id = "PlayerWatcher_Gm_Request"
            },
            content = request_json
        }
    )
end

broadcast = function(session, request_json)
    local request_data = json.decode(request_json)
    if request_data.header.time and os.time() - request_data.header.time < 60 then
        request_data.header.router = "Broadcast"
        session:ReadRouterPacket(request_data)
        LOG(RUN, INFO).Format("[ManagerService][Loop] broadcast json: %s", request_json)
    else
        LOG(RUN, INFO).Format("[ManagerService][Loop] overtime bandon, broadcast json: %s", request_json)
    end
end
