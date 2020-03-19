#ifndef SERVICE_HPP
#define SERVICE_HPP

#include "queue.hpp"
#include "message.hpp"
#include "module.hpp"

namespace lime
{
namespace core
{
class service
{
public:
    service()
    {
    }
    virtual ~service()
    {
    }

public:
    void load(const std::string &path)
    {
    }

    void work()
    {
        message *msg;
        while (msg = q.pop())
        {
            m.handle(msg);
        }
    }

    void free()
    {
    }

protected:
    queue<message> q;
    module m;
};
}; // namespace core
}; // namespace lime

#endif // !SERVICE_HPP