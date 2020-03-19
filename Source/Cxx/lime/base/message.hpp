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
class message{
public:

};
}; // namespace lime

#endif // ! MESSAGE_HPP