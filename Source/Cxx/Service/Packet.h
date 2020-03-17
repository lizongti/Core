#ifndef PACKET_HPP
#define PACKET_HPP

#include "Logger.h"

#pragma pack (1)
struct Packet
{
public:
	uint16_t size;				// size of packet including 2 Bytes of itself
	uint32_t check_sum;			// check sum from sequence_id to end, 4 Bytes
	uint32_t sequence_id;		// tcp sequence id from tcp connection build to destroy, 4 Bytes
	uint16_t module_id;			// module id to route services, 2 Bytes
	uint16_t message_id;		// message id to locate it's handles, 2 Bytes
	uint16_t protobuf_size;		// size of protobuf, 2 Bytes
	uint16_t message_flag;		// message type flag, tag if it compressed, etc
	char protobuf_content[];	// content of protobuf

public:
	static uint32_t CalculateCheckSum(Packet* packet);

	static std::string ProtobufString(Packet* packet);

	static Packet* Construct(
		uint32_t sequence_id,
		uint16_t module_id,
		uint16_t message_id,
		const std::string& protobuf_string);

	static void Destroy(Packet* packet);
	static Packet* Create(void * buf);
};
#pragma pack ()
#endif // !PACKET_HPP