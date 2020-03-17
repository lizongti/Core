do --转轴大小、连线、 图标等定义
    GoldMineFormationArray = {
        Formation1 = {
            [1] = 3,
            [2] = 3,
            [3] = 3,
            [4] = 3,
            [5] = 3
        }
    }
    GoldMineLineArray = {
        Lines1 = {
            [1] = {2, 2, 2, 2, 2},
            [2] = {1, 1, 1, 1, 1},
            [3] = {3, 3, 3, 3, 3},
            [4] = {1, 2, 3, 2, 1},
            [5] = {3, 2, 1, 2, 3},
            [6] = {2, 1, 2, 3, 2},
            [7] = {2, 3, 2, 1, 2},
            [8] = {1, 1, 2, 3, 3},
            [9] = {3, 3, 2, 1, 1},
            [10] = {2, 1, 2, 1, 2},
            [11] = {3, 2, 3, 2, 3},
            [12] = {2, 1, 1, 1, 2},
            [13] = {2, 3, 3, 3, 2},
            [14] = {1, 2, 2, 2, 1},
            [15] = {3, 2, 2, 2, 3},
            [16] = {2, 2, 1, 2, 2},
            [17] = {2, 2, 3, 2, 2},
            [18] = {2, 1, 2, 1, 2},
            [19] = {2, 3, 2, 3, 2},
            [20] = {1, 1, 1, 2, 3},
            [21] = {3, 3, 3, 2, 1},
            [22] = {1, 2, 3, 3, 3},
            [23] = {3, 2, 1, 1, 1},
            [24] = {2, 2, 2, 1, 2},
            [25] = {2, 2, 2, 3, 2},
            [26] = {1, 2, 2, 2, 3},
            [27] = {3, 2, 2, 2, 1},
            [28] = {3, 3, 2, 1, 2},
            [29] = {1, 1, 2, 3, 2},
            [30] = {3, 2, 3, 3, 3},
            [31] = {1, 2, 1, 1, 1},
            [32] = {1, 2, 3, 2, 2},
            [33] = {3, 2, 1, 2, 2},
            [34] = {2, 1, 2, 1, 1},
            [35] = {2, 3, 2, 3, 3},
            [36] = {1, 2, 2, 2, 2},
            [37] = {3, 2, 2, 2, 2},
            [38] = {2, 1, 1, 1, 1},
            [39] = {2, 3, 3, 3, 3},
            [40] = {2, 2, 2, 2, 1},
            [41] = {2, 2, 2, 2, 3},
            [42] = {1, 1, 2, 1, 1},
            [43] = {3, 3, 2, 3, 3},
            [44] = {1, 1, 1, 2, 1},
            [45] = {3, 3, 3, 2, 3},
            [46] = {2, 2, 1, 1, 1},
            [47] = {2, 2, 3, 3, 3},
            [48] = {1, 1, 2, 2, 1},
            [49] = {3, 3, 2, 2, 3},
            [50] = {3, 2, 1, 2, 1}
        }
    }
    GoldMineTypeArray = {
        Types = {
            Bonus = 1, --Bonus
            Wild = 2, --wild
            Detonator = 4, --雷管
            Detonator_Fire = 5, --点燃的雷管
            Miner = 6, --矿工
            Donkey = 7, --驴子
            Tramcar = 8, --矿车
            Mattock = 9, -- 铁镐
            Lamp = 10, --灯
            A = 11,
            K = 12,
            Q = 13,
            J = 14,
            Empty = 15, --空的图标（在HoldSpin中的黑块）
            Wild_Col_1 = 16, --整列wild第一个
            Wild_Col_2 = 17, --整列wild第二个
            Wild_Col_3 = 18, --整列wild第三个
            Wilds = {
                2,
                16,
                17,
                18
            },
            --Wild_Col触发移动后，替换为这个三个
            Wild_Col_Map = {
                [16] = true,
                [17] = true,
                [18] = true
            },
            Normal_Continue_Count = 3,
            Special_Continue_Count = {
                [6] = 2
            }
        }
    }
end

