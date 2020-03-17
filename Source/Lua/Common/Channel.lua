--------------
--  Channel --
--------------
require "Base/Path"
require "Config/system/GameRoomConfig"


_G.Channel = {}
Channel.objects = {}

Channel.register = {
    {
        type = 1,
        name = "Hall",
        Id = function(self, player, session, task)
            return "Hall"
        end,
    },
    {
        type = 2,
        name = "SystemInfo",
        Id = function(self, player, session, task)
            return "Global"
        end,
    },
    {
        type = 3,
        name = "Club",
        Id = function ( self, player, session, task)
            return string.format("Slots.Club.%s", player.club_info.club_id)
        end
    },
}

function Channel:Init()
    for k, v in pairs(GameRoomConfig) do
        local item = {
            type = v.game_type,
            name = v.game_name,
            Id = function ( self, player, session, task)
                return CommonCal.Calculate.get_game_info(session, task, player, v.game_type).channel_id
            end,
        }
        table.insert(self.register, item)
    end

    for _, v in pairs(self.register) do
        self.objects[v.type] = v
        self.objects[v.name] = v
    end
end

function Channel:Get(index)
    return self.objects[index]
end

function Channel:Id(index, player)
    if not self.objects[index] then
        return false
    end
    return self.objects[index].Id(player)
end

function Channel:Name(index)
    if not self.objects[index] then
        return ""
    end
    return self.objects[index].name
end

function Channel:Type(index)
    if not self.objects[index] then
        return 0
    end
    return self.objects[index].type
end

Channel:Init()
