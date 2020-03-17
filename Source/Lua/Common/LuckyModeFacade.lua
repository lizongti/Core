require("Common/LuckyModeNormal")
require("Common/LuckyModeLucky")
require("Common/LuckyModeUnlucky")
require("Common/LuckyModeForceWin")

LuckyModeFacade = {}

local types = {}

function LuckyModeFacade:InitLuckyTypes()
    types[LuckyType.ModeTypes.Normal] = LuckyModeNormal
    types[LuckyType.ModeTypes.Lucky] = LuckyModeLucky
    types[LuckyType.ModeTypes.Unlucky] = LuckyModeUnlucky
    types[LuckyType.ModeTypes.ForceWin] = LuckyModeForceWin
end

function LuckyModeFacade:CreateModeObject(lucky_type)
    return types[lucky_type]:Create()
end

function LuckyModeFacade:OnBaseSpinStart()
    
end

function LuckyModeFacade:OnBaseSpinEnd()
    
end

LuckyModeFacade:InitLuckyTypes()