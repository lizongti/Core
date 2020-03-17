module("LuckyModeUnlucky", package.seeall)

LuckyModeUnluckyObject = {}

local function GetUnluckyEndConfig(player, is_absolute_bankrupt, is_relative_bankrutp)
    local configs = CommonCal.Calculate.get_config(player, "UnluckyEndConditionConfig")
    
    local bankruptcy = 0
    if is_absolute_bankrupt then
       bankruptcy = 1 
    elseif is_relative_bankrutp then
        bankruptcy = 0
    else
        return
    end
    
    for i=1, #configs do
        local level = player.character.level
        if level > configs[i].level_min and level < configs[i].level_max and bankruptcy == configs[i].bankruptcy then
            return configs[i]
        end
    end
end

function LuckyModeUnluckyObject:OnBaseSpinStart(session, spin_context)
    
end

function LuckyModeUnluckyObject:OnBaseSpinEnd(session, spin_context)
    local player = session.player
    local win_chip = spin_context.win_chip
    local chip_cost = spin_context.chip_cost
    LuckyCal.AddUnluckyCredit(player, chip_cost - win_chip)

    local is_absolute_bankrupt = false
    local is_relative_bankrutp = false

    if player.character.chip < 10000 then
        is_absolute_bankrupt = true
    elseif chip_cost > player.character.chip then
        is_relative_bankrutp = true
    end

    local end_config = GetUnluckyEndConfig(player, is_absolute_bankrupt, is_relative_bankrutp)
    if end_config then
        player.character.unlucky = 0
    end
end

function Create(self)
    local obj = {}
    setmetatable(obj, {__index = LuckyModeUnluckyObject})
    return obj
end
