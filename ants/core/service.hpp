#ifndef ANTS_CORE_SERVICE_HPP
#define ANTS_CORE_SERVICE_HPP

#include <ants/core/queue.hpp>
#include <ants/core/module.hpp>

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
    void init(const std::string &name)
    {
        //thread_safe
        // get file name
    }

    void work()
    {
        void *msg;
        while (msg = q.pop())
        {
            m.work(msg);
        }
    }

    void fini()
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