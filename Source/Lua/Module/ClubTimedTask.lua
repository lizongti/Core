------------------
--  ClubTimedTask --
------------------
require "Common/ClubConsts"

_G.ClubTimedTask = {
	ResetClubChallengeEveryDay = function ( session )
	end,

	ResetClubTournamentEveryWeek = function ( session )
	end,

	GroupClubs = function ( all_club_id, grade, club_count_per_group )
		local groups = {}
		return groups
	end,

	--产生更新一组的俱乐部的段位的sql request, 同时加入了各个俱乐部段位变化的事件
	UpdateClubGradeRequests = function (requests, ranked_group_club, config_id)
	
	end,

	SendSettleMail = function ( session, task, ranked_club, config_id )
	end,

	SendSettlePushNotice = function ( session, task, ranked_club)
	end,

    RandChallengeIndex = function()
    end,

    AddSettleEvent = function (session, task, ranked_club)
    end,

    AddSettleOperative = function ( ranked_club )
    end,
}

