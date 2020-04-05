#ifndef ANTS_CORE_THREAD_HPP
#define ANTS_CORE_THREAD_HPP

#include <thread>
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
            auto service = static_shared_queue<ants::core::service>::pop(true);
            if (!service)
            {
                std::cerr << "Get empty service when working." << std::endl;
                exit(1);
            }
            if (!service->work())
            {
                std::cerr << "Service work failed." << std::endl;
                exit(1);
            }
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