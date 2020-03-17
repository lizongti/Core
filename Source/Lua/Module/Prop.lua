-----------------
--     Prop    --
-----------------
require "Common/Return"

module("Prop", package.seeall)

require "Config/PropConfig"

Purchase = function(_M, session, request)
	local response = {header = {router = "Response"}}
	if not session or not session.player then
		response.ret = Return.PLAYER_NOT_FOUND()
		return response
	end

	if request.item.amount <= 0 then
		response.ret = Return.PROP_AMOUNT_NOT_CORRECT()
		return response
	end

	local player = session.player

	local purchase_item = {request.item.id, request.item.amount}

	local ret, currency_items = Player:Purchase(player, purchase_item)
	if not ret then
		response.ret = Return.PROP_PURCHASE_FAIL()
		return response
	end

	response = {
		header = response.header,
		ret = Return.OK(),
		item = {request.item},
		prop = player.prop,
		player = {
			character = {
				gold = player.character.gold
			}
		}
	}

	return response
end

Use = function(_M, session, request)
	local response = {header = {router = "Response"}}
	if not session or not session.player then
		response.ret = Return.PLAYER_NOT_FOUND()
		return response
	end

	if request.item.amount <= 0 then
		response.ret = Return.PROP_AMOUNT_NOT_CORRECT()
		return response
	end

	local player = session.player

	local use_item = {request.item.id, request.item.amount}
	local ret, obtain_items, is_jackpot = Player:Use(player, use_item, "use", session)
	if not ret then
		response.ret = Return.PROP_PURCHASE_FAIL()
		response.item = request.item
		response.prop = player.prop
		return response
	end

	local resp_obtain_items = {}
	for _, v in pairs(obtain_items) do
		table.insert(resp_obtain_items, {id = v[1], amount = v[2]})
	end

	response = {
		header = response.header,
		ret = Return.OK(),
		item = request.item,
		obtain_items = resp_obtain_items,
		is_jackpot = is_jackpot,
		prop = player.prop,
		player = {
			character = {
				gold = player.character.gold,
			}
		}
	}

	-- opt


	Spark:UseProp(player, {
		[1] = PropConfig.PropMap[use_item[1]].name,
		[2] = use_item[2],
		[3] = PropConfig.PropMap[obtain_items[1][1]].name,
		[4] = obtain_items[1][2],
	})
	return response
end

Sell = function(_M, session, request)
	local response = {header = {router = "Response"}}
	if not session or not session.player then
		response.ret = Return.PLAYER_NOT_FOUND()
		return response
	end

	if request.item.amount <= 0 then
		response.ret = Return.PROP_AMOUNT_NOT_CORRECT()
		return response
	end

	local player = session.player

	local sell_item = {request.item.id, request.item.amount}

	local ret, currency_items = Player:Sell(player, sell_item)
	if not ret then
		response.ret = Return.PROP_SELL_FAIL()
		return response
	end

	response = {
		header = response.header,
		ret = Return.OK(),
		item = currency_items,
		prop = player.prop,
	}
	return response
end