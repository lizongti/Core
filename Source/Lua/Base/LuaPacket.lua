----------------
--  LuaPacket --
----------------
require "Base/Path"
require "Base/Protocol"
require "Base/TableCache"
require "Protocol/Player_pb"
require "Protocol/DbPlayer_pb"

if system.lua_version() >= 503 then
	pbc = require("protobuf_pb_53")
	_G.pbc = pbc
else
	require("protobuf_pb_51")
end

_G.LuaPacket = {}

-- Struct:
-- LuaPacket = {
--       data = {
--           module_id,         # module_id in lua, equals to module_id in object
--           message_id,        # message_id in lua, equals to message_id in object
--           object,            # proto encode, base64 encode data
--           proto_data,        # proto struct
--       }, 
--       object = {             # only operate by cpp function
--           size,		        # size of packet including 2 Bytes of itself
--           check_sum,	        # check sum from sequence_id to end, 4 Bytes
--           sequence_id,       # tcp sequence id from tcp connection build to destroy, 4 Bytes
--           module_id,		    # module id to route services, 2 Bytes
--           message_id,		# message id to locate it's handles, 2 Bytes
--           protobuf_size,     # size of protobuf, 4 Bytes
--           protobuf_content,  # content of protobuf
--       },     
--   }
-- 
-- Usage : 
-- Case 1 : Deserialize data from cpp object, cpp object already newed, execute the flow listed or Use CreateReadPacket()
--       ReadPacket()         # get packet from queue
--       LuaPacket:New()      # new lua object
--       Seize()              # ref cpp object
--       Check()              # check packet if packet is from client
--       Unseal()             # cpp data to lua data
--       Deserialize()        # to protobuf content to proto table, base64 decode, proto decode
--       Abandon()            # delete cpp object
--
-- Case 2 : Create data and put into a new cpp object, execute the flow listed or Use CreateWritePacket()
--       LuaPacket:New()      # new lua object
--       Prepare()            # prepare module id and message id
--       Serialize()          # normal table to proto table, to protobuf string, proto encode, base64 encode
--       Seal()               # new a cpp object with serialized data and specific sequence_id
--       WritePacket()        # push packet into queue

-- @static
function LuaPacket:New()
	local Instance = {
		object = nil,
		data = nil
	}
	setmetatable(Instance, self)
	self.__index = self
	return Instance
end

-- @static
function LuaPacket:CreateReadPacket(object, sequence_id, need_abandon)
	if not object then
		LOG(RUN, ERROR).Format("[LuaPacket][CreateReadPacket] args error!")
		return
	end
	
	local packet = LuaPacket:New()
	packet:Seize(object)
	if sequence_id and not packet:Check(sequence_id) and false then
		packet:Abandon()
		LOG(RUN, WARN).Format("[LuaPacket][CreateReadPacket] check packet failed!")
		return
	end
	packet:Unseal()
	packet:Deserialize()
	
	if need_abandon then
		packet:Abandon()
	end   
	
	return packet
end

-- @static
function LuaPacket:CreateWritePacket(data, sequence_id, time)
	local module_id = data.header.module_id
	local message_id = data.header.message_id
	if not module_id or not message_id or not data then
		LOG(RUN, ERROR).Format("[LuaPacket][CreateWritePacket] args error!")
		return
	end
	sequence_id = sequence_id or 0

	local packet = LuaPacket:New()
	packet:Prepare(module_id, message_id)
	packet:Serialize(data, time)
	packet:Seal(sequence_id)

	return packet
end

function LuaPacket:Seize(object)
	if not object then
		LOG(RUN, ERROR).Format("[LuaPacket][Seize] args error!")
		return 
	end
	self.object = object
	return self
end

function LuaPacket:Prepare(module_id, message_id)
	if not module_id or not message_id then
		LOG(RUN, ERROR).Format("[LuaPacket][Prepare] args error!")
	end
	local message = Protocol:Message(module_id, message_id)
	if not message then
		LOG(RUN, ERROR).Format("[LuaPacket][Prepare] cannot find message, module_id:%s, message_id:%s!", module_id, message_id)
		return
	end
	self.data = {
		module_id = message.module.id,
		message_id = message.id,
		requestTime = system.time(),
	}
	return self
end

function LuaPacket:Check(sequence_id)
	return self.object.check_sum == Packet:CalculateCheckSum(self.object) and self.object.sequence_id == sequence_id
end

function LuaPacket:Unseal()
	self.data = {
		module_id = self.object.module_id,
		message_id = self.object.message_id,
		object = Packet:ProtobufString(self.object)
	}
	return self
end

function LuaPacket:Seal(sequence_id)
	if not sequence_id then
		LOG(RUN, ERROR).Format("[LuaPacket][Seal] args error!")
		return 
	end
	self.object = Packet:Construct(sequence_id, self.data.__data.module_id, self.data.__data.message_id, self.data.object)
	return self
end

function LuaPacket:Deserialize()
	if not self.object.module_id or not self.object.message_id then
		LOG(RUN, ERROR).Format("[LuaPacket][Deserialize] args error!")
		return
	end

	local message = Protocol:Message(self.object.module_id, self.object.message_id)
	if not message then
		LOG(RUN, ERROR).Format("[LuaPacket][Deserialize] cannot find message, module_id:%s, message_id:%s!", self.object.module_id, self.object.message_id)
		return
	end

	local data = pbc.decodeAll(message.name, special_base64.decode(self.data.object))

	self.data = data
	data.header.module_id = message.module.name
	data.header.message_id = message.name
	return data
end

function LuaPacket:Serialize(data, time)
	if not self.data.module_id or not self.data.message_id then
		LOG(RUN, ERROR).Format("[LuaPacket][Serialize] args error!")
		return
	end
	local message = Protocol:Message(self.data.module_id, self.data.message_id)
	if not message then
		LOG(RUN, ERROR).Format("[LuaPacket][Serialize] cannot find message, module_id:%s, message_id:%s!", self.data.module_id, self.data.message_id)
		return
	end
    
	data.__data = {}
	data.__data.module_id = self.data.module_id
	data.__data.message_id = self.data.message_id
	data.header.time = time or system.time()

	local buf = pbc.encode(message.name, data)

	self.data = data
	self.data.object = special_base64.encode(buf)
	return self.data
end

function LuaPacket:Abandon()
	if self.object then
		Packet:Destroy(self.object)
		self.object = nil
	end
	return self
end