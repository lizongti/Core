--------------------------------------------------
--*********************Action***********************
pre_action_list = {
	--收集元素信息
	[1] = {
		action_type = 30, --action类型
		add_collect_num = 100, --新增的手收集元素数量
		curr_collect_num = 150, --这次收集完成后，新增的收集数量
		--收集信息的数组
		collect_info_arr = {
			{
				data = {
					item_id = 4, --图标id
					collect_num = 10 --收集元素个数
				}, --收集元素的个数
				pos = {1, 2} --pos[1]:行 pos[2]:列
			},
			{
				data = {
					item_id = 7, --图标id
					collect_num = 15 --收集元素个数
				}, --收集元素的个数
				pos = {1, 4} --pos[1]:行 pos[2]:列
			}
		}
	},
	--reels_spin中整列为wild
	-- [2] = {
	-- 	action_type = 22,
	-- 	feature = {
	-- 		wild_cols = {1, 3} --为wild的列的table
	-- 	}
	-- },
	--切换阵形信息
	[3] = {
		action_type = 24,
		--转轴信息数组
		parameter_list = {
			--spin类型： 1.BASE_SPIN 2.COIN_SPIN 3.REELS_SPIN
			spin_type = 2,
			--spin次数：仅当COIN_SPIN、REELS_SPIN时有意义
			spin_bouts = 3,
			--转轴的信息
			reel_info_arr = {
				[1] = {id = 2, formation_name = "Formation2", line_name = "Lines2", feature_file_name = nil, wild_cols = {2}},
				[2] = {id = 3, formation_name = "Formation2", line_name = "Lines2", feature_file_name = nil, wild_cols = {2}},
				[3] = {id = 4, formation_name = "Formation2", line_name = "Lines2", feature_file_name = nil, wild_cols = {2}}
			}
		}
	},
	--可以进入bonus_game
	[4] = {
		action_type = 5
	},
	--锁定金币信息数组
	[5] = {
		action_type = 4,
		parameter_list = {
			play_again_bouts = 1,
			coin_spin_bouts = 3,
			all_coin_amount = 18000,
			lock_coin_info_arr = {
				{
					pos = {2, 3}, --pos[1]:行 pos[2]:列
					data = {
						prize_type = 1, --1.筹码奖励 2.Grand Jackpot 3.Major Jackpot 4.Minor Jackpot 5.Mini Jackpot 6.PLAY_AGAIN(获得再次进行coin_spin的游戏机会)
						amount = 100000
					}
				},
				{
					pos = {3, 3}, --pos[1]:行 pos[2]:列
					data = {
						prize_type = 1, --1.筹码奖励 2.Grand Jackpot 3.Major Jackpot 4.Minor Jackpot 5.Mini Jackpot 6.PLAY_AGAIN(获得再次进行coin_spin的游戏机会)
						amount = 20000
					}
				}
			}
		}
	},
	--游戏内jackpot奖池信息
	[6] = {
		action_type = 34,
		parameter_list = {
			--索引为prize_type,即奖励类型,赢钱为:（totalamount*start_point/10000 + extra_chip）
			prize_pool = {
				--JACKPOT_GRAND
				[1] = {
					start_point = prize_config.start_point, --起始点数
					extra_chip = 100 --额外送的钱（从下注中抽取）
				},
				--JACKPOT_MAJOR
				[2] = {
					start_point = prize_config.start_point, --起始点数
					extra_chip = 50 --额外送的钱（从下注中抽取）
				},
				--JACKPOT_MINOR
				[3] = {
					start_point = prize_config.start_point, --起始点数
					extra_chip = 20 --额外送的钱（从下注中抽取）
				},
				--JACKPOT_MINI
				[4] = {
					start_point = prize_config.start_point, --起始点数
					extra_chip = 10 --额外送的钱（从下注中抽取）
				}
			}
		}
	},
	--显示金币信息数组
	[5] = {
		action_type = 25,
		parameter_list = {
			lock_coin_info_arr = {
				{
					pos = {2, 3}, --pos[1]:行 pos[2]:列
					data = {
						prize_type = 1, --1.筹码奖励 2.Grand Jackpot 3.Major Jackpot 4.Minor Jackpot 5.Mini Jackpot 6.PLAY_AGAIN(获得再次进行coin_spin的游戏机会)
						amount = 100000
					}
				},
				{
					pos = {3, 3}, --pos[1]:行 pos[2]:列
					data = {
						prize_type = 1, --1.筹码奖励 2.Grand Jackpot 3.Major Jackpot 4.Minor Jackpot 5.Mini Jackpot 6.PLAY_AGAIN(获得再次进行coin_spin的游戏机会)
						amount = 20000
					}
				}
			}
		}
	}
}
--************************************************
--------------------------------------------------

