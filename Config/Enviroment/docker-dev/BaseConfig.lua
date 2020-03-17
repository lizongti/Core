BaseConfig = {
	tcp = {
		dispatcher = 10000
	},
	zeromq = {
		manager = {
			host = "slots-game-manager",
			port = 18800
		}
	},
	redis = {
		host = "10.80.227.80",
		port = 6379,
		password = ""
	},
	mysql = {
		host = "10.80.227.80",
		port = 3306,
		username = "root",
		password = "123456",
		dbname = "slots_game"
	}
}
