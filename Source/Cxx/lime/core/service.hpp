#ifndef SERVICE_HPP
#define SERVICE_HPP

#include "queue.hpp"
#include "message.hpp"

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
        message *m;
        while (m = q.pop())
        {
            // handle(m);
        }
    }

    void free()
    {
    }

protected:
    queue<message> q;
};
}; // namespace core
}; // namespace lime

#endif // !SERVICE_HPP