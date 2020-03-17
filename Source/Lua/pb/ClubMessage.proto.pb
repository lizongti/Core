
‰(
ClubMessage.proto
Club.protoCommon.protoPlayer.proto"C
Club_Create_Request
header (2.Header
club (2.Club"‡
Club_Create_Response
header (2.Header
ret (2.Return
player (2.Player
club (2.Club

join_bonus ("_
Club_Query_Request
header (2.Header
filter (2.ClubFilter
filter_name (	"Z
Club_Query_Response
header (2.Header
ret (2.Return
clubs (2.Club"5
Club_QueryRequests_Request
header (2.Header"’
Club_QueryRequests_Response
header (2.Header
ret (2.Return
requests (2.ClubRequest$
invitations (2.ClubInvitation"K
Club_AcceptInvitation_Request
header (2.Header
	invite_id ("|
Club_AcceptInvitation_Response
header (2.Header
ret (2.Return
player (2.Player

join_bonus ("L
Club_DeclineInvitation_Request
header (2.Header
	invite_id ("P
Club_DeclineInvitation_Response
header (2.Header
ret (2.Return"J
Club_ApproveRequest_Request
header (2.Header

request_id ("M
Club_ApproveRequest_Response
header (2.Header
ret (2.Return"I
Club_RejectRequest_Request
header (2.Header

request_id ("L
Club_RejectRequest_Response
header (2.Header
ret (2.Return"=
Club_Join_Request
header (2.Header
club_id ("…
Club_Join_Response
header (2.Header
ret (2.Return
club (2.Club
player (2.Player

join_bonus (">
Club_Apply_Request
header (2.Header
club_id ("D
Club_Apply_Response
header (2.Header
ret (2.Return"A
Club_Fund_Request
header (2.Header
fund_amount ("q
Club_Fund_Response
header (2.Header
ret (2.Return
player (2.Player
club (2.Club"A
Club_Invite_Request
header (2.Header
	player_id ("E
Club_Invite_Response
header (2.Header
ret (2.Return"3
Club_GetClubInfo_Request
header (2.Header"_
Club_GetClubInfo_Response
header (2.Header
ret (2.Return
club (2.Club"H
Club_SetClubInfo_Request
header (2.Header
club (2.Club"_
Club_SetClubInfo_Response
header (2.Header
ret (2.Return
club (2.Club"-
Club_Leave_Request
header (2.Header"]
Club_Leave_Response
header (2.Header
ret (2.Return
player (2.Player"1
Club_QueryPost_Request
header (2.Header"g
Club_QueryPost_Response
header (2.Header
ret (2.Return

club_posts (2	.ClubPost"=
Club_Post_Request
header (2.Header
content (	"b
Club_Post_Response
header (2.Header
ret (2.Return

club_posts (2	.ClubPost"C
Club_DeletePost_Request
header (2.Header
post_id ("h
Club_DeletePost_Response
header (2.Header
ret (2.Return

club_posts (2	.ClubPost"B
Club_StickPost_Request
header (2.Header
post_id ("g
Club_StickPost_Response
header (2.Header
ret (2.Return

club_posts (2	.ClubPost"D
Club_QueryMember_Request
header (2.Header
club_id ("h
Club_QueryMember_Response
header (2.Header
ret (2.Return
members (2.ClubMember"B
Club_Promote_Request
header (2.Header
	player_id ("[
Club_Promote_Response
header (2.Header
ret (2.Return
club (2.Club"A
Club_Demote_Request
header (2.Header
	player_id ("Z
Club_Demote_Response
header (2.Header
ret (2.Return
club (2.Club"B
Club_KickOut_Request
header (2.Header
	player_id ("[
Club_KickOut_Response
header (2.Header
ret (2.Return
club (2.Club"7
Club_QueryTournament_Request
header (2.Header"z
Club_QueryTournament_Response
header (2.Header
ret (2.Return
club (2.Club
end_timestamp ("G
Club_QueryClubByGrade_Request
header (2.Header
grade ("d
Club_QueryClubByGrade_Response
header (2.Header
ret (2.Return
club (2.Club";
 Club_QueryDailyChallenge_Request
header (2.Header"“
!Club_QueryDailyChallenge_Response
header (2.Header
ret (2.Return(
daily_challenges (2.ChallengeItem
end_timestamp ("R
!Club_QueryChallengeLeader_Request
header (2.Header
challenge_id ("q
"Club_QueryChallengeLeader_Response
header (2.Header
ret (2.Return
leaders (2.LeaderItem"2
Club_QueryEvent_Request
header (2.Header"j
Club_QueryEvent_Response
header (2.Header
ret (2.Return
club_events (2
.ClubEvent"1
Club_QueryChat_Request
header (2.Header"i
Club_QueryChat_Reponse
header (2.Header
ret (2.Return 
	chat_data (2.ClubChatItem"O
Club_FinishChallenge_Notice
header (2.Header
challenge_index ("=
Club_LevelUp_Notice
header (2.Header
level ("4
Club_RegisterChat_Request
header (2.Header"K
Club_RegisterChat_Response
header (2.Header
ret (2.Return