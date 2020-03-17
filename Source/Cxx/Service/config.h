#ifndef CONFIG_HPP
#define CONFIG_HPP

#include <rapidjson/document.h>
#include <rapidjson/writer.h>
#include <rapidjson/stringbuffer.h>

class config_util
{
public:
	static bool parse_json(const std::string json, rapidjson::Document &document);

public:
	static bool find_string(const rapidjson::Value &object, const std::string &member_name);

	static bool find_number(const rapidjson::Value &object, const std::string &member_name);

	static bool find_object(const rapidjson::Value &object, const std::string &member_name);

	static bool find_array(const rapidjson::Value &object, const std::string &member_name);

public:
	static bool move_object(rapidjson::Value &array, const size_t &index, rapidjson::Value &value);

	static bool move_array(rapidjson::Value &array, const size_t &index, rapidjson::Value &value);

	static bool move_object(rapidjson::Value &object, const std::string &member_name, rapidjson::Value &value);

	static bool move_array(rapidjson::Value &object, const std::string &member_name, rapidjson::Value &value);

public:
	static bool read_index(const rapidjson::Value &array, const size_t &index, bool &value);

	static bool read_index(const rapidjson::Value &array, const size_t &index, std::string &value);

	static bool read_index(const rapidjson::Value &array, const size_t &index, int16_t &value);

	static bool read_index(const rapidjson::Value &array, const size_t &index, uint16_t &value);

	static bool read_index(const rapidjson::Value &array, const size_t &index, int32_t &value);

	static bool read_index(const rapidjson::Value &array, const size_t &index, uint32_t &value);

	static bool read_index(const rapidjson::Value &array, const size_t &index, int64_t &value);

	static bool read_index(const rapidjson::Value &array, const size_t &index, uint64_t &value);

	static bool read_index(const rapidjson::Value &array, const size_t &index, float &value);

	static bool read_index(const rapidjson::Value &array, const size_t &index, double &value);

public:
	static bool read_member(const rapidjson::Value &object, const std::string &member_name, bool &value);

	static bool read_member(const rapidjson::Value &object, const std::string &member_name, std::string &value);

	static bool read_member(const rapidjson::Value &object, const std::string &member_name, int16_t &value);

	static bool read_member(const rapidjson::Value &object, const std::string &member_name, uint16_t &value);

	static bool read_member(const rapidjson::Value &object, const std::string &member_name, int32_t &value);

	static bool read_member(const rapidjson::Value &object, const std::string &member_name, uint32_t &value);

	static bool read_member(const rapidjson::Value &object, const std::string &member_name, int64_t &value);

	static bool read_member(const rapidjson::Value &object, const std::string &member_name, uint64_t &value);

	static bool read_member(const rapidjson::Value &object, const std::string &member_name, float &value);

	static bool read_member(const rapidjson::Value &object, const std::string &member_name, double &value);

protected:
	std::string json;
	rapidjson::Document document;

#define CONFIG_CREATE_DOCUMENT(json, document)    \
	rapidjson::Document document;                 \
	if (!config_util::parse_json(json, document)) \
	{                                             \
		return false;                             \
	}

#define CONFIG_FOREACH_OBJECT(array, value)                 \
	for (size_t index = 0; index < array.Size(); ++index)   \
	{                                                       \
		rapidjson::Value value;                             \
		if (!config_util::move_object(array, index, value)) \
		{                                                   \
			return false;                                   \
		}

#define CONFIG_FOREACH_ARRAY(array, value)                 \
	for (size_t index = 0; index < array.Size(); ++index)  \
	{                                                      \
		rapidjson::Value value;                            \
		if (!config_util::move_array(array, index, value)) \
		{                                                  \
			return false;                                  \
		}

#define CONFIG_FOREACH_INDEX(array, index)                \
	for (size_t index = 0; index < array.Size(); ++index) \
	{

#define CONFIG_FOREACH_END \
	}

#define CONFIG_READ_MEMBER(object, member_name, value)         \
	if (!config_util::read_member(object, member_name, value)) \
	{                                                          \
		return false;                                          \
	}
#define CONFIG_READ_INDEX(array, index, value)         \
	if (!config_util::read_index(array, index, value)) \
	{                                                  \
		return false;                                  \
	}

#define CONFIG_MOVE_OBJECT(object, member_name_or_index, value)         \
	rapidjson::Value value;                                             \
	if (!config_util::move_object(object, member_name_or_index, value)) \
	{                                                                   \
		return false;                                                   \
	}
#define CONFIG_MOVE_ARRAY(object, member_name_or_index, value)         \
	rapidjson::Value value;                                            \
	if (!config_util::move_array(object, member_name_or_index, value)) \
	{                                                                  \
		return false;                                                  \
	}
#define CONFIG_FIND_STRING(object, member_name)         \
	if (!config_util::find_string(object, member_name)) \
	{                                                   \
		return false;                                   \
	}
#define CONFIG_FIND_NUMBER(object, member_name)         \
	if (!config_util::find_number(object, member_name)) \
	{                                                   \
		return false;                                   \
	}
#define CONFIG_FIND_OBJECT(object, member_name)         \
	if (!config_util::find_object(object, member_name)) \
	{                                                   \
		return false;                                   \
	}
#define CONFIG_FIND_ARRAY(object, member_name)         \
	if (!config_util::find_array(object, member_name)) \
	{                                                  \
		return false;                                  \
	}
};

#endif // !CONFIG_HPP
