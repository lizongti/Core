#ifndef SERVICE_HPP
#define SERVICE_HPP

#include "lime/base/service.hpp"

namespace lime
{
class service
{
public:
    virtual ~service() = 0;

public:
    virtual bool init(const std::string &json) = 0;

    virtual bool handle(const std::string &sender, MessageType type, void *data) = 0;

    virtual bool release() = 0;
};

}; // namespace lime

#endif // !SERVICE_HPP