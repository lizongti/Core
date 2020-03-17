module("MailType", package.seeall)

--类型1:激励视频，2：屏蔽广告计费点，3：INBOX SALE，4：Tournament奖励，5：升级客户端版本奖励，6：商品补发邮件，7：后台道具补发邮件, 8每日Bonus奖励，9获得金币，10，获得卡包，11获得VIP点数，12获得epic 卡包
MailTypes = {
    INCENTIVE_VIDEO = 1,
    BLOCK_AD_POINT = 2,
    INBOX_SALE = 3,
	TOURNAMENT_AWARD = 4,
	UPDATE_VERSION = 5,
	COMMODITY_REISSUE = 6,
	PROP_REISSUE = 7,
	DAILY_BONUS_AWARD = 8,
	FEVER_QUEST_CHIP = 9,
	FEVER_QUEST_CARD_PACKAGE = 10,
	FEVER_QUEST_VIP_POINT = 11,
	FEVER_QUEST_CARD_PACKAGE_EPIC = 12,
	BOOSTER_CASHBACK = 13,
}

TitleContentConfig = {
	["test"] = {
		title = "test",
		content = "test, %s"
	},
	["SendChips"] = {
		title = "Gift From %s",
		content = "%s sent you a bunch of chips to help you win more. Go and spin!"
	},
	["FinishClubChallenge"] = {
		title = "Club Challenge Prize",
		content = "Here is the prize for completing club daily challenge, good luck!"
	},
	["SettleTournament"] = {
		title = "Tournament Prize",
		content = "Your club ranked %s in the last tournament, here is the prize for you, wish you do better in the next season!"
	},
	["JoinClub"] = {
		title = "Club Prize",
		content = "Here is the prize for first joining a club, good luck!"
	},
	["AutoFetch"] = {
		title = "System automatic replenishing",
		content = "System automatic replenishing, please check."
	},
	["BindFacebook"] = {
		title = "Facebook Prize",
		content = "Here is the prize for connecting to Facebook, good luck!"
	},
	["VersionAward"] = {
		title = "Update Prize",
		content = "Thanks for updating!"
	},
	["TournamentPrize"] = {
		title = "Tournament Prize",
		content = "You win %s in the last tournament!"
	},
	["DailyBonus"] = {
		title = "DailyBonus",
		content = "Daily Welcome Bonus"
	},
	["FeverQuestPrizeCardPackage"] = {
		title = "FeverQuestPrize",
		content = "1 Epic Package from Quest Fever!"
	},
	["FeverQuestPrizeCoin"] = {
		title = "FeverQuestPrize",
		content = "%d Coins Prize from Quest Fever!"
	},
	["FeverQuestPrizeVipPoint"] = {
		title = "FeverQuestPrize",
		content = "%d VIP Points from Quest Fever!"
	},
	["BoosterCashback"] = {
		title = "BoosterCashback",
		content = "Cashback Bonus"
	}
}