do --枚举类型
    --spin类型
    local SPIN_ENUM = {
        BASE_SPIN = 1, --基础spin
        HOLD_SPIN = 2, --炸药合成Spin
        FREE_SPIN = 3 --Free Spin
    }
    --Bonus类型
    local BONUS_ENUM = {
        PICK_BONUS_1 = 1, --捡取的小游戏1
        PICK_BONUS_2 = 2, --捡取的小游戏2
        TURNAROUND_BONUS = 3, --转盘小游戏
        SPIN_BONUS = 4 --选择spin类型的小游戏
    }
    --奖励类型
    local PRIZE_TYPE_ENUM = {
        JAKCPOT_MEGA = 1,
        JAKCPOT_GRAND = 2,
        JACKPOT_MAJOR = 3,
        JACKPOT_MINOR = 4,
        JACKPOT_MINI = 5,
        CHIP = 6,
        JACKPOT_DOUBLE = 7
    }
    --炸药图标类型
    local BIG_DETONATOR_INFO_ENUM = {
        _3x5 = {
            {101, 101, 101, 101, 101},
            {102, 102, 102, 102, 102},
            {103, 103, 103, 103, 103}
        },
        _3x4 = {
            {201, 201, 201, 201},
            {202, 202, 202, 202},
            {203, 203, 203, 203}
        },
        _2x5 = {
            {301, 301, 301, 301, 301},
            {302, 302, 302, 302, 302}
        },
        _3x3 = {
            {401, 401, 401},
            {402, 402, 402},
            {403, 403, 403}
        },
        _2x4 = {
            {501, 501, 501, 501},
            {502, 502, 502, 502}
        },
        _3x2 = {
            {601, 601},
            {602, 602},
            {603, 603}
        },
        _2x3 = {
            {701, 701, 701},
            {702, 702, 702}
        },
        _2x2 = {
            {801, 801},
            {802, 802}
        },
        _3x1 = {
            {901},
            {902},
            {903}
        },
        _2x1 = {
            {1001},
            {1002}
        },
        _1x1 = {
            {1101}
        }
    }
    --Hold_Spin的炸药爆炸后的奖励图标类型
    local HOLD_SPIN_PRIZE_ITEM_ENUM = {
        _3x5 = {
            JAKCPOT_GRAND = 20102,
            JACKPOT_MAJOR = 20103,
            JACKPOT_MINOR = 20104,
            JACKPOT_MINI = 20105,
            CHIP = 20106
        },
        _3x4 = {
            JAKCPOT_GRAND = 20202,
            JACKPOT_MAJOR = 20203,
            JACKPOT_MINOR = 20204,
            JACKPOT_MINI = 20205,
            CHIP = 20206
        },
        _2x5 = {
            JAKCPOT_GRAND = 20302,
            JACKPOT_MAJOR = 20303,
            JACKPOT_MINOR = 20304,
            JACKPOT_MINI = 20305,
            CHIP = 20306
        },
        _3x3 = {
            JAKCPOT_GRAND = 20402,
            JACKPOT_MAJOR = 20403,
            JACKPOT_MINOR = 20404,
            JACKPOT_MINI = 20405,
            CHIP = 20406
        },
        _2x4 = {
            JAKCPOT_GRAND = 20502,
            JACKPOT_MAJOR = 20503,
            JACKPOT_MINOR = 20504,
            JACKPOT_MINI = 20505,
            CHIP = 20506
        },
        _3x2 = {
            JAKCPOT_GRAND = 20602,
            JACKPOT_MAJOR = 20603,
            JACKPOT_MINOR = 20604,
            JACKPOT_MINI = 20605,
            CHIP = 20606
        },
        _2x3 = {
            JAKCPOT_GRAND = 20702,
            JACKPOT_MAJOR = 20703,
            JACKPOT_MINOR = 20704,
            JACKPOT_MINI = 20705,
            CHIP = 20706
        },
        _2x2 = {
            JAKCPOT_GRAND = 20802,
            JACKPOT_MAJOR = 20803,
            JACKPOT_MINOR = 20804,
            JACKPOT_MINI = 20805,
            CHIP = 20806
        }
    }
end

