
å
FeverCardMessage.protoCommon.protoPlayer.proto"9
CardInfo

id (
count (

epic_count ("`
CardSetInfo
cards (2	.CardInfo
set_id (
rewarded (
rewardedChips ("k
	AlbumInfo

id (
count (
rewarded (
sets (2.CardSetInfo
rewardedChips (";
CardHistoryInfo

id (
time (
source ("U
(FeverCard_GetAlbumCompleteReward_Request
header (2.Header
album_id ("}
)FeverCard_GetAlbumCompleteReward_Response
header (2.Header
album_id (
chip (
player (2.Player"L
AlbumCompleteInfo
album_id (
chip (
player (2.Player"Q
&FeverCard_GetSetCompleteReward_Request
header (2.Header
set_id ("y
'FeverCard_GetSetCompleteReward_Response
header (2.Header
set_id (
chip (
player (2.Player"H
SetCompleteInfo
set_id (
chip (
player (2.Player"I
FeverCard_EpicMachine_Request
header (2.Header
card_id ("›
FeverCard_EpicMachine_Response
header (2.Header
ret (2.Return
	reward_id (
chip (
cards (2	.CardInfo
player (2.Player
	vip_point (
respin_count (
card_id	 ("^
FeverCard_StarWheel_Request
header (2.Header
cards (2	.CardInfo
type ("˝
FeverCard_StarWheel_Response
header (2.Header
ret (2.Return
	reward_id (
chip (
cards (2	.CardInfo
player (2.Player
star_wheel_left_time ( 
consume_cards (2	.CardInfo
wild_card_album_id	 ("4
FeverCard_History_Request
header (2.Header"o
FeverCard_History_Response
header (2.Header
ret (2.Return"
historys (2.CardHistoryInfo"’
FeverCard_NewCard_Notice
header (2.Header
cards (2	.CardInfo
type (
time (
source (*
set_complete_arr (2.SetCompleteInfo.
album_complete_arr (2.AlbumCompleteInfo"M
 FeverCard_AlbumCardsInfo_Request
header (2.Header
album_id ("m
!FeverCard_AlbumCardsInfo_Response
header (2.Header
ret (2.Return
album (2
.AlbumInfo"6
FeverCard_AlbumInfo_Request
header (2.Header"ù
FeverCard_AlbumInfo_Response
header (2.Header
ret (2.Return
album_id_arr (
star_wheel_left_time (
wild_card_album_id ("M
!FeverCard_ConfirmWildCard_Request
header (2.Header
card_id ("d
"FeverCard_ConfirmWildCard_Response
header (2.Header
ret (2.Return
card_id (