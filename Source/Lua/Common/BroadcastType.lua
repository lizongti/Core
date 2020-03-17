local GameTypes = GameType.AllTypes
local pairs = pairs
module("BroadcastType")

AllTypes = {
	OpenSesameSpin = 1,
	OpenSesameBonusGame = 2,
	DragonTaleSpin = 3,
	ForbiddenCitySpin = 4,
	VampireSpin = 5,
	FruitSliceSpin = 6,
	PharaohTreasureSpin = 7,
    HalloweenNight = 8,
	ElvesEpicSpin = 9,
	ElvesEpicJackpot = 10,
	AliceinWonderland = 11,
	AliceinWonderlandJackpot = 12,
	---保留旧玩法以上和GameType不一样的，把GameType的类型都合并过来

}

for _, gameType in pairs(GameTypes) do
	local find = false
	for __, broadType in pairs(AllTypes) do
		if broadType == gameType then
			find = true
			break
		end
	end
	if not find then
		AllTypes[_] = gameType
	end
end