do --action种类列举
    pre_action_list = {
        --jackpot信息变化
        [1] = {
            action_type = 34,
            jackpot_param = {
                --[[奖池金额计算方法： 的jackpot true:对应的  false:对应的筹码值 = prize_pool[x] * 下注的total_amount / 10000+
                        变量定义：
                            double_val =  double and 2 or 1
                        计算公式：
                            is_point_amount=false： 筹码值 = (start_point * 当前下注值 /10000 + extra_chip) * double_val
                            is_point_amount=true： 筹码值 = (start_point * total_amount /10000 + extra_chip) * double_val
                ]]
                prize_pool = {
                    --奖池信息(key为jackpot的类型1~5，文件内搜索PRIZE_TYPE_ENUM)
                    [1] = {
                        start_point = 500, --起始点数
                        extra_chip = 104000, --额外筹码值
                        double = false, --是否最终结果进行加倍
                        is_point_amount = false, --是否是指定基础金额金额
                        total_amount = 0 --指定金额的数量
                    },
                    [2] = {
                        start_point = 200, --起始点数
                        extra_chip = 52000, --额外筹码值
                        double = false, --是否最终结果进行加倍
                        is_point_amount = false, --是否是指定基础金额金额
                        total_amount = 0 --指定金额的数量
                    },
                    [3] = {
                        start_point = 100, --起始点数
                        extra_chip = 0, --额外筹码值
                        double = false, --是否最终结果进行加倍
                        is_point_amount = false, --是否是指定基础金额金额
                        total_amount = 0 --指定金额的数量
                    },
                    [4] = {
                        start_point = 50, --起始点数
                        extra_chip = 0, --额外筹码值
                        double = false, --是否最终结果进行加倍
                        is_point_amount = false, --是否是指定基础金额金额
                        total_amount = 0 --指定金额的数量
                    },
                    [5] = {
                        start_point = 15, --起始点数
                        extra_chip = 0, --额外筹码值
                        double = false, --是否最终结果进行加倍
                        is_point_amount = false, --是否是指定基础金额金额
                        total_amount = 0 --指定金额的数量
                    }
                }
            }
        },
        --绳子结数变化
        [2] = {
            action_type = 30, --action类型
            --燃烧火苗的起点（每个带火炸药的位置）
            detonator_fire_pos_arr = {
                {
                    data = 5, --图标编号
                    pos = {1, 2} --pos[1]:行 pos[2]:列
                },
                {
                    data = 5, --图标编号
                    pos = {1, 3} --pos[1]:行 pos[2]:列
                },
                {
                    data = 5, --图标编号
                    pos = {2, 2} --pos[1]:行 pos[2]:列
                }
            },
            --当前绳子结束变化
            curr_rope = {
                rope_idx = 1, --当前为第几条绳子（有1、2、3个等级）
                left_knat_count = 5 --当前绳结的段数（为0就烧到了炸弹）
            },
            --生成的新绳子信息（当前绳子烧完，才会有下面字段）
            new_rope = {
                rope_idx = 2, --当前为第几条绳子（有1、2、3个等级）
                left_knat_count = 9 --当前绳结的段数（为0就烧到了炸弹）
            }
        },
        --进入bonus提示
        [3] = {
            action_type = 5, --action类型
            --1.为pick_bonus，即绳子的前2段烧完时，触发的拾取的bonus
            --2.为turnaround_bonus,即绳子第3段烧完是，触发的转盘bonus
            --3.为spin_bonus,即转到3个bonus图标，需要进行选择的bonus
            bonus_game_type = 1
        },
        --spin的类型转换
        [4] = {
            action_type = 24,
            --转轴信息数组
            parameter_list = {
                --spin类型： 见SPIN_ENUM
                spin_type = 2,
                --spin次数：仅当HOLD_SPIN、FREE_SPIN时有意义
                spin_bouts = 3,
                --转轴的信息
                reel_info_arr = {
                    [1] = {
                        id = 2,
                        formation_name = "Formation2",
                        line_name = "Lines2",
                        feature_file_name = nil
                    }
                }
            }
        },
        --hold_spin的锁定信息
        [5] = {
            action_type = 4, --action类型
            spin_bouts = 5, --剩余spin的次数
            --3行5列的二位数组，true时为锁定，false为没有锁定
            lock_info_arr = {
                [1] = {false, false, false, true, true},
                [2] = {false, false, false, true, true},
                [3] = {true, false, false, false, false}
            }
        },
        --hold_spin的结算信息
        [6] = {
            action_type = 36, --action类型
            win_chip = 85000, --总共的赢钱
            --爆炸信息数组
            explosion_info_arr = {
                [1] = {
                    start_pos = {1, 2}, --为第1行第2列开始的炸药
                    --爆炸信息的转轴（用来播放滚动动画,为nil时代表不转动）
                    reel_info = {
                        [1] = {
                            item = 20802, --item图标（对应HOLD_SPIN_PRIZE_ITEM_ENUM）
                            prize_val = 80000 --奖励的实际筹码值
                        },
                        [2] = {
                            item = 20803, --item图标（对应HOLD_SPIN_PRIZE_ITEM_ENUM）
                            prize_val = 40000 --奖励的实际筹码值
                        },
                        [3] = {
                            item = 20804, --item图标（对应HOLD_SPIN_PRIZE_ITEM_ENUM）
                            prize_val = 20000 --奖励的实际筹码值
                        },
                        [4] = {
                            item = 20805, --item图标（对应HOLD_SPIN_PRIZE_ITEM_ENUM）
                            prize_val = 10000 --奖励的实际筹码值
                        },
                        [5] = {
                            item = 20806, --item图标（对应HOLD_SPIN_PRIZE_ITEM_ENUM）
                            prize_val = 5000 --奖励的实际筹码值
                        }
                    },
                    item_result_idx = 5, --转轴最终转到的结果(即在reel_info的索引)
                    --奖励信息
                    prize_info = {
                        prize_type = 6, --奖励类型（PRIZE_TYPE_ENUM）
                        prize_val = 5000 --获得的筹码值
                    }
                },
                [2] = {
                    start_pos = {3, 3}, --为第1行第2列开始的炸药
                    --爆炸信息的转轴（用来播放滚动动画,为nil时代表不转动）
                    reel_info = {
                        [1] = {
                            item = 20802, --item图标（对应HOLD_SPIN_PRIZE_ITEM_ENUM）
                            prize_val = 80000 --奖励的实际筹码值
                        },
                        [2] = {
                            item = 20803, --item图标（对应HOLD_SPIN_PRIZE_ITEM_ENUM）
                            prize_val = 40000 --奖励的实际筹码值
                        },
                        [3] = {
                            item = 20804, --item图标（对应HOLD_SPIN_PRIZE_ITEM_ENUM）
                            prize_val = 20000 --奖励的实际筹码值
                        },
                        [4] = {
                            item = 20805, --item图标（对应HOLD_SPIN_PRIZE_ITEM_ENUM）
                            prize_val = 10000 --奖励的实际筹码值
                        },
                        [5] = {
                            item = 20806, --item图标（对应HOLD_SPIN_PRIZE_ITEM_ENUM）
                            prize_val = 5000 --奖励的实际筹码值
                        }
                    },
                    item_result_idx = 2, --转轴最终转到的结果(即在reel_info的索引)
                    --奖励信息
                    prize_info = {
                        prize_type = 3, --奖励类型（PRIZE_TYPE_ENUM）
                        prize_val = 40000 --获得的筹码值
                    }
                }
            },
            enter_info = {
                item_ids = {},
                final_item_ids = {}
            }
        },
        --move_wild特性
        [7] = {
            action_type = 19, --action类型
            feature = {1, 3, 5} --需要自动wild的列的数组
        }
    }
