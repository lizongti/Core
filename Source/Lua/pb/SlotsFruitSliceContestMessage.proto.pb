
Ê
#SlotsFruitSliceContestMessage.protoCommon.protoPlayer.protoContest.protoSlots.proto"X
$SlotsFruitSliceContest_Enter_Request
header (2.Header
player (2.Player"ê
%SlotsFruitSliceContest_Enter_Response
header (2.Header
ret (2.Return
table (2.Table

channel_id (	
bonus ("S
#SlotsFruitSliceContest_Enter_Notice
header (2.Header
seat (2.Seat"Q
#SlotsFruitSliceContest_Exit_Request
header (2.Header
	player_id ("Ä
$SlotsFruitSliceContest_Exit_Response
header (2.Header
ret (2.Return
table (2.Table

channel_id (	"R
"SlotsFruitSliceContest_Exit_Notice
header (2.Header
seat (2.Seat"T
&SlotsFruitSliceContest_Offline_Request
header (2.Header
	player_id ("X
'SlotsFruitSliceContest_Offline_Response
header (2.Header
ret (2.Return"U
%SlotsFruitSliceContest_Offline_Notice
header (2.Header
seat (2.Seat"Ä
%SlotsFruitSliceContest_Hotfix_Request
header (2.Header
process_name (	
module_path (	
module_name (	"W
&SlotsFruitSliceContest_Hotfix_Response
header (2.Header
ret (2.Return"g
$SlotsFruitSliceContest_Start_Request
header (2.Header
	player_id (
erase_times ("V
%SlotsFruitSliceContest_Start_Response
header (2.Header
ret (2.Return"v
$SlotsFruitSliceContest_Slice_Request
header (2.Header
	player_id (
fruit_id (
win_chip ("V
%SlotsFruitSliceContest_Slice_Response
header (2.Header
ret (2.Return"Q
'SlotsFruitSliceContest_StateSync_Notice
header (2.Header
state ("w
#SlotsFruitSliceContest_Fruit_Notice
header (2.Header
fruit_id (

fruit_type (
	timestamp ("Ç
)SlotsFruitSliceContest_FruitSliced_Notice
header (2.Header
fruit_id (*
fruit_explode (2.Slots_FruitExplode"e
#SlotsFruitSliceContest_Bonus_Notice
header (2.Header
bonus (
trigger_player ("o
)SlotsFruitSliceContest_PlayerScore_Notice
header (2.Header
seat (2.Seat
player_score (