--------------------------------------------------
--*********************Spin***********************
--转轴spin结果中formation_list.id的定义
--base_spin、coin_spin（只会有5*4的转轴，并且仅有一个）
formation_list = {
	{id = 1}
}
--reels_spin （多轴转动的）
--5*3的转轴情况
formation_list = {
	{id = 2}, --第1个
	{id = 3}, --第2个
	{id = 4}, --第3个
	{id = 5} --第4个
}
--5*4的转轴情况
formation_list = {
	{id = 6}, --第1个
	{id = 7}, --第2个
	{id = 8}, --第3个
	{id = 9} --第4个
}

--进入游戏
Enter = {
	bonus_info = {
		--是否在bonus_game中
		in_bonus_game = false,
		--收集元素的个数
		collect_num = 109,
		--当前spin的类型
		curr_spin_type = 3,
		--spin次数：仅当COIN_SPIN、REELS_SPIN时有意义
		spin_bouts = 10,
		--转轴的信息
		reel_info_arr = {
			[1] = {id = 2, formation_name = "Formation2", line_name = "Lines2", feature_file_name = nil, wild_cols = {2}},
			[2] = {id = 3, formation_name = "Formation2", line_name = "Lines2", feature_file_name = nil, wild_cols = {2}},
			[3] = {id = 4, formation_name = "Formation2", line_name = "Lines2", feature_file_name = nil, wild_cols = {2}}
		},
		--jackpot奖池信息
		prize_pool = {
			--JACKPOT_GRAND
			[2] = {
				start_point = prize_config.start_point, --起始点数
				extra_chip = 100 --额外送的钱（从下注中抽取）
			},
			--JACKPOT_MAJOR
			[3] = {
				start_point = prize_config.start_point, --起始点数
				extra_chip = 50 --额外送的钱（从下注中抽取）
			},
			--JACKPOT_MINOR
			[4] = {
				start_point = prize_config.start_point, --起始点数
				extra_chip = 20 --额外送的钱（从下注中抽取）
			},
			--JACKPOT_MINI
			[5] = {
				start_point = prize_config.start_point, --起始点数
				extra_chip = 10 --额外送的钱（从下注中抽取）
			}
		}
	}
}
--************************************************
--------------------------------------------------