end

do --Slots
    Enter = {
        bonus_info = {
            in_bonus_game = true, --是否在Jackpot中
            bonus_game_type = 1, --bonus_game的类型（见BONUS_ENUM）
            curr_spin_type = 1, --当前spin的类型（SPIN_ENUM）
            spin_bouts = 5, --spin次数：仅当HOLD_SPIN、FREE_SPIN时有意义
            --转轴信息
            reel_info_arr = {
                [1] = {
                    id = 2,
                    formation_name = "Formation2",
                    line_name = "Lines2",
                    feature_file_name = nil
                }
            },
            --jackpot的参数
            jackpot_param = {}, --详见pre_action_list中的34
            --绳子信息
            curr_rope = {
                rope_idx = 1, --当前为第几条绳子（有1、2、3个等级）
                left_knat_count = 5 --当前绳结的段数（为0就烧到了炸弹）
            }
        }
    }
end

do --PickBonus
    --进入
    PickBonusEnter = {
        content = {
            rope_idx = 1, --由第几节绳子燃烧触发(目前有1、2两种，分别显示金碗和金桶的)
            --捡取游戏的信息
            pick_game_info = {
                max_pick_count = 7, --最多捡取的个数（就是pick——again的次数）
                curr_pick_count = 2, --当前pick到了第几个（每次捡取都会+1，并在服务器记录）
                pick_history = {3, 1}, --捡取的历史信息（客户端每次点击的图标的顺序，如{2，3，1，5}，顺序从prize_pool中取出奖励展示）
                prize_pool = {
                    --奖池信息（所有图标的奖励信息，与点击的位置无关）
                    {
                        prize_type = 5, --奖励类型，详见：PRIZE_TYPE_ENUM （直接文件内搜索）
                        prize_val = 1, --奖励的筹码值
                        weight = 1 --权重，客户端可忽略
                    },
                    {
                        prize_type = 6,
                        prize_val = 5,
                        weight = 2
                    },
                    {
                        prize_type = 6,
                        prize_val = 4,
                        weight = 4
                    },
                    {
                        prize_type = 6,
                        prize_val = 3,
                        weight = 8
                    },
                    {
                        prize_type = 6,
                        prize_val = 2,
                        weight = 16
                    }
                },
                win_chip = 58000 --游戏结束时的总收益
            },
            pre_action_list = {} --会触发的Action列表
        }
    }

    --捡取
    --请求
    parameter = {
        pick_pos = 3 --客户端捡取的UI对应顺序
    }
    --回复
    PickBonusPick = {
        content = {
            ----客户端的请求信息
            request = {
                pick_pos = 3 --客户端捡取的UI对应顺序
            },
            ----服务器的回复信息
            pick_success = true, --捡取是否成功
            curr_pick_count = 3, --当前pick到了第几个
            is_over = true, --游戏是否结束了
            win_chip = 30000, --游戏结束时，赢取的总金额（仅当pick_success and is_over == true时才有效）
            pre_action_list = {} --会触发的Action列表
        }
    }
