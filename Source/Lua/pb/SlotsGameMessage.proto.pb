
Ö
SlotsGameMessage.protoCommon.protoPlayer.protoContest.protoSlots.protoGameInfo.proto"o
SlotsGame_Enter_Request
header (2.Header
table_id (
	game_type (
is_fever_quest ("Ë
SlotsGame_Enter_Response
header (2.Header
ret (2.Return
player (2.Player

bonus_info (	
	game_info (2	.GameInfo
last_formation_list (	
game_status_list (	"n
SlotsGame_Bonus_Request
header (2.Header
	game_type (
command_name (	
	parameter (	"ƒ
SlotsGame_Bonus_Response
header (2.Header
ret (2.Return
	game_type (
command_name (	
content (	"q
SlotsGame_Start_Request
header (2.Header
amount (
formation_type (
bet_amount_id ("é
SlotsGame_Spin_Info
item_ids (	%
prize_items (2.Slots_PrizeItem
win_chip (
pre_action_list (	
action_list (	
final_item_ids (	
reel_ways_info (	
	ways_type (
slots_win_chip	 ("P
SlotsGame_Formation-
slots_spin_list (2.SlotsGame_Spin_Info

id ("Ÿ
SlotsGame_Start_Response
header (2.Header
ret (2.Return,
formation_list (2.SlotsGame_Formation
	game_info (2	.GameInfo
is_multiply (
is_free_spin (
multiply_value (
player (2.Player
game_status_list	 (	

lucky_info
 (	">
SlotsGame_Wild_Request
header (2.Header
pos ("H
SlotsGame_Wild_Response
header (2.Header
ret (2.Return"1
SlotsGame_Exit_Request
header (2.Header"a
SlotsGame_Exit_Response
header (2.Header
ret (2.Return
player (2.Player"L
SlotsGame_TableSync_Notice
header (2.Header
table (2.Table