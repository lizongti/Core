#ifndef ANTS_CORE_SERVICE_HPP
#define ANTS_CORE_SERVICE_HPP

#include "queue.hpp"
#include "message.hpp"
#include "module.hpp"

namespace ants
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
        message* msg;
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
}; // namespace ants

#endif // ANTS_CORE_SERVICE_HPP