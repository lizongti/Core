do --转轴大小、连线、 图标等定义
end

do --枚举类型
    --spin类型
    local SPIN_ENUM = {
        BASE_SPIN = 1, --基础spin
        FREE_SPIN = 2 --free_Spin
    }
    --Bonus类型
    local BONUS_ENUM = {
        SPIN_BONUS = 1 --选择spin类型的小游戏
    }
    --奖励类型
    local PRIZE_TYPE_ENUM = {
        JAKCPOT = 1
    }
end

do --action种类列举
    pre_action_list = {
        --jackpot信息变化
        [1] = {
            action_type = 34,
            jackpot_param = {
                --奖池信息(key为jackpot的类型，文件内搜索PRIZE_TYPE_ENUM)
                prize_pool = {
                    [1] = {
                        --奖励金额 = start_point * total_amount / 10000 + extra_chip
                        --start_point = 300, (此玩法为固定点数，故直接读取配置，服务器不发送)
                        extra_chip = 500
                    }
                }
            }
        },
        --赢取jackpot
        [2] = {
            action_type = 41,
            extra_win_chip = 50000,
            line_index = 3 --jackpot所在连线的连线
        },
        --进入bonus提示
        [3] = {
            action_type = 5, --action类型
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
        --结算时动态Wild触发的结算action
        [5] = {
            action_type = 42,
            --动态wild结算
            dynamic_wild_settle = {
                extra_win_chip = 50000,
                --wild所在的位置
                wild_pos_arr = {
                    {pos = {1, 1}, data = 5},
                    {pos = {1, 3}, data = 2}
                }
            }
        },
        [6] = {
            action_type = 43,
            --整列为特殊图标，使得全部结果加倍
            special_whole_col_settle = {
                extra_win_chip = 50000,
                special_whole_col_arr = {
                    --整列为特殊图标的列数组
                    {pos = {1}, data = true}
                }
            }
        },
        --free_spin的次数增加
        [7] = {
            action_type = 52,
            add_free_spin_bouts = 2, --增加的free_spin次数
            free_spin_bouts = 5 --增加后，free_spin的剩余次数
        },
        --free_spin的加倍数值改变
        [8] = {
            action_type = 44,
            multiple_times = 6, --最后赢钱的加倍倍数
            special_whole_col_arr = {
                --整列为特殊图标的列数组
                {pos = {1}, data = true}
            }
        },
        --free_spin结算
        [9] = {
            action_type = 45,
            extra_win_chip = 800, --最终金额
            --free_spin结束时的结算信息
            settle_info = {
                multiple_times = 6, --加倍的倍数
                base_total_win_chip = 1000, --基础总赢钱
                multiple_total_win_chip = 6000 --最终的总赢钱
            }
        }
    }
end

do --Slots
    Enter = {
        bonus_info = {
            in_bonus_game = true, --是否在bonus_game中
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
            --jackpot信息
            --奖池信息(key为jackpot的类型，文件内搜索PRIZE_TYPE_ENUM)
            jackpot_param = {
                --奖池信息(key为jackpot的类型，文件内搜索PRIZE_TYPE_ENUM)
                prize_pool = {
                    [1] = {
                        --奖励金额 = start_point * total_amount / 10000 + extra_chip
                        --start_point = 300, (此玩法为固定点数，故直接读取配置，服务器不发送)
                        extra_chip = 500
                    }
                }
            },
            --free_spin的倍数
            free_spin_multiple_times = 3
        }
    }
end

do --SpinBonus
    --进入时请求
    SpinBonusEnter = {
        content = {
            --选项信息
            select_param = {
                free_spin_bouts_level_arr = {12, 9, 6} --选择的free_spin等级对应的free_spin的次数（1级：12次 2级：9次 3:级6次）
            }
        }
    }

    --选择时请求
    --传入的请求
    parameter = {
        level = 2 --选择free_spin的等级
    }
    --回复
    SpinBonusSelect = {
        content = {
            select_request = {level = 2}, --请求的选择
            request_success = true, --请求是否成功
            pre_action_list = {} --会触发的Action列表
        }
    }
end

--功能点
--[[    1.jackpot 单档:
        a.jackpot增长
        b.jackpot必出
        c.通过连线中奖

    2.wild功能：
        a.普通wild和特殊可变wild。
        b.可变wild，随机生成。（客户端也需要,直接使用假轴实现？）
        c.有赔率联想上的可变wild，需要将连线xN倍。（并通知客户端变化过程，需要播放动画）
    3.特殊图标：
        a.连线上的，多个图标需要进行合成。（服务器更改图标）
        b.整列的图标，需要合成（x2功能）
        c.x2的功能，根据spin类型来计算
    4.scatter图标：
        a.base中触发free_spin
        b.free_spin中，增加次数
]] --[[test
    合成大图标：
        1.奖励连线所在的列，特殊图标需要合成
        2.有整列特殊图标的列

        综合一下列--->进行final结果合成

]]
