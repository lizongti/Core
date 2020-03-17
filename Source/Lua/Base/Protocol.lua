--------------
-- Protocol --
--------------
require "Base/Path"
require "Util/PrintExt"
require "Util/TableExt"
require "special_base64"
require "Common/ProtocolDefine"
require "Protocol/pbgen"

local init_pb = false

_G.Protocol = {}
Protocol.Container = ProtocolDefine

-- @static
function Protocol:Init(service_name)
	self:SetupModules(service_name)
	Protocol:InitPB()
end

function Protocol:InitPB()
	if init_pb then
		return
	end

	if system.lua_version() >= 503 then
		_G.pbc = require("protobuf_pb_53")
	else
		require("protobuf_pb_51")
	end

	for k, v in ipairs(pbc_gen) do
		pbc.register_file("../Source/Lua/pb/" .. v)
	end

	init_pb = true
end

-- @static
function Protocol:CheckModule(module_name)
	local function call_func()
		local success, error = pcall(require, "Module/" .. module_name)
		if not success then
			LOG(SYS, ERROR).Format("[Protocol][CheckModule] load error: %s", module_name)
		end
		local success, error = pcall(require, "Protocol/" .. module_name .. "Message_pb")
		if not success then
			LOG(SYS, ERROR).Format("[Protocol][CheckModule] load error: %s", module_name)
		end
	end
	local function error_func(error_msg)
		LOG(RUN, ERROR).Format("[Protocol][Sandbox]%s", debug.traceback(tostring(error_msg)))
	end
	return xpcall(call_func, error_func)
end

function Protocol:FindModule(module_name)
	for _, v in pairs(self.Container) do
		if v.name == module_name then
			return v
		end
	end
end

function Protocol:ReloadModule(module_name, module)
	if not module then
		module = self:FindModule(module_name)
		if not module then
			return
		end
	end

	--modules
	self.modules[module_name] = self.modules[module_name] or {}
	self.modules[module_name].id = module.id
	self.modules[module_name].name = module.name
	self.modules[module_name].object = _G[module_name]
	self.dictionary[self.modules[module_name].id] = self.modules[module_name]
	--LOG(SYS, INFO).Format("[Protocol][SetupModules] module name: %s, module id %s setup ok.", module.name, module.id)

	--messages
	self.modules[module_name].messages = {}
	for message_id, message_name in pairs(module.messages) do
		self.modules[module_name].messages[message_name] = {}
		self.modules[module_name].messages[message_name].id = message_id
		self.modules[module_name].messages[message_name].name = message_name
		self.modules[module_name].messages[message_name].module = self.modules[module_name]
		self.modules[module_name].messages[message_name].object = _G[module_name .. "Message_pb"][message_name]

		local id = 65536 * self.modules[module_name].id + self.modules[module_name].messages[message_name].id
		self.messages[id] = self.modules[module_name].messages[message_name]
		--LOG(SYS, INFO).Format("[Protocol][SetupModules] module name %s, message name %s, message id %s setup ok.", module.name, message_name, id)
	end

	--handlers
	self.modules[module_name].handlers = {}
	for _, handler in pairs(module.handlers) do
		local handler_name = handler[1]
		local request_name = handler[2]
		--LOG(SYS, INFO).Format("[Protocol][SetupModules] module name %s, handler name %s setup bein.", module.name, handler_name)
		self.modules[module_name].handlers[handler_name] = {}
		self.modules[module_name].handlers[handler_name].id = self.modules[module_name].messages[request_name].id
		self.modules[module_name].handlers[handler_name].name = handler_name
		self.modules[module_name].handlers[handler_name].module = self.modules[module_name]
		self.modules[module_name].handlers[handler_name].object = self.modules[module_name].object[handler_name]
		self.modules[module_name].handlers[handler_name].request = self.modules[module_name].messages[request_name]
		self.modules[module_name].handlers[handler_name].response = {}
		for idx = 3, #handler, 1 do
			table.insert(
				self.modules[module_name].handlers[handler_name].response,
				self.modules[module_name].messages[handler[idx]]
			)
		end
		--dictionary
		local id = 65536 * self.modules[module_name].id + self.modules[module_name].handlers[handler_name].id
		self.dictionary[id] = self.modules[module_name].handlers[handler_name]
		--LOG(SYS, INFO).Format("[Protocol][SetupModules] module name %s, handler name %s, handler id %s setup ok.", module.name, handler_name, id)
	end
end

-- @static
function Protocol:SetupModules(service_name)
	self.modules = self.modules or {}
	self.messages = self.messages or {}
	self.dictionary = self.dictionary or {}
	for _, module in pairs(self.Container) do
		local module_name = module.name
		if Protocol:CheckModule(module_name) then
			Protocol:ReloadModule(module_name, module)
		else
			LOG(SYS, ERROR).Format(
				"[Protocol][SetupModules] module name: %s, require failed. Continuing services with other modules!",
				module.name
			)
		end
	end
	return self
end

-- @static
function Protocol:Module(module_name)
	if self.modules[module_name] then -- locate message by name
		return self.modules[module_name]
	elseif self.dictionary[module_name] then -- locate message by id
		return self.dictionary[module_name]
	else
		LOG(RUN, WARN).Format("[Protocol][Module] module %s not exist!", module_name)
	end
end

-- @static
function Protocol:Handler(module_name, handler_name)
	local module = self:Module(module_name)
	if not module then
		LOG(RUN, WARN).Format("[Protocol][Handler] module %s not exist!", module_name)
		return
	end
	if module.handlers[handler_name] then -- locate message by name
		return module.handlers[handler_name]
	elseif self.dictionary[module.id * 65536 + handler_name] then -- locate message by id
		return self.dictionary[module.id * 65536 + handler_name]
	else
		LOG(RUN, WARN).Format("[Protocol][Handler] handler %s, %s not exist!", module_name, handler_name)
	end
end

-- @static
function Protocol:Message(module_name, message_name)
	local module = self:Module(module_name)
	if not module then
		LOG(RUN, WARN).Format("[Protocol][Message] module %s not exist!", module_name)
		return
	end

	if module.messages[message_name] then -- locate message by name
		return module.messages[message_name]
	elseif self.messages[module.id * 65536 + message_name] then -- locate message by id
		return self.messages[module.id * 65536 + message_name]
	else
		LOG(RUN, WARN).Format("[Protocol][Message] message %s, %s not exist!", module_name, message_name)
	end
end
