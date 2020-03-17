
¶
FeverQuestMessage.protoCommon.protoPlayer.proto"w
FeverQuestRank
rank (
nickname (	
avatar (
facebook_id (
star (

prize_chip ("L
FeverQuestRankInfoHistory
season (
	tier_type (
rank ("d
FeverQuestTaskProgressItem
mission_type (
mission_progress (
mission_target ("q
FeverQuestRankInfo
	tier_type (
rank (
star (,
historys (2.FeverQuestRankInfoHistory":
FeverQuest_GetQuestInfo_Request
header (2.Header"Å
 FeverQuest_GetQuestInfo_Response
header (2.Header
ret (2.Return
season (
task_id (

hard_level (&
	rank_info (2.FeverQuestRankInfo
star (
is_boost (/

progresses	 (2.FeverQuestTaskProgressItem
task_fetch_level
 (
	left_time (
boost_left_time ("S
$FeverQuest_SetQuestHardLevel_Request
header (2.Header

hard_level ("T
%FeverQuest_SetQuestHardLevel_Response
header (2.Header

hard_level ("‚
%FeverQuest_UpdateQuestProgress_Notice
header (2.Header
task_id (/

progresses (2.FeverQuestTaskProgressItem"I
FeverQuest_SeasonEnd_Notice
header (2.Header
	season_id ("•
FeverQuest_FinishQuest_Notice
header (2.Header
task_id (
player (2.Player
star (
win_chip (
	is_finish ("a
FeverQuest_GetRankInfo_Request
header (2.Header
start_index (
	end_index ("ä
FeverQuest_GetRankInfo_Response
header (2.Header
ranks (2.FeverQuestRank
start_index (
	end_index (

pool_value (&
	rank_info (2.FeverQuestRankInfo
	left_time (
	tier_type (