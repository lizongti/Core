#ifndef ANTS_CORE_THREAD_HPP
#define ANTS_CORE_THREAD_HPP

#include <thread>
#include <boost/lockfree/queue.hpp>
#include <ants/core/singleton.hpp>
#include <ants/core/queue.hpp>
#include <ants/core/service.hpp>
namespace ants
{
namespace core
{

class thread
{
public:
    thread()
    {
        thread_ = std::shared_ptr<std::thread>(new std::thread(work));
    }
    virtual ~thread(){};

public:
    static void work()
    {
        while (true)
        {
            auto service = singleton<queue<ants::core::service>>::instance().pop();
            if (service)
                service->work();
            else
                std::this_thread::sleep_for(std::chrono::milliseconds(1));
        }
    }

    std::thread::id get_id()
    {
        return thread_->get_id();
    }

protected:
    std::shared_ptr<std::thread> thread_;
};
}; // namespace core
} // namespace ants
#endif // ANTS_CORE_THREAD_HPP