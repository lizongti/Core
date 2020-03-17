#include "config.h"
#include "log.h"

bool config_util::parse_json(const std::string json, rapidjson::Document &document)
{
	document.SetObject();

	if (document.Parse<0>(json.c_str()).HasParseError())
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s], config json parse fail.\n") % __FUNCTION__;
		return false;
	}
	return true;
}

bool config_util::find_string(const rapidjson::Value &object, const std::string &member_name)
{
	if (!object.IsObject())
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] object is not object type!") % __FUNCTION__;
		return false;
	}
	if (!object.HasMember(member_name.c_str()))
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] object has no member %s!") % __FUNCTION__ % member_name;
		return false;
	}
	if (!object[member_name.c_str()].IsString())
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] member %s in object is not string !") % __FUNCTION__ % member_name;
		return false;
	}

	return true;
}

bool config_util::find_number(const rapidjson::Value &object, const std::string &member_name)
{
	if (!object.IsObject())
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] object is not object type!") % __FUNCTION__;
		return false;
	}
	if (!object.HasMember(member_name.c_str()))
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] object has no member %s!") % __FUNCTION__ % member_name;
		return false;
	}
	if (!object[member_name.c_str()].IsNumber())
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] member %s in object is not number !") % __FUNCTION__ % member_name;
		return false;
	}

	return true;
}

bool config_util::find_object(const rapidjson::Value &object, const std::string &member_name)
{
	if (!object.IsObject())
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] object is not object type!") % __FUNCTION__;
		return false;
	}
	if (!object.HasMember(member_name.c_str()))
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] object has no member %s!") % __FUNCTION__ % member_name;
		return false;
	}
	if (!object[member_name.c_str()].IsObject())
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] member %s in object is not object !") % __FUNCTION__ % member_name;
		return false;
	}

	return true;
}

bool config_util::find_array(const rapidjson::Value &object, const std::string &member_name)
{
	if (!object.IsObject())
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] object is not object type!") % __FUNCTION__;
		return false;
	}
	if (!object.HasMember(member_name.c_str()))
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] object has no member %s!") % __FUNCTION__ % member_name;
		return false;
	}
	if (!object[member_name.c_str()].IsArray())
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] member %s in object is not object !") % __FUNCTION__ % member_name;
		return false;
	}

	return true;
}

bool config_util::move_object(rapidjson::Value &array, const size_t &index, rapidjson::Value &value)
{
	if (!array.IsArray())
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] array is not array type!") % __FUNCTION__;
		return false;
	}
	if (index >= array.Size())
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] index over array size %d!") % __FUNCTION__ % index;
		return false;
	}
	if (!array[index].IsObject())
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] index %d in array is not object !") % __FUNCTION__ % index;
		return false;
	}

	value.SetObject();
	value = array[index].Move();

	return true;
}

bool config_util::move_array(rapidjson::Value &array, const size_t &index, rapidjson::Value &value)
{
	if (!array.IsArray())
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] array is not array type!") % __FUNCTION__;
		return false;
	}
	if (index >= array.Size())
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] index over array size %d!") % __FUNCTION__ % index;
		return false;
	}
	if (!array[index].IsArray())
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] index %d in array is not array !") % __FUNCTION__ % index;
		return false;
	}

	value.SetArray();
	value = array[index].Move();

	return true;
}

bool config_util::move_object(rapidjson::Value &object, const std::string &member_name, rapidjson::Value &value)
{
	if (!object.IsObject())
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] object is not object type!") % __FUNCTION__;
		return false;
	}
	if (!object.HasMember(member_name.c_str()))
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] object has no member %s!") % __FUNCTION__ % member_name;
		return false;
	}
	if (!object[member_name.c_str()].IsObject())
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] member %s in object is not object !") % __FUNCTION__ % member_name;
		return false;
	}

	value.SetObject();
	value = object[member_name.c_str()].Move();

	return true;
}

bool config_util::move_array(rapidjson::Value &object, const std::string &member_name, rapidjson::Value &value)
{
	if (!object.IsObject())
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] object is not object type!") % __FUNCTION__;
		return false;
	}
	if (!object.HasMember(member_name.c_str()))
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] object has no member %s!") % __FUNCTION__ % member_name;
		return false;
	}
	if (!object[member_name.c_str()].IsArray())
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] member %s in object is not array !") % __FUNCTION__ % member_name;
		return false;
	}

	value.SetArray();
	value = object[member_name.c_str()].Move();

	return true;
}

bool config_util::read_index(const rapidjson::Value &array, const size_t &index, bool &value)
{
	if (!array.IsArray())
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] array is not array type!") % __FUNCTION__;
		return false;
	}
	if (index >= array.Size())
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] index over array size %d!") % __FUNCTION__ % index;
		return false;
	}
	if (!array[index].IsBool())
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] index %d in array is not bool !") % __FUNCTION__ % index;
		return false;
	}

	value = array[index].GetBool();

	return true;
}

