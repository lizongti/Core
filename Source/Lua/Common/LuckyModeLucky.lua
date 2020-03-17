module("LuckyModeLucky", package.seeall)

local LuckyModeLuckyObject = {}

function LuckyModeLuckyObject:OnBaseSpinStart(session, spin_context)
    
end

function LuckyModeLuckyObject:OnBaseSpinEnd(session, spin_context)
    local player = session.player
    local win_chip = spin_context.win_chip
    local chip_cost = spin_context.chip_cost
    LuckyCal.AddLuckyCredit(player, win_chip - chip_cost)

    -- 超出了lucky值
    if player.character.lucky_credit_change >= player.character.lucky then
        local delta = player.character.lucky_credit_change - player.character.lucky
        player.character.unlucky = player.character.unlucky + delta
        -- 清空lucky
        player.character.lucky = 0
    else
        local is_lucky = LuckyCal.IsLucky(player, chip_cost)
        if not is_lucky then
            player.character.lucky = 0
        end
    end
end

function Create(self)
    local obj = {}
    setmetatable(obj, {__index = LuckyModeLuckyObject})
    return obj
end
