#ifndef ANTS_CORE_THREAD_HPP
#define ANTS_CORE_THREAD_HPP

#include <thread>
#include <boost/lockfree/queue.hpp>
#include "singleton.hpp"
#include "queue.hpp"
#include "service.hpp"
namespace ants
{
namespace core
{

class thread
{
public:
    thread()
    {
        t = std::shared_ptr<std::thread>(new std::thread([]() {
            while (true)
            {
                auto s = singleton<queue<service>>::instance().pop();
                if (s)
                    s->work();
                else
                    std::this_thread::sleep_for(std::chrono::milliseconds(1));
            }
        }));
    }
    virtual ~thread(){};

public:
    void join()
    {
        t->join();
    }

protected:
    std::shared_ptr<std::thread> t;
};
}; // namespace core
} // namespace ants
#endif // ANTS_CORE_THREAD_HPP