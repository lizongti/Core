
à-
CommandMessage.protoCommon.protoPlayer.proto
Prop.proto
Club.proto"D
DoublePurchase

vip_points (
chip (
goods_id ("V
Command_Drop_Request
header (2.Header

session_id (
	player_id ("F
Command_Drop_Response
header (2.Header
ret (2.Return"]
Command_Notice_Drop_Request
header (2.Header

session_id (
	player_id ("M
Command_Notice_Drop_Response
header (2.Header
ret (2.Return"I
Command_FinishDrop_Request
header (2.Header

session_id ("L
Command_FinishDrop_Response
header (2.Header
ret (2.Return"X
Command_Expire_Request
header (2.Header

session_id (
	player_id ("H
Command_Expire_Response
header (2.Header
ret (2.Return"o
Command_GetAttachments_Request
header (2.Header

session_id (
	player_id (
props (	"P
Command_GetAttachments_Response
header (2.Header
ret (2.Return"g
Command_GetAttachments_Notice
header (2.Header
item (2.Item
attachments_type ("^
Command_ResetPotInfo_Request
header (2.Header

session_id (
	player_id ("N
Command_ResetPotInfo_Response
header (2.Header
ret (2.Return"X
Command_GetGoods_Request
header (2.Header

session_id (
content (	"J
Command_GetGoods_Response
header (2.Header
ret (2.Return"Á
Command_GetGoods_Notice
header (2.Header
item (2.Item
goods_id (

payment_id (
payment_type (	(
double_purchase (2.DoublePurchase

vip_points ("_
Command_Player_Notice
header (2.Header
player (2.Player
collect_chip ("L
Command_AddFriend_Notice
header (2.Header
player (2.Player"x
Command_OptLog_Request
header (2.Header

session_id (
	player_id (
category (	
data (	"H
Command_OptLog_Response
header (2.Header
ret (2.Return"l
Command_Broadcast_Request
header (2.Header

channel_id (	
	player_id (	
content (	"K
Command_Broadcast_Response
header (2.Header
ret (2.Return"‚
Command_GetSendChips_Request
header (2.Header

session_id (
	player_id (

chip_count (
sender (	"N
Command_GetSendChips_Response
header (2.Header
ret (2.Return"H
Command_GetSendChips_Notice
header (2.Header
chip_get ("]
Command_ClubKickOut_Request
header (2.Header

session_id (
	player_id ("M
Command_ClubKickOut_Response
header (2.Header
ret (2.Return"N
Command_ClubKickOut_Notice
header (2.Header
player (2.Player"n
Command_ClubApprove_Request
header (2.Header

session_id (
	player_id (
club_id ("M
Command_ClubApprove_Response
header (2.Header
ret (2.Return"b
Command_ClubApprove_Notice
header (2.Header
player (2.Player

join_bonus ("o
Command_ClubReject_Request
header (2.Header

session_id (
	player_id (
	club_name (	"L
Command_ClubReject_Response
header (2.Header
ret (2.Return"G
Command_ClubReject_Notice
header (2.Header
	club_name (	"s
Command_ClubPromote_Request
header (2.Header

session_id (
	player_id (
new_identity ("M
Command_ClubPromote_Response
header (2.Header
ret (2.Return"J
Command_ClubPromote_Notice
header (2.Header
club (2.Club"r
Command_ClubDemote_Request
header (2.Header

session_id (
	player_id (
new_identity ("L
Command_ClubDemote_Response
header (2.Header
ret (2.Return"I
Command_ClubDemote_Notice
header (2.Header
club (2.Club"q
Command_Hotfix_Request
header (2.Header
process_name (	
module_path (	
module_name (	"H
Command_Hotfix_Response
header (2.Header
ret (2.Return"h
Command_Replaced_Request
header (2.Header

session_id (
	player_id (
type ("J
Command_Replaced_Response
header (2.Header
ret (2.Return"@
Command_Replaced_Notice
header (2.Header
type ("^
Command_BindFacebook_Request
header (2.Header

session_id (
	player_id ("N
Command_BindFacebook_Response
header (2.Header
ret (2.Return"œ
Command_BindPlayerInfo_Request
header (2.Header

session_id (
	player_id (
platform_head_id (	
nickname (	
action (	"P
Command_BindPlayerInfo_Response
header (2.Header
ret (2.Return"e
Command_Gm_Request
header (2.Header

session_id (
	player_id (
content (	"D
Command_Gm_Response
header (2.Header
ret (2.Return"Š
Command_InviteFrd_Request
header (2.Header

session_id (
	player_id (
friend (2.Player
frd_table_id ("K
Command_InviteFrd_Response
header (2.Header
ret (2.Return"‹
Command_InviteFrd_Notice
header (2.Header
ret (2.Return
	player_id (
friend (2.Player
frd_table_id ("Y
Command_FrdList_Request
header (2.Header

session_id (
	player_id ("I
Command_FrdList_Response
header (2.Header
ret (2.Return"\
Command_FrdList_Notice
header (2.Header
ret (2.Return
friend_list ("c
!Command_ClearTriggerTimes_Request
header (2.Header

session_id (
	player_id ("S
"Command_ClearTriggerTimes_Response
header (2.Header
ret (2.Return"p
Command_DailyMissions_Request
header (2.Header

session_id (
	player_id (
content (	"O
Command_DailyMissions_Response
header (2.Header
ret (2.Return