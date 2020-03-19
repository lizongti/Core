#ifndef MESSAGE_HPP
#define MESSAGE_HPP

#include <stdlib.h>
#include "singleton.hpp"

namespace lime
{
namespace core
{
enum message_type
{
    MESSAGE_TYPE_SYSTEM = 0,
    MESSAGE_TYPE_PTR = 1,
    MESSAGE_TYPE_JSON = 2,
    MESSAGE_TYPE_PACKET = 3,
};
struct message
{
    message_type type;
    void *data;
    size_t len;
};
}; // namespace core
}; // namespace lime

#endif // ! MESSAGE_HPP