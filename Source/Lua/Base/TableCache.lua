------------------
--  Table Cache --
------------------
require "Util/StringExt"
_G.TableCache = {}

-- forbid repeated and bool type
function TableCache:Init()
	self.val_split_str = "|"
	self.key_split_str = "."
	self.action_type = {
		["number"] = "1",
		["string"] = "2",
		["table"] = "3",
		["boolean"] = "4",
		["1"] = "number",
		["2"] = "string",
		["3"] = "table"
	}
end

TableCache:Init()

local table_key_maps = {}

function TableCache:FullPath(parent_name, name)
	if parent_name then
		--生成字符串如player.id
		return parent_name..self.key_split_str..name
	else 
		return name
	end
end

function TableCache:InitNewTable(name, limit_keys)
	local tab = {}
	local tab_data = {}
	self:AddMetaTable(name, tab, tab_data, tab, limit_keys)
	return tab
end

function TableCache:SetTableValue(key, val, parent_name, parent_data, root, limit_keys)	
	local t = type(val)
	if t == "string" then
		parent_data[key] = val
	elseif t == "number" then
		parent_data[key] = math.floor(val)
	elseif t == "function" then
		local full_path = self:FullPath(parent_name, key)
		return self:SetTableValue(key, val(full_path), parent_name, parent_data, root, limit_keys)
	elseif t == "table" then
		local tab = {}
		local tab_data = {}
		local full_path = self:FullPath(parent_name, key)
		
		if root then
			self:AddMetaTable(full_path, tab, tab_data, root, limit_keys)
			for k,v in pairs(val) do
				self:SetTableValue(k, v, full_path, tab_data, root, limit_keys)
			end
			parent_data[key] = tab
		else
			root = tab -- init root
			self:AddMetaTable(full_path, tab, tab_data, root, limit_keys)
			for k,v in pairs(val) do
				self:SetTableValue(k, v, full_path, tab_data, root, limit_keys)
			end

			return root
		end
	end 
end

--将key和value写入到tab_actions中
function TableCache:DumpToActions(key, val, tab_actions, with_child)
	local tab_val = {}
	local t = type(val)
	table.insert(tab_val, self.action_type[t])

	if t == "string" then
		table.insert(tab_val, tostring(val))
	elseif t == "number" then
		table.insert(tab_val, tostring(math.floor(val)))
	elseif t == "table" then
		for k,v in pairs(getmetatable(val).data) do
			table.insert(tab_val, k)
			if with_child then
				self:DumpToActions(self:FullPath(key, k), v, tab_actions)
			end
		end
	end

	local v = table.concat(tab_val, self.val_split_str)

	if not with_child and t == "table" then
		if table_key_maps[key] and table_key_maps[key] == v then
			return
		else
			table_key_maps[key] = v
		end
	end

	tab_actions[key] = v
end

function TableCache:AddMetaTable(name, tab, tab_data, root, limit_keys)
	local tab_meta = {}
	tab_meta.actions = (tab == root) and {} or getmetatable(root).actions
	tab_meta.root = root
	tab_meta.data = tab_data
	tab_meta.name = name
	tab_meta.__index = tab_meta.data
	tab_meta.__newindex = function(t, key, val)
		--设置data里面的数据
		local old_val = tab_meta.data[key]
		self:SetTableValue(key, val, tab_meta.name, tab_meta.data, root, limit_keys)
		if limit_keys == nil or limit_keys[key] then
			if old_val ~= val then
				--设置脏数据
				self:DumpToActions(self:FullPath(tab_meta.name, key), tab_meta.data[key], tab_meta.actions, true)
			end
		end
		self:DumpToActions(tab_meta.name, tab, tab_meta.actions, false)
	end

	setmetatable(tab, tab_meta)
end

function TableCache:AddField(tab_fields, fields, parent, limit_keys)
	--对于每一个key
	for k,v in ipairs(fields) do
		if limit_keys then
			limit_keys[v.name] = true
		end
		--生成多个.的key
		local full_path = self:FullPath(parent, v.name)
		--插入表中
		table.insert(tab_fields, full_path)
		--如果是表结构，继续递归设置
		if v.cpp_type == 10 then
			self:AddField(tab_fields, v.message_type.fields, full_path, limit_keys)
		end
	end	
end

function TableCache:GetFields(name, proto_func, limit_keys)
	local tab_fields = {}
	--插入自身
	table.insert(tab_fields, name)
	--设置proto里面所有的key
	self:AddField(tab_fields, getmetatable(proto_func())._descriptor.fields, name, limit_keys)
	return tab_fields
end

--获取保存的语句
function TableCache:GetActionCommand(root)
	local tab_cmd_str = {}
	for k,v in pairs(getmetatable(root).actions) do
        if type(v) == "string" then
			-----对于string类型有个bug,无法存带空格的string,这里先用@代替掉,后续去cpp里改掉这个问题
			v = string.encode(v)
            table.insert(tab_cmd_str, string.format("HMSET %s %s %s", getmetatable(root).name, k, v))
        else
		    table.insert(tab_cmd_str, string.format("HMSET %s %s %s", getmetatable(root).name, k, v))
        end
	end
	local tab_actions = getmetatable(root).actions
	for k in pairs(tab_actions) do
		tab_actions[k] = nil
	end

	return tab_cmd_str
end

--通过proto结构体创建redis获取命令
function TableCache:GetBuildCommand(name, proto_struct)
	local tab_fields = self:GetFields(name, proto_struct)
	local tab_cmd_str = {}
	for k, v in pairs(tab_fields) do
		table.insert(tab_cmd_str, string.format("HMGET %s %s", name, v))
	end

	return tab_cmd_str
end

-- @static @intf
function TableCache:BuildTable(data, name, proto_struct)
	local tab_cache_value = data
	local limit_keys = {}
	local tab_cache_key = self:GetFields(name, proto_struct, limit_keys)
	local tab_cache_reply = {}

	for i = 1, #tab_cache_key, 1 do
		tab_cache_reply[tab_cache_key[i]] = tab_cache_value[i]
	end

	local function read_value(full_path)
		local reply = tab_cache_reply[full_path]
		if not reply or reply == "" then -- not inited
			return nil
		end
		local cons = string.split(reply, self.val_split_str)
		
		local t = self.action_type[cons[1]]
		table.remove(cons, 1)
		if t == "number" then
			return tonumber(cons[1])
		elseif t == "string" then
			-----对于string类型有个bug,无法存带空格的string,这里先用@代替掉,后续去cpp里改掉这个问题
			return string.decode(table.concat(cons, self.val_split_str))
		elseif t == "table" then
			local keys = {}
			for i, key in pairs(cons) do
				keys[key] = read_value
			end
			return keys
		end
	end

	local root = self:SetTableValue(name, read_value, nil, nil, nil, limit_keys)

	if not root then
		root = self:InitNewTable(name, limit_keys)
	end
	--clear all actions
	local tab_actions = getmetatable(root).actions
	for k in pairs(tab_actions) do
		tab_actions [k] = nil
	end

	return root
end
