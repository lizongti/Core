TestLuckyCal = {}
local lu = require('luaunit')

function TestLuckyCal:setUp()
    self.player = {
        id = 1,
        character = {
            rand_seed = 1,
            rand_num = 0,
            lucky = 0,
            unlucky = 0,
            player_type = 1,
            level = 100,
            chip = 1000000000,
            lucky_type = LuckyType.ModeTypes.Normal,
            stage_type = 1,
        },
        client = {
            os = "Android",
            channel = "mirror"
        }
    }

    self.session = {
        player = self.player,
    }

    self.spin_context = {
        game_type = 37,
        chip_cost = 10000000000,
        amount = 40000,
        lineNum = 40,
        win_chip = 1000000,
        charge = 0,
        player_json_data = {
            ContinuousSpinNoPay = 0,
            ContinuousSpinWithoutBankrupt = 0,
            force_win_spin = 30,
            force_win_feature = 29,
        },
        player_game_info = {
            save_data = {
                force_win_info = {
                    ["game37"] = {
                        spin_count = 28,
                        new_spin_num = 30,
                        new_feature_num = 2,
                        new_award_num = 2,
                    }
                }
            }
        }
    }
end

function TestLuckyCal:test_IsForceWin()
    lu.assertEquals(LuckyCal.IsForceWinPure(self.player, 10, 5, 5, 0), true)
    lu.assertEquals(LuckyCal.IsForceWinPure(self.player, 1, 1, 1, 1), false)
    lu.assertEquals(LuckyCal.IsForceWinPure(self.player, 1, 1, 1, 0), true)
end

function TestLuckyCal:test_NewHandAddLucky()
    local old_lucky = self.player.character.lucky
    LuckyCal.OnFirstLogin(self.session)
    lu.assertNotEquals(self.player.character.lucky, old_lucky)
end

function TestLuckyCal:test_PurchaseAddLucky()
    local old_lucky = self.player.character.lucky
    local config = CommonCal.Calculate.get_config(self.player, "ShopConfig")

    for k, v in pairs(config) do
        LuckyCal.OnPurchase(self.session, v.id)
    end

    lu.assertNotEquals(self.player.character.lucky, old_lucky)
end

function TestLuckyCal:test_DailyWheelAddLucky()
    local old_lucky = self.player.character.lucky
    LuckyCal.GainLucky(self.player, 1000)
    lu.assertNotEquals(self.player.character.lucky, old_lucky)
end

function TestLuckyCal:test_LevelUpAddLucky()
    local old_lucky = self.player.character.lucky

    for level=1, 1000 do
        LuckyCal.OnLevelUp(self.player, level)
    end

    lu.assertNotEquals(self.player.character.lucky, old_lucky)
end

function TestLuckyCal:test_NormalSpinAddLucky()
    self.spin_context = {
        game_type = 37,
        chip_cost = 10000000000,
        amount = 2000,
        lineNum = 40,
        win_chip = 40000,
        charge = 0,
        player_json_data = {
            ContinuousSpinNoPay = 0,
            ContinuousSpinWithoutBankrupt = 0,
            force_win_spin = 30,
            force_win_feature = 29,
        },
        player_game_info = {
            save_data = {
                force_win_info = {
                    ["game37"] = {
                        
                    }
                }
            }
        }
    }

    self.player.character.level = 20
    
    local old_lucky = self.player.character.lucky
    
    LuckyCal.OnBaseSpinStart(self.session, self.spin_context)
    LuckyCal.OnBaseSpinEnd(self.session, self.spin_context)

    lu.assertNotEquals(self.player.character.lucky, old_lucky)
end

function TestLuckyCal:test_NormalSpinAddUnlucky()
    self.spin_context = {
        game_type = 37,
        chip_cost = 1000,
        amount = 2000,
        lineNum = 40,
        win_chip = 200000000000,
        charge = 0,
        player_json_data = {
            ContinuousSpinNoPay = 0,
            ContinuousSpinWithoutBankrupt = 0,
            force_win_spin = 30,
            force_win_feature = 29,
        },
        player_game_info = {
            save_data = {
                force_win_info = {
                    ["game37"] = {
                        
                    }
                }
            }
        }
    }

    self.player.character.level = 20
    
    local old_unlucky = self.player.character.unlucky
    
    LuckyCal.OnBaseSpinStart(self.session, self.spin_context)
    LuckyCal.OnBaseSpinEnd(self.session, self.spin_context)

    lu.assertNotEquals(self.player.character.unlucky, old_unlucky)
end

function TestLuckyCal:test_EnterNewGameAddForceWin()
    local force_win_feature = self.spin_context.player_json_data.force_win_feature
    
    LuckyCal.OnBaseSpinStart(self.session, self.spin_context)
    LuckyCal.OnBaseSpinEnd(self.session, self.spin_context)

    lu.assertNotEquals(self.spin_context.player_json_data.force_win_feature, force_win_feature)
end