end

do --TurnaroundBonus
    --
    TurnaroundBonusEnter = {
        content = {
            --转盘游戏信息
            turnaround_game_info = {
                max_rotate_count = 5, --最多的转动次数（就是roate_result_arr的长度）
                curr_rotate_count = 0, --当前的转动次数（用于恢复现场）
                --转盘的信息（用于恢复现场）
                turnaround_info = {
                    [1] = {id = 1, prize_type = 5},
                    [2] = {id = 2, prize_type = 7},
                    [3] = {id = 3, prize_type = 5},
                    [4] = {id = 4, prize_type = 3},
                    [5] = {id = 5, prize_type = 4},
                    [6] = {id = 6, prize_type = 5},
                    [7] = {id = 7, prize_type = 2},
                    [8] = {id = 8, prize_type = 4},
                    [9] = {id = 9, prize_type = 5},
                    [10] = {id = 10, prize_type = 1},
                    [11] = {id = 11, prize_type = 4},
                    [12] = {id = 12, prize_type = 5},
                    [13] = {id = 13, prize_type = 3},
                    [14] = {id = 14, prize_type = 4},
                    [15] = {id = 15, prize_type = 5},
                    [16] = {id = 16, prize_type = 3},
                    [17] = {id = 17, prize_type = 4},
                    [18] = {id = 18, prize_type = 5},
                    [19] = {id = 19, prize_type = 3},
                    [20] = {id = 20, prize_type = 4}
                },
                roate_result_arr = {6, 1, 17, 2, 6, 6}, --每次转动的转盘结果（对应turnaround_info的索引）
                win_chip = 38000 --游戏结束时的总收益
            },
            pre_action_list = {} --会触发的Action列表
        }
    }

    TurnaroundBonusRotate = {
        content = {
            rotate_success = true, --转动是否成功
            prize_type = 5, --获得的奖励类型（见PRIZE_TYPE_ENUM）
            curr_rotate_count = 6, --当前是第几次转动
            turnaround_change_info = {
                --转盘信息的改变
                pos = {5}, --改变的位置
                data = {id = 5, prize_type = 5} --改变后的信息
            },
            is_over = true, --游戏是否结束
            win_chip = 30000, --游戏结束时，赢取的总金额（仅当rotate_success and is_over == true时才有效）
            pre_action_list = {} --会触发的Action列表
        }
    }
end

do --SpinBonus
    --进入时请求
    SpinBonusEnter = {
        content = {
            --选项信息
            select_param = {
                free_spin_bouts = 10, --可获取free_spin的次数
                hold_spin_bouts = 5 --可获取hold_spin的次数
            }
        }
    }

    --选择时请求
    --传入的请求
    parameter = {
        is_free_spin = true --是否选择free_spin
    }
    --回复
    SpinBonusSelect = {
        content = {
            select_request = {is_free_spin = true}, --请求的选择
            request_success = true, --请求是否成功
            origin_result = {}, --选择hold_spin时，进入时的炸药结果(就是base-spin中的转轴结果)
            final_result = {}, --选择hold_spin时，进入时的炸药结果,合成后(就是base-spin中的转轴结果)
            pre_action_list = {} --会触发的Action列表
        }
    }
end
