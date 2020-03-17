------------------------------------------------------------------------------
----由Header,Basic,Extern,Mod四个表产生的日志总表,这套导表无法直接导出这样的表
----所以放Common里,不放Config里,Config是共享的,容易被别人导表提交导致删除了
------------------------------------------------------------------------------
module("GenOperativeConfig", package.seeall)
require "Config/ServerConfig"

Header = {}

local header_field_name_to_value = {
	["Time"] = function ( category, player, data )
		return os.date("%Y-%m-%d %X")
	end,
	["Category"] = function ( category, player, data )
		return category.name
	end,
	["CategoryAlias"] = function ( category, player, data )
		return category.alias
	end,
	["Package"] = function ( category, player, data )
		return player and player.client.package
	end,
	["Version"] = function ( category, player, data )
		return player and player.client.version
	end,
	["Channel"] = function ( category, player, data )
		return player and player.client.channel
	end,
	["EthIP"] = function ( category, player, data )
		return player and player.client.eth_ip
	end,
	["IP"] = function ( category, player, data )
		return player and player.client.ip
	end,
	["MAC"] = function ( category, player, data )
		return player and player.client.mac
	end,
	["Device"] = function ( category, player, data )
		return player and player.client.device
	end,
	["OS"] = function ( category, player, data )
		return player and player.client.os
	end,
	["ImeiIdfa"] = function ( category, player, data )
		return player and player.client.imei_idfa
	end,
	["AccountType"] = function ( category, player, data )
		return player and player.account.account_type
	end,
	["InitChannel"] = function ( category, player, data )
		return player and player.character.init_channel
	end,
	["PlayerId"] = function ( category, player, data )
		return player and player.id
	end,
	["Charge"] = function ( category, player, data )
		return player and player.character.charge
	end,
	["MonthCharge"] = function ( category, player, data )
		return player and player.character.month_charge
	end,
	["DailyCharge"] = function ( category, player, data )
		return player and player.character.daily_charge
	end,
	["VIPPoints"] = function ( category, player, data )
		return player and player.character.vip_points
	end,
	["Experience"] = function ( category, player, data )
		return player and player.character.experience
	end,
	["Level"] = function ( category, player, data )
		return player and player.character.level
	end,
	["NickName"] = function ( category, player, data )
		return player and player.user.nickname
	end,
	["Sex"] = function ( category, player, data )
		return player and player.user.sex
	end,
	["Signature"] = function ( category, player, data )
		return player and player.user.signature
	end,
	["CreateTime"] = function ( category, player, data )
		return player and os.date("%Y-%m-%d %X", player.character.create_time)
	end,
	["LoginTime"] = function ( category, player, data )
		return player and os.date("%Y-%m-%d %X", player.character.login_time)
	end,
	["LastLoginTime"] = function ( category, player, data )
		return player and os.date("%Y-%m-%d %X", player.character.last_login_time)
	end,
	["Chip"] = function ( category, player, data )
		return player and player.character.chip
	end,
	["Record"] = function ( category, player, data )
		return ""
	end,
	["Diamond"] = function ( category, player, data )
		return 0
	end,
	["FacebookID"] = function ( category, player, data )
		return player and player.account.facebook_id
	end,
	["GoogleID"] = function ( category, player, data )
		return player and player.account.google_id
	end,
}

for k,v in pairs(OperativeHeaderConfig) do
	local global_id = v.category_id * 1000 + v.field_id
	Header[global_id] = v
	Header[global_id].get_field_value = function ( category, player, data )
		if v.field_value and v.field_value ~= "" then
			return v.field_value
		else
			if header_field_name_to_value[v.field_name] then
				return header_field_name_to_value[v.field_name](category, player, data)
			end
		end
	end
end

Basic = {}

for k,v in pairs(OperativeBasicConfig) do
	local global_id = v.category_id * 1000 + v.field_id
	Basic[global_id] = v
	Basic[global_id].get_field_value = function ( category, player, data )
		return data[v.field_value_index]
	end
end

Extern = {}

for k,v in pairs(OperativeExternConfig) do
	local global_id = v.category_id * 1000 + v.field_id
	Extern[global_id] = v
	Extern[global_id].get_field_value = function ( category, player, data )
		return data[v.field_value_index]
	end
end

Mod = {}

for k,v in pairs(OperativeModConfig) do
	local global_id = v.category_id * 1000 + v.field_id
	Mod[global_id] = v
	Mod[global_id].get_field_value = function ( category, player, data )
		return data[v.field_value_index]
	end
end
