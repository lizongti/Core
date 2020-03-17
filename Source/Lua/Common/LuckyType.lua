module("LuckyType", package.seeall)

ModeTypes = {
    Normal = 1,
    ForceWin = 2,
    Lucky = 3,
    Unlucky = 4,
}

function name(type)
    local v = {"Normal", "ForceWin", "Lucky", "Unlucky"}
    return v[type]
end
