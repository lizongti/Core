#ifndef ANTS_KERNEL_MODULE_HPP
#define ANTS_KERNEL_MODULE_HPP

#include <iostream>
#include <functional>
#include <mutex>
#include <unordered_map>
#include <boost/dll/shared_library.hpp>
#include <boost/noncopyable.hpp>
#include <boost/version.hpp>
#include <boost/config.hpp>
#include <ants/detail/singleton.hpp>
#include <ants/detail/utility.hpp>
#include <ants/interface/context.h>
#include <ants/interface/import.h>

namespace ants
{
namespace kernel
{

class module
    : public std::enable_shared_from_this<module>
{
public:
    bool load(std::string const &module_name)
    {
        name = module_name;
        try
        {
            shared_library.load(name + detail::utility::shared_library_suffix());
        }
        catch (std::exception const &)
        {
            std::cerr << "Insufficient memory when loading shared memory:" << name << std::endl;
        }

        if (!shared_library.is_loaded())
        {
            std::cerr << "Failed loading shared library:" << name << std::endl;
            return false;
        }

        try
        {
            construct = &shared_library.get<interface::import_construct_function>("construct");
        }
        catch (std::exception const &)
        {
            std::cerr << "Leak function 'construct' in shared library:" << name << std::endl;
            return false;
        }

        try
        {
            handle = &shared_library.get<interface::import_handle_function>("handle");
        }
        catch (std::exception const &)
        {
            std::cerr << "Leak function 'handle' in shared library:" << name << std::endl;
            return false;
        }

        try
        {
            destroy = &shared_library.get<interface::import_destroy_function>("destroy");
        }
        catch (std::exception const &)
        {
            std::cerr << "Leak function 'destroy' in shared library:" << name << std::endl;
            return false;
        }

        return true;
    }

    bool unload()
    {
        try
        {
            shared_library.unload();
        }
        catch (std::exception const &)
        {
            std::cerr << "Shared library unload failed:" << name << std::endl;
            return false;
        }
        return true;
    }

public:
    interface::import_construct_function *construct;
    interface::import_handle_function *handle;
    interface::import_destroy_function *destroy;

private:
    std::string name;
    std::string path;
    boost::dll::shared_library shared_library;
};

class module_loader
    : public detail::singleton<module_loader>,
      private boost::noncopyable
{
public:
    static std::shared_ptr<module> load(std::string const &module_name)
    {
        std::lock_guard<std::mutex> lock(instance().mutex);

        auto &module_unordered_map = instance().module_unordered_map;
        if (module_unordered_map.find(module_name) !=
            module_unordered_map.end())
            return module_unordered_map[module_name];

        auto module = std::shared_ptr<kernel::module>(new kernel::module());
        module_unordered_map[module_name] = module;

        return module->load(module_name) ? module : nullptr;
    }

    static std::shared_ptr<module> unload(std::string const &module_name)
    {
        std::lock_guard<std::mutex> lock(instance().mutex);

        auto &module_unordered_map = instance().module_unordered_map;
        if (module_unordered_map.find(module_name) ==
            module_unordered_map.end())
            return nullptr;

        auto module = module_unordered_map[module_name];
        module_unordered_map.erase(module_name);

        return module->unload() ? module : nullptr;
    }

protected:
    std::unordered_map<std::string, std::shared_ptr<module>>
        module_unordered_map;
    mutable std::mutex mutex;
};

};     // namespace kernel
};     // namespace ants
#endif // ANTS_KERNEL_SERVICE_HPP