--------------------------------------------------
--*********************Bonus**********************
BonusEnter = {
	bonus_win = 0, --小游戏赢的筹码
	collect_num = 180, --目前玩家有的收集数量
	walk_pos = 0, --当前在地图中行走到的位置
	walk_end = false, --是否行走已经结束。当为true时，则说明行走已经结束，需要调用小游戏结算的接口
	--多轴转动的参数
	reels_spin_param = {
		--轴的结果
		reels = {
			--奖励得到的转轴
			[1] = {
				row_num = 3, --行数
				col_num = 5, --列数
				wild_cols = {1, 3} --有wild的列
			},
			[2] = {
				row_num = 3, --行数
				col_num = 5, --列数
				wild_cols = {1, 3} --有wild的列
			}
		},
		--转动的次数
		reels_spin_bouts = 10
	},
	--转盘配置
	turnaround_config = {
		--转盘的多个格子（result_id:[1~5] 对应[紫、绿、橙、黄、蓝]的空色块 6:收集狗爪奖励）
		[1] = {
			result_id = 1, --转盘格子的结果
			collect_num = 0 --收集物品的数量
		},
		[2] = {
			result_id = 6, --转盘格子的结果
			collect_num = 150 --收集物品的数量
		},
		[3] = {
			result_id = 2, --转盘格子的结果
			collect_num = 0 --收集物品的数量
		},
		[4] = {
			result_id = 3, --转盘格子的结果
			collect_num = 0 --收集物品的数量
		},
		[5] = {
			result_id = 6, --转盘格子的结果
			collect_num = 50 --收集物品的数量
		},
		[6] = {
			result_id = 4, --转盘格子的结果
			collect_num = 0 --收集物品的数量
		},
		[7] = {
			result_id = 6, --转盘格子的结果
			collect_num = 100 --收集物品的数量
		},
		[8] = {
			result_id = 5, --转盘格子的结果
			collect_num = 0 --收集物品的数量
		}
	},
	--当前地图的内容
	map_info = {
		--普通格子数组（即走路的色块，常态显示且未连续的数组）
		--prize_type:0:没有奖励 1.筹码奖励 2.ADD REELS 3.ADD FREE SPIN 4.ADD WILD REELS 5.ADD A ROW
		ordinary_item_arr = {
			[1] = {
				prize_type = 1,
				prize_val = 1000
			},
			[2] = {
				prize_type = 3,
				prize_val = 3
			},
			[3] = {
				prize_type = 3,
				prize_val = 2
			},
			[4] = {
				prize_type = 2,
				prize_val = 1
			}
			--一下的就不一一列举了，总共个对应格子数的元素
		},
		--特殊格子（即桥）
		--visable:是否显示
		special_item_arr = {
			[1] = {
				visable = true
			},
			[2] = {
				visable = true
			}
		}
	},
	--下次转盘spin的结果是否结束小游戏的预测
	--索引对应转盘的索引
	--数据模拟当前为倒数第3格时
	next_spin_predict = {
		[1] = {
			walk_end = true --下次走路是否结束
		},
		[2] = {
			walk_end = false --下次走路是否结束
		},
		[3] = {
			walk_end = true --下次走路是否结束
		},
		[4] = {
			walk_end = false --下次走路是否结束
		},
		[5] = {
			walk_end = false --下次走路是否结束
		},
		[6] = {
			walk_end = false --下次走路是否结束
		},
		[7] = {
			walk_end = true --下次走路是否结束
		},
		[8] = {
			walk_end = false --下次走路是否结束
		}
	}
}

BonusWalk = {
	walk_end = false, --是否行走已经结束。当为true时，则说明行走已经结束，需要调用小游戏结算的接口
	turnaround_result_idx = 1, --转盘结果索引（turnaround_config中的第几个元素）
	--转盘上的奖励（可扩展为多个）
	turnaround_prize = {
		collect_num = 100 --收集物品数
	},
	--走路奖励
	walk_prize = {
		--行走的记录
		[1] = {
			destin_pos = 11, --本次目的地
			--获得的奖励
			prize = {
				prize_type = 1,
				prize_val = 50
			},
			--地图元素改变
			map_change_info = {
				--普通元素改变数组(值为改变后的显示)
				--！！！注意，此处索引不连续！！
				ordinary_item_arr = {},
				special_item_arr = {}
			}
		},
		[2] = {
			destin_pos = 5, --本次目的地
			--获得的奖励
			prize = {
				prize_type = 4,
				prize_val = 1,
				--轴的结果（轴有改变时，才会发送）
				reels = {
					--奖励得到的转轴
					[1] = {
						row_num = 3, --行数
						col_num = 5, --列数
						wild_cols = {1, 3} --有wild的列
					},
					[2] = {
						row_num = 3, --行数
						col_num = 5, --列数
						wild_cols = {1, 3} --有wild的列
					}
				}
			},
			--地图元素改变
			map_change_info = {
				--普通元素改变数组(值为改变后的显示)
				--！！！注意，此处索引不连续！！
				ordinary_item_arr = {
					{
						pos = {1},
						data = {
							prize_type = 1,
							prize_val = 2000
						}
					}
				},
				special_item_arr = {
					{
						pos = {2},
						data = {
							visable = false
						}
					}
				}
			}
		}
	},
	--下次转盘spin的结果是否结束小游戏的预测
	--索引对应转盘的索引
	--数据模拟当前为倒数第3格时
	next_spin_predict = {
		[1] = {
			walk_end = true --下次走路是否结束
		},
		[2] = {
			walk_end = false --下次走路是否结束
		},
		[3] = {
			walk_end = true --下次走路是否结束
		},
		[4] = {
			walk_end = false --下次走路是否结束
		},
		[5] = {
			walk_end = false --下次走路是否结束
		},
		[6] = {
			walk_end = false --下次走路是否结束
		},
		[7] = {
			walk_end = true --下次走路是否结束
		},
		[8] = {
			walk_end = false --下次走路是否结束
		}
	}
}

