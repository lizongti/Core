------------------------
-- Prop PropOperation --
------------------------
_G.PropOperation = {}
require "Config/ServerConfig"


PropOperation.special_props = 
{
	["Chip"] = {
		Count = function(self, player)
			return player.character.chip
		end,
		Has = function(self, player, item, reason)
			if player.character.chip < item[2] then
			return false
			end
			return true    
		end,
		Obtain = function(self, player, item, reason)
			local origin = player.character.chip
			player.character.chip = player.character.chip + item[2]
            player.character.chip = math.max(player.character.chip, 0)
			RankHelper:ChallengeChip(player, origin)

			if (#item < 3) then
				-- opt
				LOG(RUN, INFO).Format("[PropOperation][Obtain] %s 变化量 %s", reason, item[2])

				Spark:ChangeProp(player, {
					[1] = "Chip",
					[2] = origin,
					[3] = player.character.chip,
					[4] = item[2],
					[5] = reason,
					[6] = system.time(),
					[7] = "",
				})
			else

				Spark:ChangeProp(player, {
					[1] = "Chip",
					[2] = origin,
					[3] = player.character.chip,
					[4] = item[2],
					[5] = reason,
					[6] = system.time(),
					[7] = item[3],
				})				
			end

			return true
		end,
		Consume = function(self, player, item, reason)
			local origin = player.character.chip
			if player.character.chip < item[2] then
				return false
			end
			player.character.chip = player.character.chip - item[2]
            player.character.chip = math.max(player.character.chip, 0)
			RankHelper:ChallengeChip(player, origin)
			
			-- opt


			Spark:ChangeProp(player, {
				[1] = "Chip",
				[2] = origin,
				[3] = player.character.chip,
				[4] = -1 * item[2],
				[5] = reason,
				[6] = system.time(),
				[7] = "",
			})
			return true
		end
	},
}

function PropOperation:Init()
	for index, item in pairs(self.special_props) do
		setmetatable(item, {
			__index = self
		})
	end
end
PropOperation:Init()

-- local prop_name_to_id = {
-- 	Chip = 1000,
-- 	Diamond = 1001,
-- }

--item[1]是道具名称(Chip, Diamond),item[2]是数量
function PropOperation:Type(item)
    local name
    if type(item[1]) == "number" then
        name = SlotsPropConfig[item[1]].name
    elseif type(item[1]) == "string" then
        name = item[1]
    end

	if self.special_props[name] then
		return self.special_props[name]
	else
		return self
	end
end