bool config_util::read_index(const rapidjson::Value &array, const size_t &index, std::string &value)
{
	if (!array.IsArray())
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] array is not array type!") % __FUNCTION__;
		return false;
	}
	if (index >= array.Size())
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] index over array size %d!") % __FUNCTION__ % index;
		return false;
	}
	if (!array[index].IsString())
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] index %d in array is not string !") % __FUNCTION__ % index;
		return false;
	}

	value = array[index].GetString();

	return true;
}

bool config_util::read_index(const rapidjson::Value &array, const size_t &index, int16_t &value)
{
	if (!array.IsArray())
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] array is not array type!") % __FUNCTION__;
		return false;
	}
	if (index >= array.Size())
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] index over array size %d!") % __FUNCTION__ % index;
		return false;
	}
	if (!array[index].IsNumber())
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] index %d in array is not number !") % __FUNCTION__ % index;
		return false;
	}

	value = static_cast<uint16_t>(array[index].GetDouble());

	return true;
}

bool config_util::read_index(const rapidjson::Value &array, const size_t &index, uint16_t &value)
{
	if (!array.IsArray())
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] array is not array type!") % __FUNCTION__;
		return false;
	}
	if (index >= array.Size())
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] index over array size %d!") % __FUNCTION__ % index;
		return false;
	}
	if (!array[index].IsNumber())
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] index %d in array is not number !") % __FUNCTION__ % index;
		return false;
	}

	value = static_cast<int16_t>(array[index].GetDouble());

	return true;
}

bool config_util::read_index(const rapidjson::Value &array, const size_t &index, int32_t &value)
{
	if (!array.IsArray())
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] array is not array type!") % __FUNCTION__;
		return false;
	}
	if (index >= array.Size())
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] index over array size %d!") % __FUNCTION__ % index;
		return false;
	}
	if (!array[index].IsNumber())
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] index %d in array is not number !") % __FUNCTION__ % index;
		return false;
	}

	value = static_cast<int32_t>(array[index].GetDouble());

	return true;
}

bool config_util::read_index(const rapidjson::Value &array, const size_t &index, uint32_t &value)
{
	if (!array.IsArray())
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] array is not array type!") % __FUNCTION__;
		return false;
	}
	if (index >= array.Size())
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] index over array size %d!") % __FUNCTION__ % index;
		return false;
	}
	if (!array[index].IsNumber())
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] index %d in array is not number !") % __FUNCTION__ % index;
		return false;
	}

	value = static_cast<uint32_t>(array[index].GetDouble());

	return true;
}

bool config_util::read_index(const rapidjson::Value &array, const size_t &index, int64_t &value)
{
	if (!array.IsArray())
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] array is not array type!") % __FUNCTION__;
		return false;
	}
	if (index >= array.Size())
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] index over array size %d!") % __FUNCTION__ % index;
		return false;
	}
	if (!array[index].IsNumber())
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] index %d in array is not number !") % __FUNCTION__ % index;
		return false;
	}

	value = static_cast<int64_t>(array[index].GetDouble());

	return true;
}

bool config_util::read_index(const rapidjson::Value &array, const size_t &index, uint64_t &value)
{
	if (!array.IsArray())
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] array is not array type!") % __FUNCTION__;
		return false;
	}
	if (index >= array.Size())
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] index over array size %d!") % __FUNCTION__ % index;
		return false;
	}
	if (!array[index].IsNumber())
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] index %d in array is not number !") % __FUNCTION__ % index;
		return false;
	}

	value = static_cast<uint64_t>(array[index].GetDouble());

	return true;
}

bool config_util::read_index(const rapidjson::Value &array, const size_t &index, float &value)
{
	if (!array.IsArray())
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] array is not array type!") % __FUNCTION__;
		return false;
	}
	if (index >= array.Size())
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] index over array size %d!") % __FUNCTION__ % index;
		return false;
	}
	if (!array[index].IsNumber())
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] index %d in array is not number !") % __FUNCTION__ % index;
		return false;
	}

	value = static_cast<float>(array[index].GetDouble());

	return true;
}

bool config_util::read_index(const rapidjson::Value &array, const size_t &index, double &value)
{
	if (!array.IsArray())
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] array is not array type!") % __FUNCTION__;
		return false;
	}
	if (index >= array.Size())
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] index over array size %d!") % __FUNCTION__ % index;
		return false;
	}
	if (!array[index].IsNumber())
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] index %d in array is not number !") % __FUNCTION__ % index;
		return false;
	}

	value = static_cast<double>(array[index].GetDouble());

	return true;
}

bool config_util::read_member(const rapidjson::Value &object, const std::string &member_name, bool &value)
{
	if (!object.IsObject())
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] object is not object type!") % __FUNCTION__;
		return false;
	}
	if (!object.HasMember(member_name.c_str()))
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] object has no member %s!") % __FUNCTION__ % member_name;
		return false;
	}
	if (!object[member_name.c_str()].IsBool())
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] member %s in object is not boolean !") % __FUNCTION__ % member_name;
		return false;
	}

	value = object[member_name.c_str()].GetBool();

	return true;
}

