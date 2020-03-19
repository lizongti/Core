#ifndef GLOBAL_SERVICE_QUEUE_HPP
#define GLOBAL_SERVICE_QUEUE_HPP

#include <boost/lockfree/queue.hpp>

#include "lime/base/singleton.hpp"
#include "lime/base/service.hpp"

namespace lime
{
class service_queue
    : public singleton<service_queue>
{
public:
    service_queue(){};
    virtual ~service_queue(){};

public:
    void reserve(size_t n)
    {
        queue.reserve(n);
    }
    service *pop()
    {
        service *s;
        return queue.pop(s) ? s : nullptr;
    }
    bool push(service *s)
    {
        return queue.bounded_push(s);
    }

protected:
    boost::lockfree::queue<service *> queue;
};
} // namespace lime
#endif // ! GLOBAL_SERVICE_QUEUE_HPP