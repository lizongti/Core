----------------
-- Hash Cache --
----------------

_G.HashCache = {}

-- forbid bool type
function HashCache:Init()
	self.val_split_str = "|"
	self.key_split_str = "|"
	self.action_type = {
		["number"] = "1",
		["string"] = "2",
		["table"] = "3",
		["1"] = "number",
		["2"] = "string",
		["3"] = "table"
	}
end
HashCache:Init()

function HashCache:InitNewHash(name)
	local hash = {}
	local hash_data = {}
	self:AddMetaTable(name, hash, hash_data, hash)
	return hash
end

function HashCache:SetHashValue(key, value, parent_data)
	parent_data[key] = value
end

function HashCache:DumpToActions(key, val, tab_actions)
	local function write_key(key)
		local key_tab = {}
		local t = type(key)
		table.insert(key_tab, self.action_type[t])
		if t == "table" then
			table.insert(key_tab, json.encode(key))
		elseif t == "string" then
			table.insert(key_tab, tostring(key))
		elseif t == "number" then
			table.insert(key_tab, tostring(math.floor(key)))        
		end

		return table.concat(key_tab, self.key_split_str)
	end

	local function write_val(val)
		local val_tab = {}
		local t = type(val)
		table.insert(val_tab, self.action_type[t])
		if t == "table" then
			table.insert(val_tab, json.encode(val))
		elseif t == "string" then
			table.insert(val_tab, tostring(val))
		elseif t == "number" then
			table.insert(val_tab, tostring(math.floor(val)))        
		end

		return table.concat(val_tab, self.val_split_str)
	end


	if val == nil then
		local key_str = write_key(key)
		tab_actions[write_key(key)] = "none"
	else
		local key_str = write_key(key)
		local val_str = write_val(val)
		tab_actions[write_key(key)] = write_val(val)
	end
end

function HashCache:AddMetaTable(name, hash, hash_data, root)
	local hash_meta = {}
	hash_meta.actions = {}
	hash_meta.root = root
	hash_meta.data = hash_data
	hash_meta.name = name
	hash_meta.__index = hash_meta.data
	hash_meta.__newindex = function(t, key, val)
		if val == hash_meta.data[key] then
			return
		end
		if type(val) == "table" then
			local tab_meta = {
				__index = {
					Dump = function()
						self:DumpToActions(key, val, hash_meta.actions)
					end
				}
			}
			setmetatable(val, tab_meta)
		end
		self:SetHashValue(key, val, hash_meta.data)
		self:DumpToActions(key, val, hash_meta.actions)
	end

	setmetatable(hash, hash_meta)
end

-- @static @intf
function HashCache:GetActionCommand(root)
	local tab_cmd_str = {}
	for k,v in pairs(getmetatable(root).actions) do
		if v == "none" then
			table.insert(tab_cmd_str, string.format("HDEL %s %s", getmetatable(root).name, k))
		else
			table.insert(tab_cmd_str, string.format("HMSET %s %s %s", getmetatable(root).name, k, v))
		end
	end
	local tab_actions = getmetatable(root).actions
	for k in pairs(tab_actions) do
		tab_actions [k] = nil
	end

	return tab_cmd_str
end

-- @static @intf
function HashCache:GetBuildCommand(name)
	local tab_cmd_str = {}
	table.insert(tab_cmd_str, string.format("HGETALL %s", name))
	return tab_cmd_str
end

-- @static @intf
-- type : "number" "string" "table" "nil"
-- root : nil , to Init a new one
function HashCache:BuildHash(reply, name, root)
	local function read_key(key_str)
		if not key_str or key_str == "" then
			return nil
		end
		local cons = string.split(key_str, self.key_split_str)
		
		local t = self.action_type[cons[1]]
		table.remove(cons, 1)
		if t == "number" then
			return tonumber(cons[1])
		elseif t == "string" then
			return table.concat(cons, self.key_split_str)
		elseif t == "table" then
			return json.decode(cons[1])
		end
	end

	local function read_value(val_str)
		if not val_str or val_str == "" then
			return nil
		end
		local cons = string.split(val_str, self.val_split_str)
		
		local t = self.action_type[cons[1]]
		table.remove(cons, 1)
		if t == "number" then
			return tonumber(cons[1])
		elseif t == "string" then
			return table.concat(cons, self.val_split_str)
		elseif t == "table" then
			return json.decode(cons[1])
		end
	end

	reply = reply or {}
	if not root then
		root = self:InitNewHash(name)
	end

	local root_data = getmetatable(root).data

	if #reply >= 2 then
		for k, v in ipairs(reply) do
			if k % 2 == 1 then
				local origin_key = reply[k]
				local origin_value = reply[k + 1]

				local key = read_key(origin_key)
				local value = read_value(origin_value)
				if not root_data[key] then
					root[key] = value
				end
			end
		end
	end

	-- clear all actions
	local hash_actions = getmetatable(root).actions
	for k,v in pairs(hash_actions) do
		hash_actions[k] = nil
	end

	return root
end

-- @static @intf
function HashCache:Pairs(root)
	return pairs(getmetatable(root).data)
end