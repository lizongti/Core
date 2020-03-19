#ifndef THREAD_HPP
#define THREAD_HPP

#include "singleton.hpp"
#include "queue.hpp"
#include "service.hpp"

namespace lime
{
namespace core
{

class thread
{
public:
    thread()
    {
        start();
    }
    virtual ~thread(){};

public:
    void join()
    {
        t->join();
    }

protected:
    void start()
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

protected:
    std::shared_ptr<std::thread> t;
};
}; // namespace core
} // namespace lime
#endif // !THREAD_HPP