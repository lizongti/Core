#ifndef ANTS_CORE_SERVICE_HPP
#define ANTS_CORE_SERVICE_HPP

#include "queue.hpp"
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
    void load(const std::string &name)
    {
        //thread_safe
        // get file name
    }

    void work()
    {
        //thread_safe
        void *msg;
        while (msg = q.pop())
        {
            m.handle(msg);
        }
    }

    void unload()
    {
        //thread_safe
    }

protected:
    queue<void> q;
    module m;
};
}; // namespace core
}; // namespace ants

#endif // ANTS_CORE_SERVICE_HPP