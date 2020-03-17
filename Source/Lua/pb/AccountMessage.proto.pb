
¾
AccountMessage.protoCommon.protoPlayer.protoAccount.protoClient.proto
User.protoDailyWheelData.protoLevelUpBoxData.proto"„
Account_Login_Request
header (2.Header
token (	
account (2.Account
client (2.Client
version ("x
Account_AgentLogin_Request
header (2.Header
token (	
account (2.Account
client (2.Client"¸
Account_Login_Response
header (2.Header
ret (2.Return
player (2.Player$
daily_wheel (2.DailyWheelData
slots_level_lock_info (	
is_dev (
game_sort_info (	
slot_level_config (	
is_new_player	 (
ui_type
 (	
	pay_award (
res_version (	"¨
Account_AgentLogin_Response
header (2.Header
ret (2.Return
player (2.Player$
daily_wheel (2.DailyWheelData
slots_level_lock_info (	
is_dev (
game_sort_info (	
slot_level_config (	
is_new_player	 (
ui_type
 (	
	pay_award ("1
Account_Logout_Request
header (2.Header"H
Account_Logout_Response
header (2.Header
ret (2.Return"G
Account_SetUser_Request
header (2.Header
user (2.User"b
Account_SetUser_Response
header (2.Header
ret (2.Return
player (2.Player"4
Account_HeartBeat_Request
header (2.Header"¨
Account_HeartBeat_Response
header (2.Header
ret (2.Return
pot_limit_time (
pot_collect_time (

pot_points (
purchased_pot ("J
Account_GetBriefInfo_Request
header (2.Header
	player_id ("c
Account_GetBriefInfo_Response
header (2.Header
ret (2.Return
user (2.User"±
Account_LevelUp_Notice
header (2.Header
level (

experience (
chip (#
	box_award (2.LevelUpBoxAward(
next_box_tip (2.NextLevelUpBoxTip"N
Account_OnSignal_Request
header (2.Header
include_player_id (	"J
Account_OnSignal_Response
header (2.Header
ret (2.Return"8
Account_SetBackground_Request
header (2.Header"O
Account_SetBackground_Response
header (2.Header
ret (2.Return"H
Account_ClientAction_Request
header (2.Header
content (	"N
Account_ClientAction_Response
header (2.Header
ret (2.Return"X
Account_Config_Request
header (2.Header

table_name (	
	game_type ("_
Account_Config_Response
header (2.Header
ret (2.Return
table_content (	"1
Account_RateUs_Request
header (2.Header"H
Account_RateUs_Response
header (2.Header
ret (2.Return"7
Account_PayFailAward_Request
header (2.Header"N
Account_PayFailAward_Response
header (2.Header
ret (2.Return"6
Account_InWhiteList_Request
header (2.Header"\
Account_InWhiteList_Response
header (2.Header
ret (2.Return
is_in ("/
Account_Ping_Request
header (2.Header"F
Account_Ping_Response
header (2.Header
ret (2.Return"Z
Account_Cheat_Request
header (2.Header
type (
arg1 (	
arg2 (	"q
Account_Cheat_Response
header (2.Header
ret (2.Return
type (
arg1 (	
arg2 (	