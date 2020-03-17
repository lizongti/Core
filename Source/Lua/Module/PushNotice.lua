module("PushNotice", package.seeall)

NoticeType = {
	SettleTournament = 1,
	FinishChallenge = 2
}

SettleTournament = function ( _M, session, request )
	local response = {
		header = {
			router = "AsyncResponse", 
			client_id = session.client_id, 
			task_id = request.header.task_id
		}
	}

	local club_id = request.club_id
	local rank = request.rank
	local data = {
		type = NoticeType.SettleTournament,
		club_id = club_id,
		rank = rank
	}

	session:WriteQueue("pushnotice", json.encode(data))

	response = {
		header = response.header,
		ret = Return.OK()
	}

	return response
end

FinishChallenge = function ( _M, session, request )
	local response = {
		header = {
			router = "AsyncResponse", 
			client_id = session.client_id, 
			task_id = request.header.task_id
		}
	}

	local club_id = request.club_id
	local challenge_index = request.challenge_index
	local data = {
		type = NoticeType.FinishChallenge,
		club_id = club_id,
		challenge_index = challenge_index
	}
	session:WriteQueue("pushnotice", json.encode(data))

	response.ret = Return.OK()
	return response
end