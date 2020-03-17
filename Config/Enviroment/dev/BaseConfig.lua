BaseConfig = {
	tcp = {
		dispatcher = 10000
	},
	zeromq = {
		manager = {
			host = "0.0.0.0",
			port = 18800
		}
	},
	redis = {
		host = "0.0.0.0",
		port = 6379,
		password = ""
	},
	mysql = {
		host = "0.0.0.0",
		port = 3306,
		username = "root",
		password = "123456",
		dbname = "slots_game"
	}
}
