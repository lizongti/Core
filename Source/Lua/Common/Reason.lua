--------------
--  Reason  --
--------------
require "Base/Path"
require "Config/system/GameRoomConfig"

_G.Reason = {}
Reason.objects = {}

Reason.register = {
	{"USE_PROP_CONSUME", "使用道具消耗"},
	{"USE_PROP_OBTAIN", "使用道具获得"},
	{"USE_PROP_OBTAIN", "使用道具获得"},
	{"PURCHARSE_PROP_CONSUME", "购买道具消耗"},
	{"PURCHARSE_PROP_OBTAIN", "购买道具获得"},
	{"SELL_PROP_CONSUME", "出售道具消耗"},
	{"SELL_PROP_OBTAIN", "出售道具获得"},
	{"PRESENT_PROP_CONSUME", "赠送道具消耗"},
	{"PRESENT_PROP_OBTAIN", "赠送道具获得"},
	{"CHARGE_PROP_OBTAIN", "充值道具获得"},
	{"UNLOCK_CONSUME", "解锁玩法消耗"},
	{"CASH_CASINO_OBTAIN", "CashCasino获得"},
	---------------------------------------------------------------
	{"DOUBLE_PURCHASE_EXTRA_PROP_OBTAIN", "复购获得"},
	{"CHARGE_VIP_EXTRA_PROP_OBTAIN", "VIP额外奖励道具获得"},
	{"INIT_PROP_OBTAIN", "初始化道具获得"},
	{"LOGIN_REWARD_PROP_OBTAIN", "登录奖励道具获得"},
	{"ONLINE_REWARD_PROP_OBTAIN", "在线奖励道具获得"},
	{"DAILY_TASK_REWARD_PROP_OBTAIN", "每日任务奖励道具获得"},
	{"LEVEL_UP_PROP_OBTAIN", "升级道具获得"},
	{"LEVEL_UP_BOX_PROP_OBTAIN", "升级礼盒道具获得"},
	{"GET_ATTACHMENT_PROP_OBTAIN", "获取附件道具获得"},
	{"GET_ATTACHMENT_PROP_CONSUME", "获取附件道具消耗"},
	{"LOBBYBONUS_MULTIPLY_CONSUME", "获取大奖倍增消耗"},
	{"LOBBYBONUS_MULTIPLY_OBTAIN", "获取大奖倍增"},
	{"LOBBYBONUS_COLLECT_POT_OBTAIN", "获取存储罐"},
	----------------------------------------------------------------
	---------------------------------FeverQuest----------------------------------------
	{"FEVERQUEST_FINISH_OBTAIN", "FeverQuest完成任务获得"},
	{"FEVERQUEST_RANK_REWARD_OBTAIN", "Fever Quest排名获得"},
	---------------------------------FeverCard----------------------------------------
	{"FEVERCARD_EPIC_MACHINE_OBTAIN", "卡牌Epic Machine获得"},
	{"FEVERCARD_STAR_WHEEL_OBTAIN", "卡牌Star Wheel获得"},
	{"FEVERCARD_SET_REWARD_OBTAIN", "卡牌集齐卡册获得"},
	{"FEVERCARD_ALBUM_REWARD_OBTAIN", "卡牌集齐卡簿获得"},
	---------------------------------OpenSesame----------------------------------------
	{"OPENSESAME_BET_CHIP_CONSUME", "芝麻开门投注道具消耗"},
	{"OPENSESAME_BET_CHIP_OBTAIN", "芝麻开门投注道具获得"},
	{"OPENSESAME_BONUS_GAME_OBTAIN", "芝麻开门BonusGame获得"},
	{"LOBBYBONUS_COLLECT_OBTAIN", "Lobby bonus collect获得"},
	{"SHOPBONUS_COLLECT_OBTAIN", "Shop bonus collect获得"},
	{"DAILYWHEEL_LOGIN_OBTAIN", "登录时的daily wheel获得"},
	{"DAILYWHEEL_VIP_EXTRA_OBTAIN", "登录时的daily wheel因vip额外获得"},
	{"LOBBYBONUS_LOGIN_AWARD_OBTAIN", "Lobby bonus 登陆奖励获得"},
	{"LOGIN_REWARD_OBTAIN", "登录时的连续登录奖励获得"},
	-------------------------------------Gift------------------------------------------
	{"GIFT_PRESENT_TREAT_CONSUME", "赠送treat道具消耗"},
	{"GIFT_PRESENT_CHIP_OBTAIN", "被赠送筹码道具获得"},
	{"GIFT_PRESENT_CHIP_CONSUME", "赠送chip道具消耗"},
	-----------------------------DragonTale--------------------------------------------
	{"DRAGONTALE_BET_CHIP_CONSUME", "Dragon Tale投注道具消耗"},
	{"DRAGONTALE_BET_CHIP_OBTAIN", "Dragon Tale投注道具获得"},
	----------------------------ForbiddenCity------------------------------------------
	{"FORBIDDENCITY_BET_CHIP_CONSUME", "Forbidden City投注道具消耗"},
	{"FORBIDDENCITY_BET_CHIP_OBTAIN", "Forbidden City投注道具获得"},
	----------------------------Vampire------------------------------------------
	{"VAMPIRE_BET_CHIP_CONSUME", "Vampire 投注道具消耗"},
	{"VAMPIRE_BET_CHIP_OBTAIN", "Vampire 投注道具获得"},
	----------------------------MonkeyKing------------------------------------------
	{"HALLOWEENNIGHT_BET_CHIP_CONSUME", "Halloween Night 投注道具消耗"},
	{"HALLOWEENNIGHT_BET_CHIP_OBTAIN", "Halloween Night 投注道具获得"},
	----------------------------FruitSlice------------------------------------------
	{"FRUITSLICE_BET_CHIP_CONSUME", "FruitSlice 投注道具消耗"},
	{"FRUITSLICE_BET_CHIP_OBTAIN", "FruitSlice 投注道具获得"},
	{"FRUITSLICE_SLICE_CHIP_OBTAIN", "FruitSlice 小游戏切水果道具获得"},
	--------------------------------------------------------------------------------
	{"PHARAOHTREASURE_BET_CHIP_CONSUME", "PharaohTreasure 投注道具消耗"},
	{"PHARAOHTREASURE_BET_CHIP_OBTAIN", "PharaohTreasure 投注道具获得"},
	{"PHARAOHTREASURE_PICK_CHIP_OBTAIN", "PharaohTreasure bonus game道具获得"},
	----------------------------Club------------------------------------------
	{"CLUB_CREATE_CONSUME", "创建俱乐部消耗"},
	{"CLUB_FUND_CONSUME", "俱乐部捐赠消耗"},
	{"GUIDANCE_OBTAIN", "新手引导道具获得"},
	{"BANKRUPT_PROTECT_OBTAIN", "破产保护获得"},
	{"RATEUS_OBTAIN", "玩家评价游戏道具获得"},
	{"JOIN_CLUB_OBTAIN", "玩家加入俱乐部道具获得"},
	{"BIND_FACEBOOK_OBTAIN", "玩家绑定facebook道具获得"},
	{"BUYLOSS_BUY_CONSUME", "玩家购买buyloss道具消耗"},
	{"BUYLOSS_BUY_OBTAIN", "玩家购买buyloss道具获得"},
	-------------------------ElvesEpic----------------------------------------------
	{"ELVESEPIC_BET_CHIP_CONSUME", "ElvesEpic 投注道具消耗"},
	{"ELVESEPIC_BET_CHIP_OBTAIN", "ElvesEpic 投注道具获得"},
	{"ELVESEPIC_BET_CHIP_JACKPOT", "ElvesEpic Jackpot中奖获得"},
	-------------------------AliceinWonderland----------------------------------------------
	{"ALICEINWONDERLAND_BET_CHIP_CONSUME", "AliceinWonderland 投注道具消耗"},
	{"ALICEINWONDERLAND_BET_CHIP_OBTAIN", "AliceinWonderland 投注道具获得"},
	{"ALICEINWONDERLAND_BET_CHIP_JACKPOT", "AliceinWonderland Jackpot中奖获得"},
	-------------------------Jackpot----------------------------------------------
	{"JACKPOT_CHIP_REWARD", "Jackpot中奖获得"},
	-------------------------Pirate----------------------------------------------
	{"PIRATE_BET_CHIP_CONSUME", "Pirate 投注道具消耗"},
	{"PIRATE_BET_CHIP_OBTAIN", "Pirate 投注道具获得"},
	{"PIRATE_BET_CHIP_Slots", "Pirate Slots小游戏获得"},
	-------------------------SantaSuprise----------------------------------------------
	{"SANTA_SUPRISE_BET_CHIP_CONSUME", "SantaSuprise 投注道具消耗"},
	{"SANTA_SUPRISE_BET_CHIP_OBTAIN", "SantaSuprise 投注道具获得"},
	-------------------------BacktoJurassic----------------------------------------------
	{"BACKTO_JURASSIC_BET_CHIP_CONSUME", "BacktoJurassic 投注道具消耗"},
	{"BACKTO_JURASSIC_BET_CHIP_OBTAIN", "BacktoJurassic 投注道具获得"},
	{"CHEFSCHOICE_BET_CHIP_CONSUME", "ChefsChoice 投注道具消耗"},
	{"CHEFSCHOICE_BET_CHIP_OBTAIN", "ChefsChoice 投注道具获得"},
	{"CHEFSCHOICE_BET_CHIP_Slots", "ChefsChoice Slots小游戏获得"},
	-------------------------WildCircus----------------------------------------------
	{"WILD_CIRCUS_BET_CHIP_CONSUME", "WildCircus 投注道具消耗"},
	{"WILD_CIRCUS_BET_CHIP_OBTAIN", "WildCircus 投注道具获得"},
	-------------------------AgentBond----------------------------------------------
	{"AGENT_BOND_BET_CHIP_CONSUME", "AgentBond 投注道具消耗"},
	{"AGENT_BOND_BET_CHIP_OBTAIN", "AgentBond 投注道具获得"},
	{"AGENT_BOND_BET_CHIP_BONUS", "AgentBond Bonus小游戏获得"},
	-------------------------LegendsofOlympus----------------------------------------------
	{"LEGENDSOF_OLYMPUS_BET_CHIP_CONSUME", "LegendsofOlympus 投注道具消耗"},
	{"LEGENDSOF_OLYMPUS_BET_CHIP_OBTAIN", "LegendsofOlympus 投注道具获得"},
	{"LEGENDSOF_OLYMPUS_BET_CHIP_BONUS", "LegendsofOlympus Bonus小游戏获得"},
	-------------------------ChineseNewYear----------------------------------------------
	{"CHINESE_NEW_YEAR_BET_CHIP_CONSUME", "ChineseNewYear 投注道具消耗"},
	{"CHINESE_NEW_YEAR_BET_CHIP_OBTAIN", "ChineseNewYear 投注道具获得"},
	{"CHINESE_NEW_YEAR_BET_BONUS_WIN", "ChineseNewYear bonus win获得"},
	{"CHINESE_NEW_YEAR_BET_CHIP_BONUS", "ChineseNewYear Bonus小游戏获得"},
	-------------------------BruceLee----------------------------------------------
	{"BRUCE_LEE_BET_CHIP_CONSUME", "BruceLee 投注道具消耗"},
	{"BRUCE_LEE_BET_CHIP_OBTAIN", "BruceLee 投注道具获得"},
	-------------------------IceAndFire----------------------------------------------
	{"ICE_AND_FIRE_BET_CHIP_CONSUME", "IceAndFire 投注道具消耗"},
	{"ICE_AND_FIRE_BET_CHIP_OBTAIN", "IceAndFire 投注道具获得"},
	{"ICE_AND_FIRE_EGG_CHIP_OBTAIN", "IceAndFire 龙蛋获得"},
	{"ICE_AND_FIRE_PROPET_CHIP_OBTAIN", "IceAndFire 龙蛋获得"},
	-------------------------LuxuryLife----------------------------------------------
	{"LUXURY_LIFE_BET_CHIP_CONSUME", "LuxuryLife 投注道具消耗"},
	{"LUXURY_LIFE_BET_CHIP_OBTAIN", "LuxuryLife 投注道具获得"},
	-------------------------CashSpin----------------------------------------------
	{"CASH_SPIN_BET_CHIP_CONSUME", "CashSpin 投注道具消耗"},
	{"CASH_SPIN_BET_CHIP_OBTAIN", "CashSpin 投注道具获得"},
	{"CASH_SPIN_BONUS_CHIP_OBTAIN", "CashSpin Bonus Game获得"},
	-------------------------PurrfectPets----------------------------------------------
	{"PURRFECT_PETS_BET_CHIP_CONSUME", "PurrfectPets 投注道具消耗"},
	{"PURRFECT_PETS_BET_CHIP_OBTAIN", "PurrfectPets 投注道具获得"},
	-------------------------SummerBeach----------------------------------------------
	{"SUMMER_BEACH_BET_CHIP_CONSUME", "SummerBeach 投注道具消耗"},
	{"SUMMER_BEACH_BET_CHIP_OBTAIN", "SummerBeach 投注道具获得"},
	{"SUMMER_BEACH_CAMERA_OBTAIN", "SummerBeach 拍照获得"},
	-------------------------WorldCup----------------------------------------------
	{"WORLD_CUP_BET_CHIP_CONSUME", "WorldCup 投注道具消耗"},
	{"WORLD_CUP_BET_CHIP_OBTAIN", "WorldCup 投注道具获得"},
	{"WORLD_CUP_FEATURE_CHIP_OBTAIN", "WorldCup 比赛获得"},
	-------------------------LeprechaunTreasure----------------------------------------------
	{"LEPRECHAUN_TREASURE_BET_CHIP_CONSUME", "LeprechaunTreasure 投注道具消耗"},
	{"LEPRECHAUN_TREASURE_BET_CHIP_OBTAIN", "LeprechaunTreasure 投注道具获得"},
	{"LEPRECHAUN_TREASURE_FEATURE_CHIP_OBTAIN", "LeprechaunTreasure 比赛获得"},
	-------------------------Ice777----------------------------------------------
	{"ICE_777_BET_CHIP_CONSUME", "Ice777 投注道具消耗"},
	{"ICE_777_BET_CHIP_OBTAIN", "Ice777 投注道具获得"},
	{"ICE_777_FEATURE_CHIP_OBTAIN", "Ice777 比赛获得"},
	-------------------------Mega5xWins----------------------------------------------
	{"MEGA5X_WINS_BET_CHIP_CONSUME", "Mega5xWins 投注道具消耗"},
	{"MEGA5X_WINS_BET_CHIP_OBTAIN", "Mega5xWins 投注道具获得"},
	{"MEGA5X_WINS_FEATURE_CHIP_OBTAIN", "Mega5xWins 比赛获得"},
	-------------------------PresidentTrump----------------------------------------------
	{"PRESIDENT_TRUMP_BET_CHIP_CONSUME", "PresidentTrump 投注道具消耗"},
	{"PRESIDENT_TRUMP_BET_CHIP_OBTAIN", "PresidentTrump 投注道具获得"},
	{"PRESIDENT_TRUMP_FEATURE_CHIP_OBTAIN", "PresidentTrump 比赛获得"},
	-------------------------TheSlotfather----------------------------------------------
	{"THE_SLOT_FATHER_BET_CHIP_CONSUME", "TheSlotFather 投注道具消耗"},
	{"THE_SLOT_FATHER_BET_CHIP_OBTAIN", "TheSlotFather 投注道具获得"},
	{"THE_SLOT_FATHER_FEATURE_CHIP_OBTAIN", "TheSlotFather 比赛获得"},
	-------------------------LittleRed----------------------------------------------
	{"LITTLE_RED_BET_CHIP_CONSUME", "LittleRed 投注道具消耗"},
	{"LITTLE_RED_BET_CHIP_OBTAIN", "LittleRed 投注道具获得"},
	{"LITTLE_RED_FEATURE_CHIP_OBTAIN", "LittleRed 比赛获得"},
	-------------------------Ad----------------------------------------------
	-------------------------WestWorld----------------------------------------------
	{"WEST_WORLD_BET_CHIP_CONSUME", "WestWorld 投注道具消耗"},
	{"WEST_WORLD_BET_CHIP_OBTAIN", "WestWorld 投注道具获得"},
	-------------------------PiggyJackpot----------------------------------------------
	{"FROZEN_ERA_BET_CHIP_CONSUME", "FROZEN_ERA 投注道具消耗"},
	{"FROZEN_ERA_BET_CHIP_OBTAIN", "FROZEN_ERA 投注道具获得"},
	{"FROZEN_ERA_FEATURE_CHIP_OBTAIN", "FROZEN_ERA 比赛获得"},
	{"AD_CHIP_OBTAIN", "广告获得"},
	------------------------PayFailAward-----------
	{"PAY_FAIL_AWARD", "支付失败获得"},
	------------------------Tournament------------------
	{"Tournament_PRIZE", "锦标赛奖励"},
	------------------------NewPurrfectPets------------------
	{"NEW_PURRFECT_PETS_BET_CHIP_CONSUME", "NewPurrfectPets 投注道具消耗"},
	{"NEW_PURRFECT_PETS_BET_CHIP_OBTAIN", "NewPurrfectPets 投注道具获得"},
	{"NEW_PURRFECT_PETS_FEATURE_CHIP_OBTAIN", "NewPurrfectPets 比赛获得"},
	-------------------------NewLeprechaunTreasure----------------------------------------------
	{"NEW_LEPRECHAUN_TREASURE_BET_CHIP_CONSUME", "NewLeprechaunTreasure 投注道具消耗"},
	{"NEW_LEPRECHAUN_TREASURE_BET_CHIP_OBTAIN", "NewLeprechaunTreasure 投注道具获得"},
	{"NEW_LEPRECHAUN_TREASURE_FEATURE_CHIP_OBTAIN", "NewLeprechaunTreasure 比赛获得"},
	-------------------------NEW_LEGENDS_OF_OLYMPUS----------------------------------------------
	{"NEW_LEGENDS_OF_OLYMPUS_BET_CHIP_CONSUME", "NEW_LEGENDS_OF_OLYMPUS 投注道具消耗"},
	{"NEW_LEGENDS_OF_OLYMPUS_BET_CHIP_OBTAIN", "NEW_LEGENDS_OF_OLYMPUS 投注道具获得"},
	{"NEW_LEGENDS_OF_OLYMPUS_FEATURE_CHIP_OBTAIN", "NEW_LEGENDS_OF_OLYMPUS 比赛获得"},
	-------------------------PiggyJackpot----------------------------------------------
	{"PIGGY_JACKPOT_BET_CHIP_CONSUME", "PIGGY_JACKPOT 投注道具消耗"},
	{"PIGGY_JACKPOT_BET_CHIP_OBTAIN", "PIGGY_JACKPOT 投注道具获得"},
	{"PIGGY_JACKPOT_FEATURE_CHIP_OBTAIN", "PIGGY_JACKPOT 比赛获得"},
	-------------------------GoldMine----------------------------------------------
	{"GOLD_MINE_BET_CHIP_CONSUME", "GOLD_MINE 投注道具消耗"},
	{"GOLD_MINE_BET_CHIP_OBTAIN", "GOLD_MINE 投注道具获得"},
	{"GOLD_MINE_FEATURE_CHIP_OBTAIN", "GOLD_MINE 比赛获得"},
	-------------------------NewWildCircus----------------------------------------------
	{"NEW_WILD_CIRCUS_BET_CHIP_CONSUME", "New_Wild_Circus 投注道具消耗"},
	{"NEW_WILD_CIRCUS_BET_CHIP_OBTAIN", "New_Wild_Circus 投注道具获得"},
	{"NEW_WILD_CIRCUS_FEATURE_CHIP_OBTAIN", "New_Wild_Circus 比赛获得"},
	-------------------------VampireRose----------------------------------------------
	{"VAMPIRE_ROSE_BET_CHIP_CONSUME", "Vampire_Rose 投注道具消耗"},
	{"VAMPIRE_ROSE_BET_CHIP_OBTAIN", "Vampire_Rose 投注道具获得"},
	{"VAMPIRE_ROSE_FEATURE_CHIP_OBTAIN", "Vampire_Rose 比赛获得"},
	-------------------------ThunderZeus----------------------------------------------
	{"THUNDER_ZEUS_BET_CHIP_CONSUME", "THUNDER_ZEUS 投注道具消耗"},
	{"THUNDER_ZEUS_BET_CHIP_OBTAIN", "THUNDER_ZEUS 投注道具获得"},
	{"THUNDER_ZEUS_FEATURE_CHIP_OBTAIN", "THUNDER_ZEUS 比赛获得"},
	-----------------------------DailyMission-------------------
	{"DAILY_MISSIONS_CHIP_OBTAIN", "DAILY_MISSIONS 收集获得"},
	-----------------------------PantherTracks-------------------
	{"PANTHER_TRACKS_CHIP_OBTAIN", "PANTHER_TRACKS 收集获得"},

	{"CLIMB_SLIDE_CHIP_OBTAIN", "CLIMB_SLIDE 收集获得"},
	{"CLIMB_SLIDE_SPIN_CHIP_OBTAIN", "CLIMB_SLIDE Spin获得"},

	-------------------------TestGame&模板----------------------------------------------
	{"TEST_GAME_BET_CHIP_CONSUME", "TEST_GAME 投注道具消耗"},
	{"TEST_GAME_BET_CHIP_OBTAIN", "TEST_GAME 投注道具获得"},
	{"TEST_GAME_FEATURE_CHIP_OBTAIN", "TEST_GAME 比赛获得"},
	-------------------------存钱罐获得---------------------------------
	{"PIGGY_BANK_CHIP_OBTAIN", "存钱罐获得"},
}

function Reason:Init()
	setmetatable(
		self,
		{
			__index = self.objects
		}
	)

	local reasonNameNeeds = {}
	for gameName, gameType in pairs(GameType.AllTypes) do
		local game_room_config = GameRoomConfig[gameType]
		if game_room_config then
			reasonNameNeeds[game_room_config.reason_name .. "_BET_CHIP_CONSUME"] = gameName .. " 投注道具消耗"
			reasonNameNeeds[game_room_config.reason_name .. "_BET_CHIP_OBTAIN"] = gameName .. " 投注道具获得"
			reasonNameNeeds[game_room_config.reason_name .. "_FEATURE_CHIP_OBTAIN"] = gameName .. " 比赛获得"
		end
	end

	for _, v in pairs(self.register) do
		self.objects[v[1]] = function()
			return v[2]
		end
		reasonNameNeeds[v[1]] = nil
	end

	for reasonName, reason in pairs(reasonNameNeeds) do
		self.objects[reasonName] = function()
			return reason
		end
	end
end

Reason:Init()
