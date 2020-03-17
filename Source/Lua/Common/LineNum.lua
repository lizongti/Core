--------------
--  LineNum --
--------------
require "Common/GameType"
require "Common/SlotsAgentBondCal"
require "Common/SlotsAliceinWonderlandCal"
require "Common/SlotsBacktoJurassicCal"
require "Common/SlotsCashSpinCal"
require "Common/SlotsChefsChoiceCal"
require "Common/SlotsChineseNewYearCal"
require "Common/SlotsDragonTaleCal"
require "Common/SlotsElvesEpicCal"
require "Common/SlotsForbiddenCityCal"
require "Common/SlotsFruitSliceCal"
require "Common/SlotsHalloweenNightCal"
require "Common/SlotsLegendsofOlympusCal"
require "Common/SlotsLuxuryLifeCal"
require "Common/SlotsOpenSesameCal"
require "Common/SlotsPharaohTreasureCal"
require "Common/SlotsPirateCal"
require "Common/SlotsPurrfectPetsCal"
require "Common/SlotsSantaSupriseCal"
require "Common/SlotsVampireCal"
require "Common/SlotsWildCircusCal"
require "Common/SlotsGameCal"
require "Common/GameConst"

_G.LineNum = {}
LineNum.objects = {}

function LineNum:Init()
    setmetatable(self, {
	    __index = self.objects
    })
	for gameName, gameType in pairs(GameType.AllTypes) do
		self.objects[gameType] = function()
			--LOG(RUN, INFO).Format("[Account][LineNum] gameType is: %s", gameType)
			-- 尽量减少复制粘贴，代码冗余
			if gameType == GameType.AllTypes.ChineseNewYear then
				return 25
			end
			if gameType == GameType.AllTypes.LeprechaunTreasure then
				return 20
			end	
			if gameType == GameType.AllTypes.LuxuryLife then
				return #SlotsLuxuryLifeCal.Const.BaseLines
			end		
			
			if gameType == GameType.AllTypes.Ice777 then
				return 1
			end
			
			if gameType == GameType.AllTypes.Mega5xWins then
				return 1
			end	

			if gameType == GameType.AllTypes.DancingDrums then
				return 100
			end	

			if gameType == GameType.AllTypes.NewBacktoJurassic then
				return 100
			end

			if gameType == GameType.AllTypes.ThunderZeus then
				return 50
			end

			if gameType == GameType.AllTypes.CashRain then
				return 60
			end

			if gameType == GameType.AllTypes.FrozenEra then
				return 100
			end

			if gameType == GameType.AllTypes.HoneyFortune then
				return 40
			end

			if gameType == GameType.AllTypes.LuckyChristmas then
				return 100
			end

			local gameCal = _G['Slots' .. gameName .. 'Cal']
			if gameCal and gameCal.Const and gameCal.Const.Lines then
				return #gameCal.Const.Lines
			end

			local newGameLineArray = _G[gameName .. 'LineArray']
			if newGameLineArray and newGameLineArray.Lines1 then
				return #newGameLineArray.Lines1
			end
			return 0
		end
	end
end

LineNum:Init()