bool config_util::read_member(const rapidjson::Value &object, const std::string &member_name, std::string &value)
{
	if (!object.IsObject())
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] object is not object type!") % __FUNCTION__;
		return false;
	}
	if (!object.HasMember(member_name.c_str()))
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] object has no member %s!") % __FUNCTION__ % member_name;
		return false;
	}
	if (!object[member_name.c_str()].IsString())
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] member %s in object is not string !") % __FUNCTION__ % member_name;
		return false;
	}

	value = object[member_name.c_str()].GetString();

	return true;
}

bool config_util::read_member(const rapidjson::Value &object, const std::string &member_name, int16_t &value)
{
	if (!object.IsObject())
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] object is not object type!") % __FUNCTION__;
		return false;
	}
	if (!object.HasMember(member_name.c_str()))
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] object has no member %s!") % __FUNCTION__ % member_name;
		return false;
	}
	if (!object[member_name.c_str()].IsNumber())
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] member %s in object is not number !") % __FUNCTION__ % member_name;
		return false;
	}

	value = static_cast<int16_t>(object[member_name.c_str()].GetDouble());

	return true;
}

bool config_util::read_member(const rapidjson::Value &object, const std::string &member_name, uint16_t &value)
{
	if (!object.IsObject())
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] object is not object type!") % __FUNCTION__;
		return false;
	}
	if (!object.HasMember(member_name.c_str()))
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] object has no member %s!") % __FUNCTION__ % member_name;
		return false;
	}
	if (!object[member_name.c_str()].IsNumber())
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] member %s in object is not number !") % __FUNCTION__ % member_name;
		return false;
	}

	value = static_cast<uint16_t>(object[member_name.c_str()].GetDouble());

	return true;
}

bool config_util::read_member(const rapidjson::Value &object, const std::string &member_name, int32_t &value)
{
	if (!object.IsObject())
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] object is not object type!") % __FUNCTION__;
		return false;
	}
	if (!object.HasMember(member_name.c_str()))
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] object has no member %s!") % __FUNCTION__ % member_name;
		return false;
	}
	if (!object[member_name.c_str()].IsNumber())
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] member %s in object is not number !") % __FUNCTION__ % member_name;
		return false;
	}

	value = static_cast<int32_t>(object[member_name.c_str()].GetDouble());

	return true;
}

bool config_util::read_member(const rapidjson::Value &object, const std::string &member_name, uint32_t &value)
{
	if (!object.IsObject())
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] object is not object type!") % __FUNCTION__;
		return false;
	}
	if (!object.HasMember(member_name.c_str()))
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] object has no member %s!") % __FUNCTION__ % member_name;
		return false;
	}
	if (!object[member_name.c_str()].IsNumber())
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] member %s in object is not number !") % __FUNCTION__ % member_name;
		return false;
	}

	value = static_cast<uint32_t>(object[member_name.c_str()].GetDouble());

	return true;
}

bool config_util::read_member(const rapidjson::Value &object, const std::string &member_name, int64_t &value)
{
	if (!object.IsObject())
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] object is not object type!") % __FUNCTION__;
		return false;
	}
	if (!object.HasMember(member_name.c_str()))
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] object has no member %s!") % __FUNCTION__ % member_name;
		return false;
	}
	if (!object[member_name.c_str()].IsNumber())
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] member %s in object is not number !") % __FUNCTION__ % member_name;
		return false;
	}

	value = static_cast<int64_t>(object[member_name.c_str()].GetDouble());

	return true;
}

bool config_util::read_member(const rapidjson::Value &object, const std::string &member_name, uint64_t &value)
{
	if (!object.IsObject())
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] object is not object type!") % __FUNCTION__;
		return false;
	}
	if (!object.HasMember(member_name.c_str()))
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] object has no member %s!") % __FUNCTION__ % member_name;
		return false;
	}
	if (!object[member_name.c_str()].IsNumber())
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] member %s in object is not number !") % __FUNCTION__ % member_name;
		return false;
	}

	value = static_cast<uint64_t>(object[member_name.c_str()].GetDouble());

	return true;
}

bool config_util::read_member(const rapidjson::Value &object, const std::string &member_name, float &value)
{
	if (!object.IsObject())
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] object is not object type!") % __FUNCTION__;
		return false;
	}
	if (!object.HasMember(member_name.c_str()))
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] object has no member %s!") % __FUNCTION__ % member_name;
		return false;
	}
	if (!object[member_name.c_str()].IsNumber())
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] member %s in object is not number !") % __FUNCTION__ % member_name;
		return false;
	}

	value = static_cast<float>(object[member_name.c_str()].GetDouble());

	return true;
}

bool config_util::read_member(const rapidjson::Value &object, const std::string &member_name, double &value)
{
	if (!object.IsObject())
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] object is not object type!") % __FUNCTION__;
		return false;
	}
	if (!object.HasMember(member_name.c_str()))
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] object has no member %s!") % __FUNCTION__ % member_name;
		return false;
	}
	if (!object[member_name.c_str()].IsNumber())
	{
		LOG(SYS, ERROR) << boost::format("[Config][%s] member %s in object is not number !") % __FUNCTION__ % member_name;
		return false;
	}

	value = static_cast<double>(object[member_name.c_str()].GetDouble());

	return true;
}
