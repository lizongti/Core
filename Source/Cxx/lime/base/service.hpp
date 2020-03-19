#ifndef SERVICE_HPP
#define SERVICE_HPP

#include <boost/lockfree/queue.hpp>
#include "lime/base/message.hpp"

namespace lime
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
    void work()
    {
        message *m;
        while (queue.pop(m))
        {
        }
    }

protected:
    boost::lockfree::queue<message *> queue;
};

}; // namespace lime

#endif // !SERVICE_HPP