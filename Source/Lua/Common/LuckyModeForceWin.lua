module("LuckyModeForceWin", package.seeall)

LuckyModeForceWinObject = {}

function LuckyModeForceWinObject:OnBaseSpinStart()
    
end

function LuckyModeForceWinObject:OnBaseSpinEnd(session, spin_context)
    local player = session.player
    local win_chip = spin_context.win_chip
    local chip_cost = spin_context.chip_cost
    local save_data = spin_context.player_game_info.save_data
    local player_json_data = spin_context.player_json_data

    if player.character.lucky > 0 then
        LuckyCal.AddLuckyCredit(player, win_chip - chip_cost)
    elseif player.character.unlucky > 0 then
        LuckyCal.AddUnluckyCredit(player, chip_cost - win_chip)
    else
        LuckyCal.AddNormalCreditChange(player, player_json_data, "normal_credit_change1", win_chip - chip_cost)
        LuckyCal.AddNormalCreditChange(player, player_json_data, "normal_credit_change2", win_chip - chip_cost)
    end

    -- 增加force win次数
    LuckyCal.AddForceWinCount(save_data, player_json_data, spin_context.game_type)
end

function Create(self)
    local obj = {}
    setmetatable(obj, {__index = LuckyModeForceWinObject})
    return obj
end
