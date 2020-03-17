BaseConfig = {
	tcp = {
		dispatcher = 10200
	},
	zeromq = {
		manager = {
			host = "slots-game-2-manager",
			port = 18800
		}
	},
	redis = {
		host = "172.31.16.33",
		port = 6379,
		password = ""
	},
	mysql = {
		host = "external-mysql.ctqs59rfmans.us-west-1.rds.amazonaws.com",
		port = 3306,
		username = "mirror",
		password = "FBYXR951rueBzz1mSY0Zx5KnPu0c76qQ",
		dbname = "slots_game"
	}
}
