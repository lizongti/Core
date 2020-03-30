#ifndef ANTS_CORE_SERVICE_HPP
#define ANTS_CORE_SERVICE_HPP

#include <ants/core/queue.hpp>
#include <ants/core/module.hpp>
#include <ants/core/singleton.hpp>

namespace ants
{
namespace core
{
class service
{
public:
    void init(std::string const &service_name, std::string const &module_name)
    {
        // singleton<module_loader>::instance().load()
        //check service name, check module name
        // get file name
    }

    void work()
    {
        void *message;
        while (message = queue.pop())
        {
            module.work(message);
        }
    }

    void fini()
    {
        //thread_safe
    }

protected:
    queue<void> queue;
    module module;
};

}; // namespace core
}; // namespace ants

#endif // ANTS_CORE_SERVICE_HPP