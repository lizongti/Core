---------------------
-- Protocol Define --
---------------------

---------------------
-- Protocol Define --
---------------------

_G.ProtocolDefine = {
    {
        id = 100,
        name = "Account", --require module "Module/Account"
        messages = {
            "Account_Login_Request", -- encode / decode proto Message "Account.Account_Login_Request"
            "Account_Login_Response",
            "Account_Logout_Request",
            "Account_Logout_Response",
            "Account_SetUser_Request",
            "Account_SetUser_Response",
            "Account_HeartBeat_Request",
            "Account_HeartBeat_Response",
            "Account_GetBriefInfo_Request",
            "Account_GetBriefInfo_Response",
            "Account_LevelUp_Notice",
            "Account_OnSignal_Request",
            "Account_OnSignal_Response",
            "Account_SetBackground_Request",
            "Account_SetBackground_Response",
            "Account_ClientAction_Request",
            "Account_ClientAction_Response",
            "Account_Config_Request",
            "Account_Config_Response",
            "Account_RateUs_Request",
            "Account_RateUs_Response",
            "Account_PayFailAward_Request",
            "Account_PayFailAward_Response",
            "Account_InWhiteList_Request",
            "Account_InWhiteList_Response",
            "Account_Ping_Request",
            "Account_Ping_Response",
            "Account_Cheat_Request",
            "Account_Cheat_Response",
            "Account_AgentLogin_Request",
            "Account_AgentLogin_Response",
        },
        handlers = {
            {"AgentLogin", "Account_AgentLogin_Request", "Account_AgentLogin_Response"},
            {"Login", "Account_Login_Request", "Account_Login_Response"},
            {"Logout", "Account_Logout_Request", "Account_Logout_Response"},
            {"SetUser", "Account_SetUser_Request", "Account_SetUser_Response"},
            {"HeartBeat", "Account_HeartBeat_Request", "Account_HeartBeat_Response"},
            {"GetBriefInfo", "Account_GetBriefInfo_Request", "Account_GetBriefInfo_Response"},
            {"OnSignal", "Account_OnSignal_Request", "Account_OnSignal_Response"},
            {"SetBackground", "Account_SetBackground_Request", "Account_SetBackground_Response"},
            {"ClientAction", "Account_ClientAction_Request", "Account_ClientAction_Response"},
            {"Config", "Account_Config_Request", "Account_Config_Response"},
            {"RateUs", "Account_RateUs_Request", "Account_RateUs_Response"},
            {"PayFailAward", "Account_PayFailAward_Request", "Account_PayFailAward_Response"},
            {"InWhiteList", "Account_InWhiteList_Request", "Account_InWhiteList_Response"},
            {"Ping", "Account_Ping_Request", "Account_Ping_Response"},
            {"Cheat", "Account_Cheat_Request", "Account_Cheat_Response"},
        }
    },
    {
        id = 101,
        name = "Communication",
        messages = {
            "Communication_Chat_Request",
            "Communication_Chat_Response",
            "Communication_Chat_Notice"
        },
        handlers = {
            {"Chat", "Communication_Chat_Request", "Communication_Chat_Response", "Communication_Chat_Notice"}
        }
    },
    {
        id = 102,
        name = "LoginReward",
        messages = {
            "LoginReward_Display_Request",
            "LoginReward_Display_Response",
            "LoginReward_Obtain_Request",
            "LoginReward_Obtain_Response"
        },
        handlers = {
            {"Display", "LoginReward_Display_Request", "LoginReward_Display_Response"},
            {"Obtain", "LoginReward_Obtain_Request", "LoginReward_Obtain_Response"}
        }
    },
    {
        id = 105,
        name = "PopUp",
        messages = {
            "PopUp_Show_Notice",
            "PopUp_Button_Request",
            "PopUp_Button_Response",
            "PopUp_Prop_Notice",
            "PopUp_Call_Notice",
            "PopUp_Toast_Notice"
        },
        handlers = {
            {"Button", "PopUp_Button_Request", "PopUp_Button_Response"}
        }
    },
    {
        id = 106,
        name = "SlotsOpenSesame",
        messages = {
            "SlotsOpenSesame_Enter_Request",
            "SlotsOpenSesame_Enter_Response",
            "SlotsOpenSesame_Start_Request",
            "SlotsOpenSesame_Start_Response",
            "SlotsOpenSesame_Exit_Request",
            "SlotsOpenSesame_Exit_Response",
            "SlotsOpenSesame_OpenBox_Request",
            "SlotsOpenSesame_OpenBox_Response",
            "SlotsOpenSesame_TableSync_Notice"
        },
        handlers = {
            {
                "Enter",
                "SlotsOpenSesame_Enter_Request",
                "SlotsOpenSesame_Enter_Response",
                "SlotsOpenSesame_TableSync_Notice"
            },
            {"Start", "SlotsOpenSesame_Start_Request", "SlotsOpenSesame_Start_Response"},
            {"Exit", "SlotsOpenSesame_Exit_Request", "SlotsOpenSesame_Exit_Response"},
            {"OpenBox", "SlotsOpenSesame_OpenBox_Request", "SlotsOpenSesame_OpenBox_Response"}
        }
    },
    {
        id = 107,
        name = "DailyTask",
        messages = {
            "DailyTask_Display_Request",
            "DailyTask_Display_Response",
            "DailyTask_Obtain_Request",
            "DailyTask_Obtain_Response",
            "DailyTask_Complete_Notice"
        },
        handlers = {
            {"Display", "DailyTask_Display_Request", "DailyTask_Display_Response"},
            {"Obtain", "DailyTask_Obtain_Request", "DailyTask_Obtain_Response"}
        }
    },
    {
        id = 108,
        name = "LobbyBonus",
        messages = {
            "LobbyBonus_Display_Request",
            "LobbyBonus_Display_Response",
            "LobbyBonus_Collect_Request",
            "LobbyBonus_Collect_Response",
            "LobbyBonus_Multiply_Request",
            "LobbyBonus_Multiply_Response",
            "LobbyBonus_AddFrd_Request",
            "LobbyBonus_AddFrd_Response",
            "LobbyBonus_ApplyFrd_Request",
            "LobbyBonus_ApplyFrd_Response",
            "LobbyBonus_IgnoreOrAcceptFrd_Request",
            "LobbyBonus_IgnoreOrAcceptFrd_Response",
            "LobbyBonus_FrdList_Request",
            "LobbyBonus_FrdList_Response",
            "LobbyBonus_FrdInfo_Request",
            "LobbyBonus_FrdInfo_Response",
            "LobbyBonus_InviteFrd_Request",
            "LobbyBonus_InviteFrd_Response",
            "LobbyBonus_OnlineFrdList_Request",
            "LobbyBonus_OnlineFrdList_Response",
            "LobbyBonus_UnLock_Request",
            "LobbyBonus_UnLock_Response",
            "LobbyBonus_CashCasino_Request",
            "LobbyBonus_CashCasino_Response",
            "LobbyBonus_Jackpot_Request",
            "LobbyBonus_Jackpot_Response",
            "LobbyBonus_LoginAward_Request",
            "LobbyBonus_LoginAward_Response",
            "LobbyBonus_CollectPot_Request",
            "LobbyBonus_CollectPot_Response",
            "LobbyBonus_PotCountDown_Request",
            "LobbyBonus_PotCountDown_Response"
        },
        handlers = {
            {"Display", "LobbyBonus_Display_Request", "LobbyBonus_Display_Response"},
            {"Collect", "LobbyBonus_Collect_Request", "LobbyBonus_Collect_Response"},
            {"Multiply", "LobbyBonus_Multiply_Request", "LobbyBonus_Multiply_Response"},
            {"AddFrd", "LobbyBonus_AddFrd_Request", "LobbyBonus_AddFrd_Response"},
            {"ApplyFrd", "LobbyBonus_ApplyFrd_Request", "LobbyBonus_ApplyFrd_Response"},
            {"IgnoreOrAcceptFrd", "LobbyBonus_IgnoreOrAcceptFrd_Request", "LobbyBonus_IgnoreOrAcceptFrd_Response"},
            {"FrdList", "LobbyBonus_FrdList_Request", "LobbyBonus_FrdList_Response"},
            {"FrdInfo", "LobbyBonus_FrdInfo_Request", "LobbyBonus_FrdInfo_Response"},
            {"InviteFrd", "LobbyBonus_InviteFrd_Request", "LobbyBonus_InviteFrd_Response"},
            {"OnlineFrdList", "LobbyBonus_OnlineFrdList_Request", "LobbyBonus_OnlineFrdList_Response"},
            {"UnLock", "LobbyBonus_UnLock_Request", "LobbyBonus_UnLock_Response"},
            {"CashCasino", "LobbyBonus_CashCasino_Request", "LobbyBonus_CashCasino_Response"},
            {"Jackpot", "LobbyBonus_Jackpot_Request", "LobbyBonus_Jackpot_Response"},
            {"LoginAward", "LobbyBonus_LoginAward_Request", "LobbyBonus_LoginAward_Response"},
            {"CollectPot", "LobbyBonus_CollectPot_Request", "LobbyBonus_CollectPot_Response"},
            {"PotCountDown", "LobbyBonus_PotCountDown_Request", "LobbyBonus_PotCountDown_Response"}
        }
    },
    {
        id = 109,
        name = "SlotsDragonTale",
        messages = {
            "SlotsDragonTale_Enter_Request",
            "SlotsDragonTale_Enter_Response",
            "SlotsDragonTale_Start_Request",
            "SlotsDragonTale_Start_Response",
            "SlotsDragonTale_Exit_Request",
            "SlotsDragonTale_Exit_Response",
            "SlotsDragonTale_TableSync_Notice"
        },
        handlers = {
            {
                "Enter",
                "SlotsDragonTale_Enter_Request",
                "SlotsDragonTale_Enter_Response",
                "SlotsDragonTale_TableSync_Notice"
            },
            {"Start", "SlotsDragonTale_Start_Request", "SlotsDragonTale_Start_Response"},
            {"Exit", "SlotsDragonTale_Exit_Request", "SlotsDragonTale_Exit_Response"}
        }
    },
    {
        id = 110,
        name = "SlotsForbiddenCity",
        messages = {
            "SlotsForbiddenCity_Enter_Request",
            "SlotsForbiddenCity_Enter_Response",
            "SlotsForbiddenCity_Start_Request",
            "SlotsForbiddenCity_Start_Response",
            "SlotsForbiddenCity_ChooseFreeSpin_Request",
            "SlotsForbiddenCity_ChooseFreeSpin_Response",
            "SlotsForbiddenCity_Exit_Request",
            "SlotsForbiddenCity_Exit_Response",
            "SlotsForbiddenCity_TableSync_Notice"
        },
        handlers = {
            {
                "Enter",
                "SlotsForbiddenCity_Enter_Request",
                "SlotsForbiddenCity_Enter_Response",
                "SlotsForbiddenCity_TableSync_Notice"
            },
            {"Start", "SlotsForbiddenCity_Start_Request", "SlotsForbiddenCity_Start_Response"},
            {
                "ChooseFreeSpin",
                "SlotsForbiddenCity_ChooseFreeSpin_Request",
                "SlotsForbiddenCity_ChooseFreeSpin_Response"
            },
            {"Exit", "SlotsForbiddenCity_Exit_Request", "SlotsForbiddenCity_Exit_Response"}
        }
    },
    {
        id = 111,
        name = "SlotsVampire",
        messages = {
            "SlotsVampire_Enter_Request",
            "SlotsVampire_Enter_Response",
            "SlotsVampire_Start_Request",
            "SlotsVampire_Start_Response",
            "SlotsVampire_Exit_Request",
            "SlotsVampire_Exit_Response",
            "SlotsVampire_TableSync_Notice"
        },
        handlers = {
            {"Enter", "SlotsVampire_Enter_Request", "SlotsVampire_Enter_Response", "SlotsVampire_TableSync_Notice"},
            {"Start", "SlotsVampire_Start_Request", "SlotsVampire_Start_Response"},
            {"Exit", "SlotsVampire_Exit_Request", "SlotsVampire_Exit_Response"}
        }
    },
    {
        id = 113,
        name = "Guidance",
        messages = {
            "Guidance_FetchData_Request",
            "Guidance_FetchData_Response"
        },
        handlers = {
            {"FetchData", "Guidance_FetchData_Request", "Guidance_FetchData_Response"}
        }
    },
    {
        id = 115,
        name = "RateUs",
        messages = {
            "RateUs_Fetch_Request",
            "RateUs_Fetch_Response"
        },
        handlers = {
            {"Fetch", "RateUs_Fetch_Request", "RateUs_Fetch_Response"}
        }
    },
    {
        id = 116,
        name = "BankruptProtect",
        messages = {
            "BankruptProtect_Fetch_Request",
            "BankruptProtect_Fetch_Response"
        },
        handlers = {
            {"Fetch", "BankruptProtect_Fetch_Request", "BankruptProtect_Fetch_Response"}
        }
    },
    {
        id = 117,
        name = "SlotsFruitSlice",
        messages = {
            "SlotsFruitSlice_Enter_Request",
            "SlotsFruitSlice_Enter_Response",
            "SlotsFruitSlice_Start_Request",
            "SlotsFruitSlice_Start_Response",
            "SlotsFruitSlice_Exit_Request",
            "SlotsFruitSlice_Exit_Response",
            "SlotsFruitSlice_Slice_Request",
            "SlotsFruitSlice_Slice_Response",
            "SlotsFruitSlice_TableSync_Notice"
        },
        handlers = {
            {
                "Enter",
                "SlotsFruitSlice_Enter_Request",
                "SlotsFruitSlice_Enter_Response",
                "SlotsFruitSlice_TableSync_Notice"
            },
            {"Start", "SlotsFruitSlice_Start_Request", "SlotsFruitSlice_Start_Response"},
            {"Exit", "SlotsFruitSlice_Exit_Request", "SlotsFruitSlice_Exit_Response"},
            {"Slice", "SlotsFruitSlice_Slice_Request", "SlotsFruitSlice_Slice_Response"}
        }
    },
    {
        id = 118,
        name = "BuyLoss",
        messages = {
            "BuyLoss_Buy_Request",
            "BuyLoss_Buy_Response",
            "BuyLoss_Trigger_Notice"
        },
        handlers = {
            {"Buy", "BuyLoss_Buy_Request", "BuyLoss_Buy_Response"}
        }
    },
    {
        id = 119,
        name = "SlotsPharaohTreasure",
        messages = {
            "SlotsPharaohTreasure_Enter_Request",
            "SlotsPharaohTreasure_Enter_Response",
            "SlotsPharaohTreasure_Start_Request",
            "SlotsPharaohTreasure_Start_Response",
            "SlotsPharaohTreasure_Exit_Request",
            "SlotsPharaohTreasure_Exit_Response",
            "SlotsPharaohTreasure_Pick_Request",
            "SlotsPharaohTreasure_Pick_Response",
            "SlotsPharaohTreasure_TableSync_Notice"
        },
        handlers = {
            {
                "Enter",
                "SlotsPharaohTreasure_Enter_Request",
                "SlotsPharaohTreasure_Enter_Response",
                "SlotsPharaohTreasure_TableSync_Notice"
            },
            {"Start", "SlotsPharaohTreasure_Start_Request", "SlotsPharaohTreasure_Start_Response"},
            {"Exit", "SlotsPharaohTreasure_Exit_Request", "SlotsPharaohTreasure_Exit_Response"},
            {"Pick", "SlotsPharaohTreasure_Pick_Request", "SlotsPharaohTreasure_Pick_Response"}
        }
    },
    {
        id = 120,
        name = "SlotsElvesEpic",
        messages = {
            "SlotsElvesEpic_Enter_Request",
            "SlotsElvesEpic_Enter_Response",
            "SlotsElvesEpic_Start_Request",
            "SlotsElvesEpic_Start_Response",
            "SlotsElvesEpic_Exit_Request",
            "SlotsElvesEpic_Exit_Response",
            "SlotsElvesEpic_TableSync_Notice",
            "SlotsElvesEpic_UpdateBetAmount_Request",
            "SlotsElvesEpic_UpdateBetAmount_Response"
        },
        handlers = {
            {
                "Enter",
                "SlotsElvesEpic_Enter_Request",
                "SlotsElvesEpic_Enter_Response",
                "SlotsElvesEpic_TableSync_Notice"
            },
            {"Start", "SlotsElvesEpic_Start_Request", "SlotsElvesEpic_Start_Response"},
            {"Exit", "SlotsElvesEpic_Exit_Request", "SlotsElvesEpic_Exit_Response"},
            {"UpdateBetAmount", "SlotsElvesEpic_UpdateBetAmount_Request", "SlotsElvesEpic_UpdateBetAmount_Response"}
        }
    },
    {
        id = 121,
        name = "SlotsHalloweenNight",
        messages = {
            "SlotsHalloweenNight_Enter_Request",
            "SlotsHalloweenNight_Enter_Response",
            "SlotsHalloweenNight_Start_Request",
            "SlotsHalloweenNight_Start_Response",
            "SlotsHalloweenNight_Exit_Request",
            "SlotsHalloweenNight_Exit_Response",
            "SlotsHalloweenNight_TableSync_Notice"
        },
        handlers = {
            {
                "Enter",
                "SlotsHalloweenNight_Enter_Request",
                "SlotsHalloweenNight_Enter_Response",
                "SlotsHalloweenNight_TableSync_Notice"
            },
            {"Start", "SlotsHalloweenNight_Start_Request", "SlotsHalloweenNight_Start_Response"},
            {"Exit", "SlotsHalloweenNight_Exit_Request", "SlotsHalloweenNight_Exit_Response"}
        }
    },
    {
        id = 122,
        name = "SlotsAliceinWonderland",
        messages = {
            "SlotsAliceinWonderland_Enter_Request",
            "SlotsAliceinWonderland_Enter_Response",
            "SlotsAliceinWonderland_Start_Request",
            "SlotsAliceinWonderland_Start_Response",
            "SlotsAliceinWonderland_Exit_Request",
            "SlotsAliceinWonderland_Exit_Response",
            "SlotsAliceinWonderland_TableSync_Notice",
            "SlotsAliceinWonderland_UpdateBetAmount_Request",
            "SlotsAliceinWonderland_UpdateBetAmount_Response"
        },
        handlers = {
            {
                "Enter",
                "SlotsAliceinWonderland_Enter_Request",
                "SlotsAliceinWonderland_Enter_Response",
                "SlotsAliceinWonderland_TableSync_Notice"
            },
            {"Start", "SlotsAliceinWonderland_Start_Request", "SlotsAliceinWonderland_Start_Response"},
            {"Exit", "SlotsAliceinWonderland_Exit_Request", "SlotsAliceinWonderland_Exit_Response"},
            {
                "UpdateBetAmount",
                "SlotsAliceinWonderland_UpdateBetAmount_Request",
                "SlotsAliceinWonderland_UpdateBetAmount_Response"
            }
        }
    },
    {
        id = 123,
        name = "SlotsPirate",
        messages = {
            "SlotsPirate_Enter_Request",
            "SlotsPirate_Enter_Response",
            "SlotsPirate_Start_Request",
            "SlotsPirate_Start_Response",
            "SlotsPirate_Exit_Request",
            "SlotsPirate_Exit_Response",
            "SlotsPirate_TableSync_Notice",
            "SlotsPirate_Slots_Request",
            "SlotsPirate_Slots_Response"
        },
        handlers = {
            {"Enter", "SlotsPirate_Enter_Request", "SlotsPirate_Enter_Response", "SlotsPirate_TableSync_Notice"},
            {"Start", "SlotsPirate_Start_Request", "SlotsPirate_Start_Response"},
            {"Exit", "SlotsPirate_Exit_Request", "SlotsPirate_Exit_Response"},
            {"Slots", "SlotsPirate_Slots_Request", "SlotsPirate_Slots_Response", "SlotsPirate_TableSync_Notice"}
        }
    },
    {
        id = 124,
        name = "SlotsSantaSuprise",
        messages = {
            "SlotsSantaSuprise_Enter_Request",
            "SlotsSantaSuprise_Enter_Response",
            "SlotsSantaSuprise_Start_Request",
            "SlotsSantaSuprise_Start_Response",
            "SlotsSantaSuprise_Exit_Request",
            "SlotsSantaSuprise_Exit_Response",
            "SlotsSantaSuprise_TableSync_Notice",
            "SlotsSantaSuprise_Wild_Request",
            "SlotsSantaSuprise_Wild_Response"
        },
        handlers = {
            {
                "Enter",
                "SlotsSantaSuprise_Enter_Request",
                "SlotsSantaSuprise_Enter_Response",
                "SlotsSantaSuprise_TableSync_Notice"
            },
            {"Start", "SlotsSantaSuprise_Start_Request", "SlotsSantaSuprise_Start_Response"},
            {"Exit", "SlotsSantaSuprise_Exit_Request", "SlotsSantaSuprise_Exit_Response"},
            {"Wild", "SlotsSantaSuprise_Wild_Request", "SlotsSantaSuprise_Wild_Response"}
        }
    },
    {
        id = 125,
        name = "SlotsBacktoJurassic",
        messages = {
            "SlotsBacktoJurassic_Enter_Request",
            "SlotsBacktoJurassic_Enter_Response",
            "SlotsBacktoJurassic_Start_Request",
            "SlotsBacktoJurassic_Start_Response",
            "SlotsBacktoJurassic_Exit_Request",
            "SlotsBacktoJurassic_Exit_Response",
            "SlotsBacktoJurassic_TableSync_Notice",
            "SlotsBacktoJurassic_SelectFreeSpinType_Request",
            "SlotsBacktoJurassic_SelectFreeSpinType_Response"
        },
        handlers = {
            {
                "Enter",
                "SlotsBacktoJurassic_Enter_Request",
                "SlotsBacktoJurassic_Enter_Response",
                "SlotsBacktoJurassic_TableSync_Notice"
            },
            {"Start", "SlotsBacktoJurassic_Start_Request", "SlotsBacktoJurassic_Start_Response"},
            {"Exit", "SlotsBacktoJurassic_Exit_Request", "SlotsBacktoJurassic_Exit_Response"},
            {
                "SelectFreeSpinType",
                "SlotsBacktoJurassic_SelectFreeSpinType_Request",
                "SlotsBacktoJurassic_SelectFreeSpinType_Response"
            }
        }
    },
    {
        id = 126,
        name = "CustomerService",
        messages = {
            "CustomerService_GetCurrentPage_Request",
            "CustomerService_GetCurrentPage_Response",
            "CustomerService_DisplayHistory_Request",
            "CustomerService_DisplayHistory_Response",
            "CustomerService_CustomerSay_Request",
            "CustomerService_CustomerSay_Response",
            "CustomerService_PushNewItem_Request",
            "CustomerService_PushNewItem_Response",
            "CustomerService_PushNewItem_Notice",
            "CustomerService_QueryUnread_Request",
            "CustomerService_QueryUnread_Response",
            "CustomerService_SetMaxRead_Request",
            "CustomerService_SetMaxRead_Response"
        },
        handlers = {
            {"GetCurrentPage", "CustomerService_GetCurrentPage_Request", "CustomerService_GetCurrentPage_Response"},
            {"DisplayHistory", "CustomerService_DisplayHistory_Request", "CustomerService_DisplayHistory_Response"},
            {"CustomerSay", "CustomerService_CustomerSay_Request", "CustomerService_CustomerSay_Response"},
            {"PushNewItem", "CustomerService_PushNewItem_Request", "CustomerService_PushNewItem_Response"},
            {"QueryUnread", "CustomerService_QueryUnread_Request", "CustomerService_QueryUnread_Response"},
            {"SetMaxRead", "CustomerService_SetMaxRead_Request", "CustomerService_SetMaxRead_Response"}
        }
    },
    {
        id = 127,
        name = "Friend",
        messages = {
            "Friend_Get_Request",
            "Friend_Get_Response",
            "Friend_PushAddFriendNotice_Request",
            "Friend_PushAddFriendNotice_Response"
        },
        handlers = {
            {"Get", "Friend_Get_Request", "Friend_Get_Response"},
            {"PushAddFriendNotice", "Friend_PushAddFriendNotice_Request", "Friend_PushAddFriendNotice_Response"}
        }
    },
    {
        id = 128,
        name = "SlotsChefsChoice",
        messages = {
            "SlotsChefsChoice_Enter_Request",
            "SlotsChefsChoice_Enter_Response",
            "SlotsChefsChoice_Start_Request",
            "SlotsChefsChoice_Start_Response",
            "SlotsChefsChoice_Exit_Request",
            "SlotsChefsChoice_Exit_Response",
            "SlotsChefsChoice_TableSync_Notice"
        },
        handlers = {
            {
                "Enter",
                "SlotsChefsChoice_Enter_Request",
                "SlotsChefsChoice_Enter_Response",
                "SlotsChefsChoice_TableSync_Notice"
            },
            {"Start", "SlotsChefsChoice_Start_Request", "SlotsChefsChoice_Start_Response"},
            {"Exit", "SlotsChefsChoice_Exit_Request", "SlotsChefsChoice_Exit_Response"}
        }
    },
    {
        id = 129,
        name = "SlotsWildCircus",
        messages = {
            "SlotsWildCircus_Enter_Request",
            "SlotsWildCircus_Enter_Response",
            "SlotsWildCircus_Start_Request",
            "SlotsWildCircus_Start_Response",
            "SlotsWildCircus_Exit_Request",
            "SlotsWildCircus_Exit_Response",
            "SlotsWildCircus_TableSync_Notice"
        },
        handlers = {
            {
                "Enter",
                "SlotsWildCircus_Enter_Request",
                "SlotsWildCircus_Enter_Response",
                "SlotsWildCircus_TableSync_Notice"
            },
            {"Start", "SlotsWildCircus_Start_Request", "SlotsWildCircus_Start_Response"},
            {"Exit", "SlotsWildCircus_Exit_Request", "SlotsWildCircus_Exit_Response"}
        }
    },
    {
        id = 130,
        name = "SlotsAgentBond",
        messages = {
            "SlotsAgentBond_Enter_Request",
            "SlotsAgentBond_Enter_Response",
            "SlotsAgentBond_Start_Request",
            "SlotsAgentBond_Start_Response",
            "SlotsAgentBond_Exit_Request",
            "SlotsAgentBond_Exit_Response",
            "SlotsAgentBond_TableSync_Notice",
            "SlotsAgentBond_Bonus_Request",
            "SlotsAgentBond_Bonus_Response"
        },
        handlers = {
            {
                "Enter",
                "SlotsAgentBond_Enter_Request",
                "SlotsAgentBond_Enter_Response",
                "SlotsAgentBond_TableSync_Notice"
            },
            {"Start", "SlotsAgentBond_Start_Request", "SlotsAgentBond_Start_Response"},
            {"Exit", "SlotsAgentBond_Exit_Request", "SlotsAgentBond_Exit_Response"},
            {"Bonus", "SlotsAgentBond_Bonus_Request", "SlotsAgentBond_Bonus_Response"}
        }
    },
    {
        id = 131,
        name = "SlotsLegendsofOlympus",
        messages = {
            "SlotsLegendsofOlympus_Enter_Request",
            "SlotsLegendsofOlympus_Enter_Response",
            "SlotsLegendsofOlympus_Bonus_Request",
            "SlotsLegendsofOlympus_Bonus_Response",
            "SlotsLegendsofOlympus_Start_Request",
            "SlotsLegendsofOlympus_Start_Response",
            "SlotsLegendsofOlympus_Exit_Request",
            "SlotsLegendsofOlympus_Exit_Response",
            "SlotsLegendsofOlympus_TableSync_Notice"
        },
        handlers = {
            {
                "Enter",
                "SlotsLegendsofOlympus_Enter_Request",
                "SlotsLegendsofOlympus_Enter_Response",
                "SlotsLegendsofOlympus_TableSync_Notice"
            },
            {"Start", "SlotsLegendsofOlympus_Start_Request", "SlotsLegendsofOlympus_Start_Response"},
            {"Bonus", "SlotsLegendsofOlympus_Bonus_Request", "SlotsLegendsofOlympus_Bonus_Response"},
            {"Exit", "SlotsLegendsofOlympus_Exit_Request", "SlotsLegendsofOlympus_Exit_Response"}
        }
    },
    {
        id = 132,
        name = "SlotsTest",
        messages = {
            "SlotsTest_Init_Request",
            "SlotsTest_Init_Response"
        },
        handlers = {
            {"Init", "SlotsTest_Init_Request", "SlotsTest_Init_Response"}
        }
    },
    {
        id = 133,
        name = "SlotsChineseNewYear",
        messages = {
            "SlotsChineseNewYear_Enter_Request",
            "SlotsChineseNewYear_Enter_Response",
            "SlotsChineseNewYear_Bonus_Request",
            "SlotsChineseNewYear_Bonus_Response",
            "SlotsChineseNewYear_Start_Request",
            "SlotsChineseNewYear_Start_Response",
            "SlotsChineseNewYear_Exit_Request",
            "SlotsChineseNewYear_Exit_Response",
            "SlotsChineseNewYear_TableSync_Notice",
            "SlotsChineseNewYear_SelFreeStyle_Request",
            "SlotsChineseNewYear_SelFreeStyle_Response"
        },
        handlers = {
            {
                "Enter",
                "SlotsChineseNewYear_Enter_Request",
                "SlotsChineseNewYear_Enter_Response",
                "SlotsChineseNewYear_TableSync_Notice"
            },
            {"Start", "SlotsChineseNewYear_Start_Request", "SlotsChineseNewYear_Start_Response"},
            {"Bonus", "SlotsChineseNewYear_Bonus_Request", "SlotsChineseNewYear_Bonus_Response"},
            {"Exit", "SlotsChineseNewYear_Exit_Request", "SlotsChineseNewYear_Exit_Response"},
            {"SelFreeStyle", "SlotsChineseNewYear_SelFreeStyle_Request", "SlotsChineseNewYear_SelFreeStyle_Response"}
        }
    },
    {
        id = 134,
        name = "SlotsBruceLee",
        messages = {
            "SlotsBruceLee_Enter_Request",
            "SlotsBruceLee_Enter_Response",
            "SlotsBruceLee_Start_Request",
            "SlotsBruceLee_Start_Response",
            "SlotsBruceLee_Exit_Request",
            "SlotsBruceLee_Exit_Response",
            "SlotsBruceLee_TableSync_Notice"
        },
        handlers = {
            {"Enter", "SlotsBruceLee_Enter_Request", "SlotsBruceLee_Enter_Response", "SlotsBruceLee_TableSync_Notice"},
            {"Start", "SlotsBruceLee_Start_Request", "SlotsBruceLee_Start_Response"},
            {"Exit", "SlotsBruceLee_Exit_Request", "SlotsBruceLee_Exit_Response"}
        }
    },
    {
        id = 135,
        name = "SlotsLuxuryLife",
        messages = {
            "SlotsLuxuryLife_Enter_Request",
            "SlotsLuxuryLife_Enter_Response",
            "SlotsLuxuryLife_Start_Request",
            "SlotsLuxuryLife_Start_Response",
            "SlotsLuxuryLife_Exit_Request",
            "SlotsLuxuryLife_Exit_Response",
            "SlotsLuxuryLife_TableSync_Notice"
        },
        handlers = {
            {
                "Enter",
                "SlotsLuxuryLife_Enter_Request",
                "SlotsLuxuryLife_Enter_Response",
                "SlotsLuxuryLife_TableSync_Notice"
            },
            {"Start", "SlotsLuxuryLife_Start_Request", "SlotsLuxuryLife_Start_Response"},
            {"Exit", "SlotsLuxuryLife_Exit_Request", "SlotsLuxuryLife_Exit_Response"}
        }
    },
    {
        id = 136,
        name = "SlotsCashSpin",
        messages = {
            "SlotsCashSpin_Enter_Request",
            "SlotsCashSpin_Enter_Response",
            "SlotsCashSpin_Start_Request",
            "SlotsCashSpin_Start_Response",
            "SlotsCashSpin_Pick_Request",
            "SlotsCashSpin_Pick_Response",
            "SlotsCashSpin_Exit_Request",
            "SlotsCashSpin_Exit_Response",
            "SlotsCashSpin_TableSync_Notice"
        },
        handlers = {
            {"Enter", "SlotsCashSpin_Enter_Request", "SlotsCashSpin_Enter_Response", "SlotsCashSpin_TableSync_Notice"},
            {"Start", "SlotsCashSpin_Start_Request", "SlotsCashSpin_Start_Response"},
            {"Pick", "SlotsCashSpin_Pick_Request", "SlotsCashSpin_Pick_Response"},
            {"Exit", "SlotsCashSpin_Exit_Request", "SlotsCashSpin_Exit_Response"}
        }
    },
    {
        id = 137,
        name = "SlotsIceAndFire",
        messages = {
            "SlotsIceAndFire_Enter_Request",
            "SlotsIceAndFire_Enter_Response",
            "SlotsIceAndFire_Start_Request",
            "SlotsIceAndFire_Start_Response",
            "SlotsIceAndFire_Feature_Start_Request",
            "SlotsIceAndFire_Feature_Start_Response",
            "SlotsIceAndFire_Select_Request",
            "SlotsIceAndFire_Select_Response",
            "SlotsIceAndFire_Pick_Request",
            "SlotsIceAndFire_Pick_Response",
            "SlotsIceAndFire_PropetPick_Request",
            "SlotsIceAndFire_PropetPick_Response",
            "SlotsIceAndFire_Exit_Request",
            "SlotsIceAndFire_Exit_Response",
            "SlotsIceAndFire_TableSync_Notice"
        },
        handlers = {
            {
                "Enter",
                "SlotsIceAndFire_Enter_Request",
                "SlotsIceAndFire_Enter_Response",
                "SlotsIceAndFire_TableSync_Notice"
            },
            {"Start", "SlotsIceAndFire_Start_Request", "SlotsIceAndFire_Start_Response"},
            {"Feature_Start", "SlotsIceAndFire_Feature_Start_Request", "SlotsIceAndFire_Feature_Start_Response"},
            {"Select", "SlotsIceAndFire_Select_Request", "SlotsIceAndFire_Select_Response"},
            {"Pick", "SlotsIceAndFire_Pick_Request", "SlotsIceAndFire_Pick_Response"},
            {"PropetPick", "SlotsIceAndFire_PropetPick_Request", "SlotsIceAndFire_PropetPick_Response"},
            {"Exit", "SlotsIceAndFire_Exit_Request", "SlotsIceAndFire_Exit_Response"}
        }
    },
    {
        id = 138,
        name = "SlotsPurrfectPets",
        messages = {
            "SlotsPurrfectPets_Enter_Request",
            "SlotsPurrfectPets_Enter_Response",
            "SlotsPurrfectPets_Start_Request",
            "SlotsPurrfectPets_Start_Response",
            "SlotsPurrfectPets_Exit_Request",
            "SlotsPurrfectPets_Exit_Response",
            "SlotsPurrfectPets_TableSync_Notice"
        },
        handlers = {
            {
                "Enter",
                "SlotsPurrfectPets_Enter_Request",
                "SlotsPurrfectPets_Enter_Response",
                "SlotsPurrfectPets_TableSync_Notice"
            },
            {"Start", "SlotsPurrfectPets_Start_Request", "SlotsPurrfectPets_Start_Response"},
            {"Exit", "SlotsPurrfectPets_Exit_Request", "SlotsPurrfectPets_Exit_Response"}
        }
    },
    {
        id = 139,
        name = "SlotsSummerBeach",
        messages = {
            "SlotsSummerBeach_Enter_Request",
            "SlotsSummerBeach_Enter_Response",
            "SlotsSummerBeach_Start_Request",
            "SlotsSummerBeach_Start_Response",
            "SlotsSummerBeach_Exit_Request",
            "SlotsSummerBeach_Exit_Response",
            "SlotsSummerBeach_TableSync_Notice"
        },
        handlers = {
            {
                "Enter",
                "SlotsSummerBeach_Enter_Request",
                "SlotsSummerBeach_Enter_Response",
                "SlotsSummerBeach_TableSync_Notice"
            },
            {"Start", "SlotsSummerBeach_Start_Request", "SlotsSummerBeach_Start_Response"},
            {"Exit", "SlotsSummerBeach_Exit_Request", "SlotsSummerBeach_Exit_Response"}
        }
    },
    {
        id = 140,
        name = "SlotsWorldCup",
        messages = {
            "SlotsWorldCup_Enter_Request",
            "SlotsWorldCup_Enter_Response",
            "SlotsWorldCup_Start_Request",
            "SlotsWorldCup_Start_Response",
            "SlotsWorldCup_Exit_Request",
            "SlotsWorldCup_Exit_Response",
            "SlotsWorldCup_TableSync_Notice"
        },
        handlers = {
            {"Enter", "SlotsWorldCup_Enter_Request", "SlotsWorldCup_Enter_Response", "SlotsWorldCup_TableSync_Notice"},
            {"Start", "SlotsWorldCup_Start_Request", "SlotsWorldCup_Start_Response"},
            {"Exit", "SlotsWorldCup_Exit_Request", "SlotsWorldCup_Exit_Response"}
        }
    },
    {
        id = 141,
        name = "SlotsGame",
        messages = {
            "SlotsGame_Enter_Request",
            "SlotsGame_Enter_Response",
            "SlotsGame_Start_Request",
            "SlotsGame_Start_Response",
            "SlotsGame_Exit_Request",
            "SlotsGame_Exit_Response",
            "SlotsGame_TableSync_Notice",
            "SlotsGame_Bonus_Request",
            "SlotsGame_Bonus_Response"
        },
        handlers = {
            {"Enter", "SlotsGame_Enter_Request", "SlotsGame_Enter_Response", "SlotsGame_TableSync_Notice"},
            {"Start", "SlotsGame_Start_Request", "SlotsGame_Start_Response"},
            {"Bonus", "SlotsGame_Bonus_Request", "SlotsGame_Bonus_Response"},
            {"Exit", "SlotsGame_Exit_Request", "SlotsGame_Exit_Response"}
        }
    },
    {
        id = 142,
        name = "PlayerMail",
        messages = {
            "PlayerMail_Query_Request",
            "PlayerMail_Query_Response",
            "PlayerMail_Fetch_Request",
            "PlayerMail_Fetch_Response",
            "PlayerMail_FetchPayment_Request",
            "PlayerMail_FetchPayment_Response",
            "PlayerMail_Delete_Request",
            "PlayerMail_Delete_Response",
            "PlayerMail_Hot_Request",
            "PlayerMail_Hot_Response"
        },
        handlers = {
            {"Query", "PlayerMail_Query_Request", "PlayerMail_Query_Response"},
            {"Fetch", "PlayerMail_Fetch_Request", "PlayerMail_Fetch_Response"},
            {"FetchPayment", "PlayerMail_FetchPayment_Request", "PlayerMail_FetchPayment_Response"},
            {"Delete", "PlayerMail_Delete_Request", "PlayerMail_Delete_Response"},
            {"Hot", "PlayerMail_Hot_Request", "PlayerMail_Hot_Response"}
        }
    },
    {
        id = 200,
        name = "Distributor",
        messages = {
            "Distributor_Notify_Request",
            "Distributor_Notify_Response",
            "Distributor_Register_Request",
            "Distributor_Register_Response",
            "Distributor_Deregister_Request",
            "Distributor_Deregister_Response"
        },
        handlers = {
            {"Notify", "Distributor_Notify_Request", "Distributor_Notify_Response"},
            {"Register", "Distributor_Register_Request", "Distributor_Register_Response"},
            {"Deregister", "Distributor_Deregister_Request", "Distributor_Deregister_Response"}
        }
    },
    {
        id = 201,
        name = "PlayerWatcher",
        messages = {
            "PlayerWatcher_Register_Request",
            "PlayerWatcher_Register_Response",
            "PlayerWatcher_Deregister_Request",
            "PlayerWatcher_Deregister_Response",
            "PlayerWatcher_Drop_Notice",
            "PlayerWatcher_HeartBeat_Request",
            "PlayerWatcher_HeartBeat_Response",
            "PlayerWatcher_GetAttachments_Request",
            "PlayerWatcher_GetAttachments_Response",
            "PlayerWatcher_GetGoods_Request",
            "PlayerWatcher_GetGoods_Response",
            "PlayerWatcher_OptLog_Request",
            "PlayerWatcher_OptLog_Response",
            "PlayerWatcher_Push_Request",
            "PlayerWatcher_Push_Response",
            "PlayerWatcher_DropBanned_Request",
            "PlayerWatcher_DropBanned_Response",
            "PlayerWatcher_SendChips_Request",
            "PlayerWatcher_SendChips_Response",
            "PlayerWatcher_Hotfix_Request",
            "PlayerWatcher_Hotfix_Response",
            "PlayerWatcher_ClubKickOut_Request",
            "PlayerWatcher_ClubKickOut_Response",
            "PlayerWatcher_ClubApprove_Request",
            "PlayerWatcher_ClubApprove_Response",
            "PlayerWatcher_ClubReject_Request",
            "PlayerWatcher_ClubReject_Response",
            "PlayerWatcher_ClubPromote_Request",
            "PlayerWatcher_ClubPromote_Response",
            "PlayerWatcher_ClubDemote_Request",
            "PlayerWatcher_ClubDemote_Response",
            "PlayerWatcher_Replaced_Request",
            "PlayerWatcher_Replaced_Response",
            "PlayerWatcher_BindFacebook_Request",
            "PlayerWatcher_BindFacebook_Response",
            "PlayerWatcher_BindPlayerInfo_Request",
            "PlayerWatcher_BindPlayerInfo_Response",
            "PlayerWatcher_VersionAward_Request",
            "PlayerWatcher_VersionAward_Response",
            "PlayerWatcher_ClearTriggerTimes_Request",
            "PlayerWatcher_ClearTriggerTimes_Response",
            "PlayerWatcher_SetBackground_Request",
            "PlayerWatcher_SetBackground_Response",
            "PlayerWatcher_FrdInfo_Request",
            "PlayerWatcher_FrdInfo_Response",
            "PlayerWatcher_InviteFrd_Request",
            "PlayerWatcher_InviteFrd_Response",
            "PlayerWatcher_OnlineFrdList_Request",
            "PlayerWatcher_OnlineFrdList_Response",
            "PlayerWatcher_FrdList_Request",
            "PlayerWatcher_FrdList_Response",
            "PlayerWatcher_IdentifyFrd_Request",
            "PlayerWatcher_IdentifyFrd_Response",
            "PlayerWatcher_KickOffInfo_Request",
            "PlayerWatcher_KickOffInfo_Response",
            "PlayerWatcher_ResetPotInfo_Request",
            "PlayerWatcher_ResetPotInfo_Response",
            "PlayerWatcher_Ping_Request",
            "PlayerWatcher_Ping_Response",
            "PlayerWatcher_Gm_Request",
            "PlayerWatcher_Gm_Reponse",
        },
        handlers = {
            {"Register", "PlayerWatcher_Register_Request", "PlayerWatcher_Register_Response"},
            {"Deregister", "PlayerWatcher_Deregister_Request", "PlayerWatcher_Deregister_Response"},
            {"HeartBeat", "PlayerWatcher_HeartBeat_Request", "PlayerWatcher_HeartBeat_Response"},
            {"GetAttachments", "PlayerWatcher_GetAttachments_Request", "PlayerWatcher_GetAttachments_Response"},
            {"GetGoods", "PlayerWatcher_GetGoods_Request", "PlayerWatcher_GetGoods_Response"},
            {"OptLog", "PlayerWatcher_OptLog_Request", "PlayerWatcher_OptLog_Response"},
            {"Push", "PlayerWatcher_Push_Request", "PlayerWatcher_Push_Response"},
            {"DropBanned", "PlayerWatcher_DropBanned_Request", "PlayerWatcher_DropBanned_Response"},
            {"SendChips", "PlayerWatcher_SendChips_Request", "PlayerWatcher_SendChips_Response"},
            {"Hotfix", "PlayerWatcher_Hotfix_Request", "PlayerWatcher_Hotfix_Response"},
            {"ClubKickOut", "PlayerWatcher_ClubKickOut_Request", "PlayerWatcher_ClubKickOut_Response"},
            {"ClubApprove", "PlayerWatcher_ClubApprove_Request", "PlayerWatcher_ClubApprove_Response"},
            {"ClubReject", "PlayerWatcher_ClubReject_Request", "PlayerWatcher_ClubReject_Response"},
            {"ClubPromote", "PlayerWatcher_ClubPromote_Request", "PlayerWatcher_ClubPromote_Response"},
            {"ClubDemote", "PlayerWatcher_ClubDemote_Request", "PlayerWatcher_ClubDemote_Response"},
            {"Replaced", "PlayerWatcher_Replaced_Request", "PlayerWatcher_Replaced_Response"},
            {"BindFacebook", "PlayerWatcher_BindFacebook_Request", "PlayerWatcher_BindFacebook_Response"},
            {"BindPlayerInfo", "PlayerWatcher_BindPlayerInfo_Request", "PlayerWatcher_BindPlayerInfo_Response"},
            {"VersionAward", "PlayerWatcher_VersionAward_Request", "PlayerWatcher_VersionAward_Response"},
            {"ClearTriggerTimes", "PlayerWatcher_ClearTriggerTimes_Request", "PlayerWatcher_ClearTriggerTimes_Response"},
            {"SetBackground", "PlayerWatcher_SetBackground_Request", "PlayerWatcher_SetBackground_Response"},
            {"FrdInfo", "PlayerWatcher_FrdInfo_Request", "PlayerWatcher_FrdInfo_Response"},
            {"InviteFrd", "PlayerWatcher_InviteFrd_Request", "PlayerWatcher_InviteFrd_Response"},
            {"OnlineFrdList", "PlayerWatcher_OnlineFrdList_Request", "PlayerWatcher_OnlineFrdList_Response"},
            {"FrdList", "PlayerWatcher_FrdList_Request", "PlayerWatcher_FrdList_Response"},
            {"IdentifyFrd", "PlayerWatcher_IdentifyFrd_Request", "PlayerWatcher_IdentifyFrd_Response"},
            {"KickOffInfo", "PlayerWatcher_KickOffInfo_Request", "PlayerWatcher_KickOffInfo_Response"},
            {"ResetPotInfo", "PlayerWatcher_ResetPotInfo_Request", "PlayerWatcher_ResetPotInfo_Response"},
            {"Ping", "PlayerWatcher_Ping_Request", "PlayerWatcher_Ping_Response"},
            {"Gm", "PlayerWatcher_Gm_Request", "PlayerWatcher_Gm_Reponse"},
        }
    },
    {
        id = 202,
        name = "Command",
        messages = {
            "Command_Drop_Request",
            "Command_Drop_Response",
            "Command_FinishDrop_Request",
            "Command_FinishDrop_Response",
            "Command_GetAttachments_Request",
            "Command_GetAttachments_Response",
            "Command_GetGoods_Request",
            "Command_GetGoods_Response",
            "Command_Player_Notice",
            "Command_Expire_Request",
            "Command_Expire_Response",
            "Command_GetGoods_Notice",
            "Command_GetAttachments_Notice",
            "Command_OptLog_Request",
            "Command_OptLog_Response",
            "Command_Broadcast_Request",
            "Command_Broadcast_Response",
            "Command_GetSendChips_Request",
            "Command_GetSendChips_Response",
            "Command_GetSendChips_Notice",
            "Command_Hotfix_Request",
            "Command_Hotfix_Response",
            "Command_Replaced_Request",
            "Command_Replaced_Response",
            "Command_Replaced_Notice",
            "Command_BindFacebook_Request",
            "Command_BindFacebook_Response",
            "Command_BindPlayerInfo_Request",
            "Command_BindPlayerInfo_Response",
            "Command_ClearTriggerTimes_Request",
            "Command_ClearTriggerTimes_Response",
            "Command_InviteFrd_Request",
            "Command_InviteFrd_Response",
            "Command_InviteFrd_Notice",
            "Command_FrdList_Request",
            "Command_FrdList_Response",
            "Command_FrdList_Notice",
            "Command_Notice_Drop_Request",
            "Command_Notice_Drop_Response",
            "Command_AddFriend_Notice",
            "Command_ResetPotInfo_Request",
            "Command_ResetPotInfo_Response",
            "Command_DailyMissions_Request",
            "Command_DailyMissions_Response",
            "Command_Gm_Request",
            "Command_Gm_Response",
        },
        handlers = {
            {"Drop", "Command_Drop_Request", "Command_Drop_Response"},
            {"FinishDrop", "Command_FinishDrop_Request", "Command_FinishDrop_Response"},
            {
                "GetAttachments",
                "Command_GetAttachments_Request",
                "Command_GetAttachments_Response",
                "Command_Player_Notice"
            },
            {"GetGoods", "Command_GetGoods_Request", "Command_GetGoods_Response", "Command_Player_Notice"},
            {"Expire", "Command_Expire_Request", "Command_Expire_Response"},
            {"OptLog", "Command_OptLog_Request", "Command_OptLog_Response"},
            {"Broadcast", "Command_Broadcast_Request", "Command_Broadcast_Response"},
            {"GetSendChips", "Command_GetSendChips_Request", "Command_GetSendChips_Response"},
            {"Hotfix", "Command_Hotfix_Request", "Command_Hotfix_Response"},
            {"Replaced", "Command_Replaced_Request", "Command_Replaced_Response"},
            {"BindFacebook", "Command_BindFacebook_Request", "Command_BindFacebook_Response"},
            {"BindPlayerInfo", "Command_BindPlayerInfo_Request", "Command_BindPlayerInfo_Response"},
            {"InviteFrd", "Command_InviteFrd_Request", "Command_InviteFrd_Response", "Command_InviteFrd_Notice"},
            {"ClearTriggerTimes", "Command_ClearTriggerTimes_Request", "Command_ClearTriggerTimes_Response"},
            {"FrdList", "Command_FrdList_Request", "Command_FrdList_Response", "Command_FrdList_Notice"},
            {"Notice_Drop", "Command_Notice_Drop_Request", "Command_Notice_Drop_Response"},
            {"ResetPotInfo", "Command_ResetPotInfo_Request", "Command_ResetPotInfo_Response"},
            {"Gm", "Command_Gm_Request", "Command_Gm_Response"},
            {"DailyMissions", "Command_DailyMissions_Request", "Command_DailyMissions_Response"}
        }
    },
    {
        id = 203,
        name = "Rank",
        messages = {
            "Rank_Challenge_Request",
            "Rank_Challenge_Response"
        },
        handlers = {
            {"Challenge", "Rank_Challenge_Request", "Rank_Challenge_Response"}
        }
    },
    {
        id = 204,
        name = "Mail",
        messages = {--以下全是新增邮件
            "Mail_Present_Request",
            "Mail_Present_Response",
            "Mail_AutoFetch_Request",
            "Mail_AutoFetch_Response",
            "Mail_NoticeFetch_Request",
            "Mail_NoticeFetch_Response",
            "Mail_SendChips_Request",
            "Mail_SendChips_Response",
            "Mail_BindFacebook_Request",
            "Mail_BindFacebook_Response",
            "Mail_VersionAward_Request",
            "Mail_VersionAward_Response",
            "Mail_TournamentPrize_Request",
            "Mail_TournamentPrize_Response",

            "Mail_FeverQuestPrizeCardPackage_Request",
            "Mail_FeverQuestPrizeCardPackage_Response",
            "Mail_FeverQuestPrizeCoin_Request",
            "Mail_FeverQuestPrizeCoin_Response",
            "Mail_FeverQuestPrizeVipPoint_Request",
            "Mail_FeverQuestPrizeVipPoint_Response",

            "Mail_DailyBonusAward_Request",
            "Mail_DailyBonusAward_Response",

            "Mail_BoosterCashback_Request",
            "Mail_BoosterCashback_Response",
        },
        handlers = {
            {"Present", "Mail_Present_Request", "Mail_Present_Response"},
            {"AutoFetch", "Mail_AutoFetch_Request", "Mail_AutoFetch_Response"},
            {"NoticeFetch", "Mail_NoticeFetch_Request", "Mail_NoticeFetch_Response"},
            {"SendChips", "Mail_SendChips_Request", "Mail_SendChips_Response"},
            {"BindFacebook", "Mail_BindFacebook_Request", "Mail_BindFacebook_Response"},
            {"VersionAward", "Mail_VersionAward_Request", "Mail_VersionAward_Response"},
            {"TournamentPrize", "Mail_TournamentPrize_Request", "Mail_TournamentPrize_Response"},

            {"FeverQuestPrizeCardPackage", "Mail_FeverQuestPrizeCardPackage_Request", "Mail_FeverQuestPrizeCardPackage_Response"},
            {"FeverQuestPrizeCoin", "Mail_FeverQuestPrizeCoin_Request", "Mail_FeverQuestPrizeCoin_Response"},
            {"FeverQuestPrizeVipPoint", "Mail_FeverQuestPrizeVipPoint_Request", "Mail_FeverQuestPrizeVipPoint_Response"},

            {"DailyBonusAward", "Mail_DailyBonusAward_Request", "Mail_DailyBonusAward_Response"},
            {"BoosterCashback", "Mail_BoosterCashback_Request", "Mail_BoosterCashback_Response"},
        }
    },
    {
        id = 205,
        name = "UniqueResource",
        messages = {
            "UniqueResource_GetRandom_Request",
            "UniqueResource_GetRandom_Response",
            "UniqueResource_GetGlobalState_Request",
            "UniqueResource_GetGlobalState_Response"
        },
        handlers = {
            {"GetRandom", "UniqueResource_GetRandom_Request", "UniqueResource_GetRandom_Response"},
            {"GetGlobalState", "UniqueResource_GetGlobalState_Request", "UniqueResource_GetGlobalState_Response"}
        }
    },
    {
        id = 206,
        name = "SlotsOpenSesameContest",
        messages = {
            "SlotsOpenSesameContest_Enter_Request",
            "SlotsOpenSesameContest_Enter_Response",
            "SlotsOpenSesameContest_Enter_Notice",
            "SlotsOpenSesameContest_Exit_Request",
            "SlotsOpenSesameContest_Exit_Response",
            "SlotsOpenSesameContest_Exit_Notice",
            "SlotsOpenSesameContest_Offline_Request",
            "SlotsOpenSesameContest_Offline_Response",
            "SlotsOpenSesameContest_Offline_Notice",
            "SlotsOpenSesameContest_Hotfix_Request",
            "SlotsOpenSesameContest_Hotfix_Response"
        },
        handlers = {
            {
                "Enter",
                "SlotsOpenSesameContest_Enter_Request",
                "SlotsOpenSesameContest_Enter_Response",
                "SlotsOpenSesameContest_Enter_Notice"
            },
            {
                "Exit",
                "SlotsOpenSesameContest_Exit_Request",
                "SlotsOpenSesameContest_Exit_Response",
                "SlotsOpenSesameContest_Exit_Notice"
            },
            {
                "Offline",
                "SlotsOpenSesameContest_Offline_Request",
                "SlotsOpenSesameContest_Offline_Response",
                "SlotsOpenSesameContest_Offline_Notice"
            },
            {"Hotfix", "SlotsOpenSesameContest_Hotfix_Request", "SlotsOpenSesameContest_Hotfix_Response"}
        }
    },
    {
        id = 207,
        name = "SlotsDragonTaleContest",
        messages = {
            "SlotsDragonTaleContest_Enter_Request",
            "SlotsDragonTaleContest_Enter_Response",
            "SlotsDragonTaleContest_Enter_Notice",
            "SlotsDragonTaleContest_Exit_Request",
            "SlotsDragonTaleContest_Exit_Response",
            "SlotsDragonTaleContest_Exit_Notice",
            "SlotsDragonTaleContest_Offline_Request",
            "SlotsDragonTaleContest_Offline_Response",
            "SlotsDragonTaleContest_Offline_Notice",
            "SlotsDragonTaleContest_Hotfix_Request",
            "SlotsDragonTaleContest_Hotfix_Response"
        },
        handlers = {
            {
                "Enter",
                "SlotsDragonTaleContest_Enter_Request",
                "SlotsDragonTaleContest_Enter_Response",
                "SlotsDragonTaleContest_Enter_Notice"
            },
            {
                "Exit",
                "SlotsDragonTaleContest_Exit_Request",
                "SlotsDragonTaleContest_Exit_Response",
                "SlotsDragonTaleContest_Exit_Notice"
            },
            {
                "Offline",
                "SlotsDragonTaleContest_Offline_Request",
                "SlotsDragonTaleContest_Offline_Response",
                "SlotsDragonTaleContest_Offline_Notice"
            },
            {"Hotfix", "SlotsDragonTaleContest_Hotfix_Request", "SlotsDragonTaleContest_Hotfix_Response"}
        }
    },
    {
        id = 208,
        name = "SlotsForbiddenCityContest",
        messages = {
            "SlotsForbiddenCityContest_Enter_Request",
            "SlotsForbiddenCityContest_Enter_Response",
            "SlotsForbiddenCityContest_Enter_Notice",
            "SlotsForbiddenCityContest_Exit_Request",
            "SlotsForbiddenCityContest_Exit_Response",
            "SlotsForbiddenCityContest_Exit_Notice",
            "SlotsForbiddenCityContest_Offline_Request",
            "SlotsForbiddenCityContest_Offline_Response",
            "SlotsForbiddenCityContest_Offline_Notice",
            "SlotsForbiddenCityContest_Hotfix_Request",
            "SlotsForbiddenCityContest_Hotfix_Response"
        },
        handlers = {
            {
                "Enter",
                "SlotsForbiddenCityContest_Enter_Request",
                "SlotsForbiddenCityContest_Enter_Response",
                "SlotsForbiddenCityContest_Enter_Notice"
            },
            {
                "Exit",
                "SlotsForbiddenCityContest_Exit_Request",
                "SlotsForbiddenCityContest_Exit_Response",
                "SlotsForbiddenCityContest_Exit_Notice"
            },
            {
                "Offline",
                "SlotsForbiddenCityContest_Offline_Request",
                "SlotsForbiddenCityContest_Offline_Response",
                "SlotsForbiddenCityContest_Offline_Notice"
            },
            {"Hotfix", "SlotsForbiddenCityContest_Hotfix_Request", "SlotsForbiddenCityContest_Hotfix_Response"}
        }
    },
    {
        id = 209,
        name = "SlotsVampireContest",
        messages = {
            "SlotsVampireContest_Enter_Request",
            "SlotsVampireContest_Enter_Response",
            "SlotsVampireContest_Enter_Notice",
            "SlotsVampireContest_Exit_Request",
            "SlotsVampireContest_Exit_Response",
            "SlotsVampireContest_Exit_Notice",
            "SlotsVampireContest_Offline_Request",
            "SlotsVampireContest_Offline_Response",
            "SlotsVampireContest_Offline_Notice",
            "SlotsVampireContest_Hotfix_Request",
            "SlotsVampireContest_Hotfix_Response"
        },
        handlers = {
            {
                "Enter",
                "SlotsVampireContest_Enter_Request",
                "SlotsVampireContest_Enter_Response",
                "SlotsVampireContest_Enter_Notice"
            },
            {
                "Exit",
                "SlotsVampireContest_Exit_Request",
                "SlotsVampireContest_Exit_Response",
                "SlotsVampireContest_Exit_Notice"
            },
            {
                "Offline",
                "SlotsVampireContest_Offline_Request",
                "SlotsVampireContest_Offline_Response",
                "SlotsVampireContest_Offline_Notice"
            },
            {"Hotfix", "SlotsVampireContest_Hotfix_Request", "SlotsVampireContest_Hotfix_Response"}
        }
    },
    {
        id = 210,
        name = "PushNotice",
        messages = {
            "PushNotice_SettleTournament_Request",
            "PushNotice_SettleTournament_Response",
            "PushNotice_FinishChallenge_Request",
            "PushNotice_FinishChallenge_Response"
        },
        handlers = {
            {"SettleTournament", "PushNotice_SettleTournament_Request", "PushNotice_SettleTournament_Response"},
            {"FinishChallenge", "PushNotice_FinishChallenge_Request", "PushNotice_FinishChallenge_Response"}
        }
    },
    {
        id = 211,
        name = "SlotsFruitSliceContest",
        messages = {
            "SlotsFruitSliceContest_Enter_Request",
            "SlotsFruitSliceContest_Enter_Response",
            "SlotsFruitSliceContest_Enter_Notice",
            "SlotsFruitSliceContest_Exit_Request",
            "SlotsFruitSliceContest_Exit_Response",
            "SlotsFruitSliceContest_Exit_Notice",
            "SlotsFruitSliceContest_Offline_Request",
            "SlotsFruitSliceContest_Offline_Response",
            "SlotsFruitSliceContest_Offline_Notice",
            "SlotsFruitSliceContest_Hotfix_Request",
            "SlotsFruitSliceContest_Hotfix_Response",
            "SlotsFruitSliceContest_Start_Request",
            "SlotsFruitSliceContest_Start_Response",
            "SlotsFruitSliceContest_Slice_Request", --切水果请求
            "SlotsFruitSliceContest_Slice_Response",
            "SlotsFruitSliceContest_StateSync_Notice", --小游戏当前状态
            "SlotsFruitSliceContest_Fruit_Notice", --通知水果来了
            "SlotsFruitSliceContest_FruitSliced_Notice", --同步玩家切的水果
            "SlotsFruitSliceContest_Bonus_Notice", --bonus
            "SlotsFruitSliceContest_PlayerScore_Notice" --同步玩家分数
        },
        handlers = {
            {
                "Enter",
                "SlotsFruitSliceContest_Enter_Request",
                "SlotsFruitSliceContest_Enter_Response",
                "SlotsFruitSliceContest_Enter_Notice"
            },
            {
                "Exit",
                "SlotsFruitSliceContest_Exit_Request",
                "SlotsFruitSliceContest_Exit_Response",
                "SlotsFruitSliceContest_Exit_Notice"
            },
            {
                "Offline",
                "SlotsFruitSliceContest_Offline_Request",
                "SlotsFruitSliceContest_Offline_Response",
                "SlotsFruitSliceContest_Offline_Notice"
            },
            {"Hotfix", "SlotsFruitSliceContest_Hotfix_Request", "SlotsFruitSliceContest_Hotfix_Response"},
            {"Start", "SlotsFruitSliceContest_Start_Request", "SlotsFruitSliceContest_Start_Response"},
            {"Slice", "SlotsFruitSliceContest_Slice_Request", "SlotsFruitSliceContest_Slice_Response"}
        }
    },
    {
        id = 212,
        name = "SlotsPharaohTreasureContest",
        messages = {
            "SlotsPharaohTreasureContest_Enter_Request",
            "SlotsPharaohTreasureContest_Enter_Response",
            "SlotsPharaohTreasureContest_Enter_Notice",
            "SlotsPharaohTreasureContest_Exit_Request",
            "SlotsPharaohTreasureContest_Exit_Response",
            "SlotsPharaohTreasureContest_Exit_Notice",
            "SlotsPharaohTreasureContest_Offline_Request",
            "SlotsPharaohTreasureContest_Offline_Response",
            "SlotsPharaohTreasureContest_Offline_Notice",
            "SlotsPharaohTreasureContest_Hotfix_Request",
            "SlotsPharaohTreasureContest_Hotfix_Response"
        },
        handlers = {
            {
                "Enter",
                "SlotsPharaohTreasureContest_Enter_Request",
                "SlotsPharaohTreasureContest_Enter_Response",
                "SlotsPharaohTreasureContest_Enter_Notice"
            },
            {
                "Exit",
                "SlotsPharaohTreasureContest_Exit_Request",
                "SlotsPharaohTreasureContest_Exit_Response",
                "SlotsPharaohTreasureContest_Exit_Notice"
            },
            {
                "Offline",
                "SlotsPharaohTreasureContest_Offline_Request",
                "SlotsPharaohTreasureContest_Offline_Response",
                "SlotsPharaohTreasureContest_Offline_Notice"
            },
            {"Hotfix", "SlotsPharaohTreasureContest_Hotfix_Request", "SlotsPharaohTreasureContest_Hotfix_Response"}
        }
    },
    {
        id = 213,
        name = "SlotsElvesEpicContest",
        messages = {
            "SlotsElvesEpicContest_Enter_Request",
            "SlotsElvesEpicContest_Enter_Response",
            "SlotsElvesEpicContest_Enter_Notice",
            "SlotsElvesEpicContest_Exit_Request",
            "SlotsElvesEpicContest_Exit_Response",
            "SlotsElvesEpicContest_Exit_Notice",
            "SlotsElvesEpicContest_Offline_Request",
            "SlotsElvesEpicContest_Offline_Response",
            "SlotsElvesEpicContest_Offline_Notice",
            "SlotsElvesEpicContest_Jackpot_Request",
            "SlotsElvesEpicContest_Jackpot_Response",
            "SlotsElvesEpicContest_Award_Request",
            "SlotsElvesEpicContest_Award_Response"
        },
        handlers = {
            {
                "Enter",
                "SlotsElvesEpicContest_Enter_Request",
                "SlotsElvesEpicContest_Enter_Response",
                "SlotsElvesEpicContest_Enter_Notice"
            },
            {
                "Exit",
                "SlotsElvesEpicContest_Exit_Request",
                "SlotsElvesEpicContest_Exit_Response",
                "SlotsElvesEpicContest_Exit_Notice"
            },
            {
                "Offline",
                "SlotsElvesEpicContest_Offline_Request",
                "SlotsElvesEpicContest_Offline_Response",
                "SlotsElvesEpicContest_Offline_Notice"
            },
            {"Jackpot", "SlotsElvesEpicContest_Jackpot_Request", "SlotsElvesEpicContest_Jackpot_Response"},
            {"Award", "SlotsElvesEpicContest_Award_Request", "SlotsElvesEpicContest_Award_Response"}
        }
    },
    {
        id = 214,
        name = "SlotsHalloweenNightContest",
        messages = {
            "SlotsHalloweenNightContest_Enter_Request",
            "SlotsHalloweenNightContest_Enter_Response",
            "SlotsHalloweenNightContest_Enter_Notice",
            "SlotsHalloweenNightContest_Exit_Request",
            "SlotsHalloweenNightContest_Exit_Response",
            "SlotsHalloweenNightContest_Exit_Notice",
            "SlotsHalloweenNightContest_Offline_Request",
            "SlotsHalloweenNightContest_Offline_Response",
            "SlotsHalloweenNightContest_Offline_Notice",
            "SlotsHalloweenNightContest_Hotfix_Request",
            "SlotsHalloweenNightContest_Hotfix_Response"
        },
        handlers = {
            {
                "Enter",
                "SlotsHalloweenNightContest_Enter_Request",
                "SlotsHalloweenNightContest_Enter_Response",
                "SlotsHalloweenNightContest_Enter_Notice"
            },
            {
                "Exit",
                "SlotsHalloweenNightContest_Exit_Request",
                "SlotsHalloweenNightContest_Exit_Response",
                "SlotsHalloweenNightContest_Exit_Notice"
            },
            {
                "Offline",
                "SlotsHalloweenNightContest_Offline_Request",
                "SlotsHalloweenNightContest_Offline_Response",
                "SlotsHalloweenNightContest_Offline_Notice"
            },
            {"Hotfix", "SlotsHalloweenNightContest_Hotfix_Request", "SlotsHalloweenNightContest_Hotfix_Response"}
        }
    },
    {
        id = 215,
        name = "SlotsAliceinWonderlandContest",
        messages = {
            "SlotsAliceinWonderlandContest_Enter_Request",
            "SlotsAliceinWonderlandContest_Enter_Response",
            "SlotsAliceinWonderlandContest_Enter_Notice",
            "SlotsAliceinWonderlandContest_Exit_Request",
            "SlotsAliceinWonderlandContest_Exit_Response",
            "SlotsAliceinWonderlandContest_Exit_Notice",
            "SlotsAliceinWonderlandContest_Offline_Request",
            "SlotsAliceinWonderlandContest_Offline_Response",
            "SlotsAliceinWonderlandContest_Offline_Notice",
            "SlotsAliceinWonderlandContest_Jackpot_Request",
            "SlotsAliceinWonderlandContest_Jackpot_Response",
            "SlotsAliceinWonderlandContest_Award_Request",
            "SlotsAliceinWonderlandContest_Award_Response"
        },
        handlers = {
            {
                "Enter",
                "SlotsAliceinWonderlandContest_Enter_Request",
                "SlotsAliceinWonderlandContest_Enter_Response",
                "SlotsAliceinWonderlandContest_Enter_Notice"
            },
            {
                "Exit",
                "SlotsAliceinWonderlandContest_Exit_Request",
                "SlotsAliceinWonderlandContest_Exit_Response",
                "SlotsAliceinWonderlandContest_Exit_Notice"
            },
            {
                "Offline",
                "SlotsAliceinWonderlandContest_Offline_Request",
                "SlotsAliceinWonderlandContest_Offline_Response",
                "SlotsAliceinWonderlandContest_Offline_Notice"
            },
            {
                "Jackpot",
                "SlotsAliceinWonderlandContest_Jackpot_Request",
                "SlotsAliceinWonderlandContest_Jackpot_Response"
            },
            {"Award", "SlotsAliceinWonderlandContest_Award_Request", "SlotsAliceinWonderlandContest_Award_Response"}
        }
    },
    {
        id = 216,
        name = "SlotsPirateContest",
        messages = {
            "SlotsPirateContest_Enter_Request",
            "SlotsPirateContest_Enter_Response",
            "SlotsPirateContest_Enter_Notice",
            "SlotsPirateContest_Exit_Request",
            "SlotsPirateContest_Exit_Response",
            "SlotsPirateContest_Exit_Notice",
            "SlotsPirateContest_Offline_Request",
            "SlotsPirateContest_Offline_Response",
            "SlotsPirateContest_Offline_Notice",
            "SlotsPirateContest_Slots_Request",
            "SlotsPirateContest_Slots_Response"
        },
        handlers = {
            {
                "Enter",
                "SlotsPirateContest_Enter_Request",
                "SlotsPirateContest_Enter_Response",
                "SlotsPirateContest_Enter_Notice"
            },
            {
                "Exit",
                "SlotsPirateContest_Exit_Request",
                "SlotsPirateContest_Exit_Response",
                "SlotsPirateContest_Exit_Notice"
            },
            {
                "Offline",
                "SlotsPirateContest_Offline_Request",
                "SlotsPirateContest_Offline_Response",
                "SlotsPirateContest_Offline_Notice"
            },
            {"Slots", "SlotsPirateContest_Slots_Request", "SlotsPirateContest_Slots_Response"}
        }
    },
    {
        id = 217,
        name = "SlotsSantaSupriseContest",
        messages = {
            "SlotsSantaSupriseContest_Enter_Request",
            "SlotsSantaSupriseContest_Enter_Response",
            "SlotsSantaSupriseContest_Enter_Notice",
            "SlotsSantaSupriseContest_Exit_Request",
            "SlotsSantaSupriseContest_Exit_Response",
            "SlotsSantaSupriseContest_Exit_Notice",
            "SlotsSantaSupriseContest_Offline_Request",
            "SlotsSantaSupriseContest_Offline_Response",
            "SlotsSantaSupriseContest_Offline_Notice"
        },
        handlers = {
            {
                "Enter",
                "SlotsSantaSupriseContest_Enter_Request",
                "SlotsSantaSupriseContest_Enter_Response",
                "SlotsSantaSupriseContest_Enter_Notice"
            },
            {
                "Exit",
                "SlotsSantaSupriseContest_Exit_Request",
                "SlotsSantaSupriseContest_Exit_Response",
                "SlotsSantaSupriseContest_Exit_Notice"
            },
            {
                "Offline",
                "SlotsSantaSupriseContest_Offline_Request",
                "SlotsSantaSupriseContest_Offline_Response",
                "SlotsSantaSupriseContest_Offline_Notice"
            }
        }
    },
    {
        id = 218,
        name = "SlotsBacktoJurassicContest",
        messages = {
            "SlotsBacktoJurassicContest_Enter_Request",
            "SlotsBacktoJurassicContest_Enter_Response",
            "SlotsBacktoJurassicContest_Enter_Notice",
            "SlotsBacktoJurassicContest_Exit_Request",
            "SlotsBacktoJurassicContest_Exit_Response",
            "SlotsBacktoJurassicContest_Exit_Notice",
            "SlotsBacktoJurassicContest_Offline_Request",
            "SlotsBacktoJurassicContest_Offline_Response",
            "SlotsBacktoJurassicContest_Offline_Notice"
        },
        handlers = {
            {
                "Enter",
                "SlotsBacktoJurassicContest_Enter_Request",
                "SlotsBacktoJurassicContest_Enter_Response",
                "SlotsBacktoJurassicContest_Enter_Notice"
            },
            {
                "Exit",
                "SlotsBacktoJurassicContest_Exit_Request",
                "SlotsBacktoJurassicContest_Exit_Response",
                "SlotsBacktoJurassicContest_Exit_Notice"
            },
            {
                "Offline",
                "SlotsBacktoJurassicContest_Offline_Request",
                "SlotsBacktoJurassicContest_Offline_Response",
                "SlotsBacktoJurassicContest_Offline_Notice"
            }
        }
    },
    {
        id = 219,
        name = "CustomerServicePasser",
        messages = {
            "CustomerServicePasser_CustomerSay_Request",
            "CustomerServicePasser_CustomerSay_Response",
            "CustomerServicePasser_StaffSay_Request",
            "CustomerServicePasser_StaffSay_Response"
        },
        handlers = {
            {"CustomerSay", "CustomerServicePasser_CustomerSay_Request", "CustomerServicePasser_CustomerSay_Response"},
            {"StaffSay", "CustomerServicePasser_StaffSay_Request", "CustomerServicePasser_StaffSay_Response"}
        }
    },
    {
        id = 220,
        name = "SlotsChefsChoiceContest",
        messages = {
            "SlotsChefsChoiceContest_Enter_Request",
            "SlotsChefsChoiceContest_Enter_Response",
            "SlotsChefsChoiceContest_Enter_Notice",
            "SlotsChefsChoiceContest_Exit_Request",
            "SlotsChefsChoiceContest_Exit_Response",
            "SlotsChefsChoiceContest_Exit_Notice",
            "SlotsChefsChoiceContest_Offline_Request",
            "SlotsChefsChoiceContest_Offline_Response",
            "SlotsChefsChoiceContest_Offline_Notice"
        },
        handlers = {
            {
                "Enter",
                "SlotsChefsChoiceContest_Enter_Request",
                "SlotsChefsChoiceContest_Enter_Response",
                "SlotsChefsChoiceContest_Enter_Notice"
            },
            {
                "Exit",
                "SlotsChefsChoiceContest_Exit_Request",
                "SlotsChefsChoiceContest_Exit_Response",
                "SlotsChefsChoiceContest_Exit_Notice"
            },
            {
                "Offline",
                "SlotsChefsChoiceContest_Offline_Request",
                "SlotsChefsChoiceContest_Offline_Response",
                "SlotsChefsChoiceContest_Offline_Notice"
            }
        }
    },
    {
        id = 221,
        name = "SlotsWildCircusContest",
        messages = {
            "SlotsWildCircusContest_Enter_Request",
            "SlotsWildCircusContest_Enter_Response",
            "SlotsWildCircusContest_Enter_Notice",
            "SlotsWildCircusContest_Exit_Request",
            "SlotsWildCircusContest_Exit_Response",
            "SlotsWildCircusContest_Exit_Notice",
            "SlotsWildCircusContest_Offline_Request",
            "SlotsWildCircusContest_Offline_Response",
            "SlotsWildCircusContest_Offline_Notice"
        },
        handlers = {
            {
                "Enter",
                "SlotsWildCircusContest_Enter_Request",
                "SlotsWildCircusContest_Enter_Response",
                "SlotsWildCircusContest_Enter_Notice"
            },
            {
                "Exit",
                "SlotsWildCircusContest_Exit_Request",
                "SlotsWildCircusContest_Exit_Response",
                "SlotsWildCircusContest_Exit_Notice"
            },
            {
                "Offline",
                "SlotsWildCircusContest_Offline_Request",
                "SlotsWildCircusContest_Offline_Response",
                "SlotsWildCircusContest_Offline_Notice"
            }
        }
    },
    {
        id = 222,
        name = "SlotsAgentBondContest",
        messages = {
            "SlotsAgentBondContest_Enter_Request",
            "SlotsAgentBondContest_Enter_Response",
            "SlotsAgentBondContest_Enter_Notice",
            "SlotsAgentBondContest_Exit_Request",
            "SlotsAgentBondContest_Exit_Response",
            "SlotsAgentBondContest_Exit_Notice",
            "SlotsAgentBondContest_Offline_Request",
            "SlotsAgentBondContest_Offline_Response",
            "SlotsAgentBondContest_Offline_Notice",
            "SlotsAgentBondContest_Slots_Request",
            "SlotsAgentBondContest_Slots_Response"
        },
        handlers = {
            {
                "Enter",
                "SlotsAgentBondContest_Enter_Request",
                "SlotsAgentBondContest_Enter_Response",
                "SlotsAgentBondContest_Enter_Notice"
            },
            {
                "Exit",
                "SlotsAgentBondContest_Exit_Request",
                "SlotsAgentBondContest_Exit_Response",
                "SlotsAgentBondContest_Exit_Notice"
            },
            {
                "Offline",
                "SlotsAgentBondContest_Offline_Request",
                "SlotsAgentBondContest_Offline_Response",
                "SlotsAgentBondContest_Offline_Notice"
            },
            {"Slots", "SlotsAgentBondContest_Slots_Request", "SlotsAgentBondContest_Slots_Response"}
        }
    },
    {
        id = 223,
        name = "SlotsLegendsofOlympusContest",
        messages = {
            "SlotsLegendsofOlympusContest_Enter_Request",
            "SlotsLegendsofOlympusContest_Enter_Response",
            "SlotsLegendsofOlympusContest_Enter_Notice",
            "SlotsLegendsofOlympusContest_Exit_Request",
            "SlotsLegendsofOlympusContest_Exit_Response",
            "SlotsLegendsofOlympusContest_Exit_Notice",
            "SlotsLegendsofOlympusContest_Offline_Request",
            "SlotsLegendsofOlympusContest_Offline_Response",
            "SlotsLegendsofOlympusContest_Offline_Notice"
        },
        handlers = {
            {
                "Enter",
                "SlotsLegendsofOlympusContest_Enter_Request",
                "SlotsLegendsofOlympusContest_Enter_Response",
                "SlotsLegendsofOlympusContest_Enter_Notice"
            },
            {
                "Exit",
                "SlotsLegendsofOlympusContest_Exit_Request",
                "SlotsLegendsofOlympusContest_Exit_Response",
                "SlotsLegendsofOlympusContest_Exit_Notice"
            },
            {
                "Offline",
                "SlotsLegendsofOlympusContest_Offline_Request",
                "SlotsLegendsofOlympusContest_Offline_Response",
                "SlotsLegendsofOlympusContest_Offline_Notice"
            }
        }
    },
    {
        id = 224,
        name = "SlotsChineseNewYearContest",
        messages = {
            "SlotsChineseNewYearContest_Enter_Request",
            "SlotsChineseNewYearContest_Enter_Response",
            "SlotsChineseNewYearContest_Enter_Notice",
            "SlotsChineseNewYearContest_Exit_Request",
            "SlotsChineseNewYearContest_Exit_Response",
            "SlotsChineseNewYearContest_Exit_Notice",
            "SlotsChineseNewYearContest_Offline_Request",
            "SlotsChineseNewYearContest_Offline_Response",
            "SlotsChineseNewYearContest_Offline_Notice"
        },
        handlers = {
            {
                "Enter",
                "SlotsChineseNewYearContest_Enter_Request",
                "SlotsChineseNewYearContest_Enter_Response",
                "SlotsChineseNewYearContest_Enter_Notice"
            },
            {
                "Exit",
                "SlotsChineseNewYearContest_Exit_Request",
                "SlotsChineseNewYearContest_Exit_Response",
                "SlotsChineseNewYearContest_Exit_Notice"
            },
            {
                "Offline",
                "SlotsChineseNewYearContest_Offline_Request",
                "SlotsChineseNewYearContest_Offline_Response",
                "SlotsChineseNewYearContest_Offline_Notice"
            }
        }
    },
    {
        id = 225,
        name = "SlotsBruceLeeContest",
        messages = {
            "SlotsBruceLeeContest_Enter_Request",
            "SlotsBruceLeeContest_Enter_Response",
            "SlotsBruceLeeContest_Enter_Notice",
            "SlotsBruceLeeContest_Exit_Request",
            "SlotsBruceLeeContest_Exit_Response",
            "SlotsBruceLeeContest_Exit_Notice",
            "SlotsBruceLeeContest_Offline_Request",
            "SlotsBruceLeeContest_Offline_Response",
            "SlotsBruceLeeContest_Offline_Notice"
        },
        handlers = {
            {
                "Enter",
                "SlotsBruceLeeContest_Enter_Request",
                "SlotsBruceLeeContest_Enter_Response",
                "SlotsBruceLeeContest_Enter_Notice"
            },
            {
                "Exit",
                "SlotsBruceLeeContest_Exit_Request",
                "SlotsBruceLeeContest_Exit_Response",
                "SlotsBruceLeeContest_Exit_Notice"
            },
            {
                "Offline",
                "SlotsBruceLeeContest_Offline_Request",
                "SlotsBruceLeeContest_Offline_Response",
                "SlotsBruceLeeContest_Offline_Notice"
            }
        }
    },
    {
        id = 226,
        name = "FriendPasser",
        messages = {
            "FriendPasser_AddFriend_Request",
            "FriendPasser_AddFriend_Response"
        },
        handlers = {
            {"AddFriend", "FriendPasser_AddFriend_Request", "FriendPasser_AddFriend_Response"}
        }
    },
    {
        id = 227,
        name = "SlotsLuxuryLifeContest",
        messages = {
            "SlotsLuxuryLifeContest_Enter_Request",
            "SlotsLuxuryLifeContest_Enter_Response",
            "SlotsLuxuryLifeContest_Enter_Notice",
            "SlotsLuxuryLifeContest_Exit_Request",
            "SlotsLuxuryLifeContest_Exit_Response",
            "SlotsLuxuryLifeContest_Exit_Notice",
            "SlotsLuxuryLifeContest_Offline_Request",
            "SlotsLuxuryLifeContest_Offline_Response",
            "SlotsLuxuryLifeContest_Offline_Notice"
        },
        handlers = {
            {
                "Enter",
                "SlotsLuxuryLifeContest_Enter_Request",
                "SlotsLuxuryLifeContest_Enter_Response",
                "SlotsLuxuryLifeContest_Enter_Notice"
            },
            {
                "Exit",
                "SlotsLuxuryLifeContest_Exit_Request",
                "SlotsLuxuryLifeContest_Exit_Response",
                "SlotsLuxuryLifeContest_Exit_Notice"
            },
            {
                "Offline",
                "SlotsLuxuryLifeContest_Offline_Request",
                "SlotsLuxuryLifeContest_Offline_Response",
                "SlotsLuxuryLifeContest_Offline_Notice"
            }
        }
    },
    {
        id = 228,
        name = "SlotsCashSpinContest",
        messages = {
            "SlotsCashSpinContest_Enter_Request",
            "SlotsCashSpinContest_Enter_Response",
            "SlotsCashSpinContest_Enter_Notice",
            "SlotsCashSpinContest_Exit_Request",
            "SlotsCashSpinContest_Exit_Response",
            "SlotsCashSpinContest_Exit_Notice",
            "SlotsCashSpinContest_Offline_Request",
            "SlotsCashSpinContest_Offline_Response",
            "SlotsCashSpinContest_Offline_Notice"
        },
        handlers = {
            {
                "Enter",
                "SlotsCashSpinContest_Enter_Request",
                "SlotsCashSpinContest_Enter_Response",
                "SlotsCashSpinContest_Enter_Notice"
            },
            {
                "Exit",
                "SlotsCashSpinContest_Exit_Request",
                "SlotsCashSpinContest_Exit_Response",
                "SlotsCashSpinContest_Exit_Notice"
            },
            {
                "Offline",
                "SlotsCashSpinContest_Offline_Request",
                "SlotsCashSpinContest_Offline_Response",
                "SlotsCashSpinContest_Offline_Notice"
            }
        }
    },
    {
        id = 229,
        name = "SlotsIceAndFireContest",
        messages = {
            "SlotsIceAndFireContest_Enter_Request",
            "SlotsIceAndFireContest_Enter_Response",
            "SlotsIceAndFireContest_Enter_Notice",
            "SlotsIceAndFireContest_Exit_Request",
            "SlotsIceAndFireContest_Exit_Response",
            "SlotsIceAndFireContest_Exit_Notice",
            "SlotsIceAndFireContest_Offline_Request",
            "SlotsIceAndFireContest_Offline_Response",
            "SlotsIceAndFireContest_Offline_Notice"
        },
        handlers = {
            {
                "Enter",
                "SlotsIceAndFireContest_Enter_Request",
                "SlotsIceAndFireContest_Enter_Response",
                "SlotsIceAndFireContest_Enter_Notice"
            },
            {
                "Exit",
                "SlotsIceAndFireContest_Exit_Request",
                "SlotsIceAndFireContest_Exit_Response",
                "SlotsIceAndFireContest_Exit_Notice"
            },
            {
                "Offline",
                "SlotsIceAndFireContest_Offline_Request",
                "SlotsIceAndFireContest_Offline_Response",
                "SlotsIceAndFireContest_Offline_Notice"
            }
        }
    },
    {
        id = 230,
        name = "SlotsBroadCastContest",
        messages = {
            "SlotsBroadCastContest_Chip_Request",
            "SlotsBroadCastContest_Chip_Response",
            "SlotsBroadCastContest_Chip_Notice"
        },
        handlers = {
            {
                "Chip",
                "SlotsBroadCastContest_Chip_Request",
                "SlotsBroadCastContest_Chip_Response",
                "SlotsBroadCastContest_Chip_Notice"
            }
        }
    },
    {
        id = 231,
        name = "SlotsPurrfectPetsContest",
        messages = {
            "SlotsPurrfectPetsContest_Enter_Request",
            "SlotsPurrfectPetsContest_Enter_Response",
            "SlotsPurrfectPetsContest_Enter_Notice",
            "SlotsPurrfectPetsContest_Exit_Request",
            "SlotsPurrfectPetsContest_Exit_Response",
            "SlotsPurrfectPetsContest_Exit_Notice",
            "SlotsPurrfectPetsContest_Offline_Request",
            "SlotsPurrfectPetsContest_Offline_Response",
            "SlotsPurrfectPetsContest_Offline_Notice"
        },
        handlers = {
            {
                "Enter",
                "SlotsPurrfectPetsContest_Enter_Request",
                "SlotsPurrfectPetsContest_Enter_Response",
                "SlotsPurrfectPetsContest_Enter_Notice"
            },
            {
                "Exit",
                "SlotsPurrfectPetsContest_Exit_Request",
                "SlotsPurrfectPetsContest_Exit_Response",
                "SlotsPurrfectPetsContest_Exit_Notice"
            },
            {
                "Offline",
                "SlotsPurrfectPetsContest_Offline_Request",
                "SlotsPurrfectPetsContest_Offline_Response",
                "SlotsPurrfectPetsContest_Offline_Notice"
            }
        }
    },
    {
        id = 232,
        name = "SlotsSummerBeachContest",
        messages = {
            "SlotsSummerBeachContest_Enter_Request",
            "SlotsSummerBeachContest_Enter_Response",
            "SlotsSummerBeachContest_Enter_Notice",
            "SlotsSummerBeachContest_Exit_Request",
            "SlotsSummerBeachContest_Exit_Response",
            "SlotsSummerBeachContest_Exit_Notice",
            "SlotsSummerBeachContest_Offline_Request",
            "SlotsSummerBeachContest_Offline_Response",
            "SlotsSummerBeachContest_Offline_Notice"
        },
        handlers = {
            {
                "Enter",
                "SlotsSummerBeachContest_Enter_Request",
                "SlotsSummerBeachContest_Enter_Response",
                "SlotsSummerBeachContest_Enter_Notice"
            },
            {
                "Exit",
                "SlotsSummerBeachContest_Exit_Request",
                "SlotsSummerBeachContest_Exit_Response",
                "SlotsSummerBeachContest_Exit_Notice"
            },
            {
                "Offline",
                "SlotsSummerBeachContest_Offline_Request",
                "SlotsSummerBeachContest_Offline_Response",
                "SlotsSummerBeachContest_Offline_Notice"
            }
        }
    },
    {
        id = 233,
        name = "SlotsWorldCupContest",
        messages = {
            "SlotsWorldCupContest_Enter_Request",
            "SlotsWorldCupContest_Enter_Response",
            "SlotsWorldCupContest_Enter_Notice",
            "SlotsWorldCupContest_Exit_Request",
            "SlotsWorldCupContest_Exit_Response",
            "SlotsWorldCupContest_Exit_Notice",
            "SlotsWorldCupContest_Offline_Request",
            "SlotsWorldCupContest_Offline_Response",
            "SlotsWorldCupContest_Offline_Notice"
        },
        handlers = {
            {
                "Enter",
                "SlotsWorldCupContest_Enter_Request",
                "SlotsWorldCupContest_Enter_Response",
                "SlotsWorldCupContest_Enter_Notice"
            },
            {
                "Exit",
                "SlotsWorldCupContest_Exit_Request",
                "SlotsWorldCupContest_Exit_Response",
                "SlotsWorldCupContest_Exit_Notice"
            },
            {
                "Offline",
                "SlotsWorldCupContest_Offline_Request",
                "SlotsWorldCupContest_Offline_Response",
                "SlotsWorldCupContest_Offline_Notice"
            }
        }
    },
    {
        id = 234,
        name = "SlotsGameContest",
        messages = {
            "SlotsGameContest_Enter_Request",
            "SlotsGameContest_Enter_Response",
            "SlotsGameContest_Enter_Notice",
            "SlotsGameContest_Exit_Request",
            "SlotsGameContest_Exit_Response",
            "SlotsGameContest_Exit_Notice",
            "SlotsGameContest_Offline_Request",
            "SlotsGameContest_Offline_Response",
            "SlotsGameContest_Offline_Notice"
        },
        handlers = {
            {
                "Enter",
                "SlotsGameContest_Enter_Request",
                "SlotsGameContest_Enter_Response",
                "SlotsGameContest_Enter_Notice"
            },
            {"Exit", "SlotsGameContest_Exit_Request", "SlotsGameContest_Exit_Response", "SlotsGameContest_Exit_Notice"},
            {
                "Offline",
                "SlotsGameContest_Offline_Request",
                "SlotsGameContest_Offline_Response",
                "SlotsGameContest_Offline_Notice"
            }
        }
    },
    {
        id = 235,
        name = "Ad",
        messages = {
            "Ad_Click_Request",
            "Ad_Click_Response",
            "Ad_Info_Request",
            "Ad_Info_Response",
            "Ad_AddFreeSpin_Request",
            "Ad_AddFreeSpin_Response"
        },
        handlers = {
            {"Click", "Ad_Click_Request", "Ad_Click_Response"},
            {"Info", "Ad_Info_Request", "Ad_Info_Response"},
            {"AddFreeSpin", "Ad_AddFreeSpin_Request", "Ad_AddFreeSpin_Response"}
        }
    },
    {
        id = 236,
        name = "Activity",
        messages = {
            "Activity_Info_Request",
            "Activity_Info_Response",
            "Activity_Status_Request",
            "Activity_Status_Response"
        },
        handlers = {
            {"Info", "Activity_Info_Request", "Activity_Info_Response"},
            {"Status", "Activity_Status_Request", "Activity_Status_Response"}
        }
    },
    {
        id = 237,
        name = "SlotsRoomInfoContest",
        messages = {
            "SlotsRoomInfoContest_Query_Request",
            "SlotsRoomInfoContest_Query_Response",
            "SlotsRoomInfoContest_TableInfo_Request",
            "SlotsRoomInfoContest_TableInfo_Response",
            "SlotsRoomInfoContest_QueryRoomBrief_Request",
            "SlotsRoomInfoContest_QueryRoomBrief_Response",
        },
        handlers = {
            {"Query", "SlotsRoomInfoContest_Query_Request", "SlotsRoomInfoContest_Query_Response"},
            {"TableInfo", "SlotsRoomInfoContest_TableInfo_Request", "SlotsRoomInfoContest_TableInfo_Response"},
            {"QueryRoomBrief", "SlotsRoomInfoContest_QueryRoomBrief_Request", "SlotsRoomInfoContest_QueryRoomBrief_Response"},
        }
    },
    {
        id = 238,
        name = "SlotsWestWorld",
        messages = {
            "SlotsWestWorld_Enter_Request",
            "SlotsWestWorld_Enter_Response",
            "SlotsWestWorld_Start_Request",
            "SlotsWestWorld_Start_Response",
            "SlotsWestWorld_Exit_Request",
            "SlotsWestWorld_Exit_Response",
            "SlotsWestWorld_TableSync_Notice"
        },
        handlers = {
            {
                "Enter",
                "SlotsWestWorld_Enter_Request",
                "SlotsWestWorld_Enter_Response",
                "SlotsWestWorld_TableSync_Notice"
            },
            {"Start", "SlotsWestWorld_Start_Request", "SlotsWestWorld_Start_Response"},
            {"Exit", "SlotsWestWorld_Exit_Request", "SlotsWestWorld_Exit_Response"}
        }
    },
    {
        id = 239,
        name = "SlotsWestWorldContest",
        messages = {
            "SlotsWestWorldContest_Enter_Request",
            "SlotsWestWorldContest_Enter_Response",
            "SlotsWestWorldContest_Enter_Notice",
            "SlotsWestWorldContest_Exit_Request",
            "SlotsWestWorldContest_Exit_Response",
            "SlotsWestWorldContest_Exit_Notice",
            "SlotsWestWorldContest_Offline_Request",
            "SlotsWestWorldContest_Offline_Response",
            "SlotsWestWorldContest_Offline_Notice",
            "SlotsWestWorldContest_Hotfix_Request",
            "SlotsWestWorldContest_Hotfix_Response"
        },
        handlers = {
            {
                "Enter",
                "SlotsWestWorldContest_Enter_Request",
                "SlotsWestWorldContest_Enter_Response",
                "SlotsWestWorldContest_Enter_Notice"
            },
            {
                "Exit",
                "SlotsWestWorldContest_Exit_Request",
                "SlotsWestWorldContest_Exit_Response",
                "SlotsWestWorldContest_Exit_Notice"
            },
            {
                "Offline",
                "SlotsWestWorldContest_Offline_Request",
                "SlotsWestWorldContest_Offline_Response",
                "SlotsWestWorldContest_Offline_Notice"
            },
            {"Hotfix", "SlotsWestWorldContest_Hotfix_Request", "SlotsWestWorldContest_Hotfix_Response"}
        }
    },
    {
        id = 240,
        name = "Tournament",
        messages = {
            "Tournament_GetConfig_Request",
            "Tournament_GetConfig_Response",
            "Tournament_GetPlayerRank_Request",
            "Tournament_GetPlayerRank_Response",
            "Tournament_GetPrize_Request",
            "Tournament_GetPrize_Response"
        },
        handlers = {
            {"GetConfig", "Tournament_GetConfig_Request", "Tournament_GetConfig_Response"},
            {"GetPlayerRank", "Tournament_GetPlayerRank_Request", "Tournament_GetPlayerRank_Response"},
            {"GetPrize", "Tournament_GetPrize_Request", "Tournament_GetPrize_Response"}
        }
    },
    {
        id = 241,
        name = "Jackpot",
        messages = {
            "Jackpot_WinReward_Notice",
            "Jackpot_GetJackpot_Request",
            "Jackpot_GetJackpot_Response",
        },
        handlers = {
            {"GetJackpot", "Jackpot_GetJackpot_Request", "Jackpot_GetJackpot_Response"},
        }
    },
    {
        id = 243,
        name = "DailyMissions",
        messages = {
            "DailyMissions_Info_Request",
            "DailyMissions_Info_Response",
            "DailyMissions_Info_Notice",
            "DailyMissions_Collect_Request",
            "DailyMissions_Collect_Response",
            "DailyMissions_FinalCollect_Request",
            "DailyMissions_FinalCollect_Response",
        },
        handlers = {
            {"Info", "DailyMissions_Info_Request", "DailyMissions_Info_Response", "DailyMissions_Info_Notice"},
            {"Collect", "DailyMissions_Collect_Request", "DailyMissions_Collect_Response"},
            {"FinalCollect", "DailyMissions_FinalCollect_Request", "DailyMissions_FinalCollect_Response"}
        }
    },
    {
        id = 244,
        name = "PantherTracks",
        messages = {
            "PantherTracks_Info_Request",
            "PantherTracks_Info_Response",
            "PantherTracks_Info_Notice",
            "PantherTracks_Select_Request",
            "PantherTracks_Select_Response",
            "PantherTracks_Collect_Request",
            "PantherTracks_Collect_Response",
        },
        handlers = {
            {"Info", "PantherTracks_Info_Request", "PantherTracks_Info_Response", "PantherTracks_Info_Notice"},
            {"Select", "PantherTracks_Select_Request", "PantherTracks_Select_Response"},
            {"Collect", "PantherTracks_Collect_Request", "PantherTracks_Collect_Response"}
        }
    },
    {
        id = 245,
        name = "ShopBonus",
        messages = {
            "ShopBonus_GetStatus_Request",
            "ShopBonus_GetStatus_Response",
            "ShopBonus_GetBonus_Request",
            "ShopBonus_GetBonus_Response"
        },
        handlers = {
            {"GetStatus", "ShopBonus_GetStatus_Request", "ShopBonus_GetStatus_Response"},
            {"GetBonus", "ShopBonus_GetBonus_Request", "ShopBonus_GetBonus_Response"}
        }
    },
    {
        id = 246,
        name = "ClimbSlide",
        messages = {
            "ClimbSlide_Collect_Request",
            "ClimbSlide_Collect_Response",
            "ClimbSlide_Collect_Notice",
            "ClimbSlide_Spin_Request",
            "ClimbSlide_Spin_Response",
            "ClimbSlide_MapInfo_Request",
            "ClimbSlide_MapInfo_Response",
            "ClimbSlide_Booster_Request",
            "ClimbSlide_Booster_Response",
            "ClimbSlide_Booster_Notice",
            "ClimbSlide_ResetMap_Request",
            "ClimbSlide_ResetMap_Response",
            "ClimbSlide_FinalCollect_Request",
            "ClimbSlide_FinalCollect_Response"
        },
        handlers = {
            {"Collect", "ClimbSlide_Collect_Request", "ClimbSlide_Collect_Response", "ClimbSlide_Collect_Notice"},
            {"Spin", "ClimbSlide_Spin_Request", "ClimbSlide_Spin_Response"},
            {"MapInfo", "ClimbSlide_MapInfo_Request", "ClimbSlide_MapInfo_Response"},
            {"Booster", "ClimbSlide_Booster_Request", "ClimbSlide_Booster_Response", "ClimbSlide_Booster_Notice"},
            {"ResetMap", "ClimbSlide_ResetMap_Request", "ClimbSlide_ResetMap_Response"},
            {"FinalCollect", "ClimbSlide_FinalCollect_Request", "ClimbSlide_FinalCollect_Response"},
        }
    },
    {
        id = 247,
        name = "FeverCard",
        messages = {
            "FeverCard_AlbumInfo_Request",
            "FeverCard_AlbumInfo_Response",
            "FeverCard_AlbumCardsInfo_Request",
            "FeverCard_AlbumCardsInfo_Response",
            "FeverCard_NewCard_Notice",
            "FeverCard_History_Request",
            "FeverCard_History_Response",
            "FeverCard_StarWheel_Request",
            "FeverCard_StarWheel_Response",
            "FeverCard_EpicMachine_Request",
            "FeverCard_EpicMachine_Response",
            "FeverCard_GetSetCompleteReward_Request",
            "FeverCard_GetSetCompleteReward_Response",
            "FeverCard_GetAlbumCompleteReward_Request",
            "FeverCard_GetAlbumCompleteReward_Response",
            "FeverCard_ConfirmWildCard_Request",
            "FeverCard_ConfirmWildCard_Response",
        },
        handlers = {
            {"AlbumInfo", "FeverCard_AlbumInfo_Request", "FeverCard_AlbumInfo_Response"},
            {"AlbumCardsInfo", "FeverCard_AlbumCardsInfo_Request", "FeverCard_AlbumCardsInfo_Response"},
            {"History", "FeverCard_History_Request", "FeverCard_History_Response"},
            {"StarWheel", "FeverCard_StarWheel_Request", "FeverCard_StarWheel_Response"},
            {"EpicMachine", "FeverCard_EpicMachine_Request", "FeverCard_EpicMachine_Response"},
            {"GetSetCompleteReward", "FeverCard_GetSetCompleteReward_Request", "FeverCard_GetSetCompleteReward_Response"},
            {"GetAlbumCompleteReward", "FeverCard_GetAlbumCompleteReward_Request", "FeverCard_GetAlbumCompleteReward_Response"},
            {"ConfirmWildCard", "FeverCard_ConfirmWildCard_Request", "FeverCard_ConfirmWildCard_Response"},
        }
    },
    {
        id = 248,
        name = "FeverQuest",
        messages = {
            "FeverQuest_GetQuestInfo_Request",
            "FeverQuest_GetQuestInfo_Response",
            "FeverQuest_GetRankInfo_Request",
            "FeverQuest_GetRankInfo_Response",
            "FeverQuest_SetQuestHardLevel_Request",
            "FeverQuest_SetQuestHardLevel_Response",
            "FeverQuest_UpdateQuestProgress_Notice",
            "FeverQuest_FinishQuest_Notice",
            "FeverQuest_SeasonEnd_Notice",
        },
        handlers = {
            {"GetQuestInfo", "FeverQuest_GetQuestInfo_Request", "FeverQuest_GetQuestInfo_Response"},
            {"SetQuestHardLevel", "FeverQuest_SetQuestHardLevel_Request", "FeverQuest_SetQuestHardLevel_Response"},
            {"GetRankInfo", "FeverQuest_GetRankInfo_Request", "FeverQuest_GetRankInfo_Response"},
        }
    },
    {
        id = 249,
        name = "NewLoginAward",
        messages = {
            "NewLoginAward_WeekInfo_Request",
            "NewLoginAward_WeekInfo_Response",
            "NewLoginAward_DailyWheelInfo_Request",
            "NewLoginAward_DailyWheelInfo_Response",
            "NewLoginAward_FeverWheelInfo_Request",
            "NewLoginAward_FeverWheelInfo_Response",
        },
        handlers = {
            {"WeekInfo", "NewLoginAward_WeekInfo_Request", "NewLoginAward_WeekInfo_Response"},
            {"DailyWheelInfo", "NewLoginAward_DailyWheelInfo_Request", "NewLoginAward_DailyWheelInfo_Response"},
            {"FeverWheelInfo", "NewLoginAward_FeverWheelInfo_Request", "NewLoginAward_FeverWheelInfo_Response"},
        }
    },
    {
        id = 250,
        name = "Booster",
        messages = {
            "Booster_GetCashbackInfo_Request",
            "Booster_GetCashbackInfo_Response",
            "Booster_GetLevelRushInfo_Request",
            "Booster_GetLevelRushInfo_Response",
            "Booster_GetBoosterBundleInfo_Request",
            "Booster_GetBoosterBundleInfo_Response",
        },
        handlers = {
            {"GetCashbackInfo", "Booster_GetCashbackInfo_Request", "Booster_GetCashbackInfo_Response"},
            {"GetLevelRushInfo", "Booster_GetLevelRushInfo_Request", "Booster_GetLevelRushInfo_Response"},
            {"GetBoosterBundleInfo", "Booster_GetBoosterBundleInfo_Request", "Booster_GetBoosterBundleInfo_Response"},
        }
    },
}
