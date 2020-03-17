----------
-- Rank --
----------
require "Common/Return"

module("Rank", package.seeall)

Challenge = function(_M, session, request)
	local response = {
		header = {
			router = "AsyncResponse", 
			client_id = session.client_id, 
			task_id = request.header.task_id
		}
	}

	session:WriteQueue("rank", request.data_json)

	response = {
		header = response.header,
		ret = Return.OK()
	}

	--return response
end