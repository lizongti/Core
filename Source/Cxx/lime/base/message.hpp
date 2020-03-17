#ifndef MESSAGE_HPP
#define MESSAGE_HPP

#include "lime/base/singleton.hpp"

namespace lime
{
enum message_type
{
    MSG_TYPE_SYSTEM = 0,
    MSG_TYPE_PTR = 1,
    MSG_TYPE_JSON = 2,
    MSG_TYPE_PACKET = 3,
};

class message_queue
{
public:
    message_queue(){};
    virtual ~message_queue(){};

public:
};

class global_message_queue
    : public singleton<global_message_queue>
{
public:
    global_message_queue(){};
    virtual ~global_message_queue(){};

private:
};
}; // namespace lime

#endif // ! MESSAGE_HPP