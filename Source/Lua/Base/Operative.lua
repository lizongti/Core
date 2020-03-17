---------------
-- Operative --
---------------
require "Base/Path"
require "Common/GenOperativeConfig"
require "Config/system/ConstValue"

_G.Operative = {}

function Operative:Init()
	self.headers = {}
	for _, config_name in pairs({"Header"}) do
		for global_field_id, field_properties in pairs(GenOperativeConfig[config_name]) do
			self.headers[field_properties.category_name] = self.headers[field_properties.category_name] or {
				id = field_properties.category_id,
				name = field_properties.category_name,
				alias = field_properties.category_alias,
				fields = {},
			}
			self.headers[field_properties.category_name].fields[field_properties.field_id] = {
				id = field_properties.field_id,
				global_field_id = global_field_id,
				name = field_properties.field_name,
				alias = field_properties.field_alias,
				get_field_value = field_properties.get_field_value
			}
		end	
	end

	self.contents = {}
	for _, config_name in pairs({"Basic", "Extern", "Mod"}) do
		for global_field_id, field_properties in pairs(GenOperativeConfig[config_name]) do
			self.contents[field_properties.category_name] = self.contents[field_properties.category_name] or {
				id = field_properties.category_id,
				name = field_properties.category_name,
				alias = field_properties.category_alias,
				fields = {},
			}
			self.contents[field_properties.category_name].fields[field_properties.field_id] = {
				id = field_properties.field_id,
				global_field_id = global_field_id,
				name = field_properties.field_name,
				alias = field_properties.field_alias,
				get_field_value = field_properties.get_field_value
			}
		end	
	end

	local function add_result_pair(result, category, field, player, data)
		local fixed_global_field_id = field.global_field_id > 110000 and (field.global_field_id % 1000 + 110000) or field.global_field_id
		local key = string.format("[%s]%s", fixed_global_field_id, field.alias)
		local origin_value = field.get_field_value(category, player, data)
		local value
		if type(origin_value) == "table" then
			value = json.encode(origin_value)
		elseif type(origin_value) == "number" then
			value = tostring(origin_value)
		else
			value = origin_value
		end
		result[key] = value
	end

	for _, content in pairs(self.contents) do
		Operative[content.name] = function(self, player, data)
			if (player and player.character.player_type == tonumber(ConstValue[5].value)) then
				return
			end

			data = data or {}
			local object = Operative:New(content.name, player)
			local result = {}

			for _, header in pairs(self.headers) do
				for _, header_field in pairs(header.fields) do
					if type(player) == "table" then
						add_result_pair(result, content, header_field, player, data)
					else
						add_result_pair(result, content, header_field, nil, data)
					end
				end
			end

			for _, content_field in pairs(content.fields) do
				if type(player) == "table" then
					add_result_pair(result, content, content_field, player, data)
				else
					add_result_pair(result, content, content_field, nil, data)
				end
			end

			for _, content_field in pairs(content.fields) do
				if type(player) == "table" then
					add_result_pair(result, content, content_field, player, data)
				else
					add_result_pair(result, content, content_field, nil, data)
				end
			end
			LOG(OPT, INFO).Format(json.encode(result))
		end
		
	end
end
Operative:Init()

-- @static
function Operative:New(category, player)
	local Instance = {
		category = category,
		player = player
	}
	return Instance
end