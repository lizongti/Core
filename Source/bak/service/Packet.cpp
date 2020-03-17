#include "Packet.h"
#include "Pool.h"

uint32_t Packet::CalculateCheckSum(Packet *packet)
{
	if (!packet)
	{
		return 0;
	}
	uint32_t ret = packet->sequence_id + 20160601;
	unsigned char *buffer = (unsigned char *)(void *)packet;
	for (auto i = packet->size - 1; i >= 10; --i)
	{
		ret = (ret << 1) ^ buffer[i];
	}
	return ret;
}

std::string Packet::ProtobufString(Packet *packet)
{
	if (!packet)
	{
		return "";
	}

	char *buf = new char[packet->protobuf_size + 1];
	if (!buf)
	{
		LOG(SYS, ERROR) << boost::format("[Packet %x][%s] packet %d %d buf too small short:0.\n") % packet % __FUNCTION__ % packet->module_id % packet->message_id;
		return "";
	}
	std::memcpy(buf, &(packet->protobuf_content), packet->protobuf_size);
	buf[packet->protobuf_size] = '\0';
	std::string val(buf);
	delete[] buf;
	return val;
}

Packet *Packet::Construct(
	uint32_t sequence_id,
	uint16_t module_id,
	uint16_t message_id,
	const std::string &protobuf_string)
{
	uint16_t size = 18 + protobuf_string.length();
	Packet *packet = (Packet*)memory_pool::malloc(size);
	packet->size = size;
	packet->sequence_id = sequence_id;
	packet->module_id = module_id;
	packet->message_id = message_id;
	packet->protobuf_size = protobuf_string.length();
	packet->message_flag = 0;

	std::memcpy(packet->protobuf_content, protobuf_string.c_str(), protobuf_string.length());
	packet->check_sum = CalculateCheckSum(packet);

	return packet;
}

void Packet::Destroy(Packet *packet)
{
	if (packet)
	{
		memory_pool::free(packet);
	}
}