--小游戏结算
BonusSettle = {
	bonus_win = 0, --小游戏赢的筹码
	collect_num = 180, --目前玩家有的收集数量
	--多轴转动的参数
	reels_spin_param = {
		--轴的结果
		reels = {
			--奖励得到的转轴
			[1] = {
				row_num = 3, --行数
				col_num = 5, --列数
				wild_cols = {1, 3} --有wild的列
			},
			[2] = {
				row_num = 3, --行数
				col_num = 5, --列数
				wild_cols = {1, 3} --有wild的列
			}
		},
		--转动的次数
		reels_spin_bouts = 10,
		--会触发的Action列表
		pre_action_list = {
			[1] = {
				action_type = 24,
				--转轴信息数组
				parameter_list = {
					--spin类型： 1.BASE_SPIN 2.COIN_SPIN 3.REELS_SPIN
					spin_type = 2,
					--spin次数：仅当COIN_SPIN、REELS_SPIN时有意义
					spin_bouts = 3,
					--转轴的信息
					reel_info_arr = {
						[1] = {id = 2, formation_name = "Formation2", line_name = "Lines2", feature_file_name = nil, wild_cols = {2}},
						[2] = {id = 3, formation_name = "Formation2", line_name = "Lines2", feature_file_name = nil, wild_cols = {2}},
						[3] = {id = 4, formation_name = "Formation2", line_name = "Lines2", feature_file_name = nil, wild_cols = {2}}
					}
				}
			}
		}
	}
}
--************************************************
--------------------------------------------------

