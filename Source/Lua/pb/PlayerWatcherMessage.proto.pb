
˛-
PlayerWatcherMessage.protoCommon.protoPlayer.proto"u
PlayerWatcher_Register_Request
header (2.Header

session_id (
	player_id (
player_type ("b
PlayerWatcher_Register_Response
header (2.Header
ret (2.Return
dropping ("N
 PlayerWatcher_Deregister_Request
header (2.Header
	player_id ("R
!PlayerWatcher_Deregister_Response
header (2.Header
ret (2.Return"M
PlayerWatcher_HeartBeat_Request
header (2.Header
	player_id ("Q
 PlayerWatcher_HeartBeat_Response
header (2.Header
ret (2.Return"f
#PlayerWatcher_GetAttachment_Request
header (2.Header
	player_id (
attachments (	"U
$PlayerWatcher_GetAttachment_Response
header (2.Header
ret (2.Return"x
$PlayerWatcher_GetAttachments_Request
header (2.Header
	player_id (
props (	
old_player_id ("V
%PlayerWatcher_GetAttachments_Response
header (2.Header
ret (2.Return"J
PlayerWatcher_GetGoods_Request
header (2.Header
content (	"P
PlayerWatcher_GetGoods_Response
header (2.Header
ret (2.Return"j
PlayerWatcher_OptLog_Request
header (2.Header
	player_id (
category (	
data (	"N
PlayerWatcher_OptLog_Response
header (2.Header
ret (2.Return"l
PlayerWatcher_Push_Request
header (2.Header
method (	
channel_name (	
content (	"L
PlayerWatcher_Push_Response
header (2.Header
ret (2.Return"S
 PlayerWatcher_DropBanned_Request
header (2.Header
player_id_list ("R
!PlayerWatcher_DropBanned_Response
header (2.Header
ret (2.Return"t
PlayerWatcher_SendChips_Request
header (2.Header
sender (	
to_player_id (

chip_count ("Q
 PlayerWatcher_SendChips_Response
header (2.Header
ret (2.Return"w
PlayerWatcher_Hotfix_Request
header (2.Header
process_name (	
module_path (	
module_name (	"N
PlayerWatcher_Hotfix_Response
header (2.Header
ret (2.Return"O
!PlayerWatcher_ClubKickOut_Request
header (2.Header
	player_id ("S
"PlayerWatcher_ClubKickOut_Response
header (2.Header
ret (2.Return"`
!PlayerWatcher_ClubApprove_Request
header (2.Header
	player_id (
club_id ("S
"PlayerWatcher_ClubApprove_Response
header (2.Header
ret (2.Return"a
 PlayerWatcher_ClubReject_Request
header (2.Header
	player_id (
	club_name (	"R
!PlayerWatcher_ClubReject_Response
header (2.Header
ret (2.Return"e
!PlayerWatcher_ClubPromote_Request
header (2.Header
	player_id (
new_identity ("S
"PlayerWatcher_ClubPromote_Response
header (2.Header
ret (2.Return"d
 PlayerWatcher_ClubDemote_Request
header (2.Header
	player_id (
new_identity ("R
!PlayerWatcher_ClubDemote_Response
header (2.Header
ret (2.Return"Z
PlayerWatcher_Replaced_Request
header (2.Header
	player_id (
type ("P
PlayerWatcher_Replaced_Response
header (2.Header
ret (2.Return"P
"PlayerWatcher_BindFacebook_Request
header (2.Header
	player_id ("T
#PlayerWatcher_BindFacebook_Response
header (2.Header
ret (2.Return"é
$PlayerWatcher_BindPlayerInfo_Request
header (2.Header
	player_id (
platform_head_id (	
nickname (	
action (	"V
%PlayerWatcher_BindPlayerInfo_Response
header (2.Header
ret (2.Return"O
!PlayerWatcher_KickOffInfo_Request
header (2.Header
	player_id ("S
"PlayerWatcher_KickOffInfo_Response
header (2.Header
ret (2.Return"P
"PlayerWatcher_VersionAward_Request
header (2.Header
	player_id ("T
#PlayerWatcher_VersionAward_Response
header (2.Header
ret (2.Return"W
PlayerWatcher_Gm_Request
header (2.Header
	player_id (
content (	"I
PlayerWatcher_Gm_Reponse
header (2.Header
ret (2.Return"U
'PlayerWatcher_ClearTriggerTimes_Request
header (2.Header
	player_id ("Y
(PlayerWatcher_ClearTriggerTimes_Response
header (2.Header
ret (2.Return"Q
#PlayerWatcher_SetBackground_Request
header (2.Header
	player_id ("U
$PlayerWatcher_SetBackground_Response
header (2.Header
ret (2.Return"H
PlayerWatcher_FrdInfo_Request
header (2.Header
frd_id ("ç
PlayerWatcher_FrdInfo_Response
header (2.Header
ret (2.Return
	game_type (
table_id (
player (2.Player"z
PlayerWatcher_InviteFrd_Request
header (2.Header
table_id (
player (2.Player
frd_id_list ("â
 PlayerWatcher_InviteFrd_Response
header (2.Header
ret (2.Return
	player_id (
	game_type (
table_id ("\
#PlayerWatcher_OnlineFrdList_Request
header (2.Header
friend_list (2.Player"s
$PlayerWatcher_OnlineFrdList_Response
header (2.Header
ret (2.Return
friend_list (2.Player"P
"PlayerWatcher_ResetPotInfo_Request
header (2.Header
	player_id ("T
#PlayerWatcher_ResetPotInfo_Response
header (2.Header
ret (2.Return"^
PlayerWatcher_FrdList_Request
header (2.Header
	player_id (
	friend_id ("O
PlayerWatcher_FrdList_Response
header (2.Header
ret (2.Return"Z
!PlayerWatcher_IdentifyFrd_Request
header (2.Header
friend_list (2.Player"û
"PlayerWatcher_IdentifyFrd_Response
header (2.Header
ret (2.Return#
online_friend_list (2.Player$
offline_friend_list (2.Player"C
PlayerWatcher_Ping_Request
header (2.Header
time ("Z
PlayerWatcher_Ping_Response
header (2.Header
ret (2.Return
time (