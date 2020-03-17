module("ClubConsts", package.seeall)

Grade = {
	BRONZE = 10,
	BRONZE_1 = 11,
	BRONZE_2 = 12,
	BRONZE_3 = 13,
	SILVER = 20,
	GOLD = 30,
	PLATINUM = 40,
	MASTER = 50,
	LEGEND = 60,
}

GradeToText = {
	[10] = "BRONZE",
	[11] = "BRONZE_1",
	[12] = "BRONZE_2",
	[13] = "BRONZE_3",
	[20] = "SILVER",
	[30] = "GOLD",
	[40] = "PLATINUM",
	[50] = "MASTER",
	[60] = "LEGEND",
}

BaseGradeOrder = {Grade.BRONZE, Grade.SILVER, Grade.GOLD, Grade.PLATINUM, Grade.MASTER, Grade.LEGEND}
AdvanceGradeOrder = {Grade.BRONZE_3, Grade.BRONZE_2, Grade.BRONZE_1, Grade.SILVER, Grade.GOLD, Grade.PLATINUM, Grade.MASTER, Grade.LEGEND}

GenNewClubGrade = function ( config_id )
	if config_id == 0 then
		return BaseGradeOrder[1]
	elseif config_id == 1 then
		return AdvanceGradeOrder[1]
	else
		return nil
	end
end

GetGradeIndex = function (grade, config_id)
	local order_config
	if config_id == 0 then
		order_config = BaseGradeOrder
	elseif config_id == 1 then
		order_config = AdvanceGradeOrder
	else
		return nil
	end
	for k,v in ipairs(order_config) do
		if v == grade then
			return k
		end
	end
end

GenNextGrade = function (cur_grade, config_id)
	local order_config
	if config_id == 0 then
		order_config = BaseGradeOrder
	elseif config_id == 1 then
		order_config = AdvanceGradeOrder
	else
		return nil
	end

	local index
	for k,v in ipairs(order_config) do
		if v == cur_grade then
			index = k
			break
		end
	end

	if not index then
		return nil
	else
		local next_index = math.min(index + 1, #order_config)
		return order_config[next_index]
	end
end

GenPostGrade = function ( cur_grade, config_id )
	local order_config
	if config_id == 0 then
		order_config = BaseGradeOrder
	elseif config_id == 1 then
		order_config = AdvanceGradeOrder
	else
		return nil
	end

	local index
	for k,v in ipairs(order_config) do
		if v == cur_grade then
			index = k
			break
		end
	end

	if not index then
		return nil
	else
		local post_index = math.max(index - 1, 1)
		return order_config[post_index]
	end
end

ClubIdentity = {
	LEADER = 1,
	CO_LEADER = 2,
	MEMBER = 3,
}

ClubIdentityToText = {
	[1] = "LEADER",
	[2] = "CO_LEADER",
	[3] = "MEMBER",
}

EventTemplate = {
	Create = "%s created the club",
	Join = "%s joined your club",
	Leave = "%s left your club",
	Fund = "%s funded %s the club",
	Promote = "%s has been promoted to co-leader",
	Demote = "%s has been demoted to member",
	KickOut = "%s has been kicked out from your club",
	BecomeLeader = "%s became the new leader",
	LevelUp = "Your club leveled up",
	CompleteTask = "Your club has completed No.%s challenge, check out the rewards in your inbox",
	TournamentRank = "Your club placed %s in the last tournament, check the rewards in your inbox",
    ClubUpGrade = "Your club moved to %s bracket, wish you good luck in the next tournament!",
    ClubDownGrade = "Your club is relegated to %s bracket",
}

EventType = {
	MEMBERSHIP = 1,
	RECORDS = 2,
}

RecordEventSubType = {
	LEVEL_UP = 1,
	COMPLETE_TASK = 2,
	TOURNAMENT_RANK = 3,
}

ClubType = {
	ANYONECANJOIN = 2,
	INVITEONLY = 1,
}

ClubTypeToText = {
	[1] = "INVITEONLY",
	[2] = "ANYONECANJOIN",
}

PostState = {
    NORMAL = 0,--普通post
    STICK = 1,--置顶post
}

AllowedChars = {" ", ".", "?", "!", ",", ":", ";", "_", "-", "(", ")", "[", "]", "{", "}", "'", '"', "#"}