--------------------------------------------------
--*********************Collect*********************
--请求收集物品的基本信息（第一次点开收集盒子时，请求）
CollectEnter = {
	--玩家身上剩余的收集物品数量
	collect_num = 2080,
	--当前礼盒所属于的页数
	curr_page = 1,
	--收集页的数组（目前是4页，一般不作修改）
	collect_page_arr = {
		[1] = {
			--开启每个box需要消耗的收集数量
			need_collect_num = 3000,
			--小盒子的信息数组
			little_box_info_arr = {
				[1] = {
					--是否已经开启了
					opened = true,
					--奖励信息（仅当opened==true时，才会有prize_info字段）
					prize_info = {
						prize_type = 1, --奖励类型 [1:筹码奖励 2:COIN_SPIN 3:BONUS_GAME 4:REELS_SPIN]
						prize_val = 1000 --奖励值
					}
				},
				[2] = {
					--是否已经开启了
					opened = false
					--奖励信息（仅当opened==true时，才会有prize_info字段）
					-- prize_info = {
					-- 	prize_type = 1, --奖励类型 [1:筹码奖励 2:COIN_SPIN 3:BONUS_GAME 4:REELS_SPIN]
					-- 	prize_val = 1000 --奖励值
					-- }
				},
				[3] = {},
				[4] = {},
				[5] = {},
				[6] = {},
				[7] = {},
				[8] = {},
				[9] = {}
			},
			--大盒子信息（整页小盒子都开启后的大奖励默认为reels_spin，所以不配置奖励类型）
			big_box_info = {
				--是否可以开启
				can_open = false,
				--是否已经开启了
				opened = false,
				--奖励信息
				prize_info = {
					prize_type = 4,
					prize_val = {
						--奖励得到的转轴
						reels = {
							[1] = {
								row_num = 4, --行数
								col_num = 5, --列数
								wild_cols = {2, 4} --有wild的列
							},
							[2] = {
								row_num = 4, --行数
								col_num = 5, --列数
								wild_cols = {2, 4} --有wild的列
							}
						},
						--转动的次数
						reels_spin_bouts = 15
					}
				}
			}
		},
		[2] = {},
		[3] = {},
		[4] = {}
	}
}
--打开收集的盒子
--请求参数
parameter = {
	--开启的是否是页面的大奖励盒子
	is_open_big_box = false,
	--开启盒子的位置信息
	box_pos = {
		page_idx = 1,
		arr_idx = 2
	}
}
--回复
CollectOpenBox = {
	--开盒子的请求信息
	open_request = {
		--开启的是否是页面的大奖励盒子
		is_open_big_box = false,
		--开启盒子的位置信息
		box_pos = {
			page_idx = 1,
			arr_idx = 2
		}
	},
	--开启的结果
	open_result = {
		--开启是否成功
		success = true,
		--开奖后，玩家身上剩余的收集物品数量
		collect_num = 2080,
		--当前礼盒所属于的页数
		curr_page = 1,
		--奖励信息(！！！除此注意判断，is_open_big_box = true的情况下，prize_val为一个tab)
		prize_info = {
			prize_type = 1, --奖励类型 [1:筹码奖励 2:COIN_SPIN 3:BONUS_GAME 4:COIN_SPIN]
			prize_val = 1000 --奖励值
		},
		--开启后产生状态变化的盒子，结构参考CollectEnter协议中的collect_page_arr字段(包括刚开启的盒子与一夜的小盒子开完导致大盒子变为可开启状态)
		change_collect_page_arr = {
			[2] = {
				--小盒子的信息数组
				little_box_info_arr = {
					[3] = {
						--是否已经开启了
						opened = true,
						--奖励信息（仅当opened==true时，才会有prize_info字段）
						prize_info = {
							prize_type = 1, --奖励类型 [1:筹码奖励 2:COIN_SPIN 3:BONUS_GAME 4:COIN_SPIN]
							prize_val = 1000 --奖励值
						}
					}
				},
				--大盒子信息（整页小盒子都开启后的大奖励默认为reels_spin，所以不配置奖励类型）
				big_box_info = {
					--是否可以开启
					can_open = true,
					--是否已经开启了
					opened = false,
					--奖励信息
					prize_info = {
						reels = {
							prize_type = 4,
							prize_val = {
								--奖励得到的转轴
								reels = {
									[1] = {
										row_num = 4, --行数
										col_num = 5, --列数
										wild_cols = {2, 4} --有wild的列
									},
									[2] = {
										row_num = 4, --行数
										col_num = 5, --列数
										wild_cols = {2, 4} --有wild的列
									}
								},
								--转动的次数
								reels_spin_bouts = 15
							}
						}
					}
				}
			}
		},
		--会触发的Action列表
		pre_action_list = {
			[1] = {
				action_type = 24,
				--转轴信息数组
				parameter_list = {
					--spin类型： 1.BASE_SPIN 2.COIN_SPIN 3.REELS_SPIN
					spin_type = 2,
					--spin次数：仅当COIN_SPIN、REELS_SPIN时有意义
					spin_bouts = 3,
					--转轴的信息
					reel_info_arr = {
						[1] = {id = 2, formation_name = "Formation2", line_name = "Lines2", feature_file_name = nil, wild_cols = {2}},
						[2] = {id = 3, formation_name = "Formation2", line_name = "Lines2", feature_file_name = nil, wild_cols = {2}},
						[3] = {id = 4, formation_name = "Formation2", line_name = "Lines2", feature_file_name = nil, wild_cols = {2}}
					}
				}
			}
		}
	}
}
--************************************************
--------------------------------------------------
